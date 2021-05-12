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
		SetMessageType(RD_TX_ERROR);

		TESTCASE(test_readonce);

		TESTCASE(test_read_barrier);

		TESTCASE_NEG(test_ar_arcache_error);

		TESTCASE_NEG(test_ar_barrier_signals_error);
		TESTCASE_NEG(test_ar_barrier_id_vs_normal_tx_id_error);

		TESTCASE_NEG(test_ar_normal_tx_id_vs_barrier_id_error);

		TESTCASE_NEG(test_r_response_slave_error);
		TESTCASE_NEG(test_r_response_barrier_resp_error);
		TESTCASE_NEG(test_r_response_rlast_error);
	}

	void reset_toggle()
	{
		resetn.write(false);
		wait(clk.posedge_event());
		resetn.write(true);
		wait(clk.posedge_event());
	}

	void setup_ar_readonce()
	{
		arsnoop.write(AR::ReadOnce);
		arbar.write(false);
		ardomain.write(Domain::Inner);
		arcache.write(2); // modifiable
		arsize.write(3); // 1 << 3 = 8 bytes
		arlen.write(7); // 7 + 1 = 8
		arburst.write(AXI_BURST_INCR);
	}

	void setup_ar_barrier()
	{
		arsnoop.write(0);
		arbar.write(true);
		ardomain.write(Domain::Inner);
		arcache.write(2); // modifiable
		arsize.write(3); // 1 << 3 = 8 bytes
		arlen.write(0);
		araddr.write(0);
		arburst.write(AXI_BURST_INCR);
	}

	void test_readonce()
	{
		setup_ar_readonce();

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		arvalid.write(false);
		arready.write(false);

		// response
		rvalid.write(true);
		rready.write(true);

		for (int i = 0; i < 7; i++) {
			wait(clk.posedge_event());
		}
		rlast.write(true);
		wait(clk.posedge_event());

		rlast.write(false);
		rvalid.write(false);
		rready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_read_barrier()
	{
		setup_ar_barrier();

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		arvalid.write(false);
		arready.write(false);

		//
		// Response
		//
		rlast.write(true);
		rvalid.write(true);
		rready.write(true);

		wait(clk.posedge_event());

		rlast.write(false);
		rvalid.write(false);
		rready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_ar_arcache_error()
	{
		setup_ar_readonce();
		arcache.write(0);

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_ar_barrier_signals_error()
	{
		setup_ar_barrier();
		arburst.write(AXI_BURST_FIXED);

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_ar_barrier_id_vs_normal_tx_id_error()
	{
		// normal first
		setup_ar_readonce();

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		setup_ar_barrier();

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_ar_normal_tx_id_vs_barrier_id_error()
	{
		// barrier tx first
		setup_ar_barrier();

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		setup_ar_readonce();

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_r_response_slave_error()
	{
		setup_ar_readonce();

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		arvalid.write(false);
		arready.write(false);

		// response
		rvalid.write(true);
		rready.write(true);

		rresp.write(2);

		wait(clk.posedge_event());

		rresp.write(0);
		rvalid.write(false);
		rready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_r_response_barrier_resp_error()
	{
		setup_ar_barrier();

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		arvalid.write(false);
		arready.write(false);

		// response
		rvalid.write(true);
		rready.write(true);

		rresp.write(1); // error

		wait(clk.posedge_event());

		rresp.write(0);
		rvalid.write(false);
		rready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_r_response_rlast_error()
	{
		setup_ar_readonce();

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		arvalid.write(false);
		arready.write(false);

		// response
		rvalid.write(true);
		rready.write(true);

		for (int i = 0; i < 7; i++) {
			wait(clk.posedge_event());
		}
		rlast.write(false); // rlast not set
		wait(clk.posedge_event());

		rlast.write(false);
		rvalid.write(false);
		rready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}
};

SIGGEN_RUN(TestSuite)

ACEPCConfig checker_config()
{
	ACEPCConfig cfg;

	cfg.check_rd_tx();
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
