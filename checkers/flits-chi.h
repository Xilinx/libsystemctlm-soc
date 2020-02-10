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

#ifndef CHECKER_FLITS_CHI_H__
#define CHECKER_FLITS_CHI_H__

namespace AMBA {
namespace CHI {
namespace CHECKERS {

template<
	int ADDR_WIDTH,
	int NODEID_WIDTH,
	int RSVDC_WIDTH>
class ReqFlit
{
public:
	//
	// Flit field widths
	//
	enum {
		QoS_Width 	= Req::QoS_Width,
		TgtID_Width 	= NODEID_WIDTH,
		SrcID_Width 	= NODEID_WIDTH,
		TxnID_Width 	= Req::TxnID_Width,

		ReturnNID_StashNID_Width = NODEID_WIDTH,
		StashNIDValid_Endian_Width = Req::StashNIDValid_Endian_Width,
		ReturnTxnID_Width = Req::ReturnTxnID_Width,

		Opcode_Width 	= Req::Opcode_Width,
		Size_Width 	= Req::Size_Width,
		Addr_Width 	= ADDR_WIDTH,
		NS_Width 	= Req::NS_Width,

		LikelyShared_Width = Req::LikelyShared_Width,
		AllowRetry_Width = Req::AllowRetry_Width,

		Order_Width 	= Req::Order_Width,
		PCrdType_Width 	= Req::PCrdType_Width,
		MemAttr_Width 	= Req::MemAttr_Width,
		SnpAttr_Width 	= Req::SnpAttr_Width,
		LPID_Width 	= Req::LPID_Width,

		ExclSnoopMe_Width = Req::ExclSnoopMe_Width,
		ExpCompAck_Width = Req::ExpCompAck_Width,

		TraceTag_Width 	= Req::TraceTag_Width,
		RSVDC_Width 	= RSVDC_WIDTH,

		// Sum of above
		FLIT_WIDTH =
			QoS_Width +
			TgtID_Width +
			SrcID_Width +
			TxnID_Width +
			ReturnNID_StashNID_Width +
			StashNIDValid_Endian_Width+
			ReturnTxnID_Width +
			Opcode_Width +
			Size_Width +
			Addr_Width +
			NS_Width +
			LikelyShared_Width +
			AllowRetry_Width +
			Order_Width +
			PCrdType_Width +
			MemAttr_Width +
			SnpAttr_Width +
			LPID_Width +
			ExclSnoopMe_Width +
			ExpCompAck_Width +
			TraceTag_Width +
			RSVDC_Width,
	};

	ReqFlit(sc_bv<FLIT_WIDTH>& flit) :
		m_RSVDC(0),
		m_pos(0)
	{
		// Init all fields except above
		ParseFlit(flit);
	}

	uint8_t GetQoS() { return m_QoS; }
	uint16_t GetTgtID() { return m_TgtID; }
	uint16_t GetSrcID() { return m_SrcID; }
	uint16_t GetTxnID() { return m_TxnID; }

	uint16_t GetReturnNID() { return m_ReturnNID_StashNID; }

	bool GetStashNIDValid() { return m_StashNIDValid_Endian; }

	bool GetReturnTxnID() { return m_ReturnTxnID; }

	uint8_t GetOpcode() { return m_Opcode; }
	uint8_t GetSize() { return m_Size; }

	uint64_t GetAddress() { return m_Address; }

	bool GetNonSecure() { return m_NonSecure; }
	bool GetLikelyShared() { return m_LikelyShared; }
	bool GetAllowRetry() { return m_AllowRetry; }
	uint8_t GetOrder() { return m_Order; }
	uint8_t GetPCrdType() { return m_PCrdType; }

	bool GetAllocate() { return m_Allocate; }
	bool GetCacheable() { return m_Cacheable; }
	bool GetDeviceMemory() { return m_DeviceMemory; }
	bool GetEarlyWrAck() { return m_EarlyWrAck; }

	bool GetSnpAttr() { return m_SnpAttr; }

	uint16_t GetLPID() { return m_LPID; }

	bool GetExcl() { return m_Excl_SnoopMe; }

	bool GetExpCompAck() { return m_ExpCompAck; }
	bool GetTraceTag() { return m_TraceTag; }

	uint32_t GetRSVDC() { return m_RSVDC; }

	void Dump(std::ostringstream& msg)
	{
		msg << " { " << hex
			<< "m_QoS: 0x" << static_cast<uint32_t>(m_QoS)
			<< ", m_TgtID: 0x" << m_TgtID
			<< ", m_SrcID: 0x" << m_SrcID
			<< ", m_TxnID: 0x" << static_cast<uint32_t>(m_TxnID)
			<< ", m_ReturnNID_StashNID: 0x" << m_ReturnNID_StashNID
			<< ", m_StashNIDValid_Endian: 0x" << m_StashNIDValid_Endian
			<< ", m_ReturnTxnID: 0x" << static_cast<uint32_t>(m_ReturnTxnID)
			<< ", m_Opcode: 0x" << static_cast<uint32_t>(m_Opcode)
			<< ", m_Size: 0x" << m_Size
			<< ", m_Address: 0x" << m_Address
			<< ", m_NonSecure: 0x" << m_NonSecure
			<< ", m_LikelyShared: 0x" << m_LikelyShared
			<< ", m_AllowRetry" << m_AllowRetry
			<< ", m_Order: 0x" << static_cast<uint32_t>(m_Order)
			<< ", m_PCrdType: 0x" << static_cast<uint32_t>(m_PCrdType)
			<< ", m_Allocate: 0x" << m_Allocate
			<< ", m_Cacheable: 0x" << m_Cacheable
			<< ", m_Devicemory: 0x" << m_DeviceMemory
			<< ", m_EarlyWrAck: 0x" << m_EarlyWrAck
			<< ", m_SnpAttr: 0x" << m_SnpAttr
			<< ", m_LPID: 0x" << m_LPID
			<< ", m_Excl_SnoopMe: 0x" << m_Excl_SnoopMe
			<< ", m_ExpCompAck: 0x" << m_ExpCompAck
			<< ", m_TraceTag: 0x" << m_TraceTag
			<< ", m_RSVDC: 0x" << m_RSVDC
			<< " } ";
	}

	bool IsRead()
	{
		switch (m_Opcode) {
		case Req::ReadNoSnp:
		case Req::ReadOnce:
		case Req::ReadOnceCleanInvalid:
		case Req::ReadOnceMakeInvalid:
		case Req::ReadClean:
		case Req::ReadNotSharedDirty:
		case Req::ReadShared:
		case Req::ReadUnique:
			return true;
		default:
			break;
		}
		return false;
	}

	bool IsDataless()
	{
		switch (m_Opcode) {
		case Req::CleanUnique:
		case Req::MakeUnique:
		case Req::Evict:
		case Req::StashOnceShared:
		case Req::StashOnceUnique:
		case Req::CleanShared:
		case Req::CleanSharedPersist:
		case Req::CleanInvalid:
		case Req::MakeInvalid:
			return true;
		default:
			break;
		}
		return false;
	}

	bool IsWrite()
	{
		switch (m_Opcode) {
		case Req::WriteNoSnpPtl:
		case Req::WriteNoSnpFull:
		case Req::WriteUniquePtl:
		case Req::WriteUniqueFull:
		case Req::WriteUniquePtlStash:
		case Req::WriteUniqueFullStash:
		case Req::WriteBackPtl:
		case Req::WriteBackFull:
		case Req::WriteEvictFull:
		case Req::WriteCleanFull:
			return true;
		default:
			break;
		}
		return false;
	}

	bool IsAtomicStore()
	{
		return m_Opcode >= Req::AtomicStore &&
				m_Opcode < Req::AtomicLoad;
	}

	bool IsAtomicCompare()
	{
		return m_Opcode == Req::AtomicCompare;
	}

	bool IsAtomic()
	{
		return m_Opcode >= Req::AtomicStore &&
				m_Opcode <= Req::AtomicCompare;
	}

	bool IsPCrdReturn()
	{
		return m_Opcode == Req::PCrdReturn;
	}

	bool IsDVMOp()
	{
		return m_Opcode == Req::DVMOp;
	}

