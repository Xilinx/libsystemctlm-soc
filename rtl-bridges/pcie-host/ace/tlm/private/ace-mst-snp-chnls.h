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
#ifndef __RTL_BRIDGES_ACE_MST_SNP_CHNLS_H__
#define __RTL_BRIDGES_ACE_MST_SNP_CHNLS_H__

#include "regfields.h"

#define SN_REQ_DESC_SZ 0x20
#define SN_RESP_DESC_SZ 0x20

namespace RTL {
namespace AMBA {
namespace ACE {

//
// ACE master snoop channels
//
template<typename T2A_HW_BRIDGE,
	int CD_DATA_WIDTH,
	int CACHELINE_SZ>
class ACESnoopChannels_M : public sc_core::sc_module,
	public axi_common,
	public ace_helpers
{
public:
	tlm_utils::simple_initiator_socket<ACESnoopChannels_M> snoop_init_socket;

	sc_in<bool >& clk;
	sc_in<bool >& resetn;

	SC_HAS_PROCESS(ACESnoopChannels_M);

	ACESnoopChannels_M(sc_module_name name,
				T2A_HW_BRIDGE *bridge,
				sc_in<bool>& _clk,
				sc_in<bool>& _resetn) :
		sc_module(name),
		axi_common(_clk, _resetn),

		snoop_init_socket("snoop-init-socket"),

		clk(_clk),
		resetn(_resetn),

		m_bridge(bridge),

		m_cur_TLM(NULL),
		m_numDVMSyncResp(0),
		m_numACE(0)
	{
		SC_THREAD(cr_thread);
		SC_THREAD(cd_thread);

		SC_THREAD(reset);
	}

	sc_event& DVMSyncRespEvent() { return m_dvm_sync_resp_event; }

	unsigned int GetNumDVMSyncResp() { return m_numDVMSyncResp; }
	void DecNumDVMSyncResp() { m_numDVMSyncResp--; }

	void pop_ac()
	{
		uint32_t idx = dev_read32(SN_REQ_FIFO_POP_DESC_REG_ADDR);
		uint32_t ac_desc_addr;
		ACETransaction *tr;
		uint64_t acaddr;
		uint32_t r;

		assert(valid_bit(idx));

		idx = descr_idx(idx);

		ac_desc_addr = SN_REQ_DESC_N_BASE_ADDR + idx * SN_REQ_DESC_SZ;

		acaddr = dev_read32(ac_desc_addr + SN_REQ_DESC_N_ACADDR_1_REG_ADDR);
		acaddr <<= 32;
		r = dev_read32(ac_desc_addr + SN_REQ_DESC_N_ACADDR_0_REG_ADDR);
		acaddr |= r;

		r = dev_read32(ac_desc_addr + SN_REQ_DESC_N_ATTR_REG_ADDR);

		tr = new ACETransaction(acaddr, acsnoop(r), acprot(r));

		assert(tr);

		//
		// Free descriptor
		//
		dev_write32(SN_REQ_FREE_DESC_REG_ADDR, 1 << idx);

		//
		// queue tr
		//
		m_crList.push_back(tr);
		m_numACE++;
		m_acEvent.notify();;
	}

private:

	class ACETransaction :
		public ace_tx_helpers
	{
	public:
		ACETransaction(uint64_t address,
				uint8_t  snoop,
				uint8_t  prot) :
			m_gp(new tlm::tlm_generic_payload()),
			m_genattr(new genattr_extension()),
			m_abortScheduled(false)
		{
			uint32_t dataLen = CACHELINE_SZ;
			uint8_t *data = new uint8_t[CACHELINE_SZ];

			if (IsNonSecure(prot)) {
				m_genattr->set_non_secure();
			}
			m_genattr->set_snoop(snoop);

			m_gp->set_command(tlm::TLM_READ_COMMAND);
			m_gp->set_address(address);
			m_gp->set_data_length(dataLen);
			m_gp->set_data_ptr(reinterpret_cast<unsigned char*>(data));

			m_gp->set_byte_enable_ptr(NULL);
			m_gp->set_byte_enable_length(0);

			m_gp->set_streaming_width(dataLen);

			m_gp->set_dmi_allowed(false);
			m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

			m_gp->set_extension(m_genattr);

			setup_ace_helpers(m_gp);
		}

		~ACETransaction()
		{
			delete[] m_gp->get_data_ptr();

			delete m_gp; // Also deletes m_genattr
		}

		bool IsNonSecure(uint8_t prot)
		{
			return (prot & AXI_PROT_NS) == AXI_PROT_NS;
		}

		tlm::tlm_generic_payload* GetGP() { return m_gp; }

		void SetAbortScheduled() { m_abortScheduled = true; }
		bool AbortScheduled() { return m_abortScheduled; }

		uint32_t GetCrResp()
		{
			uint32_t resp = 0;

			if (m_genattr->get_datatransfer()) {
				resp |= 0x1 << CR::DataTransferShift;
			}
			if (m_genattr->get_error_bit()) {
				resp |= 0x1 << CR::ErrorBitShift;
			}
			if (m_genattr->get_shared()) {
				resp |= 0x1 << CR::IsSharedShift;
			}
			if (m_genattr->get_dirty()) {
				resp |= 0x1 << CR::PassDirtyShift;
			}
			if (m_genattr->get_was_unique()) {
				resp |= 0x1 << CR::WasUniqueShift;
			}

			return resp;
		}

		bool HasDataTransfer()
		{
			return m_genattr->get_datatransfer();
		}

		unsigned char *GetData() { return m_gp->get_data_ptr(); }
		unsigned int GetDataLen() { return m_gp->get_data_length(); }

	private:
		tlm::tlm_generic_payload *m_gp;
		genattr_extension *m_genattr;
		bool m_abortScheduled;
	};

	void push_on_cr_ch(ACETransaction *tr)
	{
		static unsigned int cr_desc_idx = 0;
		uint32_t base_addr;

		base_addr = SN_RESP_DESC_N_BASE_ADDR +
				cr_desc_idx * SN_RESP_DESC_SZ;

		//
		// Setup cresp
		//
		dev_write32(base_addr + SN_RESP_DESC_N_RESP_REG_ADDR,
				tr->GetCrResp());

		//
		// push descriptor
		//
		dev_write32(SN_RESP_FIFO_PUSH_DESC_REG_ADDR,
				gen_valid_bit(1) | cr_desc_idx);

		//
		// To next cr_desc_idx
		//
		cr_desc_idx = (cr_desc_idx + 1) % T2A_HW_BRIDGE::MAX_DESC_IDX;
	}

	void cr_thread()
	{
		while (true) {
			ACETransaction *tr;

			if (m_crList.empty()) {
				wait(m_acEvent);
			}
			tr = m_crList.front();
			m_crList.pop_front();

			run_tlm(tr);

			if (reset_asserted()) {
				delete tr;
				wait_for_reset_release();
				continue;
			}
			if (tr->AbortScheduled()) {
				delete tr;
				continue;
			}

			//
			// Transmit cresp
			//
			push_on_cr_ch(tr);

			if (tr->HasDataTransfer()) {
				m_cdFifo.write(tr);
				tr = NULL;
			}

			if (tr) {
				if (tr->IsDVMSync()) {
					m_numDVMSyncResp++;
					m_dvm_sync_resp_event.notify();
				}

				delete tr;
				m_numACE--;
			}
		}
	}

	void run_tlm(ACETransaction *tr)
	{
		sc_time delay(SC_ZERO_TIME);
		tlm::tlm_generic_payload *gp = tr->GetGP();

		m_cur_TLM = tr;

		// Run the TLM transaction.
		snoop_init_socket->b_transport(*gp, delay);

		m_cur_TLM = NULL;

		//
		// Exit if reset is asserted or has been asserted
		if (reset_asserted()) {
			return;
		}
		if (tr->AbortScheduled()) {
			return;
		}

		//
		// Wait for annotated delay but abort if reset is
		// asserted.
		//
		wait(delay, resetn.negedge_event());
	}

	void cd_thread()
	{
		unsigned int cd_desc_idx = 0;

		while (true) {
			ACETransaction *tr;
			unsigned char *data;
			unsigned int len;
			uint32_t cddata_ram_addr;

			tr = m_cdFifo.read();

			data = tr->GetData();
			len = tr->GetDataLen();

			cddata_ram_addr = CD_DATA_RAM + (cd_desc_idx * CACHELINE_SZ);

			//
			// push CD data
			//
			while (len) {
				uint32_t val = 0;

				//
				// Move over 4 bytes (or the ones that are left)
				//
				for (int i = 0; i < 4; i++) {
					unsigned int shift = i * 8;;

					val |= data[0] << shift;

					data++;
					len--;

					if (len == 0) {
						break;
					}
				}

				dev_write32(cddata_ram_addr, val);
				cddata_ram_addr += 4;
			}


			//
			// push cd desc idx
			//
			dev_write32(SN_DATA_FIFO_PUSH_DESC_REG_ADDR,
					gen_valid_bit(1) | cd_desc_idx);

			//
			// To next cr_desc_idx
			//
			cd_desc_idx =
				(cd_desc_idx + 1) % T2A_HW_BRIDGE::MAX_DESC_IDX;

			// Done
			delete tr;
			m_numACE--;
		}
	}

	void ClearList(std::list<ACETransaction*>& l)
	{
		typename std::list<ACETransaction*>::iterator it;

		for (it = l.begin(); it != l.end(); it++) {
			ACETransaction *t = (*it);
			delete t;
		}
		l.clear();
	}

	void reset()
	{
		while(true) {
			wait(resetn.negedge_event());

			ClearList(m_crList);

			axi2tlm_clear_fifo(m_cdFifo);

			if (m_cur_TLM) {
				m_cur_TLM->SetAbortScheduled();
			}
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

	T2A_HW_BRIDGE *m_bridge;

	std::list<ACETransaction*> m_crList;
	sc_fifo<ACETransaction*> m_cdFifo;
	ACETransaction *m_cur_TLM;

	unsigned int m_numDVMSyncResp;
	unsigned int m_numACE;

	sc_event m_dvm_sync_resp_event;
	sc_event m_acEvent;
};

}
}
}

#endif
