/*
 * This is a small example showing howto connect an RTL AXI4Lite Device
 * to a SystemC/TLM simulation using the TLM-2-AXI4Lite bridge.
 *
 * Copyright (c) 2018 Xilinx Inc.
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

#include "tlm-bridges/tlm2axilite-bridge.h"
#include "checkers/pc-axilite.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"

#include "test-modules/signals-axilite.h"
#include "test-modules/utils.h"

#include <verilated.h>
#include "Vaxilite_dev_dpi.h"

using namespace utils;

#define CONNECT_DUT(DUT, SIGS, SIGNAME) DUT.s00_axi_ ## SIGNAME(SIGS.SIGNAME)

TrafficDesc transactions(merge({
	// Write something to address 8
        Write(8, DATA(0x1, 0x2, 0x3, 0x4)),
	// Read it back and check that we get the expected data.
        Read(8, 4),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4)
}));

AXILitePCConfig checker_config()
{
	AXILitePCConfig cfg;

	cfg.enable_all_checks();

	return cfg;
}

// Top simulation module.
SC_MODULE(Top)
{
	pthread_t thread;
	bool stop;

	// dut is the RTL AXI4Lite device we're testing.
	Vaxilite_dev_dpi dut;

	Top(sc_module_name name) :
		stop(false),
		dut("dut")
	{
	}
};

void *verilator_thread(void *arg)
{
	Top *top = (Top *) arg;
	int i;

	top->dut.resetn = 0;
	top->dut.clk = 0;

	for (i = 0; i < 2; i++) {
		top->dut.clk = !top->dut.clk;
		top->dut.eval();
	}
	top->dut.resetn = 1;

	while (!Verilated::gotFinish() && !top->stop) {
		top->dut.clk = !top->dut.clk;
		top->dut.eval();
	}
	return NULL;
}

int sc_main(int argc, char *argv[])
{
	Verilated::commandArgs(argc, argv);
	Top top("Top");

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	Verilated::traceEverOn(true);
	Verilated::mkdir("logs");

	pthread_create(&top.thread, NULL, verilator_thread, &top);

	while (1)
		sc_start(140, SC_US);

	top.stop = 1;
	pthread_join(top.thread, NULL);

	sc_stop();

	top.dut.final();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	return 0;
}
