/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Heramb Aligave.
 *            Alok Mistry.
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
 *   chi bridge top, common for rn-f and hn-f
 *
 */

module chi_bridge 
  #(
    parameter BRIDGE_MODE           = "HN_F", //Allowed values : HN_F, RN_F
    parameter CHI_CHN_REQ_WIDTH     = 121,  //Allowed values : 117-169 
    parameter CHI_CHN_RSP_WIDTH     = 51,  //Allowed values : 51-59
    parameter CHI_CHN_DAT_WIDTH     = 705,  //Allowed values : 201-749
    parameter CHI_CHN_SNP_WIDTH     = 88,  //Allowed values : 84-100
    parameter CHI_CHN_REQ_SNP_WIDTH = ((BRIDGE_MODE == "HN_F") ? CHI_CHN_REQ_WIDTH : CHI_CHN_SNP_WIDTH), 
    parameter CHI_CHN_SNP_REQ_WIDTH = ((BRIDGE_MODE == "HN_F") ? CHI_CHN_SNP_WIDTH : CHI_CHN_REQ_WIDTH), 
    parameter CHI_FLIT_DATA_WIDTH   = 512,  //Allowed values : 128, 256, 512
    parameter USR_RST_NUM           = 4, //Allowed values : 1-4
    parameter LAST_BRIDGE           = 0, // Set this param to 1 for the last bridge instance in the design
  
    parameter S_AXI_ADDR_WIDTH      = 64, //Allowed values : 32,64   
    parameter S_AXI_DATA_WIDTH      = 32 //Allowed values : 32    
    )
   (

    input 			       clk,
    input 			       resetn,
    output [USR_RST_NUM-1:0] 	       usr_resetn,

    input 			       CHI_HN_SYSCOREQ,
    output 			       CHI_HN_SYSCOACK,
    output 			       CHI_RN_SYSCOREQ,
    input 			       CHI_RN_SYSCOACK,
    output 			       CHI_TXSACTIVE,
    input 			       CHI_RXSACTIVE,
    output 			       CHI_TXLINKACTIVEREQ,
    input 			       CHI_TXLINKACTIVEACK,
    input 			       CHI_RXLINKACTIVEREQ,
    output 			       CHI_RXLINKACTIVEACK,

    input 			       CHI_TXRSPLCRDV,
    output 			       CHI_TXRSPFLITPEND,
    output 			       CHI_TXRSPFLITV,
    output [CHI_CHN_RSP_WIDTH-1:0]     CHI_TXRSPFLIT,

    input 			       CHI_TXDATLCRDV,
    output 			       CHI_TXDATFLITPEND,
    output 			       CHI_TXDATFLITV,
    output [CHI_CHN_DAT_WIDTH - 1 : 0] CHI_TXDATFLIT,

    input 			       CHI_TXSNP_TXREQ_LCRDV,
    output 			       CHI_TXSNP_TXREQ_FLITPEND,
    output 			       CHI_TXSNP_TXREQ_FLITV,
    output [CHI_CHN_SNP_REQ_WIDTH-1:0] CHI_TXSNP_TXREQ_FLIT,

    output 			       CHI_RXREQ_RXSNP_LCRDV,
    input 			       CHI_RXREQ_RXSNP_FLITPEND,
    input 			       CHI_RXREQ_RXSNP_FLITV,
    input [CHI_CHN_REQ_SNP_WIDTH-1:0]  CHI_RXREQ_RXSNP_FLIT,

    output 			       CHI_RXRSPLCRDV,
    input 			       CHI_RXRSPFLITPEND,
    input 			       CHI_RXRSPFLITV,
    input [CHI_CHN_RSP_WIDTH - 1 : 0]  CHI_RXRSPFLIT,

    output 			       CHI_RXDATLCRDV,
    input 			       CHI_RXDATFLITPEND,
    input 			       CHI_RXDATFLITV,
    input [CHI_CHN_DAT_WIDTH - 1 : 0]  CHI_RXDATFLIT,
   
    input [S_AXI_ADDR_WIDTH-1:0]       s_axi_awaddr,
    input [2:0] 		       s_axi_awprot,
    input 			       s_axi_awvalid,
    output 			       s_axi_awready,
    input [S_AXI_DATA_WIDTH-1:0]       s_axi_wdata,
    input [(S_AXI_DATA_WIDTH/8)-1:0]   s_axi_wstrb,
    input 			       s_axi_wvalid,
    output 			       s_axi_wready,
    output [1:0] 		       s_axi_bresp,
    output 			       s_axi_bvalid,
    input 			       s_axi_bready,
    input [S_AXI_ADDR_WIDTH-1:0]       s_axi_araddr,
    input [2:0] 		       s_axi_arprot,
    input 			       s_axi_arvalid,
    output 			       s_axi_arready,
    output [S_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
    output [1:0] 		       s_axi_rresp,
    output 			       s_axi_rvalid,
    input 			       s_axi_rready,
    input [S_AXI_DATA_WIDTH-1:0]       chi_bridge_config,
    input [S_AXI_DATA_WIDTH-1:0]       chi_bridge_feature_en,
    output 			       irq_out, 
    input 			       irq_ack, 
    //DUT Interrupt
    output [127:0] 		       h2c_intr_out,
    input [63:0] 		       c2h_intr_in,
    //DUT GPIO
    output [255:0] 		       h2c_gpio_out,
    input [255:0] 		       c2h_gpio_in
    );

   wire 			       CHI_RXREQ_RXSNP_Pending;
   wire 			       CHI_RXREQ_RXSNP_Valid;
   wire [CHI_CHN_REQ_SNP_WIDTH -1 :0]  CHI_RXREQ_RXSNP_Data;
   wire 			       CHI_RXRSP_Pending;
   wire 			       CHI_RXRSP_Valid;
   wire [CHI_CHN_RSP_WIDTH -1 :0]      CHI_RXRSP_Data;
   wire 			       CHI_RXDAT_Pending;
   wire 			       CHI_RXDAT_Valid;
   wire [CHI_CHN_DAT_WIDTH -1 :0]      CHI_RXDAT_Data;
   wire 			       CHI_TXSNP_TXREQ_flit_transmit;
   wire 			       CHI_TXRSP_flit_transmit;
   wire 			       CHI_TXDAT_flit_transmit;
   wire [3:0] 			       rxdat_current_credits;
   wire [3:0] 			       rxreq_rxsnp_current_credits;
   wire [3:0] 			       rxrsp_current_credits;
   wire [3:0] 			       txdat_current_credits;
   wire [3:0] 			       txsnp_txreq_current_credits;
   wire [3:0] 			       txrsp_current_credits;
   wire [1:0] 			       Tx_Link_Status;
   wire [1:0] 			       Rx_Link_Status;
   wire 			       configure_bridge;
   wire 			       go_to_lp;
   wire 			       syscoreq_i;
   wire 			       syscoack_i;
   wire 			       syscoreq_o;
   wire 			       syscoack_o;
   wire [4:0] 			       rxreq_rxsnp_refill_credits;
   wire [4:0] 			       rxrsp_refill_credits;
   wire [4:0] 			       rxdat_refill_credits;
   wire 			       rxreq_rxsnp_ownership;
   wire 			       rxrsp_ownership;
   wire 			       rxdat_ownership;
   wire [14:0] 			       rxreq_rxsnp_ownership_flip_pulse;
   wire [14:0] 			       rxrsp_ownership_flip_pulse;
   wire [14:0] 			       rxdat_ownership_flip_pulse;
   wire 			       CHI_TXRSP_Pending;
   wire 			       CHI_TXRSP_Valid;
   wire [CHI_CHN_RSP_WIDTH -1 :0]      CHI_TXRSP_Data;
   wire 			       CHI_TXDAT_Pending;
   wire 			       CHI_TXDAT_Valid;
   wire [CHI_CHN_DAT_WIDTH -1 :0]      CHI_TXDAT_Data;   
   wire 			       CHI_TXSNP_TXREQ_Pending;
   wire 			       CHI_TXSNP_TXREQ_Valid; 
   wire [CHI_CHN_SNP_REQ_WIDTH -1 :0]  CHI_TXSNP_TXREQ_Data;
   wire 			       CHI_RXREQ_RXSNP_Received;
   wire 			       CHI_RXRSP_Received;
   wire 			       CHI_RXDAT_Received;
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
   wire [31:0] 			       intr_status_reg     ;
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
   wire [31:0] 			       intr_error_clear_reg;
   wire [31:0] 			       intr_error_enable_reg;
   wire [5:0] 			       intr_flit_txn_status_reg;
   wire [31:0] 			       intr_flit_txn_enable_reg;
   wire 			       chi_syscoreq_rn;
   wire 			       chi_syscoreq_hn;
   wire 			       chi_syscoack_rn;
   wire 			       chi_syscoack_hn;

   genvar 			       gi;   

   assign rst_n = resetn & reset_reg[0];

   assign CHI_RN_SYSCOREQ = chi_syscoreq_rn;
   assign CHI_HN_SYSCOACK = chi_syscoack_hn;
   assign chi_syscoreq_hn = CHI_HN_SYSCOREQ;
   assign chi_syscoack_rn = CHI_RN_SYSCOACK;
   generate 
      for (gi=0; gi<=USR_RST_NUM-1; gi=gi+1) begin: gen_resets
	 assign usr_resetn[gi] = resetn & reset_reg[gi+1];
      end
   endgenerate

   chi_intr_handler 
     u_chi_hn_intr_handler 
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

   chi_register_interface
     #(
       .BRIDGE_MODE           (BRIDGE_MODE),
       .CHI_CHN_REQ_WIDTH     (CHI_CHN_REQ_WIDTH),
       .CHI_CHN_RSP_WIDTH     (CHI_CHN_RSP_WIDTH),
       .CHI_CHN_SNP_WIDTH     (CHI_CHN_SNP_WIDTH),
       .CHI_CHN_DAT_WIDTH     (CHI_CHN_DAT_WIDTH),
       .CHI_FLIT_DATA_WIDTH   (CHI_FLIT_DATA_WIDTH),
       .USR_RST_NUM           (USR_RST_NUM),
       .LAST_BRIDGE           (LAST_BRIDGE),
       .S_AXI_ADDR_WIDTH      (S_AXI_ADDR_WIDTH),
       .S_AXI_DATA_WIDTH      (S_AXI_DATA_WIDTH))
   u_regs 
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
      .chi_bridge_config(chi_bridge_config),
      .chi_bridge_feature_en(chi_bridge_feature_en),
      .intr_flit_txn_status_reg(intr_flit_txn_status_reg),
      .intr_flit_txn_enable_reg(intr_flit_txn_enable_reg),
      .configure_bridge(configure_bridge),
      .go_to_lp(go_to_lp),
      .syscoreq_o(syscoreq_o),
      .syscoack_o(syscoack_o),
      .syscoreq_i(syscoreq_i),
      .syscoack_i(syscoack_i),
      .rxreq_rxsnp_refill_credits(rxreq_rxsnp_refill_credits),
      .rxrsp_refill_credits(rxrsp_refill_credits),
      .rxdat_refill_credits(rxdat_refill_credits),
      .rxreq_rxsnp_ownership(rxreq_rxsnp_ownership),
      .rxrsp_ownership(rxrsp_ownership),
      .rxdat_ownership(rxdat_ownership),
      .rxreq_rxsnp_ownership_flip_pulse(rxreq_rxsnp_ownership_flip_pulse),
      .rxrsp_ownership_flip_pulse(rxrsp_ownership_flip_pulse),
      .rxdat_ownership_flip_pulse(rxdat_ownership_flip_pulse),
      .CHI_RXREQ_RXSNP_Pending(CHI_RXREQ_RXSNP_Pending),
      .CHI_RXREQ_RXSNP_Valid  (CHI_RXREQ_RXSNP_Valid),
      .CHI_RXREQ_RXSNP_Data   (CHI_RXREQ_RXSNP_Data),
      .CHI_RXRSP_Pending(CHI_RXRSP_Pending),
      .CHI_RXRSP_Valid(CHI_RXRSP_Valid),
      .CHI_RXRSP_Data(CHI_RXRSP_Data),
      .CHI_RXDAT_Pending(CHI_RXDAT_Pending),
      .CHI_RXDAT_Valid(CHI_RXDAT_Valid),
      .CHI_RXDAT_Data(CHI_RXDAT_Data),   
      .CHI_TXSNP_TXREQ_Pending(CHI_TXSNP_TXREQ_Pending),
      .CHI_TXSNP_TXREQ_Valid  (CHI_TXSNP_TXREQ_Valid), 
      .CHI_TXSNP_TXREQ_Data   (CHI_TXSNP_TXREQ_Data),
      .CHI_TXRSP_Pending(CHI_TXRSP_Pending),
      .CHI_TXRSP_Valid(CHI_TXRSP_Valid),
      .CHI_TXRSP_Data(CHI_TXRSP_Data),
      .CHI_TXDAT_Pending(CHI_TXDAT_Pending),
      .CHI_TXDAT_Valid(CHI_TXDAT_Valid),
      .CHI_TXDAT_Data(CHI_TXDAT_Data),
      .CHI_TXSNP_TXREQ_flit_transmit(CHI_TXSNP_TXREQ_flit_transmit),
      .CHI_TXRSP_flit_transmit(CHI_TXRSP_flit_transmit),
      .CHI_TXDAT_flit_transmit(CHI_TXDAT_flit_transmit),
      .rxdat_current_credits(rxdat_current_credits),
      .rxreq_rxsnp_current_credits(rxreq_rxsnp_current_credits),
      .rxrsp_current_credits(rxrsp_current_credits),
      .txdat_current_credits(txdat_current_credits),
      .txsnp_txreq_current_credits(txsnp_txreq_current_credits),
      .txrsp_current_credits(txrsp_current_credits),
      .CHI_RXREQ_RXSNP_Received(CHI_RXREQ_RXSNP_Received),
      .CHI_RXRSP_Received(CHI_RXRSP_Received),
      .CHI_RXDAT_Received(CHI_RXDAT_Received),
      .Tx_Link_Status(Tx_Link_Status),
      .Rx_Link_Status(Rx_Link_Status)
      );

   chi_channel_if  
     #(
       .BRIDGE_MODE          (BRIDGE_MODE),
       .CHI_CHN_REQ_WIDTH    (CHI_CHN_REQ_WIDTH),
       .CHI_CHN_RSP_WIDTH    (CHI_CHN_RSP_WIDTH),
       .CHI_CHN_SNP_WIDTH    (CHI_CHN_SNP_WIDTH),
       .CHI_CHN_DAT_WIDTH    (CHI_CHN_DAT_WIDTH),
       .CHI_CHN_REQ_SNP_WIDTH((BRIDGE_MODE == "HN_F") ? CHI_CHN_REQ_WIDTH : CHI_CHN_SNP_WIDTH),
       .CHI_CHN_SNP_REQ_WIDTH((BRIDGE_MODE == "HN_F") ? CHI_CHN_SNP_WIDTH : CHI_CHN_REQ_WIDTH)
       )
   u_chi_channel_if 
					    (
					     .clk(clk),        
					     .resetn(rst_n),
					     .configure_bridge(configure_bridge),  
					     .go_to_lp(go_to_lp),  
					     .rxreq_rxsnp_refill_credits(rxreq_rxsnp_refill_credits),  
					     .rxrsp_refill_credits(rxrsp_refill_credits),  
					     .rxdat_refill_credits(rxdat_refill_credits),  
					     .rxreq_rxsnp_ownership(rxreq_rxsnp_ownership),
					     .rxrsp_ownership(rxrsp_ownership),
					     .rxdat_ownership(rxdat_ownership),
					     .rxreq_rxsnp_ownership_flip_pulse(rxreq_rxsnp_ownership_flip_pulse),
					     .rxrsp_ownership_flip_pulse(rxrsp_ownership_flip_pulse),
					     .rxdat_ownership_flip_pulse(rxdat_ownership_flip_pulse),
					     .flits_in_progress(1'b1),
					     .rxdat_current_credits(rxdat_current_credits),
					     .rxreq_rxsnp_current_credits(rxreq_rxsnp_current_credits),
					     .rxrsp_current_credits(rxrsp_current_credits),
					     .txdat_current_credits(txdat_current_credits),
					     .txsnp_txreq_current_credits(txsnp_txreq_current_credits),
					     .txrsp_current_credits(txrsp_current_credits),
					     .syscoreq_i(syscoreq_i),
					     .syscoack_i(syscoack_i),
					     .syscoreq_o(syscoreq_o),
					     .syscoack_o(syscoack_o),
					     .chi_syscoreq_hn(chi_syscoreq_hn),
					     .chi_syscoack_hn(chi_syscoack_hn),
					     .chi_syscoreq_rn(chi_syscoreq_rn),
					     .chi_syscoack_rn(chi_syscoack_rn),
					     .CHI_RXSACTIVE(CHI_RXSACTIVE),
					     .CHI_TXSACTIVE(CHI_TXSACTIVE),
					     .CHI_TXLINKACTIVEREQ(CHI_TXLINKACTIVEREQ),
					     .CHI_TXLINKACTIVEACK(CHI_TXLINKACTIVEACK),

					     .CHI_TXRSPFLITPEND(CHI_TXRSPFLITPEND),
					     .CHI_TXRSPFLITV(CHI_TXRSPFLITV),
					     .CHI_TXRSPFLIT(CHI_TXRSPFLIT),
					     .CHI_TXRSPLCRDV(CHI_TXRSPLCRDV),

					     .CHI_TXDATFLITPEND(CHI_TXDATFLITPEND),
					     .CHI_TXDATFLITV(CHI_TXDATFLITV),
					     .CHI_TXDATFLIT(CHI_TXDATFLIT),
					     .CHI_TXDATLCRDV(CHI_TXDATLCRDV),

					     .CHI_RXLINKACTIVEREQ(CHI_RXLINKACTIVEREQ),
					     .CHI_RXLINKACTIVEACK(CHI_RXLINKACTIVEACK), 
      
					     .CHI_TXSNP_TXREQ_FLITPEND(CHI_TXSNP_TXREQ_FLITPEND),
					     .CHI_TXSNP_TXREQ_FLITV   (CHI_TXSNP_TXREQ_FLITV),
					     .CHI_TXSNP_TXREQ_FLIT    (CHI_TXSNP_TXREQ_FLIT),
					     .CHI_TXSNP_TXREQ_LCRDV   (CHI_TXSNP_TXREQ_LCRDV),

					     .CHI_RXREQ_RXSNP_FLITPEND       (CHI_RXREQ_RXSNP_FLITPEND),
					     .CHI_RXREQ_RXSNP_FLITV          (CHI_RXREQ_RXSNP_FLITV),
					     .CHI_RXREQ_RXSNP_FLIT           (CHI_RXREQ_RXSNP_FLIT),
					     .CHI_RXREQ_RXSNP_LCRDV          (CHI_RXREQ_RXSNP_LCRDV),

					     .CHI_RXRSPFLITPEND(CHI_RXRSPFLITPEND),
					     .CHI_RXRSPFLITV(CHI_RXRSPFLITV),
					     .CHI_RXRSPFLIT(CHI_RXRSPFLIT),
					     .CHI_RXRSPLCRDV(CHI_RXRSPLCRDV),

					     .CHI_RXDATFLITPEND(CHI_RXDATFLITPEND),
					     .CHI_RXDATFLITV(CHI_RXDATFLITV),
					     .CHI_RXDATFLIT(CHI_RXDATFLIT),
					     .CHI_RXDATLCRDV(CHI_RXDATLCRDV),
					     .CHI_TXSNP_TXREQ_Pending(1'b1),
					     .CHI_TXSNP_TXREQ_Valid(CHI_TXSNP_TXREQ_Valid),
					     .CHI_TXSNP_TXREQ_Data(CHI_TXSNP_TXREQ_Data),
					     .CHI_TXRSP_Pending(1'b1),
					     .CHI_TXRSP_Valid(CHI_TXRSP_Valid),
					     .CHI_TXRSP_Data(CHI_TXRSP_Data),
					     .CHI_TXDAT_Pending(1'b1),
					     .CHI_TXDAT_Valid(CHI_TXDAT_Valid),
					     .CHI_TXDAT_Data(CHI_TXDAT_Data),   
					     .CHI_RXREQ_RXSNP_Pending(CHI_RXREQ_RXSNP_Pending),
					     .CHI_RXREQ_RXSNP_Valid  (CHI_RXREQ_RXSNP_Valid), 
					     .CHI_RXREQ_RXSNP_Data   (CHI_RXREQ_RXSNP_Data),
					     .CHI_RXRSP_Pending(CHI_RXRSP_Pending),
					     .CHI_RXRSP_Valid(CHI_RXRSP_Valid),
					     .CHI_RXRSP_Data(CHI_RXRSP_Data),
					     .CHI_RXDAT_Pending(CHI_RXDAT_Pending),
					     .CHI_RXDAT_Valid(CHI_RXDAT_Valid),
					     .CHI_RXDAT_Data(CHI_RXDAT_Data),
					     .CHI_TXSNP_TXREQ_flit_transmit(CHI_TXSNP_TXREQ_flit_transmit),
					     .CHI_TXRSP_flit_transmit(CHI_TXRSP_flit_transmit),
					     .CHI_TXDAT_flit_transmit(CHI_TXDAT_flit_transmit),
					     .CHI_RXREQ_RXSNP_Received(CHI_RXREQ_RXSNP_Received),
					     .CHI_RXRSP_Received(CHI_RXRSP_Received),
					     .CHI_RXDAT_Received(CHI_RXDAT_Received),
					     .Tx_Link_Status(Tx_Link_Status),
					     .Rx_Link_Status(Rx_Link_Status)
					     );
   

endmodule

