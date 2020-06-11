/*
 * TLM-2.0 to CXS bridge.
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
 * [1] AMBA CXS Protocol Specification, Issue A, ARM IHI 0079
 *
 */

#ifndef TLM2CXS_BRIDGE_H__
#define TLM2CXS_BRIDGE_H__

#include "tlm-bridges/private/ccix/pkts.h"
#include "tlm-bridges/private/ccix/txlink.h"
#include "tlm-bridges/private/ccix/rxlink.h"
#include "tlm-bridges/private/ccix/portstate.h"

using namespace CCIX;

#define CXS_LOG2(x) \
((x == 2) ? 1 :	\
(x == 4) ? 2 :  \
(x == 8) ? 3 :  \
(x == 16) ? 4 : 5)

template<
	int _FLIT_WIDTH = 256,
	int _MAX_PKT_PER_FLIT = 2,
	typename TLPHdr = TLPHdr_comp
>
class tlm2cxs_bridge :
	public sc_core::sc_module
{
public:
	enum {
		FLIT_WIDTH = _FLIT_WIDTH,
		MAX_PKT_PER_FLIT = _MAX_PKT_PER_FLIT,

		//
		// Following CXS paramater values are used in the bridge:
		//
		// CXSCONTINUESDATA == true
		// CXSERRORFULLPKT == true
		// CXSCHECKTYPE == false
		// CXSLINKCONTROL == true
		//

		//
		// See 4.2.1 [1]
		//
		START_PTR_WIDTH = CXS_LOG2(FLIT_WIDTH/128),
		END_PTR_WIDTH = CXS_LOG2(FLIT_WIDTH/32),

		//
		// Sum of the widths of the START, END, ERROR, START PTRS and
		// END PTRS fields
		//
		CNTL_WIDTH =
			(3 * MAX_PKT_PER_FLIT) +
			(MAX_PKT_PER_FLIT * START_PTR_WIDTH) +
			(MAX_PKT_PER_FLIT * END_PTR_WIDTH),
	};

	typedef tlm2cxs_bridge< FLIT_WIDTH,
				MAX_PKT_PER_FLIT,
				TLPHdr
				> tlm2cxs_bridge_t;

	typedef CXSCntl<tlm2cxs_bridge_t> CXSCntl_t;
	typedef TLPHdr TLPHdr_t;
	typedef TLP<tlm2cxs_bridge_t> TLP_t;
	typedef TLPAssembler<TLPHdr_t> TLPAssembler_t;
	typedef TLPFactory<tlm2cxs_bridge_t> TLPFactory_t;

	typedef TxLink<tlm2cxs_bridge_t> TxLink_t;
	typedef RxLink<tlm2cxs_bridge_t> RxLink_t;
	typedef CCIX::PortState<tlm2cxs_bridge_t> PortState_t;


	tlm_utils::simple_target_socket<tlm2cxs_bridge> txlink_tgt_socket;
	tlm_utils::simple_initiator_socket<tlm2cxs_bridge> rxlink_init_socket;

	sc_in<bool > clk;
	sc_in<bool > resetn;

	//
	// TX link
	//
	sc_out<bool > txactivereq;
	sc_in<bool >  txactiveack;
	sc_in<bool >  txdeacthint;

	sc_out<bool > txvalid;
	sc_out<sc_bv<FLIT_WIDTH> > txdata;
	sc_out<sc_bv<CNTL_WIDTH> > txcntl;
	sc_in<bool > txcrdgnt;
	sc_out<bool > txcrdrtn;

	//
	// RX link
	//
	sc_in<bool >  rxactivereq;
	sc_out<bool > rxactiveack;
	sc_out<bool > rxdeacthint;

	sc_in<bool > rxvalid;
	sc_in<sc_bv<FLIT_WIDTH> > rxdata;
	sc_in<sc_bv<CNTL_WIDTH> > rxcntl;
	sc_out<bool > rxcrdgnt;
	sc_in<bool > rxcrdrtn;

	SC_HAS_PROCESS(tlm2cxs_bridge);

	tlm2cxs_bridge(sc_core::sc_module_name name) :
		sc_module(name),

		txlink_tgt_socket("txlink-tgt-socket"),
		rxlink_init_socket("rxlink-init-socket"),

		clk("clk"),
		resetn("resetn"),

		//
		// Init TX signals
		//
		txactivereq("txactivereq"),
		txactiveack("txactiveack"),
		txdeacthint("txdeacthint"),

		txvalid("txvalid"),
		txdata("txdata"),
		txcntl("txcntl"),
		txcrdgnt("txcrdgnt"),
		txcrdrtn("txcrdrtn"),

		//
		// Init RX signals
		//
		rxactivereq("rxactivereq"),
		rxactiveack("rxactiveack"),
		rxdeacthint("rxdeacthint"),

		rxvalid("rxvalid"),
		rxdata("rxdata"),
		rxcntl("rxcntl"),
		rxcrdgnt("rxcrdgnt"),
		rxcrdrtn("rxcrdrtn"),

		//
		// Init TX Link processer
		//
		m_TxLink("TxLink", this),

		//
		// Init RX Link processer
		//
		m_RxLink("RxLink", this),

		m_PortState("PortState", this)
	{
		txlink_tgt_socket.register_b_transport(
				this, &tlm2cxs_bridge::b_transport_txlink);

		SC_THREAD(rx_thread);
	}

	//
	// Called by PortState
	//
	bool RxLinkDeactivated()
	{
		return m_RxLink.Deactivated();
	}

	void SetPortState(CCIX::LinkState state)
	{
		m_PortState.SetState(state);
	}

private:

	virtual void b_transport_txlink(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		TLP_t *t = TLPFactory_t::Create(&trans);

		assert(t);

		wait(delay, resetn.negedge_event());
		delay = SC_ZERO_TIME;

		m_TxLink.Process(t);

		delete t;
	}

	void rx_thread()
	{
		while (true) {
			sc_time delay(SC_ZERO_TIME);
			IMsg *msg = m_RxLink.GetNext();

			// Run the TLM transaction.
			rxlink_init_socket->b_transport(msg->GetGP(), delay);

			wait(delay, resetn.negedge_event());

			delete msg;
		}
	}

	TxLink_t m_TxLink;
	RxLink_t m_RxLink;

	PortState_t m_PortState;
};

#undef CXS_LOG2
#endif
