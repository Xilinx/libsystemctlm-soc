/*
 * PCIe hosted TLM to AXI HW bridge.
 *
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Edgar E. Iglesias.
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

#ifndef TLM_HW_BRIDGE_BASE_H__
#define TLM_HW_BRIDGE_BASE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <unistd.h>
#include <assert.h>
#include <iostream>
#include "systemc.h"

#include "tlm-modules/tlm-aligner.h"
#include "tlm-extensions/genattr.h"
#include "utils/dev-access.h"
#include "utils/bitops.h"

#include "rtl-bridges/pcie-host/axi/tlm/private/user_slave_addr.h"

#undef D
#define D(x) do {		\
	if (debug_level) {	\
		x;		\
	}			\
} while (0)

#ifndef MIN
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

class tlm_hw_bridge_base
: public sc_core::sc_module
{
public:
	tlm_utils::simple_initiator_socket<tlm_hw_bridge_base> bridge_socket;

	tlm_hw_bridge_base(sc_module_name name, uint64_t base_addr = 0,
			  uint64_t base_offset = 0);

	void bridge_reset(void) {
		dev_write32(RESET_REG_ADDR_SLAVE, ~31);
		wait(10, SC_NS);
		usleep(1000);
		dev_write32(RESET_REG_ADDR_SLAVE, 31);
	}

	void set_debuglevel(int l) {
		debug_level = l;
	}

	sc_in<bool> rst;
	sc_in<bool> irq;
	sc_vector<sc_out<bool> > c2h_irq;

protected:
	enum {
		TYPE_AXI3_MASTER		= 0,
		TYPE_AXI3_SLAVE			= 1,
		TYPE_AXI4_MASTER		= 2,
		TYPE_AXI4_SLAVE			= 3,
		TYPE_AXI4_LITE_MASTER		= 4,
		TYPE_AXI4_LITE_SLAVE		= 5,
		TYPE_AXI4_STREAM_MASTER		= 6,
		TYPE_AXI4_STREAM_SLAVE		= 7,
		TYPE_ACE_MASTER			= 8,
		TYPE_ACE_SLAVE			= 9,
		TYPE_CHI_MASTER			= 10,
		TYPE_CHI_SLAVE			= 11,
		TYPE_CXS_BRIDGE			= 12,
		TYPE_PCIE_AXI4_MASTER		= 18,
		TYPE_PCIE_AXI4_SLAVE		= 19,
		TYPE_PCIE_AXI4_LITE_MASTER	= 20,
		TYPE_PCIE_AXI4_LITE_SLAVE	= 21,
	};

	unsigned int version_major;
	unsigned int version_minor;
	unsigned int bridge_type;
	unsigned int data_bitwidth;
	unsigned int data_bytewidth;
	unsigned int nr_descriptors;

	// Base address of HW bridge
	uint64_t base_addr;
	// Offset applied to all addresses.
	uint64_t base_offset;

	int debug_level;

	sc_vector<sc_signal<bool > > sig_dummy_bool;

	bool probed;
	sc_event probed_event;

	const char *bridge_type2str(unsigned int t) {
		static const char *type2str[] = {
			"axi3-master",
			"axi3-slave",
			"axi4-master",
			"axi4-slave",
			"axi4lite-master",
			"axi4lite-slave",
			"axi4stream-master",
			"axi4stream-slave",
			"ace-master",
			"ace-slave",
			"chi-master",
			"chi-slave",
			"cxs-bridge",
			"unknown",		/* 13 */
			"unknown",		/* 14 */
			"unknown",		/* 15 */
			"unknown",		/* 16 */
			"unknown",		/* 17 */
			"pcie-axi-master",	/* 18 */
			"pcie-axi-slave",
			"pcie-axi4lite-master",
			"pcie-axi4lite-slave",
		};

		if (t >= (sizeof(type2str) / sizeof(*type2str))) {
			std::ostringstream ostr;

			ostr << "Unknown or unsupported bridge type " << std::hex << t;
			SC_REPORT_ERROR("tlm-hw-bridge", ostr.str().c_str());
			return "unknown";
		}
		return type2str[t];
	}

	// Low-level device-access
	void dev_access(tlm::tlm_command cmd, uint64_t offset,
			void *buf, unsigned int len);
	void dev_write32(uint64_t offset, uint32_t v);
	void dev_write32_strong(uint64_t offset, uint32_t v);
	void dev_copy_to(uint64_t addr, unsigned char *buf,
			unsigned int len);
	void dev_copy_from(uint64_t addr, unsigned char *buf,
			unsigned int len,
			unsigned char *be, unsigned int be_len);
	uint32_t dev_read32(uint64_t offset);

	// Bridge descriptor helper functions.
	uint64_t desc_addr(int d);
	void desc_wait_ownership(int d);

	// Bridge probing
	void bridge_probe(void);
	void process_wires(void);
	uint64_t c2h_wires_toggled(void);
	int nr_connected_irq;
	static sc_event process_wires_ev;
	static unsigned int processing_wires;

	void base_before_end_of_elaboration(void)
	{
		unsigned int i;

		nr_connected_irq = 0;
		for (i = 0; i < c2h_irq.size(); i++) {
			if (c2h_irq[i].size()) {
				nr_connected_irq++;
				continue;
			}

			c2h_irq[i](sig_dummy_bool[i]);
		}
	}

private:
	bool dmi_ptr_valid;
	unsigned char *dmi_ptr;
	uint64_t dmi_ptr_addr;
	uint64_t dmi_ptr_addr_end;
	sc_time dmi_ptr_read_latency;
	sc_time dmi_ptr_write_latency;

	tlm::tlm_generic_payload dev_tr;

	void invalidate_direct_mem_ptr(sc_dt::uint64 start, sc_dt::uint64 end)
	{
		dmi_ptr_valid = false;
	}

	// Specific instances may override this call.
	void before_end_of_elaboration(void)
	{
		base_before_end_of_elaboration();
	}
};

unsigned int tlm_hw_bridge_base::processing_wires = 0;
sc_event tlm_hw_bridge_base::process_wires_ev;

tlm_hw_bridge_base::tlm_hw_bridge_base(sc_module_name name,
				uint64_t base_addr, uint64_t offset) :
	sc_module(name),
	bridge_socket("bridge_socket"),
	rst("rst"),
	irq("irq"),
	c2h_irq("c2h_intr", 64),
	sig_dummy_bool("sig_dummy_bool", 64),
	probed(false),
	probed_event("probed_event")
{
	this->base_addr = base_addr;
	this->base_offset = base_offset;

	bridge_socket.register_invalidate_direct_mem_ptr(this,
				&tlm_hw_bridge_base::invalidate_direct_mem_ptr);
	dmi_ptr_valid = false;
}

void tlm_hw_bridge_base::bridge_probe(void)
{
	uint32_t r;

	r = dev_read32(BRIDGE_IDENTIFICATION_REG_ADDR_SLAVE);
	printf("Bridge ID %x\n",r);

	r = dev_read32(BRIDGE_POSITION_REG_ADDR_SLAVE);
	printf("Position %x\n", r);

	r = dev_read32(VERSION_REG_ADDR_SLAVE);
	printf("version=%x\n", r);
	version_major = (r >> 8) & 0xff;
	version_minor = r  & 0xff;

	bridge_type = dev_read32(BRIDGE_TYPE_REG_ADDR_SLAVE);
	printf("type=%x %s\n", bridge_type, bridge_type2str(bridge_type));
	r = dev_read32(AXI_BRIDGE_CONFIG_REG_ADDR_SLAVE);

	data_bitwidth = 1 << ((r & 7) + 3);
	data_bytewidth = data_bitwidth / 8;
	nr_descriptors = dev_read32(AXI_MAX_DESC_REG_ADDR_SLAVE);

	printf("Bridge version %d.%d\n", version_major, version_minor);
	printf("Bridge data-width %d\n", data_bitwidth);
	printf("Bridge nr-descriptors: %d\n", nr_descriptors);
}

uint64_t tlm_hw_bridge_base::c2h_wires_toggled(void)
{
	uint64_t r_toggles;

	processing_wires++;
	r_toggles = dev_read32(INTR_C2H_TOGGLE_STATUS_1_REG_ADDR_SLAVE);
	r_toggles <<= 32;
	r_toggles |= dev_read32(INTR_C2H_TOGGLE_STATUS_0_REG_ADDR_SLAVE);
	processing_wires--;

	return r_toggles;
}

void tlm_hw_bridge_base::process_wires(void)
{
	while (true) {
		uint64_t r_toggles;
		uint64_t r_irqs;
		unsigned int i;

		if (nr_connected_irq == 0)
			return;

		do {
			r_toggles = c2h_wires_toggled();
			if (!r_toggles) {
				if (!irq.read())
					wait(irq.posedge_event() | process_wires_ev);
			}
		} while (r_toggles == 0);

		processing_wires++;
		dev_write32(INTR_C2H_TOGGLE_CLEAR_0_REG_ADDR_SLAVE,
				r_toggles);
		dev_write32(INTR_C2H_TOGGLE_CLEAR_1_REG_ADDR_SLAVE,
				r_toggles >> 32);

		r_irqs = dev_read32(C2H_INTR_STATUS_1_REG_ADDR_SLAVE);
		r_irqs <<= 32;
		r_irqs |= dev_read32(C2H_INTR_STATUS_0_REG_ADDR_SLAVE);

		D(printf("process-wires toggles=%lx r_irqs=%lx\n",
			 r_toggles, r_irqs));
		for (i = 0; i < c2h_irq.size(); i++) {
			if (r_toggles & bitops_mask64(i, 1)) {
				c2h_irq[i].write(r_irqs & 1);
			}
			r_irqs >>= 1;
		}

		processing_wires--;
	}
}

void tlm_hw_bridge_base::dev_access(tlm::tlm_command cmd, uint64_t offset,
					void *buf, unsigned int len)
{
	unsigned char *buf8 = (unsigned char *) buf;
	sc_time delay = SC_ZERO_TIME;

	offset += base_addr;

	// DMI is disabled for now until we find a way to issue IRQ acks
	// on memory transactions. VFIO INTX handling is a bit peculiar
	// in that interrupts need to explicitely be ACK:ed.
	if (dmi_ptr_valid && len > 8 &&
	    offset >= dmi_ptr_addr &&
	    (offset + len) <= dmi_ptr_addr_end) {
                offset -= dmi_ptr_addr;
		if (cmd == tlm::TLM_READ_COMMAND) {
			memcpy_from_io((uint8_t *) buf, dmi_ptr + offset, len);
			wait(dmi_ptr_read_latency);
		} else {
			memcpy_to_io(dmi_ptr + offset, (uint8_t *) buf, len);
			wait(dmi_ptr_write_latency);
		}
		return;
	}

	dev_tr.set_command(cmd);
	dev_tr.set_address(offset);
	dev_tr.set_data_ptr(buf8);
	dev_tr.set_data_length(len);
	dev_tr.set_streaming_width(len);
	dev_tr.set_dmi_allowed(false);
	dev_tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

	bridge_socket->b_transport(dev_tr, delay);
	assert(dev_tr.get_response_status() == tlm::TLM_OK_RESPONSE);

	// See comment about DMI above.
	if (!dmi_ptr_valid && dev_tr.is_dmi_allowed()) {
		tlm::tlm_dmi dmi_data;
		bool valid;

		valid = bridge_socket->get_direct_mem_ptr(dev_tr, dmi_data);
		if (valid && dmi_data.is_read_allowed()) {
			dmi_ptr_valid = true;
			dmi_ptr = dmi_data.get_dmi_ptr();
			dmi_ptr_addr = dmi_data.get_start_address();
			dmi_ptr_addr_end = dmi_data.get_end_address();
			dmi_ptr_read_latency = dmi_data.get_read_latency();
			dmi_ptr_write_latency = dmi_data.get_write_latency();
		}
	}
}

uint32_t tlm_hw_bridge_base::dev_read32(uint64_t offset)
{
	uint32_t r;
	assert((offset & 3) == 0);
	dev_access(tlm::TLM_READ_COMMAND, offset, &r, sizeof(r));
	return r;
}

void tlm_hw_bridge_base::dev_write32(uint64_t offset, uint32_t v)
{
	uint32_t dummy;
	assert((offset & 3) == 0);
	dev_access(tlm::TLM_WRITE_COMMAND, offset, &v, sizeof(v));
	// Enforce PCI ordering.
	dev_access(tlm::TLM_READ_COMMAND, offset, &dummy, sizeof(dummy));
}

void tlm_hw_bridge_base::dev_write32_strong(uint64_t offset, uint32_t v)
{
	uint32_t dummy;

	dev_write32(offset, v);

	// Enforce PCI ordering. Reads may not get reordered around writes
	// betweem same master and slave.
	dev_access(tlm::TLM_READ_COMMAND, offset, &dummy, sizeof(dummy));
}

uint64_t tlm_hw_bridge_base::desc_addr(int d)
{
	return 0x3000 + 0x200 * d;
}

void tlm_hw_bridge_base::desc_wait_ownership(int d)
{
	uint32_t r;

	assert(d < 31);
	do {
		r = dev_read32(OWNERSHIP_REG_ADDR_SLAVE);
		if (!(r & (1 << d))) {
			wait(SC_ZERO_TIME);
		}
	} while (r & (1 << d));
}

void tlm_hw_bridge_base::dev_copy_to(uint64_t offset, unsigned char *buf,
				     unsigned int len)
{
	dev_access(tlm::TLM_WRITE_COMMAND, offset, buf, len);
	return;
}

void tlm_hw_bridge_base::dev_copy_from(uint64_t offset, unsigned char *buf,
				       unsigned int len,
				       unsigned char *be, unsigned int be_len)
{
	unsigned int word_offset = offset % 4;
	uint32_t v;
	unsigned int i = 0;

	if (!be_len) {
		dev_access(tlm::TLM_READ_COMMAND, offset, buf, len);
		return;
	}

	offset -= word_offset;
	while (i < len) {
		size_t len_to_copy = MIN(len - i, sizeof(v) - word_offset);

		v = dev_read32(offset);
		v >>= word_offset * 8;

		if (be && be_len) {
			unsigned int j;

			for (j = 0; j < len_to_copy; j++) {
				int pos = i + j;
				if (be[pos % be_len] == TLM_BYTE_ENABLED)
					buf[pos] = v;
				v >>= 8;
			}
		} else {
			memcpy(buf + i, &v, len_to_copy);
		}

		word_offset = 0;
		i += len_to_copy;
		offset += 4;
	}
}
#endif
