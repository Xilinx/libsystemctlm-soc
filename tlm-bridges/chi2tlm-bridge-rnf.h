/*
 * CHI to TLM-2.0 bridge.
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

#ifndef CHI2TLM_BRIDGE_RNF_H__
#define CHI2TLM_BRIDGE_RNF_H__

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
class chi2tlm_bridge_rnf :
	public sc_core::sc_module
{
public:
	typedef chi2tlm_bridge_rnf< DATA_WIDTH,
				ADDR_WIDTH,
				NODEID_WIDTH,
				RSVDC_WIDTH,
				DATACHECK_WIDTH,
				POISON_WIDTH,
				DAT_OPCODE_WIDTH> chi2tlm_bridge_rnf_t;

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
		RXREQ_FLIT_WIDTH = ReqPkt_t::FLIT_WIDTH,
		RXRSP_FLIT_WIDTH = RspPkt_t::FLIT_WIDTH,
		RXDAT_FLIT_WIDTH = DatPkt_t::FLIT_WIDTH,

		TXRSP_FLIT_WIDTH = RspPkt_t::FLIT_WIDTH,
		TXDAT_FLIT_WIDTH = DatPkt_t::FLIT_WIDTH,
		TXSNP_FLIT_WIDTH = SnpPkt_t::FLIT_WIDTH,
		};


	tlm_utils::simple_initiator_socket<chi2tlm_bridge_rnf> rxreq_init_socket;
	tlm_utils::simple_initiator_socket<chi2tlm_bridge_rnf> rxrsp_init_socket;
	tlm_utils::simple_initiator_socket<chi2tlm_bridge_rnf> rxdat_init_socket;

	tlm_utils::simple_target_socket<chi2tlm_bridge_rnf> txrsp_tgt_socket;
	tlm_utils::simple_target_socket<chi2tlm_bridge_rnf> txdat_tgt_socket;
	tlm_utils::simple_target_socket<chi2tlm_bridge_rnf> txsnp_tgt_socket;

	sc_in<bool > clk;
	sc_in<bool > resetn;

	sc_in<bool >  rxsactive;
	sc_out<bool > txsactive;

	//
	// RX link
	//
	sc_in<bool >  rxlinkactivereq;
	sc_out<bool > rxlinkactiveack;

	// Generate RX channels
	CHI_RX_CH(rxreq, RXREQ_FLIT_WIDTH);
	CHI_RX_CH(rxrsp, RXRSP_FLIT_WIDTH);
	CHI_RX_CH(rxdat, RXDAT_FLIT_WIDTH);

	//
	// TX link
	//
	sc_out<bool > txlinkactivereq;
	sc_in<bool >  txlinkactiveack;

	// Generate TX channels
	CHI_TX_CH(txrsp, TXRSP_FLIT_WIDTH);
	CHI_TX_CH(txdat, TXDAT_FLIT_WIDTH);
	CHI_TX_CH(txsnp, TXSNP_FLIT_WIDTH);

	SC_HAS_PROCESS(chi2tlm_bridge_rnf);

	chi2tlm_bridge_rnf(sc_core::sc_module_name name) :
		sc_module(name),

		rxreq_init_socket("rxreq-init-socket"),
		rxrsp_init_socket("rxrsp-init-socket"),
		rxdat_init_socket("rxdat-init-socket"),

		txrsp_tgt_socket("txrsp-tgt-socket"),
		txdat_tgt_socket("txdat-tgt-socket"),
		txsnp_tgt_socket("txsnp-tgt-socket"),

		clk("clk"),
		resetn("resetn"),

		rxsactive("rxsactive"),
		txsactive("txsactive"),

		rxlinkactivereq("rxlinkactivereq"),
		rxlinkactiveack("rxlinkactiveack"),

		// Init TX channels
		CHI_INIT_CH(rxreq),
		CHI_INIT_CH(rxrsp),
		CHI_INIT_CH(rxdat),

		txlinkactivereq("txlinkactivereq"),
		txlinkactiveack("txlinkactiveack"),

		// Init RX channels
		CHI_INIT_CH(txrsp),
		CHI_INIT_CH(txdat),
		CHI_INIT_CH(txsnp),

		//
		// Init RX channel processers
		//
		m_RxReqChannel("RxReqChannel",
				clk,
				resetn,
				rxlinkactivereq,
				rxlinkactiveack,
				rxreqflitpend,
				rxreqflitv,
				rxreqflit,
				rxreqlcrdv),

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

		//
		// Init TX channel processers
		//
		m_TxRspChannel("TxRspChannel",
				clk,
				resetn,
				txlinkactivereq,
				txlinkactiveack,
				txrspflitpend,
				txrspflitv,
				txrspflit,
				txrsplcrdv),

		m_TxDatChannel("TxDatChannel",
				clk,
				resetn,
				txlinkactivereq,
				txlinkactiveack,
				txdatflitpend,
				txdatflitv,
				txdatflit,
				txdatlcrdv),

		m_TxSnpChannel("TxSnpChannel",
				clk,
				resetn,
				txlinkactivereq,
				txlinkactiveack,
				txsnpflitpend,
				txsnpflitv,
				txsnpflit,
				txsnplcrdv),

		m_PortState("PortState", this)
	{
		txrsp_tgt_socket.register_b_transport(
				this, &chi2tlm_bridge_rnf::b_transport_txrsp);
		txdat_tgt_socket.register_b_transport(
				this, &chi2tlm_bridge_rnf::b_transport_txdat);
		txsnp_tgt_socket.register_b_transport(
				this, &chi2tlm_bridge_rnf::b_transport_txsnp);

		SC_THREAD(rxreq_ch_thread);
		SC_THREAD(rxrsp_ch_thread);
		SC_THREAD(rxdat_ch_thread);
	}

	//
	// Called by PortState
	//
	bool RxChnlsDeactivated()
	{
		return m_RxReqChannel.Deactivated() &&
			m_RxRspChannel.Deactivated() &&
			m_RxDatChannel.Deactivated();
	}

	void SetPortState(LinkState state)
	{
		m_PortState.SetState(state);
	}

private:

	virtual void b_transport_txrsp(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		RspPkt_t rsp(&trans);

		wait(delay, resetn.negedge_event());
		delay = SC_ZERO_TIME;

		if (resetn.read()) {
			m_TxRspChannel.Process(&rsp);
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

	virtual void b_transport_txsnp(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		SnpPkt_t snp(&trans);

		wait(delay, resetn.negedge_event());
		delay = SC_ZERO_TIME;

		if (resetn.read()) {
			m_TxSnpChannel.Process(&snp);
		} else {
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		}
	}

	void rxreq_ch_thread()
	{
		while (true) {
			sc_time delay(SC_ZERO_TIME);
			ReqPkt_t *t = m_RxReqChannel.GetNext();

			// Run the TLM transaction.
			rxreq_init_socket->b_transport(t->GetGP(), delay);

			wait(delay, resetn.negedge_event());

			delete t;
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

	RxChannel<ReqPkt_t> m_RxReqChannel;
	RxChannel<RspPkt_t> m_RxRspChannel;
	RxChannel<DatPkt_t> m_RxDatChannel;

	TxChannel<RspPkt_t> m_TxRspChannel;
	TxChannel<DatPkt_t> m_TxDatChannel;
	TxChannel<SnpPkt_t> m_TxSnpChannel;

	PortState<chi2tlm_bridge_rnf_t> m_PortState;
};

#endif
