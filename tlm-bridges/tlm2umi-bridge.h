/*
 * TLM-2 to UMI bridge.
 *
 * Copyright (c) 2023 Zero ASIC
 * Written by Edgar E. Iglesias.
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef TLM2UMI_BRIDGE_H__
#define TLM2UMI_BRIDGE_H__
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "tlm-extensions/genattr.h"
#include "tlm-bridges/umi.h"
#include "utils/bitops.h"

#undef D
#define D(x)

template <unsigned int DATA_WIDTH>
class tlm2umi_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm2umi_bridge> socket;

	SC_HAS_PROCESS(tlm2umi_bridge);

	sc_in<bool> clk;
	sc_in<bool> rst;

	UMI_TX_PORT(req, DATA_WIDTH);
	UMI_RX_PORT(resp, DATA_WIDTH);

	tlm2umi_bridge(sc_core::sc_module_name name) :
		sc_module(name),
		socket("socket"),
		clk("clk"),
		rst("rst"),
		UMI_PORT_NAME(req),
		UMI_PORT_NAME(resp)
	{
		socket.register_b_transport(this, &tlm2umi_bridge::b_transport);
	}

private:
	sc_mutex m_mutex;

	virtual void b_transport(tlm::tlm_generic_payload& trans,
			sc_time& delay)
	{
		unsigned int len = trans.get_data_length();
		uint64_t addr = trans.get_address();
		uint8_t *buf = trans.get_data_ptr();
		genattr_extension *genattr;
		sc_bv<DATA_WIDTH> data = 0;
		unsigned int pos = 0;
		uint64_t srcaddr = 0;
		bool is_write = !trans.is_read();

		trans.get_extension(genattr);
		if (genattr) {
			srcaddr = genattr->get_master_id();
		}

		D(printf("TLM2UMI: we=%d addr=%lx len=%d\n", !trans.is_read(), addr, len));
		// Since we're going to do waits in order to wiggle the
		// UMI signals, we need to eliminate the accumulated
		// TLM delay.
		wait(delay);
		delay = SC_ZERO_TIME;
		wait(clk.posedge_event());
		resp_ready.write(1);

		m_mutex.lock();
		do {
			unsigned int tlen = std::min(DATA_WIDTH/8, len - pos);
			umi_fields f;
			uint32_t cmd;

			if (is_write) {
				sc_bv<DATA_WIDTH> tmp;
				sc_buf2bv(buf+pos, tmp, tlen * 8);
				data = tmp;
			}

			f.size = 0;
			f.len = 0;
			switch (tlen) {
				case 2: f.size = 1; break;
				case 4: f.size = 2; break;
				case 8: f.size = 3; break;
				case 16: f.size = 4; break;
				case 32: f.size = 5; break;
				case 64: f.size = 6; break;
				case 128: f.size = 7; break;
				default: f.len = tlen - 1;
			};

			f.opc = trans.is_read() ? UMI_REQ_READ : UMI_REQ_WRITE;
			f.eof = 1;
			cmd = f.pack();

			req_cmd.write(cmd);
			req_srcaddr.write(srcaddr + pos);
			req_dstaddr.write(addr + pos);
			req_data.write(data);
			req_valid.write(1);
			resp_ready.write(1);

			do {
				wait(clk.posedge_event());
			} while(!req_ready.read());
			req_valid.write(0);

			do {
				wait(clk.posedge_event());
			} while(!resp_valid.read());

			if (!is_write) {
				sc_bv2buf(buf + pos, resp_data.read(), tlen * 8);
			}
			pos += tlen;
		} while (pos < len);
		resp_ready.write(0);
		wait(clk.posedge_event());

		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		m_mutex.unlock();
	}
};
#undef D
#endif
