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
#ifndef SOC_ETH_XLNX_MRMAC_H__
#define SOC_ETH_XLNX_MRMAC_H__

#include "tlm-extensions/genattr.h"
#include "utils/regapi.h"
#include "regs-mrmac.h"

SC_MODULE(xilinx_mrmac)
{
public:
	SC_HAS_PROCESS(xilinx_mrmac);
	tlm_utils::simple_initiator_socket<xilinx_mrmac> mac_rx_socket;
	tlm_utils::simple_target_socket<xilinx_mrmac> mac_tx_socket;
	tlm_utils::simple_initiator_socket<xilinx_mrmac> phy_tx_socket;
	tlm_utils::simple_target_socket<xilinx_mrmac> phy_rx_socket;
	tlm_utils::simple_target_socket<xilinx_mrmac> reg_socket;

	sc_in<bool> rst;
	xilinx_mrmac(sc_core::sc_module_name name, bool insert_rx_crc = false);
private:
	regapi_block<uint32_t, R_STAT_RX_ECC_ERR1_0_MSB + 1 > rb;
	struct {
		struct {
			uint64_t total_packets;
			uint64_t total_good_packets;
			uint64_t total_bytes;
			uint64_t total_good_bytes;

			uint64_t packet_64;
			uint64_t packet_65_127;
			uint64_t packet_128_255;
			uint64_t packet_256_511;
			uint64_t packet_512_1023;
			uint64_t packet_1024_1518;
			uint64_t packet_1519_1522;
			uint64_t packet_1523_1548;
			uint64_t packet_1549_2047;
			uint64_t packet_2048_4095;
			uint64_t packet_4096_8191;
			uint64_t packet_8192_9215;
			uint64_t packet_large;
			uint64_t packet_small;

			uint64_t bad_fcs;

			uint64_t unicast;
			uint64_t multicast;
			uint64_t broadcast;
			uint64_t vlan;
			uint64_t pause;
		} tx;
		struct {
			uint64_t total_packets;
			uint64_t total_good_packets;
			uint64_t total_bytes;
			uint64_t total_good_bytes;

			uint64_t packet_64;
			uint64_t packet_65_127;
			uint64_t packet_128_255;
			uint64_t packet_256_511;
			uint64_t packet_512_1023;
			uint64_t packet_1024_1518;
			uint64_t packet_1519_1522;
			uint64_t packet_1523_1548;
			uint64_t packet_1549_2047;
			uint64_t packet_2048_4095;
			uint64_t packet_4096_8191;
			uint64_t packet_8192_9215;
			uint64_t packet_large;
			uint64_t packet_small;

			uint64_t bad_fcs;

			uint64_t unicast;
			uint64_t multicast;
			uint64_t broadcast;
			uint64_t vlan;
			uint64_t pause;
		} rx;
	} stats;

	struct {
		bool insert_rx_crc;
	} cfg;

	sc_fifo<tlm::tlm_generic_payload*> rxfifo;
	unsigned char txbuf[64 * 1024];
	unsigned int txpos;

	void stats_add(uint64_t &c, uint64_t v, uint64_t max) {
		bool ext = ARRAY_FIELD_EX(rb.regs, MODE_REG_0, ctl_counter_extend_0);

		if ((max - c) < v) {
			if (ext) {
				// TODO: set the extended signal
			} else {
				// Saturate.
				return;
			}
		}

		c += v;
		c &= max;
	}

	void stats_add48(uint64_t &c, uint64_t v) {
		uint64_t uint48_max = (1ULL << 48) - 1;

		stats_add(c, v, uint48_max);
	}

	void stats_add64(uint64_t &c, uint64_t v) {
		stats_add(c, v, UINT64_MAX);
	}

	void stats_update_tx_hist(int len);
	void stats_update_rx_hist(int len);

	void stats_update64(int reg, uint64_t &v) {
		// Move accumulators into user accessible registers.
		rb.regs[reg] = v;
		rb.regs[reg + 1] = v >> 32;

		// Reset accumulators to zero.
		v = 0;
	}

	void tick(void);

	void reset_thread();
	void push_stream(unsigned char *buf, int len, bool eop);
	void mac_b_transport(tlm::tlm_generic_payload& trans, sc_time& delay);
	void phy_b_transport(tlm::tlm_generic_payload& trans, sc_time& delay);
	void phy_rx_thread();
	void reg_b_transport(tlm::tlm_generic_payload& trans, sc_time& delay);
};
#endif
