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

#ifndef SIGNALS_AXILITE_H__
#define SIGNALS_AXILITE_H__

#include "tlm-bridges/amba.h"
#include "test-modules/signals-common.h"

template
<int ADDR_WIDTH, int DATA_WIDTH>
class AXILiteSignals : public sc_core::sc_module
{
public:
	/* Write address channel.  */
	sc_signal<bool> awvalid;
	sc_signal<bool> awready;
	sc_signal<sc_bv<ADDR_WIDTH> > awaddr;
	sc_signal<sc_bv<3>> awprot;

	/* Write data channel.  */
	sc_signal<bool> wvalid;
	sc_signal<bool> wready;
	sc_signal<sc_bv<DATA_WIDTH> > wdata;
	sc_signal<sc_bv<DATA_WIDTH/8> > wstrb;

	/* Write response channel.  */
	sc_signal<bool> bvalid;
	sc_signal<bool> bready;
	sc_signal<sc_bv<2> > bresp;

	/* Read address channel.  */
	sc_signal<bool> arvalid;
	sc_signal<bool> arready;
	sc_signal<sc_bv<ADDR_WIDTH> > araddr;
	sc_signal<sc_bv<3> > arprot;

	/* Read data channel.  */
	sc_signal<bool> rvalid;
	sc_signal<bool> rready;
	sc_signal<sc_bv<DATA_WIDTH> > rdata;
	sc_signal<sc_bv<2> > rresp;

	template<typename T>
	void connect(T &dev, const char *prefix)
	{
		signal_connect(&dev, prefix, awvalid);
		signal_connect(&dev, prefix, awready);
		signal_connect(&dev, prefix, awaddr);
		signal_connect(&dev, prefix, awprot);

		signal_connect(&dev, prefix, wvalid);
		signal_connect(&dev, prefix, wready);
		signal_connect(&dev, prefix, wdata);
		signal_connect(&dev, prefix, wstrb);

		signal_connect(&dev, prefix, bvalid);
		signal_connect(&dev, prefix, bready);
		signal_connect(&dev, prefix, bresp);

		signal_connect(&dev, prefix, arvalid);
		signal_connect(&dev, prefix, arready);
		signal_connect(&dev, prefix, araddr);
		signal_connect(&dev, prefix, arprot);

		signal_connect(&dev, prefix, rvalid);
		signal_connect(&dev, prefix, rready);
		signal_connect(&dev, prefix, rdata);
		signal_connect(&dev, prefix, rresp);
	}

	template<typename T>
	void connect(T *dev)
	{
		/* Write address channel.  */
		dev->awvalid(awvalid);
		dev->awready(awready);
		dev->awaddr(awaddr);
		dev->awprot(awprot);

		dev->wvalid(wvalid);
		dev->wready(wready);
		dev->wdata(wdata);
		dev->wstrb(wstrb);

		/* Write response channel.  */
		dev->bvalid(bvalid);
		dev->bready(bready);
		dev->bresp(bresp);

		/* Redev address channel.  */
		dev->arvalid(arvalid);
		dev->arready(arready);
		dev->araddr(araddr);
		dev->arprot(arprot);

		/* Redev data channel.  */
		dev->rvalid(rvalid);
		dev->rready(rready);
		dev->rdata(rdata);
		dev->rresp(rresp);
	}

	void Trace(sc_trace_file *f)
	{
		/* Write address channel.  */
		sc_trace(f, awvalid, awvalid.name());
		sc_trace(f, awready, awready.name());
		sc_trace(f, awaddr, awaddr.name());
		sc_trace(f, awprot, awprot.name());

		/* Write data channel.  */
		sc_trace(f, wvalid, wvalid.name());
		sc_trace(f, wready, wready.name());
		sc_trace(f, wdata, wdata.name());
		sc_trace(f, wstrb, wstrb.name());

		/* Write response channel.  */
		sc_trace(f, bvalid, bvalid.name());
		sc_trace(f, bready, bready.name());
		sc_trace(f, bresp, bresp.name());

		/* Redev address channel.  */
		sc_trace(f, arvalid, arvalid.name());
		sc_trace(f, arready, arready.name());
		sc_trace(f, araddr, araddr.name());
		sc_trace(f, arprot, arprot.name());

		/* Redev data channel.  */
		sc_trace(f, rvalid, rvalid.name());
		sc_trace(f, rready, rready.name());
		sc_trace(f, rdata, rdata.name());
		sc_trace(f, rresp, rresp.name());
	}

	template<typename T>
	void connect(T& dev)
	{
		connect(&dev);
	}

	AXILiteSignals(sc_core::sc_module_name name,
			AXIVersion version = V_AXI4LITE) :
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
		rresp("rresp")
	{}

private:
	AXIVersion m_version;
};
#endif

