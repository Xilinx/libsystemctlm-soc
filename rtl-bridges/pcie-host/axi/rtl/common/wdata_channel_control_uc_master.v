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
 *   Wdata Control to fetch data from DRAM and send it to DUT.
 *
 *
 */
`include "defines_common.vh"


module wdata_channel_control_uc_master
  #(
    parameter 
    MAX_DESC=4, 
    RAM_SIZE=16,
    M_AXI_USR_ADDR_WIDTH=64,
    M_AXI_USR_DATA_WIDTH=16,
    M_AXI_USR_WUSER_WIDTH=4,
    M_AXI_USR_ID_WIDTH=16,
    M_AXI_USR_LEN=4,
    RTL_USE_MODE=0,
    UC_AXI_DATA_WIDTH=M_AXI_USR_DATA_WIDTH
    )
   (
    // Clks  & Resets
    input 						      axi_aclk,
    input 						      axi_aresetn,

	// xnexts = xvalid/xready
    input 						      awnext,
    input 						      wnext,

	// From Host MAster to indicate that its done.
    input [MAX_DESC-1:0] 				      hm_done_int,

	// Use mode to see if hm needs to be invoked or not.
    input 						      use_mode,


	// Offset addr of each descriptor
    input [31:0] 					      desc_0_offset_addr,
    input [31:0] 					      desc_1_offset_addr,
    input [31:0] 					      desc_2_offset_addr,
    input [31:0] 					      desc_3_offset_addr,
    input [31:0] 					      desc_4_offset_addr,
    input [31:0] 					      desc_5_offset_addr,
    input [31:0] 					      desc_6_offset_addr,
    input [31:0] 					      desc_7_offset_addr,
    input [31:0] 					      desc_8_offset_addr,
    input [31:0] 					      desc_9_offset_addr,
    input [31:0] 					      desc_10_offset_addr,
    input [31:0] 					      desc_11_offset_addr,
    input [31:0] 					      desc_12_offset_addr,
    input [31:0] 					      desc_13_offset_addr,
    input [31:0] 					      desc_14_offset_addr,
    input [31:0] 					      desc_15_offset_addr,


	// txn size of each descriptor
    input [15:0] 					      desc_0_txn_size,
    input [15:0] 					      desc_1_txn_size,
    input [15:0] 					      desc_2_txn_size,
    input [15:0] 					      desc_3_txn_size,
    input [15:0] 					      desc_4_txn_size,
    input [15:0] 					      desc_5_txn_size,
    input [15:0] 					      desc_6_txn_size,
    input [15:0] 					      desc_7_txn_size,
    input [15:0] 					      desc_8_txn_size,
    input [15:0] 					      desc_9_txn_size,
    input [15:0] 					      desc_10_txn_size,
    input [15:0] 					      desc_11_txn_size,
    input [15:0] 					      desc_12_txn_size,
    input [15:0] 					      desc_13_txn_size,
    input [15:0] 					      desc_14_txn_size,
    input [15:0] 					      desc_15_txn_size,
	

	// txn type of each descriptor
	
    input 						      desc_0_txn_type_wr_strb,
    input 						      desc_1_txn_type_wr_strb,
    input 						      desc_2_txn_type_wr_strb,
    input 						      desc_3_txn_type_wr_strb,
    input 						      desc_4_txn_type_wr_strb,
    input 						      desc_5_txn_type_wr_strb,
    input 						      desc_6_txn_type_wr_strb,
    input 						      desc_7_txn_type_wr_strb,
    input 						      desc_8_txn_type_wr_strb,
    input 						      desc_9_txn_type_wr_strb,
    input 						      desc_10_txn_type_wr_strb,
    input 						      desc_11_txn_type_wr_strb,
    input 						      desc_12_txn_type_wr_strb,
    input 						      desc_13_txn_type_wr_strb,
    input 						      desc_14_txn_type_wr_strb,
    input 						      desc_15_txn_type_wr_strb,

	// Data coming from wdata DRAM, wstrb DRAM
    input [(M_AXI_USR_DATA_WIDTH/8)-1:0] 		      rb2uc_rd_wstrb_int,
    input [M_AXI_USR_DATA_WIDTH-1:0] 			      rb2uc_rd_data,
	// Selected wuser of current descriptor
    input [M_AXI_USR_WUSER_WIDTH-1:0] 			      wdata_wuser_in,
    input [M_AXI_USR_ID_WIDTH-1:0] 			      wdata_wid_in,

	// wdata_request id from desc_allocation block
    input [(`CLOG2(MAX_DESC))-1:0] 			      wdata_request_id,
	// corresponding awle, awsize and awaddr of wdata_request_id
    input [M_AXI_USR_LEN-1:0] 				      wdata_request_awlen,
    input [2:0] 					      wdata_request_awsize,
    input [M_AXI_USR_ADDR_WIDTH-1:0] 			      wdata_request_awaddr,

	// awlen of current wdata under process
    output [M_AXI_USR_LEN-1:0] 				      wdata_current_request_awlen,

	// W_pending_fifo_full to indicate other blocsk
    output 						      W_pending_fifo_full,
    output reg 						      W_pending_read_en,

	// Output of W_Fifo, it has wdata,wuser and wstrb info.
    output [M_AXI_USR_DATA_WIDTH-1:0] 			      wdata_read_out_wdata, 
    output [(M_AXI_USR_DATA_WIDTH/8)-1:0] 		      wdata_read_out_wstrb,
    output [M_AXI_USR_WUSER_WIDTH-1:0] 			      wdata_read_out_wuser,
    output [M_AXI_USR_ID_WIDTH-1:0] 			      wdata_read_out_wid,


	// rd address given to dram
    output reg [(`CLOG2(RAM_SIZE/(UC_AXI_DATA_WIDTH/8)))-1:0] uc2rb_rd_addr,
	
	// The corresponding desc id of givne rd address. It is used mainly in case
	// of HM use case, where HM needs to know wheather to send WSTRB or WDATA.
    output [(`CLOG2(MAX_DESC))-1:0] 			      uc2rb_rd_addr_desc_id,
   

    output [(`CLOG2(MAX_DESC))-1:0] 			      wdata_current_request_id,

	// When there is no wready, someone needs to assert first read
	// from fifo and place data on wdata, first_Write_Wdata is a pulse generated
	// on first clock then disabled.
    output 						      first_write_wdata,

	// wdata_read_en & _fifo_empty are used to deasserting/asserting wvalid
    output reg 						      wdata_read_en, 
    output 						      wdata_fifo_empty,

	// wlast from FIFO, for other blocks to know that last beat
	// of data is sent on to the BUS.
    output 						      wdata_read_out_wlast 												  
    );


   
   localparam WSTRB_SIZE=`CLOG2(M_AXI_USR_DATA_WIDTH/8);
   localparam [2:0] MAX_AWSIZE= WSTRB_SIZE[2:0];

   localparam WDATA_FIFO_DEPTH = 32;
   

   //////////////////////////////////////////////////////////////////////////////
     //
   // Wires for wstrb alignment logic
   //
   //////////////////////////////////////////////////////////////////////////////
   
   // different wstrb_size_x strobes as per axsize
   wire [15:0] 						      wstrb_size_0 ; 
   wire [15:0] 						      wstrb_size_1 ; 
   wire [15:0] 						      wstrb_size_2 ; 
   wire [15:0] 						      wstrb_size_3 ;
   wire [15:0] 						      wstrb_size_4 ;
   wire 						      current_txn_wstrb_mode;
   wire [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      wlast_wstrb_aligned;
   wire [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      wlast_wstrb_aligned_to_fifo;
   wire 						      adjust_wlast_wstrb_valid;
   wire 						      int_wire_desc_n_txn_type_wr_strb	[MAX_DESC-1:0] 		;
   wire [511:0] 					      wdata_wstrb_const;
   wire [(M_AXI_USR_DATA_WIDTH/8) -1:0] 		      wdata_wstrb;
   wire 						      current_txn_wstrb_mode_to_fifo;
   
   
   
   wire [31:0] 						      int_wire_desc_n_data_offset_addr[MAX_DESC-1:0];
   wire [15:0] 						      int_wire_desc_n_size_txn_size	[MAX_DESC-1:0]          ;

   // Its fifo count, how many data beats are stored into fifo.
   wire [5:0] 						      W_fifo_count; //same as fifo counter


   ///////////////////////////////////////////////////////////////////////
   //
   // wires for W_pending fifo
   //
   ////////////////////////////////////////////////////////////////////////
   
   // FIFO output of W_pending fifo, to indicate pending request attribs
   wire [M_AXI_USR_LEN-1:0] 				      W_pending_awlen;
   wire [(`CLOG2(M_AXI_USR_DATA_WIDTH/8))-1:0] 		      W_pending_awaddr;
   wire [2:0] 						      W_pending_awsize;
   wire 						      W_pending_fifo_empty;
   wire [(`CLOG2(MAX_DESC))-1:0] 			      W_pending_read_id;


   // W_data_fifo
   // almost full to handle backpressure by wready. Halting adress generation
   wire 						      wdata_fifo_almost_full;   
   wire 						      wdata_almost_full;   
   wire [M_AXI_USR_DATA_WIDTH-1:0] 			      wdata_read_out;
   wire 						      wdata_fifo_full;
   
   wire [(`CLOG2(M_AXI_USR_DATA_WIDTH/8))-1:0] 		      wdata_current_request_awaddr;
   wire [2:0] 						      wdata_current_request_awsize;

   // DRAM Intfc. WSTRB that is actually going into Fifo.
   wire [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      rb2uc_rd_wstrb_aligned;  						 

   wire 						      wlast_counter_is_zero;
   wire 						      W_data_wlast;
   wire 						      decr_wlast_counter;   
   wire [(`CLOG2(RAM_SIZE/(UC_AXI_DATA_WIDTH/8)))-1:0] 	      rb_rd_addr_increment;
   

   ////////////////////////////////////////////////////////////
   //
   // REGs
   //
   ///////////////////////////////////////////////////////////
   

   // For WSTRB Control logic
   reg [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      fixed_wstrb;
   reg [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      aligned_wstrb;
   reg [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      wstrb_mask ;
   reg 							      current_txn_wstrb_mode_ff;
   reg 							      current_txn_wstrb_mode_ff1;
   reg 							      current_txn_wstrb_mode_ff2;
   reg 							      current_txn_wstrb_mode_ff3;
   reg 							      current_txn_wstrb_mode_ff4;
   reg 							      current_txn_wstrb_mode_ff5;
   reg 							      current_txn_wstrb_mode_ff6;
   reg 							      check_for_wstrb_alignment;
   reg 							      wstrb_alignment_done;
   reg 							      wstrb_alignment_done_ff;
   reg 							      wstrb_alignment_done_ff2;
   reg 							      wstrb_alignment_done_ff3;
   reg 							      wstrb_alignment_done_ff4;
   reg 							      wstrb_alignment_done_ff5;
   
   

   // W_pending Fifo regs
   reg [((`CLOG2(MAX_DESC))-1):0] 			      W_pending_read_id_ff;
   reg [((`CLOG2(MAX_DESC))-1):0] 			      W_pending_read_id_ff2;
   reg [((`CLOG2(MAX_DESC))-1):0] 			      W_pending_read_id_ff3;
   reg [((`CLOG2(MAX_DESC))-1):0] 			      W_pending_read_id_ff4;
   reg [((`CLOG2(MAX_DESC))-1):0] 			      W_pending_read_id_ff5;
   reg [((`CLOG2(MAX_DESC))-1):0] 			      W_pending_read_id_ff6; 
   reg 							      W_pending_read_en_ff;


   // W_data Fifo regs control & data
   reg [M_AXI_USR_WUSER_WIDTH-1:0] 			      wdata_wuser;
   reg [M_AXI_USR_ID_WIDTH-1:0] 			      wdata_wid; 
   reg 							      wdata_write_en;   
   reg 							      wdata_write_en_ff;
   reg 							      wdata_write_en_ff2;
   reg 							      wdata_write_en_ff3;
   reg 							      wdata_write_en_ff4;
   reg 							      wdata_write_en_ff5;
   reg 							      wdata_write_en_ff6;
   reg 							      wdata_write_en_ff7;
   reg 							      wdata_write_en_ff8;
   reg 							      wdata_write_en_ff9;

   reg 							      wdata_read_en_ff;
   reg 							      wdata_read_en_ff2;
   reg 							      wdata_read_en_ff3;

   //Combining AXI AXUSER/XUSER of all the registers
   reg [M_AXI_USR_WUSER_WIDTH-1:0] 			      wdata_wuser_ff ;
   reg [M_AXI_USR_WUSER_WIDTH-1:0] 			      wdata_wuser_ff2;
   reg [M_AXI_USR_WUSER_WIDTH-1:0] 			      wdata_wuser_ff3;

   //Combining AXI AXUSER/XUSER of all the registers
   reg [M_AXI_USR_ID_WIDTH-1:0] 			      wdata_wid_ff ;
   reg [M_AXI_USR_ID_WIDTH-1:0] 			      wdata_wid_ff2;
   reg [M_AXI_USR_ID_WIDTH-1:0] 			      wdata_wid_ff3;

   
   reg 							      wdata_fifo_almost_full_ff;
   reg 							      wdata_fifo_almost_full_ff1;
   reg 							      wdata_fifo_almost_full_ff2;
   reg 							      wdata_fifo_almost_full_valid_32;
   

   
   
   // FSM State regs
   reg [2:0] 						      dram_state;
   reg 							      dram_wdata_rfifo_state;
   reg [2:0] 						      wstrb_state;

   // Delay counters to halt writing into Fifo in case of HM.
   reg [3:0] 						      wdata_delay; //max 5 cycle delay between fetched read to address
   reg [3:0] 						      wstrb_delay; //max 5 cycle delay between fetched read to address

   
   // wlast counter to keep track of current beat count and generate wlast
   reg [8:0] 						      wlast_counter;
   
   // if wlast_counter is zero asserting a flat, used for wlast generation
   reg 							      wlast_counter_is_zero_ff;
   reg 							      wlast_counter_is_zero_ff2;
   reg 							      wlast_counter_is_zero_ff3;
   reg 							      wlast_counter_is_zero_ff4;
   reg 							      wlast_counter_is_zero_ff5;
   reg 							      wlast_counter_is_zero_ff6;
   reg 							      wlast_counter_is_zero_ff7;
   


   wire 						      wdata_wr_en_32_uc;
   wire 						      wdata_wr_en_64_uc;
   wire 						      wdata_wr_en_128_uc;
   wire 						      wdata_write_en_to_fifo;
   reg 							      mask_64_bit_wr;
   reg 							      mask_64_bit_wr_ff;
   reg 							      mask_64_bit_wr_ff2;
   reg 							      mask_64_bit_wr_ff3;
   reg 							      mask_64_bit_wr_ff4;
   reg 							      mask_64_bit_wr_ff5;
   reg 							      mask_64_bit_wr_ff6;
   reg 							      mask_64_bit_wr_ff7;
   
   reg [1:0] 						      mask_32_bit_wr;
   reg [1:0] 						      mask_32_bit_wr_ff;
   reg [1:0] 						      mask_32_bit_wr_ff2;
   reg [1:0] 						      mask_32_bit_wr_ff3;
   reg [1:0] 						      mask_32_bit_wr_ff4;
   reg [1:0] 						      mask_32_bit_wr_ff5;
   reg [1:0] 						      mask_32_bit_wr_ff6;
   reg [1:0] 						      mask_32_bit_wr_ff7;
   reg [1:0] 						      mask_32_bit_wr_ff8;

   
   

   



   reg [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      wlast_wstrb_aligned_ff;
   reg [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      wlast_wstrb_aligned_ff2;
   reg [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      wlast_wstrb_aligned_ff3;
   reg [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      wlast_wstrb_aligned_ff4;
   reg [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      wlast_wstrb_aligned_ff5;
   reg [(M_AXI_USR_DATA_WIDTH/8)-1:0] 			      wlast_wstrb_aligned_ff6;
   
   reg 							      adjust_wlast_wstrb_valid_ff;
   reg 							      adjust_wlast_wstrb_valid_ff2;
   reg 							      adjust_wlast_wstrb_valid_ff3;
   reg 							      adjust_wlast_wstrb_valid_ff4;
   reg 							      adjust_wlast_wstrb_valid_ff5;

   reg [15:0] 						      current_txn_size;




   ////////////////////////////////////////////////////////
   //
   // 1D to 2D
   //
   /////////////////////////////////////////////////////////
   assign int_wire_desc_n_data_offset_addr[0] = desc_0_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[1] = desc_1_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[2] = desc_2_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[3] = desc_3_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[4] = desc_4_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[5] = desc_5_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[6] = desc_6_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[7] = desc_7_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[8] = desc_8_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[9] = desc_9_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[10] = desc_10_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[11] = desc_11_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[12] = desc_12_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[13] = desc_13_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[14] = desc_14_offset_addr; 
   assign int_wire_desc_n_data_offset_addr[15] = desc_15_offset_addr; 

   assign int_wire_desc_n_txn_type_wr_strb[0] = desc_0_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[1] = desc_1_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[2] = desc_2_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[3] = desc_3_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[4] = desc_4_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[5] = desc_5_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[6] = desc_6_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[7] = desc_7_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[8] = desc_8_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[9] = desc_9_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[10] = desc_10_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[11] = desc_11_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[12] = desc_12_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[13] = desc_13_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[14] = desc_14_txn_type_wr_strb; 
   assign int_wire_desc_n_txn_type_wr_strb[15] = desc_15_txn_type_wr_strb; 

   assign int_wire_desc_n_size_txn_size[0] = desc_0_txn_size; 
   assign int_wire_desc_n_size_txn_size[1] = desc_1_txn_size; 
   assign int_wire_desc_n_size_txn_size[2] = desc_2_txn_size; 
   assign int_wire_desc_n_size_txn_size[3] = desc_3_txn_size; 
   assign int_wire_desc_n_size_txn_size[4] = desc_4_txn_size; 
   assign int_wire_desc_n_size_txn_size[5] = desc_5_txn_size; 
   assign int_wire_desc_n_size_txn_size[6] = desc_6_txn_size; 
   assign int_wire_desc_n_size_txn_size[7] = desc_7_txn_size; 
   assign int_wire_desc_n_size_txn_size[8] = desc_8_txn_size; 
   assign int_wire_desc_n_size_txn_size[9] = desc_9_txn_size; 
   assign int_wire_desc_n_size_txn_size[10] = desc_10_txn_size; 
   assign int_wire_desc_n_size_txn_size[11] = desc_11_txn_size; 
   assign int_wire_desc_n_size_txn_size[12] = desc_12_txn_size; 
   assign int_wire_desc_n_size_txn_size[13] = desc_13_txn_size; 
   assign int_wire_desc_n_size_txn_size[14] = desc_14_txn_size; 
   assign int_wire_desc_n_size_txn_size[15] = desc_15_txn_size; 
   

   

   
   ////////////////////////////////////////////////////////////////////////////////
   //
   //   Current TXN type, either to take fixed wstrb or variable
   //
   ////////////////////////////////////////////////////////////////////////////////
   
   assign current_txn_wstrb_mode = int_wire_desc_n_txn_type_wr_strb[W_pending_read_id];

   
   //////////////////////////////////////////////////////////////
   //
   // Creating constant wstrb baesd on current axi data width
   //
   //////////////////////////////////////////////////////////////
   
   assign wdata_wstrb_const=512'hFFFFFFFFFFFFFFFF;
   assign wdata_wstrb=wdata_wstrb_const[(M_AXI_USR_DATA_WIDTH/8) -1:0];

   
   //////////////////////////////////////////////////////
   //
   // wdata_current* indicates current transfer that is
   // going on bus
   //
   ////////////////////////////////////////////////////

   assign wdata_current_request_awlen= W_pending_awlen;
   assign wdata_current_request_awsize= W_pending_awsize;
   assign wdata_current_request_awaddr= W_pending_awaddr;



   // Shifting W_pending ID. This is descriptor ID that is under service.

   `FF(axi_aclk, ~axi_aresetn, W_pending_read_id_ff  ,  W_pending_read_id_ff2 )
   `FF(axi_aclk, ~axi_aresetn, W_pending_read_id_ff2  ,  W_pending_read_id_ff3 )
   `FF(axi_aclk, ~axi_aresetn, W_pending_read_id_ff3  ,  W_pending_read_id_ff4 )
   `FF(axi_aclk, ~axi_aresetn, W_pending_read_id_ff4  ,  W_pending_read_id_ff5 )
   `FF(axi_aclk, ~axi_aresetn, W_pending_read_id_ff5  ,  W_pending_read_id_ff6 )
   
   
   // For users outside of this module, so that 
   // other modules can peek into whats happening here.
   // i.e which desc. is under process!

   assign wdata_current_request_id=W_pending_read_id;


   // Creating five different combination of wstrb possible
   // for generating wstrb in case of awlen-0, axsize< MAX AXSIZE

   assign wstrb_size_0 = 16'b1;
   assign wstrb_size_1 = 16'b11;
   assign wstrb_size_2 = 16'b1111;
   assign wstrb_size_3 = 16'b11111111;
   assign wstrb_size_4 = 16'hFFFF;

   
   //////////////////////////////////////////////////////
   //
   // wstrb_state :
   //  This FSM does job for both use case, UM & HM
   // 1) UM : In case of awlen=0 and awsize<MAX_AXSIZE shift
   //       wstrb as per awsize and awaddr.
   // 2) HM : In case of txn size < 0x10 OR 
   //		txn_size != multiple of 0x10, (i.e 0x14, 0x24)
   //
   ////////////////////////////////////////////////////
   
   localparam 
     WSTRB_IDLE = 3'b000,
     WSTRB_CHECK_SIZE = 3'b001,
     WSTRB_GEN_MASK = 3'b010,
     WSTRB_ALIGN = 3'b011,
     WSTRB_ALIGN_FOR_HM = 3'b100,
     WSTRB_ALIGNMENT_DONE = 3'b101,
     WSTRB_HM_DELAY = 3'b110;
   
   

   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 fixed_wstrb<=wstrb_size_4;
	 wstrb_mask<=0;
	 aligned_wstrb<=0;
	 wstrb_alignment_done<=0;
	 wstrb_state<=WSTRB_IDLE;
	 current_txn_size <=0;
	 wstrb_delay<=0;
      end
      
      // If current awlen is 0 & awsize is less then Max
      // means Bridge has to generate wstrbs &
      // Shift it according to the address given.
      else  begin
	 case (wstrb_state) 
	   WSTRB_IDLE:
	     // Wait for trigger from dram_state FSM,
	     // which checks for current_wstrb_mode and invokes
	     // wstrb_state FSM to compute strobes 
	     if(check_for_wstrb_alignment) begin
		wstrb_alignment_done<=0;
		current_txn_size<=0;
		wstrb_delay<=0;
		wstrb_state<=WSTRB_CHECK_SIZE;
	     end
	     else begin
		wstrb_alignment_done<=0;
		wstrb_delay<=0;
		current_txn_size<=0;
		wstrb_state<=WSTRB_IDLE;
	     end
	   
	   // Check for conditions of axsize or txnsize
	   // If it falls in catagory, then only generate
	   // wstrb else keep it constant 
	   WSTRB_CHECK_SIZE:
	     // In case of HM, check if txn size is odd .i.e 0x14, 0x4, 0x18 0x1c
	     // Compile time MUX
	     if ( (RTL_USE_MODE==1) && ( (int_wire_desc_n_size_txn_size[W_pending_read_id][3:0] & 4'hF) != 4'h0))  begin
		// If current txn size is not multiple of 0x10
		// then align wstrb for last cycle.!.
		current_txn_size <= int_wire_desc_n_size_txn_size[W_pending_read_id] & 32'hF;
		wstrb_state<=WSTRB_ALIGN_FOR_HM;
	     end
	   // Else (If UM) then check if awlen ==0 and axsize < Max axsize
	   // In which case Bridge has to generate strobes
	     else if( (wdata_current_request_awlen==0) && (wdata_current_request_awsize<MAX_AWSIZE) ) begin
		wstrb_alignment_done<=0;
		wstrb_state<=WSTRB_GEN_MASK;
	     end
	     else begin
		fixed_wstrb<= wstrb_size_4;
		wstrb_mask<='hFFFF;
		wstrb_alignment_done<=1;
		aligned_wstrb	<= 'hFFFF;
		wstrb_state<=WSTRB_ALIGNMENT_DONE;
	     end
	   
	   // If its HM, and axsize< MAX SIZE, then 
	   // check what is the actual size, and based
	   // on that generate wstrb and shift it
	   // according to the addres given.
	   WSTRB_GEN_MASK:
	     if (wdata_current_request_awsize==3'h0) begin
		wstrb_alignment_done<=0;
		fixed_wstrb<= wstrb_size_0;
		wstrb_mask<=wstrb_size_0<<wdata_current_request_awaddr;
		wstrb_state<=WSTRB_ALIGN;
	     end
	     else if (wdata_current_request_awsize==3'h1) begin
		wstrb_alignment_done<=0;
		fixed_wstrb<= wstrb_size_1;
		wstrb_mask<=wstrb_size_1<<
			    ( (M_AXI_USR_DATA_WIDTH==32) ?  ({wdata_current_request_awaddr[1],1'b0}) :
			      ( (M_AXI_USR_DATA_WIDTH==64) ?  ({wdata_current_request_awaddr[2:1],1'b0}) :
				({wdata_current_request_awaddr[3:1],1'b0})) );
		wstrb_state<=WSTRB_ALIGN;
	     end
	     else if (wdata_current_request_awsize==3'h2) begin
		wstrb_alignment_done<=0;
		fixed_wstrb<= wstrb_size_2;
		wstrb_mask<=wstrb_size_2<<(
					   (M_AXI_USR_DATA_WIDTH==32) ?  ({wdata_current_request_awaddr}) :
					   ( (M_AXI_USR_DATA_WIDTH==64) ?  ({wdata_current_request_awaddr[2],2'b00}) :
					     ({wdata_current_request_awaddr[3:2],2'b00})) );
		wstrb_state<=WSTRB_ALIGN;
	     end
	     else begin
		wstrb_alignment_done<=0;
		fixed_wstrb<= wstrb_size_3;
		wstrb_mask<=wstrb_size_3<<
			    ( (M_AXI_USR_DATA_WIDTH==32) ?  ({wdata_current_request_awaddr}) :
			      ( (M_AXI_USR_DATA_WIDTH==64) ?  ({wdata_current_request_awaddr}) :
				({wdata_current_request_awaddr[3],3'b000})) );
		wstrb_state<=WSTRB_ALIGN;
	     end 

	   // Align wstrb with address
	   WSTRB_ALIGN:
	     begin
		aligned_wstrb<=( (fixed_wstrb<<wdata_current_request_awaddr)  &	 wstrb_mask);
		wstrb_alignment_done<=1;
		wstrb_state<= WSTRB_ALIGNMENT_DONE;
	     end

	   // In case its HM, 
	   // check the size of request
	   // if its odd, (!= 0xn0) then
	   // assert wstrb auto
	   WSTRB_ALIGN_FOR_HM:
	     begin
		if(current_txn_size== 16'h4) begin
		   aligned_wstrb <= 'h000F;
		end
		else if (current_txn_size == 16'h8) begin
		   aligned_wstrb <= 'h00FF;
		end
		else begin  //else if txn size 0xC
		   aligned_wstrb <= 'h0FFF;
		end
		wstrb_alignment_done <= 1;
		wstrb_state <= WSTRB_ALIGNMENT_DONE;
	     end
	   // This state shows end of alignment,
	   // So, once its done, you assert a flag
	   // which will go into DRAM_STATE and 
	   // dram state will start further processing
	   WSTRB_ALIGNMENT_DONE:
	     if(wlast_counter_is_zero && wdata_write_en) begin
		if(RTL_USE_MODE==1) begin
		   if(UC_AXI_DATA_WIDTH==32) begin
		      wstrb_delay<=3;
		      wstrb_state<=WSTRB_HM_DELAY;
		   end
		   else if (UC_AXI_DATA_WIDTH==64) begin
		      wstrb_delay<=0;
		      wstrb_state<=WSTRB_HM_DELAY;
		   end
		   else begin
		      wstrb_alignment_done<=0;	
		      wstrb_delay<=0;
		      wstrb_state<=WSTRB_IDLE;
		   end			
		end
		else begin
		   wstrb_alignment_done<=0;
		   wstrb_state<=WSTRB_IDLE;
		end
	     end
	     else begin
		wstrb_alignment_done<=1;
		wstrb_state<=WSTRB_ALIGNMENT_DONE;
	     end
	   
	   // hm delay: in case of HM, it is required
	   // to delay assertion/deassertion of few 
	   // control signals as data takes extra cycle
	   // to arrive. So for that, sending FSM in wait
	   // state
	   WSTRB_HM_DELAY:
	     if(wstrb_delay==0) begin
		wstrb_alignment_done<=0;
		wstrb_state<=WSTRB_IDLE;
	     end
	     else begin
		wstrb_delay<=wstrb_delay-1;
		wstrb_state<=WSTRB_HM_DELAY;
	     end
	   default:
	     wstrb_state<=wstrb_state;
	 endcase 
      end 
   end 
   



   /////////////////////////////////////////////////////////////////
   //
   // when wlast_counter_is_zero i.e its wlast
   // when current_txn_Wstrb_mode is 0 i.e constant wstrb
   // when wstrb_alignment_done is 1. i.e WSTRB_FSM is done adjusting wstrbs
   // when wdata_write_en is 1. data is also being written, along with wstrbs.
   //       Then, assert aligned wstrb ELSE keep them Fixeds to all FFFF!
   //
   ////////////////////////////////////////////////////////////////////////////

   assign adjust_wlast_wstrb_valid = ( wlast_counter_is_zero & ~current_txn_wstrb_mode & wstrb_alignment_done & wdata_write_en );
   assign  wlast_wstrb_aligned = adjust_wlast_wstrb_valid ? aligned_wstrb : wdata_wstrb ;

   

   //////////////////////////////////////////////////////////////////////////////
   //
   // Shifting control and data to adjust delay in arrival of wdata from DRAM
   //
   //////////////////////////////////////////////////////////////////////////////
   
   `FF(axi_aclk, ~axi_aresetn, wlast_wstrb_aligned  ,  wlast_wstrb_aligned_ff )
   `FF(axi_aclk, ~axi_aresetn, wlast_wstrb_aligned_ff  ,  wlast_wstrb_aligned_ff2 )
   `FF(axi_aclk, ~axi_aresetn, wlast_wstrb_aligned_ff2  ,  wlast_wstrb_aligned_ff3 )
   `FF(axi_aclk, ~axi_aresetn, wlast_wstrb_aligned_ff3  ,  wlast_wstrb_aligned_ff4 )
   `FF(axi_aclk, ~axi_aresetn, wlast_wstrb_aligned_ff4  ,  wlast_wstrb_aligned_ff5 )
   `FF(axi_aclk, ~axi_aresetn, wlast_wstrb_aligned_ff5  ,  wlast_wstrb_aligned_ff6 )

   `FF(axi_aclk, ~axi_aresetn, adjust_wlast_wstrb_valid  ,  adjust_wlast_wstrb_valid_ff )
   `FF(axi_aclk, ~axi_aresetn, adjust_wlast_wstrb_valid_ff  ,  adjust_wlast_wstrb_valid_ff2 )
   `FF(axi_aclk, ~axi_aresetn, adjust_wlast_wstrb_valid_ff2  ,  adjust_wlast_wstrb_valid_ff3 )
   `FF(axi_aclk, ~axi_aresetn, adjust_wlast_wstrb_valid_ff3  ,  adjust_wlast_wstrb_valid_ff4 )
   
   //Flopping wstrb alignment done as it takes few cycels to actually writ eit
   `FF(axi_aclk, ~axi_aresetn, wstrb_alignment_done  ,  wstrb_alignment_done_ff )
   `FF(axi_aclk, ~axi_aresetn, wstrb_alignment_done_ff  ,  wstrb_alignment_done_ff2 )
   `FF(axi_aclk, ~axi_aresetn, wstrb_alignment_done_ff2  ,  wstrb_alignment_done_ff3 )
   `FF(axi_aclk, ~axi_aresetn, wstrb_alignment_done_ff3  ,  wstrb_alignment_done_ff4 )
   `FF(axi_aclk, ~axi_aresetn, wstrb_alignment_done_ff4  ,  wstrb_alignment_done_ff5 )

   `FF(axi_aclk, ~axi_aresetn, current_txn_wstrb_mode  ,  current_txn_wstrb_mode_ff )
   `FF(axi_aclk, ~axi_aresetn, current_txn_wstrb_mode_ff  ,  current_txn_wstrb_mode_ff2 )
   `FF(axi_aclk, ~axi_aresetn, current_txn_wstrb_mode_ff2  ,  current_txn_wstrb_mode_ff3 )
   `FF(axi_aclk, ~axi_aresetn, current_txn_wstrb_mode_ff3  ,  current_txn_wstrb_mode_ff4 )
   `FF(axi_aclk, ~axi_aresetn, current_txn_wstrb_mode_ff4  ,  current_txn_wstrb_mode_ff5 )
   `FF(axi_aclk, ~axi_aresetn, current_txn_wstrb_mode_ff5  ,  current_txn_wstrb_mode_ff6 )

   // *_to_fifo signals are delayed signals, they are used to adjust latency of writing into fifo
   // current txn wstrb mode to indicated when writing into fifo that, wstrb to be written from 
   // DRAM or Fixed
   assign current_txn_wstrb_mode_to_fifo = ( (RTL_USE_MODE ==1 ) ?
					     ( ( UC_AXI_DATA_WIDTH ==32 ) ? current_txn_wstrb_mode_ff6 : 
					       ( UC_AXI_DATA_WIDTH == 64 ) ? current_txn_wstrb_mode_ff4 : current_txn_wstrb_mode_ff4 ) :
					     current_txn_wstrb_mode_ff3 );

   // wlast wstrb is auto generated wstrb in the case of HM and UM both in the WLAST Cycle.
   assign wlast_wstrb_aligned_to_fifo = ( (RTL_USE_MODE ==1 ) ?
					  ( ( UC_AXI_DATA_WIDTH ==32 ) ? wlast_wstrb_aligned_ff6 : 
					    ( UC_AXI_DATA_WIDTH == 64 ) ? wlast_wstrb_aligned_ff5 : wlast_wstrb_aligned_ff4 ) :
					  wlast_wstrb_aligned_ff3 );
   
   

   // rb2uc read wstrb written into fifo. If current wstrb mode is/was 0, write fixed one, or variable
   assign rb2uc_rd_wstrb_aligned = ( ~current_txn_wstrb_mode_to_fifo ) ? wlast_wstrb_aligned_to_fifo :rb2uc_rd_wstrb_int;
   
   
   
   ///////////////////////////////////////////////////////////
   // W_pending fifo
   // To store which request went on to AXI bus
   // It will store only once slave gives AWREADY.
   // desc ID is flopped version of data output of 
   // descriptor fifo
   ///////////////////////////////////////////////////////////
   
   sync_fifo
     #(
       .DEPTH(MAX_DESC),
       .WIDTH((`CLOG2(MAX_DESC)) + M_AXI_USR_LEN + WSTRB_SIZE +  3  )
       )
   W_request_pending_fifo (
			   .clk(axi_aclk),
			   .rst_n(axi_aresetn),
			   .din({wdata_request_id,wdata_request_awlen,wdata_request_awaddr[((`CLOG2(M_AXI_USR_DATA_WIDTH/8))-1):0],wdata_request_awsize}),
			   .wren(awnext),
			   .empty(W_pending_fifo_empty),
			   .full(W_pending_fifo_full),
			   .dout({W_pending_read_id,W_pending_awlen,W_pending_awaddr,W_pending_awsize}),
			   .rden(W_pending_read_en)
			   );
   
   
   ///////////////////////////////////////////////////////////////
   //
   // Flop read en to sync with other blocks
   //
   //////////////////////////////////////////////////////////////

   `FF(axi_aclk,~axi_aresetn,W_pending_read_en , W_pending_read_en_ff);
   
   //////////////////////////////////////////////////////////////////////
   //
   // Capture awlen & id during the read_en and keep it until new id comes
   //
   ///////////////////////////////////////////////////////////////////////

   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
   	 W_pending_read_id_ff<=0;
      end
      else if(W_pending_read_en_ff) begin
	 W_pending_read_id_ff<=W_pending_read_id;
      end 
      else begin
	 W_pending_read_id_ff<=W_pending_read_id_ff;
      end
   end


   // wdata read out from Fifo, it actualy goes out on BUS
   assign wdata_read_out_wdata= wdata_read_out;
   
   ///////////////////////////////////////////////////////////
   // 
   // Flopping wdata_write_en to sync with dram delay
   //
   ///////////////////////////////////////////////////////////

   `FF(axi_aclk, ~axi_aresetn, wdata_write_en    , wdata_write_en_ff)
   `FF(axi_aclk, ~axi_aresetn, wdata_write_en_ff    , wdata_write_en_ff2)
   `FF(axi_aclk, ~axi_aresetn, wdata_write_en_ff2   , wdata_write_en_ff3)
   `FF(axi_aclk, ~axi_aresetn, wdata_write_en_ff3   , wdata_write_en_ff4)
   `FF(axi_aclk, ~axi_aresetn, wdata_write_en_ff4   , wdata_write_en_ff5)
   `FF(axi_aclk, ~axi_aresetn, wdata_write_en_ff5   , wdata_write_en_ff6)
   `FF(axi_aclk, ~axi_aresetn, wdata_write_en_ff6   , wdata_write_en_ff7)
   `FF(axi_aclk, ~axi_aresetn, wdata_write_en_ff7   , wdata_write_en_ff8)
   


   ////////////////////////////////////////////////////////////////////////////////////
   //
   // Counter to keep track of current wdata being fetched (whether is last one or not )
   //
   /////////////////////////////////////////////////////////////////////////////////////


   // Descrement wlast counter, 
   // for HM Use case it needs to be descremented every
   // 2 or 4 cycles, due to data packing and unpacking delay
   // for UM use case : it is decremented for every wdata_write_en =1
   assign decr_wlast_counter = ((RTL_USE_MODE==0) ? wdata_write_en 
				: ((UC_AXI_DATA_WIDTH==32) ? (~mask_32_bit_wr[0] & mask_32_bit_wr[1] & wdata_write_en) 
				   : ( (UC_AXI_DATA_WIDTH ==64 ) ? ( mask_64_bit_wr & wdata_write_en )  : wdata_write_en) )
				);


   // Initialize interna wlast counter, it is used to indicate end of
   // transfer and assert wlast into Fifo. So to fetch next transfer
   always@( posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 wlast_counter<=0;
      end
      // when read_en asserted, in next cycle it pops up
      // awlen of corresponding descriptor
      else if (W_pending_read_en_ff) begin
	 wlast_counter<=W_pending_awlen+1;
      end
      else if (decr_wlast_counter) begin
	 wlast_counter<=wlast_counter-1;
      end
   end

   //when counter ==1, it means wlast needs to be assereted.
   assign wlast_counter_is_zero = wlast_counter[0] && ~(|wlast_counter[8:1]);
   
   
   `FF(axi_aclk,~axi_aresetn,wlast_counter_is_zero       ,wlast_counter_is_zero_ff )
   `FF(axi_aclk,~axi_aresetn,wlast_counter_is_zero_ff    ,wlast_counter_is_zero_ff2 )
   `FF(axi_aclk,~axi_aresetn,wlast_counter_is_zero_ff2   ,wlast_counter_is_zero_ff3 )
   `FF(axi_aclk,~axi_aresetn,wlast_counter_is_zero_ff3   ,wlast_counter_is_zero_ff4 )
   `FF(axi_aclk,~axi_aresetn,wlast_counter_is_zero_ff4   ,wlast_counter_is_zero_ff5 )
   `FF(axi_aclk,~axi_aresetn,wlast_counter_is_zero_ff5   ,wlast_counter_is_zero_ff6 )
   
   
   //////////////////////////////////////////////////////////////////////////////
   //
   //		FSM To fetch wdata that is pending and store into fifo
   //
   //////////////////////////////////////////////////////////////////////////////

   localparam
     DRAM_READ_IDLE=3'b000,
     DRAM_READ_GET_ID=3'b001,
     DRAM_READ_FETCH_OFFSET=3'b010,
     DRAM_READ_WRITE_FIFO=3'b100,
     DRAM_WAIT_FOR_HM_DONE=3'b101,
     DRAM_READ_HM_DELAY= 3'b110,
     DRAM_CHECK_FOR_WSTRB = 3'b011;

   


   // Only for HM use case: This is used to propogate at the top wrapper, it indicates
   // which desc id wdata is being fetched by this block.
   // based on Desc ID host_control has to decide wheather to give WSTRB or WDATA!
   assign uc2rb_rd_addr_desc_id = (RTL_USE_MODE==1) ? 
				  ( 
				    (UC_AXI_DATA_WIDTH==128) ? W_pending_read_id_ff4 : 
				    ( (UC_AXI_DATA_WIDTH==64) ? W_pending_read_id_ff5 : W_pending_read_id_ff6 ) 
				    ) :
				  W_pending_read_id_ff3;
   
   
   // Incrementing uc2rb address
   assign rb_rd_addr_increment= 'b1;
   
   always@(posedge axi_aclk)
     begin
	if(axi_aresetn==0) 
	  begin
	     dram_state<=DRAM_READ_IDLE;
	     wdata_write_en<=0; 
	     uc2rb_rd_addr<='h0;
	     W_pending_read_en<=0;
	     check_for_wstrb_alignment<=0;
	  end 
	else begin
	   case(dram_state)
	     DRAM_READ_IDLE:
	       //If some Tx started on  AW Channel
	       //Then W_pending fifo will have some
	       //desc ID in Fifo. Read that ID first
	       if(~W_pending_fifo_empty) begin
		  //ReadEn of next tx to be plased on bus
		  W_pending_read_en<=1;
		  check_for_wstrb_alignment<=0;
		  dram_state<=DRAM_READ_GET_ID;
	       end
	       else begin
		  check_for_wstrb_alignment<=0;
		  dram_state<=DRAM_READ_IDLE;
	       end
	     DRAM_READ_GET_ID :
	       //Once read en check if use_mode is 0/1
	       // if 0, go on and start reading data from DRAM
	       // if 1, trigger hm, to fetch data from Host &
	       // wait for it to complete  
	       if(W_pending_read_en) begin
		  //If use mode is==1 mean Need to first see
		  //If all WDATA is fetched from Host or not. 
		  //Indicated by hm_done_int
		  if(use_mode==1) begin
		     //Deassert ReadEn & Fetch offset in 
		     //next state
		     W_pending_read_en<=0;
		     dram_state<=DRAM_WAIT_FOR_HM_DONE;
		  end
		  else begin
		     // its not mode1, so go and fetch
		     // data from DRAM.
		     W_pending_read_en<=0;
		     dram_state<=DRAM_CHECK_FOR_WSTRB;
		  end
	       end 

	     //If running in Mode1, Wait till hm is done and then
	     // only start transfer
	     DRAM_WAIT_FOR_HM_DONE:
	       // If mode is selected as 1, then wait 
	       // for HM to done with 
	       // reading data from Host
	       if(hm_done_int[W_pending_read_id]==1) begin
		  dram_state<=DRAM_CHECK_FOR_WSTRB;
	       end
	       else begin
		  dram_state<=DRAM_WAIT_FOR_HM_DONE;
	       end

	     DRAM_CHECK_FOR_WSTRB:
	       if(~current_txn_wstrb_mode & ~wstrb_alignment_done) begin
		  check_for_wstrb_alignment <= 1;
		  dram_state<= DRAM_CHECK_FOR_WSTRB;
	       end
	       else if(wstrb_alignment_done) begin
		  check_for_wstrb_alignment <= 0;
		  dram_state<= DRAM_READ_FETCH_OFFSET;
	       end
	       else begin
		  check_for_wstrb_alignment <= 0;
		  dram_state<= DRAM_READ_FETCH_OFFSET;
	       end
	     
	     
	     DRAM_READ_FETCH_OFFSET :
	       if(~W_pending_read_en) begin
		  // First get offset address of Desc ID that was
		  // in fifo, Map that ID into registers and 
		  // fetch corresponding data offset
		  // Send that offset into uc2rb_addr bus

		  // Address width & Shift is dependent on DUT Width
		  // i.e if DUT Data width=128, WDATA RAM will have addess in
		  //     multiples of 16 byes, 0x10,0x20,0x30. So need to remove lower 4 bits.
		  uc2rb_rd_addr<=
				 int_wire_desc_n_data_offset_addr[W_pending_read_id]>>
				 ( (UC_AXI_DATA_WIDTH==128) ? 4: ( (UC_AXI_DATA_WIDTH==64) ? 3:2) ) ;
		  
		  // At the same time asserting wdata_write 
		  // Actual will be depending on dram delay.
		  wdata_write_en<=1;
		  // Feed in wuser info.
		  wdata_wuser<=wdata_wuser_in;
		  wdata_wid<=wdata_wid_in;
		  dram_state <= DRAM_READ_WRITE_FIFO;
	       end 
	       else begin
		  dram_state <= DRAM_READ_IDLE;
	       end 
	     
	     DRAM_READ_WRITE_FIFO:
	       /* If wlast asserted, that's the end of transfer
		So Stop writing and go to IDLE  */
	       if (wlast_counter_is_zero && wdata_write_en) begin
		  if(RTL_USE_MODE==1) begin
		     if(UC_AXI_DATA_WIDTH==32) begin
			wdata_write_en<=1;
			wdata_delay<=3;
			uc2rb_rd_addr<=uc2rb_rd_addr+rb_rd_addr_increment;
			dram_state<=DRAM_READ_HM_DELAY;
		     end
		     else if(UC_AXI_DATA_WIDTH==64) begin
			wdata_write_en<=1;
			wdata_delay<=0;
			uc2rb_rd_addr<=uc2rb_rd_addr+rb_rd_addr_increment;
			dram_state<=DRAM_READ_HM_DELAY;
		     end
		     else begin
			wdata_write_en<=0;
			dram_state<=DRAM_READ_IDLE;
		     end
		  end 
		  else begin
		     wdata_write_en<=0;
		     uc2rb_rd_addr<=uc2rb_rd_addr;
		     dram_state<=DRAM_READ_IDLE;
		  end 
	       end 
	     
	     
	     
	     /* If wdata_fifo is not full, slave is accepting
	      the data on the AXI Bus, So keep pushing new data into Fifo,
	      until Wlast is not asserted. Upon wlast assertion stop
	      pushing data into Fifo*/
	       else if(~wdata_fifo_full && ~wdata_almost_full) begin
		  wdata_write_en<=1;
		  uc2rb_rd_addr<=uc2rb_rd_addr+rb_rd_addr_increment;
		  dram_state<=DRAM_READ_WRITE_FIFO;
	       end
	       else begin
		  uc2rb_rd_addr<=uc2rb_rd_addr;
		  wdata_write_en<=0;
		  dram_state<=DRAM_READ_WRITE_FIFO;
	       end 

	     DRAM_READ_HM_DELAY:
	       if(wdata_delay==0) begin
		  wdata_write_en<=0;
		  dram_state<=DRAM_READ_IDLE;
	       end
	       else begin
		  wdata_delay<=wdata_delay-1;
		  uc2rb_rd_addr<=uc2rb_rd_addr+rb_rd_addr_increment;
		  dram_state<=DRAM_READ_HM_DELAY;
	       end
	     
	     default:
	       dram_state<=dram_state;
	   endcase
	end
     end	



   always@(posedge axi_aclk) begin
      if(~axi_aresetn || W_pending_read_en ) begin
	 mask_64_bit_wr <=0;
      end
      else if (wdata_write_en) begin
	 mask_64_bit_wr<=~mask_64_bit_wr;
      end
      else begin
	 mask_64_bit_wr<=mask_64_bit_wr;
      end
   end

   always@ (posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 mask_64_bit_wr_ff <= 0;
	 mask_64_bit_wr_ff2 <= 0;
	 mask_64_bit_wr_ff3 <= 0;
	 mask_64_bit_wr_ff4 <= 0;
	 mask_64_bit_wr_ff5 <= 0;
      end
      else begin
	 mask_64_bit_wr_ff <= mask_64_bit_wr;
	 mask_64_bit_wr_ff2 <= mask_64_bit_wr_ff;
	 mask_64_bit_wr_ff3 <= mask_64_bit_wr_ff2;
	 mask_64_bit_wr_ff4 <= mask_64_bit_wr_ff3;
	 mask_64_bit_wr_ff5 <= mask_64_bit_wr_ff4;
      end
   end



   // For 32 bit generating mask in case of HM
   // Start a counter which will mask data written into the DRAM.
   // The reason is that, when used as an HM, it gets data only once in
   // Four cycles.
   always@(posedge axi_aclk) begin
      if(~axi_aresetn || W_pending_read_en ) begin
	 mask_32_bit_wr <=0;
      end
      else if (wdata_write_en) begin
	 mask_32_bit_wr<=mask_32_bit_wr + 1;
      end
      else begin
	 mask_32_bit_wr<=mask_32_bit_wr;
      end
   end

   //Mask delayed to adjust with data reading
   always@ (posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 mask_32_bit_wr_ff <= 0;
	 mask_32_bit_wr_ff2 <= 0;
	 mask_32_bit_wr_ff3 <= 0;
	 mask_32_bit_wr_ff4 <= 0;
	 mask_32_bit_wr_ff5 <= 0;
	 mask_32_bit_wr_ff6 <= 0;
      end
      else begin
	 mask_32_bit_wr_ff <= mask_32_bit_wr;
	 mask_32_bit_wr_ff2 <= mask_32_bit_wr_ff;
	 mask_32_bit_wr_ff3 <= mask_32_bit_wr_ff2;
	 mask_32_bit_wr_ff4 <= mask_32_bit_wr_ff3;
	 mask_32_bit_wr_ff5 <= mask_32_bit_wr_ff4;
	 mask_32_bit_wr_ff6 <= mask_32_bit_wr_ff5;
      end
   end
   

   
   assign wdata_wr_en_32_uc = ~mask_32_bit_wr_ff6[0] & mask_32_bit_wr_ff6[1] & wdata_write_en_ff6 ;
   assign wdata_wr_en_64_uc = mask_64_bit_wr_ff5 & wdata_write_en_ff5;
   assign wdata_wr_en_128_uc = wdata_write_en_ff4;
   
   assign wdata_write_en_to_fifo = (UC_AXI_DATA_WIDTH==128) ? wdata_wr_en_128_uc :
				   ((UC_AXI_DATA_WIDTH==64) ? wdata_wr_en_64_uc :wdata_wr_en_32_uc);

   //wlast written in to Fifo is delayed when used as an HM, as read data is also delayed
   assign W_data_wlast = ( RTL_USE_MODE==1) ? 
			 ((UC_AXI_DATA_WIDTH==128) ? wlast_counter_is_zero_ff4 :
			  ((UC_AXI_DATA_WIDTH==64) ? wlast_counter_is_zero_ff5 : wlast_counter_is_zero_ff6) ) :
			 wlast_counter_is_zero_ff3;
   
   
   ////////////////////////////////////////////////////////////////////
   //
   // FSM to read data from FIFO And sending it to AXI Intfc
   //
   ////////////////////////////////////////////////////////////////////

   localparam 
     DRAM_WDATA_RFIFO_IDLE=1'b0,
     DRAM_WDATA_RFIFO_READ=1'b1;
   
   always@ (posedge axi_aclk) 
     begin
	if(~axi_aresetn) begin
	   dram_wdata_rfifo_state<=DRAM_WDATA_RFIFO_IDLE;
	   wdata_read_en<=0;
	end
	else begin
	   case(dram_wdata_rfifo_state)
	     DRAM_WDATA_RFIFO_IDLE:
	       /* If fifo is not empty, means there is some 
		data to send. Keep on popping Data until 
		fifo is not empty*/
	       if(~wdata_fifo_empty) begin
		  wdata_read_en<=1;
		  dram_wdata_rfifo_state<=DRAM_WDATA_RFIFO_READ;
	       end
	       else begin
		  wdata_read_en<=0;
		  dram_wdata_rfifo_state<=DRAM_WDATA_RFIFO_IDLE;
	       end
	     
	     DRAM_WDATA_RFIFO_READ:
	       /* Keep on popping data until wlast comes && fifo is empty */
	       if(~wdata_fifo_empty && ~wdata_read_out_wlast) begin
		  wdata_read_en<=1;
		  dram_wdata_rfifo_state<=DRAM_WDATA_RFIFO_READ;
		  
	       end
	     // if wlast comes and it was accepted by slave with wready 
	     // keep wdata_read_en to = 0, it indicated end of txn
	       else if(wdata_read_out_wlast && wnext) begin
		  wdata_read_en<=0;
		  dram_wdata_rfifo_state<=DRAM_WDATA_RFIFO_IDLE;
	       end
	     // if in between any transfer wdata fifo becomes empty
	     // ( It will happen in case of HM, when DUT data width is < 128 )
	     // and 
	       else if(wdata_fifo_empty & wnext) begin
		  wdata_read_en<=0;
		  dram_wdata_rfifo_state<=DRAM_WDATA_RFIFO_IDLE;
	       end
	       else begin
		  wdata_read_en<=wdata_read_en;
		  dram_wdata_rfifo_state<=DRAM_WDATA_RFIFO_READ;
	       end

	     
	   endcase
	end
     end
   
   ///////////////////////////////////////////////////////////////
   //
   // This is to generate pulse in the case of start of transfer
   //
   ///////////////////////////////////////////////////////////////

   `FF(axi_aclk,~axi_aresetn,wdata_read_en      ,wdata_read_en_ff);
   `FF(axi_aclk,~axi_aresetn,wdata_read_en_ff   ,wdata_read_en_ff2);
   `FF(axi_aclk,~axi_aresetn,wdata_read_en_ff2  ,wdata_read_en_ff3);
   

   //////////////////////////////////////////////////////////////////////////////////
   //
   // first_write_wdata generates wvalid on the bus. It is trigger for
   // fethcing wdata for the very first cycle as the first wdata shouldn't depend on 
   // wready from slave. After first trigger, wdata fetching will be handled
   // by wready only.
   //
   //////////////////////////////////////////////////////////////////////////////////

   assign first_write_wdata= ~wdata_read_en_ff & wdata_read_en;

   ///////////////////////////////////////////////////////////////
   //
   // wuser flopped, to sync with wdata cominng from dram
   //
   ///////////////////////////////////////////////////////////////

   `FF(axi_aclk,~axi_aresetn, wdata_wuser,    wdata_wuser_ff);
   `FF(axi_aclk,~axi_aresetn, wdata_wuser_ff,    wdata_wuser_ff2);
   `FF(axi_aclk,~axi_aresetn, wdata_wuser_ff2,    wdata_wuser_ff3);
   

   ///////////////////////////////////////////////////////////////
   //
   // wid flopped, to sync with wdata cominng from dram
   //
   ///////////////////////////////////////////////////////////////

   `FF(axi_aclk,~axi_aresetn, wdata_wid,    wdata_wid_ff);
   `FF(axi_aclk,~axi_aresetn, wdata_wid_ff,    wdata_wid_ff2);
   `FF(axi_aclk,~axi_aresetn, wdata_wid_ff2,    wdata_wid_ff3);

   

   /////////////////////////////////////////////////////////////
   //
   // Fifo to store wdata from DRAM
   //
   //////////////////////////////////////////////////////////// 
   
   sync_fifo
     #(
       .DEPTH( WDATA_FIFO_DEPTH ), 
       .WIDTH( M_AXI_USR_DATA_WIDTH 
	       + (M_AXI_USR_DATA_WIDTH/8) 
	       + (M_AXI_USR_WUSER_WIDTH + M_AXI_USR_ID_WIDTH +1	)))

   W_data (
	   .clk(axi_aclk),
	   .rst_n(axi_aresetn),
	   .din({rb2uc_rd_data,rb2uc_rd_wstrb_aligned,wdata_wuser_ff3,wdata_wid_ff3,W_data_wlast}),
      
	   // It starts when any new request comes into W_pending Fifo and data starts
	   // coming from DRAM. If slave always accepts data (wready is always high, it will not deassert
	   // in between any txn. If wready is low, fifo will be Full in between and w_data write_en will
	   // go low and high once fifo is not full.
      
	   .wren(				  
						  (RTL_USE_MODE==0)?wdata_write_en_ff3: 
						  ( wdata_write_en_to_fifo) 
						  ),
	   .empty(wdata_fifo_empty),
	   .full(wdata_fifo_full),
	   .dout({wdata_read_out,wdata_read_out_wstrb,wdata_read_out_wuser,wdata_read_out_wid,wdata_read_out_wlast}),
      
	   // Read en is mainly responsible for handling wdata_fifo empty case
      
	   // Overall: Initially wdata_read_en and first_write_wdata helps it to get started.
	   // Once it starts, first_write_wdata will deassert. Now once there is wready, all control is given
	   // to slave (WNEXT) which indicates wvalid/wready handshake, so on each wnext next
	   // wdata is popped out, provided there is no wlast & fifo is not empty!.
      
	   // 1) wdata_read_en : it comes from FSM which starts as soon as
	   // wdata fifo is not empty. but, it is not just enough. It generates
	   // a pulse called first_write_wdata on its first cycle
      
	   // 2) first_write_wdata : This pulse is used when there is the first time write on bus, as
	   // there won't be any wnext for the first write, so need someone to start the transfer.
	   // That's why it is ORed with wnext. once deasserted control goes in hand of wnext now.
	   // - In case of HM, wdata_read_en can go low, because there can be a case where fifo is empty ( <128 DWIDTH)
	   // so in that case, wdata_read_en comes back once fifo is not empty, and whole story repeats again!

	   // 3) wnext = wvalid & wready

	   // 4) wdata_fifo_empty = ! To avoid reading when its empty !

	   // 5) wdata_read_out_wlast : WLAST is pused into fifo for each transfers, so if fifo pops a write and
	   // finds that its wlast, it shouldn't go and fetch new transfer, because then in next transfer it will
	   // again assert first_write_wdata (!) which is tricky to handle . So masking next fetch once wlast comes.
      
	   .rden(wdata_read_en && ( (wnext && ~wdata_read_out_wlast) || first_write_wdata) && ~wdata_fifo_empty ),
	   .fifo_counter(W_fifo_count)
	   );


   ////////////////////////////////////////////////////////////////
     //
   // wdata almost full, to handle backpresure.
   // due to delay in dram, four requests are already in flight, and
   // when wready is low, it is indicating that fifo is full by keeping space for
   // four data
   //
   //////////////////////////////////////////////////////////////////

   assign wdata_fifo_almost_full= (W_fifo_count>=(WDATA_FIFO_DEPTH-6))?1:0;

   
   assign wdata_almost_full = (RTL_USE_MODE==1) ?
			      ( (UC_AXI_DATA_WIDTH==32) ? wdata_fifo_almost_full_valid_32 :wdata_fifo_almost_full ) :wdata_fifo_almost_full;

   
   always @ (posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 wdata_fifo_almost_full_valid_32<=0;
      end
      else if(mask_32_bit_wr_ff6==0) begin
	 wdata_fifo_almost_full_valid_32<=wdata_fifo_almost_full_ff;
      end
      else begin
	 wdata_fifo_almost_full_valid_32<=wdata_fifo_almost_full_valid_32;
      end
      
   end
   
   always@(posedge axi_aclk)  begin
      if(~axi_aresetn) begin
	 wdata_fifo_almost_full_ff <=0 ;
	 wdata_fifo_almost_full_ff1<=0 ;
	 wdata_fifo_almost_full_ff2<=0 ;

      end
      else begin
	 wdata_fifo_almost_full_ff<=wdata_fifo_almost_full;
	 wdata_fifo_almost_full_ff1<=wdata_fifo_almost_full_ff;
	 wdata_fifo_almost_full_ff2<=wdata_fifo_almost_full_ff1;
      end
      
   end




endmodule
