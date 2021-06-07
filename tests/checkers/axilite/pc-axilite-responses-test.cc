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

#include "traffic-generators/tg-tlm.h"
#include "checkers/pc-axilite.h"
#include "checkers/config-axilite.h"
#include "test-modules/memory.h"
#include "test-modules/signals-axilite.h"
#include "siggen-axilite.h"

#define AXI_ADDR_WIDTH 32
#define AXI_DATA_WIDTH 32

SIGGEN_TESTSUITE(TestSuite)
{
	SIGGEN_TESTSUITE_CTOR(TestSuite)
	{}

	void run_tests()
	{
		TESTCASE(test_r_ch_resp_axi_okay);
		TESTCASE(test_b_ch_resp_axi_okay);

		TESTCASE_NEG(test_r_ch_resp_axi_exokay);
		TESTCASE_NEG(test_b_ch_resp_axi_exokay);

		TESTCASE_NEG(test_r_ch_resp_axi_slverr);
		TESTCASE_NEG(test_b_ch_resp_axi_slverr);

		TESTCASE_NEG(test_r_ch_resp_axi_decerr);
		TESTCASE_NEG(test_b_ch_resp_axi_decerr);
	}

#define GEN_TEST_CH_RESP(name, ch, val)	\
void test_ ## ch ## _ch_resp_ ## name()	\
{					\
	ch ## resp.write(val);		\
	ch ## valid.write(true);	\
	ch ## ready.write(true);	\
					\
	wait(clk.posedge_event());	\
					\
	ch ## resp.write(0);		\
	ch ## valid.write(false);	\
	ch ## ready.write(false);	\
					\
	wait(clk.posedge_event());	\
}

	//
	// Generate:
	// 	test_r_ch_resp_axi_okay
	// 	test_b_ch_resp_axi_okay
	//
	GEN_TEST_CH_RESP(axi_okay, r, AXI_OKAY)
	GEN_TEST_CH_RESP(axi_okay, b, AXI_OKAY)

	//
	// Generate:
	// 	test_r_ch_resp_axi_exokay
	// 	test_b_ch_resp_axi_exokay
	//
	GEN_TEST_CH_RESP(axi_exokay, r, AXI_EXOKAY)
	GEN_TEST_CH_RESP(axi_exokay, b, AXI_EXOKAY)

	//
	// Generate:
	// 	test_r_ch_resp_axi_slverr
	// 	test_b_ch_resp_axi_slverr
	//
	GEN_TEST_CH_RESP(axi_slverr, r, AXI_SLVERR)
	GEN_TEST_CH_RESP(axi_slverr, b, AXI_SLVERR)

	//
	// Generate:
	// 	test_r_ch_resp_axi_decerr
	// 	test_b_ch_resp_axi_decerr
	//
	GEN_TEST_CH_RESP(axi_decerr, r, AXI_DECERR)
	GEN_TEST_CH_RESP(axi_decerr, b, AXI_DECERR)

};

SIGGEN_RUN(TestSuite)

AXILitePCConfig checker_config()
{
	AXILitePCConfig cfg;

	cfg.check_axi_responses();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	AXILiteProtocolChecker<AXI_ADDR_WIDTH, AXI_DATA_WIDTH>
			checker("checker", checker_config());

	AXILiteSignals<AXI_ADDR_WIDTH, AXI_DATA_WIDTH>
			signals("axi_signals");

	SignalGen<AXI_ADDR_WIDTH, AXI_DATA_WIDTH> siggen("sig_gen");
	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);

	siggen.SetMessageType(AXI_RESPONSE_ERROR);

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
