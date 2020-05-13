/* Copyright (c) 2020 Xilinx Inc. 
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
 *
 *
 */

//Maximum AXI-master-bridge/AXI-slave-bridge supported in rtl
`define MAX_NUM_MASTER_BR_SUP 6
`define MAX_NUM_SLAVE_BR_SUP 6

//Declare AXI master ports
`define d_axi_m(IF, AXI_PROTOCOL, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, AWUSER_WIDTH, WUSER_WIDTH, BUSER_WIDTH, ARUSER_WIDTH, RUSER_WIDTH) \
	,output [``ID_WIDTH``-1:0] ``IF``_awid, \
	output [``ADDR_WIDTH``-1:0] ``IF``_awaddr, \
	output [((``AXI_PROTOCOL``=="AXI4")?7:3):0] ``IF``_awlen, \
	output [2:0] ``IF``_awsize, \
	output [1:0] ``IF``_awburst, \
	output [((``AXI_PROTOCOL``=="AXI4")?0:1):0] ``IF``_awlock, \
	output [3:0] ``IF``_awcache, \
	output [2:0] ``IF``_awprot, \
	output [3:0] ``IF``_awqos, \
	output [3:0] ``IF``_awregion, \
	output [``AWUSER_WIDTH``-1:0] ``IF``_awuser, \
	output ``IF``_awvalid, \
	input ``IF``_awready, \
	output [``DATA_WIDTH``-1:0] ``IF``_wdata, \
	output [(``DATA_WIDTH``/8)-1:0] ``IF``_wstrb, \
	output ``IF``_wlast, \
	output [``WUSER_WIDTH``-1:0] ``IF``_wuser, \
	output ``IF``_wvalid ,input ``IF``_wready, \
	input [``ID_WIDTH``-1:0] ``IF``_bid, \
	input [1:0] ``IF``_bresp, \
	input [``BUSER_WIDTH``-1:0] ``IF``_buser, \
	input ``IF``_bvalid ,output ``IF``_bready, \
	output [``ID_WIDTH``-1:0] ``IF``_arid, \
	output [``ADDR_WIDTH``-1:0] ``IF``_araddr, \
	output [((``AXI_PROTOCOL``=="AXI4")?7:3):0] ``IF``_arlen, \
	output [2:0] ``IF``_arsize, \
	output [1:0] ``IF``_arburst, \
	output [((``AXI_PROTOCOL``=="AXI4")?0:1):0] ``IF``_arlock, \
	output [3:0] ``IF``_arcache, \
	output [2:0] ``IF``_arprot, \
	output [3:0] ``IF``_arqos, \
	output [3:0] ``IF``_arregion, \
	output [``ARUSER_WIDTH``-1:0] ``IF``_aruser, \
	output ``IF``_arvalid, \
	input ``IF``_arready, \
	input [``ID_WIDTH``-1:0] ``IF``_rid, \
	input [``DATA_WIDTH``-1:0] ``IF``_rdata, \
	input [1:0] ``IF``_rresp, \
	input ``IF``_rlast, \
	input [``RUSER_WIDTH``-1:0] ``IF``_ruser, \
	input ``IF``_rvalid, \
	output ``IF``_rready ,output [``ID_WIDTH``-1:0] ``IF``_wid

//Declare AXI slave ports
`define d_axi_s(IF, AXI_PROTOCOL, ADDR_WIDTH , DATA_WIDTH , ID_WIDTH , AWUSER_WIDTH , WUSER_WIDTH , BUSER_WIDTH , ARUSER_WIDTH , RUSER_WIDTH) \
	,input [``ID_WIDTH``-1:0] ``IF``_awid, \
	input [``ADDR_WIDTH``-1:0] ``IF``_awaddr, \
	input [((``AXI_PROTOCOL``=="AXI4")?7:3):0] ``IF``_awlen, \
	input [2:0] ``IF``_awsize, \
	input [1:0] ``IF``_awburst, \
	input [((``AXI_PROTOCOL``=="AXI4")?0:1):0] ``IF``_awlock, \
	input [3:0] ``IF``_awcache, \
	input [2:0] ``IF``_awprot, \
	input [3:0] ``IF``_awqos, \
	input [3:0] ``IF``_awregion, \
	input [``AWUSER_WIDTH``-1:0] ``IF``_awuser, \
	input ``IF``_awvalid, \
	output ``IF``_awready, \
	input [``DATA_WIDTH``-1:0] ``IF``_wdata, \
	input [(``DATA_WIDTH``/8)-1:0] ``IF``_wstrb, \
	input ``IF``_wlast, \
	input [``WUSER_WIDTH``-1:0] ``IF``_wuser, \
	input ``IF``_wvalid, \
	output ``IF``_wready, \
	output [``ID_WIDTH``-1:0] ``IF``_bid, \
	output [1:0] ``IF``_bresp, \
	output [``BUSER_WIDTH``-1:0] ``IF``_buser, \
	output ``IF``_bvalid, \
	input ``IF``_bready, \
	input [``ID_WIDTH``-1:0] ``IF``_arid, \
	input [``ADDR_WIDTH``-1:0] ``IF``_araddr, \
	input [((``AXI_PROTOCOL``=="AXI4")?7:3):0] ``IF``_arlen, \
	input [2:0] ``IF``_arsize, \
	input [1:0] ``IF``_arburst, \
	input [((``AXI_PROTOCOL``=="AXI4")?0:1):0] ``IF``_arlock, \
	input [3:0] ``IF``_arcache, \
	input [2:0] ``IF``_arprot, \
	input [3:0] ``IF``_arqos, \
	input [3:0] ``IF``_arregion, \
	input [``ARUSER_WIDTH``-1:0] ``IF``_aruser, \
	input ``IF``_arvalid, \
	output ``IF``_arready, \
	output [``ID_WIDTH``-1:0] ``IF``_rid, \
	output [``DATA_WIDTH``-1:0] ``IF``_rdata, \
	output [1:0] ``IF``_rresp, \
	output ``IF``_rlast, \
	output [``RUSER_WIDTH``-1:0] ``IF``_ruser, \
	output ``IF``_rvalid, \
	input ``IF``_rready, \
	input [``ID_WIDTH``-1:0] ``IF``_wid


