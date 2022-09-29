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

/* Generate the different structures for the contexts.  */
#define QDMA_CPM4
#include "qdma-ctx.inc"
#undef QDMA_CPM4
#include "qdma-ctx.inc"

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc.h"
#include "tlm.h"
#include "soc/pci/core/pci-device-base.h"

#define NR_QDMA_IRQ      8

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
#define QDMA_SOFT_DEVICE_ID 0
#define QDMA_CPM4_DEVICE_ID 1
#define QDMA_CPM5_DEVICE_ID 2

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
#define QDMA_VERSION_FIELD(devid, vivado, versalip) ((devid << 28 )     \
						     + (vivado << 24)	\
						     + (versalip << 20))

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
/* Those registers are not at the same place for CPM4.  */
#define R_IND_CTXT_CMD(v)             ((v ? 0x824 : 0x844) >> 2)
#define R_DMAP_SEL_INT_CIDX(v, n)     (((v ? 0x6400 : 0x18000) \
					+ (0x10 * n)) >> 2)
#define R_DMAP_SEL_H2C_DSC_PIDX(v, n) (((v ? 0x6404 : 0x18004) \
					+ (0x10 * n)) >> 2)
#define R_DMAP_SEL_C2H_DSC_PIDX(v, n) (((v ? 0x6408 : 0x18008) \
					+ (0x10 * n)) >> 2)
#define R_DMAP_SEL_CMPT_CIDX(v, n)    (((v ? 0x640C : 0x1800C) \
					+ (0x10 * n)) >> 2)

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

template<typename SW_CTX, typename INTR_CTX, typename INTR_RING_ENTRY>
class qdma : public sc_module
{
private:
	/* Context handling.  */

	/* The per queue HW contexts.  */
	struct __attribute__((__packed__)) hw_ctx {
		/* CIDX of the last fetched descriptor.	 */
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

	/* Register area for the contexts described above.  */
	struct {
		uint32_t data[QDMA_U32_PER_CONTEXT];
	} queue_contexts[QDMA_QUEUE_COUNT][QDMA_MAX_CONTEXT_SELECTOR];

	/* MSI-X handling.  */
	enum msix_status { QDMA_MSIX_LOW = 0, QDMA_MSIX_HIGH }
		msix_status[NR_QDMA_IRQ];
	sc_event msix_trig[NR_QDMA_IRQ];

	void msix_strobe(unsigned int msix_id)
	{
		sc_event *msix_trig;

		/* Sanity check on the number of queue.	 */
		if (!(msix_id < NR_QDMA_IRQ)) {
			SC_REPORT_ERROR("qdma", "invalid MSIX ID");
		}

		/* Each queue has it's own event to be triggered.  */
		msix_trig = &this->msix_trig[msix_id];
		while (1) {
			/* Waiting for an MSIX to be triggered.	 */
			wait(*msix_trig);
			this->irq[msix_id].write(true);
			wait(10, SC_NS);
			this->irq[msix_id].write(false);
		}
	}

	/* Context commands.  */
	enum {
		QDMA_CTXT_CMD_CLR = 0,
		QDMA_CTXT_CMD_WR = 1,
		QDMA_CTXT_CMD_RD = 2,
		QDMA_CTXT_CMD_INV = 3
	};

	/* The contexts are indirectly accessed by the driver, also they are
	 * slightly version dependent (CPM4 vs CPM5).  */
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
		QDMA_CTXT_SELC_FMAP_QID2VEC = 0xC,
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
			case QDMA_CTXT_SELC_FMAP_QID2VEC:
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
	void handle_irq_ctxt_cmd(uint32_t ring_idx, uint32_t cmd) {
		INTR_CTX *intr_ctx =
			(INTR_CTX *)this->queue_contexts[ring_idx]
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
						this->irq_ring_entry_idx
						  [ring_idx] = 0;
					}
				}
				break;
			case QDMA_CTXT_CMD_INV:
				/* Drop the valid bit.	*/
				intr_ctx->valid = 0;
				break;
			default:
				break;
		}
	}

	/* Descriptors: for h2c and c2h memory mapped transfer.	 */
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
	   Handle the request.	*/
	void run_mm_dma(int16_t qid, bool h2c)
	{
		SW_CTX *sw_ctx;
		struct hw_ctx *hw_ctx;
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
		sw_ctx = this->get_software_context(qid, h2c);
		hw_ctx =
			(struct hw_ctx *)this->queue_contexts[qid]
			[h2c ? QDMA_CTXT_SELC_DEC_HW_H2C :
				QDMA_CTXT_SELC_DEC_HW_C2H].data;
		pidx = this->regs.u32
		  [h2c ? R_DMAP_SEL_H2C_DSC_PIDX(this->is_cpm4(), qid) :
		   R_DMAP_SEL_C2H_DSC_PIDX(this->is_cpm4(), qid)] & 0xffff;
		desc_size = 8 << sw_ctx->desc_size;
		ring_size = ring_sizes[sw_ctx->ring_size];

		sw_ctx->pidx = pidx;

		/* Check that the producer index is in the descriptor ring, and
		   isn't pointing to the status descriptor.  */
		if (sw_ctx->pidx >= ring_size) {
			SC_REPORT_ERROR("qdma", "Producer index outside the "
					"descriptor ring.");
		}

		/* Running through the remaining descriptors from CIDX to
		 * PIDX.  Warp around if needed */
		while (sw_ctx->pidx != hw_ctx->hw_cidx) {
			this->fetch_descriptor(
					((uint64_t)sw_ctx->desc_base_high << 32)
					+ sw_ctx->desc_base_low
					+ desc_size * hw_ctx->hw_cidx,
					desc_size, desc);

			this->do_mm_dma(pdesc->src_address, pdesc->dst_address,
					pdesc->byte_count, h2c);

			/* Descriptor is processed, go to the next one.  This
			   might warp around the descriptor ring, also skip the
			   last descriptor which is the status descriptor.  */
			hw_ctx->hw_cidx = hw_ctx->hw_cidx == ring_size - 1 ?
				0 : hw_ctx->hw_cidx + 1;

			/* Sending MSIX and / or writing back status descriptor
			   doesn't make sense at this point since the simulator
			   won't notice.  Do it once for all when the queue
			   finishes its work to gain performance.  */
			if (sw_ctx->pidx != hw_ctx->hw_cidx) {
				continue;
			}

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

			/* Trigger an IRQ?  */
			if ((!sw_ctx->irq_arm) || (!sw_ctx->irq_enabled)) {
				/* The software is polling for the completion.
				 * Just get out. */
				continue;
			}

			if (this->irq_aggregation_enabled(qid, h2c)) {
				INTR_CTX *intr_ctx;
				INTR_RING_ENTRY entry;
				int ring_idx = this->get_vec(qid, h2c);

				/* Each queue has a programmable irq ring
				 * associated to it.  */
				intr_ctx =
				  (INTR_CTX *)this->queue_contexts
				      [ring_idx]
				      [QDMA_CTXT_SELC_INT_COAL].data;

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
				this->write_irq_ring_entry(ring_idx, &entry);

				/* Send the MSI-X associated to the ring.  */
				this->msix_trig[intr_ctx->vector].notify();
			} else {
				/* Direct interrupt: legacy or MSI-X.  */
				/* Pends an IRQ for the driver.	 */
#ifdef QDMA_SOFT_IP
				this->regs.u32[R_GLBL_INTR_CFG] |=
					R_GLBL_INTR_CFG_INT_PEND;
				this->update_legacy_irq();
#endif
				/* Send the MSI-X.  */
				this->msix_trig[get_vec(qid, h2c)].notify();
			}
		}
	}

	/* Update the IRQ.  */
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

	/* Descriptors.	 */
	void fetch_descriptor(uint64_t addr, uint8_t size, uint8_t *data) {
		sc_time delay(SC_ZERO_TIME);
		tlm::tlm_generic_payload trans;

		/* Do only 4bytes transactions.	 */
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
	 * color in case of a warp arround.  NOTE: The IRQ context is not queue
	 * specific, but rather each queue has a ring index which is selecting
	 * the interrupt context.  In the CPM4 flavour it's defined in the
	 * qid2vec table.  */
	void write_irq_ring_entry(uint32_t ring_idx,
				  const INTR_RING_ENTRY *entry) {
		sc_time delay(SC_ZERO_TIME);
		tlm::tlm_generic_payload trans;
		uint64_t addr;
		INTR_CTX *intr_ctx =
			(INTR_CTX *)this->queue_contexts[ring_idx]
			[QDMA_CTXT_SELC_INT_COAL].data;

		/* Compute the address of the entry.  */
		addr = QDMA_INTR_RING_ENTRY_ADDR(intr_ctx->baddr);
		addr += QDMA_INTR_RING_ENTRY_SZ
		  * this->irq_ring_entry_idx[ring_idx];

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

		/* Now that the entry is written increment the counter, if
		 * there is a wrap around, invert the color, so the driver
		 * doesn't risk to miss / overwrite data.  */
		this->irq_ring_entry_idx[ring_idx]++;
		if (this->irq_ring_entry_idx[ring_idx] * QDMA_INTR_RING_ENTRY_SZ
		    == (1 + intr_ctx->page_size) * 4096) {
			this->irq_ring_entry_idx[ring_idx] = 0;
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
				case R_GLBL2_MISC_CAP:
					v = this->qdma_get_version();
					break;
				default:
					v = this->regs.u32[addr >> 2];
					break;
			}
			memcpy(data, &v, len);
		} else if (cmd == tlm::TLM_WRITE_COMMAND) {
			bool done = true;
			memcpy(&v, data, len);

			/* There is some differences in the register set for
			 * the cpm4 flavour, handle those register appart.  */
			if (this->is_cpm4()) {
			  switch (addr >> 2) {
			  case R_DMAP_SEL_INT_CIDX(1, 0) ...
			    R_DMAP_SEL_CMPT_CIDX(1, QDMA_QUEUE_COUNT):
				{
					int qid = (addr
					  - (R_DMAP_SEL_INT_CIDX(1, 0) << 2))
					  / 0x10;

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
			  case R_IND_CTXT_CMD(1):
					this->handle_ctxt_cmd(v);
					/* Drop the busy bit.  */
					this->regs.u32[addr >> 2] =
							v & 0xFFFFFFFE;
					break;
				default:
					done = false;
					break;
			  }
			} else {
			  switch (addr >> 2) {
			  case R_DMAP_SEL_INT_CIDX(0, 0) ...
			    R_DMAP_SEL_CMPT_CIDX(0, QDMA_QUEUE_COUNT):
				{
					int qid = (addr
					  - (R_DMAP_SEL_INT_CIDX(0, 0) << 2))
					  / 0x10;

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
			  case R_IND_CTXT_CMD(0):
					this->handle_ctxt_cmd(v);
					/* Drop the busy bit.  */
					this->regs.u32[addr >> 2] =
							v & 0xFFFFFFFE;
					break;
				default:
					done = false;
					break;
			  }
			}

			if (!done) {
				switch (addr >> 2) {
					case R_CONFIG_BLOCK_IDENT:
					case R_GLBL2_MISC_CAP:
						/* Read Only register.	*/
						break;
					case R_GLBL_INTR_CFG:
						/* W1C */
						if (v
						   & R_GLBL_INTR_CFG_INT_PEND) {
							v &=
						      ~R_GLBL_INTR_CFG_INT_PEND;
						}
						this->regs.u32[addr >> 2] = v;
						this->update_legacy_irq();
						break;
					default:
						this->regs.u32[addr >> 2] = v;
						break;
				}
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
		/* One bar mapped for PF0.  */
		this->regs.u32[R_GLBL2_PF_BARLITE_INT] = 0x01;
		this->regs.u32[R_GLBL2_CHANNEL_QDMA_CAP] =
			QDMA_QUEUE_COUNT;
		this->regs.u32[R_GLBL2_CHANNEL_MDMA] = 0x00030f0f;
		this->regs.u32[R_GLBL2_CHANNEL_FUNC_RET] = 0;
		this->regs.u32[R_GLBL2_PF_BARLITE_EXT] = 1
			<< QDMA_USER_BAR_ID;
	}

	void init_msix()
	{
		for (int i = 0; i < NR_QDMA_IRQ; i++) {
			sc_spawn(sc_bind(&qdma::msix_strobe,
				 this,
				 i));
		}
	}

	virtual bool is_cpm4() = 0;
	virtual uint32_t qdma_get_version() = 0;
	virtual bool irq_aggregation_enabled(int qid, bool h2c) = 0;
	/* Either get the MSIX Vector (in direct interrupt mode), or the IRQ
	 * Ring Index (in indirect interrupt mode).  */
	virtual int get_vec(int qid, bool h2c) = 0;
protected:
	SW_CTX *get_software_context(int qid, bool h2c)
	{
		return (SW_CTX *)this->queue_contexts[qid]
			[h2c ? QDMA_CTXT_SELC_DEC_SW_H2C
			     : QDMA_CTXT_SELC_DEC_SW_C2H].data;
	}

	qid2vec_ctx_cpm4 *get_qid2vec_context(int qid)
	{
		return (qid2vec_ctx_cpm4 *)(this->queue_contexts[qid]
			[QDMA_CTXT_SELC_FMAP_QID2VEC].data);
	}

	/* Current entry in a given interrupt ring.  */
	int irq_ring_entry_idx[QDMA_QUEUE_COUNT];
public:
	SC_HAS_PROCESS(qdma);
	sc_in<bool> rst;
	tlm_utils::simple_initiator_socket<qdma> card_bus;

	/* Interface to toward PCIE.  */
	tlm_utils::simple_target_socket<qdma> config_bar;
	tlm_utils::simple_target_socket<qdma> user_bar;
	tlm_utils::simple_initiator_socket<qdma> dma;
	sc_vector<sc_out<bool> > irq;

	qdma(sc_core::sc_module_name name) :
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
						&qdma::config_bar_b_transport);
		user_bar.register_b_transport(this,
			&qdma::axi_master_light_bar_b_transport);
		this->init_msix();
	}
};

class qdma_cpm5:
  public qdma<struct sw_ctx_cpm5,
	      struct intr_ctx_cpm5,
	      struct intr_ring_entry_cpm5>
{
private:
	bool is_cpm4()
	{
		return false;
	}

	bool irq_aggregation_enabled(int qid, bool h2c)
	{
		struct sw_ctx_cpm5 *sw_ctx = this->get_software_context(qid,
									h2c);
		return (sw_ctx->int_aggr != 0);
	}

	int get_vec(int qid, bool h2c)
	{
		struct sw_ctx_cpm5 *sw_ctx
			= this->get_software_context(qid, h2c);
		return sw_ctx->vec;
	}

	uint32_t qdma_get_version()
	{
		return QDMA_VERSION_FIELD(QDMA_CPM5_DEVICE_ID, 1, 0);
	}
public:
	qdma_cpm5(sc_core::sc_module_name name):
	  qdma(name)
	{
	}
};

class qdma_cpm4:
  public qdma<struct sw_ctx_cpm4,
	      struct intr_ctx_cpm4,
	      struct intr_ring_entry_cpm4>
{
private:
	bool is_cpm4()
	{
		return true;
	}

	bool irq_aggregation_enabled(int qid, bool h2c)
	{
		struct qid2vec_ctx_cpm4 *qid2vec_ctx =
			this->get_qid2vec_context(qid);

		return h2c ? qid2vec_ctx->h2c_en_coal
			   : qid2vec_ctx->c2h_en_coal;
	}

	int get_vec(int qid, bool h2c)
	{
		struct qid2vec_ctx_cpm4 *qid2vec_ctx
			= this->get_qid2vec_context(qid);

		return h2c ? qid2vec_ctx->h2c_vector : qid2vec_ctx->c2h_vector;
	}

	uint32_t qdma_get_version()
	{
		return QDMA_VERSION_FIELD(QDMA_CPM4_DEVICE_ID, 0, 0);
	}
public:
	qdma_cpm4(sc_core::sc_module_name name):
	  qdma(name)
	{
	}
};

#endif /* __PCI_QDMA_H__ */
