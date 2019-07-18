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

#include "tlm-bridges/tlm2tri-bridge.h"
#include "tlm-bridges/tri2tlm-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "tlm-modules/master-tri.h"
#include "test-modules/memory.h"
#include "test-modules/utils.h"
#include "test-modules/signals-tri.h"

using namespace utils;

#ifndef CACHELINE_SIZE
#define CACHELINE_SIZE 64
#endif

#define CACHE_SIZE (4 * CACHELINE_SIZE)
#define RAM_SIZE (32 * CACHELINE_SIZE)

#define LINE(l) (l * CACHELINE_SIZE)

typedef TRIMaster<
	CACHE_SIZE,
	CACHELINE_SIZE
> TRIMaster_t;

TrafficDesc transfers0(merge({
	// Round 1

	// Cacheline 1
	Write(LINE(1), DATA(0xFF, 0xFF, 0xFF, 0xFF)),
	Read(LINE(1)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	Write(LINE(1), DATA(0xFF, 0xFF, 0xFF, 0xFF)),
	Read(LINE(1)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	Write(LINE(2), DATA(0x1, 0x2, 0x3, 0x4)),
	Read(LINE(2)),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4),

	Write(LINE(3), DATA(0x4, 0x5, 0x6, 0x7, 0x4, 0x5, 0x6, 0x7)),
	Read(LINE(3)),
		Expect(DATA(0x4, 0x5, 0x6, 0x7, 0x4, 0x5, 0x6, 0x7), 8),
}));

void check_results()
{
	if (!transfers0.done()) {
		SC_REPORT_ERROR("Transfers0",
				"Failed executing transfers\n");
	}

	cout << " -- All transfers done!" << endl;
}

int sc_main(int argc, char *argv[])
{
	TRIMaster_t master("tri-master", transfers0);

	memory mem("mem", sc_time(10, SC_NS), RAM_SIZE);

	tlm2tri_bridge tlm2tri("tlm2tri-bridge");
	tri2tlm_bridge tri2tlm("tri2tlm-bridge");

	TRISignals signals("signals");

	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);

	tlm2tri.clk(clk);
	tri2tlm.clk(clk);
	tlm2tri.resetn(resetn);
	tri2tlm.resetn(resetn);

	master.enableDebug();

	// Connect tlm2ace bridge on the master
	master.m_port.init_socket.bind(tlm2tri.tgt_socket);

	signals.connect(tlm2tri);
	signals.connect(tri2tlm);

	tri2tlm.socket(mem.socket);	

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, clk, clk.name());
	sc_trace(trace_fp, resetn, resetn.name());

	signals.Trace(trace_fp);

	sc_start(20, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	check_results();

	return 0;
}
