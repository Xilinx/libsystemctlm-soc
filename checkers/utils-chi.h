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

#ifndef CHECKER_UTILS_CHI_H__
#define CHECKER_UTILS_CHI_H__

#include <sstream>
#include <tlm-bridges/amba-chi.h>
#include "config-chi.h"

#define CHI_CHECKER(cname)					\
template<typename T, typename CFG = __CHIPCConfig>		\
class cname : public sc_core::sc_module

#define CHI_CHECKER_CTOR(cname)				\
	sc_in<bool >& clk;				\
	sc_in<bool >& resetn;				\
							\
	sc_in<bool >& txsactive;			\
	sc_in<bool >& rxsactive;			\
							\
	sc_in<bool >& txlinkactivereq;			\
	sc_in<bool >& txlinkactiveack;			\
							\
	sc_in<bool >& txreqflitpend;			\
	sc_in<bool >& txreqflitv;			\
	sc_in<sc_bv<T::TXREQ_FLIT_W> >& txreqflit;	\
	sc_in<bool >& txreqlcrdv;			\
							\
	sc_in<bool >& txrspflitpend;			\
	sc_in<bool >& txrspflitv;			\
	sc_in<sc_bv<T::TXRSP_FLIT_W> >& txrspflit;	\
	sc_in<bool >& txrsplcrdv;			\
							\
	sc_in<bool >& txdatflitpend;			\
	sc_in<bool >& txdatflitv;			\
	sc_in<sc_bv<T::TXDAT_FLIT_W> >& txdatflit;	\
	sc_in<bool >& txdatlcrdv;			\
							\
	sc_in<bool >& rxlinkactivereq;			\
	sc_in<bool >& rxlinkactiveack;			\
							\
	sc_in<bool >& rxrspflitpend;			\
	sc_in<bool >& rxrspflitv;			\
	sc_in<sc_bv<T::RXRSP_FLIT_W> >& rxrspflit;	\
	sc_in<bool >& rxrsplcrdv;			\
							\
	sc_in<bool >& rxdatflitpend;			\
	sc_in<bool >& rxdatflitv;			\
	sc_in<sc_bv<T::RXDAT_FLIT_W> >& rxdatflit;	\
	sc_in<bool >& rxdatlcrdv;			\
							\
	sc_in<bool >& rxsnpflitpend;			\
	sc_in<bool >& rxsnpflitv;			\
	sc_in<sc_bv<T::RXSNP_FLIT_W> >& rxsnpflit;	\
	sc_in<bool >& rxsnplcrdv;			\
							\
	CFG& m_cfg;					\
	T& m_pc;					\
							\
	SC_HAS_PROCESS(cname);				\
	cname(sc_core::sc_module_name name, T *pc) :	\
		sc_module(name),			\
		clk(pc->clk),				\
		resetn(pc->resetn),			\
		txsactive(pc->txsactive),		\
		rxsactive(pc->rxsactive),		\
		txlinkactivereq(pc->txlinkactivereq),	\
		txlinkactiveack(pc->txlinkactiveack),	\
		txreqflitpend(pc->txreqflitpend),	\
		txreqflitv(pc->txreqflitv),		\
		txreqflit(pc->txreqflit),		\
		txreqlcrdv(pc->txreqlcrdv),		\
		txrspflitpend(pc->txrspflitpend),	\
		txrspflitv(pc->txrspflitv),		\
		txrspflit(pc->txrspflit),		\
		txrsplcrdv(pc->txrsplcrdv),		\
		txdatflitpend(pc->txdatflitpend),	\
		txdatflitv(pc->txdatflitv),		\
		txdatflit(pc->txdatflit),		\
		txdatlcrdv(pc->txdatlcrdv),		\
		rxlinkactivereq(pc->rxlinkactivereq),	\
		rxlinkactiveack(pc->rxlinkactiveack),	\
		rxrspflitpend(pc->rxrspflitpend),	\
		rxrspflitv(pc->rxrspflitv),		\
		rxrspflit(pc->rxrspflit),		\
		rxrsplcrdv(pc->rxrsplcrdv),		\
		rxdatflitpend(pc->rxdatflitpend),	\
		rxdatflitv(pc->rxdatflitv),		\
		rxdatflit(pc->rxdatflit),		\
		rxdatlcrdv(pc->rxdatlcrdv),		\
		rxsnpflitpend(pc->rxsnpflitpend),	\
		rxsnpflitv(pc->rxsnpflitv),		\
		rxsnpflit(pc->rxsnpflit),		\
		rxsnplcrdv(pc->rxsnplcrdv),		\
		m_cfg(pc->Cfg()),			\
		m_pc(*pc)

#endif /* CHECKER_UTILS_CHI_H__ */
