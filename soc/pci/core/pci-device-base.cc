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

#include "systemc.h"

#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "soc/pci/core/pci-device-base.h"

pci_device_base::pci_device_base(sc_module_name name,
				 unsigned int nr_bars,
				 unsigned int nr_irqs)
	: sc_module(name),
	  config("config"),
	  bar("bar", nr_bars),
	  dma("dma"),
	  ats_req("ats_req"),
	  ats_inv("ats_inv"),
	  irq("irq", nr_irqs)
{
	unsigned int i;

	config.register_b_transport(this, &pci_device_base::config_b_transport);

	for (i = 0; i < bar.size(); i++) {
		bar[i].register_b_transport(this,
					    &pci_device_base::bar_b_transport,
					    i);
	}

	ats_inv.register_b_transport(this,
					&pci_device_base::b_transport_ats_inv);
}

void pci_device_base::config_b_transport(tlm::tlm_generic_payload& trans,
					 sc_time& delay)
{
	if (trans.is_read()) {
		// User needs to implement an infrastructure for CONFIG-space
		// if reads are forwarded to us.
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
	} else {
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}
}

void pci_device_base::bar_b_transport(int bar_nr,
				      tlm::tlm_generic_payload& trans,
				      sc_time& delay)
{
	trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
}

void pci_device_base::b_transport_ats_inv(tlm::tlm_generic_payload& trans,
					 sc_time& delay)
{
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}
