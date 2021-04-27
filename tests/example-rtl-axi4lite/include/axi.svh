/*
 * AXI interfaces
 * Copyright (C) 2020 Xilinx Inc
 * Written by Edgar E. Iglesias <edgar.iglesias@gmail.com>
 *
 * SPDX-License-Identifier: MIT
 */

/* verilator lint_off DECLFILENAME */
`ifndef __AXI_SVH__
`define __AXI_SVH__

// Some parts are reusable in plain verilog
`include "include/axi.vh"

interface axi4lite_if #(parameter AWIDTH=32, DWIDTH=32) ();
	logic	awvalid, awready;
	logic	[AWIDTH - 1:0] awaddr;
	logic	[2:0] awprot;

	logic	arvalid, arready;
	logic	[AWIDTH - 1:0] araddr;
	logic	[2:0] arprot;

	logic	wvalid, wready;
	logic	[DWIDTH - 1:0] wdata;
	logic	[(DWIDTH/8) - 1:0] wstrb;

	logic	bvalid, bready;
	logic	[1:0] bresp;

	logic	rvalid, rready;
	logic	[1:0] rresp;
	logic	[DWIDTH - 1:0] rdata;

	wire	aridle = !arvalid | arready;
	wire	awidle = !awvalid | awready;
	wire	ridle = !rvalid | rready;
	wire	widle = !wvalid | wready;
	wire	bidle = !bvalid | bready;

	wire	ardone = arvalid & arready;
	wire	awdone = awvalid & awready;
	wire	rdone = rvalid & rready;
	wire	wdone = wvalid & wready;
	wire	bdone = bvalid & bready;

modport master_port (
	input	aridle, awidle, ridle, widle, bidle,
	input	ardone, awdone, rdone, wdone, bdone,

	output	awvalid, awaddr, awprot,
	input	awready,

	output	arvalid, araddr, arprot,
	input	arready,

	output	wvalid, wdata, wstrb,
	input	wready,

	output	bready,
	input	bvalid, bresp,

	output	rready,
	input	rvalid, rdata, rresp);

modport target_port (
	input	aridle, awidle, ridle, widle, bidle,
	input	ardone, awdone, rdone, wdone, bdone,

	input	awvalid, awaddr, awprot,
	output	awready,

	input	arvalid, araddr, arprot,
	output	arready,

	input	wvalid, wdata, wstrb,
	output	wready,

	input	bready,
	output	bvalid, bresp,

	input	rready,
	output	rvalid, rdata, rresp);
endinterface
`endif
