/*
 * Copyright (c) 2018 Xilinx Inc.
 * Written by Edgar E. Iglesias,
 *            Francisco Iglesias.
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
 *
 * References:
 *
 * [1] AMBA AXI and ACE Protocol Specification, ARM IHI 0022D, ID102711
 *
 */

#ifndef AXI2TLM_BRIDGE_DEV_H__
#define AXI2TLM_BRIDGE_DEV_H__
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <list>

#include "tlm-bridges/amba.h"
#include "tlm-bridges/amba-ace.h"
#include "tlm-extensions/genattr.h"
#include "tlm-bridges/private/ace/snoop-channels.h"

/*
  MAX DATA_WIDTH = 1024 bits / 128 bytes
  MAX ADDR_WIDTH = 64 bits / 8 bytes
*/

using namespace AMBA::ACE;

template
<int ADDR_WIDTH,
	int DATA_WIDTH,
	int ID_WIDTH = 8,
	int AxLEN_WIDTH = 8,
	int AxLOCK_WIDTH = 1,
	int AWUSER_WIDTH = 2,
	int ARUSER_WIDTH = 2,
	int WUSER_WIDTH = 2,
	int RUSER_WIDTH = 2,
	int BUSER_WIDTH = 2,
	int ACE_MODE = ACE_MODE_OFF,
	int CD_DATA_WIDTH = DATA_WIDTH>
class axi2tlm_bridge :
	public sc_core::sc_module,
	public axi_common
{
public:
	typedef ACESnoopChannels_S<
				ADDR_WIDTH,
				CD_DATA_WIDTH> ACESnoopChannels_S__;

	tlm_utils::simple_initiator_socket<axi2tlm_bridge> socket;

	SC_HAS_PROCESS(axi2tlm_bridge);

	sc_in<bool> clk;
	sc_in<bool> resetn;

	/* Write address channel.  */
	sc_in<bool> awvalid;
	sc_out<bool> awready;
	sc_in<sc_bv<ADDR_WIDTH> > awaddr;
	sc_in<sc_bv<3> > awprot;
	sc_in<AXISignal(AWUSER_WIDTH) > awuser;	// AXI4 only
	sc_in<sc_bv<4> > awregion; 		// AXI4 only
	sc_in<sc_bv<4> > awqos;			// AXI4 only
	sc_in<sc_bv<4> > awcache;
	sc_in<sc_bv<2> > awburst;
	sc_in<sc_bv<3> > awsize;
	sc_in<AXISignal(AxLEN_WIDTH) > awlen;
	sc_in<AXISignal(ID_WIDTH) > awid;
	sc_in<AXISignal(AxLOCK_WIDTH) > awlock;

	/* Write data channel.  */
	sc_in<AXISignal(ID_WIDTH) > wid;	// AXI3 only
	sc_in<bool> wvalid;
	sc_out<bool> wready;
	sc_in<sc_bv<DATA_WIDTH> > wdata;
	sc_in<sc_bv<DATA_WIDTH/8> > wstrb;
	sc_in<AXISignal(WUSER_WIDTH) > wuser;	// AXI4 only
	sc_in<bool> wlast;

	/* Write response channel.  */
	sc_out<bool> bvalid;
	sc_in<bool> bready;
	sc_out<sc_bv<2> > bresp;
	sc_out<AXISignal(BUSER_WIDTH) > buser;	// AXI4 only
	sc_out<AXISignal(ID_WIDTH) > bid;

	/* Read address channel.  */
	sc_in<bool> arvalid;
	sc_out<bool> arready;
	sc_in<sc_bv<ADDR_WIDTH> > araddr;
	sc_in<sc_bv<3> > arprot;
	sc_in<AXISignal(ARUSER_WIDTH) > aruser;	// AXI4 only
	sc_in<sc_bv<4> > arregion;		// AXI4 only
	sc_in<sc_bv<4> > arqos;			// AXI4 only
	sc_in<sc_bv<4> > arcache;
	sc_in<sc_bv<2> > arburst;
	sc_in<sc_bv<3> > arsize;
	sc_in<AXISignal(AxLEN_WIDTH) > arlen;
	sc_in<AXISignal(ID_WIDTH) > arid;
	sc_in<AXISignal(AxLOCK_WIDTH) > arlock;

	/* Read data channel.  */
	sc_out<bool> rvalid;
	sc_in<bool> rready;
	sc_out<sc_bv<DATA_WIDTH> > rdata;
	sc_out<sc_bv<(ACE_MODE == ACE_MODE_ACE) ? 4 : 2> > rresp;
	sc_out<AXISignal(RUSER_WIDTH) > ruser;	// AXI4 only
	sc_out<AXISignal(ID_WIDTH) > rid;
	sc_out<bool> rlast;

	// AXI4 signals
	sc_in<sc_bv<3> > awsnoop;
	sc_in<sc_bv<2> > awdomain;
	sc_in<sc_bv<2> > awbar;

	sc_in<bool > wack;

	sc_in<sc_bv<4> > arsnoop;
	sc_in<sc_bv<2> > ardomain;
	sc_in<sc_bv<2> > arbar;

	sc_in<bool > rack;

	axi2tlm_bridge(sc_core::sc_module_name name,
			AXIVersion version = V_AXI4) :
		sc_module(name),
		axi_common(this),

		clk("clk"),
		resetn("resetn"),

		awvalid("awvalid"),
		awready("awready"),
		awaddr("awaddr"),
		awprot("awprot"),
		awuser("awuser"),
		awregion("awregion"),
		awqos("awqos"),
		awcache("awcache"),
		awburst("awburst"),
		awsize("awsize"),
		awlen("awlen"),
		awid("awid"),
		awlock("awlock"),

		wid("wid"),
		wvalid("wvalid"),
		wready("wready"),
		wdata("wdata"),
		wstrb("wstrb"),
		wuser("wuser"),
		wlast("wlast"),

		bvalid("bvalid"),
		bready("bready"),
		bresp("bresp"),
		buser("buser"),
		bid("bid"),

		arvalid("arvalid"),
		arready("arready"),
		araddr("araddr"),
		arprot("arprot"),
		aruser("aruser"),
		arregion("arregion"),
		arqos("arqos"),
		arcache("arcache"),
		arburst("arburst"),
		arsize("arsize"),
		arlen("arlen"),
		arid("arid"),
		arlock("arlock"),

		rvalid("rvalid"),
		rready("rready"),
		rdata("rdata"),
		rresp("rresp"),
		ruser("ruser"),
		rid("rid"),
		rlast("rlast"),

		// AXI4 ACE signals
		awsnoop("awsnoop"),
		awdomain("awdomain"),
		awbar("awbar"),
		wack("wack"),

		arsnoop("arsnoop"),
		ardomain("ardomain"),
		arbar("arbar"),
		rack("rack"),

		m_snp_chnls(NULL),

		m_maxReadTransactions(16),
		m_maxWriteTransactions(16),
		m_numReadTransactions(0),
		m_numWriteTransactions(0),
		m_numReadBarriers(0),
		m_numWriteBarriers(0),
		m_maxBurstLength(AXI4_MAX_BURSTLENGTH),
		m_version(version),
		dummy("axi_dummy")
	{
		if (ACE_MODE == ACE_MODE_ACE) {
			m_snp_chnls = new ACESnoopChannels_S__(
						"ace_snp_chnls", clk, resetn);
		}

		if (m_version == V_AXI3) {
			//
			// Change m_maxBurstLength to AXI3 values
			//
			m_maxBurstLength = AXI3_MAX_BURSTLENGTH;
		}

		SC_THREAD(read_address_phase);
		SC_THREAD(read_data_phase);

		SC_THREAD(write_address_phase);
		SC_THREAD(write_data_phase);
		SC_THREAD(write_resp_phase);

		SC_THREAD(reset);
	}

	~axi2tlm_bridge()
	{
		delete m_snp_chnls;
	}

	ACESnoopChannels_S__& GetACESnoopChannels() { return *m_snp_chnls; };
private:

	class Transaction :
		public ace_tx_helpers
	{
	public:
		Transaction(tlm::tlm_command cmd,
				uint64_t address,
				uint32_t burstLen,
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
			m_burstLen(burstLen),
			m_alignedAddress(Align(address, numberBytes)),
			m_beat(1),
			m_dataIdx(0),
			m_delay(SC_ZERO_TIME),
			m_abortScheduled(false),
			m_TLMOngoing(false)
		{
			uint32_t dataLen;
			uint8_t *data;

			if (burstType == AXI_BURST_FIXED) {
				dataLen = burstLen * DATA_BUS_BYTES;
			} else {
				dataLen = GetDataLen(address,
							m_alignedAddress,
							numberBytes,
							burstLen);
			}

			data = new uint8_t[dataLen];

			assert(numberBytes > 0);
			assert(dataLen > 0);

			if (IsNonSecure(AxProt)) {
				m_genattr->set_non_secure();
			}
			m_genattr->set_burst_width(numberBytes);
			m_genattr->set_transaction_id(transaction_id);
			m_genattr->set_exclusive(AxLock == AXI_LOCK_EXCLUSIVE);
			if (AxLOCK_WIDTH > AXI4_AxLOCK_WIDTH) {
				m_genattr->set_locked(AxLock == AXI_LOCK_LOCKED);
			}
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
				m_gp->set_streaming_width(numberBytes*burstLen);
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

		uint32_t GetDataLen(uint64_t address,
					uint64_t alignedAddress,
					uint8_t numberBytes,
					uint32_t burstLen)
		{
			return numberBytes - (address - alignedAddress)
					+ (burstLen-1) * numberBytes;
		}

		unsigned int GetDataLen()
		{
			return m_gp->get_data_length();
		}

		tlm::tlm_response_status GetTLMResponse()
		{
			return m_gp->get_response_status();
		}

		template<typename T1, typename T2>
		void FillData(T1& wdata, T2& wstrb)
		{
			unsigned char *gp_data = m_gp->get_data_ptr();
			unsigned char *be = m_gp->get_byte_enable_ptr();
			unsigned int i = 0;

			if (m_beat == 1) {
				uint64_t address = m_gp->get_address();

				//
				// Skip to lower_byte_lane if address is
				// unaligned
				//
				i = address - Align(address, DATA_BUS_BYTES);
			}

			//
			// Fill in data or mark the byte as TLM_DISABLED
			//
			for (; i < DATA_BUS_BYTES && m_dataIdx < m_gp->get_data_length(); i++) {
				if (wstrb.read().bit(i)) {
					int firstbit = i * 8;
					int lastbit = firstbit + 8 - 1;

					assert(m_dataIdx < m_gp->get_data_length());
					be[m_dataIdx] = TLM_BYTE_ENABLED;
					gp_data[m_dataIdx++] =
						wdata.read().range(lastbit, firstbit).to_uint();
				} else {
					be[m_dataIdx++] = TLM_BYTE_DISABLED;
				}
			}
		}

		template<typename T>
		void GetData(T& data)
		{
			unsigned char *gp_data = m_gp->get_data_ptr();
			uint64_t address = m_gp->get_address();
			uint8_t numberBytes = m_genattr->get_burst_width();
			uint64_t alignedAddress;
			unsigned int lower_byte_lane;
			unsigned int upper_byte_lane;
			unsigned int i;

			alignedAddress = Align(address, numberBytes);

			if (m_burstType == AXI_BURST_FIXED) {
				// Set everything
				for (i = 0; i < DATA_BUS_BYTES; i++) {
					int firstbit = i*8;
					int lastbit = firstbit + 8-1;

					data.range(lastbit, firstbit) =
						gp_data[m_dataIdx++];
				}
			} else {
				if (m_beat == 1) {
					lower_byte_lane = address -
							Align(address, DATA_BUS_BYTES);
					upper_byte_lane = alignedAddress +
							(numberBytes-1) -
							Align(address, DATA_BUS_BYTES);
				} else {
					uint64_t address = alignedAddress +
								((m_beat-1) * numberBytes);

					lower_byte_lane = address -
								Align(address, DATA_BUS_BYTES);
					upper_byte_lane = lower_byte_lane +
								(numberBytes-1);
				}

				// Set data
				for (i = 0; i < DATA_BUS_BYTES; i++) {
					if (i >= lower_byte_lane && i <= upper_byte_lane) {
						int firstbit = i*8;
						int lastbit = firstbit + 8-1;

						data.range(lastbit, firstbit) =
							gp_data[m_dataIdx++];
					}
				}
			}
		}

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

		bool IsLastBeat() { return m_beat == m_burstLen; }
		bool Done() { return m_beat > m_burstLen; }

		void IncBeat() { m_beat++; }
		uint32_t GetBeat() { return m_beat; }
		void SetBeat(uint32_t beat) { m_beat = beat; }

		uint32_t GetBurstLength() { return m_burstLen; }

		//
		// Drop byte enables if all bytes are enabled
		//
		void TryDropBE()
		{
			unsigned be_len = m_gp->get_byte_enable_length();
			unsigned char *be = m_gp->get_byte_enable_ptr();
			unsigned int i;

			// If all bytes are enabled delete byte_enable
			for (i = 0; i < be_len; i++) {
				if (be[i] != TLM_BYTE_ENABLED) {
					break;
				}
			}

			if (i == be_len) {
				// All are enabled
				m_gp->set_byte_enable_ptr(NULL);
				m_gp->set_byte_enable_length(0);

				delete[] be;
			}
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

		bool hasData()
		{
			if (ACE_MODE) {
				if (IsBarrier() || IsEvict()) {
					return false;
				}
			}
			return true;
		}

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
		uint32_t m_burstLen;
		uint64_t m_alignedAddress;
		uint32_t m_beat;
		uint32_t  m_dataIdx;
		sc_time  m_delay;

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

	bool PreviousHaveData(std::list<Transaction*>& l, uint32_t id)
	{
		//
		// For AXI3:
		//
		// For a slave that supports write data interleaving, the order in
		// which it receives the first data item of each transaction must be
		// the same as the order in which it receives the addresses for the
		// transactions.
		//

		for (typename std::list<Transaction*>::iterator it = l.begin();
			it != l.end(); it++) {

			Transaction *t = (*it);

			if (t->GetTransactionID() == id) {
				break;
			}

			if (t->GetBeat() == 1) {
				//
				// Transaction has no yet received data and was
				// received before than current wid
				//
				return false;
			}
		}

		return true;
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

	void Validate(Transaction *t)
	{
		if (t->GetBurstLength() > m_maxBurstLength) {
			SC_REPORT_ERROR("axi2tlm-bridge",
				"AXI transaction burst length exceeds maximum");
		}
	}

	unsigned int get_num_ongoing_read()
	{
		return m_numReadTransactions - m_numReadBarriers;
	}

	bool assert_arready()
	{
		bool arready_val = true;

		if (get_num_ongoing_read() >= m_maxReadTransactions) {
			arready_val = false;
		}

		if (ACE_MODE == ACE_MODE_ACE &&
			m_numReadBarriers >= ACE::MaxBarriers) {
			arready_val = false;
		}

		return arready_val;
	}

	void read_address_phase()
	{
		while (true) {
			arready.write(assert_arready());

			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				wait_for_reset_release();
				continue;
			}

			if (arvalid.read() && arready.read()) {
				bool procesingTransId;

				// Sample read address and control lines
				Transaction *rt =
					new Transaction(tlm::TLM_READ_COMMAND,
							araddr.read().to_uint64(),
							to_uint(arlen) + 1,
							1 << arsize.read().to_uint(),
							arburst.read().to_uint(),
							to_uint(arid),
							to_uint(arprot),
							to_uint(arlock),
							arcache.read().to_uint(),
							arqos.read().to_uint(),
							arregion.read().to_uint());

				if (ACE_MODE) {
					rt->SetAxSnoop(arsnoop.read().to_uint());
					rt->SetAxDomain(ardomain.read().to_uint());
					rt->SetAxBar(arbar.read().to_uint());

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
						rt->SetBeat(rt->GetBurstLength());
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

				Validate(rt);

				procesingTransId = InList(rtList, rt->GetTransactionID());

				rtList.push_back(rt);

				//
				// Start a thread handling this transaction ID if needed
				//
				if (!procesingTransId) {
					sc_spawn(sc_bind(&axi2tlm_bridge::RunTLMTransaction,
							this,
							&rtList,
							rt->GetTransactionID(),
							&rdDataFifo));
				}

				m_numReadTransactions++;
			}
		}
	}

	void read_data_phase()
	{
		rvalid.write(false);

		while (true) {
			Transaction *rt = rdDataFifo.read();

			// Set AXI response
			switch (rt->GetTLMResponse()) {
			case tlm::TLM_ADDRESS_ERROR_RESPONSE:
				rresp.write(AXI_DECERR);
				break;
			case tlm::TLM_GENERIC_ERROR_RESPONSE:
				rresp.write(AXI_SLVERR);
				break;
			default:
			case tlm::TLM_OK_RESPONSE:
				if (rt->IsExclusive() && rt->ExclusiveHandled()) {
					rresp.write(AXI_EXOKAY);
				} else {
					rresp.write(AXI_OKAY);
				}
				break;
			}

			//
			// If ACE_MODE == ACE_MODE_ACE an ongoing snoop channel
			// transactions to the same cache line is not allowed
			// at the same time
			//
			if (ACE_MODE == ACE_MODE_ACE) {
				sc_bv<4> tmp_rresp = rresp.read();

				if (m_snp_chnls->wait_for_snoop_channel(
						rt->GetAddress(),
						rt->GetDataLen()) == false) {

					delete rt;
					wait_for_reset_release();
					continue;
				}
				m_snp_chnls->lock_rresp.lock(rt->GetAddress(),
							rt->GetDataLen());

				tmp_rresp[2] = rt->PassDirty();
				tmp_rresp[3] = rt->IsShared();

				rresp.write(tmp_rresp);
			}

			rid.write(rt->GetTransactionID());

			while (!rt->Done()) {

				sc_bv<DATA_WIDTH> tmp = rdata;

				rt->GetData(tmp);

				rdata.write(tmp);
				rvalid.write(true);

				rlast.write(rt->IsLastBeat());

				// Wait for rready but abort if reset is asserted
				wait_abort_on_reset(rready);

				rvalid.write(false);

				if (reset_asserted()) {
					break;
				}

				rt->IncBeat();
			}

			rlast.write(false);

			if (ACE_MODE == ACE_MODE_ACE) {
				wait_abort_on_reset(rack);

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

	unsigned int get_num_ongoing_write()
	{
		return m_numWriteTransactions - m_numWriteBarriers;
	}

	bool assert_awready()
	{
		bool awready_val = true;

		if (get_num_ongoing_write() >= m_maxWriteTransactions) {
			awready_val = false;
		}

		if (ACE_MODE == ACE_MODE_ACE &&
			m_numWriteBarriers >= ACE::MaxBarriers) {
			awready_val = false;
		}

		return awready_val;
	}

	void write_address_phase()
	{
		while (true) {
			awready.write(assert_awready());

			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				wait_for_reset_release();
				continue;
			}

			if (awvalid.read() && awready.read()) {
				// Sample write address and control lines
				Transaction *wt = new Transaction(tlm::TLM_WRITE_COMMAND,
								awaddr.read().to_uint64(),
								to_uint(awlen) + 1,
								1 << awsize.read().to_uint(),
								awburst.read().to_uint(),
								to_uint(awid),
								to_uint(arprot),
								to_uint(awlock),
								awcache.read().to_uint(),
								awqos.read().to_uint(),
								awregion.read().to_uint(),
								true);

				if (ACE_MODE) {
					wt->SetAxSnoop(awsnoop.read().to_uint());
					wt->SetAxDomain(awdomain.read().to_uint());
					wt->SetAxBar(awbar.read().to_uint());

					wt->SetupNoWrDataTransfers();

					//
					// ACE has a limit of 256 outstanding
					// barriers (section C8.4.1 [1])
					//
					if (ACE_MODE == ACE_MODE_ACE &&
						wt->IsBarrier()) {
						m_numWriteBarriers++;
					}

					if (!wt->hasData() && wrDataList.empty()) {
						//
						// Barrier and Evict have no data
						//
						handle_no_data_tx(wt);
						m_numWriteTransactions++;
						continue;
					}
				}

				//
				// Master must issue write transactions in the
				// same order in which it issues transaction
				// addresses [1]
				//
				wrDataList.push_back(wt);
				m_numWriteTransactions++;
				m_awEvent.notify();
			}
		}
	}

	Transaction *next_from(std::list<Transaction*>& l)
	{
		if (l.empty()) {
			return NULL;
		}
		return l.front();
	}

	void handle_no_data_tx(Transaction *wt)
	{
		bool procesingTransId;

		procesingTransId = InList(wtList, wt->GetTransactionID());

		wtList.push_back(wt);

		if (!procesingTransId) {
			sc_spawn(sc_bind(
				&axi2tlm_bridge::RunTLMTransaction,
					this,
					&wtList,
					wt->GetTransactionID(),
					&wrRespFifo));
		}
	}

	void write_data_phase()
	{
		while (true) {
			bool procesingTransId;
			Transaction *wt;

			if (wrDataList.empty()) {
				wready.write(false);
				wait(m_awEvent);
			}

			wready.write(true);

			// Wait for wvalid but abort if reset is asserted
			wait_abort_on_reset(wvalid);

			if (reset_asserted()) {
				wait_for_reset_release();
				continue;
			}

			if (m_version == V_AXI4) {
				wt = wrDataList.front();

				if(!wt) {
					SC_REPORT_ERROR("axi2tlm-bridge",
						"Received unexpected write "
						"data");
				}
			} else {
				uint32_t id = to_uint(wid);

				wt = GetFirstWithID(&wrDataList, id);

				if(!wt) {
					SC_REPORT_ERROR("axi2tlm-bridge",
						"Transaction with unexpected "
						"transaction ID");
				}

				if (!PreviousHaveData(wrDataList, id)) {
					SC_REPORT_ERROR("axi2tlm-bridge",
						"The first data item of each "
						"transaction is not in the same "
						"order as the order of the "
						"addresses");
				}
			}

			wt->FillData(wdata, wstrb);

			wt->IncBeat();

			if (wt->Done()) {
				wrDataList.remove(wt);

				// Make sure wlast is set
				if (wlast.read() == false) {
					SC_REPORT_ERROR("axi2tlm-bridge",
						"wlast is not set on the last "
						"transaction");
				}

				wt->TryDropBE();

				//
				// Start a thread handling this transaction ID if needed
				//
				procesingTransId = InList(wtList, wt->GetTransactionID());

				wtList.push_back(wt);

				if (!procesingTransId) {
					sc_spawn(sc_bind(&axi2tlm_bridge::RunTLMTransaction,
							this,
							&wtList,
							wt->GetTransactionID(),
							&wrRespFifo));
				}

				if (ACE_MODE) {
					//
					// Barrier and Evict have no data
					//
					wt = next_from(wrDataList);

					while (wt && !wt->hasData()) {
						wrDataList.remove(wt);
						handle_no_data_tx(wt);
						wt = next_from(wrDataList);
					}
				}
			}
		}
	}

	void write_resp_phase()
	{
		bvalid.write(false);

		while (true) {
			Transaction *wt = wrRespFifo.read();

			// Set AXI response
			switch (wt->GetTLMResponse()) {
			case tlm::TLM_ADDRESS_ERROR_RESPONSE:
				bresp.write(AXI_DECERR);
				break;
			case tlm::TLM_GENERIC_ERROR_RESPONSE:
				bresp.write(AXI_SLVERR);
				break;
			default:
			case tlm::TLM_OK_RESPONSE:
				if (wt->IsExclusive() && wt->ExclusiveHandled()) {
					bresp.write(AXI_EXOKAY);
				} else {
					bresp.write(AXI_OKAY);
				}
				break;
			}

			bid.write(wt->GetTransactionID());

			bvalid.write(true);

			// Wait for bready but abort if reset is asserted
			wait_abort_on_reset(bready);

			bvalid.write(false);

			if (ACE_MODE == ACE_MODE_ACE) {
				wait_abort_on_reset(wack);
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

	void TLMListClear(std::list<Transaction*>& l)
	{
		// Schedule abort on transactions that are ongoing and abort
		// all others
		for (typename std::list<Transaction*>::iterator it = l.begin();
			it != l.end();) {
			Transaction *t = (*it);

			if (t->TLMOngoing()) {
				t->SetAbortScheduled();
				it++;
			} else {
				it = l.erase(it);
				delete t;
			}
		}
	}

	void reset()
	{
		while(true) {
			wait(resetn.negedge_event());

			//
			// Reset got asserted, abort all transactions
			//

			axi2tlm_clear_fifo(rdDataFifo);

			axi2tlm_clear_fifo(wrRespFifo);

			for (typename std::list<Transaction*>::iterator it = wrDataList.begin();
				it != wrDataList.end(); it++) {
				Transaction *t = (*it);
				delete t;
			}
			wrDataList.clear();

			TLMListClear(rtList);
			TLMListClear(wtList);

			m_numReadTransactions = 0;
			m_numWriteTransactions = 0;
		}
	}

	class axi_dummy : public sc_core::sc_module
	{
	public:
		// AXI4
		sc_signal<AXISignal(ID_WIDTH) > wid;

		// AXI3
		sc_signal<sc_bv<4> > awqos;
		sc_signal<sc_bv<4> > awregion;
		sc_signal<AXISignal(AWUSER_WIDTH) > awuser;
		sc_signal<AXISignal(WUSER_WIDTH) > wuser;
		sc_signal<AXISignal(BUSER_WIDTH) > buser;
		sc_signal<sc_bv<4> > arregion;
		sc_signal<sc_bv<4> > arqos;
		sc_signal<AXISignal(ARUSER_WIDTH) > aruser;
		sc_signal<AXISignal(RUSER_WIDTH) > ruser;

		// AXI4 ACE signals
		sc_signal<sc_bv<3> > awsnoop;
		sc_signal<sc_bv<2> > awdomain;
		sc_signal<sc_bv<2> > awbar;
		sc_signal<bool > wack;
		sc_signal<sc_bv<4> > arsnoop;
		sc_signal<sc_bv<2> > ardomain;
		sc_signal<sc_bv<2> > arbar;
		sc_signal<bool > rack;

		axi_dummy(sc_module_name name) :
			wid("wid"),
			awqos("awqos"),
			awregion("awregion"),
			awuser("awuser"),
			wuser("wuser"),
			buser("buser"),
			arregion("arregion"),
			arqos("arqos"),
			aruser("aruser"),
			ruser("ruser"),

			// AXI4 ACE signals
			awsnoop("awsnoop"),
			awdomain("awdomain"),
			awbar("awbar"),
			wack("wack"),
			arsnoop("arsnoop"),
			ardomain("ardomain"),
			arbar("arbar"),
			rack("rack")
		{ }
	};

	void bind_dummy(void)
	{
		if (m_version == V_AXI4) {
			wid(dummy.wid);

			//
			// Optional signals
			//
			if (AWUSER_WIDTH == 0) {
				awuser(dummy.awuser);
			}
			if (WUSER_WIDTH == 0) {
				wuser(dummy.wuser);
			}
			if (BUSER_WIDTH == 0) {
				buser(dummy.buser);
			}
			if (ARUSER_WIDTH == 0) {
				aruser(dummy.aruser);
			}
			if (RUSER_WIDTH == 0) {
				ruser(dummy.ruser);
			}

			if (ACE_MODE == ACE_MODE_OFF) {
				awsnoop(dummy.awsnoop);
				awdomain(dummy.awdomain);
				awbar(dummy.awbar);
				wack(dummy.wack);
				arsnoop(dummy.arsnoop);
				ardomain(dummy.ardomain);
				arbar(dummy.arbar);
				rack(dummy.rack);
			} else if (ACE_MODE == ACE_MODE_ACELITE) {
				rack(dummy.rack);
				wack(dummy.wack);
			}
		} else if (m_version == V_AXI3) {
			awqos(dummy.awqos);
			awregion(dummy.awregion);
			awuser(dummy.awuser);
			wuser(dummy.wuser);
			buser(dummy.buser);
			arregion(dummy.arregion);
			arqos(dummy.arqos);
			aruser(dummy.aruser);
			ruser(dummy.ruser);

			// AXI4 ACE signals
			awsnoop(dummy.awsnoop);
			awdomain(dummy.awdomain);
			awbar(dummy.awbar);
			wack(dummy.wack);
			arsnoop(dummy.arsnoop);
			ardomain(dummy.ardomain);
			arbar(dummy.arbar);
			rack(dummy.rack);
		}
	}

	void before_end_of_elaboration()
	{
		bind_dummy();
	}

	ACESnoopChannels_S__ *m_snp_chnls;

	sc_fifo<Transaction*> rdDataFifo;
	sc_fifo<Transaction*> wrRespFifo;

	sc_event		m_awEvent;
	std::list<Transaction*> wrDataList;

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

	AXIVersion m_version;
	axi_dummy dummy;
};
#endif
