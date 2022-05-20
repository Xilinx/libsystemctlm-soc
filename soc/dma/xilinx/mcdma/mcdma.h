/*
 * Copyright (c) 2022 Advanced Micro Devices Inc.
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

#include "tlm-extensions/genattr.h"
#include "utils/regapi.h"
#include "regs-mcdma.h"

class mm2s_bd {
public:
	uint64_t next;
	uint64_t buffer;
	uint32_t rsvd;
	uint32_t ctrl;
	uint32_t ctrl_side;
	uint32_t status;
	uint32_t app[5];
} __attribute__ ((packed));

class s2mm_bd {
public:
	uint64_t next;
	uint64_t buffer;
	uint32_t rsvd;
	uint32_t ctrl;
	uint32_t status;
	uint32_t status_side;
	uint32_t app[5];
} __attribute__ ((packed));

class xilinx_mcdma
: public sc_core::sc_module
{
	SC_HAS_PROCESS(xilinx_mcdma);
public:
	tlm_utils::simple_initiator_socket<xilinx_mcdma> init_socket;
	tlm_utils::simple_target_socket<xilinx_mcdma> target_socket;
	sc_vector<tlm_utils::simple_target_socket_tagged<xilinx_mcdma> > s2mm_stream_socket;
	sc_vector<tlm_utils::simple_initiator_socket<xilinx_mcdma> > mm2s_stream_socket;

	sc_in<bool> rst;
	sc_out<bool> s2mm_irq;
	sc_out<bool> mm2s_irq;
	xilinx_mcdma(sc_core::sc_module_name name, int num_channels = 16);
private:
	int num_channels;
	sc_event ev_dma;
	sc_event ev_update_irqs;

	regapi_block<uint32_t, R_S2MM_Channel_Observer_6 + 1 > rb;

	void reset_thread(void);
	void dma_thread(void);
	void update_irqs(void);
	uint64_t mm2s_cur(int ch);
	uint64_t mm2s_tail(int ch);
	uint64_t s2mm_cur(int ch);
	uint64_t s2mm_tail(int ch);
	void mm2s_set_idle(int ch, bool idle);
	void s2mm_set_idle(int ch, bool idle);
	void push_stream(int ch, unsigned char *buf, int len, bool eop);
	void dma_access(tlm::tlm_command cmd, unsigned char *buf, uint64_t addr, int len);
	void dma_load(unsigned char *buf, uint64_t addr, int len);
	void dma_store(unsigned char *buf, uint64_t addr, int len);

	void mm2s_desc_load(mm2s_bd *bd, uint64_t addr);
	void mm2s_desc_store(mm2s_bd *bd, uint64_t addr);
	void s2mm_desc_load(s2mm_bd *bd, uint64_t addr);
	void s2mm_desc_store(s2mm_bd *bd, uint64_t addr);
	virtual void stream_b_transport(int id, tlm::tlm_generic_payload& trans, sc_time& delay);
	virtual void b_transport(tlm::tlm_generic_payload& trans, sc_time& delay);
};
