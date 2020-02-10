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
 * References:
 *
 * [1] AMBA 5 CHI Architecture Specification, ARM IHI 0050C, ID050218
 *
 */

#ifndef TLM_BRIDGES_AMBA_CHI_H__
#define TLM_BRIDGES_AMBA_CHI_H__

namespace AMBA {
namespace CHI {

enum {
	CACHELINE_SZ = 64,
};

namespace Req {
	enum {
		ReqLCrdReturn = 0x00,
		ReadShared = 0x01,
		ReadClean = 0x02,
		ReadOnce = 0x03,
		ReadNoSnp = 0x04,
		PCrdReturn = 0x05,
		ReadUnique = 0x07,
		CleanShared = 0x08,
		CleanInvalid = 0x09,
		MakeInvalid = 0x0A,
		CleanUnique = 0x0B,
		MakeUnique = 0x0C,
		Evict = 0x0D,

		ReadNoSnpSep = 0x11,

		DVMOp = 0x14,

		WriteEvictFull = 0x15,
		WriteCleanFull = 0x17,
		WriteUniquePtl = 0x18,
		WriteUniqueFull = 0x19,

		WriteBackPtl = 0x1A,
		WriteBackFull = 0x1B,
		WriteNoSnpPtl = 0x1C,
		WriteNoSnpFull = 0x1D,

		WriteUniqueFullStash = 0x20,
		WriteUniquePtlStash = 0x21,
		StashOnceShared = 0x22,
		StashOnceUnique = 0x23,
		ReadOnceCleanInvalid = 0x24,
		ReadOnceMakeInvalid = 0x25,
		ReadNotSharedDirty = 0x26,
		CleanSharedPersist = 0x27,

		// 0x28 - 0x2F AtomicStore
		AtomicStore = 0x28,

		// 0x30 - 0x37 AtomicLoad
		AtomicLoad = 0x30,

		AtomicSwap = 0x38,
		AtomicCompare = 0x39,
		PrefetchTgt = 0x3A,
	};

	// Sub-opcodes for AtomicLoad and AtomicStore
	namespace Atomic {
		enum {
			ADD = 000,
			CLR = 001,
			EOR = 010,
			SET = 011,
			SMAX = 100,
			SMIN = 101,
			UMAX = 110,
			UMIN = 111,
		};
	};

	// Static flit field widths
	enum {
		QoS_Width = 4,
		TxnID_Width = 8,
		StashNIDValid_Endian_Width= 1,
		ReturnTxnID_Width = 8,
		Opcode_Width = 6,
		Size_Width = 3,
		NS_Width = 1,
		LikelyShared_Width = 1,
		AllowRetry_Width = 1,
		Order_Width = 2,
		PCrdType_Width = 4,
		MemAttr_Width = 4,
		SnpAttr_Width = 1,
		LPID_Width = 5,
		ExclSnoopMe_Width = 1,
		ExpCompAck_Width = 1,
		TraceTag_Width = 1,
	};

	// Size field values
	namespace Size {
		enum {
			SZ_8 = 0x3,
			SZ_32 = 0x5,
			Reserved = 0x7,
		};
	};
};

namespace Rsp {
	enum {
		RespLCrdReturn = 0x0,
		SnpResp = 0x1,
		CompAck = 0x2,
		RetryAck = 0x3,
		Comp = 0x4,
		CompDBIDResp = 0x5,
		DBIDResp = 0x6,
		PCrdGrant = 0x7,
		ReadReceipt = 0x8,
		SnpRespFwded = 0x9,
		RespSepData = 0xB,
	};

