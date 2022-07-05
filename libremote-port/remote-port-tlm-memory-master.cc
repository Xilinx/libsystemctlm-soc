/*
 * System-C TLM-2.0 remoteport memory mapped master port.
 *
 * Copyright (c) 2016-2018 Xilinx Inc
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
#include <sstream>

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

int remoteport_tlm_memory_master::rp_bus_access(struct rp_pkt &pkt,
				   tlm::tlm_command cmd,
				   unsigned char *data, size_t len)
{
	tlm::tlm_generic_payload tr;
	sc_time delay;
	genattr_extension *genattr;
	int resp;

	delay = adaptor->sync->get_local_time();
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
	genattr->set_posted(pkt.hdr.flags & RP_PKT_FLAGS_posted);
	genattr->set_eop(pkt.busaccess.attributes & RP_BUS_ATTR_EOP);
	genattr->set_secure(pkt.busaccess.attributes & RP_BUS_ATTR_SECURE);
	genattr->set_IO_access(pkt.busaccess.attributes & RP_BUS_ATTR_IO_ACCESS);
	genattr->set_master_id(pkt.busaccess.master_id);
	tr.set_extension(genattr);

	sk->b_transport(tr, delay);

	switch (tr.get_response_status()) {
	case tlm::TLM_OK_RESPONSE:
		resp = RP_RESP_OK;
		break;
	case tlm::TLM_ADDRESS_ERROR_RESPONSE:
		resp = RP_RESP_ADDR_ERROR;
		break;
	default:
		resp = RP_RESP_BUS_GENERIC_ERROR;
		break;
	}

	adaptor->sync->set_local_time(delay);

	tr.release_extension(genattr);

	wait(SC_ZERO_TIME);
	return resp;
}

void remoteport_tlm_memory_master::cmd_read_null(
					remoteport_tlm *adaptor,
					struct rp_pkt &pkt,
					bool can_sync,
					remoteport_tlm_memory_master *dev)
{
	size_t plen;
	unsigned char *data;
	remoteport_packet pkt_tx;
	struct rp_encode_busaccess_in in;
	int resp = RP_RESP_OK;

	adaptor->sync->pre_memory_master_cmd(pkt.sync.timestamp, can_sync);

	rp_encode_busaccess_in_rsp_init(&in, &pkt);

	pkt_tx.alloc(sizeof pkt.busaccess_ext_base + pkt.busaccess.len);
	data = rp_busaccess_tx_dataptr(&adaptor->peer,
				       &pkt_tx.pkt->busaccess_ext_base);

	if (dev) {
		resp = dev->rp_bus_access(pkt, tlm::TLM_READ_COMMAND,
					data, pkt.busaccess.len);
	} else {
		memset(data, 0x0, pkt.busaccess.len);
	}

	in.clk = adaptor->rp_map_time(adaptor->sync->get_local_time());
	in.clk += pkt.busaccess.timestamp;
	in.attr |= resp << RP_BUS_RESP_SHIFT;
	plen = rp_encode_busaccess(&adaptor->peer,
				   &pkt_tx.pkt->busaccess_ext_base,
				   &in);
	adaptor->rp_write(pkt_tx.pkt, plen);
	adaptor->sync->post_memory_master_cmd(pkt.sync.timestamp, can_sync);
}

void remoteport_tlm_memory_master::cmd_write_null(
					remoteport_tlm *adaptor,
					struct rp_pkt &pkt,
					bool can_sync,
					unsigned char *data,
					size_t len,
					remoteport_tlm_memory_master *dev)
{
	size_t plen;
	sc_time delay;
	remoteport_packet pkt_tx;
	struct rp_encode_busaccess_in in;
	int resp = RP_RESP_OK;

	adaptor->sync->pre_memory_master_cmd(pkt.sync.timestamp, can_sync);

	if (dev) {
		resp = dev->rp_bus_access(pkt, tlm::TLM_WRITE_COMMAND, data, len);
	}

	if (!(pkt.hdr.flags & RP_PKT_FLAGS_posted)) {
		rp_encode_busaccess_in_rsp_init(&in, &pkt);

		in.clk = adaptor->rp_map_time(adaptor->sync->get_local_time());
		in.clk += pkt.busaccess.timestamp;
		in.attr |= resp << RP_BUS_RESP_SHIFT;

		plen = rp_encode_busaccess(&adaptor->peer,
					   &pkt_tx.pkt->busaccess_ext_base,
					   &in);
		adaptor->rp_write(pkt_tx.pkt, plen);
		assert(plen <= sizeof pkt_tx.pkt->busaccess_ext_base);
	}
	adaptor->sync->post_memory_master_cmd(pkt.sync.timestamp, can_sync);
}

void remoteport_tlm_memory_master::cmd_read(struct rp_pkt &pkt, bool can_sync)
{
	cmd_read_null(adaptor, pkt, can_sync, this);
}

void remoteport_tlm_memory_master::cmd_write(struct rp_pkt &pkt, bool can_sync,
				  unsigned char *data, size_t len)
{
	cmd_write_null(adaptor, pkt, can_sync, data, len, this);
}

void remoteport_tlm_memory_master::b_transport(tlm::tlm_generic_payload& trans,
				       sc_time& delay)
{
	tlm::tlm_command cmd = trans.get_command();
	uint64_t addr = trans.get_address();
	const char *cmd_str = cmd == tlm::TLM_WRITE_COMMAND ? "write" : "read";
	std::ostringstream msg;

	msg << name() << ": Tied-off " << cmd_str << " to 0x" << std::hex << addr << endl;
	SC_REPORT_WARNING("remote-port-tlm-memory-master", msg.str().c_str());
	trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
}

void remoteport_tlm_memory_master::tie_off(void)
{
	if (!sk.size()) {
		tieoff_sk = new tlm_utils::simple_target_socket<remoteport_tlm_memory_master>();
		tieoff_sk->register_b_transport(this, &remoteport_tlm_memory_master::b_transport);

		sk.bind(*tieoff_sk);
	}
}
