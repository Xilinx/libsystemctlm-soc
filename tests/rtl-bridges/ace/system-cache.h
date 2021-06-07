/*
 * Copyright (c) 2019 Xilinx Inc.
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
 */

#ifndef SYSTEM_CACHE_BRIDGE_H__
#define SYSTEM_CACHE_BRIDGE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <vector>
#include <list>
#include <sstream>

#include "tlm-bridges/amba.h"
#include "tlm-bridges/amba-ace.h"
#include "tlm-modules/tlm-aligner.h"
#include "tlm-extensions/genattr.h"
#include "test-modules/utils-ace.h"

class SystemCache:
	public sc_core::sc_module
{
public:
	//
	// Towards vfio bridge in rtl that then routes to the SystemCache
	//
	tlm_utils::simple_initiator_socket<SystemCache> bridge_socket;

	SC_HAS_PROCESS(SystemCache);

	SystemCache(sc_core::sc_module_name name,
			uint32_t base_addr) :
		sc_module(name),

		bridge_socket("bridge_socket"),

		m_base_addr(base_addr)
	{
		SC_THREAD(conf_thread);
	}

private:
	void conf_thread()
	{
		sc_time delay(10, SC_MS);
		wait(delay);

		barrier();
		dvm();
	}

	enum {
		VERSION0 = 0x1C020,
		VERSION1 = 0x1C028,
		BARRIER = 0x1C040,
		DVM_FIRST = 0x1C030,
		DVM_SECOND = 0x1C038,

	};

	void barrier()
	{
		dev_write32(BARRIER, 0, false);
	}

	void dvm()
	{
		dev_write32(DVM_FIRST, DVM_CMD(DVM::CmdBranchPredictorInv), false);
		dev_write32(DVM_FIRST, DVM_CMD(DVM::CmdHint), false);
		dev_write32(DVM_FIRST, DVM_CMD(DVM::CmdVirtInstCacheInv), false);
	}

	void dev_access(tlm::tlm_command cmd, uint64_t offset,
			void *buf, unsigned int len)
	{
		unsigned char *buf8 = (unsigned char *) buf;
		tlm::tlm_generic_payload dev_tr;
		sc_time delay = SC_ZERO_TIME;

		offset += m_base_addr;

		dev_tr.set_command(cmd);
		dev_tr.set_address(offset);
		dev_tr.set_data_ptr(buf8);
		dev_tr.set_data_length(len);
		dev_tr.set_streaming_width(len);
		dev_tr.set_dmi_allowed(false);
		dev_tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		bridge_socket->b_transport(dev_tr, delay);
		assert(dev_tr.get_response_status() == tlm::TLM_OK_RESPONSE);
	}

	uint32_t dev_read32(uint64_t offset)
	{
		uint32_t r;
		assert((offset & 3) == 0);
		dev_access(tlm::TLM_READ_COMMAND, offset, &r, sizeof(r));
		return r;
	}

	void dev_write32(uint64_t offset, uint32_t v, bool dummy_read = true)
	{
		uint32_t dummy;
		assert((offset & 3) == 0);
		dev_access(tlm::TLM_WRITE_COMMAND, offset, &v, sizeof(v));

		if (dummy_read) {
			dev_access(tlm::TLM_READ_COMMAND, offset, &dummy, sizeof(dummy));
		}
	}

	uint64_t m_base_addr;
};

#endif
