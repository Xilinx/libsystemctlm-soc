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
 *   This module controls ACE-usr interface channel and "ready" signals. 
 * 
 */

`include "ace_defines_common.vh"

module ace_ctrl_valid #(

			parameter ACE_PROTOCOL                                         = "FULLACE"

			//Allowed Values : 
			//  "SLV_WR_RESP",  "SLV_SN_REQ",  "MST_RD_REQ", "MST_SN_RESP", 
			//  "SLV_RD_RESP",   
			//  "MST_WR_REQ_AW",  "MST_WR_REQ_W",
			//  "MST_SN_DATA"
			,parameter ACE_CHANNEL                                          = "SLV_RD_REQ" 
			
			,parameter ADDR_WIDTH                                           = 64 
			,parameter DATA_WIDTH                                           = 128       
			
			,parameter ID_WIDTH                                             = 16        
			,parameter AWUSER_WIDTH                                         = 32        
			,parameter WUSER_WIDTH                                          = 32        
			,parameter BUSER_WIDTH                                          = 32        
			,parameter ARUSER_WIDTH                                         = 32        
			,parameter RUSER_WIDTH                                          = 32        
			
			,parameter INFBUS_WIDTH                                         = 300
			,parameter FR_DESCBUS_WIDTH                                     = 300    
			
			,parameter CACHE_LINE_SIZE                                      = 64 
			,parameter MAX_DESC                                             = 16         
			,parameter RAM_SIZE                                             = 16384     
			
			)(
			  
			  //Clock and reset
			  input clk 
			  ,input resetn
   
			  //s_ace_usr or m_ace_usr signals
			  ,output [INFBUS_WIDTH-1:0] infbus 
			  ,output infbus_last 
			  ,output [((`CLOG2(MAX_DESC))-1):0] infbus_desc_idx
			  ,output reg infbus_valid 
			  ,input infbus_ready 
			  ,input inf_xack 
   
			  //Descriptor signals
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_0 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_1 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_2 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_3 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_4 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_5 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_6 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_7 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_8 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_9 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_A 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_B 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_C 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_D 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_E 
			  ,input [FR_DESCBUS_WIDTH-1:0] fr_descbus_F 
   
			  ,input [7:0] fr_descbus_len_0 
			  ,input [7:0] fr_descbus_len_1 
			  ,input [7:0] fr_descbus_len_2 
			  ,input [7:0] fr_descbus_len_3 
			  ,input [7:0] fr_descbus_len_4 
			  ,input [7:0] fr_descbus_len_5 
			  ,input [7:0] fr_descbus_len_6 
			  ,input [7:0] fr_descbus_len_7 
			  ,input [7:0] fr_descbus_len_8 
			  ,input [7:0] fr_descbus_len_9 
			  ,input [7:0] fr_descbus_len_A 
			  ,input [7:0] fr_descbus_len_B 
			  ,input [7:0] fr_descbus_len_C 
			  ,input [7:0] fr_descbus_len_D 
			  ,input [7:0] fr_descbus_len_E 
			  ,input [7:0] fr_descbus_len_F 
   
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_0
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_1
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_2
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_3
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_4
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_5
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_6
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_7
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_8
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_9
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_A
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_B
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_C
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_D
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_E
			  ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] fr_descbus_dtoffset_F
   
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_0 //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_1 //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_2 //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_3 //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_4 //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_5 //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_6 //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_7 //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_8 //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_9 //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_A //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_B //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_C //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_D //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_E //Applicable in case of mst-read case only
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_F //Applicable in case of mst-read case only
   
   
			  //Mode selection
			  ,input int_mode_select_mode_0_1
   
			  ,input [MAX_DESC-1:0] txn_type_wr_strb
   
			  ,input [MAX_DESC-1:0] free_desc //Applicable in case of mst-read case only
   
			  //Registers
			  ,input fifo_wren //should be one clock cycle pulse
			  ,input [(`CLOG2(MAX_DESC))-1:0] fifo_din
			  ,output [(`CLOG2(MAX_DESC)):0] fifo_fill_level
			  ,output [(`CLOG2(MAX_DESC)):0] fifo_free_level
			  ,output reg [MAX_DESC-1:0] intr_comp_status_comp
			  ,input [MAX_DESC-1:0] intr_comp_clear_clr_comp
   
			  //DATA_RAM and WSTRB_RAM                               
			  ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] uc2rb_addr 
			  ,input [DATA_WIDTH-1:0] rb2uc_data 
			  ,input [(DATA_WIDTH/8)-1:0] rb2uc_wstrb
   
			  //Mode-1 signals
			  ,output reg [MAX_DESC-1:0] uc2hm_trig 
			  ,input [MAX_DESC-1:0] hm2uc_done

			  );

   localparam BRIDGE_TYPE                                                  = 
									     ( (ACE_CHANNEL=="SLV_RD_RESP") || (ACE_CHANNEL=="SLV_WR_RESP") || (ACE_CHANNEL=="SLV_SN_REQ") ) ?
                                                                             "SLV_BRIDGE"
   : "MST_BRIDGE" ;

   localparam CHANNEL_TYPE                                                 = 
									     ( (ACE_CHANNEL=="SLV_SN_REQ") || (ACE_CHANNEL=="MST_SN_RESP") || (ACE_CHANNEL=="MST_SN_DATA") ) ?
									     "SN"
   : ( ( (ACE_CHANNEL=="SLV_RD_RESP") || (ACE_CHANNEL=="MST_RD_REQ") ) ? "RD" : "WR") ;


   localparam IS_DATA                                                   = 
									  ( (ACE_CHANNEL=="SLV_RD_RESP") || (ACE_CHANNEL=="MST_WR_REQ_W") || (ACE_CHANNEL=="MST_SN_DATA") ) ?
                                                                          "YES"
   : "NO" ;

   localparam IS_MODE_1                                                   = 
									    ( (ACE_CHANNEL=="SLV_RD_RESP") || (ACE_CHANNEL=="MST_WR_REQ_W") ) ?
                                                                            "YES"
   : "NO" ;

   localparam IS_XACK                                                   = 
									  ( (ACE_CHANNEL=="SLV_RD_RESP") || (ACE_CHANNEL=="SLV_WR_RESP") ) ?
                                                                          "YES"
   : "NO" ;

   localparam DESC_IDX_WIDTH                                              = `CLOG2(MAX_DESC);
   localparam RAM_OFFSET_WIDTH                                            = `CLOG2((RAM_SIZE*8)/DATA_WIDTH);

   localparam WSTRB_WIDTH                                                 = (DATA_WIDTH/8);
   localparam XLAST_WIDTH                                                  = 1; //xlast width

   //all other sidebands except data,strb
   localparam DESCBUS_WIDTH                                               = (IS_DATA=="YES") ?  
                                                                            ( (ACE_CHANNEL=="MST_WR_REQ_W") ? 
                                                                              (FR_DESCBUS_WIDTH-DATA_WIDTH-WSTRB_WIDTH) 
                                                                              : (FR_DESCBUS_WIDTH-DATA_WIDTH) )
     : (FR_DESCBUS_WIDTH);

   localparam AXLEN_WIDTH                                                  = 8;
   localparam AXSIZE_WIDTH                                                 = 3;
   localparam AXBURST_WIDTH                                                = 2;
   localparam AXLOCK_WIDTH                                                 = 1;
   localparam AXCACHE_WIDTH                                                = 4;
   localparam AXPROT_WIDTH                                                 = 3;
   localparam AXQOS_WIDTH                                                  = 4;
   localparam AXREGION_WIDTH                                               = 4;

   localparam ARSNOOP_WIDTH                                                = 4;
   localparam AWSNOOP_WIDTH                                                = 3;

   localparam ACSNOOP_WIDTH                                                = 4;
   localparam ACPROT_WIDTH                                                 = 3;

   localparam AXDOMAIN_WIDTH                                               = 2;
   localparam AXBAR_WIDTH                                                  = 2;

   localparam AWUNIQUE_WIDTH                                               = 1;


   //Vector Index
   localparam VEC_0                                                        = 16'h0001; 
   localparam VEC_1                                                        = 16'h0002; 
   localparam VEC_2                                                        = 16'h0004; 
   localparam VEC_3                                                        = 16'h0008; 
   localparam VEC_4                                                        = 16'h0010; 
   localparam VEC_5                                                        = 16'h0020; 
   localparam VEC_6                                                        = 16'h0040; 
   localparam VEC_7                                                        = 16'h0080; 
   localparam VEC_8                                                        = 16'h0100; 
   localparam VEC_9                                                        = 16'h0200; 
   localparam VEC_A                                                        = 16'h0400; 
   localparam VEC_B                                                        = 16'h0800; 
   localparam VEC_C                                                        = 16'h1000; 
   localparam VEC_D                                                        = 16'h2000; 
   localparam VEC_E                                                        = 16'h4000; 
   localparam VEC_F                                                        = 16'h8000; 

   localparam DATA_IDLE                                                    = 3'b000;
   localparam DATA_NEW                                                     = 3'b001;
   localparam DATA_NEW_XXRAM                                               = 3'b010;
   localparam DATA_CON_XXRAM                                               = 3'b011;
   localparam DATA_CON_WAIT                                                = 3'b100;

   localparam OP_IDLE                                                      = 2'b00;
   localparam OP_STRT                                                      = 2'b01;
   localparam OP_WAIT                                                      = 2'b10;


   //                                                                      XLAST,DATA(if any),DESCBUS,DESC_IDX
   localparam USR_FIFO_WIDTH                                               = (XLAST_WIDTH+INFBUS_WIDTH+DESC_IDX_WIDTH);

   localparam USR_FIFO_DEPTH                                               = (IS_DATA=="YES") ? (32) : (MAX_DESC*2);

   localparam USR_FIFO_DATA_MSB                                            = (IS_DATA=="YES") ? (USR_FIFO_WIDTH-XLAST_WIDTH-1) : 'b0;
   localparam USR_FIFO_DATA_WIDTH                                          = (IS_DATA=="YES") ? (DATA_WIDTH) : 'b0;

   localparam USR_FIFO_STRB_MSB                                            = (ACE_CHANNEL=="MST_WR_REQ_W") ? (USR_FIFO_WIDTH-XLAST_WIDTH-DATA_WIDTH-1) : 'b0;
   localparam USR_FIFO_STRB_WIDTH                                          = (ACE_CHANNEL=="MST_WR_REQ_W") ? (WSTRB_WIDTH) : 'b0;

   localparam INFBUS_DATA_MSB                                              = (IS_DATA=="YES") ? (INFBUS_WIDTH-1) : 'b0;
   localparam INFBUS_DATA_WIDTH                                            = (IS_DATA=="YES") ? (DATA_WIDTH) : 'b0;


   //Loop variables
   integer 			i;
   integer 			j;
   integer 			k;

   //generate variable
   genvar 			gi;



   wire [DESCBUS_WIDTH-1:0] 	descbus[MAX_DESC-1:0];  //all other sidebands except data,strb

   wire [7:0] 			descbus_len[MAX_DESC-1:0] ; 
   wire [RAM_OFFSET_WIDTH-1:0] 	descbus_dtoffset[MAX_DESC-1:0] ; 

   reg [RAM_OFFSET_WIDTH-1:0] 	data_offset[MAX_DESC-1:0] ; 

   reg [RAM_OFFSET_WIDTH-1:0] 	uc2rb_rd_addr ; 
   wire [DATA_WIDTH-1:0] 	rb2uc_rd_data ; 
   wire [WSTRB_WIDTH-1:0] 	rb2uc_rd_wstrb;

   wire [DESC_IDX_WIDTH-1:0] 	ORDER_dout;
   wire [DESC_IDX_WIDTH-1:0] 	ORDER_dout_pre;
   wire 			ORDER_dout_pre_valid;
   wire 			ORDER_full;
   wire 			ORDER_empty;
   wire 			ORDER_wren;
   reg 				ORDER_rden;
   wire [DESC_IDX_WIDTH-1:0] 	ORDER_din;
   wire [DESC_IDX_WIDTH:0] 	ORDER_fifo_counter;

   reg [DESC_IDX_WIDTH:0] 	xack_cntr; 

   reg 				XACK_wren;      
   reg 				XACK_rden;      
   wire [DESC_IDX_WIDTH-1:0] 	XACK_din;       
   wire [DESC_IDX_WIDTH-1:0] 	XACK_dout;      
   wire 			XACK_full;      
   wire 			XACK_empty;
   wire 			XACK_almost_full;
   wire 			XACK_almost_empty;

   reg 				XACK_rden_ff;   

   reg [MAX_DESC-1:0] 		intr_comp_clear_clr_comp_ff;
   wire [MAX_DESC-1:0] 		comp;
   reg [MAX_DESC-1:0] 		comp_ff;


   reg [DESC_IDX_WIDTH-1:0] 	order_desc_idx;

   reg [MAX_DESC-1:0] 		op_done; 

   wire 			USR_wren;	
   reg 				USR_rden;	
   wire [USR_FIFO_WIDTH-1:0] 	USR_din;	
   wire [USR_FIFO_WIDTH-1:0] 	USR_dout;	
   wire 			USR_full;	
   wire 			USR_empty;
   wire 			USR_almost_full;
   wire 			USR_almost_empty;

   reg 				IDX_wren;	
   reg 				IDX_rden;	
   reg [DESC_IDX_WIDTH-1:0] 	IDX_din;	
   //reg  [DESC_IDX_WIDTH-1:0]                                               IDX_din_sig[MAX_DESC-1:0];	
   reg [MAX_DESC-1:0] 		IDX_din_sig[DESC_IDX_WIDTH-1:0];	
   wire [DESC_IDX_WIDTH-1:0] 	IDX_dout;	
   wire 			IDX_full;	
   wire 			IDX_empty;

   wire [MAX_DESC-1:0] 		txn_cmpl;

   reg [2:0] 			data_state;
   reg 				uc2rb_rd_valid;
   reg [RAM_OFFSET_WIDTH-1:0] 	xx_offset;
   reg [7:0] 			data_count;       
   reg [7:0] 			axlen;             
   reg [DESC_IDX_WIDTH-1:0] 	op_idx;            
   reg [USR_FIFO_WIDTH-1:0] 	usr_data_in;	
   
   reg [1:0] 			op_state;

   wire [DESC_IDX_WIDTH-1:0] 	usr_idx;

   reg [MAX_DESC-1:0] 		hm2uc_done_pulse;
   reg [MAX_DESC-1:0] 		hm2uc_done_retain;
   reg [MAX_DESC-1:0] 		hm2uc_done_ff;

   reg [MAX_DESC-1:0] 		xack_done; 


   reg 				rd_txn_valid;
   reg [7:0] 			rd_txn_size;
   wire 			rd_addr_alc_valid;
   wire [RAM_OFFSET_WIDTH-1:0] 	rd_addr_alc_offset;
   wire [DESC_IDX_WIDTH-1:0] 	rd_addr_alc_node_idx;

   wire 			rd_alc_valid;
   wire [DESC_IDX_WIDTH-1:0] 	rd_alc_desc_idx;
   wire [DESC_IDX_WIDTH-1:0] 	rd_alc_node_idx;

   wire [MAX_DESC-1:0] 		rd_addr_avail;

   wire [AXBAR_WIDTH-1+AXDOMAIN_WIDTH+ARSNOOP_WIDTH-1:0] read_txn[MAX_DESC-1:0];

   ///////////////////////
   //Description: 
   //  Tie imm_bresp mode to 0.
   //////////////////////
   assign sig_mode_select_imm_bresp = 1'b0;

   //1D to 2D conversion

   assign descbus['h0][DESCBUS_WIDTH-1:0] = fr_descbus_0[DESCBUS_WIDTH-1:0];
   assign descbus['h1][DESCBUS_WIDTH-1:0] = fr_descbus_1[DESCBUS_WIDTH-1:0]; 
   assign descbus['h2][DESCBUS_WIDTH-1:0] = fr_descbus_2[DESCBUS_WIDTH-1:0]; 
   assign descbus['h3][DESCBUS_WIDTH-1:0] = fr_descbus_3[DESCBUS_WIDTH-1:0]; 
   assign descbus['h4][DESCBUS_WIDTH-1:0] = fr_descbus_4[DESCBUS_WIDTH-1:0]; 
   assign descbus['h5][DESCBUS_WIDTH-1:0] = fr_descbus_5[DESCBUS_WIDTH-1:0]; 
   assign descbus['h6][DESCBUS_WIDTH-1:0] = fr_descbus_6[DESCBUS_WIDTH-1:0]; 
   assign descbus['h7][DESCBUS_WIDTH-1:0] = fr_descbus_7[DESCBUS_WIDTH-1:0]; 
   assign descbus['h8][DESCBUS_WIDTH-1:0] = fr_descbus_8[DESCBUS_WIDTH-1:0]; 
   assign descbus['h9][DESCBUS_WIDTH-1:0] = fr_descbus_9[DESCBUS_WIDTH-1:0]; 
   assign descbus['hA][DESCBUS_WIDTH-1:0] = fr_descbus_A[DESCBUS_WIDTH-1:0]; 
   assign descbus['hB][DESCBUS_WIDTH-1:0] = fr_descbus_B[DESCBUS_WIDTH-1:0]; 
   assign descbus['hC][DESCBUS_WIDTH-1:0] = fr_descbus_C[DESCBUS_WIDTH-1:0]; 
   assign descbus['hD][DESCBUS_WIDTH-1:0] = fr_descbus_D[DESCBUS_WIDTH-1:0]; 
   assign descbus['hE][DESCBUS_WIDTH-1:0] = fr_descbus_E[DESCBUS_WIDTH-1:0]; 
   assign descbus['hF][DESCBUS_WIDTH-1:0] = fr_descbus_F[DESCBUS_WIDTH-1:0]; 

   assign descbus_len['h0] = fr_descbus_len_0; 
   assign descbus_len['h1] = fr_descbus_len_1; 
   assign descbus_len['h2] = fr_descbus_len_2; 
   assign descbus_len['h3] = fr_descbus_len_3; 
   assign descbus_len['h4] = fr_descbus_len_4; 
   assign descbus_len['h5] = fr_descbus_len_5; 
   assign descbus_len['h6] = fr_descbus_len_6; 
   assign descbus_len['h7] = fr_descbus_len_7; 
   assign descbus_len['h8] = fr_descbus_len_8; 
   assign descbus_len['h9] = fr_descbus_len_9; 
   assign descbus_len['hA] = fr_descbus_len_A; 
   assign descbus_len['hB] = fr_descbus_len_B; 
   assign descbus_len['hC] = fr_descbus_len_C; 
   assign descbus_len['hD] = fr_descbus_len_D; 
   assign descbus_len['hE] = fr_descbus_len_E; 
   assign descbus_len['hF] = fr_descbus_len_F; 

   assign descbus_dtoffset['h0] = fr_descbus_dtoffset_0; 
   assign descbus_dtoffset['h1] = fr_descbus_dtoffset_1; 
   assign descbus_dtoffset['h2] = fr_descbus_dtoffset_2; 
   assign descbus_dtoffset['h3] = fr_descbus_dtoffset_3; 
   assign descbus_dtoffset['h4] = fr_descbus_dtoffset_4; 
   assign descbus_dtoffset['h5] = fr_descbus_dtoffset_5; 
   assign descbus_dtoffset['h6] = fr_descbus_dtoffset_6; 
   assign descbus_dtoffset['h7] = fr_descbus_dtoffset_7; 
   assign descbus_dtoffset['h8] = fr_descbus_dtoffset_8; 
   assign descbus_dtoffset['h9] = fr_descbus_dtoffset_9; 
   assign descbus_dtoffset['hA] = fr_descbus_dtoffset_A; 
   assign descbus_dtoffset['hB] = fr_descbus_dtoffset_B; 
   assign descbus_dtoffset['hC] = fr_descbus_dtoffset_C; 
   assign descbus_dtoffset['hD] = fr_descbus_dtoffset_D; 
   assign descbus_dtoffset['hE] = fr_descbus_dtoffset_E; 
   assign descbus_dtoffset['hF] = fr_descbus_dtoffset_F; 

   assign data_offset_0 = data_offset['h0]; 
   assign data_offset_1 = data_offset['h1]; 
   assign data_offset_2 = data_offset['h2]; 
   assign data_offset_3 = data_offset['h3]; 
   assign data_offset_4 = data_offset['h4]; 
   assign data_offset_5 = data_offset['h5]; 
   assign data_offset_6 = data_offset['h6]; 
   assign data_offset_7 = data_offset['h7]; 
   assign data_offset_8 = data_offset['h8]; 
   assign data_offset_9 = data_offset['h9]; 
   assign data_offset_A = data_offset['hA]; 
   assign data_offset_B = data_offset['hB]; 
   assign data_offset_C = data_offset['hC]; 
   assign data_offset_D = data_offset['hD]; 
   assign data_offset_E = data_offset['hE]; 
   assign data_offset_F = data_offset['hF]; 

   //ORDER_fifo PUSH logic

   assign ORDER_wren = (ORDER_full==1'b0) ? fifo_wren : 'b0;

   assign ORDER_din = fifo_din;

   assign fifo_fill_level = ORDER_fifo_counter;
   assign fifo_free_level = (MAX_DESC-ORDER_fifo_counter);


   //ORDER_fifo instantiation

   // ORDER_fifo stores description index. 
   // The fifo can store upto MAX_DESC description indices.

   sync_fifo #(
               .WIDTH                                                        (DESC_IDX_WIDTH)
               ,.DEPTH                                                        (MAX_DESC)
	       ) ORDER_fifo (
			     .clk                                                          (clk)
			     ,.rst_n                                                        (resetn)
			     ,.dout                                                         (ORDER_dout)
			     ,.dout_pre                                                     (ORDER_dout_pre)
			     ,.dout_pre_valid                                               (ORDER_dout_pre_valid)
			     ,.full                                                         (ORDER_full)
			     ,.empty                                                        (ORDER_empty)
			     ,.wren                                                         (ORDER_wren)
			     ,.rden                                                         (ORDER_rden)
			     ,.din                                                          (ORDER_din)
			     ,.fifo_counter                                                 (ORDER_fifo_counter)         
			     );

   //////////////////////
   //USR-Channel
   //////////////////////

   //ORDER_fifo POP logic, IDX_fifo PUSH logic

   //Index is popped from AR_fifo.
   //The popped up index is pushed into IDX_fifo

   //ORDER_rden is one clock cycle pulse.



   generate

      if (ACE_CHANNEL=="MST_RD_REQ") begin
	 
	 for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_read_txn
	    assign read_txn[gi]  = { 
				     descbus[gi][(0) +: (AXBAR_WIDTH-1)]
				     , descbus[gi][(AXBAR_WIDTH) +: (AXDOMAIN_WIDTH)]
				     , descbus[gi][(AXDOMAIN_WIDTH+AXBAR_WIDTH) +: (ARSNOOP_WIDTH)]
				     };
	 end  

	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       ORDER_rden <= 1'b0;  
	       order_desc_idx <= 'b0;
	       rd_txn_valid <= 1'b0;  
	       rd_txn_size <= 'b0;
	       for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_data_offset
		  data_offset[i] <= 'b0;  
	       end
	    end else if (ORDER_rden==1'b1) begin   
	       ORDER_rden <= 1'b0;
	       order_desc_idx <= 'b0;
	       rd_txn_valid <= 1'b0;  
	       rd_txn_size <= 'b0;
	    end else if ( (rd_txn_valid==1'b1) && (rd_addr_alc_valid==1'b1) ) begin   
	       ORDER_rden <= 1'b1;
	       order_desc_idx <= ORDER_dout_pre;  
	       rd_txn_valid <= 1'b0;
	       rd_txn_size <= 'b0;
	       data_offset[ORDER_dout_pre] <= rd_addr_alc_offset;  
	    end else if (ORDER_dout_pre_valid==1'b1) begin   
	       ORDER_rden <= 1'b0;  
	       order_desc_idx <= 'b0;
	       rd_txn_valid <= 1'b1;
	       //If txn is of type - (AR, single R, RACK)
	       if (    (read_txn[ORDER_dout_pre] == `RD_TXN_CLEANUNIQUE_0  )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_CLEANUNIQUE_1  )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_MAKEUNIQUE_0   )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_MAKEUNIQUE_1   )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_CLEANSHARED_0  )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_CLEANSHARED_1  )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_CLEANSHARED_2  )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_CLEANINVALID_0 )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_CLEANINVALID_1 )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_CLEANINVALID_2 )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_MAKEINVALID_0  )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_MAKEINVALID_1  )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_MAKEINVALID_2  )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_BARRIER_0      )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_BARRIER_1      )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_BARRIER_2      )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_BARRIER_3      )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_DVMCOMP_0      )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_DVMCOMP_1      )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_DVMMSG_0       )
		       || (read_txn[ORDER_dout_pre] == `RD_TXN_DVMMSG_1       )
		       ) begin
		  rd_txn_size <= 8'b0;
	       end else begin
		  rd_txn_size <= descbus[ORDER_dout_pre][(DESCBUS_WIDTH-ID_WIDTH-ADDR_WIDTH-1) -: (8)];
	       end

	    end
	 end


	 synchronizer#(
		       .SYNC_FF                                                       (2)  
		       ,.D_WIDTH                                                       (1+DESC_IDX_WIDTH+DESC_IDX_WIDTH)
		       ) sync_wr_reqaw_fifo_din (
						 .ck                                                           (clk) 
						 ,.rn                                                           (resetn) 
						 ,.data_in                                                      ({rd_addr_alc_valid, ORDER_dout_pre, rd_addr_alc_node_idx}) 
						 ,.q_out                                                        ({rd_alc_valid, rd_alc_desc_idx, rd_alc_node_idx})
						 );   

	 assign rd_addr_avail = free_desc; 

	 ace_addr_allocator #(
			      .ADDR_WIDTH		                        (ADDR_WIDTH)
			      ,.DATA_WIDTH		                        (DATA_WIDTH)
			      ,.RAM_SIZE		                        (RAM_SIZE)
			      ,.MAX_DESC		                        (MAX_DESC)
			      ) i_ace_addr_allocator (
						      .addr_alc_valid	                        (rd_addr_alc_valid)
						      ,.addr_alc_offset                               (rd_addr_alc_offset)    
						      ,.addr_alc_node_idx                             (rd_addr_alc_node_idx) 

						      ,.clk	                                        (clk)
						      ,.resetn	                                (resetn)

						      ,.txn_valid	                                (rd_txn_valid)
						      ,.txn_size	                                (rd_txn_size)

						      ,.alc_valid                                     (rd_alc_valid)     
						      ,.alc_desc_idx                                  (rd_alc_desc_idx)       
						      ,.alc_node_idx                                  (rd_alc_node_idx)  
						      
						      ,.txn_cmpl	                                (rd_addr_avail)  
						      );

	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       hm2uc_done_retain <= 'b0;  
	    end
	 end

      end else begin

	 for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_read_txn_zero
	    assign read_txn[gi] = 'b0;
	 end  

	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       
	       ORDER_rden <= 1'b0;  
	       order_desc_idx <= 'b0;
	       hm2uc_done_retain <= 'b0;  
	       
	    end else if ( (int_mode_select_mode_0_1==1'b1) && (IS_MODE_1=="YES") ) begin
	       
	       if (ORDER_rden==1'b1) begin   
		  ORDER_rden <= 1'b0;
		  order_desc_idx <= 'b0;
		  for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_hm2uc_done_retain_A
		     if (hm2uc_done[i]==1'b1 && hm2uc_done_ff[i]==1'b0) begin //Positive edge detection
			hm2uc_done_retain[i] <= 1'b1;
		     end
		  end
	       end else if ( (ORDER_dout_pre_valid==1'b1) && (hm2uc_done_retain[ORDER_dout_pre]==1'b1) ) begin   
		  ORDER_rden <= 1'b1;
		  order_desc_idx <= ORDER_dout_pre;
		  for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_hm2uc_done_retain_B
		     if (i==ORDER_dout_pre) begin
			hm2uc_done_retain[i] <= 1'b0;
		     end else begin
			if (hm2uc_done[i]==1'b1 && hm2uc_done_ff[i]==1'b0) begin //Positive edge detection
			   hm2uc_done_retain[i] <= 1'b1;
			end
		     end
		  end
	       end else begin
		  ORDER_rden <= 1'b0;
		  order_desc_idx <= 'b0;
		  for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_hm2uc_done_retain_C
		     if (hm2uc_done[i]==1'b1 && hm2uc_done_ff[i]==1'b0) begin //Positive edge detection
			hm2uc_done_retain[i] <= 1'b1;
		     end
		  end

	       end

	    end else begin
	       
	       if (ORDER_rden==1'b1) begin   
		  ORDER_rden <= 1'b0;
		  order_desc_idx <= 'b0;
	       end else if (ORDER_dout_pre_valid==1'b1) begin   
		  ORDER_rden <= 1'b1;
		  order_desc_idx <= ORDER_dout_pre;
	       end
	       
	    end
	 end

	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       rd_txn_valid <= 1'b0;  
	       rd_txn_size <= 'b0;
	       for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_data_offset
		  data_offset[i] <= 'b0;  
	       end
	    end
	 end

	 assign {rd_alc_valid, rd_alc_desc_idx, rd_alc_node_idx} = 'b0;

	 assign rd_addr_avail = 'b0; 

	 assign rd_addr_alc_valid = 'b0;
	 assign rd_addr_alc_offset = 'b0;
	 assign rd_addr_alc_node_idx = 'b0;

      end
   endgenerate


   // If read issues to any of AR_fifo, fill IDX_fifo with index which popped
   // from that AR_fifo. 
   // NOTE : The implementation is such that at a time only one AR_fifo has AR_rden 
   // to be 'high'

   always @(posedge clk) begin
      
      IDX_wren <= ORDER_rden;
      // If read issues to the ORDER_fifo, fill IDX_fifo with index which popped
      // from the ORDER_fifo.                                        
      IDX_din  <= order_desc_idx;

   end

   //IDX_fifo instantiation

   // IDX_fifo stores the descriptor indices in such order that bridge
   // generates read responses towards DUT.

   sync_fifo #(
               .WIDTH		                                        (DESC_IDX_WIDTH) 
               ,.DEPTH		                                        (MAX_DESC)
	       ) IDX_fifo (
			   .dout	                                                        (IDX_dout)
			   ,.full	                                                        (IDX_full)
			   ,.empty	                                                (IDX_empty)
			   ,.clk	                                                        (clk)
			   ,.rst_n	                                                (resetn)
			   ,.wren	                                                        (IDX_wren)
			   ,.rden	                                                        (IDX_rden)
			   ,.din	                                                        (IDX_din)
			   );

   //IDX_fifo POP logic, USR_fifo PUSH logic

   //USR_wren is 3 clock cycle delayed value of uc2rb_rd_valid
   //USR_din is 3 clock cycle delayed value of usr_data_in (except data,strb of the channel, that is not delayed )

   generate

      if (IS_DATA=="YES") begin
	 assign USR_din[(USR_FIFO_DATA_MSB) -: (USR_FIFO_DATA_WIDTH)] = rb2uc_rd_data[(0) +: (USR_FIFO_DATA_WIDTH)];
      end

      if (ACE_CHANNEL=="MST_WR_REQ_W") begin
	 assign USR_din[(USR_FIFO_STRB_MSB) -: (USR_FIFO_STRB_WIDTH)] = (txn_type_wr_strb[(USR_din[DESC_IDX_WIDTH-1:0])]==1'b0) ? 
									({USR_FIFO_STRB_WIDTH{1'b1}})
           : (rb2uc_rd_wstrb[(0) +: (USR_FIFO_STRB_WIDTH)]);
      end

   endgenerate

   
   synchronizer#(
		 .SYNC_FF                                                       (3)  
		 ,.D_WIDTH                                                       (1)
		 ) sync_uc2rb_rd_valid (
					.ck                                                           (clk) 
					,.rn                                                           (resetn) 
					,.data_in                                                      (uc2rb_rd_valid) 
					,.q_out                                                        (USR_wren)
					);   

   synchronizer#(
		 .SYNC_FF                                                       (3)  
		 ,.D_WIDTH                                                       (XLAST_WIDTH)
		 ) sync_r_din_last (
				    .ck                                                           (clk) 
				    ,.rn                                                           (resetn) 
				    ,.data_in                                                      (usr_data_in[USR_FIFO_WIDTH-1])
				    ,.q_out                                                        (USR_din[USR_FIFO_WIDTH-1])
				    );   

   synchronizer#(
		 .SYNC_FF                                                       (3)  
		 ,.D_WIDTH                                                       (DESCBUS_WIDTH+DESC_IDX_WIDTH)
		 ) sync_r_din_misc (
				    .ck                                                           (clk) 
				    ,.rn                                                           (resetn) 
				    ,.data_in                                                      (usr_data_in[(0) +: (DESCBUS_WIDTH+DESC_IDX_WIDTH)]) 
				    ,.q_out                                                        (USR_din[(0) +: (DESCBUS_WIDTH+DESC_IDX_WIDTH)])
				    );


   assign uc2rb_addr     = (IS_DATA=="YES") ? uc2rb_rd_addr : 'b0;

   assign rb2uc_rd_data  = rb2uc_data;
   assign rb2uc_rd_wstrb = rb2uc_wstrb;

   // IDX_rden is one clock cycle pulse. 

   // Below state machine pops one descriptor index from IDX_fifo and read all
   // data from RDATA_RAM for that descriptor and stores into USR_fifo. Then, it
   // returns to idle state again.

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 data_state     <= DATA_IDLE;
	 IDX_rden         <= 1'b0;
	 uc2rb_rd_valid    <= 1'b0;
	 uc2rb_rd_addr     <= 'b0;
	 usr_data_in             <= 'b0;

      end else begin
	 case(data_state)
	   
	   DATA_IDLE: begin
	      usr_data_in               <= 'b0;
	      //If IDX_fifo is non-empty
	      if (IDX_empty==1'b0) begin   
		 data_state     <= DATA_NEW;
		 IDX_rden         <= 1'b1;
		 uc2rb_rd_valid    <= 1'b0;
		 uc2rb_rd_addr     <= 'b0;
		 //Wait till IDX_fifo gets any element
	      end else begin
		 data_state     <= DATA_IDLE;
		 IDX_rden         <= 1'b0;
		 uc2rb_rd_valid    <= 1'b0;
		 uc2rb_rd_addr     <= 'b0;
	      end  
	      
	   end DATA_NEW: begin
	      //If USR_fifo is not almost full 
	      if (USR_almost_full==1'b0) begin
		 data_state     <= DATA_NEW_XXRAM;
		 IDX_rden         <= 1'b0;
		 uc2rb_rd_valid    <= 1'b0;
		 uc2rb_rd_addr     <= 'b0;
	      end else begin
		 data_state     <= DATA_NEW;
		 IDX_rden         <= 1'b0;
		 uc2rb_rd_valid    <= 1'b0;
		 uc2rb_rd_addr     <= 'b0;
	      end
	      
	      //Read data of new descriptor's first transfer from internal RDATA_RAM
	   end DATA_NEW_XXRAM: begin
	      uc2rb_rd_valid    <= 1'b1;
	      uc2rb_rd_addr     <= descbus_dtoffset[IDX_dout];
	      xx_offset         <= (descbus_dtoffset[IDX_dout]+1);  //Next uc2rb_rd_addr of same descriptor
	      data_count       <= 'b0;   //initialize transfer count of a descriptor
	      axlen             <= descbus_len[IDX_dout];
	      op_idx            <= IDX_dout;
	      
	      usr_data_in[USR_FIFO_WIDTH-1] <= (descbus_len[IDX_dout] == 1'b0); //last
	      //all other sidebands except data,strb   
	      usr_data_in[(DESC_IDX_WIDTH) +: (DESCBUS_WIDTH)] <= descbus[IDX_dout][DESCBUS_WIDTH-1:0];
	      usr_data_in[DESC_IDX_WIDTH-1:0] <= IDX_dout;  //usr_idx 

	      //If axlen is 0, no need to read further from RDATA_RAM 
	      if (descbus_len[IDX_dout]=='b0) begin //axlen=='b0
		 data_state <= DATA_IDLE;
		 IDX_rden <= 1'b0;
		 //If USR_fifo is not almost full 
	      end else if (USR_almost_full==1'b0) begin  
		 data_state <= DATA_CON_XXRAM;
		 IDX_rden <= 1'b0;
	      end else begin
		 data_state <= DATA_CON_WAIT;
		 IDX_rden <= 1'b0;
	      end

	   end DATA_CON_XXRAM: begin
	      uc2rb_rd_valid    <= 1'b1;
	      uc2rb_rd_addr     <= xx_offset;
	      xx_offset         <= xx_offset+1;    
	      data_count       <= data_count+1'b1;  //Calculate transfer count of a descriptor

	      usr_data_in[USR_FIFO_WIDTH-1] <= (data_count == (axlen-1)); //last
	      //all other sidebands except data,strb  
	      usr_data_in[(DESC_IDX_WIDTH) +: DESCBUS_WIDTH] <= descbus[op_idx][DESCBUS_WIDTH-1:0];
	      usr_data_in[DESC_IDX_WIDTH-1:0] <= op_idx;  //usr_idx 

	      if (data_count == (axlen-1)) begin //last reached 
		 data_state <= DATA_IDLE;
	      end else if (USR_almost_full==1'b0) begin  
		 data_state <= DATA_CON_XXRAM;
	      end else begin
		 data_state <= DATA_CON_WAIT;
	      end
	      IDX_rden <= 1'b0;
	      
	   end DATA_CON_WAIT: begin
	      //If USR_fifo is not almost full 
	      if (USR_almost_full==1'b0) begin  
		 data_state <= DATA_CON_XXRAM;
	      end else begin
		 data_state <= DATA_CON_WAIT;
	      end
	      IDX_rden         <= 1'b0;
	      uc2rb_rd_valid    <= 1'b0;
	      uc2rb_rd_addr     <= uc2rb_rd_addr;
	      
	   end default: begin
	      data_state     <= data_state;
	      IDX_rden         <= 1'b0;
	      uc2rb_rd_valid    <= 1'b0;
	      uc2rb_rd_addr     <= 'b0;
	   end
	   
	 endcase
      end
   end
   
   //USR_fifo instantiation

   // USR_fifo holds rdata along with all ace-channel sideband signals. 

   sync_fifo #(
               //Ref:  .WIDTH		                                ((XLAST_WIDTH+INFBUS_WIDTH+DESC_IDX_WIDTH))
               //                                                            XLAST,DATA(if any),DESCBUS,DESC_IDX
               .WIDTH		                                        (USR_FIFO_WIDTH)  
               ,.DEPTH		                                        (USR_FIFO_DEPTH)        //Any random number
               ,.ALMOST_FULL_DEPTH		                                (USR_FIFO_DEPTH-4)      //DEPTH-4           
               ,.ALMOST_EMPTY_DEPTH		                                (2)         //Not used
	       ) USR_fifo (
			   .dout	                                                        (USR_dout)
			   ,.full	                                                        (USR_full)
			   ,.empty	                                                (USR_empty)
			   ,.almost_full	                                                (USR_almost_full)
			   ,.almost_empty	                                                (USR_almost_empty)
			   ,.clk	                                                        (clk)
			   ,.rst_n	                                                (resetn)
			   ,.wren	                                                        (USR_wren)
			   ,.rden	                                                        (USR_rden)
			   ,.din	                                                        (USR_din)
			   );

   //ACE-Channel : AXI and control signal (usr_idx, op_done) generation.

   // Signals of ace-channel and usr_idx are read out values from USR_fifo.

   assign infbus_last = USR_dout[USR_FIFO_WIDTH-1];     //last

   assign infbus[(0) +: (INFBUS_WIDTH)] = USR_dout[(DESC_IDX_WIDTH) +: (INFBUS_WIDTH)];  

   assign usr_idx = USR_dout[DESC_IDX_WIDTH-1:0];  //descriptor index                  	



   assign infbus_desc_idx = usr_idx;                   	

   // op_done is one clock cycle pulse.
   // It indicates that read response is accepted by DUT.

   generate
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_op_done
	 
	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       op_done[gi] <= 1'b0;
	       //If valid and ready and last are 'high'
	    end else if (infbus_valid==1'b1 && infbus_ready==1'b1 && infbus_last==1'b1 && usr_idx==gi) begin
	       op_done[gi] <= 1'b1;
	    end else begin
	       op_done[gi] <= 1'b0;
	    end
	 end
	 
      end
   endgenerate

   // valid becomes 'high' when a read issues to USR_fifo. It remains
   // 'high' till ready is detected as logic 'high' .

   always @(posedge clk) begin
      
      if (resetn == 1'b0) begin
	 infbus_valid <= 1'b0;
	 //If valid and ready are 'high'
      end else if (infbus_valid==1'b1 && infbus_ready==1'b1) begin
	 infbus_valid <= 1'b0;  //valid becomes 'low'
	 //If read issues to USR_fifo
      end else if (USR_rden==1'b1) begin
	 infbus_valid <= 1'b1;  //valid becomes 'high'
      end else begin
	 infbus_valid <= infbus_valid;  //valid retains its value
      end

   end      

   //USR_fifo POP logic

   // USR_rden is one clock cycle pulse.


   always @(posedge clk) begin 
      if (resetn == 1'b0) begin
	 op_state <= OP_IDLE;
	 USR_rden        <= 1'b0;
      end else begin 
	 case(op_state)

	   OP_IDLE: begin
	      //If USR_fifo is not empty
	      if (USR_empty == 1'b0) begin
		 op_state <= OP_STRT;
		 USR_rden        <= 1'b1;    //issue read to USR_fifo
		 //Wait till USR_fifo gets any element
	      end else begin
		 op_state <= OP_IDLE;
		 USR_rden        <= 1'b0;    //USR_rden becomes 'low' as it is one clock cycle pulse
	      end
	      
	   end OP_STRT: begin
	      op_state <= OP_WAIT;  
	      USR_rden        <= 1'b0;  // USR_rden becomes 'low' as it is one clock cycle pulse
	      
	   end OP_WAIT: begin

	      //If valid and ready are 'high'
	      if (infbus_valid==1'b1 && infbus_ready==1'b1) begin
		 
		 //If USR_fifo is not empty
		 if (USR_empty == 1'b0) begin
		    op_state <= OP_STRT;
		    USR_rden        <= 1'b1;  //issue a new read to USR_fifo
		    //wait till USR_fifo gets any element
		 end else begin
		    op_state <= OP_IDLE;
		    USR_rden        <= 1'b0;
		 end
		 
		 // Wait till ready is detected as 'high'
	      end else begin
		 op_state <= OP_WAIT;
		 USR_rden        <= 1'b0;
	      end
	      
	   end default: begin
	      op_state <= op_state;
	      USR_rden        <= 1'b0;
	      
	   end  
	 endcase
      end
   end 


   //XACK_fifo PUSH logic

   //Generate XACK_wren,XACK_din

   assign XACK_din = usr_idx;

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 XACK_wren <= 1'b0;
	 //If valid and ready are 'high'
      end else if (infbus_valid==1'b1 && infbus_ready==1'b1 && infbus_last==1'b1) begin
	 XACK_wren <= 1'b1;
      end else begin
	 XACK_wren <= 1'b0;
      end
   end

   //XACK_fifo instantiation

   // XACK_fifo holds descriptor index for which read/write response is accepted by DUT
   

   sync_fifo #(
               .WIDTH                                                        (DESC_IDX_WIDTH)  
               ,.DEPTH                                                        (MAX_DESC) 
               ,.ALMOST_FULL_DEPTH                                            (MAX_DESC-2)      // Not used          
               ,.ALMOST_EMPTY_DEPTH                                           (2)         // Not used
	       ) XACK_fifo (
			    .clk                                                          (clk)
			    ,.rst_n                                                        (resetn)
			    ,.dout                                                         (XACK_dout)
			    ,.full                                                         (XACK_full)
			    ,.empty                                                        (XACK_empty)
			    ,.almost_full                                                  (XACK_almost_full)
			    ,.almost_empty                                                 (XACK_almost_empty)
			    ,.wren                                                         (XACK_wren)
			    ,.rden                                                         (XACK_rden)
			    ,.din                                                          (XACK_din)
			    );

   //XACK_fifo POP logic

   // XACK_rden is one clock cycle pulse.

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 xack_cntr <= 'b0;
	 XACK_rden <= 1'b0;
	 //If xack
      end else if (inf_xack==1'b1) begin
	 xack_cntr <= xack_cntr + 1'b1;
	 XACK_rden <= 1'b0;
	 //If xack_rden is "high"
      end else if ( (XACK_rden==1'b1) ) begin 
	 xack_cntr <= xack_cntr;
	 XACK_rden <= 1'b0;
	 //If at least one xack has arrived and XACK_fifo is not empty
      end else if ( (|xack_cntr)==1'b1 && (XACK_empty==1'b0) ) begin 
	 xack_cntr <= xack_cntr - 1'b1;
	 XACK_rden <= 1'b1;
      end else begin
	 xack_cntr <= xack_cntr;
	 XACK_rden <= 1'b0;
      end
   end

   // xack_done is one clock cycle pulse.
   // It indicates that DUT has given read acknowledgement 
   // for the descriptor

   always @(posedge clk) begin
      if (resetn==0) begin
	 XACK_rden_ff <= 'h0;
      end else begin
	 XACK_rden_ff <= XACK_rden;
      end
   end

   generate
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_xack_done
	 
	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       xack_done[gi] <= 1'b0;
	       //If output from XACK_fifo
	    end else if (XACK_rden_ff==1'b1 && XACK_dout==gi) begin
	       xack_done[gi] <= 1'b1;
	    end else begin
	       xack_done[gi] <= 1'b0;
	    end
	 end
	 

      end
   endgenerate



   //////////////////////
   //Signal :
   //  txn_cmpl
   //  comp
   //Description :
   //  Transaction completion indication from bridge to SW.
   //////////////////////

   generate

      `IF_INTFS_FULLACE

	if (IS_XACK=="YES") begin
	   assign txn_cmpl = (xack_done);

	end else begin  
	   assign txn_cmpl = (op_done);

	end

      `END_INTFS

	`IF_INTFS_LITEACE
	  assign txn_cmpl = (op_done); 
      `END_INTFS

	endgenerate

   assign comp = txn_cmpl;


   ///////////////////////
   //Signal :
   //  intr_comp_status_comp
   //Description:
   //  Update intr_comp_status_comp based on comp(from bridge) or intr_comp_clear_clr_comp(from sw)
   //////////////////////

   always @(posedge clk) begin
      if (resetn==0) begin
	 intr_comp_clear_clr_comp_ff <= 'h0;
      end else begin
	 intr_comp_clear_clr_comp_ff <= intr_comp_clear_clr_comp;
      end
   end        		
   always @(posedge clk) begin
      if (resetn==0) begin
	 comp_ff <= 'h0;
      end else begin
	 comp_ff <= comp;
      end
   end
   generate        		
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_intr_comp_status_comp
	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       intr_comp_status_comp[gi] <= 1'b0;  
	    end else if (comp[gi]==1'b1 && comp_ff[gi]==1'b0) begin //Positive edge detection
	       intr_comp_status_comp[gi] <= 1'b1;
	    end else if (intr_comp_clear_clr_comp[gi]==1'b1 && intr_comp_clear_clr_comp_ff[gi]==1'b0) begin //Positive edge detection
	       intr_comp_status_comp[gi] <= 1'b0;
	    end
	 end
      end
   endgenerate

   //////////////////////
   //Signal :
   //  uc2hm_trig
   //Description :
   //  Trigger HM to send/fetch data to/from SW based on write/read transaction
   //  correspondingly.
   //////////////////////

   //sig_mode_select_imm_bresp
   //0 : Wait for response from Host.
   //1 : Generate immediate BRESP to DUT

   //Update uc2hm_trig
   always @(posedge clk) begin
      
      if (resetn == 1'b0) begin
	 uc2hm_trig <= 'b0;
	 
	 //If mode-1
      end else if ( (int_mode_select_mode_0_1==1'b1) && (IS_MODE_1=="YES") ) begin 
	 
	 //Upon writing descriptor to ORDER_fifo 
	 //if (ORDER_rden==1'b1) begin  
	 if (ORDER_wren==1'b1) begin  
	    //uc2hm_trig[order_desc_idx] <= 'b1; 
	    uc2hm_trig[ORDER_din] <= 'b1; 
	 end else begin 
	    uc2hm_trig <= 'b0; 
	 end   

      end

   end

   //////////////////////
   //Signal :
   //  hm2uc_done_pulse
   //Description: 
   //  Detect positive edge of hm2uc_done and generate 1-cycle pusle as hm2uc_done_pulse
   //////////////////////

   always @(posedge clk) begin
      if (resetn==0) begin
	 hm2uc_done_ff <= 'h0;
      end else begin
	 hm2uc_done_ff <= hm2uc_done;
      end
   end
   generate                        
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_hm2uc_done_pulse
	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       hm2uc_done_pulse[gi] <= 1'b0;  
	    end else if (hm2uc_done[gi]==1'b1 && hm2uc_done_ff[gi]==1'b0) begin //Positive edge detection
	       hm2uc_done_pulse[gi] <= 1'b1;
	    end else begin
	       hm2uc_done_pulse[gi] <= 1'b0;
	    end
	 end
      end
   endgenerate




endmodule        

// Local Variables:
// verilog-library-directories:("./")
// End:
