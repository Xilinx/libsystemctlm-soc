/*
 * Copyright (c) 2018 Xilinx Inc.
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

#include <sstream>
#include <string>
#include <vector>
#include <array>

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "tlm-bridges/tlm2axi-bridge.h"
#include "tlm-bridges/axi2tlm-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "checkers/pc-axi.h"
#include "test-modules/memory.h"
#include "test-modules/signals-axi.h"
#include "test-modules/utils.h"
#include "siggen-axi.h"

using namespace utils;

#ifdef __AXI_VERSION_AXI3__
static const AXIVersion version = V_AXI3;
#else
static const AXIVersion version = V_AXI4;
#endif

#define AXI_ADDR_WIDTH 32
#define AXI_DATA_WIDTH 32

SIGGEN_TESTSUITE(TestSuite)
{
	SIGGEN_TESTSUITE_CTOR(TestSuite)
	{}

	void run_tests()
	{
		TESTCASE(test_rd_order);
		TESTCASE_NEG(test_rd_order_with_wrong_order);
		TESTCASE_NEG(test_rd_order_with_unexpected_tx_id);
	}

	void test_rd_order()
	{
		// id 1
		arid.write(1);
		arlen.write(0);
		arvalid.write(true);
		arready.write(true);

		sc_core::wait(clk.posedge_event());

		// id, second tx
		arid.write(1);
		arlen.write(0);
		arvalid.write(true);
		arready.write(true);

		// response 1
		rid.write(1);
		rvalid.write(true);
		rready.write(true);
		rlast.write(true);

		sc_core::wait(clk.posedge_event());

		// end
		arvalid.write(false);
		arready.write(false);

		// response 2
		rid.write(1);
		rvalid.write(true);
		rready.write(true);
		rlast.write(true);

		sc_core::wait(clk.posedge_event());

		rvalid.write(false);
		rready.write(false);
		rlast.write(false);

		sc_core::wait(clk.posedge_event());
	}

	void test_rd_order_with_wrong_order()
	{
		// id 1
		arid.write(1);
		arlen.write(1); // 2 bursts
		arvalid.write(true);
		arready.write(true);

		sc_core::wait(clk.posedge_event());

		// id, second tx
		arid.write(1);
		arlen.write(0);
		arvalid.write(true);
		arready.write(true);

		// response 1
		rid.write(1);
		rvalid.write(true);
		rready.write(true);
		rlast.write(true);  // Unexpected burst length

		sc_core::wait(clk.posedge_event());
	}

	void test_rd_order_with_unexpected_tx_id()
	{
		// id 1
		arvalid.write(false);
		arready.write(false);

		// response 1
		rid.write(2);		// Unexpected id
		rvalid.write(true);
		rready.write(true);
		rlast.write(false);

		sc_core::wait(clk.posedge_event());

		// end
		rvalid.write(false);
		rready.write(false);
		rlast.write(false);

		sc_core::wait(clk.posedge_event());
	}
};

SIGGEN_RUN(TestSuite)

AXIPCConfig checker_config()
{
	AXIPCConfig cfg(version);

	cfg.check_rd_tx_ordering();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	AXIProtocolChecker<AXI_ADDR_WIDTH, AXI_DATA_WIDTH> checker("checker",
								   checker_config());
	AXISignals<AXI_ADDR_WIDTH, AXI_DATA_WIDTH> signals("axi_signals", version);
	SignalGen<AXI_ADDR_WIDTH, AXI_DATA_WIDTH> siggen("sig_gen", version);
	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);

	siggen.SetMessageType(RD_TX_ERROR);

	// Connect clk
	checker.clk(clk);
	siggen.clk(clk);

	// Connect reset
	checker.resetn(resetn);
	siggen.resetn(resetn);

	// Connect signals
	signals.connect(checker);
	signals.connect(siggen);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, siggen.clk, siggen.clk.name());
	signals.Trace(trace_fp);

	// Run
	sc_start(100, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	return 0;
}
