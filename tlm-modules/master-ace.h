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
 */
#ifndef __MASTER_ACE_H__
#define __MASTER_ACE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "traffic-generators/tg-tlm.h"
#include "tlm-modules/cache-ace.h"
#include "tlm-modules/bp-ace.h"

template<int SZ_CACHE, int SZ_CACHELINE>
class ACEMaster :
	public sc_core::sc_module
{
public:
	class ACEPort_M :
		public sc_core::sc_module
	{
	public:
		tlm_utils::simple_initiator_socket<ACEPort_M> init_socket;
		tlm_utils::simple_target_socket<ACEPort_M> snoop_target_socket;

		ACEPort_M(sc_core::sc_module_name name) :
			sc_module(name),
			init_socket("init_socket"),
			snoop_target_socket("snoop_target_socket"),
			m_target_socket("m_target_socket"),
			m_snoop_init_socket("m_snoop_init_socket")
		{
			// Receive snoop transactions
			snoop_target_socket.register_b_transport(this,
						&ACEPort_M::b_transport_snoop);

			// Cache interface, receive ace transactions
			m_target_socket.register_b_transport(this,
							&ACEPort_M::b_transport_ace);

		}

		template<typename T>
		void bind_upstream(T& dev)
		{
			dev.init_socket.bind(m_target_socket);
			m_snoop_init_socket.bind(dev.snoop_target_socket);
		}

	private:
		// Receive and forward ace transactions (downstream from cache)
		virtual void b_transport_ace(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			init_socket->b_transport(trans, delay);
		}

		// Receive and forward snoop transactions (upstream to cache)
		virtual void b_transport_snoop(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			m_snoop_init_socket->b_transport(trans, delay);
		}

		// Upstream interface (to the cache)
		tlm_utils::simple_target_socket<ACEPort_M> m_target_socket;
		tlm_utils::simple_initiator_socket<ACEPort_M> m_snoop_init_socket;
	};

	ACEPort_M m_ace_port;

	ACEMaster(sc_core::sc_module_name name,
				WritePolicy write_policy = WriteBack) :
		sc_module(name),
		m_ace_port("m_ace_port"),
		m_gen("gen", 1),
		m_barrier_processer("barrier_processer"),
		m_cache("ace_cache", write_policy)
	{
		ConnectSockets();
	}

	template<typename T>
	ACEMaster(sc_core::sc_module_name name, T& transfers,
				WritePolicy write_policy = WriteBack) :
		sc_module(name),
		m_ace_port("m_ace_port"),
		m_gen("gen", 1),
		m_barrier_processer("barrier_processer"),
		m_cache("ace_cache", write_policy)
	{
		// Configure generator
		m_gen.addTransfers(transfers, 0);

		ConnectSockets();
	}

	template<typename T>
	void connect(T& bridge)
	{
		m_ace_port.init_socket.bind(bridge.tgt_socket);
		bridge.snoop_init_socket.bind(m_ace_port.snoop_target_socket);
	}

	void enableDebug() { m_gen.enableDebug(); }

	void CreateNonShareableRegion(uint64_t start, unsigned int len)
	{
		m_cache.create_nonshareable_region(start, len);
	}

	TLMTrafficGenerator& GetTrafficGenerator() { return m_gen; }
private:

	void ConnectSockets()
	{
		// TLMTrafficGenerator -> barrier processer
		m_gen.socket.bind(m_barrier_processer.target_socket);

		// barrier processer -> cache
		m_barrier_processer.init_socket.bind(m_cache.target_socket);

		// Connect the cache with the port
		m_ace_port.bind_upstream(m_cache);
	}

	TLMTrafficGenerator m_gen;
	BarrierProcesser m_barrier_processer;
	cache_ace<SZ_CACHE, SZ_CACHELINE> m_cache;
};

