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
#include <tlm-bridges/amba-ace.h>
#include "config-axi.h"
#include "config-axilite.h"
#include <list>

#define AXI_CHECKER(name)					\
template<typename T, typename CFG = __AXIPCConfig>		\
class name : public sc_core::sc_module, public axi_common

#define AXI_CHECKER_CTOR(name)				\
	sc_in<bool >& clk;				\
	sc_in<bool >& resetn;				\
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
	sc_in<sc_bv<T::RRESP_W> >& rresp;		\
	sc_in<AXISignal(T::RUSER_W) >& ruser;		\
	sc_in<AXISignal(T::ID_W) >& rid;		\
	sc_in<bool >& rlast;				\
	CFG& m_cfg;					\
	T& m_pc;					\
							\
	SC_HAS_PROCESS(name);				\
	name(sc_core::sc_module_name name, T *pc) :	\
		sc_module(name),			\
		axi_common(pc),				\
		clk(pc->clk),				\
		resetn(pc->resetn),			\
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

#define AXILITE_CHECKER(name)	\
template<typename T>		\
class name : public sc_core::sc_module, public axi_common

#define AXILITE_CHECKER_CTOR(name)			\
	sc_in<bool >& clk;				\
	sc_in<bool >& resetn;				\
	sc_in<bool >& awvalid;				\
	sc_in<bool >& awready;				\
	sc_in<sc_bv<T::ADDR_W> >& awaddr;		\
	sc_in<sc_bv<3> >& awprot;			\
	sc_in<bool >& wvalid;				\
	sc_in<bool >& wready;				\
	sc_in<sc_bv<T::DATA_W> >& wdata;		\
	sc_in<sc_bv<T::DATA_W/8> >& wstrb;		\
	sc_in<bool >& bvalid;				\
	sc_in<bool >& bready;				\
	sc_in<sc_bv<2> >& bresp;			\
	sc_in<bool >& arvalid;				\
	sc_in<bool >& arready;				\
	sc_in<sc_bv<T::ADDR_W> >& araddr;		\
	sc_in<sc_bv<3> >& arprot;			\
	sc_in<bool >& rvalid;				\
	sc_in<bool >& rready;				\
	sc_in<sc_bv<T::DATA_W> >& rdata;		\
	sc_in<sc_bv<2> >& rresp;			\
	__AXILitePCConfig& m_cfg;			\
	T& m_pc;					\
							\
	SC_HAS_PROCESS(name);				\
	name(sc_core::sc_module_name name, T *pc) :	\
		sc_module(name),			\
		axi_common(pc),				\
		clk(pc->clk),				\
		resetn(pc->resetn),			\
		awvalid(pc->awvalid),			\
		awready(pc->awready),			\
		awaddr(pc->awaddr),			\
		awprot(pc->awprot),			\
		wvalid(pc->wvalid),			\
		wready(pc->wready),			\
		wdata(pc->wdata),			\
		wstrb(pc->wstrb),			\
		bvalid(pc->bvalid),			\
		bready(pc->bready),			\
		bresp(pc->bresp),			\
		arvalid(pc->arvalid),			\
		arready(pc->arready),			\
		araddr(pc->araddr),			\
		arprot(pc->arprot),			\
		rvalid(pc->rvalid),			\
		rready(pc->rready),			\
		rdata(pc->rdata),			\
		rresp(pc->rresp),			\
		m_cfg(pc->Cfg()),			\
		m_pc(*pc)

#define ACE_CHECKER(name)					\
template<typename T, typename CFG = __ACEPCConfig>		\
class name : public sc_core::sc_module, public axi_common

