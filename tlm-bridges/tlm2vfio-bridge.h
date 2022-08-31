/*
 * TLM to VFIO bridge.
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
#ifndef TLM2VFIO_BRIDGE_H__
#define TLM2VFIO_BRIDGE_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "tlm-extensions/genattr.h"
#include "utils/vfio/vfio-ll.h"
#include "utils/async_event.h"
#include "utils/dev-access.h"

/* Extend constructor with name to enable use of sc_vectors.  */
class tlm_mm_vfio_gp : public tlm::tlm_generic_payload
{
public:
	tlm_mm_vfio_gp(const char *name) {}
};

/*
 * MM with support for IOMMU mappings over VFIO.
 *
 */
class tlm_mm_vfio : public tlm::tlm_mm_interface
{
public:
	tlm_mm_vfio(int nr_gp, unsigned int size, class vfio_dev *dev)
		: dev(dev),
		  map_size(nr_gp * size * 2),
		  gp("gp", nr_gp)
	{
		int flags = MAP_SHARED | MAP_ANONYMOUS;
		uintptr_t map_uint;
		unsigned int i;
		void *m;

		// Some IOMMUs have a smaller address space than the CPU.
		// Use a 1:1 low-mem mapping.
		if (dev) {
#ifdef MAP_32BIT
			flags |= MAP_32BIT;
#else
			// FIXME: Can we ask the kernel for memory that works
			// for a given vfio-dev?
#endif
		}

		m = mmap(0, map_size * 2, PROT_READ | PROT_WRITE, flags, 0, 0);
		if (m == MAP_FAILED) {
			perror("tlm_mm_vfio");
			SC_REPORT_ERROR("tlm_mm_vfio", "mmap failure");
		}

		// Lock pages to allow direct DMA.
		if (dev) {
			mlock(m, map_size * 2);
		}

		map = (uint8_t *) m;
		map_uint = (uintptr_t) map;

		// For simulations, we allow this MM to be used without a
		// VFIO device. Without dev, we excersize the MM without
		// actually creating memory maps through IOMMU's.
		if (dev) {
			dev->iommu_map_dma(map_uint, map_uint, map_size * 2,
				VFIO_DMA_MAP_FLAG_READ | VFIO_DMA_MAP_FLAG_WRITE);
		}

		for (i = 0; i < gp.size(); i++) {
			gp[i].set_data_ptr(map + i * size);
			gp[i].set_byte_enable_ptr(map + nr_gp * size + i * size);
			gp[i].set_mm(this);
		}
	}

	~tlm_mm_vfio() {
		if (dev) {
			dev->iommu_unmap_dma((uintptr_t) map, map_size * 2,
				VFIO_DMA_MAP_FLAG_READ | VFIO_DMA_MAP_FLAG_WRITE);
		}
		munmap(map, map_size);
	}

	tlm::tlm_generic_payload *allocate(int desc_idx) {
		return &gp[desc_idx];
	}

	uint64_t to_dma(uint64_t offset) {
		return offset;
	}

	void free(tlm::tlm_generic_payload *tr) {
	}

private:
	vfio_dev *dev;
	uint8_t *map;
	uint64_t map_size;
	sc_vector<tlm_mm_vfio_gp > gp;
};

class tlm2vfio_bridge
: public sc_core::sc_module
{
public:
	sc_vector<tlm_utils::simple_target_socket<tlm2vfio_bridge> > tgt_socket;

	SC_HAS_PROCESS(tlm2vfio_bridge);
	tlm2vfio_bridge(sc_module_name name, int nr_sockets,
			class vfio_dev& dev,
			int region, uint64_t offset = 0,
			bool handle_irq = true);
	void irq_poll(void);

	// FIXME: How many lines should we expose?
	sc_out<bool > irq;

private:
	vfio_dev &dev;
	uint64_t offset;
	int region;
	async_event event;
	bool irq_val;
	pthread_t thread;
	static pthread_mutex_t mutex;
	static bool mutex_initiated;
	sc_signal<bool> irq_dummy;
	bool handle_irq;

	void irq_proxy(void);
	void irq_ack(void);

	virtual void b_transport(tlm::tlm_generic_payload& trans,
			sc_time& delay);
	virtual bool get_direct_mem_ptr(tlm::tlm_generic_payload& trans,
			tlm::tlm_dmi& dmi_data);

	void before_end_of_elaboration();
};

pthread_mutex_t tlm2vfio_bridge::mutex;
bool tlm2vfio_bridge::mutex_initiated = false;

static void *poll_trampoline(void *arg) {
	class tlm2vfio_bridge *b = (class tlm2vfio_bridge *)(arg);

	b->irq_poll();
	return NULL;
}

