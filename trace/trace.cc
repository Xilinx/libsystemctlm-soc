/*
 * Trace-utils.
 *
 * Copyright (c) 2015 Xilinx Inc.
 * Written by Edgar E. Iglesias
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

#include <inttypes.h>
#include <stdio.h>
#include <signal.h>
#include <unistd.h>

#include "systemc.h"

using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "trace.h"

template < typename T > void sc_trace_template(sc_trace_file *tf, sc_object *obj)
{
	T* object ;
	if ((object  = dynamic_cast < T* >(obj)))
		sc_trace(tf, *object , object->name());
}

#define TRACE_TYPE(T, W)						\
do {									\
	sc_trace_template < sc_core::sc_signal < T<W> > > (tf,obj);	\
	sc_trace_template < sc_core::sc_in < T<W> > > (tf,obj);		\
	sc_trace_template < sc_core::sc_out < T<W> > > (tf,obj);	\
} while (0)

void trace(sc_trace_file* tf, const sc_module& mod, const char *txt)
{
	std::vector < sc_object* > ch = mod.get_child_objects();

	for ( unsigned i = 0; i < ch.size(); i++ ) {
		sc_module* m;
		sc_object* obj = ch[i];

		/* Add more types as needed.  */
		sc_trace_template < sc_core::sc_signal < bool > > (tf,obj);
		sc_trace_template < sc_core::sc_in < bool > > (tf,obj);
		sc_trace_template < sc_core::sc_out < bool > > (tf,obj);

		TRACE_TYPE(sc_bv, 2);
		TRACE_TYPE(sc_bv, 3);
		TRACE_TYPE(sc_bv, 4);
		TRACE_TYPE(sc_bv, 5);
		TRACE_TYPE(sc_bv, 6);
		TRACE_TYPE(sc_bv, 7);
		TRACE_TYPE(sc_bv, 8);
		TRACE_TYPE(sc_bv, 9);
		TRACE_TYPE(sc_bv, 10);
		TRACE_TYPE(sc_bv, 16);
		TRACE_TYPE(sc_bv, 32);
		TRACE_TYPE(sc_bv, 64);
		TRACE_TYPE(sc_bv, 128);
		TRACE_TYPE(sc_bv, 256);
		TRACE_TYPE(sc_bv, 384);
		TRACE_TYPE(sc_bv, 512);
		TRACE_TYPE(sc_bv, 1024);

		if ((m = dynamic_cast < sc_module* > (obj)))
			trace(tf, *m, m->name());
	}
}
