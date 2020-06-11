/*
 * Copyright (c) 2020 Xilinx Inc.
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
 */

#ifndef TLM_BRIDGES_CCIX_H__
#define TLM_BRIDGES_CCIX_H__

namespace CCIX {

namespace Msg {
	namespace Type {
		enum {
			Req = 0x1,
			SnpReq = 0x2,
			MiscCredited = 0x3,
			Resp = 0x9,
			SnpResp = 0xA,
			MiscUnCredited = 0xB,
		};
	};

	namespace Req {
		enum {
			Ext0_Width = 1,
			MsgType_Width = 4,
			MsgLen_Width = 5,
			TxnID_Width = 12,
			Rsvd0_Width = 2,
			ReqOp_Width = 8,

			Ext1_Width = 1,
			ExtType_Width = 3,
			Rsvd1_Width = 28,

			ReqAttr_Width = 8,
			Rsvd2_Width = 4,
			Address_51_32_Width = 20,

			Address_31_6_Width = 26,
			Rsvd3_Width = 1,
			NS_Width = 1,
			QoS_Width = 4
		};
	};

	namespace ReqOp {
		enum {
			ReadNoSnp = 0x00,
			ReadOnce = 0x01,
			ReadOnceCleanInvalid = 0x02,
			ReadOnceMakeInvalid = 0x03,
			ReadUnique = 0x04,
			ReadClean = 0x05,
			ReadNotSharedDirty = 0x06,
			ReadShared = 0x07,

			CleanUnique = 0x10,
			MakeUnique = 0x11,
			Evict = 0x13,
			CleanShared = 0x14,
			CleanSharedPersist = 0x15,
			CleanInvalid = 0x16,
			MakeInvalid = 0x17,

			CleanSharedSnpMe = 0x94,
			CleanSharedPersistSnpMe = 0x95,
			CleanInvalidSnpMe = 0x96,
			MakeInvalidSnpMe = 0x97,

			WriteNoSnpPtl = 0x20,
			WriteNoSnpFull = 0x21,
			WriteUniquePtl = 0x22,
			WriteUniqueFull = 0x23,
			WriteBackPtl = 0x24,
			WriteBackFullUD = 0x25,
			WriteBackFullSD = 0x27,
			WriteCleanFullSD = 0x2B,
			WriteEvictFull = 0x2D,

			AtomicStore = 0x40,		// 0x4X
			AtomicLoad = 0x50,		// 0x5X
			AtomicSwap = 0x60,
			AtomicCompare = 0x61,
			AtomicStoreSnpMe = 0xC0,	// 0xCX
			AtomicLoadSnpMe = 0xD0,		// 0xDX
			AtomicSwapSnpMe = 0xE0,
			AtomicCompareSnpMe = 0xE1,

			ReqChain = 0xF0
		};
	};

	namespace RespOp {
		enum {
			NOP = 0x0,
			CreditGrant = 0x1,
			CreditReturn = 0x2,
			ProtError = 0x3,

			Generic = 0x8,
		};
	};

	namespace MiscOp {
		enum {
			NOP = 0x0,
			CreditGrant = 0x1,
			CreditReturn = 0x2,
			ProtError = 0x3,

			Generic = 0x8,
		};
	};

	namespace SnpOp {
		enum {
			SnpToAny = 0x0,
			SnpToC = 0x1,
			SnpToS = 0x2,
			SnpToSC = 0x3,
			SnpToI = 0x4,
			SnpToMakeI = 0x5,

			SnpChain = 0x7,
		};
	};

	namespace Ext {
		enum {
			Type_0 = 0,
			Type_1 = 1,
			Type_2 = 2,
			Type_6 = 6,
		};
	};
};

}; // namespace CCIX

#endif /* TLM_BRIDGES_CCIX_H__ */
