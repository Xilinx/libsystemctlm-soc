/*
 * Model of the AMD/Xilinx AXI DMA (PG021)
 *
 * Copyright (c) 2026 Advanced Micro Devices Inc.
 * SPDX-License-Identifier: MIT
 *
 * See axidma.cc heading block comment for supported features.
 */
#ifndef AMD_AXIDMA_H
#define AMD_AXIDMA_H

#include <memory>

#include <tlm>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>

class amd_axidma_;

class amd_axidma : public sc_core::sc_module {
public:
    // Discrete ports
    sc_core::sc_in<bool>  rst;
    sc_core::sc_out<bool> mm2s_irq;
    sc_core::sc_out<bool> s2mm_irq;

    // Host interface
    tlm_utils::simple_initiator_socket<amd_axidma_>dma_init_socket;
    tlm_utils::simple_target_socket<amd_axidma_>regs_target_socket;

    // MM2S channel: control-stream relays 'APP' data from SOF descriptor
    tlm_utils::simple_initiator_socket<amd_axidma_> mm2s_stream_socket;
    tlm_utils::simple_initiator_socket<amd_axidma_> mm2s_control_stream_socket;

    // S2MM channel: status-stream relays 'APP' data to EOF descriptor
    // data-stream:
    // 1. SOF inferred by last EOP
    // 2. Entire packet inferred if missing generic extension
    // 1. Drop by insufficient sg-descriptors
    // 2. Drop ungracefully by hard and soft resets.
    tlm_utils::simple_target_socket<amd_axidma_> s2mm_stream_socket;
    tlm_utils::simple_target_socket<amd_axidma_> s2mm_status_stream_socket;

    amd_axidma(sc_core::sc_module_name name,
                  // Selectable IP-block config options:
                  bool mode_sg=true,  // c_include_sg
                  bool addr_32=false, // c_addr_width
                  sc_dt::uint64 clk_in_hz=(50*1000*1000));

    ~amd_axidma();  // For PImpl pattern

private:
    // Use PImpl pattern to declutter the sizable implementation from
    // header given that this module is not expected to be inherited.
    std::unique_ptr<amd_axidma_> impl_;
};
#endif
