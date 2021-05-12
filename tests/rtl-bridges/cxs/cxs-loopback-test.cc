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

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "test-modules/memory.h"
#include "test-modules/signals-cxs.h"

#include "chipdut.h"
#include "test-modules/utils-chi.h"

#include <verilated_vcd_sc.h>
#include "verilated.h"

using namespace utils::CHI;

#define LINE(l) ((l) * CACHELINE_SZ)

#define RN0_ID 0
#define HN0_ID 20

#define RN1_ID 1
#define HN1_ID 21

// Increase for more random traffic
#define NUM_TXNS_RNF0 20
#define NUM_TXNS_RNF1 20000

#define DATA_WIDTH 256
#define CNTL_WIDTH 14

typedef CXSSignals<DATA_WIDTH, CNTL_WIDTH> CXSSignals_t;

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
	// WriteUniquePtl
	//
	Write(LINE(4), burst_data, CACHELINE_SZ),

	//
	// WriteCleanFull + WriteEvictFull + ReadOnce
	//
	Read(LINE(4), CACHELINE_SZ),
		Expect(burst_data, CACHELINE_SZ),

	//
	// ReadOnce
	//
	Read(LINE(2)),
		Expect(DATA(0x0, 0x0, 0x0, 0x0), 4),

	//
	// ReadSharedNotDirty + WriteEvictFull + MakeUnique
	//
	Read(LINE(1)),
	Write(LINE(5), burst_data, CACHELINE_SZ),

	//
	// WriteBackFull + ReadOnceMakeInvalid + WriteUniquePtl
	//
	Read(LINE(17)),
	Write(LINE(17), burst_data, CACHELINE_SZ),
}));


typedef ChipDut<RN0_ID, HN0_ID> Chip0_t;
typedef ChipDut<RN1_ID, HN1_ID> Chip1_t;

SC_MODULE(Top)
{
	sc_signal<bool> rst_n;
	sc_clock clk;

	CXSSignals_t sgnls_cxs0;
	CXSSignals_t sgnls_cxs1;

	RandomTraffic rand_traffic0;
	RandomTraffic rand_traffic1;

	Chip0_t chip0;
	Chip1_t chip1;

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name,
		TrafficDesc& xfers0,
		TGDoneCallBack tgDoneCB) :
		sc_module(name),

		rst_n("resetn", true),
		clk("clk", sc_time(1, SC_US)),

		sgnls_cxs0("cxs_signals0"),
		sgnls_cxs1("cxs_signals1"),

		rand_traffic0(0, RAM_SIZE, (~(0x3llu)),
				1, RAM_SIZE, RAM_SIZE, NUM_TXNS_RNF0),
		rand_traffic1(0, RAM_SIZE, (~(0x3llu)),
				1, RAM_SIZE, RAM_SIZE, NUM_TXNS_RNF1),

		chip0("chip0", clk, rst_n),
		chip1("chip1", clk, rst_n),

		m_tgDoneCB(tgDoneCB)
	{
		sc_time startDelay = sc_time(500, SC_US);

		//
		// Configure the System Address Map on HN0
		//
		chip0.icn.SystemAddressMap().AddMap(0, RAM_SIZE/2, HN1_ID);

		//
		// Configure the CCIX port on chip 0
		//
		chip0.icn.port_CCIX[0]->AddRemoteAgent(RN1_ID);
		chip0.icn.port_CCIX[0]->AddRemoteAgent(HN1_ID);

		//
		// Configure the System Address Map on HN1
		//
		chip1.icn.SystemAddressMap().AddMap(RAM_SIZE/2, RAM_SIZE/2, HN0_ID);

		//
		// Configure the CCIX port on chip 1
		//
		chip1.icn.port_CCIX[0]->AddRemoteAgent(RN0_ID);
		chip1.icn.port_CCIX[0]->AddRemoteAgent(HN0_ID);

		//
		// Connect TX Chip0 and RX chip1
		//
		chip0.ConnectTX(sgnls_cxs0);
		chip1.ConnectRX(sgnls_cxs0);

		//
		// Connect TX Chip1 and RX chip0
		//
		chip1.ConnectTX(sgnls_cxs1);
		chip0.ConnectRX(sgnls_cxs1);

		//
		// Traffig generators
		//
		SetupTG(chip0, startDelay, xfers0, tgDoneCB);

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
	Verilated::commandArgs(argc, argv);
	Top top("Top", xfers, tgDoneCallBack);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, top.clk, top.clk.name());
	sc_trace(trace_fp, top.rst_n, top.rst_n.name());

	sc_trace(trace_fp, top.chip1.irq_out, top.chip1.irq_out.name());
	sc_trace(trace_fp, top.chip1.irq_ack, top.chip1.irq_ack.name());

	top.sgnls_cxs0.Trace(trace_fp);
	top.sgnls_cxs1.Trace(trace_fp);

	top.chip0.signals_al.Trace(trace_fp);
	top.chip1.signals_al.Trace(trace_fp);

#if VM_TRACE
        Verilated::traceEverOn(true);
        // If verilator was invoked with --trace argument,
        // and if at run time passed the +trace argument, turn on tracing
        VerilatedVcdSc* tfp = NULL;
        const char* flag = Verilated::commandArgsPlusMatch("trace");
        if (flag && 0 == strcmp(flag, "+trace")) {
                tfp = new VerilatedVcdSc;
                top.chip0.dut.trace(tfp, 99);
                top.chip1.dut.trace(tfp, 99);
                tfp->open("vlt_dump.vcd");
        }
#endif
	tgDone = &top.tgDone;

	// Reset is active low. Emit a reset cycle.
	top.rst_n.write(false);
	sc_start(4, SC_US);
	top.rst_n.write(true);

	sc_start();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

#if VM_TRACE
        if (tfp) { tfp->close(); tfp = NULL; }
#endif
	return 0;
}
