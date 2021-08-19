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
#ifndef TLM2AXI_HW_BRIDGE_H__
#define TLM2AXI_HW_BRIDGE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <assert.h>
#include "systemc.h"

#include "tlm-bridges/amba.h"
#include "tlm-modules/tlm-aligner.h"
#include "tlm-extensions/genattr.h"
#include "utils/bitops.h"

#include "rtl-bridges/pcie-host/axi/tlm/tlm-hw-bridge-base.h"
#include "rtl-bridges/pcie-host/axi/tlm/private/user_master_addr.h"

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

class tlm2axi_hw_bridge
: public tlm_hw_bridge_base
{
public:
	tlm_utils::simple_target_socket<tlm2axi_hw_bridge> tgt_socket;
	sc_vector<sc_in <bool> > h2c_irq;

	SC_HAS_PROCESS(tlm2axi_hw_bridge);

	tlm2axi_hw_bridge(sc_module_name name, uint64_t base_addr = 0,
			  uint64_t base_offset = 0,
			  bool aligner_enable = true);
	~tlm2axi_hw_bridge() {
		delete proxy_init_socket;
		delete proxy_target_socket;
		delete aligner;
	}

private:
	uint64_t base_offset;
	bool aligner_enable;

	sc_mutex mutex;

	sc_vector<sc_signal<bool > > sig_dummy_bool_h2c;

	bool is_axilite_master(void);
	void configure_aligner(void);
	void reset_thread(void);
	void desc_setup_wstrb(int d, uint64_t addr,
			      unsigned int size,
			      unsigned int total_size,
			      unsigned char *be,
			      unsigned int be_len);
	int desc_access(int d, uint64_t addr, bool is_write,
			unsigned int size,
			unsigned char *be, unsigned int be_len,
			genattr_extension *attr);

	uint32_t compute_attr(genattr_extension *attr);
	virtual void b_transport(tlm::tlm_generic_payload& trans,
				 sc_time& delay);

	virtual void b_transport_proxy(tlm::tlm_generic_payload& trans,
					sc_time& delay) {
		return proxy_init_socket[0]->b_transport(trans, delay);
	}

	void before_end_of_elaboration(void)
	{
		unsigned int i;

		base_before_end_of_elaboration();

		for (i = 0; i < h2c_irq.size(); i++) {
			if (h2c_irq[i].size())
				continue;

			h2c_irq[i](sig_dummy_bool_h2c[i]);
		}
	}

	// Used to chop and align incoming transactions.
	tlm_aligner *aligner;
	tlm_utils::simple_initiator_socket<tlm2axi_hw_bridge> *proxy_init_socket;
	tlm_utils::simple_target_socket<tlm2axi_hw_bridge> *proxy_target_socket;
};

tlm2axi_hw_bridge::tlm2axi_hw_bridge(sc_module_name name,
				uint64_t base_addr, uint64_t base_offset,
				bool aligner_enable) :
	tlm_hw_bridge_base(name, base_addr, 0),
	tgt_socket("tgt_socket"),
	h2c_irq("h2c_irq", 128),
	base_offset(base_offset),
	sig_dummy_bool_h2c("sig_dummy_bool_h2c", 128),
	aligner(NULL),
	proxy_init_socket(NULL),
	proxy_target_socket(NULL)
{
	if (aligner_enable) {
		aligner = new tlm_aligner("aligner", 128,
				AXI4_MAX_BURSTLENGTH * 16, /* MAX AXI length.  */
				4 * 1024, /* AXI never allows crossing of 4K boundary.  */
				true); /* WRAP burst-types require natural alignment.  */
		proxy_init_socket = new tlm_utils::simple_initiator_socket<tlm2axi_hw_bridge>("proxy_init_socket");
		proxy_target_socket = new tlm_utils::simple_target_socket<tlm2axi_hw_bridge>("proxy_target_socket");
		(*proxy_init_socket)(aligner->target_socket);
		aligner->init_socket(*proxy_target_socket);

		tgt_socket.register_b_transport(this, &tlm2axi_hw_bridge::b_transport_proxy);
		proxy_target_socket->register_b_transport(this, &tlm2axi_hw_bridge::b_transport);
	} else {
		tgt_socket.register_b_transport(this, &tlm2axi_hw_bridge::b_transport);
	}
	SC_THREAD(reset_thread);
	SC_THREAD(process_wires);
}

