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

#ifndef CONFIG_AXILITE_H__
#define CONFIG_AXILITE_H__

#include <tlm-bridges/amba.h>

class __AXILitePCConfig
{
public:
	__AXILitePCConfig() :
		m_mon_data_resp(false),
		m_resp_check(true),
		m_check_handshakes(false),
		m_reset_check(false),
		m_max_clks(200),
		m_max_depth(64)
	{}

	bool en_stable_data_resp_check() { return m_mon_data_resp; }

	bool en_resp_check() { return m_resp_check; }
	bool en_reset_check() { return m_reset_check; }

	bool en_handshakes_check() { return m_check_handshakes; }
	uint64_t get_max_clks() { return m_max_clks; }

	uint32_t max_depth() { return m_max_depth; }
protected:
	bool m_mon_data_resp;

	bool m_resp_check;

	bool m_check_handshakes;
	bool m_reset_check;

	uint64_t m_max_clks;

	uint32_t m_max_depth;
};

class AXILitePCConfig : private __AXILitePCConfig
{
public:
	AXILitePCConfig()
	{}

	// Constructor with all checks enabled.
	// This is useful because it doesn't imply
	// nor need explicit allocation at the caller.
	static AXILitePCConfig all_enabled(void) {
		AXILitePCConfig cfg;
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
	// Verifies that expected handshakes signals on the data an response
	// channels are detected after receiving awvalid and arvalid. It is
	// considered and reported as a hangup if max_clks clock cycles pass
	// before an expected signal has been detected.
	//
	void check_axi_handshakes(bool en = true, uint64_t max_clks = 200)
	{
		m_check_handshakes = en;
		m_resp_check = true;
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

#endif /* CONFIG_AXILITE_H__ */
