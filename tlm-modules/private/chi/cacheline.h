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
 *
 *
 * This file contains common classes used by the request nodes (RN-F, RN-D
 * and RN-I).
 *
 * References:
 *
 * [1] AMBA 5 CHI Architecture Specification, ARM IHI 0050C, ID050218
 *
 */

#ifndef TLM_MODULES_PRIV_CHI_CACHELINE_H__
#define TLM_MODULES_PRIV_CHI_CACHELINE_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/chiattr.h"
#include "tlm-bridges/amba-chi.h"

enum CacheLineStatus { INV = 0, UC, UCE, UD, UDP, SC, SD };

namespace AMBA {
namespace CHI {
namespace RN {

class CacheLine
{
public:
	CacheLine() :
		valid(false),
		tag(0),
		shared(false),
		dirty(false)
	{
		memset(byteEnable, TLM_BYTE_ENABLED, sizeof(byteEnable));
	}

	void Write(unsigned int offset,
			unsigned char *srcData,
			unsigned int len,
			unsigned char *be = NULL,
			unsigned int be_len = 0,
			unsigned int pos = 0)
	{
		if (be_len) {
			unsigned int i;

			for (i = 0; i < len; i++, pos++) {
				bool do_access = be[pos % be_len] == TLM_BYTE_ENABLED;

				if (do_access) {
					data[offset + i] = srcData[i];
					byteEnable[offset + i] = TLM_BYTE_ENABLED;
				}
			}
		} else {
			memcpy(&data[offset], srcData, len);
			memset(&byteEnable[offset], TLM_BYTE_ENABLED, len);
		}
	}

	void ByteEnablesDisableAll()
	{
		//
		// The data byte must be zero the corresponding byte enable is
		// zero 2.10.3 [1]
		//
		memset(data, 0, sizeof(data));
		memset(byteEnable, TLM_BYTE_DISABLED, sizeof(byteEnable));
		dirty = false;
	}

	void ByteEnablesEnableAll()
	{
		memset(byteEnable, TLM_BYTE_ENABLED, sizeof(byteEnable));
	}

	enum EmptyPartialFull { Empty, Partial, Full };

	EmptyPartialFull GetFillGrade()
	{
		unsigned int numEnabled = 0;
		unsigned int i;

		for (i = 0; i < CACHELINE_SZ; i++) {
			if (byteEnable[i] == TLM_BYTE_ENABLED) {
				numEnabled++;
			}
		}

		if (numEnabled == CACHELINE_SZ) {
			return Full;
		} else if (numEnabled > 0) {
			return Partial;
		}
		return Empty;
	}

	CacheLineStatus GetStatus()
	{
		if (valid) {
			if (shared && dirty) {
				return SD;
			} else if (shared && !dirty) {
				return SC;
			} else {
				EmptyPartialFull state =
					GetFillGrade();

				if (state == Full) {
					if (dirty) {
						return UD;
					} else {
						return UC;
					}
				} else if (state == Partial) {
					assert(dirty);
					return UDP;
				} else if (state == Empty) {
					assert(!dirty);
					return UCE;
				}
			}
		}
		return INV;
	}

	bool IsClean()
	{
		EmptyPartialFull state = GetFillGrade();

		if (!dirty) {
			assert(state == Empty || state == Full);
		}

		return !dirty;
	}

	bool IsUniqueCleanFull()
	{
		EmptyPartialFull state = GetFillGrade();

		return !dirty && state == Full;
	}

	bool IsDirtyPartial()
	{
		EmptyPartialFull state = GetFillGrade();

		return dirty && state == Partial;
	}

	bool IsDirtyFull()
	{
		EmptyPartialFull state = GetFillGrade();

		return dirty && state == Full;
	}

	bool IsDirty()
	{
		EmptyPartialFull state = GetFillGrade();

		if (dirty) {
			assert(state == Partial || state == Full);
		}

		return dirty;
	}

	bool IsValid() { return valid; }
	void SetValid(bool val) { valid = val; }

	chiattr_extension *GetCHIAttr() { return &m_chiattr; }
	void SetCHIAttr(chiattr_extension *attr)
	{
		m_chiattr.copy_from(*attr);
	}

	void SetTag(uint64_t val) { tag = val; }
	uint64_t GetTag() { return tag; }

	void SetShared(bool val) { shared = val; }
	bool GetShared() { return shared; }

	void SetDirty(bool val) { dirty = val; }
	bool GetDirty() { return dirty; }

	bool GetNonSecure() { return m_chiattr.GetNonSecure(); }

	uint8_t *GetData() { return data; }
	uint8_t *GetByteEnables() { return byteEnable; }

private:
	bool valid;
	uint64_t tag;
	bool shared;
	bool dirty;

	unsigned char data[CACHELINE_SZ];
	unsigned char byteEnable[CACHELINE_SZ];

	chiattr_extension m_chiattr;
};

} /* namespace RN */
} /* namespace CHI */
} /* namespace AMBA */

#endif /* TLM_MODULES_PRIV_CHI_CACHELINE_H__ */
