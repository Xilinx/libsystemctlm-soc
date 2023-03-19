/*
 * Copyright (c) 2023 Zero ASIC
 * Written by Edgar E. Iglesias.
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

#ifndef SIGNALS_WISHBONE_H__
#define SIGNALS_WISHBONE_H__

template
<int ADDR_WIDTH, int DATA_WIDTH>
class WishBoneSignals : public sc_core::sc_module
{
public:
	/* Write data channel.  */
	sc_signal<bool> stb;
	sc_signal<bool> ack;
	sc_signal<bool> err;
	sc_signal<bool> we;
	sc_signal<bool> cyc;
	sc_signal<sc_bv<3> > cti;
	sc_signal<sc_bv<2> > bte;
	sc_signal<sc_bv<ADDR_WIDTH> > adr;
        // Naming from a masters point of view.
	sc_signal<sc_bv<DATA_WIDTH> > dat_i;
	sc_signal<sc_bv<DATA_WIDTH> > dat_o;
	sc_signal<sc_bv<DATA_WIDTH/8> > sel;

	template<typename T>
	void connect_master(T *dev)
	{
		dev->stb_o(stb);
		dev->ack_i(ack);
		dev->we_o(we);
		dev->cyc_o(cyc);
		dev->adr_o(adr);
		dev->dat_i(dat_i);
		dev->dat_o(dat_o);
		dev->sel_o(sel);
	}

	template<typename T>
	void connect_slave(T *dev)
	{
		dev->stb_i(stb);
		dev->ack_o(ack);
		dev->we_i(we);
		dev->cyc_i(cyc);
		dev->adr_i(adr);
		dev->dat_o(dat_i);
		dev->dat_i(dat_o);
		dev->sel_i(sel);
	}

	void Trace(sc_trace_file *f)
	{
		/* Write data channel.  */
		sc_trace(f, stb, stb.name());
		sc_trace(f, ack, ack.name());
		sc_trace(f, err, err.name());
		sc_trace(f, we, we.name());
		sc_trace(f, cyc, cyc.name());
		sc_trace(f, adr, adr.name());
		sc_trace(f, dat_i, dat_i.name());
		sc_trace(f, dat_o, dat_o.name());
		sc_trace(f, sel, sel.name());
	}

	WishBoneSignals(sc_core::sc_module_name name) :
		sc_module(name),

		stb("stb"),
		ack("ack"),
		err("err"),
		we("we"),
		cyc("cyc"),
		cti("cti"),
		bte("bte"),
		adr("adr"),
		dat_i("dat_i"),
		dat_o("dat_o"),
		sel("sel")
	{}

private:
};
#endif
