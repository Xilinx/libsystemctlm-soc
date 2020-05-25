/*
 * TLM-2.0 model of the Xilinx XDMA.
 *
 * Currently only supports PCIe-AXI brigde mode in tandem with QEMU.
 *
 * Copyright (c) 2020 Xilinx Inc.
 * Written by Edgar E. Iglesias.
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
#ifndef PCI_XILINX_XDMA_H__
#define PCI_XILINX_XDMA_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc.h"
#include "soc/pci/core/pci-device-base.h"

template <int NUM_USR_IRQ>
class xilinx_xdma : public pci_device_base
{
	SC_HAS_PROCESS(xilinx_xdma);
public:
	// South-bound towards the EP User-logic.
	// These are the AXI4 Memory Mapped Master/Slave Bypass ports.
	tlm_utils::simple_initiator_socket<xilinx_xdma> tlm_m_axib;
	tlm_utils::simple_target_socket<xilinx_xdma> tlm_s_axib;

	sc_vector<sc_in<bool> > usr_irq_reqv;

	xilinx_xdma(sc_core::sc_module_name name) :
		pci_device_base(name, 1, NUM_USR_IRQ),
		tlm_m_axib("tlm-m-axib"),
		tlm_s_axib("tlm-s-axib"),
		usr_irq_reqv("usr-irq-reqv", NUM_USR_IRQ)
	{
		int i;

		tlm_s_axib.register_b_transport(this,
					&xilinx_xdma::tlm_s_axib_b_transport);

		SC_THREAD(handle_irqv);
		for (i = 0; i < NUM_USR_IRQ; i++) {
			sensitive << usr_irq_reqv[i];
		}
	}

private:
	// Extends the PCI device base class forwarding BAR0 traffic
	// onto the m_axib port.
	void bar_b_transport(int bar_nr, tlm::tlm_generic_payload& trans,
			     sc_time& delay) {
		tlm_m_axib->b_transport(trans, delay);
	}

	void tlm_s_axib_b_transport(tlm::tlm_generic_payload& trans,
				     sc_time& delay) {
		dma->b_transport(trans, delay);
	}

	// Map usr_irq_reqv onto the PCI Base class.
	//
	// For now, this is a direct mapping on to the PCI base IRQ vector.
	// In the future we may want to implement our own mapping
	// to MSI/MSI-X without relying on QEMU doing that for us.
	void handle_irqv(void) {
		int i;

		while (true) {
			// Wait for sensitivity on any usr_irqv[]
			wait();

			for (i = 0; i < NUM_USR_IRQ; i++) {
				irq[i] = usr_irq_reqv[i];
			}
		}
	}
};
#endif
