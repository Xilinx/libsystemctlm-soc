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
 */
#ifndef TRAFFICDESC_H_
#define TRAFFICDESC_H_

#include "tlm-extensions/genattr.h"
#include "data-transfer.h"

class TrafficDesc : public ITrafficDesc
{
public:
	TrafficDesc(const DataTransferVec& transfers) :
		m_transfers(transfers),
		m_it(m_transfers.begin())
	{}

	TrafficDesc(DataTransferVec&& transfers) :
		m_transfers(transfers),
		m_it(m_transfers.begin())
	{}

	~TrafficDesc()
	{}

	virtual tlm::tlm_command getCmd()
	{
		tlm::tlm_command cmd = tlm::TLM_IGNORE_COMMAND;

		if ((*m_it).cmd == DataTransfer::WRITE) {
			cmd = tlm::TLM_WRITE_COMMAND;
		} else if ((*m_it).cmd == DataTransfer::READ) {
			cmd = tlm::TLM_READ_COMMAND;
		}

		return cmd;
	}

	virtual uint64_t getAddress() { return (*m_it).addr; }

	virtual unsigned char *getData()
	{
		return const_cast<unsigned char*>((*m_it).data);
	}

	virtual uint32_t getDataLength() { return (*m_it).length; }

	virtual unsigned char *getByteEnable()
	{
		return const_cast<unsigned char*>((*m_it).byte_enable);
	}

	virtual uint32_t getByteEnableLength()
	{
		return (*m_it).byte_enable_length;
	}

	virtual uint32_t getStreamingWidth() { return (*m_it).streaming_width; }

	virtual unsigned char *getExpect()
	{
		return const_cast<unsigned char*>((*m_it).expect);
	}

	virtual void setExtensions(tlm::tlm_generic_payload *gp)
	{
		DataTransfer& t = (*m_it);

		if (t.ext.gen_attr.enabled) {
			genattr_extension *genattr = new genattr_extension();

			genattr->set_master_id(t.ext.gen_attr.master_id);
			genattr->set_secure(t.ext.gen_attr.secure);
			genattr->set_eop(t.ext.gen_attr.eop);
			genattr->set_wrap(t.ext.gen_attr.wrap);
			genattr->set_burst_width(t.ext.gen_attr.burst_width);
			genattr->set_transaction_id(t.ext.gen_attr.transaction_id);
			genattr->set_exclusive(t.ext.gen_attr.exclusive);
			genattr->set_locked(t.ext.gen_attr.locked);
			genattr->set_bufferable(t.ext.gen_attr.bufferable);
			genattr->set_modifiable(t.ext.gen_attr.modifiable);
			genattr->set_read_allocate(t.ext.gen_attr.read_allocate);
			genattr->set_write_allocate(t.ext.gen_attr.write_allocate);
			genattr->set_qos(t.ext.gen_attr.qos);
			genattr->set_region(t.ext.gen_attr.qos);
			genattr->set_snoop(t.ext.gen_attr.snoop);
			genattr->set_domain(t.ext.gen_attr.domain);
			genattr->set_barrier(t.ext.gen_attr.barrier);
			genattr->set_is_read_tx(t.ext.gen_attr.is_read);

			gp->set_extension(genattr);
		}
	}

	virtual bool done() { return m_it == m_transfers.end(); }
	virtual void next() { m_it++; }

private:
	DataTransferVec m_transfers;
	DataTransferIt  m_it;
};

#endif
