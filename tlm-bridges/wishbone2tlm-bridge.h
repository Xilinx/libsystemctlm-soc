/*
 * Wishbone to TLM-2 bridge.
 *
 * Copyright (c) 2023 Zero ASIC.
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

#ifndef WISHBONE2TLM_BRIDGE_H__
#define WISHBONE2TLM_BRIDGE_H__
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <endian.h>
#include "tlm-extensions/genattr.h"

#define D(x)

template <int ADDR_WIDTH, int DATA_WIDTH>
class wishbone2tlm_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_initiator_socket<wishbone2tlm_bridge> socket;

	SC_HAS_PROCESS(wishbone2tlm_bridge);

        enum endian {
                ENDIAN_NATIVE = 0,
                ENDIAN_LITTLE,
                ENDIAN_BIG,
        };

	sc_in<bool> clk_i;
	sc_in<bool> rst_i;

	sc_in<bool> stb_i;
	sc_out<bool> ack_o;
	sc_out<bool> err_o;
	sc_in<bool> we_i;
	sc_in<bool> cyc_i;
	sc_in<sc_bv<ADDR_WIDTH> > adr_i;
	sc_in<sc_bv<DATA_WIDTH> > dat_i;
	sc_out<sc_bv<DATA_WIDTH> > dat_o;
	sc_in<sc_bv<DATA_WIDTH/8> > sel_i;

	sc_in<sc_bv<3> > cti_i;
	sc_in<sc_bv<2> > bte_i;

	wishbone2tlm_bridge(sc_core::sc_module_name name, enum endian end = ENDIAN_NATIVE) :
		sc_module(name),
		socket("socket"),

		clk_i("clk_i"),
		rst_i("rst_i"),

		stb_i("stb_i"),
		ack_o("ack_o"),
		err_o("err_o"),
		we_i("we_i"),
		cyc_i("cyc_i"),
		adr_i("adr_i"),
		dat_i("dat_i"),
		dat_o("dat_o"),
		sel_i("sel_i"),
		cti_i("cti_i"),
		bte_i("bte_i"),
		m_end(end)
	{
		assert(DATA_WIDTH == 32 || DATA_WIDTH == 64);

		SC_THREAD(wb_thread);
	}

private:
	enum endian m_end;

	void wb_thread()
	{
		uint8_t data[DATA_WIDTH / 8];
		uint8_t be[DATA_WIDTH / 8];
		tlm::tlm_generic_payload gp;
		unsigned int pos = 0;
		unsigned int bus_width = DATA_WIDTH / 8;
		sc_time delay(SC_ZERO_TIME);

		gp.set_data_ptr(reinterpret_cast<unsigned char*>(data));
		gp.set_byte_enable_length(0);

		ack_o.write(0);

		while (true) {
			uint64_t tdata;
			int tlen = bus_width;
			int i;

			wait(clk_i.posedge_event());

			if (!stb_i.read()) {
				continue;
			}

			// Got a transaction.
			D(printf("WB2TLM: ADR_I=%llx we=%d data=%llx\n",
				adr_i.read().to_uint64(), we_i.read(),
				dat_i.read().to_uint64()));

			gp.set_address(adr_i.read().to_uint64());

			if (we_i.read()) {
				uint32_t sel = sel_i.read().to_uint64();

				gp.set_command(tlm::TLM_WRITE_COMMAND);
				tdata = dat_i.read().to_uint64();

				tdata = htoxe(tdata);
				memcpy(data, &tdata, bus_width);

				for (i = 0; i < bus_width; i++) {
					be[i] = sel & (1 << i) ? 0xff: 0x00;
				}
				gp.set_byte_enable_ptr(be);
			} else {
				gp.set_command(tlm::TLM_READ_COMMAND);
				gp.set_byte_enable_ptr(NULL);
			}

			gp.set_data_length(tlen);
			gp.set_streaming_width(tlen);
			gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
			// Propagate transaction
			D(printf("WB2TLM: Propagate GP tlen=%d\n", tlen));
			socket->b_transport(gp, delay);

			if (gp.get_response_status() != tlm::TLM_OK_RESPONSE) {
				err_o.write(1);
				goto next;
			}

			if (gp.is_read()) {
				memcpy(&tdata, data, tlen);
				tdata = htoxe(tdata);
				D(printf("WB2TLM: READ got tdata=%lx\n", tdata));
				dat_o.write(tdata);
			}
next:
			// ACK.
			ack_o.write(1);
			wait(clk_i.posedge_event());
			ack_o.write(0);
			err_o.write(0);
		}
	}

	uint64_t htobe(uint64_t tdata) {
		switch (DATA_WIDTH) {
		case 64: tdata = htobe64(tdata); break;
		case 32: tdata = htobe32(tdata); break;
		default: assert(false); /* Not supported.  */
		}
		return tdata;
	}

	uint64_t htole(uint64_t tdata) {
		switch (DATA_WIDTH) {
		case 64: tdata = htole64(tdata); break;
		case 32: tdata = htole32(tdata); break;
		default: assert(false); /* Not supported.  */
		}
		return tdata;
	}

	uint64_t htoxe(uint64_t tdata) {
		if (m_end == ENDIAN_BIG) {
			tdata = htobe(tdata);
		} else if (m_end == ENDIAN_LITTLE) {
			tdata = htole(tdata);
		}
		return tdata;
	}
};
#endif
