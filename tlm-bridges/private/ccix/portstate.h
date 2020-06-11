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

#ifndef TLM_BRIDGES_PRIV_CCIX_PORTSTATE_H__
#define TLM_BRIDGES_PRIV_CCIX_PORTSTATE_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/ccixattr.h"
#include "tlm-bridges/private/ccix/pkts.h"

namespace CCIX {

enum LinkState { Stop,
		 Activate,
		 Run,
		 Deactivate };

template<typename T>
class PortState :
	public sc_core::sc_module
{
public:
	SC_HAS_PROCESS(PortState);

	PortState(sc_core::sc_module_name name,
			T *bridge) :
		sc_module(name),
		clk(bridge->clk),
		resetn(bridge->resetn),
		txactivereq(bridge->txactivereq),
		txactiveack(bridge->txactiveack),
		rxactivereq(bridge->rxactivereq),
		rxactiveack(bridge->rxactiveack),
		m_state(Run),
		m_bridge(bridge)
	{
		SC_THREAD(state_thread);
	}

	void SetState(LinkState state)
	{
		m_state = state;
	}

private:
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

	LinkState GetTxState()
	{
		return GetLinkState(txactivereq.read(), txactiveack.read());
	}

	LinkState GetRxState()
	{
		return GetLinkState(rxactivereq.read(), rxactiveack.read());
	}

	void state_thread()
	{
		bool deactivateTx = false;

		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				txactivereq.write(false);
				rxactiveack.write(false);
				wait(resetn.posedge_event());
				continue;
			}

			switch (GetRxState()) {
			case Activate:
				// Go to RUN
				rxactiveack.write(true);

				break;
			case Deactivate:
				if (m_bridge->RxLinkDeactivated()) {
					// Go to STOP
					rxactiveack.write(false);
				}

				// Forward deactivate to Tx
				if (GetTxState() == Run ||
					GetTxState() == Activate) {
					deactivateTx = true;
				}
				break;
			case Run:
			case Stop:
			default:
				// Nop
				break;
			}

			switch (GetTxState()) {
			case Stop:
				//
				// Always try to have link in run state
				//
				if (m_state == Run) {
					txactivereq.write(true);
				}

				break;
			case Run:
				if (m_state == Stop) {
					deactivateTx = true;
				}

				if (deactivateTx) {
					txactivereq.write(false);
					deactivateTx = false;
				}

				break;
			case Activate:
			case Deactivate:
			default:
				// Nop
				break;
			}
		}
	}

	sc_in<bool >&  clk;
	sc_in<bool >& resetn;

	sc_out<bool >& txactivereq;
	sc_in<bool >&  txactiveack;

	sc_in<bool >&  rxactivereq;
	sc_out<bool >& rxactiveack;

	LinkState m_state;

	T *m_bridge;
};

}; // namespace CCIX

#endif
