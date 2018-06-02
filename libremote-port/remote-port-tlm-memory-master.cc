/*
 * System-C TLM-2.0 remoteport memory mapped master port.
 *
 * Copyright (c) 2016 Xilinx Inc
 * Written by Edgar E. Iglesias
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
#include <sys/utsname.h>
#include <assert.h>

#include "systemc.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm_utils/tlm_quantumkeeper.h"
#include <iostream>

extern "C" {
#include "safeio.h"
#include "remote-port-proto.h"
#include "remote-port-sk.h"
};
#include "remote-port-tlm.h"
#include "remote-port-tlm-memory-master.h"
#include "tlm-extensions/genattr.h"

using namespace sc_core;
using namespace std;

sc_time remoteport_tlm_memory_master::rp_bus_access(struct rp_pkt &pkt,
				   bool can_sync,
				   tlm::tlm_command cmd,
				   unsigned char *data, size_t len)
{
	tlm::tlm_generic_payload tr;
	sc_time delay;
	genattr_extension *genattr;

	adaptor->account_time(pkt.sync.timestamp);
	if (can_sync && adaptor->m_qk.need_sync()) {
		adaptor->m_qk.sync();
	}

	delay = adaptor->m_qk.get_local_time();
	assert(pkt.busaccess.width == 0);

	tr.set_command(cmd);
	tr.set_address(pkt.busaccess.addr);
	tr.set_data_ptr(data);
	tr.set_data_length(len);
	tr.set_streaming_width(pkt.busaccess.stream_width);
	tr.set_dmi_allowed(false);
	tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

	// Extensions
	genattr = new(genattr_extension);
	genattr->set_eop(pkt.busaccess.attributes & RP_BUS_ATTR_EOP);
	genattr->set_secure(pkt.busaccess.attributes & RP_BUS_ATTR_SECURE);
	genattr->set_master_id(pkt.busaccess.master_id);
	tr.set_extension(genattr);

	sk->b_transport(tr, delay);
	if (tr.get_response_status() != tlm::TLM_OK_RESPONSE) {
		/* Handle errors.  */
		printf("bus error\n");
	}
	adaptor->m_qk.set(delay);

	tr.release_extension(genattr);
	return delay;
}

void remoteport_tlm_memory_master::cmd_read(struct rp_pkt &pkt, bool can_sync)
{
	size_t plen;
	sc_time delay;
	struct rp_pkt lpkt = pkt;
	unsigned char *data;
	remoteport_packet pkt_tx;
	struct rp_encode_busaccess_in in;

	rp_encode_busaccess_in_rsp_init(&in, &lpkt);

	/* FIXME: We the callee is allowed to yield, and may call
		us back out again (loop). So we should be reentrant
		in respect to pkt_tx.  */
	pkt_tx.alloc(sizeof lpkt.busaccess_ext_base + lpkt.busaccess.len);
	data = rp_busaccess_tx_dataptr(&adaptor->peer,
				       &pkt_tx.pkt->busaccess_ext_base);
	delay = rp_bus_access(lpkt, can_sync, tlm::TLM_READ_COMMAND,
			      data, lpkt.busaccess.len);

	in.clk = adaptor->rp_map_time(delay);
	in.clk += lpkt.busaccess.timestamp;
	plen = rp_encode_busaccess(&adaptor->peer,
				   &pkt_tx.pkt->busaccess_ext_base,
				   &in);
	adaptor->rp_write(pkt_tx.pkt, plen);
}

void remoteport_tlm_memory_master::cmd_write(struct rp_pkt &pkt, bool can_sync,
				  unsigned char *data, size_t len)
{
	size_t plen;
	sc_time delay;
	struct rp_pkt lpkt = pkt;
	remoteport_packet pkt_tx;
	struct rp_encode_busaccess_in in;

	rp_encode_busaccess_in_rsp_init(&in, &lpkt);
	delay = rp_bus_access(lpkt, can_sync,
				tlm::TLM_WRITE_COMMAND, data, len);

	in.clk = adaptor->rp_map_time(delay);
	in.clk += lpkt.busaccess.timestamp;

	plen = rp_encode_busaccess(&adaptor->peer,
				   &pkt_tx.pkt->busaccess_ext_base,
				   &in);
	adaptor->rp_write(pkt_tx.pkt, plen);
	assert(plen <= sizeof pkt_tx.pkt->busaccess_ext_base);
}

void remoteport_tlm_memory_master::tie_off(void)
{
	if (!sk.size()) {
		tieoff_sk = new tlm_utils::simple_target_socket<remoteport_tlm_memory_master>();
		sk.bind(*tieoff_sk);
	}
}
