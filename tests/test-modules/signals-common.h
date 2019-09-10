/*
 * Common signal helper routines.
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

#ifndef SIGNALS_COMMON_H__
#define SIGNALS_COMMON_H__

/* Scan a SystemC object's children looking for prefix + name.  */
static inline sc_object *signal_find_child(sc_object *dev,
					   const char *prefix,
					   const char *name)
{
	// Allocate something long large enough to fit all signal names.
	size_t signame_size = strlen(prefix) + 128;
	char *signame = new char [signame_size];
	std::vector < sc_object* > ch = dev->get_child_objects();
	unsigned int i;

	snprintf(signame, signame_size, "%s%s", prefix, name);

	for (i = 0; i < ch.size(); i++ ) {
		if (strcmp(ch[i]->basename(), signame) == 0) {
			delete[] signame;
			return ch[i];
		}
	}
	delete[] signame;
	return NULL;
}

template <typename T>
static inline void signal_connect(sc_object *dev,
				  const char *prefix,
				  sc_signal<T> &sig,
				  bool optional = false)
{
	sc_object *obj;
	sc_in<T > *p_in;
	sc_out<T > *p_out;
	char *msg = NULL;
	int r;

	obj = signal_find_child(dev, prefix, sig.basename());
	if (!obj) {
		goto error;
	}

	p_in = dynamic_cast<__typeof__(p_in)>(obj);
	if (p_in) {
		(*p_in)(sig);
		return;
	}

	p_out = dynamic_cast<__typeof__(p_out)>(obj);
	if (p_out) {
		(*p_out)(sig);
	} else {
		goto error;
	}

	return;
error:
	if (optional)
		return;

	r = asprintf(&msg, "Unable to connect %s", sig.name());
	if (r != -1) {
		SC_REPORT_ERROR("SIGNALS:", msg);
		free(msg);
	}
}

template <typename T>
static inline void signal_connect_optional(sc_object *dev,
					   const char *prefix,
					   sc_signal<T> &sig)
{
	signal_connect(dev, prefix, sig, true);
}
#endif
