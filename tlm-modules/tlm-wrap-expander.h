/*
 * Copyright (c) 2018 Xilinx Inc.
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
 * References:
 *
 *
 * [1] AMBA AXI and ACE Protocol Specification, ARM IHI 0022D, ID102711
 *
 */

#ifndef TLM_WE_H__
#define TLM_WE_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/genattr.h"

class tlm_wrap_expander : public sc_core::sc_module
{
public:
	tlm_utils::simple_initiator_socket<tlm_wrap_expander> init_socket;
	tlm_utils::simple_target_socket<tlm_wrap_expander> target_socket;

	tlm_wrap_expander(sc_core::sc_module_name name, bool generate_two_gps) :
		sc_core::sc_module(name),
		m_generate_two_gps(generate_two_gps)
	{
		target_socket.register_b_transport(this, &tlm_wrap_expander::b_transport);
	}

private:
	bool is_wrap(tlm::tlm_generic_payload& gp)
	{
		genattr_extension *genattr;

		gp.get_extension(genattr);
		if (genattr) {
			return genattr->get_wrap();
		}

		return false;
	}

	virtual void b_transport(tlm::tlm_generic_payload& gp, sc_time& delay)
	{
		if (is_wrap(gp)) {
			unsigned int be_len = gp.get_byte_enable_length();
			unsigned char *data = gp.get_data_ptr();
			uint64_t len = gp.get_data_length();
			uint64_t addr = gp.get_address();
			unsigned char *be = NULL;
			uint64_t wrap_boundary;
			unsigned int pos;

			wrap_boundary = (addr / len) * len;

			// Start byte position in the wrap
			pos = addr - wrap_boundary;

			if (be_len) {
				be = new uint8_t[be_len*2];
				if (!be) {
					gp.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
					return;
				}
				// Copy two consecutive copies so we can do a sliding window.
				memcpy(be, gp.get_byte_enable_ptr(), be_len);
				memcpy(be + be_len, be, be_len);
			}

			if (m_generate_two_gps && pos != 0) {
				//
				// Generate two gps (first one is from
				// pos -> len and second one from the
				// wrap_boundary -> pos)
				//
				tlm::tlm_generic_payload tmp_gp;
				uint64_t len1 = len - pos;

				//
				// Setup first gp
				//
				tmp_gp.deep_copy_from(gp);
				tmp_gp.set_address(addr);
				tmp_gp.set_data_ptr(data);
				tmp_gp.set_data_length(len1);

				if (be_len) {
					tmp_gp.set_byte_enable_ptr(be);
				}

				tmp_gp.set_response_status( tlm::TLM_INCOMPLETE_RESPONSE );

				// First gp
				init_socket->b_transport(tmp_gp, delay);

				if (tmp_gp.get_response_status() == tlm::TLM_OK_RESPONSE) {
					//
					// Setup second gp
					//
					uint64_t len2 = pos;

					tmp_gp.set_address(wrap_boundary);
					tmp_gp.set_data_ptr(data + len1);
					tmp_gp.set_data_length(len2);

					if (be_len) {
						tmp_gp.set_byte_enable_ptr(be + (len1 % be_len));
					}

					tmp_gp.set_response_status( tlm::TLM_INCOMPLETE_RESPONSE );

					// Second gp
					init_socket->b_transport(tmp_gp, delay);

					//
					// Since the response of the first gp
					// was ok we can just propagate the
					// second gps response
					//
					gp.set_response_status(tmp_gp.get_response_status());
				}  else {
					//
					// Propagate the first gp's error response
					//
					gp.set_response_status(tmp_gp.get_response_status());
				}
			} else {
				// Always wrap_boundary here
				gp.set_address(wrap_boundary);

				init_socket->b_transport(gp, delay);
			}

			delete[] be;

		} else {
			//
			// Just propagate the gp if it is not a wrapping burst.
			//
			init_socket->b_transport(gp, delay);
		}
	}

	bool m_generate_two_gps;
};
#endif
