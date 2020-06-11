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
#ifndef UTILS_CHI_H__
#define UTILS_CHI_H__

#include <string.h>
#include "tlm-bridges/amba-chi.h"

namespace utils {
namespace CHI {

enum : uint32_t {
	BYTE_ENABLE = 0xFFFF0001,
	STREAMING_WIDTH = 0xFFFF0002,
	EXPECT = 0xFFFF0003,
	EXT_GEN_ATTR = 0xFFFF0004
};

struct CHITransfer {

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

	enum { MaxDataSize = 32 };
	struct {
		struct {
			bool enabled;
			uint8_t opcode;
			bool exclusive;
			bool secure;
			bool snoopme;
			uint8_t data[MaxDataSize];
		} chiattr;
	} ext;

	bool on_heap;

	CHITransfer(bool _on_heap = false) :
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
		ext.chiattr = {};
	}

	// Move C'actor
	CHITransfer(CHITransfer&& other) :
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

	~CHITransfer()
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

	CHITransfer(const CHITransfer& rhs) :
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

typedef std::vector<CHITransfer> CHITransferVec;
typedef std::vector<CHITransfer>::iterator CHITransferIt;

CHITransferVec merge(CHITransferVec transfers)
{
	CHITransferVec merged_transfers;

	for (auto& t : transfers) {
		if (merged_transfers.size() > 0) {
			CHITransfer& last = merged_transfers.back();

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
				last.ext.chiattr = t.ext.chiattr;
			}
		}

		if (t.cmd == CHITransfer::READ ||
				t.cmd == CHITransfer::WRITE ||
				t.cmd == CHITransfer::IGNORE ) {
			merged_transfers.push_back(t);
		}
	}

	return merged_transfers;
}

#define DATA(x...) ((const unsigned char[]) { x })

CHITransfer Expect(const unsigned char *expect, int length)
{
	CHITransfer t;
	t.cmd = EXPECT;
	t.expect = expect;
	t.length = length;
	return t;
}

CHITransfer Read(uint64_t address, unsigned int length = 4)
{
	CHITransfer t;
	t.cmd = CHITransfer::READ;
	t.addr = address;
	t.length = length;
	t.streaming_width = length;
	return t;
}

CHITransfer Write(uint64_t address, const unsigned char *data, unsigned int length = 4)
{
	CHITransfer t;
	t.cmd = CHITransfer::WRITE;
	t.addr = address;
	t.data = data;
	t.length = length;
	t.streaming_width = length;
	return t;
}

CHITransfer ByteEnable(const unsigned char *byte_enable,
                        unsigned int byte_enable_length)
{
	CHITransfer t;
	t.cmd = BYTE_ENABLE;
	t.byte_enable = byte_enable;
	t.byte_enable_length = byte_enable_length;
	return t;
}

CHITransfer StreamingWidth(unsigned int streaming_width)
{
	CHITransfer t;
	t.cmd = STREAMING_WIDTH;
	t.streaming_width = streaming_width;
	return t;
}

enum { AtomicOpMask = 0x7 };

CHITransfer AtomicStore(uint64_t address,
			const unsigned char *data,
			unsigned int length = 1,
			uint8_t opcode = 0)
{
	CHITransfer t;
	t.cmd = CHITransfer::WRITE;
	t.addr = address;
	t.data = data;
	t.length = length;
	t.streaming_width = length;
	t.ext.chiattr.enabled = true;
	t.ext.chiattr.opcode = Req::AtomicStore | (opcode & AtomicOpMask);
	t.ext.chiattr.snoopme = true;
	return t;
}

CHITransfer AtomicLoad(uint64_t address,
			const unsigned char *data,
			unsigned int length = 1,
			uint8_t opcode = 0)
{
	CHITransfer t;
	t.cmd = CHITransfer::READ;
	t.addr = address;
	t.length = length;
	t.streaming_width = length;
	t.ext.chiattr.enabled = true;
	t.ext.chiattr.opcode = Req::AtomicLoad | (opcode & AtomicOpMask);
	t.ext.chiattr.snoopme = true;
	memcpy(t.ext.chiattr.data, data, length);
	return t;
}

CHITransfer AtomicSwap(uint64_t address, const unsigned char *data, unsigned int length)
{
	CHITransfer t;
	t.cmd = CHITransfer::READ;
	t.addr = address;
	t.length = length;
	t.streaming_width = length;
	t.ext.chiattr.enabled = true;
	t.ext.chiattr.opcode = Req::AtomicSwap;
	t.ext.chiattr.snoopme = true;
	memcpy(t.ext.chiattr.data, data, length);
	return t;
}

CHITransfer AtomicCompare(uint64_t address, const unsigned char *data, unsigned int length)
{
	CHITransfer t;
	t.cmd = CHITransfer::READ;
	t.addr = address;
	t.length = length/2;
	t.streaming_width = length;
	t.ext.chiattr.enabled = true;
	t.ext.chiattr.opcode = Req::AtomicCompare;
	t.ext.chiattr.snoopme = true;
	memcpy(t.ext.chiattr.data, data, length);
	return t;
}

CHITransfer ExclusiveLoad(uint64_t address, unsigned int length = 4)
{
	CHITransfer t;
	t.cmd = CHITransfer::READ;
	t.addr = address;
	t.length = length;
	t.streaming_width = length;
	t.ext.chiattr.enabled = true;
	t.ext.chiattr.exclusive = true;
	return t;
}

CHITransfer ExclusiveStore(uint64_t address, const unsigned char *data, unsigned int length = 4)
{
	CHITransfer t;
	t.cmd = CHITransfer::WRITE;
	t.addr = address;
	t.data = data;
	t.length = length;
	t.streaming_width = length;
	t.ext.chiattr.enabled = true;
	t.ext.chiattr.exclusive = true;
	return t;
}

CHITransfer DVMOperation(uint64_t address,
			const unsigned char *data = NULL,
			unsigned int length = 0)
{
	static const uint8_t dummy[8] = { 0 };
	CHITransfer t;

	t.cmd = CHITransfer::IGNORE;
	t.addr = address;
	t.length = DVM::DVMOpSize;
	t.data = dummy;
	t.streaming_width = length;
	t.ext.chiattr.enabled = true;
	t.ext.chiattr.opcode = Req::DVMOp;
	t.ext.chiattr.snoopme = true;
	t.ext.chiattr.secure = true;

	if (data) {
		if (length >= DVM::DVMOpSize) {
			length = DVM::DVMOpSize;
		}

		memcpy(t.ext.chiattr.data, data, length);
	}

	return t;
}

class TrafficDesc : public ITrafficDesc
{
public:
	TrafficDesc(const CHITransferVec& transfers) :
		m_transfers(transfers),
		m_it(m_transfers.begin())
	{}

	TrafficDesc(CHITransferVec&& transfers) :
		m_transfers(transfers),
		m_it(m_transfers.begin())
	{}

	~TrafficDesc()
	{}

	virtual tlm::tlm_command getCmd()
	{
		tlm::tlm_command cmd = tlm::TLM_IGNORE_COMMAND;

		if ((*m_it).cmd == CHITransfer::WRITE) {
			cmd = tlm::TLM_WRITE_COMMAND;
		} else if ((*m_it).cmd == CHITransfer::READ) {
			cmd = tlm::TLM_READ_COMMAND;
		}

		return cmd;
	}

	virtual uint64_t getAddress() { return (*m_it).addr; }

	virtual unsigned char *getData()
	{
		return const_cast<unsigned char*>((*m_it).data);
	}

	virtual uint32_t getDataLength() { return (*m_it).length; }

	virtual unsigned char *getByteEnable()
	{
		return const_cast<unsigned char*>((*m_it).byte_enable);
	}

	virtual uint32_t getByteEnableLength()
	{
		return (*m_it).byte_enable_length;
	}

	virtual uint32_t getStreamingWidth() { return (*m_it).streaming_width; }

	virtual unsigned char *getExpect()
	{
		return const_cast<unsigned char*>((*m_it).expect);
	}

	virtual void setExtensions(tlm::tlm_generic_payload *gp)
	{
		CHITransfer& t = (*m_it);

		if (t.ext.chiattr.enabled) {
			chiattr_extension *attr = new chiattr_extension();

			attr->SetOpcode(t.ext.chiattr.opcode);

			if (t.ext.chiattr.exclusive || t.ext.chiattr.snoopme) {
				attr->SetExcl_SnoopMe(true);

				if (t.ext.chiattr.snoopme) {
					attr->SetSnpAttr(true);
				}
			}

			attr->SetNonSecure(!t.ext.chiattr.secure);

			memcpy(attr->GetData(),
				t.ext.chiattr.data,
				CHITransfer::MaxDataSize);

			gp->set_extension(attr);
		}
	}

	virtual bool done() { return m_it == m_transfers.end(); }
	virtual void next() { m_it++; }

private:
	CHITransferVec m_transfers;
	CHITransferIt  m_it;
};

}

}

#endif
