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
 * References:
 *
 *
 * [1] AMBA AXI and ACE Protocol Specification, ARM IHI 0022D, ID102711
 *
 */

#ifndef TLM_EXMON_H__
#define TLM_EXMON_H__

#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/genattr.h"

class tlm_exclusive_monitor : public sc_core::sc_module
{
public:
	tlm_utils::simple_initiator_socket<tlm_exclusive_monitor> init_socket;
	tlm_utils::simple_target_socket<tlm_exclusive_monitor> target_socket;

	tlm_exclusive_monitor(sc_core::sc_module_name name,
				uint32_t id_mask = 0xF) :
		sc_core::sc_module(name),
		m_id_mask(id_mask)
	{
		target_socket.register_b_transport(this, &tlm_exclusive_monitor::b_transport);
	}

	~tlm_exclusive_monitor()
	{
		monitor_clear();
	}

private:
	class Transaction
	{
	public:
		Transaction(tlm::tlm_generic_payload& gp, uint32_t id_mask) :
			m_id_mask(id_mask)
		{
			genattr_extension *genattr;

			m_gp.set_address(gp.get_address());
			m_gp.set_data_length(gp.get_data_length());

			gp.get_extension(genattr);
			if (genattr) {
				m_genattr.copy_from(*genattr);
			}
		}

		bool has_location(tlm::tlm_generic_payload& gp)
		{
			uint64_t addr = m_gp.get_address();
			unsigned int len = m_gp.get_data_length();

			return gp.get_address() >= addr &&
				gp.get_address() < (addr + len);
		}

		bool has_same_location(tlm::tlm_generic_payload& gp)
		{
			return m_gp.get_address() == gp.get_address() &&
				m_gp.get_data_length() == gp.get_data_length();
		}

		bool has_masked_id(tlm::tlm_generic_payload& gp)
		{
			genattr_extension *genattr;

			gp.get_extension(genattr);
			if (genattr) {
				uint32_t masked_id =
					genattr->get_transaction_id() & m_id_mask;

				return get_masked_id() == masked_id;
			}

			return false;
		}


		//
		// Get the masked id ([1] recommends one exclusive monitor for
		// every exclusive capable master).
		//
		uint32_t get_masked_id()
		{
			return m_genattr.get_transaction_id() & m_id_mask;
		}

	private:
		tlm::tlm_generic_payload m_gp;
		genattr_extension m_genattr;
		uint32_t m_id_mask;
	};

	void monitor_clear()
	{
		for (std::list<Transaction*>::iterator it = m_monitor.begin();
			it != m_monitor.end();) {
			Transaction *t = (*it);

			it = m_monitor.erase(it);
			delete t;
		}
	}

	bool is_exclusive(tlm::tlm_generic_payload& trans)
	{
		genattr_extension *genattr;

		trans.get_extension(genattr);
		if (genattr) {
			return genattr->get_exclusive();
		}

		return false;
	}

	bool is_monitored_location(tlm::tlm_generic_payload& trans)
	{
		for (std::list<Transaction*>::iterator it = m_monitor.begin();
			it != m_monitor.end(); it++) {
			Transaction *t = (*it);

			if (t->has_masked_id(trans) &&
				t->has_same_location(trans)) {
				return true;
			}
		}
		return false;
	}

	void monitor_clear_locations(tlm::tlm_generic_payload& trans)
	{
		for (std::list<Transaction*>::iterator it = m_monitor.begin();
			it != m_monitor.end();) {
			Transaction *t = (*it);

			if (t->has_location(trans)) {
				it = m_monitor.erase(it);
				delete t;
			} else {
				it++;
			}
		}
	}

	void monitor_clear_id(uint32_t masked_id)
	{
		for (std::list<Transaction*>::iterator it = m_monitor.begin();
			it != m_monitor.end(); it++) {
			Transaction *t = (*it);

			if (t->get_masked_id() == masked_id) {
				m_monitor.remove(t);
				delete t;
				return;
			}
		}
	}

	void monitor_location(tlm::tlm_generic_payload& trans)
	{
		Transaction *t = new Transaction(trans, m_id_mask);

		// If already monitoring transaction ID, remove the old one.
		monitor_clear_id(t->get_masked_id());

		m_monitor.push_back(t);
	}

	void set_exclusive_handled(tlm::tlm_generic_payload& trans)
	{
		genattr_extension *genattr;

		trans.get_extension(genattr);

		assert(genattr);

		if (genattr)
		{
			genattr->set_exclusive_handled();
		}
	}

	virtual void b_transport(tlm::tlm_generic_payload& trans,
				sc_time& delay)
	{
		if (trans.is_write()) {
			if (is_exclusive(trans)) {

				set_exclusive_handled(trans);

				if (is_monitored_location(trans)) {
					monitor_clear_locations(trans);
				} else {
					//
					// Target address was written to before
					// the exclusive write or the
					// correspending exclusive read was
					// never received. Don't update the
					// memory location but return ok as
					// response.
					//

					trans.set_response_status(tlm::TLM_OK_RESPONSE);
					return;
				}

			} else {
				monitor_clear_locations(trans);
			}
		}

		init_socket->b_transport(trans, delay);

		if (trans.is_read()) {
			if (is_exclusive(trans) &&
				trans.get_response_status() == tlm::TLM_OK_RESPONSE) {
				//
				// Exclusive read, start monitoring.
				//
				monitor_location(trans);

				set_exclusive_handled(trans);
			}
		}
	}

	std::list<Transaction*> m_monitor;
	uint32_t m_id_mask;
};
#endif
