/*
 * QDMA testsuite.
 *
 * Copyright (c) 2022 Advanced Micro Devices Inc.
 * Written by Fred Konrad
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

#include <systemc>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
#include "soc/pci/xilinx/qdma.h"

#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "tests/test-modules/utils.h"

using namespace sc_core;
using namespace sc_dt;
using namespace utils;

#define SWAP(a, b, c, d) d, c, b, a

static void Done_Callback(TLMTrafficGenerator *gen, int threadId);

typedef struct {
  const char *name;
  TrafficDesc traffic;
} QDMATest;

/* TEST1: This checks the following registers value:
          CONFIG_BLOCK_IDENT @0x00000000 should be 0x1FD30001.
	  GLBL2_MISC_CAP     @0x00000134 should be 0x21000000.

   Note that the second register can change depending on the IP version or
   whether it's a soft IP or an Hard IP.  Let's stick to the Versal CPM5
   Hard IP.  Also make sure those registers are read-only.  */
QDMATest Test1 = {"Test1: Identification and IP version registers.",
		  merge({
		     Write(0x00000000, DATA(0xDE, 0xAD, 0xBE, 0xEF)),
		     Read(0x0), Expect(DATA(SWAP(0x1F, 0xD3, 0x0, 0x01)), 4),
		     Write(0x00000134, DATA(0xDE, 0xAD, 0xBE, 0xEF)),
		     Read(0x134), Expect(DATA(SWAP(0x21, 0x00, 0x00, 0x00)), 4),
		  })};

static std::vector<QDMATest *> tests({ &Test1 });

/* This device connects to the QDMA, generate the configuration on the configs
   socket, check that the correct DMA transaction are happening.  */
SC_MODULE(TestDevice)
{
public:
	SC_HAS_PROCESS(TestDevice);

	/* DMA socket for the descriptors fetches / writeback or data R/W from
	 * the QDMA.  */
	tlm_utils::simple_target_socket<TestDevice> dma_socket;

	/* Traffic generators to BARs.  */
	TLMTrafficGenerator tg_config;
	TLMTrafficGenerator tg_user;

	/* IRQ / MSI-X.  */
	sc_vector<sc_signal<bool> > signals_irq;

	/* Card side target socket, txn from this socket are supposed to reach
	 * the board.  */
	tlm_utils::simple_target_socket<TestDevice> card_socket;

	unsigned int m_testIdx;

	TestDevice(sc_module_name name):
		sc_module(name),
		dma_socket("dma"),
		tg_config("tg-config"),
		tg_user("tg-user"),
		signals_irq("irqs", NR_QDMA_IRQ),
		card_socket("card"),
		m_testIdx(0)
	{
		dma_socket.register_b_transport(this,
				&TestDevice::dma_b_transport);

		tg_config.enableDebug();
		tg_config.setStartDelay(sc_time(10, SC_US));
		tg_config.addTransfers(tests[m_testIdx]->traffic,
					0, Done_Callback);
	}

	/* Bind the QDMA to the TestDevice.  */
	void bind(qdma_cpm5 &qdma)
	{
		tg_config.socket.bind(qdma.config_bar);
		tg_user.socket.bind(qdma.user_bar);

		qdma.dma.bind(dma_socket);
		qdma.card_bus.bind(card_socket);

		for (int i=0; i < NR_QDMA_IRQ; i++) {
			qdma.irq[i](this->signals_irq[i]);
		}
	}

	private:
	void dma_b_transport(tlm::tlm_generic_payload &trans, sc_time &delay)
	{
		/* For now there isn't any test requiring DMA. So this is an
		 * error.  */
		SC_REPORT_WARNING("qdma", "Unexpected DMA transaction");
	}

public:
	void test_loop(TLMTrafficGenerator *gen, int threadId)
	{
		assert(tests[m_testIdx]->traffic.done());
		cout << endl << " * " << tests[m_testIdx]->name << ": done!" << endl;
		m_testIdx++;

		if (m_testIdx < tests.size()) {
			tg_config.addTransfers(tests[m_testIdx]->traffic,
						0, Done_Callback);
		} else {
			sc_stop();
		}
	}
};

TestDevice *glob_qdma_tester = NULL;

static void Done_Callback(TLMTrafficGenerator *gen, int threadId)
{
	assert(glob_qdma_tester);
	glob_qdma_tester->test_loop(gen, threadId);
}

SC_MODULE(Top)
{
public:
	SC_HAS_PROCESS(Top);

	qdma_cpm5 qdma;
	TestDevice test;
	sc_signal<bool> rst;

	Top(sc_module_name name) :
		sc_module(name),
		qdma("qdma-device"),
		test("qdma-tester")
	{
		test.bind(qdma);
		glob_qdma_tester = &this->test;

		qdma.rst(rst);
		SC_THREAD(pull_reset);
	}

	void pull_reset(void) {
		/* Pull the reset signal.  */
		rst.write(true);
		wait(1, SC_US);
		rst.write(false);
	}
};

int sc_main(int argc, char *argv[])
{
	Top top("Top");

	sc_start();

	return 0;
}
