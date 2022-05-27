/*
 * Common Ethernet functions.
 *
 * Copyright (c) 2022 Advanced Micro Devices Inc.
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
#ifndef SOC_NET_ETHERNET_ETHERNET_H__
#define SOC_NET_ETHERNET_ETHERNET_H__

#include <string.h>
#include <inttypes.h>

#define ETH_ADDR_LEN	6

/* Type/Protocols. */
#define ETH_HDR_TYPE_IP		0x0800
#define ETH_HDR_TYPE_VLAN	0x8100
#define ETH_HDR_TYPE_PAUSE	0x8808
#define ETH_HDR_TYPE_UNKOWN	0xFFFF

static inline bool eth_is_multicast(const unsigned char *daddr) {
	return daddr[0] & 1;
}

static inline bool eth_is_unicast(const unsigned char *daddr) {
	return !eth_is_multicast(daddr);
}

static inline bool eth_is_broadcast(const unsigned char *daddr) {
	unsigned char bcast[ETH_ADDR_LEN] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };

	return memcmp(daddr, bcast, ETH_ADDR_LEN) == 0;
}

static inline uint16_t eth_get_type(const unsigned char *pkt) {
	uint16_t type;
	int offset = ETH_ADDR_LEN * 2;

	type = pkt[offset] << 8;
	type |= pkt[offset + 1];

	return type;
}
#endif
