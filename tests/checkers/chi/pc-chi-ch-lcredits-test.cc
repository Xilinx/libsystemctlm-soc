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
#include "checkers/pc-chi.h"
#include "checkers/config-chi.h"
#include "tlm-bridges/amba-chi.h"
#include "test-modules/memory.h"
#include "test-modules/signals-rnf-chi.h"
#include "siggen-chi.h"

typedef CHIProtocolChecker<> CHIChecker;

typedef CHISignals<
CHIChecker::TXREQ_FLIT_W,
CHIChecker::TXRSP_FLIT_W,
CHIChecker::TXDAT_FLIT_W,
CHIChecker::RXRSP_FLIT_W,
CHIChecker::RXDAT_FLIT_W,
CHIChecker::RXSNP_FLIT_W
> CHISignals_t;

SIGGEN_TESTSUITE(TestSuite)
{
	SIGGEN_TESTSUITE_CTOR(TestSuite)
	{}

	void run_tests()
	{
		SetMessageType(CHI_LCRD_ERROR);

		TESTCASE(test_lcredits);

		TESTCASE_NEG(test_to_many_lcredits);
		TESTCASE_NEG(test_to_many_lcredits_returned);
	}

	void reset_toggle()
	{
		resetn.write(false);
		wait(clk.posedge_event());
		resetn.write(true);
		wait(clk.posedge_event());
	}

	void test_lcredits()
	{
		txreqlcrdv.write(true);

		// Max 15 are allowed
		for (int i = 0; i < 15; i++) {
			wait(clk.posedge_event());
		}

		txreqlcrdv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_to_many_lcredits()
	{
		txreqlcrdv.write(true);

		for (int i = 0; i < 16; i++) {
			wait(clk.posedge_event());
		}

		txreqlcrdv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_to_many_lcredits_returned()
	{
		txreqflitv.write(true);

		wait(clk.posedge_event());

		txreqflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}
};

SIGGEN_RUN(TestSuite)

CHIPCConfig checker_config()
{
	CHIPCConfig cfg;

	cfg.check_ch_lcredits();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	CHIChecker checker("checker", checker_config());

	CHISignals_t signals("chi_signals");

	SignalGen<> siggen("sig_gen");

	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);

	// Connect clk
	checker.clk(clk);
	siggen.clk(clk);

	// Connect reset
	checker.resetn(resetn);
	siggen.resetn(resetn);

	// Connect signals
	signals.connectRNF(&checker);
	signals.connectRNF(&siggen);

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
