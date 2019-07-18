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
#ifndef __MASTER_TRI_H__
#define __MASTER_TRI_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "traffic-generators/tg-tlm.h"
#include "tlm-modules/cache-tri.h"

template<int SZ_CACHE, int SZ_CACHELINE>
class TRIMaster :
	public sc_core::sc_module
{
public:

	class Port_M :
		public sc_core::sc_module
	{
	public:
		tlm_utils::simple_initiator_socket<Port_M> init_socket;

		Port_M(sc_core::sc_module_name name) :
			sc_module(name),
			init_socket("init-socket"),
			m_target_socket("m-target-socket")
		{
			// Cache interface, receive ace transactions
			m_target_socket.register_b_transport(this,
							&Port_M::b_transport_ace);

		}

		template<typename T>
		void bind_upstream(T& dev)
		{
			dev.init_socket.bind(m_target_socket);
		}

	private:
		// Receive and forward ace transactions (downstream from cache)
		virtual void b_transport_ace(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			init_socket->b_transport(trans, delay);
		}

		// Upstream interface (to the cache)
		tlm_utils::simple_target_socket<Port_M> m_target_socket;
	};

	Port_M m_port;

	template<typename T>
	TRIMaster(sc_core::sc_module_name name, T& transfers) :
		sc_module(name),
		m_port("m-port"),
		m_gen("gen", 1),
		m_cache("tri-cache")
	{
		// Configure generator
		m_gen.addTransfers(transfers, 0);

		// TLMTrafficGenerator -> cache
		m_gen.socket.bind(m_cache.target_socket);

		// Connect the cache with the port
		m_port.bind_upstream(m_cache);
	}

	template<typename T>
	void connect(T& bridge)
	{
		m_port.init_socket.bind(bridge.tgt_socket);
	}

	void enableDebug() { m_gen.enableDebug(); }

private:
	TLMTrafficGenerator m_gen;
	cache_tri<SZ_CACHE, SZ_CACHELINE> m_cache;
};

#endif
