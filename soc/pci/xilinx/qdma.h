/*
 * This models the QDMA.
 *
 * Copyright (c) 2022 Xilinx Inc.
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

#ifndef __PCI_QDMA_H__
#define __PCI_QDMA_H__

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc.h"
#include "tlm.h"
#include "soc/pci/core/pci-device-base.h"

#define NR_QDMA_IRQ       8

/*
 * IP configuration:
 *
 * QDMA_SOFT_IP: The IP is a soft IP.
 */
//#define QDMA_SOFT_IP

#ifdef QDMA_SOFT_IP
#define QDMA_DEVICE_ID 0
/*
 * 0: QDMA
 * 1: EQDMA
 */
#define QDMA_VERSAL_IP 0
/*
 * For QDMA:
 *   0: 2018_3
 *   1: 2019_1
 *   2: 2019_2
 *
 * For EQDMA:
 *   0: 2020_1
 *   1: 2020_2
 */
#define QDMA_VIVADO_REL 1
#define QDMA_HAS_MAILBOX ((QDMA_VERSAL_IP != 0) || (QDMA_VIVADO_REL != 0))
#else
/*
 * DEVICE_ID:
 *   0: Soft Device.
 *   1: Versal CPM4.
 *   2: Versal CPM5.
 */
#define QDMA_DEVICE_ID 2

/*
 * QDMA_VERSAL_IP:
 *   0: Versal Hard IP.
 *   1: Versal Soft IP.
 */
#define QDMA_VERSAL_IP 0

/*
 * For CPM4:
 *   0: 2019_2
 * For CPM5:
 *   0: 2021_1
 *   1: 2022_1
 */
#define QDMA_VIVADO_REL 1

/* No mailboxes for the CPM4 IP. */
#define QDMA_HAS_MAILBOX (DEVICE_ID != 1)
#endif

/*
 * Config of the QDMA_GLBL2_MISC_CAP register @0x134.
 * Device ID:   31 .. 28
 * Vivado Rel:  27 .. 24
 * Versal IP:   23 .. 20
 * RTL Version: 19 .. 16
 */
#define QDMA_VERSION (QDMA_DEVICE_ID << 28 ) + (QDMA_VIVADO_REL << 24) + \
  (QDMA_VERSAL_IP << 20)

/* Number of queue, as described in the QDMA_GLBL2_CHANNEL_QDMA_CAP register
   @0x120.  */
#define QDMA_QUEUE_COUNT 2

#define QDMA_INTR_RING_ENTRY_ADDR(x) (x << 12)
#define QDMA_INTR_RING_ENTRY_SZ 8

/* Context implementation: actually there are less than 15 contexts since the
   fifth one is reserved.  */
#define QDMA_MAX_CONTEXT_SELECTOR 15
#define QDMA_U32_PER_CONTEXT 8

/* This is the bar ID for the user bar.  */
#define QDMA_USER_BAR_ID 2

/* Max size for descriptors in bytes.  */
#define QDMA_DESC_MAX_SIZE 64

/* PCIE Physical Function register offsets.  */
#define R_CONFIG_BLOCK_IDENT       (0x0 >> 2)
#define R_GLBL2_PF_BARLITE_INT     (0x104 >> 2)
#define R_GLBL2_PF_BARLITE_EXT     (0x10C >> 2)
#define R_GLBL2_CHANNEL_MDMA       (0x118 >> 2)
#define R_GLBL2_CHANNEL_QDMA_CAP   (0x120 >> 2)
#define R_GLBL2_CHANNEL_FUNC_RET   (0x12C >> 2)
#define R_GLBL2_MISC_CAP           (0x134 >> 2)
#define R_GLBL_INTR_CFG            (0x2c4 >> 2)
#define R_GLBL_INTR_CFG_INT_PEND   (1UL << 1)
#define R_GLBL_INTR_CFG_INT_EN     (1UL << 0)
#define R_IND_CTXT_DATA            (0x804 >> 2)
#define R_IND_CTXT_CMD             (0x844 >> 2)
#define R_DMAP_SEL_INT_CIDX(n)     ((0x18000 + (0x10 * n)) >> 2)
#define R_DMAP_SEL_H2C_DSC_PIDX(n) ((0x18004 + (0x10 * n)) >> 2)
#define R_DMAP_SEL_C2H_DSC_PIDX(n) ((0x18008 + (0x10 * n)) >> 2)
#define R_DMAP_SEL_CMPT_CIDX(n)    ((0x1800C + (0x10 * n)) >> 2)

