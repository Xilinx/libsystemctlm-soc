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

#include "tlm.h"
#include "tlm-extensions/genattr.h"
#include <assert.h>

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

enum {
	AXI_LOCK_NORMAL = 0,
	AXI_LOCK_EXCLUSIVE = 1,
	AXI_LOCK_LOCKED = 2,
};

enum {
	AXI3_AxLOCK_WIDTH = 2,
	AXI4_AxLOCK_WIDTH = 1,
};

enum AXIVersion {
	V_AXI4,
	V_AXI3,
	V_AXI4LITE,
};

enum {
	AXI3_MAX_BURSTLENGTH = 16,
	AXI4_MAX_BURSTLENGTH = 256,
};

/* Compute AxSize given a size in bytes.  */
static inline int map_size_to_axsize(int size) {
	switch (size) {
		case 128:
			return 7;
		case 64:
			return 6;
		case 32:
			return 5;
		case 16:
			return 4;
		case 8:
			return 3;
		case 4:
			return 2;
		case 2:
			return 1;
		case 1:
			return 0;
		default:
			return -1;
	}
}

static inline int map_size_to_axsize_assert(int size) {
	int r;

	r = map_size_to_axsize(size);
	assert(r != -1);
	return r;
}

/* Compute nearest AxSize given a size in bytes.  */
static inline int map_size_to_nearest_axsize(int size) {
	if (size == 1)
		return 0;
	else if (size == 2)
		return 1;
	else if (size <= 4)
		return 2;
	else if (size <= 8)
		return 3;
	else if (size <= 16)
		return 4;
	else if (size <= 32)
		return 5;
	else if (size <= 64)
		return 6;
	else if (size <= 128)
		return 7;
	assert(0);
	return -1;
}

// Update a generic payload and it's optional generic attributes
// based on an AXI response code.
static inline void tlm_gp_set_axi_resp(tlm::tlm_generic_payload& trans,
				       int resp)
{
	genattr_extension *genattr;

	trans.get_extension(genattr);

	switch (resp) {
	case AXI_EXOKAY:
		if (genattr)
			genattr->set_exclusive_handled();
		// Fall-through.
	case AXI_OKAY:
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		break;
	case AXI_DECERR:
		trans.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
		break;
	case AXI_SLVERR:
	default:
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		break;
	}
}

// Dig into a generic payload and it's optional generic attributes
// and return a derived AXI response code.
static inline int tlm_gp_get_axi_resp(tlm::tlm_generic_payload& trans)
{
	genattr_extension *genattr;
	int r;

	trans.get_extension(genattr);

	switch (trans.get_response_status()) {
	case tlm::TLM_OK_RESPONSE:
		r = AXI_OKAY;
		if (genattr && genattr->get_exclusive_handled()) {
			r = AXI_EXOKAY;
		}
		break;
	case tlm::TLM_ADDRESS_ERROR_RESPONSE:
		r = AXI_DECERR;
		break;
	default:
		r = AXI_SLVERR;
		break;
	}
	return r;
}

template<int N>
struct __AXISignal
{
	typedef sc_bv<N> type;
};

template<>
struct __AXISignal<1>
{
	typedef bool type;
};

template<>
struct __AXISignal<0>
{
	typedef bool type;
};

#define AXISignal(x) typename __AXISignal<x>::type

template<int N>
uint32_t to_uint(sc_out<sc_bv<N> >& port)
{
	return port.read().to_uint();
}

template<int N>
uint32_t to_uint(sc_in<sc_bv<N> >& port)
{
	return port.read().to_uint();
}

inline uint32_t to_uint(sc_out<bool>& port)
{
	return port.read();
}
inline uint32_t to_uint(sc_in<bool>& port)
{
	return port.read();
}

class axi_common
{
public:
	template<typename T>
	axi_common(T *mod) :
		clk(mod->clk),
		resetn(mod->resetn)
	{}

	axi_common(sc_in<bool>& _clk, sc_in<bool>& _resetn) :
		clk(_clk),
		resetn(_resetn)
	{}

	void wait_for_reset_release()
	{
		do {
			sc_core::wait(clk.posedge_event());
		} while (resetn.read() == false);
	}

	bool reset_asserted() { return resetn.read() == false; }

	void wait_abort_on_reset(sc_in<bool>& sig)
	{
		do {
			sc_core::wait(clk.posedge_event() | resetn.negedge_event());
		} while (sig.read() == false && resetn.read() == true);
	}

	template<typename T>
	void tlm2axi_clear_fifo(sc_fifo<T*>& fifo)
	{
		while (fifo.num_available() > 0) {
			T *tr = fifo.read();

			abort(tr);
		}
	}

	template<typename T>
	void axi2tlm_clear_fifo(sc_fifo<T*>& fifo)
	{
		while (fifo.num_available() > 0) {
			T *tr = fifo.read();
			delete tr;
		}
	}

	template<typename T>
	void abort(T *tr)
	{
		tlm::tlm_generic_payload& trans = tr->GetGP();

		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		tr->DoneEvent().notify();
	}

private:
	sc_in<bool>& clk;
	sc_in<bool>& resetn;
};

#endif
