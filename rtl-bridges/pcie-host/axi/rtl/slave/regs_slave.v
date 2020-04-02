/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Kunal Varshney. 
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy 
 * of this software and associated documentation files (the 'Software'), to deal 
 * in the Software without restriction, including without limitation the rights 
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 * copies of the Software, and to permit persons to whom the Software is 
 * furnished to do so, subject to the following conditions: 
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 * Description: 
 *   This Module Implements Register Module for Slave Bridge for 128KB memory requirement.
 *
 *
 */


`include "defines_common.vh"
`include "defines_slave_regspace.vh"
module regs_slave #(
                     parameter EN_INTFS_AXI4            = 1, 
                     parameter EN_INTFS_AXI4LITE        = 0, 
                     parameter EN_INTFS_AXI3            = 0, 
                        
                     parameter S_AXI_ADDR_WIDTH         = 64,
                     parameter S_AXI_DATA_WIDTH         = 32,
                     parameter RAM_SIZE                 = 16384,
                     parameter MAX_DESC                 = 16,
                     parameter S_AXI_USR_DATA_WIDTH     = 128, 
                     parameter S_AXI_USR_ADDR_WIDTH     = 64,    
                     parameter S_AXI_USR_ID_WIDTH       = 4,  
                     parameter S_AXI_USR_AWUSER_WIDTH   = 32,    
                     parameter S_AXI_USR_WUSER_WIDTH    = 32,    
                     parameter S_AXI_USR_BUSER_WIDTH    = 32,    
                     parameter S_AXI_USR_ARUSER_WIDTH   = 32,    
                     parameter S_AXI_USR_RUSER_WIDTH    = 32,
                     parameter PCIE_AXI                 = 0, 
                     parameter PCIE_LAST_BRIDGE         = 0,
		     parameter LAST_BRIDGE              = 0,
		     parameter EXTEND_WSTRB             = 1, 
                     parameter FORCE_RESP_ORDER         = 1


                    )
   (
    input                                                   axi_aclk,
    input                                                   axi_aresetn, // Top level AXI reset. Typically derived from Reset issued by Pcie Host. Drives AXI FSM and 'reset_reg' of this module.
    input                                                   rst_n, // combination of 'axi_aresetn' and Bridge SRST. Drives all Regs and RAMs in this module. 

    // S_AXI - AXI4-Lite
    input wire [S_AXI_ADDR_WIDTH-1:0]                       s_axi_awaddr,
    input wire [2:0]                                        s_axi_awprot,
    input wire                                              s_axi_awvalid,
    output wire                                             s_axi_awready,
    input wire [S_AXI_DATA_WIDTH-1:0]                       s_axi_wdata,
    input wire [(S_AXI_DATA_WIDTH/8)-1:0]                   s_axi_wstrb,
    input wire                                              s_axi_wvalid,
    output wire                                             s_axi_wready,
    output wire [1:0]                                       s_axi_bresp,
    output wire                                             s_axi_bvalid,
    input wire                                              s_axi_bready,
    input wire [S_AXI_ADDR_WIDTH-1:0]                       s_axi_araddr,
    input wire [2:0]                                        s_axi_arprot,
    input wire                                              s_axi_arvalid,
    output wire                                             s_axi_arready,
    output wire [S_AXI_DATA_WIDTH-1:0]                      s_axi_rdata,
    output wire [1:0]                                       s_axi_rresp,
    output wire                                             s_axi_rvalid,
    input wire                                              s_axi_rready,

    //RDATA_RAM
    input [(`CLOG2((RAM_SIZE*8)/S_AXI_USR_DATA_WIDTH))-1:0] uc2rb_rd_addr , 
    output [S_AXI_USR_DATA_WIDTH-1:0]                       rb2uc_rd_data , 

    //WDATA_RAM and WSTRB_RAM                               
    input                                                   uc2rb_wr_we , 
    input [(S_AXI_USR_DATA_WIDTH/8)-1:0]                    uc2rb_wr_bwe , 
    input [(`CLOG2((RAM_SIZE*8)/S_AXI_USR_DATA_WIDTH))-1:0] uc2rb_wr_addr , 
    input [S_AXI_USR_DATA_WIDTH-1:0]                        uc2rb_wr_data , 
    input [(S_AXI_USR_DATA_WIDTH/8)-1:0]                    uc2rb_wr_wstrb ,

    // Mode 1 Signals
    // Read port of WR DataRam
    input [(`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8)))-1:0] hm2rb_rd_addr, 
    output reg [S_AXI_USR_DATA_WIDTH-1:0]                   rb2hm_rd_data, 
    output reg [(S_AXI_USR_DATA_WIDTH/8 -1):0]              rb2hm_rd_wstrb,
    // Write port of RD DataRam
    input                                                   hm2rb_wr_we, 
    input [(S_AXI_USR_DATA_WIDTH/8 -1):0]                   hm2rb_wr_bwe, 
    input [(`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8)))-1:0] hm2rb_wr_addr, 
    input [S_AXI_USR_DATA_WIDTH-1:0]                        hm2rb_wr_data,

    input  [MAX_DESC-1:0]                                   uc2hm_trig ,
    input [MAX_DESC-1:0]                                    hm2uc_done,

// Registers
	output reg [31:0] 										bridge_identification_reg ,
    output reg [31:0] 										bridge_position_reg ,
    output reg [31:0]                                       version_reg , 
    output reg [31:0]                                       bridge_type_reg , 
    output reg [31:0]                                       mode_select_reg , 
    output reg [31:0]                                       reset_reg , 
    output reg [31:0] 										h2c_intr_0_reg ,
    output reg [31:0] 										h2c_intr_1_reg ,
	output reg [31:0] 										h2c_intr_2_reg ,
    output reg [31:0] 										h2c_intr_3_reg ,
    output reg [31:0] 										c2h_intr_status_0_reg ,
    output reg [31:0] 										c2h_intr_status_1_reg ,
	output reg [31:0] 										intr_c2h_toggle_enable_0_reg ,
    output reg [31:0] 										intr_c2h_toggle_enable_1_reg ,
	output reg [31:0] 										intr_c2h_toggle_status_0_reg ,
	output reg [31:0] 										intr_c2h_toggle_status_1_reg ,
	output reg [31:0] 										intr_c2h_toggle_clear_0_reg ,
    output reg [31:0] 										intr_c2h_toggle_clear_1_reg ,
    output reg [31:0] 										h2c_pulse_0_reg ,
    output reg [31:0] 										h2c_pulse_1_reg ,
	
    output reg [31:0] 										c2h_gpio_0_reg ,
    output reg [31:0] 										c2h_gpio_1_reg ,
    output reg [31:0] 										c2h_gpio_2_reg ,
    output reg [31:0] 										c2h_gpio_3_reg ,
    output reg [31:0] 										c2h_gpio_4_reg ,
    output reg [31:0] 										c2h_gpio_5_reg ,
    output reg [31:0] 										c2h_gpio_6_reg ,
    output reg [31:0] 										c2h_gpio_7_reg ,
    output reg [31:0] 										c2h_gpio_8_reg ,
    output reg [31:0] 										c2h_gpio_9_reg ,
    output reg [31:0] 										c2h_gpio_10_reg ,
    output reg [31:0] 										c2h_gpio_11_reg ,
    output reg [31:0] 										c2h_gpio_12_reg ,
    output reg [31:0] 										c2h_gpio_13_reg ,
    output reg [31:0] 										c2h_gpio_14_reg ,
    output reg [31:0] 										c2h_gpio_15_reg ,
	output reg [31:0] 										h2c_gpio_0_reg ,
    output reg [31:0] 										h2c_gpio_1_reg ,
    output reg [31:0] 										h2c_gpio_2_reg ,
    output reg [31:0] 										h2c_gpio_3_reg ,
    output reg [31:0] 										h2c_gpio_4_reg ,
    output reg [31:0] 										h2c_gpio_5_reg ,
    output reg [31:0] 										h2c_gpio_6_reg ,
    output reg [31:0] 										h2c_gpio_7_reg ,
    output reg [31:0] 										h2c_gpio_8_reg ,
    output reg [31:0] 										h2c_gpio_9_reg ,
    output reg [31:0] 										h2c_gpio_10_reg ,
    output reg [31:0] 										h2c_gpio_11_reg ,
    output reg [31:0] 										h2c_gpio_12_reg ,
    output reg [31:0] 										h2c_gpio_13_reg ,
    output reg [31:0] 										h2c_gpio_14_reg ,
    output reg [31:0] 										h2c_gpio_15_reg ,
    output reg [31:0]                                       axi_bridge_config_reg , 
    output reg [31:0]                                       axi_max_desc_reg , 
    output reg [31:0]                                       intr_status_reg , 
    output reg [31:0]                                       intr_error_status_reg , 
    output reg [31:0]                                       intr_error_clear_reg , 
    output reg [31:0]                                       intr_error_enable_reg , 
    output reg [31:0]                                       bridge_rd_user_config_reg ,
    output reg [31:0]                                       bridge_wr_user_config_reg ,
    output reg [31:0]                                       addr_in_0_reg , 
    output reg [31:0]                                       addr_in_1_reg , 
    output reg [31:0]                                       addr_in_2_reg , 
    output reg [31:0]                                       addr_in_3_reg , 
    output reg [31:0]                                       trans_mask_0_reg , 
    output reg [31:0]                                       trans_mask_1_reg , 
    output reg [31:0]                                       trans_mask_2_reg , 
    output reg [31:0]                                       trans_mask_3_reg , 
    output reg [31:0]                                       trans_addr_0_reg , 
    output reg [31:0]                                       trans_addr_1_reg , 
    output reg [31:0]                                       trans_addr_2_reg , 
    output reg [31:0]                                       trans_addr_3_reg , 
    output reg [31:0]                                       ownership_reg , 
    output reg [31:0]                                       ownership_flip_reg , 
    output reg [31:0]                                       status_resp_reg , 
    output reg [31:0]                                       intr_txn_avail_status_reg , 
    output reg [31:0]                                       intr_txn_avail_clear_reg , 
    output reg [31:0]                                       intr_txn_avail_enable_reg , 
    output reg [31:0]                                       intr_comp_status_reg , 
    output reg [31:0]                                       intr_comp_clear_reg , 
    output reg [31:0]                                       intr_comp_enable_reg , 
    output reg [31:0]                                       status_resp_comp_reg , 
    output reg [31:0]                                       status_busy_reg , 
    output reg [31:0]                                       resp_order_reg ,
    output reg [31:0]                                       resp_fifo_free_level_reg , 
    output reg [31:0]                                       desc_0_txn_type_reg , 
    output reg [31:0]                                       desc_0_size_reg , 
    output reg [31:0]                                       desc_0_data_offset_reg , 
    output reg [31:0]                                       desc_0_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_0_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_0_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_0_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_0_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_0_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_0_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_0_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_0_axsize_reg , 
    output reg [31:0]                                       desc_0_attr_reg , 
    output reg [31:0]                                       desc_0_axaddr_0_reg , 
    output reg [31:0]                                       desc_0_axaddr_1_reg , 
    output reg [31:0]                                       desc_0_axaddr_2_reg , 
    output reg [31:0]                                       desc_0_axaddr_3_reg , 
    output reg [31:0]                                       desc_0_axid_0_reg , 
    output reg [31:0]                                       desc_0_axid_1_reg , 
    output reg [31:0]                                       desc_0_axid_2_reg , 
    output reg [31:0]                                       desc_0_axid_3_reg , 
    output reg [31:0]                                       desc_0_axuser_0_reg , 
    output reg [31:0]                                       desc_0_axuser_1_reg , 
    output reg [31:0]                                       desc_0_axuser_2_reg , 
    output reg [31:0]                                       desc_0_axuser_3_reg , 
    output reg [31:0]                                       desc_0_axuser_4_reg , 
    output reg [31:0]                                       desc_0_axuser_5_reg , 
    output reg [31:0]                                       desc_0_axuser_6_reg , 
    output reg [31:0]                                       desc_0_axuser_7_reg , 
    output reg [31:0]                                       desc_0_axuser_8_reg , 
    output reg [31:0]                                       desc_0_axuser_9_reg , 
    output reg [31:0]                                       desc_0_axuser_10_reg , 
    output reg [31:0]                                       desc_0_axuser_11_reg , 
    output reg [31:0]                                       desc_0_axuser_12_reg , 
    output reg [31:0]                                       desc_0_axuser_13_reg , 
    output reg [31:0]                                       desc_0_axuser_14_reg , 
    output reg [31:0]                                       desc_0_axuser_15_reg , 
    output reg [31:0]                                       desc_0_xuser_0_reg , 
    output reg [31:0]                                       desc_0_xuser_1_reg , 
    output reg [31:0]                                       desc_0_xuser_2_reg , 
    output reg [31:0]                                       desc_0_xuser_3_reg , 
    output reg [31:0]                                       desc_0_xuser_4_reg , 
    output reg [31:0]                                       desc_0_xuser_5_reg , 
    output reg [31:0]                                       desc_0_xuser_6_reg , 
    output reg [31:0]                                       desc_0_xuser_7_reg , 
    output reg [31:0]                                       desc_0_xuser_8_reg , 
    output reg [31:0]                                       desc_0_xuser_9_reg , 
    output reg [31:0]                                       desc_0_xuser_10_reg , 
    output reg [31:0]                                       desc_0_xuser_11_reg , 
    output reg [31:0]                                       desc_0_xuser_12_reg , 
    output reg [31:0]                                       desc_0_xuser_13_reg , 
    output reg [31:0]                                       desc_0_xuser_14_reg , 
    output reg [31:0]                                       desc_0_xuser_15_reg , 
    output reg [31:0]                                       desc_0_wuser_0_reg , 
    output reg [31:0]                                       desc_0_wuser_1_reg , 
    output reg [31:0]                                       desc_0_wuser_2_reg , 
    output reg [31:0]                                       desc_0_wuser_3_reg , 
    output reg [31:0]                                       desc_0_wuser_4_reg , 
    output reg [31:0]                                       desc_0_wuser_5_reg , 
    output reg [31:0]                                       desc_0_wuser_6_reg , 
    output reg [31:0]                                       desc_0_wuser_7_reg , 
    output reg [31:0]                                       desc_0_wuser_8_reg , 
    output reg [31:0]                                       desc_0_wuser_9_reg , 
    output reg [31:0]                                       desc_0_wuser_10_reg , 
    output reg [31:0]                                       desc_0_wuser_11_reg , 
    output reg [31:0]                                       desc_0_wuser_12_reg , 
    output reg [31:0]                                       desc_0_wuser_13_reg , 
    output reg [31:0]                                       desc_0_wuser_14_reg , 
    output reg [31:0]                                       desc_0_wuser_15_reg , 
    output reg [31:0]                                       desc_1_txn_type_reg , 
    output reg [31:0]                                       desc_1_size_reg , 
    output reg [31:0]                                       desc_1_data_offset_reg , 
    output reg [31:0]                                       desc_1_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_1_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_1_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_1_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_1_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_1_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_1_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_1_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_1_axsize_reg , 
    output reg [31:0]                                       desc_1_attr_reg , 
    output reg [31:0]                                       desc_1_axaddr_0_reg , 
    output reg [31:0]                                       desc_1_axaddr_1_reg , 
    output reg [31:0]                                       desc_1_axaddr_2_reg , 
    output reg [31:0]                                       desc_1_axaddr_3_reg , 
    output reg [31:0]                                       desc_1_axid_0_reg , 
    output reg [31:0]                                       desc_1_axid_1_reg , 
    output reg [31:0]                                       desc_1_axid_2_reg , 
    output reg [31:0]                                       desc_1_axid_3_reg , 
    output reg [31:0]                                       desc_1_axuser_0_reg , 
    output reg [31:0]                                       desc_1_axuser_1_reg , 
    output reg [31:0]                                       desc_1_axuser_2_reg , 
    output reg [31:0]                                       desc_1_axuser_3_reg , 
    output reg [31:0]                                       desc_1_axuser_4_reg , 
    output reg [31:0]                                       desc_1_axuser_5_reg , 
    output reg [31:0]                                       desc_1_axuser_6_reg , 
    output reg [31:0]                                       desc_1_axuser_7_reg , 
    output reg [31:0]                                       desc_1_axuser_8_reg , 
    output reg [31:0]                                       desc_1_axuser_9_reg , 
    output reg [31:0]                                       desc_1_axuser_10_reg , 
    output reg [31:0]                                       desc_1_axuser_11_reg , 
    output reg [31:0]                                       desc_1_axuser_12_reg , 
    output reg [31:0]                                       desc_1_axuser_13_reg , 
    output reg [31:0]                                       desc_1_axuser_14_reg , 
    output reg [31:0]                                       desc_1_axuser_15_reg , 
    output reg [31:0]                                       desc_1_xuser_0_reg , 
    output reg [31:0]                                       desc_1_xuser_1_reg , 
    output reg [31:0]                                       desc_1_xuser_2_reg , 
    output reg [31:0]                                       desc_1_xuser_3_reg , 
    output reg [31:0]                                       desc_1_xuser_4_reg , 
    output reg [31:0]                                       desc_1_xuser_5_reg , 
    output reg [31:0]                                       desc_1_xuser_6_reg , 
    output reg [31:0]                                       desc_1_xuser_7_reg , 
    output reg [31:0]                                       desc_1_xuser_8_reg , 
    output reg [31:0]                                       desc_1_xuser_9_reg , 
    output reg [31:0]                                       desc_1_xuser_10_reg , 
    output reg [31:0]                                       desc_1_xuser_11_reg , 
    output reg [31:0]                                       desc_1_xuser_12_reg , 
    output reg [31:0]                                       desc_1_xuser_13_reg , 
    output reg [31:0]                                       desc_1_xuser_14_reg , 
    output reg [31:0]                                       desc_1_xuser_15_reg , 
    output reg [31:0]                                       desc_1_wuser_0_reg , 
    output reg [31:0]                                       desc_1_wuser_1_reg , 
    output reg [31:0]                                       desc_1_wuser_2_reg , 
    output reg [31:0]                                       desc_1_wuser_3_reg , 
    output reg [31:0]                                       desc_1_wuser_4_reg , 
    output reg [31:0]                                       desc_1_wuser_5_reg , 
    output reg [31:0]                                       desc_1_wuser_6_reg , 
    output reg [31:0]                                       desc_1_wuser_7_reg , 
    output reg [31:0]                                       desc_1_wuser_8_reg , 
    output reg [31:0]                                       desc_1_wuser_9_reg , 
    output reg [31:0]                                       desc_1_wuser_10_reg , 
    output reg [31:0]                                       desc_1_wuser_11_reg , 
    output reg [31:0]                                       desc_1_wuser_12_reg , 
    output reg [31:0]                                       desc_1_wuser_13_reg , 
    output reg [31:0]                                       desc_1_wuser_14_reg , 
    output reg [31:0]                                       desc_1_wuser_15_reg , 
    output reg [31:0]                                       desc_2_txn_type_reg , 
    output reg [31:0]                                       desc_2_size_reg , 
    output reg [31:0]                                       desc_2_data_offset_reg , 
    output reg [31:0]                                       desc_2_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_2_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_2_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_2_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_2_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_2_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_2_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_2_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_2_axsize_reg , 
    output reg [31:0]                                       desc_2_attr_reg , 
    output reg [31:0]                                       desc_2_axaddr_0_reg , 
    output reg [31:0]                                       desc_2_axaddr_1_reg , 
    output reg [31:0]                                       desc_2_axaddr_2_reg , 
    output reg [31:0]                                       desc_2_axaddr_3_reg , 
    output reg [31:0]                                       desc_2_axid_0_reg , 
    output reg [31:0]                                       desc_2_axid_1_reg , 
    output reg [31:0]                                       desc_2_axid_2_reg , 
    output reg [31:0]                                       desc_2_axid_3_reg , 
    output reg [31:0]                                       desc_2_axuser_0_reg , 
    output reg [31:0]                                       desc_2_axuser_1_reg , 
    output reg [31:0]                                       desc_2_axuser_2_reg , 
    output reg [31:0]                                       desc_2_axuser_3_reg , 
    output reg [31:0]                                       desc_2_axuser_4_reg , 
    output reg [31:0]                                       desc_2_axuser_5_reg , 
    output reg [31:0]                                       desc_2_axuser_6_reg , 
    output reg [31:0]                                       desc_2_axuser_7_reg , 
    output reg [31:0]                                       desc_2_axuser_8_reg , 
    output reg [31:0]                                       desc_2_axuser_9_reg , 
    output reg [31:0]                                       desc_2_axuser_10_reg , 
    output reg [31:0]                                       desc_2_axuser_11_reg , 
    output reg [31:0]                                       desc_2_axuser_12_reg , 
    output reg [31:0]                                       desc_2_axuser_13_reg , 
    output reg [31:0]                                       desc_2_axuser_14_reg , 
    output reg [31:0]                                       desc_2_axuser_15_reg , 
    output reg [31:0]                                       desc_2_xuser_0_reg , 
    output reg [31:0]                                       desc_2_xuser_1_reg , 
    output reg [31:0]                                       desc_2_xuser_2_reg , 
    output reg [31:0]                                       desc_2_xuser_3_reg , 
    output reg [31:0]                                       desc_2_xuser_4_reg , 
    output reg [31:0]                                       desc_2_xuser_5_reg , 
    output reg [31:0]                                       desc_2_xuser_6_reg , 
    output reg [31:0]                                       desc_2_xuser_7_reg , 
    output reg [31:0]                                       desc_2_xuser_8_reg , 
    output reg [31:0]                                       desc_2_xuser_9_reg , 
    output reg [31:0]                                       desc_2_xuser_10_reg , 
    output reg [31:0]                                       desc_2_xuser_11_reg , 
    output reg [31:0]                                       desc_2_xuser_12_reg , 
    output reg [31:0]                                       desc_2_xuser_13_reg , 
    output reg [31:0]                                       desc_2_xuser_14_reg , 
    output reg [31:0]                                       desc_2_xuser_15_reg , 
    output reg [31:0]                                       desc_2_wuser_0_reg , 
    output reg [31:0]                                       desc_2_wuser_1_reg , 
    output reg [31:0]                                       desc_2_wuser_2_reg , 
    output reg [31:0]                                       desc_2_wuser_3_reg , 
    output reg [31:0]                                       desc_2_wuser_4_reg , 
    output reg [31:0]                                       desc_2_wuser_5_reg , 
    output reg [31:0]                                       desc_2_wuser_6_reg , 
    output reg [31:0]                                       desc_2_wuser_7_reg , 
    output reg [31:0]                                       desc_2_wuser_8_reg , 
    output reg [31:0]                                       desc_2_wuser_9_reg , 
    output reg [31:0]                                       desc_2_wuser_10_reg , 
    output reg [31:0]                                       desc_2_wuser_11_reg , 
    output reg [31:0]                                       desc_2_wuser_12_reg , 
    output reg [31:0]                                       desc_2_wuser_13_reg , 
    output reg [31:0]                                       desc_2_wuser_14_reg , 
    output reg [31:0]                                       desc_2_wuser_15_reg , 
    output reg [31:0]                                       desc_3_txn_type_reg , 
    output reg [31:0]                                       desc_3_size_reg , 
    output reg [31:0]                                       desc_3_data_offset_reg , 
    output reg [31:0]                                       desc_3_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_3_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_3_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_3_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_3_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_3_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_3_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_3_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_3_axsize_reg , 
    output reg [31:0]                                       desc_3_attr_reg , 
    output reg [31:0]                                       desc_3_axaddr_0_reg , 
    output reg [31:0]                                       desc_3_axaddr_1_reg , 
    output reg [31:0]                                       desc_3_axaddr_2_reg , 
    output reg [31:0]                                       desc_3_axaddr_3_reg , 
    output reg [31:0]                                       desc_3_axid_0_reg , 
    output reg [31:0]                                       desc_3_axid_1_reg , 
    output reg [31:0]                                       desc_3_axid_2_reg , 
    output reg [31:0]                                       desc_3_axid_3_reg , 
    output reg [31:0]                                       desc_3_axuser_0_reg , 
    output reg [31:0]                                       desc_3_axuser_1_reg , 
    output reg [31:0]                                       desc_3_axuser_2_reg , 
    output reg [31:0]                                       desc_3_axuser_3_reg , 
    output reg [31:0]                                       desc_3_axuser_4_reg , 
    output reg [31:0]                                       desc_3_axuser_5_reg , 
    output reg [31:0]                                       desc_3_axuser_6_reg , 
    output reg [31:0]                                       desc_3_axuser_7_reg , 
    output reg [31:0]                                       desc_3_axuser_8_reg , 
    output reg [31:0]                                       desc_3_axuser_9_reg , 
    output reg [31:0]                                       desc_3_axuser_10_reg , 
    output reg [31:0]                                       desc_3_axuser_11_reg , 
    output reg [31:0]                                       desc_3_axuser_12_reg , 
    output reg [31:0]                                       desc_3_axuser_13_reg , 
    output reg [31:0]                                       desc_3_axuser_14_reg , 
    output reg [31:0]                                       desc_3_axuser_15_reg , 
    output reg [31:0]                                       desc_3_xuser_0_reg , 
    output reg [31:0]                                       desc_3_xuser_1_reg , 
    output reg [31:0]                                       desc_3_xuser_2_reg , 
    output reg [31:0]                                       desc_3_xuser_3_reg , 
    output reg [31:0]                                       desc_3_xuser_4_reg , 
    output reg [31:0]                                       desc_3_xuser_5_reg , 
    output reg [31:0]                                       desc_3_xuser_6_reg , 
    output reg [31:0]                                       desc_3_xuser_7_reg , 
    output reg [31:0]                                       desc_3_xuser_8_reg , 
    output reg [31:0]                                       desc_3_xuser_9_reg , 
    output reg [31:0]                                       desc_3_xuser_10_reg , 
    output reg [31:0]                                       desc_3_xuser_11_reg , 
    output reg [31:0]                                       desc_3_xuser_12_reg , 
    output reg [31:0]                                       desc_3_xuser_13_reg , 
    output reg [31:0]                                       desc_3_xuser_14_reg , 
    output reg [31:0]                                       desc_3_xuser_15_reg , 
    output reg [31:0]                                       desc_3_wuser_0_reg , 
    output reg [31:0]                                       desc_3_wuser_1_reg , 
    output reg [31:0]                                       desc_3_wuser_2_reg , 
    output reg [31:0]                                       desc_3_wuser_3_reg , 
    output reg [31:0]                                       desc_3_wuser_4_reg , 
    output reg [31:0]                                       desc_3_wuser_5_reg , 
    output reg [31:0]                                       desc_3_wuser_6_reg , 
    output reg [31:0]                                       desc_3_wuser_7_reg , 
    output reg [31:0]                                       desc_3_wuser_8_reg , 
    output reg [31:0]                                       desc_3_wuser_9_reg , 
    output reg [31:0]                                       desc_3_wuser_10_reg , 
    output reg [31:0]                                       desc_3_wuser_11_reg , 
    output reg [31:0]                                       desc_3_wuser_12_reg , 
    output reg [31:0]                                       desc_3_wuser_13_reg , 
    output reg [31:0]                                       desc_3_wuser_14_reg , 
    output reg [31:0]                                       desc_3_wuser_15_reg , 
    output reg [31:0]                                       desc_4_txn_type_reg , 
    output reg [31:0]                                       desc_4_size_reg , 
    output reg [31:0]                                       desc_4_data_offset_reg , 
    output reg [31:0]                                       desc_4_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_4_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_4_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_4_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_4_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_4_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_4_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_4_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_4_axsize_reg , 
    output reg [31:0]                                       desc_4_attr_reg , 
    output reg [31:0]                                       desc_4_axaddr_0_reg , 
    output reg [31:0]                                       desc_4_axaddr_1_reg , 
    output reg [31:0]                                       desc_4_axaddr_2_reg , 
    output reg [31:0]                                       desc_4_axaddr_3_reg , 
    output reg [31:0]                                       desc_4_axid_0_reg , 
    output reg [31:0]                                       desc_4_axid_1_reg , 
    output reg [31:0]                                       desc_4_axid_2_reg , 
    output reg [31:0]                                       desc_4_axid_3_reg , 
    output reg [31:0]                                       desc_4_axuser_0_reg , 
    output reg [31:0]                                       desc_4_axuser_1_reg , 
    output reg [31:0]                                       desc_4_axuser_2_reg , 
    output reg [31:0]                                       desc_4_axuser_3_reg , 
    output reg [31:0]                                       desc_4_axuser_4_reg , 
    output reg [31:0]                                       desc_4_axuser_5_reg , 
    output reg [31:0]                                       desc_4_axuser_6_reg , 
    output reg [31:0]                                       desc_4_axuser_7_reg , 
    output reg [31:0]                                       desc_4_axuser_8_reg , 
    output reg [31:0]                                       desc_4_axuser_9_reg , 
    output reg [31:0]                                       desc_4_axuser_10_reg , 
    output reg [31:0]                                       desc_4_axuser_11_reg , 
    output reg [31:0]                                       desc_4_axuser_12_reg , 
    output reg [31:0]                                       desc_4_axuser_13_reg , 
    output reg [31:0]                                       desc_4_axuser_14_reg , 
    output reg [31:0]                                       desc_4_axuser_15_reg , 
    output reg [31:0]                                       desc_4_xuser_0_reg , 
    output reg [31:0]                                       desc_4_xuser_1_reg , 
    output reg [31:0]                                       desc_4_xuser_2_reg , 
    output reg [31:0]                                       desc_4_xuser_3_reg , 
    output reg [31:0]                                       desc_4_xuser_4_reg , 
    output reg [31:0]                                       desc_4_xuser_5_reg , 
    output reg [31:0]                                       desc_4_xuser_6_reg , 
    output reg [31:0]                                       desc_4_xuser_7_reg , 
    output reg [31:0]                                       desc_4_xuser_8_reg , 
    output reg [31:0]                                       desc_4_xuser_9_reg , 
    output reg [31:0]                                       desc_4_xuser_10_reg , 
    output reg [31:0]                                       desc_4_xuser_11_reg , 
    output reg [31:0]                                       desc_4_xuser_12_reg , 
    output reg [31:0]                                       desc_4_xuser_13_reg , 
    output reg [31:0]                                       desc_4_xuser_14_reg , 
    output reg [31:0]                                       desc_4_xuser_15_reg , 
    output reg [31:0]                                       desc_4_wuser_0_reg , 
    output reg [31:0]                                       desc_4_wuser_1_reg , 
    output reg [31:0]                                       desc_4_wuser_2_reg , 
    output reg [31:0]                                       desc_4_wuser_3_reg , 
    output reg [31:0]                                       desc_4_wuser_4_reg , 
    output reg [31:0]                                       desc_4_wuser_5_reg , 
    output reg [31:0]                                       desc_4_wuser_6_reg , 
    output reg [31:0]                                       desc_4_wuser_7_reg , 
    output reg [31:0]                                       desc_4_wuser_8_reg , 
    output reg [31:0]                                       desc_4_wuser_9_reg , 
    output reg [31:0]                                       desc_4_wuser_10_reg , 
    output reg [31:0]                                       desc_4_wuser_11_reg , 
    output reg [31:0]                                       desc_4_wuser_12_reg , 
    output reg [31:0]                                       desc_4_wuser_13_reg , 
    output reg [31:0]                                       desc_4_wuser_14_reg , 
    output reg [31:0]                                       desc_4_wuser_15_reg , 
    output reg [31:0]                                       desc_5_txn_type_reg , 
    output reg [31:0]                                       desc_5_size_reg , 
    output reg [31:0]                                       desc_5_data_offset_reg , 
    output reg [31:0]                                       desc_5_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_5_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_5_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_5_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_5_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_5_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_5_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_5_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_5_axsize_reg , 
    output reg [31:0]                                       desc_5_attr_reg , 
    output reg [31:0]                                       desc_5_axaddr_0_reg , 
    output reg [31:0]                                       desc_5_axaddr_1_reg , 
    output reg [31:0]                                       desc_5_axaddr_2_reg , 
    output reg [31:0]                                       desc_5_axaddr_3_reg , 
    output reg [31:0]                                       desc_5_axid_0_reg , 
    output reg [31:0]                                       desc_5_axid_1_reg , 
    output reg [31:0]                                       desc_5_axid_2_reg , 
    output reg [31:0]                                       desc_5_axid_3_reg , 
    output reg [31:0]                                       desc_5_axuser_0_reg , 
    output reg [31:0]                                       desc_5_axuser_1_reg , 
    output reg [31:0]                                       desc_5_axuser_2_reg , 
    output reg [31:0]                                       desc_5_axuser_3_reg , 
    output reg [31:0]                                       desc_5_axuser_4_reg , 
    output reg [31:0]                                       desc_5_axuser_5_reg , 
    output reg [31:0]                                       desc_5_axuser_6_reg , 
    output reg [31:0]                                       desc_5_axuser_7_reg , 
    output reg [31:0]                                       desc_5_axuser_8_reg , 
    output reg [31:0]                                       desc_5_axuser_9_reg , 
    output reg [31:0]                                       desc_5_axuser_10_reg , 
    output reg [31:0]                                       desc_5_axuser_11_reg , 
    output reg [31:0]                                       desc_5_axuser_12_reg , 
    output reg [31:0]                                       desc_5_axuser_13_reg , 
    output reg [31:0]                                       desc_5_axuser_14_reg , 
    output reg [31:0]                                       desc_5_axuser_15_reg , 
    output reg [31:0]                                       desc_5_xuser_0_reg , 
    output reg [31:0]                                       desc_5_xuser_1_reg , 
    output reg [31:0]                                       desc_5_xuser_2_reg , 
    output reg [31:0]                                       desc_5_xuser_3_reg , 
    output reg [31:0]                                       desc_5_xuser_4_reg , 
    output reg [31:0]                                       desc_5_xuser_5_reg , 
    output reg [31:0]                                       desc_5_xuser_6_reg , 
    output reg [31:0]                                       desc_5_xuser_7_reg , 
    output reg [31:0]                                       desc_5_xuser_8_reg , 
    output reg [31:0]                                       desc_5_xuser_9_reg , 
    output reg [31:0]                                       desc_5_xuser_10_reg , 
    output reg [31:0]                                       desc_5_xuser_11_reg , 
    output reg [31:0]                                       desc_5_xuser_12_reg , 
    output reg [31:0]                                       desc_5_xuser_13_reg , 
    output reg [31:0]                                       desc_5_xuser_14_reg , 
    output reg [31:0]                                       desc_5_xuser_15_reg , 
    output reg [31:0]                                       desc_5_wuser_0_reg , 
    output reg [31:0]                                       desc_5_wuser_1_reg , 
    output reg [31:0]                                       desc_5_wuser_2_reg , 
    output reg [31:0]                                       desc_5_wuser_3_reg , 
    output reg [31:0]                                       desc_5_wuser_4_reg , 
    output reg [31:0]                                       desc_5_wuser_5_reg , 
    output reg [31:0]                                       desc_5_wuser_6_reg , 
    output reg [31:0]                                       desc_5_wuser_7_reg , 
    output reg [31:0]                                       desc_5_wuser_8_reg , 
    output reg [31:0]                                       desc_5_wuser_9_reg , 
    output reg [31:0]                                       desc_5_wuser_10_reg , 
    output reg [31:0]                                       desc_5_wuser_11_reg , 
    output reg [31:0]                                       desc_5_wuser_12_reg , 
    output reg [31:0]                                       desc_5_wuser_13_reg , 
    output reg [31:0]                                       desc_5_wuser_14_reg , 
    output reg [31:0]                                       desc_5_wuser_15_reg , 
    output reg [31:0]                                       desc_6_txn_type_reg , 
    output reg [31:0]                                       desc_6_size_reg , 
    output reg [31:0]                                       desc_6_data_offset_reg , 
    output reg [31:0]                                       desc_6_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_6_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_6_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_6_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_6_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_6_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_6_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_6_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_6_axsize_reg , 
    output reg [31:0]                                       desc_6_attr_reg , 
    output reg [31:0]                                       desc_6_axaddr_0_reg , 
    output reg [31:0]                                       desc_6_axaddr_1_reg , 
    output reg [31:0]                                       desc_6_axaddr_2_reg , 
    output reg [31:0]                                       desc_6_axaddr_3_reg , 
    output reg [31:0]                                       desc_6_axid_0_reg , 
    output reg [31:0]                                       desc_6_axid_1_reg , 
    output reg [31:0]                                       desc_6_axid_2_reg , 
    output reg [31:0]                                       desc_6_axid_3_reg , 
    output reg [31:0]                                       desc_6_axuser_0_reg , 
    output reg [31:0]                                       desc_6_axuser_1_reg , 
    output reg [31:0]                                       desc_6_axuser_2_reg , 
    output reg [31:0]                                       desc_6_axuser_3_reg , 
    output reg [31:0]                                       desc_6_axuser_4_reg , 
    output reg [31:0]                                       desc_6_axuser_5_reg , 
    output reg [31:0]                                       desc_6_axuser_6_reg , 
    output reg [31:0]                                       desc_6_axuser_7_reg , 
    output reg [31:0]                                       desc_6_axuser_8_reg , 
    output reg [31:0]                                       desc_6_axuser_9_reg , 
    output reg [31:0]                                       desc_6_axuser_10_reg , 
    output reg [31:0]                                       desc_6_axuser_11_reg , 
    output reg [31:0]                                       desc_6_axuser_12_reg , 
    output reg [31:0]                                       desc_6_axuser_13_reg , 
    output reg [31:0]                                       desc_6_axuser_14_reg , 
    output reg [31:0]                                       desc_6_axuser_15_reg , 
    output reg [31:0]                                       desc_6_xuser_0_reg , 
    output reg [31:0]                                       desc_6_xuser_1_reg , 
    output reg [31:0]                                       desc_6_xuser_2_reg , 
    output reg [31:0]                                       desc_6_xuser_3_reg , 
    output reg [31:0]                                       desc_6_xuser_4_reg , 
    output reg [31:0]                                       desc_6_xuser_5_reg , 
    output reg [31:0]                                       desc_6_xuser_6_reg , 
    output reg [31:0]                                       desc_6_xuser_7_reg , 
    output reg [31:0]                                       desc_6_xuser_8_reg , 
    output reg [31:0]                                       desc_6_xuser_9_reg , 
    output reg [31:0]                                       desc_6_xuser_10_reg , 
    output reg [31:0]                                       desc_6_xuser_11_reg , 
    output reg [31:0]                                       desc_6_xuser_12_reg , 
    output reg [31:0]                                       desc_6_xuser_13_reg , 
    output reg [31:0]                                       desc_6_xuser_14_reg , 
    output reg [31:0]                                       desc_6_xuser_15_reg , 
    output reg [31:0]                                       desc_6_wuser_0_reg , 
    output reg [31:0]                                       desc_6_wuser_1_reg , 
    output reg [31:0]                                       desc_6_wuser_2_reg , 
    output reg [31:0]                                       desc_6_wuser_3_reg , 
    output reg [31:0]                                       desc_6_wuser_4_reg , 
    output reg [31:0]                                       desc_6_wuser_5_reg , 
    output reg [31:0]                                       desc_6_wuser_6_reg , 
    output reg [31:0]                                       desc_6_wuser_7_reg , 
    output reg [31:0]                                       desc_6_wuser_8_reg , 
    output reg [31:0]                                       desc_6_wuser_9_reg , 
    output reg [31:0]                                       desc_6_wuser_10_reg , 
    output reg [31:0]                                       desc_6_wuser_11_reg , 
    output reg [31:0]                                       desc_6_wuser_12_reg , 
    output reg [31:0]                                       desc_6_wuser_13_reg , 
    output reg [31:0]                                       desc_6_wuser_14_reg , 
    output reg [31:0]                                       desc_6_wuser_15_reg , 
    output reg [31:0]                                       desc_7_txn_type_reg , 
    output reg [31:0]                                       desc_7_size_reg , 
    output reg [31:0]                                       desc_7_data_offset_reg , 
    output reg [31:0]                                       desc_7_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_7_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_7_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_7_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_7_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_7_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_7_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_7_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_7_axsize_reg , 
    output reg [31:0]                                       desc_7_attr_reg , 
    output reg [31:0]                                       desc_7_axaddr_0_reg , 
    output reg [31:0]                                       desc_7_axaddr_1_reg , 
    output reg [31:0]                                       desc_7_axaddr_2_reg , 
    output reg [31:0]                                       desc_7_axaddr_3_reg , 
    output reg [31:0]                                       desc_7_axid_0_reg , 
    output reg [31:0]                                       desc_7_axid_1_reg , 
    output reg [31:0]                                       desc_7_axid_2_reg , 
    output reg [31:0]                                       desc_7_axid_3_reg , 
    output reg [31:0]                                       desc_7_axuser_0_reg , 
    output reg [31:0]                                       desc_7_axuser_1_reg , 
    output reg [31:0]                                       desc_7_axuser_2_reg , 
    output reg [31:0]                                       desc_7_axuser_3_reg , 
    output reg [31:0]                                       desc_7_axuser_4_reg , 
    output reg [31:0]                                       desc_7_axuser_5_reg , 
    output reg [31:0]                                       desc_7_axuser_6_reg , 
    output reg [31:0]                                       desc_7_axuser_7_reg , 
    output reg [31:0]                                       desc_7_axuser_8_reg , 
    output reg [31:0]                                       desc_7_axuser_9_reg , 
    output reg [31:0]                                       desc_7_axuser_10_reg , 
    output reg [31:0]                                       desc_7_axuser_11_reg , 
    output reg [31:0]                                       desc_7_axuser_12_reg , 
    output reg [31:0]                                       desc_7_axuser_13_reg , 
    output reg [31:0]                                       desc_7_axuser_14_reg , 
    output reg [31:0]                                       desc_7_axuser_15_reg , 
    output reg [31:0]                                       desc_7_xuser_0_reg , 
    output reg [31:0]                                       desc_7_xuser_1_reg , 
    output reg [31:0]                                       desc_7_xuser_2_reg , 
    output reg [31:0]                                       desc_7_xuser_3_reg , 
    output reg [31:0]                                       desc_7_xuser_4_reg , 
    output reg [31:0]                                       desc_7_xuser_5_reg , 
    output reg [31:0]                                       desc_7_xuser_6_reg , 
    output reg [31:0]                                       desc_7_xuser_7_reg , 
    output reg [31:0]                                       desc_7_xuser_8_reg , 
    output reg [31:0]                                       desc_7_xuser_9_reg , 
    output reg [31:0]                                       desc_7_xuser_10_reg , 
    output reg [31:0]                                       desc_7_xuser_11_reg , 
    output reg [31:0]                                       desc_7_xuser_12_reg , 
    output reg [31:0]                                       desc_7_xuser_13_reg , 
    output reg [31:0]                                       desc_7_xuser_14_reg , 
    output reg [31:0]                                       desc_7_xuser_15_reg , 
    output reg [31:0]                                       desc_7_wuser_0_reg , 
    output reg [31:0]                                       desc_7_wuser_1_reg , 
    output reg [31:0]                                       desc_7_wuser_2_reg , 
    output reg [31:0]                                       desc_7_wuser_3_reg , 
    output reg [31:0]                                       desc_7_wuser_4_reg , 
    output reg [31:0]                                       desc_7_wuser_5_reg , 
    output reg [31:0]                                       desc_7_wuser_6_reg , 
    output reg [31:0]                                       desc_7_wuser_7_reg , 
    output reg [31:0]                                       desc_7_wuser_8_reg , 
    output reg [31:0]                                       desc_7_wuser_9_reg , 
    output reg [31:0]                                       desc_7_wuser_10_reg , 
    output reg [31:0]                                       desc_7_wuser_11_reg , 
    output reg [31:0]                                       desc_7_wuser_12_reg , 
    output reg [31:0]                                       desc_7_wuser_13_reg , 
    output reg [31:0]                                       desc_7_wuser_14_reg , 
    output reg [31:0]                                       desc_7_wuser_15_reg , 
    output reg [31:0]                                       desc_8_txn_type_reg , 
    output reg [31:0]                                       desc_8_size_reg , 
    output reg [31:0]                                       desc_8_data_offset_reg , 
    output reg [31:0]                                       desc_8_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_8_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_8_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_8_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_8_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_8_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_8_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_8_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_8_axsize_reg , 
    output reg [31:0]                                       desc_8_attr_reg , 
    output reg [31:0]                                       desc_8_axaddr_0_reg , 
    output reg [31:0]                                       desc_8_axaddr_1_reg , 
    output reg [31:0]                                       desc_8_axaddr_2_reg , 
    output reg [31:0]                                       desc_8_axaddr_3_reg , 
    output reg [31:0]                                       desc_8_axid_0_reg , 
    output reg [31:0]                                       desc_8_axid_1_reg , 
    output reg [31:0]                                       desc_8_axid_2_reg , 
    output reg [31:0]                                       desc_8_axid_3_reg , 
    output reg [31:0]                                       desc_8_axuser_0_reg , 
    output reg [31:0]                                       desc_8_axuser_1_reg , 
    output reg [31:0]                                       desc_8_axuser_2_reg , 
    output reg [31:0]                                       desc_8_axuser_3_reg , 
    output reg [31:0]                                       desc_8_axuser_4_reg , 
    output reg [31:0]                                       desc_8_axuser_5_reg , 
    output reg [31:0]                                       desc_8_axuser_6_reg , 
    output reg [31:0]                                       desc_8_axuser_7_reg , 
    output reg [31:0]                                       desc_8_axuser_8_reg , 
    output reg [31:0]                                       desc_8_axuser_9_reg , 
    output reg [31:0]                                       desc_8_axuser_10_reg , 
    output reg [31:0]                                       desc_8_axuser_11_reg , 
    output reg [31:0]                                       desc_8_axuser_12_reg , 
    output reg [31:0]                                       desc_8_axuser_13_reg , 
    output reg [31:0]                                       desc_8_axuser_14_reg , 
    output reg [31:0]                                       desc_8_axuser_15_reg , 
    output reg [31:0]                                       desc_8_xuser_0_reg , 
    output reg [31:0]                                       desc_8_xuser_1_reg , 
    output reg [31:0]                                       desc_8_xuser_2_reg , 
    output reg [31:0]                                       desc_8_xuser_3_reg , 
    output reg [31:0]                                       desc_8_xuser_4_reg , 
    output reg [31:0]                                       desc_8_xuser_5_reg , 
    output reg [31:0]                                       desc_8_xuser_6_reg , 
    output reg [31:0]                                       desc_8_xuser_7_reg , 
    output reg [31:0]                                       desc_8_xuser_8_reg , 
    output reg [31:0]                                       desc_8_xuser_9_reg , 
    output reg [31:0]                                       desc_8_xuser_10_reg , 
    output reg [31:0]                                       desc_8_xuser_11_reg , 
    output reg [31:0]                                       desc_8_xuser_12_reg , 
    output reg [31:0]                                       desc_8_xuser_13_reg , 
    output reg [31:0]                                       desc_8_xuser_14_reg , 
    output reg [31:0]                                       desc_8_xuser_15_reg , 
    output reg [31:0]                                       desc_8_wuser_0_reg , 
    output reg [31:0]                                       desc_8_wuser_1_reg , 
    output reg [31:0]                                       desc_8_wuser_2_reg , 
    output reg [31:0]                                       desc_8_wuser_3_reg , 
    output reg [31:0]                                       desc_8_wuser_4_reg , 
    output reg [31:0]                                       desc_8_wuser_5_reg , 
    output reg [31:0]                                       desc_8_wuser_6_reg , 
    output reg [31:0]                                       desc_8_wuser_7_reg , 
    output reg [31:0]                                       desc_8_wuser_8_reg , 
    output reg [31:0]                                       desc_8_wuser_9_reg , 
    output reg [31:0]                                       desc_8_wuser_10_reg , 
    output reg [31:0]                                       desc_8_wuser_11_reg , 
    output reg [31:0]                                       desc_8_wuser_12_reg , 
    output reg [31:0]                                       desc_8_wuser_13_reg , 
    output reg [31:0]                                       desc_8_wuser_14_reg , 
    output reg [31:0]                                       desc_8_wuser_15_reg , 
    output reg [31:0]                                       desc_9_txn_type_reg , 
    output reg [31:0]                                       desc_9_size_reg , 
    output reg [31:0]                                       desc_9_data_offset_reg , 
    output reg [31:0]                                       desc_9_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_9_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_9_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_9_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_9_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_9_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_9_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_9_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_9_axsize_reg , 
    output reg [31:0]                                       desc_9_attr_reg , 
    output reg [31:0]                                       desc_9_axaddr_0_reg , 
    output reg [31:0]                                       desc_9_axaddr_1_reg , 
    output reg [31:0]                                       desc_9_axaddr_2_reg , 
    output reg [31:0]                                       desc_9_axaddr_3_reg , 
    output reg [31:0]                                       desc_9_axid_0_reg , 
    output reg [31:0]                                       desc_9_axid_1_reg , 
    output reg [31:0]                                       desc_9_axid_2_reg , 
    output reg [31:0]                                       desc_9_axid_3_reg , 
    output reg [31:0]                                       desc_9_axuser_0_reg , 
    output reg [31:0]                                       desc_9_axuser_1_reg , 
    output reg [31:0]                                       desc_9_axuser_2_reg , 
    output reg [31:0]                                       desc_9_axuser_3_reg , 
    output reg [31:0]                                       desc_9_axuser_4_reg , 
    output reg [31:0]                                       desc_9_axuser_5_reg , 
    output reg [31:0]                                       desc_9_axuser_6_reg , 
    output reg [31:0]                                       desc_9_axuser_7_reg , 
    output reg [31:0]                                       desc_9_axuser_8_reg , 
    output reg [31:0]                                       desc_9_axuser_9_reg , 
    output reg [31:0]                                       desc_9_axuser_10_reg , 
    output reg [31:0]                                       desc_9_axuser_11_reg , 
    output reg [31:0]                                       desc_9_axuser_12_reg , 
    output reg [31:0]                                       desc_9_axuser_13_reg , 
    output reg [31:0]                                       desc_9_axuser_14_reg , 
    output reg [31:0]                                       desc_9_axuser_15_reg , 
    output reg [31:0]                                       desc_9_xuser_0_reg , 
    output reg [31:0]                                       desc_9_xuser_1_reg , 
    output reg [31:0]                                       desc_9_xuser_2_reg , 
    output reg [31:0]                                       desc_9_xuser_3_reg , 
    output reg [31:0]                                       desc_9_xuser_4_reg , 
    output reg [31:0]                                       desc_9_xuser_5_reg , 
    output reg [31:0]                                       desc_9_xuser_6_reg , 
    output reg [31:0]                                       desc_9_xuser_7_reg , 
    output reg [31:0]                                       desc_9_xuser_8_reg , 
    output reg [31:0]                                       desc_9_xuser_9_reg , 
    output reg [31:0]                                       desc_9_xuser_10_reg , 
    output reg [31:0]                                       desc_9_xuser_11_reg , 
    output reg [31:0]                                       desc_9_xuser_12_reg , 
    output reg [31:0]                                       desc_9_xuser_13_reg , 
    output reg [31:0]                                       desc_9_xuser_14_reg , 
    output reg [31:0]                                       desc_9_xuser_15_reg , 
    output reg [31:0]                                       desc_9_wuser_0_reg , 
    output reg [31:0]                                       desc_9_wuser_1_reg , 
    output reg [31:0]                                       desc_9_wuser_2_reg , 
    output reg [31:0]                                       desc_9_wuser_3_reg , 
    output reg [31:0]                                       desc_9_wuser_4_reg , 
    output reg [31:0]                                       desc_9_wuser_5_reg , 
    output reg [31:0]                                       desc_9_wuser_6_reg , 
    output reg [31:0]                                       desc_9_wuser_7_reg , 
    output reg [31:0]                                       desc_9_wuser_8_reg , 
    output reg [31:0]                                       desc_9_wuser_9_reg , 
    output reg [31:0]                                       desc_9_wuser_10_reg , 
    output reg [31:0]                                       desc_9_wuser_11_reg , 
    output reg [31:0]                                       desc_9_wuser_12_reg , 
    output reg [31:0]                                       desc_9_wuser_13_reg , 
    output reg [31:0]                                       desc_9_wuser_14_reg , 
    output reg [31:0]                                       desc_9_wuser_15_reg , 
    output reg [31:0]                                       desc_10_txn_type_reg , 
    output reg [31:0]                                       desc_10_size_reg , 
    output reg [31:0]                                       desc_10_data_offset_reg , 
    output reg [31:0]                                       desc_10_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_10_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_10_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_10_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_10_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_10_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_10_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_10_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_10_axsize_reg , 
    output reg [31:0]                                       desc_10_attr_reg , 
    output reg [31:0]                                       desc_10_axaddr_0_reg , 
    output reg [31:0]                                       desc_10_axaddr_1_reg , 
    output reg [31:0]                                       desc_10_axaddr_2_reg , 
    output reg [31:0]                                       desc_10_axaddr_3_reg , 
    output reg [31:0]                                       desc_10_axid_0_reg , 
    output reg [31:0]                                       desc_10_axid_1_reg , 
    output reg [31:0]                                       desc_10_axid_2_reg , 
    output reg [31:0]                                       desc_10_axid_3_reg , 
    output reg [31:0]                                       desc_10_axuser_0_reg , 
    output reg [31:0]                                       desc_10_axuser_1_reg , 
    output reg [31:0]                                       desc_10_axuser_2_reg , 
    output reg [31:0]                                       desc_10_axuser_3_reg , 
    output reg [31:0]                                       desc_10_axuser_4_reg , 
    output reg [31:0]                                       desc_10_axuser_5_reg , 
    output reg [31:0]                                       desc_10_axuser_6_reg , 
    output reg [31:0]                                       desc_10_axuser_7_reg , 
    output reg [31:0]                                       desc_10_axuser_8_reg , 
    output reg [31:0]                                       desc_10_axuser_9_reg , 
    output reg [31:0]                                       desc_10_axuser_10_reg , 
    output reg [31:0]                                       desc_10_axuser_11_reg , 
    output reg [31:0]                                       desc_10_axuser_12_reg , 
    output reg [31:0]                                       desc_10_axuser_13_reg , 
    output reg [31:0]                                       desc_10_axuser_14_reg , 
    output reg [31:0]                                       desc_10_axuser_15_reg , 
    output reg [31:0]                                       desc_10_xuser_0_reg , 
    output reg [31:0]                                       desc_10_xuser_1_reg , 
    output reg [31:0]                                       desc_10_xuser_2_reg , 
    output reg [31:0]                                       desc_10_xuser_3_reg , 
    output reg [31:0]                                       desc_10_xuser_4_reg , 
    output reg [31:0]                                       desc_10_xuser_5_reg , 
    output reg [31:0]                                       desc_10_xuser_6_reg , 
    output reg [31:0]                                       desc_10_xuser_7_reg , 
    output reg [31:0]                                       desc_10_xuser_8_reg , 
    output reg [31:0]                                       desc_10_xuser_9_reg , 
    output reg [31:0]                                       desc_10_xuser_10_reg , 
    output reg [31:0]                                       desc_10_xuser_11_reg , 
    output reg [31:0]                                       desc_10_xuser_12_reg , 
    output reg [31:0]                                       desc_10_xuser_13_reg , 
    output reg [31:0]                                       desc_10_xuser_14_reg , 
    output reg [31:0]                                       desc_10_xuser_15_reg , 
    output reg [31:0]                                       desc_10_wuser_0_reg , 
    output reg [31:0]                                       desc_10_wuser_1_reg , 
    output reg [31:0]                                       desc_10_wuser_2_reg , 
    output reg [31:0]                                       desc_10_wuser_3_reg , 
    output reg [31:0]                                       desc_10_wuser_4_reg , 
    output reg [31:0]                                       desc_10_wuser_5_reg , 
    output reg [31:0]                                       desc_10_wuser_6_reg , 
    output reg [31:0]                                       desc_10_wuser_7_reg , 
    output reg [31:0]                                       desc_10_wuser_8_reg , 
    output reg [31:0]                                       desc_10_wuser_9_reg , 
    output reg [31:0]                                       desc_10_wuser_10_reg , 
    output reg [31:0]                                       desc_10_wuser_11_reg , 
    output reg [31:0]                                       desc_10_wuser_12_reg , 
    output reg [31:0]                                       desc_10_wuser_13_reg , 
    output reg [31:0]                                       desc_10_wuser_14_reg , 
    output reg [31:0]                                       desc_10_wuser_15_reg , 
    output reg [31:0]                                       desc_11_txn_type_reg , 
    output reg [31:0]                                       desc_11_size_reg , 
    output reg [31:0]                                       desc_11_data_offset_reg , 
    output reg [31:0]                                       desc_11_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_11_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_11_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_11_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_11_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_11_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_11_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_11_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_11_axsize_reg , 
    output reg [31:0]                                       desc_11_attr_reg , 
    output reg [31:0]                                       desc_11_axaddr_0_reg , 
    output reg [31:0]                                       desc_11_axaddr_1_reg , 
    output reg [31:0]                                       desc_11_axaddr_2_reg , 
    output reg [31:0]                                       desc_11_axaddr_3_reg , 
    output reg [31:0]                                       desc_11_axid_0_reg , 
    output reg [31:0]                                       desc_11_axid_1_reg , 
    output reg [31:0]                                       desc_11_axid_2_reg , 
    output reg [31:0]                                       desc_11_axid_3_reg , 
    output reg [31:0]                                       desc_11_axuser_0_reg , 
    output reg [31:0]                                       desc_11_axuser_1_reg , 
    output reg [31:0]                                       desc_11_axuser_2_reg , 
    output reg [31:0]                                       desc_11_axuser_3_reg , 
    output reg [31:0]                                       desc_11_axuser_4_reg , 
    output reg [31:0]                                       desc_11_axuser_5_reg , 
    output reg [31:0]                                       desc_11_axuser_6_reg , 
    output reg [31:0]                                       desc_11_axuser_7_reg , 
    output reg [31:0]                                       desc_11_axuser_8_reg , 
    output reg [31:0]                                       desc_11_axuser_9_reg , 
    output reg [31:0]                                       desc_11_axuser_10_reg , 
    output reg [31:0]                                       desc_11_axuser_11_reg , 
    output reg [31:0]                                       desc_11_axuser_12_reg , 
    output reg [31:0]                                       desc_11_axuser_13_reg , 
    output reg [31:0]                                       desc_11_axuser_14_reg , 
    output reg [31:0]                                       desc_11_axuser_15_reg , 
    output reg [31:0]                                       desc_11_xuser_0_reg , 
    output reg [31:0]                                       desc_11_xuser_1_reg , 
    output reg [31:0]                                       desc_11_xuser_2_reg , 
    output reg [31:0]                                       desc_11_xuser_3_reg , 
    output reg [31:0]                                       desc_11_xuser_4_reg , 
    output reg [31:0]                                       desc_11_xuser_5_reg , 
    output reg [31:0]                                       desc_11_xuser_6_reg , 
    output reg [31:0]                                       desc_11_xuser_7_reg , 
    output reg [31:0]                                       desc_11_xuser_8_reg , 
    output reg [31:0]                                       desc_11_xuser_9_reg , 
    output reg [31:0]                                       desc_11_xuser_10_reg , 
    output reg [31:0]                                       desc_11_xuser_11_reg , 
    output reg [31:0]                                       desc_11_xuser_12_reg , 
    output reg [31:0]                                       desc_11_xuser_13_reg , 
    output reg [31:0]                                       desc_11_xuser_14_reg , 
    output reg [31:0]                                       desc_11_xuser_15_reg , 
    output reg [31:0]                                       desc_11_wuser_0_reg , 
    output reg [31:0]                                       desc_11_wuser_1_reg , 
    output reg [31:0]                                       desc_11_wuser_2_reg , 
    output reg [31:0]                                       desc_11_wuser_3_reg , 
    output reg [31:0]                                       desc_11_wuser_4_reg , 
    output reg [31:0]                                       desc_11_wuser_5_reg , 
    output reg [31:0]                                       desc_11_wuser_6_reg , 
    output reg [31:0]                                       desc_11_wuser_7_reg , 
    output reg [31:0]                                       desc_11_wuser_8_reg , 
    output reg [31:0]                                       desc_11_wuser_9_reg , 
    output reg [31:0]                                       desc_11_wuser_10_reg , 
    output reg [31:0]                                       desc_11_wuser_11_reg , 
    output reg [31:0]                                       desc_11_wuser_12_reg , 
    output reg [31:0]                                       desc_11_wuser_13_reg , 
    output reg [31:0]                                       desc_11_wuser_14_reg , 
    output reg [31:0]                                       desc_11_wuser_15_reg , 
    output reg [31:0]                                       desc_12_txn_type_reg , 
    output reg [31:0]                                       desc_12_size_reg , 
    output reg [31:0]                                       desc_12_data_offset_reg , 
    output reg [31:0]                                       desc_12_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_12_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_12_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_12_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_12_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_12_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_12_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_12_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_12_axsize_reg , 
    output reg [31:0]                                       desc_12_attr_reg , 
    output reg [31:0]                                       desc_12_axaddr_0_reg , 
    output reg [31:0]                                       desc_12_axaddr_1_reg , 
    output reg [31:0]                                       desc_12_axaddr_2_reg , 
    output reg [31:0]                                       desc_12_axaddr_3_reg , 
    output reg [31:0]                                       desc_12_axid_0_reg , 
    output reg [31:0]                                       desc_12_axid_1_reg , 
    output reg [31:0]                                       desc_12_axid_2_reg , 
    output reg [31:0]                                       desc_12_axid_3_reg , 
    output reg [31:0]                                       desc_12_axuser_0_reg , 
    output reg [31:0]                                       desc_12_axuser_1_reg , 
    output reg [31:0]                                       desc_12_axuser_2_reg , 
    output reg [31:0]                                       desc_12_axuser_3_reg , 
    output reg [31:0]                                       desc_12_axuser_4_reg , 
    output reg [31:0]                                       desc_12_axuser_5_reg , 
    output reg [31:0]                                       desc_12_axuser_6_reg , 
    output reg [31:0]                                       desc_12_axuser_7_reg , 
    output reg [31:0]                                       desc_12_axuser_8_reg , 
    output reg [31:0]                                       desc_12_axuser_9_reg , 
    output reg [31:0]                                       desc_12_axuser_10_reg , 
    output reg [31:0]                                       desc_12_axuser_11_reg , 
    output reg [31:0]                                       desc_12_axuser_12_reg , 
    output reg [31:0]                                       desc_12_axuser_13_reg , 
    output reg [31:0]                                       desc_12_axuser_14_reg , 
    output reg [31:0]                                       desc_12_axuser_15_reg , 
    output reg [31:0]                                       desc_12_xuser_0_reg , 
    output reg [31:0]                                       desc_12_xuser_1_reg , 
    output reg [31:0]                                       desc_12_xuser_2_reg , 
    output reg [31:0]                                       desc_12_xuser_3_reg , 
    output reg [31:0]                                       desc_12_xuser_4_reg , 
    output reg [31:0]                                       desc_12_xuser_5_reg , 
    output reg [31:0]                                       desc_12_xuser_6_reg , 
    output reg [31:0]                                       desc_12_xuser_7_reg , 
    output reg [31:0]                                       desc_12_xuser_8_reg , 
    output reg [31:0]                                       desc_12_xuser_9_reg , 
    output reg [31:0]                                       desc_12_xuser_10_reg , 
    output reg [31:0]                                       desc_12_xuser_11_reg , 
    output reg [31:0]                                       desc_12_xuser_12_reg , 
    output reg [31:0]                                       desc_12_xuser_13_reg , 
    output reg [31:0]                                       desc_12_xuser_14_reg , 
    output reg [31:0]                                       desc_12_xuser_15_reg , 
    output reg [31:0]                                       desc_12_wuser_0_reg , 
    output reg [31:0]                                       desc_12_wuser_1_reg , 
    output reg [31:0]                                       desc_12_wuser_2_reg , 
    output reg [31:0]                                       desc_12_wuser_3_reg , 
    output reg [31:0]                                       desc_12_wuser_4_reg , 
    output reg [31:0]                                       desc_12_wuser_5_reg , 
    output reg [31:0]                                       desc_12_wuser_6_reg , 
    output reg [31:0]                                       desc_12_wuser_7_reg , 
    output reg [31:0]                                       desc_12_wuser_8_reg , 
    output reg [31:0]                                       desc_12_wuser_9_reg , 
    output reg [31:0]                                       desc_12_wuser_10_reg , 
    output reg [31:0]                                       desc_12_wuser_11_reg , 
    output reg [31:0]                                       desc_12_wuser_12_reg , 
    output reg [31:0]                                       desc_12_wuser_13_reg , 
    output reg [31:0]                                       desc_12_wuser_14_reg , 
    output reg [31:0]                                       desc_12_wuser_15_reg , 
    output reg [31:0]                                       desc_13_txn_type_reg , 
    output reg [31:0]                                       desc_13_size_reg , 
    output reg [31:0]                                       desc_13_data_offset_reg , 
    output reg [31:0]                                       desc_13_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_13_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_13_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_13_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_13_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_13_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_13_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_13_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_13_axsize_reg , 
    output reg [31:0]                                       desc_13_attr_reg , 
    output reg [31:0]                                       desc_13_axaddr_0_reg , 
    output reg [31:0]                                       desc_13_axaddr_1_reg , 
    output reg [31:0]                                       desc_13_axaddr_2_reg , 
    output reg [31:0]                                       desc_13_axaddr_3_reg , 
    output reg [31:0]                                       desc_13_axid_0_reg , 
    output reg [31:0]                                       desc_13_axid_1_reg , 
    output reg [31:0]                                       desc_13_axid_2_reg , 
    output reg [31:0]                                       desc_13_axid_3_reg , 
    output reg [31:0]                                       desc_13_axuser_0_reg , 
    output reg [31:0]                                       desc_13_axuser_1_reg , 
    output reg [31:0]                                       desc_13_axuser_2_reg , 
    output reg [31:0]                                       desc_13_axuser_3_reg , 
    output reg [31:0]                                       desc_13_axuser_4_reg , 
    output reg [31:0]                                       desc_13_axuser_5_reg , 
    output reg [31:0]                                       desc_13_axuser_6_reg , 
    output reg [31:0]                                       desc_13_axuser_7_reg , 
    output reg [31:0]                                       desc_13_axuser_8_reg , 
    output reg [31:0]                                       desc_13_axuser_9_reg , 
    output reg [31:0]                                       desc_13_axuser_10_reg , 
    output reg [31:0]                                       desc_13_axuser_11_reg , 
    output reg [31:0]                                       desc_13_axuser_12_reg , 
    output reg [31:0]                                       desc_13_axuser_13_reg , 
    output reg [31:0]                                       desc_13_axuser_14_reg , 
    output reg [31:0]                                       desc_13_axuser_15_reg , 
    output reg [31:0]                                       desc_13_xuser_0_reg , 
    output reg [31:0]                                       desc_13_xuser_1_reg , 
    output reg [31:0]                                       desc_13_xuser_2_reg , 
    output reg [31:0]                                       desc_13_xuser_3_reg , 
    output reg [31:0]                                       desc_13_xuser_4_reg , 
    output reg [31:0]                                       desc_13_xuser_5_reg , 
    output reg [31:0]                                       desc_13_xuser_6_reg , 
    output reg [31:0]                                       desc_13_xuser_7_reg , 
    output reg [31:0]                                       desc_13_xuser_8_reg , 
    output reg [31:0]                                       desc_13_xuser_9_reg , 
    output reg [31:0]                                       desc_13_xuser_10_reg , 
    output reg [31:0]                                       desc_13_xuser_11_reg , 
    output reg [31:0]                                       desc_13_xuser_12_reg , 
    output reg [31:0]                                       desc_13_xuser_13_reg , 
    output reg [31:0]                                       desc_13_xuser_14_reg , 
    output reg [31:0]                                       desc_13_xuser_15_reg , 
    output reg [31:0]                                       desc_13_wuser_0_reg , 
    output reg [31:0]                                       desc_13_wuser_1_reg , 
    output reg [31:0]                                       desc_13_wuser_2_reg , 
    output reg [31:0]                                       desc_13_wuser_3_reg , 
    output reg [31:0]                                       desc_13_wuser_4_reg , 
    output reg [31:0]                                       desc_13_wuser_5_reg , 
    output reg [31:0]                                       desc_13_wuser_6_reg , 
    output reg [31:0]                                       desc_13_wuser_7_reg , 
    output reg [31:0]                                       desc_13_wuser_8_reg , 
    output reg [31:0]                                       desc_13_wuser_9_reg , 
    output reg [31:0]                                       desc_13_wuser_10_reg , 
    output reg [31:0]                                       desc_13_wuser_11_reg , 
    output reg [31:0]                                       desc_13_wuser_12_reg , 
    output reg [31:0]                                       desc_13_wuser_13_reg , 
    output reg [31:0]                                       desc_13_wuser_14_reg , 
    output reg [31:0]                                       desc_13_wuser_15_reg , 
    output reg [31:0]                                       desc_14_txn_type_reg , 
    output reg [31:0]                                       desc_14_size_reg , 
    output reg [31:0]                                       desc_14_data_offset_reg , 
    output reg [31:0]                                       desc_14_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_14_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_14_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_14_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_14_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_14_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_14_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_14_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_14_axsize_reg , 
    output reg [31:0]                                       desc_14_attr_reg , 
    output reg [31:0]                                       desc_14_axaddr_0_reg , 
    output reg [31:0]                                       desc_14_axaddr_1_reg , 
    output reg [31:0]                                       desc_14_axaddr_2_reg , 
    output reg [31:0]                                       desc_14_axaddr_3_reg , 
    output reg [31:0]                                       desc_14_axid_0_reg , 
    output reg [31:0]                                       desc_14_axid_1_reg , 
    output reg [31:0]                                       desc_14_axid_2_reg , 
    output reg [31:0]                                       desc_14_axid_3_reg , 
    output reg [31:0]                                       desc_14_axuser_0_reg , 
    output reg [31:0]                                       desc_14_axuser_1_reg , 
    output reg [31:0]                                       desc_14_axuser_2_reg , 
    output reg [31:0]                                       desc_14_axuser_3_reg , 
    output reg [31:0]                                       desc_14_axuser_4_reg , 
    output reg [31:0]                                       desc_14_axuser_5_reg , 
    output reg [31:0]                                       desc_14_axuser_6_reg , 
    output reg [31:0]                                       desc_14_axuser_7_reg , 
    output reg [31:0]                                       desc_14_axuser_8_reg , 
    output reg [31:0]                                       desc_14_axuser_9_reg , 
    output reg [31:0]                                       desc_14_axuser_10_reg , 
    output reg [31:0]                                       desc_14_axuser_11_reg , 
    output reg [31:0]                                       desc_14_axuser_12_reg , 
    output reg [31:0]                                       desc_14_axuser_13_reg , 
    output reg [31:0]                                       desc_14_axuser_14_reg , 
    output reg [31:0]                                       desc_14_axuser_15_reg , 
    output reg [31:0]                                       desc_14_xuser_0_reg , 
    output reg [31:0]                                       desc_14_xuser_1_reg , 
    output reg [31:0]                                       desc_14_xuser_2_reg , 
    output reg [31:0]                                       desc_14_xuser_3_reg , 
    output reg [31:0]                                       desc_14_xuser_4_reg , 
    output reg [31:0]                                       desc_14_xuser_5_reg , 
    output reg [31:0]                                       desc_14_xuser_6_reg , 
    output reg [31:0]                                       desc_14_xuser_7_reg , 
    output reg [31:0]                                       desc_14_xuser_8_reg , 
    output reg [31:0]                                       desc_14_xuser_9_reg , 
    output reg [31:0]                                       desc_14_xuser_10_reg , 
    output reg [31:0]                                       desc_14_xuser_11_reg , 
    output reg [31:0]                                       desc_14_xuser_12_reg , 
    output reg [31:0]                                       desc_14_xuser_13_reg , 
    output reg [31:0]                                       desc_14_xuser_14_reg , 
    output reg [31:0]                                       desc_14_xuser_15_reg , 
    output reg [31:0]                                       desc_14_wuser_0_reg , 
    output reg [31:0]                                       desc_14_wuser_1_reg , 
    output reg [31:0]                                       desc_14_wuser_2_reg , 
    output reg [31:0]                                       desc_14_wuser_3_reg , 
    output reg [31:0]                                       desc_14_wuser_4_reg , 
    output reg [31:0]                                       desc_14_wuser_5_reg , 
    output reg [31:0]                                       desc_14_wuser_6_reg , 
    output reg [31:0]                                       desc_14_wuser_7_reg , 
    output reg [31:0]                                       desc_14_wuser_8_reg , 
    output reg [31:0]                                       desc_14_wuser_9_reg , 
    output reg [31:0]                                       desc_14_wuser_10_reg , 
    output reg [31:0]                                       desc_14_wuser_11_reg , 
    output reg [31:0]                                       desc_14_wuser_12_reg , 
    output reg [31:0]                                       desc_14_wuser_13_reg , 
    output reg [31:0]                                       desc_14_wuser_14_reg , 
    output reg [31:0]                                       desc_14_wuser_15_reg , 
    output reg [31:0]                                       desc_15_txn_type_reg , 
    output reg [31:0]                                       desc_15_size_reg , 
    output reg [31:0]                                       desc_15_data_offset_reg , 
    output reg [31:0]                                       desc_15_data_host_addr_0_reg , 
    output reg [31:0]                                       desc_15_data_host_addr_1_reg , 
    output reg [31:0]                                       desc_15_data_host_addr_2_reg , 
    output reg [31:0]                                       desc_15_data_host_addr_3_reg , 
    output reg [31:0]                                       desc_15_wstrb_host_addr_0_reg , 
    output reg [31:0]                                       desc_15_wstrb_host_addr_1_reg , 
    output reg [31:0]                                       desc_15_wstrb_host_addr_2_reg , 
    output reg [31:0]                                       desc_15_wstrb_host_addr_3_reg , 
    output reg [31:0]                                       desc_15_axsize_reg , 
    output reg [31:0]                                       desc_15_attr_reg , 
    output reg [31:0]                                       desc_15_axaddr_0_reg , 
    output reg [31:0]                                       desc_15_axaddr_1_reg , 
    output reg [31:0]                                       desc_15_axaddr_2_reg , 
    output reg [31:0]                                       desc_15_axaddr_3_reg , 
    output reg [31:0]                                       desc_15_axid_0_reg , 
    output reg [31:0]                                       desc_15_axid_1_reg , 
    output reg [31:0]                                       desc_15_axid_2_reg , 
    output reg [31:0]                                       desc_15_axid_3_reg , 
    output reg [31:0]                                       desc_15_axuser_0_reg , 
    output reg [31:0]                                       desc_15_axuser_1_reg , 
    output reg [31:0]                                       desc_15_axuser_2_reg , 
    output reg [31:0]                                       desc_15_axuser_3_reg , 
    output reg [31:0]                                       desc_15_axuser_4_reg , 
    output reg [31:0]                                       desc_15_axuser_5_reg , 
    output reg [31:0]                                       desc_15_axuser_6_reg , 
    output reg [31:0]                                       desc_15_axuser_7_reg , 
    output reg [31:0]                                       desc_15_axuser_8_reg , 
    output reg [31:0]                                       desc_15_axuser_9_reg , 
    output reg [31:0]                                       desc_15_axuser_10_reg , 
    output reg [31:0]                                       desc_15_axuser_11_reg , 
    output reg [31:0]                                       desc_15_axuser_12_reg , 
    output reg [31:0]                                       desc_15_axuser_13_reg , 
    output reg [31:0]                                       desc_15_axuser_14_reg , 
    output reg [31:0]                                       desc_15_axuser_15_reg , 
    output reg [31:0]                                       desc_15_xuser_0_reg , 
    output reg [31:0]                                       desc_15_xuser_1_reg , 
    output reg [31:0]                                       desc_15_xuser_2_reg , 
    output reg [31:0]                                       desc_15_xuser_3_reg , 
    output reg [31:0]                                       desc_15_xuser_4_reg , 
    output reg [31:0]                                       desc_15_xuser_5_reg , 
    output reg [31:0]                                       desc_15_xuser_6_reg , 
    output reg [31:0]                                       desc_15_xuser_7_reg , 
    output reg [31:0]                                       desc_15_xuser_8_reg , 
    output reg [31:0]                                       desc_15_xuser_9_reg , 
    output reg [31:0]                                       desc_15_xuser_10_reg , 
    output reg [31:0]                                       desc_15_xuser_11_reg , 
    output reg [31:0]                                       desc_15_xuser_12_reg , 
    output reg [31:0]                                       desc_15_xuser_13_reg , 
    output reg [31:0]                                       desc_15_xuser_14_reg , 
    output reg [31:0]                                       desc_15_xuser_15_reg , 
    output reg [31:0]                                       desc_15_wuser_0_reg , 
    output reg [31:0]                                       desc_15_wuser_1_reg , 
    output reg [31:0]                                       desc_15_wuser_2_reg , 
    output reg [31:0]                                       desc_15_wuser_3_reg , 
    output reg [31:0]                                       desc_15_wuser_4_reg , 
    output reg [31:0]                                       desc_15_wuser_5_reg , 
    output reg [31:0]                                       desc_15_wuser_6_reg , 
    output reg [31:0]                                       desc_15_wuser_7_reg , 
    output reg [31:0]                                       desc_15_wuser_8_reg , 
    output reg [31:0]                                       desc_15_wuser_9_reg , 
    output reg [31:0]                                       desc_15_wuser_10_reg , 
    output reg [31:0]                                       desc_15_wuser_11_reg , 
    output reg [31:0]                                       desc_15_wuser_12_reg , 
    output reg [31:0]                                       desc_15_wuser_13_reg , 
    output reg [31:0]                                       desc_15_wuser_14_reg , 
    output reg [31:0]                                       desc_15_wuser_15_reg , 

    input [31:0]                                            uc2rb_intr_error_status_reg , 
    input [31:0]                                            uc2rb_ownership_reg , 
    input [31:0]                                            uc2rb_intr_txn_avail_status_reg , 
    input [31:0]                                            uc2rb_intr_comp_status_reg , 
    input [31:0]                                            uc2rb_status_busy_reg , 
    input [31:0]                                            uc2rb_resp_fifo_free_level_reg , 
    input [31:0]                                            uc2rb_desc_0_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_0_size_reg , 
    input [31:0]                                            uc2rb_desc_0_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_0_axsize_reg , 
    input [31:0]                                            uc2rb_desc_0_attr_reg , 
    input [31:0]                                            uc2rb_desc_0_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_0_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_0_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_0_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_0_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_0_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_0_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_0_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_0_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_0_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_1_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_1_size_reg , 
    input [31:0]                                            uc2rb_desc_1_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_1_axsize_reg , 
    input [31:0]                                            uc2rb_desc_1_attr_reg , 
    input [31:0]                                            uc2rb_desc_1_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_1_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_1_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_1_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_1_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_1_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_1_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_1_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_1_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_1_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_2_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_2_size_reg , 
    input [31:0]                                            uc2rb_desc_2_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_2_axsize_reg , 
    input [31:0]                                            uc2rb_desc_2_attr_reg , 
    input [31:0]                                            uc2rb_desc_2_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_2_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_2_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_2_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_2_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_2_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_2_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_2_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_2_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_2_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_3_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_3_size_reg , 
    input [31:0]                                            uc2rb_desc_3_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_3_axsize_reg , 
    input [31:0]                                            uc2rb_desc_3_attr_reg , 
    input [31:0]                                            uc2rb_desc_3_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_3_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_3_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_3_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_3_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_3_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_3_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_3_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_3_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_3_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_4_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_4_size_reg , 
    input [31:0]                                            uc2rb_desc_4_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_4_axsize_reg , 
    input [31:0]                                            uc2rb_desc_4_attr_reg , 
    input [31:0]                                            uc2rb_desc_4_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_4_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_4_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_4_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_4_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_4_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_4_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_4_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_4_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_4_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_5_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_5_size_reg , 
    input [31:0]                                            uc2rb_desc_5_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_5_axsize_reg , 
    input [31:0]                                            uc2rb_desc_5_attr_reg , 
    input [31:0]                                            uc2rb_desc_5_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_5_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_5_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_5_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_5_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_5_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_5_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_5_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_5_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_5_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_6_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_6_size_reg , 
    input [31:0]                                            uc2rb_desc_6_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_6_axsize_reg , 
    input [31:0]                                            uc2rb_desc_6_attr_reg , 
    input [31:0]                                            uc2rb_desc_6_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_6_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_6_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_6_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_6_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_6_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_6_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_6_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_6_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_6_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_7_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_7_size_reg , 
    input [31:0]                                            uc2rb_desc_7_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_7_axsize_reg , 
    input [31:0]                                            uc2rb_desc_7_attr_reg , 
    input [31:0]                                            uc2rb_desc_7_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_7_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_7_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_7_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_7_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_7_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_7_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_7_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_7_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_7_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_8_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_8_size_reg , 
    input [31:0]                                            uc2rb_desc_8_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_8_axsize_reg , 
    input [31:0]                                            uc2rb_desc_8_attr_reg , 
    input [31:0]                                            uc2rb_desc_8_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_8_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_8_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_8_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_8_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_8_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_8_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_8_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_8_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_8_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_9_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_9_size_reg , 
    input [31:0]                                            uc2rb_desc_9_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_9_axsize_reg , 
    input [31:0]                                            uc2rb_desc_9_attr_reg , 
    input [31:0]                                            uc2rb_desc_9_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_9_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_9_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_9_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_9_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_9_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_9_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_9_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_9_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_9_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_10_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_10_size_reg , 
    input [31:0]                                            uc2rb_desc_10_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_10_axsize_reg , 
    input [31:0]                                            uc2rb_desc_10_attr_reg , 
    input [31:0]                                            uc2rb_desc_10_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_10_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_10_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_10_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_10_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_10_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_10_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_10_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_10_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_10_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_11_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_11_size_reg , 
    input [31:0]                                            uc2rb_desc_11_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_11_axsize_reg , 
    input [31:0]                                            uc2rb_desc_11_attr_reg , 
    input [31:0]                                            uc2rb_desc_11_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_11_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_11_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_11_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_11_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_11_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_11_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_11_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_11_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_11_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_12_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_12_size_reg , 
    input [31:0]                                            uc2rb_desc_12_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_12_axsize_reg , 
    input [31:0]                                            uc2rb_desc_12_attr_reg , 
    input [31:0]                                            uc2rb_desc_12_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_12_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_12_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_12_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_12_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_12_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_12_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_12_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_12_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_12_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_13_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_13_size_reg , 
    input [31:0]                                            uc2rb_desc_13_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_13_axsize_reg , 
    input [31:0]                                            uc2rb_desc_13_attr_reg , 
    input [31:0]                                            uc2rb_desc_13_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_13_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_13_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_13_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_13_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_13_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_13_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_13_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_13_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_13_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_14_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_14_size_reg , 
    input [31:0]                                            uc2rb_desc_14_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_14_axsize_reg , 
    input [31:0]                                            uc2rb_desc_14_attr_reg , 
    input [31:0]                                            uc2rb_desc_14_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_14_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_14_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_14_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_14_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_14_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_14_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_14_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_14_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_14_wuser_15_reg , 
    input [31:0]                                            uc2rb_desc_15_txn_type_reg , 
    input [31:0]                                            uc2rb_desc_15_size_reg , 
    input [31:0]                                            uc2rb_desc_15_data_offset_reg , 
    input [31:0]                                            uc2rb_desc_15_axsize_reg , 
    input [31:0]                                            uc2rb_desc_15_attr_reg , 
    input [31:0]                                            uc2rb_desc_15_axaddr_0_reg , 
    input [31:0]                                            uc2rb_desc_15_axaddr_1_reg , 
    input [31:0]                                            uc2rb_desc_15_axaddr_2_reg , 
    input [31:0]                                            uc2rb_desc_15_axaddr_3_reg , 
    input [31:0]                                            uc2rb_desc_15_axid_0_reg , 
    input [31:0]                                            uc2rb_desc_15_axid_1_reg , 
    input [31:0]                                            uc2rb_desc_15_axid_2_reg , 
    input [31:0]                                            uc2rb_desc_15_axid_3_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_0_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_1_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_2_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_3_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_4_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_5_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_6_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_7_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_8_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_9_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_10_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_11_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_12_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_13_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_14_reg , 
    input [31:0]                                            uc2rb_desc_15_axuser_15_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_0_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_1_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_2_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_3_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_4_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_5_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_6_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_7_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_8_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_9_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_10_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_11_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_12_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_13_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_14_reg , 
    input [31:0]                                            uc2rb_desc_15_wuser_15_reg , 

    input [31:0]                                            uc2rb_intr_error_status_reg_we , 
    input [31:0]                                            uc2rb_ownership_reg_we , 
    input [31:0]                                            uc2rb_intr_txn_avail_status_reg_we , 
    input [31:0]                                            uc2rb_intr_comp_status_reg_we , 
    input [31:0]                                            uc2rb_status_busy_reg_we , 
    input [31:0]                                            uc2rb_resp_fifo_free_level_reg_we , 
    input [31:0]                                            uc2rb_desc_0_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_0_size_reg_we , 
    input [31:0]                                            uc2rb_desc_0_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_0_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_0_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_0_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_1_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_1_size_reg_we , 
    input [31:0]                                            uc2rb_desc_1_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_1_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_1_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_1_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_2_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_2_size_reg_we , 
    input [31:0]                                            uc2rb_desc_2_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_2_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_2_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_2_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_3_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_3_size_reg_we , 
    input [31:0]                                            uc2rb_desc_3_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_3_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_3_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_3_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_4_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_4_size_reg_we , 
    input [31:0]                                            uc2rb_desc_4_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_4_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_4_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_4_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_5_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_5_size_reg_we , 
    input [31:0]                                            uc2rb_desc_5_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_5_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_5_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_5_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_6_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_6_size_reg_we , 
    input [31:0]                                            uc2rb_desc_6_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_6_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_6_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_6_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_7_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_7_size_reg_we , 
    input [31:0]                                            uc2rb_desc_7_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_7_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_7_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_7_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_8_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_8_size_reg_we , 
    input [31:0]                                            uc2rb_desc_8_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_8_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_8_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_8_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_9_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_9_size_reg_we , 
    input [31:0]                                            uc2rb_desc_9_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_9_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_9_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_9_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_10_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_10_size_reg_we , 
    input [31:0]                                            uc2rb_desc_10_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_10_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_10_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_10_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_11_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_11_size_reg_we , 
    input [31:0]                                            uc2rb_desc_11_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_11_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_11_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_11_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_12_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_12_size_reg_we , 
    input [31:0]                                            uc2rb_desc_12_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_12_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_12_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_12_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_13_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_13_size_reg_we , 
    input [31:0]                                            uc2rb_desc_13_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_13_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_13_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_13_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_14_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_14_size_reg_we , 
    input [31:0]                                            uc2rb_desc_14_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_14_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_14_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_14_wuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_15_txn_type_reg_we , 
    input [31:0]                                            uc2rb_desc_15_size_reg_we , 
    input [31:0]                                            uc2rb_desc_15_data_offset_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axsize_reg_we , 
    input [31:0]                                            uc2rb_desc_15_attr_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axaddr_0_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axaddr_1_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axaddr_2_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axaddr_3_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axid_0_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axid_1_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axid_2_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axid_3_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_15_axuser_15_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_0_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_1_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_2_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_3_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_4_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_5_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_6_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_7_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_8_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_9_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_10_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_11_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_12_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_13_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_14_reg_we , 
    input [31:0]                                            uc2rb_desc_15_wuser_15_reg_we,
    
    // register interface between hm-rb
    input [31:0]                                            hm2rb_intr_error_status_reg, 
    input [31:0]                                            hm2rb_intr_error_status_reg_we, 

    // register interface between IH-rb

    input [31:0] 											ih2rb_c2h_intr_status_0_reg, 
    input [31:0] 											ih2rb_c2h_intr_status_1_reg,
	input [31:0] 											ih2rb_intr_c2h_toggle_status_0_reg, 
    input [31:0] 											ih2rb_intr_c2h_toggle_status_1_reg, 
    input [31:0] 											ih2rb_c2h_gpio_0_reg,
	input [31:0] 											ih2rb_c2h_gpio_1_reg,
	input [31:0] 											ih2rb_c2h_gpio_2_reg,
	input [31:0] 											ih2rb_c2h_gpio_3_reg,
	input [31:0] 											ih2rb_c2h_gpio_4_reg,
	input [31:0] 											ih2rb_c2h_gpio_5_reg,
	input [31:0] 											ih2rb_c2h_gpio_6_reg,
	input [31:0] 											ih2rb_c2h_gpio_7_reg,

	input [31:0] 											ih2rb_c2h_gpio_0_reg_we,
	input [31:0] 											ih2rb_c2h_gpio_1_reg_we,
	input [31:0] 											ih2rb_c2h_gpio_2_reg_we,
	input [31:0] 											ih2rb_c2h_gpio_3_reg_we,
	input [31:0] 											ih2rb_c2h_gpio_4_reg_we,
	input [31:0] 											ih2rb_c2h_gpio_5_reg_we,
	input [31:0] 											ih2rb_c2h_gpio_6_reg_we,
	input [31:0] 											ih2rb_c2h_gpio_7_reg_we,

                       
    input [31:0] 											ih2rb_c2h_intr_status_0_reg_we, 
    input [31:0] 											ih2rb_c2h_intr_status_1_reg_we,
	input [31:0] 											ih2rb_intr_c2h_toggle_status_0_reg_we, 
    input [31:0] 											ih2rb_intr_c2h_toggle_status_1_reg_we 

    );
   

//INTR_ERROR_STATUS_REG
   reg [31:0] intr_error_clear_reg_clear;


//INTR_TXN_AVAIL_STATUS_REG
   reg [31:0] intr_txn_avail_clear_reg_clear ;

//INTR_COMP_STATUS_REG
   reg [31:0] intr_comp_clear_reg_clear ;

//RESP_ORDER_REG
   reg [31:0] resp_order_reg_clear ;

// INTR_C2H_TOGGLE_CLEAR_0_REG
   reg [31:0] intr_c2h_toggle_clear_0_reg_clear ;
   
// INTR_C2H_TOGGLE_CLEAR_1_REG
   reg [31:0] intr_c2h_toggle_clear_1_reg_clear ;


// H2C_PULSE_0_REG
   reg [31:0] h2c_pulse_0_reg_clear ;

// H2C_PULSE_1_REG
   reg [31:0] h2c_pulse_1_reg_clear ;


   reg [31:0] ownership_flip_clear;


   localparam BRIDGE_MSB = ((`CLOG2(RAM_SIZE*8)) - 1 );
  

   localparam VERSION = 32'h0100;
   localparam BRIDGE_IDENTIFICATION_ID = 32'hC3A89FE1;



// BRIDGE_TYPE DEFINITION
//0X0: AXI3 Bridge in Master Mode
//0x1: AXI3 Bridge in Slave Mode
//0x2: AXI4 Bridge in Master Mode
//0x3: AXI4 Bridge in Slave Mode
//0x4: AXI4-Lite Bridge in Master Mode
//0x5: AXI4-Lite Bridge in Slave Mode
//0x8: ACE Bridge in Master Mode 
//0x9: ACE Bridge in Slave Mode
//0xA: CHI Bridge in RN_F Mode
//0xB: CHI Bridge in HN_F Mode
//0xC: CXS Bridge
//0x12: PCIe-AXI Master Bridge (AXI4 mode)
//0x13: PCIe-AXI Slave Bridge (AXI4 mode)
//0x14: PCIe-AXI Master Bridge (AXI4-Lite mode)
//0x15: PCIe-AXI Slave Bridge (AXI4-Lite mode)



   localparam [31:0] BRIDGE_TYPE = (PCIE_AXI==1'b1) ?
        ( (EN_INTFS_AXI3==1'b1) ? 32'h0011 : (EN_INTFS_AXI4LITE==1'b1) ? 32'h0015 : 32'h0013 )
      : ( (EN_INTFS_AXI3==1'b1) ? 32'h0001 : (EN_INTFS_AXI4LITE==1'b1) ? 32'h0005 : 32'h0003 ) ;

   


// BRIDGE CONFIG
   localparam [31:0] DWIDTH_DECODE = (S_AXI_USR_DATA_WIDTH==128)?32'h4:(S_AXI_USR_DATA_WIDTH==64)?32'h3:(S_AXI_USR_DATA_WIDTH==32)?32'h2:32'h4;
   localparam [31:0] IDWIDTH_DECODE = S_AXI_USR_ID_WIDTH;
   localparam [31:0] EXTEND_WSTRB_DECODE = EXTEND_WSTRB;
   
   localparam [31:0] AXI_BRIDGE_CONFIG_REG = {18'b0,EXTEND_WSTRB_DECODE[0], 1'b0 ,IDWIDTH_DECODE[7:0],1'b0,DWIDTH_DECODE[2:0]};
    
   localparam [31:0] ARUSER_WIDTH_DECODE = S_AXI_USR_ARUSER_WIDTH;        
   localparam [31:0] RUSER_WIDTH_DECODE  = S_AXI_USR_RUSER_WIDTH;         
  
   localparam [31:0] AWUSER_WIDTH_DECODE = S_AXI_USR_AWUSER_WIDTH;        
   localparam [31:0] WUSER_WIDTH_DECODE  = S_AXI_USR_WUSER_WIDTH;         
   localparam [31:0] BUSER_WIDTH_DECODE  = S_AXI_USR_BUSER_WIDTH;         

   localparam [0:0] LAST_BRIDGE_DECODE = LAST_BRIDGE;
   localparam [0:0] PCIE_LAST_BRIDGE_DECODE = PCIE_LAST_BRIDGE;   

   localparam [31:0] MAX_DESC_DECODE = MAX_DESC;
   
   localparam [31:0] BRIDGE_RD_USER_CONFIG_REG = {  12'b0
                                                  , RUSER_WIDTH_DECODE[9:0]
                                                  , ARUSER_WIDTH_DECODE[9:0]
                                                  };
    
   localparam [31:0] BRIDGE_WR_USER_CONFIG_REG = {  2'b0
                                                  , BUSER_WIDTH_DECODE[9:0]
                                                  , WUSER_WIDTH_DECODE[9:0]
                                                  , AWUSER_WIDTH_DECODE[9:0]
                                                  };
   
   

   // registering axi4lite signals
   reg [S_AXI_ADDR_WIDTH-1 : 0]           axi_awaddr;
   reg                                    axi_awready;
   reg                                    axi_wready;
   reg [1 : 0]                            axi_bresp;
   reg                                    axi_bvalid;
   reg [S_AXI_ADDR_WIDTH-1 : 0]           axi_araddr;
   reg                                    axi_arready;
   reg [S_AXI_DATA_WIDTH-1 : 0]           axi_rdata;
   reg [1 : 0]                            axi_rresp;
   reg                                    axi_rvalid;

   // example-specific design signals
   // local parameter for addressing 32 bit / 64 bit c_s_axi_data_width
   // addr_lsb is used for addressing 32/64 bit registers/memories
   // addr_lsb = 2 for 32 bits (n downto 2)
   // addr_lsb = 3 for 64 bits (n downto 3)
   localparam integer                     addr_lsb = (S_AXI_DATA_WIDTH/32) + 1;
   localparam integer                     opt_mem_addr_bits = 8;

   wire                                   reg_rd_en;
   wire                                   reg_wr_en;
   reg [S_AXI_DATA_WIDTH-1:0]             reg_data_out;



   reg       wdata_ram_data_ready_2; 
   reg       wstrb_ram_data_ready_2; 

   reg       wstrb_ram_data_ready;
   reg       wstrb_ram_data_ready_1;


   assign s_axi_awready    = axi_awready;
   assign s_axi_wready     = axi_wready;
   assign s_axi_bresp      = axi_bresp;
   assign s_axi_bvalid     = axi_bvalid;
   assign s_axi_arready    = axi_arready;
   assign s_axi_rdata      = axi_rdata;
   assign s_axi_rresp      = axi_rresp;
   assign s_axi_rvalid     = axi_rvalid;

        // implement axi_awready generation
        // axi_awready is asserted for one axi_aclk clock cycle when both
        // s_axi_awvalid and s_axi_wvalid are asserted. axi_awready is
        // de-asserted when reset is low.

        always @( posedge axi_aclk )
        begin
          if ( axi_aresetn == 1'b0 )
            begin
              axi_awready <= 1'b0;
            end 
          else
            begin    
              if (~axi_awready && s_axi_awvalid && s_axi_wvalid)
                begin
                  // slave is ready to accept write address when 
                  // there is a valid write address and write data
                  // on the write address and data bus. this design 
                  // expects no outstanding transactions. 
                  axi_awready <= 1'b1;
                end
              else           
                begin
                  axi_awready <= 1'b0;
                end
            end 
        end       

        // implement axi_awaddr latching
        // this process is used to latch the address when both 
        // s_axi_awvalid and s_axi_wvalid are valid. 

        always @( posedge axi_aclk )
        begin
          if ( axi_aresetn == 1'b0 )
            begin
              axi_awaddr <= 0;
            end 
          else
            begin    
              if (~axi_awready && s_axi_awvalid && s_axi_wvalid)
                begin
                  // write address latching 
                  axi_awaddr <= s_axi_awaddr;
                end
            end 
        end       

        // implement axi_wready generation
        // axi_wready is asserted for one axi_aclk clock cycle when both
        // s_axi_awvalid and s_axi_wvalid are asserted. axi_wready is 
        // de-asserted when reset is low. 

        always @( posedge axi_aclk )
        begin
          if ( axi_aresetn == 1'b0 )
            begin
              axi_wready <= 1'b0;
            end 
          else
            begin    
              if (~axi_wready && s_axi_wvalid && s_axi_awvalid)
                begin
                  // slave is ready to accept write data when 
                  // there is a valid write address and write data
                  // on the write address and data bus. this design 
                  // expects no outstanding transactions. 
                  axi_wready <= 1'b1;
                end
              else
                begin
                  axi_wready <= 1'b0;
                end
            end 
        end       

   // implement memory mapped register select and write logic generation
   // the write data is accepted and written to memory mapped registers when
   // axi_awready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted. write strobes are used to
   // select byte enables of slave registers while writing.
   // these registers are cleared when reset (active low) is applied.
   // slave register write enable is asserted when valid address and data are available
   // and the slave is ready to accept the write address and write data.
   assign reg_wr_en = axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid;   

   integer                                i;
   integer                                byte_index;


  always @( posedge axi_aclk )
     begin
        if ( ~axi_aresetn)
          reset_reg                     <=32'hFFFFFFFF; 
        else
          begin
             if ( reg_wr_en && (~|axi_awaddr[BRIDGE_MSB:6]) && (&axi_awaddr[5:2]) ) // Writing to RESET_REG
               begin
                  for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                    if ( s_axi_wstrb[byte_index] == 1 ) begin
                       reset_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                    end  
               end
          end // else: !if( ~axi_aresetn)
     end // always @ ( posedge axi_aclk )
   
   always @( posedge axi_aclk )
     begin
        if ( ~rst_n)
          begin
             mode_select_reg               <=32'h0; 
             h2c_intr_0_reg                <=32'h0; 
             h2c_intr_1_reg                <=32'h0;
			 h2c_intr_2_reg                <=32'h0; 
             h2c_intr_3_reg                <=32'h0;
			 h2c_gpio_0_reg                <=32'h0; 
             h2c_gpio_1_reg                <=32'h0;
			 h2c_gpio_2_reg                <=32'h0; 
             h2c_gpio_3_reg                <=32'h0;
			 h2c_gpio_4_reg                <=32'h0; 
             h2c_gpio_5_reg                <=32'h0;
			 h2c_gpio_6_reg                <=32'h0; 
             h2c_gpio_7_reg                <=32'h0; 
             intr_error_enable_reg         <=32'h0; 
             addr_in_0_reg                 <=32'h0; 
             addr_in_1_reg                 <=32'h0; 
             addr_in_2_reg                 <=32'h0; 
             addr_in_3_reg                 <=32'h0; 
             trans_mask_0_reg              <=32'h0; 
             trans_mask_1_reg              <=32'h0; 
             trans_mask_2_reg              <=32'h0; 
             trans_mask_3_reg              <=32'h0; 
             trans_addr_0_reg              <=32'h0; 
             trans_addr_1_reg              <=32'h0; 
             trans_addr_2_reg              <=32'h0; 
             trans_addr_3_reg              <=32'h0; 

             intr_txn_avail_enable_reg     <=32'h0; 
             intr_comp_enable_reg          <=32'h0; 
             status_resp_comp_reg          <=32'h0;
             status_resp_reg               <=32'h0;
             desc_0_data_host_addr_0_reg   <=32'h0; 
             desc_0_data_host_addr_1_reg   <=32'h0; 
             desc_0_data_host_addr_2_reg   <=32'h0; 
             desc_0_data_host_addr_3_reg   <=32'h0; 
             desc_0_wstrb_host_addr_0_reg  <=32'h0; 
             desc_0_wstrb_host_addr_1_reg  <=32'h0; 
             desc_0_wstrb_host_addr_2_reg  <=32'h0; 
             desc_0_wstrb_host_addr_3_reg  <=32'h0; 
             desc_0_xuser_0_reg            <=32'h0; 
             desc_0_xuser_1_reg            <=32'h0; 
             desc_0_xuser_2_reg            <=32'h0; 
             desc_0_xuser_3_reg            <=32'h0; 
             desc_0_xuser_4_reg            <=32'h0; 
             desc_0_xuser_5_reg            <=32'h0; 
             desc_0_xuser_6_reg            <=32'h0; 
             desc_0_xuser_7_reg            <=32'h0; 
             desc_0_xuser_8_reg            <=32'h0; 
             desc_0_xuser_9_reg            <=32'h0; 
             desc_0_xuser_10_reg           <=32'h0; 
             desc_0_xuser_11_reg           <=32'h0; 
             desc_0_xuser_12_reg           <=32'h0; 
             desc_0_xuser_13_reg           <=32'h0; 
             desc_0_xuser_14_reg           <=32'h0; 
             desc_0_xuser_15_reg           <=32'h0; 
             desc_1_data_host_addr_0_reg   <=32'h0; 
             desc_1_data_host_addr_1_reg   <=32'h0; 
             desc_1_data_host_addr_2_reg   <=32'h0; 
             desc_1_data_host_addr_3_reg   <=32'h0; 
             desc_1_wstrb_host_addr_0_reg  <=32'h0; 
             desc_1_wstrb_host_addr_1_reg  <=32'h0; 
             desc_1_wstrb_host_addr_2_reg  <=32'h0; 
             desc_1_wstrb_host_addr_3_reg  <=32'h0; 
             desc_1_xuser_0_reg            <=32'h0; 
             desc_1_xuser_1_reg            <=32'h0; 
             desc_1_xuser_2_reg            <=32'h0; 
             desc_1_xuser_3_reg            <=32'h0; 
             desc_1_xuser_4_reg            <=32'h0; 
             desc_1_xuser_5_reg            <=32'h0; 
             desc_1_xuser_6_reg            <=32'h0; 
             desc_1_xuser_7_reg            <=32'h0; 
             desc_1_xuser_8_reg            <=32'h0; 
             desc_1_xuser_9_reg            <=32'h0; 
             desc_1_xuser_10_reg           <=32'h0; 
             desc_1_xuser_11_reg           <=32'h0; 
             desc_1_xuser_12_reg           <=32'h0; 
             desc_1_xuser_13_reg           <=32'h0; 
             desc_1_xuser_14_reg           <=32'h0; 
             desc_1_xuser_15_reg           <=32'h0; 
             desc_2_data_host_addr_0_reg   <=32'h0; 
             desc_2_data_host_addr_1_reg   <=32'h0; 
             desc_2_data_host_addr_2_reg   <=32'h0; 
             desc_2_data_host_addr_3_reg   <=32'h0; 
             desc_2_wstrb_host_addr_0_reg  <=32'h0; 
             desc_2_wstrb_host_addr_1_reg  <=32'h0; 
             desc_2_wstrb_host_addr_2_reg  <=32'h0; 
             desc_2_wstrb_host_addr_3_reg  <=32'h0; 
             desc_2_xuser_0_reg            <=32'h0; 
             desc_2_xuser_1_reg            <=32'h0; 
             desc_2_xuser_2_reg            <=32'h0; 
             desc_2_xuser_3_reg            <=32'h0; 
             desc_2_xuser_4_reg            <=32'h0; 
             desc_2_xuser_5_reg            <=32'h0; 
             desc_2_xuser_6_reg            <=32'h0; 
             desc_2_xuser_7_reg            <=32'h0; 
             desc_2_xuser_8_reg            <=32'h0; 
             desc_2_xuser_9_reg            <=32'h0; 
             desc_2_xuser_10_reg           <=32'h0; 
             desc_2_xuser_11_reg           <=32'h0; 
             desc_2_xuser_12_reg           <=32'h0; 
             desc_2_xuser_13_reg           <=32'h0; 
             desc_2_xuser_14_reg           <=32'h0; 
             desc_2_xuser_15_reg           <=32'h0; 
             desc_3_data_host_addr_0_reg   <=32'h0; 
             desc_3_data_host_addr_1_reg   <=32'h0; 
             desc_3_data_host_addr_2_reg   <=32'h0; 
             desc_3_data_host_addr_3_reg   <=32'h0; 
             desc_3_wstrb_host_addr_0_reg  <=32'h0; 
             desc_3_wstrb_host_addr_1_reg  <=32'h0; 
             desc_3_wstrb_host_addr_2_reg  <=32'h0; 
             desc_3_wstrb_host_addr_3_reg  <=32'h0; 
             desc_3_xuser_0_reg            <=32'h0; 
             desc_3_xuser_1_reg            <=32'h0; 
             desc_3_xuser_2_reg            <=32'h0; 
             desc_3_xuser_3_reg            <=32'h0; 
             desc_3_xuser_4_reg            <=32'h0; 
             desc_3_xuser_5_reg            <=32'h0; 
             desc_3_xuser_6_reg            <=32'h0; 
             desc_3_xuser_7_reg            <=32'h0; 
             desc_3_xuser_8_reg            <=32'h0; 
             desc_3_xuser_9_reg            <=32'h0; 
             desc_3_xuser_10_reg           <=32'h0; 
             desc_3_xuser_11_reg           <=32'h0; 
             desc_3_xuser_12_reg           <=32'h0; 
             desc_3_xuser_13_reg           <=32'h0; 
             desc_3_xuser_14_reg           <=32'h0; 
             desc_3_xuser_15_reg           <=32'h0; 
             desc_4_data_host_addr_0_reg   <=32'h0; 
             desc_4_data_host_addr_1_reg   <=32'h0; 
             desc_4_data_host_addr_2_reg   <=32'h0; 
             desc_4_data_host_addr_3_reg   <=32'h0; 
             desc_4_wstrb_host_addr_0_reg  <=32'h0; 
             desc_4_wstrb_host_addr_1_reg  <=32'h0; 
             desc_4_wstrb_host_addr_2_reg  <=32'h0; 
             desc_4_wstrb_host_addr_3_reg  <=32'h0; 
             desc_4_xuser_0_reg            <=32'h0; 
             desc_4_xuser_1_reg            <=32'h0; 
             desc_4_xuser_2_reg            <=32'h0; 
             desc_4_xuser_3_reg            <=32'h0; 
             desc_4_xuser_4_reg            <=32'h0; 
             desc_4_xuser_5_reg            <=32'h0; 
             desc_4_xuser_6_reg            <=32'h0; 
             desc_4_xuser_7_reg            <=32'h0; 
             desc_4_xuser_8_reg            <=32'h0; 
             desc_4_xuser_9_reg            <=32'h0; 
             desc_4_xuser_10_reg           <=32'h0; 
             desc_4_xuser_11_reg           <=32'h0; 
             desc_4_xuser_12_reg           <=32'h0; 
             desc_4_xuser_13_reg           <=32'h0; 
             desc_4_xuser_14_reg           <=32'h0; 
             desc_4_xuser_15_reg           <=32'h0; 
             desc_5_data_host_addr_1_reg   <=32'h0; 
             desc_5_data_host_addr_2_reg   <=32'h0; 
             desc_5_data_host_addr_3_reg   <=32'h0; 
             desc_5_wstrb_host_addr_0_reg  <=32'h0; 
             desc_5_wstrb_host_addr_1_reg  <=32'h0; 
             desc_5_wstrb_host_addr_2_reg  <=32'h0; 
             desc_5_wstrb_host_addr_3_reg  <=32'h0; 
             desc_5_xuser_0_reg            <=32'h0; 
             desc_5_xuser_1_reg            <=32'h0; 
             desc_5_xuser_2_reg            <=32'h0; 
             desc_5_xuser_3_reg            <=32'h0; 
             desc_5_xuser_4_reg            <=32'h0; 
             desc_5_xuser_5_reg            <=32'h0; 
             desc_5_xuser_6_reg            <=32'h0; 
             desc_5_xuser_7_reg            <=32'h0; 
             desc_5_xuser_8_reg            <=32'h0; 
             desc_5_xuser_9_reg            <=32'h0; 
             desc_5_xuser_10_reg           <=32'h0; 
             desc_5_xuser_11_reg           <=32'h0; 
             desc_5_xuser_12_reg           <=32'h0; 
             desc_5_xuser_13_reg           <=32'h0; 
             desc_5_xuser_14_reg           <=32'h0; 
             desc_5_xuser_15_reg           <=32'h0; 
             desc_6_data_host_addr_0_reg   <=32'h0; 
             desc_6_data_host_addr_1_reg   <=32'h0; 
             desc_6_data_host_addr_2_reg   <=32'h0; 
             desc_6_data_host_addr_3_reg   <=32'h0; 
             desc_6_wstrb_host_addr_0_reg  <=32'h0; 
             desc_6_wstrb_host_addr_1_reg  <=32'h0; 
             desc_6_wstrb_host_addr_2_reg  <=32'h0; 
             desc_6_wstrb_host_addr_3_reg  <=32'h0; 
             desc_6_xuser_0_reg            <=32'h0; 
             desc_6_xuser_1_reg            <=32'h0; 
             desc_6_xuser_2_reg            <=32'h0; 
             desc_6_xuser_3_reg            <=32'h0; 
             desc_6_xuser_4_reg            <=32'h0; 
             desc_6_xuser_5_reg            <=32'h0; 
             desc_6_xuser_6_reg            <=32'h0; 
             desc_6_xuser_7_reg            <=32'h0; 
             desc_6_xuser_8_reg            <=32'h0; 
             desc_6_xuser_9_reg            <=32'h0; 
             desc_6_xuser_10_reg           <=32'h0; 
             desc_6_xuser_11_reg           <=32'h0; 
             desc_6_xuser_12_reg           <=32'h0; 
             desc_6_xuser_13_reg           <=32'h0; 
             desc_6_xuser_14_reg           <=32'h0; 
             desc_6_xuser_15_reg           <=32'h0; 
             desc_7_data_host_addr_1_reg   <=32'h0; 
             desc_7_data_host_addr_2_reg   <=32'h0; 
             desc_7_data_host_addr_3_reg   <=32'h0; 
             desc_7_wstrb_host_addr_0_reg  <=32'h0; 
             desc_7_wstrb_host_addr_1_reg  <=32'h0; 
             desc_7_wstrb_host_addr_2_reg  <=32'h0; 
             desc_7_wstrb_host_addr_3_reg  <=32'h0; 
             desc_7_xuser_0_reg            <=32'h0; 
             desc_7_xuser_1_reg            <=32'h0; 
             desc_7_xuser_2_reg            <=32'h0; 
             desc_7_xuser_3_reg            <=32'h0; 
             desc_7_xuser_4_reg            <=32'h0; 
             desc_7_xuser_5_reg            <=32'h0; 
             desc_7_xuser_6_reg            <=32'h0; 
             desc_7_xuser_7_reg            <=32'h0; 
             desc_7_xuser_8_reg            <=32'h0; 
             desc_7_xuser_9_reg            <=32'h0; 
             desc_7_xuser_10_reg           <=32'h0; 
             desc_7_xuser_11_reg           <=32'h0; 
             desc_7_xuser_12_reg           <=32'h0; 
             desc_7_xuser_13_reg           <=32'h0; 
             desc_7_xuser_14_reg           <=32'h0; 
             desc_7_xuser_15_reg           <=32'h0; 
             desc_8_data_host_addr_0_reg   <=32'h0; 
             desc_8_data_host_addr_1_reg   <=32'h0; 
             desc_8_data_host_addr_2_reg   <=32'h0; 
             desc_8_data_host_addr_3_reg   <=32'h0; 
             desc_8_wstrb_host_addr_0_reg  <=32'h0; 
             desc_8_wstrb_host_addr_1_reg  <=32'h0; 
             desc_8_wstrb_host_addr_2_reg  <=32'h0; 
             desc_8_wstrb_host_addr_3_reg  <=32'h0; 
             desc_8_xuser_0_reg            <=32'h0; 
             desc_8_xuser_1_reg            <=32'h0; 
             desc_8_xuser_2_reg            <=32'h0; 
             desc_8_xuser_3_reg            <=32'h0; 
             desc_8_xuser_4_reg            <=32'h0; 
             desc_8_xuser_5_reg            <=32'h0; 
             desc_8_xuser_6_reg            <=32'h0; 
             desc_8_xuser_7_reg            <=32'h0; 
             desc_8_xuser_8_reg            <=32'h0; 
             desc_8_xuser_9_reg            <=32'h0; 
             desc_8_xuser_10_reg           <=32'h0; 
             desc_8_xuser_11_reg           <=32'h0; 
             desc_8_xuser_12_reg           <=32'h0; 
             desc_8_xuser_13_reg           <=32'h0; 
             desc_8_xuser_14_reg           <=32'h0; 
             desc_8_xuser_15_reg           <=32'h0; 
             desc_9_data_host_addr_1_reg   <=32'h0; 
             desc_9_data_host_addr_2_reg   <=32'h0; 
             desc_9_data_host_addr_3_reg   <=32'h0; 
             desc_9_wstrb_host_addr_0_reg  <=32'h0; 
             desc_9_wstrb_host_addr_1_reg  <=32'h0; 
             desc_9_wstrb_host_addr_2_reg  <=32'h0; 
             desc_9_wstrb_host_addr_3_reg  <=32'h0; 
             desc_9_xuser_0_reg            <=32'h0; 
             desc_9_xuser_1_reg            <=32'h0; 
             desc_9_xuser_2_reg            <=32'h0; 
             desc_9_xuser_3_reg            <=32'h0; 
             desc_9_xuser_4_reg            <=32'h0; 
             desc_9_xuser_5_reg            <=32'h0; 
             desc_9_xuser_6_reg            <=32'h0; 
             desc_9_xuser_7_reg            <=32'h0; 
             desc_9_xuser_8_reg            <=32'h0; 
             desc_9_xuser_9_reg            <=32'h0; 
             desc_9_xuser_10_reg           <=32'h0; 
             desc_9_xuser_11_reg           <=32'h0; 
             desc_9_xuser_12_reg           <=32'h0; 
             desc_9_xuser_13_reg           <=32'h0; 
             desc_9_xuser_14_reg           <=32'h0; 
             desc_9_xuser_15_reg           <=32'h0; 
             desc_10_data_host_addr_0_reg   <=32'h0; 
             desc_10_data_host_addr_1_reg   <=32'h0; 
             desc_10_data_host_addr_2_reg   <=32'h0; 
             desc_10_data_host_addr_3_reg   <=32'h0; 
             desc_10_wstrb_host_addr_0_reg  <=32'h0; 
             desc_10_wstrb_host_addr_1_reg  <=32'h0; 
             desc_10_wstrb_host_addr_2_reg  <=32'h0; 
             desc_10_wstrb_host_addr_3_reg  <=32'h0; 
             desc_10_xuser_0_reg            <=32'h0; 
             desc_10_xuser_1_reg            <=32'h0; 
             desc_10_xuser_2_reg            <=32'h0; 
             desc_10_xuser_3_reg            <=32'h0; 
             desc_10_xuser_4_reg            <=32'h0; 
             desc_10_xuser_5_reg            <=32'h0; 
             desc_10_xuser_6_reg            <=32'h0; 
             desc_10_xuser_7_reg            <=32'h0; 
             desc_10_xuser_8_reg            <=32'h0; 
             desc_10_xuser_9_reg            <=32'h0; 
             desc_10_xuser_10_reg           <=32'h0; 
             desc_10_xuser_11_reg           <=32'h0; 
             desc_10_xuser_12_reg           <=32'h0; 
             desc_10_xuser_13_reg           <=32'h0; 
             desc_10_xuser_14_reg           <=32'h0; 
             desc_10_xuser_15_reg           <=32'h0; 
             desc_11_data_host_addr_0_reg   <=32'h0; 
             desc_11_data_host_addr_1_reg   <=32'h0; 
             desc_11_data_host_addr_2_reg   <=32'h0; 
             desc_11_data_host_addr_3_reg   <=32'h0; 
             desc_11_wstrb_host_addr_0_reg  <=32'h0; 
             desc_11_wstrb_host_addr_1_reg  <=32'h0; 
             desc_11_wstrb_host_addr_2_reg  <=32'h0; 
             desc_11_wstrb_host_addr_3_reg  <=32'h0; 
             desc_11_xuser_0_reg            <=32'h0; 
             desc_11_xuser_1_reg            <=32'h0; 
             desc_11_xuser_2_reg            <=32'h0; 
             desc_11_xuser_3_reg            <=32'h0; 
             desc_11_xuser_4_reg            <=32'h0; 
             desc_11_xuser_5_reg            <=32'h0; 
             desc_11_xuser_6_reg            <=32'h0; 
             desc_11_xuser_7_reg            <=32'h0; 
             desc_11_xuser_8_reg            <=32'h0; 
             desc_11_xuser_9_reg            <=32'h0; 
             desc_11_xuser_10_reg           <=32'h0; 
             desc_11_xuser_11_reg           <=32'h0; 
             desc_11_xuser_12_reg           <=32'h0; 
             desc_11_xuser_13_reg           <=32'h0; 
             desc_11_xuser_14_reg           <=32'h0; 
             desc_11_xuser_15_reg           <=32'h0; 
             desc_12_data_host_addr_1_reg   <=32'h0; 
             desc_12_data_host_addr_2_reg   <=32'h0; 
             desc_12_data_host_addr_3_reg   <=32'h0; 
             desc_12_wstrb_host_addr_0_reg  <=32'h0; 
             desc_12_wstrb_host_addr_1_reg  <=32'h0; 
             desc_12_wstrb_host_addr_2_reg  <=32'h0; 
             desc_12_wstrb_host_addr_3_reg  <=32'h0; 
             desc_12_xuser_0_reg            <=32'h0; 
             desc_12_xuser_1_reg            <=32'h0; 
             desc_12_xuser_2_reg            <=32'h0; 
             desc_12_xuser_3_reg            <=32'h0; 
             desc_12_xuser_4_reg            <=32'h0; 
             desc_12_xuser_5_reg            <=32'h0; 
             desc_12_xuser_6_reg            <=32'h0; 
             desc_12_xuser_7_reg            <=32'h0; 
             desc_12_xuser_8_reg            <=32'h0; 
             desc_12_xuser_9_reg            <=32'h0; 
             desc_12_xuser_10_reg           <=32'h0; 
             desc_12_xuser_11_reg           <=32'h0; 
             desc_12_xuser_12_reg           <=32'h0; 
             desc_12_xuser_13_reg           <=32'h0; 
             desc_12_xuser_14_reg           <=32'h0; 
             desc_12_xuser_15_reg           <=32'h0; 
             desc_13_data_host_addr_0_reg   <=32'h0; 
             desc_13_data_host_addr_1_reg   <=32'h0; 
             desc_13_data_host_addr_2_reg   <=32'h0; 
             desc_13_data_host_addr_3_reg   <=32'h0; 
             desc_13_wstrb_host_addr_0_reg  <=32'h0; 
             desc_13_wstrb_host_addr_1_reg  <=32'h0; 
             desc_13_wstrb_host_addr_2_reg  <=32'h0; 
             desc_13_wstrb_host_addr_3_reg  <=32'h0; 
             desc_13_xuser_0_reg            <=32'h0; 
             desc_13_xuser_1_reg            <=32'h0; 
             desc_13_xuser_2_reg            <=32'h0; 
             desc_13_xuser_3_reg            <=32'h0; 
             desc_13_xuser_4_reg            <=32'h0; 
             desc_13_xuser_5_reg            <=32'h0; 
             desc_13_xuser_6_reg            <=32'h0; 
             desc_13_xuser_7_reg            <=32'h0; 
             desc_13_xuser_8_reg            <=32'h0; 
             desc_13_xuser_9_reg            <=32'h0; 
             desc_13_xuser_10_reg           <=32'h0; 
             desc_13_xuser_11_reg           <=32'h0; 
             desc_13_xuser_12_reg           <=32'h0; 
             desc_13_xuser_13_reg           <=32'h0; 
             desc_13_xuser_14_reg           <=32'h0; 
             desc_13_xuser_15_reg           <=32'h0; 
             desc_14_data_host_addr_0_reg   <=32'h0; 
             desc_14_data_host_addr_1_reg   <=32'h0; 
             desc_14_data_host_addr_2_reg   <=32'h0; 
             desc_14_data_host_addr_3_reg   <=32'h0; 
             desc_14_wstrb_host_addr_0_reg  <=32'h0; 
             desc_14_wstrb_host_addr_1_reg  <=32'h0; 
             desc_14_wstrb_host_addr_2_reg  <=32'h0; 
             desc_14_wstrb_host_addr_3_reg  <=32'h0; 
             desc_14_xuser_0_reg            <=32'h0; 
             desc_14_xuser_1_reg            <=32'h0; 
             desc_14_xuser_2_reg            <=32'h0; 
             desc_14_xuser_3_reg            <=32'h0; 
             desc_14_xuser_4_reg            <=32'h0; 
             desc_14_xuser_5_reg            <=32'h0; 
             desc_14_xuser_6_reg            <=32'h0; 
             desc_14_xuser_7_reg            <=32'h0; 
             desc_14_xuser_8_reg            <=32'h0; 
             desc_14_xuser_9_reg            <=32'h0; 
             desc_14_xuser_10_reg           <=32'h0; 
             desc_14_xuser_11_reg           <=32'h0; 
             desc_14_xuser_12_reg           <=32'h0; 
             desc_14_xuser_13_reg           <=32'h0; 
             desc_14_xuser_14_reg           <=32'h0; 
             desc_14_xuser_15_reg           <=32'h0; 
             desc_15_data_host_addr_0_reg   <=32'h0; 
             desc_15_data_host_addr_1_reg   <=32'h0; 
             desc_15_data_host_addr_2_reg   <=32'h0; 
             desc_15_data_host_addr_3_reg   <=32'h0; 
             desc_15_wstrb_host_addr_0_reg  <=32'h0; 
             desc_15_wstrb_host_addr_1_reg  <=32'h0; 
             desc_15_wstrb_host_addr_2_reg  <=32'h0; 
             desc_15_wstrb_host_addr_3_reg  <=32'h0; 
             desc_15_xuser_0_reg            <=32'h0; 
             desc_15_xuser_1_reg            <=32'h0; 
             desc_15_xuser_2_reg            <=32'h0; 
             desc_15_xuser_3_reg            <=32'h0; 
             desc_15_xuser_4_reg            <=32'h0; 
             desc_15_xuser_5_reg            <=32'h0; 
             desc_15_xuser_6_reg            <=32'h0; 
             desc_15_xuser_7_reg            <=32'h0; 
             desc_15_xuser_8_reg            <=32'h0; 
             desc_15_xuser_9_reg            <=32'h0; 
             desc_15_xuser_10_reg           <=32'h0; 
             desc_15_xuser_11_reg           <=32'h0; 
             desc_15_xuser_12_reg           <=32'h0; 
             desc_15_xuser_13_reg           <=32'h0; 
             desc_15_xuser_14_reg           <=32'h0; 
             desc_15_xuser_15_reg           <=32'h0; 
             intr_error_clear_reg           <=32'h0;
	     intr_c2h_toggle_clear_0_reg    <=32'h0;
	     intr_c2h_toggle_clear_1_reg    <=32'h0;
	     h2c_pulse_0_reg                <=32'h0;
	     h2c_pulse_1_reg                <=32'h0;
             intr_txn_avail_clear_reg       <=32'h0;
             intr_comp_clear_reg            <=32'h0;
             ownership_flip_reg             <=32'h0;
             resp_order_reg                 <=32'h0;
              
          end
        else begin
           if (reg_wr_en)
             begin
                case (axi_awaddr[BRIDGE_MSB:0])  
                  // RW Registers
                  `MODE_SELECT_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         // respective byte enables are asserted as per write strobes 
                         // slave register 0
                         mode_select_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `H2C_INTR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_intr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `H2C_INTR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_intr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end
				  `H2C_INTR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_intr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `H2C_INTR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_intr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end

				  //GPIO
                  `H2C_GPIO_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_gpio_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `H2C_GPIO_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_gpio_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end
				  `H2C_GPIO_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_gpio_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `H2C_GPIO_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_gpio_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end
				  `H2C_GPIO_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_gpio_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `H2C_GPIO_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_gpio_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end
				  `H2C_GPIO_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_gpio_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `H2C_GPIO_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_gpio_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end

				  			  
                  `INTR_ERROR_ENABLE_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_error_enable_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `ADDR_IN_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         addr_in_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `ADDR_IN_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         addr_in_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `ADDR_IN_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         addr_in_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `ADDR_IN_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         addr_in_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TRANS_MASK_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         trans_mask_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TRANS_MASK_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         trans_mask_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TRANS_MASK_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         trans_mask_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TRANS_MASK_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         trans_mask_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TRANS_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         trans_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TRANS_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         trans_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TRANS_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         trans_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TRANS_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         trans_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `INTR_TXN_AVAIL_ENABLE_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_txn_avail_enable_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `INTR_COMP_ENABLE_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_comp_enable_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `STATUS_RESP_COMP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         status_resp_comp_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `STATUS_RESP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         status_resp_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_0_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_0_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
// DESC 1
                  `DESC_1_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_1_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_1_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
//DESC 2
                  `DESC_2_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_2_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_2_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
//DESC 3
                  `DESC_3_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_3_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_3_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
// DESC 4
                  `DESC_4_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_4_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_4_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
// DESC 5
                  `DESC_5_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_5_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_5_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
//DESC 6
                  `DESC_6_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_6_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_6_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
//DESC 7
                  `DESC_7_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_7_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_7_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
// DESC 8
                  `DESC_8_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_8_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_8_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
// DESC 9
                  `DESC_9_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_9_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_9_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
// desc 10
                  `DESC_10_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_10_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_10_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
// DESC 11
                  `DESC_11_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_11_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_11_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
// DESC 12
                  `DESC_12_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_12_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_12_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
// desc 13
                  `DESC_13_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_13_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_13_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
// desc 14
                  `DESC_14_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_14_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_14_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
//desc 15
                  `DESC_15_DATA_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_data_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_DATA_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_data_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_DATA_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_data_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_DATA_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_data_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_WSTRB_HOST_ADDR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_wstrb_host_addr_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_WSTRB_HOST_ADDR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_wstrb_host_addr_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_WSTRB_HOST_ADDR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_wstrb_host_addr_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_WSTRB_HOST_ADDR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_wstrb_host_addr_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_4_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_4_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_5_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_5_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_6_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_6_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_7_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_7_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_8_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_8_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_9_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_9_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_10_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_10_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_11_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_11_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_12_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_12_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_13_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_13_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_14_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_14_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `DESC_15_XUSER_15_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         desc_15_xuser_15_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  // W1C Regs
                  `OWNERSHIP_FLIP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         ownership_flip_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `INTR_TXN_AVAIL_CLEAR_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_txn_avail_clear_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `INTR_COMP_CLEAR_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_comp_clear_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `INTR_ERROR_CLEAR_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_error_clear_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `RESP_ORDER_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         resp_order_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
				  `INTR_C2H_TOGGLE_CLEAR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_c2h_toggle_clear_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  

				  `INTR_C2H_TOGGLE_CLEAR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_c2h_toggle_clear_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  

				  `H2C_PULSE_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_pulse_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  

				  `H2C_PULSE_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         h2c_pulse_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  

				  `INTR_C2H_TOGGLE_ENABLE_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_c2h_toggle_enable_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  

				  `INTR_C2H_TOGGLE_ENABLE_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_c2h_toggle_enable_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
				  
				  

                endcase // case (axi_awaddr[16:0])
             end // if (reg_wr_en)
           else
             for (i = 0; i < 32 ; i = i + 1) begin
                if (ownership_flip_clear[i])begin
                   ownership_flip_reg[i] <= 1'b0;
                end
                if (intr_txn_avail_clear_reg_clear[i])begin
                   intr_txn_avail_clear_reg[i] <= 1'b0;
                end
                if (intr_comp_clear_reg_clear[i])begin
                   intr_comp_clear_reg[i] <= 1'b0;
                end
                if (resp_order_reg_clear[i])begin
                   resp_order_reg[i] <= 1'b0;
                end
                if (intr_error_clear_reg_clear[i])begin
                   intr_error_clear_reg[i] <= 1'b0;
                end
                if (intr_c2h_toggle_clear_0_reg_clear[i])begin
                   intr_c2h_toggle_clear_0_reg[i] <= 1'b0;
                end
				if (intr_c2h_toggle_clear_1_reg_clear[i])begin
                   intr_c2h_toggle_clear_1_reg[i] <= 1'b0;
                end
                if (h2c_pulse_0_reg_clear[i])begin
                   h2c_pulse_0_reg[i] <= 1'b0;
                end
                if (h2c_pulse_1_reg_clear[i])begin
                   h2c_pulse_1_reg[i] <= 1'b0;
                end



             end
           
        end // else: !if( ~rst_n)
     end // always @ ( posedge axi_aclk )




   // Implement write response logic generation
   // The write response and response valid signals are asserted by the slave 
   // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
   // This marks the acceptance of address and indicates the status of 
   // write transaction.

   always @( posedge axi_aclk )
     begin
        if ( axi_aresetn == 1'b0 )
          begin
             axi_bvalid  <= 0;
             axi_bresp   <= 2'b0;
          end 
        else
          begin    
             if (axi_awready && s_axi_awvalid && ~axi_bvalid && axi_wready && s_axi_wvalid)
               begin
                  // indicates a valid write response is available
                  axi_bvalid <= 1'b1;
                  axi_bresp  <= 2'b0; // 'OKAY' response 
               end                   // work error responses in future
             else
               begin
                  if (s_axi_bready && axi_bvalid) 
                    //check if bready is asserted while bvalid is high) 
                    //(there is a possibility that bready is always asserted high)   
                    axi_bvalid <= 1'b0; 
               end // else: !if(axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
          end // else: !if( S_AXI_ARESETN == 1'b0 )
     end // always @ ( posedge AXI_ACLK )
   
                


        // Implement axi_arready generation
        // axi_arready is asserted for one S_AXI_ACLK clock cycle when
        // S_AXI_ARVALID is asserted. axi_awready is 
        // de-asserted when reset (active low) is asserted. 
        // The read address is also latched when S_AXI_ARVALID is 
        // asserted. axi_araddr is reset to zero on reset assertion.

        always @( posedge axi_aclk )
        begin
          if ( axi_aresetn == 1'b0 )
            begin
              axi_araddr  <= {S_AXI_ADDR_WIDTH{1'b0}};
            end 
          else
            begin    
              if (~axi_arready && s_axi_arvalid)
                begin
                  // read address latching
                  axi_araddr  <= s_axi_araddr;
                end
              else
                begin
                  axi_araddr  <= axi_araddr;
                end
            end 
        end       


//

   wire arvalid_pending_pulse;
   reg  arvalid_pending_0;
   reg  arvalid_pending_1 ;
   reg  arvalid_reg;
  
always@(posedge axi_aclk)
  begin
     if ( axi_aresetn == 1'b0 )
       begin
          arvalid_reg <= 1'b0;
          arvalid_pending_0 <= 1'b0;
          arvalid_pending_1 <= 1'b0;
       end 
     else
       begin
          arvalid_reg <= s_axi_arvalid;
          arvalid_pending_0 <= ~axi_arready && s_axi_arvalid;
          arvalid_pending_1 <= arvalid_pending_0;
       end
  end // always@ (posedge axi_aclk)
   
   
   assign arvalid_pending_pulse = (arvalid_pending_0 & ~arvalid_pending_1);
//
   
   
      always @( posedge axi_aclk )
        begin
          if ( axi_aresetn == 1'b0 )
            begin
              axi_arready <= 1'b0;
              end 
          else
            begin    
               if (~axi_arready)begin
                  if (arvalid_pending_0) begin
                     if (~axi_araddr[BRIDGE_MSB] && axi_araddr[BRIDGE_MSB-1] && axi_araddr[BRIDGE_MSB-2])begin    // read is targeted to WDATA RAM
                        axi_arready <= wdata_ram_data_ready_2;
                     end
                     else begin
                        if (axi_araddr[BRIDGE_MSB] && ~axi_araddr[BRIDGE_MSB-1] && ~axi_araddr[BRIDGE_MSB-2])begin    // read is targeted to WSTRB RAM
                           axi_arready <= wstrb_ram_data_ready_2;
                        end
                        else begin    // read is targeted to regs
//                           axi_arready <= 1'b1;     // indicates that the slave has acceped the valid read address
                           axi_arready <= arvalid_pending_1;     // indicates that the slave has acceped the valid read address
                        end
                     end
                  end
                  else 
                    axi_arready <= 1'b0;
               end
               else
                 axi_arready <= 1'b0;
            end
        end // always @ ( posedge axi_aclk )
   

          
        // Implement memory mapped register select and read logic generation
        // Slave register read enable is asserted when valid address is available
        // and the slave is ready to accept the read address.
        assign reg_rd_en = axi_arready & s_axi_arvalid & ~axi_rvalid;


   reg [S_AXI_DATA_WIDTH-1:0]             reg_data_out_1;
   reg [S_AXI_DATA_WIDTH-1:0]             reg_data_out_2;
   reg [S_AXI_DATA_WIDTH-1:0]             reg_data_out_3;
   reg [S_AXI_DATA_WIDTH-1:0]             reg_data_out_4;
   reg [S_AXI_DATA_WIDTH-1:0]             reg_data_out_5;

   reg              reg_block_hit_1;
   reg              reg_block_hit_2;
   reg              reg_block_hit_3;
   reg              reg_block_hit_4;
   reg              reg_block_hit_5;

  always @( posedge axi_aclk )
    begin
       if (~axi_aresetn)
         begin
            reg_data_out_1 <= 32'b0;
            reg_block_hit_1 <= 1'b0;
         end
       else
         begin
            if (~|axi_araddr[BRIDGE_MSB:10]) //access to reg block 1
              begin
                 reg_block_hit_1 <= 1'b1;                 

                 case (axi_araddr[9:0])    
				   `BRIDGE_IDENTIFICATION_REG_ADDR          :reg_data_out_1 <= bridge_identification_reg;
				   `BRIDGE_POSITION_REG_ADDR                :reg_data_out_1 <= bridge_position_reg;
                   `VERSION_REG_ADDR                        :reg_data_out_1 <= version_reg;
                   `BRIDGE_TYPE_REG_ADDR                    :reg_data_out_1 <= bridge_type_reg;
                   `MODE_SELECT_REG_ADDR                    :reg_data_out_1 <= mode_select_reg  ;
                   `RESET_REG_ADDR                          :reg_data_out_1 <= reset_reg                       ;        
                   `H2C_INTR_0_REG_ADDR                     :reg_data_out_1 <= h2c_intr_0_reg                  ;        
                   `H2C_INTR_1_REG_ADDR                     :reg_data_out_1 <= h2c_intr_1_reg                  ;
				   `H2C_INTR_2_REG_ADDR                     :reg_data_out_1 <= h2c_intr_2_reg                  ;        
                   `H2C_INTR_3_REG_ADDR                     :reg_data_out_1 <= h2c_intr_3_reg                  ;
				   `H2C_GPIO_0_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_0_reg                  ;        
                   `H2C_GPIO_1_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_1_reg                  ;
				   `H2C_GPIO_2_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_2_reg                  ;        
                   `H2C_GPIO_3_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_3_reg                  ;
				   `H2C_GPIO_4_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_4_reg                  ;        
                   `H2C_GPIO_5_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_5_reg                  ;
				   `H2C_GPIO_6_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_6_reg                  ;        
                   `H2C_GPIO_7_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_7_reg                  ;
				   `C2H_INTR_STATUS_0_REG_ADDR              :reg_data_out_1 <= c2h_intr_status_0_reg           ;        
                   `C2H_INTR_STATUS_1_REG_ADDR              :reg_data_out_1 <= c2h_intr_status_1_reg           ;
				   `INTR_C2H_TOGGLE_ENABLE_0_REG_ADDR       :reg_data_out_1 <= intr_c2h_toggle_enable_0_reg    ;        
                   `INTR_C2H_TOGGLE_ENABLE_1_REG_ADDR       :reg_data_out_1 <= intr_c2h_toggle_enable_1_reg    ;
				   `INTR_C2H_TOGGLE_STATUS_0_REG_ADDR       :reg_data_out_1 <= intr_c2h_toggle_status_0_reg    ;        
                   `INTR_C2H_TOGGLE_STATUS_1_REG_ADDR       :reg_data_out_1 <= intr_c2h_toggle_status_1_reg    ;
				   `INTR_C2H_TOGGLE_CLEAR_0_REG_ADDR        :reg_data_out_1 <= 32'h0           ;        
                   `INTR_C2H_TOGGLE_CLEAR_1_REG_ADDR        :reg_data_out_1 <= 32'h0           ;        
				   `H2C_PULSE_0_REG_ADDR        :reg_data_out_1 <= 32'h0           ;        
				   `H2C_PULSE_1_REG_ADDR        :reg_data_out_1 <= 32'h0           ;        
                   `C2H_GPIO_0_REG_ADDR              		:reg_data_out_1 <= c2h_gpio_0_reg           ;        
                   `C2H_GPIO_1_REG_ADDR              		:reg_data_out_1 <= c2h_gpio_1_reg           ;        
                   `C2H_GPIO_2_REG_ADDR              		:reg_data_out_1 <= c2h_gpio_2_reg           ;        
                   `C2H_GPIO_3_REG_ADDR              		:reg_data_out_1 <= c2h_gpio_3_reg           ;        
                   `C2H_GPIO_4_REG_ADDR              		:reg_data_out_1 <= c2h_gpio_4_reg           ;        
                   `C2H_GPIO_5_REG_ADDR              		:reg_data_out_1 <= c2h_gpio_5_reg           ;        
                   `C2H_GPIO_6_REG_ADDR              		:reg_data_out_1 <= c2h_gpio_6_reg           ;        
                   `C2H_GPIO_7_REG_ADDR              		:reg_data_out_1 <= c2h_gpio_7_reg           ;        
                   `C2H_GPIO_8_REG_ADDR              		:reg_data_out_1 <= c2h_gpio_8_reg           ;        
                   `C2H_GPIO_9_REG_ADDR              		:reg_data_out_1 <= c2h_gpio_9_reg           ;        
                   `C2H_GPIO_10_REG_ADDR             		:reg_data_out_1 <= c2h_gpio_10_reg          ;        
                   `C2H_GPIO_11_REG_ADDR             		:reg_data_out_1 <= c2h_gpio_11_reg          ;        
                   `C2H_GPIO_12_REG_ADDR             		:reg_data_out_1 <= c2h_gpio_12_reg          ;        
                   `C2H_GPIO_13_REG_ADDR             		:reg_data_out_1 <= c2h_gpio_13_reg          ;        
                   `C2H_GPIO_14_REG_ADDR             		:reg_data_out_1 <= c2h_gpio_14_reg          ;        
                   `C2H_GPIO_15_REG_ADDR             		:reg_data_out_1 <= c2h_gpio_15_reg          ;        
                   `AXI_BRIDGE_CONFIG_REG_ADDR              :reg_data_out_1 <= axi_bridge_config_reg           ;        
                   `AXI_MAX_DESC_REG_ADDR                   :reg_data_out_1 <= axi_max_desc_reg                ;        
                   `INTR_STATUS_REG_ADDR                    :reg_data_out_1 <= intr_status_reg                 ;        
                   `INTR_ERROR_STATUS_REG_ADDR              :reg_data_out_1 <= intr_error_status_reg           ;        
                   //read at w1c register always give 0  
                   `INTR_ERROR_CLEAR_REG_ADDR               :reg_data_out_1 <= 32'b0                           ;        
                   `INTR_ERROR_ENABLE_REG_ADDR              :reg_data_out_1 <= intr_error_enable_reg           ;        
                   `BRIDGE_RD_USER_CONFIG_REG_ADDR          :reg_data_out_1 <= bridge_rd_user_config_reg       ;
                   `BRIDGE_WR_USER_CONFIG_REG_ADDR          :reg_data_out_1 <= bridge_wr_user_config_reg       ;
                   `ADDR_IN_0_REG_ADDR                      :reg_data_out_1      <= addr_in_0_reg;                                  
                   `ADDR_IN_1_REG_ADDR                      :reg_data_out_1      <= addr_in_1_reg;                                  
                   `ADDR_IN_2_REG_ADDR                      :reg_data_out_1      <= addr_in_2_reg;                                  
                   `ADDR_IN_3_REG_ADDR                      :reg_data_out_1      <= addr_in_3_reg;                                  
                   `TRANS_MASK_0_REG_ADDR                   :reg_data_out_1      <= trans_mask_0_reg;                               
                   `TRANS_MASK_1_REG_ADDR                   :reg_data_out_1      <= trans_mask_1_reg;                               
                   `TRANS_MASK_2_REG_ADDR                   :reg_data_out_1      <= trans_mask_2_reg;                              
                   `TRANS_MASK_3_REG_ADDR                   :reg_data_out_1      <= trans_mask_3_reg;                               
                   `TRANS_ADDR_0_REG_ADDR                   :reg_data_out_1      <= trans_addr_0_reg;                              
                   `TRANS_ADDR_1_REG_ADDR                   :reg_data_out_1      <= trans_addr_1_reg;                               
                   `TRANS_ADDR_2_REG_ADDR                   :reg_data_out_1      <= trans_addr_2_reg;                            
                   `TRANS_ADDR_3_REG_ADDR                   :reg_data_out_1      <= trans_addr_3_reg;                                                
        
                   `OWNERSHIP_REG_ADDR                      :reg_data_out_1 <= ownership_reg                ;        
                   //read at w1c register always give 0  
                   `OWNERSHIP_FLIP_REG_ADDR                 :reg_data_out_1 <= 32'b0                           ;        
                   `STATUS_RESP_REG_ADDR                    :reg_data_out_1 <= status_resp_reg                 ;        
                   `INTR_TXN_AVAIL_STATUS_REG_ADDR          :reg_data_out_1 <= intr_txn_avail_status_reg            ;        
                   `INTR_COMP_STATUS_REG_ADDR               :reg_data_out_1 <= intr_comp_status_reg            ;        
                   //read at w1c register always give 0  
                   `INTR_TXN_AVAIL_CLEAR_REG_ADDR           :reg_data_out_1 <= 32'b0                           ;        
                   `INTR_TXN_AVAIL_ENABLE_REG_ADDR          :reg_data_out_1 <= intr_txn_avail_enable_reg            ;        
                   `INTR_COMP_CLEAR_REG_ADDR                :reg_data_out_1 <= 32'b0                           ;        
                   `INTR_COMP_ENABLE_REG_ADDR               :reg_data_out_1 <= intr_comp_enable_reg            ;        
                   `STATUS_BUSY_REG_ADDR                    :reg_data_out_1 <= status_busy_reg;
                   `STATUS_RESP_COMP_REG_ADDR               :reg_data_out_1 <= status_resp_comp_reg;            
                   `RESP_ORDER_REG_ADDR                     :reg_data_out_1 <= resp_order_reg;
                   `RESP_FIFO_FREE_LEVEL_REG_ADDR           :reg_data_out_1 <= resp_fifo_free_level_reg;
                   default                                  :reg_data_out_1 <= 32'b0      ;        
                 endcase
              end
            else
              begin
                 reg_block_hit_1 <= 1'b0;
                 reg_data_out_1 <= reg_data_out_1;
              end
         end
    end


  always @( posedge axi_aclk )
    begin
       if (~axi_aresetn)
         begin
            reg_data_out_2 <= 32'b0;
            reg_block_hit_2 <= 1'b0;
         end
       else
         begin
            if (~|axi_araddr[BRIDGE_MSB:14] && (&axi_araddr[13:12] && ~axi_araddr[11])) //access to reg block 2
              begin
                 reg_block_hit_2 <= 1'b1;                 

              case ({6'b000110,axi_araddr[10:0]})    
                `DESC_0_TXN_TYPE_REG_ADDR                :reg_data_out_2 <= desc_0_txn_type_reg             ;        
                `DESC_0_SIZE_REG_ADDR                    :reg_data_out_2 <= desc_0_size_reg                 ;        
                `DESC_0_DATA_OFFSET_REG_ADDR             :reg_data_out_2 <= desc_0_data_offset_reg          ;        
                `DESC_0_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_2 <= desc_0_data_host_addr_0_reg     ;        
                `DESC_0_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_2 <= desc_0_data_host_addr_1_reg     ;        
                `DESC_0_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_2 <= desc_0_data_host_addr_2_reg     ;        
                `DESC_0_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_2 <= desc_0_data_host_addr_3_reg     ;        
                `DESC_0_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_2 <= desc_0_wstrb_host_addr_0_reg    ;        
                `DESC_0_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_2 <= desc_0_wstrb_host_addr_1_reg    ;        
                `DESC_0_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_2 <= desc_0_wstrb_host_addr_2_reg    ;        
                `DESC_0_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_2 <= desc_0_wstrb_host_addr_3_reg    ;        
                `DESC_0_AXSIZE_REG_ADDR                 : reg_data_out_2 <= desc_0_axsize_reg               ;        
                `DESC_0_ATTR_REG_ADDR                   : reg_data_out_2 <= desc_0_attr_reg                 ;        
                `DESC_0_AXADDR_0_REG_ADDR               : reg_data_out_2 <= desc_0_axaddr_0_reg             ;        
                `DESC_0_AXADDR_1_REG_ADDR               : reg_data_out_2 <= desc_0_axaddr_1_reg             ;        
                `DESC_0_AXADDR_2_REG_ADDR               : reg_data_out_2 <= desc_0_axaddr_2_reg             ;        
                `DESC_0_AXADDR_3_REG_ADDR               : reg_data_out_2 <= desc_0_axaddr_3_reg             ;        
                `DESC_0_AXID_0_REG_ADDR                 : reg_data_out_2 <= desc_0_axid_0_reg               ;        
                `DESC_0_AXID_1_REG_ADDR                 : reg_data_out_2 <= desc_0_axid_1_reg               ;        
                `DESC_0_AXID_2_REG_ADDR                 : reg_data_out_2 <= desc_0_axid_2_reg               ;        
                `DESC_0_AXID_3_REG_ADDR                 : reg_data_out_2 <= desc_0_axid_3_reg               ;        
                `DESC_0_AXUSER_0_REG_ADDR               : reg_data_out_2 <= desc_0_axuser_0_reg             ;        
                `DESC_0_AXUSER_1_REG_ADDR               : reg_data_out_2 <= desc_0_axuser_1_reg             ;        
                `DESC_0_AXUSER_2_REG_ADDR               : reg_data_out_2 <= desc_0_axuser_2_reg             ;        
                `DESC_0_AXUSER_3_REG_ADDR               : reg_data_out_2 <= desc_0_axuser_3_reg             ;        
                `DESC_0_AXUSER_4_REG_ADDR               : reg_data_out_2 <= desc_0_axuser_4_reg             ;        
                `DESC_0_AXUSER_5_REG_ADDR               : reg_data_out_2 <= desc_0_axuser_5_reg             ;        
                `DESC_0_AXUSER_6_REG_ADDR               : reg_data_out_2 <= desc_0_axuser_6_reg             ;        
                `DESC_0_AXUSER_7_REG_ADDR               : reg_data_out_2 <= desc_0_axuser_7_reg             ;        
                `DESC_0_AXUSER_8_REG_ADDR               : reg_data_out_2 <= desc_0_axuser_8_reg             ;        
                `DESC_0_AXUSER_9_REG_ADDR               : reg_data_out_2 <= desc_0_axuser_9_reg             ;        
                `DESC_0_AXUSER_10_REG_ADDR              : reg_data_out_2 <= desc_0_axuser_10_reg            ;        
                `DESC_0_AXUSER_11_REG_ADDR              : reg_data_out_2 <= desc_0_axuser_11_reg            ;        
                `DESC_0_AXUSER_12_REG_ADDR              : reg_data_out_2 <= desc_0_axuser_12_reg            ;        
                `DESC_0_AXUSER_13_REG_ADDR              : reg_data_out_2 <= desc_0_axuser_13_reg            ;        
                `DESC_0_AXUSER_14_REG_ADDR              : reg_data_out_2 <= desc_0_axuser_14_reg            ;        
                `DESC_0_AXUSER_15_REG_ADDR              : reg_data_out_2 <= desc_0_axuser_15_reg            ;        
                `DESC_0_XUSER_0_REG_ADDR                : reg_data_out_2 <= desc_0_xuser_0_reg              ;        
                `DESC_0_XUSER_1_REG_ADDR                : reg_data_out_2 <= desc_0_xuser_1_reg              ;        
                `DESC_0_XUSER_2_REG_ADDR                : reg_data_out_2 <= desc_0_xuser_2_reg              ;        
                `DESC_0_XUSER_3_REG_ADDR                : reg_data_out_2 <= desc_0_xuser_3_reg              ;        
                `DESC_0_XUSER_4_REG_ADDR                : reg_data_out_2 <= desc_0_xuser_4_reg              ;        
                `DESC_0_XUSER_5_REG_ADDR                : reg_data_out_2 <= desc_0_xuser_5_reg              ;        
                `DESC_0_XUSER_6_REG_ADDR                : reg_data_out_2 <= desc_0_xuser_6_reg              ;        
                `DESC_0_XUSER_7_REG_ADDR                : reg_data_out_2 <= desc_0_xuser_7_reg              ;        
                `DESC_0_XUSER_8_REG_ADDR                : reg_data_out_2 <= desc_0_xuser_8_reg              ;        
                `DESC_0_XUSER_9_REG_ADDR                : reg_data_out_2 <= desc_0_xuser_9_reg              ;        
                `DESC_0_XUSER_10_REG_ADDR               : reg_data_out_2 <= desc_0_xuser_10_reg             ;        
                `DESC_0_XUSER_11_REG_ADDR               : reg_data_out_2 <= desc_0_xuser_11_reg             ;        
                `DESC_0_XUSER_12_REG_ADDR               : reg_data_out_2 <= desc_0_xuser_12_reg             ;        
                `DESC_0_XUSER_13_REG_ADDR               : reg_data_out_2 <= desc_0_xuser_13_reg             ;        
                `DESC_0_XUSER_14_REG_ADDR               : reg_data_out_2 <= desc_0_xuser_14_reg             ;        
                `DESC_0_XUSER_15_REG_ADDR               : reg_data_out_2 <= desc_0_xuser_15_reg             ;        
                `DESC_0_WUSER_0_REG_ADDR                : reg_data_out_2 <= desc_0_wuser_0_reg              ;        
                `DESC_0_WUSER_1_REG_ADDR                : reg_data_out_2 <= desc_0_wuser_1_reg              ;        
                `DESC_0_WUSER_2_REG_ADDR                : reg_data_out_2 <= desc_0_wuser_2_reg              ;        
                `DESC_0_WUSER_3_REG_ADDR                : reg_data_out_2 <= desc_0_wuser_3_reg              ;        
                `DESC_0_WUSER_4_REG_ADDR                : reg_data_out_2 <= desc_0_wuser_4_reg              ;        
                `DESC_0_WUSER_5_REG_ADDR                : reg_data_out_2 <= desc_0_wuser_5_reg              ;        
                `DESC_0_WUSER_6_REG_ADDR                : reg_data_out_2 <= desc_0_wuser_6_reg              ;        
                `DESC_0_WUSER_7_REG_ADDR                : reg_data_out_2 <= desc_0_wuser_7_reg              ;        
                `DESC_0_WUSER_8_REG_ADDR                : reg_data_out_2 <= desc_0_wuser_8_reg              ;        
                `DESC_0_WUSER_9_REG_ADDR                : reg_data_out_2 <= desc_0_wuser_9_reg              ;        
                `DESC_0_WUSER_10_REG_ADDR               : reg_data_out_2 <= desc_0_wuser_10_reg             ;        
                `DESC_0_WUSER_11_REG_ADDR               : reg_data_out_2 <= desc_0_wuser_11_reg             ;        
                `DESC_0_WUSER_12_REG_ADDR               : reg_data_out_2 <= desc_0_wuser_12_reg             ;        
                `DESC_0_WUSER_13_REG_ADDR               : reg_data_out_2 <= desc_0_wuser_13_reg             ;        
                `DESC_0_WUSER_14_REG_ADDR               : reg_data_out_2 <= desc_0_wuser_14_reg             ;        
                `DESC_0_WUSER_15_REG_ADDR               : reg_data_out_2 <= desc_0_wuser_15_reg             ;        
                `DESC_1_TXN_TYPE_REG_ADDR               : reg_data_out_2 <= desc_1_txn_type_reg             ;        
                `DESC_1_SIZE_REG_ADDR                   : reg_data_out_2 <= desc_1_size_reg                 ;        
                `DESC_1_DATA_OFFSET_REG_ADDR            : reg_data_out_2 <= desc_1_data_offset_reg          ;        
                `DESC_1_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_2 <= desc_1_data_host_addr_0_reg     ;        
                `DESC_1_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_2 <= desc_1_data_host_addr_1_reg     ;        
                `DESC_1_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_2 <= desc_1_data_host_addr_2_reg     ;        
                `DESC_1_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_2 <= desc_1_data_host_addr_3_reg     ;        
                `DESC_1_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_2 <= desc_1_wstrb_host_addr_0_reg    ;        
                `DESC_1_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_2 <= desc_1_wstrb_host_addr_1_reg    ;        
                `DESC_1_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_2 <= desc_1_wstrb_host_addr_2_reg    ;        
                `DESC_1_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_2 <= desc_1_wstrb_host_addr_3_reg    ;        
                `DESC_1_AXSIZE_REG_ADDR                 : reg_data_out_2 <= desc_1_axsize_reg               ;        
                `DESC_1_ATTR_REG_ADDR                   : reg_data_out_2 <= desc_1_attr_reg                 ;        
                `DESC_1_AXADDR_0_REG_ADDR               : reg_data_out_2 <= desc_1_axaddr_0_reg             ;        
                `DESC_1_AXADDR_1_REG_ADDR               : reg_data_out_2 <= desc_1_axaddr_1_reg             ;        
                `DESC_1_AXADDR_2_REG_ADDR               : reg_data_out_2 <= desc_1_axaddr_2_reg             ;        
                `DESC_1_AXADDR_3_REG_ADDR               : reg_data_out_2 <= desc_1_axaddr_3_reg             ;        
                `DESC_1_AXID_0_REG_ADDR                 : reg_data_out_2 <= desc_1_axid_0_reg               ;        
                `DESC_1_AXID_1_REG_ADDR                 : reg_data_out_2 <= desc_1_axid_1_reg               ;        
                `DESC_1_AXID_2_REG_ADDR                 : reg_data_out_2 <= desc_1_axid_2_reg               ;        
                `DESC_1_AXID_3_REG_ADDR                 : reg_data_out_2 <= desc_1_axid_3_reg               ;        
                `DESC_1_AXUSER_0_REG_ADDR               : reg_data_out_2 <= desc_1_axuser_0_reg             ;        
                `DESC_1_AXUSER_1_REG_ADDR               : reg_data_out_2 <= desc_1_axuser_1_reg             ;        
                `DESC_1_AXUSER_2_REG_ADDR               : reg_data_out_2 <= desc_1_axuser_2_reg             ;        
                `DESC_1_AXUSER_3_REG_ADDR               : reg_data_out_2 <= desc_1_axuser_3_reg             ;        
                `DESC_1_AXUSER_4_REG_ADDR               : reg_data_out_2 <= desc_1_axuser_4_reg             ;        
                `DESC_1_AXUSER_5_REG_ADDR               : reg_data_out_2 <= desc_1_axuser_5_reg             ;        
                `DESC_1_AXUSER_6_REG_ADDR               : reg_data_out_2 <= desc_1_axuser_6_reg             ;        
                `DESC_1_AXUSER_7_REG_ADDR               : reg_data_out_2 <= desc_1_axuser_7_reg             ;        
                `DESC_1_AXUSER_8_REG_ADDR               : reg_data_out_2 <= desc_1_axuser_8_reg             ;        
                `DESC_1_AXUSER_9_REG_ADDR               : reg_data_out_2 <= desc_1_axuser_9_reg             ;        
                `DESC_1_AXUSER_10_REG_ADDR              : reg_data_out_2 <= desc_1_axuser_10_reg            ;        
                `DESC_1_AXUSER_11_REG_ADDR              : reg_data_out_2 <= desc_1_axuser_11_reg            ;        
                `DESC_1_AXUSER_12_REG_ADDR              : reg_data_out_2 <= desc_1_axuser_12_reg            ;        
                `DESC_1_AXUSER_13_REG_ADDR              : reg_data_out_2 <= desc_1_axuser_13_reg            ;        
                `DESC_1_AXUSER_14_REG_ADDR              : reg_data_out_2 <= desc_1_axuser_14_reg            ;        
                `DESC_1_AXUSER_15_REG_ADDR              : reg_data_out_2 <= desc_1_axuser_15_reg            ;        
                `DESC_1_XUSER_0_REG_ADDR                : reg_data_out_2 <= desc_1_xuser_0_reg              ;        
                `DESC_1_XUSER_1_REG_ADDR                : reg_data_out_2 <= desc_1_xuser_1_reg              ;        
                `DESC_1_XUSER_2_REG_ADDR                : reg_data_out_2 <= desc_1_xuser_2_reg              ;        
                `DESC_1_XUSER_3_REG_ADDR                : reg_data_out_2 <= desc_1_xuser_3_reg              ;        
                `DESC_1_XUSER_4_REG_ADDR                : reg_data_out_2 <= desc_1_xuser_4_reg              ;        
                `DESC_1_XUSER_5_REG_ADDR                : reg_data_out_2 <= desc_1_xuser_5_reg              ;        
                `DESC_1_XUSER_6_REG_ADDR                : reg_data_out_2 <= desc_1_xuser_6_reg              ;        
                `DESC_1_XUSER_7_REG_ADDR                : reg_data_out_2 <= desc_1_xuser_7_reg              ;        
                `DESC_1_XUSER_8_REG_ADDR                : reg_data_out_2 <= desc_1_xuser_8_reg              ;        
                `DESC_1_XUSER_9_REG_ADDR                : reg_data_out_2 <= desc_1_xuser_9_reg              ;        
                `DESC_1_XUSER_10_REG_ADDR               : reg_data_out_2 <= desc_1_xuser_10_reg             ;        
                `DESC_1_XUSER_11_REG_ADDR               : reg_data_out_2 <= desc_1_xuser_11_reg             ;        
                `DESC_1_XUSER_12_REG_ADDR               : reg_data_out_2 <= desc_1_xuser_12_reg             ;        
                `DESC_1_XUSER_13_REG_ADDR               : reg_data_out_2 <= desc_1_xuser_13_reg             ;        
                `DESC_1_XUSER_14_REG_ADDR               : reg_data_out_2 <= desc_1_xuser_14_reg             ;        
                `DESC_1_XUSER_15_REG_ADDR               : reg_data_out_2 <= desc_1_xuser_15_reg             ;        
                `DESC_1_WUSER_0_REG_ADDR                : reg_data_out_2 <= desc_1_wuser_0_reg              ;        
                `DESC_1_WUSER_1_REG_ADDR                : reg_data_out_2 <= desc_1_wuser_1_reg              ;        
                `DESC_1_WUSER_2_REG_ADDR                : reg_data_out_2 <= desc_1_wuser_2_reg              ;        
                `DESC_1_WUSER_3_REG_ADDR                : reg_data_out_2 <= desc_1_wuser_3_reg              ;        
                `DESC_1_WUSER_4_REG_ADDR                : reg_data_out_2 <= desc_1_wuser_4_reg              ;        
                `DESC_1_WUSER_5_REG_ADDR                : reg_data_out_2 <= desc_1_wuser_5_reg              ;        
                `DESC_1_WUSER_6_REG_ADDR                : reg_data_out_2 <= desc_1_wuser_6_reg              ;        
                `DESC_1_WUSER_7_REG_ADDR                : reg_data_out_2 <= desc_1_wuser_7_reg              ;        
                `DESC_1_WUSER_8_REG_ADDR                : reg_data_out_2 <= desc_1_wuser_8_reg              ;        
                `DESC_1_WUSER_9_REG_ADDR                : reg_data_out_2 <= desc_1_wuser_9_reg              ;        
                `DESC_1_WUSER_10_REG_ADDR               : reg_data_out_2 <= desc_1_wuser_10_reg             ;        
                `DESC_1_WUSER_11_REG_ADDR               : reg_data_out_2 <= desc_1_wuser_11_reg             ;        
                `DESC_1_WUSER_12_REG_ADDR               : reg_data_out_2 <= desc_1_wuser_12_reg             ;        
                `DESC_1_WUSER_13_REG_ADDR               : reg_data_out_2 <= desc_1_wuser_13_reg             ;        
                `DESC_1_WUSER_14_REG_ADDR               : reg_data_out_2 <= desc_1_wuser_14_reg             ;        
                `DESC_1_WUSER_15_REG_ADDR               : reg_data_out_2 <= desc_1_wuser_15_reg             ;        
                `DESC_2_TXN_TYPE_REG_ADDR               : reg_data_out_2 <= desc_2_txn_type_reg             ;        
                `DESC_2_SIZE_REG_ADDR                   : reg_data_out_2 <= desc_2_size_reg                 ;        
                `DESC_2_DATA_OFFSET_REG_ADDR            : reg_data_out_2 <= desc_2_data_offset_reg          ;        
                `DESC_2_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_2 <= desc_2_data_host_addr_0_reg     ;        
                `DESC_2_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_2 <= desc_2_data_host_addr_1_reg     ;        
                `DESC_2_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_2 <= desc_2_data_host_addr_2_reg     ;        
                `DESC_2_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_2 <= desc_2_data_host_addr_3_reg     ;        
                `DESC_2_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_2 <= desc_2_wstrb_host_addr_0_reg    ;        
                `DESC_2_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_2 <= desc_2_wstrb_host_addr_1_reg    ;        
                `DESC_2_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_2 <= desc_2_wstrb_host_addr_2_reg    ;        
                `DESC_2_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_2 <= desc_2_wstrb_host_addr_3_reg    ;        
                `DESC_2_AXSIZE_REG_ADDR                 : reg_data_out_2 <= desc_2_axsize_reg               ;        
                `DESC_2_ATTR_REG_ADDR                   : reg_data_out_2 <= desc_2_attr_reg                 ;        
                `DESC_2_AXADDR_0_REG_ADDR               : reg_data_out_2 <= desc_2_axaddr_0_reg             ;        
                `DESC_2_AXADDR_1_REG_ADDR               : reg_data_out_2 <= desc_2_axaddr_1_reg             ;        
                `DESC_2_AXADDR_2_REG_ADDR               : reg_data_out_2 <= desc_2_axaddr_2_reg             ;        
                `DESC_2_AXADDR_3_REG_ADDR               : reg_data_out_2 <= desc_2_axaddr_3_reg             ;        
                `DESC_2_AXID_0_REG_ADDR                 : reg_data_out_2 <= desc_2_axid_0_reg               ;        
                `DESC_2_AXID_1_REG_ADDR                 : reg_data_out_2 <= desc_2_axid_1_reg               ;        
                `DESC_2_AXID_2_REG_ADDR                 : reg_data_out_2 <= desc_2_axid_2_reg               ;        
                `DESC_2_AXID_3_REG_ADDR                 : reg_data_out_2 <= desc_2_axid_3_reg               ;        
                `DESC_2_AXUSER_0_REG_ADDR               : reg_data_out_2 <= desc_2_axuser_0_reg             ;        
                `DESC_2_AXUSER_1_REG_ADDR               : reg_data_out_2 <= desc_2_axuser_1_reg             ;        
                `DESC_2_AXUSER_2_REG_ADDR               : reg_data_out_2 <= desc_2_axuser_2_reg             ;        
                `DESC_2_AXUSER_3_REG_ADDR               : reg_data_out_2 <= desc_2_axuser_3_reg             ;        
                `DESC_2_AXUSER_4_REG_ADDR               : reg_data_out_2 <= desc_2_axuser_4_reg             ;        
                `DESC_2_AXUSER_5_REG_ADDR               : reg_data_out_2 <= desc_2_axuser_5_reg             ;        
                `DESC_2_AXUSER_6_REG_ADDR               : reg_data_out_2 <= desc_2_axuser_6_reg             ;        
                `DESC_2_AXUSER_7_REG_ADDR               : reg_data_out_2 <= desc_2_axuser_7_reg             ;        
                `DESC_2_AXUSER_8_REG_ADDR               : reg_data_out_2 <= desc_2_axuser_8_reg             ;        
                `DESC_2_AXUSER_9_REG_ADDR               : reg_data_out_2 <= desc_2_axuser_9_reg             ;        
                `DESC_2_AXUSER_10_REG_ADDR              : reg_data_out_2 <= desc_2_axuser_10_reg            ;        
                `DESC_2_AXUSER_11_REG_ADDR              : reg_data_out_2 <= desc_2_axuser_11_reg            ;        
                `DESC_2_AXUSER_12_REG_ADDR              : reg_data_out_2 <= desc_2_axuser_12_reg            ;        
                `DESC_2_AXUSER_13_REG_ADDR              : reg_data_out_2 <= desc_2_axuser_13_reg            ;        
                `DESC_2_AXUSER_14_REG_ADDR              : reg_data_out_2 <= desc_2_axuser_14_reg            ;        
                `DESC_2_AXUSER_15_REG_ADDR              : reg_data_out_2 <= desc_2_axuser_15_reg            ;        
                `DESC_2_XUSER_0_REG_ADDR                : reg_data_out_2 <= desc_2_xuser_0_reg              ;        
                `DESC_2_XUSER_1_REG_ADDR                : reg_data_out_2 <= desc_2_xuser_1_reg              ;        
                `DESC_2_XUSER_2_REG_ADDR                : reg_data_out_2 <= desc_2_xuser_2_reg              ;        
                `DESC_2_XUSER_3_REG_ADDR                : reg_data_out_2 <= desc_2_xuser_3_reg              ;        
                `DESC_2_XUSER_4_REG_ADDR                : reg_data_out_2 <= desc_2_xuser_4_reg              ;        
                `DESC_2_XUSER_5_REG_ADDR                : reg_data_out_2 <= desc_2_xuser_5_reg              ;        
                `DESC_2_XUSER_6_REG_ADDR                : reg_data_out_2 <= desc_2_xuser_6_reg              ;        
                `DESC_2_XUSER_7_REG_ADDR                : reg_data_out_2 <= desc_2_xuser_7_reg              ;        
                `DESC_2_XUSER_8_REG_ADDR                : reg_data_out_2 <= desc_2_xuser_8_reg              ;        
                `DESC_2_XUSER_9_REG_ADDR                : reg_data_out_2 <= desc_2_xuser_9_reg              ;        
                `DESC_2_XUSER_10_REG_ADDR               : reg_data_out_2 <= desc_2_xuser_10_reg             ;        
                `DESC_2_XUSER_11_REG_ADDR               : reg_data_out_2 <= desc_2_xuser_11_reg             ;        
                `DESC_2_XUSER_12_REG_ADDR               : reg_data_out_2 <= desc_2_xuser_12_reg             ;        
                `DESC_2_XUSER_13_REG_ADDR               : reg_data_out_2 <= desc_2_xuser_13_reg             ;        
                `DESC_2_XUSER_14_REG_ADDR               : reg_data_out_2 <= desc_2_xuser_14_reg             ;        
                `DESC_2_XUSER_15_REG_ADDR               : reg_data_out_2 <= desc_2_xuser_15_reg             ;        
                `DESC_2_WUSER_0_REG_ADDR                : reg_data_out_2 <= desc_2_wuser_0_reg              ;        
                `DESC_2_WUSER_1_REG_ADDR                : reg_data_out_2 <= desc_2_wuser_1_reg              ;        
                `DESC_2_WUSER_2_REG_ADDR                : reg_data_out_2 <= desc_2_wuser_2_reg              ;        
                `DESC_2_WUSER_3_REG_ADDR                : reg_data_out_2 <= desc_2_wuser_3_reg              ;        
                `DESC_2_WUSER_4_REG_ADDR                : reg_data_out_2 <= desc_2_wuser_4_reg              ;        
                `DESC_2_WUSER_5_REG_ADDR                : reg_data_out_2 <= desc_2_wuser_5_reg              ;        
                `DESC_2_WUSER_6_REG_ADDR                : reg_data_out_2 <= desc_2_wuser_6_reg              ;        
                `DESC_2_WUSER_7_REG_ADDR                : reg_data_out_2 <= desc_2_wuser_7_reg              ;        
                `DESC_2_WUSER_8_REG_ADDR                : reg_data_out_2 <= desc_2_wuser_8_reg              ;        
                `DESC_2_WUSER_9_REG_ADDR                : reg_data_out_2 <= desc_2_wuser_9_reg              ;        
                `DESC_2_WUSER_10_REG_ADDR               : reg_data_out_2 <= desc_2_wuser_10_reg             ;        
                `DESC_2_WUSER_11_REG_ADDR               : reg_data_out_2 <= desc_2_wuser_11_reg             ;        
                `DESC_2_WUSER_12_REG_ADDR               : reg_data_out_2 <= desc_2_wuser_12_reg             ;        
                `DESC_2_WUSER_13_REG_ADDR               : reg_data_out_2 <= desc_2_wuser_13_reg             ;        
                `DESC_2_WUSER_14_REG_ADDR               : reg_data_out_2 <= desc_2_wuser_14_reg             ;        
                `DESC_2_WUSER_15_REG_ADDR               : reg_data_out_2 <= desc_2_wuser_15_reg             ;        
                `DESC_3_TXN_TYPE_REG_ADDR               : reg_data_out_2 <= desc_3_txn_type_reg             ;        
                `DESC_3_SIZE_REG_ADDR                   : reg_data_out_2 <= desc_3_size_reg                 ;        
                `DESC_3_DATA_OFFSET_REG_ADDR            : reg_data_out_2 <= desc_3_data_offset_reg          ;        
                `DESC_3_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_2 <= desc_3_data_host_addr_0_reg     ;        
                `DESC_3_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_2 <= desc_3_data_host_addr_1_reg     ;        
                `DESC_3_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_2 <= desc_3_data_host_addr_2_reg     ;        
                `DESC_3_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_2 <= desc_3_data_host_addr_3_reg     ;        
                `DESC_3_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_2 <= desc_3_wstrb_host_addr_0_reg    ;        
                `DESC_3_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_2 <= desc_3_wstrb_host_addr_1_reg    ;        
                `DESC_3_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_2 <= desc_3_wstrb_host_addr_2_reg    ;        
                `DESC_3_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_2 <= desc_3_wstrb_host_addr_3_reg    ;        
                `DESC_3_AXSIZE_REG_ADDR                 : reg_data_out_2 <= desc_3_axsize_reg               ;        
                `DESC_3_ATTR_REG_ADDR                   : reg_data_out_2 <= desc_3_attr_reg                 ;        
                `DESC_3_AXADDR_0_REG_ADDR               : reg_data_out_2 <= desc_3_axaddr_0_reg             ;        
                `DESC_3_AXADDR_1_REG_ADDR               : reg_data_out_2 <= desc_3_axaddr_1_reg             ;        
                `DESC_3_AXADDR_2_REG_ADDR               : reg_data_out_2 <= desc_3_axaddr_2_reg             ;        
                `DESC_3_AXADDR_3_REG_ADDR               : reg_data_out_2 <= desc_3_axaddr_3_reg             ;        
                `DESC_3_AXID_0_REG_ADDR                 : reg_data_out_2 <= desc_3_axid_0_reg               ;        
                `DESC_3_AXID_1_REG_ADDR                 : reg_data_out_2 <= desc_3_axid_1_reg               ;        
                `DESC_3_AXID_2_REG_ADDR                 : reg_data_out_2 <= desc_3_axid_2_reg               ;        
                `DESC_3_AXID_3_REG_ADDR                 : reg_data_out_2 <= desc_3_axid_3_reg               ;        
                `DESC_3_AXUSER_0_REG_ADDR               : reg_data_out_2 <= desc_3_axuser_0_reg             ;        
                `DESC_3_AXUSER_1_REG_ADDR               : reg_data_out_2 <= desc_3_axuser_1_reg             ;        
                `DESC_3_AXUSER_2_REG_ADDR               : reg_data_out_2 <= desc_3_axuser_2_reg             ;        
                `DESC_3_AXUSER_3_REG_ADDR               : reg_data_out_2 <= desc_3_axuser_3_reg             ;        
                `DESC_3_AXUSER_4_REG_ADDR               : reg_data_out_2 <= desc_3_axuser_4_reg             ;        
                `DESC_3_AXUSER_5_REG_ADDR               : reg_data_out_2 <= desc_3_axuser_5_reg             ;        
                `DESC_3_AXUSER_6_REG_ADDR               : reg_data_out_2 <= desc_3_axuser_6_reg             ;        
                `DESC_3_AXUSER_7_REG_ADDR               : reg_data_out_2 <= desc_3_axuser_7_reg             ;        
                `DESC_3_AXUSER_8_REG_ADDR               : reg_data_out_2 <= desc_3_axuser_8_reg             ;        
                `DESC_3_AXUSER_9_REG_ADDR               : reg_data_out_2 <= desc_3_axuser_9_reg             ;        
                `DESC_3_AXUSER_10_REG_ADDR              : reg_data_out_2 <= desc_3_axuser_10_reg            ;        
                `DESC_3_AXUSER_11_REG_ADDR              : reg_data_out_2 <= desc_3_axuser_11_reg            ;        
                `DESC_3_AXUSER_12_REG_ADDR              : reg_data_out_2 <= desc_3_axuser_12_reg            ;        
                `DESC_3_AXUSER_13_REG_ADDR              : reg_data_out_2 <= desc_3_axuser_13_reg            ;        
                `DESC_3_AXUSER_14_REG_ADDR              : reg_data_out_2 <= desc_3_axuser_14_reg            ;        
                `DESC_3_AXUSER_15_REG_ADDR              : reg_data_out_2 <= desc_3_axuser_15_reg            ;        
                `DESC_3_XUSER_0_REG_ADDR                : reg_data_out_2 <= desc_3_xuser_0_reg              ;        
                `DESC_3_XUSER_1_REG_ADDR                : reg_data_out_2 <= desc_3_xuser_1_reg              ;        
                `DESC_3_XUSER_2_REG_ADDR                : reg_data_out_2 <= desc_3_xuser_2_reg              ;        
                `DESC_3_XUSER_3_REG_ADDR                : reg_data_out_2 <= desc_3_xuser_3_reg              ;        
                `DESC_3_XUSER_4_REG_ADDR                : reg_data_out_2 <= desc_3_xuser_4_reg              ;        
                `DESC_3_XUSER_5_REG_ADDR                : reg_data_out_2 <= desc_3_xuser_5_reg              ;        
                `DESC_3_XUSER_6_REG_ADDR                : reg_data_out_2 <= desc_3_xuser_6_reg              ;        
                `DESC_3_XUSER_7_REG_ADDR                : reg_data_out_2 <= desc_3_xuser_7_reg              ;        
                `DESC_3_XUSER_8_REG_ADDR                : reg_data_out_2 <= desc_3_xuser_8_reg              ;        
                `DESC_3_XUSER_9_REG_ADDR                : reg_data_out_2 <= desc_3_xuser_9_reg              ;        
                `DESC_3_XUSER_10_REG_ADDR               : reg_data_out_2 <= desc_3_xuser_10_reg             ;        
                `DESC_3_XUSER_11_REG_ADDR               : reg_data_out_2 <= desc_3_xuser_11_reg             ;        
                `DESC_3_XUSER_12_REG_ADDR               : reg_data_out_2 <= desc_3_xuser_12_reg             ;        
                `DESC_3_XUSER_13_REG_ADDR               : reg_data_out_2 <= desc_3_xuser_13_reg             ;        
                `DESC_3_XUSER_14_REG_ADDR               : reg_data_out_2 <= desc_3_xuser_14_reg             ;        
                `DESC_3_XUSER_15_REG_ADDR               : reg_data_out_2 <= desc_3_xuser_15_reg             ;        
                `DESC_3_WUSER_0_REG_ADDR                : reg_data_out_2 <= desc_3_wuser_0_reg              ;        
                `DESC_3_WUSER_1_REG_ADDR                : reg_data_out_2 <= desc_3_wuser_1_reg              ;        
                `DESC_3_WUSER_2_REG_ADDR                : reg_data_out_2 <= desc_3_wuser_2_reg              ;        
                `DESC_3_WUSER_3_REG_ADDR                : reg_data_out_2 <= desc_3_wuser_3_reg              ;        
                `DESC_3_WUSER_4_REG_ADDR                : reg_data_out_2 <= desc_3_wuser_4_reg              ;        
                `DESC_3_WUSER_5_REG_ADDR                : reg_data_out_2 <= desc_3_wuser_5_reg              ;        
                `DESC_3_WUSER_6_REG_ADDR                : reg_data_out_2 <= desc_3_wuser_6_reg              ;        
                `DESC_3_WUSER_7_REG_ADDR                : reg_data_out_2 <= desc_3_wuser_7_reg              ;        
                `DESC_3_WUSER_8_REG_ADDR                : reg_data_out_2 <= desc_3_wuser_8_reg              ;        
                `DESC_3_WUSER_9_REG_ADDR                : reg_data_out_2 <= desc_3_wuser_9_reg              ;        
                `DESC_3_WUSER_10_REG_ADDR               : reg_data_out_2 <= desc_3_wuser_10_reg             ;        
                `DESC_3_WUSER_11_REG_ADDR               : reg_data_out_2 <= desc_3_wuser_11_reg             ;        
                `DESC_3_WUSER_12_REG_ADDR               : reg_data_out_2 <= desc_3_wuser_12_reg             ;        
                `DESC_3_WUSER_13_REG_ADDR               : reg_data_out_2 <= desc_3_wuser_13_reg             ;        
                `DESC_3_WUSER_14_REG_ADDR               : reg_data_out_2 <= desc_3_wuser_14_reg             ;        
                `DESC_3_WUSER_15_REG_ADDR               : reg_data_out_2 <= desc_3_wuser_15_reg             ;        

                default                                  :reg_data_out_2 <= 32'b0      ;        
              endcase
              end
            else
              begin
                 reg_block_hit_2 <= 1'b0;
                 reg_data_out_2 <= reg_data_out_2;
              end
         end
    end
   

    always @( posedge axi_aclk )
    begin
       if (~axi_aresetn)
         begin
            reg_data_out_3 <= 32'b0;
            reg_block_hit_3 <= 1'b0;
         end
       else
         begin
            if (~|axi_araddr[BRIDGE_MSB:14] && (&axi_araddr[13:11])) //access to reg block 3
              begin
                 reg_block_hit_3 <= 1'b1;                 

              case ({6'b000111,axi_araddr[10:0]})    
                `DESC_4_TXN_TYPE_REG_ADDR               : reg_data_out_3 <= desc_4_txn_type_reg             ;        
                `DESC_4_SIZE_REG_ADDR                   : reg_data_out_3 <= desc_4_size_reg                 ;        
                `DESC_4_DATA_OFFSET_REG_ADDR            : reg_data_out_3 <= desc_4_data_offset_reg          ;        
                `DESC_4_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_3 <= desc_4_data_host_addr_0_reg     ;        
                `DESC_4_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_3 <= desc_4_data_host_addr_1_reg     ;        
                `DESC_4_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_3 <= desc_4_data_host_addr_2_reg     ;        
                `DESC_4_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_3 <= desc_4_data_host_addr_3_reg     ;        
                `DESC_4_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_3 <= desc_4_wstrb_host_addr_0_reg    ;        
                `DESC_4_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_3 <= desc_4_wstrb_host_addr_1_reg    ;        
                `DESC_4_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_3 <= desc_4_wstrb_host_addr_2_reg    ;        
                `DESC_4_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_3 <= desc_4_wstrb_host_addr_3_reg    ;        
                `DESC_4_AXSIZE_REG_ADDR                 : reg_data_out_3 <= desc_4_axsize_reg               ;        
                `DESC_4_ATTR_REG_ADDR                   : reg_data_out_3 <= desc_4_attr_reg                 ;        
                `DESC_4_AXADDR_0_REG_ADDR               : reg_data_out_3 <= desc_4_axaddr_0_reg             ;        
                `DESC_4_AXADDR_1_REG_ADDR               : reg_data_out_3 <= desc_4_axaddr_1_reg             ;        
                `DESC_4_AXADDR_2_REG_ADDR               : reg_data_out_3 <= desc_4_axaddr_2_reg             ;        
                `DESC_4_AXADDR_3_REG_ADDR               : reg_data_out_3 <= desc_4_axaddr_3_reg             ;        
                `DESC_4_AXID_0_REG_ADDR                 : reg_data_out_3 <= desc_4_axid_0_reg               ;        
                `DESC_4_AXID_1_REG_ADDR                 : reg_data_out_3 <= desc_4_axid_1_reg               ;        
                `DESC_4_AXID_2_REG_ADDR                 : reg_data_out_3 <= desc_4_axid_2_reg               ;        
                `DESC_4_AXID_3_REG_ADDR                 : reg_data_out_3 <= desc_4_axid_3_reg               ;        
                `DESC_4_AXUSER_0_REG_ADDR               : reg_data_out_3 <= desc_4_axuser_0_reg             ;        
                `DESC_4_AXUSER_1_REG_ADDR               : reg_data_out_3 <= desc_4_axuser_1_reg             ;        
                `DESC_4_AXUSER_2_REG_ADDR               : reg_data_out_3 <= desc_4_axuser_2_reg             ;        
                `DESC_4_AXUSER_3_REG_ADDR               : reg_data_out_3 <= desc_4_axuser_3_reg             ;        
                `DESC_4_AXUSER_4_REG_ADDR               : reg_data_out_3 <= desc_4_axuser_4_reg             ;        
                `DESC_4_AXUSER_5_REG_ADDR               : reg_data_out_3 <= desc_4_axuser_5_reg             ;        
                `DESC_4_AXUSER_6_REG_ADDR               : reg_data_out_3 <= desc_4_axuser_6_reg             ;        
                `DESC_4_AXUSER_7_REG_ADDR               : reg_data_out_3 <= desc_4_axuser_7_reg             ;        
                `DESC_4_AXUSER_8_REG_ADDR               : reg_data_out_3 <= desc_4_axuser_8_reg             ;        
                `DESC_4_AXUSER_9_REG_ADDR               : reg_data_out_3 <= desc_4_axuser_9_reg             ;        
                `DESC_4_AXUSER_10_REG_ADDR              : reg_data_out_3 <= desc_4_axuser_10_reg            ;        
                `DESC_4_AXUSER_11_REG_ADDR              : reg_data_out_3 <= desc_4_axuser_11_reg            ;        
                `DESC_4_AXUSER_12_REG_ADDR              : reg_data_out_3 <= desc_4_axuser_12_reg            ;        
                `DESC_4_AXUSER_13_REG_ADDR              : reg_data_out_3 <= desc_4_axuser_13_reg            ;        
                `DESC_4_AXUSER_14_REG_ADDR              : reg_data_out_3 <= desc_4_axuser_14_reg            ;        
                `DESC_4_AXUSER_15_REG_ADDR              : reg_data_out_3 <= desc_4_axuser_15_reg            ;        
                `DESC_4_XUSER_0_REG_ADDR                : reg_data_out_3 <= desc_4_xuser_0_reg              ;        
                `DESC_4_XUSER_1_REG_ADDR                : reg_data_out_3 <= desc_4_xuser_1_reg              ;        
                `DESC_4_XUSER_2_REG_ADDR                : reg_data_out_3 <= desc_4_xuser_2_reg              ;        
                `DESC_4_XUSER_3_REG_ADDR                : reg_data_out_3 <= desc_4_xuser_3_reg              ;        
                `DESC_4_XUSER_4_REG_ADDR                : reg_data_out_3 <= desc_4_xuser_4_reg              ;        
                `DESC_4_XUSER_5_REG_ADDR                : reg_data_out_3 <= desc_4_xuser_5_reg              ;        
                `DESC_4_XUSER_6_REG_ADDR                : reg_data_out_3 <= desc_4_xuser_6_reg              ;        
                `DESC_4_XUSER_7_REG_ADDR                : reg_data_out_3 <= desc_4_xuser_7_reg              ;        
                `DESC_4_XUSER_8_REG_ADDR                : reg_data_out_3 <= desc_4_xuser_8_reg              ;        
                `DESC_4_XUSER_9_REG_ADDR                : reg_data_out_3 <= desc_4_xuser_9_reg              ;        
                `DESC_4_XUSER_10_REG_ADDR               : reg_data_out_3 <= desc_4_xuser_10_reg             ;        
                `DESC_4_XUSER_11_REG_ADDR               : reg_data_out_3 <= desc_4_xuser_11_reg             ;        
                `DESC_4_XUSER_12_REG_ADDR               : reg_data_out_3 <= desc_4_xuser_12_reg             ;        
                `DESC_4_XUSER_13_REG_ADDR               : reg_data_out_3 <= desc_4_xuser_13_reg             ;        
                `DESC_4_XUSER_14_REG_ADDR               : reg_data_out_3 <= desc_4_xuser_14_reg             ;        
                `DESC_4_XUSER_15_REG_ADDR               : reg_data_out_3 <= desc_4_xuser_15_reg             ;        
                `DESC_4_WUSER_0_REG_ADDR                : reg_data_out_3 <= desc_4_wuser_0_reg              ;        
                `DESC_4_WUSER_1_REG_ADDR                : reg_data_out_3 <= desc_4_wuser_1_reg              ;        
                `DESC_4_WUSER_2_REG_ADDR                : reg_data_out_3 <= desc_4_wuser_2_reg              ;        
                `DESC_4_WUSER_3_REG_ADDR                : reg_data_out_3 <= desc_4_wuser_3_reg              ;        
                `DESC_4_WUSER_4_REG_ADDR                : reg_data_out_3 <= desc_4_wuser_4_reg              ;        
                `DESC_4_WUSER_5_REG_ADDR                : reg_data_out_3 <= desc_4_wuser_5_reg              ;        
                `DESC_4_WUSER_6_REG_ADDR                : reg_data_out_3 <= desc_4_wuser_6_reg              ;        
                `DESC_4_WUSER_7_REG_ADDR                : reg_data_out_3 <= desc_4_wuser_7_reg              ;        
                `DESC_4_WUSER_8_REG_ADDR                : reg_data_out_3 <= desc_4_wuser_8_reg              ;        
                `DESC_4_WUSER_9_REG_ADDR                : reg_data_out_3 <= desc_4_wuser_9_reg              ;        
                `DESC_4_WUSER_10_REG_ADDR               : reg_data_out_3 <= desc_4_wuser_10_reg             ;        
                `DESC_4_WUSER_11_REG_ADDR               : reg_data_out_3 <= desc_4_wuser_11_reg             ;        
                `DESC_4_WUSER_12_REG_ADDR               : reg_data_out_3 <= desc_4_wuser_12_reg             ;        
                `DESC_4_WUSER_13_REG_ADDR               : reg_data_out_3 <= desc_4_wuser_13_reg             ;        
                `DESC_4_WUSER_14_REG_ADDR               : reg_data_out_3 <= desc_4_wuser_14_reg             ;        
                `DESC_4_WUSER_15_REG_ADDR               : reg_data_out_3 <= desc_4_wuser_15_reg             ;        
                `DESC_5_TXN_TYPE_REG_ADDR               : reg_data_out_3 <= desc_5_txn_type_reg             ;        
                `DESC_5_SIZE_REG_ADDR                   : reg_data_out_3 <= desc_5_size_reg                 ;        
                `DESC_5_DATA_OFFSET_REG_ADDR            : reg_data_out_3 <= desc_5_data_offset_reg          ;        
                `DESC_5_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_3 <= desc_5_data_host_addr_0_reg     ;        
                `DESC_5_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_3 <= desc_5_data_host_addr_1_reg     ;        
                `DESC_5_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_3 <= desc_5_data_host_addr_2_reg     ;        
                `DESC_5_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_3 <= desc_5_data_host_addr_3_reg     ;        
                `DESC_5_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_3 <= desc_5_wstrb_host_addr_0_reg    ;        
                `DESC_5_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_3 <= desc_5_wstrb_host_addr_1_reg    ;        
                `DESC_5_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_3 <= desc_5_wstrb_host_addr_2_reg    ;        
                `DESC_5_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_3 <= desc_5_wstrb_host_addr_3_reg    ;        
                `DESC_5_AXSIZE_REG_ADDR                 : reg_data_out_3 <= desc_5_axsize_reg               ;        
                `DESC_5_ATTR_REG_ADDR                   : reg_data_out_3 <= desc_5_attr_reg                 ;        
                `DESC_5_AXADDR_0_REG_ADDR               : reg_data_out_3 <= desc_5_axaddr_0_reg             ;        
                `DESC_5_AXADDR_1_REG_ADDR               : reg_data_out_3 <= desc_5_axaddr_1_reg             ;        
                `DESC_5_AXADDR_2_REG_ADDR               : reg_data_out_3 <= desc_5_axaddr_2_reg             ;        
                `DESC_5_AXADDR_3_REG_ADDR               : reg_data_out_3 <= desc_5_axaddr_3_reg             ;        
                `DESC_5_AXID_0_REG_ADDR                 : reg_data_out_3 <= desc_5_axid_0_reg               ;        
                `DESC_5_AXID_1_REG_ADDR                 : reg_data_out_3 <= desc_5_axid_1_reg               ;        
                `DESC_5_AXID_2_REG_ADDR                 : reg_data_out_3 <= desc_5_axid_2_reg               ;        
                `DESC_5_AXID_3_REG_ADDR                 : reg_data_out_3 <= desc_5_axid_3_reg               ;        
                `DESC_5_AXUSER_0_REG_ADDR               : reg_data_out_3 <= desc_5_axuser_0_reg             ;        
                `DESC_5_AXUSER_1_REG_ADDR               : reg_data_out_3 <= desc_5_axuser_1_reg             ;        
                `DESC_5_AXUSER_2_REG_ADDR               : reg_data_out_3 <= desc_5_axuser_2_reg             ;        
                `DESC_5_AXUSER_3_REG_ADDR               : reg_data_out_3 <= desc_5_axuser_3_reg             ;        
                `DESC_5_AXUSER_4_REG_ADDR               : reg_data_out_3 <= desc_5_axuser_4_reg             ;        
                `DESC_5_AXUSER_5_REG_ADDR               : reg_data_out_3 <= desc_5_axuser_5_reg             ;        
                `DESC_5_AXUSER_6_REG_ADDR               : reg_data_out_3 <= desc_5_axuser_6_reg             ;        
                `DESC_5_AXUSER_7_REG_ADDR               : reg_data_out_3 <= desc_5_axuser_7_reg             ;        
                `DESC_5_AXUSER_8_REG_ADDR               : reg_data_out_3 <= desc_5_axuser_8_reg             ;        
                `DESC_5_AXUSER_9_REG_ADDR               : reg_data_out_3 <= desc_5_axuser_9_reg             ;        
                `DESC_5_AXUSER_10_REG_ADDR              : reg_data_out_3 <= desc_5_axuser_10_reg            ;        
                `DESC_5_AXUSER_11_REG_ADDR              : reg_data_out_3 <= desc_5_axuser_11_reg            ;        
                `DESC_5_AXUSER_12_REG_ADDR              : reg_data_out_3 <= desc_5_axuser_12_reg            ;        
                `DESC_5_AXUSER_13_REG_ADDR              : reg_data_out_3 <= desc_5_axuser_13_reg            ;        
                `DESC_5_AXUSER_14_REG_ADDR              : reg_data_out_3 <= desc_5_axuser_14_reg            ;        
                `DESC_5_AXUSER_15_REG_ADDR              : reg_data_out_3 <= desc_5_axuser_15_reg            ;        
                `DESC_5_XUSER_0_REG_ADDR                : reg_data_out_3 <= desc_5_xuser_0_reg              ;        
                `DESC_5_XUSER_1_REG_ADDR                : reg_data_out_3 <= desc_5_xuser_1_reg              ;        
                `DESC_5_XUSER_2_REG_ADDR                : reg_data_out_3 <= desc_5_xuser_2_reg              ;        
                `DESC_5_XUSER_3_REG_ADDR                : reg_data_out_3 <= desc_5_xuser_3_reg              ;        
                `DESC_5_XUSER_4_REG_ADDR                : reg_data_out_3 <= desc_5_xuser_4_reg              ;        
                `DESC_5_XUSER_5_REG_ADDR                : reg_data_out_3 <= desc_5_xuser_5_reg              ;        
                `DESC_5_XUSER_6_REG_ADDR                : reg_data_out_3 <= desc_5_xuser_6_reg              ;        
                `DESC_5_XUSER_7_REG_ADDR                : reg_data_out_3 <= desc_5_xuser_7_reg              ;        
                `DESC_5_XUSER_8_REG_ADDR                : reg_data_out_3 <= desc_5_xuser_8_reg              ;        
                `DESC_5_XUSER_9_REG_ADDR                : reg_data_out_3 <= desc_5_xuser_9_reg              ;        
                `DESC_5_XUSER_10_REG_ADDR               : reg_data_out_3 <= desc_5_xuser_10_reg             ;        
                `DESC_5_XUSER_11_REG_ADDR               : reg_data_out_3 <= desc_5_xuser_11_reg             ;        
                `DESC_5_XUSER_12_REG_ADDR               : reg_data_out_3 <= desc_5_xuser_12_reg             ;        
                `DESC_5_XUSER_13_REG_ADDR               : reg_data_out_3 <= desc_5_xuser_13_reg             ;        
                `DESC_5_XUSER_14_REG_ADDR               : reg_data_out_3 <= desc_5_xuser_14_reg             ;        
                `DESC_5_XUSER_15_REG_ADDR               : reg_data_out_3 <= desc_5_xuser_15_reg             ;        
                `DESC_5_WUSER_0_REG_ADDR                : reg_data_out_3 <= desc_5_wuser_0_reg              ;        
                `DESC_5_WUSER_1_REG_ADDR                : reg_data_out_3 <= desc_5_wuser_1_reg              ;        
                `DESC_5_WUSER_2_REG_ADDR                : reg_data_out_3 <= desc_5_wuser_2_reg              ;        
                `DESC_5_WUSER_3_REG_ADDR                : reg_data_out_3 <= desc_5_wuser_3_reg              ;        
                `DESC_5_WUSER_4_REG_ADDR                : reg_data_out_3 <= desc_5_wuser_4_reg              ;        
                `DESC_5_WUSER_5_REG_ADDR                : reg_data_out_3 <= desc_5_wuser_5_reg              ;        
                `DESC_5_WUSER_6_REG_ADDR                : reg_data_out_3 <= desc_5_wuser_6_reg              ;        
                `DESC_5_WUSER_7_REG_ADDR                : reg_data_out_3 <= desc_5_wuser_7_reg              ;        
                `DESC_5_WUSER_8_REG_ADDR                : reg_data_out_3 <= desc_5_wuser_8_reg              ;        
                `DESC_5_WUSER_9_REG_ADDR                : reg_data_out_3 <= desc_5_wuser_9_reg              ;        
                `DESC_5_WUSER_10_REG_ADDR               : reg_data_out_3 <= desc_5_wuser_10_reg             ;        
                `DESC_5_WUSER_11_REG_ADDR               : reg_data_out_3 <= desc_5_wuser_11_reg             ;        
                `DESC_5_WUSER_12_REG_ADDR               : reg_data_out_3 <= desc_5_wuser_12_reg             ;        
                `DESC_5_WUSER_13_REG_ADDR               : reg_data_out_3 <= desc_5_wuser_13_reg             ;        
                `DESC_5_WUSER_14_REG_ADDR               : reg_data_out_3 <= desc_5_wuser_14_reg             ;        
                `DESC_5_WUSER_15_REG_ADDR               : reg_data_out_3 <= desc_5_wuser_15_reg             ;        
                `DESC_6_TXN_TYPE_REG_ADDR               : reg_data_out_3 <= desc_6_txn_type_reg             ;        
                `DESC_6_SIZE_REG_ADDR                   : reg_data_out_3 <= desc_6_size_reg                 ;        
                `DESC_6_DATA_OFFSET_REG_ADDR            : reg_data_out_3 <= desc_6_data_offset_reg          ;        
                `DESC_6_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_3 <= desc_6_data_host_addr_0_reg     ;        
                `DESC_6_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_3 <= desc_6_data_host_addr_1_reg     ;        
                `DESC_6_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_3 <= desc_6_data_host_addr_2_reg     ;        
                `DESC_6_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_3 <= desc_6_data_host_addr_3_reg     ;        
                `DESC_6_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_3 <= desc_6_wstrb_host_addr_0_reg    ;        
                `DESC_6_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_3 <= desc_6_wstrb_host_addr_1_reg    ;        
                `DESC_6_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_3 <= desc_6_wstrb_host_addr_2_reg    ;        
                `DESC_6_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_3 <= desc_6_wstrb_host_addr_3_reg    ;        
                `DESC_6_AXSIZE_REG_ADDR                 : reg_data_out_3 <= desc_6_axsize_reg               ;        
                `DESC_6_ATTR_REG_ADDR                   : reg_data_out_3 <= desc_6_attr_reg                 ;        
                `DESC_6_AXADDR_0_REG_ADDR               : reg_data_out_3 <= desc_6_axaddr_0_reg             ;        
                `DESC_6_AXADDR_1_REG_ADDR               : reg_data_out_3 <= desc_6_axaddr_1_reg             ;        
                `DESC_6_AXADDR_2_REG_ADDR               : reg_data_out_3 <= desc_6_axaddr_2_reg             ;        
                `DESC_6_AXADDR_3_REG_ADDR               : reg_data_out_3 <= desc_6_axaddr_3_reg             ;        
                `DESC_6_AXID_0_REG_ADDR                 : reg_data_out_3 <= desc_6_axid_0_reg               ;        
                `DESC_6_AXID_1_REG_ADDR                 : reg_data_out_3 <= desc_6_axid_1_reg               ;        
                `DESC_6_AXID_2_REG_ADDR                 : reg_data_out_3 <= desc_6_axid_2_reg               ;        
                `DESC_6_AXID_3_REG_ADDR                 : reg_data_out_3 <= desc_6_axid_3_reg               ;        
                `DESC_6_AXUSER_0_REG_ADDR               : reg_data_out_3 <= desc_6_axuser_0_reg             ;        
                `DESC_6_AXUSER_1_REG_ADDR               : reg_data_out_3 <= desc_6_axuser_1_reg             ;        
                `DESC_6_AXUSER_2_REG_ADDR               : reg_data_out_3 <= desc_6_axuser_2_reg             ;        
                `DESC_6_AXUSER_3_REG_ADDR               : reg_data_out_3 <= desc_6_axuser_3_reg             ;        
                `DESC_6_AXUSER_4_REG_ADDR               : reg_data_out_3 <= desc_6_axuser_4_reg             ;        
                `DESC_6_AXUSER_5_REG_ADDR               : reg_data_out_3 <= desc_6_axuser_5_reg             ;        
                `DESC_6_AXUSER_6_REG_ADDR               : reg_data_out_3 <= desc_6_axuser_6_reg             ;        
                `DESC_6_AXUSER_7_REG_ADDR               : reg_data_out_3 <= desc_6_axuser_7_reg             ;        
                `DESC_6_AXUSER_8_REG_ADDR               : reg_data_out_3 <= desc_6_axuser_8_reg             ;        
                `DESC_6_AXUSER_9_REG_ADDR               : reg_data_out_3 <= desc_6_axuser_9_reg             ;        
                `DESC_6_AXUSER_10_REG_ADDR              : reg_data_out_3 <= desc_6_axuser_10_reg            ;        
                `DESC_6_AXUSER_11_REG_ADDR              : reg_data_out_3 <= desc_6_axuser_11_reg            ;        
                `DESC_6_AXUSER_12_REG_ADDR              : reg_data_out_3 <= desc_6_axuser_12_reg            ;        
                `DESC_6_AXUSER_13_REG_ADDR              : reg_data_out_3 <= desc_6_axuser_13_reg            ;        
                `DESC_6_AXUSER_14_REG_ADDR              : reg_data_out_3 <= desc_6_axuser_14_reg            ;        
                `DESC_6_AXUSER_15_REG_ADDR              : reg_data_out_3 <= desc_6_axuser_15_reg            ;        
                `DESC_6_XUSER_0_REG_ADDR                : reg_data_out_3 <= desc_6_xuser_0_reg              ;        
                `DESC_6_XUSER_1_REG_ADDR                : reg_data_out_3 <= desc_6_xuser_1_reg              ;        
                `DESC_6_XUSER_2_REG_ADDR                : reg_data_out_3 <= desc_6_xuser_2_reg              ;        
                `DESC_6_XUSER_3_REG_ADDR                : reg_data_out_3 <= desc_6_xuser_3_reg              ;        
                `DESC_6_XUSER_4_REG_ADDR                : reg_data_out_3 <= desc_6_xuser_4_reg              ;        
                `DESC_6_XUSER_5_REG_ADDR                : reg_data_out_3 <= desc_6_xuser_5_reg              ;        
                `DESC_6_XUSER_6_REG_ADDR                : reg_data_out_3 <= desc_6_xuser_6_reg              ;        
                `DESC_6_XUSER_7_REG_ADDR                : reg_data_out_3 <= desc_6_xuser_7_reg              ;        
                `DESC_6_XUSER_8_REG_ADDR                : reg_data_out_3 <= desc_6_xuser_8_reg              ;        
                `DESC_6_XUSER_9_REG_ADDR                : reg_data_out_3 <= desc_6_xuser_9_reg              ;        
                `DESC_6_XUSER_10_REG_ADDR               : reg_data_out_3 <= desc_6_xuser_10_reg             ;        
                `DESC_6_XUSER_11_REG_ADDR               : reg_data_out_3 <= desc_6_xuser_11_reg             ;        
                `DESC_6_XUSER_12_REG_ADDR               : reg_data_out_3 <= desc_6_xuser_12_reg             ;        
                `DESC_6_XUSER_13_REG_ADDR               : reg_data_out_3 <= desc_6_xuser_13_reg             ;        
                `DESC_6_XUSER_14_REG_ADDR               : reg_data_out_3 <= desc_6_xuser_14_reg             ;        
                `DESC_6_XUSER_15_REG_ADDR               : reg_data_out_3 <= desc_6_xuser_15_reg             ;        
                `DESC_6_WUSER_0_REG_ADDR                : reg_data_out_3 <= desc_6_wuser_0_reg              ;        
                `DESC_6_WUSER_1_REG_ADDR                : reg_data_out_3 <= desc_6_wuser_1_reg              ;        
                `DESC_6_WUSER_2_REG_ADDR                : reg_data_out_3 <= desc_6_wuser_2_reg              ;        
                `DESC_6_WUSER_3_REG_ADDR                : reg_data_out_3 <= desc_6_wuser_3_reg              ;        
                `DESC_6_WUSER_4_REG_ADDR                : reg_data_out_3 <= desc_6_wuser_4_reg              ;        
                `DESC_6_WUSER_5_REG_ADDR                : reg_data_out_3 <= desc_6_wuser_5_reg              ;        
                `DESC_6_WUSER_6_REG_ADDR                : reg_data_out_3 <= desc_6_wuser_6_reg              ;        
                `DESC_6_WUSER_7_REG_ADDR                : reg_data_out_3 <= desc_6_wuser_7_reg              ;        
                `DESC_6_WUSER_8_REG_ADDR                : reg_data_out_3 <= desc_6_wuser_8_reg              ;        
                `DESC_6_WUSER_9_REG_ADDR                : reg_data_out_3 <= desc_6_wuser_9_reg              ;        
                `DESC_6_WUSER_10_REG_ADDR               : reg_data_out_3 <= desc_6_wuser_10_reg             ;        
                `DESC_6_WUSER_11_REG_ADDR               : reg_data_out_3 <= desc_6_wuser_11_reg             ;        
                `DESC_6_WUSER_12_REG_ADDR               : reg_data_out_3 <= desc_6_wuser_12_reg             ;        
                `DESC_6_WUSER_13_REG_ADDR               : reg_data_out_3 <= desc_6_wuser_13_reg             ;        
                `DESC_6_WUSER_14_REG_ADDR               : reg_data_out_3 <= desc_6_wuser_14_reg             ;        
                `DESC_6_WUSER_15_REG_ADDR               : reg_data_out_3 <= desc_6_wuser_15_reg             ;        
                `DESC_7_TXN_TYPE_REG_ADDR               : reg_data_out_3 <= desc_7_txn_type_reg             ;        
                `DESC_7_SIZE_REG_ADDR                   : reg_data_out_3 <= desc_7_size_reg                 ;        
                `DESC_7_DATA_OFFSET_REG_ADDR            : reg_data_out_3 <= desc_7_data_offset_reg          ;        
                `DESC_7_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_3 <= desc_7_data_host_addr_0_reg     ;        
                `DESC_7_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_3 <= desc_7_data_host_addr_1_reg     ;        
                `DESC_7_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_3 <= desc_7_data_host_addr_2_reg     ;        
                `DESC_7_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_3 <= desc_7_data_host_addr_3_reg     ;        
                `DESC_7_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_3 <= desc_7_wstrb_host_addr_0_reg    ;        
                `DESC_7_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_3 <= desc_7_wstrb_host_addr_1_reg    ;        
                `DESC_7_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_3 <= desc_7_wstrb_host_addr_2_reg    ;        
                `DESC_7_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_3 <= desc_7_wstrb_host_addr_3_reg    ;        
                `DESC_7_AXSIZE_REG_ADDR                 : reg_data_out_3 <= desc_7_axsize_reg               ;        
                `DESC_7_ATTR_REG_ADDR                   : reg_data_out_3 <= desc_7_attr_reg                 ;        
                `DESC_7_AXADDR_0_REG_ADDR               : reg_data_out_3 <= desc_7_axaddr_0_reg             ;        
                `DESC_7_AXADDR_1_REG_ADDR               : reg_data_out_3 <= desc_7_axaddr_1_reg             ;        
                `DESC_7_AXADDR_2_REG_ADDR               : reg_data_out_3 <= desc_7_axaddr_2_reg             ;        
                `DESC_7_AXADDR_3_REG_ADDR               : reg_data_out_3 <= desc_7_axaddr_3_reg             ;        
                `DESC_7_AXID_0_REG_ADDR                 : reg_data_out_3 <= desc_7_axid_0_reg               ;        
                `DESC_7_AXID_1_REG_ADDR                 : reg_data_out_3 <= desc_7_axid_1_reg               ;        
                `DESC_7_AXID_2_REG_ADDR                 : reg_data_out_3 <= desc_7_axid_2_reg               ;        
                `DESC_7_AXID_3_REG_ADDR                 : reg_data_out_3 <= desc_7_axid_3_reg               ;        
                `DESC_7_AXUSER_0_REG_ADDR               : reg_data_out_3 <= desc_7_axuser_0_reg             ;        
                `DESC_7_AXUSER_1_REG_ADDR               : reg_data_out_3 <= desc_7_axuser_1_reg             ;        
                `DESC_7_AXUSER_2_REG_ADDR               : reg_data_out_3 <= desc_7_axuser_2_reg             ;        
                `DESC_7_AXUSER_3_REG_ADDR               : reg_data_out_3 <= desc_7_axuser_3_reg             ;        
                `DESC_7_AXUSER_4_REG_ADDR               : reg_data_out_3 <= desc_7_axuser_4_reg             ;        
                `DESC_7_AXUSER_5_REG_ADDR               : reg_data_out_3 <= desc_7_axuser_5_reg             ;        
                `DESC_7_AXUSER_6_REG_ADDR               : reg_data_out_3 <= desc_7_axuser_6_reg             ;        
                `DESC_7_AXUSER_7_REG_ADDR               : reg_data_out_3 <= desc_7_axuser_7_reg             ;        
                `DESC_7_AXUSER_8_REG_ADDR               : reg_data_out_3 <= desc_7_axuser_8_reg             ;        
                `DESC_7_AXUSER_9_REG_ADDR               : reg_data_out_3 <= desc_7_axuser_9_reg             ;        
                `DESC_7_AXUSER_10_REG_ADDR              : reg_data_out_3 <= desc_7_axuser_10_reg            ;        
                `DESC_7_AXUSER_11_REG_ADDR              : reg_data_out_3 <= desc_7_axuser_11_reg            ;        
                `DESC_7_AXUSER_12_REG_ADDR              : reg_data_out_3 <= desc_7_axuser_12_reg            ;        
                `DESC_7_AXUSER_13_REG_ADDR              : reg_data_out_3 <= desc_7_axuser_13_reg            ;        
                `DESC_7_AXUSER_14_REG_ADDR              : reg_data_out_3 <= desc_7_axuser_14_reg            ;        
                `DESC_7_AXUSER_15_REG_ADDR              : reg_data_out_3 <= desc_7_axuser_15_reg            ;        
                `DESC_7_XUSER_0_REG_ADDR                : reg_data_out_3 <= desc_7_xuser_0_reg              ;        
                `DESC_7_XUSER_1_REG_ADDR                : reg_data_out_3 <= desc_7_xuser_1_reg              ;        
                `DESC_7_XUSER_2_REG_ADDR                : reg_data_out_3 <= desc_7_xuser_2_reg              ;        
                `DESC_7_XUSER_3_REG_ADDR                : reg_data_out_3 <= desc_7_xuser_3_reg              ;        
                `DESC_7_XUSER_4_REG_ADDR                : reg_data_out_3 <= desc_7_xuser_4_reg              ;        
                `DESC_7_XUSER_5_REG_ADDR                : reg_data_out_3 <= desc_7_xuser_5_reg              ;        
                `DESC_7_XUSER_6_REG_ADDR                : reg_data_out_3 <= desc_7_xuser_6_reg              ;        
                `DESC_7_XUSER_7_REG_ADDR                : reg_data_out_3 <= desc_7_xuser_7_reg              ;        
                `DESC_7_XUSER_8_REG_ADDR                : reg_data_out_3 <= desc_7_xuser_8_reg              ;        
                `DESC_7_XUSER_9_REG_ADDR                : reg_data_out_3 <= desc_7_xuser_9_reg              ;        
                `DESC_7_XUSER_10_REG_ADDR               : reg_data_out_3 <= desc_7_xuser_10_reg             ;        
                `DESC_7_XUSER_11_REG_ADDR               : reg_data_out_3 <= desc_7_xuser_11_reg             ;        
                `DESC_7_XUSER_12_REG_ADDR               : reg_data_out_3 <= desc_7_xuser_12_reg             ;        
                `DESC_7_XUSER_13_REG_ADDR               : reg_data_out_3 <= desc_7_xuser_13_reg             ;        
                `DESC_7_XUSER_14_REG_ADDR               : reg_data_out_3 <= desc_7_xuser_14_reg             ;        
                `DESC_7_XUSER_15_REG_ADDR               : reg_data_out_3 <= desc_7_xuser_15_reg             ;        
                `DESC_7_WUSER_0_REG_ADDR                : reg_data_out_3 <= desc_7_wuser_0_reg              ;        
                `DESC_7_WUSER_1_REG_ADDR                : reg_data_out_3 <= desc_7_wuser_1_reg              ;        
                `DESC_7_WUSER_2_REG_ADDR                : reg_data_out_3 <= desc_7_wuser_2_reg              ;        
                `DESC_7_WUSER_3_REG_ADDR                : reg_data_out_3 <= desc_7_wuser_3_reg              ;        
                `DESC_7_WUSER_4_REG_ADDR                : reg_data_out_3 <= desc_7_wuser_4_reg              ;        
                `DESC_7_WUSER_5_REG_ADDR                : reg_data_out_3 <= desc_7_wuser_5_reg              ;        
                `DESC_7_WUSER_6_REG_ADDR                : reg_data_out_3 <= desc_7_wuser_6_reg              ;        
                `DESC_7_WUSER_7_REG_ADDR                : reg_data_out_3 <= desc_7_wuser_7_reg              ;        
                `DESC_7_WUSER_8_REG_ADDR                : reg_data_out_3 <= desc_7_wuser_8_reg              ;        
                `DESC_7_WUSER_9_REG_ADDR                : reg_data_out_3 <= desc_7_wuser_9_reg              ;        
                `DESC_7_WUSER_10_REG_ADDR               : reg_data_out_3 <= desc_7_wuser_10_reg             ;        
                `DESC_7_WUSER_11_REG_ADDR               : reg_data_out_3 <= desc_7_wuser_11_reg             ;        
                `DESC_7_WUSER_12_REG_ADDR               : reg_data_out_3 <= desc_7_wuser_12_reg             ;        
                `DESC_7_WUSER_13_REG_ADDR               : reg_data_out_3 <= desc_7_wuser_13_reg             ;        
                `DESC_7_WUSER_14_REG_ADDR               : reg_data_out_3 <= desc_7_wuser_14_reg             ;        
                `DESC_7_WUSER_15_REG_ADDR               : reg_data_out_3 <= desc_7_wuser_15_reg             ;        
                default                                  :reg_data_out_3 <= 32'b0      ;        
              endcase
              end
            else
              begin
                 reg_block_hit_3 <= 1'b0;
                 reg_data_out_3 <= reg_data_out_3;
              end
         end
    end


    always @( posedge axi_aclk )
    begin
       if (~axi_aresetn)
         begin
            reg_data_out_4 <= 32'b0;
            reg_block_hit_4 <= 1'b0;
         end
       else
         begin
            if (~|axi_araddr[BRIDGE_MSB:15] && axi_araddr[14] && (~|axi_araddr[13:11])) //access to reg block 4
              begin
                 reg_block_hit_4 <= 1'b1;                 

              case ({6'b001000,axi_araddr[10:0]})    
                `DESC_8_TXN_TYPE_REG_ADDR               : reg_data_out_4 <= desc_8_txn_type_reg             ;        
                `DESC_8_SIZE_REG_ADDR                   : reg_data_out_4 <= desc_8_size_reg                 ;        
                `DESC_8_DATA_OFFSET_REG_ADDR            : reg_data_out_4 <= desc_8_data_offset_reg          ;        
                `DESC_8_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_4 <= desc_8_data_host_addr_0_reg     ;        
                `DESC_8_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_4 <= desc_8_data_host_addr_1_reg     ;        
                `DESC_8_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_4 <= desc_8_data_host_addr_2_reg     ;        
                `DESC_8_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_4 <= desc_8_data_host_addr_3_reg     ;        
                `DESC_8_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_4 <= desc_8_wstrb_host_addr_0_reg    ;        
                `DESC_8_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_4 <= desc_8_wstrb_host_addr_1_reg    ;        
                `DESC_8_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_4 <= desc_8_wstrb_host_addr_2_reg    ;        
                `DESC_8_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_4 <= desc_8_wstrb_host_addr_3_reg    ;        
                `DESC_8_AXSIZE_REG_ADDR                 : reg_data_out_4 <= desc_8_axsize_reg               ;        
                `DESC_8_ATTR_REG_ADDR                   : reg_data_out_4 <= desc_8_attr_reg                 ;        
                `DESC_8_AXADDR_0_REG_ADDR               : reg_data_out_4 <= desc_8_axaddr_0_reg             ;        
                `DESC_8_AXADDR_1_REG_ADDR               : reg_data_out_4 <= desc_8_axaddr_1_reg             ;        
                `DESC_8_AXADDR_2_REG_ADDR               : reg_data_out_4 <= desc_8_axaddr_2_reg             ;        
                `DESC_8_AXADDR_3_REG_ADDR               : reg_data_out_4 <= desc_8_axaddr_3_reg             ;        
                `DESC_8_AXID_0_REG_ADDR                 : reg_data_out_4 <= desc_8_axid_0_reg               ;        
                `DESC_8_AXID_1_REG_ADDR                 : reg_data_out_4 <= desc_8_axid_1_reg               ;        
                `DESC_8_AXID_2_REG_ADDR                 : reg_data_out_4 <= desc_8_axid_2_reg               ;        
                `DESC_8_AXID_3_REG_ADDR                 : reg_data_out_4 <= desc_8_axid_3_reg               ;        
                `DESC_8_AXUSER_0_REG_ADDR               : reg_data_out_4 <= desc_8_axuser_0_reg             ;        
                `DESC_8_AXUSER_1_REG_ADDR               : reg_data_out_4 <= desc_8_axuser_1_reg             ;        
                `DESC_8_AXUSER_2_REG_ADDR               : reg_data_out_4 <= desc_8_axuser_2_reg             ;        
                `DESC_8_AXUSER_3_REG_ADDR               : reg_data_out_4 <= desc_8_axuser_3_reg             ;        
                `DESC_8_AXUSER_4_REG_ADDR               : reg_data_out_4 <= desc_8_axuser_4_reg             ;        
                `DESC_8_AXUSER_5_REG_ADDR               : reg_data_out_4 <= desc_8_axuser_5_reg             ;        
                `DESC_8_AXUSER_6_REG_ADDR               : reg_data_out_4 <= desc_8_axuser_6_reg             ;        
                `DESC_8_AXUSER_7_REG_ADDR               : reg_data_out_4 <= desc_8_axuser_7_reg             ;        
                `DESC_8_AXUSER_8_REG_ADDR               : reg_data_out_4 <= desc_8_axuser_8_reg             ;        
                `DESC_8_AXUSER_9_REG_ADDR               : reg_data_out_4 <= desc_8_axuser_9_reg             ;        
                `DESC_8_AXUSER_10_REG_ADDR              : reg_data_out_4 <= desc_8_axuser_10_reg            ;        
                `DESC_8_AXUSER_11_REG_ADDR              : reg_data_out_4 <= desc_8_axuser_11_reg            ;        
                `DESC_8_AXUSER_12_REG_ADDR              : reg_data_out_4 <= desc_8_axuser_12_reg            ;        
                `DESC_8_AXUSER_13_REG_ADDR              : reg_data_out_4 <= desc_8_axuser_13_reg            ;        
                `DESC_8_AXUSER_14_REG_ADDR              : reg_data_out_4 <= desc_8_axuser_14_reg            ;        
                `DESC_8_AXUSER_15_REG_ADDR              : reg_data_out_4 <= desc_8_axuser_15_reg            ;        
                `DESC_8_XUSER_0_REG_ADDR                : reg_data_out_4 <= desc_8_xuser_0_reg              ;        
                `DESC_8_XUSER_1_REG_ADDR                : reg_data_out_4 <= desc_8_xuser_1_reg              ;        
                `DESC_8_XUSER_2_REG_ADDR                : reg_data_out_4 <= desc_8_xuser_2_reg              ;        
                `DESC_8_XUSER_3_REG_ADDR                : reg_data_out_4 <= desc_8_xuser_3_reg              ;        
                `DESC_8_XUSER_4_REG_ADDR                : reg_data_out_4 <= desc_8_xuser_4_reg              ;        
                `DESC_8_XUSER_5_REG_ADDR                : reg_data_out_4 <= desc_8_xuser_5_reg              ;        
                `DESC_8_XUSER_6_REG_ADDR                : reg_data_out_4 <= desc_8_xuser_6_reg              ;        
                `DESC_8_XUSER_7_REG_ADDR                : reg_data_out_4 <= desc_8_xuser_7_reg              ;        
                `DESC_8_XUSER_8_REG_ADDR                : reg_data_out_4 <= desc_8_xuser_8_reg              ;        
                `DESC_8_XUSER_9_REG_ADDR                : reg_data_out_4 <= desc_8_xuser_9_reg              ;        
                `DESC_8_XUSER_10_REG_ADDR               : reg_data_out_4 <= desc_8_xuser_10_reg             ;        
                `DESC_8_XUSER_11_REG_ADDR               : reg_data_out_4 <= desc_8_xuser_11_reg             ;        
                `DESC_8_XUSER_12_REG_ADDR               : reg_data_out_4 <= desc_8_xuser_12_reg             ;        
                `DESC_8_XUSER_13_REG_ADDR               : reg_data_out_4 <= desc_8_xuser_13_reg             ;        
                `DESC_8_XUSER_14_REG_ADDR               : reg_data_out_4 <= desc_8_xuser_14_reg             ;        
                `DESC_8_XUSER_15_REG_ADDR               : reg_data_out_4 <= desc_8_xuser_15_reg             ;        
                `DESC_8_WUSER_0_REG_ADDR                : reg_data_out_4 <= desc_8_wuser_0_reg              ;        
                `DESC_8_WUSER_1_REG_ADDR                : reg_data_out_4 <= desc_8_wuser_1_reg              ;        
                `DESC_8_WUSER_2_REG_ADDR                : reg_data_out_4 <= desc_8_wuser_2_reg              ;        
                `DESC_8_WUSER_3_REG_ADDR                : reg_data_out_4 <= desc_8_wuser_3_reg              ;        
                `DESC_8_WUSER_4_REG_ADDR                : reg_data_out_4 <= desc_8_wuser_4_reg              ;        
                `DESC_8_WUSER_5_REG_ADDR                : reg_data_out_4 <= desc_8_wuser_5_reg              ;        
                `DESC_8_WUSER_6_REG_ADDR                : reg_data_out_4 <= desc_8_wuser_6_reg              ;        
                `DESC_8_WUSER_7_REG_ADDR                : reg_data_out_4 <= desc_8_wuser_7_reg              ;        
                `DESC_8_WUSER_8_REG_ADDR                : reg_data_out_4 <= desc_8_wuser_8_reg              ;        
                `DESC_8_WUSER_9_REG_ADDR                : reg_data_out_4 <= desc_8_wuser_9_reg              ;        
                `DESC_8_WUSER_10_REG_ADDR               : reg_data_out_4 <= desc_8_wuser_10_reg             ;        
                `DESC_8_WUSER_11_REG_ADDR               : reg_data_out_4 <= desc_8_wuser_11_reg             ;        
                `DESC_8_WUSER_12_REG_ADDR               : reg_data_out_4 <= desc_8_wuser_12_reg             ;        
                `DESC_8_WUSER_13_REG_ADDR               : reg_data_out_4 <= desc_8_wuser_13_reg             ;        
                `DESC_8_WUSER_14_REG_ADDR               : reg_data_out_4 <= desc_8_wuser_14_reg             ;        
                `DESC_8_WUSER_15_REG_ADDR               : reg_data_out_4 <= desc_8_wuser_15_reg             ;        
                `DESC_9_TXN_TYPE_REG_ADDR               : reg_data_out_4 <= desc_9_txn_type_reg             ;        
                `DESC_9_SIZE_REG_ADDR                   : reg_data_out_4 <= desc_9_size_reg                 ;        
                `DESC_9_DATA_OFFSET_REG_ADDR            : reg_data_out_4 <= desc_9_data_offset_reg          ;        
                `DESC_9_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_4 <= desc_9_data_host_addr_0_reg     ;        
                `DESC_9_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_4 <= desc_9_data_host_addr_1_reg     ;        
                `DESC_9_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_4 <= desc_9_data_host_addr_2_reg     ;        
                `DESC_9_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_4 <= desc_9_data_host_addr_3_reg     ;        
                `DESC_9_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_4 <= desc_9_wstrb_host_addr_0_reg    ;        
                `DESC_9_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_4 <= desc_9_wstrb_host_addr_1_reg    ;        
                `DESC_9_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_4 <= desc_9_wstrb_host_addr_2_reg    ;        
                `DESC_9_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_4 <= desc_9_wstrb_host_addr_3_reg    ;        
                `DESC_9_AXSIZE_REG_ADDR                 : reg_data_out_4 <= desc_9_axsize_reg               ;        
                `DESC_9_ATTR_REG_ADDR                   : reg_data_out_4 <= desc_9_attr_reg                 ;        
                `DESC_9_AXADDR_0_REG_ADDR               : reg_data_out_4 <= desc_9_axaddr_0_reg             ;        
                `DESC_9_AXADDR_1_REG_ADDR               : reg_data_out_4 <= desc_9_axaddr_1_reg             ;        
                `DESC_9_AXADDR_2_REG_ADDR               : reg_data_out_4 <= desc_9_axaddr_2_reg             ;        
                `DESC_9_AXADDR_3_REG_ADDR               : reg_data_out_4 <= desc_9_axaddr_3_reg             ;        
                `DESC_9_AXID_0_REG_ADDR                 : reg_data_out_4 <= desc_9_axid_0_reg               ;        
                `DESC_9_AXID_1_REG_ADDR                 : reg_data_out_4 <= desc_9_axid_1_reg               ;        
                `DESC_9_AXID_2_REG_ADDR                 : reg_data_out_4 <= desc_9_axid_2_reg               ;        
                `DESC_9_AXID_3_REG_ADDR                 : reg_data_out_4 <= desc_9_axid_3_reg               ;        
                `DESC_9_AXUSER_0_REG_ADDR               : reg_data_out_4 <= desc_9_axuser_0_reg             ;        
                `DESC_9_AXUSER_1_REG_ADDR               : reg_data_out_4 <= desc_9_axuser_1_reg             ;        
                `DESC_9_AXUSER_2_REG_ADDR               : reg_data_out_4 <= desc_9_axuser_2_reg             ;        
                `DESC_9_AXUSER_3_REG_ADDR               : reg_data_out_4 <= desc_9_axuser_3_reg             ;        
                `DESC_9_AXUSER_4_REG_ADDR               : reg_data_out_4 <= desc_9_axuser_4_reg             ;        
                `DESC_9_AXUSER_5_REG_ADDR               : reg_data_out_4 <= desc_9_axuser_5_reg             ;        
                `DESC_9_AXUSER_6_REG_ADDR               : reg_data_out_4 <= desc_9_axuser_6_reg             ;        
                `DESC_9_AXUSER_7_REG_ADDR               : reg_data_out_4 <= desc_9_axuser_7_reg             ;        
                `DESC_9_AXUSER_8_REG_ADDR               : reg_data_out_4 <= desc_9_axuser_8_reg             ;        
                `DESC_9_AXUSER_9_REG_ADDR               : reg_data_out_4 <= desc_9_axuser_9_reg             ;        
                `DESC_9_AXUSER_10_REG_ADDR              : reg_data_out_4 <= desc_9_axuser_10_reg            ;        
                `DESC_9_AXUSER_11_REG_ADDR              : reg_data_out_4 <= desc_9_axuser_11_reg            ;        
                `DESC_9_AXUSER_12_REG_ADDR              : reg_data_out_4 <= desc_9_axuser_12_reg            ;        
                `DESC_9_AXUSER_13_REG_ADDR              : reg_data_out_4 <= desc_9_axuser_13_reg            ;        
                `DESC_9_AXUSER_14_REG_ADDR              : reg_data_out_4 <= desc_9_axuser_14_reg            ;        
                `DESC_9_AXUSER_15_REG_ADDR              : reg_data_out_4 <= desc_9_axuser_15_reg            ;        
                `DESC_9_XUSER_0_REG_ADDR                : reg_data_out_4 <= desc_9_xuser_0_reg              ;        
                `DESC_9_XUSER_1_REG_ADDR                : reg_data_out_4 <= desc_9_xuser_1_reg              ;        
                `DESC_9_XUSER_2_REG_ADDR                : reg_data_out_4 <= desc_9_xuser_2_reg              ;        
                `DESC_9_XUSER_3_REG_ADDR                : reg_data_out_4 <= desc_9_xuser_3_reg              ;        
                `DESC_9_XUSER_4_REG_ADDR                : reg_data_out_4 <= desc_9_xuser_4_reg              ;        
                `DESC_9_XUSER_5_REG_ADDR                : reg_data_out_4 <= desc_9_xuser_5_reg              ;        
                `DESC_9_XUSER_6_REG_ADDR                : reg_data_out_4 <= desc_9_xuser_6_reg              ;        
                `DESC_9_XUSER_7_REG_ADDR                : reg_data_out_4 <= desc_9_xuser_7_reg              ;        
                `DESC_9_XUSER_8_REG_ADDR                : reg_data_out_4 <= desc_9_xuser_8_reg              ;        
                `DESC_9_XUSER_9_REG_ADDR                : reg_data_out_4 <= desc_9_xuser_9_reg              ;        
                `DESC_9_XUSER_10_REG_ADDR               : reg_data_out_4 <= desc_9_xuser_10_reg             ;        
                `DESC_9_XUSER_11_REG_ADDR               : reg_data_out_4 <= desc_9_xuser_11_reg             ;        
                `DESC_9_XUSER_12_REG_ADDR               : reg_data_out_4 <= desc_9_xuser_12_reg             ;        
                `DESC_9_XUSER_13_REG_ADDR               : reg_data_out_4 <= desc_9_xuser_13_reg             ;        
                `DESC_9_XUSER_14_REG_ADDR               : reg_data_out_4 <= desc_9_xuser_14_reg             ;        
                `DESC_9_XUSER_15_REG_ADDR               : reg_data_out_4 <= desc_9_xuser_15_reg             ;        
                `DESC_9_WUSER_0_REG_ADDR                : reg_data_out_4 <= desc_9_wuser_0_reg              ;        
                `DESC_9_WUSER_1_REG_ADDR                : reg_data_out_4 <= desc_9_wuser_1_reg              ;        
                `DESC_9_WUSER_2_REG_ADDR                : reg_data_out_4 <= desc_9_wuser_2_reg              ;        
                `DESC_9_WUSER_3_REG_ADDR                : reg_data_out_4 <= desc_9_wuser_3_reg              ;        
                `DESC_9_WUSER_4_REG_ADDR                : reg_data_out_4 <= desc_9_wuser_4_reg              ;        
                `DESC_9_WUSER_5_REG_ADDR                : reg_data_out_4 <= desc_9_wuser_5_reg              ;        
                `DESC_9_WUSER_6_REG_ADDR                : reg_data_out_4 <= desc_9_wuser_6_reg              ;        
                `DESC_9_WUSER_7_REG_ADDR                : reg_data_out_4 <= desc_9_wuser_7_reg              ;        
                `DESC_9_WUSER_8_REG_ADDR                : reg_data_out_4 <= desc_9_wuser_8_reg              ;        
                `DESC_9_WUSER_9_REG_ADDR                : reg_data_out_4 <= desc_9_wuser_9_reg              ;        
                `DESC_9_WUSER_10_REG_ADDR               : reg_data_out_4 <= desc_9_wuser_10_reg             ;        
                `DESC_9_WUSER_11_REG_ADDR               : reg_data_out_4 <= desc_9_wuser_11_reg             ;        
                `DESC_9_WUSER_12_REG_ADDR               : reg_data_out_4 <= desc_9_wuser_12_reg             ;        
                `DESC_9_WUSER_13_REG_ADDR               : reg_data_out_4 <= desc_9_wuser_13_reg             ;        
                `DESC_9_WUSER_14_REG_ADDR               : reg_data_out_4 <= desc_9_wuser_14_reg             ;        
                `DESC_9_WUSER_15_REG_ADDR               : reg_data_out_4 <= desc_9_wuser_15_reg             ;        
                `DESC_10_TXN_TYPE_REG_ADDR               : reg_data_out_4 <= desc_10_txn_type_reg           ;        
                `DESC_10_SIZE_REG_ADDR                   : reg_data_out_4 <= desc_10_size_reg               ;        
                `DESC_10_DATA_OFFSET_REG_ADDR            : reg_data_out_4 <= desc_10_data_offset_reg        ;        
                `DESC_10_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_4 <= desc_10_data_host_addr_0_reg   ;        
                `DESC_10_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_4 <= desc_10_data_host_addr_1_reg   ;        
                `DESC_10_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_4 <= desc_10_data_host_addr_2_reg   ;        
                `DESC_10_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_4 <= desc_10_data_host_addr_3_reg   ;        
                `DESC_10_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_4 <= desc_10_wstrb_host_addr_0_reg  ;        
                `DESC_10_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_4 <= desc_10_wstrb_host_addr_1_reg  ;        
                `DESC_10_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_4 <= desc_10_wstrb_host_addr_2_reg  ;        
                `DESC_10_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_4 <= desc_10_wstrb_host_addr_3_reg  ;        
                `DESC_10_AXSIZE_REG_ADDR                 : reg_data_out_4 <= desc_10_axsize_reg             ;        
                `DESC_10_ATTR_REG_ADDR                   : reg_data_out_4 <= desc_10_attr_reg               ;        
                `DESC_10_AXADDR_0_REG_ADDR               : reg_data_out_4 <= desc_10_axaddr_0_reg           ;        
                `DESC_10_AXADDR_1_REG_ADDR               : reg_data_out_4 <= desc_10_axaddr_1_reg           ;        
                `DESC_10_AXADDR_2_REG_ADDR               : reg_data_out_4 <= desc_10_axaddr_2_reg           ;        
                `DESC_10_AXADDR_3_REG_ADDR               : reg_data_out_4 <= desc_10_axaddr_3_reg           ;        
                `DESC_10_AXID_0_REG_ADDR                 : reg_data_out_4 <= desc_10_axid_0_reg             ;        
                `DESC_10_AXID_1_REG_ADDR                 : reg_data_out_4 <= desc_10_axid_1_reg             ;        
                `DESC_10_AXID_2_REG_ADDR                 : reg_data_out_4 <= desc_10_axid_2_reg             ;        
                `DESC_10_AXID_3_REG_ADDR                 : reg_data_out_4 <= desc_10_axid_3_reg             ;        
                `DESC_10_AXUSER_0_REG_ADDR               : reg_data_out_4 <= desc_10_axuser_0_reg           ;        
                `DESC_10_AXUSER_1_REG_ADDR               : reg_data_out_4 <= desc_10_axuser_1_reg           ;        
                `DESC_10_AXUSER_2_REG_ADDR               : reg_data_out_4 <= desc_10_axuser_2_reg           ;        
                `DESC_10_AXUSER_3_REG_ADDR               : reg_data_out_4 <= desc_10_axuser_3_reg           ;        
                `DESC_10_AXUSER_4_REG_ADDR               : reg_data_out_4 <= desc_10_axuser_4_reg           ;        
                `DESC_10_AXUSER_5_REG_ADDR               : reg_data_out_4 <= desc_10_axuser_5_reg           ;        
                `DESC_10_AXUSER_6_REG_ADDR               : reg_data_out_4 <= desc_10_axuser_6_reg           ;        
                `DESC_10_AXUSER_7_REG_ADDR               : reg_data_out_4 <= desc_10_axuser_7_reg           ;        
                `DESC_10_AXUSER_8_REG_ADDR               : reg_data_out_4 <= desc_10_axuser_8_reg           ;        
                `DESC_10_AXUSER_9_REG_ADDR               : reg_data_out_4 <= desc_10_axuser_9_reg           ;        
                `DESC_10_AXUSER_10_REG_ADDR              : reg_data_out_4 <= desc_10_axuser_10_reg          ;        
                `DESC_10_AXUSER_11_REG_ADDR              : reg_data_out_4 <= desc_10_axuser_11_reg          ;        
                `DESC_10_AXUSER_12_REG_ADDR              : reg_data_out_4 <= desc_10_axuser_12_reg          ;        
                `DESC_10_AXUSER_13_REG_ADDR              : reg_data_out_4 <= desc_10_axuser_13_reg          ;        
                `DESC_10_AXUSER_14_REG_ADDR              : reg_data_out_4 <= desc_10_axuser_14_reg          ;        
                `DESC_10_AXUSER_15_REG_ADDR              : reg_data_out_4 <= desc_10_axuser_15_reg          ;        
                `DESC_10_XUSER_0_REG_ADDR                : reg_data_out_4 <= desc_10_xuser_0_reg            ;        
                `DESC_10_XUSER_1_REG_ADDR                : reg_data_out_4 <= desc_10_xuser_1_reg            ;        
                `DESC_10_XUSER_2_REG_ADDR                : reg_data_out_4 <= desc_10_xuser_2_reg            ;        
                `DESC_10_XUSER_3_REG_ADDR                : reg_data_out_4 <= desc_10_xuser_3_reg            ;        
                `DESC_10_XUSER_4_REG_ADDR                : reg_data_out_4 <= desc_10_xuser_4_reg            ;        
                `DESC_10_XUSER_5_REG_ADDR                : reg_data_out_4 <= desc_10_xuser_5_reg            ;        
                `DESC_10_XUSER_6_REG_ADDR                : reg_data_out_4 <= desc_10_xuser_6_reg            ;        
                `DESC_10_XUSER_7_REG_ADDR                : reg_data_out_4 <= desc_10_xuser_7_reg            ;        
                `DESC_10_XUSER_8_REG_ADDR                : reg_data_out_4 <= desc_10_xuser_8_reg            ;        
                `DESC_10_XUSER_9_REG_ADDR                : reg_data_out_4 <= desc_10_xuser_9_reg            ;        
                `DESC_10_XUSER_10_REG_ADDR               : reg_data_out_4 <= desc_10_xuser_10_reg           ;        
                `DESC_10_XUSER_11_REG_ADDR               : reg_data_out_4 <= desc_10_xuser_11_reg           ;        
                `DESC_10_XUSER_12_REG_ADDR               : reg_data_out_4 <= desc_10_xuser_12_reg           ;        
                `DESC_10_XUSER_13_REG_ADDR               : reg_data_out_4 <= desc_10_xuser_13_reg           ;        
                `DESC_10_XUSER_14_REG_ADDR               : reg_data_out_4 <= desc_10_xuser_14_reg           ;        
                `DESC_10_XUSER_15_REG_ADDR               : reg_data_out_4 <= desc_10_xuser_15_reg           ;        
                `DESC_10_WUSER_0_REG_ADDR                : reg_data_out_4 <= desc_10_wuser_0_reg            ;        
                `DESC_10_WUSER_1_REG_ADDR                : reg_data_out_4 <= desc_10_wuser_1_reg            ;        
                `DESC_10_WUSER_2_REG_ADDR                : reg_data_out_4 <= desc_10_wuser_2_reg            ;        
                `DESC_10_WUSER_3_REG_ADDR                : reg_data_out_4 <= desc_10_wuser_3_reg            ;        
                `DESC_10_WUSER_4_REG_ADDR                : reg_data_out_4 <= desc_10_wuser_4_reg            ;        
                `DESC_10_WUSER_5_REG_ADDR                : reg_data_out_4 <= desc_10_wuser_5_reg            ;        
                `DESC_10_WUSER_6_REG_ADDR                : reg_data_out_4 <= desc_10_wuser_6_reg            ;        
                `DESC_10_WUSER_7_REG_ADDR                : reg_data_out_4 <= desc_10_wuser_7_reg            ;        
                `DESC_10_WUSER_8_REG_ADDR                : reg_data_out_4 <= desc_10_wuser_8_reg            ;        
                `DESC_10_WUSER_9_REG_ADDR                : reg_data_out_4 <= desc_10_wuser_9_reg            ;        
                `DESC_10_WUSER_10_REG_ADDR               : reg_data_out_4 <= desc_10_wuser_10_reg           ;        
                `DESC_10_WUSER_11_REG_ADDR               : reg_data_out_4 <= desc_10_wuser_11_reg           ;        
                `DESC_10_WUSER_12_REG_ADDR               : reg_data_out_4 <= desc_10_wuser_12_reg           ;        
                `DESC_10_WUSER_13_REG_ADDR               : reg_data_out_4 <= desc_10_wuser_13_reg           ;        
                `DESC_10_WUSER_14_REG_ADDR               : reg_data_out_4 <= desc_10_wuser_14_reg           ;        
                `DESC_10_WUSER_15_REG_ADDR               : reg_data_out_4 <= desc_10_wuser_15_reg           ;        
                `DESC_11_TXN_TYPE_REG_ADDR               : reg_data_out_4 <= desc_11_txn_type_reg           ;        
                `DESC_11_SIZE_REG_ADDR                   : reg_data_out_4 <= desc_11_size_reg               ;        
                `DESC_11_DATA_OFFSET_REG_ADDR            : reg_data_out_4 <= desc_11_data_offset_reg        ;        
                `DESC_11_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_4 <= desc_11_data_host_addr_0_reg   ;        
                `DESC_11_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_4 <= desc_11_data_host_addr_1_reg   ;        
                `DESC_11_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_4 <= desc_11_data_host_addr_2_reg   ;        
                `DESC_11_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_4 <= desc_11_data_host_addr_3_reg   ;        
                `DESC_11_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_4 <= desc_11_wstrb_host_addr_0_reg  ;        
                `DESC_11_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_4 <= desc_11_wstrb_host_addr_1_reg  ;        
                `DESC_11_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_4 <= desc_11_wstrb_host_addr_2_reg  ;        
                `DESC_11_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_4 <= desc_11_wstrb_host_addr_3_reg  ;        
                `DESC_11_AXSIZE_REG_ADDR                 : reg_data_out_4 <= desc_11_axsize_reg             ;        
                `DESC_11_ATTR_REG_ADDR                   : reg_data_out_4 <= desc_11_attr_reg               ;        
                `DESC_11_AXADDR_0_REG_ADDR               : reg_data_out_4 <= desc_11_axaddr_0_reg           ;        
                `DESC_11_AXADDR_1_REG_ADDR               : reg_data_out_4 <= desc_11_axaddr_1_reg           ;        
                `DESC_11_AXADDR_2_REG_ADDR               : reg_data_out_4 <= desc_11_axaddr_2_reg           ;        
                `DESC_11_AXADDR_3_REG_ADDR               : reg_data_out_4 <= desc_11_axaddr_3_reg           ;        
                `DESC_11_AXID_0_REG_ADDR                 : reg_data_out_4 <= desc_11_axid_0_reg             ;        
                `DESC_11_AXID_1_REG_ADDR                 : reg_data_out_4 <= desc_11_axid_1_reg             ;        
                `DESC_11_AXID_2_REG_ADDR                 : reg_data_out_4 <= desc_11_axid_2_reg             ;        
                `DESC_11_AXID_3_REG_ADDR                 : reg_data_out_4 <= desc_11_axid_3_reg             ;        
                `DESC_11_AXUSER_0_REG_ADDR               : reg_data_out_4 <= desc_11_axuser_0_reg           ;        
                `DESC_11_AXUSER_1_REG_ADDR               : reg_data_out_4 <= desc_11_axuser_1_reg           ;        
                `DESC_11_AXUSER_2_REG_ADDR               : reg_data_out_4 <= desc_11_axuser_2_reg           ;        
                `DESC_11_AXUSER_3_REG_ADDR               : reg_data_out_4 <= desc_11_axuser_3_reg           ;        
                `DESC_11_AXUSER_4_REG_ADDR               : reg_data_out_4 <= desc_11_axuser_4_reg           ;        
                `DESC_11_AXUSER_5_REG_ADDR               : reg_data_out_4 <= desc_11_axuser_5_reg           ;        
                `DESC_11_AXUSER_6_REG_ADDR               : reg_data_out_4 <= desc_11_axuser_6_reg           ;        
                `DESC_11_AXUSER_7_REG_ADDR               : reg_data_out_4 <= desc_11_axuser_7_reg           ;        
                `DESC_11_AXUSER_8_REG_ADDR               : reg_data_out_4 <= desc_11_axuser_8_reg           ;        
                `DESC_11_AXUSER_9_REG_ADDR               : reg_data_out_4 <= desc_11_axuser_9_reg           ;        
                `DESC_11_AXUSER_10_REG_ADDR              : reg_data_out_4 <= desc_11_axuser_10_reg          ;        
                `DESC_11_AXUSER_11_REG_ADDR              : reg_data_out_4 <= desc_11_axuser_11_reg          ;        
                `DESC_11_AXUSER_12_REG_ADDR              : reg_data_out_4 <= desc_11_axuser_12_reg          ;        
                `DESC_11_AXUSER_13_REG_ADDR              : reg_data_out_4 <= desc_11_axuser_13_reg          ;        
                `DESC_11_AXUSER_14_REG_ADDR              : reg_data_out_4 <= desc_11_axuser_14_reg          ;        
                `DESC_11_AXUSER_15_REG_ADDR              : reg_data_out_4 <= desc_11_axuser_15_reg          ;        
                `DESC_11_XUSER_0_REG_ADDR                : reg_data_out_4 <= desc_11_xuser_0_reg            ;        
                `DESC_11_XUSER_1_REG_ADDR                : reg_data_out_4 <= desc_11_xuser_1_reg            ;        
                `DESC_11_XUSER_2_REG_ADDR                : reg_data_out_4 <= desc_11_xuser_2_reg            ;        
                `DESC_11_XUSER_3_REG_ADDR                : reg_data_out_4 <= desc_11_xuser_3_reg            ;        
                `DESC_11_XUSER_4_REG_ADDR                : reg_data_out_4 <= desc_11_xuser_4_reg            ;        
                `DESC_11_XUSER_5_REG_ADDR                : reg_data_out_4 <= desc_11_xuser_5_reg            ;        
                `DESC_11_XUSER_6_REG_ADDR                : reg_data_out_4 <= desc_11_xuser_6_reg            ;        
                `DESC_11_XUSER_7_REG_ADDR                : reg_data_out_4 <= desc_11_xuser_7_reg            ;        
                `DESC_11_XUSER_8_REG_ADDR                : reg_data_out_4 <= desc_11_xuser_8_reg            ;        
                `DESC_11_XUSER_9_REG_ADDR                : reg_data_out_4 <= desc_11_xuser_9_reg            ;        
                `DESC_11_XUSER_10_REG_ADDR               : reg_data_out_4 <= desc_11_xuser_10_reg           ;        
                `DESC_11_XUSER_11_REG_ADDR               : reg_data_out_4 <= desc_11_xuser_11_reg           ;        
                `DESC_11_XUSER_12_REG_ADDR               : reg_data_out_4 <= desc_11_xuser_12_reg           ;        
                `DESC_11_XUSER_13_REG_ADDR               : reg_data_out_4 <= desc_11_xuser_13_reg           ;        
                `DESC_11_XUSER_14_REG_ADDR               : reg_data_out_4 <= desc_11_xuser_14_reg           ;        
                `DESC_11_XUSER_15_REG_ADDR               : reg_data_out_4 <= desc_11_xuser_15_reg           ;        
                `DESC_11_WUSER_0_REG_ADDR                : reg_data_out_4 <= desc_11_wuser_0_reg            ;        
                `DESC_11_WUSER_1_REG_ADDR                : reg_data_out_4 <= desc_11_wuser_1_reg            ;        
                `DESC_11_WUSER_2_REG_ADDR                : reg_data_out_4 <= desc_11_wuser_2_reg            ;        
                `DESC_11_WUSER_3_REG_ADDR                : reg_data_out_4 <= desc_11_wuser_3_reg            ;        
                `DESC_11_WUSER_4_REG_ADDR                : reg_data_out_4 <= desc_11_wuser_4_reg            ;        
                `DESC_11_WUSER_5_REG_ADDR                : reg_data_out_4 <= desc_11_wuser_5_reg            ;        
                `DESC_11_WUSER_6_REG_ADDR                : reg_data_out_4 <= desc_11_wuser_6_reg            ;        
                `DESC_11_WUSER_7_REG_ADDR                : reg_data_out_4 <= desc_11_wuser_7_reg            ;        
                `DESC_11_WUSER_8_REG_ADDR                : reg_data_out_4 <= desc_11_wuser_8_reg            ;        
                `DESC_11_WUSER_9_REG_ADDR                : reg_data_out_4 <= desc_11_wuser_9_reg            ;        
                `DESC_11_WUSER_10_REG_ADDR               : reg_data_out_4 <= desc_11_wuser_10_reg           ;        
                `DESC_11_WUSER_11_REG_ADDR               : reg_data_out_4 <= desc_11_wuser_11_reg           ;        
                `DESC_11_WUSER_12_REG_ADDR               : reg_data_out_4 <= desc_11_wuser_12_reg           ;        
                `DESC_11_WUSER_13_REG_ADDR               : reg_data_out_4 <= desc_11_wuser_13_reg           ;        
                `DESC_11_WUSER_14_REG_ADDR               : reg_data_out_4 <= desc_11_wuser_14_reg           ;        
                `DESC_11_WUSER_15_REG_ADDR               : reg_data_out_4 <= desc_11_wuser_15_reg           ;        

                default                                  :reg_data_out_4 <= 32'b0      ;        
              endcase
              end
            else
              begin
                 reg_block_hit_4 <= 1'b0;
                 reg_data_out_4 <= reg_data_out_4;
              end
         end
    end

    always @( posedge axi_aclk )
    begin
       if (~axi_aresetn)
         begin
            reg_data_out_5 <= 32'b0;
            reg_block_hit_5 <= 1'b0;
         end
       else
         begin
            if (~|axi_araddr[BRIDGE_MSB:15] && axi_araddr[14] && (~|axi_araddr[13:12]) && axi_araddr[11]) //access to reg block 5
              begin
                 reg_block_hit_5 <= 1'b1;                 

              case ({6'b001001,axi_araddr[10:0]})    
                `DESC_12_TXN_TYPE_REG_ADDR               : reg_data_out_5 <= desc_12_txn_type_reg           ;        
                `DESC_12_SIZE_REG_ADDR                   : reg_data_out_5 <= desc_12_size_reg               ;        
                `DESC_12_DATA_OFFSET_REG_ADDR            : reg_data_out_5 <= desc_12_data_offset_reg        ;        
                `DESC_12_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_5 <= desc_12_data_host_addr_0_reg   ;        
                `DESC_12_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_5 <= desc_12_data_host_addr_1_reg   ;        
                `DESC_12_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_5 <= desc_12_data_host_addr_2_reg   ;        
                `DESC_12_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_5 <= desc_12_data_host_addr_3_reg   ;        
                `DESC_12_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_5 <= desc_12_wstrb_host_addr_0_reg  ;        
                `DESC_12_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_5 <= desc_12_wstrb_host_addr_1_reg  ;        
                `DESC_12_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_5 <= desc_12_wstrb_host_addr_2_reg  ;        
                `DESC_12_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_5 <= desc_12_wstrb_host_addr_3_reg  ;        
                `DESC_12_AXSIZE_REG_ADDR                 : reg_data_out_5 <= desc_12_axsize_reg             ;        
                `DESC_12_ATTR_REG_ADDR                   : reg_data_out_5 <= desc_12_attr_reg               ;        
                `DESC_12_AXADDR_0_REG_ADDR               : reg_data_out_5 <= desc_12_axaddr_0_reg           ;        
                `DESC_12_AXADDR_1_REG_ADDR               : reg_data_out_5 <= desc_12_axaddr_1_reg           ;        
                `DESC_12_AXADDR_2_REG_ADDR               : reg_data_out_5 <= desc_12_axaddr_2_reg           ;        
                `DESC_12_AXADDR_3_REG_ADDR               : reg_data_out_5 <= desc_12_axaddr_3_reg           ;        
                `DESC_12_AXID_0_REG_ADDR                 : reg_data_out_5 <= desc_12_axid_0_reg             ;        
                `DESC_12_AXID_1_REG_ADDR                 : reg_data_out_5 <= desc_12_axid_1_reg             ;        
                `DESC_12_AXID_2_REG_ADDR                 : reg_data_out_5 <= desc_12_axid_2_reg             ;        
                `DESC_12_AXID_3_REG_ADDR                 : reg_data_out_5 <= desc_12_axid_3_reg             ;        
                `DESC_12_AXUSER_0_REG_ADDR               : reg_data_out_5 <= desc_12_axuser_0_reg           ;        
                `DESC_12_AXUSER_1_REG_ADDR               : reg_data_out_5 <= desc_12_axuser_1_reg           ;        
                `DESC_12_AXUSER_2_REG_ADDR               : reg_data_out_5 <= desc_12_axuser_2_reg           ;        
                `DESC_12_AXUSER_3_REG_ADDR               : reg_data_out_5 <= desc_12_axuser_3_reg           ;        
                `DESC_12_AXUSER_4_REG_ADDR               : reg_data_out_5 <= desc_12_axuser_4_reg           ;        
                `DESC_12_AXUSER_5_REG_ADDR               : reg_data_out_5 <= desc_12_axuser_5_reg           ;        
                `DESC_12_AXUSER_6_REG_ADDR               : reg_data_out_5 <= desc_12_axuser_6_reg           ;        
                `DESC_12_AXUSER_7_REG_ADDR               : reg_data_out_5 <= desc_12_axuser_7_reg           ;        
                `DESC_12_AXUSER_8_REG_ADDR               : reg_data_out_5 <= desc_12_axuser_8_reg           ;        
                `DESC_12_AXUSER_9_REG_ADDR               : reg_data_out_5 <= desc_12_axuser_9_reg           ;        
                `DESC_12_AXUSER_10_REG_ADDR              : reg_data_out_5 <= desc_12_axuser_10_reg          ;        
                `DESC_12_AXUSER_11_REG_ADDR              : reg_data_out_5 <= desc_12_axuser_11_reg          ;        
                `DESC_12_AXUSER_12_REG_ADDR              : reg_data_out_5 <= desc_12_axuser_12_reg          ;        
                `DESC_12_AXUSER_13_REG_ADDR              : reg_data_out_5 <= desc_12_axuser_13_reg          ;        
                `DESC_12_AXUSER_14_REG_ADDR              : reg_data_out_5 <= desc_12_axuser_14_reg          ;        
                `DESC_12_AXUSER_15_REG_ADDR              : reg_data_out_5 <= desc_12_axuser_15_reg          ;        
                `DESC_12_XUSER_0_REG_ADDR                : reg_data_out_5 <= desc_12_xuser_0_reg            ;        
                `DESC_12_XUSER_1_REG_ADDR                : reg_data_out_5 <= desc_12_xuser_1_reg            ;        
                `DESC_12_XUSER_2_REG_ADDR                : reg_data_out_5 <= desc_12_xuser_2_reg            ;        
                `DESC_12_XUSER_3_REG_ADDR                : reg_data_out_5 <= desc_12_xuser_3_reg            ;        
                `DESC_12_XUSER_4_REG_ADDR                : reg_data_out_5 <= desc_12_xuser_4_reg            ;        
                `DESC_12_XUSER_5_REG_ADDR                : reg_data_out_5 <= desc_12_xuser_5_reg            ;        
                `DESC_12_XUSER_6_REG_ADDR                : reg_data_out_5 <= desc_12_xuser_6_reg            ;        
                `DESC_12_XUSER_7_REG_ADDR                : reg_data_out_5 <= desc_12_xuser_7_reg            ;        
                `DESC_12_XUSER_8_REG_ADDR                : reg_data_out_5 <= desc_12_xuser_8_reg            ;        
                `DESC_12_XUSER_9_REG_ADDR                : reg_data_out_5 <= desc_12_xuser_9_reg            ;        
                `DESC_12_XUSER_10_REG_ADDR               : reg_data_out_5 <= desc_12_xuser_10_reg           ;        
                `DESC_12_XUSER_11_REG_ADDR               : reg_data_out_5 <= desc_12_xuser_11_reg           ;        
                `DESC_12_XUSER_12_REG_ADDR               : reg_data_out_5 <= desc_12_xuser_12_reg           ;        
                `DESC_12_XUSER_13_REG_ADDR               : reg_data_out_5 <= desc_12_xuser_13_reg           ;        
                `DESC_12_XUSER_14_REG_ADDR               : reg_data_out_5 <= desc_12_xuser_14_reg           ;        
                `DESC_12_XUSER_15_REG_ADDR               : reg_data_out_5 <= desc_12_xuser_15_reg           ;        
                `DESC_12_WUSER_0_REG_ADDR                : reg_data_out_5 <= desc_12_wuser_0_reg            ;        
                `DESC_12_WUSER_1_REG_ADDR                : reg_data_out_5 <= desc_12_wuser_1_reg            ;        
                `DESC_12_WUSER_2_REG_ADDR                : reg_data_out_5 <= desc_12_wuser_2_reg            ;        
                `DESC_12_WUSER_3_REG_ADDR                : reg_data_out_5 <= desc_12_wuser_3_reg            ;        
                `DESC_12_WUSER_4_REG_ADDR                : reg_data_out_5 <= desc_12_wuser_4_reg            ;        
                `DESC_12_WUSER_5_REG_ADDR                : reg_data_out_5 <= desc_12_wuser_5_reg            ;        
                `DESC_12_WUSER_6_REG_ADDR                : reg_data_out_5 <= desc_12_wuser_6_reg            ;        
                `DESC_12_WUSER_7_REG_ADDR                : reg_data_out_5 <= desc_12_wuser_7_reg            ;        
                `DESC_12_WUSER_8_REG_ADDR                : reg_data_out_5 <= desc_12_wuser_8_reg            ;        
                `DESC_12_WUSER_9_REG_ADDR                : reg_data_out_5 <= desc_12_wuser_9_reg            ;        
                `DESC_12_WUSER_10_REG_ADDR               : reg_data_out_5 <= desc_12_wuser_10_reg           ;        
                `DESC_12_WUSER_11_REG_ADDR               : reg_data_out_5 <= desc_12_wuser_11_reg           ;        
                `DESC_12_WUSER_12_REG_ADDR               : reg_data_out_5 <= desc_12_wuser_12_reg           ;        
                `DESC_12_WUSER_13_REG_ADDR               : reg_data_out_5 <= desc_12_wuser_13_reg           ;        
                `DESC_12_WUSER_14_REG_ADDR               : reg_data_out_5 <= desc_12_wuser_14_reg           ;        
                `DESC_12_WUSER_15_REG_ADDR               : reg_data_out_5 <= desc_12_wuser_15_reg           ;        
                `DESC_13_TXN_TYPE_REG_ADDR               : reg_data_out_5 <= desc_13_txn_type_reg           ;        
                `DESC_13_SIZE_REG_ADDR                   : reg_data_out_5 <= desc_13_size_reg               ;        
                `DESC_13_DATA_OFFSET_REG_ADDR            : reg_data_out_5 <= desc_13_data_offset_reg        ;        
                `DESC_13_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_5 <= desc_13_data_host_addr_0_reg   ;        
                `DESC_13_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_5 <= desc_13_data_host_addr_1_reg   ;        
                `DESC_13_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_5 <= desc_13_data_host_addr_2_reg   ;        
                `DESC_13_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_5 <= desc_13_data_host_addr_3_reg   ;        
                `DESC_13_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_5 <= desc_13_wstrb_host_addr_0_reg  ;        
                `DESC_13_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_5 <= desc_13_wstrb_host_addr_1_reg  ;        
                `DESC_13_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_5 <= desc_13_wstrb_host_addr_2_reg  ;        
                `DESC_13_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_5 <= desc_13_wstrb_host_addr_3_reg  ;        
                `DESC_13_AXSIZE_REG_ADDR                 : reg_data_out_5 <= desc_13_axsize_reg             ;        
                `DESC_13_ATTR_REG_ADDR                   : reg_data_out_5 <= desc_13_attr_reg               ;        
                `DESC_13_AXADDR_0_REG_ADDR               : reg_data_out_5 <= desc_13_axaddr_0_reg           ;        
                `DESC_13_AXADDR_1_REG_ADDR               : reg_data_out_5 <= desc_13_axaddr_1_reg           ;        
                `DESC_13_AXADDR_2_REG_ADDR               : reg_data_out_5 <= desc_13_axaddr_2_reg           ;        
                `DESC_13_AXADDR_3_REG_ADDR               : reg_data_out_5 <= desc_13_axaddr_3_reg           ;        
                `DESC_13_AXID_0_REG_ADDR                 : reg_data_out_5 <= desc_13_axid_0_reg             ;        
                `DESC_13_AXID_1_REG_ADDR                 : reg_data_out_5 <= desc_13_axid_1_reg             ;        
                `DESC_13_AXID_2_REG_ADDR                 : reg_data_out_5 <= desc_13_axid_2_reg             ;        
                `DESC_13_AXID_3_REG_ADDR                 : reg_data_out_5 <= desc_13_axid_3_reg             ;        
                `DESC_13_AXUSER_0_REG_ADDR               : reg_data_out_5 <= desc_13_axuser_0_reg           ;        
                `DESC_13_AXUSER_1_REG_ADDR               : reg_data_out_5 <= desc_13_axuser_1_reg           ;        
                `DESC_13_AXUSER_2_REG_ADDR               : reg_data_out_5 <= desc_13_axuser_2_reg           ;        
                `DESC_13_AXUSER_3_REG_ADDR               : reg_data_out_5 <= desc_13_axuser_3_reg           ;        
                `DESC_13_AXUSER_4_REG_ADDR               : reg_data_out_5 <= desc_13_axuser_4_reg           ;        
                `DESC_13_AXUSER_5_REG_ADDR               : reg_data_out_5 <= desc_13_axuser_5_reg           ;        
                `DESC_13_AXUSER_6_REG_ADDR               : reg_data_out_5 <= desc_13_axuser_6_reg           ;        
                `DESC_13_AXUSER_7_REG_ADDR               : reg_data_out_5 <= desc_13_axuser_7_reg           ;        
                `DESC_13_AXUSER_8_REG_ADDR               : reg_data_out_5 <= desc_13_axuser_8_reg           ;        
                `DESC_13_AXUSER_9_REG_ADDR               : reg_data_out_5 <= desc_13_axuser_9_reg           ;        
                `DESC_13_AXUSER_10_REG_ADDR              : reg_data_out_5 <= desc_13_axuser_10_reg          ;        
                `DESC_13_AXUSER_11_REG_ADDR              : reg_data_out_5 <= desc_13_axuser_11_reg          ;        
                `DESC_13_AXUSER_12_REG_ADDR              : reg_data_out_5 <= desc_13_axuser_12_reg          ;        
                `DESC_13_AXUSER_13_REG_ADDR              : reg_data_out_5 <= desc_13_axuser_13_reg          ;        
                `DESC_13_AXUSER_14_REG_ADDR              : reg_data_out_5 <= desc_13_axuser_14_reg          ;        
                `DESC_13_AXUSER_15_REG_ADDR              : reg_data_out_5 <= desc_13_axuser_15_reg          ;        
                `DESC_13_XUSER_0_REG_ADDR                : reg_data_out_5 <= desc_13_xuser_0_reg            ;        
                `DESC_13_XUSER_1_REG_ADDR                : reg_data_out_5 <= desc_13_xuser_1_reg            ;        
                `DESC_13_XUSER_2_REG_ADDR                : reg_data_out_5 <= desc_13_xuser_2_reg            ;        
                `DESC_13_XUSER_3_REG_ADDR                : reg_data_out_5 <= desc_13_xuser_3_reg            ;        
                `DESC_13_XUSER_4_REG_ADDR                : reg_data_out_5 <= desc_13_xuser_4_reg            ;        
                `DESC_13_XUSER_5_REG_ADDR                : reg_data_out_5 <= desc_13_xuser_5_reg            ;        
                `DESC_13_XUSER_6_REG_ADDR                : reg_data_out_5 <= desc_13_xuser_6_reg            ;        
                `DESC_13_XUSER_7_REG_ADDR                : reg_data_out_5 <= desc_13_xuser_7_reg            ;        
                `DESC_13_XUSER_8_REG_ADDR                : reg_data_out_5 <= desc_13_xuser_8_reg            ;        
                `DESC_13_XUSER_9_REG_ADDR                : reg_data_out_5 <= desc_13_xuser_9_reg            ;        
                `DESC_13_XUSER_10_REG_ADDR               : reg_data_out_5 <= desc_13_xuser_10_reg           ;        
                `DESC_13_XUSER_11_REG_ADDR               : reg_data_out_5 <= desc_13_xuser_11_reg           ;        
                `DESC_13_XUSER_12_REG_ADDR               : reg_data_out_5 <= desc_13_xuser_12_reg           ;        
                `DESC_13_XUSER_13_REG_ADDR               : reg_data_out_5 <= desc_13_xuser_13_reg           ;        
                `DESC_13_XUSER_14_REG_ADDR               : reg_data_out_5 <= desc_13_xuser_14_reg           ;        
                `DESC_13_XUSER_15_REG_ADDR               : reg_data_out_5 <= desc_13_xuser_15_reg           ;        
                `DESC_13_WUSER_0_REG_ADDR                : reg_data_out_5 <= desc_13_wuser_0_reg            ;        
                `DESC_13_WUSER_1_REG_ADDR                : reg_data_out_5 <= desc_13_wuser_1_reg            ;        
                `DESC_13_WUSER_2_REG_ADDR                : reg_data_out_5 <= desc_13_wuser_2_reg            ;        
                `DESC_13_WUSER_3_REG_ADDR                : reg_data_out_5 <= desc_13_wuser_3_reg            ;        
                `DESC_13_WUSER_4_REG_ADDR                : reg_data_out_5 <= desc_13_wuser_4_reg            ;        
                `DESC_13_WUSER_5_REG_ADDR                : reg_data_out_5 <= desc_13_wuser_5_reg            ;        
                `DESC_13_WUSER_6_REG_ADDR                : reg_data_out_5 <= desc_13_wuser_6_reg            ;        
                `DESC_13_WUSER_7_REG_ADDR                : reg_data_out_5 <= desc_13_wuser_7_reg            ;        
                `DESC_13_WUSER_8_REG_ADDR                : reg_data_out_5 <= desc_13_wuser_8_reg            ;        
                `DESC_13_WUSER_9_REG_ADDR                : reg_data_out_5 <= desc_13_wuser_9_reg            ;        
                `DESC_13_WUSER_10_REG_ADDR               : reg_data_out_5 <= desc_13_wuser_10_reg           ;        
                `DESC_13_WUSER_11_REG_ADDR               : reg_data_out_5 <= desc_13_wuser_11_reg           ;        
                `DESC_13_WUSER_12_REG_ADDR               : reg_data_out_5 <= desc_13_wuser_12_reg           ;        
                `DESC_13_WUSER_13_REG_ADDR               : reg_data_out_5 <= desc_13_wuser_13_reg           ;        
                `DESC_13_WUSER_14_REG_ADDR               : reg_data_out_5 <= desc_13_wuser_14_reg           ;        
                `DESC_13_WUSER_15_REG_ADDR               : reg_data_out_5 <= desc_13_wuser_15_reg           ;        
                `DESC_14_TXN_TYPE_REG_ADDR               : reg_data_out_5 <= desc_14_txn_type_reg           ;        
                `DESC_14_SIZE_REG_ADDR                   : reg_data_out_5 <= desc_14_size_reg               ;        
                `DESC_14_DATA_OFFSET_REG_ADDR            : reg_data_out_5 <= desc_14_data_offset_reg        ;        
                `DESC_14_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_5 <= desc_14_data_host_addr_0_reg   ;        
                `DESC_14_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_5 <= desc_14_data_host_addr_1_reg   ;        
                `DESC_14_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_5 <= desc_14_data_host_addr_2_reg   ;        
                `DESC_14_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_5 <= desc_14_data_host_addr_3_reg   ;        
                `DESC_14_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_5 <= desc_14_wstrb_host_addr_0_reg  ;        
                `DESC_14_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_5 <= desc_14_wstrb_host_addr_1_reg  ;        
                `DESC_14_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_5 <= desc_14_wstrb_host_addr_2_reg  ;        
                `DESC_14_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_5 <= desc_14_wstrb_host_addr_3_reg  ;        
                `DESC_14_AXSIZE_REG_ADDR                 : reg_data_out_5 <= desc_14_axsize_reg             ;        
                `DESC_14_ATTR_REG_ADDR                   : reg_data_out_5 <= desc_14_attr_reg               ;        
                `DESC_14_AXADDR_0_REG_ADDR               : reg_data_out_5 <= desc_14_axaddr_0_reg           ;        
                `DESC_14_AXADDR_1_REG_ADDR               : reg_data_out_5 <= desc_14_axaddr_1_reg           ;        
                `DESC_14_AXADDR_2_REG_ADDR               : reg_data_out_5 <= desc_14_axaddr_2_reg           ;        
                `DESC_14_AXADDR_3_REG_ADDR               : reg_data_out_5 <= desc_14_axaddr_3_reg           ;        
                `DESC_14_AXID_0_REG_ADDR                 : reg_data_out_5 <= desc_14_axid_0_reg             ;        
                `DESC_14_AXID_1_REG_ADDR                 : reg_data_out_5 <= desc_14_axid_1_reg             ;        
                `DESC_14_AXID_2_REG_ADDR                 : reg_data_out_5 <= desc_14_axid_2_reg             ;        
                `DESC_14_AXID_3_REG_ADDR                 : reg_data_out_5 <= desc_14_axid_3_reg             ;        
                `DESC_14_AXUSER_0_REG_ADDR               : reg_data_out_5 <= desc_14_axuser_0_reg           ;        
                `DESC_14_AXUSER_1_REG_ADDR               : reg_data_out_5 <= desc_14_axuser_1_reg           ;        
                `DESC_14_AXUSER_2_REG_ADDR               : reg_data_out_5 <= desc_14_axuser_2_reg           ;        
                `DESC_14_AXUSER_3_REG_ADDR               : reg_data_out_5 <= desc_14_axuser_3_reg           ;        
                `DESC_14_AXUSER_4_REG_ADDR               : reg_data_out_5 <= desc_14_axuser_4_reg           ;        
                `DESC_14_AXUSER_5_REG_ADDR               : reg_data_out_5 <= desc_14_axuser_5_reg           ;        
                `DESC_14_AXUSER_6_REG_ADDR               : reg_data_out_5 <= desc_14_axuser_6_reg           ;        
                `DESC_14_AXUSER_7_REG_ADDR               : reg_data_out_5 <= desc_14_axuser_7_reg           ;        
                `DESC_14_AXUSER_8_REG_ADDR               : reg_data_out_5 <= desc_14_axuser_8_reg           ;        
                `DESC_14_AXUSER_9_REG_ADDR               : reg_data_out_5 <= desc_14_axuser_9_reg           ;        
                `DESC_14_AXUSER_10_REG_ADDR              : reg_data_out_5 <= desc_14_axuser_10_reg          ;        
                `DESC_14_AXUSER_11_REG_ADDR              : reg_data_out_5 <= desc_14_axuser_11_reg          ;        
                `DESC_14_AXUSER_12_REG_ADDR              : reg_data_out_5 <= desc_14_axuser_12_reg          ;        
                `DESC_14_AXUSER_13_REG_ADDR              : reg_data_out_5 <= desc_14_axuser_13_reg          ;        
                `DESC_14_AXUSER_14_REG_ADDR              : reg_data_out_5 <= desc_14_axuser_14_reg          ;        
                `DESC_14_AXUSER_15_REG_ADDR              : reg_data_out_5 <= desc_14_axuser_15_reg          ;        
                `DESC_14_XUSER_0_REG_ADDR                : reg_data_out_5 <= desc_14_xuser_0_reg            ;        
                `DESC_14_XUSER_1_REG_ADDR                : reg_data_out_5 <= desc_14_xuser_1_reg            ;        
                `DESC_14_XUSER_2_REG_ADDR                : reg_data_out_5 <= desc_14_xuser_2_reg            ;        
                `DESC_14_XUSER_3_REG_ADDR                : reg_data_out_5 <= desc_14_xuser_3_reg            ;        
                `DESC_14_XUSER_4_REG_ADDR                : reg_data_out_5 <= desc_14_xuser_4_reg            ;        
                `DESC_14_XUSER_5_REG_ADDR                : reg_data_out_5 <= desc_14_xuser_5_reg            ;        
                `DESC_14_XUSER_6_REG_ADDR                : reg_data_out_5 <= desc_14_xuser_6_reg            ;        
                `DESC_14_XUSER_7_REG_ADDR                : reg_data_out_5 <= desc_14_xuser_7_reg            ;        
                `DESC_14_XUSER_8_REG_ADDR                : reg_data_out_5 <= desc_14_xuser_8_reg            ;        
                `DESC_14_XUSER_9_REG_ADDR                : reg_data_out_5 <= desc_14_xuser_9_reg            ;        
                `DESC_14_XUSER_10_REG_ADDR               : reg_data_out_5 <= desc_14_xuser_10_reg           ;        
                `DESC_14_XUSER_11_REG_ADDR               : reg_data_out_5 <= desc_14_xuser_11_reg           ;        
                `DESC_14_XUSER_12_REG_ADDR               : reg_data_out_5 <= desc_14_xuser_12_reg           ;        
                `DESC_14_XUSER_13_REG_ADDR               : reg_data_out_5 <= desc_14_xuser_13_reg           ;        
                `DESC_14_XUSER_14_REG_ADDR               : reg_data_out_5 <= desc_14_xuser_14_reg           ;        
                `DESC_14_XUSER_15_REG_ADDR               : reg_data_out_5 <= desc_14_xuser_15_reg           ;        
                `DESC_14_WUSER_0_REG_ADDR                : reg_data_out_5 <= desc_14_wuser_0_reg            ;        
                `DESC_14_WUSER_1_REG_ADDR                : reg_data_out_5 <= desc_14_wuser_1_reg            ;        
                `DESC_14_WUSER_2_REG_ADDR                : reg_data_out_5 <= desc_14_wuser_2_reg            ;        
                `DESC_14_WUSER_3_REG_ADDR                : reg_data_out_5 <= desc_14_wuser_3_reg            ;        
                `DESC_14_WUSER_4_REG_ADDR                : reg_data_out_5 <= desc_14_wuser_4_reg            ;        
                `DESC_14_WUSER_5_REG_ADDR                : reg_data_out_5 <= desc_14_wuser_5_reg            ;        
                `DESC_14_WUSER_6_REG_ADDR                : reg_data_out_5 <= desc_14_wuser_6_reg            ;        
                `DESC_14_WUSER_7_REG_ADDR                : reg_data_out_5 <= desc_14_wuser_7_reg            ;        
                `DESC_14_WUSER_8_REG_ADDR                : reg_data_out_5 <= desc_14_wuser_8_reg            ;        
                `DESC_14_WUSER_9_REG_ADDR                : reg_data_out_5 <= desc_14_wuser_9_reg            ;        
                `DESC_14_WUSER_10_REG_ADDR               : reg_data_out_5 <= desc_14_wuser_10_reg           ;        
                `DESC_14_WUSER_11_REG_ADDR               : reg_data_out_5 <= desc_14_wuser_11_reg           ;        
                `DESC_14_WUSER_12_REG_ADDR               : reg_data_out_5 <= desc_14_wuser_12_reg           ;        
                `DESC_14_WUSER_13_REG_ADDR               : reg_data_out_5 <= desc_14_wuser_13_reg           ;        
                `DESC_14_WUSER_14_REG_ADDR               : reg_data_out_5 <= desc_14_wuser_14_reg           ;        
                `DESC_14_WUSER_15_REG_ADDR               : reg_data_out_5 <= desc_14_wuser_15_reg           ;        
                `DESC_15_TXN_TYPE_REG_ADDR               : reg_data_out_5 <= desc_15_txn_type_reg           ;        
                `DESC_15_SIZE_REG_ADDR                   : reg_data_out_5 <= desc_15_size_reg               ;        
                `DESC_15_DATA_OFFSET_REG_ADDR            : reg_data_out_5 <= desc_15_data_offset_reg        ;        
                `DESC_15_DATA_HOST_ADDR_0_REG_ADDR       : reg_data_out_5 <= desc_15_data_host_addr_0_reg   ;        
                `DESC_15_DATA_HOST_ADDR_1_REG_ADDR       : reg_data_out_5 <= desc_15_data_host_addr_1_reg   ;        
                `DESC_15_DATA_HOST_ADDR_2_REG_ADDR       : reg_data_out_5 <= desc_15_data_host_addr_2_reg   ;        
                `DESC_15_DATA_HOST_ADDR_3_REG_ADDR       : reg_data_out_5 <= desc_15_data_host_addr_3_reg   ;        
                `DESC_15_WSTRB_HOST_ADDR_0_REG_ADDR      : reg_data_out_5 <= desc_15_wstrb_host_addr_0_reg  ;        
                `DESC_15_WSTRB_HOST_ADDR_1_REG_ADDR      : reg_data_out_5 <= desc_15_wstrb_host_addr_1_reg  ;        
                `DESC_15_WSTRB_HOST_ADDR_2_REG_ADDR      : reg_data_out_5 <= desc_15_wstrb_host_addr_2_reg  ;        
                `DESC_15_WSTRB_HOST_ADDR_3_REG_ADDR      : reg_data_out_5 <= desc_15_wstrb_host_addr_3_reg  ;        
                `DESC_15_AXSIZE_REG_ADDR                 : reg_data_out_5 <= desc_15_axsize_reg             ;        
                `DESC_15_ATTR_REG_ADDR                   : reg_data_out_5 <= desc_15_attr_reg               ;        
                `DESC_15_AXADDR_0_REG_ADDR               : reg_data_out_5 <= desc_15_axaddr_0_reg           ;        
                `DESC_15_AXADDR_1_REG_ADDR               : reg_data_out_5 <= desc_15_axaddr_1_reg           ;        
                `DESC_15_AXADDR_2_REG_ADDR               : reg_data_out_5 <= desc_15_axaddr_2_reg           ;        
                `DESC_15_AXADDR_3_REG_ADDR               : reg_data_out_5 <= desc_15_axaddr_3_reg           ;        
                `DESC_15_AXID_0_REG_ADDR                 : reg_data_out_5 <= desc_15_axid_0_reg             ;        
                `DESC_15_AXID_1_REG_ADDR                 : reg_data_out_5 <= desc_15_axid_1_reg             ;        
                `DESC_15_AXID_2_REG_ADDR                 : reg_data_out_5 <= desc_15_axid_2_reg             ;        
                `DESC_15_AXID_3_REG_ADDR                 : reg_data_out_5 <= desc_15_axid_3_reg             ;        
                `DESC_15_AXUSER_0_REG_ADDR               : reg_data_out_5 <= desc_15_axuser_0_reg           ;        
                `DESC_15_AXUSER_1_REG_ADDR               : reg_data_out_5 <= desc_15_axuser_1_reg           ;        
                `DESC_15_AXUSER_2_REG_ADDR               : reg_data_out_5 <= desc_15_axuser_2_reg           ;        
                `DESC_15_AXUSER_3_REG_ADDR               : reg_data_out_5 <= desc_15_axuser_3_reg           ;        
                `DESC_15_AXUSER_4_REG_ADDR               : reg_data_out_5 <= desc_15_axuser_4_reg           ;        
                `DESC_15_AXUSER_5_REG_ADDR               : reg_data_out_5 <= desc_15_axuser_5_reg           ;        
                `DESC_15_AXUSER_6_REG_ADDR               : reg_data_out_5 <= desc_15_axuser_6_reg           ;        
                `DESC_15_AXUSER_7_REG_ADDR               : reg_data_out_5 <= desc_15_axuser_7_reg           ;        
                `DESC_15_AXUSER_8_REG_ADDR               : reg_data_out_5 <= desc_15_axuser_8_reg           ;        
                `DESC_15_AXUSER_9_REG_ADDR               : reg_data_out_5 <= desc_15_axuser_9_reg           ;        
                `DESC_15_AXUSER_10_REG_ADDR              : reg_data_out_5 <= desc_15_axuser_10_reg          ;        
                `DESC_15_AXUSER_11_REG_ADDR              : reg_data_out_5 <= desc_15_axuser_11_reg          ;        
                `DESC_15_AXUSER_12_REG_ADDR              : reg_data_out_5 <= desc_15_axuser_12_reg          ;        
                `DESC_15_AXUSER_13_REG_ADDR              : reg_data_out_5 <= desc_15_axuser_13_reg          ;        
                `DESC_15_AXUSER_14_REG_ADDR              : reg_data_out_5 <= desc_15_axuser_14_reg          ;        
                `DESC_15_AXUSER_15_REG_ADDR              : reg_data_out_5 <= desc_15_axuser_15_reg          ;        
                `DESC_15_XUSER_0_REG_ADDR                : reg_data_out_5 <= desc_15_xuser_0_reg            ;        
                `DESC_15_XUSER_1_REG_ADDR                : reg_data_out_5 <= desc_15_xuser_1_reg            ;        
                `DESC_15_XUSER_2_REG_ADDR                : reg_data_out_5 <= desc_15_xuser_2_reg            ;        
                `DESC_15_XUSER_3_REG_ADDR                : reg_data_out_5 <= desc_15_xuser_3_reg            ;        
                `DESC_15_XUSER_4_REG_ADDR                : reg_data_out_5 <= desc_15_xuser_4_reg            ;        
                `DESC_15_XUSER_5_REG_ADDR                : reg_data_out_5 <= desc_15_xuser_5_reg            ;        
                `DESC_15_XUSER_6_REG_ADDR                : reg_data_out_5 <= desc_15_xuser_6_reg            ;        
                `DESC_15_XUSER_7_REG_ADDR                : reg_data_out_5 <= desc_15_xuser_7_reg            ;        
                `DESC_15_XUSER_8_REG_ADDR                : reg_data_out_5 <= desc_15_xuser_8_reg            ;        
                `DESC_15_XUSER_9_REG_ADDR                : reg_data_out_5 <= desc_15_xuser_9_reg            ;        
                `DESC_15_XUSER_10_REG_ADDR               : reg_data_out_5 <= desc_15_xuser_10_reg           ;        
                `DESC_15_XUSER_11_REG_ADDR               : reg_data_out_5 <= desc_15_xuser_11_reg           ;        
                `DESC_15_XUSER_12_REG_ADDR               : reg_data_out_5 <= desc_15_xuser_12_reg           ;        
                `DESC_15_XUSER_13_REG_ADDR               : reg_data_out_5 <= desc_15_xuser_13_reg           ;        
                `DESC_15_XUSER_14_REG_ADDR               : reg_data_out_5 <= desc_15_xuser_14_reg           ;        
                `DESC_15_XUSER_15_REG_ADDR               : reg_data_out_5 <= desc_15_xuser_15_reg           ;        
                `DESC_15_WUSER_0_REG_ADDR                : reg_data_out_5 <= desc_15_wuser_0_reg            ;        
                `DESC_15_WUSER_1_REG_ADDR                : reg_data_out_5 <= desc_15_wuser_1_reg            ;        
                `DESC_15_WUSER_2_REG_ADDR                : reg_data_out_5 <= desc_15_wuser_2_reg            ;        
                `DESC_15_WUSER_3_REG_ADDR                : reg_data_out_5 <= desc_15_wuser_3_reg            ;        
                `DESC_15_WUSER_4_REG_ADDR                : reg_data_out_5 <= desc_15_wuser_4_reg            ;        
                `DESC_15_WUSER_5_REG_ADDR                : reg_data_out_5 <= desc_15_wuser_5_reg            ;        
                `DESC_15_WUSER_6_REG_ADDR                : reg_data_out_5 <= desc_15_wuser_6_reg            ;        
                `DESC_15_WUSER_7_REG_ADDR                : reg_data_out_5 <= desc_15_wuser_7_reg            ;        
                `DESC_15_WUSER_8_REG_ADDR                : reg_data_out_5 <= desc_15_wuser_8_reg            ;        
                `DESC_15_WUSER_9_REG_ADDR                : reg_data_out_5 <= desc_15_wuser_9_reg            ;        
                `DESC_15_WUSER_10_REG_ADDR               : reg_data_out_5 <= desc_15_wuser_10_reg           ;        
                `DESC_15_WUSER_11_REG_ADDR               : reg_data_out_5 <= desc_15_wuser_11_reg           ;        
                `DESC_15_WUSER_12_REG_ADDR               : reg_data_out_5 <= desc_15_wuser_12_reg           ;        
                `DESC_15_WUSER_13_REG_ADDR               : reg_data_out_5 <= desc_15_wuser_13_reg           ;        
                `DESC_15_WUSER_14_REG_ADDR               : reg_data_out_5 <= desc_15_wuser_14_reg           ;        
                `DESC_15_WUSER_15_REG_ADDR               : reg_data_out_5 <= desc_15_wuser_15_reg           ;    

                default                                  :reg_data_out_5 <= 32'b0      ;        
              endcase
              end
            else
              begin
                 reg_block_hit_5 <= 1'b0;
                 reg_data_out_5 <= reg_data_out_5;
              end
         end
    end
   

        always @(*)
        begin
              // Address decoding for reading registers
              case ({reg_block_hit_5,reg_block_hit_4,reg_block_hit_3,reg_block_hit_2,reg_block_hit_1})
                5'b00001: reg_data_out <= reg_data_out_1;  
                5'b00010: reg_data_out <= reg_data_out_2;
                5'b00100: reg_data_out <= reg_data_out_3;
                5'b01000: reg_data_out <= reg_data_out_4;
                5'b10000: reg_data_out <= reg_data_out_5;  
                default : reg_data_out <= 32'b0;
              endcase 
        end // always @ (*)

   reg [S_AXI_DATA_WIDTH-1:0]             reg_data_out_pipeline; 

  always @( posedge axi_aclk )
    begin
       if (~axi_aresetn)
         reg_data_out_pipeline <= 32'b0;
       else
         reg_data_out_pipeline <= reg_data_out;
    end


   // Updating Mecahnism of RO registers
   

always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          c2h_intr_status_0_reg[i] <= 1'b0;
        else begin
           if (ih2rb_c2h_intr_status_0_reg_we[i])
             c2h_intr_status_0_reg[i] <= ih2rb_c2h_intr_status_0_reg[i];
           else
             c2h_intr_status_0_reg[i] <= c2h_intr_status_0_reg[i];
        end
     end
  end // always @ (posedge axi_aclk)


always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          c2h_intr_status_1_reg[i] <= 1'b0;
        else begin
           if (ih2rb_c2h_intr_status_1_reg_we[i])
             c2h_intr_status_1_reg[i] <= ih2rb_c2h_intr_status_1_reg[i];
           else
             c2h_intr_status_1_reg[i] <= c2h_intr_status_1_reg[i];
        end
     end
  end // always @ (posedge axi_aclk)




always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          intr_c2h_toggle_status_0_reg[i] <= 1'b0;
        else begin
           if (ih2rb_intr_c2h_toggle_status_0_reg_we[i])
             intr_c2h_toggle_status_0_reg[i] <= ih2rb_intr_c2h_toggle_status_0_reg[i];
           else
             intr_c2h_toggle_status_0_reg[i] <= intr_c2h_toggle_status_0_reg[i];
        end
     end
  end // always @ (posedge axi_aclk)


always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          intr_c2h_toggle_status_1_reg[i] <= 1'b0;
        else begin
           if (ih2rb_intr_c2h_toggle_status_1_reg_we[i])
             intr_c2h_toggle_status_1_reg[i] <= ih2rb_intr_c2h_toggle_status_1_reg[i];
           else
             intr_c2h_toggle_status_1_reg[i] <= intr_c2h_toggle_status_1_reg[i];
        end
     end
  end // always @ (posedge axi_aclk)
   



// GPIO Registers 0-7 In   
always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          c2h_gpio_0_reg[i] <= 1'b0;
        else begin
           if (ih2rb_c2h_gpio_0_reg_we[i])
             c2h_gpio_0_reg[i] <= ih2rb_c2h_gpio_0_reg[i];
           else
             c2h_gpio_0_reg[i] <= c2h_gpio_0_reg[i];
        end
     end // for (i=0; i<32; i=i+1)
  end // always @ (posedge axi_aclk)
   

always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          c2h_gpio_1_reg[i] <= 1'b0;
        else begin
           if (ih2rb_c2h_gpio_1_reg_we[i])
             c2h_gpio_1_reg[i] <= ih2rb_c2h_gpio_1_reg[i];
           else
             c2h_gpio_1_reg[i] <= c2h_gpio_1_reg[i];
        end
     end // for (i=0; i<32; i=i+1)
  end // always @ (posedge axi_aclk)



   always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          c2h_gpio_2_reg[i] <= 1'b0;
        else begin
           if (ih2rb_c2h_gpio_2_reg_we[i])
             c2h_gpio_2_reg[i] <= ih2rb_c2h_gpio_2_reg[i];
           else
             c2h_gpio_2_reg[i] <= c2h_gpio_2_reg[i];
        end
     end // for (i=0; i<32; i=i+1)
  end // always @ (posedge axi_aclk)


always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          c2h_gpio_3_reg[i] <= 1'b0;
        else begin
           if (ih2rb_c2h_gpio_3_reg_we[i])
             c2h_gpio_3_reg[i] <= ih2rb_c2h_gpio_3_reg[i];
           else
             c2h_gpio_3_reg[i] <= c2h_gpio_3_reg[i];
        end
     end // for (i=0; i<32; i=i+1)
  end // always @ (posedge axi_aclk)


always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          c2h_gpio_4_reg[i] <= 1'b0;
        else begin
           if (ih2rb_c2h_gpio_4_reg_we[i])
             c2h_gpio_4_reg[i] <= ih2rb_c2h_gpio_4_reg[i];
           else
             c2h_gpio_4_reg[i] <= c2h_gpio_4_reg[i];
        end
     end // for (i=0; i<32; i=i+1)
  end // always @ (posedge axi_aclk)


always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          c2h_gpio_5_reg[i] <= 1'b0;
        else begin
           if (ih2rb_c2h_gpio_5_reg_we[i])
             c2h_gpio_5_reg[i] <= ih2rb_c2h_gpio_5_reg[i];
           else
             c2h_gpio_5_reg[i] <= c2h_gpio_5_reg[i];
        end
     end // for (i=0; i<32; i=i+1)
  end // always @ (posedge axi_aclk)


always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          c2h_gpio_6_reg[i] <= 1'b0;
        else begin
           if (ih2rb_c2h_gpio_6_reg_we[i])
             c2h_gpio_6_reg[i] <= ih2rb_c2h_gpio_6_reg[i];
           else
             c2h_gpio_6_reg[i] <= c2h_gpio_6_reg[i];
        end
     end // for (i=0; i<32; i=i+1)
  end // always @ (posedge axi_aclk)


always @(posedge axi_aclk)
  begin
     for (i=0; i<32; i=i+1)begin
        if (~rst_n)
          c2h_gpio_7_reg[i] <= 1'b0;
        else begin
           if (ih2rb_c2h_gpio_7_reg_we[i])
             c2h_gpio_7_reg[i] <= ih2rb_c2h_gpio_7_reg[i];
           else
             c2h_gpio_7_reg[i] <= c2h_gpio_7_reg[i];
        end
     end // for (i=0; i<32; i=i+1)
  end // always @ (posedge axi_aclk)
   

//GPIO From 8-15 are not implemented

   always @(posedge axi_aclk)
     begin
	c2h_gpio_8_reg <= 0;    
     end
   
   always @(posedge axi_aclk)
     begin
	c2h_gpio_9_reg <= 0;    
     end
   
   always @(posedge axi_aclk)
     begin
	c2h_gpio_10_reg <= 0;    
     end
   
   always @(posedge axi_aclk)
     begin
	c2h_gpio_11_reg <= 0;    
     end
   
   always @(posedge axi_aclk)
     begin
	c2h_gpio_12_reg <= 0;    
     end
   
   always @(posedge axi_aclk)
     begin
	c2h_gpio_13_reg <= 0;    
     end
   
   always @(posedge axi_aclk)
     begin
	c2h_gpio_14_reg <= 0;    
     end
   
   always @(posedge axi_aclk)
     begin
	c2h_gpio_15_reg <= 0;    
     end



   always @( posedge axi_aclk ) begin
      bridge_identification_reg <= BRIDGE_IDENTIFICATION_ID;
   end


   
//LAST_BRIDGE_REG
   always @( posedge axi_aclk ) begin
      bridge_position_reg <= {30'h0, PCIE_LAST_BRIDGE_DECODE, LAST_BRIDGE_DECODE };      
   end


//VERSION_REG
   always @( posedge axi_aclk ) begin
      version_reg <= VERSION;
   end
          
//BRIDGE_TYPE_REG
   always @( posedge axi_aclk ) begin
      bridge_type_reg <= BRIDGE_TYPE;
   end
   
//AXI_BRIDGE_CONFIG_REG
   always @( posedge axi_aclk ) begin
      axi_bridge_config_reg <= AXI_BRIDGE_CONFIG_REG;
   end

//BRIDGE_RD_USER_CONFIG_REG
   always @( posedge axi_aclk ) begin
      bridge_rd_user_config_reg <= BRIDGE_RD_USER_CONFIG_REG;
   end
   
//BRIDGE_WR_USER_CONFIG_REG
   always @( posedge axi_aclk ) begin
      bridge_wr_user_config_reg <= BRIDGE_WR_USER_CONFIG_REG;
   end
   
//AXI_MAX_DESC_REG
  always @( posedge axi_aclk ) begin
     axi_max_desc_reg <= MAX_DESC_DECODE;
  end

// All W1C registers will be cleared by the Reg Block.
// Effect of All clear registers and Ownership flip register on status* and ownership register will be implemented in C block.
// This is done so that UC block need to make multiple/local copies of these regs for its internal operations.     

//OWNERSHIP_REG    

// Logic to clear OWNERSHIP FLIP bit
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
             ownership_flip_clear[i] <= 1'b0;
           else
             if (~ownership_flip_clear[i])begin
               if (ownership_flip_reg[i])
                 ownership_flip_clear[i] <= 1'b1;
               else
                 ownership_flip_clear[i] <= 1'b0;
             end
             else begin
               if (~reg_wr_en)
                 ownership_flip_clear[i] <= 1'b0;
               else
                 ownership_flip_clear[i] <= ownership_flip_clear[i];
             end // else: !if(~ownership_flip_clear[i])
        end // for (i = 0; i < 32 ; i = i + 1)
     end // always @ ( posedge axi_aclk )
   
   
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
             ownership_reg[i] <= 1'b0;
           else
             ownership_reg[i] <= uc2rb_ownership_reg[i];
        end
     end



      

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           intr_txn_avail_status_reg[i] <= 1'b0;
           else 
             intr_txn_avail_status_reg[i] <= uc2rb_intr_txn_avail_status_reg[i];
        end
     end
   

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           intr_txn_avail_clear_reg_clear[i] <= 1'b0;
           else 
             if (~intr_txn_avail_clear_reg_clear[i])begin
               if (intr_txn_avail_clear_reg[i])
                 intr_txn_avail_clear_reg_clear[i] <= 1'b1;
               else
                 intr_txn_avail_clear_reg_clear[i] <= 1'b0;
             end
             else begin
                if (~reg_wr_en)
                  intr_txn_avail_clear_reg_clear[i] <= 1'b0;
                else
                  intr_txn_avail_clear_reg_clear[i] <= intr_txn_avail_clear_reg_clear[i] ;
             end 
        end
     end

      

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           intr_comp_status_reg[i] <= 1'b0;
           else 
             intr_comp_status_reg[i] <= uc2rb_intr_comp_status_reg[i];
        end
     end
   

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           intr_comp_clear_reg_clear[i] <= 1'b0;
           else 
             if (~intr_comp_clear_reg_clear[i])begin
               if (intr_comp_clear_reg[i])
                 intr_comp_clear_reg_clear[i] <= 1'b1;
               else
                 intr_comp_clear_reg_clear[i] <= 1'b0;
             end
             else begin
                if (~reg_wr_en)
                  intr_comp_clear_reg_clear[i] <= 1'b0;
                else
                  intr_comp_clear_reg_clear[i] <= intr_comp_clear_reg_clear[i] ;
             end 
        end
     end


   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           resp_order_reg_clear[i] <= 1'b0;
           else 
             if (~resp_order_reg_clear[i])begin
               if (resp_order_reg[i])
                 resp_order_reg_clear[i] <= 1'b1;
               else
                 resp_order_reg_clear[i] <= 1'b0;
             end
             else begin
                if (~reg_wr_en)
                  resp_order_reg_clear[i] <= 1'b0;
                else
                  resp_order_reg_clear[i] <= resp_order_reg_clear[i] ;
             end 
        end
     end


      
 
   always @( posedge axi_aclk )
     begin
        if (~rst_n)
          intr_error_status_reg[0] <= 1'b0;
        else begin
          if (uc2rb_intr_error_status_reg_we[0])
            intr_error_status_reg[0] <= uc2rb_intr_error_status_reg[0];
          else
            intr_error_status_reg[0] <= intr_error_status_reg[0];
        end
     end // always @ ( posedge axi_aclk )
   
   always @( posedge axi_aclk )
     begin
        if (~rst_n)
          intr_error_status_reg[1] <= 1'b0;
        else begin
          if (hm2rb_intr_error_status_reg_we[1])
            intr_error_status_reg[1] <= hm2rb_intr_error_status_reg[0];
          else
            intr_error_status_reg[1] <= intr_error_status_reg[1];
        end
     end // always @ ( posedge axi_aclk )
   
  

   // Tying of unused bits to 0

   always @(posedge axi_aclk)
     begin
        intr_error_status_reg[31:2] <= 30'h0;
     end
 


   always @( posedge axi_aclk )
     begin
        if (~rst_n)
          intr_error_clear_reg_clear[0] <= 1'b0;
        else begin 
          if (~intr_error_clear_reg_clear[0])begin
             if (intr_error_status_reg[0] && intr_error_clear_reg[0]) 
               intr_error_clear_reg_clear[0] <= 1'b1;
             else
               intr_error_clear_reg_clear[0] <= 1'b0;
          end
          else begin
             if (~reg_wr_en)
               intr_error_clear_reg_clear[0] <= 1'b0;
             else
               intr_error_clear_reg_clear[0] <= intr_error_clear_reg_clear[0];
          end // else: !if(~intr_error_clear_reg_clear[0])
        end // else: !if(~rst_n)
     end // always @ ( posedge axi_aclk )
   
   always @( posedge axi_aclk )
     begin
        if (~rst_n)
          intr_error_clear_reg_clear[1] <= 1'b0;
        else begin 
          if (~intr_error_clear_reg_clear[1])begin
             if (intr_error_status_reg[1] && intr_error_clear_reg[1]) 
               intr_error_clear_reg_clear[1] <= 1'b1;
             else
               intr_error_clear_reg_clear[1] <= 1'b0;
          end
          else begin
             if (~reg_wr_en)
               intr_error_clear_reg_clear[1] <= 1'b0;
             else
               intr_error_clear_reg_clear[1] <= intr_error_clear_reg_clear[1];
          end // else: !if(~intr_error_clear_reg_clear[0])
        end // else: !if(~rst_n)
     end // always @ ( posedge axi_aclk )

   always @( posedge axi_aclk )
     begin
        if (~rst_n)
          intr_error_clear_reg_clear[2] <= 1'b0;
        else begin 
          if (~intr_error_clear_reg_clear[2])begin
             if (intr_error_status_reg[2] && intr_error_clear_reg[2]) 
               intr_error_clear_reg_clear[2] <= 1'b1;
             else
               intr_error_clear_reg_clear[2] <= 1'b0;
          end
          else begin
             if (~reg_wr_en)
               intr_error_clear_reg_clear[2] <= 1'b0;
             else
               intr_error_clear_reg_clear[2] <= intr_error_clear_reg_clear[2];
          end // else: !if(~intr_error_clear_reg_clear[0])
        end // else: !if(~rst_n)
     end // always @ ( posedge axi_aclk )
   
   always @( posedge axi_aclk )
     begin
        for (i = 3; i < 32 ; i = i + 1) begin
          intr_error_clear_reg_clear[i] <= 1'b0;
        end
     end // always @ ( posedge axi_aclk )




   // INTR_C2H_TOGGLE_CLEAR_0_REG
   always @( posedge axi_aclk )
     begin
		for(i = 0; i < 32; i = i + 1 )
		  begin
			 if (~rst_n)
			   intr_c2h_toggle_clear_0_reg_clear[i] <= 1'b0;
			 else begin 
				if (~intr_c2h_toggle_clear_0_reg_clear[i])begin
				   if (intr_c2h_toggle_clear_0_reg[i]) 
					 intr_c2h_toggle_clear_0_reg_clear[i] <= 1'b1;
				   else
					 intr_c2h_toggle_clear_0_reg_clear[i] <= 1'b0;
				end
				else begin
				   if (~reg_wr_en)
					 intr_c2h_toggle_clear_0_reg_clear[i] <= 1'b0;
				   else
					 intr_c2h_toggle_clear_0_reg_clear[i] <= intr_c2h_toggle_clear_0_reg_clear[i];
				end // else: !if(~intr_c2h_toggle_clear_0_reg_clear[i])
			 end // else: !if(~rst_n)
		  end // always @ ( posedge axi_aclk )
	 end // always @ ( posedge axi_aclk )
   


   // INTR_C2H_TOGGLE_CLEAR_1_REG
   always @( posedge axi_aclk )
     begin
		for(i = 0; i < 32; i = i + 1 )
		  begin
			 if (~rst_n)
			   intr_c2h_toggle_clear_1_reg_clear[i] <= 1'b0;
			 else begin 
				if (~intr_c2h_toggle_clear_1_reg_clear[i])begin
				   if (intr_c2h_toggle_clear_1_reg[i]) 
					 intr_c2h_toggle_clear_1_reg_clear[i] <= 1'b1;
				   else
					 intr_c2h_toggle_clear_1_reg_clear[i] <= 1'b0;
				end
				else begin
				   if (~reg_wr_en)
					 intr_c2h_toggle_clear_1_reg_clear[i] <= 1'b0;
				   else
					 intr_c2h_toggle_clear_1_reg_clear[i] <= intr_c2h_toggle_clear_1_reg_clear[i];
				end // else: !if(~intr_c2h_toggle_clear_0_reg_clear[i])
			 end // else: !if(~rst_n)
		  end // always @ ( posedge axi_aclk )
	 end // always @ ( posedge axi_aclk )

   // H2C_PULSE_0_REG
   always @( posedge axi_aclk )
     begin
	for(i = 0; i < 32; i = i + 1 )
	  begin
	     if (~rst_n)
	       h2c_pulse_0_reg_clear[i] <= 1'b0;
	     else begin 
		if (~h2c_pulse_0_reg_clear[i])begin
		   if (h2c_pulse_0_reg[i]) 
		     h2c_pulse_0_reg_clear[i] <= 1'b1;
		   else
		     h2c_pulse_0_reg_clear[i] <= 1'b0;
		end
		else begin
		   if (~reg_wr_en)
		     h2c_pulse_0_reg_clear[i] <= 1'b0;
		   else
		     h2c_pulse_0_reg_clear[i] <= h2c_pulse_0_reg_clear[i];
		end 
	     end 
	  end 
     end 
   

   // H2C_PULSE_1_REG
   always @( posedge axi_aclk )
     begin
	for(i = 0; i < 32; i = i + 1 )
	  begin
	     if (~rst_n)
	       h2c_pulse_1_reg_clear[i] <= 1'b0;
	     else begin 
		if (~h2c_pulse_1_reg_clear[i])begin
		   if (h2c_pulse_1_reg[i]) 
		     h2c_pulse_1_reg_clear[i] <= 1'b1;
		   else
		     h2c_pulse_1_reg_clear[i] <= 1'b0;
		end
		else begin
		   if (~reg_wr_en)
		     h2c_pulse_1_reg_clear[i] <= 1'b0;
		   else
		     h2c_pulse_1_reg_clear[i] <= h2c_pulse_1_reg_clear[i];
		end 
	     end 
	  end 
     end 
   



   


//INTR_STATUS_REG
   always @( posedge axi_aclk )
     begin
        if (~rst_n)
          intr_status_reg <= 32'b0;
        else
          intr_status_reg <= { 28'b0, |(intr_comp_status_reg), |({ ( intr_c2h_toggle_status_0_reg ) , ( intr_c2h_toggle_status_1_reg ) }), |(intr_error_status_reg), |(intr_txn_avail_status_reg) };
     end


//STATUS_BUSY_REG
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           status_busy_reg[i] <= 1'b0;
           else 
             if (uc2rb_status_busy_reg_we[i])
                status_busy_reg[i] <= uc2rb_status_busy_reg[i];
             else 
               status_busy_reg[i] <= status_busy_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//RESP_FIFO_FREE_LEVEL_REG
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           resp_fifo_free_level_reg[i] <= 1'b0;
           else 
             if (uc2rb_resp_fifo_free_level_reg_we[i])
                resp_fifo_free_level_reg[i] <= uc2rb_resp_fifo_free_level_reg[i];
             else 
               resp_fifo_free_level_reg[i] <= resp_fifo_free_level_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_0

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_txn_type_reg_we[i])
                desc_0_txn_type_reg[i] <= uc2rb_desc_0_txn_type_reg[i];
             else 
               desc_0_txn_type_reg[i] <= desc_0_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_size_reg_we[i])
                desc_0_size_reg[i] <= uc2rb_desc_0_size_reg[i];
             else 
               desc_0_size_reg[i] <= desc_0_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_data_offset_reg_we[i])
                desc_0_data_offset_reg[i] <= uc2rb_desc_0_data_offset_reg[i];
             else 
               desc_0_data_offset_reg[i] <= desc_0_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axsize_reg_we[i])
                desc_0_axsize_reg[i] <= uc2rb_desc_0_axsize_reg[i];
             else 
               desc_0_axsize_reg[i] <= desc_0_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_attr_reg_we[i])
                desc_0_attr_reg[i] <= uc2rb_desc_0_attr_reg[i];
             else 
               desc_0_attr_reg[i] <= desc_0_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axaddr_0_reg_we[i])
                desc_0_axaddr_0_reg[i] <= uc2rb_desc_0_axaddr_0_reg[i];
             else 
               desc_0_axaddr_0_reg[i] <= desc_0_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axaddr_1_reg_we[i])
                desc_0_axaddr_1_reg[i] <= uc2rb_desc_0_axaddr_1_reg[i];
             else 
               desc_0_axaddr_1_reg[i] <= desc_0_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axaddr_2_reg_we[i])
                desc_0_axaddr_2_reg[i] <= uc2rb_desc_0_axaddr_2_reg[i];
             else 
               desc_0_axaddr_2_reg[i] <= desc_0_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axaddr_3_reg_we[i])
                desc_0_axaddr_3_reg[i] <= uc2rb_desc_0_axaddr_3_reg[i];
             else 
               desc_0_axaddr_3_reg[i] <= desc_0_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axid_0_reg_we[i])
                desc_0_axid_0_reg[i] <= uc2rb_desc_0_axid_0_reg[i];
             else 
               desc_0_axid_0_reg[i] <= desc_0_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axid_1_reg_we[i])
                desc_0_axid_1_reg[i] <= uc2rb_desc_0_axid_1_reg[i];
             else 
               desc_0_axid_1_reg[i] <= desc_0_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axid_2_reg_we[i])
                desc_0_axid_2_reg[i] <= uc2rb_desc_0_axid_2_reg[i];
             else 
               desc_0_axid_2_reg[i] <= desc_0_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axid_3_reg_we[i])
                desc_0_axid_3_reg[i] <= uc2rb_desc_0_axid_3_reg[i];
             else 
               desc_0_axid_3_reg[i] <= desc_0_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_0_reg_we[i])
                desc_0_axuser_0_reg[i] <= uc2rb_desc_0_axuser_0_reg[i];
             else 
               desc_0_axuser_0_reg[i] <= desc_0_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_1_reg_we[i])
                desc_0_axuser_1_reg[i] <= uc2rb_desc_0_axuser_1_reg[i];
             else 
               desc_0_axuser_1_reg[i] <= desc_0_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_2_reg_we[i])
                desc_0_axuser_2_reg[i] <= uc2rb_desc_0_axuser_2_reg[i];
             else 
               desc_0_axuser_2_reg[i] <= desc_0_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_3_reg_we[i])
                desc_0_axuser_3_reg[i] <= uc2rb_desc_0_axuser_3_reg[i];
             else 
               desc_0_axuser_3_reg[i] <= desc_0_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_4_reg_we[i])
                desc_0_axuser_4_reg[i] <= uc2rb_desc_0_axuser_4_reg[i];
             else 
               desc_0_axuser_4_reg[i] <= desc_0_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_5_reg_we[i])
                desc_0_axuser_5_reg[i] <= uc2rb_desc_0_axuser_5_reg[i];
             else 
               desc_0_axuser_5_reg[i] <= desc_0_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_6_reg_we[i])
                desc_0_axuser_6_reg[i] <= uc2rb_desc_0_axuser_6_reg[i];
             else 
               desc_0_axuser_6_reg[i] <= desc_0_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_7_reg_we[i])
                desc_0_axuser_7_reg[i] <= uc2rb_desc_0_axuser_7_reg[i];
             else 
               desc_0_axuser_7_reg[i] <= desc_0_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_8_reg_we[i])
                desc_0_axuser_8_reg[i] <= uc2rb_desc_0_axuser_8_reg[i];
             else 
               desc_0_axuser_8_reg[i] <= desc_0_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_9_reg_we[i])
                desc_0_axuser_9_reg[i] <= uc2rb_desc_0_axuser_9_reg[i];
             else 
               desc_0_axuser_9_reg[i] <= desc_0_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_10_reg_we[i])
                desc_0_axuser_10_reg[i] <= uc2rb_desc_0_axuser_10_reg[i];
             else 
               desc_0_axuser_10_reg[i] <= desc_0_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_11_reg_we[i])
                desc_0_axuser_11_reg[i] <= uc2rb_desc_0_axuser_11_reg[i];
             else 
               desc_0_axuser_11_reg[i] <= desc_0_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_12_reg_we[i])
                desc_0_axuser_12_reg[i] <= uc2rb_desc_0_axuser_12_reg[i];
             else 
               desc_0_axuser_12_reg[i] <= desc_0_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_13_reg_we[i])
                desc_0_axuser_13_reg[i] <= uc2rb_desc_0_axuser_13_reg[i];
             else 
               desc_0_axuser_13_reg[i] <= desc_0_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_14_reg_we[i])
                desc_0_axuser_14_reg[i] <= uc2rb_desc_0_axuser_14_reg[i];
             else 
               desc_0_axuser_14_reg[i] <= desc_0_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_axuser_15_reg_we[i])
                desc_0_axuser_15_reg[i] <= uc2rb_desc_0_axuser_15_reg[i];
             else 
               desc_0_axuser_15_reg[i] <= desc_0_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_0_reg_we[i])
                desc_0_wuser_0_reg[i] <= uc2rb_desc_0_wuser_0_reg[i];
             else 
               desc_0_wuser_0_reg[i] <= desc_0_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_1_reg_we[i])
                desc_0_wuser_1_reg[i] <= uc2rb_desc_0_wuser_1_reg[i];
             else 
               desc_0_wuser_1_reg[i] <= desc_0_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_2_reg_we[i])
                desc_0_wuser_2_reg[i] <= uc2rb_desc_0_wuser_2_reg[i];
             else 
               desc_0_wuser_2_reg[i] <= desc_0_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_3_reg_we[i])
                desc_0_wuser_3_reg[i] <= uc2rb_desc_0_wuser_3_reg[i];
             else 
               desc_0_wuser_3_reg[i] <= desc_0_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_4_reg_we[i])
                desc_0_wuser_4_reg[i] <= uc2rb_desc_0_wuser_4_reg[i];
             else 
               desc_0_wuser_4_reg[i] <= desc_0_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_5_reg_we[i])
                desc_0_wuser_5_reg[i] <= uc2rb_desc_0_wuser_5_reg[i];
             else 
               desc_0_wuser_5_reg[i] <= desc_0_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_6_reg_we[i])
                desc_0_wuser_6_reg[i] <= uc2rb_desc_0_wuser_6_reg[i];
             else 
               desc_0_wuser_6_reg[i] <= desc_0_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_7_reg_we[i])
                desc_0_wuser_7_reg[i] <= uc2rb_desc_0_wuser_7_reg[i];
             else 
               desc_0_wuser_7_reg[i] <= desc_0_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_8_reg_we[i])
                desc_0_wuser_8_reg[i] <= uc2rb_desc_0_wuser_8_reg[i];
             else 
               desc_0_wuser_8_reg[i] <= desc_0_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_9_reg_we[i])
                desc_0_wuser_9_reg[i] <= uc2rb_desc_0_wuser_9_reg[i];
             else 
               desc_0_wuser_9_reg[i] <= desc_0_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_10_reg_we[i])
                desc_0_wuser_10_reg[i] <= uc2rb_desc_0_wuser_10_reg[i];
             else 
               desc_0_wuser_10_reg[i] <= desc_0_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_11_reg_we[i])
                desc_0_wuser_11_reg[i] <= uc2rb_desc_0_wuser_11_reg[i];
             else 
               desc_0_wuser_11_reg[i] <= desc_0_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_12_reg_we[i])
                desc_0_wuser_12_reg[i] <= uc2rb_desc_0_wuser_12_reg[i];
             else 
               desc_0_wuser_12_reg[i] <= desc_0_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_13_reg_we[i])
                desc_0_wuser_13_reg[i] <= uc2rb_desc_0_wuser_13_reg[i];
             else 
               desc_0_wuser_13_reg[i] <= desc_0_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_14_reg_we[i])
                desc_0_wuser_14_reg[i] <= uc2rb_desc_0_wuser_14_reg[i];
             else 
               desc_0_wuser_14_reg[i] <= desc_0_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_0_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_0_wuser_15_reg_we[i])
                desc_0_wuser_15_reg[i] <= uc2rb_desc_0_wuser_15_reg[i];
             else 
               desc_0_wuser_15_reg[i] <= desc_0_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   
//DESC 1

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_txn_type_reg_we[i])
                desc_1_txn_type_reg[i] <= uc2rb_desc_1_txn_type_reg[i];
             else 
               desc_1_txn_type_reg[i] <= desc_1_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_size_reg_we[i])
                desc_1_size_reg[i] <= uc2rb_desc_1_size_reg[i];
             else 
               desc_1_size_reg[i] <= desc_1_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_data_offset_reg_we[i])
                desc_1_data_offset_reg[i] <= uc2rb_desc_1_data_offset_reg[i];
             else 
               desc_1_data_offset_reg[i] <= desc_1_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axsize_reg_we[i])
                desc_1_axsize_reg[i] <= uc2rb_desc_1_axsize_reg[i];
             else 
               desc_1_axsize_reg[i] <= desc_1_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_attr_reg_we[i])
                desc_1_attr_reg[i] <= uc2rb_desc_1_attr_reg[i];
             else 
               desc_1_attr_reg[i] <= desc_1_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axaddr_0_reg_we[i])
                desc_1_axaddr_0_reg[i] <= uc2rb_desc_1_axaddr_0_reg[i];
             else 
               desc_1_axaddr_0_reg[i] <= desc_1_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axaddr_1_reg_we[i])
                desc_1_axaddr_1_reg[i] <= uc2rb_desc_1_axaddr_1_reg[i];
             else 
               desc_1_axaddr_1_reg[i] <= desc_1_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axaddr_2_reg_we[i])
                desc_1_axaddr_2_reg[i] <= uc2rb_desc_1_axaddr_2_reg[i];
             else 
               desc_1_axaddr_2_reg[i] <= desc_1_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axaddr_3_reg_we[i])
                desc_1_axaddr_3_reg[i] <= uc2rb_desc_1_axaddr_3_reg[i];
             else 
               desc_1_axaddr_3_reg[i] <= desc_1_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axid_0_reg_we[i])
                desc_1_axid_0_reg[i] <= uc2rb_desc_1_axid_0_reg[i];
             else 
               desc_1_axid_0_reg[i] <= desc_1_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axid_1_reg_we[i])
                desc_1_axid_1_reg[i] <= uc2rb_desc_1_axid_1_reg[i];
             else 
               desc_1_axid_1_reg[i] <= desc_1_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axid_2_reg_we[i])
                desc_1_axid_2_reg[i] <= uc2rb_desc_1_axid_2_reg[i];
             else 
               desc_1_axid_2_reg[i] <= desc_1_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axid_3_reg_we[i])
                desc_1_axid_3_reg[i] <= uc2rb_desc_1_axid_3_reg[i];
             else 
               desc_1_axid_3_reg[i] <= desc_1_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_0_reg_we[i])
                desc_1_axuser_0_reg[i] <= uc2rb_desc_1_axuser_0_reg[i];
             else 
               desc_1_axuser_0_reg[i] <= desc_1_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_1_reg_we[i])
                desc_1_axuser_1_reg[i] <= uc2rb_desc_1_axuser_1_reg[i];
             else 
               desc_1_axuser_1_reg[i] <= desc_1_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_2_reg_we[i])
                desc_1_axuser_2_reg[i] <= uc2rb_desc_1_axuser_2_reg[i];
             else 
               desc_1_axuser_2_reg[i] <= desc_1_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_3_reg_we[i])
                desc_1_axuser_3_reg[i] <= uc2rb_desc_1_axuser_3_reg[i];
             else 
               desc_1_axuser_3_reg[i] <= desc_1_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_4_reg_we[i])
                desc_1_axuser_4_reg[i] <= uc2rb_desc_1_axuser_4_reg[i];
             else 
               desc_1_axuser_4_reg[i] <= desc_1_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_5_reg_we[i])
                desc_1_axuser_5_reg[i] <= uc2rb_desc_1_axuser_5_reg[i];
             else 
               desc_1_axuser_5_reg[i] <= desc_1_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_6_reg_we[i])
                desc_1_axuser_6_reg[i] <= uc2rb_desc_1_axuser_6_reg[i];
             else 
               desc_1_axuser_6_reg[i] <= desc_1_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_7_reg_we[i])
                desc_1_axuser_7_reg[i] <= uc2rb_desc_1_axuser_7_reg[i];
             else 
               desc_1_axuser_7_reg[i] <= desc_1_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_8_reg_we[i])
                desc_1_axuser_8_reg[i] <= uc2rb_desc_1_axuser_8_reg[i];
             else 
               desc_1_axuser_8_reg[i] <= desc_1_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_9_reg_we[i])
                desc_1_axuser_9_reg[i] <= uc2rb_desc_1_axuser_9_reg[i];
             else 
               desc_1_axuser_9_reg[i] <= desc_1_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_10_reg_we[i])
                desc_1_axuser_10_reg[i] <= uc2rb_desc_1_axuser_10_reg[i];
             else 
               desc_1_axuser_10_reg[i] <= desc_1_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_11_reg_we[i])
                desc_1_axuser_11_reg[i] <= uc2rb_desc_1_axuser_11_reg[i];
             else 
               desc_1_axuser_11_reg[i] <= desc_1_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_12_reg_we[i])
                desc_1_axuser_12_reg[i] <= uc2rb_desc_1_axuser_12_reg[i];
             else 
               desc_1_axuser_12_reg[i] <= desc_1_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_13_reg_we[i])
                desc_1_axuser_13_reg[i] <= uc2rb_desc_1_axuser_13_reg[i];
             else 
               desc_1_axuser_13_reg[i] <= desc_1_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_14_reg_we[i])
                desc_1_axuser_14_reg[i] <= uc2rb_desc_1_axuser_14_reg[i];
             else 
               desc_1_axuser_14_reg[i] <= desc_1_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_axuser_15_reg_we[i])
                desc_1_axuser_15_reg[i] <= uc2rb_desc_1_axuser_15_reg[i];
             else 
               desc_1_axuser_15_reg[i] <= desc_1_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_0_reg_we[i])
                desc_1_wuser_0_reg[i] <= uc2rb_desc_1_wuser_0_reg[i];
             else 
               desc_1_wuser_0_reg[i] <= desc_1_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_1_reg_we[i])
                desc_1_wuser_1_reg[i] <= uc2rb_desc_1_wuser_1_reg[i];
             else 
               desc_1_wuser_1_reg[i] <= desc_1_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_2_reg_we[i])
                desc_1_wuser_2_reg[i] <= uc2rb_desc_1_wuser_2_reg[i];
             else 
               desc_1_wuser_2_reg[i] <= desc_1_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_3_reg_we[i])
                desc_1_wuser_3_reg[i] <= uc2rb_desc_1_wuser_3_reg[i];
             else 
               desc_1_wuser_3_reg[i] <= desc_1_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_4_reg_we[i])
                desc_1_wuser_4_reg[i] <= uc2rb_desc_1_wuser_4_reg[i];
             else 
               desc_1_wuser_4_reg[i] <= desc_1_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_5_reg_we[i])
                desc_1_wuser_5_reg[i] <= uc2rb_desc_1_wuser_5_reg[i];
             else 
               desc_1_wuser_5_reg[i] <= desc_1_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_6_reg_we[i])
                desc_1_wuser_6_reg[i] <= uc2rb_desc_1_wuser_6_reg[i];
             else 
               desc_1_wuser_6_reg[i] <= desc_1_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_7_reg_we[i])
                desc_1_wuser_7_reg[i] <= uc2rb_desc_1_wuser_7_reg[i];
             else 
               desc_1_wuser_7_reg[i] <= desc_1_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_8_reg_we[i])
                desc_1_wuser_8_reg[i] <= uc2rb_desc_1_wuser_8_reg[i];
             else 
               desc_1_wuser_8_reg[i] <= desc_1_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_9_reg_we[i])
                desc_1_wuser_9_reg[i] <= uc2rb_desc_1_wuser_9_reg[i];
             else 
               desc_1_wuser_9_reg[i] <= desc_1_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_10_reg_we[i])
                desc_1_wuser_10_reg[i] <= uc2rb_desc_1_wuser_10_reg[i];
             else 
               desc_1_wuser_10_reg[i] <= desc_1_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_11_reg_we[i])
                desc_1_wuser_11_reg[i] <= uc2rb_desc_1_wuser_11_reg[i];
             else 
               desc_1_wuser_11_reg[i] <= desc_1_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_12_reg_we[i])
                desc_1_wuser_12_reg[i] <= uc2rb_desc_1_wuser_12_reg[i];
             else 
               desc_1_wuser_12_reg[i] <= desc_1_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_13_reg_we[i])
                desc_1_wuser_13_reg[i] <= uc2rb_desc_1_wuser_13_reg[i];
             else 
               desc_1_wuser_13_reg[i] <= desc_1_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_14_reg_we[i])
                desc_1_wuser_14_reg[i] <= uc2rb_desc_1_wuser_14_reg[i];
             else 
               desc_1_wuser_14_reg[i] <= desc_1_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_1_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_1_wuser_15_reg_we[i])
                desc_1_wuser_15_reg[i] <= uc2rb_desc_1_wuser_15_reg[i];
             else 
               desc_1_wuser_15_reg[i] <= desc_1_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_2

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_txn_type_reg_we[i])
                desc_2_txn_type_reg[i] <= uc2rb_desc_2_txn_type_reg[i];
             else 
               desc_2_txn_type_reg[i] <= desc_2_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_size_reg_we[i])
                desc_2_size_reg[i] <= uc2rb_desc_2_size_reg[i];
             else 
               desc_2_size_reg[i] <= desc_2_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_data_offset_reg_we[i])
                desc_2_data_offset_reg[i] <= uc2rb_desc_2_data_offset_reg[i];
             else 
               desc_2_data_offset_reg[i] <= desc_2_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axsize_reg_we[i])
                desc_2_axsize_reg[i] <= uc2rb_desc_2_axsize_reg[i];
             else 
               desc_2_axsize_reg[i] <= desc_2_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_attr_reg_we[i])
                desc_2_attr_reg[i] <= uc2rb_desc_2_attr_reg[i];
             else 
               desc_2_attr_reg[i] <= desc_2_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axaddr_0_reg_we[i])
                desc_2_axaddr_0_reg[i] <= uc2rb_desc_2_axaddr_0_reg[i];
             else 
               desc_2_axaddr_0_reg[i] <= desc_2_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axaddr_1_reg_we[i])
                desc_2_axaddr_1_reg[i] <= uc2rb_desc_2_axaddr_1_reg[i];
             else 
               desc_2_axaddr_1_reg[i] <= desc_2_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axaddr_2_reg_we[i])
                desc_2_axaddr_2_reg[i] <= uc2rb_desc_2_axaddr_2_reg[i];
             else 
               desc_2_axaddr_2_reg[i] <= desc_2_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axaddr_3_reg_we[i])
                desc_2_axaddr_3_reg[i] <= uc2rb_desc_2_axaddr_3_reg[i];
             else 
               desc_2_axaddr_3_reg[i] <= desc_2_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axid_0_reg_we[i])
                desc_2_axid_0_reg[i] <= uc2rb_desc_2_axid_0_reg[i];
             else 
               desc_2_axid_0_reg[i] <= desc_2_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axid_1_reg_we[i])
                desc_2_axid_1_reg[i] <= uc2rb_desc_2_axid_1_reg[i];
             else 
               desc_2_axid_1_reg[i] <= desc_2_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axid_2_reg_we[i])
                desc_2_axid_2_reg[i] <= uc2rb_desc_2_axid_2_reg[i];
             else 
               desc_2_axid_2_reg[i] <= desc_2_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axid_3_reg_we[i])
                desc_2_axid_3_reg[i] <= uc2rb_desc_2_axid_3_reg[i];
             else 
               desc_2_axid_3_reg[i] <= desc_2_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_0_reg_we[i])
                desc_2_axuser_0_reg[i] <= uc2rb_desc_2_axuser_0_reg[i];
             else 
               desc_2_axuser_0_reg[i] <= desc_2_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_1_reg_we[i])
                desc_2_axuser_1_reg[i] <= uc2rb_desc_2_axuser_1_reg[i];
             else 
               desc_2_axuser_1_reg[i] <= desc_2_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_2_reg_we[i])
                desc_2_axuser_2_reg[i] <= uc2rb_desc_2_axuser_2_reg[i];
             else 
               desc_2_axuser_2_reg[i] <= desc_2_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_3_reg_we[i])
                desc_2_axuser_3_reg[i] <= uc2rb_desc_2_axuser_3_reg[i];
             else 
               desc_2_axuser_3_reg[i] <= desc_2_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_4_reg_we[i])
                desc_2_axuser_4_reg[i] <= uc2rb_desc_2_axuser_4_reg[i];
             else 
               desc_2_axuser_4_reg[i] <= desc_2_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_5_reg_we[i])
                desc_2_axuser_5_reg[i] <= uc2rb_desc_2_axuser_5_reg[i];
             else 
               desc_2_axuser_5_reg[i] <= desc_2_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_6_reg_we[i])
                desc_2_axuser_6_reg[i] <= uc2rb_desc_2_axuser_6_reg[i];
             else 
               desc_2_axuser_6_reg[i] <= desc_2_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_7_reg_we[i])
                desc_2_axuser_7_reg[i] <= uc2rb_desc_2_axuser_7_reg[i];
             else 
               desc_2_axuser_7_reg[i] <= desc_2_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_8_reg_we[i])
                desc_2_axuser_8_reg[i] <= uc2rb_desc_2_axuser_8_reg[i];
             else 
               desc_2_axuser_8_reg[i] <= desc_2_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_9_reg_we[i])
                desc_2_axuser_9_reg[i] <= uc2rb_desc_2_axuser_9_reg[i];
             else 
               desc_2_axuser_9_reg[i] <= desc_2_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_10_reg_we[i])
                desc_2_axuser_10_reg[i] <= uc2rb_desc_2_axuser_10_reg[i];
             else 
               desc_2_axuser_10_reg[i] <= desc_2_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_11_reg_we[i])
                desc_2_axuser_11_reg[i] <= uc2rb_desc_2_axuser_11_reg[i];
             else 
               desc_2_axuser_11_reg[i] <= desc_2_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_12_reg_we[i])
                desc_2_axuser_12_reg[i] <= uc2rb_desc_2_axuser_12_reg[i];
             else 
               desc_2_axuser_12_reg[i] <= desc_2_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_13_reg_we[i])
                desc_2_axuser_13_reg[i] <= uc2rb_desc_2_axuser_13_reg[i];
             else 
               desc_2_axuser_13_reg[i] <= desc_2_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_14_reg_we[i])
                desc_2_axuser_14_reg[i] <= uc2rb_desc_2_axuser_14_reg[i];
             else 
               desc_2_axuser_14_reg[i] <= desc_2_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_axuser_15_reg_we[i])
                desc_2_axuser_15_reg[i] <= uc2rb_desc_2_axuser_15_reg[i];
             else 
               desc_2_axuser_15_reg[i] <= desc_2_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_0_reg_we[i])
                desc_2_wuser_0_reg[i] <= uc2rb_desc_2_wuser_0_reg[i];
             else 
               desc_2_wuser_0_reg[i] <= desc_2_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_1_reg_we[i])
                desc_2_wuser_1_reg[i] <= uc2rb_desc_2_wuser_1_reg[i];
             else 
               desc_2_wuser_1_reg[i] <= desc_2_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_2_reg_we[i])
                desc_2_wuser_2_reg[i] <= uc2rb_desc_2_wuser_2_reg[i];
             else 
               desc_2_wuser_2_reg[i] <= desc_2_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_3_reg_we[i])
                desc_2_wuser_3_reg[i] <= uc2rb_desc_2_wuser_3_reg[i];
             else 
               desc_2_wuser_3_reg[i] <= desc_2_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_4_reg_we[i])
                desc_2_wuser_4_reg[i] <= uc2rb_desc_2_wuser_4_reg[i];
             else 
               desc_2_wuser_4_reg[i] <= desc_2_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_5_reg_we[i])
                desc_2_wuser_5_reg[i] <= uc2rb_desc_2_wuser_5_reg[i];
             else 
               desc_2_wuser_5_reg[i] <= desc_2_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_6_reg_we[i])
                desc_2_wuser_6_reg[i] <= uc2rb_desc_2_wuser_6_reg[i];
             else 
               desc_2_wuser_6_reg[i] <= desc_2_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_7_reg_we[i])
                desc_2_wuser_7_reg[i] <= uc2rb_desc_2_wuser_7_reg[i];
             else 
               desc_2_wuser_7_reg[i] <= desc_2_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_8_reg_we[i])
                desc_2_wuser_8_reg[i] <= uc2rb_desc_2_wuser_8_reg[i];
             else 
               desc_2_wuser_8_reg[i] <= desc_2_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_9_reg_we[i])
                desc_2_wuser_9_reg[i] <= uc2rb_desc_2_wuser_9_reg[i];
             else 
               desc_2_wuser_9_reg[i] <= desc_2_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_10_reg_we[i])
                desc_2_wuser_10_reg[i] <= uc2rb_desc_2_wuser_10_reg[i];
             else 
               desc_2_wuser_10_reg[i] <= desc_2_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_11_reg_we[i])
                desc_2_wuser_11_reg[i] <= uc2rb_desc_2_wuser_11_reg[i];
             else 
               desc_2_wuser_11_reg[i] <= desc_2_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_12_reg_we[i])
                desc_2_wuser_12_reg[i] <= uc2rb_desc_2_wuser_12_reg[i];
             else 
               desc_2_wuser_12_reg[i] <= desc_2_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_13_reg_we[i])
                desc_2_wuser_13_reg[i] <= uc2rb_desc_2_wuser_13_reg[i];
             else 
               desc_2_wuser_13_reg[i] <= desc_2_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_14_reg_we[i])
                desc_2_wuser_14_reg[i] <= uc2rb_desc_2_wuser_14_reg[i];
             else 
               desc_2_wuser_14_reg[i] <= desc_2_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_2_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_2_wuser_15_reg_we[i])
                desc_2_wuser_15_reg[i] <= uc2rb_desc_2_wuser_15_reg[i];
             else 
               desc_2_wuser_15_reg[i] <= desc_2_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_3

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_txn_type_reg_we[i])
                desc_3_txn_type_reg[i] <= uc2rb_desc_3_txn_type_reg[i];
             else 
               desc_3_txn_type_reg[i] <= desc_3_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_size_reg_we[i])
                desc_3_size_reg[i] <= uc2rb_desc_3_size_reg[i];
             else 
               desc_3_size_reg[i] <= desc_3_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_data_offset_reg_we[i])
                desc_3_data_offset_reg[i] <= uc2rb_desc_3_data_offset_reg[i];
             else 
               desc_3_data_offset_reg[i] <= desc_3_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axsize_reg_we[i])
                desc_3_axsize_reg[i] <= uc2rb_desc_3_axsize_reg[i];
             else 
               desc_3_axsize_reg[i] <= desc_3_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_attr_reg_we[i])
                desc_3_attr_reg[i] <= uc2rb_desc_3_attr_reg[i];
             else 
               desc_3_attr_reg[i] <= desc_3_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axaddr_0_reg_we[i])
                desc_3_axaddr_0_reg[i] <= uc2rb_desc_3_axaddr_0_reg[i];
             else 
               desc_3_axaddr_0_reg[i] <= desc_3_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axaddr_1_reg_we[i])
                desc_3_axaddr_1_reg[i] <= uc2rb_desc_3_axaddr_1_reg[i];
             else 
               desc_3_axaddr_1_reg[i] <= desc_3_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axaddr_2_reg_we[i])
                desc_3_axaddr_2_reg[i] <= uc2rb_desc_3_axaddr_2_reg[i];
             else 
               desc_3_axaddr_2_reg[i] <= desc_3_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axaddr_3_reg_we[i])
                desc_3_axaddr_3_reg[i] <= uc2rb_desc_3_axaddr_3_reg[i];
             else 
               desc_3_axaddr_3_reg[i] <= desc_3_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axid_0_reg_we[i])
                desc_3_axid_0_reg[i] <= uc2rb_desc_3_axid_0_reg[i];
             else 
               desc_3_axid_0_reg[i] <= desc_3_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axid_1_reg_we[i])
                desc_3_axid_1_reg[i] <= uc2rb_desc_3_axid_1_reg[i];
             else 
               desc_3_axid_1_reg[i] <= desc_3_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axid_2_reg_we[i])
                desc_3_axid_2_reg[i] <= uc2rb_desc_3_axid_2_reg[i];
             else 
               desc_3_axid_2_reg[i] <= desc_3_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axid_3_reg_we[i])
                desc_3_axid_3_reg[i] <= uc2rb_desc_3_axid_3_reg[i];
             else 
               desc_3_axid_3_reg[i] <= desc_3_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_0_reg_we[i])
                desc_3_axuser_0_reg[i] <= uc2rb_desc_3_axuser_0_reg[i];
             else 
               desc_3_axuser_0_reg[i] <= desc_3_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_1_reg_we[i])
                desc_3_axuser_1_reg[i] <= uc2rb_desc_3_axuser_1_reg[i];
             else 
               desc_3_axuser_1_reg[i] <= desc_3_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_2_reg_we[i])
                desc_3_axuser_2_reg[i] <= uc2rb_desc_3_axuser_2_reg[i];
             else 
               desc_3_axuser_2_reg[i] <= desc_3_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_3_reg_we[i])
                desc_3_axuser_3_reg[i] <= uc2rb_desc_3_axuser_3_reg[i];
             else 
               desc_3_axuser_3_reg[i] <= desc_3_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_4_reg_we[i])
                desc_3_axuser_4_reg[i] <= uc2rb_desc_3_axuser_4_reg[i];
             else 
               desc_3_axuser_4_reg[i] <= desc_3_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_5_reg_we[i])
                desc_3_axuser_5_reg[i] <= uc2rb_desc_3_axuser_5_reg[i];
             else 
               desc_3_axuser_5_reg[i] <= desc_3_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_6_reg_we[i])
                desc_3_axuser_6_reg[i] <= uc2rb_desc_3_axuser_6_reg[i];
             else 
               desc_3_axuser_6_reg[i] <= desc_3_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_7_reg_we[i])
                desc_3_axuser_7_reg[i] <= uc2rb_desc_3_axuser_7_reg[i];
             else 
               desc_3_axuser_7_reg[i] <= desc_3_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_8_reg_we[i])
                desc_3_axuser_8_reg[i] <= uc2rb_desc_3_axuser_8_reg[i];
             else 
               desc_3_axuser_8_reg[i] <= desc_3_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_9_reg_we[i])
                desc_3_axuser_9_reg[i] <= uc2rb_desc_3_axuser_9_reg[i];
             else 
               desc_3_axuser_9_reg[i] <= desc_3_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_10_reg_we[i])
                desc_3_axuser_10_reg[i] <= uc2rb_desc_3_axuser_10_reg[i];
             else 
               desc_3_axuser_10_reg[i] <= desc_3_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_11_reg_we[i])
                desc_3_axuser_11_reg[i] <= uc2rb_desc_3_axuser_11_reg[i];
             else 
               desc_3_axuser_11_reg[i] <= desc_3_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_12_reg_we[i])
                desc_3_axuser_12_reg[i] <= uc2rb_desc_3_axuser_12_reg[i];
             else 
               desc_3_axuser_12_reg[i] <= desc_3_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_13_reg_we[i])
                desc_3_axuser_13_reg[i] <= uc2rb_desc_3_axuser_13_reg[i];
             else 
               desc_3_axuser_13_reg[i] <= desc_3_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_14_reg_we[i])
                desc_3_axuser_14_reg[i] <= uc2rb_desc_3_axuser_14_reg[i];
             else 
               desc_3_axuser_14_reg[i] <= desc_3_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_axuser_15_reg_we[i])
                desc_3_axuser_15_reg[i] <= uc2rb_desc_3_axuser_15_reg[i];
             else 
               desc_3_axuser_15_reg[i] <= desc_3_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_0_reg_we[i])
                desc_3_wuser_0_reg[i] <= uc2rb_desc_3_wuser_0_reg[i];
             else 
               desc_3_wuser_0_reg[i] <= desc_3_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_1_reg_we[i])
                desc_3_wuser_1_reg[i] <= uc2rb_desc_3_wuser_1_reg[i];
             else 
               desc_3_wuser_1_reg[i] <= desc_3_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_2_reg_we[i])
                desc_3_wuser_2_reg[i] <= uc2rb_desc_3_wuser_2_reg[i];
             else 
               desc_3_wuser_2_reg[i] <= desc_3_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_3_reg_we[i])
                desc_3_wuser_3_reg[i] <= uc2rb_desc_3_wuser_3_reg[i];
             else 
               desc_3_wuser_3_reg[i] <= desc_3_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_4_reg_we[i])
                desc_3_wuser_4_reg[i] <= uc2rb_desc_3_wuser_4_reg[i];
             else 
               desc_3_wuser_4_reg[i] <= desc_3_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_5_reg_we[i])
                desc_3_wuser_5_reg[i] <= uc2rb_desc_3_wuser_5_reg[i];
             else 
               desc_3_wuser_5_reg[i] <= desc_3_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_6_reg_we[i])
                desc_3_wuser_6_reg[i] <= uc2rb_desc_3_wuser_6_reg[i];
             else 
               desc_3_wuser_6_reg[i] <= desc_3_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_7_reg_we[i])
                desc_3_wuser_7_reg[i] <= uc2rb_desc_3_wuser_7_reg[i];
             else 
               desc_3_wuser_7_reg[i] <= desc_3_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_8_reg_we[i])
                desc_3_wuser_8_reg[i] <= uc2rb_desc_3_wuser_8_reg[i];
             else 
               desc_3_wuser_8_reg[i] <= desc_3_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_9_reg_we[i])
                desc_3_wuser_9_reg[i] <= uc2rb_desc_3_wuser_9_reg[i];
             else 
               desc_3_wuser_9_reg[i] <= desc_3_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_10_reg_we[i])
                desc_3_wuser_10_reg[i] <= uc2rb_desc_3_wuser_10_reg[i];
             else 
               desc_3_wuser_10_reg[i] <= desc_3_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_11_reg_we[i])
                desc_3_wuser_11_reg[i] <= uc2rb_desc_3_wuser_11_reg[i];
             else 
               desc_3_wuser_11_reg[i] <= desc_3_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_12_reg_we[i])
                desc_3_wuser_12_reg[i] <= uc2rb_desc_3_wuser_12_reg[i];
             else 
               desc_3_wuser_12_reg[i] <= desc_3_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_13_reg_we[i])
                desc_3_wuser_13_reg[i] <= uc2rb_desc_3_wuser_13_reg[i];
             else 
               desc_3_wuser_13_reg[i] <= desc_3_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_14_reg_we[i])
                desc_3_wuser_14_reg[i] <= uc2rb_desc_3_wuser_14_reg[i];
             else 
               desc_3_wuser_14_reg[i] <= desc_3_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_3_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_3_wuser_15_reg_we[i])
                desc_3_wuser_15_reg[i] <= uc2rb_desc_3_wuser_15_reg[i];
             else 
               desc_3_wuser_15_reg[i] <= desc_3_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_4

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_txn_type_reg_we[i])
                desc_4_txn_type_reg[i] <= uc2rb_desc_4_txn_type_reg[i];
             else 
               desc_4_txn_type_reg[i] <= desc_4_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_size_reg_we[i])
                desc_4_size_reg[i] <= uc2rb_desc_4_size_reg[i];
             else 
               desc_4_size_reg[i] <= desc_4_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_data_offset_reg_we[i])
                desc_4_data_offset_reg[i] <= uc2rb_desc_4_data_offset_reg[i];
             else 
               desc_4_data_offset_reg[i] <= desc_4_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axsize_reg_we[i])
                desc_4_axsize_reg[i] <= uc2rb_desc_4_axsize_reg[i];
             else 
               desc_4_axsize_reg[i] <= desc_4_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_attr_reg_we[i])
                desc_4_attr_reg[i] <= uc2rb_desc_4_attr_reg[i];
             else 
               desc_4_attr_reg[i] <= desc_4_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axaddr_0_reg_we[i])
                desc_4_axaddr_0_reg[i] <= uc2rb_desc_4_axaddr_0_reg[i];
             else 
               desc_4_axaddr_0_reg[i] <= desc_4_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axaddr_1_reg_we[i])
                desc_4_axaddr_1_reg[i] <= uc2rb_desc_4_axaddr_1_reg[i];
             else 
               desc_4_axaddr_1_reg[i] <= desc_4_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axaddr_2_reg_we[i])
                desc_4_axaddr_2_reg[i] <= uc2rb_desc_4_axaddr_2_reg[i];
             else 
               desc_4_axaddr_2_reg[i] <= desc_4_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axaddr_3_reg_we[i])
                desc_4_axaddr_3_reg[i] <= uc2rb_desc_4_axaddr_3_reg[i];
             else 
               desc_4_axaddr_3_reg[i] <= desc_4_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axid_0_reg_we[i])
                desc_4_axid_0_reg[i] <= uc2rb_desc_4_axid_0_reg[i];
             else 
               desc_4_axid_0_reg[i] <= desc_4_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axid_1_reg_we[i])
                desc_4_axid_1_reg[i] <= uc2rb_desc_4_axid_1_reg[i];
             else 
               desc_4_axid_1_reg[i] <= desc_4_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axid_2_reg_we[i])
                desc_4_axid_2_reg[i] <= uc2rb_desc_4_axid_2_reg[i];
             else 
               desc_4_axid_2_reg[i] <= desc_4_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axid_3_reg_we[i])
                desc_4_axid_3_reg[i] <= uc2rb_desc_4_axid_3_reg[i];
             else 
               desc_4_axid_3_reg[i] <= desc_4_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_0_reg_we[i])
                desc_4_axuser_0_reg[i] <= uc2rb_desc_4_axuser_0_reg[i];
             else 
               desc_4_axuser_0_reg[i] <= desc_4_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_1_reg_we[i])
                desc_4_axuser_1_reg[i] <= uc2rb_desc_4_axuser_1_reg[i];
             else 
               desc_4_axuser_1_reg[i] <= desc_4_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_2_reg_we[i])
                desc_4_axuser_2_reg[i] <= uc2rb_desc_4_axuser_2_reg[i];
             else 
               desc_4_axuser_2_reg[i] <= desc_4_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_3_reg_we[i])
                desc_4_axuser_3_reg[i] <= uc2rb_desc_4_axuser_3_reg[i];
             else 
               desc_4_axuser_3_reg[i] <= desc_4_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_4_reg_we[i])
                desc_4_axuser_4_reg[i] <= uc2rb_desc_4_axuser_4_reg[i];
             else 
               desc_4_axuser_4_reg[i] <= desc_4_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_5_reg_we[i])
                desc_4_axuser_5_reg[i] <= uc2rb_desc_4_axuser_5_reg[i];
             else 
               desc_4_axuser_5_reg[i] <= desc_4_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_6_reg_we[i])
                desc_4_axuser_6_reg[i] <= uc2rb_desc_4_axuser_6_reg[i];
             else 
               desc_4_axuser_6_reg[i] <= desc_4_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_7_reg_we[i])
                desc_4_axuser_7_reg[i] <= uc2rb_desc_4_axuser_7_reg[i];
             else 
               desc_4_axuser_7_reg[i] <= desc_4_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_8_reg_we[i])
                desc_4_axuser_8_reg[i] <= uc2rb_desc_4_axuser_8_reg[i];
             else 
               desc_4_axuser_8_reg[i] <= desc_4_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_9_reg_we[i])
                desc_4_axuser_9_reg[i] <= uc2rb_desc_4_axuser_9_reg[i];
             else 
               desc_4_axuser_9_reg[i] <= desc_4_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_10_reg_we[i])
                desc_4_axuser_10_reg[i] <= uc2rb_desc_4_axuser_10_reg[i];
             else 
               desc_4_axuser_10_reg[i] <= desc_4_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_11_reg_we[i])
                desc_4_axuser_11_reg[i] <= uc2rb_desc_4_axuser_11_reg[i];
             else 
               desc_4_axuser_11_reg[i] <= desc_4_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_12_reg_we[i])
                desc_4_axuser_12_reg[i] <= uc2rb_desc_4_axuser_12_reg[i];
             else 
               desc_4_axuser_12_reg[i] <= desc_4_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_13_reg_we[i])
                desc_4_axuser_13_reg[i] <= uc2rb_desc_4_axuser_13_reg[i];
             else 
               desc_4_axuser_13_reg[i] <= desc_4_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_14_reg_we[i])
                desc_4_axuser_14_reg[i] <= uc2rb_desc_4_axuser_14_reg[i];
             else 
               desc_4_axuser_14_reg[i] <= desc_4_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_axuser_15_reg_we[i])
                desc_4_axuser_15_reg[i] <= uc2rb_desc_4_axuser_15_reg[i];
             else 
               desc_4_axuser_15_reg[i] <= desc_4_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_0_reg_we[i])
                desc_4_wuser_0_reg[i] <= uc2rb_desc_4_wuser_0_reg[i];
             else 
               desc_4_wuser_0_reg[i] <= desc_4_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_1_reg_we[i])
                desc_4_wuser_1_reg[i] <= uc2rb_desc_4_wuser_1_reg[i];
             else 
               desc_4_wuser_1_reg[i] <= desc_4_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_2_reg_we[i])
                desc_4_wuser_2_reg[i] <= uc2rb_desc_4_wuser_2_reg[i];
             else 
               desc_4_wuser_2_reg[i] <= desc_4_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_3_reg_we[i])
                desc_4_wuser_3_reg[i] <= uc2rb_desc_4_wuser_3_reg[i];
             else 
               desc_4_wuser_3_reg[i] <= desc_4_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_4_reg_we[i])
                desc_4_wuser_4_reg[i] <= uc2rb_desc_4_wuser_4_reg[i];
             else 
               desc_4_wuser_4_reg[i] <= desc_4_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_5_reg_we[i])
                desc_4_wuser_5_reg[i] <= uc2rb_desc_4_wuser_5_reg[i];
             else 
               desc_4_wuser_5_reg[i] <= desc_4_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_6_reg_we[i])
                desc_4_wuser_6_reg[i] <= uc2rb_desc_4_wuser_6_reg[i];
             else 
               desc_4_wuser_6_reg[i] <= desc_4_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_7_reg_we[i])
                desc_4_wuser_7_reg[i] <= uc2rb_desc_4_wuser_7_reg[i];
             else 
               desc_4_wuser_7_reg[i] <= desc_4_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_8_reg_we[i])
                desc_4_wuser_8_reg[i] <= uc2rb_desc_4_wuser_8_reg[i];
             else 
               desc_4_wuser_8_reg[i] <= desc_4_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_9_reg_we[i])
                desc_4_wuser_9_reg[i] <= uc2rb_desc_4_wuser_9_reg[i];
             else 
               desc_4_wuser_9_reg[i] <= desc_4_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_10_reg_we[i])
                desc_4_wuser_10_reg[i] <= uc2rb_desc_4_wuser_10_reg[i];
             else 
               desc_4_wuser_10_reg[i] <= desc_4_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_11_reg_we[i])
                desc_4_wuser_11_reg[i] <= uc2rb_desc_4_wuser_11_reg[i];
             else 
               desc_4_wuser_11_reg[i] <= desc_4_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_12_reg_we[i])
                desc_4_wuser_12_reg[i] <= uc2rb_desc_4_wuser_12_reg[i];
             else 
               desc_4_wuser_12_reg[i] <= desc_4_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_13_reg_we[i])
                desc_4_wuser_13_reg[i] <= uc2rb_desc_4_wuser_13_reg[i];
             else 
               desc_4_wuser_13_reg[i] <= desc_4_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_14_reg_we[i])
                desc_4_wuser_14_reg[i] <= uc2rb_desc_4_wuser_14_reg[i];
             else 
               desc_4_wuser_14_reg[i] <= desc_4_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_4_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_4_wuser_15_reg_we[i])
                desc_4_wuser_15_reg[i] <= uc2rb_desc_4_wuser_15_reg[i];
             else 
               desc_4_wuser_15_reg[i] <= desc_4_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_5

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_txn_type_reg_we[i])
                desc_5_txn_type_reg[i] <= uc2rb_desc_5_txn_type_reg[i];
             else 
               desc_5_txn_type_reg[i] <= desc_5_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_size_reg_we[i])
                desc_5_size_reg[i] <= uc2rb_desc_5_size_reg[i];
             else 
               desc_5_size_reg[i] <= desc_5_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_data_offset_reg_we[i])
                desc_5_data_offset_reg[i] <= uc2rb_desc_5_data_offset_reg[i];
             else 
               desc_5_data_offset_reg[i] <= desc_5_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axsize_reg_we[i])
                desc_5_axsize_reg[i] <= uc2rb_desc_5_axsize_reg[i];
             else 
               desc_5_axsize_reg[i] <= desc_5_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_attr_reg_we[i])
                desc_5_attr_reg[i] <= uc2rb_desc_5_attr_reg[i];
             else 
               desc_5_attr_reg[i] <= desc_5_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axaddr_0_reg_we[i])
                desc_5_axaddr_0_reg[i] <= uc2rb_desc_5_axaddr_0_reg[i];
             else 
               desc_5_axaddr_0_reg[i] <= desc_5_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axaddr_1_reg_we[i])
                desc_5_axaddr_1_reg[i] <= uc2rb_desc_5_axaddr_1_reg[i];
             else 
               desc_5_axaddr_1_reg[i] <= desc_5_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axaddr_2_reg_we[i])
                desc_5_axaddr_2_reg[i] <= uc2rb_desc_5_axaddr_2_reg[i];
             else 
               desc_5_axaddr_2_reg[i] <= desc_5_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axaddr_3_reg_we[i])
                desc_5_axaddr_3_reg[i] <= uc2rb_desc_5_axaddr_3_reg[i];
             else 
               desc_5_axaddr_3_reg[i] <= desc_5_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axid_0_reg_we[i])
                desc_5_axid_0_reg[i] <= uc2rb_desc_5_axid_0_reg[i];
             else 
               desc_5_axid_0_reg[i] <= desc_5_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axid_1_reg_we[i])
                desc_5_axid_1_reg[i] <= uc2rb_desc_5_axid_1_reg[i];
             else 
               desc_5_axid_1_reg[i] <= desc_5_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axid_2_reg_we[i])
                desc_5_axid_2_reg[i] <= uc2rb_desc_5_axid_2_reg[i];
             else 
               desc_5_axid_2_reg[i] <= desc_5_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axid_3_reg_we[i])
                desc_5_axid_3_reg[i] <= uc2rb_desc_5_axid_3_reg[i];
             else 
               desc_5_axid_3_reg[i] <= desc_5_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_0_reg_we[i])
                desc_5_axuser_0_reg[i] <= uc2rb_desc_5_axuser_0_reg[i];
             else 
               desc_5_axuser_0_reg[i] <= desc_5_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_1_reg_we[i])
                desc_5_axuser_1_reg[i] <= uc2rb_desc_5_axuser_1_reg[i];
             else 
               desc_5_axuser_1_reg[i] <= desc_5_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_2_reg_we[i])
                desc_5_axuser_2_reg[i] <= uc2rb_desc_5_axuser_2_reg[i];
             else 
               desc_5_axuser_2_reg[i] <= desc_5_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_3_reg_we[i])
                desc_5_axuser_3_reg[i] <= uc2rb_desc_5_axuser_3_reg[i];
             else 
               desc_5_axuser_3_reg[i] <= desc_5_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_4_reg_we[i])
                desc_5_axuser_4_reg[i] <= uc2rb_desc_5_axuser_4_reg[i];
             else 
               desc_5_axuser_4_reg[i] <= desc_5_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_5_reg_we[i])
                desc_5_axuser_5_reg[i] <= uc2rb_desc_5_axuser_5_reg[i];
             else 
               desc_5_axuser_5_reg[i] <= desc_5_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_6_reg_we[i])
                desc_5_axuser_6_reg[i] <= uc2rb_desc_5_axuser_6_reg[i];
             else 
               desc_5_axuser_6_reg[i] <= desc_5_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_7_reg_we[i])
                desc_5_axuser_7_reg[i] <= uc2rb_desc_5_axuser_7_reg[i];
             else 
               desc_5_axuser_7_reg[i] <= desc_5_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_8_reg_we[i])
                desc_5_axuser_8_reg[i] <= uc2rb_desc_5_axuser_8_reg[i];
             else 
               desc_5_axuser_8_reg[i] <= desc_5_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_9_reg_we[i])
                desc_5_axuser_9_reg[i] <= uc2rb_desc_5_axuser_9_reg[i];
             else 
               desc_5_axuser_9_reg[i] <= desc_5_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_10_reg_we[i])
                desc_5_axuser_10_reg[i] <= uc2rb_desc_5_axuser_10_reg[i];
             else 
               desc_5_axuser_10_reg[i] <= desc_5_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_11_reg_we[i])
                desc_5_axuser_11_reg[i] <= uc2rb_desc_5_axuser_11_reg[i];
             else 
               desc_5_axuser_11_reg[i] <= desc_5_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_12_reg_we[i])
                desc_5_axuser_12_reg[i] <= uc2rb_desc_5_axuser_12_reg[i];
             else 
               desc_5_axuser_12_reg[i] <= desc_5_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_13_reg_we[i])
                desc_5_axuser_13_reg[i] <= uc2rb_desc_5_axuser_13_reg[i];
             else 
               desc_5_axuser_13_reg[i] <= desc_5_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_14_reg_we[i])
                desc_5_axuser_14_reg[i] <= uc2rb_desc_5_axuser_14_reg[i];
             else 
               desc_5_axuser_14_reg[i] <= desc_5_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_axuser_15_reg_we[i])
                desc_5_axuser_15_reg[i] <= uc2rb_desc_5_axuser_15_reg[i];
             else 
               desc_5_axuser_15_reg[i] <= desc_5_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_0_reg_we[i])
                desc_5_wuser_0_reg[i] <= uc2rb_desc_5_wuser_0_reg[i];
             else 
               desc_5_wuser_0_reg[i] <= desc_5_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_1_reg_we[i])
                desc_5_wuser_1_reg[i] <= uc2rb_desc_5_wuser_1_reg[i];
             else 
               desc_5_wuser_1_reg[i] <= desc_5_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_2_reg_we[i])
                desc_5_wuser_2_reg[i] <= uc2rb_desc_5_wuser_2_reg[i];
             else 
               desc_5_wuser_2_reg[i] <= desc_5_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_3_reg_we[i])
                desc_5_wuser_3_reg[i] <= uc2rb_desc_5_wuser_3_reg[i];
             else 
               desc_5_wuser_3_reg[i] <= desc_5_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_4_reg_we[i])
                desc_5_wuser_4_reg[i] <= uc2rb_desc_5_wuser_4_reg[i];
             else 
               desc_5_wuser_4_reg[i] <= desc_5_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_5_reg_we[i])
                desc_5_wuser_5_reg[i] <= uc2rb_desc_5_wuser_5_reg[i];
             else 
               desc_5_wuser_5_reg[i] <= desc_5_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_6_reg_we[i])
                desc_5_wuser_6_reg[i] <= uc2rb_desc_5_wuser_6_reg[i];
             else 
               desc_5_wuser_6_reg[i] <= desc_5_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_7_reg_we[i])
                desc_5_wuser_7_reg[i] <= uc2rb_desc_5_wuser_7_reg[i];
             else 
               desc_5_wuser_7_reg[i] <= desc_5_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_8_reg_we[i])
                desc_5_wuser_8_reg[i] <= uc2rb_desc_5_wuser_8_reg[i];
             else 
               desc_5_wuser_8_reg[i] <= desc_5_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_9_reg_we[i])
                desc_5_wuser_9_reg[i] <= uc2rb_desc_5_wuser_9_reg[i];
             else 
               desc_5_wuser_9_reg[i] <= desc_5_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_10_reg_we[i])
                desc_5_wuser_10_reg[i] <= uc2rb_desc_5_wuser_10_reg[i];
             else 
               desc_5_wuser_10_reg[i] <= desc_5_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_11_reg_we[i])
                desc_5_wuser_11_reg[i] <= uc2rb_desc_5_wuser_11_reg[i];
             else 
               desc_5_wuser_11_reg[i] <= desc_5_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_12_reg_we[i])
                desc_5_wuser_12_reg[i] <= uc2rb_desc_5_wuser_12_reg[i];
             else 
               desc_5_wuser_12_reg[i] <= desc_5_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_13_reg_we[i])
                desc_5_wuser_13_reg[i] <= uc2rb_desc_5_wuser_13_reg[i];
             else 
               desc_5_wuser_13_reg[i] <= desc_5_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_14_reg_we[i])
                desc_5_wuser_14_reg[i] <= uc2rb_desc_5_wuser_14_reg[i];
             else 
               desc_5_wuser_14_reg[i] <= desc_5_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_5_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_5_wuser_15_reg_we[i])
                desc_5_wuser_15_reg[i] <= uc2rb_desc_5_wuser_15_reg[i];
             else 
               desc_5_wuser_15_reg[i] <= desc_5_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_6

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_txn_type_reg_we[i])
                desc_6_txn_type_reg[i] <= uc2rb_desc_6_txn_type_reg[i];
             else 
               desc_6_txn_type_reg[i] <= desc_6_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_size_reg_we[i])
                desc_6_size_reg[i] <= uc2rb_desc_6_size_reg[i];
             else 
               desc_6_size_reg[i] <= desc_6_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_data_offset_reg_we[i])
                desc_6_data_offset_reg[i] <= uc2rb_desc_6_data_offset_reg[i];
             else 
               desc_6_data_offset_reg[i] <= desc_6_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axsize_reg_we[i])
                desc_6_axsize_reg[i] <= uc2rb_desc_6_axsize_reg[i];
             else 
               desc_6_axsize_reg[i] <= desc_6_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_attr_reg_we[i])
                desc_6_attr_reg[i] <= uc2rb_desc_6_attr_reg[i];
             else 
               desc_6_attr_reg[i] <= desc_6_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axaddr_0_reg_we[i])
                desc_6_axaddr_0_reg[i] <= uc2rb_desc_6_axaddr_0_reg[i];
             else 
               desc_6_axaddr_0_reg[i] <= desc_6_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axaddr_1_reg_we[i])
                desc_6_axaddr_1_reg[i] <= uc2rb_desc_6_axaddr_1_reg[i];
             else 
               desc_6_axaddr_1_reg[i] <= desc_6_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axaddr_2_reg_we[i])
                desc_6_axaddr_2_reg[i] <= uc2rb_desc_6_axaddr_2_reg[i];
             else 
               desc_6_axaddr_2_reg[i] <= desc_6_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axaddr_3_reg_we[i])
                desc_6_axaddr_3_reg[i] <= uc2rb_desc_6_axaddr_3_reg[i];
             else 
               desc_6_axaddr_3_reg[i] <= desc_6_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axid_0_reg_we[i])
                desc_6_axid_0_reg[i] <= uc2rb_desc_6_axid_0_reg[i];
             else 
               desc_6_axid_0_reg[i] <= desc_6_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axid_1_reg_we[i])
                desc_6_axid_1_reg[i] <= uc2rb_desc_6_axid_1_reg[i];
             else 
               desc_6_axid_1_reg[i] <= desc_6_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axid_2_reg_we[i])
                desc_6_axid_2_reg[i] <= uc2rb_desc_6_axid_2_reg[i];
             else 
               desc_6_axid_2_reg[i] <= desc_6_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axid_3_reg_we[i])
                desc_6_axid_3_reg[i] <= uc2rb_desc_6_axid_3_reg[i];
             else 
               desc_6_axid_3_reg[i] <= desc_6_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_0_reg_we[i])
                desc_6_axuser_0_reg[i] <= uc2rb_desc_6_axuser_0_reg[i];
             else 
               desc_6_axuser_0_reg[i] <= desc_6_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_1_reg_we[i])
                desc_6_axuser_1_reg[i] <= uc2rb_desc_6_axuser_1_reg[i];
             else 
               desc_6_axuser_1_reg[i] <= desc_6_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_2_reg_we[i])
                desc_6_axuser_2_reg[i] <= uc2rb_desc_6_axuser_2_reg[i];
             else 
               desc_6_axuser_2_reg[i] <= desc_6_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_3_reg_we[i])
                desc_6_axuser_3_reg[i] <= uc2rb_desc_6_axuser_3_reg[i];
             else 
               desc_6_axuser_3_reg[i] <= desc_6_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_4_reg_we[i])
                desc_6_axuser_4_reg[i] <= uc2rb_desc_6_axuser_4_reg[i];
             else 
               desc_6_axuser_4_reg[i] <= desc_6_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_5_reg_we[i])
                desc_6_axuser_5_reg[i] <= uc2rb_desc_6_axuser_5_reg[i];
             else 
               desc_6_axuser_5_reg[i] <= desc_6_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_6_reg_we[i])
                desc_6_axuser_6_reg[i] <= uc2rb_desc_6_axuser_6_reg[i];
             else 
               desc_6_axuser_6_reg[i] <= desc_6_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_7_reg_we[i])
                desc_6_axuser_7_reg[i] <= uc2rb_desc_6_axuser_7_reg[i];
             else 
               desc_6_axuser_7_reg[i] <= desc_6_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_8_reg_we[i])
                desc_6_axuser_8_reg[i] <= uc2rb_desc_6_axuser_8_reg[i];
             else 
               desc_6_axuser_8_reg[i] <= desc_6_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_9_reg_we[i])
                desc_6_axuser_9_reg[i] <= uc2rb_desc_6_axuser_9_reg[i];
             else 
               desc_6_axuser_9_reg[i] <= desc_6_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_10_reg_we[i])
                desc_6_axuser_10_reg[i] <= uc2rb_desc_6_axuser_10_reg[i];
             else 
               desc_6_axuser_10_reg[i] <= desc_6_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_11_reg_we[i])
                desc_6_axuser_11_reg[i] <= uc2rb_desc_6_axuser_11_reg[i];
             else 
               desc_6_axuser_11_reg[i] <= desc_6_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_12_reg_we[i])
                desc_6_axuser_12_reg[i] <= uc2rb_desc_6_axuser_12_reg[i];
             else 
               desc_6_axuser_12_reg[i] <= desc_6_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_13_reg_we[i])
                desc_6_axuser_13_reg[i] <= uc2rb_desc_6_axuser_13_reg[i];
             else 
               desc_6_axuser_13_reg[i] <= desc_6_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_14_reg_we[i])
                desc_6_axuser_14_reg[i] <= uc2rb_desc_6_axuser_14_reg[i];
             else 
               desc_6_axuser_14_reg[i] <= desc_6_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_axuser_15_reg_we[i])
                desc_6_axuser_15_reg[i] <= uc2rb_desc_6_axuser_15_reg[i];
             else 
               desc_6_axuser_15_reg[i] <= desc_6_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_0_reg_we[i])
                desc_6_wuser_0_reg[i] <= uc2rb_desc_6_wuser_0_reg[i];
             else 
               desc_6_wuser_0_reg[i] <= desc_6_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_1_reg_we[i])
                desc_6_wuser_1_reg[i] <= uc2rb_desc_6_wuser_1_reg[i];
             else 
               desc_6_wuser_1_reg[i] <= desc_6_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_2_reg_we[i])
                desc_6_wuser_2_reg[i] <= uc2rb_desc_6_wuser_2_reg[i];
             else 
               desc_6_wuser_2_reg[i] <= desc_6_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_3_reg_we[i])
                desc_6_wuser_3_reg[i] <= uc2rb_desc_6_wuser_3_reg[i];
             else 
               desc_6_wuser_3_reg[i] <= desc_6_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_4_reg_we[i])
                desc_6_wuser_4_reg[i] <= uc2rb_desc_6_wuser_4_reg[i];
             else 
               desc_6_wuser_4_reg[i] <= desc_6_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_5_reg_we[i])
                desc_6_wuser_5_reg[i] <= uc2rb_desc_6_wuser_5_reg[i];
             else 
               desc_6_wuser_5_reg[i] <= desc_6_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_6_reg_we[i])
                desc_6_wuser_6_reg[i] <= uc2rb_desc_6_wuser_6_reg[i];
             else 
               desc_6_wuser_6_reg[i] <= desc_6_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_7_reg_we[i])
                desc_6_wuser_7_reg[i] <= uc2rb_desc_6_wuser_7_reg[i];
             else 
               desc_6_wuser_7_reg[i] <= desc_6_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_8_reg_we[i])
                desc_6_wuser_8_reg[i] <= uc2rb_desc_6_wuser_8_reg[i];
             else 
               desc_6_wuser_8_reg[i] <= desc_6_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_9_reg_we[i])
                desc_6_wuser_9_reg[i] <= uc2rb_desc_6_wuser_9_reg[i];
             else 
               desc_6_wuser_9_reg[i] <= desc_6_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_10_reg_we[i])
                desc_6_wuser_10_reg[i] <= uc2rb_desc_6_wuser_10_reg[i];
             else 
               desc_6_wuser_10_reg[i] <= desc_6_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_11_reg_we[i])
                desc_6_wuser_11_reg[i] <= uc2rb_desc_6_wuser_11_reg[i];
             else 
               desc_6_wuser_11_reg[i] <= desc_6_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_12_reg_we[i])
                desc_6_wuser_12_reg[i] <= uc2rb_desc_6_wuser_12_reg[i];
             else 
               desc_6_wuser_12_reg[i] <= desc_6_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_13_reg_we[i])
                desc_6_wuser_13_reg[i] <= uc2rb_desc_6_wuser_13_reg[i];
             else 
               desc_6_wuser_13_reg[i] <= desc_6_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_14_reg_we[i])
                desc_6_wuser_14_reg[i] <= uc2rb_desc_6_wuser_14_reg[i];
             else 
               desc_6_wuser_14_reg[i] <= desc_6_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_6_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_6_wuser_15_reg_we[i])
                desc_6_wuser_15_reg[i] <= uc2rb_desc_6_wuser_15_reg[i];
             else 
               desc_6_wuser_15_reg[i] <= desc_6_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_7

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_txn_type_reg_we[i])
                desc_7_txn_type_reg[i] <= uc2rb_desc_7_txn_type_reg[i];
             else 
               desc_7_txn_type_reg[i] <= desc_7_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_size_reg_we[i])
                desc_7_size_reg[i] <= uc2rb_desc_7_size_reg[i];
             else 
               desc_7_size_reg[i] <= desc_7_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_data_offset_reg_we[i])
                desc_7_data_offset_reg[i] <= uc2rb_desc_7_data_offset_reg[i];
             else 
               desc_7_data_offset_reg[i] <= desc_7_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axsize_reg_we[i])
                desc_7_axsize_reg[i] <= uc2rb_desc_7_axsize_reg[i];
             else 
               desc_7_axsize_reg[i] <= desc_7_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_attr_reg_we[i])
                desc_7_attr_reg[i] <= uc2rb_desc_7_attr_reg[i];
             else 
               desc_7_attr_reg[i] <= desc_7_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axaddr_0_reg_we[i])
                desc_7_axaddr_0_reg[i] <= uc2rb_desc_7_axaddr_0_reg[i];
             else 
               desc_7_axaddr_0_reg[i] <= desc_7_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axaddr_1_reg_we[i])
                desc_7_axaddr_1_reg[i] <= uc2rb_desc_7_axaddr_1_reg[i];
             else 
               desc_7_axaddr_1_reg[i] <= desc_7_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axaddr_2_reg_we[i])
                desc_7_axaddr_2_reg[i] <= uc2rb_desc_7_axaddr_2_reg[i];
             else 
               desc_7_axaddr_2_reg[i] <= desc_7_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axaddr_3_reg_we[i])
                desc_7_axaddr_3_reg[i] <= uc2rb_desc_7_axaddr_3_reg[i];
             else 
               desc_7_axaddr_3_reg[i] <= desc_7_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axid_0_reg_we[i])
                desc_7_axid_0_reg[i] <= uc2rb_desc_7_axid_0_reg[i];
             else 
               desc_7_axid_0_reg[i] <= desc_7_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axid_1_reg_we[i])
                desc_7_axid_1_reg[i] <= uc2rb_desc_7_axid_1_reg[i];
             else 
               desc_7_axid_1_reg[i] <= desc_7_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axid_2_reg_we[i])
                desc_7_axid_2_reg[i] <= uc2rb_desc_7_axid_2_reg[i];
             else 
               desc_7_axid_2_reg[i] <= desc_7_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axid_3_reg_we[i])
                desc_7_axid_3_reg[i] <= uc2rb_desc_7_axid_3_reg[i];
             else 
               desc_7_axid_3_reg[i] <= desc_7_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_0_reg_we[i])
                desc_7_axuser_0_reg[i] <= uc2rb_desc_7_axuser_0_reg[i];
             else 
               desc_7_axuser_0_reg[i] <= desc_7_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_1_reg_we[i])
                desc_7_axuser_1_reg[i] <= uc2rb_desc_7_axuser_1_reg[i];
             else 
               desc_7_axuser_1_reg[i] <= desc_7_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_2_reg_we[i])
                desc_7_axuser_2_reg[i] <= uc2rb_desc_7_axuser_2_reg[i];
             else 
               desc_7_axuser_2_reg[i] <= desc_7_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_3_reg_we[i])
                desc_7_axuser_3_reg[i] <= uc2rb_desc_7_axuser_3_reg[i];
             else 
               desc_7_axuser_3_reg[i] <= desc_7_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_4_reg_we[i])
                desc_7_axuser_4_reg[i] <= uc2rb_desc_7_axuser_4_reg[i];
             else 
               desc_7_axuser_4_reg[i] <= desc_7_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_5_reg_we[i])
                desc_7_axuser_5_reg[i] <= uc2rb_desc_7_axuser_5_reg[i];
             else 
               desc_7_axuser_5_reg[i] <= desc_7_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_6_reg_we[i])
                desc_7_axuser_6_reg[i] <= uc2rb_desc_7_axuser_6_reg[i];
             else 
               desc_7_axuser_6_reg[i] <= desc_7_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_7_reg_we[i])
                desc_7_axuser_7_reg[i] <= uc2rb_desc_7_axuser_7_reg[i];
             else 
               desc_7_axuser_7_reg[i] <= desc_7_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_8_reg_we[i])
                desc_7_axuser_8_reg[i] <= uc2rb_desc_7_axuser_8_reg[i];
             else 
               desc_7_axuser_8_reg[i] <= desc_7_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_9_reg_we[i])
                desc_7_axuser_9_reg[i] <= uc2rb_desc_7_axuser_9_reg[i];
             else 
               desc_7_axuser_9_reg[i] <= desc_7_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_10_reg_we[i])
                desc_7_axuser_10_reg[i] <= uc2rb_desc_7_axuser_10_reg[i];
             else 
               desc_7_axuser_10_reg[i] <= desc_7_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_11_reg_we[i])
                desc_7_axuser_11_reg[i] <= uc2rb_desc_7_axuser_11_reg[i];
             else 
               desc_7_axuser_11_reg[i] <= desc_7_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_12_reg_we[i])
                desc_7_axuser_12_reg[i] <= uc2rb_desc_7_axuser_12_reg[i];
             else 
               desc_7_axuser_12_reg[i] <= desc_7_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_13_reg_we[i])
                desc_7_axuser_13_reg[i] <= uc2rb_desc_7_axuser_13_reg[i];
             else 
               desc_7_axuser_13_reg[i] <= desc_7_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_14_reg_we[i])
                desc_7_axuser_14_reg[i] <= uc2rb_desc_7_axuser_14_reg[i];
             else 
               desc_7_axuser_14_reg[i] <= desc_7_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_axuser_15_reg_we[i])
                desc_7_axuser_15_reg[i] <= uc2rb_desc_7_axuser_15_reg[i];
             else 
               desc_7_axuser_15_reg[i] <= desc_7_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_0_reg_we[i])
                desc_7_wuser_0_reg[i] <= uc2rb_desc_7_wuser_0_reg[i];
             else 
               desc_7_wuser_0_reg[i] <= desc_7_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_1_reg_we[i])
                desc_7_wuser_1_reg[i] <= uc2rb_desc_7_wuser_1_reg[i];
             else 
               desc_7_wuser_1_reg[i] <= desc_7_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_2_reg_we[i])
                desc_7_wuser_2_reg[i] <= uc2rb_desc_7_wuser_2_reg[i];
             else 
               desc_7_wuser_2_reg[i] <= desc_7_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_3_reg_we[i])
                desc_7_wuser_3_reg[i] <= uc2rb_desc_7_wuser_3_reg[i];
             else 
               desc_7_wuser_3_reg[i] <= desc_7_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_4_reg_we[i])
                desc_7_wuser_4_reg[i] <= uc2rb_desc_7_wuser_4_reg[i];
             else 
               desc_7_wuser_4_reg[i] <= desc_7_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_5_reg_we[i])
                desc_7_wuser_5_reg[i] <= uc2rb_desc_7_wuser_5_reg[i];
             else 
               desc_7_wuser_5_reg[i] <= desc_7_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_6_reg_we[i])
                desc_7_wuser_6_reg[i] <= uc2rb_desc_7_wuser_6_reg[i];
             else 
               desc_7_wuser_6_reg[i] <= desc_7_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_7_reg_we[i])
                desc_7_wuser_7_reg[i] <= uc2rb_desc_7_wuser_7_reg[i];
             else 
               desc_7_wuser_7_reg[i] <= desc_7_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_8_reg_we[i])
                desc_7_wuser_8_reg[i] <= uc2rb_desc_7_wuser_8_reg[i];
             else 
               desc_7_wuser_8_reg[i] <= desc_7_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_9_reg_we[i])
                desc_7_wuser_9_reg[i] <= uc2rb_desc_7_wuser_9_reg[i];
             else 
               desc_7_wuser_9_reg[i] <= desc_7_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_10_reg_we[i])
                desc_7_wuser_10_reg[i] <= uc2rb_desc_7_wuser_10_reg[i];
             else 
               desc_7_wuser_10_reg[i] <= desc_7_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_11_reg_we[i])
                desc_7_wuser_11_reg[i] <= uc2rb_desc_7_wuser_11_reg[i];
             else 
               desc_7_wuser_11_reg[i] <= desc_7_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_12_reg_we[i])
                desc_7_wuser_12_reg[i] <= uc2rb_desc_7_wuser_12_reg[i];
             else 
               desc_7_wuser_12_reg[i] <= desc_7_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_13_reg_we[i])
                desc_7_wuser_13_reg[i] <= uc2rb_desc_7_wuser_13_reg[i];
             else 
               desc_7_wuser_13_reg[i] <= desc_7_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_14_reg_we[i])
                desc_7_wuser_14_reg[i] <= uc2rb_desc_7_wuser_14_reg[i];
             else 
               desc_7_wuser_14_reg[i] <= desc_7_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_7_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_7_wuser_15_reg_we[i])
                desc_7_wuser_15_reg[i] <= uc2rb_desc_7_wuser_15_reg[i];
             else 
               desc_7_wuser_15_reg[i] <= desc_7_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_8

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_txn_type_reg_we[i])
                desc_8_txn_type_reg[i] <= uc2rb_desc_8_txn_type_reg[i];
             else 
               desc_8_txn_type_reg[i] <= desc_8_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_size_reg_we[i])
                desc_8_size_reg[i] <= uc2rb_desc_8_size_reg[i];
             else 
               desc_8_size_reg[i] <= desc_8_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_data_offset_reg_we[i])
                desc_8_data_offset_reg[i] <= uc2rb_desc_8_data_offset_reg[i];
             else 
               desc_8_data_offset_reg[i] <= desc_8_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axsize_reg_we[i])
                desc_8_axsize_reg[i] <= uc2rb_desc_8_axsize_reg[i];
             else 
               desc_8_axsize_reg[i] <= desc_8_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_attr_reg_we[i])
                desc_8_attr_reg[i] <= uc2rb_desc_8_attr_reg[i];
             else 
               desc_8_attr_reg[i] <= desc_8_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axaddr_0_reg_we[i])
                desc_8_axaddr_0_reg[i] <= uc2rb_desc_8_axaddr_0_reg[i];
             else 
               desc_8_axaddr_0_reg[i] <= desc_8_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axaddr_1_reg_we[i])
                desc_8_axaddr_1_reg[i] <= uc2rb_desc_8_axaddr_1_reg[i];
             else 
               desc_8_axaddr_1_reg[i] <= desc_8_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axaddr_2_reg_we[i])
                desc_8_axaddr_2_reg[i] <= uc2rb_desc_8_axaddr_2_reg[i];
             else 
               desc_8_axaddr_2_reg[i] <= desc_8_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axaddr_3_reg_we[i])
                desc_8_axaddr_3_reg[i] <= uc2rb_desc_8_axaddr_3_reg[i];
             else 
               desc_8_axaddr_3_reg[i] <= desc_8_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axid_0_reg_we[i])
                desc_8_axid_0_reg[i] <= uc2rb_desc_8_axid_0_reg[i];
             else 
               desc_8_axid_0_reg[i] <= desc_8_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axid_1_reg_we[i])
                desc_8_axid_1_reg[i] <= uc2rb_desc_8_axid_1_reg[i];
             else 
               desc_8_axid_1_reg[i] <= desc_8_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axid_2_reg_we[i])
                desc_8_axid_2_reg[i] <= uc2rb_desc_8_axid_2_reg[i];
             else 
               desc_8_axid_2_reg[i] <= desc_8_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axid_3_reg_we[i])
                desc_8_axid_3_reg[i] <= uc2rb_desc_8_axid_3_reg[i];
             else 
               desc_8_axid_3_reg[i] <= desc_8_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_0_reg_we[i])
                desc_8_axuser_0_reg[i] <= uc2rb_desc_8_axuser_0_reg[i];
             else 
               desc_8_axuser_0_reg[i] <= desc_8_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_1_reg_we[i])
                desc_8_axuser_1_reg[i] <= uc2rb_desc_8_axuser_1_reg[i];
             else 
               desc_8_axuser_1_reg[i] <= desc_8_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_2_reg_we[i])
                desc_8_axuser_2_reg[i] <= uc2rb_desc_8_axuser_2_reg[i];
             else 
               desc_8_axuser_2_reg[i] <= desc_8_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_3_reg_we[i])
                desc_8_axuser_3_reg[i] <= uc2rb_desc_8_axuser_3_reg[i];
             else 
               desc_8_axuser_3_reg[i] <= desc_8_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_4_reg_we[i])
                desc_8_axuser_4_reg[i] <= uc2rb_desc_8_axuser_4_reg[i];
             else 
               desc_8_axuser_4_reg[i] <= desc_8_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_5_reg_we[i])
                desc_8_axuser_5_reg[i] <= uc2rb_desc_8_axuser_5_reg[i];
             else 
               desc_8_axuser_5_reg[i] <= desc_8_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_6_reg_we[i])
                desc_8_axuser_6_reg[i] <= uc2rb_desc_8_axuser_6_reg[i];
             else 
               desc_8_axuser_6_reg[i] <= desc_8_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_7_reg_we[i])
                desc_8_axuser_7_reg[i] <= uc2rb_desc_8_axuser_7_reg[i];
             else 
               desc_8_axuser_7_reg[i] <= desc_8_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_8_reg_we[i])
                desc_8_axuser_8_reg[i] <= uc2rb_desc_8_axuser_8_reg[i];
             else 
               desc_8_axuser_8_reg[i] <= desc_8_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_9_reg_we[i])
                desc_8_axuser_9_reg[i] <= uc2rb_desc_8_axuser_9_reg[i];
             else 
               desc_8_axuser_9_reg[i] <= desc_8_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_10_reg_we[i])
                desc_8_axuser_10_reg[i] <= uc2rb_desc_8_axuser_10_reg[i];
             else 
               desc_8_axuser_10_reg[i] <= desc_8_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_11_reg_we[i])
                desc_8_axuser_11_reg[i] <= uc2rb_desc_8_axuser_11_reg[i];
             else 
               desc_8_axuser_11_reg[i] <= desc_8_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_12_reg_we[i])
                desc_8_axuser_12_reg[i] <= uc2rb_desc_8_axuser_12_reg[i];
             else 
               desc_8_axuser_12_reg[i] <= desc_8_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_13_reg_we[i])
                desc_8_axuser_13_reg[i] <= uc2rb_desc_8_axuser_13_reg[i];
             else 
               desc_8_axuser_13_reg[i] <= desc_8_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_14_reg_we[i])
                desc_8_axuser_14_reg[i] <= uc2rb_desc_8_axuser_14_reg[i];
             else 
               desc_8_axuser_14_reg[i] <= desc_8_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_axuser_15_reg_we[i])
                desc_8_axuser_15_reg[i] <= uc2rb_desc_8_axuser_15_reg[i];
             else 
               desc_8_axuser_15_reg[i] <= desc_8_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_0_reg_we[i])
                desc_8_wuser_0_reg[i] <= uc2rb_desc_8_wuser_0_reg[i];
             else 
               desc_8_wuser_0_reg[i] <= desc_8_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_1_reg_we[i])
                desc_8_wuser_1_reg[i] <= uc2rb_desc_8_wuser_1_reg[i];
             else 
               desc_8_wuser_1_reg[i] <= desc_8_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_2_reg_we[i])
                desc_8_wuser_2_reg[i] <= uc2rb_desc_8_wuser_2_reg[i];
             else 
               desc_8_wuser_2_reg[i] <= desc_8_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_3_reg_we[i])
                desc_8_wuser_3_reg[i] <= uc2rb_desc_8_wuser_3_reg[i];
             else 
               desc_8_wuser_3_reg[i] <= desc_8_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_4_reg_we[i])
                desc_8_wuser_4_reg[i] <= uc2rb_desc_8_wuser_4_reg[i];
             else 
               desc_8_wuser_4_reg[i] <= desc_8_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_5_reg_we[i])
                desc_8_wuser_5_reg[i] <= uc2rb_desc_8_wuser_5_reg[i];
             else 
               desc_8_wuser_5_reg[i] <= desc_8_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_6_reg_we[i])
                desc_8_wuser_6_reg[i] <= uc2rb_desc_8_wuser_6_reg[i];
             else 
               desc_8_wuser_6_reg[i] <= desc_8_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_7_reg_we[i])
                desc_8_wuser_7_reg[i] <= uc2rb_desc_8_wuser_7_reg[i];
             else 
               desc_8_wuser_7_reg[i] <= desc_8_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_8_reg_we[i])
                desc_8_wuser_8_reg[i] <= uc2rb_desc_8_wuser_8_reg[i];
             else 
               desc_8_wuser_8_reg[i] <= desc_8_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_9_reg_we[i])
                desc_8_wuser_9_reg[i] <= uc2rb_desc_8_wuser_9_reg[i];
             else 
               desc_8_wuser_9_reg[i] <= desc_8_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_10_reg_we[i])
                desc_8_wuser_10_reg[i] <= uc2rb_desc_8_wuser_10_reg[i];
             else 
               desc_8_wuser_10_reg[i] <= desc_8_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_11_reg_we[i])
                desc_8_wuser_11_reg[i] <= uc2rb_desc_8_wuser_11_reg[i];
             else 
               desc_8_wuser_11_reg[i] <= desc_8_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_12_reg_we[i])
                desc_8_wuser_12_reg[i] <= uc2rb_desc_8_wuser_12_reg[i];
             else 
               desc_8_wuser_12_reg[i] <= desc_8_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_13_reg_we[i])
                desc_8_wuser_13_reg[i] <= uc2rb_desc_8_wuser_13_reg[i];
             else 
               desc_8_wuser_13_reg[i] <= desc_8_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_14_reg_we[i])
                desc_8_wuser_14_reg[i] <= uc2rb_desc_8_wuser_14_reg[i];
             else 
               desc_8_wuser_14_reg[i] <= desc_8_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_8_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_8_wuser_15_reg_we[i])
                desc_8_wuser_15_reg[i] <= uc2rb_desc_8_wuser_15_reg[i];
             else 
               desc_8_wuser_15_reg[i] <= desc_8_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_9

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_txn_type_reg_we[i])
                desc_9_txn_type_reg[i] <= uc2rb_desc_9_txn_type_reg[i];
             else 
               desc_9_txn_type_reg[i] <= desc_9_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_size_reg_we[i])
                desc_9_size_reg[i] <= uc2rb_desc_9_size_reg[i];
             else 
               desc_9_size_reg[i] <= desc_9_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_data_offset_reg_we[i])
                desc_9_data_offset_reg[i] <= uc2rb_desc_9_data_offset_reg[i];
             else 
               desc_9_data_offset_reg[i] <= desc_9_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axsize_reg_we[i])
                desc_9_axsize_reg[i] <= uc2rb_desc_9_axsize_reg[i];
             else 
               desc_9_axsize_reg[i] <= desc_9_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_attr_reg_we[i])
                desc_9_attr_reg[i] <= uc2rb_desc_9_attr_reg[i];
             else 
               desc_9_attr_reg[i] <= desc_9_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axaddr_0_reg_we[i])
                desc_9_axaddr_0_reg[i] <= uc2rb_desc_9_axaddr_0_reg[i];
             else 
               desc_9_axaddr_0_reg[i] <= desc_9_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axaddr_1_reg_we[i])
                desc_9_axaddr_1_reg[i] <= uc2rb_desc_9_axaddr_1_reg[i];
             else 
               desc_9_axaddr_1_reg[i] <= desc_9_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axaddr_2_reg_we[i])
                desc_9_axaddr_2_reg[i] <= uc2rb_desc_9_axaddr_2_reg[i];
             else 
               desc_9_axaddr_2_reg[i] <= desc_9_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axaddr_3_reg_we[i])
                desc_9_axaddr_3_reg[i] <= uc2rb_desc_9_axaddr_3_reg[i];
             else 
               desc_9_axaddr_3_reg[i] <= desc_9_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axid_0_reg_we[i])
                desc_9_axid_0_reg[i] <= uc2rb_desc_9_axid_0_reg[i];
             else 
               desc_9_axid_0_reg[i] <= desc_9_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axid_1_reg_we[i])
                desc_9_axid_1_reg[i] <= uc2rb_desc_9_axid_1_reg[i];
             else 
               desc_9_axid_1_reg[i] <= desc_9_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axid_2_reg_we[i])
                desc_9_axid_2_reg[i] <= uc2rb_desc_9_axid_2_reg[i];
             else 
               desc_9_axid_2_reg[i] <= desc_9_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axid_3_reg_we[i])
                desc_9_axid_3_reg[i] <= uc2rb_desc_9_axid_3_reg[i];
             else 
               desc_9_axid_3_reg[i] <= desc_9_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_0_reg_we[i])
                desc_9_axuser_0_reg[i] <= uc2rb_desc_9_axuser_0_reg[i];
             else 
               desc_9_axuser_0_reg[i] <= desc_9_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_1_reg_we[i])
                desc_9_axuser_1_reg[i] <= uc2rb_desc_9_axuser_1_reg[i];
             else 
               desc_9_axuser_1_reg[i] <= desc_9_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_2_reg_we[i])
                desc_9_axuser_2_reg[i] <= uc2rb_desc_9_axuser_2_reg[i];
             else 
               desc_9_axuser_2_reg[i] <= desc_9_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_3_reg_we[i])
                desc_9_axuser_3_reg[i] <= uc2rb_desc_9_axuser_3_reg[i];
             else 
               desc_9_axuser_3_reg[i] <= desc_9_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_4_reg_we[i])
                desc_9_axuser_4_reg[i] <= uc2rb_desc_9_axuser_4_reg[i];
             else 
               desc_9_axuser_4_reg[i] <= desc_9_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_5_reg_we[i])
                desc_9_axuser_5_reg[i] <= uc2rb_desc_9_axuser_5_reg[i];
             else 
               desc_9_axuser_5_reg[i] <= desc_9_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_6_reg_we[i])
                desc_9_axuser_6_reg[i] <= uc2rb_desc_9_axuser_6_reg[i];
             else 
               desc_9_axuser_6_reg[i] <= desc_9_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_7_reg_we[i])
                desc_9_axuser_7_reg[i] <= uc2rb_desc_9_axuser_7_reg[i];
             else 
               desc_9_axuser_7_reg[i] <= desc_9_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_8_reg_we[i])
                desc_9_axuser_8_reg[i] <= uc2rb_desc_9_axuser_8_reg[i];
             else 
               desc_9_axuser_8_reg[i] <= desc_9_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_9_reg_we[i])
                desc_9_axuser_9_reg[i] <= uc2rb_desc_9_axuser_9_reg[i];
             else 
               desc_9_axuser_9_reg[i] <= desc_9_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_10_reg_we[i])
                desc_9_axuser_10_reg[i] <= uc2rb_desc_9_axuser_10_reg[i];
             else 
               desc_9_axuser_10_reg[i] <= desc_9_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_11_reg_we[i])
                desc_9_axuser_11_reg[i] <= uc2rb_desc_9_axuser_11_reg[i];
             else 
               desc_9_axuser_11_reg[i] <= desc_9_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_12_reg_we[i])
                desc_9_axuser_12_reg[i] <= uc2rb_desc_9_axuser_12_reg[i];
             else 
               desc_9_axuser_12_reg[i] <= desc_9_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_13_reg_we[i])
                desc_9_axuser_13_reg[i] <= uc2rb_desc_9_axuser_13_reg[i];
             else 
               desc_9_axuser_13_reg[i] <= desc_9_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_14_reg_we[i])
                desc_9_axuser_14_reg[i] <= uc2rb_desc_9_axuser_14_reg[i];
             else 
               desc_9_axuser_14_reg[i] <= desc_9_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_axuser_15_reg_we[i])
                desc_9_axuser_15_reg[i] <= uc2rb_desc_9_axuser_15_reg[i];
             else 
               desc_9_axuser_15_reg[i] <= desc_9_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_0_reg_we[i])
                desc_9_wuser_0_reg[i] <= uc2rb_desc_9_wuser_0_reg[i];
             else 
               desc_9_wuser_0_reg[i] <= desc_9_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_1_reg_we[i])
                desc_9_wuser_1_reg[i] <= uc2rb_desc_9_wuser_1_reg[i];
             else 
               desc_9_wuser_1_reg[i] <= desc_9_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_2_reg_we[i])
                desc_9_wuser_2_reg[i] <= uc2rb_desc_9_wuser_2_reg[i];
             else 
               desc_9_wuser_2_reg[i] <= desc_9_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_3_reg_we[i])
                desc_9_wuser_3_reg[i] <= uc2rb_desc_9_wuser_3_reg[i];
             else 
               desc_9_wuser_3_reg[i] <= desc_9_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_4_reg_we[i])
                desc_9_wuser_4_reg[i] <= uc2rb_desc_9_wuser_4_reg[i];
             else 
               desc_9_wuser_4_reg[i] <= desc_9_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_5_reg_we[i])
                desc_9_wuser_5_reg[i] <= uc2rb_desc_9_wuser_5_reg[i];
             else 
               desc_9_wuser_5_reg[i] <= desc_9_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_6_reg_we[i])
                desc_9_wuser_6_reg[i] <= uc2rb_desc_9_wuser_6_reg[i];
             else 
               desc_9_wuser_6_reg[i] <= desc_9_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_7_reg_we[i])
                desc_9_wuser_7_reg[i] <= uc2rb_desc_9_wuser_7_reg[i];
             else 
               desc_9_wuser_7_reg[i] <= desc_9_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_8_reg_we[i])
                desc_9_wuser_8_reg[i] <= uc2rb_desc_9_wuser_8_reg[i];
             else 
               desc_9_wuser_8_reg[i] <= desc_9_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_9_reg_we[i])
                desc_9_wuser_9_reg[i] <= uc2rb_desc_9_wuser_9_reg[i];
             else 
               desc_9_wuser_9_reg[i] <= desc_9_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_10_reg_we[i])
                desc_9_wuser_10_reg[i] <= uc2rb_desc_9_wuser_10_reg[i];
             else 
               desc_9_wuser_10_reg[i] <= desc_9_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_11_reg_we[i])
                desc_9_wuser_11_reg[i] <= uc2rb_desc_9_wuser_11_reg[i];
             else 
               desc_9_wuser_11_reg[i] <= desc_9_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_12_reg_we[i])
                desc_9_wuser_12_reg[i] <= uc2rb_desc_9_wuser_12_reg[i];
             else 
               desc_9_wuser_12_reg[i] <= desc_9_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_13_reg_we[i])
                desc_9_wuser_13_reg[i] <= uc2rb_desc_9_wuser_13_reg[i];
             else 
               desc_9_wuser_13_reg[i] <= desc_9_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_14_reg_we[i])
                desc_9_wuser_14_reg[i] <= uc2rb_desc_9_wuser_14_reg[i];
             else 
               desc_9_wuser_14_reg[i] <= desc_9_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_9_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_9_wuser_15_reg_we[i])
                desc_9_wuser_15_reg[i] <= uc2rb_desc_9_wuser_15_reg[i];
             else 
               desc_9_wuser_15_reg[i] <= desc_9_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_10

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_txn_type_reg_we[i])
                desc_10_txn_type_reg[i] <= uc2rb_desc_10_txn_type_reg[i];
             else 
               desc_10_txn_type_reg[i] <= desc_10_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_size_reg_we[i])
                desc_10_size_reg[i] <= uc2rb_desc_10_size_reg[i];
             else 
               desc_10_size_reg[i] <= desc_10_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_data_offset_reg_we[i])
                desc_10_data_offset_reg[i] <= uc2rb_desc_10_data_offset_reg[i];
             else 
               desc_10_data_offset_reg[i] <= desc_10_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axsize_reg_we[i])
                desc_10_axsize_reg[i] <= uc2rb_desc_10_axsize_reg[i];
             else 
               desc_10_axsize_reg[i] <= desc_10_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_attr_reg_we[i])
                desc_10_attr_reg[i] <= uc2rb_desc_10_attr_reg[i];
             else 
               desc_10_attr_reg[i] <= desc_10_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axaddr_0_reg_we[i])
                desc_10_axaddr_0_reg[i] <= uc2rb_desc_10_axaddr_0_reg[i];
             else 
               desc_10_axaddr_0_reg[i] <= desc_10_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axaddr_1_reg_we[i])
                desc_10_axaddr_1_reg[i] <= uc2rb_desc_10_axaddr_1_reg[i];
             else 
               desc_10_axaddr_1_reg[i] <= desc_10_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axaddr_2_reg_we[i])
                desc_10_axaddr_2_reg[i] <= uc2rb_desc_10_axaddr_2_reg[i];
             else 
               desc_10_axaddr_2_reg[i] <= desc_10_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axaddr_3_reg_we[i])
                desc_10_axaddr_3_reg[i] <= uc2rb_desc_10_axaddr_3_reg[i];
             else 
               desc_10_axaddr_3_reg[i] <= desc_10_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axid_0_reg_we[i])
                desc_10_axid_0_reg[i] <= uc2rb_desc_10_axid_0_reg[i];
             else 
               desc_10_axid_0_reg[i] <= desc_10_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axid_1_reg_we[i])
                desc_10_axid_1_reg[i] <= uc2rb_desc_10_axid_1_reg[i];
             else 
               desc_10_axid_1_reg[i] <= desc_10_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axid_2_reg_we[i])
                desc_10_axid_2_reg[i] <= uc2rb_desc_10_axid_2_reg[i];
             else 
               desc_10_axid_2_reg[i] <= desc_10_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axid_3_reg_we[i])
                desc_10_axid_3_reg[i] <= uc2rb_desc_10_axid_3_reg[i];
             else 
               desc_10_axid_3_reg[i] <= desc_10_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_0_reg_we[i])
                desc_10_axuser_0_reg[i] <= uc2rb_desc_10_axuser_0_reg[i];
             else 
               desc_10_axuser_0_reg[i] <= desc_10_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_1_reg_we[i])
                desc_10_axuser_1_reg[i] <= uc2rb_desc_10_axuser_1_reg[i];
             else 
               desc_10_axuser_1_reg[i] <= desc_10_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_2_reg_we[i])
                desc_10_axuser_2_reg[i] <= uc2rb_desc_10_axuser_2_reg[i];
             else 
               desc_10_axuser_2_reg[i] <= desc_10_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_3_reg_we[i])
                desc_10_axuser_3_reg[i] <= uc2rb_desc_10_axuser_3_reg[i];
             else 
               desc_10_axuser_3_reg[i] <= desc_10_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_4_reg_we[i])
                desc_10_axuser_4_reg[i] <= uc2rb_desc_10_axuser_4_reg[i];
             else 
               desc_10_axuser_4_reg[i] <= desc_10_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_5_reg_we[i])
                desc_10_axuser_5_reg[i] <= uc2rb_desc_10_axuser_5_reg[i];
             else 
               desc_10_axuser_5_reg[i] <= desc_10_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_6_reg_we[i])
                desc_10_axuser_6_reg[i] <= uc2rb_desc_10_axuser_6_reg[i];
             else 
               desc_10_axuser_6_reg[i] <= desc_10_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_7_reg_we[i])
                desc_10_axuser_7_reg[i] <= uc2rb_desc_10_axuser_7_reg[i];
             else 
               desc_10_axuser_7_reg[i] <= desc_10_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_8_reg_we[i])
                desc_10_axuser_8_reg[i] <= uc2rb_desc_10_axuser_8_reg[i];
             else 
               desc_10_axuser_8_reg[i] <= desc_10_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_9_reg_we[i])
                desc_10_axuser_9_reg[i] <= uc2rb_desc_10_axuser_9_reg[i];
             else 
               desc_10_axuser_9_reg[i] <= desc_10_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_10_reg_we[i])
                desc_10_axuser_10_reg[i] <= uc2rb_desc_10_axuser_10_reg[i];
             else 
               desc_10_axuser_10_reg[i] <= desc_10_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_11_reg_we[i])
                desc_10_axuser_11_reg[i] <= uc2rb_desc_10_axuser_11_reg[i];
             else 
               desc_10_axuser_11_reg[i] <= desc_10_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_12_reg_we[i])
                desc_10_axuser_12_reg[i] <= uc2rb_desc_10_axuser_12_reg[i];
             else 
               desc_10_axuser_12_reg[i] <= desc_10_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_13_reg_we[i])
                desc_10_axuser_13_reg[i] <= uc2rb_desc_10_axuser_13_reg[i];
             else 
               desc_10_axuser_13_reg[i] <= desc_10_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_14_reg_we[i])
                desc_10_axuser_14_reg[i] <= uc2rb_desc_10_axuser_14_reg[i];
             else 
               desc_10_axuser_14_reg[i] <= desc_10_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_axuser_15_reg_we[i])
                desc_10_axuser_15_reg[i] <= uc2rb_desc_10_axuser_15_reg[i];
             else 
               desc_10_axuser_15_reg[i] <= desc_10_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_0_reg_we[i])
                desc_10_wuser_0_reg[i] <= uc2rb_desc_10_wuser_0_reg[i];
             else 
               desc_10_wuser_0_reg[i] <= desc_10_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_1_reg_we[i])
                desc_10_wuser_1_reg[i] <= uc2rb_desc_10_wuser_1_reg[i];
             else 
               desc_10_wuser_1_reg[i] <= desc_10_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_2_reg_we[i])
                desc_10_wuser_2_reg[i] <= uc2rb_desc_10_wuser_2_reg[i];
             else 
               desc_10_wuser_2_reg[i] <= desc_10_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_3_reg_we[i])
                desc_10_wuser_3_reg[i] <= uc2rb_desc_10_wuser_3_reg[i];
             else 
               desc_10_wuser_3_reg[i] <= desc_10_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_4_reg_we[i])
                desc_10_wuser_4_reg[i] <= uc2rb_desc_10_wuser_4_reg[i];
             else 
               desc_10_wuser_4_reg[i] <= desc_10_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_5_reg_we[i])
                desc_10_wuser_5_reg[i] <= uc2rb_desc_10_wuser_5_reg[i];
             else 
               desc_10_wuser_5_reg[i] <= desc_10_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_6_reg_we[i])
                desc_10_wuser_6_reg[i] <= uc2rb_desc_10_wuser_6_reg[i];
             else 
               desc_10_wuser_6_reg[i] <= desc_10_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_7_reg_we[i])
                desc_10_wuser_7_reg[i] <= uc2rb_desc_10_wuser_7_reg[i];
             else 
               desc_10_wuser_7_reg[i] <= desc_10_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_8_reg_we[i])
                desc_10_wuser_8_reg[i] <= uc2rb_desc_10_wuser_8_reg[i];
             else 
               desc_10_wuser_8_reg[i] <= desc_10_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_9_reg_we[i])
                desc_10_wuser_9_reg[i] <= uc2rb_desc_10_wuser_9_reg[i];
             else 
               desc_10_wuser_9_reg[i] <= desc_10_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_10_reg_we[i])
                desc_10_wuser_10_reg[i] <= uc2rb_desc_10_wuser_10_reg[i];
             else 
               desc_10_wuser_10_reg[i] <= desc_10_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_11_reg_we[i])
                desc_10_wuser_11_reg[i] <= uc2rb_desc_10_wuser_11_reg[i];
             else 
               desc_10_wuser_11_reg[i] <= desc_10_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_12_reg_we[i])
                desc_10_wuser_12_reg[i] <= uc2rb_desc_10_wuser_12_reg[i];
             else 
               desc_10_wuser_12_reg[i] <= desc_10_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_13_reg_we[i])
                desc_10_wuser_13_reg[i] <= uc2rb_desc_10_wuser_13_reg[i];
             else 
               desc_10_wuser_13_reg[i] <= desc_10_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_14_reg_we[i])
                desc_10_wuser_14_reg[i] <= uc2rb_desc_10_wuser_14_reg[i];
             else 
               desc_10_wuser_14_reg[i] <= desc_10_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_10_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_10_wuser_15_reg_we[i])
                desc_10_wuser_15_reg[i] <= uc2rb_desc_10_wuser_15_reg[i];
             else 
               desc_10_wuser_15_reg[i] <= desc_10_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_11

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_txn_type_reg_we[i])
                desc_11_txn_type_reg[i] <= uc2rb_desc_11_txn_type_reg[i];
             else 
               desc_11_txn_type_reg[i] <= desc_11_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_size_reg_we[i])
                desc_11_size_reg[i] <= uc2rb_desc_11_size_reg[i];
             else 
               desc_11_size_reg[i] <= desc_11_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_data_offset_reg_we[i])
                desc_11_data_offset_reg[i] <= uc2rb_desc_11_data_offset_reg[i];
             else 
               desc_11_data_offset_reg[i] <= desc_11_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axsize_reg_we[i])
                desc_11_axsize_reg[i] <= uc2rb_desc_11_axsize_reg[i];
             else 
               desc_11_axsize_reg[i] <= desc_11_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_attr_reg_we[i])
                desc_11_attr_reg[i] <= uc2rb_desc_11_attr_reg[i];
             else 
               desc_11_attr_reg[i] <= desc_11_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axaddr_0_reg_we[i])
                desc_11_axaddr_0_reg[i] <= uc2rb_desc_11_axaddr_0_reg[i];
             else 
               desc_11_axaddr_0_reg[i] <= desc_11_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axaddr_1_reg_we[i])
                desc_11_axaddr_1_reg[i] <= uc2rb_desc_11_axaddr_1_reg[i];
             else 
               desc_11_axaddr_1_reg[i] <= desc_11_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axaddr_2_reg_we[i])
                desc_11_axaddr_2_reg[i] <= uc2rb_desc_11_axaddr_2_reg[i];
             else 
               desc_11_axaddr_2_reg[i] <= desc_11_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axaddr_3_reg_we[i])
                desc_11_axaddr_3_reg[i] <= uc2rb_desc_11_axaddr_3_reg[i];
             else 
               desc_11_axaddr_3_reg[i] <= desc_11_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axid_0_reg_we[i])
                desc_11_axid_0_reg[i] <= uc2rb_desc_11_axid_0_reg[i];
             else 
               desc_11_axid_0_reg[i] <= desc_11_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axid_1_reg_we[i])
                desc_11_axid_1_reg[i] <= uc2rb_desc_11_axid_1_reg[i];
             else 
               desc_11_axid_1_reg[i] <= desc_11_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axid_2_reg_we[i])
                desc_11_axid_2_reg[i] <= uc2rb_desc_11_axid_2_reg[i];
             else 
               desc_11_axid_2_reg[i] <= desc_11_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axid_3_reg_we[i])
                desc_11_axid_3_reg[i] <= uc2rb_desc_11_axid_3_reg[i];
             else 
               desc_11_axid_3_reg[i] <= desc_11_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_0_reg_we[i])
                desc_11_axuser_0_reg[i] <= uc2rb_desc_11_axuser_0_reg[i];
             else 
               desc_11_axuser_0_reg[i] <= desc_11_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_1_reg_we[i])
                desc_11_axuser_1_reg[i] <= uc2rb_desc_11_axuser_1_reg[i];
             else 
               desc_11_axuser_1_reg[i] <= desc_11_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_2_reg_we[i])
                desc_11_axuser_2_reg[i] <= uc2rb_desc_11_axuser_2_reg[i];
             else 
               desc_11_axuser_2_reg[i] <= desc_11_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_3_reg_we[i])
                desc_11_axuser_3_reg[i] <= uc2rb_desc_11_axuser_3_reg[i];
             else 
               desc_11_axuser_3_reg[i] <= desc_11_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_4_reg_we[i])
                desc_11_axuser_4_reg[i] <= uc2rb_desc_11_axuser_4_reg[i];
             else 
               desc_11_axuser_4_reg[i] <= desc_11_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_5_reg_we[i])
                desc_11_axuser_5_reg[i] <= uc2rb_desc_11_axuser_5_reg[i];
             else 
               desc_11_axuser_5_reg[i] <= desc_11_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_6_reg_we[i])
                desc_11_axuser_6_reg[i] <= uc2rb_desc_11_axuser_6_reg[i];
             else 
               desc_11_axuser_6_reg[i] <= desc_11_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_7_reg_we[i])
                desc_11_axuser_7_reg[i] <= uc2rb_desc_11_axuser_7_reg[i];
             else 
               desc_11_axuser_7_reg[i] <= desc_11_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_8_reg_we[i])
                desc_11_axuser_8_reg[i] <= uc2rb_desc_11_axuser_8_reg[i];
             else 
               desc_11_axuser_8_reg[i] <= desc_11_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_9_reg_we[i])
                desc_11_axuser_9_reg[i] <= uc2rb_desc_11_axuser_9_reg[i];
             else 
               desc_11_axuser_9_reg[i] <= desc_11_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_10_reg_we[i])
                desc_11_axuser_10_reg[i] <= uc2rb_desc_11_axuser_10_reg[i];
             else 
               desc_11_axuser_10_reg[i] <= desc_11_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_11_reg_we[i])
                desc_11_axuser_11_reg[i] <= uc2rb_desc_11_axuser_11_reg[i];
             else 
               desc_11_axuser_11_reg[i] <= desc_11_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_12_reg_we[i])
                desc_11_axuser_12_reg[i] <= uc2rb_desc_11_axuser_12_reg[i];
             else 
               desc_11_axuser_12_reg[i] <= desc_11_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_13_reg_we[i])
                desc_11_axuser_13_reg[i] <= uc2rb_desc_11_axuser_13_reg[i];
             else 
               desc_11_axuser_13_reg[i] <= desc_11_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_14_reg_we[i])
                desc_11_axuser_14_reg[i] <= uc2rb_desc_11_axuser_14_reg[i];
             else 
               desc_11_axuser_14_reg[i] <= desc_11_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_axuser_15_reg_we[i])
                desc_11_axuser_15_reg[i] <= uc2rb_desc_11_axuser_15_reg[i];
             else 
               desc_11_axuser_15_reg[i] <= desc_11_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_0_reg_we[i])
                desc_11_wuser_0_reg[i] <= uc2rb_desc_11_wuser_0_reg[i];
             else 
               desc_11_wuser_0_reg[i] <= desc_11_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_1_reg_we[i])
                desc_11_wuser_1_reg[i] <= uc2rb_desc_11_wuser_1_reg[i];
             else 
               desc_11_wuser_1_reg[i] <= desc_11_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_2_reg_we[i])
                desc_11_wuser_2_reg[i] <= uc2rb_desc_11_wuser_2_reg[i];
             else 
               desc_11_wuser_2_reg[i] <= desc_11_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_3_reg_we[i])
                desc_11_wuser_3_reg[i] <= uc2rb_desc_11_wuser_3_reg[i];
             else 
               desc_11_wuser_3_reg[i] <= desc_11_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_4_reg_we[i])
                desc_11_wuser_4_reg[i] <= uc2rb_desc_11_wuser_4_reg[i];
             else 
               desc_11_wuser_4_reg[i] <= desc_11_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_5_reg_we[i])
                desc_11_wuser_5_reg[i] <= uc2rb_desc_11_wuser_5_reg[i];
             else 
               desc_11_wuser_5_reg[i] <= desc_11_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_6_reg_we[i])
                desc_11_wuser_6_reg[i] <= uc2rb_desc_11_wuser_6_reg[i];
             else 
               desc_11_wuser_6_reg[i] <= desc_11_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_7_reg_we[i])
                desc_11_wuser_7_reg[i] <= uc2rb_desc_11_wuser_7_reg[i];
             else 
               desc_11_wuser_7_reg[i] <= desc_11_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_8_reg_we[i])
                desc_11_wuser_8_reg[i] <= uc2rb_desc_11_wuser_8_reg[i];
             else 
               desc_11_wuser_8_reg[i] <= desc_11_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_9_reg_we[i])
                desc_11_wuser_9_reg[i] <= uc2rb_desc_11_wuser_9_reg[i];
             else 
               desc_11_wuser_9_reg[i] <= desc_11_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_10_reg_we[i])
                desc_11_wuser_10_reg[i] <= uc2rb_desc_11_wuser_10_reg[i];
             else 
               desc_11_wuser_10_reg[i] <= desc_11_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_11_reg_we[i])
                desc_11_wuser_11_reg[i] <= uc2rb_desc_11_wuser_11_reg[i];
             else 
               desc_11_wuser_11_reg[i] <= desc_11_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_12_reg_we[i])
                desc_11_wuser_12_reg[i] <= uc2rb_desc_11_wuser_12_reg[i];
             else 
               desc_11_wuser_12_reg[i] <= desc_11_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_13_reg_we[i])
                desc_11_wuser_13_reg[i] <= uc2rb_desc_11_wuser_13_reg[i];
             else 
               desc_11_wuser_13_reg[i] <= desc_11_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_14_reg_we[i])
                desc_11_wuser_14_reg[i] <= uc2rb_desc_11_wuser_14_reg[i];
             else 
               desc_11_wuser_14_reg[i] <= desc_11_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_11_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_11_wuser_15_reg_we[i])
                desc_11_wuser_15_reg[i] <= uc2rb_desc_11_wuser_15_reg[i];
             else 
               desc_11_wuser_15_reg[i] <= desc_11_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_12

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_txn_type_reg_we[i])
                desc_12_txn_type_reg[i] <= uc2rb_desc_12_txn_type_reg[i];
             else 
               desc_12_txn_type_reg[i] <= desc_12_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_size_reg_we[i])
                desc_12_size_reg[i] <= uc2rb_desc_12_size_reg[i];
             else 
               desc_12_size_reg[i] <= desc_12_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_data_offset_reg_we[i])
                desc_12_data_offset_reg[i] <= uc2rb_desc_12_data_offset_reg[i];
             else 
               desc_12_data_offset_reg[i] <= desc_12_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axsize_reg_we[i])
                desc_12_axsize_reg[i] <= uc2rb_desc_12_axsize_reg[i];
             else 
               desc_12_axsize_reg[i] <= desc_12_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_attr_reg_we[i])
                desc_12_attr_reg[i] <= uc2rb_desc_12_attr_reg[i];
             else 
               desc_12_attr_reg[i] <= desc_12_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axaddr_0_reg_we[i])
                desc_12_axaddr_0_reg[i] <= uc2rb_desc_12_axaddr_0_reg[i];
             else 
               desc_12_axaddr_0_reg[i] <= desc_12_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axaddr_1_reg_we[i])
                desc_12_axaddr_1_reg[i] <= uc2rb_desc_12_axaddr_1_reg[i];
             else 
               desc_12_axaddr_1_reg[i] <= desc_12_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axaddr_2_reg_we[i])
                desc_12_axaddr_2_reg[i] <= uc2rb_desc_12_axaddr_2_reg[i];
             else 
               desc_12_axaddr_2_reg[i] <= desc_12_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axaddr_3_reg_we[i])
                desc_12_axaddr_3_reg[i] <= uc2rb_desc_12_axaddr_3_reg[i];
             else 
               desc_12_axaddr_3_reg[i] <= desc_12_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axid_0_reg_we[i])
                desc_12_axid_0_reg[i] <= uc2rb_desc_12_axid_0_reg[i];
             else 
               desc_12_axid_0_reg[i] <= desc_12_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axid_1_reg_we[i])
                desc_12_axid_1_reg[i] <= uc2rb_desc_12_axid_1_reg[i];
             else 
               desc_12_axid_1_reg[i] <= desc_12_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axid_2_reg_we[i])
                desc_12_axid_2_reg[i] <= uc2rb_desc_12_axid_2_reg[i];
             else 
               desc_12_axid_2_reg[i] <= desc_12_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axid_3_reg_we[i])
                desc_12_axid_3_reg[i] <= uc2rb_desc_12_axid_3_reg[i];
             else 
               desc_12_axid_3_reg[i] <= desc_12_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_0_reg_we[i])
                desc_12_axuser_0_reg[i] <= uc2rb_desc_12_axuser_0_reg[i];
             else 
               desc_12_axuser_0_reg[i] <= desc_12_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_1_reg_we[i])
                desc_12_axuser_1_reg[i] <= uc2rb_desc_12_axuser_1_reg[i];
             else 
               desc_12_axuser_1_reg[i] <= desc_12_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_2_reg_we[i])
                desc_12_axuser_2_reg[i] <= uc2rb_desc_12_axuser_2_reg[i];
             else 
               desc_12_axuser_2_reg[i] <= desc_12_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_3_reg_we[i])
                desc_12_axuser_3_reg[i] <= uc2rb_desc_12_axuser_3_reg[i];
             else 
               desc_12_axuser_3_reg[i] <= desc_12_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_4_reg_we[i])
                desc_12_axuser_4_reg[i] <= uc2rb_desc_12_axuser_4_reg[i];
             else 
               desc_12_axuser_4_reg[i] <= desc_12_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_5_reg_we[i])
                desc_12_axuser_5_reg[i] <= uc2rb_desc_12_axuser_5_reg[i];
             else 
               desc_12_axuser_5_reg[i] <= desc_12_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_6_reg_we[i])
                desc_12_axuser_6_reg[i] <= uc2rb_desc_12_axuser_6_reg[i];
             else 
               desc_12_axuser_6_reg[i] <= desc_12_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_7_reg_we[i])
                desc_12_axuser_7_reg[i] <= uc2rb_desc_12_axuser_7_reg[i];
             else 
               desc_12_axuser_7_reg[i] <= desc_12_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_8_reg_we[i])
                desc_12_axuser_8_reg[i] <= uc2rb_desc_12_axuser_8_reg[i];
             else 
               desc_12_axuser_8_reg[i] <= desc_12_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_9_reg_we[i])
                desc_12_axuser_9_reg[i] <= uc2rb_desc_12_axuser_9_reg[i];
             else 
               desc_12_axuser_9_reg[i] <= desc_12_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_10_reg_we[i])
                desc_12_axuser_10_reg[i] <= uc2rb_desc_12_axuser_10_reg[i];
             else 
               desc_12_axuser_10_reg[i] <= desc_12_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_11_reg_we[i])
                desc_12_axuser_11_reg[i] <= uc2rb_desc_12_axuser_11_reg[i];
             else 
               desc_12_axuser_11_reg[i] <= desc_12_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_12_reg_we[i])
                desc_12_axuser_12_reg[i] <= uc2rb_desc_12_axuser_12_reg[i];
             else 
               desc_12_axuser_12_reg[i] <= desc_12_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_13_reg_we[i])
                desc_12_axuser_13_reg[i] <= uc2rb_desc_12_axuser_13_reg[i];
             else 
               desc_12_axuser_13_reg[i] <= desc_12_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_14_reg_we[i])
                desc_12_axuser_14_reg[i] <= uc2rb_desc_12_axuser_14_reg[i];
             else 
               desc_12_axuser_14_reg[i] <= desc_12_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_axuser_15_reg_we[i])
                desc_12_axuser_15_reg[i] <= uc2rb_desc_12_axuser_15_reg[i];
             else 
               desc_12_axuser_15_reg[i] <= desc_12_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_0_reg_we[i])
                desc_12_wuser_0_reg[i] <= uc2rb_desc_12_wuser_0_reg[i];
             else 
               desc_12_wuser_0_reg[i] <= desc_12_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_1_reg_we[i])
                desc_12_wuser_1_reg[i] <= uc2rb_desc_12_wuser_1_reg[i];
             else 
               desc_12_wuser_1_reg[i] <= desc_12_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_2_reg_we[i])
                desc_12_wuser_2_reg[i] <= uc2rb_desc_12_wuser_2_reg[i];
             else 
               desc_12_wuser_2_reg[i] <= desc_12_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_3_reg_we[i])
                desc_12_wuser_3_reg[i] <= uc2rb_desc_12_wuser_3_reg[i];
             else 
               desc_12_wuser_3_reg[i] <= desc_12_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_4_reg_we[i])
                desc_12_wuser_4_reg[i] <= uc2rb_desc_12_wuser_4_reg[i];
             else 
               desc_12_wuser_4_reg[i] <= desc_12_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_5_reg_we[i])
                desc_12_wuser_5_reg[i] <= uc2rb_desc_12_wuser_5_reg[i];
             else 
               desc_12_wuser_5_reg[i] <= desc_12_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_6_reg_we[i])
                desc_12_wuser_6_reg[i] <= uc2rb_desc_12_wuser_6_reg[i];
             else 
               desc_12_wuser_6_reg[i] <= desc_12_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_7_reg_we[i])
                desc_12_wuser_7_reg[i] <= uc2rb_desc_12_wuser_7_reg[i];
             else 
               desc_12_wuser_7_reg[i] <= desc_12_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_8_reg_we[i])
                desc_12_wuser_8_reg[i] <= uc2rb_desc_12_wuser_8_reg[i];
             else 
               desc_12_wuser_8_reg[i] <= desc_12_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_9_reg_we[i])
                desc_12_wuser_9_reg[i] <= uc2rb_desc_12_wuser_9_reg[i];
             else 
               desc_12_wuser_9_reg[i] <= desc_12_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_10_reg_we[i])
                desc_12_wuser_10_reg[i] <= uc2rb_desc_12_wuser_10_reg[i];
             else 
               desc_12_wuser_10_reg[i] <= desc_12_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_11_reg_we[i])
                desc_12_wuser_11_reg[i] <= uc2rb_desc_12_wuser_11_reg[i];
             else 
               desc_12_wuser_11_reg[i] <= desc_12_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_12_reg_we[i])
                desc_12_wuser_12_reg[i] <= uc2rb_desc_12_wuser_12_reg[i];
             else 
               desc_12_wuser_12_reg[i] <= desc_12_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_13_reg_we[i])
                desc_12_wuser_13_reg[i] <= uc2rb_desc_12_wuser_13_reg[i];
             else 
               desc_12_wuser_13_reg[i] <= desc_12_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_14_reg_we[i])
                desc_12_wuser_14_reg[i] <= uc2rb_desc_12_wuser_14_reg[i];
             else 
               desc_12_wuser_14_reg[i] <= desc_12_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_12_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_12_wuser_15_reg_we[i])
                desc_12_wuser_15_reg[i] <= uc2rb_desc_12_wuser_15_reg[i];
             else 
               desc_12_wuser_15_reg[i] <= desc_12_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_13

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_txn_type_reg_we[i])
                desc_13_txn_type_reg[i] <= uc2rb_desc_13_txn_type_reg[i];
             else 
               desc_13_txn_type_reg[i] <= desc_13_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_size_reg_we[i])
                desc_13_size_reg[i] <= uc2rb_desc_13_size_reg[i];
             else 
               desc_13_size_reg[i] <= desc_13_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_data_offset_reg_we[i])
                desc_13_data_offset_reg[i] <= uc2rb_desc_13_data_offset_reg[i];
             else 
               desc_13_data_offset_reg[i] <= desc_13_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axsize_reg_we[i])
                desc_13_axsize_reg[i] <= uc2rb_desc_13_axsize_reg[i];
             else 
               desc_13_axsize_reg[i] <= desc_13_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_attr_reg_we[i])
                desc_13_attr_reg[i] <= uc2rb_desc_13_attr_reg[i];
             else 
               desc_13_attr_reg[i] <= desc_13_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axaddr_0_reg_we[i])
                desc_13_axaddr_0_reg[i] <= uc2rb_desc_13_axaddr_0_reg[i];
             else 
               desc_13_axaddr_0_reg[i] <= desc_13_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axaddr_1_reg_we[i])
                desc_13_axaddr_1_reg[i] <= uc2rb_desc_13_axaddr_1_reg[i];
             else 
               desc_13_axaddr_1_reg[i] <= desc_13_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axaddr_2_reg_we[i])
                desc_13_axaddr_2_reg[i] <= uc2rb_desc_13_axaddr_2_reg[i];
             else 
               desc_13_axaddr_2_reg[i] <= desc_13_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axaddr_3_reg_we[i])
                desc_13_axaddr_3_reg[i] <= uc2rb_desc_13_axaddr_3_reg[i];
             else 
               desc_13_axaddr_3_reg[i] <= desc_13_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axid_0_reg_we[i])
                desc_13_axid_0_reg[i] <= uc2rb_desc_13_axid_0_reg[i];
             else 
               desc_13_axid_0_reg[i] <= desc_13_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axid_1_reg_we[i])
                desc_13_axid_1_reg[i] <= uc2rb_desc_13_axid_1_reg[i];
             else 
               desc_13_axid_1_reg[i] <= desc_13_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axid_2_reg_we[i])
                desc_13_axid_2_reg[i] <= uc2rb_desc_13_axid_2_reg[i];
             else 
               desc_13_axid_2_reg[i] <= desc_13_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axid_3_reg_we[i])
                desc_13_axid_3_reg[i] <= uc2rb_desc_13_axid_3_reg[i];
             else 
               desc_13_axid_3_reg[i] <= desc_13_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_0_reg_we[i])
                desc_13_axuser_0_reg[i] <= uc2rb_desc_13_axuser_0_reg[i];
             else 
               desc_13_axuser_0_reg[i] <= desc_13_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_1_reg_we[i])
                desc_13_axuser_1_reg[i] <= uc2rb_desc_13_axuser_1_reg[i];
             else 
               desc_13_axuser_1_reg[i] <= desc_13_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_2_reg_we[i])
                desc_13_axuser_2_reg[i] <= uc2rb_desc_13_axuser_2_reg[i];
             else 
               desc_13_axuser_2_reg[i] <= desc_13_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_3_reg_we[i])
                desc_13_axuser_3_reg[i] <= uc2rb_desc_13_axuser_3_reg[i];
             else 
               desc_13_axuser_3_reg[i] <= desc_13_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_4_reg_we[i])
                desc_13_axuser_4_reg[i] <= uc2rb_desc_13_axuser_4_reg[i];
             else 
               desc_13_axuser_4_reg[i] <= desc_13_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_5_reg_we[i])
                desc_13_axuser_5_reg[i] <= uc2rb_desc_13_axuser_5_reg[i];
             else 
               desc_13_axuser_5_reg[i] <= desc_13_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_6_reg_we[i])
                desc_13_axuser_6_reg[i] <= uc2rb_desc_13_axuser_6_reg[i];
             else 
               desc_13_axuser_6_reg[i] <= desc_13_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_7_reg_we[i])
                desc_13_axuser_7_reg[i] <= uc2rb_desc_13_axuser_7_reg[i];
             else 
               desc_13_axuser_7_reg[i] <= desc_13_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_8_reg_we[i])
                desc_13_axuser_8_reg[i] <= uc2rb_desc_13_axuser_8_reg[i];
             else 
               desc_13_axuser_8_reg[i] <= desc_13_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_9_reg_we[i])
                desc_13_axuser_9_reg[i] <= uc2rb_desc_13_axuser_9_reg[i];
             else 
               desc_13_axuser_9_reg[i] <= desc_13_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_10_reg_we[i])
                desc_13_axuser_10_reg[i] <= uc2rb_desc_13_axuser_10_reg[i];
             else 
               desc_13_axuser_10_reg[i] <= desc_13_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_11_reg_we[i])
                desc_13_axuser_11_reg[i] <= uc2rb_desc_13_axuser_11_reg[i];
             else 
               desc_13_axuser_11_reg[i] <= desc_13_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_12_reg_we[i])
                desc_13_axuser_12_reg[i] <= uc2rb_desc_13_axuser_12_reg[i];
             else 
               desc_13_axuser_12_reg[i] <= desc_13_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_13_reg_we[i])
                desc_13_axuser_13_reg[i] <= uc2rb_desc_13_axuser_13_reg[i];
             else 
               desc_13_axuser_13_reg[i] <= desc_13_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_14_reg_we[i])
                desc_13_axuser_14_reg[i] <= uc2rb_desc_13_axuser_14_reg[i];
             else 
               desc_13_axuser_14_reg[i] <= desc_13_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_axuser_15_reg_we[i])
                desc_13_axuser_15_reg[i] <= uc2rb_desc_13_axuser_15_reg[i];
             else 
               desc_13_axuser_15_reg[i] <= desc_13_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_0_reg_we[i])
                desc_13_wuser_0_reg[i] <= uc2rb_desc_13_wuser_0_reg[i];
             else 
               desc_13_wuser_0_reg[i] <= desc_13_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_1_reg_we[i])
                desc_13_wuser_1_reg[i] <= uc2rb_desc_13_wuser_1_reg[i];
             else 
               desc_13_wuser_1_reg[i] <= desc_13_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_2_reg_we[i])
                desc_13_wuser_2_reg[i] <= uc2rb_desc_13_wuser_2_reg[i];
             else 
               desc_13_wuser_2_reg[i] <= desc_13_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_3_reg_we[i])
                desc_13_wuser_3_reg[i] <= uc2rb_desc_13_wuser_3_reg[i];
             else 
               desc_13_wuser_3_reg[i] <= desc_13_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_4_reg_we[i])
                desc_13_wuser_4_reg[i] <= uc2rb_desc_13_wuser_4_reg[i];
             else 
               desc_13_wuser_4_reg[i] <= desc_13_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_5_reg_we[i])
                desc_13_wuser_5_reg[i] <= uc2rb_desc_13_wuser_5_reg[i];
             else 
               desc_13_wuser_5_reg[i] <= desc_13_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_6_reg_we[i])
                desc_13_wuser_6_reg[i] <= uc2rb_desc_13_wuser_6_reg[i];
             else 
               desc_13_wuser_6_reg[i] <= desc_13_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_7_reg_we[i])
                desc_13_wuser_7_reg[i] <= uc2rb_desc_13_wuser_7_reg[i];
             else 
               desc_13_wuser_7_reg[i] <= desc_13_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_8_reg_we[i])
                desc_13_wuser_8_reg[i] <= uc2rb_desc_13_wuser_8_reg[i];
             else 
               desc_13_wuser_8_reg[i] <= desc_13_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_9_reg_we[i])
                desc_13_wuser_9_reg[i] <= uc2rb_desc_13_wuser_9_reg[i];
             else 
               desc_13_wuser_9_reg[i] <= desc_13_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_10_reg_we[i])
                desc_13_wuser_10_reg[i] <= uc2rb_desc_13_wuser_10_reg[i];
             else 
               desc_13_wuser_10_reg[i] <= desc_13_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_11_reg_we[i])
                desc_13_wuser_11_reg[i] <= uc2rb_desc_13_wuser_11_reg[i];
             else 
               desc_13_wuser_11_reg[i] <= desc_13_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_12_reg_we[i])
                desc_13_wuser_12_reg[i] <= uc2rb_desc_13_wuser_12_reg[i];
             else 
               desc_13_wuser_12_reg[i] <= desc_13_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_13_reg_we[i])
                desc_13_wuser_13_reg[i] <= uc2rb_desc_13_wuser_13_reg[i];
             else 
               desc_13_wuser_13_reg[i] <= desc_13_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_14_reg_we[i])
                desc_13_wuser_14_reg[i] <= uc2rb_desc_13_wuser_14_reg[i];
             else 
               desc_13_wuser_14_reg[i] <= desc_13_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_13_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_13_wuser_15_reg_we[i])
                desc_13_wuser_15_reg[i] <= uc2rb_desc_13_wuser_15_reg[i];
             else 
               desc_13_wuser_15_reg[i] <= desc_13_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_14

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_txn_type_reg_we[i])
                desc_14_txn_type_reg[i] <= uc2rb_desc_14_txn_type_reg[i];
             else 
               desc_14_txn_type_reg[i] <= desc_14_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_size_reg_we[i])
                desc_14_size_reg[i] <= uc2rb_desc_14_size_reg[i];
             else 
               desc_14_size_reg[i] <= desc_14_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_data_offset_reg_we[i])
                desc_14_data_offset_reg[i] <= uc2rb_desc_14_data_offset_reg[i];
             else 
               desc_14_data_offset_reg[i] <= desc_14_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axsize_reg_we[i])
                desc_14_axsize_reg[i] <= uc2rb_desc_14_axsize_reg[i];
             else 
               desc_14_axsize_reg[i] <= desc_14_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_attr_reg_we[i])
                desc_14_attr_reg[i] <= uc2rb_desc_14_attr_reg[i];
             else 
               desc_14_attr_reg[i] <= desc_14_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axaddr_0_reg_we[i])
                desc_14_axaddr_0_reg[i] <= uc2rb_desc_14_axaddr_0_reg[i];
             else 
               desc_14_axaddr_0_reg[i] <= desc_14_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axaddr_1_reg_we[i])
                desc_14_axaddr_1_reg[i] <= uc2rb_desc_14_axaddr_1_reg[i];
             else 
               desc_14_axaddr_1_reg[i] <= desc_14_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axaddr_2_reg_we[i])
                desc_14_axaddr_2_reg[i] <= uc2rb_desc_14_axaddr_2_reg[i];
             else 
               desc_14_axaddr_2_reg[i] <= desc_14_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axaddr_3_reg_we[i])
                desc_14_axaddr_3_reg[i] <= uc2rb_desc_14_axaddr_3_reg[i];
             else 
               desc_14_axaddr_3_reg[i] <= desc_14_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axid_0_reg_we[i])
                desc_14_axid_0_reg[i] <= uc2rb_desc_14_axid_0_reg[i];
             else 
               desc_14_axid_0_reg[i] <= desc_14_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axid_1_reg_we[i])
                desc_14_axid_1_reg[i] <= uc2rb_desc_14_axid_1_reg[i];
             else 
               desc_14_axid_1_reg[i] <= desc_14_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axid_2_reg_we[i])
                desc_14_axid_2_reg[i] <= uc2rb_desc_14_axid_2_reg[i];
             else 
               desc_14_axid_2_reg[i] <= desc_14_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axid_3_reg_we[i])
                desc_14_axid_3_reg[i] <= uc2rb_desc_14_axid_3_reg[i];
             else 
               desc_14_axid_3_reg[i] <= desc_14_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_0_reg_we[i])
                desc_14_axuser_0_reg[i] <= uc2rb_desc_14_axuser_0_reg[i];
             else 
               desc_14_axuser_0_reg[i] <= desc_14_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_1_reg_we[i])
                desc_14_axuser_1_reg[i] <= uc2rb_desc_14_axuser_1_reg[i];
             else 
               desc_14_axuser_1_reg[i] <= desc_14_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_2_reg_we[i])
                desc_14_axuser_2_reg[i] <= uc2rb_desc_14_axuser_2_reg[i];
             else 
               desc_14_axuser_2_reg[i] <= desc_14_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_3_reg_we[i])
                desc_14_axuser_3_reg[i] <= uc2rb_desc_14_axuser_3_reg[i];
             else 
               desc_14_axuser_3_reg[i] <= desc_14_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_4_reg_we[i])
                desc_14_axuser_4_reg[i] <= uc2rb_desc_14_axuser_4_reg[i];
             else 
               desc_14_axuser_4_reg[i] <= desc_14_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_5_reg_we[i])
                desc_14_axuser_5_reg[i] <= uc2rb_desc_14_axuser_5_reg[i];
             else 
               desc_14_axuser_5_reg[i] <= desc_14_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_6_reg_we[i])
                desc_14_axuser_6_reg[i] <= uc2rb_desc_14_axuser_6_reg[i];
             else 
               desc_14_axuser_6_reg[i] <= desc_14_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_7_reg_we[i])
                desc_14_axuser_7_reg[i] <= uc2rb_desc_14_axuser_7_reg[i];
             else 
               desc_14_axuser_7_reg[i] <= desc_14_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_8_reg_we[i])
                desc_14_axuser_8_reg[i] <= uc2rb_desc_14_axuser_8_reg[i];
             else 
               desc_14_axuser_8_reg[i] <= desc_14_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_9_reg_we[i])
                desc_14_axuser_9_reg[i] <= uc2rb_desc_14_axuser_9_reg[i];
             else 
               desc_14_axuser_9_reg[i] <= desc_14_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_10_reg_we[i])
                desc_14_axuser_10_reg[i] <= uc2rb_desc_14_axuser_10_reg[i];
             else 
               desc_14_axuser_10_reg[i] <= desc_14_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_11_reg_we[i])
                desc_14_axuser_11_reg[i] <= uc2rb_desc_14_axuser_11_reg[i];
             else 
               desc_14_axuser_11_reg[i] <= desc_14_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_12_reg_we[i])
                desc_14_axuser_12_reg[i] <= uc2rb_desc_14_axuser_12_reg[i];
             else 
               desc_14_axuser_12_reg[i] <= desc_14_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_13_reg_we[i])
                desc_14_axuser_13_reg[i] <= uc2rb_desc_14_axuser_13_reg[i];
             else 
               desc_14_axuser_13_reg[i] <= desc_14_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_14_reg_we[i])
                desc_14_axuser_14_reg[i] <= uc2rb_desc_14_axuser_14_reg[i];
             else 
               desc_14_axuser_14_reg[i] <= desc_14_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_axuser_15_reg_we[i])
                desc_14_axuser_15_reg[i] <= uc2rb_desc_14_axuser_15_reg[i];
             else 
               desc_14_axuser_15_reg[i] <= desc_14_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_0_reg_we[i])
                desc_14_wuser_0_reg[i] <= uc2rb_desc_14_wuser_0_reg[i];
             else 
               desc_14_wuser_0_reg[i] <= desc_14_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_1_reg_we[i])
                desc_14_wuser_1_reg[i] <= uc2rb_desc_14_wuser_1_reg[i];
             else 
               desc_14_wuser_1_reg[i] <= desc_14_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_2_reg_we[i])
                desc_14_wuser_2_reg[i] <= uc2rb_desc_14_wuser_2_reg[i];
             else 
               desc_14_wuser_2_reg[i] <= desc_14_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_3_reg_we[i])
                desc_14_wuser_3_reg[i] <= uc2rb_desc_14_wuser_3_reg[i];
             else 
               desc_14_wuser_3_reg[i] <= desc_14_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_4_reg_we[i])
                desc_14_wuser_4_reg[i] <= uc2rb_desc_14_wuser_4_reg[i];
             else 
               desc_14_wuser_4_reg[i] <= desc_14_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_5_reg_we[i])
                desc_14_wuser_5_reg[i] <= uc2rb_desc_14_wuser_5_reg[i];
             else 
               desc_14_wuser_5_reg[i] <= desc_14_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_6_reg_we[i])
                desc_14_wuser_6_reg[i] <= uc2rb_desc_14_wuser_6_reg[i];
             else 
               desc_14_wuser_6_reg[i] <= desc_14_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_7_reg_we[i])
                desc_14_wuser_7_reg[i] <= uc2rb_desc_14_wuser_7_reg[i];
             else 
               desc_14_wuser_7_reg[i] <= desc_14_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_8_reg_we[i])
                desc_14_wuser_8_reg[i] <= uc2rb_desc_14_wuser_8_reg[i];
             else 
               desc_14_wuser_8_reg[i] <= desc_14_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_9_reg_we[i])
                desc_14_wuser_9_reg[i] <= uc2rb_desc_14_wuser_9_reg[i];
             else 
               desc_14_wuser_9_reg[i] <= desc_14_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_10_reg_we[i])
                desc_14_wuser_10_reg[i] <= uc2rb_desc_14_wuser_10_reg[i];
             else 
               desc_14_wuser_10_reg[i] <= desc_14_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_11_reg_we[i])
                desc_14_wuser_11_reg[i] <= uc2rb_desc_14_wuser_11_reg[i];
             else 
               desc_14_wuser_11_reg[i] <= desc_14_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_12_reg_we[i])
                desc_14_wuser_12_reg[i] <= uc2rb_desc_14_wuser_12_reg[i];
             else 
               desc_14_wuser_12_reg[i] <= desc_14_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_13_reg_we[i])
                desc_14_wuser_13_reg[i] <= uc2rb_desc_14_wuser_13_reg[i];
             else 
               desc_14_wuser_13_reg[i] <= desc_14_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_14_reg_we[i])
                desc_14_wuser_14_reg[i] <= uc2rb_desc_14_wuser_14_reg[i];
             else 
               desc_14_wuser_14_reg[i] <= desc_14_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_14_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_14_wuser_15_reg_we[i])
                desc_14_wuser_15_reg[i] <= uc2rb_desc_14_wuser_15_reg[i];
             else 
               desc_14_wuser_15_reg[i] <= desc_14_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )

//DESC_15

   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_txn_type_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_txn_type_reg_we[i])
                desc_15_txn_type_reg[i] <= uc2rb_desc_15_txn_type_reg[i];
             else 
               desc_15_txn_type_reg[i] <= desc_15_txn_type_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_size_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_size_reg_we[i])
                desc_15_size_reg[i] <= uc2rb_desc_15_size_reg[i];
             else 
               desc_15_size_reg[i] <= desc_15_size_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_data_offset_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_data_offset_reg_we[i])
                desc_15_data_offset_reg[i] <= uc2rb_desc_15_data_offset_reg[i];
             else 
               desc_15_data_offset_reg[i] <= desc_15_data_offset_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axsize_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axsize_reg_we[i])
                desc_15_axsize_reg[i] <= uc2rb_desc_15_axsize_reg[i];
             else 
               desc_15_axsize_reg[i] <= desc_15_axsize_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_attr_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_attr_reg_we[i])
                desc_15_attr_reg[i] <= uc2rb_desc_15_attr_reg[i];
             else 
               desc_15_attr_reg[i] <= desc_15_attr_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axaddr_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axaddr_0_reg_we[i])
                desc_15_axaddr_0_reg[i] <= uc2rb_desc_15_axaddr_0_reg[i];
             else 
               desc_15_axaddr_0_reg[i] <= desc_15_axaddr_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axaddr_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axaddr_1_reg_we[i])
                desc_15_axaddr_1_reg[i] <= uc2rb_desc_15_axaddr_1_reg[i];
             else 
               desc_15_axaddr_1_reg[i] <= desc_15_axaddr_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axaddr_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axaddr_2_reg_we[i])
                desc_15_axaddr_2_reg[i] <= uc2rb_desc_15_axaddr_2_reg[i];
             else 
               desc_15_axaddr_2_reg[i] <= desc_15_axaddr_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axaddr_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axaddr_3_reg_we[i])
                desc_15_axaddr_3_reg[i] <= uc2rb_desc_15_axaddr_3_reg[i];
             else 
               desc_15_axaddr_3_reg[i] <= desc_15_axaddr_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axid_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axid_0_reg_we[i])
                desc_15_axid_0_reg[i] <= uc2rb_desc_15_axid_0_reg[i];
             else 
               desc_15_axid_0_reg[i] <= desc_15_axid_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axid_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axid_1_reg_we[i])
                desc_15_axid_1_reg[i] <= uc2rb_desc_15_axid_1_reg[i];
             else 
               desc_15_axid_1_reg[i] <= desc_15_axid_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axid_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axid_2_reg_we[i])
                desc_15_axid_2_reg[i] <= uc2rb_desc_15_axid_2_reg[i];
             else 
               desc_15_axid_2_reg[i] <= desc_15_axid_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axid_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axid_3_reg_we[i])
                desc_15_axid_3_reg[i] <= uc2rb_desc_15_axid_3_reg[i];
             else 
               desc_15_axid_3_reg[i] <= desc_15_axid_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_0_reg_we[i])
                desc_15_axuser_0_reg[i] <= uc2rb_desc_15_axuser_0_reg[i];
             else 
               desc_15_axuser_0_reg[i] <= desc_15_axuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_1_reg_we[i])
                desc_15_axuser_1_reg[i] <= uc2rb_desc_15_axuser_1_reg[i];
             else 
               desc_15_axuser_1_reg[i] <= desc_15_axuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_2_reg_we[i])
                desc_15_axuser_2_reg[i] <= uc2rb_desc_15_axuser_2_reg[i];
             else 
               desc_15_axuser_2_reg[i] <= desc_15_axuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_3_reg_we[i])
                desc_15_axuser_3_reg[i] <= uc2rb_desc_15_axuser_3_reg[i];
             else 
               desc_15_axuser_3_reg[i] <= desc_15_axuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_4_reg_we[i])
                desc_15_axuser_4_reg[i] <= uc2rb_desc_15_axuser_4_reg[i];
             else 
               desc_15_axuser_4_reg[i] <= desc_15_axuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_5_reg_we[i])
                desc_15_axuser_5_reg[i] <= uc2rb_desc_15_axuser_5_reg[i];
             else 
               desc_15_axuser_5_reg[i] <= desc_15_axuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_6_reg_we[i])
                desc_15_axuser_6_reg[i] <= uc2rb_desc_15_axuser_6_reg[i];
             else 
               desc_15_axuser_6_reg[i] <= desc_15_axuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_7_reg_we[i])
                desc_15_axuser_7_reg[i] <= uc2rb_desc_15_axuser_7_reg[i];
             else 
               desc_15_axuser_7_reg[i] <= desc_15_axuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_8_reg_we[i])
                desc_15_axuser_8_reg[i] <= uc2rb_desc_15_axuser_8_reg[i];
             else 
               desc_15_axuser_8_reg[i] <= desc_15_axuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_9_reg_we[i])
                desc_15_axuser_9_reg[i] <= uc2rb_desc_15_axuser_9_reg[i];
             else 
               desc_15_axuser_9_reg[i] <= desc_15_axuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_10_reg_we[i])
                desc_15_axuser_10_reg[i] <= uc2rb_desc_15_axuser_10_reg[i];
             else 
               desc_15_axuser_10_reg[i] <= desc_15_axuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_11_reg_we[i])
                desc_15_axuser_11_reg[i] <= uc2rb_desc_15_axuser_11_reg[i];
             else 
               desc_15_axuser_11_reg[i] <= desc_15_axuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_12_reg_we[i])
                desc_15_axuser_12_reg[i] <= uc2rb_desc_15_axuser_12_reg[i];
             else 
               desc_15_axuser_12_reg[i] <= desc_15_axuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_13_reg_we[i])
                desc_15_axuser_13_reg[i] <= uc2rb_desc_15_axuser_13_reg[i];
             else 
               desc_15_axuser_13_reg[i] <= desc_15_axuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_14_reg_we[i])
                desc_15_axuser_14_reg[i] <= uc2rb_desc_15_axuser_14_reg[i];
             else 
               desc_15_axuser_14_reg[i] <= desc_15_axuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_axuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_axuser_15_reg_we[i])
                desc_15_axuser_15_reg[i] <= uc2rb_desc_15_axuser_15_reg[i];
             else 
               desc_15_axuser_15_reg[i] <= desc_15_axuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_0_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_0_reg_we[i])
                desc_15_wuser_0_reg[i] <= uc2rb_desc_15_wuser_0_reg[i];
             else 
               desc_15_wuser_0_reg[i] <= desc_15_wuser_0_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_1_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_1_reg_we[i])
                desc_15_wuser_1_reg[i] <= uc2rb_desc_15_wuser_1_reg[i];
             else 
               desc_15_wuser_1_reg[i] <= desc_15_wuser_1_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_2_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_2_reg_we[i])
                desc_15_wuser_2_reg[i] <= uc2rb_desc_15_wuser_2_reg[i];
             else 
               desc_15_wuser_2_reg[i] <= desc_15_wuser_2_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_3_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_3_reg_we[i])
                desc_15_wuser_3_reg[i] <= uc2rb_desc_15_wuser_3_reg[i];
             else 
               desc_15_wuser_3_reg[i] <= desc_15_wuser_3_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_4_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_4_reg_we[i])
                desc_15_wuser_4_reg[i] <= uc2rb_desc_15_wuser_4_reg[i];
             else 
               desc_15_wuser_4_reg[i] <= desc_15_wuser_4_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_5_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_5_reg_we[i])
                desc_15_wuser_5_reg[i] <= uc2rb_desc_15_wuser_5_reg[i];
             else 
               desc_15_wuser_5_reg[i] <= desc_15_wuser_5_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_6_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_6_reg_we[i])
                desc_15_wuser_6_reg[i] <= uc2rb_desc_15_wuser_6_reg[i];
             else 
               desc_15_wuser_6_reg[i] <= desc_15_wuser_6_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_7_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_7_reg_we[i])
                desc_15_wuser_7_reg[i] <= uc2rb_desc_15_wuser_7_reg[i];
             else 
               desc_15_wuser_7_reg[i] <= desc_15_wuser_7_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_8_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_8_reg_we[i])
                desc_15_wuser_8_reg[i] <= uc2rb_desc_15_wuser_8_reg[i];
             else 
               desc_15_wuser_8_reg[i] <= desc_15_wuser_8_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_9_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_9_reg_we[i])
                desc_15_wuser_9_reg[i] <= uc2rb_desc_15_wuser_9_reg[i];
             else 
               desc_15_wuser_9_reg[i] <= desc_15_wuser_9_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_10_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_10_reg_we[i])
                desc_15_wuser_10_reg[i] <= uc2rb_desc_15_wuser_10_reg[i];
             else 
               desc_15_wuser_10_reg[i] <= desc_15_wuser_10_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_11_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_11_reg_we[i])
                desc_15_wuser_11_reg[i] <= uc2rb_desc_15_wuser_11_reg[i];
             else 
               desc_15_wuser_11_reg[i] <= desc_15_wuser_11_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_12_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_12_reg_we[i])
                desc_15_wuser_12_reg[i] <= uc2rb_desc_15_wuser_12_reg[i];
             else 
               desc_15_wuser_12_reg[i] <= desc_15_wuser_12_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_13_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_13_reg_we[i])
                desc_15_wuser_13_reg[i] <= uc2rb_desc_15_wuser_13_reg[i];
             else 
               desc_15_wuser_13_reg[i] <= desc_15_wuser_13_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_14_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_14_reg_we[i])
                desc_15_wuser_14_reg[i] <= uc2rb_desc_15_wuser_14_reg[i];
             else 
               desc_15_wuser_14_reg[i] <= desc_15_wuser_14_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   always @( posedge axi_aclk )
     begin
        for (i = 0; i < 32 ; i = i + 1) begin
           if (~rst_n)
           desc_15_wuser_15_reg[i] <= 1'b0;
           else 
             if (uc2rb_desc_15_wuser_15_reg_we[i])
                desc_15_wuser_15_reg[i] <= uc2rb_desc_15_wuser_15_reg[i];
             else 
               desc_15_wuser_15_reg[i] <= desc_15_wuser_15_reg[i];
        end
     end // always @ ( posedge axi_aclk )
   
   


// RAMS


   reg [(`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8)))-1:0] wdata_ram_addr;
   reg                                                   wdata_ram_rd_en;
   

always @(posedge axi_aclk)
  begin
      if ( ~rst_n)
          begin
             wdata_ram_addr   <= 'h0;     
          end
      else begin
         if (~mode_select_reg[0]) begin
            if (~axi_araddr[BRIDGE_MSB] && axi_araddr[BRIDGE_MSB-1] && axi_araddr[BRIDGE_MSB-2])begin //AXI RD targeted to WDATA RAM
               if (~wdata_ram_rd_en) begin
                  if (arvalid_pending_pulse)begin
                     wdata_ram_rd_en <= 1'b1;
                     if (S_AXI_USR_DATA_WIDTH == 128)
                       wdata_ram_addr <= axi_araddr[S_AXI_ADDR_WIDTH-1:4];
                     else if (S_AXI_USR_DATA_WIDTH == 64)
                       wdata_ram_addr <= axi_araddr[S_AXI_ADDR_WIDTH-1:3];
                     else if (S_AXI_USR_DATA_WIDTH == 32)                    
                       wdata_ram_addr <= axi_araddr[S_AXI_ADDR_WIDTH-1:2];
                  end
                  else begin
                     wdata_ram_addr   <= 'h0;
                     wdata_ram_rd_en  <= 1'b0;
                  end // else: !if(arvalid_pending_pulse)
               end // if (~wdata_ram_rd_en)
               else begin
                  wdata_ram_addr   <= 'h0;
                  wdata_ram_rd_en  <= 1'b0;
               end // else: !if(~wdata_ram_rd_en)
            end 
            else begin
                  wdata_ram_addr   <= 'h0;
                  wdata_ram_rd_en  <= 1'b0;
            end // else: !if(~axi_araddr[16] && axi_araddr[15] && ~axi_araddr[14])
         end
         else begin
            wdata_ram_addr   <= hm2rb_rd_addr;
            wdata_ram_rd_en  <= 1'b1;
         end // else: !if(~mode_select_reg[0])
      end // else: !if( ~rst_n)
  end // always @ (posedge axi_aclk)
   
   wire [S_AXI_USR_DATA_WIDTH-1:0] wdata_ram_data;                      
   wire [(S_AXI_USR_DATA_WIDTH/8)-1:0] wstrb_ram_data;
   
   reg wdata_ram_data_ready;
   reg wdata_ram_data_ready_1;

   
   always @( posedge axi_aclk )
     begin
        if ( rst_n == 1'b0 )
          begin
             wdata_ram_data_ready  <= 0;
             wdata_ram_data_ready_1  <= 0;
             wdata_ram_data_ready_2  <= 0;
          end 
        else
          if (~axi_araddr[BRIDGE_MSB] && axi_araddr[BRIDGE_MSB-1] && axi_araddr[BRIDGE_MSB-2]) begin
             wdata_ram_data_ready_1 <= wdata_ram_rd_en;
             wdata_ram_data_ready_2 <= wdata_ram_data_ready_1;
             wdata_ram_data_ready <= wdata_ram_data_ready_2;
          end
          else begin
             wdata_ram_data_ready  <= 0;
             wdata_ram_data_ready_1  <= 0;
             wdata_ram_data_ready_2  <= 0;
          end
     end // always @ ( posedge axi_aclk )
   




   // Output register or memory read data
   always @( posedge axi_aclk )
     begin
        if ( rst_n == 1'b0 )
          begin
             axi_rdata  <= 0;
          end 
        else
          begin    
             // When there is a valid read address (S_AXI_ARVALID) with 
             // acceptance of read address by the slave (axi_arready), 
             // output the read dada 
             if (~mode_select_reg[0]) begin
                  if (~axi_araddr[BRIDGE_MSB] && axi_araddr[BRIDGE_MSB-1] && axi_araddr[BRIDGE_MSB-2])begin
                    if (wdata_ram_data_ready) begin
                       if (S_AXI_USR_DATA_WIDTH == 128)begin
                         case (axi_araddr[3:2])
                           2'b00: axi_rdata <= wdata_ram_data[31:0];     //data from WDATA RAM
                           2'b01: axi_rdata <= wdata_ram_data[63:32];
                           2'b10: axi_rdata <= wdata_ram_data[95:64];
                           2'b11: axi_rdata <= wdata_ram_data[127:96];
                         endcase // case (axi_araddr[3:2])
                       end
                       else begin
                         if (S_AXI_USR_DATA_WIDTH == 64)begin
                         case (axi_araddr[2])
                           1'b0: axi_rdata <= wdata_ram_data[31:0];
                           1'b1: axi_rdata <= wdata_ram_data[63:32];
                         endcase // case (axi_araddr[2])
                         end
                         else begin 
                            if (S_AXI_USR_DATA_WIDTH == 32)                    
                              axi_rdata <= wdata_ram_data;
                         end
                       end // else: !if(S_AXI_USR_DATA_WIDTH == 128)
                    end
                    else begin
	                 axi_rdata <= axi_rdata;
                    end // else: !if(wdata_ram_data_ready)
                  end
                  else begin
                     if (axi_araddr[BRIDGE_MSB] && ~axi_araddr[BRIDGE_MSB-1] && ~axi_araddr[BRIDGE_MSB-2])begin
                        if (wstrb_ram_data_ready) begin
                           if (S_AXI_USR_DATA_WIDTH == 128)begin
                              case (axi_araddr[3:2])
                                2'b00: axi_rdata <= (EXTEND_WSTRB==1) ? { { 8{wstrb_ram_data[3]} }, { 8{wstrb_ram_data[2]} }, { 8{wstrb_ram_data[1]} }, { 8{wstrb_ram_data[0]} } } : {28'b0,wstrb_ram_data[3:0] } ;     //data from WSTRB RAM
                                2'b01: axi_rdata <= (EXTEND_WSTRB==1) ? { { 8{wstrb_ram_data[7]} }, { 8{wstrb_ram_data[6]} }, { 8{wstrb_ram_data[5]} }, { 8{wstrb_ram_data[4]} } } : {28'b0,wstrb_ram_data[7:4]};
                                2'b10: axi_rdata <= (EXTEND_WSTRB==1) ? { { 8{wstrb_ram_data[11]} }, { 8{wstrb_ram_data[10]} }, { 8{wstrb_ram_data[9]} }, { 8{wstrb_ram_data[8]} } } : {28'b0,wstrb_ram_data[11:8]};
                                2'b11: axi_rdata <= (EXTEND_WSTRB==1) ? { { 8{wstrb_ram_data[15]} }, { 8{wstrb_ram_data[14]} }, { 8{wstrb_ram_data[13]} }, { 8{wstrb_ram_data[12]} } } : {28'b0,wstrb_ram_data[15:12]};
                              endcase // case (axi_araddr[3:2])
                           end
                           else begin
                              if (S_AXI_USR_DATA_WIDTH == 64)begin
                                 case (axi_araddr[2])
                                   1'b0: axi_rdata <= (EXTEND_WSTRB==1) ? { { 8{wstrb_ram_data[3]} }, { 8{wstrb_ram_data[2]} }, { 8{wstrb_ram_data[1]} }, { 8{wstrb_ram_data[0]} } } : {28'b0,wstrb_ram_data[3:0]};
                                   1'b1: axi_rdata <= (EXTEND_WSTRB==1) ? { { 8{wstrb_ram_data[7]} }, { 8{wstrb_ram_data[6]} }, { 8{wstrb_ram_data[5]} }, { 8{wstrb_ram_data[4]} } } : {28'b0,wstrb_ram_data[7:4]};
                                 endcase // case (axi_araddr[2])
                              end
                              else begin 
                                 if (S_AXI_USR_DATA_WIDTH == 32)                    
                                   axi_rdata <= (EXTEND_WSTRB==1) ? { { 8{wstrb_ram_data[3]} }, { 8{wstrb_ram_data[2]} }, { 8{wstrb_ram_data[1]} }, { 8{wstrb_ram_data[0]} } } : {28'b0,  wstrb_ram_data[3:0] };
                              end
                           end // else: !if(S_AXI_USR_DATA_WIDTH == 128)
                        end
                        else
			    axi_rdata <= axi_rdata;
                     end // if (axi_araddr[16] && ~axi_araddr[15] && ~axi_araddr[14])
                     else
                       axi_rdata <= reg_data_out_pipeline;     // register read data
                  end // else: !if(~axi_araddr[16] && axi_araddr[15] && ~axi_araddr[14])
             end
             else begin
                rb2hm_rd_data <= wdata_ram_data;
                rb2hm_rd_wstrb <= wstrb_ram_data;
                axi_rdata <= reg_data_out_pipeline;                
             end // else: !if(~mode_select_reg[0])
          end // else: !if( rst_n == 1'b0 )
     end // always @ ( posedge axi_aclk )
   

                
                
            
   


   // Implement axi_rvalid generation
   // axi_rvalid is asserted for one AXI_ACLK clock cycle when both 
   // S_AXI_ARVALID and axi_arready are asserted. The slave registers 
   // data are available on the axi_rdata bus at this instance. The 
   // assertion of axi_rvalid marks the validity of read data on the 
   // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
   // is deasserted on reset (active low). axi_rresp and axi_rdata are 
   // cleared to zero on reset (active low).  
   always @( posedge axi_aclk )
     begin
        if ( axi_aresetn == 1'b0 )
          begin
             axi_rvalid <= 0;
             axi_rresp  <= 0;
          end 
        else
          begin    
             if (axi_arready && s_axi_arvalid && ~axi_rvalid)
               begin
                  if (~axi_araddr[BRIDGE_MSB] && axi_araddr[BRIDGE_MSB-1] && axi_araddr[BRIDGE_MSB-2]) //WDATA RAM
                    if (wdata_ram_data_ready) begin
                       axi_rvalid <= 1'b1;
                       axi_rresp  <= 2'b0; // 'OKAY' response
                    end
                    else
                      axi_rvalid <= 1'b0;
                  else begin
                     if (axi_araddr[BRIDGE_MSB] && ~axi_araddr[BRIDGE_MSB-1] && ~axi_araddr[BRIDGE_MSB-2]) //WSTRB RAM
                       if (wstrb_ram_data_ready) begin
                          axi_rvalid <= 1'b1;
                          axi_rresp  <= 2'b0; // 'OKAY' response
                       end
                       else
                         axi_rvalid <= 1'b0;
                     else begin
                        // Valid read data is available at the read data bus
                        axi_rvalid <= 1'b1;
                        axi_rresp  <= 2'b0; // 'OKAY' response
                     end // else: !if(wdata_ram_data_ready)
                  end // if (axi_arready && s_axi_arvalid && ~axi_rvalid)
               end
             else if (axi_rvalid && s_axi_rready)
               begin
                  // Read data is accepted by the master
                  axi_rvalid <= 1'b0;
               end
             
          end // else: !if( axi_aresetn == 1'b0 )
     end // always @ ( posedge axi_aclk )




            data_ram #(
                  .AWIDTH (`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8))), // Address Width
                  .DWIDTH (S_AXI_USR_DATA_WIDTH),  // Data Width
                  .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
                  .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
                  )
            u_wdata_ram (
                         .clk        (axi_aclk), 
                         .rst_a      (~rst_n), 
                         .en_a       (uc2rb_wr_we), 
                         .we_a       (1'b1), // Port A is always Write port
                         .byte_en_a  (uc2rb_wr_bwe),
                         .addr_a     (uc2rb_wr_addr), 
                         .wr_data_a  (uc2rb_wr_data), 
                         .rd_data_a  (), 
                         .OREG_CE_A  (1'b1),                 
                         .rst_b      (~rst_n), 
                         .en_b       (wdata_ram_rd_en), 
                         .we_b       (1'b0), // Port B is alwyas Read port 
                         .addr_b     (wdata_ram_addr), 
                         .rd_data_b  (wdata_ram_data), 
                         .byte_en_b  ({(S_AXI_USR_DATA_WIDTH/8){1'h0}}),
                         .wr_data_b  ({(S_AXI_USR_DATA_WIDTH){1'h0}}), 
                         .OREG_CE_B  (1'b1));




   reg [(`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8)))-1:0] wstrb_ram_addr;
   reg                                                   wstrb_ram_rd_en;


always @(posedge axi_aclk)
  begin
      if ( ~rst_n)
          begin
             wstrb_ram_addr   <= 'h0;     
          end
      else begin
         if (~mode_select_reg[0]) begin
            if (axi_araddr[BRIDGE_MSB] && ~axi_araddr[BRIDGE_MSB-1] && ~axi_araddr[BRIDGE_MSB-2])begin //AXI RD targeted to WSTRB RAM
               if (~wstrb_ram_rd_en) begin
                  if (arvalid_pending_pulse)begin
                     wstrb_ram_rd_en <= 1'b1;
                     if (S_AXI_USR_DATA_WIDTH == 128)
                       wstrb_ram_addr <= axi_araddr[S_AXI_ADDR_WIDTH-1:4];
                     else if (S_AXI_USR_DATA_WIDTH == 64)
                       wstrb_ram_addr <= axi_araddr[S_AXI_ADDR_WIDTH-1:3];
                     else if (S_AXI_USR_DATA_WIDTH == 32)                    
                       wstrb_ram_addr <= axi_araddr[S_AXI_ADDR_WIDTH-1:2];
                  end
                  else begin
                     wstrb_ram_addr   <= 'h0;
                     wstrb_ram_rd_en  <= 1'b0;
                  end // else: !if(arvalid_pending_pulse)
               end // if (~wstrb_ram_rd_en)
               else begin
                  wstrb_ram_addr   <= 'h0;
                  wstrb_ram_rd_en  <= 1'b0;
               end // else: !if(~wstrb_ram_rd_en)
            end 
            else begin
                  wstrb_ram_addr   <= 'h0;
                  wstrb_ram_rd_en  <= 1'b0;
            end // else: !if(~axi_araddr[16] && axi_araddr[15] && ~axi_araddr[14])
         end
         else begin
            wstrb_ram_addr   <= hm2rb_rd_addr;
            wstrb_ram_rd_en  <= 1'b1;
         end // else: !if(~mode_select_reg[0])
      end // else: !if( ~rst_n)
  end // always @ (posedge axi_aclk)
   



   
   always @( posedge axi_aclk )
     begin
        if ( rst_n == 1'b0 )
          begin
             wstrb_ram_data_ready  <= 0;
             wstrb_ram_data_ready_1  <= 0;
             wstrb_ram_data_ready_2  <= 0;
          end 
        else
          if (axi_araddr[BRIDGE_MSB] && ~axi_araddr[BRIDGE_MSB-1] && ~axi_araddr[BRIDGE_MSB-2]) begin
             wstrb_ram_data_ready_1 <= wstrb_ram_rd_en;
             wstrb_ram_data_ready_2 <= wstrb_ram_data_ready_1;
             wstrb_ram_data_ready <= wstrb_ram_data_ready_2;
          end
          else begin
             wstrb_ram_data_ready  <= 0;
             wstrb_ram_data_ready_1  <= 0;
             wstrb_ram_data_ready_2  <= 0;
          end
     end // always @ ( posedge axi_aclk )
   




   strb_ram #(
         .AWIDTH (`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8))), // Address Width
         .DWIDTH ((S_AXI_USR_DATA_WIDTH/8)),  // Data Width
         .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
         .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
         )
   u_wstrb_ram (
                .clk        (axi_aclk), 
                .rst_a      (~rst_n), 
                .en_a       (uc2rb_wr_we), 
                .we_a       (1'b1), // Port A is always Write port
                .nibble_en_a  ({(S_AXI_USR_DATA_WIDTH/32){1'b1}}),
                .addr_a     (uc2rb_wr_addr), 
                .wr_data_a  (uc2rb_wr_wstrb), 
                .rd_data_a  ( ), 
                .OREG_CE_A  (1'b1),                 
                .rst_b      (~rst_n), 
                .en_b       (wstrb_ram_rd_en), 
                .we_b       (1'b0), // Port B is alwyas Read port 
                .addr_b     (wstrb_ram_addr), 
                .rd_data_b  (wstrb_ram_data), 
                .nibble_en_b({(S_AXI_USR_DATA_WIDTH/32){1'h0}}),   //({ ((S_AXI_USR_DATA_WIDTH/8)/4) {1'h0}}),
                .wr_data_b  ({(S_AXI_USR_DATA_WIDTH/8){1'h0}}), 
                .OREG_CE_B  (1'b1));



// RD DATA RAM
reg rdata_ram_we;
reg [(`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8)))-1:0] rdata_ram_addr;
reg [S_AXI_USR_DATA_WIDTH-1:0] rdata_ram_data;
reg [(S_AXI_USR_DATA_WIDTH/8) -1:0] rdata_ram_bwe;
   
always @(posedge axi_aclk)
  begin
      if ( ~rst_n)
          begin
             rdata_ram_we   <= 'h0;     
             rdata_ram_addr <= 'h0;     
             rdata_ram_data <= 'h0;
             rdata_ram_bwe  <= 'h0;
          end
      else begin
         if (~mode_select_reg[0]) begin
            if (reg_wr_en) begin
               if (~axi_awaddr[BRIDGE_MSB] && axi_awaddr[BRIDGE_MSB-1] && ~axi_awaddr[BRIDGE_MSB-2])begin //AXI WR targeted to RD DATA RAM
                  rdata_ram_we <= 1'b1;
                  if (S_AXI_USR_DATA_WIDTH == 128)begin
                     rdata_ram_addr <= axi_awaddr[S_AXI_ADDR_WIDTH-1:4];
                     rdata_ram_data <= {4{s_axi_wdata}};
                     rdata_ram_bwe <= { ({4{axi_awaddr[3] && axi_awaddr[2]}} & s_axi_wstrb) , ({4{axi_awaddr[3] && ~axi_awaddr[2]}} & s_axi_wstrb) , ({4{~axi_awaddr[3] && axi_awaddr[2]}} & s_axi_wstrb) , ({4{~axi_awaddr[3] && ~axi_awaddr[2]}} & s_axi_wstrb) };
                  end
                  else if (S_AXI_USR_DATA_WIDTH == 64)begin
                     rdata_ram_addr <= axi_awaddr[S_AXI_ADDR_WIDTH-1:3];
                     rdata_ram_data <= {2{s_axi_wdata}};
                     rdata_ram_bwe  <= {({4{axi_awaddr[2]}} & s_axi_wstrb),({4{~axi_awaddr[2]}} & s_axi_wstrb)};
                  end
                  else if (S_AXI_USR_DATA_WIDTH == 32)begin
                     rdata_ram_addr <= axi_awaddr[S_AXI_ADDR_WIDTH-1:2];
                     rdata_ram_data <= s_axi_wdata;
                     rdata_ram_bwe  <= s_axi_wstrb;
                  end
               end
               else begin
                  rdata_ram_we <= 1'b0;
                  rdata_ram_addr <= 'h0;     
                  rdata_ram_data <= 'h0;
                  rdata_ram_bwe  <= 'h0;
               end // 
            end            
            else begin 
               rdata_ram_we <= 1'b0;
               rdata_ram_addr <= 'h0;     
               rdata_ram_data <= 'h0;
               rdata_ram_bwe  <= 'h0;
            end // if (reg_wr_en)
         end
         
         else begin
            rdata_ram_we   <= hm2rb_wr_we;     
            rdata_ram_bwe  <= hm2rb_wr_bwe;
            rdata_ram_addr <= hm2rb_wr_addr;     
            rdata_ram_data <= hm2rb_wr_data;
         end // else: !if(reg_wr_en)
      end // else: !if( ~rst_n)
  end // always @ (posedge axi_aclk)
   
   
// Registering uc2rb_rd_addr
   reg [(`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8)))-1:0] uc2rb_rd_addr_reg;

   always @( posedge axi_aclk )
     begin
        if (~rst_n)
          uc2rb_rd_addr_reg <= 'h0;
        else 
          uc2rb_rd_addr_reg <= uc2rb_rd_addr;
     end

               data_ram #(
                  .AWIDTH (`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8))), // Address Width
                  .DWIDTH (S_AXI_USR_DATA_WIDTH),  // Data Width
                  .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
                  .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
                  )
            u_rdata_ram (
                         .clk        (axi_aclk), 
                         .rst_a      (~rst_n), 
                         .en_a       (rdata_ram_we), 
                         .we_a       (1'b1), // Port A is always Write port
                         .byte_en_a  (rdata_ram_bwe),
                         .addr_a     (rdata_ram_addr), 
                         .wr_data_a  (rdata_ram_data), 
                         .rd_data_a  (), 
                         .OREG_CE_A  (1'b1),                 
                         .rst_b      (~rst_n), 
                         .en_b       (1'b1), 
                         .we_b       (1'b0), // Port B is alwyas Read port 
                         .addr_b     (uc2rb_rd_addr_reg), 
                         .rd_data_b  (rb2uc_rd_data), 
                         .byte_en_b  ({(S_AXI_USR_DATA_WIDTH/8){1'h0}}),
                         .wr_data_b  ({(S_AXI_USR_DATA_WIDTH){1'h0}}), 
                         .OREG_CE_B  (1'b1));

   
       
    endmodule // regs_slave
    
/* regs_slave.v ends here */