	bool IsPrefetchTgt()
	{
		return m_Opcode == Req::PrefetchTgt;
	}

	bool IsReqLCrdReturn()
	{
		return m_Opcode == Req::ReqLCrdReturn && m_TxnID == 0;
	}
private:

	void ParseFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		m_QoS = Extract<uint8_t>(flit, QoS_Width);
		m_TgtID = Extract<uint16_t>(flit, TgtID_Width);
		m_SrcID = Extract<uint16_t>(flit, SrcID_Width);
		m_TxnID = Extract<uint16_t>(flit, TxnID_Width);

		m_ReturnNID_StashNID =
			Extract<uint16_t>(flit, ReturnNID_StashNID_Width);

		m_StashNIDValid_Endian = ExtractBool(flit);

		//
		// For stash transactions ReturnTxnID contains
		// { [7:6]: 0b00, StashLPIDValid[5], StashLPID[4:0] }
		//
		m_ReturnTxnID = Extract<uint8_t>(flit, ReturnTxnID_Width);

		m_Opcode = Extract<uint8_t>(flit, Opcode_Width);

		m_Size = Extract<uint8_t>(flit, Size_Width);

		m_Address = Extract<uint64_t>(flit, Addr_Width);

		m_NonSecure = ExtractBool(flit);
		m_LikelyShared = ExtractBool(flit);
		m_AllowRetry = ExtractBool(flit);
		m_Order = Extract<uint8_t>(flit, Order_Width);
		m_PCrdType = Extract<uint8_t>(flit, PCrdType_Width);

		ExtractMemAttr(Extract<uint8_t>(flit, MemAttr_Width));

		m_SnpAttr = ExtractBool(flit);

		m_LPID = Extract<uint16_t>(flit, LPID_Width);

		m_Excl_SnoopMe = ExtractBool(flit);

		m_ExpCompAck = ExtractBool(flit);
		m_TraceTag = ExtractBool(flit);

		if (RSVDC_WIDTH) {
			m_RSVDC =
				Extract<uint32_t>(flit, RSVDC_WIDTH);
		}
	}

	enum {
		AllocateShift = 3,
		CacheableShift = 2,
		DeviceMemoryShift = 1,
		EarlyWrAckShift = 0
	};

	void ExtractMemAttr(uint8_t memattr)
	{
		bool allocate = (memattr >> AllocateShift) & 0x1;
		bool cacheable = (memattr >> CacheableShift) & 0x1;
		bool devMem = (memattr >> DeviceMemoryShift) & 0x1;
		bool earlyWrAck = (memattr >> EarlyWrAckShift) & 0x1;

		m_Allocate = allocate;
		m_Cacheable = cacheable;
		m_DeviceMemory = devMem;
		m_EarlyWrAck = earlyWrAck;
	}

	template<typename T>
	T Extract(sc_bv<FLIT_WIDTH>& flit, unsigned int width)
	{
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + width - 1;
		uint64_t mask = (1 << width) - 1;
		uint64_t val;

		val = flit.range(lastbit, firstbit).to_uint64();

		m_pos += width;

		return (T)(val & mask);
	}

	bool ExtractBool(sc_bv<FLIT_WIDTH>& flit)
	{
		return flit.bit(m_pos++) == 1;
	}

	uint8_t m_QoS;
	uint16_t m_TgtID;
	uint16_t m_SrcID;
	uint8_t m_TxnID;

	uint16_t m_ReturnNID_StashNID;

	bool m_StashNIDValid_Endian;

	//
	// For stash transactions ReturnTxnID contains
	// { [7:6]: 0b00, StashLPIDValid[5], StashLPID[4:0] }
	//
	uint8_t m_ReturnTxnID;

	uint8_t m_Opcode;

	uint32_t m_Size;
	uint64_t m_Address;

	bool m_NonSecure;
	bool m_LikelyShared;
	bool m_AllowRetry;

	uint8_t m_Order;
	uint8_t m_PCrdType;

	// MemAttr
	bool m_Allocate;
	bool m_Cacheable;
	bool m_DeviceMemory;
	bool m_EarlyWrAck;

	bool m_SnpAttr;

	uint16_t m_LPID;

	bool m_Excl_SnoopMe;

	bool m_ExpCompAck;
	bool m_TraceTag;

	uint32_t m_RSVDC;

	unsigned int m_pos;
};

template<int NODEID_WIDTH>
class RspFlit
{
public:
	//
	// Flit field widths
	//
	enum {
		QoS_Width 	= Rsp::QoS_Width,
		TgtID_Width 	= NODEID_WIDTH,
		SrcID_Width 	= NODEID_WIDTH,
		TxnID_Width 	= Rsp::TxnID_Width,
		Opcode_Width 	= Rsp::Opcode_Width,
		RespErr_Width 	= Rsp::RespErr_Width,
		Resp_Width 	= Rsp::Resp_Width,

		FwdState_DataPull_Width = Rsp::FwdState_DataPull_Width,

		DBID_Width 	= Rsp::DBID_Width,
		PCrdType_Width 	= Rsp::PCrdType_Width,
		TraceTag_Width 	= Rsp::TraceTag_Width,


		// Sum of above
		FLIT_WIDTH =
			QoS_Width +
			TgtID_Width +
			SrcID_Width +
			TxnID_Width +
			Opcode_Width +
			RespErr_Width +
			Resp_Width +
			FwdState_DataPull_Width +
			DBID_Width +
			PCrdType_Width +
			TraceTag_Width,
	};

	RspFlit(sc_bv<FLIT_WIDTH>& flit) :
		m_pos(0)
	{
		// Init all fields except above
		ParseFlit(flit);
	}

	uint16_t GetTgtID() { return m_TgtID; }
	uint16_t GetSrcID() { return m_SrcID; }
	uint8_t GetTxnID() { return m_TxnID; }
	uint8_t GetDBID() { return m_DBID; }
	uint8_t GetPCrdType() { return m_PCrdType; }

	bool IsSnoopResponse()
	{
		switch (m_Opcode) {
		case Rsp::SnpResp:
		case Rsp::SnpRespFwded:
			return true;
		}
		return false;
	}

	bool IsRetryAck() { return m_Opcode == Rsp::RetryAck; }
	bool IsCompDBIDResp() { return m_Opcode == Rsp::CompDBIDResp; }
	bool IsComp() { return m_Opcode == Rsp::Comp; }
	bool IsDBIDResp() { return m_Opcode == Rsp::DBIDResp; }
	bool IsCompAck() { return m_Opcode == Rsp::CompAck; }
	bool IsRespSepData() { return m_Opcode == Rsp::RespSepData; }
	bool IsReadReceipt() { return m_Opcode == Rsp::ReadReceipt; }
	bool IsSnpRespFwded() { return m_Opcode == Rsp::SnpRespFwded; }
	bool IsSnpResp() { return m_Opcode == Rsp::SnpResp; }
	bool IsPCrdGrant() { return m_Opcode == Rsp::PCrdGrant; }

	uint8_t GetOpcode() { return m_Opcode; }

	bool GetDataPull() { return m_FwdState_DataPull & 0x1; }

	void Dump(std::ostringstream& msg)
	{
		msg << " { " << hex
			<< "m_QoS: 0x" << hex << static_cast<uint32_t>(m_QoS)
			<< ", m_TgtID: 0x" << m_TgtID
			<< ", m_SrcID: 0x" << m_SrcID
			<< ", m_TxnID: 0x" << static_cast<uint32_t>(m_TxnID)
			<< ", m_Opcode: 0x" << static_cast<uint32_t>(m_Opcode)
			<< ", m_RespErr: 0x" << static_cast<uint32_t>(m_RespErr)
			<< ", m_Resp: 0x" << static_cast<uint32_t>(m_Resp)

			<< ", m_FwdState_DataPull: 0x"
				<< static_cast<uint32_t>(m_FwdState_DataPull)

			<< ", m_DBID: 0x" << static_cast<uint32_t>(m_DBID)
			<< ", m_PCrdType: 0x"
				<< static_cast<uint32_t>(m_PCrdType)
			<< ", m_TraceTag: 0x" << m_TraceTag
			<< " } ";

	}

	bool IsLCrdReturn()
	{
		return m_Opcode == Rsp::RespLCrdReturn && m_TxnID == 0;
	}

private:
	template<typename T>
	T Extract(sc_bv<FLIT_WIDTH>& flit, unsigned int width)
	{
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + width - 1;
		uint64_t mask = (1 << width) - 1;
		uint64_t val;

		val = flit.range(lastbit, firstbit).to_uint64();

		m_pos += width;

		return (T)(val & mask);
	}

	bool ExtractBool(sc_bv<FLIT_WIDTH>& flit)
	{
		return flit.bit(m_pos++) == 1;
	}

	void ParseFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		m_QoS = Extract<uint8_t>(flit, QoS_Width);
		m_TgtID = Extract<uint16_t>(flit, TgtID_Width);
		m_SrcID = Extract<uint16_t>(flit, SrcID_Width);
		m_TxnID = Extract<uint8_t>(flit, TxnID_Width);
		m_Opcode = Extract<uint8_t>(flit, Opcode_Width);

		m_RespErr = Extract<uint8_t>(flit, RespErr_Width);
		m_Resp = Extract<uint8_t>(flit, Resp_Width);

		m_FwdState_DataPull =
			Extract<uint8_t>(flit, FwdState_DataPull_Width);

		m_DBID = Extract<uint8_t>(flit, DBID_Width);
		m_PCrdType = Extract<uint8_t>(flit,  PCrdType_Width);
		m_TraceTag = ExtractBool(flit);
	}

	uint8_t m_QoS;
	uint16_t m_TgtID;
	uint16_t m_SrcID;
	uint8_t m_TxnID;
	uint8_t m_Opcode;

	uint8_t m_RespErr;
	uint8_t m_Resp;

	uint8_t m_FwdState_DataPull;

	uint8_t m_DBID;
	uint8_t m_PCrdType;
	bool m_TraceTag;

	unsigned int m_pos;
};

template<
	int ADDR_WIDTH,
	int NODEID_WIDTH>
class SnpFlit
{
public:
	//
	// Flit field widths
	//
	enum {
		QoS_Width 	= Snp::QoS_Width,
		SrcID_Width 	= NODEID_WIDTH,
		TxnID_Width 	= Snp::TxnID_Width,
		FwdNID_Width 	= NODEID_WIDTH,
		FwdTxnID_Width 	= Snp::FwdTxnID_Width,
		Opcode_Width 	= Snp::Opcode_Width,
		Addr_Width 	= ADDR_WIDTH,
		NS_Width 	= Snp::NS_Width,

		DoNotGoToSD_Width = Snp::DoNotGoToSD_Width,

		RetToSrc_Width 	= Snp::RetToSrc_Width,
		TraceTag_Width 	= Snp::TraceTag_Width,


		// Sum of above
		FLIT_WIDTH =
			QoS_Width +
			SrcID_Width +
			TxnID_Width +
			FwdNID_Width +
			FwdTxnID_Width +
			Opcode_Width +
			Addr_Width +
			NS_Width +
			DoNotGoToSD_Width +
			RetToSrc_Width +
			TraceTag_Width,

	};

	SnpFlit(sc_bv<FLIT_WIDTH>& flit) :
		m_pos(0)
	{
		// Init all fields except above
		ParseFlit(flit);
	}


	uint8_t GetTxnID() { return m_TxnID; }
	uint16_t GetFwdNID() { return m_FwdNID; }
	uint8_t GetFwdTxnID() { return m_FwdTxnID; }

	bool IsSnpFwd()
	{
		switch (m_Opcode) {
		case Snp::SnpSharedFwd:
		case Snp::SnpCleanFwd:
		case Snp::SnpOnceFwd:
		case Snp::SnpNotSharedDirtyFwd:
		case Snp::SnpUniqueFwd:
			return true;
		default:
			break;
		}
		return false;
	}

	bool IsSnpStash()
	{
		switch (m_Opcode) {
		case Snp::SnpUniqueStash:
		case Snp::SnpMakeInvalidStash:
		case Snp::SnpStashUnique:
		case Snp::SnpStashShared:
			return true;
		default:
			break;
		}
		return false;
	}

