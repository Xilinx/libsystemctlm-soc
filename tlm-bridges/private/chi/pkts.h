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

#ifndef TLM_BRIDGES_PRIV_CHI_PKTS_H__
#define TLM_BRIDGES_PRIV_CHI_PKTS_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-bridges/amba-chi.h"
#include "tlm-extensions/chiattr.h"

namespace AMBA {
namespace CHI {
namespace BRIDGES {

template<
	int ADDR_WIDTH,
	int NODEID_WIDTH,
	int RSVDC_WIDTH>
class ReqPkt
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

	ReqPkt(sc_bv<FLIT_WIDTH>& flit) :
		m_gp(new tlm::tlm_generic_payload()),
		m_chiattr(new chiattr_extension()),
		m_flitDone(false),
		m_pos(0),
		m_delete(true)
	{
		ParseFlit(flit);

		m_gp->set_extension(m_chiattr);
	}

	ReqPkt(tlm::tlm_generic_payload *gp) :
		m_gp(gp),
		m_chiattr(NULL),
		m_flitDone(false),
		m_pos(0),
		m_delete(false)
	{
		assert(m_gp);

		m_gp->get_extension(m_chiattr);
	}

	~ReqPkt()
	{
		if (m_delete) {
			delete m_gp;
		}
	}

	tlm::tlm_generic_payload& GetGP()
	{
		return *m_gp;
	}

	void CreateFlit(sc_out<sc_bv<FLIT_WIDTH> >& flit)
	{
		sc_bv<FLIT_WIDTH> tmp;

		CreateFlit(tmp);

		flit.write(tmp);

		m_flitDone = true;
	}

	void CreateFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		sc_bv<FLIT_WIDTH> tmp;

		if (m_chiattr) {
			assert(m_pos == 0);

			Set(tmp, m_chiattr->GetQoS(), QoS_Width);
			Set(tmp, m_chiattr->GetTgtID(), TgtID_Width);
			Set(tmp, m_chiattr->GetSrcID(), SrcID_Width);
			Set(tmp, m_chiattr->GetTxnID(), TxnID_Width);

			Set(tmp, m_chiattr->GetReturnNID_StashNID(),
					ReturnNID_StashNID_Width);

			Set(tmp, m_chiattr->GetStashNIDValid_Endian(),
					StashNIDValid_Endian_Width);

			//
			// For stash transactions ReturnTxnID contains
			// { [7:6]: 0b00, StashLPIDValid[5], StashLPID[4:0] }
			//
			Set(tmp, m_chiattr->GetReturnTxnID(),
					ReturnTxnID_Width);

			Set(tmp, m_chiattr->GetOpcode(), Opcode_Width);
			Set(tmp, GetSize(), Size_Width);
			Set(tmp, m_gp->get_address(), Addr_Width);
			Set(tmp, m_chiattr->GetNonSecure(), NS_Width);
			Set(tmp, m_chiattr->GetLikelyShared(),
					LikelyShared_Width);
			Set(tmp, m_chiattr->GetAllowRetry(), AllowRetry_Width);
			Set(tmp, m_chiattr->GetOrder(), Order_Width);
			Set(tmp, m_chiattr->GetPCrdType(), PCrdType_Width);
			Set(tmp, GetMemAttr(), MemAttr_Width);
			Set(tmp, m_chiattr->GetSnpAttr(), SnpAttr_Width);
			Set(tmp, m_chiattr->GetLPID(), LPID_Width);

			Set(tmp, m_chiattr->GetExcl_SnoopMe(),
					ExclSnoopMe_Width);

			Set(tmp, m_chiattr->GetExpCompAck(), ExpCompAck_Width);
			Set(tmp, m_chiattr->GetTraceTag(), TraceTag_Width);

			if (RSVDC_WIDTH) {
				Set(tmp, m_chiattr->GetRSVDC(), RSVDC_WIDTH);
			}
		}

		flit = tmp;
	}

	bool Done() { return m_flitDone; }

	void NotifyDone()
	{
		if (m_flitDone) {
			SetTLMOKResp();
		} else {
			SetTLMGenericErrrorResp();
		}

		m_done.notify();
	}

	sc_event& DoneEvent() { return m_done; }
private:

	template<typename T>
	void Set(sc_bv<FLIT_WIDTH>& flit, T val, unsigned int width)
	{
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + width - 1;
		T mask = (static_cast<T>(1) << width) - 1;

		flit.range(lastbit, firstbit) = val & mask;

		m_pos += width;
	}

	void Set(sc_bv<FLIT_WIDTH>& flit, bool val, unsigned int width)
	{
		flit.bit(m_pos) = val;
		m_pos += width;
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

	void ParseFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		unsigned int size;

		assert(m_gp);
		assert(m_chiattr);

		m_gp->set_command(tlm::TLM_IGNORE_COMMAND);
		m_gp->set_data_ptr(&m_dummy_data[0]);
		m_gp->set_byte_enable_ptr(NULL);
		m_gp->set_byte_enable_length(0);
		m_gp->set_dmi_allowed(false);
		m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		m_chiattr->SetQoS(Extract<uint8_t>(flit, QoS_Width));
		m_chiattr->SetTgtID(Extract<uint16_t>(flit, TgtID_Width));
		m_chiattr->SetSrcID(Extract<uint16_t>(flit, SrcID_Width));
		m_chiattr->SetTxnID(Extract<uint8_t>(flit, TxnID_Width));

		m_chiattr->SetReturnNID_StashNID(
			Extract<uint16_t>(flit, ReturnNID_StashNID_Width));

		m_chiattr->SetStashNIDValid_Endian(ExtractBool(flit));

		//
		// For stash transactions ReturnTxnID contains
		// { [7:6]: 0b00, StashLPIDValid[5], StashLPID[4:0] }
		//
		m_chiattr->SetReturnTxnID(
			Extract<uint8_t>(flit, ReturnTxnID_Width));

		m_chiattr->SetOpcode(Extract<uint8_t>(flit, Opcode_Width));

		size = Extract<uint8_t>(flit, Size_Width);

		m_gp->set_data_length(1 << size);
		m_gp->set_streaming_width(1 << size);
		m_gp->set_address(Extract<uint64_t>(flit, Addr_Width));

		m_chiattr->SetNonSecure(ExtractBool(flit));
		m_chiattr->SetLikelyShared(ExtractBool(flit));
		m_chiattr->SetAllowRetry(ExtractBool(flit));
		m_chiattr->SetOrder(Extract<uint8_t>(flit, Order_Width));
		m_chiattr->SetPCrdType(Extract<uint8_t>(flit, PCrdType_Width));

		ExtractMemAttr(Extract<uint8_t>(flit, MemAttr_Width));

		m_chiattr->SetSnpAttr(ExtractBool(flit));

		m_chiattr->SetLPID(Extract<uint16_t>(flit, LPID_Width));

		m_chiattr->SetExcl_SnoopMe(ExtractBool(flit));

		m_chiattr->SetExpCompAck(ExtractBool(flit));
		m_chiattr->SetTraceTag(ExtractBool(flit));

		if (RSVDC_WIDTH) {
			m_chiattr->SetRSVDC(
				Extract<uint32_t>(flit, RSVDC_WIDTH));
		}
	}

	uint8_t GetSize()
	{
		switch(m_gp->get_data_length()) {
		case 64:
			return 6;
		case 32:
			return 5;
		case 16:
			return 4;
		case 8:
			return 3;
		case 4:
			return 2;
		case 2:
			return 1;
		case 1:
		default:
			// return 0
			break;
		}

		return 0;
	}

	enum {
		AllocateShift = 3,
		CacheableShift = 2,
		DeviceMemoryShift = 1,
		EarlyWrAckShift = 0
	};

	uint8_t GetMemAttr()
	{
		uint8_t memattr = 0;

		if (m_chiattr) {
			memattr = (m_chiattr->GetAllocate() << AllocateShift) |
				(m_chiattr->GetCacheable() << CacheableShift) |
				(m_chiattr->GetDeviceMemory() << DeviceMemoryShift) |
				(m_chiattr->GetEarlyWrAck() << EarlyWrAckShift);
		}

		return memattr;
	}

