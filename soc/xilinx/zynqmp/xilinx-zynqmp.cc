/*
 * Xilinx SystemC/TLM-2.0 ZynqMP Wrapper.
 *
 * Written by Edgar E. Iglesias <edgar.iglesias@xilinx.com>
 *
 * Copyright (c) 2016, Xilinx Inc.
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
#include "tlm_utils/tlm_quantumkeeper.h"

using namespace sc_core;
using namespace std;

extern "C" {
#include "safeio.h"
#include "remote-port-proto.h"
#include "remote-port-sk.h"
};
#include "xilinx-zynqmp.h"
#include "tlm-extensions/genattr.h"
#include <sys/types.h>

#define NUM_MIO_WIRES 78

xilinx_emio_bank::xilinx_emio_bank(const char *name_in, const char *name_out,
				   const char *name_out_en, int num)
	:in(name_in, num),
	 out(name_out, num),
	 out_enable(name_out_en, num)
{ }

xilinx_mio_bank::xilinx_mio_bank(const char *name_in, const char *name_out,
				   int num)
	:in(name_in, num),
	 out(name_out, num)
{ }

xilinx_zynqmp::xilinx_zynqmp(sc_module_name name, const char *sk_descr,
				Iremoteport_tlm_sync *sync,
				bool blocking_socket)
	: remoteport_tlm(name, -1, sk_descr, sync, blocking_socket),
	  rp_axi_hpm0_fpd("rp_axi_hpm0_fpd"),
	  rp_axi_hpm1_fpd("rp_axi_hpm1_fpd"),
	  rp_axi_hpm_lpd("rp_axi_hpm_lpd"),
	  rp_lpd_reserved("rp_lpd_reserved"),
	  rp_axi_hpc0_fpd("rp_axi_hpc0_fpd"),
	  rp_axi_hpc1_fpd("rp_axi_hpc1_fpd"),
	  rp_axi_hp0_fpd("rp_axi_hp0_fpd"),
	  rp_axi_hp1_fpd("rp_axi_hp1_fpd"),
	  rp_axi_hp2_fpd("rp_axi_hp2_fpd"),
	  rp_axi_hp3_fpd("rp_axi_hp3_fpd"),
	  rp_axi_lpd("rp_axi_lpd"),
	  rp_axi_acp_fpd("rp_axi_acp_fpd"),
	  rp_axi_ace_fpd("rp_axi_ace_fpd"),
	  rp_wires_in("wires_in", 16, 0),
	  rp_wires_out("wires_out", 0, 4),
	  rp_irq_out("irq_out", 0, 164),
	  rp_emio0("emio0", 32, 64),
	  rp_emio1("emio1", 32, 64),
	  rp_emio2("emio2", 32, 64),
	  rp_mio_in("rp_mio_in", NUM_MIO_WIRES, 0),
	  rp_mio_out("rp_mio_out", 0, NUM_MIO_WIRES),
	  rp_user_master("rp_net_master", 10),
	  rp_user_slave("rp_net_slave", 10),
	  proxy_in("proxy_in", 9),
	  proxy_out("proxy_out", proxy_in.size()),
	  pl2ps_irq("pl2ps_irq", rp_wires_in.wires_in.size()),
	  ps2pl_irq("ps2pl_irq", rp_irq_out.wires_out.size()),
	  mio("mio_in", "mio_out", NUM_MIO_WIRES),
	  pl_resetn("pl_resetn", 4)
{
	tlm_utils::simple_target_socket<remoteport_tlm_memory_slave> * const out[] = {
		&rp_axi_hpc0_fpd.sk,
		&rp_axi_hpc1_fpd.sk,
		&rp_axi_hp0_fpd.sk,
		&rp_axi_hp1_fpd.sk,
		&rp_axi_hp2_fpd.sk,
		&rp_axi_hp3_fpd.sk,
		&rp_axi_lpd.sk,
		&rp_axi_acp_fpd.sk,
		&rp_axi_ace_fpd.sk,
	};
	tlm_utils::simple_target_socket_tagged<xilinx_zynqmp> ** const named[] = {
		&s_axi_hpc_fpd[0],
		&s_axi_hpc_fpd[1],
		&s_axi_hp_fpd[0],
		&s_axi_hp_fpd[1],
		&s_axi_hp_fpd[2],
		&s_axi_hp_fpd[3],
		&s_axi_lpd,
		&s_axi_acp_fpd,
		&s_axi_ace_fpd,
	};
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

	/* Expose friendly named PS Master ports.  */
	s_axi_hpm_fpd[0] = &rp_axi_hpm0_fpd.sk;
	s_axi_hpm_fpd[1] = &rp_axi_hpm1_fpd.sk;
	s_axi_hpm_lpd = &rp_axi_hpm_lpd.sk;
	s_lpd_reserved = &rp_lpd_reserved.sk;

	for (i = 0; i < rp_user_master.size(); i++) {
		user_master[i] = &rp_user_master[i].sk;
		user_slave[i] = &rp_user_slave[i].sk;
	}

	// Connect our Master ID injecting proxies.
	for (i = 0; i < proxy_in.size(); i++) {
		char name[32];

		sprintf(name, "proxy_in-%d", i);
		proxy_in[i].register_b_transport(this,
						  &xilinx_zynqmp::b_transport,
						  i);
		proxy_in[i].register_transport_dbg(this,
						  &xilinx_zynqmp::transport_dbg,
						  i);
		named[i][0] = &proxy_in[i];
		proxy_out[i].bind(*out[i]);
	}

	for (i = 0; i < pl2ps_irq.size(); i++) {
		rp_wires_in.wires_in[i](pl2ps_irq[i]);
	}

	for (i = 0; i < ps2pl_irq.size(); i++) {
		rp_irq_out.wires_out[i](ps2pl_irq[i]);
	}

	for (i = 0; i < emio[0]->out.size(); i++) {
		rp_emio0.wires_out[i](emio[0]->out[i]);
		rp_emio1.wires_out[i](emio[1]->out[i]);
		if (i < 28) {
			/* Top 4 PL reset signals go via a proxy.  */
			rp_emio2.wires_out[i](emio[2]->out[i]);
		}
		rp_emio0.wires_in[i](emio[0]->in[i]);
		rp_emio1.wires_in[i](emio[1]->in[i]);
		rp_emio2.wires_in[i](emio[2]->in[i]);
		rp_emio0.wires_out[i + 32](emio[0]->out_enable[i]);
		rp_emio1.wires_out[i + 32](emio[1]->out_enable[i]);
		rp_emio2.wires_out[i + 32](emio[2]->out_enable[i]);
	}

	for (i = 0; i < mio.in.size(); i++) {
		rp_mio_in.wires_in[i](mio.in[i]);
		rp_mio_out.wires_out[i](mio.out[i]);
	}

	for (i = 0; i < pl_resetn.size(); i++) {
		char name[32];

		sprintf(name, "pl_resetn_splitter_%d", i);
		pl_resetn_splitter[i] = new wire_splitter(name, 2);

		pl_resetn_splitter[i]->in(rp_emio2.wires_out[28 + i]);
		pl_resetn_splitter[i]->out[0](pl_resetn[i]);
		pl_resetn_splitter[i]->out[1](emio[2]->out[28 + i]);
	}

	// Register with Remote-Port.
	register_dev(0, &rp_axi_hpc0_fpd);
	register_dev(1, &rp_axi_hpc1_fpd);
	register_dev(2, &rp_axi_hp0_fpd);
	register_dev(3, &rp_axi_hp1_fpd);
	register_dev(4, &rp_axi_hp2_fpd);
	register_dev(5, &rp_axi_hp3_fpd);
	register_dev(6, &rp_axi_lpd);
	register_dev(7, &rp_axi_acp_fpd);
	register_dev(8, &rp_axi_ace_fpd);

	register_dev(9, &rp_axi_hpm0_fpd);
	register_dev(10, &rp_axi_hpm1_fpd);
	register_dev(11, &rp_axi_hpm_lpd);

	register_dev(12, &rp_wires_in);
	register_dev(13, &rp_wires_out);
	register_dev(14, &rp_irq_out);
	register_dev(15, &rp_lpd_reserved);
	register_dev(16, &rp_emio0);
	register_dev(17, &rp_emio1);
	register_dev(18, &rp_emio2);
	register_dev(19, &rp_mio_in);
	register_dev(20, &rp_mio_out);

	for (i = 0; i < rp_user_master.size(); i++) {
		register_dev(256 + i, &rp_user_master[i]);
		register_dev(256 + 10 + i, &rp_user_slave[i]);
	}
}

