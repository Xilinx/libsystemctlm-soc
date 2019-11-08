/*
 * Copyright (c) 2018 Xilinx Inc.
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

#ifndef SIGNALS_AXI_H__
#define SIGNALS_AXI_H__

#include "tlm-bridges/amba.h"
#include "test-modules/signals-common.h"

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
	int BUSER_WIDTH = 2>
class AXISignals : public sc_core::sc_module
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
	sc_signal<AXISignal(ID_WIDTH) > wid;
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
	sc_signal<sc_bv<2> > rresp;
	sc_signal<AXISignal(RUSER_WIDTH) > ruser;
	sc_signal<AXISignal(ID_WIDTH) > rid;
	sc_signal<bool> rlast;

	template<typename T>
	void connect(T &dev, const char *prefix)
	{
		signal_connect(&dev, prefix, awvalid);
		signal_connect(&dev, prefix, awready);
		signal_connect(&dev, prefix, awaddr);
		signal_connect(&dev, prefix, awprot);
		signal_connect_optional(&dev, prefix, awuser);
		signal_connect_optional(&dev, prefix, awregion);
		signal_connect_optional(&dev, prefix, awqos);
		signal_connect(&dev, prefix, awcache);
		signal_connect(&dev, prefix, awburst);
		signal_connect(&dev, prefix, awsize);
		signal_connect_optional(&dev, prefix, awlen);
		signal_connect_optional(&dev, prefix, awid);
		signal_connect_optional(&dev, prefix, awlock);

		signal_connect_optional(&dev, prefix, wid);
		signal_connect(&dev, prefix, wvalid);
		signal_connect(&dev, prefix, wready);
		signal_connect(&dev, prefix, wdata);
		signal_connect(&dev, prefix, wstrb);
		signal_connect_optional(&dev, prefix, wuser);
		signal_connect_optional(&dev, prefix, wlast);

		signal_connect(&dev, prefix, bvalid);
		signal_connect(&dev, prefix, bready);
		signal_connect(&dev, prefix, bresp);
		signal_connect_optional(&dev, prefix, buser);
		signal_connect_optional(&dev, prefix, bid);

		signal_connect(&dev, prefix, arvalid);
		signal_connect(&dev, prefix, arready);
		signal_connect(&dev, prefix, araddr);
		signal_connect(&dev, prefix, arprot);
		signal_connect_optional(&dev, prefix, aruser);
		signal_connect_optional(&dev, prefix, arregion);
		signal_connect_optional(&dev, prefix, arqos);
		signal_connect(&dev, prefix, arcache);
		signal_connect(&dev, prefix, arburst);
		signal_connect(&dev, prefix, arsize);
		signal_connect_optional(&dev, prefix, arlen);
		signal_connect_optional(&dev, prefix, arid);
		signal_connect_optional(&dev, prefix, arlock);

		signal_connect(&dev, prefix, rvalid);
		signal_connect(&dev, prefix, rready);
		signal_connect(&dev, prefix, rdata);
		signal_connect(&dev, prefix, rresp);
		signal_connect_optional(&dev, prefix, ruser);
		signal_connect_optional(&dev, prefix, rid);
		signal_connect_optional(&dev, prefix, rlast);
	}

	template<typename T>
	void connect(T *dev)
	{
		/* Write address channel.  */
		dev->awvalid(awvalid);
		dev->awready(awready);
		dev->awaddr(awaddr);
		dev->awprot(awprot);
		if (m_version == V_AXI4) {
			if (AWUSER_WIDTH) {
				dev->awuser(awuser);
			}
			dev->awregion(awregion);
			dev->awqos(awqos);
		}
		if (m_version == V_AXI4 || m_version == V_AXI3) {
			dev->awcache(awcache);
			dev->awburst(awburst);
			dev->awsize(awsize);
			dev->awlen(awlen);
			dev->awid(awid);
			dev->awlock(awlock);
		}

		/* Write data channel.  */
		if (m_version == V_AXI3) {
			dev->wid(wid);
		}
		dev->wvalid(wvalid);
		dev->wready(wready);
		dev->wdata(wdata);
		dev->wstrb(wstrb);
		if (m_version == V_AXI4 && WUSER_WIDTH) {
			dev->wuser(wuser);
		}
		if (m_version == V_AXI4 || m_version == V_AXI3) {
			dev->wlast(wlast);
		}

		/* Write response channel.  */
		dev->bvalid(bvalid);
		dev->bready(bready);
		dev->bresp(bresp);
		if (m_version == V_AXI4 && BUSER_WIDTH) {
			dev->buser(buser);
		}
		if (m_version == V_AXI4 || m_version == V_AXI3) {
			dev->bid(bid);
		}

		/* Redev address channel.  */
		dev->arvalid(arvalid);
		dev->arready(arready);
		dev->araddr(araddr);
		dev->arprot(arprot);
		if (m_version == V_AXI4) {
			if (ARUSER_WIDTH) {
				dev->aruser(aruser);
			}
			dev->arregion(arregion);
			dev->arqos(arqos);
		}

		if (m_version == V_AXI4 || m_version == V_AXI3) {
			dev->arcache(arcache);
			dev->arburst(arburst);
			dev->arsize(arsize);
			dev->arlen(arlen);
			dev->arid(arid);
			dev->arlock(arlock);
		}

		/* Redev data channel.  */
		dev->rvalid(rvalid);
		dev->rready(rready);
		dev->rdata(rdata);
		dev->rresp(rresp);
		if (m_version == V_AXI4 && RUSER_WIDTH) {
			dev->ruser(ruser);
		}
		if (m_version == V_AXI4 || m_version == V_AXI3) {
			dev->rid(rid);
			dev->rlast(rlast);
		}
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
		sc_trace(f, wid, wid.name());
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
	}

	template<typename T>
	void connect(T& dev)
	{
		connect(&dev);
	}

	AXISignals(sc_core::sc_module_name name,
			AXIVersion version = V_AXI4) :
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
		m_version(version)
	{}

private:
	AXIVersion m_version;
};
#endif
