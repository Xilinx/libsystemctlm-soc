/*
 * Xilinx SystemC/TLM-2.0 Versal Net Wrapper.
 *
 * Written by Francisco Iglesias <francisco.iglesias@amd.com>
 *
 * Copyright (c) 2022, Xilinx Inc.
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

#include "xilinx-versal-net.h"
#include <sys/types.h>

#define VERSAL_NET_NUM_PL2PS_IRQ 16
#define VERSAL_NET_NUM_CPM_IRQ 4

#define VERSAL_NET_NUM_PL_RESET 4
#define VERSAL_NET_NUM_PS2PL_WIRES VERSAL_NET_NUM_PL_RESET

xilinx_versal_net::xilinx_versal_net(sc_module_name name, const char *sk_descr,
				Iremoteport_tlm_sync *sync,
				bool blocking_socket)
	: remoteport_tlm(name, -1, sk_descr, sync, blocking_socket),
	  rp_m_fpd_axi_pl("rp_m_fpd_axi_pl"),
	  rp_m_lpd_axi_pl("rp_m_lpd_axi_pl"),
	  rp_m_fpd_axi_noc0("rp_m_fpd_axi_noc0"),
	  rp_m_fpd_axi_noc1("rp_m_fpd_axi_noc1"),
	  rp_m_fpd_axi_noc2("rp_m_fpd_axi_noc2"),
	  rp_m_fpd_axi_noc3("rp_m_fpd_axi_noc3"),
	  rp_m_fpd_axi_noc4("rp_m_fpd_axi_noc4"),
	  rp_m_fpd_axi_noc5("rp_m_fpd_axi_noc5"),
	  rp_m_fpd_axi_noc6("rp_m_fpd_axi_noc6"),
	  rp_m_fpd_axi_noc7("rp_m_fpd_axi_noc7"),
	  rp_m_fpd_axi_noc_iso("rp_m_fpd_axi_noc_iso"),
	  rp_m_cpm_axi_noc0("rp_m_cpm_axi_noc0"),
	  rp_m_cpm_axi_noc1("rp_m_cpm_axi_noc1"),
	  rp_m_cpm_axi_noc2("rp_m_cpm_axi_noc2"),
	  rp_m_cpm_axi_noc3("rp_m_cpm_axi_noc3"),
	  rp_m_lpd_axi_noc0("rp_m_lpd_axi_noc0"),
	  rp_reserved_0("rp_reserved_0"),
	  rp_m_pmcx_axi_noc0("rp_m_pmcx_axi_noc0"),
	  rp_pmc_npi("rp_pmc_npi"),
	  rp_m_cpm("rp_m_cpm"),
	  rp_m_hnic("rp_m_hnic"),

	  rp_s_pl_chi_fpd("rp_s_pl_chi_fpd"),
	  rp_s_pl_axi_fpd0("rp_s_pl_axi_fpd0"),
	  rp_s_pl_axi_fpd1("rp_s_pl_axi_fpd1"),
	  rp_s_pl_axi_fpd2("rp_s_pl_axi_fpd2"),
	  rp_s_pl_axi_fpd3("rp_s_pl_axi_fpd3"),
	  rp_s_noc_axi_fpd0("rp_s_noc_axi_fpd0"),
	  rp_s_noc_axi_fpd1("rp_s_noc_axi_fpd1"),
	  rp_s_noc_axi_fpd2("rp_s_noc_axi_fpd2"),
	  rp_s_noc_axi_fpd3("rp_s_noc_axi_fpd3"),
	  rp_s_pl_acp_apu("rp_s_pl_acp_apu"),
	  rp_s_cpm("rp_s_cpm"),
	  rp_s_noc_axi_cpm("rp_s_noc_axi_cpm"),
	  rp_s_pl_axi_lpd("rp_s_pl_axi_lpd"),
	  rp_s_noc_axi_pmcx0("rp_s_noc_axi_pmcx0"),

	  rp_pl2ps_irq("rp_pl2ps_irq", VERSAL_NET_NUM_PL2PS_IRQ, 0),
	  rp_wires_out("rp_wires_out", 0, VERSAL_NET_NUM_PS2PL_WIRES),
	  rp_cpm_irq("rp_cpm_irq", VERSAL_NET_NUM_CPM_IRQ, 0),
	  pl2ps_irq("pl2ps_irq", VERSAL_NET_NUM_PL2PS_IRQ),
	  cpm_irq("cpm_irq", VERSAL_NET_NUM_CPM_IRQ),
	  pl_reset("pl_reset", VERSAL_NET_NUM_PL_RESET)
{
	unsigned int i;

	m_fpd_axi_pl = &rp_m_fpd_axi_pl.sk;
	m_lpd_axi_pl = &rp_m_lpd_axi_pl.sk;
	m_fpd_axi_noc0 = &rp_m_fpd_axi_noc0.sk;
	m_fpd_axi_noc1 = &rp_m_fpd_axi_noc1.sk;
	m_fpd_axi_noc2 = &rp_m_fpd_axi_noc2.sk;
	m_fpd_axi_noc3 = &rp_m_fpd_axi_noc3.sk;
	m_fpd_axi_noc4 = &rp_m_fpd_axi_noc4.sk;
	m_fpd_axi_noc5 = &rp_m_fpd_axi_noc5.sk;
	m_fpd_axi_noc6 = &rp_m_fpd_axi_noc6.sk;
	m_fpd_axi_noc7 = &rp_m_fpd_axi_noc7.sk;
	m_fpd_axi_noc_iso = &rp_m_fpd_axi_noc_iso.sk;
	m_cpm_axi_noc0 = &rp_m_cpm_axi_noc0.sk;
	m_cpm_axi_noc1 = &rp_m_cpm_axi_noc1.sk;
	m_cpm_axi_noc2 = &rp_m_cpm_axi_noc2.sk;
	m_cpm_axi_noc3 = &rp_m_cpm_axi_noc3.sk;
	m_lpd_axi_noc0 = &rp_m_lpd_axi_noc0.sk;
	s_reserved_0 = &rp_reserved_0.sk;
	m_pmcx_axi_noc0 = &rp_m_pmcx_axi_noc0.sk;
	pmc_npi = &rp_pmc_npi.sk;
	m_cpm = &rp_m_cpm.sk;
	m_hnic = &rp_m_hnic.sk;

	s_pl_chi_fpd = &rp_s_pl_chi_fpd.sk;
	s_pl_axi_fpd0 = &rp_s_pl_axi_fpd0.sk;
	s_pl_axi_fpd1 = &rp_s_pl_axi_fpd1.sk;
	s_pl_axi_fpd2 = &rp_s_pl_axi_fpd2.sk;
	s_pl_axi_fpd3 = &rp_s_pl_axi_fpd3.sk;
	s_noc_axi_fpd0 = &rp_s_noc_axi_fpd0.sk;
	s_noc_axi_fpd1 = &rp_s_noc_axi_fpd1.sk;
	s_noc_axi_fpd2 = &rp_s_noc_axi_fpd2.sk;
	s_noc_axi_fpd3 = &rp_s_noc_axi_fpd3.sk;
	s_pl_acp_apu = &rp_s_pl_acp_apu.sk;
	s_cpm = &rp_s_cpm.sk;
	s_noc_axi_cpm = &rp_s_noc_axi_cpm.sk;
	s_pl_axi_lpd = &rp_s_pl_axi_lpd.sk;
	s_noc_axi_pmcx0 = &rp_s_noc_axi_pmcx0.sk;

	for (i = 0; i < pl2ps_irq.size(); i++) {
		rp_pl2ps_irq.wires_in[i](pl2ps_irq[i]);
	}
	for (i = 0; i < pl_reset.size(); i++) {
		rp_wires_out.wires_out[i](pl_reset[i]);
	}
	for (i = 0; i < cpm_irq.size(); i++) {
		rp_cpm_irq.wires_in[i](cpm_irq[i]);
	}

	register_dev(2, &rp_reserved_0);

	register_dev(10, &rp_s_pl_axi_fpd0);
	register_dev(12, &rp_s_pl_axi_fpd1);
	register_dev(14, &rp_s_pl_axi_fpd2);

	register_dev(15, &rp_s_pl_acp_apu);
	register_dev(16, &rp_s_pl_chi_fpd);

	register_dev(17, &rp_s_noc_axi_fpd0);
	register_dev(18, &rp_s_noc_axi_fpd1);
	register_dev(19, &rp_s_noc_axi_fpd2);
	register_dev(20, &rp_s_noc_axi_fpd3);

	register_dev(21, &rp_s_noc_axi_cpm);

	register_dev(23, &rp_s_noc_axi_pmcx0);
	register_dev(24, &rp_s_pl_axi_lpd);

	register_dev(40, &rp_m_fpd_axi_pl);
	register_dev(42, &rp_m_lpd_axi_pl);

	register_dev(50, &rp_m_fpd_axi_noc0);
	register_dev(51, &rp_m_fpd_axi_noc1);
	register_dev(52, &rp_m_fpd_axi_noc2);
	register_dev(53, &rp_m_fpd_axi_noc3);
	register_dev(54, &rp_m_fpd_axi_noc4);
	register_dev(55, &rp_m_fpd_axi_noc5);

	register_dev(56, &rp_m_cpm_axi_noc0);
	register_dev(57, &rp_m_cpm_axi_noc1);

	register_dev(58, &rp_m_lpd_axi_noc0);
	register_dev(59, &rp_m_pmcx_axi_noc0);
	register_dev(60, &rp_pmc_npi);

	register_dev(80, &rp_pl2ps_irq);
	register_dev(83, &rp_wires_out);

	register_dev(84, &rp_s_pl_axi_fpd3);

	register_dev(85, &rp_m_fpd_axi_noc6);
	register_dev(86, &rp_m_fpd_axi_noc7);
	register_dev(87, &rp_m_fpd_axi_noc_iso);

	register_dev(88, &rp_m_cpm_axi_noc2);
	register_dev(89, &rp_m_cpm_axi_noc3);

	register_dev(90, &rp_m_cpm);
	register_dev(91, &rp_s_cpm);

	register_dev(92, &rp_m_hnic);
	register_dev(93, &rp_cpm_irq);
}