	// Static flit field widths
	enum {
		QoS_Width = 4,
		TxnID_Width = 8,
		Opcode_Width = 4,
		RespErr_Width = 2,
		Resp_Width = 3,
		FwdState_DataPull_Width = 3,
		DBID_Width = 8,
		PCrdType_Width = 4,
		TraceTag_Width = 1,
	};
};

namespace Snp {
	enum {
		SnpLCrdReturn = 0x00,
		SnpShared = 0x01,
		SnpClean = 0x02,
		SnpOnce = 0x03,
		SnpNotSharedDirty = 0x04,
		SnpUniqueStash = 0x05,
		SnpMakeInvalidStash = 0x06,
		SnpUnique = 0x07,
		SnpCleanShared = 0x08,
		SnpCleanInvalid = 0x09,
		SnpMakeInvalid = 0x0A,
		SnpStashUnique = 0x0B,
		SnpStashShared = 0x0C,
		SnpDVMOp = 0x0D,
		SnpSharedFwd = 0x11,
		SnpCleanFwd = 0x12,
		SnpOnceFwd = 0x13,
		SnpNotSharedDirtyFwd = 0x14,
		SnpUniqueFwd = 0x17,
	};

	// Static flit field widths
	enum {
		QoS_Width = 4,
		TxnID_Width = 8,
		FwdTxnID_Width = 8,
		Opcode_Width = 5,
		NS_Width = 1,
		DoNotGoToSD_Width = 1,
		RetToSrc_Width = 1,
		TraceTag_Width = 1,
	};
};

namespace Dat {
	enum {
		DataLCrdReturn = 0x0,
		SnpRespData = 0x1,
		CopyBackWrData = 0x2,
		NonCopyBackWrData = 0x3,
		CompData = 0x4,
		SnpRespDataPtl = 0x5,
		SnpRespDataFwded = 0x6,
		WriteDataCancel = 0x7,
		DataSepResp = 0xB,
		NCBWrDataCompAck = 0xC,
	};

	// Static flit field widths
	enum {
		QoS_Width = 4,
		TxnID_Width = 8,
		Opcode_Width = 4,
		RespErr_Width = 2,
		Resp_Width = 3,
		FwdState_DataPull_DataSource_Width = 3,
		DBID_Width = 8,
		CCID_Width = 2,
		DataID_Width = 2,
		TraceTag_Width = 1,

		// Width prior Issue C
		Opcode_Width_3 = 3,
	};
};

// Field Resp
namespace Resp {
	enum {
		// Table 4-4
		DataSepResp_UC = 0x2,
		DataSepResp_SC = 0x1,
		DataSepResp_I = 0x0,

		// Table 4-4
		CompData_SD_PD = 0x7,
		CompData_UD_PD = 0x6,
		CompData_UC = 0x2,
		CompData_SC = 0x1,
		CompData_I = 0x0,

		// Table 4-5
		Comp_UC = 0x2,
		Comp_SC = 0x1,
		Comp_I = 0x0,

		// Table 4-6, 4.5.2 [1]
		NonCopyBackWrData = 0x0,
		CopyBackWrData_SD_PD = 0x7,
		CopyBackWrData_SC = 0x1,
		CopyBackWrData_UD_PD = 0x6,
		CopyBackWrData_UC = 0x2,
		CopyBackWrData_I = 0x0,
	};
};

// Field RespErr
namespace RespErr {
	enum {
		// Table 12.39, 12.9.38 [1]
		Okay = 0x0,
		ExclusiveOkay = 0x1,
		DataError = 0x2,
		NonDataError = 0x3,
	};
}

namespace DVM {
	enum {
		DVMOpSize = 0x3,
		PacketNumShift = 3, // In the request's address

		// DVM operations
		TLBI = 0x0,
		BranchPredictorInvalidate = 0x1,
		PICI = 0x2,
		VICI = 0x3,
		Sync = 0x4,

		//
		// Address bits with information [40:4] (37 bits), 8.2.2 [1]
		//
		AddressBits = 37,

		DVMOpMask = 0x7,
		DVMOpShift = 11,

		DVMVAValidMask = 0x1,
		DVMVAValidShift = 4,
	};
};

}; // namespace CHI
}; // namespace AMBA

#endif /* TLM_BRIDGES_AMBA_CHI_H__ */
