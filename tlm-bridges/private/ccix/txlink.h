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

#ifndef TLM_BRIDGES_PRIV_CCIX_TXLINK_H__
#define TLM_BRIDGES_PRIV_CCIX_TXLINK_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/ccixattr.h"
#include "tlm-bridges/private/ccix/pkts.h"

namespace CCIX {

//
// This class converts and tranmits (CCIX) TLP packets as CXS data flits on the
// CXS signals. The class also handles CXS TX link credits.
//
template<typename BRIDGE_T>
class TxLink :
	public sc_core::sc_module
{
public:
	typedef typename BRIDGE_T::CXSCntl_t CXSCntl_t;
	typedef typename BRIDGE_T::TLP_t TLP_t;

	enum {
		FLIT_WIDTH = BRIDGE_T::FLIT_WIDTH,
		CNTL_WIDTH = BRIDGE_T::CNTL_WIDTH
	};

	SC_HAS_PROCESS(TxLink);

	TxLink(sc_core::sc_module_name name, BRIDGE_T *bridge) :
		sc_module(name),

		clk(bridge->clk),
		resetn(bridge->resetn),

		txactivereq(bridge->txactivereq),
		txactiveack(bridge->txactiveack),
		txdeacthint(bridge->txdeacthint),

		txvalid(bridge->txvalid),
		txdata(bridge->txdata),
		txcntl(bridge->txcntl),
		txcrdgnt(bridge->txcrdgnt),
		txcrdrtn(bridge->txcrdrtn),

		m_credits(0)
	{
		SC_THREAD(tx_thread);
		SC_THREAD(reset_thread);
	}

	void Process(TLP_t *t)
	{
		m_tlpList.push_back(t);

		wait(t->DoneEvent());
	}

private:
	void tx_thread()
	{
		while (true) {

			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				txvalid.write(false);
				wait(resetn.posedge_event());
				continue;
			}

			if (GetLinkState() == Stop) {
				//
				// Do nothing
				//
				continue;
			}

			txvalid.write(false);
			txcrdrtn.write(false);

			if (txcrdgnt.read()) {
				m_credits++;
			}

			if (GetLinkState() == Activate) {
				//
				// Collect credits but do not transmit
				//
				continue;
			}

			//
			// If the flit is done: signal event and remove it from
			// the list.
			//
			if (!m_tlpList.empty() && m_tlpList.front()->Done()) {
				TLP_t *t = m_tlpList.front();

				m_tlpList.pop_front();

				t->NotifyDone();
			}

			//
			// Setup next flit if there is one
			//
			if (m_credits && !m_tlpList.empty()) {
				TLP_t *t = m_tlpList.front();
				CXSCntl_t cntl;

				t->CreateFlit(txdata, 0, cntl);

				txcntl.write(cntl.to_uint64());

				txvalid.write(true);
				m_credits--;
			} else if (m_credits && GetLinkState() == Deactivate) {
				//
				// Deactivate ongoing, return credits
				//
				txcrdrtn.write(true);
				m_credits--;
			}
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
		return GetLinkState(txactivereq.read(), txactiveack.read());
	}

	void ClearList(std::list<TLP_t*>& l)
	{
		for (typename std::list<TLP_t*>::iterator it = l.begin();
			it != l.end();) {
			TLP_t *t = (*it);

			it = l.erase(it);

			t->NotifyDone();
		}
	}

	void reset_thread()
	{
		while (true) {
			wait(resetn.negedge_event());

			ClearList(m_tlpList);
		}
	}

	sc_in<bool >& clk;
	sc_in<bool >& resetn;

	sc_out<bool >& txactivereq;
	sc_in<bool >&  txactiveack;
	sc_in<bool >&  txdeacthint;

	sc_out<bool >& txvalid;
	sc_out<sc_bv<FLIT_WIDTH> >& txdata;
	sc_out<sc_bv<CNTL_WIDTH> >& txcntl;
	sc_in<bool >& txcrdgnt;
	sc_out<bool >& txcrdrtn;

	unsigned int m_credits;
	std::list<TLP_t*> m_tlpList;
};

}; // namespace CCIX

#endif