/* About MSIX Vector mapping:
 *
 * For Versal HARD IP:
 * 0 - User Vector (1 but # might be configurable)
 * 1 - Error Vector
 * 2 - Data Vector
 *
 * For SOFT IP:
 * 0 - MailBox Vector (for IP >= 2019_1 only)
 * 1 - User Vector (1 but # might be configurable)
 * 2 - Error Vector
 * 3 - Data Vector
 */
#if QDMA_HAS_MAILBOX
#define QDMA_PF0_FIRST_DATA_MSIX_VECTOR (3)
#else
#define QDMA_PF0_FIRST_DATA_MSIX_VECTOR (2)
#endif

class qdma_cpm5 : public sc_module
{
private:
	/* Context handling.  */

	/* The per queue SW contexts.  */
	struct __attribute__((__packed__)) sw_ctx {
		/* Producer index.  */
		uint16_t pidx;
		/* The queue is allowed to raise an IRQ.  */
		uint16_t irq_arm : 1;
		uint16_t fn_id : 12;
		uint16_t rsv : 3;
		/* Queue is enabled.  */
		uint16_t enabled : 1;
		uint16_t fcrd_en : 1;
		uint16_t wbi_chk : 1;
		uint16_t wbi_int_en : 1;
		uint16_t at : 1;
		uint16_t fetch_max : 4;
		uint16_t reserved2 : 3;
		/* Number of the descriptor for this context.  */
		uint16_t ring_size : 4;
		/* desc_size: 0: 8 bytes ... 3: 64 bytes.  */
		uint16_t desc_size : 2;
		uint16_t bypass : 1;
		/* 0.  */
		uint16_t mm_chan : 1;
		/* Write to the status descriptor upon status update.  */
		uint16_t writeback_en : 1;
		/* Send an irq upon status update.  */
		uint16_t irq_enabled : 1;
		uint16_t port_id : 3;
		uint16_t irq_no_last : 1;
		uint16_t err : 2;
		uint16_t err_wb_sent : 1;
		uint16_t irq_req : 1;
		uint16_t mrkr : 1;
		uint16_t is_mm : 1;
		/* Descriptor base address, descriptor for CIDX will be at
		 * BASE + CIDX.  */
		uint32_t desc_base_low;
		uint32_t desc_base_high;
		/* MSI-X vector index.  */
		uint16_t msix_vector : 11;
		uint16_t int_aggr : 1;
		uint16_t dis_intr_on_vf : 1;
		uint16_t virtio_en : 1;
		uint16_t pack_byp_out : 1;
		uint16_t irq_byp : 1;
		uint16_t host_id : 4;
		uint16_t pasid_low : 12;
		uint16_t pasid_high : 10;
		uint16_t pasid_en : 1;
		uint16_t virtio_desc_base_low : 12;
		uint32_t virtio_desc_base_med;
		uint16_t virtio_desc_base_high : 11;
	};

	/* The per queue HW contexts.  */
	struct __attribute__((__packed__)) hw_ctx {
		/* CIDX of the last fetched descriptor.  */
		uint16_t hw_cidx;
		/* Credit consumed.  */
		uint16_t credit_used;
		uint8_t rsvd;
		/* CIDX != PIDX.  */
		uint8_t desc_pending : 1;
		uint8_t invalid_desc : 1;
		uint8_t event_pending : 1;
		uint8_t desc_fetch_pending : 4;
		uint8_t rsvd2 : 1;
	};

	/* Interrupt Aggregation.  */

	/* Interrupt contexts.  */
	struct __attribute__((__packed__)) intr_ctx {
		uint32_t valid : 1;
		uint32_t vector : 11;
		uint32_t rsvd : 1;
		uint32_t status : 1;
		uint32_t color : 1;
		uint64_t baddr : 52;
		uint32_t page_size : 3;
		uint32_t pidx : 12;
		uint32_t at : 1;
		uint32_t host_id : 4;
		uint32_t pasid : 22;
		uint32_t pasid_en : 1;
		uint32_t rsvd2 : 4;
		uint32_t func : 12;
	};

	/* Interrupt entry as written in the ring.  */
	struct __attribute__((__packed__)) intr_ring_entry {
		uint16_t pidx : 16;
		uint16_t cidx : 16;
		uint16_t color : 1;
		uint16_t interrupt_state : 2;
		uint16_t error : 2;
		uint32_t rsvd : 1;
		uint32_t interrupt_type : 1;
		uint32_t qid : 24;
		uint32_t coal_color : 1;
	};

	struct {
		uint32_t data[QDMA_U32_PER_CONTEXT];
	} queue_contexts[QDMA_QUEUE_COUNT][QDMA_MAX_CONTEXT_SELECTOR];

	/* Current index in the interrupt ring.  */
	int irq_ring_idx[QDMA_QUEUE_COUNT];

	/* Context commands.  */
	enum {
		QDMA_CTXT_CMD_CLR = 0,
		QDMA_CTXT_CMD_WR = 1,
		QDMA_CTXT_CMD_RD = 2,
		QDMA_CTXT_CMD_INV = 3
	};

	/* Context selectors.  */
	enum {
		QDMA_CTXT_SELC_DEC_SW_C2H = 0,
		QDMA_CTXT_SELC_DEC_SW_H2C = 1,
		QDMA_CTXT_SELC_DEC_HW_C2H = 2,
		QDMA_CTXT_SELC_DEC_HW_H2C = 3,
		QDMA_CTXT_SELC_DEC_CR_C2H = 4,
		QDMA_CTXT_SELC_DEC_CR_H2C = 5,
		/* Write Back, also called completion queue.  */
		QDMA_CTXT_SELC_WRB = 6,
		QDMA_CTXT_SELC_PFTCH = 7,
		/* Interrupt context.  */
		QDMA_CTXT_SELC_INT_COAL = 8,
		QDMA_CTXT_SELC_HOST_PROFILE = 0xA,
		QDMA_CTXT_SELC_TIMER = 0xB,
		QDMA_CTXT_SELC_FMAP = 0xC,
		QDMA_CTXT_SELC_FNC_STS = 0xD,
	};

	void handle_ctxt_cmd(uint32_t reg) {
		uint32_t qid = (reg >> 7) & 0x1FFF;
		uint32_t cmd = (reg >> 5) & 0x3;
		uint32_t sel = (reg >> 1) & 0xF;
		uint32_t *data;

		if (sel == QDMA_CTXT_SELC_INT_COAL) {
			/* This one requires some special treatment.  */
			this->handle_irq_ctxt_cmd(qid, cmd);
			return;
		}

		/* Find the context data.  */
		assert(qid < QDMA_QUEUE_COUNT);
		switch (sel) {
			case QDMA_CTXT_SELC_FMAP:
			case QDMA_CTXT_SELC_PFTCH:
			case QDMA_CTXT_SELC_WRB:
			case QDMA_CTXT_SELC_DEC_CR_H2C:
			case QDMA_CTXT_SELC_DEC_CR_C2H:
			case QDMA_CTXT_SELC_DEC_HW_H2C:
			case QDMA_CTXT_SELC_DEC_HW_C2H:
			case QDMA_CTXT_SELC_DEC_SW_H2C:
			case QDMA_CTXT_SELC_DEC_SW_C2H:
				data = this->queue_contexts[qid][sel].data;
				break;
			default:
				SC_REPORT_ERROR("qdma", "Unsupported selector");
				return;
			case QDMA_CTXT_SELC_INT_COAL:
				/* Handled elsewere.  */
				abort();
				return;
		}

		switch (cmd) {
			case QDMA_CTXT_CMD_CLR:
				memset(data, 0, QDMA_U32_PER_CONTEXT * 4);
				break;
			case QDMA_CTXT_CMD_WR:
				memcpy(data, &this->regs.u32[R_IND_CTXT_DATA],
						QDMA_U32_PER_CONTEXT * 4);
				break;
			case QDMA_CTXT_CMD_RD:
				memcpy(&this->regs.u32[R_IND_CTXT_DATA], data,
						QDMA_U32_PER_CONTEXT * 4);
				break;
			case QDMA_CTXT_CMD_INV:
				break;
			default:
				SC_REPORT_ERROR("qdma", "Unsupported command");
				break;
		}
	}

