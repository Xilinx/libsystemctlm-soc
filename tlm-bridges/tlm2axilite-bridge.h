/*
 * TLM-2.0 to AXI-Lite bridge.
 *
 * Copyright (c) 2017 Xilinx Inc.
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

#ifndef TLM2AXILITE_BRIDGE_H__
#define TLM2AXILITE_BRIDGE_H__
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "tlm-bridges/amba.h"

#define D(x)

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH>
class tlm2axilite_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm2axilite_bridge> tgt_socket;

	tlm2axilite_bridge(sc_core::sc_module_name name);
	SC_HAS_PROCESS(tlm2axilite_bridge);

	sc_in<BOOL_TYPE> clk;

	/* Write address channel.  */
	sc_out<BOOL_TYPE> awvalid;
	sc_in<BOOL_TYPE> awready;
	sc_out<ADDR_TYPE<ADDR_WIDTH> > awaddr;
	sc_out<DATA_TYPE<3> > awprot;

	/* Write data channel.  */
	sc_out<BOOL_TYPE> wvalid;
	sc_in<BOOL_TYPE> wready;
	sc_out<DATA_TYPE<DATA_WIDTH> > wdata;
	sc_out<ADDR_TYPE<DATA_WIDTH/8> > wstrb;

	/* Write response channel.  */
	sc_in<BOOL_TYPE> bvalid;
	sc_out<BOOL_TYPE> bready;
	sc_in<DATA_TYPE<2> > bresp;

	/* Read address channel.  */
	sc_out<BOOL_TYPE> arvalid;
	sc_in<BOOL_TYPE> arready;
	sc_out<ADDR_TYPE<ADDR_WIDTH> > araddr;
	sc_out<DATA_TYPE<3> > arprot;

	/* Read data channel.  */
	sc_in<BOOL_TYPE> rvalid;
	sc_out<BOOL_TYPE> rready;
	sc_in<DATA_TYPE<DATA_WIDTH> > rdata;
	sc_in<ADDR_TYPE<2> > rresp;

private:
	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay);
};

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH>
tlm2axilite_bridge<BOOL_TYPE, ADDR_TYPE, ADDR_WIDTH, DATA_TYPE, DATA_WIDTH> ::tlm2axilite_bridge(sc_module_name name)
	: sc_module(name), tgt_socket("tgt-socket"),
	clk("clk"),
	awvalid("awvalid"),
	awready("awready"),
	awaddr("awaddr"),
	awprot("awprot"),

	wvalid("wvalid"),
	wready("wready"),
	wdata("wdata"),
	wstrb("wstrb"),

	bvalid("bvalid"),
	bready("bready"),
	bresp("bresp"),

	arvalid("arvalid"),
	arready("arready"),
	araddr("araddr"),
	arprot("arprot"),

	rvalid("rvalid"),
	rready("rready"),
	rdata("rdata"),
	rresp("rresp")
{
	tgt_socket.register_b_transport(this, &tlm2axilite_bridge::b_transport);
}

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH>
void tlm2axilite_bridge
<BOOL_TYPE, ADDR_TYPE, ADDR_WIDTH, DATA_TYPE, DATA_WIDTH>
::b_transport(tlm::tlm_generic_payload& trans, sc_time& delay)
{
	tlm::tlm_command cmd = trans.get_command();
	sc_dt::uint64 addr = trans.get_address();
	unsigned char *data = trans.get_data_ptr();
	unsigned int len = trans.get_data_length();
	unsigned char *be = trans.get_byte_enable_ptr();
	uint64_t data64 = 0;
	bool ar, dr;
	unsigned int resp = AXI_DECERR;

	D(printf("TLM2AXI-Lite addr=%" PRIx64 " rw=%d len=%d\n",
		(uint64_t) addr, cmd == tlm::TLM_WRITE_COMMAND, len));
	if (len > DATA_WIDTH / 8) {
		trans.set_response_status(tlm::TLM_BURST_ERROR_RESPONSE);
		return;
	}

	/* Send the address.  */
	if (cmd == tlm::TLM_READ_COMMAND) {
		araddr.write(addr);
		arprot.write(0);
		arvalid.write(true);
	} else {
		awaddr.write(addr);
		awprot.write(0);
		awvalid.write(true);
	}

	/* Send or receive data.  */
	if (cmd == tlm::TLM_READ_COMMAND) {
		rready.write(true);
	} else {
		uint64_t strb;
		unsigned int i;

		if (be) {
			int be_len = trans.get_byte_enable_length();

			strb = 0;
			for (i = 0; i < len; i++) {
				uint8_t b = be[i % be_len];
				if (b == TLM_BYTE_ENABLED) {
					strb |= 1 << i;
				}
			}
		} else {
			/* All lanes active.  */
			strb = (1 << len) - 1;
		}

		memcpy(&data64, data, len);
		D(printf("data64=%lx strb=%lx\n", data64, strb));
		wdata.write(data64);
		wstrb.write(strb);
		wvalid.write(true);
		bready.write(true);
	}

	/* Wait for address and data phases.  */
	ar = false;
	dr = false;
	do {
		wait(clk.posedge_event());
		if (cmd == tlm::TLM_READ_COMMAND) {
			ar |= arready.read();
			dr = rvalid.read();

			if (ar)
				arvalid.write(false);
			data64 = rdata.read().to_uint64();
			resp = rresp.read().to_uint64();
			memcpy(data, &data64, len);
			D(printf("Read dr=%d data64=%" PRIx64 "\n", dr, data64));
		} else {
			ar |= awready.read();
			dr = wready.read();
			if (ar)
				awvalid.write(false);
		}
	} while (!ar || !dr);

	arvalid.write(false);
	rready.write(false);
	awvalid.write(false);
	wvalid.write(false);

	if (cmd == tlm::TLM_WRITE_COMMAND) {
		bool r;
		/* Wait for Bresp channel.  */
		do {
			r = bvalid.read();
			resp = bresp.read().to_uint64();
			wait(clk.posedge_event());
		} while (r == false);
	}
	bready.write(false);

	D(printf("DONE\n\n"));

	switch (resp) {
	case AXI_OKAY:
	case AXI_EXOKAY:
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		break;
	case AXI_DECERR:
		trans.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
		break;
	default:
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		break;
	}
}
#undef D
#endif
