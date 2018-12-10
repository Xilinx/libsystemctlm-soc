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

#define CHECKER_AXI_ERROR "AXI Protocol Checker Error"
#define AXI_HANDSHAKE_ERROR "axi_handshakes"

class axi_handshakes_checker
{
public:
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
		uint32_t m_rt = 0;
		uint32_t m_wd = 0;
		uint32_t m_b = 0;

		while (true) {
			bool inc_rvalid = m_rt > 0;
			bool inc_wvalid = m_wd > 0;
			bool inc_bvalid = m_b > 0;

			wait(clk.posedge_event());

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
			if (aw_channel.run()) {
				//
				// aw signals received, now expect num_beats wd
				// handshakes
				//
				m_wd += axlen.get_awlen() + 1;
			}
			if (w_channel.run(inc_wvalid)) {
				m_wd--;
				//
				// All beats for one transaction done, now
				// expect bvalid
				//
				if (axlen.get_wlast()) {
					m_b++;
				}
			}
			if (b_channel.run(inc_bvalid)) {
				m_b--;
			}
		}
	}

private:
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
				m_valid_wait = 0;
				m_ready_wait = 0;

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

	private:
		std::string m_name;

		sc_in<bool >& m_valid;
		sc_in<bool >& m_ready;

		uint32_t m_valid_wait;
		uint32_t m_ready_wait;
		uint64_t m_max_clks;
	};
};

template<typename SAMPLE_TYPE>
class monitor_xchannel_stable
{
public:
	template<typename PC>
	void run(PC& pc, sc_in<bool > &valid, sc_in<bool > &ready)
	{
		while (true) {
			SAMPLE_TYPE saved_ch, tmp_ch;

			// Wait for rvalid and sample the rdata bus.
			wait(valid.posedge_event());
			saved_ch.sample_from(pc);

			// Verify that data resp signals remain stable while master
			// is unable to receive data.
			while (ready == false) {
				wait(pc.clk.posedge_event());

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
		monitor_xchannel_stable<sample_ ## ch ##channel> mon;				\
		mon.run(m_pc, ch ## valid, ch ## ready);					\
	}

#endif /* CHECKER_UTILS_H__ */
