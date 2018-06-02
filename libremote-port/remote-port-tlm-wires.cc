/*
 * System-C TLM-2.0 remoteport wires.
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
                                           unsigned int nr_wires_out)
        : sc_module(name)
{
	unsigned int i;

	cfg.nr_wires_in = nr_wires_in;
	cfg.nr_wires_out = nr_wires_out;

	wire_name = name;

	if (nr_wires_in) {
		wires_in = new sc_in<bool>[nr_wires_in];
		SC_METHOD(wire_update);
		dont_initialize();

		for (i = 0; i < nr_wires_in; i++) {
			sensitive << wires_in[i];
		}
	}

	if (nr_wires_out) {
		wires_out = new sc_out<bool>[nr_wires_out];
	}
}


void remoteport_tlm_wires::cmd_interrupt(struct rp_pkt &pkt, bool can_sync)
{
	struct rp_pkt lpkt = pkt;

	adaptor->account_time(pkt.sync.timestamp);
	/* Always sync here. Peer is not waiting for a response so
	 * it's a good time to achieve parallelism. We also don't
	 * want to miss pin wiggeling events (by having multiple
	 * changes merged into the same time slot when using
	 * large quantums).
	 */
	if (can_sync) {
		adaptor->m_qk.sync();
	}

	assert(lpkt.hdr.dev == dev_id);
//	printf("wires_out[%d]=%d\n", lpkt.interrupt.line,lpkt.interrupt.val);
	assert(lpkt.interrupt.line < cfg.nr_wires_out);
	wires_out[lpkt.interrupt.line].write(lpkt.interrupt.val);

	/*
	 * Yield to make line-updates visible immediately.
	 * Otherwise a line-update followed by a back-to-back
	 * transaction that inspects the state of the line
	 * may not reflect the update.
	 */
	if (can_sync) {
		wait(SC_ZERO_TIME);
	}
}

void remoteport_tlm_wires::wire_update(void)
{
	remoteport_packet pkt_tx;
        size_t plen;
        int64_t clk;
        unsigned int i;

	pkt_tx.alloc(sizeof pkt_tx.pkt->interrupt);

        clk = adaptor->rp_map_time(adaptor->m_qk.get_current_time());
        for (i = 0; i < cfg.nr_wires_in; i++) {
                if (wires_in[i].event()) {
                        bool val = wires_in[i].read();
                        plen = rp_encode_interrupt(adaptor->rp_pkt_id++,
                                                   dev_id,
                                                   &pkt_tx.pkt->interrupt,
                                                   clk, i, 0, val);
                        adaptor->rp_write(pkt_tx.pkt, plen);
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
