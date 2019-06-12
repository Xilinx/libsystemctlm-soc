//
// CHI attributes extension
//
// Copyright (c) 2019 Xilinx Inc.
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

#ifndef __CHIATTR_H__
#define __CHIATTR_H__

//
// Generators for Setters and Getters.
//
#define CHIATTR_PROP_GETSET_GEN(name, type) 		\
	type Get ## name (void) const { return name ; }	\
	void Set ## name (type new_v) { name = new_v; }

#define CHIATTR_PROP_GETSET_GEN_FUNC_NAME(func_name, prop_name, type)	\
	type Get ## func_name (void) const { return prop_name ; }	\
	void Set ## func_name (type new_v) { prop_name = new_v; }

class chiattr_extension
: public tlm::tlm_extension<chiattr_extension>
{
public:
	chiattr_extension() :
		TgtID(0),
		SrcID(0),
		HomeNID(0),
		ReturnNID_StashNID(0),
		FwdNID(0),
		LPID(0),
		StashNIDValid_Endian(false),
		TxnID(0),
		ReturnTxnID(0),
		FwdTxnID(0),
		DBID(0),
		Opcode(0),
		secure(false),
		EarlyWrAck(false),
		DeviceMemory(false),
		Cacheable(false),
		Allocate(false),
		SnpAttr(false),
		LikelyShared(false),
		Order(0),
		Excl_SnoopMe(false),
		AllowRetry(false),
		ExpCompAck(false),
		RetToSrc(false),
		FwdState_DataPull_DataSource(0),
		DoNotGoToSD_DoNotDataPull(false),
		QoS(0),
		PCrdType(0),
		TraceTag(false),
		VMIDExt(0),
		Resp(0),
		RespErr(0),
		CCID(0),
		DataID(0),
		DataCheck(0),
		Poison(0),
		RSVDC(0)
	{
		memset(Data, 0, sizeof(Data));
	}

	void copy_from(const tlm_extension_base &extension) {
		const chiattr_extension &ext_chiattr = static_cast<chiattr_extension const &>(extension);
		*this = ext_chiattr;
	}

	tlm::tlm_extension_base *clone(void) const
	{
		return new chiattr_extension(*this);
	}

	CHIATTR_PROP_GETSET_GEN(TgtID, uint16_t)
	CHIATTR_PROP_GETSET_GEN(SrcID, uint16_t)
	CHIATTR_PROP_GETSET_GEN(HomeNID, uint16_t)

	CHIATTR_PROP_GETSET_GEN(ReturnNID_StashNID, uint16_t)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(ReturnNID,
					  ReturnNID_StashNID,
					  uint16_t)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(StashNID,
					  ReturnNID_StashNID,
					  uint16_t)

	CHIATTR_PROP_GETSET_GEN(FwdNID, uint16_t)
	CHIATTR_PROP_GETSET_GEN(LPID, uint8_t)

	CHIATTR_PROP_GETSET_GEN(StashNIDValid_Endian, bool)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(StashNIDValid,
					  StashNIDValid_Endian,
					  bool)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(Endian,
					  StashNIDValid_Endian,
					  bool)

	CHIATTR_PROP_GETSET_GEN(TxnID, uint8_t)
	CHIATTR_PROP_GETSET_GEN(ReturnTxnID, uint8_t)
	CHIATTR_PROP_GETSET_GEN(FwdTxnID, uint8_t)
	CHIATTR_PROP_GETSET_GEN(DBID, uint8_t)
	CHIATTR_PROP_GETSET_GEN(Opcode, uint8_t)

	CHIATTR_PROP_GETSET_GEN(secure, bool);
	bool GetNonSecure(void) const { return !secure; }
	void SetNonSecure(bool new_non_secure) {
		secure = !new_non_secure;
	}

	CHIATTR_PROP_GETSET_GEN(EarlyWrAck, bool)
	CHIATTR_PROP_GETSET_GEN(DeviceMemory, bool)
	CHIATTR_PROP_GETSET_GEN(Cacheable, bool)
	CHIATTR_PROP_GETSET_GEN(Allocate, bool)
	CHIATTR_PROP_GETSET_GEN(SnpAttr, bool)
	CHIATTR_PROP_GETSET_GEN(LikelyShared, bool)
	CHIATTR_PROP_GETSET_GEN(Order, uint8_t)

	CHIATTR_PROP_GETSET_GEN(Excl_SnoopMe, bool)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(Excl,
					  Excl_SnoopMe,
					  bool)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(SnoopMe,
					  Excl_SnoopMe,
					  bool)

	CHIATTR_PROP_GETSET_GEN(AllowRetry, bool)
	CHIATTR_PROP_GETSET_GEN(ExpCompAck, bool)
	CHIATTR_PROP_GETSET_GEN(RetToSrc, bool)

	CHIATTR_PROP_GETSET_GEN(FwdState_DataPull_DataSource, uint8_t)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(FwdState_DataPull,
					  FwdState_DataPull_DataSource,
					  uint8_t)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(FwdState,
					  FwdState_DataPull_DataSource,
					  uint8_t)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(DataPull,
					  FwdState_DataPull_DataSource,
					  uint8_t)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(DataSource,
					  FwdState_DataPull_DataSource,
					  uint8_t)

	CHIATTR_PROP_GETSET_GEN(DoNotGoToSD_DoNotDataPull, bool)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(DoNotGoToSD,
					  DoNotGoToSD_DoNotDataPull,
					  bool)
	CHIATTR_PROP_GETSET_GEN_FUNC_NAME(DoNotDataPull,
					  DoNotGoToSD_DoNotDataPull,
					  bool)

	CHIATTR_PROP_GETSET_GEN(QoS, uint8_t)
	CHIATTR_PROP_GETSET_GEN(PCrdType, uint8_t)
	CHIATTR_PROP_GETSET_GEN(TraceTag, bool)
	CHIATTR_PROP_GETSET_GEN(VMIDExt, uint8_t)
	CHIATTR_PROP_GETSET_GEN(Resp, uint8_t)
	CHIATTR_PROP_GETSET_GEN(RespErr, uint8_t)
	CHIATTR_PROP_GETSET_GEN(CCID, uint8_t)
	CHIATTR_PROP_GETSET_GEN(DataID, uint8_t)
	CHIATTR_PROP_GETSET_GEN(DataCheck, uint64_t)
	CHIATTR_PROP_GETSET_GEN(Poison, uint8_t)
	CHIATTR_PROP_GETSET_GEN(RSVDC, uint32_t)

	uint8_t *GetData() { return Data; }
private:
	// The node ID of the component to which the message is targeted.
	uint16_t TgtID;

	// The node ID of the component from which the message is sent.
	uint16_t SrcID;

	// The Requester uses the value in this field to determine the TgtID of
	// the CompAck to be sent in response to CompData.
	uint16_t HomeNID;

	// In a Request this field contains the ID for the node to which the
	// Slave sends the CompData and DataSepResp response or the ID of the
	// stash target.
	uint16_t ReturnNID_StashNID;

	// Identifies the Requester to which the CompData response can be
	// forwarded.
	uint16_t FwdNID;

	// Used in conjunction with the SrcID to uniquely identify the logical
	// processor that generated the request.
	uint8_t LPID;

	//
	// Indicates if the ReturnNID_StashNID field has a valid value stash ID
	// value on stash transactions.
	//
	// True if the if the data in the transactions is big endian  on atomic
	// transactions, false if it is little endian.
	//
	bool StashNIDValid_Endian;

	// The transaction id.
	uint8_t TxnID;

	//
	// The transaction id a slave must use in TxnID field in a CompData,
	// DataSepResp response.
	//
	// For Stash transactions this fields contains:
	//
	// StashLPID[4:0]: Provides a valid Logical Processor target value
	// within the Request Node specified by StashNID.
	//
	// StashLPIDValid[5]: Indicates if the StashLPID field has a valid
	// value.
	//
	// [7:6]: 0b00
	//
	uint8_t ReturnTxnID;

	// Identifies the TxnID of the original request associated with the
	// snoop transaction.
	uint8_t FwdTxnID;

	// The data buffer identifier.
	uint8_t DBID;

	// The transaction opcode.
	uint8_t Opcode;

	// Secure vs Non-Secure transactions.
	bool secure;

	// Specifies if early write acknowledge is permitted.
	bool EarlyWrAck;

	// Memory attribute, true if the transaction memory type is device
	// memory and false if it is normal memory.
	bool DeviceMemory;

	// Require cache lookup if set (and a cache is present).
	bool Cacheable;

	// If set the cache receiving the transactions is recommended to
	// allocate the transaction.
	bool Allocate;

	// The snoop attribute associated with the transaction.
	bool SnpAttr;

	// Indicates whether the requested data is likely to be shared with
	// another request node.
	bool LikelyShared;

	// Transaction order requirements.
	uint8_t Order;

	//
	// When used with exclusive transactions: marks the transaction as
	// exclusive.
	//
	// When used with atomic transactions and means:
	// also snoop the transaction requester (initiator) and is SnoopMe.
	//
	bool Excl_SnoopMe;

	// Let the target decide if a retry is needed if the transaction is
	// sent out without a p-credit.
	bool AllowRetry;

	// If a CompAck is supposed to be expected.
	bool ExpCompAck;

	// Return a copy of the cache line to the home node.
	bool RetToSrc;

	//
	// When the field is used as FwdState it indicates the state in the
	// CompData sent from the Snoopee to the Requester.
	//
	// When the field is used as DataPull it indicates that a snoop
	// response includes a read request.
	//
	// When the field is used as DataSource it indentifies the sender of
	// the data response.
	//
	uint8_t FwdState_DataPull_DataSource;

	//
	// This is used in snoop requests indicating that a transation to SD
	// state is not permitted or that Data pull snoop response is not
	// permitted.
	bool DoNotGoToSD_DoNotDataPull;

	// The transaction QoS prio level.
	uint8_t QoS;

	// Protocol credit type being granted or returned.
	uint8_t PCrdType;

	// A bit set for tracing the packets associated with the transaction.
	bool TraceTag;

	// Extends VMID to 16 bits.
	uint8_t VMIDExt;

	//
	// Resp[2]: The data in the response is dirty and pass on the
	// responsibility to write back the cache line.
	//
	// Resp[1:0]:
	//
	// For a snoop message response it indicates the final cache state
	// at the snoop target.
	//
	// For a completion response it indicates the final cache state at
	// the requester.
	//
	// For a write response it indicates the cache state at
	// the source (requester).
	//
	uint8_t Resp;

	// This field indicates the error status of the response.
	uint8_t RespErr;

	// The critical chunk identifier, indicates the critical 128 bit chunk
	// of data being requested.
	uint8_t CCID;

	// This field contains the relative position of the data chunk within
	// the cache line being transfered.
	uint8_t DataID;

	// Used to supply the data check for bit for the corresponding byte of
	// data.
	uint64_t DataCheck;

	// Indicates if the 64-bit chunk of data corresponding to a Poison bit
	// has an error and must no be used.
	uint8_t Poison;

	// Reserved for customer use.
	uint32_t RSVDC;

	//
	// Atomic data used for non store atomic operations. For AtomicCompare
	// place Swapdata in the MSB bytes (higher index) and CompareData in
	// the lsb bytes (lower index), starting from byte 0.
	//
	// For DVMOp transactions it contains the physical / virtual address
	// and is placed in the lsb bytes 'Data[8:0]' (being address bits
	// [64:0]). The other DVM fields are transferred with the address.
	//
	enum { MaxDataSz = 32 };
	uint8_t Data[MaxDataSz];
};

#endif /* __CHIATTR_H__ */
