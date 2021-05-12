/*
 * System-C TLM-2.0 remoteport wires.
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
#include "remote-port-tlm-wires.h"

using namespace sc_core;
using namespace std;

remoteport_tlm_wires::remoteport_tlm_wires(sc_module_name name,
					   unsigned int nr_wires_in,
					   unsigned int nr_wires_out,
					   bool posted_updates)
        : sc_module(name),
	  wires_in("wires_in", nr_wires_in),
	  wires_out("wires_out", nr_wires_out)
{
	unsigned int i;

	cfg.nr_wires_in = nr_wires_in;
	cfg.nr_wires_out = nr_wires_out;
	cfg.posted_updates = posted_updates;

	wire_name = name;

	if (nr_wires_in) {
		SC_THREAD(wire_update);

		for (i = 0; i < nr_wires_in; i++) {
			sensitive << wires_in[i];
		}
	}
}

void remoteport_tlm_wires::cmd_interrupt_null(remoteport_tlm *adaptor,
						struct rp_pkt &pkt,
						bool can_sync,
						remoteport_tlm_wires *dev)
{
	struct rp_pkt lpkt = pkt;

	adaptor->sync->pre_wire_cmd(pkt.sync.timestamp, can_sync);

	if (dev) {
		dev->interrupt_action(pkt);
	}

	if (adaptor->peer.caps.wire_posted_updates
	    && !(lpkt.hdr.flags & RP_PKT_FLAGS_posted)) {
		int64_t clk;
		size_t plen;

	        clk = adaptor->rp_map_time(adaptor->sync->get_current_time());
		plen = rp_encode_interrupt_f(lpkt.hdr.id,
					     lpkt.hdr.dev,
					     &lpkt.interrupt,
					     clk, lpkt.interrupt.line,
					     0, lpkt.interrupt.val,
					     lpkt.hdr.flags | RP_PKT_FLAGS_response);
		adaptor->rp_write(&lpkt, plen);
	}

	adaptor->sync->post_wire_cmd(pkt.sync.timestamp, can_sync);
}

void remoteport_tlm_wires::interrupt_action(struct rp_pkt &pkt)
{
	assert(pkt.hdr.dev == dev_id);
	assert(pkt.interrupt.line < cfg.nr_wires_out);

	wires_out[pkt.interrupt.line].write(pkt.interrupt.val);
}

void remoteport_tlm_wires::cmd_interrupt(struct rp_pkt &pkt, bool can_sync)
{
	cmd_interrupt_null(adaptor, pkt, can_sync, this);
}

void remoteport_tlm_wires::wire_update(void)
{
	remoteport_packet pkt_tx;
	bool events[cfg.nr_wires_in];
	unsigned int ri;
	size_t plen;
	int64_t clk;
	unsigned int i;

	pkt_tx.alloc(sizeof pkt_tx.pkt->interrupt);

	while (true) {
		int nr_events = 0;
		uint32_t flags = RP_PKT_FLAGS_posted;
		uint32_t id = 0;

		wait();
	        for (i = 0; i < cfg.nr_wires_in; i++) {
			events[i] = 0;
			if (wires_in[i].event()) {
				events[i] = true;
				nr_events++;
			}
		}

	        clk = adaptor->rp_map_time(adaptor->sync->get_current_time());
	        for (i = 0; i < cfg.nr_wires_in; i++) {
			if (events[i]) {
				bool val = wires_in[i].read();

				nr_events--;
				if (nr_events == 0 && !cfg.posted_updates) {
					flags = 0;
				}
				id = adaptor->rp_pkt_id++;
				plen = rp_encode_interrupt_f(id,
						dev_id,
						&pkt_tx.pkt->interrupt,
						clk, i, 0, val, flags);
				adaptor->rp_write(pkt_tx.pkt, plen);
			}
		}

		// Wait for an ACK on the last one.
		if (adaptor->peer.caps.wire_posted_updates
                    && !(flags & RP_PKT_FLAGS_posted) ) {
			ri = response_wait(id);
			assert(resp[ri].pkt.pkt->hdr.id == id);
			response_done(ri);
		}
	}
}


void remoteport_tlm_wires::tie_off(void)
{
	char n_str[64];
	sc_signal<bool> *sig;
	unsigned int i;

	for (i = 0; i < cfg.nr_wires_in; i++) {
		if (wires_in[i].size())
			continue;

		sprintf(n_str, "tie_off_%s_wires_in_%d", wire_name, i);
		sig = new sc_signal<bool>(n_str);
		wires_in[i](*sig);
	}

	for (i = 0; i < cfg.nr_wires_out; i++) {
		if (wires_out[i].size())
			continue;

		sprintf(n_str, "tie_off_%s_wires_out_%d", wire_name, i);
		sig = new sc_signal<bool>(n_str);
		wires_out[i](*sig);
	}
}
