/*
 * Model of the Xilinx MCDMA.
 *
 * TODO:
 *    * Fragmented packets on the RX path are not supported.
 *
 * Copyright (c) 2022 Advanced Micro Devices Inc.
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

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <inttypes.h>
#include <stdio.h>

#include "systemc.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm_utils/tlm_quantumkeeper.h"

using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm-extensions/genattr.h"
#include "utils/hexdump.h"
#include "utils/regapi.h"
#include "soc/dma/xilinx/mcdma/mcdma.h"

#define D(x)

#define CH_OFFSET(CH) (CH * 0x40 / sizeof(uint32_t))

#define MM2S_ALL_IRQ_MASK (R_MM2S_CH1SR_ERR_IRQ_MASK	\
	| R_MM2S_CH1SR_DLY_IRQ_MASK			\
	| R_MM2S_CH1SR_IOC_IRQ_MASK)

#define S2MM_ALL_IRQ_MASK (R_S2MM_CH1SR_ERR_IRQ_MASK	\
	| R_S2MM_CH1SR_DLY_IRQ_MASK			\
	| R_S2MM_CH1SR_IOC_IRQ_MASK)

xilinx_mcdma::xilinx_mcdma(sc_module_name name, int num_channels)
	: sc_module(name),
	  init_socket("init_socket"),
	  target_socket("target_socket"),
	  s2mm_stream_socket("s2mm_stream_socket", num_channels),
	  mm2s_stream_socket("mm2s_stream_socket", num_channels),
	  rst("rst"),
	  s2mm_irq("s2mm_irq"),
	  mm2s_irq("mm2s_irq"),
	  num_channels(num_channels),
	  rb("rb", mcdma_reginfo)
{
	int ch;

	for (ch = 0; ch < num_channels; ch++) {
		s2mm_stream_socket[ch].register_b_transport(this, &xilinx_mcdma::stream_b_transport, ch);
	}

	target_socket.register_b_transport(this, &xilinx_mcdma::b_transport);

	SC_METHOD(update_irqs);
	dont_initialize();
	sensitive << ev_update_irqs;

	SC_THREAD(reset_thread);
	SC_THREAD(dma_thread);
}

void xilinx_mcdma::reset_thread(void)
{
	while (true) {
		wait(rst.posedge_event());
		rb.reg_reset_all();
	}
}

// Interrupt propagation
void xilinx_mcdma::update_irqs(void)
{
	int ch;

	for (ch = 0; ch < num_channels; ch++) {
		uint32_t mm2s_isr = rb.regs[CH_OFFSET(ch) + R_MM2S_CH1SR] & MM2S_ALL_IRQ_MASK;
		uint32_t s2mm_isr = rb.regs[CH_OFFSET(ch) + R_S2MM_CH1SR] & S2MM_ALL_IRQ_MASK;
		uint32_t mm2s_mask = rb.regs[CH_OFFSET(ch) + R_MM2S_CH1CR] & MM2S_ALL_IRQ_MASK;
		uint32_t s2mm_mask = rb.regs[CH_OFFSET(ch) + R_S2MM_CH1CR] & S2MM_ALL_IRQ_MASK;

		bool mm2s_ch_irq = mm2s_isr & mm2s_mask;
		bool s2mm_ch_irq = s2mm_isr & s2mm_mask;

		rb.regs[R_MM2S_INTR_STATUS] &= ~(1U << ch);
		rb.regs[R_MM2S_INTR_STATUS] |= mm2s_ch_irq << ch;

		rb.regs[R_S2MM_INTR_STATUS] &= ~(1U << ch);
		rb.regs[R_S2MM_INTR_STATUS] |= s2mm_ch_irq << ch;
	}

	mm2s_irq.write(!!rb.regs[R_MM2S_INTR_STATUS]);
	s2mm_irq.write(!!rb.regs[R_S2MM_INTR_STATUS]);
}

void xilinx_mcdma::push_stream(int ch, unsigned char *buf, int len, bool eop)
{
	genattr_extension *genattr = new genattr_extension();
	tlm::tlm_generic_payload tr;
	sc_time delay = SC_ZERO_TIME;

	tr.set_command(tlm::TLM_WRITE_COMMAND);
	tr.set_address(0);
	tr.set_data_ptr(buf);
	tr.set_data_length(len);
	tr.set_streaming_width(len);
	tr.set_dmi_allowed(false);
	tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

	genattr->set_eop(eop);
	tr.set_extension(genattr);

	mm2s_stream_socket[ch]->b_transport(tr, delay);

	tr.release_extension(genattr);
}

void xilinx_mcdma::dma_access(tlm::tlm_command cmd, unsigned char *buf,
		uint64_t addr, int len)
{
	tlm::tlm_generic_payload tr;
	sc_time delay = SC_ZERO_TIME;

	tr.set_command(cmd);
	tr.set_address(addr);
	tr.set_data_ptr(buf);
	tr.set_data_length(len);
	tr.set_streaming_width(len);
	tr.set_dmi_allowed(false);
	tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

	init_socket->b_transport(tr, delay);
	if (tr.get_response_status() != tlm::TLM_OK_RESPONSE) {
		printf("%s:%d DMA transaction error!\n", __func__, __LINE__);
	}
}

void xilinx_mcdma::dma_load(unsigned char *buf, uint64_t addr, int len)
{
	dma_access(tlm::TLM_READ_COMMAND, buf, addr, len);
}

void xilinx_mcdma::dma_store(unsigned char *buf, uint64_t addr, int len)
{
	dma_access(tlm::TLM_WRITE_COMMAND, buf, addr, len);
}

void xilinx_mcdma::mm2s_desc_load(mm2s_bd *bd, uint64_t addr)
{
	dma_load(reinterpret_cast<unsigned char *> (bd), addr, sizeof *bd);
	D(printf("mm2s descr load: desc-addr=%lx next=%lx buffer=%lx ctrl=%x\n", addr, bd->next, bd->buffer, bd->ctrl));
}

void xilinx_mcdma::mm2s_desc_store(mm2s_bd *bd, uint64_t addr)
{
	dma_store(reinterpret_cast<unsigned char *> (bd), addr, sizeof *bd);
	D(printf("mm2s descr store: desc-addr=%lx next=%lx buffer=%lx ctrl=%x\n", addr, bd->next, bd->buffer, bd->ctrl));
}

void xilinx_mcdma::s2mm_desc_load(s2mm_bd *bd, uint64_t addr)
{
	dma_load(reinterpret_cast<unsigned char *> (bd), addr, sizeof *bd);
	D(printf("s2mm descr load: desc-addr=%lx next=%lx buffer=%lx ctrl=%x\n", addr, bd->next, bd->buffer, bd->ctrl));
}

void xilinx_mcdma::s2mm_desc_store(s2mm_bd *bd, uint64_t addr)
{
	dma_store(reinterpret_cast<unsigned char *> (bd), addr, sizeof *bd);
	D(printf("s2mm descr store: desc-addr=%lx next=%lx buffer=%lx ctrl=%x\n", addr, bd->next, bd->buffer, bd->ctrl));
}

uint64_t xilinx_mcdma::mm2s_cur(int ch) {
	uint64_t addr = rb.regs[CH_OFFSET(ch) + R_MM2S_CH1CURDESC_MSB];

	addr = (addr << 32) | rb.regs[CH_OFFSET(ch) + R_MM2S_CH1CURDESC_LSB];
	return addr;
}

uint64_t xilinx_mcdma::mm2s_tail(int ch) {
	uint64_t addr = rb.regs[CH_OFFSET(ch) + R_MM2S_CH1TAILDESC_MSB];

	addr = (addr << 32) | rb.regs[CH_OFFSET(ch) + R_MM2S_CH1TAILDESC_LSB];
	return addr;
}

uint64_t xilinx_mcdma::s2mm_cur(int ch) {
	uint64_t addr = rb.regs[CH_OFFSET(ch) + R_S2MM_CH1CURDESC_MSB];

	addr = (addr << 32) | rb.regs[CH_OFFSET(ch) + R_S2MM_CH1CURDESC_LSB];
	return addr;
}

uint64_t xilinx_mcdma::s2mm_tail(int ch) {
	uint64_t addr = rb.regs[CH_OFFSET(ch) + R_S2MM_CH1TAILDESC_MSB];

	addr = (addr << 32) | rb.regs[CH_OFFSET(ch) + R_S2MM_CH1TAILDESC_LSB];
	return addr;
}

void xilinx_mcdma::mm2s_set_idle(int ch, bool idle) {
	rb.regs[CH_OFFSET(ch) + R_MM2S_CH1SR] &= ~R_MM2S_CH1SR_IDLE_MASK;
	rb.regs[CH_OFFSET(ch) + R_MM2S_CH1SR] |= idle << R_MM2S_CH1SR_IDLE_SHIFT;
}

void xilinx_mcdma::s2mm_set_idle(int ch, bool idle) {
	rb.regs[CH_OFFSET(ch) + R_S2MM_CH1SR] &= ~R_S2MM_CH1SR_IDLE_MASK;
	rb.regs[CH_OFFSET(ch) + R_S2MM_CH1SR] |= idle << R_S2MM_CH1SR_IDLE_SHIFT;
}

void xilinx_mcdma::dma_thread(void)
{
	unsigned char buf[128 * 1024];

	while (true) {
		int num_running = 0;
		int ch;

		/* MM2S.  */
		for (ch = 0; ch < num_channels; ch++) {
			int ch_offset = CH_OFFSET(ch);
			bool tx_eof;
			unsigned int tmp;
			int len;
			mm2s_bd bd;

			if (!FIELD_EX(rb.regs[R_MM2S_CCR], MM2S_CCR, RS)) {
				D(printf("MM2S STOPPED\n"));
				continue;
			}

			if (!(rb.regs[R_MM2S_CHEN] & (1U << ch))) {
				D(printf("MM2S: ch%d DISABLED\n", ch));
				continue;
			}

			if (!FIELD_EX(rb.regs[ch_offset + R_MM2S_CH1CR], MM2S_CH1CR, RS)) {
				D(printf("MM2S: ch%d STOPPED\n", ch));
				continue;
			}

			if (FIELD_EX(rb.regs[ch_offset + R_MM2S_CH1SR], MM2S_CH1SR, IDLE)) {
				D(printf("MM2S: ch%d IDLE\n", ch));
				continue;
			}

			/* Process this channel.  */
			mm2s_desc_load(&bd, mm2s_cur(ch));
			if (bd.status & (1U << 31)) {
				mm2s_set_idle(ch, true);
				continue;
			}

			tx_eof = bd.ctrl & (1U << 30);
			len = bd.ctrl & bitops_mask64(0, 26);
			dma_load(buf, bd.buffer, len);

			D(printf("MM2S: ch%d: push-stream len=%d eof=%d\n", ch, len, tx_eof));
			D(hexdump("tx-pkt", buf, len));
			push_stream(ch, buf, len, tx_eof);

			bd.status |= 1U << 31;	/* Completed.  */
			bd.status |= len;
			mm2s_desc_store(&bd, mm2s_cur(ch));

			D(printf("MM2S: ch%d cur=%lx tail=%lx\n", ch, mm2s_cur(ch), mm2s_tail(ch)));
			if (mm2s_cur(ch) == mm2s_tail(ch)) {
				mm2s_set_idle(ch, true);
			}

			rb.regs[ch_offset + R_MM2S_CH1CURDESC_LSB] = bd.next;
			rb.regs[ch_offset + R_MM2S_CH1CURDESC_MSB] = bd.next >> 32;

			tmp = FIELD_EX(rb.regs[ch_offset + R_MM2S_CH1SR], MM2S_CH1SR, IRQ_THRESHOLD);
			D(printf("MM2S: IRQ threshold = %x\n", tmp));
			if (tmp == 0 || 1) {
				tmp = FIELD_EX(rb.regs[ch_offset + R_MM2S_CH1CR], MM2S_CH1CR, IRQ_THRESHOLD);
				rb.regs[ch_offset + R_MM2S_CH1SR] |= R_MM2S_CH1SR_IOC_IRQ_MASK;
			} else {
				tmp--;
			}
			FIELD_DP(rb, rb.regs[ch_offset + R_MM2S_CH1SR], MM2S_CH1SR, IRQ_THRESHOLD, tmp);
			D(printf("MM2S: SR=%x tmp=%x\n", rb.regs[ch_offset + R_MM2S_CH1SR], tmp));

			ev_update_irqs.notify();
			num_running++;
		}

		if (!num_running) {
			wait(ev_dma);
		}
	}
}

