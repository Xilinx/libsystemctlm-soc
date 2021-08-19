/*
 * This is a small example showing howto connect an RTL PCIe Device
 * to a SystemC/TLM simulation using the TLM bridges.
 *
 * Copyright (c) 2020 Xilinx Inc.
 * Written by Edgar E. Iglesias
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

/*
 * A few things to be aware of when running these tests.
 *
 * The basic flow is that we use the master-bridge to directly copy data
 * between host memory and the BRAM. We use the CDMA to copy data from
 * the emulated TLM memory, via the slave-bridge into BRAM.
 *
 * The CDMA bridge cannot handle byte-enables since the CDMA doesn't have
 * a way to aribitrarily configure byte-enable buffers. So the write-strobe
 * features of the slave-bridge cannot be tested in this setup.
 *
 * For large transactions, that randomize with small streaming-widths, things
 * progress very slow since these transactions get chopped up into lots of
 * small individual CDMA transactions.
 *
 * When interrupting these tests, the state of the bridges may end up such
 * that interrupts are continously fired. The host linux kernel will not
 * appreciate constantly active interrupts with no handler for them so
 * it will eventually turn off the interrupt. If this happens, the tests
 * won't even start. In that case the VFIO bindings need to be reinitiated.
 *
 * Something like the following:
 * echo "1" >/sys/bus/pci/devices/0000\:17\:00.0/remove
 * echo "1" >/sys/bus/pci/rescan
 * sleep 1
 * echo 10ee 9031 > /sys/bus/pci/drivers/vfio-pci/new_id
 *
 */

#include <sstream>

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "tlm-modules/tlm-splitter.h"
#include "tlm-bridges/tlm2vfio-bridge.h"
#include "rtl-bridges/pcie-host/axi/tlm/tlm2axi-hw-bridge.h"
#include "rtl-bridges/pcie-host/axi/tlm/axi2tlm-hw-bridge.h"
#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "traffic-generators/random-traffic.h"

#include "test-modules/memory.h"
#include "test-modules/utils.h"

#undef D
#define D(x) do {               \
        if (0) {                \
                x;              \
        }                       \
} while (0)

#define RAM_SIZE (16 * 1024)

#define BASE_MASTER_BRIDGE     0x00000000
#define BASE_SLAVE_BRIDGE      0x00020000
#define BASE_BRAM              0xB0000000
#define BASE_CDMA              0xB0100000

class tlm2cdma_bridge : public sc_core::sc_module
{
public:
	tlm_utils::simple_target_socket<tlm2cdma_bridge> target_socket;
	tlm_utils::simple_initiator_socket<tlm2cdma_bridge> init_socket;
	sc_in<bool> rst;

	SC_HAS_PROCESS(tlm2cdma_bridge);
	tlm2cdma_bridge(sc_core::sc_module_name name,
			uint64_t base_cdma, uint64_t base_bram) :
		sc_module(name),
		target_socket("target_socket"),
		init_socket("init_socket"),
		rst("rst"),
		base_cdma(base_cdma),
		base_bram(base_bram)
	{
		target_socket.register_b_transport(this, &tlm2cdma_bridge::b_transport);

		SC_THREAD(reset_thread);
	}
private:
	uint64_t base_cdma;
	uint64_t base_bram;

	enum {
		R_CR            = 0x00,
		R_SR            = 0x04,
		R_SA            = 0x18,
		R_SA_MSB        = 0x1c,
		R_DA            = 0x20,
		R_DA_MSB        = 0x24,
		R_BTT           = 0x28,
	};

	enum {
		F_CR_RESET      = (1U << 2),
		F_SR_DMA_DECERR = (1U << 6),
		F_SR_DMA_SLVERR = (1U << 5),
		F_SR_DMA_INTERR = (1U << 4),
		F_SR_IDLE       = (1U << 1),
	};

	void dev_access(tlm::tlm_command cmd, uint64_t offset,
			void *buf, unsigned int len)
	{
		unsigned char *buf8 = (unsigned char *) buf;
		sc_time delay = SC_ZERO_TIME;
		tlm::tlm_generic_payload tr;

		tr.set_command(cmd);
		tr.set_address(offset);
		tr.set_data_ptr(buf8);
		tr.set_data_length(len);
		tr.set_streaming_width(len);
		tr.set_dmi_allowed(false);
		tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		init_socket->b_transport(tr, delay);
		assert(tr.get_response_status() == tlm::TLM_OK_RESPONSE);
	}

