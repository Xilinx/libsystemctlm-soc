/*
 * TLM remoteport sockets
 *
 * Copyright (c) 2013 Xilinx Inc
 * Written by Edgar E. Iglesias
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#define _LARGEFILE64_SOURCE
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>

#include <sys/socket.h>
#include <sys/un.h>
#include <netdb.h>

#include "remote-port-sk.h"
#include "safeio.h"

#define UNIX_PREFIX "unix:"
#define TCP_PREFIX "tcp:"
#define TCPD_PREFIX "tcpd:"

int sk_reuseaddr(int fd, bool enable)
{
#ifdef _WIN32
	/* Windows defaults to reuse-addr.  */
	/* http://msdn.microsoft.com/en-us/library/windows/desktop/ms740621.aspx */
#else
	int v = enable;
	int r;


	r = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR,
		       (const char *)&v, sizeof(v));
	if (r) {
		perror("SO_REUSEADDR");
		abort();
	}
	return r;
#endif
}

static int sk_unix_client(const char *descr)
{
	struct sockaddr_un addr;
	int fd, nfd;

	fd = socket(AF_UNIX, SOCK_STREAM, 0);
	printf("connect to %s\n", descr + strlen(UNIX_PREFIX));

	memset(&addr, 0, sizeof addr);
	addr.sun_family = AF_UNIX;
	strncpy(addr.sun_path, descr + strlen(UNIX_PREFIX),
		sizeof addr.sun_path - 1);
	if (connect(fd, (struct sockaddr*)&addr, sizeof(addr)) >= 0)
		return fd;

	printf("Failed to connect to %s, attempt to listen\n", addr.sun_path);
	unlink(addr.sun_path);
	/* Failed to connect. Bind, listen and accept.  */
	if (bind(fd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
		goto fail;

	listen(fd, 5);
	nfd = accept(fd, NULL, NULL);
	close(fd);
	return nfd;
fail:
	close(fd);
	return -1;
}

static int sk_tcp_client(const char *descr, bool daemon)
{
	struct addrinfo hints;
	struct addrinfo *result, *rp;
	int sfd, s;
	char *pos;
	char *host;
	char *port = NULL;
	size_t prefix_len = daemon ? strlen(TCPD_PREFIX) : strlen(TCP_PREFIX);

	pos = (char *) descr + prefix_len;
	while (*pos == '/')
		pos++;

	host = strdup(pos);
	pos = strchr(host, ':');
	if (pos) {
		*pos = 0;
		port = pos + 1;
	}

	/* Now connect to the host and port.  */
	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_flags = AI_PASSIVE;

	s = getaddrinfo(host, port, &hints, &result);
	if (s != 0) {
		fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
		exit(EXIT_FAILURE);
	}

	for (rp = result; rp != NULL; rp = rp->ai_next) {
		sfd = socket(rp->ai_family, rp->ai_socktype,
			rp->ai_protocol);
		if (sfd == -1)
			continue;

		if (daemon) {
			if (bind(sfd, rp->ai_addr, rp->ai_addrlen) == -1) {
				perror("bind");
				exit(EXIT_FAILURE);
			}
			if (listen(sfd, 10) == -1) {
				perror("listen");
				exit(EXIT_FAILURE);
			}
			printf("Waiting on connections to %s:%s\n", host, port);
			sfd = accept(sfd, NULL, NULL);
			if (sfd < 0) {
				perror("listen");
				exit(EXIT_FAILURE);
			}
			break;
		} else {
			if (connect(sfd, rp->ai_addr, rp->ai_addrlen) != -1)
				break;
		}
		close(sfd);
	}

	if (rp == NULL) {
		return -1;
	}
	freeaddrinfo(result);

	sk_reuseaddr(sfd, true);
	return sfd;
}

int sk_open(const char *descr)
{
	int fd = -1;

	if (descr == NULL)
		return -1;

	if (memcmp(UNIX_PREFIX, descr, strlen(UNIX_PREFIX)) == 0) {
		/* UNIX.  */
		fd = sk_unix_client(descr);
		return fd;
	} else if (memcmp(TCPD_PREFIX, descr, strlen(TCP_PREFIX)) == 0) {
		fd = sk_tcp_client(descr, true);
		return fd;
	} else if (memcmp(TCP_PREFIX, descr, strlen(TCP_PREFIX)) == 0) {
		fd = sk_tcp_client(descr, false);
		return fd;
	}
	return -1;
}
