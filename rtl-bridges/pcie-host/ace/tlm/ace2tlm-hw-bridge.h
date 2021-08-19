/*
 * ACE to TLM HW bridge.
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
 * References:
 *
 * [1] AMBA AXI and ACE Protocol Specification, ARM IHI 0022D, ID102711
 */

#ifndef ACE2TLM_HW_BRIDGE_H__
#define ACE2TLM_HW_BRIDGE_H__

#include "tlm-bridges/amba.h"
#include "tlm-bridges/amba-ace.h"
#include "private/ace-slv-addr.h"
#include "private/ace-slv-snp-chnls.h"
#include "private/regfields.h"

using namespace RTL::AMBA::ACE;

#define RD_REQ_DESC_SZ 0x100
#define RD_RESP_DESC_SZ 0x100
#define WR_REQ_DESC_SZ 0x100
#define WR_RESP_DESC_SZ 0x100

template<
	int DATA_WIDTH = 128,
	int CACHELINE_SZ = 64,
	int ACE_MODE = ACE_MODE_ACE>
class ace2tlm_hw_bridge:
	public sc_core::sc_module
{
private:
	enum { MAX_DESC_IDX = 16 };

	class Transaction :
		public ace_tx_helpers
	{
	public:
		Transaction(tlm::tlm_command cmd,
				uint64_t address,
				uint32_t dataLen,
				uint8_t  numberBytes,
				uint8_t  burstType,
				uint32_t transaction_id,
				uint8_t  AxProt,
				uint8_t  AxLock,
				uint8_t  AxCache,
				uint8_t  AxQoS,
				uint8_t  AxRegion,
				bool with_be = false) :
			m_gp(new tlm::tlm_generic_payload()),
			m_genattr(new genattr_extension()),
			m_burstType(burstType),
			m_abortScheduled(false),
			m_TLMOngoing(false)
		{
			uint8_t *data;

			data = new uint8_t[dataLen];

			assert(numberBytes > 0);
			assert(dataLen > 0);

			if (IsNonSecure(AxProt)) {
				m_genattr->set_non_secure();
			}
			m_genattr->set_burst_width(numberBytes);
			m_genattr->set_transaction_id(transaction_id);
			m_genattr->set_exclusive(AxLock == AXI_LOCK_EXCLUSIVE);
			m_genattr->set_bufferable(GetBufferable(AxCache));
			m_genattr->set_modifiable(GetModifiable(AxCache));
			m_genattr->set_read_allocate(GetReadAllocate(AxCache));
			m_genattr->set_write_allocate(GetWriteAllocate(AxCache));
			m_genattr->set_qos(AxQoS);
			m_genattr->set_region(AxRegion);

			m_gp->set_command(cmd);

			if (burstType == AXI_BURST_FIXED) {
				m_gp->set_address(Align(address, DATA_BUS_BYTES));
			} else {
				m_gp->set_address(address);
			}
			m_gp->set_data_length(dataLen);
			m_gp->set_data_ptr(reinterpret_cast<unsigned char*>(data));

			if (with_be) {
				uint8_t *be = new uint8_t[dataLen];

				m_gp->set_byte_enable_ptr(reinterpret_cast<unsigned char*>(be));
				m_gp->set_byte_enable_length(dataLen);
			} else  {
				m_gp->set_byte_enable_ptr(NULL);
				m_gp->set_byte_enable_length(0);
			}

			if (burstType == AXI_BURST_INCR) {
				m_gp->set_streaming_width(dataLen);
			} else if (burstType == AXI_BURST_FIXED) {
				m_gp->set_streaming_width(DATA_BUS_BYTES);
			} else {
				m_genattr->set_wrap(true);

				// Only model the case where address == Wrap_boundary
				//m_gp->set_streaming_width(numberBytes*burstLen);
				m_gp->set_streaming_width(dataLen);
			}

			m_gp->set_dmi_allowed(false);
			m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

			m_gp->set_extension(m_genattr);

			if (ACE_MODE) {
				setup_ace_helpers(m_gp);
			}
		}

		~Transaction()
		{
			delete[] m_gp->get_data_ptr();

			if (m_gp->get_byte_enable_ptr()) {
				delete[] m_gp->get_byte_enable_ptr();
			}

			delete m_gp; // Also deletes m_genattr
		}

		uint64_t Align(uint64_t addr, uint64_t alignTo)
		{
			return (addr / alignTo) * alignTo;
		}

		unsigned int GetDataLen()
		{
			return m_gp->get_data_length();
		}

		tlm::tlm_response_status GetTLMResponse()
		{
			return m_gp->get_response_status();
		}

		unsigned char *GetData() { return m_gp->get_data_ptr(); }
		unsigned char *GetByteEnable() { return m_gp->get_byte_enable_ptr(); }

		tlm::tlm_generic_payload* GetTLMGenericPayload()
		{
			return m_gp;
		}

		uint32_t GetTransactionID()
		{
			return m_genattr->get_transaction_id();
		}

		bool IsExclusive()
		{
			return m_genattr->get_exclusive();
		}

		bool ExclusiveHandled()
		{
			return m_genattr->get_exclusive_handled();
		}

		void SetDataLen(uint32_t dataLen)
		{
			m_gp->set_data_length(dataLen);
		}

		inline bool GetBufferable(uint8_t AxCache)
		{
			return AxCache & 0x1;
		}

		inline bool GetModifiable(uint8_t AxCache)
		{
			return (AxCache >> 1) & 0x1;
		}

		inline bool GetReadAllocate(uint8_t AxCache)
		{
			return (AxCache >> 2) & 0x1;
		}

		inline bool GetWriteAllocate(uint8_t AxCache)
		{
			return (AxCache >> 3) & 0x1;
		}

		void SetAxSnoop(uint8_t AxSnoop)
		{
			m_genattr->set_snoop(AxSnoop);
		}

		bool WaitForSnoop()
		{
			uint8_t domain = m_genattr->get_domain();

			//
			// Wait for all except or WriteBack WriteClean
			//
			if (domain == Domain::Inner ||
				domain == Domain::Outer) {
				uint8_t snoop = m_genattr->get_snoop();

				if (snoop == AW::WriteBack ||
					snoop == AW::WriteClean) {
					return false;
				}
			}
			return true;
		}

		void SetAxDomain(uint8_t AxDomain)
		{
			m_genattr->set_domain(AxDomain);
		}

		void SetAxBar(uint8_t AxBar)
		{
			bool barrier = (AxBar) ? true : false;

			m_genattr->set_barrier(barrier);
		}

		bool IsNonSecure(uint8_t AxProt)
		{
			return (AxProt & AXI_PROT_NS) == AXI_PROT_NS;
		}

		void SetAbortScheduled() { m_abortScheduled = true; }
		bool AbortScheduled() { return m_abortScheduled; }

		void SetTLMOngoing(bool TLMOngoing = true)
		{
			m_TLMOngoing = TLMOngoing;
		}
		bool TLMOngoing() { return m_TLMOngoing; }

		uint64_t GetAddress() { return m_gp->get_address(); }

		void SetupSingleRdDataTransfers()
		{
			uint8_t domain = m_genattr->get_domain();
			uint8_t snoop = m_genattr->get_snoop();
			uint8_t bar = m_genattr->get_barrier();

			if (ace_helpers::HasSingleRdDataTransfer(domain,
								snoop,
								bar)) {
				m_gp->set_command(tlm::TLM_IGNORE_COMMAND);
				m_genattr->set_is_read_tx(true);
			}
		}

		void SetupNoWrDataTransfers()
		{
			uint8_t domain = m_genattr->get_domain();
			uint8_t snoop = m_genattr->get_snoop();
			uint8_t bar = m_genattr->get_barrier();

			if (bar || ace_helpers::IsEvict(domain, snoop)) {
				m_gp->set_command(tlm::TLM_IGNORE_COMMAND);
				m_genattr->set_is_write_tx(true);
			}
		}

	private:
		tlm::tlm_generic_payload *m_gp;
		genattr_extension *m_genattr;
		uint8_t m_burstType;

		bool m_abortScheduled;
		bool m_TLMOngoing;
	};

	Transaction *GetFirstWithID(std::list<Transaction*> *list,
					uint32_t transactionID)
	{
		for (typename std::list<Transaction*>::iterator it = list->begin();
			it != list->end(); it++) {
			Transaction *t = (*it);

			if (t && t->GetTransactionID() == transactionID) {
				return t;
			}
		}
		return NULL;
	}

	bool InList(std::list<Transaction*>& l, uint32_t id)
	{
		for (typename std::list<Transaction*>::iterator it = l.begin();
			it != l.end(); it++) {
			if ((*it)->GetTransactionID() == id) {
				return true;
			}
		}
		return false;
	}

	bool OverlappingAddress(std::list<Transaction*>* list, Transaction* tr)
	{
		for (typename std::list<Transaction*>::iterator it = list->begin();
			*it != tr; it++) {
			uint64_t address1 = (*it)->GetTLMGenericPayload()->get_address();
			uint64_t address2 = tr->GetTLMGenericPayload()->get_address();

			if ((address1 >> 12) == (address2 >> 12)) {
				return true;
			}
		}
		return false;
	}

	bool is_after_barrier(std::list<Transaction*> *list, Transaction *tr)
	{
		for (typename std::list<Transaction*>::iterator it = list->begin();
			*it != tr; it++) {
			Transaction *t = (*it);

			if (t->IsBarrier()) {
				return true;
			}
		}
		return false;
	}

	bool WaitForTransactions(std::list<Transaction*> *list, Transaction *tr)
	{
		if (ACE_MODE) {
			if (tr->IsBarrier()) {
				//
				// Wait a clock cycle if it is an ACE barrier
				// with transactions that need to complete
				// before the barrier.
				//
				if (tr != list->front()) {
					return true;
				}

			} else {
				//
				// Wait a clock cycle if it is a transactions
				// that has a barrier in front in the queue and
				// it is not WriteBack WriteClean or Evict
				// (section C8.4.1 [1])
				//

				if (is_after_barrier(list, tr)) {

					if (!tr->IsWriteBack() &&
						!tr->IsWriteClean() &&
						!tr->IsEvict()) {
						return true;
					}
				}
			}
		}

		//
		// Issue transactions with overlapping addresses in order [1]
		//
		return OverlappingAddress(list, tr);
	}

	void RunTLMTransaction(std::list<Transaction*> *list,
				uint32_t transactionID,
				sc_fifo<Transaction*> *fifo)
	{
		Transaction *tr;

		//
		// Issue transactions with the same ID in order
		//
		while ((tr = GetFirstWithID(list, transactionID))) {
			sc_time delay(SC_ZERO_TIME);
			tlm::tlm_generic_payload *m_gp = tr->GetTLMGenericPayload();

			tr->SetTLMOngoing();

			while (WaitForTransactions(list, tr) && resetn.read()) {
				wait(clk.posedge_event() | resetn.negedge_event());
			}

			if (reset_asserted()) {
				break;
			}

			// Run the TLM transaction.
			socket->b_transport(*m_gp, delay);

			//
			// Exit if reset is asserted, if abort was scheduled
			// run the loop once more in case another transaction
			// has been added.
			//
			if (reset_asserted()) {
				break;
			} else if (tr->AbortScheduled()) {
				list->remove(tr);
				delete tr;
				continue;
			}

			//
			// Wait for annotated delay but abort if reset is
			// asserted.
			//
			wait(delay, resetn.negedge_event());

			if (reset_asserted()) {
				break;
			}

			if (ACE_MODE == ACE_MODE_ACE) {
				//
				// Keep track of ongoing responses for
				// overlapping address checks with snoop
				// transactions
				//
				m_snp_chnls->GetOverlapList().push_back(m_gp);
			}

			list->remove(tr);

			fifo->write(tr);

			tr->SetTLMOngoing(false);
		}

		if (reset_asserted() && tr) {
			list->remove(tr);
			delete tr;
			wait_for_reset_release();
		}
	}

	bool reset_asserted() { return resetn.read() == false; }

	void wait_for_reset_release()
	{
		do {
			sc_core::wait(clk.posedge_event());
		} while (resetn.read() == false);
	}

	unsigned int get_num_ongoing_read()
	{
		return m_numReadTransactions - m_numReadBarriers;
	}

	void push_rd_data(Transaction *rt)
	{
		uint8_t *data = rt->GetData();
		unsigned int dataLen = rt->GetDataLen();
		uint32_t addr = RD_DATA_RAM;

		while (dataLen) {
			uint32_t val = 0;

			//
			// Move over 4 bytes (or the ones that are left)
			//
			for (int i = 0; i < 4; i++) {
				unsigned int shift = i * 8;;

				val |= data[0] << shift;

				data++;
				dataLen--;

				if (dataLen == 0) {
					break;
				}
			}

			dev_write32(addr, val);
			addr += 4;
		}
	}

	//
	// This one handles outgoing reqs
	//
	void read_data_phase()
	{
		unsigned int rsp_desc_idx = 0;

		while (true) {
			Transaction *rt = rdDataFifo.read();
			uint32_t desc_addr;
			uint32_t rresp;

			desc_addr = RD_RESP_DESC_N_BASE_ADDR +
					rsp_desc_idx * RD_RESP_DESC_SZ;

			// Set AXI response
			switch (rt->GetTLMResponse()) {
			case tlm::TLM_ADDRESS_ERROR_RESPONSE:
				rresp = AXI_DECERR;
				break;
			case tlm::TLM_GENERIC_ERROR_RESPONSE:
				rresp = AXI_SLVERR;
				break;
			default:
			case tlm::TLM_OK_RESPONSE:
				if (rt->IsExclusive() && rt->ExclusiveHandled()) {
					rresp = AXI_EXOKAY;
				} else {
					rresp = AXI_OKAY;
				}
				break;
			}

			//
			// If ACE_MODE == ACE_MODE_ACE an ongoing snoop channel
			// transactions to the same cache line is not allowed
			// at the same time
			//
			if (ACE_MODE == ACE_MODE_ACE) {
				if (m_snp_chnls->wait_for_snoop_channel(
						rt->GetAddress(),
						rt->GetDataLen()) == false) {

					delete rt;
					wait_for_reset_release();
					continue;
				}
				m_snp_chnls->lock_rresp.lock(rt->GetAddress(),
							rt->GetDataLen());

				rresp |= rt->PassDirty() << 2;
				rresp |= rt->IsShared() << 3;
			}

			//
			// Setup rd desc
			//

			//
			// Push rrresp, rid
			//
			dev_write32(desc_addr + RD_RESP_DESC_N_RESP_REG_ADDR, rresp);
			dev_write32(desc_addr + RD_RESP_DESC_N_XID_0_REG_ADDR,
					rt->GetTransactionID());

			//
			// push data into ram and setup data offset
			//
			push_rd_data(rt);
			dev_write32(desc_addr + RD_RESP_DESC_N_DATA_OFFSET_REG_ADDR, 0);
			dev_write32(desc_addr + RD_RESP_DESC_N_DATA_SIZE_REG_ADDR,
					rt->GetDataLen());

			//
			// push desc idx
			//
			dev_write32(RD_RESP_FIFO_PUSH_DESC_REG_ADDR,
					gen_valid_bit(1) | rsp_desc_idx);

			//
			// To next rsp_desc_idx
			//
			rsp_desc_idx = (rsp_desc_idx + 1) % MAX_DESC_IDX;

			if (ACE_MODE == ACE_MODE_ACE) {
				wait(m_rackEvent);

				m_snp_chnls->lock_rresp.unlock();

				if (rt->IsBarrier()) {
					m_numReadBarriers--;
				}
				m_snp_chnls->GetOverlapList().remove(rt->GetTLMGenericPayload());
			}

			delete rt;

			if (reset_asserted()) {
				wait_for_reset_release();
				//
				// m_numReadTransactions will be set to zero in
				// the reset thread
				//
			} else {
				m_numReadTransactions--;
			}
		}
	}

	//
	// Response phase for outgoing write responses
	//
	void write_resp_phase()
	{
		unsigned int desc_idx = 0;

		while (true) {
			Transaction *wt = wrRespFifo.read();
			uint32_t desc_addr;
			uint32_t bresp;

			desc_addr = WR_RESP_DESC_N_BASE_ADDR +
					desc_idx * WR_RESP_DESC_SZ;

			// Set AXI response
			switch (wt->GetTLMResponse()) {
			case tlm::TLM_ADDRESS_ERROR_RESPONSE:
				bresp = AXI_DECERR;
				break;
			case tlm::TLM_GENERIC_ERROR_RESPONSE:
				bresp = AXI_SLVERR;
				break;
			default:
			case tlm::TLM_OK_RESPONSE:
				if (wt->IsExclusive() && wt->ExclusiveHandled()) {
					bresp = AXI_EXOKAY;
				} else {
					bresp = AXI_OKAY;
				}
				break;
			}

			dev_write32(desc_addr + WR_RESP_DESC_N_RESP_REG_ADDR, bresp);
			dev_write32(desc_addr + WR_RESP_DESC_N_XID_0_REG_ADDR,
					wt->GetTransactionID());

			//
			// push desc idx
			//
			dev_write32(WR_RESP_FIFO_PUSH_DESC_REG_ADDR,
					gen_valid_bit(1) | desc_idx);

			//
			// To next desc_idx
			//
			desc_idx = (desc_idx + 1) % MAX_DESC_IDX;

			if (ACE_MODE == ACE_MODE_ACE) {
				wait(m_wackEvent);

				if (wt->WaitForSnoop()) {
					m_snp_chnls->lock_bresp.unlock();
				}
				if (wt->IsBarrier()) {
					m_numWriteBarriers--;
				}
				m_snp_chnls->GetOverlapList().remove(wt->GetTLMGenericPayload());
			}

			delete wt;

			if (reset_asserted()) {
				//
				// m_numWriteTransactions is set to zero in the
				// reset thread
				//
				wait_for_reset_release();
			} else {

				m_numWriteTransactions--;
			}
		}
	}

	Transaction *pop_ar_ch_fifo()
	{
		uint32_t idx = dev_read32(RD_REQ_FIFO_POP_DESC_REG_ADDR);
		uint32_t desc_addr;
		uint64_t araddr;
		uint32_t dataLen;
		uint64_t arsize;
		uint32_t arid;
		Transaction *rt;
		uint32_t r;

		//
		// Assert valid bit is set
		//
		assert(valid_bit(idx));

		idx = descr_idx(idx);

		desc_addr = RD_REQ_DESC_N_BASE_ADDR + idx * RD_REQ_DESC_SZ;

		//
		// Get araddr
		//
		araddr = dev_read32(desc_addr +
					RD_REQ_DESC_N_AXADDR_1_REG_ADDR);
		araddr <<= 32;
		r = dev_read32(desc_addr + RD_REQ_DESC_N_AXADDR_0_REG_ADDR);
		araddr |= r;

		dataLen = dev_read32(desc_addr +
					RD_REQ_DESC_N_SIZE_REG_ADDR);

		arsize = dev_read32(desc_addr +
					RD_REQ_DESC_N_AXSIZE_REG_ADDR);
		arid = dev_read32(desc_addr + RD_REQ_DESC_N_AXID_0_REG_ADDR);

		r = dev_read32(desc_addr + RD_REQ_DESC_N_ATTR_REG_ADDR);

		// Sample read address and control lines
		rt = new Transaction(tlm::TLM_READ_COMMAND,
					araddr,
					dataLen,
					arsize,
					arburst(r),
					arid,
					arprot(r),
					arlock(r),
					arcache(r),
					arqos(r),
					arregion(r));
		if (rt == NULL) {
			SC_REPORT_ERROR("ace2tlm_hw_bridge",
					"transaction alloc error");
		}

		if (ACE_MODE) {
			rt->SetAxSnoop(arsnoop(r));
			rt->SetAxDomain(ardomain(r));
			rt->SetAxBar(arbar(r));

			//
			// Setup commands with no transfers
			//
			rt->SetupSingleRdDataTransfers();

			if (rt->HasSingleRdDataTransfer()) {
				//
				// Just transmit the final beat
				// (rlast need to be set, see
				// section 3.2.1 [1])
				//
				rt->SetDataLen(16);
			}

			//
			// ACE has a limit of 256 outstanding
			// barriers (section C8.4.1 [1])
			//
			if (ACE_MODE == ACE_MODE_ACE &&
				rt->IsBarrier()) {
				m_numReadBarriers++;
			}
		}

		dev_write32(RD_REQ_FREE_DESC_REG_ADDR, 1 << idx);

		return rt;
	}

	void read_address_phase()
	{
		Transaction *rt = pop_ar_ch_fifo();
		bool procesingTransId;

		procesingTransId = InList(rtList, rt->GetTransactionID());

		rtList.push_back(rt);

		//
		// Start a thread handling this transaction ID if needed
		//
		if (!procesingTransId) {
			sc_spawn(sc_bind(&ace2tlm_hw_bridge::RunTLMTransaction,
					this,
					&rtList,
					rt->GetTransactionID(),
					&rdDataFifo));
		}

		m_numReadTransactions++;
	}

	Transaction *pop_aw_ch_fifo()
	{
		uint32_t idx = dev_read32(WR_REQ_FIFO_POP_DESC_REG_ADDR);
		uint32_t desc_addr;
		uint64_t awaddr;
		uint32_t dataLen;
		uint64_t awsize;
		uint32_t awid;
		Transaction *wt;
		uint32_t r;

		//
		// Assert valid bit is set
		//
		assert(valid_bit(idx));

		idx = descr_idx(idx);

		desc_addr = WR_REQ_DESC_N_BASE_ADDR + idx * WR_REQ_DESC_SZ;

		//
		// Get araddr
		//
		awaddr = dev_read32(desc_addr +
					WR_REQ_DESC_N_AXADDR_1_REG_ADDR);
		awaddr <<= 32;
		r = dev_read32(desc_addr + WR_REQ_DESC_N_AXADDR_0_REG_ADDR);
		awaddr |= r;

		dataLen = dev_read32(desc_addr +
					WR_REQ_DESC_N_SIZE_REG_ADDR);

		awsize = dev_read32(desc_addr +
					WR_REQ_DESC_N_AXSIZE_REG_ADDR);

		awid = dev_read32(desc_addr + WR_REQ_DESC_N_AXID_0_REG_ADDR);

		r = dev_read32(desc_addr + WR_REQ_DESC_N_ATTR_REG_ADDR);

		// Sample read address and control lines
		wt = new Transaction(tlm::TLM_WRITE_COMMAND,
					awaddr,
					dataLen,
					awsize,
					awburst(r),
					awid,
					awprot(r),
					awlock(r),
					awcache(r),
					awqos(r),
					awregion(r),
					true);
		if (wt == NULL) {
			SC_REPORT_ERROR("ace2tlm_hw_bridge",
					"transaction alloc error");
		}

		if (ACE_MODE) {
			wt->SetAxSnoop(awsnoop(r));
			wt->SetAxDomain(awdomain(r));
			wt->SetAxBar(awbar(r));

			wt->SetupNoWrDataTransfers();

			//
			// ACE has a limit of 256 outstanding
			// barriers (section C8.4.1 [1])
			//
			if (ACE_MODE == ACE_MODE_ACE &&
				wt->IsBarrier()) {
				m_numWriteBarriers++;
			}
		}

		//
		// Pop data before freeing desc
		//
		pop_wdata_wstrb(wt, desc_addr);

		dev_write32(WR_REQ_FREE_DESC_REG_ADDR, 1 << idx);

		return wt;
	}

	void pop_wdata_wstrb(Transaction *wt, uint32_t aw_desc_addr)
	{
		uint8_t *data = wt->GetData();
		uint8_t *be = wt->GetByteEnable();
		unsigned int dataLen = wt->GetDataLen();
		unsigned int data_idx = 0;
		uint32_t aligned_offset;
		uint32_t wdata_ram_addr;
		uint32_t wstrb_ram_addr;
		uint32_t offset;
		uint32_t wdata;
		uint32_t wstrb;

		offset = dev_read32(aw_desc_addr +
				WR_REQ_DESC_N_DATA_OFFSET_REG_ADDR);

		aligned_offset = wt->Align(offset, 4);

		//
		// In case the offset is unaligned read first bytes for
		// aligning the address of following reads
		//
		if (aligned_offset != offset) {
			unsigned int skip = offset - aligned_offset;

			wdata = dev_read32(WR_DATA_RAM + aligned_offset);
			wstrb = dev_read32(WSTRB_DATA_RAM + aligned_offset);

			for (; skip < 4; skip++) {
				unsigned shift = skip * 8;

				//
				// Place byte and byte enable
				//
				be[data_idx] = (wstrb >> shift) & 0xFF;
				data[data_idx++] = (wdata >> shift) & 0xFF;

				if (data_idx >= dataLen) {
					// Done
					break;
				}
			}

			offset = aligned_offset + 4;
		}

		wdata_ram_addr = WR_DATA_RAM + offset;
		wstrb_ram_addr = WSTRB_DATA_RAM + offset;

		for (; data_idx < dataLen;) {
			wdata = dev_read32(wdata_ram_addr);
			wstrb = dev_read32(wstrb_ram_addr);

			for (unsigned int i = 0; i < 4; i++) {
				unsigned shift = i * 8;

				//
				// Place byte and byte enable
				//
				be[data_idx] = (wstrb >> shift) & 0xFF;

				data[data_idx++] = (wdata >> shift) & 0xFF;

				if (data_idx >= dataLen) {
					// Done
					break;
				}
			}

			wdata_ram_addr += 4;
			wstrb_ram_addr += 4;
		}
	}

	void write_address_data_phase()
	{
		Transaction *wt = pop_aw_ch_fifo();
		bool procesingTransId;

		//
		// Start a thread handling this transaction ID if needed
		//
		procesingTransId = InList(wtList, wt->GetTransactionID());

		wtList.push_back(wt);

		if (!procesingTransId) {
			sc_spawn(sc_bind(&ace2tlm_hw_bridge::RunTLMTransaction,
					this,
					&wtList,
					wt->GetTransactionID(),
					&wrRespFifo));
		}

		m_numWriteTransactions++;
	}

	bool has_work()
	{
		uint32_t fill_level;
		uint32_t r;

		fill_level = dev_read32(RD_REQ_FIFO_FILL_LEVEL_REG_ADDR);
		if (fill_level) {
			return true;
		}

		fill_level = dev_read32(WR_REQ_FIFO_FILL_LEVEL_REG_ADDR);
		if (fill_level) {
			return true;
		}

		r = dev_read32(RD_RESP_INTR_COMP_STATUS_REG_ADDR);
		if (r) {
			return true;
		}

		r = dev_read32(WR_RESP_INTR_COMP_STATUS_REG_ADDR);
		if (r) {
			return true;
		}


		fill_level = dev_read32(SN_RESP_FIFO_FILL_LEVEL_REG_ADDR);
		if (fill_level) {
			return true;
		}

		fill_level = dev_read32(SN_DATA_FIFO_FILL_LEVEL_REG_ADDR);
		if (fill_level) {
			return true;
		}

		return false;
	}

	void work_thread()
	{
		if (!probed)
			wait(probed_event);

		while (true) {
			uint32_t fill_level;
			uint32_t r;

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
			// Process AR channel (R channel is transmit and not
			// handled here)
			//
			fill_level = dev_read32(RD_REQ_FIFO_FILL_LEVEL_REG_ADDR);
			while (fill_level--) {
				read_address_phase();
			}

			//
			// Process AW / W channels (W is handled by HW and B
			// channel is transmit and not handled here)
			//
			fill_level = dev_read32(WR_REQ_FIFO_FILL_LEVEL_REG_ADDR);
			while (fill_level--) {
				write_address_data_phase();
			}


			//
			// Notify rack
			//
			r = dev_read32(RD_RESP_INTR_COMP_STATUS_REG_ADDR);
			if (r) {
				m_rackEvent.notify();
				dev_write32(RD_RESP_INTR_COMP_CLEAR_REG_ADDR, r);
			}

			//
			// Notify wack
			//
			r = dev_read32(WR_RESP_INTR_COMP_STATUS_REG_ADDR);
			if (r) {
				m_wackEvent.notify();
				dev_write32(WR_RESP_INTR_COMP_CLEAR_REG_ADDR, r);
			}


			//
			// Process CR + CD channels (ACE channel is transmit
			// and not handled here)
			//
			fill_level = dev_read32(SN_RESP_FIFO_FILL_LEVEL_REG_ADDR);
			while (fill_level--) {
				m_snp_chnls->pop_cr();
			}

			//
			// For making sure to have received cr before handling
			// cd, the cd fifo is handled in two steps. First for
			// clearing the irq pop out the cd descriptor and
			// then check if CR has been recevied.
			//
			fill_level = dev_read32(SN_DATA_FIFO_FILL_LEVEL_REG_ADDR);
			while (fill_level--) {
				m_snp_chnls->pop_cd_descriptor();
			}

			//
			// Now handle cd if cr has been received
			//
			while (m_snp_chnls->handle_cd()) {
				m_snp_chnls->pop_cd();
			}

			wait(SC_ZERO_TIME);
		}
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
		printf("version=0x%x\n", r);
		version_major = (r >> 8) & 0xff;
		version_minor = r & 0xff;

		bridge_type = dev_read32(BRIDGE_TYPE_REG_ADDR);
		printf("type=0x%x\n", bridge_type);
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
		//
		// Hand over descriptors to HW
		//
		dev_write32(RD_REQ_FREE_DESC_REG_ADDR, 0xFFFF);
		dev_write32(WR_REQ_FREE_DESC_REG_ADDR, 0xFFFF);

		dev_write32(RD_RESP_INTR_COMP_STATUS_REG_ADDR, 0xFFFF);
		dev_write32(WR_RESP_INTR_COMP_STATUS_REG_ADDR, 0xFFFF);

		dev_write32(SN_RESP_FREE_DESC_REG_ADDR, 0xFFFF);
		dev_write32(SN_DATA_FREE_DESC_REG_ADDR, 0xFFFF);

		//
		// Enable fifo irq
		//
		dev_write32(ACE_SLV_INTR_FIFO_ENABLE_REG_ADDR, 0xF);
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

	bool probed;
	sc_event probed_event;

	unsigned int version_major;
	unsigned int version_minor;
	unsigned int bridge_type;
	uint64_t m_base_addr;

	friend class RTL::AMBA::ACE::ACESnoopChannels_S<
		ace2tlm_hw_bridge, DATA_WIDTH, CACHELINE_SZ>;

	typedef RTL::AMBA::ACE::ACESnoopChannels_S<
					ace2tlm_hw_bridge,
					DATA_WIDTH,
					CACHELINE_SZ> ACESnoopChannels_S__;

	ACESnoopChannels_S__ *m_snp_chnls;

	sc_fifo<Transaction*> rdDataFifo;
	sc_fifo<Transaction*> wrRespFifo;

	sc_event		m_awEvent;
	std::list<Transaction*> wrDataList;

	sc_event		m_rackEvent;
	sc_event		m_wackEvent;

	unsigned int m_maxReadTransactions;
	unsigned int m_maxWriteTransactions;
	unsigned int m_numReadTransactions;
	unsigned int m_numWriteTransactions;

	// ACE specific
	unsigned int m_numReadBarriers;
	unsigned int m_numWriteBarriers;

	unsigned int m_maxBurstLength;

	// Used for checking overlapping addresses
	std::list<Transaction*> rtList;
	std::list<Transaction*> wtList;

	static const uint32_t DATA_BUS_BYTES = DATA_WIDTH/8;

	bool m_irq_mode_en;
public:

	//
	// Towards ACE interconnect
	//
	tlm_utils::simple_initiator_socket<ace2tlm_hw_bridge> socket;
	tlm_utils::simple_target_socket
			<ACESnoopChannels_S__>& snoop_target_socket;

	//
	// Towards rtl, AXI4Lite init_socket
	//
	tlm_utils::simple_initiator_socket
			<ace2tlm_hw_bridge> bridge_socket;


	sc_in<bool> clk;
	sc_in<bool> resetn;
	sc_in<bool> irq;

	SC_HAS_PROCESS(ace2tlm_hw_bridge);

	ace2tlm_hw_bridge(sc_core::sc_module_name name,
				uint32_t base_addr = 0) :

		sc_module(name),

		probed(false),
		probed_event("probed_event"),

		version_major(0),
		version_minor(0),
		bridge_type(0),
		m_base_addr(base_addr),

		m_snp_chnls(new ACESnoopChannels_S__(
					"ace_snp_chnls", this, clk, resetn)),

		m_maxReadTransactions(16),
		m_maxWriteTransactions(16),
		m_numReadTransactions(0),
		m_numWriteTransactions(0),
		m_numReadBarriers(0),
		m_numWriteBarriers(0),
		m_maxBurstLength(AXI4_MAX_BURSTLENGTH),

		m_irq_mode_en(false),

		socket("init_socket"),
		snoop_target_socket(m_snp_chnls->snoop_target_socket),

		bridge_socket("bridge_socket"),

		clk("clk"),
		resetn("resetn"),
		irq("irq")
	{
		SC_THREAD(reset_thread);
		SC_THREAD(work_thread);

		SC_THREAD(read_data_phase);
		SC_THREAD(write_resp_phase);
	}

	void enable_irq_mode(bool en = true) { m_irq_mode_en = en; }
};

#endif
