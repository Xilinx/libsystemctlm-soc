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

#include <sstream>
#include <string>
#include <vector>
#include <array>

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "traffic-generators/tg-tlm.h"
#include "checkers/pc-chi.h"
#include "checkers/config-chi.h"
#include "tlm-bridges/amba-chi.h"
#include "test-modules/memory.h"
#include "test-modules/signals-rnf-chi.h"
#include "siggen-chi.h"

typedef CHIProtocolChecker<> CHIChecker;

typedef CHISignals<
CHIChecker::TXREQ_FLIT_W,
CHIChecker::TXRSP_FLIT_W,
CHIChecker::TXDAT_FLIT_W,
CHIChecker::RXRSP_FLIT_W,
CHIChecker::RXDAT_FLIT_W,
CHIChecker::RXSNP_FLIT_W
> CHISignals_t;

SIGGEN_TESTSUITE(TestSuite)
{
	SIGGEN_TESTSUITE_CTOR(TestSuite)
	{}

	void run_tests()
	{
		SetMessageType(CHI_TXN_STRUCTURES_ERROR);

		TESTCASE(test_ReadShared);
		TESTCASE(test_WriteBackFull);
		TESTCASE(test_CleanUnique);
		TESTCASE(test_CleanInvalid);
		TESTCASE(test_CleanInvalid_twice);
		TESTCASE(test_AtomicLoad);
		TESTCASE(test_SnpSharedFwd);
		TESTCASE(test_SnpShared);
		TESTCASE(test_SnpStashShared);

		TESTCASE_NEG(test_unexpected_txdat);
		TESTCASE_NEG(test_unexpected_txrsp);
		TESTCASE_NEG(test_unexpected_rxdat);
		TESTCASE_NEG(test_unexpected_rxrsp);
	}

	void reset_toggle()
	{
		resetn.write(false);
		wait(clk.posedge_event());
		resetn.write(true);
		wait(clk.posedge_event());
	}

	void test_ReadShared()
	{
		m_s->GenerateReqFlit(
			0, 20, 0, 0, 0, 0, 0, Req::ReadShared,
			0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
			0, 1, 0, 0, 1);
		txreqflitv.write(true);

		wait(clk.posedge_event());

		txreqflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateDatFlit( RxDat,
			0, 0, 20, 0, 20, Dat::CompData, 0, 0, 0, 1);
		rxdatflitv.write(true);

		wait(clk.posedge_event());

		rxdatflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( TxRsp,
			0, 20, 0, 1, Rsp::CompAck);

		txrspflitv.write(true);
		wait(clk.posedge_event());

		txrspflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_WriteBackFull()
	{
		m_s->GenerateReqFlit(
			0, 20, 0, 0, 0, 0, 0, Req::WriteBackFull,
			0, 0, 0, 0, 1);
		txreqflitv.write(true);

		wait(clk.posedge_event());

		txreqflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( RxRsp,
			0, 0, 20, 0, Rsp::DBIDResp, 0, 0, 0, 1);

		rxrspflitv.write(true);
		wait(clk.posedge_event());

		rxrspflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateDatFlit( TxDat,
			0, 20, 0, 1, 0, Dat::CopyBackWrData);
		txdatflitv.write(true);

		wait(clk.posedge_event());

		txdatflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_CleanUnique()
	{
		m_s->GenerateReqFlit(
			0, 20, 0, 0, 0, 0, 0, Req::CleanUnique,
			0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
			0, 1, 0, 0, 1);
		txreqflitv.write(true);

		wait(clk.posedge_event());

		txreqflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( RxRsp,
			0, 0, 20, 0, Rsp::Comp, 0, 0, 0, 1);

		rxrspflitv.write(true);
		wait(clk.posedge_event());

		rxrspflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( TxRsp,
			0, 20, 0, 1, Rsp::CompAck);

		txrspflitv.write(true);
		wait(clk.posedge_event());

		txrspflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_CleanInvalid()
	{
		m_s->GenerateReqFlit(
			0, 20, 0, 0, 0, 0, 0, Req::CleanInvalid,
			0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
			0, 1, 0, 0, 0);
		txreqflitv.write(true);

		wait(clk.posedge_event());

		txreqflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( RxRsp,
			0, 0, 20, 0, Rsp::Comp);

		rxrspflitv.write(true);
		wait(clk.posedge_event());

		rxrspflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_CleanInvalid_twice()
	{
		m_s->GenerateReqFlit(
			0, 20, 0, 0, 0, 0, 0, Req::CleanInvalid,
			0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
			0, 1, 0, 0, 0);
		txreqflitv.write(true);

		wait(clk.posedge_event());

		txreqflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( RxRsp,
			0, 0, 20, 0, Rsp::Comp);

		rxrspflitv.write(true);
		wait(clk.posedge_event());

		rxrspflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateReqFlit(
			0, 20, 0, 0, 0, 0, 0, Req::CleanInvalid,
			0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
			0, 1, 0, 0, 0);
		txreqflitv.write(true);

		wait(clk.posedge_event());

		txreqflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( RxRsp,
			0, 0, 20, 0, Rsp::Comp);

		rxrspflitv.write(true);
		wait(clk.posedge_event());

		rxrspflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_AtomicLoad()
	{
		m_s->GenerateReqFlit(
			0, 20, 0, 0, 0, 0, 0, Req::AtomicLoad,
			0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
			0, 1, 0, 0, 1);
		txreqflitv.write(true);

		wait(clk.posedge_event());

		txreqflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( RxRsp,
			0, 0, 20, 0, Rsp::DBIDResp, 0, 0, 0, 1);

		rxrspflitv.write(true);
		wait(clk.posedge_event());

		rxrspflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateDatFlit( TxDat,
			0, 20, 0, 1, 0, Dat::NonCopyBackWrData);

		txdatflitv.write(true);
		wait(clk.posedge_event());

		txdatflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateDatFlit( RxDat,
			0, 0, 20, 0, 0, Dat::CompData);

		rxdatflitv.write(true);
		wait(clk.posedge_event());

		rxdatflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_SnpSharedFwd()
	{
		m_s->GenerateSnpFlit(
			0, 20, 1, 2, 3, Snp::SnpSharedFwd);
		rxsnpflitv.write(true);

		wait(clk.posedge_event());

		rxsnpflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( TxRsp,
			0, 20, 0, 1, Rsp::SnpRespFwded);

		txrspflitv.write(true);
		wait(clk.posedge_event());

		txrspflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateDatFlit( TxDat,
			0, 2, 0, 3, 20, Dat::CompData, 0, 0, 0, 1);

		txdatflitv.write(true);
		wait(clk.posedge_event());

		txdatflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_SnpShared()
	{
		m_s->GenerateSnpFlit(
			0, 20, 1, 0, 0, Snp::SnpShared);
		rxsnpflitv.write(true);

		wait(clk.posedge_event());

		rxsnpflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( TxRsp,
			0, 20, 0, 1, Rsp::SnpResp);

		txrspflitv.write(true);
		wait(clk.posedge_event());

		txrspflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_SnpStashShared()
	{
		m_s->GenerateSnpFlit(
			0, 20, 1, 0, 0, Snp::SnpStashShared);
		rxsnpflitv.write(true);

		wait(clk.posedge_event());

		rxsnpflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( TxRsp,
			0, 20, 0, 1, Rsp::SnpResp, 0, 0, 1, 3);

		txrspflitv.write(true);
		wait(clk.posedge_event());

		txrspflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateDatFlit( RxDat,
			0, 0, 20, 3, 20, Dat::CompData, 0, 0, 0, 1);

		rxdatflitv.write(true);
		wait(clk.posedge_event());

		rxdatflitv.write(false);
		wait(clk.posedge_event());

		m_s->GenerateRspFlit( TxRsp,
			0, 20, 0, 1, Rsp::CompAck);

		txrspflitv.write(true);
		wait(clk.posedge_event());

		txrspflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_unexpected_txdat()
	{
		m_s->GenerateDatFlit( TxDat,
			0, 2, 0, 3, 20, Dat::CompData, 0, 0, 0, 1);

		txdatflitv.write(true);
		wait(clk.posedge_event());

		txdatflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_unexpected_txrsp()
	{
		m_s->GenerateRspFlit( TxRsp,
			0, 20, 0, 1, Rsp::SnpRespFwded);

		txrspflitv.write(true);
		wait(clk.posedge_event());

		txrspflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_unexpected_rxdat()
	{
		m_s->GenerateDatFlit( RxDat,
			0, 2, 0, 3, 20, Dat::CompData, 0, 0, 0, 1);

		rxdatflitv.write(true);
		wait(clk.posedge_event());

		rxdatflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}

	void test_unexpected_rxrsp()
	{
		m_s->GenerateRspFlit( RxRsp,
			0, 20, 0, 1, Rsp::SnpRespFwded);

		rxrspflitv.write(true);
		wait(clk.posedge_event());

		rxrspflitv.write(false);
		wait(clk.posedge_event());

		reset_toggle();
	}
};

SIGGEN_RUN(TestSuite)

CHIPCConfig checker_config()
{
	CHIPCConfig cfg;

	cfg.check_transaction_structures();

	return cfg;
}

int sc_main(int argc, char *argv[])
{
	CHIChecker checker("checker", checker_config());

	CHISignals_t signals("chi_signals");

	SignalGen<> siggen("sig_gen");

	sc_clock clk("clk", sc_time(20, SC_US));
	sc_signal<bool> resetn("resetn", true);

	// Connect clk
	checker.clk(clk);
	siggen.clk(clk);

	// Connect reset
	checker.resetn(resetn);
	siggen.resetn(resetn);

	// Connect signals
	signals.connectRNF(&checker);
	signals.connectRNF(&siggen);

	sc_trace_file *trace_fp = sc_create_vcd_trace_file(argv[0]);

	sc_trace(trace_fp, siggen.clk, siggen.clk.name());
	signals.Trace(trace_fp);

	// Run
	sc_start(100, SC_MS);

	sc_stop();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}

	return 0;
}
