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
#include <string>
#include <sstream>
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
#include "tlm-modules/tlm-splitter.h"
#include "checkers/pc-axi.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/random-traffic.h"
#include "test-modules/memory.h"
#include "test-modules/signals-axi.h"
#include "test-modules/trace-axi.h"

#define RAM_SIZE (8 * 1024)

#ifdef __AXI_VERSION_AXI3__
static const AXIVersion version = V_AXI3;
#define AXI_AXLOCK_WIDTH 2
#define AXI_AXLEN_WIDTH  4
#else
static const AXIVersion version = V_AXI4;
#define AXI_AXLOCK_WIDTH 1
#define AXI_AXLEN_WIDTH  8
#endif

AXIPCConfig checker_config()
{
	AXIPCConfig cfg;

	cfg.enable_all_checks();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	uint64_t max_addr = AXI_ADDR_WIDTH > 19 ? RAM_SIZE : (1 << AXI_ADDR_WIDTH);
	RandomTraffic transfers(0, max_addr, (~(0x3llu)), 1, max_addr, max_addr, 12000);
	tlm2axi_bridge<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		tlm2axi_bridge("tlm2axi_bridge");
	axi2tlm_bridge<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		axi2tlm_bridge("axi2tlm_bridge");
	tlm_splitter<2> splitter("splitter", true);
	AXIProtocolChecker<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		checker("checker", checker_config());
	memory mem("mem", sc_time(10, SC_NS), RAM_SIZE);
	memory ref_mem("ref_mem", sc_time(10, SC_NS), RAM_SIZE);
	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);
	TLMTrafficGenerator gen("gen");
	AXISignals<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
		AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		signals("axi_signals");
	trace_axi<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
		AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		trace("trace_axi");

//	gen.enableDebug();

	trace.print_ar();
	trace.print_aw();

	// Connect clk
	tlm2axi_bridge.clk(clk);
	axi2tlm_bridge.clk(clk);
	checker(clk);
	trace.clk(clk);

	// Connect reset
	tlm2axi_bridge.resetn(resetn);
	axi2tlm_bridge.resetn(resetn);
	checker.resetn(resetn);
	trace.resetn(resetn);

	// Connect signals
	signals.connect(tlm2axi_bridge);
	signals.connect(axi2tlm_bridge);
	signals.connect(checker);
	signals.connect(trace);

	// Connect tlm sockets
	gen.socket.bind(splitter.target_socket);
	splitter.i_sk[0]->bind(tlm2axi_bridge.tgt_socket);
	axi2tlm_bridge.socket.bind(mem.socket);
	splitter.i_sk[1]->bind(ref_mem.socket);

	gen.addTransfers(transfers);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);
	sc_trace(trace_fp, clk, clk.name());
	signals.Trace(trace_fp);

	sc_start(2000, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	return 0;
}
