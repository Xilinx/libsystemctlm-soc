/*
 * Copyright (c) 2020 Xilinx Inc.
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

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/random-traffic.h"

#include "test-modules/memory.h"
#include "test-modules/chip-ccix.h"
#include "test-modules/signals-cxs.h"

using namespace utils;

#define RN0_ID 0
#define HN0_ID 20

#define RN1_ID 1
#define HN1_ID 21

#define LINE(l) (l * CACHELINE_SZ)

typedef Chip<RN0_ID, HN0_ID> Chip0_t;
typedef Chip<RN1_ID, HN1_ID> Chip1_t;

typedef CXSSignals<
Chip0_t::CXS_DATA_W,
Chip0_t::CXS_CNTL_W
> CXSSignals_t;

int sc_main(int argc, char *argv[])
{
	unsigned int ram_sz = DEFAULT_RAM_SIZE;

	RandomTraffic transfers0(0, ram_sz, (~(0x3llu)),
					1, ram_sz, ram_sz, 100000);
	RandomTraffic transfers1(0, ram_sz, (~(0x3llu)),
					1, ram_sz, ram_sz, 100000);

	CXSSignals_t sgnls_cxs0("cxs_signals0");
	CXSSignals_t sgnls_cxs1("cxs_signals1");

	sc_signal<bool> resetn("resetn", true);
	sc_clock clk("clk", sc_time(20, SC_US));

	Chip0_t chip0("chip0", transfers0, clk, resetn);
	Chip1_t chip1("chip1", transfers1, clk, resetn);

	sc_trace_file *trace_fp = NULL;

	//
	// Configure the System Address Map on HN0
	//
	chip0.icn.SystemAddressMap().AddMap(0, ram_sz/2, HN1_ID);

	//
	// Configure the CCIX port on chip 0
	//
	chip0.icn.port_CCIX[0]->AddRemoteAgent(RN1_ID);
	chip0.icn.port_CCIX[0]->AddRemoteAgent(HN1_ID);

	//
	// Configure the System Address Map on HN1
	//
	chip1.icn.SystemAddressMap().AddMap(ram_sz/2, ram_sz/2, HN0_ID);

	//
	// Configure the CCIX port on chip 1
	//
	chip1.icn.port_CCIX[0]->AddRemoteAgent(RN0_ID);
	chip1.icn.port_CCIX[0]->AddRemoteAgent(HN0_ID);

	//
	// Connect TX Chip0 and RX chip1
	//
	sgnls_cxs0.connectTX(&chip0.cxs_bridge);
	sgnls_cxs0.connectRX(&chip1.cxs_bridge);

	//
	// Connect TX Chip1 and RX chip0
	//
	sgnls_cxs1.connectTX(&chip1.cxs_bridge);
	sgnls_cxs1.connectRX(&chip0.cxs_bridge);

	//
	// Trace setup
	//
	trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, clk, clk.name());
	sc_trace(trace_fp, resetn, resetn.name());

	sgnls_cxs0.Trace(trace_fp);
	sgnls_cxs1.Trace(trace_fp);

	chip0.Trace(trace_fp);
	chip1.Trace(trace_fp);

	//
	// Run
	//
	sc_start(2000, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	return 0;
}
