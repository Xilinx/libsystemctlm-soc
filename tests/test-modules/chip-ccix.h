/*
 * Copyright (c) 2020 Xilinx Inc.
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
#ifndef __CHIP_CCIX_H__
#define __CHIP_CCIX_H__

#include "tlm-bridges/tlm2chi-bridge-rnf.h"
#include "tlm-bridges/chi2tlm-bridge-rnf.h"
#include "tlm-bridges/tlm2chi-bridge-sn.h"
#include "tlm-bridges/chi2tlm-bridge-sn.h"

#include "tlm-bridges/tlm2cxs-bridge.h"

#include "test-modules/signals-rnf-chi.h"
#include "test-modules/signals-sn-chi.h"
#include "test-modules/signals-cxs.h"
#include "test-modules/utils.h"

#include "tlm-modules/rnf-chi.h"
#include "tlm-modules/iconnect-chi.h"
#include "tlm-modules/sn-chi.h"

#define CACHE_SIZE (4 * CACHELINE_SZ)
#define DEFAULT_RAM_SIZE (32 * CACHELINE_SZ)

namespace CCIX {

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

template<int RN_ID, int HN_ID,
		int RAM_SIZE = DEFAULT_RAM_SIZE,
		typename tlm2cxs_bridge_t = tlm2cxs_bridge<>>
SC_MODULE(Chip)
{
	enum {
		SN_ID = HN_ID - 10,

		CXS_DATA_W = tlm2cxs_bridge_t::FLIT_WIDTH,
		CXS_CNTL_W = tlm2cxs_bridge_t::CNTL_WIDTH,
	};

	//
	// RN-F <-> ICN signals
	//
	CHISignals_t signals_rnf;

	//
	// SlaveNode <-> ICN signals
	//
	CHISignals_SN_t signals_sn;

	//
	// RN-F
	//
	RequestNode_F<RN_ID,
			CACHE_SIZE,
			HN_ID> rnf;

	//
	// ICN
	//
	iconnect_chi<HN_ID,
		SN_ID,
		1,
		1> icn;

	//
	// RN-F <-> ICN bridges
	//
	tlm2chi_bridge_rnf<> t2c_bridge;
	chi2tlm_bridge_rnf<> c2t_bridge;

	//
	// SlaveNode <-> ICN bridges
	//
	tlm2chi_bridge_sn<> t2c_bridge_sn;
	chi2tlm_bridge_sn<> c2t_bridge_sn;

	//
	// TLM2CXS bridge
	//
	tlm2cxs_bridge_t cxs_bridge;

	//
	// SlaveNode with memory
	//
	SlaveNode_F<SN_ID> sn;
	memory mem;

	template<typename T>
	Chip(sc_module_name name, T& xfers,
		sc_clock& clk, sc_signal<bool>& resetn) :

		sc_module(name),

		signals_rnf("chi_signals"),
		signals_sn("chi_signals_sn"),

		rnf("rnf", xfers),
		icn("icn"),

		t2c_bridge("tlm2chi_bridge"),
		c2t_bridge("chi2tlm_bridge"),

		t2c_bridge_sn("tlm2chi_bridge_sn"),
		c2t_bridge_sn("chi2tlm_bridge_sn"),

		cxs_bridge("cxs_bridge"),

		sn("sn"),
		mem("mem", sc_time(10, SC_NS), RAM_SIZE)
	{
		//
		// Setup rnf with the interconnect
		//
		connect(clk, resetn,
			rnf, t2c_bridge,
			signals_rnf,
			c2t_bridge,
			*icn.port_RN_F[0],
			*icn.port_CCIX[0],
			cxs_bridge);

		//
		// Randomize transactions
		//
		rnf.GetCache().RandomizeTransactions(true);

		//
		// Setup slave node to the interconnect and memory
		//
		connect_sn(clk, resetn,
			*icn.port_SN, t2c_bridge_sn,
			signals_sn,
			c2t_bridge_sn, sn, mem);
	}

	void CreateNonShareableRegion(uint64_t start, unsigned int len)
	{
		rnf.GetCache().CreateNonShareableRegion(start, len);
	}

	void EnableDebug() { rnf.GetTrafficGenerator().enableDebug(); }

	template<typename T1, typename T2,
			typename T3, typename T4,
			typename T5,
			typename T6, typename T7,
			typename T8, typename T9>
	void connect(T1& clk, T2& resetn,
			T3& rn, T4& tlm2chi_b,
			T5& signals,
			T6& chi2tlm_b,
			T7& port_RN_F,
			T8& port_CCIX,
			T9& cxs_bridge)
	{
		// Connect clk
		tlm2chi_b.clk(clk);
		chi2tlm_b.clk(clk);
		cxs_bridge.clk(clk);

		// Connect reset
		tlm2chi_b.resetn(resetn);
		chi2tlm_b.resetn(resetn);
		cxs_bridge.resetn(resetn);

		// Connect RN-F signals
		signals.connectRNF(&tlm2chi_b);

		// Connect ICN signals
		signals.connectICN(&chi2tlm_b);

		// Connect tlm2chi bridge on the RN
		rn.connect(tlm2chi_b);

		// Connect chi2tlm bridge to the interconnect port
		port_RN_F.connect(chi2tlm_b);

		//
		// Connect ICN CCIX port to the TLM2CXS bridge
		//
		port_CCIX.txlink_init_socket(cxs_bridge.txlink_tgt_socket);
		cxs_bridge.rxlink_init_socket(port_CCIX.rxlink_tgt_socket);

		// Setup Port Node ID
		port_RN_F.SetNodeID(RN_ID);
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

	void Trace(sc_trace_file *trace_fp)
	{
		//
		// Trace CHI RN-F <-> ICN signals
		//
		signals_rnf.Trace(trace_fp);

		//
		// Trace CHI SN <-> ICN signals
		//
		signals_sn.Trace(trace_fp);
	}

	template<typename T>
	void ConnectTX(T& sgnls_cxs)
	{
		sgnls_cxs.connectTX(&cxs_bridge);
	}

	template<typename T>
	void ConnectRX(T& sgnls_cxs)
	{
		sgnls_cxs.connectRX(&cxs_bridge);
	}
};

}; // namespace CCIX

#endif
