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
#include "utils/crc32.h"
#include "soc/net/ethernet/ethernet.h"
#include "soc/net/ethernet/xilinx/mrmac/mrmac.h"

#define D(x)

xilinx_mrmac::xilinx_mrmac(sc_core::sc_module_name name) :
	sc_module(name),
	mac_rx_socket("mac_rx_socket"),
	mac_tx_socket("mac_tx_socket"),
	phy_tx_socket("phy_tx_socket"),
	phy_rx_socket("phy_rx_socket"),
	reg_socket("reg_socket"),
	rst("rst"),
	rb("regs", mrmac_reginfo, true),
	rxfifo("rxfifo", 2),
	txpos(0)
{
	mac_tx_socket.register_b_transport(this, &xilinx_mrmac::mac_b_transport);
	phy_rx_socket.register_b_transport(this, &xilinx_mrmac::phy_b_transport);
	reg_socket.register_b_transport(this, &xilinx_mrmac::reg_b_transport);

	SC_THREAD(reset_thread);
	SC_THREAD(phy_rx_thread);
}

void xilinx_mrmac::reset_thread() {
	while (true) {
		wait(rst.posedge_event());

		// Reset all the registers.  */
		rb.reg_reset_all();
	}
}

void xilinx_mrmac::push_stream(unsigned char *buf, int len, bool eop)
{
        genattr_extension *genattr = new genattr_extension();
        sc_time delay = SC_ZERO_TIME;
        tlm::tlm_generic_payload tr;

        tr.set_command(tlm::TLM_WRITE_COMMAND);
        tr.set_address(0);
        tr.set_data_ptr(buf);
        tr.set_data_length(len);
        tr.set_streaming_width(len);
        tr.set_dmi_allowed(false);
        tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

        genattr->set_eop(eop);
        tr.set_extension(genattr);

        phy_tx_socket->b_transport(tr, delay);

        tr.release_extension(genattr);
}

void xilinx_mrmac::stats_update_tx_hist(int len) {
	if (len < 64) {
		stats_add48(stats.tx.packet_small, 1);
	} else if (len == 64) {
		stats_add48(stats.tx.packet_64, 1);
	} else if (len < 128) {
		stats_add48(stats.tx.packet_65_127, 1);
	} else if (len < 256) {
		stats_add48(stats.tx.packet_128_255, 1);
	} else if (len < 512) {
		stats_add48(stats.tx.packet_256_511, 1);
	} else if (len < 1024) {
		stats_add48(stats.tx.packet_512_1023, 1);
	} else if (len < 1519) {
		stats_add48(stats.tx.packet_1024_1518, 1);
	} else if (len < 1523) {
		stats_add48(stats.tx.packet_1519_1522, 1);
	} else if (len < 1549) {
		stats_add48(stats.tx.packet_1523_1548, 1);
	} else if (len < 2048) {
		stats_add48(stats.tx.packet_1549_2047, 1);
	} else if (len < 4096) {
		stats_add48(stats.tx.packet_2048_4095, 1);
	} else if (len < 8192) {
		stats_add48(stats.tx.packet_4096_8191, 1);
	} else if (len < 9216) {
		stats_add48(stats.tx.packet_8192_9215, 1);
	} else {
		stats_add48(stats.tx.packet_large, 1);
	}
}

void xilinx_mrmac::tick(void) {
	stats_update64(R_STAT_TX_TOTAL_PACKETS_0_LSB, stats.tx.total_packets);
	stats_update64(R_STAT_TX_TOTAL_GOOD_PACKETS_0_LSB, stats.tx.total_good_packets);
	stats_update64(R_STAT_TX_TOTAL_BYTES_0_LSB, stats.tx.total_bytes);
	stats_update64(R_STAT_TX_TOTAL_GOOD_BYTES_0_LSB, stats.tx.total_good_bytes);

	stats_update64(R_STAT_TX_PACKET_64_BYTES_0_LSB, stats.tx.packet_64);
	stats_update64(R_STAT_TX_PACKET_65_127_BYTES_0_LSB, stats.tx.packet_65_127);
	stats_update64(R_STAT_TX_PACKET_128_255_BYTES_0_LSB, stats.tx.packet_128_255);
	stats_update64(R_STAT_TX_PACKET_256_511_BYTES_0_LSB, stats.tx.packet_256_511);
	stats_update64(R_STAT_TX_PACKET_512_1023_BYTES_0_LSB, stats.tx.packet_512_1023);
	stats_update64(R_STAT_TX_PACKET_1024_1518_BYTES_0_LSB, stats.tx.packet_1024_1518);
	stats_update64(R_STAT_TX_PACKET_1519_1522_BYTES_0_LSB, stats.tx.packet_1519_1522);
	stats_update64(R_STAT_TX_PACKET_1523_1548_BYTES_0_LSB, stats.tx.packet_1523_1548);
	stats_update64(R_STAT_TX_PACKET_1549_2047_BYTES_0_LSB, stats.tx.packet_1549_2047);
	stats_update64(R_STAT_TX_PACKET_2048_4095_BYTES_0_LSB, stats.tx.packet_2048_4095);
	stats_update64(R_STAT_TX_PACKET_4096_8191_BYTES_0_LSB, stats.tx.packet_4096_8191);
	stats_update64(R_STAT_TX_PACKET_8192_9215_BYTES_0_LSB, stats.tx.packet_8192_9215);
	stats_update64(R_STAT_TX_PACKET_LARGE_0_LSB, stats.tx.packet_large);
	stats_update64(R_STAT_TX_PACKET_SMALL_0_LSB, stats.tx.packet_small);

	stats_update64(R_STAT_TX_BAD_FCS_0_LSB, stats.tx.bad_fcs);

	stats_update64(R_STAT_TX_UNICAST_0_LSB, stats.tx.unicast);
	stats_update64(R_STAT_TX_MULTICAST_0_LSB, stats.tx.multicast);
	stats_update64(R_STAT_TX_BROADCAST_0_LSB, stats.tx.broadcast);
	stats_update64(R_STAT_TX_VLAN_0_LSB, stats.tx.vlan);
	stats_update64(R_STAT_TX_PAUSE_0_LSB, stats.tx.pause);
}

