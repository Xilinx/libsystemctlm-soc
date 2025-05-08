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
#ifndef __AMD_VERSAL2_H__
#define __AMD_VERSAL2_H__

#include "systemc.h"

#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm_utils/tlm_quantumkeeper.h"

#include "remote-port-tlm.h"
#include "remote-port-tlm-memory-master.h"
#include "remote-port-tlm-memory-slave.h"
#include "remote-port-tlm-wires.h"

class amd_versal2
: public remoteport_tlm
{
private:
	class xilinx_emio_bank
	{
	public:
		sc_vector<sc_signal<bool> > in;
		sc_vector<sc_signal<bool> > out;
		sc_vector<sc_signal<bool> > out_enable;
		xilinx_emio_bank(const char *name_in, const char *name_out,
				 const char *name_out_en, int num);
	};

	class xilinx_mio_bank
	{
	public:
		sc_vector<sc_signal<bool> > in;
		sc_vector<sc_signal<bool> > out;
		xilinx_mio_bank(const char *name_in, const char *name_out,
				int num);
	};

	// Bottom
	remoteport_tlm_memory_master rp_m_fpd_axi_pl;
	remoteport_tlm_memory_master rp_m_lpd_axi_pl;

	remoteport_tlm_memory_master rp_m_mmu_noc0;

	remoteport_tlm_memory_master rp_m_fpd_axi_noc0;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc1;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc2;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc3;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc4;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc5;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc6;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc7;
	remoteport_tlm_memory_master rp_m_fpd_axi_nociso;

	remoteport_tlm_memory_master rp_m_lpd_axi_noc0;
	remoteport_tlm_memory_master rp_m_reserved0;

	remoteport_tlm_memory_master rp_m_pmxc_axi_noc0;  // needed?
	remoteport_tlm_memory_master rp_m_pmxc_npi;

	remoteport_tlm_memory_slave rp_s_pl_axi_fpd0;
	remoteport_tlm_memory_slave rp_s_pl_axi_fpd1;
	remoteport_tlm_memory_slave rp_s_pl_axi_fpd2;
	remoteport_tlm_memory_slave rp_s_pl_axi_fpd3;

	remoteport_tlm_memory_slave rp_s_noc_axi_fpd0;
	remoteport_tlm_memory_slave rp_s_noc_axi_fpd1;
	remoteport_tlm_memory_slave rp_s_noc_axi_fpd2;
	remoteport_tlm_memory_slave rp_s_noc_axi_fpd3;

	remoteport_tlm_memory_slave rp_s_pl_acp_apu;
	remoteport_tlm_memory_slave rp_s_pl_chi_fpd;

	remoteport_tlm_memory_slave rp_s_pl_axi_lpd;

	remoteport_tlm_memory_slave rp_s_noc_axi_pmcx0;

	remoteport_tlm_wires rp_pl2ps_irq;
	remoteport_tlm_wires rp_wires_out;
	remoteport_tlm_wires rp_emio0;
	remoteport_tlm_wires rp_emio1;
	remoteport_tlm_wires rp_emio2;
	remoteport_tlm_wires rp_npi_irq;

public:
	/* FPD */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_pl;

	/* LPD */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_lpd_axi_pl;

	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_mmu_noc0;

	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc1;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc2;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc3;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc4;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc5;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc6;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc7;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_nociso;

	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_lpd_axi_noc0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_reserved0;

	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_pmxc_axi_noc0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_pmxc_npi;

	/* FPD */
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_pl_chi_fpd;

	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_pl_axi_fpd0;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_pl_axi_fpd1;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_pl_axi_fpd2;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_pl_axi_fpd3;

	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_noc_axi_fpd0;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_noc_axi_fpd1;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_noc_axi_fpd2;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_noc_axi_fpd3;

	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_pl_acp_apu;

	/* LPD */
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_pl_axi_lpd;

	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_noc_axi_pmcx0;

	sc_vector<sc_signal<bool> > pl2ps_irq;
	sc_vector<sc_signal<bool> > npi_irq;
	sc_vector<sc_signal<bool> > pl_reset;

	xilinx_emio_bank *emio[3];

	amd_versal2(sc_core::sc_module_name name, const char *sk_descr,
				Iremoteport_tlm_sync *sync = NULL,
				bool blocking_socket = true);
	~amd_versal2(void);
};

#endif
