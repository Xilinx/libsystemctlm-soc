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
 *   Top module for posh Full ACE mst bridge.
 *
 *
 */
`include "ace_defines_common.vh"
module acefull_mst #(

                        parameter S_AXI_ADDR_WIDTH               = 64 
                        ,parameter S_AXI_DATA_WIDTH               = 32 
   
                        ,parameter M_AXI_ADDR_WIDTH               = 64 
                        ,parameter M_AXI_DATA_WIDTH               = 128
                        ,parameter M_AXI_ID_WIDTH                 = 16 
                        ,parameter M_AXI_USER_WIDTH               = 32 
   
                        ,parameter M_ACE_USR_ADDR_WIDTH           = 64 
                        ,parameter M_ACE_USR_XX_DATA_WIDTH        = 128       //rdata,wdata width
                        ,parameter M_ACE_USR_SN_DATA_WIDTH        = 128       //Allowed values : (M_ACE_USR_XX_DATA_WIDTH) //cddata width
                        ,parameter M_ACE_USR_ID_WIDTH             = 16 
                        ,parameter M_ACE_USR_AWUSER_WIDTH         = 32 
                        ,parameter M_ACE_USR_WUSER_WIDTH          = 32 
                        ,parameter M_ACE_USR_BUSER_WIDTH          = 32 
                        ,parameter M_ACE_USR_ARUSER_WIDTH         = 32 
                        ,parameter M_ACE_USR_RUSER_WIDTH          = 32 
   
                        ,parameter CACHE_LINE_SIZE                = 64 
                        ,parameter XX_MAX_DESC                    = 16         //Max number of read,write descriptors 
                        ,parameter SN_MAX_DESC                    = 16         //Allowed values : (XX_MAX_DESC) //Max number of snoop descriptors
                        ,parameter XX_RAM_SIZE                    = 16384     //Size of rdata,wdata,wstrb RAM in Bytes
                        ,parameter SN_RAM_SIZE                    = 1024       //Allowed values : (SN_MAX_DESC*CACHE_LINE_WIDTH) //Snoop data RAM size
                        ,parameter USR_RST_NUM                    = 4     
		        ,parameter LAST_BRIDGE                    = 0
			,parameter EXTEND_WSTRB                   = 1
   
                        )(
   
                          //Clock and reset
                          input clk 
			  ,input resetn 
			  ,output [USR_RST_NUM-1:0] usr_resetn
			  //System Interrupt  
			  ,output irq_out 
			  ,input irq_ack 
			  //DUT Interrupt
			  ,output [127:0] h2c_intr_out
			  ,input [63:0] c2h_intr_in
			  //DUT GPIO
			  ,input [255:0] c2h_gpio_in
			  ,output [255:0] h2c_gpio_out

			  // S_AXI - AXI4-Lite
			  ,input wire [S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr
			  ,input wire [2:0] s_axi_awprot
			  ,input wire s_axi_awvalid
			  ,output wire s_axi_awready
			  ,input wire [S_AXI_DATA_WIDTH-1:0] s_axi_wdata
			  ,input wire [(S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb
			  ,input wire s_axi_wvalid
			  ,output wire s_axi_wready
			  ,output wire [1:0] s_axi_bresp
			  ,output wire s_axi_bvalid
			  ,input wire s_axi_bready
			  ,input wire [S_AXI_ADDR_WIDTH-1:0] s_axi_araddr
			  ,input wire [2:0] s_axi_arprot
			  ,input wire s_axi_arvalid
			  ,output wire s_axi_arready
			  ,output wire [S_AXI_DATA_WIDTH-1:0] s_axi_rdata
			  ,output wire [1:0] s_axi_rresp
			  ,output wire s_axi_rvalid
			  ,input wire s_axi_rready 

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

			  //M_ACE_USR
			  ,output[M_ACE_USR_ID_WIDTH-1:0] m_ace_usr_awid 
			  ,output[M_ACE_USR_ADDR_WIDTH-1:0] m_ace_usr_awaddr 
			  ,output[7:0] m_ace_usr_awlen
			  ,output[2:0] m_ace_usr_awsize 
			  ,output[1:0] m_ace_usr_awburst 
			  ,output m_ace_usr_awlock 
			  ,output[3:0] m_ace_usr_awcache 
			  ,output[2:0] m_ace_usr_awprot 
			  ,output[3:0] m_ace_usr_awqos 
			  ,output[3:0] m_ace_usr_awregion 
			  ,output[M_ACE_USR_AWUSER_WIDTH-1:0] m_ace_usr_awuser 
			  ,output[2:0] m_ace_usr_awsnoop 
			  ,output[1:0] m_ace_usr_awdomain 
			  ,output[1:0] m_ace_usr_awbar 
			  ,output m_ace_usr_awunique 
			  ,output m_ace_usr_awvalid 
			  ,input m_ace_usr_awready 
			  ,output[M_ACE_USR_XX_DATA_WIDTH-1:0] m_ace_usr_wdata 
			  ,output[(M_ACE_USR_XX_DATA_WIDTH/8)-1:0] m_ace_usr_wstrb
			  ,output m_ace_usr_wlast 
			  ,output[M_ACE_USR_WUSER_WIDTH-1:0] m_ace_usr_wuser 
			  ,output m_ace_usr_wvalid 
			  ,input m_ace_usr_wready 
			  ,input [M_ACE_USR_ID_WIDTH-1:0] m_ace_usr_bid 
			  ,input [1:0] m_ace_usr_bresp 
			  ,input [M_ACE_USR_BUSER_WIDTH-1:0] m_ace_usr_buser 
			  ,input m_ace_usr_bvalid 
			  ,output m_ace_usr_bready 
			  ,output m_ace_usr_wack 
			  ,output[M_ACE_USR_ID_WIDTH-1:0] m_ace_usr_arid 
			  ,output[M_ACE_USR_ADDR_WIDTH-1:0] m_ace_usr_araddr 
			  ,output[7:0] m_ace_usr_arlen 
			  ,output[2:0] m_ace_usr_arsize 
			  ,output[1:0] m_ace_usr_arburst 
			  ,output m_ace_usr_arlock 
			  ,output[3:0] m_ace_usr_arcache 
			  ,output[2:0] m_ace_usr_arprot 
			  ,output[3:0] m_ace_usr_arqos 
			  ,output[3:0] m_ace_usr_arregion 
			  ,output[M_ACE_USR_ARUSER_WIDTH-1:0] m_ace_usr_aruser 
			  ,output[3:0] m_ace_usr_arsnoop 
			  ,output[1:0] m_ace_usr_ardomain 
			  ,output[1:0] m_ace_usr_arbar 
			  ,output m_ace_usr_arvalid 
			  ,input m_ace_usr_arready 
			  ,input [M_ACE_USR_ID_WIDTH-1:0] m_ace_usr_rid 
			  ,input [M_ACE_USR_XX_DATA_WIDTH-1:0] m_ace_usr_rdata 
			  ,input [3:0] m_ace_usr_rresp 
			  ,input m_ace_usr_rlast 
			  ,input [M_ACE_USR_RUSER_WIDTH-1:0] m_ace_usr_ruser 
			  ,input m_ace_usr_rvalid 
			  ,output m_ace_usr_rready 
			  ,output m_ace_usr_rack 
			  ,input [M_ACE_USR_ADDR_WIDTH-1:0] m_ace_usr_acaddr 
			  ,input [3:0] m_ace_usr_acsnoop 
			  ,input [2:0] m_ace_usr_acprot 
			  ,input m_ace_usr_acvalid 
			  ,output m_ace_usr_acready 
			  ,output [4:0] m_ace_usr_crresp 
			  ,output m_ace_usr_crvalid 
			  ,input m_ace_usr_crready 
			  ,output [M_ACE_USR_SN_DATA_WIDTH-1:0] m_ace_usr_cddata 
			  ,output m_ace_usr_cdlast 
			  ,output m_ace_usr_cdvalid 
			  ,input m_ace_usr_cdready   

                          );

   localparam ACE_PROTOCOL = "FULLACE";
   
   
   ace_mst_allprot #(/*AUTOINSTPARAM*/
			// Parameters
			.ACE_PROTOCOL             (ACE_PROTOCOL),
			.S_AXI_ADDR_WIDTH         (S_AXI_ADDR_WIDTH),
			.S_AXI_DATA_WIDTH         (S_AXI_DATA_WIDTH),
			.M_AXI_ADDR_WIDTH         (M_AXI_ADDR_WIDTH),
			.M_AXI_DATA_WIDTH         (M_AXI_DATA_WIDTH),
			.M_AXI_ID_WIDTH           (M_AXI_ID_WIDTH),
			.M_AXI_USER_WIDTH         (M_AXI_USER_WIDTH),
			.M_ACE_USR_ADDR_WIDTH     (M_ACE_USR_ADDR_WIDTH),
			.M_ACE_USR_XX_DATA_WIDTH  (M_ACE_USR_XX_DATA_WIDTH),
			.M_ACE_USR_SN_DATA_WIDTH  (M_ACE_USR_SN_DATA_WIDTH),
			.M_ACE_USR_ID_WIDTH       (M_ACE_USR_ID_WIDTH),
			.M_ACE_USR_AWUSER_WIDTH   (M_ACE_USR_AWUSER_WIDTH),
			.M_ACE_USR_WUSER_WIDTH    (M_ACE_USR_WUSER_WIDTH),
			.M_ACE_USR_BUSER_WIDTH    (M_ACE_USR_BUSER_WIDTH),
			.M_ACE_USR_ARUSER_WIDTH   (M_ACE_USR_ARUSER_WIDTH),
			.M_ACE_USR_RUSER_WIDTH    (M_ACE_USR_RUSER_WIDTH),
			.CACHE_LINE_SIZE          (CACHE_LINE_SIZE),
			.XX_MAX_DESC              (XX_MAX_DESC),
			.SN_MAX_DESC              (SN_MAX_DESC),
			.XX_RAM_SIZE              (XX_RAM_SIZE),
			.SN_RAM_SIZE              (SN_RAM_SIZE),
			.USR_RST_NUM              (USR_RST_NUM),
			.EXTEND_WSTRB		(EXTEND_WSTRB)
      
      
			)i_ace_mst_allprot (/*AUTOINST*/
                                               // Outputs
                                               .usr_resetn        (usr_resetn),
                                               .irq_out           (irq_out),
                                               .h2c_intr_out      (h2c_intr_out),
                                               .h2c_gpio_out      (h2c_gpio_out),
                                               .s_axi_awready     (s_axi_awready),
                                               .s_axi_wready      (s_axi_wready),
                                               .s_axi_bresp       (s_axi_bresp),
                                               .s_axi_bvalid      (s_axi_bvalid),
                                               .s_axi_arready     (s_axi_arready),
                                               .s_axi_rdata       (s_axi_rdata),
                                               .s_axi_rresp       (s_axi_rresp),
                                               .s_axi_rvalid      (s_axi_rvalid),
                                               .m_axi_awid        (m_axi_awid),
                                               .m_axi_awaddr      (m_axi_awaddr),
                                               .m_axi_awlen       (m_axi_awlen),
                                               .m_axi_awsize      (m_axi_awsize),
                                               .m_axi_awburst     (m_axi_awburst),
                                               .m_axi_awlock      (m_axi_awlock),
                                               .m_axi_awcache     (m_axi_awcache),
                                               .m_axi_awprot      (m_axi_awprot),
                                               .m_axi_awqos       (m_axi_awqos),
                                               .m_axi_awregion    (m_axi_awregion),
                                               .m_axi_awuser      (m_axi_awuser),
                                               .m_axi_awvalid     (m_axi_awvalid),
                                               .m_axi_wdata       (m_axi_wdata),
                                               .m_axi_wstrb       (m_axi_wstrb),
                                               .m_axi_wlast       (m_axi_wlast),
                                               .m_axi_wuser       (m_axi_wuser),
                                               .m_axi_wvalid      (m_axi_wvalid),
                                               .m_axi_bready      (m_axi_bready),
                                               .m_axi_arid        (m_axi_arid),
                                               .m_axi_araddr      (m_axi_araddr),
                                               .m_axi_arlen       (m_axi_arlen),
                                               .m_axi_arsize      (m_axi_arsize),
                                               .m_axi_arburst     (m_axi_arburst),
                                               .m_axi_arlock      (m_axi_arlock),
                                               .m_axi_arcache     (m_axi_arcache),
                                               .m_axi_arprot      (m_axi_arprot),
                                               .m_axi_arqos       (m_axi_arqos),
                                               .m_axi_arregion    (m_axi_arregion),
                                               .m_axi_aruser      (m_axi_aruser),
                                               .m_axi_arvalid     (m_axi_arvalid),
                                               .m_axi_rready      (m_axi_rready),
                                               .m_ace_usr_awready (m_ace_usr_awready),
                                               .m_ace_usr_wready  (m_ace_usr_wready),
                                               .m_ace_usr_bid     (m_ace_usr_bid),
                                               .m_ace_usr_bresp   (m_ace_usr_bresp),
                                               .m_ace_usr_buser   (m_ace_usr_buser),
                                               .m_ace_usr_bvalid  (m_ace_usr_bvalid),
                                               .m_ace_usr_arready (m_ace_usr_arready),
                                               .m_ace_usr_rid     (m_ace_usr_rid),
                                               .m_ace_usr_rdata   (m_ace_usr_rdata),
                                               .m_ace_usr_rresp   (m_ace_usr_rresp),
                                               .m_ace_usr_rlast   (m_ace_usr_rlast),
                                               .m_ace_usr_ruser   (m_ace_usr_ruser),
                                               .m_ace_usr_rvalid  (m_ace_usr_rvalid),
                                               .m_ace_usr_acaddr  (m_ace_usr_acaddr),
                                               .m_ace_usr_acsnoop (m_ace_usr_acsnoop),
                                               .m_ace_usr_acprot  (m_ace_usr_acprot),
                                               .m_ace_usr_acvalid (m_ace_usr_acvalid),
                                               .m_ace_usr_crready (m_ace_usr_crready),
                                               .m_ace_usr_cdready (m_ace_usr_cdready),
                                               // Inputs
                                               .clk               (clk),
                                               .resetn            (resetn),
                                               .irq_ack           (irq_ack),
                                               .c2h_intr_in       (c2h_intr_in),
                                               .c2h_gpio_in       (c2h_gpio_in),
                                               .s_axi_awaddr      (s_axi_awaddr),
                                               .s_axi_awprot      (s_axi_awprot),
                                               .s_axi_awvalid     (s_axi_awvalid),
                                               .s_axi_wdata       (s_axi_wdata),
                                               .s_axi_wstrb       (s_axi_wstrb),
                                               .s_axi_wvalid      (s_axi_wvalid),
                                               .s_axi_bready      (s_axi_bready),
                                               .s_axi_araddr      (s_axi_araddr),
                                               .s_axi_arprot      (s_axi_arprot),
                                               .s_axi_arvalid     (s_axi_arvalid),
                                               .s_axi_rready      (s_axi_rready),
                                               .m_axi_awready     (m_axi_awready),
                                               .m_axi_wready      (m_axi_wready),
                                               .m_axi_bid         (m_axi_bid),
                                               .m_axi_bresp       (m_axi_bresp),
                                               .m_axi_buser       (m_axi_buser),
                                               .m_axi_bvalid      (m_axi_bvalid),
                                               .m_axi_arready     (m_axi_arready),
                                               .m_axi_rid         (m_axi_rid),
                                               .m_axi_rdata       (m_axi_rdata),
                                               .m_axi_rresp       (m_axi_rresp),
                                               .m_axi_rlast       (m_axi_rlast),
                                               .m_axi_ruser       (m_axi_ruser),
                                               .m_axi_rvalid      (m_axi_rvalid),
                                               .m_ace_usr_awid    (m_ace_usr_awid),
                                               .m_ace_usr_awaddr  (m_ace_usr_awaddr),
                                               .m_ace_usr_awlen   (m_ace_usr_awlen),
                                               .m_ace_usr_awsize  (m_ace_usr_awsize),
                                               .m_ace_usr_awburst (m_ace_usr_awburst),
                                               .m_ace_usr_awlock  (m_ace_usr_awlock),
                                               .m_ace_usr_awcache (m_ace_usr_awcache),
                                               .m_ace_usr_awprot  (m_ace_usr_awprot),
                                               .m_ace_usr_awqos   (m_ace_usr_awqos),
                                               .m_ace_usr_awregion(m_ace_usr_awregion),
                                               .m_ace_usr_awuser  (m_ace_usr_awuser),
                                               .m_ace_usr_awsnoop (m_ace_usr_awsnoop),
                                               .m_ace_usr_awdomain(m_ace_usr_awdomain),
                                               .m_ace_usr_awbar   (m_ace_usr_awbar),
                                               .m_ace_usr_awunique(m_ace_usr_awunique),
                                               .m_ace_usr_awvalid (m_ace_usr_awvalid),
                                               .m_ace_usr_wdata   (m_ace_usr_wdata),
                                               .m_ace_usr_wstrb   (m_ace_usr_wstrb),
                                               .m_ace_usr_wlast   (m_ace_usr_wlast),
                                               .m_ace_usr_wuser   (m_ace_usr_wuser),
                                               .m_ace_usr_wvalid  (m_ace_usr_wvalid),
                                               .m_ace_usr_bready  (m_ace_usr_bready),
                                               .m_ace_usr_wack    (m_ace_usr_wack),
                                               .m_ace_usr_arid    (m_ace_usr_arid),
                                               .m_ace_usr_araddr  (m_ace_usr_araddr),
                                               .m_ace_usr_arlen   (m_ace_usr_arlen),
                                               .m_ace_usr_arsize  (m_ace_usr_arsize),
                                               .m_ace_usr_arburst (m_ace_usr_arburst),
                                               .m_ace_usr_arlock  (m_ace_usr_arlock),
                                               .m_ace_usr_arcache (m_ace_usr_arcache),
                                               .m_ace_usr_arprot  (m_ace_usr_arprot),
                                               .m_ace_usr_arqos   (m_ace_usr_arqos),
                                               .m_ace_usr_arregion(m_ace_usr_arregion),
                                               .m_ace_usr_aruser  (m_ace_usr_aruser),
                                               .m_ace_usr_arsnoop (m_ace_usr_arsnoop),
                                               .m_ace_usr_ardomain(m_ace_usr_ardomain),
                                               .m_ace_usr_arbar   (m_ace_usr_arbar),
                                               .m_ace_usr_arvalid (m_ace_usr_arvalid),
                                               .m_ace_usr_rready  (m_ace_usr_rready),
                                               .m_ace_usr_rack    (m_ace_usr_rack),
                                               .m_ace_usr_acready (m_ace_usr_acready),
                                               .m_ace_usr_crresp  (m_ace_usr_crresp),
                                               .m_ace_usr_crvalid (m_ace_usr_crvalid),
                                               .m_ace_usr_cddata  (m_ace_usr_cddata),
                                               .m_ace_usr_cdlast  (m_ace_usr_cdlast),
                                               .m_ace_usr_cdvalid (m_ace_usr_cdvalid));




endmodule 


// Local Variables:
// verilog-library-directories:("./")
// End:

