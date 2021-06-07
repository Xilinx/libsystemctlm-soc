/*
 * TLM-2.0 to ATG bridge.
 *
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

#ifndef TLM2ATG_HW_BRIDGE_H__
#define TLM2ATG_HW_BRIDGE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <vector>
#include <list>
#include <sstream>

#include "tlm-bridges/amba.h"
#include "tlm-bridges/amba-ace.h"
#include "tlm-modules/tlm-aligner.h"
#include "tlm-extensions/genattr.h"

class atg_bridge:
	public sc_core::sc_module
{
public:

	enum {

		MASTER_CTRL = 0x0,

		SLAVE_CTRL = 0x4,
		ERROR_STATUS = 0x8,
		ERROR_ENABLE = 0xC,

		MASTER_ERROR_INTR_ENABLE = 0x10,
		CONFIG_STATUS = 0x14,

		SLAVE_ERROR = 0xB4,

		RD_CMD_RAM = 0x8000,
		WR_CMD_RAM = 0x9000,

		MASTER_RAM = 0xC000,

		MSTEN = 1 << 20, // Master enable

		MSTDONE = 1 << 31, // Master done

		CMD_VALID = 1 << 31,

		DATA_BUS_BYTES = 128/8,
	};


	//
	// TLM Traffic in
	//
	tlm_utils::simple_target_socket<atg_bridge> tgt_socket;

	//
	// Towards vfio bridge in rtl that then routes to the ATG
	//
	tlm_utils::simple_initiator_socket<atg_bridge> bridge_socket;

	SC_HAS_PROCESS(atg_bridge);

	atg_bridge(sc_core::sc_module_name name,
			uint32_t base_addr) :
		sc_module(name),

		tgt_socket("target_socket"),

		bridge_socket("bridge_socket"),

		m_base_addr(base_addr)
	{
		tgt_socket.register_b_transport(this, &atg_bridge::b_transport);

		SC_THREAD(work_thread);
	}

private:
	class Transaction
	{
	public:
		Transaction(tlm::tlm_generic_payload& gp) :
			m_gp(gp),
			m_burstType(AXI_BURST_INCR),
			m_beat(1),
			m_numBeats(0)
		{
			genattr_extension *genattr;

			m_gp.get_extension(genattr);
			if (genattr) {
				m_genattr.copy_from(*genattr);
			}

			SetupBurstType();
			SetupNumBeats();
		}

		void SetupBurstType()
		{
			unsigned int streaming_width = m_gp.get_streaming_width();
			unsigned int datalen = m_gp.get_data_length();

			if (streaming_width == datalen &&
				m_genattr.get_wrap()) {
				m_burstType = AXI_BURST_WRAP;
			} else if (streaming_width >= datalen) {
				m_burstType = AXI_BURST_INCR;
			} else if (streaming_width == DATA_BUS_BYTES) {
				m_burstType = AXI_BURST_FIXED;
			} else if (streaming_width < DATA_BUS_BYTES) {
				//
				// Specify this with burst_width if streaming
				// width is less than the data bus width
				//
				m_burstType = AXI_BURST_FIXED;
				if (streaming_width > 1) {
					streaming_width &= (~0x1);
				}

				m_genattr.set_burst_width(streaming_width);
			} else {
				SC_REPORT_ERROR("atg_bridge",
						"Unsupported burst type");
			}
		}

		void SetupNumBeats()
		{
			uint64_t address = m_gp.get_address();
			unsigned int dataLen = m_gp.get_data_length();
			uint32_t burst_width = GetBurstWidth();
			uint64_t alignedAddress;

			alignedAddress = (address / burst_width) * burst_width;
			dataLen += address - alignedAddress;

			m_numBeats = (dataLen + burst_width - 1) / burst_width;
		}

		uint32_t GetNumBeats() { return m_numBeats; }

		uint32_t GetBurstWidth()
		{
			uint32_t burst_width = m_genattr.get_burst_width();

			if (burst_width == 0) {
				// Default to databus width
				burst_width = DATA_BUS_BYTES;
			}
			return burst_width;
		}

		uint8_t GetBurstType() { return m_burstType; }

		tlm::tlm_generic_payload& GetGP() { return m_gp; }

		uint32_t GetAxID() { return m_genattr.get_transaction_id(); }

		uint64_t GetAddress() { return m_gp.get_address(); }

		uint8_t GetAxProt()
		{
			uint8_t AxProt = 0;

			if (m_genattr.get_non_secure()) {
				AxProt |= AXI_PROT_NS;
			}
			return AxProt;
		}

		uint8_t GetAxCache()
		{
			uint8_t AxCache = 0;

			 AxCache = m_genattr.get_bufferable() |
					(m_genattr.get_modifiable() << 1) |
					(m_genattr.get_read_allocate() << 2) |
					(m_genattr.get_write_allocate() << 3);
			return AxCache;
		}

		uint8_t GetAxQoS()
		{
			uint8_t AxQoS = 0;

			AxQoS = m_genattr.get_qos();
			return AxQoS;
		}

		uint8_t GetAxRegion()
		{
			uint8_t AxRegion = 0;

			AxRegion = m_genattr.get_region();
			return AxRegion;
		}

		unsigned int GetDataLen() { return m_gp.get_data_length(); }
		uint8_t *GetData() { return m_gp.get_data_ptr(); }

		void IncBeat() { m_beat++; }

		bool IsLastBeat() { return m_beat == m_numBeats; }

		bool IsExclusive() { return m_genattr.get_exclusive(); }

		sc_event& DoneEvent() { return m_done; }

		bool IsRead()
		{
			return m_gp.is_read();
		}

		bool IsWrite()
		{
			return m_gp.is_write();
		}

	private:
		tlm::tlm_generic_payload& m_gp;
		genattr_extension m_genattr;
		sc_event m_done;
		uint8_t m_burstType;
		uint32_t m_beat;
		uint32_t m_numBeats;
	};

	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		Transaction tr(trans);

		wait(delay);
		delay = SC_ZERO_TIME;

		// Abort if reset got asserted.
		if (tr.IsRead()) {
			exec_read(&tr);
		} else {
			exec_write(&tr);
		}

		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	void exec_read(Transaction *tr)
	{
		dev_write32(WR_CMD_RAM + 0x4, 0);

		exec_txn(tr, RD_CMD_RAM);

		m_txnFifo.write(tr);

		// Wait until the transaction is done.
		wait(tr->DoneEvent());

		pop_rdata(tr);
	}

	void exec_write(Transaction *tr)
	{
		dev_write32(RD_CMD_RAM + 0x4, 0);

		push_wdata(tr);

		exec_txn(tr, WR_CMD_RAM);

		m_txnFifo.write(tr);

		// Wait until the transaction is done.
		wait(tr->DoneEvent());
	}

	void pop_rdata(Transaction *rt)
	{
		uint8_t *data = rt->GetData();
		unsigned int dataLen = rt->GetDataLen();
		unsigned int data_idx = 0;
		uint32_t master_ram_addr = MASTER_RAM;
		uint32_t rdata;

		for (; data_idx < dataLen;) {
			rdata = dev_read32(master_ram_addr);

			for (unsigned int i = 0; i < 4; i++) {
				unsigned shift = i * 8;

				//
				// Place byte
				//
				data[data_idx++] = (rdata >> shift) & 0xFF;

				if (data_idx >= dataLen) {
					// Done
					break;
				}
			}

			master_ram_addr += 4;
		}
	}

	void push_wdata(Transaction *wt)
	{
		uint8_t *data = wt->GetData();
		unsigned int dataLen = wt->GetDataLen();
		uint32_t master_ram_addr = MASTER_RAM;

		while (dataLen) {
			uint32_t val = 0;

			//
			// Move over 4 bytes (or the ones that are left)
			//
			for (int i = 0; i < 4; i++) {
				unsigned int shift = i * 8;;

				val |= data[0] << shift;

				data++;
				dataLen--;

				if (dataLen == 0) {
					break;
				}
			}

			dev_write32(master_ram_addr, val);
			master_ram_addr += 4;
		}
	}

	void exec_txn(Transaction *tr, uint32_t cmd_ram_base)
	{
		uint32_t axsize = map_size_to_axsize_assert(tr->GetBurstWidth());
		uint32_t axlen = tr->GetNumBeats()-1;

		dev_write32(ERROR_ENABLE, 0xFFFFFFFF);
		dev_write32(ERROR_STATUS, MSTDONE); // Clear

		dev_write32(cmd_ram_base, tr->GetAddress());
		dev_write32(cmd_ram_base + 0x4, ( CMD_VALID |
						axlen << 0 |
						tr->GetBurstType() << 10 |
						axsize << 12 |
						tr->GetAxProt() << 21));

		dev_write32(cmd_ram_base + 0x8, 0x0);
		dev_write32(cmd_ram_base + 0xC, tr->GetAxCache() << 4);

		// Make sure next cmd is not valid (ends there)
		dev_write32(cmd_ram_base + 0x14, 0);

		dev_write32(MASTER_CTRL, MSTEN);
	}

	void work_thread()
	{
		while (true) {
			Transaction *tr = m_txnFifo.read();
			uint32_t r = dev_read32(ERROR_STATUS);

			while (r == 0) {
				sc_time delay(100, SC_US);
				wait(delay);

				r = dev_read32(ERROR_STATUS);
			}

			tr->DoneEvent().notify();
		}
	}

	void dev_access(tlm::tlm_command cmd, uint64_t offset,
			void *buf, unsigned int len)
	{
		unsigned char *buf8 = (unsigned char *) buf;
		tlm::tlm_generic_payload dev_tr;
		sc_time delay = SC_ZERO_TIME;

		offset += m_base_addr;

		dev_tr.set_command(cmd);
		dev_tr.set_address(offset);
		dev_tr.set_data_ptr(buf8);
		dev_tr.set_data_length(len);
		dev_tr.set_streaming_width(len);
		dev_tr.set_dmi_allowed(false);
		dev_tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		bridge_socket->b_transport(dev_tr, delay);
		assert(dev_tr.get_response_status() == tlm::TLM_OK_RESPONSE);
	}

	uint32_t dev_read32(uint64_t offset)
	{
		uint32_t r;
		assert((offset & 3) == 0);
		dev_access(tlm::TLM_READ_COMMAND, offset, &r, sizeof(r));
		return r;
	}

	void dev_write32(uint64_t offset, uint32_t v, bool dummy_read = true)
	{
		uint32_t dummy;
		assert((offset & 3) == 0);
		dev_access(tlm::TLM_WRITE_COMMAND, offset, &v, sizeof(v));

		if (dummy_read) {
			dev_access(tlm::TLM_READ_COMMAND, offset, &dummy, sizeof(dummy));
		}
	}

	sc_fifo<Transaction*> m_txnFifo;
	uint64_t m_base_addr;
};

#endif
