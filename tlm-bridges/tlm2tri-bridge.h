/*
 * TLM-2.0 to TRI bridge.
 *
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Francisco Iglesias.
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

#ifndef TLM2TRI_BRIDGE_H__
#define TLM2TRI_BRIDGE_H__

#include "tlm-bridges/tlm2axi-bridge.h"

#define L15_AMO_OP_WIDTH 4
#define PHY_ADDR_WIDTH          40

class tlm2tri_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm2tri_bridge> tgt_socket;

	sc_in<bool> clk;
	sc_in<bool> resetn;

	//--- Pico -> L1.5
	sc_in<bool>                     l15_transducer_ack;
	sc_in<bool>                     l15_transducer_header_ack;

	// outputs pico uses
	sc_out<sc_bv<5> >               transducer_l15_rqtype;
	sc_out<sc_bv<L15_AMO_OP_WIDTH> >  	transducer_l15_amo_op;
	sc_out<sc_bv<3> >               transducer_l15_size;
	sc_out<bool>                    transducer_l15_val;
	sc_out<sc_bv<PHY_ADDR_WIDTH> >  transducer_l15_address;
	sc_out<sc_bv<64> >              transducer_l15_data;
	sc_out<bool>                    transducer_l15_nc;


	// outputs pico doesn't use
	//output [0:0]                    transducer_l15_threadid,
	sc_out<bool>                    transducer_l15_threadid;
	sc_out<bool>                    transducer_l15_prefetch;
	sc_out<bool>                    transducer_l15_invalidate_cacheline;
	sc_out<bool>                    transducer_l15_blockstore;
	sc_out<bool>                    transducer_l15_blockinitstore;
	sc_out<sc_bv<2> >               transducer_l15_l1rplway;
	sc_out<sc_bv<64> >              transducer_l15_data_next_entry;
	sc_out<sc_bv<33> >              transducer_l15_csm_data;

	//--- L1.5 -> Pico
	sc_in<bool>                     l15_transducer_val;
	sc_in<sc_bv<4> >                l15_transducer_returntype;

	sc_in<sc_bv<64> >               l15_transducer_data_0;
	sc_in<sc_bv<64> >               l15_transducer_data_1;

	sc_out<bool>                    transducer_l15_req_ack;

	SC_HAS_PROCESS(tlm2tri_bridge);

	tlm2tri_bridge(sc_core::sc_module_name name) :
		sc_module(name),
		tgt_socket("target-socket"),

		l15_transducer_ack("l15_transducer_ack"),
		l15_transducer_header_ack("l15_transducer_header_ack"),

		transducer_l15_rqtype("transducer_l15_rqtype"),
		transducer_l15_amo_op("transducer_l15_amo_op"),
		transducer_l15_size("transducer_l15_size"),
		transducer_l15_val("transducer_l15_val"),
		transducer_l15_address("transducer_l15_address"),
		transducer_l15_data("transducer_l15_data"),
		transducer_l15_nc("transducer_l15_nc"),


		transducer_l15_threadid("transducer_l15_threadid"),
		transducer_l15_prefetch("transducer_l15_prefetch"),
		transducer_l15_invalidate_cacheline("transducer_l15_invalidate_cacheline"),
		transducer_l15_blockstore("transducer_l15_blockstore"),
		transducer_l15_blockinitstore("transducer_l15_blockinitstore"),
		transducer_l15_l1rplway("transducer_l15_l1rplway"),
		transducer_l15_data_next_entry("transducer_l15_data_next_entry"),
		transducer_l15_csm_data("transducer_l15_csm_data"),

		l15_transducer_val("l15_transducer_val"),
		l15_transducer_returntype("l15_transducer_returntype"),

		l15_transducer_data_0("l15_transducer_data_0"),
		l15_transducer_data_1("l15_transducer_data_1"),

		transducer_l15_req_ack("transducer_l15_req_ack")
	{
		tgt_socket.register_b_transport(
				this, &tlm2tri_bridge::b_transport);
	}

	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		// Since we're going todo waits in order to wiggle the
		// AXI signals, we need to eliminate the accumulated
		// TLM delay.
		wait(delay, resetn.negedge_event());
		delay = SC_ZERO_TIME;


		if (trans.is_read()) {
			uint8_t *data = trans.get_data_ptr();
			unsigned int len = trans.get_data_length();

			if (len > 8) {
				len = 8;
			}

			transducer_l15_rqtype.write(0); // LOAD_RQ
			transducer_l15_amo_op.write(0);
			transducer_l15_size.write(3); // 8 bytes
			transducer_l15_val.write(true);
			transducer_l15_address.write(trans.get_address());
			transducer_l15_nc.write(false);

			while (l15_transducer_ack.read() == false) {
				wait(clk.posedge_event());
			}

			transducer_l15_val.write(false);

			while (l15_transducer_val.read() == false) {
				wait(clk.posedge_event());
			}

			for (unsigned int i = 0; i < len; i++) {
				int firstbit = i * 8;
				int lastbit = firstbit + 8 - 1;

				data[i] = l15_transducer_data_0.read().
						range(lastbit, firstbit).to_uint();
			}

			transducer_l15_req_ack.write(true);
			wait(clk.posedge_event());
			transducer_l15_req_ack.write(false);

			trans.set_response_status(tlm::TLM_OK_RESPONSE);

		} else if (trans.is_write()){
			unsigned int len = trans.get_data_length();
			uint8_t *gp_data = trans.get_data_ptr();
			sc_bv<64> data;

			if (len > 8) {
				len = 8;
			}

			transducer_l15_rqtype.write(1); // STORE_RQ
			transducer_l15_amo_op.write(0);
			transducer_l15_size.write(3); // 8 bytes
			transducer_l15_val.write(true);
			transducer_l15_address.write(trans.get_address());
			transducer_l15_nc.write(false);

			for (unsigned int i = 0; i < len; i++) {
				int firstbit = i*8;
				int lastbit = firstbit + 8-1;

				data.range(lastbit, firstbit) = gp_data[i];
			}

			transducer_l15_data.write(data);

			while (l15_transducer_ack.read() == false) {
				wait(clk.posedge_event());
			}

			transducer_l15_val.write(false);

			while (l15_transducer_val.read() == false) {
				wait(clk.posedge_event());
			}

			transducer_l15_req_ack.write(true);
			wait(clk.posedge_event());
			transducer_l15_req_ack.write(false);

			trans.set_response_status(tlm::TLM_OK_RESPONSE);
		}
	}
};
#endif
