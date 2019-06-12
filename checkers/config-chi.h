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
 * [1] AMBA 5 CHI Architecture Specification, ARM IHI 0050C, ID050218
 *
 */

#ifndef CONFIG_CHI_H__
#define CONFIG_CHI_H__

class __CHIPCConfig
{
public:
	__CHIPCConfig() :
		m_check_requests(false),
		m_check_data_flits(false),
		m_check_snoop_requests(false),
		m_check_responses(false),
		m_check_txn_structures(false),
		m_check_request_retry(false),
		m_check_ch_lcredits(false)
	{}

	bool en_check_requests() { return m_check_requests; }
	bool en_check_data_flits() { return m_check_data_flits; }
	bool en_check_snoop_requests() { return m_check_snoop_requests; }
	bool en_check_responses() { return m_check_responses; }
	bool en_check_txn_structures() { return m_check_txn_structures; }
	bool en_check_request_retry() { return m_check_request_retry; }
	bool en_check_ch_lcredits() { return m_check_ch_lcredits; }

protected:

	bool m_check_requests;
	bool m_check_data_flits;
	bool m_check_snoop_requests;
	bool m_check_responses;
	bool m_check_txn_structures;
	bool m_check_request_retry;
	bool m_check_ch_lcredits;
};

class CHIPCConfig : private __CHIPCConfig
{
public:
	//
	// Check CHI requests
	//
	void check_requests(bool val = true) { m_check_requests = val; }

	//
	// Check CHI data flits
	//
	void check_data_flits(bool val = true) { m_check_data_flits = val; }

	//
	// Check CHI snoop requests
	//
	void check_snoop_requests(bool val = true)
	{
		m_check_snoop_requests = val;
	}

	//
	// Check CHI responses
	//
	void check_responses(bool val = true) { m_check_responses = val; }

	//
	// Check that outstanding link credits on the CHI channels are
	// between 0 - 15 (13.2.1 [1])
	//
	void check_ch_lcredits(bool val = true) { m_check_ch_lcredits = val; }

	//
	// Check transactions structures.
	//
	void check_transaction_structures(bool val = true)
	{
		m_check_txn_structures = val;
	}

	//
	// Check request retries and Protocol Credits.
	//
	void check_request_retry(bool val = true)
	{
		m_check_request_retry = val;
	}

	//
	// Enables all checks.
	//
	void enable_all_checks()
	{
		m_check_requests = true;
		m_check_ch_lcredits = true;
		m_check_request_retry = true;
		m_check_txn_structures = true;
		m_check_responses = true;
		m_check_snoop_requests = true;
		m_check_data_flits = true;
	}
};

#endif /* CONFIG_CHI_H__ */
