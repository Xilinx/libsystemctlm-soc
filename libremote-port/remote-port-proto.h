/*
 * QEMU remote port protocol parts.
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
#ifndef REMOTE_PORT_PROTO_H__
#define REMOTE_PORT_PROTO_H__

#include <stdbool.h>
#include <string.h>

/*
 * Remote-Port (RP) is an inter-simulator protocol. It assumes a reliable
 * point to point communcation with the remote simulation environment.
 *
 * Setup
 * In the SETUP phase a mandatory HELLO packet is exchanged with optional
 * CFG packets following. HELLO packets are useful to ensure that both
 * sides are speaking the same protocol and using compatible versions.
 *
 * CFG packets are used to negotiate configuration options. At the moment
 * these remain unimplemented.
 *
 * Once the session is up, communication can start through various other
 * commands. The list can be found further down this document.
 * Commands are carried over RP packets. Every RP packet contains a header
 * with length, flags and an ID to track potential responses.
 * The header is followed by a packet specific payload. You'll find the
 * details of the various commands packet layouts here. Some commands can
 * carry data/blobs in their payload.
 */


#define RP_VERSION_MAJOR 4
#define RP_VERSION_MINOR 3

#if defined(_WIN32) && defined(__MINGW32__)
/* mingw GCC has a bug with packed attributes.  */
#define PACKED __attribute__ ((gcc_struct, packed))
#else
#define PACKED __attribute__ ((packed))
#endif

/* Could be auto generated.  */
enum rp_cmd {
    RP_CMD_nop         = 0,
    RP_CMD_hello       = 1,
    RP_CMD_cfg         = 2,
    RP_CMD_read        = 3,
    RP_CMD_write       = 4,
    RP_CMD_interrupt   = 5,
    RP_CMD_sync        = 6,
    RP_CMD_ats_req     = 7,
    RP_CMD_ats_inv     = 8,
    RP_CMD_max         = 8
};

enum {
    RP_OPT_quantum = 0,
};

struct rp_cfg_state {
    uint64_t quantum;
};

enum {
    RP_PKT_FLAGS_optional      = 1 << 0,
    RP_PKT_FLAGS_response      = 1 << 1,

    /* Posted hint.
     * When set this means that the receiver is not required to respond to
     * the message. Since it's just a hint, the sender must be prepared to
     * drop responses. Note that since flags are echoed back in responses
     * a response to a posted packet will be easy to identify early in the
     * protocol stack.
     */
    RP_PKT_FLAGS_posted        = 1 << 2,
};

struct rp_pkt_hdr {
    uint32_t cmd;
    uint32_t len;
    uint32_t id;
    uint32_t flags;
    uint32_t dev;
} PACKED;

struct rp_pkt_cfg {
    struct rp_pkt_hdr hdr;
    uint32_t opt;
    uint8_t set;
} PACKED;

struct rp_version {
    uint16_t major;
    uint16_t minor;
} PACKED;

struct rp_capabilities {
    /* Offset from start of packet.  */
    uint32_t offset;
    uint16_t len;
    uint16_t reserved0;
} PACKED;

enum {
    CAP_BUSACCESS_EXT_BASE = 1,    /* New header layout. */
    CAP_BUSACCESS_EXT_BYTE_EN = 2, /* Support for Byte Enables.  */

    /*
     * Originally, all interrupt/wire updates over remote-port were posted.
     * This turned out to be a bad idea. To fix it without breaking backwards
     * compatibility, we add the WIRE Posted updates capability.
     *
     * If the peer supportes this, it will respect the RP_PKT_FLAGS_posted
     * flag. If the peer doesn't support this capability, senders need to
     * be aware that the peer will not respond to wire updates regardless
     * of the posted header-flag.
     */
    CAP_WIRE_POSTED_UPDATES = 3,

    CAP_ATS = 4, /* Address translation services */
};

struct rp_pkt_hello {
    struct rp_pkt_hdr hdr;
    struct rp_version version;
    struct rp_capabilities caps;
} PACKED;

enum {
    /* Remote port responses. */
    RP_RESP_OK                  =  0x0,
    RP_RESP_BUS_GENERIC_ERROR   =  0x1,
    RP_RESP_ADDR_ERROR          =  0x2,
    RP_RESP_MAX                 =  0xF,
};

enum {
    RP_BUS_ATTR_EOP        =  (1 << 0),
    RP_BUS_ATTR_SECURE     =  (1 << 1),
    RP_BUS_ATTR_EXT_BASE   =  (1 << 2),
    RP_BUS_ATTR_PHYS_ADDR  =  (1 << 3),

    /*
     * The access targets the I/O address space.
     */
    RP_BUS_ATTR_IO_ACCESS  =  (1 << 4),

    /*
     * Bits [11:8] are allocated for storing transaction response codes.
     * These new response codes are backward compatible as existing
     * implementations will not set/read these bits.
     * For existing implementations, these bits will be zero which is RESP_OKAY.
     */
    RP_BUS_RESP_SHIFT    =  8,
    RP_BUS_RESP_MASK     =  (RP_RESP_MAX << RP_BUS_RESP_SHIFT),
};

struct rp_pkt_busaccess {
    struct rp_pkt_hdr hdr;
    uint64_t timestamp;
    uint64_t attributes;
    uint64_t addr;

    /* Length in bytes.  */
    uint32_t len;

    /* Width of each beat in bytes. Set to zero for unknown (let the remote
       side choose).  */
    uint32_t width;

    /* Width of streaming, must be a multiple of width.
       addr should repeat itself around this width. Set to same as len
       for incremental (normal) accesses.  In bytes.  */
    uint32_t stream_width;

    /* Implementation specific source or master-id.  */
    uint16_t master_id;
} PACKED;


/* This is the new extended busaccess packet layout.  */
struct rp_pkt_busaccess_ext_base {
    struct rp_pkt_hdr hdr;
    uint64_t timestamp;
    uint64_t attributes;
    uint64_t addr;

    /* Length in bytes.  */
    uint32_t len;

    /* Width of each beat in bytes. Set to zero for unknown (let the remote
       side choose).  */
    uint32_t width;

    /* Width of streaming, must be a multiple of width.
       addr should repeat itself around this width. Set to same as len
       for incremental (normal) accesses.  In bytes.  */
    uint32_t stream_width;

    /* Implementation specific source or master-id.  */
    uint16_t master_id;
    /* ---- End of 4.0 base busaccess. ---- */

    uint16_t master_id_31_16;   /* MasterID bits [31:16].  */
    uint32_t master_id_63_32;   /* MasterID bits [63:32].  */
    /* ---------------------------------------------------
     * Since hdr is 5 x 32bit, we are now 64bit aligned.  */

    uint32_t data_offset;       /* Offset to data from start of pkt.  */
    uint32_t next_offset;       /* Offset to next extension. 0 if none.  */

    uint32_t byte_enable_offset;
    uint32_t byte_enable_len;

    /* ---- End of CAP_BUSACCESS_EXT_BASE. ---- */

    /* If new features are needed that may always occupy space
     * in the header, then add a new capability and extend the
     * this area with new fields.
     * Will help receivers find data_offset and next offset,
     * even those that don't know about extended fields.
     */
} PACKED;

struct rp_pkt_interrupt {
    struct rp_pkt_hdr hdr;
    uint64_t timestamp;
    uint64_t vector;
    uint32_t line;
    uint8_t val;
} PACKED;

struct rp_pkt_sync {
    struct rp_pkt_hdr hdr;
    uint64_t timestamp;
} PACKED;

enum {
    RP_ATS_ATTR_exec     = 1 << 0,
    RP_ATS_ATTR_read     = 1 << 1,
    RP_ATS_ATTR_write    = 1 << 2,
};

enum {
    RP_ATS_RESULT_ok = 0,
    RP_ATS_RESULT_error = 1,
};

struct rp_pkt_ats {
    struct rp_pkt_hdr hdr;
    uint64_t timestamp;
    uint64_t attributes;
    uint64_t addr;
    uint64_t len;
    uint32_t result;
    uint64_t reserved0;
    uint64_t reserved1;
    uint64_t reserved2;
    uint64_t reserved3;
} PACKED;

struct rp_pkt {
    union {
        struct rp_pkt_hdr hdr;
        struct rp_pkt_hello hello;
        struct rp_pkt_busaccess busaccess;
        struct rp_pkt_busaccess_ext_base busaccess_ext_base;
        struct rp_pkt_interrupt interrupt;
        struct rp_pkt_sync sync;
        struct rp_pkt_ats ats;
    };
};

struct rp_peer_state {
    void *opaque;

    struct rp_pkt pkt;
    bool hdr_used;

    struct rp_version version;

    struct {
        bool busaccess_ext_base;
        bool busaccess_ext_byte_en;
        bool wire_posted_updates;
        bool ats;
    } caps;

    /* Used to normalize our clk.  */
    int64_t clk_base;

    struct rp_cfg_state local_cfg;
    struct rp_cfg_state peer_cfg;
};

const char *rp_cmd_to_string(enum rp_cmd cmd);
int rp_decode_hdr(struct rp_pkt *pkt);
int rp_decode_payload(struct rp_pkt *pkt);

void rp_encode_hdr(struct rp_pkt_hdr *hdr,
                   uint32_t cmd, uint32_t id, uint32_t dev, uint32_t len,
                   uint32_t flags);

/*
 * caps is a an array of supported capabilities by the implementor.
 * caps_out is the encoded (network byte order) version of the
 * same array. It should be sent to the peer after the hello packet.
 */
size_t rp_encode_hello_caps(uint32_t id, uint32_t dev, struct rp_pkt_hello *pkt,
                            uint16_t version_major, uint16_t version_minor,
                            uint32_t *caps, uint32_t *features_out,
                            uint32_t features_len);

/* rp_encode_hello is deprecated in favor of hello_caps.  */
static inline size_t __attribute__ ((deprecated))
rp_encode_hello(uint32_t id, uint32_t dev, struct rp_pkt_hello *pkt,
                uint16_t version_major, uint16_t version_minor) {
    return rp_encode_hello_caps(id, dev, pkt, version_major, version_minor,
                                NULL, NULL, 0);
}

static inline void *__attribute__ ((deprecated))
rp_busaccess_dataptr(struct rp_pkt_busaccess *pkt)
{
    /* Right after the packet.  */
    return pkt + 1;
}

/*
 * rp_busaccess_rx_dataptr
 *
 * Predicts the dataptr for a packet to be transmitted.
 * This should only be used if you are trying to keep
 * the entire packet in a linear buffer.
 */
static inline unsigned char *
rp_busaccess_tx_dataptr(struct rp_peer_state *peer,
                        struct rp_pkt_busaccess_ext_base *pkt)
{
    unsigned char *p = (unsigned char *) pkt;

    if (peer->caps.busaccess_ext_base) {
        /* We always put our data right after the header.  */
        return p + sizeof *pkt;
    } else {
        /* Right after the old packet layout.  */
        return p + sizeof(struct rp_pkt_busaccess);
    }
}

/*
 * rp_busaccess_rx_dataptr
 *
 * Extracts the dataptr from a received packet.
 */
static inline unsigned char *
rp_busaccess_rx_dataptr(struct rp_peer_state *peer,
                        struct rp_pkt_busaccess_ext_base *pkt)
{
    unsigned char *p = (unsigned char *) pkt;

    if (pkt->attributes & RP_BUS_ATTR_EXT_BASE) {
        return p + pkt->data_offset;
    } else {
        /* Right after the old packet layout.  */
        return p + sizeof(struct rp_pkt_busaccess);
    }
}

static inline unsigned char *
rp_busaccess_byte_en_ptr(struct rp_peer_state *peer,
                         struct rp_pkt_busaccess_ext_base *pkt)
{
    unsigned char *p = (unsigned char *) pkt;

    if ((pkt->attributes & RP_BUS_ATTR_EXT_BASE)
        && pkt->byte_enable_len) {
        assert(pkt->byte_enable_offset >= sizeof *pkt);
        assert(pkt->byte_enable_offset + pkt->byte_enable_len
               <= pkt->hdr.len + sizeof pkt->hdr);
        return p + pkt->byte_enable_offset;
    }
    return NULL;
}

size_t __attribute__ ((deprecated))
rp_encode_read(uint32_t id, uint32_t dev,
               struct rp_pkt_busaccess *pkt,
               int64_t clk, uint16_t master_id,
               uint64_t addr, uint64_t attr, uint32_t size,
               uint32_t width, uint32_t stream_width);

size_t __attribute__ ((deprecated))
rp_encode_read_resp(uint32_t id, uint32_t dev,
                    struct rp_pkt_busaccess *pkt,
                    int64_t clk, uint16_t master_id,
                    uint64_t addr, uint64_t attr, uint32_t size,
                    uint32_t width, uint32_t stream_width);

size_t __attribute__ ((deprecated))
rp_encode_write(uint32_t id, uint32_t dev,
                struct rp_pkt_busaccess *pkt,
                int64_t clk, uint16_t master_id,
                uint64_t addr, uint64_t attr, uint32_t size,
                uint32_t width, uint32_t stream_width);

size_t __attribute__ ((deprecated))
rp_encode_write_resp(uint32_t id, uint32_t dev,
                     struct rp_pkt_busaccess *pkt,
                     int64_t clk, uint16_t master_id,
                     uint64_t addr, uint64_t attr, uint32_t size,
                     uint32_t width, uint32_t stream_width);

struct rp_encode_busaccess_in {
    uint32_t cmd;
    uint32_t id;
    uint32_t flags;
    uint32_t dev;
    int64_t clk;
    uint64_t master_id;
    uint64_t addr;
    uint64_t attr;
    uint32_t size;
    uint32_t width;
    uint32_t stream_width;
    uint32_t byte_enable_len;
};

/* Prepare encode_busaccess input parameters for a packet response.  */
static inline void
rp_encode_busaccess_in_rsp_init(struct rp_encode_busaccess_in *in,
                                struct rp_pkt *pkt) {
    memset(in, 0, sizeof *in);
    in->cmd = pkt->hdr.cmd;
    in->id = pkt->hdr.id;
    in->flags = pkt->hdr.flags | RP_PKT_FLAGS_response;
    in->dev = pkt->hdr.dev;
    /* FIXME: Propagate all master_id fields?  */
    in->master_id = pkt->busaccess.master_id;
    in->addr = pkt->busaccess.addr;
    in->size = pkt->busaccess.len;
    in->width = pkt->busaccess.width;
    in->stream_width = pkt->busaccess.stream_width;
    in->byte_enable_len = 0;
}
size_t rp_encode_busaccess(struct rp_peer_state *peer,
                           struct rp_pkt_busaccess_ext_base *pkt,
                           struct rp_encode_busaccess_in *in);

size_t rp_encode_interrupt_f(uint32_t id, uint32_t dev,
                             struct rp_pkt_interrupt *pkt,
                             int64_t clk,
                             uint32_t line, uint64_t vector, uint8_t val,
                             uint32_t flags);

size_t rp_encode_interrupt(uint32_t id, uint32_t dev,
                           struct rp_pkt_interrupt *pkt,
                           int64_t clk,
                           uint32_t line, uint64_t vector, uint8_t val);

size_t rp_encode_sync(uint32_t id, uint32_t dev,
                      struct rp_pkt_sync *pkt,
                      int64_t clk);

size_t rp_encode_sync_resp(uint32_t id, uint32_t dev,
                           struct rp_pkt_sync *pkt,
                           int64_t clk);

size_t rp_encode_ats_req(uint32_t id, uint32_t dev,
                             struct rp_pkt_ats *pkt,
                             int64_t clk, uint64_t attr, uint64_t addr,
                             uint64_t size, uint64_t result, uint32_t flags);

size_t rp_encode_ats_inv(uint32_t id, uint32_t dev,
                             struct rp_pkt_ats *pkt,
                             int64_t clk, uint64_t attr, uint64_t addr,
                             uint64_t size, uint64_t result, uint32_t flags);

void rp_process_caps(struct rp_peer_state *peer,
                     void *caps, size_t caps_len);

/* Dynamically resizable remote port pkt.  */

typedef struct RemotePortDynPkt {
    struct rp_pkt *pkt;
    size_t size;
} RemotePortDynPkt;

/*
 * Make sure dpkt is allocated and has enough room.
 */

void rp_dpkt_alloc(RemotePortDynPkt *dpkt, size_t size);

void rp_dpkt_swap(RemotePortDynPkt *a, RemotePortDynPkt *b);

/*
 * Check if the dpkt is valid. Used for debugging purposes.
 */

bool rp_dpkt_is_valid(RemotePortDynPkt *dpkt);

/*
 * Invalidate the dpkt. Used for debugging purposes.
 */

void rp_dpkt_invalidate(RemotePortDynPkt *dpkt);

void rp_dpkt_free(RemotePortDynPkt *dpkt);

static inline int rp_get_busaccess_response(struct rp_pkt *pkt)
{
    return (pkt->busaccess_ext_base.attributes & RP_BUS_RESP_MASK) >>
                                                            RP_BUS_RESP_SHIFT;
}
#endif
