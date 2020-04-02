/*
 * Xilinx SystemC/TLM-2.0 Versal Wrapper.
 *
 * Written by Edgar E. Iglesias <edgar.iglesias@xilinx.com>
 *
 * Copyright (c) 2020, Xilinx Inc.
 * All rights reserved.
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

#include <inttypes.h>

#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

using namespace sc_core;
using namespace std;

#include "xilinx-versal.h"
#include <sys/types.h>

#define VERSAL_NUM_PL2PS_IRQ 16

#define VERSAL_NUM_PL_RESET 4
#define VERSAL_NUM_PS2PL_WIRES VERSAL_NUM_PL_RESET

xilinx_versal::xilinx_versal(sc_module_name name, const char *sk_descr,
				Iremoteport_tlm_sync *sync)
	: remoteport_tlm(name, -1, sk_descr),
	  rp_m_axi_gp_0("rp_m_axi_gp_0"),
	  rp_m_axi_gp_2("rp_m_axi_gp_2"),
	  rp_if_ps_noc_cci_0("rp_if_ps_noc_cci_0"),
	  rp_if_ps_noc_cci_1("rp_if_ps_noc_cci_1"),
	  rp_if_ps_noc_cci_2("rp_if_ps_noc_cci_2"),
	  rp_if_ps_noc_cci_3("rp_if_ps_noc_cci_3"),
	  rp_if_ps_noc_nci_0("rp_if_ps_noc_nci_0"),
	  rp_if_ps_noc_nci_1("rp_if_ps_noc_nci_1"),
	  rp_if_ps_noc_pcie_0("rp_if_ps_noc_pcie_0"),
	  rp_if_ps_noc_pcie_1("rp_if_ps_noc_pcie_1"),
	  rp_if_ps_noc_rpu_0("rp_if_ps_noc_rpu_0"),
	  rp_if_pmc_noc_axi_0("rp_if_pmc_noc_axi_0"),

	  rp_s_axi_gp_0("rp_s_axi_gp_0"),
	  rp_s_axi_gp_2("rp_s_axi_gp_2"),
	  rp_s_axi_gp_4("rp_s_axi_gp_4"),

	  rp_s_axi_acp("rp_s_axi_acp"),
	  rp_s_axi_ace("rp_s_axi_ace"),

	  rp_if_noc_ps_nci_0("rp_if_noc_ps_nci_0"),
	  rp_if_noc_ps_nci_1("rp_if_noc_ps_nci_1"),
	  rp_if_noc_ps_cci_0("rp_if_noc_ps_cci_0"),
	  rp_if_noc_ps_cci_1("rp_if_noc_ps_cci_1"),
	  rp_if_noc_ps_pcie_0("rp_if_noc_ps_pcie_0"),
	  rp_if_noc_ps_pcie_1("rp_if_noc_ps_pcie_1"),
	  rp_if_noc_pmc_axi_0("rp_if_noc_pmc_axi_0"),
	  rp_pl2ps_irq("rp_pl2ps_irq", VERSAL_NUM_PL2PS_IRQ, 0),
	  rp_wires_out("rp_wires_out", 0, VERSAL_NUM_PS2PL_WIRES),
	  pl2ps_irq("pl2ps_irq", VERSAL_NUM_PL2PS_IRQ),
	  pl_reset("pl_reset", VERSAL_NUM_PL_RESET)
{
	int i;

	m_axi_gp_0 = &rp_m_axi_gp_0.sk;
	m_axi_gp_2 = &rp_m_axi_gp_2.sk;
	if_ps_noc_cci_0 = &rp_if_ps_noc_cci_0.sk;
	if_ps_noc_cci_1 = &rp_if_ps_noc_cci_1.sk;
	if_ps_noc_cci_2 = &rp_if_ps_noc_cci_2.sk;
	if_ps_noc_cci_3 = &rp_if_ps_noc_cci_3.sk;
	if_ps_noc_nci_0 = &rp_if_ps_noc_nci_0.sk;
	if_ps_noc_nci_1 = &rp_if_ps_noc_nci_1.sk;
	if_ps_noc_pcie_0 = &rp_if_ps_noc_pcie_0.sk;
	if_ps_noc_pcie_1 = &rp_if_ps_noc_pcie_1.sk;
	if_ps_noc_rpu_0 = &rp_if_ps_noc_rpu_0.sk;
	if_pmc_noc_axi_0 = &rp_if_pmc_noc_axi_0.sk;

	s_axi_gp_0 = &rp_s_axi_gp_0.sk;
	s_axi_gp_2 = &rp_s_axi_gp_2.sk;
	s_axi_gp_4 = &rp_s_axi_gp_4.sk;

	s_axi_acp = &rp_s_axi_acp.sk;
	s_axi_ace = &rp_s_axi_ace.sk;

	if_noc_ps_nci_0 = &rp_if_noc_ps_nci_0.sk;
	if_noc_ps_nci_1 = &rp_if_noc_ps_nci_1.sk;
	if_noc_ps_cci_0 = &rp_if_noc_ps_cci_0.sk;
	if_noc_ps_cci_1 = &rp_if_noc_ps_cci_1.sk;
	if_noc_ps_pcie_0 = &rp_if_noc_ps_pcie_0.sk;
	if_noc_ps_pcie_1 = &rp_if_noc_ps_pcie_1.sk;
	if_noc_pmc_axi_0 = &rp_if_noc_pmc_axi_0.sk;

	for (i = 0; i < pl2ps_irq.size(); i++) {
		rp_pl2ps_irq.wires_in[i](pl2ps_irq[i]);
	}
	for (i = 0; i < pl_reset.size(); i++) {
		rp_wires_out.wires_out[i](pl_reset[i]);
	}

	register_dev(10, &rp_s_axi_gp_0);
	register_dev(12, &rp_s_axi_gp_2);
	register_dev(14, &rp_s_axi_gp_4);
	register_dev(15, &rp_s_axi_acp);
	register_dev(16, &rp_s_axi_ace);
	register_dev(17, &rp_if_noc_ps_nci_0);
	register_dev(18, &rp_if_noc_ps_nci_1);
	register_dev(19, &rp_if_noc_ps_cci_0);
	register_dev(20, &rp_if_noc_ps_cci_1);
	register_dev(21, &rp_if_noc_ps_pcie_0);
	register_dev(22, &rp_if_noc_ps_pcie_1);
	register_dev(23, &rp_if_noc_pmc_axi_0);

	register_dev(40, &rp_m_axi_gp_0);
	register_dev(42, &rp_m_axi_gp_2);
	register_dev(50, &rp_if_ps_noc_cci_0);
	register_dev(51, &rp_if_ps_noc_cci_1);
	register_dev(52, &rp_if_ps_noc_cci_2);
	register_dev(53, &rp_if_ps_noc_cci_3);
	register_dev(54, &rp_if_ps_noc_nci_0);
	register_dev(55, &rp_if_ps_noc_nci_1);
	register_dev(56, &rp_if_ps_noc_pcie_0);
	register_dev(57, &rp_if_ps_noc_pcie_1);
	register_dev(58, &rp_if_ps_noc_rpu_0);
	register_dev(59, &rp_if_pmc_noc_axi_0);

	register_dev(80, &rp_pl2ps_irq);
	register_dev(83, &rp_wires_out);
}