tlm2vfio_bridge::tlm2vfio_bridge(sc_module_name name,
		int nr_sockets,
		class vfio_dev& dev,
		int region, uint64_t offset,
		bool handle_irq) :
	sc_module(name),
	tgt_socket("tgt_socket", nr_sockets),
	irq("irq"),
	dev(dev),
	offset(offset),
	region(region),
	event("ev"),
	irq_val(false),
	irq_dummy("irq_dummy"),
	handle_irq(handle_irq)
{
	unsigned int i;

	for (i = 0; i < tgt_socket.size(); i++) {
		tgt_socket[i].register_b_transport(this,
				&tlm2vfio_bridge::b_transport);
		tgt_socket[i].register_get_direct_mem_ptr(this,
				&tlm2vfio_bridge::get_direct_mem_ptr);
	}

	if (!tlm2vfio_bridge::mutex_initiated) {
		pthread_mutex_init(&tlm2vfio_bridge::mutex, NULL);
		tlm2vfio_bridge::mutex_initiated = true;
	}

	if (handle_irq) {
		SC_THREAD(irq_proxy);
		pthread_create(&thread, NULL, poll_trampoline, this);
	}
}

void tlm2vfio_bridge::irq_proxy(void)
{
	while (true) {
		irq.write(irq_val);
		wait(event);
	}
}

void tlm2vfio_bridge::irq_ack(void)
{
	pthread_mutex_lock(&tlm2vfio_bridge::mutex);
	if (irq_val) {
		irq_val = 0;
		dev.unmask_irq(VFIO_PCI_INTX_IRQ_INDEX, 0);
		event.notify(SC_ZERO_TIME);
	}
	pthread_mutex_unlock(&tlm2vfio_bridge::mutex);
}

void tlm2vfio_bridge::irq_poll(void)
{
        while (true) {
		uint64_t c;
		ssize_t ret;

		dev.unmask_irq(VFIO_PCI_INTX_IRQ_INDEX, 0);
		do {
			ret = read(dev.efd_irq, (void *)&c, sizeof c);
			if (ret < 0) {
				printf("eventfd-irq: %s\n", strerror(errno));
				SC_REPORT_WARNING("tlm2vfio", "read-irq");
			}
			pthread_mutex_lock(&tlm2vfio_bridge::mutex);
			irq_val = true;
			event.notify();
			pthread_mutex_unlock(&tlm2vfio_bridge::mutex);
		} while (ret == sizeof c);
		SC_REPORT_WARNING("tlm2vfio", "read-irq");
        }
}

void tlm2vfio_bridge::b_transport(tlm::tlm_generic_payload& trans,
		sc_time& delay)
{
	sc_dt::uint64 addr = trans.get_address();
	unsigned char *data = trans.get_data_ptr();
	unsigned int len = trans.get_data_length();
	unsigned char *be = trans.get_byte_enable_ptr();
	unsigned int sw = trans.get_streaming_width();
	genattr_extension *genattr;
	bool is_write = !trans.is_read();
	uint8_t *map = (uint8_t *) dev.map[region];

	trans.get_extension(genattr);

	if (be) {
		trans.set_response_status(tlm::TLM_BYTE_ENABLE_ERROR_RESPONSE);
		return;
	}

	if (sw && sw < len) {
		trans.set_response_status(tlm::TLM_BURST_ERROR_RESPONSE);
		return;
	}

	addr += this->offset;

	if (addr + len > dev.map_size[region]) {
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
	}

	if (is_write) {
		memcpy_to_io(map + addr, data, len);
	} else {
		memcpy_from_io(data, map + addr, len);
	}

	// FIXME: We should be reading out some kind of counter from HW.
	wait(SC_ZERO_TIME);

	// Any access to the device is potentially ACK:ing interrupts.
	// We don't know which access, so we'll potentially be retriggering
	// multiple times per real IRQ.
	if (len < 8)
		irq_ack();

	trans.set_dmi_allowed(true);
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}

bool tlm2vfio_bridge::get_direct_mem_ptr(tlm::tlm_generic_payload& trans,
		tlm::tlm_dmi& dmi_data)
{
	dmi_data.allow_read_write();
	dmi_data.set_dmi_ptr((unsigned char*)dev.map[region]);
	dmi_data.set_start_address(0);
	dmi_data.set_end_address(dev.map_size[region] - 1);
	dmi_data.set_read_latency(SC_ZERO_TIME);
	dmi_data.set_write_latency(SC_ZERO_TIME);
	return true;
}

void tlm2vfio_bridge::before_end_of_elaboration()
{
	assert(tlm2vfio_bridge::mutex_initiated);

	if (!handle_irq) {
		irq(irq_dummy);
	}
}
#endif
