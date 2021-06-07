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
#include "traffic-generators/config-parser/parserfacade.h"
#include "traffic-generators/config-parser/commandlineparser.h"
#include "checkers/pc-axi.h"
#include "test-modules/memory.h"
#include "test-modules/signals-axi.h"
#include "test-modules/utils.h"
#include "test-modules/trace-axi.h"

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

static std::vector<ITrafficDesc*> tds;
static std::vector<ITrafficDesc*>::iterator tdsIt;

void SetupTraffic(TLMTrafficGenerator *gen, int threadId)
{
	if (tdsIt != tds.end()) {
		gen->addTransfers((*tdsIt), threadId, &SetupTraffic);
		tdsIt++;
	}
}

AXIPCConfig checker_config()
{
	AXIPCConfig cfg(version);

	cfg.enable_all_checks();

	return cfg;
}

void CreateTrafficDesc(CmdLineParser& p)
{
	for (auto& cfg: p.getConfigs()) {
		DataTransferVec transfers;

		if (ParserFacade::Deserialize(transfers, cfg.c_str())) {
			tds.push_back(new TrafficDesc(transfers));

			if (p.getDebugModeStatus()) {
				for (auto t: transfers) {
					cout << t << endl;
				}
			}

		} else {
			std::ostringstream msg;
			msg << "config-parser error on " << cfg << ": "
				<< ParserFacade::getLastErrorDescription() << endl;

			throw std::runtime_error(msg.str());
		}
	}
	tdsIt = tds.begin();
}

template<typename T>
void SetupTrace(CmdLineParser& parser, T& trace)
{
	if (parser.get_ar()) {
		trace.print_ar();
	}
	if (parser.get_rr()) {
		trace.print_rr();
	}
	if (parser.get_aw()) {
		trace.print_aw();
	}
	if (parser.get_w()) {
		trace.print_w();
	}
	if (parser.get_b()) {
		trace.print_b();
	}
}

int sc_main(int argc, char *argv[])
{
	CmdLineParser& parser = CmdLineParser::InstanceCmdLineParser(argc, argv);

	tlm2axi_bridge<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		tlm2axi_bridge("tlm2axi_bridge", version, false);

	axi2tlm_bridge<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		axi2tlm_bridge("axi2tlm_bridge", version);

	AXIProtocolChecker<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		checker("checker", checker_config());

	AXISignals<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
			AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		signals("axi_signals", version);

	trace_axi<AXI_ADDR_WIDTH, AXI_DATA_WIDTH, AXI_ID_WIDTH,
		AXI_AXLEN_WIDTH, AXI_AXLOCK_WIDTH>
		trace("trace_axi");

	TLMTrafficGenerator gen("gen", 5);
	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);
	memory mem("mem", sc_time(10, SC_NS), SZ_1K);

	CreateTrafficDesc(parser);

	if (parser.getDebugTraffic()) {
		gen.enableDebug();
	}

	SetupTraffic(&gen, 0);

	SetupTrace(parser, trace);

	// Connect clk
	tlm2axi_bridge.clk(clk);
	axi2tlm_bridge.clk(clk);
	checker.clk(clk);
	trace.clk(clk);

	// Connect reset
	tlm2axi_bridge.resetn(resetn);
	axi2tlm_bridge.resetn(resetn);
	checker.resetn(resetn);
	trace.resetn(resetn);

	// Connect signals
	signals.connect(tlm2axi_bridge);
	signals.connect(checker);
	signals.connect(axi2tlm_bridge);
	signals.connect(trace);

	// Connect tlm sockets
	gen.socket.bind(tlm2axi_bridge.tgt_socket);
	axi2tlm_bridge.socket.bind(mem.socket);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, clk, clk.name());
	signals.Trace(trace_fp);

	sc_start(100, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	for (auto* td: tds) {
		delete td;
	}
	tds.clear();

	return 0;
}
