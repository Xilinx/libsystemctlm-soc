/*
 * This is a small example showing howto connect an RTL AXI Device
 * to a SystemC/TLM simulation using the TLM-2-AXI bridges.
 *
 * Copyright (c) 2019 Xilinx Inc.
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
#include "tlm-bridges/tlm2vfio-bridge.h"
#include "rtl-bridges/pcie-host/axi/tlm/tlm2axi-hw-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "traffic-generators/random-traffic.h"

#include "test-modules/memory.h"
#include "test-modules/utils.h"

//#define DESIGN_BZIP2

#ifdef DESIGN_BZIP2
#define RAM_SIZE (4 * 1024)

#define BASE_MASTER_BRIDGE(idx)     0x00000000
#define BASE_SLAVE_BRIDGE(idx)      0x00020000
#define BASE_BRAM(idx)              0xA4080000
#else
#define RAM_SIZE (16 * 1024)

#define BASE_MASTER_BRIDGE(idx)     (0x00000000 + 0x20000 * idx)
#define BASE_SLAVE_BRIDGE(idx)      (0x00100000 + 0x20000 * idx)
#define BASE_BRAM(idx)              (0xB0000000 + 0x04000 * idx)
#endif

static void DoneCallback(TLMTrafficGenerator *gen, int threadId)
{
	sc_stop();
}

// Top simulation module.
SC_MODULE(Top)
{
	sc_signal<bool> rst; // Active high.
	sc_signal<bool> rst_n; // Active low.
	sc_signal<bool> irq;

	tlm2axi_hw_bridge tlm_hw_bridge;
	vfio_dev vdev;
	tlm2vfio_bridge tlm2vfio;

	RandomTraffic *rand_xfers;
	tlm_splitter<2> splitter;
	TLMTrafficGenerator tg;

	memory ref_ram;

	void gen_rst_n(void) {
		rst_n.write(!rst.read());
	}

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name, unsigned int ram_size,
			const char *devname, int iommu_group,
			int bridge_idx) :
		rst("rst"),
		rst_n("rst_n"),
		irq("irq"),
		tlm_hw_bridge("tlm_hw_bridge",
			BASE_MASTER_BRIDGE(bridge_idx), BASE_BRAM(bridge_idx)),
		vdev(devname, iommu_group),
		tlm2vfio("tlm2vfio_bridge", 1, vdev, 0),
		splitter("splitter", true),
		tg("tg", 1),
		ref_ram("ref_ram", sc_time(1, SC_NS), ram_size)
	{
		SC_METHOD(gen_rst_n);
		sensitive << rst;

		if (bridge_idx >= 6) {
			rand_xfers = new RandomTraffic(0, ram_size - 8, UINT64_MAX & (~7), 1, 8, 8, 10000);
		} else {
			rand_xfers = new RandomTraffic(0, ram_size, UINT64_MAX, 1, ram_size, ram_size, 10000);
		}

		// Wire up the clock and reset signals.
		tlm_hw_bridge.rst(rst);

		rand_xfers->setInitMemory(true);
		rand_xfers->setMaxStreamingWidthLen(ram_size);

		tg.enableDebug();
		tg.addTransfers(*rand_xfers, 0, DoneCallback);
		tg.setStartDelay(sc_time(15, SC_US));

		tg.socket.bind(splitter.target_socket);
		splitter.i_sk[0]->bind(ref_ram.socket);
		splitter.i_sk[1]->bind(tlm_hw_bridge.tgt_socket);

		tlm_hw_bridge.bridge_socket(tlm2vfio.tgt_socket[0]);

		tlm_hw_bridge.irq(irq);
		tlm2vfio.irq(irq);
	}
};

int sc_main(int argc, char *argv[])
{
	sc_trace_file *trace_fp;
	int iommu_group;
	int bridge_idx;

	if (argc < 4) {
		printf("%s: device-name iommu-group bridge-index\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	trace_fp = sc_create_vcd_trace_file(argv[0]);
	iommu_group = strtoull(argv[2], NULL, 10);
	bridge_idx = strtoull(argv[3], NULL, 10);
	Top top("Top", RAM_SIZE, argv[1], iommu_group, bridge_idx);

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
