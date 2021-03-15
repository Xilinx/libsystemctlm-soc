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
				Iremoteport_tlm_sync *sync,
				bool blocking_socket)
	: remoteport_tlm(name, -1, sk_descr, sync, blocking_socket),
	  rp_m_axi_fpd("rp_m_axi_fpd"),
	  rp_m_axi_lpd("rp_m_axi_lpd"),
	  rp_fpd_cci_noc_0("rp_fpd_cci_noc_0"),
	  rp_fpd_cci_noc_1("rp_fpd_cci_noc_1"),
	  rp_fpd_cci_noc_2("rp_fpd_cci_noc_2"),
	  rp_fpd_cci_noc_3("rp_fpd_cci_noc_3"),
	  rp_fpd_axi_noc_0("rp_fpd_axi_noc_0"),
	  rp_fpd_axi_noc_1("rp_fpd_axi_noc_1"),
	  rp_cpm_pcie_noc_0("rp_cpm_pcie_noc_0"),
	  rp_cpm_pcie_noc_1("rp_cpm_pcie_noc_1"),
	  rp_noc_lpd_axi_0("rp_noc_lpd_axi_0"),
	  rp_pmc_noc_axi_0("rp_pmc_noc_axi_0"),
	  rp_reserved_0("rp_reserved_0"),

	  rp_s_axi_fpd("rp_s_axi_fpd"),
	  rp_s_axi_gp_2("rp_s_axi_gp_2"),
	  rp_s_axi_lpd("rp_s_axi_lpd"),

	  rp_s_acp_fpd("rp_s_acp_fpd"),
	  rp_s_ace_fpd("rp_s_ace_fpd"),

	  rp_noc_fpd_axi_0("rp_noc_fpd_axi_0"),
	  rp_noc_fpd_axi_1("rp_noc_fpd_axi_1"),
	  rp_noc_fpd_cci_0("rp_noc_fpd_cci_0"),
	  rp_noc_fpd_cci_1("rp_noc_fpd_cci_1"),
	  rp_noc_cpm_pcie_0("rp_noc_cpm_pcie_0"),
	  rp_noc_cpm_pcie_1("rp_noc_cpm_pcie_1"),
	  rp_noc_pmc_axi_0("rp_noc_pmc_axi_0"),
	  rp_pl2ps_irq("rp_pl2ps_irq", VERSAL_NUM_PL2PS_IRQ, 0),
	  rp_wires_out("rp_wires_out", 0, VERSAL_NUM_PS2PL_WIRES),
	  pl2ps_irq("pl2ps_irq", VERSAL_NUM_PL2PS_IRQ),
	  pl_reset("pl_reset", VERSAL_NUM_PL_RESET)
{
	unsigned int i;

	s_reserved_0 = &rp_reserved_0.sk;
	m_axi_fpd = &rp_m_axi_fpd.sk;
	m_axi_lpd = &rp_m_axi_lpd.sk;
	fpd_cci_noc_0 = &rp_fpd_cci_noc_0.sk;
	fpd_cci_noc_1 = &rp_fpd_cci_noc_1.sk;
	fpd_cci_noc_2 = &rp_fpd_cci_noc_2.sk;
	fpd_cci_noc_3 = &rp_fpd_cci_noc_3.sk;
	fpd_axi_noc_0 = &rp_fpd_axi_noc_0.sk;
	fpd_axi_noc_1 = &rp_fpd_axi_noc_1.sk;
	cpm_pcie_noc_0 = &rp_cpm_pcie_noc_0.sk;
	cpm_pcie_noc_1 = &rp_cpm_pcie_noc_1.sk;
	noc_lpd_axi_0 = &rp_noc_lpd_axi_0.sk;
	pmc_noc_axi_0 = &rp_pmc_noc_axi_0.sk;

	s_axi_fpd = &rp_s_axi_fpd.sk;
	s_axi_gp_2 = &rp_s_axi_gp_2.sk;
	s_axi_lpd = &rp_s_axi_lpd.sk;

	s_acp_fpd = &rp_s_acp_fpd.sk;
	s_ace_fpd = &rp_s_ace_fpd.sk;

	noc_fpd_axi_0 = &rp_noc_fpd_axi_0.sk;
	noc_fpd_axi_1 = &rp_noc_fpd_axi_1.sk;
	noc_fpd_cci_0 = &rp_noc_fpd_cci_0.sk;
	noc_fpd_cci_1 = &rp_noc_fpd_cci_1.sk;
	noc_cpm_pcie_0 = &rp_noc_cpm_pcie_0.sk;
	noc_cpm_pcie_1 = &rp_noc_cpm_pcie_1.sk;
	noc_pmc_axi_0 = &rp_noc_pmc_axi_0.sk;

	for (i = 0; i < pl2ps_irq.size(); i++) {
		rp_pl2ps_irq.wires_in[i](pl2ps_irq[i]);
	}
	for (i = 0; i < pl_reset.size(); i++) {
		rp_wires_out.wires_out[i](pl_reset[i]);
	}

	register_dev(2, &rp_reserved_0);
	register_dev(10, &rp_s_axi_fpd);
	register_dev(12, &rp_s_axi_gp_2);
	register_dev(14, &rp_s_axi_lpd);
	register_dev(15, &rp_s_acp_fpd);
	register_dev(16, &rp_s_ace_fpd);
	register_dev(17, &rp_noc_fpd_axi_0);
	register_dev(18, &rp_noc_fpd_axi_1);
	register_dev(19, &rp_noc_fpd_cci_0);
	register_dev(20, &rp_noc_fpd_cci_1);
	register_dev(21, &rp_noc_cpm_pcie_0);
	register_dev(22, &rp_noc_cpm_pcie_1);
	register_dev(23, &rp_noc_pmc_axi_0);

	register_dev(40, &rp_m_axi_fpd);
	register_dev(42, &rp_m_axi_lpd);
	register_dev(50, &rp_fpd_cci_noc_0);
	register_dev(51, &rp_fpd_cci_noc_1);
	register_dev(52, &rp_fpd_cci_noc_2);
	register_dev(53, &rp_fpd_cci_noc_3);
	register_dev(54, &rp_fpd_axi_noc_0);
	register_dev(55, &rp_fpd_axi_noc_1);
	register_dev(56, &rp_cpm_pcie_noc_0);
	register_dev(57, &rp_cpm_pcie_noc_1);
	register_dev(58, &rp_noc_lpd_axi_0);
	register_dev(59, &rp_pmc_noc_axi_0);

	register_dev(80, &rp_pl2ps_irq);
	register_dev(83, &rp_wires_out);
}
