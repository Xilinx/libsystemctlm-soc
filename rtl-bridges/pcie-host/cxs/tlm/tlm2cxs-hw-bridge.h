/*
 * CXS <-> TLM-2.0 HW bridge.
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
 *
 * [1] AMBA CXS Protocol Specification, Issue A, ARM IHI 0079
 * [2] CCIX Base Specification Revision 1.0 Version 1.0
 *
 */

#ifndef TLM2CXS_HW_BRIDGE_H__
#define TLM2CXS_HW_BRIDGE_H__

#include <unistd.h>

#include "cxs-regs.h"

#include "tlm-bridges/private/ccix/pkts.h"

#define CXS_IRQ_RX_FLAG 0x1
#define CXS_IRQ_TX_FLAG 0x2
#define CXS_IRQ_MASK (CXS_IRQ_TX_FLAG | CXS_IRQ_RX_FLAG)

#define SET_CREDITS (1 << 4)
#define NUM_RX_DESC_EN 15
#define NUM_TX_DESC_EN 15

#define LINK_STATUS_MASK 0x3
#define LINK_STATUS_UP 3

#define CXS_LOG2(x) \
((x == 2) ? 1 :	\
(x == 4) ? 2 :  \
(x == 8) ? 3 :  \
(x == 16) ? 4 : 5)

using namespace CCIX;

template<
	int _FLIT_WIDTH = 256,
	int _MAX_PKT_PER_FLIT = 2,
	typename TLPHdr = TLPHdr_comp
