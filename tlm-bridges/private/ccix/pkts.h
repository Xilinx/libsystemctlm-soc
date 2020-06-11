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
 * [1] AMBA CXS Protocol Specification, Issue A, ARM IHI 0079
 * [2] CCIX Base Specification Revision 1.0 Version 1.0
 *
 */

#ifndef TLM_BRIDGES_PRIV_CCIX_PKTS_H__
#define TLM_BRIDGES_PRIV_CCIX_PKTS_H__

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-bridges/ccix.h"
#include "tlm-extensions/ccixattr.h"
#include "utils/bitops.h"

#define GEN_TLP_HDR_FIELD_FUNCS(idx, fname, shift, width) 		\
uint32_t get_ ## fname()						\
{									\
	return (m_hdr[idx] >> shift) & bitops_mask64(0, width);		\
}									\
uint32_t set_ ## fname(uint32_t v) {					\
	uint32_t mask = static_cast<uint32_t>(bitops_mask64(0, width));	\
	assert((v & ~mask) == 0);					\
	return (v & mask) << shift;					\
}

#define GEN_FIELD_FUNCS(fname, shift, width)				\
uint32_t get_ ## fname(uint32_t r)					\
{									\
	return (r >> shift) & bitops_mask64(0, width);			\
} 									\
uint32_t set_ ## fname(uint32_t v) {					\
	uint32_t mask = static_cast<uint32_t>(bitops_mask64(0, width));	\
	assert((v & ~mask) == 0);					\
	return (v & mask) << shift;					\
}


namespace CCIX {

class TLPHdr_opt
{
public:
	enum {
		TLPHdr_Size = 4, // TLP Header bytes

		Type = 0x1,
		TC_CCIX = 0x7,  // CCIX TC
	};

	//
	// Bits [31:0]
	//
	GEN_TLP_HDR_FIELD_FUNCS(0, type, 30, 1);
	GEN_TLP_HDR_FIELD_FUNCS(0, msgCredit, 24, 6);
	GEN_TLP_HDR_FIELD_FUNCS(0, rsvd0, 23, 1);
	GEN_TLP_HDR_FIELD_FUNCS(0, tc, 20, 3);
	GEN_TLP_HDR_FIELD_FUNCS(0, tgtID, 14, 6);
	GEN_TLP_HDR_FIELD_FUNCS(0, srcID, 8, 6);
	GEN_TLP_HDR_FIELD_FUNCS(0, rsvd1, 7, 1);
	GEN_TLP_HDR_FIELD_FUNCS(0, length, 0, 7);

	TLPHdr_opt(tlm::tlm_generic_payload *gp,
			ccixattr_extension *attr,
			uint32_t len)
	{
		m_hdr.push_back(set_type(Type) |
				set_msgCredit(attr->GetMsgCredit()) |

				set_rsvd0(0) |
				set_tc(TC_CCIX) |

				set_tgtID(attr->GetTgtID()) |
				set_srcID(attr->GetSrcID()) |

				set_rsvd1(0) |
				set_length(len));
	}

	TLPHdr_opt(uint8_t *hdr)
	{
		m_hdr.push_back(hdr[0] << 24 |
				hdr[1] << 16 |
				hdr[2] << 8 |
				hdr[3]);
	}

	uint32_t *data() { return m_hdr.data(); }
	uint32_t size() { return m_hdr.size(); }

private:
	std::vector<uint32_t> m_hdr;
};

class TLPHdr_comp
{
public:
	enum {
		TLPHdr_Size = 16, // TLP Header bytes

		Fmt = 0x3,      // b'011
		Type = 0x12,    // b'10010
		TC_CCIX = 0x7,  // CCIX TC
		Attr0 = 0x0,
		TD = 0x0,
		EP = 0x0,
		Attr1 = 0x0,
		AT = 0x0,

		MsgCode = 0x7F, // b'01111111
	};

	//
	// For bits [31:0]
	//
	GEN_TLP_HDR_FIELD_FUNCS(0, fmt, 29, 3);
	GEN_TLP_HDR_FIELD_FUNCS(0, type, 24, 5);
	GEN_TLP_HDR_FIELD_FUNCS(0, rsvd0_0, 23, 1);
	GEN_TLP_HDR_FIELD_FUNCS(0, tc, 20, 3);
	GEN_TLP_HDR_FIELD_FUNCS(0, rsvd0_1, 19, 1);
	GEN_TLP_HDR_FIELD_FUNCS(0, attr0, 17, 2);
	GEN_TLP_HDR_FIELD_FUNCS(0, rsvd0_2, 16, 1);
	GEN_TLP_HDR_FIELD_FUNCS(0, td, 15, 1);
	GEN_TLP_HDR_FIELD_FUNCS(0, ep, 14, 1);
	GEN_TLP_HDR_FIELD_FUNCS(0, attr1, 12, 2);
	GEN_TLP_HDR_FIELD_FUNCS(0, at, 10, 2);
	GEN_TLP_HDR_FIELD_FUNCS(0, length, 0, 10);

	//
	// For bits [63:32]
	//
	GEN_TLP_HDR_FIELD_FUNCS(1, requestorID, 16, 16);
	GEN_TLP_HDR_FIELD_FUNCS(1, rsvd1_0, 8, 8);
	GEN_TLP_HDR_FIELD_FUNCS(1, msgCode, 0, 8);

	//
	// For bits [95:64]
	//
	GEN_TLP_HDR_FIELD_FUNCS(2, busNumber, 24, 8);
	GEN_TLP_HDR_FIELD_FUNCS(2, deviceNumber, 19, 5);
	GEN_TLP_HDR_FIELD_FUNCS(2, funcNumber, 16, 3);
	GEN_TLP_HDR_FIELD_FUNCS(2, vendorID, 0, 16);

	//
	// For bits [127:96]
	//
	GEN_TLP_HDR_FIELD_FUNCS(3, rsvd3_0, 30, 2);
	GEN_TLP_HDR_FIELD_FUNCS(3, msgCredit, 24, 6);
	GEN_TLP_HDR_FIELD_FUNCS(3, rsvd3_1, 20, 4);
	GEN_TLP_HDR_FIELD_FUNCS(3, tgtID, 14, 6);
	GEN_TLP_HDR_FIELD_FUNCS(3, srcID, 8, 6);
	GEN_TLP_HDR_FIELD_FUNCS(3, rsvd3_2, 0, 8);

	TLPHdr_comp(tlm::tlm_generic_payload *gp,
			ccixattr_extension *attr,
			uint32_t len)
	{
		// Bits [31:0]
		m_hdr.push_back(set_fmt(Fmt) |
				set_type(Type) |

				set_rsvd0_0(0) |
				set_tc(TC_CCIX) |

				set_rsvd0_1(0) |
				set_attr0(Attr0) |
				set_rsvd0_2(0) |

				set_td(0) |
				set_ep(0) |
				set_attr1(Attr1) |
				set_at(AT) |
				set_length(len));

		//
		// Bits [63:32]
		//
		m_hdr.push_back(set_requestorID(0) |
				set_rsvd1_0(0) |
				set_msgCode(MsgCode));

		//
		// Bits [95:64]
		//
		m_hdr.push_back(set_busNumber(0) | set_deviceNumber(0) |
				set_funcNumber(0) | set_vendorID(0));

		//
		// Bits [127:96]
		//
		m_hdr.push_back(set_rsvd3_0(0) |
				set_msgCredit(attr->GetMsgCredit()) |
				set_rsvd3_1(0) |
				set_tgtID(attr->GetTgtID()) |
				set_srcID(attr->GetSrcID()) |
				set_rsvd3_2(0));
	}

	TLPHdr_comp(uint8_t *hdr)
	{
		for (unsigned int i = 0; i < TLPHdr_Size; i+=4) {
			uint32_t val = hdr[i] << 24 |
					hdr[i+1] << 16 |
					hdr[i+2] << 8 |
					hdr[i+3];

			m_hdr.push_back(val);
		}
	}

	uint32_t *data() { return m_hdr.data(); }
	uint32_t size() { return m_hdr.size(); }

private:
	std::vector<uint32_t> m_hdr;
};

class IMsg
{
public:
	//
	// Used when generating outgoing TLPs
	//
	IMsg(tlm::tlm_generic_payload *gp) :
		m_gp(gp),
		m_attr(NULL),
		m_delete(false),
		m_pos(0),
		m_idx(0)
	{
		assert(gp);
		gp->get_extension(m_attr);

		assert(m_attr);
	}

	//
	// Used when parsing incoming TLPs
	//
	IMsg(uint8_t *msg, uint8_t defTgTID,
			uint8_t defSrcID, uint8_t msgCredit) :
		m_gp(new tlm::tlm_generic_payload()),
		m_attr(new ccixattr_extension()),
		m_delete(true),
		m_pos(0),
		m_idx(0)
	{
		uint32_t hdr_val = peek_next_uint32(msg);

		memset(m_data, 0, sizeof(m_data));

		m_gp->set_data_ptr(m_data);
		m_gp->set_data_length(CACHELINE_SZ);

		m_gp->set_streaming_width(CACHELINE_SZ);

		m_gp->set_extension(m_attr);

		//
		// Parse MsgType and MsgLen
		//
		m_attr->SetTgtID(defTgTID);
		m_attr->SetSrcID(defSrcID);
		m_attr->SetMsgCredit(msgCredit);
		m_attr->SetMsgType(get_MsgType(hdr_val));
		m_attr->SetMsgLen(get_MsgLen(hdr_val));
	}

	tlm::tlm_generic_payload& GetGP() { return *m_gp; }
	ccixattr_extension* GetCCIXAttr() { return m_attr; }

	virtual ~IMsg()
	{
		if (m_delete) {
			// Also deletes the extension
			delete m_gp;
		}
	}

	uint32_t *data() { return m_hdr.data(); }
	uint32_t size() { return m_hdr.size(); }

	uint32_t GetMsgType() { return m_attr->GetMsgType(); }
	uint32_t GetMsgLen() { return m_attr->GetMsgLen(); }

	bool IsReqChain()
	{
		return m_attr->GetMsgType() == Msg::Type::Req &&
			m_attr->GetReqOp() == Msg::ReqOp::ReqChain;
	}

	bool IsSnpReqChain()
	{
		return m_attr->GetMsgType() == Msg::Type::SnpReq &&
			m_attr->GetSnpOp() == Msg::SnpOp::SnpChain;
	}

protected:

	//
	// Advances m_pos
	//
	void ParseByteEnables(uint8_t *msg, unsigned int n_bytes)
	{
		uint8_t *byteEnables = &msg[m_pos];
		unsigned int i;

		for (i = 0; i < n_bytes; i++) {
			bool enable;
			unsigned int bit = (i % 8);

			//
			// Go to next byte
			//
			if (bit == 0 && i > 0) {
				byteEnables++;
				m_pos++;
			}

			//
			// Check bit
			//
			enable = (byteEnables[0] >> bit) & 1;

			if (enable) {
				m_byteEnable[i] = TLM_BYTE_ENABLED;
			} else {
				m_byteEnable[i] = TLM_BYTE_DISABLED;
			}
		}

		//
		// The data that comes after the byte enables is 4 byte
		// aligned
		//
		for (; m_pos % 4; m_pos++);

		//
		// In case of less than 64 bytes data disable the rest
		//
		for (; i < sizeof(m_byteEnable); i++) {
			m_byteEnable[i] = TLM_BYTE_DISABLED;
		}

		m_gp->set_byte_enable_ptr(m_byteEnable);
		m_gp->set_byte_enable_length(sizeof(m_byteEnable));
	}

	bool IsWrite()
	{
		switch(m_attr->GetReqOp()) {
		case Msg::ReqOp::WriteNoSnpPtl:
		case Msg::ReqOp::WriteNoSnpFull:
		case Msg::ReqOp::WriteUniquePtl:
		case Msg::ReqOp::WriteUniqueFull:
		case Msg::ReqOp::WriteBackPtl:
		case Msg::ReqOp::WriteBackFullUD:
		case Msg::ReqOp::WriteBackFullSD:
		case Msg::ReqOp::WriteCleanFullSD:
		case Msg::ReqOp::WriteEvictFull:
			return true;
		default:
			break;
		}
		return false;
	}

	bool IsAtomic()
	{
		return m_attr->GetReqOp() >= Msg::ReqOp::AtomicStore &&
			m_attr->GetReqOp() <= Msg::ReqOp::AtomicCompareSnpMe;
	}

	unsigned int GetTailSize(uint8_t *msg)
	{
		unsigned int msgLen_bytes = m_attr->GetMsgLen() * 4;

		return msgLen_bytes - m_pos;
	}

	void ParseData(uint8_t* msg, unsigned int dataLen)
	{
		//
		// CCIX Data is always multiple of four bytes see (Req Size
		// field)
		//
		for (unsigned int i = 0; i < dataLen; i+=4) {
			m_data[i + 0] = msg[m_pos++];
			m_data[i + 1] = msg[m_pos++];
			m_data[i + 2] = msg[m_pos++];
			m_data[i + 3] = msg[m_pos++];
		}

		m_gp->set_data_length(dataLen);
		m_gp->set_streaming_width(dataLen);
	}

	//
	// Updates hdr_val
	//
	void ExtractExtensions(uint32_t& hdr_val, uint8_t *msg, bool advance = true)
	{
		while (get_Ext(hdr_val)) {
			hdr_val = get_next_uint32(msg);

			ExtractExtension(hdr_val);
		}

		if (advance) {
			hdr_val = get_next_uint32(msg);
		}
	}

