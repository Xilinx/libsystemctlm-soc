/*
 * Bit operation functions.
 *
 * Copyright (c) 2019 Xilinx Inc.
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

#ifndef BITOPS_H__
#define BITOPS_H__

static inline uint64_t bitops_mask64(unsigned int start, unsigned int len)
{
	uint64_t v;

	if (start >= 64 || len == 0)
		return 0;

	v = ~(uint64_t)0;
	if (len < 64)
		v >>= 64 - len;
	v <<= start;
	return v;
}

// Maps an sc_bv into a vector of booleans.
template <int width>
static void map_sc_bv2v(sc_vector<sc_signal<bool> > &v, const sc_bv<width> &s)
{
	int i;

	for (i = 0; i < width && i < v.size(); i++) {
		bool b = s[i].to_bool();

		v[i].write(b);
	}
}
#endif
