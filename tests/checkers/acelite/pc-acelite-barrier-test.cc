/*
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

#include "traffic-generators/tg-tlm.h"
#include "checkers/pc-acelite.h"
#include "checkers/config-ace.h"
#include "test-modules/memory.h"
#include "test-modules/signals-acelite.h"
#include "siggen-acelite.h"

#define AXI_ADDR_WIDTH 64
#define AXI_DATA_WIDTH 64

typedef ACELiteSignals<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH	// DATA_WIDTH
> ACELiteSignals__;

SIGGEN_TESTSUITE(TestSuite)
{
	SIGGEN_TESTSUITE_CTOR(TestSuite)
	{}

	void run_tests()
	{
		SetMessageType(BARRIER_ERROR);

		TESTCASE(test_barrier);
		TESTCASE(test_barrier_outstanding);

		TESTCASE_NEG(test_barrier_wrong_write_barrier_sequence_error);
		TESTCASE_NEG(test_barrier_wrong_read_barrier_sequence_error);
	}

	void reset_toggle()
	{
		resetn.write(false);
		wait(clk.posedge_event());
		resetn.write(true);
		wait(clk.posedge_event());
	}

	void setup_ar_barrier(uint8_t id)
	{
		arsnoop.write(0);
		arbar.write(true);
		ardomain.write(Domain::Inner);
		arcache.write(2); // modifiable
		arsize.write(3); // 1 << 3 = 8 bytes
		arlen.write(0);
		araddr.write(0);
		arburst.write(AXI_BURST_INCR);
		arid.write(id);
	}

	void setup_aw_barrier(uint8_t id)
	{
		awsnoop.write(0);
		awbar.write(true);
		awdomain.write(Domain::Inner);
		awcache.write(2); // modifiable
		awsize.write(3); // 1 << 3 = 8 bytes
		awlen.write(0);
		awaddr.write(0);
		awburst.write(AXI_BURST_INCR);
		awid.write(id);
	}

	void do_write_barrier(uint8_t id = 0)
	{
		setup_aw_barrier(id);

		awvalid.write(true);
		awready.write(true);

		wait(clk.posedge_event());

		awvalid.write(false);
		awready.write(false);

		//
		// Response
		//
		bid.write(id);
		bvalid.write(true);
		bready.write(true);

		wait(clk.posedge_event());

		bid.write(0);
		bvalid.write(false);
		bready.write(false);

		wait(clk.posedge_event());
	}

	void do_read_barrier(uint8_t id = 0)
	{
		setup_ar_barrier(id);

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		arvalid.write(false);
		arready.write(false);

		//
		// Response
		//
		rid.write(id);
		rvalid.write(true);
		rready.write(true);

		wait(clk.posedge_event());

		rid.write(0);
		rvalid.write(false);
		rready.write(false);

		wait(clk.posedge_event());
	}

	void test_barrier()
	{
		do_read_barrier();
		do_write_barrier();

		reset_toggle();
	}

	void test_barrier_outstanding()
	{
		do_read_barrier(0);
		do_read_barrier(1);
		do_read_barrier(2);
		do_write_barrier(0);
		do_write_barrier(1);
		do_write_barrier(2);

		reset_toggle();
	}

	void test_barrier_wrong_write_barrier_sequence_error()
	{
		uint8_t r_id = 0;
		uint8_t w_id = 1;

		do_read_barrier(r_id);
		do_write_barrier(w_id);

		reset_toggle();
	}

	void test_barrier_wrong_read_barrier_sequence_error()
	{
		uint8_t r_id = 0;
		uint8_t w_id = 1;

		do_write_barrier(w_id);
		do_read_barrier(r_id);

		reset_toggle();
	}
};

SIGGEN_RUN(TestSuite)

ACEPCConfig checker_config()
{
	ACEPCConfig cfg;

	cfg.check_ace_barriers();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	ACELiteProtocolChecker<AXI_ADDR_WIDTH, AXI_DATA_WIDTH>
			checker("checker", checker_config());

	ACELiteSignals__ signals("acelite_signals");

	SignalGen<AXI_ADDR_WIDTH, AXI_DATA_WIDTH> siggen("sig_gen");

	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);

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
