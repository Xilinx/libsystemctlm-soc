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
#ifndef TLM_ALIGNER_H__
#define TLM_ALIGNER_H__

#include <stdint.h>

#define D(x)

#ifndef MIN
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

/*
 * This module is a generic alignment proxy module that will take any TLM
 * generic payload and chop it up into multiple GP's in order to satisfy
 * a configurable set of alignment constrains.
 */
class tlm_aligner : public sc_core::sc_module
{
public:
	class IValidator
	{
	public:
		virtual bool validate(uint64_t t_addr,
					unsigned int t_len,
					unsigned int streaming_width) = 0;
	};

	tlm_utils::simple_initiator_socket<tlm_aligner> init_socket;
	tlm_utils::simple_target_socket<tlm_aligner> target_socket;

	tlm_aligner(sc_core::sc_module_name name,
			uint32_t bus_width,
			uint64_t max_len = 256 * 1024,
			uint64_t max_address_boundary = 4 * 1024,
			bool do_natural_alignment = false,
			IValidator *validator = NULL) :
		bus_width(bus_width),
		max_len(max_len),
		max_address_boundary(max_address_boundary),
		do_natural_alignment(do_natural_alignment),
		m_validator(validator)
	{
		target_socket.register_b_transport(this, &tlm_aligner::b_transport);
	}

	void set_bus_width(uint32_t w) {
		bus_width = w;
	}

	uint32_t get_bus_width(void) {
		return bus_width;
	}

	void set_max_len(uint64_t len) {
		max_len = len;
	}

	uint64_t get_max_len(void) {
		return max_len;
	}

private:
	// Bus with in bits.
	uint32_t bus_width;
	// Maximum length of transactions in bytes.
	uint64_t max_len;
	// Maximum size of addressing boundary in bytes.
	// If a transaction crosses this boundary, it will get chopped
	// even if it's properly align. For example to support the
	// 4K addressing boundary in AXI.
	uint64_t max_address_boundary;
	bool do_natural_alignment;
	IValidator *m_validator;

	uint64_t compute_natural_alignment(uint64_t addr)
	{
		if (addr == 0)
			return UINT64_MAX;

		// Negation first does a logical complement flipping the
		// lower zero bits to ones. Then it adds one thus clearing
		// them all again and setting the first non-zero bit. All
		// other bits get cleared by the AND.
		return addr & (-addr);
	}

	uint64_t compute_max_addr_range(uint64_t addr, uint64_t natural_alignment)
	{
		uint64_t len = max_len;

		len = MIN(len, max_address_boundary - (addr % max_address_boundary));
		if (do_natural_alignment) {
			len = MIN(len, natural_alignment - (addr % natural_alignment));
		}
		return len;
	}

	virtual void b_transport(tlm::tlm_generic_payload& trans,
				sc_time& delay)
	{
		unsigned int be_len = trans.get_byte_enable_length();
		unsigned char *data = trans.get_data_ptr();
		unsigned int len = trans.get_data_length();
		unsigned int streaming_width = trans.get_streaming_width();
		sc_dt::uint64 addr = trans.get_address();
		tlm::tlm_generic_payload gp;
		uint64_t natural_alignment;
		unsigned char *be = NULL;
		unsigned int pos = 0;
		uint64_t addr_range;

		natural_alignment = compute_natural_alignment(addr);
		addr_range = compute_max_addr_range(addr, natural_alignment);

		// FIXME: Streaming width is mandatory according to spec but
		// we don't seem to set it always.
		if (streaming_width == 0) {
			streaming_width = len;
		}

		if ((!do_natural_alignment || addr % natural_alignment == 0) &&
		     len < max_len &&
		     len == addr_range &&
		     streaming_width == len) {
			// Fast path, just forward the transaction.
			init_socket->b_transport(trans, delay);
			return;
		}

		// Since data and byte_enable ptrs remain NULL, nothing gets copied.
		// This is true with acceleras Open Source implementation, but is it
		// true by spec?
		gp.deep_copy_from(trans);

		if (be_len) {
			be = new uint8_t[be_len * 2];
			if (!be) {
				trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
				return;
			}
			// Copy two consecutive copies so we can do a sliding window.
			memcpy(be, trans.get_byte_enable_ptr(), be_len);
			memcpy(be + be_len, be, be_len);
		}

		// Need to chop this one up into multiple transactions.
		while (pos < len) {
			uint64_t t_addr = addr + (pos % streaming_width);
			unsigned int t_len;

			natural_alignment = compute_natural_alignment(t_addr);
			addr_range = compute_max_addr_range(t_addr, natural_alignment);

			t_len = MIN(len - pos, addr_range);
			// Don't cross streaming_width boundary unless we're aligned.
			if (pos % streaming_width != 0) {
				// Make a single beat to align with streaming width
				t_len = MIN(t_len, streaming_width - (pos % streaming_width));
				gp.set_streaming_width(t_len);
			} else if (streaming_width != len) {
				if (m_validator &&
					m_validator->validate(t_addr, t_len, streaming_width)) {
					gp.set_streaming_width(streaming_width);
				} else {
					unsigned int bus_width_bytes = MIN(bus_width / 8, streaming_width);

					// Chop up into multiple beats.
					t_len = MIN(t_len, bus_width_bytes);
					gp.set_streaming_width(t_len);
				}
			}

			assert(t_len > 0);
			assert(t_len <= max_len);
			gp.set_address(t_addr);
			gp.set_data_ptr(data + pos);
			gp.set_data_length(t_len);

			if (be_len) {
				// Sliding window of byte-enables.
				gp.set_byte_enable_ptr(be + (pos % be_len));
			}

			init_socket->b_transport(gp, delay);
			if (gp.get_response_status() != tlm::TLM_OK_RESPONSE) {
				break;
			}

			pos += t_len;
		}
		// Restore data ptr from start-pos for update_from_original()
		gp.set_data_ptr(trans.get_data_ptr());
		trans.update_original_from(gp);
		delete[] be;
	}
};
#endif
