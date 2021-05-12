/*
 * Remote-port PCIe device.
 *
 * In a QEMU co-simulation, this module allows SystemC to model a PCIe EP
 * attached to a QEMU PCIe RC.
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
#ifndef REMOTE_PORT_TLM_PCIE_H
#define REMOTE_PORT_TLM_PCIE_H

#include <assert.h>
#include "remote-port-tlm.h"
#include "remote-port-tlm-memory-master.h"
#include "remote-port-tlm-memory-slave.h"
#include "remote-port-tlm-wires.h"
#include "remote-port-tlm-ats.h"

#include "soc/pci/core/pci-device-base.h"

// Remote-Port PCIe End-Point
class remoteport_tlm_pci_ep
	: public sc_module
{
	SC_HAS_PROCESS(remoteport_tlm_pci_ep);
private:
	remoteport_tlm_memory_slave rp_dma;
	remoteport_tlm_wires rp_irq;
	remoteport_tlm_ats rp_ats;

public:
	sc_in<bool> rst;

	// TLM Socket to serve PCIe Config Space acceses.
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *config;
	// BARs (IO or MMIO).
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *bar[6];
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> &dma;

	tlm_utils::simple_target_socket<remoteport_tlm_ats> &ats_req;
	tlm_utils::simple_initiator_socket<remoteport_tlm_ats> &ats_inv;

	// Interrupts.
	// For legacy interrupts, this will be a vector of size 1.
	// When using MSI/MSI-X, you can either send transactions over the
	// dma socket or create a larger irq vector and let the remote-port peer
	// convert these signals into MSI/MSI-X messages.
	sc_vector<sc_in<bool> > &irq;

	sc_vector<sc_signal<bool> > signals_irq;

	// Constructor that auto-creates a new Remote-port adaptor.
	// This is suitable for having one Remote-port session per
	// PCIe EP, e.g in a hotpluggable setup.
	remoteport_tlm_pci_ep(sc_module_name name,
			int nr_io_bars,
			int nr_mmio_bars,
			int nr_irqs,
			const char *sk_descr,
			Iremoteport_tlm_sync *sync = NULL,
			bool blocking_socket = false)
		: sc_module(name),
		  rp_dma("rp_dma"),
		  rp_irq("rp_irq", nr_irqs, 0),
		  rp_ats("rp_ats"),
		  rst("rst"),
		  dma(rp_dma.sk),
		  ats_req(rp_ats.req),
		  ats_inv(rp_ats.inv),
		  irq(rp_irq.wires_in),
		  signals_irq("signals_irq", nr_irqs),
		  free_adaptor(true),
		  rp_config("rp_config"),
		  rp_io("rp_io", nr_io_bars),
		  rp_mmio("rp_mmio", nr_mmio_bars),
		  tieoff_config(NULL)
	{
		assert(sk_descr);
		adaptor = new remoteport_tlm("rp", -1, sk_descr,
					sync, blocking_socket);

		connect_rp_devs(0);
	}

	// Constructor that uses a pre-existing Remote-port adaptor.
	// This is suitable for setups where the PCIe connections are
	// fixes and not run-time pluggable.
	remoteport_tlm_pci_ep(sc_module_name name,
			int nr_io_bars,
			int nr_mmio_bars,
			int nr_irqs,
			remoteport_tlm *adaptor,
			int rp_dev_base)
		: sc_module(name),
		  rp_dma("rp_dma"),
		  rp_irq("rp_irq", nr_irqs, 0),
		  rp_ats("rp_ats"),
		  rst("rst"),
		  dma(rp_dma.sk),
		  ats_req(rp_ats.req),
		  ats_inv(rp_ats.inv),
		  irq(rp_irq.wires_in),
		  signals_irq("signals_irq", nr_irqs),
		  adaptor(adaptor),
		  free_adaptor(false),
		  rp_config("rp_config"),
		  rp_io("rp_io", nr_io_bars),
		  rp_mmio("rp_mmio", nr_mmio_bars),
		  tieoff_config(NULL)
	{
		assert(adaptor);
		connect_rp_devs(rp_dev_base);
	}

	~remoteport_tlm_pci_ep() {
		if (free_adaptor) {
			delete adaptor;
		}
		if (tieoff_config) {
			delete tieoff_config;
		}
	}

	void bind(pci_device_base &pcidev);

	void before_end_of_elaboration(void) {
		if (!rp_config.sk.size()) {
			tieoff_config =
				new tlm_utils::simple_target_socket<remoteport_tlm_pci_ep>("tieoff_config");
			rp_config.sk.bind(*tieoff_config);
		}
	}
private:
	remoteport_tlm *adaptor;
	bool free_adaptor;

	sc_signal<bool> sig_rst;

	remoteport_tlm_memory_master rp_config;
	sc_vector<remoteport_tlm_memory_master> rp_io;
	sc_vector<remoteport_tlm_memory_master> rp_mmio;

	tlm_utils::simple_target_socket<remoteport_tlm_pci_ep> *tieoff_config;

	void propagate_rst(void);
	void connect_rp_devs(int rp_dev_base);
};
#endif
