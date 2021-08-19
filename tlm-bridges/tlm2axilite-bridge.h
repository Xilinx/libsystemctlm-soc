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

#include <vector>
#include <sstream>

#include "tlm-bridges/amba.h"
#include "tlm-modules/tlm-aligner.h"
#include "tlm-extensions/genattr.h"

#define TLM2AXILITE_BRIDGE_MSG "tlm2axilite-bridge"

#define D(x)

template <int ADDR_WIDTH, int DATA_WIDTH>
class tlm2axilite_bridge
: public sc_core::sc_module,
	public tlm_aligner::IValidator,
	public axi_common
{
public:
	tlm_utils::simple_target_socket<tlm2axilite_bridge> tgt_socket;

	SC_HAS_PROCESS(tlm2axilite_bridge);

	sc_in<bool> clk;
	sc_in<bool> resetn;

	/* Write address channel.  */
	sc_out<bool> awvalid;
	sc_in<bool> awready;
	sc_out<sc_bv<ADDR_WIDTH> > awaddr;
	sc_out<sc_bv<3> > awprot;

	/* Write data channel.  */
	sc_out<bool> wvalid;
	sc_in<bool> wready;
	sc_out<sc_bv<DATA_WIDTH> > wdata;
	sc_out<sc_bv<DATA_WIDTH/8> > wstrb;

	/* Write response channel.  */
	sc_in<bool> bvalid;
	sc_out<bool> bready;
	sc_in<sc_bv<2> > bresp;

	/* Read address channel.  */
	sc_out<bool> arvalid;
	sc_in<bool> arready;
	sc_out<sc_bv<ADDR_WIDTH> > araddr;
	sc_out<sc_bv<3> > arprot;

	/* Read data channel.  */
	sc_in<bool> rvalid;
	sc_out<bool> rready;
	sc_in<sc_bv<DATA_WIDTH> > rdata;
	sc_in<sc_bv<2> > rresp;

	tlm2axilite_bridge(sc_core::sc_module_name name,
				bool aligner_enable=true) :
		sc_module(name),
		axi_common(this),
		tgt_socket("tgt_socket"),

		clk("clk"),
		resetn("resetn"),

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
		rresp("rresp"),

		aligner(NULL),
		proxy_init_socket(NULL),
		proxy_target_socket(NULL)
	{
		if (aligner_enable) {
			aligner = new tlm_aligner("aligner",
						  DATA_WIDTH,
						  DATA_WIDTH / 8, /* MAX AXILite tx length.  */
						  4 * 1024, /* AXI never allows crossing of 4K boundary.  */
						  true, /* WRAP burst-types require natural alignment.  */
						  this);

			proxy_init_socket = new tlm_utils::simple_initiator_socket<tlm2axilite_bridge>("proxy_init_socket");
			proxy_target_socket = new tlm_utils::simple_target_socket<tlm2axilite_bridge>("proxy_target_socket");

			(*proxy_init_socket)(aligner->target_socket);
			aligner->init_socket(*proxy_target_socket);

			tgt_socket.register_b_transport(this, &tlm2axilite_bridge::b_transport_proxy);
			proxy_target_socket->register_b_transport(this, &tlm2axilite_bridge::b_transport);
		} else {
			tgt_socket.register_b_transport(this, &tlm2axilite_bridge::b_transport);
		}

		SC_THREAD(read_address_phase);
		SC_THREAD(write_address_phase);
		SC_THREAD(read_resp_phase);
		SC_THREAD(write_data_phase);
		SC_THREAD(write_resp_phase);

		SC_THREAD(reset);
	}

	~tlm2axilite_bridge() {
		delete proxy_init_socket;
		delete proxy_target_socket;
		delete aligner;
	}

private:
	class Transaction
	{
	public:
		Transaction(tlm::tlm_generic_payload& gp) :
			m_gp(gp)
		{
			genattr_extension *genattr;

			m_gp.get_extension(genattr);
			if (genattr) {
				m_genattr.copy_from(*genattr);
			}
		}

		tlm::tlm_generic_payload& GetGP() { return m_gp; }

		uint32_t GetAxID() { return m_genattr.get_transaction_id(); }

		uint64_t GetAddress() { return m_gp.get_address(); }

		uint8_t GetAxProt()
		{
			uint8_t AxProt = 0;

			if (m_genattr.get_non_secure()) {
				AxProt |= AXI_PROT_NS;
			}
			return AxProt;
		}

		sc_event& DoneEvent() { return m_done; }
	private:
		tlm::tlm_generic_payload& m_gp;
		genattr_extension m_genattr;
		sc_event m_done;
	};

	bool validate(uint64_t addr,
			unsigned int len,
			unsigned int streaming_width)
	{
		bool valid_for_axilite = true;

		// All transactions need to be of max bus_width size
		if (len > DATA_WIDTH/8) {
			valid_for_axilite = false;
		}

		// Address must not wrapp
		if (streaming_width < len) {
			valid_for_axilite = false;
		}

		return valid_for_axilite;
	}

	// Useful for debugging the response handling.
	void print_vec(std::vector<Transaction*> &vec, const char *name) {
		int i;

		printf("name=%s size=%d\n", name, (int)vec.size());
		for (i = 0; i < vec.size(); i++) {
			printf("vec[%d].AxID = %d\n", i, vec[i]->GetAxID());
		}
		printf("\n");
	}

	bool Validate(Transaction& tr)
	{
		tlm::tlm_generic_payload& trans = tr.GetGP();

		if (trans.get_data_length() == 0) {
			SC_REPORT_INFO(TLM2AXILITE_BRIDGE_MSG,
					"Zero-length transaction");
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
			return false;
		}

		if (trans.get_data_length() > DATA_WIDTH / 8) {
			SC_REPORT_INFO(TLM2AXILITE_BRIDGE_MSG,
					"Data length > data bus width");
			trans.set_response_status(tlm::TLM_BURST_ERROR_RESPONSE);
			return false;
		}

		return true;
	}

	virtual void b_transport_proxy(tlm::tlm_generic_payload& trans,
					sc_time& delay) {
		return proxy_init_socket[0]->b_transport(trans, delay);
	}

	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		Transaction tr(trans);

		// Since we're going todo waits in order to wiggle the
		// AXI signals, we need to eliminate the accumulated
		// TLM delay.
		wait(delay, resetn.negedge_event());
		delay = SC_ZERO_TIME;

		m_mutex.lock();
		if (resetn.read() && Validate(tr)) {
			// Hand it over to the signal wiggling machinery.
			if (trans.is_read()) {
				rdTransFifo.write(&tr);
			} else {
				wrTransFifo.write(&tr);
			}
			// Wait until the transaction is done.
			wait(tr.DoneEvent());
		} else {
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		}

		m_mutex.unlock();
	}

	bool read_address_phase(Transaction *rt)
	{
		if (reset_asserted()) {
			arvalid.write(false);
			return false;
		}

		araddr.write(rt->GetAddress());
		arprot.write(rt->GetAxProt());

		arvalid.write(true);

		wait_abort_on_reset(arready);

		arvalid.write(false);

		return resetn.read();
	}

	bool write_address_phase(Transaction *wt)
	{
		if (reset_asserted()) {
			awvalid.write(false);
			return false;
		}

		awaddr.write(wt->GetAddress());
		awprot.write(wt->GetAxProt());

		awvalid.write(true);

		return true;
	}

	void address_phase(sc_fifo<Transaction*> &transFifo)
	{
		while (true) {
			Transaction *tr = transFifo.read();
			tlm::tlm_generic_payload& trans = tr->GetGP();

			/* Send the address and pass on the transaction to the
			 * next pipeline step if reset was not asserted.
			 */
			if (trans.is_read()) {
				if (read_address_phase(tr)) {
					rdResponses.write(tr);
				}
			} else {
				if (write_address_phase(tr)) {
					wrDataFifo.write(tr);
					tr = NULL;
					wait_abort_on_reset(awready);
				}
				awvalid.write(false);
			}

			/* Abort transaction if reset is asserted. */
			if (reset_asserted()) {
				if (tr) {
					abort(tr);
				}
				wait_for_reset_release();
			}
		}
	}

	void read_address_phase() {
		address_phase(rdTransFifo);
	}

	void write_address_phase() {
		address_phase(wrTransFifo);
	}

	void read_resp_phase()
	{
		rready.write(false);

		while (true) {
			Transaction *tr = NULL;
			tlm::tlm_generic_payload *trans = NULL;
			unsigned char *data = NULL;
			unsigned char *be = NULL;
			unsigned int len = 0;
			unsigned int be_len = 0;
			uint64_t data64 = 0;
			unsigned int bitoffset = 0;
			unsigned int pos = 0;
			unsigned int streaming_width = 0;

			while (len || tr == NULL) {
				rready.write(true);

				wait(clk.posedge_event() | resetn.negedge_event());

				if (reset_asserted()) {
					break;
				}

				if (rvalid.read()) {
					sc_bv<128> data128 = 0;
					unsigned int readlen;
					unsigned int w;
					uint64_t addr;

					tr = rdResponses.read();

					trans = &tr->GetGP();
					addr = trans->get_address();
					data = trans->get_data_ptr();
					len = trans->get_data_length();
					be = trans->get_byte_enable_ptr();
					be_len = trans->get_byte_enable_length();
					streaming_width = trans->get_streaming_width();

					addr = trans->get_address() + (pos % streaming_width);
					bitoffset = (addr * 8) % DATA_WIDTH;
					readlen = (DATA_WIDTH - bitoffset) / 8;
					readlen = readlen <= len ? readlen : len;

					for (w = 0; w < readlen; w += sizeof data64) {
						unsigned int copylen = readlen - w;

						copylen = copylen <= sizeof data64 ? copylen : sizeof data64;

						data128 = rdata.read() >> (w * 8 + bitoffset);
						data64 = data128.to_uint64();

						assert(copylen <= len);
						if (be && be_len) {
							uint64_t val = data64;
							unsigned int i;

							for (i = 0; i < copylen; i++) {
								if (be[(pos + i)% be_len] == TLM_BYTE_ENABLED) {
									data[pos + i] = val & 0xff;
								}
								val >>= 8;
							}
						} else {
							memcpy(data + pos, &data64, copylen);
						}

						D(printf("Read addr=%x data64=%lx len=%d readlen=%d pos=%d w=%d sw=%d ofset=%d, copylen=%d\n",
							addr, data64, len, readlen, pos, w, streaming_width,
							(w * 8 + bitoffset), copylen));
						pos += copylen;
						len -= copylen;
					}
				}
			}
			rready.write(false);

			//
			// Translate the response and notify if not in reset.
			//
			if (resetn.read() == true) {
				// Set response
				switch (rresp.read().to_uint64()) {
				case AXI_OKAY:
					trans->set_response_status(tlm::TLM_OK_RESPONSE);
					break;
				case AXI_DECERR:
					D(printf("DECERR\n"));
					trans->set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
					break;
				case AXI_SLVERR:
					D(printf("SLVERR\n"));
					trans->set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
					break;
				default:
					SC_REPORT_ERROR(TLM2AXILITE_BRIDGE_MSG,
						"Unexpected read response detected");
					break;
				}

				tr->DoneEvent().notify();
			} else {
				assert(tr == NULL);
				wait_for_reset_release();
			}
		}
	}

	void write_data_phase()
	{
		wvalid.write(false);

		while (true) {
			Transaction *tr = wrDataFifo.read();

			prepare_wbeat(tr);

			wait_abort_on_reset(wready);

			wvalid.write(false);

			//
			// Pass the transaction to the next pipeline step if
			// not in reset.
			//
			if (resetn.read() == true) {
				wrResponses.write(tr);
			} else {
				wait_for_reset_release();
			}
		}
	}

	void write_resp_phase()
	{
		bready.write(false);

		while (true) {
			Transaction *tr;

			bready.write(true);

			wait_abort_on_reset(bvalid);
			bready.write(false);

			if (reset_asserted()) {
				wait_for_reset_release();
				continue;
			}

			tr = wrResponses.read();

			tlm::tlm_generic_payload& trans = tr->GetGP();

			// Set TLM response
			switch (bresp.read().to_uint64()) {
			case AXI_OKAY:
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
			default:
				SC_REPORT_ERROR(TLM2AXILITE_BRIDGE_MSG,
					"Unexpected read response detected");
			}

			tr->DoneEvent().notify();
		}
	}

	int prepare_wbeat(Transaction *tr)
	{
		tlm::tlm_generic_payload& trans = tr->GetGP();
		unsigned int streaming_width = trans.get_streaming_width();
		sc_dt::uint64 addr = trans.get_address();
		unsigned char *data = trans.get_data_ptr();
		unsigned int len = trans.get_data_length();
		unsigned char *be = trans.get_byte_enable_ptr();
		int be_len = trans.get_byte_enable_length();
		unsigned int bitoffset;
		sc_bv<DATA_WIDTH/8> strb = 0;
		sc_bv<DATA_WIDTH> data128 = 0;
		uint64_t t64;
		unsigned int i;
		unsigned int maxlen, wlen;

		assert(streaming_width);

		bitoffset = (addr * 8) % DATA_WIDTH;
		maxlen = (DATA_WIDTH - bitoffset) / 8;
		if (maxlen > streaming_width) {
			maxlen = streaming_width;
		}
		wlen = len <= maxlen ? len : maxlen;

		D(printf("WBEAT: wlen=%d bitoffset=%d\n", wlen, bitoffset));

		if (be && be_len) {
			strb = 0;
			for (i = 0; i < wlen; i++) {
				uint8_t b = be[i % be_len];
				if (b == TLM_BYTE_ENABLED) {
					strb[i] = true;
				}
			}
		} else {
			/* All lanes active.  */
			for (i = 0; i < wlen; i++) {
				strb[i] = true;
			}
		}
		strb.lrotate(bitoffset / 8);

		for (i = 0; i < wlen; i += sizeof(t64)) {
			unsigned int copylen = wlen - i;

			t64 = 0;
			copylen = copylen < sizeof(t64) ? copylen : sizeof(t64);
			memcpy(&t64, data + i, copylen);
			data128.range(copylen * 8 - 1 + i * 8 + bitoffset,
				i * 8 + bitoffset) = t64;
		}

		wdata.write(data128);
		D(std::cout << "strb " << strb << std::endl);
		D(std::cout << "data128 " << data128 << std::endl);

		wstrb.write(strb);
		wvalid.write(true);
		return wlen;
	}

	void reset()
	{
		while(true) {

			wait(resetn.negedge_event());

			//
			// Reset got asserted, abort all transactions
			//

			tlm2axi_clear_fifo(rdTransFifo);
			tlm2axi_clear_fifo(wrTransFifo);

			tlm2axi_clear_fifo(rdResponses);

			tlm2axi_clear_fifo(wrDataFifo);
			tlm2axi_clear_fifo(wrResponses);
		}
	}

	sc_fifo<Transaction*> rdTransFifo;
	sc_fifo<Transaction*> wrTransFifo;

	sc_fifo<Transaction*> rdResponses;

	sc_fifo<Transaction*> wrDataFifo;
	sc_fifo<Transaction*> wrResponses;

	sc_mutex m_mutex;

	tlm_aligner *aligner;
	tlm_utils::simple_initiator_socket<tlm2axilite_bridge> *proxy_init_socket;
	tlm_utils::simple_target_socket<tlm2axilite_bridge> *proxy_target_socket;
};


#undef D
#endif
