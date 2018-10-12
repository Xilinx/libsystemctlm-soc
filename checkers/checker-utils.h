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

#ifndef CHECKER_UTILS_H__
#define CHECKER_UTILS_H__

#include <tlm-bridges/amba.h>
#include "config-axi.h"

#define AXI_CHECKER(name)	\
template<typename T>		\
class name : public sc_core::sc_module

#define AXI_CHECKER_CTOR(name)				\
	sc_in<bool >& clk;				\
	sc_in<bool >& awvalid;				\
	sc_in<bool >& awready;				\
	sc_in<sc_bv<T::ADDR_W> >& awaddr;		\
	sc_in<sc_bv<3> >& awprot;			\
	sc_in<AXISignal(T::AWUSER_W) >& awuser;		\
	sc_in<sc_bv<4> >& awregion;			\
	sc_in<sc_bv<4> >& awqos;			\
	sc_in<sc_bv<4> >& awcache;			\
	sc_in<sc_bv<2> >& awburst;			\
	sc_in<sc_bv<3> >& awsize;			\
	sc_in<AXISignal(T::AxLEN_W) >& awlen;		\
	sc_in<AXISignal(T::ID_W) >& awid;		\
	sc_in<AXISignal(T::AxLOCK_W) >& awlock;		\
	sc_in<AXISignal(T::ID_W) >& wid;		\
	sc_in<bool >& wvalid;				\
	sc_in<bool >& wready;				\
	sc_in<sc_bv<T::DATA_W> >& wdata;		\
	sc_in<sc_bv<T::DATA_W/8> >& wstrb;		\
	sc_in<AXISignal(T::WUSER_W) >& wuser;		\
	sc_in<bool >& wlast;				\
	sc_in<bool >& bvalid;				\
	sc_in<bool >& bready;				\
	sc_in<sc_bv<2> >& bresp;			\
	sc_in<AXISignal(T::BUSER_W) >& buser;		\
	sc_in<AXISignal(T::ID_W) >& bid;		\
	sc_in<bool >& arvalid;				\
	sc_in<bool >& arready;				\
	sc_in<sc_bv<T::ADDR_W> >& araddr;		\
	sc_in<sc_bv<3> >& arprot;			\
	sc_in<AXISignal(T::ARUSER_W) >& aruser;		\
	sc_in<sc_bv<4> >& arregion;			\
	sc_in<sc_bv<4> >& arqos;			\
	sc_in<sc_bv<4> >& arcache;			\
	sc_in<sc_bv<2> >& arburst;			\
	sc_in<sc_bv<3> >& arsize;			\
	sc_in<AXISignal(T::AxLEN_W) >& arlen;		\
	sc_in<AXISignal(T::ID_W) >& arid;		\
	sc_in<AXISignal(T::AxLOCK_W) >& arlock;		\
	sc_in<bool >& rvalid;				\
	sc_in<bool >& rready;				\
	sc_in<sc_bv<T::DATA_W> >& rdata;		\
	sc_in<sc_bv<2> >& rresp;			\
	sc_in<AXISignal(T::RUSER_W) >& ruser;		\
	sc_in<AXISignal(T::ID_W) >& rid;		\
	sc_in<bool >& rlast;				\
	__AXIPCConfig& m_cfg;				\
	T& m_pc;					\
							\
	SC_HAS_PROCESS(name);				\
	name(sc_core::sc_module_name name, T *pc) :	\
		clk(pc->clk),				\
		awvalid(pc->awvalid),			\
		awready(pc->awready),			\
		awaddr(pc->awaddr),			\
		awprot(pc->awprot),			\
		awuser(pc->awuser),			\
		awregion(pc->awregion),			\
		awqos(pc->awqos),			\
		awcache(pc->awcache),			\
		awburst(pc->awburst),			\
		awsize(pc->awsize),			\
		awlen(pc->awlen),			\
		awid(pc->awid),				\
		awlock(pc->awlock),			\
		wid(pc->wid),				\
		wvalid(pc->wvalid),			\
		wready(pc->wready),			\
		wdata(pc->wdata),			\
		wstrb(pc->wstrb),			\
		wuser(pc->wuser),			\
		wlast(pc->wlast),			\
		bvalid(pc->bvalid),			\
		bready(pc->bready),			\
		bresp(pc->bresp),			\
		buser(pc->buser),			\
		bid(pc->bid),				\
		arvalid(pc->arvalid),			\
		arready(pc->arready),			\
		araddr(pc->araddr),			\
		arprot(pc->arprot),			\
		aruser(pc->aruser),			\
		arregion(pc->arregion),			\
		arqos(pc->arqos),			\
		arcache(pc->arcache),			\
		arburst(pc->arburst),			\
		arsize(pc->arsize),			\
		arlen(pc->arlen),			\
		arid(pc->arid),				\
		arlock(pc->arlock),			\
		rvalid(pc->rvalid),			\
		rready(pc->rready),			\
		rdata(pc->rdata),			\
		rresp(pc->rresp),			\
		ruser(pc->ruser),			\
		rid(pc->rid),				\
		rlast(pc->rlast),			\
		m_cfg(pc->Cfg()),			\
		m_pc(*pc)

#endif /* CHECKER_UTILS_H__ */
