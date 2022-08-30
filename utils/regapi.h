/*
 * This implements a thin Register API. It's somewhat compatible with the
 * Xilinx regapi tools including the RegAPI that made it into QEMU. 
 *
 * Copyright (c) 2022 Advanced Micro Devices Inc.
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
#ifndef UTILS_REGAPI_H__
#define UTILS_REGAPI_H__

#include "tlm-extensions/genattr.h"
#include "utils/bitops.h"

#define REG32(R, N)					\
	enum { A_ ## R = N };				\
	enum { R_ ## R = (N) / 4 };

#define FIELD(R, F, SH, LEN)				\
	enum { R_ ## R ## _ ## F ## _SHIFT = (SH)};	\
	enum { R_ ## R ## _ ## F ## _LENGTH = (LEN)};	\
	enum { R_ ## R ## _ ## F ## _MASK = ((1ULL << LEN) - 1) << SH};

#define FIELD_EX(V, R, F)				\
	(((uint64_t)(V) >> R_ ## R ## _ ## F ## _SHIFT) & ((1ULL << R_ ## R ## _ ## F ## _LENGTH) - 1))

#define ARRAY_FIELD_EX(A, R, F)	FIELD_EX((A)[R_ ## R], R, F)

#define FIELD_DP(RB, D, R, F, V)			\
	(RB).reg_deposit(D, R_ ## R ## _ ## F ## _SHIFT, R_ ## R ## _ ## F ## _LENGTH, V)

#define ARRAY_FIELD_DP(RB, R, F, V)			\
	(RB).reg_deposit((RB).regs[R_ ## R], R_ ## R ## _ ## F ## _SHIFT, R_ ## R ## _ ## F ## _LENGTH, V)

template <typename T >
struct regapi_info {
	const char *name;
	T ro;
	T w1c;
	T reset;
	T cor;
	T rsvd;
	T unimp;

	uint64_t addr;
};

template <typename T, int R_MAX >
class regapi_block : public sc_core::sc_module
{
public:
	const regapi_info <T > *info;
	T regs[R_MAX];
	bool debug;

	regapi_block(sc_core::sc_module_name name,
			const regapi_info <T > *info_p, bool a_debug = false) :
		sc_module(name),
		info(info_p),
		debug(a_debug)
	{
		assert(info_p);
	}

	void reg_deposit(T &dst, int shift, int len, T val) {
		uint64_t mask = bitops_mask64(shift, len);
		dst &= ~mask;
		dst |= val << shift;
	}

	T reg_access(tlm::tlm_generic_payload& tr, sc_time& delay, T val) {
		uint64_t addr = tr.get_address();
		bool is_read = tr.is_read();
		unsigned int regindex;
		bool found = false;
		int i = 0;

		while (i < R_MAX && info[i].name) {
			if (addr == info[i].addr) {
				found = true;
				break;
			}
			i++;
		}

		if (!found) {
			if (debug) {
				printf("reg: %s INVALID 0x%lx = %x\n",
					is_read ? "READ" : "WRITE", addr, is_read ? 0 : val);
			}
			tr.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
			return 0;
		}

		regindex = addr / sizeof(T);

		if (is_read) {
			val = regs[regindex];

			/* Clear bits marked as clear-on-read.  */
			regs[regindex] &= ~info[i].cor;
		} else {
			if (info[i].ro) {
				regs[regindex] &= info[i].ro;
				val &= ~info[i].ro;
				regs[regindex] |= val;
			} else {
				regs[regindex] = val;
			}

			/* Clear bits marked as write one to clear.  */
			regs[regindex] &= ~info[i].w1c;
		}

		if (debug) {
			printf("reg: %s %s 0x%lx = %x (%x)\n",
				is_read ? "READ" : "WRITE", info[i].name, addr, val, regs[regindex]);
		}
		tr.set_response_status(tlm::TLM_OK_RESPONSE);
		return regs[regindex];
	}


	void reg_reset(const regapi_info<T > *rinfo) {
		unsigned int regindex = rinfo->addr / sizeof(T);

		assert(rinfo->name);
		assert(regindex < R_MAX);

		regs[regindex] = rinfo->reset;
	}

	void reg_reset_all(void) {
		unsigned int i;

		for (i = 0; i < R_MAX && info[i].name; i++) {
			reg_reset(info + i);
		}
	}

	void reg_b_transport(tlm::tlm_generic_payload& tr, sc_time& delay) {
		unsigned char *data = tr.get_data_ptr();
		int len = tr.get_data_length();
		T val = 0;

		if (sizeof val != len) {
			tr.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
			return;
		}

		if (!tr.is_read()) {
			memcpy(&val, data, len);
		}

		val = reg_access(tr, delay, val);

		if (tr.is_read()) {
			memcpy(data, &val, len);
		}
	}
};
#endif
