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
#include "tlm-bridges/tlm2acelite-bridge.h"
#include "tlm-bridges/acelite2tlm-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "checkers/pc-ace.h"
#include "checkers/pc-acelite.h"
#include "test-modules/memory.h"
#include "test-modules/signals-ace.h"
#include "test-modules/signals-acelite.h"
#include "test-modules/utils-ace.h"

#include "tlm-modules/master-ace.h"
#include "tlm-modules/iconnect-ace.h"

using namespace utils;
using namespace utils::ACE;

#ifndef CACHELINE_SIZE
#define CACHELINE_SIZE 64
#endif

#define CACHE_SIZE (4 * CACHELINE_SIZE)
#define RAM_SIZE (32 * CACHELINE_SIZE)

#define NUM_ACE_MASTERS 3
#define NUM_ACELITE_MASTERS 1

#define LINE(l) (l * CACHELINE_SIZE)

typedef ACESignals<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH 	// DATA_WIDTH
> ACESignals_t;

typedef ACELiteSignals<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH 	// DATA_WIDTH
> ACELiteSignals_t;

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

typedef tlm2acelite_bridge<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH 	// DATA_WIDTH
> tlm2acelite_bridge_t;

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

typedef acelite2tlm_bridge<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH 	// DATA_WIDTH
> acelite2tlm_bridge_t;

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

typedef ACELiteProtocolChecker<
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
	CACHELINE_SIZE	// CACHELINE_SZ
> ACELiteChecker;

typedef ACEMaster<
	CACHE_SIZE,
	CACHELINE_SIZE
> ACEMaster_t;

typedef iconnect_ace<
	NUM_ACE_MASTERS,
	NUM_ACELITE_MASTERS,
	CACHELINE_SIZE
> iconnect_ace_t;

const unsigned char burst_data[140] = {
	0x11, 0x12, 0x13, 0x14, 0x21, 0x22, 0x23, 0x24,
	0x21, 0x22, 0x23, 0x24, 0x31, 0x32, 0x33, 0x34,
	0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x43, 0x44,
	0x41, 0x42, 0x43, 0x44, 0x51, 0x52, 0x53, 0x54
};

const unsigned char dummy_data[CACHELINE_SIZE] = { 0 };

TrafficDesc transfers0(merge({

	// Round 1

	// Cacheline 1
	Write(LINE(1), DATA(0xFF, 0xFF, 0xFF, 0xFF)),

	// Cacheline 2
	Write(LINE(2), DATA(0xFF, 0xFF, 0xFF, 0xFF)),

	// Cacheline 3
	Write(LINE(3), DATA(0xFF, 0xFF, 0xFF, 0xFF)),

	// Cacheline 0
	Write(0, DATA(0xFF, 0xFF, 0xFF, 0xFF)),

	// Round 2

	// Cacheline 1
	Write(LINE(1), DATA(0x1, 0x1, 0x1, 0x1)),

	// Cacheline 2
	Write(LINE(2), DATA(0x1, 0x1, 0x1, 0x1)),

	// Cacheline 3
	Write(LINE(3), DATA(0x1, 0x1, 0x1, 0x1)),

	// Cacheline 0
	Write(LINE(0), DATA(0x1, 0x1, 0x1, 0x1)),

	// Multiple lines starting from cacheline 4
	Write(LINE(4), burst_data, sizeof(burst_data)),

	// Test barrier
	ReadBarrier(), WriteBarrier(),

	// Test DVM branch predictor invalidate message
	DVMMessage(DVM_CMD(DVM::CmdBranchPredictorInv)),

	// Test DVM Sync message
	DVMMessage(DVM_CMD(DVM::CmdSync) | DVM::CompletionBit),

	// Test cache maintenance operations,
	CleanShared(LINE(0), dummy_data, sizeof(dummy_data)),
	CleanInvalid(LINE(0), dummy_data, sizeof(dummy_data)),
	MakeInvalid(LINE(0), dummy_data, sizeof(dummy_data))
}));

