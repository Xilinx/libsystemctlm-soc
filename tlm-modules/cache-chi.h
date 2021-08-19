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

#ifndef TLM_MODULES_CACHE_CHI_H__
#define TLM_MODULES_CACHE_CHI_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/chiattr.h"
#include "tlm-bridges/amba-chi.h"
#include "tlm-modules/private/chi/txnids.h"
#include "tlm-modules/private/chi/cacheline.h"
#include "tlm-modules/private/chi/txns-rn.h"

using namespace AMBA::CHI;

template<
	int NODE_ID,
	int CACHE_SZ,
	int ICN_ID = 20>
class cache_chi :
	public sc_core::sc_module
{
private:
	enum { NUM_CACHELINES = CACHE_SZ / CACHELINE_SZ };

	typedef RN::CacheLine CacheLine;
	typedef RN::ITxn<NODE_ID, ICN_ID> ITxn;
	typedef RN::ReadTxn<NODE_ID, ICN_ID> ReadTxn;
	typedef RN::DatalessTxn<NODE_ID, ICN_ID> DatalessTxn;
	typedef RN::WriteTxn<NODE_ID, ICN_ID> WriteTxn;
	typedef RN::AtomicTxn<NODE_ID, ICN_ID> AtomicTxn;
	typedef RN::DVMOpTxn<NODE_ID, ICN_ID> DVMOpTxn;
	typedef RN::SnpRespTxn<NODE_ID, ICN_ID> SnpRespTxn;

	class ITransmitter
	{
	public:
		ITransmitter() {}
		virtual ~ITransmitter() {}

		virtual void ProcessSnp(ITxn *t) = 0;
		virtual void Process(ITxn *t) = 0;
	};

	class TxChannel :
		public sc_core::sc_module
	{
	public:

		SC_HAS_PROCESS(TxChannel);

		TxChannel(sc_core::sc_module_name name,
			tlm_utils::simple_initiator_socket<cache_chi>& init_socket) :
			sc_core::sc_module(name),
			m_init_socket(init_socket),
			m_transmitter(NULL)
		{
			SC_THREAD(tx_thread);
		}

		template<typename TxnType>
		void Process(TxnType& t)
		{
			Process(&t);
			wait(t.DoneEvent());
		}

		template<typename TxnType>
		void Process(TxnType *t)
		{
			m_txList.push_back(t);
			m_listEvent.notify();
		}

		void SetTransmitter(ITransmitter *transmitter)
		{
			m_transmitter = transmitter;
		}

	private:
		void tx_thread()
		{
			while (true) {
				sc_time delay(SC_ZERO_TIME);
				ITxn *t;

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

				if (m_transmitter && t->IsSnp()) {
					m_transmitter->ProcessSnp(t);

				} else if (m_transmitter &&
						t->GetIsWriteUniqueWithCompAck()) {

					m_transmitter->Process(t);

				} else if (t->Done()) {
					t->DoneEvent().notify();
				}
				//
				// Else the txn is waiting for a response
				//
			}
		}

		tlm_utils::simple_initiator_socket<cache_chi>& m_init_socket;
		std::list<ITxn*> m_txList;
		sc_event m_listEvent;
		ITransmitter *m_transmitter;
	};

	class Transmitter :
		public ITransmitter
	{
	public:
		Transmitter(TxChannel& txRspChannel,
				TxChannel& txDatChannel) :
			m_txRspChannel(txRspChannel),
			m_txDatChannel(txDatChannel)
		{}

		void Process(ITxn *t)
		{
			if (t->TransmitOnTxDatChannel()) {
				m_txDatChannel.Process(t);
			}

			if (t->TransmitOnTxRspChannel()) {
				m_txRspChannel.Process(t);
			}

			if (t->Done()) {
				t->DoneEvent().notify();
			}
		}

		void ProcessSnp(ITxn *t)
		{
			if (t->TransmitOnTxDatChannel()) {
				m_txDatChannel.Process(t);
			} else if (t->TransmitOnTxRspChannel()) {
				m_txRspChannel.Process(t);
			} else if (t->Done()) {
				delete t;
			}

			// Else the txn is waiting on the rx channels
		}

	private:
		TxChannel& m_txRspChannel;
		TxChannel& m_txDatChannel;
	};

	class ICache
	{
	public:
		ICache(TxChannel& txReqChannel,
				TxChannel& txRspChannel,
				TxChannel& txDatChannel,
				TxnIDs *ids,
				ITxn   **txn) :
			m_cacheline(new CacheLine[NUM_CACHELINES]),
			m_txReqChannel(txReqChannel),
			m_txRspChannel(txRspChannel),
			m_txDatChannel(txDatChannel),
			m_ids(ids),
			m_txn(txn),
			m_randomize(false),
			m_seed(0)
		{
			memset(m_receivedDVM, 0, sizeof(m_receivedDVM));
		}

		virtual ~ICache()
		{
			delete[] m_cacheline;
		}

		virtual void HandleLoad(tlm::tlm_generic_payload& gp) = 0;
		virtual void HandleStore(tlm::tlm_generic_payload& gp) = 0;

		inline unsigned int get_line_offset(uint64_t addr)
		{
			return addr & (CACHELINE_SZ-1);
		}

		inline uint64_t align_address(uint64_t addr)
		{
			return addr & ~(CACHELINE_SZ-1);
		}

		inline uint64_t get_tag(uint64_t addr)
		{
			return align_address(addr);
		}

		inline uint64_t get_index(uint64_t tag)
		{
			return (tag % CACHE_SZ) / CACHELINE_SZ;
		}

		CacheLine *get_line(uint64_t addr)
		{
			uint64 tag = get_tag(addr);
			unsigned int index = get_index(tag);

			return &m_cacheline[index];
		}

		// Tag must have been checked before calling this function
		unsigned int ReadLine(tlm::tlm_generic_payload& gp, unsigned int pos)
		{
			unsigned char *data = gp.get_data_ptr() + pos;
			uint64_t addr = gp.get_address() + pos;
			unsigned int len = gp.get_data_length() - pos;
			unsigned int line_offset = get_line_offset(addr);
			unsigned int max_len = CACHELINE_SZ - line_offset;
			unsigned char *be = gp.get_byte_enable_ptr();
			unsigned int be_len = gp.get_byte_enable_length();
			CacheLine *l = get_line(addr);
			uint8_t *lineData = l->GetData();

			if (len > max_len) {
				len = max_len;
			}

			if (be_len) {
				unsigned int i;

				for (i = 0; i < len; i++, pos++) {
					bool do_access = be[pos % be_len] == TLM_BYTE_ENABLED;

					if (do_access) {
						data[i] = lineData[line_offset + i];
					}
				}
			} else {
				memcpy(data, &lineData[line_offset], len);
			}

			return len;
		}

		// Tag must have been checked before calling this function
		unsigned int WriteLine(tlm::tlm_generic_payload& gp,
					unsigned int pos)
		{
			unsigned char *data = gp.get_data_ptr() + pos;
			uint64_t addr = gp.get_address() + pos;
			unsigned int len = gp.get_data_length() - pos;
			unsigned int line_offset = get_line_offset(addr);
			unsigned int max_len = CACHELINE_SZ - line_offset;
			unsigned char *be = gp.get_byte_enable_ptr();
			unsigned int be_len = gp.get_byte_enable_length();
			CacheLine *l = get_line(addr);

			if (len > max_len) {
				len = max_len;
			}

			l->Write(line_offset, data, len, be, be_len, pos);

			if (l->GetFillGrade() != CacheLine::Empty) {
				l->SetDirty(true);
			}

			return len;
		}

		bool InCache(uint64_t addr,
				bool nonSecure,
				bool requireFullState = false)
		{
			uint64 tag = get_tag(addr);
			CacheLine *l = get_line(addr);

			if (!l->IsValid()) {
				return false;
			}

			if (requireFullState &&
				l->GetFillGrade() != CacheLine::Full) {
				return false;
			}

			return l->GetTag() == tag &&
				nonSecure == l->GetNonSecure();
		}

		bool IsUnique(uint64_t addr)
		{
			CacheLine *l = get_line(addr);

			return l->GetShared() == false;
		}

		unsigned int ToWrite(tlm::tlm_generic_payload& gp,
					unsigned int pos)
		{
			uint64_t addr = gp.get_address() + pos;
			unsigned int len = gp.get_data_length() - pos;
			unsigned int line_offset = this->get_line_offset(addr);
			unsigned int max_len = CACHELINE_SZ - line_offset;

			if (len > max_len) {
				len = max_len;
			}

			return len;
		}

		void DVMOperation(tlm::tlm_generic_payload& gp,
					chiattr_extension *chiattr)
		{
			DVMOpTxn t(gp, chiattr, m_ids);

			assert(m_txn[t.GetTxnID()] == NULL);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void AtomicNonStore(tlm::tlm_generic_payload& gp,
					chiattr_extension *chiattr)
		{
			AtomicTxn t(gp, chiattr, m_ids);

			assert(m_txn[t.GetTxnID()] == NULL);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;

			t.ReadLine(gp, 0);
		}

		void AtomicStore(tlm::tlm_generic_payload& gp,
					chiattr_extension *chiattr)
		{
			uint64_t addr = gp.get_address();
			WriteTxn t(gp, chiattr->GetOpcode(), m_ids,
					addr, 0, get_line_offset(addr));

			assert(m_txn[t.GetTxnID()] == NULL);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		unsigned int WriteNoSnp(tlm::tlm_generic_payload& gp,
					uint8_t opcode,
					uint64_t addr,
					unsigned int pos)
		{
			WriteTxn t(gp, opcode, m_ids,
					get_tag(addr), pos, get_line_offset(addr));
			unsigned int len = gp.get_data_length() - pos;

			assert(m_txn[t.GetTxnID()] == NULL);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;

			if (len > CACHELINE_SZ) {
				len = CACHELINE_SZ;
			}

			return len;
		}

		unsigned int WriteUniqueFull(tlm::tlm_generic_payload& gp,
					uint64_t addr,
					unsigned int pos)
		{
			WriteTxn t(gp, Req::WriteUniqueFull, m_ids,
					get_tag(addr), pos, get_line_offset(addr));

			t.SetExpCompAck(GetRandomBool());

			assert(m_txn[t.GetTxnID()] == NULL);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;

			return CACHELINE_SZ;
		}

		unsigned int WriteUniquePtl(tlm::tlm_generic_payload& gp,
					uint64_t addr,
					unsigned int pos)
		{
			WriteTxn t(gp, Req::WriteUniquePtl, m_ids,
					get_tag(addr), pos, get_line_offset(addr));
			unsigned int len = gp.get_data_length() - pos;

			t.SetExpCompAck(GetRandomBool());

			assert(m_txn[t.GetTxnID()] == NULL);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;

			if (len > CACHELINE_SZ) {
				len = CACHELINE_SZ;
			}

			return len;
		}

		void WriteBackFull(CacheLine *l, tlm::tlm_generic_payload& gp)
		{
			WriteTxn t(Req::WriteBackFull, l, m_ids);

			assert(l && l->IsValid() && l->GetDirty());
			assert(m_txn[t.GetTxnID()] == NULL);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void WriteBackPtl(CacheLine *l, tlm::tlm_generic_payload& gp)
		{
			WriteTxn t(Req::WriteBackPtl, l, m_ids);

			assert(l && l->IsValid() && l->GetDirty());
			assert(m_txn[t.GetTxnID()] == NULL);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void WriteCleanFull(CacheLine *l, tlm::tlm_generic_payload& gp)
		{
			WriteTxn t(Req::WriteCleanFull, l, m_ids);

			assert(l && l->IsValid() && l->GetDirty());
			assert(m_txn[t.GetTxnID()] == NULL);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void WriteEvictFull(CacheLine *l, tlm::tlm_generic_payload& gp)
		{
			WriteTxn t(Req::WriteEvictFull, l, m_ids);

			assert(l && l->IsValid() && !l->GetDirty());
			assert(m_txn[t.GetTxnID()] == NULL);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void Evict(CacheLine *l, tlm::tlm_generic_payload& gp)
		{
			DatalessTxn t(Req::Evict, l->GetTag(), l, m_ids);

			assert(l && l->IsValid());

			//
			// Special case for evict, invalidate (silent cache
			// state transition 4.6 [1]) before issuing is required
			// (4.7.2 [1]).
			//
			l->SetValid(false);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void InvalidateCacheLine(CacheLine *l,
					tlm::tlm_generic_payload& gp)
		{
			//
			// Sometimes do a WriteCleanFull first
			//
			if (l->IsDirtyFull() && GetRandomBool()) {
				WriteCleanFull(l, gp);
			}

			//
			// Line might have been invalidated by a snoop here if
			// we issued a WriteCleanFull so check if it is valid
			//
			if (l->IsValid()) {
				if (l->IsDirtyPartial()) {
					WriteBackPtl(l, gp);
				} else if ((l->IsDirty())) {
					WriteBackFull(l, gp);
				} else {
					//
					// Line is clean, if line is UC do a
					// WriteEvictFull sometimes
					//
					if (l->IsUniqueCleanFull() &&
						GetRandomBool()) {

						WriteEvictFull(l, gp);
					} else {
						Evict(l, gp);
					}
				}
			}
		}

		unsigned int ReadNoSnp(tlm::tlm_generic_payload& gp,
					uint64_t addr,
					unsigned int pos)
		{
			ReadTxn t(gp, Req::ReadNoSnp,
					get_tag(addr), // 2.10.2 + 4.2.1
					NULL,
					m_ids);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;

			return t.FetchNonCoherentData(gp,
							pos,
							get_line_offset(addr));
		}

		unsigned int ReadOnce(tlm::tlm_generic_payload& gp,
					uint8_t opcode,
					uint64_t addr,
					unsigned int pos)
		{
			CacheLine *l = get_line(addr);
			ReadTxn t(gp, opcode,
					get_tag(addr), // 2.10.2 + 4.2.1
					NULL,
					m_ids);

			//
			// Line might be in the cache but not with fillgrade
			// full
			//
			if (l->IsValid()) {
				InvalidateCacheLine(l, gp);
			}

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;

			return t.FetchNonCoherentData(gp,
							pos,
							get_line_offset(addr));
		}

		void ReadShared(tlm::tlm_generic_payload& gp,
					uint64_t addr)
		{
			CacheLine *l = get_line(addr);
			ReadTxn t(gp, Req::ReadShared,
					get_tag(addr), // 2.10.2 + 4.2.1
					l, m_ids);

			if (l->IsValid()) {
				InvalidateCacheLine(l, gp);
			}

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void ReadClean(tlm::tlm_generic_payload& gp,
					uint64_t addr)
		{
			CacheLine *l = get_line(addr);
			ReadTxn t(gp, Req::ReadClean,
					get_tag(addr), // 2.10.2 + 4.2.1
					l, m_ids);

			if (l->IsValid()) {
				InvalidateCacheLine(l, gp);
			}

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void ReadNotSharedDirty(tlm::tlm_generic_payload& gp,
					uint64_t addr)
		{
			CacheLine *l = get_line(addr);
			ReadTxn t(gp, Req::ReadNotSharedDirty,
					get_tag(addr), // 2.10.2 + 4.2.1
					l, m_ids);

			if (l->IsValid()) {
				InvalidateCacheLine(l, gp);
			}

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void ReadUnique(tlm::tlm_generic_payload& gp,
					uint64_t addr)
		{
			CacheLine *l = get_line(addr);
			ReadTxn t(gp, Req::ReadUnique,
					get_tag(addr), // 2.10.2 + 4.2.1
					l, m_ids);

			if (l->IsValid()) {
				InvalidateCacheLine(l, gp);
			}

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void MakeUnique(tlm::tlm_generic_payload& gp,
					uint64_t addr)
		{
			CacheLine *l = get_line(addr);
			DatalessTxn t(Req::MakeUnique, get_tag(addr), l, m_ids, &gp);

			if (l->IsValid()) {
				InvalidateCacheLine(l, gp);
			}

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		void CleanUnique(tlm::tlm_generic_payload& gp,
					uint64_t addr)
		{
			CacheLine *l = get_line(addr);
			DatalessTxn t(Req::CleanUnique, l->GetTag(), l, m_ids);

			m_txn[t.GetTxnID()] = &t;
			m_txReqChannel.Process(t);

			m_txn[t.GetTxnID()] = NULL;
		}

		//
		// See 4.7.6 [1]
		//
		bool HandleSnp(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			bool ret = true;
			bool nonSecure = chiattr->GetNonSecure();
			uint64_t addr = gp.get_address();
			CacheLine *l = get_line(gp.get_address());

			if (chiattr->GetOpcode() == Snp::SnpDVMOp) {
				uint8_t txnID = chiattr->GetTxnID();

				//
				// Check if the other packet to this DVM
				// request has been received, if so output a
				// response, else just mark that it was
				// received.
				//
				if (m_receivedDVM[txnID]) {
					SnpRespTxn *t = new SnpRespTxn(gp);

					m_receivedDVM[txnID] = false;

					t->SetSnpResp(INV);
					m_txRspChannel.Process(t);
				} else {
					m_receivedDVM[txnID] = true;
				}
			} else if (InCache(addr, nonSecure)) {
				switch(chiattr->GetOpcode()) {
				case Snp::SnpOnce:
					HandleSnpOnce(gp, chiattr);
					break;
				case Snp::SnpClean:
				case Snp::SnpShared:
				case Snp::SnpNotSharedDirty:
					HandleSnpClean(gp, chiattr);
					break;
				case Snp::SnpUnique:
					HandleSnpUnique(gp, chiattr);
					break;
				case Snp::SnpCleanShared:
					HandleSnpCleanShared(gp, chiattr);
					break;
				case Snp::SnpCleanInvalid:
					HandleSnpCleanInvalid(gp, chiattr);
					break;
				case Snp::SnpMakeInvalid:
					HandleSnpMakeInvalid(gp, chiattr);
					break;
				case Snp::SnpUniqueStash:
					HandleSnpUniqueStash(gp, chiattr);
					break;
				case Snp::SnpMakeInvalidStash:
					HandleSnpMakeInvalidStash(gp, chiattr);
					break;
				case Snp::SnpStashUnique:
					HandleSnpStashUnique(gp, chiattr);
					break;
				case Snp::SnpStashShared:
					HandleSnpStashShared(gp, chiattr);
					break;
				case Snp::SnpOnceFwd:
					HandleSnpOnceFwd(gp, chiattr);
					break;
				case Snp::SnpCleanFwd:
					HandleSnpCleanFwd(gp, chiattr);
					break;
				case Snp::SnpNotSharedDirtyFwd:
					HandleSnpNotSharedDirtyFwd(gp, chiattr);
					break;
				case Snp::SnpSharedFwd:
					HandleSnpSharedFwd(gp, chiattr);
					break;
				case Snp::SnpUniqueFwd:
					HandleSnpUniqueFwd(gp, chiattr);
					break;
				default:
					ret = false;
					break;
				}

				if (!l->IsValid()) {
					m_monitor.Reset(gp.get_address());
				}

			} else {
				SnpRespTxn *t = new SnpRespTxn(gp);

				t->SetSnpResp(INV);
				m_txRspChannel.Process(t);
			}

			return ret;
		}

		// Table 4-16 [1]
		void HandleSnpOnce(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// SnpRespData_UC;
				t->SetSnpRespData(UC);
				break;
			case UCE:
				// SnpResp_UC;
				t->SetSnpResp(UC);
				break;
			case UD:
				// SnpRespData_UD;
				t->SetSnpRespData(UD);
				break;
			case UDP:
				// SnpRespDataPtl_UD;
				t->SetSnpRespDataPtl(UD);
				break;
			case SC:
				if (chiattr->GetRetToSrc()) {
					// SnpRespData_SC;
					t->SetSnpRespData(SC);
				} else {
					// SnpResp_SC;
					t->SetSnpResp(SC);
				}
				break;
			case SD:
				// SnpRespData_SD;
				t->SetSnpRespData(SD);
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			}

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		// Table 4-17 [1]
		void HandleSnpClean(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// Go to SC
				l->SetShared(true);

				// SnpRespData_SC;
				t->SetSnpRespData(SC);
				break;
			case UCE:
				// Go to I
				l->SetValid(false);

				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			case UD:
				// Go to SC
				l->SetShared(true);

				// SnpRespData_SC_PD;
				t->SetSnpRespData(SC, true);
				break;
			case UDP:
				// Go to I
				l->SetValid(false);

				// SnpRespDataPtl_I_PD;
				t->SetSnpRespDataPtl(INV, true);
				break;
			case SC:
				// Stay in SC
				if (chiattr->GetRetToSrc()) {
					// SnpRespData_SC;
					t->SetSnpRespData(SC);
				} else {
					// SnpResp_SC;
					t->SetSnpResp(SC);
				}
				break;
			case SD:
				// Go to SC;
				l->SetDirty(false);

				// SnpRespData_SC_PD;
				t->SetSnpRespData(SC, true);
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			}

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		// Table 4-18 [1]
		void HandleSnpUnique(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// SnpRespData_I;
				t->SetSnpRespData(INV);
				break;
			case UCE:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			case UD:
				// SnpRespData_I_PD;
				t->SetSnpRespData(INV, true);
				break;
			case UDP:
				// SnpRespDataPtl_I_PD;
				t->SetSnpRespDataPtl(INV, true);
				break;
			case SC:
				// Stay in SC
				if (chiattr->GetRetToSrc()) {
					// SnpRespData_I;
					t->SetSnpRespData(INV);
				} else {
					// SnpResp_I;
					t->SetSnpResp(INV);
				}
				break;
			case SD:
				// SnpRespData_I_PD;
				t->SetSnpRespData(INV, true);
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			}

			//
			// Invalidate line
			//
			l->SetValid(false);

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		// Table 4-19 [1]
		void HandleSnpCleanShared(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// SnpResp_UC;
				t->SetSnpResp(UC);
				break;
			case UCE:
				// Go to I
				l->SetValid(false);

				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			case UD:
				// Go to UC
				l->SetDirty(false);

				// SnpRespData_UC_PD;
				t->SetSnpRespData(UC, true);
				break;
			case UDP:
				// Go to I
				l->SetValid(false);

				// SnpRespDataPtl_I_PD;
				t->SetSnpRespDataPtl(INV, true);
				break;
			case SC:
				// Stay in SC

				// SnpResp_SC;
				t->SetSnpResp(SC);
				break;
			case SD:
				// Go to SC
				l->SetDirty(false);

				// SnpRespData_SC_PD;
				t->SetSnpRespData(SC, true);
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			}

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		// Table 4-19 [1]
		void HandleSnpCleanInvalid(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			case UCE:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			case UD:
				// SnpRespData_I_PD;
				t->SetSnpRespData(INV, true);
				break;
			case UDP:
				// SnpRespDataPtl_I_PD;
				t->SetSnpRespDataPtl(INV, true);
				break;
			case SC:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			case SD:
				// SnpRespData_I_PD;
				t->SetSnpRespData(INV, true);
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			}

			//
			// Invalidate line
			//
			l->SetValid(false);

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		// Table 4-19 [1]
		void HandleSnpMakeInvalid(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			//
			// Invalidate line
			//
			l->SetValid(false);

			t->SetSnpResp(INV);

			m_txRspChannel.Process(t);
		}

		// Table 4-20
		void HandleSnpUniqueStash(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// SnpResp_I;
				t->SetSnpResp(INV);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			case UCE:
				// SnpResp_I;
				t->SetSnpResp(INV);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			case UD:
				// SnpRespData_I_PD;
				t->SetSnpRespData(INV, true);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			case UDP:
				// SnpRespDataPtl_I_PD;
				t->SetSnpRespDataPtl(INV, true);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			case SC:
				// SnpResp_I;
				t->SetSnpResp(INV);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			case SD:
				// SnpRespData_I_PD;
				t->SetSnpRespData(INV, true);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			}

			//
			// Invalidate line
			//
			l->SetValid(false);

			if (t->GetDataPull()) {
				t->SetupDBID(m_ids);
				m_txn[t->GetDBID()] = t;
			}

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		void HandleSnpMakeInvalidStash(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			//
			// Invalidate line
			//
			l->SetValid(false);

			t->SetSnpResp(INV);
			if (!chiattr->GetDoNotDataPull()) {
				t->SetDataPull(l, true);
				t->SetupDBID(m_ids);
				m_txn[t->GetDBID()] = t;
			}

			m_txRspChannel.Process(t);
		}

		void HandleSnpStashUnique(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// SnpResp_UC;
				t->SetSnpResp(UC);
				break;
			case UCE:
				// SnpResp_UC;
				t->SetSnpResp(UC);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			case UD:
				// SnpResp_UD;
				t->SetSnpResp(UD);
				break;
			case UDP:
				// SnpResp_UD;
				t->SetSnpResp(UD);
				break;
			case SC:
				// SnpResp_SC_Read;
				t->SetSnpResp(SC);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			case SD:
				// SnpResp_SD_Read;
				t->SetSnpResp(SD);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			}

			if (t->GetDataPull()) {
				t->SetupDBID(m_ids);
				m_txn[t->GetDBID()] = t;
			}

			m_txRspChannel.Process(t);
		}

		void HandleSnpStashShared(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// SnpResp_UC;
				t->SetSnpResp(UC);
				break;
			case UCE:
				// SnpResp_UC;
				t->SetSnpResp(UC);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			case UD:
				// SnpResp_UD;
				t->SetSnpResp(UD);
				break;
			case UDP:
				// SnpResp_UD;
				t->SetSnpResp(UD);
				break;
			case SC:
				// SnpResp_SC_Read;
				t->SetSnpResp(SC);
				break;
			case SD:
				// SnpResp_SD_Read;
				t->SetSnpResp(SD);
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				if (!chiattr->GetDoNotDataPull()) {
					t->SetDataPull(l, true);
				}
				break;
			}

			m_txRspChannel.Process(t);
		}

		// Table 4-23
		void HandleSnpOnceFwd(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// CompData_I
				t->SetCompData(l, INV);

				// SnpResp_UC_Fwded_I
				t->SetSnpRespFwded(UC, INV);
				break;
			case UCE:
				// SnpResp_UC
				t->SetSnpResp(UC);
				break;
			case UD:
				// CompData_I
				t->SetCompData(l, INV);

				// SnpResp_UD_Fwded_I
				t->SetSnpRespFwded(UD, INV);
				break;
			case UDP:
				// SnpRespDataPtl_UD
				t->SetSnpRespDataPtl(UD);
				break;
			case SC:
				// CompData_I
				t->SetCompData(l, INV);

				// SnpResp_SC_Fwded_I
				t->SetSnpRespFwded(SC, INV);
				break;
			case SD:
				// CompData_I
				t->SetCompData(l, INV);

				// SnpResp_SD_Fwded_I
				t->SetSnpRespFwded(SD, INV);
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			}

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		// Table 4-24
		void HandleSnpCleanFwd(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// Go to SC
				l->SetShared(true);

				// CompData_SC
				t->SetCompData(l, SC);

				if (chiattr->GetRetToSrc()) {
					// SnpRespData_SC_Fwded_SC
					t->SetSnpRespDataFwded(SC, SC);
				} else {
					// SnpResp_SC_Fwded_SC
					t->SetSnpRespFwded(SC, SC);
				}

				break;
			case UCE:
				// Go to I
				l->SetValid(false);

				// SnpResp_INV
				t->SetSnpResp(INV);
				break;
			case UD:
				// Go to SC
				l->SetShared(true);
				l->SetDirty(false);

				// CompData_SC
				t->SetCompData(l, SC);

				// SnpRespData_SC_PD_Fwded_SC
				t->SetSnpRespDataFwded(SC, SC, true);

				break;
			case UDP:
				// Go to I
				l->SetValid(false);

				// SnpRespDataPtl_I_PD
				t->SetSnpRespDataPtl(INV, true);
				break;
			case SC:
				// Stay in SC

				// CompData_I
				t->SetCompData(l, SC);

				if (chiattr->GetRetToSrc()) {
					// SnpRespData_SC_Fwded_SC
					t->SetSnpRespDataFwded(SC, SC);
				} else {
					// SnpResp_SC_Fwded_SC
					t->SetSnpRespFwded(SC, SC);
				}
				break;
			case SD:
				// Go to SC
				l->SetDirty(false);

				// CompData_SC
				t->SetCompData(l, SC);

				// SnpRespData_SC_PD_Fwded_SC
				t->SetSnpRespDataFwded(SC, SC, true);
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			}

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		// Table 4-25
		void HandleSnpNotSharedDirtyFwd(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// Go to SC
				l->SetShared(true);

				// CompData_SC
				t->SetCompData(l, SC);

				if (chiattr->GetRetToSrc()) {
					// SnpRespData_SC_Fwded_SC
					t->SetSnpRespDataFwded(SC, SC);
				} else {
					// SnpResp_SC_Fwded_SC
					t->SetSnpRespFwded(SC, SC);
				}

				break;
			case UCE:
				// Go to I
				l->SetValid(false);

				// SnpResp_INV
				t->SetSnpResp(INV);
				break;
			case UD:
				// Go to SC
				l->SetShared(true);
				l->SetDirty(false);

				// CompData_SC
				t->SetCompData(l, SC);

				// SnpRespData_SC_PD_Fwded_SC
				t->SetSnpRespDataFwded(SC, SC, true);

				break;
			case UDP:
				// Go to I
				l->SetValid(false);

				// SnpRespDataPtl_I_PD
				t->SetSnpRespDataPtl(INV, true);
				break;
			case SC:
				// Stay in SC

				// CompData_SC
				t->SetCompData(l, SC);

				if (chiattr->GetRetToSrc()) {
					// SnpRespData_SC_Fwded_SC
					t->SetSnpRespDataFwded(SC, SC);
				} else {
					// SnpResp_SC_Fwded_SC
					t->SetSnpRespFwded(SC, SC);
				}

				break;
			case SD:
				// Go to SC
				l->SetDirty(false);

				// CompData_SC
				t->SetCompData(l, SC);

				// SnpRespData_SC_PD_Fwded_SC
				t->SetSnpRespDataFwded(SC, SC, true);
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			}

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		// Table 4-26
		void HandleSnpSharedFwd(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// Go to SC
				l->SetShared(true);

				// CompData_SC
				t->SetCompData(l, SC);

				if (chiattr->GetRetToSrc()) {
					// SnpRespData_SC_Fwded_SC
					t->SetSnpRespDataFwded(SC, SC);
				} else {
					// SnpResp_SC_Fwded_SC
					t->SetSnpRespFwded(SC, SC);
				}

				break;
			case UCE:
				// Go to I
				l->SetValid(false);

				// SnpResp_INV
				t->SetSnpResp(INV);
				break;
			case UD:
				// Go to SC
				l->SetShared(true);
				l->SetDirty(false);

				// CompData_SC
				t->SetCompData(l, SC);

				// SnpRespData_SC_PD_Fwded_SC
				t->SetSnpRespDataFwded(SC, SC, true);

				break;
			case UDP:
				// Go to I
				l->SetValid(false);

				// SnpRespDataPtl_I_PD
				t->SetSnpRespDataPtl(INV, true);
				break;
			case SC:
				// Stay in SC

				// CompData_SC
				t->SetCompData(l, SC);

				if (chiattr->GetRetToSrc()) {
					// SnpRespData_SC_Fwded_SC
					t->SetSnpRespDataFwded(SC, SC);
				} else {
					// SnpResp_SC_Fwded_SC
					t->SetSnpRespFwded(SC, SC);
				}

				break;
			case SD:
				// Go to SC
				l->SetDirty(false);

				// CompData_SC
				t->SetCompData(l, SC);

				// SnpRespData_SC_PD_Fwded_SC
				t->SetSnpRespDataFwded(SC, SC, true);
				break;
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			}

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		// Table 4-27
		void HandleSnpUniqueFwd(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
			CacheLine *l = get_line(gp.get_address());
			SnpRespTxn *t = new SnpRespTxn(gp);

			switch (l->GetStatus()) {
			case UC:
				// CompData_UC
				t->SetCompData(l, UC);

				// SnpResp_I_Fwded_UC
				t->SetSnpRespFwded(INV, UC);
				break;
				// SnpResp_INV
				t->SetSnpResp(INV);
				break;
			case UDP:
				// SnpRespDataPtl_I_PD
				t->SetSnpRespDataPtl(INV, true);
				break;
			case SC:
				// CompData_UC
				t->SetCompData(l, UC);

				// SnpResp_I_Fwded_UC
				t->SetSnpRespFwded(INV, UC);
				break;
			case UD:
			case SD:

				// CompData_UD_PD
				t->SetCompData(l, UD, true);

				// SnpResp_I_Fwded_UD_PD
				t->SetSnpRespFwded(INV, UD, false, true);
				break;
			case UCE:
			case INV:
			default:
				// SnpResp_I;
				t->SetSnpResp(INV);
				break;
			}

			l->SetValid(false);

			if (t->GetDataToHomeNode()) {
				t->SetData(l);
				m_txDatChannel.Process(t);
			} else {
				m_txRspChannel.Process(t);
			}
		}

		void HandleSnpDVMOp(tlm::tlm_generic_payload& gp,
				chiattr_extension *chiattr)
		{
		}

		CacheLine *GetCacheLine() { return m_cacheline; }

		bool GetRandomBool()
		{
			if (m_randomize == false) {
				return false;
			}
			return rand_r(&m_seed) % 2;
		}

		int GetRandomInt(int modulo)
		{
			if (m_randomize == false) {
				return false;
			}
			return rand_r(&m_seed) % modulo;
		}

		void SetRandomize(bool val) { m_randomize = val; }

		void SetSeed(unsigned int seed) { m_seed = seed; }
		unsigned int GetSeed() { return m_seed; }

		bool AllBytesEnabled(tlm::tlm_generic_payload& gp)
		{
			unsigned char *be = gp.get_byte_enable_ptr();
			unsigned int be_len = gp.get_byte_enable_length();
			unsigned int i;

			if (be_len < CACHELINE_SZ) {
				return false;
			}

			if (be_len) {
				for (i = 0; i < be_len; i++) {
					if (be[i] != TLM_BYTE_ENABLED) {
						break;
					}
				}

				if (i != be_len) {
					return false;
				}
			}

			return true;
		}

		bool IsExclusive(tlm::tlm_generic_payload& trans)
		{
			chiattr_extension *chiattr;

			trans.get_extension(chiattr);
			if (chiattr) {
				return chiattr->GetExcl();
			}
			return false;
		}

		bool HasExclusiveOkay(tlm::tlm_generic_payload& trans)
		{
			chiattr_extension *chiattr;

			trans.get_extension(chiattr);
			if (chiattr) {
				return chiattr->GetRespErr() ==
						RespErr::ExclusiveOkay;
			}
			return false;
		}

		bool ClearExclusiveOkay(tlm::tlm_generic_payload& trans)
		{
			chiattr_extension *chiattr;

			trans.get_extension(chiattr);
			if (chiattr) {
				chiattr->SetRespErr(RespErr::Okay);
			}
			return false;
		}

		void SetExclusiveOkay(tlm::tlm_generic_payload& trans)
		{
			chiattr_extension *chiattr;

			trans.get_extension(chiattr);
			if (chiattr) {
				chiattr->SetRespErr(RespErr::ExclusiveOkay);
			}
		}

		//
		// LP exclusive monitor Section 6.2.1 [1]
		//
		class LPExclusiveMonitor
		{
		public:
			void Set(uint64_t addr)
			{
				if (!InList(addr)) {
					m_addr.push_back(addr);
				}
			}

			void Reset(uint64_t addr)
			{
				if (InList(addr)) {
					m_addr.remove(addr);
				}
			}

			bool IsSet(uint64_t addr)
			{
				return InList(addr);
			}
		private:

			bool InList(uint64_t addr)
			{
				typename std::list<uint64_t>::iterator it;

				for (it = m_addr.begin();
					it != m_addr.end(); it++) {

					if ((*it) == addr) {
						return true;
					}
				}
				return false;
			}

			std::list<uint64_t> m_addr;
		};

	protected:
		CacheLine *m_cacheline;

		TxChannel& m_txReqChannel;
		TxChannel& m_txRspChannel;
		TxChannel& m_txDatChannel;

		TxnIDs *m_ids;
		ITxn   **m_txn;

		bool m_randomize;
		unsigned int m_seed;

		LPExclusiveMonitor m_monitor;
		bool m_receivedDVM[TxnIDs::NumIDs];
	};

	class CacheWriteBack : public ICache
	{
	public:
		CacheWriteBack(TxChannel& txReqChannel,
				TxChannel& txRspChannel,
				TxChannel& txDatChannel,
				TxnIDs *ids,
				ITxn   **txn) :
			ICache(txReqChannel,
				txRspChannel,
				txDatChannel,
				ids,
				txn)
		{}

		bool GetNonSecure(tlm::tlm_generic_payload& gp)
		{
			chiattr_extension *attr;

			gp.get_extension(attr);
			if (attr) {
				return attr->GetNonSecure();
			}

			//
			// Default to be non secure access
			//
			return true;
		}

		void HandleLoad(tlm::tlm_generic_payload& gp)
		{
			bool nonSecure = this->GetNonSecure(gp);
			uint64_t addr = gp.get_address();
			unsigned int len = gp.get_data_length();
			unsigned int pos = 0;
			bool exclusive = this->IsExclusive(gp);
			bool exclusive_failed = false;

			while (pos < len) {
				if (this->InCache(addr, nonSecure, true)) {
					unsigned int n = this->ReadLine(gp, pos);
					pos+=n;
					addr+=n;
				} else {
					int randomInt = this->GetRandomInt(6);

					//
					// Randomize between different reads if not
					// exclusive. Exclusive loads always use
					// ReadShared here.
					//
					if (exclusive || randomInt == 0) {
						this->ReadShared(gp, addr);
					} else if (randomInt == 1) {
						this->ReadClean(gp, addr);
					} else if (randomInt == 2) {
						unsigned int n =
							this->ReadOnce(gp,
								Req::ReadOnce,
								addr, pos);

						pos+=n;
						addr+=n;
					} else if (randomInt == 3) {
						unsigned int n =
							this->ReadOnce(gp,
								Req::ReadOnceCleanInvalid,
								addr, pos);

						pos+=n;
						addr+=n;
					} else if (randomInt == 4) {
						unsigned int n =
							this->ReadOnce(gp,
								Req::ReadOnceMakeInvalid,
								addr, pos);

						pos+=n;
						addr+=n;
					} else {
						this->ReadNotSharedDirty(gp, addr);
					}

					if (exclusive) {
						if (!this->HasExclusiveOkay(gp)) {
							exclusive_failed = true;
						}
						this->m_monitor.Set(addr);
						this->ClearExclusiveOkay(gp);
					}
				}
			}

			if (exclusive && !exclusive_failed) {
				this->SetExclusiveOkay(gp);
			}

			gp.set_response_status(tlm::TLM_OK_RESPONSE);
		}

		void HandleStore(tlm::tlm_generic_payload& gp)
		{
			bool nonSecure = this->GetNonSecure(gp);
			uint64_t addr = gp.get_address();
			unsigned int len = gp.get_data_length();
			unsigned int pos = 0;
			bool exclusive = this->IsExclusive(gp);

			while (pos < len) {
				if (exclusive &&
					!this->m_monitor.IsSet(addr)) {
					break;
				}

				if (this->InCache(addr, nonSecure)){
					if (this->IsUnique(addr)) {
						unsigned int n = this->WriteLine(gp, pos);

						if (exclusive) {
							//
							// Exclusive sequence
							// for the line done
							//
							this->m_monitor.Reset(addr);
						}

						pos+=n;
						addr+=n;
					} else {
						this->CleanUnique(gp, addr);

						if (exclusive) {
							// exclusive failed
							if (!this->HasExclusiveOkay(gp)) {
								this->m_monitor.Reset(addr);
								break;
							}
							this->ClearExclusiveOkay(gp);
						}
					}
				} else {

					int randomInt = this->GetRandomInt(2);

					//
					// Make sure to use an operation that
					// puts the line in unique state if
					// the exclusive store has been done
					// without a paired exclusive load,
					// 6.3.3 [1]
					//
					if (exclusive || randomInt == 0) {
						unsigned int n = this->ToWrite(gp, pos);

						if (n == CACHELINE_SZ) {
							this->MakeUnique(gp, addr);
						} else {
							this->ReadUnique(gp, addr);
						}
					} else {
						unsigned int n;

						if (this->AllBytesEnabled(gp)) {
							n =this->WriteUniqueFull(gp, addr, pos);
						} else {
							n =this->WriteUniquePtl(gp, addr, pos);
						}

						pos+=n;
						addr+=n;
					}
				}
			}

			if (exclusive && pos == len) {
				this->SetExclusiveOkay(gp);
			}

			gp.set_response_status(tlm::TLM_OK_RESPONSE);
		}
	};

	bool IsPCrdGrant(chiattr_extension *attr)
	{
		return attr->GetOpcode() == Rsp::PCrdGrant;
	}

	bool IsRetryAck(chiattr_extension *attr)
	{
		return attr->GetOpcode() == Rsp::RetryAck;
	}

	virtual void b_transport_rxrsp(tlm::tlm_generic_payload& trans,
				sc_time& delay)
	{
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);

		if (trans.get_command() == tlm::TLM_IGNORE_COMMAND) {
			chiattr_extension *chiattr;

			trans.get_extension(chiattr);

			if (chiattr) {
				ITxn *t = m_txn[chiattr->GetTxnID()];

				if (t) {
					bool ret = true;

					if (IsRetryAck(chiattr)) {

						t->HandleRetryAck(chiattr);

						//
						// If got both RetryAck and
						// PCrdGrant
						//
						if (t->RetryRequest()) {
							m_txReqChannel.Process(t);
						}
					} else if (IsPCrdGrant(chiattr)) {

						t->HandlePCrdGrant(chiattr);

						//
						// If got both RetryAck and
						// PCrdGrant
						//
						if (t->RetryRequest()) {
							m_txReqChannel.Process(t);
						}
					} else {
						ret = t->HandleRxRsp(trans, chiattr);

						m_transmitter.Process(t);
					}

					if (ret) {
						trans.set_response_status(
							tlm::TLM_OK_RESPONSE);
					}
				}
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
				ITxn *t = m_txn[chiattr->GetTxnID()];

				if (t) {
					bool ret = t->HandleRxDat(trans, chiattr);

					if (t->IsSnp()) {
						//
						// Snps (data pull) only receives once
						//
						m_txn[chiattr->GetTxnID()] = NULL;
						m_transmitter.ProcessSnp(t);
					} else {
						m_transmitter.Process(t);
					}

					if (ret) {
						trans.set_response_status(
							tlm::TLM_OK_RESPONSE);
					}
				}
			}
		}
	}

	virtual void b_transport_rxsnp(tlm::tlm_generic_payload& trans,
				sc_time& delay)
	{
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);

		if (trans.get_command() == tlm::TLM_IGNORE_COMMAND) {
			chiattr_extension *chiattr;

			trans.get_extension(chiattr);

			if (chiattr) {
				bool ret = m_cache->HandleSnp(trans, chiattr);

				if (ret) {
					trans.set_response_status(
						tlm::TLM_OK_RESPONSE);
				}
			}
		}
	}

	void WriteNoSnp(tlm::tlm_generic_payload& gp)
	{
		uint64_t addr = gp.get_address();
		unsigned int len = gp.get_data_length();
		unsigned int pos = 0;

		while (pos < len) {
			unsigned int n;

			if (m_cache->AllBytesEnabled(gp)) {
				n = m_cache->WriteNoSnp(gp,
							Req::WriteUniqueFull,
							addr,
							pos);
			} else {
				n = m_cache->WriteNoSnp(gp,
							Req::WriteUniquePtl,
							addr,
							pos);
			}

			pos+=n;
			addr+=n;
		}

		gp.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	void ReadNoSnp(tlm::tlm_generic_payload& gp)
	{
		uint64_t addr = gp.get_address();
		unsigned int len = gp.get_data_length();
		unsigned int pos = 0;

		while (pos < len) {
			unsigned int n =m_cache->ReadNoSnp(gp, addr, pos);

			pos+=n;
			addr+=n;
		}

		gp.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	class NonShareableRegion
	{
	public:
		NonShareableRegion(uint64_t start, unsigned int len) :
			m_nonshareable_start(start),
			m_nonshareable_len(len)
		{}

		bool InRegion(uint64_t addr)
		{
			uint64_t m_nonshareable_end = m_nonshareable_start + m_nonshareable_len;

			return addr >= m_nonshareable_start &&
				addr < m_nonshareable_end;
		}

	private:
		const uint64_t m_nonshareable_start;
		const unsigned int m_nonshareable_len;
	};

	bool InNonShareableRegion(tlm::tlm_generic_payload& gp)
	{
		typename std::vector<NonShareableRegion>::iterator it;
		uint64_t addr = gp.get_address();

		for (it = m_regions.begin(); it != m_regions.end();
			it++) {

			if ((*it).InRegion(addr)) {
				return true;
			}
		}
		return false;
	}

	void AddNonShareableRegion(uint64_t start, unsigned int len)
	{
		NonShareableRegion region(start, len);

		m_regions.push_back(region);
	}

	bool IsAtomic(tlm::tlm_generic_payload& gp)
	{
		chiattr_extension *attr;

		gp.get_extension(attr);
		if (attr) {
			uint8_t opcode = attr->GetOpcode();

			return opcode >= Req::AtomicStore &&
				opcode <= Req::AtomicCompare;
		}

		return false;
	}

	bool IsDVMOp(tlm::tlm_generic_payload& gp)
	{
		chiattr_extension *attr;

		gp.get_extension(attr);
		if (attr) {
			return attr->GetOpcode() == Req::DVMOp;
		}

		return false;
	}

	void HandleAtomic(tlm::tlm_generic_payload& gp)
	{
		chiattr_extension *attr;

		gp.get_extension(attr);
		if (attr) {
			if (attr->GetOpcode() < Req::AtomicLoad) {
				m_cache->AtomicStore(gp, attr);
			} else {
				m_cache->AtomicNonStore(gp, attr);
			}
		}

		gp.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	void HandleDVMOperation(tlm::tlm_generic_payload& gp)
	{
		chiattr_extension *attr;

		gp.get_extension(attr);
		if (attr) {
			m_cache->DVMOperation(gp, attr);
		}

		gp.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	virtual void b_transport(tlm::tlm_generic_payload& trans,
				sc_time& delay)
	{
		m_mutex.lock();

		wait(delay);
		delay = SC_ZERO_TIME;

		if (InNonShareableRegion(trans)) {
			if (trans.is_write()) {
				WriteNoSnp(trans);
			} else if (trans.is_read()){
				ReadNoSnp(trans);
			}
		} else if (IsAtomic(trans)) {
			HandleAtomic(trans);
		} else if (IsDVMOp(trans)) {
			HandleDVMOperation(trans);
		} else {
			if (trans.is_write()) {
				m_cache->HandleStore(trans);
			} else if (trans.is_read()){
				m_cache->HandleLoad(trans);
			}
		}

		m_mutex.unlock();
	}


	TxChannel m_txReqChannel;
	TxChannel m_txRspChannel;
	TxChannel m_txDatChannel;

	Transmitter m_transmitter;

	TxnIDs  m_ids;
	ICache *m_cache;
	ITxn   *m_txn[TxnIDs::NumIDs];

	sc_mutex m_mutex;

	std::vector<NonShareableRegion> m_regions;

public:
	tlm_utils::simple_target_socket<cache_chi> target_socket;

	// Downstream
	tlm_utils::simple_initiator_socket<cache_chi> txreq_init_socket;
	tlm_utils::simple_initiator_socket<cache_chi> txrsp_init_socket;
	tlm_utils::simple_initiator_socket<cache_chi> txdat_init_socket;

	tlm_utils::simple_target_socket<cache_chi> rxrsp_tgt_socket;
	tlm_utils::simple_target_socket<cache_chi> rxdat_tgt_socket;
	tlm_utils::simple_target_socket<cache_chi> rxsnp_tgt_socket;

	SC_HAS_PROCESS(cache_chi);

	cache_chi(sc_core::sc_module_name name) :
		sc_core::sc_module(name),

		m_txReqChannel("TxReqChannel", txreq_init_socket),
		m_txRspChannel("TxRspChannel", txrsp_init_socket),
		m_txDatChannel("TxDatChannel", txdat_init_socket),
		m_transmitter(m_txRspChannel, m_txDatChannel),

		target_socket("target_socket"),

		txreq_init_socket("txreq_init_socket"),
		txrsp_init_socket("txrsp_init_socket"),
		txdat_init_socket("txdat_init_socket"),

		rxrsp_tgt_socket("rxrsp_tgt_socket"),
		rxdat_tgt_socket("rxdat_tgt_socket"),
		rxsnp_tgt_socket("rxsnp_tgt_socket")
	{
		m_txRspChannel.SetTransmitter(&m_transmitter);
		m_txDatChannel.SetTransmitter(&m_transmitter);

		memset(m_txn, 0, sizeof(m_txn));

		m_cache = new CacheWriteBack(m_txReqChannel,
						m_txRspChannel,
						m_txDatChannel,
						&m_ids,
						m_txn);

		target_socket.register_b_transport(this,
					&cache_chi::b_transport);

		rxrsp_tgt_socket.register_b_transport(this,
					&cache_chi::b_transport_rxrsp);
		rxdat_tgt_socket.register_b_transport(this,
					&cache_chi::b_transport_rxdat);
		rxsnp_tgt_socket.register_b_transport(this,
					&cache_chi::b_transport_rxsnp);
	}

	~cache_chi()
	{
		delete m_cache;
	}

	void RandomizeTransactions(bool val) { m_cache->SetRandomize(val); }

	void SetSeed(unsigned int seed) { m_cache->SetSeed(seed); }
	unsigned int GetSeed() { return m_cache->GetSeed(); }

	void CreateNonShareableRegion(uint64_t start, unsigned int len)
	{
		AddNonShareableRegion(start, len);
	}
};

#endif /* TLM_MODULES_CACHE_CHI_H__ */