bool tlm2axi_hw_bridge::is_axilite_master(void)
{
	return bridge_type == TYPE_AXI4_LITE_MASTER ||
               bridge_type == TYPE_PCIE_AXI4_LITE_MASTER;
}

void tlm2axi_hw_bridge::configure_aligner(void)
{
	unsigned int max_burstlen = 1;

	switch (bridge_type) {
	case TYPE_AXI3_MASTER:
	case TYPE_AXI3_SLAVE:
		max_burstlen = AXI3_MAX_BURSTLENGTH - 1;
		break;
	case TYPE_PCIE_AXI4_MASTER:
	case TYPE_PCIE_AXI4_SLAVE:
	case TYPE_AXI4_MASTER:
	case TYPE_AXI4_SLAVE:
		max_burstlen = AXI4_MAX_BURSTLENGTH - 1;
		break;
	case TYPE_PCIE_AXI4_LITE_MASTER:
	case TYPE_PCIE_AXI4_LITE_SLAVE:
	case TYPE_AXI4_LITE_MASTER:
	case TYPE_AXI4_LITE_SLAVE:
		max_burstlen = 1;
		break;
	}

	aligner->set_bus_width(data_bitwidth);
	aligner->set_max_len(max_burstlen * data_bytewidth);
}

void tlm2axi_hw_bridge::reset_thread(void)
{
	uint32_t r_intr_status;
	unsigned int d;

	while (true) {
		wait(rst.negedge_event());
		wait(SC_ZERO_TIME);

		bridge_probe();
		bridge_reset();
		configure_aligner();

		r_intr_status = dev_read32(INTR_STATUS_REG_ADDR_MASTER);
		if (r_intr_status && !irq.read()) {
			printf("master: IRQ stuck low: intr-status=%x irq=%d\n",
				r_intr_status, irq.read());
			printf("master: Reset to bring IRQ's back to life.\n");
			bridge_reset();
		}

		dev_write32(INTR_ERROR_ENABLE_REG_ADDR_MASTER, 0x0);
		dev_write32(INTR_COMP_ENABLE_REG_ADDR_MASTER, 0x0);

		// Enable c2h interrupts
		dev_write32(INTR_C2H_TOGGLE_ENABLE_0_REG_ADDR_MASTER,
				0xFFFFFFFF);
		dev_write32(INTR_C2H_TOGGLE_ENABLE_1_REG_ADDR_MASTER,
				0xFFFFFFFF);

		// Clear all pending completion interrupts.
		dev_write32_strong(INTR_COMP_CLEAR_REG_ADDR_MASTER, 0xffff);
		// Enable all completion interrupts.
		dev_write32_strong(INTR_COMP_ENABLE_REG_ADDR_MASTER, 0xffff);

		for (d = 0; d < 16; d++) {
			uint64_t d_base = desc_addr(d);

			// We only support 64bit addresses at the moment.
			dev_write32(d_base + DESC_0_AXADDR_2_REG_ADDR_MASTER, 0);
			dev_write32(d_base + DESC_0_AXADDR_3_REG_ADDR_MASTER, 0);

			// AxID - For the moment, we always use zero AxIDs.
			dev_write32(d_base + DESC_0_AXID_0_REG_ADDR_MASTER, 0);
			dev_write32(d_base + DESC_0_AXID_1_REG_ADDR_MASTER, 0);
			dev_write32(d_base + DESC_0_AXID_2_REG_ADDR_MASTER, 0);
			dev_write32(d_base + DESC_0_AXID_3_REG_ADDR_MASTER, 0);
		}

		probed = true;
		probed_event.notify();
	}
}