//Declare AXI4 master ports
`define d_axi4_m(IF, ADDR_WIDTH , DATA_WIDTH , ID_WIDTH , USER_WIDTH) \
	,output [``ID_WIDTH``-1 : 0] ``IF``_awid, \
	output [``ADDR_WIDTH``-1 : 0] ``IF``_awaddr, \
	output [7 : 0] ``IF``_awlen, \
	output [2 : 0] ``IF``_awsize, \
	output [1 : 0] ``IF``_awburst, \
	output ``IF``_awlock, \
	output [3 : 0] ``IF``_awcache, \
	output [2 : 0] ``IF``_awprot, \
	output [3 : 0] ``IF``_awqos, \
	output [3:0] ``IF``_awregion, \
	output [``USER_WIDTH``-1 : 0] ``IF``_awuser, \
	output ``IF``_awvalid, \
	input ``IF``_awready, \
	output [``DATA_WIDTH``-1 : 0] ``IF``_wdata, \
	output [``DATA_WIDTH``/8-1 : 0] ``IF``_wstrb, \
	output ``IF``_wlast, \
	output [``USER_WIDTH``-1 : 0] ``IF``_wuser, \
	output ``IF``_wvalid, \
	input ``IF``_wready, \
	input [``ID_WIDTH``-1 : 0] ``IF``_bid, \
	input [1 : 0] ``IF``_bresp, \
	input [``USER_WIDTH``-1 : 0] ``IF``_buser, \
	input ``IF``_bvalid, \
	output ``IF``_bready, \
	output [``ID_WIDTH``-1 : 0] ``IF``_arid, \
	output [``ADDR_WIDTH``-1 : 0] ``IF``_araddr, \
	output [7 : 0] ``IF``_arlen, \
	output [2 : 0] ``IF``_arsize, \
	output [1 : 0] ``IF``_arburst, \
	output ``IF``_arlock, \
	output [3 : 0] ``IF``_arcache, \
	output [2 : 0] ``IF``_arprot, \
	output [3 : 0] ``IF``_arqos, \
	output [3:0] ``IF``_arregion, \
	output [``USER_WIDTH``-1 : 0] ``IF``_aruser, \
	output ``IF``_arvalid, \
	input ``IF``_arready, \
	input [``ID_WIDTH``-1 : 0] ``IF``_rid, \
	input [``DATA_WIDTH``-1 : 0] ``IF``_rdata, \
	input [1 : 0] ``IF``_rresp, \
	input ``IF``_rlast, \
	input [``USER_WIDTH``-1 : 0] ``IF``_ruser, \
	input ``IF``_rvalid, \
	output ``IF``_rready


//Declare AXI4lite slave ports
`define d_axi4lite_s(IF, ADDR_WIDTH , DATA_WIDTH) \
	,input [``ADDR_WIDTH``-1:0] ``IF``_awaddr, \
	input [2:0] ``IF``_awprot, \
	input ``IF``_awvalid, \
	output ``IF``_awready, \
	input [``DATA_WIDTH``-1:0] ``IF``_wdata, \
	input [(``DATA_WIDTH``/8)-1:0] ``IF``_wstrb, \
	input ``IF``_wvalid, \
	output ``IF``_wready, \
	output [1:0] ``IF``_bresp, \
	output ``IF``_bvalid, \
	input ``IF``_bready, \
	input [``ADDR_WIDTH``-1:0] ``IF``_araddr, \
	input [2:0] ``IF``_arprot, \
	input ``IF``_arvalid, \
	output ``IF``_arready, \
	output [``DATA_WIDTH``-1:0] ``IF``_rdata, \
	output [1:0] ``IF``_rresp, \
	output ``IF``_rvalid, \
	input ``IF``_rready