#define ACE_CHECKER_CTOR(name)				\
	sc_in<bool >& clk;				\
	sc_in<bool >& resetn;				\
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
	sc_in<sc_bv<T::RRESP_W> >& rresp;		\
	sc_in<AXISignal(T::RUSER_W) >& ruser;		\
	sc_in<AXISignal(T::ID_W) >& rid;		\
	sc_in<bool >& rlast;				\
	sc_in<sc_bv<3> >& awsnoop;			\
	sc_in<sc_bv<2> >& awdomain;			\
	sc_in<sc_bv<2> >& awbar;			\
	sc_in<bool >& wack;				\
	sc_in<sc_bv<4> >& arsnoop;			\
	sc_in<sc_bv<2> >& ardomain;			\
	sc_in<sc_bv<2> >& arbar;			\
	sc_in<bool >& rack;				\
	sc_in<bool >& acvalid;				\
	sc_in<bool >& acready;				\
	sc_in<sc_bv<T::ADDR_W> >& acaddr;		\
	sc_in<sc_bv<4> >& acsnoop;			\
	sc_in<sc_bv<3> >& acprot;			\
	sc_in<bool >& crvalid;				\
	sc_in<bool >& crready;				\
	sc_in<sc_bv<5> >& crresp;			\
	sc_in<bool >& cdvalid;				\
	sc_in<bool >& cdready;				\
	sc_in<sc_bv<T::CD_DATA_W> >& cddata;		\
	sc_in<bool >& cdlast;				\
	CFG& m_cfg;					\
	T& m_pc;					\
							\
	SC_HAS_PROCESS(name);				\
	name(sc_core::sc_module_name name, T *pc) :	\
		sc_module(name),			\
		axi_common(pc),				\
		clk(pc->clk),				\
		resetn(pc->resetn),			\
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
		awsnoop(pc->awsnoop),			\
		awdomain(pc->awdomain),			\
		awbar(pc->awbar),			\
		wack(pc->wack),				\
		arsnoop(pc->arsnoop),			\
		ardomain(pc->ardomain),			\
		arbar(pc->arbar),			\
		rack(pc->rack),				\
		acvalid(pc->acvalid),			\
		acready(pc->acready),			\
		acaddr(pc->acaddr),			\
		acsnoop(pc->acsnoop),			\
		acprot(pc->acprot),			\
		crvalid(pc->crvalid),			\
		crready(pc->crready),			\
		crresp(pc->crresp),			\
		cdvalid(pc->cdvalid),			\
		cdready(pc->cdready),			\
		cddata(pc->cddata),			\
		cdlast(pc->cdlast),			\
		m_cfg(pc->Cfg()),			\
		m_pc(*pc)


#define CHECKER_AXI_ERROR "AXI Protocol Checker Error"
#define AXI_HANDSHAKE_ERROR "axi_handshakes"
#define AXI_RESET_ERROR "axi_reset"

class axi_handshakes_checker : public axi_common
{
public:
	template<typename T>
	axi_handshakes_checker(T *mod) :
		axi_common(mod)
	{}

