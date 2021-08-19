/*
 * TLM to ACE HW bridge.
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

#ifndef TLM2ACE_HW_BRIDGE_H__
#define TLM2ACE_HW_BRIDGE_H__
#include "tlm-bridges/amba.h"
#include "tlm-bridges/amba-ace.h"
#include "tlm-modules/tlm-aligner.h"
#include "private/ace-mst-addr.h"
#include "private/ace-mst-snp-chnls.h"
#include "private/regfields.h"

using namespace RTL::AMBA::ACE;

#define RD_REQ_DESC_SZ 0x100
#define RD_RESP_DESC_SZ 0x100
#define WR_REQ_DESC_SZ 0x100
#define WR_RESP_DESC_SZ 0x100

template<
	int DATA_WIDTH = 128,
	int CACHELINE_SZ = 64,
	int ACE_MODE = ACE_MODE_ACE
>
class tlm2ace_hw_bridge:
	public sc_core::sc_module
{
private:
	enum { MAX_DESC_IDX = 16 };

	class Transaction :
		public ace_tx_helpers
	{
	public:
		Transaction(tlm::tlm_generic_payload& gp) :
			m_gp(gp),
			m_burstType(AXI_BURST_INCR),
			m_numBeats(0)
		{
			genattr_extension *genattr;

			m_gp.get_extension(genattr);
			if (genattr) {
				m_genattr.copy_from(*genattr);
			}

			SetupBurstType();
			SetupNumBeats();

			if (ACE_MODE) {
				setup_ace_helpers(&m_gp);
			}
		}

		void SetupBurstType()
		{
			unsigned int streaming_width = m_gp.get_streaming_width();
			unsigned int datalen = m_gp.get_data_length();

			if (streaming_width == datalen &&
				m_genattr.get_wrap()) {
				m_burstType = AXI_BURST_WRAP;
			} else if (streaming_width >= datalen) {
				m_burstType = AXI_BURST_INCR;
			} else if (streaming_width == DATA_BUS_BYTES) {
				m_burstType = AXI_BURST_FIXED;
			} else if (streaming_width < DATA_BUS_BYTES) {
				//
				// Specify this with burst_width if streaming
				// width is less than the data bus width
				//
				m_burstType = AXI_BURST_FIXED;
				if (streaming_width > 1) {
					streaming_width &= (~0x1);
				}

				m_genattr.set_burst_width(streaming_width);
			} else {
				SC_REPORT_ERROR(TLM2AXI_BRIDGE_MSG,
						"Unsupported burst type");
			}
		}

		void SetupNumBeats()
		{
			uint64_t address = m_gp.get_address();
			unsigned int dataLen = m_gp.get_data_length();
			uint32_t burst_width = GetBurstWidth();
			uint64_t alignedAddress;

			alignedAddress = (address / burst_width) * burst_width;
			dataLen += address - alignedAddress;

			m_numBeats = (dataLen + burst_width - 1) / burst_width;
		}

		uint32_t GetNumBeats() { return m_numBeats; }

		uint32_t GetBurstWidth()
		{
			uint32_t burst_width = m_genattr.get_burst_width();

			if (burst_width == 0) {
				// Default to databus width
				burst_width = DATA_BUS_BYTES;
			}
			return burst_width;
		}

		uint8_t GetBurstType() { return m_burstType; }

		tlm::tlm_generic_payload& GetGP() { return m_gp; }

		uint32_t GetAxID() { return m_genattr.get_transaction_id(); }

		uint64_t GetAddress() { return m_gp.get_address(); }
		unsigned int GetDataLen() { return m_gp.get_data_length(); }
		uint8_t *GetData() { return m_gp.get_data_ptr(); }

		void SetDataLen(uint32_t dataLen)
		{
			m_gp.set_data_length(dataLen);
		}

		uint8_t GetAxProt()
		{
			uint8_t AxProt = 0;

			if (m_genattr.get_non_secure()) {
				AxProt |= AXI_PROT_NS;
			}
			return AxProt;
		}

		uint8_t GetAxLock()
		{
			uint8_t AxLock = AXI_LOCK_NORMAL;

			if (m_genattr.get_exclusive()) {
				AxLock = AXI_LOCK_EXCLUSIVE;
			}
			return AxLock;
		}

		uint8_t GetAxCache()
		{
			uint8_t AxCache = 0;

			AxCache = m_genattr.get_bufferable() |
					(m_genattr.get_modifiable() << 1) |
					(m_genattr.get_read_allocate() << 2) |
					(m_genattr.get_write_allocate() << 3);
			return AxCache;
		}

		uint8_t GetAxQoS()
		{
			uint8_t AxQoS = 0;

			AxQoS = m_genattr.get_qos();
			return AxQoS;
		}

		uint8_t GetAxRegion()
		{
			uint8_t AxRegion = 0;

			AxRegion = m_genattr.get_region();
			return AxRegion;
		}

		sc_event& DoneEvent() { return m_done; }

		bool IsRead()
		{
			if (ACE_MODE) {
				//
				// Transactions with no data transfer but that
				// are sent out on the rd channels.
				//
				if (HasSingleRdDataTransfer()) {
					return true;
				}
			}
			return m_gp.is_read();
		}

		bool IsWrite()
		{
			if (ACE_MODE) {
				if (IsEvict() || IsWriteBarrier()) {
					return true;
				}
			}
			return m_gp.is_write();
		}

		uint64_t Align(uint64_t addr, uint64_t alignTo)
		{
			return (addr / alignTo) * alignTo;
		}

	private:
		tlm::tlm_generic_payload& m_gp;
		genattr_extension m_genattr;
		sc_event m_done;
		uint8_t m_burstType;
		uint32_t m_numBeats;
	};

	bool ValidateBurstWidth(uint32_t burst_width)
	{
		static const unsigned int widths[] = {
			1, 2, 4, 8, 16, 32, 64, 128
		};
		unsigned int i;

		for (i = 0; i < sizeof widths / sizeof widths[0]; i++) {
			if (widths[i] == burst_width) {
				return true;
			}
		}
		return false;
	}

	bool Validate(Transaction& tr)
	{
		tlm::tlm_generic_payload& trans = tr.GetGP();

		if (trans.get_data_length() == 0) {
			SC_REPORT_INFO(TLM2AXI_BRIDGE_MSG,
					"Zero-length transaction");
			return false;
		}

		if (trans.get_streaming_width() == 0) {
			SC_REPORT_INFO(TLM2AXI_BRIDGE_MSG,
					"Zero-length streaming-width");
			return false;
		}

		if (!ValidateBurstWidth(tr.GetBurstWidth())) {
			return false;
		}

		if (tr.GetNumBeats() > m_maxBurstLength) {
			return false;
		}

		if (!tr.IsRead() && !tr.IsWrite()) {
			return false;
		}

		return true;
	}

	bool read_address_phase(Transaction *rt)
	{
		static unsigned int ar_desc_idx = 0;

		int axsize = map_size_to_axsize_assert(rt->GetBurstWidth());
		uint32_t desc_addr;
		uint64_t araddr;
		uint32_t txn_size;
		uint32_t attr;

		desc_addr = RD_REQ_DESC_N_BASE_ADDR +
				ar_desc_idx * RD_REQ_DESC_SZ;

		//
		// Setup ar channel signals descriptor
		//
		araddr = rt->GetAddress();

		dev_write32(desc_addr + RD_REQ_DESC_N_AXADDR_0_REG_ADDR,
				(uint32_t)(araddr & 0xFFFFFFFF));
		dev_write32(desc_addr + RD_REQ_DESC_N_AXADDR_1_REG_ADDR,
				(uint32_t)((araddr>>32) & 0xFFFFFFFF));


		//
		// Barrier transactions must have axlen == 0
		// (Section 3.1.5 [1]). Also DVM transactions (Section
		// C12.6 [1]).
		if (rt->GetAxBar() || rt->IsDVM()) {
			txn_size = 16;
			rt->SetDataLen(0);
		} else {
			txn_size = rt->GetDataLen();
		}
		dev_write32(desc_addr + RD_REQ_DESC_N_SIZE_REG_ADDR,
				txn_size);

		dev_write32(desc_addr + RD_REQ_DESC_N_AXSIZE_REG_ADDR,
				axsize);

		//
		// Attributes
		//
		attr =  gen_arburst(rt->GetBurstType()) |
			gen_arlock(rt->GetAxLock()) |
			gen_arcache(rt->GetAxCache()) |
			gen_arprot(rt->GetAxProt()) |
			gen_arqos(rt->GetAxQoS()) |
			gen_arregion(rt->GetAxRegion()) |
			gen_arbar(rt->GetAxBar()) |
			gen_ardomain(rt->GetAxDomain()) |
			gen_arsnoop(rt->GetAxSnoop());

		dev_write32(desc_addr + RD_REQ_DESC_N_ATTR_REG_ADDR,
				attr);

		// arid
		dev_write32(desc_addr + RD_REQ_DESC_N_AXID_0_REG_ADDR,
					rt->GetAxID());

		if (ACE_MODE) {
			//
			// Barrier transactions must have axlen == 0
			// (Section 3.1.5 [1]). Also DVM transactions (Section
			// C12.6 [1]).
			//
			if (ACE_MODE == ACE_MODE_ACE) {
				//
				// Wait until the DVM Sync response has been
				// sent before transmitting DVMComplete
				//
				if (rt->IsDVMComplete() &&
					m_snp_chnls->GetNumDVMSyncResp() == 0) {

					wait(m_snp_chnls->DVMSyncRespEvent() |
						resetn.negedge_event());
				}
				m_snp_chnls->DecNumDVMSyncResp();
			}
		}

		//
		// push descriptor for transmission
		//
		dev_write32(RD_REQ_FIFO_PUSH_DESC_REG_ADDR,
				gen_valid_bit(1) | ar_desc_idx);

		//
		// To next ar_desc_idx
		//
		ar_desc_idx = (ar_desc_idx + 1) % MAX_DESC_IDX;

		return true;
	}

	bool write_address_phase(Transaction *wt)
	{
		static unsigned int aw_desc_idx = 0;

		int axsize = map_size_to_axsize_assert(wt->GetBurstWidth());
		uint32_t desc_addr;
		uint64_t awaddr;
		uint32_t txn_size;
		uint32_t attr;

		desc_addr = WR_REQ_DESC_N_BASE_ADDR +
				aw_desc_idx * WR_REQ_DESC_SZ;

		//
		// Setup aw channel signals descriptor
		//
		awaddr = wt->GetAddress();

		dev_write32(desc_addr + WR_REQ_DESC_N_AXADDR_0_REG_ADDR,
				(uint32_t)(awaddr & 0xFFFFFFFF));
		dev_write32(desc_addr + WR_REQ_DESC_N_AXADDR_1_REG_ADDR,
				(uint32_t)((awaddr>>32) & 0xFFFFFFFF));


		//
		// Barrier transactions must have axlen == 0
		// (Section 3.1.5 [1]). Also Evict.
		//
		if (wt->GetAxBar()) {
			txn_size = 0;
		} else {
			txn_size = wt->GetDataLen();

			//
			// Let wstrb handle the situation below by disabling
			// the last bytes
			//
			if (txn_size < DATA_BUS_BYTES) {
				txn_size = DATA_BUS_BYTES;
			}
		}
		dev_write32(desc_addr + WR_REQ_DESC_N_SIZE_REG_ADDR,
				txn_size);

		dev_write32(desc_addr + WR_REQ_DESC_N_AXSIZE_REG_ADDR,
				axsize);

		//
		// Attributes
		//
		attr =  gen_awburst(wt->GetBurstType()) |
			gen_awlock(wt->GetAxLock()) |
			gen_awcache(wt->GetAxCache()) |
			gen_awprot(wt->GetAxProt()) |
			gen_awqos(wt->GetAxQoS()) |
			gen_awregion(wt->GetAxRegion()) |
			gen_awbar(wt->GetAxBar()) |
			gen_awdomain(wt->GetAxDomain()) |
			gen_awsnoop(wt->GetAxSnoop());

		dev_write32(desc_addr + WR_REQ_DESC_N_ATTR_REG_ADDR,
				attr);

		// awid
		dev_write32(desc_addr + WR_REQ_DESC_N_AXID_0_REG_ADDR,
					wt->GetAxID());

		//
		// Setup data
		//
		push_wdata_wstrb(wt, desc_addr);

		//
		// push descriptor for transmission
		//
		dev_write32(WR_REQ_FIFO_PUSH_DESC_REG_ADDR,
				gen_valid_bit(1) | aw_desc_idx);

		//
		// To next aw_desc_idx
		//
		aw_desc_idx = (aw_desc_idx + 1) % MAX_DESC_IDX;

		return true;
	}

	void push_wdata_wstrb(Transaction *wt, uint32_t desc_addr)
	{
		uint8_t *data = wt->GetData();
		unsigned int dataLen = wt->GetDataLen();
		uint32_t wdata_ram_addr = WR_DATA_RAM;
		uint32_t wstrb_ram_addr = WSTRB_DATA_RAM;

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

			dev_write32(wdata_ram_addr, val);
			wdata_ram_addr += 4;
		}

		if (wt->GetGP().get_byte_enable_length()) {
			uint8_t *be = wt->GetGP().get_byte_enable_ptr();
			unsigned int be_len = wt->GetGP().
						get_byte_enable_length();
			unsigned int pos = 0;
			unsigned int num_written = 0;

			dev_write32(desc_addr + WR_REQ_DESC_N_TXN_TYPE_REG_ADDR,
							1 << 1);

			dataLen = wt->GetDataLen();

			while (dataLen) {
				uint32_t val = 0;

				//
				// Move over 4 bytes (or the ones that are left)
				//
				for (int i = 0; i < 4; i++) {
					unsigned int shift = i * 8;;
					uint8_t b = be[pos++ % be_len];

					val |= b << shift;

					dataLen--;

					if (dataLen == 0) {
						break;
					}
				}

				dev_write32(wstrb_ram_addr, val);
				wstrb_ram_addr += 4;
				num_written += 4;
			}

			while (num_written < DATA_BUS_BYTES) {
				dev_write32(wstrb_ram_addr, 0);
				wstrb_ram_addr += 4;
				num_written += 4;
			}

		} else if (wt->GetDataLen() < DATA_BUS_BYTES) {
			unsigned int pos = DATA_BUS_BYTES;

			dev_write32(desc_addr + WR_REQ_DESC_N_TXN_TYPE_REG_ADDR,
						1 << 1);

			dataLen = wt->GetDataLen();

			while (pos) {
				uint32_t val = 0;

				//
				// Enable bytes until all bytes supposed to be
				// written have been enabled and disable the
				// last bytes on the bus if needed
				//
				for (int i = 0; i < 4; i++) {
					unsigned int shift = i * 8;;
					uint8_t b = 0xFF; // Enable

					if (!dataLen) {
						b = 0; // Disable byte
					}

					val |= b << shift;

					if (dataLen > 0) {
						dataLen--;
					}
					pos--;
				}

				dev_write32(wstrb_ram_addr, val);
				wstrb_ram_addr += 4;
			}

		} else {
			dev_write32(desc_addr + WR_REQ_DESC_N_TXN_TYPE_REG_ADDR,
						0);
		}
	}

	void address_phase(sc_fifo<Transaction*> &transFifo)
	{
		while (true) {
			Transaction *tr = transFifo.read();

			/* Send the address and pass on the transaction to the
			 * next pipeline step if reset was not asserted.
			 */
			if (tr->IsRead()) {
				if (read_address_phase(tr)) {
					rdResponses.push_back(tr);
				}

			} else {
				if (write_address_phase(tr)) {
					wrResponses.push_back(tr);
					tr = NULL;
				}
			}

			/* Abort transaction if reset is asserted. */
			if (reset_asserted()) {
				if (tr) {
					abort(tr);
				}
				wait_for_reset_release();
			}
		}
	}

	void read_address_phase() {
		address_phase(rdTransFifo);
	}

	void write_address_phase() {
		address_phase(wrTransFifo);
	}

	bool reset_asserted() { return resetn.read() == false; }

	void wait_for_reset_release()
	{
		do {
			sc_core::wait(clk.posedge_event());
		} while (resetn.read() == false);
	}

	// Aligner proxy
	virtual void b_transport_proxy(tlm::tlm_generic_payload& trans,
					sc_time& delay) {
		return proxy_init_socket[0]->b_transport(trans, delay);
	}

	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		Transaction tr(trans);

		// Since we're going todo waits in order to wiggle the
		// AXI signals, we need to eliminate the accumulated
		// TLM delay.
		wait(delay, resetn.negedge_event());
		delay = SC_ZERO_TIME;

		// Abort if reset got asserted.
		if (resetn.read() && Validate(tr)) {
			// Hand it over to the signal wiggling machinery.
			if (tr.IsRead()) {
				rdTransFifo.write(&tr);
			} else {
				wrTransFifo.write(&tr);
			}
			// Wait until the transaction is done.
			wait(tr.DoneEvent());
		} else {
			trans.set_response_status(
				tlm::TLM_GENERIC_ERROR_RESPONSE);
		}
	}

	// Lookup a transaction in a vector. If found, return
	// the pointer and remove it.
	Transaction *LookupAxID(std::vector<Transaction*> &vec,
					      uint32_t id)
	{
		Transaction *tr = NULL;
		unsigned int i;

		// Find _FIRST_ bid in vector
		for (i = 0; i < vec.size(); i++) {
			if (vec[i]->GetAxID() == id) {
				break;
			}
		}

		// If found, remove and return it.
		if (i < vec.size()) {
			tr = vec[i];
			vec.erase(vec.begin() + i);
		}
		return tr;
	}

	template<typename T>
	void abort(T *tr)
	{
		tlm::tlm_generic_payload& trans = tr->GetGP();

		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		tr->DoneEvent().notify();
	}

	void read_resp_phase()
	{
		uint32_t idx = dev_read32(RD_RESP_FIFO_POP_DESC_REG_ADDR);
		Transaction *tr = NULL;
		uint32_t desc_addr;
		uint64_t resp;
		uint32_t rid;

		assert(valid_bit(idx));

		idx = descr_idx(idx);

		desc_addr = RD_RESP_DESC_N_BASE_ADDR + idx * RD_RESP_DESC_SZ;

		rid = dev_read32(desc_addr + RD_RESP_DESC_N_XID_0_REG_ADDR);

		tr = LookupAxID(rdResponses, rid);

		if (!tr) {
			SC_REPORT_ERROR(TLM2AXI_BRIDGE_MSG,
				"Received a read response with an unexpected "
				"transaction ID");
		}


		//
		// ACE Clean and Make transactions have
		// a single data transfer and data must
		// be ignored.
		//
		// Section C3.2.1 [1]
		//
		if (!tr->HasSingleRdDataTransfer()) {
			//
			// Get data
			//
			pop_rdata(tr, desc_addr);
		}

		//
		// Read resp
		//
		resp = dev_read32(desc_addr + RD_RESP_DESC_N_RESP_REG_ADDR);

		//
		// Descriptor has been read so now we can free it
		//
		dev_write32(RD_RESP_FREE_DESC_REG_ADDR, 1 << idx);

		//
		// Translate the response and notify if not in reset.
		//
		if (resetn.read() == true) {

			tlm_gp_set_axi_resp(tr->GetGP(), resp & 3);

			if (ACE_MODE == ACE_MODE_ACE) {
				if (m_snp_chnls->ExtractIsShared(resp)) {
					tr->SetShared();
				}
				if (m_snp_chnls->ExtractPassDirty(resp)) {
					tr->SetDirty();
				}

				// Reset asserted while rack is being signaled
				if (reset_asserted()) {
					abort(tr);
					wait_for_reset_release();
					return;
				}
			}

			tr->DoneEvent().notify();
		} else {
			//
			// Reset is asserted, abort the transaction.
			//
			if (tr) {
				abort(tr);
			}
			wait_for_reset_release();
		}
	}

	void pop_rdata(Transaction *rt, uint32_t r_desc_addr)
	{
		uint8_t *data = rt->GetData();
		unsigned int dataLen = rt->GetDataLen();
		unsigned int data_idx = 0;
		uint32_t aligned_offset;
		uint32_t rd_data_ram_addr;
		uint32_t offset;
		uint32_t rdata;

		offset = dev_read32(r_desc_addr +
				RD_RESP_DESC_N_DATA_OFFSET_REG_ADDR);

		aligned_offset = rt->Align(offset, 4);

		//
		// In case the offset is unaligned read first bytes for
		// aligning the address of following reads
		//
		if (aligned_offset != offset) {
			unsigned int skip = offset - aligned_offset;

			rdata = dev_read32(RD_DATA_RAM + aligned_offset);

			for (; skip < 4; skip++) {
				unsigned shift = skip * 8;

				//
				// Place byte and byte enable
				//
				data[data_idx++] = (rdata >> shift) & 0xFF;

				if (data_idx >= dataLen) {
					// Done
					break;
				}
			}

			offset = aligned_offset + 4;
		}

		rd_data_ram_addr = RD_DATA_RAM + offset;

		for (; data_idx < dataLen;) {
			rdata = dev_read32(rd_data_ram_addr);

			for (unsigned int i = 0; i < 4; i++) {
				unsigned shift = i * 8;

				//
				// Place byte and byte enable
				//
				data[data_idx++] = (rdata >> shift) & 0xFF;

				if (data_idx >= dataLen) {
					// Done
					break;
				}
			}

			rd_data_ram_addr += 4;
		}
	}

	void write_resp_phase()
	{
		uint32_t idx = dev_read32(WR_RESP_FIFO_POP_DESC_REG_ADDR);
		Transaction *tr;
		uint32_t desc_addr;
		uint32_t bid_u32;
		uint32_t bresp;

		assert(valid_bit(idx));

		idx = descr_idx(idx);

		desc_addr = WR_RESP_DESC_N_BASE_ADDR + idx * WR_RESP_DESC_SZ;

		bid_u32 = dev_read32(desc_addr + WR_RESP_DESC_N_XID_0_REG_ADDR);

		tr = LookupAxID(wrResponses, bid_u32);
		if (!tr) {
			SC_REPORT_ERROR("tlm2axi-bridge",
				"Received a write response "
				"with an unexpected transaction ID");
		}

		bresp = dev_read32(desc_addr + WR_RESP_DESC_N_RESP_REG_ADDR);

		//
		// Descriptor has been read so now we can free it
		//
		dev_write32(WR_RESP_FREE_DESC_REG_ADDR, 1 << idx);

		//
		// Setup TLM response
		//
		tlm_gp_set_axi_resp(tr->GetGP(), bresp);

		if (ACE_MODE == ACE_MODE_ACE) {
			if (reset_asserted()) {
				abort(tr);
				wait_for_reset_release();
				return;
			}
		}

		tr->DoneEvent().notify();
	}

	bool has_work()
	{
		uint32_t fill_level;

		fill_level = dev_read32(RD_RESP_FIFO_FILL_LEVEL_REG_ADDR);
		if (fill_level) {
			return true;
		}

		fill_level = dev_read32(WR_RESP_FIFO_FILL_LEVEL_REG_ADDR);
		if (fill_level) {
			return true;
		}

		fill_level = dev_read32(SN_REQ_FIFO_FILL_LEVEL_REG_ADDR);
		if (fill_level) {
			return true;
		}

		return false;
	}

	//
	// This one must handle incoming r responses and b responses (ar/aw/w
	// channels is handled by rtl).
	//
	void work_thread()
	{
		if (!probed)
			wait(probed_event);

		while (true) {
			uint32_t fill_level;

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
			// Process R channel (AR channel is transmit and not
			// handled here)
			//
			fill_level = dev_read32(RD_RESP_FIFO_FILL_LEVEL_REG_ADDR);
			while (fill_level--) {
				read_resp_phase();
			}

			//
			// Process B channel (AW / W channels are transmit and
			// not handled here)
			//
			fill_level = dev_read32(WR_RESP_FIFO_FILL_LEVEL_REG_ADDR);
			while (fill_level--) {
				write_resp_phase();
			}

			//
			// Process AC channel (CR / CD channels are transmit and
			// not handled here)
			//
			fill_level = dev_read32(SN_REQ_FIFO_FILL_LEVEL_REG_ADDR);
			while (fill_level--) {
				m_snp_chnls->pop_ac();
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
		dev_write32(RD_RESP_FREE_DESC_REG_ADDR, 0xFFFF);
		dev_write32(WR_RESP_FREE_DESC_REG_ADDR, 0xFFFF);

		//
		// Hand over AC channel descriptors
		//
		dev_write32(SN_REQ_FREE_DESC_REG_ADDR, 0xFFFF);

		//
		// Enable fifo irq
		//
		dev_write32(ACE_MST_INTR_FIFO_ENABLE_REG_ADDR, 0xF);
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

	friend class RTL::AMBA::ACE::ACESnoopChannels_M<
			tlm2ace_hw_bridge, DATA_WIDTH, CACHELINE_SZ>;

	typedef RTL::AMBA::ACE::ACESnoopChannels_M<
				tlm2ace_hw_bridge,
				DATA_WIDTH,
				CACHELINE_SZ> ACESnoopChannels_M__;

	ACESnoopChannels_M__ *m_snp_chnls;

	static const uint32_t DATA_BUS_BYTES = DATA_WIDTH/8;

	sc_fifo<Transaction*> rdTransFifo;
	sc_fifo<Transaction*> wrTransFifo;

	std::vector<Transaction*> rdResponses;

	sc_fifo<Transaction*> wrDataFifo;
	std::vector<Transaction*> wrResponses;

	unsigned int m_maxBurstLength;

	bool m_irq_mode_en;

	tlm_aligner *aligner;
	tlm_utils::simple_initiator_socket<tlm2ace_hw_bridge> *proxy_init_socket;
	tlm_utils::simple_target_socket<tlm2ace_hw_bridge> *proxy_target_socket;

public:
	//
	// From ACE master
	//
	tlm_utils::simple_target_socket<tlm2ace_hw_bridge> tgt_socket;
	tlm_utils::simple_initiator_socket<ACESnoopChannels_M__>& snoop_init_socket;

	//
	// Towards rtl, AXI4Lite init_socket
	//
	tlm_utils::simple_initiator_socket<tlm2ace_hw_bridge> bridge_socket;

	sc_in<bool> clk;
	sc_in<bool> resetn;
	sc_in<bool> irq;

	SC_HAS_PROCESS(tlm2ace_hw_bridge);

	tlm2ace_hw_bridge(sc_core::sc_module_name name,
			uint32_t base_addr = 0,
			bool aligner_enable=true) :
		sc_module(name),

		probed(false),
		probed_event("probed_event"),

		version_major(0),
		version_minor(0),
		bridge_type(0),
		m_base_addr(base_addr),

		m_snp_chnls(new ACESnoopChannels_M__(
					"ace_snp_chnls", this, clk, resetn)),

		m_maxBurstLength(AXI4_MAX_BURSTLENGTH),

		m_irq_mode_en(false),

		aligner(NULL),
		proxy_init_socket(NULL),
		proxy_target_socket(NULL),

		tgt_socket("target_socket"),
		snoop_init_socket(m_snp_chnls->snoop_init_socket),

		bridge_socket("bridge_socket"),

		clk("clk"),
		resetn("resetn"),
		irq("irq")
	{
		if (aligner_enable) {
			aligner = new tlm_aligner("aligner",
						  DATA_WIDTH,
						  m_maxBurstLength * DATA_WIDTH / 8, /* MAX AXI length.  */
						  4 * 1024, /* AXI never allows crossing of 4K boundary.  */
						  true); /* WRAP burst-types require natural alignment.  */

			proxy_init_socket = new tlm_utils::simple_initiator_socket<tlm2ace_hw_bridge>("proxy_init_socket");
			proxy_target_socket = new tlm_utils::simple_target_socket<tlm2ace_hw_bridge>("proxy_target_socket");

			(*proxy_init_socket)(aligner->target_socket);
			aligner->init_socket(*proxy_target_socket);

			tgt_socket.register_b_transport(this, &tlm2ace_hw_bridge::b_transport_proxy);
			proxy_target_socket->register_b_transport(this, &tlm2ace_hw_bridge::b_transport);
		} else {
			tgt_socket.register_b_transport(this, &tlm2ace_hw_bridge::b_transport);
		}


		SC_THREAD(reset_thread);
		SC_THREAD(work_thread);

		SC_THREAD(read_address_phase);
		SC_THREAD(write_address_phase);
	}

	~tlm2ace_hw_bridge() {
		delete proxy_init_socket;
		delete proxy_target_socket;
		delete aligner;
		delete m_snp_chnls;
	}

	void enable_irq_mode(bool en = true) { m_irq_mode_en = en; }
};

#endif
