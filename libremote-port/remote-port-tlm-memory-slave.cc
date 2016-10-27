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
#include "remote-port-tlm-memory-slave.h"

using namespace sc_core;
using namespace std;

remoteport_tlm_memory_slave::remoteport_tlm_memory_slave(sc_module_name name)
	: sc_module(name)
{
	sk.register_b_transport(this, &remoteport_tlm_memory_slave::b_transport);
}

void remoteport_tlm_memory_slave::tie_off(void)
{
	if (!sk.size()) {
		tieoff_sk = new tlm_utils::simple_initiator_socket<remoteport_tlm_memory_slave>();
		tieoff_sk->bind(sk);
	}
}

void remoteport_tlm_memory_slave::b_transport(tlm::tlm_generic_payload& trans,
				       sc_time& delay)
{
	size_t plen;
	int64_t clk;
	bool resp_ready;

	tlm::tlm_command cmd = trans.get_command();
	sc_dt::uint64 addr = trans.get_address();
	unsigned char *data = trans.get_data_ptr();
	unsigned int len = trans.get_data_length();
	unsigned int wid = trans.get_streaming_width();

	adaptor->pkt_tx.alloc(sizeof adaptor->pkt_tx.pkt->busaccess + len);
	clk = adaptor->rp_map_time(adaptor->m_qk.get_current_time());

	if (cmd == tlm::TLM_READ_COMMAND) {
		plen = rp_encode_read(adaptor->rp_pkt_id++, dev_id,
					&adaptor->pkt_tx.pkt->busaccess,
					clk, 0,
					addr, 0,
					len,
					0,
					wid);
		adaptor->rp_write(adaptor->pkt_tx.pkt, plen);
	} else {
		plen = rp_encode_write(adaptor->rp_pkt_id++, dev_id,
					&adaptor->pkt_tx.pkt->busaccess,
					clk, 0,
					addr, 0,
					len,
					0,
					wid);
		adaptor->rp_write(adaptor->pkt_tx.pkt, plen);
		adaptor->rp_write(data, len);
	}
	do {
		resp_ready = adaptor->rp_process(false);
	} while (!resp_ready);

	if (cmd == tlm::TLM_READ_COMMAND) {
		memcpy(data, adaptor->pkt_rx.u8 + adaptor->pkt_rx.data_offset, len);
	}
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}
