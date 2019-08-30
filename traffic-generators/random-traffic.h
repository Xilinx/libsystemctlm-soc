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
#ifndef RANDOMTRAFFIC_H_
#define RANDOMTRAFFIC_H_

#include <stdlib.h>
#include "itraffic-desc.h"

#ifndef MIN
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

class RandomTraffic : public ITrafficDesc
{
public:
	RandomTraffic(uint64_t minAddress,
			uint64_t maxAddress,
			uint64_t addressMask,
			uint32_t minDataLen,
			uint32_t maxDataLen,
			uint32_t maxByteEnablesLen,
			uint32_t numTransfers,
			unsigned int seed = 0) :
		m_minAddress(minAddress),
		m_maxAddress(maxAddress),
		m_addressMask(addressMask),
		m_minDataLen(minDataLen),
		m_maxDataLen(maxDataLen),
		m_minStreamingWidthLen(0),
		m_maxStreamingWidthLen(maxDataLen),
		m_maxByteEnablesLen(maxByteEnablesLen),
		m_data(new uint8_t[maxDataLen]),
		m_byte_enables(new uint8_t[maxDataLen]),
		m_numTransfers(numTransfers),
		m_last_write(false),
		m_seed(seed),
		hasAddrLen(false)
	{}

	~RandomTraffic()
	{
		delete[] m_data;
	}

	virtual tlm::tlm_command getCmd()
	{
		tlm::tlm_command cmd;

		if (m_last_write) {
			m_last_write = false;
			return tlm::TLM_READ_COMMAND;
		}

		cmd = (rand_r(&m_seed) % 2) ?
			tlm::TLM_WRITE_COMMAND : tlm::TLM_READ_COMMAND;

		m_last_write = cmd == tlm::TLM_WRITE_COMMAND;
		return cmd;
	}

	virtual uint64_t getAddress()
	{
		if (!hasAddrLen)
			genAddrLen();
		return address;
	}

	virtual unsigned char *getData() {
		unsigned int i;
		uint32_t v = 0;

		if (!hasAddrLen)
			genAddrLen();

		// FIXME: Do something faster?
		for (i = 0; i < len; i++) {
			v = v ? v : rand_r(&m_seed);
			m_data[i] = v;
			v >>= 8;
		}
		return m_data;
	}
	virtual uint32_t getDataLength()
	{
		if (!hasAddrLen)
			genAddrLen();
		return len;
	}

	virtual unsigned char *getByteEnable() {
		unsigned int i;
		uint32_t v = 0;

		if (!hasAddrLen)
			genAddrLen();

		// FIXME: Do something faster?
		for (i = 0; i < be_len; i++) {
			v = v ? v : rand_r(&m_seed);
			m_byte_enables[i] = v & 1 ? TLM_BYTE_ENABLED : 0;
			v >>= 1;
		}
		return be_len ? m_byte_enables : nullptr;
	}
	virtual uint32_t getByteEnableLength() {
		if (!hasAddrLen)
			genAddrLen();

		return be_len;
	}

	virtual uint32_t getStreamingWidth() {
		if (!hasAddrLen)
			genAddrLen();

		return sw_len;
	};

	virtual unsigned char *getExpect() { return nullptr; }

	virtual void setExtensions(tlm::tlm_generic_payload *gp) {}

	virtual bool done() { return (m_numTransfers == 0); }
	virtual void next() {
		if (!m_last_write) {
			hasAddrLen = false;
		} else {
			be_len = 0;
			sw_len = len;
		}
		m_numTransfers--;
	}

	void setSeed(unsigned int seed) { m_seed = seed; }
	unsigned int getSeed() { return m_seed; }

	void setMinStreamingWidthLen(uint32_t len) { m_minStreamingWidthLen = len; }
	uint32_t getMinStreamingWidthLen(void) { return m_minStreamingWidthLen; }

	void setMaxStreamingWidthLen(uint32_t len) { m_maxStreamingWidthLen = len; }
	uint32_t getMaxStreamingWidthLen(void) { return m_maxStreamingWidthLen; }

private:
	uint64_t m_minAddress;
	uint64_t m_maxAddress;
	uint64_t m_addressMask;
	uint32_t m_minDataLen;
	uint32_t m_maxDataLen;
	uint32_t m_minStreamingWidthLen;
	uint32_t m_maxStreamingWidthLen;
	uint32_t m_maxByteEnablesLen;
	uint8_t *m_data;
	uint8_t *m_byte_enables;
	uint32_t m_numTransfers;
	bool m_last_write;

	unsigned int m_seed;

	bool hasAddrLen;
	uint64_t address;
	uint32_t len;
	uint32_t be_len;
	uint32_t sw_len;

	// Coordinated Address and Len generation.
	// We need to make sure that address + len does not exceed m_maxAddress.
	void genAddrLen(void) {
		uint32_t max_len = m_maxDataLen;
		uint32_t max_be_len;
		bool has_be;
		bool has_sw;

		address = (m_minAddress +
					(rand_r(&m_seed) % (m_maxAddress-m_minAddress)));
		address &= m_addressMask;

		// Need to cap length to stay within address-bounds.
		max_len = MIN(max_len, m_maxAddress - address);

		len = rand_r(&m_seed) % max_len;
		len = (len > m_minDataLen) ? len : m_minDataLen;
		hasAddrLen = true;

		be_len = 0;
		if (m_maxByteEnablesLen) {
			has_be = rand_r(&m_seed) & 1;
			max_be_len = MIN(m_maxByteEnablesLen, len);
			be_len = has_be ? rand_r(&m_seed) % max_be_len : 0;
		}

		// If has_sw turns out to be true, create a streaming-width smaller than length
		has_sw = rand_r(&m_seed) & 1;
		sw_len = has_sw ? rand_r(&m_seed) % len : len;
		if (sw_len < m_minStreamingWidthLen) {
			sw_len = m_minStreamingWidthLen;
		}
		if (sw_len > m_maxStreamingWidthLen) {
			sw_len = m_maxStreamingWidthLen;
		}

		// sw_len zero is not allowed.
		sw_len = sw_len ? sw_len : len;
	}
};
#endif
