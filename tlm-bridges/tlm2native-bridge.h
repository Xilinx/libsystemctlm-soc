/*
 * TLM to Native bridge.
 *
 * Copyright (c) 2019 Xilinx Inc.
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
#ifndef TLM2NATIVE_BRIDGE_H__
#define TLM2NATIVE_BRIDGE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

class tlm2native_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm2native_bridge > target_socket;

	SC_HAS_PROCESS(tlm2native_bridge);
	tlm2native_bridge(sc_module_name name,
			uint8_t *mem = NULL, uint64_t size = 0,
			sc_time latency = SC_ZERO_TIME);

private:
	virtual void b_transport(tlm::tlm_generic_payload& trans,
			sc_time& delay);
	virtual bool get_direct_mem_ptr(tlm::tlm_generic_payload& trans,
			tlm::tlm_dmi& dmi_data);
	virtual unsigned int transport_dbg(tlm::tlm_generic_payload& trans);


	uint8_t *mem;
	uint64_t size;
	sc_time latency;
};

tlm2native_bridge::tlm2native_bridge(sc_module_name name,
				     uint8_t *mem, uint64_t size,
				     sc_time latency) :
	sc_module(name),
	target_socket("target_socket"),
	mem(mem),
	size(size),
	latency(latency)
{
	target_socket.register_b_transport(this,
			&tlm2native_bridge::b_transport);
	target_socket.register_transport_dbg(this,
			&tlm2native_bridge::transport_dbg);
	target_socket.register_get_direct_mem_ptr(this,
			&tlm2native_bridge::get_direct_mem_ptr);
}

void tlm2native_bridge::b_transport(tlm::tlm_generic_payload& trans,
				sc_time& delay)
{
	tlm::tlm_command cmd = trans.get_command();
	uint64 addr = trans.get_address();
	unsigned char *ptr = trans.get_data_ptr();
	unsigned int len = trans.get_data_length();
	unsigned int streaming_width = trans.get_streaming_width();
	unsigned char *be = trans.get_byte_enable_ptr();
	unsigned int be_len = trans.get_byte_enable_length();

	if (streaming_width == 0) {
		streaming_width = len;
	}

	if (((addr + MIN(len, streaming_width)) > sc_dt::uint64(size)) &&
			size > 0) {
		trans.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
		SC_REPORT_FATAL("tlm2native", "Unsupported access\n");
		return;
	}

	if (be_len || streaming_width) {
		// Slow path.
		unsigned int pos;

		for (pos = 0; pos < len; pos++) {
			bool do_access = true;

			if (be_len) {
				do_access = be[pos % be_len] == TLM_BYTE_ENABLED;
			}
			if (do_access) {
				if (trans.is_read()) {
					ptr[pos] = mem[addr + (pos % streaming_width)];
				} else {
					mem[addr + (pos % streaming_width)] = ptr[pos];
				}
			}
		}
	} else {
		if (trans.get_command() == tlm::TLM_READ_COMMAND)
			memcpy(ptr, &mem[addr], len);
		else if (cmd == tlm::TLM_WRITE_COMMAND)
			memcpy(&mem[addr], ptr, len);
	}

	delay += latency;

	trans.set_dmi_allowed(true);
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}

bool tlm2native_bridge::get_direct_mem_ptr(tlm::tlm_generic_payload& trans,
					   tlm::tlm_dmi& dmi_data)
{
	uint64_t end_addr = size > 0 ? size - 1 : ~(uint64_t)0;

	dmi_data.allow_read_write();

	dmi_data.set_dmi_ptr(mem);
	dmi_data.set_start_address(0);
	dmi_data.set_end_address(end_addr);
	/* Latencies are per byte.  Our latency is expressed per access,
	   which are in 32bits so dividie by 4. Is there a better way?.  */
	dmi_data.set_read_latency(latency / 4);
	dmi_data.set_write_latency(latency / 4);
	return true;
}

unsigned int tlm2native_bridge::transport_dbg(tlm::tlm_generic_payload& trans)
{
	unsigned int len = trans.get_data_length();
	sc_time delay = SC_ZERO_TIME;

	b_transport(trans, delay);
	return len;
}
#endif
