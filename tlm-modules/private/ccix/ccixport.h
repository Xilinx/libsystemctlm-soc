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
 * References:
 *
 * [1] AMBA 5 CHI Architecture Specification, ARM IHI 0050C, ID050218
 * [2] CCIX Base Specification Revision 1.0 Version 1.0
 *
 */
#ifndef TLM_MODULES_PRIV_CCIX_CCIXPORT_H__
#define TLM_MODULES_PRIV_CCIX_CCIXPORT_H__

#include "tlm-modules/private/chi/txnids.h"
#include "tlm-extensions/ccixattr.h"
#include "tlm-bridges/ccix.h"

namespace CCIX {

template<typename ICN>
class CCIXPort :
	public sc_core::sc_module
{
private:
	typedef typename ICN::ReqTxn ReqTxn;
	typedef typename ICN::DatMsg DatMsg;;
	typedef typename ICN::RspMsg RspMsg;
	typedef typename ICN::SnpMsg SnpMsg;
	typedef typename ICN::RequestOrderer RequestOrderer;
	typedef typename ICN::IPacketRouter IPacketRouter;
	typedef typename ICN::Address Address;
	typedef typename ICN::SnoopFilter SnoopFilter;

	//
	// SrcID and TxnID needs to be unique for CCIX transactions (see
	// section 3.3.13 [2])
	//
	class CCIXID
	{
	public:
		CCIXID(uint16_t SrcID, uint16_t TxnID) :
			m_SrcID(SrcID),
			m_TxnID(TxnID)
		{}

		uint16_t GetSrcID() { return m_SrcID; }
		uint16_t GetTxnID() { return m_TxnID; }

                friend bool operator==(const CCIXID& lhs, const CCIXID& rhs)
                {
                        return lhs.m_SrcID == rhs.m_SrcID &&
                                lhs.m_TxnID == rhs.m_TxnID;
                }
	private:
		uint16_t m_SrcID;
		uint16_t m_TxnID;
	};

	class CCIXAgent
	{
	public:
		CCIXAgent(uint16_t id) :
			m_id(id)
		{}

		uint16_t GetID() { return m_id; }

		SnoopFilter& GetSnoopFilter() { return m_snpFilter; }

	private:
		uint16_t m_id;
		SnoopFilter m_snpFilter;
	};

	class ITxn
	{
	public:
		//
		// Incoming CCIX
		//
		ITxn(tlm::tlm_generic_payload& gp,
				uint8_t SrcID, uint16_t TxnID) :
			m_chiattr(new chiattr_extension()),
			m_ccixattr(new ccixattr_extension()),
			m_id(SrcID, TxnID),
			m_transmitDone(false),
			m_ExpCompAck(false)
		{
			memset(m_data, 0, sizeof(m_data));
			memset(m_byteEnable, TLM_BYTE_DISABLED,
				sizeof(m_byteEnable));

			m_gp.set_data_ptr(m_data);
			m_gp.set_data_length(CACHELINE_SZ);

			m_gp.set_byte_enable_ptr(m_byteEnable);
			m_gp.set_byte_enable_length(CACHELINE_SZ);

			m_gp.set_streaming_width(CACHELINE_SZ);

			// m_gp will delete the extensions
			m_gp.set_extension(m_chiattr);
			m_gp.set_extension(m_ccixattr);

			m_gp.deep_copy_from(gp);
		}

		//
		// Outgoing CCIX requests
		//
		ITxn(ReqTxn *req,
			uint8_t SrcID, uint16_t TxnID) :
			m_chiattr(new chiattr_extension()),
			m_ccixattr(new ccixattr_extension()),
			m_id(SrcID, TxnID),
			m_transmitDone(false),
			m_ExpCompAck(false)
		{
			Setup(req->GetGP());
		}

		//
		// Outgoing CCIX responses (Comp) and Misc
		//
		ITxn() :
			m_chiattr(NULL),
			m_ccixattr(new ccixattr_extension()),
			m_id(0, 0), 		// unused
			m_transmitDone(false),
			m_ExpCompAck(false)	// unused
		{
			m_gp.set_command(tlm::TLM_IGNORE_COMMAND);

			memset(m_data, 0, sizeof(m_data));
			memset(m_byteEnable, 0, sizeof(m_byteEnable));

			m_gp.set_data_ptr(m_data);
			m_gp.set_data_length(CACHELINE_SZ);
			m_gp.set_streaming_width(CACHELINE_SZ);

			// m_gp will delete the extensions
			m_gp.set_extension(m_ccixattr);
		}

		//
		// Outgoing CCIX responses
		//
		ITxn(RspMsg& rsp,
			uint8_t SrcID, uint16_t TxnID) :
			m_chiattr(new chiattr_extension()),
			m_ccixattr(new ccixattr_extension()),
			m_id(SrcID, TxnID),
			m_transmitDone(false),
			m_ExpCompAck(false)
		{
			Setup(rsp.GetGP());
		}

		//
		// Outgoing CCIX responses
		//
		ITxn(DatMsg& dat,
			uint8_t SrcID, uint16_t TxnID) :
			m_chiattr(new chiattr_extension()),
			m_ccixattr(new ccixattr_extension()),
			m_id(SrcID, TxnID),
			m_transmitDone(false),
			m_ExpCompAck(false)
		{
			Setup(dat.GetGP());
		}

		//
		// Outgoing CCIX snoop requests
		//
		ITxn(SnpMsg& msg,
			uint8_t SrcID, uint16_t TxnID) :
			m_chiattr(new chiattr_extension()),
			m_ccixattr(new ccixattr_extension()),
			m_id(SrcID, TxnID),
			m_transmitDone(false),
			m_ExpCompAck(false)
		{
			Setup(msg.GetGP());
		}

		virtual ~ITxn()
		{}

		tlm::tlm_generic_payload& GetGP()
		{
			return m_gp;
		}
		chiattr_extension *GetCHIAttr() { return m_chiattr; }
		ccixattr_extension *GetCCIXAttr() { return m_ccixattr; }

		uint8_t GetCHIQoS() { return m_chiattr->GetQoS(); }
		uint8_t GetCHITxnID() { return m_chiattr->GetTxnID(); }
		void SetCHITxnID(uint8_t TxnID)
		{
			m_chiattr->SetTxnID(TxnID);
		}

		uint16_t GetCCIXTxnID() { return m_ccixattr->GetTxnID(); }
		void SetCCIXTxnID(uint16_t TxnID)
		{
			m_ccixattr->SetTxnID(TxnID);
		}

		uint16_t GetSrcID() { return m_chiattr->GetSrcID(); }
		uint16_t GetTgtID() { return m_chiattr->GetTgtID(); }

		uint8_t GetDBID() { return m_chiattr->GetDBID(); }
		void SetDBID(uint8_t DBID)
		{
			m_chiattr->SetDBID(DBID);
		}

		uint16_t GetHomeNID() { return m_chiattr->GetHomeNID(); }
		void SetHomeNID(uint16_t HomeNID)
		{
			m_chiattr->SetHomeNID(HomeNID);
		}

		bool GetExpCompAck() { return m_ExpCompAck; }
		void SetExpCompAck(bool val) { m_ExpCompAck = val; }

		CCIXID& GetCCIXID() { return m_id; }

		bool IsWriteUnique()
		{
			switch(m_chiattr->GetOpcode()) {
			case Req::WriteUniquePtl:
			case Req::WriteUniqueFull:
			case Req::WriteUniqueFullStash:
			case Req::WriteUniquePtlStash:
				return true;
			}
			return false;
		}

		void SetTransmitDone() { m_transmitDone = true; }
		bool GetTransmitDone() { return m_transmitDone; }

	protected:

		void Setup(tlm::tlm_generic_payload& gp)
		{
			memset(m_data, 0, CACHELINE_SZ);
			memset(m_byteEnable, TLM_BYTE_DISABLED,
				CACHELINE_SZ);

			m_gp.set_data_ptr(m_data);
			m_gp.set_data_length(CACHELINE_SZ);

			m_gp.set_byte_enable_ptr(m_byteEnable);
			m_gp.set_byte_enable_length(CACHELINE_SZ);

			m_gp.set_streaming_width(CACHELINE_SZ);

			// m_gp will delete the extensions
			m_gp.set_extension(m_chiattr);
			m_gp.set_extension(m_ccixattr);

			//
			// Copy gp fields (amongs others address field) and
			// also the extensions
			//
			m_gp.deep_copy_from(gp);
		}

		uint8_t toReqOp(uint8_t chiOpcode)
		{
			switch (chiOpcode) {
			case Req::ReadNoSnp:
				return Msg::ReqOp::ReadNoSnp;
			case Req::ReadOnce:
				return Msg::ReqOp::ReadOnce;
			case Req::ReadOnceCleanInvalid:
				return Msg::ReqOp::ReadOnceCleanInvalid;
			case Req::ReadOnceMakeInvalid:
				return Msg::ReqOp::ReadOnceMakeInvalid;
			case Req::ReadClean:
				return Msg::ReqOp::ReadClean;
			case Req::ReadNotSharedDirty:
				return Msg::ReqOp::ReadNotSharedDirty;
			case Req::ReadShared:
				return Msg::ReqOp::ReadShared;
			case Req::ReadUnique:
				return Msg::ReqOp::ReadUnique;
			default:
				break;
			}
			return 0;
		}

		uint64_t Align(uint64_t addr, uint64_t alignTo)
		{
			return (addr / alignTo) * alignTo;
		}

		tlm::tlm_generic_payload m_gp;
		chiattr_extension *m_chiattr;
		ccixattr_extension *m_ccixattr;

		uint8_t m_data[CACHELINE_SZ];
		uint8_t m_byteEnable[CACHELINE_SZ];

		CCIXID m_id;

		bool m_transmitDone;
		bool m_ExpCompAck;
	};

	class CCIXReq :
		public ITxn
	{
	public:

		using ITxn::m_gp;
		using ITxn::m_chiattr;
		using ITxn::m_ccixattr;
		using ITxn::m_data;
		using ITxn::m_byteEnable;
		using ITxn::m_ExpCompAck;

		enum {
			//
			// CCIX ReqAttrMemType
			//
			Device_nRnE = 0,
			Device_nRE = 1,
			Device_RE = 2,
			NonCacheable = 3,
			WBnA = 4,
			WBA = 5,

			ReqAttrMemType_Mask = 0x7,
		};

		//
		// Incoming CCIX request (from CXS)
		//
		CCIXReq(tlm::tlm_generic_payload& gp,
				ccixattr_extension *ccix) :
			ITxn(gp, ccix->GetSrcID(), ccix->GetTxnID()),
			m_datAttr(NULL)
		{
			ccix2chi();
		}

		//
		// Outgoing CCIX request (to CXS)
		//
		// Used for Reads and Dataless requests
		//
		CCIXReq(ReqTxn* req) :
			ITxn(req, req->GetSrcID(), req->GetTxnID()),
			m_datAttr(NULL)
		{
			//
			// CCIX Fully Coherent Read transactions use CompAck
			// (see 3.4.1.1)
			//
			if (req->IsSnpRead() ||
				IsDataLessWithCompAck(req->GetOpcode())) {
				m_ExpCompAck = true;
			}

			chi2ccix(req);
		}

		//
		// Outgoing CCIX Write / Atomic requests (to CXS)
		//
		CCIXReq(ReqTxn* req, DatMsg& dat) :
			ITxn(req, req->GetSrcID(), req->GetTxnID()),
			m_datAttr(NULL)
		{
			chi2ccix(req);
			AddData(req, dat);
		}

		tlm::tlm_generic_payload* GetDatGP() { return &m_datGP; }

		chiattr_extension *GetDatAttr(RspMsg& rsp)
		{
			chiattr_extension *rspAttr = rsp.GetCHIAttr();

			//
			// Update TgtId / TxnID
			//
			m_datAttr->SetTgtID(rspAttr->GetSrcID());
			m_datAttr->SetTxnID(rspAttr->GetDBID());

			return m_datAttr;
		}

		bool IsDataLess()
		{
			switch(m_chiattr->GetOpcode()) {
			case Req::CleanUnique:
			case Req::MakeUnique:
			case Req::Evict:
			case Req::CleanShared:
			case Req::CleanSharedPersist:
			case Req::CleanInvalid:
			case Req::MakeInvalid:
			case Req::StashOnceUnique:
			case Req::StashOnceShared:
				return true;
			}
			return false;
		}

		uint8_t GetDataLessResp()
		{
			switch(m_chiattr->GetOpcode()) {
			case Req::CleanUnique:
			case Req::MakeUnique:
				return Comp_UC;
			case Req::Evict:
			default:
				return Comp_I;
			}
			return Comp_I;
		}

		bool IsWrite()
		{
			switch(m_chiattr->GetOpcode()) {
			case Req::WriteEvictFull:
			case Req::WriteCleanFull:
			case Req::WriteUniquePtl:
			case Req::WriteUniqueFull:

			case Req::WriteBackFull:
			case Req::WriteBackPtl:
			case Req::WriteNoSnpPtl:
			case Req::WriteNoSnpFull:

			case Req::WriteUniqueFullStash:
			case Req::WriteUniquePtlStash:
				return true;
			}
			return false;
		}

		bool IsAtomicNonStore()
		{
			uint8_t op = m_ccixattr->GetReqOp();
			bool isAtomicNonStore =
				op >= Msg::ReqOp::AtomicLoad &&
				op <= Msg::ReqOp::AtomicCompare;

			bool isAtomicNonStoreSnpMe =
				op >= Msg::ReqOp::AtomicLoadSnpMe &&
				op <= Msg::ReqOp::AtomicCompareSnpMe;

			return isAtomicNonStore || isAtomicNonStoreSnpMe;
		}

		bool IsAtomicCompare()
		{
			uint8_t op = m_ccixattr->GetReqOp();

			return op == Msg::ReqOp::AtomicCompare ||
				op == Msg::ReqOp::AtomicCompareSnpMe;
		}

		unsigned int GetReqSize()
		{
			uint8_t reqSize = m_ccixattr->GetReqAttr();

			reqSize = (reqSize >> ReqAttrSize_Shift) &
					ReqAttrSize_Mask;

			return 1 << reqSize;
		}

		uint8_t GetReqAttrMemType()
		{
			//
			// See Table 2-12, section 2.9.4 [1] and Table 2-9,
			// section 2.8.5
			//
			bool devmem = m_chiattr->GetDeviceMemory();
			bool EWA = m_chiattr->GetEarlyWrAck();
			uint8_t order = m_chiattr->GetOrder();
			bool cacheable = m_chiattr->GetCacheable();
			bool allocate = m_chiattr->GetAllocate();

			if (devmem) {
				if (order == Endpoint_Order) {
					return EWA ? Device_nRE : Device_nRnE;
				}
				//
				// Unset EWA is not valid (see Table 2-12 [1])
				//
				assert(EWA);
				return Device_RE;
			}

			//
			// Access targets Normal Memory
			//
			if (cacheable && allocate) {
				return WBA;
			} else if (cacheable && !allocate) {
				return WBnA;
			} else {
				return NonCacheable;
			}
		}

	private:
		enum {
			ReqAttrSize_Mask = 0x7,
			ReqAttrSize_Shift = 4,

			//
			// CHI Order
			//
			Request_Order = 0x2,
			Endpoint_Order = 0x3,

			// CHI responses
			Comp_I = 0x0,
			Comp_UC = 0x2,
			Comp_SC = 0x1,

			SZ_8 = 8,

			AtomicOpMask = 0x7,
		};

		bool IsDataLessWithCompAck(uint8_t opcode)
		{
			//
			// CleanUnique MakeUnique uses CompAck
			//
			return opcode == Req::CleanUnique ||
				opcode == Req::MakeUnique;
		}

		//
		// Address and data has been copied at ITxn construction
		//
		void chi2ccix(ReqTxn *req)
		{
			//
			// Convert extension
			//
			m_ccixattr->SetTgtID(m_chiattr->GetTgtID());
			m_ccixattr->SetSrcID(m_chiattr->GetSrcID());
			m_ccixattr->SetTxnID(m_chiattr->GetTxnID());

			//
			// Write ReqOp are set with the dat
			//
			if (req->IsRead() || req->IsDataLess()) {
				m_ccixattr->SetReqOp(
					toReqOp(m_chiattr->GetOpcode()));
			}

			m_ccixattr->SetNonSecure(m_chiattr->GetNonSecure());
			m_ccixattr->SetQoS(m_chiattr->GetQoS());

			m_ccixattr->SetMsgType(Msg::Type::Req);

			m_ccixattr->SetReqAttr(GetReqAttr());
		}

		uint8_t GetReqAttrSize()
		{
			uint8_t ReqAttrSize;

			switch (m_gp.get_data_length()) {
			case 128:
				ReqAttrSize = 7;
				break;
			case 64:
				ReqAttrSize = 6;
				break;
			case 32:
				ReqAttrSize = 5;
				break;
			case 16:
				ReqAttrSize = 4;
				break;
			case 8:
				ReqAttrSize = 3;
				break;
			case 4:
				ReqAttrSize = 2;
				break;
			case 2:
				ReqAttrSize = 1;
				break;
			default:
				ReqAttrSize = 0;
				break;
			}

			return ReqAttrSize << ReqAttrSize_Shift;
		}

		uint8_t GetReqAttr()
		{
			return GetReqAttrSize() | GetReqAttrMemType();
		}

		void AddData(ReqTxn* req, DatMsg& dat)
		{
			m_gp.set_command(tlm::TLM_WRITE_COMMAND);

			CopyData(req, dat);

			if (req->IsAtomic()) {
				m_ccixattr->SetReqOp(toAtomicReqOp(req));
			} else {
				m_ccixattr->SetReqOp(toWriteReqOp(dat));
			}
		}

		void CopyData(ReqTxn *req, DatMsg& dat)
		{
			if (req->GetDataLenght() < CACHELINE_SZ) {
				//
				// All dats contain CACHELINE_SZ bytes
				//
				unsigned char *data =
					dat.GetGP().get_data_ptr();

				uint64_t addr = req->GetAddress();
				unsigned int len = req->GetDataLenght();
				uint64_t aligned_addr = this->Align(addr, len);
				unsigned int offset;

				//
				// See section 3.5.4 [2], AtomicCompare window
				// always starts at the aligned_addr
				//
				if (!req->IsAtomicCompare() &&
					GetReqAttrMemType() < NonCacheable) {
					offset = addr & (CACHELINE_SZ-1);
					len -= (addr - aligned_addr);
				} else {
					offset =
						aligned_addr & (CACHELINE_SZ-1);
				}

				data += offset;

				//
				// Generate always min SZ_8
				// (see 3.5.4 [2])
				//
				if (len < SZ_8) {
					uint8_t d[SZ_8] = { 0 };
					unsigned int d_off;

					d_off = m_gp.get_address() & 0x3;

					//
					// Adjust d_off for AtomicCompare
					//
					if (req->IsAtomicCompare()) {
						d_off = (d_off / len) * len;
					}

					memcpy(&d[d_off], data, len);

					//
					// Place from the start of m_data
					//
					memcpy(m_data, d, SZ_8);
					m_gp.set_data_length(SZ_8);
				} else {
					//
					// Place from the start of m_data
					// (see 3.5.4.4 [2])
					//
					memcpy(m_data, data, len);
					m_gp.set_data_length(len);
				}

				m_gp.set_byte_enable_ptr(NULL);
				m_gp.set_byte_enable_length(0);
			} else {
				assert(m_gp.get_data_length() == CACHELINE_SZ);

				memcpy(m_data,
					dat.GetGP().get_data_ptr(),
					sizeof(m_data));

				memcpy(m_byteEnable,
					dat.GetGP().get_data_ptr(),
					sizeof(m_byteEnable));
			}
		}

		uint8_t toReqOp(uint8_t chiOpcode)
		{
			switch (chiOpcode) {
			case Req::ReadNoSnp:
				return Msg::ReqOp::ReadNoSnp;
			case Req::ReadOnce:
				return Msg::ReqOp::ReadOnce;
			case Req::ReadOnceCleanInvalid:
				return Msg::ReqOp::ReadOnceCleanInvalid;
			case Req::ReadOnceMakeInvalid:
				return Msg::ReqOp::ReadOnceMakeInvalid;
			case Req::ReadClean:
				return Msg::ReqOp::ReadClean;
			case Req::ReadNotSharedDirty:
				return Msg::ReqOp::ReadNotSharedDirty;
			case Req::ReadShared:
				return Msg::ReqOp::ReadShared;
			case Req::ReadUnique:
				return Msg::ReqOp::ReadUnique;

			case Req::Evict:
				return Msg::ReqOp::Evict;
			case Req::CleanShared:
				return Msg::ReqOp::CleanShared;
			case Req::CleanSharedPersist:
				return Msg::ReqOp::CleanSharedPersist;
			case Req::CleanInvalid:
				return Msg::ReqOp::CleanInvalid;
			case Req::MakeInvalid:
				return Msg::ReqOp::MakeInvalid;

			case Req::CleanUnique:
				return Msg::ReqOp::CleanUnique;
			case Req::MakeUnique:
				return Msg::ReqOp::MakeUnique;

			default:
				break;
			}

			SC_REPORT_ERROR("CCIXPort", "ReqOp translation error");
			return 0;
		}

		uint8_t toWriteReqOp(DatMsg& dat)
		{
			uint8_t resp = dat.GetCHIAttr()->GetResp();

			switch (m_chiattr->GetOpcode()) {
			case Req::WriteNoSnpPtl:
				return Msg::ReqOp::WriteNoSnpPtl;
			case Req::WriteNoSnpFull:
				return Msg::ReqOp::WriteNoSnpFull;

			case Req::WriteUniquePtl:
				return Msg::ReqOp::WriteUniquePtl;
			case Req::WriteUniqueFull:
				return Msg::ReqOp::WriteUniqueFull;

			case Req::WriteEvictFull:
				return Msg::ReqOp::WriteEvictFull;

			case Req::WriteBackPtl:
				return Msg::ReqOp::WriteBackPtl;

			case Req::WriteBackFull:
				switch (resp) {
				case Resp::CopyBackWrData_SD_PD:
					return Msg::ReqOp::WriteBackFullSD;

				case Resp::CopyBackWrData_UD_PD:
					return Msg::ReqOp::WriteBackFullUD;

				//
				// Below should not be propagated
				//
				case Resp::CopyBackWrData_SC:
				case Resp::CopyBackWrData_UC:
				default:
					break;
				}
				break;
			case Req::WriteCleanFull:
				switch (resp) {
				case Resp::CopyBackWrData_SD_PD:
				case Resp::CopyBackWrData_UD_PD:
					return Msg::ReqOp::WriteCleanFullSD;

				//
				// Below should not be propagated
				//
				case Resp::CopyBackWrData_SC:
				case Resp::CopyBackWrData_UC:
				default:
					break;
				}
				break;

			default:
				break;
			}

			SC_REPORT_ERROR("CCIXPort", "ReqOp translation error");
			return 0;
		}

		uint8_t toAtomicReqOp(ReqTxn *req)
		{
			uint8_t chiOpcode = req->GetOpcode();

			if (m_chiattr->GetSnoopMe()) {
				if (req->IsAtomicStore()) {
					uint8_t subop =
						chiOpcode & AtomicOpMask;

					return Msg::ReqOp::AtomicStoreSnpMe |
						subop;

				} else if (req->IsAtomicLoad()) {
					uint8_t subop =
						chiOpcode & AtomicOpMask;

					return Msg::ReqOp::AtomicLoadSnpMe |
						subop;

				} else if (req->IsAtomicSwap()) {

					return Msg::ReqOp::AtomicSwapSnpMe;

				} else if (req->IsAtomicCompare()) {

					return Msg::ReqOp::AtomicCompareSnpMe;
				}
			} else {
				if (req->IsAtomicStore()) {
					uint8_t subop =
						chiOpcode & AtomicOpMask;

					return Msg::ReqOp::AtomicStore |
						subop;

				} else if (req->IsAtomicLoad()) {
					uint8_t subop =
						chiOpcode & AtomicOpMask;

					return Msg::ReqOp::AtomicLoad |
						subop;

				} else if (req->IsAtomicSwap()) {

					return Msg::ReqOp::AtomicSwap;

				} else if (req->IsAtomicCompare()) {

					return Msg::ReqOp::AtomicCompare;
				}
			}
			SC_REPORT_ERROR("CCIXPort", "ReqOp translation error");
			return 0;
		}

		//
		// Only WriteNoSnpPtl, WriteUniquePtl and WriteBackPtl
		// contain byte enables 3.11.2 [2]
		//
		bool HasByteEnables()
		{
			//
			// CCIX messages with Byte enables
			//
			switch(m_ccixattr->GetReqOp()) {
			case Msg::ReqOp::WriteNoSnpPtl:
			case Msg::ReqOp::WriteUniquePtl:
			case Msg::ReqOp::WriteBackPtl:
				return true;
			default:
				break;
			}
			return false;
		}

		void ccix2chi()
		{
			uint8_t opcode;

			//
			// Reqs are always TLM_IGNORE_COMMAND
			//
			m_gp.set_command(tlm::TLM_IGNORE_COMMAND);

			// Convert extension
			m_chiattr->SetTgtID(m_ccixattr->GetTgtID());
			m_chiattr->SetSrcID(m_ccixattr->GetSrcID());
			m_chiattr->SetTxnID(m_ccixattr->GetTxnID());

			opcode = toCHI(m_ccixattr->GetReqOp());
			m_chiattr->SetOpcode(opcode);

			m_chiattr->SetNonSecure(m_ccixattr->GetNonSecure());
			m_chiattr->SetQoS(m_ccixattr->GetQoS());

			//
			// CCIX WriteUniques don't use CompAck
			//
			if (IsFullyCoherentRead() ||
				IsDataLessWithCompAck(opcode)) {
				m_chiattr->SetExpCompAck(true);
				m_ExpCompAck = true;

			}

			if (IsCCIXAtomicSnpMe(m_ccixattr->GetReqOp())) {
				m_chiattr->SetSnoopMe(true);
				m_chiattr->SetSnpAttr(true);
			} else {
				m_chiattr->SetSnpAttr(GetCHISnpAttr());
			}

			ToCHIMemoryAttributes(GetCCIXMemType());

			if (IsWrite() || IsCCIXAtomic(m_ccixattr->GetReqOp())) {
				CreateDatGP();
			}
		}

		uint8_t GetCCIXMemType()
		{
			return m_ccixattr->GetReqAttr() & ReqAttrMemType_Mask;
		}

		void ToCHIMemoryAttributes(uint8_t ccixMemType)
		{
			// Handle Device Memory
			if (ccixMemType < NonCacheable) {
				bool EWA =
					ccixMemType == Device_nRE ||
					ccixMemType == Device_RE;

				m_chiattr->SetDeviceMemory(true);
				m_chiattr->SetCacheable(false);
				m_chiattr->SetAllocate(false);
				m_chiattr->SetEarlyWrAck(EWA);

				if (ccixMemType == Device_nRE ||
					ccixMemType == Device_nRnE) {
					m_chiattr->SetOrder(Endpoint_Order);
				} else if (ccixMemType == Device_RE) {
					//
					// Always reply the CompData from the
					// HomeNode and not directly from the
					// slave
					//
					m_chiattr->SetOrder(Request_Order);
				}

				return;
			}

			//
			// Handle Normal Memory, always allow EWA
			//
			m_chiattr->SetDeviceMemory(false);
			m_chiattr->SetEarlyWrAck(true);
			switch (ccixMemType) {
			case NonCacheable:
				m_chiattr->SetCacheable(false);
				m_chiattr->SetAllocate(false);
				break;
			case WBnA:
				m_chiattr->SetCacheable(true);
				m_chiattr->SetAllocate(false);
				break;
			case WBA:
				m_chiattr->SetCacheable(true);
				m_chiattr->SetAllocate(true);
				break;
			default:
				SC_REPORT_ERROR("CCIXPort",
					"ReqAttr translation error");
				break;
			};
		}

		bool GetCHISnpAttr()
		{
			switch(m_chiattr->GetOpcode()) {
			//
			// Set SnpAttr (return true)
			//
			case Req::ReadOnce:
			case Req::ReadOnceCleanInvalid:
			case Req::ReadOnceMakeInvalid:
			case Req::ReadClean:
			case Req::ReadNotSharedDirty:
			case Req::ReadShared:
			case Req::ReadUnique:

			//
			// DataLess
			//
			// SnpAttr is allowed to be set on all and must be set
			// on CleanUnique, MakeUnique, StashOnce*, Evict ,
			// 2.9.6 [1]
			//
			case Req::CleanUnique:
			case Req::MakeUnique:
			case Req::Evict:
			case Req::CleanShared:
			case Req::CleanSharedPersist:
			case Req::CleanInvalid:
			case Req::MakeInvalid:
			case Req::StashOnceUnique:
			case Req::StashOnceShared:
				return true;

			//
			// No SnpAttr (return false for all others)
			//
			case Req::ReadNoSnpSep:
			case Req::ReadNoSnp:
			default:
				break;
			}
			return false;
		}

		uint8_t toCHI(uint8_t ccixOp)
		{
			switch (ccixOp) {
			//
			// Reads
			//
			case Msg::ReqOp::ReadNoSnp:
				return Req::ReadNoSnp;
			case Msg::ReqOp::ReadOnce:
				return Req::ReadOnce;
			case Msg::ReqOp::ReadOnceCleanInvalid:
				return Req::ReadOnceCleanInvalid;
			case Msg::ReqOp::ReadOnceMakeInvalid:
				return Req::ReadOnceMakeInvalid;
			case Msg::ReqOp::ReadClean:
				return Req::ReadClean;
			case Msg::ReqOp::ReadNotSharedDirty:
				return Req::ReadNotSharedDirty;
			case Msg::ReqOp::ReadShared:
				return Req::ReadShared;
			case Msg::ReqOp::ReadUnique:
				return Req::ReadUnique;

			//
			// Dataless
			//
			case Msg::ReqOp::Evict:
				return Req::Evict;
			case Msg::ReqOp::CleanShared:
				return Req::CleanShared;
			case Msg::ReqOp::CleanSharedPersist:
				return Req::CleanSharedPersist;
			case Msg::ReqOp::CleanInvalid:
				return Req::CleanInvalid;
			case Msg::ReqOp::MakeInvalid:
				return Req::MakeInvalid;

			case Msg::ReqOp::CleanUnique:
				return Req::CleanUnique;
			case Msg::ReqOp::MakeUnique:
				return Req::MakeUnique;

			//
			// Writes
			//
			case Msg::ReqOp::WriteNoSnpPtl:
				return Req::WriteNoSnpPtl;
			case Msg::ReqOp::WriteNoSnpFull:
				return Req::WriteNoSnpFull;

			case Msg::ReqOp::WriteUniquePtl:
				return Req::WriteUniquePtl;
			case Msg::ReqOp::WriteUniqueFull:
				return Req::WriteUniqueFull;

			case Msg::ReqOp::WriteBackPtl:
				return Req::WriteBackPtl;

			case Msg::ReqOp::WriteBackFullUD:
			case Msg::ReqOp::WriteBackFullSD:
				return Req::WriteBackFull;

			case Msg::ReqOp::WriteCleanFullSD:
				return Req::WriteCleanFull;

			case Msg::ReqOp::WriteEvictFull:
				return Req::WriteEvictFull;

			default:
				break;
			}

			if (IsCCIXAtomic(ccixOp)) {
				return toCHIAtomic(ccixOp);
			}

			SC_REPORT_ERROR("CCIXPort", "ReqOp translation error");
			return 0;
		}

		bool IsCCIXAtomic(uint8_t op)
		{
			return op >= Msg::ReqOp::AtomicStore &&
				op <= Msg::ReqOp::AtomicCompareSnpMe;
		}

		bool IsCCIXAtomicSnpMe(uint8_t op)
		{
			return op >= Msg::ReqOp::AtomicStoreSnpMe &&
				op <= Msg::ReqOp::AtomicCompareSnpMe;
		}

		bool IsCCIXAtomicStore(uint8_t op)
		{
			bool isAtomicStore = op >= Msg::ReqOp::AtomicStore &&
						op < Msg::ReqOp::AtomicLoad;
			bool isAtomicStoreSnpMe =
					op >= Msg::ReqOp::AtomicStoreSnpMe &&
					op < Msg::ReqOp::AtomicLoadSnpMe;

			return isAtomicStore || isAtomicStoreSnpMe;
		}

		bool IsCCIXAtomicLoad(uint8_t op)
		{
			bool isAtomicLoad = op >= Msg::ReqOp::AtomicLoad &&
						op < Msg::ReqOp::AtomicSwap;

			bool isAtomicLoadSnpMe =
				op >= Msg::ReqOp::AtomicLoadSnpMe &&
				op < Msg::ReqOp::AtomicSwapSnpMe;

			return isAtomicLoad || isAtomicLoadSnpMe;
		}

		bool IsCCIXAtomicSwap(uint8_t op)
		{
			return op == Msg::ReqOp::AtomicSwap ||
				op == Msg::ReqOp::AtomicSwapSnpMe;
		}

		bool IsCCIXAtomicCompare(uint8_t op)
		{
			return op == Msg::ReqOp::AtomicCompare ||
				op == Msg::ReqOp::AtomicCompareSnpMe;
		}

		uint8_t toCHIAtomic(uint8_t ccixOp)
		{
			if (IsCCIXAtomicStore(ccixOp)) {
				uint8_t subop = ccixOp & AtomicOpMask;

				return Req::AtomicStore | subop;

			} else if (IsCCIXAtomicLoad(ccixOp)) {
				uint8_t subop = ccixOp & AtomicOpMask;

				return Req::AtomicLoad | subop;

			} else if (IsCCIXAtomicSwap(ccixOp)) {
				return Req::AtomicSwap;

			} else if (IsCCIXAtomicCompare(ccixOp)) {
				return Req::AtomicCompare;
			}

			SC_REPORT_ERROR("CCIXPort", "ReqOp translation error");
			return 0;
		}

		bool IsFullyCoherentRead()
		{
			switch(m_chiattr->GetOpcode()) {
			case Req::ReadOnce:
			case Req::ReadOnceCleanInvalid:
			case Req::ReadOnceMakeInvalid:
			case Req::ReadClean:
			case Req::ReadNotSharedDirty:
			case Req::ReadShared:
			case Req::ReadUnique:
				return true;
			}
			return false;
		}

		uint8_t GetDatOpcode()
		{
			if (IsCCIXAtomic(m_ccixattr->GetReqOp())) {
				return Dat::NonCopyBackWrData;
			}

			switch(m_chiattr->GetOpcode()) {
			case Req::WriteNoSnpPtl:
			case Req::WriteNoSnpFull:
			case Req::WriteUniquePtl:
			case Req::WriteUniqueFull:
			case Req::WriteUniquePtlStash:
			case Req::WriteUniqueFullStash:
				return Dat::NonCopyBackWrData;

			case Req::WriteBackPtl:
			case Req::WriteBackFull:
			case Req::WriteCleanFull:
			case Req::WriteEvictFull:
			default:
				return Dat::CopyBackWrData;
			}
		}

		void CreateDatGP()
		{
			m_datAttr = reinterpret_cast<
					chiattr_extension*>(m_chiattr->clone());

			m_datGP.set_command(tlm::TLM_WRITE_COMMAND);

			if (m_gp.get_data_length() < CACHELINE_SZ) {
				//
				// Create data and byte enables
				//
				GenerateCHIData();

			} else if (!HasByteEnables()) {
				//
				// Enable all bytes
				//
				memset(m_byteEnable,
					TLM_BYTE_ENABLED,
					sizeof(m_byteEnable));
			}


			//
			// Dat is always CACHELINE_SZ
			//
			m_datGP.set_data_ptr(m_data);
			m_datGP.set_data_length(CACHELINE_SZ);
			m_datGP.set_streaming_width(CACHELINE_SZ);
			m_datGP.set_byte_enable_ptr(m_byteEnable);
			m_datGP.set_byte_enable_length(CACHELINE_SZ);

			//
			// Setup the dat later when rsp has beend receieved
			//
			m_datAttr->SetOpcode(GetDatOpcode());

			m_datAttr->SetResp(toDatResp(m_ccixattr->GetReqOp()));

			//
			// m_datGP_gp will delete the extension
			//
			m_datGP.set_extension(m_datAttr);
		}

		void GenerateCHIData()
		{
			unsigned char *src = m_gp.get_data_ptr();
			uint64_t addr = m_gp.get_address();
			unsigned int len = GetReqSize();
			uint64_t aligned_addr = this->Align(addr, len);
			uint8_t data[CACHELINE_SZ] = { 0 };
			uint8_t byteEnable[CACHELINE_SZ];
			unsigned int offset;

			memset(byteEnable, TLM_BYTE_DISABLED,
				sizeof(byteEnable));

			//
			// See section 3.5.4 [2], AtomicCompare window
			// always starts at the aligned_addr
			//
			// All dats contain CACHELINE_SZ bytes
			//
			if (!IsAtomicCompare() &&
				GetReqAttrMemType() < NonCacheable) {
				offset = addr & (CACHELINE_SZ-1);
				len -= (addr - aligned_addr);
			} else {
				offset = aligned_addr & (CACHELINE_SZ-1);
			}

			//
			// If req size is < SZ_8, extract the data from the 8
			// byte window
			//
			if (len < SZ_8) {
				//
				// Calculate where in the 8 byte window data is
				// placed
				//
				uint8_t s_off = m_gp.get_address() & 0x3;

				if (IsAtomicCompare()) {
					s_off = (s_off / len) * len;
				}

				src += s_off;
			}

			//
			// Place into data
			//
			memcpy(&data[offset], src, len);
			memset(&byteEnable[offset], TLM_BYTE_ENABLED, len);

			//
			// Move into m_data
			//
			memcpy(m_data, data, CACHELINE_SZ);
			memcpy(m_byteEnable, byteEnable, CACHELINE_SZ);

			//
			// For the CHI request
			//
			m_gp.set_data_length(len);
			m_gp.set_streaming_width(len);
			m_gp.set_byte_enable_ptr(NULL);
			m_gp.set_byte_enable_length(0);
		}

		uint8_t toDatResp(uint8_t ccixOp)
		{
			if (IsCCIXAtomic(ccixOp)) {
				return Resp::NonCopyBackWrData;
			}

			switch (ccixOp) {
			case Msg::ReqOp::WriteNoSnpPtl:
			case Msg::ReqOp::WriteNoSnpFull:
			case Msg::ReqOp::WriteUniquePtl:
			case Msg::ReqOp::WriteUniqueFull:
				return Resp::NonCopyBackWrData;

			case Msg::ReqOp::WriteBackPtl:
			case Msg::ReqOp::WriteBackFullUD:
				return Resp::CopyBackWrData_UD_PD;

			case Msg::ReqOp::WriteBackFullSD:
				return Resp::CopyBackWrData_SD_PD;

			case Msg::ReqOp::WriteCleanFullSD:
				return Resp::CopyBackWrData_SD_PD;

			case Msg::ReqOp::WriteEvictFull:
				return Resp::CopyBackWrData_UC;

			default:
				break;
			}

			SC_REPORT_ERROR("CCIXPort", "ReqOp translation error");
			return 0;
		}

		tlm::tlm_generic_payload m_datGP;
		chiattr_extension *m_datAttr;
	};

	class CCIXResp :
		public ITxn
	{
	public:
		using ITxn::m_gp;
		using ITxn::m_chiattr;
		using ITxn::m_ccixattr;
		using ITxn::m_data;
		using ITxn::m_byteEnable;
		using ITxn::m_id;

		//
		// Incoming CCIXResp (from CXS)
		//
		CCIXResp(tlm::tlm_generic_payload& gp,
				ccixattr_extension *ccix) :
			ITxn(gp, ccix->GetSrcID(), ccix->GetTxnID())
		{
			ccix2chi();
		}

		//
		// Outgoing CCIX responses with data (toward CXS)
		//
		// CCIXID is the RN ID and TxnID (dat TgtID and TxnID)
		//
		CCIXResp(DatMsg& dat, CCIXReq *ccixReq) :
			ITxn(dat, dat.GetTgtID(), dat.GetTxnID())
		{
			chi2ccix();

			SetResp(dat, ccixReq->IsAtomicNonStore());

			//
			// The CHI dat contains CACHELINE_SZ but according to
			// 3.5.4.1 [2] CCIX returns the request's size
			//
			if (ccixReq->GetReqSize() < CACHELINE_SZ) {
				GenerateCCIXData(ccixReq);
			}

			//
			// Update SrcID for CompData (Dats carry data and if a
			// CCIX resp carries data it is CompData). This is done
			// for being able to route back the CompAck
			//
			m_ccixattr->SetSrcID(m_chiattr->GetHomeNID());
		}

		//
		// Outgoing Rsps (toward CXS)
		//
		CCIXResp(RspMsg& rsp) :
			ITxn(rsp, rsp.GetSrcID(), rsp.GetTxnID())
		{
			chi2ccix();
		}

		//
		// Outgoing Comp (toward CXS and RN)
		//
		CCIXResp(CCIXReq *req) :
			ITxn()
		{
			// Setup CCIX extension
			m_ccixattr->SetTgtID(req->GetSrcID());
			m_ccixattr->SetSrcID(req->GetTgtID());
			m_ccixattr->SetTxnID(req->GetCHITxnID());
			m_ccixattr->SetRespAttr(0);
			m_ccixattr->SetRespOp(0);

			m_ccixattr->SetMsgType(Msg::Type::Resp);
		}

		bool IsCompData()
		{
			//
			// CCIX Responses with data are CompData (see table
			// 3-12 at section 3.3.3.1 [2])
			//
			return m_gp.is_write();
		}

		bool IsComp()
		{
			return m_ccixattr->GetRespOp() == 0 &&
				m_ccixattr->GetRespAttr() == 0;
		}

		void GenerateCHIData(CCIXReq *ccixReq)
		{
			tlm::tlm_generic_payload& gp = ccixReq->GetGP();

			uint64_t addr = gp.get_address();
			unsigned int len = ccixReq->GetReqSize();
			uint8_t data[CACHELINE_SZ] = { 0 };
			uint8_t byteEnable[CACHELINE_SZ];
			uint8_t m_data_off = 0;
			unsigned int offset;
			uint64_t aligned_addr;

			memset(byteEnable, TLM_BYTE_DISABLED,
				sizeof(byteEnable));

			//
			// Correct AtomicCompare data window length
			//
			if (ccixReq->IsAtomicCompare()) {
				//
				// Inbound is half outbound
				//
				len /= 2;
			}

			//
			// See section 3.5.4 [2], AtomicCompare window
			// always starts at the aligned_addr
			//
			// All dats contain CACHELINE_SZ bytes
			//
			aligned_addr = this->Align(addr, len);

			if (!ccixReq->IsAtomicCompare() &&
				ccixReq->GetReqAttrMemType() <
						CCIXReq::NonCacheable) {

				offset = addr & (CACHELINE_SZ-1);
				len -= (addr - aligned_addr);
			} else {
				offset = aligned_addr & (CACHELINE_SZ-1);
			}

			//
			// All dats contain CACHELINE_SZ bytes
			//
			offset = gp.get_address() & (CACHELINE_SZ-1);

			//
			// If req size is < SZ_8, extract the data from the 8
			// byte window
			//
			if (len < SZ_8) {
				//
				// Calculate where in the 8 byte window data is
				// placed
				//
				m_data_off = m_gp.get_address() & 0x3;

				if (ccixReq->IsAtomicCompare()) {
					m_data_off = (m_data_off / len) * len;
				}
			}

			//
			// Place into data
			//
			memcpy(&data[offset], &m_data[m_data_off], len);
			memset(&byteEnable[offset], TLM_BYTE_ENABLED, len);

			//
			// Move into m_data
			//
			memcpy(m_data, data, CACHELINE_SZ);
			memcpy(m_byteEnable, byteEnable, CACHELINE_SZ);

			m_gp.set_data_length(CACHELINE_SZ);
			m_gp.set_streaming_width(CACHELINE_SZ);
			m_gp.set_byte_enable_length(CACHELINE_SZ);
		}

	private:
		enum {
			//
			// CHI resp[2:0], see 4.5.1 [1]
			//
			CHI_CompData_I = 0x0,
			CHI_CompData_UC = 0x2,
			CHI_CompData_SC = 0x1,
			CHI_CompData_UD_PD = 0x6,
			CHI_CompData_SD_PD = 0x7,

			//
			// CCIX see table 3-12 at section 3.3.3.1 [2]
			//
			ReqRespOp_Comp = 0x0,
			ReqRespOp_CompData_UC = 0x1,
			ReqRespOp_CompData_SC = 0x1,
			ReqRespOp_CompData_UD_PD = 0x2,
			ReqRespOp_CompData_SD_PD = 0x2,

			RespAttr_Comp = 0x0,
			RespAttr_CompData_UC = 0x4,
			RespAttr_CompData_SC = 0x6,
			RespAttr_CompData_UD_PD = 0x5,
			RespAttr_CompData_SD_PD = 0x7,

			//
			// CCIX see table 3-16 at section 3.3.5.1 [2]
			//
			ReqRespOp_CompAck = 0x6,
			RespAttr_CompAck = 0x0,

			SZ_8 = 8,
		};

		void GenerateCCIXData(CCIXReq *ccixReq)
		{
			tlm::tlm_generic_payload& gp = ccixReq->GetGP();

			uint64_t addr = gp.get_address();
			unsigned int len = ccixReq->GetReqSize();

			uint8_t data[CACHELINE_SZ] = { 0 };
			uint8_t byteEnable[CACHELINE_SZ];
			unsigned int data_offset = 0;
			unsigned int offset;
			uint64_t aligned_addr;

			memset(byteEnable, TLM_BYTE_DISABLED,
				sizeof(byteEnable));

			//
			// Correct AtomicCompare data window length
			//
			if (ccixReq->IsAtomicCompare()) {
				//
				// Inbound length is half outbound
				//
				len /= 2;
			}

			//
			// See section 3.5.4 [2], AtomicCompare window
			// always starts at the aligned_addr
			//
			// All dats contain CACHELINE_SZ bytes
			//
			aligned_addr = this->Align(addr, len);

			if (!ccixReq->IsAtomicCompare() &&
				ccixReq->GetReqAttrMemType() <
						CCIXReq::NonCacheable) {

				offset = addr & (CACHELINE_SZ-1);
				len -= (addr - aligned_addr);
			} else {
				offset = aligned_addr & (CACHELINE_SZ-1);
			}

			//
			// If req size is < SZ_8, extract the data from the 8
			// byte window
			//
			if (len < SZ_8) {
				//
				// Calculate where in the 8 byte window data is
				// placed
				//
				data_offset = m_gp.get_address() & 0x3;

				if (ccixReq->IsAtomicCompare()) {
					data_offset = (data_offset / len) * len;
				}
			}

			//
			// Place into data
			//
			memcpy(&data[data_offset], &m_data[offset], len);
			memset(&byteEnable[data_offset], TLM_BYTE_ENABLED, len);

			//
			// SZ_8 is min CCIX resp size
			//
			len = (len < SZ_8) ? SZ_8 : len;

			//
			// Move back into m_data
			//
			memcpy(m_data, data, len);
			memcpy(m_byteEnable, byteEnable, len);

			m_gp.set_data_length(len);
			m_gp.set_streaming_width(len);
			m_gp.set_byte_enable_length(len);
		}

		bool AllByteEnablesAsserted()
		{
			int i = 0;

			for (; i < CACHELINE_SZ; i++) {
				if (m_byteEnable[i] != TLM_BYTE_ENABLED) {
					break;
				}
			}

			return i == CACHELINE_SZ;
		}

		void chi2ccix()
		{
			//
			// Convert extension
			//
			m_ccixattr->SetTgtID(m_chiattr->GetTgtID());
			m_ccixattr->SetSrcID(m_chiattr->GetSrcID());
			m_ccixattr->SetTxnID(m_chiattr->GetTxnID());

			m_ccixattr->SetMsgType(Msg::Type::Resp);
		}

		void SetResp(DatMsg& dat, bool isAtomicNonStore)
		{
			if (dat.IsCompData()) {
				//
				// Atomic non stores reply with CompData_UC
				// (3.3.8 [2])
				//
				if (isAtomicNonStore) {
					m_ccixattr->SetRespOp(
							ReqRespOp_CompData_UC);
					m_ccixattr->SetRespAttr(
							RespAttr_CompData_UC);
					return;
				}

				//
				// Translate CHI response
				//
				switch(dat.GetCHIAttr()->GetResp()) {
				case CHI_CompData_I:
				case CHI_CompData_UC:
					m_ccixattr->SetRespOp(
						ReqRespOp_CompData_UC);

					m_ccixattr->SetRespAttr(
						RespAttr_CompData_UC);

					break;
				case CHI_CompData_SC:
					m_ccixattr->SetRespOp(
						ReqRespOp_CompData_SC);

					m_ccixattr->SetRespAttr(
						RespAttr_CompData_SC);

					break;
				case CHI_CompData_UD_PD:
					m_ccixattr->SetRespOp(
						ReqRespOp_CompData_UD_PD);

					m_ccixattr->SetRespAttr(
						RespAttr_CompData_UD_PD);

					break;
				case CHI_CompData_SD_PD:
					m_ccixattr->SetRespOp(
						ReqRespOp_CompData_SD_PD);

					m_ccixattr->SetRespAttr(
						RespAttr_CompData_SD_PD);

					break;
				default:
					SC_REPORT_ERROR("CCIXPort",
						"Response translation error");
					break;
				}
			}
		}

		bool IsCompData_UC()
		{
			uint8_t RespOp = m_ccixattr->GetRespOp();
			uint8_t RespAttr = m_ccixattr->GetRespAttr();

			return RespOp == ReqRespOp_CompData_UC &&
				RespAttr == RespAttr_CompData_UC;
		}

		bool IsCompData_SC()
		{
			uint8_t RespOp = m_ccixattr->GetRespOp();
			uint8_t RespAttr = m_ccixattr->GetRespAttr();

			return RespOp == ReqRespOp_CompData_SC &&
				RespAttr == RespAttr_CompData_SC;
		}

		bool IsCompData_UD_PD()
		{
			uint8_t RespOp = m_ccixattr->GetRespOp();
			uint8_t RespAttr = m_ccixattr->GetRespAttr();

			return RespOp == ReqRespOp_CompData_UD_PD &&
				RespAttr == RespAttr_CompData_UD_PD;
		}

		bool IsCompData_SD_PD()
		{
			uint8_t RespOp = m_ccixattr->GetRespOp();
			uint8_t RespAttr = m_ccixattr->GetRespAttr();

			return RespOp == ReqRespOp_CompData_SD_PD &&
				RespAttr == RespAttr_CompData_SD_PD;
		}

		uint8_t GetCHIOpcode()
		{
			//
			// Both Dat::CompData and Rsp::Comp == 0x4
			//
			return Rsp::Comp;
		}

		uint8_t GetCHIResp()
		{
			if (IsCompData_UC()) {
				return CHI_CompData_UC;
			} else if (IsCompData_SC()) {
				return CHI_CompData_SC;
			} else if (IsCompData_UD_PD()) {
				return CHI_CompData_UD_PD;
			} else if (IsCompData_SD_PD()) {
				return CHI_CompData_SD_PD;
			}

			SC_REPORT_ERROR("CCIXPort",
				"Response translation error");
			return 0;
		}

		//
		// See  table 4-5, section 4.5.1 [1] and table 3-19, section
		// 3.3.8 [2] for CleanUnique, MakeUnique and other DataLess
		// Comp responses
		//
		void ccix2chi()
		{
			uint8_t opcode;

			// Convert extension
			m_chiattr->SetTgtID(m_ccixattr->GetTgtID());
			m_chiattr->SetSrcID(m_ccixattr->GetSrcID());
			m_chiattr->SetTxnID(m_ccixattr->GetTxnID());

			opcode = GetCHIOpcode();
			m_chiattr->SetOpcode(opcode);

			if (IsCompData()) {
				uint8_t resp = GetCHIResp();

				m_chiattr->SetResp(resp);

				//
				// CCIX2CHI conversion of CompData is done at
				// the RN side since CompData is always sent
				// from HN -> RN, so the CCIXID needs to be
				// corrected (always the request's SrcID TxnID)
				//
				m_id = CCIXID(m_ccixattr->GetTgtID(),
						m_ccixattr->GetTxnID());
			}

			m_chiattr->SetNonSecure(m_ccixattr->GetNonSecure());
			m_chiattr->SetQoS(m_ccixattr->GetQoS());
		}

	};

	class CCIXSnpReq :
		public ITxn
	{
	public:
		using ITxn::m_chiattr;
		using ITxn::m_ccixattr;

		//
		// Incoming CCIX SnpReqs
		//
		CCIXSnpReq(tlm::tlm_generic_payload& gp,
				ccixattr_extension *ccix) :
			ITxn(gp, ccix->GetSrcID(), ccix->GetTxnID())
		{
			ccix2chi();
		}

		//
		// Outgoing CCIX SnpReq (toward CXS)
		//
		CCIXSnpReq(CCIXAgent& agent, ReqTxn *req, SnpMsg& msg) :
			ITxn(msg, msg.GetSrcID(), msg.GetTxnID())
		{
			chi2ccix(agent, req, msg);
		}

	private:
		//
		// Address was copied at ITxn construction
		//
		// SnpCast is 0 (never broadcast)
		//
		// DataRet is always deasserted for all snps (see 3.3.4.1 [2])
		//
		void chi2ccix(CCIXAgent& agent, ReqTxn *req, SnpMsg& msg)
		{
			//
			// Convert extension
			//
			m_ccixattr->SetTgtID(agent.GetID());
			m_ccixattr->SetSrcID(msg.GetSrcID());
			m_ccixattr->SetTxnID(msg.GetTxnID());

			m_ccixattr->SetNonSecure(
				msg.GetCHIAttr()->GetNonSecure());

			m_ccixattr->SetSnpOp(toSnpOp(
				msg.GetCHIAttr()->GetOpcode()));

			m_ccixattr->SetMsgType(Msg::Type::SnpReq);
		}

		uint8_t toSnpOp(uint8_t chiOpcode)
		{
			//
			// See 4.3 [1] and 3.3.4 [2]
			//
			switch (chiOpcode) {

			case Snp::SnpOnce:
				return Msg::SnpOp::SnpToAny;
			case Snp::SnpClean:
			case Snp::SnpShared:
			case Snp::SnpNotSharedDirty:
				return Msg::SnpOp::SnpToS;

			case Snp::SnpUnique:
			case Snp::SnpCleanInvalid:
				return Msg::SnpOp::SnpToI;

			case Snp::SnpCleanShared:
				return Msg::SnpOp::SnpToC;

			case Snp::SnpMakeInvalid:
				return Msg::SnpOp::SnpToMakeI;

			//
			// Unsupported
			//
			case Snp::SnpUniqueStash:
			case Snp::SnpMakeInvalidStash:
			case Snp::SnpStashUnique:
			case Snp::SnpStashShared:
			case Snp::SnpOnceFwd:
			case Snp::SnpCleanFwd:
			case Snp::SnpNotSharedDirtyFwd:
			case Snp::SnpSharedFwd:
			case Snp::SnpUniqueFwd:
			default:
				break;
			}

			SC_REPORT_ERROR("CCIXPort", "SnpOp translation error");
			return 0;
		}

		//
		// Address was copied at ITxn construction
		//
		void ccix2chi()
		{
			uint8_t opcode;

			//
			// Convert extension
			//
			// CHI snoops don't use TgtID
			//
			m_chiattr->SetSrcID(m_ccixattr->GetSrcID());
			m_chiattr->SetTxnID(m_ccixattr->GetTxnID());

			opcode = toCHIOpcode(m_ccixattr->GetSnpOp());
			m_chiattr->SetOpcode(opcode);
			m_chiattr->SetDoNotGoToSD(GetDoNotGoToSD(opcode));

			m_chiattr->SetNonSecure(m_ccixattr->GetNonSecure());

			//
			// Don't return a cache line if it is in SC state
			//
			m_chiattr->SetRetToSrc(false);
		}

		bool GetDoNotGoToSD(uint8_t opcode)
		{
			return opcode == Snp::SnpCleanShared ||
				opcode == Snp::SnpMakeInvalid;
		}

		uint8_t toCHIOpcode(uint8_t chiOpcode)
		{
			//
			// See toSnpOp and 4.3 [1] 3.3.4 [2] for wich CHI
			// Snoops to transmit
			//
			switch (chiOpcode) {
			case Msg::SnpOp::SnpToAny:
				return Snp::SnpOnce;

			case Msg::SnpOp::SnpToS:
				return Snp::SnpShared;

			case Msg::SnpOp::SnpToI:
				return Snp::SnpUnique;

			case Msg::SnpOp::SnpToC:
				return Snp::SnpCleanShared;

			case Msg::SnpOp::SnpToMakeI:
				return Snp::SnpMakeInvalid;

			//
			// Unsupported
			//
			//case Snp::SnpUniqueStash:
			case Snp::SnpMakeInvalidStash:
			case Snp::SnpStashUnique:
			case Snp::SnpStashShared:
			case Snp::SnpOnceFwd:
			case Snp::SnpCleanFwd:
			case Snp::SnpNotSharedDirtyFwd:
			case Snp::SnpSharedFwd:
			case Snp::SnpUniqueFwd:
			default:
				break;
			}

			SC_REPORT_ERROR("CCIXPort", "SnpOp translation error");
			return 0;
		}
	};

	class CCIXSnpResp :
		public ITxn
	{
	public:
		using ITxn::m_gp;
		using ITxn::m_chiattr;
		using ITxn::m_ccixattr;
		using ITxn::m_byteEnable;

		//
		// Incoming CCIXResp (from CXS)
		//
		CCIXSnpResp(tlm::tlm_generic_payload& gp,
				ccixattr_extension *ccix) :
			ITxn(gp, ccix->GetSrcID(), ccix->GetTxnID())
		{
			ccix2chi();
		}

		//
		// Outgoing Snoop Response (toward CXS)
		//
		// CCIXID is the RN ID and TxnID (dat TgtID and TxnID)
		//
		CCIXSnpResp(DatMsg& dat) :
			ITxn(dat, dat.GetTgtID(), dat.GetTxnID())
		{
			chi2ccix();

			SetResp(dat);

			assert(AllByteEnablesAsserted() || IsSnpRespDataPtl());
		}

		//
		// Outgoing Snoop Response (toward CXS)
		//
		CCIXSnpResp(RspMsg& rsp) :
			ITxn(rsp, rsp.GetSrcID(), rsp.GetTxnID())
		{
			chi2ccix();
			SetResp(rsp);
		}

		bool IsSnpRespData()
		{
			return m_ccixattr->GetRespOp() < RespOp_SnpRespDataPtl_UD;
		}

		bool IsSnpRespDataPtl()
		{
			uint8_t RespOp = m_ccixattr->GetRespOp();

			return RespOp == RespOp_SnpRespDataPtl_UD ||
				RespOp == RespOp_SnpRespDataPtl_I_PD;
		}

		bool IsSnpResp()
		{
			return m_ccixattr->GetRespOp() == RespOp_SnpResp_I;
		}

		bool IsCompAck()
		{
			return m_ccixattr->GetRespOp() == ReqRespOp_CompAck &&
				m_ccixattr->GetRespAttr() == RespAttr_CompAck;
		}

	private:
		enum {
			//
			// CHI Snoop resp[2:0], see table 4-7 section 4.5.3 [1]
			//
			CHI_SnpResp_I = 0x0,
			CHI_SnpResp_SC = 0x1,
			CHI_SnpResp_UC_UD = 0x2,
			CHI_SnpResp_SD = 0x3,

			//
			// CHI Snoop resp[2:0], see table 4-9 section 4.5.3 [1]
			//
			CHI_SnpRespData_I = 0x0,
			CHI_SnpRespData_SC = 0x1,
			CHI_SnpRespData_UC_UD = 0x2,
			CHI_SnpRespData_SD = 0x3,

			CHI_SnpRespData_I_PD = 0x4,
			CHI_SnpRespData_UC_PD = 0x6,
			CHI_SnpRespData_SC_PD = 0x5,

			CHI_SnpRespDataPtl_I_PD = 0x4,
			CHI_SnpRespDataPtl_UD = 0x2,

			//
			// CCIX see table 3-16 at section 3.3.5.1 [2]
			//
			//
			// RespOp
			//
			RespOp_SnpRespData_I = 0x0,
			RespOp_SnpRespData_UC = 0x0,
			RespOp_SnpRespData_UD = 0x0,
			RespOp_SnpRespData_SC = 0x0,
			RespOp_SnpRespData_SD = 0x0,

			RespOp_SnpRespData_I_PD = 0x1,
			RespOp_SnpRespData_UC_PD = 0x1,
			RespOp_SnpRespData_SC_PD = 0x1,

			RespOp_SnpRespDataPtl_UD = 0x2,
			RespOp_SnpRespDataPtl_I_PD = 0x3,

			RespOp_SnpResp_I = 0x4,
			RespOp_SnpResp_UC = 0x4,
			RespOp_SnpResp_SC = 0x4,

			//
			// RespAttr
			//
			RespAttr_SnpRespData_I = 0x0,
			RespAttr_SnpRespData_UC = 0x4,
			RespAttr_SnpRespData_UD = 0x5,
			RespAttr_SnpRespData_SC = 0x6,
			RespAttr_SnpRespData_SD = 0x7,

			RespAttr_SnpRespData_I_PD = 0x0,
			RespAttr_SnpRespData_UC_PD = 0x4,
			RespAttr_SnpRespData_SC_PD = 0x6,

			RespAttr_SnpRespDataPtl_UD = 0x5,
			RespAttr_SnpRespDataPtl_I_PD = 0x0,

			RespAttr_SnpResp_I = 0x0,
			RespAttr_SnpResp_UC = 0x4,
			RespAttr_SnpResp_SC = 0x6,

			ReqRespOp_CompAck = 0x6,
			RespAttr_CompAck = 0x0,
		};

		bool IsSnpRespDataPtl(uint8_t opcode)
		{
			return opcode == Dat::SnpRespDataPtl;
		}

		bool AllByteEnablesAsserted()
		{
			int i;

			if (m_gp.get_byte_enable_length() == 0 &&
				m_gp.get_byte_enable_ptr() == NULL) {
				return true;
			}

			for (i = 0; i < CACHELINE_SZ; i++) {
				if (m_byteEnable[i] != TLM_BYTE_ENABLED) {
					break;
				}
			}

			return i == CACHELINE_SZ;
		}

		//
		// Data was copied when constructing ITxn
		//
		void chi2ccix()
		{
			//
			// Convert extension
			//
			m_ccixattr->SetTgtID(m_chiattr->GetTgtID());
			m_ccixattr->SetSrcID(m_chiattr->GetSrcID());
			m_ccixattr->SetTxnID(m_chiattr->GetTxnID());

			m_ccixattr->SetMsgType(Msg::Type::SnpResp);
		}

		void SetResp(DatMsg& dat)
		{
			if (dat.IsSnpRespData()) {

				switch(dat.GetCHIAttr()->GetResp()) {
				case CHI_SnpRespData_I:
					m_ccixattr->SetRespOp(
						RespOp_SnpRespData_I);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpRespData_I);

					break;
				case CHI_SnpRespData_SC:
					m_ccixattr->SetRespOp(
						RespOp_SnpRespData_SC);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpRespData_SC);

					break;
				case CHI_SnpRespData_UC_UD:
					m_ccixattr->SetRespOp(
						RespOp_SnpRespData_UC);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpRespData_UC);

					break;
				case CHI_SnpRespData_SD:
					m_ccixattr->SetRespOp(
						RespOp_SnpRespData_SD);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpRespData_SD);

					break;
				case CHI_SnpRespData_I_PD:
					m_ccixattr->SetRespOp(
						RespOp_SnpRespData_I_PD);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpRespData_I_PD);

					break;
				case CHI_SnpRespData_UC_PD:
					m_ccixattr->SetRespOp(
						RespOp_SnpRespData_UC_PD);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpRespData_UC_PD);

					break;
				case CHI_SnpRespData_SC_PD:
					m_ccixattr->SetRespOp(
						RespOp_SnpRespData_SC_PD);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpRespData_SC_PD);

					break;
				default:
					SC_REPORT_ERROR("CCIXPort",
						"SnpRespData error");
					break;
				}
			} else if (dat.IsSnpRespDataPtl()) {
				switch(dat.GetCHIAttr()->GetResp()) {
				case CHI_SnpRespDataPtl_I_PD:
					m_ccixattr->SetRespOp(
						RespOp_SnpRespDataPtl_I_PD);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpRespDataPtl_I_PD);

					break;
				case CHI_SnpRespDataPtl_UD:
					m_ccixattr->SetRespOp(
						RespOp_SnpRespDataPtl_UD);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpRespDataPtl_UD);

					break;
				default:
					SC_REPORT_ERROR("CCIXPort",
							"SnpDataResp error");
					break;
				}
			}
		}

		void SetResp(RspMsg& rsp)
		{
			if (rsp.IsSnpResp()) {
				switch(rsp.GetCHIAttr()->GetResp()) {
				case CHI_SnpResp_I:
					m_ccixattr->SetRespOp(RespOp_SnpResp_I);
					m_ccixattr->SetRespAttr(
						RespAttr_SnpResp_I);

					break;
				case CHI_SnpResp_UC_UD:
					m_ccixattr->SetRespOp(
						RespOp_SnpResp_UC);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpResp_UC);

					break;
				case CHI_SnpResp_SC:
					m_ccixattr->SetRespOp(
						RespOp_SnpResp_SC);

					m_ccixattr->SetRespAttr(
						RespAttr_SnpResp_SC);

					break;
				default:
					SC_REPORT_ERROR("CCIXPort",
							"SnpResp error");
					break;
				}
			} else if (rsp.IsCompAck()) {
				m_ccixattr->SetRespOp(ReqRespOp_CompAck);
				m_ccixattr->SetRespAttr(RespAttr_CompAck);
			}
		}

		void ccix2chi()
		{
			// Convert extension
			m_chiattr->SetTgtID(m_ccixattr->GetTgtID());
			m_chiattr->SetSrcID(m_ccixattr->GetSrcID());
			m_chiattr->SetTxnID(m_ccixattr->GetTxnID());

			if (IsSnpRespData()) {

				ParseSnpRespData();

			} else if (IsSnpRespDataPtl()) {

				ParseSnpRespDataPtl();

			} else if (IsSnpResp()) {

				ParseSnpResp();

			} else if (IsCompAck()) {

				m_chiattr->SetOpcode(Rsp::CompAck);
			}

			m_chiattr->SetNonSecure(m_ccixattr->GetNonSecure());
			m_chiattr->SetQoS(m_ccixattr->GetQoS());
		}

		void ParseSnpResp()
		{
			m_chiattr->SetOpcode(Rsp::SnpResp);

			switch(m_ccixattr->GetRespAttr()) {
			case RespAttr_SnpResp_I:
				m_chiattr->SetResp(CHI_SnpResp_I);
				break;
			case RespAttr_SnpResp_UC:
				m_chiattr->SetResp(CHI_SnpResp_UC_UD);
				break;
			case RespAttr_SnpResp_SC:
				m_chiattr->SetResp(CHI_SnpResp_SC);
				break;
			default:
				SC_REPORT_ERROR("CCIXPort", "SnpResp error");
				break;
			}
		}

		void ParseSnpRespData()
		{
			m_chiattr->SetOpcode(Dat::SnpRespData);

			if (m_ccixattr->GetRespOp() < RespOp_SnpRespData_I_PD) {
				switch(m_ccixattr->GetRespAttr()) {
				case RespAttr_SnpRespData_I:
					m_chiattr->SetResp(CHI_SnpRespData_I);
					break;

				case RespAttr_SnpRespData_SC:
					m_chiattr->SetResp(CHI_SnpRespData_SC);
					break;

				case RespAttr_SnpRespData_UC:
				case RespAttr_SnpRespData_UD:
					m_chiattr->SetResp(
						CHI_SnpRespData_UC_UD);
					break;

				case RespAttr_SnpRespData_SD:
					m_chiattr->SetResp(CHI_SnpRespData_SD);
					break;
				default:
					SC_REPORT_ERROR("CCIXPort",
						"SnpRespData error");
					break;
				}
			} else {
				switch(m_ccixattr->GetRespAttr()) {
				case RespAttr_SnpRespData_I_PD:
					m_chiattr->SetResp(
						CHI_SnpRespData_I_PD);

					break;
				case RespAttr_SnpRespData_UC_PD:
					m_chiattr->SetResp(
						CHI_SnpRespData_UC_PD);

					break;
				case RespAttr_SnpRespData_SC_PD:
					m_chiattr->SetResp(
						CHI_SnpRespData_SC_PD);

					break;
				default:
					SC_REPORT_ERROR("CCIXPort",
						"SnpRespData error");
					break;
				}
			}
		}

		void ParseSnpRespDataPtl()
		{
			m_chiattr->SetOpcode(Dat::SnpRespDataPtl);

			switch(m_ccixattr->GetRespAttr()) {
			case RespAttr_SnpRespDataPtl_I_PD:
				m_chiattr->SetResp(CHI_SnpRespDataPtl_I_PD);
				break;
			case RespAttr_SnpRespDataPtl_UD:
				m_chiattr->SetResp(CHI_SnpRespDataPtl_UD);
				break;
			default:
				SC_REPORT_ERROR("CCIXPort",
					"SnpRespDataPtl error");
				break;
			}
		}
	};

	class LinkCredits
	{
	public:
		LinkCredits(uint32_t initVal) :
			m_reqCredits(initVal),
			m_dataCredits(initVal),
			m_snoopCredits(initVal),
			m_miscCredits(initVal)
		{}

		void IncReq(uint32_t val = 1) { m_reqCredits += val; };
		void IncData(uint32_t val = 1) { m_dataCredits += val; };
		void IncSnoop(uint32_t val = 1) { m_snoopCredits += val; };
		void IncMisc(uint32_t val = 1) { m_miscCredits += val; };

		void DecReq(uint32_t val = 1) { m_reqCredits -= val; }
		void DecData(uint32_t val = 1) { m_dataCredits -= val; }
		void DecSnoop(uint32_t val = 1) { m_snoopCredits -= val; }
		void DecMisc(uint32_t val = 1) { m_miscCredits -= val; }

		uint32_t GetReqCredits() { return m_reqCredits; }
		uint32_t GetDataCredits() { return m_dataCredits; }
		uint32_t GetSnoopCredits() { return m_snoopCredits; }
		uint32_t GetMiscCredits() { return m_miscCredits; }

		bool HasCredits()
		{
			return m_reqCredits > 0 || m_dataCredits > 0 ||
				m_snoopCredits > 0 || m_miscCredits;
		}

	private:
		uint32_t m_reqCredits;
		uint32_t m_dataCredits;
		uint32_t m_snoopCredits;
		uint32_t m_miscCredits;
	};

	class CCIXMisc :
		public ITxn
	{
	public:
		using ITxn::m_gp;
		using ITxn::m_ccixattr;

		enum {
			//
			// See 3.7.2.3 [2]
			//
			Max_Msg_Credits = 255,
		};

		//
		// Outgoing CCIXMisc (toward CXS)
		//
		CCIXMisc(LinkCredits& credits,
				uint8_t SrcID,
				uint8_t TgtID,
				uint8_t MsgType = Msg::Type::MiscUnCredited,
				uint8_t MiscOp = Msg::MiscOp::CreditGrant) :
			ITxn()
		{
			m_ccixattr->SetSrcID(SrcID);
			m_ccixattr->SetTgtID(TgtID);

			m_ccixattr->SetMsgType(MsgType);
			m_ccixattr->SetMiscOp(MiscOp);

			SetupCredits(credits);
		}
	private:
		void SetupCredits(LinkCredits& credits)
		{
			uint32_t crdts;

			// Req
			crdts = (credits.GetReqCredits() > Max_Msg_Credits) ?
						Max_Msg_Credits :
						credits.GetReqCredits();

			m_ccixattr->SetReqCredit(crdts);
			credits.DecReq(crdts);

			// Data
			crdts = (credits.GetDataCredits() > Max_Msg_Credits) ?
						Max_Msg_Credits :
						credits.GetDataCredits();

			m_ccixattr->SetDataCredit(crdts);
			credits.DecData(crdts);

			// Snoop
			crdts = (credits.GetSnoopCredits() > Max_Msg_Credits) ?
						Max_Msg_Credits :
						credits.GetSnoopCredits();

			m_ccixattr->SetSnpCredit(crdts);
			credits.DecSnoop(crdts);

			// Misc
			crdts = (credits.GetMiscCredits() > Max_Msg_Credits) ?
						Max_Msg_Credits :
						credits.GetMiscCredits();

			m_ccixattr->SetMiscCredit(crdts);
			credits.DecMisc(crdts);
		}
	};

	class CCIXLink :
		public sc_core::sc_module
	{
	public:

		SC_HAS_PROCESS(CCIXLink);

		CCIXLink(sc_module_name name,
				uint16_t SrcID,
				tlm_utils::simple_initiator_socket<CCIXPort>&
							txlink_init_socket) :

			sc_core::sc_module(name),

			m_txlink_init_s(txlink_init_socket),

			//
			// While max CCIX credits [2] are 1023 we are limited to
			// 256 on the reqs/snpreqs, this because the CHI TxnID
			// is 8 bits. For simplicity use the same max on the
			// MiscCredits
			//
			m_txCredits(TxnIDs::NumIDs),
			m_rxCredits(0),

			m_SrcID(SrcID),
			m_TgtID(0)
		{
			//
			// Be sure that the CHI ID is CCIX compatible
			//
			assert((SrcID >> 6) == 0);

			SC_THREAD(tx_thread);
		}

		//
		// Uncredited
		//
		void TransmitUnCredited(ITxn *t)
		{
			TransmitTxn(t);
		}

		void Transmit(CCIXReq *req)
		{
			WaitForCredits(req);

			m_rxCredits.DecReq();
			if (req->IsWrite()) {
				m_rxCredits.DecData();
			}

			TransmitTxn(req);
		}

		void Transmit(CCIXSnpReq *snp)
		{
			if (m_rxCredits.GetSnoopCredits() == 0) {
				wait(m_rxCreditsEvent);
			}

			m_rxCredits.DecSnoop();

			TransmitTxn(snp);
		}

		void Transmit(CCIXMisc *misc)
		{
			if (m_rxCredits.GetMiscCredits() == 0) {
				wait(m_rxCreditsEvent);
			}

			m_rxCredits.DecMisc();

			TransmitTxn(misc);
		}

		void ReturnTxReqCredits()
		{
			m_txCredits.IncReq();
			m_txEvent.notify();
		}

		void ReturnTxDataCredits()
		{
			m_txCredits.IncData();
			m_txEvent.notify();
		}

		void ReturnTxSnoopCredits()
		{
			m_txCredits.IncSnoop();
			m_txEvent.notify();
		}

		void ReturnTxMiscCredits()
		{
			m_txCredits.IncMisc();
			m_txEvent.notify();
		}

		void UpdateRxCredits(ccixattr_extension *ccix)
		{
			m_rxCredits.IncReq(ccix->GetReqCredit());
			m_rxCredits.IncData(ccix->GetDataCredit());
			m_rxCredits.IncSnoop(ccix->GetSnpCredit());
			m_rxCredits.IncMisc(ccix->GetMiscCredit());

			m_rxCreditsEvent.notify();
		}

		//
		// Handle piggybacked credits
		//
		void UpdateRxCredits(uint8_t MsgCredit)
		{
			m_rxCredits.IncReq(ExtractReq(MsgCredit));
			m_rxCredits.IncData(ExtractData(MsgCredit));
			m_rxCredits.IncSnoop(ExtractSnoop(MsgCredit));

			m_rxCreditsEvent.notify();
		}

		void SetTgtID(uint8_t TgtID)
		{
			//
			// Be sure that the ID is CCIX compatible
			//
			assert((TgtID >> 6) == 0);

			m_TgtID = TgtID;
		}

		uint8_t GetCHIReqID() { return m_reqIDs.GetID(); }
		void ReturnCHIReqID(uint8_t txnID, bool hasData)
		{
			m_reqIDs.ReturnID(txnID);

			ReturnTxReqCredits();

			if (hasData) {
				ReturnTxDataCredits();
			}
		}

		uint8_t GetCHISnpReqID() { return m_snpReqIDs.GetID(); }
		void ReturnCHISnpReqID(uint8_t txnID)
		{
			m_snpReqIDs.ReturnID(txnID);
			ReturnTxSnoopCredits();
		}

	private:
		enum {
			MsgCrdt_ReqShift = 0,
			MsgCrdt_DataShift = 2,
			MsgCrdt_SnoopShift = 2,

			MsgCrdt_Mask = 0x3,
		};

		uint32_t ExtractReq(uint8_t MsgCredit)
		{
			return (MsgCredit >> MsgCrdt_ReqShift) & MsgCrdt_Mask;
		}
		uint32_t ExtractData(uint8_t MsgCredit)
		{
			return (MsgCredit >> MsgCrdt_DataShift) & MsgCrdt_Mask;
		}
		uint32_t ExtractSnoop(uint8_t MsgCredit)
		{
			return (MsgCredit >> MsgCrdt_SnoopShift) & MsgCrdt_Mask;
		}

		void WaitForCredits(CCIXReq *req)
		{
			//
			// Wait for credits, also wait for data credits if the
			// req contains data (see section 3.7.1 [2]).
			//
			while (true) {
				bool hasCredits =
					m_rxCredits.GetReqCredits() > 0;

				if (hasCredits && req->IsWrite()) {
					uint32_t dataCrdts =
						m_rxCredits.GetDataCredits();

					hasCredits = dataCrdts > 0;
				}

				//
				// If there are credits, exit
				//
				if (hasCredits) {
					break;
				}

				wait(m_rxCreditsEvent);
			};
		}

		void TransmitTxn(ITxn *t)
		{
			m_txList.push_back(t);
			m_txEvent.notify();

			while (!t->GetTransmitDone()) {
				wait(m_txnDone);
			}
		}

		void tx_thread()
		{
			while (true) {
				//
				// Check if something is queued for tx
				//
				if (!m_txCredits.HasCredits() &&
					m_txList.empty()) {
					wait(m_txEvent);
				}

				//
				// Handle the credits first
				//
				if (m_txCredits.HasCredits()) {
					CCIXMisc msg(m_txCredits,
							m_SrcID,
							m_TgtID);

					Transmit(msg.GetGP());
				} else if (!m_txList.empty()) {

					ITxn *t = m_txList.front();

					m_txList.remove(t);

					Transmit(t->GetGP());

					t->SetTransmitDone();
					m_txnDone.notify();
				}
			}
		}

		void Transmit(tlm::tlm_generic_payload& gp)
		{
			sc_time delay(SC_ZERO_TIME);

			m_txlink_init_s->b_transport(gp, delay);

			assert(gp.get_response_status() ==
					tlm::TLM_OK_RESPONSE);

			wait(delay);
		}

		tlm_utils::simple_initiator_socket< CCIXPort>& m_txlink_init_s;

		LinkCredits m_txCredits;
		LinkCredits m_rxCredits;

		std::list<ITxn*> m_txList;

		sc_event m_txEvent;
		sc_event m_rxCreditsEvent;
		sc_event m_txnDone;

		//
		// TxnIDs used on the CHI side
		//
		TxnIDs m_reqIDs;
		TxnIDs m_snpReqIDs;

		//
		// SrcID and TgtID used in generated CCIXMisc messages
		//
		uint8_t m_SrcID;
		uint8_t m_TgtID;
	};

	virtual void b_transport_rxlink(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		ccixattr_extension *attr;

		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);

		trans.get_extension(attr);
		if (attr) {
			ReceiveCCIX(trans, attr);
			trans.set_response_status(tlm::TLM_OK_RESPONSE);
		}
	}

	void Receive_CCIXReq(tlm::tlm_generic_payload& gp,
			ccixattr_extension *ccix)
	{
		CCIXReq *ccixReq = new CCIXReq(gp, ccix);
		ReqTxn *req = new ReqTxn(ccixReq->GetGP());
		uint8_t txnID = m_ccixLink.GetCHIReqID();

		ccixReq->SetCHITxnID(txnID);
		req->GetCHIAttr()->SetTxnID(txnID);

		m_reqOrderer->ProcessReq(req);

		m_ccix_HN.push_back(ccixReq);
	}

	void Receive_CCIXResp(tlm::tlm_generic_payload& gp,
			ccixattr_extension *ccix)
	{
		CCIXResp ccixRsp(gp, ccix);

		if (ccixRsp.IsCompData()) {
			//
			// Handle incoming CCIX CompData at RN (always HN -> RN)
			//
			CCIXReq *ccixReq = GetCCIXReq(ccixRsp.GetCCIXID(),
							m_ccix_RN_ongoing);
			assert(ccixReq);
			if (ccixReq) {
				DatMsg *dat;

				//
				// Handle the case when data length <
				// CACHELINE_SZ
				//
				if (ccixReq->GetReqSize() < CACHELINE_SZ) {
					ccixRsp.GenerateCHIData(ccixReq);
				}

				dat = new DatMsg(&ccixRsp.GetGP(),
						ccixRsp.GetCHIAttr());

				//
				// Propagate QoS
				//
				dat->GetCHIAttr()->SetQoS(ccixReq->GetCHIQoS());

				if (ccixReq->GetExpCompAck()) {
					//
					// Route the CompAck to the other HN
					//
					dat->SetDBID(m_ids->GetID());
					dat->GetCHIAttr()->SetHomeNID(
							dat->GetSrcID());

					//
					// Keep track of DBID
					//
					ccixReq->SetDBID(dat->GetDBID());
				} else {
					//
					// CCIX Atomic non stores ends here and
					// ReadNoSnp
					//
					CCIXReq_Done_RN(ccixReq);
				}

				m_router->RouteDat(*dat);

				delete dat;
			}

		} else if (ccixRsp.IsComp()) {
			//
			// Handle incoming CCIX Comp at RN (always HN -> RN)
			//
			CCIXID id(ccixRsp.GetTgtID(), ccixRsp.GetCHITxnID());
			CCIXReq *ccixReq = GetCCIXReq(id, m_ccix_RN_ongoing);

			assert(ccixReq);
			if (ccixReq) {
				//
				// CCIX DataLess forwards Comp to the CHI side
				// and migth require waiting for CompAck
				//
				if (ccixReq->IsDataLess()) {
					RspMsg rsp(&ccixRsp.GetGP(),
							ccixRsp.GetCHIAttr());

					//
					// Propagate QoS
					//
					rsp.GetCHIAttr()->SetQoS(
						ccixReq->GetCHIQoS());

					//
					// Is CCIX DataLess with CompAck
					//
					if (ccixReq->GetExpCompAck()) {
						//
						// Route the CompAck to the
						// other HN
						//
						rsp.GetCHIAttr()->SetHomeNID(
							ccixRsp.GetSrcID());

						rsp.SetDBID(m_ids->GetID());

						//
						// Keep track of DBID
						//
						ccixReq->SetDBID(rsp.GetDBID());
					}

					//
					// Set dataless response (CHI)
					//
					rsp.GetCHIAttr()->SetResp(
						ccixReq->GetDataLessResp());

					//
					// Transmit CHI rsp
					//
					m_router->RouteRsp(rsp);

					//
					// Dataless withot CompAck ends here
					//
					if (!ccixReq->GetExpCompAck()) {
						CCIXReq_Done_RN(ccixReq);
					}

				} else {
					//
					// Writes / AtomicStores end after Comp
					//
					CCIXReq_Done_RN(ccixReq);
				}
			}
		}
	}

	void Receive_CCIXSnpReq(tlm::tlm_generic_payload& gp,
			ccixattr_extension *ccix)
	{
		CCIXSnpReq *ccixSnp = new CCIXSnpReq(gp, ccix);
		SnpMsg msg(ccixSnp->GetGP());
		uint8_t chiTxnID = m_ccixLink.GetCHISnpReqID();

		msg.GetCHIAttr()->SetTxnID(chiTxnID);
		ccixSnp->SetCHITxnID(chiTxnID);

		m_router->RouteSnpReq(msg);

		m_ccix_RN_SnpReq.push_back(ccixSnp);
	}

	void Receive_CCIXSnpResp(tlm::tlm_generic_payload& gp,
			ccixattr_extension *ccix)
	{
		CCIXSnpResp ccixRsp(gp, ccix);

		if (ccixRsp.IsSnpResp()) {

			RspMsg rsp(&ccixRsp.GetGP(), ccixRsp.GetCHIAttr());

			m_router->RouteRsp(rsp);

		} else if (ccixRsp.IsSnpRespData() ||
				ccixRsp.IsSnpRespDataPtl()) {

			DatMsg dat(&ccixRsp.GetGP(), ccixRsp.GetCHIAttr());

			m_router->RouteDat(dat);

		} else {
			//
			// Handle incoming CCIX CompAck at HN (always RN -> HN)
			//
			CCIXReq *ccixReq = GetCCIXReq(ccixRsp.GetCCIXID(),
							m_ccix_HN);

			assert(ccixRsp.IsCompAck());
			assert(ccixReq && ccixReq->GetExpCompAck());

			if (ccixReq && ccixReq->GetExpCompAck()) {
				RspMsg rsp(ccixRsp.GetGP());

				//
				// Remap the TxnID to be the CHI DBID stored
				// in the CCIX req. This is because DBID
				// HomeNID is not used with CCIX.
				//
				rsp.GetCHIAttr()->SetTxnID(ccixReq->GetDBID());

				//
				// Propagate QoS
				//
				rsp.GetCHIAttr()->SetQoS(ccixReq->GetCHIQoS());

				m_router->RouteRsp(rsp);

				// CCIX Req is done now
				CCIXReq_Done_HN(ccixReq, false);
			}
		}
	}

	void ReceiveCCIX(tlm::tlm_generic_payload& gp,
				ccixattr_extension *ccix)
	{
		//
		// Handle piggybacked credits
		//
		if (ccix->GetMsgCredit()) {
			m_ccixLink.UpdateRxCredits(ccix->GetMsgCredit());
		}

		switch (ccix->GetMsgType()) {
		case Msg::Type::Req:
			Receive_CCIXReq(gp, ccix);
			break;
		case Msg::Type::SnpReq:
			Receive_CCIXSnpReq(gp, ccix);
			break;
		case Msg::Type::Resp:
			Receive_CCIXResp(gp, ccix);
			break;
		case Msg::Type::SnpResp:
			Receive_CCIXSnpResp(gp, ccix);
			break;
		case Msg::Type::MiscUnCredited:
			m_ccixLink.UpdateRxCredits(ccix);
			break;
		default:
			break;
		}
	}

	//
	// Request ordering at RN side
	//
	void req_ordering_thread()
	{
		while (true) {
			sc_time delay(SC_ZERO_TIME);
			CCIXReq *ccixReq;

			if (m_ccix_RN.empty()) {
				wait(m_pushEvent);
			}

			ccixReq = m_ccix_RN.front();
			assert(ccixReq);

			m_ccix_RN.remove(ccixReq);
			m_ccix_RN_ongoing.push_back(ccixReq);

			m_ccixLink.Transmit(ccixReq);

			//
			// One at a time
			//
			if (Ongoing(ccixReq)) {
				wait(m_removeEvent);
			}
		}
	}

	bool Ongoing(CCIXReq *ccixReq)
	{
		typename std::list<CCIXReq*>::iterator it;
		for (it = m_ccix_RN_ongoing.begin();
			it != m_ccix_RN_ongoing.end(); it++) {

			if ((*it) == ccixReq) {
				return true;
			}
		}
		return false;
	}

	void RN_Transmit_CCIXReq(CCIXReq *ccixReq)
	{
		assert(ccixReq);
		m_ccix_RN.push_back(ccixReq);
		m_pushEvent.notify();
	}

	CCIXReq *GetCCIXReq(CCIXID& id, std::list<CCIXReq*>& l)
	{
		typename std::list<CCIXReq*>::iterator it;

		for (it = l.begin(); it != l.end(); it++) {
			CCIXReq *ccixReq = (*it);

			if (ccixReq->GetCCIXID() == id) {
				return ccixReq;
			}
		}
		return NULL;
	}

	CCIXSnpReq *GetCCIXSnpReq(CCIXID& id, std::list<CCIXSnpReq*>& l)
	{
		typename std::list<CCIXSnpReq*>::iterator it;

		for (it = l.begin(); it != l.end(); it++) {
			CCIXSnpReq *snpReq = (*it);

			if (snpReq->GetSrcID() == id.GetSrcID() &&
				snpReq->GetCHITxnID() == id.GetTxnID()) {
				return snpReq;
			}
		}
		return NULL;
	}

	CCIXReq *GetCCIXReq_by_CHI_TxnID(CCIXID& id, std::list<CCIXReq*>& l)
	{
		typename std::list<CCIXReq*>::iterator it;

		for (it = l.begin(); it != l.end(); it++) {
			CCIXReq *ccixReq = (*it);

			if (ccixReq->GetSrcID() == id.GetSrcID() &&
				ccixReq->GetCHITxnID() == id.GetTxnID()) {
				return ccixReq;
			}
		}
		return NULL;
	}

	CCIXReq *GetCCIXReq_by_DBID(uint8_t DBID, std::list<CCIXReq*>& l)
	{
		typename std::list<CCIXReq*>::iterator it;

		for (it = l.begin(); it != l.end(); it++) {
			CCIXReq *ccixReq = (*it);

			if (ccixReq->GetDBID() == DBID) {
				return ccixReq;
			}
		}
		return NULL;
	}

	void CHI_RequestDone(ReqTxn* req)
	{
		m_reqOrderer->ReqDone(req);
	}

	void CCIXReq_Done_RN(CCIXReq *ccixReq)
	{
		m_ccix_RN_ongoing.remove(ccixReq);
		delete ccixReq;
		m_removeEvent.notify();
	}

	void CCIXReq_Done_HN(CCIXReq *ccixReq, bool hasData)
	{
		m_ccixLink.ReturnCHIReqID(ccixReq->GetCHITxnID(), hasData);
		m_ccix_HN.remove(ccixReq);
		delete ccixReq;
	}

	void CCIXSnpReq_Done_RN(CCIXSnpReq *ccixSnp)
	{
		m_ccixLink.ReturnCHISnpReqID(ccixSnp->GetCHITxnID());
		m_ccix_RN_SnpReq.remove(ccixSnp);
		delete ccixSnp;
	}

	IPacketRouter *m_router;
	RequestOrderer *m_reqOrderer;
	TxnIDs *m_ids;
	ReqTxn **m_ongoingTxn;

	sc_event m_pushEvent;
	sc_event m_removeEvent;

	//
	// CCIXLink
	//
	CCIXLink m_ccixLink;

	//
	// Tracks remote CCIX agents
	//
	std::vector<CCIXAgent> m_agents;

	//
	// HN side CCIX txns
	//
	std::list<CCIXReq*> m_ccix_HN;

	//
	// RN side CCIX txns
	//
	std::list<CCIXReq*> m_ccix_RN;
	std::list<CCIXReq*> m_ccix_RN_ongoing;
	std::list<CCIXSnpReq*> m_ccix_RN_SnpReq;

public:
	tlm_utils::simple_initiator_socket<CCIXPort> txlink_init_socket;
	tlm_utils::simple_target_socket<CCIXPort> rxlink_tgt_socket;

	SC_HAS_PROCESS(CCIXPort);

	CCIXPort(sc_module_name name,
			uint16_t SrcID,
			IPacketRouter *router,
			RequestOrderer *reqOrderer,
			TxnIDs *ids,
			ReqTxn **ongoingTxn) :
		sc_core::sc_module(name),

		m_router(router),
		m_reqOrderer(reqOrderer),
		m_ids(ids),
		m_ongoingTxn(ongoingTxn),

		m_ccixLink("ccix_link", SrcID, txlink_init_socket),

		txlink_init_socket("txlink_init_socket"),
		rxlink_tgt_socket("rxlink_tgt_socket")

	{
		rxlink_tgt_socket.register_b_transport(
				this, &CCIXPort::b_transport_rxlink);

		SC_THREAD(req_ordering_thread);
	}

	void ProcessReq(ReqTxn *req)
	{
		//
		// RN side
		//
		if (req->IsRead() || req->IsDataLess()) {

			RN_Transmit_CCIXReq(new CCIXReq(req));

			//
			// See Table 2-7 [1]
			//
			if (req->IsNonCoherentRead() &&
				req->IsOrdered()) {
				RspMsg *rsp = new RspMsg(req, Rsp::ReadReceipt);

				//
				// Swap the ID since the response comes from
				// the target
				//
				rsp->GetCHIAttr()->SetSrcID(req->GetTgtID());

				m_router->TransmitToRequestNode(rsp);
			}

			//
			// Req has now been propagated to the other side (HN)
			//
			CHI_RequestDone(req);

		} else if (req->IsWrite() || req->IsAtomicStore()) {
			RspMsg *rsp = new RspMsg(req, Rsp::CompDBIDResp);

			//
			// Swap the ID since the response comes from
			// the target
			//
			rsp->GetCHIAttr()->SetSrcID(req->GetTgtID());

			// HomeNID not used, see 2.6.3 [1]
			rsp->SetDBID(m_ids->GetID());
			m_ongoingTxn[rsp->GetDBID()] = req;

			if (req->IsWriteUnique() && req->GetExpCompAck()) {
				req->SetWaitingForCompAck(true);
			}

			//
			// Tx to RN for obtaining the data
			//
			m_router->TransmitToRequestNode(rsp);

		} else if (req->IsAtomic()) {
			//
			// AtomicStore i handled as an IsWrite, so only
			// the non store atomics are handled here
			//
			RspMsg *rsp = new RspMsg(req, Rsp::DBIDResp);

			//
			// Swap the ID since the response comes from
			// the target
			//
			rsp->GetCHIAttr()->SetSrcID(req->GetTgtID());

			// HomeNID not used, see 2.6.3 [1]
			rsp->SetDBID(m_ids->GetID());
			m_ongoingTxn[rsp->GetDBID()] = req;

			m_router->TransmitToRequestNode(rsp);
		}
	}

	void ProcessDat(DatMsg& dat)
	{
		if (dat.IsCompData()) {
			//
			// HN -> RN
			//
			CCIXID id(dat.GetTgtID(), dat.GetTxnID());

			CCIXReq *ccixReq = GetCCIXReq_by_CHI_TxnID(
						id, m_ccix_HN);

			assert(ccixReq);
			if (ccixReq) {
				CCIXResp ccixRsp(dat, ccixReq);

				//
				// Remap to CCIX TxnID
				//
				ccixRsp.SetCCIXTxnID(ccixReq->GetCCIXTxnID());

				//
				// Store HomeNID and DBID if CompAck is used
				// for being able to recreate the correct
				// values when the CompAck is received.
				//
				if (ccixReq->GetExpCompAck()) {
					ccixReq->SetHomeNID(
						dat.GetCHIAttr()->GetHomeNID());
					ccixReq->SetDBID(
						dat.GetDBID());
				} else {
					//
					// Atomics non stores and ReadNoSnp are
					// now done
					//
					CCIXReq_Done_HN(ccixReq,
						ccixReq->IsAtomicNonStore());
				}

				m_ccixLink.TransmitUnCredited(&ccixRsp);
			}

		} else if (dat.IsCopyBackWrData()) {
			//
			// RN side
			//
			// CopyBackWrData is received at the RN side before
			// transmitting a CCIX Write request
			//
			ReqTxn *req = m_ongoingTxn[dat.GetTxnID()];

			assert(req);

			//
			// CCIX only forwards Dirty data (see commands
			// WriteBackFull UD/SD, WriteCleanFullSD)
			//
			if (dat.GetPassDirty()) {
				RN_Transmit_CCIXReq(new CCIXReq(req, dat));
			}

			//
			// CHI req done on RN iconnect, delete the CHI req only
			// if CompAck is not expected
			//
			if (!req->GetWaitingForCompAck()) {
				uint16_t txnID = dat.GetTxnID();

				m_ids->ReturnID(txnID);
				m_ongoingTxn[txnID] = NULL;
				CHI_RequestDone(req);
			}

		} else if (dat.IsNonCopyBackWrData() ||
				dat.IsNonCopyBackWrDataCompAck()) {
			//
			// RN side
			//
			// NonCopyBackWrData is received at the RN side before
			// transmitting an CCIX WriteNoSnp/Atomic request
			//
			uint16_t txnID = dat.GetTxnID();
			ReqTxn *req = m_ongoingTxn[txnID];
			bool WriteUniqueDone;

			assert(req);
			assert(req->IsWrite() || req->IsAtomic());

			RN_Transmit_CCIXReq(new CCIXReq(req, dat));

			//
			// CHI req is done at the RN iconnect unless it is a
			// WriteUnique/WriteUniquePtl containing a CompAck and
			// the CompAck has not yet been received.
			//
			WriteUniqueDone = req->IsWriteUnique() &&
						req->GetCompAckReceived();
			if (!req->GetWaitingForCompAck() ||
				WriteUniqueDone) {
				m_ids->ReturnID(txnID);
				m_ongoingTxn[txnID] = NULL;
				CHI_RequestDone(req);
			} else if (req->IsWriteUnique()) {
				//
				// CCIXReq has been transmitted, wait for the
				// CHI CompAck on the RN side
				//
				req->SetWriteToSNDone(true);
			}

		} else if (dat.IsSnpRespData() || dat.IsSnpRespDataPtl()) {
			//
			// RN -> HN
			//
			CCIXID id(dat.GetTgtID(), dat.GetTxnID());

			CCIXSnpReq *ccixSnp = GetCCIXSnpReq(id,
						m_ccix_RN_SnpReq);

			CCIXSnpResp ccixSnpRsp(dat);

			assert(ccixSnp);

			ccixSnpRsp.SetCCIXTxnID(ccixSnp->GetCCIXTxnID());

			m_ccixLink.TransmitUnCredited(&ccixSnpRsp);

			//
			// SnpReq is done
			//
			CCIXSnpReq_Done_RN(ccixSnp);
		}
	}

	void ProcessResp(RspMsg& rsp)
	{
		if (rsp.IsCompAck()) {
			//
			// Outgoing CompAck is sent from RN -> HN
			//
			CCIXID id(rsp.GetSrcID(), rsp.GetTxnID());
			uint16_t txnID = rsp.GetTxnID();
			ReqTxn *req = m_ongoingTxn[txnID];
			CCIXReq *ccixReq;

			//
			// CHI side WriteUniques with CompAck might end here,
			// also the corresponding CCIX req will be done once
			// the CCIX Comp has been received so return in that
			// case
			//
			if (req && req->IsWriteUnique()) {

				if (req->GetWriteToSNDone()) {
					m_ids->ReturnID(txnID);
					m_ongoingTxn[txnID] = NULL;

					CHI_RequestDone(req);
				} else {
					//
					// The CompAck was received before the
					// WriteData for the WriteUnique, so
					// just wait for the data
					//
					req->SetCompAckReceived(true);
				}
				return;
			}

			ccixReq = GetCCIXReq_by_DBID(rsp.GetTxnID(),
							m_ccix_RN_ongoing);

			assert(ccixReq);
			if (ccixReq) {
				//
				// Only CCIX Full Coherent reads and Dataless
				// with CompAck transmit CompAck
				//
				if (ccixReq->GetExpCompAck()) {
					CCIXSnpResp ccixSnpRsp(rsp);
					uint8_t ccixTxnID =
						ccixReq->GetCCIXID().GetTxnID();

					ccixSnpRsp.SetCCIXTxnID(ccixTxnID);

					m_ccixLink.TransmitUnCredited(
								&ccixSnpRsp);

					ccixReq->SetExpCompAck(false);

				}

				//
				// CCIX Req done at the RN side
				//
				if (!ccixReq->GetExpCompAck()) {
					m_ids->ReturnID(ccixReq->GetDBID());
					CCIXReq_Done_RN(ccixReq);
				}
			}

		} else if (rsp.IsComp()) {
			//
			// HN transmitting CCIX Comp (DataLess txns)
			//
			CCIXID id(rsp.GetTgtID(), rsp.GetTxnID());

			CCIXReq *ccixReq = GetCCIXReq_by_CHI_TxnID(
							id, m_ccix_HN);

			assert(ccixReq);
			if (ccixReq) {
				CCIXResp ccixRsp(ccixReq);

				//
				// Remap to CCIX TxnID
				//
				ccixRsp.SetCCIXTxnID(ccixReq->GetCCIXTxnID());

				//
				// Store HomeNID and DBID if CompAck is used
				// for being able to recreate the correct
				// values when the CCIX CompAck is received.
				//
				if (ccixReq->GetExpCompAck()) {
					ccixReq->SetDBID(rsp.GetDBID());
					ccixReq->SetHomeNID(
						rsp.GetCHIAttr()->GetHomeNID());
				}

				//
				// Outgoing CCIX comp
				//
				m_ccixLink.TransmitUnCredited(&ccixRsp);

				//
				// The CCIX Req is done at the HN side
				// (DataLess without CompAck)
				//
				if (!ccixReq->GetExpCompAck()) {
					bool hasData = !ccixReq->IsDataLess();

					CCIXReq_Done_HN(ccixReq, hasData);
				}
			}

		} else if (rsp.IsCompDBIDResp() || rsp.IsDBIDResp()) {
			//
			// CompDBID is HN side only (for obtaining the Write /
			// Atomic Data)
			//
			CCIXID id(rsp.GetTgtID(), rsp.GetTxnID());

			CCIXReq *ccixReq = GetCCIXReq_by_CHI_TxnID(
							id, m_ccix_HN);

			assert(ccixReq);
			if (ccixReq) {
				DatMsg dat(ccixReq->GetDatGP(),
						ccixReq->GetDatAttr(rsp));

				m_router->RouteDat(dat);

				//
				// Atomic stores will get Comp, atomic non
				// stores will get CompData
				//
				if (!ccixReq->IsAtomicNonStore()) {
					CCIXResp ccixRsp(ccixReq);

					//
					// Remap to CCIX TxnID
					//
					ccixRsp.SetCCIXTxnID(
						ccixReq->GetCCIXTxnID());

					//
					// Outgoing CCIX comp
					//
					m_ccixLink.TransmitUnCredited(&ccixRsp);

					//
					// CCIX Req done at the HN side
					//
					CCIXReq_Done_HN(ccixReq, true);
				}
			}
		} else if (rsp.IsSnpResp()) {
			//
			// RN -> HN
			//
			CCIXID id(rsp.GetTgtID(), rsp.GetTxnID());

			CCIXSnpReq *ccixSnp = GetCCIXSnpReq(id,
							m_ccix_RN_SnpReq);

			CCIXSnpResp ccixSnpRsp(rsp);

			assert(ccixSnp);

			//
			// Use the same txnID as the the CCIX snoop request
			//
			ccixSnpRsp.SetCCIXTxnID(ccixSnp->GetCCIXTxnID());

			m_ccixLink.TransmitUnCredited(&ccixSnpRsp);

			//
			// SnpReq is done
			//
			CCIXSnpReq_Done_RN(ccixSnp);
		}
	}

	bool NeedsSnoop(ReqTxn *req)
	{
		typename std::vector<CCIXAgent>::iterator it;

		for (it = m_agents.begin(); it != m_agents.end(); it++) {
			CCIXAgent& agent = (*it);

			if (agent.GetID() != req->GetSrcID() ||
				req->GetSnpMe()) {

				SnoopFilter& snpFilter =
					agent.GetSnoopFilter();

				Address addr(req);

				if (snpFilter.ContainsAllocated(addr)) {
					return true;
				}
			}
		}
		return false;
	}

	void Transmit(ReqTxn *req, SnpMsg& msg)
	{
		typename std::vector<CCIXAgent>::iterator it;

		for (it = m_agents.begin(); it != m_agents.end(); it++) {
			CCIXAgent& agent = (*it);

			SnoopFilter& snpFilter = agent.GetSnoopFilter();

			Address addr(req);

			if (snpFilter.ContainsAllocated(addr)) {
				CCIXSnpReq ccixSnp(agent, req, msg);

				m_ccixLink.Transmit(&ccixSnp);
			}
		}
	}

	void UpdateSnoopFilter(ReqTxn *req)
	{
		typename std::vector<CCIXAgent>::iterator it;

		assert(!m_agents.empty());

		for (it = m_agents.begin(); it != m_agents.end(); it++) {
			CCIXAgent& agent = (*it);

			if (agent.GetID() == req->GetSrcID()) {
				agent.GetSnoopFilter().Update(req);
			}
		}
	}

	template<typename MsgType>
	void UpdateSnoopFilter(MsgType& msg, ReqTxn *req)
	{
		typename std::vector<CCIXAgent>::iterator it;

		assert(!m_agents.empty());

		for (it = m_agents.begin(); it != m_agents.end(); it++) {
			CCIXAgent& agent = (*it);

			if (agent.GetID() == req->GetSrcID()) {
				agent.GetSnoopFilter().Update(msg, req);
			}
		}
	}

	bool Contains(uint16_t id)
	{
		typename std::vector<CCIXAgent>::iterator it;

		assert(!m_agents.empty());

		for (it = m_agents.begin(); it != m_agents.end(); it++) {

			if ((*it).GetID() == id) {
				return true;
			}
		}
		return false;
	}

	void AddRemoteAgent(uint16_t id)
	{
		m_agents.push_back(CCIXAgent(id));

		//
		// Only one link connection is supported at the moment
		//
		m_ccixLink.SetTgtID(id);
	}
};

} /* namespace CCIX */

#endif /* TLM_MODULES_PRIV_CCIX_PORT_H__ */