//Connect AXI ports
`define c_axi(IFA, IFB) \
	,.``IFA``_awid(``IFB``_awid), \
	.``IFA``_awaddr(``IFB``_awaddr), \
	.``IFA``_awlen(``IFB``_awlen), \
	.``IFA``_awsize(``IFB``_awsize), \
	.``IFA``_awburst(``IFB``_awburst), \
	.``IFA``_awlock(``IFB``_awlock), \
	.``IFA``_awcache(``IFB``_awcache), \
	.``IFA``_awprot(``IFB``_awprot), \
	.``IFA``_awqos(``IFB``_awqos), \
	.``IFA``_awregion(``IFB``_awregion), \
	.``IFA``_awuser(``IFB``_awuser), \
	.``IFA``_awvalid(``IFB``_awvalid), \
	.``IFA``_awready(``IFB``_awready), \
	.``IFA``_wdata(``IFB``_wdata), \
	.``IFA``_wstrb(``IFB``_wstrb), \
	.``IFA``_wlast(``IFB``_wlast), \
	.``IFA``_wuser(``IFB``_wuser), \
	.``IFA``_wvalid(``IFB``_wvalid), \
	.``IFA``_wready(``IFB``_wready), \
	.``IFA``_bid(``IFB``_bid), \
	.``IFA``_bresp(``IFB``_bresp), \
	.``IFA``_buser(``IFB``_buser), \
	.``IFA``_bvalid(``IFB``_bvalid), \
	.``IFA``_bready(``IFB``_bready), \
	.``IFA``_arid(``IFB``_arid), \
	.``IFA``_araddr(``IFB``_araddr), \
	.``IFA``_arlen(``IFB``_arlen), \
	.``IFA``_arsize(``IFB``_arsize), \
	.``IFA``_arburst(``IFB``_arburst), \
	.``IFA``_arlock(``IFB``_arlock), \
	.``IFA``_arcache(``IFB``_arcache), \
	.``IFA``_arprot(``IFB``_arprot), \
	.``IFA``_arqos(``IFB``_arqos), \
	.``IFA``_arregion(``IFB``_arregion), \
	.``IFA``_aruser(``IFB``_aruser), \
	.``IFA``_arvalid(``IFB``_arvalid), \
	.``IFA``_arready(``IFB``_arready), \
	.``IFA``_rid(``IFB``_rid), \
	.``IFA``_rdata(``IFB``_rdata), \
	.``IFA``_rresp(``IFB``_rresp), \
	.``IFA``_rlast(``IFB``_rlast), \
	.``IFA``_ruser(``IFB``_ruser), \
	.``IFA``_rvalid(``IFB``_rvalid), \
	.``IFA``_rready(``IFB``_rready), \
	.``IFA``_wid(``IFB``_wid)

//Connect AXI4 ports
`define c_axi4(IFA, IFB) \
	,.``IFA``_awid(``IFB``_awid), \
	.``IFA``_awaddr(``IFB``_awaddr), \
	.``IFA``_awlen(``IFB``_awlen), \
	.``IFA``_awsize(``IFB``_awsize), \
	.``IFA``_awburst(``IFB``_awburst), \
	.``IFA``_awlock(``IFB``_awlock), \
	.``IFA``_awcache(``IFB``_awcache), \
	.``IFA``_awprot(``IFB``_awprot), \
	.``IFA``_awqos(``IFB``_awqos), \
	.``IFA``_awregion(``IFB``_awregion), \
	.``IFA``_awuser(``IFB``_awuser), \
	.``IFA``_awvalid(``IFB``_awvalid), \
	.``IFA``_awready(``IFB``_awready), \
	.``IFA``_wdata(``IFB``_wdata), \
	.``IFA``_wstrb(``IFB``_wstrb), \
	.``IFA``_wlast(``IFB``_wlast), \
	.``IFA``_wuser(``IFB``_wuser), \
	.``IFA``_wvalid(``IFB``_wvalid), \
	.``IFA``_wready(``IFB``_wready), \
	.``IFA``_bid(``IFB``_bid), \
	.``IFA``_bresp(``IFB``_bresp), \
	.``IFA``_buser(``IFB``_buser), \
	.``IFA``_bvalid(``IFB``_bvalid), \
	.``IFA``_bready(``IFB``_bready), \
	.``IFA``_arid(``IFB``_arid), \
	.``IFA``_araddr(``IFB``_araddr), \
	.``IFA``_arlen(``IFB``_arlen), \
	.``IFA``_arsize(``IFB``_arsize), \
	.``IFA``_arburst(``IFB``_arburst), \
	.``IFA``_arlock(``IFB``_arlock), \
	.``IFA``_arcache(``IFB``_arcache), \
	.``IFA``_arprot(``IFB``_arprot), \
	.``IFA``_arqos(``IFB``_arqos), \
	.``IFA``_arregion(``IFB``_arregion), \
	.``IFA``_aruser(``IFB``_aruser), \
	.``IFA``_arvalid(``IFB``_arvalid), \
	.``IFA``_arready(``IFB``_arready), \
	.``IFA``_rid(``IFB``_rid), \
	.``IFA``_rdata(``IFB``_rdata), \
	.``IFA``_rresp(``IFB``_rresp), \
	.``IFA``_rlast(``IFB``_rlast), \
	.``IFA``_ruser(``IFB``_ruser), \
	.``IFA``_rvalid(``IFB``_rvalid), \
	.``IFA``_rready(``IFB``_rready)
 
//Connect AXI4lite ports
`define c_axi4lite(IFA, IFB) \
	,.``IFA``_awaddr(``IFB``_awaddr), \
	.``IFA``_awprot(``IFB``_awprot), \
	.``IFA``_awvalid(``IFB``_awvalid), \
	.``IFA``_awready(``IFB``_awready), \
	.``IFA``_wdata(``IFB``_wdata), \
	.``IFA``_wstrb(``IFB``_wstrb), \
	.``IFA``_wvalid(``IFB``_wvalid), \
	.``IFA``_wready(``IFB``_wready), \
	.``IFA``_bresp(``IFB``_bresp), \
	.``IFA``_bvalid(``IFB``_bvalid), \
	.``IFA``_bready(``IFB``_bready), \
	.``IFA``_araddr(``IFB``_araddr), \
	.``IFA``_arprot(``IFB``_arprot), \
	.``IFA``_arvalid(``IFB``_arvalid), \
	.``IFA``_arready(``IFB``_arready), \
	.``IFA``_rdata(``IFB``_rdata), \
	.``IFA``_rresp(``IFB``_rresp), \
	.``IFA``_rvalid(``IFB``_rvalid), \
	.``IFA``_rready(``IFB``_rready)


