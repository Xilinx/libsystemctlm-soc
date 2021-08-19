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

#include <sstream>

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "tlm-bridges/tlm2chi-bridge-rnf.h"
#include "tlm-bridges/chi2tlm-bridge-rnf.h"
#include "tlm-bridges/tlm2axilite-bridge.h"
#include "checkers/pc-axilite.h"
#include "traffic-generators/tg-tlm.h"
#include "tlm-modules/rnf-chi.h"

#include "traffic-generators/random-traffic.h"

#include "rtl-bridges/pcie-host/chi/tlm/tlm2chi-hwb-rnf.h"
#include "rtl-bridges/pcie-host/chi/tlm/chi2tlm-hwb-rnf.h"

#include "tlm-modules/iconnect-chi.h"
#include "tlm-modules/sn-chi.h"
#include "test-modules/memory.h"

#include "test-modules/signals-axilite.h"
#include "test-modules/signals-rnf-chi.h"
#include "test-modules/utils-chi.h"

#include "checkers/pc-chi.h"

#include "Vchi_bridge_rn_top.h"
#include "Vchi_bridge_hn_top.h"

#include <verilated_vcd_sc.h>
#include "verilated.h"

using namespace utils::CHI;

#define NODE_ID_RNF0 0
#define NODE_ID_RNF1 1

#define NUM_RN_F 2

#define CACHE_SIZE (4 * CACHELINE_SZ)
#define LINE(l) ((l) * CACHELINE_SZ)

#define RAM_SIZE (32 * CACHELINE_SZ)

// Increase for more random traffic
#define NUM_TXNS_RNF0 20
#define NUM_TXNS_RNF1 20000

typedef TLMTrafficGenerator::DoneCallback TGDoneCB;

typedef tlm2chi_bridge_rnf<
        512, /* int DATA_WIDTH = 512, */
        48,  /* int ADDR_WIDTH = 48, */
        7,   /* int NODEID_WIDTH = 7, */
        0,   /* int RSVDC_WIDTH = 0, */
        64,  /* int DATACHECK_WIDTH = 64, */
        8,   /* POISON_WIDTH = 8 */
	Dat::Opcode_Width_3 /* CHI Issue B */
> tlm2chi_bridge_rnf_t;

typedef chi2tlm_bridge_rnf<
        512, /* int DATA_WIDTH = 512, */
        48,  /* int ADDR_WIDTH = 48, */
        7,   /* int NODEID_WIDTH = 7, */
        0,   /* int RSVDC_WIDTH = 0, */
        64,  /* int DATACHECK_WIDTH = 64, */
        8,   /* POISON_WIDTH = 8 */
	Dat::Opcode_Width_3 /* CHI Issue B */
> chi2tlm_bridge_rnf_t;

typedef tlm2chi_hwb_rnf<
        512, /* int DATA_WIDTH = 512, */
        48,  /* int ADDR_WIDTH = 48, */
        7,   /* int NODEID_WIDTH = 7, */
        0,   /* int RSVDC_WIDTH = 0, */
        64,  /* int DATACHECK_WIDTH = 64, */
        8,   /* POISON_WIDTH = 8 */
	Dat::Opcode_Width_3 /* CHI Issue B */
> tlm2chi_hwb_rnf_t;

typedef chi2tlm_hwb_rnf<
        512, /* int DATA_WIDTH = 512, */
        48,  /* int ADDR_WIDTH = 48, */
        7,   /* int NODEID_WIDTH = 7, */
        0,   /* int RSVDC_WIDTH = 0, */
        64,  /* int DATACHECK_WIDTH = 64, */
        8,   /* POISON_WIDTH = 8 */
	Dat::Opcode_Width_3 /* CHI Issue B */
> chi2tlm_hwb_rnf_t;

typedef CHISignals<
tlm2chi_bridge_rnf_t::TXREQ_FLIT_WIDTH,
tlm2chi_bridge_rnf_t::TXRSP_FLIT_WIDTH,
tlm2chi_bridge_rnf_t::TXDAT_FLIT_WIDTH,
tlm2chi_bridge_rnf_t::RXRSP_FLIT_WIDTH,
tlm2chi_bridge_rnf_t::RXDAT_FLIT_WIDTH,
tlm2chi_bridge_rnf_t::RXSNP_FLIT_WIDTH
> CHISignals_t;

typedef CHIProtocolChecker<
        512, /* int DATA_WIDTH = 512, */
        48,  /* int ADDR_WIDTH = 48, */
        7,   /* int NODEID_WIDTH = 7, */
        0,   /* int RSVDC_WIDTH = 0, */
        64,  /* int DATACHECK_WIDTH = 64, */
        8,   /* POISON_WIDTH = 8 */
	Dat::Opcode_Width_3 /* CHI Issue B */
> CHIChecker_t;

typedef TLMTrafficGenerator::DoneCallback TGDoneCallBack;

sc_event *tgDone;

void tgDoneCallBack(TLMTrafficGenerator *gen, int threadID)
{
	tgDone->notify();
}

AXILitePCConfig pc_axilite_config()
{
	AXILitePCConfig cfg;

	cfg.enable_all_checks();

	return cfg;
}

CHIPCConfig pc_chi_config()
{
	CHIPCConfig cfg;

	cfg.enable_all_checks();

	return cfg;
}

// Top simulation module.
SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst_n; // Active low.

	AXILiteSignals<64, 32 > al_signals_rn;
	AXILiteSignals<64, 32 > al_signals_hn;
	tlm2axilite_bridge<64, 32 > bridge_rn;
	tlm2axilite_bridge<64, 32 > bridge_hn;
        AXILiteProtocolChecker<64, 32 > checker;

	RandomTraffic rand_traffic0;
	RandomTraffic rand_traffic1;

	// dut
	Vchi_bridge_rn_top dut_rn;
	Vchi_bridge_hn_top dut_hn;

	CHISignals_t signals_chi_dut;
	CHISignals_t signals1;

	RequestNode_F<NODE_ID_RNF0, CACHE_SIZE> rnf0;
	RequestNode_F<NODE_ID_RNF1, CACHE_SIZE> rnf1;

	tlm2chi_hwb_rnf_t t2c_hw_bridge0;
	chi2tlm_hwb_rnf_t c2t_hw_bridge0;

	tlm2chi_bridge_rnf_t t2c_bridge1;
	chi2tlm_bridge_rnf_t c2t_bridge1;

	// Interconnect + slave mem
	iconnect_chi<20, 10, NUM_RN_F> icn;
	SlaveNode_F<> sn;
	memory mem;

	CHIChecker_t checker0;

	sc_signal<sc_bv<128> > h2c_intr_out;
	sc_signal<sc_bv<256> > h2c_gpio_out;

	sc_signal<sc_bv<128> > h2c_intr_out2;
	sc_signal<sc_bv<256> > h2c_gpio_out2;

	sc_signal<sc_bv<64> > c2h_intr_in;
	sc_signal<sc_bv<256> > c2h_gpio_in;

	sc_signal<bool> irq_out;
	sc_signal<bool> irq_out2;

	sc_signal<bool>	irq_ack;
	sc_signal<sc_bv<4> > usr_resetn;
	sc_signal<sc_bv<4> > usr_resetn2;

	sc_signal<bool> CHI_SYSCOREQ;
	sc_signal<bool> CHI_SYSCOACK;

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name, TGDoneCallBack tgDoneCB) :

		clk("clk", sc_time(1, SC_US)),
		rst_n("rst_n"),
		al_signals_rn("axilite_sgnls_rn"),
		al_signals_hn("axilite_sgnls_hn"),
		bridge_rn("bridge_rn"),
		bridge_hn("bridge_hn"),
                checker("checker", pc_axilite_config()),

		rand_traffic0(0, RAM_SIZE, (~(0x3llu)),
				1, RAM_SIZE, RAM_SIZE, NUM_TXNS_RNF0),
		rand_traffic1(0, RAM_SIZE, (~(0x3llu)),
				1, RAM_SIZE, RAM_SIZE, NUM_TXNS_RNF1),

		dut_rn("dut_rn"),
		dut_hn("dut_hn"),
		signals_chi_dut("signals_chi_dut"),
		signals1("chi_signals1"),

		rnf0("rnf0"),
		rnf1("rnf1", rand_traffic1),

		t2c_hw_bridge0("tlm2chi_hw_bridge0"),
		c2t_hw_bridge0("chi2tlm_hw_bridge0"),

		t2c_bridge1("tlm2chi_bridge1"),
		c2t_bridge1("chi2tlm_bridge1"),

		icn("iconnect_chi"),
		sn("sn"),
		mem("mem", sc_time(10, SC_NS), RAM_SIZE),

		checker0("chi_checker0", pc_chi_config()),

		h2c_intr_out("h2c_intr_out"),
		h2c_gpio_out("h2c_gpio_out"),
		h2c_intr_out2("h2c_intr_out2"),
		h2c_gpio_out2("h2c_gpio_out2"),

		c2h_intr_in("c2h_intr_in"),
		c2h_gpio_in("c2h_gpio_in"),

		irq_out("irq_out"),
		irq_out2("irq_out2"),

		irq_ack("irq_ack"),
		usr_resetn("usr_resetn"),
		usr_resetn2("usr_resetn2"),
		CHI_SYSCOREQ("CHI_SYSCOREQ"),
		CHI_SYSCOACK("CHI_SYSCOACK"),

		m_tgDoneCB(tgDoneCB)
	{

		// always keep high
		irq_ack.write(true);

		//
		// Configure the traffic generators
		//
		rnf1.GetTrafficGenerator().setStartDelay(sc_time(100, SC_US));
		rnf0.GetTrafficGenerator().enableDebug();
		rnf0.GetTrafficGenerator().setStartDelay(sc_time(100, SC_US));
		rnf0.GetTrafficGenerator().addTransfers(rand_traffic0, 0,
							m_tgDoneCB);

		// Wire up the clock and reset signals.
		bridge_rn.clk(clk);
		bridge_rn.resetn(rst_n);
		bridge_hn.clk(clk);
		bridge_hn.resetn(rst_n);
		checker.clk(clk);
		checker.resetn(rst_n);

		// hw bridge
		t2c_hw_bridge0.resetn(rst_n);
		t2c_hw_bridge0.bridge_socket.bind(bridge_rn.tgt_socket);
		t2c_hw_bridge0.irq(irq_out);

		// hw bridge
		c2t_hw_bridge0.resetn(rst_n);
		c2t_hw_bridge0.bridge_socket.bind(bridge_hn.tgt_socket);
		c2t_hw_bridge0.irq(irq_out);

		// icn <-> dut connection
		connect_icn_hw_bridge();

		// icn <-> sn connection
		connect_icn_sn();

		//
		// dut rn
		//
		dut_rn.clk(clk);
		dut_rn.resetn(rst_n);
		dut_rn.c2h_gpio_in(c2h_gpio_in);
		dut_rn.h2c_intr_out(h2c_intr_out);
		dut_rn.h2c_gpio_out(h2c_gpio_out);
		dut_rn.c2h_intr_in(c2h_intr_in);
		dut_rn.irq_out(irq_out);
		dut_rn.irq_ack(irq_ack);
		dut_rn.usr_resetn(usr_resetn);
		usr_resetn.write(true);

		// dut_hn
		dut_hn.clk(clk);
		dut_hn.resetn(rst_n);
		dut_hn.c2h_gpio_in(c2h_gpio_in);
		dut_hn.h2c_intr_out(h2c_intr_out2);
		dut_hn.h2c_gpio_out(h2c_gpio_out2);
		dut_hn.c2h_intr_in(c2h_intr_in);
		dut_hn.irq_out(irq_out2);
		dut_hn.irq_ack(irq_ack);
		dut_hn.usr_resetn(usr_resetn2);

		//
		// Connect rnf0 and rnf1
		//
		rnf0.connect(t2c_hw_bridge0);

		//
		// Setup rnf1 with the interconnect
		//
		connect(clk, rst_n,
			rnf1, t2c_bridge1,
			signals1,
			c2t_bridge1, *icn.port_RN_F[1]);

		//
		// DUT CHI Signals
		//
		connect_chi_signals_dut_rn();
		connect_chi_signals_dut_hn();

		// Wire-up the bridge and checker.
		al_signals_rn.connect(bridge_rn);
		al_signals_rn.connect(checker);

		al_signals_hn.connect(bridge_hn);

		//
		// DUT AXI4Lite Signals
		//
		connect_axilite_signals(al_signals_rn, dut_rn);
		connect_axilite_signals(al_signals_hn, dut_hn);

		//
		// Connect the CHI checker to DUT CHI signals
		//
		checker0.clk(clk);
		checker0.resetn(rst_n);
		signals_chi_dut.connectRNF(&checker0);

		SC_THREAD(tgDone_thread);
	}

	void connect_icn_hw_bridge()
	{
		//
		// TxLink
		//
		icn.port_RN_F[0]->txrsp_init_socket.bind(
				c2t_hw_bridge0.txrsp_tgt_socket);
		icn.port_RN_F[0]->txdat_init_socket.bind(
				c2t_hw_bridge0.txdat_tgt_socket);
		icn.port_RN_F[0]->txsnp_init_socket.bind(
				c2t_hw_bridge0.txsnp_tgt_socket);

		//
		// RxLink
		//
		c2t_hw_bridge0.rxreq_init_socket.bind(
				icn.port_RN_F[0]->rxreq_tgt_socket);
		c2t_hw_bridge0.rxrsp_init_socket.bind(
				icn.port_RN_F[0]->rxrsp_tgt_socket);
                c2t_hw_bridge0.rxdat_init_socket.bind(
				icn.port_RN_F[0]->rxdat_tgt_socket);
	}

	void tgDone_thread()
	{
		while (true) {
			wait(tgDone);
			if (!rand_traffic0.done()) {
				rnf0.GetTrafficGenerator().addTransfers(
					rand_traffic0, 0, m_tgDoneCB);
			} else {
				sc_stop();
			}
		}
	}

	template<typename T1, typename T2>
	void connect_axilite_signals(T1& signals, T2& dut)
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

	void connect_chi_signals_dut_rn()
	{
		// Dut
		dut_rn.CHI_TXSACTIVE(signals_chi_dut.sactive0);
		dut_rn.CHI_RXSACTIVE(signals_chi_dut.sactive1);

		dut_rn.CHI_TXLINKACTIVEREQ(signals_chi_dut.linkactivereq0);
		dut_rn.CHI_TXLINKACTIVEACK(signals_chi_dut.linkactiveack0);

		//
		// REQ channel
		//
		dut_rn.CHI_TXREQFLITPEND(signals_chi_dut.reqflitpend0);
		dut_rn.CHI_TXREQFLITV(signals_chi_dut.reqflitv0);
		dut_rn.CHI_TXREQFLIT(signals_chi_dut.reqflit0);
		dut_rn.CHI_TXREQLCRDV(signals_chi_dut.reqlcrdv0);

		//
		// RSP channel
		//
		dut_rn.CHI_TXRSPFLITPEND(signals_chi_dut.rspflitpend0);
		dut_rn.CHI_TXRSPFLITV(signals_chi_dut.rspflitv0);
		dut_rn.CHI_TXRSPFLIT(signals_chi_dut.rspflit0);
		dut_rn.CHI_TXRSPLCRDV(signals_chi_dut.rsplcrdv0);

		//
		// DAT channel
		//
		dut_rn.CHI_TXDATFLITPEND(signals_chi_dut.datflitpend0);
		dut_rn.CHI_TXDATFLITV(signals_chi_dut.datflitv0);
		dut_rn.CHI_TXDATFLIT(signals_chi_dut.datflit0);
		dut_rn.CHI_TXDATLCRDV(signals_chi_dut.datlcrdv0);

		dut_rn.CHI_RXLINKACTIVEREQ(signals_chi_dut.linkactivereq1);
		dut_rn.CHI_RXLINKACTIVEACK(signals_chi_dut.linkactiveack1);

		//
		// RSP channel
		//
		dut_rn.CHI_RXRSPFLITPEND(signals_chi_dut.rspflitpend1);
		dut_rn.CHI_RXRSPFLITV(signals_chi_dut.rspflitv1);
		dut_rn.CHI_RXRSPFLIT(signals_chi_dut.rspflit1);
		dut_rn.CHI_RXRSPLCRDV(signals_chi_dut.rsplcrdv1);

		//
		// DAT channel
		//
		dut_rn.CHI_RXDATFLITPEND(signals_chi_dut.datflitpend1);
		dut_rn.CHI_RXDATFLITV(signals_chi_dut.datflitv1);
		dut_rn.CHI_RXDATFLIT(signals_chi_dut.datflit1);
		dut_rn.CHI_RXDATLCRDV(signals_chi_dut.datlcrdv1);

		//
		// SNP channel
		//
		dut_rn.CHI_RXSNPFLITPEND(signals_chi_dut.snpflitpend1);
		dut_rn.CHI_RXSNPFLITV(signals_chi_dut.snpflitv1);
		dut_rn.CHI_RXSNPFLIT(signals_chi_dut.snpflit1);
		dut_rn.CHI_RXSNPLCRDV(signals_chi_dut.snplcrdv1);

		dut_rn.CHI_SYSCOREQ(CHI_SYSCOREQ);
		dut_rn.CHI_SYSCOACK(CHI_SYSCOACK);
	}

	void connect_chi_signals_dut_hn()
	{
		// Dut
		dut_hn.CHI_RXSACTIVE(signals_chi_dut.sactive0);
		dut_hn.CHI_TXSACTIVE(signals_chi_dut.sactive1);

		dut_hn.CHI_RXLINKACTIVEREQ(signals_chi_dut.linkactivereq0);
		dut_hn.CHI_RXLINKACTIVEACK(signals_chi_dut.linkactiveack0);

		//
		// REQ channel
		//
		dut_hn.CHI_RXREQFLITPEND(signals_chi_dut.reqflitpend0);
		dut_hn.CHI_RXREQFLITV(signals_chi_dut.reqflitv0);
		dut_hn.CHI_RXREQFLIT(signals_chi_dut.reqflit0);
		dut_hn.CHI_RXREQLCRDV(signals_chi_dut.reqlcrdv0);

		//
		// RSP channel
		//
		dut_hn.CHI_RXRSPFLITPEND(signals_chi_dut.rspflitpend0);
		dut_hn.CHI_RXRSPFLITV(signals_chi_dut.rspflitv0);
		dut_hn.CHI_RXRSPFLIT(signals_chi_dut.rspflit0);
		dut_hn.CHI_RXRSPLCRDV(signals_chi_dut.rsplcrdv0);

		//
		// DAT channel
		//
		dut_hn.CHI_RXDATFLITPEND(signals_chi_dut.datflitpend0);
		dut_hn.CHI_RXDATFLITV(signals_chi_dut.datflitv0);
		dut_hn.CHI_RXDATFLIT(signals_chi_dut.datflit0);
		dut_hn.CHI_RXDATLCRDV(signals_chi_dut.datlcrdv0);

		dut_hn.CHI_TXLINKACTIVEREQ(signals_chi_dut.linkactivereq1);
		dut_hn.CHI_TXLINKACTIVEACK(signals_chi_dut.linkactiveack1);

		//
		// RSP channel
		//
		dut_hn.CHI_TXRSPFLITPEND(signals_chi_dut.rspflitpend1);
		dut_hn.CHI_TXRSPFLITV(signals_chi_dut.rspflitv1);
		dut_hn.CHI_TXRSPFLIT(signals_chi_dut.rspflit1);
		dut_hn.CHI_TXRSPLCRDV(signals_chi_dut.rsplcrdv1);

		//
		// DAT channel
		//
		dut_hn.CHI_TXDATFLITPEND(signals_chi_dut.datflitpend1);
		dut_hn.CHI_TXDATFLITV(signals_chi_dut.datflitv1);
		dut_hn.CHI_TXDATFLIT(signals_chi_dut.datflit1);
		dut_hn.CHI_TXDATLCRDV(signals_chi_dut.datlcrdv1);

		//
		// SNP channel
		//
		dut_hn.CHI_TXSNPFLITPEND(signals_chi_dut.snpflitpend1);
		dut_hn.CHI_TXSNPFLITV(signals_chi_dut.snpflitv1);
		dut_hn.CHI_TXSNPFLIT(signals_chi_dut.snpflit1);
		dut_hn.CHI_TXSNPLCRDV(signals_chi_dut.snplcrdv1);

		dut_hn.CHI_SYSCOREQ(CHI_SYSCOREQ);
		dut_hn.CHI_SYSCOACK(CHI_SYSCOACK);

		CHI_SYSCOREQ.write(true);
	}

	void connect_icn_sn()
	{
		// icn -> sn
		icn.port_SN[0].txreq_init_socket.bind(sn.rxreq_tgt_socket);
		icn.port_SN[0].txdat_init_socket.bind(sn.rxdat_tgt_socket);

		sn.txrsp_init_socket.bind(icn.port_SN[0].rxrsp_tgt_socket);
                sn.txdat_init_socket.bind(icn.port_SN[0].rxdat_tgt_socket);

		// Connect the slave node to the memory
		sn.init_socket(mem.socket);
	}

	template<typename T1, typename T2,
			typename T3, typename T4,
			typename T5,
			typename T6, typename T7>
	void connect(T1& clk, T2& resetn,
			T3& rn, T4& tlm2chi_b,
			T5& signals,
			T6& chi2tlm_b, T7& port_RN_F)
	{
		// Connect clk
		tlm2chi_b.clk(clk);
		chi2tlm_b.clk(clk);

		// Connect reset
		tlm2chi_b.resetn(resetn);
		chi2tlm_b.resetn(resetn);

		// Connect RN-F signals
		signals.connectRNF(&tlm2chi_b);

		// Connect ICN signals
		signals.connectICN(&chi2tlm_b);

		// Connect tlm2chi bridge on the RN
		rn.connect(tlm2chi_b);

		// Connect chi2tlm bridge to the interconnect port
		port_RN_F.connect(chi2tlm_b);
	}

	TGDoneCallBack m_tgDoneCB;
	sc_event tgDone;
};

