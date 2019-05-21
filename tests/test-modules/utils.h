/*
 * Copyright (c) 2018 Xilinx Inc.
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
#ifndef UTILS_H__
#define UTILS_H__

namespace utils {

enum : uint32_t {
	BYTE_ENABLE = 0xFFFF0001,
	STREAMING_WIDTH = 0xFFFF0002,
	EXPECT = 0xFFFF0003,
	EXT_GEN_ATTR = 0xFFFF0004
};

DataTransferVec merge(DataTransferVec transfers)
{
	DataTransferVec merged_transfers;

	for (auto& t : transfers) {
		/* flytta till test api */
		if (merged_transfers.size() > 0) {
			DataTransfer& last = merged_transfers.back();

			if (t.cmd == BYTE_ENABLE) {
				last.byte_enable = t.byte_enable;
				last.byte_enable_length = t.byte_enable_length;
				// Clear merge pointer to avoid it getting
				// freed on destruction of t.
				t.byte_enable = nullptr;
			} else if (t.cmd == STREAMING_WIDTH) {
				last.streaming_width = t.streaming_width;
			} else if (t.cmd == EXPECT) {
				last.expect = t.expect;
				// Clear merge pointer to avoid it getting
				// freed on destruction of t.
				t.expect = nullptr;
			} else if (t.cmd == EXT_GEN_ATTR) {
				last.ext.gen_attr = t.ext.gen_attr;
			}
		}

		if (t.cmd == DataTransfer::READ ||
				t.cmd == DataTransfer::WRITE ||
				t.cmd == DataTransfer::IGNORE ) {
			merged_transfers.push_back(t);
		}
	}

	return merged_transfers;
}

#define DATA(x...) ((const unsigned char[]) { x })

/* move to test dir */
DataTransfer Expect(const unsigned char *expect, int length)
{
	DataTransfer t;
	t.cmd = EXPECT;
	t.expect = expect;
	t.length = length;
	return t;
}

DataTransfer GenAttr(uint64_t master_id,
			bool secure,
			bool eop,
			bool wrap = false,
			uint32_t burst_width = 0,
			uint32_t transaction_id = 0,
			bool exclusive = false,
			bool locked = false,
			bool bufferable = false,
			bool modifiable = false,
			bool read_allocate = false,
			bool write_allocate = false,
			uint8_t qos = 0,
			uint8_t region = 0)
{
	DataTransfer t;
	t.cmd = EXT_GEN_ATTR;
	t.ext.gen_attr.enabled = true;
	t.ext.gen_attr.master_id = master_id;
	t.ext.gen_attr.secure = secure;
	t.ext.gen_attr.eop = eop;
	t.ext.gen_attr.wrap = wrap;
	t.ext.gen_attr.burst_width = burst_width;
	t.ext.gen_attr.transaction_id = transaction_id;
	t.ext.gen_attr.exclusive = exclusive;
	t.ext.gen_attr.locked = locked;
	t.ext.gen_attr.bufferable = bufferable;
	t.ext.gen_attr.modifiable = modifiable;
	t.ext.gen_attr.read_allocate = read_allocate;
	t.ext.gen_attr.write_allocate = write_allocate;
	t.ext.gen_attr.qos = qos;
	t.ext.gen_attr.region = region;
	return t;
}

DataTransfer Read(uint64_t address, unsigned int length = 4)
{
	DataTransfer t;
	t.cmd = DataTransfer::READ;
	t.addr = address;
	t.length = length;
	t.streaming_width = length;
	return t;
}

DataTransfer Write(uint64_t address, const unsigned char *data, unsigned int length = 4)
{
	DataTransfer t;
	t.cmd = DataTransfer::WRITE;
	t.addr = address;
	t.data = data;
	t.length = length;
	t.streaming_width = length;
	return t;
}

DataTransfer ByteEnable(const unsigned char *byte_enable,
                        unsigned int byte_enable_length)
{
	DataTransfer t;
	t.cmd = BYTE_ENABLE;
	t.byte_enable = byte_enable;
	t.byte_enable_length = byte_enable_length;
	return t;
}

DataTransfer StreamingWidth(unsigned int streaming_width)
{
	DataTransfer t;
	t.cmd = STREAMING_WIDTH;
	t.streaming_width = streaming_width;
	return t;
}

}

#endif
