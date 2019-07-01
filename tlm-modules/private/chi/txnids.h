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

#ifndef TLM_MODULES_PRIV_CHI_TXNIDS_H__
#define TLM_MODULES_PRIV_CHI_TXNIDS_H__

namespace AMBA {
namespace CHI {

class TxnIDs
{
public:
	enum { NumIDs = 256 };

	TxnIDs()
	{
		for (uint32_t i = 0; i < NumIDs; i++) {
			m_ids.push_back(static_cast<uint8_t>(i));
		}
	}

	uint8_t GetID()
	{
		uint8_t id;

		if (m_ids.empty()) {
			sc_core::wait(m_returnIDEvent);
		}

		id = m_ids.front();
		m_ids.pop_front();

		return id;
	}

	void ReturnID(uint8_t id)
	{
		m_ids.push_back(id);
		m_returnIDEvent.notify();
	}
private:
	std::list<uint8_t> m_ids;
	sc_event m_returnIDEvent;
};

}; // namespace CHI
}; // namespace AMBA

#endif /* TLM_MODULES_PRIV_CHI_TXNIDS_H__ */
