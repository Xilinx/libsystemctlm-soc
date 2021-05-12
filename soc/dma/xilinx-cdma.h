/*
 * Copyright (c) 2020 Xilinx Inc.
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
#ifndef DMA_XILINX_CDMA_H__
#define DMA_XILINX_CDMA_H__

#define D(x)

class xilinx_cdma
: public sc_core::sc_module
{
public:
	SC_HAS_PROCESS(xilinx_cdma);
	tlm_utils::simple_initiator_socket<xilinx_cdma> init_socket;
	tlm_utils::simple_target_socket<xilinx_cdma> target_socket;

	xilinx_cdma(sc_core::sc_module_name name) :
		sc_module(name),
		init_socket("init_socket"),
		target_socket("target_socket")
	{
		target_socket.register_b_transport(this,
						   &xilinx_cdma::b_transport);
		SC_THREAD(do_dma_copy);
	}

private:
	enum {
		CR_RS		= 1 << 0,
		CR_RESET	= 1 << 2,
		CR_KEYHOLE	= 1 << 3,
		CR_CYCLIC_BD	= 1 << 4,
		CR_IOC_IRQ_EN	= 1 << 12,
	};

	enum {
		SR_HALTED	= 1 << 0,
		SR_IDLE		= 1 << 1,
		SR_SGINCLD	= 1 << 3,
		SR_IOC_IRQ	= 1 << 12,
	};

	enum {
		R_CR		= 0x00 / 4,
		R_SR		= 0x04 / 4,
		R_SA		= 0x18 / 4,
		R_SA_MSB	= 0x1c / 4,
		R_DA		= 0x20 / 4,
		R_DA_MSB	= 0x24 / 4,
		R_BTT		= 0x28 / 4,
		R_MAX		= 0x2c / 4,
	};

	uint32_t regs[R_MAX];
	sc_event ev_dma_copy;

	void do_dma_copy(void) {
		while (true) {
			unsigned char buf[64];
			uint64_t sa, da;
			uint32_t tlen;

			if (!regs[R_BTT]) {
				D(printf("%s: wait for copy event\n",
					name()));
				wait(ev_dma_copy);
			}

			tlen = regs[R_BTT];
			tlen = tlen > sizeof buf ? sizeof buf : tlen;

			sa = regs[R_SA_MSB];
			sa <<= 32;
			sa |= regs[R_SA];

			da = regs[R_DA_MSB];
			da <<= 32;
			da |= regs[R_DA];

			D(printf("%s: copy sa=%lx da=%lx tlen=%d\n",
				name(), sa, da, tlen));
			do_dma_trans(tlm::TLM_READ_COMMAND, buf, sa, tlen);
			wait(SC_ZERO_TIME);
			do_dma_trans(tlm::TLM_WRITE_COMMAND, buf, da, tlen);

			sa += tlen;
			da += tlen;

			regs[R_BTT] -= tlen;
			regs[R_SA] = sa;
			regs[R_SA_MSB] = sa >> 32;
			regs[R_DA] = da;
			regs[R_DA_MSB] = da >> 32;

			if (!regs[R_BTT]) {
				D(printf("%s: dma copy done\n", name()));
				regs[R_SR] |= SR_IDLE | SR_IOC_IRQ;
			}
		}
	};

	void do_dma_trans(tlm::tlm_command cmd, unsigned char *buf,
			sc_dt::uint64 addr, sc_dt::uint64 len) {
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
	}

	void b_transport(tlm::tlm_generic_payload& trans, sc_time& delay) {
		tlm::tlm_command cmd = trans.get_command();
		unsigned char *data = trans.get_data_ptr();
		unsigned int len = trans.get_data_length();
		uint64_t addr = trans.get_address();

		if (len != 4 || trans.get_byte_enable_ptr()) {
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
			return;
		}

		addr >>= 2;
		if (trans.get_command() == tlm::TLM_READ_COMMAND) {
			memcpy(data, &regs[addr], len);
		} else if (cmd == tlm::TLM_WRITE_COMMAND) {
			uint32_t v;
			memcpy(&v, data, len);
			switch (addr) {
				case R_CR:
					regs[addr] = v;
					regs[addr] &= ~CR_RESET;
					break;
				case R_SR:
					regs[addr] &= ~(v & SR_IOC_IRQ);
					D(printf("%s: SR=%x.%x val=%x\n", name(),
						regs[R_SR], regs[addr], v));
					break;
				case R_BTT:
					regs[addr] = v;
					regs[R_SR] &= ~(SR_IDLE);
					D(printf("%s: write LENGTH %d\n",
							name(), regs[R_BTT]));
					ev_dma_copy.notify(SC_ZERO_TIME);
					break;
				default:
					/* No side-effect.  */
					regs[addr] = v;
					break;
			}
		}
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}
};
#undef D
#endif
