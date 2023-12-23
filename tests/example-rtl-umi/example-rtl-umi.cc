/*
 * This is a small example showing howto connect an RTL UMI Device
 * to a SystemC/TLM simulation using the TLM-2-UMI bridge.
 *
 * Copyright (c) 2024 Zero ASIC.
 * Written by Edgar E. Iglesias
 *
 * SPDX-License-Identifier: MIT
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

#include "tlm-bridges/tlm2umi-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"

#include "test-modules/signals-umi.h"
#include "test-modules/utils.h"
#include "trace/trace.h"
#if VM_TRACE
#include <verilated_vcd_sc.h>
#endif

#include "Vumi_dev.h"

using namespace utils;

#define DW 64

#define CONNECT_DUT(DUT, SIGS, SIGNAME) DUT.s00_axi_ ## SIGNAME(SIGS.SIGNAME)

TrafficDesc transactions(merge({
	// Write something to address 8
        Write(8, DATA(0x1, 0x2, 0x3, 0x4)),
	// Read it back and check that we get the expected data.
        Read(8, 4),
	     Expect(DATA(0x1, 0x2, 0x3, 0x4), 4)
}));

// Top simulation module.
SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst;

	TLMTrafficGenerator tg;
	UMISignals<DW> signals_req;
	UMISignals<DW> signals_resp;
	tlm2umi_bridge<DW> bridge;
	Vumi_dev dut;

	void do_reset(void) {
		int i;

		rst.write(false);
		for (i = 0; i < 2; i++) {
			wait(clk.posedge_event());
		}
		rst.write(true);
		for (i = 0; i < 4; i++) {
			wait(clk.posedge_event());
		}
		rst.write(false);
	}

	SC_HAS_PROCESS(Top);
	Top(sc_module_name name) :
		clk("clk", sc_time(1, SC_US)),
		rst("rst"),
		tg("traffic_generator"),
		signals_req("signals_req"),
		signals_resp("signals_resp"),
		bridge("bridge"),
		dut("dut")
	{
		SC_THREAD(do_reset);

		// Configure the Traffic generator.
		tg.setStartDelay(sc_time(8, SC_US));
		tg.enableDebug();
		tg.addTransfers(transactions);
		tg.socket.bind(bridge.socket);

		// Wire up the clock and reset signals.
		bridge.clk(clk);
		bridge.rst(rst);
		dut.clk(clk);
		dut.rst(rst);

		// Wire-up the bridge and checker.
		signals_req.connect(bridge, "req_");
		signals_resp.connect(bridge, "resp_");
		signals_req.connect(dut, "udev_req_");
		signals_resp.connect(dut, "udev_resp_");
	}
};

int sc_main(int argc, char *argv[])
{
	Top top("Top");

#if VM_TRACE
	// Before any evaluation, need to know to calculate those signals only used for tracing
	Verilated::traceEverOn(true);
#endif

	Verilated::commandArgs(argc, argv);

	// You must do one evaluation before enabling waves, in order to allow
	// SystemC to interconnect everything for testing.
	sc_start(SC_ZERO_TIME);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);
	trace(trace_fp, top, "top");

#if VM_TRACE
	// General logfile
	ios::sync_with_stdio();

	// If verilator was invoked with --trace argument,
	// and if at run time passed the +trace argument, turn on tracing
	VerilatedVcdSc* tfp = nullptr;
	const char* flag = Verilated::commandArgsPlusMatch("trace");
	if (flag && 0 == std::strcmp(flag, "+trace")) {
		std::cout << "Enabling waves into logs/vlt_dump.vcd...\n";
		tfp = new VerilatedVcdSc;
		top.dut.trace(tfp, 99);  // Trace 99 levels of hierarchy
		Verilated::mkdir("logs");
		tfp->open("logs/vlt_dump.vcd");

		trace_fp = sc_create_vcd_trace_file(argv[0]);
		trace(trace_fp, top, "Top");
	}
#endif

	sc_start(140, SC_US);
	sc_stop();

#if VM_TRACE
	// Flush the wave files each cycle so we can immediately see the output
	// Don't do this in "real" programs, do it in an abort() handler instead
	if (tfp) tfp->flush();
#endif
	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
	return 0;
}
