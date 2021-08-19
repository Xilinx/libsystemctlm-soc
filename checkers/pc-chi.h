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

#ifndef __PC_CHI_H__
#define __PC_CHI_H__

#include <sstream>
#include <tlm-bridges/private/chi/common.h>
#include "config-chi.h"
#include "checker-chi.h"

using namespace AMBA::CHI;

#define PC_CHI_CH(name, flit_width)	\
sc_in<bool > name ## flitpend;		\
sc_in<bool > name ## flitv;		\
sc_in<sc_bv<flit_width> > name ## flit;	\
sc_in<bool > name ## lcrdv

template<
	int DATA_WIDTH = 512,
	int ADDR_WIDTH = 44,
	int NODEID_WIDTH = 7,
	int RSVDC_WIDTH = 32,
	int DATACHECK_WIDTH = 64,
	int POISON_WIDTH = 8,
	int DAT_OPCODE_WIDTH = Dat::Opcode_Width>
class CHIProtocolChecker : public sc_core::sc_module
{
public:
	typedef CHIProtocolChecker<
				DATA_WIDTH,
				ADDR_WIDTH,
				NODEID_WIDTH,
				RSVDC_WIDTH,
				DATACHECK_WIDTH,
				POISON_WIDTH,
				DAT_OPCODE_WIDTH> PCType;

	typedef CHECKERS::ReqFlit< ADDR_WIDTH,
			NODEID_WIDTH,
			RSVDC_WIDTH> ReqFlit_t;

	typedef CHECKERS::RspFlit<NODEID_WIDTH> RspFlit_t;

	// lsb 3 bits on address not used
	typedef CHECKERS::SnpFlit<ADDR_WIDTH-3, NODEID_WIDTH> SnpFlit_t;

	typedef CHECKERS::DatFlit< DATA_WIDTH,
			NODEID_WIDTH,
			RSVDC_WIDTH,
			DATACHECK_WIDTH,
			POISON_WIDTH,
			DAT_OPCODE_WIDTH> DatFlit_t;

	enum {
		TXREQ_FLIT_W = ReqFlit_t::FLIT_WIDTH,
		TXRSP_FLIT_W = RspFlit_t::FLIT_WIDTH,
		TXDAT_FLIT_W = DatFlit_t::FLIT_WIDTH,

		RXRSP_FLIT_W = RspFlit_t::FLIT_WIDTH,
		RXDAT_FLIT_W = DatFlit_t::FLIT_WIDTH,
		RXSNP_FLIT_W = SnpFlit_t::FLIT_WIDTH,
		};


	sc_in<bool > clk;
	sc_in<bool > resetn;

	sc_in<bool > txsactive;
	sc_in<bool > rxsactive;

	//
	// RN-F TX link
	//
	sc_in<bool > txlinkactivereq;
	sc_in<bool > txlinkactiveack;

	// Generate TX channels
	PC_CHI_CH(txreq, TXREQ_FLIT_W);
	PC_CHI_CH(txrsp, TXRSP_FLIT_W);
	PC_CHI_CH(txdat, TXDAT_FLIT_W);

	//
	// RN-F RX link
	//
	sc_in<bool > rxlinkactivereq;
	sc_in<bool > rxlinkactiveack;

	// Generate RX channels
	PC_CHI_CH(rxrsp, RXRSP_FLIT_W);
	PC_CHI_CH(rxdat, RXDAT_FLIT_W);
	PC_CHI_CH(rxsnp, RXSNP_FLIT_W);

	SC_HAS_PROCESS(CHIProtocolChecker);
	CHIProtocolChecker(sc_core::sc_module_name name,
			CHIPCConfig cfg = CHIPCConfig()) :
		sc_module(name),

		clk("clk"),
		resetn("resetn"),

		txsactive("txsactive"),
		rxsactive("rxsactive"),

		txlinkactivereq("txlinkactivereq"),
		txlinkactiveack("txlinkactiveack"),

		// Init TX channels
		CHI_INIT_CH(txreq),
		CHI_INIT_CH(txrsp),
		CHI_INIT_CH(txdat),

		rxlinkactivereq("rxlinkactivereq"),
		rxlinkactiveack("rxlinkactiveack"),

		// Init RX channels
		CHI_INIT_CH(rxrsp),
		CHI_INIT_CH(rxdat),
		CHI_INIT_CH(rxsnp),

		m_cfg(*reinterpret_cast<__CHIPCConfig*>(&cfg)),

		m_check_requests("check_requests", this),
		m_check_data_flits("check_data_flits", this),
		m_check_snoop_requests("check_snoop_requests", this),
		m_check_responses("check_responses", this),
		m_check_txn_structures("check_txn_structures", this),
		m_check_request_retry("check_request_retry", this),
		m_check_ch_lcredits("check_ch_lcredits", this)
	{}

	__CHIPCConfig& Cfg() { return m_cfg; }
private:
	// Checker cfg
	__CHIPCConfig m_cfg;

	CHECKERS::checker_requests<PCType>	m_check_requests;
	CHECKERS::checker_data_flits<PCType>	m_check_data_flits;
	CHECKERS::checker_snoop_requests<PCType> m_check_snoop_requests;
	CHECKERS::checker_responses<PCType>	m_check_responses;
	CHECKERS::checker_txn_structures<PCType> m_check_txn_structures;
	CHECKERS::checker_request_retry<PCType>	m_check_request_retry;
	CHECKERS::checker_ch_lcredits<PCType>	m_check_ch_lcredits;
};

#endif /* __PC_CHI_H__ */
