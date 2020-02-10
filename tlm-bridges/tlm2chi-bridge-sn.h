/*
 * TLM-2.0 to CHI bridge.
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

#ifndef TLM2CHI_BRIDGE_SN_H__
#define TLM2CHI_BRIDGE_SN_H__

#include "tlm-bridges/private/chi/pkts.h"
#include "tlm-bridges/private/chi/common.h"

template<
	int DATA_WIDTH = 512,
	int ADDR_WIDTH = 44,
	int NODEID_WIDTH = 7,
	int RSVDC_WIDTH = 32,
	int DATACHECK_WIDTH = 64,
	int POISON_WIDTH = 8,
	int DAT_OPCODE_WIDTH = Dat::Opcode_Width>
class tlm2chi_bridge_sn :
	public sc_core::sc_module
{
public:
	typedef tlm2chi_bridge_sn< DATA_WIDTH,
				ADDR_WIDTH,
				NODEID_WIDTH,
				RSVDC_WIDTH,
				DATACHECK_WIDTH,
				POISON_WIDTH,
				DAT_OPCODE_WIDTH> tlm2chi_bridge_sn_t;

	typedef BRIDGES::ReqPkt< ADDR_WIDTH,
			NODEID_WIDTH,
			RSVDC_WIDTH> ReqPkt_t;

	typedef BRIDGES::RspPkt<NODEID_WIDTH> RspPkt_t;

	// lsb 3 bits on address not used
	typedef BRIDGES::SnpPkt<ADDR_WIDTH-3, NODEID_WIDTH> SnpPkt_t;

	typedef BRIDGES::DatPkt< DATA_WIDTH,
			NODEID_WIDTH,
			RSVDC_WIDTH,
			DATACHECK_WIDTH,
			POISON_WIDTH,
			DAT_OPCODE_WIDTH> DatPkt_t;
	enum {
		TXREQ_FLIT_WIDTH = ReqPkt_t::FLIT_WIDTH,
		TXDAT_FLIT_WIDTH = DatPkt_t::FLIT_WIDTH,

		RXRSP_FLIT_WIDTH = RspPkt_t::FLIT_WIDTH,
		RXDAT_FLIT_WIDTH = DatPkt_t::FLIT_WIDTH,
		};


	tlm_utils::simple_target_socket<tlm2chi_bridge_sn> txreq_tgt_socket;
	tlm_utils::simple_target_socket<tlm2chi_bridge_sn> txdat_tgt_socket;

	tlm_utils::simple_initiator_socket<tlm2chi_bridge_sn> rxrsp_init_socket;
	tlm_utils::simple_initiator_socket<tlm2chi_bridge_sn> rxdat_init_socket;

	sc_in<bool > clk;
	sc_in<bool > resetn;

	sc_out<bool > txsactive;
	sc_in<bool >  rxsactive;

	//
	// TX link
	//
	sc_out<bool > txlinkactivereq;
	sc_in<bool >  txlinkactiveack;

	// Generate TX channels
	CHI_TX_CH(txreq, TXREQ_FLIT_WIDTH);
	CHI_TX_CH(txdat, TXDAT_FLIT_WIDTH);

	//
	// RX link
	//
	sc_in<bool >  rxlinkactivereq;
	sc_out<bool > rxlinkactiveack;

	// Generate RX channels
	CHI_RX_CH(rxrsp, RXRSP_FLIT_WIDTH);
	CHI_RX_CH(rxdat, RXDAT_FLIT_WIDTH);

	SC_HAS_PROCESS(tlm2chi_bridge_sn);

	tlm2chi_bridge_sn(sc_core::sc_module_name name) :
		sc_module(name),

		txreq_tgt_socket("txreq-tgt-socket"),
		txdat_tgt_socket("txdat-tgt-socket"),

		rxrsp_init_socket("rxrsp-init-socket"),
		rxdat_init_socket("rxdat-init-socket"),

		txlinkactivereq("txlinkactivereq"),
		txlinkactiveack("txlinkactiveack"),

		// Init TX channels
		CHI_INIT_CH(txreq),
		CHI_INIT_CH(txdat),

		rxlinkactivereq("rxlinkactivereq"),
		rxlinkactiveack("rxlinkactiveack"),

		// Init RX channels
		CHI_INIT_CH(rxrsp),
		CHI_INIT_CH(rxdat),

		//
		// Init TX channel processers
		//
		m_TxReqChannel("TxReqChannel",
				clk,
				resetn,
				txlinkactivereq,
				txlinkactiveack,
				txreqflitpend,
				txreqflitv,
				txreqflit,
				txreqlcrdv),

		m_TxDatChannel("TxDatChannel",
				clk,
				resetn,
				txlinkactivereq,
				txlinkactiveack,
				txdatflitpend,
				txdatflitv,
				txdatflit,
				txdatlcrdv),

		//
		// Init RX channel processers
		//
		m_RxRspChannel("RxRspChannel",
				clk,
				resetn,
				rxlinkactivereq,
				rxlinkactiveack,
				rxrspflitpend,
				rxrspflitv,
				rxrspflit,
				rxrsplcrdv),

		m_RxDatChannel("RxDatChannel",
				clk,
				resetn,
				rxlinkactivereq,
				rxlinkactiveack,
				rxdatflitpend,
				rxdatflitv,
				rxdatflit,
				rxdatlcrdv),

		m_PortState("PortState", this)
	{
		txreq_tgt_socket.register_b_transport(
				this, &tlm2chi_bridge_sn::b_transport_txreq);
		txdat_tgt_socket.register_b_transport(
				this, &tlm2chi_bridge_sn::b_transport_txdat);

		SC_THREAD(rxrsp_ch_thread);
		SC_THREAD(rxdat_ch_thread);
	}

	//
	// Called by PortState
	//
	bool RxChnlsDeactivated()
	{
		return m_RxRspChannel.Deactivated() &&
			m_RxDatChannel.Deactivated();
	}

private:

	virtual void b_transport_txreq(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		ReqPkt_t req(&trans);

		wait(delay, resetn.negedge_event());
		delay = SC_ZERO_TIME;

		if (resetn.read()) {
			m_TxReqChannel.Process(&req);
		} else {
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		}
	}

	virtual void b_transport_txdat(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		DatPkt_t dat(&trans);

		wait(delay, resetn.negedge_event());
		delay = SC_ZERO_TIME;

		if (resetn.read()) {
			m_TxDatChannel.Process(&dat);
		} else {
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		}
	}

	void rxrsp_ch_thread()
	{
		while (true) {
			sc_time delay(SC_ZERO_TIME);
			RspPkt_t *t = m_RxRspChannel.GetNext();

			// Run the TLM transaction.
			rxrsp_init_socket->b_transport(t->GetGP(), delay);

			wait(delay, resetn.negedge_event());

			delete t;
		}
	}

	void rxdat_ch_thread()
	{
		while (true) {
			sc_time delay(SC_ZERO_TIME);
			DatPkt_t *t = m_RxDatChannel.GetNext();

			// Run the TLM transaction.
			rxdat_init_socket->b_transport(t->GetGP(), delay);

			wait(delay, resetn.negedge_event());

			delete t;
		}
	}

	TxChannel<ReqPkt_t> m_TxReqChannel;
	TxChannel<DatPkt_t> m_TxDatChannel;

	RxChannel<RspPkt_t> m_RxRspChannel;
	RxChannel<DatPkt_t> m_RxDatChannel;

	PortState<tlm2chi_bridge_sn_t> m_PortState;
};

#endif