void xilinx_mcdma::stream_b_transport(int ch, tlm::tlm_generic_payload& trans, sc_time& delay)
{
	unsigned char *buf = trans.get_data_ptr();
	int len = trans.get_data_length();
	int ch_offset = CH_OFFSET(ch);
	unsigned int tmp;
	int pos = 0;
	int bdlen;
	s2mm_bd bd;

	D(printf("Got packet on ch=%d\n", ch));

	while (pos < len) {
		if (!FIELD_EX(rb.regs[R_S2MM_CCR], S2MM_CCR, RS)) {
			D(printf("S2MM STOPPED\n"));
			goto drop;
		}

		if (!(rb.regs[R_S2MM_CHEN] & (1U << ch))) {
			D(printf("S2MM: ch%d DISABLED\n", ch));
			goto drop;
		}

		if (!FIELD_EX(rb.regs[ch_offset + R_S2MM_CH1CR], S2MM_CH1CR, RS)) {
			D(printf("S2MM: ch%d STOPPED\n", ch));
			goto drop;
		}

		if (FIELD_EX(rb.regs[ch_offset + R_S2MM_CH1SR], S2MM_CH1SR, IDLE)) {
			D(printf("S2MM: ch%d IDLE\n", ch));
			goto drop;
		}

		/* Process this channel.  */
		s2mm_desc_load(&bd, s2mm_cur(ch));
		bdlen = bd.ctrl & bitops_mask64(0, 26);
		assert(bdlen >= len);
		dma_store(buf + pos, bd.buffer, len - pos);

		if (bd.status & (1U << 31)) {
			s2mm_set_idle(ch, true);
			goto drop;
		}

		bd.status = 1U << 31;	/* Completed.  */
		bd.status |= 1U << 27;	/* SOF.  */
		bd.status |= 1U << 26;	/* EOF.  */
		bd.status |= len;
		D(printf("S2MM: cur=%lx bd.buffer=%lx bdlen=%d len=%d status=%x offsetof-status=%ld\n",
			 s2mm_cur(ch), bd.buffer, bdlen, len, bd.status, offsetof(typeof(bd), status)));
		D(hexdump("rx-pkt", buf + pos, len - pos));
		s2mm_desc_store(&bd, s2mm_cur(ch));

		D(printf("S2MM: ch%d cur=%lx tail=%lx\n", ch, s2mm_cur(ch), s2mm_tail(ch)));
		if (s2mm_cur(ch) == s2mm_tail(ch)) {
			s2mm_set_idle(ch, true);
		}

		rb.regs[ch_offset + R_S2MM_CH1CURDESC_LSB] = bd.next;
		rb.regs[ch_offset + R_S2MM_CH1CURDESC_MSB] = bd.next >> 32;

		tmp = FIELD_EX(rb.regs[ch_offset + R_S2MM_CH1SR], S2MM_CH1SR, IRQ_THRESHOLD);
		D(printf("S2MM: RX: IRQ threshold = %x\n", tmp));
		if (tmp == 0 || 1) {
			tmp = FIELD_EX(rb.regs[ch_offset + R_S2MM_CH1CR], S2MM_CH1CR, IRQ_THRESHOLD);
			rb.regs[ch_offset + R_S2MM_CH1SR] |= R_S2MM_CH1SR_IOC_IRQ_MASK;
		} else {
			tmp--;
		}
		FIELD_DP(rb, rb.regs[ch_offset + R_S2MM_CH1SR], S2MM_CH1SR, IRQ_THRESHOLD, tmp);
		D(printf("S2MM: SR=%x tmp=%x\n", rb.regs[ch_offset + R_S2MM_CH1SR], tmp));

		ev_update_irqs.notify();
		pos += len;
	}

	trans.set_response_status(tlm::TLM_OK_RESPONSE);
	return;

drop:
	printf("Dropped\n");
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}

void xilinx_mcdma::b_transport(tlm::tlm_generic_payload& trans, sc_time& delay)
{
	uint64_t addr = trans.get_address();
	bool is_read = trans.is_read();
	unsigned int regindex;
	int ch, ch_offset;

	regindex = addr / sizeof(uint32_t);

	if (is_read) {
		rb.reg_b_transport(trans, delay);
	} else {
		switch (regindex) {
		case R_MM2S_CH1CR...R_MM2S_CH15PKTCOUNT_STAT:
			ch = (regindex - R_MM2S_CH1CR) / (0x40 / 4);
			ch_offset = CH_OFFSET(ch);

			rb.reg_b_transport(trans, delay);

			switch (regindex - ch_offset) {
			case R_MM2S_CH1TAILDESC_MSB:
				if (FIELD_EX(rb.regs[ch_offset + R_MM2S_CH1CR], MM2S_CH1CR, RS)) {
					/* Unpause.  */
					mm2s_set_idle(ch, false);
					ev_dma.notify();
				}
				break;
			}
			break;
		default:
			rb.reg_b_transport(trans, delay);
			break;
		}
	}

	ev_update_irqs.notify();
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}
