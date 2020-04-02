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
 *   Top module for AXI4 Master.
 *
 *
 */
`include "defines_common.vh"
module axi4_master #(
                     parameter S_AXI_ADDR_WIDTH              =   64, //Allowed values : 32,64   
                     parameter S_AXI_DATA_WIDTH              =   32, //Allowed values : 32    

                     parameter M_AXI_ADDR_WIDTH              =   64, //   
                     parameter M_AXI_DATA_WIDTH              =   128, //Allowed values : 128
                     parameter M_AXI_ID_WIDTH                =   4,  //Allowed values : 4-16
                     parameter M_AXI_USER_WIDTH              =   32, //Allowed values : 1-32          

                     parameter M_AXI_USR_ADDR_WIDTH          =   64,    
                     parameter M_AXI_USR_DATA_WIDTH          =   128, //Allowed values : 32,64,128
                     parameter M_AXI_USR_ID_WIDTH            =   16,   //Allowed values : 1-16
		     parameter M_AXI_USR_AWUSER_WIDTH         =    32, //Allowed values : 1-32
		     parameter M_AXI_USR_WUSER_WIDTH         =    32, //Allowed values : 1-32
		     parameter M_AXI_USR_BUSER_WIDTH         =    32, //Allowed values : 1-32
		     parameter M_AXI_USR_ARUSER_WIDTH         =    32, //Allowed values : 1-32
		     parameter M_AXI_USR_RUSER_WIDTH         =    32, //Allowed values : 1-32


                     parameter RAM_SIZE                      =   16384, // Size of RAM in Bytes
                     parameter MAX_DESC                      =   16,                   
                     parameter USR_RST_NUM                   =   4, //Allowed values : 1-31
                     parameter PCIE_AXI = 0,
                     parameter PCIE_LAST_BRIDGE = 0,
		     parameter LAST_BRIDGE                   =   0,
		     parameter EXTEND_WSTRB                  =   1


                     )(

                       //Clock and reset
                       input 				      axi_aclk, 
                       input 				      axi_aresetn, 

                       output [USR_RST_NUM-1:0] 	      usr_resetn,
                       //System Interrupt  
                       output 				      irq_out, 
                       input 				      irq_ack, 
                       //DUT Interrupt
                       output [127:0] 			      h2c_intr_out,
                       input [63:0] 			      c2h_intr_in,
                       output [63:0] 			      h2c_pulse_out,
                       //DUT GPIO
                       input [255:0] 			      c2h_gpio_in,
		       output [255:0] 			      h2c_gpio_out,

                       // S_AXI - AXI4-Lite
                       input wire [S_AXI_ADDR_WIDTH-1:0]      s_axi_awaddr,
                       input wire [2:0] 		      s_axi_awprot,
                       input wire 			      s_axi_awvalid,
                       output wire 			      s_axi_awready,
                       input wire [S_AXI_DATA_WIDTH-1:0]      s_axi_wdata,
                       input wire [(S_AXI_DATA_WIDTH/8)-1:0]  s_axi_wstrb,
                       input wire 			      s_axi_wvalid,
                       output wire 			      s_axi_wready,
                       output wire [1:0] 		      s_axi_bresp,
                       output wire 			      s_axi_bvalid,
                       input wire 			      s_axi_bready,
                       input wire [S_AXI_ADDR_WIDTH-1:0]      s_axi_araddr,
                       input wire [2:0] 		      s_axi_arprot,
                       input wire 			      s_axi_arvalid,
                       output wire 			      s_axi_arready,
                       output wire [S_AXI_DATA_WIDTH-1:0]     s_axi_rdata,
                       output wire [1:0] 		      s_axi_rresp,
                       output wire 			      s_axi_rvalid,
                       input wire 			      s_axi_rready, 

                       // M_AXI - AXI4
                       output wire [M_AXI_ID_WIDTH-1 : 0]     m_axi_awid,
                       output wire [M_AXI_ADDR_WIDTH-1 : 0]   m_axi_awaddr,
                       output wire [7 : 0] 		      m_axi_awlen,
                       output wire [2 : 0] 		      m_axi_awsize,
                       output wire [1 : 0] 		      m_axi_awburst,
                       output wire 			      m_axi_awlock,
                       output wire [3 : 0] 		      m_axi_awcache,
                       output wire [2 : 0] 		      m_axi_awprot,
                       output wire [3 : 0] 		      m_axi_awqos,
                       output wire [3:0] 		      m_axi_awregion, 
                       output wire [M_AXI_USER_WIDTH-1 : 0]   m_axi_awuser,
                       output wire 			      m_axi_awvalid,
                       input wire 			      m_axi_awready,
                       output wire [M_AXI_DATA_WIDTH-1 : 0]   m_axi_wdata,
                       output wire [M_AXI_DATA_WIDTH/8-1 : 0] m_axi_wstrb,
                       output wire 			      m_axi_wlast,
                       output wire [M_AXI_USER_WIDTH-1 : 0]   m_axi_wuser,
                       output wire 			      m_axi_wvalid,
                       input wire 			      m_axi_wready,
                       input wire [M_AXI_ID_WIDTH-1 : 0]      m_axi_bid,
                       input wire [1 : 0] 		      m_axi_bresp,
                       input wire [M_AXI_USER_WIDTH-1 : 0]    m_axi_buser,
                       input wire 			      m_axi_bvalid,
                       output wire 			      m_axi_bready,
                       output wire [M_AXI_ID_WIDTH-1 : 0]     m_axi_arid,
                       output wire [M_AXI_ADDR_WIDTH-1 : 0]   m_axi_araddr,
                       output wire [7 : 0] 		      m_axi_arlen,
                       output wire [2 : 0] 		      m_axi_arsize,
                       output wire [1 : 0] 		      m_axi_arburst,
                       output wire 			      m_axi_arlock,
                       output wire [3 : 0] 		      m_axi_arcache,
                       output wire [2 : 0] 		      m_axi_arprot,
                       output wire [3 : 0] 		      m_axi_arqos,
                       output wire [3:0] 		      m_axi_arregion,
                       output wire [M_AXI_USER_WIDTH-1 : 0]   m_axi_aruser,
                       output wire 			      m_axi_arvalid,
                       input wire 			      m_axi_arready,
                       input wire [M_AXI_ID_WIDTH-1 : 0]      m_axi_rid,
                       input wire [M_AXI_DATA_WIDTH-1 : 0]    m_axi_rdata,
                       input wire [1 : 0] 		      m_axi_rresp,
                       input wire 			      m_axi_rlast,
                       input wire [M_AXI_USER_WIDTH-1 : 0]    m_axi_ruser,
                       input wire 			      m_axi_rvalid,
                       output wire 			      m_axi_rready,

                       output [M_AXI_USR_ID_WIDTH-1:0] 	      m_axi_usr_awid, 
                       output [M_AXI_USR_ADDR_WIDTH-1:0]      m_axi_usr_awaddr, 
                       output [7:0] 			      m_axi_usr_awlen, 
                       output [2:0] 			      m_axi_usr_awsize, 
                       output [1:0] 			      m_axi_usr_awburst, 
                       output 				      m_axi_usr_awlock, 
                       output [3:0] 			      m_axi_usr_awcache, 
                       output [2:0] 			      m_axi_usr_awprot, 
                       output [3:0] 			      m_axi_usr_awqos, 
                       output [3:0] 			      m_axi_usr_awregion, 
                       output [M_AXI_USR_AWUSER_WIDTH-1:0]    m_axi_usr_awuser, 
                       output 				      m_axi_usr_awvalid, 
                       input 				      m_axi_usr_awready, 
                       output [M_AXI_USR_DATA_WIDTH-1:0]      m_axi_usr_wdata, 
                       output [(M_AXI_USR_DATA_WIDTH/8)-1:0]  m_axi_usr_wstrb,
                       output 				      m_axi_usr_wlast, 
                       output [M_AXI_USR_WUSER_WIDTH-1:0]     m_axi_usr_wuser, 
                       output 				      m_axi_usr_wvalid, 
                       input 				      m_axi_usr_wready, 
                       input [M_AXI_USR_ID_WIDTH-1:0] 	      m_axi_usr_bid, 
                       input [1:0] 			      m_axi_usr_bresp, 
                       input [M_AXI_USR_BUSER_WIDTH-1:0]      m_axi_usr_buser, 
                       input 				      m_axi_usr_bvalid, 
                       output 				      m_axi_usr_bready, 
                       output [M_AXI_USR_ID_WIDTH-1:0] 	      m_axi_usr_arid, 
                       output [M_AXI_USR_ADDR_WIDTH-1:0]      m_axi_usr_araddr, 
                       output [7:0] 			      m_axi_usr_arlen, 
                       output [2:0] 			      m_axi_usr_arsize, 
                       output [1:0] 			      m_axi_usr_arburst, 
                       output 				      m_axi_usr_arlock, 
                       output [3:0] 			      m_axi_usr_arcache, 
                       output [2:0] 			      m_axi_usr_arprot, 
                       output [3:0] 			      m_axi_usr_arqos, 
                       output [3:0] 			      m_axi_usr_arregion, 
                       output [M_AXI_USR_ARUSER_WIDTH-1:0]    m_axi_usr_aruser, 
                       output 				      m_axi_usr_arvalid, 
                       input 				      m_axi_usr_arready, 
                       input [M_AXI_USR_ID_WIDTH-1:0] 	      m_axi_usr_rid, 
                       input [M_AXI_USR_DATA_WIDTH-1:0]       m_axi_usr_rdata, 
                       input [1:0] 			      m_axi_usr_rresp, 
                       input 				      m_axi_usr_rlast, 
                       input [M_AXI_USR_RUSER_WIDTH-1:0]      m_axi_usr_ruser, 
                       input 				      m_axi_usr_rvalid, 
                       output 				      m_axi_usr_rready


                       );


   wire [1:0] 						      awlock;
   wire [1:0] 						      arlock;
   
   assign m_axi_usr_awlock= awlock[0] ;
   assign m_axi_usr_arlock= arlock[0] ;
   

   axi_master_common
     #(/*AUTOINSTPARAM*/
       // Parameters
       .S_AXI_ADDR_WIDTH				(S_AXI_ADDR_WIDTH),
       .S_AXI_DATA_WIDTH				(S_AXI_DATA_WIDTH),
       .M_AXI_ADDR_WIDTH				(M_AXI_ADDR_WIDTH),
       .M_AXI_DATA_WIDTH				(M_AXI_DATA_WIDTH),

       .M_AXI_ID_WIDTH					(M_AXI_ID_WIDTH),
       .M_AXI_USER_WIDTH				(M_AXI_USER_WIDTH),
       .M_AXI_USR_ADDR_WIDTH			(M_AXI_USR_ADDR_WIDTH),
       .M_AXI_USR_DATA_WIDTH			(M_AXI_USR_DATA_WIDTH),
       .M_AXI_USR_ID_WIDTH				(M_AXI_USR_ID_WIDTH),
       .M_AXI_USR_AWUSER_WIDTH (M_AXI_USR_AWUSER_WIDTH),
       .M_AXI_USR_ARUSER_WIDTH (M_AXI_USR_ARUSER_WIDTH),
       .M_AXI_USR_WUSER_WIDTH  (M_AXI_USR_WUSER_WIDTH),
       .M_AXI_USR_RUSER_WIDTH  (M_AXI_USR_RUSER_WIDTH),
       .M_AXI_USR_BUSER_WIDTH  (M_AXI_USR_BUSER_WIDTH),
       .RAM_SIZE						(RAM_SIZE),
       .MAX_DESC						(MAX_DESC),
       .USR_RST_NUM						(USR_RST_NUM),
       .EN_INTFM_AXI4 (1),
       .EN_INTFM_AXI3 (0),
       .EN_INTFM_AXI4LITE (0),
       .PCIE_AXI                          (PCIE_AXI),
       .PCIE_LAST_BRIDGE                          (PCIE_LAST_BRIDGE),
       .LAST_BRIDGE (LAST_BRIDGE),
       .EXTEND_WSTRB (EXTEND_WSTRB))
   
   i_axi4_master
     (/*AUTOINST*/
      // Outputs
      .usr_resetn							(usr_resetn[USR_RST_NUM-1:0]),
      .irq_out							(irq_out),
      .h2c_intr_out						(h2c_intr_out),
      .s_axi_awready						(s_axi_awready),
      .s_axi_wready						(s_axi_wready),
      .s_axi_bresp						(s_axi_bresp[1:0]),
      .s_axi_bvalid						(s_axi_bvalid),
      .s_axi_arready						(s_axi_arready),
      .s_axi_rdata						(s_axi_rdata[S_AXI_DATA_WIDTH-1:0]),
      .s_axi_rresp						(s_axi_rresp[1:0]),
      .s_axi_rvalid						(s_axi_rvalid),
      .m_axi_awid							(m_axi_awid[M_AXI_ID_WIDTH-1:0]),
      .m_axi_awaddr						(m_axi_awaddr[M_AXI_ADDR_WIDTH-1:0]),
      .m_axi_awlen						(m_axi_awlen[7:0]),
      .m_axi_awsize						(m_axi_awsize[2:0]),
      .m_axi_awburst						(m_axi_awburst[1:0]),
      .m_axi_awlock						(m_axi_awlock),
      .m_axi_awcache						(m_axi_awcache[3:0]),
      .m_axi_awprot						(m_axi_awprot[2:0]),
      .m_axi_awqos						(m_axi_awqos[3:0]),
      .m_axi_awregion						(m_axi_awregion[3:0]),
      .m_axi_awuser						(m_axi_awuser[M_AXI_USER_WIDTH-1:0]),
      .m_axi_awvalid						(m_axi_awvalid),
      .m_axi_wdata						(m_axi_wdata[M_AXI_DATA_WIDTH-1:0]),
      .m_axi_wstrb						(m_axi_wstrb[M_AXI_DATA_WIDTH/8-1:0]),
      .m_axi_wlast						(m_axi_wlast),
      .m_axi_wuser						(m_axi_wuser[M_AXI_USER_WIDTH-1:0]),
      .m_axi_wvalid						(m_axi_wvalid),
      .m_axi_bready						(m_axi_bready),
      .m_axi_arid							(m_axi_arid[M_AXI_ID_WIDTH-1:0]),
      .m_axi_araddr						(m_axi_araddr[M_AXI_ADDR_WIDTH-1:0]),
      .m_axi_arlen						(m_axi_arlen[7:0]),
      .m_axi_arsize						(m_axi_arsize[2:0]),
      .m_axi_arburst						(m_axi_arburst[1:0]),
      .m_axi_arlock						(m_axi_arlock),
      .m_axi_arcache						(m_axi_arcache[3:0]),
      .m_axi_arprot						(m_axi_arprot[2:0]),
      .m_axi_arqos						(m_axi_arqos[3:0]),
      .m_axi_arregion						(m_axi_arregion[3:0]),
      .m_axi_aruser						(m_axi_aruser[M_AXI_USER_WIDTH-1:0]),
      .m_axi_arvalid						(m_axi_arvalid),
      .m_axi_rready						(m_axi_rready),
      .m_axi_usr_awid						(m_axi_usr_awid[M_AXI_USR_ID_WIDTH-1:0]),
      .m_axi_usr_awaddr					(m_axi_usr_awaddr[M_AXI_USR_ADDR_WIDTH-1:0]),
      .m_axi_usr_awlen					(m_axi_usr_awlen[7:0]),
      .m_axi_usr_awsize					(m_axi_usr_awsize[2:0]),
      .m_axi_usr_awburst					(m_axi_usr_awburst[1:0]),
      .m_axi_usr_awlock					(awlock),
      .m_axi_usr_awcache					(m_axi_usr_awcache[3:0]),
      .m_axi_usr_awprot					(m_axi_usr_awprot[2:0]),
      .m_axi_usr_awqos					(m_axi_usr_awqos[3:0]),
      .m_axi_usr_awregion					(m_axi_usr_awregion[3:0]),
      .m_axi_usr_awuser					(m_axi_usr_awuser),
      .m_axi_usr_awvalid					(m_axi_usr_awvalid),
      .m_axi_usr_wdata					(m_axi_usr_wdata[M_AXI_USR_DATA_WIDTH-1:0]),
      .m_axi_usr_wstrb					(m_axi_usr_wstrb[(M_AXI_USR_DATA_WIDTH/8)-1:0]),
      .m_axi_usr_wlast					(m_axi_usr_wlast),
      .m_axi_usr_wuser					(m_axi_usr_wuser),
      .m_axi_usr_wvalid					(m_axi_usr_wvalid),
      .m_axi_usr_bready					(m_axi_usr_bready),
      .m_axi_usr_arid						(m_axi_usr_arid[M_AXI_USR_ID_WIDTH-1:0]),
      .m_axi_usr_araddr					(m_axi_usr_araddr[M_AXI_USR_ADDR_WIDTH-1:0]),
      .m_axi_usr_arlen					(m_axi_usr_arlen[7:0]),
      .m_axi_usr_arsize					(m_axi_usr_arsize[2:0]),
      .m_axi_usr_arburst					(m_axi_usr_arburst[1:0]),
      .m_axi_usr_arlock					(arlock),
      .m_axi_usr_arcache					(m_axi_usr_arcache[3:0]),
      .m_axi_usr_arprot					(m_axi_usr_arprot[2:0]),
      .m_axi_usr_arqos					(m_axi_usr_arqos[3:0]),
      .m_axi_usr_arregion					(m_axi_usr_arregion[3:0]),
      .m_axi_usr_aruser					(m_axi_usr_aruser),
      .m_axi_usr_arvalid					(m_axi_usr_arvalid),
      .m_axi_usr_rready					(m_axi_usr_rready),
      //	.m_axi_usr_wid						(m_axi_usr_wid[M_AXI_USR_ID_WIDTH-1:0]),
      .h2c_pulse_out				(h2c_pulse_out),
      // Inputs
      .axi_aclk							(axi_aclk),
      .axi_aresetn						(axi_aresetn),
      .irq_ack							(irq_ack),
      .c2h_intr_in						(c2h_intr_in),
      .c2h_gpio_in						(c2h_gpio_in),
      .h2c_gpio_out                       (h2c_gpio_out),
      .s_axi_awaddr						(s_axi_awaddr[S_AXI_ADDR_WIDTH-1:0]),
      .s_axi_awprot						(s_axi_awprot[2:0]),
      .s_axi_awvalid						(s_axi_awvalid),
      .s_axi_wdata						(s_axi_wdata[S_AXI_DATA_WIDTH-1:0]),
      .s_axi_wstrb						(s_axi_wstrb[(S_AXI_DATA_WIDTH/8)-1:0]),
      .s_axi_wvalid						(s_axi_wvalid),
      .s_axi_bready						(s_axi_bready),
      .s_axi_araddr						(s_axi_araddr[S_AXI_ADDR_WIDTH-1:0]),
      .s_axi_arprot						(s_axi_arprot[2:0]),
      .s_axi_arvalid						(s_axi_arvalid),
      .s_axi_rready						(s_axi_rready),
      .m_axi_awready						(m_axi_awready),
      .m_axi_wready						(m_axi_wready),
      .m_axi_bid							(m_axi_bid[M_AXI_ID_WIDTH-1:0]),
      .m_axi_bresp						(m_axi_bresp[1:0]),
      .m_axi_buser						(m_axi_buser[M_AXI_USER_WIDTH-1:0]),
      .m_axi_bvalid						(m_axi_bvalid),
      .m_axi_arready						(m_axi_arready),
      .m_axi_rid							(m_axi_rid[M_AXI_ID_WIDTH-1:0]),
      .m_axi_rdata						(m_axi_rdata[M_AXI_DATA_WIDTH-1:0]),
      .m_axi_rresp						(m_axi_rresp[1:0]),
      .m_axi_rlast						(m_axi_rlast),
      .m_axi_ruser						(m_axi_ruser[M_AXI_USER_WIDTH-1:0]),
      .m_axi_rvalid						(m_axi_rvalid),
      .m_axi_usr_awready					(m_axi_usr_awready),
      .m_axi_usr_wready					(m_axi_usr_wready),
      .m_axi_usr_bid						(m_axi_usr_bid[M_AXI_USR_ID_WIDTH-1:0]),
      .m_axi_usr_bresp					(m_axi_usr_bresp[1:0]),
      .m_axi_usr_buser					(m_axi_usr_buser),
      .m_axi_usr_bvalid					(m_axi_usr_bvalid),
      .m_axi_usr_arready					(m_axi_usr_arready),
      .m_axi_usr_rid						(m_axi_usr_rid[M_AXI_USR_ID_WIDTH-1:0]),
      .m_axi_usr_rdata					(m_axi_usr_rdata[M_AXI_USR_DATA_WIDTH-1:0]),
      .m_axi_usr_rresp					(m_axi_usr_rresp[1:0]),
      .m_axi_usr_rlast					(m_axi_usr_rlast),
      .m_axi_usr_ruser					(m_axi_usr_ruser),
      .m_axi_usr_rvalid					(m_axi_usr_rvalid));
   
endmodule 

// Local Variables:
// verilog-library-directories:("./")
// End:


