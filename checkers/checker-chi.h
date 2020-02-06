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

#ifndef CHECKER_CHI_H__
#define CHECKER_CHI_H__

#include <list>
#include <sstream>
#include <vector>
#include "checkers/utils-chi.h"
#include "checkers/flits-chi.h"

#define CHI_LCRD_ERROR "ch_lcredits"
#define CHI_REQ_ERROR "requests"
#define CHI_DAT_ERROR "dat"
#define CHI_SNP_ERROR "snp"
#define CHI_RSP_ERROR "rsp"
#define CHI_TXN_STRUCTURES_ERROR "txn_structures"
#define CHI_REQ_RETRY_ERROR "request_retry"

namespace AMBA {
namespace CHI {
namespace CHECKERS {

CHI_CHECKER(checker_ch_lcredits)
{
public:
	CHI_CHECKER_CTOR(checker_ch_lcredits)
	{
		if (m_cfg.en_check_ch_lcredits()) {
			SC_THREAD(check_ch_lcredits);
		}
	}

private:
	//
	// Link credit monitor
	//
	class LCrdMonitor
	{
	public:
		enum { MAX_CREDITS = 15 };	// 13.2.1 [1]

		LCrdMonitor(sc_in<bool >& flitv, sc_in<bool >& lcrdv) :
			m_lcrdv(lcrdv),
			m_flitv(flitv),
			m_credits(0)
		{}

		void Run()
		{
			if (m_flitv.read()) {
				m_credits--;
			}
			if (m_lcrdv.read()) {
				m_credits++;
			}

			if (!Check()) {
				std::ostringstream msg;

				msg << m_flitv.name() << " - "
					<< m_lcrdv.name()
					<< " error, counted credits: "
					<< m_credits;

				SC_REPORT_ERROR(CHI_LCRD_ERROR,
						msg.str().c_str());
			}
		}

		bool Check()
		{
			return m_credits >= 0 && m_credits <= MAX_CREDITS;
		}

		void Reset() { m_credits = 0; }
		int GetCredits() { return m_credits; }

	private:
		sc_in<bool >& m_lcrdv;
		sc_in<bool >& m_flitv;
		int m_credits;
	};

	void check_ch_lcredits()
	{
		LCrdMonitor txreq_mon(txreqflitv, txreqlcrdv);
		LCrdMonitor txrsp_mon(txrspflitv, txrsplcrdv);
		LCrdMonitor txdat_mon(txdatflitv, txdatlcrdv);

		LCrdMonitor rxrsp_mon(rxrspflitv, rxrsplcrdv);
		LCrdMonitor rxdat_mon(rxdatflitv, rxdatlcrdv);
		LCrdMonitor rxsnp_mon(rxsnpflitv, rxsnplcrdv);

		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {

				txreq_mon.Reset();
				txrsp_mon.Reset();
				txdat_mon.Reset();

				rxrsp_mon.Reset();
				rxdat_mon.Reset();
				rxsnp_mon.Reset();

				wait(resetn.posedge_event());
				continue;
			}

			txreq_mon.Run();
			txrsp_mon.Run();
			txdat_mon.Run();

			rxrsp_mon.Run();
			rxdat_mon.Run();
			rxsnp_mon.Run();
		}
	}
};

CHI_CHECKER(checker_requests)
{
public:
	CHI_CHECKER_CTOR(checker_requests)
	{
		if (m_cfg.en_check_requests()) {
			SC_THREAD(check_requests);
		}
	}

private:
	typedef typename T::ReqFlit_t ReqFlit_t;

	void CheckOpcode(ReqFlit_t& req)
	{
		bool opcode_ok = false;

		switch (req.GetOpcode()) {
		case Req::ReqLCrdReturn:
		case Req::ReadShared:
		case Req::ReadClean:
		case Req::ReadOnce:
		case Req::ReadNoSnp:
		case Req::PCrdReturn:
		case Req::ReadUnique:
		case Req::CleanShared:
		case Req::CleanInvalid:
		case Req::MakeInvalid:
		case Req::CleanUnique:
		case Req::MakeUnique:
		case Req::Evict:
		//
		// ReadNoSnpSep is only for ICN - SN, 4.2.1 [1]
		// case Req::ReadNoSnpSep:
		//
		case Req::DVMOp:
		case Req::WriteEvictFull:
		case Req::WriteCleanFull:
		case Req::WriteUniquePtl:
		case Req::WriteUniqueFull:
		case Req::WriteBackPtl:
		case Req::WriteBackFull:
		case Req::WriteNoSnpPtl:
		case Req::WriteNoSnpFull:
		case Req::WriteUniqueFullStash:
		case Req::WriteUniquePtlStash:
		case Req::StashOnceShared:
		case Req::StashOnceUnique:
		case Req::ReadOnceCleanInvalid:
		case Req::ReadOnceMakeInvalid:
		case Req::ReadNotSharedDirty:
		case Req::CleanSharedPersist:
		case Req::PrefetchTgt:
			opcode_ok = true;
			break;
		default:
			break;
		}

		if (req.GetOpcode() >= Req::AtomicStore &&
			req.GetOpcode() <= Req::AtomicCompare) {
			opcode_ok = true;
		}

		if (!opcode_ok) {
			std::ostringstream msg;

			msg << " Opcode error on: ";
			req.Dump(msg);

			SC_REPORT_ERROR(CHI_REQ_ERROR,
				msg.str().c_str());
		}
	}

	void CheckExpCompAck(ReqFlit_t& req)
	{
		bool ExpCompAck_ok = true;

		//
		// Table 2.8, 2.8.3 [1]
		//
		switch (req.GetOpcode()) {
		case Req::ReadClean:
		case Req::ReadNotSharedDirty:
		case Req::ReadShared:
		case Req::ReadUnique:
		case Req::CleanUnique:
		case Req::MakeUnique:
			if (!req.GetExpCompAck()) {
				ExpCompAck_ok = false;
			}
			break;

		case Req::CleanShared:
		case Req::CleanSharedPersist:
		case Req::CleanInvalid:
		case Req::MakeInvalid:
		case Req::WriteBackPtl:
		case Req::WriteBackFull:
		case Req::WriteCleanFull:
		case Req::AtomicStore:
		case Req::AtomicLoad:
		case Req::AtomicSwap:
		case Req::AtomicCompare:
		case Req::StashOnceShared:
		case Req::StashOnceUnique:
		case Req::Evict:
		case Req::WriteEvictFull:
		case Req::WriteNoSnpPtl:
		case Req::WriteNoSnpFull:
			if (req.GetExpCompAck()) {
				ExpCompAck_ok = false;
			}
			break;
		default:
			// For the other opcodes it is optional
			break;
		}

		if (!ExpCompAck_ok) {
			std::ostringstream msg;

			msg << "Opcode - ExpCompAck error on request: ";
			req.Dump(msg);

			SC_REPORT_ERROR(CHI_REQ_ERROR,
				msg.str().c_str());
		}
	}

	void CheckSnpAttr(ReqFlit_t& req)
	{
		bool SnpAttr_ok = true;

		//
		// Table 2.14, 2.9.6 [1]
		//
		switch (req.GetOpcode()) {
		case Req::ReadOnce:
		case Req::ReadOnceCleanInvalid:
		case Req::ReadOnceMakeInvalid:
		case Req::ReadClean:
		case Req::ReadNotSharedDirty:
		case Req::ReadShared:
		case Req::ReadUnique:
		case Req::CleanUnique:
		case Req::MakeUnique:
		case Req::StashOnceShared:
		case Req::StashOnceUnique:
		case Req::WriteBackPtl:
		case Req::WriteBackFull:
		case Req::WriteCleanFull:
		case Req::WriteEvictFull:
		case Req::WriteUniquePtl:
		case Req::WriteUniqueFull:
		case Req::WriteUniqueFullStash:
		case Req::WriteUniquePtlStash:
		case Req::Evict:
			if (!req.GetSnpAttr()) {
				SnpAttr_ok = false;
			}
			break;

		case Req::WriteNoSnpPtl:
		case Req::WriteNoSnpFull:
		case Req::ReadNoSnp:
		case Req::ReadNoSnpSep:
			if (req.GetSnpAttr()) {
				SnpAttr_ok = false;
			}
			break;
		default:
			// For the other opcodes it is optional
			break;
		}

		if (!SnpAttr_ok) {
			std::ostringstream msg;

			msg << "Opcode - SnpAttr error on request: ";
			req.Dump(msg);

			SC_REPORT_ERROR(CHI_REQ_ERROR,
				msg.str().c_str());
		}
	}

	void CheckOrder(ReqFlit_t& req)
	{
		// Table 2-7, 2.3.1 [1]
		if (req.GetOrder() == 0x1) {
			std::ostringstream msg;

			msg << "Order error (0b01) on request: ";
			req.Dump(msg);

			SC_REPORT_ERROR(CHI_REQ_ERROR,
				msg.str().c_str());
		}

		if (req.GetOrder() != 0) {
			bool order_ok;

			//
			// Other non zero order values are only allowed for
			// below opcodes, 2.8.5 [1]
			//
			switch (req.GetOpcode()) {
			case Req::ReadNoSnp:
			case Req::ReadOnce:
			case Req::ReadOnceCleanInvalid:
			case Req::ReadOnceMakeInvalid:
			case Req::WriteUniquePtl:
			case Req::WriteUniqueFull:
			case Req::AtomicStore:
			case Req::AtomicLoad:
			case Req::AtomicSwap:
			case Req::AtomicCompare:
				order_ok = true;
				break;
			default:
				order_ok = false;
				break;
			};

			if (!order_ok) {
				std::ostringstream msg;

				msg << "Opcode - Order error on request: ";
				req.Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_ERROR,
					msg.str().c_str());
			}
		}
	}

