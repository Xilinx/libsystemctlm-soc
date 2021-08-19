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
#ifndef AXI2TLM_HW_BRIDGE_H__
#define AXI2TLM_HW_BRIDGE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <assert.h>
#include "systemc.h"

#include "tlm-modules/tlm-aligner.h"
#include "tlm-modules/tlm-wrap-expander.h"
#include "tlm-extensions/genattr.h"

#include "tlm-bridges/tlm2vfio-bridge.h"
#include "rtl-bridges/pcie-host/axi/tlm/tlm-hw-bridge-base.h"
#include "rtl-bridges/pcie-host/axi/tlm/private/user_slave_addr.h"

#include "utils/bindump.h"
#include "utils/hexdump.h"

#undef D
#define D(x) do {		\
	if (debug_level) {	\
		x;		\
	}			\
} while (0)

#ifndef MIN
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

#define MAX_NR_DESCRIPTORS 16
#define DESC_MASK 0xffff

class axi2tlm_hw_bridge
: public tlm_hw_bridge_base
{
public:
	tlm_utils::simple_initiator_socket<axi2tlm_hw_bridge> init_socket;

	SC_HAS_PROCESS(axi2tlm_hw_bridge);

	axi2tlm_hw_bridge(sc_module_name name, uint64_t base_addr = 0,
			  uint64_t base_offset = 0, vfio_dev *vdev = NULL);
	~axi2tlm_hw_bridge() {
		delete mm;
	}
private:

	enum {
		DESC_STATE_FREE,
		DESC_STATE_DATA,
	};

	uint32_t r_resp;
	int desc_state[MAX_NR_DESCRIPTORS];
	uint32_t desc_busy;
	uint32_t desc_size[MAX_NR_DESCRIPTORS];
	tlm::tlm_generic_payload *desc_gp[MAX_NR_DESCRIPTORS];
	bool mode1;
	bool debug;

	tlm_utils::simple_initiator_socket<axi2tlm_hw_bridge> we_init_socket;
	tlm_utils::simple_target_socket<axi2tlm_hw_bridge> we_target_socket;
	tlm_wrap_expander wrap_expander;

	// MAX AXI4 transaction size.
#define MAX_DATA_BYTES (MAX_NR_DESCRIPTORS * AXI4_MAX_BURSTLENGTH * 1024 / 8)
	uint32_t data32[MAX_DATA_BYTES / 4];
	uint32_t be32[MAX_DATA_BYTES / 4];
	tlm::tlm_generic_payload gp;
	tlm_mm_vfio *mm;

	void reset_thread(void);
	void work_thread(void);

	bool process_be(uint32_t data_offset, uint32_t size, uint32_t *in32, uint32_t *out32);
	void process_desc_free(unsigned int d, uint32_t r_avail);
	unsigned int process(uint32_t r_avail);

	bool is_axilite_slave(void) {
		return bridge_type == TYPE_AXI4_LITE_SLAVE ||
			bridge_type == TYPE_PCIE_AXI4_LITE_SLAVE;
	}

	bool is_axi4_slave(void) {
		return bridge_type == TYPE_AXI4_SLAVE ||
			bridge_type == TYPE_PCIE_AXI4_SLAVE;
	}

	virtual void we_b_transport(tlm::tlm_generic_payload& gp, sc_time& delay) {
		init_socket->b_transport(gp, delay);
	}
};

axi2tlm_hw_bridge::axi2tlm_hw_bridge(sc_module_name name,
				uint64_t base_addr, uint64_t offset,
				vfio_dev *vdev) :
	tlm_hw_bridge_base(name, base_addr, offset),
	init_socket("init_socket"),
	desc_busy(0),
	we_init_socket("we_init_socket"),
	we_target_socket("we_target_socket"),
	wrap_expander("wrap_expander", true),
	mm(NULL)
{
	mode1 = true;
	if (mode1) {
		mm = new tlm_mm_vfio(MAX_NR_DESCRIPTORS,
				AXI4_MAX_BURSTLENGTH * 1024 / 8, vdev);
	}

	we_target_socket.register_b_transport(this, &axi2tlm_hw_bridge::we_b_transport);
	we_init_socket.bind(wrap_expander.target_socket);
	wrap_expander.init_socket(we_target_socket);

	SC_THREAD(reset_thread);
	SC_THREAD(work_thread);
	SC_THREAD(process_wires);
}

void axi2tlm_hw_bridge::reset_thread(void)
{
	unsigned int i;

	while (true) {
		uint32_t r;

		wait(rst.negedge_event());
		wait(SC_ZERO_TIME);

		bridge_probe();
		bridge_reset();
		printf("axi2tlm: mode=%d DESC_MASK=%x\n", mode1, DESC_MASK);

		// Select Mode
		dev_write32(MODE_SELECT_REG_ADDR_SLAVE, mode1);
		r_resp = 0;

		r = dev_read32(INTR_TXN_AVAIL_STATUS_REG_ADDR_SLAVE);
		if (r) {
			printf("Stale pending transactions avail=%x\n", r);
			dev_write32(STATUS_RESP_COMP_REG_ADDR_SLAVE, r);
			// These now move o busy and handled below.
		}

		// Try to do gracious recovery to avoid hanging
		// active masters.
		r = dev_read32(STATUS_BUSY_REG_ADDR_SLAVE);
		if (r) {
			printf("Graceful recovery from busy=%x\n", r);
			// Generate dummy responses.
			dev_write32(STATUS_RESP_COMP_REG_ADDR_SLAVE, r);
			dev_write32(OWNERSHIP_FLIP_REG_ADDR_SLAVE, r);

			while (r)
				r = dev_read32(STATUS_BUSY_REG_ADDR_SLAVE);

			dev_write32(STATUS_RESP_COMP_REG_ADDR_SLAVE, 0);
		}

		// Enable all allocation IRQs
		dev_write32(INTR_TXN_AVAIL_ENABLE_REG_ADDR_SLAVE, DESC_MASK);

		// Enable C2H interrupts
		dev_write32(INTR_C2H_TOGGLE_ENABLE_0_REG_ADDR_SLAVE, 0xFFFFFFFF);
		dev_write32(INTR_C2H_TOGGLE_ENABLE_1_REG_ADDR_SLAVE, 0xFFFFFFFF);

		// Ack any stale completions.
		dev_write32(STATUS_RESP_COMP_REG_ADDR_SLAVE, 0x0);

		// Hand all descriptors to HW.
		dev_write32(OWNERSHIP_FLIP_REG_ADDR_SLAVE, DESC_MASK);

		if (mm) {
			for (i = 0; i < MAX_NR_DESCRIPTORS; i++) {
				uint64_t desc_addr = this->desc_addr(i);
				tlm::tlm_generic_payload &gp = *mm->allocate(i);
				uint64_t v64;

				v64 = (uint64_t) gp.get_data_ptr();
				v64 = mm->to_dma(v64);
				dev_write32(desc_addr + DESC_0_DATA_HOST_ADDR_0_REG_ADDR_SLAVE, v64);
				v64 >>= 32;
				dev_write32(desc_addr + DESC_0_DATA_HOST_ADDR_1_REG_ADDR_SLAVE, v64);
				dev_write32(desc_addr + DESC_0_DATA_HOST_ADDR_2_REG_ADDR_SLAVE, 0);
				dev_write32(desc_addr + DESC_0_DATA_HOST_ADDR_3_REG_ADDR_SLAVE, 0);

				v64 = (uint64_t) gp.get_byte_enable_ptr();
				v64 = mm->to_dma(v64);
				dev_write32(desc_addr + DESC_0_WSTRB_HOST_ADDR_0_REG_ADDR_SLAVE, v64);
				v64 >>= 32;
				dev_write32(desc_addr + DESC_0_WSTRB_HOST_ADDR_1_REG_ADDR_SLAVE, v64);
				dev_write32(desc_addr + DESC_0_WSTRB_HOST_ADDR_2_REG_ADDR_SLAVE, 0);
				dev_write32(desc_addr + DESC_0_WSTRB_HOST_ADDR_3_REG_ADDR_SLAVE, 0);
			}
		}

		probed = true;
		probed_event.notify();
	}
}

// Return true if Byte-enables are needed.
bool axi2tlm_hw_bridge::process_be(uint32_t data_offset, uint32_t size,
				uint32_t *in32, uint32_t *out32)
{
	unsigned int i;
	uint32_t be_byte;
	bool needed = false;

	assert((data_offset % 4) == 0);

	for (i = 0; i < size; i += 4) {
		unsigned int bytes_to_handle = MIN(4, size - i);
		uint64_t be_mask;

		if (in32)
			be_byte = in32[i / 4];
		else
			be_byte = dev_read32(DRAM_OFFSET_WSTRB_SLAVE + data_offset + i);
		out32[i / 4] = be_byte;

		if (0) {
			// Check if some strobes are unset.
			// Debug code to double check the type & 2 feature.
			be_mask = 1;
			be_mask = (be_mask << (bytes_to_handle * 8)) - 1;
			be_byte &= be_mask;
			if (be_byte != be_mask) {
				needed = true;
			}
		} else {
			needed = true;
		}
	}

	assert(needed);
	return needed;
}

