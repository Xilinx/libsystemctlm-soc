/*
 * This is a small example showing howto connect an RTL PCIe Accelerator
 * to a SystemC/TLM simulation using the TLM-2-PCIe bridges.
 *
 * Copyright (c) 2020 Xilinx Inc.
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

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "tlm-modules/tlm-splitter.h"
#include "tlm-bridges/tlm2axi-bridge.h"
#include "tlm-bridges/tlm2axilite-bridge.h"
#include "tlm-bridges/axi2tlm-bridge.h"
#include "tlm-bridges/axilite2tlm-bridge.h"
#include "rtl-bridges/pcie-host/axi/tlm/tlm2axi-hw-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/random-traffic.h"
#include "checkers/pc-axi.h"
#include "checkers/pc-axilite.h"

#include "test-modules/memory.h"
#include "test-modules/signals-axi.h"
#include "test-modules/signals-axilite.h"
#include "test-modules/utils.h"
#include "trace/trace.h"

#include <verilated_vcd_sc.h>
#include "Vpcie_ep.h"

using namespace utils;

// Top simulation module.
SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst; // Active high.
	sc_signal<bool> rst_n; // Active low.

	RandomTraffic rand_xfers;
	tlm_splitter<2> splitter;
	TLMTrafficGenerator tg;

	tlm2axilite_bridge<64, 32> s_axi_tlm_bridge;
	axi2tlm_bridge<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > m_axi_tlm_bridge;
	axi2tlm_bridge<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > m_axi_usr_tlm_bridge;
	tlm2axi_hw_bridge tlm2axi_sw_bridge;
	Vpcie_ep ep_bridge;

	sc_vector<AXILiteSignals<64, 32 > > signals_s_axi_pcie;
	sc_vector<AXISignals<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > > signals_m_axi_pcie;
	sc_vector<AXISignals<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > > signals_m_axi_usr;

	sc_vector<AXISignals<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > > signals_m_tieoff;
	sc_vector<AXISignals<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > > signals_s_tieoff;

	sc_vector<AXISignals<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > > signals_pcie_m_tieoff;
	sc_vector<AXISignals<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > > signals_pcie_s_tieoff;

	sc_vector<AXILiteSignals<64, 32 > > signals_pcie_sm_tieoff;
	sc_vector<AXILiteSignals<64, 32 > > signals_pcie_ss_tieoff;

	sc_signal<bool> irq_req_bool;
	sc_signal<sc_bv<2> > irq_req;
	sc_signal<sc_bv<2> > irq_ack;
	sc_signal<sc_bv<64> > usr_irq_req;
	sc_signal<sc_bv<64> > usr_irq_ack;

	sc_signal<sc_bv<256> > h2c_gpio_out;
	sc_signal<sc_bv<256> > c2h_gpio_in;

	sc_signal<bool> usr_resetn;

	memory ram;
	memory ref_ram;
	memory dummy_ram;

	void pull_rst(void) {
		rst.write(0);
		wait(400, SC_NS);
		rst.write(1);
		wait(400, SC_NS);
		rst.write(0);
	}

	void gen_rst_n(void) {
		rst_n.write(!rst.read());
	}

	void unify_irq_req(void) {
		int v = irq_req.read().to_uint64();
		irq_req_bool.write(!!v);
	}

	void set_debuglevel(int l) {
		tlm2axi_sw_bridge.set_debuglevel(l);
	}

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name, unsigned int ram_size = 1 * 1024) :
		sc_module(name),
		clk("clk", sc_time(10, SC_NS)),
		rst("rst"),
		rst_n("rst_n"),
		rand_xfers(0, ram_size - 4, UINT64_MAX, 1, ram_size, ram_size, 100),
		splitter("splitter", true),
		tg("tg", 1),
		s_axi_tlm_bridge("s_axi_tlm_bridge"),
		m_axi_tlm_bridge("m_axi_tlm_bridge"),
		m_axi_usr_tlm_bridge("m_axi_usr_tlm_bridge"),
		tlm2axi_sw_bridge("tlm2axi_sw_bridge"),
		ep_bridge("ep_bridge"),
		signals_s_axi_pcie("s_axi_pcie", 1),
		signals_m_axi_pcie("m_axi_pcie", 1),
		signals_m_axi_usr("m_axi_usr", 1),
		signals_m_tieoff("signals_master_tieoff", 5),
		signals_s_tieoff("signals_slave_tieoff", 6),
		signals_pcie_m_tieoff("signals_pcie_master_tieoff", signals_m_tieoff.size()),
		signals_pcie_s_tieoff("signals_pcie_slave_tieoff", signals_s_tieoff.size()),
		signals_pcie_sm_tieoff("signals_pcie_s_master_tieoff", signals_m_tieoff.size()),
		signals_pcie_ss_tieoff("signals_pcie_s_slave_tieoff", signals_s_tieoff.size()),
		irq_req_bool("irq_req_bool"),
		irq_req("irq_req"),
		irq_ack("irq_ack"),
		usr_irq_req("usr_irq_req"),
		usr_irq_ack("usr_irq_ack"),

		h2c_gpio_out("h2c_gpio_out"),
		c2h_gpio_in("c2h_gpio_in"),

		usr_resetn("usr_resetn"),

		ram("ram", sc_time(1, SC_NS), ram_size),
		ref_ram("ref_ram", sc_time(1, SC_NS), ram_size),
		dummy_ram("dummy_ram", sc_time(1, SC_NS), ram_size)
	{
		char pname[128];
		int i;

		SC_THREAD(pull_rst);

		SC_METHOD(gen_rst_n);
		sensitive << rst;

		SC_METHOD(unify_irq_req);
		sensitive << irq_req;

		rand_xfers.setMaxStreamingWidthLen(ram_size);

		tg.enableDebug();
		tg.addTransfers(rand_xfers, 0);
		tg.setStartDelay(sc_time(15, SC_US));

		assert(signals_m_tieoff.size() <= 6);
		for (i = 0; i < signals_m_tieoff.size(); i++) {
			int bi = 6 - signals_m_tieoff.size() + i;

			snprintf(pname, sizeof(pname) - 1, "m_axi_usr_%d_", bi);
			signals_m_tieoff[i].connect(ep_bridge, pname);

			snprintf(pname, sizeof(pname) - 1, "m_axi_pcie_m%d_", bi);
			signals_pcie_m_tieoff[i].connect(ep_bridge, pname);

			snprintf(pname, sizeof(pname) - 1, "s_axi_pcie_m%d_", bi);
			signals_pcie_sm_tieoff[i].connect(ep_bridge, pname);
		}

		assert(signals_s_tieoff.size() <= 6);
		for (i = 0; i < signals_s_tieoff.size(); i++) {
			int bi = 6 - signals_s_tieoff.size() + i;

			snprintf(pname, sizeof(pname) - 1, "s_axi_usr_%d_", bi);
			signals_s_tieoff[i].connect(ep_bridge, pname);

			snprintf(pname, sizeof(pname) - 1, "m_axi_pcie_s%d_", bi);
			signals_pcie_s_tieoff[i].connect(ep_bridge, pname);

			snprintf(pname, sizeof(pname) - 1, "s_axi_pcie_s%d_", bi);
			signals_pcie_ss_tieoff[i].connect(ep_bridge, pname);
		}

		ep_bridge.clk(clk);
		s_axi_tlm_bridge.clk(clk);
		m_axi_tlm_bridge.clk(clk);
		m_axi_usr_tlm_bridge.clk(clk);

		ep_bridge.resetn(rst_n);
		ep_bridge.usr_resetn(usr_resetn);
		s_axi_tlm_bridge.resetn(rst_n);
		m_axi_tlm_bridge.resetn(rst_n);
		m_axi_usr_tlm_bridge.resetn(rst_n);

		ep_bridge.h2c_gpio_out(h2c_gpio_out);
		ep_bridge.c2h_gpio_in(c2h_gpio_in);

		ep_bridge.irq_req(irq_req);
		ep_bridge.irq_ack(irq_ack);
		ep_bridge.usr_irq_req(usr_irq_req);
		ep_bridge.usr_irq_ack(usr_irq_ack);

		tg.socket.bind(splitter.target_socket);
		splitter.i_sk[0]->bind(ref_ram.socket);
		splitter.i_sk[1]->bind(tlm2axi_sw_bridge.tgt_socket);
		m_axi_tlm_bridge.socket(dummy_ram.socket);

		signals_s_axi_pcie[0].connect(ep_bridge, "s_axi_pcie_m0_");
		signals_s_axi_pcie[0].connect(s_axi_tlm_bridge);

		signals_m_axi_pcie[0].connect(ep_bridge, "m_axi_pcie_m0_");
		signals_m_axi_pcie[0].connect(m_axi_tlm_bridge);

		signals_m_axi_usr[0].connect(ep_bridge, "m_axi_usr_0_");
		signals_m_axi_usr[0].connect(m_axi_usr_tlm_bridge);

		tlm2axi_sw_bridge.bridge_socket(s_axi_tlm_bridge.tgt_socket);
		m_axi_usr_tlm_bridge.socket.bind(ram.socket);

		tlm2axi_sw_bridge.irq(irq_req_bool);
		tlm2axi_sw_bridge.rst(rst);

		irq_ack.write(3);
	}
};

int sc_main(int argc, char *argv[])
{
	Verilated::commandArgs(argc, argv);
	Top top("Top");

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	trace(trace_fp, top, "top");

#if VM_TRACE
	Verilated::traceEverOn(true);
	// If verilator was invoked with --trace argument,
	// and if at run time passed the +trace argument, turn on tracing
	VerilatedVcdSc* tfp = NULL;
	const char* flag = Verilated::commandArgsPlusMatch("trace");
	if (flag && 0 == strcmp(flag, "+trace")) {
		tfp = new VerilatedVcdSc;
		tfp->open("vlt_dump.vcd");
	}
#endif

	if (argc > 1 && !strcmp(argv[1], "--debug")) {
		// We only have one level at the moment.
		top.set_debuglevel(1);
	}

	sc_start(2, SC_MS);

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
#if VM_TRACE
	if (tfp) { tfp->close(); tfp = NULL; }
#endif
	return 0;
}