	void CheckAllowRetry(ReqFlit_t& req)
	{
		if (req.GetAllowRetry()) {
			//
			// PrefetchTgt must have AllowRetry deasserted, section
			// 2.11.2 [1]
			//
			if (req.GetOpcode() == Req::PrefetchTgt) {
				std::ostringstream msg;

				msg << "AllowRetry error (set on PrefetchTgt)"
					"  on request: ";
				req.Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_ERROR,
					msg.str().c_str());
			}
			//
			// If AllowRetry is asserted PcrdType must be 0b0000,
			// section 2.11.2 [1]
			//
			if (req.GetPCrdType()) {
				std::ostringstream msg;

				msg << "AllowRetry - PCrdType  error (PCrdType "
					"must be 0b0000) on request: ";
				req.Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_ERROR,
					msg.str().c_str());
			}

			if (req.IsPCrdReturn()) {
				std::ostringstream msg;

				//
				// Transaction is sent with credit (2.3.3 [1])
				// and transactions using a preallocated credit
				// must have AllowRetry deasserted (2.11.2 [1])
				//
				msg << "AllowRetry asserted on PCrdReturn error";
				req.Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_ERROR,
					msg.str().c_str());
			}
		}
	}

	void CheckAddress(ReqFlit_t& req)
	{
		if (req.IsAtomicCompare()) {
			// Inbound length is half outbound
			unsigned int size = 1 << req.GetSize() / 2;
			uint64_t aligned_addr = Align(req.GetAddress(), size);

			if (aligned_addr != req.GetAddress()) {
				std::ostringstream msg;

				//
				// 2.10.5 [1]
				//
				msg << "Address alignment error on "
					"AtomicCompare";
				req.Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_ERROR,
					msg.str().c_str());
			}
		} else if (req.IsAtomic()) {
			unsigned int size = 1 << req.GetSize();
			uint64_t aligned_addr = Align(req.GetAddress(), size);

			if (aligned_addr != req.GetAddress()) {
				std::ostringstream msg;

				//
				// 2.10.5 [1]
				//
				msg << "Address alignment error on "
					"atomic request";
				req.Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_ERROR,
					msg.str().c_str());
			}
		}
	}

	uint64_t Align(uint64_t addr, uint64_t alignTo)
	{
		return (addr / alignTo) * alignTo;
	}

	void CheckSize(ReqFlit_t& req)
	{
		if (req.GetSize() == Req::Size::Reserved) {
			std::ostringstream msg;

			//
			// Table 2-15 2.10.1 [1]
			//
			msg << "Size error (value reserved)";
			req.Dump(msg);

			SC_REPORT_ERROR(CHI_REQ_ERROR,
				msg.str().c_str());
		}

		if (req.IsAtomicCompare()) {
			if (req.GetSize() > Req::Size::SZ_32) {
				std::ostringstream msg;

				//
				// 4.2.4 [1]
				//
				msg << "Size error on AtomicCompare";
				req.Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_ERROR,
					msg.str().c_str());
			}
		}

		if (req.IsAtomic()) {
			if (req.GetSize() > Req::Size::SZ_8) {
				std::ostringstream msg;

				//
				// 4.2.4 [1]
				//
				msg << "Size error on atomic request";
				req.Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_ERROR,
					msg.str().c_str());
			}
		}
	}

	void CheckDVM(ReqFlit_t& req)
	{
		//
		// 8.1.4 [1]
		//
		if (req.IsDVMOp()) {
			std::ostringstream msg;
			bool dvm_ok = true;

			msg << "DVMOp error on ";

			if (req.GetReturnNID()) {
				msg << "ReturnNID";
				dvm_ok = false;
			}
			if (req.GetStashNIDValid()) {
				msg << ", StashNIDValid";
				dvm_ok = false;
			}
			if (req.GetReturnTxnID()) {
				msg << ", StashNIDValid";
				dvm_ok = false;
			}
			if (req.GetReturnTxnID()) {
				msg << ", StashNIDValid";
				dvm_ok = false;
			}
			if (req.GetSize() > DVM::DVMOpSize) {
				msg << ", Size";
				dvm_ok = false;
			}
			if (req.GetNonSecure()) {
				msg << ", NonSecure";
				dvm_ok = false;
			}
			if (req.GetLikelyShared()) {
				msg << ", LikelyShared";
				dvm_ok = false;
			}
			if (req.GetOrder()) {
				msg << ", Order";
				dvm_ok = false;
			}
			if (req.GetAllocate() || req.GetCacheable() ||
				req.GetDeviceMemory() || req.GetEarlyWrAck()) {
				msg << ", MemAttr";
				dvm_ok = false;
			}
			if (req.GetSnpAttr()) {
				msg << ", SnpAttr";
				dvm_ok = false;
			}
			if (req.GetExcl()) {
				msg << ", Excl";
				dvm_ok = false;
			}

			if (!dvm_ok) {
				req.Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_ERROR,
					msg.str().c_str());
			}
		}
	}

	void CheckExcl(ReqFlit_t& req)
	{
		bool exclusive_ok = true;;

		if (req.GetExcl()) {
			//
			// 6.3 [1]
			//
			switch (req.GetOpcode()) {
			case Req::ReadClean:
			case Req::ReadNotSharedDirty:
			case Req::ReadShared:
			case Req::CleanUnique:
			case Req::WriteNoSnpPtl:
			case Req::WriteNoSnpFull:
			case Req::ReadNoSnp:
				exclusive_ok = true;
				break;
			default:
				exclusive_ok = false;
				break;
			}

			//
			// SnoopMe uses same field and is used in Atomics
			// 12.9.27 [1]
			//
			if (req.IsAtomic()) {
				exclusive_ok = true;
			}
		}

		if (!exclusive_ok) {
			std::ostringstream msg;

			msg << "Exclusive error";
			req.Dump(msg);

			SC_REPORT_ERROR(CHI_REQ_ERROR,
				msg.str().c_str());
		}
	}

	void CheckRequest()
	{
		sc_bv<T::TXREQ_FLIT_W> flit = txreqflit.read();
		ReqFlit_t req(flit);

		CheckOpcode(req);

		CheckExpCompAck(req);

		CheckSnpAttr(req);

		CheckOrder(req);

		CheckAllowRetry(req);

		CheckAddress(req);

		CheckSize(req);

		CheckDVM(req);

		CheckExcl(req);
	}

	void check_requests()
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				wait(resetn.posedge_event());
				continue;
			}

			if (txreqflitv.read()) {
				CheckRequest();
			}
		}
	}
};

CHI_CHECKER(checker_data_flits)
{
public:
	CHI_CHECKER_CTOR(checker_data_flits)
	{
		if (m_cfg.en_check_data_flits()) {
			SC_THREAD(check_data_flits);
		}
	}

private:
	typedef typename T::DatFlit_t DatFlit_t;

	void CheckOpcode(DatFlit_t& dat)
	{
		bool opcode_ok = false;

		switch (dat.GetOpcode()) {
		case Dat::DataLCrdReturn:
		case Dat::SnpRespData:
		case Dat::CopyBackWrData:
		case Dat::NonCopyBackWrData:
		case Dat::CompData:
		case Dat::SnpRespDataPtl:
		case Dat::SnpRespDataFwded:
		case Dat::WriteDataCancel:
		case Dat::DataSepResp:
		case Dat::NCBWrDataCompAck:
			opcode_ok = true;
			break;
		default:
			break;
		}

		if (!opcode_ok) {
			std::ostringstream msg;

			msg << " Opcode error on: ";
			dat.Dump(msg);

			SC_REPORT_ERROR(CHI_DAT_ERROR,
				msg.str().c_str());
		}
	}

	void CheckDat()
	{
		sc_bv<T::TXDAT_FLIT_W> flit = txdatflit.read();
		DatFlit_t dat(flit);

		CheckOpcode(dat);
	}

	void check_data_flits()
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				wait(resetn.posedge_event());
				continue;
			}

			if (txdatflitv.read()) {
				CheckDat();
			}
		}
	}
};

