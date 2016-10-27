/*
 * Remote-port protocol
 *
 * Copyright (c) 2013 Xilinx Inc
 * Written by Edgar E. Iglesias <edgar.iglesias@xilinx.com>
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

#define _BSD_SOURCE
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <assert.h>
#include "remote-port-proto.h"

#undef MIN
#define MIN(x, y) (x < y ? x : y)

#if defined(__linux__)
#  include <endian.h>
#elif defined(__FreeBSD__) || defined(__NetBSD__)
#  include <sys/endian.h>
#elif defined(__OpenBSD__)
#  include <sys/types.h>
#  define be16toh(x) betoh16(x)
#  define be32toh(x) betoh32(x)
#  define be64toh(x) betoh64(x)
#elif defined(__WIN32)
/* We assume little endian.  */
#    define htobe64(x) _byteswap_uint64(x)
#    define htobe32(x) _byteswap_ulong(x)
#    define htobe16(x) _byteswap_ushort(x)

#    define be64toh(x) _byteswap_uint64(x)
#    define be32toh(x) _byteswap_ulong(x)
#    define be16toh(x) _byteswap_ushort(x)
#endif

/* Fallback for ancient Linux systems.  */
#ifndef htobe64
#  include <byteswap.h>

#  if __BYTE_ORDER == __LITTLE_ENDIAN
#    define htobe64(x) bswap_64(x)
#    define htobe32(x) bswap_32(x)
#    define htobe16(x) bswap_16(x)

#    define be64toh(x) bswap_64(x)
#    define be32toh(x) bswap_32(x)
#    define be16toh(x) bswap_16(x)
#  else
#    define htobe64(x) x
#    define htobe32(x) x
#    define htobe16(x) x

#    define be64toh(x) x
#    define be32toh(x) x
#    define be16toh(x) x
#  endif
#endif

#define RP_OPT_ENT(name) [RP_OPT_ ## name] = offsetof(struct rp_cfg_state, name)
static const size_t rp_opt_map[] = {
    RP_OPT_ENT(quantum),
};

static const char *rp_cmd_names[RP_CMD_max + 1] = {
    [RP_CMD_nop] = "nop",
    [RP_CMD_hello] = "hello",
    [RP_CMD_cfg] = "cfg",
    [RP_CMD_read] = "read",
    [RP_CMD_write] = "write",
    [RP_CMD_interrupt] = "interrupt",
    [RP_CMD_sync] = "sync",
};

const char *rp_cmd_to_string(enum rp_cmd cmd)
{
    assert(cmd <= RP_CMD_max);
    return rp_cmd_names[cmd];
}

int rp_decode_hdr(struct rp_pkt *pkt)
{
    int used = 0;

    pkt->hdr.cmd = be32toh(pkt->hdr.cmd);
    pkt->hdr.len = be32toh(pkt->hdr.len);
    pkt->hdr.id = be32toh(pkt->hdr.id);
    pkt->hdr.flags = be32toh(pkt->hdr.flags);
    pkt->hdr.dev = be32toh(pkt->hdr.dev);
    used += sizeof pkt->hdr;
    return used;
}

int rp_decode_payload(struct rp_pkt *pkt)
{
    int used = 0;

    switch (pkt->hdr.cmd) {
    case RP_CMD_hello:
        assert(pkt->hdr.len >= sizeof pkt->hello.version);
        pkt->hello.version.major = be16toh(pkt->hello.version.major);
        pkt->hello.version.minor = be16toh(pkt->hello.version.minor);
        used += pkt->hdr.len;
        break;
    case RP_CMD_write:
    case RP_CMD_read:
        assert(pkt->hdr.len >= sizeof pkt->busaccess - sizeof pkt->hdr);
        pkt->busaccess.timestamp = be64toh(pkt->busaccess.timestamp);
        pkt->busaccess.addr = be64toh(pkt->busaccess.addr);
        pkt->busaccess.master_id = be16toh(pkt->busaccess.master_id);
        pkt->busaccess.attributes = be64toh(pkt->busaccess.attributes);
        pkt->busaccess.len = be32toh(pkt->busaccess.len);
        pkt->busaccess.width = be32toh(pkt->busaccess.width);
        pkt->busaccess.stream_width = be32toh(pkt->busaccess.stream_width);
        used += sizeof pkt->busaccess - sizeof pkt->hdr;
        break;
    case RP_CMD_interrupt:
        pkt->interrupt.timestamp = be64toh(pkt->interrupt.timestamp);
        pkt->interrupt.vector = be64toh(pkt->interrupt.vector);
        pkt->interrupt.line = be32toh(pkt->interrupt.line);
        pkt->interrupt.val = pkt->interrupt.val;
        used += pkt->hdr.len;
        break;
    case RP_CMD_sync:
        pkt->sync.timestamp = be64toh(pkt->interrupt.timestamp);
        used += pkt->hdr.len;
        break;
    default:
        break;
    }
    return used;
}

void rp_encode_hdr(struct rp_pkt_hdr *hdr, uint32_t cmd, uint32_t id,
                   uint32_t dev, uint32_t len, uint32_t flags)
{
    hdr->cmd = htobe32(cmd);
    hdr->len = htobe32(len);
    hdr->id = htobe32(id);
    hdr->dev = htobe32(dev);
    hdr->flags = htobe32(flags);
}

size_t rp_encode_hello(uint32_t id, uint32_t dev, struct rp_pkt_hello *pkt,
                       uint16_t version_major, uint16_t version_minor)
{
    rp_encode_hdr(&pkt->hdr, RP_CMD_hello, id, dev,
                  sizeof *pkt - sizeof pkt->hdr, 0);
    pkt->version.major = htobe16(version_major);
    pkt->version.minor = htobe16(version_minor);
    return sizeof *pkt;
}

static void rp_encode_busaccess_common(struct rp_pkt_busaccess *pkt,
                                  int64_t clk, uint16_t master_id,
                                  uint64_t addr, uint32_t attr, uint32_t size,
                                  uint32_t width, uint32_t stream_width)
{
    pkt->timestamp = htobe64(clk);
    pkt->master_id = htobe16(master_id);
    pkt->addr = htobe64(addr);
    pkt->attributes = htobe64(attr);
    pkt->len = htobe32(size);
    pkt->width = htobe32(width);
    pkt->stream_width = htobe32(stream_width);
}

size_t rp_encode_read(uint32_t id, uint32_t dev,
                      struct rp_pkt_busaccess *pkt,
                      int64_t clk, uint16_t master_id,
                      uint64_t addr, uint32_t attr, uint32_t size,
                      uint32_t width, uint32_t stream_width)
{
    rp_encode_hdr(&pkt->hdr, RP_CMD_read, id, dev,
                  sizeof *pkt - sizeof pkt->hdr, 0);
    rp_encode_busaccess_common(pkt, clk, master_id, addr, attr,
                               size, width, stream_width);
    return sizeof *pkt;
}

size_t rp_encode_read_resp(uint32_t id, uint32_t dev,
                           struct rp_pkt_busaccess *pkt,
                           int64_t clk, uint16_t master_id,
                           uint64_t addr, uint32_t attr, uint32_t size,
                           uint32_t width, uint32_t stream_width)
{
    rp_encode_hdr(&pkt->hdr, RP_CMD_read, id, dev,
                  sizeof *pkt - sizeof pkt->hdr + size, RP_PKT_FLAGS_response);
    rp_encode_busaccess_common(pkt, clk, master_id, addr, attr,
                               size, width, stream_width);
    return sizeof *pkt + size;
}

size_t rp_encode_write(uint32_t id, uint32_t dev,
                       struct rp_pkt_busaccess *pkt,
                       int64_t clk, uint16_t master_id,
                       uint64_t addr, uint32_t attr, uint32_t size,
                       uint32_t width, uint32_t stream_width)
{
    rp_encode_hdr(&pkt->hdr, RP_CMD_write, id, dev,
                  sizeof *pkt - sizeof pkt->hdr + size, 0);
    rp_encode_busaccess_common(pkt, clk, master_id, addr, attr,
                               size, width, stream_width);
    return sizeof *pkt;
}

size_t rp_encode_write_resp(uint32_t id, uint32_t dev,
                       struct rp_pkt_busaccess *pkt,
                       int64_t clk, uint16_t master_id,
                       uint64_t addr, uint32_t attr, uint32_t size,
                       uint32_t width, uint32_t stream_width)
{
    rp_encode_hdr(&pkt->hdr, RP_CMD_write, id, dev,
                  sizeof *pkt - sizeof pkt->hdr, RP_PKT_FLAGS_response);
    rp_encode_busaccess_common(pkt, clk, master_id, addr, attr,
                               size, width, stream_width);
    return sizeof *pkt;
}

size_t rp_encode_interrupt(uint32_t id, uint32_t dev,
                           struct rp_pkt_interrupt *pkt,
                           int64_t clk,
                           uint32_t line, uint64_t vector, uint8_t val)
{
    rp_encode_hdr(&pkt->hdr, RP_CMD_interrupt, id, dev,
                  sizeof *pkt - sizeof pkt->hdr, 0);
    pkt->timestamp = htobe64(clk);
    pkt->vector = htobe64(vector);
    pkt->line = htobe32(line);
    pkt->val = val;
    return sizeof *pkt;
}

static size_t rp_encode_sync_common(uint32_t id, uint32_t dev,
                                    struct rp_pkt_sync *pkt,
                                    int64_t clk, uint32_t flags)
{
    rp_encode_hdr(&pkt->hdr, RP_CMD_sync, id, dev,
                  sizeof *pkt - sizeof pkt->hdr, flags);
    pkt->timestamp = htobe64(clk);
    return sizeof *pkt;
}

size_t rp_encode_sync(uint32_t id, uint32_t dev,
                      struct rp_pkt_sync *pkt,
                      int64_t clk)
{
    return rp_encode_sync_common(id, dev, pkt, clk, 0);
}

size_t rp_encode_sync_resp(uint32_t id, uint32_t dev,
                           struct rp_pkt_sync *pkt,
                           int64_t clk)
{
    return rp_encode_sync_common(id, dev, pkt, clk, RP_PKT_FLAGS_response);
}

void rp_dpkt_alloc(RemotePortDynPkt *dpkt, size_t size)
{
    if (dpkt->size < size) {
        char *u8;
        dpkt->pkt = realloc(dpkt->pkt, size);
        u8 = (void *) dpkt->pkt;
        memset(u8 + dpkt->size, 0, size - dpkt->size);
        dpkt->size = size;
    }
}

void rp_dpkt_swap(RemotePortDynPkt *a, RemotePortDynPkt *b)
{
    struct rp_pkt *tmp_pkt;
    size_t tmp_size;

    tmp_pkt = a->pkt;
    tmp_size = a->size;
    a->pkt = b->pkt;
    a->size = b->size;
    b->pkt = tmp_pkt;
    b->size = tmp_size;
}

bool rp_dpkt_is_valid(RemotePortDynPkt *dpkt)
{
    return dpkt->size > 0 && dpkt->pkt->hdr.len;
}

void rp_dpkt_invalidate(RemotePortDynPkt *dpkt)
{
    assert(rp_dpkt_is_valid(dpkt));
    dpkt->pkt->hdr.len = 0;
}

inline void rp_dpkt_free(RemotePortDynPkt *dpkt)
{
    dpkt->size = 0;
    free(dpkt->pkt);
}
