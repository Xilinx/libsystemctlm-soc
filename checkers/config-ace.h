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
 *
 *
 * References:
 *
 * [1] AMBA AXI and ACE Protocol Specification, ARM IHI 0022D, ID102711
 *
 */

#ifndef CONFIG_ACE_H__
#define CONFIG_ACE_H__

#include <tlm-bridges/amba.h>

class __ACEPCConfig
{
public:
	__ACEPCConfig() :
		m_mon_data_resp(false),
		m_check_handshakes(false),
		m_reset_check(false),
		m_rd_tx_check(false),
		m_wr_tx_check(false),
		m_wr_wstrb(false),
		m_wr_wstrb_with_gaps(false),
		m_resp_check(false),
		m_ace_snoop_ch_check(false),
		m_ace_barrier_check(false),
		m_ace_cd_data_check(false),
		m_max_clks(200),
		m_cacheline_sz(64),
		m_max_depth(64)
	{}

	bool en_stable_data_resp_check() { return m_mon_data_resp; }

	bool en_handshakes_check() { return m_check_handshakes; }

	bool en_reset_check() { return m_reset_check; }

	bool en_rd_tx_check() { return m_rd_tx_check; }

	bool en_wr_tx_check() { return m_wr_tx_check; }

	bool en_wstrb_check() { return m_wr_wstrb; }
	bool allow_wstrb_gaps() { return m_wr_wstrb_with_gaps; }

	bool en_resp_check() { return m_resp_check; }

	bool en_ace_snoop_ch_check() { return m_ace_snoop_ch_check; }

	bool en_ace_barrier_check() { return m_ace_barrier_check; }

	bool en_ace_cd_data_check() { return m_ace_cd_data_check; }

	uint64_t get_max_clks() { return m_max_clks; }

	uint64_t get_cacheline_sz() { return m_cacheline_sz; }

	uint32_t max_depth() { return m_max_depth; }

	AXIVersion get_axi_version() { return V_AXI4; }

	void set_cacheline_size(uint64_t size)
	{
		m_cacheline_sz = size;
	}
protected:

	bool m_mon_data_resp;

	bool m_check_handshakes;
	bool m_reset_check;
	bool m_rd_tx_check;
	bool m_wr_tx_check;
	bool m_wr_wstrb;
	bool m_wr_wstrb_with_gaps;
	bool m_resp_check;
	bool m_ace_snoop_ch_check;
	bool m_ace_barrier_check;
	bool m_ace_cd_data_check;

	uint64_t m_max_clks;
	uint64_t m_cacheline_sz;

	// Dump configuration
	std::vector<uint64_t> m_addr;

	uint32_t m_max_depth;
};

class ACEPCConfig : private __ACEPCConfig
{
public:
	//
	// Check that data response signals are stable between rvalid and
	// rready (no changes on the signals are allowed until rready).
	//
	void check_stable_data_resp_signal(bool en = true)
	{
		m_mon_data_resp = en;
	}

	//
	// Check the ACE responses and report errors.
	//
	void check_ace_responses(bool en = true) { m_resp_check = en; }

	//
	// Verifies that expected handshakes signals on the data an
	// response channels are detected after receiving awvalid, arvalid
	// and acvalid. It is considered and reported as a hangup if
	// max_clks clock cycles pass before an expected signal has been
	// detected.
	//
	void check_ace_handshakes(bool en = true, uint64_t max_clks = 200)
	{
		m_check_handshakes = en;
		m_max_clks = max_clks;
	}

	//
	// Verify that arvalid, rvalid, awvalid, wvalid, bvalid, and in
	// case of ACE mode that rack, wack, acvalid, crvalid and cdvalid
	// are deasserted the first cycle after reset has been released.
	//
	void check_ace_reset(bool en = true)
	{
		m_reset_check = en;
	}

	//
	// Check read transactions signaling (ar and r channel). This check
	// verifies signaling on the ar and r channels. On the ar channel the
	// signaling is validated according to section C3.1.5 [1] (for ACELite
	// according to C11.2 [1]) and on the r channel a check on rlast is
	// performed.
	//
	void check_rd_tx(bool en = true) { m_rd_tx_check = en; }

	//
	// Checks write transaction signaling (aw, w and b channel). On the aw
	// channel the signaling is validated according to section C3.1.5 [1]
	// (for ACELite according to C11.2 [1]) and on the w channel a check on
	// wlast is performed.
	//
	void check_wr_tx(bool en = true) { m_wr_tx_check = en; }

	//
	// Check the wstrb of the transaction.
	//
	void check_wr_tx_data_wstrb(bool allow_gaps = false, bool en = true)
	{
		m_wr_wstrb = en;
		m_wr_wstrb_with_gaps = allow_gaps;
	}

	//
	// Check ACE ac, cr and cd snoop channel signaling. This check can only
	// be enabled for ACE signaling and is not applicable for ACELite.
	//
	void check_ace_snoop_ch_signaling(bool en = true)
	{
		m_ace_snoop_ch_check = en;
	}

	//
	// Check that ACE barriers pairs are found and that barriers are issued
	// in the same sequence on the read and write address channels.
	//
	void check_ace_barriers(bool en = true)
	{
		m_ace_barrier_check = en;
	}

	//
	// Track an ACE master's cacheline allocations and check that it
	// responds with data on the snoop cd channel for read snoops as
	// recommended in [1] (section 5.2.2). A requirement for this check is
	// that the master supports snoop filters. This check can only be
	// enabled for ACE signaling and is not applicable for ACELite.
	//
	void check_ace_cd_data(bool en = true)
	{
		m_ace_cd_data_check = en;
	}

	//
	// Enables all checks.
	//
	void enable_all_checks()
	{
		m_mon_data_resp = true;
		m_check_handshakes = true;
		m_rd_tx_check = true;
		m_wr_tx_check = true;
		m_wr_wstrb = true;
		m_wr_wstrb_with_gaps = true;
		m_resp_check = true;
		m_reset_check = true;
		m_ace_snoop_ch_check = true;
		m_ace_barrier_check = true;
		m_ace_cd_data_check = true;
	}

	//
	// Set the maximum outstanding transactions allowed
	//
	void set_max_outstanding_tx(uint32_t max_depth)
	{
		m_max_depth = max_depth;
	}
};

#endif /* CONFIG_ACE_H__ */
