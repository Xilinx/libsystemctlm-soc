/*
 * Versal 600G DCMAC in Coupled MAC+PCS (FixedE) mode
 *
 * Copyright (c) 2025 Advanced Micro Devices Inc.
 *
 * SPDX-License-Identifier: MIT
 */
#ifndef SOC_ETH_XLNX_DCMAC_ETH_H_
#define SOC_ETH_XLNX_DCMAC_ETH_H_

#include <array>
#include <systemc>
using namespace sc_core;
using namespace sc_dt;

#include "tlm_utils/simple_target_socket.h"
#include "utils/regapi.h"
#include "dcmac-ethmac.h"

SC_MODULE(amd_dcmac_eth)
{
 public:
    SC_HAS_PROCESS(amd_dcmac_eth);

    sc_in<bool> rst;
    sc_vector<amd_dcmac_ethmac> mac;

    class reg_spec {
     public:
        uint64_t addr;
        uint64_t size;
        tlm::tlm_target_socket<>& sk;

        reg_spec(uint64_t a, uint64_t s, tlm::tlm_target_socket<>& t)
            : addr(a), size(s), sk(t) {}
    };
    std::vector<reg_spec> get_regs(uint64_t dev_base);

    amd_dcmac_eth(sc_core::sc_module_name name, bool insert_rx_crc = false);

 private:
    sc_vector<sc_signal<bool, SC_MANY_WRITERS>> mac_rst;
    bool cfg_insert_rx_crc;

    sc_event mode_set;
    void on_mode_set();

    amd_dcmac_ethmac *mac_item_creator(const char *name, size_t i) {
        return new amd_dcmac_ethmac(name, mode_set, cfg_insert_rx_crc);
    }

    // Device-level registers only (see public get_regs())
    regapi_block<uint32_t, R_ALL_CHANNEL_MAC_TICK_REG_TX + 1> rb;
    tlm_utils::simple_target_socket<amd_dcmac_eth> reg_socket;
    void reg_b_transport(tlm::tlm_generic_payload& tr, sc_time& delay);
    void reg_written(uint64_t addr);

    void on_reset();
    void soft_reset_tx();
    void soft_reset_rx();
    void mac_reset(unsigned port, bool v);
};
#endif
