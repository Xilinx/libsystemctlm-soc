/*
 * RTL-wrapper around the TLM model of the Xilinx XDMA.
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
#ifndef PCI_XILINX_XDMA_RTL_H__
#define PCI_XILINX_XDMA_RTL_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc.h"

#include "soc/pci/xilinx/xdma.h"
#include "tlm-bridges/tlm2axilite-bridge.h"
#include "tlm-bridges/axi2tlm-bridge.h"
#include "tests/test-modules/signals-axi.h"

template <int NUM_USR_IRQ>
class xilinx_xdma_rtl : public xilinx_xdma<NUM_USR_IRQ>
{
public:
	SC_HAS_PROCESS(xilinx_xdma_rtl);

	sc_in<bool> axi_clk;
	sc_in<bool> axi_aresetn;

	// TODO: Make some of these widths template variables.
	tlm2axilite_bridge<64, 32> m_axib;
	axi2tlm_bridge<64, 128, 16, 8, 1, 32, 32, 32, 32, 32 > s_axib;

	sc_in<sc_bv<NUM_USR_IRQ> > usr_irq_req;
	sc_out<sc_bv<NUM_USR_IRQ> > usr_irq_ack;

	xilinx_xdma_rtl(sc_core::sc_module_name name)
		: xilinx_xdma<NUM_USR_IRQ>::xilinx_xdma(name),
		axi_clk("axi_clk"),
		axi_aresetn("axi_aresetn"),
		m_axib("m_axib"),
		s_axib("s_axib"),
		usr_irq_req("usr_irq_req"),
		usr_irq_ack("usr_irq_ack"),
		signals_usr_irq_reqv("signals_isr_irq_reqv", NUM_USR_IRQ)
	{
		int i;

		for (i = 0; i < signals_usr_irq_reqv.size(); i++) {
			xilinx_xdma<NUM_USR_IRQ>::usr_irq_reqv[i](signals_usr_irq_reqv[i]);
		}

		m_axib.clk(axi_clk);
		m_axib.resetn(axi_aresetn);
		s_axib.clk(axi_clk);
		s_axib.resetn(axi_aresetn);

		SC_THREAD(handle_rtl_irq);
		xilinx_xdma<NUM_USR_IRQ>::sensitive << usr_irq_req;
	}

	void before_end_of_elaboration(void) {
		// Connect these late allowing the user to override
		// connections.

		if (!xilinx_xdma<NUM_USR_IRQ>::tlm_m_axib.size()) {
			xilinx_xdma<NUM_USR_IRQ>::tlm_m_axib.bind(m_axib.tgt_socket);
		}

		if (!s_axib.socket.size()) {
			s_axib.socket.bind(xilinx_xdma<NUM_USR_IRQ>::tlm_s_axib);
		}
	}

private:
	// To propagate usr_irq_req onto TLM xdma
	sc_vector<sc_signal<bool> > signals_usr_irq_reqv;

	void handle_rtl_irq(void) {
		int i;

		while (true) {
			sc_bv<NUM_USR_IRQ> n_irq_ack = 0;
			bool do_ack = false;

			// Wait for sensitivity
			wait();

			for (i = 0; i < NUM_USR_IRQ; i++) {
				bool p_req, n_req;

				p_req = signals_usr_irq_reqv[i].read();
				n_req = usr_irq_req.read()[i].to_bool();

				if (p_req != n_req) {
					if (usr_irq_ack.read()[i].to_bool()) {
						SC_REPORT_ERROR("XDMA",
							"IRQ while acked.");
					}
					n_irq_ack[i] = 1;
					do_ack = true;
				}
			}

			// Proxy sc_bv IRQ requests onto the TLM irq vector
			// of our base class.
			map_sc_bv2v<NUM_USR_IRQ>(signals_usr_irq_reqv,
						 usr_irq_req);
			if (do_ack) {
				wait(axi_clk.posedge_event());
				usr_irq_ack.write(n_irq_ack);

				wait(axi_clk.posedge_event());
				usr_irq_ack.write(0);
			}
		}
	}
};
#endif