	void ExtractMemAttr(uint8_t memattr)
	{
		bool allocate = (memattr >> AllocateShift) & 0x1;
		bool cacheable = (memattr >> CacheableShift) & 0x1;
		bool devMem = (memattr >> DeviceMemoryShift) & 0x1;
		bool earlyWrAck = (memattr >> EarlyWrAckShift) & 0x1;

		m_chiattr->SetAllocate(allocate);
		m_chiattr->SetCacheable(cacheable);
		m_chiattr->SetDeviceMemory(devMem);
		m_chiattr->SetEarlyWrAck(earlyWrAck);
	}

	void SetTLMOKResp()
	{
		m_gp->set_response_status(tlm::TLM_OK_RESPONSE);
	}


	void SetTLMGenericErrrorResp()
	{
		m_gp->set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
	}

	enum { MAX_DATA_SZ = 64 };

	tlm::tlm_generic_payload *m_gp;
	chiattr_extension *m_chiattr;
	bool m_flitDone;
	sc_event m_done;
	unsigned int m_pos;
	bool m_delete;
	uint8_t m_dummy_data[MAX_DATA_SZ];
};

template<int NODEID_WIDTH>
class RspPkt
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

	RspPkt(sc_bv<FLIT_WIDTH>& flit) :
		m_gp(new tlm::tlm_generic_payload()),
		m_chiattr(new chiattr_extension()),
		m_flitDone(false),
		m_pos(0),
		m_delete(true)
	{
		ParseFlit(flit);

		m_gp->set_extension(m_chiattr);
	}

	RspPkt(tlm::tlm_generic_payload* gp) :
		m_gp(gp),
		m_chiattr(NULL),
		m_flitDone(false),
		m_pos(0),
		m_delete(false)
	{
		m_gp->get_extension(m_chiattr);
	}

	~RspPkt()
	{
		if (m_delete) {
			delete m_gp;
		}
	}

	tlm::tlm_generic_payload& GetGP()
	{
		return *m_gp;
	}

	void CreateFlit(sc_out<sc_bv<FLIT_WIDTH> >& flit)
	{
		sc_bv<FLIT_WIDTH> tmp;

		CreateFlit(tmp);

		flit.write(tmp);

		m_flitDone = true;
	}

	void CreateFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		sc_bv<FLIT_WIDTH> tmp;

		if (m_chiattr) {
			assert(m_pos == 0);

			Set(tmp, m_chiattr->GetQoS(), QoS_Width);
			Set(tmp, m_chiattr->GetTgtID(), TgtID_Width);
			Set(tmp, m_chiattr->GetSrcID(), SrcID_Width);
			Set(tmp, m_chiattr->GetTxnID(), TxnID_Width);
			Set(tmp, m_chiattr->GetOpcode(), Opcode_Width);
			Set(tmp, m_chiattr->GetRespErr(), RespErr_Width);
			Set(tmp, m_chiattr->GetResp(), Resp_Width);

			Set(tmp, m_chiattr->GetFwdState_DataPull(),
					FwdState_DataPull_Width);

			Set(tmp, m_chiattr->GetDBID(), DBID_Width);
			Set(tmp, m_chiattr->GetPCrdType(), PCrdType_Width);
			Set(tmp, m_chiattr->GetTraceTag(), TraceTag_Width);
		}

		flit = tmp;
	}

	bool Done() { return m_flitDone; }

	void NotifyDone()
	{
		if (m_flitDone) {
			SetTLMOKResp();
		} else {
			SetTLMGenericErrrorResp();
		}

		m_done.notify();
	}

	sc_event& DoneEvent() { return m_done; }
private:

	template<typename T>
	void Set(sc_bv<FLIT_WIDTH>& flit, T val, unsigned int width)
	{
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + width - 1;
		T mask = (static_cast<T>(1) << width) - 1;

		flit.range(lastbit, firstbit) = val & mask;

		m_pos += width;
	}

	void Set(sc_bv<FLIT_WIDTH>& flit, bool val, unsigned int width)
	{
		flit.bit(m_pos) = val;
		m_pos += width;
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

	void ParseFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		assert(m_gp);
		assert(m_chiattr);

		m_gp->set_command(tlm::TLM_IGNORE_COMMAND);
		m_gp->set_data_ptr(&m_dummy_data[0]);
		m_gp->set_data_length(MAX_DATA_SZ);
		m_gp->set_byte_enable_ptr(NULL);
		m_gp->set_byte_enable_length(0);
		m_gp->set_dmi_allowed(false);
		m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		m_chiattr->SetQoS(Extract<uint8_t>(flit, QoS_Width));
		m_chiattr->SetTgtID(Extract<uint16_t>(flit, TgtID_Width));
		m_chiattr->SetSrcID(Extract<uint16_t>(flit, SrcID_Width));
		m_chiattr->SetTxnID(Extract<uint8_t>(flit, TxnID_Width));
		m_chiattr->SetOpcode(Extract<uint8_t>(flit, Opcode_Width));

		m_chiattr->SetRespErr(Extract<uint8_t>(flit, RespErr_Width));
		m_chiattr->SetResp(Extract<uint8_t>(flit, Resp_Width));

		m_chiattr->SetFwdState_DataPull(
			Extract<uint8_t>(flit, FwdState_DataPull_Width));

		m_chiattr->SetDBID(Extract<uint8_t>(flit, DBID_Width));
		m_chiattr->SetPCrdType(Extract<uint8_t>(flit,  PCrdType_Width));
		m_chiattr->SetTraceTag(ExtractBool(flit));
	}

	void SetTLMOKResp()
	{
		m_gp->set_response_status(tlm::TLM_OK_RESPONSE);
	}


	void SetTLMGenericErrrorResp()
	{
		m_gp->set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
	}

	enum { MAX_DATA_SZ = 64 };

	tlm::tlm_generic_payload *m_gp;
	chiattr_extension *m_chiattr;
	bool m_flitDone;
	sc_event m_done;
	unsigned int m_pos;
	bool m_delete;
	uint8_t m_dummy_data[MAX_DATA_SZ];
};

template<
	int ADDR_WIDTH,
	int NODEID_WIDTH>
class SnpPkt
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

	SnpPkt(sc_bv<FLIT_WIDTH>& flit) :
		m_gp(new tlm::tlm_generic_payload()),
		m_chiattr(new chiattr_extension()),
		m_flitDone(false),
		m_pos(0),
		m_delete(true)
	{
		ParseFlit(flit);

		m_gp->set_extension(m_chiattr);
	}

	SnpPkt(tlm::tlm_generic_payload *gp) :
		m_gp(gp),
		m_chiattr(NULL),
		m_flitDone(false),
		m_pos(0),
		m_delete(false)
	{
		m_gp->get_extension(m_chiattr);
	}

	~SnpPkt()
	{
		if (m_delete) {
			delete m_gp;
		}
	}

	tlm::tlm_generic_payload& GetGP()
	{
		return *m_gp;
	}

	void CreateFlit(sc_out<sc_bv<FLIT_WIDTH> >& flit)
	{
		sc_bv<FLIT_WIDTH> tmp;

		CreateFlit(tmp);

		flit.write(tmp);

		m_flitDone = true;
	}

	void CreateFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		sc_bv<FLIT_WIDTH> tmp;

		if (m_chiattr) {
			assert(m_pos == 0);

			Set(tmp, m_chiattr->GetQoS(), QoS_Width);
			Set(tmp, m_chiattr->GetSrcID(), SrcID_Width);
			Set(tmp, m_chiattr->GetTxnID(), TxnID_Width);
			Set(tmp, m_chiattr->GetFwdNID(), FwdNID_Width);
			Set(tmp, m_chiattr->GetFwdTxnID(), FwdTxnID_Width);
			Set(tmp, m_chiattr->GetOpcode(), Opcode_Width);
			Set(tmp, m_gp->get_address() >> 3, Addr_Width);
			Set(tmp, m_chiattr->GetNonSecure(), NS_Width);

			// Bit is also DoNotDataPull
			Set(tmp, m_chiattr->GetDoNotGoToSD(), DoNotGoToSD_Width);

			Set(tmp, m_chiattr->GetRetToSrc(), RetToSrc_Width);
			Set(tmp, m_chiattr->GetTraceTag(), TraceTag_Width);
		}

		flit = tmp;
	}

	bool Done() { return m_flitDone; }

	void NotifyDone()
	{
		if (m_flitDone) {
			SetTLMOKResp();
		} else {
			SetTLMGenericErrrorResp();
		}

		m_done.notify();
	}

	sc_event& DoneEvent() { return m_done; }
private:

	template<typename T>
	void Set(sc_bv<FLIT_WIDTH>& flit, T val, unsigned int width)
	{
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + width - 1;
		T mask = (static_cast<T>(1) << width) - 1;

		flit.range(lastbit, firstbit) = val & mask;

		m_pos += width;
	}

	void Set(sc_bv<FLIT_WIDTH>& flit, bool val, unsigned int width)
	{
		flit.bit(m_pos) = val;
		m_pos += width;
	}

	template<typename T>
	T Extract(sc_bv<FLIT_WIDTH>& flit, unsigned int width)
	{
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + width - 1;
		uint64_t mask = (static_cast<T>(1) << width) - 1;
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
		assert(m_gp);
		assert(m_chiattr);

		m_gp->set_command(tlm::TLM_IGNORE_COMMAND);
		m_gp->set_data_ptr(&m_dummy_data[0]);
		m_gp->set_data_length(MAX_DATA_SZ);
		m_gp->set_byte_enable_ptr(NULL);
		m_gp->set_byte_enable_length(0);
		m_gp->set_dmi_allowed(false);
		m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		m_chiattr->SetQoS(Extract<uint8_t>(flit, QoS_Width));
		m_chiattr->SetSrcID(Extract<uint16_t>(flit, SrcID_Width));
		m_chiattr->SetTxnID(Extract<uint8_t>(flit, TxnID_Width));
		m_chiattr->SetFwdNID(Extract<uint16_t>(flit, FwdNID_Width));
		m_chiattr->SetFwdTxnID(Extract<uint16_t>(flit, FwdTxnID_Width));
		m_chiattr->SetOpcode(Extract<uint8_t>(flit, Opcode_Width));
		m_gp->set_address(Extract<uint64_t>(flit, Addr_Width) << 3);
		m_chiattr->SetNonSecure(ExtractBool(flit));

		// Bit is also DoNotDataPull
		m_chiattr->SetDoNotGoToSD(ExtractBool(flit));

		m_chiattr->SetRetToSrc(ExtractBool(flit));
		m_chiattr->SetTraceTag(ExtractBool(flit));
	}

	void SetTLMOKResp()
	{
		m_gp->set_response_status(tlm::TLM_OK_RESPONSE);
	}


	void SetTLMGenericErrrorResp()
	{
		m_gp->set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
	}

	enum { MAX_DATA_SZ = 64 };

	tlm::tlm_generic_payload *m_gp;
	chiattr_extension *m_chiattr;
	bool m_flitDone;
	sc_event m_done;
	unsigned int m_pos;
	bool m_delete;
	uint8_t m_dummy_data[MAX_DATA_SZ];
};

template<
	int DATA_WIDTH,
	int NODEID_WIDTH,
	int RSVDC_WIDTH,
	int DATACHECK_WIDTH,
	int POISON_WIDTH,
	int DAT_OPCODE_WIDTH>
class DatPkt
{
public:
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

	DatPkt(sc_bv<FLIT_WIDTH>& flit) :
		m_sent(0),
		m_gp(new tlm::tlm_generic_payload()),
		m_chiattr(new chiattr_extension()),
		m_flitDone(false),
		m_pos(0),
		m_delete(true)
	{
		ParseFlit(flit);

		m_gp->set_extension(m_chiattr);
	}

	DatPkt(tlm::tlm_generic_payload *gp) :
		m_sent(0),
		m_gp(gp),
		m_chiattr(NULL),
		m_flitDone(false),
		m_pos(0),
		m_delete(false)
	{
		m_gp->get_extension(m_chiattr);
	}

	~DatPkt()
	{
		if (m_delete) {
			delete[] m_gp->get_data_ptr();

			if (m_gp->get_byte_enable_ptr()) {
				delete[] m_gp->get_byte_enable_ptr();
			}

			delete m_gp;
		}
	}

	tlm::tlm_generic_payload& GetGP()
	{
		return *m_gp;
	}

	void CreateFlit(sc_out<sc_bv<FLIT_WIDTH> >& flit)
	{
		sc_bv<FLIT_WIDTH> tmp;

		CreateFlit(tmp);

		flit.write(tmp);

		m_sent += Data_Width / 8;

		if (m_sent >= m_gp->get_data_length()) {
			//
			// All transmitted
			//
			m_flitDone = true;
		}
	}

	void CreateFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		sc_bv<FLIT_WIDTH> tmp;

		if (m_chiattr) {
			uint8_t dataID = m_sent / (Data_Width/8);

			assert(m_pos == 0);

			Set(tmp, m_chiattr->GetQoS(), QoS_Width);
			Set(tmp, m_chiattr->GetTgtID(), TgtID_Width);
			Set(tmp, m_chiattr->GetSrcID(), SrcID_Width);
			Set(tmp, m_chiattr->GetTxnID(), TxnID_Width);
			Set(tmp, m_chiattr->GetHomeNID(), HomeNID_Width);
			Set(tmp, m_chiattr->GetOpcode(), Opcode_Width);
			Set(tmp, m_chiattr->GetRespErr(), RespErr_Width);
			Set(tmp, m_chiattr->GetResp(), Resp_Width);

			Set(tmp, m_chiattr->GetFwdState_DataPull_DataSource(),
					FwdState_DataPull_DataSource_Width);

			Set(tmp, m_chiattr->GetDBID(), DBID_Width);
			Set(tmp, m_chiattr->GetCCID(), CCID_Width);
			Set(tmp, dataID, DataID_Width);
			Set(tmp, m_chiattr->GetTraceTag(), TraceTag_Width);

			if (RSVDC_WIDTH) {
				Set(tmp, m_chiattr->GetRSVDC(), RSVDC_Width);
			}

			SetByteEnable(tmp);
			SetData(tmp);

			if (DATACHECK_WIDTH) {
				Set(tmp, m_chiattr->GetDataCheck(), DataCheck_Width);
			}

			if (POISON_WIDTH) {
				Set(tmp, m_chiattr->GetPoison(), Poison_Width);
			}
		}

		flit = tmp;
	}

	bool Done()
	{
		return m_flitDone;
	}

	void NotifyDone()
	{
		if (m_flitDone) {
			SetTLMOKResp();
		} else {
			SetTLMGenericErrrorResp();
		}

		m_done.notify();
	}

	sc_event& DoneEvent() { return m_done; }
private:

	template<typename T>
	void Set(sc_bv<FLIT_WIDTH>& flit, T val, unsigned int width)
	{
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + width - 1;
		T mask = (static_cast<T>(1) << width) - 1;

		flit.range(lastbit, firstbit) = val & mask;

		m_pos += width;
	}

	void Set(sc_bv<FLIT_WIDTH>& flit, bool val, unsigned int width)
	{
		flit.bit(m_pos) = val;
		m_pos += width;
	}

	void SetByteEnable(sc_bv<FLIT_WIDTH>& flit)
	{
		unsigned char *be = m_gp->get_byte_enable_ptr();
		int be_len = m_gp->get_byte_enable_length();
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + BE_Width - 1;
		unsigned int i;
		unsigned int offset = m_sent;
		unsigned int bepos = 0;

		if (be && be_len) {
			for (i = firstbit; i <= lastbit; i++, bepos++) {
				uint8_t b = be[(bepos + offset) % be_len];
				if (b == TLM_BYTE_ENABLED) {
					flit[i] = true;
				}
			}
		} else {
			unsigned int len = m_gp->get_data_length();

			/* All lanes active up to datalength.  */
			for (i = firstbit; i <= lastbit; i++) {
				if (len > 0) {
					flit[i] = true;
					len--;
				} else {
					flit[i] = false;
				}
			}
		}

		m_pos += BE_Width;
	}

	void SetData(sc_bv<FLIT_WIDTH>& flit)
	{
		unsigned char *data = m_gp->get_data_ptr();
		unsigned int len = m_gp->get_data_length();
		unsigned int firstbit = m_pos;
		unsigned int bus_width_bytes = DATA_WIDTH/8;
		unsigned int i;

		// Only write up to DATA_WIDTH size
		if (len > bus_width_bytes) {
			len = bus_width_bytes;
		}

		for (i = 0; i <= len; i++, firstbit += 8) {
			unsigned int lastbit = firstbit + 8 - 1;

			flit.range(lastbit, firstbit) = data[i];
		}

		m_pos += DATA_WIDTH;
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

	void ExtractByteEnable(sc_bv<FLIT_WIDTH>& flit)
	{
		unsigned int be_len = BE_Width;
		uint8_t *be = new uint8_t[be_len];
		unsigned int i;

		m_gp->set_byte_enable_ptr(be);
		m_gp->set_byte_enable_length(be_len);

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
		uint8_t *data = new uint8_t[dataLen];
		unsigned int i;

		m_gp->set_data_ptr(data);
		m_gp->set_data_length(dataLen);
		m_gp->set_streaming_width(dataLen);

		for (i = 0; i < dataLen; i++) {
			data[i] = Extract<uint8_t>(flit, 8);
		}
	}

	void ParseFlit(sc_bv<FLIT_WIDTH>& flit)
	{
		assert(m_gp);
		assert(m_chiattr);

		m_gp->set_command(tlm::TLM_WRITE_COMMAND);
		m_gp->set_dmi_allowed(false);
		m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		m_chiattr->SetQoS(Extract<uint8_t>(flit, QoS_Width));
		m_chiattr->SetTgtID(Extract<uint16_t>(flit, TgtID_Width));
		m_chiattr->SetSrcID(Extract<uint16_t>(flit, SrcID_Width));
		m_chiattr->SetTxnID(Extract<uint8_t>(flit, TxnID_Width));
		m_chiattr->SetHomeNID(Extract<uint16_t>(flit, HomeNID_Width));
		m_chiattr->SetOpcode(Extract<uint8_t>(flit, Opcode_Width));
		m_chiattr->SetRespErr(Extract<uint8_t>(flit, RespErr_Width));
		m_chiattr->SetResp(Extract<uint8_t>(flit, Resp_Width));

		m_chiattr->SetFwdState_DataPull_DataSource(
			Extract<uint8_t>(flit,
					 FwdState_DataPull_DataSource_Width));

		m_chiattr->SetDBID(Extract<uint8_t>(flit, DBID_Width));
		m_chiattr->SetCCID(Extract<uint8_t>(flit, CCID_Width));
		m_chiattr->SetDataID(Extract<uint8_t>(flit, DataID_Width));
		m_chiattr->SetTraceTag(ExtractBool(flit));

		if (RSVDC_WIDTH) {
			m_chiattr->SetRSVDC(Extract<uint8_t>(flit, RSVDC_Width));
		}

		ExtractByteEnable(flit);
		ExtractData(flit);

		if (DATACHECK_WIDTH) {
			m_chiattr->SetDataCheck(
				Extract<uint64_t>(flit, DataCheck_Width));
		}

		if (POISON_WIDTH) {
			m_chiattr->SetPoison(
				Extract<uint8_t>(flit, Poison_Width));
		}
	}

	void SetTLMOKResp()
	{
		m_gp->set_response_status(tlm::TLM_OK_RESPONSE);
	}

	void SetTLMGenericErrrorResp()
	{
		m_gp->set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
	}

	unsigned int m_sent;

	tlm::tlm_generic_payload *m_gp;
	chiattr_extension *m_chiattr;
	bool m_flitDone;
	sc_event m_done;
	unsigned int m_pos;
	bool m_delete;
};

}; // namespace BRIDGES
}; // namespace CHI
}; // namespace AMBA

#endif
