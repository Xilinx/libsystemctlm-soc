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
#include "tlm-bridges/umi2tlm-bridge.h"
#include "tlm-modules/tlm-splitter.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/random-traffic.h"

#include "test-modules/signals-umi.h"
#include "test-modules/memory.h"
#include "trace/trace.h"

#define RAM_SIZE (64 * 1024)
#ifndef DW
#define DW 256
#endif

SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst;

	TLMTrafficGenerator tg;
	UMISignals<DW> signals_req;
	UMISignals<DW> signals_resp;
	tlm2umi_bridge<DW> tlm2umi;
	umi2tlm_bridge<DW> umi2tlm;
	tlm_splitter<2> splitter;
	memory mem;
	memory ref_mem;
	RandomTraffic transfers;

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
		tlm2umi("tlm2umi"),
		umi2tlm("umi2tlm"),
		splitter("splitter", true),
		mem("mem", sc_time(10, SC_NS), RAM_SIZE),
		ref_mem("ref_mem", sc_time(10, SC_NS), RAM_SIZE),
		transfers(0, RAM_SIZE - DW/8, (~(DW/8 - 1)), 1, DW/8, 0, 2 * 1024)
	{
		SC_THREAD(do_reset);

		// Configure the Traffic generator.
		transfers.setMaxStreamingWidthLen(0);
		tg.setStartDelay(sc_time(8, SC_US));
		tg.enableDebug();
		tg.addTransfers(transfers);
		tg.socket.bind(splitter.target_socket);

		// Wire up the clock and reset signals.
		tlm2umi.clk(clk);
		tlm2umi.rst(rst);
		umi2tlm.clk(clk);
		umi2tlm.rst(rst);

		// Wire-up the bridges.
		signals_req.connect(tlm2umi, "req_");
		signals_resp.connect(tlm2umi, "resp_");
		signals_req.connect(umi2tlm, "req_");
		signals_resp.connect(umi2tlm, "resp_");

		// Splitter
		splitter.i_sk[1]->bind(tlm2umi.socket);
		umi2tlm.socket.bind(mem.socket);
		splitter.i_sk[0]->bind(ref_mem.socket);
	}
};

int sc_main(int argc, char *argv[])
{
	Top top("Top");

	// You must do one evaluation before enabling waves, in order to allow
	// SystemC to interconnect everything for testing.
	sc_start(SC_ZERO_TIME);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);
	trace(trace_fp, top, "top");

	sc_start(10, SC_MS);
	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
	return 0;
}
