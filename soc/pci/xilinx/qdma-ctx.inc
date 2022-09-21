/*
 * This models the context for the QDMA.
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

/* The per queue SW contexts.  */
#ifdef QDMA_CPM4
struct __attribute__((__packed__)) sw_ctx_cpm4 {
#else /* !QDMA_CPM4 */
struct __attribute__((__packed__)) sw_ctx_cpm5 {
#endif
	/* Producer index.  */
	uint16_t pidx;
	/* The queue is allowed to raise an IRQ.  */
	uint16_t irq_arm : 1;
#ifdef QDMA_CPM4
	uint32_t rsv : 15;
#else /* !QDMA_CPM4 */
	uint16_t fn_id : 12;
	uint16_t rsv : 3;
#endif /* QDMA_CPM4 */
	/* Queue is enabled.  */
	uint16_t enabled : 1;
	uint16_t fcrd_en : 1;
	uint16_t wbi_chk : 1;
	uint16_t wbi_int_en : 1;
#ifdef QDMA_CPM4
	uint16_t fn_id : 8;
#else /* !QDMA_CPM4 */
	uint16_t at : 1;
	uint16_t fetch_max : 4;
	uint16_t reserved2 : 3;
#endif /* QDMA_CPM4 */
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
	 * BASE + CIDX.	 */
	uint32_t desc_base_low;
	uint32_t desc_base_high;
#ifndef QDMA_CPM4
	/* MSI-X vector (direct irq), IRQ Ring index (indirect irq).  */
	uint16_t vec : 11;
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
#endif /* !QDMA_CPM4 */
};

/* Interrupt Aggregation.  */
/* Interrupt contexts.	*/
#ifdef QDMA_CPM4
struct __attribute__((__packed__)) intr_ctx_cpm4 {
#else /* !QDMA_CPM4 */
struct __attribute__((__packed__)) intr_ctx_cpm5 {
#endif
	uint32_t valid : 1;
#ifdef QDMA_CPM4
	uint32_t vector : 5;
#else /* !QDMA_CPM4 */
	uint32_t vector : 11;
#endif /* QDMA_CPM4 */
	uint32_t rsvd : 1;
	uint32_t status : 1;
	uint32_t color : 1;
	uint64_t baddr : 52;
	uint32_t page_size : 3;
	uint32_t pidx : 12;
#ifndef QDMA_CPM4
	uint32_t at : 1;
	uint32_t host_id : 4;
	uint32_t pasid : 22;
	uint32_t pasid_en : 1;
	uint32_t rsvd2 : 4;
	uint32_t func : 12;
#endif /* !QDMA_CPM4 */
};

/* Interrupt entry as written in the ring.  */
#ifdef QDMA_CPM4
struct __attribute__((__packed__)) intr_ring_entry_cpm4 {
#else /* !QDMA_CPM4 */
struct __attribute__((__packed__)) intr_ring_entry_cpm5 {
#endif /* QDMA_CPM4 */
	uint16_t pidx : 16;
	uint16_t cidx : 16;
	uint16_t color : 1;
	uint16_t interrupt_state : 2;
#ifdef QDMA_CPM4
	uint16_t error : 4;
	uint32_t rsvd : 11;
	uint16_t err_int : 1;
#else /* !QDMA_CPM4 */
	uint16_t error : 2;
	uint32_t rsvd : 1;
#endif /* QDMA_CPM4 */
	uint32_t interrupt_type : 1;
#ifdef QDMA_CPM4
	uint32_t qid : 11;
#else /* !QDMA_CPM4 */
	uint32_t qid : 24;
#endif /* QDMA_CPM4 */
	uint32_t coal_color : 1;
};

#ifdef QDMA_CPM4
struct __attribute__((__packed__)) qid2vec_ctx_cpm4 {
	/* For direct IRQ:
	 *   MSI-X vector index.
	 * For indirect IRQ:
	 *   Ring Index.  */
	uint16_t c2h_vector : 8;
	/* 0: direct irq, 1: indirect irq.  */
	uint16_t c2h_en_coal : 1;
	/* Likewise for h2c.  */
	uint16_t h2c_vector : 8;
	uint16_t h2c_en_coal : 1;
	uint16_t rsvd : 14;
};
#endif /* QDMA_CPM4 */
