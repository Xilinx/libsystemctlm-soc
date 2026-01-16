/*
 * Example and test for Versal 600G DCMAC in Coupled MAC+PCS (FixedE) mode
 *
 * Copyright (c) 2025 Advanced Micro Devices Inc.
 *
 * SPDX-License-Identifier: MIT
 */
#include <sstream>

#define SC_INCLUDE_DYNAMIC_PROCESSES
#include "soc/net/ethernet/xilinx/dcmac/dcmac-eth.h"

using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm-extensions/genattr.h"

#include "soc/interconnect/iconnect.h"
#include "soc/net/ethernet/ethernet.h"
#include "utils/crc32.h"

// Top simulation module.
SC_MODULE(Top)
{
    sc_clock clk;
    sc_signal<bool> rst;

    struct {
        uint64_t mac_rx;
        uint64_t phy_tx;
    } stats, stats_prev;

    unsigned char txbuf[10 * 1024];

    // Packet ports
    tlm_utils::simple_initiator_socket<Top> mac_tx_socket;
    tlm_utils::simple_target_socket<Top> mac_rx_socket;
    tlm_utils::simple_initiator_socket<Top> phy_rx_socket;
    tlm_utils::simple_target_socket<Top> phy_tx_socket;

    // mmio initiator
    tlm_utils::simple_initiator_socket<Top> reg_socket;

    // mmio targets
    iconnect<1, (1 + 2 * 6)> eth_regs;

    // dcmac in FixedE mode
    xilinx_dcmac_eth eth;

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

    void eth_bind_mmio(uint64_t dev_base) {
        // Connect all device's MMIO targets into a bus
        std::vector<xilinx_dcmac_eth::reg_spec> regs = eth.get_regs(dev_base);
        for (xilinx_dcmac_eth::reg_spec& r : regs) {
            eth_regs.memmap(r.addr, r.size, ADDRMODE_RELATIVE, -1, r.sk);
        }

        // Connect mmio initiator to the bus
        reg_socket.bind(*(eth_regs.t_sk[0]));
    }

    void eth_access(tlm::tlm_command cmd, uint64_t offset,
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

        // Send tr to dcmac's mmio dispatcher
        reg_socket->b_transport(tr, delay);
    }

    void eth_write32(uint64_t offset, uint32_t v) {
        eth_access(tlm::TLM_WRITE_COMMAND, offset, &v, 4);
    }

    uint32_t eth_read32(uint64_t offset) {
        uint32_t v;
        eth_access(tlm::TLM_READ_COMMAND, offset, &v, 4);
        return v;
    }

    uint64_t eth_read64(uint64_t offset) {
        uint64_t v64;
        uint32_t v32;

        eth_access(tlm::TLM_READ_COMMAND, offset + 4, &v32, 4);
        v64 = v32;
        v64 <<= 32;
        eth_access(tlm::TLM_READ_COMMAND, offset, &v32, 4);
        v64 |= v32;
        return v64;
    }

    // reg_* for accessing port-0 registers
    void reg_write32(uint64_t offset, uint32_t v) {
        eth_write32(A_C0_PORT_BASE + offset, v);
    }

    uint32_t reg_read32(uint64_t offset) {
        return eth_read32(A_C0_PORT_BASE + offset);
    }

    uint64_t reg_read64(uint64_t offset) {
        return eth_read64(A_C0_PORT_BASE + offset);
    }

    void reg_tick(void) {
        uint32_t v;

        reg_write32(A_C0_PORT_TICK_REG_TX,
                    R_C0_PORT_TICK_REG_TX_c0_tx_port_soft_pm_tick_MASK);
        // Wait for stats to become ready.
        do {
            v = reg_read32(A_C0_STAT_PORT_TX_STATISTICS_READY);
            v = FIELD_EX(v, C0_STAT_PORT_TX_STATISTICS_READY,
                         c0_stat_tx_port_statistics_ready);
        } while (!v);

        reg_write32(A_C0_PORT_TICK_REG_RX,
                    R_C0_PORT_TICK_REG_RX_c0_rx_port_soft_pm_tick_MASK);
        do {
            v = reg_read32(A_C0_STAT_PORT_RX_STATISTICS_READY);
            v = FIELD_EX(v, C0_STAT_PORT_RX_STATISTICS_READY,
                         c0_stat_rx_port_statistics_ready);
        } while (!v);
    }

    void check_tx_enabled() {
        printf("%s\n", __func__);

        stats_prev = stats;

        tx(mac_tx_socket, 64);
        assert(stats.phy_tx - stats_prev.phy_tx == 1);
        stats_prev = stats;
    }

    void check_tx_csum() {
    }

    void check_rx_csum() {
    }

    void check_tx_stats_hist() {
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
                daddr_type_reg = A_C0_STAT_TX_UNICAST_LSB;
                memset(txbuf, 0x00, ETH_ADDR_LEN);
            } else if (daddr_type == 1) {
                daddr_type_reg = A_C0_STAT_TX_MULTICAST_LSB;
                memset(txbuf, 0x01, ETH_ADDR_LEN);
            } else {
                daddr_type_reg = A_C0_STAT_TX_BROADCAST_LSB;
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
                v64 = 1;
            } else if (len == 64) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_64_BYTES_LSB);
            } else if (len < 128) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_65_127_BYTES_LSB);
            } else if (len < 256) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_128_255_BYTES_LSB);
            } else if (len < 512) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_256_511_BYTES_LSB);
            } else if (len < 1024) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_512_1023_BYTES_LSB);
            } else if (len < 1519) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_1024_1518_BYTES_LSB);
            } else if (len < 1523) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_1519_1522_BYTES_LSB);
            } else if (len < 1549) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_1523_1548_BYTES_LSB);
            } else if (len < 2048) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_1549_2047_BYTES_LSB);
            } else if (len < 4096) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_2048_4095_BYTES_LSB);
            } else if (len < 8192) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_4096_8191_BYTES_LSB);
            } else if (len < 9216) {
                v64 = reg_read64(A_C0_STAT_TX_PACKET_8192_9215_BYTES_LSB);
            } else {
                v64 = reg_read32(A_C0_STAT_TX_PACKET_LARGE);
            }
            //printf("len=%d v64=%ld\n", len, v64);
            assert(v64 == 1);

            v64 = reg_read64(daddr_type_reg);
            assert(v64 == 1);

            if (eth_type && len >= 14) {
                if (eth_type == 1) {
                    v64 = reg_read64(A_C0_STAT_TX_VLAN_LSB);
                } else if (eth_type == 2) {
                    v64 = reg_read64(A_C0_STAT_TX_PAUSE_LSB);
                }
                assert(v64 == 1);
            }
        }
        printf("\n");
    }

    void check_rx_stats_hist() {
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
                daddr_type_reg = A_C0_STAT_RX_UNICAST_LSB;
                memset(txbuf, 0x00, ETH_ADDR_LEN);
            } else if (daddr_type == 1) {
                daddr_type_reg = A_C0_STAT_RX_MULTICAST_LSB;
                memset(txbuf, 0x01, ETH_ADDR_LEN);
            } else {
                daddr_type_reg = A_C0_STAT_RX_BROADCAST_LSB;
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
                v64 = reg_read64(A_C0_STAT_RX_PACKET_SMALL_LSB);
            } else if (len == 64) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_64_BYTES_LSB);
            } else if (len < 128) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_65_127_BYTES_LSB);
            } else if (len < 256) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_128_255_BYTES_LSB);
            } else if (len < 512) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_256_511_BYTES_LSB);
            } else if (len < 1024) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_512_1023_BYTES_LSB);
            } else if (len < 1519) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_1024_1518_BYTES_LSB);
            } else if (len < 1523) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_1519_1522_BYTES_LSB);
            } else if (len < 1549) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_1523_1548_BYTES_LSB);
            } else if (len < 2048) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_1549_2047_BYTES_LSB);
            } else if (len < 4096) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_2048_4095_BYTES_LSB);
            } else if (len < 8192) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_4096_8191_BYTES_LSB);
            } else if (len < 9216) {
                v64 = reg_read64(A_C0_STAT_RX_PACKET_8192_9215_BYTES_LSB);
            } else {
                v64 = reg_read32(A_C0_STAT_RX_PACKET_LARGE);
            }
            //printf("len=%d v64=%ld\n", len, v64);
            assert(v64 == 1);

            v64 = reg_read64(daddr_type_reg);
            assert(v64 == 1);

            if (eth_type && len >= 14) {
                if (eth_type == 1) {
                    v64 = reg_read64(A_C0_STAT_RX_VLAN_LSB);
                } else if (eth_type == 2) {
                    v64 = reg_read64(A_C0_STAT_RX_PAUSE_LSB);
                }
                assert(v64 == 1);
            }
        }
        printf("\n");
    }

    void check_mmio() {
        printf("%s\n", __func__);

        // Sanity check the mmio register targets for their reset values
        assert(eth_read32(A_CONFIGURATION_REVISION) == 1);

        for (unsigned pn = 0; pn < 6; pn++) {
            uint64_t cb = A_C0_CHANNEL_BASE + pn * 0x1000;
            uint64_t pb = A_C0_PORT_BASE + pn * 0x1000;

            assert(eth_read32(cb + A_C0_CHANNEL_CONFIGURATION_TX) == 0xc03);
            assert(eth_read32(pb + A_C0_TX_MODE_REG) == 0x40220);
            printf(".");
        }
        printf("\n");
    }

    void check(void) {
        /* Pull the reset signal.  */
        rst.write(true);
        wait(1, SC_US);
        rst.write(false);
        wait(1, SC_US);

        check_mmio();
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
        mac_tx_socket("mac_tx_socket"),
        mac_rx_socket("mac_rx_socket"),
        phy_rx_socket("phy_rx_socket"),
        phy_tx_socket("phy_tx_socket"),
        reg_socket("reg_socket"),
        eth_regs("eth_regs"),
        eth("dcmac_eth")
    {
        memset(&stats, 0, sizeof(stats));
        memset(&stats_prev, 0, sizeof(stats_prev));

        SC_THREAD(check);

        eth.rst(rst);
        eth_bind_mmio(0);  // use of A_* offsets requires base at 0

        // Wire up port 0
        mac_tx_socket.bind(eth.mac[0].mac_tx_socket);
        mac_rx_socket.bind(eth.mac[0].mac_rx_socket);
        phy_rx_socket.bind(eth.mac[0].phy_rx_socket);
        phy_tx_socket.bind(eth.mac[0].phy_tx_socket);

        mac_rx_socket.register_b_transport(this, &Top::mac_b_transport);
        phy_tx_socket.register_b_transport(this, &Top::phy_b_transport);

        // Loop back unused ports to avoid 'port not bound' error
        for (unsigned pn = 1; pn < 6; pn++) {
            eth.mac[pn].mac_tx_socket.bind(eth.mac[pn].mac_rx_socket);
            eth.mac[pn].phy_tx_socket.bind(eth.mac[pn].phy_rx_socket);
        }
    }
};

int sc_main(int argc, char *argv[])
{
    Top top("Top");

    sc_start();

    return 0;
}