	uint32_t dev_read32(uint64_t offset)
	{
		uint32_t r;
		assert((offset & 3) == 0);
		dev_access(tlm::TLM_READ_COMMAND, offset, &r, sizeof(r));
		return r;
	}

	void dev_write32(uint64_t offset, uint32_t v)
	{
		uint32_t dummy;
		assert((offset & 3) == 0);
		dev_access(tlm::TLM_WRITE_COMMAND, offset, &v, sizeof(v));
		// Enforce PCI ordering.
	}

	void cdma_reset_ch(unsigned int offset)
	{
		uint32_t r_cr;

		// Reset the CDMA.
		D(printf("cdma: Reset ch %x\n", offset));
		r_cr = dev_read32(base_cdma + offset + R_CR);
		r_cr |= F_CR_RESET;
		dev_write32(base_cdma + offset + R_CR, r_cr);
		do {
			r_cr = dev_read32(base_cdma + offset + R_CR);
			D(printf("cdma: r_cr=%x\n", r_cr));
		} while (r_cr & F_CR_RESET);
		D(printf("cdma: Reset done\n"));
	}

	void cdma_reset(void)
	{
		cdma_reset_ch(0);
	}

	void reset_thread(void)
	{
		while (true) {
			wait(rst.negedge_event());

			// Wait until the TLM2VFIO bridge has reset.
			wait(SC_ZERO_TIME);
			cdma_reset();
		}
	}

	virtual void b_transport(tlm::tlm_generic_payload &trans, sc_time &delay) {
		uint64_t addr = trans.get_address();
		unsigned char *data = trans.get_data_ptr();
		unsigned char *be = trans.get_byte_enable_ptr();
		unsigned int len = trans.get_data_length();
		bool is_write = !trans.is_read();
		uint64_t sa, da;
		uint32_t r_sr;

		if (len > 16 * 1024) {
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
			return;
		}

		if (be) {
			// The CDMA bridge cannot propagate byte-enables.
			SC_REPORT_WARNING("cdma_bridge", "Cannot propagate byte-enables");
			trans.set_response_status(tlm::TLM_BYTE_ENABLE_ERROR_RESPONSE);
			return;
		}

		if (is_write) {
			// Copy the data to BRAM.
			trans.set_address(base_bram);
			init_socket->b_transport(trans, delay);
			assert(trans.get_response_status() == tlm::TLM_OK_RESPONSE);

			// Restore addr.
			trans.set_address(addr);

			sa = base_bram;
			da = addr;
		} else {
			sa = addr;
			da = base_bram;
		}

		// OK, now set up the DMA.
		D(printf("cdma: sa=%lx da=%lx len=%d\n", sa, da, len));
		cdma_reset();
		dev_write32(base_cdma + R_SA, sa);
		dev_write32(base_cdma + R_SA_MSB, sa >> 32);
		dev_write32(base_cdma + R_DA, da);
		dev_write32(base_cdma + R_DA_MSB, da >> 32);

		dev_write32(base_cdma + R_BTT, len);

		do {
			uint32_t err;

			r_sr = dev_read32(base_cdma + R_SR);
			err = r_sr & (F_SR_DMA_DECERR | F_SR_DMA_SLVERR | F_SR_DMA_INTERR);

			if (err) {
				printf("cdma: ERROR SR=%x DECERR=%d SLVERR=%d INTERR=%d\n",
					r_sr, err & F_SR_DMA_DECERR, err & F_SR_DMA_SLVERR,
					err & F_SR_DMA_INTERR);
				sc_stop();
			}
		} while (!(r_sr & F_SR_IDLE));

		if (!is_write) {
			// DATA is now in BRAM, copy it out.
			trans.set_address(base_bram);
			init_socket->b_transport(trans, delay);
			assert(trans.get_response_status() == tlm::TLM_OK_RESPONSE);

			// Restore addr.
			trans.set_address(addr);
		}

		D(printf("cdma: sa=%lx da=%lx len=%d SR=%x done\n", sa, da, len, r_sr));
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}
};

