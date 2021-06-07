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
		SetMessageType(WR_TX_ERROR);

		TESTCASE(test_writeunique);

		TESTCASE(test_write_barrier);

		TESTCASE_NEG(test_aw_awsnoop_error);
		TESTCASE_NEG(test_aw_awcache_error);
		TESTCASE_NEG(test_aw_awburst_error);

		TESTCASE_NEG(test_aw_barrier_signals_error);
		TESTCASE_NEG(test_aw_barrier_id_vs_normal_tx_id_error);

		TESTCASE_NEG(test_aw_normal_tx_id_vs_barrier_id_error);

		TESTCASE_NEG(test_b_response_slave_error);

		TESTCASE_NEG(test_w_response_wlast_error);
	}

	void reset_toggle()
	{
		resetn.write(false);
		wait(clk.posedge_event());
		resetn.write(true);
		wait(clk.posedge_event());
	}

	void setup_aw_writeunique()
	{
		awsnoop.write(AW::WriteUnique);
		awbar.write(false);
		awdomain.write(Domain::Inner);
		awcache.write(2); // modifiable
		awsize.write(3); // 1 << 3 = 8 bytes
		awlen.write(7); // 7 + 1 = 8
		awburst.write(AXI_BURST_INCR);
	}

	void setup_aw_barrier()
	{
		awsnoop.write(0);
		awbar.write(true);
		awdomain.write(Domain::Inner);
		awcache.write(2); // modifiable
		awsize.write(3); // 1 << 3 = 8 bytes
		awlen.write(0);
		awaddr.write(0);
		awburst.write(AXI_BURST_INCR);
	}

	void do_wdata_phase()
	{
		wvalid.write(true);
		wready.write(true);

		for (int i = 0; i < 7; i++) {
			wait(clk.posedge_event());
		}
		// Set wlast on last beat
		wlast.write(true);
		wait(clk.posedge_event());

		wlast.write(false);
		wvalid.write(false);
		wready.write(false);
	}

	void do_aw_writeunique_wdata_phases()
	{
		setup_aw_writeunique();

		awvalid.write(true);
		awready.write(true);

		wait(clk.posedge_event());

		awvalid.write(false);
		awready.write(false);

		//
		// Data phase
		//
		do_wdata_phase();
	}

	void test_writeunique()
	{
		do_aw_writeunique_wdata_phases();

		//
		// Response
		//
		bvalid.write(true);
		bready.write(true);

		wait(clk.posedge_event());

		bvalid.write(false);
		bready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_write_barrier()
	{
		setup_aw_barrier();

		awvalid.write(true);
		awready.write(true);

		wait(clk.posedge_event());

		awvalid.write(false);
		awready.write(false);

		//
		// Response
		//
		bvalid.write(true);
		bready.write(true);

		wait(clk.posedge_event());

		bvalid.write(false);
		bready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_aw_awsnoop_error()
	{
		setup_aw_writeunique();
		awsnoop.write(0xf);

		awvalid.write(true);
		awready.write(true);

		wait(clk.posedge_event());

		awvalid.write(false);
		awready.write(false);

		reset_toggle();
	}

	void test_aw_awcache_error()
	{
		setup_aw_writeunique();
		awcache.write(0);

		awvalid.write(true);
		awready.write(true);

		wait(clk.posedge_event());

		awvalid.write(false);
		awready.write(false);

		reset_toggle();
	}

	void test_aw_awburst_error()
	{
		setup_aw_writeunique();
		awburst.write(AXI_BURST_FIXED);

		awvalid.write(true);
		awready.write(true);

		wait(clk.posedge_event());

		awvalid.write(false);
		awready.write(false);

		reset_toggle();
	}

	void test_aw_barrier_signals_error()
	{
		setup_aw_barrier();
		awburst.write(AXI_BURST_FIXED);

		awvalid.write(true);
		awready.write(true);

		wait(clk.posedge_event());

		awvalid.write(false);
		awready.write(false);

		reset_toggle();
	}

	void test_aw_barrier_id_vs_normal_tx_id_error()
	{
		// normal first
		setup_aw_writeunique();

		awvalid.write(true);
		awready.write(true);

		wait(clk.posedge_event());

		setup_aw_barrier();

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_aw_normal_tx_id_vs_barrier_id_error()
	{
		// barrier tx first
		setup_aw_barrier();

		awvalid.write(true);
		awready.write(true);

		wait(clk.posedge_event());

		setup_aw_writeunique();

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_b_response_slave_error()
	{
		do_aw_writeunique_wdata_phases();

		//
		// Response
		//
		bvalid.write(true);
		bready.write(true);
		bresp.write(2);

		wait(clk.posedge_event());

		bresp.write(0);
		bvalid.write(false);
		bready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_w_response_wlast_error()
	{
		setup_aw_writeunique();

		awvalid.write(true);
		awready.write(true);

		wait(clk.posedge_event());

		awvalid.write(false);
		awready.write(false);

		//
		// Data phase
		//
		wvalid.write(true);
		wready.write(true);

		for (int i = 0; i < 7; i++) {
			wait(clk.posedge_event());
		}
		// wlast not set on last beat
		wlast.write(false);
		wait(clk.posedge_event());

		wvalid.write(false);
		wready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}
};

SIGGEN_RUN(TestSuite)

ACEPCConfig checker_config()
{
	ACEPCConfig cfg;

	cfg.check_wr_tx();
	cfg.set_max_outstanding_tx(257);
	cfg.check_ace_responses();

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
	sc_trace(trace_fp, siggen.resetn, siggen.resetn.name());
	signals.Trace(trace_fp);

	// Run
	sc_start(100, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	return 0;
}
