/*
 * TRI to TLM-2.0 bridge.
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

#ifndef TRI2TLM_BRIDGE_H__
#define TRI2TLM_BRIDGE_H__

#include "tlm-bridges/axi2tlm-bridge.h"

#define L15_AMO_OP_WIDTH 4
#define PHY_ADDR_WIDTH          40

class tri2tlm_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_initiator_socket<tri2tlm_bridge> socket;

	sc_in<bool> clk;
	sc_in<bool> resetn;

	//--- Pico -> L1.5
	sc_out<bool>                     l15_transducer_ack;
	sc_out<bool>                     l15_transducer_header_ack;

	// outputs pico uses
	sc_in<sc_bv<5> >               transducer_l15_rqtype;
	sc_in<sc_bv<L15_AMO_OP_WIDTH> >  	transducer_l15_amo_op;
	sc_in<sc_bv<3> >               transducer_l15_size;
	sc_in<bool>                    transducer_l15_val;
	sc_in<sc_bv<PHY_ADDR_WIDTH> >  transducer_l15_address;
	sc_in<sc_bv<64> >              transducer_l15_data;
	sc_in<bool>                    transducer_l15_nc;


	// outputs pico doesn't use
	//output [0:0]                    transducer_l15_threadid,
	sc_in<bool>                    transducer_l15_threadid;
	sc_in<bool>                    transducer_l15_prefetch;
	sc_in<bool>                    transducer_l15_invalidate_cacheline;
	sc_in<bool>                    transducer_l15_blockstore;
	sc_in<bool>                    transducer_l15_blockinitstore;
	sc_in<sc_bv<2> >               transducer_l15_l1rplway;
	sc_in<sc_bv<64> >              transducer_l15_data_next_entry;
	sc_in<sc_bv<32> >              transducer_l15_csm_data;

	//--- L1.5 -> Pico
	sc_out<bool>                     l15_transducer_val;
	sc_out<sc_bv<4> >                l15_transducer_returntype;

	sc_out<sc_bv<64> >               l15_transducer_data_0;
	sc_out<sc_bv<64> >               l15_transducer_data_1;

	sc_in<bool>                    transducer_l15_req_ack;

	SC_HAS_PROCESS(tri2tlm_bridge);

	tri2tlm_bridge(sc_core::sc_module_name name) :
		sc_module(name),
		socket("init-socket"),

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
		SC_THREAD(rx_thread);
	}

	class Transaction
	{
	public:
		Transaction(tlm::tlm_command cmd,
				uint64_t address) :
			m_gp(new tlm::tlm_generic_payload()),
			m_delay(SC_ZERO_TIME)
		{
			const unsigned int len = 8;  // only support 8 bytes at the moment
			uint8_t *data = new uint8_t[len];

			m_gp->set_command(cmd);
			m_gp->set_address(address);
			m_gp->set_data_length(len);
			m_gp->set_data_ptr(reinterpret_cast<unsigned char*>(data));

			m_gp->set_byte_enable_ptr(NULL);
			m_gp->set_byte_enable_length(0);

			m_gp->set_streaming_width(len);
			m_gp->set_dmi_allowed(false);
			m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
		}

		~Transaction()
		{
			delete[] m_gp->get_data_ptr();

			if (m_gp->get_byte_enable_ptr()) {
				delete[] m_gp->get_byte_enable_ptr();
			}

			delete m_gp; // Also deletes m_genattr
		}

		tlm::tlm_generic_payload& GetGP()
		{
			return *m_gp;
		}

		sc_time& GetDelay()
		{
			return m_delay;
		}

		template<typename T>
		void GetData(T& data)
		{
			unsigned char *gp_data = m_gp->get_data_ptr();

			// All data accesses use the full width of the data bus.
			for (unsigned int i = 0; i < 8; i++) {
				int firstbit = i*8;
				int lastbit = firstbit + 8-1;

				data.range(lastbit, firstbit) = gp_data[i];
			}
		}

		template<typename T1>
		void FillData(T1& wdata)
		{
			unsigned char *gp_data = m_gp->get_data_ptr();
			unsigned int len = 8;

			for (unsigned int i = 0; i < len; i++) {
				int firstbit = i * 8;
				int lastbit = firstbit + 8 - 1;

				gp_data[i] =
					wdata.read().range(lastbit, firstbit).to_uint();
			}
		}
	private:
		tlm::tlm_generic_payload *m_gp;
		sc_time  m_delay;
	};

	void run_write()
	{
		Transaction tr(tlm::TLM_WRITE_COMMAND,
				transducer_l15_address.read().to_uint64());

		tr.FillData(transducer_l15_data);

		l15_transducer_ack.write(true);
		wait(clk.posedge_event());
		l15_transducer_ack.write(false);

		socket->b_transport(tr.GetGP(), tr.GetDelay());

		l15_transducer_val.write(true);
		while (transducer_l15_req_ack.read() == false) {
			wait(clk.posedge_event());
		}
		l15_transducer_val.write(false);
	}

	void run_read()
	{
		sc_bv<64> data;

		Transaction tr(tlm::TLM_READ_COMMAND,
				transducer_l15_address.read().to_uint64());

		l15_transducer_ack.write(true);
		wait(clk.posedge_event());
		l15_transducer_ack.write(false);

		socket->b_transport(tr.GetGP(), tr.GetDelay());

		tr.GetData(data);

		l15_transducer_val.write(true);
		l15_transducer_data_0.write(data);

		while (transducer_l15_req_ack.read() == false) {
			wait(clk.posedge_event());
		}

		l15_transducer_val.write(false);
	}

	void rx_thread()
	{
		while (true) {
			wait(clk.posedge_event());

			if (transducer_l15_val.read()) {
				if (transducer_l15_rqtype.read().to_uint() > 0) {
					run_write();
				} else {
					run_read();
				}
			}
		}
	}
};
#endif
