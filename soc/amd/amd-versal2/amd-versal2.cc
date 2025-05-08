/*
 * AMD SystemC/TLM-2.0 amd_versal2 Wrapper.
 *
 * Written by Francisco Iglesias <francisco.iglesias@amd.com>
 *
 * Copyright (c) 2025 Advanced Micro Devices Inc.
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

#include "amd-versal2.h"
#include <sys/types.h>

#define AMD_VERSAL2_NUM_PL2PS_IRQ 16
#define AMD_VERSAL2_NUM_CPM_IRQ 4
#define VERSAL_NUM_NPI_IRQ   12

#define AMD_VERSAL2_NUM_PL_RESET 4
#define AMD_VERSAL2_NUM_PS2PL_WIRES AMD_VERSAL2_NUM_PL_RESET

amd_versal2::xilinx_emio_bank::xilinx_emio_bank(const char *name_in,
						  const char *name_out,
						  const char *name_out_en,
						  int num)
  :in(name_in, num),
   out(name_out, num),
   out_enable(name_out_en, num)
{
}

amd_versal2::xilinx_mio_bank::xilinx_mio_bank(const char *name_in,
						const char *name_out,
						int num)
  :in(name_in, num),
   out(name_out, num)
{
}

amd_versal2::amd_versal2(sc_module_name name, const char *sk_descr,
				Iremoteport_tlm_sync *sync,
				bool blocking_socket)
	: remoteport_tlm(name, -1, sk_descr, sync, blocking_socket),

	  rp_m_fpd_axi_pl("rp_m_fpd_axi_pl"),
	  rp_m_lpd_axi_pl("rp_m_lpd_axi_pl"),

	  rp_m_mmu_noc0("rp_m_mmu_noc0"),

	  rp_m_fpd_axi_noc0("rp_m_fpd_axi_noc0"),
	  rp_m_fpd_axi_noc1("rp_m_fpd_axi_noc1"),
	  rp_m_fpd_axi_noc2("rp_m_fpd_axi_noc2"),
	  rp_m_fpd_axi_noc3("rp_m_fpd_axi_noc3"),
	  rp_m_fpd_axi_noc4("rp_m_fpd_axi_noc4"),
	  rp_m_fpd_axi_noc5("rp_m_fpd_axi_noc5"),
	  rp_m_fpd_axi_noc6("rp_m_fpd_axi_noc6"),
	  rp_m_fpd_axi_noc7("rp_m_fpd_axi_noc7"),
	  rp_m_fpd_axi_nociso("rp_m_fpd_axi_nociso"),

	  rp_m_lpd_axi_noc0("rp_m_lpd_axi_noc0"),
	  rp_m_reserved0("rp_m_reserved0"),

	  rp_m_pmxc_axi_noc0("rp_m_pmxc_axi_noc0"),
	  rp_m_pmxc_npi("rp_m_pmxc_npi"),

	  rp_s_pl_axi_fpd0("rp_s_pl_axi_fpd0"),
	  rp_s_pl_axi_fpd1("rp_s_pl_axi_fpd1"),
	  rp_s_pl_axi_fpd2("rp_s_pl_axi_fpd2"),
	  rp_s_pl_axi_fpd3("rp_s_pl_axi_fpd3"),

	  rp_s_noc_axi_fpd0("rp_s_noc_axi_fpd0"),
	  rp_s_noc_axi_fpd1("rp_s_noc_axi_fpd1"),
	  rp_s_noc_axi_fpd2("rp_s_noc_axi_fpd2"),
	  rp_s_noc_axi_fpd3("rp_s_noc_axi_fpd3"),

	  rp_s_pl_acp_apu("rp_s_pl_acp_apu"),
	  rp_s_pl_chi_fpd("rp_s_pl_chi_fpd"),

	  rp_s_pl_axi_lpd("rp_s_pl_axi_lpd"),
	  rp_s_noc_axi_pmcx0("rp_s_noc_axi_pmcx0"),

	  rp_pl2ps_irq("rp_pl2ps_irq", AMD_VERSAL2_NUM_PL2PS_IRQ, 0),
	  rp_wires_out("rp_wires_out", 0, AMD_VERSAL2_NUM_PS2PL_WIRES),
	  rp_emio0("emio0", 32, 64),
	  rp_emio1("emio1", 32, 64),
	  rp_emio2("emio2", 32, 64),
	  rp_npi_irq("rp_npi_irq", VERSAL_NUM_NPI_IRQ, 0),
	  pl2ps_irq("pl2ps_irq", AMD_VERSAL2_NUM_PL2PS_IRQ),
	  npi_irq("npi_irq", VERSAL_NUM_NPI_IRQ),
	  pl_reset("pl_reset", AMD_VERSAL2_NUM_PL_RESET)
{
	unsigned int i;

	for (i = 0; i < 3; i++) {
		char emio_in_name[20];
		char emio_out_name[20];
		char emio_out_en_name[20];
		snprintf(emio_in_name, sizeof(emio_in_name), "emio_%d_in", i);
		snprintf(emio_out_name, sizeof(emio_out_name),
			 "emio_%d_out", i);
		snprintf(emio_out_en_name, sizeof(emio_out_en_name),
			 "emio_out_en_%d", i);
		emio[i] = new xilinx_emio_bank(emio_in_name, emio_out_name,
                                      emio_out_en_name, 32);
	}

	m_fpd_axi_pl = &rp_m_fpd_axi_pl.sk;
	m_lpd_axi_pl = &rp_m_lpd_axi_pl.sk;

	m_mmu_noc0 = &rp_m_mmu_noc0.sk;

	m_fpd_axi_noc0 = &rp_m_fpd_axi_noc0.sk;
	m_fpd_axi_noc1 = &rp_m_fpd_axi_noc1.sk;
	m_fpd_axi_noc2 = &rp_m_fpd_axi_noc2.sk;
	m_fpd_axi_noc3 = &rp_m_fpd_axi_noc3.sk;
	m_fpd_axi_noc4 = &rp_m_fpd_axi_noc4.sk;
	m_fpd_axi_noc5 = &rp_m_fpd_axi_noc5.sk;
	m_fpd_axi_noc6 = &rp_m_fpd_axi_noc6.sk;
	m_fpd_axi_noc7 = &rp_m_fpd_axi_noc7.sk;
	m_fpd_axi_nociso = &rp_m_fpd_axi_nociso.sk;

	m_lpd_axi_noc0 = &rp_m_lpd_axi_noc0.sk;
	m_reserved0 = &rp_m_reserved0.sk;

	m_pmxc_axi_noc0 = &rp_m_pmxc_axi_noc0.sk;
	m_pmxc_npi = &rp_m_pmxc_npi.sk;

	s_pl_axi_fpd0 = &rp_s_pl_axi_fpd0.sk;
	s_pl_axi_fpd1 = &rp_s_pl_axi_fpd1.sk;
	s_pl_axi_fpd2 = &rp_s_pl_axi_fpd2.sk;
	s_pl_axi_fpd3 = &rp_s_pl_axi_fpd3.sk;

	s_noc_axi_fpd0 = &rp_s_noc_axi_fpd0.sk;
	s_noc_axi_fpd1 = &rp_s_noc_axi_fpd1.sk;
	s_noc_axi_fpd2 = &rp_s_noc_axi_fpd2.sk;
	s_noc_axi_fpd3 = &rp_s_noc_axi_fpd3.sk;

	s_pl_acp_apu = &rp_s_pl_acp_apu.sk;
	s_pl_chi_fpd = &rp_s_pl_chi_fpd.sk;

	s_pl_axi_lpd = &rp_s_pl_axi_lpd.sk;
	s_noc_axi_pmcx0 = &rp_s_noc_axi_pmcx0.sk;

	for (i = 0; i < pl2ps_irq.size(); i++) {
		rp_pl2ps_irq.wires_in[i](pl2ps_irq[i]);
	}
	for (i = 0; i < pl_reset.size(); i++) {
		rp_wires_out.wires_out[i](pl_reset[i]);
	}
	for (i = 0; i < npi_irq.size(); i++) {
		rp_npi_irq.wires_in[i](npi_irq[i]);
	}

	for (i = 0; i < emio[0]->out.size(); i++) {
		rp_emio0.wires_out[i](emio[0]->out[i]);
		rp_emio1.wires_out[i](emio[1]->out[i]);
		rp_emio2.wires_out[i](emio[2]->out[i]);
		rp_emio0.wires_in[i](emio[0]->in[i]);
		rp_emio1.wires_in[i](emio[1]->in[i]);
		rp_emio2.wires_in[i](emio[2]->in[i]);
		rp_emio0.wires_out[i + 32](emio[0]->out_enable[i]);
		rp_emio1.wires_out[i + 32](emio[1]->out_enable[i]);
		rp_emio2.wires_out[i + 32](emio[2]->out_enable[i]);
	}

	// dev_id assignments for the cosim remote ports must match those
	// of the remote peer.
	// For example, in remote peer QEMU, they are assigned in device-tree
	// file versal2-pl-remoteport.dtsi, property expression 'remote-ports ='.
	register_dev(2, &rp_m_reserved0);

	register_dev(10, &rp_s_pl_axi_fpd0);
	register_dev(12, &rp_s_pl_axi_fpd1);
	register_dev(14, &rp_s_pl_axi_fpd2);

	register_dev(15, &rp_s_pl_acp_apu);
	register_dev(16, &rp_s_pl_chi_fpd);

	register_dev(17, &rp_s_noc_axi_fpd0);
	register_dev(18, &rp_s_noc_axi_fpd1);
	register_dev(19, &rp_s_noc_axi_fpd2);
	register_dev(20, &rp_s_noc_axi_fpd3);

	// Reserved Device IDs
	// 21, 22

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

	// Reserved Device IDs
	// 56, 57

	register_dev(58, &rp_m_lpd_axi_noc0);
	register_dev(59, &rp_m_pmxc_axi_noc0);
	register_dev(60, &rp_m_pmxc_npi);

	register_dev(80, &rp_pl2ps_irq);
	register_dev(83, &rp_wires_out);

	register_dev(84, &rp_s_pl_axi_fpd3);

	register_dev(85, &rp_m_fpd_axi_noc6);
	register_dev(86, &rp_m_fpd_axi_noc7);
	register_dev(87, &rp_m_fpd_axi_nociso);

	// Reserved Device IDs
	// 88, 89, 90, 91, 92, 93

	register_dev(94, &rp_m_mmu_noc0);
	register_dev(95, &rp_emio0);
	register_dev(96, &rp_emio1);
	register_dev(97, &rp_emio2);
	register_dev(98, &rp_npi_irq);
}

amd_versal2::~amd_versal2(void)
{
	for(int i = 0; i < 3; i++) {
		delete(emio[i]);
	}
}
