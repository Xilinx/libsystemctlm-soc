/*
 * Copyright (c) 2018 Xilinx Inc.
 * Written by Francisco Iglesias
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

#include "tlm-modules/tlm-exmon.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "test-modules/memory.h"
#include "test-modules/utils.h"

using namespace utils;

#define GENATTR(id, exclusive) \
GenAttr(0, false, false, false, 0, id, exclusive)

DataTransferVec transactions = {
	//
	// Non exclusive accesses
	//
        Write(0, DATA(0x1, 0x2, 0x3, 0x4)),
        Read(0),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4),

        Write(0, DATA(0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
		      0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
		      0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
		      0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0), 32),
        Read(0, 32),
		Expect(DATA(
			0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
			0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
			0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
			0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0), 32),

	//
	// Exclusive read write 0
	//
        Read(0),
		GENATTR(0x0, true),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

        Write(0, DATA(0x0, 0x0, 0x0, 0x1)),
		GENATTR(0x0, true),

        Read(0),
		Expect(DATA(0x0, 0x0, 0x0, 0x1), 4),

	//
	// Other master writes before exclusive write
	//
        Read(4),
		GENATTR(0x0, true),

	// other transaction id non exclusive
        Write(4, DATA(0x5, 0x6, 0x7, 0x8)),
		GENATTR(0x11, false),

        Write(4, DATA(0x0, 0x0, 0x0, 0x0)),
		GENATTR(0x0, true),

        Read(4),
		Expect(DATA(0x5, 0x6, 0x7, 0x8), 4),

	//
	// reset monitored arid before the exclusive write
	//
        Read(8),
		GENATTR(0x0, true),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	// reset monitored arid
        Read(4),
		GENATTR(0x0, true),

        Write(8, DATA(0x0, 0x0, 0x0, 0x0)),
		GENATTR(0x0, true),

        Read(8),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),
	//
	// Monitor 2 arids at the same time
	//
        Read(12),
		GENATTR(0x0, true),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

        Read(16),
		GENATTR(0x1, true),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

        Write(12, DATA(0x1, 0x1, 0x1, 0x1)),
		GENATTR(0x0, true),

        Write(16, DATA(0x2, 0x2, 0x2, 0x2)),
		GENATTR(0x1, true),

        Read(12),
		Expect(DATA(0x1, 0x1, 0x1, 0x1), 4),

        Read(16),
		Expect(DATA(0x2, 0x2, 0x2, 0x2), 4),
};

SC_MODULE(Dut)
{
public:
	enum { RamSize = 256 * 1024 };

	Dut(sc_module_name name, DataTransferVec &transfers) :
		tg("tg"),
		exmon("exclusive_monitor", 0x1), // Monitor max 2 ids
		ram("ram", sc_time(1, SC_NS), RamSize),
		xfers(merge(transfers))
	{
		tg.enableDebug();
		tg.addTransfers(xfers, 0);

		// tg -> exmon -> ram
		tg.socket.bind(exmon.target_socket);
		exmon.init_socket.bind(ram.socket);
	}

private:
	TLMTrafficGenerator tg;
	tlm_exclusive_monitor exmon;
	memory ram;
	TrafficDesc xfers;
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
