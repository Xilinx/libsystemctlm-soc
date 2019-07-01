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
 * [1] AMBA 5 CHI Architecture Specification, ARM IHI 0050C, ID050218
 *
 */

#ifndef TLM_MODULES_PRIV_CHI_TXNS_RN_H__
#define TLM_MODULES_PRIV_CHI_TXNS_RN_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/chiattr.h"
#include "tlm-bridges/amba-chi.h"
#include "tlm-modules/private/chi/cacheline.h"

namespace AMBA {
namespace CHI {
namespace RN {

template<
	int NODE_ID,
	int ICN_ID>
class ITxn
{
public:
	ITxn(uint8_t opcode, TxnIDs* ids,
			CacheLine *l = NULL, bool isSnp = false) :
		m_l(l),
		m_chiattr(new chiattr_extension()),
		m_ids(ids),
		m_txnID(0),
		m_isSnp(isSnp),
		m_gotRetryAck(false),
		m_gotPCrdGrant(false),
		m_isWriteUniqueWithCompAck(false)
	{
		m_chiattr->SetSrcID(NODE_ID);

		if (!m_isSnp) {
			if (DoAssertCheck(opcode)) {
				assert(m_l);
			}

			// Store for release in destructor
			m_txnID = m_ids->GetID();

			m_chiattr->SetTgtID(ICN_ID);
			m_chiattr->SetTxnID(m_txnID);
			m_chiattr->SetOpcode(opcode);
		} else {
			assert(m_l == NULL);
			assert(m_ids == NULL);
		}

		//
		// Transactions (except PrefetchTgt) must start with
		// AllowRetry asserted 2.11 [1]
		//
		if (opcode != Req::PrefetchTgt) {
			m_chiattr->SetAllowRetry(true);
		}

		// Takes ownership of the ptr
		m_gp.set_extension(m_chiattr);
	}

	virtual ~ITxn()
	{
		if (m_ids) {
			m_ids->ReturnID(m_txnID);
		}
	}

	bool DoAssertCheck(uint8_t opcode)
	{
		if (opcode >= Req::AtomicStore &&
			opcode <= Req::AtomicCompare) {
			return false;
		}
		switch (opcode) {
		case Req::ReadOnce:
		case Req::ReadOnceCleanInvalid:
		case Req::ReadOnceMakeInvalid:
		case Req::ReadNoSnp:
		case Req::WriteUniquePtl:
		case Req::WriteUniqueFull:
		case Req::WriteNoSnpPtl:
		case Req::DVMOp:
			return false;
		default:
			break;
		}
		return true;
	}

	virtual bool HandleRxRsp(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
	{
		return false;
	}

	virtual bool HandleRxDat(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
	{
		return false;
	}

	virtual bool TransmitOnTxDatChannel() { return false; }

	virtual bool TransmitOnTxRspChannel() { return false; }

	bool RetryRequest()
	{
		m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
		return m_gotRetryAck && m_gotPCrdGrant;
	}

	void HandleRetryAck(chiattr_extension *chiattr)
	{
		//
		// Keep TgtID, Set PCrdType and deassert AllowRetry
		// 2.6.5 + 2.11.2 [1]
		//
		m_chiattr->SetAllowRetry(false);
		m_chiattr->SetPCrdType(chiattr->GetPCrdType());
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

	//
	// For transactions that terminate after a TXChannel, example
	// with ExpCompAck
	//
	virtual bool Done() = 0;

	tlm::tlm_generic_payload& GetGP()
	{
		return m_gp;
	}

	uint8_t GetTxnID() { return m_txnID; }
	uint8_t GetDBID() { return m_chiattr->GetDBID(); }

	bool IsSnp() { return m_isSnp; }

	sc_event& DoneEvent() { return m_done; }

	bool GetIsWriteUniqueWithCompAck()
	{
		return m_isWriteUniqueWithCompAck;
	}

	void SetIsWriteUniqueWithCompAck(bool val)
	{
		m_isWriteUniqueWithCompAck = val;
	}

protected:

	//
	// Copy over relevant attributes for transactions that will
	// fill read in / allocate a cacheline.
	//
	void CopyCHIAttr(tlm::tlm_generic_payload& gp)
	{
		chiattr_extension *attr;

		gp.get_extension(attr);
		if (attr) {
			CopyCHIAttr(attr);

			m_chiattr->SetOrder(attr->GetOrder());
		}
	}

	//
	// Copy attributes when reading in / writing back a cacheline
	//
	void CopyCHIAttr(chiattr_extension *attr)
	{
		assert(attr);

		m_chiattr->SetNonSecure(attr->GetNonSecure());

		m_chiattr->SetDeviceMemory(attr->GetDeviceMemory());
		m_chiattr->SetCacheable(attr->GetCacheable());
		m_chiattr->SetAllocate(attr->GetAllocate());

		m_chiattr->SetQoS(attr->GetQoS());
	}

	void SetupCompAck(chiattr_extension *chiattr,
				bool targetHomeNID = true)
	{
		m_gp.set_command(tlm::TLM_IGNORE_COMMAND);
		m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		m_chiattr->SetExpCompAck(false);
		if (targetHomeNID) {
			m_chiattr->SetTgtID(chiattr->GetHomeNID());
		} else {
			m_chiattr->SetTgtID(chiattr->GetSrcID());
		}
		m_chiattr->SetTxnID(chiattr->GetDBID());
		m_chiattr->SetOpcode(Rsp::CompAck);
	}

	unsigned int CopyData(tlm::tlm_generic_payload& gp,
			chiattr_extension *chiattr)
	{
		unsigned char *data = gp.get_data_ptr();
		unsigned int len = gp.get_data_length();
		unsigned int offset = chiattr->GetDataID() * len;
		unsigned char *be = gp.get_byte_enable_ptr();
		unsigned int be_len = gp.get_byte_enable_length();
		unsigned int max_len = CACHELINE_SZ - offset;

		if (len > max_len) {
			len = max_len;
		}

		m_l->Write(offset, data, len, be, be_len);

		return len;
	}

	void ParseReadResp(chiattr_extension *chiattr)
	{
		if (chiattr->GetOpcode() == Dat::DataSepResp) {
			switch (chiattr->GetResp()) {
			case Resp::DataSepResp_UC:
				m_l->SetValid(true);
				m_l->SetShared(false);
				m_l->SetDirty(false);
				break;
			case Resp::DataSepResp_SC:
				m_l->SetValid(true);
				m_l->SetShared(true);
				m_l->SetDirty(false);
				break;
			case Resp::DataSepResp_I:
			default:
				m_l->SetValid(false);
				break;
			}
		} else if (chiattr->GetOpcode() == Dat::CompData) {
			switch (chiattr->GetResp()) {
			case Resp::CompData_UC:
				m_l->SetValid(true);
				m_l->SetShared(false);
				m_l->SetDirty(false);
				break;
			case Resp::CompData_SC:
				m_l->SetValid(true);
				m_l->SetShared(true);
				m_l->SetDirty(false);
				break;
			case Resp::CompData_UD_PD:
				m_l->SetValid(true);
				m_l->SetShared(false);
				m_l->SetDirty(true);
				break;
			case Resp::CompData_SD_PD:
				m_l->SetValid(true);
				m_l->SetShared(true);
				m_l->SetDirty(true);
				break;
			case Resp::CompData_I:
			default:
				m_l->SetValid(false);
				break;
			}
		} else {
			m_l->SetValid(false);
		}
	}

	CacheLine *m_l;
	tlm::tlm_generic_payload m_gp;
	chiattr_extension *m_chiattr;
	TxnIDs *m_ids;
	uint8_t m_txnID;
	sc_event m_done;
	bool m_isSnp;
	bool m_gotRetryAck;
	bool m_gotPCrdGrant;
	bool m_isWriteUniqueWithCompAck;
};

template<
	int NODE_ID,
	int ICN_ID>
class ReadTxn : public ITxn<NODE_ID, ICN_ID>
{
public:
	typedef ITxn<NODE_ID, ICN_ID> ITxn_t;

	using ITxn_t::m_gp;
	using ITxn_t::m_chiattr;
	using ITxn_t::m_l;

	ReadTxn(tlm::tlm_generic_payload& gp,
			uint8_t opcode,
			uint64_t addr,
			CacheLine *l,
			TxnIDs *ids) :
		ITxn_t(opcode, ids, l),
		m_readAddr(addr),
		m_gotRspSepData(false),
		m_gotReadReceipt(true),
		m_gotDataSepRsp(false),
		m_received(0),
		m_transmitCompAck(true)
	{
		unsigned int len = CACHELINE_SZ;

		memset(m_data, 0, sizeof(m_data));
		memset(m_byteEnable, 0, sizeof(m_byteEnable));

		m_gp.set_command(tlm::TLM_IGNORE_COMMAND);

		m_gp.set_address(addr);

		m_gp.set_data_length(len);
		m_gp.set_data_ptr(m_data);	// unused on ignore gps

		m_gp.set_byte_enable_ptr(NULL);
		m_gp.set_byte_enable_length(0);

		m_gp.set_streaming_width(len);

		m_gp.set_dmi_allowed(false);
		m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		// It is permitted to use CompAck on all read, 2.8.3
		// [1]
		m_chiattr->SetExpCompAck(true);

		//
		// SnpAttr must be set on ReadOnce*, ReadClean,
		// ReadShared, ReadNotSharedDirty, ReadUnique and must
		// be unset on ReadNoSnp and ReadNoSnpSep.
		// 2.9.6 [1]
		//
		if (opcode == Req::ReadNoSnp ||
			opcode == Req::ReadNoSnpSep) {
			m_chiattr->SetSnpAttr(false);
		} else {
			m_chiattr->SetSnpAttr(true);
		}

		this->CopyCHIAttr(gp);

		if (IsNonCoherentRead() && IsOrdered()) {
			m_gotReadReceipt = false;
		}
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

	bool IsOrdered()
	{
		return m_chiattr->GetOrder() > 1;
	}

	virtual bool HandleRxRsp(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
	{
		bool acceptRspSepData = !m_gotRspSepData &&
			chiattr->GetOpcode() == Rsp::RespSepData;

		bool acceptReadReceipt = !m_gotRspSepData &&
			chiattr->GetOpcode() == Rsp::ReadReceipt;

		bool rspHandled = false;

		if (acceptRspSepData) {

			//
			// RspSepData means ReadReceipt
			//
			m_gotRspSepData = true;
			m_gotReadReceipt = true;

			rspHandled = true;

		} else if (acceptReadReceipt) {

			m_gotReadReceipt = true;

			rspHandled = true;
		}

		return rspHandled;
	}

	virtual bool HandleRxDat(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
	{
		bool acceptCompData =
			m_gotRspSepData == false &&
			m_gotDataSepRsp == false &&
			chiattr->GetOpcode() == Dat::CompData;

		bool acceptDataSepRsp =
			m_gotDataSepRsp == false &&
			chiattr->GetOpcode() == Dat::DataSepResp;

		bool datHandled = false;

		if (acceptCompData || acceptDataSepRsp) {

			if (IsNonCoherentRead()) {
				m_received += CopyDataNonCoherent(gp, chiattr);
			} else {
				m_received += this->CopyData(gp, chiattr);

				this->ParseReadResp(chiattr);
				if (m_l->IsValid()) {
					m_l->SetTag(m_readAddr);
					m_l->ByteEnablesEnableAll();

					//
					// Copy the attributes used into the line
					//
					m_l->SetCHIAttr(m_chiattr);
				}
			}

			if (m_received == CACHELINE_SZ) {
				m_gotRspSepData = true;
				m_gotDataSepRsp = true;

				// All done setup CompAck
				this->SetupCompAck(chiattr);
			}

			datHandled = true;
		}

		return datHandled;
	}

	bool TransmitOnTxRspChannel()
	{
		//
		// 2.3.1, Read no with separate non-data and data-only
		// responses: All reads are permitted to wait for both
		// responses before signaling CompAck (required for
		// ordered ReadOnce and ReadNoSnp).
		//
		return m_transmitCompAck &&
			m_gotRspSepData && m_gotDataSepRsp;
	}

	bool IsReadOnce()
	{
		return m_chiattr->GetOpcode() == Req::ReadOnce;
	}


	unsigned int CopyDataNonCoherent(tlm::tlm_generic_payload& gp,
			chiattr_extension *chiattr)
	{
		unsigned char *data = gp.get_data_ptr();
		unsigned int len = gp.get_data_length();
		unsigned int offset = chiattr->GetDataID() * len;
		unsigned char *be = gp.get_byte_enable_ptr();
		unsigned int be_len = gp.get_byte_enable_length();
		unsigned int max_len = CACHELINE_SZ - offset;

		assert(len == be_len);

		if (len > max_len) {
			len = max_len;
		}

		memcpy(&m_data[offset], data, len);
		memcpy(&m_byteEnable[offset], be, len);

		return len;
	}

	unsigned int FetchNonCoherentData(tlm::tlm_generic_payload& gp,
				unsigned int pos,
				unsigned int line_offset)
	{
		unsigned char *data = gp.get_data_ptr() + pos;
		unsigned int len = gp.get_data_length() - pos;
		unsigned int max_len = CACHELINE_SZ - line_offset;
		unsigned char *be = gp.get_byte_enable_ptr();
		unsigned int be_len = gp.get_byte_enable_length();

		if (len > max_len) {
			len = max_len;
		}

		if (be_len) {
			unsigned int i;

			for (i = 0; i < len; i++, pos++) {
				bool do_access = be[pos % be_len] == TLM_BYTE_ENABLED;

				if (do_access) {
					data[i] = m_data[line_offset + i];
				}
			}
		} else {
			memcpy(data, &m_data[line_offset], len);
		}

		return len;
	}

	bool Done()
	{
		bool compAckDone = true;

		if (m_transmitCompAck) {
			compAckDone = m_gp.get_response_status() !=
						tlm::TLM_INCOMPLETE_RESPONSE;
		}

		return m_gotRspSepData && m_gotDataSepRsp &&
			m_gotReadReceipt && compAckDone;
	}

	void SetExpCompAck(bool val)
	{
		m_chiattr->SetExpCompAck(val);
		m_transmitCompAck = val;
	}
private:
	uint64_t m_readAddr;
	bool m_gotRspSepData;
	bool m_gotReadReceipt;
	bool m_gotDataSepRsp;
	unsigned int m_received;

	bool m_transmitCompAck;

	uint8_t m_data[CACHELINE_SZ];
	uint8_t m_byteEnable[CACHELINE_SZ];
};

template<
	int NODE_ID,
	int ICN_ID>
class DatalessTxn : public ITxn<NODE_ID, ICN_ID>
{
public:
	typedef ITxn<NODE_ID, ICN_ID> ITxn_t;

	using ITxn_t::m_gp;
	using ITxn_t::m_chiattr;
	using ITxn_t::m_l;

	DatalessTxn(uint8_t opcode,
			uint64_t addr,	// cache aligned
			CacheLine *l,
			TxnIDs *ids,
			tlm::tlm_generic_payload *gp = NULL  // Used for MakeUnique
			) :
		ITxn<NODE_ID, ICN_ID>(opcode, ids, l),
		m_gotComp(false),
		m_transmitCompAck(false)
	{
		unsigned int len = CACHELINE_SZ;

		m_gp.set_command(tlm::TLM_IGNORE_COMMAND);

		m_gp.set_address(addr);

		m_gp.set_data_length(len);
		m_gp.set_data_ptr(l->GetData());

		m_gp.set_byte_enable_ptr(NULL);
		m_gp.set_byte_enable_length(0);

		m_gp.set_streaming_width(len);

		m_gp.set_dmi_allowed(false);
		m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		//
		// Below must assert ExpCompACk but not the other
		// dataless reqs, 2.3.1 [1]
		//
		if (opcode == Req::CleanUnique ||
			opcode == Req::MakeUnique) {
			m_chiattr->SetExpCompAck(true);
			m_transmitCompAck = true;
		}
		//
		// SnpAttr is allowed to be set on all and must be set
		// on CleanUnique, MakeUnique, StashOnce*, Evict ,
		// 2.9.6 [1]
		//
		m_chiattr->SetSnpAttr(true);

		m_isCacheMaintenance = IsCacheMaintenance(opcode);
		m_isMakeUnique = opcode == Req::MakeUnique;

		if (gp) {
			//
			// MakeUnique allocates a line
			//
			assert(m_isMakeUnique);

			this->CopyCHIAttr(*gp);
		} else {
			//
			// Line is already allocated
			//
			this->CopyCHIAttr(l->GetCHIAttr());
		}
	}

	virtual bool HandleRxRsp(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
	{
		bool rspHandled = false;

		if (!m_gotComp &&
			chiattr->GetOpcode() == Rsp::Comp) {

			m_gotComp = true;

			//
			// Cache maintenance ops ignores resp field
			// 4.5.1 [1]
			//
			if (!m_isCacheMaintenance) {
				ParseResp(chiattr);
			}

			if (m_transmitCompAck) {

				//
				// MakeUnique expects store to complete cacheline
				//
				if (IsMakeUnique()) {
					m_l->ByteEnablesDisableAll();

					//
					// Copy the attributes used into the line
					//
					m_l->SetCHIAttr(m_chiattr);
				}

				// Use SrcID as target
				this->SetupCompAck(chiattr, false);
			} else {
				//
				// Transaction completed
				//
				this->m_done.notify();
			}

			rspHandled = true;
		}

		return rspHandled;
	}

	bool TransmitOnTxRspChannel()
	{
		return m_transmitCompAck;
	}

	bool Done()
	{
		if (m_transmitCompAck) {
			bool compAckDone = m_gp.get_response_status() !=
						tlm::TLM_INCOMPLETE_RESPONSE;

			return m_gotComp && compAckDone;
		}
		return m_gotComp;
	}

private:
	bool IsMakeUnique()
	{
		return m_isMakeUnique;
	}

	bool IsCacheMaintenance(uint8_t opcode)
	{
		switch(opcode) {
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

	void ParseResp(chiattr_extension *chiattr)
	{
		switch (chiattr->GetResp()) {
		case Resp::Comp_UC:
			m_l->SetValid(true);
			m_l->SetTag(m_gp.get_address());
			m_l->SetShared(false);
			m_l->SetDirty(false);
			break;
		case Resp::Comp_SC:
			m_l->SetValid(true);
			m_l->SetTag(m_gp.get_address());
			m_l->SetShared(true);
			m_l->SetDirty(false);
			break;
		case Resp::Comp_I:
		default:
			m_l->SetValid(false);
			break;
		}
	}

	bool m_gotComp;
	bool m_transmitCompAck;
	bool m_isCacheMaintenance;
	bool m_isMakeUnique;
};

template<
	int NODE_ID,
	int ICN_ID>
class WriteTxn : public ITxn<NODE_ID, ICN_ID>
{
public:
	typedef ITxn<NODE_ID, ICN_ID> ITxn_t;

	using ITxn_t::m_gp;
	using ITxn_t::m_chiattr;
	using ITxn_t::m_l;
	using ITxn_t::m_isWriteUniqueWithCompAck;

	//
	// Used by NonCopyBack requests
	//
	WriteTxn(tlm::tlm_generic_payload& gp,
			uint8_t opcode,
			TxnIDs *ids,
			uint64_t addr,	// cache aligned
			unsigned int pos,
			unsigned int line_offset) :
		ITxn<NODE_ID, ICN_ID>(opcode, ids, NULL),
		m_gotDBID(false),
		m_gotComp(false),
		m_sentCompAck(true),
		m_opcode(opcode),
		m_datOpcode(GetDatOpcode())
	{
		Init();
		m_gp.set_address(addr);

		if (IsAtomicStore()) {
			// The request uses the correct length
			m_gp.set_data_length(gp.get_data_length());
		}

		this->CopyCHIAttr(gp);

		memset(m_data, 0, sizeof(m_data));
		memset(m_byteEnable, TLM_BYTE_DISABLED, sizeof(m_byteEnable));

		CopyDataNonCached(gp, pos, line_offset);
	}

	void CopyDataNonCached(tlm::tlm_generic_payload& gp,
				unsigned int pos,
				unsigned int line_offset)
	{
		unsigned char *data = gp.get_data_ptr() + pos;
		unsigned int len = gp.get_data_length() - pos;
		unsigned int max_len = CACHELINE_SZ - line_offset;
		unsigned char *be = gp.get_byte_enable_ptr();
		unsigned int be_len = gp.get_byte_enable_length();

		if (len > max_len) {
			len = max_len;
		}

		if (be_len) {
			unsigned int i;

			for (i = 0; i < len; i++, pos++) {
				bool do_access = be[pos % be_len] == TLM_BYTE_ENABLED;

				if (do_access) {
					m_data[line_offset + i] = data[i];
					m_byteEnable[line_offset + i] = TLM_BYTE_ENABLED;
				}
			}
		} else {
			memcpy(&m_data[line_offset], data, len);
			memset(&m_byteEnable[line_offset],
					TLM_BYTE_ENABLED, len);
		}
	}

	//
	// Used by CopyBack requests
	//
	WriteTxn(uint8_t opcode,
			CacheLine *l,
			TxnIDs *ids) :
		ITxn<NODE_ID, ICN_ID>(opcode, ids, l),
		m_gotDBID(false),
		m_gotComp(false),
		m_sentCompAck(true),
		m_opcode(opcode),
		m_datOpcode(GetDatOpcode())
	{
		Init();
	}


	void Init()
	{
		m_gp.set_command(tlm::TLM_IGNORE_COMMAND);

		if (IsCopyBack()) {
			m_gp.set_address(m_l->GetTag());

			//
			// Move over data and byte enables
			//
			memcpy(m_data, m_l->GetData(), CACHELINE_SZ);
			memcpy(m_byteEnable, m_l->GetByteEnables(), CACHELINE_SZ);
		}

		m_gp.set_data_length(CACHELINE_SZ);
		m_gp.set_data_ptr(m_data);

		m_gp.set_byte_enable_ptr(m_byteEnable);
		m_gp.set_byte_enable_length(CACHELINE_SZ);

		m_gp.set_streaming_width(CACHELINE_SZ);

		m_gp.set_dmi_allowed(false);
		m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		//
		// SnpAttr must be set on WriteBack, WriteClean,
		// WriteEvictFull and WriteUnique. It must be unset on
		// WriteNoSnp. See 2.9.6 [1]
		//
		if (IsWriteNoSnpPtl() || IsWriteNoSnpFull()) {
			m_chiattr->SetSnpAttr(false);
		} else {
			m_chiattr->SetSnpAttr(true);
		}

		//
		// Copy line CHI attr for WriteBackFull, WriteBackPtl,
		// WriteCleanFull and WriteEvictFull.
		//
		if (IsCopyBack()) {
			this->CopyCHIAttr(m_l->GetCHIAttr());
		}
	}

	virtual bool HandleRxRsp(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
	{
		bool rspHandled = false;

		if (!m_gotComp &&
			chiattr->GetOpcode() == Rsp::Comp) {

			m_gotComp = true;

			rspHandled = true;

		} else if (!m_gotDBID &&
			chiattr->GetOpcode() == Rsp::DBIDResp) {

			m_gotDBID = true;
			SetupWriteDat(chiattr);

			if (IsCopyBack()) {
				UpdateLineStatus();
			}

			rspHandled = true;
		} else if (!m_gotDBID && !m_gotComp &&
			chiattr->GetOpcode() == Rsp::CompDBIDResp) {

			m_gotComp = true;
			m_gotDBID = true;

			SetupWriteDat(chiattr);

			if (IsCopyBack()) {
				UpdateLineStatus();
			}

			rspHandled = true;
		}

		return rspHandled;
	}

	bool TransmitOnTxDatChannel()
	{
		bool writeDone = m_gp.get_response_status() !=
					tlm::TLM_INCOMPLETE_RESPONSE;

		return m_gotDBID && !writeDone;
	}

	bool TransmitOnTxRspChannel()
	{
		bool writeDone = m_gp.get_response_status() !=
					tlm::TLM_INCOMPLETE_RESPONSE;

		if (!m_sentCompAck && m_gotDBID && writeDone) {
			m_gp.set_command(tlm::TLM_IGNORE_COMMAND);
			m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

			// TgtID, TxnID already setup
			m_chiattr->SetOpcode(Rsp::CompAck);

			m_sentCompAck = true;

			return true;
		}

		return false;
	}

	bool Done()
	{
		bool writeDone = m_gp.get_response_status() !=
					tlm::TLM_INCOMPLETE_RESPONSE;

		return m_sentCompAck && m_gotComp && m_gotDBID && writeDone;
	}

	bool IsWriteNoSnpPtl()
	{
		return m_opcode == Req::WriteNoSnpPtl;
	}

	bool IsWriteNoSnpFull()
	{
		return m_opcode == Req::WriteNoSnpFull;
	}

	bool IsWriteUnique()
	{
		switch(m_opcode) {
		case Req::WriteUniquePtl:
		case Req::WriteUniqueFull:
		case Req::WriteUniquePtlStash:
		case Req::WriteUniqueFullStash:
			return true;
		default:
			return false;
		}
	}

	void SetExpCompAck(bool val)
	{
		//
		// Only WriteUnique is allowed to have ExpCompAck
		// asserted
		//
		if (val) {
			assert(IsWriteUnique());
		}

		m_chiattr->SetExpCompAck(val);
		m_sentCompAck = !val;
		m_isWriteUniqueWithCompAck = val;
	}

private:

	bool IsAtomicStore()
	{
		uint8_t opcode = m_opcode;

		return opcode >= Req::AtomicStore && opcode < Req::AtomicLoad;
	}

	uint8_t GetDatOpcode()
	{
		if (IsAtomicStore()) {
			return Dat::NonCopyBackWrData;
		}

		switch(m_opcode) {
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

	bool IsCopyBack()
	{
		switch(m_opcode) {
		case Req::WriteBackPtl:
		case Req::WriteBackFull:
		case Req::WriteCleanFull:
		case Req::WriteEvictFull:
			return true;
		default:
			break;
		}
		return false;
	}

	bool IsNonCopyBack()
	{
		switch(m_opcode) {
		case Req::WriteNoSnpPtl:
		case Req::WriteNoSnpFull:
		case Req::WriteUniquePtl:
		case Req::WriteUniqueFull:
		case Req::WriteUniquePtlStash:
		case Req::WriteUniqueFullStash:
			return true;
		default:
			return false;
		}
	}

	void SetupWriteDat(chiattr_extension *chiattr)
	{
		m_gp.set_command(tlm::TLM_WRITE_COMMAND);
		// Data flit is of cache size length
		m_gp.set_data_length(CACHELINE_SZ);
		m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		// Writes use SrcID instead HomeNID, 2.6.3 [1]
		m_chiattr->SetTgtID(chiattr->GetSrcID());
		m_chiattr->SetTxnID(chiattr->GetDBID());
		m_chiattr->SetOpcode(m_datOpcode);
		m_chiattr->SetResp(GetResp());
	}

	uint8_t GetResp()
	{
		bool shared;
		bool dirty;

		if (IsNonCopyBack() || IsAtomicStore()) {
			//
			// WriteNoSnp* / WriteUnique* are used without
			// cacheline (so below if does not apply)
			// (4.2.3 [1])
			//
			return Resp::NonCopyBackWrData;
		}

		shared = m_l->GetShared();
		dirty = m_l->GetDirty();

		if (!m_l->IsValid()) {
			//
			// If the line got invalid by a snoop request
			// return CopyBackWrData_I and deassert byte
			// enables, 4.9.1 [1]
			//
			memset(m_byteEnable,
				TLM_BYTE_DISABLED,
				sizeof(m_byteEnable));

			return Resp::CopyBackWrData_I;
		}

		if (shared && dirty) {
			return Resp::CopyBackWrData_SD_PD;
		} else if (shared && !dirty) {
			return Resp::CopyBackWrData_SC;
		} else if (!shared && dirty) {
			return Resp::CopyBackWrData_UD_PD;
		} else { // (!shared && !dirty)
			return Resp::CopyBackWrData_UC;
		}
	}

	void UpdateLineStatus()
	{
		switch(m_opcode) {
		case Req::WriteCleanFull:
			m_l->SetDirty(false);
			break;

		case Req::WriteBackPtl:
		case Req::WriteBackFull:
		case Req::WriteEvictFull:
			m_l->SetValid(false);
			break;

		//
		// Non copy back don't update cache line status
		// 4.2.3 [1]
		//
		default:
			break;
		}
	}

	bool m_gotDBID;
	bool m_gotComp;
	bool m_sentCompAck;

	unsigned int m_opcode;
	unsigned int m_datOpcode;

	// Copy of the line to write back
	uint8_t m_data[CACHELINE_SZ];
	uint8_t m_byteEnable[CACHELINE_SZ];
};

//
// Handles the non store atomics, AtomicStore is handled with a
// WriteTxn
//
template<
	int NODE_ID,
	int ICN_ID>
class AtomicTxn : public ITxn<NODE_ID, ICN_ID>
{
public:
	typedef ITxn<NODE_ID, ICN_ID> ITxn_t;

	using ITxn_t::m_gp;
	using ITxn_t::m_chiattr;

	AtomicTxn(tlm::tlm_generic_payload& gp,
			chiattr_extension *attr,
			TxnIDs *ids) :
		ITxn<NODE_ID, ICN_ID>(attr->GetOpcode(), ids, NULL),
		m_gotDBID(false),
		m_gotCompData(false),
		m_datOpcode(Dat::NonCopyBackWrData),
		m_received(0),
		m_inboundLen(gp.get_data_length())
	{
		unsigned int len = gp.get_data_length();
		uint64_t addr = gp.get_address();

		if (IsAtomicCompare()) {
			//
			// outbound is the double of inbound length so
			// double up
			//
			len = len * 2;
		}

		m_gp.set_command(tlm::TLM_IGNORE_COMMAND);
		m_gp.set_address(addr);

		m_gp.set_data_length(len);
		m_gp.set_data_ptr(m_data);

		m_gp.set_byte_enable_ptr(m_byteEnable);
		m_gp.set_byte_enable_length(CACHELINE_SZ);

		m_gp.set_streaming_width(len);

		m_gp.set_dmi_allowed(false);
		m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		m_chiattr->SetSnpAttr(attr->GetSnpAttr());
		m_chiattr->SetSnoopMe(attr->GetSnoopMe());

		this->CopyCHIAttr(gp);

		memset(m_data, 0, sizeof(m_data));
		memset(m_byteEnable, TLM_BYTE_DISABLED, sizeof(m_byteEnable));

		if (IsAtomicCompare()) {
			//
			// Copy over CompareData + Swapdata
			//
			uint64_t addr = gp.get_address();
			unsigned int offsetCompareData;
			unsigned int offsetSwapData;
			uint8_t *data = attr->GetData();

			offsetCompareData = GetLineOffset(addr);

			//
			// If in the CompareData has been placed in
			// middle of the window place SwapData at the
			// beggining, else in the middle
			//
			if (offsetCompareData % len) {
				offsetSwapData =
					offsetCompareData - m_inboundLen;
			} else {
				offsetSwapData =
					offsetCompareData + m_inboundLen;
			}

			//
			// Place CompareData
			//
			memcpy(&m_data[offsetCompareData],
				&data[0], m_inboundLen);
			memset(&m_byteEnable[offsetCompareData],
				TLM_BYTE_ENABLED, m_inboundLen);

			//
			// Place SwapData
			//
			memcpy(&m_data[offsetSwapData],
				&data[m_inboundLen], m_inboundLen);
			memset(&m_byteEnable[offsetSwapData],
				TLM_BYTE_ENABLED, m_inboundLen);
		} else {
			//
			// Copy over TxnData
			//
			unsigned int offset = GetLineOffset(addr);

			memcpy(&m_data[offset], attr->GetData(), len);
			memset(&m_byteEnable[offset],
				TLM_BYTE_ENABLED, m_inboundLen);
		}
	}

	bool IsAtomicCompare()
	{
		uint8_t opcode = m_chiattr->GetOpcode();

		return opcode == Req::AtomicCompare;
	}

	unsigned int GetLineOffset(uint64_t addr)
	{
		return addr & (CACHELINE_SZ-1);
	}

	virtual bool HandleRxRsp(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
	{
		bool rspHandled = false;

		if (!m_gotDBID &&
			chiattr->GetOpcode() == Rsp::DBIDResp) {

			m_gotDBID = true;
			SetupWriteDat(chiattr);

			rspHandled = true;
		}

		return rspHandled;
	}

	bool TransmitOnTxDatChannel()
	{
		bool writeDone = m_gp.get_response_status() !=
					tlm::TLM_INCOMPLETE_RESPONSE;

		return m_gotDBID && !writeDone;
	}

	virtual bool HandleRxDat(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
	{
		bool datHandled = false;

		if (!m_gotCompData &&
			chiattr->GetOpcode() == Dat::CompData) {

			m_received += CopyDataNonCoherent(gp, chiattr);

			//
			// If all has been received
			//
			if (m_received == m_inboundLen) {
				m_gotCompData = true;
			}

			datHandled = true;
		}

		return datHandled;
	}

	bool Done()
	{
		bool writeDone = m_gp.get_response_status() !=
					tlm::TLM_INCOMPLETE_RESPONSE;

		return m_gotCompData && m_gotDBID && writeDone;
	}

	unsigned int CopyDataNonCoherent(tlm::tlm_generic_payload& gp,
			chiattr_extension *chiattr)
	{
		unsigned char *data = gp.get_data_ptr();
		unsigned int len = gp.get_data_length();
		unsigned int offset = chiattr->GetDataID() * len;
		unsigned char *be = gp.get_byte_enable_ptr();
		unsigned int be_len = gp.get_byte_enable_length();
		unsigned int max_len = CACHELINE_SZ - offset;
		int num_copied = 0;

		assert(len == be_len);

		if (len > max_len) {
			len = max_len;
		}

		if (be_len) {
			unsigned int i;

			for (i = 0; i < len; i++) {
				bool do_access = be[i % be_len] == TLM_BYTE_ENABLED;

				if (do_access) {
					m_data[i] = data[i];
					num_copied++;
				}
			}
		} else {
			memcpy(&m_data[offset], data, len);
			num_copied = len;
		}

		return num_copied;
	}

	// Tag must have been checked before calling this function
	unsigned int ReadLine(tlm::tlm_generic_payload& gp, unsigned int pos)
	{
		unsigned char *data = gp.get_data_ptr() + pos;
		uint64_t addr = gp.get_address() + pos;
		unsigned int len = gp.get_data_length() - pos;
		unsigned int line_offset = GetLineOffset(addr);
		unsigned int max_len = CACHELINE_SZ - line_offset;
		unsigned char *be = gp.get_byte_enable_ptr();
		unsigned int be_len = gp.get_byte_enable_length();

		if (len > max_len) {
			len = max_len;
		}

		if (be_len) {
			unsigned int i;

			for (i = 0; i < len; i++, pos++) {
				bool do_access = be[pos % be_len] == TLM_BYTE_ENABLED;

				if (do_access) {
					data[i] = m_data[line_offset + i];
				}
			}
		} else {
			memcpy(data, &m_data[line_offset], len);
		}

		return len;
	}

private:
	void SetupWriteDat(chiattr_extension *chiattr)
	{
		m_gp.set_command(tlm::TLM_WRITE_COMMAND);
		m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
		m_gp.set_data_length(CACHELINE_SZ);

		// Writes use SrcID instead HomeNID, 2.6.3 [1]
		m_chiattr->SetTgtID(chiattr->GetSrcID());
		m_chiattr->SetTxnID(chiattr->GetDBID());
		m_chiattr->SetOpcode(m_datOpcode);
		m_chiattr->SetResp(Resp::NonCopyBackWrData);
	}

	bool m_gotDBID;
	bool m_gotCompData;

	uint8_t m_datOpcode;

	uint8_t m_data[CACHELINE_SZ];
	uint8_t m_byteEnable[CACHELINE_SZ];

	unsigned int m_received;
	unsigned int m_inboundLen;
};

template<
	int NODE_ID,
	int ICN_ID>
class DVMOpTxn : public ITxn<NODE_ID, ICN_ID>
{
public:
	typedef ITxn<NODE_ID, ICN_ID> ITxn_t;

	using ITxn_t::m_gp;
	using ITxn_t::m_chiattr;

	DVMOpTxn(tlm::tlm_generic_payload& gp,
			chiattr_extension *chiattr,
			TxnIDs *ids) :
		ITxn<NODE_ID, ICN_ID>(Req::DVMOp, ids, NULL),
		m_gotDBID(false),
		m_gotComp(false),
		m_opcode(Req::DVMOp),
		m_datOpcode(Dat::NonCopyBackWrData)
	{
		m_gp.set_command(tlm::TLM_IGNORE_COMMAND);
		m_gp.set_address(gp.get_address());
		m_gp.set_data_length(DVM::DVMOpSize);
		m_gp.set_data_ptr(m_data);
		m_gp.set_byte_enable_ptr(m_byteEnable);
		m_gp.set_byte_enable_length(DVM::DVMOpSize);
		m_gp.set_streaming_width(DVM::DVMOpSize);

		memcpy(m_data, chiattr->GetData(), DVM::DVMOpSize);
		memset(&m_data[DVM::DVMOpSize], 0,
				sizeof(m_data) - DVM::DVMOpSize);

		memset(m_byteEnable, TLM_BYTE_ENABLED, DVM::DVMOpSize);
		memset(&m_byteEnable[DVM::DVMOpSize],
			TLM_BYTE_DISABLED,
			sizeof(m_data) - DVM::DVMOpSize);

		// 8.1.4 [1]
		m_chiattr->SetNonSecure(false);
	}

	virtual bool HandleRxRsp(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
	{
		bool rspHandled = false;

		if (!m_gotComp &&
			chiattr->GetOpcode() == Rsp::Comp) {

			m_gotComp = true;

			rspHandled = true;

		} else if (!m_gotDBID &&
			chiattr->GetOpcode() == Rsp::DBIDResp) {

			m_gotDBID = true;
			SetupWriteDat(chiattr);

			rspHandled = true;
		}

		return rspHandled;
	}

	bool TransmitOnTxDatChannel()
	{
		bool writeDone = m_gp.get_response_status() !=
					tlm::TLM_INCOMPLETE_RESPONSE;

		return m_gotDBID && !writeDone;
	}

	bool Done()
	{
		bool writeDone = m_gp.get_response_status() !=
					tlm::TLM_INCOMPLETE_RESPONSE;

		return m_gotComp && m_gotDBID && writeDone;
	}

private:
	void SetupWriteDat(chiattr_extension *chiattr)
	{
		m_gp.set_command(tlm::TLM_WRITE_COMMAND);
		m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		// Writes use SrcID instead HomeNID, 2.6.3 [1]
		m_chiattr->SetTgtID(chiattr->GetSrcID());
		m_chiattr->SetTxnID(chiattr->GetDBID());
		m_chiattr->SetOpcode(m_datOpcode);
		m_chiattr->SetResp(Resp::NonCopyBackWrData);
	}

	bool m_gotDBID;
	bool m_gotComp;

	unsigned int m_opcode;
	unsigned int m_datOpcode;

	uint8_t m_data[CACHELINE_SZ];
	uint8_t m_byteEnable[CACHELINE_SZ];
};

template<
	int NODE_ID,
	int ICN_ID>
class SnpRespTxn : public ITxn<NODE_ID, ICN_ID>
{
public:
	typedef ITxn<NODE_ID, ICN_ID> ITxn_t;

	using ITxn_t::m_gp;
	using ITxn_t::m_chiattr;
	using ITxn_t::m_l;
	using ITxn_t::m_txnID;
	using ITxn_t::m_ids;

	SnpRespTxn(tlm::tlm_generic_payload& gp) :
		ITxn<NODE_ID, ICN_ID>(Rsp::SnpResp, NULL, NULL, true),
		m_dataToHomeNode(false),
		m_dataToReqNode(false),
		m_gotCompData(true),
		m_transmitCompAck(false),
		m_fwdAttr(new chiattr_extension()),
		m_received(0)
	{
		//
		// Store the snoop req
		//
		m_snpReqGP.deep_copy_from(gp);
		m_snpReqGP.get_extension(m_snpReqAttr);

		assert(m_snpReqAttr);

		//
		// Default init as SnpResp without data
		//
		InitSnpResp();

		//
		// Take over ownership
		//
		m_fwdGP.set_extension(m_fwdAttr);
	}

	void InitSnpResp()
	{
		chiattr_extension *attr = m_snpReqAttr;

		m_gp.set_command(tlm::TLM_IGNORE_COMMAND);

		// This should be taken from the snpReq
		m_gp.set_address(m_snpReqGP.get_address());

		m_gp.set_data_length(CACHELINE_SZ);
		m_gp.set_data_ptr(m_dummy_data);

		m_gp.set_byte_enable_ptr(NULL);
		m_gp.set_byte_enable_length(0);

		m_gp.set_streaming_width(CACHELINE_SZ);

		m_gp.set_dmi_allowed(false);
		m_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		//
		// Always start by Replying the ICN first
		//
		m_chiattr->SetQoS(attr->GetQoS());
		m_chiattr->SetTgtID(attr->GetSrcID());
		m_chiattr->SetSrcID(NODE_ID);
		m_chiattr->SetTxnID(attr->GetTxnID());
	}

	virtual bool HandleRxDat(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
	{
		bool datHandled = false;

		if (m_gotCompData == false &&
			chiattr->GetOpcode() == Dat::CompData) {

			assert(m_l);

			m_received += this->CopyData(gp, chiattr);

			this->ParseReadResp(chiattr);

			if (m_received == CACHELINE_SZ) {
				m_gotCompData = true;
				m_transmitCompAck = true;


				// All done setup CompAck
				this->SetupCompAck(chiattr);
			}

			datHandled = true;
		}

		return datHandled;
	}

	bool TransmitOnTxDatChannel()
	{
		if (m_dataToReqNode) {
			m_gp.deep_copy_from(m_fwdGP);

			m_dataToReqNode = false;

			return true;
		}

		return false;
	}

	//
	// First tx on rsp channel is done directly from the snoop
	// handling functions, so a second tx is only done when
	// transmiting CompAck for stash snoops.
	//
	bool TransmitOnTxRspChannel()
	{
		bool ret = m_transmitCompAck;

		m_transmitCompAck = false;

		return ret;
	}

	bool Done()
	{
		return m_dataToReqNode == false &&
			m_gotCompData == true;
	}

	void SetSnpResp(uint8_t lineState,
			bool passDirty = false)
	{
		m_chiattr->SetOpcode(Rsp::SnpResp);
		m_chiattr->SetResp(GetResp(lineState, passDirty));
	}

	void SetSnpRespData(uint8_t lineState,
				bool passDirty = false)
	{
		m_chiattr->SetOpcode(Dat::SnpRespData);
		m_chiattr->SetResp(GetResp(lineState, passDirty));

		m_dataToHomeNode = true;
	}

	void SetSnpRespDataPtl(uint8_t lineState,
				bool passDirty = false)
	{
		m_chiattr->SetOpcode(Dat::SnpRespDataPtl);
		m_chiattr->SetResp(GetResp(lineState, passDirty));
		m_dataToHomeNode = true;
	}

	void SetSnpRespFwded(uint8_t lineState,
			uint8_t fwdedState,
			bool passDirty = false,
			bool fwdedPassDirty = false)
	{
		m_chiattr->SetOpcode(Rsp::SnpRespFwded);
		m_chiattr->SetResp(GetResp(lineState, passDirty));
		m_chiattr->SetFwdState(GetResp(fwdedState,
						fwdedPassDirty));
	}

	void SetSnpRespDataFwded(uint8_t lineState,
			uint8_t fwdedState,
			bool passDirty = false,
			bool fwdedPassDirty = false)
	{
		m_chiattr->SetOpcode(Dat::SnpRespDataFwded);
		m_chiattr->SetResp(GetResp(lineState, passDirty));
		m_chiattr->SetFwdState(GetResp(fwdedState,
						fwdedPassDirty));
		m_dataToHomeNode = true;
	}

	void SetData(CacheLine *l)
	{
		m_gp.set_command(tlm::TLM_WRITE_COMMAND);
		m_gp.set_data_ptr(l->GetData());
		m_gp.set_byte_enable_ptr(l->GetByteEnables());
		m_gp.set_byte_enable_length(CACHELINE_SZ);
	}

	void SetDataPull(CacheLine *l, bool dataPull)
	{
		m_l = l;
		m_chiattr->SetDataPull(true);
		m_gotCompData = false;
	}

	bool GetDataPull()
	{
		return m_chiattr->GetDataPull();
	}

	void SetupDBID(TxnIDs *ids)
	{
		//
		// Setup ID release on delete
		//
		m_ids = ids;
		m_txnID = ids->GetID();

		m_chiattr->SetDBID(m_txnID);
	}

	bool GetDataToHomeNode()
	{
		return m_dataToHomeNode;
	}

	void SetCompData(CacheLine *l, uint8_t lineState,
				bool passDirty = false)
	{
		m_fwdGP.set_command(tlm::TLM_WRITE_COMMAND);

		m_fwdGP.set_address(m_snpReqGP.get_address());

		m_fwdGP.set_data_ptr(l->GetData());
		m_fwdGP.set_data_length(CACHELINE_SZ);

		m_fwdGP.set_byte_enable_ptr(l->GetByteEnables());
		m_fwdGP.set_byte_enable_length(CACHELINE_SZ);

		m_fwdAttr->SetQoS(m_snpReqAttr->GetQoS());

		m_fwdAttr->SetTgtID(m_snpReqAttr->GetFwdNID());
		m_fwdAttr->SetSrcID(NODE_ID);
		m_fwdAttr->SetTxnID(m_snpReqAttr->GetFwdTxnID());
		m_fwdAttr->SetHomeNID(m_snpReqAttr->GetSrcID());
		m_fwdAttr->SetDBID(m_snpReqAttr->GetTxnID());
		m_fwdAttr->SetOpcode(Dat::CompData);

		m_fwdAttr->SetResp(GetCompDataResp(lineState, passDirty));

		m_dataToReqNode = true;
	}

private:
	// Table 12-36
	uint8_t GetResp(uint8_t lineState, bool passDirty)
	{
		if (passDirty) {
			switch(lineState) {
			case UC:
				return 0x6;
			case SC:
				return 0x5;
			case INV:
			default:
				return 0x4;
			}
		} else {
			switch(lineState) {
			case SD:
				return 0x3;
			case UC:
			case UD:
				return 0x2;
			case SC:
				return 0x1;
			case INV:
			default:
				return 0x0;
			}
		}
	}

	uint8_t GetCompDataResp(uint8_t lineState, bool passDirty)
	{
		if (passDirty) {
			switch(lineState) {
			case UD:
				return 0x6;
			case SD:
				return 0x7;
			case INV:
			default:
				return 0x4;
			}
		} else {
			switch(lineState) {
			case UC:
				return 0x2;
			case SC:
				return 0x1;
			case INV:
			default:
				return 0x0;
			}
		}
	}

	bool m_dataToHomeNode;
	bool m_dataToReqNode;
	bool m_gotCompData;
	bool m_transmitCompAck;

	//
	// Copy of the snoop request transaction
	//
	tlm::tlm_generic_payload m_snpReqGP;
	chiattr_extension *m_snpReqAttr;

	tlm::tlm_generic_payload m_fwdGP;
	chiattr_extension *m_fwdAttr;

	unsigned char m_dummy_data[CACHELINE_SZ];
	unsigned int m_received;
};

} /* namespace RN */
} /* namespace CHI */
} /* namespace AMBA */

#endif /* TLM_MODULES_PRIV_CHI_TXNS_RN_H__ */
