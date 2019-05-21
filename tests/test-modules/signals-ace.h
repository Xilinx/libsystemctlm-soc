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

#ifndef SIGNALS_ACE_H__
#define SIGNALS_ACE_H__

#include "tlm-bridges/amba.h"
#include "tlm-bridges/amba-ace.h"

template
<int ADDR_WIDTH,
	int DATA_WIDTH,
	int ID_WIDTH = 8,
	int AxLEN_WIDTH = 8,
	int AxLOCK_WIDTH = 1,
	int AWUSER_WIDTH = 2,
	int ARUSER_WIDTH = 2,
	int WUSER_WIDTH = 2,
	int RUSER_WIDTH = 2,
	int BUSER_WIDTH = 2,
	int CD_DATA_WIDTH = DATA_WIDTH>
class ACESignals : public sc_core::sc_module
{
public:
	/* Write address channel.  */
	sc_signal<bool> awvalid;
	sc_signal<bool> awready;
	sc_signal<sc_bv<ADDR_WIDTH> > awaddr;
	sc_signal<sc_bv<3>> awprot;
	sc_signal<AXISignal(AWUSER_WIDTH) > awuser;
	sc_signal<sc_bv<4>> awregion;
	sc_signal<sc_bv<4>> awqos;
	sc_signal<sc_bv<4>> awcache;
	sc_signal<sc_bv<2>> awburst;
	sc_signal<sc_bv<3>> awsize;
	sc_signal<AXISignal(AxLEN_WIDTH) > awlen;
	sc_signal<AXISignal(ID_WIDTH) > awid;
	sc_signal<AXISignal(AxLOCK_WIDTH) > awlock;

	/* Write data channel.  */
	sc_signal<bool> wvalid;
	sc_signal<bool> wready;
	sc_signal<sc_bv<DATA_WIDTH> > wdata;
	sc_signal<sc_bv<DATA_WIDTH/8> > wstrb;
	sc_signal<AXISignal(WUSER_WIDTH) > wuser;
	sc_signal<bool> wlast;

	/* Write response channel.  */
	sc_signal<bool> bvalid;
	sc_signal<bool> bready;
	sc_signal<sc_bv<2> > bresp;
	sc_signal<AXISignal(BUSER_WIDTH) > buser;
	sc_signal<AXISignal(ID_WIDTH) > bid;

	/* Read address channel.  */
	sc_signal<bool> arvalid;
	sc_signal<bool> arready;
	sc_signal<sc_bv<ADDR_WIDTH> > araddr;
	sc_signal<sc_bv<3> > arprot;
	sc_signal<AXISignal(ARUSER_WIDTH) > aruser;
	sc_signal<sc_bv<4> > arregion;
	sc_signal<sc_bv<4> > arqos;
	sc_signal<sc_bv<4> > arcache;
	sc_signal<sc_bv<2> > arburst;
	sc_signal<sc_bv<3> > arsize;
	sc_signal<AXISignal(AxLEN_WIDTH) > arlen;
	sc_signal<AXISignal(ID_WIDTH) > arid;
	sc_signal<AXISignal(AxLOCK_WIDTH) > arlock;

	/* Read data channel.  */
	sc_signal<bool> rvalid;
	sc_signal<bool> rready;
	sc_signal<sc_bv<DATA_WIDTH> > rdata;
	sc_signal<sc_bv<4> > rresp;
	sc_signal<AXISignal(RUSER_WIDTH) > ruser;
	sc_signal<AXISignal(ID_WIDTH) > rid;
	sc_signal<bool> rlast;

	// AXI4 ACE signals
	sc_signal<sc_bv<3> > awsnoop;
	sc_signal<sc_bv<2> > awdomain;
	sc_signal<sc_bv<2> > awbar;
	sc_signal<bool > wack;
	sc_signal<sc_bv<4> > arsnoop;
	sc_signal<sc_bv<2> > ardomain;
	sc_signal<sc_bv<2> > arbar;
	sc_signal<bool > rack;

	// Snoop address channel
	sc_signal<bool > acvalid;
	sc_signal<bool > acready;
	sc_signal<sc_bv<ADDR_WIDTH> > acaddr;
	sc_signal<sc_bv<4> > acsnoop;
	sc_signal<sc_bv<3> > acprot;

	// Snoop response channel
	sc_signal<bool > crvalid;
	sc_signal<bool > crready;
	sc_signal<sc_bv<5> > crresp;

	// Snoop data channel
	sc_signal<bool > cdvalid;
	sc_signal<bool > cdready;
	sc_signal<sc_bv<CD_DATA_WIDTH> > cddata;
	sc_signal<bool > cdlast;

