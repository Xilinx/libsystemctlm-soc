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

#include "systemc.h"

#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm_utils/tlm_quantumkeeper.h"

#include "remote-port-tlm.h"
#include "remote-port-tlm-memory-master.h"
#include "remote-port-tlm-memory-slave.h"
#include "remote-port-tlm-wires.h"

class xilinx_versal
: public remoteport_tlm
{
private:
	remoteport_tlm_memory_master rp_m_axi_gp_0;
	remoteport_tlm_memory_master rp_m_axi_gp_2;
	remoteport_tlm_memory_master rp_if_ps_noc_cci_0;
	remoteport_tlm_memory_master rp_if_ps_noc_cci_1;
	remoteport_tlm_memory_master rp_if_ps_noc_cci_2;
	remoteport_tlm_memory_master rp_if_ps_noc_cci_3;
	remoteport_tlm_memory_master rp_if_ps_noc_nci_0;
	remoteport_tlm_memory_master rp_if_ps_noc_nci_1;
	remoteport_tlm_memory_master rp_if_ps_noc_pcie_0;
	remoteport_tlm_memory_master rp_if_ps_noc_pcie_1;
	remoteport_tlm_memory_master rp_if_ps_noc_rpu_0;
	remoteport_tlm_memory_master rp_if_pmc_noc_axi_0;

	remoteport_tlm_memory_slave rp_s_axi_gp_0;
	remoteport_tlm_memory_slave rp_s_axi_gp_2;
	remoteport_tlm_memory_slave rp_s_axi_gp_4;
	remoteport_tlm_memory_slave rp_s_axi_acp;
	remoteport_tlm_memory_slave rp_s_axi_ace;

	remoteport_tlm_memory_slave rp_if_noc_ps_nci_0;
	remoteport_tlm_memory_slave rp_if_noc_ps_nci_1;
	remoteport_tlm_memory_slave rp_if_noc_ps_cci_0;
	remoteport_tlm_memory_slave rp_if_noc_ps_cci_1;
	remoteport_tlm_memory_slave rp_if_noc_ps_pcie_0;
	remoteport_tlm_memory_slave rp_if_noc_ps_pcie_1;
	remoteport_tlm_memory_slave rp_if_noc_pmc_axi_0;

	remoteport_tlm_wires rp_pl2ps_irq;
	remoteport_tlm_wires rp_wires_out;

public:
	/* FPD 0 and 1. Base PS only has port 0.  */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_axi_gp_0;
	/* LPD.  */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_axi_gp_2;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *if_ps_noc_cci_0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *if_ps_noc_cci_1;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *if_ps_noc_cci_2;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *if_ps_noc_cci_3;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *if_ps_noc_nci_0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *if_ps_noc_nci_1;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *if_ps_noc_pcie_0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *if_ps_noc_pcie_1;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *if_ps_noc_rpu_0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *if_pmc_noc_axi_0;

	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_gp_0;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_gp_2;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_gp_4;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_acp;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_ace;

	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *if_noc_ps_nci_0;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *if_noc_ps_nci_1;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *if_noc_ps_cci_0;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *if_noc_ps_cci_1;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *if_noc_ps_pcie_0;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *if_noc_ps_pcie_1;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *if_noc_pmc_axi_0;

	sc_vector<sc_signal<bool> > pl2ps_irq;
	sc_vector<sc_signal<bool> > pl_reset;

	xilinx_versal(sc_core::sc_module_name name, const char *sk_descr,
			Iremoteport_tlm_sync *sync = NULL);
};
