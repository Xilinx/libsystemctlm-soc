/*
 * This is a small example showing howto connect an RTL AXI Device
 * to a SystemC/TLM simulation using the TLM-2-AXI bridges.
 *
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Edgar E. Iglesias
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

#include "tlm-modules/tlm-splitter.h"
#include "tlm-bridges/tlm2axi-bridge.h"
#include "tlm-bridges/tlm2axilite-bridge.h"
#include "tlm-bridges/tlm2native-bridge.h"
#include "tlm-bridges/axi2tlm-bridge.h"
#include "rtl-bridges/pcie-host/axi/tlm/axi2tlm-hw-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/random-traffic.h"
#include "checkers/pc-axi.h"
#include "checkers/pc-axilite.h"

#include "test-modules/memory.h"
#include "test-modules/signals-axi.h"
#include "test-modules/signals-axilite.h"
#include "test-modules/utils.h"

#include "trace/trace.h"

#include <verilated_vcd_sc.h>
#include "Vaxi3_slave.h"
#include "Vaxi4_slave.h"
#include "Vaxi4lite_slave.h"
#include "verilated.h"

#define basename buggy

#ifdef __AXI_VERSION_AXI3__
#define AXI_VERSION V_AXI3
#define DUT_SW_BRIDGE_DECL tlm2axi_bridge<64, 128, 16, 4, 2, 0, 0, 0, 0, 0 >
#define DUT_HW_BRIDGE_TYPE Vaxi3_slave
#define DUT_SIGNALS_DECL   AXISignals<64, 128, 16, 4, 2, 0, 0, 0, 0, 0 >
#define DUT_CHECKER_DECL   AXIProtocolChecker<64, 128, 16, 4, 2, 0, 0, 0, 0, 0 >

#elif defined(__AXI_VERSION_AXILITE__)
#define AXI_VERSION V_AXI4LITE
#define DUT_SW_BRIDGE_DECL tlm2axilite_bridge<64, 64 >
#define DUT_HW_BRIDGE_TYPE Vaxi4lite_slave
#define DUT_SIGNALS_DECL   AXILiteSignals<64, 64 >
#define DUT_CHECKER_DECL   AXILiteProtocolChecker<64, 64 >

#else
#define AXI_VERSION V_AXI4
#define DUT_SW_BRIDGE_DECL tlm2axi_bridge<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 >
#define DUT_HW_BRIDGE_TYPE Vaxi4_slave
#define DUT_SIGNALS_DECL   AXISignals<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 >
#define DUT_CHECKER_DECL   AXIProtocolChecker<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 >
#endif

using namespace utils;

// Top simulation module.
SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst; // Active high.
	sc_signal<bool> rst_n; // Active low.

	AXILiteSignals<64, 32 > signals_host;
	AXISignals<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > signals_host_dma;
	DUT_SIGNALS_DECL signals_dut;

	sc_signal<sc_bv<128> > signals_h2c_intr_out;
	sc_signal<sc_bv<64> > signals_c2h_intr_in;
	sc_signal<sc_bv<256> > signals_c2h_gpio_in;
	sc_signal<sc_bv<256> > signals_h2c_gpio_out;
	sc_signal<sc_bv<64> > signals_h2c_pulse_out;
	sc_signal<sc_bv<4> > signals_usr_resetn;
	sc_signal<bool> signals_irq_out;
	sc_signal<bool> signals_irq_ack;

	tlm2axilite_bridge<64, 32 > bridge_tlm2axilite;
	DUT_SW_BRIDGE_DECL bridge_dut;
	axi2tlm_bridge<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > bridge_axi2tlm_dma;
	tlm2native_bridge bridge_tlm2native_dma;

	AXILiteProtocolChecker<64, 32  > checker_axilite;
	DUT_CHECKER_DECL checker_dut;

	axi2tlm_hw_bridge tlm_hw_bridge;
	DUT_HW_BRIDGE_TYPE rtl_hw_bridge;

	RandomTraffic rand_xfers;
	RandomTraffic rand_xfers_al;
	tlm_splitter<2> splitter;
	TLMTrafficGenerator tg;

	memory ram;
	memory ref_ram;

	void gen_rst_n(void) {
		rst_n.write(!rst.read());
	}

#ifdef __AXI_VERSION_AXILITE__
	AXILitePCConfig checker_axi_config() {
		AXILitePCConfig cfg;
#else
	AXIPCConfig checker_axi_config() {
		AXIPCConfig cfg(AXI_VERSION);
#endif
		cfg.enable_all_checks();
		// The SW/HW interaction takes too long and our
		// protocol-checkers detect handshake errors.
		cfg.check_axi_handshakes(false);
		return cfg;
	}

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name, unsigned int ram_size = 8 * 1024) :
		clk("clk", sc_time(10, SC_NS)),
		rst("rst"),
		rst_n("rst_n"),
		signals_host("signals_host"),
		signals_host_dma("signals_host_dma"),
		signals_dut("signals_dut", AXI_VERSION),
		signals_h2c_intr_out("h2c_intr_out"),
		signals_c2h_intr_in("c2h_intr_in"),
		signals_c2h_gpio_in("c2h_gpio_in"),
		signals_h2c_gpio_out("h2c_gpio_out"),
		signals_h2c_pulse_out("h2c_pulse_out"),
		signals_usr_resetn("signals_usr_resetn"),
		signals_irq_out("signals_irq_out"),
		signals_irq_ack("signals_irq_ack"),
		bridge_tlm2axilite("bridge_tlm2axilite"),
#ifdef __AXI_VERSION_AXI3__
		bridge_dut("bridge_dut", V_AXI3),
#else
		bridge_dut("bridge_dut"),
#endif
		bridge_axi2tlm_dma("bridge_axi2tlm_dma"),
		bridge_tlm2native_dma("bridge_tlm2native_dma"),
		checker_axilite("checker_axilite",
				AXILitePCConfig::all_enabled()),
		checker_dut("checker_dut", checker_axi_config()),
		tlm_hw_bridge("tlm_hw_bridge", 0, 0, NULL),
		rtl_hw_bridge("rtl_hw_bridge"),
		rand_xfers(0, ram_size - 4, UINT64_MAX, 1, ram_size, ram_size, 200000, 1),
		rand_xfers_al(0, ram_size - 8, UINT64_MAX & (~7), 8, 8, 8, 200000, 1),
		splitter("splitter", true),
		tg("tg", 2),
		ram("ram", SC_ZERO_TIME, ram_size),
		ref_ram("ref_ram", SC_ZERO_TIME, ram_size)
	{

		SC_METHOD(gen_rst_n);
		sensitive << rst;

		// Wire up the clock and reset signals.
		bridge_tlm2axilite.clk(clk);
		bridge_tlm2axilite.resetn(rst_n);
		bridge_dut.clk(clk);
		bridge_dut.resetn(rst_n);
		bridge_axi2tlm_dma.clk(clk);
		bridge_axi2tlm_dma.resetn(rst_n);
		checker_axilite.clk(clk);
		checker_axilite.resetn(rst_n);
		checker_dut.clk(clk);
		checker_dut.resetn(rst_n);
		rtl_hw_bridge.axi_aclk(clk);
		rtl_hw_bridge.axi_aresetn(rst_n);
		tlm_hw_bridge.rst(rst);

		rand_xfers.setMaxStreamingWidthLen(ram_size);

		tg.enableDebug();
#if defined(__AXI_VERSION_AXILITE__)
		tg.addTransfers(rand_xfers_al, 0);
#else
		tg.addTransfers(rand_xfers, 0);
#endif
		tg.setStartDelay(sc_time(15, SC_US));

		tg.socket.bind(splitter.target_socket);
		splitter.i_sk[0]->bind(ref_ram.socket);
		splitter.i_sk[1]->bind(bridge_dut.tgt_socket);

		tlm_hw_bridge.bridge_socket(bridge_tlm2axilite.tgt_socket);
		tlm_hw_bridge.init_socket(ram.socket);
		tlm_hw_bridge.irq(signals_irq_out);

		// Wire-up the bridge and checker.
		signals_host.connect(bridge_tlm2axilite);
		signals_host.connect(checker_axilite);
		signals_host.connect(rtl_hw_bridge, "s_axi_");
		signals_host_dma.connect(rtl_hw_bridge, "m_axi_");
		signals_host_dma.connect(bridge_axi2tlm_dma);

		bridge_axi2tlm_dma.socket(bridge_tlm2native_dma.target_socket);

		signals_dut.connect(rtl_hw_bridge, "s_axi_usr_");
		signals_dut.connect(bridge_dut);
		signals_dut.connect(checker_dut);

		rtl_hw_bridge.h2c_intr_out(signals_h2c_intr_out);
		rtl_hw_bridge.c2h_intr_in(signals_c2h_intr_in);
		rtl_hw_bridge.c2h_gpio_in(signals_c2h_gpio_in);
		rtl_hw_bridge.h2c_gpio_out(signals_h2c_gpio_out);
		rtl_hw_bridge.h2c_pulse_out(signals_h2c_pulse_out);

		rtl_hw_bridge.irq_out(signals_irq_out);
		rtl_hw_bridge.irq_ack(signals_irq_ack);
		signals_irq_ack.write(1);

		rtl_hw_bridge.usr_resetn(signals_usr_resetn);
	}
};

int sc_main(int argc, char *argv[])
{
	Verilated::commandArgs(argc, argv);
	Top top("Top");

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	trace(trace_fp, top, "top");
	top.signals_host.Trace(trace_fp);
	top.signals_dut.Trace(trace_fp);

#if VM_TRACE
	Verilated::traceEverOn(true);
	// If verilator was invoked with --trace argument,
	// and if at run time passed the +trace argument, turn on tracing
	VerilatedVcdSc* tfp = NULL;
	const char* flag = Verilated::commandArgsPlusMatch("trace");
	if (flag && 0 == strcmp(flag, "+trace")) {
		tfp = new VerilatedVcdSc;
		top.rtl_hw_bridge.trace(tfp, 99);
		tfp->open("vlt_dump.vcd");
	}
#endif

	// Reset is active high. Emit a reset cycle.
	top.rst.write(true);
	sc_start(4, SC_US);
	top.rst.write(false);

	sc_start(2, SC_MS);

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
#if VM_TRACE
	if (tfp) { tfp->close(); tfp = NULL; }
#endif
	return 0;
}