	void PlaceBE()
	{
		unsigned char *be = m_gp->get_byte_enable_ptr();
		int be_len = m_gp->get_byte_enable_length();
		unsigned int len = m_gp->get_data_length();

		if (be && be_len) {
			unsigned int bepos = 0;

			while (bepos < len) {
				uint32_t BE_u32 = 0;

				//
				// Create uint32_t value as according section
				// 3.5.4.5 [2]
				//
				for (int byte = 3; byte >= 0; byte--) {
					uint8_t val = 0;
					unsigned shift = byte * 8;

					//
					// Create byte value as according
					// section 3.5.4.5 [2]
					//
					for (int bit = 0; bit < 8 && bepos < len;
						bit++, bepos++) {

						uint8_t b = be[bepos % be_len];

						if (b == TLM_BYTE_ENABLED) {
							val |= (1 << bit);
						}
					}

					//
					// Place byte into u32
					//
					BE_u32 |= val << shift;
				}

				m_hdr.push_back(BE_u32);
			}
		} else {
			//
			// Enable all bytes
			//
			unsigned int bepos = 0;

			while (bepos < len) {
				uint32_t BE_u32 = 0;

				//
				// Create uint32_t value as according 3.5.4.5
				// [2]
				//
				for (int byte = 3; byte >= 0; byte--) {
					uint8_t val = 0;
					unsigned shift = byte * 8;

					//
					// Create byte value as according
					// 3.5.4.5 [2]
					//
					// Enable 8 bytes at a time
					//
					val = 0xFF;

					//
					// Place byte into u32
					//
					BE_u32 |= val << shift;

					bepos += 8;
					if (bepos == len) {
						break;
					}
				}

				m_hdr.push_back(BE_u32);
			}
		}
	}

	void PlaceData()
	{
		uint8_t *data = m_gp->get_data_ptr();
		unsigned int len = m_gp->get_data_length();

		while (len) {
			uint32_t data_u32 = 0;

			//
			// Move over 4 bytes (or the ones that are left)
			//
			for (int byte = 3; byte >= 0; byte--) {
				unsigned shift = byte * 8;

				data_u32 |= data[0] << shift;

				data++;
			}

			m_hdr.push_back(data_u32);
			len -= 4;
		}
	}

	GEN_FIELD_FUNCS(Ext, 31, 1);
	GEN_FIELD_FUNCS(MsgType, 27, 4);
	GEN_FIELD_FUNCS(MsgLen, 22, 5);

	GEN_FIELD_FUNCS(ExtType, 28, 3);

	// Ext 0
	GEN_FIELD_FUNCS(Address_63_60, 20, 4);
	GEN_FIELD_FUNCS(Ext0TgtID, 14, 6);
	GEN_FIELD_FUNCS(Ext0SrcID, 8, 6);
	GEN_FIELD_FUNCS(Address_59_52, 0, 8);

	// Ext 1
	GEN_FIELD_FUNCS(Address_5_0, 0, 6);

	// Ext 2
	GEN_FIELD_FUNCS(User, 0, 28);

	// Ext 7
	GEN_FIELD_FUNCS(RespErr, 24, 2);
	GEN_FIELD_FUNCS(Poison0, 8, 8);
	GEN_FIELD_FUNCS(Poison1, 0, 8);

	void ExtractExtension(uint32_t ext)
	{
		switch (get_ExtType(ext)) {
		case Msg::Ext::Type_0:
		{
			uint64_t addr = m_gp->get_address();

			addr |= static_cast<uint64_t>(get_Address_63_60(ext)) << 60;
			addr |= static_cast<uint64_t>(get_Address_59_52(ext)) << 52;

			m_gp->set_address(addr);

			//
			// The extension SrcID and TgtID overried the default
			// 3.11.9.1 [2]
			//
			m_attr->SetTgtID(get_Ext0TgtID(ext));
			m_attr->SetSrcID(get_Ext0SrcID(ext));

			break;
		}
		case Msg::Ext::Type_1:
		{
			uint64_t addr = m_gp->get_address();

			addr |= get_Address_5_0(ext);

			m_gp->set_address(addr);

			break;
		}
		case Msg::Ext::Type_2:
			m_attr->SetUser(get_User(ext));

			break;
		case Msg::Ext::Type_6:
			m_attr->SetRespErr(get_RespErr(ext));
			m_attr->SetPoison0(get_Poison0(ext));
			m_attr->SetPoison1(get_Poison0(ext));

			break;
		default:
			break;
		}
	}

	//
	// Updates m_pos
	//
	uint32_t get_next_uint32(uint8_t *msg)
	{
		uint32_t val = (msg[m_pos] << 24) |
				(msg[m_pos + 1] << 16) |
				(msg[m_pos + 2] << 8) |
				(msg[m_pos + 3] << 0);

		m_pos += 4;

		return val;
	}

	uint32_t peek_next_uint32(uint8_t *msg)
	{
		return (msg[m_pos] << 24) |
			(msg[m_pos + 1] << 16) |
			(msg[m_pos + 2] << 8) |
			(msg[m_pos + 3] << 0);
	}

	tlm::tlm_generic_payload *m_gp;
	ccixattr_extension *m_attr;
	bool m_delete;

	unsigned int m_pos;
	std::vector<uint32_t> m_hdr;
	uint32_t m_idx;

