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

module ace_ctrl_ready #(

			parameter ACE_PROTOCOL                                         = "FULLACE"
			
			//Allowed Values : 
			//  "SLV_RD_REQ",  "SLV_SN_RESP",  "MST_WR_RESP",  "MST_SN_REQ",
			//  "SLV_SN_DATA",
			//  "SLV_WR_REQ",  
			,parameter ACE_CHANNEL                                          = "SLV_RD_REQ" 
			
			,parameter ADDR_WIDTH                                           = 64 
			,parameter DATA_WIDTH                                           = 128       
			
			,parameter ID_WIDTH                                             = 16        
			,parameter AWUSER_WIDTH                                         = 32        
			,parameter WUSER_WIDTH                                          = 32        
			,parameter BUSER_WIDTH                                          = 32        
			,parameter ARUSER_WIDTH                                         = 32        
			,parameter RUSER_WIDTH                                          = 32        
			
			,parameter INFBUS_WIDTH                                         = 200
			,parameter TR_DESCBUS_WIDTH                                     = 200    
			
			,parameter AW_INFBUS_WIDTH                                      = 150    
			,parameter AW_TR_DESCBUS_WIDTH                                  = 150    
			
			,parameter CACHE_LINE_SIZE                                      = 64 
			,parameter MAX_DESC                                             = 16         
			,parameter RAM_SIZE                                             = 16384     
			
			)(
			  
			  //Clock and reset
			  input clk 
			  ,input resetn
   
			  //s_ace_usr or m_ace_usr signals
			  ,input [INFBUS_WIDTH-1:0] infbus 
			  ,input infbus_last //Strictly drive '1' for "SLV_RD_REQ",  "SLV_SN_RESP",  "MST_WR_RESP",  "MST_SN_REQ"   
			  ,input infbus_valid 
			  ,output reg infbus_ready 
			  ,output reg inf_xack 
   
			  //s_ace_usr_aw signals  
			  //Applicable in case of slv-write case only. Drive aw_infbus_valid to '0' in all other cases.
			  ,input [AW_INFBUS_WIDTH-1:0] aw_infbus 
			  ,input [7:0] aw_infbus_len
			  ,input [ID_WIDTH-1:0] aw_infbus_id
			  ,input aw_infbus_valid 
			  ,output reg aw_infbus_ready 
   
			  ,output reg [MAX_DESC-1:0] txn_type_wr_strb
   
			  //error signals
			  ,output reg error_status
			  ,input error_clear
   
			  //Descriptor signals
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_0 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_1 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_2 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_3 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_4 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_5 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_6 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_7 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_8 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_9 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_A 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_B 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_C 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_D 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_E 
			  ,output [TR_DESCBUS_WIDTH-1:0] tr_descbus_F 
   
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_0 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_1 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_2 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_3 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_4 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_5 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_6 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_7 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_8 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_9 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_A 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_B 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_C 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_D 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_E 
			  ,output [AW_TR_DESCBUS_WIDTH-1:0] aw_tr_descbus_F 
   
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_0
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_1
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_2
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_3
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_4
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_5
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_6
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_7
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_8
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_9
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_A
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_B
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_C
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_D
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_E
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] tr_descbus_dtoffset_F
   
   
			  //Mode selection
			  ,input int_mode_select_mode_0_1
   
			  //Registers
			  ,input [MAX_DESC-1:0] desc_avail
			  ,input fifo_rden //should be one clock cycle pulse
			  ,output [(`CLOG2(MAX_DESC))-1:0] fifo_dout
			  ,output fifo_dout_valid //it is one clock cycle pulse
			  ,output [(`CLOG2(MAX_DESC)):0] fifo_fill_level
			  ,output [(`CLOG2(MAX_DESC)):0] fifo_free_level
   
			  //DATA_RAM and WSTRB_RAM                               
			  ,output reg uc2rb_we 
			  ,output [(DATA_WIDTH/8)-1:0] uc2rb_bwe //Generate all 1s always.     
			  ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] uc2rb_addr 
			  ,output reg [DATA_WIDTH-1:0] uc2rb_data 
			  ,output reg [(DATA_WIDTH/8)-1:0] uc2rb_wstrb
   
			  //Mode-1 signals
			  ,output reg [MAX_DESC-1:0] uc2hm_trig 
			  ,input [MAX_DESC-1:0] hm2uc_done

			  );

   localparam BRIDGE_TYPE                                                  = 
									     ( (ACE_CHANNEL=="MST_WR_RESP") || (ACE_CHANNEL=="MST_SN_REQ") ) ?
                                                                             "MST_BRIDGE"
   : "SLV_BRIDGE" ;

   localparam CHANNEL_TYPE                                                 = 
									     ( (ACE_CHANNEL=="SLV_SN_RESP") || (ACE_CHANNEL=="SLV_SN_DATA") || (ACE_CHANNEL=="MST_SN_REQ") ) ?
									     "SN"
   : ( ( (ACE_CHANNEL=="SLV_RD_REQ") ) ? "RD" : "WR") ;

   localparam IS_DATA                                                   = 
									  ( (ACE_CHANNEL=="SLV_WR_REQ") || (ACE_CHANNEL=="SLV_SN_DATA") ) ?
                                                                          "YES"
   : "NO" ;

   localparam IS_MODE_1                                                   = 
									    ( (ACE_CHANNEL=="SLV_WR_REQ") ) ?
                                                                            "YES"
   : "NO" ;

   localparam IS_XACK                                                   = 
									  ( (ACE_CHANNEL=="MST_WR_RESP") ) ?
                                                                          "YES"
   : "NO" ;

   localparam DESC_IDX_WIDTH                                               = `CLOG2(MAX_DESC);
   localparam RAM_OFFSET_WIDTH                                             = `CLOG2((RAM_SIZE*8)/DATA_WIDTH);

   localparam DESCBUS_WIDTH                                                = TR_DESCBUS_WIDTH;

   localparam AW_DESCBUS_WIDTH                                             = AW_TR_DESCBUS_WIDTH;

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
   localparam VEC_0                                                       = 16'h0001; 
   localparam VEC_1                                                       = 16'h0002; 
   localparam VEC_2                                                       = 16'h0004; 
   localparam VEC_3                                                       = 16'h0008; 
   localparam VEC_4                                                       = 16'h0010; 
   localparam VEC_5                                                       = 16'h0020; 
   localparam VEC_6                                                       = 16'h0040; 
   localparam VEC_7                                                       = 16'h0080; 
   localparam VEC_8                                                       = 16'h0100; 
   localparam VEC_9                                                       = 16'h0200; 
   localparam VEC_A                                                       = 16'h0400; 
   localparam VEC_B                                                       = 16'h0800; 
   localparam VEC_C                                                       = 16'h1000; 
   localparam VEC_D                                                       = 16'h2000; 
   localparam VEC_E                                                       = 16'h4000; 
   localparam VEC_F                                                       = 16'h8000; 

   localparam WR_INF_IDLE                                                  = 2'b00;                        
   localparam WR_INF_WAIT_ALC                                              = 2'b01;                           
   localparam WR_INF_FILL_AWFIFO                                           = 2'b10;                            
   localparam WR_INF_TXN_DONE                                              = 2'b11;                           

   localparam USR_IDLE                                                     = 4'b0000;
   localparam USR_NO_W_TXN                                                 = 4'b0001;
   localparam USR_NO_W_WAIT                                                = 4'b0010;
   localparam USR_NEW_TXN                                                  = 4'b0011;
   localparam USR_ALC_WAIT                                                 = 4'b0100;
   localparam USR_ALC_TXN                                                  = 4'b0101;
   localparam USR_NEW_WAIT                                                 = 4'b0110;
   localparam USR_CON_TXN                                                  = 4'b0111;
   localparam USR_CON_WAIT                                                 = 4'b1000; 
   localparam USR_WAIT_WDATA                                               = 4'b1001;

   localparam WSTRB_WIDTH                                                  = (DATA_WIDTH/8);
   localparam XLAST_WIDTH                                                  = 1;            //last/rlast width

   localparam BRESP_WIDTH                                                  = 2;            //bresp width
   localparam RRESP_WIDTH                                                  = (ACE_PROTOCOL=="FULLACE") ? (4) :
                                                                             (2) ;            //rresp width
   localparam CRRESP_WIDTH                                                 = 5;


   localparam USR_FIFO_WIDTH                                               = (XLAST_WIDTH+INFBUS_WIDTH);

   localparam USR_FIFO_LAST                                                = (USR_FIFO_WIDTH-1);

   localparam USR_FIFO_WDATA_MSB                                           = (IS_DATA=="YES") ? 
                                                                             (USR_FIFO_WIDTH-XLAST_WIDTH-1)
     : ('b0);
   localparam USR_FIFO_WDATA_WIDTH                                         = (IS_DATA=="YES") ? 
                                                                             (DATA_WIDTH)
     : ('b0);
   localparam USR_FIFO_WDATA_LSB                                           = (IS_DATA=="YES") ? 
                                                                             (USR_FIFO_WIDTH-XLAST_WIDTH-DATA_WIDTH)
     : ('b0);

   localparam USR_FIFO_WSTRB_MSB                                           = (ACE_CHANNEL=="SLV_WR_REQ") ? 
                                                                             (USR_FIFO_WIDTH-XLAST_WIDTH-DATA_WIDTH-1)
     : ('b0);
   localparam USR_FIFO_WSTRB_WIDTH                                         = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (DATA_WIDTH/8)
     : ('b0);
   localparam USR_FIFO_WSTRB_LSB                                           = (ACE_CHANNEL=="SLV_WR_REQ") ? 
                                                                             (USR_FIFO_WIDTH-XLAST_WIDTH-DATA_WIDTH-WSTRB_WIDTH)
     : ('b0);

   localparam AW_DESCBUS_AWLEN_MSB                                         = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AW_DESCBUS_WIDTH-ID_WIDTH-ADDR_WIDTH-1)
     : ('b0);

   localparam AW_DESCBUS_AWLEN_WIDTH                                       = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AXLEN_WIDTH)
     : ('b0);

   localparam AW_DESCBUS_AWLEN_LSB                                         = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AW_DESCBUS_WIDTH-ID_WIDTH-ADDR_WIDTH-AXLEN_WIDTH)
     : ('b0);


   localparam WRITE_TXN_WIDTH                                              = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AXBAR_WIDTH-1+AXDOMAIN_WIDTH+AWSNOOP_WIDTH)
     : ('h3);



   localparam AW_DESCBUS_AXBAR_MSB                                         = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AXBAR_WIDTH-1+AWUNIQUE_WIDTH-1)
     : ('b0);

   localparam AW_DESCBUS_AXBAR_WIDTH                                       = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AXBAR_WIDTH)
     : ('b0);

   localparam AW_DESCBUS_AXBAR_LSB                                         = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AWUNIQUE_WIDTH)
     : ('b0);







   localparam AW_DESCBUS_AXDOMAIN_MSB                                      = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AXDOMAIN_WIDTH+AXBAR_WIDTH+AWUNIQUE_WIDTH-1)
     : ('b0);

   localparam AW_DESCBUS_AXDOMAIN_WIDTH                                    = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AXDOMAIN_WIDTH)
     : ('b0);

   localparam AW_DESCBUS_AXDOMAIN_LSB                                      = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AXBAR_WIDTH+AWUNIQUE_WIDTH)
     : ('b0);

   localparam AW_DESCBUS_AWSNOOP_MSB                                       = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AWSNOOP_WIDTH+AXDOMAIN_WIDTH+AXBAR_WIDTH+AWUNIQUE_WIDTH-1)
     : ('b0);

   localparam AW_DESCBUS_AWSNOOP_WIDTH                                     = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AWSNOOP_WIDTH)
     : ('b0);

   localparam AW_DESCBUS_AWSNOOP_LSB                                       = (ACE_CHANNEL=="SLV_WR_REQ") ?
                                                                             (AXDOMAIN_WIDTH+AXBAR_WIDTH+AWUNIQUE_WIDTH)
     : ('b0);


   //Loop variables
   integer 			i;
   integer 			j;
   integer 			k;

   //generate variable
   genvar 			gi;

   wire 			error_ctl;

   reg 				error_ctl_hw;
   reg 				error_ctl_hw_ff;

   reg 				error_clear_ff;

   reg [DESCBUS_WIDTH-1:0] 	descbus[MAX_DESC-1:0] ; 

   reg [AW_DESCBUS_WIDTH-1:0] 	aw_descbus[MAX_DESC-1:0] ; 

   wire 			sig_mode_select_imm_bresp;

   wire 			txn_valid;
   wire [7:0] 			txn_size; //AXLEN (Request is (AXLEN+1))
   wire 			alc_valid;
   wire [RAM_OFFSET_WIDTH-1:0] 	alc_offset; //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [10:0]
   wire [DESC_IDX_WIDTH-1:0] 	alc_idx; //For MAX_DESC=16, it is [3:0] 

   //Common signals for any channel. xx can be wr, rd, sn.
   reg 				xx_txn_valid;
   reg [7:0] 			xx_txn_size; //AXLEN (Request is (AXLEN+1))
   wire 			xx_alc_valid;
   wire [RAM_OFFSET_WIDTH-1:0] 	xx_alc_offset; //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [10:0]
   wire [DESC_IDX_WIDTH-1:0] 	xx_alc_idx;         //For MAX_DESC=16, it is [3:0] 
   reg [RAM_OFFSET_WIDTH-1:0] 	xx_offset; //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [10:0]
   reg [DESC_IDX_WIDTH-1:0] 	xx_idx; //For MAX_DESC=16, it is [3:0] 

   reg [1:0] 			wr_inf_state;
   wire [DESC_IDX_WIDTH-1:0] 	AW_dout [MAX_DESC-1 : 0];
   wire [DESC_IDX_WIDTH-1:0] 	AW_dout_pre [MAX_DESC-1 : 0];
   wire [MAX_DESC-1 : 0] 	AW_dout_pre_valid;
   wire [MAX_DESC-1 : 0] 	AW_full;
   wire [MAX_DESC-1 : 0] 	AW_empty;
   reg [MAX_DESC-1 : 0] 	AW_wren;
   wire [MAX_DESC-1 : 0] 	AW_rden;
   reg [DESC_IDX_WIDTH-1:0] 	AW_din [MAX_DESC-1 : 0];
   reg [MAX_DESC-1 : 0] 	awid_matched;
   reg [MAX_DESC-1 : 0] 	AW_fifo_new;
   wire [MAX_DESC-1 : 0] 	AW_fifo_valid;
   reg [ID_WIDTH-1:0] 		AW_fifo_awid[MAX_DESC-1 : 0];

   wire [WRITE_TXN_WIDTH-1:0] 	write_txn;
   wire [WRITE_TXN_WIDTH-1:0] 	write_txn_updated[MAX_DESC-1 : 0];

   reg 				wr_txn_valid;
   reg 				wr_txn_valid_ff;
   reg [7:0] 			wr_txn_size; //AXLEN (Request is (AXLEN+1))
   wire 			wr_alc_valid;
   reg 				wr_alc_valid_ff;
   wire [RAM_OFFSET_WIDTH-1:0] 	wr_alc_offset; //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [10:0]
   wire [DESC_IDX_WIDTH-1:0] 	wr_alc_idx; //For MAX_DESC=16, it is [3:0] 
   reg [DESC_IDX_WIDTH-1:0] 	wr_alc_idx_ff; //For MAX_DESC=16, it is [3:0] 

   reg [RAM_OFFSET_WIDTH-1:0] 	wr_desc_offset [MAX_DESC-1:0];
   reg [RAM_OFFSET_WIDTH-1:0] 	wr_fifo_pop_offset[MAX_DESC-1:0];
   reg [DESC_IDX_WIDTH-1:0] 	wr_fifo_pop_idx;

   wire [DESC_IDX_WIDTH-1:0] 	AW_W_dout;
   wire [DESC_IDX_WIDTH-1:0] 	AW_W_dout_pre;
   wire 			AW_W_dout_pre_valid;
   wire 			AW_W_full;
   wire 			AW_W_empty;
   wire 			AW_W_wren;
   reg 				AW_W_rden;
   wire [DESC_IDX_WIDTH-1:0] 	AW_W_din;

   wire 			USR_full;
   wire 			USR_empty;
   wire 			USR_almost_full;
   wire 			USR_almost_empty;
   reg 				USR_wren;
   reg 				USR_rden;
   reg [USR_FIFO_WIDTH-1:0] 	USR_din; 
   wire [USR_FIFO_WIDTH-1:0] 	USR_dout; 

   reg 				last;
   reg [7:0] 			last_cntr;
   reg [7:0] 			usrlen_sig;
   reg [MAX_DESC-1:0] 		error_wr_wlast;  
   reg [MAX_DESC-1:0] 		error_wr_wlast_ff;  
   reg [MAX_DESC-1:0] 		req_avail;
   reg [DESC_IDX_WIDTH-1:0] 	wr_alc_idx_current;
   reg [3:0] 			usr_state;
   
   reg 				USR_rden_ff;              


   wire [DESC_IDX_WIDTH-1:0] 	ORDER_dout;
   wire [DESC_IDX_WIDTH-1:0] 	ORDER_dout_pre;
   wire 			ORDER_dout_pre_valid;
   wire 			ORDER_full;
   wire 			ORDER_empty;
   reg 				ORDER_wren;
   wire 			ORDER_rden;
   reg [DESC_IDX_WIDTH-1:0] 	ORDER_din;
   wire [DESC_IDX_WIDTH:0] 	ORDER_fifo_counter;
   
   reg 				ORDER_rden_ff;

   wire [MAX_DESC-1:0] 		txn_avail;
   reg [MAX_DESC-1:0] 		xack_done; 
   wire [MAX_DESC-1:0] 		hm2uc_bresp_done;
   reg [MAX_DESC-1:0] 		hm2uc_done_pulse;
   reg [MAX_DESC-1:0] 		hm2uc_done_ff;

   ///////////////////////
   //Description: 
   //  Tie imm_bresp mode to 0.
   //////////////////////
   assign sig_mode_select_imm_bresp = 1'b0;

   //1D to 2D conversion

   assign tr_descbus_0 = descbus['h0][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_1 = descbus['h1][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_2 = descbus['h2][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_3 = descbus['h3][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_4 = descbus['h4][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_5 = descbus['h5][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_6 = descbus['h6][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_7 = descbus['h7][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_8 = descbus['h8][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_9 = descbus['h9][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_A = descbus['hA][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_B = descbus['hB][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_C = descbus['hC][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_D = descbus['hD][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_E = descbus['hE][DESCBUS_WIDTH-1:0]; 
   assign tr_descbus_F = descbus['hF][DESCBUS_WIDTH-1:0]; 


   assign aw_tr_descbus_0 = aw_descbus['h0][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_1 = aw_descbus['h1][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_2 = aw_descbus['h2][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_3 = aw_descbus['h3][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_4 = aw_descbus['h4][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_5 = aw_descbus['h5][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_6 = aw_descbus['h6][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_7 = aw_descbus['h7][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_8 = aw_descbus['h8][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_9 = aw_descbus['h9][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_A = aw_descbus['hA][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_B = aw_descbus['hB][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_C = aw_descbus['hC][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_D = aw_descbus['hD][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_E = aw_descbus['hE][AW_DESCBUS_WIDTH-1:0]; 
   assign aw_tr_descbus_F = aw_descbus['hF][AW_DESCBUS_WIDTH-1:0]; 

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 tr_descbus_dtoffset_0 <= 'b0;
	 tr_descbus_dtoffset_1 <= 'b0;
	 tr_descbus_dtoffset_2 <= 'b0;
	 tr_descbus_dtoffset_3 <= 'b0;
	 tr_descbus_dtoffset_4 <= 'b0;
	 tr_descbus_dtoffset_5 <= 'b0;
	 tr_descbus_dtoffset_6 <= 'b0;
	 tr_descbus_dtoffset_7 <= 'b0;
	 tr_descbus_dtoffset_8 <= 'b0;
	 tr_descbus_dtoffset_9 <= 'b0;
	 tr_descbus_dtoffset_A <= 'b0;
	 tr_descbus_dtoffset_B <= 'b0;
	 tr_descbus_dtoffset_C <= 'b0;
	 tr_descbus_dtoffset_D <= 'b0;
	 tr_descbus_dtoffset_E <= 'b0;
	 tr_descbus_dtoffset_F <= 'b0;

	 //update the signals once txn allocation is done (on alc_valid)
      end else if (txn_valid==1'b1 && alc_valid==1'b1) begin
	 tr_descbus_dtoffset_0 <= ( (IS_DATA=="YES") && (alc_idx=='h0) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_1 <= ( (IS_DATA=="YES") && (alc_idx=='h1) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_2 <= ( (IS_DATA=="YES") && (alc_idx=='h2) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_3 <= ( (IS_DATA=="YES") && (alc_idx=='h3) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_4 <= ( (IS_DATA=="YES") && (alc_idx=='h4) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_5 <= ( (IS_DATA=="YES") && (alc_idx=='h5) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_6 <= ( (IS_DATA=="YES") && (alc_idx=='h6) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_7 <= ( (IS_DATA=="YES") && (alc_idx=='h7) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_8 <= ( (IS_DATA=="YES") && (alc_idx=='h8) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_9 <= ( (IS_DATA=="YES") && (alc_idx=='h9) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_A <= ( (IS_DATA=="YES") && (alc_idx=='hA) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_B <= ( (IS_DATA=="YES") && (alc_idx=='hB) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_C <= ( (IS_DATA=="YES") && (alc_idx=='hC) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_D <= ( (IS_DATA=="YES") && (alc_idx=='hD) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_E <= ( (IS_DATA=="YES") && (alc_idx=='hE) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
	 tr_descbus_dtoffset_F <= ( (IS_DATA=="YES") && (alc_idx=='hF) ) ? ((alc_offset*DATA_WIDTH)/8) : 'b0;
         
	 
      end
   end 

   
   
   ///////////////////////
   //Transation Allocator/Descriptor Allocator
   //Description :
   //  txn_allocator allocates descriptor number and offset of data/strb-RAM.
   //////////////////////

   generate

      `IF_ACECH_SLV_WR_REQ

	assign write_txn = {
                            aw_infbus[(AW_DESCBUS_AXBAR_MSB) : (AW_DESCBUS_AXBAR_LSB)]
                            , aw_infbus[(AW_DESCBUS_AXDOMAIN_MSB) : (AW_DESCBUS_AXDOMAIN_LSB)]
                            , aw_infbus[(AW_DESCBUS_AWSNOOP_MSB) : (AW_DESCBUS_AWSNOOP_LSB)]
        
			    };
      
      
      
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_write_txn_updated
	 assign write_txn_updated[gi] = {
					 aw_descbus[gi][(AW_DESCBUS_AXBAR_MSB) : (AW_DESCBUS_AXBAR_LSB)]
					 , aw_descbus[gi][(AW_DESCBUS_AXDOMAIN_MSB) : (AW_DESCBUS_AXDOMAIN_LSB)]
					 , aw_descbus[gi][(AW_DESCBUS_AWSNOOP_MSB) : (AW_DESCBUS_AWSNOOP_LSB)]
         
					 };
      end

`ELSE
      
      assign write_txn = 'b0;
      
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_write_txn_updated_zero
	 assign write_txn_updated[gi] = 'b0;
      end

      `END
	endgenerate  


   assign txn_valid = (ACE_CHANNEL=="SLV_WR_REQ") ? wr_txn_valid : xx_txn_valid ;

   assign txn_size  = (ACE_CHANNEL=="SLV_WR_REQ") ? wr_txn_size 
                      : ( (IS_DATA=="YES") ? xx_txn_size  
                          : 'b0 ) ;



   assign wr_alc_valid  = (ACE_CHANNEL=="SLV_WR_REQ") ?  alc_valid : 'b0 ;                  
   assign wr_alc_offset = alc_offset;
   assign wr_alc_idx    = alc_idx;

   assign xx_alc_valid  = (ACE_CHANNEL=="SLV_WR_REQ") ?  'b0 : alc_valid ;                  
   assign xx_alc_offset = alc_offset;
   assign xx_alc_idx    = alc_idx;

   generate

      if (IS_DATA=="YES") begin

	 //Allocates descriptor and offset address for requested memory size.
	 ace_txn_allocator #(
			     .CHANNEL_TYPE       (CHANNEL_TYPE)
			     ,.ADDR_WIDTH         (ADDR_WIDTH)
			     ,.DATA_WIDTH         (DATA_WIDTH)
			     ,.RAM_SIZE           (RAM_SIZE)
			     ,.MAX_DESC           (MAX_DESC)
			     ,.CACHE_LINE_SIZE    (CACHE_LINE_SIZE)
			     )i_ace_txn_allocator (
						   .alc_valid      (alc_valid)
						   ,.alc_offset     (alc_offset)
						   ,.alc_idx        (alc_idx)
						   ,.clk            (clk)
						   ,.resetn         (resetn)
						   ,.txn_valid      (txn_valid)
						   ,.txn_size       (txn_size)
						   ,.desc_avail     (desc_avail)
						   ,.addr_avail     (desc_avail)
						   );

      end else begin

	 assign alc_offset = 'b0;

	 //Allocates descriptor.
	 ace_desc_allocator #(
			      .ADDR_WIDTH		                        (ADDR_WIDTH)
			      ,.DATA_WIDTH		                        (DATA_WIDTH)
			      ,.RAM_SIZE		                        (RAM_SIZE)
			      ,.MAX_DESC		                        (MAX_DESC)
			      ) i_ace_desc_allocator (
						      .clk	                                        (clk)
						      ,.resetn	                                (resetn)
						      ,.txn_valid                                     (txn_valid)
						      ,.desc_alc_valid                                (alc_valid)
						      ,.desc_alc_idx	                                (alc_idx)
						      ,.desc_avail                                    (desc_avail)
						      );

      end
   endgenerate

   ///////////////////////
   //Description: 
   //  At any clock-edge, aw_descbus signal can be updated by AW channel. 
   //  AW-channel can update the signals once txn allocation is done (on wr_alc_valid).
   //////////////////////

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_aw_descbus
	    aw_descbus[i][AW_DESCBUS_WIDTH-1:0]         <= 'b0;
	 end

	 //update the signals once txn allocation is done (on wr_alc_valid)
      end else if (wr_txn_valid==1'b1 && wr_alc_valid==1'b1) begin
	 aw_descbus[wr_alc_idx][AW_DESCBUS_WIDTH-1:0]           <= aw_infbus;
	 
      end
   end 

   
   ///////////////////////
   //AW-Channel
   //////////////////////

   //AW_fifo PUSH logic

   // awready generation if transaction allocation is successful. 
   // This signal is always one clock pulse. 

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 wr_txn_valid         <= 1'b0;
	 aw_infbus_ready    <= 1'b0;
	 wr_alc_idx_current   <= 'b0;
	 wr_inf_state         <= WR_INF_IDLE;
	 AW_fifo_new    <= 'b0 ;
	 awid_matched   <= 'b0;
	 wr_txn_size <= 'b0 ;
	 for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AW_wren_reset
            AW_wren[i] <= 'b0;
            AW_din[i]  <= 'b0;
            AW_fifo_awid[i] <= 'b0;
	 end
      end else begin 

	 case(wr_inf_state)

	   WR_INF_IDLE: begin
	      //Request for allocation when awvalid and awready is high and there is no pending request
	      if (aw_infbus_valid==1'b1 && aw_infbus_ready==1'b0 && wr_txn_valid==1'b0) begin
		 wr_inf_state                              <= WR_INF_WAIT_ALC;
		 wr_txn_valid                              <= 1'b1;  

		 //If txn is of type - (AW, B, WACK)  (No W)
		 if (    (write_txn == `WR_TXN_EVICT_0        )
			 || (write_txn == `WR_TXN_EVICT_1        )
			 || (write_txn == `WR_TXN_BARRIER_0      )
			 || (write_txn == `WR_TXN_BARRIER_1      )
			 || (write_txn == `WR_TXN_BARRIER_2      )
			 || (write_txn == `WR_TXN_BARRIER_3      )
			 ) begin
		    wr_txn_size <= 'b0 ;
		 end else begin
		    wr_txn_size <= aw_infbus_len[7:0] ;
		 end

	      end else begin
		 wr_inf_state <= WR_INF_IDLE;
	      end
	      
	      //Wait till txn allocation is completed  
	   end WR_INF_WAIT_ALC: begin
	      //If allocation completes
	      if (wr_txn_valid==1'b1 && wr_alc_valid==1'b1) begin 
		 wr_inf_state                              <= WR_INF_FILL_AWFIFO;   
		 wr_txn_valid                              <= 1'b0;      // de-assert allocation request
		 wr_desc_offset[wr_alc_idx]                <= wr_alc_offset;
		 wr_alc_idx_current                        <= wr_alc_idx;
		 aw_infbus_ready                         <= 1'b1;      //assert awready
		 for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_awid_matched
		    awid_matched[i]                         <= ( (AW_fifo_valid[i]==1'b1) && (AW_fifo_awid[i]==aw_infbus_id) ) ? 1'b1 : 1'b0;
		 end
		 //The equation finds first lower order '1' from operand and put all other bits as '0'.
		 AW_fifo_new                               <= ((~AW_fifo_valid))&(-(~AW_fifo_valid)) ;   //One-hot vector. Priority to LSB first.
		 //Wait until allocation is done
	      end else begin
		 wr_inf_state                              <= WR_INF_WAIT_ALC;
	      end
	      
	      //PUSH desc-idx to AW_fifo
	   end WR_INF_FILL_AWFIFO: begin
	      if (aw_infbus_valid==1'b1 && aw_infbus_ready==1'b1) begin 
		 wr_inf_state                              <= WR_INF_TXN_DONE;
		 aw_infbus_ready                         <= 1'b0;
		 if ( (|awid_matched)==1'b1 ) begin   //AW_fifo exists with matching awid
		    for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AW_wren_matched
		       if (awid_matched[i]==1'b1) begin
			  AW_wren[i] <= 1'b1;                 
			  AW_din[i]  <= wr_alc_idx_current;
		       end
		    end
		 end else begin  //Add in new AW_fifo
		    for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AW_wren_new
		       if (AW_fifo_new[i]==1'b1) begin
			  AW_wren[i] <= 1'b1;                 
			  AW_din[i]  <= wr_alc_idx_current;
			  AW_fifo_awid[i]     <= aw_infbus_id;
		       end
		    end
		 end  
	      end else begin
		 wr_inf_state                              <= WR_INF_FILL_AWFIFO;
	      end

	      //AW-channel ohandshaking done, make AW_wren signal low
	   end WR_INF_TXN_DONE: begin
	      wr_inf_state                                <= WR_INF_IDLE;
	      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AW_wren_low
		 AW_wren[i] <= 1'b0;                 
	      end
	   end default: begin
	      wr_inf_state <= wr_inf_state;

	   end
	 endcase
      end
   end  

   // An AW_fifo is valid when it's not empty

   generate

      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_AW_fifo_valid
	 assign AW_fifo_valid[gi] = ~AW_empty[gi];
      end

   endgenerate  

   //AW_fifo instantiation

   generate

      // MAX_DESC AW_fifo are instantiated. 
      // Each AW_fifo has unique awid (AW_fifo_awid).
      // AW_fifo stores description index. 
      // The fifo can store upto MAX_DESC description indices.
      // If the awid does not match with AW_fifo_awid of any fifo, a new fifo is filled and AW_fifo_awid is updated.
      // If the awid matches with AW_fifo_awid of any fifo, the desc index of that txn is pushed into same fifo.

      assign AW_rden = 'b0;

      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_AW_fifo
	 sync_fifo #(
		     .WIDTH		                                        (DESC_IDX_WIDTH)
		     ,.DEPTH		                                        (MAX_DESC)
		     ) AW_fifo (
				.dout	                                                        (AW_dout[gi])
				,.dout_pre	                                                (AW_dout_pre[gi])
				,.dout_pre_valid                                               (AW_dout_pre_valid[gi])
				,.full	                                                        (AW_full[gi])
				,.empty	                                                (AW_empty[gi])
				,.clk	                                                        (clk)
				,.rst_n	                                                (resetn)
				,.wren	                                                        (AW_wren[gi])
				,.rden	                                                        (AW_rden[gi])
				,.din	                                                        (AW_din[gi])
				);
      end

   endgenerate

   //AW_W_fifo PUSH logic

   //Upon write txn allocation, fill AW_W_fifo with allocated desc index
   assign AW_W_wren  = (wr_txn_valid==1'b1 && wr_alc_valid==1'b1); 
   assign AW_W_din   = wr_alc_idx;

   //AW_W_fifo instantiation

   // AW_W_fifo is used for AW-Channel and W-channel
   // Description :
   //   This FIFO is required to store the order of AW requests. Output from this
   //   FIFO is used to process W-channel data.

   sync_fifo #(
               .WIDTH                                                        (DESC_IDX_WIDTH)
               ,.DEPTH                                                        (MAX_DESC)
	       ) AW_W_fifo (
			    .dout                                                         (AW_W_dout)
			    ,.dout_pre                                                     (AW_W_dout_pre)
			    ,.dout_pre_valid                                               (AW_W_dout_pre_valid)
			    ,.full                                                         (AW_W_full)
			    ,.empty                                                        (AW_W_empty)
			    ,.clk                                                          (clk)
			    ,.rst_n                                                        (resetn)
			    ,.wren                                                         (AW_W_wren)
			    ,.rden                                                         (AW_W_rden)
			    ,.din                                                          (AW_W_din)
			    );
   
   //////////////////////
   //ACE-Channel
   //////////////////////

   //ready remains '1' if USR_fifo has space left.
   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 infbus_ready                               <= 1'b0;
      end else if (!USR_almost_full) begin 
	 infbus_ready                               <= 1'b1;
      end else begin 
	 infbus_ready                               <= 1'b0;
      end
   end

   //USR_fifo PUSH logic

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 USR_wren                                         <= 1'b0;
	 
	 //Upon valid and ready, push data into USR_fifo.
      end else if (infbus_valid==1'b1 && infbus_ready==1'b1) begin         
	 USR_wren                                         <= 1'b1;
	 USR_din                                          <= {infbus_last,infbus};
	 
      end else begin         
	 USR_wren                                         <= 1'b0;
      end
   end

   //USR_fifo instantiation

   // USR_fifo holds wdata, wstrb along with all w-channel sideband signals.
   

   sync_fifo #(
               //Ref:  .WIDTH                                                ((XLAST_WIDTH+INFBUS_WIDTH))
               .WIDTH                                                        (USR_FIFO_WIDTH)  
               ,.DEPTH                                                        (8) 
               ,.ALMOST_FULL_DEPTH                                            (8-2)      //DEPTH-2           
               ,.ALMOST_EMPTY_DEPTH                                           (2)         // Not used
	       ) USR_fifo (
			   .dout                                                         (USR_dout)
			   ,.full                                                         (USR_full)
			   ,.empty                                                        (USR_empty)
			   ,.almost_full                                                  (USR_almost_full)
			   ,.almost_empty                                                 (USR_almost_empty)
			   ,.clk                                                          (clk)
			   ,.rst_n                                                        (resetn)
			   ,.wren                                                         (USR_wren)
			   ,.rden                                                         (USR_rden)
			   ,.din                                                          (USR_din)
			   );


   //AW_W_fifo POP logic and USR_fifo POP logic

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 USR_rden_ff    <= 1'b0;
	 uc2rb_we  <= 1'b0;
      end else begin
	 USR_rden_ff    <= USR_rden;
	 uc2rb_we  <= (IS_DATA=="YES") ? USR_rden_ff : 'b0;
      end
   end

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 uc2rb_data   <= 'b0;
	 uc2rb_wstrb  <= 'b0;
      end else begin
	 uc2rb_data   <= (IS_DATA=="YES") ? USR_dout[(USR_FIFO_WDATA_MSB) : (USR_FIFO_WDATA_LSB)] : 'b0; 
	 uc2rb_wstrb  <= (ACE_CHANNEL=="SLV_WR_REQ") ? USR_dout[(USR_FIFO_WSTRB_MSB) : (USR_FIFO_WSTRB_LSB)] : 'b0;
      end
   end

   // Below state machine starts processing one transaction and returns to idle
   // state again upon writing all transfers of that transaction to internal RAMs.
   // After processing one transaction, the state machine returns back to idle state.

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 usr_state                                              <= USR_IDLE;
	 AW_W_rden                                             <= 1'b0;
	 USR_rden                                                <= 1'b0;
	 req_avail                                          <= 'b0;
	 last <= 'b0;
	 last_cntr                                            <= 'b0;
	 usrlen_sig                                             <= 'b0;
	 error_wr_wlast                                        <= 'b0;   
	 xx_txn_valid                                          <= 'b0;   
	 xx_txn_size                                           <= 'b0;   
	 for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_txn_type_wr_strb
	    txn_type_wr_strb[i]           <= 'b0;
	    descbus[i]                    <= 'b0;
	 end  

      end else begin         

	 case(usr_state)

	   USR_IDLE: begin

	      req_avail   <= 'b0;

	      `IF_ACECH_SLV_WR_REQ

		//If txn is of type - (AW, B, WACK)  (No W)
		if ( (   (write_txn_updated[AW_W_dout_pre] == `WR_TXN_EVICT_0        )
			 || (write_txn_updated[AW_W_dout_pre] == `WR_TXN_EVICT_1        )
			 || (write_txn_updated[AW_W_dout_pre] == `WR_TXN_BARRIER_0      )
			 || (write_txn_updated[AW_W_dout_pre] == `WR_TXN_BARRIER_1      )
			 || (write_txn_updated[AW_W_dout_pre] == `WR_TXN_BARRIER_2      )
			 || (write_txn_updated[AW_W_dout_pre] == `WR_TXN_BARRIER_3      )
			 )
		     && (AW_W_dout_pre_valid==1'b1) ) begin
		   usr_state <= USR_NO_W_TXN;   
		   AW_W_rden <= 1'b1;
		   USR_rden <= 1'b0;  //don't read from USR_fifo
		   usrlen_sig <= 'b0;
		   last_cntr <= 'b0;

		   
		   
		   //If AW-request and W-request both are available
		   //end else if(AW_W_empty==1'b0 && USR_empty==1'b0) begin   
		end else if(AW_W_dout_pre_valid==1'b1 && USR_empty==1'b0) begin   
		   usr_state <= USR_NEW_TXN;   
		   AW_W_rden <= 1'b1;
		   USR_rden <= 1'b1;
		   usrlen_sig <= 'b0;
		   last_cntr <= 'b0;
		   
		   //If AW-request or W-request is unavailable
		end else begin
		   usr_state <= usr_state;
		   USR_rden <= 1'b0;
		   last_cntr <= 'b0;
		   usrlen_sig <= 'b0;
		end  

`ELSE
	      
	      //If USR_fifo is not empty 
	      if(USR_empty==1'b0 && xx_txn_valid==1'b0) begin   
		 usr_state <= USR_ALC_WAIT;   
		 USR_rden <= 1'b0;
		 xx_txn_valid <= 1'b1;
		 xx_txn_size <= (ACE_CHANNEL=="SLV_SN_DATA") ? (((CACHE_LINE_SIZE*8)/DATA_WIDTH)-1) : 'b0 ;  
		 usrlen_sig <= 'b0;
		 last_cntr <= 'b0;
		 
		 //If USR_fifo is empty 
	      end else begin
		 usr_state <= usr_state;
		 USR_rden <= 1'b0;
		 xx_txn_valid <= 1'b0;
		 xx_txn_size <= 'b0;  
		 last_cntr <= 'b0;
		 usrlen_sig <= 'b0;
	      end  

	      `END


		// New transaction from AW_W_fifo. For transactions which don't have data
		// transer on W channel
		end USR_NO_W_TXN: begin   //Only valid for "SLV_WR_REQ"
		   usr_state <= USR_NO_W_WAIT; 
		   AW_W_rden <= 1'b0;
		   USR_rden <= 1'b0;
		   last_cntr <= 'b0;
		   usrlen_sig <= 'b0;
		   error_wr_wlast <= 'b0;        //as it is one clock-cycle pulse
		   
		   // Use descriptor index from AW_W_fifo. For transactions which don't have data
		   // transer on W channel
		end USR_NO_W_WAIT: begin   //Only valid for "SLV_WR_REQ"
		   usr_state <= USR_IDLE; 
		   AW_W_rden <= 1'b0;
		   USR_rden <= 1'b0;
		   last_cntr <= 'b0;
		   usrlen_sig <= 'b0;
		   error_wr_wlast <= 'b0;        //as it is one clock-cycle pulse
		   req_avail[AW_W_dout]   <= 1'b1;
		   
		   // New transaction from AW_W_fifo and USR_fifo 
		end USR_NEW_TXN: begin   //Only valid for "SLV_WR_REQ"
		   usr_state <= USR_NEW_WAIT; 
		   AW_W_rden <= 1'b0;
		   USR_rden <= 1'b0;
		   last_cntr <= 'b0;
		   usrlen_sig <= 'b0;
		   error_wr_wlast <= 'b0;        //as it is one clock-cycle pulse
		   
		   // New transaction from USR_fifo 
		end USR_ALC_WAIT: begin   //Only valid for channels other than "SLV_WR_REQ"
		   last_cntr <= 'b0;
		   usrlen_sig <= 'b0;
		   error_wr_wlast <= 'b0;        //as it is one clock-cycle pulse
		   if (xx_txn_valid==1'b1 && xx_alc_valid==1'b1) begin 
		      usr_state <= USR_ALC_TXN; 
		      xx_txn_valid <= 1'b0;
		      xx_offset    <= xx_alc_offset;
		      xx_idx       <= xx_alc_idx;
		      USR_rden <= 1'b1;
		      
		      //Wait until allocation is done
		   end else begin
		      usr_state <= usr_state;
		      USR_rden <= 1'b0;
		   end
		   
		   // New transaction from USR_fifo 
		end USR_ALC_TXN: begin   //Only valid for channels other than "SLV_WR_REQ"
		   USR_rden <= 1'b0;
		   usr_state <= USR_NEW_WAIT; 


		   // Wait for processing of AW and W channel signals for new transaction
		end USR_NEW_WAIT: begin
		   
		   `IF_ACECH_SLV_WR_REQ
		     //update the offsets for wdata in WDATA_RAM/WSTRB_RAM 
		     wr_fifo_pop_offset[AW_W_dout]                       <= wr_desc_offset[AW_W_dout]+1;  
		   //WDATA_RAM/WSTRB_RAM addr 
		   uc2rb_addr                                       <= wr_desc_offset[AW_W_dout];   
		   //calculate awlen
		   usrlen_sig                                           <= aw_descbus[AW_W_dout][(AW_DESCBUS_AWLEN_MSB) : (AW_DESCBUS_AWLEN_LSB)];
		   //Store descriptor index from AW_W_fifo for further processing of
		   //W-channel transfers
		   wr_fifo_pop_idx                                     <= AW_W_dout;
		   //Compute wstrb control bit
		   txn_type_wr_strb[AW_W_dout]              <= ~(&USR_dout[(USR_FIFO_WSTRB_MSB) : (USR_FIFO_WSTRB_LSB)]);  // <= ~(&wstrb)
		   descbus[AW_W_dout]           <= USR_dout[(USR_FIFO_WIDTH-XLAST_WIDTH-1): 0];
		   
`ELSE
		   //update the offsets for data/strb 
		   wr_fifo_pop_offset[xx_idx]                       <= xx_offset+1;  
		   //DATA/STRB RAM addr 
		   uc2rb_addr                                       <= (IS_DATA=="YES") ? xx_offset : 'b0;   
		   //calculate length
		   usrlen_sig                                           <= (ACE_CHANNEL=="SLV_SN_DATA") ? (((CACHE_LINE_SIZE*8)/DATA_WIDTH)-1) : 'b0 ; 
		   //Store descriptor for further processing of
		   //the ace-channel transfers
		   wr_fifo_pop_idx                                     <= xx_idx;
		   descbus[xx_idx]           <= USR_dout[(USR_FIFO_WIDTH-XLAST_WIDTH-1): 0];
		   
		   `END



		     last                                               <= USR_dout[USR_FIFO_LAST];  
		   //Count number of transfers
		   last_cntr                                          <= last_cntr+1;
		   
		   
		   
		   if (USR_dout[USR_FIFO_LAST]==1'b1) begin //last==1'b1   
		      usr_state <= USR_IDLE;
		      USR_rden <= 1'b0;
		      
		      `IF_ACECH_SLV_WR_REQ
			req_avail[AW_W_dout] <= 1'b1;
		      //If last occurs before expected
		      if ( aw_descbus[AW_W_dout][(AW_DESCBUS_AWLEN_MSB) : (AW_DESCBUS_AWLEN_LSB)] != 'b0  ) begin //awlen!=0
			 error_wr_wlast[AW_W_dout] <= 1'b1;
		      end else begin
			 error_wr_wlast[AW_W_dout] <= 1'b0;
		      end  
		      
`ELSE

		      req_avail[xx_idx] <= 1'b1;
		      //If last occurs before expected
		      if ( (ACE_CHANNEL=="SLV_SN_DATA") ) begin //len!=0  
			 error_wr_wlast[xx_idx] <= 1'b1;
		      end else begin
			 error_wr_wlast[xx_idx] <= 1'b0;
		      end  
		      
		      `END

			 
			//If last is not present in first transfer, process further the ace-channel
			//transfers 
			end else if (USR_dout[USR_FIFO_LAST]==1'b0) begin //last==1'b0   
			   if (USR_empty==1'b0) begin
			      USR_rden <= 1'b1;
			      //Continue processing further ace-channel transfers
			      usr_state <= USR_CON_TXN;  
			   end else begin
			      USR_rden <= 1'b0;
			      //Wait till next ace-channel transfers are available
			      usr_state <= USR_WAIT_WDATA;
			   end  


			   `IF_ACECH_SLV_WR_REQ
			     //If last was expected(number of transfers is equal to 1) but didn't arrive
			     if ( aw_descbus[AW_W_dout][(AW_DESCBUS_AWLEN_MSB) : (AW_DESCBUS_AWLEN_LSB)] == 'b0  ) begin //awlen==0
				error_wr_wlast[AW_W_dout] <= 1'b1;
			     end else begin
				error_wr_wlast[AW_W_dout] <= 1'b0;
			     end  
			   
			   `END
			      
			     end 
		   
		   
		   
		   //Continue processing further ace-channel transfers
		end USR_CON_TXN: begin
		   usr_state <= USR_CON_WAIT; 
		   USR_rden <= 1'b0;
		   last_cntr <= last_cntr;
		   error_wr_wlast <= 'b0;   //as it is one clock-cycle pulse
		   
		   // Wait for processing of ace-channel signals for same transaction
		end USR_CON_WAIT: begin

		   wr_fifo_pop_offset[wr_fifo_pop_idx]                 <= wr_fifo_pop_offset[wr_fifo_pop_idx]+1;
		   uc2rb_addr                                       <= (IS_DATA=="YES") ? wr_fifo_pop_offset[wr_fifo_pop_idx] : 'b0;
		   wr_fifo_pop_idx                                     <= wr_fifo_pop_idx;
		   txn_type_wr_strb[wr_fifo_pop_idx]        <= (txn_type_wr_strb[wr_fifo_pop_idx]) | (~(&USR_dout[(USR_FIFO_WSTRB_MSB) : (USR_FIFO_WSTRB_LSB)]));  // (txn_type_wr_strb[wr_fifo_pop_idx]) | (~(&wstrb))
		   
		   descbus[wr_fifo_pop_idx]           <= USR_dout[(USR_FIFO_WIDTH-XLAST_WIDTH-1): 0];
		   
		   last                                               <= USR_dout[USR_FIFO_LAST]; 
		   //Count number of transfers
		   last_cntr                                          <= last_cntr+1;
		   
		   if (USR_dout[USR_FIFO_LAST]==1'b1) begin //last==1'b1
		      usr_state <= USR_IDLE;
		      req_avail[wr_fifo_pop_idx] <= 1'b1;
		      USR_rden <= 1'b0;
		      //If last occurs before expected
		      if ( last_cntr != usrlen_sig  ) begin //last_cntr!=awlen
			 error_wr_wlast[wr_fifo_pop_idx] <= 1'b1;
		      end else begin
			 error_wr_wlast[wr_fifo_pop_idx] <= 1'b0;
		      end  
		      
		   end else if (USR_dout[USR_FIFO_LAST]==1'b0) begin  //last==1'b0
		      if (USR_empty==1'b0) begin
			 USR_rden <= 1'b1;
			 //Continue processing further ace-channel transfers
			 usr_state <= USR_CON_TXN;
		      end else begin
			 USR_rden <= 1'b0;
			 //Wait till next ace-channel transfers are available
			 usr_state <= USR_WAIT_WDATA;
		      end  
		      //If last was expected(number of transfers is equal to (usrlen_sig+1)) but didn't arrive
		      if ( last_cntr == usrlen_sig  ) begin //last_cntr==awlen
			 error_wr_wlast[wr_fifo_pop_idx] <= 1'b1;
		      end else begin
			 error_wr_wlast[wr_fifo_pop_idx] <= 1'b0;
		      end 
		   end 
		   

		   // Wait for processing of ace-channel signals for same transaction
		end USR_WAIT_WDATA: begin
		   if (USR_empty==1'b0) begin
		      USR_rden <= 1'b1;
		      usr_state <= USR_CON_TXN;
		   end else begin
		      usr_state <= USR_WAIT_WDATA;
		   end      
		   last_cntr <= last_cntr;
		   error_wr_wlast <= 'b0;   //as it is one clock-cycle pulse
		   
		end default: begin
		   usr_state <= usr_state;
		end
	   
	 endcase
      end
   end 

   assign uc2rb_bwe = (IS_DATA=="YES") ? {(DATA_WIDTH/8){1'b1}} : 'b0; 

   //ORDER_fifo PUSH logic

   //txn_avail : should be one-hot vector.

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 ORDER_wren <= 'b0;
	 ORDER_din <= 'b0;
      end else begin
	 `REG_IDX_VLD(txn_avail,ORDER_din,ORDER_wren)
      end
   end

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


   //ORDER_fifo POP logic

   `FF_RSTLOW(clk,resetn,ORDER_rden,ORDER_rden_ff)

   assign ORDER_rden = (ORDER_empty==1'b0) ? fifo_rden : 'b0;

   assign fifo_dout = ORDER_dout;

   assign fifo_dout_valid = ORDER_rden_ff;

   //wack/rack generation from bridge to DUT.

   always @(posedge clk) begin

      `IF_INTFS_FULLACE
	 
	if ( (ACE_CHANNEL=="MST_WR_RESP") ) begin  //master write response
	   inf_xack <= |(req_avail);
	end else begin
	   inf_xack <= 'b0;
	end
      
      `END_INTFS
	 
	`IF_INTFS_LITEACE
    
	  inf_xack <= 'b0;
      
      `END_INTFS                           
	end

   //////////////////////
   //Signal :
   //  uc2hm_trig
   //Description :
   //  Trigger HM to send/fetch data to/from SW based on write/read transaction
   //  correspondingly.
   //////////////////////

   //Update uc2hm_trig
   generate
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_uc2hm_trig
	 always @(posedge clk) begin
	    
	    if (resetn == 1'b0) begin
	       uc2hm_trig[gi] <= 1'b0;
	       
	       //If mode-1
	    end else if (int_mode_select_mode_0_1==1'b1)begin 
	       
               uc2hm_trig[gi] <= req_avail[gi];

	    end
	    
	 end
      end
   endgenerate

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
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_hm2uc_done_pulse
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

   //////////////////////
   //Signal :
   //  xack_done
   //Description :
   //  wack/rack generation indication from bridge to DUT.
   //////////////////////

   always @(posedge clk) begin

      `IF_INTFS_FULLACE
	 
	if ( (ACE_CHANNEL=="MST_WR_RESP") ) begin  //master write response
	   xack_done <= req_avail;
	end else begin
	   xack_done <= 'b0;
	end
      
      `END_INTFS
	 
	`IF_INTFS_LITEACE
    
	  xack_done <= 'b0;
      
      `END_INTFS                           
	end

   //////////////////////
   //Signal :
   //  txn_avail
   //Description :
   //  Transaction availablity indication from bridge to SW.
   //////////////////////

   generate
      `IF_INTFS_FULLACE


	if (ACE_CHANNEL=="MST_SN_REQ") begin  //master Snoop request
	   assign txn_avail = (req_avail);

	end else if (ACE_CHANNEL=="MST_WR_RESP") begin  //master write response
	   assign txn_avail = (xack_done);
           



	end else if (ACE_CHANNEL=="SLV_RD_REQ") begin  //slv read request
	   assign txn_avail = (req_avail);

	end else if (ACE_CHANNEL=="SLV_WR_REQ") begin  //slv write request
	   assign txn_avail = (int_mode_select_mode_0_1==1'b0) ? 
                              (req_avail)              //Mode-0
             : 
                              (hm2uc_done_pulse);   //Mode-1

	end else if ( (ACE_CHANNEL=="SLV_SN_RESP") || (ACE_CHANNEL=="SLV_SN_DATA") ) begin  //slv snoop response/data
	   assign txn_avail = (req_avail);

	end else begin
	   assign txn_avail = 'b0;

	end


      `END_INTFS

	`IF_INTFS_LITEACE
	  assign txn_avail = (int_mode_select_mode_0_1==1'b0) ? 
                             ((sig_mode_select_imm_bresp==1'b0) ? req_avail : 'b0)              //Mode-0
            : 
                             ((sig_mode_select_imm_bresp==1'b0) ? hm2uc_done_pulse : hm2uc_bresp_done);   //Mode-1
      `END_INTFS                           
	endgenerate


   ///////////////////////
   //Signal :
   //  error_status
   //Description:
   //  Update error_status based on error_ctl_hw(from bridge) or error_clear(from sw)
   //////////////////////


   assign error_ctl = (|error_wr_wlast_ff) ;


   always @(posedge clk) begin
      if (resetn==0) begin
	 error_wr_wlast_ff <= 'h0;
      end else begin
	 error_wr_wlast_ff <= error_wr_wlast;
      end
   end        		

   //always @(posedge clk) begin
   //  if (resetn==0) begin
   //    error_ctl <= 'h0;
   //  end else begin
   //    error_ctl <= (|error_wr_wlast);
   //  end
   //end        		


   always @(posedge clk) begin
      if (resetn==0) begin
	 error_ctl_hw <= 'h0;
      end else begin
	 error_ctl_hw <= error_ctl;
      end
   end        		

   always @(posedge clk) begin
      if (resetn==0) begin
	 error_clear_ff <= 'h0;
      end else begin
	 error_clear_ff <= error_clear;
      end
   end        		
   always @(posedge clk) begin
      if (resetn==0) begin
	 error_ctl_hw_ff <= 'h0;
      end else begin
	 error_ctl_hw_ff <= error_ctl_hw;
      end
   end

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 error_status <= 1'b0;  
      end else if (error_ctl_hw==1'b1 && error_ctl_hw_ff==1'b0) begin //Positive edge detection
	 error_status <= 1'b1;
      end else if (error_clear==1'b1 && error_clear_ff==1'b0) begin //Positive edge detection
	 error_status <= 1'b0;
      end
   end





endmodule        

// Local Variables:
// verilog-library-directories:("./")
// End:
