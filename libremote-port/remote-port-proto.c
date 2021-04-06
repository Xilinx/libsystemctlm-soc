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

#ifndef _DEFAULT_SOURCE
# define _DEFAULT_SOURCE
#endif
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

static const char *rp_cmd_names[RP_CMD_max + 1] = {
    [RP_CMD_nop] = "nop",
    [RP_CMD_hello] = "hello",
    [RP_CMD_cfg] = "cfg",
    [RP_CMD_read] = "read",
    [RP_CMD_write] = "write",
    [RP_CMD_interrupt] = "interrupt",
    [RP_CMD_sync] = "sync",
    [RP_CMD_ats_req] = "ats_request",
    [RP_CMD_ats_inv] = "ats_invalidation",
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
    /* Master_id has an odd decoding due to historical reasons.  */
    uint64_t master_id;

    switch (pkt->hdr.cmd) {
    case RP_CMD_hello:
        assert(pkt->hdr.len >= sizeof pkt->hello.version);
        pkt->hello.version.major = be16toh(pkt->hello.version.major);
        pkt->hello.version.minor = be16toh(pkt->hello.version.minor);
        used += sizeof pkt->hello.version;

        if ((pkt->hdr.len - used) >= sizeof pkt->hello.caps) {
            void *offset;
            int i;

            pkt->hello.caps.offset = be32toh(pkt->hello.caps.offset);
            pkt->hello.caps.len = be16toh(pkt->hello.caps.len);

            offset = (char *)pkt + pkt->hello.caps.offset;
            for (i = 0; i < pkt->hello.caps.len; i++) {
                uint32_t cap;

                /* We don't know if offset is 32bit aligned so use
                 * memcpy to do the endian conversion.  */
                memcpy(&cap, offset + i * sizeof cap, sizeof cap);
                cap = be32toh(cap);
                memcpy(offset + i * sizeof cap, &cap, sizeof cap);
            }
            used += sizeof pkt->hello.caps;
        } else {
            pkt->hello.caps.offset = 0;
            pkt->hello.caps.len = 0;
        }

        /* Consume everything ignoring additional headers we do not yet
         * know about.  */
        used = pkt->hdr.len;
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
        master_id = be16toh(pkt->busaccess.master_id);

        used += sizeof pkt->busaccess - sizeof pkt->hdr;

        if (pkt->busaccess.attributes & RP_BUS_ATTR_EXT_BASE) {
            struct rp_pkt_busaccess_ext_base *pext = &pkt->busaccess_ext_base;

            assert(pkt->hdr.len >= sizeof *pext - sizeof pkt->hdr);
            master_id |= (uint64_t)be16toh(pext->master_id_31_16) << 16;
            master_id |= (uint64_t)be32toh(pext->master_id_63_32) << 32;
            pext->data_offset = be32toh(pext->data_offset);
            pext->next_offset = be32toh(pext->next_offset);
            pext->byte_enable_offset = be32toh(pext->byte_enable_offset);
            pext->byte_enable_len = be32toh(pext->byte_enable_len);

            used += sizeof *pext - sizeof pkt->busaccess;
        }
        pkt->busaccess.master_id = master_id;
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
    case RP_CMD_ats_req:
    case RP_CMD_ats_inv:
        pkt->ats.attributes = be64toh(pkt->ats.attributes);
        pkt->ats.addr = be64toh(pkt->ats.addr);
        pkt->ats.len = be64toh(pkt->ats.len);
        pkt->ats.result = be32toh(pkt->ats.result);
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

size_t rp_encode_hello_caps(uint32_t id, uint32_t dev, struct rp_pkt_hello *pkt,
                            uint16_t version_major, uint16_t version_minor,
                            uint32_t *caps, uint32_t *caps_out,
                            uint32_t caps_len)
{
    size_t psize = sizeof *pkt + sizeof caps[0] * caps_len;
    unsigned int i;

    rp_encode_hdr(&pkt->hdr, RP_CMD_hello, id, dev,
                  psize - sizeof pkt->hdr, 0);
    pkt->version.major = htobe16(version_major);
    pkt->version.minor = htobe16(version_minor);

    /* Feature list is appeneded right after the hello packet.  */
    pkt->caps.offset = htobe32(sizeof *pkt);
    pkt->caps.len = htobe16(caps_len);

    for (i = 0; i < caps_len; i++) {
        uint32_t cap;

        cap = caps[i];
        caps_out[i] = htobe32(cap);
    }
    return sizeof *pkt;
}

static void rp_encode_busaccess_common(struct rp_pkt_busaccess *pkt,
                                  int64_t clk, uint16_t master_id,
                                  uint64_t addr, uint64_t attr, uint32_t size,
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
                      uint64_t addr, uint64_t attr, uint32_t size,
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
                           uint64_t addr, uint64_t attr, uint32_t size,
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
                       uint64_t addr, uint64_t attr, uint32_t size,
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
                       uint64_t addr, uint64_t attr, uint32_t size,
                       uint32_t width, uint32_t stream_width)
{
    rp_encode_hdr(&pkt->hdr, RP_CMD_write, id, dev,
                  sizeof *pkt - sizeof pkt->hdr, RP_PKT_FLAGS_response);
    rp_encode_busaccess_common(pkt, clk, master_id, addr, attr,
                               size, width, stream_width);
    return sizeof *pkt;
}

/* New API for extended header.  */
size_t rp_encode_busaccess(struct rp_peer_state *peer,
                           struct rp_pkt_busaccess_ext_base *pkt,
                           struct rp_encode_busaccess_in *in) {
    struct rp_pkt_busaccess *pkt_v4_0 = (void *) pkt;
    uint32_t hsize = 0;
    uint32_t ret_size = 0;

    /* Allocate packet space.  */
    if (in->cmd == RP_CMD_write && !(in->flags & RP_PKT_FLAGS_response)) {
        hsize = in->size;
    }
    if (in->cmd == RP_CMD_read && (in->flags & RP_PKT_FLAGS_response)) {
        hsize = in->size;
        ret_size = in->size;
    }

    /* If peer does not support the busaccess base extensions, use the
     * old layout. For responses, what matters is if we're responding
     * to a packet with the extensions.
     */
    if (!peer->caps.busaccess_ext_base && !(in->attr & RP_BUS_ATTR_EXT_BASE)) {
        /* Old layout.  */
        assert(in->master_id < UINT16_MAX);

        rp_encode_hdr(&pkt->hdr, in->cmd, in->id, in->dev,
                  sizeof *pkt_v4_0 - sizeof pkt->hdr + hsize, in->flags);
        rp_encode_busaccess_common(pkt_v4_0, in->clk, in->master_id,
                                   in->addr, in->attr,
                                   in->size, in->width, in->stream_width);
        return sizeof *pkt_v4_0 + ret_size;
    }

    /* Encode the extended fields.  */
    pkt->master_id_31_16 = htobe16(in->master_id >> 16);
    pkt->master_id_63_32 = htobe32(in->master_id >> 32);

    /* We always put data right after the header.  */
    pkt->data_offset = htobe32(sizeof *pkt);
    pkt->next_offset = 0;

    pkt->byte_enable_offset = htobe32(sizeof *pkt + hsize);
    pkt->byte_enable_len = htobe32(in->byte_enable_len);
    hsize += in->byte_enable_len;

    rp_encode_hdr(&pkt->hdr, in->cmd, in->id, in->dev,
                  sizeof *pkt - sizeof pkt->hdr + hsize, in->flags);
    rp_encode_busaccess_common(pkt_v4_0, in->clk, in->master_id, in->addr,
                               in->attr | RP_BUS_ATTR_EXT_BASE,
                               in->size, in->width, in->stream_width);

    return sizeof *pkt + ret_size;
}

size_t rp_encode_interrupt_f(uint32_t id, uint32_t dev,
                             struct rp_pkt_interrupt *pkt,
                             int64_t clk,
                             uint32_t line, uint64_t vector, uint8_t val,
                             uint32_t flags)
{
    rp_encode_hdr(&pkt->hdr, RP_CMD_interrupt, id, dev,
                  sizeof *pkt - sizeof pkt->hdr, flags);
    pkt->timestamp = htobe64(clk);
    pkt->vector = htobe64(vector);
    pkt->line = htobe32(line);
    pkt->val = val;
    return sizeof *pkt;
}

size_t rp_encode_interrupt(uint32_t id, uint32_t dev,
                           struct rp_pkt_interrupt *pkt,
                           int64_t clk,
                           uint32_t line, uint64_t vector, uint8_t val)
{
    return rp_encode_interrupt_f(id, dev, pkt, clk, line, vector, val, 0);
}

static size_t rp_encode_ats_common(uint32_t cmd, uint32_t id, uint32_t dev,
                         struct rp_pkt_ats *pkt,
                         int64_t clk, uint64_t attr, uint64_t addr,
                         uint64_t len, uint64_t result, uint32_t flags)
{
    rp_encode_hdr(&pkt->hdr, cmd, id, dev,
                  sizeof *pkt - sizeof pkt->hdr, flags);
    pkt->timestamp = htobe64(clk);
    pkt->attributes = htobe64(attr);
    pkt->addr = htobe64(addr);
    pkt->len = htobe64(len);
    pkt->result = htobe32(result);
    return sizeof *pkt;
}

size_t rp_encode_ats_req(uint32_t id, uint32_t dev,
                         struct rp_pkt_ats *pkt,
                         int64_t clk, uint64_t attr, uint64_t addr,
                         uint64_t len, uint64_t result, uint32_t flags)
{
    return rp_encode_ats_common(RP_CMD_ats_req, id, dev,
                                pkt, clk, attr,
                                addr, len, result, flags);
}

size_t rp_encode_ats_inv(uint32_t id, uint32_t dev,
                         struct rp_pkt_ats *pkt,
                         int64_t clk, uint64_t attr, uint64_t addr,
                         uint64_t len, uint64_t result, uint32_t flags)
{
    return rp_encode_ats_common(RP_CMD_ats_inv, id, dev,
                                pkt, clk, attr,
                                addr, len, result, flags);
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

void rp_process_caps(struct rp_peer_state *peer,
                     void *caps, size_t caps_len)
{
    int i;

    assert(peer->caps.busaccess_ext_base == false);

    for (i = 0; i < caps_len; i++) {
        uint32_t cap;

        memcpy(&cap, caps + i * sizeof cap, sizeof cap);

        switch (cap) {
        case CAP_BUSACCESS_EXT_BASE:
            peer->caps.busaccess_ext_base = true;
            break;
        case CAP_BUSACCESS_EXT_BYTE_EN:
            peer->caps.busaccess_ext_byte_en = true;
            break;
        case CAP_WIRE_POSTED_UPDATES:
            peer->caps.wire_posted_updates = true;
            break;
        case CAP_ATS:
            peer->caps.ats = true;
            break;
        }
    }
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
