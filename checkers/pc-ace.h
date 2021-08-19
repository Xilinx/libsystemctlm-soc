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

#ifndef PC_ACE_H__
#define PC_ACE_H__

#include <sstream>
#include <tlm-bridges/amba.h>
#include "config-ace.h"
#include "checker-axi.h"
#include "checker-ace.h"

template<int ADDR_WIDTH,
	 int DATA_WIDTH,
	 int ID_WIDTH = 8,
	 int AxLEN_WIDTH = 8,
	 int AxLOCK_WIDTH = 1,
	 int AWUSER_WIDTH = 2,
	 int ARUSER_WIDTH = 2,
	 int WUSER_WIDTH = 2,
	 int RUSER_WIDTH = 2,
	 int BUSER_WIDTH = 2,
	 int CACHELINE_SZ = 64,
	 int CD_DATA_WIDTH = DATA_WIDTH>
class ACEProtocolChecker : public sc_core::sc_module
{
public:
	enum {	ADDR_W = ADDR_WIDTH,
		DATA_W = DATA_WIDTH,
		ID_W = ID_WIDTH,
		AxLEN_W = AxLEN_WIDTH,
		AxLOCK_W = AxLOCK_WIDTH,
		AWUSER_W = AWUSER_WIDTH,
		ARUSER_W = ARUSER_WIDTH,
		WUSER_W = WUSER_WIDTH,
		RUSER_W = RUSER_WIDTH,
		BUSER_W = BUSER_WIDTH,
		CD_DATA_W = CD_DATA_WIDTH,
		RRESP_W = 4
		};

	typedef ACEProtocolChecker<ADDR_WIDTH,
					DATA_WIDTH,
					ID_WIDTH,
					AxLEN_WIDTH,
					AxLOCK_WIDTH,
					AWUSER_WIDTH,
					ARUSER_WIDTH,
					WUSER_WIDTH,
					RUSER_WIDTH,
					BUSER_WIDTH,
					CACHELINE_SZ,
					CD_DATA_WIDTH> PCType;

	sc_in<bool > clk;
	sc_in<bool > resetn;

	/* Write address channel.  */
	sc_in<bool > awvalid;
	sc_in<bool > awready;
	sc_in<sc_bv<ADDR_WIDTH> > awaddr;
	sc_in<sc_bv<3> > awprot;
	sc_in<AXISignal(AWUSER_WIDTH) > awuser;
	sc_in<sc_bv<4> > awregion;
	sc_in<sc_bv<4> > awqos;
	sc_in<sc_bv<4> > awcache;
	sc_in<sc_bv<2> > awburst;
	sc_in<sc_bv<3> > awsize;
	sc_in<AXISignal(AxLEN_WIDTH) > awlen;
	sc_in<AXISignal(ID_WIDTH) > awid;
	sc_in<AXISignal(AxLOCK_WIDTH) > awlock;

	/* Write data channel.  */
	sc_in<AXISignal(ID_WIDTH) > wid; // Keep for stable checker
	sc_in<bool > wvalid;
	sc_in<bool > wready;
	sc_in<sc_bv<DATA_WIDTH> > wdata;
	sc_in<sc_bv<DATA_WIDTH/8> > wstrb;
	sc_in<AXISignal(WUSER_WIDTH) > wuser;
	sc_in<bool > wlast;

	/* Write response channel.  */
	sc_in<bool > bvalid;
	sc_in<bool > bready;
	sc_in<sc_bv<2> > bresp;
	sc_in<AXISignal(BUSER_WIDTH) > buser;
	sc_in<AXISignal(ID_WIDTH) > bid;

	/* Read address channel.  */
	sc_in<bool > arvalid;
	sc_in<bool > arready;
	sc_in<sc_bv<ADDR_WIDTH> > araddr;
	sc_in<sc_bv<3> > arprot;
	sc_in<AXISignal(ARUSER_WIDTH) > aruser;
	sc_in<sc_bv<4> > arregion;
	sc_in<sc_bv<4> > arqos;
	sc_in<sc_bv<4> > arcache;
	sc_in<sc_bv<2> > arburst;
	sc_in<sc_bv<3> > arsize;
	sc_in<AXISignal(AxLEN_WIDTH) > arlen;
	sc_in<AXISignal(ID_WIDTH) > arid;
	sc_in<AXISignal(AxLOCK_WIDTH) > arlock;

	/* Read data channel.  */
	sc_in<bool > rvalid;
	sc_in<bool > rready;
	sc_in<sc_bv<DATA_WIDTH> > rdata;
	sc_in<sc_bv<RRESP_W> > rresp;
	sc_in<AXISignal(RUSER_WIDTH) > ruser;
	sc_in<AXISignal(ID_WIDTH) > rid;
	sc_in<bool > rlast;

	// AXI4 ACE signals
	sc_in<sc_bv<3> > awsnoop;
	sc_in<sc_bv<2> > awdomain;
	sc_in<sc_bv<2> > awbar;

	sc_in<bool > wack;

	sc_in<sc_bv<4> > arsnoop;
	sc_in<sc_bv<2> > ardomain;
	sc_in<sc_bv<2> > arbar;

	sc_in<bool > rack;