CHI_CHECKER(checker_snoop_requests)
{
public:
	CHI_CHECKER_CTOR(checker_snoop_requests)
	{
		if (m_cfg.en_check_snoop_requests()) {
			SC_THREAD(check_snoop_requests);
		}
	}

private:
	typedef typename T::SnpFlit_t SnpFlit_t;

	void CheckOpcode(SnpFlit_t& snp)
	{
		bool opcode_ok = false;

		switch (snp.GetOpcode()) {
		case Snp::SnpLCrdReturn:
		case Snp::SnpShared:
		case Snp::SnpClean:
		case Snp::SnpOnce:
		case Snp::SnpNotSharedDirty:
		case Snp::SnpUniqueStash:
		case Snp::SnpMakeInvalidStash:
		case Snp::SnpUnique:
		case Snp::SnpCleanShared:
		case Snp::SnpCleanInvalid:
		case Snp::SnpMakeInvalid:
		case Snp::SnpStashUnique:
		case Snp::SnpStashShared:
		case Snp::SnpDVMOp:
		case Snp::SnpSharedFwd:
		case Snp::SnpCleanFwd:
		case Snp::SnpOnceFwd:
		case Snp::SnpNotSharedDirtyFwd:
		case Snp::SnpUniqueFwd:
			opcode_ok = true;
			break;
		default:
			break;
		}

		if (!opcode_ok) {
			std::ostringstream msg;

			msg << " Opcode error on: ";
			snp.Dump(msg);

			SC_REPORT_ERROR(CHI_SNP_ERROR,
				msg.str().c_str());
		}
	}

	void CheckDVM(SnpFlit_t& snp)
	{
		if (snp.IsSnpDVMOp()) {
			//
			// 8.1.4 [1]
			//
			if (snp.GetFwdNID()) {
				std::ostringstream msg;

				msg << "SnpDVMOp: FwdNID error on (must be "
					"zero): ";
				snp.Dump(msg);

				SC_REPORT_ERROR(CHI_SNP_ERROR,
					msg.str().c_str());
			}
			if (snp.GetNonSecure()) {
				std::ostringstream msg;

				msg << "SnpDVMOp: NonSecure error on (must be "
					"zero): ";
				snp.Dump(msg);

				SC_REPORT_ERROR(CHI_SNP_ERROR,
					msg.str().c_str());
			}

			if (snp.GetDoNotGoToSD()) {
				std::ostringstream msg;

				msg << "SnpDVMOp: DoNotGoToSD error on (must be"
					" zero): ";
				snp.Dump(msg);

				SC_REPORT_ERROR(CHI_SNP_ERROR,
					msg.str().c_str());
			}

			if (snp.GetRetToSrc()) {
				std::ostringstream msg;

				msg << "SnpDVMOp: RetToSrc error on (must be "
					"zero): ";
				snp.Dump(msg);

				SC_REPORT_ERROR(CHI_SNP_ERROR,
					msg.str().c_str());
			}
		}
	}

	void CheckSnoopRequests()
	{
		sc_bv<T::RXSNP_FLIT_W> flit = rxsnpflit.read();
		SnpFlit_t snp(flit);

		CheckOpcode(snp);

		CheckDVM(snp);
	}

	void check_snoop_requests()
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				wait(resetn.posedge_event());
				continue;
			}

			if (rxsnpflitv.read()) {
				CheckSnoopRequests();
			}
		}
	}
};

CHI_CHECKER(checker_responses)
{
public:
	CHI_CHECKER_CTOR(checker_responses)
	{
		if (m_cfg.en_check_responses()) {
			SC_THREAD(check_responses);
		}
	}

private:
	typedef typename T::RspFlit_t RspFlit_t;

	void CheckOpcode(RspFlit_t& rsp)
	{
		bool opcode_ok = false;

		switch (rsp.GetOpcode()) {
		case Rsp::RespLCrdReturn:
		case Rsp::SnpResp:
		case Rsp::CompAck:
		case Rsp::RetryAck:
		case Rsp::Comp:
		case Rsp::CompDBIDResp:
		case Rsp::DBIDResp:
		case Rsp::PCrdGrant:
		case Rsp::ReadReceipt:
		case Rsp::SnpRespFwded:
		case Rsp::RespSepData:
			opcode_ok = true;
			break;
		default:
			break;
		}

		if (!opcode_ok) {
			std::ostringstream msg;

			msg << " Opcode error on: ";
			rsp.Dump(msg);

			SC_REPORT_ERROR(CHI_RSP_ERROR,
				msg.str().c_str());
		}
	}

	void CheckResponses()
	{
		sc_bv<T::RXRSP_FLIT_W> flit = rxrspflit.read();
		RspFlit_t rsp(flit);

		CheckOpcode(rsp);
	}

	void check_responses()
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				wait(resetn.posedge_event());
				continue;
			}

			if (rxrspflitv.read()) {
				CheckResponses();
			}
		}
	}
};

CHI_CHECKER(checker_txn_structures)
{
public:
	CHI_CHECKER_CTOR(checker_txn_structures)
	{
		memset(m_txn, 0 , sizeof(m_txn));

		if (m_cfg.en_check_txn_structures()) {
			SC_THREAD(check_txn_flows);
		}
	}

	~checker_txn_structures()
	{
		Reset();
	}

private:
	enum { NUM_TXNIDS = 256, };

	typedef typename T::ReqFlit_t ReqFlit_t;
	typedef typename T::RspFlit_t RspFlit_t;
	typedef typename T::DatFlit_t DatFlit_t;
	typedef typename T::SnpFlit_t SnpFlit_t;

	class ITxn
	{
	public:
		ITxn(ReqFlit_t *req) :
			m_req(req),
			m_DBID(0),
			m_HomeNID(0),
			m_HomeNIDValid(false)
		{}

		virtual ~ITxn()
		{
			delete m_req;
		}

		virtual bool HandleRxDat(DatFlit_t& dat) = 0;
		virtual bool HandleRxRsp(RspFlit_t& rsp) = 0;

		virtual bool HandleTxDat(DatFlit_t& dat) = 0;
		virtual bool HandleTxRsp(RspFlit_t& rsp) = 0;

		virtual bool Done() = 0;

		ReqFlit_t* GetReq() { return m_req; }

		uint16_t GetTxnID() { return m_req->GetTxnID(); }

		void SetDBID(uint8_t DBID) { m_DBID = DBID; }
		uint8_t GetDBID() { return m_DBID; }

		void SetHomeNID(uint16_t HomeNID) { m_HomeNID = HomeNID; }
		uint16_t GetHomeNID() { return m_HomeNID; }

		void SetHomeNIDValid(bool HomeNIDValid)
		{
			m_HomeNIDValid = HomeNIDValid;
		}
		bool GetHomeNIDValid()
		{
			return m_HomeNIDValid;
		}
	private:
		ReqFlit_t *m_req;

		uint8_t m_DBID;
		uint16_t m_HomeNID;
		bool  m_HomeNIDValid;
	};

	class ReadTxn : public ITxn
	{
	public:
		ReadTxn(ReqFlit_t *req) :
			ITxn(req),
			m_allowSepResp(true),
			m_gotRspSepData(false),
			m_gotDataSepResp(false),
			m_gotReadReceipt(true),
			m_gotCompAck(true)
		{
			//
			// Expect CompAck if set, table 2.8, 2.8.3 [1]
			//
			if (req->GetExpCompAck()) {
				m_gotCompAck = false;
			}

			//
			// table 2-7, 2.3 [1]
			//
			// For order[1:0] == 0b10 or 0b11 and
			// ExpCompAck == 0, don't allow separate responses
			//
			if (!req->GetExpCompAck() &&
				(req->GetOrder() >> 1) & 0x1) {
				m_allowSepResp = false;
			}

			//
			// table 2-7, 2.3 [1]
			//
			// For order[1:0] == 0b10 or 0b11 expect ReadReceipt
			//
			if ((req->GetOrder() >> 1) & 0x1) {
				m_gotReadReceipt = false;
			}
		}

		bool HandleRxDat(DatFlit_t& dat)
		{
			bool datHandled = false;

			bool acceptCompData =
				m_gotRspSepData == false &&
				m_gotDataSepResp == false &&
				dat.IsCompData();

			bool acceptDataSepResp =
				m_allowSepResp &&
				m_gotDataSepResp == false &&
				dat.IsDataSepResp();

			if (acceptDataSepResp) {
				m_gotDataSepResp = true;

				// For CompAck
				this->SetHomeNID(dat.GetSrcID());
				this->SetHomeNIDValid(true);
				this->SetDBID(dat.GetDBID());

				datHandled = true;
			} else if (acceptCompData) {
				m_gotDataSepResp = true;
				m_gotRspSepData = true;

				// Store for CompAck
				this->SetHomeNID(dat.GetHomeNID());
				this->SetHomeNIDValid(true);
				this->SetDBID(dat.GetDBID());

				datHandled = true;
			}

			return datHandled;
		}

		bool HandleRxRsp(RspFlit_t& rsp)
		{
			bool rspHandled = false;

			bool acceptRspSepData =
				m_allowSepResp &&
				m_gotRspSepData == false &&
				rsp.IsRespSepData();

			bool acceptReadReceipt =
				m_gotReadReceipt == false &&
				rsp.IsReadReceipt();

			if (acceptRspSepData) {
				m_gotRspSepData = true;

				//
				// table 2-7 [1], RspSepData == ReadReceipt if sent.
				//
				m_gotReadReceipt = true;

				// For CompAck
				this->SetHomeNID(rsp.GetSrcID());
				this->SetHomeNIDValid(true);
				this->SetDBID(rsp.GetDBID());

				rspHandled = true;
			} else if (acceptReadReceipt) {
				m_gotReadReceipt = true;

				rspHandled = true;
			}

			return rspHandled;
		}

		// Never transmits
		bool HandleTxDat(DatFlit_t& dat) { return false; }

		bool HandleTxRsp(RspFlit_t& rsp)
		{
			bool rspHandled = false;

			bool acceptCompAck =
				m_gotCompAck == false &&
				rsp.IsCompAck();

			if (acceptCompAck) {
				m_gotCompAck = true;
				rspHandled = true;
			}

			return rspHandled;
		}

		bool Done()
		{
			return m_gotRspSepData &&
				m_gotDataSepResp &&
				m_gotReadReceipt &&
				m_gotCompAck;
		}

	private:
		bool m_allowSepResp;
		bool m_gotRspSepData;
		bool m_gotDataSepResp;
		bool m_gotReadReceipt;
		bool m_gotCompAck;
	};

	class DatalessTxn : public ITxn
	{
	public:
		DatalessTxn(ReqFlit_t *req) :
			ITxn(req),
			m_gotComp(false),
			m_gotCompAck(true)
		{
			if (req->GetExpCompAck()) {
				m_gotCompAck = false;
			}
		}

		// Dataless
		bool HandleTxDat(DatFlit_t& dat) { return false; }
		bool HandleRxDat(DatFlit_t& dat) { return false; }

		bool HandleRxRsp(RspFlit_t& rsp)
		{
			bool rspHandled = false;

			if (m_gotComp == false && rsp.IsComp()) {
				m_gotComp = true;

				// Store for CompAck
				this->SetHomeNID(rsp.GetSrcID());
				this->SetHomeNIDValid(true);
				this->SetDBID(rsp.GetDBID());

				rspHandled = true;
			}

			return rspHandled;
		}

		bool HandleTxRsp(RspFlit_t& rsp)
		{
			bool rspHandled = false;

			if (m_gotCompAck == false && rsp.IsCompAck()) {
				m_gotCompAck = true;
				rspHandled = true;
			}

			return rspHandled;
		}

		bool Done()
		{
			return m_gotComp && m_gotCompAck;
		}

	private:
		bool m_gotComp;
		bool m_gotCompAck;
	};

	class AtomicTxn : public ITxn
	{
	public:
		AtomicTxn(ReqFlit_t *req) :
			ITxn(req),
			m_gotDBID(false),
			m_gotCompData(false),
			m_gotTxDat(false)
		{}

		bool HandleTxDat(DatFlit_t& dat)
		{
			bool datHandled = false;

			if (!m_gotTxDat && dat.IsNonCopyBackWrData()) {

				m_gotTxDat = true;
				datHandled = true;
			}

			return datHandled;
		}

		bool HandleRxDat(DatFlit_t& dat)
		{
			bool rspHandled = false;

			if (!m_gotCompData && dat.IsCompData()) {

				m_gotCompData = true;
				rspHandled = true;
			}

			return rspHandled;
		}

		bool HandleRxRsp(RspFlit_t& rsp)
		{
			bool rspHandled = false;

			if (m_gotDBID == false && rsp.IsDBIDResp()) {

				m_gotDBID = true;

				// Store for WriteData
				this->SetHomeNID(rsp.GetSrcID());
				this->SetHomeNIDValid(true);
				this->SetDBID(rsp.GetDBID());

				rspHandled = true;
			}

			return rspHandled;
		}

		bool HandleTxRsp(RspFlit_t& rsp) { return false; }

		bool Done()
		{
			return m_gotDBID &&
				m_gotCompData &&
				m_gotTxDat;
		}

	private:
		bool m_gotDBID;
		bool m_gotCompData;
		bool m_gotTxDat;
	};

	class WriteTxn : public ITxn
	{
	public:
		WriteTxn(ReqFlit_t *req) :
			ITxn(req),
			m_gotDBID(false),
			m_gotComp(false),
			m_gotCompAck(true),
			m_gotTxDat(false)
		{
			if (req->GetExpCompAck()) {
				m_gotCompAck = false;
			}
		}

		bool HandleTxDat(DatFlit_t& dat)
		{
			bool datHandled = false;

			if (dat.IsCopyBackWrData() ||
				dat.IsNonCopyBackWrData()) {

				m_gotTxDat = true;

				datHandled = true;

			} else if (dat.IsNCBWrDataCompAck()) {
				m_gotTxDat = true;
				m_gotCompAck = true;
				datHandled = true;
			}

			return datHandled;
		}

		// Never receives
		bool HandleRxDat(DatFlit_t& dat) { return false; }

		bool HandleRxRsp(RspFlit_t& rsp)
		{
			bool rspHandled = false;

			bool acceptCompDBID = !m_gotComp &&
						!m_gotDBID &&
						rsp.IsCompDBIDResp();

			if (m_gotComp == false && rsp.IsComp()) {

				m_gotComp = true;

				// Store for WriteData
				this->SetHomeNID(rsp.GetSrcID());
				this->SetHomeNIDValid(true);
				this->SetDBID(rsp.GetDBID());

				rspHandled = true;

			} else if (m_gotDBID == false && rsp.IsDBIDResp()) {

				m_gotDBID = true;

				// Store for WriteData
				this->SetHomeNID(rsp.GetSrcID());
				this->SetHomeNIDValid(true);
				this->SetDBID(rsp.GetDBID());

				rspHandled = true;

			} else if (acceptCompDBID) {

				m_gotComp = true;
				m_gotDBID = true;

				// Store for WriteData
				this->SetHomeNID(rsp.GetSrcID());
				this->SetHomeNIDValid(true);
				this->SetDBID(rsp.GetDBID());

				rspHandled = true;
			}

			return rspHandled;
		}

		bool HandleTxRsp(RspFlit_t& rsp)
		{
			bool rspHandled = false;

			if (m_gotCompAck == false && rsp.IsCompAck()) {
				m_gotCompAck = true;
				rspHandled = true;
			}

			return rspHandled;
		}

		bool Done()
		{
			return m_gotDBID &&
				m_gotComp &&
				m_gotCompAck &&
				m_gotTxDat;
		}

	private:
		bool m_gotDBID;
		bool m_gotComp;
		bool m_gotCompAck;
		bool m_gotTxDat;
	};

	class SnpFwdTxn
	{
	public:
		SnpFwdTxn(SnpFlit_t *snp) :
			m_snp(snp),
			m_gotCompData(false),
			m_snpDone(false)
		{}

		~SnpFwdTxn()
		{
			delete m_snp;
		}

		bool HandleTxDat(DatFlit_t& dat)
		{
			bool datHandled = false;

			if (m_snpDone == false && dat.IsSnoopResponse()) {
				//
				// Don't expect CompData if we got SnpRespData or
				// SnpRespDataPtl instead of SnpRespDataFwded
				//
				if (!dat.IsSnpRespDataFwded()) {
					m_gotCompData = true;
				}

				m_snpDone = true;
				datHandled = true;
			} else if (m_gotCompData == false &&
					dat.IsCompData()) {
				m_gotCompData = true;
				datHandled = true;
			}

			return datHandled;
		}

		bool HandleTxRsp(RspFlit_t& rsp)
		{
			bool rspHandled = false;

			if (m_snpDone == false) {
				//
				// Don't expect CompData if we got SnpResp
				// instead of SnpRespFwded
				//
				if (!rsp.IsSnpRespFwded()) {
					m_gotCompData = true;
				}

				m_snpDone = true;
				rspHandled = true;
			}
			return rspHandled;
		}

		bool Done()
		{
			return m_gotCompData && m_snpDone;
		}

		uint8_t GetTxnID() { return m_snp->GetTxnID(); }

		uint16_t GetFwdNID() { return m_snp->GetFwdNID(); }
		uint8_t GetFwdTxnID() { return m_snp->GetFwdTxnID(); }
		uint8_t GetSnpRespDone() { return m_snpDone; }

	private:
		SnpFlit_t *m_snp;
		bool m_gotCompData;
		bool m_snpDone;
	};

	class SnpStashTxn
	{
	public:
		SnpStashTxn(SnpFlit_t *snp) :
			m_snp(snp),
			m_sentSnpResp(false),
			m_expCompData(false),
			m_gotCompData(false),
			m_sentCompAck(false),
			m_HomeNID(0),
			m_HomeNIDValid(false),
			m_DBID(0),
			m_DBIDForCompData(0)
		{}

		~SnpStashTxn()
		{
			delete m_snp;
		}

		bool HandleTxRsp(RspFlit_t& rsp)
		{
			bool rspHandled = false;

			if (m_sentSnpResp == false && rsp.IsSnpResp()) {
				m_sentSnpResp = true;

				if (!rsp.GetDataPull()) {
					m_gotCompData = true;
					m_sentCompAck = true;
				} else {
					// TxnID for CompData
					m_DBIDForCompData = rsp.GetDBID();
					m_expCompData = true;
				}

				rspHandled = true;
			} else if (m_sentCompAck == false && rsp.IsCompAck()) {
				m_sentCompAck = true;
				rspHandled = true;
			}
			return rspHandled;
		}

		bool HandleTxDat(DatFlit_t& dat)
		{
			bool datHandled = false;
			bool isSnpRespData =
				dat.IsSnpRespData() || dat.IsSnpRespDataPtl();

			if (m_sentSnpResp == false && isSnpRespData) {
				m_sentSnpResp = true;

				if (!dat.GetDataPull()) {
					m_gotCompData = true;
					m_sentCompAck = true;
				} else {
					// TxnID for CompData
					m_DBIDForCompData = dat.GetDBID();
					m_expCompData = true;
				}

				datHandled = true;
			}
			return datHandled;
		}

		bool HandleRxDat(DatFlit_t& dat)
		{
			bool datHandled = false;

			bool acceptCompData =
				m_gotCompData == false &&
				dat.IsCompData();

			if (acceptCompData) {
				m_gotCompData = true;

				// Store for CompAck
				m_HomeNID = dat.GetHomeNID();
				m_HomeNIDValid = true;
				m_DBID = dat.GetDBID();

				datHandled = true;
			}

			return datHandled;
		}

		bool Done()
		{
			return m_sentSnpResp && m_gotCompData && m_sentCompAck;
		}

		uint8_t GetTxnID() { return m_snp->GetTxnID(); }

		uint8_t GetDBIDForCompData() { return m_DBIDForCompData; }
		uint8_t GetDBID() { return m_DBID; }
		uint16_t GetHomeNID() { return m_HomeNID; }
		bool GetHomeNIDValid() { return m_HomeNIDValid; }
		bool GetExpCompData() { return m_expCompData; }
	private:
		SnpFlit_t *m_snp;

		bool m_sentSnpResp;
		bool m_expCompData;
		bool m_gotCompData;
		bool m_sentCompAck;

		uint16_t m_HomeNID;
		bool m_HomeNIDValid;
		uint8_t m_DBID;
		uint8_t m_DBIDForCompData;
	};

	class SnpNonFwdNonStashTxn
	{
	public:
		SnpNonFwdNonStashTxn(SnpFlit_t *snp) :
			m_snp(snp),
			m_snpDone(false)
		{}

		~SnpNonFwdNonStashTxn()
		{
			delete m_snp;
		}

		bool HandleTxRsp(RspFlit_t& rsp)
		{
			bool rspHandled = false;

			if (m_snpDone == false && rsp.IsSnpResp()) {
				m_snpDone = true;
				rspHandled = true;
			}
			return rspHandled;
		}

		bool HandleTxDat(DatFlit_t& dat)
		{
			bool datHandled = false;
			bool isSnpRespData =
				dat.IsSnpRespData() || dat.IsSnpRespDataPtl();

			if (m_snpDone == false && isSnpRespData) {
				m_snpDone = true;
				datHandled = true;
			}
			return datHandled;
		}

		bool Done()
		{
			return m_snpDone;
		}

		uint8_t GetTxnID() { return m_snp->GetTxnID(); }
	private:
		SnpFlit_t *m_snp;
		bool m_snpDone;
	};

	ITxn *GetTxnWithIDs(uint16_t HomeNID, uint8_t DBID)
	{
		int i;

		for (i = 0; i < NUM_TXNIDS; i++) {
			ITxn *t = m_txn[i];

			if (t && t->GetHomeNIDValid() &&
				t->GetHomeNID() == HomeNID &&
				t->GetDBID() == DBID) {
				return t;
			}
		}

		return NULL;
	}

	void CheckTxnID(ReqFlit_t *req)
	{
		uint8_t txnID = req->GetTxnID();

		if (m_txn[txnID]) {
			std::ostringstream msg;

			msg << "Duplicate ID detected on: ";
			req->Dump(msg);

			SC_REPORT_ERROR(CHI_TXN_STRUCTURES_ERROR,
				msg.str().c_str());
		}
	}

	SnpFwdTxn *LookupSnpFwd(uint8_t txnID)
	{
		typename std::list<SnpFwdTxn*>::iterator it;

		for (it = m_snpFwdList.begin(); it != m_snpFwdList.end(); it++) {
			SnpFwdTxn *snp = (*it);

			if (snp->GetTxnID() == txnID) {
				return snp;
			}
		}
		return NULL;
	}

	SnpFwdTxn *LookupSnpFwd(uint16_t TgtID, uint8_t txnID)
	{
		typename std::list<SnpFwdTxn*>::iterator it;

		for (it = m_snpFwdList.begin(); it != m_snpFwdList.end(); it++) {
			SnpFwdTxn *snp = (*it);

			if (snp->GetSnpRespDone() &&
				snp->GetFwdNID() == TgtID &&
				snp->GetFwdTxnID() == txnID) {
				return snp;
			}
		}
		return NULL;
	}

	SnpNonFwdNonStashTxn *LookupSnp(uint8_t txnID)
	{
		typename std::list<SnpNonFwdNonStashTxn*>::iterator it;

		for (it = m_snpList.begin(); it != m_snpList.end(); it++) {
			SnpNonFwdNonStashTxn *snp = (*it);

			if (snp->GetTxnID() == txnID) {
				return snp;
			}
		}
		return NULL;
	}

	SnpStashTxn *LookupSnpStash(uint16_t TgtID, uint8_t txnID)
	{
		typename std::list<SnpStashTxn*>::iterator it;

		for (it = m_snpStashList.begin(); it != m_snpStashList.end(); it++) {
			SnpStashTxn *snp = (*it);

			if (snp->GetHomeNIDValid() &&
				snp->GetHomeNID() == TgtID &&
				snp->GetDBID() == txnID) {
				return snp;
			}
		}
		return NULL;
	}

	SnpStashTxn *LookupSnpStash(DatFlit_t& dat)
	{
		typename std::list<SnpStashTxn*>::iterator it;

		for (it = m_snpStashList.begin(); it != m_snpStashList.end(); it++) {
			SnpStashTxn *snp = (*it);

			if (snp->GetExpCompData() &&
				dat.GetTxnID() == snp->GetDBIDForCompData()) {
				return snp;
			}
		}
		return NULL;
	}

	SnpStashTxn *LookupSnpStash(uint8_t txnID)
	{
		typename std::list<SnpStashTxn*>::iterator it;

		for (it = m_snpStashList.begin(); it != m_snpStashList.end(); it++) {
			SnpStashTxn *snpStash = (*it);

			if (snpStash->GetTxnID() == txnID) {
				return snpStash;
			}
		}
		return NULL;
	}

	bool SnpFwdHandleTxDat(DatFlit_t& dat)
	{
		SnpFwdTxn *snpFwd = LookupSnpFwd(dat.GetTxnID());
		bool datHandled = false;

		if (snpFwd) {
			datHandled = snpFwd->HandleTxDat(dat);
			if (snpFwd->Done()) {
				m_snpFwdList.remove(snpFwd);
				delete snpFwd;
			}
		}
		return datHandled;
	}

	bool SnpStashHandleTxDat(DatFlit_t& dat)
	{
		SnpStashTxn *snpStash = LookupSnpStash(dat.GetTxnID());
		bool datHandled = false;

		if (snpStash) {
			datHandled = snpStash->HandleTxDat(dat);
			if (snpStash->Done()) {
				m_snpStashList.remove(snpStash);
				delete snpStash;
			}
		}
		return datHandled;
	}

	bool SnpHandleTxDat(DatFlit_t& dat)
	{
		SnpNonFwdNonStashTxn *snp = LookupSnp(dat.GetTxnID());
		bool datHandled = false;

		if (snp) {
			datHandled = snp->HandleTxDat(dat);
			if (snp->Done()) {
				m_snpList.remove(snp);
				delete snp;
			}
		}
		return datHandled;
	}

	bool SnpFwdHandleTxRsp(RspFlit_t& rsp)
	{
		SnpFwdTxn *snpFwd = LookupSnpFwd(rsp.GetTxnID());
		bool rspHandled = false;

		if (snpFwd) {
			rspHandled = snpFwd->HandleTxRsp(rsp);
			if (snpFwd->Done()) {
				m_snpFwdList.remove(snpFwd);
				delete snpFwd;
			}
		}
		return rspHandled;
	}

	bool SnpStashHandleTxRsp(RspFlit_t& rsp)
	{
		SnpStashTxn *snpStash = NULL;
		bool rspHandled = false;

		if (rsp.IsSnpResp()) {
			snpStash = LookupSnpStash(rsp.GetTxnID());
		} else if (rsp.IsCompAck()) {
			snpStash = LookupSnpStash(rsp.GetTgtID(), rsp.GetTxnID());
		}

		if (snpStash) {
			rspHandled = snpStash->HandleTxRsp(rsp);
			if (snpStash->Done()) {
				m_snpStashList.remove(snpStash);
				delete snpStash;
			}
		}
		return rspHandled;
	}

	bool SnpHandleTxRsp(RspFlit_t& rsp)
	{
		SnpNonFwdNonStashTxn *snp = LookupSnp(rsp.GetTxnID());
		bool rspHandled = false;

		if (snp) {
			rspHandled = snp->HandleTxRsp(rsp);
			if (snp->Done()) {
				m_snpList.remove(snp);
				delete snp;
			}
		}
		return rspHandled;
	}

	void HandleTxDat()
	{
		sc_bv<T::TXDAT_FLIT_W> flit = txdatflit.read();
		DatFlit_t dat(flit);
		bool datHandled = false;

		// Ignore L-Credit returns
		if (dat.IsLCrdReturn()) {
			return;
		}

		if (!dat.IsSnoopResponse()) {
			ITxn *t = GetTxnWithIDs(dat.GetTgtID(), dat.GetTxnID());

			if (t) {
				datHandled = t->HandleTxDat(dat);
				if (t->Done()) {
					m_txn[t->GetTxnID()] = NULL;
					delete t;
				}
			}

			if (!datHandled) {
				// Check if there is a SnpFwdTxn
				//
				SnpFwdTxn *snp = LookupSnpFwd(dat.GetTgtID(),
								dat.GetTxnID());

				if (snp) {
					datHandled = snp->HandleTxDat(dat);
					if (snp->Done()) {
						m_snpFwdList.remove(snp);
						delete snp;
					}
				}
			}

		} else {
			datHandled = SnpFwdHandleTxDat(dat);
			if (!datHandled) {
				//
				// Try Stash snoops
				//
				datHandled = SnpStashHandleTxDat(dat);
			}
			if (!datHandled) {
				//
				// Try nonFwd nonStash snoops
				//
				datHandled = SnpHandleTxDat(dat);
			}
		}

		if (!datHandled) {
			std::ostringstream msg;

			msg << "No outstanding request found for datflit on "
				"TXDAT: ";
			dat.Dump(msg);

			SC_REPORT_ERROR(CHI_TXN_STRUCTURES_ERROR,
				msg.str().c_str());
		}
	}

	void HandleTxRsp()
	{
		sc_bv<T::TXRSP_FLIT_W> flit = txrspflit.read();
		RspFlit_t rsp(flit);
		bool rspHandled = false;

		// Ignore L-Credit returns
		if (rsp.IsLCrdReturn()) {
			return;
		}

		if (!rsp.IsSnoopResponse()) {
			ITxn *t = GetTxnWithIDs(rsp.GetTgtID(), rsp.GetTxnID());

			if (t) {
				rspHandled = t->HandleTxRsp(rsp);
				if (t->Done()) {
					m_txn[t->GetTxnID()] = NULL;
					delete t;
				}
			}
			if (!rspHandled) {
				//
				// Try Stash snoops (CompAck)
				//
				rspHandled = SnpStashHandleTxRsp(rsp);
			}
		} else {
			rspHandled = SnpFwdHandleTxRsp(rsp);;
			if (!rspHandled) {
				//
				// Try Stash snoops (SnpResp)
				//
				rspHandled = SnpStashHandleTxRsp(rsp);
			}
			if (!rspHandled) {
				//
				// Try nonFwd nonStash snoops
				//
				rspHandled = SnpHandleTxRsp(rsp);
			}
		}

		if (!rspHandled) {
			std::ostringstream msg;

			msg << "No outstanding request found for rspflit on "
				"TXRSP: ";
			rsp.Dump(msg);

			SC_REPORT_ERROR(CHI_TXN_STRUCTURES_ERROR,
				msg.str().c_str());
		}
	}

	void HandleRxDat()
	{
		sc_bv<T::RXDAT_FLIT_W> flit = rxdatflit.read();
		DatFlit_t dat(flit);
		bool datHandled = false;
		ITxn *t = m_txn[dat.GetTxnID()];

		// Ignore L-Credit returns
		if (dat.IsLCrdReturn()) {
			return;
		}

		if (t) {
			datHandled = t->HandleRxDat(dat);
			if (t->Done()) {
				m_txn[t->GetTxnID()] = NULL;
				delete t;
			}
		} else {
			//
			// Check Snp[*]Stash transactions
			//
			SnpStashTxn *snpStash = LookupSnpStash(dat);
			if (snpStash) {
				datHandled = snpStash->HandleRxDat(dat);
			}
		}

		if (!datHandled) {
			std::ostringstream msg;

			msg << "No outstanding request found for datflit on "
				"RXDAT: ";
			dat.Dump(msg);

			SC_REPORT_ERROR(CHI_TXN_STRUCTURES_ERROR,
				msg.str().c_str());
		}
	}

	void HandleRxRsp()
	{
		sc_bv<T::RXRSP_FLIT_W> flit = rxrspflit.read();
		RspFlit_t rsp(flit);
		bool rspHandled = false;
		ITxn *t;

		// Ignore L-Credit returns
		if (rsp.IsLCrdReturn()) {
			return;
		}

		//
		// Ignore PCrdGrant
		//
		if (rsp.IsPCrdGrant()) {
			return;
		}

		t = m_txn[rsp.GetTxnID()];

		if (t) {
			if (rsp.IsRetryAck()) {
				//
				// Handle RetryAck as if it means that the
				// transactions will be restarted here.
				//
				m_txn[rsp.GetTxnID()] = NULL;
				delete t;
				rspHandled = true;

			} else {
				rspHandled = t->HandleRxRsp(rsp);

				if (t->Done()) {
					m_txn[t->GetTxnID()] = NULL;
					delete t;
				}
			}
		}

		if (!rspHandled) {
			std::ostringstream msg;

			msg << "No outstanding request found for rspflit on "
				"RXRSP: ";
			rsp.Dump(msg);

			SC_REPORT_ERROR(CHI_TXN_STRUCTURES_ERROR,
				msg.str().c_str());
		}
	}

	void SampleSnpReq()
	{
		sc_bv<T::RXSNP_FLIT_W> flit = rxsnpflit.read();
		SnpFlit_t *snp = new SnpFlit_t(flit);

		if (snp->IsLCrdReturn()) {

			delete snp;

		} else if (snp->IsSnpFwd()) {
			SnpFwdTxn *m_snpFwd = new SnpFwdTxn(snp);

			m_snpFwdList.push_back(m_snpFwd);
		} else if (snp->IsSnpDVMOp()) {
			SnpNonFwdNonStashTxn *m_snp = LookupSnp(snp->GetTxnID());
			if (!m_snp) {
				m_snp = new SnpNonFwdNonStashTxn(snp);
				m_snpList.push_back(m_snp);
			} else {
				// Second message for the SnpDVMOp
				delete snp;
			}
		} else if (snp->IsSnpStash()) {
			SnpStashTxn *m_snp = new SnpStashTxn(snp);

			m_snpStashList.push_back(m_snp);
		} else {
			SnpNonFwdNonStashTxn *m_snp = new SnpNonFwdNonStashTxn(snp);

			m_snpList.push_back(m_snp);
		}
	}

	void SampleRequest()
	{
		sc_bv<T::TXREQ_FLIT_W> flit = txreqflit.read();
		ReqFlit_t *req = new ReqFlit_t(flit);
		uint8_t txnID = req->GetTxnID();

		if (!req->IsPrefetchTgt() && !req->IsPCrdReturn() &&
			!req->IsReqLCrdReturn()) {
			CheckTxnID(req);
		}

		if (req->IsRead()) {
			ReadTxn *t = new ReadTxn(req);

			m_txn[txnID] = t;

		} else if (req->IsDataless()) {
			DatalessTxn *t = new DatalessTxn(req);

			m_txn[txnID] = t;

		} else if (req->IsWrite() ||
				req->IsAtomicStore() ||
				req->IsDVMOp()) {

			WriteTxn *t = new WriteTxn(req);

			m_txn[txnID] = t;
		} else if (req->IsAtomic()) {
			AtomicTxn *t = new AtomicTxn(req);

			m_txn[txnID] = t;
		} else {
			//
			// unchecked req at the moment
			//
			delete req;
		}
	}

	template<typename ListType>
	void ClearList(std::list<ListType*>& l)
	{
		typename std::list<ListType*>::iterator it;

		for (it = l.begin(); it != l.end(); it++) {
			ListType *t = (*it);
			delete t;

		}
		l.clear();
	}

	void Reset()
	{
		int i;

		for (i = 0; i < NUM_TXNIDS; i++) {
			ITxn *t = m_txn[i];

			if (t) {
				m_txn[i] = NULL;
				delete t;
			}
		}

		ClearList(m_snpFwdList);
		ClearList(m_snpList);
		ClearList(m_snpStashList);
	}

	void check_txn_flows()
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				Reset();
				wait(resetn.posedge_event());
				continue;
			}

			if (txreqflitv.read()) {
				SampleRequest();
			}

			if (txdatflitv.read()) {
				HandleTxDat();
			}

			if (txrspflitv.read()) {
				HandleTxRsp();
			}

			if (rxdatflitv.read()) {
				HandleRxDat();
			}

			if (rxrspflitv.read()) {
				HandleRxRsp();
			}

			if (rxsnpflitv.read()) {
				SampleSnpReq();
			}
		}
	}

	ITxn *m_txn[NUM_TXNIDS];
	std::list<SnpFwdTxn*> m_snpFwdList;
	std::list<SnpNonFwdNonStashTxn*> m_snpList;
	std::list<SnpStashTxn*> m_snpStashList;
};

