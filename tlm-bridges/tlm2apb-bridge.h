/*
 * Copyright (c) 2013 Xilinx Inc.
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

#define SC_INCLUDE_DYNAMIC_PROCESSES

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH>
class tlm2apb_bridge
: public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm2apb_bridge> tgt_socket;

	tlm2apb_bridge(sc_core::sc_module_name name);
	SC_HAS_PROCESS(tlm2apb_bridge);

	sc_in<BOOL_TYPE> clk;
	sc_out<BOOL_TYPE> psel;
	sc_out<BOOL_TYPE> penable;
	sc_out<BOOL_TYPE> pwrite;
	sc_out<ADDR_TYPE<ADDR_WIDTH> > paddr;
	sc_out<DATA_TYPE<DATA_WIDTH> > pwdata;
	sc_in<DATA_TYPE<DATA_WIDTH> > prdata;
	sc_in<BOOL_TYPE> pready;

private:
	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay);
};

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH>
tlm2apb_bridge<BOOL_TYPE, ADDR_TYPE, ADDR_WIDTH, DATA_TYPE, DATA_WIDTH> ::tlm2apb_bridge(sc_module_name name)
	: sc_module(name), tgt_socket("tgt_socket"),
	clk("clk"),
	psel("psel"),
	penable("penable"),
	pwrite("pwrite"),
	paddr("paddr"),
	pwdata("pwdata"),
	prdata("prdata"),
	pready("pready")
{
	tgt_socket.register_b_transport(this, &tlm2apb_bridge::b_transport);
}

template
<class BOOL_TYPE, template <int> class ADDR_TYPE, int ADDR_WIDTH, template <int> class DATA_TYPE, int DATA_WIDTH>
void tlm2apb_bridge
<BOOL_TYPE, ADDR_TYPE, ADDR_WIDTH, DATA_TYPE, DATA_WIDTH>
::b_transport(tlm::tlm_generic_payload& trans, sc_time& delay)
{
	tlm::tlm_command cmd = trans.get_command();
	sc_dt::uint64    addr = trans.get_address();
	unsigned char*   data = trans.get_data_ptr();
	unsigned int     len = trans.get_data_length();
	unsigned char*   byt = trans.get_byte_enable_ptr();
	unsigned int     wid = trans.get_streaming_width();
	uint32_t tprdata = 0;
	uint32_t tpwdata = 0;

	if (byt != 0) {
		trans.set_response_status(tlm::TLM_BYTE_ENABLE_ERROR_RESPONSE);
		return;
	}

	if (len != 4 || wid < len) {
		trans.set_response_status(tlm::TLM_BURST_ERROR_RESPONSE);
		return;
	}

	/* Setup phase. Prepare all ctrl signals except enable.  */
	psel = BOOL_TYPE(1);
	paddr = addr;

	pwrite = BOOL_TYPE(false);
	if (cmd == tlm::TLM_WRITE_COMMAND) {
		memcpy(&tpwdata, data, len);
		pwrite = BOOL_TYPE(true);
	}

	pwdata = (uint64_t) tpwdata;

	/* Because we wait for events we need to accomodate delay.  */
	wait(delay);
	delay = SC_ZERO_TIME;

	wait(clk.posedge_event());
	wait(clk.negedge_event());
	/* Access phase. Enable.  */
	penable = BOOL_TYPE(true);

	do {
		wait(clk.posedge_event());
		/* Readout data.  */
		if (cmd == tlm::TLM_READ_COMMAND) {
			tprdata = prdata.read().to_uint64();
			memcpy(data, &tprdata, len);
		}

		psel = pready == BOOL_TYPE(true) ? BOOL_TYPE(false) : BOOL_TYPE(true);
		penable = pready == BOOL_TYPE(true) ? BOOL_TYPE(false) : BOOL_TYPE(true);
	} while (pready.read() == BOOL_TYPE(false));
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}
