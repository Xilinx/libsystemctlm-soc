/*
 * Copyright (c) 2018 Xilinx Inc.
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
#ifndef TLM_SPLITTER_H__
#define TLM_SPLITTER_H__

#include <stdint.h>
#include "utils/hexdump.h"

#define TLM_SPLITTER_ERROR "TLM Splitter Error"

/*
 * This module is a TLM interconnect splitter. Any transactions ingressing
 * on our slave port will be replicated on all the outgoing master ports.
 *
 * Optionally, the module can verify that all data responses for reads match.
 */
template<unsigned int NR_INIT_SOCKETS>
class tlm_splitter : public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm_splitter> target_socket;
	tlm_utils::simple_initiator_socket_tagged<tlm_splitter> *i_sk[NR_INIT_SOCKETS];

	tlm_splitter(sc_core::sc_module_name name, bool do_check_read_data = false) :
		do_check_read_data(do_check_read_data)
	{
		char sk_name[64];
		unsigned int i;

		for (i = 0; i < NR_INIT_SOCKETS; i++) {
			sprintf(sk_name, "init_socket_%d", i);
			i_sk[i] = new tlm_utils::simple_initiator_socket_tagged<tlm_splitter>(sk_name);
		}
		target_socket.register_b_transport(this, &tlm_splitter::b_transport);
	}
private:
	bool do_check_read_data;

	virtual void b_transport(tlm::tlm_generic_payload &trans, sc_time &delay) {
		unsigned char *data = trans.get_data_ptr();
		unsigned int len = trans.get_data_length();
		tlm::tlm_response_status resp_status = tlm::TLM_OK_RESPONSE;
		uint8_t *ref_data = NULL;
		unsigned int i;

		if (do_check_read_data && trans.is_read()) {
			ref_data = new uint8_t[len];
		}

		for (i = 0; i < NR_INIT_SOCKETS; i++) {
			(*i_sk[i])->b_transport(trans, delay);

			if (trans.get_response_status() != tlm::TLM_OK_RESPONSE) {
				resp_status = trans.get_response_status();
			}

			if (do_check_read_data && trans.is_read()) {
				if (i == 0) {
					memcpy(ref_data, data, len);
				} else {
					if (memcmp(ref_data, data, len)) {
						hexdump("ref-data", ref_data, len);
						hexdump("data", data, len);
						SC_REPORT_ERROR(TLM_SPLITTER_ERROR,
							"Read-data missmatch");
					}
				}
			}
		}
		trans.set_response_status(resp_status);
		delete[] ref_data;
	}
};
#endif