	/* This one diserve a special treatment, because it has some side
	 * effects.  */
	void handle_irq_ctxt_cmd(uint32_t qid, uint32_t cmd) {
		struct intr_ctx *intr_ctx =
			(struct intr_ctx *)this->queue_contexts[qid]
						[QDMA_CTXT_SELC_INT_COAL].data;

		switch (cmd) {
			case QDMA_CTXT_CMD_CLR:
				memset(intr_ctx, 0, QDMA_U32_PER_CONTEXT * 4);
				break;
			case QDMA_CTXT_CMD_RD:
				memcpy(&this->regs.u32[R_IND_CTXT_DATA],
						intr_ctx,
						QDMA_U32_PER_CONTEXT * 4);
				break;
			case QDMA_CTXT_CMD_WR:
				{
					bool valid = intr_ctx->valid;

					memcpy(intr_ctx,
						&this->regs.u32[R_IND_CTXT_DATA],
						QDMA_U32_PER_CONTEXT * 4);
					if (intr_ctx->valid && !valid) {
						/* Interrupt context validated,
						 * reset the ring index.  */
						this->irq_ring_idx[qid] = 0;
					}
				}
				break;
			case QDMA_CTXT_CMD_INV:
				/* Drop the valid bit.  */
				intr_ctx->valid = 0;
				break;
			default:
				break;
		}
	}

	/* Descriptors: for h2c and c2h memory mapped transfer.  */
	struct x2c_mm_descriptor {
		uint64_t src_address : 64;
		uint64_t byte_count : 28;
		uint64_t rsvd0 : 36;
		uint64_t dst_address : 64;
		uint64_t rsvd1 : 64;
	};

	/* Status descriptor, written by the DMA at the end of the transfer.  */
	struct x2c_wb_descriptor {
		/* 0 No errors, 1: DMA error, 2: Descriptor fetch error.  */
		uint16_t err : 2;
		uint16_t rsvd0 : 14;
		uint16_t cidx : 16;
		uint16_t pidx : 16;
		uint16_t rsvd1 : 16;
	};

	/* Transfer data from the Host 2 the Card (h2c = true),
	   Card 2 Host (h2c = false).  */
	int do_mm_dma(uint64_t src_addr, uint64_t dst_addr, uint64_t size,
			bool h2c)
	{
		uint64_t i;
		sc_time delay(SC_ZERO_TIME);
		struct {
			tlm::tlm_generic_payload trans;
			const char *name;
		} trans_ext[2];
		uint32_t data;

		trans_ext[0].trans.set_command(tlm::TLM_READ_COMMAND);
		trans_ext[0].trans.set_data_ptr((unsigned char *)&data);
		trans_ext[0].trans.set_streaming_width(4);
		trans_ext[0].trans.set_data_length(4);

		trans_ext[1].trans.set_command(tlm::TLM_WRITE_COMMAND);
		trans_ext[1].trans.set_data_ptr((unsigned char *)&data);
		trans_ext[1].trans.set_streaming_width(4);
		trans_ext[1].trans.set_data_length(4);

		for (i = 0; i < size; i+=4) {
			trans_ext[0].trans.set_address(src_addr);
			trans_ext[1].trans.set_address(dst_addr);
			src_addr += 4;
			dst_addr += 4;

			if (h2c) {
				this->dma->b_transport(
					trans_ext[0].trans, delay);
			} else {
				this->card_bus->b_transport(
					trans_ext[0].trans, delay);
			}

			if (trans_ext[0].trans.get_response_status() !=
				tlm::TLM_OK_RESPONSE) {
				SC_REPORT_ERROR("qdma",
					"error while fetching the data");
				return -1;
			}

			if (h2c) {
				this->card_bus->b_transport(
					trans_ext[1].trans, delay);
			} else {
				this->dma->b_transport(
					trans_ext[1].trans, delay);
			}

			if (trans_ext[1].trans.get_response_status() !=
				tlm::TLM_OK_RESPONSE) {
				SC_REPORT_ERROR("qdma",
					"error while pushing the data");
				return -1;
			}
		}

		return 0;
	}

	/* The driver wrote the @pidx in the update register of the given qid.
	   Handle the request.  */
	void run_mm_dma(int16_t qid, bool h2c)
	{
		struct sw_ctx *sw_ctx;
		struct hw_ctx *hw_ctx;
		struct intr_ctx *intr_ctx;
		uint16_t pidx;
		uint8_t desc[QDMA_DESC_MAX_SIZE];
		int desc_size;
		uint32_t ring_sizes[16] = {
			2048, 64, 128, 192, 256, 384, 512, 768, 1024,
			1536, 3072, 4096, 6144, 8192, 12288, 16384 };
		uint32_t ring_size;
		struct x2c_mm_descriptor *pdesc =
				(struct x2c_mm_descriptor *)desc;
		struct x2c_wb_descriptor *pstatus =
				(struct x2c_wb_descriptor *) desc;

		if (qid > QDMA_QUEUE_COUNT) {
			SC_REPORT_ERROR("qdma", "invalid queue ID");
			return;
		}

		/* Compute some useful information from the context.  */
		sw_ctx =
			(struct sw_ctx *)this->queue_contexts[qid]
			[h2c ? QDMA_CTXT_SELC_DEC_SW_H2C :
				QDMA_CTXT_SELC_DEC_SW_C2H].data;
		hw_ctx =
			(struct hw_ctx *)this->queue_contexts[qid]
			[h2c ? QDMA_CTXT_SELC_DEC_HW_H2C :
				QDMA_CTXT_SELC_DEC_HW_C2H].data;
		intr_ctx =
			(struct intr_ctx *)this->queue_contexts[qid]
			[QDMA_CTXT_SELC_INT_COAL].data;
		pidx = this->regs.u32
			[h2c ? R_DMAP_SEL_H2C_DSC_PIDX(qid) :
				R_DMAP_SEL_C2H_DSC_PIDX(qid)] & 0xffff;
		desc_size = 8 << sw_ctx->desc_size;
		ring_size = ring_sizes[sw_ctx->ring_size];

		sw_ctx->pidx = pidx;

		if (sw_ctx->pidx == hw_ctx->hw_cidx) {
			if (sw_ctx->int_aggr) {
				this->send_msix(intr_ctx->vector, false);
			} else if (sw_ctx->msix_vector >=
					QDMA_PF0_FIRST_DATA_MSIX_VECTOR) {
				this->send_msix(sw_ctx->msix_vector, false);
			}
			return;
		}

		/* Running through the remaining descriptors from sw_idx to
		 * hw_idx.  */
		while (sw_ctx->pidx > hw_ctx->hw_cidx) {
			int current_descriptor;

			/* cidx acts as the current descriptor processed by the
			 * Q.  */
			hw_ctx->hw_cidx++;
			current_descriptor = hw_ctx->hw_cidx;

			this->fetch_descriptor(
					((uint64_t)sw_ctx->desc_base_high << 32)
					+ sw_ctx->desc_base_low
					+ desc_size * (current_descriptor - 1),
					desc_size, desc);

			this->do_mm_dma(pdesc->src_address, pdesc->dst_address,
					pdesc->byte_count, h2c);

			/* Update the status, and write the descriptor back. */
			if (sw_ctx->writeback_en) {
				/* Fetch the last descriptor, put the status in
				 * it, and write it back.  */
				this->fetch_descriptor(
					((uint64_t)sw_ctx->desc_base_high << 32)
					+ sw_ctx->desc_base_low
					+ desc_size * ring_size,
					desc_size,
					desc);

				pstatus->err = 0;
				pstatus->cidx = hw_ctx->hw_cidx;
				pstatus->pidx = pidx;
				this->descriptor_writeback(
					((uint64_t)sw_ctx->desc_base_high << 32)
					+ sw_ctx->desc_base_low
					+ desc_size * ring_size,
					desc_size,
					desc);
			}

			if (sw_ctx->pidx != hw_ctx->hw_cidx) {
				continue;
			}

			/* Trigger an IRQ?  */
			if ((!sw_ctx->irq_arm) || (!sw_ctx->irq_enabled)) {
				/* The software is polling for the completion.
				 * Just get out. */
				continue;
			}

			if (sw_ctx->int_aggr) {
				struct intr_ring_entry entry;

				/* Update the PIDX in the Interrupt Context
				 * Structure.  */
				intr_ctx->pidx = pidx;

				if (!intr_ctx->valid) {
					SC_REPORT_ERROR("qdma",
						"invalid interrupt context");
					return;
				}

				/* Now the controller needs to populate the IRQ
				 * ring.  */
				entry.qid = qid;
				entry.interrupt_type = h2c ? 0 : 1;
				entry.coal_color = intr_ctx->color;
				entry.error = 0;
				entry.interrupt_state = 0;
				entry.color = entry.coal_color;
				entry.cidx = hw_ctx->hw_cidx;
				entry.pidx = intr_ctx->pidx;

				/* Write it to the buffer.  */
				this->write_irq_ring_entry(qid, &entry);

				/* Send the MSI-X.  */
				this->send_msix(intr_ctx->vector, true);
			} else {
				/* Direct interrupt: legacy or MSI-X.  */
				/* Pends an IRQ for the driver.  */
#ifdef QDMA_SOFT_IP
				this->regs.u32[R_GLBL_INTR_CFG] |=
					R_GLBL_INTR_CFG_INT_PEND;
				this->update_legacy_irq();
#endif

				if (sw_ctx->msix_vector >=
					QDMA_PF0_FIRST_DATA_MSIX_VECTOR) {
					this->send_msix(sw_ctx->msix_vector,
							true);
				}
			}
		}
	}

