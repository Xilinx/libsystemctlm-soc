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

#ifndef TLM_MODULES_SN_CHI_H__
#define TLM_MODULES_SN_CHI_H__

#include <list>
#include <endian.h>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/chiattr.h"
#include "tlm-bridges/amba-chi.h"
#include "tlm-modules/private/chi/txnids.h"

using namespace AMBA::CHI;

template<int NODE_ID=10>
class SlaveNode_F :
	public sc_core::sc_module
{
private:
	class IMsg
	{
	public:
		IMsg() :
			m_chiattr(new chiattr_extension())
		{
			m_gp.set_data_ptr(m_data);
			m_gp.set_data_length(CACHELINE_SZ);

			m_gp.set_byte_enable_ptr(m_byteEnable);
			m_gp.set_byte_enable_length(CACHELINE_SZ);

			m_gp.set_streaming_width(CACHELINE_SZ);

			m_gp.set_extension(m_chiattr);
		}

		virtual ~IMsg() {}

		tlm::tlm_generic_payload& GetGP()
		{
			return m_gp;
		}

		chiattr_extension *GetCHIAttr() { return m_chiattr; }

		uint8_t GetTxnID() { return m_chiattr->GetTxnID(); }
		uint16_t GetSrcID() { return m_chiattr->GetSrcID(); }
		uint8_t GetDBID() { return m_chiattr->GetDBID(); }

	protected:

		tlm::tlm_generic_payload m_gp;
		chiattr_extension *m_chiattr;

		uint8_t m_data[CACHELINE_SZ];
		uint8_t m_byteEnable[CACHELINE_SZ];
	};

	class ReqTxn :
		public IMsg
	{
	public:
		using IMsg::m_gp;
		using IMsg::m_data;
		using IMsg::m_byteEnable;
		using IMsg::m_chiattr;

		ReqTxn(tlm::tlm_generic_payload& gp) :
			m_dataReceived(0)
		{
			m_gp.deep_copy_from(gp);

			InitSlaveGP();

			// 2.10 [1]
			if (IsReadNoSnp() || IsReadNoSnpSep()) {
				uint64_t aligned_addr = GetAlignedAddress(gp.get_address(),
									gp.get_data_length());
				unsigned int line_offset = GetLineOffset(aligned_addr);

				m_slaveGP.set_command(tlm::TLM_READ_COMMAND);
				m_slaveGP.set_address(aligned_addr);

				// Read out all bytes in the window
				m_slaveGP.set_byte_enable_ptr(NULL);
				m_slaveGP.set_byte_enable_length(0);

				m_slaveGP.set_data_ptr(&m_dataSlave[line_offset]);
				m_slaveGP.set_data_length(gp.get_data_length());
				m_slaveGP.set_streaming_width(gp.get_data_length());

			} else if (IsWriteNoSnpFull() || IsWriteNoSnpPtl()) {
				uint64_t addr = gp.get_address();
				uint64_t aligned_addr = GetAlignedAddress(addr,
									gp.get_data_length());
				uint64_t diff = addr - aligned_addr;
				unsigned int len = gp.get_data_length() - diff;
				unsigned int line_offset = GetLineOffset(addr);

				m_slaveGP.set_command(tlm::TLM_WRITE_COMMAND);
				m_slaveGP.set_address(gp.get_address());

				m_slaveGP.set_data_ptr(&m_dataSlave[line_offset]);
				m_slaveGP.set_data_length(len);

				m_slaveGP.set_byte_enable_ptr(
					&m_byteEnableSlave[line_offset]);
				m_slaveGP.set_byte_enable_length(len);

				m_slaveGP.set_streaming_width(len);
			}
			// Atomics don't use m_slaveGP

		}

		void InitSlaveGP()
		{
			m_slaveGP.set_data_ptr(m_dataSlave);
			m_slaveGP.set_data_length(CACHELINE_SZ);

			m_slaveGP.set_byte_enable_ptr(m_byteEnableSlave);
			m_slaveGP.set_byte_enable_length(CACHELINE_SZ);

			m_slaveGP.set_streaming_width(CACHELINE_SZ);
		}

		tlm::tlm_generic_payload& GetSlaveGP()
		{
			return m_slaveGP;
		}

		uint64_t GetAlignedAddress(uint64_t addr, unsigned int alignSize)
		{
			return (addr / alignSize) * alignSize;
		}

		enum { RequestAccepted = 1, };

		bool RequiresReadReceipt()
		{
			return m_chiattr->GetOrder() == RequestAccepted ||
				m_chiattr->GetOpcode() == Req::ReadNoSnpSep;
		}

		bool GetAllowRetry()
		{
			return m_chiattr->GetAllowRetry();
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

		bool IsReadNoSnp()
		{
			return m_chiattr->GetOpcode() == Req::ReadNoSnp;
		}

		bool IsReadNoSnpSep()
		{
			return m_chiattr->GetOpcode() == Req::ReadNoSnpSep;
		}

		bool IsWriteNoSnpFull()
		{
			return m_chiattr->GetOpcode() == Req::WriteNoSnpFull;
		}

		bool IsWriteNoSnpPtl()
		{
			return m_chiattr->GetOpcode() == Req::WriteNoSnpPtl;
		}

		bool IsCacheMaintenance()
		{
			switch (m_chiattr->GetOpcode()) {
			case Req::CleanShared:
			case Req::CleanSharedPersist:
			case Req::CleanInvalid:
			case Req::MakeInvalid:
				return true;
			}
			return false;
		}

		void CopyWriteData(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			m_dataReceived += CopyData(gp, chiattr);
		}

		bool AllWriteDataRecieved()
		{
			return m_dataReceived == CACHELINE_SZ;
		}

		uint8_t *GetSwapData()
		{
			uint64_t address = m_gp.get_address();
			unsigned int outboundLen = GetDataLength();
			unsigned int offset = GetLineOffset(address);

			if (offset % outboundLen) {
				offset = offset - outboundLen/2;
			} else {
				offset = offset + outboundLen/2;
			}

			return &m_dataSlave[offset];
		}

		uint8_t *GetCompareData()
		{
			uint64_t address = m_gp.get_address();
			unsigned int offset = GetLineOffset(address);

			return &m_dataSlave[offset];
		}

		unsigned int GetLineOffset(uint64_t addr)
		{
			return addr & (CACHELINE_SZ-1);
		}

		enum { AtomicOpMask = 0x7 };

		uint8_t GetAtomicOp()
		{
			return m_chiattr->GetOpcode() & AtomicOpMask;
		}

		void CopyOrginialData(uint8_t *orgData)
		{
			unsigned int len = m_gp.get_data_length();
			unsigned int offset = GetLineOffset(m_gp.get_address());

			if (IsAtomicCompare()) {
				// inbound length is halv outbound
				len = len/2;
			}

			assert(len <= CACHELINE_SZ);

			memset(m_data, 0, sizeof(m_data));
			memset(m_byteEnable, TLM_BYTE_DISABLED, sizeof(m_byteEnable));

			memcpy(&m_data[offset], orgData, len);
			memset(&m_byteEnable[offset], TLM_BYTE_ENABLED, len);
		}

		bool IsBigEndian() { return m_chiattr->GetEndian(); }

		uint64_t GetAddress() { return m_gp.get_address(); }
		uint8_t *GetData()
		{
			unsigned int offset = GetLineOffset(m_gp.get_address());

			return &m_dataSlave[offset];
		}

		unsigned int GetDataLength()
		{
			return m_gp.get_data_length();
		}

		uint8_t *GetOrginialData() { return m_data; }
		uint8_t *GetOrginialByteEnable() { return m_byteEnable; }

	private:

		unsigned int CopyData(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			unsigned char *data = m_dataSlave;
			unsigned char *byteEnable = m_byteEnableSlave;
			unsigned char *srcData = gp.get_data_ptr();
			unsigned int len = gp.get_data_length();
			unsigned char *be = gp.get_byte_enable_ptr();
			unsigned int be_len = gp.get_byte_enable_length();
			unsigned int offset = chiattr->GetDataID() * len;
			unsigned int max_len = CACHELINE_SZ - offset;

			if (len > max_len) {
				len = max_len;
			}

			if (be_len) {
				unsigned int i;

				for (i = 0; i < len; i++) {
					bool do_access = be[i % be_len] == TLM_BYTE_ENABLED;

					if (do_access) {
						data[offset + i] = srcData[i];
						byteEnable[offset + i] = TLM_BYTE_ENABLED;
					} else {
						byteEnable[offset + i] = TLM_BYTE_DISABLED;
					}
				}
			} else {
				memcpy(&data[offset], srcData, len);
				memset(&byteEnable[offset], TLM_BYTE_ENABLED, len);
			}

			return len;
		}

		tlm::tlm_generic_payload m_slaveGP;

		uint8_t m_dataSlave[CACHELINE_SZ];
		uint8_t m_byteEnableSlave[CACHELINE_SZ];

		unsigned int m_dataReceived;
	};

	class RspMsg :
		public IMsg
	{
	public:
		using IMsg::m_chiattr;

		RspMsg(ReqTxn *req, uint8_t opcode, uint8_t DBID = 0)
		{
			chiattr_extension *attr = req->GetCHIAttr();

			m_chiattr->SetQoS(attr->GetQoS());
			m_chiattr->SetTgtID(attr->GetSrcID());
			m_chiattr->SetSrcID(NODE_ID);
			m_chiattr->SetTxnID(attr->GetTxnID());
			m_chiattr->SetDBID(DBID);
			m_chiattr->SetOpcode(opcode);
			m_chiattr->SetTraceTag(attr->GetTraceTag());
		};
	};

	class DatMsg :
		public IMsg
	{
	public:
		using IMsg::m_gp;
		using IMsg::m_data;
		using IMsg::m_byteEnable;
		using IMsg::m_chiattr;

		enum { INV = 0, UC = 0x2 };

		DatMsg(ReqTxn *req)
		{
			tlm::tlm_generic_payload& gp = req->GetSlaveGP();
			chiattr_extension *attr = req->GetCHIAttr();

			m_gp.set_command(tlm::TLM_WRITE_COMMAND);

			//
			// req always have data + byte enable
			//
			if (!req->IsAtomic()) {
				memcpy(m_data, gp.get_data_ptr(), CACHELINE_SZ);

				if (gp.get_byte_enable_length()) {
					memcpy(m_byteEnable, gp.get_byte_enable_ptr(),
							gp.get_byte_enable_length());
				} else {
					m_gp.set_byte_enable_ptr(NULL);
					m_gp.set_byte_enable_length(0);
				}

			} else {
				memcpy(m_data, req->GetOrginialData(), CACHELINE_SZ);
				memcpy(m_byteEnable, req->GetOrginialByteEnable(), CACHELINE_SZ);
				m_gp.set_data_length(CACHELINE_SZ);
			}

			m_chiattr->SetQoS(attr->GetQoS());
			m_chiattr->SetTgtID(attr->GetReturnNID());
			m_chiattr->SetSrcID(NODE_ID);
			m_chiattr->SetTxnID(attr->GetReturnTxnID());

			if (req->IsReadNoSnpSep()) {
				m_chiattr->SetOpcode(Dat::DataSepResp);
			} else {
				m_chiattr->SetOpcode(Dat::CompData);
			}

			m_chiattr->SetHomeNID(attr->GetSrcID());
			m_chiattr->SetDBID(attr->GetTxnID());
			m_chiattr->SetTraceTag(attr->GetTraceTag());

			if (!req->IsAtomic()) {
				//
				// Always UC, 4.7.1 [1]
				//
				m_chiattr->SetResp(UC);
			} else {
				//
				// Always CompData_I, 4.7.4 [1]
				//
				m_chiattr->SetResp(INV);
			}
		}
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

		void Process(IMsg *msg)
		{
			m_txList.push_back(msg);
			m_listEvent.notify();
		}
	private:

		void tx_thread()
		{
			while (true) {
				sc_time delay(SC_ZERO_TIME);
				IMsg *msg;

				if (m_txList.empty()) {
					wait(m_listEvent);
				}

				msg = m_txList.front();
				m_txList.remove(msg);

				assert(msg->GetGP().get_response_status() ==
						tlm::TLM_INCOMPLETE_RESPONSE);

				m_init_socket->b_transport(msg->GetGP(), delay);

				assert(msg->GetGP().get_response_status() ==
						tlm::TLM_OK_RESPONSE);
				delete msg;
			} }

		tlm_utils::simple_initiator_socket<T>& m_init_socket;
		std::list<IMsg*> m_txList;
		sc_event m_listEvent;
	};

	class AtomicOperations
	{
	private:
		template<typename T1>
		void AtomicADD(uint8_t *data1, uint8_t *data2)
		{
			T1 *val1 = reinterpret_cast<T1*>(data1);
			T1 *val2 = reinterpret_cast<T1*>(data2);

			*val1 += *val2;
		}

		template<typename T1>
		void AtomicCLR(uint8_t *data1, uint8_t *data2)
		{
			T1 *val1 = reinterpret_cast<T1*>(data1);
			T1 *val2 = reinterpret_cast<T1*>(data2);

			*val1 = *val1 & ~(*val2);
		}

		template<typename T1>
		void AtomicEOR(uint8_t *data1, uint8_t *data2)
		{
			T1 *val1 = reinterpret_cast<T1*>(data1);
			T1 *val2 = reinterpret_cast<T1*>(data2);

			*val1 = *val1 ^ *val2;
		}

		template<typename T1>
		void AtomicSET(uint8_t *data1, uint8_t *data2)
		{
			T1 *val1 = reinterpret_cast<T1*>(data1);
			T1 *val2 = reinterpret_cast<T1*>(data2);

			*val1 = *val1 | *val2;
		}

		template<typename T1>
		void AtomicMAX(uint8_t *data1, uint8_t *data2)
		{
			T1 *val1 = reinterpret_cast<T1*>(data1);
			T1 *val2 = reinterpret_cast<T1*>(data2);

			if ((*val2-*val1) > 0) {
				*val1 = *val2;
			}
		}

		template<typename T1>
		void AtomicMIN(uint8_t *data1, uint8_t *data2)
		{
			T1 *val1 = reinterpret_cast<T1*>(data1);
			T1 *val2 = reinterpret_cast<T1*>(data2);

			if ((*val2-*val1) < 0) {
				*val1 = *val2;
			}
		}

		void DoAdd(ReqTxn *req, uint8_t *data)
		{
			switch (req->GetDataLength()) {
			case 1:
				AtomicADD<uint8_t>(data, req->GetData());
				break;
			case 2:
				AtomicADD<uint16_t>(data, req->GetData());
				break;
			case 4:
				AtomicADD<uint32_t>(data, req->GetData());
				break;
			case 8:
				AtomicADD<uint64_t>(data, req->GetData());
				break;
			default:
				break;
			}
		}

		void DoCLR(ReqTxn *req, uint8_t *data)
		{
			switch (req->GetDataLength()) {
			case 1:
				AtomicCLR<uint8_t>(data, req->GetData());
				break;
			case 2:
				AtomicCLR<uint16_t>(data, req->GetData());
				break;
			case 4:
				AtomicCLR<uint32_t>(data, req->GetData());
				break;
			case 8:
				AtomicCLR<uint64_t>(data, req->GetData());
				break;
			default:
				break;
			}
		}

		void DoEOR(ReqTxn *req, uint8_t *data)
		{
			switch (req->GetDataLength()) {
			case 1:
				AtomicEOR<uint8_t>(data, req->GetData());
				break;
			case 2:
				AtomicEOR<uint16_t>(data, req->GetData());
				break;
			case 4:
				AtomicEOR<uint32_t>(data, req->GetData());
				break;
			case 8:
				AtomicEOR<uint64_t>(data, req->GetData());
				break;
			default:
				break;
			}
		}

		void DoSET(ReqTxn *req, uint8_t *data)
		{
			switch (req->GetDataLength()) {
			case 1:
				AtomicSET<uint8_t>(data, req->GetData());
				break;
			case 2:
				AtomicSET<uint16_t>(data, req->GetData());
				break;
			case 4:
				AtomicSET<uint32_t>(data, req->GetData());
				break;
			case 8:
				AtomicSET<uint64_t>(data, req->GetData());
				break;
			default:
				break;
			}
		}

		void DoSMAX(ReqTxn *req, uint8_t *data)
		{
			switch (req->GetDataLength()) {
			case 1:
				AtomicMAX<uint8_t>(data, req->GetData());
				break;
			case 2:
				AtomicMAX<uint16_t>(data, req->GetData());
				break;
			case 4:
				AtomicMAX<uint32_t>(data, req->GetData());
				break;
			case 8:
				AtomicMAX<uint64_t>(data, req->GetData());
				break;
			default:
				break;
			}
		}

		void DoSMIN(ReqTxn *req, uint8_t *data)
		{
			switch (req->GetDataLength()) {
			case 1:
				AtomicMIN<int8_t>(data, req->GetData());
				break;
			case 2:
				AtomicMIN<int16_t>(data, req->GetData());
				break;
			case 4:
				AtomicMIN<int32_t>(data, req->GetData());
				break;
			case 8:
				AtomicMIN<int64_t>(data, req->GetData());
				break;
			default:
				break;
			}
		}

		void DoUMAX(ReqTxn *req, uint8_t *data)
		{
			switch (req->GetDataLength()) {
			case 1:
				AtomicMAX<uint8_t>(data, req->GetData());
				break;
			case 2:
				AtomicMAX<uint16_t>(data, req->GetData());
				break;
			case 4:
				AtomicMAX<uint32_t>(data, req->GetData());
				break;
			case 8:
				AtomicMAX<uint64_t>(data, req->GetData());
				break;
			default:
				break;
			}
		}

		void DoUMIN(ReqTxn *req, uint8_t *data)
		{
			switch (req->GetDataLength()) {
			case 1:
				AtomicMIN<uint8_t>(data, req->GetData());
				break;
			case 2:
				AtomicMIN<uint16_t>(data, req->GetData());
				break;
			case 4:
				AtomicMIN<uint32_t>(data, req->GetData());
				break;
			case 8:
				AtomicMIN<uint64_t>(data, req->GetData());
				break;
			default:
				break;
			}
		}

	public:
		void Process(ReqTxn *req, uint8_t *data)
		{
			switch(req->GetAtomicOp()) {
			case Req::Atomic::ADD:
				DoAdd(req, data);
				break;
			case Req::Atomic::CLR:
				DoCLR(req, data);
				break;
			case Req::Atomic::EOR:
				DoEOR(req, data);
				break;
			case Req::Atomic::SET:
				DoSET(req, data);
				break;
			case Req::Atomic::SMAX:
				DoSMAX(req, data);
				break;
			case Req::Atomic::SMIN:
				DoSMIN(req, data);
				break;
			case Req::Atomic::UMAX:
				DoUMAX(req, data);
				break;
			case Req::Atomic::UMIN:
				DoUMAX(req, data);
				break;
			default:
				break;

			}
		}
	};

	template<typename T>
	class TxnProcessor :
		public sc_core::sc_module
	{
	public:

		SC_HAS_PROCESS(TxnProcessor);

		TxnProcessor(sc_core::sc_module_name name,
			tlm_utils::simple_initiator_socket<T>& init_socket,
				TxnIDs& ids,
			TxChannel<SlaveNode_F>& txRspChannel,
			TxChannel<SlaveNode_F>& txDatChannel,
			ReqTxn **txn) :
			sc_core::sc_module(name),
			m_init_socket(init_socket),
			m_ids(ids),
			m_txRspChannel(txRspChannel),
			m_txDatChannel(txDatChannel),
			m_txn(txn)
		{
			SC_THREAD(tx_thread);
		}

		void RunResponsePhase(ReqTxn *req)
		{
			if (req->IsReadNoSnp() || req->IsReadNoSnpSep()) {

				if (req->RequiresReadReceipt()) {
					RspMsg *rsp =
						new RspMsg(req,
							Rsp::ReadReceipt);

					m_txRspChannel.Process(rsp);
				}

				RunDataPhase(req);
			} else if (req->IsAtomic() && !req->IsAtomicStore()) {
				RspMsg *rsp =
					new RspMsg(req,
						Rsp::DBIDResp,
						m_ids.GetID());

				m_txn[rsp->GetDBID()] = req;

				m_txRspChannel.Process(rsp);
			} else if (req->IsCacheMaintenance()) {
				// Just reply on cache maintenance
				RspMsg *rsp = new RspMsg(req, Rsp::Comp);

				m_txRspChannel.Process(rsp);

				// Req is now done
				delete req;
			} else {
				RspMsg *rsp =
					new RspMsg(req,
						Rsp::CompDBIDResp,
						m_ids.GetID());

				m_txn[rsp->GetDBID()] = req;

				m_txRspChannel.Process(rsp);
			}
		}

		void RunDataPhase(ReqTxn *req)
		{
			m_txList.push_back(req);
			m_listEvent.notify();
		}
	private:

		void tx_thread()
		{
			while (true) {
				sc_time delay(SC_ZERO_TIME);
				ReqTxn *req;

				if (m_txList.empty()) {
					wait(m_listEvent);
				}

				req = m_txList.front();
				m_txList.remove(req);

				if (req->IsAtomic()) {
					HandleAtomic(req);
				} else {
					//
					// ReadNoSnp / WriteNoSnp
					//
					m_init_socket->b_transport(
							req->GetSlaveGP(), delay);

					assert(req->GetSlaveGP().get_response_status() ==
							tlm::TLM_OK_RESPONSE);
				}

				if (req->IsReadNoSnp() || req->IsReadNoSnpSep()) {
					DatMsg *dat = new DatMsg(req);

					m_txDatChannel.Process(dat);
				}

				delete req;
			}
		}

		void SwapBytes(uint8_t *data, unsigned int len)
		{
			uint8_t swappedData[len];
			unsigned int i;

			for (i = 0; i < len; i++) {
				swappedData[i] = data[len-1-i];
			}

			memcpy(data, swappedData, len);
		}

		void CorrectEndiannessPreOp(ReqTxn *req, uint8_t *data)
		{
			unsigned int len = req->GetDataLength();

#if __BYTE_ORDER == __BIG_ENDIAN
			if (!req->IsBigEndian()) {
				//
				// Convert to big endian since the
				// operation will be done in big endian
				//
				SwapBytes(data, len);
				SwapBytes(req->GetData(), len);
			}
#else
			if (req->IsBigEndian()) {
				//
				// Convert to little endian since the
				// operation will be done in little endian
				//
				SwapBytes(data, len);
				SwapBytes(req->GetData(), len);
			}
#endif
		}

		void CorrectEndiannessPostOp(ReqTxn *req, uint8_t *data)
		{
			unsigned int len = req->GetDataLength();

#if __BYTE_ORDER == __BIG_ENDIAN
			if (!req->IsBigEndian()) {
				//
				// The operation was done in big endian
				// But result needs to be in little endian
				//
				SwapBytes(data, len);
			}
#else
			if (req->IsBigEndian()) {
				//
				// The operation was done in little endian
				// But result needs to be in big endian
				//
				//
				SwapBytes(data, len);
			}
#endif
		}

		void HandleAtomic(ReqTxn *req)
		{
			uint8_t data[CACHELINE_SZ];
			unsigned int len = req->GetDataLength();

			DoTLM(req, tlm::TLM_READ_COMMAND, data, sizeof(data));

			if (!req->IsAtomicStore()) {
				req->CopyOrginialData(data);
			}

			if (req->IsAtomicStore() || req->IsAtomicLoad()) {

				CorrectEndiannessPreOp(req, data);

				m_atomicOps.Process(req, data);

				CorrectEndiannessPostOp(req, data);

			} else if (req->IsAtomicSwap()) {
				memcpy(data, req->GetData(), len);
			} else if (req->IsAtomicCompare()) {
				uint8_t *compData = req->GetCompareData();
				uint8_t *swapData = req->GetSwapData();

				if (!memcmp(data, compData, len/2)) {
					memcpy(data, swapData, len/2);
				}
			}

			DoTLM(req, tlm::TLM_WRITE_COMMAND, data, sizeof(data));

			if (!req->IsAtomicStore()) {
				DatMsg *dat = new DatMsg(req);

				m_txDatChannel.Process(dat);
			}
		}

		void DoTLM(ReqTxn *req,
				tlm::tlm_command cmd,
				uint8_t *data,
				unsigned int maxLen)
		{
			tlm::tlm_generic_payload gp;
			unsigned int len = req->GetDataLength() ;
			sc_time delay(SC_ZERO_TIME);

			assert(len <= maxLen);

			if (len > maxLen) {
				len = maxLen;
			}

			gp.set_command(cmd);
			gp.set_address(req->GetAddress());
			gp.set_data_ptr(data);
			gp.set_data_length(len);
			gp.set_streaming_width(len);

			m_init_socket->b_transport(gp, delay);

			assert(gp.get_response_status() ==
					tlm::TLM_OK_RESPONSE);
		}

		tlm_utils::simple_initiator_socket<T>& m_init_socket;
		std::list<ReqTxn*> m_txList;
		sc_event m_listEvent;

		TxnIDs& m_ids;

		TxChannel<SlaveNode_F>& m_txRspChannel;
		TxChannel<SlaveNode_F>& m_txDatChannel;

		AtomicOperations m_atomicOps;

		ReqTxn **m_txn;
	};

	class RequestOrderer :
		public sc_core::sc_module
	{
	public:
		SC_HAS_PROCESS(RequestOrderer);

		RequestOrderer(sc_core::sc_module_name name,
				TxnProcessor<SlaveNode_F>& txnProcessor) :
			sc_core::sc_module(name),
			m_txnProcessor(txnProcessor)
		{
			SC_THREAD(req_ordering_thread);
		}

		void ProcessReq(ReqTxn *req)
		{
			assert(req);
			m_reqList.push_back(req);
			m_pushEvent.notify();
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

				m_reqList.remove(req);

				// Process req now
				m_txnProcessor.RunResponsePhase(req);
			}
		}

		std::list<ReqTxn*> m_reqList;
		sc_event m_pushEvent;

		TxnProcessor<SlaveNode_F>& m_txnProcessor;
	};

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
					m_reqOrderer.ProcessReq(req);
				}

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
				uint8_t txnID = chiattr->GetTxnID();
				ReqTxn *req = m_txn[txnID];

				if (req) {
					req->CopyWriteData(trans, chiattr);

					if (req->AllWriteDataRecieved()) {
						m_txn[txnID] = NULL;
						m_ids.ReturnID(txnID);

						m_txnProcessor.RunDataPhase(req);
					}
				}

				trans.set_response_status(tlm::TLM_OK_RESPONSE);
			}
		}
	}

	void ReplyRetry(ReqTxn *req)
	{
		RspMsg *rspRetryAck = new RspMsg(req, Rsp::RetryAck, 0);
		RspMsg *rspPCrdGrant = new RspMsg(req, Rsp::PCrdGrant, 0);

		// PCrdType == 0
		m_txRspChannel.Process(rspRetryAck);
		m_txRspChannel.Process(rspPCrdGrant);
	}

	bool GetToggle()
	{
		m_toggle = (m_toggle) ? false : true;

		return m_toggle;
	}

	TxChannel<SlaveNode_F> m_txRspChannel;
	TxChannel<SlaveNode_F> m_txDatChannel;

	TxnProcessor<SlaveNode_F> m_txnProcessor;

	TxnIDs m_ids;
	ReqTxn *m_txn[TxnIDs::NumIDs];

	bool m_toggle;
	RequestOrderer m_reqOrderer;

