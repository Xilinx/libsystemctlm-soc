/*
 * TLM-2.0 PCI device base class.
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
#ifndef PCI_DEVICE_BASE_H__
#define PCI_DEVICE_BASE_H__

// This is a base class representing a PCIe device.
// Actual models may extend on this.
class pci_device_base : public sc_core::sc_module
{
public:
	// Config Address-Space
	tlm_utils::simple_target_socket<pci_device_base> config;
	// Up to 6 BAR ports.
	sc_vector<tlm_utils::simple_target_socket_tagged<pci_device_base> > bar;
	// A DMA port for end-point access into the host.
	tlm_utils::simple_initiator_socket<pci_device_base> dma;

	tlm_utils::simple_initiator_socket<pci_device_base> ats_req;
	tlm_utils::simple_target_socket<pci_device_base> ats_inv;

	// Interrupts. Normally this vector will be of size 1.
	// Depending on where device connects there may be infrastructure
	// to handle multiple interrupts (mapping these signals into MSI).
	//
	// If not, the DMA port can be used to send MSI/MSI-X interrupts.
	sc_vector<sc_out<bool> > irq;

	pci_device_base(sc_module_name name,
			unsigned int nr_bars,
			unsigned int nr_irqs);

protected:
	virtual void config_b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay);

	// Tagged callback for BAR access. ID represents the BAR nr.
	virtual void bar_b_transport(int bar_nr, tlm::tlm_generic_payload& trans,
				     sc_time& delay);

	virtual void b_transport_ats_inv(tlm::tlm_generic_payload& trans,
				     sc_time& delay);
};
#endif
