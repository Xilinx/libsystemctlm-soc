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
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH,
	int ID_WIDTH = 8>
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
	sc_out<sc_bv<ID_WIDTH> > awid;
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
	sc_in<sc_bv<ID_WIDTH> > bid;

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
	sc_out<sc_bv<ID_WIDTH> > arid;
	sc_out<bool > arlock;

	/* Read data channel.  */
	sc_in<BOOL_TYPE> rvalid;
	sc_out<BOOL_TYPE> rready;
	sc_in<DATA_TYPE<DATA_WIDTH> > rdata;
	sc_in<ADDR_TYPE<2> > rresp;
	sc_in<sc_bv<2> > ruser;
	sc_in<sc_bv<ID_WIDTH> > rid;
	sc_in<bool> rlast;

	static const uint32_t DATA_BUS_BYTES = DATA_WIDTH/8;

	class Transaction
	{
	public:
		Transaction(tlm::tlm_generic_payload& gp, sc_time& delay,
			    uint32_t AxID) :
			m_gp(gp),
			m_delay(delay),
			AxID(AxID)
		{}

		tlm::tlm_generic_payload& GetGP() { return m_gp; }

		uint32_t GetAxID() { return AxID; }

		sc_time& GetDelay() { return m_delay; }

		sc_event& DoneEvent() { return m_done; }
	private:
		tlm::tlm_generic_payload& m_gp;
		sc_time& m_delay;
		sc_event m_done;
		uint32_t AxID;
	};

	sc_fifo<Transaction*> transFifo;

	sc_fifo<Transaction*> rdRespFifo;

	sc_fifo<Transaction*> wrDataFifo;
	sc_fifo<Transaction*> wrRespFifo;


