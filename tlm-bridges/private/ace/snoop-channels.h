/*
 * AMBA ACE snoop channels.
 *
 * This file contains the two classes, the first class ACESnoopChannels_M
 * handles the snoop channels on the ACE master side and translates snoop
 * request on the ACE signals (ac channel) to TLM generic payloads with an
 * attached generic attributes extension. The generic payload transaction is
 * thereafter forwarded towards the TLM target connected on the snoop TLM
 * initiator socket. When done, the result of the TLM transaction is translated
 * and signaled back on the cr / cd channels as required (to the interconnect).
 * ACESnoopChannels_M is used by the tlm2axi_bridge when it is configured in
 * ACE mode.
 *
 * The second class ACESnoopChannels_S handles the snoop channels from the
 * interconnect side and translates snoop request described in the TLM generic
 * payloads with an generic attributes extension into signal wiggling on the
 * ACE signals (ac channel). The result of the request is then picked up on the
 * cr / cd channels and returned back with the generic payload.
 * ACESnoopChannels_S is used by the axi2tlm_bridge when it is configured in
 * ACE mode.
 *
 * Copyright (c) 2019 Xilinx Inc.
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

#ifndef TLM_BRIDGES_PRIV_ACE_SNOOP_CHANNELS_H__
#define TLM_BRIDGES_PRIV_ACE_SNOOP_CHANNELS_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "tlm-bridges/amba.h"
#include "tlm-bridges/amba-ace.h"
#include "tlm-extensions/genattr.h"

namespace AMBA {
namespace ACE {

//
// ACE master snoop channels
//
template<int ADDR_WIDTH, int CD_DATA_WIDTH, int CACHELINE_SZ>
class ACESnoopChannels_M : public sc_core::sc_module,
	public axi_common,
	public ace_helpers
{
public:
	enum { m_maxACE = 16 };

	tlm_utils::simple_initiator_socket<ACESnoopChannels_M> snoop_init_socket;

	sc_in<bool >& clk;
	sc_in<bool >& resetn;

	// Snoop address channel
	sc_in<bool >  acvalid;
	sc_out<bool > acready;
	sc_in<sc_bv<ADDR_WIDTH> > acaddr;
	sc_in<sc_bv<4> > acsnoop;
	sc_in<sc_bv<3> > acprot;

	// Snoop response channel
	sc_out<bool > crvalid;
	sc_in<bool >  crready;
	sc_out<sc_bv<5> > crresp;

	// Snoop data channel
	sc_out<bool > cdvalid;
	sc_in<bool >  cdready;
	sc_out<sc_bv<CD_DATA_WIDTH> > cddata;
	sc_out<bool > cdlast;

	SC_HAS_PROCESS(ACESnoopChannels_M);

	ACESnoopChannels_M(sc_module_name name,
				sc_in<bool>& _clk,
				sc_in<bool>& _resetn) :
		sc_module(name),
		axi_common(_clk, _resetn),

		snoop_init_socket("snoop-init-socket"),

		//
		clk(_clk),
		resetn(_resetn),

		// Snoop address channel
		acvalid("acvalid"),
		acready("acready"),
		acaddr("acaddr"),
		acsnoop("acsnoop"),
		acprot("acprot"),

		// Snoop response channel
		crvalid("crvalid"),
		crready("crready"),
		crresp("crresp"),

		// Snoop data channel
		cdvalid("cdvalid"),
		cdready("cdready"),
		cddata("cddata"),
		cdlast("cdlast"),

		m_cur_TLM(NULL),
		m_numDVMSyncResp(0),
		m_numACE(0)
	{
		SC_THREAD(ac_thread);
		SC_THREAD(cr_thread);
		SC_THREAD(cd_thread);

		SC_THREAD(reset);
	}

	sc_event& DVMSyncRespEvent() { return m_dvm_sync_resp_event; }

	unsigned int GetNumDVMSyncResp() { return m_numDVMSyncResp; }
	void DecNumDVMSyncResp() { m_numDVMSyncResp--; }
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

	void ac_thread()
	{
		while (true) {
			if (m_numACE < m_maxACE) {
				acready.write(true);
			} else {
				acready.write(false);
			}

			/* Wait for acvalid but abort if reset is asserted. */
			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				wait_for_reset_release();
				continue;
			}

			if (acvalid.read() && acready.read()) {
				ACETransaction *tr = new ACETransaction(
							acaddr.read().to_uint64(),
							to_uint(acsnoop),
							to_uint(acprot));

				m_crList.push_back(tr);
				m_numACE++;
				m_acEvent.notify();
			}
		}
	}

	void cr_thread()
	{
		while (true) {
			ACETransaction *tr;

			crresp.write(0);
			crvalid.write(false);

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

			crresp.write(tr->GetCrResp());
			crvalid.write(true);

			if (tr->HasDataTransfer()) {
				m_cdFifo.write(tr);
				tr = NULL;
			}

			wait_abort_on_reset(crready);

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
		int bus_width = CD_DATA_WIDTH/8;

		while (true) {
			ACETransaction *tr;
			unsigned char *data;
			unsigned int len;
			unsigned int pos;

			cddata.write(0);
			cdlast.write(false);
			cdvalid.write(false);

			tr = m_cdFifo.read();

			pos = 0;
			data = tr->GetData();
			len = tr->GetDataLen();

			while (pos < len) {
				sc_bv<CD_DATA_WIDTH> tmp_data;

				for (int i = 0; i < bus_width; i++) {
					int firstbit = i*8;
					int lastbit = firstbit + 8-1;

					if (pos < len) {
						tmp_data.range(lastbit, firstbit) =
							data[pos++];
					}
				}

				cddata.write(tmp_data);
				cdlast.write(pos == len);

				cdvalid.write(true);

				wait_abort_on_reset(cdready);
			}

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

	std::list<ACETransaction*> m_crList;
	sc_fifo<ACETransaction*> m_cdFifo;
	ACETransaction *m_cur_TLM;

	unsigned int m_numDVMSyncResp;
	unsigned int m_numACE;

	sc_event m_dvm_sync_resp_event;
	sc_event m_acEvent;
};

//
// ACE slave snoop channels
//
template<int ADDR_WIDTH, int CD_DATA_WIDTH>
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

	tlm_utils::simple_target_socket<ACESnoopChannels_S> snoop_target_socket;

	sc_in<bool >& clk;
	sc_in<bool >& resetn;

	// Snoop address channel
	sc_out<bool > acvalid;
	sc_in<bool >  acready;
	sc_out<sc_bv<ADDR_WIDTH> > acaddr;
	sc_out<sc_bv<4> > acsnoop;
	sc_out<sc_bv<3> > acprot;

	// Snoop response channel
	sc_in<bool >  crvalid;
	sc_out<bool > crready;
	sc_in<sc_bv<5> > crresp;

	// Snoop data channel
	sc_in<bool >  cdvalid;
	sc_out<bool > cdready;
	sc_in<sc_bv<CD_DATA_WIDTH> > cddata;
	sc_in<bool > cdlast;

	SC_HAS_PROCESS(ACESnoopChannels_S);

	ACELock lock_snoop;
	ACELock lock_rresp;
	ACELock lock_bresp;

	ACESnoopChannels_S(sc_module_name name,
				sc_in<bool>& _clk,
				sc_in<bool>& _resetn) :
		sc_module(name),
		axi_common(_clk, _resetn),

		snoop_target_socket("snoop-target-socket"),

		//
		clk(_clk),
		resetn(_resetn),

		// Snoop address channel
		acvalid("acvalid"),
		acready("acready"),
		acaddr("acaddr"),
		acsnoop("acsnoop"),
		acprot("acprot"),

		// Snoop response channel
		crvalid("crvalid"),
		crready("crready"),
		crresp("crresp"),

		// Snoop data channel
		cdvalid("cdvalid"),
		cdready("cdready"),
		cddata("cddata"),
		cdlast("cdlast"),
		lock_snoop("lock_snoop", _resetn),
		lock_rresp("lock_rresp", _resetn),
		lock_bresp("lock_bresp", _resetn)
	{
		snoop_target_socket.register_b_transport(this,
					&ACESnoopChannels_S::b_transport);

		SC_THREAD(ac_thread);
		SC_THREAD(cr_thread);
		SC_THREAD(cd_thread);

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

		acFifo.write(&tr);
		wait(tr.DoneEvent());

		m_overlapList.remove(&trans);

		lock_snoop.unlock();
	}

	void ac_thread()
	{
		acvalid.write(false);

		while (true) {
			ACETransaction *tr = acFifo.read();

			acaddr.write(tr->GetAddress());
			acsnoop.write(tr->GetAxSnoop());
			acprot.write(tr->GetAxProt());

			acvalid.write(true);
			wait_abort_on_reset(acready);
			acvalid.write(false);

			if (reset_asserted()) {
				abort(tr);
				wait_for_reset_release();
				continue;
			}

			crFifo.write(tr);
		}
	}

	void cr_thread()
	{
		crready.write(false);

		while (true) {
			ACETransaction *tr = crFifo.read();

			crready.write(true);
			wait_abort_on_reset(crvalid);
			crready.write(false);

			if (reset_asserted()) {
				abort(tr);
				wait_for_reset_release();
				continue;
			}

			tr->SetCrResp(crresp.read().to_uint());

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
	}

	void cd_thread()
	{
		int bus_width = CD_DATA_WIDTH/8;

		cdready.write(false);

		while (true) {
			ACETransaction *tr = cdFifo.read();
			tlm::tlm_generic_payload& trans = tr->GetGP();
			unsigned char *data = tr->GetData();
			unsigned int len = tr->GetDataLen();
			unsigned int pos = 0;

			while (pos < len) {
				cdready.write(true);
				wait_abort_on_reset(cdvalid);
				cdready.write(false);

				if (reset_asserted()) {
					abort(tr);
					wait_for_reset_release();
					continue;
				}

				for (int i = 0; i < bus_width; i++) {
					int firstbit = i*8;
					int lastbit = firstbit + 8-1;

					if (pos < len) {
						data[pos++] =
							cddata.read().range(lastbit, firstbit).to_uint();
					}
				}
			}

			// cdlast should be set here, check this?
			if (cdlast.read() != true) {
				std::cout <<
					"cdlast not set on last transaction! "
					<< std::endl;
			}

			// Set response and notify
			trans.set_response_status(tlm::TLM_OK_RESPONSE);
			tr->DoneEvent().notify();
		}
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

	sc_fifo<ACETransaction*> acFifo;
	sc_fifo<ACETransaction*> crFifo;
	sc_fifo<ACETransaction*> cdFifo;

	std::list<tlm::tlm_generic_payload*> m_overlapList;
};

// End of namespace ACE
};

// End of namespace AMBA
};

#endif
