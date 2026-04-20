/*
 * Versal 600G DCMAC Ethernet port in Coupled MAC+PCS mode
 *
 * Copyright (c) 2025 Advanced Micro Devices Inc.
 *
 * SPDX-License-Identifier: MIT
 */
#include <inttypes.h>
#include <stdio.h>

#include "dcmac-ethmac.h"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm_utils/tlm_quantumkeeper.h"
#include "tlm-extensions/genattr.h"
#include "utils/hexdump.h"
#include "utils/regapi.h"
#include "utils/crc32.h"
#include "soc/net/ethernet/ethernet.h"

#define D(x)

static const regapi_info<uint32_t> dcmac_port_reginfo[] = {
#define VERSAL_600G_DCMAC_PREGS_INIT
#include "dcmac-regs.h"
};

amd_dcmac_ethmac::amd_dcmac_ethmac(sc_module_name name,
                                   sc_event& mode_set_ev,
                                   bool insert_rx_crc) :
    sc_module(name),
    mac_rx_socket("mac_rx_socket"),
    mac_tx_socket("mac_tx_socket"),
    phy_tx_socket("phy_tx_socket"),
    phy_rx_socket("phy_rx_socket"),
    reg_socket("reg_socket"),
    rst("rst"),
    mode_set(mode_set_ev),
    rb("regs", dcmac_port_reginfo),
    rxfifo("rxfifo", 2),
    txpos(0)
{
    mac_tx_socket.register_b_transport(this, &amd_dcmac_ethmac::mac_b_transport);
    phy_rx_socket.register_b_transport(this, &amd_dcmac_ethmac::phy_b_transport);

    reg_socket.register_b_transport(this, &amd_dcmac_ethmac::reg_b_transport);

    memset(&stats, 0, sizeof(stats));

    cfg.insert_rx_crc = insert_rx_crc;

    SC_METHOD(on_reset);
    sensitive << rst.pos();

    SC_THREAD(phy_rx_thread);
}

void amd_dcmac_ethmac::on_reset()
{
    // Reset all the registers.
    rb.reg_reset_all();
    memset(&stats, 0, sizeof(stats));
}

void amd_dcmac_ethmac::push_stream(unsigned char *buf, int len, bool eop)
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

void amd_dcmac_ethmac::stats_update_tx_hist(unsigned len)
{
    if (len < 64) {
        stats_add47(stats.tx.packet_small, 1);
    } else if (len == 64) {
        stats_add47(stats.tx.packet_64, 1);
    } else if (len < 128) {
        stats_add47(stats.tx.packet_65_127, 1);
    } else if (len < 256) {
        stats_add47(stats.tx.packet_128_255, 1);
    } else if (len < 512) {
        stats_add47(stats.tx.packet_256_511, 1);
    } else if (len < 1024) {
        stats_add47(stats.tx.packet_512_1023, 1);
    } else if (len < 1519) {
        stats_add47(stats.tx.packet_1024_1518, 1);
    } else if (len < 1523) {
        stats_add47(stats.tx.packet_1519_1522, 1);
    } else if (len < 1549) {
        stats_add47(stats.tx.packet_1523_1548, 1);
    } else if (len < 2048) {
        stats_add47(stats.tx.packet_1549_2047, 1);
    } else if (len < 4096) {
        stats_add47(stats.tx.packet_2048_4095, 1);
    } else if (len < 8192) {
        stats_add47(stats.tx.packet_4096_8191, 1);
    } else if (len < 9216) {
        stats_add47(stats.tx.packet_8192_9215, 1);
    } else {
        stats_add47(stats.tx.packet_large, 1);
    }
}

void amd_dcmac_ethmac::stats_update_rx_hist(unsigned len)
{
    if (len < 64) {
        stats_add47(stats.rx.packet_small, 1);
    } else if (len == 64) {
        stats_add47(stats.rx.packet_64, 1);
    } else if (len < 128) {
        stats_add47(stats.rx.packet_65_127, 1);
    } else if (len < 256) {
        stats_add47(stats.rx.packet_128_255, 1);
    } else if (len < 512) {
        stats_add47(stats.rx.packet_256_511, 1);
    } else if (len < 1024) {
        stats_add47(stats.rx.packet_512_1023, 1);
    } else if (len < 1519) {
        stats_add47(stats.rx.packet_1024_1518, 1);
    } else if (len < 1523) {
        stats_add47(stats.rx.packet_1519_1522, 1);
    } else if (len < 1549) {
        stats_add47(stats.rx.packet_1523_1548, 1);
    } else if (len < 2048) {
        stats_add47(stats.rx.packet_1549_2047, 1);
    } else if (len < 4096) {
        stats_add47(stats.rx.packet_2048_4095, 1);
    } else if (len < 8192) {
        stats_add47(stats.rx.packet_4096_8191, 1);
    } else if (len < 9216) {
        stats_add47(stats.rx.packet_8192_9215, 1);
    } else {
        stats_add47(stats.rx.packet_large, 1);
    }
}

