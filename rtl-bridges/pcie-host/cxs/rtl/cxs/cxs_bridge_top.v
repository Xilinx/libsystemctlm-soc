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
 *    CXS Top wrapper
 *
 */

`include "cxs_defines_regspace.vh"
module cxs_bridge_top 
  #(
    parameter       CXS_DATA_FLIT_WIDTH         = 256,//256,512,1024 
    parameter       CXS_CNTL_WIDTH              = 14, //14,36,44
    parameter       CXS_DATACHECK               = 0, //0 or 1
    parameter       CXS_REPLICATION             = 0, //0 or 1
    parameter       USR_RST_NUM                 = 4, //1 to 4
    parameter       LAST_BRIDGE                 = 0, //1 or 0
    parameter       S_AXI_ADDR_WIDTH            = 64, //Allowed values : 32,64   
    parameter       S_AXI_DATA_WIDTH            = 32 //Allowed values : 32    
    )
   (
    input 								clk, 
    input 								resetn,
    output [USR_RST_NUM-1:0] 						usr_resetn,

    output 								CXS_ACTIVE_REQ_TX,
    input 								CXS_ACTIVE_ACK_TX,
    input 								CXS_DEACT_HINT_TX,
    input 								CXS_ACTIVE_REQ_RX,
    output 								CXS_ACTIVE_ACK_RX, 
    output 								CXS_DEACT_HINT_RX,
    

    // CXS Transmit Channel
    output  [CXS_DATA_FLIT_WIDTH-1:0]                                   CXS_DATA_TX,
    output  [CXS_CNTL_WIDTH-1:0]                                        CXS_CNTL_TX,
    output                                                       	CXS_VALID_TX,
    output 								CXS_CRDRTN_TX,
    output 	                                                        CXS_CRDRTN_CHK_TX,
    output [(CXS_DATA_FLIT_WIDTH/8) -1 :0]                              CXS_DATA_CHK_TX,
    output                                                              CXS_CNTL_CHK_TX,
    output                                                              CXS_VALID_CHK_TX,
    input 								CXS_CRDGNT_TX,
    input 								CXS_CRDGNT_CHK_TX,

    // CXS RECEIVE CHANNEL 
    input  [CXS_DATA_FLIT_WIDTH-1:0]                                    CXS_DATA_RX,
    input  [CXS_CNTL_WIDTH  -1:0]					CXS_CNTL_RX,
    input 								CXS_VALID_RX,
    input 								CXS_CRDRTN_RX,
    input 								CXS_CRDRTN_CHK_RX,
    input  [(CXS_DATA_FLIT_WIDTH/8) -1 :0]                              CXS_DATA_CHK_RX,
    input                                                               CXS_CNTL_CHK_RX,
    input                                                               CXS_VALID_CHK_RX,
    output                               				CXS_CRDGNT_RX,
    output 								CXS_CRDGNT_CHK_RX,
   
  
    // Slave AXI Lite Interface for Bridge register configuration
    input [S_AXI_ADDR_WIDTH-1:0] 					s_axi_awaddr,
    input [2:0] 							s_axi_awprot,
    input 								s_axi_awvalid,
    output 								s_axi_awready,
    input [S_AXI_DATA_WIDTH-1:0] 					s_axi_wdata,
    input [(S_AXI_DATA_WIDTH/8)-1:0] 					s_axi_wstrb,
    input 								s_axi_wvalid,
    output 								s_axi_wready,
    output [1:0] 							s_axi_bresp,
    output 								s_axi_bvalid,
    input 								s_axi_bready,
    input [S_AXI_ADDR_WIDTH-1:0] 					s_axi_araddr,
    input [2:0] 							s_axi_arprot,
    input 								s_axi_arvalid,
    output 								s_axi_arready,
    output [S_AXI_DATA_WIDTH-1:0] 					s_axi_rdata,
    output [1:0] 							s_axi_rresp,
    output 								s_axi_rvalid,
    input 								s_axi_rready,
    // Interrupt signals
    output 								irq_out, 
    input 								irq_ack, 
    //DUT Interrupt
    output [127:0] 							h2c_intr_out, // Host to Card Interrupt
    input [63:0] 							c2h_intr_in, // Card to Host Interrupt
    //DUT GPIO
    output [255:0] 							h2c_gpio_out, // Host to Card general purpose IOs
    input [255:0] 							c2h_gpio_in    // Card to Host general purpose IOs   
    );
   
     
   wire [10:0] req_1;
   wire [6:0]  req_2;
   wire [1:0]  req_3;											
   wire [31:0] 	cxs_bridge_feature_en;


   assign req_1 = CXS_DATA_FLIT_WIDTH;
   assign req_2 = CXS_CNTL_WIDTH;
   assign dchk = CXS_DATACHECK ? 1'b1: 1'b0;
   assign repl = CXS_REPLICATION ? 1'b1: 1'b0;
   assign req_3 = {repl,dchk};

   assign  cxs_bridge_feature_en = {12'b0,req_3,req_2,req_1};



   
   cxs_bridge 
     #(
       .CXS_DATA_FLIT_WIDTH  (CXS_DATA_FLIT_WIDTH),
       .CXS_CNTL_WIDTH       (CXS_CNTL_WIDTH),
       .USR_RST_NUM          (USR_RST_NUM),
       .LAST_BRIDGE          (LAST_BRIDGE),
       .S_AXI_ADDR_WIDTH     (S_AXI_ADDR_WIDTH),
       .S_AXI_DATA_WIDTH     (S_AXI_DATA_WIDTH)
       )
   u_cxs_bridge
     (
      .clk(clk),        
      .resetn(resetn),
      .usr_resetn(usr_resetn),
      .CXS_ACTIVE_REQ_TX(CXS_ACTIVE_REQ_TX),
      .CXS_ACTIVE_ACK_TX(CXS_ACTIVE_ACK_TX),
      .CXS_ACTIVE_REQ_RX(CXS_ACTIVE_REQ_RX) ,
      .CXS_ACTIVE_ACK_RX(CXS_ACTIVE_ACK_RX) , 
      .CXS_DEACT_HINT_TX(CXS_DEACT_HINT_TX) ,
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
      // CXS Transmit Channel
      .s_axi_awaddr       (s_axi_awaddr),
      .s_axi_awprot       (s_axi_awprot),
      .s_axi_awvalid      (s_axi_awvalid),
      .s_axi_awready      (s_axi_awready),
      .s_axi_wdata        (s_axi_wdata),
      .s_axi_wstrb        (s_axi_wstrb),
      .s_axi_wvalid       (s_axi_wvalid),
      .s_axi_wready       (s_axi_wready),
      .s_axi_bresp        (s_axi_bresp),
      .s_axi_bvalid       (s_axi_bvalid),
      .s_axi_bready       (s_axi_bready),
      .s_axi_araddr       (s_axi_araddr),
      .s_axi_arprot       (s_axi_arprot),
      .s_axi_arvalid      (s_axi_arvalid),
      .s_axi_arready      (s_axi_arready),
      .s_axi_rdata        (s_axi_rdata),
      .s_axi_rresp        (s_axi_rresp),
      .s_axi_rvalid       (s_axi_rvalid),
      .s_axi_rready       (s_axi_rready),
      .irq_out            (irq_out), 
      .irq_ack            (irq_ack), 
      .cxs_bridge_feature_en  (cxs_bridge_feature_en),
      .h2c_intr_out(h2c_intr_out),
      .h2c_gpio_out(h2c_gpio_out),
      .c2h_intr_in(c2h_intr_in),
      .c2h_gpio_in(c2h_gpio_in)
      );           
   
endmodule        











