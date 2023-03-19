/*
 * TLM-2 to WishBone bridge.
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

#ifndef TLM2WISHBONE_BRIDGE_H__
#define TLM2WISHBONE_BRIDGE_H__
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "tlm-extensions/genattr.h"

#undef D
#define D(x)

template <int ADDR_WIDTH, int DATA_WIDTH>
class tlm2wishbone_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm2wishbone_bridge> socket;

	SC_HAS_PROCESS(tlm2wishbone_bridge);

	enum endian {
		ENDIAN_NATIVE = 0,
		ENDIAN_LITTLE,
		ENDIAN_BIG,
	};

	sc_in<bool> clk_i;
	sc_in<bool> rst_i;

	sc_out<bool> stb_o;
	sc_in<bool> ack_i;
	sc_out<bool> we_o;
	sc_out<bool> cyc_o;
	sc_out<sc_bv<ADDR_WIDTH> > adr_o;
	sc_in<sc_bv<DATA_WIDTH> > dat_i;
	sc_out<sc_bv<DATA_WIDTH> > dat_o;
	sc_out<sc_bv<DATA_WIDTH/8> > sel_o;

	sc_mutex m_mutex;

	tlm2wishbone_bridge(sc_core::sc_module_name name, enum endian end = ENDIAN_NATIVE) :
		sc_module(name),
		socket("socket"),

		clk_i("clk_i"),
		rst_i("rst_i"),

		stb_o("stb_o"),
		ack_i("ack_i"),
		we_o("we_o"),
		cyc_o("cyc_o"),
		adr_o("adr_i"),
		dat_i("dat_i"),
		dat_o("dat_o"),
		sel_o("sel_o"),
		m_end(end)
	{
		assert(DATA_WIDTH == 32 || DATA_WIDTH == 64);
		// Only native (i.e host) endianness is supported.
		assert(end == ENDIAN_NATIVE);

		socket.register_b_transport(this, &tlm2wishbone_bridge::b_transport);
	}

private:
	enum endian m_end;

	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		unsigned int bus_width = DATA_WIDTH / 8;
		uint64_t addr = trans.get_address();
		uint8_t *data = trans.get_data_ptr();
		unsigned int len = trans.get_data_length();
		unsigned int pos = 0;

		D(printf("WB: we=%d addr=%lx len=%d\n", !trans.is_read(), addr, len));
		// Since we're going to do waits in order to wiggle the
		// AXI signals, we need to eliminate the accumulated
		// TLM delay.
		wait(delay);
		delay = SC_ZERO_TIME;
		wait(clk_i.posedge_event());

		m_mutex.lock();
		do {
			int tlen = std::min(bus_width, len);
			uint64_t tdata = 0;
			uint32_t byte_en;

			byte_en = (1 << tlen) - 1;
			byte_en <<= (addr + pos) % bus_width;

			adr_o.write(addr + pos);
			stb_o.write(1);
			sel_o.write((1 << tlen) - 1);
			cyc_o.write(1);

			we_o.write(!trans.is_read());
			if (!trans.is_read()) {
				memcpy(&tdata, data + pos, tlen);
				tdata <<= ((addr + pos) % bus_width) * 8;
				dat_o.write(tdata);
			}

			do {
				wait(clk_i.posedge_event());
				if (trans.is_read()) {
					tdata = dat_i.read().to_uint64();
					D(printf("Got DATA=%lx (shift=%ld)\n", tdata, addr % bus_width));
				}
			} while (!ack_i.read());

			if (trans.is_read()) {
				tdata >>= (addr % bus_width) * 8;
				D(printf("READ: tdata=%lx tlen=%d\n", tdata, tlen));
				memcpy(data + pos, &tdata, tlen);
			}

			pos += tlen;
		} while (pos < len);

		stb_o.write(0);
		we_o.write(0);
		adr_o.write(0);
		dat_o.write(0);
		cyc_o.write(0);

		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		m_mutex.unlock();
	}
};
#undef D
#endif
