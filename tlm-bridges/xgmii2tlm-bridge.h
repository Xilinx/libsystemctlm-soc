/*
 * XGMII to TLM Generic-Payload Streams bridge.
 *
 * Copyright (c) 2019 Xilinx Inc.
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
#ifndef __XGMII2TLM_BRIDGE_H__
#define __XGMII2TLM_BRIDGE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES
#include <stdio.h>
#include "tlm-extensions/genattr.h"

#define D(x)

class xgmii2tlm_bridge
: public sc_core::sc_module
{
public:
        tlm_utils::simple_initiator_socket<xgmii2tlm_bridge> init_socket;

	enum xgmii_mode {
		MODE_10G = 0,
		MODE_1G = 1,
	} mode;

	xgmii2tlm_bridge(sc_core::sc_module_name name,
				enum xgmii_mode mode = MODE_10G);
	SC_HAS_PROCESS(xgmii2tlm_bridge);

	sc_in<bool> clk;
	sc_in<sc_bv<64> > xxd;
	sc_in<sc_bv<8> > xxc;
private:
	// Max packet size.
	unsigned char buf[8 * 1024];
	unsigned int len;
	bool sof_found;
	bool preamble_55_found;
	bool preamble_d5_found;
	sc_time delay;

	void process_byte(tlm::tlm_generic_payload &tr,
				uint8_t data, bool ctrl);
	void reset(void);
	void process(void);
};

xgmii2tlm_bridge::xgmii2tlm_bridge(sc_module_name name, enum xgmii_mode mode)
	: sc_module(name),
	init_socket("init_socket"),
	mode(mode),
	clk("clk"),
	xxd("xxd"),
	xxc("xxc")
{
        SC_THREAD(process);
}

void xgmii2tlm_bridge::reset(void)
{
	// Reset.
	len = 0;
	sof_found = false;
	preamble_55_found = false;
	preamble_d5_found = false;
	delay = SC_ZERO_TIME;
}

void xgmii2tlm_bridge::process_byte(tlm::tlm_generic_payload &tr,
					uint8_t data, bool ctrl)
{
	D(printf("c=%x %2.2x len=%d\n", ctrl, data, len));

	if (ctrl == 1) {
		if (data == 0xfb) {
			sof_found = true;
			preamble_55_found = false;
			preamble_d5_found = false;
			len = 0;
		}
		if (data == 0xfe) {
			printf("Frame error\n");
			reset();
		}
		if (data == 0xfd) {
			if (!preamble_d5_found) {
				reset();
				return;
			}

			// EOF, emit generic payload.
			D(printf("phy-tx: proxy to QEMU %d\n",
						len));
			tr.set_data_length(len - 4);
			tr.set_streaming_width(len - 4);
			tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
			init_socket->b_transport(tr, delay);

			// Start gathering a new packet.
			reset();
		}
	} else {
		if (sof_found) {
			if (preamble_d5_found) {
				buf[len++] = data;
			} else if (preamble_55_found) {
				if (data == 0xd5) {
					preamble_d5_found = true;
				}
			} else {
				if (data == 0x55) {
					preamble_55_found = true;
				}
			}
		}
		if (len == sizeof buf) {
			printf("XGMII overrun!\n");
			reset();
		}
	}

}

void xgmii2tlm_bridge::process(void) {
	int lanes = mode == MODE_10G ? 8 : 1;
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
		uint64_t d64;
		uint8_t c8;
		wait(clk.posedge_event());
		d64 = xxd.read().to_uint64();
		c8 = xxc.read().to_uint64();

		// Fast path, all lanes carry packet data.
		if (mode == MODE_10G && preamble_d5_found && c8 == 0) {
			memcpy(buf + len, &d64, 8);
			len += 8;
			continue;
		}

		for (l = 0; l < lanes; l++) {
			uint8_t d8;
			bool c1;

			d8 = d64 >> l * 8;
			c1 = c8 & (1 << l);
			process_byte(tr, d8, c1);
		}
	}

	tr.release_extension(genattr);
}
#undef D
#endif
