/*
 * TLM Generic-Payload Streams to MII bridge.
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
#ifndef __TLM2MII_BRIDGE_H__
#define __TLM2MII_BRIDGE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES
#include <stdio.h>
#include "utils/crc32.h"

#define D(x)

class tlm2mii_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm2mii_bridge> socket;

	tlm2mii_bridge(sc_core::sc_module_name name, bool append_csum = true);

	sc_in<bool> clk;
	sc_out<sc_bv<4> > data;
	sc_out<bool > enable;
private:
	SC_HAS_PROCESS(tlm2mii_bridge);
	sc_fifo<tlm::tlm_generic_payload*> rxfifo;
	bool m_append_csum;

	void push_data_buf(const char *name, unsigned char *buf,
			   int len, bool en = true);

	void process_packet(unsigned char *data, int len);
	void process_thread() {
		while(true) {
			tlm::tlm_generic_payload *gp = rxfifo.read();
			process_packet(gp->get_data_ptr(), gp->get_data_length());

			delete gp->get_data_ptr();
			delete gp;
		}
	}
	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay);
};

tlm2mii_bridge::tlm2mii_bridge(sc_module_name name, bool append_csum)
	: sc_module(name),
	socket("socket"),
	clk("clk"),
	data("data"),
	rxfifo("rxfifo", 1),
	m_append_csum(append_csum)
{
	SC_THREAD(process_thread);
	socket.register_b_transport(this, &tlm2mii_bridge::b_transport);
}

void tlm2mii_bridge::push_data_buf(const char *name, unsigned char *buf,
					int len, bool en)
{
	int i = 0;

	D(printf("phy: %s len=%d\n", name, len));
	for (i = 0; i < len * 2; i++) {
		unsigned int d4 = 0;

		wait(clk.posedge_event());
		enable.write(en);

		if (i & 1) {
			D(printf("%2.2x ", buf[i / 2]));
		}

		d4 = buf[i / 2];
		d4 >>= (i & 1) * 4;
		d4 &= 0xf;

		data.write(d4);
	}
	D(printf("\n"));
}

void tlm2mii_bridge::process_packet(unsigned char *data, int len)
{
	unsigned char idle_seq[] = { 0x07, 0x07, 0x07, 0x07,
				     0x07, 0x07, 0x07, 0x07 };
	unsigned char sof_preamble_seq[] = { 0x55, 0x55, 0x55, 0x55,
					     0x55, 0x55, 0x55, 0xd5 };
	unsigned char crc_d[4];
	unsigned int i;
	uint32_t crc;

	// Emit some idle sequence.
	push_data_buf("idle", idle_seq, sizeof(idle_seq), false);

	// Emit preamble
	push_data_buf("sof_preamble",
		      sof_preamble_seq, sizeof(sof_preamble_seq));

	push_data_buf("packet-data", data, len);

	if (m_append_csum) {
		crc = crc32(0, data, len);
		// Append a checksum.
		crc_d[0] = crc; crc >>= 8;
		crc_d[1] = crc; crc >>= 8;
		crc_d[2] = crc; crc >>= 8;
		crc_d[3] = crc;

		push_data_buf("crc", crc_d, sizeof(crc_d));
	}
	wait(clk.posedge_event());

	// Done
	enable.write(0);
}

void tlm2mii_bridge::b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay)
{
	tlm::tlm_generic_payload *gp = new tlm::tlm_generic_payload();
	unsigned char *buf = new unsigned char [trans.get_data_length()];

	gp->set_data_ptr(buf);
	gp->deep_copy_from(trans);
	rxfifo.write(gp);

	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}
#undef D
#endif
