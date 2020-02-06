/*
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
 *
 *
 * References:
 *
 * [1] AMBA 5 CHI Architecture Specification, ARM IHI 0050C, ID050218
 *
 */

#ifndef TLM_BRIDGES_PRIV_CHI_COMMON_H__
#define TLM_BRIDGES_PRIV_CHI_COMMON_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/chiattr.h"

#define CHI_TX_CH(name, flit_width)		\
sc_out<bool > name ## flitpend;			\
sc_out<bool > name ## flitv;			\
sc_out<sc_bv<flit_width> > name ## flit;	\
sc_in<bool > name ## lcrdv

#define CHI_RX_CH(name, flit_width)	\
sc_in<bool > name ## flitpend;		\
sc_in<bool > name ## flitv;		\
sc_in<sc_bv<flit_width> > name ## flit;	\
sc_out<bool > name ## lcrdv

#define CHI_INIT_CH(name)		\
name ## flitpend(#name "flitpend"),	\
name ## flitv(#name "flitv"),		\
name ## flit(#name "flit"),		\
name ## lcrdv(#name "lcrdv")


namespace AMBA {
namespace CHI {

enum LinkState { Stop,
		 Activate,
		 Run,
		 Deactivate };

template<typename TxnType>
class TxChannel :
	public sc_core::sc_module
{
public:
	SC_HAS_PROCESS(TxChannel);

	TxChannel(sc_core::sc_module_name name,
			sc_in<bool >& _clk,
			sc_in<bool >& _resetn,
			sc_out<bool >& _txlinkactivereq,
			sc_in<bool >&  _txlinkactiveack,
			sc_out<bool >& _flitpend,
			sc_out<bool >& _flitv,
			sc_out<sc_bv<TxnType::FLIT_WIDTH> >& _flit,
			sc_in<bool >& _lcrdv) :
		sc_module(name),
		clk(_clk),
		resetn(_resetn),
		txlinkactivereq(_txlinkactivereq),
		txlinkactiveack(_txlinkactiveack),
		flitpend(_flitpend),
		flitv(_flitv),
		flit(_flit),
		lcrdv(_lcrdv),
		m_credits(0)
	{
		SC_THREAD(tx_thread);
		SC_THREAD(reset_thread);
	}

	void Process(TxnType* tx)
	{
		m_txList.push_back(tx);

		wait(tx->DoneEvent());
	}

private:
	void tx_thread()
	{
		while (true) {

			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				flitv.write(false);
				wait(resetn.posedge_event());
				continue;
			}

			if (GetLinkState() == Stop) {
				//
				// Do nothing
				//
				continue;
			}

			flitv.write(false);

			if (lcrdv.read()) {
				m_credits++;
			}

			if (GetLinkState() == Activate) {
				//
				// Collect credits but do not transmit
				//
				continue;
			} else if (GetLinkState() == Run) {
				//
				// Always asserted, 13.4 [1]
				//
				flitpend.write(true);
			}

			//
			// If the flit is done: signal event and remove it from
			// the list.
			//
			if (!m_txList.empty() && m_txList.front()->Done()) {
				TxnType *t = m_txList.front();

				m_txList.pop_front();

				t->NotifyDone();
			}

			//
			// Setup next flit if there is one
			//
			if (m_credits && !m_txList.empty()) {
				TxnType *t = m_txList.front();

				t->CreateFlit(flit);

				flitv.write(true);
				m_credits--;
			} else if (m_credits && GetLinkState() == Deactivate) {
				//
				// Deactivate ongoing, return credits
				//
				CreateLCreditReturnFlit(flit);

				flitv.write(true);
				m_credits--;

				if (m_credits == 0) {
					flitpend.write(false);
				}
			}
		}
	}

	void CreateLCreditReturnFlit(sc_out<sc_bv<TxnType::FLIT_WIDTH> >& flit)
	{
		//
		// Opcode 0, TxnID 0 and other fields are don't care, 12.10 [1]
		//
		sc_bv<TxnType::FLIT_WIDTH> tmp; // Initialised to 0

		flit.write(tmp);
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
		return GetLinkState(txlinkactivereq.read(),
					txlinkactiveack.read());
	}

	void ClearList(std::list<TxnType*>& l)
	{
		for (typename std::list<TxnType*>::iterator it = l.begin();
			it != l.end();) {
			TxnType *t = (*it);

			it = l.erase(it);

			t->NotifyDone();

			delete t;
		}
	}

	void reset_thread()
	{
		while (true) {
			wait(resetn.negedge_event());

			ClearList(m_txList);
		}
	}

	sc_in<bool >& clk;
	sc_in<bool >& resetn;

	sc_out<bool >& txlinkactivereq;
	sc_in<bool >&  txlinkactiveack;

	sc_out<bool >& flitpend;
	sc_out<bool >& flitv;
	sc_out<sc_bv<TxnType::FLIT_WIDTH> >& flit;
	sc_in<bool >& lcrdv;

