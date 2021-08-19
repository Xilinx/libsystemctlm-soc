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

#include <verilated_vcd_sc.h>
#include "verilated.h"

#include "tlm-bridges/tlm2axilite-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "traffic-generators/random-traffic.h"
#include "checkers/pc-axilite.h"

#include "tlm-bridges/tlm2ace-bridge.h"
#include "tlm-bridges/ace2tlm-bridge.h"
#include "rtl-bridges/pcie-host/ace/tlm/ace2tlm-hw-bridge.h"

#include "checkers/pc-ace.h"

#include "test-modules/signals-axi.h"
#include "test-modules/signals-ace.h"
#include "test-modules/utils-ace.h"

#include "tlm-modules/master-ace.h"
#include "tlm-modules/iconnect-ace.h"

#include "test-modules/memory.h"
#include "test-modules/signals-axilite.h"
#include "test-modules/utils.h"
#include "test-modules/utils-ace.h"

#include "checkers/pc-ace.h"

#include "trace/trace.h"

#include "Vace_slv.h"

#define basename buggy
using namespace utils;
using namespace utils::ACE;

#define NUM_ACE_MASTERS 2
#define NUM_ACELITE_MASTERS 0
#define CACHELINE_SIZE 64

#define CACHE_SIZE (4 * CACHELINE_SIZE)

#define LINE(l) ((l) * CACHELINE_SIZE)

// Increase for more random traffic
#define NUM_TXNS_MSTR0 4
#define NUM_TXNS_MSTR1 20000

#define AXI_ADDR_WIDTH 64
#define AXI_DATA_WIDTH 128

typedef ACESignals<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	16,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	32,		// AWUSER_WIDTH
	32,		// ARUSER_WIDTH
	32,		// WUSER_WIDTH
	32,		// RUSER_WIDTH
	32,		// BUSER_WIDTH
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> ACESignals_t;

typedef tlm2ace_bridge<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	16,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	32,		// AWUSER_WIDTH
	32,		// ARUSER_WIDTH
	32,		// WUSER_WIDTH
	32,		// RUSER_WIDTH
	32,		// BUSER_WIDTH
	CACHELINE_SIZE,	// CACHELINE_SZ
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> tlm2ace_bridge_t;

typedef ace2tlm_bridge<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	16,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	32,		// AWUSER_WIDTH
	32,		// ARUSER_WIDTH
	32,		// WUSER_WIDTH
	32,		// RUSER_WIDTH
	32,		// BUSER_WIDTH
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> ace2tlm_bridge_t;

typedef ACEProtocolChecker<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	16,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	32,		// AWUSER_WIDTH
	32,		// ARUSER_WIDTH
	32,		// WUSER_WIDTH
	32,		// RUSER_WIDTH
	32,		// BUSER_WIDTH
	CACHELINE_SIZE,	// CACHELINE_SZ
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> ACEChecker;

typedef ACEMaster<
	CACHE_SIZE,
	CACHELINE_SIZE
> ACEMaster_t;

typedef iconnect_ace<
	NUM_ACE_MASTERS,
	NUM_ACELITE_MASTERS,
	CACHELINE_SIZE
> iconnect_ace_t;

typedef TLMTrafficGenerator::DoneCallback TGDoneCallBack;

static const unsigned char dummy_data[CACHELINE_SIZE] = { 0 };
static const unsigned char burst_data[140] = {
	0x11, 0x12, 0x13, 0x14, 0x21, 0x22, 0x23, 0x24,
	0x21, 0x22, 0x23, 0x24, 0x31, 0x32, 0x33, 0x34,
	0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x43, 0x44,
	0x41, 0x42, 0x43, 0x44, 0x51, 0x52, 0x53, 0x54
};

sc_trace_file* m_trace_fp = NULL;
VerilatedVcdSc* m_tfp = NULL;
sc_event* tgDone;

void tgDoneCallBack(TLMTrafficGenerator *gen, int threadID)
{
	tgDone->notify();
}

static void error_handler(const sc_report& rep, const sc_actions& ac)
{
	if (rep.get_severity() == SC_ERROR) {

		if (m_trace_fp) {
			sc_close_vcd_trace_file(m_trace_fp);
			m_trace_fp = NULL;
		}
		if (m_tfp) {
			m_tfp->close();
			m_tfp = NULL;
		}
	}

	sc_report_handler::default_handler(rep, ac);
}

TrafficDesc xfers(merge({

	// Round 1

	// Cacheline 1
	Write(LINE(1), DATA(0xFF, 0xFF, 0xFF, 0xFF)),

	// Cacheline 2
	Write(LINE(2), DATA(0xFF, 0xFF, 0xFF, 0xFF)),

	// Cacheline 3
	Write(LINE(3), DATA(0xFF, 0xFF, 0xFF, 0xFF)),

	// Cacheline 0
	Write(0, DATA(0xFF, 0xFF, 0xFF, 0xFF)),

	// Round 2

	// Cacheline 1
	Write(LINE(1), DATA(0x1, 0x1, 0x1, 0x1)),

	// Cacheline 2
	Write(LINE(2), DATA(0x1, 0x1, 0x1, 0x1)),

	// Cacheline 3
	Write(LINE(3), DATA(0x1, 0x1, 0x1, 0x1)),

	// Cacheline 0
	Write(LINE(0), DATA(0x1, 0x1, 0x1, 0x1)),

	// Multiple lines starting from cacheline 4
	Write(LINE(4), burst_data, sizeof(burst_data)),

	// Test barrier
	ReadBarrier(), WriteBarrier(),

	// Test DVM branch predictor invalidate message
	DVMMessage(DVM_CMD(DVM::CmdBranchPredictorInv)),

	// Test DVM Sync message
	DVMMessage(DVM_CMD(DVM::CmdSync) | DVM::CompletionBit),

	// Test cache maintenance operations,
	CleanShared(LINE(0), dummy_data, sizeof(dummy_data)),
	CleanInvalid(LINE(0), dummy_data, sizeof(dummy_data)),
	MakeInvalid(LINE(0), dummy_data, sizeof(dummy_data)),

	// Exclusive load store sequence
	ExclusiveLoad(0),
	ExclusiveStore(0, DATA(0x0, 0x0, 0x0, 0x1), 4),
	Read(0),
		Expect(DATA(0x0, 0x0, 0x0, 0x1), 4),
}));

// Top simulation module.
SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst; // Active high.
	sc_signal<bool> rst_n; // Active low.

	AXILiteSignals<64, 32 > signals_host;
	ACESignals_t signals_ace_dut;
	ACESignals_t signals_m1;

	AXISignals<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > signals_host_dma;

	sc_signal<sc_bv<128> > signals_h2c_intr_out;
	sc_signal<sc_bv<256> > signals_h2c_gpio_out;
	sc_signal<sc_bv<64> > signals_c2h_intr_in;
	sc_signal<sc_bv<256> > signals_c2h_gpio_in;
	sc_signal<sc_bv<4> > signals_usr_resetn;
	sc_signal<bool> signals_irq_out;
	sc_signal<bool> signals_irq_ack;
	sc_signal<bool> signals_awunique;

	RandomTraffic rand_xfers0;
	RandomTraffic rand_xfers1;

	tlm2axilite_bridge<64, 32 > bridge_tlm2axilite;
        AXILiteProtocolChecker<64, 32  > checker_axilite;

	ACEMaster_t m0;
	ACEMaster_t m1;

	tlm2ace_bridge_t t2a_bridge0;
	tlm2ace_bridge_t t2a_bridge1;
	ace2tlm_bridge_t a2t_bridge1;

	ace2tlm_hw_bridge<> a2t_hw_bridge0;
	iconnect_ace_t iconnect;

	Vace_slv dut;

	memory ram;

	void gen_rst_n(void) {
		rst_n.write(!rst.read());
	}

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name,
		TrafficDesc &xfers,
		TGDoneCallBack tgDoneCB,
		unsigned int ram_size = 8 * 1024) :

		clk("clk", sc_time(10, SC_US)),
		rst("rst"),
		rst_n("rst_n"),

		signals_host("signals_host"),
		signals_ace_dut("ace_signals_dut"),
		signals_m1("ace_signals_m1"),

		signals_host_dma("signals_host_dma"),

		signals_h2c_intr_out("c2h_intr_out"),
		signals_h2c_gpio_out("h2c_gpio_out"),
		signals_c2h_intr_in("c2h_intr_in"),
		signals_c2h_gpio_in("c2h_gpio_in"),
		signals_usr_resetn("signals_usr_resetn"),
		signals_irq_out("signals_irq_out"),
		signals_irq_ack("signals_irq_ack"),

                rand_xfers0(0, ram_size - 4, UINT64_MAX,
				1, ram_size, ram_size, NUM_TXNS_MSTR0),
                rand_xfers1(0, ram_size - 4, UINT64_MAX,
				1, ram_size, ram_size, NUM_TXNS_MSTR1),

		bridge_tlm2axilite("bridge_tlm2axilite"),
		checker_axilite("checker_axilite",
				AXILitePCConfig::all_enabled()),

		m0("ace_master0"),
		m1("ace_master1", rand_xfers1),

		t2a_bridge0("tlm2ace_bridge0"),
		t2a_bridge1("tlm2ace_bridge1"),

		a2t_bridge1("ace2tlm_bridge1"),

		a2t_hw_bridge0("ace2tlm_hw_bridge0"),
		iconnect("ace_iconnect"),

		dut("dut"),

		ram("ram", SC_ZERO_TIME, ram_size),

		m_tgDoneCB(tgDoneCB)
	{
		SC_METHOD(gen_rst_n);
		sensitive << rst;

		//
		// Wire up the clock and reset signals.
		//
		bridge_tlm2axilite.clk(clk);
		bridge_tlm2axilite.resetn(rst_n);

		checker_axilite.clk(clk);
		checker_axilite.resetn(rst_n);

		t2a_bridge0.clk(clk);
		t2a_bridge0.resetn(rst_n);

		a2t_hw_bridge0.clk(clk);
		a2t_hw_bridge0.resetn(rst_n);

		dut.clk(clk);
		dut.resetn(rst_n);

		//
		// Setup ACE master 0
		//
		m0.GetTrafficGenerator().addTransfers(xfers, 0, m_tgDoneCB);
		m0.connect(t2a_bridge0);
		m0.GetTrafficGenerator().setStartDelay(sc_time(400, SC_US));
		m0.enableDebug();

		//
		// Setup ACE master 1
		//
		m1.GetTrafficGenerator().setStartDelay(sc_time(400, SC_US));

		//
		// ACE signals dut
		//
		signals_ace_dut.connect(&t2a_bridge0);
		connect_ace_signals_dut();

		//
		// Connect ACE master 1
		//
		connect(clk, rst_n,
			m1, t2a_bridge1,
			signals_m1,
			a2t_bridge1, *iconnect.s_ace_port[1]);
		iconnect.s_ace_port[1]->SetForwardDVM(true);

		//
		// AXI4Lite signals
		//
		// Connect hw bridge <-> dut
		//
		a2t_hw_bridge0.bridge_socket(bridge_tlm2axilite.tgt_socket);
		signals_host.connect(bridge_tlm2axilite);
		signals_host.connect(checker_axilite);
		connect_axilite_dut();

		//
		// Connect a2t_hw_bridge <-> interconnect
		//
		iconnect.s_ace_port[0]->connect_master(a2t_hw_bridge0);
		iconnect.s_ace_port[0]->SetForwardDVM(true);

		//
		// Connect iconnect <-> Ram
		//
		iconnect.ds_port.connect_slave(ram);

		//
		// AXI4 dut Master (mode 1)
		//
		signals_host_dma.connect(dut, "m_axi_");

		//
		// Other signals
		//
		dut.c2h_gpio_in(signals_c2h_gpio_in);
		dut.h2c_intr_out(signals_h2c_intr_out);
		dut.h2c_gpio_out(signals_h2c_gpio_out);
		dut.c2h_intr_in(signals_c2h_intr_in);
		dut.irq_out(signals_irq_out);
		dut.irq_ack(signals_irq_ack);
		dut.usr_resetn(signals_usr_resetn);
		signals_usr_resetn.write(true);

		a2t_hw_bridge0.irq(signals_irq_out);

		signals_irq_ack.write(1);

		SC_THREAD(tgDone_thread);
	}

	template<typename T1, typename T2,
			typename T3, typename T4,
			typename T5,
			typename T6, typename T7>
	void connect(T1& clk, T2& resetn,
			T3& master, T4& tlm2ace_b,
			T5& signals,
			T6& ace2tlm_b, T7& s_ace_port)
	{
		// Connect clk
		tlm2ace_b.clk(clk);
		ace2tlm_b.clk(clk);

		// Connect reset
		tlm2ace_b.resetn(resetn);
		ace2tlm_b.resetn(resetn);

		// Connect signals
		signals.connect(&tlm2ace_b);
		signals.connect(&ace2tlm_b);

		// Connect tlm2ace bridge on the master
		master.connect(tlm2ace_b);

		// Connect ace2tlm bridge to the interconnect slave ace port
		s_ace_port.connect_master(ace2tlm_b);
	}

	void tgDone_thread()
	{
		while (true) {
			wait(tgDone);

			if (!rand_xfers0.done()) {
				//
				// Generate random traffic
				//
				m0.GetTrafficGenerator().addTransfers(
					rand_xfers0,0, m_tgDoneCB);
			} else {
				sc_stop();
			}
		}
	}

	void connect_axilite_dut()
	{
		dut.s_axi_awvalid(signals_host.awvalid);
		dut.s_axi_awready(signals_host.awready);
		dut.s_axi_awaddr(signals_host.awaddr);
		dut.s_axi_awprot(signals_host.awprot);

		dut.s_axi_arvalid(signals_host.arvalid);
		dut.s_axi_arready(signals_host.arready);
		dut.s_axi_araddr(signals_host.araddr);
		dut.s_axi_arprot(signals_host.arprot);

		dut.s_axi_wvalid(signals_host.wvalid);
		dut.s_axi_wready(signals_host.wready);
		dut.s_axi_wdata(signals_host.wdata);
		dut.s_axi_wstrb(signals_host.wstrb);

		dut.s_axi_bvalid(signals_host.bvalid);
		dut.s_axi_bready(signals_host.bready);
		dut.s_axi_bresp(signals_host.bresp);

		dut.s_axi_rvalid(signals_host.rvalid);
		dut.s_axi_rready(signals_host.rready);
		dut.s_axi_rdata(signals_host.rdata);
		dut.s_axi_rresp(signals_host.rresp);
	}

	void connect_ace_signals_dut()
	{
		dut.s_ace_usr_awvalid(signals_ace_dut.awvalid);
		dut.s_ace_usr_awready(signals_ace_dut.awready);
		dut.s_ace_usr_awaddr(signals_ace_dut.awaddr);
		dut.s_ace_usr_awprot(signals_ace_dut.awprot);
		dut.s_ace_usr_awuser(signals_ace_dut.awuser);
		dut.s_ace_usr_awregion(signals_ace_dut.awregion);
		dut.s_ace_usr_awqos(signals_ace_dut.awqos);
		dut.s_ace_usr_awcache(signals_ace_dut.awcache);
		dut.s_ace_usr_awburst(signals_ace_dut.awburst);
		dut.s_ace_usr_awsize(signals_ace_dut.awsize);
		dut.s_ace_usr_awlen(signals_ace_dut.awlen);
		dut.s_ace_usr_awid(signals_ace_dut.awid);
		dut.s_ace_usr_awlock(signals_ace_dut.awlock);

		/* Write data channel.  */
		dut.s_ace_usr_wvalid(signals_ace_dut.wvalid);
		dut.s_ace_usr_wready(signals_ace_dut.wready);
		dut.s_ace_usr_wdata(signals_ace_dut.wdata);
		dut.s_ace_usr_wstrb(signals_ace_dut.wstrb);
		dut.s_ace_usr_wuser(signals_ace_dut.wuser);
		dut.s_ace_usr_wlast(signals_ace_dut.wlast);

		/* Write response channel.  */
		dut.s_ace_usr_bvalid(signals_ace_dut.bvalid);
		dut.s_ace_usr_bready(signals_ace_dut.bready);
		dut.s_ace_usr_bresp(signals_ace_dut.bresp);
		dut.s_ace_usr_buser(signals_ace_dut.buser);
		dut.s_ace_usr_bid(signals_ace_dut.bid);

		/* Read address channel.  */
		dut.s_ace_usr_arvalid(signals_ace_dut.arvalid);
		dut.s_ace_usr_arready(signals_ace_dut.arready);
		dut.s_ace_usr_araddr(signals_ace_dut.araddr);
		dut.s_ace_usr_arprot(signals_ace_dut.arprot);
		dut.s_ace_usr_aruser(signals_ace_dut.aruser);
		dut.s_ace_usr_arregion(signals_ace_dut.arregion);
		dut.s_ace_usr_arqos(signals_ace_dut.arqos);
		dut.s_ace_usr_arcache(signals_ace_dut.arcache);
		dut.s_ace_usr_arburst(signals_ace_dut.arburst);
		dut.s_ace_usr_arsize(signals_ace_dut.arsize);
		dut.s_ace_usr_arlen(signals_ace_dut.arlen);
		dut.s_ace_usr_arid(signals_ace_dut.arid);
		dut.s_ace_usr_arlock(signals_ace_dut.arlock);

		/* Read data channel.  */
		dut.s_ace_usr_rvalid(signals_ace_dut.rvalid);
		dut.s_ace_usr_rready(signals_ace_dut.rready);
		dut.s_ace_usr_rdata(signals_ace_dut.rdata);
		dut.s_ace_usr_rresp(signals_ace_dut.rresp);
		dut.s_ace_usr_ruser(signals_ace_dut.ruser);
		dut.s_ace_usr_rid(signals_ace_dut.rid);
		dut.s_ace_usr_rlast(signals_ace_dut.rlast);

		// AXI4 signals
		dut.s_ace_usr_awsnoop(signals_ace_dut.awsnoop);
		dut.s_ace_usr_awdomain(signals_ace_dut.awdomain);
		dut.s_ace_usr_awbar(signals_ace_dut.awbar);

		dut.s_ace_usr_wack(signals_ace_dut.wack);

		dut.s_ace_usr_arsnoop(signals_ace_dut.arsnoop);
		dut.s_ace_usr_ardomain(signals_ace_dut.ardomain);
		dut.s_ace_usr_arbar(signals_ace_dut.arbar);

		dut.s_ace_usr_rack(signals_ace_dut.rack);

		// Snoop address channel
		dut.s_ace_usr_acvalid(signals_ace_dut.acvalid);
		dut.s_ace_usr_acready(signals_ace_dut.acready);
		dut.s_ace_usr_acaddr(signals_ace_dut.acaddr);
		dut.s_ace_usr_acsnoop(signals_ace_dut.acsnoop);
		dut.s_ace_usr_acprot(signals_ace_dut.acprot);

		// Snoop response channel
		dut.s_ace_usr_crvalid(signals_ace_dut.crvalid);
		dut.s_ace_usr_crready(signals_ace_dut.crready);
		dut.s_ace_usr_crresp(signals_ace_dut.crresp);

		// Snoop data channel
		dut.s_ace_usr_cdvalid(signals_ace_dut.cdvalid);
		dut.s_ace_usr_cdready(signals_ace_dut.cdready);
		dut.s_ace_usr_cddata(signals_ace_dut.cddata);
		dut.s_ace_usr_cdlast(signals_ace_dut.cdlast);

		dut.s_ace_usr_awunique(signals_awunique);
	}

	TGDoneCallBack m_tgDoneCB;
	sc_event tgDone;
};

int sc_main(int argc, char *argv[])
{
	Verilated::commandArgs(argc, argv);
	Top top("Top", xfers, tgDoneCallBack);
	sc_trace_file *trace_fp = NULL;

	trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, top.clk, top.clk.name());
	sc_trace(trace_fp, top.rst_n, top.rst_n.name());
	sc_trace(trace_fp, top.signals_irq_out, top.signals_irq_out.name());
	sc_trace(trace_fp, top.signals_irq_ack, top.signals_irq_ack.name());
	top.signals_host.Trace(trace_fp);
	top.signals_ace_dut.Trace(trace_fp);
	top.signals_m1.Trace(trace_fp);

#if VM_TRACE
        Verilated::traceEverOn(true);
        // If verilator was invoked with --trace argument,
        // and if at run time passed the +trace argument, turn on tracing
        VerilatedVcdSc* tfp = NULL;
        const char* flag = Verilated::commandArgsPlusMatch("trace");
        if (flag && 0 == strcmp(flag, "+trace")) {
                tfp = new VerilatedVcdSc;
                top.dut.trace(tfp, 99);
                tfp->open("vlt_dump.vcd");
        }
#endif
	tgDone = &top.tgDone;

	sc_report_handler::set_handler(error_handler);
	m_trace_fp = trace_fp;
	m_tfp = tfp;

	// Reset is active high. Emit a reset cycle.
	top.rst.write(true);
	sc_start(4, SC_US);
	top.rst.write(false);

	sc_start();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
#if VM_TRACE
        if (tfp) { tfp->close(); tfp = NULL; }
#endif
	return 0;
}