void amd_dcmac_ethmac::stats_update64(unsigned reg, uint64_t &v)
{
    // Move accumulators into user accessible registers.
    rb.regs[reg] = v;
    rb.regs[reg + 1] = v >> 32;

    // Reset accumulators to zero.
    v = 0;
}

void amd_dcmac_ethmac::stats_update32(unsigned reg, uint64_t &v)
{
    // Move accumulators into user accessible registers.
    rb.regs[reg] = v & UINT32_MAX;

    // Reset accumulators to zero.
    v = 0;
}

void amd_dcmac_ethmac::stats_tx_ticked()
{
    stats_update32(R_C0_STAT_TX_PACKET_LARGE, stats.tx.packet_large);

    stats_update64(R_C0_STAT_TX_PACKET_64_BYTES_LSB, stats.tx.packet_64);
    stats_update64(R_C0_STAT_TX_PACKET_65_127_BYTES_LSB, stats.tx.packet_65_127);
    stats_update64(R_C0_STAT_TX_PACKET_128_255_BYTES_LSB, stats.tx.packet_128_255);
    stats_update64(R_C0_STAT_TX_PACKET_256_511_BYTES_LSB, stats.tx.packet_256_511);
    stats_update64(R_C0_STAT_TX_PACKET_512_1023_BYTES_LSB, stats.tx.packet_512_1023);
    stats_update64(R_C0_STAT_TX_PACKET_1024_1518_BYTES_LSB, stats.tx.packet_1024_1518);
    stats_update64(R_C0_STAT_TX_PACKET_1519_1522_BYTES_LSB, stats.tx.packet_1519_1522);
    stats_update64(R_C0_STAT_TX_PACKET_1523_1548_BYTES_LSB, stats.tx.packet_1523_1548);
    stats_update64(R_C0_STAT_TX_PACKET_1549_2047_BYTES_LSB, stats.tx.packet_1549_2047);
    stats_update64(R_C0_STAT_TX_PACKET_2048_4095_BYTES_LSB, stats.tx.packet_2048_4095);
    stats_update64(R_C0_STAT_TX_PACKET_4096_8191_BYTES_LSB, stats.tx.packet_4096_8191);
    stats_update64(R_C0_STAT_TX_PACKET_8192_9215_BYTES_LSB, stats.tx.packet_8192_9215);

    stats_update64(R_C0_STAT_TX_BAD_FCS_LSB, stats.tx.bad_fcs);

    stats_update64(R_C0_STAT_TX_UNICAST_LSB, stats.tx.unicast);
    stats_update64(R_C0_STAT_TX_MULTICAST_LSB, stats.tx.multicast);
    stats_update64(R_C0_STAT_TX_BROADCAST_LSB, stats.tx.broadcast);
    stats_update64(R_C0_STAT_TX_VLAN_LSB, stats.tx.vlan);
    stats_update64(R_C0_STAT_TX_PAUSE_LSB, stats.tx.pause);

    stats_update64(R_C0_STAT_TX_TOTAL_BYTES_LSB, stats.tx.total_bytes);
    stats_update64(R_C0_STAT_TX_TOTAL_GOOD_BYTES_LSB, stats.tx.total_good_bytes);
    stats_update64(R_C0_STAT_TX_TOTAL_PACKETS_LSB, stats.tx.total_packets);
    stats_update64(R_C0_STAT_TX_TOTAL_GOOD_PACKETS_LSB, stats.tx.total_good_packets);

    ARRAY_FIELD_DP(rb, C0_STAT_PORT_TX_STATISTICS_READY,
                   c0_stat_tx_port_statistics_ready, 1);
}

