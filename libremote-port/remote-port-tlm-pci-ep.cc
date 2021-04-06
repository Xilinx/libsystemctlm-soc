/*
 * System-C TLM-2.0 remoteport PCIe device.
 *
 * Copyright (c) 2020 Xilinx Inc
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

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/atsattr.h"

#include "remote-port-tlm-pci-ep.h"

void remoteport_tlm_pci_ep::propagate_rst(void) {
	sig_rst.write(rst.read());
}

/*
 * RP-dev allocation.
 *
 * We allocate 20 RP devices for a single PCIe device.
 * dev          Function
 * 0            Config space
 * 1            Legacy IRQ
 * 2            Reserved for Messages
 * 3            DMA from the End-point towards us.
 * 4 - 9        Reserved
 * 10 - 20      IO or Memory Mapped BARs (6 + 4 reserved)
 * 21           ATS
 */

// Connect all remote-port objects to public members.
void remoteport_tlm_pci_ep::connect_rp_devs(int rp_dev_base) {
	unsigned int i;

	if (rp_io.size() + rp_mmio.size() > 6) {
		SC_REPORT_ERROR("rp-pci-ep", "Too many BARs!\n");
		return;
	}

	// Reset propagation.
	adaptor->rst(sig_rst);
	SC_METHOD(propagate_rst);
	dont_initialize();
	sensitive << rst;

	config = &rp_config.sk;
	adaptor->register_dev(rp_dev_base, &rp_config);
	adaptor->register_dev(rp_dev_base + 1, &rp_irq);
	adaptor->register_dev(rp_dev_base + 3, &rp_dma);

	for (i = 0; i < rp_io.size(); i++) {
		bar[i] = &rp_io[i].sk;

		adaptor->register_dev(rp_dev_base + 10 + i, &rp_io[i]);
	}

	for (i = 0; i < rp_mmio.size(); i++) {
		bar[rp_io.size() + i] = &rp_mmio[i].sk;
		adaptor->register_dev(rp_dev_base + 10 + rp_io.size() + i, &rp_mmio[i]);
	}

	adaptor->register_dev(rp_dev_base + 21, &rp_ats);
}

void remoteport_tlm_pci_ep::bind(pci_device_base &dev) {
	unsigned int i;

	config->bind(dev.config);
	dev.dma.bind(dma);

	for (i = 0; i < dev.bar.size(); i++) {
		bar[i]->bind(dev.bar[i]);
	}

	for (i = 0; i < dev.irq.size() && i < irq.size(); i++) {
		irq[i](signals_irq[i]);
		dev.irq[i](signals_irq[i]);
	}

	dev.ats_req.bind(ats_req);
	ats_inv.bind(dev.ats_inv);
}