CHI_CHECKER(checker_request_retry)
{
public:
	CHI_CHECKER_CTOR(checker_request_retry)
	{
		memset(m_txn, 0 , sizeof(m_txn));

		if (m_cfg.en_check_request_retry()) {
			SC_THREAD(check_request_retry);
		}
	}

	~checker_request_retry()
	{
		Reset();
	}

private:
	enum { NUM_TXNIDS = 256, };

	typedef typename T::ReqFlit_t ReqFlit_t;
	typedef typename T::RspFlit_t RspFlit_t;
	typedef typename T::DatFlit_t DatFlit_t;

	class PCredits
	{
	public:
		PCredits() :
			m_numPCredits(0)
		{}

		~PCredits()
		{
			ClearReqs();
		}

		void ClearReqs()
		{
			typename std::list<ReqFlit_t*>::iterator it;

			for (it = m_reqs.begin(); it != m_reqs.end(); it++) {
				ReqFlit_t *req = (*it);
				delete req;

			}
			m_reqs.clear();
		}

		void AddRequest(ReqFlit_t *req)
		{
			m_reqs.push_back(req);
		}

		void IncNumPCredits() { m_numPCredits++; }

		void DecNumPCredits()
		{
			m_numPCredits--;

			//
			// If multiple credits have been assigned to an RN the
			// RN decides which requests it will use the credits on
			// meaning that there is no one to one mapping between
			// credits and transactions (2.11 [1]). This forces a
			// wait until all credits have been removed before
			// deleting the retried requests in the checker.
			//
			if (m_numPCredits == 0 && m_reqs.size() > 0) {
				ClearReqs();
			}
		}

		unsigned int GetNumPCredits() { return m_numPCredits; }

		bool Check()
		{
			//
			// Once there are no outstanding transactions from the
			// RN all given PCrdGrants also needs to have been
			// accompanied with a RetryAck. But since there is no
			// fixed mapping between credits and txns (see above),
			// it is not possible to now which transaction to
			// remove once we received an PCrdReturn. So if this
			// has happened m_numPCredits will be less than the
			// m_reqs (transactions that have received RetryAck
			// with this credit).
			//
			return m_numPCredits <= m_reqs.size();
		}

		bool ContainsRetriedRequest(ReqFlit_t *newReq)
		{
			typename std::list<ReqFlit_t*>::iterator it;

			for (it = m_reqs.begin(); it != m_reqs.end(); it++) {
				ReqFlit_t *req = (*it);

				if (Compare(req, newReq)) {
					return true;
				}

			}
			return false;
		}

		unsigned int GetNumRetryRequests() { return m_reqs.size(); }

	private:

		bool Compare(ReqFlit_t *req0, ReqFlit_t *req1)
		{
			// TgtID, QoS, TxnID, ReturnTxnID (ReadNoSnp only here
			// since ReadNoSnpSep is not allowed from RN to ICN),
			// RSVDC, AllowRetry, PCrdType, TraceTag is allowed to
			// differ according to 2.11 [1]

			return
				req0->GetSrcID() == req1->GetSrcID() &&
				req0->GetReturnNID() == req1->GetReturnNID() &&
				req0->GetStashNIDValid() == req1->GetStashNIDValid() &&
				req0->GetOpcode() == req1->GetOpcode() &&
				req0->GetSize() == req1->GetSize() &&
				req0->GetAddress() == req1->GetAddress() &&
				req0->GetNonSecure() == req1->GetNonSecure() &&
				req0->GetLikelyShared() == req1->GetLikelyShared() &&
				req0->GetOrder() == req1->GetOrder() &&
				req0->GetAllocate() == req1->GetAllocate() &&
				req0->GetCacheable() == req1->GetCacheable() &&
				req0->GetDeviceMemory() == req1->GetDeviceMemory() &&
				req0->GetEarlyWrAck() == req1->GetEarlyWrAck() &&
				req0->GetSnpAttr() == req1->GetSnpAttr() &&
				req0->GetLPID() == req1->GetLPID() &&
				req0->GetExcl() == req1->GetExcl() &&
				req0->GetExpCompAck() == req1->GetExpCompAck();

		}

		unsigned int m_numPCredits;

		//
		// Requests that have recieved RetryAck with this this credit
		// type (the credit type is the index into the array of the
		// completer)
		//
		std::list<ReqFlit_t*> m_reqs;
	};

	class Completer
	{
	public:
		enum { NUM_PCREDITS_TYPES = 16 }; // 2.11 [1]

		Completer(RspFlit_t& rsp) :
			m_nodeID(rsp.GetSrcID()),
			m_credits(new PCredits[NUM_PCREDITS_TYPES])
		{
		}

		~Completer()
		{
			delete[] m_credits;
		}

		uint16_t GetNodeID() { return m_nodeID; }

		void HandleRetryAck(RspFlit_t& rsp, ReqFlit_t *req)
		{
			PCredits& credit = m_credits[rsp.GetPCrdType()];

			assert(rsp.GetPCrdType() < NUM_PCREDITS_TYPES);

			credit.AddRequest(req);
		}

		void HandlePCrdGrant(RspFlit_t& rsp)
		{
			PCredits& credit = m_credits[rsp.GetPCrdType()];

			assert(rsp.GetPCrdType() < NUM_PCREDITS_TYPES);

			credit.IncNumPCredits();
		}

		bool ReturnPCredit(ReqFlit_t *req)
		{
			bool handled = false;
			PCredits& credit = m_credits[req->GetPCrdType()];

			assert(req->GetPCrdType() < NUM_PCREDITS_TYPES);

			if (req->IsPCrdReturn() &&
				credit.GetNumPCredits() > 0) {

				credit.DecNumPCredits();
				handled = true;

			} else if (credit.ContainsRetriedRequest(req)) {

				credit.DecNumPCredits();
				handled = true;
			}

			return handled;
		}

		bool Check()
		{
			int i = 0;

			for (i = 0; i < NUM_PCREDITS_TYPES; i++) {
				if (!m_credits[i].Check()) {
					return false;
				}
			}
			return true;
		}

		void Dump(std::ostringstream& msg)
		{
			int i = 0;

			msg << " { " << hex << "m_nodeID: 0x" << m_nodeID <<
				", PCredits : { ";

			for (i = 0; i < NUM_PCREDITS_TYPES; i++) {

				if (!m_credits[i].Check()) {

					msg <<  "[ type: " << i << "]: num credits: "
						<< dec << m_credits[i].GetNumPCredits()
						<< ", number of issued RetryAcks:" <<
						m_credits[i].GetNumRetryRequests();

					return;
				}
			}
			msg << " } ";
		}

		bool ContainsRetriedRequest(ReqFlit_t *req)
		{
			int i = 0;

			for (i = 0; i < NUM_PCREDITS_TYPES; i++) {
				if (m_credits[i].ContainsRetriedRequest(req)) {
					return true;
				}
			}
			return false;
		}

	private:
		// NodeID of the completer replying with RetryAcK
		uint16_t m_nodeID;

		PCredits *m_credits;
	};

	Completer *LookupCompleter(ReqFlit_t *req)
	{
		typename std::list<Completer*>::iterator it;

		for (it = m_completers.begin();
			it != m_completers.end(); it++) {
			Completer *comp = (*it);

			if (req->IsPCrdReturn() &&
				comp->GetNodeID() == req->GetTgtID()) {
				return comp;
			} else if (comp->ContainsRetriedRequest(req)) {
				return comp;
			}

		}
		return NULL;
	}

	Completer *LookupCompleter(RspFlit_t& rsp)
	{
		typename std::list<Completer*>::iterator it;

		for (it = m_completers.begin();
			it != m_completers.end(); it++) {
			Completer *comp = (*it);

			if (comp->GetNodeID() == rsp.GetSrcID()) {
				return comp;
			}

		}
		return NULL;
	}

	void CheckCompleters()
	{
		typename std::list<Completer*>::iterator it;
		Completer *compWithErr = NULL;

		//
		// Only check completers if there are no outstanding txns since
		// txns might get rerouted (it is not known if a completer will
		// get a rerouted req and if we have receieved a PCrdGrant for
		// that rerouted req, the RetryAck might be on its way)
		//
		for (it = m_completers.begin();
			it != m_completers.end(); it++) {
			Completer *comp = (*it);

			if (!comp->Check()) {
				compWithErr = comp;
				break;
			}
		}

		if (compWithErr) {
			std::ostringstream msg;

			msg << "PCredits error detected, completer: ";
			compWithErr->Dump(msg);

			SC_REPORT_ERROR(CHI_REQ_RETRY_ERROR,
					msg.str().c_str());
		}
	}

	unsigned int NumOutstandingRequests()
	{
		int outstandingTxns = 0;
		int i;

		for (i = 0; i < NUM_TXNIDS; i++) {
			if (m_txn[i]) {
				outstandingTxns++;
			}
		}

		return outstandingTxns;
	}

	void HandleRxDat()
	{
		sc_bv<T::RXDAT_FLIT_W> flit = rxdatflit.read();
		DatFlit_t dat(flit);
		ReqFlit_t *req = m_txn[dat.GetTxnID()];

		//
		// Receiving dat for a request means that the request has
		// passed retry procedure, so no need to keep track of it any
		// more
		//
		if (req) {
			delete req;
		}
		m_txn[dat.GetTxnID()] = NULL;

		if (NumOutstandingRequests() == 0) {
			CheckCompleters();
		}
	}

	void HandleRxRsp()
	{
		sc_bv<T::RXRSP_FLIT_W> flit = rxrspflit.read();
		RspFlit_t rsp(flit);

		if (rsp.IsRetryAck()) {
			Completer *comp = LookupCompleter(rsp);
			ReqFlit_t *req = m_txn[rsp.GetTxnID()];

			if (!req) {
				std::ostringstream msg;

				msg << "RetryAck to non existing req: ";
				rsp.Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_RETRY_ERROR,
					msg.str().c_str());
			}

			//
			// Create a completer if there is none
			//
			if (!comp) {
				comp = new Completer(rsp);
				m_completers.push_back(comp);
			}

			m_txn[rsp.GetTxnID()] = NULL;
			comp->HandleRetryAck(rsp, req);

		} else if (rsp.IsPCrdGrant()) {
			Completer *comp = LookupCompleter(rsp);

			//
			// Create a completer if there is none (PCrdGrant can
			// arrive before RetryAck)
			//
			if (!comp) {
				comp = new Completer(rsp);
				m_completers.push_back(comp);
			}

			comp->HandlePCrdGrant(rsp);
		} else {
			//
			// If the rsp is not RetryAck or PCrdGrant it is a
			// response to a request has passed on from the retry
			// sequence, if it is the first time for the request
			// hitting this then deallocate it
			//
			ReqFlit_t *req = m_txn[rsp.GetTxnID()];

			if (req) {
				delete req;
			}
			m_txn[rsp.GetTxnID()] = NULL;
		}

		if (NumOutstandingRequests() == 0) {
			CheckCompleters();
		}
	}

	void SampleRequest()
	{
		sc_bv<T::TXREQ_FLIT_W> flit = txreqflit.read();
		ReqFlit_t *req = new ReqFlit_t(flit);
		uint8_t txnID = req->GetTxnID();

		// Ignore L-Credit returns
		if (req->IsReqLCrdReturn()) {
			delete req;
			return;
		}

		if (req->GetAllowRetry()) {
			m_txn[txnID] = req;
		} else {
			Completer *comp = LookupCompleter(req);
			bool handled = false;

			if (comp) {
				handled = comp->ReturnPCredit(req);
			}

			if (!handled) {
				std::ostringstream msg;

				if (req->IsPCrdReturn()) {
					msg << "PCrdReturn error (no "
						"outstanding credits available"
						" to return)";
				} else {
					msg << "Allow retry error: No "
						"outstanding request found "
						"for retrying req: ";
				}
				req->Dump(msg);

				SC_REPORT_ERROR(CHI_REQ_RETRY_ERROR,
					msg.str().c_str());
			}
			//
			// Retrying reqs do not get RetryAck responses
			//
			delete req;
		}
	}

	template<typename ListType>
	void ClearList(std::list<ListType*>& l)
	{
		typename std::list<ListType*>::iterator it;

		for (it = l.begin(); it != l.end(); it++) {
			ListType *t = (*it);
			delete t;

		}
		l.clear();
	}

	void Reset()
	{
		int i;

		for (i = 0; i < NUM_TXNIDS; i++) {
			if (m_txn[i]) {
				delete m_txn[i];
			}
			m_txn[i] = NULL;
		}

		ClearList(m_completers);
	}

	void check_request_retry()
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());
			if (resetn.read() == false) {
				Reset();
				wait(resetn.posedge_event());
				continue;
			}

			if (txreqflitv.read()) {
				SampleRequest();
			}

			if (rxdatflitv.read()) {
				HandleRxDat();
			}

			if (rxrspflitv.read()) {
				HandleRxRsp();
			}
		}
	}

	ReqFlit_t *m_txn[NUM_TXNIDS];
	std::list<Completer*> m_completers;
};

}; // namespace CHECKERS
}; // namespace CHI
}; // namespace AMBA

#endif /* CHECKER_CHI_H__ */