TrafficDesc transfers1(merge({
	// Read default values once for delaying this thread

	Write(LINE(0), DATA(0x0, 0x0, 0x0, 0x0)),

	// Cacheline 0
	Read(LINE(0)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	// Round 1

	// Cacheline 1
	Read(LINE(1)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	// Cacheline 2
	Read(LINE(2)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	// Cacheline 3
	Read(LINE(3)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	// Cacheline 0
	Read(LINE(0)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	// Round 2

	// Cacheline 1
	Read(LINE(1)),
		Expect(DATA(0x1, 0x1, 0x1, 0x1), 4),

	// Cacheline 2
	Read(LINE(2)),
		Expect(DATA(0x1, 0x1, 0x1, 0x1), 4),

	// Cacheline 3
	Read(LINE(3)),
		Expect(DATA(0x1, 0x1, 0x1, 0x1), 4),

	// Cacheline 0
	Read(LINE(0)),
		Expect(DATA(0x1, 0x1, 0x1, 0x1), 4),

	// Round 3
	// Cacheline 1
	Write(LINE(1), DATA(0x1, 0x2, 0x3, 0x4)),
	Read(LINE(1)),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4),

	// Cacheline 2
	Write(LINE(2), DATA(0x1, 0x2, 0x3, 0x4)),
	Read(LINE(2)),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4),

	// Cacheline 3
	Write(LINE(3), DATA(0x1, 0x2, 0x3, 0x4)),
	Read(LINE(3)),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4),

	// Multiple lines starting from cacheline 4
	Read(LINE(4), sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

	// Exclusive load store sequence
	ExclusiveLoad(0),
	ExclusiveStore(0, DATA(0x0, 0x0, 0x0, 0x1), 4),
	Read(0),
		Expect(DATA(0x0, 0x0, 0x0, 0x1), 4),
}));

TrafficDesc transfers2(merge({
	// Read default values once for delaying this thread

	// Cacheline 10, 11, 12, 13
	Read(LINE(10)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	Read(LINE(11)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	Read(LINE(12)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	Read(LINE(13)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	// Test write
	Write(LINE(13), DATA(0x1, 0x2, 0x3, 0x4)),

	Read(LINE(13)),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4),

	// Test write with offset
	Write(LINE(13) + 4, DATA(0x1, 0x2, 0x3, 0x4)),

	Read(LINE(13) + 4),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4),


	//
	// Multiple lines starting from cacheline 10
	//
	Write(LINE(10), burst_data, sizeof(burst_data)),
	Read(LINE(10), sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

	//
	// Multiple lines starting from cacheline 10 + 4
	//
	Write(LINE(10) + 4, burst_data, sizeof(burst_data)),
	Read(LINE(10) + 4, sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

	//
	// Multiple lines starting from cacheline 14
	//
	Write(LINE(14), burst_data, sizeof(burst_data)),
	Read(LINE(14), sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

	//
	// Multiple lines starting from cacheline 14 + 4
	//
	Write(LINE(14) + 4, burst_data, sizeof(burst_data)),
	Read(LINE(14) + 4, sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),
}));

TrafficDesc acelite_transfers0(merge({
	// Cacheline 8
	Write(LINE(8), DATA(0x1, 0x1, 0x1, 0x1)),
	Read(LINE(8)),
		Expect(DATA(0x1, 0x1, 0x1, 0x1), 4),

	// Cacheline 9
	Write(LINE(9), DATA(0x1, 0x1, 0x1, 0x1)),
	Read(LINE(9)),
		Expect(DATA(0x1, 0x1, 0x1, 0x1), 4),

	//
	// Multiple lines starting from cacheline 7
	//
	Write(LINE(7), burst_data, sizeof(burst_data)),
	Read(LINE(7), sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

	//
	// Multiple lines starting from cacheline 7 + 4
	//
	Write(LINE(7) + 4, burst_data, sizeof(burst_data)),
	Read(LINE(7) + 4, sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

	//
	// Multiple lines starting from cacheline 7 + 4
	//
	Write(LINE(7) + 4, burst_data, sizeof(burst_data)),
	Read(LINE(7) + 4, sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

	//
	// Multiple lines starting from cacheline 7 + 7
	//
	Write(LINE(7) + 7, burst_data, sizeof(burst_data)),
	Read(LINE(7) + 7, sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),
	//
	// Multiple lines starting from cacheline 7 + 8
	//
	Write(LINE(7) + 8, burst_data, sizeof(burst_data)),
	Read(LINE(7) + 8, sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

	//
	// Multiple lines starting from cacheline 7 + 4
	//
	Write(LINE(7) + 4, burst_data, sizeof(burst_data)),
	Read(LINE(7) + 4, sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

	//
	// Multiple lines starting from cacheline 7 + 7
	//
	Write(LINE(7) + 7, burst_data, sizeof(burst_data)),
	Read(LINE(7) + 7, sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),
	//
	// Multiple lines starting from cacheline 7 + 8
	//
	Write(LINE(7) + 8, burst_data, sizeof(burst_data)),
	Read(LINE(7) + 8, sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

	//
	// Multiple lines starting from cacheline 4 (written in transfer0)
	//
	Read(LINE(4), sizeof(burst_data)),
		Expect(burst_data, sizeof(burst_data)),

}));

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

void check_results()
{
	if (!transfers0.done()) {
		SC_REPORT_ERROR("Transfers0",
				"Failed executing transfers\n");
	}

	if (!transfers1.done()) {
		SC_REPORT_ERROR("Transfers1",
				"Failed executing transfers\n");
	}

	if (!transfers2.done()) {
		SC_REPORT_ERROR("Transfers2",
				"Failed executing transfers\n");
	}

	if (!acelite_transfers0.done()) {
		SC_REPORT_ERROR("ACELite Transfers0",
				"Failed executing transfers\n");
	}

	cout << " -- All transfers done!" << endl;
}

ACEPCConfig checker_config()
{
	ACEPCConfig cfg;

	cfg.enable_all_checks();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	ACEMaster_t master0("ace_master0", transfers0);
	ACEMaster_t master1("ace_master1", transfers1);
	ACEMaster_t master2("ace_master2", transfers2, WriteThrough);

	ACELiteMaster al_master("acelite_master", acelite_transfers0);

	iconnect_ace_t iconnect("ace_iconnect");

	memory mem("mem", sc_time(10, SC_NS), RAM_SIZE);

	ACESignals_t signals0("ace_signals0");
	ACESignals_t signals1("ace_signals1");
	ACESignals_t signals2("ace_signals2");

	ACELiteSignals_t al_signals("acelite_signals");

	tlm2ace_bridge_t t2a_bridge0("tlm2ace_bridge0");
	tlm2ace_bridge_t t2a_bridge1("tlm2ace_bridge1");
	tlm2ace_bridge_t t2a_bridge2("tlm2ace_bridge2");

	tlm2acelite_bridge_t t2al_bridge("tlm2acelite_bridge");

	ace2tlm_bridge_t a2t_bridge0("ace2tlm_bridge0");
	ace2tlm_bridge_t a2t_bridge1("ace2tlm_bridge1");
	ace2tlm_bridge_t a2t_bridge2("ace2tlm_bridge2");

	acelite2tlm_bridge_t al2t_bridge("acelite2tlm_bridge");

	ACEChecker checker0("checker0", checker_config());
	ACEChecker checker1("checker1", checker_config());
	ACEChecker checker2("checker2", checker_config());

	ACELiteChecker al_checker("acelite_checker",
					checker_config());

	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);

	//
	// Setup master0 with the interconnect
	//
	connect(clk, resetn,
		master0, t2a_bridge0,
		signals0,
		a2t_bridge0, *iconnect.s_ace_port[0]);
	iconnect.s_ace_port[0]->SetForwardDVM(true);

	//
	// Setup master1 with the interconnect
	//
	connect(clk, resetn,
		master1, t2a_bridge1,
		signals1,
		a2t_bridge1, *iconnect.s_ace_port[1]);
	iconnect.s_ace_port[1]->SetForwardDVM(true);

	//
	// Setup master2 with the interconnect
	//
	connect(clk, resetn,
		master2, t2a_bridge2,
		signals2,
		a2t_bridge2, *iconnect.s_ace_port[2]);

	//
	// Setup the ACELite master with the interconnect
	//
	connect(clk, resetn,
		al_master, t2al_bridge,
		al_signals,
		al2t_bridge, *iconnect.s_acelite_port[0]);

	//
	// Downstream port
	//
	iconnect.ds_port.connect_slave(mem);

	//
	// Connect the ACE protocol checker0
	//
	checker0.clk(clk);
	checker0.resetn(resetn);
	signals0.connect(&checker0);

	//
	// Connect the ACE protocol checker1
	//
	checker1.clk(clk);
	checker1.resetn(resetn);
	signals1.connect(&checker1);

	//
	// Connect the ACE protocol checker2
	//
	checker2.clk(clk);
	checker2.resetn(resetn);
	signals2.connect(&checker2);

	//
	// Connect the ACELite protocol checker
	//
	al_checker.clk(clk);
	al_checker.resetn(resetn);
	al_signals.connect(&al_checker);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, clk, clk.name());

	signals0.Trace(trace_fp);
	signals1.Trace(trace_fp);
	signals2.Trace(trace_fp);
	al_signals.Trace(trace_fp);

	sc_start(20, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	check_results();

	return 0;
}
