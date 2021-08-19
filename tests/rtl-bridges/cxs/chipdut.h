/*
 * Copyright (c) 2020 Xilinx Inc.
 * Written by Francisco Iglesias
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
#ifndef __CHIPDUT__H
#define __CHIPDUT__H

#include "tlm-bridges/tlm2chi-bridge-rnf.h"
#include "tlm-bridges/chi2tlm-bridge-rnf.h"
#include "tlm-bridges/tlm2chi-bridge-sn.h"
#include "tlm-bridges/chi2tlm-bridge-sn.h"

#include "tlm-bridges/tlm2axilite-bridge.h"
#include "rtl-bridges/pcie-host/cxs/tlm/tlm2cxs-hw-bridge.h"

#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/random-traffic.h"

#include "test-modules/signals-axilite.h"
#include "test-modules/signals-rnf-chi.h"
#include "test-modules/signals-sn-chi.h"
#include "test-modules/signals-cxs.h"

#include "tlm-modules/rnf-chi.h"
#include "tlm-modules/iconnect-chi.h"
#include "tlm-modules/sn-chi.h"

#include "Vcxs_bridge_top.h"

#define CACHE_SIZE (4 * CACHELINE_SZ)
#define RAM_SIZE (32 * CACHELINE_SZ)

typedef CHISignals<
tlm2chi_bridge_rnf<>::TXREQ_FLIT_WIDTH,
tlm2chi_bridge_rnf<>::TXRSP_FLIT_WIDTH,
tlm2chi_bridge_rnf<>::TXDAT_FLIT_WIDTH,
tlm2chi_bridge_rnf<>::RXRSP_FLIT_WIDTH,
tlm2chi_bridge_rnf<>::RXDAT_FLIT_WIDTH,
tlm2chi_bridge_rnf<>::RXSNP_FLIT_WIDTH
> CHISignals_t;

typedef CHISignals_SN<
tlm2chi_bridge_sn<>::TXREQ_FLIT_WIDTH,
tlm2chi_bridge_sn<>::TXDAT_FLIT_WIDTH,
tlm2chi_bridge_sn<>::RXRSP_FLIT_WIDTH,
tlm2chi_bridge_sn<>::RXDAT_FLIT_WIDTH
> CHISignals_SN_t;

template<int RN_ID, int HN_ID,
		int FLIT_WIDTH = 256,
		int CNTL_WIDTH = 14>
SC_MODULE(ChipDut)
{
	enum { SN_ID = HN_ID - 10 };

	typedef CXSSignals<FLIT_WIDTH, CNTL_WIDTH> CXSSignals_t;

	//
	// CXS_DATACHECK = 'Parity' uses one CNTL CHK bit
	//
	typedef CXSChkSignals<FLIT_WIDTH/8, 1> CXSChkSignals_t;

	//
	// RN-F <-> ICN signals
	//
	CHISignals_t signals_rnf;

	//
	// SlaveNode <-> ICN signals
	//
	CHISignals_SN_t signals_sn;

	//
	// AXI4Lite signals toward dut
	//
	AXILiteSignals<64, 32 > signals_al;

	//
	// Other signals
	//
	sc_signal<bool> irq_out;
	sc_signal<bool>	irq_ack;

	sc_signal<sc_bv<128> > h2c_intr_out;
	sc_signal<sc_bv<256> > h2c_gpio_out;

	sc_signal<sc_bv<64> > c2h_intr_in;
	sc_signal<sc_bv<256> > c2h_gpio_in;

	sc_signal<sc_bv<4> > usr_resetn;

	//
	// Checking signals
	//
	CXSChkSignals_t dummy_tx_chk;
	CXSChkSignals_t dummy_rx_chk;

	//
	// RN-F
	//
	RequestNode_F<RN_ID,
			CACHE_SIZE,
			HN_ID> rnf;

	//
	// ICN
	//
	iconnect_chi<HN_ID,
			SN_ID,
			1,
			1> icn;

	//
	// RN-F <-> ICN bridges
	//
	tlm2chi_bridge_rnf<> t2c_bridge;
	chi2tlm_bridge_rnf<> c2t_bridge;

	//
	// SlaveNode <-> ICN bridges
	//
	tlm2chi_bridge_sn<> t2c_bridge_sn;
	chi2tlm_bridge_sn<> c2t_bridge_sn;

	//
	// TLM2CXS HW bridge
	//
	tlm2cxs_hw_bridge<> cxs_hwb;
	tlm2axilite_bridge<64, 32 > al_bridge;
	Vcxs_bridge_top dut;

	//
	// SlaveNode with memory
	//
	SlaveNode_F<SN_ID> sn;
	memory mem;

	ChipDut(sc_module_name name, sc_clock& clk, sc_signal<bool>& resetn) :

		sc_module(name),

		//
		// Signals
		//
		signals_rnf("chi_signals"),
		signals_sn("chi_signals_sn"),

		signals_al("signals_al"),

		//
		// Other signals
		//
		irq_out("irq_out"),
		irq_ack("irq_ack"),

		h2c_intr_out("h2c_intr_out"),
		h2c_gpio_out("h2c_gpio_out"),

		c2h_intr_in("c2h_intr_in"),
		c2h_gpio_in("c2h_gpio_in"),

		usr_resetn("usr_resetn"),

		dummy_tx_chk("cxs_tx_chk_signals"),
		dummy_rx_chk("cxs_rx_chk_signals"),

		//
		// TLM components
		//
		rnf("rnf"),
		icn("icn"),

		t2c_bridge("tlm2chi_bridge"),
		c2t_bridge("chi2tlm_bridge"),

		t2c_bridge_sn("tlm2chi_bridge_sn"),
		c2t_bridge_sn("chi2tlm_bridge_sn"),

		cxs_hwb("cxs_hwb"),
		al_bridge("al_bridge"),
		dut("dut"),

		sn("sn"),
		mem("mem", sc_time(10, SC_NS), RAM_SIZE)
	{
		//
		// Setup rnf with the interconnect
		//
		connect(clk, resetn,
			rnf, t2c_bridge,
			signals_rnf,
			c2t_bridge,
			*icn.port_RN_F[0],
			*icn.port_CCIX[0],
			cxs_hwb);

		rnf.EnableDebug();

		//
		// Randomize transactions
		//
		rnf.GetCache().RandomizeTransactions(true);

		//
		// Setup slave node to the interconnect and memory
		//
		connect_sn(clk, resetn,
			*icn.port_SN, t2c_bridge_sn,
			signals_sn,
			c2t_bridge_sn, sn, mem);

		//
		// Connect CXS HWB <-> tlm2axilite bridge
		//
		cxs_hwb.bridge_socket(al_bridge.tgt_socket);

		//
		// CXS HWB irq
		//
		cxs_hwb.irq(irq_out);

		//
		// Connect the AXI4Lite signals
		//
		signals_al.connect(al_bridge);
		connect_al_signals(signals_al, dut);

		//
		// tlm2axilite bridge clk, resetn
		//
		al_bridge.clk(clk);
		al_bridge.resetn(resetn);

		//
		// Other signals
		//
		dut.clk(clk);
		dut.resetn(resetn);
		dut.c2h_gpio_in(c2h_gpio_in);
		dut.h2c_intr_out(h2c_intr_out);
		dut.h2c_gpio_out(h2c_gpio_out);
		dut.c2h_intr_in(c2h_intr_in);
		dut.irq_out(irq_out);
		dut.irq_ack(irq_ack);
		dut.usr_resetn(usr_resetn);
		usr_resetn.write(true);

		dut.CXS_CRDRTN_CHK_TX(dummy_tx_chk.crdrtn_chk);
		dut.CXS_CNTL_CHK_TX(dummy_tx_chk.cntl_chk);
		dut.CXS_VALID_CHK_TX(dummy_tx_chk.valid_chk);
		dut.CXS_CRDGNT_CHK_TX(dummy_tx_chk.crdgnt_chk);
		dut.CXS_DATA_CHK_TX(dummy_tx_chk.data_chk);

		dut.CXS_CRDRTN_CHK_RX(dummy_rx_chk.crdrtn_chk);
		dut.CXS_CNTL_CHK_RX(dummy_rx_chk.cntl_chk);
		dut.CXS_VALID_CHK_RX(dummy_rx_chk.valid_chk);
		dut.CXS_CRDGNT_CHK_RX(dummy_rx_chk.crdgnt_chk);
		dut.CXS_DATA_CHK_RX(dummy_rx_chk.data_chk);

		irq_ack.write(true);
	}

	template<typename T1, typename T2,
			typename T3, typename T4,
			typename T5,
			typename T6, typename T7,
			typename T8, typename T9>
	void connect(T1& clk, T2& resetn,
			T3& rn, T4& tlm2chi_b,
			T5& signals,
			T6& chi2tlm_b,
			T7& port_RN_F,
			T8& port_CCIX,
			T9& cxs_bridge)
	{
		// Connect clk
		tlm2chi_b.clk(clk);
		chi2tlm_b.clk(clk);

		// Connect reset
		tlm2chi_b.resetn(resetn);
		chi2tlm_b.resetn(resetn);
		cxs_bridge.resetn(resetn);

		// Connect RN-F signals
		signals.connectRNF(&tlm2chi_b);

		// Connect ICN signals
		signals.connectICN(&chi2tlm_b);

		// Connect tlm2chi bridge on the RN
		rn.connect(tlm2chi_b);

		// Connect chi2tlm bridge to the interconnect port
		port_RN_F.connect(chi2tlm_b);

		//
		// Connect ICN CCIX port to the TLM2CXS bridge
		//
		port_CCIX.txlink_init_socket(cxs_bridge.txlink_tgt_socket);
		cxs_bridge.rxlink_init_socket(port_CCIX.rxlink_tgt_socket);

		// Setup Port Node ID
		port_RN_F.SetNodeID(RN_ID);
	}

	template<typename T1, typename T2,
			typename T3, typename T4,
			typename T5,
			typename T6, typename T7, typename T8>
	void connect_sn(T1& clk, T2& resetn,
			T3& port_SN, T4& tlm2chi_b,
			T5& signals,
			T6& chi2tlm_b, T7& sn, T8& mem)
	{
		// Connect clk
		tlm2chi_b.clk(clk);
		chi2tlm_b.clk(clk);

		// Connect reset
		tlm2chi_b.resetn(resetn);
		chi2tlm_b.resetn(resetn);

		// Connect ICN signals
		signals.connectICN(&tlm2chi_b);

		// Connect SN signals
		signals.connectSN(&chi2tlm_b);

		// Connect tlm2ace bridge on the master
		port_SN.connect(tlm2chi_b);

		// Connect chi2tlm bridge to the interconnect port
		sn.connect(chi2tlm_b);

		// Connect the slave node to the memory
		sn.init_socket(mem.socket);
	}

	template<typename T1, typename T2>
	void connect_al_signals(T1& signals, T2& dut)
	{
		//
		// Since the AXILite Dut doesn't use the same naming
		// conventions as AXILiteSignals, we need to manually connect
		// everything.
		//
		dut.s_axi_awvalid(signals.awvalid);
		dut.s_axi_awready(signals.awready);
		dut.s_axi_awaddr(signals.awaddr);
		dut.s_axi_awprot(signals.awprot);

		dut.s_axi_arvalid(signals.arvalid);
		dut.s_axi_arready(signals.arready);
		dut.s_axi_araddr(signals.araddr);
		dut.s_axi_arprot(signals.arprot);

		dut.s_axi_wvalid(signals.wvalid);
		dut.s_axi_wready(signals.wready);
		dut.s_axi_wdata(signals.wdata);
		dut.s_axi_wstrb(signals.wstrb);

		dut.s_axi_bvalid(signals.bvalid);
		dut.s_axi_bready(signals.bready);
		dut.s_axi_bresp(signals.bresp);

		dut.s_axi_rvalid(signals.rvalid);
		dut.s_axi_rready(signals.rready);
		dut.s_axi_rdata(signals.rdata);
		dut.s_axi_rresp(signals.rresp);
	}

	void ConnectRX(CXSSignals_t& sgnls)
	{
		/* Write address channel.  */
		dut.CXS_ACTIVE_REQ_RX(sgnls.activereq);
		dut.CXS_ACTIVE_ACK_RX(sgnls.activeack);
		dut.CXS_DEACT_HINT_RX(sgnls.deacthint);

		dut.CXS_VALID_RX(sgnls.valid);
		dut.CXS_DATA_RX(sgnls.data);
		dut.CXS_CNTL_RX(sgnls.cntl);
		dut.CXS_CRDGNT_RX(sgnls.crdgnt);
		dut.CXS_CRDRTN_RX(sgnls.crdrtn);
	}

	void ConnectTX(CXSSignals_t& sgnls)
	{
		/* Write address channel.  */
		dut.CXS_ACTIVE_REQ_TX(sgnls.activereq);
		dut.CXS_ACTIVE_ACK_TX(sgnls.activeack);
		dut.CXS_DEACT_HINT_TX(sgnls.deacthint);

		dut.CXS_VALID_TX(sgnls.valid);
		dut.CXS_DATA_TX(sgnls.data);
		dut.CXS_CNTL_TX(sgnls.cntl);
		dut.CXS_CRDGNT_TX(sgnls.crdgnt);
		dut.CXS_CRDRTN_TX(sgnls.crdrtn);
	}

	void Trace(sc_trace_file *trace_fp)
	{
		//
		// Trace CHI RN-F <-> ICN signals
		//
		signals_rnf.Trace(trace_fp);

		//
		// Trace CHI SN <-> ICN signals
		//
		signals_sn.Trace(trace_fp);

		//
		// Trace AXI4Lite signals
		//
		signals_al.Trace(trace_fp);
	}
};

#endif
