/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Meera Bagdai. 
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
 *   Wrapper module for ACE slave bridge.
 *
 *
 */
`include "ace_defines_common.vh"
module ace_host_master_slv #(
                              parameter ACE_PROTOCOL                   = "FULLACE" 
                              
                              ,parameter S_AXI_ADDR_WIDTH               = 64 
                              ,parameter S_AXI_DATA_WIDTH               = 32 
                              
                              ,parameter M_AXI_ADDR_WIDTH               = 64 
                              ,parameter M_AXI_DATA_WIDTH               = 128
                              ,parameter M_AXI_ID_WIDTH                 = 16 
                              ,parameter M_AXI_USER_WIDTH               = 32 
                              
                              ,parameter S_ACE_USR_ADDR_WIDTH           = 64 
                              ,parameter S_ACE_USR_XX_DATA_WIDTH        = 128       
                              ,parameter S_ACE_USR_SN_DATA_WIDTH        = 128       
                              ,parameter S_ACE_USR_ID_WIDTH             = 16 
                              ,parameter S_ACE_USR_AWUSER_WIDTH         = 32 
                              ,parameter S_ACE_USR_WUSER_WIDTH          = 32 
                              ,parameter S_ACE_USR_BUSER_WIDTH          = 32 
                              ,parameter S_ACE_USR_ARUSER_WIDTH         = 32 
                              ,parameter S_ACE_USR_RUSER_WIDTH          = 32 
                              
                              ,parameter CACHE_LINE_SIZE                = 64 
                              ,parameter XX_MAX_DESC                    = 16        
                              ,parameter SN_MAX_DESC                    = 16        
                              ,parameter XX_RAM_SIZE                    = 16384     
                              ,parameter SN_RAM_SIZE                    = 512       
                              ,parameter USR_RST_NUM                    = 4     
                              ,parameter LAST_BRIDGE                    = 0
                              ,parameter EXTEND_WSTRB                   = 1
                              
                              )(
				
				//Clock and reset
				input clk 
				,input resetn 
   
				// M_AXI - AXI4
				,output wire [M_AXI_ID_WIDTH-1 : 0] m_axi_awid
				,output wire [M_AXI_ADDR_WIDTH-1 : 0] m_axi_awaddr
				,output wire [7 : 0] m_axi_awlen
				,output wire [2 : 0] m_axi_awsize
				,output wire [1 : 0] m_axi_awburst
				,output wire m_axi_awlock
				,output wire [3 : 0] m_axi_awcache
				,output wire [2 : 0] m_axi_awprot
				,output wire [3 : 0] m_axi_awqos
				,output wire [3:0] m_axi_awregion 
				,output wire [M_AXI_USER_WIDTH-1 : 0] m_axi_awuser
				,output wire m_axi_awvalid
				,input wire m_axi_awready
				,output wire [M_AXI_DATA_WIDTH-1 : 0] m_axi_wdata
				,output wire [M_AXI_DATA_WIDTH/8-1 : 0] m_axi_wstrb
				,output wire m_axi_wlast
				,output wire [M_AXI_USER_WIDTH-1 : 0] m_axi_wuser
				,output wire m_axi_wvalid
				,input wire m_axi_wready
				,input wire [M_AXI_ID_WIDTH-1 : 0] m_axi_bid
				,input wire [1 : 0] m_axi_bresp
				,input wire [M_AXI_USER_WIDTH-1 : 0] m_axi_buser
				,input wire m_axi_bvalid
				,output wire m_axi_bready
				,output wire [M_AXI_ID_WIDTH-1 : 0] m_axi_arid
				,output wire [M_AXI_ADDR_WIDTH-1 : 0] m_axi_araddr
				,output wire [7 : 0] m_axi_arlen
				,output wire [2 : 0] m_axi_arsize
				,output wire [1 : 0] m_axi_arburst
				,output wire m_axi_arlock
				,output wire [3 : 0] m_axi_arcache
				,output wire [2 : 0] m_axi_arprot
				,output wire [3 : 0] m_axi_arqos
				,output wire [3:0] m_axi_arregion 
				,output wire [M_AXI_USER_WIDTH-1 : 0] m_axi_aruser
				,output wire m_axi_arvalid
				,input wire m_axi_arready
				,input wire [M_AXI_ID_WIDTH-1 : 0] m_axi_rid
				,input wire [M_AXI_DATA_WIDTH-1 : 0] m_axi_rdata
				,input wire [1 : 0] m_axi_rresp
				,input wire m_axi_rlast
				,input wire [M_AXI_USER_WIDTH-1 : 0] m_axi_ruser
				,input wire m_axi_rvalid
				,output wire m_axi_rready
   
				,input [31:0] version_reg
				,input [31:0] bridge_type_reg
   
				,input [XX_MAX_DESC-1:0] rd_uc2hm_trig //For s_ace_usr read channel
				,output [XX_MAX_DESC-1:0] rd_hm2uc_done //For s_ace_usr read channel
				,input [XX_MAX_DESC-1:0] wr_uc2hm_trig //For s_ace_usr write channel
				,output [XX_MAX_DESC-1:0] wr_hm2uc_done //For s_ace_usr write channel
   
				// Mode 1 Signals
				// Read port of WR DataRam
				,output [(`CLOG2(XX_RAM_SIZE/(S_ACE_USR_XX_DATA_WIDTH/8)))-1:0] hm2rb_rd_addr 
				,input [S_ACE_USR_XX_DATA_WIDTH-1:0] rb2hm_rd_data 
				,input [((S_ACE_USR_XX_DATA_WIDTH/8) -1):0] rb2hm_rd_wstrb
				// Write port of RD DataRam
				,output hm2rb_wr_we 
				,output [(S_ACE_USR_XX_DATA_WIDTH/8 -1):0] hm2rb_wr_bwe 
				,output [(`CLOG2(XX_RAM_SIZE/(S_ACE_USR_XX_DATA_WIDTH/8)))-1:0] hm2rb_wr_addr 
				,output [S_ACE_USR_XX_DATA_WIDTH-1:0] hm2rb_wr_data
   
   
				// Regs in from rb to hm
				,input [31:0] intr_error_status_reg
				,input [31:0] intr_error_clear_reg
   
				,output [31:0] hm2rb_intr_error_status_reg 
				,output [31:0] hm2rb_intr_error_status_reg_we 
   
    				,input [31:0] rd_resp_desc_0_data_size_reg 
    				,input [31:0] rd_resp_desc_0_data_offset_reg 
    				,input [31:0] rd_resp_desc_0_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_0_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_0_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_0_data_host_addr_3_reg 
   
    				,input [31:0] rd_resp_desc_1_data_size_reg 
    				,input [31:0] rd_resp_desc_1_data_offset_reg 
    				,input [31:0] rd_resp_desc_1_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_1_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_1_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_1_data_host_addr_3_reg 
   
   
    				,input [31:0] rd_resp_desc_2_data_size_reg 
    				,input [31:0] rd_resp_desc_2_data_offset_reg 
    				,input [31:0] rd_resp_desc_2_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_2_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_2_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_2_data_host_addr_3_reg 
   
   
    				,input [31:0] rd_resp_desc_3_data_size_reg 
    				,input [31:0] rd_resp_desc_3_data_offset_reg 
    				,input [31:0] rd_resp_desc_3_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_3_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_3_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_3_data_host_addr_3_reg 
   
   
    				,input [31:0] rd_resp_desc_4_data_size_reg 
    				,input [31:0] rd_resp_desc_4_data_offset_reg 
    				,input [31:0] rd_resp_desc_4_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_4_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_4_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_4_data_host_addr_3_reg 
   
   
    				,input [31:0] rd_resp_desc_5_data_size_reg 
    				,input [31:0] rd_resp_desc_5_data_offset_reg 
    				,input [31:0] rd_resp_desc_5_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_5_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_5_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_5_data_host_addr_3_reg 
   
   
    				,input [31:0] rd_resp_desc_6_data_size_reg 
    				,input [31:0] rd_resp_desc_6_data_offset_reg 
    				,input [31:0] rd_resp_desc_6_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_6_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_6_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_6_data_host_addr_3_reg 
   
   
    				,input [31:0] rd_resp_desc_7_data_size_reg 
    				,input [31:0] rd_resp_desc_7_data_offset_reg 
    				,input [31:0] rd_resp_desc_7_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_7_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_7_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_7_data_host_addr_3_reg 
   
   
    				,input [31:0] rd_resp_desc_8_data_size_reg 
    				,input [31:0] rd_resp_desc_8_data_offset_reg 
    				,input [31:0] rd_resp_desc_8_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_8_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_8_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_8_data_host_addr_3_reg 
   
    				,input [31:0] rd_resp_desc_9_data_size_reg 
    				,input [31:0] rd_resp_desc_9_data_offset_reg 
    				,input [31:0] rd_resp_desc_9_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_9_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_9_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_9_data_host_addr_3_reg 
   
    				,input [31:0] rd_resp_desc_a_data_size_reg 
    				,input [31:0] rd_resp_desc_a_data_offset_reg 
    				,input [31:0] rd_resp_desc_a_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_a_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_a_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_a_data_host_addr_3_reg 
   
   
   
    				,input [31:0] rd_resp_desc_b_data_size_reg 
    				,input [31:0] rd_resp_desc_b_data_offset_reg 
    				,input [31:0] rd_resp_desc_b_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_b_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_b_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_b_data_host_addr_3_reg 
   
    				,input [31:0] rd_resp_desc_c_data_size_reg 
    				,input [31:0] rd_resp_desc_c_data_offset_reg 
    				,input [31:0] rd_resp_desc_c_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_c_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_c_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_c_data_host_addr_3_reg 
   
   
    				,input [31:0] rd_resp_desc_d_data_size_reg 
    				,input [31:0] rd_resp_desc_d_data_offset_reg 
    				,input [31:0] rd_resp_desc_d_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_d_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_d_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_d_data_host_addr_3_reg 
   
   
    				,input [31:0] rd_resp_desc_e_data_size_reg 
    				,input [31:0] rd_resp_desc_e_data_offset_reg 
    				,input [31:0] rd_resp_desc_e_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_e_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_e_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_e_data_host_addr_3_reg 
   
   
    				,input [31:0] rd_resp_desc_f_data_size_reg 
    				,input [31:0] rd_resp_desc_f_data_offset_reg 
    				,input [31:0] rd_resp_desc_f_data_host_addr_0_reg 
    				,input [31:0] rd_resp_desc_f_data_host_addr_1_reg 
    				,input [31:0] rd_resp_desc_f_data_host_addr_2_reg 
    				,input [31:0] rd_resp_desc_f_data_host_addr_3_reg 
   
   
				,input [31:0] wr_req_desc_0_txn_type_reg 
    				,input [31:0] wr_req_desc_0_size_reg 
    				,input [31:0] wr_req_desc_0_data_offset_reg 
    				,input [31:0] wr_req_desc_0_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_0_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_0_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_0_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_0_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_0_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_0_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_0_wstrb_host_addr_3_reg 
   
    				,input [31:0] wr_req_desc_1_txn_type_reg 
    				,input [31:0] wr_req_desc_1_size_reg 
    				,input [31:0] wr_req_desc_1_data_offset_reg 
    				,input [31:0] wr_req_desc_1_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_1_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_1_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_1_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_1_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_1_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_1_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_1_wstrb_host_addr_3_reg 
   
   
    				,input [31:0] wr_req_desc_2_txn_type_reg 
    				,input [31:0] wr_req_desc_2_size_reg 
    				,input [31:0] wr_req_desc_2_data_offset_reg 
    				,input [31:0] wr_req_desc_2_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_2_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_2_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_2_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_2_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_2_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_2_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_2_wstrb_host_addr_3_reg 
   
   
    				,input [31:0] wr_req_desc_3_txn_type_reg 
    				,input [31:0] wr_req_desc_3_size_reg 
    				,input [31:0] wr_req_desc_3_data_offset_reg 
    				,input [31:0] wr_req_desc_3_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_3_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_3_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_3_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_3_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_3_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_3_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_3_wstrb_host_addr_3_reg 
   
   
    				,input [31:0] wr_req_desc_4_txn_type_reg 
    				,input [31:0] wr_req_desc_4_size_reg 
    				,input [31:0] wr_req_desc_4_data_offset_reg 
    				,input [31:0] wr_req_desc_4_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_4_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_4_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_4_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_4_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_4_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_4_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_4_wstrb_host_addr_3_reg 
   
   
    				,input [31:0] wr_req_desc_5_txn_type_reg 
    				,input [31:0] wr_req_desc_5_size_reg 
    				,input [31:0] wr_req_desc_5_data_offset_reg 
    				,input [31:0] wr_req_desc_5_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_5_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_5_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_5_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_5_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_5_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_5_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_5_wstrb_host_addr_3_reg 
   
   
    				,input [31:0] wr_req_desc_6_txn_type_reg 
    				,input [31:0] wr_req_desc_6_size_reg 
    				,input [31:0] wr_req_desc_6_data_offset_reg 
    				,input [31:0] wr_req_desc_6_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_6_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_6_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_6_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_6_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_6_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_6_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_6_wstrb_host_addr_3_reg 
   
   
    				,input [31:0] wr_req_desc_7_txn_type_reg 
    				,input [31:0] wr_req_desc_7_size_reg 
    				,input [31:0] wr_req_desc_7_data_offset_reg 
    				,input [31:0] wr_req_desc_7_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_7_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_7_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_7_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_7_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_7_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_7_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_7_wstrb_host_addr_3_reg 
   
   
    				,input [31:0] wr_req_desc_8_txn_type_reg 
    				,input [31:0] wr_req_desc_8_size_reg 
    				,input [31:0] wr_req_desc_8_data_offset_reg 
    				,input [31:0] wr_req_desc_8_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_8_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_8_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_8_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_8_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_8_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_8_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_8_wstrb_host_addr_3_reg 
   
    				,input [31:0] wr_req_desc_9_txn_type_reg 
    				,input [31:0] wr_req_desc_9_size_reg 
    				,input [31:0] wr_req_desc_9_data_offset_reg 
    				,input [31:0] wr_req_desc_9_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_9_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_9_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_9_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_9_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_9_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_9_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_9_wstrb_host_addr_3_reg 
   
    				,input [31:0] wr_req_desc_a_txn_type_reg 
    				,input [31:0] wr_req_desc_a_size_reg 
    				,input [31:0] wr_req_desc_a_data_offset_reg 
    				,input [31:0] wr_req_desc_a_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_a_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_a_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_a_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_a_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_a_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_a_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_a_wstrb_host_addr_3_reg 
   
   
   
    				,input [31:0] wr_req_desc_b_txn_type_reg 
    				,input [31:0] wr_req_desc_b_size_reg 
    				,input [31:0] wr_req_desc_b_data_offset_reg 
    				,input [31:0] wr_req_desc_b_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_b_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_b_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_b_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_b_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_b_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_b_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_b_wstrb_host_addr_3_reg 
   
    				,input [31:0] wr_req_desc_c_txn_type_reg 
    				,input [31:0] wr_req_desc_c_size_reg 
    				,input [31:0] wr_req_desc_c_data_offset_reg 
    				,input [31:0] wr_req_desc_c_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_c_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_c_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_c_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_c_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_c_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_c_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_c_wstrb_host_addr_3_reg 
   
   
    				,input [31:0] wr_req_desc_d_txn_type_reg 
    				,input [31:0] wr_req_desc_d_size_reg 
    				,input [31:0] wr_req_desc_d_data_offset_reg 
    				,input [31:0] wr_req_desc_d_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_d_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_d_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_d_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_d_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_d_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_d_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_d_wstrb_host_addr_3_reg 
   
   
    				,input [31:0] wr_req_desc_e_txn_type_reg 
    				,input [31:0] wr_req_desc_e_size_reg 
    				,input [31:0] wr_req_desc_e_data_offset_reg 
    				,input [31:0] wr_req_desc_e_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_e_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_e_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_e_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_e_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_e_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_e_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_e_wstrb_host_addr_3_reg 
   
   
    				,input [31:0] wr_req_desc_f_txn_type_reg 
    				,input [31:0] wr_req_desc_f_size_reg 
    				,input [31:0] wr_req_desc_f_data_offset_reg 
    				,input [31:0] wr_req_desc_f_data_host_addr_0_reg 
    				,input [31:0] wr_req_desc_f_data_host_addr_1_reg 
    				,input [31:0] wr_req_desc_f_data_host_addr_2_reg 
    				,input [31:0] wr_req_desc_f_data_host_addr_3_reg 
    				,input [31:0] wr_req_desc_f_wstrb_host_addr_0_reg 
    				,input [31:0] wr_req_desc_f_wstrb_host_addr_1_reg 
    				,input [31:0] wr_req_desc_f_wstrb_host_addr_2_reg 
    				,input [31:0] wr_req_desc_f_wstrb_host_addr_3_reg 


   

				);


   localparam XX_DESC_IDX_WIDTH                                               = `CLOG2(XX_MAX_DESC);
   localparam XX_RAM_OFFSET_WIDTH                                             = `CLOG2((XX_RAM_SIZE*8)/S_ACE_USR_XX_DATA_WIDTH);

   wire [31:0] 			      rd_hm2rb_intr_error_status_reg;
   wire [31:0] 			      rd_hm2rb_intr_error_status_reg_we;

   wire [31:0] 			      wr_hm2rb_intr_error_status_reg;
   wire [31:0] 			      wr_hm2rb_intr_error_status_reg_we;

   assign hm2rb_intr_error_status_reg = (rd_hm2rb_intr_error_status_reg | wr_hm2rb_intr_error_status_reg);
   assign hm2rb_intr_error_status_reg_we = (rd_hm2rb_intr_error_status_reg_we | wr_hm2rb_intr_error_status_reg_we);


   host_master_s #(
                   .M_AXI_ADDR_WIDTH       (M_AXI_ADDR_WIDTH     ),  
                   .M_AXI_DATA_WIDTH       (M_AXI_DATA_WIDTH     ),  
                   .M_AXI_ID_WIDTH         (M_AXI_ID_WIDTH       ),  
                   .M_AXI_USER_WIDTH       (M_AXI_USER_WIDTH     ),  
                   .RAM_SIZE               (XX_RAM_SIZE             ),  
                   .S_AXI_USR_DATA_WIDTH   (S_ACE_USR_XX_DATA_WIDTH ),  
                   .MAX_DESC               (XX_MAX_DESC             )  

		   )

   read_host_master_s
     (
      .axi_aclk                (clk),
      .axi_aresetn     (resetn),
      // Outputs
      .hm2uc_done           (rd_hm2uc_done),
      .hm2rb_rd_addr        (),
      .hm2rb_wr_we          (hm2rb_wr_we),
      .hm2rb_wr_bwe         (hm2rb_wr_bwe),
      .hm2rb_wr_addr        (hm2rb_wr_addr),
      .hm2rb_wr_data_in     (hm2rb_wr_data),
      .hm2rb_wr_wstrb_in    (), //NC
      .hm2rb_intr_error_status_reg_we(rd_hm2rb_intr_error_status_reg_we),
      .hm2rb_intr_error_status_reg(rd_hm2rb_intr_error_status_reg),
      .rb2hm_intr_error_status_reg({31'h0,intr_error_status_reg[1]}),
      .rb2hm_intr_error_clear_reg({31'h0,intr_error_clear_reg[1]}),

      // From RB-to HM
      
      .desc_0_txn_type_reg(32'b1),
      .desc_0_size_reg(rd_resp_desc_0_data_size_reg),
      .desc_0_data_offset_reg(rd_resp_desc_0_data_offset_reg),
      .desc_0_data_host_addr_0_reg(rd_resp_desc_0_data_host_addr_0_reg),
      .desc_0_data_host_addr_1_reg(rd_resp_desc_0_data_host_addr_1_reg),
      .desc_0_data_host_addr_2_reg(rd_resp_desc_0_data_host_addr_2_reg),
      .desc_0_data_host_addr_3_reg(rd_resp_desc_0_data_host_addr_3_reg),
      .desc_0_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_0_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_0_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_0_wstrb_host_addr_3_reg({32{1'b0}}),
      
      .desc_1_txn_type_reg(32'b1),
      .desc_1_size_reg(rd_resp_desc_1_data_size_reg),
      .desc_1_data_offset_reg(rd_resp_desc_1_data_offset_reg),
      .desc_1_data_host_addr_0_reg(rd_resp_desc_1_data_host_addr_0_reg),
      .desc_1_data_host_addr_1_reg(rd_resp_desc_1_data_host_addr_1_reg),
      .desc_1_data_host_addr_2_reg(rd_resp_desc_1_data_host_addr_2_reg),
      .desc_1_data_host_addr_3_reg(rd_resp_desc_1_data_host_addr_3_reg),
      .desc_1_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_1_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_1_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_1_wstrb_host_addr_3_reg({32{1'b0}}),
      
      .desc_2_txn_type_reg(32'b1),
      .desc_2_size_reg(rd_resp_desc_2_data_size_reg),
      .desc_2_data_offset_reg(rd_resp_desc_2_data_offset_reg),
      .desc_2_data_host_addr_0_reg(rd_resp_desc_2_data_host_addr_0_reg),
      .desc_2_data_host_addr_1_reg(rd_resp_desc_2_data_host_addr_1_reg),
      .desc_2_data_host_addr_2_reg(rd_resp_desc_2_data_host_addr_2_reg),
      .desc_2_data_host_addr_3_reg(rd_resp_desc_2_data_host_addr_3_reg),
      .desc_2_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_2_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_2_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_2_wstrb_host_addr_3_reg({32{1'b0}}),
      
      .desc_3_txn_type_reg(32'b1),
      .desc_3_size_reg(rd_resp_desc_3_data_size_reg),
      .desc_3_data_offset_reg(rd_resp_desc_3_data_offset_reg),
      .desc_3_data_host_addr_0_reg(rd_resp_desc_3_data_host_addr_0_reg),
      .desc_3_data_host_addr_1_reg(rd_resp_desc_3_data_host_addr_1_reg),
      .desc_3_data_host_addr_2_reg(rd_resp_desc_3_data_host_addr_2_reg),
      .desc_3_data_host_addr_3_reg(rd_resp_desc_3_data_host_addr_3_reg),
      .desc_3_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_3_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_3_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_3_wstrb_host_addr_3_reg({32{1'b0}}),
      
      .desc_4_txn_type_reg(32'b1),
      .desc_4_size_reg(rd_resp_desc_4_data_size_reg),
      .desc_4_data_offset_reg(rd_resp_desc_4_data_offset_reg),
      .desc_4_data_host_addr_0_reg(rd_resp_desc_4_data_host_addr_0_reg),
      .desc_4_data_host_addr_1_reg(rd_resp_desc_4_data_host_addr_1_reg),
      .desc_4_data_host_addr_2_reg(rd_resp_desc_4_data_host_addr_2_reg),
      .desc_4_data_host_addr_3_reg(rd_resp_desc_4_data_host_addr_3_reg),
      .desc_4_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_4_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_4_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_4_wstrb_host_addr_3_reg({32{1'b0}}),
      
      .desc_5_txn_type_reg(32'b1),
      .desc_5_size_reg(rd_resp_desc_5_data_size_reg),
      .desc_5_data_offset_reg(rd_resp_desc_5_data_offset_reg),
      .desc_5_data_host_addr_0_reg(rd_resp_desc_5_data_host_addr_0_reg),
      .desc_5_data_host_addr_1_reg(rd_resp_desc_5_data_host_addr_1_reg),
      .desc_5_data_host_addr_2_reg(rd_resp_desc_5_data_host_addr_2_reg),
      .desc_5_data_host_addr_3_reg(rd_resp_desc_5_data_host_addr_3_reg),
      .desc_5_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_5_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_5_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_5_wstrb_host_addr_3_reg({32{1'b0}}),
      
      
      .desc_6_txn_type_reg(32'b1),
      .desc_6_size_reg(rd_resp_desc_6_data_size_reg),
      .desc_6_data_offset_reg(rd_resp_desc_6_data_offset_reg),
      .desc_6_data_host_addr_0_reg(rd_resp_desc_6_data_host_addr_0_reg),
      .desc_6_data_host_addr_1_reg(rd_resp_desc_6_data_host_addr_1_reg),
      .desc_6_data_host_addr_2_reg(rd_resp_desc_6_data_host_addr_2_reg),
      .desc_6_data_host_addr_3_reg(rd_resp_desc_6_data_host_addr_3_reg),
      .desc_6_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_6_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_6_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_6_wstrb_host_addr_3_reg({32{1'b0}}),
      
      
      .desc_7_txn_type_reg(32'b1),
      .desc_7_size_reg(rd_resp_desc_7_data_size_reg),
      .desc_7_data_offset_reg(rd_resp_desc_7_data_offset_reg),
      .desc_7_data_host_addr_0_reg(rd_resp_desc_7_data_host_addr_0_reg),
      .desc_7_data_host_addr_1_reg(rd_resp_desc_7_data_host_addr_1_reg),
      .desc_7_data_host_addr_2_reg(rd_resp_desc_7_data_host_addr_2_reg),
      .desc_7_data_host_addr_3_reg(rd_resp_desc_7_data_host_addr_3_reg),
      .desc_7_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_7_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_7_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_7_wstrb_host_addr_3_reg({32{1'b0}}),
      
      .desc_8_txn_type_reg(32'b1),
      .desc_8_size_reg(rd_resp_desc_8_data_size_reg),
      .desc_8_data_offset_reg(rd_resp_desc_8_data_offset_reg),
      .desc_8_data_host_addr_0_reg(rd_resp_desc_8_data_host_addr_0_reg),
      .desc_8_data_host_addr_1_reg(rd_resp_desc_8_data_host_addr_1_reg),
      .desc_8_data_host_addr_2_reg(rd_resp_desc_8_data_host_addr_2_reg),
      .desc_8_data_host_addr_3_reg(rd_resp_desc_8_data_host_addr_3_reg),
      .desc_8_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_8_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_8_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_8_wstrb_host_addr_3_reg({32{1'b0}}),
      
      .desc_9_txn_type_reg(32'b1),
      .desc_9_size_reg(rd_resp_desc_9_data_size_reg),
      .desc_9_data_offset_reg(rd_resp_desc_9_data_offset_reg),
      .desc_9_data_host_addr_0_reg(rd_resp_desc_9_data_host_addr_0_reg),
      .desc_9_data_host_addr_1_reg(rd_resp_desc_9_data_host_addr_1_reg),
      .desc_9_data_host_addr_2_reg(rd_resp_desc_9_data_host_addr_2_reg),
      .desc_9_data_host_addr_3_reg(rd_resp_desc_9_data_host_addr_3_reg),
      .desc_9_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_9_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_9_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_9_wstrb_host_addr_3_reg({32{1'b0}}),
      
      .desc_10_txn_type_reg(32'b1),
      .desc_10_size_reg(rd_resp_desc_a_data_size_reg),
      .desc_10_data_offset_reg(rd_resp_desc_a_data_offset_reg),
      .desc_10_data_host_addr_0_reg(rd_resp_desc_a_data_host_addr_0_reg),
      .desc_10_data_host_addr_1_reg(rd_resp_desc_a_data_host_addr_1_reg),
      .desc_10_data_host_addr_2_reg(rd_resp_desc_a_data_host_addr_2_reg),
      .desc_10_data_host_addr_3_reg(rd_resp_desc_a_data_host_addr_3_reg),
      .desc_10_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_10_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_10_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_10_wstrb_host_addr_3_reg({32{1'b0}}),
      
      .desc_11_txn_type_reg(32'b1),
      .desc_11_size_reg(rd_resp_desc_b_data_size_reg),
      .desc_11_data_offset_reg(rd_resp_desc_b_data_offset_reg),
      .desc_11_data_host_addr_0_reg(rd_resp_desc_b_data_host_addr_0_reg),
      .desc_11_data_host_addr_1_reg(rd_resp_desc_b_data_host_addr_1_reg),
      .desc_11_data_host_addr_2_reg(rd_resp_desc_b_data_host_addr_2_reg),
      .desc_11_data_host_addr_3_reg(rd_resp_desc_b_data_host_addr_3_reg),
      .desc_11_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_11_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_11_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_11_wstrb_host_addr_3_reg({32{1'b0}}),
      
      
      .desc_12_txn_type_reg(32'b1),
      .desc_12_size_reg(rd_resp_desc_c_data_size_reg),
      .desc_12_data_offset_reg(rd_resp_desc_c_data_offset_reg),
      .desc_12_data_host_addr_0_reg(rd_resp_desc_c_data_host_addr_0_reg),
      .desc_12_data_host_addr_1_reg(rd_resp_desc_c_data_host_addr_1_reg),
      .desc_12_data_host_addr_2_reg(rd_resp_desc_c_data_host_addr_2_reg),
      .desc_12_data_host_addr_3_reg(rd_resp_desc_c_data_host_addr_3_reg),
      .desc_12_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_12_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_12_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_12_wstrb_host_addr_3_reg({32{1'b0}}),
      
      
      .desc_13_txn_type_reg(32'b1),
      .desc_13_size_reg(rd_resp_desc_d_data_size_reg),
      .desc_13_data_offset_reg(rd_resp_desc_d_data_offset_reg),
      .desc_13_data_host_addr_0_reg(rd_resp_desc_d_data_host_addr_0_reg),
      .desc_13_data_host_addr_1_reg(rd_resp_desc_d_data_host_addr_1_reg),
      .desc_13_data_host_addr_2_reg(rd_resp_desc_d_data_host_addr_2_reg),
      .desc_13_data_host_addr_3_reg(rd_resp_desc_d_data_host_addr_3_reg),
      .desc_13_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_13_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_13_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_13_wstrb_host_addr_3_reg({32{1'b0}}),
      
      .desc_14_txn_type_reg(32'b1),
      .desc_14_size_reg(rd_resp_desc_e_data_size_reg),
      .desc_14_data_offset_reg(rd_resp_desc_e_data_offset_reg),
      .desc_14_data_host_addr_0_reg(rd_resp_desc_e_data_host_addr_0_reg),
      .desc_14_data_host_addr_1_reg(rd_resp_desc_e_data_host_addr_1_reg),
      .desc_14_data_host_addr_2_reg(rd_resp_desc_e_data_host_addr_2_reg),
      .desc_14_data_host_addr_3_reg(rd_resp_desc_e_data_host_addr_3_reg),
      .desc_14_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_14_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_14_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_14_wstrb_host_addr_3_reg({32{1'b0}}),
      
      
      .desc_15_txn_type_reg(32'b1),
      .desc_15_size_reg(rd_resp_desc_f_data_size_reg),
      .desc_15_data_offset_reg(rd_resp_desc_f_data_offset_reg),
      .desc_15_data_host_addr_0_reg(rd_resp_desc_f_data_host_addr_0_reg),
      .desc_15_data_host_addr_1_reg(rd_resp_desc_f_data_host_addr_1_reg),
      .desc_15_data_host_addr_2_reg(rd_resp_desc_f_data_host_addr_2_reg),
      .desc_15_data_host_addr_3_reg(rd_resp_desc_f_data_host_addr_3_reg),
      .desc_15_wstrb_host_addr_0_reg({32{1'b0}}),
      .desc_15_wstrb_host_addr_1_reg({32{1'b0}}),
      .desc_15_wstrb_host_addr_2_reg({32{1'b0}}),
      .desc_15_wstrb_host_addr_3_reg({32{1'b0}}),


      // M-AXI 
      .m_axi_awid       (), 
      .m_axi_awaddr     (), 
      .m_axi_awlen      (), 
      .m_axi_awsize     (), 
      .m_axi_awburst    (), 
      .m_axi_awlock     (), 
      .m_axi_awcache    (), 
      .m_axi_awprot     (), 
      .m_axi_awqos      (), 
      .m_axi_awregion   (), 
      .m_axi_awuser     (), 
      .m_axi_awvalid    (), 
      .m_axi_awready    (1'b0), 
      .m_axi_wdata      (), 
      .m_axi_wstrb      (), 
      .m_axi_wlast      (), 
      .m_axi_wuser      (), 
      .m_axi_wvalid     (), 
      .m_axi_wready     (1'b0), 
      .m_axi_bid        ({M_AXI_ID_WIDTH{1'b0}}), 
      .m_axi_bresp      (2'b0), 
      .m_axi_buser      ({M_AXI_USER_WIDTH{1'b0}}), 
      .m_axi_bvalid     (1'b0), 
      .m_axi_bready     (), 
      .m_axi_arid       (m_axi_arid    ), 
      .m_axi_araddr     (m_axi_araddr  ), 
      .m_axi_arlen      (m_axi_arlen   ), 
      .m_axi_arsize     (m_axi_arsize  ), 
      .m_axi_arburst    (m_axi_arburst ), 
      .m_axi_arlock     (m_axi_arlock  ), 
      .m_axi_arcache    (m_axi_arcache ), 
      .m_axi_arprot     (m_axi_arprot  ), 
      .m_axi_arqos      (m_axi_arqos   ), 
      .m_axi_arregion   (m_axi_arregion), 
      .m_axi_aruser     (m_axi_aruser  ), 
      .m_axi_arvalid    (m_axi_arvalid ), 
      .m_axi_arready    (m_axi_arready ), 
      .m_axi_rid        (m_axi_rid     ), 
      .m_axi_rdata      (m_axi_rdata   ), 
      .m_axi_rresp      (m_axi_rresp   ), 
      .m_axi_rlast      (m_axi_rlast   ), 
      .m_axi_ruser      (m_axi_ruser   ), 
      .m_axi_rvalid     (m_axi_rvalid  ), 
      .m_axi_rready     (m_axi_rready  ), 


      // Inputs
      .version_reg          (version_reg),
      .bridge_type_reg      (bridge_type_reg),
      .axi_max_desc_reg     ({ {(32-XX_DESC_IDX_WIDTH){1'b0}}, XX_MAX_DESC[XX_DESC_IDX_WIDTH-1:0] } ),
      
      .uc2hm_trig           (rd_uc2hm_trig),
      .rb2hm_rd_dout        ({S_ACE_USR_XX_DATA_WIDTH{1'b0}}),
      .rb2hm_rd_wstrb       ({(S_ACE_USR_XX_DATA_WIDTH/8){1'b0}})
      );


   host_master_s #(
                   .M_AXI_ADDR_WIDTH       (M_AXI_ADDR_WIDTH     ),  
                   .M_AXI_DATA_WIDTH       (M_AXI_DATA_WIDTH     ),  
                   .M_AXI_ID_WIDTH         (M_AXI_ID_WIDTH       ),  
                   .M_AXI_USER_WIDTH       (M_AXI_USER_WIDTH     ),  
                   .RAM_SIZE               (XX_RAM_SIZE             ),  
                   .S_AXI_USR_DATA_WIDTH   (S_ACE_USR_XX_DATA_WIDTH ),  
                   .MAX_DESC               (XX_MAX_DESC             )  

		   )

   write_host_master_s
     (
      .axi_aclk                (clk),
      .axi_aresetn     (resetn),
      // Outputs
      .hm2uc_done           (wr_hm2uc_done),
      .hm2rb_rd_addr        (hm2rb_rd_addr),
      .hm2rb_wr_we          (),
      .hm2rb_wr_bwe         (),
      .hm2rb_wr_addr        (),
      .hm2rb_wr_data_in     (),
      .hm2rb_wr_wstrb_in    (), //NC
      .hm2rb_intr_error_status_reg_we(wr_hm2rb_intr_error_status_reg_we),
      .hm2rb_intr_error_status_reg(wr_hm2rb_intr_error_status_reg),
      .rb2hm_intr_error_status_reg({31'h0,intr_error_status_reg[1]}),
      .rb2hm_intr_error_clear_reg({31'h0,intr_error_clear_reg[1]}),

      // From RB-to HM
      
      .desc_0_txn_type_reg(wr_req_desc_0_txn_type_reg),
      .desc_0_size_reg(wr_req_desc_0_size_reg),
      .desc_0_data_offset_reg(wr_req_desc_0_data_offset_reg),
      .desc_0_data_host_addr_0_reg(wr_req_desc_0_data_host_addr_0_reg),
      .desc_0_data_host_addr_1_reg(wr_req_desc_0_data_host_addr_1_reg),
      .desc_0_data_host_addr_2_reg(wr_req_desc_0_data_host_addr_2_reg),
      .desc_0_data_host_addr_3_reg(wr_req_desc_0_data_host_addr_3_reg),
      .desc_0_wstrb_host_addr_0_reg(wr_req_desc_0_wstrb_host_addr_0_reg),
      .desc_0_wstrb_host_addr_1_reg(wr_req_desc_0_wstrb_host_addr_1_reg),
      .desc_0_wstrb_host_addr_2_reg(wr_req_desc_0_wstrb_host_addr_2_reg),
      .desc_0_wstrb_host_addr_3_reg(wr_req_desc_0_wstrb_host_addr_3_reg),
      
      .desc_1_txn_type_reg(wr_req_desc_1_txn_type_reg),
      .desc_1_size_reg(wr_req_desc_1_size_reg),
      .desc_1_data_offset_reg(wr_req_desc_1_data_offset_reg),
      .desc_1_data_host_addr_0_reg(wr_req_desc_1_data_host_addr_0_reg),
      .desc_1_data_host_addr_1_reg(wr_req_desc_1_data_host_addr_1_reg),
      .desc_1_data_host_addr_2_reg(wr_req_desc_1_data_host_addr_2_reg),
      .desc_1_data_host_addr_3_reg(wr_req_desc_1_data_host_addr_3_reg),
      .desc_1_wstrb_host_addr_0_reg(wr_req_desc_1_wstrb_host_addr_0_reg),
      .desc_1_wstrb_host_addr_1_reg(wr_req_desc_1_wstrb_host_addr_1_reg),
      .desc_1_wstrb_host_addr_2_reg(wr_req_desc_1_wstrb_host_addr_2_reg),
      .desc_1_wstrb_host_addr_3_reg(wr_req_desc_1_wstrb_host_addr_3_reg),
      
      .desc_2_txn_type_reg(wr_req_desc_2_txn_type_reg),
      .desc_2_size_reg(wr_req_desc_2_size_reg),
      .desc_2_data_offset_reg(wr_req_desc_2_data_offset_reg),
      .desc_2_data_host_addr_0_reg(wr_req_desc_2_data_host_addr_0_reg),
      .desc_2_data_host_addr_1_reg(wr_req_desc_2_data_host_addr_1_reg),
      .desc_2_data_host_addr_2_reg(wr_req_desc_2_data_host_addr_2_reg),
      .desc_2_data_host_addr_3_reg(wr_req_desc_2_data_host_addr_3_reg),
      .desc_2_wstrb_host_addr_0_reg(wr_req_desc_2_wstrb_host_addr_0_reg),
      .desc_2_wstrb_host_addr_1_reg(wr_req_desc_2_wstrb_host_addr_1_reg),
      .desc_2_wstrb_host_addr_2_reg(wr_req_desc_2_wstrb_host_addr_2_reg),
      .desc_2_wstrb_host_addr_3_reg(wr_req_desc_2_wstrb_host_addr_3_reg),
      
      .desc_3_txn_type_reg(wr_req_desc_3_txn_type_reg),
      .desc_3_size_reg(wr_req_desc_3_size_reg),
      .desc_3_data_offset_reg(wr_req_desc_3_data_offset_reg),
      .desc_3_data_host_addr_0_reg(wr_req_desc_3_data_host_addr_0_reg),
      .desc_3_data_host_addr_1_reg(wr_req_desc_3_data_host_addr_1_reg),
      .desc_3_data_host_addr_2_reg(wr_req_desc_3_data_host_addr_2_reg),
      .desc_3_data_host_addr_3_reg(wr_req_desc_3_data_host_addr_3_reg),
      .desc_3_wstrb_host_addr_0_reg(wr_req_desc_3_wstrb_host_addr_0_reg),
      .desc_3_wstrb_host_addr_1_reg(wr_req_desc_3_wstrb_host_addr_1_reg),
      .desc_3_wstrb_host_addr_2_reg(wr_req_desc_3_wstrb_host_addr_2_reg),
      .desc_3_wstrb_host_addr_3_reg(wr_req_desc_3_wstrb_host_addr_3_reg),
      
      .desc_4_txn_type_reg(wr_req_desc_4_txn_type_reg),
      .desc_4_size_reg(wr_req_desc_4_size_reg),
      .desc_4_data_offset_reg(wr_req_desc_4_data_offset_reg),
      .desc_4_data_host_addr_0_reg(wr_req_desc_4_data_host_addr_0_reg),
      .desc_4_data_host_addr_1_reg(wr_req_desc_4_data_host_addr_1_reg),
      .desc_4_data_host_addr_2_reg(wr_req_desc_4_data_host_addr_2_reg),
      .desc_4_data_host_addr_3_reg(wr_req_desc_4_data_host_addr_3_reg),
      .desc_4_wstrb_host_addr_0_reg(wr_req_desc_4_wstrb_host_addr_0_reg),
      .desc_4_wstrb_host_addr_1_reg(wr_req_desc_4_wstrb_host_addr_1_reg),
      .desc_4_wstrb_host_addr_2_reg(wr_req_desc_4_wstrb_host_addr_2_reg),
      .desc_4_wstrb_host_addr_3_reg(wr_req_desc_4_wstrb_host_addr_3_reg),
      
      .desc_5_txn_type_reg(wr_req_desc_5_txn_type_reg),
      .desc_5_size_reg(wr_req_desc_5_size_reg),
      .desc_5_data_offset_reg(wr_req_desc_5_data_offset_reg),
      .desc_5_data_host_addr_0_reg(wr_req_desc_5_data_host_addr_0_reg),
      .desc_5_data_host_addr_1_reg(wr_req_desc_5_data_host_addr_1_reg),
      .desc_5_data_host_addr_2_reg(wr_req_desc_5_data_host_addr_2_reg),
      .desc_5_data_host_addr_3_reg(wr_req_desc_5_data_host_addr_3_reg),
      .desc_5_wstrb_host_addr_0_reg(wr_req_desc_5_wstrb_host_addr_0_reg),
      .desc_5_wstrb_host_addr_1_reg(wr_req_desc_5_wstrb_host_addr_1_reg),
      .desc_5_wstrb_host_addr_2_reg(wr_req_desc_5_wstrb_host_addr_2_reg),
      .desc_5_wstrb_host_addr_3_reg(wr_req_desc_5_wstrb_host_addr_3_reg),
      
      
      .desc_6_txn_type_reg(wr_req_desc_6_txn_type_reg),
      .desc_6_size_reg(wr_req_desc_6_size_reg),
      .desc_6_data_offset_reg(wr_req_desc_6_data_offset_reg),
      .desc_6_data_host_addr_0_reg(wr_req_desc_6_data_host_addr_0_reg),
      .desc_6_data_host_addr_1_reg(wr_req_desc_6_data_host_addr_1_reg),
      .desc_6_data_host_addr_2_reg(wr_req_desc_6_data_host_addr_2_reg),
      .desc_6_data_host_addr_3_reg(wr_req_desc_6_data_host_addr_3_reg),
      .desc_6_wstrb_host_addr_0_reg(wr_req_desc_6_wstrb_host_addr_0_reg),
      .desc_6_wstrb_host_addr_1_reg(wr_req_desc_6_wstrb_host_addr_1_reg),
      .desc_6_wstrb_host_addr_2_reg(wr_req_desc_6_wstrb_host_addr_2_reg),
      .desc_6_wstrb_host_addr_3_reg(wr_req_desc_6_wstrb_host_addr_3_reg),
      
      
      .desc_7_txn_type_reg(wr_req_desc_7_txn_type_reg),
      .desc_7_size_reg(wr_req_desc_7_size_reg),
      .desc_7_data_offset_reg(wr_req_desc_7_data_offset_reg),
      .desc_7_data_host_addr_0_reg(wr_req_desc_7_data_host_addr_0_reg),
      .desc_7_data_host_addr_1_reg(wr_req_desc_7_data_host_addr_1_reg),
      .desc_7_data_host_addr_2_reg(wr_req_desc_7_data_host_addr_2_reg),
      .desc_7_data_host_addr_3_reg(wr_req_desc_7_data_host_addr_3_reg),
      .desc_7_wstrb_host_addr_0_reg(wr_req_desc_7_wstrb_host_addr_0_reg),
      .desc_7_wstrb_host_addr_1_reg(wr_req_desc_7_wstrb_host_addr_1_reg),
      .desc_7_wstrb_host_addr_2_reg(wr_req_desc_7_wstrb_host_addr_2_reg),
      .desc_7_wstrb_host_addr_3_reg(wr_req_desc_7_wstrb_host_addr_3_reg),
      
      .desc_8_txn_type_reg(wr_req_desc_8_txn_type_reg),
      .desc_8_size_reg(wr_req_desc_8_size_reg),
      .desc_8_data_offset_reg(wr_req_desc_8_data_offset_reg),
      .desc_8_data_host_addr_0_reg(wr_req_desc_8_data_host_addr_0_reg),
      .desc_8_data_host_addr_1_reg(wr_req_desc_8_data_host_addr_1_reg),
      .desc_8_data_host_addr_2_reg(wr_req_desc_8_data_host_addr_2_reg),
      .desc_8_data_host_addr_3_reg(wr_req_desc_8_data_host_addr_3_reg),
      .desc_8_wstrb_host_addr_0_reg(wr_req_desc_8_wstrb_host_addr_0_reg),
      .desc_8_wstrb_host_addr_1_reg(wr_req_desc_8_wstrb_host_addr_1_reg),
      .desc_8_wstrb_host_addr_2_reg(wr_req_desc_8_wstrb_host_addr_2_reg),
      .desc_8_wstrb_host_addr_3_reg(wr_req_desc_8_wstrb_host_addr_3_reg),
      
      .desc_9_txn_type_reg(wr_req_desc_9_txn_type_reg),
      .desc_9_size_reg(wr_req_desc_9_size_reg),
      .desc_9_data_offset_reg(wr_req_desc_9_data_offset_reg),
      .desc_9_data_host_addr_0_reg(wr_req_desc_9_data_host_addr_0_reg),
      .desc_9_data_host_addr_1_reg(wr_req_desc_9_data_host_addr_1_reg),
      .desc_9_data_host_addr_2_reg(wr_req_desc_9_data_host_addr_2_reg),
      .desc_9_data_host_addr_3_reg(wr_req_desc_9_data_host_addr_3_reg),
      .desc_9_wstrb_host_addr_0_reg(wr_req_desc_9_wstrb_host_addr_0_reg),
      .desc_9_wstrb_host_addr_1_reg(wr_req_desc_9_wstrb_host_addr_1_reg),
      .desc_9_wstrb_host_addr_2_reg(wr_req_desc_9_wstrb_host_addr_2_reg),
      .desc_9_wstrb_host_addr_3_reg(wr_req_desc_9_wstrb_host_addr_3_reg),
      
      .desc_10_txn_type_reg(wr_req_desc_a_txn_type_reg),
      .desc_10_size_reg(wr_req_desc_a_size_reg),
      .desc_10_data_offset_reg(wr_req_desc_a_data_offset_reg),
      .desc_10_data_host_addr_0_reg(wr_req_desc_a_data_host_addr_0_reg),
      .desc_10_data_host_addr_1_reg(wr_req_desc_a_data_host_addr_1_reg),
      .desc_10_data_host_addr_2_reg(wr_req_desc_a_data_host_addr_2_reg),
      .desc_10_data_host_addr_3_reg(wr_req_desc_a_data_host_addr_3_reg),
      .desc_10_wstrb_host_addr_0_reg(wr_req_desc_a_wstrb_host_addr_0_reg),
      .desc_10_wstrb_host_addr_1_reg(wr_req_desc_a_wstrb_host_addr_1_reg),
      .desc_10_wstrb_host_addr_2_reg(wr_req_desc_a_wstrb_host_addr_2_reg),
      .desc_10_wstrb_host_addr_3_reg(wr_req_desc_a_wstrb_host_addr_3_reg),
      
      .desc_11_txn_type_reg(wr_req_desc_b_txn_type_reg),
      .desc_11_size_reg(wr_req_desc_b_size_reg),
      .desc_11_data_offset_reg(wr_req_desc_b_data_offset_reg),
      .desc_11_data_host_addr_0_reg(wr_req_desc_b_data_host_addr_0_reg),
      .desc_11_data_host_addr_1_reg(wr_req_desc_b_data_host_addr_1_reg),
      .desc_11_data_host_addr_2_reg(wr_req_desc_b_data_host_addr_2_reg),
      .desc_11_data_host_addr_3_reg(wr_req_desc_b_data_host_addr_3_reg),
      .desc_11_wstrb_host_addr_0_reg(wr_req_desc_b_wstrb_host_addr_0_reg),
      .desc_11_wstrb_host_addr_1_reg(wr_req_desc_b_wstrb_host_addr_1_reg),
      .desc_11_wstrb_host_addr_2_reg(wr_req_desc_b_wstrb_host_addr_2_reg),
      .desc_11_wstrb_host_addr_3_reg(wr_req_desc_b_wstrb_host_addr_3_reg),
      
      
      .desc_12_txn_type_reg(wr_req_desc_c_txn_type_reg),
      .desc_12_size_reg(wr_req_desc_c_size_reg),
      .desc_12_data_offset_reg(wr_req_desc_c_data_offset_reg),
      .desc_12_data_host_addr_0_reg(wr_req_desc_c_data_host_addr_0_reg),
      .desc_12_data_host_addr_1_reg(wr_req_desc_c_data_host_addr_1_reg),
      .desc_12_data_host_addr_2_reg(wr_req_desc_c_data_host_addr_2_reg),
      .desc_12_data_host_addr_3_reg(wr_req_desc_c_data_host_addr_3_reg),
      .desc_12_wstrb_host_addr_0_reg(wr_req_desc_c_wstrb_host_addr_0_reg),
      .desc_12_wstrb_host_addr_1_reg(wr_req_desc_c_wstrb_host_addr_1_reg),
      .desc_12_wstrb_host_addr_2_reg(wr_req_desc_c_wstrb_host_addr_2_reg),
      .desc_12_wstrb_host_addr_3_reg(wr_req_desc_c_wstrb_host_addr_3_reg),
      
      
      .desc_13_txn_type_reg(wr_req_desc_d_txn_type_reg),
      .desc_13_size_reg(wr_req_desc_d_size_reg),
      .desc_13_data_offset_reg(wr_req_desc_d_data_offset_reg),
      .desc_13_data_host_addr_0_reg(wr_req_desc_d_data_host_addr_0_reg),
      .desc_13_data_host_addr_1_reg(wr_req_desc_d_data_host_addr_1_reg),
      .desc_13_data_host_addr_2_reg(wr_req_desc_d_data_host_addr_2_reg),
      .desc_13_data_host_addr_3_reg(wr_req_desc_d_data_host_addr_3_reg),
      .desc_13_wstrb_host_addr_0_reg(wr_req_desc_d_wstrb_host_addr_0_reg),
      .desc_13_wstrb_host_addr_1_reg(wr_req_desc_d_wstrb_host_addr_1_reg),
      .desc_13_wstrb_host_addr_2_reg(wr_req_desc_d_wstrb_host_addr_2_reg),
      .desc_13_wstrb_host_addr_3_reg(wr_req_desc_d_wstrb_host_addr_3_reg),
      
      .desc_14_txn_type_reg(wr_req_desc_e_txn_type_reg),
      .desc_14_size_reg(wr_req_desc_e_size_reg),
      .desc_14_data_offset_reg(wr_req_desc_e_data_offset_reg),
      .desc_14_data_host_addr_0_reg(wr_req_desc_e_data_host_addr_0_reg),
      .desc_14_data_host_addr_1_reg(wr_req_desc_e_data_host_addr_1_reg),
      .desc_14_data_host_addr_2_reg(wr_req_desc_e_data_host_addr_2_reg),
      .desc_14_data_host_addr_3_reg(wr_req_desc_e_data_host_addr_3_reg),
      .desc_14_wstrb_host_addr_0_reg(wr_req_desc_e_wstrb_host_addr_0_reg),
      .desc_14_wstrb_host_addr_1_reg(wr_req_desc_e_wstrb_host_addr_1_reg),
      .desc_14_wstrb_host_addr_2_reg(wr_req_desc_e_wstrb_host_addr_2_reg),
      .desc_14_wstrb_host_addr_3_reg(wr_req_desc_e_wstrb_host_addr_3_reg),
      
      
      .desc_15_txn_type_reg(wr_req_desc_f_txn_type_reg),
      .desc_15_size_reg(wr_req_desc_f_size_reg),
      .desc_15_data_offset_reg(wr_req_desc_f_data_offset_reg),
      .desc_15_data_host_addr_0_reg(wr_req_desc_f_data_host_addr_0_reg),
      .desc_15_data_host_addr_1_reg(wr_req_desc_f_data_host_addr_1_reg),
      .desc_15_data_host_addr_2_reg(wr_req_desc_f_data_host_addr_2_reg),
      .desc_15_data_host_addr_3_reg(wr_req_desc_f_data_host_addr_3_reg),
      .desc_15_wstrb_host_addr_0_reg(wr_req_desc_f_wstrb_host_addr_0_reg),
      .desc_15_wstrb_host_addr_1_reg(wr_req_desc_f_wstrb_host_addr_1_reg),
      .desc_15_wstrb_host_addr_2_reg(wr_req_desc_f_wstrb_host_addr_2_reg),
      .desc_15_wstrb_host_addr_3_reg(wr_req_desc_f_wstrb_host_addr_3_reg),


      // M-AXI 
      .m_axi_awid       (m_axi_awid    ), 
      .m_axi_awaddr     (m_axi_awaddr  ), 
      .m_axi_awlen      (m_axi_awlen   ), 
      .m_axi_awsize     (m_axi_awsize  ), 
      .m_axi_awburst    (m_axi_awburst ), 
      .m_axi_awlock     (m_axi_awlock  ), 
      .m_axi_awcache    (m_axi_awcache ), 
      .m_axi_awprot     (m_axi_awprot  ), 
      .m_axi_awqos      (m_axi_awqos   ), 
      .m_axi_awregion   (m_axi_awregion), 
      .m_axi_awuser     (m_axi_awuser  ), 
      .m_axi_awvalid    (m_axi_awvalid ), 
      .m_axi_awready    (m_axi_awready ), 
      .m_axi_wdata      (m_axi_wdata   ), 
      .m_axi_wstrb      (m_axi_wstrb   ), 
      .m_axi_wlast      (m_axi_wlast   ), 
      .m_axi_wuser      (m_axi_wuser   ), 
      .m_axi_wvalid     (m_axi_wvalid  ), 
      .m_axi_wready     (m_axi_wready  ), 
      .m_axi_bid        (m_axi_bid     ), 
      .m_axi_bresp      (m_axi_bresp   ), 
      .m_axi_buser      (m_axi_buser   ), 
      .m_axi_bvalid     (m_axi_bvalid  ), 
      .m_axi_bready     (m_axi_bready  ), 
      .m_axi_arid       (), 
      .m_axi_araddr     (), 
      .m_axi_arlen      (), 
      .m_axi_arsize     (), 
      .m_axi_arburst    (), 
      .m_axi_arlock     (), 
      .m_axi_arcache    (), 
      .m_axi_arprot     (), 
      .m_axi_arqos      (), 
      .m_axi_arregion   (), 
      .m_axi_aruser     (), 
      .m_axi_arvalid    (), 
      .m_axi_arready    (1'b0), 
      .m_axi_rid        ({M_AXI_ID_WIDTH{1'b0}}), 
      .m_axi_rdata      ({M_AXI_DATA_WIDTH{1'b0}}), 
      .m_axi_rresp      (2'b0), 
      .m_axi_rlast      (1'b0), 
      .m_axi_ruser      ({M_AXI_USER_WIDTH{1'b0}}), 
      .m_axi_rvalid     (1'b0), 
      .m_axi_rready     (), 


      // Inputs
      .version_reg          (version_reg),
      .bridge_type_reg      (bridge_type_reg),
      .axi_max_desc_reg     ({ {(32-XX_DESC_IDX_WIDTH){1'b0}}, XX_MAX_DESC[XX_DESC_IDX_WIDTH-1:0] } ),
      
      .uc2hm_trig           (wr_uc2hm_trig),
      .rb2hm_rd_dout        (rb2hm_rd_data),
      .rb2hm_rd_wstrb       (rb2hm_rd_wstrb)
      );


   
endmodule   



