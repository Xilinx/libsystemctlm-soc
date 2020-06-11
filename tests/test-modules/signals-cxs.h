/*
 * Copyright (c) 2020 Xilinx Inc.
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

#ifndef SIGNALS_CXS_H__
#define SIGNALS_CXS_H__

#include "tlm-bridges/amba.h"
#include "test-modules/signals-common.h"

template<
	int FLIT_WIDTH,
	int CNTL_WIDTH
>
class CXSSignals : public sc_core::sc_module
{
public:
	sc_signal<bool > activereq;
	sc_signal<bool > activeack;
	sc_signal<bool > deacthint;

	sc_signal<bool > valid;
	sc_signal<sc_bv<FLIT_WIDTH> > data;
	sc_signal<sc_bv<CNTL_WIDTH> > cntl;
	sc_signal<bool > crdgnt;
	sc_signal<bool > crdrtn;

	template<typename T>
	void connect(T &dev, const char *prefix)
	{
		signal_connect(&dev, prefix, activereq);
		signal_connect(&dev, prefix, activeack);

		signal_connect(&dev, prefix, valid);
		signal_connect(&dev, prefix, data);
		signal_connect(&dev, prefix, cntl);
		signal_connect(&dev, prefix, crdgnt);
		signal_connect(&dev, prefix, crdrtn);
	}

	template<typename T>
	void connectTX(T *dev)
	{
		/* Write address channel.  */
		dev->txactivereq(activereq);
		dev->txactiveack(activeack);
		dev->txdeacthint(deacthint);

		dev->txvalid(valid);
		dev->txdata(data);
		dev->txcntl(cntl);
		dev->txcrdgnt(crdgnt);
		dev->txcrdrtn(crdrtn);
	}

	template<typename T>
	void connectRX(T *dev)
	{
		/* Write address channel.  */
		dev->rxactivereq(activereq);
		dev->rxactiveack(activeack);
		dev->rxdeacthint(deacthint);

		dev->rxvalid(valid);
		dev->rxdata(data);
		dev->rxcntl(cntl);
		dev->rxcrdgnt(crdgnt);
		dev->rxcrdrtn(crdrtn);
	}

	void Trace(sc_trace_file *f)
	{
		/* Write address channel.  */
		sc_trace(f, activereq, activereq.name());
		sc_trace(f, activeack, activeack.name());

		sc_trace(f, valid, valid.name());
		sc_trace(f, data, data.name());
		sc_trace(f, cntl, cntl.name());
		sc_trace(f, crdgnt, crdgnt.name());
		sc_trace(f, crdrtn, crdrtn.name());
	}

	template<typename T>
	void connect(T& dev)
	{
		connect(&dev);
	}

	CXSSignals(sc_core::sc_module_name name) :
		sc_module(name),

		activereq("activereq"),
		activeack("activeack"),

		valid("valid"),
		data("data"),
		cntl("cntl"),
		crdgnt("crdgnt"),
		crdrtn("crdrtn")
	{}
};


template<
	int FLIT_WIDTH,
	int CNTL_WIDTH
>
class CXSChkSignals : public sc_core::sc_module
{
public:

	sc_signal<bool> crdrtn_chk;
	sc_signal<bool> valid_chk;
	sc_signal<bool> crdgnt_chk;
	sc_signal<AXISignal(CNTL_WIDTH) > cntl_chk;
	sc_signal<sc_bv<FLIT_WIDTH> > data_chk;

	CXSChkSignals(sc_core::sc_module_name name) :
		sc_module(name),

		crdrtn_chk("crdrtn_chk"),
		valid_chk("valid_chk"),
		crdgnt_chk("crdgnt_chk"),
		cntl_chk("cntl_chk"),
		data_chk("data_chk")
	{}
};

#endif
