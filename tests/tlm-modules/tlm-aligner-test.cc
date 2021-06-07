/*
 * Copyright (c) 2018 Xilinx Inc.
 * Written by Edgar E. Iglesias
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
#include <sstream>
#include <vector>
#include <array>

#include <stdio.h>
#include <stdlib.h>

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "tlm-bridges/tlm2axi-bridge.h"

#include "tlm-modules/tlm-aligner.h"
#include "tlm-modules/tlm-splitter.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/random-traffic.h"
#include "traffic-generators/traffic-desc.h"
#include "test-modules/memory.h"
#include "test-modules/utils.h"
#include "test-modules/signals-axi.h"

using namespace utils;

DataTransferVec transactions = {
        Write(28, DATA(0x1, 0x2, 0x3, 0x4)),
        Write(32, DATA(0x5, 0x6, 0x7, 0x8)),
        Read(28, 8),
        Read(0, 32),
        Read(0, 4),
};

SC_MODULE(Dut)
{
public:
	Dut(sc_module_name name, DataTransferVec &transfers,
		unsigned int ram_size = 256 * 1024) :
		xfers(merge(transfers)),
		rand_xfers(0, ram_size - 1024, UINT64_MAX, 1, ram_size, ram_size, 1000),
		splitter("splitter", true),
		tg("tg", 1),
		bridge("tlm2axi_bridge"),
		signals("signals_axi"),
		clk("clk"),
		rst_n("rst_n", true),
		aligner("aligner", 64, 32, 4 * 1024, true, &bridge),
		ram("ram", sc_time(1, SC_NS), ram_size),
		ref_ram("ref_ram", sc_time(1, SC_NS), ram_size)
	{
		target_socket.register_b_transport(this, &Dut::b_transport);

//		tg.enableDebug();
		tg.addTransfers(xfers, 0);
		tg.addTransfers(rand_xfers, 0);

		// TG feeds the aligner who in turn loops back to Dut module.  */
		tg.socket.bind(splitter.target_socket);

		splitter.i_sk[0]->bind(aligner.target_socket);
		splitter.i_sk[1]->bind(ref_ram.socket);

		aligner.init_socket.bind(target_socket);
		init_socket.bind(ram.socket);

		// Dummy connections on the bridge
		dummy_socket(bridge.tgt_socket);
		bridge.clk(clk);
		bridge.resetn(rst_n);
		signals.connect(bridge);
	}

private:
	TrafficDesc xfers;
	RandomTraffic rand_xfers;

	tlm_utils::simple_initiator_socket<Dut> init_socket;
	tlm_utils::simple_target_socket<Dut> target_socket;
	tlm_splitter<2> splitter;
	TLMTrafficGenerator tg;

	// Run with the TLM to AXI bridge's validate function
	tlm2axi_bridge<32, 32> bridge;

	// Dummy connections for the bridge
	tlm_utils::simple_initiator_socket<Dut> dummy_socket;
	AXISignals<32, 32> signals;
	sc_signal<bool> clk;
	sc_signal<bool> rst_n;

	tlm_aligner aligner;
	memory ram;

	memory ref_ram;

	virtual void b_transport(tlm::tlm_generic_payload &trans, sc_time &delay)
	{
		// Apply checks?
		init_socket->b_transport(trans, delay);
	}
};

SC_MODULE(Top)
{
	Dut dut;

	Top(sc_module_name name,
	    DataTransferVec &transfers_dut) :
		dut("dut", transfers_dut)
	{ }
};

int sc_main(int argc, char *argv[])
{
	Top top("Top", transactions);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);
	sc_start(100, SC_MS);
	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
	return 0;
}
