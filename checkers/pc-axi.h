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

#ifndef PC_AXI_H__
#define PC_AXI_H__

#include <sstream>
#include <tlm-bridges/amba.h>
#include "checker-axi.h"

template<int ADDR_WIDTH,
	 int DATA_WIDTH,
	 int ID_WIDTH = 8,
	 int AxLEN_WIDTH = 8,
	 int AxLOCK_WIDTH = 1,
	 int AWUSER_WIDTH = 2,
	 int ARUSER_WIDTH = 2,
	 int WUSER_WIDTH = 2,
	 int RUSER_WIDTH = 2,
	 int BUSER_WIDTH = 2>
class AXIProtocolChecker : public sc_core::sc_module
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
		RRESP_W = 2 };

	typedef AXIProtocolChecker<ADDR_WIDTH,
					DATA_WIDTH,
					ID_WIDTH,
					AxLEN_WIDTH,
					AxLOCK_WIDTH,
					AWUSER_WIDTH,
					ARUSER_WIDTH,
					WUSER_WIDTH,
					RUSER_WIDTH,
					BUSER_WIDTH> PCType;

	sc_in<bool > clk;
	sc_in<bool > resetn;

	/* Write address channel.  */
	sc_in<bool > awvalid;
	sc_in<bool > awready;
	sc_in<sc_bv<ADDR_WIDTH> > awaddr;
	sc_in<sc_bv<3> > awprot;
	sc_in<AXISignal(AWUSER_WIDTH) > awuser;	// AXI4 only
	sc_in<sc_bv<4> > awregion;		// AXI4 only
	sc_in<sc_bv<4> > awqos;			// AXI4 only
	sc_in<sc_bv<4> > awcache;
	sc_in<sc_bv<2> > awburst;
	sc_in<sc_bv<3> > awsize;
	sc_in<AXISignal(AxLEN_WIDTH) > awlen;
	sc_in<AXISignal(ID_WIDTH) > awid;
	sc_in<AXISignal(AxLOCK_WIDTH) > awlock;

	/* Write data channel.  */
	sc_in<AXISignal(ID_WIDTH) > wid;		// AXI3 only
	sc_in<bool > wvalid;
	sc_in<bool > wready;
	sc_in<sc_bv<DATA_WIDTH> > wdata;
	sc_in<sc_bv<DATA_WIDTH/8> > wstrb;
	sc_in<AXISignal(WUSER_WIDTH) > wuser;	// AXI4 only
	sc_in<bool > wlast;

	/* Write response channel.  */
	sc_in<bool > bvalid;
	sc_in<bool > bready;
	sc_in<sc_bv<2> > bresp;
	sc_in<AXISignal(BUSER_WIDTH) > buser;	// AXI4 only
	sc_in<AXISignal(ID_WIDTH) > bid;

	/* Read address channel.  */
	sc_in<bool > arvalid;
	sc_in<bool > arready;
	sc_in<sc_bv<ADDR_WIDTH> > araddr;
	sc_in<sc_bv<3> > arprot;
	sc_in<AXISignal(ARUSER_WIDTH) > aruser;	// AXI4 only
	sc_in<sc_bv<4> > arregion;		// AXI4 only
	sc_in<sc_bv<4> > arqos;			// AXI4 only
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
	sc_in<sc_bv<2> > rresp;
	sc_in<AXISignal(RUSER_WIDTH) > ruser;	// AXI4 only
	sc_in<AXISignal(ID_WIDTH) > rid;
	sc_in<bool > rlast;

	SC_HAS_PROCESS(AXIProtocolChecker);
	AXIProtocolChecker(sc_core::sc_module_name name,
			AXIPCConfig cfg = AXIPCConfig()) :
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

		dummy("axi_dummy"),
		m_cfg(*reinterpret_cast<__AXIPCConfig*>(&cfg)),
		m_checker_axi_stable("checker_axi_stable", this),
		m_check_rd_tx("check_rd_tx", this),
		m_check_wr_tx("check_wr_tx", this),
		m_check_addr_alignment("check_addr_alignment", this),
		m_check_axi_handshakes("check_axi_handshakes", this),
		m_check_axi_reset("check_axi_reset", this)
	{}

	AXIVersion GetVersion() { return m_cfg.get_axi_version(); }

	__AXIPCConfig& Cfg() { return m_cfg; }
private:
	class axi_dummy : public sc_core::sc_module {
	public:
		// AXI4
		sc_signal<AXISignal(ID_WIDTH) > wid;

		// AXI3
		sc_signal<sc_bv<4> > awqos;
		sc_signal<sc_bv<4> > awregion;
		sc_signal<AXISignal(AWUSER_WIDTH) > awuser;
		sc_signal<AXISignal(WUSER_WIDTH) > wuser;
		sc_signal<AXISignal(BUSER_WIDTH) > buser;
		sc_signal<sc_bv<4> > arregion;
		sc_signal<sc_bv<4> > arqos;
		sc_signal<AXISignal(ARUSER_WIDTH) > aruser;
		sc_signal<AXISignal(RUSER_WIDTH) > ruser;

		axi_dummy(sc_module_name name) :
			wid("wid"),
			awqos("awqos"),
			awregion("awregion"),
			awuser("awuser"),
			wuser("wuser"),
			buser("buser"),
			arregion("arregion"),
			arqos("arqos"),
			aruser("aruser"),
			ruser("ruser")
		{ }
	};

	void bind_dummy(void) {
		if (GetVersion() == V_AXI4) {
			wid(dummy.wid);

			//
			// Optional signals
			//
			if (AWUSER_WIDTH == 0) {
				awuser(dummy.awuser);
			}
			if (WUSER_WIDTH == 0) {
				wuser(dummy.wuser);
			}
			if (BUSER_WIDTH == 0) {
				buser(dummy.buser);
			}
			if (ARUSER_WIDTH == 0) {
				aruser(dummy.aruser);
			}
			if (RUSER_WIDTH == 0) {
				ruser(dummy.ruser);
			}
		} else if (GetVersion() == V_AXI3) {
			awqos(dummy.awqos);
			awregion(dummy.awregion);
			awuser(dummy.awuser);
			wuser(dummy.wuser);
			buser(dummy.buser);
			arregion(dummy.arregion);
			arqos(dummy.arqos);
			aruser(dummy.aruser);
			ruser(dummy.ruser);
		}
	}

	void before_end_of_elaboration()
	{
		bind_dummy();
	}

	axi_dummy dummy;

	// Checker cfg
	__AXIPCConfig m_cfg;

	// Checkers
	checker_axi_stable<PCType> m_checker_axi_stable;
	check_rd_tx<PCType> m_check_rd_tx;
	check_wr_tx<PCType> m_check_wr_tx;
	check_addr_alignment<PCType> m_check_addr_alignment;
	check_axi_handshakes<PCType> m_check_axi_handshakes;
	check_axi_reset<PCType> m_check_axi_reset;
};

#endif /* PC_AXI_H__ */
