/*
 * CHI to TLM-2.0 HW bridge.
 *
 * Copyright (c) 2020 Xilinx Inc.
 * Written by Francisco Iglesias.
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

#ifndef CHI2TLM_HW_BRIDGE_RNF_H__
#define CHI2TLM_HW_BRIDGE_RNF_H__

#include <unistd.h>

#include "tlm-bridges/private/chi/pkts.h"
#include "tlm-bridges/private/chi/common.h"

#include "private/chi-regs.h"

#define NUM_CREDITS 15

#define NUM_TXSNP_DESC_EN NUM_CREDITS
#define NUM_TXRSP_DESC_EN NUM_CREDITS
#define NUM_TXDAT_DESC_EN NUM_CREDITS

#define NUM_RXREQ_DESC_EN NUM_CREDITS
#define NUM_RXRSP_DESC_EN NUM_CREDITS
#define NUM_RXDAT_DESC_EN NUM_CREDITS

#define IRQ_RXREQ_FLAG 0x4
#define IRQ_RXRSP_FLAG 0x2
#define IRQ_RXDAT_FLAG 0x1

#define HNF_IRQ_RX_MASK (IRQ_RXREQ_FLAG | IRQ_RXRSP_FLAG | IRQ_RXDAT_FLAG)

#define TXSNP_DESC_SZ 0x10
#define TXRSP_DESC_SZ 0x8
#define TXDAT_DESC_SZ 0x60

#define RXREQ_DESC_SZ 0x10
#define RXRSP_DESC_SZ 0x8
#define RXDAT_DESC_SZ 0x60

#define HNF_SYSCOREQ_SHIFT 3

#define REFILL_CREDITS_SHIFT 1
#define SET_CREDITS 1

template<
	int DATA_WIDTH = 512,
	int ADDR_WIDTH = 44,
	int NODEID_WIDTH = 7,
	int RSVDC_WIDTH = 32,
	int DATACHECK_WIDTH = 64,
	int POISON_WIDTH = 8,
	int DAT_OPCODE_WIDTH = Dat::Opcode_Width>
class chi2tlm_hwb_rnf :
	public sc_core::sc_module
{
public:
	typedef chi2tlm_hwb_rnf< DATA_WIDTH,
				ADDR_WIDTH,
				NODEID_WIDTH,
				RSVDC_WIDTH,
				DATACHECK_WIDTH,
				POISON_WIDTH> chi2tlm_hwb_rnf_t;

	typedef BRIDGES::ReqPkt< ADDR_WIDTH,
			NODEID_WIDTH,
			RSVDC_WIDTH> ReqPkt_t;

	typedef BRIDGES::RspPkt<NODEID_WIDTH> RspPkt_t;

	// lsb 3 bits on address not used
	typedef BRIDGES::SnpPkt<ADDR_WIDTH-3, NODEID_WIDTH> SnpPkt_t;

	typedef BRIDGES::DatPkt< DATA_WIDTH,
			NODEID_WIDTH,
			RSVDC_WIDTH,
			DATACHECK_WIDTH,
			POISON_WIDTH,
			DAT_OPCODE_WIDTH> DatPkt_t;
	enum {
		RXREQ_FLIT_WIDTH = ReqPkt_t::FLIT_WIDTH,
		RXRSP_FLIT_WIDTH = RspPkt_t::FLIT_WIDTH,
		RXDAT_FLIT_WIDTH = DatPkt_t::FLIT_WIDTH,

		TXRSP_FLIT_WIDTH = RspPkt_t::FLIT_WIDTH,
		TXDAT_FLIT_WIDTH = DatPkt_t::FLIT_WIDTH,
		TXSNP_FLIT_WIDTH = SnpPkt_t::FLIT_WIDTH,
		};


	tlm_utils::simple_initiator_socket<chi2tlm_hwb_rnf> rxreq_init_socket;
	tlm_utils::simple_initiator_socket<chi2tlm_hwb_rnf> rxrsp_init_socket;
	tlm_utils::simple_initiator_socket<chi2tlm_hwb_rnf> rxdat_init_socket;

	tlm_utils::simple_target_socket<chi2tlm_hwb_rnf> txrsp_tgt_socket;
	tlm_utils::simple_target_socket<chi2tlm_hwb_rnf> txdat_tgt_socket;
	tlm_utils::simple_target_socket<chi2tlm_hwb_rnf> txsnp_tgt_socket;

	// AXI4Lite init_socket
	tlm_utils::simple_initiator_socket<chi2tlm_hwb_rnf> bridge_socket;

	sc_in<bool > resetn;
	sc_in<bool > irq;

	SC_HAS_PROCESS(chi2tlm_hwb_rnf);

	chi2tlm_hwb_rnf(sc_core::sc_module_name name,
			uint32_t base_addr = 0) :
		sc_module(name),

		rxreq_init_socket("rxreq_init_socket"),
		rxrsp_init_socket("rxrsp_init_socket"),
		rxdat_init_socket("rxdat_init_socket"),

		txrsp_tgt_socket("txrsp_tgt_socket"),
		txdat_tgt_socket("txdat_tgt_socket"),
		txsnp_tgt_socket("txsnp_tgt_socket"),

		bridge_socket("bridge_socket"),

		resetn("resetn"),
		irq("irq"),

		m_irq_mode_en(false),
		m_sysco_handshake_en(false),

		probed(false),
		probed_event("probed_event"),

		version_major(0),
		version_minor(0),
		bridge_type(0),
		m_base_addr(base_addr)
	{
		txrsp_tgt_socket.register_b_transport(
				this, &chi2tlm_hwb_rnf::b_transport_txrsp);
		txdat_tgt_socket.register_b_transport(
				this, &chi2tlm_hwb_rnf::b_transport_txdat);
		txsnp_tgt_socket.register_b_transport(
				this, &chi2tlm_hwb_rnf::b_transport_txsnp);

		SC_THREAD(reset_thread);
		SC_THREAD(work_thread);
	}

	void low_power_enable(bool enable)
	{
		dev_write32(CHI_BRIDGE_LOW_POWER_REG_ADDR, (enable) ? 1 : 0);
	}

	void enable_irq_mode(bool en = true) { m_irq_mode_en = en; }
	void enable_sysco_handshake(bool en = true)
	{
		m_sysco_handshake_en = en;
	}
private:

	void transmitRspPkt(RspPkt_t &rsp)
	{
		static uint32_t rsp_idx = 0;
		const uint32_t rsp_desc_sz = 8;

		sc_bv<RspPkt_t::FLIT_WIDTH> flit;
		int flit_sz_regs = to_regs(flit.length());
		uint32_t rsp_bit;
		uint32_t addr;
		int i;

		rsp_bit = 1 << rsp_idx;

		wait_for_descr_free(TXRSP_OWNERSHIP_REG_ADDR, rsp_idx);

		addr = TXRSP_RAM + rsp_idx * rsp_desc_sz;

		rsp.CreateFlit(flit);

		for (i = 0; i < flit_sz_regs; i++) {
			int firstbit = i*32;
			int lastbit = firstbit + 32-1;
			uint32_t v;

			if (lastbit >= flit.length()) {
				lastbit = flit.length() - 1;
			}

			v = flit.range(lastbit, firstbit).to_uint();

			dev_write32(addr + i*4, v, false);
		}

		dev_write32(TXRSP_OWNERSHIP_FLIP_REG_ADDR, rsp_bit);

		rsp_idx = (rsp_idx + 1) % NUM_TXRSP_DESC_EN;
	}

	virtual void b_transport_txrsp(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		RspPkt_t rsp(&trans);

		if (!probed)
			wait(probed_event);

		transmitRspPkt(rsp);

		// Transmit rsp flit on hw bridge
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	void transmitDatPkt(DatPkt_t &dat)
	{
		static int dat_idx = 0;

		sc_bv<DatPkt_t::FLIT_WIDTH> flit;
		int flit_sz_regs = to_regs(flit.length());
		uint32_t dat_bit;
		uint32_t addr;
		int i;

		dat_bit = 1 << dat_idx;

		wait_for_descr_free(TXDAT_OWNERSHIP_REG_ADDR, dat_idx);

		addr = TXDAT_RAM + dat_idx * TXDAT_DESC_SZ;

		dat.CreateFlit(flit);

		for (i = 0; i < flit_sz_regs; i++) {
			int firstbit = i*32;
			int lastbit = firstbit + 32-1;
			uint32_t v;

			if (lastbit >= flit.length()) {
				lastbit = flit.length() - 1;
			}

			v = flit.range(lastbit, firstbit).to_uint();

			dev_write32(addr + i*4, v, false);
		}

		dev_write32(TXDAT_OWNERSHIP_FLIP_REG_ADDR, dat_bit);

		dat_idx = (dat_idx + 1) % NUM_TXDAT_DESC_EN;
	}

	virtual void b_transport_txdat(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		DatPkt_t dat(&trans);

		if (!probed)
			wait(probed_event);

		transmitDatPkt(dat);

		// Transmit dat flit on hw bridge
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	void transmitSnpPkt(SnpPkt_t &snp)
	{
		static int snp_idx = 0;

		sc_bv<SnpPkt_t::FLIT_WIDTH> flit;
		int flit_sz_regs = to_regs(flit.length());
		uint32_t snp_bit;
		uint32_t addr;
		int i;

		snp_bit = 1 << snp_idx;

		wait_for_descr_free(TXSNP_TXREQ_OWNERSHIP_REG_ADDR, snp_idx);

		addr = TXSNP_RAM + snp_idx * TXSNP_DESC_SZ;

		snp.CreateFlit(flit);

		for (i = 0; i < flit_sz_regs; i++) {
			int firstbit = i*32;
			int lastbit = firstbit + 32-1;
			uint32_t v;

			if (lastbit >= flit.length()) {
				lastbit = flit.length() - 1;
			}

			v = flit.range(lastbit, firstbit).to_uint();

			dev_write32(addr + i*4, v, false);
		}

		dev_write32(TXSNP_TXREQ_OWNERSHIP_FLIP_REG_ADDR, snp_bit);

		snp_idx = (snp_idx + 1) % NUM_TXSNP_DESC_EN;
	}

	virtual void b_transport_txsnp(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		SnpPkt_t snp(&trans);

		if (!probed)
			wait(probed_event);

		transmitSnpPkt(snp);

		// Transmit snp flit on hw bridge
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	bool has_work()
	{
		uint32_t stat = dev_read32(INTR_FLIT_TXN_STATUS_REG_ADDR);

		if (stat & HNF_IRQ_RX_MASK) {
			return true;
		}

		return false;
	}

	void work_thread()
	{
		if (!probed)
			wait(probed_event);

		while (true) {
			uint32_t reqs = 0;
			uint32_t dats = 0;
			uint32_t rsps = 0;
			uint32_t stat = 0;

			if (m_irq_mode_en) {
				if (!irq.read()) {
					wait(irq.posedge_event());
				}
			} else {
				if (!has_work()) {
					sc_time delay(100, SC_US);
					wait(delay);
					continue;
				}
			}

			// Get rx irqs status
			stat = dev_read32(INTR_FLIT_TXN_STATUS_REG_ADDR);

			// Clear irqs to be handled
			dev_write32(INTR_FLIT_TXN_CLEAR_REG_ADDR, stat);

			if (stat & IRQ_RXREQ_FLAG) {
				reqs = dev_read32(RXREQ_RXSNP_OWNERSHIP_REG_ADDR);
			}
			if (stat & IRQ_RXRSP_FLAG) {
				rsps = dev_read32(RXRSP_OWNERSHIP_REG_ADDR);
			}
			if (stat & IRQ_RXDAT_FLAG) {
				dats = dev_read32(RXDAT_OWNERSHIP_REG_ADDR);
			}

			// rxrsp
			if (rsps) {
				process_rxrsp_ch(rsps);
				dev_write32(RXRSP_OWNERSHIP_FLIP_REG_ADDR,
					rsps);
			}

			// rxdat
			if (dats) {
				process_rxdat_ch(dats);
				dev_write32(RXDAT_OWNERSHIP_FLIP_REG_ADDR,
					dats);
			}

			// rxreq
			if (reqs) {
				process_rxreq_ch(reqs);
				dev_write32(
					RXREQ_RXSNP_OWNERSHIP_FLIP_REG_ADDR,
					reqs);
			}

			wait(SC_ZERO_TIME);
		}
	}

	ReqPkt_t *get_rxreq()
	{
		static int req_idx = 0;

		uint32_t addr = RXREQ_RAM + (req_idx * RXREQ_DESC_SZ);

		uint8_t req[RXREQ_DESC_SZ];
		uint32_t r;
		sc_bv<ReqPkt_t::FLIT_WIDTH> flit;
		int i;

		// Read out req from ram
		for (i = 0; i < RXREQ_DESC_SZ/4; i++) {
			uint32_t *d = reinterpret_cast<uint32_t*>(&req[i*4]);

			r = dev_read32(addr | (i << 2));

			d[0] = r;
		}

		req_idx = (req_idx + 1) % NUM_RXREQ_DESC_EN;

		// Convert to flit
		for (i = 0; i < to_bytes(flit.length()); i++) {
			int firstbit = i*8;
			int lastbit = firstbit + 8-1;
			uint8_t mask = (1 << (lastbit-firstbit+1))-1;

			if (lastbit > (flit.length()-1) ) {
				lastbit = flit.length()-1;
			}

			flit.range(lastbit, firstbit) = req[i] & mask;
		}

		return new ReqPkt_t(flit);
	}

	void process_rxreq_ch(uint32_t num_reqs)
	{
		sc_time delay(SC_ZERO_TIME);
		ReqPkt_t *t;

		//
		// num_reqs contains is in number of bits set
		//
		while (num_reqs) {
			num_reqs = clear_next_bit(num_reqs);

			// Receive req from bridge
			t = get_rxreq();

			//
			// Forward the TLM transaction (to the ICN)
			//
			// Run the TLM transaction.
			rxreq_init_socket->b_transport(t->GetGP(), delay);

			wait(delay, resetn.negedge_event());

			delete t;
			t = NULL;
		}
	}

	RspPkt_t *get_rxrsp()
	{
		static int rsp_idx = 0;

		uint32_t addr = RXRSP_RAM + (rsp_idx * RXRSP_DESC_SZ);

		uint8_t rsp[RXRSP_DESC_SZ] = { 0 };
		uint32_t r;
		sc_bv<RspPkt_t::FLIT_WIDTH> flit;
		int i;

		// Read out rsp from ram
		for (i = 0; i < RXRSP_DESC_SZ/4; i++) {
			uint32_t *d = reinterpret_cast<uint32_t*>(&rsp[i*4]);

			r = dev_read32(addr | (i << 2));

			d[0] = r;
		}

		rsp_idx = (rsp_idx + 1) % NUM_RXRSP_DESC_EN;

		// Convert to flit
		for (i = 0; i < to_bytes(flit.length()); i++) {
			int firstbit = i*8;
			int lastbit = firstbit + 8-1;
			uint8_t mask = (1 << (lastbit-firstbit+1))-1;

			if (lastbit > (flit.length()-1) ) {
				lastbit = flit.length()-1;
			}

			flit.range(lastbit, firstbit) = rsp[i] & mask;
		}

		return new RspPkt_t(flit);
	}

	uint32_t clear_next_bit(uint32_t val)
	{
		for (uint32_t i = 0; i < 32; i++) {
			if (val & 1) {
				break;
			}
			val >>= 1;
		}

		// clear first bit;
		val &= ~(1);

		return val;
	}

	void process_rxrsp_ch(uint32_t num_rsp)
	{
		sc_time delay(SC_ZERO_TIME);
		RspPkt_t *t;

		while (num_rsp) {
			num_rsp = clear_next_bit(num_rsp);

			// Receive rsp from bridge
			t = get_rxrsp();

			//
			// Forward the TLM transaction (to the ICN)
			//
			// Run the TLM transaction.
			rxrsp_init_socket->b_transport(t->GetGP(), delay);

			wait(delay, resetn.negedge_event());

			delete t;
			t = NULL;
		}
	}

	DatPkt_t *get_rxdat()
	{
		static int dat_idx = 0;

		uint32_t addr = RXDAT_RAM + (dat_idx * RXDAT_DESC_SZ);

		uint8_t dat[RXDAT_DESC_SZ] = { 0 };
		uint32_t r;
		sc_bv<DatPkt_t::FLIT_WIDTH> flit;
		int i;

		// Read out dat from ram
		for (i = 0; i < RXDAT_DESC_SZ/4; i++) {
			uint32_t *d = reinterpret_cast<uint32_t*>(&dat[i*4]);

			r = dev_read32(addr | (i << 2));

			d[0] = r;
		}

		dat_idx = (dat_idx + 1) % NUM_RXDAT_DESC_EN;

		// Convert to flit
		for (i = 0; i < to_bytes(flit.length()); i++) {
			int firstbit = i*8;
			int lastbit = firstbit + 8-1;
			uint8_t mask = (1 << (lastbit-firstbit+1))-1;

			if (lastbit > (flit.length()-1) ) {
				lastbit = flit.length()-1;
			}

			flit.range(lastbit, firstbit) = dat[i] & mask;
		}

		return new DatPkt_t(flit);
	}

	void process_rxdat_ch(uint32_t num_dats)
	{
		sc_time delay(SC_ZERO_TIME);
		DatPkt_t *t;

		while (num_dats) {
			num_dats = clear_next_bit(num_dats);

			// Receive dat from bridge
			t = get_rxdat();

			//
			// Forward the TLM transaction (to the ICN)
			//
			// Run the TLM transaction.
			rxdat_init_socket->b_transport(t->GetGP(), delay);

			wait(delay, resetn.negedge_event());

			delete t;
			t = NULL;
		}
	}

	void reset_thread(void)
	{
		while (true) {
			//
			// Wait for reset release
			//
			wait(resetn.posedge_event());
			wait(SC_ZERO_TIME);

			bridge_probe();
			bridge_reset();
			bridge_configure();

			probed = true;
			probed_event.notify();
		}
	}

	void bridge_probe()
	{
		uint32_t r;

		r = dev_read32(VERSION_REG_ADDR);
		printf("version=%x\n", r);
		version_major = (r >> 8) & 0xff;
		version_minor = r & 0xff;

		bridge_type = dev_read32(BRIDGE_TYPE_REG_ADDR);
		printf("type=%x\n", bridge_type);
	}

	void bridge_reset()
	{
		dev_write32(RESET_REG_ADDR, ~31);
		wait(10, SC_NS);
		usleep(1000);
		dev_write32(RESET_REG_ADDR, 31);
	}

	void bridge_configure()
	{
		// Rx allow credits reg
		//
		// 1f = (15 <<1) | 1
		//
		uint32_t val =
			(NUM_CREDITS << REFILL_CREDITS_SHIFT) | SET_CREDITS;

		dev_write32(CHI_BRIDGE_RXREQ_RXSNP_REFILL_CREDITS_REG_ADDR, val),
		dev_write32(CHI_BRIDGE_RXRSP_REFILL_CREDITS_REG_ADDR, val),
		dev_write32(CHI_BRIDGE_RXDAT_REFILL_CREDITS_REG_ADDR, val),

		//
		// Enable tx rx irqs, bits [5:0]
		//
		dev_write32(INTR_FLIT_TXN_ENABLE_REG_ADDR, HNF_IRQ_RX_MASK);

		if (m_sysco_handshake_en) {
			//
			// SYSCOACK
			//
			val = 0;
			while ( ( (val >> HNF_SYSCOREQ_SHIFT) & 1 ) == 0) {
				// wait for SYSCOREQ here
				wait(sc_time(10, SC_US));
				val = dev_read32(CHI_BRIDGE_COHERENT_REQ_REG_ADDR);
			}
			dev_write32(CHI_BRIDGE_COHERENT_REQ_REG_ADDR, 1 << 1);
		}

		// bridge configure reg
		dev_write32(CHI_BRIDGE_CONFIGURE_REG_ADDR, 1);
	}

	int to_bytes(int len)
	{
		int sz_bytes = len / 8;

		if (len % 8) {
			sz_bytes++;
		}
		return sz_bytes;
	}

	int to_regs(int len)
	{
		int sz_regs = len / 32;

		if (len % 32) {
			sz_regs++;
		}
		return sz_regs;
	}

	void wait_for_descr_free(uint32_t ownership_reg, uint32_t descr_idx)
	{
		uint32_t r = dev_read32(ownership_reg);

		while ((r >> descr_idx) & 1) {
			wait(sc_time(10, SC_US));
			r = dev_read32(ownership_reg);
		}
	}

	void dev_access(tlm::tlm_command cmd, uint64_t offset,
			void *buf, unsigned int len)
	{
		unsigned char *buf8 = (unsigned char *) buf;
		tlm::tlm_generic_payload dev_tr;
		sc_time delay = SC_ZERO_TIME;

		offset += m_base_addr;

		dev_tr.set_command(cmd);
		dev_tr.set_address(offset);
		dev_tr.set_data_ptr(buf8);
		dev_tr.set_data_length(len);
		dev_tr.set_streaming_width(len);
		dev_tr.set_dmi_allowed(false);
		dev_tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		bridge_socket->b_transport(dev_tr, delay);
		assert(dev_tr.get_response_status() == tlm::TLM_OK_RESPONSE);
	}

	uint32_t dev_read32(uint64_t offset)
	{
		uint32_t r;
		assert((offset & 3) == 0);
		dev_access(tlm::TLM_READ_COMMAND, offset, &r, sizeof(r));
		return r;
	}

	void dev_write32(uint64_t offset, uint32_t v, bool dummy_read = true)
	{
		uint32_t dummy;
		assert((offset & 3) == 0);
		dev_access(tlm::TLM_WRITE_COMMAND, offset, &v, sizeof(v));

		if (dummy_read) {
			dev_access(tlm::TLM_READ_COMMAND, offset,
					&dummy, sizeof(dummy));
		}
	}

	bool m_irq_mode_en;
	bool m_sysco_handshake_en;

	bool probed;
	sc_event probed_event;

	unsigned int version_major;
	unsigned int version_minor;
	unsigned int bridge_type;
	uint64_t m_base_addr;
};

#endif
