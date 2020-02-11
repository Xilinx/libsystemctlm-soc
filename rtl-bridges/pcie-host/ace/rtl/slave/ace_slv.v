/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Meera Bagdai. 
 * 
 * Permission is hereby granted free of charge to any person obtaining a copy 
 * of this software and associated documentation files (the 'Software') to deal 
 * in the Software without restriction including without limitation the rights 
 * to use copy modify merge publish distribute sublicense and/or sell 
 * copies of the Software and to permit persons to whom the Software is 
 * furnished to do so subject to the following conditions: 
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS' WITHOUT WARRANTY OF ANY KIND EXPRESS OR
 * IMPLIED INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM DAMAGES OR OTHER
 * LIABILITY WHETHER IN AN ACTION OF CONTRACT TORT OR OTHERWISE ARISING FROM
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 * Description: 
 *   Top module for ACE slave bridge.
 *
 *
 */
`include "ace_defines_common.vh"
module ace_slv #(
                  parameter ACE_PROTOCOL                   = "FULLACE" //Allowed values : "FULLACE"    
                  
                  ,parameter S_AXI_ADDR_WIDTH               = 64 //Allowed values : 32,64   
                  ,parameter S_AXI_DATA_WIDTH               = 32 //Allowed values : 32    
                  
                  ,parameter M_AXI_ADDR_WIDTH               = 64  //Allowed values : Upto 64  
                  ,parameter M_AXI_DATA_WIDTH               = 128 //Allowed values : 128
                  ,parameter M_AXI_ID_WIDTH                 = 16  //Allowed values : log2(MAX_DESC) to 16
                  ,parameter M_AXI_USER_WIDTH               = 32  //Allowed values : 1 to 32  
                  
                  ,parameter S_ACE_USR_ADDR_WIDTH           = 64  //Allowed values : Upto 64       //araddr,awaddr,acaddr width
                  ,parameter S_ACE_USR_DATA_WIDTH           = 128 //Allowed values : 128           //rdata,wdata,cddata width
                  ,parameter S_ACE_USR_ID_WIDTH             = 16  //Allowed values : 1 to 16
                  ,parameter S_ACE_USR_AWUSER_WIDTH         = 32  //Allowed values : 1 to 32  
                  ,parameter S_ACE_USR_WUSER_WIDTH          = 32  //Allowed values : 1 to 32  
                  ,parameter S_ACE_USR_BUSER_WIDTH          = 32  //Allowed values : 1 to 32  
                  ,parameter S_ACE_USR_ARUSER_WIDTH         = 32  //Allowed values : 1 to 32  
                  ,parameter S_ACE_USR_RUSER_WIDTH          = 32  //Allowed values : 1 to 32  
                  
                  ,parameter CACHE_LINE_SIZE                = 64    //Size of Cache line in Bytes
                  ,parameter MAX_DESC                       = 16     //Max number of read,write,snoop descriptors 
                  ,parameter RAM_SIZE                       = 16384 //Size of rdata,wdata,wstrb RAM in Bytes
                  ,parameter USR_RST_NUM                    = 4      //Allowed values : 1 to 31 
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
   
		    //S_ACE_USR
		    ,input [S_ACE_USR_ID_WIDTH-1:0] s_ace_usr_awid 
		    ,input [S_ACE_USR_ADDR_WIDTH-1:0] s_ace_usr_awaddr 
		    ,input [7:0] s_ace_usr_awlen
		    ,input [2:0] s_ace_usr_awsize 
		    ,input [1:0] s_ace_usr_awburst 
		    ,input s_ace_usr_awlock 
		    ,input [3:0] s_ace_usr_awcache 
		    ,input [2:0] s_ace_usr_awprot 
		    ,input [3:0] s_ace_usr_awqos 
		    ,input [3:0] s_ace_usr_awregion 
		    ,input [S_ACE_USR_AWUSER_WIDTH-1:0] s_ace_usr_awuser 
		    ,input [2:0] s_ace_usr_awsnoop 
		    ,input [1:0] s_ace_usr_awdomain 
		    ,input [1:0] s_ace_usr_awbar 
		    ,input s_ace_usr_awunique 
		    ,input s_ace_usr_awvalid 
		    ,output s_ace_usr_awready 
		    ,input [S_ACE_USR_DATA_WIDTH-1:0] s_ace_usr_wdata 
		    ,input [(S_ACE_USR_DATA_WIDTH/8)-1:0] s_ace_usr_wstrb
		    ,input s_ace_usr_wlast 
		    ,input [S_ACE_USR_WUSER_WIDTH-1:0] s_ace_usr_wuser 
		    ,input s_ace_usr_wvalid 
		    ,output s_ace_usr_wready 
		    ,output [S_ACE_USR_ID_WIDTH-1:0] s_ace_usr_bid 
		    ,output [1:0] s_ace_usr_bresp 
		    ,output [S_ACE_USR_BUSER_WIDTH-1:0] s_ace_usr_buser 
		    ,output s_ace_usr_bvalid 
		    ,input s_ace_usr_bready 
		    ,input s_ace_usr_wack 
		    ,input [S_ACE_USR_ID_WIDTH-1:0] s_ace_usr_arid 
		    ,input [S_ACE_USR_ADDR_WIDTH-1:0] s_ace_usr_araddr 
		    ,input [7:0] s_ace_usr_arlen 
		    ,input [2:0] s_ace_usr_arsize 
		    ,input [1:0] s_ace_usr_arburst 
		    ,input s_ace_usr_arlock 
		    ,input [3:0] s_ace_usr_arcache 
		    ,input [2:0] s_ace_usr_arprot 
		    ,input [3:0] s_ace_usr_arqos 
		    ,input [3:0] s_ace_usr_arregion 
		    ,input [S_ACE_USR_ARUSER_WIDTH-1:0] s_ace_usr_aruser 
		    ,input [3:0] s_ace_usr_arsnoop 
		    ,input [1:0] s_ace_usr_ardomain 
		    ,input [1:0] s_ace_usr_arbar 
		    ,input s_ace_usr_arvalid 
		    ,output s_ace_usr_arready 
		    ,output [S_ACE_USR_ID_WIDTH-1:0] s_ace_usr_rid 
		    ,output [S_ACE_USR_DATA_WIDTH-1:0] s_ace_usr_rdata 
		    ,output [3:0] s_ace_usr_rresp 
		    ,output s_ace_usr_rlast 
		    ,output [S_ACE_USR_RUSER_WIDTH-1:0] s_ace_usr_ruser 
		    ,output s_ace_usr_rvalid 
		    ,input s_ace_usr_rready 
		    ,input s_ace_usr_rack 
		    ,output [S_ACE_USR_ADDR_WIDTH-1:0] s_ace_usr_acaddr 
		    ,output [3:0] s_ace_usr_acsnoop 
		    ,output [2:0] s_ace_usr_acprot 
		    ,output s_ace_usr_acvalid 
		    ,input s_ace_usr_acready 
		    ,input [4:0] s_ace_usr_crresp 
		    ,input s_ace_usr_crvalid 
		    ,output s_ace_usr_crready 
		    ,input [S_ACE_USR_DATA_WIDTH-1:0] s_ace_usr_cddata 
		    ,input s_ace_usr_cdlast 
		    ,input s_ace_usr_cdvalid 
		    ,output s_ace_usr_cdready   
   
                    );


   acefull_slv #(
                  .S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH),
                  .S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH),
                  .M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH),
                  .M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH),
                  .M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH),
                  .M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH),
                  .S_ACE_USR_ADDR_WIDTH         (S_ACE_USR_ADDR_WIDTH),
                  .S_ACE_USR_XX_DATA_WIDTH      (S_ACE_USR_DATA_WIDTH),
                  .S_ACE_USR_SN_DATA_WIDTH      (S_ACE_USR_DATA_WIDTH),
                  .S_ACE_USR_ID_WIDTH           (S_ACE_USR_ID_WIDTH),
                  .S_ACE_USR_AWUSER_WIDTH       (S_ACE_USR_AWUSER_WIDTH),
                  .S_ACE_USR_WUSER_WIDTH        (S_ACE_USR_WUSER_WIDTH),
                  .S_ACE_USR_BUSER_WIDTH        (S_ACE_USR_BUSER_WIDTH),
                  .S_ACE_USR_ARUSER_WIDTH       (S_ACE_USR_ARUSER_WIDTH),
                  .S_ACE_USR_RUSER_WIDTH        (S_ACE_USR_RUSER_WIDTH),
                  .CACHE_LINE_SIZE              (CACHE_LINE_SIZE),
                  .XX_MAX_DESC                  (MAX_DESC),
                  .SN_MAX_DESC                  (MAX_DESC),
                  .XX_RAM_SIZE                  (RAM_SIZE),
                  .SN_RAM_SIZE                  (MAX_DESC*CACHE_LINE_SIZE),  //SN_MAX_DESC*CACHE_LINE_SIZE
                  .USR_RST_NUM                  (USR_RST_NUM),
                  .EXTEND_WSTRB		      (EXTEND_WSTRB)
		  )i_acefull_slv (
				   .usr_resetn       (usr_resetn),
				   .irq_out          (irq_out),
				   .h2c_intr_out     (h2c_intr_out),
				   .h2c_gpio_out     (h2c_gpio_out),
				   .s_axi_awready    (s_axi_awready),
				   .s_axi_wready     (s_axi_wready),
				   .s_axi_bresp      (s_axi_bresp),
				   .s_axi_bvalid     (s_axi_bvalid),
				   .s_axi_arready    (s_axi_arready),
				   .s_axi_rdata      (s_axi_rdata),
				   .s_axi_rresp      (s_axi_rresp),
				   .s_axi_rvalid     (s_axi_rvalid),
				   .m_axi_awid       (m_axi_awid),
				   .m_axi_awaddr     (m_axi_awaddr),
				   .m_axi_awlen      (m_axi_awlen),
				   .m_axi_awsize     (m_axi_awsize),
				   .m_axi_awburst    (m_axi_awburst),
				   .m_axi_awlock     (m_axi_awlock),
				   .m_axi_awcache    (m_axi_awcache),
				   .m_axi_awprot     (m_axi_awprot),
				   .m_axi_awqos      (m_axi_awqos),
				   .m_axi_awregion   (m_axi_awregion),
				   .m_axi_awuser     (m_axi_awuser),
				   .m_axi_awvalid    (m_axi_awvalid),
				   .m_axi_wdata      (m_axi_wdata),
				   .m_axi_wstrb      (m_axi_wstrb),
				   .m_axi_wlast      (m_axi_wlast),
				   .m_axi_wuser      (m_axi_wuser),
				   .m_axi_wvalid     (m_axi_wvalid),
				   .m_axi_bready     (m_axi_bready),
				   .m_axi_arid       (m_axi_arid),
				   .m_axi_araddr     (m_axi_araddr),
				   .m_axi_arlen      (m_axi_arlen),
				   .m_axi_arsize     (m_axi_arsize),
				   .m_axi_arburst    (m_axi_arburst),
				   .m_axi_arlock     (m_axi_arlock),
				   .m_axi_arcache    (m_axi_arcache),
				   .m_axi_arprot     (m_axi_arprot),
				   .m_axi_arqos      (m_axi_arqos),
				   .m_axi_arregion   (m_axi_arregion),
				   .m_axi_aruser     (m_axi_aruser),
				   .m_axi_arvalid    (m_axi_arvalid),
				   .m_axi_rready     (m_axi_rready),
				   .s_ace_usr_awready(s_ace_usr_awready),
				   .s_ace_usr_wready (s_ace_usr_wready),
				   .s_ace_usr_bid    (s_ace_usr_bid),
				   .s_ace_usr_bresp  (s_ace_usr_bresp),
				   .s_ace_usr_buser  (s_ace_usr_buser),
				   .s_ace_usr_bvalid (s_ace_usr_bvalid),
				   .s_ace_usr_arready(s_ace_usr_arready),
				   .s_ace_usr_rid    (s_ace_usr_rid),
				   .s_ace_usr_rdata  (s_ace_usr_rdata),
				   .s_ace_usr_rresp  (s_ace_usr_rresp),
				   .s_ace_usr_rlast  (s_ace_usr_rlast),
				   .s_ace_usr_ruser  (s_ace_usr_ruser),
				   .s_ace_usr_rvalid (s_ace_usr_rvalid),
				   .s_ace_usr_acaddr (s_ace_usr_acaddr),
				   .s_ace_usr_acsnoop(s_ace_usr_acsnoop),
				   .s_ace_usr_acprot (s_ace_usr_acprot),
				   .s_ace_usr_acvalid(s_ace_usr_acvalid),
				   .s_ace_usr_crready(s_ace_usr_crready),
				   .s_ace_usr_cdready(s_ace_usr_cdready),
				   .clk         (clk),
				   .resetn      (resetn),
				   .irq_ack          (irq_ack),
				   .c2h_intr_in      (c2h_intr_in),
				   .c2h_gpio_in      (c2h_gpio_in),
				   .s_axi_awaddr     (s_axi_awaddr),
				   .s_axi_awprot     (s_axi_awprot),
				   .s_axi_awvalid    (s_axi_awvalid),
				   .s_axi_wdata      (s_axi_wdata),
				   .s_axi_wstrb      (s_axi_wstrb),
				   .s_axi_wvalid     (s_axi_wvalid),
				   .s_axi_bready     (s_axi_bready),
				   .s_axi_araddr     (s_axi_araddr),
				   .s_axi_arprot     (s_axi_arprot),
				   .s_axi_arvalid    (s_axi_arvalid),
				   .s_axi_rready     (s_axi_rready),
				   .m_axi_awready    (m_axi_awready),
				   .m_axi_wready     (m_axi_wready),
				   .m_axi_bid        (m_axi_bid),
				   .m_axi_bresp      (m_axi_bresp),
				   .m_axi_buser      (m_axi_buser),
				   .m_axi_bvalid     (m_axi_bvalid),
				   .m_axi_arready    (m_axi_arready),
				   .m_axi_rid        (m_axi_rid),
				   .m_axi_rdata      (m_axi_rdata),
				   .m_axi_rresp      (m_axi_rresp),
				   .m_axi_rlast      (m_axi_rlast),
				   .m_axi_ruser      (m_axi_ruser),
				   .m_axi_rvalid     (m_axi_rvalid),
				   .s_ace_usr_awid   (s_ace_usr_awid),
				   .s_ace_usr_awaddr (s_ace_usr_awaddr),
				   .s_ace_usr_awlen  (s_ace_usr_awlen),
				   .s_ace_usr_awsize (s_ace_usr_awsize),
				   .s_ace_usr_awburst(s_ace_usr_awburst),
				   .s_ace_usr_awlock (s_ace_usr_awlock),
				   .s_ace_usr_awcache(s_ace_usr_awcache),
				   .s_ace_usr_awprot (s_ace_usr_awprot),
				   .s_ace_usr_awqos  (s_ace_usr_awqos),
				   .s_ace_usr_awregion(s_ace_usr_awregion),
				   .s_ace_usr_awuser (s_ace_usr_awuser),
				   .s_ace_usr_awsnoop(s_ace_usr_awsnoop),
				   .s_ace_usr_awdomain(s_ace_usr_awdomain),
				   .s_ace_usr_awbar  (s_ace_usr_awbar),
				   .s_ace_usr_awunique(s_ace_usr_awunique),
				   .s_ace_usr_awvalid(s_ace_usr_awvalid),
				   .s_ace_usr_wdata  (s_ace_usr_wdata),
				   .s_ace_usr_wstrb  (s_ace_usr_wstrb),
				   .s_ace_usr_wlast  (s_ace_usr_wlast),
				   .s_ace_usr_wuser  (s_ace_usr_wuser),
				   .s_ace_usr_wvalid (s_ace_usr_wvalid),
				   .s_ace_usr_bready (s_ace_usr_bready),
				   .s_ace_usr_wack   (s_ace_usr_wack),
				   .s_ace_usr_arid   (s_ace_usr_arid),
				   .s_ace_usr_araddr (s_ace_usr_araddr),
				   .s_ace_usr_arlen  (s_ace_usr_arlen),
				   .s_ace_usr_arsize (s_ace_usr_arsize),
				   .s_ace_usr_arburst(s_ace_usr_arburst),
				   .s_ace_usr_arlock (s_ace_usr_arlock),
				   .s_ace_usr_arcache(s_ace_usr_arcache),
				   .s_ace_usr_arprot (s_ace_usr_arprot),
				   .s_ace_usr_arqos  (s_ace_usr_arqos),
				   .s_ace_usr_arregion(s_ace_usr_arregion),
				   .s_ace_usr_aruser (s_ace_usr_aruser),
				   .s_ace_usr_arsnoop(s_ace_usr_arsnoop),
				   .s_ace_usr_ardomain(s_ace_usr_ardomain),
				   .s_ace_usr_arbar  (s_ace_usr_arbar),
				   .s_ace_usr_arvalid(s_ace_usr_arvalid),
				   .s_ace_usr_rready (s_ace_usr_rready),
				   .s_ace_usr_rack   (s_ace_usr_rack),
				   .s_ace_usr_acready(s_ace_usr_acready),
				   .s_ace_usr_crresp (s_ace_usr_crresp),
				   .s_ace_usr_crvalid(s_ace_usr_crvalid),
				   .s_ace_usr_cddata (s_ace_usr_cddata),
				   .s_ace_usr_cdlast (s_ace_usr_cdlast),
				   .s_ace_usr_cdvalid(s_ace_usr_cdvalid));
   

endmodule                        

// Local Variables:
// verilog-library-directories:("./")
// End:
