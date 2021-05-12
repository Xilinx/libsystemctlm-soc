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
#include "checkers/pc-ace.h"
#include "checkers/config-ace.h"
#include "test-modules/memory.h"
#include "test-modules/signals-ace.h"
#include "siggen-ace.h"

#define AXI_ADDR_WIDTH 64
#define AXI_DATA_WIDTH 64

typedef ACESignals<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH	// DATA_WIDTH
> ACESignals__;

SIGGEN_TESTSUITE(TestSuite)
{
	SIGGEN_TESTSUITE_CTOR(TestSuite)
	{}

	void run_tests()
	{
		SetMessageType(AC_CH_ERROR);
		SetMessageType(CR_CH_ERROR);
		SetMessageType(CD_CH_ERROR);

		TESTCASE(test_ac_cr_cd_readclean);

		TESTCASE_NEG(test_ac_acsnoop_error);
		TESTCASE_NEG(test_ac_acaddr_error);
		TESTCASE_NEG(test_cr_unexpected_resp_error);
		TESTCASE_NEG(test_cr_pass_dirty_error);
		TESTCASE_NEG(test_cr_pass_dirty_no_datatransfer_error);
		TESTCASE_NEG(test_cr_is_shared_error);
		TESTCASE_NEG(test_cd_unexpected_data_error);
		TESTCASE_NEG(test_cd_cdlast_error);
	}

	void reset_toggle()
	{
		resetn.write(false);
		wait(clk.posedge_event());
		resetn.write(true);
		wait(clk.posedge_event());
	}

	void test_ac_cr_cd_readclean()
	{
		acsnoop.write(AC::ReadClean);
		acvalid.write(true);
		acready.write(true);

		wait(clk.posedge_event());

		acvalid.write(false);
		acready.write(false);

		//
		// Response
		//
		crvalid.write(true);
		crready.write(true);
		crresp.write(1); // data transfer

		wait(clk.posedge_event());

		crvalid.write(false);
		crready.write(false);

		//
		// Data phase
		//
		cdvalid.write(true);
		cdready.write(true);

		for (int i = 0; i < 7; i++) {
			wait(clk.posedge_event());
		}
		// Set wlast on last beat
		cdlast.write(true);
		wait(clk.posedge_event());

		cdvalid.write(false);
		cdready.write(false);

		reset_toggle();
	}

	void test_ac_acsnoop_error()
	{
		acsnoop.write(0x4);
		acvalid.write(true);
		acready.write(true);

		wait(clk.posedge_event());

		acsnoop.write(0x0);
		acvalid.write(false);
		acready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_ac_acaddr_error()
	{
		acsnoop.write(AC::ReadClean);
		acaddr.write(1);

		acvalid.write(true);
		acready.write(true);

		wait(clk.posedge_event());

		acvalid.write(false);
		acready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_cr_unexpected_resp_error()
	{
		//
		// Response to no tx
		//
		crvalid.write(true);
		crready.write(true);
		crresp.write(1 << 2); // pass dirty

		wait(clk.posedge_event());

		crresp.write(0);
		crvalid.write(false);
		crready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_cr_pass_dirty_error()
	{
		acsnoop.write(AC::ReadClean);
		acvalid.write(true);
		acready.write(true);

		wait(clk.posedge_event());

		acvalid.write(false);
		acready.write(false);

		//
		// Response
		//
		crvalid.write(true);
		crready.write(true);
		crresp.write(1 << 2); // pass dirty

		wait(clk.posedge_event());

		crresp.write(0);
		crvalid.write(false);
		crready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_cr_pass_dirty_no_datatransfer_error()
	{
		acsnoop.write(AC::ReadClean);
		acvalid.write(true);
		acready.write(true);

		wait(clk.posedge_event());

		acvalid.write(false);
		acready.write(false);

		//
		// Response
		//
		crvalid.write(true);
		crready.write(true);
		crresp.write(1 << 2); // pass dirty

		wait(clk.posedge_event());

		crresp.write(0);
		crvalid.write(false);
		crready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_cr_is_shared_error()
	{
		acsnoop.write(AC::ReadUnique);
		acvalid.write(true);
		acready.write(true);

		wait(clk.posedge_event());

		acvalid.write(false);
		acready.write(false);

		//
		// Response
		//
		crvalid.write(true);
		crready.write(true);
		crresp.write(1 << 3); // is shared

		wait(clk.posedge_event());

		crresp.write(0);
		crvalid.write(false);
		crready.write(false);

		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_cd_unexpected_data_error()
	{
		//
		// Data phase no tx
		//
		cdvalid.write(true);
		cdready.write(true);

		wait(clk.posedge_event());

		cdvalid.write(false);
		cdready.write(false);

		reset_toggle();
	}

	void test_cd_cdlast_error()
	{
		acsnoop.write(AC::ReadClean);
		acvalid.write(true);
		acready.write(true);

		wait(clk.posedge_event());

		acvalid.write(false);
		acready.write(false);

		//
		// Response
		//
		crvalid.write(true);
		crready.write(true);

		wait(clk.posedge_event());

		crvalid.write(false);
		crready.write(false);

		//
		// Data phase
		//
		cdvalid.write(true);
		cdready.write(true);

		for (int i = 0; i < 7; i++) {
			wait(clk.posedge_event());
		}
		// cdlast not set on last beat
		cdlast.write(false);
		wait(clk.posedge_event());

		cdvalid.write(false);
		cdready.write(false);

		reset_toggle();
	}
};

SIGGEN_RUN(TestSuite)

ACEPCConfig checker_config()
{
	ACEPCConfig cfg;

	cfg.check_ace_snoop_ch_signaling();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	ACEProtocolChecker<AXI_ADDR_WIDTH, AXI_DATA_WIDTH>
			checker("checker", checker_config());

	ACESignals__ signals("ace_signals");

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
