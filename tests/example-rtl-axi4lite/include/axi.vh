/*
 * AXI macros
 * Copyright (C) 2020 Xilinx Inc
 * Written by Edgar E. Iglesias <edgar.iglesias@gmail.com>
 *
 * SPDX-License-Identifier: MIT
 */

/* verilator lint_off DECLFILENAME */
`ifndef __AXI_VH__
`define __AXI_VH__

`define AXI_OKAY   2'b00
`define AXI_EXOKAY 2'b01
`define AXI_SLVERR 2'b10
`define AXI_DECERR 2'b11

`define AXI_BURST_FIXED 0
`define AXI_BURST_INCR  1
`define AXI_BURST_WRAP  2

`define AXI_PROT_PRIV 1
`define AXI_PROT_NS   2
`define AXI_PROT_INSN 4 

`define AXILITE_PORT_DIR(name, prefix, aw, dw, i, o)	\
	o prefix``arvalid,				\
	i prefix``arready,				\
	o [aw - 1:0] prefix``araddr,			\
	o [2:0] prefix``arprot,				\
							\
	o prefix``awvalid,				\
	i prefix``awready,				\
	o [aw - 1:0] prefix``awaddr,			\
	o [2:0] prefix``awprot,				\
							\
	i prefix``rvalid,				\
	o prefix``rready,				\
	i [dw - 1:0] prefix``rdata,			\
	i [1:0] prefix``rresp,				\
							\
	o prefix``wvalid,				\
	i prefix``wready,				\
	o [dw - 1:0] prefix``wdata,			\
	o [(dw / 8) - 1:0] prefix``wstrb,		\
							\
	i prefix``bvalid,				\
	o prefix``bready,				\
	i [1:0] prefix``bresp

`define AXILITE_MASTER_PORT(name, prefix, aw, dw)	\
	`AXILITE_PORT_DIR(name, prefix, aw, dw, input, output)
`define AXILITE_TARGET_PORT(name, prefix, aw, dw)	\
	`AXILITE_PORT_DIR(name, prefix, aw, dw, output, input)

`define AXILITE_NETS(prefix, aw, dw)		\
	wire	prefix``arvalid;			\
	wire	prefix``arready;			\
	wire	[aw - 1:0] prefix``araddr;		\
	wire	[2:0] prefix``arprot;			\
							\
	wire	prefix``awvalid;			\
	wire	prefix``awready;			\
	wire	[aw - 1:0] prefix``awaddr;		\
	wire	[2:0] prefix``awprot;			\
							\
	wire	prefix``rvalid;				\
	wire	prefix``rready;				\
	wire	[dw - 1:0] prefix``rdata;		\
	wire	[1:0] prefix``rresp;			\
							\
	wire	prefix``wvalid;				\
	wire	prefix``wready;				\
	wire	[dw - 1:0] prefix``wdata;		\
	wire	[(dw / 8) - 1:0] prefix``wstrb;		\
							\
	wire	prefix``bvalid;				\
	wire	prefix``bready;				\
	wire	[1:0] prefix``bresp

