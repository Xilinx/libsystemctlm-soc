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
 *   cxs bridge top
 *
 */

module cxs_bridge
  #(
    parameter       CXS_DATA_FLIT_WIDTH         = 256,//256,512,1024, ALLOWED VALUES 256
    parameter       CXS_CNTL_WIDTH              = 14,// ALLOWED VALUES 256
    parameter       USR_RST_NUM                 = 4, //1 to 4
    parameter       LAST_BRIDGE                 = 0, //1 or 0
    parameter       S_AXI_ADDR_WIDTH            = 64, //Allowed values : 32,64   
    parameter       S_AXI_DATA_WIDTH            = 32 //Allowed values : 32    
      )
   (

    input 			       clk,
    input 			       resetn,
    output [USR_RST_NUM-1:0] 	       usr_resetn,

    output 				CXS_ACTIVE_REQ_TX,
    input 				CXS_ACTIVE_ACK_TX,
    input 				CXS_DEACT_HINT_TX,
    input 				CXS_ACTIVE_REQ_RX,
    output 				CXS_ACTIVE_ACK_RX, 
    output 				CXS_DEACT_HINT_RX,
    

    // CXS Transmit Channel
    output  [CXS_DATA_FLIT_WIDTH-1:0]   CXS_DATA_TX,
    output  [CXS_CNTL_WIDTH -1:0]       CXS_CNTL_TX,
    output                              CXS_VALID_TX,
    output 				CXS_CRDRTN_TX,
    output 				CXS_CRDRTN_CHK_TX,
    output  [(CXS_DATA_FLIT_WIDTH/8) -1 :0] CXS_DATA_CHK_TX,
    output                              CXS_CNTL_CHK_TX,
    output                              CXS_VALID_CHK_TX,
    input 				CXS_CRDGNT_TX,
    input 				CXS_CRDGNT_CHK_TX,

    // CXS RECEIVE CHANNEL 
    input  [CXS_DATA_FLIT_WIDTH-1:0]    CXS_DATA_RX,
    input  [CXS_CNTL_WIDTH -1:0]        CXS_CNTL_RX,
    input 				CXS_VALID_RX,
    input 				CXS_CRDRTN_RX,
    input 				CXS_CRDRTN_CHK_RX,
    input  [(CXS_DATA_FLIT_WIDTH/8) -1 :0] CXS_DATA_CHK_RX,
    input                               CXS_CNTL_CHK_RX,
    input                               CXS_VALID_CHK_RX,
    output                              CXS_CRDGNT_RX,
    output 				CXS_CRDGNT_CHK_RX,
   
   
  
    // Slave AXI Lite Interface for Bridge register configuration
    input [S_AXI_ADDR_WIDTH-1:0] 	s_axi_awaddr,
    input [2:0] 			s_axi_awprot,
    input 				s_axi_awvalid,
    output 				s_axi_awready,
    input [S_AXI_DATA_WIDTH-1:0] 	s_axi_wdata,
    input [(S_AXI_DATA_WIDTH/8)-1:0] 	s_axi_wstrb,
    input 				s_axi_wvalid,
    output 				s_axi_wready,
    output [1:0] 			s_axi_bresp,
    output 				s_axi_bvalid,
    input 				s_axi_bready,
    input [S_AXI_ADDR_WIDTH-1:0] 	s_axi_araddr,
    input [2:0] 			s_axi_arprot,
    input 				s_axi_arvalid,
    output 				s_axi_arready,
    output [S_AXI_DATA_WIDTH-1:0] 	s_axi_rdata,
    output [1:0] 			s_axi_rresp,
    output 				s_axi_rvalid,
    input 				s_axi_rready,
    // Interrupt signals
    output 				irq_out, 
    input 				irq_ack, 
    input [31:0]                        cxs_bridge_feature_en,
    //DUT Interrupt
    output [127:0] 			h2c_intr_out, // Host to Card Interrupt
    input [63:0] 			c2h_intr_in, // Card to Host Interrupt
    //DUT GPIO
    output [255:0] 			h2c_gpio_out, // Host to Card general purpose IOs
    input [255:0] 			c2h_gpio_in 
       
        );

   wire 			       CXS_RX_Valid;
   wire [CXS_DATA_FLIT_WIDTH -1 :0]    CXS_RX_Data;
   wire [CXS_DATA_FLIT_WIDTH -1 :0]    CXS_TX_Data;
   wire [CXS_CNTL_WIDTH -1 :0]         CXS_RX_Cntl;
   wire [CXS_CNTL_WIDTH -1 :0]         CXS_TX_Cntl;
   wire 			       CXS_TX_Flit_transmit;
   wire 			       CXS_RX_Flit_received;
   wire [3:0] 			       rx_current_credits;
   wire [3:0] 			       tx_current_credits;
   wire [1:0] 			       Tx_Link_Status;
   wire [1:0] 			       Rx_Link_Status;
   wire 			       cxs_configure_bridge;
   wire 			       cxs_go_to_lp_rx;
   wire 			       cxs_credit_return_tx;
   wire [4:0] 			       rx_refill_credits;
   wire 			       rx_ownership;
   wire [14:0] 			       rx_ownership_flip_pulse;
   wire [31:0] 			       ih2rb_c2h_gpio_0_reg; 
   wire [31:0] 			       ih2rb_c2h_gpio_1_reg; 
   wire [31:0] 			       ih2rb_c2h_gpio_2_reg; 
   wire [31:0] 			       ih2rb_c2h_gpio_3_reg; 
   wire [31:0] 			       ih2rb_c2h_gpio_4_reg; 
   wire [31:0] 			       ih2rb_c2h_gpio_5_reg; 
   wire [31:0] 			       ih2rb_c2h_gpio_6_reg; 
   wire [31:0] 			       ih2rb_c2h_gpio_7_reg; 
   wire [31:0] 			       ih2rb_intr_c2h_toggle_status_0_reg_we; 
   wire [31:0] 			       ih2rb_intr_c2h_toggle_status_1_reg_we; 
   wire [31:0] 			       ih2rb_c2h_gpio_0_reg_we; 
   wire [31:0] 			       ih2rb_c2h_gpio_1_reg_we; 
   wire [31:0] 			       ih2rb_c2h_gpio_2_reg_we; 
   wire [31:0] 			       ih2rb_c2h_gpio_3_reg_we; 
   wire [31:0] 			       ih2rb_c2h_gpio_4_reg_we; 
   wire [31:0] 			       ih2rb_c2h_gpio_5_reg_we; 
   wire [31:0] 			       ih2rb_c2h_gpio_6_reg_we; 
   wire [31:0] 			       ih2rb_c2h_gpio_7_reg_we; 
   wire [31:0] 			       intr_h2c_0_reg;
   wire [31:0] 			       intr_h2c_1_reg;
   wire [31:0] 			       intr_h2c_2_reg;
   wire [31:0] 			       intr_h2c_3_reg;
   wire [31:0] 			       reset_reg;
   wire [31:0] 			       intr_c2h_toggle_status_0_reg;
   wire [31:0] 			       intr_c2h_toggle_status_1_reg;
   wire [31:0] 			       intr_c2h_toggle_enable_0_reg;
   wire [31:0] 			       intr_c2h_toggle_enable_1_reg;
   wire [31:0] 			       ih2rb_intr_c2h_toggle_status_0_reg;
   wire [31:0] 			       ih2rb_intr_c2h_toggle_status_1_reg;
   wire [31:0] 			       ih2rb_c2h_intr_status_0_reg; 
   wire [31:0] 			       ih2rb_c2h_intr_status_1_reg;
   wire [31:0] 			       ih2rb_c2h_intr_status_0_reg_we; 
   wire [31:0] 			       ih2rb_c2h_intr_status_1_reg_we;
   wire [31:0] 			       c2h_intr_status_0_reg;
   wire [31:0] 			       c2h_intr_status_1_reg;
   wire [31:0] 			       h2c_gpio_0_reg;
   wire [31:0] 			       h2c_gpio_1_reg;
   wire [31:0] 			       h2c_gpio_2_reg;
   wire [31:0] 			       h2c_gpio_3_reg;
   wire [31:0] 			       h2c_gpio_4_reg;
   wire [31:0] 			       h2c_gpio_5_reg;
   wire [31:0] 			       h2c_gpio_6_reg;
   wire [31:0] 			       h2c_gpio_7_reg;
   wire [31:0] 			       c2h_gpio_0_reg;
   wire [31:0] 			       c2h_gpio_1_reg;
   wire [31:0] 			       c2h_gpio_2_reg;
   wire [31:0] 			       c2h_gpio_3_reg;
   wire [31:0] 			       c2h_gpio_4_reg;
   wire [31:0] 			       c2h_gpio_5_reg;
   wire [31:0] 			       c2h_gpio_6_reg;
   wire [31:0] 			       c2h_gpio_7_reg;
   wire [31:0] 			       c2h_gpio_8_reg;
   wire [31:0] 			       c2h_gpio_9_reg;
   wire [31:0] 			       c2h_gpio_10_reg;
   wire [31:0] 			       c2h_gpio_11_reg;
   wire [31:0] 			       c2h_gpio_12_reg;
   wire [31:0] 			       c2h_gpio_13_reg;
   wire [31:0] 			       c2h_gpio_14_reg;
   wire [31:0] 			       c2h_gpio_15_reg;
   wire [31:0] 			       intr_c2h_toggle_clear_0_reg;
   wire [31:0] 			       intr_c2h_toggle_clear_1_reg;
   wire [31:0] 			       intr_error_status_reg;
   wire [31:0] 			       intr_error_enable_reg;
   wire [5:0] 			       intr_flit_txn_status_reg;
   wire [31:0] 			       intr_flit_txn_enable_reg;
 
   genvar 			       gi;   

   assign rst_n = resetn & reset_reg[0];

    generate 
      for (gi=0; gi<=USR_RST_NUM-1; gi=gi+1) begin: gen_resets
	 assign usr_resetn[gi] = resetn & reset_reg[gi+1];
      end
   endgenerate

   cxs_intr_handler 
     u_cxs_intr_handler 
       (
	.clk(clk), 
	.resetn(rst_n), 
	.irq_out(irq_out),
	.irq_ack(irq_ack),
	.h2c_intr_out(h2c_intr_out),
	.h2c_gpio_out(h2c_gpio_out),
	.c2h_intr_in(c2h_intr_in),
	.c2h_gpio_in(c2h_gpio_in),
	.ih2rb_c2h_intr_status_0_reg(ih2rb_c2h_intr_status_0_reg), 
	.ih2rb_c2h_intr_status_1_reg(ih2rb_c2h_intr_status_1_reg), 
	.ih2rb_c2h_intr_status_0_reg_we(ih2rb_c2h_intr_status_0_reg_we), 
	.ih2rb_c2h_intr_status_1_reg_we(ih2rb_c2h_intr_status_1_reg_we), 
	.ih2rb_c2h_gpio_0_reg(ih2rb_c2h_gpio_0_reg),
	.ih2rb_c2h_gpio_1_reg(ih2rb_c2h_gpio_1_reg),
	.ih2rb_c2h_gpio_2_reg(ih2rb_c2h_gpio_2_reg),
	.ih2rb_c2h_gpio_3_reg(ih2rb_c2h_gpio_3_reg),
	.ih2rb_c2h_gpio_4_reg(ih2rb_c2h_gpio_4_reg),
	.ih2rb_c2h_gpio_5_reg(ih2rb_c2h_gpio_5_reg),
	.ih2rb_c2h_gpio_6_reg(ih2rb_c2h_gpio_6_reg),
	.ih2rb_c2h_gpio_7_reg(ih2rb_c2h_gpio_7_reg),
	.ih2rb_intr_c2h_toggle_status_0_reg(ih2rb_intr_c2h_toggle_status_0_reg), 
	.ih2rb_intr_c2h_toggle_status_1_reg(ih2rb_intr_c2h_toggle_status_1_reg), 
	.ih2rb_intr_c2h_toggle_status_0_reg_we(ih2rb_intr_c2h_toggle_status_0_reg_we), 
	.ih2rb_intr_c2h_toggle_status_1_reg_we(ih2rb_intr_c2h_toggle_status_1_reg_we),
	.ih2rb_c2h_gpio_0_reg_we(ih2rb_c2h_gpio_0_reg_we), 
	.ih2rb_c2h_gpio_1_reg_we(ih2rb_c2h_gpio_1_reg_we), 
	.ih2rb_c2h_gpio_2_reg_we(ih2rb_c2h_gpio_2_reg_we), 
	.ih2rb_c2h_gpio_3_reg_we(ih2rb_c2h_gpio_3_reg_we), 
	.ih2rb_c2h_gpio_4_reg_we(ih2rb_c2h_gpio_4_reg_we), 
	.ih2rb_c2h_gpio_5_reg_we(ih2rb_c2h_gpio_5_reg_we), 
	.ih2rb_c2h_gpio_6_reg_we(ih2rb_c2h_gpio_6_reg_we), 
	.ih2rb_c2h_gpio_7_reg_we(ih2rb_c2h_gpio_7_reg_we),
	.intr_h2c_0_reg(intr_h2c_0_reg),
	.intr_h2c_1_reg(intr_h2c_1_reg),
	.intr_h2c_2_reg(intr_h2c_2_reg),
	.intr_h2c_3_reg(intr_h2c_3_reg),
	.c2h_intr_status_0_reg(c2h_intr_status_0_reg),
	.c2h_intr_status_1_reg(c2h_intr_status_1_reg),
	.intr_c2h_toggle_status_0_reg(intr_c2h_toggle_status_0_reg),
	.intr_c2h_toggle_status_1_reg(intr_c2h_toggle_status_1_reg),
	.intr_c2h_toggle_enable_0_reg(intr_c2h_toggle_enable_0_reg),
	.intr_c2h_toggle_enable_1_reg(intr_c2h_toggle_enable_1_reg),
	.c2h_gpio_0_reg(c2h_gpio_0_reg),
	.c2h_gpio_1_reg(c2h_gpio_1_reg),
	.c2h_gpio_2_reg(c2h_gpio_2_reg),
	.c2h_gpio_3_reg(c2h_gpio_3_reg),
	.c2h_gpio_4_reg(c2h_gpio_4_reg),
	.c2h_gpio_5_reg(c2h_gpio_5_reg),
	.c2h_gpio_6_reg(c2h_gpio_6_reg),
	.c2h_gpio_7_reg(c2h_gpio_7_reg),
	.c2h_gpio_8_reg(c2h_gpio_8_reg),
	.c2h_gpio_9_reg(c2h_gpio_9_reg),
	.c2h_gpio_10_reg(c2h_gpio_10_reg),
	.c2h_gpio_11_reg(c2h_gpio_11_reg),
	.c2h_gpio_12_reg(c2h_gpio_12_reg),
	.c2h_gpio_13_reg(c2h_gpio_13_reg),
	.c2h_gpio_14_reg(c2h_gpio_14_reg),
	.c2h_gpio_15_reg(c2h_gpio_15_reg),
	.h2c_gpio_0_reg(h2c_gpio_0_reg),
	.h2c_gpio_1_reg(h2c_gpio_1_reg),
	.h2c_gpio_2_reg(h2c_gpio_2_reg),
	.h2c_gpio_3_reg(h2c_gpio_3_reg),
	.h2c_gpio_4_reg(h2c_gpio_4_reg),
	.h2c_gpio_5_reg(h2c_gpio_5_reg),
	.h2c_gpio_6_reg(h2c_gpio_6_reg),
	.h2c_gpio_7_reg(h2c_gpio_7_reg),
	.intr_c2h_toggle_clear_0_reg(intr_c2h_toggle_clear_0_reg),
	.intr_c2h_toggle_clear_1_reg(intr_c2h_toggle_clear_1_reg),
	.intr_error_status_reg(32'b0),
	.intr_error_enable_reg(intr_error_enable_reg),
	.intr_flit_txn_status_reg(intr_flit_txn_status_reg),
	.intr_flit_txn_enable_reg(intr_flit_txn_enable_reg[5:0])
	);

   cxs_register_interface
     #(
       .CXS_DATA_FLIT_WIDTH  (CXS_DATA_FLIT_WIDTH),
       .CXS_CNTL_WIDTH       (CXS_CNTL_WIDTH),
       .USR_RST_NUM          (USR_RST_NUM),
       .LAST_BRIDGE          (LAST_BRIDGE),
       .S_AXI_ADDR_WIDTH     (S_AXI_ADDR_WIDTH),
       .S_AXI_DATA_WIDTH     (S_AXI_DATA_WIDTH))
   u_cxs_regs 
     (
      .clk(clk),
      .resetn(resetn), 
      .rst_n(rst_n), 
      .s_axi_awaddr(s_axi_awaddr),
      .s_axi_awprot(s_axi_awprot),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),
      .s_axi_wdata(s_axi_wdata),
      .s_axi_wstrb(s_axi_wstrb),
      .s_axi_wvalid(s_axi_wvalid),
      .s_axi_wready(s_axi_wready),
      .s_axi_bresp(s_axi_bresp),
      .s_axi_bvalid(s_axi_bvalid),
      .s_axi_bready(s_axi_bready),
      .s_axi_araddr(s_axi_araddr),
      .s_axi_arprot(s_axi_arprot),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),
      .s_axi_rdata(s_axi_rdata),
      .s_axi_rresp(s_axi_rresp),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rready(s_axi_rready),
      .ih2rb_c2h_gpio_0_reg(ih2rb_c2h_gpio_0_reg),
      .ih2rb_c2h_gpio_1_reg(ih2rb_c2h_gpio_1_reg),
      .ih2rb_c2h_gpio_2_reg(ih2rb_c2h_gpio_2_reg),
      .ih2rb_c2h_gpio_3_reg(ih2rb_c2h_gpio_3_reg),
      .ih2rb_c2h_gpio_4_reg(ih2rb_c2h_gpio_4_reg),
      .ih2rb_c2h_gpio_5_reg(ih2rb_c2h_gpio_5_reg),
      .ih2rb_c2h_gpio_6_reg(ih2rb_c2h_gpio_6_reg),
      .ih2rb_c2h_gpio_7_reg(ih2rb_c2h_gpio_7_reg),
      .ih2rb_c2h_gpio_0_reg_we(ih2rb_c2h_gpio_0_reg_we),
      .ih2rb_c2h_gpio_1_reg_we(ih2rb_c2h_gpio_1_reg_we),
      .ih2rb_c2h_gpio_2_reg_we(ih2rb_c2h_gpio_2_reg_we),
      .ih2rb_c2h_gpio_3_reg_we(ih2rb_c2h_gpio_3_reg_we),
      .ih2rb_c2h_gpio_4_reg_we(ih2rb_c2h_gpio_4_reg_we),
      .ih2rb_c2h_gpio_5_reg_we(ih2rb_c2h_gpio_5_reg_we),
      .ih2rb_c2h_gpio_6_reg_we(ih2rb_c2h_gpio_6_reg_we),
      .ih2rb_c2h_gpio_7_reg_we(ih2rb_c2h_gpio_7_reg_we),
      .ih2rb_c2h_intr_status_0_reg(ih2rb_c2h_intr_status_0_reg), 
      .ih2rb_c2h_intr_status_1_reg(ih2rb_c2h_intr_status_1_reg), 
      .ih2rb_c2h_intr_status_0_reg_we(ih2rb_c2h_intr_status_0_reg_we), 
      .ih2rb_c2h_intr_status_1_reg_we(ih2rb_c2h_intr_status_1_reg_we),
      .ih2rb_intr_c2h_toggle_status_0_reg(ih2rb_intr_c2h_toggle_status_0_reg),
      .ih2rb_intr_c2h_toggle_status_1_reg(ih2rb_intr_c2h_toggle_status_1_reg),
      .ih2rb_intr_c2h_toggle_status_0_reg_we(ih2rb_intr_c2h_toggle_status_0_reg_we),
      .ih2rb_intr_c2h_toggle_status_1_reg_we(ih2rb_intr_c2h_toggle_status_1_reg_we),
      .intr_h2c_0_reg(intr_h2c_0_reg),
      .intr_h2c_1_reg(intr_h2c_1_reg),
      .intr_h2c_2_reg(intr_h2c_2_reg),
      .intr_h2c_3_reg(intr_h2c_3_reg),
      .intr_c2h_toggle_status_0_reg(intr_c2h_toggle_status_0_reg),
      .intr_c2h_toggle_status_1_reg(intr_c2h_toggle_status_1_reg),
      .intr_c2h_toggle_enable_0_reg(intr_c2h_toggle_enable_0_reg),
      .intr_c2h_toggle_enable_1_reg(intr_c2h_toggle_enable_1_reg),
      .intr_c2h_toggle_clear_0_reg(intr_c2h_toggle_clear_0_reg),
      .intr_c2h_toggle_clear_1_reg(intr_c2h_toggle_clear_1_reg),
      .h2c_gpio_0_reg(h2c_gpio_0_reg),
      .h2c_gpio_1_reg(h2c_gpio_1_reg),
      .h2c_gpio_2_reg(h2c_gpio_2_reg),
      .h2c_gpio_3_reg(h2c_gpio_3_reg),
      .h2c_gpio_4_reg(h2c_gpio_4_reg),
      .h2c_gpio_5_reg(h2c_gpio_5_reg),
      .h2c_gpio_6_reg(h2c_gpio_6_reg),
      .h2c_gpio_7_reg(h2c_gpio_7_reg),
      .reset_reg(reset_reg),
      .intr_error_enable_reg(intr_error_enable_reg),
      .cxs_bridge_feature_en(cxs_bridge_feature_en),
      .intr_flit_txn_status_reg(intr_flit_txn_status_reg),
      .intr_flit_txn_enable_reg(intr_flit_txn_enable_reg),
      .cxs_configure_bridge(cxs_configure_bridge),  
      .cxs_go_to_lp_rx(cxs_go_to_lp_rx),  
      .cxs_credit_return_tx(cxs_credit_return_tx),  
      .rx_refill_credits(rx_refill_credits),  
      .rx_ownership(rx_ownership),
      .rx_ownership_flip_pulse(rx_ownership_flip_pulse),
      .rx_current_credits(rx_current_credits),
      .tx_current_credits(tx_current_credits),
      .CXS_TX_Valid(CXS_TX_Valid),
      .CXS_TX_Data(CXS_TX_Data),
      .CXS_TX_Cntl(CXS_TX_Cntl),
      .CXS_RX_Valid(CXS_RX_Valid),
      .CXS_RX_Data(CXS_RX_Data),
      .CXS_RX_Cntl(CXS_RX_Cntl),
      .CXS_TX_Flit_transmit(CXS_TX_Flit_transmit),
      .CXS_RX_Flit_received(CXS_RX_Flit_received),
      .Tx_Link_Status(Tx_Link_Status),
      .Rx_Link_Status(Rx_Link_Status)
      );

   cxs_channel_if  
     #(
       .CXS_DATA_FLIT_WIDTH   (CXS_DATA_FLIT_WIDTH),
       .CXS_CNTL_WIDTH        (CXS_CNTL_WIDTH)
       )
   u_cxs_channel_if 
    (
    .clk(clk),        
    .resetn(rst_n),
    .cxs_configure_bridge(cxs_configure_bridge),  
    .cxs_go_to_lp_rx(cxs_go_to_lp_rx),  
    .cxs_credit_return_tx(cxs_credit_return_tx),  
    .rx_refill_credits(rx_refill_credits),  
    .rx_ownership(rx_ownership),
    .rx_ownership_flip_pulse(rx_ownership_flip_pulse),
    .rx_current_credits(rx_current_credits),
    .tx_current_credits(tx_current_credits),
    .CXS_ACTIVE_REQ_TX(CXS_ACTIVE_REQ_TX),
    .CXS_ACTIVE_ACK_TX(CXS_ACTIVE_ACK_TX),
    .CXS_ACTIVE_REQ_RX(CXS_ACTIVE_REQ_RX) ,
    .CXS_ACTIVE_ACK_RX(CXS_ACTIVE_ACK_RX) , 
    .CXS_DEACT_HINT_TX(CXS_DEACT_HINT_TX),
    .CXS_DEACT_HINT_RX(CXS_DEACT_HINT_RX),
    // CHI TX  Channel
    .CXS_DATA_TX(CXS_DATA_TX),
    .CXS_CNTL_TX(CXS_CNTL_TX),
    .CXS_VALID_TX(CXS_VALID_TX),
    .CXS_CRDRTN_TX(CXS_CRDRTN_TX),
    .CXS_CRDGNT_TX(CXS_CRDGNT_TX),
    .CXS_DATA_CHK_TX(CXS_DATA_CHK_TX),
    .CXS_CNTL_CHK_TX(CXS_CNTL_CHK_TX),
    .CXS_VALID_CHK_TX(CXS_VALID_CHK_TX),
    .CXS_CRDRTN_CHK_TX(CXS_CRDRTN_CHK_TX),
    .CXS_CRDGNT_CHK_TX(CXS_CRDGNT_CHK_TX),

    // CXS RECEIVE CHANNEL 
    .CXS_DATA_RX(CXS_DATA_RX),
    .CXS_CNTL_RX(CXS_CNTL_RX),
    .CXS_VALID_RX(CXS_VALID_RX),
    .CXS_CRDRTN_RX(CXS_CRDRTN_RX),
    .CXS_CRDGNT_RX(CXS_CRDGNT_RX),
    .CXS_DATA_CHK_RX(CXS_DATA_CHK_RX),
    .CXS_CNTL_CHK_RX(CXS_CNTL_CHK_RX),
    .CXS_VALID_CHK_RX(CXS_VALID_CHK_RX),
    .CXS_CRDRTN_CHK_RX(CXS_CRDRTN_CHK_RX),
    .CXS_CRDGNT_CHK_RX(CXS_CRDGNT_CHK_RX),

    .CXS_TX_Valid(CXS_TX_Valid),
    .CXS_TX_Data(CXS_TX_Data),
    .CXS_TX_Cntl(CXS_TX_Cntl),
    .CXS_RX_Valid(CXS_RX_Valid),
    .CXS_RX_Data(CXS_RX_Data),
    .CXS_RX_Cntl(CXS_RX_Cntl),
    .CXS_TX_Flit_transmit(CXS_TX_Flit_transmit),
    .CXS_RX_Flit_received(CXS_RX_Flit_received),
    .Tx_Link_Status(Tx_Link_Status),
    .Rx_Link_Status(Rx_Link_Status)
     );

endmodule

