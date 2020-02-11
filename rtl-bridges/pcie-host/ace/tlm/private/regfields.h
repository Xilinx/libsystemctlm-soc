/*
 * Copyright (c) 2020 Xilinx Inc.
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
 *
 */

#ifndef ACE_HW_BRIDGE_REGFIELDS_H__
#define ACE_HW_BRIDGE_REGFIELDS_H__

#define GEN_FIELD_FUNCS(fname, shift, mask) \
uint8_t fname(uint32_t r) { return (r >> shift) & mask; } \
uint32_t gen_ ## fname(uint32_t v) { return (v & mask) << shift; }

namespace RTL {
namespace AMBA {
namespace ACE {

	GEN_FIELD_FUNCS(valid_bit, 31, 1)
	GEN_FIELD_FUNCS(descr_idx, 0, 0xF)

	GEN_FIELD_FUNCS(arburst, 0, 0x3)
	GEN_FIELD_FUNCS(arlock, 2, 0x1)
	GEN_FIELD_FUNCS(arcache, 4, 0xF)
	GEN_FIELD_FUNCS(arprot, 8, 0x7)
	GEN_FIELD_FUNCS(arqos, 11, 0xF)
	GEN_FIELD_FUNCS(arregion, 15, 0xF)
	GEN_FIELD_FUNCS(arbar, 20, 0x3)
	GEN_FIELD_FUNCS(ardomain, 22, 0x3)
	GEN_FIELD_FUNCS(arsnoop, 24, 0xF)

	GEN_FIELD_FUNCS(awburst, 0, 0x1)
	GEN_FIELD_FUNCS(awlock, 2, 0x1)
	GEN_FIELD_FUNCS(awcache, 4, 0xF)
	GEN_FIELD_FUNCS(awprot, 8, 0x7)
	GEN_FIELD_FUNCS(awqos, 11, 0xF)
	GEN_FIELD_FUNCS(awregion, 15, 0xF)
	GEN_FIELD_FUNCS(awbar, 20, 0x3)
	GEN_FIELD_FUNCS(awdomain, 22, 0x3)
	GEN_FIELD_FUNCS(awsnoop, 24, 0xF)

	GEN_FIELD_FUNCS(acprot, 8, 0x7)
	GEN_FIELD_FUNCS(acsnoop, 24, 0xF)
} } }

#undef GEN_FIELD_FUNCS

#endif
