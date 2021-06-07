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

#include "tlm-bridges/tlm2axi-bridge.h"
#include "tlm-bridges/axi2tlm-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "checkers/pc-axi.h"
#include "test-modules/memory.h"
#include "test-modules/signals-axi.h"
#include "test-modules/utils.h"

using namespace utils;

#define SZ_1K 1024

#ifdef __AXI_VERSION_AXI3__
static const AXIVersion version = V_AXI3;
#define AXI_AXLOCK_WIDTH 2
#define AXI_AXLEN_WIDTH  4
#else
static const AXIVersion version = V_AXI4;
#define AXI_AXLOCK_WIDTH 1
#define AXI_AXLEN_WIDTH  8
#endif

const unsigned char burst_data[] = {
	0x11, 0x12, 0x13, 0x14, 0x21, 0x22, 0x23, 0x24,
	0x21, 0x22, 0x23, 0x24, 0x31, 0x32, 0x33, 0x34,
	0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x43, 0x44,
	0x41, 0x42, 0x43, 0x44, 0x51, 0x52, 0x53, 0x54
};

TrafficDesc transfers(merge({
	Read(0x0),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	Write(0x0, DATA(0xff, 0xff, 0xff, 0xff)),

	Read(0x0),
		Expect(DATA(0xff, 0xff, 0xff, 0xff), 4),

	/* With gen_attr */
	Write(0x0, DATA(0x0, 0x1, 0x2, 0x3)),
		GenAttr(0x10, true, true),

	Read(0x0),
		Expect(DATA(0x0, 0x1, 0x2, 0x3), 4),
		GenAttr(0x10, true, true),

	/* Burst tests */
	Write(0x0, burst_data, 8),
	Read(0x0, 8),
		Expect(burst_data, 8),

	Write(0x0, burst_data, 16),
	Read(0x0, 16),
		Expect(burst_data, 16),

	Write(0x0, burst_data, 32),
	Read(0x0, 32),
		Expect(burst_data, 32),
}));


TrafficDesc narrowTransfers(merge({
	/* Narrow transfers */
	Write(0x0, DATA(0x5), 1),
	Read(0x0, 1),
		Expect(DATA(0x5), 1),

	Write(0x0, DATA(0x3, 0x4), 2),
	Read(0x0, 2),
		Expect(DATA(0x3, 0x4), 2),

	Write(0x0, DATA(0x2, 0x3, 0x4), 3),
	Read(0x0, 3),
		Expect(DATA(0x2, 0x3, 0x4), 3),
}));

TrafficDesc unalignedTransfers(merge({
	/* Unaligned transfers */
	Write(0x1, DATA(0x5), 1),
	Read(0x1, 1),
		Expect(DATA(0x5), 1),
	Write(0x1, DATA(0x3, 0x4), 2),
	Read(0x1, 2),
		Expect(DATA(0x3, 0x4), 2),
	Write(0x1, DATA(0x2, 0x3, 0x4), 3),
	Read(0x1, 3),
		Expect(DATA(0x2, 0x3, 0x4), 3),
	Write(0x1, DATA(0x0, 0x1, 0x2, 0x3)),
	Read(0x1),
		Expect(DATA(0x0, 0x1, 0x2, 0x3), 4),

	Write(0x2, DATA(0x5), 1),
	Read(0x2, 1),
		Expect(DATA(0x5), 1),
	Write(0x2, DATA(0x3, 0x4), 2),
	Read(0x2, 2),
		Expect(DATA(0x3, 0x4), 2),

	Write(0x2, DATA(0x2, 0x3, 0x4), 3),
	Read(0x2, 3),
		Expect(DATA(0x2, 0x3, 0x4), 3),
	Write(0x2, DATA(0x0, 0x1, 0x2, 0x3)),
	Read(0x2),
		Expect(DATA(0x0, 0x1, 0x2, 0x3), 4),

	Write(0x3, DATA(0x5), 1),
	Read(0x3, 1),
		Expect(DATA(0x5), 1),
	Write(0x3, DATA(0x3, 0x4), 2),
	Read(0x3, 2),
		Expect(DATA(0x3, 0x4), 2),

	Write(0x3, DATA(0x2, 0x3, 0x4), 3),
	Read(0x3, 3),
		Expect(DATA(0x2, 0x3, 0x4), 3),
	Write(0x3, DATA(0x0, 0x1, 0x2, 0x3)),
	Read(0x3),
		Expect(DATA(0x0, 0x1, 0x2, 0x3), 4),
}));

TrafficDesc exclusiveTransfers(merge({
	Read(0x0),
		GenAttr(0x10, true, true, false, 0, 0, true),
	Write(0x0, DATA(0x10, 0x11, 0x12, 0x13)),
		GenAttr(0x10, true, true, false, 0, 0, true),

	/* Locked transfers */
	Read(0x0),
		GenAttr(0x10, true, true, false, 0, 0, false, true),
	Write(0x0, DATA(0x10, 0x11, 0x12, 0x13)),
		GenAttr(0x10, true, true, false, 0, 0, false, true),
}));

TrafficDesc memAttrTransfers(merge({
	Read(0x0),
		GenAttr(0x10, true, true, false, 0, 0, false, false,
			false,	// bufferable
			true,	// modifiable
			true,	// read_allocate
			true),	// write_allocate

	Write(0x0, DATA(0x10, 0x11, 0x12, 0x13)),
		GenAttr(0x10, true, true, false, 0, 0, false, false,
			false,	// bufferable
			true,	// modifiable
			true,	// read_allocate
			true),	// write_allocate
}));

TrafficDesc qosTransfers(merge({
	Read(0x0),
		GenAttr(0x10, true, true, false, 0, 0, false, false,
			false,	// bufferable
			true,	// modifiable
			true,	// read_allocate
			true,	// write_allocate
			3),
	Write(0x0, DATA(0x10, 0x11, 0x12, 0x13)),
		GenAttr(0x10, true, true, false, 0, 0, false, false, 4,
			false,	// bufferable
			true,	// modifiable
			true,	// read_allocate
			true,	// write_allocate
			3),
}));

TrafficDesc regionTransfers(merge({
	Read(0x0),
		GenAttr(0x10, true, true, false, 0, 0, false, false,
			false,	// bufferable
			true,	// modifiable
			true,	// read_allocate
			true,	// write_allocate
			3, 2),
	Write(0x0, DATA(0x10, 0x11, 0x12, 0x13)),
		GenAttr(0x10, true, true, false, 0, 0, false, false,
			false,	// bufferable
			true,	// modifiable
			true,	// read_allocate
			true,	// write_allocate
			3, 2),
}));

TrafficDesc parallel1(merge({
	Write(0x0, DATA(0x0, 0x1, 0x2, 0x3)),
	Write(0x4, DATA(0x4, 0x5, 0x6, 0x7)),
	Write(0x8, DATA(0x8, 0x9, 0xa, 0xb)),
	Write(0xc, DATA(0xc, 0xd, 0xe, 0xf)),
	Read(0x0),
	Read(0x4),
	Read(0x8),
	Read(0xc),
}));

TrafficDesc parallel2(merge({
	Write(0x10, DATA(0x10, 0x11, 0x12, 0x13)),
	Write(0x14, DATA(0x14, 0x15, 0x16, 0x17)),
	Write(0x18, DATA(0x18, 0x19, 0x1a, 0x1b)),
	Write(0x1c, DATA(0x1c, 0x1d, 0x1e, 0x1f)),
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
	Write(0x20, DATA(0x10, 0x11, 0x12, 0x13)),
	Write(0x24, DATA(0x14, 0x15, 0x16, 0x17)),
	Write(0x28, DATA(0x18, 0x19, 0x1a, 0x1b)),
	Write(0x2c, DATA(0x1c, 0x1d, 0x1e, 0x1f)),
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
	Read(0x0), Read(0x4), Read(0x8), Read(0xc),
}));
TrafficDesc parallel5(merge({
	Read(0x10), Read(0x14), Read(0x18), Read(0x1c),
}));


static std::vector<ITrafficDesc*> dts({
	&narrowTransfers,
	&unalignedTransfers,
	&exclusiveTransfers,
	&memAttrTransfers,
	&qosTransfers,
	&regionTransfers
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

	if (!narrowTransfers.done()) {
		SC_REPORT_ERROR("Narrow Transfers",
				"Failed executing transfers\n");
	}

	if (!unalignedTransfers.done()) {
		SC_REPORT_ERROR("Unaligned Transfers",
				"Failed executing transfers\n");
	}

	if (!exclusiveTransfers.done()) {
		SC_REPORT_ERROR("Exclusive Transfers",
				"Failed executing transfers\n");
	}

	if (!memAttrTransfers.done() ) {
		SC_REPORT_ERROR("MemAttr Transfers",
				"Failed executing transfers\n");
	}

	if (!parallel1.done() || !parallel2.done() ||
		!parallel3.done() || !parallel4.done()) {
		SC_REPORT_ERROR("Parallel processing",
				"Failed executing transfers\n");
	}
}

AXIPCConfig checker_config()
{
	AXIPCConfig cfg(version);

	cfg.enable_all_checks();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	tlm2axi_bridge<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		tlm2axi_bridge("tlm2axi_bridge", version);

	axi2tlm_bridge<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		axi2tlm_bridge("axi2tlm_bridge", version);

	AXIProtocolChecker<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		checker("checker", checker_config());

	AXISignals<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		signals("axi_signals", version);

	TLMTrafficGenerator gen("gen", 5);
	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);
	memory mem("mem", sc_time(10, SC_NS), SZ_1K);

	gen.enableDebug();

	// Connect clk
	tlm2axi_bridge.clk(clk);
	axi2tlm_bridge.clk(clk);
	checker.clk(clk);

	// Connect reset
	tlm2axi_bridge.resetn(resetn);
	axi2tlm_bridge.resetn(resetn);
	checker.resetn(resetn);

	// Connect signals
	signals.connect(tlm2axi_bridge);
	signals.connect(checker);
	signals.connect(axi2tlm_bridge);

	// Connect tlm sockets
	gen.socket.bind(tlm2axi_bridge.tgt_socket);
	axi2tlm_bridge.socket.bind(mem.socket);

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
