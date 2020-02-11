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
 *   RN-F Top wrapper
 *
 */

`include "chi_defines_field.vh"
module chi_bridge_rn_top 
  #(
    parameter [1:0] CHI_VERSION                 = 0,  //Allowed values : 0 --> CHI.B, 1--> CHI.C
    parameter       CHI_NODE_ID_WIDTH           = 7,  //Allowed values : 7 to 11
    parameter       CHI_REQ_ADDR_WIDTH          = 48,  //Allowed values : 45 to 52
    parameter       CHI_FLIT_DATA_WIDTH         = 512,  //Allowed values : 128.256,512 
    parameter [0:0] CHI_DMT_ENA                 = 0, //1 or 0
    parameter [0:0] CHI_DCT_ENA                 = 0, //1 or 0
    parameter [0:0] CHI_ATOMIC_ENA              = 0, //1 or 0
    parameter [0:0] CHI_STASHING_ENA            = 0, //1 or 0
    parameter [0:0] CHI_DATA_POISON_ENA         = 0, //1 or 0
    parameter [0:0] CHI_DATA_CHECK_ENA          = 0, //1 or 0
    parameter [0:0] CHI_CCF_WRAP_ORDER          = 0, //1 or 0
    parameter [0:0] CHI_ENHANCE_FEATURE_EN      = 0, //1 or 0
    parameter       USR_RST_NUM                 = 4, //Allowed values 1 to 4
    parameter       LAST_BRIDGE                 = 0, // Set this param to 1 for the last bridge instance in the design  
    parameter S_AXI_ADDR_WIDTH            = 64, //Allowed values : 32,64   
    parameter S_AXI_DATA_WIDTH            = 32 //Allowed values : 32    
    )
   (
    input 											  clk, 
    input 											  resetn,
    output [USR_RST_NUM-1:0] 									  usr_resetn,

    output 											  CHI_SYSCOREQ,
    input 											  CHI_SYSCOACK,

    output 											  CHI_TXSACTIVE,
    input 											  CHI_RXSACTIVE,
    output 											  CHI_TXLINKACTIVEREQ,
    input 											  CHI_TXLINKACTIVEACK,
    input 											  CHI_RXLINKACTIVEREQ,
    output 											  CHI_RXLINKACTIVEACK, 

    // CHI TXRSP Channel
    input 											  CHI_TXRSPLCRDV,
    output 											  CHI_TXRSPFLITPEND,
    output 											  CHI_TXRSPFLITV,
    output [((2*CHI_NODE_ID_WIDTH) + `CHI_RSP_FLIT_CNST_WIDTH)-1:0] 				  CHI_TXRSPFLIT,

    // CHI TXDAT Channel
    input 											  CHI_TXDATLCRDV,
    output 											  CHI_TXDATFLITPEND,
    output 											  CHI_TXDATFLITV,
    output [((3*CHI_NODE_ID_WIDTH) + 2*(CHI_FLIT_DATA_WIDTH/8) + 
    CHI_FLIT_DATA_WIDTH + (CHI_FLIT_DATA_WIDTH/64) + `CHI_DAT_FLIT_CNST_WIDTH +
    ( (CHI_VERSION==1) ? 1 : 0 ) ) - 1 : 0] 							  CHI_TXDATFLIT,

    // CHI TXSNP Channel
    input 											  CHI_TXREQLCRDV,
    output 											  CHI_TXREQFLITPEND,
    output 											  CHI_TXREQFLITV,
    output [((3*CHI_NODE_ID_WIDTH) + CHI_REQ_ADDR_WIDTH + `CHI_REQ_FLIT_CNST_WIDTH)-1:0] 	  CHI_TXREQFLIT,

    // CHI RXRSP Channel
    output 											  CHI_RXRSPLCRDV,
    input 											  CHI_RXRSPFLITPEND,
    input 											  CHI_RXRSPFLITV,
    input [((2*CHI_NODE_ID_WIDTH) + `CHI_RSP_FLIT_CNST_WIDTH) - 1 : 0] 				  CHI_RXRSPFLIT,

    // CHI RXDAT Channel
    output 											  CHI_RXDATLCRDV,
    input 											  CHI_RXDATFLITPEND,
    input 											  CHI_RXDATFLITV,
    input [((3*CHI_NODE_ID_WIDTH) + 2*(CHI_FLIT_DATA_WIDTH/8) + 
    CHI_FLIT_DATA_WIDTH + (CHI_FLIT_DATA_WIDTH/64) + `CHI_DAT_FLIT_CNST_WIDTH 
    + ( (CHI_VERSION==1) ? 1 : 0 ) ) - 1 : 0] 							  CHI_RXDATFLIT,

    // CHI RXREQ Channel
    output 											  CHI_RXSNPLCRDV,
    input 											  CHI_RXSNPFLITPEND,
    input 											  CHI_RXSNPFLITV,
    input [((2*CHI_NODE_ID_WIDTH) + ( CHI_REQ_ADDR_WIDTH -3) + `CHI_SNP_FLIT_CNST_WIDTH) - 1 : 0] CHI_RXSNPFLIT,

    // Slave AXI Lite Interface for Bridge register configuration
    input [S_AXI_ADDR_WIDTH-1:0] 								  s_axi_awaddr,
    input [2:0] 										  s_axi_awprot,
    input 											  s_axi_awvalid,
    output 											  s_axi_awready,
    input [S_AXI_DATA_WIDTH-1:0] 								  s_axi_wdata,
    input [(S_AXI_DATA_WIDTH/8)-1:0] 								  s_axi_wstrb,
    input 											  s_axi_wvalid,
    output 											  s_axi_wready,
    output [1:0] 										  s_axi_bresp,
    output 											  s_axi_bvalid,
    input 											  s_axi_bready,
    input [S_AXI_ADDR_WIDTH-1:0] 								  s_axi_araddr,
    input [2:0] 										  s_axi_arprot,
    input 											  s_axi_arvalid,
    output 											  s_axi_arready,
    output [S_AXI_DATA_WIDTH-1:0] 								  s_axi_rdata,
    output [1:0] 										  s_axi_rresp,
    output 											  s_axi_rvalid,
    input 											  s_axi_rready,
    // Interrupt signals
    output 											  irq_out, 
    input 											  irq_ack, 
    //DUT Interrupt
    output [127:0] 										  h2c_intr_out, // Host to Card Interrupt
    input [63:0] 										  c2h_intr_in, // Card to Host Interrupt
    //DUT GPIO
    output [255:0] 										  h2c_gpio_out, // Host to Card general purpose IOs
    input [255:0] 										  c2h_gpio_in    // Card to Host general purpose IOs
   
    );

   localparam CHI_CHN_REQ_WIDTH = ((3*CHI_NODE_ID_WIDTH) + CHI_REQ_ADDR_WIDTH + `CHI_REQ_FLIT_CNST_WIDTH);
   localparam CHI_CHN_RSP_WIDTH = ((2*CHI_NODE_ID_WIDTH) + `CHI_RSP_FLIT_CNST_WIDTH);
   localparam CHI_CHN_DAT_WIDTH =  (
				    (3*CHI_NODE_ID_WIDTH) 
				    + ( 2*(CHI_FLIT_DATA_WIDTH/8) )
				    + CHI_FLIT_DATA_WIDTH 
				    + (CHI_FLIT_DATA_WIDTH/64) 
				    + `CHI_DAT_FLIT_CNST_WIDTH
				    + ( (CHI_VERSION==1) ? 1 : 0 )
				    );
   localparam CHI_CHN_SNP_WIDTH = (2*CHI_NODE_ID_WIDTH + ( CHI_REQ_ADDR_WIDTH -3 ) + `CHI_SNP_FLIT_CNST_WIDTH);  
   localparam BRIDGE_MODE = "RN_F";
   
   
   wire [3:0] 											  req_1;
   wire [5:0] 											  req_2;
   wire [10:0] 											  req_3;
   wire [3:0] 											  req_4;
   wire [9:0] 											  req_5;
   wire [31:0] 											  chi_bridge_config;
   wire [31:0] 											  chi_bridge_feature_en;

   assign req_1 = CHI_NODE_ID_WIDTH;
   assign req_2 = CHI_REQ_ADDR_WIDTH;
   assign req_3 = CHI_FLIT_DATA_WIDTH;
   assign req_4 = (CHI_VERSION==1) ? 4 : 3;
   assign req_5 = {CHI_ENHANCE_FEATURE_EN,CHI_CCF_WRAP_ORDER,CHI_DATA_CHECK_ENA,CHI_DATA_POISON_ENA, CHI_STASHING_ENA,CHI_ATOMIC_ENA,CHI_DCT_ENA,CHI_DMT_ENA,CHI_VERSION};

   assign  chi_bridge_config = {8'b0,req_4,req_3,req_2,req_1};
   assign  chi_bridge_feature_en = {22'b0,req_5};


   chi_bridge 
     #(
       .BRIDGE_MODE          (BRIDGE_MODE),
       .CHI_CHN_REQ_WIDTH    (CHI_CHN_REQ_WIDTH),
       .CHI_CHN_RSP_WIDTH    (CHI_CHN_RSP_WIDTH),
       .CHI_CHN_DAT_WIDTH    (CHI_CHN_DAT_WIDTH),
       .CHI_CHN_SNP_WIDTH    (CHI_CHN_SNP_WIDTH),
       .CHI_FLIT_DATA_WIDTH  (CHI_FLIT_DATA_WIDTH),
       .USR_RST_NUM          (USR_RST_NUM),
       .LAST_BRIDGE          (LAST_BRIDGE),
       .S_AXI_ADDR_WIDTH     (S_AXI_ADDR_WIDTH),
       .S_AXI_DATA_WIDTH     (S_AXI_DATA_WIDTH)
       )
   u_chi_bridge
     (
      .clk(clk),        
      .resetn(resetn),
      .usr_resetn(usr_resetn),
      .CHI_RN_SYSCOREQ       (CHI_SYSCOREQ),
      .CHI_RN_SYSCOACK       (CHI_SYSCOACK),
      .CHI_HN_SYSCOREQ       (1'b0),
      .CHI_HN_SYSCOACK       (),
      .CHI_TXSACTIVE      (CHI_TXSACTIVE),
      .CHI_RXSACTIVE      (CHI_RXSACTIVE),
      .CHI_TXLINKACTIVEREQ(CHI_TXLINKACTIVEREQ),
      .CHI_TXLINKACTIVEACK(CHI_TXLINKACTIVEACK),
      .CHI_RXLINKACTIVEREQ(CHI_RXLINKACTIVEREQ) ,
      .CHI_RXLINKACTIVEACK(CHI_RXLINKACTIVEACK) , 
      // CHI TX RSP Channel
      .CHI_TXRSPFLITPEND  (CHI_TXRSPFLITPEND),
      .CHI_TXRSPFLITV     (CHI_TXRSPFLITV),
      .CHI_TXRSPFLIT      (CHI_TXRSPFLIT),
      .CHI_TXRSPLCRDV     (CHI_TXRSPLCRDV),
      // CHI TX DAT Channel
      .CHI_TXDATFLITPEND  (CHI_TXDATFLITPEND),
      .CHI_TXDATFLITV     (CHI_TXDATFLITV),
      .CHI_TXDATFLIT      (CHI_TXDATFLIT),
      .CHI_TXDATLCRDV     (CHI_TXDATLCRDV),
      // CHI TX SNP/REQ Channel
      // When configured as HN-F TX SNP Channel
      // When configured as RN-F TX REQ Channel
      .CHI_TXSNP_TXREQ_FLITPEND  (CHI_TXREQFLITPEND),
      .CHI_TXSNP_TXREQ_FLITV     (CHI_TXREQFLITV   ),
      .CHI_TXSNP_TXREQ_FLIT      (CHI_TXREQFLIT    ),
      .CHI_TXSNP_TXREQ_LCRDV     (CHI_TXREQLCRDV   ),
      // CHI RX REQ/SNP Channel
      // When configured as HN-F RX REQ Channel
      // When configured as RN-F RX SNP Channel
      .CHI_RXREQ_RXSNP_FLITPEND  (CHI_RXSNPFLITPEND),
      .CHI_RXREQ_RXSNP_FLITV     (CHI_RXSNPFLITV   ),
      .CHI_RXREQ_RXSNP_FLIT      (CHI_RXSNPFLIT    ),
      .CHI_RXREQ_RXSNP_LCRDV     (CHI_RXSNPLCRDV   ),
      // CHI RX RSP Channel
      .CHI_RXRSPFLITPEND  (CHI_RXRSPFLITPEND),
      .CHI_RXRSPFLITV     (CHI_RXRSPFLITV),
      .CHI_RXRSPFLIT      (CHI_RXRSPFLIT),
      .CHI_RXRSPLCRDV     (CHI_RXRSPLCRDV),
      // CHI RX DAT Channel
      .CHI_RXDATFLITPEND  (CHI_RXDATFLITPEND),
      .CHI_RXDATFLITV     (CHI_RXDATFLITV),
      .CHI_RXDATFLIT      (CHI_RXDATFLIT),
      .CHI_RXDATLCRDV     (CHI_RXDATLCRDV),
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
      .chi_bridge_config  (chi_bridge_config),
      .chi_bridge_feature_en(chi_bridge_feature_en),
      .h2c_intr_out(h2c_intr_out),
      .h2c_gpio_out(h2c_gpio_out),
      .c2h_intr_in(c2h_intr_in),
      .c2h_gpio_in(c2h_gpio_in)
      );           
   
endmodule        











