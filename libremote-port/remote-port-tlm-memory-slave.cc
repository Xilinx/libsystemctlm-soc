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

#include "tlm-extensions/genattr.h"
#include "tlm-extensions/atsattr.h"

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

// Convert TLM Generic Attributes into remote-port attributes.
static inline uint64_t genattr_to_rpattr(genattr_extension *genattr)
{
	uint64_t rp_attr = 0;

	if (genattr->get_eop()) {
		rp_attr |= RP_BUS_ATTR_EOP;
	}
	if (genattr->get_secure()) {
		rp_attr |= RP_BUS_ATTR_SECURE;
	}
	return rp_attr;
}

void remoteport_tlm_memory_slave::b_transport(tlm::tlm_generic_payload& trans,
				       sc_time& delay)
{
	size_t plen;
	struct rp_encode_busaccess_in in = {0};

	tlm::tlm_command cmd = trans.get_command();
	sc_dt::uint64 addr = trans.get_address();
	unsigned char *data = trans.get_data_ptr();
	unsigned char *be = trans.get_byte_enable_ptr();
	unsigned int len = trans.get_data_length();
	unsigned int wid = trans.get_streaming_width();
	remoteport_packet pkt_tx;
	genattr_extension *genattr;
	atsattr_extension *atsattr;
	uint16_t master_id = 0;
	uint64_t attr = 0;
	unsigned int ri;
	bool is_posted = false;

	if (be && !adaptor->peer.caps.busaccess_ext_byte_en) {
		trans.set_response_status(tlm::TLM_BYTE_ENABLE_ERROR_RESPONSE);
		return;
	}

	trans.get_extension(genattr);
	if (genattr) {
		in.flags |= genattr->get_posted() ? RP_PKT_FLAGS_posted : 0;
		master_id = genattr->get_master_id();
		attr |= genattr_to_rpattr(genattr);
		is_posted = genattr->get_posted();
	}
	trans.get_extension(atsattr);
	if (atsattr) {
		attr |= atsattr->is_phys_addr() ? RP_BUS_ATTR_PHYS_ADDR : 0;
	}

	pkt_tx.alloc(sizeof pkt_tx.pkt->busaccess + len);
	in.clk = adaptor->rp_map_time(adaptor->sync->get_current_time());

	in.cmd = cmd == tlm::TLM_READ_COMMAND ? RP_CMD_read : RP_CMD_write;
	in.id = adaptor->rp_pkt_id++;
	in.dev = dev_id;
	in.master_id = master_id;
	in.addr = addr;
	in.attr = attr;
	in.size = len;
	in.width = 0;
	in.stream_width = wid;
	in.byte_enable_len = trans.get_byte_enable_length();


	plen = rp_encode_busaccess(&adaptor->peer,
				   &pkt_tx.pkt->busaccess_ext_base,
				   &in);

	adaptor->rp_write(pkt_tx.pkt, plen);
	if (cmd == tlm::TLM_WRITE_COMMAND) {
		adaptor->rp_write(data, len);
	}
	if (in.byte_enable_len) {
		adaptor->rp_write(be, in.byte_enable_len);
	}

	if (is_posted) {
		return;
	}

	ri = response_wait(in.id);
	assert(resp[ri].pkt.pkt->hdr.id == in.id);

	switch (rp_get_busaccess_response(resp[ri].pkt.pkt)) {
	case RP_RESP_OK:
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		break;
	case RP_RESP_ADDR_ERROR:
		trans.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
		break;
	default:
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		break;
	}

	if (cmd == tlm::TLM_READ_COMMAND) {
		uint8_t *rx_data = rp_busaccess_rx_dataptr(&adaptor->peer,
					   &resp[ri].pkt.pkt->busaccess_ext_base);

		// Handle READ byte-enables.
		//
		// For reads, we pass along the byte enables to our peer
		// so that it can avoid issues reads for disabled bytes.
		// This is may be important for addresses with read side
		// effects.
		//
		// According to the TLM spec, reads with byte-enables
		// should not modify byte disabled content in the
		// generic payload data buffer.
		// The remote peer does not control our buffer, so we
		// do it here.
		//
		if (in.byte_enable_len) {
			unsigned int i;

			for (i = 0; i < len; i++) {
				uint8_t b = be[i % in.byte_enable_len];
				if (b == TLM_BYTE_ENABLED) {
					data[i] = rx_data[i];
				}
			}
		} else {
			memcpy(data, rx_data, len);
		}
	}
	// Give back the RP response slot.
	response_done(ri);
}