void amd_dcmac_ethmac::stats_rx_ticked()
{
    stats_update32(R_C0_STAT_RX_PACKET_LARGE, stats.rx.packet_large);

    stats_update64(R_C0_STAT_RX_PACKET_SMALL_LSB, stats.rx.packet_small);
    stats_update64(R_C0_STAT_RX_PACKET_64_BYTES_LSB, stats.rx.packet_64);
    stats_update64(R_C0_STAT_RX_PACKET_65_127_BYTES_LSB, stats.rx.packet_65_127);
    stats_update64(R_C0_STAT_RX_PACKET_128_255_BYTES_LSB, stats.rx.packet_128_255);
    stats_update64(R_C0_STAT_RX_PACKET_256_511_BYTES_LSB, stats.rx.packet_256_511);
    stats_update64(R_C0_STAT_RX_PACKET_512_1023_BYTES_LSB, stats.rx.packet_512_1023);
    stats_update64(R_C0_STAT_RX_PACKET_1024_1518_BYTES_LSB, stats.rx.packet_1024_1518);
    stats_update64(R_C0_STAT_RX_PACKET_1519_1522_BYTES_LSB, stats.rx.packet_1519_1522);
    stats_update64(R_C0_STAT_RX_PACKET_1523_1548_BYTES_LSB, stats.rx.packet_1523_1548);
    stats_update64(R_C0_STAT_RX_PACKET_1549_2047_BYTES_LSB, stats.rx.packet_1549_2047);
    stats_update64(R_C0_STAT_RX_PACKET_2048_4095_BYTES_LSB, stats.rx.packet_2048_4095);
    stats_update64(R_C0_STAT_RX_PACKET_4096_8191_BYTES_LSB, stats.rx.packet_4096_8191);
    stats_update64(R_C0_STAT_RX_PACKET_8192_9215_BYTES_LSB, stats.rx.packet_8192_9215);

    stats_update64(R_C0_STAT_RX_BAD_FCS_LSB, stats.rx.bad_fcs);

    stats_update64(R_C0_STAT_RX_UNICAST_LSB, stats.rx.unicast);
    stats_update64(R_C0_STAT_RX_MULTICAST_LSB, stats.rx.multicast);
    stats_update64(R_C0_STAT_RX_BROADCAST_LSB, stats.rx.broadcast);
    stats_update64(R_C0_STAT_RX_VLAN_LSB, stats.rx.vlan);
    stats_update64(R_C0_STAT_RX_PAUSE_LSB, stats.rx.pause);

    stats_update64(R_C0_STAT_RX_TOTAL_BYTES_LSB, stats.rx.total_bytes);
    stats_update64(R_C0_STAT_RX_TOTAL_GOOD_BYTES_LSB, stats.rx.total_good_bytes);
    stats_update64(R_C0_STAT_RX_TOTAL_PACKETS_LSB, stats.rx.total_packets);
    stats_update64(R_C0_STAT_RX_TOTAL_GOOD_PACKETS_LSB, stats.rx.total_good_packets);

    ARRAY_FIELD_DP(rb, C0_STAT_PORT_RX_STATISTICS_READY,
                   c0_stat_rx_port_statistics_ready, 1);
}

void amd_dcmac_ethmac::mac_b_transport(tlm::tlm_generic_payload& trans, sc_time& delay)
{
    unsigned char *data = trans.get_data_ptr();
    int len = trans.get_data_length();
    genattr_extension *genattr;
    bool eop = true;

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
            SC_REPORT_WARNING("dcmac_ethmac", "TX packet too small. Dropped\n");
            goto done;
        }

        if (cfgs_tx_fcs_insert()) {
            uint32_t crc = crc32(0, txbuf, txpos);
            memcpy(txbuf + txpos, &crc, sizeof(crc));
            txpos += sizeof(crc);
        } else if (cfgs_tx_fcs_check()) {
            uint32_t crc = crc32(0, txbuf, txpos - 4);
            uint32_t pkt_crc;

            memcpy(&pkt_crc, txbuf + txpos - 4, sizeof(pkt_crc));
            if (pkt_crc != crc) {
                stats_add47(stats.tx.bad_fcs, 1);
                good = false;
            }
        }

        if (good) {
            uint16_t type;

            stats_add47(stats.tx.total_good_packets, 1);
            stats_add53(stats.tx.total_good_bytes, txpos);
            stats_add47(stats.tx.unicast, eth_is_unicast(txbuf));
            stats_add47(stats.tx.multicast, eth_is_multicast(txbuf) && !eth_is_broadcast(txbuf));
            stats_add47(stats.tx.broadcast, eth_is_broadcast(txbuf));

            type = eth_get_type(txbuf);
            switch (type) {
            case ETH_HDR_TYPE_VLAN:
                stats_add47(stats.tx.vlan, 1);
                break;
            case ETH_HDR_TYPE_PAUSE:
                stats_add47(stats.tx.pause, 1);
                break;
            default:
                break;
            };
        }

        stats_add47(stats.tx.total_packets, 1);
        stats_add53(stats.tx.total_bytes, txpos);
        stats_update_tx_hist(txpos);

        push_stream(txbuf, txpos, true);
        D(hexdump("assembled mac tx", txbuf, txpos));
        txpos = 0;
    }

    D(printf("mac-tx %d done\n", trans.get_data_length()));
