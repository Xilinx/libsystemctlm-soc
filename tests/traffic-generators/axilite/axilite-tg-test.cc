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

#include "tlm-bridges/tlm2axilite-bridge.h"
#include "tlm-bridges/axilite2tlm-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "checkers/pc-axilite.h"
#include "test-modules/memory.h"
#include "test-modules/signals-axilite.h"
#include "test-modules/utils.h"
#include "test-modules/trace-axilite.h"

using namespace utils;

#define SZ_1K 1024

const unsigned char burst_data[] = {
	0x11, 0x12, 0x13, 0x14, 0x21, 0x22, 0x23, 0x24,
	0x21, 0x22, 0x23, 0x24, 0x31, 0x32, 0x33, 0x34,
	0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x43, 0x44,
	0x41, 0x42, 0x43, 0x44, 0x51, 0x52, 0x53, 0x54
};

TrafficDesc transfers(merge({
	Read(0x0),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),
	Read(0x4),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),
	Read(0x8),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	Write(0x0, DATA(0xaa, 0xbb, 0xcc, 0xdd)),
	Read(0x0),
		Expect(DATA(0xaa, 0xbb, 0xcc, 0xdd), 4),

	Write(0x4, DATA(0xab, 0xba, 0xdc, 0xcd)),
	Read(0x4),
		Expect(DATA(0xab, 0xba, 0xdc, 0xcd), 4),

	Write(0x8, DATA(0xa, 0xb, 0xc, 0xd)),
	Read(0x8),
		Expect(DATA(0xa, 0xb, 0xc, 0xd), 4),

	/* 1 byte at a time */
	Write(0x0, DATA(0x9), 1),
	Read(0x0, 1),
		Expect(DATA(0x9), 1),

	Write(0x1, DATA(0xa), 1),
	Read(0x1, 1),
		Expect(DATA(0xa), 1),

	Write(0x2, DATA(0xb), 1),
	Read(0x2, 1),
		Expect(DATA(0xb), 1),

	Write(0x3, DATA(0xc), 1),
	Read(0x3, 1),
		Expect(DATA(0xc), 1),

	/* 2 bytes at a time */
	Write(0x0, DATA(0x2, 0x3), 2),
	Read(0x0, 2),
		Expect(DATA(0x2, 0x3), 2),

	Write(0x2, DATA(0x4, 0x5), 2),
	Read(0x2, 2),
		Expect(DATA(0x4, 0x5), 2),

	Write(0x1, DATA(0x2, 0x3), 2),
	Read(0x1, 2),
		Expect(DATA(0x2, 0x3), 2),
}));

TrafficDesc transfers_64(merge({
	Write(0x0, DATA(0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0), 8),
	Read(0x0, 8),
		Expect(DATA(0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0), 8),

	Write(0x0, DATA(0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7), 8),
	Read(0x0, 8),
		Expect(DATA(0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7), 8),

	Write(0x0, DATA(0x8, 0x9, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf), 8),
	Read(0x0, 8),
		Expect(DATA(0x8, 0x9, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf), 8),

	Write(0x0, DATA(0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf), 8),
	Read(0x0, 8),
		Expect(DATA(0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf), 8),

	/* 1 byte at a time */
	Write(0x4, DATA(0xd), 1),
	Read(0x4, 1),
		Expect(DATA(0xd), 1),

	Write(0x5, DATA(0xe), 1),
	Read(0x5, 1),
		Expect(DATA(0xe), 1),

	Write(0x6, DATA(0xf), 1),
	Read(0x6, 1),
		Expect(DATA(0xf), 1),

	Write(0x7, DATA(0x7), 1),
	Read(0x7, 1),
		Expect(DATA(0x7), 1),

	/* 2 bytes at a time */
	Write(0x4, DATA(0x6, 0x7), 2),
	Read(0x4, 2),
		Expect(DATA(0x6, 0x7), 2),

	Write(0x6, DATA(0x8, 0x9), 2),
	Read(0x6, 2),
		Expect(DATA(0x8, 0x9), 2),

	Write(0x4, DATA(0x6, 0x7), 2),
	Read(0x4, 2),
		Expect(DATA(0x6, 0x7), 2),

	Write(0x6, DATA(0x7, 0x8), 2),
	Read(0x6, 2),
		Expect(DATA(0x7, 0x8), 2),

	Write(0x3, DATA(0x4, 0x5), 2),
	Read(0x3, 2),
		Expect(DATA(0x4, 0x5), 2),
}));

TrafficDesc parallel1(merge({
	Write(0x0, DATA(0x0, 0x1, 0x2, 0x3), 4),
	Write(0x4, DATA(0x4, 0x5, 0x6, 0x7), 4),
	Write(0x8, DATA(0x8, 0x9, 0xa, 0xb), 4),
	Write(0xc, DATA(0xc, 0xd, 0xe, 0xf), 4),
	Read(0x0),
	Read(0x4),
	Read(0x8),
	Read(0xc),
}));

TrafficDesc parallel2(merge({
	Write(0x10, DATA(0x10, 0x11, 0x12, 0x13), 4),
	Write(0x14, DATA(0x14, 0x15, 0x16, 0x17), 4),
	Write(0x18, DATA(0x18, 0x19, 0x1a, 0x1b), 4),
	Write(0x1c, DATA(0x1c, 0x1d, 0x1e, 0x1f), 4),
	Read(0x10),
		Expect(DATA(0x10, 0x11, 0x12, 0x13), 4),
	Read(0x14),
		Expect(DATA(0x14, 0x15, 0x16, 0x17), 4),
	Read(0x18),
		Expect(DATA(0x18, 0x19, 0x1a, 0x1b), 4),
	Read(0x1c),
		Expect(DATA(0x1c, 0x1d, 0x1e, 0x1f), 4),
}));

TrafficDesc parallel3(merge({
	Write(0x20, DATA(0x10, 0x11, 0x12, 0x13), 4),
	Write(0x24, DATA(0x14, 0x15, 0x16, 0x17), 4),
	Write(0x28, DATA(0x18, 0x19, 0x1a, 0x1b), 4),
	Write(0x2c, DATA(0x1c, 0x1d, 0x1e, 0x1f), 4),
	Read(0x20),
		Expect(DATA(0x10, 0x11, 0x12, 0x13), 4),
	Read(0x24),
		Expect(DATA(0x14, 0x15, 0x16, 0x17), 4),
	Read(0x28),
		Expect(DATA(0x18, 0x19, 0x1a, 0x1b), 4),
	Read(0x2c),
		Expect(DATA(0x1c, 0x1d, 0x1e, 0x1f), 4),
}));

TrafficDesc parallel4(merge({
	Read(0x0, 4),
	Read(0x4, 4),
	Read(0x8, 4),
	Read(0xc, 4),
}));
TrafficDesc parallel5(merge({
	Read(0x10, 4),
	Read(0x14, 4),
	Read(0x18, 4),
	Read(0x1c, 4),
}));

static std::vector<ITrafficDesc*> dts({
#if 0
#if AXI_DATA_WIDTH == 64
	&transfers_64
#endif
#endif
});

void DoneCallback(TLMTrafficGenerator *gen, int threadId)
{
	static std::vector<ITrafficDesc*>::iterator it = dts.begin();

	if (it != dts.end()) {
		gen->addTransfers((*it), 0, &DoneCallback);
		it++;
	} else {
		gen->addTransfers(parallel1, 0);
		gen->addTransfers(parallel2, 1);
		gen->addTransfers(parallel3, 2);

		gen->addTransfers(parallel4, 3);
		gen->addTransfers(parallel5, 4);
	}
}

void check_results()
{
	if (!transfers.done()) {
		SC_REPORT_ERROR("Transfers",
				"Failed executing transfers\n");
	}
}

AXILitePCConfig checker_config()
{
	AXILitePCConfig cfg;

	cfg.enable_all_checks();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	tlm2axilite_bridge<AXI_ADDR_WIDTH, AXI_DATA_WIDTH>
		tlm2axilite_bridge("tlm2axilite_bridge");

	axilite2tlm_bridge<AXI_ADDR_WIDTH, AXI_DATA_WIDTH>
		axilite2tlm_bridge("axilite2tlm_bridge");

	AXILiteSignals<AXI_ADDR_WIDTH, AXI_DATA_WIDTH>
		signals("axilite_signals");

	AXILiteProtocolChecker<AXI_ADDR_WIDTH, AXI_DATA_WIDTH>
		checker("checker", checker_config());

	trace_axilite<AXI_ADDR_WIDTH, AXI_DATA_WIDTH>
		trace("trace_axilite");

	TLMTrafficGenerator gen("gen", 5);
	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);
	memory mem("mem", sc_time(10, SC_NS), SZ_1K);

	gen.enableDebug();

	// Connect clk
	tlm2axilite_bridge.clk(clk);
	axilite2tlm_bridge.clk(clk);
	checker.clk(clk);
	trace.clk(clk);

	// Connect reset
	tlm2axilite_bridge.resetn(resetn);
	axilite2tlm_bridge.resetn(resetn);
	checker.resetn(resetn);
	trace.resetn(resetn);

	// Connect signals
	signals.connect(tlm2axilite_bridge);
	signals.connect(axilite2tlm_bridge);
	signals.connect(checker);
	signals.connect(trace);

	trace.print_all();

	// Connect tlm sockets
	gen.socket.bind(tlm2axilite_bridge.tgt_socket);
	axilite2tlm_bridge.socket.bind(mem.socket);

	gen.addTransfers(transfers, 0, DoneCallback);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, clk, clk.name());
	signals.Trace(trace_fp);

	sc_start(100, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	check_results();

	return 0;
}
