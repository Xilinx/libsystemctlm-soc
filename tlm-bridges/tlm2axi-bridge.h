/*
 * TLM-2.0 to AXI bridge.
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

#ifndef TLM2AXI_BRIDGE_H__
#define TLM2AXI_BRIDGE_H__
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "tlm-bridges/amba.h"
#include "tlm-extensions/genattr.h"

#define D(x)

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH>
class tlm2axi_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm2axi_bridge> tgt_socket;

	tlm2axi_bridge(sc_core::sc_module_name name);
	SC_HAS_PROCESS(tlm2axi_bridge);

	sc_in<BOOL_TYPE> clk;

	/* Write address channel.  */
	sc_out<BOOL_TYPE> awvalid;
	sc_in<BOOL_TYPE> awready;
	sc_out<ADDR_TYPE<ADDR_WIDTH> > awaddr;
	sc_out<DATA_TYPE<3> > awprot;
	sc_out<sc_bv<2> > awuser;
	sc_out<sc_bv<4> > awregion;
	sc_out<sc_bv<4> > awqos;
	sc_out<sc_bv<4> > awcache;
	sc_out<sc_bv<2> > awburst;
	sc_out<sc_bv<3> > awsize;
	sc_out<sc_bv<8> > awlen;
	sc_out<bool > awid;
	sc_out<bool > awlock;

	/* Write data channel.  */
	sc_out<BOOL_TYPE> wvalid;
	sc_in<BOOL_TYPE> wready;
	sc_out<DATA_TYPE<DATA_WIDTH> > wdata;
	sc_out<ADDR_TYPE<DATA_WIDTH/8> > wstrb;
	sc_out<sc_bv<2> > wuser;
	sc_out<bool> wlast;

	/* Write response channel.  */
	sc_in<BOOL_TYPE> bvalid;
	sc_out<BOOL_TYPE> bready;
	sc_in<DATA_TYPE<2> > bresp;
	sc_in<sc_bv<2> > buser;
	sc_in<bool> bid;

	/* Read address channel.  */
	sc_out<BOOL_TYPE> arvalid;
	sc_in<BOOL_TYPE> arready;
	sc_out<ADDR_TYPE<ADDR_WIDTH> > araddr;
	sc_out<DATA_TYPE<3> > arprot;
	sc_out<sc_bv<2> > aruser;
	sc_out<sc_bv<4> > arregion;
	sc_out<sc_bv<4> > arqos;
	sc_out<sc_bv<4> > arcache;
	sc_out<sc_bv<2> > arburst;
	sc_out<sc_bv<3> > arsize;
	sc_out<sc_bv<8> > arlen;
	sc_out<bool > arid;
	sc_out<bool > arlock;

	/* Read data channel.  */
	sc_in<BOOL_TYPE> rvalid;
	sc_out<BOOL_TYPE> rready;
	sc_in<DATA_TYPE<DATA_WIDTH> > rdata;
	sc_in<ADDR_TYPE<2> > rresp;
	sc_in<sc_bv<2> > ruser;
	sc_in<bool> rid;
	sc_in<bool> rlast;

