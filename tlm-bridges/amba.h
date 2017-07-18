/*
 * Shared AMBA defs.
 *
 * Copyright (c) 2017 Xilinx Inc.
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

#ifndef TLM_BRIDGES_AMBA_H__
#define TLM_BRIDGES_AMBA_H__

enum {
	AXI_OKAY = 0,
	AXI_EXOKAY = 1,
	AXI_SLVERR = 2,
	AXI_DECERR = 3,
};

enum {
	AXI_BURST_FIXED = 0,
	AXI_BURST_INCR = 1,
	AXI_BURST_WRAP = 2,
};

enum {
	AXI_PROT_PRIV = 1 << 0,
	AXI_PROT_NS = 1 << 1,
	AXI_PROT_INSN = 1 << 2,
};
#endif