void xilinx_mrmac::mac_b_transport(tlm::tlm_generic_payload& trans, sc_time& delay) {
	unsigned char *data = trans.get_data_ptr();
	int len = trans.get_data_length();
	genattr_extension *genattr;
	bool eop = true;

	if (!ARRAY_FIELD_EX(rb.regs, CONFIGURATION_TX_REG1_0, ctl_tx_enable_0)) {
		SC_REPORT_WARNING("mrmac", "TX while TX disabled. Packet dropped.\n");
		goto done;
	}

	trans.get_extension(genattr);
	if (genattr) {
		eop = genattr->get_eop();
	}

	assert(len < (int)(sizeof (txbuf) - txpos));
	memcpy(txbuf + txpos, data, len);
	txpos += len;

	if (eop) {
		bool good = true;

		if (txpos < 14) {
			SC_REPORT_WARNING("mrmac", "TX packet too small. Dropped\n");
			goto done;
		}

		if (ARRAY_FIELD_EX(rb.regs, CONFIGURATION_TX_REG1_0, ctl_tx_fcs_ins_enable_0)) {
			uint32_t crc = crc32(0, txbuf, txpos);
			memcpy(txbuf + txpos, &crc, sizeof(crc));
			txpos += sizeof(crc);
		} else if (!ARRAY_FIELD_EX(rb.regs, CONFIGURATION_TX_REG1_0, ctl_tx_ignore_fcs_0)) {
			uint32_t crc = crc32(0, txbuf, txpos - 4);
			uint32_t pkt_crc;

			memcpy(&pkt_crc, txbuf + txpos - 4, sizeof(pkt_crc));
			if (pkt_crc != crc) {
				stats_add48(stats.tx.bad_fcs, 1);
				good = false;
			}
		}

		if (good) {
			uint16_t type;

			stats_add48(stats.tx.total_good_packets, 1);
			stats_add64(stats.tx.total_good_bytes, txpos);
			stats_add48(stats.tx.unicast, eth_is_unicast(txbuf));
			stats_add48(stats.tx.multicast, eth_is_multicast(txbuf) && !eth_is_broadcast(txbuf));
			stats_add48(stats.tx.broadcast, eth_is_broadcast(txbuf));

			type = eth_get_type(txbuf);
			switch (type) {
			case ETH_HDR_TYPE_VLAN:
				stats_add48(stats.tx.vlan, 1);
				break;
			case ETH_HDR_TYPE_PAUSE:
				stats_add48(stats.tx.pause, 1);
				break;
			default:
				break;
			};
		}

		stats_add48(stats.tx.total_packets, 1);
		stats_add64(stats.tx.total_bytes, txpos);
		stats_update_tx_hist(txpos);

		push_stream(txbuf, txpos, true);
		D(hexdump("assembled mac tx", txbuf, txpos));
		txpos = 0;
	}

	D(printf("mac-tx %d done\n", trans.get_data_length()));
done:
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}

void xilinx_mrmac::phy_b_transport(tlm::tlm_generic_payload& trans, sc_time& delay) {
	tlm::tlm_generic_payload *gp = new tlm::tlm_generic_payload();
	unsigned char *buf = new unsigned char [trans.get_data_length()];

	gp->set_data_ptr(buf);

	gp->deep_copy_from(trans);
	if (rxfifo.num_free()) {
		rxfifo.write(gp);
	} else {
		// Packet-loss
	}
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}

void xilinx_mrmac::phy_rx_thread() {
	while (true) {
		tlm::tlm_generic_payload *trans;
		sc_time delay = SC_ZERO_TIME;

		trans = rxfifo.read();
		assert(trans);

		if (!ARRAY_FIELD_EX(rb.regs, CONFIGURATION_RX_REG1_0, ctl_rx_enable_0)) {
			SC_REPORT_WARNING("mrmac", "TX while TX disabled\n");
		} else {
			mac_rx_socket->b_transport(*trans, delay);
		}

		delete trans->get_data_ptr();
		delete trans;
	}
}

void xilinx_mrmac::reg_b_transport(tlm::tlm_generic_payload& trans, sc_time& delay) {
	unsigned char *data = trans.get_data_ptr();
	uint64_t addr = trans.get_address();
	int len = trans.get_data_length();
	uint32_t v = 0;

	rb.reg_b_transport(trans, delay);

	memcpy(&v, data, len);

	switch (addr) {
	case A_TICK_REG_0:
		tick();
		if (FIELD_EX(v, TICK_REG_0, tick_reg_0)) {
			ARRAY_FIELD_DP(rb, STAT_STATISTICS_READY_0, stat_statistics_ready_0, 3);
		}
		break;
	}

	trans.set_response_status(tlm::TLM_OK_RESPONSE);
}