	/* Send an MSI-X on the @vec.  */
	void send_msix(uint32_t vec, bool val)
	{
#ifdef QDMA_SOFT_IP
		if (this->regs.u32[R_GLBL_INTR_CFG] & R_GLBL_INTR_CFG_INT_EN) {
			return;
		}
#endif

		/* Value doesn't matter here, but must be != 0.  */
		this->irq[vec].write(val);
	}

	/* Update the IRQ, or MSI-X depending on the configuration.  */
	void update_legacy_irq(void)
	{
#ifndef QDMA_SOFT_IP
		return;
#endif

		bool irq_on;

		if (this->regs.u32[R_GLBL_INTR_CFG] & R_GLBL_INTR_CFG_INT_EN) {
			/* Yes, so consider sending a legacy IRQ not an MSI-X.
			 */
			irq_on = this->regs.u32[R_GLBL_INTR_CFG] &
					R_GLBL_INTR_CFG_INT_PEND;

			this->irq[0].write(!!irq_on);
		}
	}

	/* Descriptors.  */
	void fetch_descriptor(uint64_t addr, uint8_t size, uint8_t *data) {
		sc_time delay(SC_ZERO_TIME);
		tlm::tlm_generic_payload trans;

		/* Do only 4bytes transactions.  */
		trans.set_command(tlm::TLM_READ_COMMAND);
		trans.set_data_length(4);
		trans.set_streaming_width(4);

		for (int i = 0; i < size; i += 4) {
			trans.set_address(addr + i);
			trans.set_data_ptr(data + i);
			this->dma->b_transport(trans, delay);
			if (trans.get_response_status() !=
				tlm::TLM_OK_RESPONSE) {
				goto err;
			}
		}

		return;
err:
		SC_REPORT_ERROR("qdma", "error fetching the descriptor");
	}

