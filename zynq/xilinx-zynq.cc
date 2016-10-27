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

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <inttypes.h>

#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

using namespace sc_core;
using namespace std;

#include "xilinx-zynq.h"
#include <sys/types.h>

xilinx_zynq::xilinx_zynq(sc_module_name name, const char *sk_descr)
	: remoteport_tlm(name, -1, sk_descr),
	  rp_m_axi_gp0("rp_m_axi_gp0"),
	  rp_m_axi_gp1("rp_m_axi_gp1"),
	  rp_s_axi_gp0("rp_s_axi_gp0"),
	  rp_s_axi_gp1("rp_s_axi_gp1"),
	  rp_s_axi_hp0("rp_s_axi_hp0"),
	  rp_s_axi_hp1("rp_s_axi_hp1"),
	  rp_s_axi_hp2("rp_s_axi_hp2"),
	  rp_s_axi_hp3("rp_s_axi_hp3"),
	  rp_s_axi_acp("rp_s_axi_acp"),
	  rp_wires_in("wires_in", 20, 0),
	  rp_wires_out("wires_out", 0, 17),
	  rp_irq_out("irq_out", 0, 28),
	  pl2ps_irq("pl2ps_irq", 20),
	  ps2pl_irq("ps2pl_irq", 28),
	  ps2pl_rst("ps2pl_rst", 17)
{
	int i;

	m_axi_gp[0] = &rp_m_axi_gp0.sk;
	m_axi_gp[1] = &rp_m_axi_gp1.sk;

	s_axi_gp[0] = &rp_s_axi_gp0.sk;
	s_axi_gp[1] = &rp_s_axi_gp1.sk;

	s_axi_hp[0] = &rp_s_axi_hp0.sk;
	s_axi_hp[1] = &rp_s_axi_hp1.sk;
	s_axi_hp[2] = &rp_s_axi_hp2.sk;
	s_axi_hp[3] = &rp_s_axi_hp3.sk;
	s_axi_acp = &rp_s_axi_acp.sk;

	/* PL to PS Interrupt signals.  */
	for (i = 0; i < 20; i++) {
		rp_wires_in.wires_in[i](pl2ps_irq[i]);
	}

	/* PS to PL Interrupt signals.  */
	for (i = 0; i < 28; i++) {
		rp_irq_out.wires_out[i](ps2pl_irq[i]);
	}

	/* PS to PL resets.  */
	for (i = 0; i < 17; i++) {
		rp_wires_out.wires_out[i](ps2pl_rst[i]);
	}

	register_dev(0, &rp_s_axi_gp0);
	register_dev(1, &rp_s_axi_gp1);

	register_dev(2, &rp_s_axi_hp0);
	register_dev(3, &rp_s_axi_hp1);
	register_dev(4, &rp_s_axi_hp2);
	register_dev(5, &rp_s_axi_hp3);

	register_dev(6, &rp_s_axi_acp);

	register_dev(7, &rp_m_axi_gp0);
	register_dev(8, &rp_m_axi_gp1);
	register_dev(9, &rp_wires_in);
	register_dev(10, &rp_wires_out);
	register_dev(11, &rp_irq_out);
}
