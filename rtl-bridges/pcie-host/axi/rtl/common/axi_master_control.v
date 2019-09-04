
/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Alok Mistry.
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
 *
 * Description: 
 *  axi_master_control is a generic AXI Mastre module used as Host Master
 *  and User Master using Parameter RTL_USE_MODE= 1 or 0 respectively.
 *
 */


`include "defines_common.vh"
module axi_master_control #(
                            parameter M_AXI_USR_ADDR_WIDTH         =    64,    
                            parameter M_AXI_USR_DATA_WIDTH         =    128, //Allowed values : 32,64,128
                            parameter M_AXI_USR_ID_WIDTH           =    16, //Allowed values : 1-16  
                            parameter M_AXI_USR_AWUSER_WIDTH         =    32, //Allowed values : 1-32
			    parameter M_AXI_USR_WUSER_WIDTH         =    32, //Allowed values : 1-32
			    parameter M_AXI_USR_BUSER_WIDTH         =    32, //Allowed values : 1-32
			    parameter M_AXI_USR_ARUSER_WIDTH         =    32, //Allowed values : 1-32
			    parameter M_AXI_USR_RUSER_WIDTH         =    32, //Allowed values : 1-32
			    parameter M_AXI_USR_LEN_WIDTH          = 8,
                            parameter RAM_SIZE                     =   16384, // Size of RAM in Bytes
                            parameter MAX_DESC                     =   16,

			    // RTL USE MODE if = 0 - This module will act
			    // as UM Bridge                            
			    // if = 1 Thsi module will act as
			    // Host master
			    parameter RTL_USE_MODE		    =   0,
			    // When RTL USE_MODE =1, providing information to HM about
			    // UC Bridge configuration
			    parameter UC_AXI_DATA_WIDTH  = M_AXI_USR_DATA_WIDTH,
			    parameter EN_INTFM_AXI4  = 1,
			    parameter EN_INTFM_AXI4LITE = 0,
			    parameter EN_INTFM_AXI3 = 0

                            )
   (
	
	
	
    input 						      axi_aclk,
    input 						      axi_aresetn,
    
    // Data Ram Interface 
    //read port of WR DataRam
    output [(`CLOG2(RAM_SIZE/(UC_AXI_DATA_WIDTH/8)))-1:0]     uc2rb_rd_addr, 
    output [(`CLOG2(MAX_DESC))-1:0] 			      uc2rb_rd_addr_desc_id,
    input [M_AXI_USR_DATA_WIDTH-1:0] 			      rb2uc_rd_data,
    input [(M_AXI_USR_DATA_WIDTH/8 -1):0] 		      rb2uc_rd_wstrb, 
    // Write port of RD DataRam
    output reg 						      uc2rb_wr_we, 
    output reg [(M_AXI_USR_DATA_WIDTH/8 -1):0] 		      uc2rb_wr_bwe, 
    output reg [(`CLOG2(RAM_SIZE/(UC_AXI_DATA_WIDTH/8)))-1:0] uc2rb_wr_addr, 
    output reg [M_AXI_USR_DATA_WIDTH-1:0] 		      uc2rb_wr_data,
	// uc2rb_wr_desc_id indicates that the data sent on *wr_data port
	// belongs to which descriptor number ( used in case of HM use case where data coming
	// from host can be WDATA or WSTRB)
    output reg [(`CLOG2(MAX_DESC))-1:0] 		      uc2rb_wr_desc_id, 

    //Host Master Interface (Mode 1)
    output [MAX_DESC-1:0] 				      uc2hm_trig,
    input [MAX_DESC-1:0] 				      hm2uc_done,
    
    // Registers from Reg Block
    input [31:0] 					      version_reg ,
    input [31:0] 					      bridge_type_reg ,
    input [31:0] 					      mode_select_reg ,
    input [31:0] 					      reset_reg ,
    input [31:0] 					      intr_h2c_0_reg ,
    input [31:0] 					      intr_h2c_1_reg ,
    input [31:0] 					      intr_c2h_0_status_reg ,
    input [31:0] 					      intr_c2h_1_status_reg ,
    input [31:0] 					      c2h_gpio_0_status_reg ,
    input [31:0] 					      c2h_gpio_1_status_reg ,
    input [31:0] 					      c2h_gpio_2_status_reg ,
    input [31:0] 					      c2h_gpio_3_status_reg ,
    input [31:0] 					      c2h_gpio_4_status_reg ,
    input [31:0] 					      c2h_gpio_5_status_reg ,
    input [31:0] 					      c2h_gpio_6_status_reg ,
    input [31:0] 					      c2h_gpio_7_status_reg ,
    input [31:0] 					      c2h_gpio_8_status_reg ,
    input [31:0] 					      c2h_gpio_9_status_reg ,
    input [31:0] 					      c2h_gpio_10_status_reg ,
    input [31:0] 					      c2h_gpio_11_status_reg ,
    input [31:0] 					      c2h_gpio_12_status_reg ,
    input [31:0] 					      c2h_gpio_13_status_reg ,
    input [31:0] 					      c2h_gpio_14_status_reg ,
    input [31:0] 					      c2h_gpio_15_status_reg ,
    input [31:0] 					      axi_bridge_config_reg ,
    input [31:0] 					      axi_max_desc_reg ,
    input [31:0] 					      intr_status_reg ,
    input [31:0] 					      intr_error_status_reg ,
    input [31:0] 					      intr_error_clear_reg ,
    input [31:0] 					      intr_error_enable_reg ,
    input [31:0] 					      ownership_reg ,
    input [31:0] 					      ownership_flip_reg ,
    input [31:0] 					      status_resp_reg ,
    input [31:0] 					      intr_comp_status_reg ,
    input [31:0] 					      intr_comp_clear_reg ,
    input [31:0] 					      intr_comp_enable_reg ,
    input [31:0] 					      desc_0_txn_type_reg ,
    input [31:0] 					      desc_0_size_reg ,
    input [31:0] 					      desc_0_data_offset_reg ,
    input [31:0] 					      desc_0_data_host_addr_0_reg ,
    input [31:0] 					      desc_0_data_host_addr_1_reg ,
    input [31:0] 					      desc_0_data_host_addr_2_reg ,
    input [31:0] 					      desc_0_data_host_addr_3_reg ,
    input [31:0] 					      desc_0_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_0_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_0_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_0_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_0_axsize_reg ,
    input [31:0] 					      desc_0_attr_reg ,
    input [31:0] 					      desc_0_axaddr_0_reg ,
    input [31:0] 					      desc_0_axaddr_1_reg ,
    input [31:0] 					      desc_0_axaddr_2_reg ,
    input [31:0] 					      desc_0_axaddr_3_reg ,
    input [31:0] 					      desc_0_axid_0_reg ,
    input [31:0] 					      desc_0_axid_1_reg ,
    input [31:0] 					      desc_0_axid_2_reg ,
    input [31:0] 					      desc_0_axid_3_reg ,
    input [31:0] 					      desc_0_axuser_0_reg ,
    input [31:0] 					      desc_0_axuser_1_reg ,
    input [31:0] 					      desc_0_axuser_2_reg ,
    input [31:0] 					      desc_0_axuser_3_reg ,
    input [31:0] 					      desc_0_axuser_4_reg ,
    input [31:0] 					      desc_0_axuser_5_reg ,
    input [31:0] 					      desc_0_axuser_6_reg ,
    input [31:0] 					      desc_0_axuser_7_reg ,
    input [31:0] 					      desc_0_axuser_8_reg ,
    input [31:0] 					      desc_0_axuser_9_reg ,
    input [31:0] 					      desc_0_axuser_10_reg ,
    input [31:0] 					      desc_0_axuser_11_reg ,
    input [31:0] 					      desc_0_axuser_12_reg ,
    input [31:0] 					      desc_0_axuser_13_reg ,
    input [31:0] 					      desc_0_axuser_14_reg ,
    input [31:0] 					      desc_0_axuser_15_reg ,
    input [31:0] 					      desc_0_xuser_0_reg ,
    input [31:0] 					      desc_0_xuser_1_reg ,
    input [31:0] 					      desc_0_xuser_2_reg ,
    input [31:0] 					      desc_0_xuser_3_reg ,
    input [31:0] 					      desc_0_xuser_4_reg ,
    input [31:0] 					      desc_0_xuser_5_reg ,
    input [31:0] 					      desc_0_xuser_6_reg ,
    input [31:0] 					      desc_0_xuser_7_reg ,
    input [31:0] 					      desc_0_xuser_8_reg ,
    input [31:0] 					      desc_0_xuser_9_reg ,
    input [31:0] 					      desc_0_xuser_10_reg ,
    input [31:0] 					      desc_0_xuser_11_reg ,
    input [31:0] 					      desc_0_xuser_12_reg ,
    input [31:0] 					      desc_0_xuser_13_reg ,
    input [31:0] 					      desc_0_xuser_14_reg ,
    input [31:0] 					      desc_0_xuser_15_reg ,
    input [31:0] 					      desc_0_wuser_0_reg ,
    input [31:0] 					      desc_0_wuser_1_reg ,
    input [31:0] 					      desc_0_wuser_2_reg ,
    input [31:0] 					      desc_0_wuser_3_reg ,
    input [31:0] 					      desc_0_wuser_4_reg ,
    input [31:0] 					      desc_0_wuser_5_reg ,
    input [31:0] 					      desc_0_wuser_6_reg ,
    input [31:0] 					      desc_0_wuser_7_reg ,
    input [31:0] 					      desc_0_wuser_8_reg ,
    input [31:0] 					      desc_0_wuser_9_reg ,
    input [31:0] 					      desc_0_wuser_10_reg ,
    input [31:0] 					      desc_0_wuser_11_reg ,
    input [31:0] 					      desc_0_wuser_12_reg ,
    input [31:0] 					      desc_0_wuser_13_reg ,
    input [31:0] 					      desc_0_wuser_14_reg ,
    input [31:0] 					      desc_0_wuser_15_reg ,
    input [31:0] 					      desc_1_txn_type_reg ,
    input [31:0] 					      desc_1_size_reg ,
    input [31:0] 					      desc_1_data_offset_reg ,
    input [31:0] 					      desc_1_data_host_addr_0_reg ,
    input [31:0] 					      desc_1_data_host_addr_1_reg ,
    input [31:0] 					      desc_1_data_host_addr_2_reg ,
    input [31:0] 					      desc_1_data_host_addr_3_reg ,
    input [31:0] 					      desc_1_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_1_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_1_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_1_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_1_axsize_reg ,
    input [31:0] 					      desc_1_attr_reg ,
    input [31:0] 					      desc_1_axaddr_0_reg ,
    input [31:0] 					      desc_1_axaddr_1_reg ,
    input [31:0] 					      desc_1_axaddr_2_reg ,
    input [31:0] 					      desc_1_axaddr_3_reg ,
    input [31:0] 					      desc_1_axid_0_reg ,
    input [31:0] 					      desc_1_axid_1_reg ,
    input [31:0] 					      desc_1_axid_2_reg ,
    input [31:0] 					      desc_1_axid_3_reg ,
    input [31:0] 					      desc_1_axuser_0_reg ,
    input [31:0] 					      desc_1_axuser_1_reg ,
    input [31:0] 					      desc_1_axuser_2_reg ,
    input [31:0] 					      desc_1_axuser_3_reg ,
    input [31:0] 					      desc_1_axuser_4_reg ,
    input [31:0] 					      desc_1_axuser_5_reg ,
    input [31:0] 					      desc_1_axuser_6_reg ,
    input [31:0] 					      desc_1_axuser_7_reg ,
    input [31:0] 					      desc_1_axuser_8_reg ,
    input [31:0] 					      desc_1_axuser_9_reg ,
    input [31:0] 					      desc_1_axuser_10_reg ,
    input [31:0] 					      desc_1_axuser_11_reg ,
    input [31:0] 					      desc_1_axuser_12_reg ,
    input [31:0] 					      desc_1_axuser_13_reg ,
    input [31:0] 					      desc_1_axuser_14_reg ,
    input [31:0] 					      desc_1_axuser_15_reg ,
    input [31:0] 					      desc_1_xuser_0_reg ,
    input [31:0] 					      desc_1_xuser_1_reg ,
    input [31:0] 					      desc_1_xuser_2_reg ,
    input [31:0] 					      desc_1_xuser_3_reg ,
    input [31:0] 					      desc_1_xuser_4_reg ,
    input [31:0] 					      desc_1_xuser_5_reg ,
    input [31:0] 					      desc_1_xuser_6_reg ,
    input [31:0] 					      desc_1_xuser_7_reg ,
    input [31:0] 					      desc_1_xuser_8_reg ,
    input [31:0] 					      desc_1_xuser_9_reg ,
    input [31:0] 					      desc_1_xuser_10_reg ,
    input [31:0] 					      desc_1_xuser_11_reg ,
    input [31:0] 					      desc_1_xuser_12_reg ,
    input [31:0] 					      desc_1_xuser_13_reg ,
    input [31:0] 					      desc_1_xuser_14_reg ,
    input [31:0] 					      desc_1_xuser_15_reg ,
    input [31:0] 					      desc_1_wuser_0_reg ,
    input [31:0] 					      desc_1_wuser_1_reg ,
    input [31:0] 					      desc_1_wuser_2_reg ,
    input [31:0] 					      desc_1_wuser_3_reg ,
    input [31:0] 					      desc_1_wuser_4_reg ,
    input [31:0] 					      desc_1_wuser_5_reg ,
    input [31:0] 					      desc_1_wuser_6_reg ,
    input [31:0] 					      desc_1_wuser_7_reg ,
    input [31:0] 					      desc_1_wuser_8_reg ,
    input [31:0] 					      desc_1_wuser_9_reg ,
    input [31:0] 					      desc_1_wuser_10_reg ,
    input [31:0] 					      desc_1_wuser_11_reg ,
    input [31:0] 					      desc_1_wuser_12_reg ,
    input [31:0] 					      desc_1_wuser_13_reg ,
    input [31:0] 					      desc_1_wuser_14_reg ,
    input [31:0] 					      desc_1_wuser_15_reg ,
    input [31:0] 					      desc_2_txn_type_reg ,
    input [31:0] 					      desc_2_size_reg ,
    input [31:0] 					      desc_2_data_offset_reg ,
    input [31:0] 					      desc_2_data_host_addr_0_reg ,
    input [31:0] 					      desc_2_data_host_addr_1_reg ,
    input [31:0] 					      desc_2_data_host_addr_2_reg ,
    input [31:0] 					      desc_2_data_host_addr_3_reg ,
    input [31:0] 					      desc_2_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_2_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_2_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_2_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_2_axsize_reg ,
    input [31:0] 					      desc_2_attr_reg ,
    input [31:0] 					      desc_2_axaddr_0_reg ,
    input [31:0] 					      desc_2_axaddr_1_reg ,
    input [31:0] 					      desc_2_axaddr_2_reg ,
    input [31:0] 					      desc_2_axaddr_3_reg ,
    input [31:0] 					      desc_2_axid_0_reg ,
    input [31:0] 					      desc_2_axid_1_reg ,
    input [31:0] 					      desc_2_axid_2_reg ,
    input [31:0] 					      desc_2_axid_3_reg ,
    input [31:0] 					      desc_2_axuser_0_reg ,
    input [31:0] 					      desc_2_axuser_1_reg ,
    input [31:0] 					      desc_2_axuser_2_reg ,
    input [31:0] 					      desc_2_axuser_3_reg ,
    input [31:0] 					      desc_2_axuser_4_reg ,
    input [31:0] 					      desc_2_axuser_5_reg ,
    input [31:0] 					      desc_2_axuser_6_reg ,
    input [31:0] 					      desc_2_axuser_7_reg ,
    input [31:0] 					      desc_2_axuser_8_reg ,
    input [31:0] 					      desc_2_axuser_9_reg ,
    input [31:0] 					      desc_2_axuser_10_reg ,
    input [31:0] 					      desc_2_axuser_11_reg ,
    input [31:0] 					      desc_2_axuser_12_reg ,
    input [31:0] 					      desc_2_axuser_13_reg ,
    input [31:0] 					      desc_2_axuser_14_reg ,
    input [31:0] 					      desc_2_axuser_15_reg ,
    input [31:0] 					      desc_2_xuser_0_reg ,
    input [31:0] 					      desc_2_xuser_1_reg ,
    input [31:0] 					      desc_2_xuser_2_reg ,
    input [31:0] 					      desc_2_xuser_3_reg ,
    input [31:0] 					      desc_2_xuser_4_reg ,
    input [31:0] 					      desc_2_xuser_5_reg ,
    input [31:0] 					      desc_2_xuser_6_reg ,
    input [31:0] 					      desc_2_xuser_7_reg ,
    input [31:0] 					      desc_2_xuser_8_reg ,
    input [31:0] 					      desc_2_xuser_9_reg ,
    input [31:0] 					      desc_2_xuser_10_reg ,
    input [31:0] 					      desc_2_xuser_11_reg ,
    input [31:0] 					      desc_2_xuser_12_reg ,
    input [31:0] 					      desc_2_xuser_13_reg ,
    input [31:0] 					      desc_2_xuser_14_reg ,
    input [31:0] 					      desc_2_xuser_15_reg ,
    input [31:0] 					      desc_2_wuser_0_reg ,
    input [31:0] 					      desc_2_wuser_1_reg ,
    input [31:0] 					      desc_2_wuser_2_reg ,
    input [31:0] 					      desc_2_wuser_3_reg ,
    input [31:0] 					      desc_2_wuser_4_reg ,
    input [31:0] 					      desc_2_wuser_5_reg ,
    input [31:0] 					      desc_2_wuser_6_reg ,
    input [31:0] 					      desc_2_wuser_7_reg ,
    input [31:0] 					      desc_2_wuser_8_reg ,
    input [31:0] 					      desc_2_wuser_9_reg ,
    input [31:0] 					      desc_2_wuser_10_reg ,
    input [31:0] 					      desc_2_wuser_11_reg ,
    input [31:0] 					      desc_2_wuser_12_reg ,
    input [31:0] 					      desc_2_wuser_13_reg ,
    input [31:0] 					      desc_2_wuser_14_reg ,
    input [31:0] 					      desc_2_wuser_15_reg ,
    input [31:0] 					      desc_3_txn_type_reg ,
    input [31:0] 					      desc_3_size_reg ,
    input [31:0] 					      desc_3_data_offset_reg ,
    input [31:0] 					      desc_3_data_host_addr_0_reg ,
    input [31:0] 					      desc_3_data_host_addr_1_reg ,
    input [31:0] 					      desc_3_data_host_addr_2_reg ,
    input [31:0] 					      desc_3_data_host_addr_3_reg ,
    input [31:0] 					      desc_3_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_3_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_3_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_3_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_3_axsize_reg ,
    input [31:0] 					      desc_3_attr_reg ,
    input [31:0] 					      desc_3_axaddr_0_reg ,
    input [31:0] 					      desc_3_axaddr_1_reg ,
    input [31:0] 					      desc_3_axaddr_2_reg ,
    input [31:0] 					      desc_3_axaddr_3_reg ,
    input [31:0] 					      desc_3_axid_0_reg ,
    input [31:0] 					      desc_3_axid_1_reg ,
    input [31:0] 					      desc_3_axid_2_reg ,
    input [31:0] 					      desc_3_axid_3_reg ,
    input [31:0] 					      desc_3_axuser_0_reg ,
    input [31:0] 					      desc_3_axuser_1_reg ,
    input [31:0] 					      desc_3_axuser_2_reg ,
    input [31:0] 					      desc_3_axuser_3_reg ,
    input [31:0] 					      desc_3_axuser_4_reg ,
    input [31:0] 					      desc_3_axuser_5_reg ,
    input [31:0] 					      desc_3_axuser_6_reg ,
    input [31:0] 					      desc_3_axuser_7_reg ,
    input [31:0] 					      desc_3_axuser_8_reg ,
    input [31:0] 					      desc_3_axuser_9_reg ,
    input [31:0] 					      desc_3_axuser_10_reg ,
    input [31:0] 					      desc_3_axuser_11_reg ,
    input [31:0] 					      desc_3_axuser_12_reg ,
    input [31:0] 					      desc_3_axuser_13_reg ,
    input [31:0] 					      desc_3_axuser_14_reg ,
    input [31:0] 					      desc_3_axuser_15_reg ,
    input [31:0] 					      desc_3_xuser_0_reg ,
    input [31:0] 					      desc_3_xuser_1_reg ,
    input [31:0] 					      desc_3_xuser_2_reg ,
    input [31:0] 					      desc_3_xuser_3_reg ,
    input [31:0] 					      desc_3_xuser_4_reg ,
    input [31:0] 					      desc_3_xuser_5_reg ,
    input [31:0] 					      desc_3_xuser_6_reg ,
    input [31:0] 					      desc_3_xuser_7_reg ,
    input [31:0] 					      desc_3_xuser_8_reg ,
    input [31:0] 					      desc_3_xuser_9_reg ,
    input [31:0] 					      desc_3_xuser_10_reg ,
    input [31:0] 					      desc_3_xuser_11_reg ,
    input [31:0] 					      desc_3_xuser_12_reg ,
    input [31:0] 					      desc_3_xuser_13_reg ,
    input [31:0] 					      desc_3_xuser_14_reg ,
    input [31:0] 					      desc_3_xuser_15_reg ,
    input [31:0] 					      desc_3_wuser_0_reg ,
    input [31:0] 					      desc_3_wuser_1_reg ,
    input [31:0] 					      desc_3_wuser_2_reg ,
    input [31:0] 					      desc_3_wuser_3_reg ,
    input [31:0] 					      desc_3_wuser_4_reg ,
    input [31:0] 					      desc_3_wuser_5_reg ,
    input [31:0] 					      desc_3_wuser_6_reg ,
    input [31:0] 					      desc_3_wuser_7_reg ,
    input [31:0] 					      desc_3_wuser_8_reg ,
    input [31:0] 					      desc_3_wuser_9_reg ,
    input [31:0] 					      desc_3_wuser_10_reg ,
    input [31:0] 					      desc_3_wuser_11_reg ,
    input [31:0] 					      desc_3_wuser_12_reg ,
    input [31:0] 					      desc_3_wuser_13_reg ,
    input [31:0] 					      desc_3_wuser_14_reg ,
    input [31:0] 					      desc_3_wuser_15_reg ,
    input [31:0] 					      desc_4_txn_type_reg ,
    input [31:0] 					      desc_4_size_reg ,
    input [31:0] 					      desc_4_data_offset_reg ,
    input [31:0] 					      desc_4_data_host_addr_0_reg ,
    input [31:0] 					      desc_4_data_host_addr_1_reg ,
    input [31:0] 					      desc_4_data_host_addr_2_reg ,
    input [31:0] 					      desc_4_data_host_addr_3_reg ,
    input [31:0] 					      desc_4_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_4_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_4_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_4_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_4_axsize_reg ,
    input [31:0] 					      desc_4_attr_reg ,
    input [31:0] 					      desc_4_axaddr_0_reg ,
    input [31:0] 					      desc_4_axaddr_1_reg ,
    input [31:0] 					      desc_4_axaddr_2_reg ,
    input [31:0] 					      desc_4_axaddr_3_reg ,
    input [31:0] 					      desc_4_axid_0_reg ,
    input [31:0] 					      desc_4_axid_1_reg ,
    input [31:0] 					      desc_4_axid_2_reg ,
    input [31:0] 					      desc_4_axid_3_reg ,
    input [31:0] 					      desc_4_axuser_0_reg ,
    input [31:0] 					      desc_4_axuser_1_reg ,
    input [31:0] 					      desc_4_axuser_2_reg ,
    input [31:0] 					      desc_4_axuser_3_reg ,
    input [31:0] 					      desc_4_axuser_4_reg ,
    input [31:0] 					      desc_4_axuser_5_reg ,
    input [31:0] 					      desc_4_axuser_6_reg ,
    input [31:0] 					      desc_4_axuser_7_reg ,
    input [31:0] 					      desc_4_axuser_8_reg ,
    input [31:0] 					      desc_4_axuser_9_reg ,
    input [31:0] 					      desc_4_axuser_10_reg ,
    input [31:0] 					      desc_4_axuser_11_reg ,
    input [31:0] 					      desc_4_axuser_12_reg ,
    input [31:0] 					      desc_4_axuser_13_reg ,
    input [31:0] 					      desc_4_axuser_14_reg ,
    input [31:0] 					      desc_4_axuser_15_reg ,
    input [31:0] 					      desc_4_xuser_0_reg ,
    input [31:0] 					      desc_4_xuser_1_reg ,
    input [31:0] 					      desc_4_xuser_2_reg ,
    input [31:0] 					      desc_4_xuser_3_reg ,
    input [31:0] 					      desc_4_xuser_4_reg ,
    input [31:0] 					      desc_4_xuser_5_reg ,
    input [31:0] 					      desc_4_xuser_6_reg ,
    input [31:0] 					      desc_4_xuser_7_reg ,
    input [31:0] 					      desc_4_xuser_8_reg ,
    input [31:0] 					      desc_4_xuser_9_reg ,
    input [31:0] 					      desc_4_xuser_10_reg ,
    input [31:0] 					      desc_4_xuser_11_reg ,
    input [31:0] 					      desc_4_xuser_12_reg ,
    input [31:0] 					      desc_4_xuser_13_reg ,
    input [31:0] 					      desc_4_xuser_14_reg ,
    input [31:0] 					      desc_4_xuser_15_reg ,
    input [31:0] 					      desc_4_wuser_0_reg ,
    input [31:0] 					      desc_4_wuser_1_reg ,
    input [31:0] 					      desc_4_wuser_2_reg ,
    input [31:0] 					      desc_4_wuser_3_reg ,
    input [31:0] 					      desc_4_wuser_4_reg ,
    input [31:0] 					      desc_4_wuser_5_reg ,
    input [31:0] 					      desc_4_wuser_6_reg ,
    input [31:0] 					      desc_4_wuser_7_reg ,
    input [31:0] 					      desc_4_wuser_8_reg ,
    input [31:0] 					      desc_4_wuser_9_reg ,
    input [31:0] 					      desc_4_wuser_10_reg ,
    input [31:0] 					      desc_4_wuser_11_reg ,
    input [31:0] 					      desc_4_wuser_12_reg ,
    input [31:0] 					      desc_4_wuser_13_reg ,
    input [31:0] 					      desc_4_wuser_14_reg ,
    input [31:0] 					      desc_4_wuser_15_reg ,
    input [31:0] 					      desc_5_txn_type_reg ,
    input [31:0] 					      desc_5_size_reg ,
    input [31:0] 					      desc_5_data_offset_reg ,
    input [31:0] 					      desc_5_data_host_addr_0_reg ,
    input [31:0] 					      desc_5_data_host_addr_1_reg ,
    input [31:0] 					      desc_5_data_host_addr_2_reg ,
    input [31:0] 					      desc_5_data_host_addr_3_reg ,
    input [31:0] 					      desc_5_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_5_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_5_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_5_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_5_axsize_reg ,
    input [31:0] 					      desc_5_attr_reg ,
    input [31:0] 					      desc_5_axaddr_0_reg ,
    input [31:0] 					      desc_5_axaddr_1_reg ,
    input [31:0] 					      desc_5_axaddr_2_reg ,
    input [31:0] 					      desc_5_axaddr_3_reg ,
    input [31:0] 					      desc_5_axid_0_reg ,
    input [31:0] 					      desc_5_axid_1_reg ,
    input [31:0] 					      desc_5_axid_2_reg ,
    input [31:0] 					      desc_5_axid_3_reg ,
    input [31:0] 					      desc_5_axuser_0_reg ,
    input [31:0] 					      desc_5_axuser_1_reg ,
    input [31:0] 					      desc_5_axuser_2_reg ,
    input [31:0] 					      desc_5_axuser_3_reg ,
    input [31:0] 					      desc_5_axuser_4_reg ,
    input [31:0] 					      desc_5_axuser_5_reg ,
    input [31:0] 					      desc_5_axuser_6_reg ,
    input [31:0] 					      desc_5_axuser_7_reg ,
    input [31:0] 					      desc_5_axuser_8_reg ,
    input [31:0] 					      desc_5_axuser_9_reg ,
    input [31:0] 					      desc_5_axuser_10_reg ,
    input [31:0] 					      desc_5_axuser_11_reg ,
    input [31:0] 					      desc_5_axuser_12_reg ,
    input [31:0] 					      desc_5_axuser_13_reg ,
    input [31:0] 					      desc_5_axuser_14_reg ,
    input [31:0] 					      desc_5_axuser_15_reg ,
    input [31:0] 					      desc_5_xuser_0_reg ,
    input [31:0] 					      desc_5_xuser_1_reg ,
    input [31:0] 					      desc_5_xuser_2_reg ,
    input [31:0] 					      desc_5_xuser_3_reg ,
    input [31:0] 					      desc_5_xuser_4_reg ,
    input [31:0] 					      desc_5_xuser_5_reg ,
    input [31:0] 					      desc_5_xuser_6_reg ,
    input [31:0] 					      desc_5_xuser_7_reg ,
    input [31:0] 					      desc_5_xuser_8_reg ,
    input [31:0] 					      desc_5_xuser_9_reg ,
    input [31:0] 					      desc_5_xuser_10_reg ,
    input [31:0] 					      desc_5_xuser_11_reg ,
    input [31:0] 					      desc_5_xuser_12_reg ,
    input [31:0] 					      desc_5_xuser_13_reg ,
    input [31:0] 					      desc_5_xuser_14_reg ,
    input [31:0] 					      desc_5_xuser_15_reg ,
    input [31:0] 					      desc_5_wuser_0_reg ,
    input [31:0] 					      desc_5_wuser_1_reg ,
    input [31:0] 					      desc_5_wuser_2_reg ,
    input [31:0] 					      desc_5_wuser_3_reg ,
    input [31:0] 					      desc_5_wuser_4_reg ,
    input [31:0] 					      desc_5_wuser_5_reg ,
    input [31:0] 					      desc_5_wuser_6_reg ,
    input [31:0] 					      desc_5_wuser_7_reg ,
    input [31:0] 					      desc_5_wuser_8_reg ,
    input [31:0] 					      desc_5_wuser_9_reg ,
    input [31:0] 					      desc_5_wuser_10_reg ,
    input [31:0] 					      desc_5_wuser_11_reg ,
    input [31:0] 					      desc_5_wuser_12_reg ,
    input [31:0] 					      desc_5_wuser_13_reg ,
    input [31:0] 					      desc_5_wuser_14_reg ,
    input [31:0] 					      desc_5_wuser_15_reg ,
    input [31:0] 					      desc_6_txn_type_reg ,
    input [31:0] 					      desc_6_size_reg ,
    input [31:0] 					      desc_6_data_offset_reg ,
    input [31:0] 					      desc_6_data_host_addr_0_reg ,
    input [31:0] 					      desc_6_data_host_addr_1_reg ,
    input [31:0] 					      desc_6_data_host_addr_2_reg ,
    input [31:0] 					      desc_6_data_host_addr_3_reg ,
    input [31:0] 					      desc_6_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_6_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_6_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_6_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_6_axsize_reg ,
    input [31:0] 					      desc_6_attr_reg ,
    input [31:0] 					      desc_6_axaddr_0_reg ,
    input [31:0] 					      desc_6_axaddr_1_reg ,
    input [31:0] 					      desc_6_axaddr_2_reg ,
    input [31:0] 					      desc_6_axaddr_3_reg ,
    input [31:0] 					      desc_6_axid_0_reg ,
    input [31:0] 					      desc_6_axid_1_reg ,
    input [31:0] 					      desc_6_axid_2_reg ,
    input [31:0] 					      desc_6_axid_3_reg ,
    input [31:0] 					      desc_6_axuser_0_reg ,
    input [31:0] 					      desc_6_axuser_1_reg ,
    input [31:0] 					      desc_6_axuser_2_reg ,
    input [31:0] 					      desc_6_axuser_3_reg ,
    input [31:0] 					      desc_6_axuser_4_reg ,
    input [31:0] 					      desc_6_axuser_5_reg ,
    input [31:0] 					      desc_6_axuser_6_reg ,
    input [31:0] 					      desc_6_axuser_7_reg ,
    input [31:0] 					      desc_6_axuser_8_reg ,
    input [31:0] 					      desc_6_axuser_9_reg ,
    input [31:0] 					      desc_6_axuser_10_reg ,
    input [31:0] 					      desc_6_axuser_11_reg ,
    input [31:0] 					      desc_6_axuser_12_reg ,
    input [31:0] 					      desc_6_axuser_13_reg ,
    input [31:0] 					      desc_6_axuser_14_reg ,
    input [31:0] 					      desc_6_axuser_15_reg ,
    input [31:0] 					      desc_6_xuser_0_reg ,
    input [31:0] 					      desc_6_xuser_1_reg ,
    input [31:0] 					      desc_6_xuser_2_reg ,
    input [31:0] 					      desc_6_xuser_3_reg ,
    input [31:0] 					      desc_6_xuser_4_reg ,
    input [31:0] 					      desc_6_xuser_5_reg ,
    input [31:0] 					      desc_6_xuser_6_reg ,
    input [31:0] 					      desc_6_xuser_7_reg ,
    input [31:0] 					      desc_6_xuser_8_reg ,
    input [31:0] 					      desc_6_xuser_9_reg ,
    input [31:0] 					      desc_6_xuser_10_reg ,
    input [31:0] 					      desc_6_xuser_11_reg ,
    input [31:0] 					      desc_6_xuser_12_reg ,
    input [31:0] 					      desc_6_xuser_13_reg ,
    input [31:0] 					      desc_6_xuser_14_reg ,
    input [31:0] 					      desc_6_xuser_15_reg ,
    input [31:0] 					      desc_6_wuser_0_reg ,
    input [31:0] 					      desc_6_wuser_1_reg ,
    input [31:0] 					      desc_6_wuser_2_reg ,
    input [31:0] 					      desc_6_wuser_3_reg ,
    input [31:0] 					      desc_6_wuser_4_reg ,
    input [31:0] 					      desc_6_wuser_5_reg ,
    input [31:0] 					      desc_6_wuser_6_reg ,
    input [31:0] 					      desc_6_wuser_7_reg ,
    input [31:0] 					      desc_6_wuser_8_reg ,
    input [31:0] 					      desc_6_wuser_9_reg ,
    input [31:0] 					      desc_6_wuser_10_reg ,
    input [31:0] 					      desc_6_wuser_11_reg ,
    input [31:0] 					      desc_6_wuser_12_reg ,
    input [31:0] 					      desc_6_wuser_13_reg ,
    input [31:0] 					      desc_6_wuser_14_reg ,
    input [31:0] 					      desc_6_wuser_15_reg ,
    input [31:0] 					      desc_7_txn_type_reg ,
    input [31:0] 					      desc_7_size_reg ,
    input [31:0] 					      desc_7_data_offset_reg ,
    input [31:0] 					      desc_7_data_host_addr_0_reg ,
    input [31:0] 					      desc_7_data_host_addr_1_reg ,
    input [31:0] 					      desc_7_data_host_addr_2_reg ,
    input [31:0] 					      desc_7_data_host_addr_3_reg ,
    input [31:0] 					      desc_7_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_7_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_7_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_7_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_7_axsize_reg ,
    input [31:0] 					      desc_7_attr_reg ,
    input [31:0] 					      desc_7_axaddr_0_reg ,
    input [31:0] 					      desc_7_axaddr_1_reg ,
    input [31:0] 					      desc_7_axaddr_2_reg ,
    input [31:0] 					      desc_7_axaddr_3_reg ,
    input [31:0] 					      desc_7_axid_0_reg ,
    input [31:0] 					      desc_7_axid_1_reg ,
    input [31:0] 					      desc_7_axid_2_reg ,
    input [31:0] 					      desc_7_axid_3_reg ,
    input [31:0] 					      desc_7_axuser_0_reg ,
    input [31:0] 					      desc_7_axuser_1_reg ,
    input [31:0] 					      desc_7_axuser_2_reg ,
    input [31:0] 					      desc_7_axuser_3_reg ,
    input [31:0] 					      desc_7_axuser_4_reg ,
    input [31:0] 					      desc_7_axuser_5_reg ,
    input [31:0] 					      desc_7_axuser_6_reg ,
    input [31:0] 					      desc_7_axuser_7_reg ,
    input [31:0] 					      desc_7_axuser_8_reg ,
    input [31:0] 					      desc_7_axuser_9_reg ,
    input [31:0] 					      desc_7_axuser_10_reg ,
    input [31:0] 					      desc_7_axuser_11_reg ,
    input [31:0] 					      desc_7_axuser_12_reg ,
    input [31:0] 					      desc_7_axuser_13_reg ,
    input [31:0] 					      desc_7_axuser_14_reg ,
    input [31:0] 					      desc_7_axuser_15_reg ,
    input [31:0] 					      desc_7_xuser_0_reg ,
    input [31:0] 					      desc_7_xuser_1_reg ,
    input [31:0] 					      desc_7_xuser_2_reg ,
    input [31:0] 					      desc_7_xuser_3_reg ,
    input [31:0] 					      desc_7_xuser_4_reg ,
    input [31:0] 					      desc_7_xuser_5_reg ,
    input [31:0] 					      desc_7_xuser_6_reg ,
    input [31:0] 					      desc_7_xuser_7_reg ,
    input [31:0] 					      desc_7_xuser_8_reg ,
    input [31:0] 					      desc_7_xuser_9_reg ,
    input [31:0] 					      desc_7_xuser_10_reg ,
    input [31:0] 					      desc_7_xuser_11_reg ,
    input [31:0] 					      desc_7_xuser_12_reg ,
    input [31:0] 					      desc_7_xuser_13_reg ,
    input [31:0] 					      desc_7_xuser_14_reg ,
    input [31:0] 					      desc_7_xuser_15_reg ,
    input [31:0] 					      desc_7_wuser_0_reg ,
    input [31:0] 					      desc_7_wuser_1_reg ,
    input [31:0] 					      desc_7_wuser_2_reg ,
    input [31:0] 					      desc_7_wuser_3_reg ,
    input [31:0] 					      desc_7_wuser_4_reg ,
    input [31:0] 					      desc_7_wuser_5_reg ,
    input [31:0] 					      desc_7_wuser_6_reg ,
    input [31:0] 					      desc_7_wuser_7_reg ,
    input [31:0] 					      desc_7_wuser_8_reg ,
    input [31:0] 					      desc_7_wuser_9_reg ,
    input [31:0] 					      desc_7_wuser_10_reg ,
    input [31:0] 					      desc_7_wuser_11_reg ,
    input [31:0] 					      desc_7_wuser_12_reg ,
    input [31:0] 					      desc_7_wuser_13_reg ,
    input [31:0] 					      desc_7_wuser_14_reg ,
    input [31:0] 					      desc_7_wuser_15_reg ,
    input [31:0] 					      desc_8_txn_type_reg ,
    input [31:0] 					      desc_8_size_reg ,
    input [31:0] 					      desc_8_data_offset_reg ,
    input [31:0] 					      desc_8_data_host_addr_0_reg ,
    input [31:0] 					      desc_8_data_host_addr_1_reg ,
    input [31:0] 					      desc_8_data_host_addr_2_reg ,
    input [31:0] 					      desc_8_data_host_addr_3_reg ,
    input [31:0] 					      desc_8_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_8_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_8_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_8_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_8_axsize_reg ,
    input [31:0] 					      desc_8_attr_reg ,
    input [31:0] 					      desc_8_axaddr_0_reg ,
    input [31:0] 					      desc_8_axaddr_1_reg ,
    input [31:0] 					      desc_8_axaddr_2_reg ,
    input [31:0] 					      desc_8_axaddr_3_reg ,
    input [31:0] 					      desc_8_axid_0_reg ,
    input [31:0] 					      desc_8_axid_1_reg ,
    input [31:0] 					      desc_8_axid_2_reg ,
    input [31:0] 					      desc_8_axid_3_reg ,
    input [31:0] 					      desc_8_axuser_0_reg ,
    input [31:0] 					      desc_8_axuser_1_reg ,
    input [31:0] 					      desc_8_axuser_2_reg ,
    input [31:0] 					      desc_8_axuser_3_reg ,
    input [31:0] 					      desc_8_axuser_4_reg ,
    input [31:0] 					      desc_8_axuser_5_reg ,
    input [31:0] 					      desc_8_axuser_6_reg ,
    input [31:0] 					      desc_8_axuser_7_reg ,
    input [31:0] 					      desc_8_axuser_8_reg ,
    input [31:0] 					      desc_8_axuser_9_reg ,
    input [31:0] 					      desc_8_axuser_10_reg ,
    input [31:0] 					      desc_8_axuser_11_reg ,
    input [31:0] 					      desc_8_axuser_12_reg ,
    input [31:0] 					      desc_8_axuser_13_reg ,
    input [31:0] 					      desc_8_axuser_14_reg ,
    input [31:0] 					      desc_8_axuser_15_reg ,
    input [31:0] 					      desc_8_xuser_0_reg ,
    input [31:0] 					      desc_8_xuser_1_reg ,
    input [31:0] 					      desc_8_xuser_2_reg ,
    input [31:0] 					      desc_8_xuser_3_reg ,
    input [31:0] 					      desc_8_xuser_4_reg ,
    input [31:0] 					      desc_8_xuser_5_reg ,
    input [31:0] 					      desc_8_xuser_6_reg ,
    input [31:0] 					      desc_8_xuser_7_reg ,
    input [31:0] 					      desc_8_xuser_8_reg ,
    input [31:0] 					      desc_8_xuser_9_reg ,
    input [31:0] 					      desc_8_xuser_10_reg ,
    input [31:0] 					      desc_8_xuser_11_reg ,
    input [31:0] 					      desc_8_xuser_12_reg ,
    input [31:0] 					      desc_8_xuser_13_reg ,
    input [31:0] 					      desc_8_xuser_14_reg ,
    input [31:0] 					      desc_8_xuser_15_reg ,
    input [31:0] 					      desc_8_wuser_0_reg ,
    input [31:0] 					      desc_8_wuser_1_reg ,
    input [31:0] 					      desc_8_wuser_2_reg ,
    input [31:0] 					      desc_8_wuser_3_reg ,
    input [31:0] 					      desc_8_wuser_4_reg ,
    input [31:0] 					      desc_8_wuser_5_reg ,
    input [31:0] 					      desc_8_wuser_6_reg ,
    input [31:0] 					      desc_8_wuser_7_reg ,
    input [31:0] 					      desc_8_wuser_8_reg ,
    input [31:0] 					      desc_8_wuser_9_reg ,
    input [31:0] 					      desc_8_wuser_10_reg ,
    input [31:0] 					      desc_8_wuser_11_reg ,
    input [31:0] 					      desc_8_wuser_12_reg ,
    input [31:0] 					      desc_8_wuser_13_reg ,
    input [31:0] 					      desc_8_wuser_14_reg ,
    input [31:0] 					      desc_8_wuser_15_reg ,
    input [31:0] 					      desc_9_txn_type_reg ,
    input [31:0] 					      desc_9_size_reg ,
    input [31:0] 					      desc_9_data_offset_reg ,
    input [31:0] 					      desc_9_data_host_addr_0_reg ,
    input [31:0] 					      desc_9_data_host_addr_1_reg ,
    input [31:0] 					      desc_9_data_host_addr_2_reg ,
    input [31:0] 					      desc_9_data_host_addr_3_reg ,
    input [31:0] 					      desc_9_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_9_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_9_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_9_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_9_axsize_reg ,
    input [31:0] 					      desc_9_attr_reg ,
    input [31:0] 					      desc_9_axaddr_0_reg ,
    input [31:0] 					      desc_9_axaddr_1_reg ,
    input [31:0] 					      desc_9_axaddr_2_reg ,
    input [31:0] 					      desc_9_axaddr_3_reg ,
    input [31:0] 					      desc_9_axid_0_reg ,
    input [31:0] 					      desc_9_axid_1_reg ,
    input [31:0] 					      desc_9_axid_2_reg ,
    input [31:0] 					      desc_9_axid_3_reg ,
    input [31:0] 					      desc_9_axuser_0_reg ,
    input [31:0] 					      desc_9_axuser_1_reg ,
    input [31:0] 					      desc_9_axuser_2_reg ,
    input [31:0] 					      desc_9_axuser_3_reg ,
    input [31:0] 					      desc_9_axuser_4_reg ,
    input [31:0] 					      desc_9_axuser_5_reg ,
    input [31:0] 					      desc_9_axuser_6_reg ,
    input [31:0] 					      desc_9_axuser_7_reg ,
    input [31:0] 					      desc_9_axuser_8_reg ,
    input [31:0] 					      desc_9_axuser_9_reg ,
    input [31:0] 					      desc_9_axuser_10_reg ,
    input [31:0] 					      desc_9_axuser_11_reg ,
    input [31:0] 					      desc_9_axuser_12_reg ,
    input [31:0] 					      desc_9_axuser_13_reg ,
    input [31:0] 					      desc_9_axuser_14_reg ,
    input [31:0] 					      desc_9_axuser_15_reg ,
    input [31:0] 					      desc_9_xuser_0_reg ,
    input [31:0] 					      desc_9_xuser_1_reg ,
    input [31:0] 					      desc_9_xuser_2_reg ,
    input [31:0] 					      desc_9_xuser_3_reg ,
    input [31:0] 					      desc_9_xuser_4_reg ,
    input [31:0] 					      desc_9_xuser_5_reg ,
    input [31:0] 					      desc_9_xuser_6_reg ,
    input [31:0] 					      desc_9_xuser_7_reg ,
    input [31:0] 					      desc_9_xuser_8_reg ,
    input [31:0] 					      desc_9_xuser_9_reg ,
    input [31:0] 					      desc_9_xuser_10_reg ,
    input [31:0] 					      desc_9_xuser_11_reg ,
    input [31:0] 					      desc_9_xuser_12_reg ,
    input [31:0] 					      desc_9_xuser_13_reg ,
    input [31:0] 					      desc_9_xuser_14_reg ,
    input [31:0] 					      desc_9_xuser_15_reg ,
    input [31:0] 					      desc_9_wuser_0_reg ,
    input [31:0] 					      desc_9_wuser_1_reg ,
    input [31:0] 					      desc_9_wuser_2_reg ,
    input [31:0] 					      desc_9_wuser_3_reg ,
    input [31:0] 					      desc_9_wuser_4_reg ,
    input [31:0] 					      desc_9_wuser_5_reg ,
    input [31:0] 					      desc_9_wuser_6_reg ,
    input [31:0] 					      desc_9_wuser_7_reg ,
    input [31:0] 					      desc_9_wuser_8_reg ,
    input [31:0] 					      desc_9_wuser_9_reg ,
    input [31:0] 					      desc_9_wuser_10_reg ,
    input [31:0] 					      desc_9_wuser_11_reg ,
    input [31:0] 					      desc_9_wuser_12_reg ,
    input [31:0] 					      desc_9_wuser_13_reg ,
    input [31:0] 					      desc_9_wuser_14_reg ,
    input [31:0] 					      desc_9_wuser_15_reg ,
    input [31:0] 					      desc_10_txn_type_reg ,
    input [31:0] 					      desc_10_size_reg ,
    input [31:0] 					      desc_10_data_offset_reg ,
    input [31:0] 					      desc_10_data_host_addr_0_reg ,
    input [31:0] 					      desc_10_data_host_addr_1_reg ,
    input [31:0] 					      desc_10_data_host_addr_2_reg ,
    input [31:0] 					      desc_10_data_host_addr_3_reg ,
    input [31:0] 					      desc_10_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_10_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_10_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_10_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_10_axsize_reg ,
    input [31:0] 					      desc_10_attr_reg ,
    input [31:0] 					      desc_10_axaddr_0_reg ,
    input [31:0] 					      desc_10_axaddr_1_reg ,
    input [31:0] 					      desc_10_axaddr_2_reg ,
    input [31:0] 					      desc_10_axaddr_3_reg ,
    input [31:0] 					      desc_10_axid_0_reg ,
    input [31:0] 					      desc_10_axid_1_reg ,
    input [31:0] 					      desc_10_axid_2_reg ,
    input [31:0] 					      desc_10_axid_3_reg ,
    input [31:0] 					      desc_10_axuser_0_reg ,
    input [31:0] 					      desc_10_axuser_1_reg ,
    input [31:0] 					      desc_10_axuser_2_reg ,
    input [31:0] 					      desc_10_axuser_3_reg ,
    input [31:0] 					      desc_10_axuser_4_reg ,
    input [31:0] 					      desc_10_axuser_5_reg ,
    input [31:0] 					      desc_10_axuser_6_reg ,
    input [31:0] 					      desc_10_axuser_7_reg ,
    input [31:0] 					      desc_10_axuser_8_reg ,
    input [31:0] 					      desc_10_axuser_9_reg ,
    input [31:0] 					      desc_10_axuser_10_reg ,
    input [31:0] 					      desc_10_axuser_11_reg ,
    input [31:0] 					      desc_10_axuser_12_reg ,
    input [31:0] 					      desc_10_axuser_13_reg ,
    input [31:0] 					      desc_10_axuser_14_reg ,
    input [31:0] 					      desc_10_axuser_15_reg ,
    input [31:0] 					      desc_10_xuser_0_reg ,
    input [31:0] 					      desc_10_xuser_1_reg ,
    input [31:0] 					      desc_10_xuser_2_reg ,
    input [31:0] 					      desc_10_xuser_3_reg ,
    input [31:0] 					      desc_10_xuser_4_reg ,
    input [31:0] 					      desc_10_xuser_5_reg ,
    input [31:0] 					      desc_10_xuser_6_reg ,
    input [31:0] 					      desc_10_xuser_7_reg ,
    input [31:0] 					      desc_10_xuser_8_reg ,
    input [31:0] 					      desc_10_xuser_9_reg ,
    input [31:0] 					      desc_10_xuser_10_reg ,
    input [31:0] 					      desc_10_xuser_11_reg ,
    input [31:0] 					      desc_10_xuser_12_reg ,
    input [31:0] 					      desc_10_xuser_13_reg ,
    input [31:0] 					      desc_10_xuser_14_reg ,
    input [31:0] 					      desc_10_xuser_15_reg ,
    input [31:0] 					      desc_10_wuser_0_reg ,
    input [31:0] 					      desc_10_wuser_1_reg ,
    input [31:0] 					      desc_10_wuser_2_reg ,
    input [31:0] 					      desc_10_wuser_3_reg ,
    input [31:0] 					      desc_10_wuser_4_reg ,
    input [31:0] 					      desc_10_wuser_5_reg ,
    input [31:0] 					      desc_10_wuser_6_reg ,
    input [31:0] 					      desc_10_wuser_7_reg ,
    input [31:0] 					      desc_10_wuser_8_reg ,
    input [31:0] 					      desc_10_wuser_9_reg ,
    input [31:0] 					      desc_10_wuser_10_reg ,
    input [31:0] 					      desc_10_wuser_11_reg ,
    input [31:0] 					      desc_10_wuser_12_reg ,
    input [31:0] 					      desc_10_wuser_13_reg ,
    input [31:0] 					      desc_10_wuser_14_reg ,
    input [31:0] 					      desc_10_wuser_15_reg ,
    input [31:0] 					      desc_11_txn_type_reg ,
    input [31:0] 					      desc_11_size_reg ,
    input [31:0] 					      desc_11_data_offset_reg ,
    input [31:0] 					      desc_11_data_host_addr_0_reg ,
    input [31:0] 					      desc_11_data_host_addr_1_reg ,
    input [31:0] 					      desc_11_data_host_addr_2_reg ,
    input [31:0] 					      desc_11_data_host_addr_3_reg ,
    input [31:0] 					      desc_11_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_11_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_11_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_11_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_11_axsize_reg ,
    input [31:0] 					      desc_11_attr_reg ,
    input [31:0] 					      desc_11_axaddr_0_reg ,
    input [31:0] 					      desc_11_axaddr_1_reg ,
    input [31:0] 					      desc_11_axaddr_2_reg ,
    input [31:0] 					      desc_11_axaddr_3_reg ,
    input [31:0] 					      desc_11_axid_0_reg ,
    input [31:0] 					      desc_11_axid_1_reg ,
    input [31:0] 					      desc_11_axid_2_reg ,
    input [31:0] 					      desc_11_axid_3_reg ,
    input [31:0] 					      desc_11_axuser_0_reg ,
    input [31:0] 					      desc_11_axuser_1_reg ,
    input [31:0] 					      desc_11_axuser_2_reg ,
    input [31:0] 					      desc_11_axuser_3_reg ,
    input [31:0] 					      desc_11_axuser_4_reg ,
    input [31:0] 					      desc_11_axuser_5_reg ,
    input [31:0] 					      desc_11_axuser_6_reg ,
    input [31:0] 					      desc_11_axuser_7_reg ,
    input [31:0] 					      desc_11_axuser_8_reg ,
    input [31:0] 					      desc_11_axuser_9_reg ,
    input [31:0] 					      desc_11_axuser_10_reg ,
    input [31:0] 					      desc_11_axuser_11_reg ,
    input [31:0] 					      desc_11_axuser_12_reg ,
    input [31:0] 					      desc_11_axuser_13_reg ,
    input [31:0] 					      desc_11_axuser_14_reg ,
    input [31:0] 					      desc_11_axuser_15_reg ,
    input [31:0] 					      desc_11_xuser_0_reg ,
    input [31:0] 					      desc_11_xuser_1_reg ,
    input [31:0] 					      desc_11_xuser_2_reg ,
    input [31:0] 					      desc_11_xuser_3_reg ,
    input [31:0] 					      desc_11_xuser_4_reg ,
    input [31:0] 					      desc_11_xuser_5_reg ,
    input [31:0] 					      desc_11_xuser_6_reg ,
    input [31:0] 					      desc_11_xuser_7_reg ,
    input [31:0] 					      desc_11_xuser_8_reg ,
    input [31:0] 					      desc_11_xuser_9_reg ,
    input [31:0] 					      desc_11_xuser_10_reg ,
    input [31:0] 					      desc_11_xuser_11_reg ,
    input [31:0] 					      desc_11_xuser_12_reg ,
    input [31:0] 					      desc_11_xuser_13_reg ,
    input [31:0] 					      desc_11_xuser_14_reg ,
    input [31:0] 					      desc_11_xuser_15_reg ,
    input [31:0] 					      desc_11_wuser_0_reg ,
    input [31:0] 					      desc_11_wuser_1_reg ,
    input [31:0] 					      desc_11_wuser_2_reg ,
    input [31:0] 					      desc_11_wuser_3_reg ,
    input [31:0] 					      desc_11_wuser_4_reg ,
    input [31:0] 					      desc_11_wuser_5_reg ,
    input [31:0] 					      desc_11_wuser_6_reg ,
    input [31:0] 					      desc_11_wuser_7_reg ,
    input [31:0] 					      desc_11_wuser_8_reg ,
    input [31:0] 					      desc_11_wuser_9_reg ,
    input [31:0] 					      desc_11_wuser_10_reg ,
    input [31:0] 					      desc_11_wuser_11_reg ,
    input [31:0] 					      desc_11_wuser_12_reg ,
    input [31:0] 					      desc_11_wuser_13_reg ,
    input [31:0] 					      desc_11_wuser_14_reg ,
    input [31:0] 					      desc_11_wuser_15_reg ,
    input [31:0] 					      desc_12_txn_type_reg ,
    input [31:0] 					      desc_12_size_reg ,
    input [31:0] 					      desc_12_data_offset_reg ,
    input [31:0] 					      desc_12_data_host_addr_0_reg ,
    input [31:0] 					      desc_12_data_host_addr_1_reg ,
    input [31:0] 					      desc_12_data_host_addr_2_reg ,
    input [31:0] 					      desc_12_data_host_addr_3_reg ,
    input [31:0] 					      desc_12_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_12_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_12_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_12_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_12_axsize_reg ,
    input [31:0] 					      desc_12_attr_reg ,
    input [31:0] 					      desc_12_axaddr_0_reg ,
    input [31:0] 					      desc_12_axaddr_1_reg ,
    input [31:0] 					      desc_12_axaddr_2_reg ,
    input [31:0] 					      desc_12_axaddr_3_reg ,
    input [31:0] 					      desc_12_axid_0_reg ,
    input [31:0] 					      desc_12_axid_1_reg ,
    input [31:0] 					      desc_12_axid_2_reg ,
    input [31:0] 					      desc_12_axid_3_reg ,
    input [31:0] 					      desc_12_axuser_0_reg ,
    input [31:0] 					      desc_12_axuser_1_reg ,
    input [31:0] 					      desc_12_axuser_2_reg ,
    input [31:0] 					      desc_12_axuser_3_reg ,
    input [31:0] 					      desc_12_axuser_4_reg ,
    input [31:0] 					      desc_12_axuser_5_reg ,
    input [31:0] 					      desc_12_axuser_6_reg ,
    input [31:0] 					      desc_12_axuser_7_reg ,
    input [31:0] 					      desc_12_axuser_8_reg ,
    input [31:0] 					      desc_12_axuser_9_reg ,
    input [31:0] 					      desc_12_axuser_10_reg ,
    input [31:0] 					      desc_12_axuser_11_reg ,
    input [31:0] 					      desc_12_axuser_12_reg ,
    input [31:0] 					      desc_12_axuser_13_reg ,
    input [31:0] 					      desc_12_axuser_14_reg ,
    input [31:0] 					      desc_12_axuser_15_reg ,
    input [31:0] 					      desc_12_xuser_0_reg ,
    input [31:0] 					      desc_12_xuser_1_reg ,
    input [31:0] 					      desc_12_xuser_2_reg ,
    input [31:0] 					      desc_12_xuser_3_reg ,
    input [31:0] 					      desc_12_xuser_4_reg ,
    input [31:0] 					      desc_12_xuser_5_reg ,
    input [31:0] 					      desc_12_xuser_6_reg ,
    input [31:0] 					      desc_12_xuser_7_reg ,
    input [31:0] 					      desc_12_xuser_8_reg ,
    input [31:0] 					      desc_12_xuser_9_reg ,
    input [31:0] 					      desc_12_xuser_10_reg ,
    input [31:0] 					      desc_12_xuser_11_reg ,
    input [31:0] 					      desc_12_xuser_12_reg ,
    input [31:0] 					      desc_12_xuser_13_reg ,
    input [31:0] 					      desc_12_xuser_14_reg ,
    input [31:0] 					      desc_12_xuser_15_reg ,
    input [31:0] 					      desc_12_wuser_0_reg ,
    input [31:0] 					      desc_12_wuser_1_reg ,
    input [31:0] 					      desc_12_wuser_2_reg ,
    input [31:0] 					      desc_12_wuser_3_reg ,
    input [31:0] 					      desc_12_wuser_4_reg ,
    input [31:0] 					      desc_12_wuser_5_reg ,
    input [31:0] 					      desc_12_wuser_6_reg ,
    input [31:0] 					      desc_12_wuser_7_reg ,
    input [31:0] 					      desc_12_wuser_8_reg ,
    input [31:0] 					      desc_12_wuser_9_reg ,
    input [31:0] 					      desc_12_wuser_10_reg ,
    input [31:0] 					      desc_12_wuser_11_reg ,
    input [31:0] 					      desc_12_wuser_12_reg ,
    input [31:0] 					      desc_12_wuser_13_reg ,
    input [31:0] 					      desc_12_wuser_14_reg ,
    input [31:0] 					      desc_12_wuser_15_reg ,
    input [31:0] 					      desc_13_txn_type_reg ,
    input [31:0] 					      desc_13_size_reg ,
    input [31:0] 					      desc_13_data_offset_reg ,
    input [31:0] 					      desc_13_data_host_addr_0_reg ,
    input [31:0] 					      desc_13_data_host_addr_1_reg ,
    input [31:0] 					      desc_13_data_host_addr_2_reg ,
    input [31:0] 					      desc_13_data_host_addr_3_reg ,
    input [31:0] 					      desc_13_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_13_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_13_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_13_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_13_axsize_reg ,
    input [31:0] 					      desc_13_attr_reg ,
    input [31:0] 					      desc_13_axaddr_0_reg ,
    input [31:0] 					      desc_13_axaddr_1_reg ,
    input [31:0] 					      desc_13_axaddr_2_reg ,
    input [31:0] 					      desc_13_axaddr_3_reg ,
    input [31:0] 					      desc_13_axid_0_reg ,
    input [31:0] 					      desc_13_axid_1_reg ,
    input [31:0] 					      desc_13_axid_2_reg ,
    input [31:0] 					      desc_13_axid_3_reg ,
    input [31:0] 					      desc_13_axuser_0_reg ,
    input [31:0] 					      desc_13_axuser_1_reg ,
    input [31:0] 					      desc_13_axuser_2_reg ,
    input [31:0] 					      desc_13_axuser_3_reg ,
    input [31:0] 					      desc_13_axuser_4_reg ,
    input [31:0] 					      desc_13_axuser_5_reg ,
    input [31:0] 					      desc_13_axuser_6_reg ,
    input [31:0] 					      desc_13_axuser_7_reg ,
    input [31:0] 					      desc_13_axuser_8_reg ,
    input [31:0] 					      desc_13_axuser_9_reg ,
    input [31:0] 					      desc_13_axuser_10_reg ,
    input [31:0] 					      desc_13_axuser_11_reg ,
    input [31:0] 					      desc_13_axuser_12_reg ,
    input [31:0] 					      desc_13_axuser_13_reg ,
    input [31:0] 					      desc_13_axuser_14_reg ,
    input [31:0] 					      desc_13_axuser_15_reg ,
    input [31:0] 					      desc_13_xuser_0_reg ,
    input [31:0] 					      desc_13_xuser_1_reg ,
    input [31:0] 					      desc_13_xuser_2_reg ,
    input [31:0] 					      desc_13_xuser_3_reg ,
    input [31:0] 					      desc_13_xuser_4_reg ,
    input [31:0] 					      desc_13_xuser_5_reg ,
    input [31:0] 					      desc_13_xuser_6_reg ,
    input [31:0] 					      desc_13_xuser_7_reg ,
    input [31:0] 					      desc_13_xuser_8_reg ,
    input [31:0] 					      desc_13_xuser_9_reg ,
    input [31:0] 					      desc_13_xuser_10_reg ,
    input [31:0] 					      desc_13_xuser_11_reg ,
    input [31:0] 					      desc_13_xuser_12_reg ,
    input [31:0] 					      desc_13_xuser_13_reg ,
    input [31:0] 					      desc_13_xuser_14_reg ,
    input [31:0] 					      desc_13_xuser_15_reg ,
    input [31:0] 					      desc_13_wuser_0_reg ,
    input [31:0] 					      desc_13_wuser_1_reg ,
    input [31:0] 					      desc_13_wuser_2_reg ,
    input [31:0] 					      desc_13_wuser_3_reg ,
    input [31:0] 					      desc_13_wuser_4_reg ,
    input [31:0] 					      desc_13_wuser_5_reg ,
    input [31:0] 					      desc_13_wuser_6_reg ,
    input [31:0] 					      desc_13_wuser_7_reg ,
    input [31:0] 					      desc_13_wuser_8_reg ,
    input [31:0] 					      desc_13_wuser_9_reg ,
    input [31:0] 					      desc_13_wuser_10_reg ,
    input [31:0] 					      desc_13_wuser_11_reg ,
    input [31:0] 					      desc_13_wuser_12_reg ,
    input [31:0] 					      desc_13_wuser_13_reg ,
    input [31:0] 					      desc_13_wuser_14_reg ,
    input [31:0] 					      desc_13_wuser_15_reg ,
    input [31:0] 					      desc_14_txn_type_reg ,
    input [31:0] 					      desc_14_size_reg ,
    input [31:0] 					      desc_14_data_offset_reg ,
    input [31:0] 					      desc_14_data_host_addr_0_reg ,
    input [31:0] 					      desc_14_data_host_addr_1_reg ,
    input [31:0] 					      desc_14_data_host_addr_2_reg ,
    input [31:0] 					      desc_14_data_host_addr_3_reg ,
    input [31:0] 					      desc_14_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_14_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_14_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_14_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_14_axsize_reg ,
    input [31:0] 					      desc_14_attr_reg ,
    input [31:0] 					      desc_14_axaddr_0_reg ,
    input [31:0] 					      desc_14_axaddr_1_reg ,
    input [31:0] 					      desc_14_axaddr_2_reg ,
    input [31:0] 					      desc_14_axaddr_3_reg ,
    input [31:0] 					      desc_14_axid_0_reg ,
    input [31:0] 					      desc_14_axid_1_reg ,
    input [31:0] 					      desc_14_axid_2_reg ,
    input [31:0] 					      desc_14_axid_3_reg ,
    input [31:0] 					      desc_14_axuser_0_reg ,
    input [31:0] 					      desc_14_axuser_1_reg ,
    input [31:0] 					      desc_14_axuser_2_reg ,
    input [31:0] 					      desc_14_axuser_3_reg ,
    input [31:0] 					      desc_14_axuser_4_reg ,
    input [31:0] 					      desc_14_axuser_5_reg ,
    input [31:0] 					      desc_14_axuser_6_reg ,
    input [31:0] 					      desc_14_axuser_7_reg ,
    input [31:0] 					      desc_14_axuser_8_reg ,
    input [31:0] 					      desc_14_axuser_9_reg ,
    input [31:0] 					      desc_14_axuser_10_reg ,
    input [31:0] 					      desc_14_axuser_11_reg ,
    input [31:0] 					      desc_14_axuser_12_reg ,
    input [31:0] 					      desc_14_axuser_13_reg ,
    input [31:0] 					      desc_14_axuser_14_reg ,
    input [31:0] 					      desc_14_axuser_15_reg ,
    input [31:0] 					      desc_14_xuser_0_reg ,
    input [31:0] 					      desc_14_xuser_1_reg ,
    input [31:0] 					      desc_14_xuser_2_reg ,
    input [31:0] 					      desc_14_xuser_3_reg ,
    input [31:0] 					      desc_14_xuser_4_reg ,
    input [31:0] 					      desc_14_xuser_5_reg ,
    input [31:0] 					      desc_14_xuser_6_reg ,
    input [31:0] 					      desc_14_xuser_7_reg ,
    input [31:0] 					      desc_14_xuser_8_reg ,
    input [31:0] 					      desc_14_xuser_9_reg ,
    input [31:0] 					      desc_14_xuser_10_reg ,
    input [31:0] 					      desc_14_xuser_11_reg ,
    input [31:0] 					      desc_14_xuser_12_reg ,
    input [31:0] 					      desc_14_xuser_13_reg ,
    input [31:0] 					      desc_14_xuser_14_reg ,
    input [31:0] 					      desc_14_xuser_15_reg ,
    input [31:0] 					      desc_14_wuser_0_reg ,
    input [31:0] 					      desc_14_wuser_1_reg ,
    input [31:0] 					      desc_14_wuser_2_reg ,
    input [31:0] 					      desc_14_wuser_3_reg ,
    input [31:0] 					      desc_14_wuser_4_reg ,
    input [31:0] 					      desc_14_wuser_5_reg ,
    input [31:0] 					      desc_14_wuser_6_reg ,
    input [31:0] 					      desc_14_wuser_7_reg ,
    input [31:0] 					      desc_14_wuser_8_reg ,
    input [31:0] 					      desc_14_wuser_9_reg ,
    input [31:0] 					      desc_14_wuser_10_reg ,
    input [31:0] 					      desc_14_wuser_11_reg ,
    input [31:0] 					      desc_14_wuser_12_reg ,
    input [31:0] 					      desc_14_wuser_13_reg ,
    input [31:0] 					      desc_14_wuser_14_reg ,
    input [31:0] 					      desc_14_wuser_15_reg ,
    input [31:0] 					      desc_15_txn_type_reg ,
    input [31:0] 					      desc_15_size_reg ,
    input [31:0] 					      desc_15_data_offset_reg ,
    input [31:0] 					      desc_15_data_host_addr_0_reg ,
    input [31:0] 					      desc_15_data_host_addr_1_reg ,
    input [31:0] 					      desc_15_data_host_addr_2_reg ,
    input [31:0] 					      desc_15_data_host_addr_3_reg ,
    input [31:0] 					      desc_15_wstrb_host_addr_0_reg ,
    input [31:0] 					      desc_15_wstrb_host_addr_1_reg ,
    input [31:0] 					      desc_15_wstrb_host_addr_2_reg ,
    input [31:0] 					      desc_15_wstrb_host_addr_3_reg ,
    input [31:0] 					      desc_15_axsize_reg ,
    input [31:0] 					      desc_15_attr_reg ,
    input [31:0] 					      desc_15_axaddr_0_reg ,
    input [31:0] 					      desc_15_axaddr_1_reg ,
    input [31:0] 					      desc_15_axaddr_2_reg ,
    input [31:0] 					      desc_15_axaddr_3_reg ,
    input [31:0] 					      desc_15_axid_0_reg ,
    input [31:0] 					      desc_15_axid_1_reg ,
    input [31:0] 					      desc_15_axid_2_reg ,
    input [31:0] 					      desc_15_axid_3_reg ,
    input [31:0] 					      desc_15_axuser_0_reg ,
    input [31:0] 					      desc_15_axuser_1_reg ,
    input [31:0] 					      desc_15_axuser_2_reg ,
    input [31:0] 					      desc_15_axuser_3_reg ,
    input [31:0] 					      desc_15_axuser_4_reg ,
    input [31:0] 					      desc_15_axuser_5_reg ,
    input [31:0] 					      desc_15_axuser_6_reg ,
    input [31:0] 					      desc_15_axuser_7_reg ,
    input [31:0] 					      desc_15_axuser_8_reg ,
    input [31:0] 					      desc_15_axuser_9_reg ,
    input [31:0] 					      desc_15_axuser_10_reg ,
    input [31:0] 					      desc_15_axuser_11_reg ,
    input [31:0] 					      desc_15_axuser_12_reg ,
    input [31:0] 					      desc_15_axuser_13_reg ,
    input [31:0] 					      desc_15_axuser_14_reg ,
    input [31:0] 					      desc_15_axuser_15_reg ,
    input [31:0] 					      desc_15_xuser_0_reg ,
    input [31:0] 					      desc_15_xuser_1_reg ,
    input [31:0] 					      desc_15_xuser_2_reg ,
    input [31:0] 					      desc_15_xuser_3_reg ,
    input [31:0] 					      desc_15_xuser_4_reg ,
    input [31:0] 					      desc_15_xuser_5_reg ,
    input [31:0] 					      desc_15_xuser_6_reg ,
    input [31:0] 					      desc_15_xuser_7_reg ,
    input [31:0] 					      desc_15_xuser_8_reg ,
    input [31:0] 					      desc_15_xuser_9_reg ,
    input [31:0] 					      desc_15_xuser_10_reg ,
    input [31:0] 					      desc_15_xuser_11_reg ,
    input [31:0] 					      desc_15_xuser_12_reg ,
    input [31:0] 					      desc_15_xuser_13_reg ,
    input [31:0] 					      desc_15_xuser_14_reg ,
    input [31:0] 					      desc_15_xuser_15_reg ,
    input [31:0] 					      desc_15_wuser_0_reg ,
    input [31:0] 					      desc_15_wuser_1_reg ,
    input [31:0] 					      desc_15_wuser_2_reg ,
    input [31:0] 					      desc_15_wuser_3_reg ,
    input [31:0] 					      desc_15_wuser_4_reg ,
    input [31:0] 					      desc_15_wuser_5_reg ,
    input [31:0] 					      desc_15_wuser_6_reg ,
    input [31:0] 					      desc_15_wuser_7_reg ,
    input [31:0] 					      desc_15_wuser_8_reg ,
    input [31:0] 					      desc_15_wuser_9_reg ,
    input [31:0] 					      desc_15_wuser_10_reg ,
    input [31:0] 					      desc_15_wuser_11_reg ,
    input [31:0] 					      desc_15_wuser_12_reg ,
    input [31:0] 					      desc_15_wuser_13_reg ,
    input [31:0] 					      desc_15_wuser_14_reg ,
    input [31:0] 					      desc_15_wuser_15_reg ,
  
    output reg [31:0] 					      uc2rb_intr_error_status_reg ,
    output reg [31:0] 					      uc2rb_ownership_reg ,
    output reg [31:0] 					      uc2rb_intr_comp_status_reg ,
    output reg [31:0] 					      uc2rb_status_resp_reg ,
    output [31:0] 					      uc2rb_status_busy_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_15_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_0_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_1_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_2_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_3_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_4_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_5_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_6_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_7_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_8_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_9_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_10_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_11_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_12_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_13_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_14_reg ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_15_reg ,

    output [31:0] 					      uc2rb_intr_error_status_reg_we ,
    output [31:0] 					      uc2rb_ownership_reg_we ,
    output [31:0] 					      uc2rb_intr_comp_status_reg_we ,
    output reg [31:0] 					      uc2rb_status_resp_reg_we ,
    output [31:0] 					      uc2rb_status_busy_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_0_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_1_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_2_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_3_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_4_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_5_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_6_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_7_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_8_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_9_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_10_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_11_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_12_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_13_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_14_xuser_15_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_0_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_1_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_2_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_3_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_4_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_5_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_6_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_7_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_8_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_9_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_10_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_11_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_12_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_13_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_14_reg_we ,
    output reg [31:0] 					      uc2rb_desc_15_xuser_15_reg_we ,


    //M_AXI_USR
    output [M_AXI_USR_ID_WIDTH-1:0] 			      m_axi_usr_awid, 
    output [M_AXI_USR_ADDR_WIDTH-1:0] 			      m_axi_usr_awaddr, 
    output [M_AXI_USR_LEN_WIDTH-1:0] 			      m_axi_usr_awlen, 
    output [2:0] 					      m_axi_usr_awsize, 
    output [1:0] 					      m_axi_usr_awburst, 
    output [1:0] 					      m_axi_usr_awlock, 
    output [3:0] 					      m_axi_usr_awcache, 
    output [2:0] 					      m_axi_usr_awprot, 
    output [3:0] 					      m_axi_usr_awqos, 
    output [3:0] 					      m_axi_usr_awregion, 
    output [M_AXI_USR_AWUSER_WIDTH-1:0] 		      m_axi_usr_awuser, 
    output 						      m_axi_usr_awvalid, 
    input 						      m_axi_usr_awready, 
    output [M_AXI_USR_DATA_WIDTH-1:0] 			      m_axi_usr_wdata, 
    output [(M_AXI_USR_DATA_WIDTH/8)-1:0] 		      m_axi_usr_wstrb,
    output 						      m_axi_usr_wlast, 
    output [M_AXI_USR_WUSER_WIDTH-1:0] 			      m_axi_usr_wuser, 
    output 						      m_axi_usr_wvalid, 
    input 						      m_axi_usr_wready, 
    input [M_AXI_USR_ID_WIDTH-1:0] 			      m_axi_usr_bid, 
    input [1:0] 					      m_axi_usr_bresp, 
    input [M_AXI_USR_BUSER_WIDTH-1:0] 			      m_axi_usr_buser, 
    input 						      m_axi_usr_bvalid, 
    output 						      m_axi_usr_bready, 
    output [M_AXI_USR_ID_WIDTH-1:0] 			      m_axi_usr_arid, 
    output [M_AXI_USR_ADDR_WIDTH-1:0] 			      m_axi_usr_araddr, 
    output [M_AXI_USR_LEN_WIDTH-1:0] 			      m_axi_usr_arlen, 
    output [2:0] 					      m_axi_usr_arsize, 
    output [1:0] 					      m_axi_usr_arburst, 
    output [1:0] 					      m_axi_usr_arlock, 
    output [3:0] 					      m_axi_usr_arcache, 
    output [2:0] 					      m_axi_usr_arprot, 
    output [3:0] 					      m_axi_usr_arqos, 
    output [3:0] 					      m_axi_usr_arregion, 
    output [M_AXI_USR_ARUSER_WIDTH-1:0] 		      m_axi_usr_aruser, 
    output 						      m_axi_usr_arvalid, 
    input 						      m_axi_usr_arready, 
    input [M_AXI_USR_ID_WIDTH-1:0] 			      m_axi_usr_rid, 
    input [M_AXI_USR_DATA_WIDTH-1:0] 			      m_axi_usr_rdata, 
    input [1:0] 					      m_axi_usr_rresp, 
    input 						      m_axi_usr_rlast, 
    input [M_AXI_USR_RUSER_WIDTH-1:0] 			      m_axi_usr_ruser, 
    input 						      m_axi_usr_rvalid, 
    output 						      m_axi_usr_rready,
	// For AXI3
    output [M_AXI_USR_ID_WIDTH-1:0] 			      m_axi_usr_wid
    );

   
   integer 						      k;   
   

   //////////////////////////////////////////////////////////////////
							      //
   // Assigning reg for AXI (output) ports
   //
   //////////////////////////////////////////////////////////////////


   reg [M_AXI_USR_ID_WIDTH-1:0] 			      axi_usr_reg_awid; 
   reg [M_AXI_USR_ADDR_WIDTH-1:0] 			      axi_usr_reg_awaddr; 
   reg [7:0] 						      axi_usr_reg_awlen; 
   reg [2:0] 						      axi_usr_reg_awsize; 
   reg [1:0] 						      axi_usr_reg_awburst; 
   reg [1:0] 						      axi_usr_reg_awlock; 
   reg [3:0] 						      axi_usr_reg_awcache; 
   reg [2:0] 						      axi_usr_reg_awprot; 
   reg [3:0] 						      axi_usr_reg_awqos; 
   reg [3:0] 						      axi_usr_reg_awregion; 
   reg [M_AXI_USR_AWUSER_WIDTH-1:0] 			      axi_usr_reg_awuser; 
   reg [M_AXI_USR_WUSER_WIDTH-1:0] 			      axi_usr_reg_wuser; 
   reg [M_AXI_USR_ID_WIDTH-1:0] 			      axi_usr_reg_arid; 
   reg [M_AXI_USR_ADDR_WIDTH-1:0] 			      axi_usr_reg_araddr; 
   reg [7:0] 						      axi_usr_reg_arlen; 
   reg [2:0] 						      axi_usr_reg_arsize; 
   reg [1:0] 						      axi_usr_reg_arburst; 
   reg [1:0] 						      axi_usr_reg_arlock; 
   reg [3:0] 						      axi_usr_reg_arcache; 
   reg [2:0] 						      axi_usr_reg_arprot; 
   reg [3:0] 						      axi_usr_reg_arqos; 
   reg [3:0] 						      axi_usr_reg_arregion; 
   reg [M_AXI_USR_ARUSER_WIDTH-1:0] 			      axi_usr_reg_aruser; 




   // Mapping 1d Input registers into 2d regs.
`include "user_master_desc_2d.vh"

   
   ///////////////////////////////////////////////////////////
   //
   // Reg & Wire declare
   //
   //////////////////////////////////////////////////////////////
   
   reg 							      bresp_delay;
   reg [MAX_DESC-1:0] 					      bresp_completed ;
   reg [31:0] 						      bresp_status ;
   reg [31:0] 						      bresp_status_we ;
   reg [M_AXI_USR_BUSER_WIDTH-1:0] 			      bresp_buser[MAX_DESC-1:0];
   reg [31:0] 						      bresp_buser_we[MAX_DESC-1:0];
   reg [MAX_DESC-1:0] 					      ownership_per_desc_wr;
   reg [MAX_DESC-1:0] 					      rresp_completed;   
   reg [MAX_DESC-1:0] 					      increment_offset_addr;
   reg [MAX_DESC-1:0] 					      increment_offset_addr_done;   
   reg [31:0] 						      update_ownership_reg;
   reg 							      bid_not_found_error;
   reg 							      rlast_not_asserted_error;
   reg 							      rid_not_found_error;
   

   wire 						      first_wvalid;
   wire [31:0] 						      ownership_done;
   wire [31:0] 						      update_intr_comp_status_reg;
   wire [31:0] 						      update_intr_error_status_reg;
   wire 						      wdata_fifo_empty;
   
   


   
   ///////////////////////////////////////////////////////////////////////
   // 
   // Register & wires
   //
   /////////////////////////////////////////////////////////////////////

   
   wire 						      first_write_wdata;
   wire 						      first_second_write_pulse;
   wire 						      wdata_pending_read_en;
   wire 						      wr_desc_allocation_in_progress;
   wire 						      rd_desc_allocation_in_progress;
   wire 						      wdata_pending_fifo_full;
   wire [M_AXI_USR_LEN_WIDTH-1:0] 			      wdata_pending_awlen;
   wire [(`CLOG2(MAX_DESC))-1:0] 			      wdata_pending_id;
   wire 						      wlast;
   wire 						      awnext,arnext,rnext,wnext;
   wire 						      awvalid_asserted;
   wire 						      wdata_read_en;
   wire 						      rdata_almost_full;
   wire [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      wdata_read_out_wstrb;
   wire [M_AXI_USR_WUSER_WIDTH-1:0] 			      wdata_read_out_wuser;
   wire [M_AXI_USR_DATA_WIDTH-1:0] 			      wdata_read_out_wdata;
   wire [M_AXI_USR_ID_WIDTH-1:0] 			      wdata_read_out_wid;
   
   wire [(`CLOG2(MAX_DESC))-1:0] 			      desc_wr_req_id;
   wire 						      wdata_fifo_almost_full;
   wire [(`CLOG2(MAX_DESC))-1:0] 			      desc_rd_req_id;
   
   //To generate write pulse 
   wire 						      gen_write;
   wire 						      gen_read;
   wire 						      start_write_tx;
   wire 						      start_read_tx;
   
   //Calculate AWELN by dividing [Total Bytes/2^(AXSIZE) ]
   wire [7:0] 						      desc_n_awlen;
   wire [7:0] 						      desc_n_arlen;
   
   
   reg 							      awvalid;
   reg 							      wdata_pending_read_en_ff;
   reg 							      awvalid_ff;
   reg 							      awvalid_pulse;
   reg 							      arvalid;
   reg 							      wvalid;
   reg 							      rready;
   reg 							      bready;
   reg [M_AXI_USR_ADDR_WIDTH-1:0] 			      awaddr;
   reg [M_AXI_USR_ADDR_WIDTH-1:0] 			      araddr;
   reg [M_AXI_USR_DATA_WIDTH-1:0] 			      wdata;
   reg [M_AXI_USR_DATA_WIDTH-1:0] 			      wdata_ff;
   reg [M_AXI_USR_DATA_WIDTH-1:0] 			      wdata_ff2;
   
   //Descriptor Fifo:
   reg [(`CLOG2(MAX_DESC))-1:0] 			      desc_rd_req_id_out_ff;
   reg [(`CLOG2(MAX_DESC))-1:0] 			      desc_rd_req_id_out_ff2;
   reg [(`CLOG2(MAX_DESC))-1:0] 			      desc_wr_req_id_out_ff;
   reg [(`CLOG2(MAX_DESC))-1:0] 			      desc_wr_req_id_out_ff2;
   
   //To latch tx and rx generation
   reg 							      start_write_tx_ff, start_write_tx_ff2;
   reg 							      start_read_tx_ff, start_read_tx_ff2;
   reg 							      axi_in_progress;
   reg [1:0] 						      dram_wdata_rfifo_state;
   reg [15:0] 						      int_reg_desc_aw_txn_size;
   reg [15:0] 						      int_reg_desc_ar_txn_size;
   wire [2:0] 						      int_desc_awsize;
   wire [2:0] 						      int_desc_arsize;
   reg [15:0] 						      int_reg_desc_awlen;
   reg [15:0] 						      int_reg_desc_arlen;

   // In case of HM, last transfer needs to be masked
   // when writing it back into memory
   reg [15:0] 						      hm_rlast_mem_strobes[15:0];
   reg [15:0] 						      hm_wlast_strobes[15:0];
   
   
   //////////////////////////////////////////////////////
   // 
   // Descriptor allocator registers & wires
   //
   /////////////////////////////////////////////////////
   
   

   wire [(`CLOG2(MAX_DESC))-1:0] 			      desc_rd_req_id_out;
   wire [(`CLOG2(MAX_DESC))-1:0] 			      desc_wr_req_id_out;
   wire [511:0] 					      wdata_wstrb_const;
   wire [(M_AXI_USR_DATA_WIDTH/8) -1:0] 		      wdata_wstrb;
   
   wire 						      desc_rd_req_read_en;
   wire 						      desc_wr_req_read_en;
   //Delaying FIFO read en, so that I can setup AXI ATTRIB before generating AWVALID/ARVALID
   reg 							      desc_rd_req_read_en_ff;
   reg 							      desc_rd_req_read_en_ff2;
   reg 							      desc_rd_req_read_en_ff3;
   reg 							      desc_rd_req_read_en_ff4;
   reg 							      desc_rd_req_read_en_ff5;
   reg 							      desc_rd_req_read_en_ff6;
   
   reg 							      desc_wr_req_read_en_ff;
   reg 							      desc_wr_req_read_en_ff2;
   reg 							      desc_wr_req_read_en_ff3;
   
   ////////////////////////////////////////////////////////////////////////////
   //
   // HM Regs/Wire
   //
   ////////////////////////////////////////////////////////////////////////////

   
   reg [MAX_DESC-1:0] 					      uc2hm_trig_wr;
   reg 							      use_mode;
   reg [MAX_DESC-1:0] 					      hm_done_int;   

   wire [MAX_DESC-1:0] 					      uc2hm_trig_rd;
   
   /////////////////////////////////////////////////////////////////////
   //
   // RDATA Channel regs and wires
   //
   ///////////////////////////////////////////////////////////////////

   ////////////////////////////////////////////////////////////////////////
   ///
   // Reg for RDATA_CHENNEL
   //
   //////////////////////////////////////////////////////////////////////

   reg [MAX_DESC-1:0] 					      arid_read_en_reg; 
   reg 							      arid_read_en_reg_valid; 
   reg [MAX_DESC-1:0] 					      arid_read_en_reg_ff;
   reg [M_AXI_USR_DATA_WIDTH-1:0] 			      rdata_in;
   reg [M_AXI_USR_ID_WIDTH-1:0] 			      rid_in;
   reg [M_AXI_USR_RUSER_WIDTH-1:0] 			      ruser_in;
   reg [1:0] 						      rresp_in;
   reg 							      rvalid_in;
   reg 							      rlast_in;
   wire [(`CLOG2(MAX_DESC)):0] 				      rdata_fifo_counter;
   
   
   
   wire [M_AXI_USR_ID_WIDTH-1:0] 			      fifo_id_rd_reg[15:0];
   wire [MAX_DESC-1:0] 					      fifo_id_rd_reg_valid;
   wire [(`CLOG2(MAX_DESC))-1:0] 			      arid_response_id_reg[15:0];
   wire 						      rnext_on_bus; 
   wire [9:0] 						      rdata_counter_done[MAX_DESC-1:0];
   wire [(`CLOG2(MAX_DESC))-1:0] 			      fifo_select;
   wire 						      send_data_to_dram;   
   wire 						      halt_rdata_fifo_read;   
   wire [(`CLOG2(MAX_DESC))-1:0] 			      desc_rdata_id;
   wire 						      um_as_hm_count_st;   
   wire [2:0] 						      increment_rdata_offset_addr;

   wire [M_AXI_USR_ID_WIDTH-1:0] 			      rdata_read_out_id;
   wire [M_AXI_USR_DATA_WIDTH-1:0] 			      rdata_read_out_data;
   wire [1:0] 						      rdata_read_out_resp;
   wire 						      rdata_read_out_rlast;
   wire [M_AXI_USR_RUSER_WIDTH-1:0] 			      rdata_read_out_ruser;
   wire 						      rdata_fifo_empty,rdata_fifo_full;
   wire 						      um_as_hm_max_wr_delay;

   
   reg 							      rnext_on_bus_ff;
   reg 							      rdata_read_en;
   reg [(`CLOG2(RAM_SIZE/(UC_AXI_DATA_WIDTH/8)))-1:0] 	      offset_addr [MAX_DESC-1:0];
   reg 							      rdata_processed;
   reg [1:0] 						      rdata_fifo_read;
   reg 							      rdata_read_en_ff;	
   reg 							      rdata_read_en_ff2;
   reg 							      rdata_read_en_ff3;
   reg 							      rdata_read_en_ff4;
   reg 							      rdata_read_en_ff5;		
   reg [9:0] 						      rdata_counter[MAX_DESC-1:0];
   reg [9:0] 						      rdata_counter_ff_0[MAX_DESC-1:0];
   reg [(`CLOG2(MAX_DESC))-1:0] 			      fifo_select_ff;
   reg [(`CLOG2(MAX_DESC))-1:0] 			      fifo_select_rd_per_fifo [MAX_DESC-1:0];
   reg 							      rdata_fifo_state[MAX_DESC-1:0];
   reg [MAX_DESC-1:0] 					      send_data_to_dram_per_fifo;
   reg 							      send_data_to_dram_ff;
   reg 							      send_data_to_dram_ff2;
   reg [MAX_DESC-1:0] 					      increment_offset;
   reg [MAX_DESC-1:0] 					      halt_rdata_fifo_read_per_fifo;
   reg [(`CLOG2(MAX_DESC))-1:0] 			      desc_rdata_id_per_fifo[MAX_DESC-1:0];
   reg [1:0] 						      rdata_read_out_first_bad_resp[MAX_DESC-1:0];
   reg [MAX_DESC-1:0] 					      rdata_received_bad_response;
   reg [MAX_DESC-1:0] 					      rdata_received_bad_response_ff;   
   reg [31:0] 						      rresp_status;
   reg [31:0] 						      rresp_status_we;
   reg [2:0] 						      um_as_hm_wr_data_counter;
   reg [MAX_DESC-1:0] 					      rlast_not_asserted_error_check_late;
   reg [MAX_DESC-1:0] 					      rlast_not_asserted_error_check_early;

   

   ////////////////////////////////////////////////////////////////////
   //
   // AXID Store regs & wires
   //
   ///////////////////////////////////////////////////////////////////

   
   wire [(`CLOG2(MAX_DESC))-1:0] 			      awid_response_id_reg[15:0];   
   wire [M_AXI_USR_ID_WIDTH-1:0] 			      fifo_id_reg[15:0];
   wire [MAX_DESC-1:0] 					      fifo_id_reg_valid;
   
   reg [MAX_DESC-1:0] 					      awid_read_en_reg;
   reg [MAX_DESC-1:0] 					      awid_read_en_reg_ff;
   reg [MAX_DESC-1:0] 					      ownership_done_per_fifo[MAX_DESC-1:0];
   

   ///////////////////////////////////////////////////////////////////////////
   //
   // Bresp handler regs & wires
   //
   ////////////////////////////////////////////////////////////////////////

   reg [M_AXI_USR_RUSER_WIDTH-1:0] 			      read_ruser[MAX_DESC-1:0];
   reg [31:0] 						      read_ruser_we[MAX_DESC-1:0];
   reg [MAX_DESC-1:0] 					      ownership_per_desc_rd;
   reg [MAX_DESC-1:0] 					      ownership_done_per_fifo_rd[MAX_DESC-1:0];
   reg [M_AXI_USR_ID_WIDTH-1:0] 			      bid_ff;
   reg [M_AXI_USR_BUSER_WIDTH-1:0] 			      buser_ff;
   reg 							      bresp_fifo_write_en;
   reg 							      bresp_fifo_read_en;
   reg [1:0] 						      bresp_ff;
   reg 							      bresp_not_okay;
   reg 							      bresp_fifo_read_en_ff;
   reg 							      bresp_fifo_read_en_ff2;
   reg [MAX_DESC-1:0] 					      bresp_read_id_not_found;
   reg [(`CLOG2(MAX_DESC))-1:0] 			      write_response_desc_id_per_fifo[MAX_DESC-1:0];
   reg [MAX_DESC-1:0] 					      send_bresp_to_host_per_fifo;
   
   
   wire [1:0] 						      bresp_read_resp;
   wire [M_AXI_USR_BUSER_WIDTH-1:0] 			      bresp_read_buser;
   wire 						      send_bresp_to_host;
   wire 						      bresp_valid;
   wire [M_AXI_USR_ID_WIDTH-1:0] 			      bresp_read_id;
   wire 						      bresp_fifo_empty;
   //Keeping is +1
   wire [(`CLOG2(MAX_DESC)):0] 				      write_response_desc_id;
   wire [31:0] 						      update_uc2rb_status_resp_reg;
   wire [31:0] 						      update_uc2rb_status_resp_reg_we;
   wire [MAX_DESC-1:0] 					      ownership_per_desc_rd_mode_1;





   
   //////////////////////////////////////////////////////////////////////
   //
   // Update Ownership. A pulse on Update_ownership_reg will 
   // Set Ownership_reg ( Txn is done either Rd/Wr )
   // A pulse on Ownership_flip_reg will trigger Rd/Wr generation
   //
   ///////////////////////////////////////////////////////////////////////
   
   // Tying it of to 1, as pulse is used to set 
   assign uc2rb_ownership_reg_we=32'hFFFFFFFF;

   
   always@ (posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin 
	 if(~axi_aresetn) begin
	    uc2rb_ownership_reg[k] <= 0;
	 end
	 else if (~uc2rb_ownership_reg[k]) begin
	    uc2rb_ownership_reg[k]<=ownership_flip_reg[k];
	 end
	 else begin
	    if (update_ownership_reg[k]) begin
	       uc2rb_ownership_reg[k] <= ~update_ownership_reg[k];
	    end
	    else begin
	       uc2rb_ownership_reg[k] <= uc2rb_ownership_reg[k];
	    end
	 end 
      end 
   end 

   // Connecting unused bits to 0
   always@ (posedge axi_aclk) begin
      uc2rb_ownership_reg[31:(MAX_DESC) ] <= 0;
   end
   
   ///////////////////////////////////////////////////////////////////
   //
   // Ownership done based on WR/RD responses, to upadte ownership_reg
   //
   ///////////////////////////////////////////////////////////////////

   always@(posedge axi_aclk) begin
      
      for(k=0;k<MAX_DESC;k=k+1) begin
	 if(~axi_aresetn) begin
	    update_ownership_reg[k]<=0;
	 end
	 else if(ownership_flip_reg[k]) begin
	    update_ownership_reg[k]<=0;
	 end
	 else if (ownership_done[k]) begin
	    update_ownership_reg[k]<=1;
	 end
	 else begin
	    update_ownership_reg[k]<=update_ownership_reg[k];
	 end
      end 
   end 
   

   /////////////////////////////////////////////////////////////////////////////
   //
   // Intr_comp_status_reg : Bits are set to 1, if any of the 
   // Txn is completed either bresp/rresp
   // Tying of Write Enables to 1, as Set/Reset is based on Pulse.
   //
   //////////////////////////////////////////////////////////////////////////////
   
   assign uc2rb_intr_comp_status_reg_we=32'hFFFFFFFF;
   
   always@ (posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin
	 if(~axi_aresetn) begin
	    uc2rb_intr_comp_status_reg[k] <= 0;
	 end
	 else if (~uc2rb_intr_comp_status_reg[k]) begin
	    uc2rb_intr_comp_status_reg[k]<=update_intr_comp_status_reg[k];
	 end
	 else begin
	    if (intr_comp_clear_reg[k]) begin
	       uc2rb_intr_comp_status_reg[k] <= 0;//
	    end
	    else begin
	       uc2rb_intr_comp_status_reg[k]<= uc2rb_intr_comp_status_reg[k];
	    end
	    
	 end 
      end 
   end 

   // Connecting unused bits to 0
   always@ (posedge axi_aclk) begin
      uc2rb_intr_comp_status_reg[31:(MAX_DESC) ] <= 0;
   end
   

   //////////////////////////////////////////////////////////////////////////////////
   //
   // 	Intr Comp status update 
   //
   /////////////////////////////////////////////////////////////////////////////////

   generate 
      for(i=0;i<MAX_DESC;i=i+1) begin:update_intr_comp_staus_reg_for
	 assign update_intr_comp_status_reg[i]=	bresp_completed[i] | rresp_completed[i];
      end
   endgenerate

   /////////////////////////////////////////////////////////////////////////////
   //	
   // Updating intr_error_status: To indicate that
   // there is an error, either invalid bid,rid or rlast.
   // Only ERR_0 is in the hand of User Master.
   //
   ////////////////////////////////////////////////////////////////////////////

   assign uc2rb_intr_error_status_reg_we=32'h1;
   
   always@ (posedge axi_aclk) begin
      for(k=0;k<32;k=k+1) begin
	 if(~axi_aresetn) begin
	    uc2rb_intr_error_status_reg[k] <= 0;
	 end
	 else if (~uc2rb_intr_error_status_reg[k]) begin
	    uc2rb_intr_error_status_reg[k]<=update_intr_error_status_reg[k];
	 end
	 else begin
	    if (intr_error_clear_reg[k]) begin
	       uc2rb_intr_error_status_reg[k] <= 0;//
	    end
	    else begin
	       uc2rb_intr_error_status_reg[k]<= uc2rb_intr_error_status_reg[k];
	    end
	 end 
      end 
   end 
   

   //////////////////////////////////////////////////////////////////
   // 
   // Intr Error status update, if any bid/rid not found and rlast 
   // not asserted properly
   //
   ////////////////////////////////////////////////////////////////

   assign update_intr_error_status_reg[0]=
					  bid_not_found_error | 
					  rlast_not_asserted_error | 
					  rid_not_found_error; 

   // Tying non-driven bits to 0
   assign update_intr_error_status_reg[31:1]= 0 ;
   
   

   ////////////////////////////////////////////////////////////
   //
   // Assigning AXI Control signals 
   //
   ///////////////////////////////////////////////////////////
   
   assign m_axi_usr_awvalid 	= awvalid;
   assign m_axi_usr_arvalid 	= arvalid;
   assign m_axi_usr_wvalid 	= wvalid;
   assign m_axi_usr_rready 	= rready;
   assign m_axi_usr_bready 	= bready;
   assign m_axi_usr_wlast 		= wlast;



   /////////////////////////////////////////////////////////
   // 
   // AWLEN Calcuation Total Size / (M_AXI_DATA_WIDTH/8). 
   // Considering Software will always give 
   // Total size =  awlen * (M_AXI_DATA_WIDTH/8 )
   // Flopping this into multiple stages, as its taking
   // More combo logic.
   //
   /////////////////////////////////////////////////////////

   localparam [31:0] AXI4LITE_MAX_AXSIZE = (`CLOG2((M_AXI_USR_DATA_WIDTH/8))) -3;
   always@ (posedge axi_aclk) begin

      if(EN_INTFM_AXI4LITE=='h1) begin
	 int_reg_desc_aw_txn_size<=(M_AXI_USR_DATA_WIDTH/8);
      end
      else begin
	 // Taking muxed output of each descriptor into register
	 int_reg_desc_aw_txn_size<=int_wire_desc_n_size_txn_size[desc_wr_req_id];
      end



      // Calculating len.
      // NOTE: Its Compile time MUX.
      if(RTL_USE_MODE==0) begin
	 int_reg_desc_awlen<= ( (int_reg_desc_aw_txn_size /(M_AXI_USR_DATA_WIDTH/8))-1 );
      end
      else begin
	 // In case of RTL USE Mode == 1, i.e used as HM. Need to append axlen to align with 128 Data Width of HM.
	 // If M_AXI_USR_DATA_WIDTH==32, then user can have txn_size==0x14, so need to make it 0x20 and assert
	 // wstrb accordingly. As HM is always going to be 128 bit Data Width.
	 int_reg_desc_awlen<= ( ( { int_reg_desc_aw_txn_size[15:( `CLOG2(M_AXI_USR_DATA_WIDTH/8) )], { ( (`CLOG2(M_AXI_USR_DATA_WIDTH/8) ) ){1'b0}} }
				  + {|int_reg_desc_aw_txn_size[(`CLOG2(M_AXI_USR_DATA_WIDTH/8))-1:0], { ( (`CLOG2(M_AXI_USR_DATA_WIDTH/8) ) ){1'b0}} } )
				/ (M_AXI_USR_DATA_WIDTH/8) )  -1  ;
      end 
   end 
   
   
   always@ (posedge axi_aclk) begin
      //In case of AXI4Lite txnsize is always max of one beat.
      if(EN_INTFM_AXI4LITE=='h1) begin
	 int_reg_desc_ar_txn_size<=(M_AXI_USR_DATA_WIDTH/8);
      end
      else begin
	 // Taking muxed output of each descriptor into register
	 int_reg_desc_ar_txn_size<=int_wire_desc_n_size_txn_size[desc_rd_req_id];
      end
      
      
      // Calculating len.
      if(RTL_USE_MODE==0) begin
	 int_reg_desc_arlen<= ( (int_reg_desc_ar_txn_size /(M_AXI_USR_DATA_WIDTH/8))-1 ); 
      end 
      else begin
	 int_reg_desc_arlen<= ( ( { int_reg_desc_ar_txn_size[15:( `CLOG2(M_AXI_USR_DATA_WIDTH/8) )], { ( (`CLOG2(M_AXI_USR_DATA_WIDTH/8) ) ){1'b0}} }
				  + {|int_reg_desc_ar_txn_size[(`CLOG2(M_AXI_USR_DATA_WIDTH/8))-1:0], { ( (`CLOG2(M_AXI_USR_DATA_WIDTH/8) ) ){1'b0}} } )
				/ (M_AXI_USR_DATA_WIDTH/8) )  -1  ;
      end
   end 
   
   assign int_desc_awsize = ( (EN_INTFM_AXI4LITE==1) ?
			      (`CLOG2((M_AXI_USR_DATA_WIDTH/8)))
			      :int_wire_desc_n_axsize_axsize[desc_wr_req_id]
			      );

   assign int_desc_arsize = ( (EN_INTFM_AXI4LITE==1) ?
			      (`CLOG2((M_AXI_USR_DATA_WIDTH/8)))
			      :int_wire_desc_n_axsize_axsize[desc_rd_req_id]
			      );


   ///////////////////////////////////////////////////////////////////////
   //    
   // To generate strobes for writing rdata back to memory 
   // In case of HM, DWIDTH=32,
   // One can request data worth of 0x14, in which case
   // HM sends read req of arlen=2 and arsize=4. So when 
   // Writing data back, we need to ensure last 12 bytes are
   // Not written into the DRAM memory.
   //
   //////////////////////////////////////////////////////////////////////
   
   always@ (posedge axi_aclk) begin
      if (~axi_aresetn) begin
	 hm_rlast_mem_strobes[0]<=0;
	 hm_rlast_mem_strobes[1]<=0;
	 hm_rlast_mem_strobes[2]<=0;
	 hm_rlast_mem_strobes[3]<=0;
	 hm_rlast_mem_strobes[4]<=0;
	 hm_rlast_mem_strobes[5]<=0;
	 hm_rlast_mem_strobes[6]<=0;
	 hm_rlast_mem_strobes[7]<=0;
	 hm_rlast_mem_strobes[8]<=0;
	 hm_rlast_mem_strobes[9]<=0;
	 hm_rlast_mem_strobes[10]<=0;
	 hm_rlast_mem_strobes[11]<=0;
	 hm_rlast_mem_strobes[12]<=0;
	 hm_rlast_mem_strobes[13]<=0;
	 hm_rlast_mem_strobes[14]<=0;
	 hm_rlast_mem_strobes[15]<=0;
      end
      else if((int_wire_desc_n_size_txn_size[desc_rd_req_id][3:0] & 4'hF)==4'h4 ) begin
	 hm_rlast_mem_strobes[desc_rd_req_id]<=(16'h000F);
      end
      else if((int_wire_desc_n_size_txn_size[desc_rd_req_id][3:0] & 4'hF)==4'h8 ) begin
	 hm_rlast_mem_strobes[desc_rd_req_id]<=16'h00FF;
      end
      else if((int_wire_desc_n_size_txn_size[desc_rd_req_id][3:0] & 4'hF)==4'hC ) begin
	 hm_rlast_mem_strobes[desc_rd_req_id]<=16'h0FFF;
      end
      else begin
	 hm_rlast_mem_strobes[desc_rd_req_id]<=16'hFFFF;
      end
   end	
   
   
   
   assign	desc_n_awlen 		= int_reg_desc_awlen[7:0];
   assign	desc_n_arlen 		= int_reg_desc_arlen[7:0];
   

   /////////////////////////////////////////////////////////////////////////'
   //
   // wdata_channel data assigns
   //
   /////////////////////////////////////////////////////////////////////////
   
   assign	m_axi_usr_wdata 	= wdata_read_out_wdata;
   assign	m_axi_usr_wstrb 	= wdata_read_out_wstrb; 
   assign 	m_axi_usr_wuser 	=wdata_read_out_wuser;
   assign m_axi_usr_wid = wdata_read_out_wid;
   

   //////////////////////////////////////////////////////////////////////////////
   //
   // Flopping all AXI Attrib before giving out on the BUS 
   //
   //////////////////////////////////////////////////////////////////////////////

   always@ (posedge axi_aclk) begin
      //Write channel
      axi_usr_reg_awlen  	<= desc_n_awlen[M_AXI_USR_LEN_WIDTH-1:0];
      axi_usr_reg_awaddr 	<= int_desc_n_axaddr_reg		 [desc_wr_req_id][M_AXI_USR_ADDR_WIDTH-1:0];
      axi_usr_reg_awsize  	<= int_desc_awsize ;
      axi_usr_reg_awregion      <= int_wire_desc_n_attr_axregion  	 [desc_wr_req_id];
      axi_usr_reg_awburst 	<= int_wire_desc_n_attr_axburst 	 [desc_wr_req_id];
      axi_usr_reg_awlock  	<= int_wire_desc_n_attr_axlock  	 [desc_wr_req_id];
      axi_usr_reg_awcache 	<= int_wire_desc_n_attr_axcache 	 [desc_wr_req_id];
      axi_usr_reg_awprot  	<= int_wire_desc_n_attr_axprot  	 [desc_wr_req_id];
      axi_usr_reg_awqos   	<= int_wire_desc_n_attr_axqos   	 [desc_wr_req_id];
      axi_usr_reg_awuser 	<= int_wire_desc_n_axuser 	 	 [desc_wr_req_id][M_AXI_USR_AWUSER_WIDTH-1:0];

      //Read Channel
      axi_usr_reg_araddr 	<= int_desc_n_axaddr_reg		 [desc_rd_req_id][M_AXI_USR_ADDR_WIDTH-1:0];
      axi_usr_reg_arsize  	<= int_desc_arsize ;
      axi_usr_reg_arlen  	<= desc_n_arlen[M_AXI_USR_LEN_WIDTH-1:0];
      axi_usr_reg_arregion      <= int_wire_desc_n_attr_axregion  	 [desc_rd_req_id];
      axi_usr_reg_arburst 	<= int_wire_desc_n_attr_axburst 	 [desc_rd_req_id];
      axi_usr_reg_arlock  	<= int_wire_desc_n_attr_axlock  	 [desc_rd_req_id];
      axi_usr_reg_arcache 	<= int_wire_desc_n_attr_axcache 	 [desc_rd_req_id];
      axi_usr_reg_arprot  	<= int_wire_desc_n_attr_axprot  	 [desc_rd_req_id];
      axi_usr_reg_arqos   	<= int_wire_desc_n_attr_axqos   	 [desc_rd_req_id];
      axi_usr_reg_aruser 	<= int_wire_desc_n_axuser 	 	 [desc_rd_req_id][M_AXI_USR_ARUSER_WIDTH-1:0];

      if(EN_INTFM_AXI4LITE=='h1) begin
	 axi_usr_reg_awid        <= 'h0;
	 axi_usr_reg_arid        <= 'h0;
      end
      else begin
	 axi_usr_reg_awid        <= int_desc_n_axid_reg			 [desc_wr_req_id][M_AXI_USR_ID_WIDTH-1:0];
	 axi_usr_reg_arid        <= int_desc_n_axid_reg			 [desc_rd_req_id][M_AXI_USR_ID_WIDTH-1:0];
      end
   end



   /////////////////////////////////////////////////////////////////////////////////////////
   //
   // Assigning flopped AXI Attrib to AXI Bus
   //
   /////////////////////////////////////////////////////////////////////////////////////////

   assign 	m_axi_usr_awlen  	= axi_usr_reg_awlen  	;
   assign 	m_axi_usr_arlen  	= axi_usr_reg_arlen  	;
   assign 	m_axi_usr_awaddr 	= axi_usr_reg_awaddr 	;
   assign 	m_axi_usr_araddr 	= axi_usr_reg_araddr 	;
   assign 	m_axi_usr_awid  	= axi_usr_reg_awid  	;
   assign 	m_axi_usr_arid  	= axi_usr_reg_arid  	;
   assign 	m_axi_usr_awsize  	= axi_usr_reg_awsize  	;
   assign 	m_axi_usr_arsize  	= axi_usr_reg_arsize  	;
   assign 	m_axi_usr_awregion 	= axi_usr_reg_awregion 	;
   assign 	m_axi_usr_awburst 	= axi_usr_reg_awburst 	;
   assign 	m_axi_usr_awlock  	= axi_usr_reg_awlock  	;
   assign 	m_axi_usr_awcache 	= axi_usr_reg_awcache 	;
   assign 	m_axi_usr_awprot  	= axi_usr_reg_awprot  	;
   assign 	m_axi_usr_awqos   	= axi_usr_reg_awqos   	;
   assign 	m_axi_usr_awuser 	= axi_usr_reg_awuser 	;
   assign 	m_axi_usr_arregion 	= axi_usr_reg_arregion 	;
   assign 	m_axi_usr_arburst 	= axi_usr_reg_arburst 	;
   assign 	m_axi_usr_arlock  	= axi_usr_reg_arlock  	;
   assign 	m_axi_usr_arcache 	= axi_usr_reg_arcache 	;
   assign 	m_axi_usr_arprot  	= axi_usr_reg_arprot  	;
   assign 	m_axi_usr_arqos   	= axi_usr_reg_arqos   	;
   assign 	m_axi_usr_aruser 	= axi_usr_reg_aruser 	;





   //////////////////////////////////////////////////////////////////
   //
   // awvalid_asserted :
   // For wdata_control to know that AXI request is initiated
   // on axi BUS.
   //
   /////////////////////////////////////////////////////////////////

   `FF(axi_aclk,~axi_aresetn, awvalid , awvalid_ff );
   `FF(axi_aclk,~axi_aresetn,( awvalid & (~awvalid_ff)), awvalid_pulse );
   assign awvalid_asserted = awvalid_pulse;


   //////////////////////////////////////////////////////////////////
   //
   // XNEXT: its xvalid && xready. To indicate that slave has
   // Accepted current beat of data/request etc
   //
   /////////////////////////////////////////////////////////////////
   
   assign awnext = m_axi_usr_awready && m_axi_usr_awvalid;
   assign arnext = m_axi_usr_arready && m_axi_usr_arvalid;
   assign wnext = m_axi_usr_wready & m_axi_usr_wvalid ;




   //////////////////////////////////////////////////////////////////
   //
   //		AXI BUS Control Signals.  			
   //
   //////////////////////////////////////////////////////////////////

   //AXI Awvalid 
   always @(posedge axi_aclk)                                   
     begin                                                                
	//In Reset keep awvalid low                                                           
	if  (axi_aresetn == 0 )                                           
	  begin                                                            
	     awvalid <= 1'b0;                                           
	  end                      
	//If Tx is started then assert awvalid                                        
	else if (~awvalid && gen_write)                 
	  begin                                                            
	     awvalid <= 1'b1;                                           
	  end
	//once we get awready, deassert awvalid                                                              
	else if  (m_axi_usr_awready && awvalid)                             
	  begin                                                            
	     awvalid <= 1'b0;                                           
	  end                                                              
	else 
	  begin                                                              
	     awvalid <= awvalid;                                      
	  end
     end                                                                
   

   //AXI Arvalid 
   always @(posedge axi_aclk)                                   
     begin                                                                
	//In Reset keep arvalid low                                                           
	if  (axi_aresetn == 0 )                                           
	  begin                                                            
	     arvalid <= 1'b0;                                           
	  end                      
	//If Tx is started then assert arvalid                                        
	else if (~arvalid && gen_read)                 
	  begin                                                            
	     arvalid <= 1'b1;                                           
	  end
	//once we get awready, deassert arvalid                                                              
	else if  (m_axi_usr_arready && arvalid)                             
	  begin                                                            
	     arvalid <= 1'b0;                                           
	  end                                                              
	else                                                               
	  arvalid <= arvalid;                                      
     end          

   
   //AXI wvalid 
   always @(posedge axi_aclk)                                   
     begin                                                                
	//In Reset keep valid low                                                           
	if  (axi_aresetn == 0 )                                           
	  begin                                                            
	     wvalid <= 1'b0;                                           
	  end                      
	//If Tx is started then assert valid                                        
	else if (~wvalid &&  first_write_wdata)
	  begin                                                            
	     wvalid <= ( 1'b1 );                               
	  end
	// deassert valid once wlast comes                                                              
	else if  (wlast && wnext)                             
	  begin                                                            
	     wvalid <= 1'b0;                                           
	  end                                                              
        //For HM use case if Fifo is empty wvalid should go low.
	//For UM use case, Fifo will never be empty.
	else if(wnext) begin                                                              
	   wvalid <= wdata_read_en & ~wdata_fifo_empty ;
	end
	else begin
	   wvalid<=wvalid;
	end
     end  


   //AXI bready 
   always @(posedge axi_aclk)                                   
     begin                                                                
	//In Reset keep valid low                                                           
	if  (axi_aresetn == 0 )                                           
	  begin                                                            
	     bready <= 1'b0;                                           
	  end                      
	//If Tx is started then assert valid                                        
	else if  (m_axi_usr_bvalid && ~bready)                 
	  begin                                                            
	     bready <= 1'b1;                                           
	  end
	// deassert valid once wlast comes                                                              
	else if  (bready)                             
	  begin                                                            
	     bready <= 1'b0;
	  end                                                              
	else                                                               
	  bready <= bready;                                      
     end  


   //AXI rready 
   always @(posedge axi_aclk)                                   
     begin                                                                
	//In Reset keep valid low                                                           
	if  (axi_aresetn == 0 )                                           
	  begin                                                            
	     rready<= 1'b0;                                           
	  end                      
	//If Tx is started then assert valid                                        
	else if  (m_axi_usr_rvalid && ~rdata_almost_full)                 
	  begin                                                            
	     if (m_axi_usr_rlast && rready) begin
		rready <= 1'b0;                                           
	     end
	     else begin
		rready <= 1'b1;
	     end
	  end  
	else begin
	   rready<=1'b0;
	end
     end

   ////////////////////////////////////////////////////////////////////////
   //////////////////// End of AXI BUS Signals  ///////////////////////////
   ////////////////////////////////////////////////////////////////////////
   



   ////////////////////////////////////////////////////////////////////////////
   //
   //  START of Descriptor Allocator: It looks for ownership reg changes, once 
   //  An ownership is triggered, it puts that ID into its RD/WD fifo based
   //  On txn Type.
   //   
   //  It also pops up each RD/WR fifo independently and gives ID out.
   //  So, other blocks can use it and drive corresponding txn on the
   //  AXI Bus.
   //
   /////////////////////////////////////////////////////////////////////////////



   /////////////////////////////////////////////////////////////
   //
   // Descriptor allocator module
   //
   ////////////////////////////////////////////////////////////



   descriptor_allocator_uc_master 
     descriptor_allocator  
       (
	.axi_aclk(axi_aclk),
	.axi_aresetn(axi_aresetn),
	//Based on axvalid/axready flop next id on the BUS
	.arnext(arnext),
	.awnext(awnext),
	//To identify type of txn on bus
	.desc_0_txn_type (int_wire_desc_n_txn_type_wr_rd[0]),
	.desc_1_txn_type (int_wire_desc_n_txn_type_wr_rd[1]),
	.desc_2_txn_type (int_wire_desc_n_txn_type_wr_rd[2]),
	.desc_3_txn_type (int_wire_desc_n_txn_type_wr_rd[3]),
	.desc_4_txn_type (int_wire_desc_n_txn_type_wr_rd[4]),
	.desc_5_txn_type (int_wire_desc_n_txn_type_wr_rd[5]),
	.desc_6_txn_type (int_wire_desc_n_txn_type_wr_rd[6]),
	.desc_7_txn_type (int_wire_desc_n_txn_type_wr_rd[7]),
	.desc_8_txn_type (int_wire_desc_n_txn_type_wr_rd[8]),
	.desc_9_txn_type (int_wire_desc_n_txn_type_wr_rd[9]),
	.desc_10_txn_type(int_wire_desc_n_txn_type_wr_rd[10]),
	.desc_11_txn_type(int_wire_desc_n_txn_type_wr_rd[11]),
	.desc_12_txn_type(int_wire_desc_n_txn_type_wr_rd[12]),
	.desc_13_txn_type(int_wire_desc_n_txn_type_wr_rd[13]),
	.desc_14_txn_type(int_wire_desc_n_txn_type_wr_rd[14]),
	.desc_15_txn_type(int_wire_desc_n_txn_type_wr_rd[15]),
	//Next write/Read request ID
	.write_request_id(desc_wr_req_id_out),
	.read_request_id(desc_rd_req_id_out),
	//Next write/read request en ( To tell other blocks
	//that next transfer is coming
	.read_request_en(desc_rd_req_read_en),
	.write_request_en(desc_wr_req_read_en),
       
	.wdata_pending_fifo_full(wdata_pending_fifo_full),
	//Ownership reg
	.uc2rb_ownership_reg ( uc2rb_ownership_reg[MAX_DESC-1:0]),
	//To handshake between AXID and desc_allocation
	.wr_desc_allocation_in_progress(wr_desc_allocation_in_progress),
	.rd_desc_allocation_in_progress(rd_desc_allocation_in_progress)
	);

   
   /////////////////////////////////////////////////////////////////
	 //
   // Adding logic to trigger Host Master Interface 
   //
   ////////////////////////////////////////////////////////////////
   
   // Getting Use mode from mode select register
   
   always@(posedge axi_aclk) 
     begin
	if(~axi_aresetn) begin
	   use_mode<=0;
	end
	else begin
	   use_mode<=mode_select_reg[0];
	end
     end	
   
   
   always@(posedge axi_aclk) 
     begin
	if(RTL_USE_MODE==0)  begin
	   if(~axi_aresetn) begin
	      uc2hm_trig_wr<=0;
	   end
	   else if(desc_wr_req_read_en_ff && use_mode) begin
	      uc2hm_trig_wr[desc_wr_req_id_out]<=1;
	   end
	   else begin
	      uc2hm_trig_wr<=0;
	   end
	end 
	else begin //If RTL_USE_MODE==1 i.e in HM Case
	   uc2hm_trig_wr<=0;
	end
     end

   assign uc2hm_trig = uc2hm_trig_wr | uc2hm_trig_rd;
   
   
   // HM Done bit
   
   always@(posedge axi_aclk)
     begin
	for(k=0;k<MAX_DESC;k=k+1) begin:hm_done_internal
	   if(RTL_USE_MODE==0)  begin
	      if(~axi_aresetn) begin
		 hm_done_int[k]<=0;
	      end
	      else if(uc2hm_trig_rd[k] | uc2hm_trig_wr[k])begin
		 hm_done_int[k]<=0;
	      end	
	      else if(hm2uc_done[k]) begin
		 hm_done_int[k]<=1;
	      end
	   end
	   else begin //IF RTL_USE_MODE==1 i.e HM Case
	      hm_done_int[k]<=0;
	   end
	end	
     end
   

   ////////////////////////////////////////////////////////////////
   //
   // START of Delaying_En READ/WRITE En. So That other blocks are
   // Synchronized. Basically to setup AXI BUS before new ID arrives 
   //
   ////////////////////////////////////////////////////////////////

   `FF(axi_aclk, ~axi_aresetn, desc_rd_req_read_en     , desc_rd_req_read_en_ff )
   `FF(axi_aclk, ~axi_aresetn, desc_rd_req_read_en_ff     , desc_rd_req_read_en_ff2 )
   // Triggering ~ff3 will generate/latch axi attrib on the AXI Bus for current READ
   `FF(axi_aclk, ~axi_aresetn, desc_rd_req_read_en_ff2     , desc_rd_req_read_en_ff3 )
   `FF(axi_aclk, ~axi_aresetn, desc_rd_req_read_en_ff3     , desc_rd_req_read_en_ff4 )
   `FF(axi_aclk, ~axi_aresetn, desc_rd_req_read_en_ff4     , desc_rd_req_read_en_ff5 )
   `FF(axi_aclk, ~axi_aresetn, desc_rd_req_read_en_ff5     , desc_rd_req_read_en_ff6 )
   
   

   `FF(axi_aclk, ~axi_aresetn,  desc_wr_req_read_en,   desc_wr_req_read_en_ff)
   `FF(axi_aclk, ~axi_aresetn,  desc_wr_req_read_en_ff,   desc_wr_req_read_en_ff2)
   `FF(axi_aclk, ~axi_aresetn,  desc_wr_req_read_en_ff2,   desc_wr_req_read_en_ff3)
   
   
   
   
   assign start_write_tx = desc_wr_req_read_en_ff3 ;
   assign start_read_tx = desc_rd_req_read_en_ff3  ;
   
   
   // Delaying start_write as need some time to setup
   // Axi bus before awvalid comes
   always @(posedge axi_aclk)
     begin
	//start_write_tx_ff is used to load wdata_counter
	//it is before one cycle of awvalid
	start_write_tx_ff<=start_write_tx;
	start_write_tx_ff2<=start_write_tx_ff;
	start_read_tx_ff<=start_read_tx;
	start_read_tx_ff2<=start_read_tx_ff;
     end
   
   //This will actually trigger AWVALID/ARVALID after one cycle	
   assign gen_write 	= start_write_tx_ff2;
   assign gen_read 	= start_read_tx_ff2;
   



   ////////////////////////////////////////////////////////////////
   //
   // START of Delaying_id READ/WRITE ID. So That other blocks are
   // Synchronized. Basically to setup AXI BUS before new ID arrives 
   //
   ////////////////////////////////////////////////////////////////


   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 desc_rd_req_id_out_ff<=0;
      end
      else if(desc_rd_req_read_en_ff) begin
	 desc_rd_req_id_out_ff<=desc_rd_req_id_out;
      end
      else begin
	 desc_rd_req_id_out_ff<=desc_rd_req_id_out_ff;
      end
   end
   
   
   always@(posedge axi_aclk) begin
      desc_rd_req_id_out_ff2<=desc_rd_req_id_out_ff;
   end
   
   assign desc_rd_req_id = desc_rd_req_id_out_ff2;
   
   
   // Preserving previous desc id until new id comes up.
   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 desc_wr_req_id_out_ff<=0;
      end
      else if(desc_wr_req_read_en_ff) begin
	 desc_wr_req_id_out_ff<=desc_wr_req_id_out;
      end
      else begin
	 desc_wr_req_id_out_ff<=desc_wr_req_id_out_ff;
      end
   end
   always@(posedge axi_aclk) begin
      desc_wr_req_id_out_ff2<=desc_wr_req_id_out_ff;
   end
   
   assign desc_wr_req_id = desc_wr_req_id_out_ff2;



   




   /////////////////////////////////////////////////////////////////////////////////////
   //
   // START of wdata_channel_control: It will take Desc ID read by desc_allocator 
   // block and put it into its own FIFO (W_pending_fifo) along with awlen of correspondiong
   // desc ID. 
   // Once W_pending_fifo is not empty It will start popping up requests and fetch wdata from 
   // DRAM. It will then put it into wdata_fifo and send into AXI BUS.
   //
   /////////////////////////////////////////////////////////////////////////////////////
   
   ////////////////////////////////////////////////
   //
   // Creating constant wstrb
   //
   ///////////////////////////////////////////////
   
   assign wdata_wstrb_const=512'hFFFFFFFFFFFFFFFF;
   assign wdata_wstrb=wdata_wstrb_const[(M_AXI_USR_DATA_WIDTH/8) -1:0];



   //////////////////////////////////////////////////////
   //
   // wdata control module
   //
   //////////////////////////////////////////////////////
   
   wdata_channel_control_uc_master 
     #(.MAX_DESC(MAX_DESC),
       .RAM_SIZE(RAM_SIZE),
       .M_AXI_USR_ADDR_WIDTH(M_AXI_USR_ADDR_WIDTH),
       .M_AXI_USR_DATA_WIDTH(M_AXI_USR_DATA_WIDTH),
       .M_AXI_USR_WUSER_WIDTH(M_AXI_USR_WUSER_WIDTH),
       .M_AXI_USR_ID_WIDTH(M_AXI_USR_ID_WIDTH),
       .M_AXI_USR_LEN(M_AXI_USR_LEN_WIDTH),
       .RTL_USE_MODE (RTL_USE_MODE),
       .UC_AXI_DATA_WIDTH (UC_AXI_DATA_WIDTH)) 	
   wdata_control 
     (
      
      //Inputs	
      .axi_aclk(axi_aclk),
      .axi_aresetn(axi_aresetn),
      //AWNEXT: To see which request went on AXI BUS
      .awnext ( awvalid_asserted ),
      .wnext  ( wnext ),

      //HM Done to indicate that Host Master has fetched data
      .hm_done_int (hm_done_int),
      .use_mode    (use_mode),	
      
      //write_request_id popped by desc_allocator block
      .wdata_request_id (desc_wr_req_id_out_ff2),
      //awlen on bus (which will correpond to write_request_id
      .wdata_request_awlen (m_axi_usr_awlen),
      .wdata_request_awsize  ( m_axi_usr_awsize),
      .wdata_request_awaddr (m_axi_usr_awaddr),

      //DRAM Intf
      .rb2uc_rd_data (rb2uc_rd_data),
      .rb2uc_rd_wstrb_int ( rb2uc_rd_wstrb ),
      
      //Offset txn type of each descriptor.
      .desc_0_txn_type_wr_strb	  ( int_wire_desc_n_txn_type_wr_strb[0] ),
      .desc_1_txn_type_wr_strb      ( int_wire_desc_n_txn_type_wr_strb[1] ),
      .desc_2_txn_type_wr_strb      ( int_wire_desc_n_txn_type_wr_strb[2] ),
      .desc_3_txn_type_wr_strb      ( int_wire_desc_n_txn_type_wr_strb[3] ),
      .desc_4_txn_type_wr_strb      ( int_wire_desc_n_txn_type_wr_strb[4] ),
      .desc_5_txn_type_wr_strb      ( int_wire_desc_n_txn_type_wr_strb[5] ),
      .desc_6_txn_type_wr_strb      ( int_wire_desc_n_txn_type_wr_strb[6] ),
      .desc_7_txn_type_wr_strb      ( int_wire_desc_n_txn_type_wr_strb[7] ),
      .desc_8_txn_type_wr_strb      ( int_wire_desc_n_txn_type_wr_strb[8] ),
      .desc_9_txn_type_wr_strb      ( int_wire_desc_n_txn_type_wr_strb[9] ),
      .desc_10_txn_type_wr_strb     ( int_wire_desc_n_txn_type_wr_strb[10]),
      .desc_11_txn_type_wr_strb     ( int_wire_desc_n_txn_type_wr_strb[11]),
      .desc_12_txn_type_wr_strb     ( int_wire_desc_n_txn_type_wr_strb[12]),
      .desc_13_txn_type_wr_strb     ( int_wire_desc_n_txn_type_wr_strb[13]),
      .desc_14_txn_type_wr_strb     ( int_wire_desc_n_txn_type_wr_strb[14]),
      .desc_15_txn_type_wr_strb     ( int_wire_desc_n_txn_type_wr_strb[15]),
      
      //Offset add of each descriptor.
      .desc_0_offset_addr	 ( int_wire_desc_n_data_offset_addr[0] ),
      .desc_1_offset_addr      ( int_wire_desc_n_data_offset_addr[1] ),
      .desc_2_offset_addr      ( int_wire_desc_n_data_offset_addr[2] ),
      .desc_3_offset_addr      ( int_wire_desc_n_data_offset_addr[3] ),
      .desc_4_offset_addr      ( int_wire_desc_n_data_offset_addr[4] ),
      .desc_5_offset_addr      ( int_wire_desc_n_data_offset_addr[5] ),
      .desc_6_offset_addr      ( int_wire_desc_n_data_offset_addr[6] ),
      .desc_7_offset_addr      ( int_wire_desc_n_data_offset_addr[7] ),
      .desc_8_offset_addr      ( int_wire_desc_n_data_offset_addr[8] ),
      .desc_9_offset_addr      ( int_wire_desc_n_data_offset_addr[9] ),
      .desc_10_offset_addr     ( int_wire_desc_n_data_offset_addr[10]),
      .desc_11_offset_addr     ( int_wire_desc_n_data_offset_addr[11]),
      .desc_12_offset_addr     ( int_wire_desc_n_data_offset_addr[12]),
      .desc_13_offset_addr     ( int_wire_desc_n_data_offset_addr[13]),
      .desc_14_offset_addr     ( int_wire_desc_n_data_offset_addr[14]),
      .desc_15_offset_addr     ( int_wire_desc_n_data_offset_addr[15]),

      //txn size of each descriptor.
      .desc_0_txn_size	  ( int_wire_desc_n_size_txn_size[0] ),
      .desc_1_txn_size      ( int_wire_desc_n_size_txn_size[1] ),
      .desc_2_txn_size      ( int_wire_desc_n_size_txn_size[2] ),
      .desc_3_txn_size      ( int_wire_desc_n_size_txn_size[3] ),
      .desc_4_txn_size      ( int_wire_desc_n_size_txn_size[4] ),
      .desc_5_txn_size      ( int_wire_desc_n_size_txn_size[5] ),
      .desc_6_txn_size      ( int_wire_desc_n_size_txn_size[6] ),
      .desc_7_txn_size      ( int_wire_desc_n_size_txn_size[7] ),
      .desc_8_txn_size      ( int_wire_desc_n_size_txn_size[8] ),
      .desc_9_txn_size      ( int_wire_desc_n_size_txn_size[9] ),
      .desc_10_txn_size     ( int_wire_desc_n_size_txn_size[10]),
      .desc_11_txn_size     ( int_wire_desc_n_size_txn_size[11]),
      .desc_12_txn_size     ( int_wire_desc_n_size_txn_size[12]),
      .desc_13_txn_size     ( int_wire_desc_n_size_txn_size[13]),
      .desc_14_txn_size     ( int_wire_desc_n_size_txn_size[14]),
      .desc_15_txn_size     ( int_wire_desc_n_size_txn_size[15]),
      

      //Outputs	
      //Following are Popped from fifo.
      //To get Desc ID/AWLEN info.
      .wdata_current_request_awlen (wdata_pending_awlen),
      .wdata_current_request_id (wdata_pending_id),
      .W_pending_read_en(wdata_pending_read_en),
      .W_pending_fifo_full (wdata_pending_fifo_full),
      
      
      //Wstrb/wdata/wuser out from fifo
      .wdata_read_out_wdata (wdata_read_out_wdata),
      .wdata_read_out_wstrb (wdata_read_out_wstrb),
      .wdata_read_out_wuser (wdata_read_out_wuser),
      .wdata_read_out_wid (wdata_read_out_wid),
      
      //DRAM Interface
      .uc2rb_rd_addr (uc2rb_rd_addr),
      // For HM to know desc id of corresponding address
      .uc2rb_rd_addr_desc_id ( uc2rb_rd_addr_desc_id),
      
      //This is the trigger pulse wlast/wvalid.
      .first_write_wdata	 (first_write_wdata),
      .wdata_fifo_empty (wdata_fifo_empty),
      .wdata_read_en (wdata_read_en),
      //Depending on current wdata on bus, muxing wuser from registers
      .wdata_wuser_in		 (int_wire_desc_n_wuser[wdata_pending_id][M_AXI_USR_WUSER_WIDTH-1:0]),
      .wdata_wid_in		 (int_desc_n_axid_reg[wdata_pending_id][M_AXI_USR_ID_WIDTH-1:0]),
      .wdata_read_out_wlast ( wlast)
      
      );


   ///////////////////////////////////////////////////////////////////////////////////////////
       //////////// END of wdata_channel_control /////////////////////////////////////////////////
       ///////////////////////////////////////////////////////////////////////////////////////////
       
   
   /////////////////////////////////////////////////////////////
       // Flop read en as data is valid on next cycle It is used
   // by wlast counter
   ////////////////////////////////////////////////////////////

   always@ (posedge axi_aclk) 
     begin
	wdata_pending_read_en_ff<=wdata_pending_read_en;
     end
   

   
   
   //////////////////////////////////////////////////////////////////////////////////////////////////////
   // 
   // START of AWID_STORE : it fetches what all AXI Write request went on bus and puts corresponding 
   // AWID into FIFO, there are 16 fifos per unique ID. So, in the response case, same fifo is popped
   // based on BID, and corresponding ID's RDATA_RAM/Registers are updated with rdata/response
   //
   /////////////////////////////////////////////////////////////////////////////////////////////////////



   axid_store 
     #(.MAX_DESC(MAX_DESC), .M_AXI_USR_ID_WIDTH(M_AXI_USR_ID_WIDTH))
   awid_store 
     (
      
      // Inputs
      .axi_aclk	(axi_aclk),
      .axi_aresetn	(axi_aresetn),
      
      //AXID on the BUS will be stored into Fifo
      .m_axi_usr_axid	(m_axi_usr_awid),
      .axid_read_en	(awid_read_en_reg),
      
      //AWNEXT to indicated sampling of AWID
      .axnext		(awnext),
      
      .fifo_id_reg_valid_ff	(fifo_id_reg_valid),
      //From Read Fifo
      .desc_req_id		(desc_wr_req_id),
      
      .axid_response_id0	(awid_response_id_reg[0]),
      .axid_response_id1	(awid_response_id_reg[1]),
      .axid_response_id2	(awid_response_id_reg[2]),
      .axid_response_id3	(awid_response_id_reg[3]),
      .axid_response_id4	(awid_response_id_reg[4]),
      .axid_response_id5	(awid_response_id_reg[5]),
      .axid_response_id6	(awid_response_id_reg[6]),
      .axid_response_id7	(awid_response_id_reg[7]),
      .axid_response_id8	(awid_response_id_reg[8]),
      .axid_response_id9	(awid_response_id_reg[9]),
      .axid_response_id10	(awid_response_id_reg[10]),
      .axid_response_id11	(awid_response_id_reg[11]),
      .axid_response_id12	(awid_response_id_reg[12]),
      .axid_response_id13	(awid_response_id_reg[13]),
      .axid_response_id14	(awid_response_id_reg[14]),
      .axid_response_id15	(awid_response_id_reg[15]),
      
      .fifo_id_reg0	(fifo_id_reg[0]),
      .fifo_id_reg1	(fifo_id_reg[1]),
      .fifo_id_reg2	(fifo_id_reg[2]),
      .fifo_id_reg3	(fifo_id_reg[3]),
      .fifo_id_reg4	(fifo_id_reg[4]),
      .fifo_id_reg5	(fifo_id_reg[5]),
      .fifo_id_reg6	(fifo_id_reg[6]),
      .fifo_id_reg7	(fifo_id_reg[7]),
      .fifo_id_reg8	(fifo_id_reg[8]),
      .fifo_id_reg9	(fifo_id_reg[9]),
      .fifo_id_reg10	(fifo_id_reg[10]),
      .fifo_id_reg11	(fifo_id_reg[11]),
      .fifo_id_reg12	(fifo_id_reg[12]),
      .fifo_id_reg13	(fifo_id_reg[13]),
      .fifo_id_reg14	(fifo_id_reg[14]),
      .fifo_id_reg15	(fifo_id_reg[15]),
      // This is a handshake between desc_allocation block and axid_store_block.
      // desc_allocation block should not start popping new requests untill
      // AXID block has allocated existing request which is on the bus
      .desc_allocation_in_progress(wr_desc_allocation_in_progress)
      );
   

   /////////////////////////////////////////////////////////////////////
       //
   // TO sync with awid_read_en pulse
   //
   /////////////////////////////////////////////////////////////////////

   always@ (posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:awid_read_for
	 if(~axi_aresetn) begin
	    awid_read_en_reg_ff[k]<=0;
	 end
	 else begin
	    awid_read_en_reg_ff[k]<=awid_read_en_reg[k];
	 end
      end
   end


   //////////////////////////////////////////////////////////////////////
   //
   // Update Ownership, once any AWID_response_id is popped	
   // It indicateds that BID is found in one of the FIFO(16 fifos)	
   //
   /////////////////////////////////////////////////////////////////////

   always@(posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:ownership_update
	 if(~axi_aresetn) begin
	    ownership_done_per_fifo[k]<='h0;
	 end
	 else if(awid_read_en_reg_ff[k]) begin
	    ownership_done_per_fifo[k][awid_response_id_reg[k]]<=1;
	 end
	 else begin
	    ownership_done_per_fifo[k]<=0;
	 end
      end
   end





   //////////////////////////////////////////////////////////////////////
   //
   // START of Bresp_handler	
   //
   //////////////////////////////////////////////////////////////////////////

   
   ////////////////////////////////////////////////////////////////////////////
   //
   // Bresp_update: It updates bresp, buser once descriptor_id of received bid
   // is found in Fifo.
   //
   ////////////////////////////////////////////////////////////////////////////


   assign send_bresp_to_host= |send_bresp_to_host_per_fifo;
   assign ownership_done[MAX_DESC-1:0]= ownership_per_desc_wr | ( (use_mode==0) ? ownership_per_desc_rd : ownership_per_desc_rd_mode_1 );


   assign uc2hm_trig_rd={MAX_DESC{use_mode}} & ownership_per_desc_rd;

   assign ownership_per_desc_rd_mode_1=  hm2uc_done & int_wire_desc_n_txn_type_wr_rd; 


   // Bresp_valid 
   assign bresp_valid = m_axi_usr_bvalid && bready;

   ///////////////////////////////////////////
   //
   // When bvalid is high, flop response signals
   //
   ///////////////////////////////////////////

   always@ (posedge axi_aclk) begin
      
      if(bresp_valid) begin
	 bid_ff<=m_axi_usr_bid;
	 bresp_ff<=m_axi_usr_bresp;
	 buser_ff<=m_axi_usr_buser;
      end
      else begin
	 bid_ff<=bid_ff;
	 bresp_ff<=bresp_ff;
	 buser_ff<=buser_ff;
      end
   end


   //////////////////////////////////////////////////
   //
   // When bvalid is high, assert bresp_fifo_write en
   //
   ///////////////////////////////////////////////////
   
   always@( posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 bresp_fifo_write_en<=0;		
      end
      else if (bresp_valid) begin
	 bresp_fifo_write_en<=1;		
      end
      else begin
	 bresp_fifo_write_en<=0;		
      end
   end



   ///////////////////////////////////////////////////////////////
   //
   // Once bresp_fifo is full, pop it and wait for one more cycle
   // before popping next bresp 
   //
   ////////////////////////////////////////////////////////////////
   

   always@( posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 bresp_fifo_read_en<=0;
	 bresp_delay<=0;		
      end
      else if (~bresp_fifo_empty && ~bresp_delay ) begin
	 bresp_fifo_read_en<=1;		
	 bresp_delay<=1;		
      end
      else if (bresp_delay) begin
	 bresp_fifo_read_en<=0;
	 bresp_delay<=0;		
      end
      else begin
	 bresp_fifo_read_en<=0;
      end
      
   end	
   


   ////////////////////////////////////////////////////////////////
   //
   // BRESP fifo
   //
   ///////////////////////////////////////////////////////////////

   sync_fifo  #(.DEPTH((MAX_DESC)), .WIDTH(M_AXI_USR_ID_WIDTH + 2 + M_AXI_USR_BUSER_WIDTH))
   bresp_fifo 
     (
      .clk(axi_aclk),
      .rst_n(axi_aresetn),
      .din({bid_ff,bresp_ff,buser_ff}),
      .wren(bresp_fifo_write_en),
      .empty(bresp_fifo_empty),
      .full(),
      .dout({bresp_read_id,bresp_read_resp,bresp_read_buser}),
      .rden(bresp_fifo_read_en)
      );
   
   
   
   ////////////////////////////////////////////////////////////
   //
   // Synchronize fifo_read_en with id_out.
   //
   ///////////////////////////////////////////////////////////
   
   always@ (posedge axi_aclk) begin
      bresp_fifo_read_en_ff<=bresp_fifo_read_en;
      bresp_fifo_read_en_ff2<=bresp_fifo_read_en_ff;
      
   end
   

   /////////////////////////////////////////////////////////////////////////
   //
   // BID comparison: It compares id popped from bresp_fifo with one of 
   // the MAX_DESC FIFOs. If there is a match, bresp is sent to the corresponding
   // desc_id (From FIFO Out )
   //
   // Here, desc_id is found by looking at Fifo's data bus,
   // as fifo is used in such a way that it always point to the NEXT data  
   // So, even without popping from FIFO, desc_id can be read.
   //
   // **It is useful in read case, when there is a need to fetch multiple rdata
   // with same rid and decrement counters of each descriptor.
   //
   /////////////////////////////////////////////////////////////////////////
   
   
   always@( posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:gen_bresp
	 if(~axi_aresetn) begin
	    awid_read_en_reg[k]<=0;
	    send_bresp_to_host_per_fifo[k]<=0;	
	    bresp_read_id_not_found[k]<=0;
	    write_response_desc_id_per_fifo[k]<=0;	
	 end 
	 else if(bresp_fifo_read_en_ff) begin
	    //Check in each fifo if bid matches with register.
	    //If yes then asser awid_read_en of corresponding fifo
	    if((bresp_read_id==fifo_id_reg[k]) && fifo_id_reg_valid[k]) begin
	       write_response_desc_id_per_fifo[k]<=awid_response_id_reg[k];
	       send_bresp_to_host_per_fifo[k]<=1;	
	       //This is per Fifo
	       awid_read_en_reg[k]<=1;
	       bresp_read_id_not_found[k]<=0;
	    end
	    else begin
	       bresp_read_id_not_found[k]<=1;
	       write_response_desc_id_per_fifo[k]<=0;	
	    end
	 end
	 else begin
	    awid_read_en_reg[k]<=0;
	    send_bresp_to_host_per_fifo[k]<=0;	
	    bresp_read_id_not_found[k]<=0;
	 end
      end
   end


   ////////////////////////////////////////////////////////////////////////
   //
   // Combining 16 FIFOs and ORed as only single fifo will have unique ID
   // only single will be active at a time
   //
   ////////////////////////////////////////////////////////////////////////
   
   assign write_response_desc_id = (
				    write_response_desc_id_per_fifo[0] |
				    ( ( MAX_DESC > 1 ) ?	write_response_desc_id_per_fifo[1]  : 0 ) |
				    ( ( MAX_DESC > 2 ) ?	write_response_desc_id_per_fifo[2]  : 0 ) |
				    ( ( MAX_DESC > 3 ) ?	write_response_desc_id_per_fifo[3]  : 0 ) |
				    ( ( MAX_DESC > 4 ) ?	write_response_desc_id_per_fifo[4]  : 0 ) |
				    ( ( MAX_DESC > 5 ) ?	write_response_desc_id_per_fifo[5]  : 0 ) |
				    ( ( MAX_DESC > 6 ) ?	write_response_desc_id_per_fifo[6]  : 0 ) |
				    ( ( MAX_DESC > 7 ) ?	write_response_desc_id_per_fifo[7]  : 0 ) |
				    ( ( MAX_DESC > 8 ) ?	write_response_desc_id_per_fifo[8]  : 0 ) |
				    ( ( MAX_DESC > 9 ) ?	write_response_desc_id_per_fifo[9]  : 0 ) |
				    ( ( MAX_DESC > 10 ) ?	write_response_desc_id_per_fifo[10] : 0 ) |
				    ( ( MAX_DESC > 11 ) ?	write_response_desc_id_per_fifo[11] : 0 ) |
				    ( ( MAX_DESC > 12 ) ?	write_response_desc_id_per_fifo[12] : 0 ) |
				    ( ( MAX_DESC > 13 ) ?	write_response_desc_id_per_fifo[13] : 0 ) |
				    ( ( MAX_DESC > 14 ) ?	write_response_desc_id_per_fifo[14] : 0 ) |
				    ( ( MAX_DESC > 15 ) ?	write_response_desc_id_per_fifo[15] : 0 )
				    );
   
   

   //////////////////////////////////////////////////////////////////
   //
   // If none of the bid matches, assert bid_not_found_error
   // Which will eventually go as intr_error[0] bit.
   //
   /////////////////////////////////////////////////////////////////
   
   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 bid_not_found_error<=0;
      end
      else if ( (bresp_read_id_not_found=='hFFFF)) begin	
	 bid_not_found_error<=1;
      end
      else begin
	 bid_not_found_error<=0;
      end
      
   end

   ////////////////////////////////////////////////////////////////////
   //
   //  Updating bresp user and bresp status to registe
   //
   ///////////////////////////////////////////////////////////////////
   
   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 bresp_completed<=0;
	 ownership_per_desc_wr<=0;
	 bresp_status<=0;	
	 bresp_status_we<=0;
	 for(k=0;k<MAX_DESC;k=k+1)
	   begin :bresp_busr_regs_init
	      bresp_buser[k]<=0;
	      bresp_buser_we[k]<=0;
	   end
      end
      else if(send_bresp_to_host) begin
	 //Indicate that bresp is completed in 
	 //Intr_comp_reg.
	 bresp_completed[write_response_desc_id]<='b1;
	 //Indicate that Ownership is done for this Descriptor
	 ownership_per_desc_wr[write_response_desc_id]<='b1;
	 //Write back bresp into register. (In status_resp reg )
	 bresp_status[(write_response_desc_id<<1)]<=bresp_read_resp[0];	
	 bresp_status[(write_response_desc_id<<1)+1]<=bresp_read_resp[1];	
	 bresp_buser[write_response_desc_id]<=bresp_read_buser;
	 bresp_buser_we[write_response_desc_id]<=32'hFFFFFFFF;
	 //Enable corresponding strobes
	 bresp_status_we[(write_response_desc_id<<1)]<=1'b1;	
	 bresp_status_we[(write_response_desc_id<<1)+1]<=1'b1;	
      end
      else begin
	 bresp_completed<=0;
	 ownership_per_desc_wr<=0;
	 bresp_status<=0;	
	 bresp_status_we<=0;
	 for(k=0;k<MAX_DESC;k=k+1)
	   begin :bresp_busr_regs_init_clear
	      bresp_buser[k]<=0;
	      bresp_buser_we[k]<=0;
	   end
      end
   end




   /////////////////////////////////////////////////////////////////////////////////
   //
   // Bresp/Rresp  status update
   //
   /////////////////////////////////////////////////////////////////////////////////

   assign update_uc2rb_status_resp_reg =  bresp_status | rresp_status ; 
   assign update_uc2rb_status_resp_reg_we =   bresp_status_we | rresp_status_we;
   
   
   always@( posedge axi_aclk)begin
      if(~axi_aresetn) begin
	 uc2rb_status_resp_reg_we<=0;
	 uc2rb_status_resp_reg<=0;
      end
      else begin
	 uc2rb_status_resp_reg_we<=update_uc2rb_status_resp_reg_we;
	 uc2rb_status_resp_reg<=update_uc2rb_status_resp_reg;
      end
   end



   ///////////////////////////////////////////////////////////////////////////////////////////////////////
   /// 
   /// START of RDATA_CHENNEL : it fetches all the AXI Read requests that are on bus and places corresponding 
   /// ARID into FIFO. There are MAX_DESC number of Fifos, each represents an unique ID. 
   /// When read response arrives, a fifo is popped based on RID, and corresponding Desc ID's 
   /// RDATA_RAM/Registers are updated with rdata/response
   ///
   //////////////////////////////////////////////////////////////////////////////////////////////////////



   
   axid_store #(
		.MAX_DESC(MAX_DESC), 
		.M_AXI_USR_ID_WIDTH(M_AXI_USR_ID_WIDTH)
		)
   arid_store (
      
	       // Inputs
	       .axi_aclk	(axi_aclk),
	       .axi_aresetn	(axi_aresetn),
      
	       //AXID on the BUS will be stored into Fifo
	       .m_axi_usr_axid	(m_axi_usr_arid),
	       .axid_read_en	(arid_read_en_reg),
      
	       //AWNEXT to indicated sampling of AWID
	       .axnext		(arnext),
      
	       .fifo_id_reg_valid_ff	(fifo_id_rd_reg_valid),
      
	       //From Read Fifo
	       .desc_req_id		(desc_rd_req_id),
      
	       .axid_response_id0	(arid_response_id_reg[0]),
	       .axid_response_id1	(arid_response_id_reg[1]),
	       .axid_response_id2	(arid_response_id_reg[2]),
	       .axid_response_id3	(arid_response_id_reg[3]),
	       .axid_response_id4	(arid_response_id_reg[4]),
	       .axid_response_id5	(arid_response_id_reg[5]),
	       .axid_response_id6	(arid_response_id_reg[6]),
	       .axid_response_id7	(arid_response_id_reg[7]),
	       .axid_response_id8	(arid_response_id_reg[8]),
	       .axid_response_id9	(arid_response_id_reg[9]),
	       .axid_response_id10	(arid_response_id_reg[10]),
	       .axid_response_id11	(arid_response_id_reg[11]),
	       .axid_response_id12	(arid_response_id_reg[12]),
	       .axid_response_id13	(arid_response_id_reg[13]),
	       .axid_response_id14	(arid_response_id_reg[14]),
	       .axid_response_id15	(arid_response_id_reg[15]),
      
	       .fifo_id_reg0	(fifo_id_rd_reg[0]),
	       .fifo_id_reg1	(fifo_id_rd_reg[1]),
	       .fifo_id_reg2	(fifo_id_rd_reg[2]),
	       .fifo_id_reg3	(fifo_id_rd_reg[3]),
	       .fifo_id_reg4	(fifo_id_rd_reg[4]),
	       .fifo_id_reg5	(fifo_id_rd_reg[5]),
	       .fifo_id_reg6	(fifo_id_rd_reg[6]),
	       .fifo_id_reg7	(fifo_id_rd_reg[7]),
	       .fifo_id_reg8	(fifo_id_rd_reg[8]),
	       .fifo_id_reg9	(fifo_id_rd_reg[9]),
	       .fifo_id_reg10	(fifo_id_rd_reg[10]),
	       .fifo_id_reg11	(fifo_id_rd_reg[11]),
	       .fifo_id_reg12	(fifo_id_rd_reg[12]),
	       .fifo_id_reg13	(fifo_id_rd_reg[13]),
	       .fifo_id_reg14	(fifo_id_rd_reg[14]),
	       .fifo_id_reg15	(fifo_id_rd_reg[15]),
      
	       .desc_allocation_in_progress(rd_desc_allocation_in_progress)
	       );



   /////////////////////////////////////////////////////////////////////
     //
   // Flopping arid_read_en as, arid_response needs to be sampled on the
   // next edge. Data from FIFO will be valid on next cycle
   //
   ////////////////////////////////////////////////////////////////////
   
   always@ (posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:arid_read_for
	 if(~axi_aresetn) begin
	    arid_read_en_reg_ff[k]<=0;
	 end
	 else begin
	    arid_read_en_reg_ff[k]<=arid_read_en_reg[k];
	 end
      end
   end



   //////////////////////////////////////////////////////////////////////
   //
   // From AXI BUS, Flopping incoming data,resp,id,valid before using it
   //
   /////////////////////////////////////////////////////////////////////
   
   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 rdata_in<=0;
	 rvalid_in<=0;
	 
	 rresp_in<=0;
	 
	 rid_in<=0;
	 rlast_in<=0;
	 
      end
      else begin
	 rdata_in<=m_axi_usr_rdata;
	 rvalid_in<=m_axi_usr_rvalid;
	 
	 rresp_in<=m_axi_usr_rresp;
	 ruser_in<=m_axi_usr_ruser;
	 
	 rid_in<=m_axi_usr_rid;
	 rlast_in<=m_axi_usr_rlast;
      end
   end


   // rvalid & rready handshake on bus
   assign rnext_on_bus= m_axi_usr_rvalid & m_axi_usr_rready;
   
   always@(posedge axi_aclk) begin
      rnext_on_bus_ff<=rnext_on_bus;
   end



   //////////////////////////////////////////////////////////////////////////////////////
   //
   // RDATA Fifo, it stores RDATA from AXI BUS directly, it also stores, rresp, rlast 
   // ,rid and ruser
   //
   //////////////////////////////////////////////////////////////////////////////////////
   
   
   sync_fifo  #(.DEPTH(MAX_DESC), .WIDTH(M_AXI_USR_DATA_WIDTH+M_AXI_USR_ID_WIDTH+2+1 + M_AXI_USR_RUSER_WIDTH))
   rdata_fifo 
     (
      .clk(axi_aclk),
      .rst_n(axi_aresetn),
      .din({rdata_in,rid_in,rresp_in,rlast_in,ruser_in}),
      .wren(rnext_on_bus_ff),
      .empty(rdata_fifo_empty),
      .full(rdata_fifo_full),
      .dout({rdata_read_out_data,rdata_read_out_id,rdata_read_out_resp,rdata_read_out_rlast,rdata_read_out_ruser}),
      .rden(rdata_read_en),
      .fifo_counter(rdata_fifo_counter)
      );

   //assert almost full flag if fifo is full-1
   assign rdata_almost_full= ((rdata_fifo_counter >(MAX_DESC-3))?1:0);



   ////////////////////////////////////////////////////////////////////////////////
   //
   // FSM to read data from rdata_fifo and halting it until data is not processed
   //
   /////////////////////////////////////////////////////////////////////////////////

   
   
   assign um_as_hm_max_wr_delay = (RTL_USE_MODE==1) ? (rdata_read_en | rdata_read_en_ff | rdata_read_en_ff2 | rdata_read_en_ff3 | rdata_read_en_ff4) : 0;

   
   
   localparam RDATA_READ_IDLE=2'b00,RDATA_READ_WAIT=2'b01,RDATA_READ_WAIT_2=2'b10,RDATA_READ_WAIT_3=2'b11;
   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 rdata_read_en<=0;
	 rdata_fifo_read<=RDATA_READ_IDLE;
      end
      else begin
	 case(rdata_fifo_read) 
	   RDATA_READ_IDLE:
	     if(~rdata_fifo_empty) begin
		rdata_read_en<=1;
		rdata_fifo_read<=RDATA_READ_WAIT;
	     end
	     else begin
		rdata_read_en<=0;
		rdata_fifo_read<=RDATA_READ_IDLE;
	     end
	   RDATA_READ_WAIT:
	     begin
		rdata_read_en<=0;
		rdata_fifo_read<=RDATA_READ_WAIT_2;
	     end
	   RDATA_READ_WAIT_2:
	     if(halt_rdata_fifo_read || um_as_hm_max_wr_delay) begin
		rdata_read_en<=0;
		rdata_fifo_read<=RDATA_READ_WAIT_2;
	     end
	     else begin
		rdata_fifo_read<=RDATA_READ_IDLE;
	     end
	   default:
	     rdata_fifo_read<=rdata_fifo_read;
	 endcase 
      end
   end

   //////////////////////////////////////////
   //
   // Flopping to sync with rdata_out
   //
   //////////////////////////////////////////

   always@ (posedge axi_aclk) begin
      rdata_read_en_ff<=rdata_read_en;
      rdata_read_en_ff2<=rdata_read_en_ff;
      rdata_read_en_ff3<=rdata_read_en_ff2;
      rdata_read_en_ff4<=rdata_read_en_ff3;	  
   end



   //////////////////////////////////////////////////////////////////
   //
   // FSM to fetch data from rdata_fifo and identifiy which desc it
   // it belongs to by looking at rid. 
   //
   ////////////////////////////////////////////////////////////////////


   localparam RDATA_FIFO_IDLE=1'b0, RDATA_FIFO_MATCH_ID=1'b1;
   always@ (posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin
	 if(~axi_aresetn) begin
	    halt_rdata_fifo_read_per_fifo[k]<=0;
	    send_data_to_dram_per_fifo[k]<=0;
	    fifo_select_rd_per_fifo[k]<=0;
	    desc_rdata_id_per_fifo[k]<=0;
	    rdata_fifo_state[k]<=RDATA_FIFO_IDLE;
	 end
	 else begin 
	    case(rdata_fifo_state[k])
	      RDATA_FIFO_IDLE:
		if(rdata_read_en) begin
		   halt_rdata_fifo_read_per_fifo[k]<=1;
		   send_data_to_dram_per_fifo[k]<=0;
		   fifo_select_rd_per_fifo[k]<=0;
		   rdata_fifo_state[k]<=RDATA_FIFO_MATCH_ID;
		end
		else begin
		   halt_rdata_fifo_read_per_fifo[k]<=0;
		   send_data_to_dram_per_fifo[k]<=0;
		   fifo_select_rd_per_fifo[k]<=0;
		   rdata_fifo_state[k]<=RDATA_FIFO_IDLE;
		end	
	      RDATA_FIFO_MATCH_ID:
		if((rdata_read_out_id==fifo_id_rd_reg[k]) && fifo_id_rd_reg_valid[k]) begin
		   send_data_to_dram_per_fifo[k]<=1;
		   desc_rdata_id_per_fifo[k]<=arid_response_id_reg[k];
		   fifo_select_rd_per_fifo[k]<=k;
		   rdata_fifo_state[k]<=RDATA_FIFO_IDLE;
		end
		else begin
		   desc_rdata_id_per_fifo[k]<=0;
		   fifo_select_rd_per_fifo[k]<=0;
		   rdata_fifo_state[k]<=RDATA_FIFO_IDLE;
		end
	    endcase		
	 end
      end
   end


   //////////////////////////////////////////////////////////////////
   //
   // Flopping send_data_to_dram trigger signal, to sync with
   // Other blocks	
   //
   //////////////////////////////////////////////////////////////////

   always@ (posedge axi_aclk) begin
      send_data_to_dram_ff<=send_data_to_dram;
      send_data_to_dram_ff2<=send_data_to_dram_ff;
   end
   

   ///////////////////////////////////////////////////////////////////
   //
   // ORed desc_rdata_id from all fifos, as only one is active 
   // at a time
   //	
   ///////////////////////////////////////////////////////////////////

   assign desc_rdata_id	= (
			   desc_rdata_id_per_fifo[0] |
			   ( ( MAX_DESC > 1) ? desc_rdata_id_per_fifo[1]  : 0 ) |
			   ( ( MAX_DESC > 2) ? desc_rdata_id_per_fifo[2]  : 0 ) |
			   ( ( MAX_DESC > 3) ? desc_rdata_id_per_fifo[3]  : 0 ) |
			   ( ( MAX_DESC > 4) ? desc_rdata_id_per_fifo[4]  : 0 ) |
			   ( ( MAX_DESC > 5) ? desc_rdata_id_per_fifo[5]  : 0 ) |
			   ( ( MAX_DESC > 6) ? desc_rdata_id_per_fifo[6]  : 0 ) |
			   ( ( MAX_DESC > 7) ? desc_rdata_id_per_fifo[7]  : 0 ) |
			   ( ( MAX_DESC > 8) ? desc_rdata_id_per_fifo[8]  : 0 ) |
			   ( ( MAX_DESC > 9) ? desc_rdata_id_per_fifo[9]  : 0 ) |
			   ( ( MAX_DESC > 10) ? desc_rdata_id_per_fifo[10] : 0 ) |
			   ( ( MAX_DESC > 11) ? desc_rdata_id_per_fifo[11] : 0 ) |
			   ( ( MAX_DESC > 12) ? desc_rdata_id_per_fifo[12] : 0 ) |
			   ( ( MAX_DESC > 13) ? desc_rdata_id_per_fifo[13] : 0 ) |
			   ( ( MAX_DESC > 14) ? desc_rdata_id_per_fifo[14] : 0 ) |
			   ( ( MAX_DESC > 15) ? desc_rdata_id_per_fifo[15] : 0 )
			   );

   assign fifo_select = (
			 fifo_select_rd_per_fifo[0] |
			 ( ( MAX_DESC > 1 ) ? fifo_select_rd_per_fifo[1]  : 0 ) |
			 ( ( MAX_DESC > 2 ) ? fifo_select_rd_per_fifo[2]  : 0 ) |
			 ( ( MAX_DESC > 3 ) ? fifo_select_rd_per_fifo[3]  : 0 ) |
			 ( ( MAX_DESC > 4 ) ? fifo_select_rd_per_fifo[4]  : 0 ) |
			 ( ( MAX_DESC > 5 ) ? fifo_select_rd_per_fifo[5]  : 0 ) |
			 ( ( MAX_DESC > 6 ) ? fifo_select_rd_per_fifo[6]  : 0 ) |
			 ( ( MAX_DESC > 7 ) ? fifo_select_rd_per_fifo[7]  : 0 ) |
			 ( ( MAX_DESC > 8 ) ? fifo_select_rd_per_fifo[8]  : 0 ) |
			 ( ( MAX_DESC > 9 ) ? fifo_select_rd_per_fifo[9]  : 0 ) |
			 ( ( MAX_DESC > 10 ) ? fifo_select_rd_per_fifo[10] : 0 ) |
			 ( ( MAX_DESC > 11 ) ? fifo_select_rd_per_fifo[11] : 0 ) |
			 ( ( MAX_DESC > 12 ) ? fifo_select_rd_per_fifo[12] : 0 ) |
			 ( ( MAX_DESC > 13 ) ? fifo_select_rd_per_fifo[13] : 0 ) |
			 ( ( MAX_DESC > 14 ) ? fifo_select_rd_per_fifo[14] : 0 ) |
			 ( ( MAX_DESC > 15 ) ? fifo_select_rd_per_fifo[15] : 0 )
			 );

   /////////////////////////////////////////////////////
   //
   // Halt fifo read: to stop fetching one more data
   // untill current data is processed.
   //
   //////////////////////////////////////////////////////
   
   assign halt_rdata_fifo_read = | halt_rdata_fifo_read_per_fifo;
   
   ///////////////////////////////////////////////////////////////////
   //
   // ORed send_data_to_dram from all fifos, as only one is active 
   // at a time
   //	
   ///////////////////////////////////////////////////////////////////

   assign send_data_to_dram  = |send_data_to_dram_per_fifo; 


   /////////////////////////////////////////////////////////////////////
   //
   // Rdata_counter: Maintaining Counters per unique ID. Flopping it and
   // creating _ff_0, which will be used to identify it counter has
   // been decremented frmo 1 to 0.
   //
   //////////////////////////////////////////////////////////////////////

   always@ (posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:rdata_count_pulse
	 rdata_counter_ff_0[k]<=rdata_counter[k];
      end
   end
   
   /////////////////////////////////////////////////////////////////////
   //
   // Generate pulse when rdata_counter[Per Desc] goes from 0x1 to 0x0.
   // This is used to identify if rlast came correclty, or should reponse
   // be routed back to Host
   //
   //////////////////////////////////////////////////////////////////////
   
   generate
      for(i=0;i<MAX_DESC;i=i+1) begin:pulsegen
	 assign rdata_counter_done[i]=rdata_counter_ff_0[i] & {rdata_counter[i][9:1],~rdata_counter[i][0]};
      end
   endgenerate




   ////////////////////////////////////////////////////////////////////
   //
   // If after rdata is fetched and none of the ID is matched
   // send_data_to_dram will remain low, so assert it as an 
   // Error.
   //
   ///////////////////////////////////////////////////////////////////


   always@ (posedge axi_aclk) begin	  
      if(~axi_aresetn) begin
	 rid_not_found_error<=0;
      end
      else if(rdata_read_en_ff2) begin
	 rid_not_found_error<=~send_data_to_dram;
      end
      else begin
	 rid_not_found_error<=0;
      end
      
   end



   
   always@(posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin
	 if(~axi_aresetn) begin
	    rlast_not_asserted_error_check_late[k]<=0;
	    rlast_not_asserted_error_check_early[k]<=0;
	 end
	 else if((rdata_counter[k][0] && ~(|rdata_counter[k][9:1]))) begin
	    rlast_not_asserted_error_check_late[k]<=1;
	    rlast_not_asserted_error_check_early[k]<=0;

	 end
	 else if((~rdata_counter[k][0]) && (|rdata_counter[k][9:1])) begin
	    rlast_not_asserted_error_check_late[k]<=0;
	    rlast_not_asserted_error_check_early[k]<=1;
	 end
	 else begin
	    rlast_not_asserted_error_check_late[k]<=0;
	    rlast_not_asserted_error_check_early[k]<=0;
	 end
      end
   end
   


   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 rlast_not_asserted_error<=0;
      end
      else if(send_data_to_dram && rlast_not_asserted_error_check_late[desc_rdata_id] && ~rdata_read_out_rlast) begin
	 rlast_not_asserted_error<=1;
      end
      else if(send_data_to_dram && rlast_not_asserted_error_check_early[desc_rdata_id] && rdata_read_out_rlast) begin
	 rlast_not_asserted_error<=1;
      end
      else begin
	 rlast_not_asserted_error<=0;
      end
   end
   
   

   
   //////////////////////////////////////////////////////////////////////////////
   //
   // Rresp status update. once "send_data_to_dram" is triggered, and desc_rdata_id
   // is fetched, update reigsters of corresponding desc with ruser, rresp & rdata
   //
   // In case of bad response, the first bad rresp (not okay) will be latched
   // and updated into registers, others will be ignored.
   //
   // The ruser in last beat of the transaction will be written into the register
   //
   //////////////////////////////////////////////////////////////////////////////


   always@ (posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin
	 if(~axi_aresetn) begin
	    read_ruser_we[k]<=0;
	    read_ruser[k]<=0;
	    rresp_completed[k]<=0;
	    rresp_status[(k<<1)]<=0;
	    rresp_status[(k<<1)+1]<=0;
	    rresp_status_we[(k<<1)]<=0;
	    rresp_status_we[(k<<1)+1]<=0;
	    ownership_per_desc_rd[k]<=0;
	 end
	 else if(send_data_to_dram_ff2 && (k==desc_rdata_id) && (rdata_counter[k]==0)) begin
	    //This is the end of transfer ( rdata_counter ==0)
	    //if (rdata_counter[desc_rdata_id]==0) begin
	    //Update ownership
	    if(rdata_read_out_rlast) begin
	       ownership_per_desc_rd[k]<=1;
	    end
	    //update register to indicated that any one of the desc is done
	    rresp_completed[k]<=1;//update_intr_comp_status_reg[desc_read_id]<=1;
	    //Update registers for status
	    rresp_status[(k<<1)]<=rdata_read_out_first_bad_resp[k][0];
	    rresp_status[(k<<1)+1]<=rdata_read_out_first_bad_resp[k][1];
	    rresp_status_we[(k<<1)]<=1;
	    rresp_status_we[(k<<1)+1]<=1;
	    //Send ruser
	    read_ruser[k]<=rdata_read_out_ruser;
	    read_ruser_we[k]<='hFFFFFFFF;			
	 end
	 else begin
	    rresp_completed[k]<=0;
	    ownership_per_desc_rd[k]<=0;
	    rresp_status[(k<<1)]<=0;
	    rresp_status[(k<<1)+1]<=0;
	    rresp_status_we[(k<<1)]<=0;
	    rresp_status_we[(k<<1)+1]<=0;
	    read_ruser[k]<=0;
	    read_ruser_we[k]<=0;
	 end
      end
   end
   

   always@( posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin
	 if(~axi_aresetn) begin
	    rdata_read_out_first_bad_resp[k]<=0;
	    rdata_received_bad_response[k]<=0;
	 end
	 //If read_respnse is non zero store it in respective registers.
	 //If first bad response comes, then store it
	 else if(send_data_to_dram_ff2 && (k==desc_rdata_id)) begin
	    if((rdata_read_out_resp!=0) && ~rdata_received_bad_response_ff[k]) begin
	       rdata_read_out_first_bad_resp[k]<=rdata_read_out_resp;
	       rdata_received_bad_response[k]<=1;
	    end
	    else if(rdata_counter[k]==0) begin
	       rdata_read_out_first_bad_resp[k]<=0;
	       rdata_received_bad_response[k]<=0;
	    end
	    else begin
	       rdata_read_out_first_bad_resp[k]<=rdata_read_out_first_bad_resp[k];
	    end		
	 end
	 else begin
	    rdata_read_out_first_bad_resp[k]<=rdata_read_out_first_bad_resp[k];
	    rdata_received_bad_response[k]<=rdata_received_bad_response[k];
	 end
      end
   end

   always@( posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 rdata_received_bad_response_ff<=0;
      end else begin
	 rdata_received_bad_response_ff<=rdata_received_bad_response;
      end
   end
   
   /////////////////////////////////////////////////////////////////////
   //
   // Update XUSER for both Writes (buser) and Reads (ruser)
   //
   /////////////////////////////////////////////////////////////////////
   
   always@( posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:uc2rb_xuser
	 if(~axi_aresetn) begin
	    int_reg_desc_n_xuser_0_xuser[k]<=0 ;
	    int_reg_desc_n_xuser_0_xuser_we[k]<=0 ;
	    int_reg_desc_n_xuser_1_xuser[k]<=0;
	    int_reg_desc_n_xuser_1_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_2_xuser[k]<=0;
	    int_reg_desc_n_xuser_2_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_3_xuser[k]<=0;
	    int_reg_desc_n_xuser_3_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_4_xuser[k]<=0;
	    int_reg_desc_n_xuser_4_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_5_xuser[k]<=0;
	    int_reg_desc_n_xuser_5_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_6_xuser[k]<=0;
	    int_reg_desc_n_xuser_6_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_7_xuser[k]<=0;
	    int_reg_desc_n_xuser_7_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_8_xuser[k]<=0;
	    int_reg_desc_n_xuser_8_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_9_xuser[k]<=0;
	    int_reg_desc_n_xuser_9_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_10_xuser[k]<=0;
	    int_reg_desc_n_xuser_10_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_11_xuser[k]<=0;
	    int_reg_desc_n_xuser_11_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_12_xuser[k]<=0;
	    int_reg_desc_n_xuser_12_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_13_xuser[k]<=0;
	    int_reg_desc_n_xuser_13_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_14_xuser[k]<=0;
	    int_reg_desc_n_xuser_14_xuser_we[k]<=0;
	    int_reg_desc_n_xuser_15_xuser[k]<=0;
	    int_reg_desc_n_xuser_15_xuser_we[k]<=0;
	 end
	 else begin
	    int_reg_desc_n_xuser_0_xuser[k]<=read_ruser[k] | bresp_buser[k] ;
	    int_reg_desc_n_xuser_0_xuser_we[k]<=read_ruser_we[k] | bresp_buser_we[k];
	 end
      end
   end

   ////////////////////////////////////////////////////////////////////////////
   //
   // DRAM interface, to write rdata into RDATA_RAM.
   // offset counter (For DRAM address ) is maintained per unique ID.
   //
   ////////////////////////////////////////////////////////////////////////////
   

   always@ (posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 uc2rb_wr_data<=0;
	 uc2rb_wr_we  <=0;
	 uc2rb_wr_bwe <=0;
	 uc2rb_wr_addr<=0;
	 uc2rb_wr_desc_id <= 0;
	 arid_read_en_reg_valid<=0;
      end
      else if(send_data_to_dram ) begin
	 //rdata counter will be decremented after this cycle
	 //So, if desc_rdata_is ==x and that counter is =1,
	 //means that is the last data we have got. 
	 if (rdata_read_out_rlast) begin
	    //If this is the last transfer, then 
	    //Pop data from ARID FIFO. This will trigger
	    // Ownership update
	    
	    uc2rb_wr_bwe <= hm_rlast_mem_strobes[desc_rdata_id];
	    arid_read_en_reg_valid<=1;
	    // Assign write enables to only valid data

	    //arid_read_en_reg[fifo_select]<=1;
	 end
	 else begin
	    uc2rb_wr_bwe <= 16'hFFFF;
	 end
	 uc2rb_wr_data<=rdata_read_out_data;
	 uc2rb_wr_we  <=1;
	 uc2rb_wr_addr<=offset_addr[desc_rdata_id];
	 uc2rb_wr_desc_id <= desc_rdata_id;
      end
      else begin
	 uc2rb_wr_we  <=0;
	 uc2rb_wr_bwe <='h0;
	 uc2rb_wr_desc_id <= 0;
	 arid_read_en_reg_valid<=0;
      end
   end


   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 fifo_select_ff<=0;
      end
      else begin
	 fifo_select_ff<=fifo_select;
      end
   end

   
   always@ (posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 arid_read_en_reg<=0;
      end
      else if(arid_read_en_reg_valid) begin
	 arid_read_en_reg[fifo_select_ff]<=1;
      end
      else begin
	 arid_read_en_reg<=0;
      end
   end

   ///////////////////////////////////////////////////////////////////////////
   //
   // Offset counter Per descriptor. 
   // For any new request,
   //	wait for rd_request on AXI, once any request is initiated
   // 	assign corresponding offset_address to offser_addr register and make 
   // 	rdata_couter = arlen+1. 
   //
   // For any existing request,
   //	Increment offset counter and decrement rdata_counter
   //
   ////////////////////////////////////////////////////////////////////////////


   
   assign increment_rdata_offset_addr = (RTL_USE_MODE==1) ? ((UC_AXI_DATA_WIDTH==128)?1: ((UC_AXI_DATA_WIDTH==64) ? 2:4)) : 1;

   
   always@(posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:offset_count
	 if(~axi_aresetn) begin
	    offset_addr[k]<=0;
	    rdata_counter[k]<=0;
	 end
	 //If desc_rd_req_id comes on bus initialize the counter & Offset
	 else if((desc_rd_req_id ==k) && (desc_rd_req_read_en_ff6)) begin
	    offset_addr[k]<=int_wire_desc_n_data_offset_addr[k]>>((UC_AXI_DATA_WIDTH==128)?4: ((UC_AXI_DATA_WIDTH==64) ? 3:2));
	    rdata_counter[k]<= m_axi_usr_arlen+1;
	 end
	 else if(send_data_to_dram_ff && (desc_rdata_id==k)) begin
	    // AS an HM, it sees DUT DRAM, so addresses needs to be incremented accordingly
	    offset_addr[k]<=offset_addr[k]+ increment_rdata_offset_addr ;
	    rdata_counter[k]<=rdata_counter[k]-1;
	 end
	 else begin
	    offset_addr[k]<=offset_addr[k];
	 end
      end
   end
   

endmodule // axi_master_control




/* axi_master_control.v ends here */
