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
#include "tlm-extensions/genattr.h"

#include "tlm-bridges/tlm2vfio-bridge.h"
#include "rtl-bridges/pcie-host/axi/tlm/tlm-hw-bridge-base.h"
#include "rtl-bridges/pcie-host/axi/tlm/private/user_slave_addr.h"

#include "tests/test-modules/hexdump.h"

#undef D
#define D(x) do {		\
	if (0) {		\
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
};

axi2tlm_hw_bridge::axi2tlm_hw_bridge(sc_module_name name,
				uint64_t base_addr, uint64_t offset,
				vfio_dev *vdev) :
	tlm_hw_bridge_base(name, base_addr, offset),
	init_socket("init-socket"),
	desc_busy(0)
{
	mode1 = true;
	if (mode1) {
		mm = new tlm_mm_vfio(MAX_NR_DESCRIPTORS,
				AXI4_MAX_BURSTLENGTH * 1024 / 8, vdev);
	}

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
	uint64_t axaddr;
	uint32_t data_offset;
	uint32_t axsize;
	uint32_t axid;
	uint32_t size;
	uint32_t type;
	bool is_write;
	bool be_needed = false;
	tlm::tlm_generic_payload &gp = mm ?  *mm->allocate(d) : this->gp;
	uint32_t *data32;
	uint32_t *be32;

	if (mm) {
		gp.acquire();

		data32 = (uint32_t *) gp.get_data_ptr();
		be32 = (uint32_t *) gp.get_byte_enable_ptr();
		desc_gp[d] = &gp;
	} else {
		data32 = this->data32;
		be32 = this->be32;
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

	D(printf("desc[%d]: axaddr=%lx type=%x is_write=%d axsize=%d "
		 "num-bytes=%d size=%d data_offset=%x axid=%d\n",
		 d, axaddr, type, is_write, axsize, number_bytes,
		 size, data_offset, axid));

	offset = axaddr % number_bytes;

	if (is_write) {
		if (!mode1) {
			dev_copy_from(DRAM_OFFSET_WRITE_SLAVE + data_offset,
				(unsigned char *)data32, size, NULL, 0);
		}

		if (type & 2) {
			be_needed = process_be(data_offset, size, mode1 ? be32 : NULL, be32);
		}
		D(hexdump("axi-wr-data32", (unsigned char *)data32 + offset, size - offset));
		D(hexdump("axi-wr-be32", (unsigned char *)be32 + offset, size - offset));
	}

	gp.set_address(axaddr);
	gp.set_data_ptr((unsigned char *)data32 + offset);
	gp.set_data_length(size - offset);
	gp.set_streaming_width(size - offset);
	gp.set_byte_enable_ptr(be_needed ? (unsigned char *)be32 + offset: NULL);
	gp.set_byte_enable_length(be_needed ? size - offset: 0);
	gp.set_command(is_write ? tlm::TLM_WRITE_COMMAND : tlm::TLM_READ_COMMAND);
	init_socket->b_transport(gp, delay);

	if (!is_write) {
		D(hexdump("read-data32", (unsigned char *)data32 + offset, size - offset));
		if (!mode1) {
			dev_copy_to(DRAM_OFFSET_READ_SLAVE + data_offset,
				(unsigned char *)data32, size);
		}
	}

	r_resp &= ~(3 << (d * 2));
	r_resp |= AXI_OKAY << (d * 2);
	dev_write32_strong(STATUS_RESP_REG_ADDR_SLAVE, r_resp);
	dev_write32_strong(RESP_ORDER_REG_ADDR_SLAVE, d | (1U << 31));

	dev_write32_strong(OWNERSHIP_FLIP_REG_ADDR_SLAVE, 1U << d);
	// Move along.
	desc_state[d] = DESC_STATE_DATA;
	desc_busy |= 1U << d;
	if (mm) {
		gp.set_data_ptr((uint8_t *) data32);
		gp.set_byte_enable_ptr((uint8_t *) be32);
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

	// Since we only ACK when all descriptors are done, we only
	// have pending work when the top descriptor is busy.
	return busy & (1 << (nr_descriptors - 1));
}

void axi2tlm_hw_bridge::work_thread(void)
{
	unsigned int num_pending;
	uint32_t r_avail;
	unsigned int num_loops;

	while (true) {
		if (!irq.read()) {
			wait(irq.posedge_event());
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
