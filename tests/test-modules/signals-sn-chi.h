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

#ifndef SIGNALS_SN_CHI_H__
#define SIGNALS_SN_CHI_H__

#include "signals-rnf-chi.h"

template<
	int TXREQ_FLIT_WIDTH,
	int TXDAT_FLIT_WIDTH,
	int RXRSP_FLIT_WIDTH,
	int RXDAT_FLIT_WIDTH>
class CHISignals_SN :
	public sc_core::sc_module
{
public:
	sc_signal<bool > sactive0; // TX for RN-F, RX for ICN
	sc_signal<bool > sactive1; // RX for RN-F, TX for ICN

	//
	// Link 0
	//
	sc_signal<bool > linkactivereq0; // TX for RN-F, RX for ICN
	sc_signal<bool > linkactiveack0; // RX for RN-F, TX for ICN

	CHI_CH_SIGNALS(req, 0, TXREQ_FLIT_WIDTH);
	CHI_CH_SIGNALS(dat, 0, TXDAT_FLIT_WIDTH);

	//
	// Link 1
	//
	sc_signal<bool > linkactivereq1; // RX for RN-F, TX for ICN
	sc_signal<bool > linkactiveack1; // TX for RN-F, RX for ICN

	// Generate RX channels
	CHI_CH_SIGNALS(rsp, 1, RXRSP_FLIT_WIDTH);
	CHI_CH_SIGNALS(dat, 1, RXDAT_FLIT_WIDTH);

	CHISignals_SN(sc_core::sc_module_name name) :
		sc_module(name),

		sactive0("sactive0"),
		sactive1("sactive1"),

		linkactivereq0("linkactivereq0"),
		linkactiveack0("linkactiveack0"),

		CHI_INIT_CH_LINK(req, 0),
		CHI_INIT_CH_LINK(dat, 0),

		linkactivereq1("linkactivereq1"),
		linkactiveack1("linkactiveack1"),

		CHI_INIT_CH_LINK(rsp, 1),
		CHI_INIT_CH_LINK(dat, 1)
	{}

	template<typename T>
	void connectICN(T *dev)
	{
		dev->txsactive(sactive0);
		dev->rxsactive(sactive1);

		dev->txlinkactivereq(linkactivereq0);
		dev->txlinkactiveack(linkactiveack0);

		// Generate connection of TX channels
		CONNECT_TX_CH(dev, req, 0);
		CONNECT_TX_CH(dev, dat, 0);

		dev->rxlinkactivereq(linkactivereq1);
		dev->rxlinkactiveack(linkactiveack1);

		// Generate connection of RX channels
		CONNECT_RX_CH(dev, rsp, 1);
		CONNECT_RX_CH(dev, dat, 1);
	}

	template<typename T>
	void connectSN(T *dev)
	{
		dev->rxsactive(sactive0);
		dev->txsactive(sactive1);

		dev->rxlinkactivereq(linkactivereq0);
		dev->rxlinkactiveack(linkactiveack0);

		// Generate connection of RX channels
		CONNECT_RX_CH(dev, req, 0);
		CONNECT_RX_CH(dev, dat, 0);

		dev->txlinkactivereq(linkactivereq1);
		dev->txlinkactiveack(linkactiveack1);

		// Generate connection of TX channels
		CONNECT_TX_CH(dev, rsp, 1);
		CONNECT_TX_CH(dev, dat, 1);
	}

	void Trace(sc_trace_file *f)
	{
		sc_trace(f, sactive0, sactive0.name());
		sc_trace(f, sactive1, sactive1.name());

		sc_trace(f, linkactivereq0, linkactivereq0.name());
		sc_trace(f, linkactiveack0, linkactiveack0.name());

		// Generate tracing of TX channels
		TRACE_CH(f, req, 0);
		TRACE_CH(f, dat, 0);

		sc_trace(f, linkactivereq1, linkactivereq1.name());
		sc_trace(f, linkactiveack1, linkactiveack1.name());

		// Generate tracing of RX channels
		TRACE_CH(f, rsp, 1);
		TRACE_CH(f, dat, 1);
	}
};

#endif /* SIGNALS_SN_CHI_H__ */