void xilinx_zynqmp::tie_off(void)
{
	tlm_utils::simple_initiator_socket<xilinx_zynqmp> *tieoff_sk;
	unsigned int i;

	remoteport_tlm::tie_off();

	for (i = 0; i < proxy_in.size(); i++) {
		if (proxy_in[i].size())
			continue;
		tieoff_sk = new tlm_utils::simple_initiator_socket<xilinx_zynqmp>();
		tieoff_sk->bind(proxy_in[i]);
	}
}

xilinx_zynqmp::~xilinx_zynqmp(void)
{
	for(int i = 0; i < 3; i++) {
		delete(emio[i]);
	}
}

// Modify the Master ID and pass through transactions.
void xilinx_zynqmp::b_transport(int id,
				tlm::tlm_generic_payload& trans,
				sc_time &delay)
{
	// The lower 6 bits of the Master ID are controlled by PL logic.
	// Upper 7 bits are dictated by the PS.
	//
	// Bits [9:6] are the port index + 8.
	// Bits [12:10] are the TBU index.
#define MASTER_ID(tbu, id_9_6) ((tbu) << 10 | (id_9_6) << 6)
	static const uint32_t master_id[9] = {
		MASTER_ID(0, 8),
		MASTER_ID(0, 9),
		MASTER_ID(3, 10),
		MASTER_ID(4, 11),
		MASTER_ID(4, 12),
		MASTER_ID(5, 13),
		MASTER_ID(2, 14),
		MASTER_ID(0, 2), /* ACP. No TBU. AXI IDs? */
		MASTER_ID(0, 15), /* ACE. No TBU.  */
	};
	uint64_t mid;
	genattr_extension *genattr;

	trans.get_extension(genattr);
	if (!genattr) {
		genattr = new genattr_extension();
		trans.set_extension(genattr);
	}

	mid = genattr->get_master_id();
	/* PL Logic cannot control upper bits.  */
	mid &= (1ULL << 6) - 1;
	mid |= master_id[id];
	genattr->set_master_id(mid);

	proxy_out[id]->b_transport(trans, delay);
}

// Passthrough.
unsigned int xilinx_zynqmp::transport_dbg(int id, tlm::tlm_generic_payload& trans) {
	return proxy_out[id]->transport_dbg(trans);
}
