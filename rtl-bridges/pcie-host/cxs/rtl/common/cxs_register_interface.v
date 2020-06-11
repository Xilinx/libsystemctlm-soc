/*
 * Copyright (c) 2020 Xilinx Inc.
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

`include "cxs_defines_regspace.vh"

module cxs_register_interface 
  #(
    parameter       CXS_DATA_FLIT_WIDTH   = 256,//256,512,1024 
    parameter       CXS_CNTL_WIDTH        = 14,// 256
    parameter       USR_RST_NUM           = 4, // 32,64   
    parameter       LAST_BRIDGE           = 0, // Set this param to 1 for the last bridge instance in the design
    parameter       S_AXI_ADDR_WIDTH      = 32, //Allowed values : 32,64   
    parameter       S_AXI_DATA_WIDTH      = 32  //Allowed values : 32    
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
    output reg [31:0] 			  intr_error_enable_reg,
    output [5:0] 			  intr_flit_txn_status_reg,
    output reg [31:0] 			  intr_flit_txn_enable_reg,
    output reg [31:0] 			  reset_reg,
    input [31:0] 			  cxs_bridge_feature_en,
    input 				  CXS_RX_Valid,
    input [CXS_DATA_FLIT_WIDTH -1 :0]     CXS_RX_Data,
    input [CXS_CNTL_WIDTH -1 :0]          CXS_RX_Cntl,
    input  				  CXS_TX_Flit_transmit,
    output 				  CXS_RX_Flit_received,
    input [3:0] 			  rx_current_credits,
    input [3:0] 			  tx_current_credits,
    input [1:0] 			  Tx_Link_Status,
    input [1:0] 			  Rx_Link_Status,
    output 				  cxs_configure_bridge,
    output 				  cxs_go_to_lp_rx,
    output 				  cxs_credit_return_tx,
    output [4:0] 			  rx_refill_credits,
    output wire 			  rx_ownership,
    output [14:0] 			  rx_ownership_flip_pulse,
    output 				  CXS_TX_Valid,
    output [CXS_DATA_FLIT_WIDTH -1 :0] 	  CXS_TX_Data,
    output [CXS_CNTL_WIDTH -1 :0] 	  CXS_TX_Cntl

    );


   
   // Registers
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
   reg [31:0] 				  cxs_bridge_config_reg;
   reg [31:0] 				  cxs_bridge_feature_en_reg;
   reg [31:0] 				  cxs_bridge_channel_tx_sts_reg;
   reg [31:0] 				  cxs_bridge_channel_rx_sts_reg;
   reg [31:0] 				  cxs_bridge_configure_reg;
   reg [31:0] 				  cxs_bridge_rx_refill_credits_reg;
   reg [31:0] 				  cxs_bridge_low_power_reg;
   reg [31:0] 				  intr_status_reg;
   reg 					  intr_flit_txn_rx_status_reg;
   reg 					  intr_flit_txn_tx_status_reg;
  


   localparam NUM_CXS_DATA_RAM = (CXS_DATA_FLIT_WIDTH == 1024) ? 32 :(CXS_DATA_FLIT_WIDTH == 512) ? 16 : (CXS_DATA_FLIT_WIDTH == 256) ? 8 : 16;
   localparam NUM_CXS_DATA_EN_WD = (CXS_DATA_FLIT_WIDTH == 1024) ? 5 :(CXS_DATA_FLIT_WIDTH == 512) ? 4 : (CXS_DATA_FLIT_WIDTH == 256) ? 3 : 3;
   localparam NUM_CXS_CNTL_RAM = (CXS_CNTL_WIDTH >= 32) ? 2 : 1;

   localparam RAM_ADDR_WIDTH = `CLOG2(`MAX_NUM_CREDITS);
   
   localparam END_PTR_LSB_POS = (CXS_CNTL_WIDTH == 14) ? 4 : 
                                (CXS_CNTL_WIDTH == 18) ? 6 :
                                (CXS_CNTL_WIDTH == 22) ? 8 :
				(CXS_CNTL_WIDTH == 27) ? 9 :
				(CXS_CNTL_WIDTH == 33) ? 12 :
                                (CXS_CNTL_WIDTH == 36) ? 12 :
				(CXS_CNTL_WIDTH == 44) ? 16 :
				  4 ; 

   localparam END_PTR_MSB_POS = (CXS_CNTL_WIDTH == 14) ? 5 : 
                                (CXS_CNTL_WIDTH == 18) ? 7 :
                                (CXS_CNTL_WIDTH == 22) ? 9 :
				(CXS_CNTL_WIDTH == 27) ? 11 :
				(CXS_CNTL_WIDTH == 33) ? 14 :
                                (CXS_CNTL_WIDTH == 36) ? 14 :
				(CXS_CNTL_WIDTH == 44) ? 19 :
				  5 ; 
    localparam END_ERR_PTR_LSB_POS = (CXS_CNTL_WIDTH == 14) ? 6 : 
                                (CXS_CNTL_WIDTH == 18) ? 8 :
                                (CXS_CNTL_WIDTH == 22) ? 10 :
				(CXS_CNTL_WIDTH == 27) ? 12 :
				(CXS_CNTL_WIDTH == 33) ? 15 :
                                (CXS_CNTL_WIDTH == 36) ? 15 :
				(CXS_CNTL_WIDTH == 44) ? 20 :
				  6 ; 

   localparam END_ERR_PTR_MSB_POS = (CXS_CNTL_WIDTH == 14) ? 7 : 
                                (CXS_CNTL_WIDTH == 18) ? 9 :
                                (CXS_CNTL_WIDTH == 22) ? 11 :
				(CXS_CNTL_WIDTH == 27) ? 14 :
				(CXS_CNTL_WIDTH == 33) ? 17 :
                                (CXS_CNTL_WIDTH == 36) ? 17 :
				(CXS_CNTL_WIDTH == 44) ? 23 :
				  7 ;				  
		
   localparam EFF_CNTL_PADDING  = ('h20-((CXS_CNTL_WIDTH) % 'h20));
   localparam EFF_CXS_CNTL_WIDTH  = EFF_CNTL_PADDING + CXS_CNTL_WIDTH;

   localparam VERSION = 32'h00000100;
   localparam BRIDGE_MSB = ((`CLOG2(128*1024)) - 1 );

   reg  [EFF_CXS_CNTL_WIDTH-1:0]          eff_cxs_rx_cntl_reg;
   wire [EFF_CXS_CNTL_WIDTH-1:0]          eff_cxs_rx_cntl;
   wire [CXS_DATA_FLIT_WIDTH-1:0]         eff_cxs_rx_data;
   reg  [CXS_DATA_FLIT_WIDTH-1:0]         eff_cxs_rx_data_reg;
   reg                                    cxs_rx_valid_reg;

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
   //0xC : CXS Bridge  

   localparam TYPE = 4'hC;
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

   wire [CXS_DATA_FLIT_WIDTH-1:0] 	  tx_cxs_dat_ram_rdata;
   wire [EFF_CXS_CNTL_WIDTH-1:0] 	  tx_cxs_cntl_ram_rdata;
   reg [RAM_ADDR_WIDTH-1:0] 		  rx_cxs_data_ram_raddr;
   reg [RAM_ADDR_WIDTH-1:0] 		  rx_cxs_data_ram_raddr_c;
   reg                                    rx_ram_data_rd_en_c;           
   reg 					  rx_cxs_cntl_ram_rd_en_ar;
   wire [NUM_CXS_DATA_RAM-1:0] 		  rx_cxs_data_ram_rd_en;
   reg [NUM_CXS_DATA_EN_WD-1:0] 	  rx_cxs_data_ram_rd_lsw_ptr;
   reg [NUM_CXS_DATA_EN_WD-1:0] 	  rx_cxs_data_ram_rd_lsw_ptr_c;
   reg [NUM_CXS_CNTL_RAM-1:0] 		  rx_cxs_cntl_ram_rd_en;
   reg [3:0] 				  rx_cxs_cntl_ram_raddr;
   reg [NUM_CXS_DATA_RAM-1:0] 		  rx_cxs_data_ram_rd_en_d;
   reg [NUM_CXS_DATA_RAM-1:0] 		  rx_cxs_data_ram_rd_en_d1;
   reg [NUM_CXS_DATA_RAM-1:0] 		  rx_cxs_data_ram_rd_en_d2;
   reg [NUM_CXS_CNTL_RAM-1:0]		  rx_cxs_cntl_ram_rd_en_d;
   reg [NUM_CXS_CNTL_RAM-1:0]		  rx_cxs_cntl_ram_rd_en_d1;
   reg [NUM_CXS_CNTL_RAM-1:0]		  rx_cxs_cntl_ram_rd_en_d2;
   reg 					  mem_wr_en_reg;
   reg 					  mem_wr_en_reg_1;
   reg 					  rx_cxs_data_ram_rd_en_d3;
   reg 					  rx_cxs_cntl_ram_rd_en_d3;
   wire 				  rx_cxs_data_ram_rd_pulse;
   wire 				  rx_cxs_cntl_ram_rd_pulse;
   reg 					  rx_cxs_data_ram_rd_pulse_1;
   reg 					  rx_cxs_cntl_ram_rd_pulse_1;
   wire [S_AXI_DATA_WIDTH-1:0] 		  rx_cxs_data_ram_rdata;
   wire [S_AXI_DATA_WIDTH-1:0] 		  rx_cxs_cntl_ram_rdata;
   reg [S_AXI_DATA_WIDTH-1:0] 		  rx_cxs_data_ram_rdata_1;
   reg [S_AXI_DATA_WIDTH-1:0] 		  rx_cxs_cntl_ram_rdata_1;
   reg [S_AXI_DATA_WIDTH-1:0] 		  rx_cxs_data_ram_rdata_2;
   reg [S_AXI_DATA_WIDTH-1:0] 		  rx_cxs_cntl_ram_rdata_2;
   wire [S_AXI_DATA_WIDTH-1:0] 		  rx_cxs_data_ram_rdata_seg;
   wire [S_AXI_DATA_WIDTH-1:0] 		  rx_cxs_cntl_ram_rdata_seg;

   reg [RAM_ADDR_WIDTH-1:0] 		  tx_cxs_dat_ram_waddr;    
   reg [RAM_ADDR_WIDTH-1:0] 		  tx_cxs_dat_ram_waddr_c;    
   reg [NUM_CXS_DATA_EN_WD:0] 		  tx_cxs_dat_ram_wr_lsw_ptr;
   reg [NUM_CXS_DATA_EN_WD:0] 		  tx_cxs_dat_ram_wr_lsw_ptr_c;
   wire [NUM_CXS_DATA_RAM-1:0] 		  tx_cxs_dat_ram_wr_en;
   reg [15-1:0] 		          tx_cxs_dat_ram_wr_addr_sel;
   wire [RAM_ADDR_WIDTH-1:0] 		  tx_cxs_cntl_ram_waddr;    
   reg [8-1:0] 				  tx_cxs_cntl_ram_waddr_1;    
   reg  				  tx_cxs_cntl_ram_wr_en_aw;
   reg [NUM_CXS_CNTL_RAM-1:0] 		  tx_cxs_cntl_ram_wr_en;
   reg                                    tx_cxs_cntl_wr;  
   reg [S_AXI_DATA_WIDTH-1:0] 		  tx_cxs_ram_wdata;
   reg [S_AXI_DATA_WIDTH-1:0] 		  tx_cxs_cntl_ram_wdata;
   reg [4-1:0] 				  write_rx_cxs_dat_addr;
   reg [4-1:0] 				  write_rx_cxs_cntl_addr;
   wire 				  cxs_tx_read_reg;
   reg 					  cxs_tx_read_reg_1;
   reg 					  tx_flits_transmitted;

   wire [S_AXI_DATA_WIDTH*NUM_CXS_DATA_RAM-1:0] tx_cxs_ram_rdata;
   wire [4-1 :0] 			        tx_cxs_dat_ram_raddr;
   wire [14:0] 					take_tx_flip_ownership;
   reg [31:0] 					tx_ownership_flip_reg;
   reg [31:0] 					tx_ownership_flip_clear;
   wire [14:0] 					take_tx_ownership;
   wire [14:0] 					tx_ownership_reg;
   reg [14:0] 					rx_ownership_reg;
   
   reg [14:0] 					update_rx_ownership;
   reg [14:0] 					update_rx_good_tlp_reg;
   reg [14:0] 					update_rx_error_tlp_reg;
   reg [14:0] 					rx_good_tlp_reg;
   reg [14:0] 					rx_error_tlp_reg;
   
   reg [31:0] 					rx_ownership_flip_reg;
   reg [31:0] 					rx_ownership_flip_reg_ff;
   reg [31:0] 					rx_ownership_flip_clear;
   wire [11:0] 					awaddr;
   wire [4:0] 					cxs_bridge_channel_tx_sts;
   wire [4:0] 					cxs_bridge_channel_rx_sts;
   reg 						dat_wr_0;
   reg 						dat_wr_1;
   reg [14:0] 					txdat_ram_wr_en_t;
   wire 					mem_wr_en_pulse;
   reg 						cxs_txdat_read;
   wire 					cxs_txdat_flit_valid;
   reg [S_AXI_DATA_WIDTH-1:0] 			reg_data_out_1;


   assign eff_cxs_rx_data =  CXS_RX_Data;
   assign eff_cxs_rx_cntl = {{EFF_CNTL_PADDING{1'b0}}, CXS_RX_Cntl};

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
   

   // implement axi_awaddr latcxsng
   // this process is used to latch the address when both 
   // s_axi_awvalid and s_axi_wvalid are valid. 

   always @( posedge clk )
     begin
        if ( ~resetn  )
          axi_awaddr <= 0;
        else
          begin    
             if (~axi_awready && s_axi_awvalid && s_axi_wvalid)
               // write address latcxsng 
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
   assign reg_rd_en = axi_arready & s_axi_arvalid & ~axi_rvalid & (axi_araddr[15:12] == 0);
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
      rx_ownership_flip_reg_ff <= rx_ownership_flip_reg;
   end
   
   assign rx_ownership_flip_pulse = rx_ownership_flip_reg & (~rx_ownership_flip_reg_ff);

   wire    rx_ownership_flip;
   assign rx_ownership_flip = |rx_ownership_flip_reg;
   
   //*******************************************************************************************/
   //Configuration Registers going to Link Layer
   //*******************************************************************************************/

   assign cxs_configure_bridge     = cxs_bridge_configure_reg[0];
   assign cxs_go_to_lp_rx          = cxs_bridge_low_power_reg[0];
   assign cxs_credit_return_tx     = cxs_bridge_low_power_reg[0];
   assign rx_refill_credits = cxs_bridge_rx_refill_credits_reg[4:0];
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
             intr_c2h_toggle_clear_0_reg         <=32'h0;
             intr_c2h_toggle_clear_1_reg         <=32'h0;
             cxs_bridge_configure_reg            <=32'h0; 
             cxs_bridge_rx_refill_credits_reg    <=32'h0000_000F; 
             cxs_bridge_low_power_reg            <=32'h0; 
             tx_ownership_flip_reg               <=32'h0; 
             rx_ownership_flip_reg               <=32'h0; 
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
                  `CXS_BRIDGE_CONFIGURE_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         cxs_bridge_configure_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `CXS_BRIDGE_RX_REFILL_CREDITS_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         cxs_bridge_rx_refill_credits_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `CXS_BRIDGE_LOW_POWER_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         cxs_bridge_low_power_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `TX_OWNERSHIP_FLIP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         tx_ownership_flip_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                      end  
                  `RX_OWNERSHIP_FLIP_REG_ADDR: 
                    for ( byte_index = 0; byte_index <= (S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( s_axi_wstrb[byte_index] == 1 ) begin
                         rx_ownership_flip_reg[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
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
		 
		 if (rx_ownership_flip_clear[i]) begin
		    rx_ownership_flip_reg[i] <= 0;
		 end
				 
		 if(tx_ownership_flip_clear[i]) begin
		    tx_ownership_flip_reg[i] <= 1'b0;
		 end
	    end
	   

        //      if(tx_current_credits == 0)
	//        cxs_bridge_low_power_reg[1] <= 1'b0;
	      if(Tx_Link_Status != 2'b11 & tx_current_credits == 0)
	        cxs_bridge_low_power_reg[0] <= 1'b0;

	      if (intr_flit_txn_status_reg[0] && intr_flit_txn_clear_reg[0])        
                intr_flit_txn_clear_reg[0] <= 1'b0;
	      if (intr_flit_txn_status_reg[1] && intr_flit_txn_clear_reg[1])        
                intr_flit_txn_clear_reg[1] <= 1'b0;
              intr_error_clear_reg <= intr_error_clear_reg_is;
	      if(cxs_bridge_rx_refill_credits_reg[4] == 1'b1)
		cxs_bridge_rx_refill_credits_reg[4] <= 1'b0;
              
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


   // Logic to clear TX_OWNERSHIP_FLIP bit
   always @( posedge clk )
     begin
	for (i = 0; i < 15 ; i = i + 1) begin
	   if (~rst_n)
	     tx_ownership_flip_clear[i] <= 1'b0;

	   else
	     if (~tx_ownership_flip_clear[i])begin
		if (~tx_ownership_reg[i] && tx_ownership_flip_reg[i])
		  tx_ownership_flip_clear[i] <= 1'b1;

		else
		  tx_ownership_flip_clear[i] <= 1'b0;

	     end
	     else begin
		if (~reg_wr_en)
		  tx_ownership_flip_clear[i] <= 1'b0;

		else
		  tx_ownership_flip_clear[i] <= tx_ownership_flip_clear[i];

	     end
	end
     end 
   

   
   always@( posedge clk) 
     begin
	for( k = 0 ; k < 15 ; k = k + 1) begin
	   if(~rst_n) begin
	      rx_ownership_reg[k] <= 0;
	   end
	   else if (rx_ownership_reg[k])begin
	      rx_ownership_reg[k] <= ~rx_ownership_flip_pulse[k];
	   end
	   else begin
	      if(update_rx_ownership[k]) begin
		 rx_ownership_reg[k]<= update_rx_ownership[k];
	      end
	      else begin
		 rx_ownership_reg[k]<= rx_ownership_reg[k];
	      end
	   end
	end
     end

  
   // Logic to clear RXDAT_OWNERSHIP_FLIP bit
   always @( posedge clk )
     begin
	for (i = 0; i < 15 ; i = i + 1) begin
	   if (~rst_n)
	     rx_ownership_flip_clear[i] <= 1'b0;
	   else
	     if (~rx_ownership_flip_clear[i])begin
		if (~rx_ownership_reg[i] && rx_ownership_flip_reg[i])
		  rx_ownership_flip_clear[i] <= 1'b1;
		else
		  rx_ownership_flip_clear[i] <= 1'b0;
	     end
	     else begin
		if (~reg_wr_en)
		  rx_ownership_flip_clear[i] <= 1'b0;
		else
		  rx_ownership_flip_clear[i] <= rx_ownership_flip_clear[i];
	     end
	end 
     end

   
   assign rx_ownership = |rx_ownership_reg;
   wire end_of_good_packet;
   wire end_of_error_packet;

   always @( posedge clk )                 
     begin
	for (k = 0; k < 15 ; k = k + 1) begin
           if (~rst_n) begin
	      update_rx_ownership[k] <= 0;
	   end                                    
	   else begin          
	      if(cxs_rx_valid_reg && (k==write_rx_cxs_dat_addr)) begin
		 update_rx_ownership[k] <= 1;
	      end
              else begin
		 update_rx_ownership[k] <= 0;
	      end
	   end
	end
     end
   assign end_of_good_packet = cxs_rx_valid_reg & |(eff_cxs_rx_cntl_reg[END_PTR_MSB_POS: END_PTR_LSB_POS]) &
                               ~(|(eff_cxs_rx_cntl_reg[END_ERR_PTR_MSB_POS: END_ERR_PTR_LSB_POS]));
   assign end_of_error_packet = cxs_rx_valid_reg & |(eff_cxs_rx_cntl_reg[END_PTR_MSB_POS: END_PTR_LSB_POS]) &
                               (|(eff_cxs_rx_cntl_reg[END_ERR_PTR_MSB_POS: END_ERR_PTR_LSB_POS]));
   always @( posedge clk )                 
     begin
	for (k = 0; k < 15 ; k = k + 1) begin
           if (~rst_n) begin
	      update_rx_good_tlp_reg[k] <= 0;
	   end                                    
	   else begin          
	      if(cxs_rx_valid_reg && (k==write_rx_cxs_dat_addr) & end_of_good_packet ) begin
		 update_rx_good_tlp_reg[k] <= 1;
	      end
              else begin
		 update_rx_good_tlp_reg[k] <= 0;
	      end
	   end
	end
     end

 always@( posedge clk) 
     begin
	for( k = 0 ; k < 15 ; k = k + 1) begin
	   if(~rst_n) begin
	      rx_good_tlp_reg[k] <= 0;
	   end
	   else if (rx_good_tlp_reg[k])begin
	      rx_good_tlp_reg[k] <= ~rx_ownership_flip_pulse[k];
	   end
	   else begin
	      if(update_rx_good_tlp_reg[k]) begin
		 rx_good_tlp_reg[k]<= update_rx_good_tlp_reg[k];
	      end
	      else begin
		 rx_good_tlp_reg[k]<= rx_good_tlp_reg[k];
	      end
	   end
	end
     end

  always @( posedge clk )                 
     begin
	for (k = 0; k < 15 ; k = k + 1) begin
           if (~rst_n) begin
	      update_rx_error_tlp_reg[k] <= 0;
	   end                                    
	   else begin          
	      if(cxs_rx_valid_reg && (k==write_rx_cxs_dat_addr) & end_of_error_packet ) begin
		 update_rx_error_tlp_reg[k] <= 1;
	      end
              else begin
		 update_rx_error_tlp_reg[k] <= 0;
	      end
	   end
	end
     end

 always@( posedge clk) 
     begin
	for( k = 0 ; k < 15 ; k = k + 1) begin
	   if(~rst_n) begin
	      rx_error_tlp_reg[k] <= 0;
	   end
	   else if (rx_error_tlp_reg[k])begin
	      rx_error_tlp_reg[k] <= ~rx_ownership_flip_pulse[k];
	   end
	   else begin
	      if(update_rx_error_tlp_reg[k]) begin
		 rx_error_tlp_reg[k]<= update_rx_error_tlp_reg[k];
	      end
	      else begin
		 rx_error_tlp_reg[k]<= rx_error_tlp_reg[k];
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
                  // read address latcxsng
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
   assign cxs_bridge_channel_tx_sts= {CXS_TX_Flit_transmit, Tx_Link_Status};
   assign cxs_bridge_channel_rx_sts= {cxs_rx_valid_reg,Rx_Link_Status};
   assign CXS_RX_Flit_received   = cxs_rx_valid_reg;

   
   always @( posedge clk )
     begin
        if (~rst_n)begin
           cxs_bridge_channel_tx_sts_reg <= 0;
           cxs_bridge_channel_rx_sts_reg <= 0;
           link_up                       <= 0;
	end
	else begin
           cxs_bridge_channel_tx_sts_reg <= {27'b0,cxs_bridge_channel_tx_sts};
           cxs_bridge_channel_rx_sts_reg <= {27'b0,cxs_bridge_channel_rx_sts};
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
		    `CXS_BRIDGE_FLIT_CONFIG_REG_ADDR          :reg_data_out_1 <= cxs_bridge_feature_en; //cxs_bridge_config_reg ;        
                    `CXS_BRIDGE_CONFIGURE_REG_ADDR           :reg_data_out_1 <= cxs_bridge_configure_reg;
                    `CXS_BRIDGE_RX_REFILL_CREDITS_REG_ADDR:reg_data_out_1 <= {27'b0,cxs_bridge_rx_refill_credits_reg[4:0]};        
                    `CXS_BRIDGE_LOW_POWER_REG_ADDR           :reg_data_out_1 <= cxs_bridge_low_power_reg;        
                    `CXS_BRIDGE_CHANNEL_TX_STS_REG_ADDR      :reg_data_out_1 <= cxs_bridge_channel_tx_sts_reg;        
                    `CXS_BRIDGE_CHANNEL_RX_STS_REG_ADDR      :reg_data_out_1 <= cxs_bridge_channel_rx_sts_reg;
                    `INTR_STATUS_REG_ADDR                    :reg_data_out_1 <= intr_status_reg;        
                    `INTR_ERROR_STATUS_REG_ADDR              :reg_data_out_1 <= intr_error_status_reg;        
                    `INTR_ERROR_CLEAR_REG_ADDR               :reg_data_out_1 <= 32'b0 ;        
                    `INTR_ERROR_ENABLE_REG_ADDR              :reg_data_out_1 <= intr_error_enable_reg;        
                    `TX_OWNERSHIP_REG_ADDR                :reg_data_out_1 <= {17'b0,tx_ownership_reg[14:0]} ;        
                    `TX_OWNERSHIP_FLIP_REG_ADDR           :reg_data_out_1 <= {17'b0,tx_ownership_flip_reg[14:0]};        
                    `RX_OWNERSHIP_REG_ADDR                :reg_data_out_1 <= {17'b0,rx_ownership_reg[14:0]};        
                    `RX_OWNERSHIP_FLIP_REG_ADDR           :reg_data_out_1 <= {17'b0,rx_ownership_flip_reg[14:0]};        
                    `RX_GOOD_TLP_REG_ADDR                 :reg_data_out_1 <= {17'b0,rx_good_tlp_reg[14:0]};        
                    `RX_ERROR_TLP_REG_ADDR                :reg_data_out_1 <= {17'b0,rx_error_tlp_reg[14:0]};        
                    `CXS_BRIDGE_TX_CUR_CREDIT_REG_ADDR    :reg_data_out_1 <= {28'b0,tx_current_credits[3:0]};
                    `CXS_BRIDGE_RX_CUR_CREDIT_REG_ADDR    :reg_data_out_1 <= {28'b0,write_rx_cxs_dat_addr[3:0]};
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



   always @( posedge clk ) begin
        if (~rst_n) begin
        intr_error_status_reg <= 32'b0;
     end
       else begin 
	if (intr_error_clear_reg[0])
        intr_error_status_reg <= 1'b0;
	else if (end_of_error_packet)
        intr_error_status_reg <= 1'b1; 
     end
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
          intr_flit_txn_rx_status_reg <= 0;
        else begin 
	   if (intr_flit_txn_clear_reg[0])
             intr_flit_txn_rx_status_reg <= 0;
           else if (cxs_rx_valid_reg) 
             intr_flit_txn_rx_status_reg <= 1'b1;

        end
     end

reg all_flits_sent_1;
wire all_flits_sent;
assign all_flits_sent = |take_tx_ownership;
   always @( posedge clk )
     begin
        if (~rst_n) begin
           tx_flits_transmitted <= 1'b0;
           cxs_tx_read_reg_1 <= 1'b0;
           all_flits_sent_1 <= 1'b0;
	end
	else begin
	   cxs_tx_read_reg_1 <= cxs_tx_read_reg;
	   all_flits_sent_1 <= all_flits_sent;
	   if(all_flits_sent_1 & ~all_flits_sent)
	//   if(cxs_tx_read_reg_1 & ~cxs_tx_read_reg)
             tx_flits_transmitted <= 1'b1;
	   else if (intr_flit_txn_clear_reg [1]  )
             tx_flits_transmitted <= 1'b0;
	 	end
     end
   always @( posedge clk )
     begin
        if (~rst_n)
          intr_flit_txn_tx_status_reg <= 0;
        else begin 
	   if (intr_flit_txn_clear_reg[1])
             intr_flit_txn_tx_status_reg <= 0;
           else  
             intr_flit_txn_tx_status_reg <= tx_flits_transmitted;
        end
     end

   assign intr_flit_txn_status_reg = {intr_flit_txn_tx_status_reg,intr_flit_txn_rx_status_reg};


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
          intr_status_reg <= {29'b0,|({(intr_c2h_toggle_status_0_reg & intr_c2h_toggle_enable_0_reg),(intr_c2h_toggle_status_1_reg & intr_c2h_toggle_enable_1_reg)}),|(intr_error_status_reg), |(intr_flit_txn_status_reg[1:0] )};
     end




   
   // RAMS


   reg [14:0] rx_cxs_data_ram_rd_en_t;

   localparam BASE_DATA_LSW = (NUM_CXS_DATA_RAM == 8) ? 8 :
                              (NUM_CXS_DATA_RAM ==16) ? 4 :
                              (NUM_CXS_DATA_RAM == 32) ? 2 : 0;
   localparam BASE_DATA_LSB = (NUM_CXS_DATA_RAM == 8) ? 5 :
                               (NUM_CXS_DATA_RAM ==16) ? 6 :
                               (NUM_CXS_DATA_RAM == 32) ? 7 : 0;
   integer    j;

   always @(posedge clk)
     begin
	if (~resetn)
          begin
            rx_cxs_data_ram_raddr_c <= 0;
	    rx_ram_data_rd_en_c <= 1'b0;
	  end
	else begin
           rx_cxs_data_ram_raddr_c <= 0;

	    rx_ram_data_rd_en_c <= 1'b0;
	   if (arvalid_pending_pulse & axi_araddr[15:12] == 4'h3 & 
	    axi_araddr[11:8] >= 'h1 &  axi_araddr[11:8] <= 'h8 ) begin
	    rx_ram_data_rd_en_c <= 1'b1;
            if(axi_araddr[11:BASE_DATA_LSB] >= (BASE_DATA_LSW ) & axi_araddr[11:BASE_DATA_LSB] <= (BASE_DATA_LSW +'h0E))
	   rx_cxs_data_ram_raddr_c <= axi_araddr[11:BASE_DATA_LSB] - BASE_DATA_LSW;


	   end
	end
     end    

 always@ (posedge clk)begin
	if (~resetn)
	  begin
              rx_cxs_data_ram_rd_lsw_ptr_c <= 0;
	      end
	      else begin
              rx_cxs_data_ram_rd_lsw_ptr_c <= ( NUM_CXS_DATA_RAM == 8) ? axi_araddr[4:2] :
	                                    ( NUM_CXS_DATA_RAM == 16 ) ? axi_araddr[5:2] : 
	                                    ( NUM_CXS_DATA_RAM == 32) ? axi_araddr[6:2] : 0; 
       end
   end

reg rx_cxs_data_selected;

   
   
   always @(posedge clk)
     begin
	if (~resetn)
          begin
             rx_cxs_data_ram_raddr <= 0;
	     rx_cxs_data_selected <= 0;
	     rx_cxs_data_ram_rd_lsw_ptr <= 0;
          end
	else begin
             rx_cxs_data_ram_raddr <= rx_cxs_data_ram_raddr_c;
	     rx_cxs_data_selected <= rx_ram_data_rd_en_c;
	     rx_cxs_data_ram_rd_lsw_ptr <= rx_cxs_data_ram_rd_lsw_ptr_c;
	end
     end  


   assign rx_cxs_data_ram_rd_en[NUM_CXS_DATA_RAM-1:0] =  mem_rd_en_d ? 
                                  ( NUM_CXS_DATA_RAM == 8) ?
				    ((rx_cxs_data_selected & 1'b1) << rx_cxs_data_ram_rd_lsw_ptr[NUM_CXS_DATA_EN_WD-1:0]) :
				  ( NUM_CXS_DATA_RAM == 16) ? 
				    ((rx_cxs_data_selected & 1'b1) << rx_cxs_data_ram_rd_lsw_ptr[NUM_CXS_DATA_EN_WD-1:0]) :
				   ( NUM_CXS_DATA_RAM == 32) ? 
				    ((rx_cxs_data_selected & 1'b1) << rx_cxs_data_ram_rd_lsw_ptr[NUM_CXS_DATA_EN_WD-1:0]) :
				      0 : 0;


  // assign rx_cxs_data_ram_rd_en[NUM_CXS_DATA_RAM-1:0] =  mem_rd_en_d ? ( (rx_cxs_data_selected & 1'b1 ) << rx_cxs_data_ram_rd_lsw_ptr[7:2]): 0;
   


   always@(*) begin
      rx_cxs_data_ram_rdata_1 = rx_cxs_data_ram_rdata_seg;
   end

 
   reg cxs_cntl_rd;

   always @(posedge clk)
     begin
	if (~resetn)
          begin
             rx_cxs_cntl_ram_raddr   <= 'h0;     
             rx_cxs_cntl_ram_rd_en_ar  <= 0;
             cxs_cntl_rd <= 1'b0;
          end
	else begin
           if (arvalid_pending_pulse )
             begin
	//0x3600
		if(axi_araddr[15:12] ==  4'h3 & axi_araddr[11:8] == 'hc ) begin
                   rx_cxs_cntl_ram_raddr   <= ( NUM_CXS_CNTL_RAM == 1) ? axi_araddr[5:2] : axi_araddr[6:3] ;
                   rx_cxs_cntl_ram_rd_en_ar  <= ( NUM_CXS_CNTL_RAM == 1) ? 1'b1: axi_araddr[2];
                   cxs_cntl_rd              <= 1'b1;
		end
		else begin
                   rx_cxs_cntl_ram_raddr   <= 'h0;
                   rx_cxs_cntl_ram_rd_en_ar  <= 0;
                   cxs_cntl_rd <= 1'b0;
		end 
             end 
           else begin
              rx_cxs_cntl_ram_rd_en_ar <= 0;
              rx_cxs_cntl_ram_raddr <= 0;
              cxs_cntl_rd <= 1'b0;
           end
	end
     end



   //11:8 ==6
   always@ (*) begin
      if(arvalid_pending_1) 
	rx_cxs_cntl_ram_rd_en = cxs_cntl_rd ?
	                       (NUM_CXS_CNTL_RAM == 2) ? 
			       ~rx_cxs_cntl_ram_rd_en_ar ? 2'b01: 2'b10 :
			       rx_cxs_cntl_ram_rd_en_ar : 0;
      else
	rx_cxs_cntl_ram_rd_en = 0;
   end


 always @ (*) begin
      rx_cxs_cntl_ram_rdata_1 = rx_cxs_cntl_ram_rdata_seg;
   end

 // Output register or memory read data
   always @( posedge clk )
     begin
        if (~resetn) begin
           rx_cxs_data_ram_rd_en_d <= 0;
           rx_cxs_data_ram_rd_en_d1 <= 0;
           rx_cxs_data_ram_rd_en_d2 <= 0;
           rx_cxs_data_ram_rd_en_d3 <= 0;
	   rx_cxs_data_ram_rdata_2 <= 0;
           rx_cxs_cntl_ram_rd_en_d <= 0;
           rx_cxs_cntl_ram_rd_en_d1 <= 0;
           rx_cxs_cntl_ram_rd_en_d2 <= 0;
           rx_cxs_cntl_ram_rd_en_d3 <= 0;
	   rx_cxs_cntl_ram_rdata_2 <= 0;

	end
        else
          begin    
	     rx_cxs_cntl_ram_rdata_2 <= rx_cxs_cntl_ram_rdata_1;
             rx_cxs_cntl_ram_rd_en_d <= |rx_cxs_cntl_ram_rd_en;
             rx_cxs_cntl_ram_rd_en_d1 <= rx_cxs_cntl_ram_rd_en_d;
             rx_cxs_cntl_ram_rd_en_d2 <= rx_cxs_cntl_ram_rd_en_d1;
             rx_cxs_cntl_ram_rd_en_d3 <= |rx_cxs_cntl_ram_rd_en_d2;
	     rx_cxs_data_ram_rdata_2 <= rx_cxs_data_ram_rdata_1;
             rx_cxs_data_ram_rd_en_d <= (~rx_cxs_cntl_ram_rd_en_d)? rx_cxs_data_ram_rd_en : 0;
             rx_cxs_data_ram_rd_en_d1 <= rx_cxs_data_ram_rd_en_d;
             rx_cxs_data_ram_rd_en_d2 <= rx_cxs_data_ram_rd_en_d1;
             rx_cxs_data_ram_rd_en_d3 <= |rx_cxs_data_ram_rd_en_d2;
          end
     end

    

   assign rx_cxs_data_ram_rd_pulse =  ~rx_cxs_data_ram_rd_en_d3 & |rx_cxs_data_ram_rd_en_d2;
   assign rx_cxs_cntl_ram_rd_pulse =  ~rx_cxs_cntl_ram_rd_en_d3 & |rx_cxs_cntl_ram_rd_en_d2;

   assign rnext = s_axi_rvalid & s_axi_rready;

 always @( posedge clk )
     begin
        if ( ~resetn  )
          begin
             axi_rdata  <= 0;
	     rx_cxs_data_ram_rd_pulse_1 <= 0;
	     rx_cxs_cntl_ram_rd_pulse_1 <= 0;
          end 
        else
          begin    
	     rx_cxs_data_ram_rd_pulse_1 <= rx_cxs_data_ram_rd_pulse;
	     rx_cxs_cntl_ram_rd_pulse_1 <= rx_cxs_cntl_ram_rd_pulse;
             if (rx_cxs_data_ram_rd_pulse_1 )
               axi_rdata <= rx_cxs_data_ram_rdata_2;
             else if (rx_cxs_cntl_ram_rd_pulse_1)
               axi_rdata <= rx_cxs_cntl_ram_rdata_2;    
             else if(reg_rd_en_d)
               axi_rdata <= reg_data_out_1;
	     else if(non_impl_access)
	       axi_rdata <= 0;
	     else 
	       axi_rdata <= axi_rdata;
          end
     end


   always@(posedge clk) begin
      if ( ~resetn  ) begin
	 rdata_ready<=0;
      end
      else begin
	 rdata_ready <= reg_rd_en_d | rx_cxs_data_ram_rd_pulse_1 | rx_cxs_cntl_ram_rd_pulse_1;  
      end
   end


   assign data_ready = reg_rd_en_d | rx_cxs_data_ram_rd_pulse_1 | rx_cxs_cntl_ram_rd_pulse_1;  

   
   
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

  



   //RXDAT RAM

    always @( posedge clk )
     begin
        if ( ~rst_n  )
          begin
             write_rx_cxs_dat_addr  <= 0;
             write_rx_cxs_cntl_addr <= 0;
             eff_cxs_rx_data_reg    <= 0;
             eff_cxs_rx_cntl_reg    <= 0;
	     cxs_rx_valid_reg       <= 0;
	  end
	else begin
           eff_cxs_rx_data_reg      <= eff_cxs_rx_data;
           eff_cxs_rx_cntl_reg      <= eff_cxs_rx_cntl;
           cxs_rx_valid_reg         <= (Rx_Link_Status == 2'b11) ? CXS_RX_Valid : 1'b0;

           if(cxs_rx_valid_reg) begin
	      if (write_rx_cxs_dat_addr == 'hE )
		write_rx_cxs_dat_addr <= 0;
              else
		write_rx_cxs_dat_addr <= write_rx_cxs_dat_addr + 1'b1;
	   end

            if(cxs_rx_valid_reg) begin
	      if (write_rx_cxs_cntl_addr == 'hE )
		write_rx_cxs_cntl_addr <= 0;
              else
		write_rx_cxs_cntl_addr <= write_rx_cxs_cntl_addr + 1'b1;
	   end

	end
     end

   cxs_rxflit_ram #(
                    .AWIDTH (`CLOG2(`MAX_NUM_CREDITS)), // Address Width
		    .WWIDTH (CXS_DATA_FLIT_WIDTH),  // Data Width
                    .RWIDTH (S_AXI_DATA_WIDTH),  // Data Width
                    .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
                    .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
                    )
   u_rx_cxs_data_ram (
                .clk        (clk), 
                .rst_a      (~rst_n), 
                .en_a       (1'b1), 
                .we_a       (cxs_rx_valid_reg), // Port A is always Write port
                .word_en_a  ({NUM_CXS_DATA_RAM{1'b1}}),
                .addr_a     (write_rx_cxs_dat_addr), 
                .wr_data_a  (eff_cxs_rx_data_reg), 
                .rd_data_a  (), 
                .OREG_CE_A  (1'b1),                 
                .rst_b      (~rst_n), 
                .en_b       (|rx_cxs_data_ram_rd_en), 
                .we_b       (1'b0), // Port B is always Read port 
                .addr_b     (rx_cxs_data_ram_raddr), 
                .rd_data_b  (rx_cxs_data_ram_rdata_seg), 
                .word_en_b  (rx_cxs_data_ram_rd_en),
                .wr_data_b  ({CXS_DATA_FLIT_WIDTH{1'b0}}), 
                .OREG_CE_B  (1'b1));


   cxs_rxflit_ram #(
                    .AWIDTH (`CLOG2(`MAX_NUM_CREDITS)), // Address Width
                    .WWIDTH (EFF_CXS_CNTL_WIDTH),  // Data Width
                    .RWIDTH (S_AXI_DATA_WIDTH),  // Data Width
                    .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
                    .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
                    )
   u_rx_cxs_cntl_ram (
                      .clk        (clk), 
                      .rst_a      (~rst_n), 
                      .en_a       (1'b1), 
                      .we_a       (cxs_rx_valid_reg), // Port A is always Write port
                      .word_en_a  ({NUM_CXS_CNTL_RAM{1'b1}}),
                      .addr_a     (write_rx_cxs_cntl_addr), 
                      .wr_data_a  (eff_cxs_rx_cntl_reg), 
                      .rd_data_a  (), 
                      .OREG_CE_A  (1'b1),                 
                      .rst_b      (~rst_n), 
                      .en_b       (|rx_cxs_cntl_ram_rd_en), 
                      .we_b       (1'b0), // Port B is always Read port 
                      .addr_b     (rx_cxs_cntl_ram_raddr), 
                      .rd_data_b  (rx_cxs_cntl_ram_rdata_seg), 
                      .word_en_b  (rx_cxs_cntl_ram_rd_en),
                      .wr_data_b  ({EFF_CXS_CNTL_WIDTH{1'b0}}), 
                      .OREG_CE_B  (1'b1));

   always @(posedge clk)
     begin
	if (~resetn)
	  begin
             tx_cxs_dat_ram_wr_addr_sel   <= 0;
             mem_wr_en_reg <= 1'b0;
             mem_wr_en_reg_1 <= 1'b0;
             tx_cxs_ram_wdata <= 0;
             dat_wr_0 <= 0;
             dat_wr_1 <= 0;
	     tx_cxs_dat_ram_waddr_c <= 0;
	  end
	else 
	  begin
             mem_wr_en_reg <= mem_wr_en;
             mem_wr_en_reg_1 <= mem_wr_en_reg;
             tx_cxs_dat_ram_wr_addr_sel   <= 0;
             dat_wr_0 <= 1'b0;
             dat_wr_1 <= dat_wr_0;

             if(axi_awaddr[15:12] ==  4'h4 & axi_awaddr[11:8] >= 'h1 &  axi_awaddr[11:8] <= 'h8 & mem_wr_en & ~mode_select_reg[0])
               begin
		  tx_cxs_ram_wdata  <= s_axi_wdata;
		  dat_wr_0 <= 1'b1;
		  ///Define Offset parameters for ease /0x3600 to ox3b40
            if(axi_awaddr[11:BASE_DATA_LSB] >= (BASE_DATA_LSW ) & axi_awaddr[11:BASE_DATA_LSB] <= (BASE_DATA_LSW +'h0E))
		 tx_cxs_dat_ram_waddr_c <= axi_awaddr[11:BASE_DATA_LSB] - BASE_DATA_LSW;
               end
	  end    
     end
   
   
     always@ (posedge clk)begin
	if (~resetn)
	  begin
              tx_cxs_dat_ram_wr_lsw_ptr_c <= 0;
	      end
	      else begin
              tx_cxs_dat_ram_wr_lsw_ptr_c <= ( NUM_CXS_DATA_RAM == 8) ? axi_awaddr[4:2] :
	                                    ( NUM_CXS_DATA_RAM == 16 ) ? axi_awaddr[5:2] : 
	                                    ( NUM_CXS_DATA_RAM == 32) ? axi_awaddr[6:2] : 0; 
       end
   end

   
   always @(posedge clk)
     begin
	if (~resetn)
	  begin
             tx_cxs_dat_ram_waddr <= 0;
             tx_cxs_dat_ram_wr_lsw_ptr <= 0;
	  end
	else 
	  begin
             tx_cxs_dat_ram_waddr <= tx_cxs_dat_ram_waddr_c;
             tx_cxs_dat_ram_wr_lsw_ptr <= tx_cxs_dat_ram_wr_lsw_ptr_c;
	     end
	     end
	  

   assign tx_cxs_dat_ram_wr_en[NUM_CXS_DATA_RAM-1:0] =  dat_wr_1 ? 
                                  ( NUM_CXS_DATA_RAM == 8) ?
				    (1'b1 << tx_cxs_dat_ram_wr_lsw_ptr[NUM_CXS_DATA_EN_WD-1:0]) :
				  ( NUM_CXS_DATA_RAM == 16) ? 
				    (1'b1 << tx_cxs_dat_ram_wr_lsw_ptr[NUM_CXS_DATA_EN_WD-1:0]) :
				   ( NUM_CXS_DATA_RAM == 32) ? 
				    (1'b1 << tx_cxs_dat_ram_wr_lsw_ptr[NUM_CXS_DATA_EN_WD-1:0]) :
				      0 : 0;


   always @(posedge clk)
     begin
	if ( ~resetn)
	  begin
             tx_cxs_cntl_ram_waddr_1   <= 'h0;     
             tx_cxs_cntl_ram_wr_en_aw  <= 0;
             tx_cxs_cntl_ram_wdata  <= 0;
             tx_cxs_cntl_wr <= 1'b0;
	  end
	else begin
           if(axi_awaddr[15:12] ==  4'h4 & axi_awaddr[11:8] == 'hC  & mem_wr_en & ~mode_select_reg[0]) begin
              tx_cxs_cntl_ram_waddr_1   <=( NUM_CXS_CNTL_RAM == 1) ? axi_awaddr[5:2] : axi_awaddr[6:3];
              tx_cxs_cntl_ram_wr_en_aw  <= ( NUM_CXS_CNTL_RAM == 1) ? 1'b1: axi_awaddr[2];
              tx_cxs_cntl_ram_wdata <= s_axi_wdata;
              tx_cxs_cntl_wr <= 1'b1;
           end
           else begin
              tx_cxs_cntl_ram_waddr_1   <= 'h00;
              tx_cxs_cntl_ram_wr_en_aw  <= 0;
              tx_cxs_cntl_wr <= 1'b0;
           end 
        end
     end

   assign tx_cxs_cntl_ram_waddr = tx_cxs_cntl_ram_waddr_1[3:0];

  

   always@ (*) begin
      if (mem_wr_en_reg)
	tx_cxs_cntl_ram_wr_en = tx_cxs_cntl_wr ?
	                      (NUM_CXS_CNTL_RAM == 2) ? 
	              ~tx_cxs_cntl_ram_wr_en_aw ? 2'b01 :  2'b10 :
		        tx_cxs_cntl_ram_wr_en_aw :  0;
      else
	tx_cxs_cntl_ram_wr_en = 0;
   end


   assign mem_wr_en_pulse = ~mem_wr_en_reg  & mem_wr_en_reg_1;

   

   assign take_tx_flip_ownership =  tx_ownership_flip_reg[14:0];
   assign tx_ownership_reg = take_tx_ownership;


   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //                                               TXDAT RAM                                                        //
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

   wire tx_cxs_flit_valid;
   cxs_txflit_mgmt u_cxs_txflit_mgmt (
					       .clk             (clk), 
					       .rst_n           (rst_n), 
					       .own_flit        (take_tx_flip_ownership), 
					       .link_up         (link_up),
					       .credit_avail    (CXS_TX_Flit_transmit),
					       .read_req        (cxs_tx_read_reg), 
					       .read_addr       (tx_cxs_dat_ram_raddr), 
					       .flit_pending    (), 
					       .ownership       (take_tx_ownership),
					       .flit_valid      (tx_cxs_flit_valid)
					       );

   cxs_txflit_ram #(
		    .AWIDTH (`CLOG2(`MAX_NUM_CREDITS)), // Address Width
		    .WWIDTH (S_AXI_DATA_WIDTH),  // Data Width
		    .RWIDTH (CXS_DATA_FLIT_WIDTH),  // Data Width
		    .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
		    .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
		    )
   u_txdat_ram (
		.clk        (clk), 
		.rst_a      (~rst_n), 
		.en_a       (1'b1), 
		.we_a       (|tx_cxs_dat_ram_wr_en), // One Hot Encoded Write Enable based on Address Decode 
		.word_en_a  (tx_cxs_dat_ram_wr_en),
		.addr_a     (tx_cxs_dat_ram_waddr), 
		.wr_data_a  (tx_cxs_ram_wdata), 
		.rd_data_a  (), 
		.OREG_CE_A  (1'b1),                 
		.rst_b      (~rst_n), 
		.en_b       (cxs_tx_read_reg), //single bit  
		.we_b       (1'b0), // Port B is alwyas Read port 
		.addr_b     (tx_cxs_dat_ram_raddr), //incrementing address no dependency on Number of RAMs
		.rd_data_b  (tx_cxs_dat_ram_rdata), //dependent on i incrementer
		.word_en_b  ({NUM_CXS_DATA_RAM{1'b1}}),
		.wr_data_b  (32'b0), 
		.OREG_CE_B  (1'b1));

   assign CXS_TX_Data = link_up ? tx_cxs_dat_ram_rdata[CXS_DATA_FLIT_WIDTH-1:0] : 0;
   assign CXS_TX_Valid = link_up ? tx_cxs_flit_valid : 0;

   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
     //                                               TXRSP RAM                                                        //
     ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 wire cxs_tx_cntl_read_reg;
 wire [3:0] tx_cxs_cntl_ram_raddr;

   cxs_txflit_mgmt u_tx_cxs_cntl_mgmt (
					       .clk             (clk), 
					       .rst_n           (rst_n), 
					       .own_flit        (take_tx_flip_ownership), 
					       .credit_avail    (CXS_TX_Flit_transmit),
					       .link_up         (link_up),
					       .read_req        (cxs_tx_cntl_read_reg), 
					       .read_addr       (tx_cxs_cntl_ram_raddr), 
					       .flit_pending    (), 
					       .ownership       (),
					       .flit_valid      ()
					       );

   cxs_txflit_ram #(
		    .AWIDTH (`CLOG2(`MAX_NUM_CREDITS)), // Address Width
		    .WWIDTH (S_AXI_DATA_WIDTH),  // Data Width
		    .RWIDTH (EFF_CXS_CNTL_WIDTH),  // Data Width
		    .OREG_A ("TRUE"),  // Optional Port A output pipeline registers
		    .OREG_B ("TRUE")   // Optional Port B output pipeline registers  
		    )
   u_tx_cntl_ram (
		.clk        (clk), 
		.rst_a      (~rst_n), 
		.en_a       (1'b1), 
		.we_a       (|tx_cxs_cntl_ram_wr_en), // Port A is always Write port
		.word_en_a  (tx_cxs_cntl_ram_wr_en),
		.addr_a     (tx_cxs_cntl_ram_waddr[3:0]), 
		.wr_data_a  (tx_cxs_cntl_ram_wdata), 
		.rd_data_a  (), 
		.OREG_CE_A  (1'b1),                 
		.rst_b      (~rst_n), 
		.en_b       (cxs_tx_cntl_read_reg), 
		.we_b       (1'b0), // Port B is alwyas Read port 
		.addr_b     (tx_cxs_cntl_ram_raddr), 
		.rd_data_b  (tx_cxs_cntl_ram_rdata), 
		.word_en_b  ({NUM_CXS_CNTL_RAM{1'b1}}),
		.wr_data_b  (32'b0), 
		.OREG_CE_B  (1'b1));

   assign CXS_TX_Cntl     = tx_cxs_cntl_ram_rdata[CXS_CNTL_WIDTH-1:0];

 

    
endmodule
