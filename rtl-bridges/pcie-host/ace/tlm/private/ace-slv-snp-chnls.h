/*
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
#ifndef __RTL_BRIDGES_ACE_SNP_CHNLS_H__
#define __RTL_BRIDGES_ACE_SNP_CHNLS_H__

#include "regfields.h"

#define SN_REQ_DESC_SZ 0x20
#define SN_RESP_DESC_SZ 0x20

namespace RTL {
namespace AMBA {
namespace ACE {

//
// ACE slave snoop channels
//
template<
	typename A2T_HW_BRIDGE,
	int CD_DATA_WIDTH,
	int CACHELINE_SZ>
class ACESnoopChannels_S :
	public sc_core::sc_module,
	public axi_common
{
public:
	class ACELock :  public sc_core::sc_module
	{
	public:
		ACELock(sc_module_name name, sc_in<bool>& _resetn) :
			sc_module(name),
			resetn(_resetn),
			m_ongoing(false),
			m_addr(0)
		{}

		void lock(uint64_t addr, unsigned int len)
		{
			while (trylock(addr, len) == false) {

				wait(m_unlock_ev |
					resetn.negedge_event());

				if (resetn.read() == 0) {
					return;
				}
			}
			m_ongoing = true;
			m_addr = addr;
			m_len = len;
		}

		bool trylock(uint64_t addr, unsigned int len)
		{
			if (m_ongoing == false) {
				return true;
			} else if (!range_overlap(addr, len)) {
				return true;
			}
			return false;
		}

		void unlock()
		{
			m_ongoing = false;
			m_unlock_ev.notify();
		}

		sc_event& unlock_event() { return m_unlock_ev; }

		uint64_t get_address() { return m_addr; }

	private:
		bool range_overlap(uint64_t addr, unsigned int len)
		{
			uint64_t last_addr = addr + len - 1;

			if (in_locked_range(addr) ||
				in_locked_range(last_addr) ||
				in_range(addr, len, m_addr)) {
				return true;
			}
			return false;
		}

		bool in_range(uint64_t start_addr,
				unsigned int len,
				uint64_t addr)
		{
			return addr >= start_addr &&
				addr < (start_addr + len);
		}

		bool in_locked_range(uint64_t addr)
		{
			return in_range(m_addr, m_len, addr);
		}

		sc_in<bool >& resetn;
		bool m_ongoing;
		uint64_t m_addr;
		unsigned int m_len;
		sc_event m_unlock_ev;
	};

	A2T_HW_BRIDGE *m_bridge;

	tlm_utils::simple_target_socket<ACESnoopChannels_S> snoop_target_socket;

	sc_in<bool >& clk;
	sc_in<bool >& resetn;

	SC_HAS_PROCESS(ACESnoopChannels_S);

	ACELock lock_snoop;
	ACELock lock_rresp;
	ACELock lock_bresp;

	ACESnoopChannels_S(sc_module_name name,
				A2T_HW_BRIDGE *bridge,
				sc_in<bool>& _clk,
				sc_in<bool>& _resetn) :
		sc_module(name),
		axi_common(_clk, _resetn),

		m_bridge(bridge),

		snoop_target_socket("snoop-target-socket"),

		clk(_clk),
		resetn(_resetn),

		lock_snoop("lock_snoop", _resetn),
		lock_rresp("lock_rresp", _resetn),
		lock_bresp("lock_bresp", _resetn)
	{
		snoop_target_socket.register_b_transport(this,
					&ACESnoopChannels_S::b_transport);
		SC_THREAD(reset);
	}

	bool wait_for_snoop_channel(uint64_t addr, unsigned int len)
	{
		//
		// Make sure the snoop channel is not processing the
		// same cacheline.
		//
		while (!lock_snoop.trylock(addr, len)) {

			wait(lock_snoop.unlock_event() |
				resetn.negedge_event());

			if (reset_asserted()) {
				return false;
			}
		}
		return true;
	}

	std::list<tlm::tlm_generic_payload*>& GetOverlapList()
	{
		return m_overlapList;
	}

	bool handle_cd()
	{
		//
		// Only handle CD data if the corresponding CR has been
		// received
		//
		return (cdFifo.num_available() > 0) && !m_CDDescriptors.empty();
	}

	void pop_cr()
	{
		ACETransaction *tr = crFifo.read();
		uint32_t idx = dev_read32(SN_RESP_FIFO_POP_DESC_REG_ADDR);
		uint32_t cr_desc_addr;
		uint32_t crresp;

		//
		// Assert valid bit is set
		//
		assert(valid_bit(idx));

		idx = descr_idx(idx);

		cr_desc_addr = SN_RESP_DESC_N_BASE_ADDR + idx * SN_RESP_DESC_SZ;

		crresp = dev_read32(cr_desc_addr + SN_RESP_DESC_N_RESP_REG_ADDR);

		dev_write32(SN_RESP_FREE_DESC_REG_ADDR, 1 << idx);

		tr->SetCrResp(crresp);

		if (tr->HasErrorBit()) {
			abort(tr);
		} else if (tr->HasDataTransfer()) {
			cdFifo.write(tr);
		} else {
			tlm::tlm_generic_payload& trans = tr->GetGP();

			trans.set_response_status(tlm::TLM_OK_RESPONSE);
			tr->DoneEvent().notify();
		}
	}

	void pop_cd_descriptor()
	{
		uint32_t idx = dev_read32(SN_DATA_FIFO_POP_DESC_REG_ADDR);

		m_CDDescriptors.push_back(idx);
	}

	void pop_cd()
	{
		ACETransaction *tr = cdFifo.read();
		tlm::tlm_generic_payload& trans = tr->GetGP();
		unsigned char *data = tr->GetData();
		unsigned int len = tr->GetDataLen();
		unsigned int pos = 0;
		uint32_t cddata_ram_addr;
		uint32_t idx;

		if (m_CDDescriptors.empty()) {
			SC_REPORT_ERROR("ace2tlm_hw_bridge",
				"ACESnoopChannels_S pop_cd when"
				" m_CDDescriptors.empty");
		}

		idx = m_CDDescriptors.front();

		assert(valid_bit(idx));

		m_CDDescriptors.pop_front();

		idx = descr_idx(idx);

		cddata_ram_addr = CD_DATA_RAM + idx * CACHELINE_SZ;

		for (; pos < len;) {
			uint32_t d = dev_read32(cddata_ram_addr);

			for (unsigned int i = 0; i < 4; i++) {
				unsigned shift = i * 8;

				//
				// Place byte and byte enable
				//
				//
				data[pos++] = (d >> shift) & 0xFF;

				if (pos >= len) {
					// Done
					break;
				}
			}

			cddata_ram_addr += 4;
		}
		dev_write32(SN_DATA_FREE_DESC_REG_ADDR, 1 << idx);

		// Set response and notify
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		tr->DoneEvent().notify();
	}

private:
	class ACETransaction :
		public ace_tx_helpers
	{
	public:
		ACETransaction(tlm::tlm_generic_payload& gp) :
			m_gp(gp)
		{
			m_gp.get_extension(m_genattr);

			setup_ace_helpers(&m_gp);
		}

		tlm::tlm_generic_payload& GetGP() { return m_gp; }

		uint8_t GetAxProt()
		{
			uint8_t AxProt = 0;

			if (m_genattr && m_genattr->get_non_secure()) {
				AxProt |= AXI_PROT_NS;
			}
			return AxProt;
		}

		unsigned char *GetData() { return m_gp.get_data_ptr(); }
		unsigned int GetDataLen() { return m_gp.get_data_length(); }
		uint64_t GetAddress() { return m_gp.get_address(); }

		void SetCrResp(uint8_t resp)
		{
			if (m_genattr) {
				if ((resp >> CR::DataTransferShift) & 0x1) {
					m_genattr->set_datatransfer();
				}

				if ((resp >> CR::ErrorBitShift) & 0x1) {
					m_genattr->set_error_bit();
				}

				if ((resp >> CR::PassDirtyShift) & 0x1) {
					m_genattr->set_dirty();
				}

				if ((resp >> CR::IsSharedShift) & 0x1) {
					m_genattr->set_shared();
				}

				if ((resp >> CR::WasUniqueShift) & 0x1) {
					m_genattr->set_was_unique();
				}
			}
		}

		sc_event& DoneEvent() { return m_done; }
	private:
		tlm::tlm_generic_payload& m_gp;
		genattr_extension *m_genattr;
		sc_event m_done;
	};

	void wait_for_response_channels(uint64_t addr, unsigned int len)
	{
		bool rresp_ok = false;
		bool bresp_ok = false;

		//
		// Make sure the same cache line is not being
		// processed on the response channels.
		//
		while (!rresp_ok || !bresp_ok) {
			// Check rresp channel
			rresp_ok = lock_rresp.trylock(addr, len);
			if (rresp_ok == false) {

				wait(lock_rresp.unlock_event() |
					resetn.negedge_event());

				if (reset_asserted()) {
					return;
				}
			}

			// Check bresp channel
			bresp_ok = lock_bresp.trylock(addr, len);
			if (bresp_ok == false) {

				wait(lock_bresp.unlock_event() |
					resetn.negedge_event());

				if (reset_asserted()) {
					return;
				}
			}
		}
	}

	bool addresses_overlap(tlm::tlm_generic_payload *gp1,
				tlm::tlm_generic_payload *gp2)
	{
		uint64_t addr1 = gp1->get_address();
		unsigned int len1 = gp1->get_data_length();
		uint64_t addr2 = gp2->get_address();
		unsigned int len2 = gp2->get_data_length();
		uint64_t last_addr2 = addr2 + len2 - 1;

		if (in_range(addr1, len1, addr2) ||
			in_range(addr1, len1, last_addr2) ||
			in_range(addr2, len2, addr1)) {
			return true;
		}
		return false;
	}

	bool in_range(uint64_t start_addr,
			unsigned int len,
			uint64_t addr)
	{
		return addr >= start_addr &&
			addr < (start_addr + len);
	}

	bool wait_for_overlapping_tx(tlm::tlm_generic_payload *gp)
	{
		typename
		std::list<tlm::tlm_generic_payload*>::iterator it;

		for (it = m_overlapList.begin(); (*it) != gp; it++) {
			 tlm::tlm_generic_payload *list_gp= (*it);

			if (addresses_overlap(list_gp, gp)) {
				return true;
			}
		}
		return false;
	}

	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		ACETransaction tr(trans);

		//
		// Wait for the delay
		//
		wait(delay, resetn.negedge_event());
		if (reset_asserted()) {
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
			return;
		}
		delay = SC_ZERO_TIME;

		//
		// Make sure that responses for transactions with
		// overlapping addresses are handled in order with this
		// snoop
		//
		m_overlapList.push_back(&trans);

		while (wait_for_overlapping_tx(&trans)) {

			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
				return;
			}
		}

		//
		// Lock out responses until done
		//
		wait_for_response_channels(tr.GetAddress(),
						tr.GetDataLen());
		if (reset_asserted()) {
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
			return;
		}

		lock_snoop.lock(tr.GetAddress(),
				tr.GetDataLen());

		//acFifo.write(&tr);
		push_on_ac_ch(&tr);

		wait(tr.DoneEvent());

		m_overlapList.remove(&trans);

		lock_snoop.unlock();
	}

	//
	// Transmits
	//
	void push_on_ac_ch(ACETransaction *tr)
	{
		static unsigned int ac_desc_idx = 0;
		uint32_t base_addr;
		uint64_t addr = tr->GetAddress();

		base_addr = SN_REQ_DESC_N_BASE_ADDR +
				ac_desc_idx * SN_REQ_DESC_SZ;
		//
		// Transmit on ac channels
		//
		dev_write32(base_addr + SN_REQ_DESC_N_ACADDR_0_REG_ADDR,
				(uint32_t)(addr & 0xFFFFFFFF));
		dev_write32(base_addr + SN_REQ_DESC_N_ACADDR_1_REG_ADDR,
				(uint32_t)((addr>>32) & 0xFFFFFFFF));

		// snoop + prot
		dev_write32(base_addr + SN_REQ_DESC_N_ATTR_REG_ADDR,
				gen_acprot(tr->GetAxProt()) |
				gen_acsnoop(tr->GetAxSnoop()) );

		//
		// push descriptor
		//
		dev_write32(SN_REQ_FIFO_PUSH_DESC_REG_ADDR,
				gen_valid_bit(1) | ac_desc_idx);

		//
		// To next ac_desc_idx
		//
		ac_desc_idx = (ac_desc_idx + 1) % A2T_HW_BRIDGE::MAX_DESC_IDX;

		//
		// Wait for crresp
		//
		crFifo.write(tr);
	}

	void reset()
	{
		while(true) {
			wait(resetn.negedge_event());

			tlm2axi_clear_fifo(acFifo);
			tlm2axi_clear_fifo(crFifo);
			tlm2axi_clear_fifo(cdFifo);

			lock_snoop.unlock();
			lock_rresp.unlock();
			lock_bresp.unlock();
		}
	}

	uint32_t dev_read32(uint64_t offset)
	{
		return m_bridge->dev_read32(offset);
	}

	void dev_write32(uint64_t offset, uint32_t v, bool dummy_read = true)
	{
		m_bridge->dev_write32(offset, v, dummy_read);
	}

	sc_fifo<ACETransaction*> acFifo;
	sc_fifo<ACETransaction*> crFifo;
	sc_fifo<ACETransaction*> cdFifo;

	std::list<tlm::tlm_generic_payload*> m_overlapList;

	std::list<uint32_t> m_CDDescriptors;
};

}
}
}

#endif
