/*
 * A device used to loopback Wires.
 *
 * Copyright (c) 2025, Advanced Micro Device, Inc.
 * Written by Sai Pavan Boddu <sai.pavan.boddu@amd.com>.
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

#include <systemc.h>

using namespace sc_core;
using namespace std;

#include "wire-loopback.h"
#include <sys/types.h>

SC_HAS_PROCESS(wire_loopback);

wire_loopback::wire_loopback(sc_module_name name, int nr_wires)
	:sc_module(name), wire_in("wire_in", nr_wires), wire_out("wire_out", nr_wires)
{
	int i;
	SC_METHOD(loopback);
	    for(i = 0; i < nr_wires; i++) {
	        sensitive << wire_in[i];
	    }

	this->nr_wires = nr_wires;
}

void wire_loopback::loopback(void)
{
	int i;

	for(i = 0; i < nr_wires; i++) {
		wire_out[i].write(wire_in[i].read());
	}
}