class ACELiteMaster :
	public sc_core::sc_module
{
public:
	class ACELitePort_M :
		public sc_core::sc_module
	{
	public:
		// Initiator against the interconnect
		tlm_utils::simple_initiator_socket<ACELitePort_M> init_socket;

		// Upstream interface (where traffic generator connects)
		tlm_utils::simple_target_socket<ACELitePort_M> target_socket;

		ACELitePort_M(sc_core::sc_module_name name) :
			sc_module(name),
			init_socket("init_socket"),
			target_socket("target_socket")
		{
			target_socket.register_b_transport(this,
							&ACELitePort_M::b_transport);

		}

	private:
		// Receive and forward transactions (from the traffic
		// generator to the interconnect)
		virtual void b_transport(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			if (trans.is_write()) {
				write_unique(trans);
			} else if (trans.is_read()) {
				read_once(trans);
			}
		}

		void write_unique(tlm::tlm_generic_payload& gp)
		{
			genattr_extension genattr;
			genattr_extension *attr;

			genattr.set_bufferable(true);
			genattr.set_modifiable(true);
			genattr.set_read_allocate(true);
			genattr.set_write_allocate(true);

			genattr.set_secure(false);

			gp.get_extension(attr);
			if (attr) {
				// Leave as normal access (Sec 3.1.5 [1])

				genattr.set_qos(attr->get_qos());
				genattr.set_secure(attr->get_secure());
				genattr.set_region(attr->get_region());
			}

			genattr.set_domain(Domain::Inner);
			genattr.set_snoop(AW::WriteUnique);

			if (do_tlm(gp, genattr)) {
				gp.set_response_status(tlm::TLM_OK_RESPONSE);
			} else {
				gp.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
			}
		}

		void read_once(tlm::tlm_generic_payload& gp)
		{
			genattr_extension genattr;
			genattr_extension *attr;

			genattr.set_bufferable(true);
			genattr.set_modifiable(true);
			genattr.set_read_allocate(true);
			genattr.set_write_allocate(true);

			gp.get_extension(attr);
			if (attr) {
				// Leave as normal access (Sec 3.1.5 [1])

				genattr.set_qos(attr->get_qos());
				genattr.set_secure(attr->get_secure());
				genattr.set_region(attr->get_region());
			}

			genattr.set_domain(Domain::Inner);
			genattr.set_snoop(AR::ReadOnce);

			if (do_tlm(gp, genattr)) {
				gp.set_response_status(tlm::TLM_OK_RESPONSE);
			} else {
				gp.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
			}
		}

		bool do_tlm(tlm::tlm_generic_payload& gp_org,
				genattr_extension& attr)
		{
			genattr_extension *genattr;
			sc_time delay(SC_ZERO_TIME);
			tlm::tlm_generic_payload gp;

			genattr = new genattr_extension();
			genattr->copy_from(attr);

			gp.set_command(gp_org.get_command());

			gp.set_address(gp_org.get_address());

			gp.set_data_length(gp_org.get_data_length());
			gp.set_data_ptr(gp_org.get_data_ptr());

			gp.set_byte_enable_ptr(gp_org.get_byte_enable_ptr());
			gp.set_byte_enable_length(gp_org.get_byte_enable_length());

			gp.set_streaming_width(gp_org.get_streaming_width());

			gp.set_dmi_allowed(false);
			gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

			gp.set_extension(genattr);

			init_socket->b_transport(gp, delay);

			return gp.get_response_status() == tlm::TLM_OK_RESPONSE;
		}
	};

	ACELitePort_M m_acelite_port;

	template<typename T>
	ACELiteMaster(sc_core::sc_module_name name, T& transfers) :
		sc_module(name),
		m_acelite_port("m_acelite_port"),
		m_gen("gen", 1)
	{
		// Configure generator
		m_gen.addTransfers(transfers, 0);

		// TLMTrafficGenerator -> cache
		m_gen.socket.bind(m_acelite_port.target_socket);
	}

	template<typename T>
	void connect(T& bridge)
	{
		m_acelite_port.init_socket.bind(bridge.tgt_socket);
	}

	void enableDebug() { m_gen.enableDebug(); }

private:
	TLMTrafficGenerator m_gen;
};

#endif
