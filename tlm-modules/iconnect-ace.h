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
 * References:
 *
 *
 * [1] AMBA AXI and ACE Protocol Specification, ARM IHI 0022D, ID102711
 *
 */

#ifndef __ICONNECT_ACE_H__
#define __ICONNECT_ACE_H__

#include <sstream>
#include <list>

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/genattr.h"
#include "tlm-bridges/amba.h"

template<
	int NUM_ACE_MASTERS = 2,
	int NUM_ACELITE_MASTERS = 1,
	int CACHELINE_SZ = 64>
class iconnect_ace : public sc_core::sc_module
{
public:
	class Transaction :
		public ace_tx_helpers
	{
	public:
		enum { INTERCONNECT_TR_ID = NUM_ACE_MASTERS,
			ACELite_ID_offset = 1024 };

		Transaction(tlm::tlm_generic_payload& gp,
				int port_id = INTERCONNECT_TR_ID) :
			m_gp(gp),
			m_port_id(port_id),
			m_is_read_once(is_read_once(gp)),
			m_is_write_unique(is_write_unique(gp)),
			m_is_write_line_unique(is_write_line_unique(gp)),
			m_n_segments(num_segments(gp)),
			m_is_acelite(is_acelite(port_id))
		{
			setup_ace_helpers(&m_gp);
		}

		inline bool is_acelite(int port_id)
		{
			return port_id >= ACELite_ID_offset;
		}

		unsigned int num_segments(tlm::tlm_generic_payload& gp)
		{
			uint64_t aligned_start = gp.get_address() & ~(CACHELINE_SZ-1);
			uint64_t aligned_end;

			// Address of last byte in the transfer
			aligned_end = gp.get_address() + gp.get_data_length() - 1;

			// End up in next cacheline
			aligned_end += CACHELINE_SZ;

			// Get address of the first byte of the next cacheline
			aligned_end &= ~(CACHELINE_SZ-1);

			return (aligned_end - aligned_start) / CACHELINE_SZ;
		}

		tlm::tlm_generic_payload& GetGP() { return m_gp; }

		int GetPortID() { return m_port_id; };

		sc_event& DoneEvent() { return m_done; }

		tlm::tlm_response_status GetTLMResponse()
		{
			return m_gp.get_response_status();
		}

		void SetTLMResponse(tlm::tlm_response_status status)
		{
			m_gp.set_response_status(status);
		}

		bool Done()
		{
			tlm::tlm_response_status status = GetTLMResponse();

			return status != tlm::TLM_INCOMPLETE_RESPONSE;
		}

		void SegmentDone() { m_n_segments--; }

		unsigned int GetNumSegments() { return m_n_segments; }

		bool AllSegmentsReceived() { return m_n_segments == 0; }

		bool IsRead()
		{
			return m_gp.is_read() || HasSingleRdDataTransfer();
		}

		bool IsWrite()
		{
			return m_gp.is_write();
		}

		bool IsSnoopingTransaction()
		{
			genattr_extension *genattr;

			m_gp.get_extension(genattr);
			if (genattr) {
				uint8_t domain = genattr->get_domain();

				if (IsRead()) {
					switch (genattr->get_snoop()) {
					case AR::ReadOnce:
					case AR::ReadClean:
					case AR::ReadNotSharedDirty:
					case AR::ReadShared:
					case AR::ReadUnique:
					case AR::CleanUnique:
					case AR::MakeUnique:
					//
					// Treat all dvm as snooping
					//
					case AR::DVMComplete:
					case AR::DVMMessage:
						if (domain == Domain::Inner ||
							domain == Domain::Outer) {
							return true;
						}
						break;
					case AR::CleanShared:
					case AR::CleanInvalid:
					case AR::MakeInvalid:
						if (domain == Domain::NonSharable ||
							domain == Domain::Inner ||
							domain == Domain::Outer) {
							return true;
						}
						break;
					default:
						break;
					}
				} else if (IsWrite()) {
					switch (genattr->get_snoop()) {
					case AW::WriteUnique:
					case AW::WriteLineUnique:
						if (domain == Domain::Inner ||
							domain == Domain::Outer) {
							return true;
						}
						break;
					default:
						break;
					}
				}
			}

			return false;
		}

		bool IsExclusive()
		{
			genattr_extension *genattr;

			m_gp.get_extension(genattr);
			if (genattr) {
				return genattr->get_exclusive();
			}
			return false;
		}

		uint64_t GetAddress() { return m_gp.get_address(); }
		unsigned int GetDataLen() { return m_gp.get_data_length(); }

		bool InAddressRange(uint64_t addr)
		{
			uint64_t start_addr = m_gp.get_address();
			uint64_t end_addr = m_gp.get_address() + m_gp.get_data_length();

			if (addr >= start_addr && addr < end_addr) {
				return true;
			}

			return false;
		}

		bool IsReadOnce() { return m_is_read_once; }
		bool IsWriteUnique() { return m_is_write_unique; }
		bool IsWriteLineUnique() { return m_is_write_line_unique; }

		bool IsACELite() { return m_is_acelite; }

		void SetExtension(iconnect_event *ie_ext)
		{
			m_gp.set_extension(ie_ext);
		}

		void set_exokay()
		{
			genattr_extension *genattr;

			m_gp.get_extension(genattr);
			if (genattr) {
				genattr->set_exclusive_handled(true);
			}
		}

	private:

		bool is_write_unique(tlm::tlm_generic_payload& gp)
		{
			if (gp.is_write()) {
				genattr_extension *genattr;

				gp.get_extension(genattr);

				if (genattr) {
					uint8_t domain = genattr->get_domain();
					uint8_t snoop = genattr->get_snoop();

					return ace_helpers::IsWriteUnique(domain, snoop);
				}
			}

			return false;
		}

		bool is_write_line_unique(tlm::tlm_generic_payload& gp)
		{
			if (gp.is_write()) {
				genattr_extension *genattr;

				gp.get_extension(genattr);

				if (genattr) {
					uint8_t domain = genattr->get_domain();
					uint8_t snoop = genattr->get_snoop();

					return ace_helpers::IsWriteLineUnique(domain, snoop);
				}
			}

			return false;
		}

		bool is_read_once(tlm::tlm_generic_payload& gp)
		{
			if (gp.is_read()) {
				genattr_extension *genattr;

				gp.get_extension(genattr);

				if (genattr) {
					uint8_t domain = genattr->get_domain();

					if ((domain == Domain::Inner ||
						domain == Domain::Outer) &&
						genattr->get_snoop() == AR::ReadOnce) {
						return true;
					}
				}
			}

			return false;
		}

		tlm::tlm_generic_payload& m_gp;
		int m_port_id;
		sc_event m_done;
		bool m_is_read_once;
		bool m_is_write_unique;
		bool m_is_write_line_unique;
		unsigned int m_n_segments;
		bool m_is_acelite;
	};