	uint8_t m_data[CACHELINE_SZ];
	uint8_t m_byteEnable[CACHELINE_SZ];
};

class MsgReq :
	public IMsg
{
public:
	// First 32 bits
	GEN_FIELD_FUNCS(TxnID, 10, 12);
	GEN_FIELD_FUNCS(rsvd0_0, 8, 2);
	GEN_FIELD_FUNCS(ReqOp, 0, 8);

	// Next 32 bits (after optional extensions)
	GEN_FIELD_FUNCS(ReqAttr, 24, 8);
	GEN_FIELD_FUNCS(rsvd2_0, 20, 4);
	GEN_FIELD_FUNCS(Address_51_32, 0, 20);

	// Final header 32 bits
	GEN_FIELD_FUNCS(Address_31_6, 6, 26);
	GEN_FIELD_FUNCS(rsvd3_0, 5, 1);
	GEN_FIELD_FUNCS(NS, 4, 1);
	GEN_FIELD_FUNCS(QoS, 0, 4);

	//
	// Used when generating outgoing messages
	//
	MsgReq(tlm::tlm_generic_payload *gp) :
		IMsg(gp)
	{
		uint64_t addr = gp->get_address();
		bool ExtType0_required = get_Address_63_60(addr >> 32) ||
					get_Address_59_52(addr >> 32);
		bool ExtType1_required = get_Address_5_0(addr);
		uint32_t ext_val =
			(ExtType0_required || ExtType1_required) ? 1 : 0;

		m_hdr.push_back(set_Ext(ext_val) |
				set_MsgType(m_attr->GetMsgType()) |
				set_MsgLen(0) |
				set_TxnID(m_attr->GetTxnID()) |
				set_rsvd0_0(0) |
				set_ReqOp(m_attr->GetReqOp()));

		//
		// ExtType0 for Address bits 63:60 and bits 59::52
		//
		if (ExtType0_required) {
			m_hdr.push_back(set_Ext(ExtType1_required) |
					set_ExtType(Msg::Ext::Type_0) |
					set_Address_63_60(addr >> 32) |
					set_Address_59_52(addr >> 32));
		}

		//
		// ExtType1 for Address bits 5_0
		//
		if (ExtType1_required) {
			uint32_t mask = static_cast<uint32_t>(bitops_mask64(0, 6));
			assert(ExtType1Allowed());

			m_hdr.push_back(set_ExtType(Msg::Ext::Type_1) |
					set_Address_5_0(addr & mask));
		}

		m_hdr.push_back(set_ReqAttr(m_attr->GetReqAttr()) |
				set_rsvd2_0(0) |
				set_Address_51_32(addr >> 32));

		m_hdr.push_back(set_Address_31_6(addr >> 6) |
				set_rsvd3_0(0) |
				set_NS(m_attr->GetNonSecure()) |
				set_QoS(m_attr->GetQoS()));

		//
		// Is write or is atomic carrying data?
		//
		if (gp->is_write()) {
			if (HasByteEnables()) {
				PlaceBE();
			}
			PlaceData();
		}

		// Set MsgLen
		m_hdr[0] = m_hdr[0] | set_MsgLen(m_hdr.size());
	}

	//
	// Used when parsing incoming messages
	//
	MsgReq(uint8_t *msg, uint8_t defTgtID,
			uint8_t defSrcID, uint8_t msgCredit) :
		IMsg(msg, defTgtID, defSrcID, msgCredit)
	{
		ExtractMessage(msg);
	}

private:

	//
	// Only below reqOps allowed to have ExtType1 (see 3.5.1 [2])
	//
	bool ExtType1Allowed()
	{
		uint8_t ccixOp = m_attr->GetReqOp();
		bool isAtomic;

		switch (ccixOp) {
		case Msg::ReqOp::ReadNoSnp:
		case Msg::ReqOp::WriteNoSnpPtl:
		case Msg::ReqOp::WriteUniquePtl:
			return true;
		default:
			break;
		}

		//
		// Atomics are allowed to have ExtType1
		//
		isAtomic = ccixOp >= Msg::ReqOp::AtomicStore &&
				ccixOp <= Msg::ReqOp::AtomicCompareSnpMe;

		return isAtomic;
	}

	void ExtractMessage(uint8_t *msg)
	{
		uint32_t hdr_val = get_next_uint32(msg);
		unsigned int dataLen;
		uint64_t addr;

		m_attr->SetTxnID(get_TxnID(hdr_val));
		m_attr->SetReqOp(get_ReqOp(hdr_val));

		// Advances hdr
		ExtractExtensions(hdr_val, msg);

		//
		// Chained requests don't contain below bytes
		//
		if (!IsReqChain()) {
			m_attr->SetReqAttr(get_ReqAttr(hdr_val));
			addr = m_gp->get_address();
			addr |= static_cast<uint64_t>(get_Address_51_32(hdr_val)) << 32;
			hdr_val = get_next_uint32(msg);

			addr |= static_cast<uint64_t>(get_Address_31_6(hdr_val)) << 6;
			m_attr->SetNonSecure(get_NS(hdr_val));
			m_attr->SetQoS(get_QoS(hdr_val));
			m_gp->set_address(addr);
		}

		//
		// Handle byte enables
		//
		if (HasByteEnables() ||
			(IsReqChain() && GetTailSize(msg) > CACHELINE_SZ)) {
			unsigned int be_len =
				IsReqChain() ? CACHELINE_SZ : get_size();

			//
			// Advances hdr
			//
			ParseByteEnables(msg, be_len);
		}

		dataLen = GetTailSize(msg);
		if (dataLen > 0) {
			//
			// Only CCIX Write Reqs, chained writes and Atomics
			// carry data
			//
			assert(IsWrite() || IsAtomic() || IsReqChain());

			ParseData(msg, dataLen);

			// Contains data
			m_gp->set_command(tlm::TLM_WRITE_COMMAND);
		}
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
		switch(m_attr->GetReqOp()) {
		case Msg::ReqOp::WriteNoSnpPtl:
		case Msg::ReqOp::WriteUniquePtl:
		case Msg::ReqOp::WriteBackPtl:
			return true;
		default:
			break;
		}
		return false;
	}

	bool IsReqChain()
	{
		return m_attr->GetReqOp() == Msg::ReqOp::ReqChain;
	}

	//
	// ReqAttr fields
	//
	GEN_FIELD_FUNCS(ReqAttrSize, 4, 3);
	GEN_FIELD_FUNCS(ReqAttrMemoryType, 0, 4);

	//
	// Size in bytes
	//
	unsigned int get_size()
	{
		switch (get_ReqAttrSize(m_attr->GetReqAttr())) {
		case 7:
			SC_REPORT_ERROR("CCIXMsgReq",
				"ReqAttr size 128 not suporrted");
			return 128;
		case 6:
			return 64;
		case 5:
			return 32;
		case 4:
			return 16;
		default:
			break;
		}

		//
		// For all other sizes the msg carries 8 bytes
		//
		return 8;
	}
};

class MsgRsp :
	public IMsg
{
public:
	GEN_FIELD_FUNCS(TxnID, 10, 12);
	GEN_FIELD_FUNCS(rsvd0_0, 7, 3);
	GEN_FIELD_FUNCS(RespAttr, 4, 3);
	GEN_FIELD_FUNCS(rsvd0_1, 3, 1);
	GEN_FIELD_FUNCS(RespOp, 0, 3);

	//
	// Used when generating outgoing messages
	//
	MsgRsp(tlm::tlm_generic_payload *gp) :
		IMsg(gp)
	{
		m_hdr.push_back(set_Ext(0) |
				set_MsgType(m_attr->GetMsgType()) |
				set_MsgLen(0) |
				set_TxnID(m_attr->GetTxnID()) |
				set_rsvd0_0(0) |
				set_RespAttr(m_attr->GetRespAttr()) |
				set_rsvd0_1(0) |
				set_RespOp(m_attr->GetRespOp()));

		if (gp->is_write()) {
			//
			// Only SnpRespDataPtl contains byte enables 3.11.2 [2]
			//
			if (IsSnpRespDataPtl()) {
				PlaceBE();
			}
			PlaceData();
		}

		// Set MsgLen
		m_hdr[0] = m_hdr[0] | set_MsgLen(m_hdr.size());
	}

	//
	// Used when parsing incoming messages
	//
	MsgRsp(uint8_t *msg, uint8_t defTgtID,
			uint8_t defSrcID, uint8_t msgCredit) :
		IMsg(msg, defTgtID, defSrcID, msgCredit)
	{
		ExtractMessage(msg);
	}

private:
	enum {
		RespOp_SnpRespDataPtl_UD = 0x2,
		RespOp_SnpRespDataPtl_I_PD = 0x3,
	};

	bool IsSnpRespDataPtl()
	{
		if (m_attr->GetMsgType() != Msg::Type::SnpResp) {
			return false;
		}

		return m_attr->GetRespOp() == RespOp_SnpRespDataPtl_UD ||
			m_attr->GetRespOp() == RespOp_SnpRespDataPtl_I_PD;
	}

	void ExtractMessage(uint8_t *msg)
	{
		uint32_t hdr_val = get_next_uint32(msg);
		unsigned int dataLen;

		m_attr->SetTxnID(get_TxnID(hdr_val));
		m_attr->SetRespAttr(get_RespAttr(hdr_val));
		m_attr->SetRespOp(get_RespOp(hdr_val));

		//
		// Don't advances hdr in case of no extensions
		//
		ExtractExtensions(hdr_val, msg, false);

		//
		// Byte enables are only included for SnpRespDataPtl and
		// SnpRespDataPtl and those transactions always return
		// CACHELINE_SZ data (16.4 [2])
		//
		// If the tail then is larger than CACHELINE_SZ it means this
		// is a SnpRespDataPtl and contains byte enables.
		//
		dataLen = GetTailSize(msg);
		if (dataLen > CACHELINE_SZ) {
			//
			// Advances hdr
			//
			ParseByteEnables(msg, CACHELINE_SZ);
		}

		dataLen = GetTailSize(msg);
		if (dataLen > 0) {
			ParseData(msg, dataLen);

			//
			// Mark as write (response with data), it will then be
			// parsed as a CompData response
			//
			m_gp->set_command(tlm::TLM_WRITE_COMMAND);
		}
	}
};

class MsgSnpReq :
	public IMsg
{
public:
	// First 32 bits
	GEN_FIELD_FUNCS(TxnID, 10, 12);
	GEN_FIELD_FUNCS(rsvd0_0, 7, 3);
	GEN_FIELD_FUNCS(SnpCast, 5, 2);
	GEN_FIELD_FUNCS(DR, 4, 1);
	GEN_FIELD_FUNCS(SnpOp, 0, 4);

	// Next 32 bits (after optional extensions)
	GEN_FIELD_FUNCS(rsvd2_0, 20, 12);
	GEN_FIELD_FUNCS(Address_51_32, 0, 20);

	// Final header 32 bits
	GEN_FIELD_FUNCS(Address_31_6, 6, 26);
	GEN_FIELD_FUNCS(rsvd3_0, 5, 1);
	GEN_FIELD_FUNCS(NS, 4, 1);
	GEN_FIELD_FUNCS(rsvd3_1, 0, 4);

	//
	// Used when generating outgoing messages
	//
	MsgSnpReq(tlm::tlm_generic_payload *gp) :
		IMsg(gp)
	{
		uint64_t addr = gp->get_address();
		bool ExtType0_required = get_Address_63_60(addr >> 32) ||
					get_Address_59_52(addr >> 32);

		m_hdr.push_back(set_Ext(ExtType0_required) |
				set_MsgType(m_attr->GetMsgType()) |
				set_MsgLen(0) |
				set_TxnID(m_attr->GetTxnID()) |
				set_rsvd0_0(0) |
				set_SnpCast(m_attr->GetSnpCast()) |
				set_DR(m_attr->GetDataRet()) |
				set_SnpOp(m_attr->GetSnpOp()));

		// ExtType0 for Address bits 63:60 and bits 59::52
		//
		if (ExtType0_required) {
			m_hdr.push_back(set_ExtType(Msg::Ext::Type_0) |
					set_Address_63_60(addr >> 32) |
					set_Address_59_52(addr >> 32));
		}

		//
		// ExtType1 is not allowed for snoop reques(see 3.11.9 [2])
		//
		assert(get_Address_5_0(addr) == 0);

		m_hdr.push_back(set_rsvd2_0(0) |
				set_Address_51_32(addr >> 32));

		m_hdr.push_back(set_Address_31_6(addr >> 6) |
				set_rsvd3_0(0) |
				set_NS(m_attr->GetNonSecure()) |
				set_rsvd3_1(0));

		// Set MsgLen
		m_hdr[0] = m_hdr[0] | set_MsgLen(m_hdr.size());
	}

	//
	// Used when parsing incoming messages
	//
	MsgSnpReq(uint8_t *msg, uint8_t defTgtID,
			uint8_t defSrcID, uint8_t msgCredit) :
		IMsg(msg, defTgtID, defSrcID, msgCredit)
	{
		ExtractMessage(msg);
	}

private:
	void ExtractMessage(uint8_t *msg)
	{
		uint32_t hdr_val = get_next_uint32(msg);
		uint64_t addr;

		m_attr->SetTxnID(get_TxnID(hdr_val));
		m_attr->SetDataRet(get_DR(hdr_val));
		m_attr->SetSnpOp(get_SnpOp(hdr_val));

		// Advances hdr
		ExtractExtensions(hdr_val, msg);

		//
		// Chained snoop requests don't contain below bytes
		//
		if (!IsSnpReqChain()) {
			addr = m_gp->get_address();
			addr |= static_cast<uint64_t>(get_Address_51_32(hdr_val)) << 32;
			hdr_val = get_next_uint32(msg);;

			addr |= static_cast<uint64_t>(get_Address_31_6(hdr_val)) << 6;
			m_attr->SetNonSecure(get_NS(hdr_val));

			m_gp->set_address(addr);
		}
	}
};

class MsgCrdEx :
	public IMsg
{
public:
	// First 32 bits
	GEN_FIELD_FUNCS(rsvd0_0, 19, 3);
	GEN_FIELD_FUNCS(MiscOp, 16, 4);
	GEN_FIELD_FUNCS(DataCredit, 8, 8);
	GEN_FIELD_FUNCS(ReqCredit, 0, 8);

	// Final header 32 bits
	GEN_FIELD_FUNCS(rsvd1_0, 16, 16);
	GEN_FIELD_FUNCS(MiscCredit, 8, 8);
	GEN_FIELD_FUNCS(SnpCredit, 0, 8);

	//
	// Used when generating outgoing messages
	//
	MsgCrdEx(tlm::tlm_generic_payload *gp) :
		IMsg(gp)
	{

		m_hdr.push_back(set_Ext(0) |
				set_MsgType(m_attr->GetMsgType()) |
				set_MsgLen(0) |
				set_rsvd0_0(0) |
				set_MiscOp(m_attr->GetMiscOp()) |
				set_DataCredit(m_attr->GetDataCredit()) |
				set_ReqCredit(m_attr->GetReqCredit()));

		m_hdr.push_back(set_rsvd1_0(0) |
				set_MiscCredit(m_attr->GetMiscCredit()) |
				set_SnpCredit(m_attr->GetSnpCredit()));

		// Set MsgLen
		m_hdr[0] = m_hdr[0] | set_MsgLen(m_hdr.size());
	}

	//
	// Used when parsing incoming messages
	//
	MsgCrdEx(uint8_t *msg, uint8_t defTgtID,
			uint8_t defSrcID, uint8_t msgCredit) :
		IMsg(msg, defTgtID, defSrcID, msgCredit)
	{
		ExtractMessage(msg);
	}

private:
	void ExtractMessage(uint8_t *msg)
	{
		uint32_t hdr_val = get_next_uint32(msg);

		m_attr->SetMiscOp(get_MiscOp(hdr_val));
		m_attr->SetDataCredit(get_DataCredit(hdr_val));
		m_attr->SetReqCredit(get_ReqCredit(hdr_val));
		hdr_val = get_next_uint32(msg);

		// Misc Messages are not allowed to have extensions, 13.4 [2]

		m_attr->SetMiscCredit(get_MiscCredit(hdr_val));
		m_attr->SetSnpCredit(get_SnpCredit(hdr_val));
	}
};

class MsgNOP :
	public IMsg
{
public:
	GEN_FIELD_FUNCS(rsvd0_0, 19, 3);
	GEN_FIELD_FUNCS(MiscOp, 16, 4);
	GEN_FIELD_FUNCS(rsvd0_1, 0, 16);

	//
	// Used when generating outgoing messages
	//
	MsgNOP(tlm::tlm_generic_payload *gp) :
		IMsg(gp)
	{
		m_hdr.push_back(set_Ext(0) |
				set_MsgType(m_attr->GetMsgType()) |
				set_MsgLen(0) |
				set_rsvd0_0(0) |
				set_MiscOp(m_attr->GetMiscOp()) |
				set_rsvd0_1(0));

		// Set MsgLen
		m_hdr[0] = m_hdr[0] | set_MsgLen(m_hdr.size());
	}

	//
	// Used when parsing incoming messages
	//
	MsgNOP(uint8_t *msg, uint8_t defTgtID,
			uint8_t defSrcID, uint8_t msgCredit) :
		IMsg(msg, defTgtID, defSrcID, msgCredit)
	{
		ExtractMessage(msg);
	}

private:
	void ExtractMessage(uint8_t *msg)
	{
		uint32_t hdr_val = get_next_uint32(msg);

		m_attr->SetMiscOp(get_MiscOp(hdr_val));

		// Misc Messages are not allowed to have extensions, 13.4 [2]
	}
};

class MsgMiscCredited :
	public IMsg
{
public:
	GEN_FIELD_FUNCS(MiscCredit, 19, 3);
	GEN_FIELD_FUNCS(MiscOp, 16, 4);
	GEN_FIELD_FUNCS(payload0, 8, 8);
	GEN_FIELD_FUNCS(payload1, 0, 8);

	//
	// Used when generating outgoing messages
	//
	MsgMiscCredited(tlm::tlm_generic_payload *gp) :
		IMsg(gp)
	{
		uint32_t val;

		val = set_Ext(0) |
			set_MsgType(m_attr->GetMsgType()) |
			set_MsgLen(0) |
			set_MiscCredit(m_attr->GetMiscCredit()) |
			set_MiscOp(m_attr->GetMiscOp());

		//
		// Create the first 2 bytes of payload
		//
		if (m_attr->GetPayloadSz() > 0) {
			uint8_t *d  = m_attr->GetPayload();

			val |= (d[0] << 8 | d[1]);
		}

		m_hdr.push_back(val);

		//
		// Create the last portion of payload
		//
		if (m_attr->GetPayloadSz() > 2) {
			PlacePayload();
		}

		// Set MsgLen
		m_hdr[0] = m_hdr[0] | set_MsgLen(m_hdr.size());
	}

	//
	// Used when parsing incoming messages
	//
	MsgMiscCredited(uint8_t *msg, uint8_t defTgtID,
			uint8_t defSrcID, uint8_t msgCredit) :
		IMsg(msg, defTgtID, defSrcID, msgCredit)
	{
		ExtractMessage(msg);
	}

private:
	void ExtractMessage(uint8_t *msg)
	{
		uint32_t hdr_val = get_next_uint32(msg);
		uint8_t *payload = m_attr->GetPayload();
		unsigned int payloadSz;

		m_attr->SetMiscCredit(get_MiscCredit(hdr_val));
		m_attr->SetMiscOp(get_MiscOp(hdr_val));
		payload[0] = get_payload0(hdr_val);
		payload[1] = get_payload1(hdr_val);

		// Misc Messages are not allowed to have extensions, 13.4 [2]

		//
		// Copy last portion of payload if there
		//
		payloadSz = GetTailSize(msg);
		if (payloadSz > 0) {
			//
			// First 2 bytes were copied above
			//
			memcpy(reinterpret_cast<void*>(&payload[2]),
				reinterpret_cast<void*>(&msg[m_pos]),
				payloadSz);
		}
	}

	void PlacePayload()
	{
		//
		// First two bytes are already placed above
		//
		unsigned int len = m_attr->GetPayloadSz() - 2;
		uint8_t *data = m_attr->GetPayload() + 2;

		while (len) {
			uint32_t data_u32 = 0;

			//
			// Move over 4 bytes (or the ones that are left)
			//
			for (int i = 3; i >= 0; i--) {
				unsigned shift = i * 8;

				data_u32 |= data[0] << shift;

				data++;
				len--;

				if (len == 0) {
					break;
				}
			}

			m_hdr.push_back(data_u32);
		}
	}
};

template<typename T>
class CXSCntl
{
public:
	enum {
		NumStartBits = T::MAX_PKT_PER_FLIT,
		NumEndErrorBits = T::MAX_PKT_PER_FLIT,
		NumEndBits = T::MAX_PKT_PER_FLIT,