	bool IsSnpDVMOp()
	{
		return m_Opcode == Snp::SnpDVMOp;
	}

	bool IsLCrdReturn()
	{
		return m_Opcode == Snp::SnpLCrdReturn && m_TxnID == 0;
	}

	uint8_t GetOpcode() { return m_Opcode; }
	bool GetNonSecure() { return m_NonSecure; }
	bool GetDoNotGoToSD() { return m_DoNotGoToSD; }
	bool GetRetToSrc() { return m_RetToSrc; }

	void Dump(std::ostringstream& msg)
	{
		msg << " { " << hex
			<< "m_QoS: 0x" << hex << static_cast<uint32_t>(m_QoS)
			<< ", m_SrcID: 0x" << m_SrcID
			<< ", m_TxnID: 0x" << static_cast<uint32_t>(m_TxnID)
			<< ", m_FwdNID: 0x" << m_FwdNID
			<< ", m_FwdNID: 0x" << static_cast<uint32_t>(m_FwdTxnID)
			<< ", m_Opcode: 0x" << static_cast<uint32_t>(m_Opcode)
			<< ", m_Address: 0x" << m_Address
			<< ", m_NonSecure: 0x" << m_NonSecure
			<< ", m_DoNotGoToSD: 0x" << m_DoNotGoToSD
			<< ", m_RetToSrc: 0x" << m_RetToSrc
			<< ", m_TraceTag: 0x" << m_TraceTag
			<< " } ";
	}

private:
	template<typename T>
	T Extract(sc_bv<FLIT_WIDTH>& flit, unsigned int width)
	{
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + width - 1;
		uint64_t mask = (1 << width) - 1;
		uint64_t val;

		val = flit.range(lastbit, firstbit).to_uint64();

		m_pos += width;

		return (T)(val & mask);
	}

	bool ExtractBool(sc_bv<FLIT_WIDTH>& flit)
	{
		return flit.bit(m_pos++) == 1;
	}

	void ParseFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		m_QoS = Extract<uint8_t>(flit, QoS_Width);
		m_SrcID = Extract<uint16_t>(flit, SrcID_Width);
		m_TxnID = Extract<uint8_t>(flit, TxnID_Width);
		m_FwdNID = Extract<uint16_t>(flit, FwdNID_Width);
		m_FwdTxnID = Extract<uint8_t>(flit, FwdTxnID_Width);
		m_Opcode = Extract<uint8_t>(flit, Opcode_Width);
		m_Address = Extract<uint64_t>(flit, Addr_Width) << 3;
		m_NonSecure = ExtractBool(flit);

		// Bit is also DoNotDataPull
		m_DoNotGoToSD = ExtractBool(flit);

		m_RetToSrc = ExtractBool(flit);
		m_TraceTag = ExtractBool(flit);
	}

	uint8_t m_QoS;
	uint16_t m_SrcID;
	uint8_t m_TxnID;
	uint16_t m_FwdNID;
	uint8_t m_FwdTxnID;
	uint8_t m_Opcode;
	uint64_t m_Address;
	bool m_NonSecure;

	// Bit is also DoNotDataPull
	bool m_DoNotGoToSD;

	bool m_RetToSrc;
	bool m_TraceTag;

	unsigned int m_pos;
};

template<
	int DATA_WIDTH,
	int NODEID_WIDTH,
	int RSVDC_WIDTH,
	int DATACHECK_WIDTH,
	int POISON_WIDTH,
	int DAT_OPCODE_WIDTH>
class DatFlit
{
public:
	//
	// Flit field widths
	//
	enum {
		QoS_Width 	= Dat::QoS_Width,
		TgtID_Width 	= NODEID_WIDTH,
		SrcID_Width 	= NODEID_WIDTH,
		TxnID_Width 	= Dat::TxnID_Width,
		HomeNID_Width 	= NODEID_WIDTH,
		Opcode_Width 	= DAT_OPCODE_WIDTH,
		RespErr_Width 	= Dat::RespErr_Width,
		Resp_Width 	= Dat::Resp_Width,

