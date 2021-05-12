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

#include <sstream>

#define SC_INCLUDE_DYNAMIC_PROCESSES
#define __STDC_FORMAT_MACROS

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include <verilated_vcd_sc.h>
#include "verilated.h"

#include "tlm-bridges/tlm2axilite-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "traffic-generators/random-traffic.h"
#include "checkers/pc-axilite.h"

#include "tlm-bridges/tlm2ace-bridge.h"
#include "tlm-bridges/ace2tlm-bridge.h"
#include "rtl-bridges/pcie-host/ace/tlm/tlm2ace-hw-bridge.h"
#include "rtl-bridges/pcie-host/ace/tlm/ace2tlm-hw-bridge.h"

#include "checkers/pc-ace.h"

#include "test-modules/signals-axi.h"
#include "test-modules/signals-ace.h"
#include "test-modules/utils-ace.h"

#include "tlm-modules/master-ace.h"
#include "tlm-modules/iconnect-ace.h"

#include "test-modules/memory.h"
#include "test-modules/signals-axilite.h"
#include "test-modules/utils.h"
#include "test-modules/utils-ace.h"
#include "tlm-bridges/tlm2vfio-bridge.h"

#include "atg_bridge.h"
#include "system-cache.h"

#include "trace/trace.h"

#define basename buggy
using namespace utils;
using namespace utils::ACE;

#define ATG_BASE_ADDR 0x00120000
#define SYSTEM_CACHE_BASE_ADDR 0x000E0000
#define ACE_SLV_BASE_ADDR 0x00040000

#define NUM_ACE_MASTERS 2
#define NUM_ACELITE_MASTERS 0
#define CACHELINE_SIZE 64

#define CACHE_SIZE (4 * CACHELINE_SIZE)

#define LINE(l) (l * CACHELINE_SIZE)

#define AXI_ADDR_WIDTH 64
#define AXI_DATA_WIDTH 128

#define CACHEABLE \
GenAttr(0, 0, 0, false, 0, 0, false, false, true, true, true, true)

typedef ACESignals<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	16,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	32,		// AWUSER_WIDTH
	32,		// ARUSER_WIDTH
	32,		// WUSER_WIDTH
	32,		// RUSER_WIDTH
	32,		// BUSER_WIDTH
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> ACESignals_t;

typedef tlm2ace_bridge<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	16,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	32,		// AWUSER_WIDTH
	32,		// ARUSER_WIDTH
	32,		// WUSER_WIDTH
	32,		// RUSER_WIDTH
	32,		// BUSER_WIDTH
	CACHELINE_SIZE,	// CACHELINE_SZ
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> tlm2ace_bridge_t;

typedef ace2tlm_bridge<
	AXI_ADDR_WIDTH,	// ADDR_WIDTH
	AXI_DATA_WIDTH,	// DATA_WIDTH
	16,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	32,		// AWUSER_WIDTH
	32,		// ARUSER_WIDTH
	32,		// WUSER_WIDTH
	32,		// RUSER_WIDTH
	32,		// BUSER_WIDTH
	AXI_DATA_WIDTH	// CD_DATA_WIDTH = DATA_WIDTH
> ace2tlm_bridge_t;

typedef ACEMaster<
	CACHE_SIZE,
	CACHELINE_SIZE
> ACEMaster_t;

typedef iconnect_ace<
	NUM_ACE_MASTERS,
	NUM_ACELITE_MASTERS,
	CACHELINE_SIZE
> iconnect_ace_t;

typedef TLMTrafficGenerator::DoneCallback TGDoneCallBack;

void tgDoneCallBack(TLMTrafficGenerator *gen, int threadID)
{
	sc_stop();
}

//
// AXI traffic generated towards the System cache that will trigger outgoing
// ACE traffic (from the cache).
//
TrafficDesc xfers_sc(merge({
	//
	// Test ReadOnce, WriteUnique from the System cache
	//
	Read(LINE(0)),
	Write(LINE(0), DATA(0x12, 0x12, 0x12, 0x12)),

	//
	// Test ReadShared from the System cache
	//
	Read(LINE(0)), CACHEABLE,

	//
	// Sequence for testing WriteBacks generated from System cache
	//
	Write(LINE(1), DATA(0x11, 0x11, 0x11, 0x11)),
		 CACHEABLE,

	Write(LINE((256 + 1)), DATA(0x22, 0x22, 0x22, 0x22)),
		 CACHEABLE,

	Write(LINE((512 + 1)), DATA(0x33, 0x33, 0x33, 0x33)),
		 CACHEABLE
}));

//
// Traffic generated from ACE master 1 that will trigger snoops towards the
// system cache
//
TrafficDesc xfers_m1(merge({
	//
	// Test to generate a ReadShared snoop towards the System cache
	//
	Read(LINE(0)), CACHEABLE,
		Expect(DATA(0x12, 0x12, 0x12, 0x12), 4),

	//
	// Test to read data written by the System to ram (WriteBack data)
	//
	Read(LINE(1)), CACHEABLE,
		Expect(DATA(0x11, 0x11, 0x11, 0x11), 4),

	//
	// Generate ReadShared / ReadSharedNotDirty snoops towards the System
	// cache
	//
	Read(LINE((256 + 1))), CACHEABLE,
		Expect(DATA(0x22, 0x22, 0x22, 0x22), 4),

	Read(LINE((512 + 1))), CACHEABLE,
		Expect(DATA(0x33, 0x33, 0x33, 0x33), 4),

	//
	// Test to transmit a DVM branch predictor invalidate message
	//
	DVMMessage(DVM_CMD(DVM::CmdBranchPredictorInv)),

	//
	// Test to transmit a DVM Sync message to the cache
	//
	DVMMessage(DVM_CMD(DVM::CmdSync) | DVM::CompletionBit)
}));

// Top simulation module.
SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst; // Active high.
	sc_signal<bool> rst_n; // Active low.
	sc_signal<bool> irq;
	ACESignals_t signals_m1;

	TLMTrafficGenerator gen;
	atg_bridge atg_bridge0;

	ace2tlm_hw_bridge<> a2t_hw_bridge0;
	iconnect_ace_t iconnect;

	ACEMaster_t m1;
	tlm2ace_bridge_t t2a_bridge1;
	ace2tlm_bridge_t a2t_bridge1;

	vfio_dev vdev;
	tlm2vfio_bridge slv_tlm2vfio;     // Towards ACE slv bridge
	tlm2vfio_bridge atg_sc_tlm2vfio;  // Towards ATG & System cache

	SystemCache s_cache;

	memory ram;

	void gen_rst_n(void) {
		rst_n.write(!rst.read());
	}

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name,
		TrafficDesc& xfers_sc,
		TrafficDesc& xfers_m1,
		const char *devname,
		int iommu_group,
		TGDoneCallBack tgDoneCB,
		unsigned int ram_size = 64 * 1024) :

		clk("clk", sc_time(10, SC_US)),
		rst("rst"),
		rst_n("rst_n"),
		irq("irq"),
		signals_m1("ace-signals-m1"),

		gen("gen"),
		atg_bridge0("atg_bridge0", ATG_BASE_ADDR),

		a2t_hw_bridge0("ace2tlm-hw-bridge0", ACE_SLV_BASE_ADDR),
		iconnect("ace_iconnect"),

		m1("ace_master1"),

		t2a_bridge1("tlm2ace_bridge1"),
		a2t_bridge1("ace2tlm_bridge1"),

		vdev(devname, iommu_group),
		slv_tlm2vfio("ace-slv-tlm2vfio-bridge", 1, vdev, 0),
		atg_sc_tlm2vfio("atg-tlm2vfio-bridge", 2, vdev, 2, 0, false),

		s_cache("system_cache", SYSTEM_CACHE_BASE_ADDR),

		ram("ram", SC_ZERO_TIME, ram_size)
	{
		SC_METHOD(gen_rst_n);
		sensitive << rst;

		//
		// Wire up the clock and reset signals.
		//
		a2t_hw_bridge0.clk(clk);
		a2t_hw_bridge0.resetn(rst_n);

		//
		// Setup the traffic generator towards atg_bridge (and the
		// System cache)
		//
		gen.addTransfers(xfers_sc);
		gen.setStartDelay(sc_time(400, SC_US));
		gen.enableDebug();

		//
		// Connect the traffic generator with the atg_bridge0
		//
		gen.socket(atg_bridge0.tgt_socket);

		//
		// a2t_hw_bridge0 <-> iconnect
		//
		iconnect.s_ace_port[0]->connect_master(a2t_hw_bridge0);
		iconnect.s_ace_port[0]->SetForwardDVM(true);

		//
		// iconnect <-> ram
		//
		iconnect.ds_port.connect_slave(ram);

		//
		// Setup irq
		//
		slv_tlm2vfio.irq(irq);
		a2t_hw_bridge0.irq(irq);

		//
		// Setup atg_bridge0 <-> vfio bridge
		//
		atg_bridge0.bridge_socket(atg_sc_tlm2vfio.tgt_socket[0]);

		//
		// Setup a2t_hw_bridge0 <-> vfio bridge
		//
		a2t_hw_bridge0.bridge_socket(slv_tlm2vfio.tgt_socket[0]);

		// Setup ACE master 1
		m1.GetTrafficGenerator().addTransfers(xfers_m1, 0, tgDoneCB);
		m1.GetTrafficGenerator().setStartDelay(sc_time(1000, SC_MS));
		m1.GetTrafficGenerator().enableDebug();

		//
		// System cache (issues control I/F commands generating ACE
		// read/write barriers and DVM messages from the cache)
		//
		s_cache.bridge_socket(atg_sc_tlm2vfio.tgt_socket[1]);

		//
		// Connect ACE master 1
		//
		connect(clk, rst_n,
			m1, t2a_bridge1,
			signals_m1,
			a2t_bridge1, *iconnect.s_ace_port[1]);
		iconnect.s_ace_port[1]->SetForwardDVM(true);
	}

	template<typename T1, typename T2,
			typename T3, typename T4,
			typename T5,
			typename T6, typename T7>
	void connect(T1& clk, T2& resetn,
			T3& master, T4& tlm2ace_b,
			T5& signals,
			T6& ace2tlm_b, T7& s_ace_port)
	{
		// Connect clk
		tlm2ace_b.clk(clk);
		ace2tlm_b.clk(clk);

		// Connect reset
		tlm2ace_b.resetn(resetn);
		ace2tlm_b.resetn(resetn);

		// Connect signals
		signals.connect(&tlm2ace_b);
		signals.connect(&ace2tlm_b);

		// Connect tlm2ace bridge on the master
		master.connect(tlm2ace_b);

		// Connect ace2tlm bridge to the interconnect slave ace port
		s_ace_port.connect_master(ace2tlm_b);
	}
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

	Top top("Top", xfers_sc, xfers_m1,
		argv[1], iommu_group, tgDoneCallBack);

	// Reset is active high. Emit a reset cycle.
	top.rst.write(true);
	sc_start(4, SC_US);
	top.rst.write(false);

	sc_start();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
	return 0;
}
