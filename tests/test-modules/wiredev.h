/*
 * Copyright (c) 2025, Advanced Micro Device, Inc.
 * Written by Sai Pavan
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

class wiredev
: public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<wiredev> socket;

	wiredev(sc_core::sc_module_name name, unsigned int nr_wires_in,
		unsigned int nr_wires_out = 0);
	sc_vector<sc_in<bool> > wires_in;
	sc_vector<sc_out<bool> > wires_out;
	virtual void b_transport(tlm::tlm_generic_payload& trans,
						sc_time& delay);
	virtual unsigned int transport_dbg(tlm::tlm_generic_payload& trans);
};