		StartPtr_Width = T::START_PTR_WIDTH,
		EndPtr_Width = T::END_PTR_WIDTH,

		StartPtr_Mask = (1 << StartPtr_Width) - 1,
		EndPtr_Mask = (1 << EndPtr_Width) - 1,

		//
		// Endbits bit position
		//
		EndBits_Shift = NumStartBits +
				(NumStartBits * StartPtr_Width),

		//
		// EndPtrs bit position
		//
		EndPtrs_Shift = EndBits_Shift +
				NumEndBits +
				NumEndErrorBits,

		//
		// StartPtr and EndPtr alignment (see 4.2.1 [1])
		//
		Align_128 = 128,
		Align_32 = 32,
	};

	CXSCntl(uint64_t cntl = 0)
	{
		ParseCntl(cntl);
	}

	void AddStartPtr(unsigned int flit_pos)
	{
		unsigned int startPtr = flit_pos / Align_128;

		m_startPtrs.push_back(startPtr);
	}

	void AddEndPtr(unsigned int flit_pos)
	{
		unsigned int endPtr = flit_pos / Align_32;

		m_endPtrs.push_back(endPtr);
	}

	uint64_t to_uint64()
	{
		uint64_t cntl = 0;

		//
		// Add StartBits and StartPtrs
		//
		for (unsigned int i = 0; i < m_startPtrs.size(); i++) {
			unsigned int ptr_shift =
					NumStartBits + i * StartPtr_Width;

			//
			// Startbit
			//
			cntl |= 1 << i;

			//
			// StartPtr
			//
			cntl |= ((m_startPtrs[i] & StartPtr_Mask) << ptr_shift);
		}

		//
		// Add EndBits and EndPtrs
		//
		for (unsigned int i = 0; i < m_endPtrs.size(); i++) {
			unsigned int ptr_shift =
					EndPtrs_Shift + i * EndPtr_Width;

			//
			// EndBit
			//
			cntl |= 1 << (EndBits_Shift + i);

			//
			// StartPtr
			//
			cntl |= ((m_endPtrs[i] & EndPtr_Mask) << ptr_shift);
		}

		return cntl;
	}

