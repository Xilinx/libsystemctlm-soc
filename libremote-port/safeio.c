/*
 * Safe IO, take care of signal interruption and partial reads/writes.
 *
 * Copyright (c) 2011 Edgar E. Iglesias.
 * Written by Edgar E. Iglesias.
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
#include <stdio.h>
#include <unistd.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <fcntl.h>

#define D(x)

#if !defined(SPLICE_F_MOVE) && defined(__NR_splice)
#define SPLICE_F_MOVE          1
#include <sys/syscall.h>

long splice(int fd_in, off_t *off_in, int fd_out,
                   off_t *off_out, size_t len, unsigned int flags)
{
	return syscall(__NR_splice, fd_in, off_in, 
		       fd_out, off_out, len, flags);
}
#endif

ssize_t
rp_safe_read(int fd, void *rbuf, size_t count)
{
	ssize_t r;
	size_t rlen = 0;
	unsigned char *buf = rbuf;

	do {
		if ((r = read(fd, buf + rlen, count - rlen)) < 0) {
			if (errno == EINTR)
				continue;
			return -1;
		}
		rlen += r;
	} while (rlen < count && r);

	return rlen;
}

ssize_t
rp_safe_write(int fd, const void *wbuf, size_t count)
{
	ssize_t r;
	size_t wlen = 0;
	const unsigned char *buf = wbuf;

	do {
		if ((r = write(fd, buf + wlen, count - wlen)) < 0) {
			if (errno == EINTR) {
				continue;
			} else if (errno == EAGAIN) 
				break;
			return -1;
		}

		wlen += r;
	} while (wlen < count);

	return wlen;
}

/* Try to splice if possible.  */
int rp_safe_copyfd(int s, off64_t off, size_t olen, int d)
{
	static unsigned char buf[16 * 1024];
	int len = olen;
	int rlen;
	int wlen;
	int tlen = 0;

	D(fprintf(stderr, "%s off=%lld len=%d\n", __func__, off, len));
	lseek64(s, off, SEEK_SET);
#if 0
	long r;	
	do 
	{
		wlen = len > 16 * 1024 ? 16 * 1024 : len;
		r = splice(s, NULL, d, NULL, wlen, 0);
		D(fprintf(stderr, "splice r=%d errno=%d\n", r, errno));
		if (r == -1) {
			D(perror("splice"));
			if (errno == ENOSYS
			    || errno == EINVAL
			    || errno == EBADF)
				goto classic_read_write;
			if (errno == EAGAIN)
				continue;
		}
		else
			len -= r;
	}
	while (r > 0 && len > 0);

	D(fprintf (stderr, "dcore len=%d r=%ld errno=%d\n", len, r, errno));
	return r;
  classic_read_write:
#endif
	D(fprintf (stderr,
		   "dcore: fallback to classic read-write"
		   " r=%d errno=%d olen=%d.\n",
		   r, errno, olen));
	do
	{
		rlen = len > sizeof buf ? sizeof buf : len;
		rlen = read(s, buf, rlen);
		D(printf("read=%d errno=%d\n", rlen, errno));
		if (rlen == -1
		    && (errno == EAGAIN || errno == EINTR))
			continue;
		wlen = 0;
		while (rlen && wlen < rlen) 
		{
			int w;
			w = rp_safe_write(d, buf + wlen, rlen - wlen);
			if (w == -1) {
				D(perror("write"));
				break;
			}
			wlen += w;
		}
		tlen += wlen;
		len -= wlen;
	} while (rlen && len);
	D(fprintf (stderr, "done tlen=%d olen=%d\n", tlen, olen));
	return tlen;
}