public:
	tlm_utils::simple_initiator_socket<SlaveNode_F> init_socket;

	tlm_utils::simple_target_socket<SlaveNode_F> rxreq_tgt_socket;
	tlm_utils::simple_target_socket<SlaveNode_F> rxdat_tgt_socket;

	tlm_utils::simple_initiator_socket<SlaveNode_F> txrsp_init_socket;
	tlm_utils::simple_initiator_socket<SlaveNode_F> txdat_init_socket;

	SC_HAS_PROCESS(SlaveNode_F);

	SlaveNode_F(sc_core::sc_module_name name) :
		sc_core::sc_module(name),

		m_txRspChannel("TxRspChannel", txrsp_init_socket),
		m_txDatChannel("TxDatChannel", txdat_init_socket),

		m_txnProcessor("slave_port",
				init_socket,
				m_ids,
				m_txRspChannel,
				m_txDatChannel,
				m_txn),

		m_toggle(false),

		m_reqOrderer("reqOrderer",
				m_txnProcessor),

		init_socket("init_socket"),

		rxreq_tgt_socket("rxreq_tgt_socket"),
		rxdat_tgt_socket("rxdat_tgt_socket"),

		txrsp_init_socket("txrsp_init_socket"),
		txdat_init_socket("txdat_init_socket")

	{
		rxreq_tgt_socket.register_b_transport(
				this, &SlaveNode_F::b_transport_rxreq);
		rxdat_tgt_socket.register_b_transport(
				this, &SlaveNode_F::b_transport_rxdat);

		memset(m_txn, 0x0, sizeof(m_txn));
	}

	template<typename T>
	void connect(T& dev)
	{
		dev.rxreq_init_socket.bind(rxreq_tgt_socket);
		dev.rxdat_init_socket.bind(rxdat_tgt_socket);

		txrsp_init_socket(dev.txrsp_tgt_socket);
		txdat_init_socket(dev.txdat_tgt_socket);
	}
};

#endif /* TLM_MODULES_SN_CHI_H__ */