	std::vector<unsigned int>& GetStartPtrs()
	{
		return m_startPtrs;
	}

	std::vector<unsigned int>& GetEndPtrs()
	{
		return m_endPtrs;
	}

private:
	void ParseCntl(uint64_t cntl)
	{
		//
		// Parse StartBits and StartPtrs
		//
		for (int i = 0; i < NumStartBits; i++) {
			if ((cntl >> i) & 1) {
				unsigned int ptr_shift = NumStartBits +
							(i * StartPtr_Width);
				unsigned int ptr;

				ptr = (cntl >> ptr_shift) & StartPtr_Mask;

				m_startPtrs.push_back(ptr);
			}
		}

		//
		// Parse EndBits and EndPtrs
		//
		for (int i = 0; i < NumEndBits; i++) {
			unsigned int endBit_Shift = EndBits_Shift + i;

			if ((cntl >> endBit_Shift) & 1) {
				unsigned int ptr_shift = EndPtrs_Shift +
							(i * EndPtr_Width);
				unsigned int ptr;

				ptr = (cntl >> ptr_shift) & EndPtr_Mask;

				m_endPtrs.push_back(ptr);
			}
		}
	}

	std::vector<unsigned int> m_startPtrs;
	std::vector<unsigned int> m_endPtrs;
};

template<typename T>
class TLP
{
public:
	typedef typename T::CXSCntl_t CXSCntl_t;
	typedef typename T::TLPHdr_t TLPHdr_t;

