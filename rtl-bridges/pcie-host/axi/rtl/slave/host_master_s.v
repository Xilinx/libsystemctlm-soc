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
 *   Host Master block which controls fetching & writing data from & to Host
 *   in Mode 1. For Slave Bridge
 *
 *
 */

`include "defines_common.vh"
module host_master_s
  #(
    parameter M_AXI_ADDR_WIDTH              =   64,    
    parameter M_AXI_DATA_WIDTH              =   128, //Allowed values : 128
    parameter M_AXI_ID_WIDTH                =   4,  //Allowed values : 4-16
    parameter M_AXI_USER_WIDTH              =   32, //Allowed values : 1-32  
    parameter RAM_SIZE                     =   16384, // Size of RAM in Bytes
    parameter S_AXI_USR_DATA_WIDTH         = 128,
    parameter MAX_DESC                     =   16,
    parameter EXTEND_WSTRB                 =   1
  
    )
   (
	
	input 													 axi_aclk,
	input 													 axi_aresetn,
	// M_AXI interface AXI4
   
    output [M_AXI_ID_WIDTH-1 : 0] 							 m_axi_awid,
    output [M_AXI_ADDR_WIDTH-1 : 0] 						 m_axi_awaddr,
    output [7 : 0] 											 m_axi_awlen,
    output [2 : 0] 											 m_axi_awsize,
    output [1 : 0] 											 m_axi_awburst,
    output 													 m_axi_awlock,
    output [3 : 0] 											 m_axi_awcache,
    output [2 : 0] 											 m_axi_awprot,
    output [3 : 0] 											 m_axi_awqos,
    output [3:0] 											 m_axi_awregion, 
    output [M_AXI_USER_WIDTH-1 : 0] 						 m_axi_awuser,
    output 													 m_axi_awvalid,
    input 													 m_axi_awready,
    output [M_AXI_DATA_WIDTH-1 : 0] 						 m_axi_wdata,
    output [M_AXI_DATA_WIDTH/8-1 : 0] 						 m_axi_wstrb,
    output 													 m_axi_wlast,
    output [M_AXI_USER_WIDTH-1 : 0] 						 m_axi_wuser,
    output 													 m_axi_wvalid,
    input 													 m_axi_wready,
    input [M_AXI_ID_WIDTH-1 : 0] 							 m_axi_bid,
    input [1 : 0] 											 m_axi_bresp,
    input [M_AXI_USER_WIDTH-1 : 0] 							 m_axi_buser,
    input 													 m_axi_bvalid,
    output 													 m_axi_bready,
    output [M_AXI_ID_WIDTH-1 : 0] 							 m_axi_arid,
    output [M_AXI_ADDR_WIDTH-1 : 0] 						 m_axi_araddr,
    output [7 : 0] 											 m_axi_arlen,
    output [2 : 0] 											 m_axi_arsize,
    output [1 : 0] 											 m_axi_arburst,
    output 													 m_axi_arlock,
    output [3 : 0] 											 m_axi_arcache,
    output [2 : 0] 											 m_axi_arprot,
    output [3 : 0] 											 m_axi_arqos,
    output [3:0] 											 m_axi_arregion,
    output [M_AXI_USER_WIDTH-1 : 0] 						 m_axi_aruser,
    output 													 m_axi_arvalid,
    input 													 m_axi_arready,
    input [M_AXI_ID_WIDTH-1 : 0] 							 m_axi_rid,
    input [M_AXI_DATA_WIDTH-1 : 0] 							 m_axi_rdata,
    input [1 : 0] 											 m_axi_rresp,
    input 													 m_axi_rlast,
    input [M_AXI_USER_WIDTH-1 : 0] 							 m_axi_ruser,
    input 													 m_axi_rvalid,
    output 													 m_axi_rready,


	//RB - HM interface Reg values
   

    input [31:0] 											 desc_0_txn_type_reg ,
    input [31:0] 											 desc_0_size_reg ,
    input [31:0] 											 desc_0_data_offset_reg ,
    input [31:0] 											 desc_0_data_host_addr_0_reg ,
    input [31:0] 											 desc_0_data_host_addr_1_reg ,
    input [31:0] 											 desc_0_data_host_addr_2_reg ,
    input [31:0] 											 desc_0_data_host_addr_3_reg ,
    input [31:0] 											 desc_0_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_0_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_0_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_0_wstrb_host_addr_3_reg ,

    input [31:0] 											 desc_1_txn_type_reg ,
    input [31:0] 											 desc_1_size_reg ,
    input [31:0] 											 desc_1_data_offset_reg ,
    input [31:0] 											 desc_1_data_host_addr_0_reg ,
    input [31:0] 											 desc_1_data_host_addr_1_reg ,
    input [31:0] 											 desc_1_data_host_addr_2_reg ,
    input [31:0] 											 desc_1_data_host_addr_3_reg ,
    input [31:0] 											 desc_1_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_1_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_1_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_1_wstrb_host_addr_3_reg ,


    input [31:0] 											 desc_2_txn_type_reg ,
    input [31:0] 											 desc_2_size_reg ,
    input [31:0] 											 desc_2_data_offset_reg ,
    input [31:0] 											 desc_2_data_host_addr_0_reg ,
    input [31:0] 											 desc_2_data_host_addr_1_reg ,
    input [31:0] 											 desc_2_data_host_addr_2_reg ,
    input [31:0] 											 desc_2_data_host_addr_3_reg ,
    input [31:0] 											 desc_2_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_2_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_2_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_2_wstrb_host_addr_3_reg ,


    input [31:0] 											 desc_3_txn_type_reg ,
    input [31:0] 											 desc_3_size_reg ,
    input [31:0] 											 desc_3_data_offset_reg ,
    input [31:0] 											 desc_3_data_host_addr_0_reg ,
    input [31:0] 											 desc_3_data_host_addr_1_reg ,
    input [31:0] 											 desc_3_data_host_addr_2_reg ,
    input [31:0] 											 desc_3_data_host_addr_3_reg ,
    input [31:0] 											 desc_3_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_3_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_3_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_3_wstrb_host_addr_3_reg ,


    input [31:0] 											 desc_4_txn_type_reg ,
    input [31:0] 											 desc_4_size_reg ,
    input [31:0] 											 desc_4_data_offset_reg ,
    input [31:0] 											 desc_4_data_host_addr_0_reg ,
    input [31:0] 											 desc_4_data_host_addr_1_reg ,
    input [31:0] 											 desc_4_data_host_addr_2_reg ,
    input [31:0] 											 desc_4_data_host_addr_3_reg ,
    input [31:0] 											 desc_4_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_4_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_4_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_4_wstrb_host_addr_3_reg ,


    input [31:0] 											 desc_5_txn_type_reg ,
    input [31:0] 											 desc_5_size_reg ,
    input [31:0] 											 desc_5_data_offset_reg ,
    input [31:0] 											 desc_5_data_host_addr_0_reg ,
    input [31:0] 											 desc_5_data_host_addr_1_reg ,
    input [31:0] 											 desc_5_data_host_addr_2_reg ,
    input [31:0] 											 desc_5_data_host_addr_3_reg ,
    input [31:0] 											 desc_5_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_5_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_5_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_5_wstrb_host_addr_3_reg ,


    input [31:0] 											 desc_6_txn_type_reg ,
    input [31:0] 											 desc_6_size_reg ,
    input [31:0] 											 desc_6_data_offset_reg ,
    input [31:0] 											 desc_6_data_host_addr_0_reg ,
    input [31:0] 											 desc_6_data_host_addr_1_reg ,
    input [31:0] 											 desc_6_data_host_addr_2_reg ,
    input [31:0] 											 desc_6_data_host_addr_3_reg ,
    input [31:0] 											 desc_6_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_6_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_6_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_6_wstrb_host_addr_3_reg ,


    input [31:0] 											 desc_7_txn_type_reg ,
    input [31:0] 											 desc_7_size_reg ,
    input [31:0] 											 desc_7_data_offset_reg ,
    input [31:0] 											 desc_7_data_host_addr_0_reg ,
    input [31:0] 											 desc_7_data_host_addr_1_reg ,
    input [31:0] 											 desc_7_data_host_addr_2_reg ,
    input [31:0] 											 desc_7_data_host_addr_3_reg ,
    input [31:0] 											 desc_7_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_7_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_7_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_7_wstrb_host_addr_3_reg ,


    input [31:0] 											 desc_8_txn_type_reg ,
    input [31:0] 											 desc_8_size_reg ,
    input [31:0] 											 desc_8_data_offset_reg ,
    input [31:0] 											 desc_8_data_host_addr_0_reg ,
    input [31:0] 											 desc_8_data_host_addr_1_reg ,
    input [31:0] 											 desc_8_data_host_addr_2_reg ,
    input [31:0] 											 desc_8_data_host_addr_3_reg ,
    input [31:0] 											 desc_8_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_8_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_8_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_8_wstrb_host_addr_3_reg ,

    input [31:0] 											 desc_9_txn_type_reg ,
    input [31:0] 											 desc_9_size_reg ,
    input [31:0] 											 desc_9_data_offset_reg ,
    input [31:0] 											 desc_9_data_host_addr_0_reg ,
    input [31:0] 											 desc_9_data_host_addr_1_reg ,
    input [31:0] 											 desc_9_data_host_addr_2_reg ,
    input [31:0] 											 desc_9_data_host_addr_3_reg ,
    input [31:0] 											 desc_9_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_9_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_9_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_9_wstrb_host_addr_3_reg ,

    input [31:0] 											 desc_10_txn_type_reg ,
    input [31:0] 											 desc_10_size_reg ,
    input [31:0] 											 desc_10_data_offset_reg ,
    input [31:0] 											 desc_10_data_host_addr_0_reg ,
    input [31:0] 											 desc_10_data_host_addr_1_reg ,
    input [31:0] 											 desc_10_data_host_addr_2_reg ,
    input [31:0] 											 desc_10_data_host_addr_3_reg ,
    input [31:0] 											 desc_10_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_10_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_10_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_10_wstrb_host_addr_3_reg ,



    input [31:0] 											 desc_11_txn_type_reg ,
    input [31:0] 											 desc_11_size_reg ,
    input [31:0] 											 desc_11_data_offset_reg ,
    input [31:0] 											 desc_11_data_host_addr_0_reg ,
    input [31:0] 											 desc_11_data_host_addr_1_reg ,
    input [31:0] 											 desc_11_data_host_addr_2_reg ,
    input [31:0] 											 desc_11_data_host_addr_3_reg ,
    input [31:0] 											 desc_11_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_11_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_11_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_11_wstrb_host_addr_3_reg ,

    input [31:0] 											 desc_12_txn_type_reg ,
    input [31:0] 											 desc_12_size_reg ,
    input [31:0] 											 desc_12_data_offset_reg ,
    input [31:0] 											 desc_12_data_host_addr_0_reg ,
    input [31:0] 											 desc_12_data_host_addr_1_reg ,
    input [31:0] 											 desc_12_data_host_addr_2_reg ,
    input [31:0] 											 desc_12_data_host_addr_3_reg ,
    input [31:0] 											 desc_12_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_12_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_12_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_12_wstrb_host_addr_3_reg ,


    input [31:0] 											 desc_13_txn_type_reg ,
    input [31:0] 											 desc_13_size_reg ,
    input [31:0] 											 desc_13_data_offset_reg ,
    input [31:0] 											 desc_13_data_host_addr_0_reg ,
    input [31:0] 											 desc_13_data_host_addr_1_reg ,
    input [31:0] 											 desc_13_data_host_addr_2_reg ,
    input [31:0] 											 desc_13_data_host_addr_3_reg ,
    input [31:0] 											 desc_13_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_13_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_13_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_13_wstrb_host_addr_3_reg ,


    input [31:0] 											 desc_14_txn_type_reg ,
    input [31:0] 											 desc_14_size_reg ,
    input [31:0] 											 desc_14_data_offset_reg ,
    input [31:0] 											 desc_14_data_host_addr_0_reg ,
    input [31:0] 											 desc_14_data_host_addr_1_reg ,
    input [31:0] 											 desc_14_data_host_addr_2_reg ,
    input [31:0] 											 desc_14_data_host_addr_3_reg ,
    input [31:0] 											 desc_14_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_14_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_14_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_14_wstrb_host_addr_3_reg ,


    input [31:0] 											 desc_15_txn_type_reg ,
    input [31:0] 											 desc_15_size_reg ,
    input [31:0] 											 desc_15_data_offset_reg ,
    input [31:0] 											 desc_15_data_host_addr_0_reg ,
    input [31:0] 											 desc_15_data_host_addr_1_reg ,
    input [31:0] 											 desc_15_data_host_addr_2_reg ,
    input [31:0] 											 desc_15_data_host_addr_3_reg ,
    input [31:0] 											 desc_15_wstrb_host_addr_0_reg ,
    input [31:0] 											 desc_15_wstrb_host_addr_1_reg ,
    input [31:0] 											 desc_15_wstrb_host_addr_2_reg ,
    input [31:0] 											 desc_15_wstrb_host_addr_3_reg ,


	// HM <-> UC interface
    output reg [MAX_DESC-1:0] 								 hm2uc_done,
    input [MAX_DESC-1:0] 									 uc2hm_trig,

	// HM <-> RB interface

    // Read port of RD DataRam
    output [(`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8)))-1:0] hm2rb_rd_addr, 
    input [S_AXI_USR_DATA_WIDTH-1:0] 						 rb2hm_rd_dout,
    input [(S_AXI_USR_DATA_WIDTH/8)-1:0] 					 rb2hm_rd_wstrb, 
	
    // Write port of WR DataRam
    output 													 hm2rb_wr_we, 
    output [(S_AXI_USR_DATA_WIDTH/8 -1):0] 					 hm2rb_wr_bwe, 
    output [(`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8)))-1:0] hm2rb_wr_addr, 
    output [S_AXI_USR_DATA_WIDTH-1:0] 						 hm2rb_wr_data_in,
    output [(S_AXI_USR_DATA_WIDTH/8 -1):0] 					 hm2rb_wr_wstrb_in,


	// Regs in from rb to hm
	input [31:0] 											 rb2hm_intr_error_status_reg,
	input [31:0] 											 rb2hm_intr_error_clear_reg,

	input [31:0] 											 version_reg,
	input [31:0] 											 bridge_type_reg,
	input [31:0] 											 axi_max_desc_reg,
	
    output [31:0] 											 hm2rb_intr_error_status_reg, 
    output [31:0] 											 hm2rb_intr_error_status_reg_we     
    );
   



   //wires
   /*AUTOWIRE*/

   reg [31:0] 												 desc_n_axaddr_0_reg[MAX_DESC-1:0];
   reg [31:0] 												 desc_n_axaddr_1_reg[MAX_DESC-1:0];
   reg [31:0] 												 desc_n_axaddr_2_reg[MAX_DESC-1:0];
   reg [31:0] 												 desc_n_axaddr_3_reg[MAX_DESC-1:0];

   wire [31:0] 												 desc_n_data_host_addr_0[MAX_DESC-1:0];
   wire [31:0] 												 desc_n_data_host_addr_1[MAX_DESC-1:0];
   wire [31:0] 												 desc_n_data_host_addr_2[MAX_DESC-1:0];
   wire [31:0] 												 desc_n_data_host_addr_3[MAX_DESC-1:0];

   wire [31:0] 												 desc_n_wstrb_host_addr_0[MAX_DESC-1:0];
   wire [31:0] 												 desc_n_wstrb_host_addr_1[MAX_DESC-1:0];
   wire [31:0] 												 desc_n_wstrb_host_addr_2[MAX_DESC-1:0];
   wire [31:0] 												 desc_n_wstrb_host_addr_3[MAX_DESC-1:0];

   wire [(`CLOG2(MAX_DESC))-1:0] 							 uc2rb_wr_desc_id;
   wire [(`CLOG2(MAX_DESC))-1:0] 							 uc2rb_rd_addr_desc_id;   
   

   wire [31:0] 												 desc_0_txn_type_hm_reg  ;
   wire [31:0] 												 desc_1_txn_type_hm_reg  ;
   wire [31:0] 												 desc_2_txn_type_hm_reg  ;
   wire [31:0] 												 desc_3_txn_type_hm_reg  ;
   wire [31:0] 												 desc_4_txn_type_hm_reg  ;
   wire [31:0] 												 desc_5_txn_type_hm_reg  ;
   wire [31:0] 												 desc_6_txn_type_hm_reg  ;
   wire [31:0] 												 desc_7_txn_type_hm_reg  ;
   wire [31:0] 												 desc_8_txn_type_hm_reg  ;
   wire [31:0] 												 desc_9_txn_type_hm_reg  ;
   wire [31:0] 												 desc_10_txn_type_hm_reg ;
   wire [31:0] 												 desc_11_txn_type_hm_reg ;
   wire [31:0] 												 desc_12_txn_type_hm_reg ;
   wire [31:0] 												 desc_13_txn_type_hm_reg ;
   wire [31:0] 												 desc_14_txn_type_hm_reg ;
   wire [31:0] 												 desc_15_txn_type_hm_reg ;


   wire [31:0] 										 uc2rb_ownership_reg;
   reg [31:0] 										 uc2rb_ownership_reg_ff;
   wire [MAX_DESC-1:0] 										 desc_n_wstrb_control;
   wire [MAX_DESC-1:0] 										 desc_n_txn_type;
   reg [31:0] 											 hm_txn_start;
   wire [MAX_DESC-1:0] 										 hm_txn_done;
   reg [MAX_DESC-1:0] 										 wstrb_fetch_in_prog;

   
   wire 													 current_data_or_strb;
   wire 													 current_data_or_strb_64;
   wire 													 current_data_or_strb_32;
   reg 														 current_data_or_strb_ff;
   reg 														 current_data_or_strb_ff2;
   reg 														 current_data_or_strb_ff3;
   reg 														 current_data_or_strb_ff4;
   
   //Packing data from RB in case of 64 bit width
   reg [S_AXI_USR_DATA_WIDTH-1:0] rb_unpacked_data_0;
   reg [S_AXI_USR_DATA_WIDTH-1:0] rb_unpacked_data_1;
   reg [S_AXI_USR_DATA_WIDTH-1:0] rb_unpacked_data_2;
   reg [S_AXI_USR_DATA_WIDTH-1:0] rb_unpacked_data_3;
   
   wire [127:0] 				  rb_packed_data;
   wire [127:0] 				  rb_packed_data_32;
   wire [127:0] 				  rb_packed_data_64;
   //Packing unpacking of strobes in case of slave

   reg [(S_AXI_USR_DATA_WIDTH/8)-1:0] rb_unpacked_wstrb_0;
   reg [(S_AXI_USR_DATA_WIDTH/8)-1:0] rb_unpacked_wstrb_1;
   reg [(S_AXI_USR_DATA_WIDTH/8)-1:0] rb_unpacked_wstrb_2;
   reg [(S_AXI_USR_DATA_WIDTH/8)-1:0] rb_unpacked_wstrb_3;
   

   wire [15:0] 				  rb_packed_wstrb_32;
   wire [15:0] 				  rb_packed_wstrb_64;

  
   wire [M_AXI_DATA_WIDTH-1:0] 	  rb2hm_packed_data;
   wire [M_AXI_DATA_WIDTH-1:0] 	  rb_packed_wstrb;
   wire [M_AXI_DATA_WIDTH-1:0] 	  rb_packed_wstrb_extended;
   
   reg [1:0] 					  hm_fetch_state[MAX_DESC-1:0];


   wire                                               hm2rb_wr_128_we;
   wire [(M_AXI_DATA_WIDTH/8 -1):0] 				  hm2rb_wr_128_bwe;
   // Address widht needs to be same as DUT DRAM address width
   // As AXI_Master should be able to send unaligned address as well for DRAM
   wire [(`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8)))-1:0] hm2rb_wr_128_addr;
   wire [M_AXI_DATA_WIDTH-1:0] 						  hm2rb_wr_128_data;
   wire [(M_AXI_DATA_WIDTH/8 -1):0] 				  hm2rb_wr_128_wstrb;
   
   reg 												  hm2rb_wr_128_we_ff;
   reg [(M_AXI_DATA_WIDTH/8 -1):0] 					  hm2rb_wr_128_bwe_ff;
   
   reg 												  hm2rb_wr_128_we_ff1;
   reg [(M_AXI_DATA_WIDTH/8 -1):0] 					  hm2rb_wr_128_bwe_ff1;
   
   reg 												  hm2rb_wr_128_we_ff2;
   reg [(M_AXI_DATA_WIDTH/8 -1):0] 					  hm2rb_wr_128_bwe_ff2;

   
   reg 												  hm2rb_wr_packed_we;
   reg [(S_AXI_USR_DATA_WIDTH/8 -1):0] 				  hm2rb_wr_packed_bwe;
   reg [(`CLOG2(RAM_SIZE/(S_AXI_USR_DATA_WIDTH/8)))-1:0] hm2rb_wr_packed_addr;
   reg [S_AXI_USR_DATA_WIDTH-1:0] 						 hm2rb_wr_packed_data;
   reg [(S_AXI_USR_DATA_WIDTH/8 -1):0] 					 hm2rb_wr_packed_wstrb;
   
   wire [1:0] 											 shift_wr_addr;

   wire [1:0] 											 m_axi_awlock_all_prot;
   wire [1:0] 											 m_axi_arlock_all_prot;
   
   integer 						  k;
   

   assign m_axi_awlock = m_axi_awlock_all_prot[0];
   assign m_axi_arlock = m_axi_arlock_all_prot[0];
   

   
   assign hm2rb_wr_data_strb= (S_AXI_USR_DATA_WIDTH==128) ? current_data_or_strb :
							  ((S_AXI_USR_DATA_WIDTH==64) ? current_data_or_strb_64 : current_data_or_strb_32) ;

   assign current_data_or_strb =  ~wstrb_fetch_in_prog[uc2rb_wr_desc_id];

   // Shifting indication of wheather its data or strb as per DUT Width.  As in case of
   // Dut widht less than 128, its will take extra cycles to fill wdata ram.
   assign current_data_or_strb_64 = current_data_or_strb_ff & current_data_or_strb_ff2;
   assign current_data_or_strb_32 = current_data_or_strb_ff & current_data_or_strb_ff2 & current_data_or_strb_ff3 & current_data_or_strb_ff4;
   
   always@(posedge axi_aclk) begin
	  if(~axi_aresetn) begin
		 current_data_or_strb_ff <= 0;
		 current_data_or_strb_ff2 <= 0;
		 current_data_or_strb_ff3 <= 0;
		 current_data_or_strb_ff4 <= 0;
		 
	  end
	  else begin
		 current_data_or_strb_ff  <= current_data_or_strb;
		 current_data_or_strb_ff2 <= current_data_or_strb_ff;
		 current_data_or_strb_ff3 <= current_data_or_strb_ff2;
		 current_data_or_strb_ff4 <= current_data_or_strb_ff3;
	  end
   end
   
   assign 	desc_n_data_host_addr_0 [0] =		 desc_0_data_host_addr_0_reg ;
   assign 	desc_n_data_host_addr_1 [0] =		 desc_0_data_host_addr_1_reg ;
   assign 	desc_n_data_host_addr_2 [0] =		 desc_0_data_host_addr_2_reg ;
   assign 	desc_n_data_host_addr_3 [0] =		 desc_0_data_host_addr_3_reg ;
   assign 	desc_n_data_host_addr_0 [1] =		 desc_1_data_host_addr_0_reg ;
   assign 	desc_n_data_host_addr_1 [1] =		 desc_1_data_host_addr_1_reg ;
   assign 	desc_n_data_host_addr_2 [1] =		 desc_1_data_host_addr_2_reg ;
   assign 	desc_n_data_host_addr_3 [1] =		 desc_1_data_host_addr_3_reg ;
   assign 	desc_n_data_host_addr_0 [2] =		 desc_2_data_host_addr_0_reg ;
   assign 	desc_n_data_host_addr_1 [2] =		 desc_2_data_host_addr_1_reg ;
   assign 	desc_n_data_host_addr_2 [2] =		 desc_2_data_host_addr_2_reg ;
   assign 	desc_n_data_host_addr_3 [2] =		 desc_2_data_host_addr_3_reg ;
   assign 	desc_n_data_host_addr_0 [3] =		 desc_3_data_host_addr_0_reg ;
   assign 	desc_n_data_host_addr_1 [3] =		 desc_3_data_host_addr_1_reg ;
   assign 	desc_n_data_host_addr_2 [3] =		 desc_3_data_host_addr_2_reg ;
   assign 	desc_n_data_host_addr_3 [3] =		 desc_3_data_host_addr_3_reg ;
   assign 	desc_n_data_host_addr_0 [4] =		 desc_4_data_host_addr_0_reg ;
   assign 	desc_n_data_host_addr_1 [4] =		 desc_4_data_host_addr_1_reg ;
   assign 	desc_n_data_host_addr_2 [4] =		 desc_4_data_host_addr_2_reg ;
   assign 	desc_n_data_host_addr_3 [4] =		 desc_4_data_host_addr_3_reg ;
   assign 	desc_n_data_host_addr_0 [5] =		 desc_5_data_host_addr_0_reg ;
   assign 	desc_n_data_host_addr_1 [5] =		 desc_5_data_host_addr_1_reg ;
   assign 	desc_n_data_host_addr_2 [5] =		 desc_5_data_host_addr_2_reg ;
   assign 	desc_n_data_host_addr_3 [5] =		 desc_5_data_host_addr_3_reg ;
   assign 	desc_n_data_host_addr_0 [6] =		 desc_6_data_host_addr_0_reg ;
   assign 	desc_n_data_host_addr_1 [6] =		 desc_6_data_host_addr_1_reg ;
   assign 	desc_n_data_host_addr_2 [6] =		 desc_6_data_host_addr_2_reg ;
   assign 	desc_n_data_host_addr_3 [6] =		 desc_6_data_host_addr_3_reg ;
   assign 	desc_n_data_host_addr_0 [7] =		 desc_7_data_host_addr_0_reg ;
   assign 	desc_n_data_host_addr_1 [7] =		 desc_7_data_host_addr_1_reg ;
   assign 	desc_n_data_host_addr_2 [7] =		 desc_7_data_host_addr_2_reg ;
   assign 	desc_n_data_host_addr_3 [7] =		 desc_7_data_host_addr_3_reg ;
   assign 	desc_n_data_host_addr_0 [8] =		 desc_8_data_host_addr_0_reg ;
   assign 	desc_n_data_host_addr_1 [8] =		 desc_8_data_host_addr_1_reg ;
   assign 	desc_n_data_host_addr_2 [8] =		 desc_8_data_host_addr_2_reg ;
   assign 	desc_n_data_host_addr_3 [8] =		 desc_8_data_host_addr_3_reg ;
   assign 	desc_n_data_host_addr_0 [9] =		 desc_9_data_host_addr_0_reg ;
   assign 	desc_n_data_host_addr_1 [9] =		 desc_9_data_host_addr_1_reg ;
   assign 	desc_n_data_host_addr_2 [9] =		 desc_9_data_host_addr_2_reg ;
   assign 	desc_n_data_host_addr_3 [9] =		 desc_9_data_host_addr_3_reg ;
   assign  desc_n_data_host_addr_0 [10] =		desc_10_data_host_addr_0_reg ;
   assign  desc_n_data_host_addr_1 [10] =		desc_10_data_host_addr_1_reg ;
   assign  desc_n_data_host_addr_2 [10] =		desc_10_data_host_addr_2_reg ;
   assign  desc_n_data_host_addr_3 [10] =		desc_10_data_host_addr_3_reg ;
   assign  desc_n_data_host_addr_0 [11] =		desc_11_data_host_addr_0_reg ;
   assign  desc_n_data_host_addr_1 [11] =		desc_11_data_host_addr_1_reg ;
   assign  desc_n_data_host_addr_2 [11] =		desc_11_data_host_addr_2_reg ;
   assign  desc_n_data_host_addr_3 [11] =		desc_11_data_host_addr_3_reg ;
   assign  desc_n_data_host_addr_0 [12] =		desc_12_data_host_addr_0_reg ;
   assign  desc_n_data_host_addr_1 [12] =		desc_12_data_host_addr_1_reg ;
   assign  desc_n_data_host_addr_2 [12] =		desc_12_data_host_addr_2_reg ;
   assign  desc_n_data_host_addr_3 [12] =		desc_12_data_host_addr_3_reg ;
   assign  desc_n_data_host_addr_0 [13] =		desc_13_data_host_addr_0_reg ;
   assign  desc_n_data_host_addr_1 [13] =		desc_13_data_host_addr_1_reg ;
   assign  desc_n_data_host_addr_2 [13] =		desc_13_data_host_addr_2_reg ;
   assign  desc_n_data_host_addr_3 [13] =		desc_13_data_host_addr_3_reg ;
   assign  desc_n_data_host_addr_0 [14] =		desc_14_data_host_addr_0_reg ;
   assign  desc_n_data_host_addr_1 [14] =		desc_14_data_host_addr_1_reg ;
   assign  desc_n_data_host_addr_2 [14] =		desc_14_data_host_addr_2_reg ;
   assign  desc_n_data_host_addr_3 [14] =		desc_14_data_host_addr_3_reg ;
   assign  desc_n_data_host_addr_0 [15] =		desc_15_data_host_addr_0_reg ;
   assign  desc_n_data_host_addr_1 [15] =		desc_15_data_host_addr_1_reg ;
   assign  desc_n_data_host_addr_2 [15] =		desc_15_data_host_addr_2_reg ;
   assign  desc_n_data_host_addr_3 [15] =		desc_15_data_host_addr_3_reg ;



   assign 	desc_n_wstrb_host_addr_0 [0] =		 desc_0_wstrb_host_addr_0_reg ;
   assign 	desc_n_wstrb_host_addr_1 [0] =		 desc_0_wstrb_host_addr_1_reg ;
   assign 	desc_n_wstrb_host_addr_2 [0] =		 desc_0_wstrb_host_addr_2_reg ;
   assign 	desc_n_wstrb_host_addr_3 [0] =		 desc_0_wstrb_host_addr_3_reg ;
   assign 	desc_n_wstrb_host_addr_0 [1] =		 desc_1_wstrb_host_addr_0_reg ;
   assign 	desc_n_wstrb_host_addr_1 [1] =		 desc_1_wstrb_host_addr_1_reg ;
   assign 	desc_n_wstrb_host_addr_2 [1] =		 desc_1_wstrb_host_addr_2_reg ;
   assign 	desc_n_wstrb_host_addr_3 [1] =		 desc_1_wstrb_host_addr_3_reg ;
   assign 	desc_n_wstrb_host_addr_0 [2] =		 desc_2_wstrb_host_addr_0_reg ;
   assign 	desc_n_wstrb_host_addr_1 [2] =		 desc_2_wstrb_host_addr_1_reg ;
   assign 	desc_n_wstrb_host_addr_2 [2] =		 desc_2_wstrb_host_addr_2_reg ;
   assign 	desc_n_wstrb_host_addr_3 [2] =		 desc_2_wstrb_host_addr_3_reg ;
   assign 	desc_n_wstrb_host_addr_0 [3] =		 desc_3_wstrb_host_addr_0_reg ;
   assign 	desc_n_wstrb_host_addr_1 [3] =		 desc_3_wstrb_host_addr_1_reg ;
   assign 	desc_n_wstrb_host_addr_2 [3] =		 desc_3_wstrb_host_addr_2_reg ;
   assign 	desc_n_wstrb_host_addr_3 [3] =		 desc_3_wstrb_host_addr_3_reg ;
   assign 	desc_n_wstrb_host_addr_0 [4] =		 desc_4_wstrb_host_addr_0_reg ;
   assign 	desc_n_wstrb_host_addr_1 [4] =		 desc_4_wstrb_host_addr_1_reg ;
   assign 	desc_n_wstrb_host_addr_2 [4] =		 desc_4_wstrb_host_addr_2_reg ;
   assign 	desc_n_wstrb_host_addr_3 [4] =		 desc_4_wstrb_host_addr_3_reg ;
   assign 	desc_n_wstrb_host_addr_0 [5] =		 desc_5_wstrb_host_addr_0_reg ;
   assign 	desc_n_wstrb_host_addr_1 [5] =		 desc_5_wstrb_host_addr_1_reg ;
   assign 	desc_n_wstrb_host_addr_2 [5] =		 desc_5_wstrb_host_addr_2_reg ;
   assign 	desc_n_wstrb_host_addr_3 [5] =		 desc_5_wstrb_host_addr_3_reg ;
   assign 	desc_n_wstrb_host_addr_0 [6] =		 desc_6_wstrb_host_addr_0_reg ;
   assign 	desc_n_wstrb_host_addr_1 [6] =		 desc_6_wstrb_host_addr_1_reg ;
   assign 	desc_n_wstrb_host_addr_2 [6] =		 desc_6_wstrb_host_addr_2_reg ;
   assign 	desc_n_wstrb_host_addr_3 [6] =		 desc_6_wstrb_host_addr_3_reg ;
   assign 	desc_n_wstrb_host_addr_0 [7] =		 desc_7_wstrb_host_addr_0_reg ;
   assign 	desc_n_wstrb_host_addr_1 [7] =		 desc_7_wstrb_host_addr_1_reg ;
   assign 	desc_n_wstrb_host_addr_2 [7] =		 desc_7_wstrb_host_addr_2_reg ;
   assign 	desc_n_wstrb_host_addr_3 [7] =		 desc_7_wstrb_host_addr_3_reg ;
   assign 	desc_n_wstrb_host_addr_0 [8] =		 desc_8_wstrb_host_addr_0_reg ;
   assign 	desc_n_wstrb_host_addr_1 [8] =		 desc_8_wstrb_host_addr_1_reg ;
   assign 	desc_n_wstrb_host_addr_2 [8] =		 desc_8_wstrb_host_addr_2_reg ;
   assign 	desc_n_wstrb_host_addr_3 [8] =		 desc_8_wstrb_host_addr_3_reg ;
   assign 	desc_n_wstrb_host_addr_0 [9] =		 desc_9_wstrb_host_addr_0_reg ;
   assign 	desc_n_wstrb_host_addr_1 [9] =		 desc_9_wstrb_host_addr_1_reg ;
   assign 	desc_n_wstrb_host_addr_2 [9] =		 desc_9_wstrb_host_addr_2_reg ;
   assign 	desc_n_wstrb_host_addr_3 [9] =		 desc_9_wstrb_host_addr_3_reg ;
   assign  desc_n_wstrb_host_addr_0 [10] =		desc_10_wstrb_host_addr_0_reg ;
   assign  desc_n_wstrb_host_addr_1 [10] =		desc_10_wstrb_host_addr_1_reg ;
   assign  desc_n_wstrb_host_addr_2 [10] =		desc_10_wstrb_host_addr_2_reg ;
   assign  desc_n_wstrb_host_addr_3 [10] =		desc_10_wstrb_host_addr_3_reg ;
   assign  desc_n_wstrb_host_addr_0 [11] =		desc_11_wstrb_host_addr_0_reg ;
   assign  desc_n_wstrb_host_addr_1 [11] =		desc_11_wstrb_host_addr_1_reg ;
   assign  desc_n_wstrb_host_addr_2 [11] =		desc_11_wstrb_host_addr_2_reg ;
   assign  desc_n_wstrb_host_addr_3 [11] =		desc_11_wstrb_host_addr_3_reg ;
   assign  desc_n_wstrb_host_addr_0 [12] =		desc_12_wstrb_host_addr_0_reg ;
   assign  desc_n_wstrb_host_addr_1 [12] =		desc_12_wstrb_host_addr_1_reg ;
   assign  desc_n_wstrb_host_addr_2 [12] =		desc_12_wstrb_host_addr_2_reg ;
   assign  desc_n_wstrb_host_addr_3 [12] =		desc_12_wstrb_host_addr_3_reg ;
   assign  desc_n_wstrb_host_addr_0 [13] =		desc_13_wstrb_host_addr_0_reg ;
   assign  desc_n_wstrb_host_addr_1 [13] =		desc_13_wstrb_host_addr_1_reg ;
   assign  desc_n_wstrb_host_addr_2 [13] =		desc_13_wstrb_host_addr_2_reg ;
   assign  desc_n_wstrb_host_addr_3 [13] =		desc_13_wstrb_host_addr_3_reg ;
   assign  desc_n_wstrb_host_addr_0 [14] =		desc_14_wstrb_host_addr_0_reg ;
   assign  desc_n_wstrb_host_addr_1 [14] =		desc_14_wstrb_host_addr_1_reg ;
   assign  desc_n_wstrb_host_addr_2 [14] =		desc_14_wstrb_host_addr_2_reg ;
   assign  desc_n_wstrb_host_addr_3 [14] =		desc_14_wstrb_host_addr_3_reg ;
   assign  desc_n_wstrb_host_addr_0 [15] =		desc_15_wstrb_host_addr_0_reg ;
   assign  desc_n_wstrb_host_addr_1 [15] =		desc_15_wstrb_host_addr_1_reg ;
   assign  desc_n_wstrb_host_addr_2 [15] =		desc_15_wstrb_host_addr_2_reg ;
   assign  desc_n_wstrb_host_addr_3 [15] =		desc_15_wstrb_host_addr_3_reg ;


   assign desc_n_wstrb_control[0]= desc_0_txn_type_reg[1];
   assign desc_n_wstrb_control[1]= desc_1_txn_type_reg[1];
   assign desc_n_wstrb_control[2]= desc_2_txn_type_reg[1];
   assign desc_n_wstrb_control[3]= desc_3_txn_type_reg[1];
   assign desc_n_wstrb_control[4]= desc_4_txn_type_reg[1];
   assign desc_n_wstrb_control[5]= desc_5_txn_type_reg[1];
   assign desc_n_wstrb_control[6]= desc_6_txn_type_reg[1];
   assign desc_n_wstrb_control[7]= desc_7_txn_type_reg[1];
   assign desc_n_wstrb_control[8]= desc_8_txn_type_reg[1];
   assign desc_n_wstrb_control[9]= desc_9_txn_type_reg[1];
   assign desc_n_wstrb_control[10]= desc_10_txn_type_reg[1];
   assign desc_n_wstrb_control[11]= desc_11_txn_type_reg[1];
   assign desc_n_wstrb_control[12]= desc_12_txn_type_reg[1];
   assign desc_n_wstrb_control[13]= desc_13_txn_type_reg[1];
   assign desc_n_wstrb_control[14]= desc_14_txn_type_reg[1];
   assign desc_n_wstrb_control[15]= desc_15_txn_type_reg[1];


   assign desc_n_txn_type[0]= desc_0_txn_type_reg[0];
   assign desc_n_txn_type[1]= desc_1_txn_type_reg[0];
   assign desc_n_txn_type[2]= desc_2_txn_type_reg[0];
   assign desc_n_txn_type[3]= desc_3_txn_type_reg[0];
   assign desc_n_txn_type[4]= desc_4_txn_type_reg[0];
   assign desc_n_txn_type[5]= desc_5_txn_type_reg[0];
   assign desc_n_txn_type[6]= desc_6_txn_type_reg[0];
   assign desc_n_txn_type[7]= desc_7_txn_type_reg[0];
   assign desc_n_txn_type[8]= desc_8_txn_type_reg[0];
   assign desc_n_txn_type[9]= desc_9_txn_type_reg[0];
   assign desc_n_txn_type[10]= desc_10_txn_type_reg[0];
   assign desc_n_txn_type[11]= desc_11_txn_type_reg[0];
   assign desc_n_txn_type[12]= desc_12_txn_type_reg[0];
   assign desc_n_txn_type[13]= desc_13_txn_type_reg[0];
   assign desc_n_txn_type[14]= desc_14_txn_type_reg[0];
   assign desc_n_txn_type[15]= desc_15_txn_type_reg[0];

   
   
   //    Floping ownership done from HM to 
   //	Indicate that HM has completed transfer 
   //	and assert done 
   

   always@(posedge axi_aclk) begin
	  uc2rb_ownership_reg_ff<=uc2rb_ownership_reg;
   end

   assign hm_txn_done=uc2rb_ownership_reg_ff[MAX_DESC-1:0] & ~uc2rb_ownership_reg[MAX_DESC-1:0];

   ///////////////////////////////////////////////////
   //
   // Read Data Packing Unpacking
   //
   ///////////////////////////////////////////////////
   
   
   // When DUT Data width is < 128, the wstrb/data comes in chunks to HM, so we
   // Need to wait and gather all data/wstrb and represent to HM as if it was single chunk
   
   assign rb_packed_data_64= (S_AXI_USR_DATA_WIDTH==64) ? {rb_unpacked_data_0,rb_unpacked_data_1} : 0;
   assign rb_packed_data_32= (S_AXI_USR_DATA_WIDTH==32) ? {rb_unpacked_data_0,rb_unpacked_data_1,rb_unpacked_data_2,rb_unpacked_data_3} : 0;
   
   assign rb2hm_packed_data= ~wstrb_fetch_in_prog[uc2rb_rd_addr_desc_id] ? 
							 (
							  (S_AXI_USR_DATA_WIDTH==128) ? rb2hm_rd_dout :
							  ((S_AXI_USR_DATA_WIDTH==64)? rb_packed_data_64 : rb_packed_data_32) 
							  ) :
							 ( ( EXTEND_WSTRB ) ? rb_packed_wstrb_extended : rb_packed_wstrb  )
							   ;

   // For extended WSTRB
   
   assign rb_packed_wstrb_extended =	    { { {8{rb_packed_wstrb[99]}}, {8{rb_packed_wstrb[98]}} , {8{rb_packed_wstrb[97]}} , {8{rb_packed_wstrb[96]}} } 
											 , { {8{rb_packed_wstrb[67]}}, {8{rb_packed_wstrb[66]}} , {8{rb_packed_wstrb[65]}} , {8{rb_packed_wstrb[64]}} }
											 , { {8{rb_packed_wstrb[35]}}, {8{rb_packed_wstrb[34]}} , {8{rb_packed_wstrb[33]}} , {8{rb_packed_wstrb[32]}} }
											 , { {8{rb_packed_wstrb[3]}}, {8{rb_packed_wstrb[2]}} , {8{rb_packed_wstrb[1]}} , {8{rb_packed_wstrb[0]}} }
											  };
   
   


   assign rb_packed_wstrb =	 ( (S_AXI_USR_DATA_WIDTH==128) ? 
							   {28'h0,rb2hm_rd_wstrb[15:12],28'h0,rb2hm_rd_wstrb[11:8],28'h0,rb2hm_rd_wstrb[7:4],28'h0,rb2hm_rd_wstrb[3:0]} :
							   ((S_AXI_USR_DATA_WIDTH==64)? 
								{28'h0,rb_packed_wstrb_64[15:12],28'h0,rb_packed_wstrb_64[11:8],28'h0,rb_packed_wstrb_64[7:4],28'h0,rb_packed_wstrb_64[3:0]} : 
								{28'h0,rb_packed_wstrb_32[15:12],28'h0,rb_packed_wstrb_32[11:8],28'h0,rb_packed_wstrb_32[7:4],28'h0,rb_packed_wstrb_32[3:0]}) 
							   );

										 
   
   always@(posedge axi_aclk) begin
	  if(~axi_aresetn) begin
		 rb_unpacked_data_0<=0;
		 rb_unpacked_data_1<=0;
 		 rb_unpacked_data_2<=0;
		 rb_unpacked_data_3<=0;
	  end
	  else begin
		 if(S_AXI_USR_DATA_WIDTH==64) begin
			rb_unpacked_data_0<= rb2hm_rd_dout;
			rb_unpacked_data_1<=rb_unpacked_data_0;
		 end
		 else if(S_AXI_USR_DATA_WIDTH==32) begin
			rb_unpacked_data_0<=rb2hm_rd_dout;
			rb_unpacked_data_1<=rb_unpacked_data_0;
			rb_unpacked_data_2<=rb_unpacked_data_1;
			rb_unpacked_data_3<=rb_unpacked_data_2;
		 end
	  end 
   end 





   // Packing unpacking of wstrb
   assign rb_packed_wstrb_64= (S_AXI_USR_DATA_WIDTH==64) ? {rb_unpacked_wstrb_0,rb_unpacked_wstrb_1} : 0;
   assign rb_packed_wstrb_32= (S_AXI_USR_DATA_WIDTH==32) ? {rb_unpacked_wstrb_0,rb_unpacked_wstrb_1,rb_unpacked_wstrb_2,rb_unpacked_wstrb_3} : 0;

  

   always@(posedge axi_aclk) begin
	  if(~axi_aresetn) begin
		 rb_unpacked_wstrb_0<=0;
		 rb_unpacked_wstrb_1<=0;
 		 rb_unpacked_wstrb_2<=0;
		 rb_unpacked_wstrb_3<=0;
	  end
	  else begin
		 if(S_AXI_USR_DATA_WIDTH==64) begin
			rb_unpacked_wstrb_0<= rb2hm_rd_wstrb;
			rb_unpacked_wstrb_1<=rb_unpacked_wstrb_0;
		 end
		 else if(S_AXI_USR_DATA_WIDTH==32) begin
			rb_unpacked_wstrb_0<=rb2hm_rd_wstrb;
			rb_unpacked_wstrb_1<=rb_unpacked_wstrb_0;
			rb_unpacked_wstrb_2<=rb_unpacked_wstrb_1;
			rb_unpacked_wstrb_3<=rb_unpacked_wstrb_2;
		 end
	  end
   end 
   
	  
   

   // To select if i need to trigger 2 times, (If WSTRB is also need to be fetched ) 
   parameter HM_IDLE=2'b00,
			   HM_WAIT_FOR_WDATA_DONE=2'b01, 
			   HM_CHECK_WSTRB =2'b10,
			   HM_FETCH_WSTRB=2'b11;
   always@(posedge axi_aclk) begin
	  for(k=0;k<MAX_DESC;k=k+1) begin:hm_txn_control
		 if(~axi_aresetn) begin
			hm_fetch_state[k]<=0;		
			hm2uc_done[k]<=0;	
			hm_txn_start[k]<=0;
			wstrb_fetch_in_prog[k]<=0;
		 end
		 else begin
			case(hm_fetch_state[k])
			  HM_IDLE:
				//If UM/US is giving trigger start txn
				if(uc2hm_trig[k]) begin
				   hm_txn_start[k]<=1;
				   hm2uc_done[k]<=0;	
				   wstrb_fetch_in_prog[k]<=0;
				   desc_n_axaddr_0_reg[k]<=desc_n_data_host_addr_0[k];
				   desc_n_axaddr_1_reg[k]<=desc_n_data_host_addr_1[k];
				   desc_n_axaddr_2_reg[k]<=desc_n_data_host_addr_2[k];
				   desc_n_axaddr_3_reg[k]<=desc_n_data_host_addr_3[k];
				   hm_fetch_state[k]<=HM_WAIT_FOR_WDATA_DONE;
				end
				else begin
				   hm_txn_start[k]<=0;
				   hm2uc_done[k]<=0;	
				   wstrb_fetch_in_prog[k]<=0;
				   desc_n_axaddr_0_reg[k]<=desc_n_data_host_addr_0[k];
				   desc_n_axaddr_1_reg[k]<=desc_n_data_host_addr_1[k];
				   desc_n_axaddr_2_reg[k]<=desc_n_data_host_addr_2[k];
				   desc_n_axaddr_3_reg[k]<=desc_n_data_host_addr_3[k];
				   hm_fetch_state[k]<=HM_IDLE;

				end

			  HM_WAIT_FOR_WDATA_DONE:
				if(hm_txn_done[k]) begin
				   hm_txn_start[k]<=0;
				   hm2uc_done[k]<=0;	
				   wstrb_fetch_in_prog[k]<=0;
				   desc_n_axaddr_0_reg[k]<=desc_n_data_host_addr_0[k];
				   desc_n_axaddr_1_reg[k]<=desc_n_data_host_addr_1[k];
				   desc_n_axaddr_2_reg[k]<=desc_n_data_host_addr_2[k];
				   desc_n_axaddr_3_reg[k]<=desc_n_data_host_addr_3[k];
				   hm_fetch_state[k]<=HM_CHECK_WSTRB;
				end
				else begin
				   hm_txn_start[k]<=0;
				   hm2uc_done[k]<=0;	
				   wstrb_fetch_in_prog[k]<=0;
				   desc_n_axaddr_0_reg[k]<=desc_n_data_host_addr_0[k];
				   desc_n_axaddr_1_reg[k]<=desc_n_data_host_addr_1[k];
				   desc_n_axaddr_2_reg[k]<=desc_n_data_host_addr_2[k];
				   desc_n_axaddr_3_reg[k]<=desc_n_data_host_addr_3[k];
				   hm_fetch_state[k]<=HM_WAIT_FOR_WDATA_DONE;
				end
			  HM_CHECK_WSTRB:
				//Check if txn is done or not. If done & The txn was 
				//having constatn WSTRB, ignore and wait for next trigger
				//if(~desc_n_wstrb_control[k]) begin
				if(desc_n_txn_type[k]) begin
				   hm_txn_start[k]<=0;
				   hm2uc_done[k]<=1;
				   wstrb_fetch_in_prog[k]<=0;
				   desc_n_axaddr_0_reg[k]<=desc_n_data_host_addr_0[k];
				   desc_n_axaddr_1_reg[k]<=desc_n_data_host_addr_1[k];
				   desc_n_axaddr_2_reg[k]<=desc_n_data_host_addr_2[k];
				   desc_n_axaddr_3_reg[k]<=desc_n_data_host_addr_3[k];
				   hm_fetch_state[k]<=HM_IDLE;
				end
			  //If done and txn was having variable WSTRB, trigger next
			  //Txn and WSTRB Host Address
				else begin
				   hm_txn_start[k]<=1;
				   hm2uc_done[k]<=0;	
				   wstrb_fetch_in_prog[k]<=1;
				   desc_n_axaddr_0_reg[k]<=desc_n_wstrb_host_addr_0[k];
				   desc_n_axaddr_1_reg[k]<=desc_n_wstrb_host_addr_1[k];
				   desc_n_axaddr_2_reg[k]<=desc_n_wstrb_host_addr_2[k];
				   desc_n_axaddr_3_reg[k]<=desc_n_wstrb_host_addr_3[k];
				   hm_fetch_state[k]<=HM_FETCH_WSTRB;
				end
			  
			  HM_FETCH_WSTRB:
				if(hm_txn_done[k]) begin
				   hm_txn_start[k]<=0;
				   hm2uc_done[k]<=1;
				   wstrb_fetch_in_prog[k]<=0;
				   desc_n_axaddr_0_reg[k]<=desc_n_wstrb_host_addr_0[k];
				   desc_n_axaddr_1_reg[k]<=desc_n_wstrb_host_addr_1[k];
				   desc_n_axaddr_2_reg[k]<=desc_n_wstrb_host_addr_2[k];
				   desc_n_axaddr_3_reg[k]<=desc_n_wstrb_host_addr_3[k];
				   hm_fetch_state[k]<=HM_IDLE;
				end	
				else begin
				   hm_txn_start[k]<=0;
				   wstrb_fetch_in_prog[k]<=1;
				   hm2uc_done[k]<=0;
				   desc_n_axaddr_0_reg[k]<=desc_n_wstrb_host_addr_0[k];
				   desc_n_axaddr_1_reg[k]<=desc_n_wstrb_host_addr_1[k];
				   desc_n_axaddr_2_reg[k]<=desc_n_wstrb_host_addr_2[k];
				   desc_n_axaddr_3_reg[k]<=desc_n_wstrb_host_addr_3[k];
				   hm_fetch_state[k]<=HM_FETCH_WSTRB;
				end 
			endcase 
		 end 
	  end 
   end 
   
				


   assign desc_0_txn_type_hm_reg  = {31'h0, desc_0_txn_type_reg[0]}; 
   assign desc_1_txn_type_hm_reg  = {31'h0, desc_1_txn_type_reg[0]}; 
   assign desc_2_txn_type_hm_reg  = {31'h0, desc_2_txn_type_reg[0]}; 
   assign desc_3_txn_type_hm_reg  = {31'h0, desc_3_txn_type_reg[0]}; 
   assign desc_4_txn_type_hm_reg  = {31'h0, desc_4_txn_type_reg[0]}; 
   assign desc_5_txn_type_hm_reg  = {31'h0, desc_5_txn_type_reg[0]}; 
   assign desc_6_txn_type_hm_reg  = {31'h0, desc_6_txn_type_reg[0]}; 
   assign desc_7_txn_type_hm_reg  = {31'h0, desc_7_txn_type_reg[0]}; 
   assign desc_8_txn_type_hm_reg  = {31'h0, desc_8_txn_type_reg[0]}; 
   assign desc_9_txn_type_hm_reg  = {31'h0, desc_9_txn_type_reg[0]}; 
   assign desc_10_txn_type_hm_reg = {31'h0, desc_10_txn_type_reg[0]}; 
   assign desc_11_txn_type_hm_reg = {31'h0, desc_11_txn_type_reg[0]}; 
   assign desc_12_txn_type_hm_reg = {31'h0, desc_12_txn_type_reg[0]}; 
   assign desc_13_txn_type_hm_reg = {31'h0, desc_13_txn_type_reg[0]}; 
   assign desc_14_txn_type_hm_reg = {31'h0, desc_14_txn_type_reg[0]}; 
   assign desc_15_txn_type_hm_reg = {31'h0, desc_15_txn_type_reg[0]}; 



   always@(posedge axi_aclk) begin
	  if(~axi_aresetn) begin
		 hm2rb_wr_128_we_ff  <=0 ;
		 hm2rb_wr_128_we_ff1 <=0 ;
		 hm2rb_wr_128_we_ff2 <=0 ;
		 hm2rb_wr_128_bwe_ff <=0 ;
		 hm2rb_wr_128_bwe_ff1<=0 ;
		 hm2rb_wr_128_bwe_ff2<=0 ;
	  end
	  else begin
		 hm2rb_wr_128_we_ff<=hm2rb_wr_128_we;
		 hm2rb_wr_128_we_ff1<=hm2rb_wr_128_we_ff;
		 hm2rb_wr_128_we_ff2<=hm2rb_wr_128_we_ff1;
		 hm2rb_wr_128_bwe_ff<= hm2rb_wr_128_bwe;
		 hm2rb_wr_128_bwe_ff1<=hm2rb_wr_128_bwe_ff;
		 hm2rb_wr_128_bwe_ff2<=hm2rb_wr_128_bwe_ff1;
	  end
   end
   


   assign shift_wr_addr = (S_AXI_USR_DATA_WIDTH==64)? 1 : 2;
   
   
   always@( posedge axi_aclk) begin
	  if(S_AXI_USR_DATA_WIDTH<128) begin
		 if(~axi_aresetn) begin
			hm2rb_wr_packed_we<=0;
			hm2rb_wr_packed_bwe<=0;
			hm2rb_wr_packed_data<=0;
			hm2rb_wr_packed_addr<=0;
		 end
		 else if(hm2rb_wr_128_we) begin
			hm2rb_wr_packed_we <= hm2rb_wr_128_we ;
			hm2rb_wr_packed_bwe<= hm2rb_wr_128_bwe[(S_AXI_USR_DATA_WIDTH/8)-1:0];
			hm2rb_wr_packed_addr<= (hm2rb_wr_128_addr) ;
			hm2rb_wr_packed_data<= hm2rb_wr_128_data[(S_AXI_USR_DATA_WIDTH)-1:0];
		 end
		 else if(hm2rb_wr_128_we_ff) begin
	 		hm2rb_wr_packed_we <=  hm2rb_wr_128_we_ff;
			hm2rb_wr_packed_bwe<=  hm2rb_wr_128_bwe_ff[(2*(S_AXI_USR_DATA_WIDTH/8))-1:(S_AXI_USR_DATA_WIDTH/8)];
			hm2rb_wr_packed_addr<= (hm2rb_wr_128_addr) + 1;
			hm2rb_wr_packed_data<= hm2rb_wr_128_data[(2*S_AXI_USR_DATA_WIDTH)-1:S_AXI_USR_DATA_WIDTH];
		 end
		 else if(hm2rb_wr_128_we_ff1 && (S_AXI_USR_DATA_WIDTH==32) ) begin
			hm2rb_wr_packed_we <=  hm2rb_wr_128_we_ff1;
			hm2rb_wr_packed_bwe<=  hm2rb_wr_128_bwe_ff1[(3*(S_AXI_USR_DATA_WIDTH/8))-1:(2*(S_AXI_USR_DATA_WIDTH/8))];
			hm2rb_wr_packed_addr<= (hm2rb_wr_128_addr) + 2; 
			hm2rb_wr_packed_data<= hm2rb_wr_128_data[(3*S_AXI_USR_DATA_WIDTH)-1:(2*S_AXI_USR_DATA_WIDTH)];
		 end
		 else if(hm2rb_wr_128_we_ff2 && (S_AXI_USR_DATA_WIDTH==32) ) begin
			hm2rb_wr_packed_we <=  hm2rb_wr_128_we_ff2;
			hm2rb_wr_packed_bwe<=  hm2rb_wr_128_bwe_ff2[(4*(S_AXI_USR_DATA_WIDTH/8))-1:(3*(S_AXI_USR_DATA_WIDTH/8))];
			hm2rb_wr_packed_addr<= (hm2rb_wr_128_addr) + 3;
			hm2rb_wr_packed_data<= hm2rb_wr_128_data[(4*S_AXI_USR_DATA_WIDTH)-1:(3*S_AXI_USR_DATA_WIDTH)];
		 end
		 else begin
 			hm2rb_wr_packed_we<=0;
			hm2rb_wr_packed_bwe<=0;
			hm2rb_wr_packed_data<=0;
			hm2rb_wr_packed_addr<=0;
		 end
	  end 
   end 
   
 
   assign hm2rb_wr_we= (S_AXI_USR_DATA_WIDTH==128) ? hm2rb_wr_128_we : hm2rb_wr_packed_we;
   assign hm2rb_wr_bwe= (S_AXI_USR_DATA_WIDTH==128) ? hm2rb_wr_128_bwe : hm2rb_wr_packed_bwe;
   assign hm2rb_wr_data_in= (S_AXI_USR_DATA_WIDTH==128) ? hm2rb_wr_128_data : hm2rb_wr_packed_data;
   assign hm2rb_wr_addr= (S_AXI_USR_DATA_WIDTH==128) ? hm2rb_wr_128_addr : hm2rb_wr_packed_addr;
   assign hm2rb_wr_wstrb_in = (S_AXI_USR_DATA_WIDTH==128) ? hm2rb_wr_128_data : hm2rb_wr_packed_data;
   
   axi_master_control 
	 #(
	   .M_AXI_USR_ADDR_WIDTH (M_AXI_ADDR_WIDTH), 
       .M_AXI_USR_DATA_WIDTH (M_AXI_DATA_WIDTH), 
       .M_AXI_USR_ID_WIDTH   (M_AXI_ID_WIDTH  ), 
       .M_AXI_USR_AWUSER_WIDTH (M_AXI_USER_WIDTH),
	   .M_AXI_USR_ARUSER_WIDTH (M_AXI_USER_WIDTH),
	   .M_AXI_USR_WUSER_WIDTH (M_AXI_USER_WIDTH),
	   .M_AXI_USR_RUSER_WIDTH (M_AXI_USER_WIDTH),
	   .M_AXI_USR_BUSER_WIDTH (M_AXI_USER_WIDTH),
	   .M_AXI_USR_LEN_WIDTH  (8), // always AXI4
	   .RTL_USE_MODE		       (1),
	   .UC_AXI_DATA_WIDTH (S_AXI_USR_DATA_WIDTH)
	   )
   axi_master_control_inst_host
	 (/*AUTO*INST*/
	  // Outputs
	  .uc2rb_rd_addr  (hm2rb_rd_addr),
	  .uc2rb_wr_we    (hm2rb_wr_128_we),
	  .uc2rb_wr_bwe   (hm2rb_wr_128_bwe),
	  .uc2rb_wr_addr  (hm2rb_wr_128_addr),
	  .uc2rb_wr_data  (hm2rb_wr_128_data),
	  .uc2rb_intr_error_status_reg(hm2rb_intr_error_status_reg[31:0]),
	  .uc2rb_ownership_reg( uc2rb_ownership_reg ),
      .uc2rb_intr_comp_status_reg( ),
      .uc2rb_status_resp_reg( ),
      .uc2rb_intr_error_status_reg_we (hm2rb_intr_error_status_reg_we[31:0]),
      .uc2rb_ownership_reg_we ( ),
      .uc2rb_intr_comp_status_reg_we ( ),
      .uc2rb_status_resp_reg_we ( ),

	  .uc2rb_wr_desc_id ( uc2rb_wr_desc_id ),
	  .uc2rb_rd_addr_desc_id ( uc2rb_rd_addr_desc_id),
      // Inputs
      .axi_aclk       (axi_aclk),
      .axi_aresetn    (axi_aresetn),
      .rb2uc_rd_data  (rb2hm_packed_data),
      .rb2uc_rd_wstrb (16'hFFFF),	//WSTRB will always be 16'hFFFF
      .hm2uc_done     ( 16'h0 ),  
      .version_reg    ( version_reg ),  
      .bridge_type_reg( bridge_type_reg ),  
      .mode_select_reg( 32'h0 ), // User Master RTL as HM will always operate in Mode0
      .reset_reg      ( 32'h0  ), 
      .intr_h2c_0_reg ( 32'h0  ), 
      .intr_h2c_1_reg ( 32'h0  ), 
      .intr_c2h_0_status_reg( 32'h0 ), 
      .intr_c2h_1_status_reg( 32'h0 ), 
      .c2h_gpio_0_status_reg( 32'h0 ), 
      .c2h_gpio_1_status_reg( 32'h0 ), 
      .c2h_gpio_2_status_reg( 32'h0 ), 
      .c2h_gpio_3_status_reg( 32'h0 ), 
      .c2h_gpio_4_status_reg( 32'h0 ), 
      .c2h_gpio_5_status_reg( 32'h0 ), 
      .c2h_gpio_6_status_reg( 32'h0 ), 
      .c2h_gpio_7_status_reg( 32'h0 ), 
      .c2h_gpio_8_status_reg( 32'h0 ), 
      .c2h_gpio_9_status_reg( 32'h0 ), 
      .c2h_gpio_10_status_reg( 32'h0 ), 
      .c2h_gpio_11_status_reg( 32'h0 ), 
      .c2h_gpio_12_status_reg( 32'h0 ), 
      .c2h_gpio_13_status_reg( 32'h0 ), 
      .c2h_gpio_14_status_reg( 32'h0 ), 
      .c2h_gpio_15_status_reg( 32'h0 ), 
      .axi_bridge_config_reg( ), 
      .axi_max_desc_reg(axi_max_desc_reg),
      .intr_status_reg( 32'h0 ), 
      .intr_error_status_reg( rb2hm_intr_error_status_reg),
      .intr_error_clear_reg( rb2hm_intr_error_clear_reg),
      .intr_error_enable_reg( 32'h0 ),
      .ownership_reg  ( 32'h0 ),  
      .ownership_flip_reg(hm_txn_start),
      .status_resp_reg( 32'h0 ),
      .intr_comp_status_reg( 32'h0 ),
      .intr_comp_clear_reg(  32'h0 ),
      .intr_comp_enable_reg( 32'h0 ),
      .desc_0_txn_type_reg(desc_0_txn_type_hm_reg),
      .desc_0_size_reg(desc_0_size_reg[31:0]),
      .desc_0_data_offset_reg(desc_0_data_offset_reg[31:0]),
      .desc_0_data_host_addr_0_reg(32'h0 ), 
      .desc_0_data_host_addr_1_reg(32'h0 ), 
      .desc_0_data_host_addr_2_reg(32'h0 ), 
      .desc_0_data_host_addr_3_reg(32'h0 ), 
      .desc_0_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_0_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_0_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_0_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_0_axsize_reg(32'h4),
      .desc_0_attr_reg(32'h1),
      .desc_0_axaddr_0_reg(desc_n_axaddr_0_reg[0]),
      .desc_0_axaddr_1_reg(desc_n_axaddr_1_reg[0]),
      .desc_0_axaddr_2_reg(desc_n_axaddr_2_reg[0]),
      .desc_0_axaddr_3_reg(desc_n_axaddr_3_reg[0]),
      .desc_0_axid_0_reg( 32'h0 ), 
      .desc_0_axid_1_reg( 32'h0 ), 
      .desc_0_axid_2_reg( 32'h0 ), 
      .desc_0_axid_3_reg( 32'h0 ), 
      .desc_0_axuser_0_reg(32'h0 ),  
      .desc_0_axuser_1_reg(32'h0 ),  
      .desc_0_axuser_2_reg(32'h0 ),  
      .desc_0_axuser_3_reg(32'h0 ),  
      .desc_0_axuser_4_reg(32'h0 ),  
      .desc_0_axuser_5_reg(32'h0 ),  
      .desc_0_axuser_6_reg(32'h0 ),  
      .desc_0_axuser_7_reg(32'h0 ),  
      .desc_0_axuser_8_reg(32'h0 ),  
      .desc_0_axuser_9_reg(32'h0 ),  
      .desc_0_axuser_10_reg(32'h0 ), 
      .desc_0_axuser_11_reg(32'h0 ), 
      .desc_0_axuser_12_reg(32'h0 ), 
      .desc_0_axuser_13_reg(32'h0 ), 
      .desc_0_axuser_14_reg(32'h0 ), 
      .desc_0_axuser_15_reg(32'h0 ), 
      .desc_0_xuser_0_reg(32'h0 ), 
      .desc_0_xuser_1_reg(32'h0 ), 
      .desc_0_xuser_2_reg(32'h0 ), 
      .desc_0_xuser_3_reg(32'h0 ), 
      .desc_0_xuser_4_reg(32'h0 ), 
      .desc_0_xuser_5_reg(32'h0 ), 
      .desc_0_xuser_6_reg(32'h0 ), 
      .desc_0_xuser_7_reg(32'h0 ), 
      .desc_0_xuser_8_reg(32'h0 ), 
      .desc_0_xuser_9_reg(32'h0 ), 
      .desc_0_xuser_10_reg(32'h0 ), 
      .desc_0_xuser_11_reg(32'h0 ), 
      .desc_0_xuser_12_reg(32'h0 ), 
      .desc_0_xuser_13_reg(32'h0 ), 
      .desc_0_xuser_14_reg(32'h0 ), 
      .desc_0_xuser_15_reg(32'h0 ), 
      .desc_0_wuser_0_reg(32'h0 ), 
      .desc_0_wuser_1_reg(32'h0 ), 
      .desc_0_wuser_2_reg(32'h0 ), 
      .desc_0_wuser_3_reg(32'h0 ), 
      .desc_0_wuser_4_reg(32'h0 ), 
      .desc_0_wuser_5_reg(32'h0 ), 
      .desc_0_wuser_6_reg(32'h0 ), 
      .desc_0_wuser_7_reg(32'h0 ), 
      .desc_0_wuser_8_reg(32'h0 ), 
      .desc_0_wuser_9_reg(32'h0 ), 
      .desc_0_wuser_10_reg(32'h0 ), 
      .desc_0_wuser_11_reg(32'h0 ), 
      .desc_0_wuser_12_reg(32'h0 ), 
      .desc_0_wuser_13_reg(32'h0 ), 
      .desc_0_wuser_14_reg(32'h0 ), 
      .desc_0_wuser_15_reg(32'h0 ), 
      .desc_1_txn_type_reg(desc_1_txn_type_hm_reg ),
      .desc_1_size_reg(desc_1_size_reg[31:0]),
      .desc_1_data_offset_reg(desc_1_data_offset_reg[31:0]),
      .desc_1_data_host_addr_0_reg(32'h0 ), 
      .desc_1_data_host_addr_1_reg(32'h0 ), 
      .desc_1_data_host_addr_2_reg(32'h0 ), 
      .desc_1_data_host_addr_3_reg(32'h0 ), 
      .desc_1_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_1_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_1_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_1_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_1_axsize_reg(32'h4),
      .desc_1_attr_reg(32'h1),
      .desc_1_axaddr_0_reg(desc_n_axaddr_0_reg[1]),
      .desc_1_axaddr_1_reg(desc_n_axaddr_1_reg[1]),
      .desc_1_axaddr_2_reg(desc_n_axaddr_2_reg[1]),
      .desc_1_axaddr_3_reg(desc_n_axaddr_3_reg[1]),
      .desc_1_axid_0_reg( 32'h1),
      .desc_1_axid_1_reg( 32'h0),
      .desc_1_axid_2_reg( 32'h0),
      .desc_1_axid_3_reg( 32'h0),
      .desc_1_axuser_0_reg(32'h0 ),
      .desc_1_axuser_1_reg(32'h0 ),
      .desc_1_axuser_2_reg(32'h0 ),
      .desc_1_axuser_3_reg(32'h0 ),
      .desc_1_axuser_4_reg(32'h0 ),
      .desc_1_axuser_5_reg(32'h0 ),
      .desc_1_axuser_6_reg(32'h0 ),
      .desc_1_axuser_7_reg(32'h0 ),
      .desc_1_axuser_8_reg(32'h0 ),
      .desc_1_axuser_9_reg(32'h0 ),
      .desc_1_axuser_10_reg(32'h0 ),
      .desc_1_axuser_11_reg(32'h0 ),
      .desc_1_axuser_12_reg(32'h0 ),
      .desc_1_axuser_13_reg(32'h0 ),
      .desc_1_axuser_14_reg(32'h0 ),
      .desc_1_axuser_15_reg(32'h0 ),
      .desc_1_xuser_0_reg(32'h0 ),
      .desc_1_xuser_1_reg(32'h0 ),
      .desc_1_xuser_2_reg(32'h0 ),
      .desc_1_xuser_3_reg(32'h0 ),
      .desc_1_xuser_4_reg(32'h0 ),
      .desc_1_xuser_5_reg(32'h0 ),
      .desc_1_xuser_6_reg(32'h0 ),
      .desc_1_xuser_7_reg(32'h0 ),
      .desc_1_xuser_8_reg(32'h0 ),
      .desc_1_xuser_9_reg(32'h0 ),
      .desc_1_xuser_10_reg(32'h0 ),
      .desc_1_xuser_11_reg(32'h0 ),
      .desc_1_xuser_12_reg(32'h0 ),
      .desc_1_xuser_13_reg(32'h0 ),
      .desc_1_xuser_14_reg(32'h0 ),
      .desc_1_xuser_15_reg(32'h0 ),
      .desc_1_wuser_0_reg(32'h0 ),
      .desc_1_wuser_1_reg(32'h0 ),
      .desc_1_wuser_2_reg(32'h0 ),
      .desc_1_wuser_3_reg(32'h0 ),
      .desc_1_wuser_4_reg(32'h0 ),
      .desc_1_wuser_5_reg(32'h0 ),
      .desc_1_wuser_6_reg(32'h0 ),
      .desc_1_wuser_7_reg(32'h0 ),
      .desc_1_wuser_8_reg(32'h0 ),
      .desc_1_wuser_9_reg(32'h0 ),
      .desc_1_wuser_10_reg(32'h0 ),
      .desc_1_wuser_11_reg(32'h0 ),
      .desc_1_wuser_12_reg(32'h0 ),
      .desc_1_wuser_13_reg(32'h0 ),
      .desc_1_wuser_14_reg(32'h0 ),
      .desc_1_wuser_15_reg(32'h0 ),
      .desc_2_txn_type_reg(desc_2_txn_type_hm_reg),
      .desc_2_size_reg(desc_2_size_reg[31:0]),
      .desc_2_data_offset_reg(desc_2_data_offset_reg[31:0]),
      .desc_2_data_host_addr_0_reg(32'h0 ), 
      .desc_2_data_host_addr_1_reg(32'h0 ), 
      .desc_2_data_host_addr_2_reg(32'h0 ), 
      .desc_2_data_host_addr_3_reg(32'h0 ), 
      .desc_2_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_2_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_2_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_2_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_2_axsize_reg(32'h4),
      .desc_2_attr_reg(32'h1),
      .desc_2_axaddr_0_reg(desc_n_axaddr_0_reg[2]),
      .desc_2_axaddr_1_reg(desc_n_axaddr_1_reg[2]),
      .desc_2_axaddr_2_reg(desc_n_axaddr_2_reg[2]),
      .desc_2_axaddr_3_reg(desc_n_axaddr_3_reg[2]),
      .desc_2_axid_0_reg(32'h2),
      .desc_2_axid_1_reg(32'h0),
      .desc_2_axid_2_reg(32'h0),
      .desc_2_axid_3_reg(32'h0),
      .desc_2_axuser_0_reg(32'h0 ),
      .desc_2_axuser_1_reg(32'h0 ),
      .desc_2_axuser_2_reg(32'h0 ),
      .desc_2_axuser_3_reg(32'h0 ),
      .desc_2_axuser_4_reg(32'h0 ),
      .desc_2_axuser_5_reg(32'h0 ),
      .desc_2_axuser_6_reg(32'h0 ),
      .desc_2_axuser_7_reg(32'h0 ),
      .desc_2_axuser_8_reg(32'h0 ),
      .desc_2_axuser_9_reg(32'h0 ),
      .desc_2_axuser_10_reg(32'h0 ),
      .desc_2_axuser_11_reg(32'h0 ),
      .desc_2_axuser_12_reg(32'h0 ),
      .desc_2_axuser_13_reg(32'h0 ),
      .desc_2_axuser_14_reg(32'h0 ),
      .desc_2_axuser_15_reg(32'h0 ),
      .desc_2_xuser_0_reg(32'h0 ),
      .desc_2_xuser_1_reg(32'h0 ),
      .desc_2_xuser_2_reg(32'h0 ),
      .desc_2_xuser_3_reg(32'h0 ),
      .desc_2_xuser_4_reg(32'h0 ),
      .desc_2_xuser_5_reg(32'h0 ),
      .desc_2_xuser_6_reg(32'h0 ),
      .desc_2_xuser_7_reg(32'h0 ),
      .desc_2_xuser_8_reg(32'h0 ),
      .desc_2_xuser_9_reg(32'h0 ),
      .desc_2_xuser_10_reg(32'h0 ),
      .desc_2_xuser_11_reg(32'h0 ),
      .desc_2_xuser_12_reg(32'h0 ),
      .desc_2_xuser_13_reg(32'h0 ),
      .desc_2_xuser_14_reg(32'h0 ),
      .desc_2_xuser_15_reg(32'h0 ),
      .desc_2_wuser_0_reg(32'h0 ),
      .desc_2_wuser_1_reg(32'h0 ),
      .desc_2_wuser_2_reg(32'h0 ),
      .desc_2_wuser_3_reg(32'h0 ),
      .desc_2_wuser_4_reg(32'h0 ),
      .desc_2_wuser_5_reg(32'h0 ),
      .desc_2_wuser_6_reg(32'h0 ),
      .desc_2_wuser_7_reg(32'h0 ),
      .desc_2_wuser_8_reg(32'h0 ),
      .desc_2_wuser_9_reg(32'h0 ),
      .desc_2_wuser_10_reg(32'h0 ),
      .desc_2_wuser_11_reg(32'h0 ),
      .desc_2_wuser_12_reg(32'h0 ),
      .desc_2_wuser_13_reg(32'h0 ),
      .desc_2_wuser_14_reg(32'h0 ),
      .desc_2_wuser_15_reg(32'h0 ),

      .desc_3_txn_type_reg(desc_3_txn_type_hm_reg),
      .desc_3_size_reg(desc_3_size_reg[31:0]),
      .desc_3_data_offset_reg(desc_3_data_offset_reg[31:0]),
      .desc_3_data_host_addr_0_reg(32'h0 ), 
      .desc_3_data_host_addr_1_reg(32'h0 ), 
      .desc_3_data_host_addr_2_reg(32'h0 ), 
      .desc_3_data_host_addr_3_reg(32'h0 ), 
      .desc_3_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_3_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_3_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_3_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_3_axsize_reg(32'h4),
      .desc_3_attr_reg(32'h1),
      .desc_3_axaddr_0_reg(desc_n_axaddr_0_reg[3]),
      .desc_3_axaddr_1_reg(desc_n_axaddr_1_reg[3]),
      .desc_3_axaddr_2_reg(desc_n_axaddr_2_reg[3]),
      .desc_3_axaddr_3_reg(desc_n_axaddr_3_reg[3]),
      .desc_3_axid_0_reg( 32'h3),
      .desc_3_axid_1_reg( 32'h0),
      .desc_3_axid_2_reg( 32'h0),
      .desc_3_axid_3_reg( 32'h0),
      .desc_3_axuser_0_reg(32'h0 ),
      .desc_3_axuser_1_reg(32'h0 ),
      .desc_3_axuser_2_reg(32'h0 ),
      .desc_3_axuser_3_reg(32'h0 ),
      .desc_3_axuser_4_reg(32'h0 ),
      .desc_3_axuser_5_reg(32'h0 ),
      .desc_3_axuser_6_reg(32'h0 ),
      .desc_3_axuser_7_reg(32'h0 ),
      .desc_3_axuser_8_reg(32'h0 ),
      .desc_3_axuser_9_reg(32'h0 ),
      .desc_3_axuser_10_reg(32'h0 ),
      .desc_3_axuser_11_reg(32'h0 ),
      .desc_3_axuser_12_reg(32'h0 ),
      .desc_3_axuser_13_reg(32'h0 ),
      .desc_3_axuser_14_reg(32'h0 ),
      .desc_3_axuser_15_reg(32'h0 ),
      .desc_3_xuser_0_reg(32'h0 ),
      .desc_3_xuser_1_reg(32'h0 ),
      .desc_3_xuser_2_reg(32'h0 ),
      .desc_3_xuser_3_reg(32'h0 ),
      .desc_3_xuser_4_reg(32'h0 ),
      .desc_3_xuser_5_reg(32'h0 ),
      .desc_3_xuser_6_reg(32'h0 ),
      .desc_3_xuser_7_reg(32'h0 ),
      .desc_3_xuser_8_reg(32'h0 ),
      .desc_3_xuser_9_reg(32'h0 ),
      .desc_3_xuser_10_reg(32'h0 ),
      .desc_3_xuser_11_reg(32'h0 ),
      .desc_3_xuser_12_reg(32'h0 ),
      .desc_3_xuser_13_reg(32'h0 ),
      .desc_3_xuser_14_reg(32'h0 ),
      .desc_3_xuser_15_reg(32'h0 ),
      .desc_3_wuser_0_reg(32'h0 ),
      .desc_3_wuser_1_reg(32'h0 ),
      .desc_3_wuser_2_reg(32'h0 ),
      .desc_3_wuser_3_reg(32'h0 ),
      .desc_3_wuser_4_reg(32'h0 ),
      .desc_3_wuser_5_reg(32'h0 ),
      .desc_3_wuser_6_reg(32'h0 ),
      .desc_3_wuser_7_reg(32'h0 ),
      .desc_3_wuser_8_reg(32'h0 ),
      .desc_3_wuser_9_reg(32'h0 ),
      .desc_3_wuser_10_reg(32'h0 ),
      .desc_3_wuser_11_reg(32'h0 ),
      .desc_3_wuser_12_reg(32'h0 ),
      .desc_3_wuser_13_reg(32'h0 ),
      .desc_3_wuser_14_reg(32'h0 ),
      .desc_3_wuser_15_reg(32'h0 ),

      .desc_4_txn_type_reg(desc_4_txn_type_hm_reg),
      .desc_4_size_reg(desc_4_size_reg[31:0]),
      .desc_4_data_offset_reg(desc_4_data_offset_reg[31:0]),
      .desc_4_data_host_addr_0_reg(32'h0 ), 
      .desc_4_data_host_addr_1_reg(32'h0 ), 
      .desc_4_data_host_addr_2_reg(32'h0 ), 
      .desc_4_data_host_addr_3_reg(32'h0 ), 
      .desc_4_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_4_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_4_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_4_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_4_axsize_reg(32'h4),
      .desc_4_attr_reg(32'h1),
      .desc_4_axaddr_0_reg(desc_n_axaddr_0_reg[4]),
      .desc_4_axaddr_1_reg(desc_n_axaddr_1_reg[4]),
      .desc_4_axaddr_2_reg(desc_n_axaddr_2_reg[4]),
      .desc_4_axaddr_3_reg(desc_n_axaddr_3_reg[4]),
      .desc_4_axid_0_reg( 32'h4 ),
      .desc_4_axid_1_reg( 32'h0 ),
      .desc_4_axid_2_reg( 32'h0 ),
      .desc_4_axid_3_reg( 32'h0 ),
      .desc_4_axuser_0_reg(32'h0 ),
      .desc_4_axuser_1_reg(32'h0 ),
      .desc_4_axuser_2_reg(32'h0 ),
      .desc_4_axuser_3_reg(32'h0 ),
      .desc_4_axuser_4_reg(32'h0 ),
      .desc_4_axuser_5_reg(32'h0 ),
      .desc_4_axuser_6_reg(32'h0 ),
      .desc_4_axuser_7_reg(32'h0 ),
      .desc_4_axuser_8_reg(32'h0 ),
      .desc_4_axuser_9_reg(32'h0 ),
      .desc_4_axuser_10_reg(32'h0 ),
      .desc_4_axuser_11_reg(32'h0 ),
      .desc_4_axuser_12_reg(32'h0 ),
      .desc_4_axuser_13_reg(32'h0 ),
      .desc_4_axuser_14_reg(32'h0 ),
      .desc_4_axuser_15_reg(32'h0 ),
      .desc_4_xuser_0_reg(32'h0 ),
      .desc_4_xuser_1_reg(32'h0 ),
      .desc_4_xuser_2_reg(32'h0 ),
      .desc_4_xuser_3_reg(32'h0 ),
      .desc_4_xuser_4_reg(32'h0 ),
      .desc_4_xuser_5_reg(32'h0 ),
      .desc_4_xuser_6_reg(32'h0 ),
      .desc_4_xuser_7_reg(32'h0 ),
      .desc_4_xuser_8_reg(32'h0 ),
      .desc_4_xuser_9_reg(32'h0 ),
      .desc_4_xuser_10_reg(32'h0 ),
      .desc_4_xuser_11_reg(32'h0 ),
      .desc_4_xuser_12_reg(32'h0 ),
      .desc_4_xuser_13_reg(32'h0 ),
      .desc_4_xuser_14_reg(32'h0 ),
      .desc_4_xuser_15_reg(32'h0 ),
      .desc_4_wuser_0_reg(32'h0 ),
      .desc_4_wuser_1_reg(32'h0 ),
      .desc_4_wuser_2_reg(32'h0 ),
      .desc_4_wuser_3_reg(32'h0 ),
      .desc_4_wuser_4_reg(32'h0 ),
      .desc_4_wuser_5_reg(32'h0 ),
      .desc_4_wuser_6_reg(32'h0 ),
      .desc_4_wuser_7_reg(32'h0 ),
      .desc_4_wuser_8_reg(32'h0 ),
      .desc_4_wuser_9_reg(32'h0 ),
      .desc_4_wuser_10_reg(32'h0 ),
      .desc_4_wuser_11_reg(32'h0 ),
      .desc_4_wuser_12_reg(32'h0 ),
      .desc_4_wuser_13_reg(32'h0 ),
      .desc_4_wuser_14_reg(32'h0 ),
      .desc_4_wuser_15_reg(32'h0 ),

      .desc_5_txn_type_reg(desc_5_txn_type_hm_reg),
      .desc_5_size_reg(desc_5_size_reg[31:0]),
      .desc_5_data_offset_reg(desc_5_data_offset_reg[31:0]),
      .desc_5_data_host_addr_0_reg(32'h0 ), 
      .desc_5_data_host_addr_1_reg(32'h0 ), 
      .desc_5_data_host_addr_2_reg(32'h0 ), 
      .desc_5_data_host_addr_3_reg(32'h0 ), 
      .desc_5_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_5_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_5_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_5_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_5_axsize_reg(32'h4),
      .desc_5_attr_reg(32'h1),
      .desc_5_axaddr_0_reg(desc_n_axaddr_0_reg[5]),
      .desc_5_axaddr_1_reg(desc_n_axaddr_1_reg[5]),
      .desc_5_axaddr_2_reg(desc_n_axaddr_2_reg[5]),
      .desc_5_axaddr_3_reg(desc_n_axaddr_3_reg[5]),
      .desc_5_axid_0_reg( 32'h5 ),
      .desc_5_axid_1_reg( 32'h0 ),
      .desc_5_axid_2_reg( 32'h0 ),
      .desc_5_axid_3_reg( 32'h0 ),
      .desc_5_axuser_0_reg(32'h0 ),
      .desc_5_axuser_1_reg(32'h0 ),
      .desc_5_axuser_2_reg(32'h0 ),
      .desc_5_axuser_3_reg(32'h0 ),
      .desc_5_axuser_4_reg(32'h0 ),
      .desc_5_axuser_5_reg(32'h0 ),
      .desc_5_axuser_6_reg(32'h0 ),
      .desc_5_axuser_7_reg(32'h0 ),
      .desc_5_axuser_8_reg(32'h0 ),
      .desc_5_axuser_9_reg(32'h0 ),
      .desc_5_axuser_10_reg(32'h0 ),
      .desc_5_axuser_11_reg(32'h0 ),
      .desc_5_axuser_12_reg(32'h0 ),
      .desc_5_axuser_13_reg(32'h0 ),
      .desc_5_axuser_14_reg(32'h0 ),
      .desc_5_axuser_15_reg(32'h0 ),
      .desc_5_xuser_0_reg(32'h0 ),
      .desc_5_xuser_1_reg(32'h0 ),
      .desc_5_xuser_2_reg(32'h0 ),
      .desc_5_xuser_3_reg(32'h0 ),
      .desc_5_xuser_4_reg(32'h0 ),
      .desc_5_xuser_5_reg(32'h0 ),
      .desc_5_xuser_6_reg(32'h0 ),
      .desc_5_xuser_7_reg(32'h0 ),
      .desc_5_xuser_8_reg(32'h0 ),
      .desc_5_xuser_9_reg(32'h0 ),
      .desc_5_xuser_10_reg(32'h0 ),
      .desc_5_xuser_11_reg(32'h0 ),
      .desc_5_xuser_12_reg(32'h0 ),
      .desc_5_xuser_13_reg(32'h0 ),
      .desc_5_xuser_14_reg(32'h0 ),
      .desc_5_xuser_15_reg(32'h0 ),
      .desc_5_wuser_0_reg(32'h0 ),
      .desc_5_wuser_1_reg(32'h0 ),
      .desc_5_wuser_2_reg(32'h0 ),
      .desc_5_wuser_3_reg(32'h0 ),
      .desc_5_wuser_4_reg(32'h0 ),
      .desc_5_wuser_5_reg(32'h0 ),
      .desc_5_wuser_6_reg(32'h0 ),
      .desc_5_wuser_7_reg(32'h0 ),
      .desc_5_wuser_8_reg(32'h0 ),
      .desc_5_wuser_9_reg(32'h0 ),
      .desc_5_wuser_10_reg(32'h0 ),
      .desc_5_wuser_11_reg(32'h0 ),
      .desc_5_wuser_12_reg(32'h0 ),
      .desc_5_wuser_13_reg(32'h0 ),
      .desc_5_wuser_14_reg(32'h0 ),
      .desc_5_wuser_15_reg(32'h0 ),

      .desc_6_txn_type_reg(desc_6_txn_type_hm_reg),
      .desc_6_size_reg(desc_6_size_reg[31:0]),
      .desc_6_data_offset_reg(desc_6_data_offset_reg[31:0]),
      .desc_6_data_host_addr_0_reg(32'h0 ), 
      .desc_6_data_host_addr_1_reg(32'h0 ), 
      .desc_6_data_host_addr_2_reg(32'h0 ), 
      .desc_6_data_host_addr_3_reg(32'h0 ), 
      .desc_6_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_6_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_6_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_6_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_6_axsize_reg(32'h4),
      .desc_6_attr_reg(32'h1),
      .desc_6_axaddr_0_reg(desc_n_axaddr_0_reg[6]),
      .desc_6_axaddr_1_reg(desc_n_axaddr_1_reg[6]),
      .desc_6_axaddr_2_reg(desc_n_axaddr_2_reg[6]),
      .desc_6_axaddr_3_reg(desc_n_axaddr_3_reg[6]),
      .desc_6_axid_0_reg( 32'h6 ),
      .desc_6_axid_1_reg( 32'h0 ),
      .desc_6_axid_2_reg( 32'h0 ),
      .desc_6_axid_3_reg( 32'h0 ),
      .desc_6_axuser_0_reg(32'h0 ),
      .desc_6_axuser_1_reg(32'h0 ),
      .desc_6_axuser_2_reg(32'h0 ),
      .desc_6_axuser_3_reg(32'h0 ),
      .desc_6_axuser_4_reg(32'h0 ),
      .desc_6_axuser_5_reg(32'h0 ),
      .desc_6_axuser_6_reg(32'h0 ),
      .desc_6_axuser_7_reg(32'h0 ),
      .desc_6_axuser_8_reg(32'h0 ),
      .desc_6_axuser_9_reg(32'h0 ),
      .desc_6_axuser_10_reg(32'h0 ),
      .desc_6_axuser_11_reg(32'h0 ),
      .desc_6_axuser_12_reg(32'h0 ),
      .desc_6_axuser_13_reg(32'h0 ),
      .desc_6_axuser_14_reg(32'h0 ),
      .desc_6_axuser_15_reg(32'h0 ),
      .desc_6_xuser_0_reg(32'h0 ),
      .desc_6_xuser_1_reg(32'h0 ),
      .desc_6_xuser_2_reg(32'h0 ),
      .desc_6_xuser_3_reg(32'h0 ),
      .desc_6_xuser_4_reg(32'h0 ),
      .desc_6_xuser_5_reg(32'h0 ),
      .desc_6_xuser_6_reg(32'h0 ),
      .desc_6_xuser_7_reg(32'h0 ),
      .desc_6_xuser_8_reg(32'h0 ),
      .desc_6_xuser_9_reg(32'h0 ),
      .desc_6_xuser_10_reg( 32'h0  ),
      .desc_6_xuser_11_reg( 32'h0  ),
      .desc_6_xuser_12_reg( 32'h0  ),
      .desc_6_xuser_13_reg( 32'h0  ),
      .desc_6_xuser_14_reg( 32'h0  ),
      .desc_6_xuser_15_reg( 32'h0  ),
      .desc_6_wuser_0_reg(32'h0 ),
      .desc_6_wuser_1_reg(32'h0 ),
      .desc_6_wuser_2_reg(32'h0 ),
      .desc_6_wuser_3_reg(32'h0 ),
      .desc_6_wuser_4_reg(32'h0 ),
      .desc_6_wuser_5_reg(32'h0 ),
      .desc_6_wuser_6_reg(32'h0 ),
      .desc_6_wuser_7_reg(32'h0 ),
      .desc_6_wuser_8_reg(32'h0 ),
      .desc_6_wuser_9_reg(32'h0 ),
      .desc_6_wuser_10_reg(32'h0 ),
      .desc_6_wuser_11_reg(32'h0 ),
      .desc_6_wuser_12_reg(32'h0 ),
      .desc_6_wuser_13_reg(32'h0 ),
      .desc_6_wuser_14_reg(32'h0 ),
      .desc_6_wuser_15_reg(32'h0 ),

      .desc_7_txn_type_reg(desc_7_txn_type_hm_reg),
      .desc_7_size_reg(desc_7_size_reg[31:0]),
      .desc_7_data_offset_reg(desc_7_data_offset_reg[31:0]),
      .desc_7_data_host_addr_0_reg(32'h0 ), 
      .desc_7_data_host_addr_1_reg(32'h0 ), 
      .desc_7_data_host_addr_2_reg(32'h0 ), 
      .desc_7_data_host_addr_3_reg(32'h0 ), 
      .desc_7_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_7_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_7_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_7_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_7_axsize_reg(32'h4),
      .desc_7_attr_reg(32'h1),
      .desc_7_axaddr_0_reg(desc_n_axaddr_0_reg[7]),
      .desc_7_axaddr_1_reg(desc_n_axaddr_1_reg[7]),
      .desc_7_axaddr_2_reg(desc_n_axaddr_2_reg[7]),
      .desc_7_axaddr_3_reg(desc_n_axaddr_3_reg[7]),
      .desc_7_axid_0_reg( 32'h7 ),
      .desc_7_axid_1_reg( 32'h0 ),
      .desc_7_axid_2_reg( 32'h0 ),
      .desc_7_axid_3_reg( 32'h0 ),
      .desc_7_axuser_0_reg(32'h0 ),
      .desc_7_axuser_1_reg(32'h0 ),
      .desc_7_axuser_2_reg(32'h0 ),
      .desc_7_axuser_3_reg(32'h0 ),
      .desc_7_axuser_4_reg(32'h0 ),
      .desc_7_axuser_5_reg(32'h0 ),
      .desc_7_axuser_6_reg(32'h0 ),
      .desc_7_axuser_7_reg(32'h0 ),
      .desc_7_axuser_8_reg(32'h0 ),
      .desc_7_axuser_9_reg(32'h0 ),
      .desc_7_axuser_10_reg(32'h0 ),
      .desc_7_axuser_11_reg(32'h0 ),
      .desc_7_axuser_12_reg(32'h0 ),
      .desc_7_axuser_13_reg(32'h0 ),
      .desc_7_axuser_14_reg(32'h0 ),
      .desc_7_axuser_15_reg(32'h0 ),
      .desc_7_xuser_0_reg(32'h0 ),
      .desc_7_xuser_1_reg(32'h0 ),
      .desc_7_xuser_2_reg(32'h0 ),
      .desc_7_xuser_3_reg(32'h0 ),
      .desc_7_xuser_4_reg(32'h0 ),
      .desc_7_xuser_5_reg(32'h0 ),
      .desc_7_xuser_6_reg(32'h0 ),
      .desc_7_xuser_7_reg(32'h0 ),
      .desc_7_xuser_8_reg(32'h0 ),
      .desc_7_xuser_9_reg(32'h0 ),
      .desc_7_xuser_10_reg(32'h0 ),
      .desc_7_xuser_11_reg(32'h0 ),
      .desc_7_xuser_12_reg(32'h0 ),
      .desc_7_xuser_13_reg(32'h0 ),
      .desc_7_xuser_14_reg(32'h0 ),
      .desc_7_xuser_15_reg(32'h0 ),
      .desc_7_wuser_0_reg( 32'h0 ),
      .desc_7_wuser_1_reg( 32'h0 ),
      .desc_7_wuser_2_reg( 32'h0 ),
      .desc_7_wuser_3_reg( 32'h0 ),
      .desc_7_wuser_4_reg( 32'h0 ),
      .desc_7_wuser_5_reg( 32'h0 ),
      .desc_7_wuser_6_reg( 32'h0 ),
      .desc_7_wuser_7_reg( 32'h0 ),
      .desc_7_wuser_8_reg( 32'h0 ),
      .desc_7_wuser_9_reg( 32'h0 ),
      .desc_7_wuser_10_reg(32'h0 ),
      .desc_7_wuser_11_reg(32'h0 ),
      .desc_7_wuser_12_reg(32'h0 ),
      .desc_7_wuser_13_reg(32'h0 ),
      .desc_7_wuser_14_reg(32'h0 ),
      .desc_7_wuser_15_reg(32'h0 ),

      .desc_8_txn_type_reg(desc_8_txn_type_hm_reg),
      .desc_8_size_reg(desc_8_size_reg[31:0]),
      .desc_8_data_offset_reg(desc_8_data_offset_reg[31:0]),
      .desc_8_data_host_addr_0_reg(32'h0 ), 
      .desc_8_data_host_addr_1_reg(32'h0 ), 
      .desc_8_data_host_addr_2_reg(32'h0 ), 
      .desc_8_data_host_addr_3_reg(32'h0 ), 
      .desc_8_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_8_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_8_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_8_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_8_axsize_reg(32'h4),
      .desc_8_attr_reg(32'h1),
      .desc_8_axaddr_0_reg(desc_n_axaddr_0_reg[8]),
      .desc_8_axaddr_1_reg(desc_n_axaddr_1_reg[8]),
      .desc_8_axaddr_2_reg(desc_n_axaddr_2_reg[8]),
      .desc_8_axaddr_3_reg(desc_n_axaddr_3_reg[8]),
      .desc_8_axid_0_reg( 32'h8 ),
      .desc_8_axid_1_reg( 32'h0 ),
      .desc_8_axid_2_reg( 32'h0 ),
      .desc_8_axid_3_reg( 32'h0 ),
      .desc_8_axuser_0_reg(32'h0 ),
      .desc_8_axuser_1_reg(32'h0 ),
      .desc_8_axuser_2_reg(32'h0 ),
      .desc_8_axuser_3_reg(32'h0 ),
      .desc_8_axuser_4_reg(32'h0 ),
      .desc_8_axuser_5_reg(32'h0 ),
      .desc_8_axuser_6_reg(32'h0 ),
      .desc_8_axuser_7_reg(32'h0 ),
      .desc_8_axuser_8_reg(32'h0 ),
      .desc_8_axuser_9_reg(32'h0 ),
      .desc_8_axuser_10_reg( 32'h0),
      .desc_8_axuser_11_reg( 32'h0),
      .desc_8_axuser_12_reg( 32'h0),
      .desc_8_axuser_13_reg( 32'h0),
      .desc_8_axuser_14_reg( 32'h0),
      .desc_8_axuser_15_reg( 32'h0),
      .desc_8_xuser_0_reg(32'h0 ),
      .desc_8_xuser_1_reg(32'h0 ),
      .desc_8_xuser_2_reg(32'h0 ),
      .desc_8_xuser_3_reg(32'h0 ),
      .desc_8_xuser_4_reg(32'h0 ),
      .desc_8_xuser_5_reg(32'h0 ),
      .desc_8_xuser_6_reg(32'h0 ),
      .desc_8_xuser_7_reg(32'h0 ),
      .desc_8_xuser_8_reg(32'h0 ),
      .desc_8_xuser_9_reg(32'h0 ),
      .desc_8_xuser_10_reg(32'h0 ),
      .desc_8_xuser_11_reg(32'h0 ),
      .desc_8_xuser_12_reg(32'h0 ),
      .desc_8_xuser_13_reg(32'h0 ),
      .desc_8_xuser_14_reg(32'h0 ),
      .desc_8_xuser_15_reg(32'h0 ),
      .desc_8_wuser_0_reg(32'h0 ),
      .desc_8_wuser_1_reg(32'h0 ),
      .desc_8_wuser_2_reg(32'h0 ),
      .desc_8_wuser_3_reg(32'h0 ),
      .desc_8_wuser_4_reg(32'h0 ),
      .desc_8_wuser_5_reg(32'h0 ),
      .desc_8_wuser_6_reg(32'h0 ),
      .desc_8_wuser_7_reg(32'h0 ),
      .desc_8_wuser_8_reg(32'h0 ),
      .desc_8_wuser_9_reg(32'h0 ),
      .desc_8_wuser_10_reg(32'h0 ),
      .desc_8_wuser_11_reg(32'h0 ),
      .desc_8_wuser_12_reg(32'h0 ),
      .desc_8_wuser_13_reg(32'h0 ),
      .desc_8_wuser_14_reg(32'h0 ),
      .desc_8_wuser_15_reg(32'h0 ),

      .desc_9_txn_type_reg(desc_9_txn_type_hm_reg),
      .desc_9_size_reg(desc_9_size_reg[31:0]),
      .desc_9_data_offset_reg(desc_9_data_offset_reg[31:0]),
      .desc_9_data_host_addr_0_reg(32'h0 ), 
      .desc_9_data_host_addr_1_reg(32'h0 ), 
      .desc_9_data_host_addr_2_reg(32'h0 ), 
      .desc_9_data_host_addr_3_reg(32'h0 ), 
      .desc_9_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_9_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_9_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_9_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_9_axsize_reg(32'h4),
      .desc_9_attr_reg(32'h1),
      .desc_9_axaddr_0_reg(desc_n_axaddr_0_reg[9]),
      .desc_9_axaddr_1_reg(desc_n_axaddr_1_reg[9]),
      .desc_9_axaddr_2_reg(desc_n_axaddr_2_reg[9]),
      .desc_9_axaddr_3_reg(desc_n_axaddr_3_reg[9]),
      .desc_9_axid_0_reg( 32'h9 ),
      .desc_9_axid_1_reg( 32'h0 ),
      .desc_9_axid_2_reg( 32'h0 ),
      .desc_9_axid_3_reg( 32'h0 ),
      .desc_9_axuser_0_reg(32'h0 ),
      .desc_9_axuser_1_reg(32'h0 ),
      .desc_9_axuser_2_reg(32'h0 ),
      .desc_9_axuser_3_reg(32'h0 ),
      .desc_9_axuser_4_reg(32'h0 ),
      .desc_9_axuser_5_reg(32'h0 ),
      .desc_9_axuser_6_reg(32'h0 ),
      .desc_9_axuser_7_reg(32'h0 ),
      .desc_9_axuser_8_reg(32'h0 ),
      .desc_9_axuser_9_reg(32'h0 ),
      .desc_9_axuser_10_reg(32'h0 ),
      .desc_9_axuser_11_reg(32'h0 ),
      .desc_9_axuser_12_reg(32'h0 ),
      .desc_9_axuser_13_reg(32'h0 ),
      .desc_9_axuser_14_reg(32'h0 ),
      .desc_9_axuser_15_reg(32'h0 ),
      .desc_9_xuser_0_reg(32'h0 ),
      .desc_9_xuser_1_reg(32'h0 ),
      .desc_9_xuser_2_reg(32'h0 ),
      .desc_9_xuser_3_reg(32'h0 ),
      .desc_9_xuser_4_reg(32'h0 ),
      .desc_9_xuser_5_reg(32'h0 ),
      .desc_9_xuser_6_reg(32'h0 ),
      .desc_9_xuser_7_reg(32'h0 ),
      .desc_9_xuser_8_reg(32'h0 ),
      .desc_9_xuser_9_reg(32'h0 ),
      .desc_9_xuser_10_reg(32'h0 ),
      .desc_9_xuser_11_reg(32'h0 ),
      .desc_9_xuser_12_reg(32'h0 ),
      .desc_9_xuser_13_reg(32'h0 ),
      .desc_9_xuser_14_reg(32'h0 ),
      .desc_9_xuser_15_reg(32'h0 ),
      .desc_9_wuser_0_reg(32'h0 ),
      .desc_9_wuser_1_reg(32'h0 ),
      .desc_9_wuser_2_reg(32'h0 ),
      .desc_9_wuser_3_reg(32'h0 ),
      .desc_9_wuser_4_reg(32'h0 ),
      .desc_9_wuser_5_reg(32'h0 ),
      .desc_9_wuser_6_reg(32'h0 ),
      .desc_9_wuser_7_reg(32'h0 ),
      .desc_9_wuser_8_reg(32'h0 ),
      .desc_9_wuser_9_reg(32'h0 ),
      .desc_9_wuser_10_reg(32'h0 ),
      .desc_9_wuser_11_reg(32'h0 ),
      .desc_9_wuser_12_reg(32'h0 ),
      .desc_9_wuser_13_reg(32'h0 ),
      .desc_9_wuser_14_reg(32'h0 ),
      .desc_9_wuser_15_reg(32'h0 ),

      .desc_10_txn_type_reg(desc_10_txn_type_hm_reg),
      .desc_10_size_reg(desc_10_size_reg[31:0]),
      .desc_10_data_offset_reg(desc_10_data_offset_reg[31:0]),
      .desc_10_data_host_addr_0_reg(32'h0 ), 
      .desc_10_data_host_addr_1_reg(32'h0 ), 
      .desc_10_data_host_addr_2_reg(32'h0 ), 
      .desc_10_data_host_addr_3_reg(32'h0 ), 
      .desc_10_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_10_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_10_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_10_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_10_axsize_reg(32'h4),
      .desc_10_attr_reg(32'h1),
      .desc_10_axaddr_0_reg(desc_n_axaddr_0_reg[10]),
      .desc_10_axaddr_1_reg(desc_n_axaddr_1_reg[10]),
      .desc_10_axaddr_2_reg(desc_n_axaddr_2_reg[10]),
      .desc_10_axaddr_3_reg(desc_n_axaddr_3_reg[10]),
      .desc_10_axid_0_reg( 32'hA ),
      .desc_10_axid_1_reg( 32'h0 ),
      .desc_10_axid_2_reg( 32'h0 ),
      .desc_10_axid_3_reg( 32'h0 ),
      .desc_10_axuser_0_reg(32'h0 ),
      .desc_10_axuser_1_reg(32'h0 ),
      .desc_10_axuser_2_reg(32'h0 ),
      .desc_10_axuser_3_reg(32'h0 ),
      .desc_10_axuser_4_reg(32'h0 ),
      .desc_10_axuser_5_reg(32'h0 ),
      .desc_10_axuser_6_reg(32'h0 ),
      .desc_10_axuser_7_reg(32'h0 ),
      .desc_10_axuser_8_reg(32'h0 ),
      .desc_10_axuser_9_reg(32'h0 ),
      .desc_10_axuser_10_reg(32'h0 ),
      .desc_10_axuser_11_reg(32'h0 ),
      .desc_10_axuser_12_reg(32'h0 ),
      .desc_10_axuser_13_reg(32'h0 ),
      .desc_10_axuser_14_reg(32'h0 ),
      .desc_10_axuser_15_reg(32'h0 ),
      .desc_10_xuser_0_reg(32'h0 ),
      .desc_10_xuser_1_reg(32'h0 ),
      .desc_10_xuser_2_reg(32'h0 ),
      .desc_10_xuser_3_reg(32'h0 ),
      .desc_10_xuser_4_reg(32'h0 ),
      .desc_10_xuser_5_reg(32'h0 ),
      .desc_10_xuser_6_reg(32'h0 ),
      .desc_10_xuser_7_reg(32'h0 ),
      .desc_10_xuser_8_reg(32'h0 ),
      .desc_10_xuser_9_reg(32'h0 ),
      .desc_10_xuser_10_reg(32'h0 ),
      .desc_10_xuser_11_reg(32'h0 ),
      .desc_10_xuser_12_reg(32'h0 ),
      .desc_10_xuser_13_reg(32'h0 ),
      .desc_10_xuser_14_reg(32'h0 ),
      .desc_10_xuser_15_reg(32'h0 ),
      .desc_10_wuser_0_reg(32'h0 ),
      .desc_10_wuser_1_reg(32'h0 ),
      .desc_10_wuser_2_reg(32'h0 ),
      .desc_10_wuser_3_reg(32'h0 ),
      .desc_10_wuser_4_reg(32'h0 ),
      .desc_10_wuser_5_reg(32'h0 ),
      .desc_10_wuser_6_reg(32'h0 ),
      .desc_10_wuser_7_reg(32'h0 ),
      .desc_10_wuser_8_reg(32'h0 ),
      .desc_10_wuser_9_reg(32'h0 ),
      .desc_10_wuser_10_reg(32'h0 ),
      .desc_10_wuser_11_reg(32'h0 ),
      .desc_10_wuser_12_reg(32'h0 ),
      .desc_10_wuser_13_reg(32'h0 ),
      .desc_10_wuser_14_reg(32'h0 ),
      .desc_10_wuser_15_reg(32'h0 ),

      .desc_11_txn_type_reg(desc_11_txn_type_hm_reg),
      .desc_11_size_reg(desc_11_size_reg[31:0]),
      .desc_11_data_offset_reg(desc_11_data_offset_reg[31:0]),
      .desc_11_data_host_addr_0_reg(32'h0 ), 
      .desc_11_data_host_addr_1_reg(32'h0 ), 
      .desc_11_data_host_addr_2_reg(32'h0 ), 
      .desc_11_data_host_addr_3_reg(32'h0 ), 
      .desc_11_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_11_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_11_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_11_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_11_axsize_reg(32'h4),
      .desc_11_attr_reg(32'h1),
      .desc_11_axaddr_0_reg(desc_n_axaddr_0_reg[11]),
      .desc_11_axaddr_1_reg(desc_n_axaddr_1_reg[11]),
      .desc_11_axaddr_2_reg(desc_n_axaddr_2_reg[11]),
      .desc_11_axaddr_3_reg(desc_n_axaddr_3_reg[11]),
      .desc_11_axid_0_reg( 32'hB),
      .desc_11_axid_1_reg( 32'h0),
      .desc_11_axid_2_reg( 32'h0),
      .desc_11_axid_3_reg( 32'h0),
      .desc_11_axuser_0_reg(32'h0 ),
      .desc_11_axuser_1_reg(32'h0 ),
      .desc_11_axuser_2_reg(32'h0 ),
      .desc_11_axuser_3_reg(32'h0 ),
      .desc_11_axuser_4_reg(32'h0 ),
      .desc_11_axuser_5_reg(32'h0 ),
      .desc_11_axuser_6_reg(32'h0 ),
      .desc_11_axuser_7_reg(32'h0 ),
      .desc_11_axuser_8_reg(32'h0 ),
      .desc_11_axuser_9_reg(32'h0 ),
      .desc_11_axuser_10_reg(32'h0 ),
      .desc_11_axuser_11_reg(32'h0 ),
      .desc_11_axuser_12_reg(32'h0 ),
      .desc_11_axuser_13_reg(32'h0 ),
      .desc_11_axuser_14_reg(32'h0 ),
      .desc_11_axuser_15_reg(32'h0 ),
      .desc_11_xuser_0_reg(32'h0 ),
      .desc_11_xuser_1_reg(32'h0 ),
      .desc_11_xuser_2_reg(32'h0 ),
      .desc_11_xuser_3_reg(32'h0 ),
      .desc_11_xuser_4_reg(32'h0 ),
      .desc_11_xuser_5_reg(32'h0 ),
      .desc_11_xuser_6_reg(32'h0 ),
      .desc_11_xuser_7_reg(32'h0 ),
      .desc_11_xuser_8_reg(32'h0 ),
      .desc_11_xuser_9_reg(32'h0 ),
      .desc_11_xuser_10_reg(32'h0 ),
      .desc_11_xuser_11_reg(32'h0 ),
      .desc_11_xuser_12_reg(32'h0 ),
      .desc_11_xuser_13_reg(32'h0 ),
      .desc_11_xuser_14_reg(32'h0 ),
      .desc_11_xuser_15_reg(32'h0 ),
      .desc_11_wuser_0_reg(32'h0 ),
      .desc_11_wuser_1_reg(32'h0 ),
      .desc_11_wuser_2_reg(32'h0 ),
      .desc_11_wuser_3_reg(32'h0 ),
      .desc_11_wuser_4_reg(32'h0 ),
      .desc_11_wuser_5_reg(32'h0 ),
      .desc_11_wuser_6_reg(32'h0 ),
      .desc_11_wuser_7_reg(32'h0 ),
      .desc_11_wuser_8_reg(32'h0 ),
      .desc_11_wuser_9_reg(32'h0 ),
      .desc_11_wuser_10_reg(32'h0 ),
      .desc_11_wuser_11_reg(32'h0 ),
      .desc_11_wuser_12_reg(32'h0 ),
      .desc_11_wuser_13_reg(32'h0 ),
      .desc_11_wuser_14_reg(32'h0 ),
      .desc_11_wuser_15_reg(32'h0 ),

      .desc_12_txn_type_reg(desc_12_txn_type_hm_reg),
      .desc_12_size_reg(desc_12_size_reg[31:0]),
      .desc_12_data_offset_reg(desc_12_data_offset_reg[31:0]),
      .desc_12_data_host_addr_0_reg(32'h0 ), 
      .desc_12_data_host_addr_1_reg(32'h0 ), 
      .desc_12_data_host_addr_2_reg(32'h0 ), 
      .desc_12_data_host_addr_3_reg(32'h0 ), 
      .desc_12_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_12_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_12_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_12_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_12_axsize_reg(32'h4),
      .desc_12_attr_reg(32'h1),
      .desc_12_axaddr_0_reg(desc_n_axaddr_0_reg[12]),
      .desc_12_axaddr_1_reg(desc_n_axaddr_1_reg[12]),
      .desc_12_axaddr_2_reg(desc_n_axaddr_2_reg[12]),
      .desc_12_axaddr_3_reg(desc_n_axaddr_3_reg[12]),
      .desc_12_axid_0_reg( 32'hC ),
      .desc_12_axid_1_reg( 32'h0 ),
      .desc_12_axid_2_reg( 32'h0 ),
      .desc_12_axid_3_reg( 32'h0 ),
      .desc_12_axuser_0_reg(32'h0 ),
      .desc_12_axuser_1_reg(32'h0 ),
      .desc_12_axuser_2_reg(32'h0 ),
      .desc_12_axuser_3_reg(32'h0 ),
      .desc_12_axuser_4_reg(32'h0 ),
      .desc_12_axuser_5_reg(32'h0 ),
      .desc_12_axuser_6_reg(32'h0 ),
      .desc_12_axuser_7_reg(32'h0 ),
      .desc_12_axuser_8_reg(32'h0 ),
      .desc_12_axuser_9_reg(32'h0 ),
      .desc_12_axuser_10_reg(32'h0 ),
      .desc_12_axuser_11_reg(32'h0 ),
      .desc_12_axuser_12_reg(32'h0 ),
      .desc_12_axuser_13_reg(32'h0 ),
      .desc_12_axuser_14_reg(32'h0 ),
      .desc_12_axuser_15_reg(32'h0 ),
      .desc_12_xuser_0_reg(32'h0 ),
      .desc_12_xuser_1_reg(32'h0 ),
      .desc_12_xuser_2_reg(32'h0 ),
      .desc_12_xuser_3_reg(32'h0 ),
      .desc_12_xuser_4_reg(32'h0 ),
      .desc_12_xuser_5_reg(32'h0 ),
      .desc_12_xuser_6_reg(32'h0 ),
      .desc_12_xuser_7_reg(32'h0 ),
      .desc_12_xuser_8_reg(32'h0 ),
      .desc_12_xuser_9_reg(32'h0 ),
      .desc_12_xuser_10_reg(32'h0 ),
      .desc_12_xuser_11_reg(32'h0 ),
      .desc_12_xuser_12_reg(32'h0 ),
      .desc_12_xuser_13_reg(32'h0 ),
      .desc_12_xuser_14_reg(32'h0 ),
      .desc_12_xuser_15_reg(32'h0 ),
      .desc_12_wuser_0_reg(32'h0 ),
      .desc_12_wuser_1_reg(32'h0 ),
      .desc_12_wuser_2_reg(32'h0 ),
      .desc_12_wuser_3_reg(32'h0 ),
      .desc_12_wuser_4_reg(32'h0 ),
      .desc_12_wuser_5_reg(32'h0 ),
      .desc_12_wuser_6_reg(32'h0 ),
      .desc_12_wuser_7_reg(32'h0 ),
      .desc_12_wuser_8_reg(32'h0 ),
      .desc_12_wuser_9_reg(32'h0 ),
      .desc_12_wuser_10_reg(32'h0 ),
      .desc_12_wuser_11_reg(32'h0 ),
      .desc_12_wuser_12_reg(32'h0 ),
      .desc_12_wuser_13_reg(32'h0 ),
      .desc_12_wuser_14_reg(32'h0 ),
      .desc_12_wuser_15_reg(32'h0 ),
	  
      .desc_13_txn_type_reg(desc_13_txn_type_hm_reg),
      .desc_13_size_reg(desc_13_size_reg[31:0]),
      .desc_13_data_offset_reg(desc_13_data_offset_reg[31:0]),
      .desc_13_data_host_addr_0_reg(32'h0 ), 
      .desc_13_data_host_addr_1_reg(32'h0 ), 
      .desc_13_data_host_addr_2_reg(32'h0 ), 
      .desc_13_data_host_addr_3_reg(32'h0 ), 
      .desc_13_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_13_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_13_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_13_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_13_axsize_reg(32'h4),
      .desc_13_attr_reg(32'h1),
      .desc_13_axaddr_0_reg(desc_n_axaddr_0_reg[13]),
      .desc_13_axaddr_1_reg(desc_n_axaddr_1_reg[13]),
      .desc_13_axaddr_2_reg(desc_n_axaddr_2_reg[13]),
      .desc_13_axaddr_3_reg(desc_n_axaddr_3_reg[13]),
      .desc_13_axid_0_reg( 32'hD ),
      .desc_13_axid_1_reg( 32'h0 ),
      .desc_13_axid_2_reg( 32'h0 ),
      .desc_13_axid_3_reg( 32'h0 ),
      .desc_13_axuser_0_reg(32'h0 ),
      .desc_13_axuser_1_reg(32'h0 ),
      .desc_13_axuser_2_reg(32'h0 ),
      .desc_13_axuser_3_reg(32'h0 ),
      .desc_13_axuser_4_reg(32'h0 ),
      .desc_13_axuser_5_reg(32'h0 ),
      .desc_13_axuser_6_reg(32'h0 ),
      .desc_13_axuser_7_reg(32'h0 ),
      .desc_13_axuser_8_reg(32'h0 ),
      .desc_13_axuser_9_reg(32'h0 ),
      .desc_13_axuser_10_reg(32'h0 ),
      .desc_13_axuser_11_reg(32'h0 ),
      .desc_13_axuser_12_reg(32'h0 ),
      .desc_13_axuser_13_reg(32'h0 ),
      .desc_13_axuser_14_reg(32'h0 ),
      .desc_13_axuser_15_reg(32'h0 ),
      .desc_13_xuser_0_reg(32'h0 ),
      .desc_13_xuser_1_reg(32'h0 ),
      .desc_13_xuser_2_reg(32'h0 ),
      .desc_13_xuser_3_reg(32'h0 ),
      .desc_13_xuser_4_reg(32'h0 ),
      .desc_13_xuser_5_reg(32'h0 ),
      .desc_13_xuser_6_reg(32'h0 ),
      .desc_13_xuser_7_reg(32'h0 ),
      .desc_13_xuser_8_reg(32'h0 ),
      .desc_13_xuser_9_reg(32'h0 ),
      .desc_13_xuser_10_reg(32'h0 ),
      .desc_13_xuser_11_reg(32'h0 ),
      .desc_13_xuser_12_reg(32'h0 ),
      .desc_13_xuser_13_reg(32'h0 ),
      .desc_13_xuser_14_reg(32'h0 ),
      .desc_13_xuser_15_reg(32'h0 ),
      .desc_13_wuser_0_reg(32'h0 ),
      .desc_13_wuser_1_reg(32'h0 ),
      .desc_13_wuser_2_reg(32'h0 ),
      .desc_13_wuser_3_reg(32'h0 ),
      .desc_13_wuser_4_reg(32'h0 ),
      .desc_13_wuser_5_reg(32'h0 ),
      .desc_13_wuser_6_reg(32'h0 ),
      .desc_13_wuser_7_reg(32'h0 ),
      .desc_13_wuser_8_reg(32'h0 ),
      .desc_13_wuser_9_reg(32'h0 ),
      .desc_13_wuser_10_reg(32'h0 ),
      .desc_13_wuser_11_reg(32'h0 ),
      .desc_13_wuser_12_reg(32'h0 ),
      .desc_13_wuser_13_reg(32'h0 ),
      .desc_13_wuser_14_reg(32'h0 ),
      .desc_13_wuser_15_reg(32'h0 ),
      .desc_14_txn_type_reg(desc_14_txn_type_hm_reg),
      .desc_14_size_reg(desc_14_size_reg[31:0]),
      .desc_14_data_offset_reg(desc_14_data_offset_reg[31:0]),
      .desc_14_data_host_addr_0_reg(32'h0 ),
      .desc_14_data_host_addr_1_reg(32'h0 ),
      .desc_14_data_host_addr_2_reg(32'h0 ),
      .desc_14_data_host_addr_3_reg(32'h0 ),
      .desc_14_wstrb_host_addr_0_reg(32'h0 ),
      .desc_14_wstrb_host_addr_1_reg(32'h0 ),
      .desc_14_wstrb_host_addr_2_reg(32'h0 ),
      .desc_14_wstrb_host_addr_3_reg(32'h0 ),
      .desc_14_axsize_reg(32'h4),
      .desc_14_attr_reg(32'h1),
      .desc_14_axaddr_0_reg(desc_n_axaddr_0_reg[14]),
      .desc_14_axaddr_1_reg(desc_n_axaddr_1_reg[14]),
      .desc_14_axaddr_2_reg(desc_n_axaddr_2_reg[14]),
      .desc_14_axaddr_3_reg(desc_n_axaddr_3_reg[14]),
      .desc_14_axid_0_reg( 32'hE ),
      .desc_14_axid_1_reg( 32'h0 ),
      .desc_14_axid_2_reg( 32'h0 ),
      .desc_14_axid_3_reg( 32'h0 ),
      .desc_14_axuser_0_reg(32'h0 ),
      .desc_14_axuser_1_reg(32'h0 ),
      .desc_14_axuser_2_reg(32'h0 ),
      .desc_14_axuser_3_reg(32'h0 ),
      .desc_14_axuser_4_reg(32'h0 ),
      .desc_14_axuser_5_reg(32'h0 ),
      .desc_14_axuser_6_reg(32'h0 ),
      .desc_14_axuser_7_reg(32'h0 ),
      .desc_14_axuser_8_reg(32'h0 ),
      .desc_14_axuser_9_reg(32'h0 ),
      .desc_14_axuser_10_reg(32'h0 ),
      .desc_14_axuser_11_reg(32'h0 ),
      .desc_14_axuser_12_reg(32'h0 ),
      .desc_14_axuser_13_reg(32'h0 ),
      .desc_14_axuser_14_reg(32'h0 ),
      .desc_14_axuser_15_reg(32'h0 ),
      .desc_14_xuser_0_reg(32'h0 ),
      .desc_14_xuser_1_reg(32'h0 ),
      .desc_14_xuser_2_reg(32'h0 ),
      .desc_14_xuser_3_reg(32'h0 ),
      .desc_14_xuser_4_reg(32'h0 ),
      .desc_14_xuser_5_reg(32'h0 ),
      .desc_14_xuser_6_reg(32'h0 ),
      .desc_14_xuser_7_reg(32'h0 ),
      .desc_14_xuser_8_reg(32'h0 ),
      .desc_14_xuser_9_reg(32'h0 ),
      .desc_14_xuser_10_reg(32'h0 ),
      .desc_14_xuser_11_reg(32'h0 ),
      .desc_14_xuser_12_reg(32'h0 ),
      .desc_14_xuser_13_reg(32'h0 ),
      .desc_14_xuser_14_reg(32'h0 ),
      .desc_14_xuser_15_reg(32'h0 ),
      .desc_14_wuser_0_reg(32'h0 ),
      .desc_14_wuser_1_reg(32'h0 ),
      .desc_14_wuser_2_reg(32'h0 ),
      .desc_14_wuser_3_reg(32'h0 ),
      .desc_14_wuser_4_reg(32'h0 ),
      .desc_14_wuser_5_reg(32'h0 ),
      .desc_14_wuser_6_reg(32'h0 ),
      .desc_14_wuser_7_reg(32'h0 ),
      .desc_14_wuser_8_reg(32'h0 ),
      .desc_14_wuser_9_reg(32'h0 ),
      .desc_14_wuser_10_reg(32'h0 ),
      .desc_14_wuser_11_reg(32'h0 ),
      .desc_14_wuser_12_reg(32'h0 ),
      .desc_14_wuser_13_reg(32'h0 ),
      .desc_14_wuser_14_reg(32'h0 ),
      .desc_14_wuser_15_reg(32'h0 ),
      .desc_15_txn_type_reg(desc_15_txn_type_hm_reg),
      .desc_15_size_reg(desc_15_size_reg[31:0]),
      .desc_15_data_offset_reg(desc_15_data_offset_reg[31:0]),
      .desc_15_data_host_addr_0_reg(32'h0 ), 
      .desc_15_data_host_addr_1_reg(32'h0 ), 
      .desc_15_data_host_addr_2_reg(32'h0 ), 
      .desc_15_data_host_addr_3_reg(32'h0 ), 
      .desc_15_wstrb_host_addr_0_reg(32'h0 ), 
      .desc_15_wstrb_host_addr_1_reg(32'h0 ), 
      .desc_15_wstrb_host_addr_2_reg(32'h0 ), 
      .desc_15_wstrb_host_addr_3_reg(32'h0 ), 
      .desc_15_axsize_reg(32'h4),
      .desc_15_attr_reg(32'h1),
      .desc_15_axaddr_0_reg(desc_n_axaddr_0_reg[15]),
      .desc_15_axaddr_1_reg(desc_n_axaddr_1_reg[15]),
      .desc_15_axaddr_2_reg(desc_n_axaddr_2_reg[15]),
      .desc_15_axaddr_3_reg(desc_n_axaddr_3_reg[15]),
      .desc_15_axid_0_reg( 32'hF ),
      .desc_15_axid_1_reg( 32'h0 ),
      .desc_15_axid_2_reg( 32'h0 ),
      .desc_15_axid_3_reg( 32'h0 ),
      .desc_15_axuser_0_reg(32'h0 ),
      .desc_15_axuser_1_reg(32'h0 ),
      .desc_15_axuser_2_reg(32'h0 ),
      .desc_15_axuser_3_reg(32'h0 ),
      .desc_15_axuser_4_reg(32'h0 ),
      .desc_15_axuser_5_reg(32'h0 ),
      .desc_15_axuser_6_reg(32'h0 ),
      .desc_15_axuser_7_reg(32'h0 ),
      .desc_15_axuser_8_reg(32'h0 ),
      .desc_15_axuser_9_reg(32'h0 ),
      .desc_15_axuser_10_reg(32'h0 ),
      .desc_15_axuser_11_reg(32'h0 ),
      .desc_15_axuser_12_reg(32'h0 ),
      .desc_15_axuser_13_reg(32'h0 ),
      .desc_15_axuser_14_reg(32'h0 ),
      .desc_15_axuser_15_reg(32'h0 ),
      .desc_15_xuser_0_reg(32'h0 ),
      .desc_15_xuser_1_reg(32'h0 ),
      .desc_15_xuser_2_reg(32'h0 ),
      .desc_15_xuser_3_reg(32'h0 ),
      .desc_15_xuser_4_reg(32'h0 ),
      .desc_15_xuser_5_reg(32'h0 ),
      .desc_15_xuser_6_reg(32'h0 ),
      .desc_15_xuser_7_reg(32'h0 ),
      .desc_15_xuser_8_reg(32'h0 ),
      .desc_15_xuser_9_reg(32'h0 ),
      .desc_15_xuser_10_reg(32'h0 ),
      .desc_15_xuser_11_reg(32'h0 ),
      .desc_15_xuser_12_reg(32'h0 ),
      .desc_15_xuser_13_reg(32'h0 ),
      .desc_15_xuser_14_reg(32'h0 ),
      .desc_15_xuser_15_reg(32'h0 ),
      .desc_15_wuser_0_reg(32'h0 ),
      .desc_15_wuser_1_reg(32'h0 ),
      .desc_15_wuser_2_reg(32'h0 ),
      .desc_15_wuser_3_reg(32'h0 ),
      .desc_15_wuser_4_reg(32'h0 ),
      .desc_15_wuser_5_reg(32'h0 ),
      .desc_15_wuser_6_reg(32'h0 ),
      .desc_15_wuser_7_reg(32'h0 ),
      .desc_15_wuser_8_reg(32'h0 ),
      .desc_15_wuser_9_reg(32'h0 ),
      .desc_15_wuser_10_reg(32'h0 ),
      .desc_15_wuser_11_reg(32'h0 ),
      .desc_15_wuser_12_reg(32'h0 ),
      .desc_15_wuser_13_reg(32'h0 ),
      .desc_15_wuser_14_reg(32'h0 ),
      .desc_15_wuser_15_reg(32'h0 ),

      .m_axi_usr_awid       (m_axi_awid    ),         
      .m_axi_usr_awaddr     (m_axi_awaddr  ),         
      .m_axi_usr_awlen      (m_axi_awlen   ),         
      .m_axi_usr_awsize     (m_axi_awsize  ),         
      .m_axi_usr_awburst    (m_axi_awburst ),         
      .m_axi_usr_awlock     (m_axi_awlock_all_prot  ),         
      .m_axi_usr_awcache    (m_axi_awcache ),         
      .m_axi_usr_awprot     (m_axi_awprot  ),         
      .m_axi_usr_awqos      (m_axi_awqos   ),         
      .m_axi_usr_awregion   (m_axi_awregion),         
      .m_axi_usr_awuser     (m_axi_awuser  ),         
      .m_axi_usr_awvalid    (m_axi_awvalid ),         
      .m_axi_usr_awready    (m_axi_awready ),         
      .m_axi_usr_wdata      (m_axi_wdata   ),         
      .m_axi_usr_wstrb      (m_axi_wstrb   ), 
      .m_axi_usr_wlast      (m_axi_wlast   ),         
      .m_axi_usr_wuser      (m_axi_wuser   ),         
      .m_axi_usr_wvalid     (m_axi_wvalid  ),         
      .m_axi_usr_wready     (m_axi_wready  ),         
      .m_axi_usr_bid        (m_axi_bid     ), 
      .m_axi_usr_bresp      (m_axi_bresp   ),         
      .m_axi_usr_buser      (m_axi_buser   ),         
      .m_axi_usr_bvalid     (m_axi_bvalid  ),         
      .m_axi_usr_bready     (m_axi_bready  ),         
      .m_axi_usr_arid       (m_axi_arid    ), 
      .m_axi_usr_araddr     (m_axi_araddr  ),         
      .m_axi_usr_arlen      (m_axi_arlen   ),         
      .m_axi_usr_arsize     (m_axi_arsize  ),         
      .m_axi_usr_arburst    (m_axi_arburst ),         
      .m_axi_usr_arlock     (m_axi_arlock_all_prot  ),         
      .m_axi_usr_arcache    (m_axi_arcache ),         
      .m_axi_usr_arprot     (m_axi_arprot  ),         
      .m_axi_usr_arqos      (m_axi_arqos   ),         
      .m_axi_usr_arregion   (m_axi_arregion),         
      .m_axi_usr_aruser     (m_axi_aruser  ),         
      .m_axi_usr_arvalid    (m_axi_arvalid ),         
      .m_axi_usr_arready    (m_axi_arready ),         
      .m_axi_usr_rid        (m_axi_rid     ), 
      .m_axi_usr_rdata      (m_axi_rdata   ),         
      .m_axi_usr_rresp      (m_axi_rresp   ),         
      .m_axi_usr_rlast      (m_axi_rlast   ),         
      .m_axi_usr_ruser      (m_axi_ruser   ),         
      .m_axi_usr_rvalid     (m_axi_rvalid  ),         
      .m_axi_usr_rready     (m_axi_rready  )  
	  
      );
   


endmodule // host_control_master

         


/* host_control_master.v ends here */