private:
	int prepare_wbeat(tlm::tlm_generic_payload& trans, sc_time& delay,
			unsigned int offset);
	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay);
};

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH>
tlm2axi_bridge<BOOL_TYPE, ADDR_TYPE, ADDR_WIDTH, DATA_TYPE, DATA_WIDTH> ::tlm2axi_bridge(sc_module_name name)
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
	tgt_socket.register_b_transport(this, &tlm2axi_bridge::b_transport);
}

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH>
int tlm2axi_bridge
<BOOL_TYPE, ADDR_TYPE, ADDR_WIDTH, DATA_TYPE, DATA_WIDTH>
::prepare_wbeat(tlm::tlm_generic_payload& trans, sc_time& delay,
                unsigned int offset)
{
	sc_dt::uint64 addr = trans.get_address();
	unsigned char *data = trans.get_data_ptr();
	unsigned int len = trans.get_data_length();
	unsigned char *be = trans.get_byte_enable_ptr();
	unsigned int bitoffset;
	uint64_t strb;
	sc_bv<DATA_WIDTH> data128 = 0;
	uint64_t t64;
	unsigned int i;
	unsigned int maxlen, wlen;

	addr += offset;
	data += offset;
	len -= offset;

	bitoffset = (addr * 8) % DATA_WIDTH;
	maxlen = (DATA_WIDTH - bitoffset) / 8;
	wlen = len <= maxlen ? len : maxlen;

	D(printf("WBEAT: pos=%d wlen=%d bitoffset=%d\n", offset, wlen, bitoffset));

	if (be) {
		int be_len = trans.get_byte_enable_length();

		strb = 0;
		for (i = 0; i < wlen; i++) {
			uint8_t b = be[(i + bitoffset / 8) % be_len];
			if (b == TLM_BYTE_ENABLED) {
				strb |= 1 << i;
			}
		}
	} else {
		/* All lanes active.  */
		strb = (1 << wlen) - 1;
	}
	strb <<= bitoffset / 8;

	for (i = 0; i < wlen; i += sizeof(t64)) {
		int copylen = wlen < sizeof(t64) ? wlen : sizeof(t64);

		t64 = 0;
		memcpy(&t64, data + i, copylen);
		data128.range(copylen * 8 - 1 + i * 8 + bitoffset,
			i * 8 + bitoffset) = t64;
	}

	wdata.write(data128);
	D(cout << "strb " << strb << endl);
	D(cout << "data128 " << data128 << endl);

	wstrb.write(strb);
	wvalid.write(true);
	bready.write(true);
	return wlen;
}

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH>
void tlm2axi_bridge
<BOOL_TYPE, ADDR_TYPE, ADDR_WIDTH, DATA_TYPE, DATA_WIDTH>
::b_transport(tlm::tlm_generic_payload& trans, sc_time& delay)
{
	tlm::tlm_command cmd = trans.get_command();
	sc_dt::uint64 addr = trans.get_address();
	unsigned char *data = trans.get_data_ptr();
	unsigned int len = trans.get_data_length();
	genattr_extension *genattr;
	unsigned int bitoffset;
	unsigned int pos = 0;
	uint64_t data64 = 0;
	bool ar, dr, alldone = false;
	unsigned int resp = AXI_DECERR;
	unsigned int nr_beats = (len * 8 + DATA_WIDTH - 1) / DATA_WIDTH;
	unsigned int beat = 0;
	sc_bv<128> data128 = 0;
	unsigned int prot = 0;

	D(printf("TLM2AXI addr=%lx rw=%d len=%d nr-beats=%d\n",
		addr, cmd == tlm::TLM_WRITE_COMMAND, len,
		nr_beats));

	/* Extensions.  */
	trans.get_extension(genattr);
	if (genattr) {
		if (genattr->get_non_secure()) {
			prot |= AXI_PROT_NS;
		}
	}

	/* Send the address.  */
	if (cmd == tlm::TLM_READ_COMMAND) {
		araddr.write(addr);
		arprot.write(prot);
		arsize.write(7);
		arlen.write(nr_beats - 1);
		arburst.write(AXI_BURST_INCR);

		arvalid.write(true);
	} else {
		awaddr.write(addr & ~0xf);
		awprot.write(prot);
		awsize.write(7);
		awlen.write(nr_beats - 1);
		awburst.write(AXI_BURST_INCR);

		awvalid.write(true);
	}

	/* Prepare first beat of data.  */
	bitoffset = (addr * 8) % DATA_WIDTH;
	if (cmd == tlm::TLM_READ_COMMAND) {
		rready.write(true);
	} else {
		pos += prepare_wbeat(trans, delay, pos);
		beat++;
		alldone = pos == len;
		wlast.write(alldone);
	}

	/* Wait for address and data phases to finish.  */
	ar = false;
	dr = false;
	do {
		wait(clk.posedge_event());

		if (cmd == tlm::TLM_READ_COMMAND) {
			ar |= arready.read();
			dr = rvalid.read();
			if (ar)
				arvalid.write(false);

			if (dr) {
				unsigned int readlen;
				unsigned int w;

				readlen = (DATA_WIDTH - bitoffset) / 8;
				readlen = readlen <= len ? readlen : len;

				for (w = 0; w < readlen; w += sizeof data64) {
					int copylen = readlen <= sizeof data64 ? readlen : sizeof data64;
					data128 = rdata.read() >> (w * 8 + bitoffset);
					data64 = data128.to_uint64();
					memcpy(data + pos, &data64, copylen);
					D(printf("Read dr=%d data64=%lx pos=%d\n",
						dr, data64, pos,
						(w * sizeof data64 * 8 + bitoffset)));
					pos += copylen;
				}
				bitoffset = 0;

				resp = rresp.read().to_uint64();
				alldone = pos == len;
			}
		} else {
			ar |= awready.read();
			dr = wready.read();
			if (ar)
				awvalid.write(false);

			if (dr) {
				alldone = pos == len;
				if (!alldone) {
					pos += prepare_wbeat(trans, delay, pos);
					wlast.write(alldone);
					beat++;
					wlast.write(beat == nr_beats);
				} else {
					D(printf("beat=%d nr-beats=%d\n", beat, nr_beats));
					assert(beat == nr_beats);
					wvalid.write(false);
				}
			}
		}
		D(printf("wr=%d pos=%d len=%d\n", cmd == tlm::TLM_WRITE_COMMAND,
			pos, len));
		fflush(NULL);
	} while (!ar || !dr || !alldone);

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
			if (!r)
				wait(clk.posedge_event());
		} while (r == false);
	}
	bready.write(false);

	D(printf("DONE resp=%d\n\n", resp));

	switch (resp) {
	case AXI_OKAY:
	case AXI_EXOKAY:
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		break;
	case AXI_DECERR:
		D(printf("DECERR\n"));
		trans.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
		break;
	case AXI_SLVERR:
		D(printf("SLVERR\n"));
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		break;
	}
	D(fflush(NULL));
}
#undef D
#endif
