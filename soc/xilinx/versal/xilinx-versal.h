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
	remoteport_tlm_memory_master rp_m_axi_fpd;
	remoteport_tlm_memory_master rp_m_axi_lpd;
	remoteport_tlm_memory_master rp_fpd_cci_noc_0;
	remoteport_tlm_memory_master rp_fpd_cci_noc_1;
	remoteport_tlm_memory_master rp_fpd_cci_noc_2;
	remoteport_tlm_memory_master rp_fpd_cci_noc_3;
	remoteport_tlm_memory_master rp_fpd_axi_noc_0;
	remoteport_tlm_memory_master rp_fpd_axi_noc_1;
	remoteport_tlm_memory_master rp_cpm_pcie_noc_0;
	remoteport_tlm_memory_master rp_cpm_pcie_noc_1;
	remoteport_tlm_memory_master rp_noc_lpd_axi_0;
	remoteport_tlm_memory_master rp_pmc_noc_axi_0;
	remoteport_tlm_memory_master rp_reserved_0;

	remoteport_tlm_memory_slave rp_s_axi_fpd;
	remoteport_tlm_memory_slave rp_s_axi_gp_2;
	remoteport_tlm_memory_slave rp_s_axi_lpd;
	remoteport_tlm_memory_slave rp_s_acp_fpd;
	remoteport_tlm_memory_slave rp_s_ace_fpd;

	remoteport_tlm_memory_slave rp_noc_fpd_axi_0;
	remoteport_tlm_memory_slave rp_noc_fpd_axi_1;
	remoteport_tlm_memory_slave rp_noc_fpd_cci_0;
	remoteport_tlm_memory_slave rp_noc_fpd_cci_1;
	remoteport_tlm_memory_slave rp_noc_cpm_pcie_0;
	remoteport_tlm_memory_slave rp_noc_cpm_pcie_1;
	remoteport_tlm_memory_slave rp_noc_pmc_axi_0;

	remoteport_tlm_wires rp_pl2ps_irq;
	remoteport_tlm_wires rp_wires_out;

public:
	/* FPD 0 and 1. Base PS only has port 0.  */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_axi_fpd;
	/* LPD.  */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_axi_lpd;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *fpd_cci_noc_0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *fpd_cci_noc_1;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *fpd_cci_noc_2;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *fpd_cci_noc_3;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *fpd_axi_noc_0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *fpd_axi_noc_1;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *cpm_pcie_noc_0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *cpm_pcie_noc_1;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *noc_lpd_axi_0;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *pmc_noc_axi_0;

	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *s_reserved_0;

	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_fpd;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_gp_2;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_lpd;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_acp_fpd;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_ace_fpd;

	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *noc_fpd_axi_0;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *noc_fpd_axi_1;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *noc_fpd_cci_0;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *noc_fpd_cci_1;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *noc_cpm_pcie_0;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *noc_cpm_pcie_1;
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *noc_pmc_axi_0;

	sc_vector<sc_signal<bool> > pl2ps_irq;
	sc_vector<sc_signal<bool> > pl_reset;

	xilinx_versal(sc_core::sc_module_name name, const char *sk_descr,
			Iremoteport_tlm_sync *sync = NULL,
			bool blocking_socket = true);
};