int sc_main(int argc, char *argv[])
{
	Verilated::commandArgs(argc, argv);
	Top top("Top", tgDoneCallBack);
	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, top.clk, top.clk.name());
	sc_trace(trace_fp, top.rst_n, top.rst_n.name());
	sc_trace(trace_fp, top.irq_out, top.irq_out.name());
	sc_trace(trace_fp, top.irq_ack, top.irq_ack.name());
	sc_trace(trace_fp, top.CHI_SYSCOREQ, top.CHI_SYSCOREQ.name());
	sc_trace(trace_fp, top.CHI_SYSCOACK, top.CHI_SYSCOACK.name());

	top.al_signals_rn.Trace(trace_fp);
	top.al_signals_hn.Trace(trace_fp);

	top.signals_chi_dut.Trace(trace_fp);
	top.signals1.Trace(trace_fp);

#if VM_TRACE
        Verilated::traceEverOn(true);
        // If verilator was invoked with --trace argument,
        // and if at run time passed the +trace argument, turn on tracing
        VerilatedVcdSc* tfp = NULL;
        const char* flag = Verilated::commandArgsPlusMatch("trace");
        if (flag && 0 == strcmp(flag, "+trace")) {
                tfp = new VerilatedVcdSc;
                top.dut_rn.trace(tfp, 99);
                top.dut_hn.trace(tfp, 99);
                tfp->open("vlt_dump.vcd");
        }
#endif
	tgDone = &top.tgDone;

	// Reset is active low. Emit a reset cycle.
	top.rst_n.write(false);
	sc_start(4, SC_US);
	top.rst_n.write(true);

	sc_start();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
#if VM_TRACE
        if (tfp) { tfp->close(); tfp = NULL; }
#endif
	return 0;
}
