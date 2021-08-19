/*
 * This is a small example showing howto connect a PCIe EP on an FPGA
 * to QEMU and SystemC/TLM simulation using the TLM bridges.
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
#include "tlm_utils/tlm_quantumkeeper.h"

#include "remote-port-tlm-pci-ep.h"
#include "tlm-bridges/tlm2vfio-bridge.h"
#include "rtl-bridges/pcie-host/axi/tlm/tlm2axi-hw-bridge.h"
#include "rtl-bridges/pcie-host/axi/tlm/axi2tlm-hw-bridge.h"

#include "soc/pci/xilinx/xdma.h"

#undef D
#define D(x) do {               \
        if (0) {                \
                x;              \
        }                       \
} while (0)

#define BASE_MASTER_BRIDGE	0x00000000
#define BASE_SLAVE_BRIDGE	0x00020000
#define DUT_OFFSET		0xB0000000

// Top simulation module.
SC_MODULE(Top)
{
	SC_HAS_PROCESS(Top);

	sc_signal<bool> rst; // Active high.
	sc_signal<bool> irq;

	vfio_dev vdev;
	tlm2vfio_bridge tlm2vfio;
	tlm2axi_hw_bridge tlm_master_hw_bridge;
	axi2tlm_hw_bridge tlm_slave_hw_bridge;

	remoteport_tlm_pci_ep rp_pci_ep;
	xilinx_xdma<0> xdma;

	void pull_reset(void) {
		/* Pull the reset signal.  */
		rst.write(true);
		wait(4, SC_US);
		rst.write(false);
	}

	Top(sc_module_name name, const char *sk_descr,
			const char *devname, int iommu_group) :
		sc_module(name),
		rst("rst"),
		irq("irq"),
		vdev(devname, iommu_group),
		tlm2vfio("tlm2vfio_bridge", 2, vdev, 0),
		tlm_master_hw_bridge("tlm_master_hw_bridge", BASE_MASTER_BRIDGE,
				     DUT_OFFSET),
		tlm_slave_hw_bridge("tlm_slave_hw_bridge", BASE_SLAVE_BRIDGE, 0, &vdev),
		rp_pci_ep("rp_pci_ep", 0, 1, 0, sk_descr),
		xdma("xdma")
	{
		m_qk.set_global_quantum(sc_time(10, SC_US));

		SC_THREAD(pull_reset);
		sensitive << rst;

		// Wire up the clock and reset signals.
		tlm_master_hw_bridge.rst(rst);
		tlm_slave_hw_bridge.rst(rst);
		rp_pci_ep.rst(rst);

		tlm_master_hw_bridge.bridge_socket(tlm2vfio.tgt_socket[0]);
		tlm_slave_hw_bridge.bridge_socket(tlm2vfio.tgt_socket[1]);

		tlm_master_hw_bridge.irq(irq);
		tlm_slave_hw_bridge.irq(irq);
		tlm2vfio.irq(irq);

		xdma.tlm_m_axib.bind(tlm_master_hw_bridge.tgt_socket);
		tlm_slave_hw_bridge.init_socket(xdma.tlm_s_axib);

		rp_pci_ep.bind(xdma);
	}

private:
	tlm_utils::tlm_quantumkeeper m_qk;
};

int sc_main(int argc, char *argv[])
{
	sc_trace_file *trace_fp;
	int iommu_group;
	int bridge_idx;

	if (argc < 4) {
		printf("%s: socket-description device-name iommu-group\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	trace_fp = sc_create_vcd_trace_file(argv[0]);
	iommu_group = strtoull(argv[3], NULL, 10);
	Top top("Top", argv[1], argv[2], iommu_group);

	sc_start();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
	return 0;
}
