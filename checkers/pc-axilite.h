/*
 * Copyright (c) 2018 Xilinx Inc.
 * Written by Edgar E. Iglesias,
 *            Francisco Iglesias.
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

#ifndef PC_AXILITE_H__
#define PC_AXILITE_H__

#include <sstream>
#include <tlm-bridges/amba.h>
#include "checker-axilite.h"

template <int ADDR_WIDTH, int DATA_WIDTH>
class AXILiteProtocolChecker : public sc_core::sc_module
{
public:
	enum {	ADDR_W = ADDR_WIDTH,
		DATA_W = DATA_WIDTH };

	typedef AXILiteProtocolChecker<ADDR_WIDTH, DATA_WIDTH> PCType;

	sc_in<bool > clk;
	sc_in<bool > resetn;

	/* Write address channel.  */
	sc_in<bool > awvalid;
	sc_in<bool > awready;
	sc_in<sc_bv<ADDR_WIDTH> > awaddr;
	sc_in<sc_bv<3> > awprot;

	/* Write data channel.  */
	sc_in<bool > wvalid;
	sc_in<bool > wready;
	sc_in<sc_bv<DATA_WIDTH> > wdata;
	sc_in<sc_bv<DATA_WIDTH/8> > wstrb;

	/* Write response channel.  */
	sc_in<bool > bvalid;
	sc_in<bool > bready;
	sc_in<sc_bv<2> > bresp;

	/* Read address channel.  */
	sc_in<bool > arvalid;
	sc_in<bool > arready;
	sc_in<sc_bv<ADDR_WIDTH> > araddr;
	sc_in<sc_bv<3> > arprot;

	/* Read data channel.  */
	sc_in<bool > rvalid;
	sc_in<bool > rready;
	sc_in<sc_bv<DATA_WIDTH> > rdata;
	sc_in<sc_bv<2> > rresp;

	SC_HAS_PROCESS(AXILiteProtocolChecker);
	AXILiteProtocolChecker(sc_core::sc_module_name name,
			AXILitePCConfig cfg = AXILitePCConfig()) :
		sc_module(name),

		clk("clk"),
		resetn("resetn"),

		awvalid("awvalid"),
		awready("awready"),
		awaddr("awaddr"),
		awprot("awprot"),

		wvalid("wvalid"),
		wready("wready"),
		wdata("wdata"),
		wstrb("wstrb"),

		bvalid("bvalid"),
		bready("bready"),
		bresp("bresp"),

		arvalid("arvalid"),
		arready("arready"),
		araddr("araddr"),
		arprot("arprot"),

		rvalid("rvalid"),
		rready("rready"),
		rdata("rdata"),
		rresp("rresp"),

		m_cfg(*reinterpret_cast<__AXILitePCConfig*>(&cfg)),
		m_checker_axilite_stable("checker-axilite-stable", this),
		m_check_axilite_responses("check-axilite-responses", this),
		m_check_axilite_handshakes("check-axilite-handshakes", this),
		m_check_axilite_reset("check-axilite-reset", this)
	{}

	__AXILitePCConfig& Cfg() { return m_cfg; }
private:
	// Checker cfg
	__AXILitePCConfig m_cfg;

	// Checkers
	checker_axilite_stable<PCType> m_checker_axilite_stable;
	check_axilite_responses<PCType> m_check_axilite_responses;
	check_axilite_handshakes<PCType> m_check_axilite_handshakes;
	check_axilite_reset<PCType> m_check_axilite_reset;
};

#endif /* PC_AXILITE_H__ */
