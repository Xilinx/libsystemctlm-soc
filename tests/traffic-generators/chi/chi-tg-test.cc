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

#include "tlm-bridges/tlm2chi-bridge-rnf.h"
#include "tlm-bridges/chi2tlm-bridge-rnf.h"
#include "tlm-bridges/tlm2chi-bridge-sn.h"
#include "tlm-bridges/chi2tlm-bridge-sn.h"
#include "traffic-generators/tg-tlm.h"
#include "test-modules/memory.h"
#include "test-modules/signals-rnf-chi.h"
#include "test-modules/signals-sn-chi.h"
#include "test-modules/utils-chi.h"

#include "tlm-modules/rnf-chi.h"
#include "tlm-modules/iconnect-chi.h"
#include "tlm-modules/sn-chi.h"

#include "checkers/pc-chi.h"

using namespace utils::CHI;

#define CACHE_SIZE (4 * CACHELINE_SZ)
#define RAM_SIZE (32 * CACHELINE_SZ)

#define NODE_ID_RNF0 0
#define NODE_ID_RNF1 1

#define NONSHAREABLE_START (28 * CACHELINE_SZ)
#define NONSHAREABLE_SZ (4 * CACHELINE_SZ)

#define LINE(l) (l * CACHELINE_SZ)

typedef CHISignals<
tlm2chi_bridge_rnf<>::TXREQ_FLIT_WIDTH,
tlm2chi_bridge_rnf<>::TXRSP_FLIT_WIDTH,
tlm2chi_bridge_rnf<>::TXDAT_FLIT_WIDTH,
tlm2chi_bridge_rnf<>::RXRSP_FLIT_WIDTH,
tlm2chi_bridge_rnf<>::RXDAT_FLIT_WIDTH,
tlm2chi_bridge_rnf<>::RXSNP_FLIT_WIDTH
> CHISignals_t;

typedef CHISignals_SN<
tlm2chi_bridge_sn<>::TXREQ_FLIT_WIDTH,
tlm2chi_bridge_sn<>::TXDAT_FLIT_WIDTH,
tlm2chi_bridge_sn<>::RXRSP_FLIT_WIDTH,
tlm2chi_bridge_sn<>::RXDAT_FLIT_WIDTH
> CHISignals_SN_t;

typedef CHIProtocolChecker<> CHIChecker_t;

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

	ExclusiveLoad(LINE(26), 4),
	ExclusiveStore(LINE(26), DATA(0x1, 0x2, 0x3, 0x4)),
	Read(LINE(26), 4),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4),

	// Test a failed exclusive
	ExclusiveStore(LINE(26), DATA(0x2, 0x4, 0x5, 0x6)),
	Read(LINE(26), 4),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4),

	DVMOperation(0),
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

template<typename T1, typename T2,
		typename T3, typename T4,
		typename T5,
		typename T6, typename T7>
void connect(T1& clk, T2& resetn,
		T3& rn, T4& tlm2chi_b,
		T5& signals,
		T6& chi2tlm_b, T7& port_RN_F)
{
	// Connect clk
	tlm2chi_b.clk(clk);
	chi2tlm_b.clk(clk);

	// Connect reset
	tlm2chi_b.resetn(resetn);
	chi2tlm_b.resetn(resetn);

	// Connect RN-F signals
	signals.connectRNF(&tlm2chi_b);

	// Connect ICN signals
	signals.connectICN(&chi2tlm_b);

	// Connect tlm2chi bridge on the RN
	rn.connect(tlm2chi_b);

	// Connect chi2tlm bridge to the interconnect port
	port_RN_F.connect(chi2tlm_b);
}

template<typename T1, typename T2,
		typename T3, typename T4,
		typename T5,
		typename T6, typename T7, typename T8>
void connect_sn(T1& clk, T2& resetn,
		T3& port_SN, T4& tlm2chi_b,
		T5& signals,
		T6& chi2tlm_b, T7& sn, T8& mem)
{
	// Connect clk
	tlm2chi_b.clk(clk);
	chi2tlm_b.clk(clk);

	// Connect reset
	tlm2chi_b.resetn(resetn);
	chi2tlm_b.resetn(resetn);

	// Connect ICN signals
	signals.connectICN(&tlm2chi_b);

	// Connect SN signals
	signals.connectSN(&chi2tlm_b);

	// Connect tlm2ace bridge on the master
	port_SN.connect(tlm2chi_b);

	// Connect chi2tlm bridge to the interconnect port
	sn.connect(chi2tlm_b);

	// Connect the slave node to the memory
	sn.init_socket(mem.socket);
}

void check_results()
{
	if (!transfers0.done()) {
		SC_REPORT_ERROR("Transfers0",
				"Failed executing transfers\n");
	}
}

CHIPCConfig checker_config()
{
	CHIPCConfig cfg;

	cfg.enable_all_checks();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	RequestNode_F<NODE_ID_RNF0, CACHE_SIZE> rnf0("rnf0", transfers0);
	RequestNode_F<NODE_ID_RNF1, CACHE_SIZE> rnf1("rnf1", transfers1);

	iconnect_chi<> icn("iconnect_chi");

	SlaveNode_F<> sn("sn");

	memory mem("mem", sc_time(10, SC_NS), RAM_SIZE);

	tlm2chi_bridge_rnf<> t2c_bridge0("tlm2chi_bridge0");
	tlm2chi_bridge_rnf<> t2c_bridge1("tlm2chi_bridge1");

	tlm2chi_bridge_sn<> t2c_bridge_sn("tlm2chi_bridge_sn");

	chi2tlm_bridge_rnf<> c2t_bridge0("chi2tlm_bridge0");
	chi2tlm_bridge_rnf<> c2t_bridge1("chi2tlm_bridge1");

	chi2tlm_bridge_sn<> c2t_bridge_sn("chi2tlm_bridge_sn");

	CHISignals_t signals0("chi_signals0");
	CHISignals_t signals1("chi_signals1");

	CHISignals_SN_t signals_sn("chi_signals_sn");

	CHIChecker_t checker0("chi_checker0", checker_config());
	CHIChecker_t checker1("chi_checker1", checker_config());

	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);

	rnf0.GetCache().CreateNonShareableRegion(
			NONSHAREABLE_START, NONSHAREABLE_SZ);

	//
	// Randomize transactions
	//
	rnf0.GetCache().RandomizeTransactions(true);
	rnf1.GetCache().RandomizeTransactions(true);

	//
	// Setup rnf0 with the interconnect
	//
	connect(clk, resetn,
		rnf0, t2c_bridge0,
		signals0,
		c2t_bridge0, *icn.port_RN_F[0]);

	rnf0.EnableDebug();

	//
	// Setup rnf1 with the interconnect
	//
	connect(clk, resetn,
		rnf1, t2c_bridge1,
		signals1,
		c2t_bridge1, *icn.port_RN_F[1]);

	//
	// Setup slave node to the interconnect and memory
	//
	connect_sn(clk, resetn,
		*icn.port_SN, t2c_bridge_sn,
		signals_sn,
		c2t_bridge_sn, sn, mem);

	//
	// Connect checker0
	//
	checker0.clk(clk);
	checker0.resetn(resetn);
	signals0.connectRNF(&checker0);

	//
	// Connect checker1
	//
	checker1.clk(clk);
	checker1.resetn(resetn);
	signals1.connectRNF(&checker1);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, clk, clk.name());

	signals0.Trace(trace_fp);
	signals1.Trace(trace_fp);
	signals_sn.Trace(trace_fp);

	sc_start(30, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	check_results();

	return 0;
}