	class SnoopTransaction
	{
	public:
		SnoopTransaction(Transaction *tr,
					uint64_t addr,
					int num_masters) :
			m_tr(tr),
			m_num_ports_done(0),
			m_num_masters_to_snoop(num_masters),
			m_exec_ds_gp(tr->IsReadOnce())
		{
			genattr_extension snoop_genattr;
			int i;

			assert(m_tr->IsRead() || m_tr->IsWrite());

			init_snoop_genattr(snoop_genattr);

			for (i = 0; i < NUM_ACE_MASTERS; i++) {
				init_snoop_gp(m_snoop_gp[i],
						addr,
						snoop_genattr,
						i);
			}

			init_ds_gp(addr);
		}

		tlm::tlm_generic_payload& GetGP(int port_id)
		{
			assert(port_id < NUM_ACE_MASTERS);

			return m_snoop_gp[port_id];
		}

		void PortDone(int port_id)
		{
			tlm::tlm_generic_payload& snoop_gp = get_snoop_gp(port_id);
			tlm::tlm_generic_payload& gp = m_tr->GetGP();
			genattr_extension *snoop_genattr;
			genattr_extension *genattr;

			snoop_gp.get_extension(snoop_genattr);
			gp.get_extension(genattr);

			if (snoop_genattr && genattr) {
				if (snoop_genattr->get_shared()) {
					genattr->set_shared();
				}

				if (snoop_genattr->get_datatransfer()) {

					//
					// Only read transactions copy data
					//
					if (is_read_snoop(snoop_genattr)) {
						copy_data(snoop_gp, gp);
					}

					//
					// Data doesn't need to be fetch from
					// downstream anymore if it is a
					// ReadOnce.
					//
					if (m_tr->IsReadOnce()) {
						m_exec_ds_gp = false;
					}

					if (m_tr->AllowPassDirty()) {
						if (snoop_genattr->get_dirty()) {
							genattr->set_dirty();
						}
					} else if (snoop_genattr->get_dirty()) {
						//
						// Write dirty data downstream
						// so we return clean data to
						// the master
						//
						copy_data(snoop_gp, m_ds_gp);
						m_exec_ds_gp = true;
					}
				}

				update_trans_response(snoop_genattr);
			}

			m_num_ports_done++;
		}

		void ds_gp_done()
		{
			tlm::tlm_generic_payload& gp = m_tr->GetGP();

			copy_data(m_ds_gp, gp);
		}

		bool SnoopDone()
		{
			return m_num_ports_done == m_num_masters_to_snoop;
		}

		Transaction *GetTransaction() { return m_tr; }

		bool exec_ds_gp()
		{
			return m_exec_ds_gp;
		}

		tlm::tlm_generic_payload& get_ds_gp() { return m_ds_gp; }

		bool got_error_response()
		{
			int i;

			for (i = 0; i < NUM_ACE_MASTERS; i++) {
				if (m_snoop_gp[i].get_response_status() ==
					tlm::TLM_GENERIC_ERROR_RESPONSE) {
					return true;
				}
			}

			if (m_ds_gp.get_response_status() ==
				tlm::TLM_GENERIC_ERROR_RESPONSE) {
				return true;
			}

			return false;
		}

		uint64_t GetSnoopAddress()
		{
			return m_snoop_gp[0].get_address();
		}

	private:
		void update_trans_response(genattr_extension *snoop_genattr)
		{
			if (snoop_genattr->get_error_bit()) {
				m_tr->SetTLMResponse(tlm::TLM_GENERIC_ERROR_RESPONSE);
				return;
			} else if (m_tr->GetTLMResponse() !=
					tlm::TLM_GENERIC_ERROR_RESPONSE) {
				//
				// Only update as ok below if the response is
				// not already an error
				//

				switch (snoop_genattr->get_snoop()) {
				case AC::ReadOnce:
					// Don't update response here
					break;
				case AC::ReadClean:
				case AC::ReadNotSharedDirty:
				case AC::ReadShared:
				case AC::ReadUnique:
					if (snoop_genattr->get_datatransfer()) {
						m_tr->SetTLMResponse(tlm::TLM_OK_RESPONSE);
					}
					break;
				case AC::CleanInvalid:

					if (m_tr->IsWriteUnique()) {
						// Don't update response here
						break;
					}

				/* Fall through */
				case AC::MakeInvalid:
					// WriteLineUnique needs to go downstream
					if (!m_tr->IsWriteLineUnique()) {
						m_tr->SetTLMResponse(tlm::TLM_OK_RESPONSE);
					}
					break;
				case AC::CleanShared:
					m_tr->SetTLMResponse(tlm::TLM_OK_RESPONSE);
					break;
				case AC::DVMMessage:
				case AC::DVMComplete:
					m_tr->SetTLMResponse(tlm::TLM_OK_RESPONSE);
					break;
				default:
					m_tr->SetTLMResponse(tlm::TLM_GENERIC_ERROR_RESPONSE);
					break;
				}
			}
		}

		bool is_read_snoop(genattr_extension *snoop_genattr)
		{
			switch (snoop_genattr->get_snoop()) {
			case AC::ReadOnce:
			case AC::ReadClean:
			case AC::ReadNotSharedDirty:
			case AC::ReadShared:
			case AC::ReadUnique:
				return true;
				break;
			default:
				break;
			}

			return false;
		}

		bool is_first_segment(uint64_t seg_start_addr,
					unsigned int seg_len,
					uint64_t addr)
		{
			uint64_t seg_end_addr = seg_start_addr + seg_len;

			return addr >= seg_start_addr && addr < seg_end_addr;
		}

		void copy_data(tlm::tlm_generic_payload& snoop_gp,
				tlm::tlm_generic_payload& gp)
		{
			uint64_t snoop_addr = snoop_gp.get_address();
			unsigned char *src_d = snoop_gp.get_data_ptr();
			unsigned int len = snoop_gp.get_data_length();
			uint64_t snoop_end_addr = snoop_addr + len;

			uint64_t gp_addr = gp.get_address();
			unsigned int dst_len = gp.get_data_length();
			uint64_t gp_end_addr = gp_addr + dst_len;
			unsigned char *dst_d = gp.get_data_ptr();

			assert(src_d && dst_d);

			if (is_first_segment(snoop_addr, len, gp_addr)) {
				//
				// This is the first cacheline segment in a
				// ReadOnce, adjust start position if needed.
				//
				unsigned int offset = gp_addr - snoop_addr;

				len -= offset;
				src_d += offset;
			} else {
				//
				// All other segments need to offset dst_d so
				// the cacheline is written to the correct
				// position.
				//
				unsigned int offset = snoop_addr-gp_addr;

				dst_d += offset;
			}

			//
			// Check if it is the last cacheline segment of a
			// ReadOnce tx and trim len if needed.
			//
			if (snoop_end_addr > gp_end_addr) {
				unsigned int trim = snoop_end_addr - gp_end_addr;

				len -= trim;
			}

			assert(len <= CACHELINE_SZ);

			if (src_d && dst_d) {
				memcpy(dst_d, src_d, len);
			}
		}

		inline
		tlm::tlm_generic_payload& get_snoop_gp(int port_id)
		{
			assert(port_id < NUM_ACE_MASTERS);
			return m_snoop_gp[port_id];
		}

		void init_snoop_genattr(genattr_extension& snoop_genattr)
		{
			genattr_extension *genattr;
			tlm::tlm_generic_payload& gp = m_tr->GetGP();

			gp.get_extension(genattr);

			// What do we do if genattr == NULL...
			if (genattr) {
				snoop_genattr.set_secure(genattr->get_secure());

				if (m_tr->IsRead()) {
					switch (genattr->get_snoop()) {
					case AR::ReadOnce:
						snoop_genattr.set_snoop(AC::ReadOnce);
						break;
					case AR::ReadClean:
						snoop_genattr.set_snoop(AC::ReadClean);
						break;
					case AR::ReadNotSharedDirty:
						snoop_genattr.set_snoop(AC::ReadNotSharedDirty);
						break;
					case AR::ReadShared:
						snoop_genattr.set_snoop(AC::ReadShared);
						break;
					case AR::ReadUnique:
						snoop_genattr.set_snoop(AC::ReadUnique);
						break;
					case AR::CleanShared:
						snoop_genattr.set_snoop(AC::CleanShared);
						break;
					case AR::CleanUnique:
					case AR::CleanInvalid:
						snoop_genattr.set_snoop(AC::CleanInvalid);
						break;
					case AR::MakeUnique:
					case AR::MakeInvalid:
						snoop_genattr.set_snoop(AC::MakeInvalid);
						break;
					case AR::DVMMessage:
						snoop_genattr.set_snoop(AC::DVMMessage);
						break;
					case AR::DVMComplete:
						snoop_genattr.set_snoop(AC::DVMComplete);
						break;
					default:
						// Shouldn't get here...
						break;
					}
				} else if (m_tr->IsWrite()) {
					switch (genattr->get_snoop()) {
					case AW::WriteUnique:
						snoop_genattr.set_snoop(AC::CleanInvalid);
						break;
					case AW::WriteLineUnique:
						snoop_genattr.set_snoop(AC::MakeInvalid);
						break;
					default:
						// Shouldn't get here...
						break;
					}
				}
			}
		}

