/*
 * A debug device.
 *
 * Copyright (c) 2025, Advanced Micro Device, Inc.
 * Written by Sai Pavan
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

#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

using namespace sc_core;
using namespace std;

#include "wiredev.h"
#include <sys/types.h>
#include <time.h>

wiredev::wiredev(sc_module_name name, unsigned int nr_wires_in,
		 unsigned int nr_wires_out)
	: sc_module(name), socket("socket"),
	  wires_in("wires-in", nr_wires_in),
	  wires_out("wires-out", nr_wires_out)
{
	/* We don't support mixed in-outs.  */
	assert(nr_wires_in == 0 || nr_wires_out == 0);
	socket.register_b_transport(this, &wiredev::b_transport);
	socket.register_transport_dbg(this, &wiredev::transport_dbg);
}

void wiredev::b_transport(tlm::tlm_generic_payload& trans, sc_time& delay)
{
	unsigned int i = 0;
	tlm::tlm_command cmd = trans.get_command();
	sc_dt::uint64    addr = trans.get_address();
	unsigned char*   data = trans.get_data_ptr();
	unsigned int     len = trans.get_data_length();
	uint64_t v = 0;
	uint32_t wire_offset = 0;
	bool is_input = wires_in.size();
	unsigned int nr_wires = is_input ? wires_in.size() : wires_out.size();

	if (len > sizeof(v)) {
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		return;
	}

	if (trans.get_command() == tlm::TLM_READ_COMMAND) {
		wire_offset = addr * 8;
		for (i = wire_offset; i < wire_offset + (len * 8); i++) {
			bool val;

			if (i >= nr_wires) {
				break;
			}

			val = is_input ? wires_in[i].read() : wires_out[i].read();
			v = v | (val << (i - wire_offset));
		}
		memcpy(data, &v, len);
	} else if (cmd == tlm::TLM_WRITE_COMMAND) {
		if (is_input) {
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
			return;
		}

		memcpy(&v, data, len);
		wire_offset = addr * 8;
		for (i = wire_offset; i < wire_offset + (len * 8); i++) {
			if (i >= wires_out.size()) {
				break;
			}
			wires_out[i].write(v & ((uint64_t)1 << (i - wire_offset)));
		}
	}

	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}

unsigned int wiredev::transport_dbg(tlm::tlm_generic_payload& trans)
{
	unsigned int     len = trans.get_data_length();
	return len;
}
