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

#include "trace/trace.h"

#define basename buggy
using namespace utils;
using namespace utils::ACE;

#define ACE_MST_BASE_ADDR 0x00000000
#define ACE_SLV_BASE_ADDR 0x00020000

#define NUM_ACE_MASTERS 2
#define NUM_ACELITE_MASTERS 0
#define CACHELINE_SIZE 64

#define CACHE_SIZE (4 * CACHELINE_SIZE)

#define LINE(l) (l * CACHELINE_SIZE)

#define AXI_ADDR_WIDTH 64
#define AXI_DATA_WIDTH 128

#define NUM_TXNS_MSTR0 20000
#define NUM_TXNS_MSTR1 20000

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

// Top simulation module.
SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst; // Active high.
	sc_signal<bool> rst_n; // Active low.
	sc_signal<bool> irq;
	ACESignals_t signals_m1;

	RandomTraffic rand_xfers0;
	RandomTraffic rand_xfers1;

	ACEMaster_t m0;
	tlm2ace_hw_bridge<> t2a_hw_bridge0;

	ace2tlm_hw_bridge<> a2t_hw_bridge0;
	iconnect_ace_t iconnect;

	ACEMaster_t m1;
	tlm2ace_bridge_t t2a_bridge1;
	ace2tlm_bridge_t a2t_bridge1;

	vfio_dev vdev;
	tlm2vfio_bridge tlm2vfio;

	memory ram;

	void gen_rst_n(void) {
		rst_n.write(!rst.read());
	}

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name,
		const char *devname,
		int iommu_group,
		TGDoneCallBack tgDoneCB,
		unsigned int ram_size = 8 * 1024) :

		clk("clk", sc_time(10, SC_US)),
		rst("rst"),
		rst_n("rst_n"),
		irq("irq"),
		signals_m1("ace_signals_m1"),

                rand_xfers0(0, ram_size - 4, UINT64_MAX,
				1, ram_size, ram_size, NUM_TXNS_MSTR0),
                rand_xfers1(0, ram_size - 4, UINT64_MAX,
				1, ram_size, ram_size, NUM_TXNS_MSTR1),

		m0("ace_master0"),
		t2a_hw_bridge0("tlm2ace_hw_bridge0", ACE_MST_BASE_ADDR),

		a2t_hw_bridge0("ace2tlm_hw_bridge0", ACE_SLV_BASE_ADDR),
		iconnect("ace_iconnect"),

		m1("ace_master1", rand_xfers1),
		t2a_bridge1("tlm2ace_bridge1"),
		a2t_bridge1("ace2tlm_bridge1"),

		vdev(devname, iommu_group),
		tlm2vfio("tlm2vfio_bridge", 2, vdev, 0),

		ram("ram", SC_ZERO_TIME, ram_size)
	{
		SC_METHOD(gen_rst_n);
		sensitive << rst;

		//
		// Wire up the clock and reset signals.
		//
		t2a_hw_bridge0.clk(clk);
		t2a_hw_bridge0.resetn(rst_n);

		a2t_hw_bridge0.clk(clk);
		a2t_hw_bridge0.resetn(rst_n);

		//
		// Setup ACE master 0
		//
		m0.GetTrafficGenerator().addTransfers(rand_xfers0, 0, tgDoneCB);
		m0.GetTrafficGenerator().setStartDelay(sc_time(400, SC_US));
		m0.enableDebug();

		//
		// Connect ACE master 0 to the tlm2ace_hw_bridge (DUT)
		//
		m0.connect(t2a_hw_bridge0);

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
		t2a_hw_bridge0.irq(irq);
		tlm2vfio.irq(irq);
		a2t_hw_bridge0.irq(irq);

		//
		// Setup t2a_hw_bridge0 <-> vfio bridge
		//
		t2a_hw_bridge0.bridge_socket(tlm2vfio.tgt_socket[0]);
		a2t_hw_bridge0.bridge_socket(tlm2vfio.tgt_socket[1]);

		// Setup ACE master 1
		m1.GetTrafficGenerator().setStartDelay(sc_time(400, SC_US));

		//
		// Connect master1
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
	Top top("Top", argv[1], iommu_group, tgDoneCallBack);

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
