/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Heramb Aligave.
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
 *   This Module Implements Register Module for HN-F & RN-F Bridge for 128KB memory requirement.
 *
 */

`include "defines_common.vh"
`include "chi_defines_regspace.vh"
`include "chi_defines_field.vh"

module chi_register_interface 
  #(
    parameter BRIDGE_MODE = "HN_F", //Allowed values : HN_F, RN_F
    parameter CHI_CHN_REQ_WIDTH     = 121,  //Allowed values : 117-169 ,  
    parameter CHI_CHN_RSP_WIDTH     = 51,  //Allowed values : 51-59,   
    parameter CHI_CHN_DAT_WIDTH     = 705,  //Allowed values : 201-749,   
    parameter CHI_CHN_SNP_WIDTH     = 88,  //Allowed values : 84-100,
    parameter CHI_FLIT_DATA_WIDTH   = 512, //Allowed values :  128, 256, 512
    parameter CHI_CHN_REQ_SNP_WIDTH = ((BRIDGE_MODE == "HN_F") ? CHI_CHN_REQ_WIDTH : CHI_CHN_SNP_WIDTH),
    parameter CHI_CHN_SNP_REQ_WIDTH = ((BRIDGE_MODE == "HN_F") ? CHI_CHN_SNP_WIDTH : CHI_CHN_REQ_WIDTH),
    parameter USR_RST_NUM           = 4, //Allowed values : 32,64   
    parameter LAST_BRIDGE           = 0, // Set this param to 1 for the last bridge instance in the design
    parameter S_AXI_ADDR_WIDTH      = 32, //Allowed values : 32,64   
    parameter S_AXI_DATA_WIDTH      = 32  //Allowed values : 32    
    )
   (
    input 				  clk,
    input 				  resetn, 
    input 				  rst_n, 
    // S_AXI - AXI4-Lite
    input wire [S_AXI_ADDR_WIDTH-1:0] 	  s_axi_awaddr,
    input wire [2:0] 			  s_axi_awprot,
    input wire 				  s_axi_awvalid,
    output wire 			  s_axi_awready,
    input wire [S_AXI_DATA_WIDTH-1:0] 	  s_axi_wdata,
    input wire [(S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input wire 				  s_axi_wvalid,
    output wire 			  s_axi_wready,
    output wire [1:0] 			  s_axi_bresp,
    output wire 			  s_axi_bvalid,
    input wire 				  s_axi_bready,
    input wire [S_AXI_ADDR_WIDTH-1:0] 	  s_axi_araddr,
    input wire [2:0] 			  s_axi_arprot,
    input wire 				  s_axi_arvalid,
    output wire 			  s_axi_arready,
    output wire [S_AXI_DATA_WIDTH-1:0] 	  s_axi_rdata,
    output wire [1:0] 			  s_axi_rresp,
    output wire 			  s_axi_rvalid,
    input wire 				  s_axi_rready,
    // register interface between IH-rb
    input [31:0] 			  ih2rb_c2h_gpio_0_reg, 
    input [31:0] 			  ih2rb_c2h_gpio_1_reg, 
    input [31:0] 			  ih2rb_c2h_gpio_2_reg, 
    input [31:0] 			  ih2rb_c2h_gpio_3_reg, 
    input [31:0] 			  ih2rb_c2h_gpio_4_reg, 
    input [31:0] 			  ih2rb_c2h_gpio_5_reg, 
    input [31:0] 			  ih2rb_c2h_gpio_6_reg, 
    input [31:0] 			  ih2rb_c2h_gpio_7_reg, 
    input [31:0] 			  ih2rb_c2h_gpio_0_reg_we,
    input [31:0] 			  ih2rb_c2h_gpio_1_reg_we,
    input [31:0] 			  ih2rb_c2h_gpio_2_reg_we,
    input [31:0] 			  ih2rb_c2h_gpio_3_reg_we,
    input [31:0] 			  ih2rb_c2h_gpio_4_reg_we,
    input [31:0] 			  ih2rb_c2h_gpio_5_reg_we,
    input [31:0] 			  ih2rb_c2h_gpio_6_reg_we,
    input [31:0] 			  ih2rb_c2h_gpio_7_reg_we,
    input [31:0] 			  ih2rb_c2h_intr_status_0_reg,
    input [31:0] 			  ih2rb_c2h_intr_status_1_reg,
    input [31:0] 			  ih2rb_c2h_intr_status_0_reg_we,
    input [31:0] 			  ih2rb_c2h_intr_status_1_reg_we,
    input [31:0] 			  ih2rb_intr_c2h_toggle_status_0_reg,
    input [31:0] 			  ih2rb_intr_c2h_toggle_status_1_reg,
    input [31:0] 			  ih2rb_intr_c2h_toggle_status_0_reg_we,
    input [31:0] 			  ih2rb_intr_c2h_toggle_status_1_reg_we,
    // register interface between hm-rb

    output reg [31:0] 			  c2h_intr_status_0_reg, 
    output reg [31:0] 			  c2h_intr_status_1_reg,
    output reg [31:0] 			  intr_c2h_toggle_status_0_reg ,
    output reg [31:0] 			  intr_c2h_toggle_status_1_reg ,
    output reg [31:0] 			  intr_c2h_toggle_enable_0_reg ,
    output reg [31:0] 			  intr_c2h_toggle_enable_1_reg ,
    output reg [31:0] 			  intr_c2h_toggle_clear_0_reg ,
    output reg [31:0] 			  intr_c2h_toggle_clear_1_reg ,
    output reg [31:0] 			  c2h_gpio_0_reg ,
    output reg [31:0] 			  c2h_gpio_1_reg ,
    output reg [31:0] 			  c2h_gpio_2_reg ,
    output reg [31:0] 			  c2h_gpio_3_reg ,
    output reg [31:0] 			  c2h_gpio_4_reg ,
    output reg [31:0] 			  c2h_gpio_5_reg ,
    output reg [31:0] 			  c2h_gpio_6_reg ,
    output reg [31:0] 			  c2h_gpio_7_reg ,
    output reg [31:0] 			  c2h_gpio_8_reg ,
    output reg [31:0] 			  c2h_gpio_9_reg ,
    output reg [31:0] 			  c2h_gpio_10_reg ,
    output reg [31:0] 			  c2h_gpio_11_reg ,
    output reg [31:0] 			  c2h_gpio_12_reg ,
    output reg [31:0] 			  c2h_gpio_13_reg ,
    output reg [31:0] 			  c2h_gpio_14_reg ,
    output reg [31:0] 			  c2h_gpio_15_reg ,
    output reg [31:0] 			  h2c_gpio_0_reg ,
    output reg [31:0] 			  h2c_gpio_1_reg ,
    output reg [31:0] 			  h2c_gpio_2_reg ,
    output reg [31:0] 			  h2c_gpio_3_reg ,
    output reg [31:0] 			  h2c_gpio_4_reg ,
    output reg [31:0] 			  h2c_gpio_5_reg ,
    output reg [31:0] 			  h2c_gpio_6_reg ,
    output reg [31:0] 			  h2c_gpio_7_reg ,
    output reg [31:0] 			  intr_h2c_0_reg ,
    output reg [31:0] 			  intr_h2c_1_reg ,
    output reg [31:0] 			  intr_h2c_2_reg ,
    output reg [31:0] 			  intr_h2c_3_reg ,
    output reg [31:0] 			  intr_status_reg ,
    output reg [31:0] 			  intr_error_enable_reg,
    output [5:0] 			  intr_flit_txn_status_reg,
    output reg [31:0] 			  intr_flit_txn_enable_reg,
    output reg [31:0] 			  reset_reg,
    input [31:0] 			  chi_bridge_config,
    input [31:0] 			  chi_bridge_feature_en,
    input 				  CHI_RXREQ_RXSNP_Pending,
    input 				  CHI_RXREQ_RXSNP_Valid,
    input [CHI_CHN_REQ_SNP_WIDTH -1 :0]   CHI_RXREQ_RXSNP_Data,
    input 				  CHI_RXRSP_Pending,
    input 				  CHI_RXRSP_Valid,
    input [CHI_CHN_RSP_WIDTH -1 :0] 	  CHI_RXRSP_Data,
    input 				  CHI_RXDAT_Pending,
    input 				  CHI_RXDAT_Valid,
    input [CHI_CHN_DAT_WIDTH -1 :0] 	  CHI_RXDAT_Data,
    input 				  CHI_TXSNP_TXREQ_flit_transmit,
    input 				  CHI_TXRSP_flit_transmit,
    input 				  syscoreq_i,
    input 				  syscoack_i,
    input 				  CHI_TXDAT_flit_transmit,
    input [3:0] 			  rxdat_current_credits,
    input [3:0] 			  rxrsp_current_credits,
    input [3:0] 			  rxreq_rxsnp_current_credits,
    input [3:0] 			  txdat_current_credits,
    input [3:0] 			  txrsp_current_credits,
    input [3:0] 			  txsnp_txreq_current_credits,
    input [1:0] 			  Tx_Link_Status,
    input [1:0] 			  Rx_Link_Status,
    output 				  configure_bridge,
    output 				  go_to_lp,
    output 				  syscoreq_o,
    output 				  syscoack_o,
    output [4:0] 			  rxreq_rxsnp_refill_credits,
    output [4:0] 			  rxrsp_refill_credits,
    output [4:0] 			  rxdat_refill_credits,
    output wire 			  rxreq_rxsnp_ownership,
    output wire 			  rxrsp_ownership,
    output wire 			  rxdat_ownership,
    output wire [14:0] 			  rxreq_rxsnp_ownership_flip_pulse,
    output wire [14:0] 			  rxrsp_ownership_flip_pulse,
    output wire [14:0] 			  rxdat_ownership_flip_pulse,
    output 				  CHI_TXRSP_Pending,
    output 				  CHI_TXRSP_Valid,
    output [CHI_CHN_RSP_WIDTH -1 :0] 	  CHI_TXRSP_Data,
    output 				  CHI_TXDAT_Pending,
    output 				  CHI_TXDAT_Valid,
    output [CHI_CHN_DAT_WIDTH -1 :0] 	  CHI_TXDAT_Data,
    output 				  CHI_TXSNP_TXREQ_Pending,
    output 				  CHI_TXSNP_TXREQ_Valid,
    output [CHI_CHN_SNP_REQ_WIDTH -1 :0]  CHI_TXSNP_TXREQ_Data,
    output 				  CHI_RXREQ_RXSNP_Received,
    output 				  CHI_RXRSP_Received,
    output 				  CHI_RXDAT_Received

    );


   
   // Registers
   reg [31:0] 				  version_reg ; 
   reg [31:0] 				  last_bridge_reg ;
   reg [31:0] 				  bridge_type_reg ;
   reg [31:0] 				  mode_select_reg ;
   
   reg [31:0] 				  intr_error_status_reg;
   reg [31:0] 				  intr_error_clear_reg ;
   reg [31:0] 				  intr_error_clear_reg_clear ;
   reg [31:0] 				  intr_error_clear_reg_is ;
   reg [31:0] 				  intr_c2h_toggle_clear_0_reg_clear ;
   reg [31:0] 				  intr_c2h_toggle_clear_1_reg_clear ;
   
   reg [31:0] 				  intr_flit_txn_clear_reg;
   reg [31:0] 				  intr_flit_txn_clear_reg_clear;
   reg [31:0] 				  intr_flit_txn_clear_reg_is;
   reg [31:0] 				  chi_bridge_config_reg;
   reg [31:0] 				  chi_bridge_feature_en_reg;
   reg [31:0] 				  chi_bridge_channel_tx_sts_reg;
   reg [31:0] 				  chi_bridge_channel_rx_sts_reg;
   reg [31:0] 				  chi_bridge_configure_reg;
   reg [31:0] 				  chi_bridge_rxreq_rxsnp_refill_credits_reg;
   reg [31:0] 				  chi_bridge_rxrsp_refill_credits_reg;
   reg [31:0] 				  chi_bridge_rxdat_refill_credits_reg;
   reg [31:0] 				  chi_bridge_low_power_reg;
   reg [15:0] 				  chi_bridge_rxrsp_ordering_reg;
   reg [15:0] 				  chi_bridge_rxdat_ordering_reg;
   reg [31:0] 				  chi_bridge_coh_req_reg;
   reg 					  intr_flit_txn_rxreq_rxsnp_status_reg;
   reg 					  intr_flit_txn_rxrsp_status_reg;
   reg 					  intr_flit_txn_rxdat_status_reg;
   reg 					  intr_flit_txn_txsnp_txreq_status_reg;
   reg 					  intr_flit_txn_txrsp_status_reg;
   reg 					  intr_flit_txn_txdat_status_reg;

   localparam NUM_DAT_RAM = (CHI_FLIT_DATA_WIDTH == 512) ? 23 : (CHI_FLIT_DATA_WIDTH == 256) ? 12 : (CHI_FLIT_DATA_WIDTH == 128) ? 7 : 23;
   localparam NUM_RSP_RAM = 2;
   localparam NUM_SNP_REQ_RAM = (BRIDGE_MODE=="HN_F") ? 3 : 4;
   localparam NUM_REQ_SNP_RAM = (BRIDGE_MODE=="HN_F") ? 4 : 3;

   localparam RAM_ADDR_WIDTH = `CLOG2(`MAX_NUM_CREDITS);
   localparam RAM_ADDR_OFFSET_PER_CHANNEL_WIDTH =6 ;
   localparam RXREQ_RXSNP_FLIT_LSW_EN =2 ;
   localparam RAM_ADDR_OFFSET_TXCHN_VAL = 4 ;
   localparam RAM_ADDR_OFFSET_RXCHN_VAL = 3 ;
   
   localparam EFF_DAT_PADDING  = ('h20-((CHI_CHN_DAT_WIDTH) % 'h20));
   localparam EFF_RSP_PADDING  = ('h20-((CHI_CHN_RSP_WIDTH) % 'h20));
   localparam EFF_REQ_SNP_PADDING  = ('h20-((CHI_CHN_REQ_SNP_WIDTH) % 'h20));
   localparam EFF_SNP_REQ_PADDING  = ('h20-((CHI_CHN_SNP_REQ_WIDTH) % 'h20));
   
   localparam EFF_CHI_DAT_WIDTH  = EFF_DAT_PADDING + CHI_CHN_DAT_WIDTH;
   localparam EFF_CHI_RSP_WIDTH  = EFF_RSP_PADDING + CHI_CHN_RSP_WIDTH;
   localparam EFF_CHI_REQ_SNP_WIDTH  = EFF_REQ_SNP_PADDING + CHI_CHN_REQ_SNP_WIDTH;
   localparam EFF_CHI_SNP_REQ_WIDTH  = EFF_SNP_REQ_PADDING + CHI_CHN_SNP_REQ_WIDTH;

   localparam VERSION = 32'h00000100;
   localparam BRIDGE_MSB = ((`CLOG2(128*1024)) - 1 );

   // BRIDGE_TYPE DEFINITION
   //0x0 : AXI3 Bridge in Master Mode
   //0x1 : AXI3 Bridge in Slave Mode
   //0x2 : AXI4 Bridge in Master Mode
   //0x3 : AXI4 Bridge in Slave Mode
   //0x4 : AXI4-lite Bridge in Master Mode
   //0x5 : AXI4-lite Bridge in Slave Mode
   //0x6 : Reserved
   //0x7 : Reserved
   //0x8 : ACE Bridge in Master Mode
   //0x9 : ACE Bridge in Interconnect Mode
   //0xA : CHI Bridge in RN-F Mode
   //0xB : CHI Bridge in HN-F Mode

   localparam [3:0] TYPE = (BRIDGE_MODE=="HN_F") ? 4'hB : 4'hA;
   localparam [31:0] BRIDGE_TYPE = {28'b0,TYPE} ;

   // registering axi4lite signals
   reg [S_AXI_ADDR_WIDTH-1 : 0] 	  axi_awaddr;
   reg                                    axi_awready;
   reg                                    axi_wready;
   reg [1 : 0] 				  axi_bresp;
   reg                                    axi_bvalid;
   reg [S_AXI_ADDR_WIDTH-1 : 0] 	  axi_araddr;
   reg                                    axi_arready;
   reg [S_AXI_DATA_WIDTH-1 : 0] 	  axi_rdata;
   reg [1 : 0] 				  axi_rresp;
   reg                                    axi_rvalid;

   wire 				  rnext;
   reg 					  rdata_ready;
   wire 				  data_ready;
   reg 					  rdata_ready_ff;
   reg 					  non_impl_access;
   wire 				  arvalid_pending_pulse;
   reg 					  arvalid_pending_0;
   reg 					  arvalid_pending_1 ;
   // example-specific design signals
   // local parameter for addressing 32 bit / 64 bit c_s_axi_data_width
   // addr_lsb is used for addressing 32/64 bit registers/memories
   // addr_lsb = 2 for 32 bits (n downto 2)
   // addr_lsb = 3 for 64 bits (n downto 3)

   wire 				  reg_rd_en;
   reg 					  reg_rd_en_d;
   wire 				  mem_wr_en;
   wire 				  mem_rd_en;
   reg 					  mem_rd_en_d;
   wire 				  reg_wr_en;

   reg [RAM_ADDR_WIDTH-1:0] 		  rxdat_ram_raddr;
   reg [RAM_ADDR_WIDTH-1:0] 		  rxrsp_ram_raddr;
   reg [RAM_ADDR_WIDTH-1:0] 		  rxreq_rxsnp_ram_raddr;
   reg [RXREQ_RXSNP_FLIT_LSW_EN-1:0] 	  rxreq_rxsnp_ram_rd_en_ar;
   reg 					  rxrsp_ram_rd_en_ar;
   wire [RXREQ_RXSNP_FLIT_LSW_EN-1:0] 	  ram_req_rd_en_diff;
   wire 				  ram_rsp_rd_en_diff;
   wire [NUM_DAT_RAM-1:0] 		  rxdat_ram_rd_en;
   reg [11:0] 				  rxdat_ram_rd_lsw_ptr;
   reg [11:0] 				  txdat_ram_wr_lsw_ptr;
   reg [NUM_REQ_SNP_RAM-1:0] 		  rxreq_rxsnp_ram_rd_en;
   reg [1:0] 				  rxrsp_ram_rd_en;
   reg [RXREQ_RXSNP_FLIT_LSW_EN-1:0] 	  req_en;
   reg 					  rsp_en;
   reg [NUM_DAT_RAM-1:0] 		  rxdat_ram_rd_en_d;
   reg [NUM_REQ_SNP_RAM-1:0] 		  rxreq_rxsnp_ram_rd_en_d;
   reg 					  rxrsp_ram_rd_en_d;
   reg [NUM_DAT_RAM-1:0] 		  rxdat_ram_rd_en_d1;
   reg [NUM_REQ_SNP_RAM-1:0] 		  rxreq_rxsnp_ram_rd_en_d1;
   reg 					  rxrsp_ram_rd_en_d1;
   reg [NUM_DAT_RAM-1:0] 		  rxdat_ram_rd_en_d2;
   reg [NUM_REQ_SNP_RAM-1:0] 		  rxreq_rxsnp_ram_rd_en_d2;
   reg 					  rxrsp_ram_rd_en_d2;
   reg 					  mem_wr_en_reg;
   reg 					  mem_wr_en_reg_1;
   reg 					  rxdat_ram_rd_en_d3;
   reg 					  rxreq_rxsnp_ram_rd_en_d3;
   reg 					  rxrsp_ram_rd_en_d3;
   wire 				  rxdat_ram_rd_pulse;
   wire 				  rxreq_rxsnp_ram_rd_pulse;
   wire 				  rxrsp_ram_rd_pulse;
   reg 					  rxdat_ram_rd_pulse_1;
   reg 					  rxreq_rxsnp_ram_rd_pulse_1;
   reg 					  rxrsp_ram_rd_pulse_1;
   wire [S_AXI_DATA_WIDTH-1:0] 		  rxreq_rxsnp_ram_rdata;
   wire [S_AXI_DATA_WIDTH-1:0] 		  rxrsp_ram_rdata;
   reg [S_AXI_DATA_WIDTH-1:0] 		  rxdat_ram_rdata_1;
   reg [S_AXI_DATA_WIDTH-1:0] 		  rxreq_rxsnp_ram_rdata_1;
   reg [S_AXI_DATA_WIDTH-1:0] 		  rxrsp_ram_rdata_1;
   reg [S_AXI_DATA_WIDTH-1:0] 		  rxdat_ram_rdata_2;
   reg [S_AXI_DATA_WIDTH-1:0] 		  rxreq_rxsnp_ram_rdata_2;
   reg [S_AXI_DATA_WIDTH-1:0] 		  rxrsp_ram_rdata_2;
   wire [S_AXI_DATA_WIDTH-1:0] 		  rxdat_ram_rdata_seg;
   wire [S_AXI_DATA_WIDTH-1:0] 		  rxreq_rxsnp_ram_rdata_seg;
   wire [S_AXI_DATA_WIDTH-1:0] 		  rxrsp_ram_rdata_seg;
   reg [RAM_ADDR_WIDTH-1:0] 		  txdat_ram_waddr;    
   wire [RAM_ADDR_WIDTH-1:0] 		  txsnp_txreq_ram_waddr;    
   reg [8-1:0] 				  txsnp_txreq_ram_waddr_1;    
   reg [RAM_ADDR_WIDTH-1:0] 		  txrsp_ram_waddr;    
   reg 					  txrsp_ram_wr_en_aw;
   reg [1:0] 				  txsnp_txreq_ram_wr_en_aw;
   wire [RAM_ADDR_OFFSET_PER_CHANNEL_WIDTH-1:0] dat_ram_en_diff;
   wire [RAM_ADDR_OFFSET_PER_CHANNEL_WIDTH-1:0] rsp_ram_en_diff;
   wire [RAM_ADDR_OFFSET_PER_CHANNEL_WIDTH-1:0] snp_ram_en_diff;
   wire [NUM_DAT_RAM-1:0] 			txdat_ram_wr_en;
   reg [NUM_SNP_REQ_RAM-1:0] 			txsnp_txreq_ram_wr_en;
   reg [NUM_RSP_RAM-1:0] 			txrsp_ram_wr_en;
   reg [S_AXI_DATA_WIDTH-1:0] 			txdat_ram_wdata;
   reg [S_AXI_DATA_WIDTH-1:0] 			txrsp_ram_wdata;
   reg [S_AXI_DATA_WIDTH-1:0] 			txsnp_txreq_ram_wdata;
   wire [EFF_CHI_DAT_WIDTH-1:0] 		eff_chi_rxdat_data; 
   wire [EFF_CHI_RSP_WIDTH-1:0] 		eff_chi_rxrsp_data; 
   wire [EFF_CHI_REQ_SNP_WIDTH-1:0] 		eff_chi_rxreq_rxsnp_data; 
   reg [EFF_CHI_DAT_WIDTH-1:0] 			eff_chi_rxdat_data_reg; 
   reg [EFF_CHI_RSP_WIDTH-1:0] 			eff_chi_rxrsp_data_reg; 
   reg [EFF_CHI_REQ_SNP_WIDTH-1:0] 		eff_chi_rxreq_rxsnp_data_reg; 
   reg 						chi_rxdat_valid_reg;
   reg 						chi_rxrsp_valid_reg;
   reg 						chi_rxreq_rxsnp_valid_reg;
   reg [4-1:0] 					write_rxdat_addr;
   reg [4-1:0] 					write_rxreq_rxsnp_addr;
   reg [4-1:0] 					write_rxrsp_addr;
   wire 					chi_txdat_read_reg;
   wire 					chi_txrsp_read_reg;
   wire 					chi_txsnp_txreq_read_reg;
   reg 						chi_txdat_read_reg_1;
   reg 						chi_txrsp_read_reg_1;
   reg 						chi_txsnp_txreq_read_reg_1;
   reg 						txsnp_txreq_flits_transmitted;
   reg 						txrsp_flits_transmitted;
   reg 						txdat_flits_transmitted;

   wire [S_AXI_DATA_WIDTH*NUM_DAT_RAM-1:0] 	txdat_ram_rdata;
   wire [S_AXI_DATA_WIDTH*NUM_RSP_RAM-1:0] 	txrsp_ram_rdata;
   wire [S_AXI_DATA_WIDTH*NUM_SNP_REQ_RAM-1:0] 	txsnp_txreq_ram_rdata;
   wire [RAM_ADDR_WIDTH-1 :0] 			txdat_ram_raddr;
   wire [RAM_ADDR_WIDTH-1 :0] 			txrsp_ram_raddr;
   wire [RAM_ADDR_WIDTH-1 :0] 			txsnp_txreq_ram_raddr;
   wire [14:0] 					take_txrsp_flip_ownership;
   wire [14:0] 					take_txsnp_txreq_flip_ownership;
   wire [14:0] 					take_txdat_flip_ownership;
   reg [31:0] 					txsnp_txreq_ownership_flip_reg;
   reg [31:0] 					txrsp_ownership_flip_reg;
   reg [31:0] 					txdat_ownership_flip_reg;
   reg [31:0] 					txsnp_txreq_ownership_flip_clear;
   reg [31:0] 					txrsp_ownership_flip_clear;
   reg [31:0] 					txdat_ownership_flip_clear;
   wire [14:0] 					take_txdat_ownership;
   wire [14:0] 					take_txsnp_txreq_ownership;
   wire [14:0] 					take_txrsp_ownership;
   wire [14:0] 					txdat_ownership_reg;
   wire [14:0] 					txrsp_ownership_reg;
   wire [14:0] 					txsnp_txreq_ownership_reg;
   reg [14:0] 					rxreq_rxsnp_ownership_reg;
   
   reg [14:0] 					update_rxreq_rxsnp_ownership;
   reg [14:0] 					update_rxdat_ownership;
   reg [14:0] 					update_rxrsp_ownership;
   
   reg [14:0] 					rxdat_ownership_reg;
   reg [14:0] 					rxrsp_ownership_reg;
   reg [31:0] 					rxreq_rxsnp_ownership_flip_reg;
   reg [31:0] 					rxreq_rxsnp_ownership_flip_reg_ff;
   reg [31:0] 					rxdat_ownership_flip_reg;
   reg [31:0] 					rxdat_ownership_flip_reg_ff;
   reg [31:0] 					rxrsp_ownership_flip_reg;
   reg [31:0] 					rxrsp_ownership_flip_reg_ff;
   reg [31:0] 					rxreq_rxsnp_ownership_flip_clear;
   reg [31:0] 					rxdat_ownership_flip_clear;
   reg [31:0] 					rxrsp_ownership_flip_clear;
   wire [11:0] 					awaddr;
   wire [4:0] 					chi_bridge_channel_tx_sts;
   wire [4:0] 					chi_bridge_channel_rx_sts;
   reg [29:0] 					global_order_pos;
   reg [4:0] 					position_occupied;
   reg [14:0] 					rxrsp_ordering_reg;
   reg [14:0] 					rxdat_ordering_reg;
   reg 						dat_wr_0;
   reg 						dat_wr_1;
   reg [14:0] 					txdat_ram_wr_en_t;
   wire 					mem_wr_en_pulse;
   reg [3:0] 					txdat_ram_waddr_record;
   reg [3:0] 					txrsp_ram_waddr_record;
   reg [3:0] 					txsnp_txreq_ram_waddr_record;
   reg 						chi_txdat_read;
   reg 						chi_txrsp_read;
   reg 						chi_txsnp_txreq_read;
   wire 					chi_txdat_flit_valid;
   wire 					chi_txrsp_flit_valid;
   wire 					chi_txsnp_txreq_flit_valid;
   reg [S_AXI_DATA_WIDTH-1:0] 			reg_data_out_1;


   assign eff_chi_rxdat_data = {{EFF_DAT_PADDING{1'b0}}, CHI_RXDAT_Data};
   assign eff_chi_rxrsp_data = {{EFF_RSP_PADDING{1'b0}}, CHI_RXRSP_Data};
   assign eff_chi_rxreq_rxsnp_data = {{EFF_REQ_SNP_PADDING{1'b0}}, CHI_RXREQ_RXSNP_Data};

   // Updating Mecahnism of RO registers
   

   integer 					i,k;

   always @(posedge clk)
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
     end

   always @(posedge clk)
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
     end
   

   always @(posedge clk)
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
	end
     end
   


   always @(posedge clk)
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
	end
     end
   
   always @(posedge clk)
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
	end
     end
   
   always @(posedge clk)
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
	end
     end
   
   always @(posedge clk)
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
	end
     end
   
   always @(posedge clk)
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
	end
     end
   
   always @(posedge clk)
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
	end 
     end
   
   always @(posedge clk)
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
	end 
     end 
   

   
   
   always @(posedge clk)
     begin
	for (i=0; i<32; i=i+1)begin
           if (~rst_n) begin
	      c2h_gpio_8_reg[i] <= 1'b0;
              c2h_gpio_9_reg[i] <= 1'b0;
              c2h_gpio_10_reg[i] <= 1'b0;
              c2h_gpio_11_reg[i] <= 1'b0;
              c2h_gpio_12_reg[i] <= 1'b0;
              c2h_gpio_13_reg[i] <= 1'b0;
              c2h_gpio_14_reg[i] <= 1'b0;
              c2h_gpio_15_reg[i] <= 1'b0;
	   end
           else begin
              c2h_gpio_8_reg[i] <= 1'b0;
              c2h_gpio_9_reg[i] <= 1'b0;
              c2h_gpio_10_reg[i] <= 1'b0;
              c2h_gpio_11_reg[i] <= 1'b0;
              c2h_gpio_12_reg[i] <= 1'b0;
              c2h_gpio_13_reg[i] <= 1'b0;
              c2h_gpio_14_reg[i] <= 1'b0;
              c2h_gpio_15_reg[i] <= 1'b0;
	   end
	end
     end

   always @(posedge clk)
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
     end


   always @(posedge clk)
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
     end



   assign s_axi_awready    = axi_awready;
   assign s_axi_wready     = axi_wready;
   assign s_axi_bresp      = axi_bresp;
   assign s_axi_bvalid     = axi_bvalid;
   assign s_axi_arready    = axi_arready;
   assign s_axi_rdata      = axi_rdata;
   assign s_axi_rresp      = axi_rresp;
   assign s_axi_rvalid     = axi_rvalid;


   wire bnext;
   reg 	awready_state;

   localparam AWREADY_IDLE =0, WAIT_FOR_BNEXT = 1;
   
   
   assign bnext = s_axi_bready & axi_bvalid;
   
   // implement axi_awready generation
   // axi_awready is asserted for one clk clock cycle when both
   // s_axi_awvalid and s_axi_wvalid are asserted. axi_awready is
   // de-asserted when reset is low.

   always @( posedge clk )
     begin
        if ( ~resetn  ) begin
           axi_awready <= 1'b0;
	   awready_state <= AWREADY_IDLE;
	end
        else
          begin
	     case(awready_state)
	       AWREADY_IDLE:
		 if (~axi_awready && s_axi_awvalid && s_axi_wvalid) begin
		    // slave is ready to accept write address when 
		    // there is a valid write address and write data
		    // on the write address and data bus. this design 
		    // expects no outstanding transactions. 
		    axi_awready <= 1'b1;
		    awready_state <= WAIT_FOR_BNEXT;
		 end
		 else begin
		    axi_awready <= 1'b0;
		    awready_state <= AWREADY_IDLE;
		 end // else: !if(~axi_awready && s_axi_awvalid && s_axi_wvalid)
	       WAIT_FOR_BNEXT:
		 if (bnext) begin
		    axi_awready <= 1'b0;
		    awready_state <= AWREADY_IDLE;
		 end
		 else begin
		    axi_awready <= 1'b0;
		    awready_state <= WAIT_FOR_BNEXT;
		 end
	       default:
		 awready_state <= awready_state;
	     endcase
	  end
     end // always @ ( posedge clk )
   

   // implement axi_awaddr latching
   // this process is used to latch the address when both 
   // s_axi_awvalid and s_axi_wvalid are valid. 

   always @( posedge clk )
     begin
        if ( ~resetn  )
          axi_awaddr <= 0;
        else
          begin    
             if (~axi_awready && s_axi_awvalid && s_axi_wvalid)
               // write address latching 
               axi_awaddr <= s_axi_awaddr;
          end 
     end       

   reg wready_state;

   localparam WREADY_IDLE=1,WREADY_ASSERTED=0;
   
   // implement axi_wready generation
   // axi_wready is asserted for one clk clock cycle when both
   // s_axi_awvalid and s_axi_wvalid are asserted. axi_wready is 
   // de-asserted when reset is low. 


   always @( posedge clk )
     begin
        if ( ~resetn  ) begin
           axi_wready <= 1'b0;
	   wready_state <= WREADY_IDLE;
	end
        else
          begin
	     case(wready_state)
	       WREADY_IDLE:
		 if (~axi_wready && s_axi_wvalid && s_axi_awvalid)
		   begin
		      // slave is ready to accept write data when 
		      // there is a valid write address and write data
		      // on the write address and data bus. this design 
		      // expects no outstanding transactions. 
		      axi_wready <= 1'b1;
		      wready_state <= WREADY_ASSERTED;
		   end
		 else begin
		    axi_wready <= 1'b0;
		    wready_state <= WREADY_IDLE;
		 end // else: !if(~axi_wready && s_axi_awvalid && s_axi_wvalid)
	       WREADY_ASSERTED:
		 if (bnext) begin
		    axi_wready <= 1'b0;
		    wready_state <= WREADY_IDLE;
		 end
		 else begin
		    axi_wready <= 1'b0;
		    wready_state <= WREADY_ASSERTED;
		 end
	       default:
		 wready_state <= wready_state;
	     endcase
	  end
     end
   

   // implement memory mapped register select and write logic generation
   // the write data is accepted and written to memory mapped registers when
   // axi_awready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted. write strobes are used to
   // select byte enables of slave registers while writing.
   // these registers are cleared when reset (active low) is applied.
   // slave register write enable is asserted when valid address and data are available
   // and the slave is ready to accept the write address and write data.

   //*******************************************************************************************/
   //Address decoding for Register Bank Write/Read Access or Flit Memory
   //Access
   //*******************************************************************************************/
   assign reg_wr_en = axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid & axi_awaddr[15:12] == 0 ;   
   assign mem_wr_en = axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid & axi_awaddr[15:12] >= 4'h3;
   assign mem_rd_en = ~axi_rvalid && axi_arready && s_axi_arvalid & axi_araddr[15:12] >= 4'h3;


   integer byte_index;

   always @( posedge clk )
     begin
        if ( ~resetn)
          reset_reg <= 32'hFFFFFFFF; 
        else
          begin
             if (reg_wr_en && (~|axi_awaddr[BRIDGE_MSB:6]) && (&axi_awaddr[5:2])) // Writing to RESET_REG
               begin
                  for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                    if ( s_axi_wstrb[byte_index] == 1 ) begin
                       reset_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                    end  
               end
          end
     end
   


   always@( posedge clk )begin
      rxreq_rxsnp_ownership_flip_reg_ff <= rxreq_rxsnp_ownership_flip_reg;
      rxdat_ownership_flip_reg_ff <= rxdat_ownership_flip_reg;
      rxrsp_ownership_flip_reg_ff <= rxrsp_ownership_flip_reg;
   end
   
   assign rxreq_rxsnp_ownership_flip_pulse = rxreq_rxsnp_ownership_flip_reg & (~rxreq_rxsnp_ownership_flip_reg_ff);
   assign rxdat_ownership_flip_pulse = rxdat_ownership_flip_reg & (~rxdat_ownership_flip_reg_ff);
   assign rxrsp_ownership_flip_pulse = rxrsp_ownership_flip_reg & (~rxrsp_ownership_flip_reg_ff);

   assign rxreq_rxsnp_ownership_flip = |rxreq_rxsnp_ownership_flip_reg;
   assign rxdat_ownership_flip = |rxdat_ownership_flip_reg;
   assign rxrsp_ownership_flip = |rxrsp_ownership_flip_reg;
   
   //*******************************************************************************************/
   //Configuration Registers going to Link Layer
   //*******************************************************************************************/

   assign configure_bridge     = chi_bridge_configure_reg[0];
   assign go_to_lp             = chi_bridge_low_power_reg[0];
   assign syscoreq_o           = BRIDGE_MODE == "HN_F" ? 1'b0:  chi_bridge_coh_req_reg[0];
   assign syscoack_o           = BRIDGE_MODE == "RN_F" ? 1'b0:  chi_bridge_coh_req_reg[1];
   assign rxreq_rxsnp_refill_credits = chi_bridge_rxreq_rxsnp_refill_credits_reg[4:0];
   assign rxrsp_refill_credits = chi_bridge_rxrsp_refill_credits_reg[4:0];
   assign rxdat_refill_credits = chi_bridge_rxdat_refill_credits_reg[4:0];
   assign awaddr = axi_awaddr[11:0];
   //*******************************************************************************************/
   //Programmable Registers 
   //*******************************************************************************************/

   always @( posedge clk )
     begin
        if (~rst_n)
          begin
             mode_select_reg                     <=32'h0; 
             intr_h2c_0_reg                      <=32'h0; 
             intr_h2c_1_reg                      <=32'h0; 
             intr_h2c_2_reg                      <=32'h0; 
             intr_h2c_3_reg                      <=32'h0; 
             intr_error_enable_reg               <=32'h0; 
             intr_c2h_toggle_enable_0_reg        <=32'h0;
             intr_c2h_toggle_enable_1_reg        <=32'h0;
             intr_c2h_toggle_clear_0_reg        <=32'h0;
             intr_c2h_toggle_clear_1_reg        <=32'h0;
             chi_bridge_configure_reg            <=32'h0; 
             chi_bridge_rxreq_rxsnp_refill_credits_reg <=32'h0000_000F; 
             chi_bridge_rxrsp_refill_credits_reg <=32'h0000_000F; 
             chi_bridge_rxdat_refill_credits_reg <=32'h0000_000F; 
             chi_bridge_low_power_reg            <=32'h0; 
             chi_bridge_coh_req_reg            <=32'h0; 
             txsnp_txreq_ownership_flip_reg            <=32'h0; 
             txrsp_ownership_flip_reg            <=32'h0; 
             txdat_ownership_flip_reg            <=32'h0; 
             rxreq_rxsnp_ownership_flip_reg            <=32'h0; 
             rxrsp_ownership_flip_reg            <=32'h0; 
             rxdat_ownership_flip_reg            <=32'h0; 
             intr_flit_txn_clear_reg             <=32'h0;
             intr_flit_txn_enable_reg            <=32'h0;
             
          end
        else begin
           if (reg_wr_en)
             begin
                case (awaddr) //offset of register access 
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
                         intr_h2c_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `H2C_INTR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_h2c_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `H2C_INTR_2_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_h2c_2_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `H2C_INTR_3_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_h2c_3_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
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
                  `INTR_ERROR_CLEAR_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_error_clear_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `C2H_INTR_TOGGLE_CLEAR_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_c2h_toggle_clear_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `C2H_INTR_TOGGLE_CLEAR_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_c2h_toggle_clear_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `C2H_INTR_TOGGLE_ENABLE_0_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_c2h_toggle_enable_0_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `C2H_INTR_TOGGLE_ENABLE_1_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_c2h_toggle_enable_1_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `CHI_BRIDGE_CONFIGURE_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         chi_bridge_configure_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `CHI_BRIDGE_RXREQ_RXSNP_REFILL_CREDITS_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         chi_bridge_rxreq_rxsnp_refill_credits_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `CHI_BRIDGE_RXRSP_REFILL_CREDITS_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         chi_bridge_rxrsp_refill_credits_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end
                  `CHI_BRIDGE_RXDAT_REFILL_CREDITS_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         chi_bridge_rxdat_refill_credits_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end   
                  `CHI_BRIDGE_LOW_POWER_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         chi_bridge_low_power_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `CHI_BRIDGE_COHERENT_REQ_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         chi_bridge_coh_req_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TXSNP_TXREQ_OWNERSHIP_FLIP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         txsnp_txreq_ownership_flip_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TXRSP_OWNERSHIP_FLIP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         txrsp_ownership_flip_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end
                  `TXDAT_OWNERSHIP_FLIP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         txdat_ownership_flip_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `RXREQ_RXSNP_OWNERSHIP_FLIP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         rxreq_rxsnp_ownership_flip_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `RXRSP_OWNERSHIP_FLIP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         rxrsp_ownership_flip_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end
                  `RXDAT_OWNERSHIP_FLIP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         rxdat_ownership_flip_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end   
                  `INTR_FLIT_TXN_CLEAR_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_flit_txn_clear_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `INTR_FLIT_TXN_ENABLE_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         intr_flit_txn_enable_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end
		  default: begin end

                endcase
             end
           else begin

	      for (i = 0; i < 15 ; i = i + 1) begin
		 
		 if (rxreq_rxsnp_ownership_flip_clear[i]) begin
		    rxreq_rxsnp_ownership_flip_reg[i] <= 0;
		 end
		 if (rxrsp_ownership_flip_clear[i]) begin
		    rxrsp_ownership_flip_reg[i] <= 0;
		 end
		 if (rxdat_ownership_flip_clear[i]) begin
		    rxdat_ownership_flip_reg[i] <= 0;
		 end
		 
		 if(txsnp_txreq_ownership_flip_clear[i]) begin
		    txsnp_txreq_ownership_flip_reg[i] <= 1'b0;
		 end
		 if(txrsp_ownership_flip_clear[i]) begin
		    txrsp_ownership_flip_reg[i] <= 1'b0;
		 end
		 if(txdat_ownership_flip_clear[i]) begin
		    txdat_ownership_flip_reg[i] <= 1'b0;
		 end
	      end
	      

	      if (intr_flit_txn_status_reg[0] && intr_flit_txn_clear_reg[0])        
                intr_flit_txn_clear_reg[0] <= 1'b0;
	      if (intr_flit_txn_status_reg[1] && intr_flit_txn_clear_reg[1])        
                intr_flit_txn_clear_reg[1] <= 1'b0;
	      if (intr_flit_txn_status_reg[2] && intr_flit_txn_clear_reg[2])        
                intr_flit_txn_clear_reg[2] <= 1'b0;
	      if (intr_flit_txn_status_reg[3] && intr_flit_txn_clear_reg[3])        
                intr_flit_txn_clear_reg[3] <= 1'b0;
	      if (intr_flit_txn_status_reg[4] && intr_flit_txn_clear_reg[4])        
                intr_flit_txn_clear_reg[4] <= 1'b0;
	      if (intr_flit_txn_status_reg[5] && intr_flit_txn_clear_reg[5])        
                intr_flit_txn_clear_reg[5] <= 1'b0;
              intr_error_clear_reg <= intr_error_clear_reg_is;
	      if(chi_bridge_rxreq_rxsnp_refill_credits_reg[4] == 1'b1)
		chi_bridge_rxreq_rxsnp_refill_credits_reg[4] <= 1'b0;
	      if(chi_bridge_rxrsp_refill_credits_reg[4] == 1'b1)
		chi_bridge_rxrsp_refill_credits_reg[4] <= 1'b0;
	      if(chi_bridge_rxdat_refill_credits_reg[4] == 1'b1)
		chi_bridge_rxdat_refill_credits_reg[4] <= 1'b0;
              
	      for (i = 0; i < 32 ; i = i + 1) begin
		 if (intr_c2h_toggle_clear_0_reg_clear[i])begin
                    intr_c2h_toggle_clear_0_reg[i] <= 1'b0;
                 end
		 if(intr_c2h_toggle_clear_1_reg_clear[i])begin
                    intr_c2h_toggle_clear_1_reg[i] <= 1'b0;
                 end
              end
	   end
        end
     end


   always@(*) begin
      intr_error_clear_reg_is = intr_error_clear_reg_clear;
      for (i = 0; i < 32 ; i = i + 1) begin
         if (intr_error_clear_reg_clear[i])
           intr_error_clear_reg_is[i] = 1'b0;
      end                                       
   end                                         


   // Logic to clear TXDAT_OWNERSHIP_FLIP bit
   always @( posedge clk )
     begin
	for (i = 0; i < 15 ; i = i + 1) begin
	   if (~rst_n)
	     txdat_ownership_flip_clear[i] <= 1'b0;

	   else
	     if (~txdat_ownership_flip_clear[i])begin
		if (~txdat_ownership_reg[i] && txdat_ownership_flip_reg[i])
		  txdat_ownership_flip_clear[i] <= 1'b1;

		else
		  txdat_ownership_flip_clear[i] <= 1'b0;

	     end
	     else begin
		if (~reg_wr_en)
		  txdat_ownership_flip_clear[i] <= 1'b0;

		else
		  txdat_ownership_flip_clear[i] <= txdat_ownership_flip_clear[i];

	     end
	end
     end 
   


   // Logic to clear TXRSP_OWNERSHIP_FLIP bit
   always @( posedge clk )
     begin
	for (i = 0; i < 15 ; i = i + 1) begin
	   if (~rst_n)
	     txrsp_ownership_flip_clear[i] <= 1'b0;

	   else
	     if (~txrsp_ownership_flip_clear[i])begin
		if (~txrsp_ownership_reg[i] && txrsp_ownership_flip_reg[i])
		  txrsp_ownership_flip_clear[i] <= 1'b1;

		else
		  txrsp_ownership_flip_clear[i] <= 1'b0;
	     end
	     else begin
		if (~reg_wr_en)
		  txrsp_ownership_flip_clear[i] <= 1'b0;

		else
		  txrsp_ownership_flip_clear[i] <= txrsp_ownership_flip_clear[i];

	     end 
	end 
     end 
   

   // Logic to clear TXSNP_TXREQ_OWNERSHIP_FLIP bit
   always @( posedge clk )
     begin
	for (i = 0; i < 15 ; i = i + 1) begin
	   if (~rst_n)
	     txsnp_txreq_ownership_flip_clear[i] <= 1'b0;

	   else
	     if (~txsnp_txreq_ownership_flip_clear[i])begin
		if (~txsnp_txreq_ownership_reg[i] && txsnp_txreq_ownership_flip_reg[i])
		  txsnp_txreq_ownership_flip_clear[i] <= 1'b1;

		else
		  txsnp_txreq_ownership_flip_clear[i] <= 1'b0;
	     end
	     else begin
		if (~reg_wr_en)
		  txsnp_txreq_ownership_flip_clear[i] <= 1'b0;

		else
		  txsnp_txreq_ownership_flip_clear[i] <= txsnp_txreq_ownership_flip_clear[i];

	     end 
	end
     end



   
   
   always@( posedge clk) 
     begin
	for( k = 0 ; k < 15 ; k = k + 1) begin
	   if(~rst_n) begin
	      rxreq_rxsnp_ownership_reg[k] <= 0;
	   end
	   else if (rxreq_rxsnp_ownership_reg[k])begin
	      rxreq_rxsnp_ownership_reg[k] <= ~rxreq_rxsnp_ownership_flip_pulse[k];
	   end
	   else begin
	      if(update_rxreq_rxsnp_ownership[k]) begin
		 rxreq_rxsnp_ownership_reg[k]<= update_rxreq_rxsnp_ownership[k];
	      end
	      else begin
		 rxreq_rxsnp_ownership_reg[k]<= rxreq_rxsnp_ownership_reg[k];
	      end
	   end
	end
     end

   // Logic to clear RXREQ_RXSNP_OWNERSHIP_FLIP bit
   always @( posedge clk )
     begin
	for (i = 0; i < 15 ; i = i + 1) begin
	   if (~rst_n)
	     rxreq_rxsnp_ownership_flip_clear[i] <= 1'b0;
	   else
	     if (~rxreq_rxsnp_ownership_flip_clear[i])begin
		if (~rxreq_rxsnp_ownership_reg[i] && rxreq_rxsnp_ownership_flip_reg[i])
		  rxreq_rxsnp_ownership_flip_clear[i] <= 1'b1;
		else
		  rxreq_rxsnp_ownership_flip_clear[i] <= 1'b0;
	     end
	     else begin
		if (~reg_wr_en)
		  rxreq_rxsnp_ownership_flip_clear[i] <= 1'b0;
		else
		  rxreq_rxsnp_ownership_flip_clear[i] <= rxreq_rxsnp_ownership_flip_clear[i];
	     end 
	end 
     end


   
   
   always@( posedge clk) 
     begin
	for( k = 0 ; k < 15 ; k = k + 1) begin
	   if(~rst_n) begin
	      rxdat_ownership_reg[k] <= 0;
	   end
	   else if (rxdat_ownership_reg[k])begin
	      rxdat_ownership_reg[k] <= ~rxdat_ownership_flip_pulse[k];
	   end
	   else begin
	      if(update_rxdat_ownership[k]) begin
		 rxdat_ownership_reg[k]<= update_rxdat_ownership[k];
	      end
	      else begin
		 rxdat_ownership_reg[k]<= rxdat_ownership_reg[k];
	      end
	   end
	end
     end

   // Logic to clear RXDAT_OWNERSHIP_FLIP bit
   always @( posedge clk )
     begin
	for (i = 0; i < 15 ; i = i + 1) begin
	   if (~rst_n)
	     rxdat_ownership_flip_clear[i] <= 1'b0;
	   else
	     if (~rxdat_ownership_flip_clear[i])begin
		if (~rxdat_ownership_reg[i] && rxdat_ownership_flip_reg[i])
		  rxdat_ownership_flip_clear[i] <= 1'b1;
		else
		  rxdat_ownership_flip_clear[i] <= 1'b0;
	     end
	     else begin
		if (~reg_wr_en)
		  rxdat_ownership_flip_clear[i] <= 1'b0;
		else
		  rxdat_ownership_flip_clear[i] <= rxdat_ownership_flip_clear[i];
	     end
	end 
     end

   
   
   always@( posedge clk) 
     begin
	for( k = 0 ; k < 15 ; k = k + 1) begin
	   if(~rst_n) begin
	      rxrsp_ownership_reg[k] <= 0;
	   end
	   else if (rxrsp_ownership_reg[k])begin
	      rxrsp_ownership_reg[k] <= ~rxrsp_ownership_flip_pulse[k];
	   end
	   else begin
	      if(update_rxrsp_ownership[k]) begin
		 rxrsp_ownership_reg[k]<= update_rxrsp_ownership[k];
	      end
	      else begin
		 rxrsp_ownership_reg[k]<= rxrsp_ownership_reg[k];
	      end
	   end
	end
     end

   // Logic to clear RXRSP_OWNERSHIP_FLIP bit
   always @( posedge clk )
     begin
	for (i = 0; i < 15 ; i = i + 1) begin
	   if (~rst_n)
	     rxrsp_ownership_flip_clear[i] <= 1'b0;
	   else
	     if (~rxrsp_ownership_flip_clear[i])begin
		if (~rxrsp_ownership_reg[i] && rxrsp_ownership_flip_reg[i])
		  rxrsp_ownership_flip_clear[i] <= 1'b1;
		else
		  rxrsp_ownership_flip_clear[i] <= 1'b0;
	     end
	     else begin
		if (~reg_wr_en)
		  rxrsp_ownership_flip_clear[i] <= 1'b0;
		else
		  rxrsp_ownership_flip_clear[i] <= rxrsp_ownership_flip_clear[i];
	     end
	end
     end
   
   
   
   assign rxreq_rxsnp_ownership = |rxreq_rxsnp_ownership_reg;
   assign rxdat_ownership = |rxdat_ownership_reg;
   assign rxrsp_ownership = |rxrsp_ownership_reg;

   always @( posedge clk )                 
     begin
	for (k = 0; k < 15 ; k = k + 1) begin
           if (~rst_n) begin
	      update_rxreq_rxsnp_ownership[k] <= 0;
	   end                                    
	   else begin          
	      if(chi_rxreq_rxsnp_valid_reg && (k==write_rxreq_rxsnp_addr)) begin
		 update_rxreq_rxsnp_ownership[k] <= 1;
	      end
              else begin
		 update_rxreq_rxsnp_ownership[k] <= 0;
	      end
	   end
	end
     end
   

   always @( posedge clk )                 
     begin
	for (k = 0; k < 15 ; k = k + 1) begin
           if (~rst_n) begin
	      update_rxdat_ownership[k] <= 0;
	   end                                    
	   else begin          
	      if(chi_rxdat_valid_reg && (k==write_rxdat_addr)) begin
		 update_rxdat_ownership[k] <= 1;
	      end
              else begin
		 update_rxdat_ownership[k] <= 0;
	      end
	   end
	end
     end
   


   always @( posedge clk )                 
     begin
	for (k = 0; k < 15 ; k = k + 1) begin
           if (~rst_n) begin
	      update_rxrsp_ownership[k] <= 0;
	   end                                    
	   else begin          
	      if(chi_rxrsp_valid_reg && (k==write_rxrsp_addr)) begin
		 update_rxrsp_ownership[k] <= 1;
	      end
              else begin
		 update_rxrsp_ownership[k] <= 0;
	      end
	   end
	end
     end
   




   // ***********************************************************************************/
   // Implement write response logic generation
   // The write response and response valid signals are asserted by the slave 
   // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
   // This marks the acceptance of address and indicates the status of 
   // write transaction.
   // ***********************************************************************************/

   always @( posedge clk )
     begin
        if ( ~resetn  )
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
               end
          end
     end
   
   


   // Implement axi_arready generation
   // axi_arready is asserted for one S_AXI_ACLK clock cycle when
   // S_AXI_ARVALID is asserted. axi_awready is 
   // de-asserted when reset (active low) is asserted. 
   // The read address is also latched when S_AXI_ARVALID is 
   // asserted. axi_araddr is reset to zero on reset assertion.

   always @( posedge clk )
     begin
        if ( ~resetn  )
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




   
   always @( posedge clk )
     begin
        if ( ~resetn  )
          begin
             axi_arready <= 1'b0;
          end 
        else
          begin    
             if (~axi_arready)begin
          
                if (arvalid_pending_pulse) 
                  axi_arready <= 1'b1;
             end //pending
             else 
               axi_arready <= 1'b0;
          end
     end
   

   
   // Implement memory mapped register select and read logic generation
   // Slave register read enable is asserted when valid address is available
   // and the slave is ready to accept the read address.
   assign reg_rd_en = axi_arready & s_axi_arvalid & ~axi_rvalid & (axi_araddr[15:12] == 0);

   

   

   
   //This serves read address request for all RAMS and even registers too
   always@(posedge clk)
     begin
	if ( ~resetn  )
	  begin
             arvalid_pending_1 <= 1'b0;
	  end 
	else
	  begin
             arvalid_pending_1 <= arvalid_pending_0;
	  end
     end
   


   reg arreq_state;
   
   localparam ARREQ_IDLE=0, ARREQ_PENDING=1;
   
   always@( posedge clk) begin
      if(~resetn) begin
	 arvalid_pending_0 <= 1'b0;
	 arreq_state <= ARREQ_IDLE;
      end
      else begin
	 case (arreq_state)
	   ARREQ_IDLE: 
	     if(~axi_arready && s_axi_arvalid) begin
		arvalid_pending_0 <= 1;
		arreq_state <= ARREQ_PENDING;
	     end
	     else begin
		arvalid_pending_0 <= 0;
		arreq_state <= ARREQ_IDLE;
	     end
	   ARREQ_PENDING:
	     if(rnext) begin
		arvalid_pending_0 <= 0;
		arreq_state <= ARREQ_IDLE;
	     end
	     else begin
		arvalid_pending_0 <= 1;
		arreq_state <= ARREQ_PENDING;
	     end
	   default:
	     begin
		arvalid_pending_0 <= arvalid_pending_0;
		arreq_state<=ARREQ_IDLE;
	     end
	 endcase
      end
   end


   /*
    * FSM To monitor if there is any invalid reg/mem access
    * 
    */

   reg rreq_state;
   reg [3:0] rreq_pending_count;
   
   
   localparam RREQ_IDLE=0, RREQ_PENDING=1;

   // Its max delay from arvalid assertion
   // to finding out which memory/regs is being
   // accesed by user.
   localparam RREQ_MAX_DELAY = 15;
   
   
   always@( posedge clk) begin
      if(~resetn) begin
	 non_impl_access <= 0;
	 rreq_pending_count <= RREQ_MAX_DELAY;
	 rreq_state <= RREQ_IDLE;
      end
      else begin
	 case (rreq_state)
	   RREQ_IDLE: 
	     if(arvalid_pending_pulse) begin
		non_impl_access <= 0;
		rreq_pending_count <= RREQ_MAX_DELAY;
		rreq_state <= RREQ_PENDING;
	     end
	     else begin
		non_impl_access <= 0;
		rreq_state <= RREQ_IDLE;
	     end
	   RREQ_PENDING:
	     if(data_ready) begin
		rreq_state <= RREQ_IDLE;
	     end
	     else if (rreq_pending_count==0) begin
		non_impl_access <= 1;
		rreq_state<=RREQ_IDLE;
	     end
	     else begin
		rreq_pending_count <= rreq_pending_count - 1;
	     end
	   default:
	     rreq_state<=RREQ_IDLE;	
	 endcase
      end
   end
   
   
   assign arvalid_pending_pulse = arvalid_pending_0 & ~arvalid_pending_1;

   
   
   reg link_up;

   
   // **********************************************************************/ 
   //Check link status 
   // **********************************************************************/
   assign chi_bridge_channel_tx_sts= {CHI_TXSNP_TXREQ_flit_transmit, CHI_TXRSP_flit_transmit,CHI_TXDAT_flit_transmit,Tx_Link_Status};
   assign chi_bridge_channel_rx_sts= {chi_rxreq_rxsnp_valid_reg,chi_rxrsp_valid_reg,chi_rxdat_valid_reg,Rx_Link_Status};

   
   always @( posedge clk )
     begin
        if (~rst_n)begin
           chi_bridge_channel_tx_sts_reg <= 0;
           chi_bridge_channel_rx_sts_reg <= 0;
           link_up                       <= 0;
	end
	else begin
           chi_bridge_channel_tx_sts_reg <= {27'b0,chi_bridge_channel_tx_sts};
           chi_bridge_channel_rx_sts_reg <= {27'b0,chi_bridge_channel_rx_sts};
           link_up <= &(Tx_Link_Status) & &(Rx_Link_Status);
	end
     end


   always @( posedge clk )
     begin
	if (~resetn)
          reg_data_out_1 <= 32'b0;
	else
          begin
             if (reg_rd_en) //access to reg block 1
               begin
                  case (axi_araddr[11:0])    
                    `BRIDGE_IDENTIFICATION_REG_ADDR          :reg_data_out_1 <= `BRIDGE_IDENTIFICATION_ID;
                    `LAST_BRIDGE_REG_ADDR                    :reg_data_out_1 <= LAST_BRIDGE; //last_bridge_reg;
                    `VERSION_REG_ADDR                        :reg_data_out_1 <= VERSION; //version_reg;
                    `BRIDGE_TYPE_REG_ADDR                    :reg_data_out_1 <= BRIDGE_TYPE; //bridge_type_reg;
                    `MODE_SELECT_REG_ADDR                    :reg_data_out_1 <= mode_select_reg;
                    `RESET_REG_ADDR                          :reg_data_out_1 <= reset_reg;        
                    `H2C_INTR_0_REG_ADDR                     :reg_data_out_1 <= intr_h2c_0_reg;        
                    `H2C_INTR_1_REG_ADDR                     :reg_data_out_1 <= intr_h2c_1_reg;        
                    `H2C_INTR_2_REG_ADDR                     :reg_data_out_1 <= intr_h2c_2_reg;        
                    `H2C_INTR_3_REG_ADDR                     :reg_data_out_1 <= intr_h2c_3_reg;        
                    `H2C_GPIO_0_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_0_reg;        
                    `H2C_GPIO_1_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_1_reg;
                    `H2C_GPIO_2_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_2_reg;        
                    `H2C_GPIO_3_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_3_reg;
                    `H2C_GPIO_4_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_4_reg;        
                    `H2C_GPIO_5_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_5_reg;
                    `H2C_GPIO_6_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_6_reg;        
                    `H2C_GPIO_7_REG_ADDR                     :reg_data_out_1 <= h2c_gpio_7_reg;
		    `C2H_INTR_0_STATUS_REG_ADDR              :reg_data_out_1 <= c2h_intr_status_0_reg;
                    `C2H_INTR_TOGGLE_ENABLE_0_REG_ADDR       :reg_data_out_1 <= intr_c2h_toggle_enable_0_reg;        
                    `C2H_INTR_TOGGLE_ENABLE_1_REG_ADDR       :reg_data_out_1 <= intr_c2h_toggle_enable_1_reg;
                    `C2H_INTR_TOGGLE_STATUS_0_REG_ADDR       :reg_data_out_1 <= intr_c2h_toggle_status_0_reg;        
		    `C2H_INTR_1_STATUS_REG_ADDR              :reg_data_out_1 <= c2h_intr_status_1_reg;
                    `C2H_INTR_TOGGLE_STATUS_1_REG_ADDR       :reg_data_out_1 <= intr_c2h_toggle_status_1_reg;
                    `C2H_INTR_TOGGLE_CLEAR_0_REG_ADDR        :reg_data_out_1 <= 32'h0;
                    `C2H_INTR_TOGGLE_CLEAR_1_REG_ADDR        :reg_data_out_1 <= 32'h0;
                    `C2H_GPIO_0_REG_ADDR                     :reg_data_out_1 <= c2h_gpio_0_reg;        
                    `C2H_GPIO_1_REG_ADDR                    :reg_data_out_1 <= c2h_gpio_1_reg;        
                    `C2H_GPIO_2_REG_ADDR                     :reg_data_out_1 <= c2h_gpio_2_reg;        
                    `C2H_GPIO_3_REG_ADDR                     :reg_data_out_1 <= c2h_gpio_3_reg;        
                    `C2H_GPIO_4_REG_ADDR                     :reg_data_out_1 <= c2h_gpio_4_reg;        
                    `C2H_GPIO_5_REG_ADDR                     :reg_data_out_1 <= c2h_gpio_5_reg;        
                    `C2H_GPIO_6_REG_ADDR                     :reg_data_out_1 <= c2h_gpio_6_reg;        
                    `C2H_GPIO_7_REG_ADDR                     :reg_data_out_1 <= c2h_gpio_7_reg;        
                    `C2H_GPIO_8_REG_ADDR                     :reg_data_out_1 <= c2h_gpio_8_reg;        
                    `C2H_GPIO_9_REG_ADDR                     :reg_data_out_1 <= c2h_gpio_9_reg;        
                    `C2H_GPIO_10_REG_ADDR                    :reg_data_out_1 <= c2h_gpio_10_reg;        
                    `C2H_GPIO_11_REG_ADDR                    :reg_data_out_1 <= c2h_gpio_11_reg;        
                    `C2H_GPIO_12_REG_ADDR                    :reg_data_out_1 <= c2h_gpio_12_reg;        
                    `C2H_GPIO_13_REG_ADDR                    :reg_data_out_1 <= c2h_gpio_13_reg;        
                    `C2H_GPIO_14_REG_ADDR                    :reg_data_out_1 <= c2h_gpio_14_reg;        
                    `C2H_GPIO_15_REG_ADDR                    :reg_data_out_1 <= c2h_gpio_15_reg;
		    `CHI_BRIDGE_FLIT_CONFIG_REG_ADDR          :reg_data_out_1 <= chi_bridge_config; //chi_bridge_config_reg ;        
                    `CHI_BRIDGE_FEATURE_EN_REG_ADDR          :reg_data_out_1 <= chi_bridge_feature_en; //chi_bridge_feature_en_reg;        
                    `CHI_BRIDGE_CONFIGURE_REG_ADDR           :reg_data_out_1 <= chi_bridge_configure_reg;
                    `CHI_BRIDGE_RXREQ_RXSNP_REFILL_CREDITS_REG_ADDR:reg_data_out_1 <= {27'b0,chi_bridge_rxreq_rxsnp_refill_credits_reg[4:0]};        
                    `CHI_BRIDGE_RXRSP_REFILL_CREDITS_REG_ADDR:reg_data_out_1 <= {27'b0,chi_bridge_rxrsp_refill_credits_reg[4:0]};        
                    `CHI_BRIDGE_RXDAT_REFILL_CREDITS_REG_ADDR:reg_data_out_1 <= {27'b0,chi_bridge_rxdat_refill_credits_reg[4:0]};        
                    `CHI_BRIDGE_LOW_POWER_REG_ADDR           :reg_data_out_1 <= chi_bridge_low_power_reg;        
                    `CHI_BRIDGE_COHERENT_REQ_REG_ADDR        :reg_data_out_1 <= {28'b0,syscoreq_i,syscoack_i,chi_bridge_coh_req_reg[1:0]};        
                    `CHI_BRIDGE_CHANNEL_TX_STS_REG_ADDR      :reg_data_out_1 <= chi_bridge_channel_tx_sts_reg;        
                    `CHI_BRIDGE_CHANNEL_RX_STS_REG_ADDR      :reg_data_out_1 <= chi_bridge_channel_rx_sts_reg;
                    `INTR_STATUS_REG_ADDR                    :reg_data_out_1 <= intr_status_reg;        
                    `INTR_ERROR_STATUS_REG_ADDR              :reg_data_out_1 <= intr_error_status_reg;        
                    `INTR_ERROR_CLEAR_REG_ADDR               :reg_data_out_1 <= 32'b0 ;        
                    `INTR_ERROR_ENABLE_REG_ADDR              :reg_data_out_1 <= intr_error_enable_reg;        
                    `TXSNP_TXREQ_OWNERSHIP_REG_ADDR                :reg_data_out_1 <= {17'b0,txsnp_txreq_ownership_reg[14:0]} ;        
                    `TXRSP_OWNERSHIP_REG_ADDR                :reg_data_out_1 <= {17'b0,txrsp_ownership_reg[14:0]};        
                    `TXDAT_OWNERSHIP_REG_ADDR                :reg_data_out_1 <= {17'b0,txdat_ownership_reg[14:0]};        
                    `TXSNP_TXREQ_OWNERSHIP_FLIP_REG_ADDR           :reg_data_out_1 <= {17'b0,txsnp_txreq_ownership_flip_reg[14:0]};        
                    `TXRSP_OWNERSHIP_FLIP_REG_ADDR           :reg_data_out_1 <= {17'b0,txrsp_ownership_flip_reg[14:0]};        
                    `TXDAT_OWNERSHIP_FLIP_REG_ADDR           :reg_data_out_1 <= {17'b0,txdat_ownership_flip_reg[14:0]};        
                    `RXREQ_RXSNP_OWNERSHIP_REG_ADDR                :reg_data_out_1 <= {17'b0,rxreq_rxsnp_ownership_reg[14:0]};        
                    `RXRSP_OWNERSHIP_REG_ADDR                :reg_data_out_1 <= {17'b0,rxrsp_ownership_reg[14:0]};        
                    `RXDAT_OWNERSHIP_REG_ADDR                :reg_data_out_1 <= {17'b0,rxdat_ownership_reg[14:0]};        
                    `RXREQ_RXSNP_OWNERSHIP_FLIP_REG_ADDR           :reg_data_out_1 <= {17'b0,rxreq_rxsnp_ownership_flip_reg[14:0]};        
                    `RXRSP_OWNERSHIP_FLIP_REG_ADDR           :reg_data_out_1 <= {17'b0,rxrsp_ownership_flip_reg[14:0]};        
                    `RXDAT_OWNERSHIP_FLIP_REG_ADDR           :reg_data_out_1 <= {17'b0,rxdat_ownership_flip_reg[14:0]};        
                    `CHI_BRIDGE_RXREQ_RXSNP_ORDERING_REG_ADDR      :reg_data_out_1 <= 32'b0;        
                    `CHI_BRIDGE_RXRSP_ORDERING_REG_ADDR      :reg_data_out_1 <= {16'b0,chi_bridge_rxrsp_ordering_reg[15:0]};        
                    `CHI_BRIDGE_RXDAT_ORDERING_REG_ADDR      :reg_data_out_1 <= {16'b0,chi_bridge_rxdat_ordering_reg[15:0]};
                    `CHI_BRIDGE_TXSNP_TXREQ_CUR_CREDIT_REG_ADDR    :reg_data_out_1 <= {28'b0,txsnp_txreq_current_credits[3:0]};
                    `CHI_BRIDGE_TXRSP_CUR_CREDIT_REG_ADDR    :reg_data_out_1 <= {28'b0,txrsp_current_credits[3:0]};
                    `CHI_BRIDGE_TXDAT_CUR_CREDIT_REG_ADDR    :reg_data_out_1 <= {28'b0,txdat_current_credits[3:0]};
                    `CHI_BRIDGE_RXREQ_RXSNP_CUR_CREDIT_REG_ADDR    :reg_data_out_1 <= {28'b0,write_rxreq_rxsnp_addr[3:0]};
                    `CHI_BRIDGE_RXRSP_CUR_CREDIT_REG_ADDR    :reg_data_out_1 <= {28'b0,write_rxrsp_addr[3:0]};
                    `CHI_BRIDGE_RXDAT_CUR_CREDIT_REG_ADDR    :reg_data_out_1 <= {28'b0,write_rxdat_addr[3:0]};
                    `INTR_FLIT_TXN_STATUS_REG_ADDR           :reg_data_out_1 <= {26'b0,intr_flit_txn_status_reg};        
                    `INTR_FLIT_TXN_CLEAR_REG_ADDR            :reg_data_out_1 <= intr_flit_txn_clear_reg;        
                    `INTR_FLIT_TXN_ENABLE_REG_ADDR           :reg_data_out_1 <= intr_flit_txn_enable_reg;
                    default                                  :reg_data_out_1 <= 32'b0      ;        
                  endcase
               end
	  end
     end



   /*  
    // Currently only one 32 bit C2H INTR reg is implemented  
    // Currently only one 32 bit C2H GPIO reg is implemented 
    */



   

   always @( posedge clk )
     begin
        if (~rst_n) begin
	   chi_bridge_rxrsp_ordering_reg <= 0;
	   chi_bridge_rxdat_ordering_reg <= 0;
	end
	else begin
	   chi_bridge_rxrsp_ordering_reg <= rxrsp_ordering_reg;
	   chi_bridge_rxdat_ordering_reg <= rxdat_ordering_reg;
	end
     end



   


   always @( posedge clk )
     begin
        intr_error_status_reg <= 32'b0;
     end
   
   


   always @( posedge clk )
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
           end
        end
     end
   
   

   always @( posedge clk )
     begin
        for (i = 1; i < 32 ; i = i + 1) begin
           intr_error_clear_reg_clear[i] <= 1'b0;
        end
     end
   
   always @( posedge clk )
     begin
        if (~resetn) begin
	   reg_rd_en_d <= 1'b0;
	   mem_rd_en_d <= 1'b0;
	end
	else begin
	   reg_rd_en_d <= reg_rd_en;
	   mem_rd_en_d <= mem_rd_en;
	end
     end

   //******************************************************************************************/
   //Transaction Status register implementation
   //Clears with txn_clear bits 
   //Set with Ownership bit set for Receive Channel
   //Set when Flits are sent on Transmit Channel
   //******************************************************************************************/

   always @( posedge clk )
     begin
        if (~rst_n)
          intr_flit_txn_rxreq_rxsnp_status_reg <= 0;
        else begin 
	   if (intr_flit_txn_clear_reg[2])
             intr_flit_txn_rxreq_rxsnp_status_reg <= 0;
           else if (chi_rxreq_rxsnp_valid_reg) 
             intr_flit_txn_rxreq_rxsnp_status_reg <= 1'b1;

        end
     end

   always @( posedge clk )
     begin
        if (~rst_n)
          intr_flit_txn_rxrsp_status_reg <= 0;
        else begin 
           if (intr_flit_txn_clear_reg[1])
             intr_flit_txn_rxrsp_status_reg <= 0;
           else if (chi_rxrsp_valid_reg) 
             intr_flit_txn_rxrsp_status_reg <= 1'b1;
        end
     end

   always @( posedge clk )
     begin
        if (~rst_n)
          intr_flit_txn_rxdat_status_reg <= 0;
        else begin 
	   if (intr_flit_txn_clear_reg[0])
             intr_flit_txn_rxdat_status_reg <= 0;
           else if (chi_rxdat_valid_reg) 
             intr_flit_txn_rxdat_status_reg <= 1'b1;
        end
     end

   always @( posedge clk )
     begin
        if (~rst_n) begin
           txsnp_txreq_flits_transmitted <= 1'b0;
           txrsp_flits_transmitted <= 1'b0;
           txdat_flits_transmitted <= 1'b0;
           chi_txsnp_txreq_read_reg_1 <= 1'b0;
           chi_txrsp_read_reg_1 <= 1'b0;
           chi_txdat_read_reg_1 <= 1'b0;
	end
	else begin
	   chi_txdat_read_reg_1 <= chi_txdat_read_reg;
	   chi_txrsp_read_reg_1 <= chi_txrsp_read_reg;
	   chi_txsnp_txreq_read_reg_1 <= chi_txsnp_txreq_read_reg;
	   if(chi_txsnp_txreq_read_reg_1 & ~chi_txsnp_txreq_read_reg)
             txsnp_txreq_flits_transmitted <= 1'b1;
	   else if (intr_flit_txn_clear_reg [5]  )
             txsnp_txreq_flits_transmitted <= 1'b0;
	   if(chi_txrsp_read_reg_1 & ~chi_txrsp_read_reg)
             txrsp_flits_transmitted <= 1'b1;
	   else if (intr_flit_txn_clear_reg [4]  )
             txrsp_flits_transmitted <= 1'b0;
	   if(chi_txdat_read_reg_1 & ~chi_txdat_read_reg)
             txdat_flits_transmitted <= 1'b1;
	   else if (intr_flit_txn_clear_reg [3]  )
             txdat_flits_transmitted <= 1'b0;
	end
     end
   always @( posedge clk )
     begin
        if (~rst_n)
          intr_flit_txn_txsnp_txreq_status_reg <= 0;
        else begin 
	   if (intr_flit_txn_clear_reg[3])
             intr_flit_txn_txsnp_txreq_status_reg <= 0;
           else  
             intr_flit_txn_txsnp_txreq_status_reg <= txsnp_txreq_flits_transmitted;
        end
     end

   always @( posedge clk )
     begin
        if (~rst_n)
          intr_flit_txn_txrsp_status_reg <= 0;
        else begin 
           if (intr_flit_txn_clear_reg[4])
             intr_flit_txn_txrsp_status_reg <= 0;
           else  
             intr_flit_txn_txrsp_status_reg <= txrsp_flits_transmitted;
        end
     end

   always @( posedge clk )
     begin
        if (~rst_n)
          intr_flit_txn_txdat_status_reg <= 0;
        else begin 
           if (intr_flit_txn_clear_reg[5])
             intr_flit_txn_txdat_status_reg <= 0;
           else  
             intr_flit_txn_txdat_status_reg <= txdat_flits_transmitted;
        end
     end

   assign intr_flit_txn_status_reg = {intr_flit_txn_txsnp_txreq_status_reg,intr_flit_txn_txrsp_status_reg,intr_flit_txn_txdat_status_reg,intr_flit_txn_rxreq_rxsnp_status_reg,intr_flit_txn_rxrsp_status_reg,intr_flit_txn_rxdat_status_reg};


   // INTR_C2H_TOGGLE_CLEAR_0_REG
   always @( posedge clk )
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
		end 
	     end 
	  end 
     end 
   
   


   // INTR_C2H_TOGGLE_CLEAR_1_REG
   always @( posedge clk )
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
		end
	     end 
	  end 
     end 


   //INTR_STATUS_REG
   always @( posedge clk )
     begin
        if (~rst_n)
          intr_status_reg <= 32'b0;
        else
          intr_status_reg <= {29'b0,|({(intr_c2h_toggle_status_0_reg & intr_c2h_toggle_enable_0_reg),(intr_c2h_toggle_status_1_reg & intr_c2h_toggle_enable_1_reg)}),|(intr_error_status_reg), |(intr_flit_txn_status_reg[5:0] )};
     end




   
   // RAMS


   reg [14:0] rxdat_ram_rd_en_t;

   localparam RXDAT_BASE_LSW = 32'h60;
   localparam TXDAT_BASE_LSW = 32'h40;
   integer    j;

   always @(posedge clk)
     begin
	if (~resetn)
          begin
             rxdat_ram_rd_en_t[14:0] <= 0;
	  end
	else begin
           rxdat_ram_rd_en_t[14:0] <= 0;

	   ///Define Offset parameters for ease /0x3600 to ox3b40
	   if (arvalid_pending_pulse & axi_araddr[15:12] == 4'h3) begin

              for (j=0;j<15;j=j+1)
		begin : rxdat_ram
		   if(axi_araddr[11:4] >= (RXDAT_BASE_LSW + 6*j) & axi_araddr[11:4] <= (RXDAT_BASE_LSW + 6*j + 5))
                     rxdat_ram_rd_en_t[j] <= 1'b1;
		end

	   end
	end
     end    


   reg rxdat_selected;
   
   always @(posedge clk)
     begin
	if (~resetn)
          begin
             rxdat_ram_raddr <= 0;
	     rxdat_selected <= 0;
          end
	else begin
	   case(rxdat_ram_rd_en_t)
	     15'b000000000000001: begin 
                rxdat_ram_raddr <= 4'b0000;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h600;
		rxdat_selected <= 1'b1;
             end
	     15'b000000000000010: begin 
                rxdat_ram_raddr <= 4'b0001;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h660;
		rxdat_selected <= 1'b1;
             end
	     15'b000000000000100: begin 
                rxdat_ram_raddr <= 4'b0010;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h6C0;
		rxdat_selected <= 1'b1;
             end
	     15'b000000000001000: begin 
                rxdat_ram_raddr <= 4'b0011;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h720;
		rxdat_selected <= 1'b1;
             end
	     15'b000000000010000: begin 
                rxdat_ram_raddr <= 4'b0100;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h780;
		rxdat_selected <= 1'b1;
             end
	     15'b000000000100000: begin 
                rxdat_ram_raddr <= 4'b0101;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h7E0;
		rxdat_selected <= 1'b1;
             end
	     15'b000000001000000: begin 
                rxdat_ram_raddr <= 4'b0110;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h840;
		rxdat_selected <= 1'b1;
             end
	     15'b000000010000000: begin 
                rxdat_ram_raddr <= 4'b0111;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h8A0;
		rxdat_selected <= 1'b1;
             end
	     15'b000000100000000: begin 
                rxdat_ram_raddr <= 4'b1000;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h900;
		rxdat_selected <= 1'b1;
             end
	     15'b000001000000000: begin 
                rxdat_ram_raddr <= 4'b1001;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h960;
		rxdat_selected <= 1'b1;
             end
	     15'b000010000000000: begin 
                rxdat_ram_raddr <= 4'b1010;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'h9C0;
		rxdat_selected <= 1'b1;
             end
	     15'b000100000000000: begin 
                rxdat_ram_raddr <= 4'b1011;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'hA20;
		rxdat_selected <= 1'b1;
             end
	     15'b001000000000000: begin 
                rxdat_ram_raddr <= 4'b1100;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'hA80;
		rxdat_selected <= 1'b1;
             end
	     15'b010000000000000: begin 
                rxdat_ram_raddr <= 4'b1101;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'hAE0;
		rxdat_selected <= 1'b1;
             end
	     15'b100000000000000: begin 
                rxdat_ram_raddr <= 4'b1110;
                rxdat_ram_rd_lsw_ptr    <= axi_araddr[11:0] - 'hB40;
		rxdat_selected <= 1'b1;
             end
	     15'b000000000000000: begin
		rxdat_ram_raddr <= 4'b0000;
                rxdat_ram_rd_lsw_ptr    <= 0;
		rxdat_selected <= 1'b0;
             end
	   endcase
	end
     end  

   assign rxdat_ram_rd_en[NUM_DAT_RAM-1:0] =  mem_rd_en_d ? ( (rxdat_selected & 1'b1 ) << rxdat_ram_rd_lsw_ptr[7:2]): 0;
   
   reg req_rd;
   reg rsp_rd;

   always @(posedge clk)
     begin
	if (~resetn)
          begin
             rxreq_rxsnp_ram_raddr   <= 'h0;     
             rxreq_rxsnp_ram_rd_en_ar  <= 0;
             rxrsp_ram_raddr   <= 'h0;     
             rxrsp_ram_rd_en_ar  <= 0;
             req_rd <= 1'b0;
             rsp_rd <= 1'b0;
          end
	else begin
           if (arvalid_pending_pulse )
             begin
		//0x3100 
		if(axi_araddr[15:12] ==  4'h3 & axi_araddr[11:8] == 'h01) begin
                   rxreq_rxsnp_ram_raddr   <= axi_araddr[7:4];
                   rxreq_rxsnp_ram_rd_en_ar  <= axi_araddr[3:2];
                   req_rd <= 1'b1;
                end
		else begin
                   rxreq_rxsnp_ram_rd_en_ar <= 0;
                   rxreq_rxsnp_ram_raddr <= 0;
                   req_rd <= 1'b0;
		end
		//0x3400
		if(axi_araddr[15:12] ==  4'h3 & axi_araddr[11:8] == 'h4 ) begin
                   rxrsp_ram_raddr   <= axi_araddr[6:3] ;
                   rxrsp_ram_rd_en_ar  <= axi_araddr[2];
                   rsp_rd              <= 1'b1;
		end
		else begin
                   rxrsp_ram_raddr   <= 'h0;
                   rxrsp_ram_rd_en_ar  <= 0;
                   rsp_rd <= 1'b0;
		end 
             end 
           else begin
              rxreq_rxsnp_ram_rd_en_ar <= 0;
              rxreq_rxsnp_ram_raddr <= 0;
              req_rd <= 1'b0;
              rxrsp_ram_raddr   <= 'h0;
              rxrsp_ram_rd_en_ar  <= 0;
              rsp_rd <= 1'b0;
           end
	end
     end




   //11:8==1
   assign ram_req_rd_en_diff = rxreq_rxsnp_ram_rd_en_ar ;
   always@ (*) begin
      if (arvalid_pending_1)
	req_en = rxreq_rxsnp_ram_rd_en_ar;
      else 
	req_en = 0;

      if(arvalid_pending_1 ) begin
	 case(req_en)
	   2'b00: rxreq_rxsnp_ram_rd_en = req_rd ? 4'b0001 : 0;
	   2'b01: rxreq_rxsnp_ram_rd_en = 4'b0010;
	   2'b10: rxreq_rxsnp_ram_rd_en = 4'b0100;
	   2'b11: rxreq_rxsnp_ram_rd_en = 4'b1000;
	 endcase
      end 
      else 
	rxreq_rxsnp_ram_rd_en = 4'b0000;
   end

   //11:8 ==4
   assign ram_rsp_rd_en_diff = rxrsp_ram_rd_en_ar;
   always@ (*) begin
      if (arvalid_pending_1)
	rsp_en = rxrsp_ram_rd_en_ar;
      else 
	rsp_en = 0;
      if(arvalid_pending_1) 
	rxrsp_ram_rd_en = rsp_rd & ~rxrsp_ram_rd_en_ar ? 2'b01: rsp_rd & rxrsp_ram_rd_en_ar ? 2'b10:0;
      else
	rxrsp_ram_rd_en = 0;
   end



   always@(*) begin
      rxdat_ram_rdata_1 = rxdat_ram_rdata_seg;
   end

   always @ (*) begin
      rxrsp_ram_rdata_1 = rxrsp_ram_rdata_seg;
   end

   always @ (*) begin
      rxreq_rxsnp_ram_rdata_1 = rxreq_rxsnp_ram_rdata_seg;
   end
   

   // Output register or memory read data
   always @( posedge clk )
     begin
        if (~resetn) begin
           rxdat_ram_rd_en_d <= 0;
           rxreq_rxsnp_ram_rd_en_d <= 0;
           rxrsp_ram_rd_en_d <= 0;
           rxdat_ram_rd_en_d1 <= 0;
           rxreq_rxsnp_ram_rd_en_d1 <= 0;
           rxrsp_ram_rd_en_d1 <= 0;
           rxdat_ram_rd_en_d2 <= 0;
           rxreq_rxsnp_ram_rd_en_d2 <= 0;
           rxrsp_ram_rd_en_d2 <= 0;
           rxdat_ram_rd_en_d3 <= 0;
           rxreq_rxsnp_ram_rd_en_d3 <= 0;
           rxrsp_ram_rd_en_d3 <= 0;
	   rxdat_ram_rdata_2 <= 0;
	   rxreq_rxsnp_ram_rdata_2 <= 0;
	   rxrsp_ram_rdata_2 <= 0;

	end
        else
          begin    
	     rxreq_rxsnp_ram_rd_en_d <= rxreq_rxsnp_ram_rd_en;
             rxrsp_ram_rd_en_d <= |rxrsp_ram_rd_en;
	     rxdat_ram_rdata_2 <= rxdat_ram_rdata_1;
	     rxreq_rxsnp_ram_rdata_2 <= rxreq_rxsnp_ram_rdata_1;
	     rxrsp_ram_rdata_2 <= rxrsp_ram_rdata_1;
             rxdat_ram_rd_en_d <= ((rxreq_rxsnp_ram_rd_en_d[NUM_REQ_SNP_RAM-1:0] == 'b0000) &
                                   ~rxrsp_ram_rd_en_d)? rxdat_ram_rd_en : 0;
             rxdat_ram_rd_en_d1 <= rxdat_ram_rd_en_d;
             rxreq_rxsnp_ram_rd_en_d1 <= rxreq_rxsnp_ram_rd_en_d;
             rxrsp_ram_rd_en_d1 <= rxrsp_ram_rd_en_d;
             rxdat_ram_rd_en_d2 <= rxdat_ram_rd_en_d1;
             rxreq_rxsnp_ram_rd_en_d2 <= rxreq_rxsnp_ram_rd_en_d1;
             rxrsp_ram_rd_en_d2 <= rxrsp_ram_rd_en_d1;
             rxdat_ram_rd_en_d3 <= |rxdat_ram_rd_en_d2;
             rxreq_rxsnp_ram_rd_en_d3 <= |rxreq_rxsnp_ram_rd_en_d2;
             rxrsp_ram_rd_en_d3 <= |rxrsp_ram_rd_en_d2;
          end
     end
   

   assign rxdat_ram_rd_pulse =  ~rxdat_ram_rd_en_d3 & |rxdat_ram_rd_en_d2;
   assign rxreq_rxsnp_ram_rd_pulse =  ~rxreq_rxsnp_ram_rd_en_d3 & |rxreq_rxsnp_ram_rd_en_d2;
   assign rxrsp_ram_rd_pulse =  ~rxrsp_ram_rd_en_d3 & |rxrsp_ram_rd_en_d2;

   assign rnext = s_axi_rvalid & s_axi_rready;


   always@(posedge clk) begin
      if ( ~resetn  ) begin
	 rdata_ready<=0;
      end
      else begin
	 rdata_ready <= reg_rd_en_d | rxdat_ram_rd_pulse_1 | rxreq_rxsnp_ram_rd_pulse_1 | rxrsp_ram_rd_pulse_1;  
      end
   end


   assign data_ready = reg_rd_en_d | rxdat_ram_rd_pulse_1 | rxreq_rxsnp_ram_rd_pulse_1 | rxrsp_ram_rd_pulse_1;  

   
   
   always@ (posedge clk) begin
      if ( ~resetn  ) begin
         axi_rvalid <= 0;
         axi_rresp  <= 0;
      end
      else if (~axi_rvalid) begin
	 // rdata_ready is asserted when any of reg/mem access
	 // is valid.
	 axi_rvalid <= data_ready | non_impl_access;
	 axi_rresp  <= 0;
      end
      else if (rnext) begin
	 axi_rvalid <= 0;
	 axi_rresp  <= 0;
      end
      else begin
	 axi_rvalid <= axi_rvalid;
	 axi_rresp  <= axi_rresp;
      end
      
   end

   always @( posedge clk )
     begin
        if ( ~resetn  )
          begin
             axi_rdata  <= 0;
	     rxdat_ram_rd_pulse_1 <= 0;
	     rxreq_rxsnp_ram_rd_pulse_1 <= 0;
	     rxrsp_ram_rd_pulse_1 <= 0;
          end 
        else
          begin    
	     rxdat_ram_rd_pulse_1 <= rxdat_ram_rd_pulse;
	     rxreq_rxsnp_ram_rd_pulse_1 <= rxreq_rxsnp_ram_rd_pulse;
	     rxrsp_ram_rd_pulse_1 <= rxrsp_ram_rd_pulse;
             if (rxdat_ram_rd_pulse_1 )
               axi_rdata <= rxdat_ram_rdata_2;
             else if (rxreq_rxsnp_ram_rd_pulse_1)
               axi_rdata <= rxreq_rxsnp_ram_rdata_2;    
             else if (rxrsp_ram_rd_pulse_1)
               axi_rdata <= rxrsp_ram_rdata_2;    
             else if(reg_rd_en_d)
               axi_rdata <= reg_data_out_1;
	     else if(non_impl_access)
	       axi_rdata <= 0;
	     else 
	       axi_rdata <= axi_rdata;
          end
     end




   //RXDAT RAM

   assign CHI_RXDAT_Received = chi_rxdat_valid_reg;
   assign CHI_RXRSP_Received = chi_rxrsp_valid_reg;
   assign CHI_RXREQ_RXSNP_Received = chi_rxreq_rxsnp_valid_reg;
   always @( posedge clk )
     begin
        if ( ~rst_n  )
          begin
             write_rxdat_addr <= 0;
             write_rxreq_rxsnp_addr <= 0;
             write_rxrsp_addr <= 0;
             eff_chi_rxdat_data_reg <= 0;
             eff_chi_rxrsp_data_reg <= 0;
             eff_chi_rxreq_rxsnp_data_reg <= 0;
	  end
	else begin
           eff_chi_rxdat_data_reg <= eff_chi_rxdat_data;
           eff_chi_rxrsp_data_reg <= eff_chi_rxrsp_data;
           eff_chi_rxreq_rxsnp_data_reg <= eff_chi_rxreq_rxsnp_data;
           chi_rxdat_valid_reg    <= CHI_RXDAT_Valid;
           chi_rxrsp_valid_reg    <= CHI_RXRSP_Valid;
           chi_rxreq_rxsnp_valid_reg    <= CHI_RXREQ_RXSNP_Valid;

           if(chi_rxdat_valid_reg) begin
	      if (write_rxdat_addr == 'hE )
		write_rxdat_addr <= 0;
              else
		write_rxdat_addr <= write_rxdat_addr + 1'b1;
	   end

           if(chi_rxreq_rxsnp_valid_reg) begin
              if(write_rxreq_rxsnp_addr == 'hE ) 
		write_rxreq_rxsnp_addr <= 0;
	      else
		write_rxreq_rxsnp_addr <= write_rxreq_rxsnp_addr + 1'b1;
	   end

           if(chi_rxrsp_valid_reg) begin
              if(write_rxrsp_addr == 'hE ) 
		write_rxrsp_addr <= 0;
              else write_rxrsp_addr <= write_rxrsp_addr + 1'b1;
	   end
	end
     end

   chi_rxflit_ram #(
                    .AWIDTH (`CLOG2(`MAX_NUM_CREDITS)), // Address Width
		    .WWIDTH (EFF_CHI_DAT_WIDTH),  // Data Width
                    .RWIDTH (S_AXI_DATA_WIDTH),  // Data Width
                    .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
                    .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
                    )
   u_rxdat_ram (
                .clk        (clk), 
                .rst_a      (~rst_n), 
                //.en_a       (uc2rb_wr_we), 
                .en_a       (1'b1), 
                .we_a       (chi_rxdat_valid_reg), // Port A is always Write port
                .word_en_a  ({NUM_DAT_RAM{1'b1}}),
                .addr_a     (write_rxdat_addr), 
                .wr_data_a  (eff_chi_rxdat_data_reg), 
                .rd_data_a  (), 
                .OREG_CE_A  (1'b1),                 
                .rst_b      (~rst_n), 
                .en_b       (|rxdat_ram_rd_en), 
                .we_b       (1'b0), // Port B is alwyas Read port 
                .addr_b     (rxdat_ram_raddr), 
                .rd_data_b  (rxdat_ram_rdata_seg), 
                .word_en_b  (rxdat_ram_rd_en),
                .wr_data_b  ({EFF_CHI_DAT_WIDTH{1'b0}}), 
                .OREG_CE_B  (1'b1));


   chi_rxflit_ram #(
                    .AWIDTH (`CLOG2(`MAX_NUM_CREDITS)), // Address Width
                    .WWIDTH (EFF_CHI_REQ_SNP_WIDTH),  // Data Width
                    .RWIDTH (S_AXI_DATA_WIDTH),  // Data Width
                    .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
                    .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
                    )
   u_rxreq_rxsnp_ram (
                      .clk        (clk), 
                      .rst_a      (~rst_n), 
                      .en_a       (1'b1), 
                      .we_a       (chi_rxreq_rxsnp_valid_reg), // Port A is always Write port
                      .word_en_a  ({NUM_REQ_SNP_RAM{1'b1}}),
                      .addr_a     (write_rxreq_rxsnp_addr), 
                      .wr_data_a  (eff_chi_rxreq_rxsnp_data_reg), 
                      .rd_data_a  (), 
                      .OREG_CE_A  (1'b1),                 
                      .rst_b      (~rst_n), 
                      .en_b       (|rxreq_rxsnp_ram_rd_en), 
                      .we_b       (1'b0), // Port B is alwyas Read port 
                      .addr_b     (rxreq_rxsnp_ram_raddr), 
                      .rd_data_b  (rxreq_rxsnp_ram_rdata_seg), 
                      .word_en_b  (rxreq_rxsnp_ram_rd_en),
                      .wr_data_b  ({EFF_CHI_REQ_SNP_WIDTH{1'b0}}), 
                      .OREG_CE_B  (1'b1));

   chi_rxflit_ram #(
                    .AWIDTH (`CLOG2(`MAX_NUM_CREDITS)), // Address Width
		    .WWIDTH (EFF_CHI_RSP_WIDTH),  // Data Width
                    .RWIDTH (S_AXI_DATA_WIDTH),  // Data Width
                    .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
                    .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
                    )
   u_rxrsp_ram (
                .clk        (clk), 
                .rst_a      (~rst_n), 
                .en_a       (1'b1), 
                .we_a       (chi_rxrsp_valid_reg), // Port A is always Write port
                .word_en_a  ({NUM_RSP_RAM{1'b1}}),
                .addr_a     (write_rxrsp_addr), 
                .wr_data_a  (eff_chi_rxrsp_data_reg), 
                .rd_data_a  (), 
                .OREG_CE_A  (1'b1),                 
                .rst_b      (~rst_n), 
                .en_b       (|rxrsp_ram_rd_en), 
                .we_b       (1'b0), // Port B is alwyas Read port 
                .addr_b     (rxrsp_ram_raddr), 
                .rd_data_b  (rxrsp_ram_rdata_seg), 
                .word_en_b  (rxrsp_ram_rd_en),
                .wr_data_b  ({EFF_CHI_RSP_WIDTH{1'b0}}), 
                .OREG_CE_B  (1'b1));


   always @(posedge clk)
     begin
	if (~resetn)
	  begin
             txdat_ram_wr_en_t[14:0]   <= 0;
             mem_wr_en_reg <= 1'b0;
             mem_wr_en_reg_1 <= 1'b0;
             txdat_ram_wdata <= 0;
             dat_wr_0 <= 0;
             dat_wr_1 <= 0;
	  end
	else 
	  begin
             mem_wr_en_reg <= mem_wr_en;
             mem_wr_en_reg_1 <= mem_wr_en_reg;
             txdat_ram_wr_en_t[14:0]   <= 0;
             dat_wr_0 <= 1'b0;
             dat_wr_1 <= dat_wr_0;

             if(axi_awaddr[15:12] ==  4'h4 & axi_awaddr[11:8] >= 'h4 & mem_wr_en & ~mode_select_reg[0])
               begin
		  txdat_ram_wdata  <= s_axi_wdata;
		  dat_wr_0 <= 1'b1;
		  ///Define Offset parameters for ease /0x3600 to ox3b40
		  for (k=0;k<15;k=k+1)
		    begin : txdat_ram
                       if(axi_awaddr[11:4] >= (TXDAT_BASE_LSW + 6*k) & axi_awaddr[11:4] <= (TXDAT_BASE_LSW + 6*k + 5))
			 txdat_ram_wr_en_t[k] <= 1'b1;
		    end
               end
	  end    
     end
   
   
   
   always @(posedge clk)
     begin
	if (~resetn)
	  begin
             txdat_ram_waddr <= 0;
             txdat_ram_wr_lsw_ptr <= 0;
	  end
	else 
	  begin
	     case(txdat_ram_wr_en_t)
	       15'b000000000000001: begin 
                  txdat_ram_waddr <= 4'b0000;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] ;
               end
	       15'b000000000000010: begin 
                  txdat_ram_waddr <= 4'b0001;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h460;
               end
	       15'b000000000000100: begin 
                  txdat_ram_waddr <= 4'b0010;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h4c0;
               end
	       15'b000000000001000: begin 
                  txdat_ram_waddr <= 4'b0011;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h520;
               end
	       15'b000000000010000: begin 
                  txdat_ram_waddr <= 4'b0100;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h580;
               end
	       15'b000000000100000: begin 
                  txdat_ram_waddr <= 4'b0101;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h5e0;
               end
	       15'b000000001000000: begin 
                  txdat_ram_waddr <= 4'b0110;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h640;
               end
	       15'b000000010000000: begin 
                  txdat_ram_waddr <= 4'b0111;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h6a0;
               end
	       15'b000000100000000: begin 
                  txdat_ram_waddr <= 4'b1000;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h700;
               end
	       15'b000001000000000: begin 
                  txdat_ram_waddr <= 4'b1001;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h760;
               end
	       15'b000010000000000: begin 
                  txdat_ram_waddr <= 4'b1010;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h7C0;
               end
	       15'b000100000000000: begin 
                  txdat_ram_waddr <= 4'b1011;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h820;
               end
	       15'b001000000000000: begin 
                  txdat_ram_waddr <= 4'b1100;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h880;
               end
	       15'b010000000000000: begin 
                  txdat_ram_waddr <= 4'b1101;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h8E0;
               end
	       15'b100000000000000: begin 
                  txdat_ram_waddr <= 4'b1110;
                  txdat_ram_wr_lsw_ptr    <= axi_awaddr[11:0] - 'h940;
               end
	       15'b000000000000000: begin
		  txdat_ram_waddr <= 4'b0000;
                  txdat_ram_wr_lsw_ptr    <= 0;
               end
	     endcase
	  end
     end  

   assign txdat_ram_wr_en[NUM_DAT_RAM-1:0] =  dat_wr_1 ? (1'b1 << txdat_ram_wr_lsw_ptr[7:2]) : 0;


   reg rsp_wr;
   reg snp_wr;
   always @(posedge clk)
     begin
	if ( ~resetn)
	  begin
             txrsp_ram_waddr   <= 'h0;     
             txrsp_ram_wr_en_aw  <= 0;
             txsnp_txreq_ram_waddr_1   <= 'h0;     
             txsnp_txreq_ram_wr_en_aw  <= 0;
             txrsp_ram_wdata  <= 0;
             txsnp_txreq_ram_wdata  <= 0;
             rsp_wr <= 1'b0;
             snp_wr <= 1'b0;
	  end
	else begin
           if(axi_awaddr[15:12] ==  4'h4 & axi_awaddr[11:8] == 'h2  & mem_wr_en & ~mode_select_reg[0]) begin
              txrsp_ram_waddr   <= axi_awaddr[6:3] ;
              txrsp_ram_wr_en_aw  <= axi_awaddr[2];
              txrsp_ram_wdata <= s_axi_wdata;
              rsp_wr         <= 1'b1;
           end
           else begin
              txrsp_ram_wr_en_aw <= 0;
              txrsp_ram_waddr <= 0;
              rsp_wr         <= 1'b0;
           end
           if(axi_awaddr[15:12] ==  4'h4 & axi_awaddr[11:8] == 'h1  & mem_wr_en & ~mode_select_reg[0]) begin
              txsnp_txreq_ram_waddr_1   <= axi_awaddr[11:4] - 'h10 ;
              txsnp_txreq_ram_wr_en_aw  <= axi_awaddr[3:2];
              txsnp_txreq_ram_wdata <= s_axi_wdata;
              snp_wr <= 1'b1;
           end
           else begin
              txsnp_txreq_ram_waddr_1   <= 'h00;
              txsnp_txreq_ram_wr_en_aw  <= 0;
              snp_wr <= 1'b0;
           end 
        end
     end

   assign txsnp_txreq_ram_waddr = txsnp_txreq_ram_waddr_1[3:0];

   always@ (*) begin
      if (mem_wr_en_reg)
	txrsp_ram_wr_en = rsp_wr & ~txrsp_ram_wr_en_aw ? 2'b01 : rsp_wr & txrsp_ram_wr_en_aw ? 2'b10 : 0;
      else
	txrsp_ram_wr_en = 0;
   end


   always@ (*) begin
      if (mem_wr_en_reg)
	txsnp_txreq_ram_wr_en = snp_wr ? 1'b1 << txsnp_txreq_ram_wr_en_aw : 0;
      else
	txsnp_txreq_ram_wr_en = 0;
   end


   assign mem_wr_en_pulse = ~mem_wr_en_reg  & mem_wr_en_reg_1;

   

   assign take_txdat_flip_ownership =  txdat_ownership_flip_reg[14:0];
   assign take_txrsp_flip_ownership =  txrsp_ownership_flip_reg[14:0];
   assign take_txsnp_txreq_flip_ownership =  txsnp_txreq_ownership_flip_reg[14:0];
   assign txsnp_txreq_ownership_reg = take_txsnp_txreq_ownership;
   assign txrsp_ownership_reg = take_txrsp_ownership;
   assign txdat_ownership_reg = take_txdat_ownership;


   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //                                               TXDAT RAM                                                        //
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

   chi_txflit_mgmt u_chi_hn_txflit_txdat_mgmt (
					       .clk             (clk), 
					       .rst_n           (rst_n), 
					       .own_flit        (take_txdat_flip_ownership), 
					       .link_up         (link_up),
					       .credit_avail    (CHI_TXDAT_flit_transmit),
					       .read_req        (chi_txdat_read_reg), 
					       .read_addr       (txdat_ram_raddr), 
					       .flit_pending    (CHI_TXDAT_Pending), 
					       .ownership       (take_txdat_ownership),
					       .flit_valid      (chi_txdat_flit_valid)
					       );

   chi_txflit_ram #(
		    .AWIDTH (`CLOG2(`MAX_NUM_CREDITS)), // Address Width
		    .WWIDTH (S_AXI_DATA_WIDTH),  // Data Width
		    .RWIDTH (EFF_CHI_DAT_WIDTH),  // Data Width
		    .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
		    .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
		    )
   u_txdat_ram (
		.clk        (clk), 
		.rst_a      (~rst_n), 
		.en_a       (1'b1), 
		.we_a       (|txdat_ram_wr_en), // One Hot Encoded Write Enable based on Address Decode 
		.word_en_a  (txdat_ram_wr_en),
		.addr_a     (txdat_ram_waddr), 
		.wr_data_a  (txdat_ram_wdata), 
		.rd_data_a  (), 
		.OREG_CE_A  (1'b1),                 
		.rst_b      (~rst_n), 
		.en_b       (chi_txdat_read_reg), //single bit  
		.we_b       (1'b0), // Port B is alwyas Read port 
		.addr_b     (txdat_ram_raddr), //incrementing address no dependency on Number of RAMs
		.rd_data_b  (txdat_ram_rdata), //dependent on i incrementer
		.word_en_b  ({NUM_DAT_RAM{1'b1}}),
		.wr_data_b  (32'b0), 
		.OREG_CE_B  (1'b1));

   assign CHI_TXDAT_Data = link_up ? txdat_ram_rdata[CHI_CHN_DAT_WIDTH-1:0] : 0;
   assign CHI_TXDAT_Valid = chi_txdat_flit_valid;

   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
     //                                               TXRSP RAM                                                        //
     ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

   chi_txflit_mgmt u_chi_hn_txflit_txrsp_mgmt (
					       .clk             (clk), 
					       .rst_n           (rst_n), 
					       .own_flit        (take_txrsp_flip_ownership), 
					       .credit_avail    (CHI_TXRSP_flit_transmit),
					       .link_up         (link_up),
					       .read_req        (chi_txrsp_read_reg), 
					       .read_addr       (txrsp_ram_raddr), 
					       .flit_pending    (CHI_TXRSP_Pending), 
					       .ownership       (take_txrsp_ownership),
					       .flit_valid      (chi_txrsp_flit_valid)
					       );

   chi_txflit_ram #(
		    .AWIDTH (`CLOG2(`MAX_NUM_CREDITS)), // Address Width
		    .WWIDTH (S_AXI_DATA_WIDTH),  // Data Width
		    .RWIDTH (EFF_CHI_RSP_WIDTH),  // Data Width
		    .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
		    .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
		    )
   u_txrsp_ram (
		.clk        (clk), 
		.rst_a      (~rst_n), 
		.en_a       (1'b1), 
		.we_a       (|txrsp_ram_wr_en), // Port A is always Write port
		.word_en_a  (txrsp_ram_wr_en),
		.addr_a     (txrsp_ram_waddr), 
		.wr_data_a  (txrsp_ram_wdata), 
		.rd_data_a  (), 
		.OREG_CE_A  (1'b1),                 
		.rst_b      (~rst_n), 
		.en_b       (chi_txrsp_read_reg), 
		.we_b       (1'b0), // Port B is alwyas Read port 
		.addr_b     (txrsp_ram_raddr), 
		.rd_data_b  (txrsp_ram_rdata), 
		.word_en_b  ({NUM_RSP_RAM{1'b1}}),
		.wr_data_b  (32'b0), 
		.OREG_CE_B  (1'b1));

   assign CHI_TXRSP_Data = link_up ? txrsp_ram_rdata[CHI_CHN_RSP_WIDTH-1:0] : 0;
   assign CHI_TXRSP_Valid = chi_txrsp_flit_valid;

   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
     //                                               TXSNP_TXREQ RAM                                                        //
     ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

   chi_txflit_mgmt u_chi_hn_txflit_txsnp_txreq_mgmt (
						     .clk             (clk), 
						     .rst_n           (rst_n), 
						     .own_flit        (take_txsnp_txreq_flip_ownership), 
						     .credit_avail    (CHI_TXSNP_TXREQ_flit_transmit),
						     .link_up         (link_up),
						     .read_req        (chi_txsnp_txreq_read_reg), 
						     .read_addr       (txsnp_txreq_ram_raddr), 
						     .flit_pending    (CHI_TXSNP_TXREQ_Pending), 
						     .ownership       (take_txsnp_txreq_ownership),
						     .flit_valid      (chi_txsnp_txreq_flit_valid)
						     );

   chi_txflit_ram #(
		    .AWIDTH (`CLOG2(`MAX_NUM_CREDITS)), // Address Width
		    .WWIDTH (S_AXI_DATA_WIDTH),  // Data Width
		    .RWIDTH (EFF_CHI_SNP_REQ_WIDTH),  // Data Width
		    .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
		    .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
		    )
   u_txsnp_txreq_ram (
		      .clk        (clk), 
		      .rst_a      (~rst_n), 
		      .en_a       (1'b1), 
		      .we_a       (|txsnp_txreq_ram_wr_en), // Port A is always Write port
		      .word_en_a  (txsnp_txreq_ram_wr_en),
		      .addr_a     (txsnp_txreq_ram_waddr), 
		      .wr_data_a  (txsnp_txreq_ram_wdata), 
		      .rd_data_a  (), 
		      .OREG_CE_A  (1'b1),                 
		      .rst_b      (~rst_n), 
		      .en_b       (chi_txsnp_txreq_read_reg), 
		      .we_b       (1'b0), // Port B is alwyas Read port 
		      .addr_b     (txsnp_txreq_ram_raddr), 
		      .rd_data_b  (txsnp_txreq_ram_rdata), 
		      .word_en_b  ({NUM_SNP_REQ_RAM{1'b1}}), 
		      .wr_data_b  (32'b0), 
		      .OREG_CE_B  (1'b1));

   assign CHI_TXSNP_TXREQ_Data = link_up ? txsnp_txreq_ram_rdata[CHI_CHN_SNP_REQ_WIDTH-1:0] : 0;
   assign CHI_TXSNP_TXREQ_Valid = chi_txsnp_txreq_flit_valid;



   always @(posedge clk)
     begin
	if ( ~rst_n) begin
           global_order_pos   <= 'h0;     
           position_occupied   <= 'h0;     
	   rxrsp_ordering_reg <= 0;
	   rxdat_ordering_reg <= 0;
        end
	else begin
           global_order_pos   <= 'h0;     
           position_occupied   <= 'h0;     
	   rxrsp_ordering_reg <= 0;
	   rxdat_ordering_reg <= 0;
	end
     end
   
endmodule
