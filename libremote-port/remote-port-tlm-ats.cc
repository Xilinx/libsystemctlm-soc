/*
 * System-C TLM-2.0 remoteport ATS device.
 *
 * Copyright (c) 2021 Xilinx Inc
 * Written by Francisco Iglesias
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

#include "systemc.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "remote-port-tlm-ats.h"
#include "tlm-extensions/atsattr.h"

remoteport_tlm_ats::remoteport_tlm_ats(sc_module_name name) :
	sc_module(name),
	req("ats_req"),
	inv("ats_inv")
{
	req.register_b_transport(this, &remoteport_tlm_ats::b_transport);
}

void remoteport_tlm_ats::ats_invalidate(struct rp_pkt &pkt)
{
	sc_time delay(SC_ZERO_TIME);
	tlm::tlm_generic_payload gp;
	atsattr_extension *atsattr = new atsattr_extension();

	gp.set_extension(atsattr);
	gp.set_command(tlm::TLM_IGNORE_COMMAND);

	gp.set_address(pkt.ats.addr);
	atsattr->set_length(pkt.ats.len);
	atsattr->set_attributes(pkt.ats.attributes);

	inv->b_transport(gp, delay);

	assert(gp.get_response_status() == tlm::TLM_OK_RESPONSE);

	wait(delay);
}

void remoteport_tlm_ats::cmd_ats_inv_null(remoteport_tlm *adaptor,
						struct rp_pkt &pkt,
						bool can_sync,
						remoteport_tlm_ats *dev)
{
	struct rp_pkt lpkt = pkt;
	int64_t clk;
	size_t plen;

	adaptor->sync->pre_ats_inv_cmd(pkt.sync.timestamp, can_sync);

	if (dev) {
		dev->ats_invalidate(pkt);
	}

	clk = adaptor->rp_map_time(adaptor->sync->get_current_time());
	plen = rp_encode_ats_inv(lpkt.hdr.id, lpkt.hdr.dev,
				&lpkt.ats,
				clk,
				lpkt.ats.attributes,
				lpkt.ats.addr,
				lpkt.ats.len,
				lpkt.ats.result,
				lpkt.hdr.flags | RP_PKT_FLAGS_response);

	adaptor->rp_write(&lpkt, plen);

	adaptor->sync->post_ats_inv_cmd(pkt.sync.timestamp, can_sync);
}

void remoteport_tlm_ats::tie_off(void)
{
	if (!req.size()) {
		tieoff_req = new tlm_utils::simple_initiator_socket<remoteport_tlm_ats>();
		tieoff_req->bind(req);
	}
	if (!inv.size()) {
		tieoff_inv = new tlm_utils::simple_target_socket<remoteport_tlm_ats>();
		inv.bind(*tieoff_inv);
	}
}

void remoteport_tlm_ats::b_transport(tlm::tlm_generic_payload& trans,
				       sc_time& delay)
{
	int64_t clk = adaptor->rp_map_time(adaptor->sync->get_current_time());
	uint32_t id = adaptor->rp_pkt_id++;
	atsattr_extension *ats_attr;
	remoteport_packet pkt_tx;
	unsigned int ri;
	size_t plen;

	trans.get_extension(ats_attr);

	if (!adaptor->peer.caps.ats || !ats_attr) {
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		return;
	}

	pkt_tx.alloc(sizeof pkt_tx.pkt->ats);

	plen = rp_encode_ats_req(id, dev_id,
				&pkt_tx.pkt->ats,
				clk,
				ats_attr->get_attributes(),
				trans.get_address(),
				ats_attr->get_length(),
				0, 0);

	adaptor->rp_write(pkt_tx.pkt, plen);

	ri = response_wait(id);
	assert(resp[ri].pkt.pkt->hdr.id == id);

	trans.set_address(resp[ri].pkt.pkt->ats.addr);
	ats_attr->set_attributes(resp[ri].pkt.pkt->ats.attributes);
	ats_attr->set_length(resp[ri].pkt.pkt->ats.len);
	ats_attr->set_result(resp[ri].pkt.pkt->ats.result);

	// Give back the RP response slot.
	response_done(ri);

	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}

void remoteport_tlm_ats::cmd_ats_inv(struct rp_pkt &pkt, bool can_sync)
{
	cmd_ats_inv_null(adaptor, pkt, can_sync, this);
}