	unsigned int m_credits;
	std::list<TxnType*> m_txList;
};

template<typename TxnType>
class RxChannel :
	public sc_core::sc_module
{
public:
	enum { MAX_CREDITS = 15 };	// 13.2.1 [1]

	SC_HAS_PROCESS(RxChannel);

	RxChannel(sc_core::sc_module_name name,
			sc_in<bool >& _clk,
			sc_in<bool >& _resetn,
			sc_in<bool >&  _rxlinkactivereq,
			sc_out<bool >& _rxlinkactiveack,
			sc_in<bool >& _flitpend,
			sc_in<bool >& _flitv,
			sc_in<sc_bv<TxnType::FLIT_WIDTH> >& _flit,
			sc_out<bool >& _lcrdv) :
		sc_module(name),
		clk(_clk),
		resetn(_resetn),
		rxlinkactivereq(_rxlinkactivereq),
		rxlinkactiveack(_rxlinkactiveack),
		flitpend(_flitpend),
		flitv(_flitv),
		flit(_flit),
		lcrdv(_lcrdv),
		m_credits(MAX_CREDITS)
	{
		SC_THREAD(rx_thread);
		SC_THREAD(reset_thread);
	}

	//
	// Blocks until we can return and gives ownership of the pointer to the
	// caller (that will need to delete it).
	//
	TxnType *GetNext()
	{
		TxnType *t;

		if (m_txList.empty()) {
			wait(m_txnEvent);
		}

		t = m_txList.front();
		m_txList.pop_front();

		return t;
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
				lcrdv.write(false);
				wait(resetn.posedge_event());
				continue;
			}

			lcrdv.write(false);

			if (GetLinkState() == Stop) {
				//
				// Do nothing
				//
				continue;
			}

			//
			// Receive packet
			//
			if (flitv.read()) {
				sc_bv<TxnType::FLIT_WIDTH> tmpFlit = flit.read();
				TxnType *t;

				t = new TxnType(tmpFlit);

				m_txList.push_back(t);
				m_txnEvent.notify();

				m_credits++;
			}

			if (GetLinkState() == Deactivate) {
				//
				// Don't give more credits
				//
				continue;
			}

			if (m_credits) {
				lcrdv.write(true);
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
		return GetLinkState(rxlinkactivereq.read(),
					rxlinkactiveack.read());
	}

	void ClearList(std::list<TxnType*>& l)
	{
		for (typename std::list<TxnType*>::iterator it = l.begin();
			it != l.end();) {
			TxnType *t = (*it);

			it = l.erase(it);

			delete t;
		}
	}

	void reset_thread()
	{
		while (true) {
			wait(resetn.negedge_event());

			ClearList(m_txList);
		}
	}

	sc_in<bool >&  clk;
	sc_in<bool >& resetn;

	sc_in<bool >&  rxlinkactivereq;
	sc_out<bool >& rxlinkactiveack;

	sc_in<bool >& flitpend;
	sc_in<bool >& flitv;
	sc_in<sc_bv<TxnType::FLIT_WIDTH> >& flit;
	sc_out<bool >& lcrdv;

	unsigned int m_credits;
	std::list<TxnType*> m_txList;
	sc_event m_txnEvent;
};

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
		txsactive(bridge->txsactive),
		txlinkactivereq(bridge->txlinkactivereq),
		txlinkactiveack(bridge->txlinkactiveack),
		rxlinkactivereq(bridge->rxlinkactivereq),
		rxlinkactiveack(bridge->rxlinkactiveack),
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
		return GetLinkState(txlinkactivereq.read(),
					txlinkactiveack.read());
	}

	LinkState GetRxState()
	{
		return GetLinkState(rxlinkactivereq.read(),
					rxlinkactiveack.read());
	}

	void state_thread()
	{
		bool deactivateTx = false;

		// Always set
		txsactive.write(true);

		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				txlinkactivereq.write(false);
				rxlinkactiveack.write(false);
				wait(resetn.posedge_event());
				continue;
			}

			switch (GetRxState()) {
			case Activate:
				// Go to RUN
				rxlinkactiveack.write(true);

				break;
			case Deactivate:
				if (m_bridge->RxChnlsDeactivated()) {
					// Go to STOP
					rxlinkactiveack.write(false);
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
					txlinkactivereq.write(true);
				}

				break;
			case Run:
				if (m_state == Stop) {
					deactivateTx = true;
				}

				if (deactivateTx) {
					txlinkactivereq.write(false);
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

	sc_out<bool >& txsactive;

	sc_out<bool >& txlinkactivereq;
	sc_in<bool >&  txlinkactiveack;

	sc_in<bool >&  rxlinkactivereq;
	sc_out<bool >& rxlinkactiveack;

	LinkState m_state;

	T *m_bridge;
};

}; // namespace CHI
}; // namespace AMBA

#endif
