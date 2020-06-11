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
 *
 * [1] AMBA CXS Protocol Specification, Issue A, ARM IHI 0079
 *
 */

#ifndef TLM_BRIDGES_PRIV_CCIX_RXLINK_H__
#define TLM_BRIDGES_PRIV_CCIX_RXLINK_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/ccixattr.h"
#include "tlm-bridges/private/ccix/pkts.h"

namespace CCIX {

//
// This class translates received CXS data flits into TLP packets and extracts
// the internal CCIX messages inside the TLP. The extracted CCIX messages are
// represented with a generic payload (with an attached CCIX attributes
// extension). The class also handles CXS RX link credits.
//
template<typename BRIDGE_T>
class RxLink :
	public sc_core::sc_module
{
public:
	typedef typename BRIDGE_T::CXSCntl_t CXSCntl_t;
	typedef typename BRIDGE_T::TLPAssembler_t TLPAssembler_t;

	enum {
		MAX_CREDITS = 15,

		FLIT_WIDTH = BRIDGE_T::FLIT_WIDTH,
		CNTL_WIDTH = BRIDGE_T::CNTL_WIDTH
	};

	SC_HAS_PROCESS(RxLink);

	RxLink(sc_core::sc_module_name name, BRIDGE_T *bridge) :
		sc_module(name),

		clk(bridge->clk),
		resetn(bridge->resetn),

		rxactivereq(bridge->rxactivereq),
		rxactiveack(bridge->rxactiveack),

		rxvalid(bridge->rxvalid),
		rxdata(bridge->rxdata),
		rxcntl(bridge->rxcntl),
		rxcrdgnt(bridge->rxcrdgnt),
		rxcrdrtn(bridge->rxcrdrtn),

		m_credits(MAX_CREDITS)
	{
		SC_THREAD(rx_thread);
		SC_THREAD(reset_thread);
	}

	//
	// Blocks until we can return and gives ownership of the pointer to the
	// caller (that will need to delete it).
	//
	IMsg *GetNext()
	{
		IMsg *msg;

		if (m_ccixMsgs.empty()) {
			wait(m_msgEvent);
		}

		msg = m_ccixMsgs.front();
		m_ccixMsgs.pop_front();

		assert(msg);

		return msg;
	}

	bool Deactivated() { return m_credits == MAX_CREDITS; }

private:

	void rx_thread()
	{
		//
		// Ignore flitpend
		//
		while (true) {

			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				rxcrdgnt.write(false);
				wait(resetn.posedge_event());
				continue;
			}

			rxcrdgnt.write(false);

			if (GetLinkState() == Stop) {
				//
				// Do nothing
				//
				continue;
			}

			//
			// Receive packet
			//
			if (rxvalid.read()) {
				processRxCntl();
				processRxData();

				m_credits++;
			} else if (rxcrdrtn.read()) {
				m_credits++;
			}

			if (GetLinkState() == Deactivate) {
				//
				// Don't give more credits
				//
				continue;
			}

			if (m_credits) {
				rxcrdgnt.write(true);
				m_credits--;
			}
		}
	}

	enum {
		NumStartBits = BRIDGE_T::MAX_PKT_PER_FLIT,
		NumEndErrorBits = BRIDGE_T::MAX_PKT_PER_FLIT,
		NumEndBits = BRIDGE_T::MAX_PKT_PER_FLIT,

		StartPtr_Width = BRIDGE_T::START_PTR_WIDTH,
		EndPtr_Width = BRIDGE_T::END_PTR_WIDTH,

		StartPtr_Mask = (1 << StartPtr_Width) - 1,
		EndPtr_Mask = (1 << EndPtr_Width) - 1,

		//
		// Endbits bit position
		//
		EndBits_Shift = NumStartBits +
				(NumStartBits * StartPtr_Width),

		//
		// EndPtrs bit position
		//
		EndPtrs_Shift = EndBits_Shift +
				NumEndBits +
				NumEndErrorBits,
	};

	void processRxCntl()
	{
		CXSCntl_t cntl(rxcntl.read().to_uint64());

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
	void processRxData()
	{
		sc_bv<FLIT_WIDTH> flit = rxdata.read();
		int flit_pos;

		//
		// Process 4 bytes (32 bits) at a time
		//
		for (flit_pos = 0; flit_pos < flit.length(); flit_pos +=32) {
			if (!m_assemblers.empty()) {
				TLPAssembler_t *tlpAs = m_assemblers.front();

				if (flit_pos >= tlpAs->GetStartPtr()) {
					unsigned int firstbit = flit_pos;
					unsigned int lastbit =
							firstbit + 32 - 1;
					uint32_t val;

					val = flit.range(lastbit, firstbit).to_uint();

					//
					// Collect byte or u32?
					//
					tlpAs->PushBack(val);

					if (tlpAs->Done(flit_pos)) {
						m_assemblers.remove(tlpAs);

						tlpAs->ExtractCCIXMessages(m_ccixMsgs);

						delete tlpAs;

						m_msgEvent.notify();
					}
				}
			}
		}

		if (!m_assemblers.empty()) {
			//
			// For next flit collect data from the beginning
			//
			m_assemblers.front()->SetStartPtr(0);

			assert(m_assemblers.size() == 1);
		}
	}

	LinkState GetLinkState(bool req, bool ack)
	{
		if (req && ack) {
			return Run;
		} else if (req && !ack) {
			return Activate;
		} else if (!req && ack) {
			return Deactivate;
		}
		return Stop;
	}

	LinkState GetLinkState()
	{
		return GetLinkState(rxactivereq.read(),
					rxactiveack.read());
	}

	template<typename T>
	void ClearList(std::list<T*>& l)
	{
		for (typename std::list<T*>::iterator it = l.begin();
			it != l.end();) {
			T *t = (*it);

			it = l.erase(it);

			delete t;
		}
	}

	void reset_thread()
	{
		while (true) {
			wait(resetn.negedge_event());

			ClearList(m_assemblers);
			ClearList(m_ccixMsgs);
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

	sc_in<bool >& clk;
	sc_in<bool >& resetn;

	sc_in<bool >&  rxactivereq;
	sc_out<bool >& rxactiveack;

	sc_in<bool >& rxvalid;
	sc_in<sc_bv<BRIDGE_T::FLIT_WIDTH> >& rxdata;
	sc_in<sc_bv<BRIDGE_T::CNTL_WIDTH> >& rxcntl;
	sc_out<bool >& rxcrdgnt;
	sc_in<bool >& rxcrdrtn;

	unsigned int m_credits;
	sc_event m_msgEvent;
};

}; // namespace CCIX

#endif
