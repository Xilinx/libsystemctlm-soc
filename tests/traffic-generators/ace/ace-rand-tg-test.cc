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

#include "tlm-bridges/tlm2ace-bridge.h"
#include "tlm-bridges/ace2tlm-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "traffic-generators/random-traffic.h"
#include "checkers/pc-ace.h"
#include "test-modules/memory.h"
#include "test-modules/signals-ace.h"
#include "test-modules/utils-ace.h"

#include "tlm-modules/master-ace.h"
#include "tlm-modules/iconnect-ace.h"

using namespace utils;

#ifndef CACHELINE_SIZE
#define CACHELINE_SIZE 64
#endif

#define CACHE_SIZE (4 * CACHELINE_SIZE)
#define RAM_SIZE (4 * CACHE_SIZE)
#define NUM_ACE_MASTERS 3

typedef ACESignals<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	8,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	2,		// AWUSER_WIDTH
	2,		// ARUSER_WIDTH
	2,		// WUSER_WIDTH
	2,		// RUSER_WIDTH
	2,		// BUSER_WIDTH
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> ACESignals_t;

typedef tlm2ace_bridge<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	8,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	2,		// AWUSER_WIDTH
	2,		// ARUSER_WIDTH
	2,		// WUSER_WIDTH
	2,		// RUSER_WIDTH
	2,		// BUSER_WIDTH
	CACHELINE_SIZE,	// CACHELINE_SZ
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> tlm2ace_bridge_t;

typedef ace2tlm_bridge<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	8,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	2,		// AWUSER_WIDTH
	2,		// ARUSER_WIDTH
	2,		// WUSER_WIDTH
	2,		// RUSER_WIDTH
	2,		// BUSER_WIDTH
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> ace2tlm_bridge_t;

typedef ACEProtocolChecker<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	8,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	2,		// AWUSER_WIDTH
	2,		// ARUSER_WIDTH
	2,		// WUSER_WIDTH
	2,		// RUSER_WIDTH
	2,		// BUSER_WIDTH
	CACHELINE_SIZE,	// CACHELINE_SZ
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> ACEChecker;

typedef ACEMaster<
	CACHE_SIZE,
	CACHELINE_SIZE
> ACEMaster_t;

typedef iconnect_ace<
	NUM_ACE_MASTERS,
	0,
	CACHELINE_SIZE
> iconnect_ace_t;

const unsigned char burst_data[140] = {
	0x11, 0x12, 0x13, 0x14, 0x21, 0x22, 0x23, 0x24,
	0x21, 0x22, 0x23, 0x24, 0x31, 0x32, 0x33, 0x34,
	0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x43, 0x44,
	0x41, 0x42, 0x43, 0x44, 0x51, 0x52, 0x53, 0x54
};


template<typename T1, typename T2,
		typename T3, typename T4,
		typename T5,
		typename T6, typename T7>
void connect(T1& clk, T2& resetn,
		T3& master, T4& tlm2ace_b,
		T5& signals,
		T6& ace2tlm_b, T7& s_ace_port)
{
	// Connect clk
	tlm2ace_b.clk(clk);
	ace2tlm_b.clk(clk);

	// Connect reset
	tlm2ace_b.resetn(resetn);
	ace2tlm_b.resetn(resetn);

	// Connect signals
	signals.connect(&tlm2ace_b);
	signals.connect(&ace2tlm_b);

	// Connect tlm2ace bridge on the master
	master.connect(tlm2ace_b);

	// Connect ace2tlm bridge to the interconnect slave ace port
	s_ace_port.connect_master(ace2tlm_b);
}

ACEPCConfig checker_config()
{
	ACEPCConfig cfg;

	cfg.enable_all_checks();
	cfg.check_ace_handshakes(true, 300);

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	uint64_t max_addr = RAM_SIZE;
	RandomTraffic transfers0(0, max_addr, (~(0x3llu)),
					1, max_addr, max_addr, 12000);
	RandomTraffic transfers1(0, max_addr, (~(0x3llu)),
					1, max_addr, max_addr, 12000);
	RandomTraffic transfers2(0, max_addr, (~(0x3llu)),
					1, max_addr, max_addr, 12000);

	ACEMaster_t master0("ace_master0", transfers0);
	ACEMaster_t master1("ace_master1", transfers1);
	ACEMaster_t master2("ace_master2", transfers2, WriteThrough);

	iconnect_ace_t iconnect("ace_iconnect");

	memory mem("mem", sc_time(10, SC_NS), RAM_SIZE);

	ACESignals_t signals0("ace_signals0");
	ACESignals_t signals1("ace_signals1");
	ACESignals_t signals2("ace_signals2");

	tlm2ace_bridge_t t2a_bridge0("tlm2ace_bridge0");
	tlm2ace_bridge_t t2a_bridge1("tlm2ace_bridge1");
	tlm2ace_bridge_t t2a_bridge2("tlm2ace_bridge2");

	ace2tlm_bridge_t a2t_bridge0("ace2tlm_bridge0");
	ace2tlm_bridge_t a2t_bridge1("ace2tlm_bridge1");
	ace2tlm_bridge_t a2t_bridge2("ace2tlm_bridge2");

	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);

	ACEChecker checker0("checker0", checker_config());
	ACEChecker checker1("checker1", checker_config());
	ACEChecker checker2("checker2", checker_config());


	// Setup master0 with the interconnect
	connect(clk, resetn,
		master0, t2a_bridge0,
		signals0,
		a2t_bridge0, *iconnect.s_ace_port[0]);

	// Setup master1 with the interconnect
	connect(clk, resetn,
		master1, t2a_bridge1,
		signals1,
		a2t_bridge1, *iconnect.s_ace_port[1]);

	// Setup master2 with the interconnect
	connect(clk, resetn,
		master2, t2a_bridge2,
		signals2,
		a2t_bridge2, *iconnect.s_ace_port[2]);

	// Downstream port
	iconnect.ds_port.connect_slave(mem);

	// Connect the ACE protocol checker0
	checker0.clk(clk);
	checker0.resetn(resetn);
	signals0.connect(&checker0);

	// Connect the ACE protocol checker1
	checker1.clk(clk);
	checker1.resetn(resetn);
	signals1.connect(&checker1);

	// Connect the ACE protocol checker2
	checker2.clk(clk);
	checker2.resetn(resetn);
	signals2.connect(&checker2);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, clk, clk.name());

	signals0.Trace(trace_fp);
	signals1.Trace(trace_fp);
	signals2.Trace(trace_fp);

	sc_start(2000, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	return 0;
}