private:
	int prepare_wbeat(tlm::tlm_generic_payload& trans, sc_time& delay,
			unsigned int offset);

	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		genattr_extension *genattr;
		uint32_t AxID = 0;

		// Does this GP carry a transaction ID?
		trans.get_extension(genattr);
		if (genattr) {
			AxID = genattr->get_transaction_id();
		}

		Transaction tr(trans, delay, AxID);
		// Hand it over to the singal wiggling machinery.
		transFifo.write(&tr);
		// Wait until the transaction is done.
		wait(tr.DoneEvent());
	}

	void read_address_phase(sc_dt::uint64 addr,
					uint8_t burstType,
					unsigned int prot,
					unsigned int nr_beats,
					uint32_t transaction_id)
	{
		araddr.write(addr);
		arprot.write(prot);
		arsize.write((DATA_WIDTH/8)/2);
		arlen.write(nr_beats - 1);
		arburst.write(burstType);
		arid.write(transaction_id);

		arvalid.write(true);

		do {
			wait(clk.posedge_event());
		} while (arready.read() == false);

		arvalid.write(false);
	}

	void write_address_phase(sc_dt::uint64 addr,
					uint8_t burstType,
					unsigned int prot,
					unsigned int nr_beats,
					uint32_t transaction_id)
	{
		awaddr.write(addr);
		awprot.write(prot);
		awsize.write((DATA_WIDTH/8)/2);
		awlen.write(nr_beats - 1);
		awburst.write(burstType);
		awid.write(transaction_id);

		awvalid.write(true);

		do {
			wait(clk.posedge_event());
		} while (awready.read() == false);

		awvalid.write(false);
	}

	bool ValidateBurstWidth(uint32_t burst_width)
	{
		static const unsigned int widths[] = {
			1, 2, 4, 8, 16, 32, 64, 128
		};
		int i;

		for (i = 0; i < sizeof widths / sizeof widths[0]; i++) {
			if (widths[i] == burst_width) {
				return true;
			}
		}
		return false;
	}

	uint8_t GetNumBeats(tlm::tlm_generic_payload& gp)
	{
		uint64_t address = gp.get_address();
		unsigned int dataLen = gp.get_data_length();
		uint32_t burst_width = 0;
		genattr_extension *genattr;
		uint64_t alignedAddress;
		uint8_t nrBeats;

		gp.get_extension(genattr);
		if (genattr) {
			burst_width = genattr->get_burst_width();
		}

		if (burst_width == 0) {
			// Default to databus width
			burst_width = DATA_BUS_BYTES;
		}

		if (!ValidateBurstWidth(burst_width)) {
			SC_REPORT_ERROR("tlm2axi", "AXI burst width error");
		}

		alignedAddress = (address / burst_width) * burst_width;
		dataLen += address - alignedAddress;

		nrBeats = dataLen/burst_width;

		if (dataLen % burst_width) {
			nrBeats++;
		}

		return nrBeats;
	}

	void address_phase()
	{
		while (true) {
			Transaction *tr = transFifo.read();
			tlm::tlm_generic_payload& trans = tr->GetGP();
			unsigned int datalen = trans.get_data_length();
			unsigned int streaming_width = trans.get_streaming_width();
			genattr_extension *genattr;
			unsigned int prot = 0;
			uint8_t transaction_id = 0;
			uint8_t burstType;

			/* Extensions.  */
			trans.get_extension(genattr);
			if (genattr) {
				if (genattr->get_non_secure()) {
					prot |= AXI_PROT_NS;
				}
				transaction_id = genattr->get_transaction_id();
			}

			//
			// Burst type
			//
			if (streaming_width >= datalen) {
				burstType = AXI_BURST_INCR;
			} else if (streaming_width == DATA_BUS_BYTES) {
				burstType = AXI_BURST_FIXED;
			} else if (streaming_width < DATA_BUS_BYTES) {

				//
				// Specify this with burst_width if streaming
				// width is less than the data bus width
				//

				burstType = AXI_BURST_FIXED;

				if (genattr == nullptr) {
					genattr = new genattr_extension();
					trans.set_extension(genattr);
				}

				genattr->set_burst_width(streaming_width);
			} else {
				burstType = AXI_BURST_WRAP;
			}

			/* Send the address.  */
			if (trans.is_read()) {
				read_address_phase(trans.get_address(),
							burstType,
							prot,
							GetNumBeats(trans),
							transaction_id);
				rdRespFifo.write(tr);
			} else {
				write_address_phase(trans.get_address(),
							burstType,
							prot,
							GetNumBeats(trans),
							transaction_id);
				wrDataFifo.write(tr);
			}
		}
	}

	void read_resp_phase()
	{
		rready.write(false);

		while (true) {
			Transaction *tr = rdRespFifo.read();
			tlm::tlm_generic_payload& trans = tr->GetGP();
			unsigned char *data = trans.get_data_ptr();
			unsigned int len = trans.get_data_length();
			uint64_t data64 = 0;
			unsigned int bitoffset;
			unsigned int pos = 0;

			bitoffset = (trans.get_address() * 8) % DATA_WIDTH;

			while (pos < len) {
				rready.write(true);

				wait(clk.posedge_event());

				if (rvalid.read()) {
					sc_bv<128> data128 = 0;
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

				}
			}
			rready.write(false);

			// Set response
			switch (rresp.read().to_uint64()) {
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

			tr->DoneEvent().notify();
		}
	}

	void write_data_phase()
	{
		wvalid.write(false);

		while (true) {
			Transaction *tr = wrDataFifo.read();
			tlm::tlm_generic_payload& trans = tr->GetGP();
			sc_time& delay = tr->GetDelay();
			unsigned int len = trans.get_data_length();
			unsigned int beat = 1;
			unsigned int nr_beats = GetNumBeats(trans);
			unsigned int pos = 0;

			while (pos < len) {
				pos += prepare_wbeat(trans, delay, pos);
				wlast.write(beat == nr_beats);
				beat++;
				do {
					wait(clk.posedge_event());
				} while (wready.read() == false);
			}

			wlast.write(false);
			wvalid.write(false);

			wrRespFifo.write(tr);
		}
	}

	void write_resp_phase()
	{
		bready.write(false);

		while (true) {
			Transaction *tr = wrRespFifo.read();
			tlm::tlm_generic_payload& trans = tr->GetGP();

			bready.write(true);
			do {
				wait(clk.posedge_event());
			} while (bvalid.read() == false);
			bready.write(false);

			// Set TLM response
			switch (bresp.read().to_uint64()) {
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

			tr->DoneEvent().notify();
		}
	}
};

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH, int ID_WIDTH>
tlm2axi_bridge<BOOL_TYPE, ADDR_TYPE, ADDR_WIDTH, DATA_TYPE, DATA_WIDTH, ID_WIDTH> ::tlm2axi_bridge(sc_module_name name)
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

	SC_THREAD(address_phase);
	SC_THREAD(read_resp_phase);
	SC_THREAD(write_data_phase);
	SC_THREAD(write_resp_phase);
}

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH, int ID_WIDTH>
int tlm2axi_bridge
<BOOL_TYPE, ADDR_TYPE, ADDR_WIDTH, DATA_TYPE, DATA_WIDTH, ID_WIDTH>
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
	return wlen;
}


typedef tlm2axi_bridge<bool, sc_bv, 32, sc_bv, 32> TLM2AXI_bridge;

#undef D
#endif