void axi2tlm_hw_bridge::process_desc_free(unsigned int d, uint32_t r_avail)
{
	uint64_t desc_addr = this->desc_addr(d);
	sc_time delay(SC_ZERO_TIME);
	unsigned int offset = 0;
	unsigned int number_bytes;
	unsigned int burst_length;
	uint64_t axaddr;
	unsigned int axburst;
	unsigned int axprot;
	unsigned int axlock;
	unsigned int axlen;
	unsigned int axqos = 0;
	uint32_t data_offset;
	uint32_t axsize;
	uint32_t axid;
	uint32_t attr;
	uint32_t size;
	// tx_size holds the size of the TLM transfer + offset. Most of the
	// time it's the same as the AXI transfer but for some specific burst
	// types (narrow bursts) it differs.
	uint32_t tx_size;
	uint32_t type;
	int axi_resp;
	bool is_write;
	bool be_needed = false;
	tlm::tlm_generic_payload &gp = mm ?  *mm->allocate(d) : this->gp;
	genattr_extension *genattr = NULL;
	uint32_t *data32;
	uint32_t *be32;

	if (mm) {
		gp.acquire();

		data32 = (uint32_t *) gp.get_data_ptr();
		be32 = (uint32_t *) gp.get_byte_enable_ptr();
		desc_gp[d] = &gp;

		// Pick up pre-allocated extension
		gp.get_extension(genattr);
	} else {
		data32 = this->data32;
		be32 = this->be32;
	}

	// Lazy allocation of extensions.
	if (!genattr) {
		genattr = new(genattr_extension);
		gp.set_extension(genattr);
	}

	axaddr = dev_read32(desc_addr + DESC_0_AXADDR_1_REG_ADDR_SLAVE);
	axaddr <<= 32;
	axaddr |= dev_read32(desc_addr + DESC_0_AXADDR_0_REG_ADDR_SLAVE);

	type = dev_read32(desc_addr + DESC_0_TXN_TYPE_REG_ADDR_SLAVE);
	is_write = !(type & 1);

	axsize = dev_read32(desc_addr + DESC_0_AXSIZE_REG_ADDR_SLAVE);
	number_bytes = 1 << axsize;
	size = dev_read32(desc_addr + DESC_0_SIZE_REG_ADDR_SLAVE);
	data_offset = dev_read32(desc_addr + DESC_0_DATA_OFFSET_REG_ADDR_SLAVE);
	axid = dev_read32(desc_addr + DESC_0_AXID_0_REG_ADDR_SLAVE);
	attr = dev_read32(desc_addr + DESC_0_ATTR_REG_ADDR_SLAVE);
	axburst = attr & 3;
	axlock = (attr >> 2) & 3;
	axprot = (attr >> 8) & 7;

	axlen = (size - 1) / data_bytewidth;
	burst_length = axlen + 1;

	if (is_axilite_slave()) {
		axburst = AXI_BURST_INCR;
		axlock = 0;
	} else if (is_axi4_slave()) {
		axlock &= 1;
		axqos = (attr >> 11) & 0xf;
	}

	genattr->set_wrap(axburst == AXI_BURST_WRAP);
	genattr->set_exclusive(axlock == AXI_LOCK_EXCLUSIVE);
	genattr->set_locked(axlock == AXI_LOCK_LOCKED);
	genattr->set_non_secure(axprot & AXI_PROT_NS);
	genattr->set_qos(axqos);

	D(printf("desc[%d]: axaddr=%lx type=%x is_write=%d axsize=%d "
		 "num-bytes=%d size=%d data_offset=%x axid=%d\n",
		 d, axaddr, type, is_write, axsize, number_bytes,
		 size, data_offset, axid));

	// A3.4.2 addr - (INT(addr/Data_Bus_Bytes)) * Data_Bus_Bytes;
	offset = axaddr - ((axaddr / data_bytewidth) * data_bytewidth);
	tx_size = size;

	if (is_write) {
		if (!mode1) {
			dev_copy_from(DRAM_OFFSET_WRITE_SLAVE + data_offset,
				(unsigned char *)data32, size, NULL, 0);
		}

		if (type & 2) {
			be_needed = process_be(data_offset, size, mode1 ? be32 : NULL, be32);
		}

		D(hexdump("axi-wr-data32", (unsigned char *)data32, size));
		D(hexdump("axi-wr-be32", (unsigned char *)be32, size));

		if (burst_length > 1 &&
		    (axburst == AXI_BURST_FIXED || number_bytes < data_bytewidth)) {
			uint8_t *d8, *be8;
			unsigned int src_pos, pos, len, addr = axaddr;
			unsigned int b;
			int i;

			d8 = (unsigned char *)data32;
			be8 = (unsigned char *)be32;

			D(printf("Narrow write BURST\n"));
			len = number_bytes;
			len -= axaddr & (number_bytes - 1);
			pos = offset + len;
			D(printf("off=%d len=%d src_pos=%d pos=%d\n",
				offset, len, src_pos, pos));
			for (b = 1; b < burst_length; b++) {
				if (axburst != AXI_BURST_FIXED) {
					len = number_bytes;
					src_pos = pos % data_bytewidth;
				} else {
					// For fixed bursts, length remains
					// unmodified each beat (due to possible unalignment).
					src_pos = offset;
				}
				src_pos += b * data_bytewidth;

				D(printf("copy pos=%x src_pos=%x len=%d\n",
						pos, src_pos, len));
				memmove(d8 + pos, d8 + src_pos, len);
				memmove(be8 + pos, be8 + src_pos, len);
				pos += len;
			}
			tx_size = pos;
			D(hexdump("narrow-wr-data32", (unsigned char *)data32, tx_size));
			D(hexdump("narrow-wr-be32", (unsigned char *)be32, tx_size));
		}
	} else {
		if (burst_length > 1 && number_bytes < data_bytewidth) {
			// Narrow read, we need to adjust the total size
			// we're going to read on the TLM side.
			tx_size = offset + number_bytes * burst_length;
			tx_size -= axaddr & (number_bytes - 1);
		}
	}

	gp.set_address(axaddr);
	gp.set_data_ptr((unsigned char *)data32 + offset);
	gp.set_data_length(tx_size - offset);
	gp.set_streaming_width(tx_size - offset);
	gp.set_byte_enable_ptr(be_needed ? (unsigned char *)be32 + offset: NULL);
	gp.set_byte_enable_length(be_needed ? tx_size - offset: 0);
	gp.set_command(is_write ? tlm::TLM_WRITE_COMMAND : tlm::TLM_READ_COMMAND);

	if (axburst == AXI_BURST_FIXED) {
		unsigned int sw;

		// A FIXED burst does cannot cross number_bytes boundaries.
		sw = number_bytes;
		sw -= axaddr & (number_bytes - 1);
		gp.set_streaming_width(sw);
	}

	if (axburst == AXI_BURST_WRAP) {
		// Wrap expander.
		we_init_socket->b_transport(gp, delay);
	} else {
		init_socket->b_transport(gp, delay);
	}

	if (!is_write) {
		D(hexdump("read_data32", (unsigned char *)data32, tx_size));

		if (burst_length > 1 &&
		    (axburst == AXI_BURST_FIXED || number_bytes < data_bytewidth)) {
			uint8_t *d8 = (unsigned char *)data32;
			unsigned int pos, len, dst_pos;
			uint8_t bounce_d8[4096];
			unsigned int b;

			// We need to use a bounce buffer so that the buffer
			// expansion does not overwrite it's own source data.
			memcpy(bounce_d8, data32, tx_size);

			D(printf("Narrow read BURST\n"));
			len = number_bytes;
			len -= axaddr & (number_bytes - 1);
			pos = offset + len;
			for (b = 1; b < burst_length; b++) {
				if (axburst != AXI_BURST_FIXED) {
					len = number_bytes;
					dst_pos = pos % data_bytewidth;
				} else {
					dst_pos = offset;
				}
				dst_pos += b * data_bytewidth;

				D(printf("copy pos=%x dst_pos=%x len=%d\n",
					pos, dst_pos, number_bytes));
				memmove(d8 + dst_pos, bounce_d8 + pos, len);
				pos += len;
			}
			D(hexdump("narrow-rd-data32", (unsigned char *)data32, size));
		}

		if (!mode1) {
			dev_copy_to(DRAM_OFFSET_READ_SLAVE + data_offset,
				(unsigned char *)data32, size);
		}
	}

	axi_resp = tlm_gp_get_axi_resp(gp);
	r_resp &= ~(3 << (d * 2));
	r_resp |= axi_resp << (d * 2);
	dev_write32_strong(STATUS_RESP_REG_ADDR_SLAVE, r_resp);
	dev_write32_strong(RESP_ORDER_REG_ADDR_SLAVE, d | (1U << 31));

	dev_write32_strong(OWNERSHIP_FLIP_REG_ADDR_SLAVE, 1U << d);
	// Move along.
	desc_state[d] = DESC_STATE_DATA;
	desc_busy |= 1U << d;
	if (mm) {
		gp.set_data_ptr((uint8_t *) data32);
		gp.set_byte_enable_ptr((uint8_t *) be32);
	} else {
		gp.release_extension(genattr);
	}
}

unsigned int axi2tlm_hw_bridge::process(uint32_t r_avail)
{
	uint32_t num_pending_mask = 0;
	uint32_t num_pending = 0;
	unsigned int d;
	uint32_t own;
	uint32_t ack = 0;
	uint32_t busy;

	// ACK them.
	dev_write32(INTR_TXN_AVAIL_CLEAR_REG_ADDR_SLAVE, r_avail);
	busy = dev_read32(STATUS_BUSY_REG_ADDR_SLAVE);
	own = dev_read32(OWNERSHIP_REG_ADDR_SLAVE);

	// What HW doesn't own and is not TXN_AVAIL, ready to ACK.
	ack = (~busy) & (~own) & desc_busy & DESC_MASK;

	if (ack) {
		// For transactions to stay in order, we need to ACK all at once.
		if (!busy && !own)
		{
			dev_write32(OWNERSHIP_FLIP_REG_ADDR_SLAVE, ack);
		} else {
			ack = 0;
		}
	}

	// Now process them.
	for (d = 0; d < MAX_NR_DESCRIPTORS; d++) {
		if (r_avail & (1U << d)) {
			process_desc_free(d, r_avail);
		}
		if (ack & (1U << d)) {
			desc_state[d] = DESC_STATE_FREE;
			desc_busy &= ~(1U << d);
			if (mm) {
				desc_gp[d]->release();
			}
			desc_gp[d] = NULL;
		}
		if (desc_state[d] != DESC_STATE_FREE) {
			num_pending++;
			num_pending_mask |= 1U << d;
		}
	}

	if (debug) {
		printf("r_avail=%x busy=%x own=%x ack=%x pending=%x\n",
			r_avail, busy, own, ack, num_pending_mask);
	}

	// When write transactions come in with AW phase active but delayed
	// W phase, a descriptor will get allocated but not become available
	// for processing until data comes. If a read transaction comes in
	// in between, another descriptor will be allocated and the read
	// will become available before the write (reordered descriptors).
	// So it's not enough to check for the top bit to be set here, we
	// need to check that all bits are set before we issue an ACK.
	//
	// TODO: We probably need to enforce in-order handling of descriptors
	// to avoid reordering when not allowed by the AXI rules.
	D(print_binary("\ndb", desc_busy));
	D(print_binary("\nbusy", busy));
	D(print_binary("\nown", own));
	return desc_busy == 0xffff;
}

