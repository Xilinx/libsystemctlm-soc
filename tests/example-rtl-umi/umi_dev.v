/*
 * Wrapper around the UMI memory agent.
 *
 * Copyright (c) 2024 Zero ASIC.
 * Written by Edgar E. Iglesias
 *
 * SPDX-License-Identifier: MIT
 */

module umi_dev
    #(
        parameter DW = 64,
        parameter AW = 64
    )(
        input clk,
        input rst,

        input [31:0] udev_req_cmd,
        input [AW-1:0] udev_req_dstaddr,
        input [AW-1:0] udev_req_srcaddr,
        input [DW-1:0] udev_req_data,
        input udev_req_valid,
        output reg udev_req_ready,

        output reg [31:0] udev_resp_cmd,
        output reg [AW-1:0] udev_resp_dstaddr,
        output reg [AW-1:0] udev_resp_srcaddr,
        output reg [DW-1:0] udev_resp_data,
        output reg udev_resp_valid,
        input udev_resp_ready
    );
    wire nreset = ~rst;

    // See: submodules/umi/umi/rtl/umi_mem_agent.v
    wire [0:0] sram_ctrl;
    umi_mem_agent #(.AW(AW), .DW(DW), .CTRLW(1)) mem(.*);
endmodule
