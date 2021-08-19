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
		SetMessageType(CD_DATA_ERROR);

		TESTCASE(test_line_alloc_and_snoop_readshared);
		TESTCASE(test_line_alloc_writeback_and_snoop_readshared);
		TESTCASE(test_line_alloc_cleaninvalid_and_snoop_readshared);
		TESTCASE(test_line_alloc_snoop_cleaninvalid_and_snoop_readshared);
		TESTCASE(test_line_snoop_readshared_no_line_in_cache);

		TESTCASE_NEG(test_line_unexpected_cd_data_error);
		TESTCASE_NEG(test_line_cd_data_without_data_error);
	}

	void reset_toggle()
	{
		resetn.write(false);
		wait(clk.posedge_event());
		resetn.write(true);
		wait(clk.posedge_event());
	}

	void setup_ar(uint8_t snoop)
	{
		arsnoop.write(snoop);
		arbar.write(false);
		ardomain.write(Domain::Inner);
		arcache.write(2); // modifiable
		arsize.write(3); // 1 << 3 = 8 bytes
		arlen.write(7); // 7 + 1 = 8
		arburst.write(AXI_BURST_INCR);
	}

	void do_readshared()
	{
		setup_ar(AR::ReadShared);

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
	}

	void do_cleaninvalid()
	{
		setup_ar(AR::CleanInvalid);

		arvalid.write(true);
		arready.write(true);

		wait(clk.posedge_event());

		arvalid.write(false);
		arready.write(false);

		// response
		rlast.write(true);
		rvalid.write(true);
		rready.write(true);

		wait(clk.posedge_event());

		rlast.write(false);
		rvalid.write(false);
		rready.write(false);

		wait(clk.posedge_event());
	}

	void setup_aw_writeback()
	{
		awsnoop.write(AW::WriteBack);
		awbar.write(false);
		awdomain.write(Domain::Inner);
		awcache.write(2); // modifiable
		awsize.write(3); // 1 << 3 = 8 bytes
		awlen.write(7); // 7 + 1 = 8
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

	void do_aw_writeback_wdata_phases()
	{
		setup_aw_writeback();

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

	void do_writeback()
	{
		do_aw_writeback_wdata_phases();

		//
		// Response
		//
		bvalid.write(true);
		bready.write(true);

		wait(clk.posedge_event());

		bvalid.write(false);
		bready.write(false);

		wait(clk.posedge_event());
	}

	enum {
		DataTransfer = 1,
		IsShared = (1 << 3),
	};

	void do_ac_cr_readshared(uint8_t resp,
				uint8_t snoop = AC::ReadShared)
	{
		acsnoop.write(snoop);
		acvalid.write(true);
		acready.write(true);

		wait(clk.posedge_event());

		acvalid.write(false);
		acready.write(false);

		//
		// Response
		//
		crresp.write(resp);
		crvalid.write(true);
		crready.write(true);

		wait(clk.posedge_event());

		crresp.write(0);
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
	}

	void do_ac_cr_cleaninvalid(uint8_t resp)
	{
		do_ac_cr_readshared(resp, AC::CleanInvalid);
	}

	void test_line_alloc_and_snoop_readshared()
	{
		// allocate
		do_readshared();

		// read line via snoop
		do_ac_cr_readshared(DataTransfer | IsShared);

		reset_toggle();
	}

	void test_line_alloc_writeback_and_snoop_readshared()
	{
		// allocate
		do_readshared();

		// evict line
		do_writeback();

		//
		// read line via snoop (no datatransfer set since cacheline
		// should have been evicted)
		//
		do_ac_cr_readshared(0);

		reset_toggle();
	}

	void test_line_alloc_cleaninvalid_and_snoop_readshared()
	{
		// allocate
		do_readshared();

		// snoop cleaninvalid for evicting line
		do_cleaninvalid();

		//
		// read line via snoop (no datatransfer set since cacheline
		// should have been evicted)
		//
		do_ac_cr_readshared(0);

		reset_toggle();
	}

	void test_line_alloc_snoop_cleaninvalid_and_snoop_readshared()
	{
		// allocate
		do_readshared();

		// snoop cleaninvalid for evicting line
		do_ac_cr_cleaninvalid(0);

		//
		// read line via snoop (no datatransfer set since cacheline
		// should have been evicted)
		//
		do_ac_cr_readshared(0);

		reset_toggle();
	}

	void test_line_snoop_readshared_no_line_in_cache()
	{
		//
		// no line in cache
		//
		do_ac_cr_readshared(0);

		reset_toggle();
	}

	void test_line_unexpected_cd_data_error()
	{
		//
		// no line in cache but crresp with datatransfer
		//
		do_ac_cr_readshared(DataTransfer | IsShared);

		reset_toggle();
	}

	void test_line_cd_data_without_data_error()
	{
		// allocate
		do_readshared();

		//
		// line in cache but crresp without datatransfer
		//
		do_ac_cr_readshared(0);

		reset_toggle();
	}
};

SIGGEN_RUN(TestSuite)

ACEPCConfig checker_config()
{
	ACEPCConfig cfg;

	cfg.check_ace_cd_data();

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