	void descriptor_writeback(uint64_t addr, uint8_t size, uint8_t *data) {
		sc_time delay(SC_ZERO_TIME);
		tlm::tlm_generic_payload trans;

		trans.set_command(tlm::TLM_WRITE_COMMAND);
		trans.set_address(addr);
		trans.set_data_ptr(data);
		trans.set_data_length(size);
		trans.set_streaming_width(size);

		this->dma->b_transport(trans, delay);

		if (trans.get_response_status() != tlm::TLM_OK_RESPONSE) {
			SC_REPORT_ERROR("qdma",
					"error writing back the descriptor");
		}
	}

	/* Write the IRQ ring entry and increment the ring pointer and the
	 * color in case of a warp arround.  */
	void write_irq_ring_entry(uint32_t qid,
				const struct intr_ring_entry *entry) {
		sc_time delay(SC_ZERO_TIME);
		tlm::tlm_generic_payload trans;
		uint64_t addr;
		struct intr_ctx *intr_ctx =
			(struct intr_ctx *)this->queue_contexts[qid]
			[QDMA_CTXT_SELC_INT_COAL].data;

		/* Compute the address of the entry.  */
		addr = QDMA_INTR_RING_ENTRY_ADDR(intr_ctx->baddr);
		addr += QDMA_INTR_RING_ENTRY_SZ * this->irq_ring_idx[qid];

		trans.set_command(tlm::TLM_WRITE_COMMAND);
		trans.set_address(addr);
		trans.set_data_ptr((unsigned char *)entry);
		trans.set_data_length(QDMA_INTR_RING_ENTRY_SZ);
		trans.set_streaming_width(QDMA_INTR_RING_ENTRY_SZ);

		this->dma->b_transport(trans, delay);

		if (trans.get_response_status() != tlm::TLM_OK_RESPONSE) {
			SC_REPORT_ERROR("qdma",
					"error writing to the IRQ ring");
		}

		this->irq_ring_idx[qid]++;
		if (this->irq_ring_idx[qid] * QDMA_INTR_RING_ENTRY_SZ
				== (1 + intr_ctx->page_size) * 4096) {
			/* IRQ ring wrapped, swap the color in the IRQ context.
			 */
			this->irq_ring_idx[qid] = 0;
			intr_ctx->color = intr_ctx->color ? 0 : 1;
		}
	}

	void axi_master_light_bar_b_transport(tlm::tlm_generic_payload &trans,
					      sc_time &delay) {
		tlm::tlm_command cmd = trans.get_command();
		sc_dt::uint64 addr = trans.get_address();
		unsigned char *data = trans.get_data_ptr();
		unsigned int len = trans.get_data_length();
		unsigned char *byte_en = trans.get_byte_enable_ptr();
		unsigned int s_width = trans.get_streaming_width();
		uint32_t v = 0;

		if (byte_en || len > 4 || s_width < len) {
			goto err;
		}

		if (cmd == tlm::TLM_READ_COMMAND) {
			switch (addr >> 2) {
				default:
					v = this->axi_regs.u32[addr >> 2];
					break;
			}
			memcpy(data, &v, len);
		} else if (cmd == tlm::TLM_WRITE_COMMAND) {
			memcpy(&v, data, len);
			switch (addr >> 2) {
				default:
					this->axi_regs.u32[addr >> 2] = v;
					break;
			}
		} else {
			goto err;
		}

		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		return;

err:
		SC_REPORT_WARNING("qdma",
				"unsupported read / write on the axi bar");
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
	}

