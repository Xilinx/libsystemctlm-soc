/*
 * Device access helper functions.
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

#ifndef DEVICE_ACCESS_H__
#define DEVICE_ACCESS_H__

#undef MAX
#define MAX(a, b) (a) > (b) ? a : b

#define barrier() __asm__ __volatile__ ("" : : : "memory")

// These IO functions will try to avoid unaligned accesses.
void memcpy_from_io(uint8_t *buf, void *src, size_t len)
{
	union {
		uint8_t *u8;
		uint16_t *u16;
		uint32_t *u32;
		uint64_t *u64;
	} p;
	uint64_t v64;
	uintptr_t addr = (uintptr_t) src;

	p.u8 = (uint8_t *) src;

	barrier();
	if (len == 1) {
		buf[0] = p.u8[0];
	} else {
		if (len == 2 && (addr & 1) == 0) {
			v64 = p.u16[0];
		} else if (len == 4 && (addr & 3) == 0) {
			v64 = p.u32[0];
		} else if (len == 8 && (addr & 7) == 0) {
			v64 = p.u64[0];
		} else {
			// Assume this is an access to memory and fallback to memcpy.
			memcpy(buf, p.u8, len);
			return;
		}
		memcpy(buf, &v64, len);
	}
}

void memcpy_to_io(void *dst, uint8_t *buf, size_t len)
{
	union {
		uint8_t *u8;
		uint16_t *u16;
		uint32_t *u32;
		uint64_t *u64;
	} p;
	union {
		uint8_t u8;
		uint16_t u16;
		uint32_t u32;
		uint64_t u64;
	} v;
	uintptr_t addr = (uintptr_t) dst;

	p.u8 = (uint8_t *) dst;

	if (len == 1) {
		p.u8[0] = buf[0];
	} else {
		memcpy(&v.u64, buf, MIN(len, sizeof v));
		if (len == 2 && (addr & 1) == 0) {
			p.u16[0] = v.u16;
		} else if (len == 4 && (addr & 3) == 0) {
			p.u32[0] = v.u32;
		} else if (len == 8 && (addr & 7) == 0) {
			p.u64[0] = v.u64;
		} else {
			// Assume this is an access to memory and fallback to memcpy.
			memcpy(p.u8, buf, len);
		}
	}
	barrier();
}

#undef barrier
#endif