	// Snoop address channel
	sc_in<bool > acvalid;
	sc_in<bool > acready;
	sc_in<sc_bv<ADDR_WIDTH> > acaddr;
	sc_in<sc_bv<4> > acsnoop;
	sc_in<sc_bv<3> > acprot;

	// Snoop response channel
	sc_in<bool > crvalid;
	sc_in<bool > crready;
	sc_in<sc_bv<5> > crresp;

	// Snoop data channel
	sc_in<bool > cdvalid;
	sc_in<bool > cdready;
	sc_in<sc_bv<CD_DATA_WIDTH> > cddata;
	sc_in<bool > cdlast;

	SC_HAS_PROCESS(ACEProtocolChecker);
	ACEProtocolChecker(sc_core::sc_module_name name,
			ACEPCConfig cfg = ACEPCConfig()) :
		sc_module(name),

		clk("clk"),
		resetn("resetn"),

		awvalid("awvalid"),
		awready("awready"),
		awaddr("awaddr"),
		awprot("awprot"),
		awuser("awuser"),
		awregion("awregion"),
		awqos("awqos"),
		awcache("awcache"),
		awburst("awburst"),
		awsize("awsize"),
		awlen("awlen"),
		awid("awid"),
		awlock("awlock"),

		wid("wid"),
		wvalid("wvalid"),
		wready("wready"),
		wdata("wdata"),
		wstrb("wstrb"),
		wuser("wuser"),
		wlast("wlast"),

		bvalid("bvalid"),
		bready("bready"),
		bresp("bresp"),
		buser("buser"),
		bid("bid"),

		arvalid("arvalid"),
		arready("arready"),
		araddr("araddr"),
		arprot("arprot"),
		aruser("aruser"),
		arregion("arregion"),
		arqos("arqos"),
		arcache("arcache"),
		arburst("arburst"),
		arsize("arsize"),
		arlen("arlen"),
		arid("arid"),
		arlock("arlock"),

		rvalid("rvalid"),
		rready("rready"),
		rdata("rdata"),
		rresp("rresp"),
		ruser("ruser"),
		rid("rid"),
		rlast("rlast"),

		// AXI4 ACE signals
		awsnoop("awsnoop"),
		awdomain("awdomain"),
		awbar("awbar"),
		wack("wack"),

		arsnoop("arsnoop"),
		ardomain("ardomain"),
		arbar("arbar"),
		rack("rack"),

		// Snoop address channel
		acvalid("acvalid"),
		acready("acready"),
		acaddr("acaddr"),
		acsnoop("acsnoop"),
		acprot("acprot"),

		// Snoop response channel
		crvalid("crvalid"),
		crready("crready"),
		crresp("crresp"),

		// Snoop data channel
		cdvalid("cdvalid"),
		cdready("cdready"),
		cddata("cddata"),
		cdlast("cdlast"),

		dummy("axi_dummy"),

		m_ace_mode(ACE_MODE_ACE),

		m_cfg(*reinterpret_cast<__ACEPCConfig*>(&cfg)),
		m_check_axi_stable("check_axi_stable", this),
		m_check_axi_reset("check_axi_reset", this),
		m_check_ace_stable("check_ace_stable", this),
		m_check_ace_handshakes("check_ace_handshakes", this),
		m_check_ace_rd_tx("check_ace_rd_tx", this),
		m_check_ace_wr_tx("check_ace_wr_tx", this),
		m_check_ace_snoop_ch("check_ace_snoop_ch", this),
		m_check_ace_barrier("check_ace_barrier", this),
		m_check_ace_cd_data("check_ace_cd_data", this),
		m_check_ace_reset("check_ace_reset", this)
	{
		m_cfg.set_cacheline_size(CACHELINE_SZ);
	}

	__ACEPCConfig& Cfg() { return m_cfg; }

	unsigned int GetACEMode() { return m_ace_mode; }
private:
	class axi_dummy : public sc_core::sc_module {
	public:
		sc_signal<AXISignal(ID_WIDTH) > wid;

		axi_dummy(sc_module_name name) :
			wid("wid")
		{ }
	};

	void before_end_of_elaboration()
	{
		wid(dummy.wid);
	}

	axi_dummy dummy;

	unsigned int m_ace_mode;

	// Checker cfg
	__ACEPCConfig m_cfg;

	//
	// AXI checkers, monitors signals that are both AXI and ACE
	//
	checker_axi_stable<PCType, __ACEPCConfig> m_check_axi_stable;
	check_axi_reset<PCType, __ACEPCConfig>    m_check_axi_reset;

	//
	// ACE checkers, monitors ACE signals only
	//
	checker_ace_stable<PCType>         m_check_ace_stable;
	checker_ace_handshakes<PCType>     m_check_ace_handshakes;
	checker_ace_rd_tx<PCType>          m_check_ace_rd_tx;
	checker_ace_wr_tx<PCType>          m_check_ace_wr_tx;
	checker_ace_snoop_channels<PCType> m_check_ace_snoop_ch;
	checker_ace_barrier<PCType> 	   m_check_ace_barrier;
	checker_ace_cd_data<PCType> 	   m_check_ace_cd_data;
	checker_ace_reset<PCType>          m_check_ace_reset;
};

#endif /* PC_ACE_H__ */
