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
 *   This module handles ACE-usr interface and SW registers. 
 * 
 */

`include "ace_defines_common.vh"
`include "ace_defines_slv.vh"

module ace_slv_snoop_inf #(

                            parameter ACE_PROTOCOL                   = "FULLACE" 
                            
                            ,parameter ADDR_WIDTH                     = 64 
                            ,parameter XX_DATA_WIDTH                  = 128       
                            ,parameter SN_DATA_WIDTH                  = 128       
                            ,parameter ID_WIDTH                       = 16 
                            ,parameter AWUSER_WIDTH                   = 32 
                            ,parameter WUSER_WIDTH                    = 32 
                            ,parameter BUSER_WIDTH                    = 32 
                            ,parameter ARUSER_WIDTH                   = 32 
                            ,parameter RUSER_WIDTH                    = 32 
                            
                            ,parameter CACHE_LINE_SIZE                = 64 
                            ,parameter XX_MAX_DESC                    = 8         
                            ,parameter SN_MAX_DESC                    = 8         
                            ,parameter XX_RAM_SIZE                    = 16384     
                            ,parameter SN_RAM_SIZE                    = 512       

                            )(

                              //Clock and reset
                              input clk 
			      ,input resetn
   
			      //S_ACE_USR
			      ,output reg [ADDR_WIDTH-1:0] s_ace_usr_acaddr 
			      ,output reg [3:0] s_ace_usr_acsnoop 
			      ,output reg [2:0] s_ace_usr_acprot 
			      ,output reg s_ace_usr_acvalid 
			      ,input s_ace_usr_acready 
			      ,input [4:0] s_ace_usr_crresp 
			      ,input s_ace_usr_crvalid 
			      ,output reg s_ace_usr_crready 
			      ,input [SN_DATA_WIDTH-1:0] s_ace_usr_cddata 
			      ,input s_ace_usr_cdlast 
			      ,input s_ace_usr_cdvalid 
			      ,output s_ace_usr_cdready 
   
			      //RAM commands  
			      //CDDATA_RAM                               
			      ,output uc2rb_sn_we 
			      ,output [(SN_DATA_WIDTH/8)-1:0] uc2rb_sn_bwe //Generate all 1s always.     
			      ,output [(`CLOG2((SN_RAM_SIZE*8)/SN_DATA_WIDTH))-1:0] uc2rb_sn_addr 
			      ,output [SN_DATA_WIDTH-1:0] uc2rb_sn_data 
   
			      ,input sig_mode_select_sn_auto_order 
   
   
   
			      //Declare all signals
			      ,input [7:0] int_version_major_ver
			      ,input [7:0] int_version_minor_ver
			      ,input [7:0] int_bridge_type_type
			      ,input [6:0] int_bridge_config_addr_width
			      ,input [3:0] int_bridge_config_cache_line_size
			      ,input [7:0] int_bridge_config_id_width
			      ,input [2:0] int_bridge_config_data_width
			      ,input [31:0] int_max_desc_max_desc
			      ,input [0:0] int_reset_dut_srst_3
			      ,input [0:0] int_reset_dut_srst_2
			      ,input [0:0] int_reset_dut_srst_1
			      ,input [0:0] int_reset_dut_srst_0
			      ,input [0:0] int_reset_srst
			      ,input [0:0] int_mode_select_mode_0_1
			      ,input [7:0] int_sn_ownership_flip_flip
			      ,input [0:0] int_intr_status_sn_comp
			      ,input [0:0] int_intr_status_wr_comp
			      ,input [0:0] int_intr_status_rd_comp
			      ,input [0:0] int_intr_status_wr_txn_avail
			      ,input [0:0] int_intr_status_rd_txn_avail
			      ,input [0:0] int_intr_status_c2h
			      ,input [0:0] int_intr_status_error
			      ,input [7:0] int_sn_intr_comp_clear_clr_comp
			      ,input [7:0] int_sn_intr_comp_enable_en_comp
			      ,input [0:0] int_intr_error_status_err_1
			      ,input [0:0] int_intr_error_clear_clr_err_2
			      ,input [0:0] int_intr_error_clear_clr_err_1
			      ,input [0:0] int_intr_error_clear_clr_err_0
			      ,input [0:0] int_intr_error_enable_en_err_2
			      ,input [0:0] int_intr_error_enable_en_err_1
			      ,input [0:0] int_intr_error_enable_en_err_0
			      ,input [0:0] int_sn_req_order_valid_7
			      ,input [2:0] int_sn_req_order_desc_idx_7
			      ,input [0:0] int_sn_req_order_valid_6
			      ,input [2:0] int_sn_req_order_desc_idx_6
			      ,input [0:0] int_sn_req_order_valid_5
			      ,input [2:0] int_sn_req_order_desc_idx_5
			      ,input [0:0] int_sn_req_order_valid_4
			      ,input [2:0] int_sn_req_order_desc_idx_4
			      ,input [0:0] int_sn_req_order_valid_3
			      ,input [2:0] int_sn_req_order_desc_idx_3
			      ,input [0:0] int_sn_req_order_valid_2
			      ,input [2:0] int_sn_req_order_desc_idx_2
			      ,input [0:0] int_sn_req_order_valid_1
			      ,input [2:0] int_sn_req_order_desc_idx_1
			      ,input [0:0] int_sn_req_order_valid_0
			      ,input [2:0] int_sn_req_order_desc_idx_0
			      ,input [0:0] int_sn_req_push_push
			      ,output reg [7:0] int_sn_ownership_own
			      ,output reg [7:0] int_sn_intr_comp_status_comp
			      ,output reg [4:0] int_sn_status_resp_0_resp_3
			      ,output reg [4:0] int_sn_status_resp_0_resp_2
			      ,output reg [4:0] int_sn_status_resp_0_resp_1
			      ,output reg [4:0] int_sn_status_resp_0_resp_0
			      ,output reg [4:0] int_sn_status_resp_1_resp_7
			      ,output reg [4:0] int_sn_status_resp_1_resp_6
			      ,output reg [4:0] int_sn_status_resp_1_resp_5
			      ,output reg [4:0] int_sn_status_resp_1_resp_4
			      ,output reg [0:0] int_sn_resp_order_valid_7
			      ,output reg [2:0] int_sn_resp_order_desc_idx_7
			      ,output reg [0:0] int_sn_resp_order_valid_6
			      ,output reg [2:0] int_sn_resp_order_desc_idx_6
			      ,output reg [0:0] int_sn_resp_order_valid_5
			      ,output reg [2:0] int_sn_resp_order_desc_idx_5
			      ,output reg [0:0] int_sn_resp_order_valid_4
			      ,output reg [2:0] int_sn_resp_order_desc_idx_4
			      ,output reg [0:0] int_sn_resp_order_valid_3
			      ,output reg [2:0] int_sn_resp_order_desc_idx_3
			      ,output reg [0:0] int_sn_resp_order_valid_2
			      ,output reg [2:0] int_sn_resp_order_desc_idx_2
			      ,output reg [0:0] int_sn_resp_order_valid_1
			      ,output reg [2:0] int_sn_resp_order_desc_idx_1
			      ,output reg [0:0] int_sn_resp_order_valid_0
			      ,output reg [2:0] int_sn_resp_order_desc_idx_0
   
`include "int_snoop_desc_port.vh"


			      );

   localparam SN_DESC_IDX_WIDTH                                               = `CLOG2(SN_MAX_DESC);

   localparam CRRESP_WIDTH                                                  = 5;            //crresp width

   //Loop variables
   integer 			    i;
   integer 			    j;
   integer 			    k;

   //generate variable
   genvar 			    gi;

   //Descriptor 2d vectors
   wire [2:0] 			    int_sn_desc_n_attr_acprot [SN_MAX_DESC-1:0];
   wire [3:0] 			    int_sn_desc_n_attr_acsnoop [SN_MAX_DESC-1:0];
   wire [31:0] 			    int_sn_desc_n_acaddr_0_addr [SN_MAX_DESC-1:0];
   wire [31:0] 			    int_sn_desc_n_acaddr_1_addr [SN_MAX_DESC-1:0];
   wire [31:0] 			    int_sn_desc_n_acaddr_2_addr [SN_MAX_DESC-1:0];
   wire [31:0] 			    int_sn_desc_n_acaddr_3_addr [SN_MAX_DESC-1:0];

   //Snoop Channel

   wire [127:0] 		    sig_sn_desc_n_acaddr_addr [SN_MAX_DESC-1:0];

   wire 			    acnext;

   wire 			    gen_snoop;
   wire 			    start_snoop_tx;
   reg 				    start_snoop_tx_ff;
   reg 				    start_snoop_tx_ff2;

   wire 			    sn_request_en;
   reg 				    sn_request_en_ff;
   reg 				    sn_request_en_ff2;
   reg 				    sn_request_en_ff3;
   reg 				    sn_request_en_ff4;
   reg 				    sn_request_en_ff5;
   reg 				    sn_request_en_ff6;

   wire [(SN_DESC_IDX_WIDTH)-1:0]   sn_request_id;
   reg [(SN_DESC_IDX_WIDTH)-1:0]    sn_request_id_ff;
   reg [(SN_DESC_IDX_WIDTH)-1:0]    sn_request_id_ff2;

   wire [(SN_DESC_IDX_WIDTH)-1:0]   desc_sn_req_id;

   reg 				    crresp_fifo_write_en;
   reg 				    crresp_fifo_read_en;
   reg [4:0] 			    crresp_ff;
   reg 				    crresp_fifo_read_en_ff;
   reg 				    crresp_fifo_read_en_ff2;

   wire [4:0] 			    crresp_read_resp;

   reg 				    crresp_delay;
   reg [SN_MAX_DESC-1:0] 	    crresp_completed ;
   reg [63:0] 			    crresp_status ;
   wire [63:0] 			    update_uc2rb_status_crresp_reg;

   wire 			    crresp_valid;

   wire [31:0] 			    update_sn_intr_comp_status_reg;

   wire 			    crresp_fifo_empty;

   wire 			    send_crresp_to_host;

   wire 			    crresp_read_id;   //dummy variable

   reg [SN_MAX_DESC-1:0] 	    send_crresp_to_host_per_fifo;

   wire 			    sn_desc_allocation_in_progress;

   wire [(SN_DESC_IDX_WIDTH)-1:0]   sn_response_id_reg[SN_MAX_DESC-1:0];   
   wire [0:0] 			    fifo_id_sn_reg[SN_MAX_DESC-1:0];
   wire [SN_MAX_DESC-1:0] 	    fifo_id_sn_reg_valid;

   reg [SN_MAX_DESC-1:0] 	    snid_read_en_reg;
   reg [SN_MAX_DESC-1:0] 	    snid_read_en_reg_ff;
   reg [SN_MAX_DESC-1:0] 	    ownership_done_per_fifo[SN_MAX_DESC-1:0];

   reg [31:0] 			    update_ownership_reg;
   wire [31:0] 			    ownership_done;

   reg [SN_MAX_DESC-1:0] 	    ownership_per_desc_sn;

   //Keeping is +1
   wire [(SN_DESC_IDX_WIDTH):0]     snoop_response_desc_id;

   reg [(SN_DESC_IDX_WIDTH)-1:0]    snoop_response_desc_id_per_fifo[SN_MAX_DESC-1:0];








   ///////////////////////
   //2-D array of descriptor fields
   //////////////////////

`include "ace_usr_slv_snoop_desc_2d.vh"

   ///////////////////////
   //Description: 
   //  Write request order to SW
   //////////////////////

   generate

      for (gi=0; gi<=SN_MAX_DESC-1; gi=gi+1) begin: gen_sig_sn_desc_n_acaddr_addr
	 assign sig_sn_desc_n_acaddr_addr[gi] = {  int_sn_desc_n_acaddr_3_addr[gi]
						   ,int_sn_desc_n_acaddr_2_addr[gi]
						   ,int_sn_desc_n_acaddr_1_addr[gi]
						   ,int_sn_desc_n_acaddr_0_addr[gi] };
      end

   endgenerate  

   ///////////////////////////////////////////////////////////////////////////////////////////////////////
   /// 
   /// START of Snoop Channel : it fetches all the AXI Read requests that are on bus and places corresponding 
   /// ARID into FIFO. There are SN_MAX_DESC number of Fifos, each represents an unique ID. 
   /// When read response arrives, a fifo is popped based on RID, and corresponding Desc ID's 
   /// RDATA_RAM/Registers are updated with rdata/response
   ///
   //////////////////////////////////////////////////////////////////////////////////////////////////////




   axid_store #(
     		.MAX_DESC(SN_MAX_DESC), 
     		.M_AXI_USR_ID_WIDTH(1)
     		)
   snoop_store (
      
     		// Inputs
     		.axi_aclk	(clk),
     		.axi_aresetn	(resetn),
      
     		//AXID on the BUS will be stored into Fifo
     		.m_axi_usr_axid	(1'b0),
     		.axid_read_en	(snid_read_en_reg),
      
     		//AWNEXT to indicated sampling of AWID
     		.axnext		(acnext),
      
     		.fifo_id_reg_valid_ff	(fifo_id_sn_reg_valid),
      
     		//From Read Fifo
     		.desc_req_id		(desc_sn_req_id),
      
     		.axid_response_id0	(sn_response_id_reg[0]),
     		.axid_response_id1	(sn_response_id_reg[1]),
     		.axid_response_id2	(sn_response_id_reg[2]),
     		.axid_response_id3	(sn_response_id_reg[3]),
     		.axid_response_id4	(sn_response_id_reg[4]),
     		.axid_response_id5	(sn_response_id_reg[5]),
     		.axid_response_id6	(sn_response_id_reg[6]),
     		.axid_response_id7	(sn_response_id_reg[7]),
      
     		.fifo_id_reg0	(fifo_id_sn_reg[0]),
     		.fifo_id_reg1	(fifo_id_sn_reg[1]),
     		.fifo_id_reg2	(fifo_id_sn_reg[2]),
     		.fifo_id_reg3	(fifo_id_sn_reg[3]),
     		.fifo_id_reg4	(fifo_id_sn_reg[4]),
     		.fifo_id_reg5	(fifo_id_sn_reg[5]),
     		.fifo_id_reg6	(fifo_id_sn_reg[6]),
     		.fifo_id_reg7	(fifo_id_sn_reg[7]),
      
     		.desc_allocation_in_progress(sn_desc_allocation_in_progress)
     		);


   /////////////////////////////////////////////////////////////////////
     //
   // TO sync with snid_read_en pulse
   //
   /////////////////////////////////////////////////////////////////////

   always@ (posedge clk) begin
      for(k=0;k<SN_MAX_DESC;k=k+1) begin:snid_read_for
     	 if(~resetn) begin
     	    snid_read_en_reg_ff[k]<=0;
     	 end
     	 else begin
     	    snid_read_en_reg_ff[k]<=snid_read_en_reg[k];
     	 end
      end
   end


   //////////////////////////////////////////////////////////////////////
   //
   // Update Ownership, once any SNID_response_id is popped	
   // It indicateds that BID is found in one of the FIFO(16 fifos)	
   //
   /////////////////////////////////////////////////////////////////////

   always@(posedge clk) begin
      for(k=0;k<SN_MAX_DESC;k=k+1) begin:ownership_update
     	 if(~resetn) begin
     	    ownership_done_per_fifo[k]<='h0;
     	 end
     	 else if(snid_read_en_reg_ff[k]) begin
     	    ownership_done_per_fifo[k][sn_response_id_reg[k]]<=1;
     	 end
     	 else begin
     	    ownership_done_per_fifo[k]<=0;
     	 end
      end
   end



   //////////////////////////////////////////////////////////////////
   //
   // acnext: its acvalid && acready. 
   //
   /////////////////////////////////////////////////////////////////

   ////////////////////////////////////////////////////////////////
   //
   // START of Delaying_id SNOOP. So That other blocks are
   // Synchronized. 
   //
   ////////////////////////////////////////////////////////////////


   always@(posedge clk) begin
      if(~resetn) begin
     	 sn_request_id_ff<=0;
      end
      else if(sn_request_en_ff) begin
     	 sn_request_id_ff<=sn_request_id;
      end
      else begin
     	 sn_request_id_ff<=sn_request_id_ff;
      end
   end


   always@(posedge clk) begin
      sn_request_id_ff2<=sn_request_id_ff;
   end

   assign desc_sn_req_id = sn_request_id_ff2;

   //////////////////////////////////////////////////////////////////////////////
   //
   // Flopping all ACE Attrib before giving out on the BUS 
   //
   //////////////////////////////////////////////////////////////////////////////

   always@ (posedge clk) begin
      
      //Snoop Channel
      s_ace_usr_acaddr   <= sig_sn_desc_n_acaddr_addr     [desc_sn_req_id][ADDR_WIDTH-1:0];     
      s_ace_usr_acsnoop  <= int_sn_desc_n_attr_acsnoop    [desc_sn_req_id];
      s_ace_usr_acprot   <= int_sn_desc_n_attr_acprot     [desc_sn_req_id];

   end






   assign acnext = s_ace_usr_acready && s_ace_usr_acvalid;

   //s_ace_usr_acvalid
   always @(posedge clk)                                   
     begin                                                                
        //In Reset keep s_ace_usr_acvalid low                                                           
        if  (resetn == 0 )                                           
          begin                                                            
             s_ace_usr_acvalid <= 1'b0;                                           
          end                      
        //If Tx is started then assert s_ace_usr_acvalid                                        
        else if (~s_ace_usr_acvalid && gen_snoop)                 
          begin                                                            
             s_ace_usr_acvalid <= 1'b1;                                           
          end
        //once we get s_ace_usr_acready, deassert s_ace_usr_acvalid                                                              
        else if  (s_ace_usr_acready && s_ace_usr_acvalid)                             
          begin                                                            
             s_ace_usr_acvalid <= 1'b0;                                           
          end                                                              
        else                                                               
          s_ace_usr_acvalid <= s_ace_usr_acvalid;                                      
     end          

   ////////////////////////////////////////////////////////////////
   //
   // START of Delaying_En SNOOP En. So That other blocks are
   // Synchronized. 
   //
   ////////////////////////////////////////////////////////////////

   `FF_RSTLOW(clk, resetn, sn_request_en     , sn_request_en_ff )
   `FF_RSTLOW(clk, resetn, sn_request_en_ff     , sn_request_en_ff2 )
   // Triggering ~ff3 will generate/latch axi attrib on the ACE Bus for current SNOOP
   `FF_RSTLOW(clk, resetn, sn_request_en_ff2     , sn_request_en_ff3 )
   `FF_RSTLOW(clk, resetn, sn_request_en_ff3     , sn_request_en_ff4 )
   `FF_RSTLOW(clk, resetn, sn_request_en_ff4     , sn_request_en_ff5 )
   `FF_RSTLOW(clk, resetn, sn_request_en_ff5     , sn_request_en_ff6 )

   
   assign start_snoop_tx = sn_request_en_ff3  ;
   
   

   // Delaying start_snoop as need some time to setup
   // ACE bus before acvalid comes
   always @(posedge clk)
     begin
     	start_snoop_tx_ff <=start_snoop_tx;
     	start_snoop_tx_ff2<=start_snoop_tx_ff;
     end

   //This will actually trigger ACVALID after one cycle	
   assign gen_snoop 	= start_snoop_tx_ff2;



   ///////////////////////
   //Instantiate snoop descriptor request ID generator
   //////////////////////

   ace_desc_generator #(
			.ACE_PROTOCOL      (ACE_PROTOCOL)
			,.MAX_DESC          (SN_MAX_DESC)
			,.TXN_TYP           ("SN")
			)sn_ace_desc_generator (
						.request_id                                    (sn_request_id)
						,.request_en                                    (sn_request_en)
						,.clk                                           (clk)
						,.resetn                                        (resetn)
						,.aznext                                        (acnext)
						,.desc_allocation_in_progress                   (sn_desc_allocation_in_progress)
						,.sig_mode_select_zz_auto_order                 (sig_mode_select_sn_auto_order)
						,.int_zz_ownership_own                          (int_sn_ownership_own)
						,.int_zz_req_order_valid_7                      (int_sn_req_order_valid_7)
						,.int_zz_req_order_desc_idx_7                   (int_sn_req_order_desc_idx_7)
						,.int_zz_req_order_valid_6                      (int_sn_req_order_valid_6)
						,.int_zz_req_order_desc_idx_6                   (int_sn_req_order_desc_idx_6)
						,.int_zz_req_order_valid_5                      (int_sn_req_order_valid_5)
						,.int_zz_req_order_desc_idx_5                   (int_sn_req_order_desc_idx_5)
						,.int_zz_req_order_valid_4                      (int_sn_req_order_valid_4)
						,.int_zz_req_order_desc_idx_4                   (int_sn_req_order_desc_idx_4)
						,.int_zz_req_order_valid_3                      (int_sn_req_order_valid_3)
						,.int_zz_req_order_desc_idx_3                   (int_sn_req_order_desc_idx_3)
						,.int_zz_req_order_valid_2                      (int_sn_req_order_valid_2)
						,.int_zz_req_order_desc_idx_2                   (int_sn_req_order_desc_idx_2)
						,.int_zz_req_order_valid_1                      (int_sn_req_order_valid_1)
						,.int_zz_req_order_desc_idx_1                   (int_sn_req_order_desc_idx_1)
						,.int_zz_req_order_valid_0                      (int_sn_req_order_valid_0)
						,.int_zz_req_order_desc_idx_0                   (int_sn_req_order_desc_idx_0)
						,.int_zz_req_push_push                          (int_sn_req_push_push)
						);

   //Snoop resp
   //AXI s_ace_usr_crready 
   always @(posedge clk)                                   
     begin                                                                
        //In Reset keep valid low                                                           
        if  (resetn == 0 )                                           
          begin                                                            
             s_ace_usr_crready <= 1'b0;                                           
          end                      
        //If Tx is started then assert valid                                        
        else if  (s_ace_usr_crvalid && ~s_ace_usr_crready)                 
          begin                                                            
             s_ace_usr_crready <= 1'b1;                                           
          end
        // deassert valid once wlast comes                                                              
        else if  (s_ace_usr_crready)                             
          begin                                                            
             s_ace_usr_crready <= 1'b0;
          end                                                              
        else                                                               
          s_ace_usr_crready <= s_ace_usr_crready;                                      
     end  

   ////////////////////////////////////////////////////////////////////////////
   //
   // It updates crresp once descriptor_id
   // is found in Fifo.
   //
   ////////////////////////////////////////////////////////////////////////////


   assign send_crresp_to_host= |send_crresp_to_host_per_fifo;
   assign ownership_done[SN_MAX_DESC-1:0]= ownership_per_desc_sn;

   // crresp_valid 
   assign crresp_valid = s_ace_usr_crvalid && s_ace_usr_crready;

   ///////////////////////////////////////////
   //
   // When bvalid is high, flop response signals
   //
   ///////////////////////////////////////////

   always@ (posedge clk) begin
      
      if(crresp_valid) begin
     	 crresp_ff<=s_ace_usr_crresp;
      end
      else begin
     	 crresp_ff<=crresp_ff;
      end
   end


   //////////////////////////////////////////////////
   //
   // When bvalid is high, assert crresp_fifo_write_en
   //
   ///////////////////////////////////////////////////

   always@( posedge clk) begin
      if(~resetn) begin
     	 crresp_fifo_write_en<=0;		
      end
      else if (crresp_valid) begin
     	 crresp_fifo_write_en<=1;		
      end
      else begin
     	 crresp_fifo_write_en<=0;		
      end
   end



   ///////////////////////////////////////////////////////////////
   //
   // Once crresp_fifo is full, pop it and wait for one more cycle
   // before popping next crresp 
   //
   ////////////////////////////////////////////////////////////////


   always@( posedge clk) begin
      if(~resetn) begin
     	 crresp_fifo_read_en<=0;
     	 crresp_delay<=0;		
      end
      else if (~crresp_fifo_empty && ~crresp_delay ) begin
     	 crresp_fifo_read_en<=1;		
     	 crresp_delay<=1;		
      end
      else if (crresp_delay) begin
     	 crresp_fifo_read_en<=0;
     	 crresp_delay<=0;		
      end
      else begin
     	 crresp_fifo_read_en<=0;
      end
      
   end	
   


   ////////////////////////////////////////////////////////////////
   //
   // crresp_fifo
   //
   ///////////////////////////////////////////////////////////////

   sync_fifo  #(.DEPTH((SN_MAX_DESC)), .WIDTH(CRRESP_WIDTH)) 
   crresp_fifo 
     (
      .clk(clk),
      .rst_n(resetn),
      .din(crresp_ff),
      .wren(crresp_fifo_write_en),
      .empty(crresp_fifo_empty),
      .full(),
      .dout(crresp_read_resp),
      .rden(crresp_fifo_read_en)
      );



   ////////////////////////////////////////////////////////////
   //
   // Synchronize fifo_read_en with id_out.
   //
   ///////////////////////////////////////////////////////////

   always@ (posedge clk) begin
      crresp_fifo_read_en_ff<=crresp_fifo_read_en;
      crresp_fifo_read_en_ff2<=crresp_fifo_read_en_ff;
      
   end

   /////////////////////////////////////////////////////////////////////////
   //
   // BID comparison: It compares id popped from crresp_fifo with one of 
   // the SN_MAX_DESC FIFOs. If there is a match, crresp is sent to the corresponding
   // desc_id (From FIFO Out )
   //
   // Here, desc_id is found by looking at Fifo's data bus,
   // as fifo is used in such a way that it always point to the NEXT data  
   // So, even without popping from FIFO, desc_id can be read.
   //
   // **It is useful in read case, when there is a need to fetch multiple rdata
   // with same rid and decrement counters of each descriptor.
   //
   /////////////////////////////////////////////////////////////////////////

   assign crresp_read_id = 'b0;

   always@( posedge clk) begin
      for(k=0;k<SN_MAX_DESC;k=k+1) begin:gen_crresp
     	 if(~resetn) begin
     	    snid_read_en_reg[k]<=0;
     	    send_crresp_to_host_per_fifo[k]<=0;	
     	    snoop_response_desc_id_per_fifo[k]<=0;	
     	 end 
     	 else if(crresp_fifo_read_en_ff) begin
     	    //Check in each fifo if bid matches with register.
     	    //If yes then asser snid_read_en of corresponding fifo
     	    if((crresp_read_id==fifo_id_sn_reg[k]) && fifo_id_sn_reg_valid[k]) begin
     	       snoop_response_desc_id_per_fifo[k]<=sn_response_id_reg[k];
     	       send_crresp_to_host_per_fifo[k]<=1;	
     	       //This is per Fifo
     	       snid_read_en_reg[k]<=1;
     	    end
     	    else begin
     	       snoop_response_desc_id_per_fifo[k]<=0;	
     	    end
     	 end
     	 else begin
     	    snid_read_en_reg[k]<=0;
     	    send_crresp_to_host_per_fifo[k]<=0;	
     	 end
      end
   end


   ////////////////////////////////////////////////////////////////////////
   //
   // Combining 16 FIFOs and ORed as only single fifo will have unique ID
   // only single will be active at a time
   //
   ////////////////////////////////////////////////////////////////////////

   assign snoop_response_desc_id= 	( ( (SN_MAX_DESC>=1)  ? snoop_response_desc_id_per_fifo[0] : 'b0 ) |
     			 		  ( (SN_MAX_DESC>=2)  ? snoop_response_desc_id_per_fifo[1] : 'b0 ) |	
     			 		  ( (SN_MAX_DESC>=3)  ? snoop_response_desc_id_per_fifo[2] : 'b0 ) |	
     			 		  ( (SN_MAX_DESC>=4)  ? snoop_response_desc_id_per_fifo[3] : 'b0 ) |	
     			 		  ( (SN_MAX_DESC>=5)  ? snoop_response_desc_id_per_fifo[4] : 'b0 ) |	
     			 		  ( (SN_MAX_DESC>=6)  ? snoop_response_desc_id_per_fifo[5] : 'b0 ) |	
     			 		  ( (SN_MAX_DESC>=7)  ? snoop_response_desc_id_per_fifo[6] : 'b0 ) |	
     			 		  ( (SN_MAX_DESC>=8)  ? snoop_response_desc_id_per_fifo[7] : 'b0 ) );



   

   ////////////////////////////////////////////////////////////////////
   //
   //  Updating crresp status to register
   //
   ///////////////////////////////////////////////////////////////////

   always@(posedge clk) begin
      if(~resetn) begin
     	 crresp_completed<=0;
     	 ownership_per_desc_sn<=0;
     	 crresp_status<=0;	
      end
      else if(send_crresp_to_host) begin
     	 //Indicate that crresp is completed in 
     	 //Intr_comp_reg.
     	 crresp_completed[snoop_response_desc_id]<=1;
     	 //Indicate that Ownership is done for this Descriptor
     	 ownership_per_desc_sn[snoop_response_desc_id]<=1;
     	 //Write back crresp into register. (In status_resp reg )
     	 crresp_status[(snoop_response_desc_id<<1)]<=crresp_read_resp[0];	
     	 crresp_status[(snoop_response_desc_id<<1)+1]<=crresp_read_resp[1];	
     	 crresp_status[(snoop_response_desc_id<<1)+2]<=crresp_read_resp[2];	
     	 crresp_status[(snoop_response_desc_id<<1)+3]<=crresp_read_resp[3];	
     	 crresp_status[(snoop_response_desc_id<<1)+4]<=crresp_read_resp[4];	
      end
      else begin
     	 crresp_completed<=0;
     	 ownership_per_desc_sn<=0;
     	 crresp_status<=0;	
      end
   end




   /////////////////////////////////////////////////////////////////////////////////
   //
   // crresp  status update
   //
   /////////////////////////////////////////////////////////////////////////////////

   assign update_uc2rb_status_crresp_reg =  crresp_status  ; 

   always@( posedge clk)begin
      if(~resetn) begin
     	 //uc2rb_status_resp_reg<= 0;
         
	 int_sn_status_resp_1_resp_7  <=  'b0;
	 int_sn_status_resp_1_resp_6  <=  'b0;
	 int_sn_status_resp_1_resp_5  <=  'b0;
	 int_sn_status_resp_1_resp_4  <=  'b0;
	 int_sn_status_resp_0_resp_3  <=  'b0;
	 int_sn_status_resp_0_resp_2  <=  'b0;
	 int_sn_status_resp_0_resp_1  <=  'b0;
	 int_sn_status_resp_0_resp_0  <=  'b0;

      end
      else begin
	 //	 uc2rb_status_resp_reg<=update_uc2rb_status_crresp_reg;
	 
	 int_sn_status_resp_1_resp_7  <=  update_uc2rb_status_crresp_reg[60:56];
	 int_sn_status_resp_1_resp_6  <=  update_uc2rb_status_crresp_reg[52:48];
	 int_sn_status_resp_1_resp_5  <=  update_uc2rb_status_crresp_reg[44:40];
	 int_sn_status_resp_1_resp_4  <=  update_uc2rb_status_crresp_reg[36:32];
	 int_sn_status_resp_0_resp_3  <=  update_uc2rb_status_crresp_reg[28:24];
	 int_sn_status_resp_0_resp_2  <=  update_uc2rb_status_crresp_reg[20:16];
	 int_sn_status_resp_0_resp_1  <=  update_uc2rb_status_crresp_reg[12:8];
	 int_sn_status_resp_0_resp_0  <=  update_uc2rb_status_crresp_reg[4:0];

      end
   end

   //////////////////////////////////////////////////////////////////////
   //
   // Update Ownership. A pulse on Update_ownership_reg will 
   // Set Ownership_reg ( Txn is done either Rd/Wr )
   // A pulse on Ownership_flip_reg will trigger Rd/Wr generation
   //
   ///////////////////////////////////////////////////////////////////////

   always@ (posedge clk) begin
      for(k=0;k<SN_MAX_DESC;k=k+1) begin 
     	 if(~resetn) begin
     	    int_sn_ownership_own[k] <= 0;
     	 end
     	 else if (~int_sn_ownership_own[k]) begin
     	    int_sn_ownership_own[k]<=int_sn_ownership_flip_flip[k];
     	 end
     	 else begin
     	    if (update_ownership_reg[k]) begin
     	       int_sn_ownership_own[k] <= ~update_ownership_reg[k];
     	    end
     	    else begin
     	       int_sn_ownership_own[k] <= int_sn_ownership_own[k];
     	    end
     	 end 
      end 
   end 


   ///////////////////////////////////////////////////////////////////
   //
   // Ownership done based on WR/RD responses, to upadte ownership_reg
   //
   ///////////////////////////////////////////////////////////////////

   always@(posedge clk) begin
      
      for(k=0;k<SN_MAX_DESC;k=k+1) begin
     	 if(~resetn) begin
     	    update_ownership_reg[k]<=0;
     	 end
     	 else if(int_sn_ownership_flip_flip[k]) begin
     	    update_ownership_reg[k]<=0;
     	 end
     	 else if (ownership_done[k]) begin
     	    update_ownership_reg[k]<=1;
     	 end
     	 else begin
     	    update_ownership_reg[k]<=update_ownership_reg[k];
     	 end
      end 
   end 



   /////////////////////////////////////////////////////////////////////////////
   //
   // Intr_comp_status_reg : Bits are set to 1, if any of the 
   // Txn is completed either crresp
   // Tying of Write Enables to 1, as Set/Reset is based on Pulse.
   //
   //////////////////////////////////////////////////////////////////////////////

   always@ (posedge clk) begin
      for(k=0;k<SN_MAX_DESC;k=k+1) begin
     	 if(~resetn) begin
     	    int_sn_intr_comp_status_comp[k] <= 0;
     	 end
     	 else if (~int_sn_intr_comp_status_comp[k]) begin
     	    int_sn_intr_comp_status_comp[k]<=update_sn_intr_comp_status_reg[k];
     	 end
     	 else begin
     	    if (int_sn_intr_comp_clear_clr_comp[k]) begin
     	       int_sn_intr_comp_status_comp[k] <= 0;//
     	    end
     	    else begin
     	       int_sn_intr_comp_status_comp[k]<= int_sn_intr_comp_status_comp[k];
     	    end
     	    
     	 end 
      end 
   end 



   //////////////////////////////////////////////////////////////////////////////////
   //
   // 	Intr Comp status update 
   //
   /////////////////////////////////////////////////////////////////////////////////

   generate 
      for(gi=0;gi<SN_MAX_DESC;gi=gi+1) begin:update_sn_intr_comp_status_reg_for
     	 assign update_sn_intr_comp_status_reg[gi]=	crresp_completed[gi] ;
      end
   endgenerate





endmodule 


// Local Variables:
// verilog-library-directories:("./")
// End:

