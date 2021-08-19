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

#ifndef TLM_MODULES_ICONNECT_CHI_H__
#define TLM_MODULES_ICONNECT_CHI_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/chiattr.h"
#include "tlm-bridges/amba-chi.h"
#include "tlm-modules/private/chi/txnids.h"
#include "tlm-modules/private/ccix/ccixport.h"

using namespace AMBA::CHI;

template<
	int NODE_ID = 20,
	int SLAVE_NODE_ID = 10,
	int NUM_CHI_RN_F = 2,
	int NUM_CCIX_PORTS = 0
	>
class iconnect_chi :
	public sc_core::sc_module
{
private:
	class SnpTxnTracker
	{
	public:
		SnpTxnTracker(uint8_t txnID) :
			m_txnID(txnID),
			m_resp(0),
			m_done(false),
			m_dataReceived(0)
		{}

		uint8_t GetTxnID() { return m_txnID; }

		void ReceivedBytes(unsigned int n)
		{
			m_dataReceived += n;
		}

		//
		// For being able to mark done when a no data responses is
		// received.
		//
		void SetDone(bool val) { m_done = val; }

		bool Done() { return m_done || m_dataReceived == CACHELINE_SZ; }

		bool ReceivedData() { return m_dataReceived == CACHELINE_SZ; }

		void SetResp(uint8_t resp) { m_resp = resp; }

		enum { CacheStateMask = 0x3,
			PassDirtyShift = 2,
			PassDirtyMask = 0x1 };

		uint8_t GetRespCacheState()
		{
			return m_resp & CacheStateMask;
		}

		bool GetRespPassDirty()
		{
			return (m_resp >> PassDirtyShift) & PassDirtyMask;
		}

	private:
		uint8_t m_txnID;
		uint8_t m_resp;
		bool m_done;
		unsigned int m_dataReceived;
	};

	class IMsg
	{
	public:
		IMsg(tlm::tlm_generic_payload *gp, chiattr_extension *chiattr) :
			m_gp(gp),
			m_chiattr(chiattr),
			m_delete(false)
		{}

		IMsg() :
			m_gp(new tlm::tlm_generic_payload()),
			m_chiattr(new chiattr_extension()),
			m_delete(true)
		{
			m_gp->set_data_ptr(m_data);
			m_gp->set_data_length(CACHELINE_SZ);

			m_gp->set_byte_enable_ptr(m_byteEnable);
			m_gp->set_byte_enable_length(CACHELINE_SZ);

			m_gp->set_streaming_width(CACHELINE_SZ);

			m_gp->set_extension(m_chiattr);
		}

		virtual ~IMsg()
		{
			if (m_delete) {
				// Also deletes extension
				delete m_gp;
			}
		}

		tlm::tlm_generic_payload& GetGP()
		{
			return *m_gp;
		}
		chiattr_extension *GetCHIAttr() { return m_chiattr; }

		uint8_t GetTxnID() { return m_chiattr->GetTxnID(); }
		uint16_t GetSrcID() { return m_chiattr->GetSrcID(); }
		uint16_t GetTgtID() { return m_chiattr->GetTgtID(); }

		uint8_t GetDBID() { return m_chiattr->GetDBID(); }
		void SetDBID(uint8_t DBID)
		{
			m_chiattr->SetDBID(DBID);
		}

	protected:

		tlm::tlm_generic_payload *m_gp;
		chiattr_extension *m_chiattr;

		uint8_t m_data[CACHELINE_SZ];
		uint8_t m_byteEnable[CACHELINE_SZ];

		bool m_delete;
	};

	class ReqTxn :
		public IMsg
	{
	public:

		using IMsg::m_gp;
		using IMsg::m_chiattr;
		using IMsg::m_data;
		using IMsg::m_byteEnable;

		//
		// Used when building ICN requests at ports, or retry requests
		// towards SN
		//
		ReqTxn(tlm::tlm_generic_payload& gp) :
			m_waitingForReadReceipt(false),
			m_waitingForCompAck(false),
			m_gotRetryAck(false),
			m_gotPCrdGrant(false),
			m_isSnpFwded(false),
			m_snpResp(0),
			m_snpDataFwded(false),
			m_gotSnpData(false),
			m_isSnpDataPtl(false),
			m_compAckReceived(false),
			m_writeToSNDone(false),
			m_compSNReceived(false),
			m_chiattrSN(new chiattr_extension),
			m_dataReceived(0)
		{
			m_gp->deep_copy_from(gp);

			// For storing SN requests (unused in a retry request)
			m_reqSNCopy.set_extension(m_chiattrSN);

			//
			// ReadOnce* without ExpCompAck will not receive
			// CompAck after a Snp*Fwd has forwarded data and ends after the
			// snoop response.
			//
			if (!GetExpCompAck()) {
				if (IsReadOnce() ||
					IsReadOnceCleanInvalid() ||
					IsReadOnceMakeInvalid()) {

					SetCompAckReceived(true);
				}
			}
		}


		enum { RequireReadReceipt = 1, };

		//
		// Used when building SN requests
		//
		ReqTxn(ReqTxn *req, uint8_t opcode, uint8_t txnID) :
			m_waitingForReadReceipt(false),
			m_waitingForCompAck(false),
			m_gotRetryAck(false),
			m_gotPCrdGrant(false),
			m_isSnpFwded(false),
			m_snpResp(0),
			m_snpDataFwded(false),
			m_gotSnpData(false),
			m_isSnpDataPtl(false),
			m_compAckReceived(false),
			m_writeToSNDone(false),
			m_compSNReceived(false),
			m_chiattrSN(NULL),
			m_dataReceived(0)
		{
			tlm::tlm_generic_payload& gp = req->GetGP();
			chiattr_extension *attr = req->GetCHIAttr();

			m_gp->set_address(gp.get_address());

			m_chiattr->SetQoS(attr->GetQoS());
			m_chiattr->SetTgtID(SLAVE_NODE_ID);
			m_chiattr->SetSrcID(NODE_ID);
			m_chiattr->SetTxnID(txnID);

			if (opcode == Req::ReadNoSnp ||
				IsAtomicNonStore(opcode)) {

				if (req->AllowsDMT()) {
					m_chiattr->SetReturnNID(attr->GetSrcID());
					m_chiattr->SetReturnTxnID(attr->GetTxnID());
				} else {
					m_chiattr->SetReturnNID(NODE_ID);
					m_chiattr->SetReturnTxnID(txnID);
				}
			}

			m_chiattr->SetOpcode(opcode);
			m_chiattr->SetNonSecure(attr->GetNonSecure());
			m_chiattr->SetLikelyShared(attr->GetLikelyShared());

			if (req->IsAtomic()) {
				m_gp->set_data_length(req->GetDataLenght());
			}

			//
			// Always set AllowRetry at first issue of the req,
			// 2.11.2 [1]
			//
			m_chiattr->SetAllowRetry(true);

			if (!req->IsOrdered() && !req->GetExpCompAck()) {
				m_chiattr->SetOrder(RequireReadReceipt);
			}

			m_chiattr->SetTraceTag(attr->GetTraceTag());

			// Store for Retry sequence
			req->CopyToRequestSN(m_gp);
		}

		tlm::tlm_generic_payload& GetReqSNCopy()
		{
			return m_reqSNCopy;
		}

		void CopyToRequestSN(tlm::tlm_generic_payload *gp)
		{
			m_reqSNCopy.deep_copy_from(*gp);
		}

		unsigned int GetDataLenght()
		{
			return m_gp->get_data_length();
		}

		uint8_t GetOpcode()
		{
			return m_chiattr->GetOpcode();
		}

		void SetWaitingForCompAck(bool val)
		{
			m_waitingForCompAck = val;
		}

		bool GetWaitingForCompAck() { return m_waitingForCompAck; }

		bool GetExpCompAck()
		{
			return m_chiattr->GetExpCompAck();
		}


		bool GetWaitingForReadReceipt() { return m_waitingForReadReceipt; }
		void SetWaitingForReadReceipt(bool val)
		{
			m_waitingForReadReceipt = val;
		}

		bool GetSnpMe()
		{
			// TODO
			return false;
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

		bool IsAtomicNonStore(uint8_t opcode)
		{
			return opcode >= Req::AtomicLoad &&
				opcode <= Req::AtomicCompare;
		}

		bool IsAtomicNonStore()
		{
			return m_chiattr->GetOpcode() >= Req::AtomicLoad &&
				m_chiattr->GetOpcode() <= Req::AtomicCompare;
		}

		bool IsAtomicStore()
		{
			uint8_t opcode = m_chiattr->GetOpcode();

			return opcode >= Req::AtomicStore && opcode < Req::AtomicLoad;
		}

		bool IsAtomicLoad()
		{
			uint8_t opcode = m_chiattr->GetOpcode();

			return opcode >= Req::AtomicLoad && opcode < Req::AtomicSwap;
		}

		bool IsAtomicCompare()
		{
			uint8_t opcode = m_chiattr->GetOpcode();

			return opcode == Req::AtomicCompare;
		}

		bool IsAtomicSwap()
		{
			uint8_t opcode = m_chiattr->GetOpcode();

			return opcode == Req::AtomicSwap;
		}

		bool IsAtomic()
		{
			uint8_t opcode = m_chiattr->GetOpcode();

			return opcode >= Req::AtomicStore &&
				opcode <= Req::AtomicCompare;
		}

		bool IsDVMOp()
		{
			return m_chiattr->GetOpcode() == Req::DVMOp;
		}

		bool IsSnpRead()
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

		bool IsReadOnce()
		{
			return m_chiattr->GetOpcode() == Req::ReadOnce;
		}

		bool IsReadOnceCleanInvalid()
		{
			return m_chiattr->GetOpcode() == Req::ReadOnceCleanInvalid;
		}

		bool IsReadOnceMakeInvalid()
		{
			return m_chiattr->GetOpcode() == Req::ReadOnceMakeInvalid;
		}

		//
		// Data will not remain coherent if keept in a local cache at
		// the requester, 4.2.1 [1]
		//
		bool IsNonCoherentRead()
		{
			switch(m_chiattr->GetOpcode()) {
			case Req::ReadNoSnp:
			case Req::ReadOnce:
			case Req::ReadOnceCleanInvalid:
			case Req::ReadOnceMakeInvalid:
				return true;
			}
			return false;
		}

		bool IsRead()
		{
			switch(m_chiattr->GetOpcode()) {
			case Req::ReadNoSnp:
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

		bool IsCopyBack()
		{
			switch(m_chiattr->GetOpcode()) {
			case Req::WriteBackFull:
			case Req::WriteBackPtl:
			case Req::WriteCleanFull:
			case Req::WriteEvictFull:
				return true;
			}
			return false;
		}

		bool IsSnoopingReq()
		{
			//
			// Table 4-3, 4.4 [1]
			//
			switch(m_chiattr->GetOpcode()) {
			// Read
			case Req::ReadOnce:
			case Req::ReadOnceCleanInvalid:
			case Req::ReadOnceMakeInvalid:
			case Req::ReadClean:
			case Req::ReadNotSharedDirty:
			case Req::ReadShared:
			case Req::ReadUnique:

			// Dataless
			case Req::CleanUnique:
			case Req::MakeUnique:
			case Req::CleanShared:
			case Req::CleanSharedPersist:
			case Req::CleanInvalid:
			case Req::MakeInvalid:

			// Dataless-stash
			case Req::StashOnceUnique:
			case Req::StashOnceShared:

			// Write
			case Req::WriteUniqueFull:
			case Req::WriteUniquePtl:

			// Write-stash
			case Req::WriteUniqueFullStash:
			case Req::WriteUniquePtlStash:

			// Atomic
			case Req::AtomicStore:
			case Req::AtomicLoad:
			case Req::AtomicSwap:
			case Req::AtomicCompare:

			// Others
			case Req::DVMOp:
				return true;
			}
			return false;
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

		bool IsCleanUnique()
		{
			return m_chiattr->GetOpcode() == Req::CleanUnique;
		}

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

		bool AllowsPassDirtySnpData()
		{
			if (m_isSnpDataPtl) {
				return false;
			}

			switch(m_chiattr->GetOpcode()) {
			case Req::ReadShared:
			case Req::ReadUnique:
				return true;
			}
			return false;
		}

		bool AllocatesCacheLine()
		{
			switch(m_chiattr->GetOpcode()) {
			case Req::ReadClean:
			case Req::ReadNotSharedDirty:
			case Req::ReadShared:
			case Req::ReadUnique:
				return true;
			}
			return false;
		}

		bool GetAllowRetry() { return m_chiattr->GetAllowRetry(); }

		bool IsEvict()
		{
			return m_chiattr->GetOpcode() == Req::Evict;
		}

		bool GetSnpAttr()
		{
			return m_chiattr->GetSnpAttr();
		}

		uint64_t GetAddress()
		{
			return m_gp->get_address();
		}

		bool GetNonSecure()
		{
			return m_chiattr->GetNonSecure();
		}

		//
		// Table 2-7 [1]
		//
		bool IsOrdered() { return m_chiattr->GetOrder() > 1; };
		uint8_t GetOrder() { return m_chiattr->GetOrder(); }

		void WaitForSnpTxn(uint8_t txnID)
		{
			SnpTxnTracker tracker(txnID);

			m_snpTrackers.push_back(tracker);
		}

		void SetIsSnpFwded(bool val) { m_isSnpFwded = val; }
		bool IsSnpFwded() { return m_isSnpFwded; }

		void SetSnpTxnDone(uint16_t txnID, uint8_t resp)
		{
			SnpTxnTracker *tracker = GetSnpTxnTracker(txnID);

			tracker->SetResp(resp);
			tracker->SetDone(true);
		}

		bool AllSnpTxnDone()
		{
			typename std::vector<SnpTxnTracker>::iterator it;

			for (it = m_snpTrackers.begin();
				it != m_snpTrackers.end(); it++) {
				SnpTxnTracker& tracker = (*it);

				if (!tracker.Done()) {
					return false;
				}
			}
			// All SnpTxnTrackers done!
			return true;
		}

		void CopySnpData(IMsg *t)
		{
			tlm::tlm_generic_payload& gp = t->GetGP();
			chiattr_extension *chiattr = t->GetCHIAttr();
			SnpTxnTracker *tracker = GetSnpTxnTracker(t->GetTxnID());

			assert(chiattr);
			assert(tracker);

			if (chiattr && tracker) {
				unsigned int n = this->CopyData(gp, chiattr);

				tracker->ReceivedBytes(n);
				tracker->SetResp(chiattr->GetResp());

				//
				// Consider data as received if all data (1
				// cache line) has been collected from 1
				// snooped RN-F.
				//
				if (tracker->ReceivedData()) {
					m_gp->set_data_length(CACHELINE_SZ);
					m_gp->set_byte_enable_length(CACHELINE_SZ);
				}

				if (chiattr->GetOpcode() ==
					Dat::SnpRespDataPtl) {
					m_isSnpDataPtl = true;
				}
			}
		}

		bool AllSnpDataReceived(uint8_t txnID)
		{
			SnpTxnTracker *tracker = GetSnpTxnTracker(txnID);

			return tracker->Done();
		}

		bool InitGotSnpData()
		{
			typename std::vector<SnpTxnTracker>::iterator it;

			for (it = m_snpTrackers.begin();
				it != m_snpTrackers.end(); it++) {
				SnpTxnTracker& tracker = (*it);

				if (tracker.ReceivedData()) {
					return true;
				}
			}
			return false;
		}

		bool GotSnpData()
		{
			return m_gotSnpData;
		}

		bool IsSnpDataPtl()
		{
			return m_isSnpDataPtl;
		}

		void SetGotSnpData(bool val) { m_gotSnpData = val; }

		enum {
			INV = 0x0,
			SC = 0x1,
			UC = 0x2,
			UD_PD = 0x6,
			SD_PD = 0x7 };

		bool AllowsDMT()
		{
			//
			// Need to fetch from SN into the ICN and
			// correct cache state since SN is permitted to
			// always return UC 4.7.1
			//
			// Also ExpCompAck needs to be set (or both
			// ExpCompAck and order are deasserted) 4.2.1 [1] (or
			// see table 2-6, 2.3.1 [1])
			//
			// Exclusive accesses don't allow DMT 4.2.1
			//
			if (m_snpResp && m_snpResp != UC) {
				return false;
			}
			if (!m_chiattr->GetExpCompAck() &&
				m_chiattr->GetOrder()) {
				return false;
			}
			if (m_chiattr->GetExcl()) {
				return false;
			}

			//
			// Finally let the SN process atomics
			//
			if (IsAtomic()) {
				return false;
			}
			return true;
		}

		//
		// Call this when constructing the DatMsg back to the RN-F with
		// snooped data, this is the allowed cache line state at the
		// requesting RN-F after snooping.
		//
		// This is also used when deciding if DMT will be used since
		// the SN always replies CompData_UC irrespective of the
		// original request, see 4.7.1 [1]
		//
		uint8_t GetSnpRespResult()
		{
			return m_snpResp;
		}

		bool GetSnpRespPassDirty()
		{
			return m_snpResp == UD_PD || m_snpResp == SD_PD;
		}

		void SnpRespPassDirtyClear()
		{
			if (m_snpResp == UD_PD) {
				m_snpResp = UC;
			} else if (m_snpResp == SD_PD) {
				m_snpResp = SC;
			}
		}

		void ParseSnpResponses()
		{
			typename std::vector<SnpTxnTracker>::iterator it;
			bool shared = false;
			bool passDirty = false;

			//
			// If the line is not invalid in one RN-F then it is
			// shared.
			//
			// If an RN-F passes dirty passDirty is set.
			//
			for (it = m_snpTrackers.begin();
				it != m_snpTrackers.end(); it++) {
				SnpTxnTracker& tracker = (*it);

				if (tracker.GetRespCacheState() != INV) {
					shared = true;
				}
				if (tracker.GetRespPassDirty()) {
					passDirty = true;
				}
			}

			if (shared && passDirty) {
				m_snpResp = SD_PD;
			} else if (!shared && passDirty) {
				m_snpResp = UD_PD;
			} else if (shared && !passDirty) {
				m_snpResp = SC;
			} else {
				// !shared && !passDirty
				m_snpResp = UC;
			}

			m_gotSnpData = InitGotSnpData();
		}

		void SetCompAckReceived(bool val)
		{
			m_compAckReceived = val;
		}

		bool GetCompAckReceived()
		{
			return m_compAckReceived;
		}

		//
		// For WriteUnique with CompAck and non store atomics
		//
		void SetWriteToSNDone(bool val) { m_writeToSNDone = val; }
		bool GetWriteToSNDone()
		{
			return m_writeToSNDone;
		}

		void SetCompSNReceived(bool val) { m_compSNReceived = val; }
		bool GetCompSNReceived()
		{
			return m_compSNReceived;
		}

		void SetSnpDataFwded(bool val) { m_snpDataFwded = val; }
		bool SnpDataFwded() { return m_snpDataFwded; }

		//
		// For retry sequence towards SN
		//
		bool RetryRequest()
		{
			return m_gotRetryAck && m_gotPCrdGrant;
		}

		void HandleRetryAck(chiattr_extension *chiattr)
		{
			//
			// Keep TgtID, Set PCrdType and deassert AllowRetry
			// 2.6.5 + 2.11.2 [1]
			//
			m_chiattrSN->SetAllowRetry(false);
			m_chiattrSN->SetPCrdType(chiattr->GetPCrdType());
			m_gotRetryAck = true;
		}

		void HandlePCrdGrant(chiattr_extension *chiattr)
		{
			// Only one transaction at a time so just keep track
			// that a PCrdGrant has been is received. Most likely
			// it will arrive after the RetryAck, but it can also
			// arrive before 2.3.2 [1].
			m_gotPCrdGrant = true;
		}

		uint8_t GetLPID() { return m_chiattr->GetLPID(); }
		uint8_t GetExcl() { return m_chiattr->GetExcl(); }
		uint8_t GetRespErr() { return m_chiattr->GetRespErr(); }
		void SetRespErr(uint8_t val)
		{
			m_chiattr->SetRespErr(val);
		}

		void CopyWriteData(IMsg *t, bool IsAtomic = false)
		{
			m_dataReceived += CopyData(t->GetGP(), t->GetCHIAttr());

			if (!IsAtomic) {
				m_gp->set_data_length(m_dataReceived);
				m_gp->set_byte_enable_length(m_dataReceived);
			}
		}

		bool AllWriteDataRecieved()
		{
			return m_dataReceived == CACHELINE_SZ;
		}

		unsigned int GetDataReceived() { return m_dataReceived; }

	private:

		unsigned int CopyData(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			unsigned char *srcData = gp.get_data_ptr();
			unsigned int len = gp.get_data_length();
			unsigned int offset = chiattr->GetDataID() * len;
			unsigned char *be = gp.get_byte_enable_ptr();
			unsigned int be_len = gp.get_byte_enable_length();
			unsigned int max_len = CACHELINE_SZ - offset;

			if (len > max_len) {
				len = max_len;
			}

			if (be_len) {
				unsigned int i;

				for (i = 0; i < len; i++) {
					bool do_access = be[i % be_len] == TLM_BYTE_ENABLED;

					if (do_access) {
						m_data[offset + i] = srcData[i];
						m_byteEnable[offset+i] = TLM_BYTE_ENABLED;
					} else {
						m_data[offset + i] = 0;
						m_byteEnable[offset+i] = TLM_BYTE_DISABLED;
					}
				}
			} else {
				memcpy(&m_data[offset], srcData, len);
				memset(&m_byteEnable[offset], TLM_BYTE_ENABLED, len);
			}

			return len;
		}

		SnpTxnTracker *GetSnpTxnTracker(uint8_t txnID)
		{
			typename std::vector<SnpTxnTracker>::iterator it;

			for (it = m_snpTrackers.begin();
				it != m_snpTrackers.end(); it++) {
				SnpTxnTracker& tracker = (*it);

				if (tracker.GetTxnID() == txnID) {
					return &tracker;
				}
			}
			return NULL;
		}

		std::list<uint16_t> m_snpIDs;
		bool m_waitingForReadReceipt;
		bool m_waitingForCompAck;

		//
		// For Retry sequence towards SN
		//
		bool m_gotRetryAck;
		bool m_gotPCrdGrant;

		bool m_isSnpFwded;
		uint8_t m_snpResp;
		bool m_snpDataFwded;
		bool m_gotSnpData;
		bool m_isSnpDataPtl;
		bool m_compAckReceived;
		bool m_writeToSNDone;
		bool m_compSNReceived;

		//
		// For storing the request towards SN in case a Retry sequence
		// is started
		//
		tlm::tlm_generic_payload m_reqSNCopy;
		chiattr_extension *m_chiattrSN;

		unsigned int m_dataReceived;

		std::vector<SnpTxnTracker> m_snpTrackers;
	};

	class RspMsg :
		public IMsg
	{
	public:
		using IMsg::m_gp;
		using IMsg::m_chiattr;

		//
		// This is when constructing the incomming responses in the
		// ports.
		//
		RspMsg(tlm::tlm_generic_payload *gp,
			chiattr_extension *chiattr) :
			IMsg(gp, chiattr)
		{}

		//
		// This is called when creating dataless responses and read receipts
		//
		RspMsg(ReqTxn *req, uint8_t opcode)
		{
			chiattr_extension *attr = req->GetCHIAttr();

			m_gp->set_command(tlm::TLM_IGNORE_COMMAND);

			m_chiattr->SetQoS(attr->GetQoS());
			m_chiattr->SetTgtID(attr->GetSrcID());
			m_chiattr->SetSrcID(NODE_ID);
			m_chiattr->SetTxnID(attr->GetTxnID());
			m_chiattr->SetOpcode(opcode);

			m_chiattr->SetResp(GetResp(req));
			m_chiattr->SetRespErr(req->GetRespErr());
			m_chiattr->SetTraceTag(attr->GetTraceTag());
		};

		//
		// This is called when routing responses.
		//
		RspMsg(RspMsg& rhs)
		{
			m_gp->deep_copy_from(rhs.GetGP());
			m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
		}

		RspMsg(tlm::tlm_generic_payload& gp)
		{
			m_gp->deep_copy_from(gp);
		};

		bool IsCompAck()
		{
			return m_chiattr->GetOpcode() == Rsp::CompAck;
		}

		bool IsCompDBIDResp()
		{
			return m_chiattr->GetOpcode() == Rsp::CompDBIDResp;
		}

		bool IsComp()
		{
			return m_chiattr->GetOpcode() == Rsp::Comp;
		}

		bool IsDBIDResp()
		{
			return m_chiattr->GetOpcode() == Rsp::DBIDResp;
		}

		bool IsSnpResp()
		{
			return m_chiattr->GetOpcode() == Rsp::SnpResp;
		}

		bool IsSnpRespFwded()
		{
			return m_chiattr->GetOpcode() == Rsp::SnpRespFwded;
		}

		bool IsRetryAck()
		{
			return m_chiattr->GetOpcode() == Rsp::RetryAck;
		}

		bool IsPCrdGrant()
		{
			return m_chiattr->GetOpcode() == Rsp::PCrdGrant;
		}

		bool IsReadReceipt()
		{
			return m_chiattr->GetOpcode() == Rsp::ReadReceipt;
		}

	private:
		enum { Comp_I = 0x0, Comp_UC = 0x2, Comp_SC = 0x1 };

		uint8_t GetResp(ReqTxn *req)
		{
			//
			// Taken from table 4-13, 4.7.2 [1]
			//
			switch(req->GetOpcode()) {
			case Req::CleanUnique:
			case Req::MakeUnique:
				return Comp_UC;
			case Req::Evict:
			default:
				return Comp_I;
			}
			return Comp_I;
		}
	};

	class DatMsg :
		public IMsg
	{
	public:
		using IMsg::m_gp;
		using IMsg::m_chiattr;
		using IMsg::m_data;
		using IMsg::m_byteEnable;

		//
		// This is called when routing packets.
		//
		DatMsg(DatMsg& rhs)
		{
			m_gp->deep_copy_from(rhs.GetGP());
			m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
		}

		//
		// This is when constructing the incomming dat in the ports.
		//
		DatMsg(tlm::tlm_generic_payload *gp,
			chiattr_extension *chiattr) :
			IMsg(gp, chiattr)
		{}

		//
		// This is called on snoop responses.
		//
		DatMsg(ReqTxn *req)
		{
			tlm::tlm_generic_payload& gp = req->GetGP();
			chiattr_extension *attr = req->GetCHIAttr();

			m_gp->set_command(tlm::TLM_WRITE_COMMAND);

			//
			// req always have data + byte enable
			//
			memcpy(m_data, gp.get_data_ptr(), CACHELINE_SZ);
			memcpy(m_byteEnable, gp.get_byte_enable_ptr(),
					gp.get_byte_enable_length());

			m_chiattr->SetQoS(attr->GetQoS());
			m_chiattr->SetTgtID(attr->GetSrcID());
			m_chiattr->SetSrcID(NODE_ID);
			m_chiattr->SetTxnID(attr->GetTxnID());
			m_chiattr->SetHomeNID(NODE_ID);
			m_chiattr->SetOpcode(Dat::CompData);

			//
			// ReadNoSnp, ReadOnce* return CompData_I (table 4-12,
			// 4.7.1 [1])
			//
			if (req->IsNonCoherentRead()) {
				m_chiattr->SetResp(Resp::CompData_I);
			} else {
				m_chiattr->SetResp(req->GetSnpRespResult());
			}

			m_chiattr->SetRespErr(req->GetRespErr());
			m_chiattr->SetTraceTag(attr->GetTraceTag());
		}

		//
		// This is called for slave node DatMsgs.
		//
		DatMsg(ReqTxn *req, uint8_t opcode, uint8_t txnID)
		{
			tlm::tlm_generic_payload& gp = req->GetGP();
			chiattr_extension *attr = req->GetCHIAttr();

			m_gp->set_command(tlm::TLM_WRITE_COMMAND);
			m_gp->set_address(gp.get_address());

			m_gp->set_data_length(CACHELINE_SZ);

			//
			// req always have data + byte enable
			//
			memcpy(m_data, gp.get_data_ptr(), CACHELINE_SZ);
			if (req->IsAtomic()) {
				memcpy(m_byteEnable, gp.get_byte_enable_ptr(),
						req->GetDataReceived());
			} else {
				memcpy(m_byteEnable, gp.get_byte_enable_ptr(),
						gp.get_byte_enable_length());
			}

			m_chiattr->SetQoS(attr->GetQoS());
			m_chiattr->SetTgtID(SLAVE_NODE_ID);
			m_chiattr->SetSrcID(NODE_ID);
			m_chiattr->SetTxnID(txnID);

			m_chiattr->SetOpcode(opcode);

			m_chiattr->SetTraceTag(attr->GetTraceTag());
		}

		void SetupNonDMT(ReqTxn *req)
		{
			//
			// Setup HomeNID / DBID if ExpCompAck is set
			//
			if (req->GetExpCompAck()) {
				m_chiattr->SetHomeNID(NODE_ID);
				m_chiattr->SetDBID(m_chiattr->GetTxnID());
			}

			m_chiattr->SetTgtID(req->GetSrcID());
			m_chiattr->SetSrcID(NODE_ID);
			m_chiattr->SetTxnID(req->GetTxnID());
			m_chiattr->SetRespErr(req->GetRespErr());

			if (!req->IsAtomic()) {
				m_chiattr->SetResp(req->GetSnpRespResult());
			} else {
				m_chiattr->SetResp(Resp::CompData_I);
			}
		}

		bool IsCompData()
		{
			return m_chiattr->GetOpcode() == Dat::CompData;
		}

		bool IsCopyBackWrData()
		{
			return m_chiattr->GetOpcode() == Dat::CopyBackWrData;
		}

		bool IsNonCopyBackWrData()
		{
			return m_chiattr->GetOpcode() == Dat::NonCopyBackWrData;
		}

		bool IsNonCopyBackWrDataCompAck()
		{
			return m_chiattr->GetOpcode() == Dat::NCBWrDataCompAck;
		}

		bool IsSnpRespData()
		{
			return m_chiattr->GetOpcode() == Dat::SnpRespData;
		}

		bool IsSnpRespDataFwded()
		{
			return m_chiattr->GetOpcode() == Dat::SnpRespDataFwded;
		}

		bool IsSnpRespDataPtl()
		{
			return m_chiattr->GetOpcode() == Dat::SnpRespDataPtl;
		}

		enum { PassDirtyShift = 2 };

		bool GetPassDirty()
		{
			return (m_chiattr->GetResp() >> PassDirtyShift) & 0x1;
		}
	};

	class SnpMsg :
		public IMsg
	{
	public:
		using IMsg::m_gp;
		using IMsg::m_chiattr;
		using IMsg::m_data;
		using IMsg::m_byteEnable;

		//
		// SnpMsg Construction
		//
		SnpMsg(ReqTxn *req, uint8_t txnID, bool allowsSnpFwd)
		{
			tlm::tlm_generic_payload& gp = req->GetGP();
			chiattr_extension *attr = req->GetCHIAttr();
			uint64_t addr;

			m_gp->set_command(tlm::TLM_IGNORE_COMMAND);

			if (req->IsDVMOp()) {
				bool isSecondPacket = allowsSnpFwd;

				addr = GenerateSnpDVMPacket(req,
							isSecondPacket);
			} else {
				addr = gp.get_address();
			}

			m_gp->set_address(addr);
			m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

			// Copy and override
			m_chiattr->SetQoS(attr->GetQoS());
			m_chiattr->SetSrcID(NODE_ID);
			m_chiattr->SetTxnID(txnID);
			m_chiattr->SetOpcode(GetOpcode(req, allowsSnpFwd));

			if (!req->IsDVMOp()) {

				if (IsSnpFwded()) {
					m_chiattr->SetFwdNID(attr->GetSrcID());
					m_chiattr->SetFwdTxnID(attr->GetTxnID());
				} else {
					m_chiattr->SetFwdNID(0);
					m_chiattr->SetFwdTxnID(0);
				}

				m_chiattr->SetNonSecure(attr->GetNonSecure());
				m_chiattr->SetDoNotGoToSD(GetDoNotGoToSD());

				//
				// Return cache line if it is in SC state
				//
				m_chiattr->SetRetToSrc(true);

				m_chiattr->SetTraceTag(attr->GetTraceTag());
			} else {
				m_chiattr->SetNonSecure(false);
			}
		}

		SnpMsg(tlm::tlm_generic_payload& gp)
		{
			m_gp->deep_copy_from(gp);
			m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
		}

		//
		// SnpMsg construction when routing the messages
		//
		SnpMsg(SnpMsg& rhs)
		{
			m_gp->deep_copy_from(rhs.GetGP());
			m_gp->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
		}

		uint64_t GenerateSnpDVMPacket(ReqTxn *req,
						bool isSecondPacket)
		{
			tlm::tlm_generic_payload& gp = req->GetGP();
			uint64_t addr;
			uint8_t op = GetDVMOp(gp.get_address());
			bool VAValid = GetVAValid(gp.get_address());
			uint8_t *data = gp.get_data_ptr();

			//
			// See Table 8-3, 8.2.2 [1]
			//
			if (isSecondPacket) {
				//
				// Second packet
				//
				if (op != DVM::PICI && VAValid) {
					//
					// VA, bit 47 49 must be 0 if unused,
					// 8.1.4 [1]
					//
					int i;

					// bits [7:4]
					addr = data[0] & 0xF0;

					// bits [39:8] (4 bytes)
					for (i = 1; i < 5; i++) {
						addr |= (data[i] << (i *8));
					}

					// bits [43:40]
					addr |= ((uint64_t) data[5] & 0xF) << (i *8);

					// data bit [47] -> addr bit [44]
					addr |= (((uint64_t) data[5] >> 7 ) & 0x1) << 44;

					// data bit [49] -> addr bit [45]
					addr |= (((uint64_t) data[6] >> 7 ) & 0x1) << 45;

				} else {
					// PA
					int i;

					addr = 0;
					for (i = 0; i < 8; i++) {
						addr |= (data[i] << (i * 8));
					}
				}

				addr |= (1 << DVM::PacketNumShift);
			} else {
				//
				// First packet
				//
				uint64_t addressMask;

				//
				// ((1 << DVM::AddressBits) - 1)
				//
				addressMask = 1;
				addressMask <<= DVM::AddressBits;
				addressMask -= 1;
				addressMask <<= 4;

				addr = gp.get_address() & addressMask;

				if (op != DVM::PICI && VAValid) {
					//
					// VA, unused bits must be 0,
					// 8.1.4 [1]
					//

					// bits [46:44]
					addr |= (((uint64_t) data[5] >> 4) & 0x7) << 41;

					// data bit [48] -> addr bit [44]
					addr |= ((uint64_t) data[6] & 0x1) << 44;

					// data bit [50] -> addr bit [45]
					addr |= (((uint64_t) data[6] >> 2 ) & 0x1) << 45;
				}

				// Set VMIDExt, if unused it will be 0
				m_chiattr->SetVMIDExt(data[7]);
			}

			return addr;
		}

		uint8_t GetDVMOp(uint64_t addr)
		{
			return (addr >> DVM::DVMOpShift) & DVM::DVMOpMask;
		}

		bool GetVAValid(uint64_t addr)
		{
			return (addr >> DVM::DVMVAValidShift) & DVM::DVMVAValidMask;
		}

		bool IsSnpFwded()
		{
			switch(m_chiattr->GetOpcode()) {
			case Snp::SnpOnceFwd:
			case Snp::SnpCleanFwd:
			case Snp::SnpNotSharedDirtyFwd:
			case Snp::SnpSharedFwd:
			case Snp::SnpUniqueFwd:
				return true;
			default:
				break;
			}
			return false;
		}

	private:
		uint8_t GetOpcode(ReqTxn *req, bool allowSnpFwd)
		{
			uint8_t opcode;

			if (req->IsAtomic()) {
				return Snp::SnpUnique;
			} else if (req->GetOpcode() == Req::DVMOp) {
				return Snp::SnpDVMOp;
			}

			switch (req->GetOpcode()) {
			case Req::ReadOnce:
				opcode = Snp::SnpOnce;
				break;
			case Req::ReadOnceCleanInvalid:
				opcode = Snp::SnpUnique;
				break;
			case Req::ReadOnceMakeInvalid:
				opcode = Snp::SnpUnique;
				break;
			case Req::ReadClean:
				opcode = Snp::SnpClean;
				break;
			case Req::ReadNotSharedDirty:
				opcode = Snp::SnpNotSharedDirty;
				break;
			case Req::ReadShared:
				opcode = Snp::SnpShared;
				break;
			case Req::ReadUnique:
				opcode = Snp::SnpUnique;
				break;

			// Dataless
			case Req::CleanUnique:
				opcode = Snp::SnpCleanInvalid;
				break;
			case Req::MakeUnique:
				opcode = Snp::SnpMakeInvalid;
				break;
			case Req::CleanShared:
			case Req::CleanSharedPersist:
				opcode = Snp::SnpCleanShared;
				break;
			case Req::CleanInvalid:
				opcode = Snp::SnpCleanInvalid;
				break;
			case Req::MakeInvalid:
				opcode = Snp::SnpMakeInvalid;
				break;

			// Dataless-stash
			case Req::StashOnceUnique:
				opcode = Snp::SnpStashUnique;
				break;
			case Req::StashOnceShared:
				opcode = Snp::SnpStashShared;
				break;

			// Write
			case Req::WriteUniqueFull:
				opcode = Snp::SnpMakeInvalid;
				break;
			case Req::WriteUniquePtl:
				opcode = Snp::SnpCleanInvalid;
				break;

			// Write-stash
			case Req::WriteUniqueFullStash:
				opcode = Snp::SnpMakeInvalidStash;
				break;
			case Req::WriteUniquePtlStash:
				opcode = Snp::SnpUniqueStash;
				break;

			// DVMOp
			case Req::DVMOp:
				opcode = Snp::SnpDVMOp;
				break;

			default:
				opcode = 0xFF;
				break;
			}

			if (allowSnpFwd) {
				//
				// Switch to Snp*Fwd
				//
				switch (opcode) {
				case Snp::SnpOnce:
					opcode = Snp::SnpOnceFwd;
					break;
				case Snp::SnpClean:
					opcode = Snp::SnpCleanFwd;
					break;
				case Snp::SnpNotSharedDirty:
					opcode = Snp::SnpNotSharedDirtyFwd;
					break;
				case Snp::SnpShared:
					opcode = Snp::SnpSharedFwd;
					break;
				case Snp::SnpUnique:
					opcode = Snp::SnpUniqueFwd;
					break;
				default:
					break;
				}
			}

			return opcode;
		}

		bool GetDoNotGoToSD()
		{
			//
			// Must be set on below snoop requests, other snoop
			// requests are allowed or must keep it unset
			//
			switch(m_chiattr->GetOpcode()) {
			case Snp::SnpUniqueFwd:
			case Snp::SnpUnique:
			case Snp::SnpCleanShared:
			case Snp::SnpCleanInvalid:
			case Snp::SnpMakeInvalid:
				return true;
			default:
				break;
			}
			return false;
		}
	};

	class IPacketRouter
	{
	public:
		IPacketRouter() {}
		virtual ~IPacketRouter() {}

		virtual void RouteReq(ReqTxn *req) = 0;

		virtual void RouteRsp(RspMsg& rsp) = 0;

		virtual void RouteDat(DatMsg& dat) = 0;

		virtual void RouteDat_SN(DatMsg& dat) = 0;

		virtual void RouteRsp_SN(RspMsg& rsp) = 0;

		virtual void RouteSnpReq(SnpMsg& msg) = 0;

		virtual void TransmitToRequestNode(RspMsg *m) = 0;

	};

	template<typename T>
	class TxChannel :
		public sc_core::sc_module
	{
	public:

		SC_HAS_PROCESS(TxChannel);

		TxChannel(sc_core::sc_module_name name,
			tlm_utils::simple_initiator_socket<T>& init_socket) :
			sc_core::sc_module(name),
			m_init_socket(init_socket)
		{
			SC_THREAD(tx_thread);
		}

		void Process(IMsg *t)
		{
			m_txList.push_back(t);
			m_listEvent.notify();
		}
	private:

		void tx_thread()
		{
			while (true) {
				sc_time delay(SC_ZERO_TIME);
				IMsg *t;

				if (m_txList.empty()) {
					wait(m_listEvent);
				}

				t = m_txList.front();
				m_txList.remove(t);

				assert(t->GetGP().get_response_status() ==
						tlm::TLM_INCOMPLETE_RESPONSE);

				m_init_socket->b_transport(t->GetGP(), delay);

				assert(t->GetGP().get_response_status() ==
						tlm::TLM_OK_RESPONSE);
				delete t;
			}
		}

		tlm_utils::simple_initiator_socket<T>& m_init_socket;
		std::list<IMsg*> m_txList;
		sc_event m_listEvent;
	};

	class Address
	{
	public:
		Address(ReqTxn *req) :
			m_addr(Align(req->GetAddress())),
			m_non_secure(req->GetNonSecure())
		{}

		Address(uint64_t address, bool non_secure) :
			m_addr(address),
			m_non_secure(non_secure)
		{}

		friend bool operator==(const Address& lhs, const Address& rhs)
		{
			return lhs.m_addr == rhs.m_addr &&
				lhs.m_non_secure == rhs.m_non_secure;
		}

	private:
		uint64_t Align(uint64_t addr)
		{
			return addr & ~(CACHELINE_SZ-1);
		}

		uint64_t m_addr;
		bool m_non_secure;
	};

	class SnoopFilter
	{
	public:
		//
		// Taken from tables: 4-7, 4-8, 4-9 and 4-10 at 4.5.3 [1]
		//
		enum {
			INV = 0x0, // 0b000
			I_PD = 0x4 // 0b100
			};

		SnoopFilter()
		{}

		//
		// Called from the PoC after snooping
		//
		template<typename TxnType>
		void Update(TxnType& t, ReqTxn *req)
		{
			switch (t.GetCHIAttr()->GetResp()) {
			case INV:
			case I_PD:
			{
				//
				// Cache line is invalid at RN-F, evict if
				// needed
				//
				Address addr(req);

				EvictCacheLine(addr);
				break;
			}
			default:
				// No change if the line is not Invalid on a
				// snoop resp
				break;
			}
		}

		//
		// Called from the TxnProcessor
		//
		void Update(ReqTxn *req)
		{
			Address addr(req);

			//
			// DataPull Read missing at the moment
			//

			switch (req->GetOpcode()) {
			//
			// ReadClean, ReadNotSharedDirty, ReadShared,
			// ReadUnique allocates a cache line, table 4-12, 4.7.1
			// [1]
			//
			// CleanUnique and MakeUnique allocates a cache line,
			// table 4-13, 4.7.2 [1]
			//
			case Req::ReadClean:
			case Req::ReadNotSharedDirty:
			case Req::ReadShared:
			case Req::ReadUnique:
			case Req::CleanUnique:
			case Req::MakeUnique:
				AllocateCacheLine(addr);
				break;
			//
			// CleanShared and CleanSharedPersist leaves
			// the cache line allocation unchanged, table
			// 4-13, 4.7.2 [1]
			//
			// WriteCleanFull leaves the line allocation unchanged
			// 4.7.3, table 4-14 [1]
			//
			case Req::CleanShared:
			case Req::CleanSharedPersist:
			case Req::WriteCleanFull:
				// No change
				break;
			default:
				//
				// All other transactions expect the line to be
				// invalid afterwards, 4.7 [1]
				//
				EvictCacheLine(addr);
				break;
			}
		}

		bool ContainsAllocated(Address& addr)
		{
			return InList(addr);
		}

	private:

		void AllocateCacheLine(Address& addr)
		{
			if (!InList(addr)) {
				m_allocated.push_back(addr);
			}
		}

		void EvictCacheLine(Address& addr)
		{
			if (InList(addr)) {
				m_allocated.remove(addr);
			}
		}

		bool InList(Address& addr)
		{
			typename std::list<Address>::iterator it;
			for (it = m_allocated.begin();
				it != m_allocated.end(); it++) {

				if ((*it) == addr) {
					return true;
				}
			}
			return false;
		}

		std::list<Address> m_allocated;
	};

	class RequestOrderer :
		public sc_core::sc_module
	{
	public:
		SC_HAS_PROCESS(RequestOrderer);

		RequestOrderer(sc_core::sc_module_name name,
				IPacketRouter *router) :
			sc_core::sc_module(name),
			m_router(router)
		{
			SC_THREAD(req_ordering_thread);
		}

		void ProcessReq(ReqTxn *req)
		{
			assert(req);
			m_reqList.push_back(req);
			m_pushEvent.notify();
		}

		bool RunVerify(ReqTxn *req)
		{
			switch (req->GetCHIAttr()->GetOpcode()) {
			case Req::WriteCleanFull:
			case Req::WriteUniquePtl:
			case Req::WriteUniqueFull:
			case Req::WriteUniqueFullStash:
			case Req::WriteUniquePtlStash:
				return false;
			default:
				return true;
			}
		}

		void ReqDone(ReqTxn *req)
		{
			m_ongoing.remove(req);

			delete req;

			m_removeEvent.notify();
		}

	private:

		void req_ordering_thread()
		{
			while (true) {
				ReqTxn *req;

				if (m_reqList.empty()) {
					wait(m_pushEvent);
				}

				req = m_reqList.front();
				assert(req);
				if (OverlappingRequestOngoing(req)) {
					//
					// block processing (by blocking write
					// observer order is preserved)
					//
					wait(m_removeEvent);

					//
					// check againg if there is an overlapping
					//
					continue;
				}

				m_reqList.remove(req);
				m_ongoing.push_back(req);

				// Forward to router now
				m_router->RouteReq(req);

				// One at a time
				if (Ongoing(req)) {
					wait(m_removeEvent);
				}
			}
		}

		bool OverlappingRequestOngoing(ReqTxn *req)
		{
			typename std::list<ReqTxn*>::iterator it;

			for (it = m_ongoing.begin();
				it != m_ongoing.end(); it++) {
				ReqTxn *tmp = (*it);
				Address addr1(tmp);
				Address addr2(req);

				//
				// Endpoint address range is 64b, same as cache
				// line here 2.8 [1]
				//
				if (addr1 == addr2) {
					return true;
				}
			}
			return false;
		}

		bool Ongoing(ReqTxn *req)
		{
			typename std::list<ReqTxn*>::iterator it;
			for (it = m_ongoing.begin();
				it != m_ongoing.end(); it++) {

				if ((*it) == req) {
					return true;
				}
			}
			return false;
		}

		IPacketRouter *m_router;
		std::list<ReqTxn*> m_reqList;
		std::list<ReqTxn*> m_ongoing;
		sc_event m_pushEvent;
		sc_event m_removeEvent;

	};

	//
	// Also handles RN_D interface
	//
	class Port_RN_F :
		public sc_core::sc_module
	{
	public:
		tlm_utils::simple_target_socket<Port_RN_F> rxreq_tgt_socket;
		tlm_utils::simple_target_socket<Port_RN_F> rxrsp_tgt_socket;
		tlm_utils::simple_target_socket<Port_RN_F> rxdat_tgt_socket;

		tlm_utils::simple_initiator_socket<Port_RN_F> txrsp_init_socket;
		tlm_utils::simple_initiator_socket<Port_RN_F> txdat_init_socket;
		tlm_utils::simple_initiator_socket<Port_RN_F> txsnp_init_socket;

		SC_HAS_PROCESS(Port_RN_F);

		Port_RN_F(sc_module_name name,
				IPacketRouter *router,
				RequestOrderer *reqOrderer,
				uint16_t nodeID) :
			sc_core::sc_module(name),

			rxreq_tgt_socket("rxreq_tgt_socket"),
			rxrsp_tgt_socket("rxrsp_tgt_socket"),
			rxdat_tgt_socket("rxdat_tgt_socket"),

			txrsp_init_socket("txrsp_init_socket"),
			txdat_init_socket("txdat_init_socket"),
			txsnp_init_socket("txsnp_init_socket"),

			m_router(router),
			m_reqOrderer(reqOrderer),
			m_txRspChannel("TxRspChannel", txrsp_init_socket),
			m_txDatChannel("TxDatChannel", txdat_init_socket),
			m_txSnpChannel("TxSnpChannel", txsnp_init_socket),
			m_onlySnpDVM(false),
			m_nodeID(nodeID),
			m_toggle(false)
		{
			rxreq_tgt_socket.register_b_transport(
					this, &Port_RN_F::b_transport_rxreq);
			rxrsp_tgt_socket.register_b_transport(
					this, &Port_RN_F::b_transport_rxrsp);
			rxdat_tgt_socket.register_b_transport(
					this, &Port_RN_F::b_transport_rxdat);
		}

		//
		// RN_D interfaces only handles DVM snoop transactions
		//
		bool GetOnlySnpDVM() { return m_onlySnpDVM; }
		void SetOnlySnpDVM(bool onlySnpDVM)
		{
			m_onlySnpDVM = onlySnpDVM;
		}

		void Transmit(RspMsg *rsp) { m_txRspChannel.Process(rsp); }
		void Transmit(DatMsg *dat) { m_txDatChannel.Process(dat); }
		void Transmit(SnpMsg *snp) { m_txSnpChannel.Process(snp); }

		uint16_t GetNodeID() { return m_nodeID; }
		void SetNodeID(uint16_t nodeID) { m_nodeID = nodeID; }

		template<typename T>
		void connect(T& dev)
		{
			dev.rxreq_init_socket(rxreq_tgt_socket);
			dev.rxrsp_init_socket(rxrsp_tgt_socket);
			dev.rxdat_init_socket(rxdat_tgt_socket);

			txrsp_init_socket.bind(dev.txrsp_tgt_socket);
			txdat_init_socket.bind(dev.txdat_tgt_socket);
			txsnp_init_socket.bind(dev.txsnp_tgt_socket);
		}

		SnoopFilter& GetSnoopFilter() { return m_snoopFilter; }
	private:
		virtual void b_transport_rxreq(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);

			if (trans.get_command() == tlm::TLM_IGNORE_COMMAND) {
				chiattr_extension *chiattr;
				trans.get_extension(chiattr);
				if (chiattr) {
					ReqTxn *req = new ReqTxn(trans);

					if (req->GetAllowRetry() && GetToggle()) {

						ReplyRetry(req);

						//
						// Don't store it, instead
						// always accept retry reqs
						//
						delete req;
					} else {
						m_reqOrderer->ProcessReq(req);
					}

					trans.set_response_status(tlm::TLM_OK_RESPONSE);
				}
			}
		}

		virtual void b_transport_rxrsp(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);

			if (trans.get_command() == tlm::TLM_IGNORE_COMMAND) {
				chiattr_extension *chiattr;
				trans.get_extension(chiattr);
				if (chiattr) {
					RspMsg rsp(&trans, chiattr);

					m_router->RouteRsp(rsp);

					trans.set_response_status(tlm::TLM_OK_RESPONSE);
				}
			}
		}

		virtual void b_transport_rxdat(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);

			if (trans.is_write()) {
				chiattr_extension *chiattr;
				trans.get_extension(chiattr);
				if (chiattr) {
					DatMsg dat(&trans, chiattr);

					m_router->RouteDat(dat);

					trans.set_response_status(tlm::TLM_OK_RESPONSE);
				}
			}
		}

		void ReplyRetry(ReqTxn *req)
		{
			RspMsg *rspRetryAck = new RspMsg(req, Rsp::RetryAck);
			RspMsg *rspPCrdGrant = new RspMsg(req, Rsp::PCrdGrant);

			// PCrdType == 0
			m_txRspChannel.Process(rspRetryAck);
			m_txRspChannel.Process(rspPCrdGrant);
		}

		bool GetToggle()
		{
			m_toggle = (m_toggle) ? false : true;

			return m_toggle;
		}

		IPacketRouter *m_router;
		RequestOrderer *m_reqOrderer;

		TxChannel<Port_RN_F> m_txRspChannel;
		TxChannel<Port_RN_F> m_txDatChannel;
		TxChannel<Port_RN_F> m_txSnpChannel;

		bool m_onlySnpDVM;
		uint16_t m_nodeID;
		bool m_toggle;

		SnoopFilter m_snoopFilter;
	};

	class Port_SN :
		public sc_core::sc_module
	{
	public:
		tlm_utils::simple_initiator_socket<Port_SN> txreq_init_socket;
		tlm_utils::simple_initiator_socket<Port_SN> txdat_init_socket;

		tlm_utils::simple_target_socket<Port_SN> rxrsp_tgt_socket;
		tlm_utils::simple_target_socket<Port_SN> rxdat_tgt_socket;

		SC_HAS_PROCESS(Port_SN);

		Port_SN(sc_module_name name,
				IPacketRouter *router,
				uint16_t nodeID) :
			sc_core::sc_module(name),

			txreq_init_socket("txreq_init_socket"),
			txdat_init_socket("txdat_init_socket"),

			rxrsp_tgt_socket("rxrsp_tgt_socket"),
			rxdat_tgt_socket("rxdat_tgt_socket"),

			m_router(router),
			m_txReqChannel("TxReqChannel", txreq_init_socket),
			m_txDatChannel("TxDatChannel", txdat_init_socket),
			m_nodeID(nodeID)
		{
			rxrsp_tgt_socket.register_b_transport(
					this, &Port_SN::b_transport_rxrsp);
			rxdat_tgt_socket.register_b_transport(
					this, &Port_SN::b_transport_rxdat);
		}

		void Transmit(ReqTxn *req) { m_txReqChannel.Process(req); }
		void Transmit(DatMsg *dat) { m_txDatChannel.Process(dat); }

		uint16_t GetNodeID() { return m_nodeID; }
		void SetNodeID(uint16_t nodeID) { m_nodeID = nodeID; }

		template<typename T>
		void connect(T& dev)
		{
			txreq_init_socket(dev.txreq_tgt_socket);
			txdat_init_socket(dev.txdat_tgt_socket);

			dev.rxrsp_init_socket.bind(rxrsp_tgt_socket);
			dev.rxdat_init_socket.bind(rxdat_tgt_socket);

		}

	private:
		virtual void b_transport_rxrsp(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);

			if (trans.get_command() == tlm::TLM_IGNORE_COMMAND) {
				chiattr_extension *chiattr;
				trans.get_extension(chiattr);
				if (chiattr) {
					RspMsg rsp(&trans, chiattr);

					m_router->RouteRsp_SN(rsp);

					trans.set_response_status(tlm::TLM_OK_RESPONSE);
				}
			}
		}

		virtual void b_transport_rxdat(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);

			if (trans.is_write()) {
				chiattr_extension *chiattr;
				trans.get_extension(chiattr);
				if (chiattr) {
					DatMsg dat(&trans, chiattr);

					m_router->RouteDat_SN(dat);

					trans.set_response_status(tlm::TLM_OK_RESPONSE);
				}
			}
		}

		IPacketRouter *m_router;

		TxChannel<Port_SN> m_txReqChannel;
		TxChannel<Port_SN> m_txDatChannel;

		uint16_t m_nodeID;
	};

	typedef iconnect_chi<NODE_ID, SLAVE_NODE_ID,
				NUM_CHI_RN_F, NUM_CCIX_PORTS> iconnect_chi_t;

	friend class CCIX::CCIXPort<iconnect_chi_t>;

	typedef CCIX::CCIXPort<iconnect_chi_t> Port_CCIX;

	class IDVMOpProcessor
	{
	public:
		virtual ~IDVMOpProcessor() {}

		virtual void ProcessDVM(ReqTxn *req) = 0;
	};

	class TxnProcessor
	{
	public:
		TxnProcessor(Port_RN_F **port_RN_F,
				Port_CCIX **port_CCIX,
				Port_SN **port_SN,
				TxnIDs *ids,
				ReqTxn **ongoingTxn,
				RequestOrderer *reqOrderer,
				IDVMOpProcessor *poc,
				IPacketRouter *router) :
			m_port_RN_F(port_RN_F),
			m_port_CCIX(port_CCIX),
			m_port_SN(port_SN),
			m_ids(ids),
			m_ongoingTxn(ongoingTxn),
			m_reqOrderer(reqOrderer),
			m_poc(poc),
			m_router(router)
		{}

		void ProcessSnpdReq(ReqTxn *req)
		{
			if (req->GotSnpData() && req->GetSnpRespPassDirty() &&
				!req->AllowsPassDirtySnpData()) {
				//
				// Transmit dirty data to SN
				//
				ReqTxn *wrReq = new ReqTxn(req, Req::WriteNoSnpPtl,
								m_ids->GetID());

				req->SnpRespPassDirtyClear();

				m_ongoingTxn[wrReq->GetTxnID()] = req;

				m_port_SN[0]->Transmit(wrReq);

			} else if (req->GotSnpData() && req->IsSnpRead() &&
					!req->IsSnpDataPtl()) {

				DatMsg dat(req);

				if (req->GetExpCompAck()) {
					dat.GetCHIAttr()->SetHomeNID(NODE_ID);
					dat.SetDBID(m_ids->GetID());

					m_ongoingTxn[dat.GetDBID()] = req;

					req->SetWaitingForCompAck(true);
				} else {
					//
					// ReadOnce* without CompAck are done here
					//
					RequestDone(req);
				}

				m_router->RouteDat(dat);

			} else if (req->IsDVMOp()) {
				RspMsg *rsp = new RspMsg(req, Rsp::Comp);

				TransmitToRequestNode(rsp);

				RequestDone(req);
			} else {
				//
				// Make sure GotSnpData is cleared, since this
				// 'else' is entered when there is no data or
				// when we have handled the data (written out
				// dirty data). The clear actually only happens
				// when dirty data has been written out.
				//
				req->SetGotSnpData(false);
				req->SetWriteToSNDone(false);
				req->SetCompSNReceived(false);

				ProcessReq(req);
			}
		}

		void ProcessReq(ReqTxn *req)
		{
			if (req->IsRead()) {
				//
				// This is entered when snooping did not give
				// data result or when no snooping is done
				// (ReadNoSnp)
				//
				// Construct an SN req taking into
				// consideration if DMT is allowed
				ReqTxn *rdReq = new ReqTxn(req,
							Req::ReadNoSnp,
							m_ids->GetID());

				//
				// To note CopyBack has always ExpCompAck and
				// always allows DMT.
				//
				// Table 2-6, table 2-7 2.3.1 [1]
				//
				if (req->AllowsDMT()) {
					if (!req->GetExpCompAck() && !req->GetOrder()) {
						//
						// Wait for ReadReceipt
						//
						req->SetWaitingForReadReceipt(true);
					} else {
						//
						// Wait for CompAck
						//
						req->SetWaitingForCompAck(true);
					}
				}

				// To SN
				m_ongoingTxn[rdReq->GetTxnID()] = req;
				m_port_SN[0]->Transmit(rdReq);

			} else if (req->IsWrite() || req->IsAtomicStore()) {
				RspMsg rsp(req, Rsp::CompDBIDResp);

				// HomeNID not used, see 2.6.3 [1]
				rsp.SetDBID(m_ids->GetID());
				m_ongoingTxn[rsp.GetDBID()] = req;

				if (req->IsWriteUnique() && req->GetExpCompAck()) {
					req->SetWaitingForCompAck(true);
				}

				m_router->RouteRsp(rsp);

			} else if (req->IsDataLess()) {
				RspMsg rsp(req, Rsp::Comp);

				if (req->GetExpCompAck()) {
					rsp.GetCHIAttr()->SetHomeNID(NODE_ID);
					rsp.SetDBID(m_ids->GetID());

					m_ongoingTxn[rsp.GetDBID()] = req;

					req->SetWaitingForCompAck(true);
				} else {
					//
					// Update the snoop filter on RN-F
					// ports for reqs without CompAck. Reqs
					// with CompAck will update the snoop
					// filter when the  CompAck is
					// received. See table 2-8, 2.8.3 [1]
					// for which requests that are allowed
					// to have CompAck.
					//
					UpdatePortRNFSnoopFilter(req);

					RequestDone(req);
				}

				m_router->RouteRsp(rsp);

			} else if (req->IsAtomic() || req->IsDVMOp()) {
				//
				// AtomicStore i handled as an IsWrite, so only
				// the non store atomics are handled here
				//
				RspMsg rsp(req, Rsp::DBIDResp);

				// HomeNID not used, see 2.6.3 [1]
				rsp.SetDBID(m_ids->GetID());
				m_ongoingTxn[rsp.GetDBID()] = req;

				m_router->RouteRsp(rsp);
			} else {
				RequestDone(req);
			}
		}

		void ProcessDat(DatMsg& dat)
		{
			ReqTxn *req = m_ongoingTxn[dat.GetTxnID()];

			if (!req) {
				// what to do here?
				assert(req);
			}

			if (dat.IsCopyBackWrData()) {

				assert(req->IsWrite());

				req->CopyWriteData(&dat);

				if (req->AllWriteDataRecieved()) {

					//
					// Update RN-F ports snoop filter
					//
					UpdatePortRNFSnoopFilter(req);

					//
					// Forward to SN only if PassDirty is
					// set.
					//
					// Resp is the same on all flits in a
					// multi data flit transfer, 12.9.36
					// [1]
					//
					if (dat.GetPassDirty()) {
						// To SN
						ReqTxn *wrReq = new ReqTxn(req,
								Req::WriteNoSnpPtl,
								dat.GetTxnID());

						m_port_SN[0]->Transmit(wrReq);

					} else {
						// WriteEvictFull ends here
						// aswell as other CopyBack
						// that returned without
						// passing dirty data
						uint8_t txnID = dat.GetTxnID();

						m_ids->ReturnID(txnID);
						m_ongoingTxn[txnID] = NULL;
						RequestDone(req);
					}
				}
			} else if (dat.IsNonCopyBackWrData() ||
					dat.IsNonCopyBackWrDataCompAck()) {

				assert(req->IsWrite() ||
					req->IsAtomic() || req->IsDVMOp());

				req->CopyWriteData(&dat, req->IsAtomic());

				if (req->AllWriteDataRecieved()) {
					if (!req->IsDVMOp()) {
						ReqTxn *wrReq;
						uint8_t opcode;

						if (req->IsAtomic()) {
							opcode = req->GetOpcode();
						} else {
							opcode = Req::WriteNoSnpPtl;
						}

						if (req->IsWriteUnique() &&
							dat.IsNonCopyBackWrDataCompAck()) {

							// No harm is done if we always
							// set this even if ExpCompAck
							// is deasserted

							req->SetCompAckReceived(true);
						}

						// To SN
						wrReq = new ReqTxn(req,
								opcode,
								dat.GetTxnID());

						m_port_SN[0]->Transmit(wrReq);
					} else {
						uint8_t txnID = dat.GetTxnID();

						//
						// Return the ID since new ones
						// will be taken
						//
						m_ids->ReturnID(txnID);
						m_ongoingTxn[txnID] = NULL;

						m_poc->ProcessDVM(req);
					}
				}
			}
		}

		void ProcessResp(RspMsg& rsp)
		{
			if (rsp.IsCompAck()) {
				uint16_t txnID = rsp.GetTxnID();
				ReqTxn *req = m_ongoingTxn[txnID];

				assert(req);
				assert(req->GetWaitingForCompAck());

				if (req->IsWriteUnique()) {

					//
					// If the has been written to the SN
					// the req is completed, else only keep
					// track that CompAck has been received.
					//
					if (req->GetWriteToSNDone()) {
						m_ids->ReturnID(txnID);
						m_ongoingTxn[txnID] = NULL;

						RequestDone(req);
					} else {
						req->SetCompAckReceived(true);
					}
				} else {
					//
					// Update the snoop filter on RN-F ports. See
					// table 2-8, 2.8.3 [1] for which requests that
					// are allowed to have CompAck.
					//
					UpdatePortRNFSnoopFilter(req);

					if (req->AllSnpTxnDone()) {
						//
						// Req done
						//
						m_ids->ReturnID(txnID);
						m_ongoingTxn[txnID] = NULL;

						RequestDone(req);

					} else {
						//
						// Waiting for snoop Fwded response
						//
						req->SetCompAckReceived(true);
					}
				}
			}
		}

		//
		// Non DMT see req->AllowDMT(), or non store Atomics
		//
		void ProcessDat_SN(DatMsg& datSN)
		{
			DatMsg dat(datSN);
			ReqTxn *req = m_ongoingTxn[datSN.GetTxnID()];

			dat.SetupNonDMT(req);

			//
			// ReadNoSnp / ReadOnce without CompAck and atomics are
			// done now.
			//
			if (!req->GetExpCompAck()) {

				m_ids->ReturnID(datSN.GetTxnID());
				m_ongoingTxn[datSN.GetTxnID()] = NULL;

				RequestDone(req);
			} else {
				assert(!req->GetCompAckReceived());

				req->SetWaitingForCompAck(true);
			}

			m_router->RouteDat(dat);
		}

		void ProcessResp_SN(RspMsg& rsp)
		{
			if (rsp.IsRetryAck() || rsp.IsPCrdGrant()) {
				//
				// Retry sequence, since one req is issued at a
				// time marking that both RetryAck & PCrdGrant
				// have been received is enough.
				//
				uint8_t txnID = rsp.GetTxnID();
				ReqTxn *req = m_ongoingTxn[txnID];
				chiattr_extension *attr = rsp.GetCHIAttr();

				if (rsp.IsRetryAck()) {
					req->HandleRetryAck(attr);
				} else if (rsp.IsPCrdGrant()) {
					req->HandlePCrdGrant(attr);
				}

				// Got both RetryAck and PCrdGrant
				if (req->RetryRequest()) {
					ReqTxn *reqSN = new ReqTxn(req->GetReqSNCopy());

					m_port_SN[0]->Transmit(reqSN);
				}

			} else if (rsp.IsCompDBIDResp() || rsp.IsDBIDResp()) {
				uint8_t txnID = rsp.GetTxnID();
				ReqTxn *req = m_ongoingTxn[txnID];
				DatMsg *dat = new DatMsg(req, Dat::NonCopyBackWrData,
								rsp.GetDBID());

				// To SN
				m_port_SN[0]->Transmit(dat);

				if (rsp.IsCompDBIDResp()) {
					req->SetCompSNReceived(true);
				}

				if (rsp.IsCompDBIDResp() || req->GetCompSNReceived()) {
					if (req->GotSnpData()) {
						//
						// Always return after written out
						// dirty snoop data
						//
						m_ids->ReturnID(txnID);
						m_ongoingTxn[txnID] = NULL;

						//
						// Rerun the req now
						//
						ProcessSnpdReq(req);
					} else if (req->IsWrite() || req->IsAtomicStore()) {
						//
						// Write / AtomicStore req from RN done
						// if not expecting CompAck (or if
						// CompAck has been received), only
						// WriteUnique can expect CompAck Table
						// 2-8 [1]
						//

						if (!req->GetExpCompAck() ||
							req->GetCompAckReceived()) {

							m_ids->ReturnID(txnID);
							m_ongoingTxn[txnID] = NULL;

							RequestDone(req);
						} else {
							assert(req->IsWriteUnique());
							req->SetWriteToSNDone(true);
						}
					}
				}
			} else if (rsp.IsComp()) {
				uint8_t txnID = rsp.GetTxnID();
				ReqTxn *req = m_ongoingTxn[txnID];

				req->SetCompSNReceived(true);

				if (req->GetWriteToSNDone()) {
					if (req->GotSnpData()) {
						//
						// Always return after written out
						// dirty snoop data
						//
						m_ids->ReturnID(txnID);
						m_ongoingTxn[txnID] = NULL;

						//
						// Rerun the req now
						//
						ProcessSnpdReq(req);
					} else if (req->IsWrite() || req->IsAtomicStore()) {
						//
						// Write / AtomicStore req from RN done
						// if not expecting CompAck (or if
						// CompAck has been received), only
						// WriteUnique can expect CompAck Table
						// 2-8 [1]
						//

						if (!req->GetExpCompAck() ||
							req->GetCompAckReceived()) {

							m_ids->ReturnID(txnID);
							m_ongoingTxn[txnID] = NULL;

							RequestDone(req);
						} else {
							assert(req->IsWriteUnique());
							req->SetWriteToSNDone(true);
						}
					}
				}
			} else if (rsp.IsReadReceipt()) {
				uint8_t txnID = rsp.GetTxnID();
				ReqTxn *req = m_ongoingTxn[txnID];

				assert(req);
				assert(req->GetWaitingForReadReceipt());

				//
				// No CompAck will come for this ReadOnce /
				// ReadNoSnp, so request is done (Order == 0 and
				// ExpCompAck == 0, table 2-7)
				//
				m_ids->ReturnID(txnID);
				m_ongoingTxn[txnID] = NULL;

				RequestDone(req);
			}
		}

		void RequestDone(ReqTxn* req)
		{
			m_reqOrderer->ReqDone(req);
		}

		Port_RN_F *LookupPortRNF(uint16_t nodeID)
		{
			for (int i = 0; i < NUM_CHI_RN_F; i++) {
				if (m_port_RN_F[i]->GetNodeID() == nodeID) {
					return m_port_RN_F[i];
				}
			}
			return NULL;
		}


		void TransmitReadReceipt(ReqTxn *req)
		{
			RspMsg *rsp = new RspMsg(req, Rsp::ReadReceipt);

			TransmitToRequestNode(rsp);
		}

		Port_CCIX *LookupPortCCIX(uint16_t nodeID)
		{
			for (int i = 0; i < NUM_CCIX_PORTS; i++) {
				if (m_port_CCIX[i]->Contains(nodeID)) {
					return m_port_CCIX[i];
				}
			}
			return NULL;
		}

	private:
		void UpdatePortRNFSnoopFilter(ReqTxn *req)
		{
			Port_RN_F *port = LookupPortRNF(req->GetSrcID());
			Port_CCIX *port_CCIX;

			if (port) {
				port->GetSnoopFilter().Update(req);

			} else if ((port_CCIX = LookupPortCCIX(req->GetSrcID()))) {

				port_CCIX->UpdateSnoopFilter(req);
			}
		}

		template<typename TxnType>
		void TransmitToRequestNode(TxnType *t)
		{
			Port_RN_F *port = LookupPortRNF(t->GetTgtID());

			if (port) {
				port->Transmit(t);
			}
		}

		//
		// Request Node ports
		//
		Port_RN_F **m_port_RN_F;

		//
		// CCIX ports
		//
		Port_CCIX **m_port_CCIX;

		//
		// Slave Node port
		//
		Port_SN **m_port_SN;

		//
		// Transaction IDs
		//
		TxnIDs *m_ids;

		//
		// Ongoing transactions tracking
		//
		ReqTxn **m_ongoingTxn;
		RequestOrderer *m_reqOrderer;

		// IDVMOpProcessor
		IDVMOpProcessor *m_poc;

		IPacketRouter *m_router;
	};

	//
	// Point of Coherence, PoC, snoops the required RN-F / RN-D
	//
	class PointOfCoherence : public IDVMOpProcessor
	{
	public:
		PointOfCoherence(Port_RN_F **port_RN_F,
				Port_CCIX **port_CCIX,
				TxnIDs *ids,
				ReqTxn **ongoingTxn,
				TxnProcessor& txnProcessor) :
			m_port_RN_F(port_RN_F),
			m_port_CCIX(port_CCIX),
			m_ids(ids),
			m_ongoingTxn(ongoingTxn),
			m_txnProcessor(txnProcessor),
			m_DCT_enabled(NUM_CCIX_PORTS == 0)
		{}

		void ProcessReq(ReqTxn *req)
		{
			std::list<Port_RN_F*> ports;
			std::list<Port_CCIX*> ports_CCIX;

			FillPortsToSnoop(req, ports, ports_CCIX);

			if (ports.empty() && ports_CCIX.empty()) {
				m_txnProcessor.ProcessReq(req);
			} else {
				typename std::list<Port_RN_F*>::iterator it;
				typename std::list<Port_CCIX*>::iterator ccixIt;

				//
				// Do DCT only to one port and Exclusive don't
				// allow DCT 6.3.1 [1]
				//
				bool allowsSnpFwd = false;

				if (m_DCT_enabled) {
					allowsSnpFwd =
						ports.size() == 1 &&
						!req->GetExcl();
				}

				for (it = ports.begin(); it != ports.end(); it++) {
					SnpMsg *snp = new SnpMsg(req,
								m_ids->GetID(),
								allowsSnpFwd);
					Port_RN_F *port = (*it);

					if (allowsSnpFwd && snp->IsSnpFwded()) {
						req->SetIsSnpFwded(true);
						req->SetWaitingForCompAck(true);
					}

					req->WaitForSnpTxn(snp->GetTxnID());
					m_ongoingTxn[snp->GetTxnID()] = req;

					port->Transmit(snp);
				}

				//
				// Iterate CCIX ports now
				//
				// allowsSnpFwd is always false when using CCIX
				// ports
				//
				for (ccixIt = ports_CCIX.begin();
					ccixIt != ports_CCIX.end(); ccixIt++) {

					//
					// Never allow SnpFwd*
					//
					SnpMsg snp(req, m_ids->GetID(), false);

					Port_CCIX *port_CCIX = (*ccixIt);

					req->WaitForSnpTxn(snp.GetTxnID());
					m_ongoingTxn[snp.GetTxnID()] = req;

					port_CCIX->Transmit(req, snp);
				}
			}
		}

		void ProcessDVM(ReqTxn *req)
		{
			for (int i = 0; i < NUM_CHI_RN_F; i++) {
				Port_RN_F *port = m_port_RN_F[i];

				if (port->GetNodeID() != req->GetSrcID()) {
					uint8_t txnID = m_ids->GetID();
					SnpMsg *dvmSnp0 = new SnpMsg(req, txnID, false);
					SnpMsg *dvmSnp1 = new SnpMsg(req, txnID, true);

					req->WaitForSnpTxn(txnID);
					m_ongoingTxn[txnID] = req;

					port->Transmit(dvmSnp0);
					port->Transmit(dvmSnp1);
				}
			}
		}

		void FillPortsToSnoop(ReqTxn *req,
					std::list<Port_RN_F*>& ports,
					std::list<Port_CCIX*>& ports_CCIX)
		{
			for (int i = 0; i < NUM_CHI_RN_F; i++) {
				Port_RN_F *port = m_port_RN_F[i];

				if (port->GetNodeID() != req->GetSrcID() ||
					req->GetSnpMe()) {

					SnoopFilter& snpFilter =
						port->GetSnoopFilter();
					Address addr(req);

					if (snpFilter.ContainsAllocated(addr)) {
						ports.push_back(port);
					}
				}
			}

			for (int i = 0; i < NUM_CCIX_PORTS; i++) {
				Port_CCIX *port = m_port_CCIX[i];

				if (port->NeedsSnoop(req)) {
					ports_CCIX.push_back(port);
				}
			}
		}

		void ProcessResp(RspMsg& rsp)
		{
			uint16_t txnID = rsp.GetTxnID();
			ReqTxn *req = m_ongoingTxn[txnID];

			assert(req);

			if (req) {
				uint16_t id = rsp.GetSrcID();
				uint8_t resp = rsp.GetCHIAttr()->GetResp();
				Port_RN_F *port =
					m_txnProcessor.LookupPortRNF(id);
				Port_CCIX *port_CCIX =
					m_txnProcessor.LookupPortCCIX(id);
				bool noFwdedData;
				bool fwdedDataGotCompAck;

				//
				// Snoop filter update
				//
				if (port) {
					port->GetSnoopFilter().Update(rsp, req);
				} else if (port_CCIX) {
					port_CCIX->UpdateSnoopFilter(rsp, req);
				}

				//
				// Single snoop tx done
				//
				req->SetSnpTxnDone(txnID, resp);

				//
				// Track if we sent data when using Snp*Fwded
				//
				if (req->IsSnpFwded()) {
					req->SetSnpDataFwded(rsp.IsSnpRespFwded());
				}

				//
				// Wait for CompAck if it is a Snp*Fwded that
				// has forwarded data
				//
				//
				noFwdedData = req->IsSnpFwded() &&
						!req->SnpDataFwded();

				fwdedDataGotCompAck =
					req->IsSnpFwded() && req->SnpDataFwded() &&
					req->GetCompAckReceived();

				if (!req->IsSnpFwded() || noFwdedData ||
						fwdedDataGotCompAck) {
					//
					// Single snoop txn done
					//
					m_ongoingTxn[txnID] = NULL;
					m_ids->ReturnID(txnID);
				}

				CheckSnpDone(req);
			}
		}

		void ProcessDat(DatMsg& dat)
		{
			uint16_t txnID = dat.GetTxnID();
			ReqTxn *req = m_ongoingTxn[txnID];

			assert(req);

			if (req) {
				req->CopySnpData(&dat);

				//
				// Depending on channel size this can come in
				// up to 4 packets for every txnID.
				//
				if (req->AllSnpDataReceived(txnID)) {
					uint16_t id = dat.GetSrcID();
					Port_RN_F *port =
						m_txnProcessor.LookupPortRNF(id);
					Port_CCIX *port_CCIX =
						m_txnProcessor.LookupPortCCIX(id);
					bool noFwdedData;
					bool fwdedDataGotCompAck;

					//
					// Snoop filter update
					//
					if (port) {
						port->GetSnoopFilter().Update(dat, req);
					} else if (port_CCIX) {
						port_CCIX->UpdateSnoopFilter(dat, req);
					}

					//
					// Track if we sent data when using Snp*Fwded
					//
					if (req->IsSnpFwded()) {
						req->SetSnpDataFwded(dat.IsSnpRespDataFwded());
					}


					//
					// Wait for CompAck if it is a Snp*Fwded that
					// has forwarded data
					//
					noFwdedData = req->IsSnpFwded() &&
						!req->SnpDataFwded();

					fwdedDataGotCompAck =
						req->IsSnpFwded() && req->SnpDataFwded() &&
						req->GetCompAckReceived();

					if (!req->IsSnpFwded() || noFwdedData ||
						fwdedDataGotCompAck) {
						//
						// Single snoop txn done
						//
						m_ongoingTxn[txnID] = NULL;
						m_ids->ReturnID(txnID);
					}

					CheckSnpDone(req);
				}
			}
		}

		void CheckSnpDone(ReqTxn *req)
		{
			if (req->AllSnpTxnDone()) {

				if (req->IsSnpFwded() && req->SnpDataFwded()) {

					if (req->GetCompAckReceived()) {
						//
						// Req is done
						//
						m_txnProcessor.RequestDone(req);
					}
					//
					// Else keep waiting for CompAck on the same
					// txnID (txn and txnID has already setup)
					//

				} else {
					//
					// All snoops done, continue processing req
					//

					req->ParseSnpResponses();

					m_txnProcessor.ProcessSnpdReq(req);
				}
			}
		}

		void EnableDCT(bool enable) { m_DCT_enabled = enable; }
	private:
		Port_RN_F **m_port_RN_F;
		Port_CCIX **m_port_CCIX;

		TxnIDs *m_ids;
		ReqTxn **m_ongoingTxn;

		TxnProcessor& m_txnProcessor;

		bool m_DCT_enabled;
	};

	class ExclusiveMonitor
	{
	public:
		bool HandleExclusive(ReqTxn *req)
		{
			bool exclusivePassed = true;

			if (req->IsCleanUnique() && InList(req->GetLPID())) {
				//
				// Exclusive store passed, clear the list here
				// and below will 'if' will add the LPID back
				// in as recomended in 6.2.1 [1]
				//
				m_LPIDs.clear();
			} else {
				exclusivePassed = false;
			}

			if (IsExclusive(req)) {
				m_LPIDs.push_back(req->GetLPID());
			}

			if (exclusivePassed) {
				req->SetRespErr(RespErr::ExclusiveOkay);
			}

			return exclusivePassed;
		}

	private:

		bool InList(uint8_t LPID)
		{
			typename std::list<uint8_t>::iterator it;
			for (it = m_LPIDs.begin();
				it != m_LPIDs.end(); it++) {

				if ((*it) == LPID) {
					return true;
				}
			}
			return false;
		}

		bool IsExclusive(ReqTxn *req)
		{
			switch (req->GetOpcode()) {
			case Req::ReadClean:
			case Req::ReadNotSharedDirty:
			case Req::ReadShared:
			case Req::CleanUnique:
				return true;
			default:
				break;
			}
			return false;
		}

		std::list<uint8_t> m_LPIDs;
	};

	class SystemAddressMap
	{
	public:
		void AddMap(uint64_t startAddress,
				unsigned int regionLength,
				uint16_t TgtID)
		{
			uint64_t endAddress = startAddress + regionLength;

			m_maps.push_back(AddressMap(startAddress,
							endAddress,
							TgtID));
		}

		void AddPrefetchTgtMap(uint64_t startAddress,
					unsigned int regionLength,
					uint16_t TgtID)
		{
			uint64_t endAddress = startAddress + regionLength;

			m_prefetchTgt.push_back(AddressMap(startAddress,
								endAddress,
								TgtID));
		}

		void UpdateTgtID(ReqTxn *req)
		{
			//
			// See 3.3.1 about PrefetchTgt and DVMOp
			//
			// Forwarding DVMOp reqs are not supported yet.
			//
			if (req->GetOpcode() == Req::PrefetchTgt) {

				//
				// PrefetchTgt maps
				//
				IterateMaps(m_prefetchTgt, req);

			} else if (!req->IsDVMOp()) {
				//
				// All other reqs
				//
				IterateMaps(m_maps, req);
			}
		}

	private:
		class AddressMap
		{
		public:
			AddressMap(uint64_t startAddress,
					uint64_t endAddress, uint16_t TgtID) :
				m_startAddress(startAddress),
				m_endAddress(endAddress),
				m_TgtID(TgtID)
			{}

			bool InRegion(uint64_t addr)
			{
				return addr >= m_startAddress &&
					addr < m_endAddress;
			}

			uint16_t GetTgtID() { return m_TgtID; }

		private:
			uint64_t m_startAddress;
			uint64_t m_endAddress;
			uint16_t m_TgtID;
		};

		void IterateMaps(std::vector<AddressMap>& maps, ReqTxn *req)
		{
			typename std::vector<AddressMap>::iterator it;

			for (it = maps.begin(); it != maps.end(); it++) {
				AddressMap& map = (*it);

				if (map.InRegion(req->GetAddress())) {
					uint16_t tgtID = map.GetTgtID();

					//
					// Update TgtID
					//
					req->GetCHIAttr()->SetTgtID(tgtID);
				}
			}
		}

		std::vector<AddressMap> m_maps;
		std::vector<AddressMap> m_prefetchTgt;
	};

	class PacketRouter :
		public IPacketRouter
	{
	public:

		PacketRouter(SystemAddressMap& sam,
				PointOfCoherence& poc,
				TxnProcessor& txnProcessor,
				Port_RN_F **port_RN_F,
				Port_CCIX **port_CCIX) :
			m_sam(sam),
			m_poc(poc),
			m_txnProcessor(txnProcessor),
			m_port_RN_F(port_RN_F),
			m_port_CCIX(port_CCIX)
		{}

		void RouteReq(ReqTxn *req)
		{
			Port_CCIX *port_CCIX;

			m_sam.UpdateTgtID(req);

			port_CCIX = LookupPortCCIX(req->GetTgtID());

			if (port_CCIX) {
				port_CCIX->ProcessReq(req);
			} else {
				RouteInternal(req);
			}
		}

		void RouteInternal(ReqTxn *req)
		{
			bool exclusivePassed = true;

			//
			// See Table 2-7
			//
			if (req->IsNonCoherentRead() &&
				req->IsOrdered()) {
				m_txnProcessor.TransmitReadReceipt(req);
			}

			if (!req->IsAtomic() && req->GetExcl()) {
				exclusivePassed = m_exmon.HandleExclusive(req);
			}

			if (req->GetSnpAttr() && req->IsSnoopingReq() &&
				exclusivePassed) {

				m_poc.ProcessReq(req);

			} else {

				m_txnProcessor.ProcessReq(req);
			}
		}

		void RouteDat(DatMsg& dat)
		{
			Port_RN_F *port_RN_F;
			Port_CCIX *port_CCIX;

			if (dat.GetTgtID() == NODE_ID) {
				bool isSnpResp = dat.IsSnpRespData() ||
						dat.IsSnpRespDataPtl() ||
						dat.IsSnpRespDataFwded();

				if (isSnpResp) {
					m_poc.ProcessDat(dat);
				} else {
					m_txnProcessor.ProcessDat(dat);
				}
			} else if ((port_RN_F = LookupPortRNF(dat.GetTgtID()))) {

				port_RN_F->Transmit(new DatMsg(dat));

			} else if ((port_CCIX = LookupPortCCIX(dat.GetTgtID()))) {

				port_CCIX->ProcessDat(dat);
			}
		}

		void RouteRsp(RspMsg& rsp)
		{
			Port_CCIX *port_CCIX;
			Port_RN_F *port_RN_F;

			if (rsp.GetTgtID() == NODE_ID) {
				if (rsp.IsSnpResp() || rsp.IsSnpRespFwded()) {
					m_poc.ProcessResp(rsp);
				} else {
					m_txnProcessor.ProcessResp(rsp);
				}
			} else if ((port_RN_F = LookupPortRNF(rsp.GetTgtID()))) {

				port_RN_F->Transmit(new RspMsg(rsp));

			} else if ((port_CCIX = LookupPortCCIX(rsp.GetTgtID()))) {

				port_CCIX->ProcessResp(rsp);
			}
		}

		void RouteDat_SN(DatMsg& dat)
		{
			if (dat.GetTgtID() == NODE_ID) {
				m_txnProcessor.ProcessDat_SN(dat);
			} else {
				//
				// DMT
				//
				RouteDat(dat);
			}
		}

		void RouteRsp_SN(RspMsg& rsp)
		{
			m_txnProcessor.ProcessResp_SN(rsp);
		}

		void TransmitToRequestNode(RspMsg *t)
		{
			Port_RN_F *port = LookupPortRNF(t->GetTgtID());

			if (port) {
				port->Transmit(t);
			}
		}

		void RouteSnpReq(SnpMsg& msg)
		{
			for (int i = 0; i < NUM_CHI_RN_F; i++) {
				m_port_RN_F[i]->Transmit(new SnpMsg(msg));
			}
		}

	private:
		Port_RN_F *LookupPortRNF(uint16_t nodeID)
		{
			for (int i = 0; i < NUM_CHI_RN_F; i++) {
				if (m_port_RN_F[i]->GetNodeID() == nodeID) {
					return m_port_RN_F[i];
				}
			}
			return NULL;
		}

		Port_CCIX *LookupPortCCIX(uint16_t nodeID)
		{
			for (int i = 0; i < NUM_CCIX_PORTS; i++) {
				if (m_port_CCIX[i]->Contains(nodeID)) {
					return m_port_CCIX[i];
				}
			}
			return NULL;
		}

		SystemAddressMap& m_sam;
		PointOfCoherence& m_poc;
		TxnProcessor& m_txnProcessor;
		Port_RN_F **m_port_RN_F;
		Port_CCIX **m_port_CCIX;
		ExclusiveMonitor m_exmon;
	};

	RequestOrderer m_reqOrderer;
	TxnIDs m_ids;
	ReqTxn *m_ongoingTxn[TxnIDs::NumIDs];

	TxnProcessor m_txnProcessor;
	PointOfCoherence m_poc;
	SystemAddressMap m_sam;
	PacketRouter m_router;