		FwdState_DataPull_DataSource_Width = 3,

		DBID_Width 	= Dat::DBID_Width,
		CCID_Width 	= Dat::CCID_Width,
		DataID_Width 	= Dat::DataID_Width,
		TraceTag_Width 	= Dat::TraceTag_Width,

		RSVDC_Width 	= RSVDC_WIDTH,
		BE_Width 	= DATA_WIDTH/8,
		Data_Width 	= DATA_WIDTH,
		DataCheck_Width = DATACHECK_WIDTH,
		Poison_Width 	= POISON_WIDTH,


		// Sum of above
		FLIT_WIDTH =
			QoS_Width +
			TgtID_Width +
			SrcID_Width +
			TxnID_Width +
			HomeNID_Width +
			Opcode_Width +
			RespErr_Width +
			Resp_Width +
			FwdState_DataPull_DataSource_Width +
			DBID_Width +
			CCID_Width +
			DataID_Width +
			TraceTag_Width +
			RSVDC_Width +
			BE_Width +
			Data_Width +
			DataCheck_Width +
			Poison_Width,
	};

	DatFlit(sc_bv<FLIT_WIDTH>& flit) :
		m_RSVDC(0),
		m_DataCheck(0),
		m_Poison(0),
		m_pos(0)
	{
		memset(m_data, 0x0, sizeof(m_data));
		memset(m_byteEnable,
			TLM_BYTE_DISABLED,
			sizeof(m_byteEnable));

		// Init all fields except above
		ParseFlit(flit);
	}

	uint16_t GetTgtID() { return m_TgtID; }
	uint16_t GetSrcID() { return m_SrcID; }
	uint16_t GetHomeNID() { return m_HomeNID; }

	uint8_t GetTxnID() { return m_TxnID; }
	uint8_t GetDBID() { return m_DBID; }

	bool IsSnoopResponse()
	{
		switch (m_Opcode) {
		case Dat::SnpRespData:
		case Dat::SnpRespDataPtl:
		case Dat::SnpRespDataFwded:
			return true;
		}
		return false;
	}

	bool IsCopyBackWrData() { return m_Opcode == Dat::CopyBackWrData; }
	bool IsNonCopyBackWrData() { return m_Opcode == Dat::NonCopyBackWrData; }
	bool IsNCBWrDataCompAck() { return m_Opcode == Dat::NCBWrDataCompAck; }
	bool IsCompData() { return m_Opcode == Dat::CompData; }
	bool IsDataSepResp() { return m_Opcode == Dat::DataSepResp; }
	bool IsSnpRespData() { return m_Opcode == Dat::SnpRespData; }
	bool IsSnpRespDataPtl() { return m_Opcode == Dat::SnpRespDataPtl; }
	bool IsSnpRespDataFwded() { return m_Opcode == Dat::SnpRespDataFwded; }

	uint8_t GetOpcode() { return m_Opcode; }

	bool GetDataPull() { return m_FwdState_DataPull_DataSource & 0x1; }

	void Dump(std::ostringstream& msg)
	{
		msg << " { " << hex
			<< "m_QoS: 0x" << hex << static_cast<uint32_t>(m_QoS)
			<< ", m_TgtID: 0x" << m_TgtID
			<< ", m_SrcID: 0x" << m_SrcID
			<< ", m_TxnID: 0x" << static_cast<uint32_t>(m_TxnID)
			<< ", m_HomeNID: 0x" << m_HomeNID
			<< ", m_Opcode: 0x" << static_cast<uint32_t>(m_Opcode)
			<< ", m_RespErr: 0x" << static_cast<uint32_t>(m_RespErr)
			<< ", m_Resp: 0x" << static_cast<uint32_t>(m_Resp)

			<< ", m_FwdState_DataPull_DataSource: 0x"
				<< static_cast<uint32_t>(m_FwdState_DataPull_DataSource)

			<< ", m_DBID: 0x" << static_cast<uint32_t>(m_DBID)
			<< ", m_CCID: 0x" << static_cast<uint32_t>(m_CCID)
			<< ", m_DataID: 0x" << static_cast<uint32_t>(m_DataID)
			<< ", m_TraceTag: 0x" << m_TraceTag
			<< ", m_RSVDC: 0x" << m_RSVDC
			<< ", m_DataCheck: 0x" << m_DataCheck
			<< ", m_Poison: 0x" << static_cast<uint32_t>(m_Poison)

			<< " } ";
	}