	template<typename T>
	void connect(T *dev)
	{
		/* Write address channel.  */
		dev->awvalid(awvalid);
		dev->awready(awready);
		dev->awaddr(awaddr);
		dev->awprot(awprot);
		if (AWUSER_WIDTH) {
			dev->awuser(awuser);
		}
		dev->awregion(awregion);
		dev->awqos(awqos);
		dev->awcache(awcache);
		dev->awburst(awburst);
		dev->awsize(awsize);
		dev->awlen(awlen);
		dev->awid(awid);
		dev->awlock(awlock);

		dev->wvalid(wvalid);
		dev->wready(wready);
		dev->wdata(wdata);
		dev->wstrb(wstrb);
		if (WUSER_WIDTH) {
			dev->wuser(wuser);
		}
		dev->wlast(wlast);

		/* Write response channel.  */
		dev->bvalid(bvalid);
		dev->bready(bready);
		dev->bresp(bresp);
		if (BUSER_WIDTH) {
			dev->buser(buser);
		}
		dev->bid(bid);

		/* Redev address channel.  */
		dev->arvalid(arvalid);
		dev->arready(arready);
		dev->araddr(araddr);
		dev->arprot(arprot);
		if (ARUSER_WIDTH) {
			dev->aruser(aruser);
		}
		dev->arregion(arregion);
		dev->arqos(arqos);
		dev->arcache(arcache);
		dev->arburst(arburst);
		dev->arsize(arsize);
		dev->arlen(arlen);
		dev->arid(arid);
		dev->arlock(arlock);

		/* Redev data channel.  */
		dev->rvalid(rvalid);
		dev->rready(rready);
		dev->rdata(rdata);
		dev->rresp(rresp);
		if (RUSER_WIDTH) {
			dev->ruser(ruser);
		}
		dev->rid(rid);
		dev->rlast(rlast);

		// AXI4 ACE + ACELite signals
		dev->awsnoop(awsnoop);
		dev->awdomain(awdomain);
		dev->awbar(awbar);
		dev->arsnoop(arsnoop);
		dev->ardomain(ardomain);
		dev->arbar(arbar);

		// AXI4 ACE signals
		dev->wack(wack);
		dev->rack(rack);

		// Snoop address channel
		dev->acvalid(acvalid);
		dev->acready(acready);
		dev->acaddr(acaddr);
		dev->acsnoop(acsnoop);
		dev->acprot(acprot);

		// Snoop response channel
		dev->crvalid(crvalid);
		dev->crready(crready);
		dev->crresp(crresp);

		// Snoop data channel
		dev->cdvalid(cdvalid);;
		dev->cdready(cdready);
		dev->cddata(cddata);
		dev->cdlast(cdlast);
	}

	void Trace(sc_trace_file *f)
	{
		/* Write address channel.  */
		sc_trace(f, awvalid, awvalid.name());
		sc_trace(f, awready, awready.name());
		sc_trace(f, awaddr, awaddr.name());
		sc_trace(f, awprot, awprot.name());
		sc_trace(f, awuser, awuser.name());
		sc_trace(f, awregion, awregion.name());
		sc_trace(f, awqos, awqos.name());
		sc_trace(f, awcache, awcache.name());
		sc_trace(f, awburst, awburst.name());
		sc_trace(f, awsize, awsize.name());
		sc_trace(f, awlen, awlen.name());
		sc_trace(f, awid, awid.name());
		sc_trace(f, awlock, awlock.name());

		/* Write data channel.  */
		sc_trace(f, wvalid, wvalid.name());
		sc_trace(f, wready, wready.name());
		sc_trace(f, wdata, wdata.name());
		sc_trace(f, wstrb, wstrb.name());
		sc_trace(f, wuser, wuser.name());
		sc_trace(f, wlast, wlast.name());

		/* Write response channel.  */
		sc_trace(f, bvalid, bvalid.name());
		sc_trace(f, bready, bready.name());
		sc_trace(f, bresp, bresp.name());
		sc_trace(f, buser, buser.name());
		sc_trace(f, bid, bid.name());

		/* Redev address channel.  */
		sc_trace(f, arvalid, arvalid.name());
		sc_trace(f, arready, arready.name());
		sc_trace(f, araddr, araddr.name());
		sc_trace(f, arprot, arprot.name());
		sc_trace(f, aruser, aruser.name());
		sc_trace(f, arregion, arregion.name());
		sc_trace(f, arqos, arqos.name());
		sc_trace(f, arcache, arcache.name());
		sc_trace(f, arburst, arburst.name());
		sc_trace(f, arsize, arsize.name());
		sc_trace(f, arlen, arlen.name());
		sc_trace(f, arid, arid.name());
		sc_trace(f, arlock, arlock.name());

		/* Redev data channel.  */
		sc_trace(f, rvalid, rvalid.name());
		sc_trace(f, rready, rready.name());
		sc_trace(f, rdata, rdata.name());
		sc_trace(f, rresp, rresp.name());
		sc_trace(f, ruser, ruser.name());
		sc_trace(f, rid, rid.name());
		sc_trace(f, rlast, rlast.name());

		// AXI4 ACE + ACELite signals
		sc_trace(f, awsnoop, awsnoop.name());
		sc_trace(f, awdomain, awdomain.name());
		sc_trace(f, awbar, awbar.name());
		sc_trace(f, arsnoop, arsnoop.name());
		sc_trace(f, ardomain, ardomain.name());
		sc_trace(f, arbar, arbar.name());

		sc_trace(f, wack, wack.name());
		sc_trace(f, rack, rack.name());

		// Snoop address channel
		sc_trace(f, acvalid, acvalid.name());
		sc_trace(f, acready, acready.name());
		sc_trace(f, acaddr, acaddr.name());
		sc_trace(f, acsnoop, acsnoop.name());
		sc_trace(f, acprot, acprot.name());

		// Snoop response channel
		sc_trace(f, crvalid, crvalid.name());
		sc_trace(f, crready, crready.name());
		sc_trace(f, crresp, crresp.name());

		// Snoop data channel
		sc_trace(f, cdvalid, cdvalid.name());;
		sc_trace(f, cdready, cdready.name());
		sc_trace(f, cddata, cddata.name());
		sc_trace(f, cdlast, cdlast.name());
	}

	template<typename T>
	void connect(T& dev)
	{
		connect(&dev);
	}

	ACESignals(sc_core::sc_module_name name) :
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
		cdlast("cdlast")
	{}
};
#endif