done:
    trans.set_response_status(tlm::TLM_OK_RESPONSE);
}

void amd_dcmac_ethmac::phy_rx_thread()
{
    while (true) {
        tlm::tlm_generic_payload *trans;
        sc_time delay = SC_ZERO_TIME;
        unsigned char *rxbuf;
        bool good = true;
        int len;

        trans = rxfifo.read();
        assert(trans);
        rxbuf = trans->get_data_ptr();
        len = trans->get_data_length();

        if (cfgs_rx_fcs_check()) {
            uint32_t crc = crc32(0, rxbuf, len - 4);
            uint32_t pkt_crc;

            memcpy(&pkt_crc, rxbuf + len - 4, sizeof(pkt_crc));
            if (pkt_crc != crc) {
                stats_add47(stats.rx.bad_fcs, 1);
                good = false;
            }
        }

        stats_add47(stats.rx.total_packets, 1);
        stats_add53(stats.rx.total_bytes, len);
        stats_update_rx_hist(len);

        if (good) {
            uint16_t type;

            stats_add47(stats.rx.total_good_packets, 1);
            stats_add53(stats.rx.total_good_bytes, len);
            stats_add47(stats.rx.unicast, eth_is_unicast(rxbuf));
            stats_add47(stats.rx.multicast, eth_is_multicast(rxbuf) && !eth_is_broadcast(rxbuf));
            stats_add47(stats.rx.broadcast, eth_is_broadcast(rxbuf));

            type = eth_get_type(rxbuf);
            switch (type) {
            case ETH_HDR_TYPE_VLAN:
                stats_add47(stats.rx.vlan, 1);
                break;
            case ETH_HDR_TYPE_PAUSE:
                stats_add47(stats.rx.pause, 1);
                break;
            default:
                break;
            };

            if (cfgs_rx_fcs_delete()) {
                // Specs says don't delete FCS for packets less or equal to 8 bytes long.
                if (len > 8) {
                    len -= 4;
                }
            }

            mac_rx_socket->b_transport(*trans, delay);
        }

        delete trans->get_data_ptr();
        delete trans;
    }
}

void amd_dcmac_ethmac::phy_b_transport(tlm::tlm_generic_payload& trans, sc_time& delay)
{
    tlm::tlm_generic_payload *gp = new tlm::tlm_generic_payload();
    int len = trans.get_data_length();
    unsigned char *buf = new unsigned char [len + 4];

    gp->set_data_ptr(buf);
    gp->deep_copy_from(trans);

    if (cfg.insert_rx_crc) {
        uint32_t crc = crc32(0, buf, len);
        memcpy(buf + len, &crc, sizeof(crc));
        len += sizeof(crc);
        gp->set_data_length(len);
    }

    if (rxfifo.num_free()) {
        rxfifo.write(gp);
    } else {
        // Packet-loss
    }
    trans.set_response_status(tlm::TLM_OK_RESPONSE);
}

void amd_dcmac_ethmac::reg_written(uint64_t addr)
{
    switch (addr) {
    case A_C0_TX_MODE_REG:
    case A_C0_RX_MODE_REG:
        mode_set.notify(SC_ZERO_TIME); // Wakes up global to enable/disable other ports
        break;
    case A_C0_PORT_TICK_REG_TX:
        if (ctls_tx_soft_pm_ticked()) {
            stats_tx_ticked();
        }
        break;
    case A_C0_PORT_TICK_REG_RX:
        if (ctls_rx_soft_pm_ticked()) {
            stats_rx_ticked();
        }
        break;
    }
}

void amd_dcmac_ethmac::reg_b_transport(tlm::tlm_generic_payload& tr, sc_time& delay)
{
    if (reg_read0(tr)) {
        return;
    }

    // Transfer data between transaction and reg-block
    rb.reg_b_transport(tr, delay);

    // Action(s) on write
    if (tr.is_write()) {
        reg_written(tr.get_address());
    }
}

bool amd_dcmac_ethmac::reg_read0(tlm::tlm_generic_payload& tr)
{
    // No-op when reset held in reset, e.g., disabled by global config
    if (!rst.read()) {
        return false;
    }

    if (tr.is_read()) {
        unsigned char *data = tr.get_data_ptr();
        int len = tr.get_data_length();
        memset(data, 0, len);
    }

    tr.set_response_status(tlm::TLM_OK_RESPONSE);
    return true;
}
