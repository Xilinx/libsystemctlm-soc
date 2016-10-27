/*
 Xilinx SystemC/TLM-2.0 Zynq Wrapper.

 Written by Edgar E. Iglesias <edgar.iglesias@xilinx.com>

 Copyright (c) 2016, Xilinx Inc.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 */

#include "systemc.h"

#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm_utils/tlm_quantumkeeper.h"

#include "remote-port-tlm.h"
#include "remote-port-tlm-memory-master.h"
#include "remote-port-tlm-memory-slave.h"
#include "remote-port-tlm-wires.h"

class xilinx_zynq
: public remoteport_tlm
{
private:
	remoteport_tlm_memory_master rp_m_axi_gp0;
	remoteport_tlm_memory_master rp_m_axi_gp1;

	remoteport_tlm_memory_slave rp_s_axi_gp0;
	remoteport_tlm_memory_slave rp_s_axi_gp1;

	remoteport_tlm_memory_slave rp_s_axi_hp0;
	remoteport_tlm_memory_slave rp_s_axi_hp1;
	remoteport_tlm_memory_slave rp_s_axi_hp2;
	remoteport_tlm_memory_slave rp_s_axi_hp3;

	remoteport_tlm_memory_slave rp_s_axi_acp;

	remoteport_tlm_wires rp_wires_in;
	remoteport_tlm_wires rp_wires_out;
	remoteport_tlm_wires rp_irq_out;

public:
	/*
	 * M_AXI_GP 0 - 1.
	 * These sockets represent the High speed PS to PL interfaces.
	 * These are AXI Slave ports on the PS side and AXI Master ports
	 * on the PL side.
	 *
	 * Used to transfer data from the PS to the PL.
	 */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *m_axi_gp[2];

	/*
	 * S_AXI_GP0 - 1.
	 * These sockets represent the High speed IO Coherent PL to PS
	 * interfaces.
	 *
	 * HP0 - 3.
	 * These sockets represent the High performance dataflow PL to PS interfaces.
	 *
	 * ACP
	 * Accelerator Coherency Port, used to transfered coherent data to
	 * the PS via the Cortex-A9 subsystem.
	 *
	 * These are AXI Master ports on the PS side and AXI Slave ports
	 * on the PL side.
	 *
	 * Used to transfer data from the PL to the PS.
	 */
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_gp[2];
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_hp[4];
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *s_axi_acp;

	/* PL (fabric) to PS interrupt signals.  */
	sc_vector<sc_signal<bool> > pl2ps_irq;

	/* PS to PL Interrupt signals.  */
	sc_vector<sc_signal<bool> > ps2pl_irq;

	/* FPGA out resets.  */
	sc_vector<sc_signal<bool> > ps2pl_rst;

	xilinx_zynq(sc_core::sc_module_name name, const char *sk_descr);
};