	enum {
		FLIT_WIDTH = T::FLIT_WIDTH,
		CNTL_WIDTH = T::CNTL_WIDTH,
	};

	TLP(IMsg *msg) :
		m_gp(&msg->GetGP()),
		m_attr(msg->GetCCIXAttr()),
		m_pos(0),
		m_tlpDone(false)
	{
		assert(m_gp);
		assert(m_attr);

		PushBack_TLP_hdr(msg->size());

		PushBack(*msg);
	}

	void PushBack_TLP_hdr(uint32_t len)
	{
		TLPHdr_t hdr(m_gp, m_attr, len);

		PushBack(hdr);
	}

	virtual ~TLP()
	{}

	void CreateFlit(sc_out<sc_bv<FLIT_WIDTH> >& flit,
				int flit_pos,
				CXSCntl_t& cntl)
	{
		sc_bv<FLIT_WIDTH> tmpFlit = flit.read();

		//
		// Start of new TLPs be 16 byte aligned (128 bit), see 4.2 [1]
		//
		if (m_pos == 0) {
			for (; flit_pos < tmpFlit.length() && flit_pos % 128;
				flit_pos += 8) {
				unsigned int firstbit = flit_pos;
				unsigned int lastbit = firstbit + 8 - 1;

				tmpFlit.range(lastbit, firstbit) = 0;
			}
		}

		//
		// Fill the flit data and cntl
		//
		for (; flit_pos < tmpFlit.length() && !Done(); flit_pos += 8) {
			unsigned int firstbit = flit_pos;
			unsigned int lastbit = firstbit + 8 - 1;

			bool mark_end = Mark_EndPtr();

			assert(m_pos < m_tlp.size());

			if (m_pos == 0) {
				cntl.AddStartPtr(flit_pos);
			}

			tmpFlit.range(lastbit, firstbit) = get_tlp_byte();

			if (mark_end) {
				cntl.AddEndPtr(flit_pos);
			}
		}

		flit = tmpFlit;
	}

	void CreateFlit(sc_bv<FLIT_WIDTH>& flit,
				int flit_pos,
				CXSCntl_t& cntl)
	{
		sc_bv<FLIT_WIDTH> tmpFlit = flit;

		//
		// Start of new TLPs be 16 byte aligned (128 bit), see 4.2 [1]
		//
		if (m_pos == 0) {
			for (; flit_pos < tmpFlit.length() && flit_pos % 128;
				flit_pos += 8) {
				unsigned int firstbit = flit_pos;
				unsigned int lastbit = firstbit + 8 - 1;

				tmpFlit.range(lastbit, firstbit) = 0;
			}
		}

		//
		// Fill the flit data and cntl
		//
		for (; flit_pos < tmpFlit.length() && !Done(); flit_pos += 8) {
			unsigned int firstbit = flit_pos;
			unsigned int lastbit = firstbit + 8 - 1;

			bool mark_end = Mark_EndPtr();

			assert(m_pos < m_tlp.size());

			if (m_pos == 0) {
				cntl.AddStartPtr(flit_pos);
			}

			tmpFlit.range(lastbit, firstbit) = get_tlp_byte();

			if (mark_end) {
				cntl.AddEndPtr(flit_pos);
			}
		}

		flit = tmpFlit;
	}

	uint8_t get_tlp_byte()
	{
		uint8_t v = m_tlp[m_pos++];

		if (m_pos == m_tlp.size()) {
			m_tlpDone = true;
		}

		return v;
	}

	uint8_t get_tlp_u32()
	{
		uint32_t v = m_tlp[m_pos] |
				(m_tlp[m_pos + 1] << 8) |
				(m_tlp[m_pos + 2] << 16) |
				(m_tlp[m_pos + 3] << 24);

		m_pos += 4;

		if (m_pos == m_tlp.size()) {
			m_tlpDone = true;
		}

		return v;
	}

	bool Mark_EndPtr()
	{
		//
		// End Ptr is set on the last 4 bytes
		//
		return m_pos == (m_tlp.size() - 4);
	}

	bool Done() { return m_tlpDone; }

	void NotifyDone()
	{
		if (m_tlpDone) {
			SetTLMOKResp();
		} else {
			SetTLMGenericErrrorResp();
		}

		m_done.notify();
	}

	sc_event& DoneEvent() { return m_done; }

	template<typename MSG_T>
	void PushBack(MSG_T& msg)
	{
		uint32_t *d;

		d = msg.data();
		for (unsigned int i = 0; i < msg.size(); i++) {
			uint32_t v =  d[i];

			m_tlp.push_back((v >> 24) & 0xFF);
			m_tlp.push_back((v >> 16) & 0xFF);
			m_tlp.push_back((v >> 8) & 0xFF);
			m_tlp.push_back(v & 0xFF);
		}
	}

	std::vector<uint8_t>& GetTLP()
	{
		return m_tlp;
	}

private:

	void SetTLMOKResp()
	{
		m_gp->set_response_status(tlm::TLM_OK_RESPONSE);
	}

	void SetTLMGenericErrrorResp()
	{
		m_gp->set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
	}

	tlm::tlm_generic_payload *m_gp;
	ccixattr_extension *m_attr;
	sc_event m_done;
	unsigned int m_pos;
	std::vector<uint8_t> m_tlp;
	bool m_tlpDone;
};

template<typename TLPHdr_t>
class TLPAssembler
{
public:
	TLPAssembler(unsigned int startPtr) :
		m_startPtr(startPtr),
		m_endPtr(0),
		m_hasEndPtr(false),
		m_defTgtID(0),
		m_defSrcID(0),
		m_msgCredit(0)
	{}

	//
	// Where in the flit to start the assemble (bit position)
	//
	// Only used with the TLP's first flit and on the following ones it
	// should be 0 (start collecting from the beginning)
	//
	int GetStartPtr() { return m_startPtr; }
	void SetStartPtr(int startPtr)
	{
		m_startPtr = startPtr;
	}

	//
	// Where in the flit to stop the assembling (bit position)
	//
	// Only used with the TLP's last flit
	//
	void SetEndPtr(int endPtr)
	{
		m_endPtr = endPtr;
		m_hasEndPtr = true;
	}

	bool Done(int flit_pos)
	{
		return m_hasEndPtr && flit_pos == m_endPtr;
	}

	void PushBack(uint32_t val)
	{
		m_data.push_back(val & 0xFF);
		m_data.push_back((val >> 8) & 0xFF);
		m_data.push_back((val >> 16) & 0xFF);
		m_data.push_back((val >> 24) & 0xFF);
	}

