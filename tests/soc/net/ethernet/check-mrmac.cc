/*
 * MRMAC, Example and test-suite.
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

#include <sstream>

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc.h"
#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "soc/net/ethernet/ethernet.h"
#include "soc/net/ethernet/xilinx/mrmac/mrmac.h"
#include "utils/crc32.h"

// Top simulation module.
SC_MODULE(Top)
{
	sc_clock clk;
	sc_signal<bool> rst;

	xilinx_mrmac mac;

	struct {
		uint64_t mac_rx;
		uint64_t phy_tx;
	} stats, stats_prev;

	unsigned char txbuf[10 * 1024];

	tlm_utils::simple_initiator_socket<Top> reg_socket;
	tlm_utils::simple_initiator_socket<Top> mac_tx_socket;
	tlm_utils::simple_target_socket<Top> mac_rx_socket;
	tlm_utils::simple_initiator_socket<Top> phy_rx_socket;
	tlm_utils::simple_target_socket<Top> phy_tx_socket;

	SC_HAS_PROCESS(Top);

	void csum(int len) {
		uint32_t crc = crc32(0, txbuf, len);
		memcpy(txbuf + len, &crc, sizeof(crc));
	}

	void tx(tlm_utils::simple_initiator_socket<Top> &socket, int len, bool eop = true) {
		genattr_extension *genattr = new genattr_extension();
		sc_time delay = SC_ZERO_TIME;
		tlm::tlm_generic_payload tr;

		tr.set_command(tlm::TLM_WRITE_COMMAND);
		tr.set_address(0);
		tr.set_data_ptr(txbuf);
		tr.set_data_length(len);
		tr.set_streaming_width(len);
		tr.set_dmi_allowed(false);
		tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		genattr->set_eop(eop);
		tr.set_extension(genattr);

		socket->b_transport(tr, delay);

		tr.release_extension(genattr);
		wait(1, SC_US);
	}

	void reg_access(tlm::tlm_command cmd, uint64_t offset,
			void *buf, unsigned int len) {
		sc_time delay = SC_ZERO_TIME;
		tlm::tlm_generic_payload tr;

		tr.set_command(cmd);
		tr.set_address(offset);
		tr.set_data_ptr((unsigned char *) buf);
		tr.set_data_length(len);
		tr.set_streaming_width(len);
		tr.set_dmi_allowed(false);
		tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

		reg_socket->b_transport(tr, delay);
	}

	void reg_write32(uint64_t offset, uint32_t v) {
		reg_access(tlm::TLM_WRITE_COMMAND, offset, &v, 4);
	}

	uint32_t reg_read32(uint64_t offset) {
		uint32_t v;
		reg_access(tlm::TLM_READ_COMMAND, offset, &v, 4);
		return v;
	}

	uint64_t reg_read64(uint64_t offset) {
		uint64_t v64;
		uint32_t v32;

		reg_access(tlm::TLM_READ_COMMAND, offset + 4, &v32, 4);
		v64 = v32;
		v64 <<= 32;
		reg_access(tlm::TLM_READ_COMMAND, offset, &v32, 4);
		v64 |= v32;
		return v64;
	}

	void reg_tick(void) {
		uint32_t v;

		reg_write32(A_TICK_REG_0, R_TICK_REG_0_tick_reg_0_MASK);
		// Wait for stats to become ready.
		do {
			v = reg_read32(A_STAT_STATISTICS_READY_0);
		} while ((v & R_STAT_STATISTICS_READY_0_stat_statistics_ready_0_MASK) != 3);
	}

	void check_tx_enabled(void) {
		uint32_t v;

		printf("%s\n", __func__);

		stats_prev = stats;

		tx(mac_tx_socket, 64);
		assert(stats.phy_tx - stats_prev.phy_tx == 1);
		stats_prev = stats;

		v = reg_read32(A_CONFIGURATION_TX_REG1_0);
		v &= ~R_CONFIGURATION_TX_REG1_0_ctl_tx_enable_0_MASK;
		reg_write32(A_CONFIGURATION_TX_REG1_0, v);

		tx(mac_tx_socket, 64);
		assert(stats.phy_tx - stats_prev.phy_tx == 0);
		stats_prev = stats;

		v |= R_CONFIGURATION_TX_REG1_0_ctl_tx_enable_0_MASK;
		reg_write32(A_CONFIGURATION_TX_REG1_0, v);
	}

	void check_tx_csum(void) {
		uint32_t v, saved;
		uint64_t v64;

		printf("%s\n", __func__);

		reg_tick();

		saved = v = reg_read32(A_CONFIGURATION_TX_REG1_0);
		v &= ~R_CONFIGURATION_TX_REG1_0_ctl_tx_fcs_ins_enable_0_MASK;
		v &= ~R_CONFIGURATION_TX_REG1_0_ctl_tx_ignore_fcs_0_MASK;
		reg_write32(A_CONFIGURATION_TX_REG1_0, v);

		memset(txbuf, 0, 68);
		tx(mac_tx_socket, 68);
		assert(stats.phy_tx - stats_prev.phy_tx == 1);
		stats_prev = stats;

		reg_tick();

		v64 = reg_read64(A_STAT_TX_BAD_FCS_0_LSB);
		assert(v64 == 1);

		reg_tick();
		csum(64);
		tx(mac_tx_socket, 68);
		assert(stats.phy_tx - stats_prev.phy_tx == 1);
		stats_prev = stats;

		v64 = reg_read64(A_STAT_TX_BAD_FCS_0_LSB);
		assert(v64 == 0);

		// Restore.
		reg_write32(A_CONFIGURATION_TX_REG1_0, saved);
	}

	void check_rx_csum(void) {
		uint32_t v, saved;
		uint64_t v64;

		printf("%s\n", __func__);

		reg_tick();

		saved = v = reg_read32(A_CONFIGURATION_RX_REG1_0);
		v |= R_CONFIGURATION_RX_REG1_0_ctl_rx_delete_fcs_0_MASK;
		v &= ~R_CONFIGURATION_RX_REG1_0_ctl_rx_ignore_fcs_0_MASK;
		reg_write32(A_CONFIGURATION_RX_REG1_0, v);

		memset(txbuf, 0, 68);
		tx(phy_rx_socket, 68);
		assert(stats.mac_rx - stats_prev.mac_rx == 0);
		stats_prev = stats;

		reg_tick();

		v64 = reg_read64(A_STAT_RX_BAD_FCS_0_LSB);
		assert(v64 == 1);

		reg_tick();
		csum(64);
		tx(phy_rx_socket, 68);
		assert(stats.mac_rx - stats_prev.mac_rx == 1);
		stats_prev = stats;

		v64 = reg_read64(A_STAT_RX_BAD_FCS_0_LSB);
		assert(v64 == 0);

		// Restore.
		reg_write32(A_CONFIGURATION_RX_REG1_0, saved);
	}

	void check_tx_stats_hist(void) {
		unsigned int seed = 0;
		uint64_t v64;
		int len;
		int i;

		printf("%s\n", __func__);

		// Zero accumulators.
		reg_tick();
		for (i = 0; i < 100 * 1000; i++) {
			uint64_t daddr_type_reg;
			unsigned int daddr_type;
			unsigned int eth_type;

			len = rand_r(&seed);
			len %= 9 * 1024;
			len += ETH_ADDR_LEN * 2 + 2;

			daddr_type = rand_r(&seed) % 3;
			eth_type = rand_r(&seed) % 3;

			if ((i & 1023) == 0) {
				printf("."); fflush(NULL);
			}

			memset(txbuf, 0, len);

			if (daddr_type == 0) {
				daddr_type_reg = A_STAT_TX_UNICAST_0_LSB;
				memset(txbuf, 0x00, ETH_ADDR_LEN);
			} else if (daddr_type == 1) {
				daddr_type_reg = A_STAT_TX_MULTICAST_0_LSB;
				memset(txbuf, 0x01, ETH_ADDR_LEN);
			} else {
				daddr_type_reg = A_STAT_TX_BROADCAST_0_LSB;
				memset(txbuf, 0xff, ETH_ADDR_LEN);
			}

			if (eth_type == 1) {
				txbuf[12] = ETH_HDR_TYPE_VLAN >> 8;
				txbuf[13] = ETH_HDR_TYPE_VLAN & 0xff;
			} else if (eth_type == 2) {
				txbuf[12] = ETH_HDR_TYPE_PAUSE >> 8;
				txbuf[13] = ETH_HDR_TYPE_PAUSE & 0xff;
			}

			tx(mac_tx_socket, len);

			reg_tick();

			// Include the csum.
			len += 4;
			if (len < 64) {
				v64 = reg_read64(A_STAT_TX_PACKET_SMALL_0_LSB);
			} else if (len == 64) {
				v64 = reg_read64(A_STAT_TX_PACKET_64_BYTES_0_LSB);
			} else if (len < 128) {
				v64 = reg_read64(A_STAT_TX_PACKET_65_127_BYTES_0_LSB);
			} else if (len < 256) {
				v64 = reg_read64(A_STAT_TX_PACKET_128_255_BYTES_0_LSB);
			} else if (len < 512) {
				v64 = reg_read64(A_STAT_TX_PACKET_256_511_BYTES_0_LSB);
			} else if (len < 1024) {
				v64 = reg_read64(A_STAT_TX_PACKET_512_1023_BYTES_0_LSB);
			} else if (len < 1519) {
				v64 = reg_read64(A_STAT_TX_PACKET_1024_1518_BYTES_0_LSB);
			} else if (len < 1523) {
				v64 = reg_read64(A_STAT_TX_PACKET_1519_1522_BYTES_0_LSB);
			} else if (len < 1549) {
				v64 = reg_read64(A_STAT_TX_PACKET_1523_1548_BYTES_0_LSB);
			} else if (len < 2048) {
				v64 = reg_read64(A_STAT_TX_PACKET_1549_2047_BYTES_0_LSB);
			} else if (len < 4096) {
				v64 = reg_read64(A_STAT_TX_PACKET_2048_4095_BYTES_0_LSB);
			} else if (len < 8192) {
				v64 = reg_read64(A_STAT_TX_PACKET_4096_8191_BYTES_0_LSB);
			} else if (len < 9216) {
				v64 = reg_read64(A_STAT_TX_PACKET_8192_9215_BYTES_0_LSB);
			} else {
				v64 = reg_read64(A_STAT_TX_PACKET_LARGE_0_LSB);
			}
			//printf("len=%d v64=%ld\n", len, v64);
			assert(v64 == 1);

			v64 = reg_read64(daddr_type_reg);
			assert(v64 == 1);

			if (eth_type && len >= 14) {
				if (eth_type == 1) {
					v64 = reg_read64(A_STAT_TX_VLAN_0_LSB);
				} else if (eth_type == 2) {
					v64 = reg_read64(A_STAT_TX_PAUSE_0_LSB);
				}
				assert(v64 == 1);
			}
		}
		printf("\n");
	}

	void check_rx_stats_hist(void) {
		unsigned int seed = 0;
		uint64_t v64;
		int len;
		int i;

		printf("%s\n", __func__);

		// Zero accumulators.
		reg_tick();
		for (i = 0; i < 100 * 1000; i++) {
			uint64_t daddr_type_reg;
			unsigned int daddr_type;
			unsigned int eth_type;

			len = rand_r(&seed);
			len %= 9 * 1024;
			len += ETH_ADDR_LEN * 2 + 2;

			daddr_type = rand_r(&seed) % 3;
			eth_type = rand_r(&seed) % 3;

			if ((i & 1023) == 0) {
				printf("."); fflush(NULL);
			}

			memset(txbuf, 0, len);

			if (daddr_type == 0) {
				daddr_type_reg = A_STAT_RX_UNICAST_0_LSB;
				memset(txbuf, 0x00, ETH_ADDR_LEN);
			} else if (daddr_type == 1) {
				daddr_type_reg = A_STAT_RX_MULTICAST_0_LSB;
				memset(txbuf, 0x01, ETH_ADDR_LEN);
			} else {
				daddr_type_reg = A_STAT_RX_BROADCAST_0_LSB;
				memset(txbuf, 0xff, ETH_ADDR_LEN);
			}

			if (eth_type == 1) {
				txbuf[12] = ETH_HDR_TYPE_VLAN >> 8;
				txbuf[13] = ETH_HDR_TYPE_VLAN & 0xff;
			} else if (eth_type == 2) {
				txbuf[12] = ETH_HDR_TYPE_PAUSE >> 8;
				txbuf[13] = ETH_HDR_TYPE_PAUSE & 0xff;
			}

			csum(len);
			len += 4;
			tx(phy_rx_socket, len);

			reg_tick();

			if (len < 64) {
				v64 = reg_read64(A_STAT_RX_PACKET_SMALL_0_LSB);
			} else if (len == 64) {
				v64 = reg_read64(A_STAT_RX_PACKET_64_BYTES_0_LSB);
			} else if (len < 128) {
				v64 = reg_read64(A_STAT_RX_PACKET_65_127_BYTES_0_LSB);
			} else if (len < 256) {
				v64 = reg_read64(A_STAT_RX_PACKET_128_255_BYTES_0_LSB);
			} else if (len < 512) {
				v64 = reg_read64(A_STAT_RX_PACKET_256_511_BYTES_0_LSB);
			} else if (len < 1024) {
				v64 = reg_read64(A_STAT_RX_PACKET_512_1023_BYTES_0_LSB);
			} else if (len < 1519) {
				v64 = reg_read64(A_STAT_RX_PACKET_1024_1518_BYTES_0_LSB);
			} else if (len < 1523) {
				v64 = reg_read64(A_STAT_RX_PACKET_1519_1522_BYTES_0_LSB);
			} else if (len < 1549) {
				v64 = reg_read64(A_STAT_RX_PACKET_1523_1548_BYTES_0_LSB);
			} else if (len < 2048) {
				v64 = reg_read64(A_STAT_RX_PACKET_1549_2047_BYTES_0_LSB);
			} else if (len < 4096) {
				v64 = reg_read64(A_STAT_RX_PACKET_2048_4095_BYTES_0_LSB);
			} else if (len < 8192) {
				v64 = reg_read64(A_STAT_RX_PACKET_4096_8191_BYTES_0_LSB);
			} else if (len < 9216) {
				v64 = reg_read64(A_STAT_RX_PACKET_8192_9215_BYTES_0_LSB);
			} else {
				v64 = reg_read64(A_STAT_RX_PACKET_LARGE_0_LSB);
			}
			//printf("len=%d v64=%ld\n", len, v64);
			assert(v64 == 1);

			v64 = reg_read64(daddr_type_reg);
			assert(v64 == 1);

			if (eth_type && len >= 14) {
				if (eth_type == 1) {
					v64 = reg_read64(A_STAT_RX_VLAN_0_LSB);
				} else if (eth_type == 2) {
					v64 = reg_read64(A_STAT_RX_PAUSE_0_LSB);
				}
				assert(v64 == 1);
			}
		}
		printf("\n");
	}

	void check(void) {
		/* Pull the reset signal.  */
		rst.write(true);
		wait(1, SC_US);
		rst.write(false);

		check_tx_enabled();
		check_tx_csum();
		check_rx_csum();
		check_tx_stats_hist();
		check_rx_stats_hist();

		sc_stop();
        }

	void mac_b_transport(tlm::tlm_generic_payload& trans, sc_time& delay) {
		// MAC rx.
		stats.mac_rx++;
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	void phy_b_transport(tlm::tlm_generic_payload& trans, sc_time& delay) {
		// PHY tx.
		stats.phy_tx++;
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	Top(sc_module_name name) :
		clk("clk", sc_time(1, SC_US)),
		rst("rst"),
		mac("mac"),
		reg_socket("reg_socket"),
		mac_tx_socket("mac_tx_socket"),
		mac_rx_socket("mac_rx_socket"),
		phy_rx_socket("phy_rx_socket"),
		phy_tx_socket("phy_tx_socket")
	{
		memset(&stats, 0, sizeof(stats));
		memset(&stats_prev, 0, sizeof(stats_prev));

		SC_THREAD(check);

		mac.rst(rst);
		reg_socket.bind(mac.reg_socket);
		mac_tx_socket.bind(mac.mac_tx_socket);
		mac_rx_socket.bind(mac.mac_rx_socket);
		phy_rx_socket.bind(mac.phy_rx_socket);
		phy_tx_socket.bind(mac.phy_tx_socket);

		mac_rx_socket.register_b_transport(this, &Top::mac_b_transport);
		phy_tx_socket.register_b_transport(this, &Top::phy_b_transport);
	}
};

int sc_main(int argc, char *argv[])
{
	Top top("Top");

	sc_start();

	return 0;
}