		void init_snoop_gp(tlm::tlm_generic_payload& snoop_gp,
					uint64_t addr,
					genattr_extension& snoop_genattr,
					int i)
		{
			genattr_extension *genattr = new genattr_extension();
			unsigned char *data = &m_snoop_mem[i*CACHELINE_SZ];

			genattr->copy_from(snoop_genattr);

			snoop_gp.set_command(tlm::TLM_READ_COMMAND);
			snoop_gp.set_address(addr);

			snoop_gp.set_data_ptr(data);
			snoop_gp.set_data_length(CACHELINE_SZ);

			snoop_gp.set_byte_enable_ptr(NULL);
			snoop_gp.set_byte_enable_length(0);

			snoop_gp.set_streaming_width(CACHELINE_SZ);

			snoop_gp.set_dmi_allowed(false);

			snoop_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

			snoop_gp.set_extension(genattr);
		}

		void init_ds_gp(uint64_t addr)
		{
			tlm::tlm_generic_payload& gp = m_tr->GetGP();
			unsigned char *data = &m_ds_mem[0];
			genattr_extension *genattr = new genattr_extension();
			genattr_extension *genattr_org;

			if (m_tr->IsReadOnce()) {
				m_ds_gp.set_command(tlm::TLM_READ_COMMAND);

				gp.get_extension(genattr_org);
				if (genattr_org) {
					genattr->copy_from(*genattr_org);
				}

			} else {
				m_ds_gp.set_command(tlm::TLM_WRITE_COMMAND);

				//
				// Writethrough no allocate ([1], Section 7.1)
				//
				genattr->set_bufferable(false);
				genattr->set_modifiable(true);
				genattr->set_read_allocate(true);
				genattr->set_write_allocate(false);
			}

			m_ds_gp.set_address(addr);

			m_ds_gp.set_data_ptr(data);
			m_ds_gp.set_data_length(CACHELINE_SZ);

			m_ds_gp.set_byte_enable_ptr(NULL);
			m_ds_gp.set_byte_enable_length(0);

			m_ds_gp.set_streaming_width(CACHELINE_SZ);

			m_ds_gp.set_dmi_allowed(false);

			m_ds_gp.set_extension(genattr);

			m_ds_gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
		}

		Transaction *m_tr;
		int m_num_ports_done;
		int m_num_masters_to_snoop;

		tlm::tlm_generic_payload m_snoop_gp[NUM_ACE_MASTERS];
		uint8_t m_snoop_mem[NUM_ACE_MASTERS * CACHELINE_SZ];

		tlm::tlm_generic_payload m_ds_gp;
		uint8_t m_ds_mem[CACHELINE_SZ];
		bool m_exec_ds_gp;
	};

	class ISnoopEngine
	{
	public:
		ISnoopEngine() {}

		virtual ~ISnoopEngine() {}

		virtual void process(Transaction *tr) = 0;
		virtual void snoop_done(SnoopTransaction *snoop_tr) = 0;
	};

	class DownstreamPort :
		public sc_core::sc_module
	{
	public:
		tlm_utils::simple_initiator_socket<DownstreamPort> init_socket;

		SC_HAS_PROCESS(DownstreamPort);

		DownstreamPort(sc_core::sc_module_name name) :
			sc_core::sc_module(name),
			init_socket("init_socket")
		{
			SC_THREAD(downstream_port_thread);
		}

		void process(Transaction *tr)
		{
			m_downstream_fifo.write(tr);
		}

		template<typename T>
		void connect_slave(T& slave)
		{
			init_socket(slave.socket);
		}
	private:
		void downstream_port_thread()
		{
			while (true) {
				sc_time delay(SC_ZERO_TIME);
				Transaction *tr = m_downstream_fifo.read();

				init_socket->b_transport(tr->GetGP(), delay);

				wait(delay);

				tr->DoneEvent().notify();
			}
		}

		sc_fifo<Transaction*> m_downstream_fifo;
	};

	class OverlappingTxOrderer :
		public sc_core::sc_module
	{
	public:
		SC_HAS_PROCESS(OverlappingTxOrderer);

		OverlappingTxOrderer(sc_core::sc_module_name name,
				ISnoopEngine *snoop_engine,
				DownstreamPort& ds_port) :
			sc_core::sc_module(name),
			m_snoop_engine(snoop_engine),
			m_ds_port(ds_port)
		{}

		void process(Transaction& trans)
		{
			if (trans.IsSnoopingTransaction()) {
				if (is_overlapping(trans) && !trans.IsDVM()) {
					//
					// This cacheline is already being processed,
					// wait for that tx to complete.
					//
					to_overlapping(&trans);
				} else {
					//
					// Start processing snoop transaction
					//
					to_snoop_engine(&trans);
					m_ongoing_tx.push_back(&trans);
				}
			} else {
				//
				// No snooping transaction, forward it to the
				// downstream port.
				//
				to_downstream_port(&trans);
				m_ongoing_tx.push_back(&trans);

			}

			wait(trans.DoneEvent());

			m_ongoing_tx.remove(&trans);

			restart_overlapping(trans);
		}

	private:
		inline void to_snoop_engine(Transaction *trans)
		{
			m_snoop_engine->process(trans);
		}

		inline void to_downstream_port(Transaction *trans)
		{
			m_ds_port.process(trans);
		}

		inline void to_overlapping(Transaction *trans)
		{
			m_overlapping_tx.push_back(trans);
		}

		bool is_overlapping(Transaction& tr)
		{
			uint64_t addr = tr.GetAddress();
			uint64_t last_addr = addr + tr.GetDataLen()-1;

			for (typename std::list<Transaction*>::iterator it = m_ongoing_tx.begin();
				it != m_ongoing_tx.end(); it++) {
				Transaction *ongoing_tr = (*it);

				if (ongoing_tr->InAddressRange(addr) ||
					ongoing_tr->InAddressRange(last_addr) ||
					tr.InAddressRange(ongoing_tr->GetAddress()) ) {
					return true;
				}
			}

			return false;
		}

		void restart_overlapping(Transaction& tr)
		{
			uint64_t addr = tr.GetAddress();
			uint64_t last_addr = addr + tr.GetDataLen()-1;
			typename std::list<Transaction*>::iterator it = m_overlapping_tx.begin();

			//
			// Check if any overlapping tx (a tx accessing the same
			// cacheline) needs to be restarted.
			//
			for (; it != m_overlapping_tx.end();) {
				Transaction *overlapping_tr = (*it);
				bool restart_tr = false;

				if (overlapping_tr->InAddressRange(addr) ||
					overlapping_tr->InAddressRange(last_addr) ||
					tr.InAddressRange(overlapping_tr->GetAddress()) ) {

					if (!is_overlapping(*overlapping_tr)) {
						//
						// Found an overlapping tr stalled by
						// the transaction that is now done.
						// Restart it!
						//
						restart_tr = true;
					}
				}

				if (restart_tr) {
					//
					// Move overlapping tr to the
					// ongoing list
					//
					it = m_overlapping_tx.erase(it);
					m_ongoing_tx.push_back(overlapping_tr);

					//
					// Start processing it.
					//
					if (overlapping_tr->IsSnoopingTransaction()) {
						to_snoop_engine(overlapping_tr);
					} else {
						to_downstream_port(overlapping_tr);
					}
				} else {
					it++;
				}
			}
		}

		ISnoopEngine *m_snoop_engine;
		DownstreamPort& m_ds_port;

		std::list<Transaction*> m_ongoing_tx;
		std::list<Transaction*> m_overlapping_tx;
	};