>
class tlm2cxs_hw_bridge :
	public sc_core::sc_module
{
public:
	enum {
		FLIT_WIDTH = _FLIT_WIDTH,
		MAX_PKT_PER_FLIT = _MAX_PKT_PER_FLIT,

		//
		// Following CXS paramater values are used in the bridge:
		//
		// CXSCONTINUESDATA == true
		// CXSERRORFULLPKT == true
		// CXSCHECKTYPE == false
		// CXSLINKCONTROL == true
		//

		//
		// See 4.2.1 [1]
		//
		START_PTR_WIDTH = CXS_LOG2(FLIT_WIDTH/128),
		END_PTR_WIDTH = CXS_LOG2(FLIT_WIDTH/32),

		//
		// Sum of the widths of the START, END, ERROR, START PTRS and
		// END PTRS fields
		//
		CNTL_WIDTH =
			(3 * MAX_PKT_PER_FLIT) +
			(MAX_PKT_PER_FLIT * START_PTR_WIDTH) +
			(MAX_PKT_PER_FLIT * END_PTR_WIDTH),
	};

	typedef tlm2cxs_hw_bridge<FLIT_WIDTH,
				MAX_PKT_PER_FLIT,
				TLPHdr> tlm2cxs_hwb_t;

	typedef CXSCntl<tlm2cxs_hwb_t> CXSCntl_t;
	typedef TLPHdr TLPHdr_t;
	typedef TLP<tlm2cxs_hwb_t> TLP_t;
	typedef TLPAssembler<TLPHdr_t> TLPAssembler_t;
	typedef TLPFactory<tlm2cxs_hwb_t> TLPFactory_t;

	tlm_utils::simple_target_socket<tlm2cxs_hwb_t> txlink_tgt_socket;
	tlm_utils::simple_initiator_socket<tlm2cxs_hwb_t> rxlink_init_socket;

	// AXI4Lite init_socket
	tlm_utils::simple_initiator_socket<tlm2cxs_hwb_t> bridge_socket;

	sc_in<bool > resetn;
	sc_in<bool > irq;

	SC_HAS_PROCESS(tlm2cxs_hw_bridge);

	tlm2cxs_hw_bridge(sc_core::sc_module_name name,
			uint32_t base_addr = 0) :

		sc_module(name),

		txlink_tgt_socket("txlink_tgt_socket"),
		rxlink_init_socket("rxlink_init_socket"),

		bridge_socket("bridge_socket"),

		resetn("resetn"),
		irq("irq"),

		m_tx_idx(0),
		m_rx_idx(0),

		m_irq_mode_en(false),

		probed(false),
		probed_event("probed_event"),

		m_txDone(true),
		m_txDoneEvent("txdone_event"),

		version_major(0),
		version_minor(0),
		bridge_type(0),
		m_base_addr(base_addr)
	{
		txlink_tgt_socket.register_b_transport(
				this, &tlm2cxs_hw_bridge::b_transport_txlink);


		SC_THREAD(reset_thread);
		SC_THREAD(work_thread);
	}

	void enable_irq_mode(bool en = true) { m_irq_mode_en = en; }

        void low_power_enable(bool enable)
        {
                dev_write32(CXS_BRIDGE_LOW_POWER_REG_ADDR, (enable) ? 1 : 0);
        }

private:
	enum {
		//
		// FLIT_WIDTH in bytes
		//
		FW = FLIT_WIDTH/8,

		//
		// CNTL_WIDTH in bytes (FCW max is 8, see 4.2.2 [1])
		//
		FCW = (CNTL_WIDTH > 32) ? 8 : 4,
	};

	//
	// Bytes to regs
	//
	int to_regs(int len)
	{
		int sz_regs = len / 4;

		if (len % 4) {
			sz_regs++;
		}
		return sz_regs;
	}

	void IncTxIdx()
	{
		m_tx_idx = (m_tx_idx + 1) % NUM_TX_DESC_EN;
	}
	int GetTxIdx() { return m_tx_idx; }

	void SetupFlit(TLP_t *t, int tx_idx)
	{
		uint32_t tx_data_addr = TX_BASE_DATA + (tx_idx * FW);
		uint32_t tx_cntl_addr = TX_BASE_CNTL + (tx_idx * FCW);

		sc_bv<FLIT_WIDTH> txdata;
		CXSCntl_t cntl;
		uint32_t tx_bit;
		int i;

		t->CreateFlit(txdata, 0, cntl);

		//
		// TX Data
		//
		for (i = 0; i < to_regs(FW); i++) {
			int firstbit = i*32;
			int lastbit = firstbit + 32-1;
			uint32_t v;

			if (lastbit >= txdata.length()) {
				lastbit = txdata.length() - 1;
			}

			v = txdata.range(lastbit, firstbit).to_uint();

			dev_write32(tx_data_addr + i*4, v, false);
		}

		//
		// TX cntl
		//
		for (i = 0; i < to_regs(FCW); i++) {
			uint32_t shift = i * 32;

			dev_write32(tx_cntl_addr + i*4,
					cntl.to_uint64() >> shift);
		}
	}

	void transmitTLP(TLP_t *t)
	{
		//
		// Transmit one TLP at the time because of continuous data, also
		// max packet size (see 3.10.2.2 [2]) needs to fit flit array
		//
		uint32_t own_flip = 0;

		m_mutex.lock();

		m_txDone = false;

		while (!t->Done()) {

			int tx_idx = GetTxIdx();

			own_flip |= (1 << tx_idx);

			SetupFlit(t, tx_idx);

			IncTxIdx();
		}

		dev_write32(TX_OWNERSHIP_FLIP_REG_ADDR, own_flip);

		if (!m_txDone) {
			wait(m_txDoneEvent);
		}

		m_mutex.unlock();
	}

	virtual void b_transport_txlink(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		TLP_t *t = TLPFactory_t::Create(&trans);

		assert(t);

		if (!probed) {
			wait(probed_event);
		}

		transmitTLP(t);
		trans.set_response_status(tlm::TLM_OK_RESPONSE);

		delete t;
	}

	void processRxCntl(uint64_t rx_cntl)
	{
		CXSCntl_t cntl(rx_cntl);

		std::vector<unsigned int>::iterator ptr_it;
		typename std::list<TLPAssembler_t*>::iterator tlpas_it;

		//
		// Parse all StartPtrs
		//
		ptr_it = cntl.GetStartPtrs().begin();

		for (; ptr_it != cntl.GetStartPtrs().end(); ptr_it++) {

			unsigned int ptr = (*ptr_it);
			unsigned int flit_start_pos;

			flit_start_pos = ptr * CXSCntl_t::Align_128;

			//
			// Create a new assembler for each StartBit / StartPtr
			//
			m_assemblers.push_back(new TLPAssembler_t(flit_start_pos));
		}

		//
		// Parse all EndPtrs
		//
		tlpas_it = m_assemblers.begin();
		ptr_it = cntl.GetEndPtrs().begin();

		for (;ptr_it != cntl.GetEndPtrs().end(); ptr_it++, tlpas_it++) {

			unsigned int ptr = (*ptr_it);
			unsigned int flit_end_pos = ptr * CXSCntl_t::Align_32;

			TLPAssembler_t *tlpAs;

			//
			// There must be an assembler for each end bit
			//
			assert(tlpas_it != m_assemblers.end());

			//
			// Assign the EndPtr on the corresponding assembler
			//
			tlpAs = (*tlpas_it);
			tlpAs->SetEndPtr(flit_end_pos);
		}
	}

	//
	// Assemble TLP data
	//
	void processRxData(std::vector<uint32_t>& rx_data)
	{
		std::vector<uint32_t>::iterator it;
		int flit_pos = 0;

		//
		// Process 4 bytes (32 bits) at a time
		//
		for (it = rx_data.begin(); it != rx_data.end(); it++) {
			if (!m_assemblers.empty()) {
				TLPAssembler_t *tlpAs = m_assemblers.front();

				if (flit_pos >= tlpAs->GetStartPtr()) {

					uint32_t val = (*it);

					tlpAs->PushBack(val);

					if (tlpAs->Done(flit_pos)) {
						m_assemblers.remove(tlpAs);

						tlpAs->ExtractCCIXMessages(m_ccixMsgs);

						delete tlpAs;
					}
				}
			}

			//
			// flit_pos is in bits
			//
			flit_pos += 32;
		}

		if (!m_assemblers.empty()) {
			//
			// For next flit collect data from the beginning
			//
			assert(m_assemblers.size() == 1);

			m_assemblers.front()->SetStartPtr(0);
		}
	}

	void IncRxIdx()
	{
		m_rx_idx = (m_rx_idx + 1) % NUM_RX_DESC_EN;
	}
	int GetRxIdx() { return m_rx_idx; }

	void receive_flit()
	{
		int rx_idx = GetRxIdx();

		uint32_t rx_data_addr = RX_BASE_DATA + (rx_idx * FW);
		uint32_t rx_cntl_addr = RX_BASE_CNTL + (rx_idx * FCW);

		uint32_t rx_bit;
		std::vector<uint32_t> rx_data;
		uint64_t rx_cntl = 0;
		int i;

		rx_bit = 1 << rx_idx;

		//
		// Read out data from ram
		//
		for (i = 0; i < to_regs(FW); i++) {
			uint32_t reg_addr = rx_data_addr + i * 4;

			rx_data.push_back(dev_read32(reg_addr));
		}

		//
		// Read out cntl from ram
		//
		for (i = 0; i < to_regs(FCW); i++) {
			uint32_t reg_addr = rx_cntl_addr + i * 4;
			uint32_t shift = i * 32;
			uint32_t r;

			r = dev_read32(reg_addr);

			rx_cntl |= r << shift;
		}

		dev_write32(RX_OWNERSHIP_FLIP_REG_ADDR, rx_bit);

		IncRxIdx();

		processRxCntl(rx_cntl);
		processRxData(rx_data);
	}

	uint32_t clear_next_bit(uint32_t val)
	{
		for (uint32_t i = 0; i < 32; i++) {
			if (val & 1) {
				break;
			}
			val >>= 1;
		}

		// Clear first bit
		val &= ~(1);

		return val;
	}

	void process_rx_flits(uint32_t num_flits)
	{
		//
		// Receive the number of bits set in num_flits
		//
		while (num_flits) {
			num_flits = clear_next_bit(num_flits);

			receive_flit();

			while (!m_ccixMsgs.empty()) {
				sc_time delay(SC_ZERO_TIME);
				IMsg *msg;

				msg = m_ccixMsgs.front();
				m_ccixMsgs.pop_front();

				rxlink_init_socket->b_transport(msg->GetGP(), delay);

				wait(delay, resetn.negedge_event());

				delete msg;
			}
		}
	}

	bool has_work()
	{
		uint32_t stat = dev_read32(INTR_FLIT_TXN_STATUS_REG_ADDR);

		return stat & CXS_IRQ_MASK;
	}

	void work_thread()
	{
		if (!probed) {
			wait(probed_event);
		}

		while (true) {
			uint32_t stat;

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

			//
			// Read status & clear irqs
			//
			stat = dev_read32(INTR_FLIT_TXN_STATUS_REG_ADDR);

			dev_write32(INTR_FLIT_TXN_CLEAR_REG_ADDR, stat);

			//
			// Notify m_txDoneEvent
			//
			if (stat & CXS_IRQ_TX_FLAG) {
				m_txDone = true;
				m_txDoneEvent.notify();
			}

			//
			// Receive flits
			//
			if (stat & CXS_IRQ_RX_FLAG) {
				uint32_t rx_flits = dev_read32(RX_OWNERSHIP_REG_ADDR);

				process_rx_flits(rx_flits);
			}


			wait(SC_ZERO_TIME);
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

		m_tx_idx = 0;
		m_rx_idx = 0;
	}

	void bridge_configure()
	{
		uint32_t r;

		//
		// RX credits
		//
		dev_write32(CXS_BRIDGE_RX_REFILL_CREDITS_REG_ADDR,
				SET_CREDITS | NUM_RX_DESC_EN);

		//
		// Enable TX / RX irqs, bits [0] = 1
		//
		dev_write32(INTR_FLIT_TXN_ENABLE_REG_ADDR, CXS_IRQ_MASK);

		//
		// Enable bridge
		//
		dev_write32(CXS_BRIDGE_CONFIGURE_REG_ADDR, 1);

		//
		// Wait for the TX link to come up
		//
		r = dev_read32(CXS_BRIDGE_CHANNEL_TX_STS_REG_ADDR);
		while ( (r & LINK_STATUS_MASK) != LINK_STATUS_UP) {
			wait(sc_time(10, SC_US));
			r = dev_read32(CXS_BRIDGE_CHANNEL_TX_STS_REG_ADDR);
		}

		//
		// Wait for the RX link to come up
		//
		r = dev_read32(CXS_BRIDGE_CHANNEL_RX_STS_REG_ADDR);
		while ( (r & LINK_STATUS_MASK) != LINK_STATUS_UP) {
			wait(sc_time(10, SC_US));
			r = dev_read32(CXS_BRIDGE_CHANNEL_RX_STS_REG_ADDR);
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

	//
	// TLP Assemblers
	//
	std::list<TLPAssembler_t*> m_assemblers;

	//
	// Extracted CCIX messages
	//
	std::list<IMsg*> m_ccixMsgs;

	int m_tx_idx;
	int m_rx_idx;

	bool m_irq_mode_en;

	bool probed;
	sc_event probed_event;

	bool m_txDone;
	sc_event m_txDoneEvent;

	sc_mutex m_mutex;

	unsigned int version_major;
	unsigned int version_minor;
	unsigned int bridge_type;
	uint64_t m_base_addr;
};

#endif
