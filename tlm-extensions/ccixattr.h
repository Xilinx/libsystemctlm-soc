//
// CCIX attributes extension
//
// Copyright (c) 2020 Xilinx Inc.
// Written by Francisco Iglesias.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//

#ifndef __CCIXATTR_H__
#define __CCIXATTR_H__

//
// Generators for Setters and Getters.
//
#define CCIXATTR_PROP_GETSET_GEN(name, type) 		\
	type Get ## name (void) const { return name ; }	\
	void Set ## name (type new_v) { name = new_v; }

class ccixattr_extension
: public tlm::tlm_extension<ccixattr_extension>
{
public:
	ccixattr_extension() :
		TgtID(0),
		SrcID(0),
		MsgLen(0),
		MsgCredit(0),
		Ext(0),
		MsgType(0),
		QoS(0),
		TxnID(0),
		ReqOp(0),
		secure(false),
		ReqAttr(0),

		// For snoop messages
		SnpCast(0),
		DataRet(0),
		SnpOp(0),

		// For response messages
		RespOp(0),
		RespAttr(0),

		MiscOp(0),

		DataCredit(0),
		ReqCredit(0),
		MiscCredit(0),
		SnpCredit(0),
		PayloadSz(0),

		User(0),
		RespErr(0),
		Poison0(0),
		Poison1(0)
	{
		memset(Payload, 0, sizeof(Payload));
	}

	void copy_from(const tlm_extension_base &extension) {
		const ccixattr_extension &ext_ccixattr =
			static_cast<ccixattr_extension const &>(extension);

		*this = ext_ccixattr;
	}

	tlm::tlm_extension_base *clone(void) const
	{
		return new ccixattr_extension(*this);
	}

	CCIXATTR_PROP_GETSET_GEN(TgtID, uint8_t)
	CCIXATTR_PROP_GETSET_GEN(SrcID, uint8_t)
	CCIXATTR_PROP_GETSET_GEN(MsgLen, uint8_t)
	CCIXATTR_PROP_GETSET_GEN(MsgCredit, uint8_t)
	CCIXATTR_PROP_GETSET_GEN(Ext, bool)
	CCIXATTR_PROP_GETSET_GEN(MsgType, uint8_t)
	CCIXATTR_PROP_GETSET_GEN(QoS, uint8_t)
	CCIXATTR_PROP_GETSET_GEN(TxnID, uint16_t)
	CCIXATTR_PROP_GETSET_GEN(ReqOp, uint8_t)

	CCIXATTR_PROP_GETSET_GEN(secure, bool);
	bool GetNonSecure(void) const { return !secure; }
	void SetNonSecure(bool new_non_secure) {
		secure = !new_non_secure;
	}

	CCIXATTR_PROP_GETSET_GEN(ReqAttr, uint8_t)

	// Fields used by snoop messages
	CCIXATTR_PROP_GETSET_GEN(SnpCast, uint8_t)
	CCIXATTR_PROP_GETSET_GEN(DataRet, bool)
	CCIXATTR_PROP_GETSET_GEN(SnpOp, uint8_t)

	// Fields used by response messages
	CCIXATTR_PROP_GETSET_GEN(RespOp, uint8_t)
	CCIXATTR_PROP_GETSET_GEN(RespAttr, uint8_t)

	CCIXATTR_PROP_GETSET_GEN(MiscOp, uint8_t)

	CCIXATTR_PROP_GETSET_GEN(DataCredit, uint32_t)
	CCIXATTR_PROP_GETSET_GEN(ReqCredit, uint32_t)
	CCIXATTR_PROP_GETSET_GEN(MiscCredit, uint32_t)
	CCIXATTR_PROP_GETSET_GEN(SnpCredit, uint32_t)

	uint8_t *GetPayload() { return Payload; }
	CCIXATTR_PROP_GETSET_GEN(PayloadSz, uint32_t)

	CCIXATTR_PROP_GETSET_GEN(User, uint32_t)

	CCIXATTR_PROP_GETSET_GEN(RespErr, uint8_t)
	CCIXATTR_PROP_GETSET_GEN(Poison0, uint8_t)
	CCIXATTR_PROP_GETSET_GEN(Poison1, uint8_t)
private:
	uint8_t TgtID;
	uint8_t SrcID;
	uint8_t MsgLen;
	uint8_t MsgCredit;
	bool Ext;
	uint8_t MsgType;
	uint8_t QoS;
	uint16_t TxnID;
	uint8_t ReqOp;
	bool secure;
	uint8_t ReqAttr;

	uint8_t SnpCast;
	bool DataRet;
	uint8_t SnpOp;

	uint8_t RespOp;
	uint8_t RespAttr;

	uint8_t MiscOp;

	uint32_t DataCredit;
	uint32_t ReqCredit;
	uint32_t MiscCredit;
	uint32_t SnpCredit;

	enum { MaxDataSz = 32 };
	uint8_t Payload[MaxDataSz];
	uint32_t PayloadSz;

	// Extensions
	uint32_t User;

	uint8_t RespErr;
	uint8_t Poison0;
	uint8_t Poison1;
};

#undef CCIXATTR_PROP_GETSET_GEN

#endif /* __CCIXATTR_H__ */
