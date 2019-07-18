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
 */

#ifndef __CACHE_TRI_H__
#define __CACHE_TRI_H__

#include <list>
#include <vector>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/triattr.h"

template<int CACHE_SZ, int CACHELINE_SZ = 64>
class cache_tri :
	public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<cache_tri> target_socket;

	// Downstream
	tlm_utils::simple_initiator_socket<cache_tri> init_socket;

#if 0
	tlm_utils::simple_target_socket<cache_tri> snoop_target_socket;

		snoop_target_socket("snoop-target-socket"),

		snoop_target_socket.register_b_transport(this, &cache_tri::b_transport_snoop);
#endif

	cache_tri(sc_core::sc_module_name name) :
		sc_core::sc_module(name),
		target_socket("target-socket"),
		init_socket("init-socket"),
		m_cache(NULL)
	{
		m_cache = new CacheWriteThrough(init_socket);

		target_socket.register_b_transport(this, &cache_tri::b_transport);
	}

	~cache_tri()
	{
		delete m_cache;
	}

private:
	class ICache
	{
	public:
		enum { NUM_CACHELINES = CACHE_SZ / CACHELINE_SZ };

		struct CacheLine
		{
			CacheLine() :
				valid(false),
				tag(0),
				shared(false),
				dirty(false)
			{}

			bool valid;
			uint64_t tag;
			bool shared;
			bool dirty;
			unsigned char data[CACHELINE_SZ];
		};

		ICache(tlm_utils::simple_initiator_socket<cache_tri>& init_socket) :
			m_cacheline(new CacheLine[NUM_CACHELINES]),
			m_init_socket(init_socket),
			m_ongoing_gp(NULL)
		{}

		virtual ~ICache()
		{
			delete[] m_cacheline;
		}

		virtual void handle_load(tlm::tlm_generic_payload& gp) = 0;
		virtual void handle_store(tlm::tlm_generic_payload& gp) = 0;

		//
		// Transactions
		//
		void write_unique(tlm::tlm_generic_payload& gp,
					unsigned int pos, unsigned int len)
		{
			if (do_tlm(gp, pos, len)) {
				//
				// Only update lines that are in UC or SC
				// state [1] (C4.8.2 WriteUnique)
				//
				while (pos < len) {
					uint64_t addr = gp.get_address() + pos;
					unsigned int line_offset = get_line_offset(addr);
					unsigned int max_len = CACHELINE_SZ - line_offset;
					unsigned int n = len;

					if (n > max_len) {
						n = max_len;
					}

					if (in_cache(addr)) {
						CacheLine *l = get_line(addr);

						this->write_line(gp, pos, false);

						l->shared = true;
					}

					//
					// Move to next cacheline
					//
					pos+=n;
					addr+=n;
				}
			}
		}

		void read_clean(tlm::tlm_generic_payload& gp,
				uint64_t addr)
		{
			uint64_t tag = get_tag(addr);
			CacheLine *l = get_line(addr);
			unsigned int len = CACHELINE_SZ;

			if (do_tlm(tlm::TLM_READ_COMMAND,
					tag,
					l->data,
					len)) {
				l->valid = true;
				l->tag = tag;
				l->shared = false;
				l->dirty = false;
			}
		}

		// Tag must have been checked before calling this function
		unsigned int read_line(tlm::tlm_generic_payload& gp, unsigned int pos)
		{
			unsigned char *data = gp.get_data_ptr() + pos;
			uint64_t addr = gp.get_address() + pos;
			unsigned int len = gp.get_data_length() - pos;
			unsigned int line_offset = get_line_offset(addr);
			unsigned int max_len = CACHELINE_SZ - line_offset;
			unsigned char *be = gp.get_byte_enable_ptr();
			unsigned int be_len = gp.get_byte_enable_length();
			CacheLine *l = get_line(addr);

			if (len > max_len) {
				len = max_len;
			}

			if (be_len) {
				unsigned int i;

				for (i = 0; i < len; i++, pos++) {
					bool do_access = be[pos % be_len] == TLM_BYTE_ENABLED;

					if (do_access) {
						data[i] = l->data[line_offset + i];
					}
				}
			} else {
				memcpy(data, &l->data[line_offset], len);
			}

			return len;
		}

		// Tag must have been checked before calling this function
		unsigned int write_line(tlm::tlm_generic_payload& gp,
					unsigned int pos, bool dirty = true)
		{
			unsigned char *data = gp.get_data_ptr() + pos;
			uint64_t addr = gp.get_address() + pos;
			unsigned int len = gp.get_data_length() - pos;
			unsigned int line_offset = get_line_offset(addr);
			unsigned int max_len = CACHELINE_SZ - line_offset;
			unsigned char *be = gp.get_byte_enable_ptr();
			unsigned int be_len = gp.get_byte_enable_length();
			CacheLine *l = get_line(addr);

			if (len > max_len) {
				len = max_len;
			}

			if (be_len) {
				unsigned int i;

				for (i = 0; i < len; i++, pos++) {
					bool do_access = be[pos % be_len] == TLM_BYTE_ENABLED;

					if (do_access) {
						l->data[line_offset + i] = data[i];
					}
				}
			} else {
				memcpy(&l->data[line_offset], data, len);
			}

			l->dirty = dirty;

			return len;
		}

		inline unsigned int get_line_offset(uint64_t addr)
		{
			return addr & (CACHELINE_SZ-1);
		}

		inline uint64_t align_address(uint64_t addr)
		{
			return addr & ~(CACHELINE_SZ-1);
		}

		inline uint64_t get_tag(uint64_t addr)
		{
			return align_address(addr);
		}

		inline uint64_t get_index(uint64_t tag)
		{
			return (tag % CACHE_SZ) / CACHELINE_SZ;
		}

		CacheLine *get_line(uint64_t addr)
		{
			uint64 tag = get_tag(addr);
			unsigned int index = get_index(tag);

			return &m_cacheline[index];
		}

		bool in_cache(uint64_t addr)
		{
			uint64 tag = get_tag(addr);
			CacheLine *l = get_line(addr);

			if (!l->valid) {
				return false;
			}

			return l->tag == tag;
		}

		bool is_unique(uint64_t addr)
		{
			CacheLine *l = get_line(addr);

			return l->shared == false;
		}

		unsigned int to_write(tlm::tlm_generic_payload& gp,
					unsigned int pos)
		{
			uint64_t addr = gp.get_address() + pos;
			unsigned int len = gp.get_data_length() - pos;
			unsigned int line_offset = this->get_line_offset(addr);
			unsigned int max_len = CACHELINE_SZ - line_offset;

			if (len > max_len) {
				len = max_len;
			}

			return len;
		}

		bool exec_tlm_gp(tlm::tlm_generic_payload& exec_gp)
		{
			sc_time delay(SC_ZERO_TIME);

			m_ongoing_gp = &exec_gp;

			m_init_socket->b_transport(exec_gp, delay);

			m_ongoing_gp = NULL;

			return exec_gp.get_response_status() == tlm::TLM_OK_RESPONSE;
		}

		bool do_tlm(tlm::tlm_generic_payload& gp_org,
				unsigned int pos = 0,
				unsigned int len = 0)
		{
			unsigned char *data = gp_org.get_data_ptr() + pos;
			uint64_t addr = gp_org.get_address() + pos;
			uint32_t be_len = gp_org.get_byte_enable_length();
			uint8_t be[be_len];
			tlm::tlm_generic_payload gp;

			if (len == 0) {
				len = gp_org.get_data_length();
			}

			gp.set_command(gp_org.get_command());

			gp.set_address(addr);

			gp.set_data_length(len);
			gp.set_data_ptr(data);

			if (be_len >= gp_org.get_data_length()) {
				gp.set_byte_enable_ptr(gp_org.get_byte_enable_ptr() + pos);
				gp.set_byte_enable_length(len);
			} else {
				unsigned int i;
				uint8_t *be_org = gp_org.get_byte_enable_ptr();

				for (i = 0; i < be_len; i++) {
					unsigned int be_idx = pos + i;

					be[i] = be_org[be_idx % be_len];
				}

				gp.set_byte_enable_ptr(be);
				gp.set_byte_enable_length(be_len);
			}

			gp.set_streaming_width(len);

			gp.set_dmi_allowed(false);
			gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

			return exec_tlm_gp(gp);
		}

		bool do_tlm(tlm::tlm_command cmd, uint64_t addr, unsigned char *data,
				unsigned int len)
		{
			tlm::tlm_generic_payload gp;

			gp.set_command(cmd);

			gp.set_address(addr);

			gp.set_data_length(len);
			gp.set_data_ptr(data);

			gp.set_byte_enable_ptr(NULL);
			gp.set_byte_enable_length(0);

			gp.set_streaming_width(len);

			gp.set_dmi_allowed(false);
			gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

			return exec_tlm_gp(gp);
		}

	protected:
		CacheLine *m_cacheline;
		tlm_utils::simple_initiator_socket<cache_tri>& m_init_socket;
		tlm::tlm_generic_payload *m_ongoing_gp;
	};

	class CacheWriteThrough : public ICache
	{
	public:
		CacheWriteThrough(tlm_utils::simple_initiator_socket<cache_tri>& init_socket) :
			ICache(init_socket)
		{}

		void handle_load(tlm::tlm_generic_payload& gp)
		{
			uint64_t addr = gp.get_address();
			unsigned int len = gp.get_data_length();
			unsigned int pos = 0;

			while (pos < len) {
				if (this->in_cache(addr)) {
					unsigned int n = this->read_line(gp, pos);
					pos+=n;
					addr+=n;
				} else {
					this->read_clean(gp, addr);
				}
			}

			gp.set_response_status(tlm::TLM_OK_RESPONSE);
		}

		void handle_store(tlm::tlm_generic_payload& gp)
		{
			unsigned int len = gp.get_data_length();
			unsigned int pos = 0;

			while (pos < len) {
				unsigned int n = this->to_write(gp, pos);

				this->write_unique(gp, pos, n);

				pos+=n;
			}

			gp.set_response_status(tlm::TLM_OK_RESPONSE);
		}
	};

	virtual void b_transport(tlm::tlm_generic_payload& trans,
				sc_time& delay)
	{
		m_mutex.lock();

		wait(delay);
		delay = SC_ZERO_TIME;

		if (trans.is_write()) {
			m_cache->handle_store(trans);
		} else if (trans.is_read()){
			m_cache->handle_load(trans);
		}

		m_mutex.unlock();
	}

#if 0
	virtual void b_transport_snoop(tlm::tlm_generic_payload& gp,
				sc_time& delay)
	{
	}
#endif

	sc_mutex m_mutex;

	ICache *m_cache;
};

#endif /* __CACHE_TRI_H__ */