	void ExtractCCIXMessages(std::list<IMsg*>& m_ccixMsgs)
	{
		unsigned int pos = 0;

		ExtractTLPHeader(pos);

		while (pos < m_data.size()) {
			IMsg *msg = ExtractCCIXMessage(pos);

			if (msg) {
				if (msg->IsReqChain()) {

					SetupReqChain(msg, m_ccixMsgs);

				} else if (msg->IsSnpReqChain()) {

					SetupSnpReqChain(msg, m_ccixMsgs);
				}

				m_ccixMsgs.push_back(msg);
			} else {
				SC_REPORT_ERROR("TLPAssembler",
					"Received invalid CCIX Message");
				continue;
			}

			//
			// Forward piggybacked credits only with the first
			// message
			//
			m_msgCredit = 0;

			//
			// Advance to next message
			//
			pos += (msg->GetMsgLen() * 4);
		}
	}

private:
	void ExtractTLPHeader(unsigned int& pos)
	{
		TLPHdr_t hdr(m_data.data());

		m_defTgtID = hdr.get_tgtID();
		m_defSrcID = hdr.get_srcID();
		m_msgCredit = hdr.get_msgCredit();

		pos += TLPHdr_t::TLPHdr_Size;
	}

	IMsg *ExtractCCIXMessage(unsigned int& pos)
	{
		uint8_t *msg = m_data.data() + pos;
		uint32_t msghdr;

		assert((m_data.size() - pos) >= 4);

		msghdr = toMsgHdr(msg);

		switch(ExtractMsgType(msghdr)) {
		case Msg::Type::Req:
			return new MsgReq(msg,
					m_defTgtID,
					m_defSrcID,
					m_msgCredit);

		case Msg::Type::SnpReq:

			return new MsgSnpReq(msg,
					m_defTgtID,
					m_defSrcID,
					m_msgCredit);

		case Msg::Type::Resp:
		case Msg::Type::SnpResp:

			return new MsgRsp(msg,
					m_defTgtID,
					m_defSrcID,
					m_msgCredit);

		case Msg::Type::MiscUnCredited:

			switch (ExtractMiscOp(msghdr)) {
			case Msg::MiscOp::NOP:
				return new MsgNOP(msg,
						m_defTgtID,
						m_defSrcID,
						m_msgCredit);

			case Msg::MiscOp::CreditGrant:
			case Msg::MiscOp::CreditReturn:

				return new MsgCrdEx(msg,
						m_defTgtID,
						m_defSrcID,
						m_msgCredit);

			case Msg::MiscOp::ProtError:
			case Msg::MiscOp::Generic:
			default:
				break;
			}

			break;
		case Msg::Type::MiscCredited:
			return new MsgMiscCredited(msg,
						m_defTgtID,
						m_defSrcID,
						m_msgCredit);
		default:
			break;
		}

		return NULL;
	}

	enum {
		MsgType_Shift =  27,
		MsgType_Mask = 0xF,

		MiscOp_Shift =  16,
		MiscOp_Mask = 0x7,
	};

	IMsg *LookupPrev(std::list<IMsg*>& m_ccixMsgs, uint8_t msgType)
	{
		typename std::list<IMsg*>::reverse_iterator it;

		for (it = m_ccixMsgs.rbegin(); it != m_ccixMsgs.rend(); it++) {
			IMsg *msg = (*it);

			if (msg->GetMsgType() == msgType) {
				return msg;
			}
		}

		return NULL;
	}

	void SetupReqChain(IMsg *msg, std::list<IMsg*>& m_ccixMsgs)
	{
		IMsg *prev = LookupPrev(m_ccixMsgs, Msg::Type::Req);

		if (prev) {
			tlm::tlm_generic_payload& gp = msg->GetGP();
			tlm::tlm_generic_payload& prev_gp = prev->GetGP();
			ccixattr_extension *ccix = msg->GetCCIXAttr();
			ccixattr_extension *ccix_prev = prev->GetCCIXAttr();

			gp.set_command(prev_gp.get_command());
			gp.set_address(prev_gp.get_address() + CACHELINE_SZ);

			//
			// All other fields become identical as the previous req
			//
			ccix->copy_from(*ccix_prev);
		} else {
			SC_REPORT_ERROR("TLPAssembler",
				"No previous request found for ReqChain");
		}
	}

	void SetupSnpReqChain(IMsg *msg, std::list<IMsg*>& m_ccixMsgs)
	{
		IMsg *prev = LookupPrev(m_ccixMsgs, Msg::Type::SnpReq);

		if (prev) {
			tlm::tlm_generic_payload& gp = msg->GetGP();
			tlm::tlm_generic_payload& prev_gp = prev->GetGP();
			ccixattr_extension *ccix = msg->GetCCIXAttr();
			ccixattr_extension *ccix_prev = prev->GetCCIXAttr();

			gp.set_command(prev_gp.get_command());
			gp.set_address(prev_gp.get_address() + CACHELINE_SZ);

			//
			// All other fields become identical as the previous req
			//
			ccix->copy_from(*ccix_prev);
		} else {
			SC_REPORT_ERROR("TLPAssembler",
				"No previous request found for SnpReqChain");
		}
	}

	uint32_t toMsgHdr(uint8_t *msg)
	{
		return (msg[0] << 24) | (msg[1] << 16) |
			(msg[2] << 8) | (msg[3] << 0);
	}

	uint8_t ExtractMsgType(uint32_t hdr)
	{
		return (hdr >> MsgType_Shift) & MsgType_Mask;
	}

	uint8_t ExtractMiscOp(uint32_t hdr)
	{
		return (hdr >> MiscOp_Shift) & MiscOp_Mask;
	}

	int m_startPtr;
	int m_endPtr;
	bool m_hasEndPtr;
	std::vector<uint8_t> m_data;

	//
	// Default values for the CCIX messages
	//
	uint8_t m_defTgtID;
	uint8_t m_defSrcID;
	uint8_t m_msgCredit;
};

template<typename T>
class TLPFactory
{
public:
	typedef typename T::TLP_t TLP_t;

	static TLP_t *Create(tlm::tlm_generic_payload *gp)
	{
		ccixattr_extension *ccix;

		assert(gp);

		gp->get_extension(ccix);

		if (ccix) {
			switch (ccix->GetMsgType()) {
			case Msg::Type::Req:
				return create_TLP<MsgReq>(gp);
			case Msg::Type::SnpReq:
				return create_TLP<MsgSnpReq>(gp);
			case Msg::Type::Resp:
			case Msg::Type::SnpResp:
				return create_TLP<MsgRsp>(gp);
			case Msg::Type::MiscUnCredited:

				switch (ccix->GetMiscOp()) {
				case Msg::MiscOp::NOP:
					return create_TLP<MsgNOP>(gp);

				case Msg::MiscOp::CreditGrant:
				case Msg::MiscOp::CreditReturn:
					return create_TLP<MsgCrdEx>(gp);

				case Msg::MiscOp::ProtError:
				case Msg::MiscOp::Generic:
				default:
					break;
				}

				break;
			case Msg::Type::MiscCredited:
				return create_TLP<MsgMiscCredited>(gp);
			default:
				break;
			}
		}

		return NULL;
	}

	template<typename MSG_T>
	static TLP_t *create_TLP(tlm::tlm_generic_payload *gp)
	{
		MSG_T msg(gp);

		return new TLP_t(&msg);
	}
};

}; // namespace CCIX

#undef GEN_FIELD_FUNCS
#undef GEN_TLP_HDR_FIELD_FUNCS

#endif