void tlm2axi_hw_bridge::desc_setup_wstrb(int d, uint64_t addr,
					unsigned int size,
					unsigned int total_size,
					unsigned char *be,
					unsigned int be_len)
{
	uint64_t r_addr = DRAM_OFFSET_WSTRB_MASTER;
	unsigned int offset;
	unsigned int nr_beats;
	unsigned int beat;
	unsigned int bit = 0;
	unsigned int i;

	offset = addr % data_bytewidth;
	nr_beats = (offset + size + data_bytewidth - 1) / data_bytewidth;

	D(printf("wstrb off=%d size=%d nr_beats=%d\n", offset, size, nr_beats));
	for (beat = 0; beat < nr_beats; beat++) {
		for (i = 0; i < data_bytewidth; i += 4) {
			uint32_t v;
			int bit_size;

			bit_size = MIN(size, 4);

			if (bit <= offset) {
				v = bitops_mask64((offset - bit) * 8,
						bit_size * 8);
			} else if (size > bit - offset) {
				v = bitops_mask64(0, (size - (bit - offset)) * 8);
			} else {
				v = 0;
			}

			// Handle user-provided BE.
			if (be && be_len) {
				int j;

				v = 0;
				for (j = 0; j < 4; j++) {
					unsigned int bit_pos = bit + j;

					// Are we within bounds?
					if (bit_pos < offset)
						continue;
					if (bit_pos >= offset + size)
						break;
					// Compute bit pos within active data.
					bit_pos -= offset;

					if (be[bit_pos % be_len] == TLM_BYTE_ENABLED) {
						v |= 0xff << (j * 8);
					}
				}
			}

			D(printf("wstrb[%lx] = %x bit=%d bit_size=%d\n",
					r_addr, v, bit, bit_size));
			dev_write32(r_addr, v);
			r_addr += 4;
			bit += 4;
		}
	}
}

uint32_t tlm2axi_hw_bridge::compute_attr(genattr_extension *attr)
{
	bool secure = 0;
	bool locked = 0;
	uint8_t qos = 0;
	uint8_t region = 0;
	uint32_t u32 = 0;

	if (attr) {
		secure = attr->get_secure();
		qos = attr->get_qos();
		region = attr->get_region();
	}

	// Encode into ATTR register format.
	u32 |= locked << 2;
	u32 |= secure << 9;
	u32 |= qos << 11;
	u32 |= region << 15;

	return u32;
}

