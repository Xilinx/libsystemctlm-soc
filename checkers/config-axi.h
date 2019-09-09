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

#ifndef CONFIG_AXI_H__
#define CONFIG_AXI_H__

#include <tlm-bridges/amba.h>

class __AXIPCConfig
{
public:
	__AXIPCConfig(AXIVersion version) :
		m_mon_data_resp(false),
		m_resp_check(true),
		m_rd_ordering(false),
		m_wr_bursts(false),
		m_wr_wstrb(false),
		m_wr_wstrb_with_gaps(false),
		m_wr_data_order(false),
		m_valid_axlen(false),
		m_addr_align(false),
		m_check_handshakes(false),
		m_reset_check(false),
		m_max_clks(200),
		m_en_disp_all(false),
		m_max_depth(64),
		m_version(version)
	{}

	bool en_stable_data_resp_check() { return m_mon_data_resp; }
	bool en_resp_check() { return m_resp_check; }
	bool en_rd_order_check() { return m_rd_ordering; }
	bool en_wr_bursts_check() { return m_wr_bursts; }

	bool en_wstrb_check() { return m_wr_wstrb; }
	bool allow_wstrb_gaps() { return m_wr_wstrb_with_gaps; }

	bool en_wr_tx_data_order_check() { return m_wr_data_order; }

	bool en_valid_axlen_check() { return m_valid_axlen; }

	bool en_addr_align_check() { return m_addr_align; }

	bool en_handshakes_check() { return m_check_handshakes; }

	bool en_reset_check() { return m_reset_check; }

	uint64_t get_max_clks() { return m_max_clks; }

	enum { MAX_AxSIZE = 7 }; // 1 << MAX_AxSIZE = 128 bytes

	// Dump configuration
	bool en_disp_all() { return m_en_disp_all; }
	std::vector<uint64_t>& get_addresses() { return m_addr; }

	uint32_t max_depth() { return m_max_depth; }

	AXIVersion get_axi_version() { return m_version; }
protected:

	bool m_mon_data_resp;

	bool m_resp_check;
	bool m_rd_ordering;

	bool m_wr_bursts;
	bool m_wr_wstrb;
	bool m_wr_wstrb_with_gaps;
	bool m_wr_data_order;

	bool m_valid_axlen;
	bool m_addr_align;

	bool m_check_handshakes;
	bool m_reset_check;

	uint64_t m_max_clks;

	// Dump configuration
	bool m_en_disp_all;
	std::vector<uint64_t> m_addr;

	uint32_t m_max_depth;

	AXIVersion m_version;
};

class AXIPCConfig : private __AXIPCConfig
{
public:
	AXIPCConfig(AXIVersion version = V_AXI4) :
		__AXIPCConfig(version)
	{}

	// Constructor with all checks enabled.
	// This is useful because it doesn't imply
	// nor need explicit allocation at the caller.
	static AXIPCConfig all_enabled(void) {
		AXIPCConfig cfg;
		cfg.enable_all_checks();
		return cfg;
	}

	//
	// Check that data response signals are stable between rvalid and
	// rready (no changes on the signals are allowed until rready).
	//
	void check_stable_data_resp_signal(bool en = true)
	{
		m_mon_data_resp = en;
	}

	//
	// Check the AXI responses and report errors.
	//
	void check_axi_responses(bool en = true) { m_resp_check = en; }

	//
	// Check that read transactions with the same id are run in order.
	//
	void check_rd_tx_ordering(bool en = true) { m_rd_ordering = en; }

	//
	// Check that wlast is generated on the final transaction wdata transfer.
	//
	void check_wr_tx_data_bursts(bool en = true) { m_wr_bursts = en; }

	//
	// Check the wstrb of the transaction.
	//
	void check_wr_tx_data_wstrb(bool allow_gaps = false, bool en = true)
	{
		m_wr_wstrb = en;
		m_wr_wstrb_with_gaps = allow_gaps;
	}

	//
	// Check that the first data item on AXI3 interleaved data (on the
	// write data channel) is in the order of the addresses.
	//
	void check_wr_tx_data_order(bool en = true) { m_wr_data_order = en; }

	//
	// Verifies burst lengths of transactions taking burst type in
	// consideration (the burst length must be 2, 4, 8 or 16 for wrap
	// transactions)
	//
	void check_valid_axlen(bool en = true) { m_valid_axlen = en; }

	//
	// Verifies address alingment based on burst type (the start address
	// must be aligned to the size of each transfer on wrap transactions)
	//
	void check_address_alignment(bool en = true) { m_addr_align = en; }

	//
	// Verifies that expected handshakes signals on the data an response
	// channels are detected after receiving awvalid and arvalid. It is
	// considered and reported as a hangup if max_clks clock cycles pass
	// before an expected signal has been detected.
	//
	void check_axi_handshakes(bool en = true, uint64_t max_clks = 200)
	{
		m_check_handshakes = en;
		m_max_clks = max_clks;
	}

	//
	// Verify that arvalid, rvalid, awvalid, wvalid and bvalid are
	// deasserted the first cycle after reset has been released.
	//
	void check_axi_reset(bool en = true)
	{
		m_reset_check = en;
	}

	//
	// Enables all checks.
	//
	void enable_all_checks()
	{
		m_mon_data_resp = true;
		m_resp_check = true;
		m_rd_ordering = true;
		m_wr_bursts = true;
		m_wr_wstrb = true;
		m_wr_wstrb_with_gaps = true;
		m_wr_data_order = true;
		m_valid_axlen = true;
		m_addr_align = true;
		m_check_handshakes = true;
		m_reset_check = true;
	}

	//
	// Set the maximum outstanding transactions allowed
	//
	void set_max_outstanding_tx(uint32_t max_depth)
	{
		m_max_depth = max_depth;
	}
};

#endif /* CONFIG_AXI_H__ */
