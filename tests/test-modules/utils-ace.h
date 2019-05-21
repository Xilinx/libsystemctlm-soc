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
#ifndef UTILS_ACE_H__
#define UTILS_ACE_H__

#include "test-modules/utils.h"
#include "tlm-bridges/amba-ace.h"

using namespace AMBA::ACE;

namespace utils {

namespace ACE {

DataTransfer ReadBarrier(uint32_t transaction_id = 0xAA, uint8_t domain = 1)
{
	static const uint8_t dummy = 0;
	DataTransfer t;

	t.cmd = DataTransfer::IGNORE;
	t.addr = 0;
	t.data = &dummy;
	t.length = 1;
	t.streaming_width = t.length;

	t.ext.gen_attr.enabled = true;
	t.ext.gen_attr.modifiable = true;
	t.ext.gen_attr.barrier = true;
	t.ext.gen_attr.is_read = true;

	t.ext.gen_attr.transaction_id = transaction_id;
	t.ext.gen_attr.domain = domain;

	return t;
}

DataTransfer WriteBarrier(uint32_t transaction_id = 0xAA, uint8_t domain = 1)
{
	static const uint8_t dummy = 0;
	DataTransfer t;

	t.cmd = DataTransfer::IGNORE;
	t.addr = 0;
	t.data = &dummy;
	t.length = 1;
	t.streaming_width = t.length;

	t.ext.gen_attr.enabled = true;
	t.ext.gen_attr.modifiable = true;
	t.ext.gen_attr.barrier = true;
	t.ext.gen_attr.is_read = false;

	t.ext.gen_attr.transaction_id = transaction_id;
	t.ext.gen_attr.domain = domain;

	return t;
}

#define DVM_CMD(x) (x << DVM::CmdShift)

DataTransfer DVMMessage(uint32_t dvm_cmd,
				uint32_t transaction_id = 0xBB,
				uint8_t domain = 1)
{
	static const uint8_t dummy = 0;
	DataTransfer t;

	t.cmd = DataTransfer::IGNORE;
	t.addr = dvm_cmd;
	t.data = &dummy;
	t.length = 1;
	t.streaming_width = t.length;

	t.ext.gen_attr.enabled = true;
	t.ext.gen_attr.modifiable = true;

	t.ext.gen_attr.transaction_id = transaction_id;
	t.ext.gen_attr.domain = domain;
	t.ext.gen_attr.snoop = AR::DVMMessage;

	t.ext.gen_attr.is_read = true;

	return t;
}

DataTransfer ExclusiveLoad(uint64_t address, unsigned int length = 4)
{
	DataTransfer t;

	t.cmd = DataTransfer::READ;
	t.addr = address;
	t.length = length;
	t.streaming_width = t.length;

	t.ext.gen_attr.enabled = true;
	t.ext.gen_attr.exclusive = true;
	t.ext.gen_attr.domain = 1;

	return t;
}

DataTransfer ExclusiveStore(uint64_t address,
				const unsigned char *data,
				unsigned int length = 4)
{
	DataTransfer t;

	t.cmd = DataTransfer::WRITE;
	t.addr = address;
	t.data = data;
	t.length = length;
	t.streaming_width = length;

	t.ext.gen_attr.enabled = true;
	t.ext.gen_attr.exclusive = true;
	t.ext.gen_attr.domain = 1;

	return t;
}

DataTransfer CleanShared(uint64_t address,
				const unsigned char *data,
				unsigned int length)
{
	DataTransfer t;

	t.cmd = DataTransfer::IGNORE;
	t.addr = address;
	t.data = data;
	t.length = length;
	t.streaming_width = t.length;

	t.ext.gen_attr.enabled = true;

	t.ext.gen_attr.modifiable = true;
	t.ext.gen_attr.barrier = false;
	t.ext.gen_attr.is_read = true;

	t.ext.gen_attr.domain = 1;

	t.ext.gen_attr.snoop = AR::CleanShared;

	return t;
}

DataTransfer CleanInvalid(uint64_t address,
				const unsigned char *data,
				unsigned int length)
{
	DataTransfer t;

	t.cmd = DataTransfer::IGNORE;
	t.addr = address;
	t.data = data;
	t.length = length;
	t.streaming_width = t.length;

	t.ext.gen_attr.enabled = true;

	t.ext.gen_attr.modifiable = true;
	t.ext.gen_attr.barrier = false;
	t.ext.gen_attr.is_read = true;

	t.ext.gen_attr.domain = 1;

	t.ext.gen_attr.snoop = AR::CleanInvalid;

	return t;
}

DataTransfer MakeInvalid(uint64_t address,
				const unsigned char *data,
				unsigned int length)
{
	DataTransfer t;

	t.cmd = DataTransfer::IGNORE;
	t.addr = address;
	t.data = data;
	t.length = length;
	t.streaming_width = t.length;

	t.ext.gen_attr.enabled = true;

	t.ext.gen_attr.modifiable = true;
	t.ext.gen_attr.barrier = false;
	t.ext.gen_attr.is_read = true;

	t.ext.gen_attr.domain = 1;

	t.ext.gen_attr.snoop = AR::MakeInvalid;

	return t;
}

} /* namespace ACE */

} /* namespace utils */

#endif
