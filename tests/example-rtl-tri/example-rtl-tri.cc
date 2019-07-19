/*
 * This is a small example showing howto connect an RTL AXI Device
 * to a SystemC/TLM simulation using the TLM-2-AXI bridges.
 *
 * Copyright (c) 2018 Xilinx Inc.
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

#include "tlm-bridges/axi2tlm-bridge.h"
#include "tlm-bridges/tlm2tri-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "tlm-modules/cache-tri.h"

#include "test-modules/signals-axi.h"
#include "test-modules/signals-tri.h"
#include "test-modules/utils.h"
#include "test-modules/memory.h"

#include "Vaxifull_dev.h"
#include "Vsystem.h"

#include <verilated_vcd_sc.h>
#include "verilated.h"

using namespace utils;

#define CONNECT_DUT(DUT, SIGS, SIGNAME) DUT.s00_axi_ ## SIGNAME(SIGS.SIGNAME)

#define CACHELINE_SIZE 64
#define CACHE_SIZE (4 * CACHELINE_SIZE)
#define RAM_SIZE (32 * CACHELINE_SIZE)

typedef AXISignals<
	64,		// ADDR_WIDTH
	512,		// DATA_WIDTH
	16,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	11,		// AWUSER_WIDTH
	11,		// ARUSER_WIDTH
	11,		// WUSER_WIDTH
	11,		// RUSER_WIDTH
	11 		// BUSER_WIDTH
> AXISignals_t;

typedef axi2tlm_bridge<
	64,		// ADDR_WIDTH
	512,		// DATA_WIDTH
	16,		// ID_WIDTH
	8,		// AxLEN_WIDTH
	1,		// AxLOCK_WIDTH
	11,		// AWUSER_WIDTH
	11,		// ARUSER_WIDTH
	11,		// WUSER_WIDTH
	11,		// RUSER_WIDTH
	11 		// BUSER_WIDTH
> axi2tlm_bridge_t;

TrafficDesc transactions(merge({
	// Write something to address 8
        Write(8, DATA(0x1, 0x2, 0x3, 0x4)),
	// Read it back and check that we get the expected data.
        Read(8, 4),
		Expect(DATA(0x1, 0x2, 0x3, 0x4), 4)
}));

// Top simulation module.
SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst_n; // Active low.

	TLMTrafficGenerator tg;
	cache_tri<CACHE_SIZE, CACHELINE_SIZE> m_cache;

	TRISignals tri_signals;
	tlm2tri_bridge tri_bridge;

	AXISignals_t axi_signals;
	axi2tlm_bridge_t axi_bridge;

	memory mem;

	// dut is the RTL AXI device we're testing.
	Vsystem system;

	sc_signal<bool>	sys_rst_n;
	sc_signal<bool>	pll_rst_n;
	sc_signal<bool>	clk_en;
	sc_signal<bool>	pll_bypass;
	sc_signal<bool>	pll_lock;

	// dummy 
	sc_signal<sc_bv<8> > sw;
	sc_signal<sc_bv<8> > leds;
	sc_signal<bool>	chip_io_slew;
	sc_signal<bool>	jtag_clk;
	sc_signal<bool>	jtag_rst_l;
	sc_signal<bool>	jtag_modesel;
	sc_signal<bool>	jtag_datain;
	sc_signal<bool>	jtag_dataout;
	sc_signal<bool>	async_mux;
	sc_signal<bool>	l15_transducer_l2miss;
	sc_signal<bool>	l15_transducer_noncacheable;
	sc_signal<bool>	l15_transducer_atomic;
	sc_signal<bool>	l15_transducer_threadid;
	sc_signal<bool>	l15_transducer_prefetch;
	sc_signal<bool>	l15_transducer_f4b;
	sc_signal<bool>	l15_transducer_inval_icache_all_way;
	sc_signal<bool>	l15_transducer_inval_dcache_all_way;
	sc_signal<bool>	l15_transducer_cross_invalidate;
	sc_signal<bool>	l15_transducer_inval_dcache_inval;
	sc_signal<bool>	l15_transducer_inval_icache_inval;
	sc_signal<bool>	l15_transducer_blockinitstore;
	sc_signal<sc_bv<2> >	chip_io_impsel;
	sc_signal<sc_bv<5> >	pll_rangea;
	sc_signal<sc_bv<2> >	clk_mux_sel;
	sc_signal<sc_bv<2> >	l15_transducer_error;
	sc_signal<sc_bv<64> >	l15_transducer_data_2;
	sc_signal<sc_bv<64> >	l15_transducer_data_3;
	sc_signal<sc_bv<12> >	l15_transducer_inval_address_15_4;
	sc_signal<sc_bv<2> >	l15_transducer_cross_invalidate_way;
	sc_signal<sc_bv<2> >	l15_transducer_inval_way;

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name) :
		clk("clk", sc_time(1, SC_US)),
		rst_n("rst_n"),
		tg("traffic-generator"),

		m_cache("tri-cache"),

		tri_signals("tri-signals"),
		tri_bridge("tri-bridge"),

		axi_signals("axi-signals"),
		axi_bridge("axi-bridge"),

		mem("mem", sc_time(10, SC_NS), 2048),
		system("system"), 

		sys_rst_n("sys_rst_n"),
		pll_rst_n("pll_rst_n"),
		clk_en("clk_en"),
		pll_bypass("pll_bypass"),
		pll_lock("pll_lock"),
		async_mux("async_mux"),
		pll_rangea("pll_rangea"),
		clk_mux_sel("clk_mux_sel")

	{
		// Configure the Traffic generator.
		tg.setStartDelay(sc_time(10, SC_MS));
		tg.enableDebug();
		tg.addTransfers(transactions);
		tg.socket.bind(m_cache.target_socket);

		m_cache.init_socket.bind(tri_bridge.tgt_socket);

		// Wire up the clock and reset signals.
		tri_bridge.clk(clk);
		tri_bridge.resetn(rst_n);
		axi_bridge.clk(clk);
		axi_bridge.resetn(rst_n);

		// Wire-up the bridge
		tri_signals.connect(tri_bridge);
		axi_signals.connect(axi_bridge);

		axi_bridge.socket.bind(mem.socket);

		connectSystem();
	}

	void connectSystem()
	{
		system.core_ref_clk(clk);
		system.io_clk(clk);
		system.chipset_clk(clk);

		system.sys_rst_n(sys_rst_n);
		system.pll_rst_n(pll_rst_n);
		system.clk_en(clk_en);
		system.pll_bypass(pll_bypass);
		system.pll_lock(pll_lock);

		// leave unconnected
		system.sw(sw);
		system.leds(leds);
		system.chip_io_slew(chip_io_slew);
		system.jtag_clk(jtag_clk);
		system.jtag_rst_l(jtag_rst_l);
		system.jtag_modesel(jtag_modesel);
		system.jtag_datain(jtag_datain);
		system.jtag_dataout(jtag_dataout);
		system.async_mux(async_mux);

		system.l15_transducer_l2miss(l15_transducer_l2miss);
		system.l15_transducer_noncacheable(l15_transducer_noncacheable);

		system.l15_transducer_atomic(l15_transducer_atomic);
		system.l15_transducer_threadid(l15_transducer_threadid);
		system.l15_transducer_prefetch(l15_transducer_prefetch);
		system.l15_transducer_f4b(l15_transducer_f4b);
		system.l15_transducer_inval_icache_all_way(l15_transducer_inval_icache_all_way);
		system.l15_transducer_inval_dcache_all_way(l15_transducer_inval_dcache_all_way);
		system.l15_transducer_cross_invalidate(l15_transducer_cross_invalidate);
		system.l15_transducer_inval_dcache_inval(l15_transducer_inval_dcache_inval);
		system.l15_transducer_inval_icache_inval(l15_transducer_inval_icache_inval);
		system.l15_transducer_blockinitstore(l15_transducer_blockinitstore);
		system.chip_io_impsel(chip_io_impsel);
		system.pll_rangea(pll_rangea);

		system.clk_mux_sel(clk_mux_sel);
		system.l15_transducer_error(l15_transducer_error);
		system.l15_transducer_data_2(l15_transducer_data_2);
		system.l15_transducer_data_3(l15_transducer_data_3);
		system.l15_transducer_inval_address_15_4(l15_transducer_inval_address_15_4);
		system.l15_transducer_cross_invalidate_way(l15_transducer_cross_invalidate_way);
		system.l15_transducer_inval_way(l15_transducer_inval_way);

		tri_signals.connect(system);

		system.m_axi_awlock(axi_signals.awlock);
		system.m_axi_awvalid(axi_signals.awvalid);
		system.m_axi_awready(axi_signals.awready);

		system.m_axi_wlast(axi_signals.wlast);
		system.m_axi_wvalid(axi_signals.wvalid);
		system.m_axi_wready(axi_signals.wready);
		system.m_axi_arlock(axi_signals.arlock);
		system.m_axi_arvalid(axi_signals.arvalid);
		system.m_axi_arready(axi_signals.arready);
		system.m_axi_rlast(axi_signals.rlast);
		system.m_axi_rvalid(axi_signals.rvalid);
		system.m_axi_rready(axi_signals.rready);
		system.m_axi_bvalid(axi_signals.bvalid);
		system.m_axi_bready(axi_signals.bready);
		system.m_axi_awid(axi_signals.awid);
		system.m_axi_awaddr(axi_signals.awaddr);
		system.m_axi_awlen(axi_signals.awlen);
		system.m_axi_awsize(axi_signals.awsize);
		system.m_axi_awburst(axi_signals.awburst);
		system.m_axi_awcache(axi_signals.awcache);
		system.m_axi_awprot(axi_signals.awprot);
		system.m_axi_awqos(axi_signals.awqos);
		system.m_axi_awregion(axi_signals.awregion);
		system.m_axi_awuser(axi_signals.awuser);
		system.m_axi_wid(axi_signals.wid);
		system.m_axi_wdata(axi_signals.wdata);
		system.m_axi_wstrb(axi_signals.wstrb);
		system.m_axi_wuser(axi_signals.wuser);
		system.m_axi_arid(axi_signals.arid);
		system.m_axi_araddr(axi_signals.araddr);
		system.m_axi_arlen(axi_signals.arlen);
		system.m_axi_arsize(axi_signals.arsize);
		system.m_axi_arburst(axi_signals.arburst);
		system.m_axi_arcache(axi_signals.arcache);
		system.m_axi_arprot(axi_signals.arprot);
		system.m_axi_arqos(axi_signals.arqos);
		system.m_axi_arregion(axi_signals.arregion);
		system.m_axi_aruser(axi_signals.aruser);
		system.m_axi_rid(axi_signals.rid);
		system.m_axi_rdata(axi_signals.rdata);
		system.m_axi_rresp(axi_signals.rresp);
		system.m_axi_ruser(axi_signals.ruser);
		system.m_axi_bid(axi_signals.bid);
		system.m_axi_bresp(axi_signals.bresp);
		system.m_axi_buser(axi_signals.buser);
	}

	void Trace(sc_trace_file *trace_fp)
	{
		sc_trace(trace_fp, clk, clk.name());
		sc_trace(trace_fp, rst_n, rst_n.name());

		sc_trace(trace_fp, pll_bypass, pll_bypass.name());
		sc_trace(trace_fp, clk_mux_sel, clk_mux_sel.name());
		sc_trace(trace_fp, pll_rangea, pll_rangea.name());

		sc_trace(trace_fp, async_mux, async_mux.name());
		sc_trace(trace_fp, pll_rst_n, pll_rst_n.name());
		sc_trace(trace_fp, pll_lock, pll_lock.name());
		sc_trace(trace_fp, clk_en, clk_en.name());
		sc_trace(trace_fp, sys_rst_n, sys_rst_n.name());
	}

};

void tick()
{
	sc_start(1, SC_US);
}

void reset_and_init(Top* top)
{
    top->pll_bypass = 1; // trin: pll_bypass is a switch in the pll; not reliable
    top->clk_mux_sel = 0; // selecting ref clock
//    // rangeA = x10 ? 5'b1 : x5 ? 5'b11110 : x2 ? 5'b10100 : x1 ? 5'b10010 : x20 ? 5'b0 : 5'b1;
    top->pll_rangea = 1; // 10x ref clock
//    // pll_rangea = 5'b11110; // 5x ref clock
//    // pll_rangea = 5'b00000; // 20x ref clock
    
//    // JTAG simulation currently not supported here
//    jtag_modesel = 1'b1;
//    jtag_datain = 1'b0;

    top->async_mux = 0;

    std::cout << "Before first ticks" << std::endl << std::flush;
    tick();
    std::cout << "After very first tick" << std::endl << std::flush;
//    // Reset PLL for 100 cycles
//    repeat(100)@(posedge core_ref_clk);
//    pll_rst_n = 1'b1;
    for (int i = 0; i < 100; i++) {
        tick();
    }
    top->pll_rst_n = 1;

    std::cout << "Before second ticks" << std::endl << std::flush;
//    // Wait for PLL lock
//    wait( pll_lock == 1'b1 );
    while (!top->pll_lock) {
        tick();
    }

    std::cout << "Before third ticks" << std::endl << std::flush;
//    // After 10 cycles turn on chip-level clock enable
//    repeat(10)@(posedge `CHIP_INT_CLK);
//    clk_en = 1'b1;
    for (int i = 0; i < 10; i++) {
        tick();
    }
    top->clk_en = 1;

//    // After 100 cycles release reset
//    repeat(100)@(posedge `CHIP_INT_CLK);
//    sys_rst_n = 1'b1;
//    jtag_rst_l = 1'b1;
    for (int i = 0; i < 100; i++) {
        tick();
    }
    top->sys_rst_n = 1;

//    // Wait for SRAM init, trin: 5000 cycles is about the lowest
//    repeat(5000)@(posedge `CHIP_INT_CLK);
    for (int i = 0; i < 5000; i++) {
        tick();
    }

//    top->diag_done = 1;

    //top->ciop_fake_iob.ok_iob = 1;
    //top->ok_iob = 1;
    std::cout << "Reset complete" << std::endl << std::flush;
}

int sc_main(int argc, char *argv[])
{
	Verilated::commandArgs(argc, argv);
	Top top("Top");

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	top.tri_signals.Trace(trace_fp);
	top.axi_signals.Trace(trace_fp);
	top.Trace(trace_fp);

#if VM_TRACE
        Verilated::traceEverOn(true);
        // If verilator was invoked with --trace argument,
        // and if at run time passed the +trace argument, turn on tracing
        VerilatedVcdSc* tfp = NULL;
        const char* flag = Verilated::commandArgsPlusMatch("trace");
        if (flag && 0 == strcmp(flag, "+trace")) {
                tfp = new VerilatedVcdSc;
                top.system.trace(tfp, 99);
                tfp->open("vlt_dump.vcd");
        }
#endif

	// Reset is active low. Emit a reset cycle.
	top.rst_n.write(false);
	sc_start(4, SC_US);
	top.rst_n.write(true);

	reset_and_init(&top);

	sc_start(20, SC_MS);
	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
#if VM_TRACE
        if (tfp) { tfp->close(); tfp = NULL; }
#endif

	return 0;
}
