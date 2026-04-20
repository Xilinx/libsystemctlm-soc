/*
 * SystemC/TLM-2.0 functional model of the AMD/Xilinx AXI DMA (PG021)
 * (https://docs.amd.com/r/en-US/pg021_axi_dma)
 *
 * Copyright (c) 2026 Advanced Micro Devices Inc.
 * SPDX-License-Identifier: MIT
 *
 * Parameterizd IP configuration options
 * -- mode_sg = c_include_sg           Scatther/Gather or Direct mode
 *                                     (DM to be implemented)
 * -- dma_32 = (c_addr_width <= 32)    _MSB fields of registers and buffer desc.
 *
 * Hard-coded IP configuration options
 * -- c_enable_multi_channel = 0       No multi-channel (replaced by MCDMA: PG288)
 * -- c_num_mm2s_channels = 1
 * -- c_num_s2mm_channels = 1
 * -- c_sg_length_width = 26           Full length in descriptor Control/Status
 * -- c_sg_include_stscntrl_strm = 1   MM2S control stream and S2MM status stream
 * -- c_micro_dma = 0                  No micro mode
 * -- c_include_mm2s = 1               MM2S stream initiator
 * -- c_m_axi_mm2s_data_width = 32     MM2S registers are 32-bit aligned
 * -- c_include_mm2s_dre = 1           MM2S unaligned DMA allowed
 * -- c_include_s2mm = 1               S2MM stream target
 * -- c_sg_use_stsapp_length = 0       No RxLength in S2MM status stream
 * -- c_m_axi_s2mm_data_width = 32     S2MM registers are 32-bit aligned
 * -- c_include_s2mm_dre = 1           S2MM unaligned DMA allowed
 *
 * Other supported features
 * -- Cyclic and non-cyclic descriptor-chains for both directions.
 * -- MM2S stream initiator aborts upon reset, even if there is
 *    back-pressure from target, e.g., stalled by Ethernet MAC
 *    by pause frames from link peer.
 * -- S2MM stream target completes transaction with TLM_GENERIC_ERROR_RESPONSE
 *    upon reset
 *
 * Other non-supported features
 * -- Keyhole mode
 *
 * Limitation
 * -- Loosely-Timed only
 * -- MM2S control stream initiator makes single blocking transaction of
 *    (5*32) bytes before SOF
 * -- S2MM status stream target expects a single blocking transaction;
 *    o Captured data sent to memory on next EOF; before EOF, if given
 *    o Less than (5*32) bytes, data are 0 padded
 *    o More than (5*32) bytes, extra data are dropped,
 *
 * References:
 * -- SG-mode programming sequence:
 *    https://docs.amd.com/r/en-US/pg021_axi_dma/Scatter/Gather-Mode
 * -- Direct-mode programming sequence:
 *    https://docs.amd.com/r/en-US/pg021_axi_dma/Direct-Register-Mode-Simple-DMA
 */
#define SC_INCLUDE_DYNAMIC_PROCESSES

// Placed upfront to ensure self-sufficient header
#include "soc/dma/amd/axidma/axidma.h"

#include <sstream>
#include <iomanip>
#include <cstring>
#include <vector>

#include <systemc>
#include <tlm>
#include <tlm_utils/peq_with_cb_and_phase.h>

#include "tlm-extensions/genattr.h"  // Needed by regapi.h
#include "utils/regapi.h"

using namespace std;
using namespace sc_core;
using namespace sc_dt;
using namespace tlm;
using namespace tlm_utils;

#define HEX(V_) \
    std::hex << std::showbase << std::nouppercase << (V_) << std::dec

#define DBUG(M_) do { \
        if (sc_report_handler::get_verbosity_level() == SC_DEBUG) {      \
            cerr << "DMA: [" << std::setw(15) << sc_time_stamp() << "] " \
                 << "axidma.cc:" << __LINE__ << ": " << M_ << std::endl; \
        }                                                                \
    } while (0)

#define LOG(L_, M_) do { \
        std::ostringstream oss_; \
        oss_ << "axidma.cc:" << __LINE__ << ": " << M_; \
        SC_REPORT_ ## L_("DMA", oss_.str().c_str()); \
    } while (0)

#define LOG_INFO(M_) LOG(INFO, M_)
#define LOG_WARN(M_) LOG(WARNING, M_)
#define LOG_ERROR(M_) LOG(ERROR, M_)
#define LOG_FATAL(M_) LOG(FATAL, M_)

#define LOG_TLM_NOT_OK(T_, M_) do {                     \
        if (!T_.is_response_ok()) {                     \
            LOG_WARN(M_);                               \
        }                                               \
    } while (0)

/*
 * Scatter-gather descriptor layout in host memory
 */
REG32(SG_NXTDESC,     0x00)
REG32(SG_NXTDESC_MSB, 0x04)
REG32(SG_BUFADDR,     0x08)
REG32(SG_BUFADDR_MSB, 0x0C)
REG32(SG_RSVD,        0x10)
REG32(SG_RSVD_MSB,    0x14)
REG32(SG_CONTROL,     0x18)
    FIELD(SG_CONTROL, BuffBytes, 0, 26)
    FIELD(SG_CONTROL, TXEOF, 26, 1)
    FIELD(SG_CONTROL, TXSOF, 27, 1)
REG32(SG_STATUS,      0x1C)
    FIELD(SG_STATUS,  XferBytes, 0, 26)
    FIELD(SG_STATUS,  RXEOF, 26, 1)
    FIELD(SG_STATUS,  RXSOF, 27, 1)
    FIELD(SG_STATUS,  DMAIntErr, 28, 1)
    FIELD(SG_STATUS,  DMASlvErr, 29, 1)
    FIELD(SG_STATUS,  DMADecErr, 30, 1)
    FIELD(SG_STATUS,  ALL_ERRS,  28, 3)
    FIELD(SG_STATUS,  Cmplt, 31, 1)
REG32(SG_APP_0, 0x20)
REG32(SG_APP_1, 0x24)
REG32(SG_APP_2, 0x28)
REG32(SG_APP_3, 0x2C)
REG32(SG_APP_4, 0x30)

enum {
    SG_WORDS = R_SG_APP_4 + 1,
    SG_BYTES = SG_WORDS * 4,
    SG_APP_BYTES = SG_BYTES - A_SG_APP_0,
};

/*
 * Registers common in both SG-mode and Direct-mode
 * The MM2S and S2MM blocks have identical layouts.
 * SG_CTL is given space but not modelled.
 */
REG32(MM2S_BASE, 0x00)
REG32(S2MM_BASE, 0x30)

REG32(DMACR, 0x00)
    FIELD(DMACR, RS, 0, 1)
    FIELD(DMACR, Reset, 2, 1)
    FIELD(DMACR, Keyhole, 3, 1)
    FIELD(DMACR, CyclicBDEnable, 4, 1)
    FIELD(DMACR, ALL_IrqEN, 12, 3)
    FIELD(DMACR, IOC_IrqEN, 12, 1)
    FIELD(DMACR, Dly_IrqEN, 13, 1)
    FIELD(DMACR, Err_IrqEN, 14, 1)
    FIELD(DMACR, IRQThreshold, 16, 8)
    FIELD(DMACR, IRQDelay, 24, 8)
REG32(DMASR, 0x04)
    FIELD(DMASR, Halted, 0, 1)
    FIELD(DMASR, Idle, 1, 1)
    FIELD(DMASR, SGIncld, 3, 1)
    FIELD(DMASR, DMAIntErr, 4, 1)
    FIELD(DMASR, DMASlvErr, 5, 1)
    FIELD(DMASR, DMADecErr, 6, 1)
    FIELD(DMASR, SGIntErr, 8, 1)
    FIELD(DMASR, SGSlvErr, 9, 1)
    FIELD(DMASR, SGDecErr, 10, 1)
    FIELD(DMASR, ALL_Irq, 12, 3)
    FIELD(DMASR, W1C_Irq, 12, 2)
    FIELD(DMASR, IOC_Irq, 12, 1)
    FIELD(DMASR, Dly_Irq, 13, 1)
    FIELD(DMASR, Err_Irq, 14, 1)
    FIELD(DMASR, IRQThresholdSts, 16, 8)
    FIELD(DMASR, IRQDelaySts, 24, 8)

REG32(CURDESC,      0x08)  // SG-mode only
REG32(CURDESC_MSB,  0x0C)
REG32(TAILDESC,     0x10)
REG32(TAILDESC_MSB, 0x14)

REG32(DMA_A,      0x18)    // Direct-mode (non-SG) only
REG32(DMA_A_MSB,  0x1C)
REG32(DMA_LENGTH, 0x28)
    FIELD(DMA_LENGTH, Length, 0, 26)

REG32(SG_CTL, 0x2C)
    FIELD(SG_CTL, SG_CACHE, 0, 4)

enum {
    R_MAX = R_SG_CTL + 1,

    R_DMASR_DMAERR_MASK = R_DMASR_DMAIntErr_MASK |
                          R_DMASR_DMASlvErr_MASK |
                          R_DMASR_DMADecErr_MASK,

    R_DMASR_SG_ERR_MASK = R_DMASR_SGIntErr_MASK |
                          R_DMASR_SGSlvErr_MASK |
                          R_DMASR_SGDecErr_MASK,

    R_DMASR_ERRS_MASK   = R_DMASR_DMAERR_MASK |
                          R_DMASR_SG_ERR_MASK,

    R_DMASR_IRQS_MASK   = R_DMASR_IOC_Irq_MASK |
                          R_DMASR_Dly_Irq_MASK |
                          R_DMASR_Err_Irq_MASK,

    R_DMACR_IENS_MASK   = R_DMACR_IOC_IrqEN_MASK |
                          R_DMACR_Dly_IrqEN_MASK |
                          R_DMACR_Err_IrqEN_MASK,
};

/*
 * Although documentation states that R_DMASR_Err_Irq_MASK bit is W1C,
 * in reality that is not true because it is stuck at 1 when any bit
 * of R_DMASR_ERRS_MASK is 1, which can ONLY be cleared by DMACR.Reset
 */
static const regapi_info<uint32_t> axidma_reginfo[] = {
    {    .name =  "DMACR",     .ro = 0x8fe2,
                               .reset = (1U << R_DMACR_IRQThreshold_SHIFT) |
                                        (1U << 1),
         .addr = A_DMACR,
    }, { .name =  "DMASR",     .ro = ~((uint32_t)R_DMASR_Dly_Irq_MASK |
                                       (uint32_t)R_DMASR_IOC_Irq_MASK),
                               .w1c = (uint32_t)R_DMASR_Dly_Irq_MASK |
                                      (uint32_t)R_DMASR_IOC_Irq_MASK,
                               .reset = (1 << R_DMASR_Halted_SHIFT) |
                                        (1 << R_DMASR_IRQThresholdSts_SHIFT),
         .addr = A_DMASR,
    }, { .name =  "CURDESC",   .ro = 0x3f,
         .addr = A_CURDESC,
    }, { .name =  "CURDESC_MSB",
         .addr = A_CURDESC_MSB,
    }, { .name =  "TAILDESC",  .ro = 0x3f,
         .addr = A_TAILDESC,
    }, { .name =  "TAILDESC_MSB",
         .addr = A_TAILDESC_MSB,
    }, { .name =  "DMA_A",
         .addr = A_DMA_A,
    }, { .name =  "DMA_A_MSB",
         .addr = A_DMA_A_MSB,
    }, { .name =  "DMA_LENGTH",.ro = ~((1U << 26) - 1),
         .addr = A_DMA_LENGTH,
    }, { .name =  "SG_CTL",    .ro = 0xf0,
                               .reset = 0x0f,
         .addr = A_SG_CTL,
    },

    {}
};

/*
 * Helper functions
 */
typedef sc_dt::uint64 tlm_addr_t;  // Address used by TLM generic payloads

static uint32_t axidma_reg_ini_value(unsigned rn)
{
    uint64_t addr = rn * 4;

    for (auto *pi = &axidma_reginfo[0]; pi->name; pi++) {
        if (pi->addr == addr) {
            return pi->reset;
        }
    }

    return 0;
}

static tlm_addr_t le64_p(const uint32_t *p32)
{
    tlm_addr_t a = p32[1];
    return (a << 32) | p32[0];
}

static void le64_store(uint32_t *p32, tlm_addr_t v64)
{
    p32[0] = (uint32_t)(v64 & 0xFFFFFFFFU);
    p32[1] = (uint32_t)(v64 >> 32);
}

static uint32_t cpu32_dp(uint32_t rv, unsigned b0, unsigned n, uint32_t fv)
{
    uint32_t mask = (~0U >> (32 - n)) << b0;

    fv = (fv << b0) & mask;
    rv = (rv & ~mask) | fv;
    return rv;
}

#define RVFLD_DP(v_, r_, f_, fv_)               \
    cpu32_dp((v_),                              \
             R_ ## r_ ## _ ## f_ ## _SHIFT,     \
             R_ ## r_ ## _ ## f_ ## _LENGTH,    \
             (fv_))

#define RVFLD_EX(v_, r_, f_) \
    ((uint32_t)FIELD_EX(v_, r_, f_))

/*
 * Short hand notation for SC_MANY_WRITERS objects
 */
template<typename T>
using mwr_signal = sc_signal<T, SC_MANY_WRITERS>;

template<typename T>
using mwr_buffer = sc_buffer<T, SC_MANY_WRITERS>;

/*
 * An aggregate to bundle IP's configured options and other static data
 */
struct axidma_cfg
{
    explicit axidma_cfg(const char *tag,
                        amd_axidma *o,
                        bool mode_sg,
                        bool addr_32,
                        sc_dt::uint64 clk_in_hz) :
        dtag(tag),
        mm2s(tag[0] == 'M'),
        sg(mode_sg),
        a32(addr_32),
        clk_hz(clk_in_hz),
        xpi(*o)
    {
        // 1 IRQDelay timer tick == 125 cycles at clk_hz
        auto ns = clk_hz;
        ns = 125;
        ns = (ns * 1000 * 1000 * 1000) / clk_hz;

        idt_interval = sc_time((double)ns, SC_NS);
    }

    std::string dtag;
    bool mm2s;
    bool sg;
    bool a32;
    sc_dt::uint64 clk_hz;
    sc_time idt_interval;

    amd_axidma& xpi;  // For all to reach the top-level wrapper
};

/*
 * Register block
 */
class axidma_rb : public regapi_block<uint32_t, R_MAX>
{
protected:
    typedef regapi_block<uint32_t, (R_SG_CTL + 1)> base_type;

public:
    axidma_cfg& cfg;

    explicit axidma_rb(sc_module_name name, axidma_cfg& c, bool debug=false) :
        base_type(name, axidma_reginfo, debug),
        cfg(c)
    {
        this->reg_reset_all();
    }

    using base_type::reg_reset_all;

    void reg_reset_all() {
        base_type::reg_reset_all();

        if (cfg.sg) {
            regs[R_DMASR] |= R_DMASR_SGIncld_MASK;
        }
    }

    virtual std::string debug_prefix() override {
        std::ostringstream oss;
        oss << "REG: [" << std::setw(15) << sc_time_stamp() << "]";
        return oss.str();
    }
};

/*
 * A number of AXIDMA registers are actually requests and responses
 * as a bundle.
 *
 * When they are written by host driver, particular writes trigger
 * the evaluation as a request bundle.
 *
 * When responses are produced by the model, the responses must be
 * made visible as a bundle.
 *
 * For deterministic evaluation of a request bundle and deterministic
 * presentation of a response bundle, this model uses the semantics
 * of sc_prim_channel to "copy" a bundle crossing the boundary in the
 * update phase of a delta cycle.
 */
template <typename T>  // Caveat: only integer-like T is supported
class axidma_buf : public sc_buffer<T, SC_UNCHECKED_WRITERS>
{
private:
    typedef sc_buffer<T, SC_UNCHECKED_WRITERS> scbuf_type;

public:
    typedef typename scbuf_type::value_type value_type;
    typedef axidma_buf<T> base_type;

    explicit axidma_buf(const char *name_) :
        scbuf_type(name_)
    {
        reset();
    }

    explicit axidma_buf(const char *name_, const value_type& rst_v_) :
        scbuf_type(name_, rst_v_)
    {
        m_rst_v = rst_v_;
        reset();
    }

protected:
    mutable uint32_t m_rcnt = 0; // need updated from read() override
    uint32_t m_wcnt = 0;

    // Use own state to avoid hacking into the base class
    value_type m_rst_v = 0;
    value_type m_prv_v = 0;
    value_type m_cur_v = 0;
    value_type m_new_v = 0;

public:
    virtual void write(const value_type& v_) override {
        m_new_v = v_;
        scbuf_type::write(v_);
    }

    virtual const value_type& read() const override {
        catchup();
        return m_cur_v;
    }

    virtual void print(::std::ostream& os_) const override {
        os_ << m_cur_v; // Don't invoke catchup()
    }

    virtual void reset() {
        m_wcnt  = 0;
        m_rcnt  = 0;
        m_prv_v = m_rst_v;
        m_cur_v = m_rst_v;
        m_new_v = m_rst_v;
    }

    T changes() const {
        return read() ^ m_prv_v;
    }

    T negedges() const {
        return changes() & m_prv_v;
    }

    T posedges() const {
        return changes() & m_cur_v;
    }

    bool updated() const {
        return m_rcnt != m_wcnt;
    }

    void catchup() const { // const for read() to call
        m_rcnt = m_wcnt;   // m_rcnt declared mutable
    }

    void go_update() {
        scbuf_type::write(0);  // a fake write to trigger update
    }

protected:
    virtual void update() {
        if (!updated()) {
            m_prv_v = m_cur_v; // only if m_cur_v has been read
        }
        m_cur_v = m_new_v;

        m_wcnt = m_rcnt + 1;   // update implies written
        scbuf_type::update();
    }
};

class axidma_r32 : public axidma_buf<uint32_t>
{
public:
    typedef axidma_buf<uint32_t> base_type;

    explicit axidma_r32(const char *name, axidma_rb& r, unsigned n) :
        base_type(name, axidma_reg_ini_value(n)),
        rb(r),
        rn(n)
    {}

protected:
    axidma_rb& rb;
    unsigned   rn;
};

class axidma_r64 : public axidma_buf<tlm_addr_t>
{
public:
    typedef axidma_buf<tlm_addr_t> base_type;

    explicit axidma_r64(const char *name, axidma_rb& r, unsigned n) :
        base_type(name), // 64b regs don't have non-zero reset value
        rb(r),
        rn(n)
    {}

protected:
    axidma_rb& rb;
    unsigned   rn;
};

class axidma_in32 : public axidma_r32
{
public:
    typedef axidma_r32 base_type;

    explicit axidma_in32(const char *name, axidma_rb& r, unsigned n) :
        base_type(name, r, n)
    {}

protected:
    virtual void update() override {
        m_new_v = rb.regs[rn];
        base_type::update();
    }

private:
    // write() of this class should NEVER be used; instead, the new
    // value is always from rb.regs[rn]
    virtual void write(const value_type& v) override {}
};

class axidma_in64 : public axidma_r64
{
public:
    typedef axidma_r64 base_type;

    explicit axidma_in64(const char *name, axidma_rb& r, unsigned n) :
        base_type(name, r, n)
    {}

protected:
    virtual void update() override {
        m_new_v = le64_p(&rb.regs[rn]);
        base_type::update();
    }

private:
    // write() of this class should NEVER be used; instead, the new
    // value is always from rb.regs[rn]
    virtual void write(const value_type& v) override {}
};

class axidma_out32 : public axidma_r32
{
public:
    typedef axidma_r32 base_type;

    explicit axidma_out32(const char *name, axidma_rb& r, unsigned n) :
        base_type(name, r, n)
    {}

    // For out-to-rb buffer, the only readers are internal logics,
    // which needs immediate visibility into what those logics have
    // written in the same evaluation phase
    virtual const value_type& read() const override {
        return m_new_v;
    }

protected:
    virtual void update() override {
        base_type::update();
        rb.regs[rn] = m_cur_v;
    }
};

class axidma_out64 : public axidma_r64
{
public:
    typedef axidma_r64 base_type;

    explicit axidma_out64(const char *name, axidma_rb& r, unsigned n) :
        base_type(name, r, n)
    {}

    // For out-to-rb buffer, the only readers are internal logics,
    // which needs immediate visibility into what those logics has
    // written in the same evaluation phase
    const value_type& read() const override {
        return m_new_v;
    }

protected:
    virtual void update() override {
        base_type::update();
        le64_store(&rb.regs[rn], m_cur_v);
    }
};

class axidma_cr : public axidma_in32
{
public:
    typedef axidma_in32 base_type;

    explicit axidma_cr(const char *name, axidma_rb& r) :
        base_type(name, r, R_DMACR)
    {}

    unsigned dly_cnt() {
        return RVFLD_EX(read(), DMACR, IRQDelay);
    }

    unsigned ioc_cnt() {
        return RVFLD_EX(read(), DMACR, IRQThreshold);
    }

    uint32_t irqs_en() {
        return read() & R_DMACR_ALL_IrqEN_MASK;
    }

    bool cbd() {
        return RVFLD_EX(read(), DMACR, CyclicBDEnable);
    }

    bool rst() {
        return RVFLD_EX(read(), DMACR, Reset);
    }

    bool rst_posedge() {
        return RVFLD_EX(posedges(), DMACR, Reset);
    }

    bool rst_negedge() {
        return RVFLD_EX(negedges(), DMACR, Reset);
    }

    bool rs() {
        return RVFLD_EX(read(), DMACR, RS);
    }

    bool rs_posedge() {
        return RVFLD_EX(posedges(), DMACR, RS);
    }

    bool rs_negedge() {
        return RVFLD_EX(negedges(), DMACR, RS);
    }

    void clear_rs() { // A backdoor for sr.set_err_*()
        m_cur_v &= ~R_DMACR_RS_MASK;
        m_new_v &= ~R_DMACR_RS_MASK;
        rb.regs[rn] &= ~R_DMACR_RS_MASK;
    }
};

class axidma_sr : public axidma_out32
{
public:
    typedef axidma_out32 base_type;

    explicit axidma_sr(const char *name, axidma_rb& r, axidma_cr& c, bool sg) :
        base_type(name, r, R_DMASR),
        cr(c)
    {
        if (sg) {
            m_rst_v |= R_DMASR_SGIncld_MASK;
            reset();
        }
    }

private:
    axidma_cr& cr;

protected:
    virtual void update() override {
        base_type::update();

        if (RVFLD_EX(m_cur_v, DMASR, Halted)) {
            // The only CR bit that internal logic would write to
            rb.regs[R_DMACR] &= ~R_DMACR_RS_MASK;
        }
    }

public:
    unsigned dly_sts() {
        return RVFLD_EX(read(), DMASR, IRQDelaySts);
    }

    unsigned ioc_sts() {
        return RVFLD_EX(read(), DMASR, IRQThresholdSts);
    }

    uint32_t irqs() {
        return read() & R_DMASR_ALL_Irq_MASK;
    }

    uint32_t w1c_irqs() {
        return read() & R_DMASR_W1C_Irq_MASK;
    }

    uint32_t errs() {
        return read() & R_DMASR_ERRS_MASK;
    }

    bool idle() {
        return RVFLD_EX(read(), DMASR, Idle);
    }

    bool halted() {
        return RVFLD_EX(read(), DMASR, Halted);
    }

    void set_dly_sts(unsigned v) {
        write(RVFLD_DP(read(), DMASR, IRQDelaySts, v));
    }

    void set_ioc_sts(unsigned v) {
        write(RVFLD_DP(read(), DMASR, IRQThresholdSts, v));
    }

    void set_idle(bool v) {
        write(RVFLD_DP(read(), DMASR, Idle, v));
    }

    void set_halted(bool v) {
        write(RVFLD_DP(read(), DMASR, Halted, v));
    }

    void set_dly_irq(bool v) {
        write(RVFLD_DP(read(), DMASR, Dly_Irq, v));
    }

    void set_ioc_irq(bool v) {
        write(RVFLD_DP(read(), DMASR, IOC_Irq, v));
    }

    void set_err_sgint() {
        set_err(R_DMASR_SGIntErr_MASK);
    }

    void set_err_dmaint() {
        set_err(R_DMASR_DMAIntErr_MASK);
    }

protected:
    void set_err(uint32_t causes) {
        sc_assert(causes);  // Only CR.Reset can clear
        set_halted(true);
        cr.clear_rs();
        write(read() | (causes | R_DMASR_SGIntErr_MASK));
    }
};

class axidma_sr_in : public axidma_buf<uint32_t>
{
public:
    typedef axidma_buf<uint32_t> base_type;

    axidma_sr_in(const char *name) : base_type(name) {}

    uint32_t w1c_irqs() {
        return read() & R_DMASR_W1C_Irq_MASK;
    }

    void write(const unsigned char *dptr) {
        uint32_t v;

        std::memcpy(&v, dptr, sizeof(v));
        base_type::write(v & R_DMASR_W1C_Irq_MASK);
    }

private:
    // normal write() of this class should NEVER be used.
    virtual void write(const value_type& v) override {}
};

class axidma_regs : public axidma_rb
{
public:
    axidma_cr    cr;
    axidma_in64  head;
    axidma_in64  tail;
    axidma_in64  dptr;
    axidma_in32  dlen;

    axidma_sr    sr;
    axidma_sr_in sr_in;    // To handle w1c
    axidma_out64 head_out; // To update R_CURDESC during run
    axidma_out32 dlen_out; // To update R_DMA_LENGTH for DM-IOC

public:
    explicit axidma_regs(sc_module_name name, axidma_cfg& c) :
        axidma_rb(name, c),
        cr   ("cr_in",   *this),
        head ("head_in", *this, R_CURDESC),
        tail ("tail_in", *this, R_TAILDESC),
        dptr ("dptr_in", *this, R_DMA_A),
        dlen ("dlen_in", *this, R_DMA_LENGTH),
        sr   ("sr_out",  *this, cr, c.sg),
        sr_in("sr_in"),
        head_out("head_out", *this, R_CURDESC),
        dlen_out("dlen_out", *this, R_DMA_LENGTH)
    {}

    void reset() {
        reg_reset_all();
        cr.reset();
        head.reset();
        tail.reset();
        dptr.reset();
        dlen.reset();
        sr.reset();
        sr_in.reset();
        head_out.reset();
        dlen_out.reset();
    }

    void b_transport(tlm_generic_payload& tr, sc_time& delay) {
        /*
         * When Linux is configured with CONFIG_PHYS_ADDR_T_64BIT, the
         * xilinx_axienet driver from AMD-EDF Linux issues a single
         * 64-bit wide access to those registers with _MSB upper 32 bits.
         *
         * However, regapi_block for axidma is defined as uint32_t, and
         * all access sizes != 4 bytes are rejected with error.
         *
         * So the only option here is to break up the transaction into 2
         * so access can be handled AND traced/logged properly.
         *
         * This must be done even if this module has been instantiated
         * to support only 32-bit DMA because the Linux driver simply
         * ignores the device-tree's setting when accessing those
         * registers.  However, in that case, reads from upper 32 bits
         * can simply return 0, while writes can be simply dropped.
         *
         * To ensure correct action trigger, the _MSB part must be
         * the 2nd transaction.
         *
         * There is no need to adjust 'delay' for 2nd transaction
         * because registers accesses are modelled without latency.
         */
        if (tr.get_data_length() != 8) {
            b_transport_32(tr, delay);
            return;
        }

        tr.set_data_length(4);
        b_transport_32(tr, delay);
        if (tr.get_response_status() == tlm::TLM_OK_RESPONSE) {
            unsigned char *dptr = tr.get_data_ptr();

            tr.set_address(tr.get_address() + 4);
            tr.set_data_ptr(dptr + 4);
            b_transport_32(tr, delay);

            tr.set_data_ptr(dptr);
        }

        tr.set_data_length(8);
    }

    void b_transport_32(tlm_generic_payload& tr, sc_time& delay) {
        tlm_addr_t ra = tr.get_address();

        // Reject invalid access
        if (!!(ra & 3)) {
            LOG_WARN(cfg.dtag << "Rejected unaligned access to" <<
                     " addr=" << HEX(ra));
            tr.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
            return;
        }

        if (ra >= sizeof(regs)) {
            LOG_WARN(cfg.dtag << "Rejected out-of-bound access to" <<
                     " addr=" << HEX(ra));
            tr.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
            return;
        }

        bool is_write = tr.is_write();
        unsigned rn = ra / 4;

        // For 32-bit DMA, ignores all writes to _MSB.  Reads are fine
        // because they are reset to 0.
        if (is_write && cfg.a32) {
            switch (rn) {
            case R_CURDESC_MSB:
            case R_TAILDESC_MSB:
            case R_DMA_A_MSB:
                tr.set_response_status(tlm::TLM_OK_RESPONSE);
                return;
            }
        }

        // Ignore writes to unimplemented registers.  Reads are fine
        // because they are reset to 0.
        if (is_write && cfg.sg) {
            switch (rn) {
            case R_DMA_A ... R_DMA_LENGTH:
                LOG_WARN(cfg.dtag << "SG-mode ignores writes to" <<
                         " addr=" << HEX(ra));
                return;
            }
        } else if (is_write) {
            switch (rn) {
            case R_CURDESC ... R_TAILDESC_MSB:
            case R_SG_CTL  ... R_SG_CTL:
                LOG_WARN(cfg.dtag << "Direct-mode ignores writes to" <<
                         " addr=" << HEX(ra));
                return;
            }
        }

        // Ignore writes to selected registers when they become
        // read-only (DMACR.RS bit must be checked immediately).
        if (is_write &&
            (!sr.halted() || RVFLD_EX(regs[R_DMACR], DMACR, RS))) {
            switch (rn) {
            case R_CURDESC:
            case R_CURDESC_MSB:
            case R_DMA_A:
            case R_DMA_A_MSB:
            case R_DMA_LENGTH:
                LOG_WARN(cfg.dtag << "Running ignores writes to" <<
                         " addr=" << HEX(ra));
                return;
            }
        }

        // Now let the access go through
        uint32_t prv_v = (rn < R_MAX) ? regs[rn] : 0;
        reg_b_transport(tr, delay);
        if (tr.get_response_status() != tlm::TLM_OK_RESPONSE) {
            return;
        }
        if (!is_write) {
            return;
        }

        // Write latching and action trigger.
        // There is no requirment of write-order for R_CURDESC and R_DMA_A
        rn = (cfg.a32 && rn == R_TAILDESC) ? (unsigned)R_TAILDESC_MSB : rn;
        switch (rn) {
        case R_DMACR:
            if (sr.errs() || !!(regs[R_DMASR] & R_DMASR_ERRS_MASK)) {
                // CR.RS bit is stuck at 0 until CR.Reset clears the errors
                regs[rn] = RVFLD_DP(regs[rn], DMACR, RS, 0);
            }
            if (RVFLD_EX(regs[R_DMACR], DMACR, IRQThreshold) == 0) {
                // Writing 0 to this field has no effect
                regs[rn] = RVFLD_DP(regs[rn], DMACR, IRQThreshold,
                                    RVFLD_EX(prv_v, DMACR, IRQThreshold));
            }
            cr.go_update();
            break;
        case R_CURDESC:
        case R_CURDESC_MSB:
            head.go_update();
            break;
        case R_TAILDESC_MSB:
            tail.go_update();
            break;
        case R_DMA_A:
        case R_DMA_A_MSB:
            dptr.go_update();
            break;
        case R_DMA_LENGTH:
            dlen.go_update();
            break;
        case R_DMASR:
            // Need to capture the TR value to extract W1C bits
            // because they are not in regs[R_DMASR].
            sr_in.write(tr.get_data_ptr());
            break;
        }
    }
};

/*
 * Host memory access wrapper.
 *
 * Via R_SG_CONTROL.BuffBytes and R_DMA_LENGTH.Length fields,
 * a single DMA transfer size is limited to be (2^26 - 1) bytes.
 */
class axidma_dma : public sc_module
{
public:
    explicit axidma_dma(sc_module_name name, axidma_cfg& c) :
        sc_module(name),
        cfg(c)
    {}

    axidma_cfg& cfg;

    bool fetch(unsigned char *dptr, tlm_addr_t addr, unsigned len) {
        return access(tlm::TLM_READ_COMMAND, dptr, addr, len);
    }

    bool store(tlm_addr_t addr, unsigned char *dptr, unsigned len) {
        return access(tlm::TLM_WRITE_COMMAND, dptr, addr, len);
    }

private:
    bool access(tlm::tlm_command cmd, unsigned char *dptr,
                tlm_addr_t addr, unsigned len)
    {
        if (cfg.a32) {
            addr = (uint32_t)addr;
        }

        tlm_generic_payload tr;

        tr.set_command(cmd);
        tr.set_address(addr);
        tr.set_data_ptr(dptr);
        tr.set_data_length(len);
        tr.set_streaming_width(len);
        tr.set_dmi_allowed(false);
        tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

        sc_time delay = SC_ZERO_TIME;
        cfg.xpi.dma_init_socket->b_transport(tr, delay);

        const char *e;
        switch (tr.get_response_status()) {
        case tlm::TLM_OK_RESPONSE:
            return true;
        case tlm::TLM_INCOMPLETE_RESPONSE:
            e = "INCOMPLETE";
            break;
        case tlm::TLM_GENERIC_ERROR_RESPONSE:
            e = "GENERIC_ERROR";
            break;
        case tlm::TLM_ADDRESS_ERROR_RESPONSE:
            e = "ADDRESS_ERROR";
            break;
        case tlm::TLM_COMMAND_ERROR_RESPONSE:
            e = "COMMAND_ERROR";
            break;
        case tlm::TLM_BURST_ERROR_RESPONSE:
            e = "BURST_ERROR";
            break;
        case tlm::TLM_BYTE_ENABLE_ERROR_RESPONSE:
            e = "BYTE_ENABLE_ERROR";
            break;
        default:
            e = "UNKNOWN_TLM_STATUS";
        }

        const char *c = (cmd == tlm::TLM_READ_COMMAND ? "Read" : "Write");
        LOG_WARN(cfg.dtag << "DMA-" << c <<
                 " TLM error: TLM_" << e << "_RESPONSE");

        if (cmd == tlm::TLM_READ_COMMAND) {
            std::memset(dptr, 0, len);  // Return all 0 on error
        }
        return false;
    }
};

/*
 * Data stream mover run-control constants
 */
enum {
    DSM_RUNC_UNDEF = 0,
    DSM_RUNC_IN_RST,
    DSM_RUNC_IN_GO,
    DSM_RUNC_IN_STOP,

    DSM_RUNC_OUT_IOC,              // 4 kinds of IOC (EOF=0/1, (H==T)=T/F
    DSM_RUNC_OUT_IOC_STALLED,
    DSM_RUNC_OUT_IOC_EOF,
    DSM_RUNC_OUT_IOC_EOF_STALLED,

    DSM_RUNC_OUT_STOPPED,
    DSM_RUNC_OUT_ERR_SGINT,
    DSM_RUNC_OUT_ERR_DMAINT,
};

/*
 * MM2S data stream mover
 */
class axidma_mdm : public sc_module,
                   public tlm::tlm_mm_interface
{
public:
    class ds_reader {  // Interface: reads data from host memory
    public:
        virtual ~ds_reader() = default;
        virtual unsigned b_fetch(tlm_addr_t& dma_addr, bool& eof,
                                 unsigned char *dptr, unsigned dlen) = 0;
    };

    explicit axidma_mdm(sc_module_name name, axidma_cfg& c,
                        ds_reader *sg, ds_reader *dm) :
        sc_module(name),
        cfg(c),
        stream_dma(c.sg ? sg : dm),
        stream_stop("stream_stop_ev"),
        stream_cmplt("stream_cmplt_ev")
    {
        // Danger!! both *sg and *dm may not be constructed yet
        sc_assert(stream_dma && "BUG: null ds_reader given");
    }

private:
    axidma_cfg& cfg;
    ds_reader*  stream_dma;
    sc_event    stream_stop;
    sc_event    stream_cmplt;
    tlm_generic_payload *stream_tr = nullptr;

public:
    void stop() {
        stream_stop.notify();
    }

    unsigned b_transfer(bool& aborted) {
        aborted = false;

        // Transfer at most one buffer-ful, with caller responsible for
        // calling multiple times to transfer host data in one contiguous
        // memory block.
        unsigned dlen = 8 * 1024;
        unsigned char *dptr;

        // Get/make a payload object, reuse if was completed gracefully
        auto tr = stream_tr;
        if (tr) {
            dptr = tr->get_data_ptr();
            tr->reset();
        } else {
            // Allow an 8-byte aligned buffer and a sticky extension
            auto bsz = sizeof(tlm_addr_t);
            bsz = (dlen + bsz - 1) / bsz;
            dptr = reinterpret_cast<unsigned char *>(new tlm_addr_t[bsz]);

            stream_tr = new tlm_generic_payload(this);
            stream_tr->acquire();  // Keep it as reusable

            tr = stream_tr;
            tr->set_extension(new genattr_extension());
            tr->set_data_ptr(reinterpret_cast<unsigned char *>
                             (new tlm_addr_t[dlen / 8]));
        }

        // Load data from host memory and gets back dma_addr for logging
        tlm_addr_t dma_addr;
        bool eof = false;
        dlen = stream_dma->b_fetch(dma_addr, eof, dptr, dlen);

        // Prepare TLM payload
        tr->get_extension<genattr_extension>()->set_eop(eof);
        tr->set_data_ptr(dptr);
        tr->set_data_length(dlen);
        tr->set_streaming_width(dlen);

        tr->set_command(tlm::TLM_WRITE_COMMAND);
        tr->set_address(0);
        tr->set_dmi_allowed(false);
        tr->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

        // Push payload to stream target and watch for abandonment,
        // e.g., host-driver resets after mm2s stream target is
        // stalled for too long (e.g., non-stop Ethernet pause frames).
        auto& sk = cfg.xpi.mm2s_stream_socket;
        sc_time delay = SC_ZERO_TIME;
        tlm_phase tr_ph = tlm::BEGIN_REQ;
        tlm_sync_enum status;

        tr->acquire();
        status = sk->nb_transport_fw(*tr, tr_ph, delay);

        if (status != tlm::TLM_ACCEPTED) {
            // Immediate completion
            DBUG(cfg.dtag << "Stream-push done=immd" <<
                 " dma_addr=" << HEX(dma_addr) <<
                 " len=" << dlen <<
                 " tlm_resp=" << tr->get_response_status());

            if ((status == tlm::TLM_UPDATED) && (tr_ph == tlm::BEGIN_RESP)) {
                tr_ph = tlm::END_RESP;
                sk->nb_transport_fw(*tr, tr_ph, delay);
            }

            tr->release();  // For pre-fw acqure, reuse retained.
            return dlen;
        }

        // Wait for done from nb_transport_bw or abandone event
        wait(stream_cmplt | stream_stop);

        if (stream_cmplt.triggered()) {
            // Completed normally
            DBUG(cfg.dtag << "Stream-push done=resp" <<
                 " dma_addr=" << HEX(dma_addr) <<
                 " len=" << dlen <<
                 " tlm_resp=" << tr->get_response_status());

            // The pre-fw acquire has been released by _bw().
            return dlen;
        }

        // Aborted, and the abandoned TR is no longer reusable because
        // the TR may still be owned by the stream target.
        sc_assert(stream_stop.triggered());
        DBUG(cfg.dtag << "Stream-push done=resp" <<
             " dma_addr=" << HEX(dma_addr) <<
             " len=" << dlen <<
             " eof=" << eof);

        // For abandoned TR, release the allocation acquire, and
        // the pre-fw acquire will be released by _bw().
        stream_tr->release();
        stream_tr = nullptr;

        aborted = true;
        return 0;
    }

    tlm_sync_enum nb_transport_bw(tlm_generic_payload& tr,
                                  tlm_phase& phase,
                                  sc_time& delay) {
        if (phase != tlm::BEGIN_RESP) {
            return TLM_ACCEPTED;
        }

        if (&tr == stream_tr) {
            stream_cmplt.notify();
        }

        // It is critical to decrement the refcnt here for the pre-fw acquire
        // by axidma_mdm.b_transfer().
        //
        // If axidma_mdm.b_transfer() has abandoned this TR, this release
        // frees the TR.
        //
        // If axidma_mdm.b_transfer() still waits for this, this release
        // is paired to the pre-fw acquire.
        tr.release();
        phase = tlm::END_RESP;
        return TLM_COMPLETED;
    }

    virtual void free(tlm_generic_payload *tr) { // tlm_mm_interface::free()
        if (tr == stream_tr) {
            tr->reset(); // Reuse if completed gracefully.
            return;
        }

        // Discard the abandoned one
        delete tr->get_data_ptr();

        auto genattr = tr->get_extension<genattr_extension>();
        if (genattr) {
            tr->release_extension(genattr);
        }

        delete tr;
    }
};

/*
 * S2MM data stream mover
 */
class axidma_sdm : public sc_module
{
public:
    SC_HAS_PROCESS(axidma_sdm);

    class ds_writer {  // Interface: writes data to host memory
    public:
        virtual ~ds_writer() = default;
        virtual unsigned b_store(unsigned char *dptr,
                                 unsigned dlen, bool eof_in) = 0;
    };

    explicit axidma_sdm(sc_module_name name, axidma_cfg& c,
                         ds_writer *sg, ds_writer *dm) :
        sc_module(name),
        cfg(c),
        stream_dma(c.sg ? sg : dm),
        stream_received("stream_recvd_ev")
    {
        // Danger!! Both *sg and *dm may not be constructed yet
        sc_assert(stream_dma && "BUG: null ds_writer given");

        SC_THREAD(stream_thread);
    }

private:
    axidma_cfg& cfg;
    ds_writer*  stream_dma;
    sc_event    stream_received;
    tlm_generic_payload *stream_tr = nullptr;

public:
    tlm_sync_enum nb_transport_fw(tlm_generic_payload& tr,
                                  tlm_phase& phase,
                                  sc_time& delay) {
        if (phase == tlm::END_RESP) {
            return tlm::TLM_COMPLETED;
        }

        sc_assert(phase == tlm::BEGIN_REQ && "BUG: Phase unexpected");

        // Forward payload to worker, who will send only BEGIN_RESP
        // to imply END_REQ; thus, the s2mm stream initiator peer
        // must not violate TLM restriction by issuing another TR
        // until END_REQ (explicit or implied).
        sc_assert(!stream_tr && "BUG: S2MM stream target gets multiple TRs");
        stream_tr = &tr;

        DBUG(cfg.dtag << "Received new stream-push" << " len=" << tr.get_data_length());

        stream_received.notify(delay);
        return tlm::TLM_ACCEPTED;
    }

private:
    void stream_thread() {
        while (true) {
            wait(stream_received);
            if (!stream_tr) {
                continue;
            }

            auto& tr = *stream_tr;
            auto  tr_len = tr.get_data_length();
            auto  tr_buf = tr.get_data_ptr();
            bool  ok;

            // TR is assumed EOF if no genattr given (like for Direct mode)
            auto genattr = tr.get_extension<genattr_extension>();
            bool tr_eof = !genattr || genattr->get_eop();

            // This thread will not miss another stream_received event
            // even if stream_dma->b_store() blocks because only one
            // TLM payload can be outstanding due to BEGIN_RESP withheld
            // until data has been stored.
            ok = stream_dma->b_store(tr_buf, tr_len, tr_eof);

            tr.set_response_status(ok ? tlm::TLM_OK_RESPONSE
                                      : tlm::TLM_GENERIC_ERROR_RESPONSE);

            tlm_phase phase = tlm::BEGIN_RESP;
            sc_time delay = SC_ZERO_TIME;

            stream_tr = nullptr;
            cfg.xpi.s2mm_stream_socket->nb_transport_bw(tr, phase, delay);
        }
    }
};

/*
 * Scatter-gather data mover.
 */
class axidma_sg : public sc_module
{
public:
    sc_buffer<bool>       cbd_in;
    sc_buffer<unsigned>   runc_in;
    sc_buffer<tlm_addr_t> head_in;
    sc_buffer<tlm_addr_t> tail_in;

    sc_out<unsigned>      runc_out;
    sc_out<tlm_addr_t>    head_out;
    sc_out<tlm_addr_t>    next_out;

    explicit axidma_sg(sc_module_name name, axidma_dma& dma_a) :
        sc_module(name),
        cbd_in ("cbd_in"),
        runc_in("runc_in"),
        head_in("head_in"),
        tail_in("tail_in"),
        runc_out("runc_out"),
        head_out("head_out"),
        next_out("next_out"),
        dma(dma_a),
        cfg(dma.cfg),
        runc_enb("runc_enb")
    {
        sc_assert(cfg.sg && "BUG: AXIDMA not configured for SG");
        reset();

        // Initial state is running disabled
        runc_dis = runc_enb + 1;
    }

protected:
    axidma_dma& dma;
    axidma_cfg& cfg;

    // State tracking
    sc_buffer<unsigned> runc_enb;
    unsigned runc_dis;
    enum {
        SGS_UNDEF = 0,
        SGS_ACTIVE,
        SGS_CMPLT,
    } state;

    tlm_addr_t desc_addr;
    tlm_addr_t next_addr;
    tlm_addr_t data_addr;
    tlm_addr_t sof_addr;
    tlm_addr_t eof_addr;

    // Parsed info from current descriptor
    unsigned data_len;
    unsigned data_pos;
    uint8_t  app_pos;
    bool     sof;
    bool     eof;

    uint32_t raw[SG_WORDS];

    void reset() {
        undef();
        desc_addr = 0;
        next_addr = 0;
        data_addr = 0;
        app_pos = 0;
        sof = true;
        eof = false;
        std::memset(raw, 0, sizeof(raw));
    }

    bool can_run() { return runc_dis == runc_enb; }

    void do_start() {
        sc_assert(!can_run() && "BUG: SG still active");

        if (head_in.event() || state == SGS_UNDEF) {
            next_addr = head_in;
        }
        runc_enb.write(runc_dis);
    }

    void notify_stop() {
        runc_enb.write(runc_dis + 1);
    }

    void set_stopped() { set_halted(DSM_RUNC_OUT_STOPPED); }

    void set_halted(unsigned cause) {
        runc_dis = runc_enb + 1;
        runc_out.write(cause);

        DBUG(cfg.dtag << "SG-chain halted.  cause=" << cause);
    }

    void set_cmplt(bool stalled) {
        if (stalled) {
            set_halted(eof ? DSM_RUNC_OUT_IOC_EOF_STALLED
                           : DSM_RUNC_OUT_IOC_STALLED);
        } else {
            runc_out.write(eof ? DSM_RUNC_OUT_IOC_EOF
                               : DSM_RUNC_OUT_IOC);
        }
    }

    void undef() {
        sof_addr = 1;
        eof_addr = 1;
        data_pos = 0;
        data_len = 0;
        state = SGS_UNDEF;
    }

    unsigned char *raw_ptr(unsigned rn) {
        sc_assert(rn < SG_WORDS);
        return reinterpret_cast<unsigned char *>(&raw[rn]);
    }

    unsigned char *app_ptr() {
        return raw_ptr(R_SG_APP_0);
    }

    unsigned avail() {
        if (state == SGS_ACTIVE) {
            return (data_len - data_pos);
        } else {
            return 0;
        }
    }

    void cmplt_desc() {
        unsigned wr_len = sizeof(raw[R_SG_STATUS]);
        uint32_t status = 0;
        bool stalled = (desc_addr == tail_in);

        state = SGS_CMPLT;
        status = RVFLD_DP(status, SG_STATUS, Cmplt, 1);
        status = RVFLD_DP(status, SG_STATUS, XferBytes, data_pos);

        if (!cfg.mm2s) {
            status = RVFLD_DP(status, SG_STATUS, RXSOF, sof);
            status = RVFLD_DP(status, SG_STATUS, RXEOF, eof);
            if (eof) {
                wr_len += SG_APP_BYTES;  // Add APP words for S2MM EOF
            }
        }

        raw[R_SG_STATUS] = status;

        DBUG(cfg.dtag << "DESC-store:" <<
             " addr=" << HEX(desc_addr) <<
             " next=" << HEX(next_addr) <<
             " dptr=" << HEX(data_addr) <<
             " ctrl=" << HEX(raw[R_SG_CONTROL]) <<
             " stat=" << HEX(raw[R_SG_STATUS]) <<
             " dlen=" << data_len <<
             " dxfr=" << data_pos <<
             " idle=" << stalled);

        dma.store((desc_addr + A_SG_STATUS), raw_ptr(R_SG_STATUS), wr_len);

        head_out.write(desc_addr);
        next_out.write(next_addr);
        set_cmplt(stalled);
    }

    unsigned fetch_desc() {
        if (!can_run()) {
            return 0;
        }

        auto addr = next_addr;
        head_out.write(addr);

        // Fetch up to status to check out Cmplt bit overrun
        unsigned dlen = A_SG_STATUS + 4;
        auto dptr = raw_ptr(0);
        dma.fetch(dptr, addr, dlen);

        auto ok = parse(addr);
        if (!ok) {
            return 0;
        }

        if (ok && cfg.mm2s && app_pos) {
            dma.fetch((dptr + dlen), (addr + dlen), app_pos);
        }

        return avail();
    }

    bool parse(tlm_addr_t addr) {
        uint32_t status = raw[R_SG_STATUS];
        uint32_t control = raw[R_SG_CONTROL];

        if (cfg.a32) {
            // Wipe out the _MSB fields in 32-bit mode
            raw[R_SG_NXTDESC_MSB] = 0;
            raw[R_SG_BUFADDR_MSB] = 0;
            raw[R_SG_RSVD_MSB]    = 0;
        }

        desc_addr = addr;
        next_addr = le64_p(&raw[R_SG_NXTDESC]);
        data_addr = le64_p(&raw[R_SG_BUFADDR]);
        data_len  = RVFLD_EX(control, SG_CONTROL, BuffBytes);
        data_pos  = 0;

        DBUG(cfg.dtag << "DESC-parse:" <<
             " addr=" << HEX(desc_addr) <<
             " next=" << HEX(next_addr) <<
             " dptr=" << HEX(data_addr) <<
             " ctrl=" << HEX(control) <<
             " stat=" << HEX(status) <<
             " dlen=" << data_len <<
             " cbd="  << cbd_in);

        // In Cyclic chain mode, the Cmplt bit is ignored
        bool cmplt = cbd_in ? 0 : RVFLD_EX(status, SG_STATUS, Cmplt);

        if (cmplt) {
            LOG_WARN(cfg.dtag << "DESC-parse: cmplt=1 at " << HEX(desc_addr));

            undef();
            set_halted(DSM_RUNC_OUT_ERR_SGINT);
            return false;
        }

        if (data_len == 0) {
            LOG_WARN(cfg.dtag << "DESC-parse: dlen=0 at " << HEX(desc_addr));

            raw[R_SG_STATUS] = R_SG_STATUS_DMAIntErr_MASK;
            dma.store((desc_addr + A_SG_STATUS),
                      raw_ptr(R_SG_STATUS), sizeof(uint32_t));

            undef();
            set_halted(DSM_RUNC_OUT_ERR_DMAINT);
            return false;
        }

        // Ready for transfer
        state = SGS_ACTIVE;

        // For S2MM, the cooked state of .sof, .eof, and .app_pos
        //  states must be untouched
        if (!cfg.mm2s) {
            return true;
        }

        // More parsing of MM2S
        sof = RVFLD_EX(control, SG_CONTROL, TXSOF);
        eof = RVFLD_EX(control, SG_CONTROL, TXEOF);
        app_pos = 0;

        if (sof) {
            // If 2 SOF MM2S descriptors are seen without an EOF desc
            // in between, 2nd SOF is considered redundant and ignored.
            if (sof_addr != 1) {
                LOG_WARN(cfg.dtag << "SOF desc at " << HEX(desc_addr) <<
                         " ignored by SOF desc at " << HEX(sof_addr));
                sof = false;
            } else {
                app_pos = SG_APP_BYTES;
            }
        } else {
            // If next after EOF is not SOF, assume it is SOF but without APP
            if (eof_addr != 1) {
                LOG_WARN(cfg.dtag << "desc at " << HEX(desc_addr) <<
                         " assumed SOF by last EOF desc at " << HEX(eof_addr));
                sof = true;
            }
        }

        if (sof) {
            sof_addr = desc_addr;
            eof_addr = 1;
        }
        if (eof) {
            eof_addr = desc_addr;
            sof_addr = 1;
        }
        return true;
    }
};

class axidma_mm2s_sg : public axidma_sg,
                       public axidma_mdm::ds_reader
{
public:
    SC_HAS_PROCESS(axidma_mm2s_sg);

    explicit axidma_mm2s_sg(sc_module_name name,
                            axidma_dma& dma_a,
                            axidma_mdm& dsm_a) :
        axidma_sg(name, dma_a),
        dsm(dsm_a)
    {
        if (!cfg.sg) {
            return;
        }

        sc_assert(cfg.mm2s && "BUG: Not bound to MMS2");

        SC_THREAD(dsm_thread);

        SC_METHOD(actor);
           sensitive << runc_in;
           dont_initialize();
    }

private:
    axidma_mdm& dsm;
    bool rst_in = false;

public:
    virtual unsigned b_fetch(tlm_addr_t& dma_addr, bool& eof_out,
                             unsigned char *dptr, unsigned dlen) override {
        sc_assert(cfg.sg && "BUG: Not in SG mode");
        sc_assert(dlen   && "BUG: 0-len data fetch");
        sc_assert(dptr   && "BUG: bad arg");

        if (state != SGS_ACTIVE) {
            if (fetch_desc() == 0) {
                dma_addr = 0;
                eof_out = false;
                return 0;
            }
        }

        unsigned have = avail();
        sc_assert(have && "BUG: Inconsistent desc state");

        dlen = (dlen < have) ? dlen : have;
        dma_addr = data_addr + data_pos;

        dma.fetch(dptr, dma_addr, dlen);
        data_pos += dlen;

        /*
         * Completion happens only upon consumption of last byte of
         * MM2S desc, and it only indicates data copied out of host
         * memory, while delivery to stream target may still fail.
         */
        if (avail()) {
            eof_out = false;  // last byte not consumed yet
        } else {
            cmplt_desc();
            eof_out = eof;
        }

        return dlen;
    }

private:
    void actor() {
        switch (runc_in.read()) {
        case DSM_RUNC_IN_RST:
            DBUG(cfg.dtag << "axidma_mm2s_sg.actor: DSM_RUNC_IN_RESET");
            rst_in = true;
            break;
        case DSM_RUNC_IN_STOP:
            DBUG(cfg.dtag << "axidma_mm2s_sg.actor: DSM_RUNC_IN_STOP");
            break;
        case DSM_RUNC_IN_GO:
            DBUG(cfg.dtag << "axidma_mm2s_sg.actor: DSM_RUNC_IN_GO");
            do_start();
            return;
        default:
            return;
        }

        // Notify stopping by mismatching runc_dis.  Need to consider 3 cases:
        // 1. dsm_thread() has observed can_run() being true and yield to
        //    next delta
        // 2. dsm_thread() has observed can_run() being false
        // 3. dsm_thread() is waiting for completion of TLM payload from
        //    target of MM2M data stream.
        //
        // In all cases, dsm_thread() will be responsible for ack'ing
        // stopping by writing to runc_out.
        dsm.stop();
        notify_stop();
    }

    void dsm_thread() {
        sc_assert(cfg.sg && "BUG: Not in SG mode");

        while (true) {
            if (can_run()) {
                wait(SC_ZERO_TIME);
            } else {
                wait(runc_enb.default_event());
            }
            if (!can_run()) {
                if (rst_in) {
                    reset();
                    rst_in = false;
                }
                set_stopped();
                continue;
            }

            /*
             * At this point, the controller provides the guarantee that the
             * desc-chain can be inspected.
             *
             * If the chain contains error, the chain loader signals the
             * controller to halt again.
             */
            auto avail = fetch_desc();
            if (!avail) {
                continue;
            }

            if (sof) {
                control_b_transfer();
            }

            // Transfer one desc to stream target, in multiple fragments
            // if data too long for intermediate buffer.
            for (unsigned pos = 0; pos < avail; ) {
                bool aborted = false;
                unsigned len = dsm.b_transfer(aborted);

                if (aborted) {
                    set_stopped();
                    break;
                }

                if (!len) {
                    sc_assert(!can_run() && "BUG: 0 from this->b_fetch()");
                    break;
                }

                pos += len;
            }
        }
    }

    void control_b_transfer() {
        if (!app_pos) {
            return;
        }

        // Just in case the binding policy is SC_ZERO_OR_MORE_BOUND
        auto& sk{cfg.xpi.mm2s_control_stream_socket};
        if (sk.size() == 0) {
            return;
        }

        tlm_generic_payload tr;

        tr.set_command(tlm::TLM_WRITE_COMMAND);
        tr.set_address(0);
        tr.set_data_ptr(app_ptr());
        tr.set_data_length(app_pos);
        tr.set_streaming_width(app_pos);
        tr.set_dmi_allowed(false);
        tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

        sc_time delay = SC_ZERO_TIME;
        sk->b_transport(tr, delay);
    }
};

class axidma_s2mm_sg : public axidma_sg,
                       public axidma_sdm::ds_writer
{
public:
    SC_HAS_PROCESS(axidma_s2mm_sg);

    explicit axidma_s2mm_sg(sc_module_name name,
                            axidma_dma& dma_a) :
        axidma_sg(name, dma_a)
    {
        sc_assert(!cfg.mm2s && "BUG: Not bound to S2MM");

        SC_METHOD(actor);
           sensitive << runc_in;
           dont_initialize();
    }

public:
    void status_b_transport(tlm_generic_payload& tr, sc_time& delay) {
        if (!cfg.sg) {
            return;
        }

        unsigned char *buf = tr.get_data_ptr();
        unsigned len = tr.get_data_length();

        unsigned char *app = raw_ptr(R_SG_APP_0);
        unsigned cap = SG_APP_BYTES - app_pos;

        // Any bytes beyond APP_4 are dropped
        if (len > cap) {
            len = cap;
        }
        if (len) {
            std::memcpy(app + app_pos, buf, len);
            app_pos += len;
        }

        tr.set_response_status(tlm::TLM_OK_RESPONSE);
    }

    virtual unsigned b_store(unsigned char *dptr,
                             unsigned dlen, bool eof_in) override {
        sc_assert(cfg.sg && "BUG: Not in SG mode");
        sc_assert(dlen   && "BUG: 0-len data store");
        sc_assert(dptr   && "BUG: bad arg");

        const char *drop_msg = nullptr;
        unsigned pos = 0;

        DBUG(cfg.dtag << "Stream sg-store: start;" <<
             " len=" << dlen <<
             " sof=" << sof <<
             " eof=" << eof);

        /*
         * To keep it simple, SG S2MM, unlike SG MM2S, drops unstored data
         * if the operation cannot complete for whatever reason.
         */
        while (pos < dlen) {
            if (runc_in.event()) {
                // Yield to actor() to evaluate, to avoid multiple writers
                // to runc_out in the same delta cycle.
                wait(SC_ZERO_TIME);
            }

            if (!can_run()) {
                drop_msg = "stalled";
                goto drop;
            }

            unsigned stored = store_one((dptr + pos), (dlen - pos), eof_in);
            if (stored == 0) {
                drop_msg = "unstored";
                goto drop;
            }

            pos += stored;
        }

        DBUG(cfg.dtag << "Stream sg-store: cmplt;" <<
             " len=" << dlen <<
             " sof=" << sof <<
             " eof=" << eof);
        return true;

    drop:
        if (drop_msg) {
            DBUG(cfg.dtag << "Stream sg-store: " << drop_msg << "; " <<
                 " drops " << (dlen - pos) << " bytes"
                 " of "    << dlen);
        }
        return false;
    }

private:
    unsigned store_one(unsigned char *dptr, unsigned dlen, bool eof_in) {
        if (state != SGS_ACTIVE) {
            if (fetch_desc() == 0) {
                return 0;
            }
        }

        auto have = avail();
        sc_assert(have && "BUG: Inconsistent desc state");

        unsigned slen = (have < dlen) ? have : dlen;
        dma.store((data_addr + data_pos), dptr, slen);
        data_pos += slen;

        // Un-fill desc stays active only if not EOF
        if (!eof_in && avail()) {
            return slen;
        }

        // Complete the descriptor
        eof = eof_in;
        cmplt_desc();

        // For S2MM, EOF of current desc is SOF of next desc
        sof = eof;
        eof = false;

        // If there is still unstored data, pause for next delta
        // so the controller can pick up the completed desc before
        // storing remaining portion to next desc.
        if (slen < dlen) {
            wait(SC_ZERO_TIME);
        }

        return slen;
    }

    void actor() {
        switch (runc_in.read()) {
        case DSM_RUNC_IN_RST:
            DBUG(cfg.dtag << "axidma_s2mm_sg.actor: DSM_RUNC_IN_RESET");
            reset();
            break;
        case DSM_RUNC_IN_STOP:
            DBUG(cfg.dtag << "axidma_s2mm_sg.actor: DSM_RUNC_IN_STOP");
            break;
        case DSM_RUNC_IN_GO:
            DBUG(cfg.dtag << "axidma_s2mm_sg.actor: DSM_RUNC_IN_GO");
            do_start();
            return;
        default:
            return;
        }

        // Disable run and indicate stopped to controller.
        // Unlike that of mm2s_sg, there is no need to notify_stop()
        // because s2mm_sg is not sensitive to runc_enb.
        set_stopped();
    }
};

/*
 * Direct-mode MM2S data mover
 */
class axidma_mm2s_dm : public sc_module,
                       public axidma_mdm::ds_reader
{
public:
    sc_buffer<unsigned>   runc_in;
    sc_buffer<tlm_addr_t> dptr_in;
    sc_buffer<tlm_addr_t> dlen_in;

    sc_out<unsigned>      runc_out;
    sc_out<tlm_addr_t>    dlen_out;

    explicit axidma_mm2s_dm(sc_module_name name,
                            axidma_dma& dma_a,
                            axidma_mdm& dsm_a) :
        sc_module(name),
        runc_in("runc_in"),
        dptr_in("dma_a_in"),
        dlen_in("dma_len_in"),
        runc_out("runc_out"),
        dlen_out("dma_len_out"),
        cfg(dma_a.cfg),
        dma(dma_a),
        dsm(dsm_a)
    {
        sc_assert(cfg.mm2s && "BUG: Not bound to MMS2");
    }

private:
    axidma_cfg& cfg;
    axidma_dma& dma;
    axidma_mdm& dsm;

public:
    virtual unsigned b_fetch(tlm_addr_t& dma_addr, bool& eof_out,
                             unsigned char *dptr, unsigned dlen) override {
        sc_assert(!cfg.sg && "BUG: Not in Direct mode");

        sc_assert(0 && "BUG: Not implemented yet");
        return 0;
    }

    //Notes for TBD:
    //1. MM2S controller expects:
    //   a. DSM_RUNC_IN_GO from runc_in to start one transfer
    //   b. DSM_RUNC_OUT_IOC_EOF to runc_out when complete, with
    //      dlen_out to emit actual transferred size
};

/*
 * Direct-mode S2MM data mover
 */
class axidma_s2mm_dm : public sc_module,
                       public axidma_sdm::ds_writer
{
public:
    sc_buffer<unsigned>   runc_in;
    sc_buffer<tlm_addr_t> dptr_in;
    sc_buffer<tlm_addr_t> dlen_in;

    sc_out<unsigned>      runc_out;
    sc_out<tlm_addr_t>    dlen_out;

    explicit axidma_s2mm_dm(sc_module_name name, axidma_dma& dma_a) :
        sc_module(name),
        runc_in("runc_in"),
        dptr_in("dma_a_in"),
        dlen_in("dma_len_in"),
        runc_out("runc_out"),
        dlen_out("dma_len_out"),
        cfg(dma_a.cfg),
        dma(dma_a)
    {
        sc_assert(!cfg.mm2s && "BUG: Not bound to S2MM");
    }

private:
    axidma_cfg& cfg;
    axidma_dma& dma;

public:
    virtual unsigned b_store(unsigned char *dptr,
                             unsigned dlen, bool eof_in) override {
        sc_assert(!cfg.sg && "BUG: Not in Direct mode");

        sc_assert(0 && "BUG: Not implemented yet");
        return 0;
    }

    //Notes for TBD:
    //1. S2MM controller expects:
    //   a. DSM_RUNC_IN_GO from runc_in to start in standby for
    //      one push from S2MM data stream initiator, with host
    //      buffer at dptr_in with max size of dlen_in.
    //   b. DSM_RUNC_OUT_IOC_EOF to runc_out after a push has
    //      arrived and been transferred to host, with dlen_out
    //      emitting actual transferred size
};

/*
 * One for each of mm2s and s2mm, an axidma_ctlr controller maintains
 * the operational states for its respective direction.
 */
class axidma_ctlr : public sc_module
{
public:
    SC_HAS_PROCESS(axidma_ctlr);

    sc_in<bool>            rst_in;   // System reset

    mwr_buffer<unsigned>   runc_in; // Driven by stream data mover
    axidma_buf<tlm_addr_t> head_in;
    axidma_buf<tlm_addr_t> next_in;

    sc_out<bool>           cbd_out;  // Drive stream data mover
    sc_out<unsigned>       runc_out;
    sc_out<tlm_addr_t>     head_out;
    sc_out<tlm_addr_t>     tail_out;

    axidma_regs rb;

    explicit axidma_ctlr(sc_module_name name, axidma_cfg& c) :
        sc_module(name),
        rst_in("rst_in"),
        runc_in("runc_in"),
        head_in("head_in"),
        next_in("next_in"),
        cbd_out ("cbd_out"),
        runc_out("runc_out"),
        head_out("head_out"),
        tail_out("tail_out"),
        rb("regs", c),
        cfg(c),
        idt_clk("idt_clk")
    {
        init();
    }

    void reset();

private:
    axidma_cfg& cfg;
    sc_event    idt_clk;
    unsigned    idt_cnt = 0;
    unsigned    ioc_cnt = 1;
    bool        idt_ticking;
    tlm_addr_t  sg_next;

    bool dsm_is_halting() {
        return !rb.cr.rs() && !rb.sr.halted();
    }

    bool dsm_is_halted() {
        return !rb.cr.rs() &&  rb.sr.halted();
    }

    bool dsm_is_starting() {
        return  rb.cr.rs() &&  rb.sr.halted();
    }

    bool dsm_is_running() {
        return  rb.cr.rs() && !rb.sr.halted();
    }

    bool dsm_is_idle() {
        return dsm_is_running() && rb.sr.idle();
    }

    void update_irq(bool pending) {
        if (cfg.mm2s) {
            cfg.xpi.mm2s_irq.write(pending);
        } else {
            cfg.xpi.s2mm_irq.write(pending);
        }
    }

    void init();
    void actor();
};

void axidma_ctlr::init()
{
    if (cfg.sg) {
        SC_METHOD(actor);
           sensitive << rst_in;     // System reset
           sensitive << rb.cr;      // DMACR written by host
           sensitive << rb.sr_in;   // DMASR written by host for W1C
           sensitive << rb.tail;    // TAILDESC_MSB written host
           sensitive << runc_in;    // State change from data mover
           sensitive << head_in;    // Current head from data mover
           sensitive << idt_clk;    // Timer ticking
           dont_initialize();
    } else {
        SC_METHOD(actor);
           sensitive << rst_in;     // System reset
           sensitive << rb.cr;      // DMACR written by host
           sensitive << rb.sr_in;   // DMASR written by host for W1C
           sensitive << rb.dlen;    // DMA_LENGTH written by host
           sensitive << runc_in;    // State change from data mover
           dont_initialize();
    }

    idt_cnt = 0;
    ioc_cnt = 1;
}

void axidma_ctlr::reset()
{
    DBUG(cfg.dtag << "CR.Reset activated" <<
         " rst=" << rst_in.read() <<
         " cr=" << HEX(rb.cr) <<
         " sr=" << HEX(rb.sr));

    if (dsm_is_running()) {
        runc_out.write(DSM_RUNC_IN_RST);
    }

    rb.reset();
    update_irq(false);

    idt_cnt = 0;
    ioc_cnt = 1;
    sg_next = 1;
}

void axidma_ctlr::actor()
{
    // Hard reset
    if (rst_in.posedge_event().triggered()) {
        reset();
        next_trigger(rst_in.negedge_event());
        return;
    }
    if (rst_in.read()) {
        return;
    }

    // Soft reset
    if (rb.cr.updated() && rb.cr.rst_posedge()) {
        reset();
        return;
    }
    if (rb.cr.rst()) {
        return;
    }

    /*
     * Deterministically evaluate all triggers together to produce
     * one or more deterministic reactions.
     */
    bool idt_ticked = idt_clk.triggered();

    bool stream_upd = runc_in.event();    // Data mover triggers
    bool stream_head = head_in.event();

    bool cr_written = rb.cr.event();      // Host triggers
    bool w1c_written = rb.sr_in.event();
    bool tail_written = rb.tail.event();
    bool dlen_written = rb.dlen.event();

    bool run_posedge = false;
    bool run_negedge = false;
    if (cr_written) {
        run_posedge = rb.cr.rs_posedge();
        run_negedge = rb.cr.rs_negedge();
    }

    bool verbose = false;

    verbose |= stream_upd;
    verbose |= stream_head;
    verbose |= run_posedge;
    verbose |= run_negedge;
    verbose |= tail_written;
    verbose |= dlen_written;

    // Debug stays quiet for some events
    if (verbose) {
        DBUG(cfg.dtag << "axidma_ctlr::actor()" <<
             " rs="  << rb.cr.rs() <<
             " hlt=" << rb.sr.halted() <<
             " idl=" << rb.sr.idle() <<
             " trig:" <<
             " cr="      << cr_written <<
             " w1c="     << w1c_written <<
             " tail="    << tail_written <<
             " dlen="    << dlen_written <<
             " runc_in=" << stream_upd <<
             " head_in=" << stream_head <<
             " idt_clk=" << idt_ticked);
    }

    /*
     * There are 3 sub sections:
     * - 1st, evaluate triggers independently into actions
     * - 2nd, prioritize and filter out actions
     * - Last, carry out the selected actions.
     */
    bool irq_changed = false;
    if (w1c_written) {
        // IRQ clearing by W1C, only Dly_Irq and IOC_Irq can be
        // cleared because Err_Irq is stuck until DMACR.Reset
        // clears the error bits
        uint32_t w1c_irqs = rb.sr.w1c_irqs();
        uint32_t w1c_reqs = rb.sr_in.w1c_irqs();

        w1c_reqs &= w1c_irqs;
        irq_changed = !!w1c_reqs;

        if (RVFLD_EX(w1c_reqs, DMASR, Dly_Irq)) {
            rb.sr.set_dly_irq(false);
        }
        if (RVFLD_EX(w1c_reqs, DMASR, IOC_Irq)) {
            rb.sr.set_ioc_irq(false);
        }
    }

    bool idt_running = !!idt_cnt;
    bool idt_expired = false;
    if (idt_running && idt_ticked) {
        idt_cnt--;
        if (idt_cnt == 0) {
            idt_cnt = rb.cr.dly_cnt();
            idt_expired = true;
        }
    }

    enum {
        DSM_NEXT_STEADY = 0,
        DSM_NEXT_IDLE,
        DSM_NEXT_START,
        DSM_NEXT_HALTING,
        DSM_NEXT_HALTED,
        DSM_NEXT_STALLED,
    } dsm_next = DSM_NEXT_STEADY;

    bool dsm_eof = false;
    bool dsm_ioc = false;
    if (stream_upd) {
        unsigned sts = runc_in.read();
        sc_assert(sts && "BUG: stream_sts has 0 value");

        switch (sts) {
        case DSM_RUNC_OUT_ERR_SGINT:
            rb.sr.set_err_sgint();
            irq_changed = true;
            dsm_next = DSM_NEXT_HALTED;
            break;
        case DSM_RUNC_OUT_ERR_DMAINT:
            rb.sr.set_err_dmaint();
            irq_changed = true;
            dsm_next = DSM_NEXT_HALTED;
            break;
        case DSM_RUNC_OUT_STOPPED:
            dsm_next = DSM_NEXT_HALTED;
            break;
        case DSM_RUNC_OUT_IOC_STALLED:
        case DSM_RUNC_OUT_IOC_EOF_STALLED:
            dsm_next = DSM_NEXT_STALLED;
            break;
        }

        switch (sts) {
        case DSM_RUNC_OUT_IOC:
        case DSM_RUNC_OUT_IOC_EOF:
        case DSM_RUNC_OUT_IOC_STALLED:
        case DSM_RUNC_OUT_IOC_EOF_STALLED:
            dsm_ioc = true;
            if (cfg.sg) {
                sc_assert(next_in.updated() && "BUG: SG-IOC without next");
                sg_next = next_in.read();
            } else {
                sc_assert(next_in.updated() && "BUG: DM-IOC without dlen");
                rb.dlen_out.write(next_in.read());
            }
            break;
        }

        switch (sts) {
        case DSM_RUNC_OUT_IOC_EOF:
        case DSM_RUNC_OUT_IOC_EOF_STALLED:
            dsm_eof = true;
            break;
        }
    }

    bool ioc_irq = false;
    if (dsm_ioc && !cfg.sg) {
        ioc_irq = true;
    } else if (dsm_ioc) {
        idt_cnt = rb.cr.dly_cnt();
        idt_expired = false;

        if (ioc_cnt && (!cfg.mm2s || dsm_eof)) {
            ioc_cnt--;  // MM2S counts down only on EOF
        }
        if (!ioc_cnt) {
            ioc_irq = true;
        }
    }

    /*
     * All internally generated actions can be nullified by host
     */
    if (!cr_written) {
        goto actions;
    }

    if (RVFLD_EX(rb.cr.changes(), DMACR, ALL_IrqEN)) {
        irq_changed = true;
    }

    if (run_negedge) {
        // Stopping disables the timer and removes pending irq
        idt_running = false;
        idt_expired = false;
        dsm_next = DSM_NEXT_HALTING;

        // Also flushes any unread head and tail, i.e., host are required
        // to write them again before run_posedge
        rb.head.catchup();
        rb.tail.catchup();
    } else if (idt_running && !rb.cr.dly_cnt()) {
        // Disabling the timer also removes pending irq
        idt_running = false;
        idt_expired = false;
    } else if (!idt_running && rb.cr.dly_cnt()) {
        idt_running = true;
        idt_expired = false;
    }

    if (run_posedge) {
        if (cfg.sg) {
            if (rb.head.updated()) {
                sg_next = rb.head.read();
            } else {
                LOG_WARN(cfg.dtag
                         << "R_CURDESC not written during DMACR.RS==0");
                sg_next = rb.head_out.read();
            }

            if (rb.tail.updated()) {
                dsm_next = DSM_NEXT_START;
            } else {
                dsm_next = DSM_NEXT_IDLE;
            }
        } else {
            if (rb.dlen.updated()) {
                dsm_next = DSM_NEXT_START;
            } else {
                dsm_next = DSM_NEXT_IDLE;
            }
        }
    }

actions:
    if (dsm_is_running() && stream_head) {
        rb.head_out.write(head_in.read());  // To update R_CURDESC
    }

    if (dsm_ioc && !cfg.sg) {
        rb.dlen_out.write(next_in.read());  // To update R_DMA_LENGTH
    }

    if (idt_expired) {
        idt_cnt = rb.cr.dly_cnt();
        rb.sr.set_dly_irq(true);
        irq_changed = true;

        if (verbose) {
            DBUG(cfg.dtag << "IRQDelay_Irq raised." << " new_idt=" << idt_cnt);
        }
    }

    if (ioc_irq) {
        ioc_cnt = rb.cr.ioc_cnt();
        rb.sr.set_ioc_irq(true);
        irq_changed = true;

        DBUG(cfg.dtag << "IOC_Irq raised." << " new_ioc=" << ioc_cnt);
    }

    if (cfg.sg) {
        rb.sr.set_dly_sts(idt_cnt);
        rb.sr.set_ioc_sts(ioc_cnt);
    }

    if (idt_ticked) {
        if (idt_running) {
            idt_clk.notify(cfg.idt_interval);  // Schedule next tick
            idt_ticking = true;
        } else {
            idt_ticking = false;
        }
    } else if (idt_ticking) {
        if (!idt_running) {
            idt_clk.cancel();                  // Stop the clock
            idt_ticking = false;
        }
    } else if (idt_running) {
        idt_clk.notify(cfg.idt_interval);      // Schedule next tick
        idt_ticking = true;
    }

    if (irq_changed) {
        uint32_t ien = rb.cr.irqs_en();
        uint32_t irq = rb.sr.irqs();
        bool pending = ien & irq;

        update_irq(pending);

        if (verbose) {
            DBUG(cfg.dtag << "IRQ updated to " << pending <<
                 ", ien=" << HEX(ien) <<
                 ", irq=" << HEX(irq));
        }
    }

    /*
     * Adjust the data stream state
     */
    if ((rb.tail.updated() && cfg.sg) || (rb.dlen.updated() && !cfg.sg)) {
        if (dsm_next == DSM_NEXT_STALLED) {
            // New tail/dlen written since last DSM_RUNC_IN_GO,
            // so resume from last IOC's descriptor's next_addr
            dsm_next = DSM_NEXT_START;
        }
        if ((dsm_next == DSM_NEXT_STEADY) && dsm_is_idle()) {
            // New tail/dlen written since last CR.RS.posedge
            dsm_next = DSM_NEXT_START;
        }
    }

    const char *dsm_next_str = nullptr;
    switch (dsm_next) {
    case DSM_NEXT_STEADY:
        break;
    case DSM_NEXT_HALTING:
        // CR.RS.negedge detected
        dsm_next_str = "halting";
        runc_out.write(DSM_RUNC_IN_STOP);
        break;
    case DSM_NEXT_HALTED:
        // CR.RS.negedge ack'ed
        dsm_next_str = "halted";
        rb.sr.set_halted(true);
        rb.sr.set_idle(false);
        sg_next = 1;
        break;
    case DSM_NEXT_IDLE:
        // Tail not written between CR.RS.negedge to CR.RS.posedge
        dsm_next_str = "idle";
        rb.sr.set_halted(false);
        rb.sr.set_idle(true);
        break;
    case DSM_NEXT_STALLED:
        // Tail not written since last DSM_RUNC_IN_GO
        rb.sr.set_halted(false);
        rb.sr.set_idle(true);

        DBUG(cfg.dtag << "DMA stall" <<
             " cr=" << HEX(rb.cr) <<
             " sr=" << HEX(rb.sr) <<
             " h="  << HEX(rb.head_out.read()) <<
             " t="  << HEX(tail_out.read()) <<
             " n="  << HEX(sg_next));
        break;
    case DSM_NEXT_START:
        rb.sr.set_halted(false);
        rb.sr.set_idle(false);

        tlm_addr_t h, t;
        if (cfg.sg) {
            sc_assert(!(sg_next & 0x3f) && "BUG: sg_next invalid");
            h = sg_next;
            t = rb.tail.read();
        } else {
            h = rb.dptr;
            t = rb.dlen.read();
        }

        head_out.write(h);
        tail_out.write(t);
        runc_out.write(DSM_RUNC_IN_GO);

        DBUG(cfg.dtag << "DMA start" <<
             " cr=" << HEX(rb.cr) <<
             " sr=" << HEX(rb.sr) <<
             " h=" << HEX(h) <<
             " t=" << HEX(t));
        break;
    }

    if (dsm_next_str) {
        DBUG(cfg.dtag << "DMA " << dsm_next_str <<
             " cr=" << HEX(rb.cr) <<
             " sr=" << HEX(rb.sr));
    }
}

/*
 * The actual amd_axidma implementation, de-cluttering the public-facing
 * module.
 */
class amd_axidma_ : public sc_module
{
public:
    SC_HAS_PROCESS(amd_axidma_);

    sc_in<bool> rst_in;

    explicit amd_axidma_(sc_module_name name,
                         amd_axidma *w,
                         bool mode_sg,
                         bool addr_32,
                         sc_dt::uint64 clk_in_hz) :
        sc_module(name),
        rst_in("rst_in"),
        mm2s_cfg("MM2S: ",   w, mode_sg, addr_32, clk_in_hz),
        mm2s_ctl("mm2s_ctl", mm2s_cfg),
        mm2s_dma("mm2s_dma", mm2s_cfg),
        mm2s_dsm("mm2s_dsm", mm2s_cfg, &mm2s_sg, &mm2s_dm),
        mm2s_sg ("mm2s_sg",  mm2s_dma, mm2s_dsm),
        mm2s_dm ("mm2s_dm",  mm2s_dma, mm2s_dsm),
        s2mm_cfg("S2MM: ",   w, mode_sg, addr_32, clk_in_hz),
        s2mm_ctl("s2mm_ctl", s2mm_cfg),
        s2mm_dma("s2mm_dma", s2mm_cfg),
        s2mm_dsm("s2mm_dsm", s2mm_cfg, &s2mm_sg, &s2mm_dm),
        s2mm_sg ("s2mm_sg",  s2mm_dma),
        s2mm_dm ("s2mm_dm",  s2mm_dma),
        dummy_in64("unused_in64"),
        dummy_in01("unused_in01")
    {
        init();
    }

private:
    axidma_cfg  mm2s_cfg;
    axidma_ctlr mm2s_ctl;
    axidma_dma  mm2s_dma;
    axidma_mdm  mm2s_dsm;
    axidma_mm2s_sg mm2s_sg;
    axidma_mm2s_dm mm2s_dm;

    axidma_cfg  s2mm_cfg;
    axidma_ctlr s2mm_ctl;
    axidma_dma  s2mm_dma;
    axidma_sdm  s2mm_dsm;
    axidma_s2mm_sg s2mm_sg;
    axidma_s2mm_dm s2mm_dm;

    mwr_signal<tlm_addr_t> dummy_in64;
    mwr_signal<bool>       dummy_in01;

    tlm_sync_enum mm2s_dsm_nb_transport_bw(tlm_generic_payload& tr,
                                           tlm_phase& phase,
                                           sc_time& delay) {
        return mm2s_dsm.nb_transport_bw(tr, phase, delay);
    }

    tlm_sync_enum s2mm_dsm_nb_transport_fw(tlm_generic_payload& tr,
                                           tlm_phase& phase,
                                           sc_time& delay) {
        return s2mm_dsm.nb_transport_fw(tr, phase, delay);
    }

    void s2mm_sgs_b_transport(tlm_generic_payload& tr,
                                 sc_time& delay) {
        s2mm_sg.status_b_transport(tr, delay);
    }

    void regs_b_transport(tlm_generic_payload& tr, sc_time& delay) {
        tlm_addr_t addr = tr.get_address();

        if (addr < A_S2MM_BASE) {
            mm2s_ctl.rb.b_transport(tr, delay);
        } else {
            tr.set_address(addr - A_S2MM_BASE);
            s2mm_ctl.rb.b_transport(tr, delay);
            tr.set_address(addr);
        }
    }

    void init();
    void connect_sg();
    void connect_dm();
};

/*
 * Implementation: construction
 */
void amd_axidma_::init()
{
    auto& xpi = mm2s_cfg.xpi;

    connect_sg();
    connect_dm();

    xpi.s2mm_status_stream_socket.register_b_transport(this,
                    &amd_axidma_::s2mm_sgs_b_transport);

    xpi.s2mm_stream_socket.register_nb_transport_fw(this,
                    &amd_axidma_::s2mm_dsm_nb_transport_fw);

    xpi.mm2s_stream_socket.register_nb_transport_bw(this,
                    &amd_axidma_::mm2s_dsm_nb_transport_bw);

    xpi.regs_target_socket.register_b_transport(this,
                    &amd_axidma_::regs_b_transport);

    mm2s_ctl.rst_in(rst_in);
    s2mm_ctl.rst_in(rst_in);
}

void amd_axidma_::connect_sg()
{
    axidma_cfg& cfg = mm2s_cfg;  // Just to get to common members

    if (cfg.sg) {
        mm2s_ctl.runc_out(mm2s_sg.runc_in);  // MM2S Ctlr => MM2S Mover
        mm2s_ctl.head_out(mm2s_sg.head_in);
        mm2s_ctl.tail_out(mm2s_sg.tail_in);
        mm2s_ctl.cbd_out( mm2s_sg.cbd_in);

        mm2s_sg.runc_out(mm2s_ctl.runc_in);  // MM2S Mover => MM2S Ctlr
        mm2s_sg.head_out(mm2s_ctl.head_in);
        mm2s_sg.next_out(mm2s_ctl.next_in);

        s2mm_ctl.runc_out(s2mm_sg.runc_in);  // S2MM Ctlr => S2MM Mover
        s2mm_ctl.head_out(s2mm_sg.head_in);
        s2mm_ctl.tail_out(s2mm_sg.tail_in);
        s2mm_ctl.cbd_out( s2mm_sg.cbd_in);

        s2mm_sg.runc_out(s2mm_ctl.runc_in);  // S2MM Mover => S2MM Ctlr
        s2mm_sg.head_out(s2mm_ctl.head_in);
        s2mm_sg.next_out(s2mm_ctl.next_in);
    } else {
        // Avoid sc_out<T> unbound errors
        mm2s_sg.runc_out(mm2s_sg.runc_in);
        mm2s_sg.head_out(mm2s_sg.head_in);
        mm2s_sg.next_out(dummy_in64);
        mm2s_ctl.cbd_out(dummy_in01);

        s2mm_sg.runc_out(s2mm_sg.runc_in);
        s2mm_sg.head_out(s2mm_sg.head_in);
        s2mm_sg.next_out(dummy_in64);
        s2mm_ctl.cbd_out(dummy_in01);
    }
}

void amd_axidma_::connect_dm()
{
    axidma_cfg& cfg = mm2s_cfg;  // Just to get to common members

    if (!cfg.sg) {
        mm2s_ctl.runc_out(mm2s_dm.runc_in);  // MM2S Ctlr => MM2S Mover
        mm2s_ctl.head_out(mm2s_dm.dptr_in);
        mm2s_ctl.tail_out(mm2s_dm.dlen_in);

        mm2s_dm.runc_out(mm2s_ctl.runc_in);  // MM2S Mover => MM2S Ctlr
        mm2s_dm.dlen_out(mm2s_ctl.next_in);

        s2mm_ctl.runc_out(s2mm_dm.runc_in);  // S2MM Ctlr => S2MM Mover
        s2mm_ctl.head_out(s2mm_dm.dptr_in);
        s2mm_ctl.tail_out(s2mm_dm.dlen_in);

        s2mm_dm.runc_out(s2mm_ctl.runc_in);  // S2MM Mover => S2MM Ctlr
        s2mm_dm.dlen_out(s2mm_ctl.next_in);
    } else {
        // Avoid sc_out<T> unbound errors
        mm2s_dm.runc_out(mm2s_dm.runc_in);
        mm2s_dm.dlen_out(mm2s_dm.dlen_in);

        s2mm_dm.runc_out(s2mm_dm.runc_in);
        s2mm_dm.dlen_out(s2mm_dm.dlen_in);
    }
}

/*
 * Implementation: Wrapper constructor and destructor
 *
 * PImpl pattern requires that they are defined only after amd_axidma_
 * is a complete type.
 */
amd_axidma::~amd_axidma() = default;

amd_axidma::amd_axidma(sc_core::sc_module_name name,
                       bool mode_sg,
                       bool addr_32,
                       sc_dt::uint64 clk_in_hz) :
    sc_module(name),
    rst("rst"),
    mm2s_irq("mm2s_irq"),
    s2mm_irq("s2mm_irq"),
    dma_init_socket("dma_init_socket"),
    regs_target_socket("regs_targe_socket"),
    mm2s_stream_socket("mm2s_stream_socket"),
    mm2s_control_stream_socket("mm2s_control_stream_socket"),
    s2mm_stream_socket("s2mm_stream_socket"),
    s2mm_status_stream_socket("s2mm_status_stream_socket"),
    impl_(std::make_unique<amd_axidma_>("impl",
                                           this,
                                           mode_sg,
                                           addr_32,
                                           clk_in_hz))
{
    impl_->rst_in(rst);
}
