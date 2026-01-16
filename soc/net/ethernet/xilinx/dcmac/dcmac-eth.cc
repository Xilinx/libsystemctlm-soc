/*
 * Versal 600G DCMAC in Coupled MAC+PCS mode
 *
 * Copyright (c) 2025 Advanced Micro Devices Inc.
 *
 * SPDX-License-Identifier: MIT
 */
#include <stdio.h>
#include <string>

#include "dcmac-eth.h"
#include "tlm-extensions/genattr.h"
#include "utils/regapi.h"

using namespace sc_core;
using namespace sc_dt;
using namespace std;

// Device-level registers affecting all eth ports
static const regapi_info<uint32_t> dcmac_eth_reginfo[] = {
#define VERSAL_600G_DCMAC_GREGS_INIT
#define R_STAT_TX_ECC_DROPPED
#include "dcmac-regs.h"
};

xilinx_dcmac_eth::xilinx_dcmac_eth(sc_module_name name, bool insert_rx_crc) :
    sc_module(name),
    rst("rst"),
    mac("mac"),
    mac_rst("mac_rst", 6),
    cfg_insert_rx_crc(insert_rx_crc),
    mode_set("mode_set"),
    rb("regs", dcmac_eth_reginfo),
    reg_socket("reg_socket")
{
    mac.init(6, sc_bind(&xilinx_dcmac_eth::mac_item_creator, this,
                        sc_unnamed::_1, sc_unnamed::_2));
    for (unsigned pn = 0; pn < 6; pn++) {
        mac[pn].rst.bind(mac_rst[pn]);
    }

    reg_socket.register_b_transport(this, &xilinx_dcmac_eth::reg_b_transport);

    SC_METHOD(on_mode_set);
    sensitive << mode_set;

    SC_METHOD(on_reset);
    sensitive << rst;
}

std::vector<xilinx_dcmac_eth::reg_spec> xilinx_dcmac_eth::get_regs(uint64_t dev_base)
{
    std::vector<xilinx_dcmac_eth::reg_spec> rbs;

    rbs.emplace_back(dev_base, sizeof(rb.regs), reg_socket);

    for (unsigned pn = 0; pn < 6; pn++) {
        uint64_t a = dev_base + pn * 0x1000;

        rbs.emplace_back((a + A_C0_CHANNEL_BASE), sizeof(mac[pn].crb.regs),
                         mac[pn].creg_socket);

        rbs.emplace_back((a + A_C0_PORT_BASE), sizeof(mac[pn].rb.regs),
                         mac[pn].reg_socket);
    }

    return rbs;
}

void xilinx_dcmac_eth::mac_reset(unsigned n, bool v)
{
    mac_rst[n].write(v);
}

void xilinx_dcmac_eth::on_reset()
{
    bool on = rst.posedge();

    // Reset device-level registers before resetting the macs
    if (on) {
        rb.reg_reset_all();
    }

    for (unsigned pn = 0; pn < 6; pn++) {
        mac_reset(pn, on);
    }
}

void xilinx_dcmac_eth::on_mode_set()
{
    unsigned dr[6] = {0};

    if (!mode_set.triggered()) {
        return;
    }

    // 400G: port 0 disables all other 5 ports
    dr[0] = mac[0].data_rate();
    if (dr[0] == 400) {
        for (unsigned pn = 1; pn <= 5; pn++) {
            mac_reset(pn, true);
        }
        return;
    }

    // 200G: 0/2/4 disables 1/3/5, respectively
    // 100G: all ports usable
    mac_reset(2, false);
    mac_reset(4, false);
    dr[2] = mac[2].data_rate();
    dr[4] = mac[4].data_rate();
    for (unsigned pn = 0; pn <= 4; pn += 2) {
        switch (dr[pn]) {
        case 200:
            mac_reset(pn + 1, true);
            break;
        case 100:
            mac_reset(pn + 1, false);
            break;
        }
    }
}

void xilinx_dcmac_eth::soft_reset_tx()
{
    bool c = ARRAY_FIELD_EX(rb.regs, GLOBAL_CONTROL_REG_TX, soft_tx_core_reset);
    bool m = ARRAY_FIELD_EX(rb.regs, GLOBAL_CONTROL_REG_TX, soft_tx_macif_reset);

    if (c || m) {
        for (unsigned pn = 0; pn < 6; pn++) {
            mac_reset(pn, true);
        }
    } else if (!c && !m) {
        for (unsigned pn = 0; pn < 6; pn++) {
            mac_reset(pn, false);
        }
    }
}

void xilinx_dcmac_eth::soft_reset_rx()
{
    bool c = ARRAY_FIELD_EX(rb.regs, GLOBAL_CONTROL_REG_RX, soft_rx_core_reset);
    bool m = ARRAY_FIELD_EX(rb.regs, GLOBAL_CONTROL_REG_RX, soft_rx_macif_reset);

    if (c || m) {
        for (unsigned pn = 0; pn < 6; pn++) {
            mac_reset(pn, true);
        }
    } else if (!c && !m) {
        for (unsigned pn = 0; pn < 6; pn++) {
            mac_reset(pn, false);
        }
    }
}

void xilinx_dcmac_eth::reg_written(uint64_t addr)
{
    switch (addr) {
    case A_GLOBAL_CONTROL_REG_TX:
        soft_reset_tx();
        break;
    case A_GLOBAL_CONTROL_REG_RX:
        soft_reset_rx();
        break;
    }
}

void xilinx_dcmac_eth::reg_b_transport(tlm::tlm_generic_payload& tr, sc_time& delay)
{
    // Transfer data between transaction and reg-block
    rb.reg_b_transport(tr, delay);

    // Action(s) on write
    if (tr.is_write()) {
        reg_written(tr.get_address());
    }
}