	void config_bar_b_transport(tlm::tlm_generic_payload &trans,
			sc_time &delay) {
		tlm::tlm_command cmd = trans.get_command();
		sc_dt::uint64 addr = trans.get_address();
		unsigned char *data = trans.get_data_ptr();
		unsigned int len = trans.get_data_length();
		unsigned char *byte_en = trans.get_byte_enable_ptr();
		unsigned int s_width = trans.get_streaming_width();
		uint32_t v = 0;

		if (byte_en || len > 4 || s_width < len) {
			goto err;
		}
		if (cmd == tlm::TLM_READ_COMMAND) {
			switch (addr >> 2) {
				default:
					v = this->regs.u32[addr >> 2];
					break;
			}
			memcpy(data, &v, len);
		} else if (cmd == tlm::TLM_WRITE_COMMAND) {
			memcpy(&v, data, len);

			switch (addr >> 2) {
				case R_CONFIG_BLOCK_IDENT:
				case R_GLBL2_MISC_CAP:
					/* Read Only register.  */
					break;
				case R_DMAP_SEL_INT_CIDX(0) ...
					R_DMAP_SEL_CMPT_CIDX(QDMA_QUEUE_COUNT):
				{
					int qid = (addr - (R_DMAP_SEL_INT_CIDX(0) << 2)) / 0x10;

					this->regs.u32[addr >> 2] = v;

					switch (addr % 0x10) {
						case 0x4:
							/* R_DMAP_SEL_H2C_DSC_PIDX(n) */
							this->run_mm_dma(qid,
									true);
							break;
						case 0x8:
							/* R_DMAP_SEL_C2H_DSC_PIDX(n) */
							this->run_mm_dma(qid,
									false);
							break;
						default:
							break;
					}
					break;
				}
				case R_IND_CTXT_CMD:
					this->handle_ctxt_cmd(v);
					/* Drop the busy bit.  */
					this->regs.u32[addr >> 2] =
							v & 0xFFFFFFFE;
					break;
				case R_GLBL_INTR_CFG:
					/* W1C */
					if (v & R_GLBL_INTR_CFG_INT_PEND) {
						v &= ~R_GLBL_INTR_CFG_INT_PEND;
					}
					this->regs.u32[addr >> 2] = v;
					this->update_legacy_irq();
					break;
				default:
					this->regs.u32[addr >> 2] = v;
					break;
			}
		} else {
			goto err;
		}

		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		return;
err:
		SC_REPORT_WARNING("qdma",
				"unsupported read / write on the config bar");
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		return;
	}

	union {
		struct {
			uint32_t config_block_ident;
		};
		uint32_t u32[0x18000];
	} regs;

	struct {
		uint32_t u32[0xA8];
	} axi_regs;

	/* Reset the IP.  */
	void reset(void) {
		this->regs.config_block_ident = 0x1FD30001;
		this->regs.u32[R_GLBL2_MISC_CAP] = QDMA_VERSION;
		/* One bar mapped for PF0.  */
		this->regs.u32[R_GLBL2_PF_BARLITE_INT] = 0x01;
		this->regs.u32[R_GLBL2_CHANNEL_QDMA_CAP] =
			QDMA_QUEUE_COUNT;
		this->regs.u32[R_GLBL2_CHANNEL_MDMA] = 0x00030f0f;
		this->regs.u32[R_GLBL2_CHANNEL_FUNC_RET] = 0;
		this->regs.u32[R_GLBL2_PF_BARLITE_EXT] = 1
			<< QDMA_USER_BAR_ID;
	}

public:
	SC_HAS_PROCESS(qdma_cpm5);
	sc_in<bool> rst;
	tlm_utils::simple_initiator_socket<qdma_cpm5> card_bus;

	/* Interface to toward PCIE.  */
	tlm_utils::simple_target_socket<qdma_cpm5> config_bar;
	tlm_utils::simple_target_socket<qdma_cpm5> user_bar;
	tlm_utils::simple_initiator_socket<qdma_cpm5> dma;
	sc_vector<sc_out<bool> > irq;

	qdma_cpm5(sc_core::sc_module_name name) :
		rst("rst"),
		card_bus("card_initiator_socket"),
		config_bar("config_bar"),
		user_bar("user_bar"),
		dma("dma"),
		irq("irq", NR_QDMA_IRQ)
	{
		memset(&regs, 0, sizeof regs);

		SC_METHOD(reset);
		dont_initialize();
		sensitive << rst;

		config_bar.register_b_transport(this,
						&qdma_cpm5::config_bar_b_transport);
		user_bar.register_b_transport(this,
			&qdma_cpm5::axi_master_light_bar_b_transport);
	}
};

#endif /* __PCI_QDMA_H__ */
