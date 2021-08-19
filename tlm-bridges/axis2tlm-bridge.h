/*
 * TLM-2.0 to AXIS bridge.
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

#ifndef AXIS2TLM_BRIDGE_H__
#define AXIS2TLM_BRIDGE_H__
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "tlm-bridges/amba.h"
#include "tlm-extensions/genattr.h"

#define D(x)

template <int DATA_WIDTH, int USER_WIDTH = 1>
class axis2tlm_bridge
: public sc_core::sc_module,
	public axi_common
{
public:
	tlm_utils::simple_initiator_socket<axis2tlm_bridge> socket;

	SC_HAS_PROCESS(axis2tlm_bridge);

	sc_in<bool> clk;
	sc_in<bool> resetn;

	/* Write data channel.  */
	sc_in<bool> tvalid;
	sc_out<bool> tready;
	sc_in<sc_bv<DATA_WIDTH> > tdata;
	sc_in<sc_bv<DATA_WIDTH/8> > tstrb;
	sc_in<AXISignal(USER_WIDTH) > tuser;
	sc_in<bool> tlast;

	axis2tlm_bridge(sc_core::sc_module_name name,
				bool aligner_enable=true) :
		sc_module(name),
		axi_common(this),
		socket("tgt_socket"),

		clk("clk"),
		resetn("resetn"),

		tvalid("tvalid"),
		tready("tready"),
		tdata("tdata"),
		tstrb("tstrb"),
		tuser("tuser"),
		tlast("tlast")
	{
		SC_THREAD(axis_thread);
	}

private:
	enum { MAX_DATA = 4*1024 };

	unsigned int get_last_byte()
	{
		unsigned int bus_width = DATA_WIDTH / 8;
		unsigned int last_byte = 0;
		unsigned int i;

		for (i = 0; i < bus_width; i++) {
			if (tstrb.read().bit(i)) {
				last_byte = i;
			}
		}

		return last_byte;
	}

	void run_tlm(tlm::tlm_generic_payload& gp, unsigned int &pos)
	{
		sc_time delay(SC_ZERO_TIME);

		gp.set_data_length(pos);
		gp.set_streaming_width(pos);
		gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		socket->b_transport(gp, delay);

		tready.write(false);
		wait(delay);
		tready.write(true);

		pos = 0;
	}

	void axis_thread()
	{
		uint8_t data[MAX_DATA];
		tlm::tlm_generic_payload gp;
		unsigned int pos = 0;
		unsigned int bus_width = DATA_WIDTH / 8;
		genattr_extension *genattr = new genattr_extension();

		gp.set_command(tlm::TLM_WRITE_COMMAND);
		gp.set_address(0);
		gp.set_data_ptr(reinterpret_cast<unsigned char*>(data));
		gp.set_byte_enable_ptr(NULL);
		gp.set_byte_enable_length(0);

		gp.set_extension(genattr);

		tready.write(true);

		while (true) {

			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				wait_for_reset_release();
				continue;
			}

			if (tvalid.read()) {
				unsigned int last_byte = get_last_byte();
				unsigned int i;

				for (i = 0; i < bus_width; i++) {
					if (tstrb.read().bit(i)) {
						unsigned int firstbit = i * 8;
						unsigned int lastbit = firstbit + 8 - 1;

						data[pos++] =
							tdata.read().range(lastbit, firstbit).to_uint();

						if (pos == MAX_DATA) {
							if (tlast.read() && i == last_byte) {
								genattr->set_eop();
							}

							run_tlm(gp, pos);

							genattr->set_eop(false);
						}
					}
				}

				if (tlast.read() && pos > 0) {
					genattr->set_eop();

					run_tlm(gp, pos);

					genattr->set_eop(false);
				}
			}
		}
	}
};

#endif