void axi2tlm_hw_bridge::work_thread(void)
{
	static const bool use_irq = true;
	unsigned int num_pending;
	uint32_t r_avail;
	unsigned int num_loops;

	if (!probed)
		wait(probed_event);

	while (true) {
		if (use_irq && !irq.read()) {
			wait(irq.posedge_event());
		} else {
			wait(1, SC_NS);
		}

		// Read-out which descriptors are pending.
		r_avail = dev_read32(INTR_TXN_AVAIL_STATUS_REG_ADDR_SLAVE);
		if (!r_avail)
			continue;

		// Mask interrupts while we process things.
		dev_write32(INTR_TXN_AVAIL_ENABLE_REG_ADDR_SLAVE, 0);

		// Keep polling as long as there are pending descriptors.
		// We need to do this because completion interrupts
		// are not yet working.
		num_loops = 0;
		this->debug = false;
		do {
			num_pending = process(r_avail);
			r_avail = dev_read32(INTR_TXN_AVAIL_STATUS_REG_ADDR_SLAVE);
			num_loops++;
			if (num_loops > 10000) {
				this->debug = true;
			}
		} while(r_avail || num_pending);

		dev_write32(INTR_TXN_AVAIL_ENABLE_REG_ADDR_SLAVE, DESC_MASK);
	}
}
#endif