	template<typename PC, typename PCCFG, typename IAXLEN>
	void run(PC& p, PCCFG& cfg, IAXLEN& axlen)
	{
		uint64_t m_max_clks = cfg.get_max_clks();
		HandshakeMonitor ar_channel("ar", p.arvalid, p.arready, m_max_clks);
		HandshakeMonitor rr_channel("r", p.rvalid, p.rready, m_max_clks);
		HandshakeMonitor aw_channel("aw", p.awvalid, p.awready, m_max_clks);
		HandshakeMonitor w_channel("w", p.wvalid, p.wready, m_max_clks);
		HandshakeMonitor b_channel("b", p.bvalid, p.bready, m_max_clks);
		sc_in<bool >& clk = p.clk;
		sc_in<bool >& resetn = p.resetn;
		uint32_t m_rt = 0;
		int m_wd = 0;
		uint32_t m_b = 0;
		uint32_t m_aw = 0;
		uint32_t m_wlast = 0;
		bool is_axi3 = axlen.is_axi3();
		bool use_ids = !axlen.is_axi4lite(); // AXI4Lite doesn't use ids

		while (true) {
			bool inc_rvalid = m_rt > 0;
			bool inc_awvalid = m_wd < 0;
			bool inc_wvalid = m_wd > 0;
			bool inc_bvalid = m_b > 0;

			sc_core::wait(clk.posedge_event() | resetn.negedge_event());
			if (reset_asserted()) {
				ar_channel.restart();
				rr_channel.restart();
				aw_channel.restart();
				w_channel.restart();
				b_channel.restart();
				m_rt = 0;
				m_wd = 0;
				m_b = 0;

				m_aw = 0;
				m_wlast = 0;
				m_awids.clear();
				m_wids.clear();
				m_bids.clear();

				wait_for_reset_release();
				continue;
			}

			//
			// ar and rr channels
			//
			if (ar_channel.run()) {
				//
				// ar signals received, now expect num_beats rr
				// handshakes
				//
				m_rt += axlen.get_arlen() + 1;
			}
			if (rr_channel.run(inc_rvalid)) {
				//
				// rr signals received
				//
				m_rt--;
			}

			//
			// aw, w and b channels
			//
			if (aw_channel.run(inc_awvalid)) {
				//
				// aw signals received, now expect num_beats wd
				// handshakes (or if in ACE mode and it is a
				// write barrier expect a response instead)
				//
				if (!axlen.hasData()) {
					m_b++;

					assert(use_ids);
					m_bids.push_back(axlen.get_awid());

				} else if (use_ids) {
					uint32_t awid = axlen.get_awid();
					bool id_in_wids = (is_axi3) ?
							in_list(m_wids, awid) :
							true;

					m_wd += axlen.get_awlen() + 1;

					//
					// wlast for the txn came before aw
					//
					if (id_in_wids && m_wlast > m_aw) {
						m_b++;
						m_wlast--;

						if (is_axi3) {
							remove(m_wids, awid);
						}
						m_bids.push_back(awid);
					} else {
						m_aw++;
						m_awids.push_back(awid);
					}
				} else {
					m_wd++;
				}
			}
			if (w_channel.run(inc_wvalid)) {
				m_wd--;
				//
				// All beats for one transaction done, now
				// expect bvalid
				//
				if (axlen.get_wlast()) {
					if (use_ids) {
						uint32_t wid = axlen.get_wid();
						bool id_in_awids = (is_axi3) ?
							in_list(m_awids, wid) :
							true;
						//
						// aw for the txn came before
						// wlast
						//
						if (id_in_awids &&
							m_aw > m_wlast) {

							m_b++;
							m_aw--;

							if (is_axi3) {
								remove(m_awids,
									wid);
								m_bids.push_back(
									wid);
							} else {
								uint32_t id;

								assert(!m_awids.empty());

								id = m_awids.front();

								m_awids.pop_front();
								m_bids.push_back(id);
							}
						} else {
							m_wlast++;
							if (is_axi3) {
								m_wids.push_back(
									wid);
							}
						}
					} else {
						m_b++;
					}
				}
			}
			if (b_channel.run(inc_bvalid)) {
				if (use_ids) {
					uint32_t bid = axlen.get_bid();

					if (in_list(m_bids, bid)) {
						remove(m_bids, bid);
						m_b--;
					}
				} else {
					m_b--;
				}
			}
		}
	}

	class HandshakeMonitor
	{
	public:
		HandshakeMonitor(std::string name,
				sc_in<bool >& valid,
				sc_in<bool >& ready,
				uint64_t max_clks) :
			m_name(name),
			m_valid(valid),
			m_ready(ready),
			m_valid_wait(0),
			m_ready_wait(0),
			m_max_clks(max_clks)
		{}

		bool run(bool inc_valid = false)
		{
			if (!m_valid.read()) {

				if (inc_valid) {
					// Waiting for valid and not for ready
					inc_valid_w();
				}

				if (m_ready_wait) {
					std::ostringstream msg;

					msg << m_name << "valid toggled without"
						<< " waiting for " << m_name
						<< "ready!";

					SC_REPORT_ERROR(AXI_HANDSHAKE_ERROR,
							msg.str().c_str());
				}

			} else if (!m_ready.read()) {
				// Valid == true, now waiting for ready only
				inc_ready_w();
			} else {
				// Valid == true, ready == true
				restart();

				return true;
			}

			return false;
		}

		void inc_valid_w()
		{
			m_valid_wait++;
			if (m_valid_wait == m_max_clks) {
				std::ostringstream msg;

				msg << m_name << "valid hangup detected!";

				SC_REPORT_ERROR(AXI_HANDSHAKE_ERROR,
						msg.str().c_str());
			}
		}