	bool IsLCrdReturn()
	{
		return m_Opcode == Dat::DataLCrdReturn && m_TxnID == 0;
	}

private:
	template<typename T>
	T Extract(sc_bv<FLIT_WIDTH>& flit, unsigned int width)
	{
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + width - 1;
		uint64_t mask = (1 << width) - 1;
		uint64_t val;

		val = flit.range(lastbit, firstbit).to_uint64();

		m_pos += width;

		return (T)(val & mask);
	}

	bool ExtractBool(sc_bv<FLIT_WIDTH>& flit)
	{
		return flit.bit(m_pos++) == 1;
	}

	void ExtractByteEnable(sc_bv<FLIT_WIDTH>& flit)
	{
		unsigned int be_len = BE_Width;
		uint8_t *be = m_byteEnable;
		unsigned int i;

		for (i = 0; i < be_len; i++) {
			if (ExtractBool(flit)) {
				be[i] = TLM_BYTE_ENABLED;
			} else {
				be[i] = TLM_BYTE_DISABLED;
			}
		}
	}

	void ExtractData(sc_bv<FLIT_WIDTH>& flit)
	{
		unsigned int dataLen = Data_Width / 8;
		unsigned int i;

		for (i = 0; i < dataLen; i++) {
			m_data[i] = Extract<uint8_t>(flit, 8);
		}
	}

	void ParseFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		m_QoS = Extract<uint8_t>(flit, QoS_Width);
		m_TgtID = Extract<uint16_t>(flit, TgtID_Width);
		m_SrcID = Extract<uint16_t>(flit, SrcID_Width);
		m_TxnID = Extract<uint8_t>(flit, TxnID_Width);
		m_HomeNID = Extract<uint16_t>(flit, HomeNID_Width);
		m_Opcode = Extract<uint8_t>(flit, Opcode_Width);
		m_RespErr = Extract<uint8_t>(flit, RespErr_Width);
		m_Resp = Extract<uint8_t>(flit, Resp_Width);

		m_FwdState_DataPull_DataSource =
			Extract<uint8_t>(flit,
					 FwdState_DataPull_DataSource_Width);

		m_DBID = Extract<uint8_t>(flit, DBID_Width);
		m_CCID = Extract<uint8_t>(flit, CCID_Width);
		m_DataID = Extract<uint8_t>(flit, DataID_Width);
		m_TraceTag = ExtractBool(flit);

		if (RSVDC_WIDTH) {
			m_RSVDC = Extract<uint32_t>(flit, RSVDC_Width);
		}

		ExtractByteEnable(flit);
		ExtractData(flit);

		if (DATACHECK_WIDTH) {
			m_DataCheck =
				Extract<uint64_t>(flit, DataCheck_Width);
		}

		if (POISON_WIDTH) {
			m_Poison =
				Extract<uint8_t>(flit, Poison_Width);
		}
	}

	uint8_t m_QoS;
	uint16_t m_TgtID;
	uint16_t m_SrcID;
	uint8_t m_TxnID;
	uint16_t m_HomeNID;
	uint8_t m_Opcode;
	uint8_t m_RespErr;
	uint8_t m_Resp;

	uint8_t m_FwdState_DataPull_DataSource;

	uint8_t m_DBID;
	uint8_t m_CCID;
	uint8_t m_DataID;
	bool m_TraceTag;

	uint32_t m_RSVDC;

	uint8_t m_data[CACHELINE_SZ];
	uint8_t m_byteEnable[CACHELINE_SZ];

	uint64_t m_DataCheck;
	uint8_t m_Poison;

	unsigned int m_pos;
};

}; // namespace CHECKERS
}; // namespace CHI
}; // namespace AMBA


#endif /* CHECKER_FLITS_CHI_H__ */