	class ACELitePort_S :
		public sc_core::sc_module
	{
	public:
		tlm_utils::simple_target_socket<ACELitePort_S> target_socket;

		SC_HAS_PROCESS(ACELitePort_S);

		ACELitePort_S(sc_core::sc_module_name name,
			OverlappingTxOrderer& overlapping_orderer,
			int port_id) :
			sc_core::sc_module(name),
			target_socket("target_socket"),
			m_overlapping_orderer(overlapping_orderer),
			m_port_id(port_id)
		{
			target_socket.register_b_transport(this, &ACELitePort_S::b_transport);
		}

		int GetPortId() { return m_port_id; }

		template<typename T>
		void connect_master(T& m_bridge)
		{
			m_bridge.socket.bind(target_socket);
		}

	private:
		virtual void b_transport(tlm::tlm_generic_payload& gp, sc_time& delay)
		{
			Transaction trans(gp, m_port_id);

			if (trans.IsEvict() || trans.IsBarrier()) {
				gp.set_response_status(tlm::TLM_OK_RESPONSE);
				return;
			}

			//
			// Push the tx to the next step which is to check if
			// there is an ongoing tx with overlapping addresses
			// this new tx needs to wait for.
			//
			m_overlapping_orderer.process(trans);
		}

		OverlappingTxOrderer& m_overlapping_orderer;
		int m_port_id;
	};

	class ACEPort_S :
		public sc_core::sc_module
	{
	public:
		tlm_utils::simple_target_socket<ACEPort_S> target_socket;
		tlm_utils::simple_initiator_socket<ACEPort_S> snoop_init_socket;

		SC_HAS_PROCESS(ACEPort_S);

		ACEPort_S(sc_core::sc_module_name name,
			OverlappingTxOrderer& overlapping_orderer,
			ISnoopEngine *snoop_engine,
			int port_id) :
			sc_core::sc_module(name),
			target_socket("target_socket"),
			snoop_init_socket("snoop_init_socket"),
			m_overlapping_orderer(overlapping_orderer),
			m_snoop_engine(snoop_engine),
			m_port_id(port_id),
			m_forward_dvm(false)
		{
			target_socket.register_b_transport(this, &ACEPort_S::b_transport);
		}

		void snoop_master(SnoopTransaction* snoop_tr)
		{
			sc_spawn(sc_bind(&ACEPort_S::snoop_master_thread,
					this, snoop_tr));
		}

		//
		// Handles DVM complete transactions on the snoop channels
		//
		void snoop_master(tlm::tlm_generic_payload& gp)
		{
			sc_time delay(SC_ZERO_TIME);

			snoop_init_socket->b_transport(gp, delay);

			wait(delay);
		}

		int GetPortId() { return m_port_id; }

		template<typename T>
		void connect_master(T& m_bridge)
		{
			m_bridge.socket.bind(target_socket);
			snoop_init_socket.bind(m_bridge.snoop_target_socket);
		}

		bool GetForwardDVM() { return m_forward_dvm; }
		void SetForwardDVM(bool process_dvm) { m_forward_dvm = process_dvm; }

	private:
		inline void to_snoop_done(SnoopTransaction *trans)
		{
			m_snoop_engine->snoop_done(trans);
		}

		void snoop_master_thread(SnoopTransaction* snoop_tr)
		{
			sc_time delay(SC_ZERO_TIME);

			snoop_init_socket->b_transport(snoop_tr->GetGP(m_port_id), delay);

			wait(delay);

			snoop_tr->PortDone(m_port_id);

			if (snoop_tr->SnoopDone()) {
				to_snoop_done(snoop_tr);
			}
		}

		virtual void b_transport(tlm::tlm_generic_payload& gp, sc_time& delay)
		{
			Transaction trans(gp, m_port_id);

			//
			// Act as if it is a domain boundary for barrier
			// transactions (section 8.3 [1]). The TLM initiator
			// must assert that there are no pre barrier
			// transactions ongoing.
			//
			if (trans.IsEvict() || trans.IsBarrier()) {
				gp.set_response_status(tlm::TLM_OK_RESPONSE);
				return;
			}

			//
			// Push the tx to the next step which is to check if
			// there is an ongoing tx with overlapping addresses
			// this new tx needs to wait for.
			//
			m_overlapping_orderer.process(trans);
		}


		OverlappingTxOrderer& m_overlapping_orderer;
		ISnoopEngine *m_snoop_engine;
		int m_port_id;

		bool m_forward_dvm;
	};

	class PortDVMCompleteTracker
	{
	public:
		PortDVMCompleteTracker() :
			m_running(false),
			m_port_id(0)
		{}

		void Reset(int port_id)
		{
			int i;

			// All ports done
			for (i = 0; i < NUM_ACE_MASTERS; i++) {
				m_port_done[i] = true;
			}

			m_running = false;
			m_port_id = port_id;
		}

		void WaitCompleteFor(int id)
		{
			m_port_done[id] = false;
		}

		bool PortDone(int id)
		{
			bool ret = false;

			if (!m_port_done[id]) {
				//
				// Mark port done and return true
				//
				m_port_done[id] = true;
				ret = true;;
			}

			return ret;
		}

		bool Done()
		{
			int i;

			for (i = 0; i < NUM_ACE_MASTERS; i++) {
				if (!m_port_done[i]) {
					return false;
				}
			}

			return true;
		}

		void SetRunning(bool running) { m_running = false; }
		bool GetRunning() { return m_running; }

		tlm::tlm_generic_payload& GetGP() { return m_gp; }

		int GetPortID() { return m_port_id; }

	private:
		tlm::tlm_generic_payload m_gp;
		bool m_port_done[NUM_ACE_MASTERS];
		bool m_running;
		int m_port_id;
	};

	class DVMCompleteHandler
	{
	public:
		DVMCompleteHandler(ACEPort_S **s_ace_port) :
			m_s_ace_port(s_ace_port)
		{
			int i;

			for (i = 0; i < NUM_ACE_MASTERS; i++) {
				m_tracker[i].Reset(i);
				init_gp(m_tracker[i].GetGP());
			}

		}

		void StartCollectingFor(int port_id)
		{
			PortDVMCompleteTracker *tracker = GetTracker(port_id);

			assert(tracker->GetRunning() == false);

			if (!tracker->GetRunning()) {
				int id;

				for (id = 0; id < NUM_ACE_MASTERS; id++) {
					//
					// Wait for completes from other ports
					// if they participate in DVM
					//
					if (m_s_ace_port[id]->GetForwardDVM() &&
						port_id != id) {
						tracker->WaitCompleteFor(id);
					}
				}

				tracker->SetRunning(true);
				m_list.push_back(tracker);
			}
		}

		PortDVMCompleteTracker *GetTracker(int port_id)
		{
			assert(port_id < NUM_ACE_MASTERS);
			return &m_tracker[port_id];
		}

		void ReceivedFrom(int port_id)
		{
			typename std::list<PortDVMCompleteTracker*>::iterator it;

			for (it = m_list.begin(); it != m_list.end(); it++) {
				PortDVMCompleteTracker *tracker = (*it);

				//
				// break if port_id was marked, else try next
				// tracker
				//
				if (tracker->PortDone(port_id)) {
					break;
				}
			}

			assert(it != m_list.end());
		}

		PortDVMCompleteTracker *GetDone()
		{
			typename std::list<PortDVMCompleteTracker*>::iterator it;

			for (it = m_list.begin(); it != m_list.end(); it++) {
				PortDVMCompleteTracker *tracker = (*it);

				if (tracker->Done()) {
					return tracker;
				}
			}

			return NULL;
		}

		void SnoopDone(PortDVMCompleteTracker *tracker)
		{
			m_list.remove(tracker);
			tracker->GetGP().set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
			tracker->SetRunning(false);
		}

	private:
		void init_gp(tlm::tlm_generic_payload& gp)
		{
			genattr_extension *genattr = new genattr_extension();

			gp.set_command(tlm::TLM_READ_COMMAND);
			gp.set_address(0);

			gp.set_data_ptr(&m_dummy_data[0]);
			gp.set_data_length(CACHELINE_SZ);

			gp.set_byte_enable_ptr(NULL);
			gp.set_byte_enable_length(0);

			gp.set_streaming_width(CACHELINE_SZ);

			gp.set_dmi_allowed(false);

			gp.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

			genattr->set_secure(false);
			genattr->set_snoop(AC::DVMComplete);

			gp.set_extension(genattr);
		}

		uint8_t m_dummy_data[CACHELINE_SZ];
		ACEPort_S **m_s_ace_port;
		PortDVMCompleteTracker m_tracker[NUM_ACE_MASTERS];
		std::list<PortDVMCompleteTracker*> m_list;
	};

	class PosMonitor :
		public sc_core::sc_module
	{
	public:
		SC_HAS_PROCESS(PosMonitor);

		PosMonitor(sc_core::sc_module_name name) :
			sc_core::sc_module(name),
			m_lock(false)
		{
			int id;

			for (id = 0; id < NUM_ACE_MASTERS; id++) {
				m_port_set[id] = false;
			}

			SC_THREAD(release_lock_thread);
		}

		void Set(int port_id)
		{
			m_port_set[port_id] = true;
		}
		bool IsSet(int port_id) { return m_port_set[port_id]; }

		void Reset(int port_id)
		{
			int id;

			for (id = 0; id < NUM_ACE_MASTERS; id++) {
				if (port_id != id) {
					m_port_set[id] = false;
				}
			}
		}

		void SetLock(bool val) { m_lock = val; }
		bool IsLocked() { return m_lock; }

		sc_event* GetReleaseEvent() { return &m_release_event; };

		void release_lock_thread()
		{
			while (true) {
				wait(m_release_event);
				m_lock = false;
			}
		}

	private:
		bool m_lock;
		bool m_port_set[NUM_ACE_MASTERS];

		sc_event m_release_event;
	};