		void inc_ready_w()
		{
			m_ready_wait++;
			if (m_ready_wait == m_max_clks) {
				std::ostringstream msg;

				msg << m_name << "ready hangup detected!";

				SC_REPORT_ERROR(AXI_HANDSHAKE_ERROR,
						msg.str().c_str());
			}
		}

		void restart()
		{
			m_valid_wait = 0;
			m_ready_wait = 0;
		}

	private:
		std::string m_name;

		sc_in<bool >& m_valid;
		sc_in<bool >& m_ready;

		uint32_t m_valid_wait;
		uint32_t m_ready_wait;
		uint64_t m_max_clks;
	};

private:
	bool in_list(std::list<uint32_t>& l, uint32_t id)
	{
		for (typename std::list<uint32_t>::iterator it = l.begin();
			it != l.end(); it++) {

			if ((*it) == id) {
				return true;
			}
		}
		return false;
	}

	void remove(std::list<uint32_t>& l, uint32_t id)
	{
		for (typename std::list<uint32_t>::iterator it = l.begin();
			it != l.end(); it++) {

			if ((*it) == id) {
				l.erase(it);
				return;
			}
		}
	}

	std::list<uint32_t> m_awids;
	std::list<uint32_t> m_wids;
	std::list<uint32_t> m_bids;
};

template<typename SAMPLE_TYPE>
class monitor_xchannel_stable : public axi_common
{
public:
	template<typename T>
	monitor_xchannel_stable(T *mod) :
		axi_common(mod)
	{}

	template<typename PC>
	void run(PC& pc, sc_in<bool > &valid, sc_in<bool > &ready)
	{
		sc_in<bool >& clk = pc.clk;
		sc_in<bool >& resetn = pc.resetn;

		while (true) {
			SAMPLE_TYPE saved_ch, tmp_ch;

			// Wait for rvalid and sample the rdata bus.
			sc_core::wait(valid.posedge_event() | resetn.negedge_event());
			if (reset_asserted()) {
				wait_for_reset_release();
				continue;
			}

			saved_ch.sample_from(pc);

			// Verify that data resp signals remain stable while master
			// is unable to receive data.
			while (ready == false) {
				sc_core::wait(clk.posedge_event() | resetn.negedge_event());
				if (reset_asserted()) {
					wait_for_reset_release();
					break;
				}

				tmp_ch.sample_from(pc);
				if (!saved_ch.cmp_eq_stable_valid_cycle_signals(tmp_ch)) {
					char msg[256];

					snprintf(msg, sizeof(msg), "%s valid/ready cycle unstable signals violation",
						tmp_ch.get_name());
					SC_REPORT_ERROR(CHECKER_AXI_ERROR, msg);
				}
			}
		}
	}
};

#define GEN_STABLE_MON(ch)									\
	void monitor_ ## ch ## channel_stable(void) {						\
		monitor_xchannel_stable<sample_ ## ch ##channel> mon(this);			\
		mon.run(m_pc, ch ## valid, ch ## ready);					\
	}


class axi_reset_checker : public axi_common
{
public:
	template<typename T>
	axi_reset_checker(T *mod) :
		axi_common(mod),
		resetn(mod->resetn),
		arvalid(mod->arvalid),
		rvalid(mod->rvalid),
		awvalid(mod->awvalid),
		wvalid(mod->wvalid),
		bvalid(mod->bvalid)
	{}

	void run()
	{
		while (true) {

			sc_core::wait(resetn.negedge_event());

			wait_for_reset_release();

			check_valid(arvalid, "ar");
			check_valid(rvalid, "r");

			check_valid(awvalid, "aw");
			check_valid(wvalid, "w");
			check_valid(bvalid, "b");
		}
	}

private:
	void check_valid(sc_in<bool>& valid, std::string prefix)
	{
		if (valid.read() != false) {
			std::ostringstream msg;

			msg << prefix <<
				"valid asserted after at reset release!";

			SC_REPORT_ERROR(AXI_RESET_ERROR, msg.str().c_str());
		}
	}

	sc_in<bool >& resetn;
	sc_in<bool >& arvalid;
	sc_in<bool >& rvalid;
	sc_in<bool >& awvalid;
	sc_in<bool >& wvalid;
	sc_in<bool >& bvalid;
};

#endif /* CHECKER_UTILS_H__ */
