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

module ace_mst_rd_resp_ready #(

			       //Allowed Values : 
			       //  "MST_RD_RESP"
			       parameter ACE_PROTOCOL                                         = "FULLACE"
			       
			       ,parameter ACE_CHANNEL                                          = "MST_RD_RESP" 
			       
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
   
				 ,output [MAX_DESC-1:0] arid_read_en //Applicable in case of mst-read case only.
   
				 //error signals
				 ,output reg error_status
				 ,input error_clear
   
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_id0 //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_id1 //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_id2 //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_id3 //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_id4 //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_id5 //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_id6 //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_id7 //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_id8 //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_id9 //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_idA //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_idB //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_idC //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_idD //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_idE //Applicable in case of mst-read only
				 ,input [(`CLOG2(MAX_DESC))-1:0] arid_response_idF //Applicable in case of mst-read only
   
				 ,input [ID_WIDTH-1:0] rd_fifo_id_reg0 //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_reg1 //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_reg2 //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_reg3 //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_reg4 //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_reg5 //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_reg6 //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_reg7 //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_reg8 //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_reg9 //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_regA //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_regB //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_regC //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_regD //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_regE //Applicable in case of mst-read only
				 ,input [ID_WIDTH-1:0] rd_fifo_id_regF //Applicable in case of mst-read only
   
				 ,input [MAX_DESC-1:0] rd_fifo_id_reg_valid //Applicable in case of mst-read only
   
				 ,input ar_valid_ready //Applicable in case of mst-read only
   
				 ,input [(`CLOG2(MAX_DESC))-1:0] ar_valid_ready_desc_idx //Applicable in case of mst-read only
   
				 ,input [7:0] ar_valid_ready_arlen //Applicable in case of mst-read only
   
				 ,input [ID_WIDTH-1:0] ar_valid_ready_arid //Applicable in case of mst-read only
   
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
   
				 ,output [7:0] tr_descbus_len_0
				 ,output [7:0] tr_descbus_len_1
				 ,output [7:0] tr_descbus_len_2
				 ,output [7:0] tr_descbus_len_3
				 ,output [7:0] tr_descbus_len_4
				 ,output [7:0] tr_descbus_len_5
				 ,output [7:0] tr_descbus_len_6
				 ,output [7:0] tr_descbus_len_7
				 ,output [7:0] tr_descbus_len_8
				 ,output [7:0] tr_descbus_len_9
				 ,output [7:0] tr_descbus_len_A
				 ,output [7:0] tr_descbus_len_B
				 ,output [7:0] tr_descbus_len_C
				 ,output [7:0] tr_descbus_len_D
				 ,output [7:0] tr_descbus_len_E
				 ,output [7:0] tr_descbus_len_F
   
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_0 //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_1 //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_2 //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_3 //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_4 //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_5 //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_6 //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_7 //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_8 //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_9 //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_A //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_B //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_C //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_D //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_E //Applicable in case of mst-read case only
				 ,input [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] data_offset_F //Applicable in case of mst-read case only
   
   
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
									     ( (ACE_CHANNEL=="MST_RD_RESP") || (ACE_CHANNEL=="MST_WR_RESP") || (ACE_CHANNEL=="MST_SN_REQ") ) ?
                                                                             "MST_BRIDGE"
   : "SLV_BRIDGE" ;

   localparam CHANNEL_TYPE                                                 = 
									     ( (ACE_CHANNEL=="SLV_SN_RESP") || (ACE_CHANNEL=="SLV_SN_DATA") || (ACE_CHANNEL=="MST_SN_REQ") ) ?
									     "SN"
   : ( ( (ACE_CHANNEL=="SLV_RD_REQ") || (ACE_CHANNEL=="MST_RD_RESP") ) ? "RD" : "WR") ;

   localparam IS_DATA                                                   = 
									  ( (ACE_CHANNEL=="SLV_WR_REQ") || (ACE_CHANNEL=="SLV_SN_DATA") || (ACE_CHANNEL=="MST_RD_RESP") ) ?
                                                                          "YES"
   : "NO" ;

   localparam IS_MODE_1                                                   = 
									    ( (ACE_CHANNEL=="SLV_WR_REQ") || (ACE_CHANNEL=="MST_RD_RESP") ) ?
                                                                            "YES"
   : "NO" ;

   localparam IS_XACK                                                   = 
									  ( (ACE_CHANNEL=="MST_RD_RESP") || (ACE_CHANNEL=="MST_WR_RESP") ) ?
                                                                          "YES"
   : "NO" ;




   localparam DESC_IDX_WIDTH                                               = `CLOG2(MAX_DESC);
   localparam RAM_OFFSET_WIDTH                                             = `CLOG2((RAM_SIZE*8)/DATA_WIDTH);

   localparam DESCBUS_WIDTH                                                = TR_DESCBUS_WIDTH;


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

   localparam USR_IDLE                                                     = 3'b000;                        
   localparam USR_NEW_TXN                                                  = 3'b001;                           
   localparam USR_ALC_WAIT                                                 = 3'b010;                           
   localparam USR_ALC_TXN                                                  = 3'b011;                           
   localparam USR_NEW_WAIT                                                 = 3'b100;                          
   localparam USR_CON_TXN                                                  = 3'b101;                          
   localparam USR_CON_WAIT                                                 = 3'b110;                          
   localparam USR_WAIT_WDATA                                               = 3'b111;                              

   localparam WSTRB_WIDTH                                                  = (DATA_WIDTH/8);
   localparam XLAST_WIDTH                                                  = 1;            //last/rlast width

   localparam BRESP_WIDTH                                                  = 2;            //bresp width
   localparam RRESP_WIDTH                                                  = (ACE_PROTOCOL=="FULLACE") ? (4) :
                                                                             (2) ;            //rresp width
   localparam CRRESP_WIDTH                                                 = 5;

   localparam AXLEN_WIDTH                                                  = 8;

   localparam USR_FIFO_WIDTH                                               = (XLAST_WIDTH+INFBUS_WIDTH);
   localparam USR_FIFO_DEPTH                                               = (8); 
   localparam USR_FIFO_ALMOST_FULL_DEPTH                                   = (USR_FIFO_DEPTH-2);


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




   localparam DESCBUS_RDATA_MSB                                   = (DESCBUS_WIDTH-1);
   localparam DESCBUS_RID_MSB                                     = (DESCBUS_WIDTH-DATA_WIDTH-1);
   localparam DESCBUS_RRESP_MSB                                   = (DESCBUS_WIDTH-DATA_WIDTH-ID_WIDTH-1);
   localparam DESCBUS_RUSER_MSB                                   = (DESCBUS_WIDTH-DATA_WIDTH-ID_WIDTH-RRESP_WIDTH-1);

   //localparam DESCBUS_                                        = (DESCBUS_WIDTH-ID_WIDTH-ADDR_WIDTH-1);


   //Loop variables
   integer 			       i;
   integer 			       j;
   integer 			       k;

   //generate variable
   genvar 			       gi;


   wire [DESCBUS_WIDTH-1:0] 	       descbus[MAX_DESC-1:0]; 

   reg [DATA_WIDTH-1:0] 	       descbus_rdata[MAX_DESC-1:0]; 
   reg [ID_WIDTH-1:0] 		       descbus_rid[MAX_DESC-1:0]; 
   reg [RRESP_WIDTH-1:0] 	       descbus_rresp[MAX_DESC-1:0]; 
   reg [RUSER_WIDTH-1:0] 	       descbus_ruser[MAX_DESC-1:0]; 

   wire [RAM_OFFSET_WIDTH-1:0] 	       data_offset[MAX_DESC-1:0] ; 
   reg [7:0] 			       len[MAX_DESC-1:0] ; 

   wire 			       sig_mode_select_imm_bresp;

   wire 			       txn_valid;
   wire [7:0] 			       txn_size; //AXLEN (Request is (AXLEN+1))
   wire 			       alc_valid;
   wire [RAM_OFFSET_WIDTH-1:0] 	       alc_offset; //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [10:0]
   wire [DESC_IDX_WIDTH-1:0] 	       alc_idx; //For MAX_DESC=16, it is [3:0] 


   reg 				       xx_txn_valid;
   reg [7:0] 			       xx_txn_size; //AXLEN (Request is (AXLEN+1))
   wire 			       xx_alc_valid;
   wire [RAM_OFFSET_WIDTH-1:0] 	       xx_alc_offset; //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [10:0]
   wire [DESC_IDX_WIDTH-1:0] 	       xx_alc_idx;    //For MAX_DESC=16, it is [3:0] 
   reg [RAM_OFFSET_WIDTH-1:0] 	       xx_offset; //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [10:0]
   reg [DESC_IDX_WIDTH-1:0] 	       xx_idx; //For MAX_DESC=16, it is [3:0] 

   reg [1:0] 			       wr_inf_state;

   reg 				       wr_txn_valid;
   reg 				       wr_txn_valid_ff;
   reg [7:0] 			       wr_txn_size; //AXLEN (Request is (AXLEN+1))
   wire 			       wr_alc_valid;
   reg 				       wr_alc_valid_ff;
   wire [RAM_OFFSET_WIDTH-1:0] 	       wr_alc_offset; //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [10:0]
   wire [DESC_IDX_WIDTH-1:0] 	       wr_alc_idx; //For MAX_DESC=16, it is [3:0] 
   reg [DESC_IDX_WIDTH-1:0] 	       wr_alc_idx_ff; //For MAX_DESC=16, it is [3:0] 

   reg [RAM_OFFSET_WIDTH-1:0] 	       wr_desc_offset [MAX_DESC-1:0];
   reg [RAM_OFFSET_WIDTH-1:0] 	       wr_fifo_pop_offset[MAX_DESC-1:0];
   reg [DESC_IDX_WIDTH-1:0] 	       wr_fifo_pop_idx;

   wire 			       USR_full;
   wire 			       USR_empty;
   wire 			       USR_almost_full;
   wire 			       USR_almost_empty;
   reg 				       USR_wren;
   wire 			       USR_rden;
   reg [USR_FIFO_WIDTH-1:0] 	       USR_din; 
   wire [USR_FIFO_WIDTH-1:0] 	       USR_dout; 

   reg 				       last;
   reg [7:0] 			       last_cntr;
   reg [7:0] 			       usrlen_sig;
   reg [MAX_DESC-1:0] 		       error_wr_wlast;  
   wire [MAX_DESC-1:0] 		       req_avail;
   reg [DESC_IDX_WIDTH-1:0] 	       wr_alc_idx_current;
   reg [2:0] 			       usr_state;
   
   reg 				       USR_rden_ff;              


   wire [DESC_IDX_WIDTH-1:0] 	       ORDER_dout;
   wire [DESC_IDX_WIDTH-1:0] 	       ORDER_dout_pre;
   wire 			       ORDER_dout_pre_valid;
   wire 			       ORDER_full;
   wire 			       ORDER_empty;
   reg 				       ORDER_wren;
   wire 			       ORDER_rden;
   reg [DESC_IDX_WIDTH-1:0] 	       ORDER_din;
   wire [DESC_IDX_WIDTH:0] 	       ORDER_fifo_counter;
   
   reg 				       ORDER_rden_ff;

   wire [MAX_DESC-1:0] 		       txn_avail;
   reg [MAX_DESC-1:0] 		       xack_done; 
   wire [MAX_DESC-1:0] 		       hm2uc_bresp_done;
   wire [MAX_DESC-1:0] 		       hm2uc_xack_done;
   reg [MAX_DESC-1:0] 		       hm2uc_done_pulse;
   reg [MAX_DESC-1:0] 		       hm2uc_done_ff;

   reg [MAX_DESC-1:0] 		       arid_read_en_reg; 
   reg 				       arid_read_en_reg_valid; 
   reg [MAX_DESC-1:0] 		       arid_read_en_reg_ff;
   reg [DATA_WIDTH-1:0] 	       rdata_in;
   reg [ID_WIDTH-1:0] 		       rid_in;
   reg [RUSER_WIDTH-1:0] 	       ruser_in;
   reg [RRESP_WIDTH-1:0] 	       rresp_in;
   reg 				       rvalid_in;
   reg 				       rlast_in;
   wire [(`CLOG2(MAX_DESC)):0] 	       rdata_fifo_counter;



   wire [ID_WIDTH-1:0] 		       fifo_id_rd_reg[MAX_DESC-1:0];
   wire [MAX_DESC-1:0] 		       fifo_id_rd_reg_valid;
   wire [(`CLOG2(MAX_DESC))-1:0]       arid_response_id_reg[MAX_DESC-1:0];
   wire 			       rnext_on_bus; 
   wire [9:0] 			       rdata_counter_done[MAX_DESC-1:0];
   wire [(`CLOG2(MAX_DESC))-1:0]       fifo_select;
   wire 			       send_data_to_dram;   
   wire 			       halt_rdata_fifo_read;   
   wire [(`CLOG2(MAX_DESC))-1:0]       desc_rdata_id;
   wire 			       um_as_hm_count_st;   
   wire [2:0] 			       increment_rdata_offset_addr;

   wire [ID_WIDTH-1:0] 		       rdata_read_out_id;
   wire [DATA_WIDTH-1:0] 	       rdata_read_out_data;
   wire [RRESP_WIDTH-1:0] 	       rdata_read_out_resp;
   wire 			       rdata_read_out_rlast;
   wire [RUSER_WIDTH-1:0] 	       rdata_read_out_ruser;
   wire 			       rdata_fifo_empty,rdata_fifo_full;


   reg 				       rnext_on_bus_ff;
   reg 				       rdata_read_en;
   reg [(`CLOG2(RAM_SIZE/(DATA_WIDTH/8)))-1:0] offset_addr [MAX_DESC-1:0];
   reg 					       rdata_processed;
   reg [1:0] 				       rdata_fifo_read;
   reg 					       rdata_read_en_ff; 
   reg 					       rdata_read_en_ff2;
   reg 					       rdata_read_en_ff3;
   reg 					       rdata_read_en_ff4;
   reg 					       rdata_read_en_ff5; 
   reg [9:0] 				       rdata_counter[MAX_DESC-1:0];
   reg [9:0] 				       rdata_counter_ff_0[MAX_DESC-1:0];
   reg [(`CLOG2(MAX_DESC))-1:0] 	       fifo_select_ff;
   reg [(`CLOG2(MAX_DESC))-1:0] 	       fifo_select_rd_per_fifo [MAX_DESC-1:0];
   reg 					       rdata_fifo_state[MAX_DESC-1:0];
   reg [MAX_DESC-1:0] 			       send_data_to_dram_per_fifo;
   reg 					       send_data_to_dram_ff;
   reg 					       send_data_to_dram_ff2;
   reg [MAX_DESC-1:0] 			       increment_offset;
   reg [MAX_DESC-1:0] 			       halt_rdata_fifo_read_per_fifo;
   reg [(`CLOG2(MAX_DESC))-1:0] 	       desc_rdata_id_per_fifo[MAX_DESC-1:0];
   reg [RRESP_WIDTH-1:0] 		       rdata_read_out_first_bad_resp[MAX_DESC-1:0];
   reg [MAX_DESC-1:0] 			       rdata_received_bad_response;
   reg [MAX_DESC-1:0] 			       rdata_received_bad_response_ff;   
   reg [2:0] 				       um_as_hm_wr_data_counter;
   reg [MAX_DESC-1:0] 			       rlast_not_asserted_error_check_late;
   reg [MAX_DESC-1:0] 			       rlast_not_asserted_error_check_early;

   wire 				       error_ctl;

   reg 					       error_ctl_hw;
   reg 					       error_ctl_hw_ff;

   reg 					       error_clear_ff;

   reg 					       rlast_not_asserted_error;
   reg 					       rid_not_found_error;

   reg [DESC_IDX_WIDTH-1:0] 		       uc2rb_wr_desc_id;   

   reg 					       uc2rb_wr_we;
   reg [RAM_OFFSET_WIDTH-1:0] 		       uc2rb_wr_addr;  
   reg [DATA_WIDTH-1:0] 		       uc2rb_wr_data; 

   reg [MAX_DESC-1:0] 			       rresp_completed;   
   reg [RUSER_WIDTH-1:0] 		       read_ruser[MAX_DESC-1:0];

   reg [MAX_DESC-1:0] 			       ownership_per_desc_rd;
   
   



   ///////////////////////
   //Description: 
   //  Tie imm_bresp mode to 0.
   //////////////////////
   assign sig_mode_select_imm_bresp = 1'b0;

   //1D to 2D conversion

   generate 

      for(gi=0;gi<MAX_DESC;gi=gi+1) begin:gen_descbus
         assign descbus[gi] = {    descbus_rdata[gi]
                                   , descbus_rid[gi]
                                   , descbus_rresp[gi]
                                   , descbus_ruser[gi]
				   };

      end  

   endgenerate

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

   assign tr_descbus_len_0 = len['h0]; 
   assign tr_descbus_len_1 = len['h1]; 
   assign tr_descbus_len_2 = len['h2]; 
   assign tr_descbus_len_3 = len['h3]; 
   assign tr_descbus_len_4 = len['h4]; 
   assign tr_descbus_len_5 = len['h5]; 
   assign tr_descbus_len_6 = len['h6]; 
   assign tr_descbus_len_7 = len['h7]; 
   assign tr_descbus_len_8 = len['h8]; 
   assign tr_descbus_len_9 = len['h9]; 
   assign tr_descbus_len_A = len['hA]; 
   assign tr_descbus_len_B = len['hB]; 
   assign tr_descbus_len_C = len['hC]; 
   assign tr_descbus_len_D = len['hD]; 
   assign tr_descbus_len_E = len['hE]; 
   assign tr_descbus_len_F = len['hF]; 

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
	 if (ACE_CHANNEL=="MST_RD_RESP") begin
	    tr_descbus_dtoffset_0 <= data_offset_0;
	    tr_descbus_dtoffset_1 <= data_offset_1;
	    tr_descbus_dtoffset_2 <= data_offset_2;
	    tr_descbus_dtoffset_3 <= data_offset_3;
	    tr_descbus_dtoffset_4 <= data_offset_4;
	    tr_descbus_dtoffset_5 <= data_offset_5;
	    tr_descbus_dtoffset_6 <= data_offset_6;
	    tr_descbus_dtoffset_7 <= data_offset_7;
	    tr_descbus_dtoffset_8 <= data_offset_8;
	    tr_descbus_dtoffset_9 <= data_offset_9;
	    tr_descbus_dtoffset_A <= data_offset_A;
	    tr_descbus_dtoffset_B <= data_offset_B;
	    tr_descbus_dtoffset_C <= data_offset_C;
	    tr_descbus_dtoffset_D <= data_offset_D;
	    tr_descbus_dtoffset_E <= data_offset_E;
	    tr_descbus_dtoffset_F <= data_offset_F;
	 end else begin
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
   end 

   
   assign data_offset['h0] = data_offset_0; 
   assign data_offset['h1] = data_offset_1; 
   assign data_offset['h2] = data_offset_2; 
   assign data_offset['h3] = data_offset_3; 
   assign data_offset['h4] = data_offset_4; 
   assign data_offset['h5] = data_offset_5; 
   assign data_offset['h6] = data_offset_6; 
   assign data_offset['h7] = data_offset_7; 
   assign data_offset['h8] = data_offset_8; 
   assign data_offset['h9] = data_offset_9; 
   assign data_offset['hA] = data_offset_A; 
   assign data_offset['hB] = data_offset_B; 
   assign data_offset['hC] = data_offset_C; 
   assign data_offset['hD] = data_offset_D; 
   assign data_offset['hE] = data_offset_E; 
   assign data_offset['hF] = data_offset_F; 

   assign fifo_id_rd_reg['h0] = rd_fifo_id_reg0;
   assign fifo_id_rd_reg['h1] = rd_fifo_id_reg1;
   assign fifo_id_rd_reg['h2] = rd_fifo_id_reg2;
   assign fifo_id_rd_reg['h3] = rd_fifo_id_reg3;
   assign fifo_id_rd_reg['h4] = rd_fifo_id_reg4;
   assign fifo_id_rd_reg['h5] = rd_fifo_id_reg5;
   assign fifo_id_rd_reg['h6] = rd_fifo_id_reg6;
   assign fifo_id_rd_reg['h7] = rd_fifo_id_reg7;
   assign fifo_id_rd_reg['h8] = rd_fifo_id_reg8;
   assign fifo_id_rd_reg['h9] = rd_fifo_id_reg9;
   assign fifo_id_rd_reg['hA] = rd_fifo_id_regA;
   assign fifo_id_rd_reg['hB] = rd_fifo_id_regB;
   assign fifo_id_rd_reg['hC] = rd_fifo_id_regC;
   assign fifo_id_rd_reg['hD] = rd_fifo_id_regD;
   assign fifo_id_rd_reg['hE] = rd_fifo_id_regE;
   assign fifo_id_rd_reg['hF] = rd_fifo_id_regF;

   assign fifo_id_rd_reg_valid = rd_fifo_id_reg_valid;
   
   assign arid_response_id_reg['h0] = arid_response_id0;
   assign arid_response_id_reg['h1] = arid_response_id1;
   assign arid_response_id_reg['h2] = arid_response_id2;
   assign arid_response_id_reg['h3] = arid_response_id3;
   assign arid_response_id_reg['h4] = arid_response_id4;
   assign arid_response_id_reg['h5] = arid_response_id5;
   assign arid_response_id_reg['h6] = arid_response_id6;
   assign arid_response_id_reg['h7] = arid_response_id7;
   assign arid_response_id_reg['h8] = arid_response_id8;
   assign arid_response_id_reg['h9] = arid_response_id9;
   assign arid_response_id_reg['hA] = arid_response_idA;
   assign arid_response_id_reg['hB] = arid_response_idB;
   assign arid_response_id_reg['hC] = arid_response_idC;
   assign arid_response_id_reg['hD] = arid_response_idD;
   assign arid_response_id_reg['hE] = arid_response_idE;
   assign arid_response_id_reg['hF] = arid_response_idF;
   
   ///////////////////////
   //Transation Allocator/Descriptor Allocator
   //Description :
   //  txn_allocator allocates descriptor number and offset of data/strb-RAM.
   //////////////////////

   assign txn_valid = 'b0;

   assign txn_size  = 'b0;

   assign wr_alc_valid  = (ACE_CHANNEL=="SLV_WR_REQ") ?  alc_valid : 'b0 ;                  
   assign wr_alc_offset = alc_offset;
   assign wr_alc_idx    = alc_idx;

   assign xx_alc_valid  = (ACE_CHANNEL=="SLV_WR_REQ") ?  'b0 : alc_valid ;                  
   assign xx_alc_offset = alc_offset;
   assign xx_alc_idx    = alc_idx;

   generate

      if (ACE_CHANNEL=="MST_RD_RESP") begin

	 assign alc_valid = 'b0;
	 assign alc_offset = 'b0;
	 assign alc_idx = 'b0;


      end else if (IS_DATA=="YES") begin

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
               ,.DEPTH                                                        (USR_FIFO_DEPTH) 
               ,.ALMOST_FULL_DEPTH                                            (USR_FIFO_ALMOST_FULL_DEPTH)                 
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

   assign USR_rden = rdata_read_en; 

   assign {    rdata_read_out_rlast
               , rdata_read_out_data 
               , rdata_read_out_id   
               , rdata_read_out_resp 
               , rdata_read_out_ruser 
	       }                          = USR_dout;

   assign rdata_fifo_empty = USR_empty;       
   assign rdata_fifo_full  = USR_full;       

   ////////////////////////////////////////////////////////////////////////////////
     //
   // FSM to read data from rdata_fifo and halting it until data is not processed
   //
   /////////////////////////////////////////////////////////////////////////////////

   assign um_as_hm_max_wr_delay = 0;


   localparam RDATA_READ_IDLE=2'b00,RDATA_READ_WAIT=2'b01,RDATA_READ_WAIT_2=2'b10,RDATA_READ_WAIT_3=2'b11;
   always@(posedge clk) begin
      if(~resetn) begin
     	 rdata_read_en<=0;
     	 rdata_fifo_read<=RDATA_READ_IDLE;
      end
      else begin
     	 case(rdata_fifo_read) 
     	   RDATA_READ_IDLE:
     	     if(~rdata_fifo_empty) begin
     		rdata_read_en<=1;
     		rdata_fifo_read<=RDATA_READ_WAIT;
     	     end
     	     else begin
     		rdata_read_en<=0;
     		rdata_fifo_read<=RDATA_READ_IDLE;
     	     end
     	   RDATA_READ_WAIT:
     	     begin
     		rdata_read_en<=0;
     		rdata_fifo_read<=RDATA_READ_WAIT_2;
     	     end
     	   RDATA_READ_WAIT_2:
     	     if(halt_rdata_fifo_read || um_as_hm_max_wr_delay) begin
     		rdata_read_en<=0;
     		rdata_fifo_read<=RDATA_READ_WAIT_2;
     	     end
     	     else begin
     		rdata_fifo_read<=RDATA_READ_IDLE;
     	     end
     	 endcase 
      end
   end

   //////////////////////////////////////////
   //
   // Flopping to sync with rdata_out
   //
   //////////////////////////////////////////

   always@ (posedge clk) begin
      rdata_read_en_ff<=rdata_read_en;
      rdata_read_en_ff2<=rdata_read_en_ff;
      rdata_read_en_ff3<=rdata_read_en_ff2;
      rdata_read_en_ff4<=rdata_read_en_ff3;	  
   end



   //////////////////////////////////////////////////////////////////
   //
   // FSM to fetch data from rdata_fifo and identifiy which desc it
   // it belongs to by looking at rid. 
   //
   ////////////////////////////////////////////////////////////////////


   localparam RDATA_FIFO_IDLE=1'b0, RDATA_FIFO_MATCH_ID=1'b1;
   always@ (posedge clk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin
     	 if(~resetn) begin
     	    halt_rdata_fifo_read_per_fifo[k]<=0;
     	    send_data_to_dram_per_fifo[k]<=0;
     	    fifo_select_rd_per_fifo[k]<=0;
     	    desc_rdata_id_per_fifo[k]<=0;
     	    rdata_fifo_state[k]<=RDATA_FIFO_IDLE;
     	 end
     	 else begin 
     	    case(rdata_fifo_state[k])
     	      RDATA_FIFO_IDLE:
     		if(rdata_read_en) begin
     		   halt_rdata_fifo_read_per_fifo[k]<=1;
     		   send_data_to_dram_per_fifo[k]<=0;
     		   fifo_select_rd_per_fifo[k]<=0;
     		   rdata_fifo_state[k]<=RDATA_FIFO_MATCH_ID;
     		end
     		else begin
     		   halt_rdata_fifo_read_per_fifo[k]<=0;
     		   send_data_to_dram_per_fifo[k]<=0;
     		   fifo_select_rd_per_fifo[k]<=0;
     		   rdata_fifo_state[k]<=RDATA_FIFO_IDLE;
     		end	
     	      RDATA_FIFO_MATCH_ID:
     		if((rdata_read_out_id==fifo_id_rd_reg[k]) && fifo_id_rd_reg_valid[k]) begin
     		   send_data_to_dram_per_fifo[k]<=1;
     		   desc_rdata_id_per_fifo[k]<=arid_response_id_reg[k];
     		   fifo_select_rd_per_fifo[k]<=k;
     		   rdata_fifo_state[k]<=RDATA_FIFO_IDLE;
     		end
     		else begin
     		   desc_rdata_id_per_fifo[k]<=0;
     		   fifo_select_rd_per_fifo[k]<=0;
     		   rdata_fifo_state[k]<=RDATA_FIFO_IDLE;
     		end
     	    endcase		
     	 end
      end
   end


   //////////////////////////////////////////////////////////////////
   //
   // Flopping send_data_to_dram trigger signal, to sync with
   // Other blocks	
   //
   //////////////////////////////////////////////////////////////////

   always@ (posedge clk) begin
      send_data_to_dram_ff<=send_data_to_dram;
      send_data_to_dram_ff2<=send_data_to_dram_ff;
   end


   ///////////////////////////////////////////////////////////////////
   //
   // ORed desc_rdata_id from all fifos, as only one is active 
   // at a time
   //	
   ///////////////////////////////////////////////////////////////////

   assign desc_rdata_id	=
     			 desc_rdata_id_per_fifo[0] |
     			 desc_rdata_id_per_fifo[1] |
     			 desc_rdata_id_per_fifo[2] |
     			 desc_rdata_id_per_fifo[3] |
     			 desc_rdata_id_per_fifo[4] |
     			 desc_rdata_id_per_fifo[5] |
     			 desc_rdata_id_per_fifo[6] |
     			 desc_rdata_id_per_fifo[7] |
     			 desc_rdata_id_per_fifo[8] |
     			 desc_rdata_id_per_fifo[9] |
     			 desc_rdata_id_per_fifo[10] |
     			 desc_rdata_id_per_fifo[11] |
     			 desc_rdata_id_per_fifo[12] |
     			 desc_rdata_id_per_fifo[13] |
     			 desc_rdata_id_per_fifo[14] |
     			 desc_rdata_id_per_fifo[15] ;


   assign fifo_select	=
     			 fifo_select_rd_per_fifo[0] |
     			 fifo_select_rd_per_fifo[1] |
     			 fifo_select_rd_per_fifo[2] |
     			 fifo_select_rd_per_fifo[3] |
     			 fifo_select_rd_per_fifo[4] |
     			 fifo_select_rd_per_fifo[5] |
     			 fifo_select_rd_per_fifo[6] |
     			 fifo_select_rd_per_fifo[7] |
     			 fifo_select_rd_per_fifo[8] |
     			 fifo_select_rd_per_fifo[9] |
     			 fifo_select_rd_per_fifo[10] |
     			 fifo_select_rd_per_fifo[11] |
     			 fifo_select_rd_per_fifo[12] |
     			 fifo_select_rd_per_fifo[13] |
     			 fifo_select_rd_per_fifo[14] |
     			 fifo_select_rd_per_fifo[15] ;

   /////////////////////////////////////////////////////
   //
   // Halt fifo read: to stop fetching one more data
   // untill current data is processed.
   //
   //////////////////////////////////////////////////////

   assign halt_rdata_fifo_read = | halt_rdata_fifo_read_per_fifo;

   ///////////////////////////////////////////////////////////////////
   //
   // ORed send_data_to_dram from all fifos, as only one is active 
   // at a time
   //	
   ///////////////////////////////////////////////////////////////////

   assign send_data_to_dram  = |send_data_to_dram_per_fifo; 


   /////////////////////////////////////////////////////////////////////
   //
   // Rdata_counter: Maintaining Counters per unique ID. Flopping it and
   // creating _ff_0, which will be used to identify it counter has
   // been decremented frmo 1 to 0.
   //
   //////////////////////////////////////////////////////////////////////

   always@ (posedge clk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:rdata_count_pulse
     	 rdata_counter_ff_0[k]<=rdata_counter[k];
      end
   end

   /////////////////////////////////////////////////////////////////////
   //
   // Generate pulse when rdata_counter[Per Desc] goes from 0x1 to 0x0.
   // This is used to identify if rlast came correclty, or should reponse
   // be routed back to Host
   //
   //////////////////////////////////////////////////////////////////////

   generate
      for(gi=0;gi<MAX_DESC;gi=gi+1) begin:pulsegen
     	 assign rdata_counter_done[gi]=rdata_counter_ff_0[gi] & {rdata_counter[gi][9:1],~rdata_counter[gi][0]};
      end
   endgenerate


   //////////////////////////////////////////////////////////////////
   // 
   // Intr Error status update, if any bid/rid not found and rlast 
   // not asserted properly
   //
   ////////////////////////////////////////////////////////////////

   assign update_intr_error_status_reg =
					rlast_not_asserted_error | 
					rid_not_found_error; 



   ////////////////////////////////////////////////////////////////////
   //
   // If after rdata is fetched and none of the ID is matched
   // send_data_to_dram will remain low, so assert it as an 
   // Error.
   //
   ///////////////////////////////////////////////////////////////////


   always@ (posedge clk) begin	  
      if(~resetn) begin
     	 rid_not_found_error<=0;
      end
      else if(rdata_read_en_ff2) begin
     	 rid_not_found_error<=~send_data_to_dram;
      end
      else begin
     	 rid_not_found_error<=0;
      end
      
   end




   always@(posedge clk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin
     	 if(~resetn) begin
     	    rlast_not_asserted_error_check_late[k]<=0;
     	    rlast_not_asserted_error_check_early[k]<=0;
     	 end
     	 else if((rdata_counter[k][0] && ~(|rdata_counter[k][9:1]))) begin
     	    rlast_not_asserted_error_check_late[k]<=1;
     	    rlast_not_asserted_error_check_early[k]<=0;

     	 end
     	 else if((~rdata_counter[k][0]) && (|rdata_counter[k][9:1])) begin
     	    rlast_not_asserted_error_check_late[k]<=0;
     	    rlast_not_asserted_error_check_early[k]<=1;
     	 end
     	 else begin
     	    rlast_not_asserted_error_check_late[k]<=0;
     	    rlast_not_asserted_error_check_early[k]<=0;
     	 end
      end
   end



   always@(posedge clk) begin
      if(~resetn) begin
     	 rlast_not_asserted_error<=0;
      end
      else if(send_data_to_dram && rlast_not_asserted_error_check_late[desc_rdata_id] && ~rdata_read_out_rlast) begin
     	 rlast_not_asserted_error<=1;
      end
      else if(send_data_to_dram && rlast_not_asserted_error_check_early[desc_rdata_id] && rdata_read_out_rlast) begin
     	 rlast_not_asserted_error<=1;
      end
      else begin
     	 rlast_not_asserted_error<=0;
      end
   end




   //////////////////////////////////////////////////////////////////////////////
   //
   // Rresp status update. once "send_data_to_dram" is triggered, and desc_rdata_id
   // is fetched, update reigsters of corresponding desc with ruser, rresp & rdata
   //
   // In case of bad response, the first bad rresp (not okay) will be latched
   // and updated into registers, others will be ignored.
   //
   // The ruser in last beat of the transaction will be written into the register
   //
   //////////////////////////////////////////////////////////////////////////////

   assign req_avail = ownership_per_desc_rd;

   always@ (posedge clk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin
     	 if(~resetn) begin
     	    read_ruser[k]<=0;
     	    rresp_completed[k]<=0;
     	    descbus_rresp[k]<=0;
     	    ownership_per_desc_rd[k]<=0;
     	 end
     	 else if(send_data_to_dram_ff2 && (k==desc_rdata_id) && (rdata_counter[k]==0)) begin
     	    //This is the end of transfer ( rdata_counter ==0)
     	    //if (rdata_counter[desc_rdata_id]==0) begin
     	    //Update ownership
     	    if(rdata_read_out_rlast) begin
     	       ownership_per_desc_rd[k]<=1;
     	    end
     	    //update register to indicated that any one of the desc is done
     	    rresp_completed[k]<=1;//update_intr_comp_status_reg[desc_read_id]<=1;
     	    //Update registers for status
            descbus_rresp[k]<=rdata_read_out_first_bad_resp[k];
     	    //Send ruser
     	    read_ruser[k]<=rdata_read_out_ruser;
     	 end
     	 else begin
     	    rresp_completed[k]<=0;
     	    ownership_per_desc_rd[k]<=0;
     	    descbus_rresp[k]<=0;
     	    read_ruser[k]<=0;
     	 end
      end
   end


   always@( posedge clk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin
     	 if(~resetn) begin
     	    rdata_read_out_first_bad_resp[k]<=0;
     	    rdata_received_bad_response[k]<=0;
     	 end
     	 //If read_respnse is non zero store it in respective registers.
     	 //If first bad response comes, then store it
     	 else if(send_data_to_dram_ff2 && (k==desc_rdata_id)) begin
     	    if((rdata_read_out_resp!=0) && ~rdata_received_bad_response_ff[k]) begin
     	       rdata_read_out_first_bad_resp[k]<=rdata_read_out_resp;
     	       rdata_received_bad_response[k]<=1;
     	    end
     	    else if(rdata_counter[k]==0) begin
     	       rdata_read_out_first_bad_resp[k]<=0;
     	       rdata_received_bad_response[k]<=0;
     	    end
     	    else begin
     	       rdata_read_out_first_bad_resp[k]<=rdata_read_out_first_bad_resp[k];
     	    end		
     	 end
     	 else begin
     	    rdata_read_out_first_bad_resp[k]<=rdata_read_out_first_bad_resp[k];
     	    rdata_received_bad_response[k]<=rdata_received_bad_response[k];
     	 end
      end
   end

   always@( posedge clk) begin
      if(~resetn) begin
     	 rdata_received_bad_response_ff<=0;
      end else begin
     	 rdata_received_bad_response_ff<=rdata_received_bad_response;
      end
   end

   /////////////////////////////////////////////////////////////////////
   //
   // Update XUSER for both Writes (buser) and Reads (ruser)
   //
   /////////////////////////////////////////////////////////////////////
   
   always@( posedge clk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:uc2rb_xuser
     	 if(~resetn) begin
     	    descbus_ruser[k]<=0;
     	 end
     	 else begin
     	    descbus_ruser[k]<=read_ruser[k];
     	 end
      end
   end

   /////////////////////////////////////////////////////////////////////
   //
   // Update RID for Reads
   //
   /////////////////////////////////////////////////////////////////////
   
   always@( posedge clk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:uc2rb_rid
     	 if(~resetn) begin
     	    descbus_rid[k]<=0;
     	    descbus_rdata[k]<=0;
     	 end
     	 else if ((ar_valid_ready_desc_idx ==k) && (ar_valid_ready)) begin
     	    descbus_rid[k]<=ar_valid_ready_arid;
     	 end
      end
   end

   ////////////////////////////////////////////////////////////////////////////
   //
   // DRAM interface, to write rdata into RDATA_RAM.
   // offset counter (For DRAM address ) is maintained per unique ID.
   //
   ////////////////////////////////////////////////////////////////////////////


   always@ (posedge clk) begin
      if(~resetn) begin
     	 uc2rb_wr_data<=0;
     	 uc2rb_wr_we  <=0;
     	 //uc2rb_wr_bwe <=0;
     	 uc2rb_wr_addr<=0;
     	 uc2rb_wr_desc_id <= 0;
     	 arid_read_en_reg_valid<=0;
      end
      else if(send_data_to_dram ) begin
     	 //rdata counter will be decremented after this cycle
     	 //So, if desc_rdata_is ==x and that counter is =1,
     	 //means that is the last data we have got. 
     	 if (rdata_read_out_rlast) begin
     	    //If this is the last transfer, then 
     	    //Pop data from ARID FIFO. This will trigger
     	    // Ownership update
     	    
     	    arid_read_en_reg_valid<=1;
     	    // Assign write enables to only valid data

     	 end
     	 else begin
     	 end
     	 uc2rb_wr_data<=rdata_read_out_data;
     	 uc2rb_wr_we  <=1;
     	 uc2rb_wr_addr<=offset_addr[desc_rdata_id];
     	 uc2rb_wr_desc_id <= desc_rdata_id;
      end
      else begin
     	 uc2rb_wr_we  <=0;
     	 //uc2rb_wr_bwe <='h0;
     	 uc2rb_wr_desc_id <= 0;
     	 arid_read_en_reg_valid<=0;
      end
   end


   always@(posedge clk) begin
      if(~resetn) begin
     	 fifo_select_ff<=0;
      end
      else begin
     	 fifo_select_ff<=fifo_select;
      end
   end

   assign arid_read_en = arid_read_en_reg;

   always@ (posedge clk) begin
      if(~resetn) begin
     	 arid_read_en_reg<=0;
      end
      else if(arid_read_en_reg_valid) begin
     	 arid_read_en_reg[fifo_select_ff]<=1;
      end
      else begin
     	 arid_read_en_reg<=0;
      end
   end

   ///////////////////////////////////////////////////////////////////////////
   //
   // Offset counter Per descriptor. 
   // For any new request,
   //	wait for rd_request on AXI, once any request is initiated
   // 	assign corresponding offset_address to offser_addr register and make 
   // 	rdata_couter = arlen+1. 
   //
   // For any existing request,
   //	Increment offset counter and decrement rdata_counter
   //
   ////////////////////////////////////////////////////////////////////////////



   assign increment_rdata_offset_addr = 1;


   always@(posedge clk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin:offset_count
	 if(~resetn) begin
	    offset_addr[k]<=0;
	    rdata_counter[k]<=0;
	    len[k]<=0;
	 end
	 //If desc_rd_req_id comes on bus initialize the counter & Offset
	 //else if((desc_rd_req_id ==k) && (desc_rd_req_read_en_ff6)) begin
	 else if((ar_valid_ready_desc_idx ==k) && (ar_valid_ready)) begin
	    offset_addr[k]<=data_offset[k];
	    rdata_counter[k]<= ar_valid_ready_arlen+1;
	    len[k]<= ar_valid_ready_arlen;
	 end
	 else if(send_data_to_dram_ff && (desc_rdata_id==k)) begin
	    // AS an HM, it sees DUT DRAM, so addresses needs to be incremented accordingly
	    offset_addr[k]<=offset_addr[k]+ increment_rdata_offset_addr ;
	    rdata_counter[k]<=rdata_counter[k]-1;
	 end
	 else begin
	    offset_addr[k]<=offset_addr[k];
	 end
      end
   end
   

   //AW_W_fifo POP logic and USR_fifo POP logic

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 USR_rden_ff    <= 1'b0;
	 uc2rb_we  <= 1'b0;
	 uc2rb_addr  <= 'b0;
      end else begin
	 USR_rden_ff    <= USR_rden;
	 //uc2rb_we  <= (IS_DATA=="YES") ? USR_rden_ff : 'b0;
	 uc2rb_we  <= (ACE_CHANNEL=="MST_RD_RESP") ? uc2rb_wr_we : 'b0;
	 uc2rb_addr  <= uc2rb_wr_addr;
      end
   end

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 uc2rb_data   <= 'b0;
	 uc2rb_wstrb  <= 'b0;
      end else begin
	 //uc2rb_data   <= (IS_DATA=="YES") ? USR_dout[(USR_FIFO_WDATA_MSB) : (USR_FIFO_WDATA_LSB)] : 'b0; 
	 uc2rb_data   <= (ACE_CHANNEL=="MST_RD_RESP") ? uc2rb_wr_data : 'b0; 
	 //uc2rb_wstrb  <= (ACE_CHANNEL=="SLV_WR_REQ") ? USR_dout[(USR_FIFO_WSTRB_MSB) : (USR_FIFO_WSTRB_LSB)] : 'b0;
	 uc2rb_wstrb  <= 'b0;
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

   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
	 
	if ( (ACE_CHANNEL=="MST_RD_RESP") || (ACE_CHANNEL=="MST_WR_RESP") ) begin  //mst read/write response
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
	 
	if ( (ACE_CHANNEL=="MST_RD_RESP") || (ACE_CHANNEL=="MST_WR_RESP") ) begin  //mst read/write response
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
   //  hm2uc_xack_done
   //Description :
   //  Indication of wack/rack generation and data-transfer to host.
   //////////////////////

   generate

      `IF_INTFS_FULLACE
	 
	if (ACE_CHANNEL=="MST_RD_RESP") begin  //mst read response
	   assign hm2uc_xack_done = hm2uc_done_pulse; 
	end else begin
	   assign hm2uc_xack_done = 'b0; 
	end
      
      `END_INTFS
	 
	`IF_INTFS_LITEACE
    
	  assign hm2uc_xack_done = 'b0; 
      
      `END_INTFS                           
	endgenerate

   //////////////////////
   //Signal :
   //  txn_avail
   //Description :
   //  Transaction availablity indication from bridge to SW.
   //////////////////////

   generate
      `IF_INTFS_FULLACE


	if (ACE_CHANNEL=="MST_SN_REQ") begin  //mst Snoop request
	   assign txn_avail = (req_avail);

	end else if (ACE_CHANNEL=="MST_RD_RESP") begin  //mst read response
	   assign txn_avail = (int_mode_select_mode_0_1==1'b0) ? 
                              (xack_done)              //Mode-0
             : 
                              (hm2uc_xack_done);   //Mode-1

	end else if (ACE_CHANNEL=="MST_WR_RESP") begin  //mst write response
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


   assign error_ctl = update_intr_error_status_reg ;


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
