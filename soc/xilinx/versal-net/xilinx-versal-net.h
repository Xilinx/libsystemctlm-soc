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
#ifndef __XILINX_VERSAL_NET_H__
#define __XILINX_VERSAL_NET_H__

#include "systemc.h"

#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm_utils/tlm_quantumkeeper.h"

#include "remote-port-tlm.h"
#include "remote-port-tlm-memory-master.h"
#include "remote-port-tlm-memory-slave.h"
#include "remote-port-tlm-wires.h"

class xilinx_versal_net
: public remoteport_tlm
{
private:
	remoteport_tlm_memory_master rp_m_fpd_axi_pl;
	remoteport_tlm_memory_master rp_m_lpd_axi_pl;

	remoteport_tlm_memory_master rp_m_fpd_axi_noc0;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc1;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc2;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc3;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc4;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc5;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc6;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc7;
	remoteport_tlm_memory_master rp_m_fpd_axi_noc_iso;

	remoteport_tlm_memory_master rp_m_cpm_axi_noc0;
	remoteport_tlm_memory_master rp_m_cpm_axi_noc1;
	remoteport_tlm_memory_master rp_m_cpm_axi_noc2;
	remoteport_tlm_memory_master rp_m_cpm_axi_noc3;

	remoteport_tlm_memory_master rp_m_lpd_axi_noc0;
	remoteport_tlm_memory_master rp_reserved_0;

	remoteport_tlm_memory_master rp_m_pmcx_axi_noc0;
	remoteport_tlm_memory_master rp_pmc_npi;

	remoteport_tlm_memory_master rp_m_cpm;
	remoteport_tlm_memory_master rp_m_hnic;

	remoteport_tlm_memory_slave rp_s_pl_chi_fpd;

	remoteport_tlm_memory_slave rp_s_pl_axi_fpd0;
	remoteport_tlm_memory_slave rp_s_pl_axi_fpd1;
	remoteport_tlm_memory_slave rp_s_pl_axi_fpd2;
	remoteport_tlm_memory_slave rp_s_pl_axi_fpd3;

	remoteport_tlm_memory_slave rp_s_noc_axi_fpd0;
	remoteport_tlm_memory_slave rp_s_noc_axi_fpd1;
	remoteport_tlm_memory_slave rp_s_noc_axi_fpd2;
	remoteport_tlm_memory_slave rp_s_noc_axi_fpd3;

	remoteport_tlm_memory_slave rp_s_pl_acp_apu;
	remoteport_tlm_memory_slave rp_s_cpm;

	remoteport_tlm_memory_slave rp_s_noc_axi_cpm;
	remoteport_tlm_memory_slave rp_s_pl_axi_lpd;

	remoteport_tlm_memory_slave rp_s_noc_axi_pmcx0;

	remoteport_tlm_wires rp_pl2ps_irq;
	remoteport_tlm_wires rp_wires_out;
	remoteport_tlm_wires rp_cpm_irq;

public:
	/* FPD */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_pl;
	/* LPD */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_lpd_axi_pl;

	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc1;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc2;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc3;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc4;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc5;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc6;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc7;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_fpd_axi_noc_iso;

	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_cpm_axi_noc0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_cpm_axi_noc1;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_cpm_axi_noc2;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_cpm_axi_noc3;

	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_lpd_axi_noc0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *s_reserved_0;

	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_pmcx_axi_noc0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *pmc_npi;

	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_cpm;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_hnic;

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
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_cpm;

	/* LPD */
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_noc_axi_cpm;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_pl_axi_lpd;

	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_noc_axi_pmcx0;

	sc_vector<sc_signal<bool> > pl2ps_irq;
	sc_vector<sc_signal<bool> > cpm_irq;
	sc_vector<sc_signal<bool> > pl_reset;

	xilinx_versal_net(sc_core::sc_module_name name, const char *sk_descr,
				Iremoteport_tlm_sync *sync = NULL,
				bool blocking_socket = true);
};

#endif
