/*
 * Xilinx SystemC/TLM-2.0 ZynqMP Wrapper.
 *
 * Copyright (C) 2016, Xilinx, Inc.
 * Copyright (C) 2023, Advanced Micro Devices, Inc.
 * All rights reserved.
 *
 * Written by Edgar E. Iglesias <edgar.iglesias@xilinx.com>
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
#include "tlm-modules/wire-splitter.h"

class xilinx_zynqmp
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

	remoteport_tlm_memory_master rp_axi_hpm0_fpd;
	remoteport_tlm_memory_master rp_axi_hpm1_fpd;
	remoteport_tlm_memory_master rp_axi_hpm_lpd;
	remoteport_tlm_memory_master rp_lpd_reserved;

	remoteport_tlm_memory_slave rp_axi_hpc0_fpd;
	remoteport_tlm_memory_slave rp_axi_hpc1_fpd;
	remoteport_tlm_memory_slave rp_axi_hp0_fpd;
	remoteport_tlm_memory_slave rp_axi_hp1_fpd;
	remoteport_tlm_memory_slave rp_axi_hp2_fpd;
	remoteport_tlm_memory_slave rp_axi_hp3_fpd;
	remoteport_tlm_memory_slave rp_axi_lpd;
	remoteport_tlm_memory_slave rp_axi_acp_fpd;
	remoteport_tlm_memory_slave rp_axi_ace_fpd;

	remoteport_tlm_wires rp_wires_in;
	remoteport_tlm_wires rp_wires_out;
	remoteport_tlm_wires rp_irq_out;
	remoteport_tlm_wires rp_emio0;
	remoteport_tlm_wires rp_emio1;
	remoteport_tlm_wires rp_emio2;
	remoteport_tlm_wires rp_mio_in;
	remoteport_tlm_wires rp_mio_out;

	sc_vector<remoteport_tlm_memory_master > rp_user_master;
	sc_vector<remoteport_tlm_memory_slave > rp_user_slave;

	/*
	 * In order to get Master-IDs right, we need to proxy all
	 * transactions and inject generic attributes with Master IDs.
	 */
	sc_vector<tlm_utils::simple_target_socket_tagged<xilinx_zynqmp> > proxy_in;
	sc_vector<tlm_utils::simple_initiator_socket_tagged<xilinx_zynqmp> > proxy_out;

	/*
	 * Proxies for friendly named pl_resets.
	 */
	wire_splitter *pl_resetn_splitter[4];

	virtual void b_transport(int id,
				 tlm::tlm_generic_payload& trans,
				 sc_time& delay);
	virtual unsigned int transport_dbg(int id,
					   tlm::tlm_generic_payload& trans);
public:
	/*
	 * HPM0 - 1 _FPD.
	 * These sockets represent the High speed PS to PL interfaces.
	 * These are AXI Slave ports on the PS side and AXI Master ports
	 * on the PL side.
	 *
	 * HPM_LPD
	 * Used to transfer data quickly from the LPD to the PL.
	 *
	 * Used to transfer data from the PS to the PL.
	 */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *s_axi_hpm_fpd[2];
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *s_axi_hpm_lpd;
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *s_lpd_reserved;

	/*
	 * HPC0 - 1.
	 * These sockets represent the High speed IO Coherent PL to PS
	 * interfaces.
	 *
	 * HP0 - 3.
	 * These sockets represent the High speed PL to PS interfaces.
	 *
	 * PL_LPD
	 * Low-Power interface used to transfer data to the Low Power Domain.
	 *
	 * ACP
	 * Accelerator Coherency Port, used to transfered coherent data to
	 * the PS via the Cortex-A53 subsystem.
	 *
	 * These are AXI Master ports on the PS side and AXI Slave ports
	 * on the PL side.
	 *
	 * Used to transfer data from the PL to the PS.
	 */
	tlm_utils::simple_target_socket_tagged<xilinx_zynqmp> *s_axi_hpc_fpd[2];
	tlm_utils::simple_target_socket_tagged<xilinx_zynqmp> *s_axi_hp_fpd[4];
	tlm_utils::simple_target_socket_tagged<xilinx_zynqmp> *s_axi_lpd;
	tlm_utils::simple_target_socket_tagged<xilinx_zynqmp> *s_axi_acp_fpd;
	tlm_utils::simple_target_socket_tagged<xilinx_zynqmp> *s_axi_ace_fpd;

	sc_vector<sc_signal<bool> > pl2ps_irq;
	sc_vector<sc_signal<bool> > ps2pl_irq;

	xilinx_emio_bank *emio[3];
	xilinx_mio_bank mio;

	/*
	 * 4 PL resets, same as EMIO[2][31:28] but with friendly names.
	 * See the TRM, Chapter 27 GPIO, page 761.
	 */
	sc_vector<sc_signal<bool> > pl_resetn;

	/*
	 * User-defined ports.
	 */
	tlm_utils::simple_initiator_socket<remoteport_tlm_memory_master> *user_master[10];
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> *user_slave[10];

	xilinx_zynqmp(sc_core::sc_module_name name, const char *sk_descr,
			Iremoteport_tlm_sync *sync = NULL,
			bool blocking_socket = true);
	~xilinx_zynqmp(void);
	void tie_off(void);
};