public:

	Port_RN_F *port_RN_F[NUM_CHI_RN_F];
	Port_SN   *port_SN;

	Port_CCIX *port_CCIX[NUM_CCIX_PORTS];

	SC_HAS_PROCESS(iconnect_chi);

	iconnect_chi(sc_module_name name) :
		sc_core::sc_module(name),

		m_reqOrderer("reqOrderer",
				&m_router),

		m_txnProcessor(port_RN_F,
				port_CCIX,
				&port_SN,
				&m_ids,
				m_ongoingTxn,
				&m_reqOrderer,
				&m_poc,
				&m_router),

		m_poc(port_RN_F,
			port_CCIX,
			&m_ids,
			m_ongoingTxn,
			m_txnProcessor),

		m_router(m_sam,
			m_poc,
			m_txnProcessor,
			port_RN_F,
			port_CCIX)
	{
		for (int portID = 0; portID < NUM_CHI_RN_F; portID++) {
			std::ostringstream name;

			name << "port_RN_F" << portID;

			port_RN_F[portID] = new Port_RN_F(name.str().c_str(),
							&m_router,
							&m_reqOrderer,
							portID);
		}

		port_SN = new Port_SN("Port_SN", &m_router, SLAVE_NODE_ID);

		for (int portID = 0; portID < NUM_CCIX_PORTS; portID++) {
			std::ostringstream name;

			name << "port_CCIX" << portID;

			port_CCIX[portID] = new Port_CCIX(name.str().c_str(),
							NODE_ID,
							&m_router,
							&m_reqOrderer,
							&m_ids,
							m_ongoingTxn);
		}

		memset(m_ongoingTxn,
			0x0,
			TxnIDs::NumIDs * sizeof(m_ongoingTxn[0]));
	}

	void EnableDCT(bool enable) { m_poc.EnableDCT(enable); }

	SystemAddressMap& SystemAddressMap() { return m_sam; }

	virtual ~iconnect_chi()
	{
		for (int i = 0; i < NUM_CHI_RN_F; i++) {
			delete port_RN_F[i];
		}
		delete port_SN;
		for (int i = 0; i < NUM_CCIX_PORTS; i++) {
			delete port_CCIX[i];
		}
	}
};

#endif /* TLM_MODULES_ICONNECT_CHI_H__ */