static void DoneCallback(TLMTrafficGenerator *gen, int threadId)
{
	sc_stop();
}

// Top simulation module.
SC_MODULE(Top)
{
	sc_signal<bool> rst; // Active high.
	sc_signal<bool> rst_n; // Active low.
	sc_signal<bool> irq;

	vfio_dev vdev;
	tlm2vfio_bridge tlm2vfio;
	tlm2axi_hw_bridge tlm_master_hw_bridge;
	axi2tlm_hw_bridge tlm_slave_hw_bridge;
	tlm2cdma_bridge cdma_bridge;
	tlm_aligner cdma_aligner;

	RandomTraffic *rand_xfers;
	tlm_splitter<2> splitter;
	TLMTrafficGenerator tg;

	memory ram;
	memory ref_ram;

	void pull_reset(void) {
		/* Pull the reset signal.  */
		rst.write(true);
		wait(4, SC_US);
		rst.write(false);
	}

	void gen_rst_n(void) {
		rst_n.write(!rst.read());
	}

	SC_HAS_PROCESS(Top);

	Top(sc_module_name name, unsigned int ram_size,
			const char *devname, int iommu_group) :
		sc_module(name),
		rst("rst"),
		rst_n("rst_n"),
		irq("irq"),
		vdev(devname, iommu_group),
		tlm2vfio("tlm2vfio_bridge", 2, vdev, 0),
		tlm_master_hw_bridge("tlm_master_hw_bridge", BASE_MASTER_BRIDGE, 0),
		tlm_slave_hw_bridge("tlm_slave_hw_bridge", BASE_SLAVE_BRIDGE, 0, &vdev),
		cdma_bridge("cdma_bridge", BASE_CDMA, BASE_BRAM),
		cdma_aligner("cdma_aligner", 128, 4 * 1024),
		splitter("splitter", true),
		tg("tg", 1),
		ram("ram", sc_time(1, SC_NS), ram_size),
		ref_ram("ref_ram", sc_time(1, SC_NS), ram_size)
	{
		SC_THREAD(pull_reset);
		SC_METHOD(gen_rst_n);
		sensitive << rst;

		rand_xfers = new RandomTraffic(0, ram_size - 8,
					~(uint64_t)0xf, 1, ram_size, 0, 1000);

		// Wire up the clock and reset signals.
		tlm_master_hw_bridge.rst(rst);
		tlm_slave_hw_bridge.rst(rst);
		cdma_bridge.rst(rst);

		rand_xfers->setInitMemory(true);
		rand_xfers->setMaxStreamingWidthLen(ram_size);

		tg.enableDebug();
		tg.addTransfers(*rand_xfers, 0, DoneCallback);
		tg.setStartDelay(sc_time(15, SC_US));

		tg.socket.bind(splitter.target_socket);
		splitter.i_sk[0]->bind(ref_ram.socket);
		splitter.i_sk[1]->bind(cdma_aligner.target_socket);
		cdma_aligner.init_socket(cdma_bridge.target_socket);

		cdma_bridge.init_socket(tlm_master_hw_bridge.tgt_socket);

		tlm_master_hw_bridge.bridge_socket(tlm2vfio.tgt_socket[0]);
		tlm_slave_hw_bridge.bridge_socket(tlm2vfio.tgt_socket[1]);
		tlm_slave_hw_bridge.init_socket(ram.socket);

		tlm_master_hw_bridge.irq(irq);
		tlm_slave_hw_bridge.irq(irq);
		tlm2vfio.irq(irq);
	}
};

int sc_main(int argc, char *argv[])
{
	sc_trace_file *trace_fp;
	int iommu_group;
	int bridge_idx;

	if (argc < 3) {
		printf("%s: device-name iommu-group\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	trace_fp = sc_create_vcd_trace_file(argv[0]);
	iommu_group = strtoull(argv[2], NULL, 10);
	Top top("Top", RAM_SIZE, argv[1], iommu_group);

	sc_start();

	if (trace_fp) {
		sc_close_vcd_trace_file(trace_fp);
	}
	return 0;
}
