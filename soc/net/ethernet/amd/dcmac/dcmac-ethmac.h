/*
 * Versal 600G DCMAC Ethernet port in Coupled MAC+PCS (FixedE) mode
 *
 * Copyright (c) 2025 Advanced Micro Devices Inc.
 *
 * SPDX-License-Identifier: MIT
 */
#ifndef SOC_ETH_XLNX_DCMAC_ETHPORT_H_
#define SOC_ETH_XLNX_DCMAC_ETHPORT_H_

#include <systemc>
#include <tlm>
#include "tlm-extensions/genattr.h"
#include "utils/regapi.h"
#include "dcmac-regs.h"

#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

class amd_dcmac_eth;

SC_MODULE(amd_dcmac_ethmac)
{
    friend amd_dcmac_eth;

 public:
    SC_HAS_PROCESS(amd_dcmac_ethmac);

    tlm_utils::simple_initiator_socket<amd_dcmac_ethmac> mac_rx_socket;
    tlm_utils::simple_target_socket<amd_dcmac_ethmac> mac_tx_socket;
    tlm_utils::simple_initiator_socket<amd_dcmac_ethmac> phy_tx_socket;
    tlm_utils::simple_target_socket<amd_dcmac_ethmac> phy_rx_socket;
    tlm_utils::simple_target_socket<amd_dcmac_ethmac> creg_socket;
    tlm_utils::simple_target_socket<amd_dcmac_ethmac> reg_socket;

    sc_core::sc_in<bool> rst;
    amd_dcmac_ethmac(sc_core::sc_module_name name,
                     sc_core::sc_event& mode_set_ev,
                     bool insert_rx_crc = false);

    unsigned data_rate() {
        unsigned tr = ARRAY_FIELD_EX(rb.regs, C0_TX_MODE_REG,
                                     c0_ctl_tx_data_rate);
        unsigned rr = ARRAY_FIELD_EX(rb.regs, C0_RX_MODE_REG,
                                     c0_ctl_rx_data_rate);

        switch (tr >= rr ? tr : rr) {
        case 0:
            return 100;
        case 1:
            return 200;
        default:
            return 400;
        }
    }

 private:
    sc_core::sc_event& mode_set;

    regapi_block<uint32_t, R_C0_CHANNEL_CONFIGURATION_RX + 1> crb;
    regapi_block<uint32_t, R_C0_STAT_RX_ECC_COUNT + 1> rb;
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

    sc_core::sc_fifo<tlm::tlm_generic_payload*> rxfifo;
    unsigned char txbuf[64 * 1024];
    unsigned int txpos;

    void stats_add(uint64_t &c, uint64_t v, uint64_t max) {
        if ((max - c) < v) {
            c = max; // Saturate.
            return;
        }

        c += v;
        c &= max;
    }

    void stats_add47(uint64_t &c, uint64_t v) {
        uint64_t uint47_max = (1ULL << 47) - 1;
        stats_add(c, v, uint47_max);
    }

    void stats_add53(uint64_t &c, uint64_t v) {
        uint64_t uint53_max = (1ULL << 53) - 1;
        stats_add(c, v, uint53_max);
    }

    void stats_update_tx_hist(unsigned len);
    void stats_update_rx_hist(unsigned len);
    void stats_update32(unsigned reg, uint64_t &v);
    void stats_update64(unsigned reg, uint64_t &v);
    void stats_tx_ticked();
    void stats_rx_ticked();

    bool cfgs_tx_fcs_insert() {
        return ARRAY_FIELD_EX(crb.regs, C0_CHANNEL_CONFIGURATION_TX,
                              c0_ctl_tx_fcs_ins_enable);
    }

    bool cfgs_tx_fcs_check() {
        return !ARRAY_FIELD_EX(crb.regs, C0_CHANNEL_CONFIGURATION_TX,
                               c0_ctl_tx_ignore_fcs);
    }

    bool cfgs_rx_fcs_delete() {
        return ARRAY_FIELD_EX(crb.regs, C0_CHANNEL_CONFIGURATION_RX,
                              c0_ctl_rx_delete_fcs);
    }

    bool cfgs_rx_fcs_check() {
        return !ARRAY_FIELD_EX(crb.regs, C0_CHANNEL_CONFIGURATION_RX,
                               c0_ctl_rx_ignore_fcs);
    }

    bool cfgs_tx_soft_pm_tick() {
        return !ARRAY_FIELD_EX(rb.regs, C0_TX_MODE_REG,
                               c0_ctl_tx_tick_reg_mode_sel);
    }

    bool cfgs_rx_soft_pm_tick() {
        return !ARRAY_FIELD_EX(rb.regs, C0_RX_MODE_REG,
                               c0_ctl_rx_tick_reg_mode_sel);
    }

    bool ctls_tx_soft_pm_ticked() {
        return cfgs_tx_soft_pm_tick()
               && ARRAY_FIELD_EX(rb.regs, C0_PORT_TICK_REG_TX,
                                 c0_tx_port_soft_pm_tick);
    }

    bool ctls_rx_soft_pm_ticked() {
        return cfgs_rx_soft_pm_tick()
               && ARRAY_FIELD_EX(rb.regs, C0_PORT_TICK_REG_RX,
                                 c0_rx_port_soft_pm_tick);
    }

    void on_reset();
    void push_stream(unsigned char *buf, int len, bool eop);
    void mac_b_transport(tlm::tlm_generic_payload& tr, sc_core::sc_time& delay);
    void phy_b_transport(tlm::tlm_generic_payload& tr, sc_core::sc_time& delay);
    void phy_rx_thread();

    void creg_b_transport(tlm::tlm_generic_payload& tr, sc_core::sc_time& delay);
    void reg_b_transport(tlm::tlm_generic_payload& tr, sc_core::sc_time& delay);
    void reg_written(uint64_t addr);
    bool reg_read0(tlm::tlm_generic_payload& tr);
};
#endif
