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
#ifndef TLM_MODULES_RNF_CHI_H__
#define TLM_MODULES_RNF_CHI_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "traffic-generators/tg-tlm.h"
#include "tlm-modules/cache-chi.h"

template<int NODE_ID, int SZ_CACHE, int ICN_ID = 20>
class RequestNode_F:
	public sc_core::sc_module
{
private:
	class Port_RN_F :
		public sc_core::sc_module
	{
	public:
		tlm_utils::simple_initiator_socket<Port_RN_F> txreq_init_socket;
		tlm_utils::simple_initiator_socket<Port_RN_F> txrsp_init_socket;
		tlm_utils::simple_initiator_socket<Port_RN_F> txdat_init_socket;

		tlm_utils::simple_target_socket<Port_RN_F> rxrsp_tgt_socket;
		tlm_utils::simple_target_socket<Port_RN_F> rxdat_tgt_socket;
		tlm_utils::simple_target_socket<Port_RN_F> rxsnp_tgt_socket;

		Port_RN_F(sc_core::sc_module_name name) :
			sc_module(name),

			txreq_init_socket("txreq-init-socket"),
			txrsp_init_socket("txrsp-init-socket"),
			txdat_init_socket("txdat-init-socket"),

			rxrsp_tgt_socket("rxrsp-tgt-socket"),
			rxdat_tgt_socket("rxdat-tgt-socket"),
			rxsnp_tgt_socket("rxsnp-tgt-socket"),

			m_txreq_tgt_socket("txreq-tgt-socket"),
			m_txrsp_tgt_socket("txrsp-tgt-socket"),
			m_txdat_tgt_socket("txdat-tgt-socket"),

			m_rxrsp_init_socket("rxrsp-init-socket"),
			m_rxdat_init_socket("rxdat-init-socket"),
			m_rxsnp_init_socket("rxsnp-init-socket")
		{
			//
			// Tx forward (to the ICN)
			//
			m_txreq_tgt_socket.register_b_transport(
					this, &Port_RN_F::b_transport_txreq);
			m_txrsp_tgt_socket.register_b_transport(
					this, &Port_RN_F::b_transport_txrsp);
			m_txdat_tgt_socket.register_b_transport(
					this, &Port_RN_F::b_transport_txdat);

			//
			// Rx forward (to the cache)
			//
			rxrsp_tgt_socket.register_b_transport(
					this, &Port_RN_F::b_transport_rxrsp);
			rxdat_tgt_socket.register_b_transport(
					this, &Port_RN_F::b_transport_rxdat);
			rxsnp_tgt_socket.register_b_transport(
					this, &Port_RN_F::b_transport_rxsnp);
		}

		//
		// Forward channels from / to the cache
		//
		template<typename T>
		void bind_upstream(T& dev)
		{
			dev.txreq_init_socket.bind(m_txreq_tgt_socket);
			dev.txrsp_init_socket.bind(m_txrsp_tgt_socket);
			dev.txdat_init_socket.bind(m_txdat_tgt_socket);

			m_rxrsp_init_socket.bind(dev.rxrsp_tgt_socket);
			m_rxdat_init_socket.bind(dev.rxdat_tgt_socket);
			m_rxsnp_init_socket.bind(dev.rxsnp_tgt_socket);
		}

	private:
		//
		// Forward tx channels downstream (to the ICN)
		//
		virtual void b_transport_txreq(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			txreq_init_socket->b_transport(trans, delay);
		}

		virtual void b_transport_txrsp(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			txrsp_init_socket->b_transport(trans, delay);
		}

		virtual void b_transport_txdat(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			txdat_init_socket->b_transport(trans, delay);
		}

		//
		// Forward rx channels upstream (to the cache)
		//
		virtual void b_transport_rxrsp(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			m_rxrsp_init_socket->b_transport(trans, delay);
		}

		virtual void b_transport_rxdat(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			m_rxdat_init_socket->b_transport(trans, delay);
		}

		virtual void b_transport_rxsnp(tlm::tlm_generic_payload& trans,
						sc_time& delay)
		{
			m_rxsnp_init_socket->b_transport(trans, delay);
		}

		//
		// Downstream interface (for forwarding downstream to the ICN)
		//
		tlm_utils::simple_target_socket<Port_RN_F> m_txreq_tgt_socket;
		tlm_utils::simple_target_socket<Port_RN_F> m_txrsp_tgt_socket;
		tlm_utils::simple_target_socket<Port_RN_F> m_txdat_tgt_socket;

		//
		// Upstream interface (for forwarding upstream to the cache)
		//
		tlm_utils::simple_initiator_socket<Port_RN_F> m_rxrsp_init_socket;
		tlm_utils::simple_initiator_socket<Port_RN_F> m_rxdat_init_socket;
		tlm_utils::simple_initiator_socket<Port_RN_F> m_rxsnp_init_socket;
	};

	void ConnectSockets()
	{
		// TLMTrafficGenerator -> cache
		m_gen.socket.bind(m_cache.target_socket);

		// Connect the cache with the port
		port.bind_upstream(m_cache);
	}
public:

	typedef cache_chi<NODE_ID, SZ_CACHE, ICN_ID> cache_chi_t;

	Port_RN_F port;

	RequestNode_F(sc_core::sc_module_name name) :
		sc_module(name),
		port("port-RN-F"),
		m_gen("gen", 1),
		m_cache("cache_chi")
	{
		ConnectSockets();
	}

	template<typename T>
	RequestNode_F(sc_core::sc_module_name name, T& transfers) :
		sc_module(name),
		port("port-RN-F"),
		m_gen("gen", 1),
		m_cache("cache_chi")
	{
		// Configure generator
		m_gen.addTransfers(transfers, 0);

		ConnectSockets();
	}

	template<typename T>
	void connect(T& dev)
	{
		port.txreq_init_socket.bind(dev.txreq_tgt_socket);
		port.txrsp_init_socket.bind(dev.txrsp_tgt_socket);
		port.txdat_init_socket.bind(dev.txdat_tgt_socket);

		dev.rxrsp_init_socket(port.rxrsp_tgt_socket);
		dev.rxdat_init_socket(port.rxdat_tgt_socket);
		dev.rxsnp_init_socket(port.rxsnp_tgt_socket);
	}

	void EnableDebug() { m_gen.enableDebug(); }

	cache_chi_t& GetCache() { return m_cache; }
	TLMTrafficGenerator& GetTrafficGenerator() { return m_gen; }

private:
	TLMTrafficGenerator m_gen;
	cache_chi_t m_cache;
};

#endif /* TLM_MODULES_RNF_CHI_H__ */
