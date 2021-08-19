/*
 * TLM Generic-Payload Streams to XGMII bridge.
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
#ifndef __TLM2XGMII_BRIDGE_H__
#define __TLM2XGMII_BRIDGE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES
#include <stdio.h>

#define D(x)

class tlm2xgmii_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm2xgmii_bridge> tgt_socket;

	enum xgmii_mode {
		MODE_10G = 0,
		MODE_1G = 1,
	} mode;

	tlm2xgmii_bridge(sc_core::sc_module_name name,
				enum xgmii_mode mode = MODE_10G);

	sc_in<bool> clk;
	sc_out<sc_bv<64> > xxd;
	sc_out<sc_bv<8> > xxc;
private:
	void push_data_buf(const char *name, unsigned char *buf,
				int len, uint64_t ctrl);

	void process_packet(unsigned char *data, int len);
	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay);
};

tlm2xgmii_bridge::tlm2xgmii_bridge(sc_module_name name, enum xgmii_mode mode)
	: sc_module(name),
	tgt_socket("tgt_socket"),
	mode(mode),
	clk("clk"),
	xxd("xxd"),
	xxc("xxc")
{
	tgt_socket.register_b_transport(this, &tlm2xgmii_bridge::b_transport);
}

void tlm2xgmii_bridge::push_data_buf(const char *name, unsigned char *buf,
					int len, uint64_t ctrl)
{
	int lanes = mode == MODE_10G ? 8 : 1;
	int l;
	int i = 0;

	D(printf("phy: %s ctrl=%" PRIx64 " len=%d\n", name, ctrl, len));
	while (i < len) {
		uint64_t data = 0;
		uint8_t c = 0xff;

		wait(clk.posedge_event());

		for (l = 0; l < lanes && i < len; l++) {
			data |= (uint64_t)buf[i++] << (l * 8);

			c &= ~(1 << l);
			c |= (ctrl & 1) << l;
			ctrl >>= 1;
		}
		xxc.write(c);
		xxd.write(data);

		if (lanes == 8) {
			D(printf("c=%2.2x %16.16lx \n", c, data));
		} else {
			D(printf("c=%2.2x %2.2lx \n", c, data));
		}
	}
	D(printf("\n"));
}

void tlm2xgmii_bridge::process_packet(unsigned char *data, int len)
{
	unsigned char idle_seq[] = { 0x07, 0x07, 0x07, 0x07,
				     0x07, 0x07, 0x07, 0x07 };
	unsigned char sof_preamble_seq[] = { 0xfb, 0x55, 0x55, 0x55,
					     0x55, 0x55, 0x55, 0xd5 };
	struct {
		unsigned char d[16];
		uint64_t c;
		int len;
	} last;
	unsigned int i;

	last.len = len % 8;

	// Emit some idle sequence.
	for (i = 0; i < 2; i++) {
		push_data_buf("idle", idle_seq, sizeof(idle_seq), 0xff);
	}

	// Emit preamble
	push_data_buf("sof_preamble",
			sof_preamble_seq, sizeof(sof_preamble_seq), 1);

	push_data_buf("packet-data", data, len & (~7), 0);
	memset(last.d, 0x07, sizeof(last.d));
	memcpy(last.d, data + (len & (~7)), last.len);

	// Append a checksum.
	last.d[last.len++] = 0xC0;
	last.d[last.len++] = 0xC1;
	last.d[last.len++] = 0xC2;
	last.d[last.len++] = 0xC3;

	// Append an EOF ctrl byte.
	last.d[last.len++] = 0xFD;
	last.c = ~0U << (last.len - 1);

	push_data_buf("packet-data + eof", last.d,
			last.len > 8 ? 16 : 8, last.c);

	push_data_buf("idle", idle_seq, sizeof(idle_seq), 0xff);
}

void tlm2xgmii_bridge::b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay)
{
	unsigned char *data = trans.get_data_ptr();
	unsigned int len = trans.get_data_length();

	process_packet(data, len);
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}
#undef D
#undef MAX_PACKET_SIZE
#endif