`define AXILITE_CONNECT(a, b, s)			\
	.a``s(b``s)
`define AXILITE_CONNECT_PORT(a, b)			\
	`AXILITE_CONNECT(a, b, arvalid),		\
	`AXILITE_CONNECT(a, b, arready),		\
	`AXILITE_CONNECT(a, b, araddr),			\
	`AXILITE_CONNECT(a, b, arprot),			\
							\
	`AXILITE_CONNECT(a, b, awvalid),		\
	`AXILITE_CONNECT(a, b, awready),		\
	`AXILITE_CONNECT(a, b, awaddr),			\
	`AXILITE_CONNECT(a, b, awprot),			\
							\
	`AXILITE_CONNECT(a, b, rvalid),			\
	`AXILITE_CONNECT(a, b, rready),			\
	`AXILITE_CONNECT(a, b, rdata),			\
	`AXILITE_CONNECT(a, b, rresp),			\
							\
	`AXILITE_CONNECT(a, b, wvalid),			\
	`AXILITE_CONNECT(a, b, wready),			\
	`AXILITE_CONNECT(a, b, wdata),			\
	`AXILITE_CONNECT(a, b, wstrb),			\
							\
	`AXILITE_CONNECT(a, b, bvalid),			\
	`AXILITE_CONNECT(a, b, bready),			\
	`AXILITE_CONNECT(a, b, bresp)
	

`define AXI_PROPAGATE_IN(iface, prefix, b) assign iface.``b = prefix``b 
`define AXI_PROPAGATE_OUT(iface, prefix, b) assign prefix``b = iface.``b
`define AXILITE_MASTER_PROPAGATE(iface, prefix)		\
	`AXI_PROPAGATE_OUT(iface, prefix, arvalid);	\
	`AXI_PROPAGATE_IN(iface, prefix, arready);	\
	`AXI_PROPAGATE_OUT(iface, prefix, araddr);	\
	`AXI_PROPAGATE_OUT(iface, prefix, arprot);	\
							\
	`AXI_PROPAGATE_OUT(iface, prefix, awvalid);	\
	`AXI_PROPAGATE_IN(iface, prefix, awready);	\
	`AXI_PROPAGATE_OUT(iface, prefix, awaddr);	\
	`AXI_PROPAGATE_OUT(iface, prefix, awprot);	\
							\
	`AXI_PROPAGATE_IN(iface, prefix, rvalid);	\
	`AXI_PROPAGATE_OUT(iface, prefix, rready);	\
	`AXI_PROPAGATE_IN(iface, prefix, rdata);	\
	`AXI_PROPAGATE_IN(iface, prefix, rresp);	\
							\
	`AXI_PROPAGATE_OUT(iface, prefix, wvalid);	\
	`AXI_PROPAGATE_IN(iface, prefix, wready);	\
	`AXI_PROPAGATE_OUT(iface, prefix, wdata);	\
	`AXI_PROPAGATE_OUT(iface, prefix, wstrb);	\
							\
	`AXI_PROPAGATE_IN(iface, prefix, bvalid);	\
	`AXI_PROPAGATE_OUT(iface, prefix, bready);	\
	`AXI_PROPAGATE_IN(iface, prefix, bresp)

`define AXILITE_TARGET_PROPAGATE(iface, prefix)		\
	`AXI_PROPAGATE_IN(iface, prefix, arvalid);	\
	`AXI_PROPAGATE_OUT(iface, prefix, arready);	\
	`AXI_PROPAGATE_IN(iface, prefix, araddr);	\
	`AXI_PROPAGATE_IN(iface, prefix, arprot);	\
							\
	`AXI_PROPAGATE_IN(iface, prefix, awvalid);	\
	`AXI_PROPAGATE_OUT(iface, prefix, awready);	\
	`AXI_PROPAGATE_IN(iface, prefix, awaddr);	\
	`AXI_PROPAGATE_IN(iface, prefix, awprot);	\
							\
	`AXI_PROPAGATE_OUT(iface, prefix, rvalid);	\
	`AXI_PROPAGATE_IN(iface, prefix, rready);	\
	`AXI_PROPAGATE_OUT(iface, prefix, rdata);	\
	`AXI_PROPAGATE_OUT(iface, prefix, rresp);	\
							\
	`AXI_PROPAGATE_IN(iface, prefix, wvalid);	\
	`AXI_PROPAGATE_OUT(iface, prefix, wready);	\
	`AXI_PROPAGATE_IN(iface, prefix, wdata);	\
	`AXI_PROPAGATE_IN(iface, prefix, wstrb);	\
							\
	`AXI_PROPAGATE_OUT(iface, prefix, bvalid);	\
	`AXI_PROPAGATE_IN(iface, prefix, bready);	\
	`AXI_PROPAGATE_OUT(iface, prefix, bresp)
`endif
