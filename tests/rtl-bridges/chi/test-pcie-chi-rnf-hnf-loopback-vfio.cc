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

#include <sstream>

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
#include "traffic-generators/tg-tlm.h"
#include "tlm-modules/rnf-chi.h"

#include "traffic-generators/random-traffic.h"

#include "rtl-bridges/pcie-host/chi/tlm/tlm2chi-hwb-rnf.h"
#include "rtl-bridges/pcie-host/chi/tlm/chi2tlm-hwb-rnf.h"

#include "tlm-modules/iconnect-chi.h"
#include "tlm-modules/sn-chi.h"
#include "test-modules/memory.h"

#include "test-modules/signals-rnf-chi.h"
#include "test-modules/utils-chi.h"

#include "tlm-bridges/tlm2vfio-bridge.h"

using namespace utils::CHI;

#define NODE_ID_RNF0 0
#define NODE_ID_RNF1 1

#define NUM_RN_F 2

#define CACHE_SIZE (4 * CACHELINE_SZ)
#define LINE(l) (l * CACHELINE_SZ)

#define RAM_SIZE (32 * CACHELINE_SZ)

#define CHI_HNF_BASE_ADDR 0x00000000
#define CHI_RNF_BASE_ADDR 0x00020000

#define NUM_TXNS_RNF0 20000
#define NUM_TXNS_RNF1 20000

typedef tlm2chi_bridge_rnf<
        512, /* int DATA_WIDTH = 512, */
        48,  /* int ADDR_WIDTH = 48, */
        7,   /* int NODEID_WIDTH = 7, */
        0,   /* int RSVDC_WIDTH = 0, */
        64,  /* int DATACHECK_WIDTH = 64, */
        8,   /* POISON_WIDTH = 8 */
	Dat::Opcode_Width_3 /* CHI Issue B */
> tlm2chi_bridge_rnf_t;

typedef chi2tlm_bridge_rnf<
        512, /* int DATA_WIDTH = 512, */
        48,  /* int ADDR_WIDTH = 48, */
        7,   /* int NODEID_WIDTH = 7, */
        0,   /* int RSVDC_WIDTH = 0, */
        64,  /* int DATACHECK_WIDTH = 64, */
        8,   /* POISON_WIDTH = 8 */
	Dat::Opcode_Width_3 /* CHI Issue B */
> chi2tlm_bridge_rnf_t;

typedef tlm2chi_hwb_rnf<
        512, /* int DATA_WIDTH = 512, */
        48,  /* int ADDR_WIDTH = 48, */
        7,   /* int NODEID_WIDTH = 7, */
        0,   /* int RSVDC_WIDTH = 0, */
        64,  /* int DATACHECK_WIDTH = 64, */
        8,   /* POISON_WIDTH = 8 */
	Dat::Opcode_Width_3 /* CHI Issue B */
> tlm2chi_hwb_rnf_t;

typedef chi2tlm_hwb_rnf<
        512, /* int DATA_WIDTH = 512, */
        48,  /* int ADDR_WIDTH = 48, */
        7,   /* int NODEID_WIDTH = 7, */
        0,   /* int RSVDC_WIDTH = 0, */
        64,  /* int DATACHECK_WIDTH = 64, */
        8,   /* POISON_WIDTH = 8 */
	Dat::Opcode_Width_3 /* CHI Issue B */
> chi2tlm_hwb_rnf_t;

typedef CHISignals<
tlm2chi_bridge_rnf_t::TXREQ_FLIT_WIDTH,
tlm2chi_bridge_rnf_t::TXRSP_FLIT_WIDTH,
tlm2chi_bridge_rnf_t::TXDAT_FLIT_WIDTH,
tlm2chi_bridge_rnf_t::RXRSP_FLIT_WIDTH,
tlm2chi_bridge_rnf_t::RXDAT_FLIT_WIDTH,
tlm2chi_bridge_rnf_t::RXSNP_FLIT_WIDTH
> CHISignals_t;

typedef TLMTrafficGenerator::DoneCallback TGDoneCallBack;

void tgDoneCallBack(TLMTrafficGenerator *gen, int threadID)
{
	sc_stop();
}

// Top simulation module.
SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst_n; // Active low.
	sc_signal<bool> irq;

	// For rnf1
	CHISignals_t signals1;

	RandomTraffic rand_traffic0;
	RandomTraffic rand_traffic1;

	RequestNode_F<NODE_ID_RNF0, CACHE_SIZE> rnf0;
	RequestNode_F<NODE_ID_RNF1, CACHE_SIZE> rnf1;

	tlm2chi_hwb_rnf_t t2c_hw_bridge0;
	chi2tlm_hwb_rnf_t c2t_hw_bridge0;

	// For rnf1
	tlm2chi_bridge_rnf_t t2c_bridge1;
	chi2tlm_bridge_rnf_t c2t_bridge1;

	// Interconnect + slave mem 
	iconnect_chi<20, 10, NUM_RN_F> icn;
	SlaveNode_F<> sn;
	memory mem;

	vfio_dev vdev;
	tlm2vfio_bridge tlm2vfio;

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name,
		const char *devname,
		int iommu_group,
		TGDoneCallBack tgDoneCB) :

		clk("clk", sc_time(1, SC_US)),
		rst_n("rst_n"),
		irq("irq"),
		signals1("chi_signals1"),

		rand_traffic0(0, RAM_SIZE, (~(0x3llu)),
					1, RAM_SIZE, RAM_SIZE, NUM_TXNS_RNF0),
		rand_traffic1(0, RAM_SIZE, (~(0x3llu)),
					1, RAM_SIZE, RAM_SIZE, NUM_TXNS_RNF1),

		rnf0("rnf0"),
		rnf1("rnf1", rand_traffic1),

		t2c_hw_bridge0("tlm2chi_hw_bridge0", CHI_RNF_BASE_ADDR),
		c2t_hw_bridge0("chi2tlm_bridge0", CHI_HNF_BASE_ADDR),

		t2c_bridge1("tlm2chi_bridge1"),
		c2t_bridge1("chi2tlm_bridge1"),

		icn("iconnect_chi"),
		sn("sn"),
		mem("mem", sc_time(10, SC_NS), RAM_SIZE),

		vdev(devname, iommu_group),
		tlm2vfio("tlm2vfio_bridge", 2, vdev, 0)
	{

		//
		// Setup rnf0
		//
		rnf0.GetTrafficGenerator().addTransfers(rand_traffic0, 0,
							tgDoneCB);
		rnf0.GetTrafficGenerator().setStartDelay(sc_time(100, SC_US));
		rnf0.GetTrafficGenerator().enableDebug();

		//
		// Setup rnf1
		//
		rnf1.GetTrafficGenerator().setStartDelay(sc_time(9400, SC_US));

		//
		// tlm2chi hw bridge
		//
		t2c_hw_bridge0.resetn(rst_n);

		//
		// chi2tlm hw bridge
		//
		c2t_hw_bridge0.resetn(rst_n);

		//
		// Connect rnf0 and rnf1
		//
		rnf0.connect(t2c_hw_bridge0);

		//
		// chi2tlm hw bridge interconnect connection
		//
		connect_icn_hw_bridge();

		// icn <-> sn connection
		connect_icn_sn();

		//
		// Setup irq
		//
		t2c_hw_bridge0.irq(irq);
		tlm2vfio.irq(irq);
		c2t_hw_bridge0.irq(irq);

		//
		// Setup t2a_hw_bridge0 <-> vfio bridge
		//
		t2c_hw_bridge0.bridge_socket(tlm2vfio.tgt_socket[0]);
		c2t_hw_bridge0.bridge_socket(tlm2vfio.tgt_socket[1]);

		//
		// Setup rnf1 with the interconnect
		//
		connect(clk, rst_n,
			rnf1, t2c_bridge1,
			signals1,
			c2t_bridge1, *icn.port_RN_F[1]);
	}

	void connect_icn_hw_bridge()
	{
		//
		// TxLink
		//
		icn.port_RN_F[0]->txrsp_init_socket.bind(
				c2t_hw_bridge0.txrsp_tgt_socket);

		icn.port_RN_F[0]->txdat_init_socket.bind(
				c2t_hw_bridge0.txdat_tgt_socket);

		icn.port_RN_F[0]->txsnp_init_socket.bind(
				c2t_hw_bridge0.txsnp_tgt_socket);
		//
		// RxLink
		//
		c2t_hw_bridge0.rxreq_init_socket.bind(
				icn.port_RN_F[0]->rxreq_tgt_socket);

		c2t_hw_bridge0.rxrsp_init_socket.bind(
				icn.port_RN_F[0]->rxrsp_tgt_socket);

                c2t_hw_bridge0.rxdat_init_socket.bind(
				icn.port_RN_F[0]->rxdat_tgt_socket);
	}

	void connect_icn_sn()
	{
		// icn -> sn 
		icn.port_SN[0].txreq_init_socket.bind(sn.rxreq_tgt_socket);
		icn.port_SN[0].txdat_init_socket.bind(sn.rxdat_tgt_socket);

		sn.txrsp_init_socket.bind(icn.port_SN[0].rxrsp_tgt_socket);
                sn.txdat_init_socket.bind(icn.port_SN[0].rxdat_tgt_socket);

		// Connect the slave node to the memory
		sn.init_socket(mem.socket);
	}

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
