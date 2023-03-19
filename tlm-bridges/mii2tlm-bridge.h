/*
 * MII to TLM Generic-Payload Streams bridge.
 *
 * Copyright (c) 2023 Zero ASIC
 * Written by Edgar E. Iglesias.
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
#ifndef __MII2TLM_BRIDGE_H__
#define __MII2TLM_BRIDGE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES
#include <stdio.h>
#include "tlm-extensions/genattr.h"

#define D(x)

class mii2tlm_bridge
: public sc_core::sc_module
{
public:
        tlm_utils::simple_initiator_socket<mii2tlm_bridge> init_socket;

	mii2tlm_bridge(sc_core::sc_module_name name);
	SC_HAS_PROCESS(mii2tlm_bridge);

	sc_in<bool> clk;
	sc_in<sc_bv<4> > data;
	sc_in<bool > enable;

private:
	// Max packet size.
	unsigned char buf[8 * 1024];
	unsigned int len;
	sc_time delay;

	int preamble_count;
	unsigned int d8;
	int d8_count;

	enum {
		IDLE = 0,
		PREAMBLE = 1,
		DATA = 2,
	} state;

	void process_nibble(tlm::tlm_generic_payload &tr, uint8_t data);
	void reset(void);
	void process(void);
};

mii2tlm_bridge::mii2tlm_bridge(sc_module_name name)
	: sc_module(name),
	init_socket("init_socket"),
	clk("clk"),
	data("data"),
	enable("enable")
{
        SC_THREAD(process);
}

void mii2tlm_bridge::reset(void)
{
	// Reset.
	len = 0;
	d8 = 0;
	d8_count = 0;
	preamble_count = 0;
	state = IDLE;
	delay = SC_ZERO_TIME;
}

void mii2tlm_bridge::process_nibble(tlm::tlm_generic_payload &tr, uint8_t d4)
{
	D(printf("d8=%2.2x d4=%2.2x len=%d\n", d8, d4, len));

	switch (state) {
	case IDLE:
		if (d4 == 0x5) {
			preamble_count = 1;
			state = PREAMBLE;
		}
		break;
	case PREAMBLE:
		if (d4 == 0x5) {
			preamble_count++;
		} else {
			state = d4 == 0xd ? DATA : IDLE;
		}
		break;
	case DATA:
		switch (d8_count) {
		case 0:
			d8 = d4;
			d8_count++;
			break;
		case 1:
			d8 |= d4 << 4;
			buf[len++] = d8;
			d8 = 0;
			d8_count = 0;
			break;
		};
		break;
	default:
		assert(0);
		break;
	};
}

void mii2tlm_bridge::process(void) {
	tlm::tlm_generic_payload tr;
	genattr_extension *genattr;
	int l;

	genattr = new(genattr_extension);
	genattr->set_eop(true);
	genattr->set_posted(true);

	tr.set_extension(genattr);
	tr.set_command(tlm::TLM_WRITE_COMMAND);
	tr.set_address(0);
	tr.set_data_ptr(buf);
	tr.set_dmi_allowed(false);

	// Reset the packet gathering state.
	reset();

	while (true) {
		uint16_t d;

		wait(clk.posedge_event());

		if (enable.read()) {
			d = data.read().to_uint64();
			process_nibble(tr, d);
		} else {
			if (len) {
				int i;
				D(printf("tx-packet:\n"));
				for (i = 0; i < len; i++) {
					D(printf("%2.2x ", buf[i]));
				}
				D(printf("\n"));
			}
			// TX and reset.
			if (len) {
				tr.set_data_length(len);
				tr.set_streaming_width(len);
				tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
				init_socket->b_transport(tr, delay);
			}
			reset();
		}
	}

	tr.release_extension(genattr);
}
#undef D
#endif