	class SnoopEngine :
		public sc_core::sc_module,
		public ISnoopEngine
	{
	public:
		SC_HAS_PROCESS(SnoopEngine);

		SnoopEngine(sc_core::sc_module_name name,
				ACEPort_S **s_ace_port,
				DownstreamPort& ds_port) :
			sc_core::sc_module(name),
			m_exmon("pos_monitor"),
			m_s_ace_port(s_ace_port),
			m_dvm_completes(s_ace_port),
			m_ds_port(ds_port)
		{
			SC_THREAD(snoop_engine_thread);
			SC_THREAD(snoop_done_thread);
		}

		virtual void process(Transaction *tr)
		{
			m_snoop_engine_fifo.write(tr);
		}

		virtual void snoop_done(SnoopTransaction *snoop_tr)
		{
			m_snoop_done_fifo.write(snoop_tr);
		}
	private:
		//
		// Entry step into the snoop engine, snoop transactions come in
		// order in the fifo.
		//
		void snoop_engine_thread()
		{
			while (true) {
				Transaction *tr = m_snoop_engine_fifo.read();
				uint64_t addr = tr->GetAddress() & ~(CACHELINE_SZ-1);
				unsigned int i;

				if (tr->IsDVMSync()) {
					//
					// Mark that port will be waiting for
					// DVM completes.
					//
					m_dvm_completes.StartCollectingFor(tr->GetPortID());

				} else if (tr->IsDVMComplete()) {
					handle_dvm_complete(tr);

					//
					// Complete transactions are done here
					//
					tr->SetTLMResponse(tlm::TLM_OK_RESPONSE);
					tr->DoneEvent().notify();
					continue;
				}

				if (tr->IsExclusive()) {
					//
					// Failed exlusive CleanUnique ends here
					//
					if (!handle_exclusive(tr)) {
						tr->SetTLMResponse(tlm::TLM_OK_RESPONSE);
						tr->DoneEvent().notify();
						continue;
					}
				}

				//
				// Generate and process snoop transactions
				//
				for (i = 0; i < tr->GetNumSegments(); i++, addr += CACHELINE_SZ) {
					int num_masters;

					if (tr->IsACELite()) {
						//
						// All ACE master
						//
						num_masters = NUM_ACE_MASTERS;
					} else if (tr->IsDVM()) {
						//
						// All DVM masters except initiating master
						//
						num_masters = get_num_dvm_masters() - 1;
					} else {
						//
						// All ACE masters except initiating master
						//
						num_masters = NUM_ACE_MASTERS-1;
					}

					process_snoop(new SnoopTransaction(
								tr,
								addr,
								num_masters));
				}
			}
		}

		void process_snoop(SnoopTransaction *snoop_tr)
		{
			if (snoop_tr->SnoopDone()) {
				//
				// Special case when there is only one
				// master in the system an no snooping
				// is needed.
				//
				m_snoop_done_fifo.write(snoop_tr);
			} else {
				//
				// Snoop all masters except the initiating
				// master.
				//
				Transaction *tr = snoop_tr->GetTransaction();

				for (int i = 0; i < NUM_ACE_MASTERS; i++) {

					if (tr->IsDVM() && !m_s_ace_port[i]->GetForwardDVM()) {
						continue;
					}

					if (m_s_ace_port[i]->GetPortId() != tr->GetPortID()) {
						m_s_ace_port[i]->snoop_master(snoop_tr);
					}
				}
			}
		}

		void exec_dvm_complete(PortDVMCompleteTracker *tracker)
		{
			int id = tracker->GetPortID();

			m_s_ace_port[id]->snoop_master(tracker->GetGP());

			m_dvm_completes.SnoopDone(tracker);
		}

		void handle_dvm_complete(Transaction *tr)
		{
			PortDVMCompleteTracker *done_tracker;

			//
			// Mark that port has issued a complete.
			//
			m_dvm_completes.ReceivedFrom(tr->GetPortID());

			//
			// Issue back a complete to an initiaing master if all
			// completes for it's sync have arrived.
			//
			done_tracker = m_dvm_completes.GetDone();
			if (done_tracker) {
				sc_spawn(sc_bind(&SnoopEngine::exec_dvm_complete,
						this, done_tracker));
			}
		}

		bool handle_exclusive(Transaction *tr)
		{
			if (tr->IsCleanUnique()) {
				int port_id = tr->GetPortID();
				iconnect_event *ie_ext;
				bool proceed = m_exmon.IsSet(port_id);

				//
				// Mark port set if monitor is not locked
				//
				if (!m_exmon.IsLocked()) {
					m_exmon.Set(port_id);
				}

				//
				// Don't proceed if the port was not set before
				// this tx the tx
				//
				if (!proceed) {
					tr->SetTLMResponse(tlm::TLM_OK_RESPONSE);
					return false;
				}

				//
				// Reset monitor and lock until a release event
				//
				ie_ext = new iconnect_event(
						m_exmon.GetReleaseEvent());

				// Takes over ownership
				tr->SetExtension(ie_ext);

				m_exmon.Reset(port_id);
				m_exmon.SetLock(true);

				tr->set_exokay();

			} else if (tr->IsReadShared() | tr->IsReadClean() ) {
				//
				// Only mark set if port is not locked
				//
				if (!m_exmon.IsLocked()) {
					m_exmon.Set(tr->GetPortID());
				}

				//
				// Always EXOKAY but clean will fail if address
				// has not been set in the PoS monitor
				//
				tr->set_exokay();
			}

			return true;
		}

		int get_num_dvm_masters()
		{
			int num_dvm_masters = 0;
			int i;

			for (i = 0; i < NUM_ACE_MASTERS; i++) {
				if (m_s_ace_port[i]->GetForwardDVM()) {
					num_dvm_masters++;
				}
			}

			return num_dvm_masters;
		}

		void snoop_done_thread()
		{
			while (true) {
				SnoopTransaction *snoop_tr = m_snoop_done_fifo.read();

				if (snoop_tr->exec_ds_gp()) {
					sc_spawn(sc_bind(&SnoopEngine::exec_snoop_downstream_gp,
							this, snoop_tr));
				} else {
					finalize_snoop_tr(snoop_tr);
				}
			}
		}

		//
		// Clean dirty data or read data for ReadOnce
		//
		// ReadOnce fetches data (a cache line) either by snooping the
		// masters or from downstream with the snoop transaction's
		// ds_gp. tr->GetGP() is only used to store and return the data
		// afterwards.
		//
		// The snoop transaction's ds_gp is also used when writing down
		// dirty data that is not supposed be returned to the master,
		// for example when processing a WriteUnique.
		//
		void exec_snoop_downstream_gp(SnoopTransaction *snoop_tr)
		{
			Transaction *tr = snoop_tr->GetTransaction();
			Transaction ds_tr(snoop_tr->get_ds_gp());

			m_ds_port.process(&ds_tr);

			wait(ds_tr.DoneEvent());

			if (tr->IsReadOnce()) {
				snoop_tr->ds_gp_done();
			}

			finalize_snoop_tr(snoop_tr);
		}

		void finalize_snoop_tr(SnoopTransaction *snoop_tr)
		{
			Transaction *tr = snoop_tr->GetTransaction();
			bool finalize_tr = true;

			if (tr->IsReadOnce() || tr->IsWriteUnique()) {
				//
				// The snoop transactions is now done meaning that
				// WriteUnique has clean + invalidated a cacheline
				// and ReadOnce has got a cacheline and copied
				// it in into the response.
				//
				tr->SegmentDone();
				if (snoop_tr->got_error_response()) {
					tr->SetTLMResponse(tlm::TLM_GENERIC_ERROR_RESPONSE);
				}

				if (!tr->AllSegmentsReceived()) {
					//
					// Don't finalize the tr if it is still waiting
					// for segments.
					//
					finalize_tr = false;
				} else {
					//
					// All cachelines have been processed
					// for WriteUnique and ReadOnce.
					//
					// ReadOnce is now done so set the
					// response (WriteUnique response will be
					// set downstream).
					//
					if (tr->IsReadOnce() &&
						tr->GetTLMResponse() ==
						tlm::TLM_INCOMPLETE_RESPONSE) {
						tr->SetTLMResponse(tlm::TLM_OK_RESPONSE);
					}
				}

			}

			if (finalize_tr) {
				if (tr->Done()) {
					tr->DoneEvent().notify();
				} else {
					m_ds_port.process(tr);
				}
			}

			delete snoop_tr;
		}

		PosMonitor m_exmon;

		ACEPort_S **m_s_ace_port;
		DVMCompleteHandler m_dvm_completes;
		sc_fifo<Transaction*> m_snoop_engine_fifo;
		sc_fifo<SnoopTransaction*> m_snoop_done_fifo;
		DownstreamPort& m_ds_port;
	};