int tlm2axi_hw_bridge::desc_access(int d, uint64_t addr, bool is_write,
				   unsigned int size,
				   unsigned char *be, unsigned int be_len,
				   genattr_extension *attr)
{
	uint64_t d_base = desc_addr(d);
	unsigned int offset;
	bool need_wstrb = false;
	unsigned int total_size;
	unsigned int nr_beats;
	int axsize = -1;
	bool use_irq;
	uint32_t v;

	offset = addr % data_bytewidth;

	nr_beats = (offset + size + data_bytewidth - 1) / data_bytewidth;
	total_size = nr_beats * data_bytewidth;

	/* Wait for an interrupt or poll?  */
	use_irq = nr_beats > 1;

	/*
	 * Currently, byte enables (WSTRB) can be auto-generated by the HW if:
	 * 1. Single-beat
	 * 2. Size matches exactly with AxSize (Size cannot be less)
	 */
	if (size <= data_bytewidth && !is_axilite_master()) {
		axsize = map_size_to_axsize(size);
		if (axsize != -1) {
			offset = 0;
		}
	}

	D(printf("tlm2axi: addr=%lx is_write=%d axsize=%d size=%d total_size=%d\n",
		addr, is_write, axsize, size, total_size));
	if ((axsize == -1 || be_len) && is_write) {
		desc_setup_wstrb(d, addr, size, total_size, be, be_len);
		need_wstrb = true;
		D(printf("need wstrb axsize=%d\n", axsize));
	}

	if (is_axilite_master()) {
		axsize = map_size_to_axsize(data_bytewidth);
		assert(axsize != -1);
	}

	/*
	 * Size does not match any AxSize. Find the nearest.
	 */
	if (axsize == -1) {
		if ((offset + size) >= data_bytewidth) {
			axsize = map_size_to_nearest_axsize(data_bytewidth);
		} else {
			axsize = map_size_to_nearest_axsize(offset + size);
		}
	}

	desc_wait_ownership(d);

	// 64bit address
	dev_write32(d_base + DESC_0_AXADDR_0_REG_ADDR_MASTER, addr);
	dev_write32(d_base + DESC_0_AXADDR_1_REG_ADDR_MASTER, addr >> 32);

	// Data offset
	dev_write32(d_base + DESC_0_DATA_OFFSET_REG_ADDR_MASTER,
		    DRAM_OFFSET_WRITE_MASTER);

	// Attributes
	v = compute_attr(attr);
	// INCR bursts
	v |= 1;
	dev_write32(d_base + DESC_0_ATTR_REG_ADDR_MASTER, v);

	// Total size
	dev_write32(d_base + DESC_0_SIZE_REG_ADDR_MASTER, total_size);
	// AxSize encoded bytes per beat
	dev_write32(d_base + DESC_0_AXSIZE_REG_ADDR_MASTER, axsize);
	// TXN type
	v = is_write ? 0 : 1;
	v |= need_wstrb ? 2 : 0;
	dev_write32(d_base + DESC_0_TXN_TYPE_REG_ADDR_MASTER, v);

	dev_write32_strong(OWNERSHIP_FLIP_REG_ADDR_MASTER, 1 << d);
	v = dev_read32(OWNERSHIP_REG_ADDR_MASTER);

	if (use_irq && (v & (1 << d))) {
		if (!irq.read())
			wait(irq.posedge_event());
	}

	desc_wait_ownership(d);

	dev_write32(INTR_COMP_CLEAR_REG_ADDR_MASTER, 1U << d);
	v = dev_read32(STATUS_RESP_REG_ADDR_MASTER);
	v >>= d * 2;
	v &= 3;
	return v;
}

void tlm2axi_hw_bridge::b_transport(tlm::tlm_generic_payload& trans,
                                  sc_time& delay)
{
	sc_dt::uint64 addr = trans.get_address();
	unsigned char *data = trans.get_data_ptr();
	unsigned int len = trans.get_data_length();
	unsigned char *be = trans.get_byte_enable_ptr();
	unsigned int be_len = trans.get_byte_enable_length();
	unsigned int sw = trans.get_streaming_width();
	genattr_extension *genattr;
	bool is_write = !trans.is_read();
	unsigned int offset;
	int resp;

	trans.get_extension(genattr);

	if (sw && sw < len) {
		trans.set_response_status(tlm::TLM_BURST_ERROR_RESPONSE);
		return;
	}

	if (!probed)
		wait(probed_event);

	addr += this->base_offset;
	offset = addr % data_bytewidth;

	mutex.lock();
	if (is_write) {
		dev_copy_to(DRAM_OFFSET_WRITE_MASTER + offset, data, len);
	}

	D(printf("hw bridge %s addr=%lx len=%d sw=%d be_len=%d\n",
		is_write ? "write" : "read", (uint64_t)addr, len, sw, be_len));
	resp = desc_access(0, addr, is_write, len, be, be_len, genattr);

	if (!is_write && (resp == AXI_OKAY || resp == AXI_EXOKAY)) {
		dev_copy_from(DRAM_OFFSET_READ_MASTER + offset, data, len, be, be_len);
	}
	D(hexdump("tlm2axi-data: ", data, len));
	tlm_gp_set_axi_resp(trans, resp);
	mutex.unlock();

	// SystemC uses voluntary preemption and we don't have a wait-queue.
	// If two callers are spinning around this interface, time may only
	// advance in the calls with the lock taken while competing threads
	// are stuck waiting for the lock(). Once this thread releases the
	// lock it may keep re-taking it for-ever.
	// Avoid that by yielding, now baked into the wires processing loop
	// below.

	// For transactions that are non-Early-Ack, any wire update as side
	// effects should be visible before we response.
	process_wires_ev.notify();
	do {
		wait(SC_ZERO_TIME);
	} while (processing_wires);
}
#endif
