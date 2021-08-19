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

#include "test-modules/memory.h"
#include "test-modules/chip-ccix.h"
#include "test-modules/signals-cxs.h"
#include "test-modules/utils-chi.h"

using namespace utils::CHI;

#define RN0_ID 0
#define HN0_ID 20

#define RN1_ID 1
#define HN1_ID 21

#define NONSHAREABLE_START (28 * CACHELINE_SZ)
#define NONSHAREABLE_SZ (4 * CACHELINE_SZ)

#define LINE(l) ((l) * CACHELINE_SZ)

typedef Chip<RN0_ID, HN0_ID> Chip0_t;
typedef Chip<RN1_ID, HN1_ID> Chip1_t;

typedef CXSSignals<
Chip0_t::CXS_DATA_W,
Chip0_t::CXS_CNTL_W
> CXSSignals_t;

const unsigned char burst_data[140] = {
	0x11, 0x12, 0x13, 0x14, 0x21, 0x22, 0x23, 0x24,
	0x21, 0x22, 0x23, 0x24, 0x31, 0x32, 0x33, 0x34,
	0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x43, 0x44,
	0x41, 0x42, 0x43, 0x44, 0x51, 0x52, 0x53, 0x54,

	0x11, 0x12, 0x13, 0x14, 0x21, 0x22, 0x23, 0x24,
	0x21, 0x22, 0x23, 0x24, 0x31, 0x32, 0x33, 0x34,
	0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x43, 0x44,
	0x41, 0x42, 0x43, 0x44, 0x51, 0x52, 0x53, 0x54
};

TrafficDesc transfers0(merge({
	//
	// ReadUnique
	// line[0]
	//
	Write(LINE(0), DATA(0xFF, 0xFF, 0xFF, 0xFF)),
	Read(LINE(0)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	//
	// WriteBackFull + MakeUnique
	// line[0]
	//
	Write(LINE(4), burst_data, CACHELINE_SZ),
	Read(LINE(4), CACHELINE_SZ),
		Expect(burst_data, CACHELINE_SZ),

	// ReadShared
	// line[2]
	Read(LINE(2)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	// Read what rnf1 wrote back
	// line[1]
	Read(LINE(13)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	//
	// Evict + ReadShared + Evict + MakeUnique
	// line[1]
	//
	Read(LINE(1)),
	Write(LINE(5), burst_data, CACHELINE_SZ),

	// nop
	// line[2]
	Read(LINE(2)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	//
	// SnpSharedFwd (addr is in the other cache)
	// line[1]
	//
	Read(LINE(17), CACHELINE_SZ),
		Expect(&burst_data[32], CACHELINE_SZ),

	// CleanUnique
	// line[1]
	Write(LINE(17), burst_data, CACHELINE_SZ),

	// SnpSharedFwd second time
	// line[3]
	Read(LINE(15)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	// CleanUnique second time
	// line[3]
	Write(LINE(15), burst_data, CACHELINE_SZ),

	// WriteNoSnpFull
	Write(LINE(28), &burst_data[32], CACHELINE_SZ),

	// ReadNoSnp
	Read(LINE(28), CACHELINE_SZ),
		Expect(&burst_data[32], CACHELINE_SZ),

	// WriteNoSnpPtl
	Write(LINE(28), &burst_data[4], 8),

	// ReadNoSnp
	Read(LINE(28), 8),
		Expect(&burst_data[4], 8),

	// AtomicStore
	AtomicStore(LINE(27) + 2, DATA(0x0, 0x1), 2),

	// AtomicLoad
	AtomicLoad(LINE(27) + 2, DATA(0x0, 0x1), 2),
		Expect(DATA(0x0, 0x1), 2),

	// AtomicStore
	AtomicStore(LINE(27), DATA(0x1), 1),

	// AtomicLoad
	AtomicLoad(LINE(27), DATA(0x1), 1),
		Expect(DATA(0x1), 1),

	AtomicLoad(LINE(27), DATA(0x1), 1),
		Expect(DATA(0x2), 1),

	Write(LINE(27), DATA(0x0, 0x0), 2),
	Read(LINE(3)),

	AtomicLoad(LINE(27), DATA(0x0, 0x1), 2),
		Expect(DATA(0x0, 0x0), 2),

	AtomicLoad(LINE(27), DATA(0x1, 0x1), 2),
		Expect(DATA(0x0, 0x1), 2),
	AtomicLoad(LINE(27), DATA(0x0, 0x1), 2),
		Expect(DATA(0x1, 0x2), 2),
	AtomicLoad(LINE(27), DATA(0xFF, 0xFF), 2, Req::Atomic::CLR),
		Expect(DATA(0x1, 0x3), 2),

	AtomicSwap(LINE(27), DATA(0xFF, 0xFF), 2),
		Expect(DATA(0x0, 0x0), 2),
	AtomicSwap(LINE(27), DATA(0x0, 0x0), 2),
		Expect(DATA(0xFF, 0xFF), 2),

	AtomicCompare(LINE(27), DATA(0x0, 0x0, 0xFF, 0xFF), 4),
		Expect(DATA(0x0, 0x0), 2),
	AtomicCompare(LINE(27), DATA(0xFF, 0xFF, 0x0, 0x0), 4),
		Expect(DATA(0xFF, 0xFF), 2),

	AtomicCompare(LINE(27)+8, DATA(0x0, 0x0, 0xFF, 0xFF), 4),
		Expect(DATA(0x00, 0x00), 2),
}));

TrafficDesc transfers1(merge({
	// ReadUnique
	// line[1]
	Write(LINE(13), DATA(0xFF, 0xFF, 0xFF, 0xFF)),
	Read(LINE(13)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	// WriteBackFull + MakeUnique
	// line[1]
	Write(LINE(17), &burst_data[32], CACHELINE_SZ),
	Read(LINE(17), CACHELINE_SZ),
		Expect(&burst_data[32], CACHELINE_SZ),


	// Read what rnf0 wrote back
	// line[0]
	Read(LINE(0)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	// snoop rnf0
	// line[0]
	Read(LINE(4)),
		Expect(&burst_data[0], CACHELINE_SZ),

	//
	// ReadShared + Evict + MakeUnique
	// line[0]
	//
	Read(LINE(12)),
	Write(LINE(16), &burst_data[32], CACHELINE_SZ),

	// ReadShared
	// line[3]
	Read(LINE(15)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	// SnpSharedFwd
	// line[0]
	Read(LINE(4), CACHELINE_SZ),
		Expect(burst_data, CACHELINE_SZ),

	// CleanUnique
	// line[0]
	Write(LINE(4), &burst_data[32], CACHELINE_SZ),

	// SnpSharedFwd second time
	// line[2]
	Read(LINE(2)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	// CleanUnique second time
	// line[2]
	Write(LINE(2), &burst_data[32], CACHELINE_SZ),
}));

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
}

int sc_main(int argc, char *argv[])
{
	unsigned int ram_sz = DEFAULT_RAM_SIZE;

	CXSSignals_t sgnls_cxs0("cxs_signals0");
	CXSSignals_t sgnls_cxs1("cxs_signals1");

	sc_signal<bool> resetn("resetn", true);
	sc_clock clk("clk", sc_time(20, SC_US));

	Chip0_t chip0("chip0", transfers0, clk, resetn);
	Chip1_t chip1("chip1", transfers1, clk, resetn);

	sc_trace_file *trace_fp = NULL;

	//
	// Configure the System Address Map on HN0 (memory is handled by HN1)
	//
	chip0.icn.SystemAddressMap().AddMap(0, ram_sz, HN1_ID);

	//
	// Configure the CCIX port on chip 0
	//
	chip0.icn.port_CCIX[0]->AddRemoteAgent(RN1_ID);
	chip0.icn.port_CCIX[0]->AddRemoteAgent(HN1_ID);

	chip0.CreateNonShareableRegion(NONSHAREABLE_START, NONSHAREABLE_SZ);

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
	// Connect RX Chip0 and TX chip1
	//
	sgnls_cxs1.connectRX(&chip0.cxs_bridge);
	sgnls_cxs1.connectTX(&chip1.cxs_bridge);

	chip0.EnableDebug();
	chip1.EnableDebug();

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
	sc_start(20, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	check_results();

	return 0;
}
