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
 *
 *
 * References:
 *
 * [1] AMBA AXI and ACE Protocol Specification, ARM IHI 0022D, ID102711
 *
 */

#ifndef CHECKER_AXILITE_H__
#define CHECKER_AXILITE_H__

#include "checker-utils.h"
#include <list>
#include <sstream>
#include <vector>

#define AXI_RESPONSE_ERROR "axi_response"

AXILITE_CHECKER(checker_axilite_stable)
{
public:
	AXILITE_CHECKER_CTOR(checker_axilite_stable)
	{
		SC_THREAD(monitor_archannel_stable);
		SC_THREAD(monitor_awchannel_stable);
		SC_THREAD(monitor_wchannel_stable);
		SC_THREAD(monitor_bchannel_stable);
		SC_THREAD(monitor_rchannel_stable);
	}

private:
#define SAMPLE_SIGNAL(d, s) s = d.s
	class sample_awchannel {
	public:
		bool awvalid;
		bool awready;
		sc_bv<T::ADDR_W> awaddr;
		sc_bv<3> awprot;

		bool cmp_eq_stable_valid_cycle_signals(const sample_awchannel& rhs) {
			bool eq = true;

			eq &= awaddr == rhs.awaddr;
			eq &= awprot == rhs.awprot;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, awvalid);
			SAMPLE_SIGNAL(dev, awready);
			SAMPLE_SIGNAL(dev, awaddr);
			SAMPLE_SIGNAL(dev, awprot);
		}

		const char *get_name(void) { return "awchannel"; }
	};

	class sample_archannel {
	public:
		bool arvalid;
		bool arready;
		sc_bv<T::ADDR_W> araddr;
		sc_bv<3> arprot;

		bool cmp_eq_stable_valid_cycle_signals(const sample_archannel& rhs) {
			bool eq = true;

			eq &= araddr == rhs.araddr;
			eq &= arprot == rhs.arprot;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, arvalid);
			SAMPLE_SIGNAL(dev, arready);
			SAMPLE_SIGNAL(dev, araddr);
			SAMPLE_SIGNAL(dev, arprot);
		}

		const char *get_name(void) { return "archannel"; }
	};

	class sample_wchannel {
	public:
		bool wvalid;
		bool wready;
		sc_bv<T::DATA_W> wdata;
		sc_bv<T::DATA_W/8> wstrb;

		bool cmp_eq_stable_valid_cycle_signals(const sample_wchannel& rhs) {
			bool eq = true;

			eq &= wdata == rhs.wdata;
			eq &= wstrb == rhs.wstrb;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, wvalid);
			SAMPLE_SIGNAL(dev, wready);
			SAMPLE_SIGNAL(dev, wdata);
			SAMPLE_SIGNAL(dev, wstrb);
		}

		const char *get_name(void) { return "wchannel"; }
	};

	class sample_bchannel {
	public:
		bool bvalid;
		bool bready;
		sc_bv<2> bresp;

		bool cmp_eq_stable_valid_cycle_signals(const sample_bchannel& rhs) {
			bool eq = true;

			eq &= bresp == rhs.bresp;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, bvalid);
			SAMPLE_SIGNAL(dev, bready);
			SAMPLE_SIGNAL(dev, bresp);
		}

		const char *get_name(void) { return "bchannel"; }
	};

	class sample_rchannel {
	public:
		bool rvalid;
		bool rready;
		sc_bv<T::DATA_W> rdata;
		sc_bv<2> rresp;

		bool cmp_eq_stable_valid_cycle_signals(const sample_rchannel& rhs) {
			bool eq = true;

			eq &= rdata == rhs.rdata;
			eq &= rresp == rhs.rresp;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, rvalid);
			SAMPLE_SIGNAL(dev, rready);
			SAMPLE_SIGNAL(dev, rdata);
			SAMPLE_SIGNAL(dev, rresp);
		}

		const char *get_name(void) { return "rchannel"; }
	};

	GEN_STABLE_MON(aw)
	GEN_STABLE_MON(ar)
	GEN_STABLE_MON(w)
	GEN_STABLE_MON(b)
	GEN_STABLE_MON(r)
};

AXILITE_CHECKER(check_axilite_handshakes)
{
public:
	AXILITE_CHECKER_CTOR(check_axilite_handshakes)
	{
		if (m_cfg.en_handshakes_check()) {
			SC_THREAD(axi_handshakes_check);
		}
	}

private:
	class IAxLen
	{
	public:
		bool hasData() { return true; }
		uint32_t get_arlen() { return 0; }
		uint32_t get_awlen() { return 0; }
		bool get_wlast() { return true; }

		uint32_t get_awid() { return 0; }
		uint32_t get_wid() { return 0; }
		uint32_t get_bid() { return 0; }

		bool is_axi3() { return false; }
		bool is_axi4lite() { return true; }
	};

	void axi_handshakes_check()
	{
		axi_handshakes_checker checker(this);
		IAxLen axlen;

		checker.run(m_pc, m_cfg, axlen);
	}
};

AXILITE_CHECKER(check_axilite_responses)
{
public:
	AXILITE_CHECKER_CTOR(check_axilite_responses)
	{
		if (m_cfg.en_resp_check()) {
			SC_THREAD(axi_resp_check);
		}
	}

private:
	void axi_resp_check()
	{
		while (true) {

			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				wait_for_reset_release();
				continue;
			}

			if (rvalid.read() && rready.read()) {
				if (to_uint(rresp) != AXI_OKAY) {
					std::ostringstream msg;

					msg << "Error response identifed, "
						<< "rresp: 0x" << std::hex
						<< to_uint(rresp);

					SC_REPORT_ERROR(AXI_RESPONSE_ERROR,
							msg.str().c_str());
				}
			}

			if (bvalid.read() && bready.read()) {
				if (to_uint(bresp) != AXI_OKAY) {
					std::ostringstream msg;

					msg << "Error response identifed, "
						<< "bresp: 0x" << std::hex
						<< to_uint(bresp);

					SC_REPORT_ERROR(AXI_RESPONSE_ERROR,
							msg.str().c_str());
				}
			}
		}
	}
};

AXILITE_CHECKER(check_axilite_reset)
{
public:
	AXILITE_CHECKER_CTOR(check_axilite_reset)
	{
		if (m_cfg.en_reset_check()) {
			SC_THREAD(axi_reset_check);
		}
	}

private:
	void axi_reset_check()
	{
		axi_reset_checker checker(this);

		checker.run();
	}
};

#endif
