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
#ifndef DATA_TRANSFER_H__
#define DATA_TRANSFER_H__

#include <string.h>

struct DataTransfer {

	enum : uint32_t {
		READ,
		WRITE,
		IGNORE,
	};

	uint64_t                 addr;
	uint32_t                 cmd;
	const unsigned char*     data;
	uint32_t                 length;
	const unsigned char*     byte_enable;
	uint32_t                 byte_enable_length;
	uint32_t                 streaming_width;
	const unsigned char*     expect;

	struct {
		struct {
			bool enabled;
			uint64_t master_id;
			bool secure;
			bool eop;
			bool wrap;
			uint32_t burst_width;
			uint32_t transaction_id;
			bool exclusive;
			bool locked;
			bool bufferable;
			bool modifiable;
			bool read_allocate;
			bool write_allocate;
			uint8_t qos;
			uint8_t region;
			uint8_t snoop;
			uint8_t domain;
			bool barrier;
			bool is_read;
		} gen_attr;
	} ext;

	bool on_heap;

	DataTransfer(bool _on_heap = false) :
        addr(0),
		cmd(0),
		data(nullptr),
		length(0),
		byte_enable(nullptr),
		byte_enable_length(0),
		streaming_width(0),
		expect(nullptr),
		on_heap(_on_heap)
	{
		ext.gen_attr = {};
	}

	// Move C'actor
	DataTransfer(DataTransfer&& other) :
		data(other.data),
		byte_enable(other.byte_enable),
		expect(other.expect),
		on_heap(other.on_heap){

		addr = other.addr;
		cmd = other.cmd;
		length = other.length;
		byte_enable_length = other.byte_enable_length;
		streaming_width = other.streaming_width;
		ext = other.ext;

		// Clear the incoming pointers
		other.data = nullptr;
		other.byte_enable =  nullptr;
		other.expect = nullptr;
	}

	~DataTransfer()
	{
		if (on_heap) {
			if (data) {
				delete[] data;
			}
			if (byte_enable) {
				delete[] byte_enable;
			}
			if (expect) {
				delete[] expect;
			}
		}
	}

	friend std::ostream& operator<< (std::ostream &out, const DataTransfer& t)
	{
		out << "{ .cmd = " << (t.cmd == READ ? "R" : "W") << ", "
			<< ".addr = " << std::hex << t.addr << ", ";
		if (t.cmd == WRITE) {
			std::cout << ".data = { ";
			for (uint32_t i = 0; i < t.length; i++) {
				std::cout << "0x" << std::hex
					<< static_cast<unsigned int>(t.data[i])
					<< ", ";
			}
		} else if (t.expect) {
			std::cout << ".expect = { ";
			for (uint32_t i = 0; i < t.length; i++) {
				std::cout << "0x" << std::hex
					<< static_cast<unsigned int>(t.expect[i])
					<< ", ";
			}
		}
		out << " }, .length = " << std::dec << t.length << ", "
			<< ", .streaming_width = " << std::dec << t.streaming_width << ", "
			<< ".ext.gen_attr { "
			<< ".enabled: " << t.ext.gen_attr.enabled << ", "
			<< ".master_id: " << t.ext.gen_attr.master_id << ", "
			<< ".secure: " << t.ext.gen_attr.secure << ", "
			<< ".eop: " << t.ext.gen_attr.eop << ", "
			<< ".wrap: " << t.ext.gen_attr.wrap << ", "
			<< ".burst_width: " << t.ext.gen_attr.burst_width << ", "
			<< ".transaction_id: " << t.ext.gen_attr.transaction_id << ", "
			<< ".exclusive: " << t.ext.gen_attr.exclusive << ", "
			<< ".locked: " << t.ext.gen_attr.locked << ", "
			<< ".bufferable: " << t.ext.gen_attr.bufferable << ", "
			<< ".modifiable: " << t.ext.gen_attr.modifiable << ", "
			<< ".read_allocate: " << t.ext.gen_attr.read_allocate << ", "
			<< ".write_allocate: " << t.ext.gen_attr.write_allocate << ", "
			<< ".qos: " << static_cast<uint32_t>(t.ext.gen_attr.qos) << ", "
			<< ".region: " << static_cast<uint32_t>(t.ext.gen_attr.region) << ", "
			<< ".snoop: " << static_cast<uint32_t>(t.ext.gen_attr.snoop) << ", "
			<< ".domain: " << static_cast<uint32_t>(t.ext.gen_attr.domain) << ", "
			<< ".barrier: " << t.ext.gen_attr.barrier
			<< " }, ";
		return out;
	}

	DataTransfer(const DataTransfer& rhs) :
		addr(rhs.addr),
		cmd(rhs.cmd),
		data(nullptr),
		length(rhs.length),
		byte_enable(nullptr),
		byte_enable_length(rhs.byte_enable_length),
		streaming_width(rhs.streaming_width),
		expect(nullptr),
		// Always copy onto heap since we don't know the scope of the
		// the rhs.
		on_heap(true)
	{
		if (rhs.data) {
			data = new unsigned char[rhs.length];
			memcpy((void *) data, rhs.data, rhs.length);
		}

		if (rhs.byte_enable) {
			byte_enable = new unsigned char[rhs.byte_enable_length];
			memcpy((void *) byte_enable, rhs.byte_enable, rhs.byte_enable_length);
		}

		if (rhs.expect) {
			expect = new unsigned char[rhs.length];
			memcpy((void *) expect, rhs.expect, rhs.length);
		}

		this->ext = rhs.ext;
	}
};

typedef std::vector<DataTransfer> DataTransferVec;
typedef std::vector<DataTransfer>::iterator DataTransferIt;


#endif /* DATA_TRANSFER_H__ */
