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
#include "traffic-generators/random-traffic.h"
#include "test-modules/memory.h"
#include "test-modules/signals-rnf-chi.h"
#include "test-modules/signals-sn-chi.h"
#include "test-modules/utils.h"

#include "tlm-modules/rnf-chi.h"
#include "tlm-modules/iconnect-chi.h"
#include "tlm-modules/sn-chi.h"

#include "checkers/pc-chi.h"

using namespace utils;

#define CACHE_SIZE (4 * CACHELINE_SZ)
#define RAM_SIZE (32 * CACHELINE_SZ)

#define NODE_ID_RNF0 0
#define NODE_ID_RNF1 1

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

CHIPCConfig checker_config()
{
	CHIPCConfig cfg;

	cfg.enable_all_checks();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	uint64_t max_addr = RAM_SIZE;
	RandomTraffic transfers0(0, max_addr, (~(0x3llu)),
					1, max_addr, max_addr, 100000);
	RandomTraffic transfers1(0, max_addr, (~(0x3llu)),
					1, max_addr, max_addr, 100000);

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

	sc_start(2000, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	return 0;
}
