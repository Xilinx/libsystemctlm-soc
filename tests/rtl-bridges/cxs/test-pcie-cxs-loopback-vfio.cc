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

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "tlm-bridges/tlm2chi-bridge-rnf.h"
#include "tlm-bridges/chi2tlm-bridge-rnf.h"
#include "tlm-bridges/tlm2chi-bridge-sn.h"
#include "tlm-bridges/chi2tlm-bridge-sn.h"

#include "tlm-bridges/tlm2vfio-bridge.h"
#include "rtl-bridges/pcie-host/cxs/tlm/tlm2cxs-hw-bridge.h"

#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/random-traffic.h"

#include "tlm-modules/rnf-chi.h"
#include "tlm-modules/iconnect-chi.h"
#include "tlm-modules/sn-chi.h"
#include "test-modules/memory.h"

#include "test-modules/signals-axilite.h"
#include "test-modules/signals-rnf-chi.h"
#include "test-modules/signals-sn-chi.h"
#include "test-modules/signals-cxs.h"

#include "test-modules/utils-chi.h"

using namespace utils::CHI;

#define CACHE_SIZE (4 * CACHELINE_SZ)
#define LINE(l) ((l) * CACHELINE_SZ)

#define RN0_ID 0
#define HN0_ID 20

#define RN1_ID 1
#define HN1_ID 21

#define RAM_SIZE (32 * CACHELINE_SZ)

// Increase for more random traffic
#define NUM_TXNS_RNF0 20000
#define NUM_TXNS_RNF1 20000

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

#define CXS_B_BASE_ADDR 0x00000000
#define CXS_F_BASE_ADDR 0x00020000

typedef TLMTrafficGenerator::DoneCallback TGDoneCallBack;

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

sc_event *tgDone;

void tgDoneCallBack(TLMTrafficGenerator *gen, int threadID)
{
	tgDone->notify();
}

TrafficDesc xfers(merge({
	//
	// ReadUnique
	//
	Write(LINE(0), DATA(0xFF, 0xFF, 0xFF, 0xFF)),
	Read(LINE(0)),
		Expect(DATA(0xFF, 0xFF, 0xFF, 0xFF), 4),

	//
	// WriteBackFull + MakeUnique
	//
	Write(LINE(4), burst_data, CACHELINE_SZ),
	Read(LINE(4), CACHELINE_SZ),
		Expect(burst_data, CACHELINE_SZ),

	// ReadShared
	Read(LINE(2)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	//
	// ReadShared + Evict + MakeUnique
	//
	Read(LINE(1)),
	Write(LINE(5), burst_data, CACHELINE_SZ),
}));

template<int RN_ID, int HN_ID>
SC_MODULE(Chip)
{
	enum { SN_ID = HN_ID - 10 };

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
	// TLM2CXS HW bridge
	//
	tlm2cxs_hw_bridge<> cxs_hwb;

	//
	// SlaveNode with memory
	//
	SlaveNode_F<SN_ID> sn;
	memory mem;

	Chip(sc_module_name name,
		uint32_t base_addr,
		sc_clock& clk,
		sc_signal<bool>& resetn) :

		sc_module(name),

		//
		// Signals
		//
		signals_rnf("chi_signals"),
		signals_sn("chi_signals_sn"),

		//
		// TLM components
		//
		rnf("rnf"),
		icn("icn"),

		t2c_bridge("tlm2chi_bridge"),
		c2t_bridge("chi2tlm_bridge"),

		t2c_bridge_sn("tlm2chi_bridge_sn"),
		c2t_bridge_sn("chi2tlm_bridge_sn"),

		cxs_hwb("cxs_hwb", base_addr),

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
			cxs_hwb);

		//
		// Setup slave node to the interconnect and memory
		//
		connect_sn(clk, resetn,
			*icn.port_SN, t2c_bridge_sn,
			signals_sn,
			c2t_bridge_sn, sn, mem);
	}

	void EnableDebug() { rnf.EnableDebug(); }

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
};

typedef Chip<RN0_ID, HN0_ID> Chip0_t;
typedef Chip<RN1_ID, HN1_ID> Chip1_t;

SC_MODULE(Top)
{
	sc_signal<bool> rst_n;
	sc_clock clk;
	sc_signal<bool> irq;

	RandomTraffic rand_traffic0;
	RandomTraffic rand_traffic1;

	Chip0_t chip0;
	Chip1_t chip1;

	vfio_dev vdev;
	tlm2vfio_bridge tlm2vfio;

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name,
		const char *devname,
		int iommu_group,
		TrafficDesc& xfers0,
		TGDoneCallBack tgDoneCB) :
		sc_module(name),

		rst_n("resetn", true),
		clk("clk", sc_time(1, SC_US)),
		irq("irq"),

		rand_traffic0(0, RAM_SIZE, (~(0x3llu)),
				1, RAM_SIZE, RAM_SIZE, NUM_TXNS_RNF0),
		rand_traffic1(0, RAM_SIZE, (~(0x3llu)),
				1, RAM_SIZE, RAM_SIZE, NUM_TXNS_RNF1),

		chip0("chip0", CXS_B_BASE_ADDR, clk, rst_n),
		chip1("chip1", CXS_F_BASE_ADDR, clk, rst_n),

		vdev(devname, iommu_group),
		tlm2vfio("tlm2vfio_bridge", 2, vdev, 0),

		m_tgDoneCB(tgDoneCB)
	{
		sc_time startDelay = sc_time(500, SC_US);

		//
		// Configure the System Address Map on HN0
		//
		chip0.icn.SystemAddressMap().AddMap(0, RAM_SIZE, HN1_ID);

		//
		// Configure the CCIX port on chip 0
		//
		chip0.icn.port_CCIX[0]->AddRemoteAgent(RN1_ID);
		chip0.icn.port_CCIX[0]->AddRemoteAgent(HN1_ID);

		//
		// Configure the CCIX port on chip 1
		//
		chip1.icn.port_CCIX[0]->AddRemoteAgent(RN0_ID);
		chip1.icn.port_CCIX[0]->AddRemoteAgent(HN0_ID);

		chip0.EnableDebug();
		chip1.EnableDebug();

		//
		// Traffig generators
		//
		SetupTG(chip0, startDelay, xfers0, tgDoneCB);

		//
		// Connect CXS HWBs <-> tlm2vfio bridge
		//
		chip0.cxs_hwb.bridge_socket(tlm2vfio.tgt_socket[0]);
		chip1.cxs_hwb.bridge_socket(tlm2vfio.tgt_socket[1]);

		//
		// Setup irq
		//
		tlm2vfio.irq(irq);
		chip0.cxs_hwb.irq(irq);
		chip1.cxs_hwb.irq(irq);

		SC_THREAD(tgDone_thread);
	}

	void tgDone_thread()
	{
		while (true) {
			wait(tgDone);

			if (!rand_traffic0.done()) {
				SetupTG(chip0, SC_ZERO_TIME,
					rand_traffic0, m_tgDoneCB);

				SetupTG(chip1, SC_ZERO_TIME, rand_traffic1);

			} else {
				sc_stop();
			}
		}
	}

	template<typename T1, typename T2>
	void SetupTG(T1& chip, sc_time startDelay,
			T2& xfers, TGDoneCallBack tgDoneCB = NULL)
	{
		TLMTrafficGenerator& tg = chip.rnf.GetTrafficGenerator();

		tg.setStartDelay(startDelay);
		tg.addTransfers(xfers, 0, tgDoneCB);
	}

	TGDoneCallBack m_tgDoneCB;
	sc_event tgDone;
};

int sc_main(int argc, char *argv[])
{
	sc_trace_file *trace_fp;
	int iommu_group;

	if (argc < 3) {
		printf("%s: device-name iommu-group\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	trace_fp = sc_create_vcd_trace_file(argv[0]);
	iommu_group = strtoull(argv[2], NULL, 10);
	Top top("Top", argv[1], iommu_group, xfers, tgDoneCallBack);

	tgDone = &top.tgDone;

	// Reset is active low. Emit a reset cycle.
	top.rst_n.write(false);
	sc_start(4, SC_US);
	top.rst_n.write(true);

	sc_start();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
	return 0;
}
