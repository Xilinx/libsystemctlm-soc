/*
 * UMI to TLM-2 bridge.
 *
 * Copyright (c) 2024 Zero ASIC.
 * Written by Edgar E. Iglesias.
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef UMI2TLM_BRIDGE_H__
#define UMI2TLM_BRIDGE_H__
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "tlm-extensions/genattr.h"
#include "tlm-bridges/umi.h"

#undef D
#define D(x)

template <unsigned int DATA_WIDTH>
class umi2tlm_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_initiator_socket<umi2tlm_bridge> socket;

	SC_HAS_PROCESS(umi2tlm_bridge);

	sc_in<bool> clk;
	sc_in<bool> rst;

	UMI_RX_PORT(req, DATA_WIDTH);
	UMI_TX_PORT(resp, DATA_WIDTH);

	umi2tlm_bridge(sc_core::sc_module_name name) :
		sc_module(name),
		socket("socket"),

		clk("clk"),
		rst("rst"),

		UMI_PORT_NAME(req),
		UMI_PORT_NAME(resp)
		{
			SC_THREAD(umi_thread);
		}

private:
	uint8_t data[1024];
	umi_fields f_tx;

	void send_resp(uint64_t sa, uint64_t da) {
		resp_cmd.write(f_tx.pack());
		resp_srcaddr.write(sa);
		resp_dstaddr.write(da);

		resp_valid.write(1);
		do {
			wait(clk.posedge_event());
		} while (!resp_ready.read());
		resp_valid.write(0);
		wait(clk.posedge_event());
	}

	void umi_thread()
	{
		genattr_extension *genattr = new genattr_extension();
		tlm::tlm_generic_payload gp;
		sc_time delay(SC_ZERO_TIME);
		unsigned int pos;

		gp.set_data_ptr(reinterpret_cast<unsigned char*>(data));
		gp.set_byte_enable_length(0);
		req_ready.write(1);

		while (true) {
			tlm::tlm_command gp_cmd;
			uint64_t sa, da;
			uint32_t cmd;
			unsigned int nbytes;
			unsigned int tlen;
			umi_fields f;
			sc_bv<DATA_WIDTH> data_bv;
			unsigned int i;

			wait(clk.posedge_event());
			if (!req_valid.read()) {
				continue;
			}

			// Got a transaction.
			sa = req_srcaddr.read().to_uint64();
			da = req_dstaddr.read().to_uint64();
			cmd = req_cmd.read().to_uint64();

			f.unpack(cmd);
			nbytes = (f.len + 1) << f.size;

			D(printf("UMI2TLM: %s addr=%lx -> %lx cmd=%x opc=%d size=%d len=%d %dB\n",
						umi_opc_str(f.opc),
						sa, da, cmd, f.opc, f.size, f.len, nbytes));

			genattr->set_master_id(sa);
			gp.set_extension(genattr);
			gp.set_address(da);
			switch (f.opc) {
				case UMI_REQ_READ:  gp_cmd = tlm::TLM_READ_COMMAND; break;
				case UMI_REQ_POSTED: /* Fall through.  */
				case UMI_REQ_WRITE: gp_cmd = tlm::TLM_WRITE_COMMAND; break;
				default: assert(0);
			};
			gp.set_command(gp_cmd);
			gp.set_data_length(nbytes);
			gp.set_streaming_width(nbytes);
			assert(nbytes <= sizeof data);

			// Copy data.
			data_bv = req_data.read();
			if (gp_cmd == tlm::TLM_WRITE_COMMAND) {
				for (i = 0; i < nbytes; i++) {
					data[i] = data_bv.range(i * 8 + 8 - 1, i * 8).to_uint();
				}
			}
			socket->b_transport(gp, delay);

			// back-pressure until we're done.
			req_ready.write(0);
			wait(clk.posedge_event());

			// Response.
			if (gp_cmd == tlm::TLM_READ_COMMAND) {
				// Write response is needed.
				f_tx = f;
				f_tx.opc = UMI_RESP_READ;
				f_tx.size = 0;

				/* Send multiple responses.  */
				pos = 0;
				do {
					tlen = std::min(DATA_WIDTH/8, nbytes - pos);
					f_tx.len = tlen - 1;

					for (i = 0; i < tlen; i++) {
						data_bv.range(i * 8 + 8 - 1, i * 8) = data[pos + i];
					}
					resp_data.write(data_bv);

					f_tx.eof = 1;
					f_tx.eom = (pos + tlen) == nbytes;
					send_resp(da, sa);

					D(printf("UMI: %s %lx -> %lx pos=%d nbytes=%d eom=%d\n",
								umi_opc_str(f_tx.opc),
								da, sa,
								pos, nbytes, f_tx.eom));

					// Advance state.
					pos += tlen;
					sa += tlen;
					da += tlen;
				} while (pos < nbytes);
			} else {
				pos = nbytes;
				if (f.opc == UMI_REQ_POSTED) {
					// No ACK should be sent.
				} else {
					assert(f.opc == UMI_REQ_WRITE);

					// Write response is needed.
					f_tx = f;
					f_tx.opc = UMI_RESP_WRITE;
					f_tx.eom = 1;
					send_resp(da, sa);
					// done
				}
			}
			req_ready.write(1);
		}
	}
};
#undef D
#endif