	ACEPort_S *s_ace_port[NUM_ACE_MASTERS];
	ACELitePort_S *s_acelite_port[NUM_ACELITE_MASTERS];
	DownstreamPort ds_port;

	SC_HAS_PROCESS(iconnect_ace);

	iconnect_ace(sc_core::sc_module_name name) :
		sc_core::sc_module(name),
		ds_port("ds_port"),
		m_snoop_engine("snoop_engine",
				s_ace_port,
				ds_port),
		m_overlapping_orderer("overlapping_orderer",
					&m_snoop_engine,
					ds_port)
	{
		int port_id;

		for (port_id = 0; port_id < NUM_ACE_MASTERS; port_id++) {
			std::ostringstream name;

			name << "s_ace_port" << port_id;

			s_ace_port[port_id] = new ACEPort_S(name.str().c_str(),
						m_overlapping_orderer,
						&m_snoop_engine,
						port_id);
		}

		for (port_id = 0; port_id < NUM_ACELITE_MASTERS; port_id++) {
			std::ostringstream name;
			int id = Transaction::ACELite_ID_offset + port_id;

			name << "s_acelite_port" << port_id;

			s_acelite_port[port_id] = new ACELitePort_S(name.str().c_str(),
						m_overlapping_orderer,
						id);
		}
	}

	~iconnect_ace()
	{
		int i;

		for (i = 0; i < NUM_ACE_MASTERS; i++) {
			delete s_ace_port[i];
		}

		for (i = 0; i < NUM_ACELITE_MASTERS; i++) {
			delete s_acelite_port[i];
		}
	}

private:
	SnoopEngine m_snoop_engine;
	OverlappingTxOrderer m_overlapping_orderer;
};

#endif /* __ICONNECT_ACE_H__ */
