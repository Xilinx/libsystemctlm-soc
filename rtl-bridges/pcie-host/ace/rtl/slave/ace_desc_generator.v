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

module ace_desc_generator #(

                            parameter ACE_PROTOCOL                   = "FULLACE" 
                            
                            ,parameter MAX_DESC                       = 8         
                            ,parameter TXN_TYP                        = "SN"   //Allowed values : "SN" (,"RD", "WR")

                            )(

                              //Clock and reset
                              input clk 
			      ,input resetn
			      // it indicates azvalid/azready handshake
			      ,input aznext
   
			      // wdata_pending_fifo_full indicateds that all axi requests
			      // are now filled into fifo no more are allowed ( Ideally should
			      // Never be full as ownership is allowed til MAX_DESC
			      //,input 						  wdata_pending_fifo_full
   
			      // When request is begin sent to bus
			      // other blocks are processing it for futher info
			      // So halting fetching new desc ID untill current one
			      // is processed by other blocks
			      ,input desc_allocation_in_progress
   
   
			      // Outputs
			      // For other blocks to know which DESC ID is to be
			      // placed on BUS
			      ,output [(`CLOG2(MAX_DESC))-1:0] request_id
   
			      // Corresponding Enables when en =1 on the next cycle
			      // *request_id is valid. This is basically same as FIFO EN
			      ,output request_en
   
			      // used to create a pulse once any ownership is given
			      ,input [MAX_DESC-1:0] int_zz_ownership_own
   
			      ,input sig_mode_select_zz_auto_order 
   
			      ,input [0:0] int_zz_req_order_valid_7
			      ,input [2:0] int_zz_req_order_desc_idx_7
			      ,input [0:0] int_zz_req_order_valid_6
			      ,input [2:0] int_zz_req_order_desc_idx_6
			      ,input [0:0] int_zz_req_order_valid_5
			      ,input [2:0] int_zz_req_order_desc_idx_5
			      ,input [0:0] int_zz_req_order_valid_4
			      ,input [2:0] int_zz_req_order_desc_idx_4
			      ,input [0:0] int_zz_req_order_valid_3
			      ,input [2:0] int_zz_req_order_desc_idx_3
			      ,input [0:0] int_zz_req_order_valid_2
			      ,input [2:0] int_zz_req_order_desc_idx_2
			      ,input [0:0] int_zz_req_order_valid_1
			      ,input [2:0] int_zz_req_order_desc_idx_1
			      ,input [0:0] int_zz_req_order_valid_0
			      ,input [2:0] int_zz_req_order_desc_idx_0
			      ,input [0:0] int_zz_req_push_push



			      );


   localparam DESC_IDX_WIDTH                                               = `CLOG2(MAX_DESC);

   //Loop variables
   integer 			    i;
   integer 			    j;
   integer 			    k;

   //generate variable
   genvar 			    gi;

   // Regs & Wire

   reg [MAX_DESC-1:0] 		    OWNERSHIP_reg_ff;
   reg [MAX_DESC-1:0] 		    OWNERSHIP_reg_ff2;
   reg [MAX_DESC-1:0] 		    desc_fifo_write_pend;
   reg [MAX_DESC-1:0] 		    desc_fifo_write_done;

   reg 				    desc_alloc_fifo_state;

   wire [MAX_DESC-1:0] 		    OWNERSHIP_reg_pulse;



   wire 			    DESC_REQ_ID_wren;	
   reg 				    DESC_REQ_ID_rden;	
   wire [DESC_IDX_WIDTH-1:0] 	    DESC_REQ_ID_din;	
   //reg  [DESC_IDX_WIDTH-1:0]                                               DESC_REQ_ID_din_sig[MAX_DESC-1:0];	
   reg [MAX_DESC-1:0] 		    DESC_REQ_ID_din_sig[DESC_IDX_WIDTH-1:0];	
   wire [DESC_IDX_WIDTH-1:0] 	    DESC_REQ_ID_dout;	
   wire 			    DESC_REQ_ID_full;	
   wire 			    DESC_REQ_ID_empty;

   wire [DESC_IDX_WIDTH-1:0] 	    REQ_ORDER_dout;
   wire [DESC_IDX_WIDTH-1:0] 	    REQ_ORDER_dout_pre;
   wire 			    REQ_ORDER_dout_pre_valid;
   wire 			    REQ_ORDER_full;
   wire 			    REQ_ORDER_empty;
   wire 			    REQ_ORDER_wren;
   reg 				    REQ_ORDER_rden;
   wire [DESC_IDX_WIDTH-1:0] 	    REQ_ORDER_din;

   reg [MAX_DESC-1:0] 		    req_valid;

   wire 			    req_gnt_vld;
   wire [DESC_IDX_WIDTH-1:0] 	    req_gnt_idx;

   wire 			    req_auto_gnt_vld;
   wire [DESC_IDX_WIDTH-1:0] 	    req_auto_gnt_idx;

   reg 				    int_zz_req_push_push_ff;

   reg [DESC_IDX_WIDTH-1:0] 	    sig_zz_req_order_desc_idx[MAX_DESC-1:0];
   reg [MAX_DESC-1:0] 		    sig_zz_req_order_valid;

   reg [MAX_DESC-1:0] 		    zzreq_init;
   reg [MAX_DESC-1:0] 		    zzreq_init_req;
   reg [MAX_DESC-1:0] 		    zzreq_init_req_proc;  //process bresp init request 
   reg [MAX_DESC-1:0] 		    zzreq_init_ser;
   reg [MAX_DESC-1:0] 		    zzreq_init_serfailed;  //it is just valid for value-1 of zzreq_init_req_onehot. //Serice failed.
   wire [MAX_DESC-1:0] 		    zzreq_init_req_onehot;  //One hot Vector
   reg [MAX_DESC-1:0] 		    zzreq_init_ff;

   reg [MAX_DESC-1:0] 		    int_zz_ownership_own_ff;

   reg 				    fetch_req_fifo_state;

   ////////////////////////////////////////////////
   //
   //	write and read request_id out
   //
   //////////////////////////////////////////////

   assign request_id = DESC_REQ_ID_dout;

   assign request_en = DESC_REQ_ID_rden;

   ///////////////////////////////////////////////////
   //
   // Creating Pulse from ownership reg
   //
   //////////////////////////////////////////////////

   `FF_RSTLOW(clk,resetn, int_zz_ownership_own[MAX_DESC-1:0], OWNERSHIP_reg_ff )
   `FF_RSTLOW(clk,resetn, OWNERSHIP_reg_ff, OWNERSHIP_reg_ff2 )

   assign OWNERSHIP_reg_pulse = (int_zz_ownership_own & ~OWNERSHIP_reg_ff2);


   ///////////////////////////////////////////////////////////////////////////
   //
   // Detecting Ownership pulse and putting it in write_pending register
   //
   ///////////////////////////////////////////////////////////////////////////
   //generate
   //       for(gi=0;gi<MAX_DESC;gi=gi+1) begin:desc_fifo_pen
   //     	 always @ (posedge clk)
   //     	   begin
   //     		  
   //     		  if(~resetn) begin
   //     			 desc_fifo_write_pend[gi] <= 0;
   //     		  end
   //     		  else if(OWNERSHIP_reg_pulse[gi] && (~desc_fifo_write_pend[gi])) begin
   //     			 desc_fifo_write_pend[gi]<=1;
   //     		  end
   //     		  else if (desc_fifo_write_done[gi]) begin
   //     			 desc_fifo_write_pend[gi]<=0;
   //     		  end
   //     	   end
   //       end
   //endgenerate

   ///////////////////////
   //Description: 
   //  request order from SW
   //////////////////////


   //PENDING : Write min cycles required btw two int_zz_req_push_push

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_sig_zz_req_order_desc_idx_reset
	    sig_zz_req_order_desc_idx[i] <= 'b0;
	 end
	 sig_zz_req_order_valid <= 'b0;  
      end else if (int_zz_req_push_push==1'b1 && int_zz_req_push_push_ff==1'b0) begin //Positive edge detection
	 sig_zz_req_order_valid[7]      <= int_zz_req_order_valid_7    ; 
	 sig_zz_req_order_desc_idx[7]   <= int_zz_req_order_desc_idx_7 ; 
	 sig_zz_req_order_valid[6]      <= int_zz_req_order_valid_6    ; 
	 sig_zz_req_order_desc_idx[6]   <= int_zz_req_order_desc_idx_6 ; 
	 sig_zz_req_order_valid[5]      <= int_zz_req_order_valid_5    ; 
	 sig_zz_req_order_desc_idx[5]   <= int_zz_req_order_desc_idx_5 ; 
	 sig_zz_req_order_valid[4]      <= int_zz_req_order_valid_4    ; 
	 sig_zz_req_order_desc_idx[4]   <= int_zz_req_order_desc_idx_4 ; 
	 sig_zz_req_order_valid[3]      <= int_zz_req_order_valid_3    ; 
	 sig_zz_req_order_desc_idx[3]   <= int_zz_req_order_desc_idx_3 ; 
	 sig_zz_req_order_valid[2]      <= int_zz_req_order_valid_2    ; 
	 sig_zz_req_order_desc_idx[2]   <= int_zz_req_order_desc_idx_2 ; 
	 sig_zz_req_order_valid[1]      <= int_zz_req_order_valid_1    ; 
	 sig_zz_req_order_desc_idx[1]   <= int_zz_req_order_desc_idx_1 ; 
	 sig_zz_req_order_valid[0]      <= int_zz_req_order_valid_0    ; 
	 sig_zz_req_order_desc_idx[0]   <= int_zz_req_order_desc_idx_0 ; 
      end
   end


   //REQ_ORDER_fifo PUSH logic

   `FF_RSTLOW(clk,resetn,int_zz_req_push_push,int_zz_req_push_push_ff)

   generate        		
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_gi
	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       req_valid[gi] <= 1'b0;  
	    end else if (int_zz_req_push_push==1'b1 && int_zz_req_push_push_ff==1'b0 && sig_zz_req_order_valid[gi]==1'b1) begin //Positive edge detection
	       req_valid[gi] <= 1'b1;
	    end else begin
	       req_valid[gi] <= 1'b0;
	    end
	 end
      end
   endgenerate 


   //////////////////////
   //Grant Controller
   //Description :
   //  There can be multiple bits of value '1' in req_valid. Grant allocator
   //  grants to each of the bits but one after the other, so that it can
   //  be pushed to REQ_ORDER_fifo.
   //////////////////////

   grant_controller #(
		      .MAX_DESC		                        (MAX_DESC)
		      ,.EDGE_TYP		                        (1)      //Posedge
		      ) zz_req_grant_controller (
						 .det_out                                       ()
						 ,.req_out                                       ()
						 ,.gnt_out                                       ()
						 ,.gnt_vld                                       (req_gnt_vld)
						 ,.gnt_idx                                       (req_gnt_idx)
						 ,.clk		                                (clk)
						 ,.rst_n		                                (resetn)
						 ,.din		                                (req_valid)
						 );
   
   assign REQ_ORDER_wren = req_gnt_vld;
   assign REQ_ORDER_din = sig_zz_req_order_desc_idx[req_gnt_idx];  


   //REQ_ORDER_fifo instantiation

   // REQ_ORDER_fifo stores description index. 
   // The fifo can store upto MAX_DESC description indices.

   sync_fifo #(
               .WIDTH		                                        (DESC_IDX_WIDTH)
               ,.DEPTH		                                        (MAX_DESC)
	       ) REQ_ORDER_fifo (
				 .clk	                                                        (clk)
				 ,.rst_n	                                                (resetn)
				 ,.dout	                                                        (REQ_ORDER_dout)
				 ,.dout_pre	                                                (REQ_ORDER_dout_pre)
				 ,.dout_pre_valid                                               (REQ_ORDER_dout_pre_valid)
				 ,.full	                                                        (REQ_ORDER_full)
				 ,.empty	                                                (REQ_ORDER_empty)
				 ,.wren	                                                        (REQ_ORDER_wren)
				 ,.rden	                                                        (REQ_ORDER_rden)
				 ,.din	                                                        (REQ_ORDER_din)
				 );

   //////////////////////
   //Signal :
   //  zzreq_init
   //Description :
   //  This signal initiates request generation towards DUT.
   //////////////////////

   always @(posedge clk) begin
      if (resetn==0) begin
	 int_zz_ownership_own_ff <= 'h0;
      end else begin
	 int_zz_ownership_own_ff <= int_zz_ownership_own;
      end
   end

   //Update zzreq_init
   generate
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_zzreq_init
	 always @(posedge clk) begin
	    
	    if (resetn == 1'b0) begin
	       zzreq_init[gi] <= 1'b0;
	       
	    end else begin
               
	       //When transaction is in progress, wait for ownership from Host 
	       if (int_zz_ownership_own[gi]==1'b1 && int_zz_ownership_own_ff[gi]==1'b0) begin 
		  zzreq_init[gi] <= 1'b1;      
	       end else begin
		  zzreq_init[gi] <= 1'b0;      
	       end

	    end
	 end
      end
   endgenerate


   //REQ_ORDER_fifo POP logic, DESC_REQUEST_ID_fifo PUSH logic


   //////////////////////
   //Grant Controller
   //Description :
   //  There can be multiple bits of value '1' in req_auto_valid. Grant allocator
   //  grants to each of the bits but one after the other, so that it can
   //  be pushed to REQ_ORDER_fifo.
   //////////////////////

   grant_controller #(
		      .MAX_DESC		                        (MAX_DESC)
		      ,.EDGE_TYP		                        (1)      //Posedge
		      ) req_auto_grant_controller (
						   .det_out                                       ()
						   ,.req_out                                       ()
						   ,.gnt_out                                       ()
						   ,.gnt_vld                                       (req_auto_gnt_vld)
						   ,.gnt_idx                                       (req_auto_gnt_idx)
						   ,.clk		                                (clk)
						   ,.rst_n		                                (resetn)
						   ,.din		                                (zzreq_init)
						   );
   
   always @(posedge clk) begin
      if (resetn==0) begin
	 zzreq_init_ff <= 'h0;
      end else begin
	 zzreq_init_ff <= zzreq_init;
      end
   end        		

   // zzreq_init_req becomes 'high' when a new zzreq_init comes and remains 
   // 'high' until corrosponding index is pushed into DESC_REQ_ID_fifo

   generate
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_zzreq_init_req
	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       zzreq_init_req[gi] <= 1'b0;  
	       // zzreq_init is served (required index is pushed into DESC_REQ_ID_fifo)
	    end else if (zzreq_init_ser[gi]==1'b1) begin   
	       zzreq_init_req[gi] <= 1'b0;
	       //Actual new zzreq_init occurs
	    end else if (zzreq_init[gi]==1'b1 && zzreq_init_ff[gi]==1'b0) begin  
	       zzreq_init_req[gi] <= 1'b1;
	    end
	 end
      end
   endgenerate

   generate
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_zzreq_init_req_proc
	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       zzreq_init_req_proc[gi] <= 1'b0;  
	       // zzreq_init is served (required index is pushed into DESC_REQ_ID_fifo)
	    end else if (zzreq_init_ser[gi]==1'b1) begin   
	       zzreq_init_req_proc[gi] <= 1'b0;
	       //Failed serving zzreq_init (required index is not pushed into DESC_REQ_ID_fifo yet)
	    end else if (zzreq_init_serfailed[gi]==1'b1) begin   
	       zzreq_init_req_proc[gi] <= 1'b0;
	    end else begin
	       zzreq_init_req_proc[gi] <= zzreq_init_req[gi];
	    end
	 end
      end
   endgenerate


   // If multiple decriptors have zzreq_init_req as 'high' , lower most index is
   //  selected for process.
   
   assign zzreq_init_req_onehot = (zzreq_init_req_proc)&(-zzreq_init_req_proc);      //One-hot vector. Priority to LSB first.

   assign DESC_REQ_ID_wren = ( (sig_mode_select_zz_auto_order==1'b1) ) ?
                             (req_auto_gnt_vld)
     : (REQ_ORDER_rden);
   generate

      for (gi=0; gi<=DESC_IDX_WIDTH-1; gi=gi+1) begin: gen_DESC_REQ_ID_din
	 assign DESC_REQ_ID_din[gi]  = ( (sig_mode_select_zz_auto_order==1'b1) ) ?

				       (req_auto_gnt_idx[gi])

           // If read issues to the REQ_ORDER_fifo, fill DESC_REQ_ID_fifo with index which popped
           // from the REQ_ORDER_fifo. 
           : (DESC_REQ_ID_din_sig[gi][0]);
      end

   endgenerate

   always @(posedge clk) begin
      
      if (resetn == 1'b0) begin
	 zzreq_init_ser       <= 'b0;
	 REQ_ORDER_rden   <= 'b0;
	 zzreq_init_serfailed <= 'b0;
	 for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_DESC_REQ_ID_din_array_reset
	    DESC_REQ_ID_din_sig[k] <= 'b0;
	 end
      end else begin

	 //If any of the zzreq_init was served
	 if (|zzreq_init_ser==1'b1) begin      
	    zzreq_init_ser       <= 'b0;
	    REQ_ORDER_rden   <= 'b0;
	    zzreq_init_serfailed <= 'b0;
	    for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_DESC_REQ_ID_din_array_clear
               DESC_REQ_ID_din_sig[k] <= 'b0;
	    end

	 end else begin

	    // i represents descriptor number
	    for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_zzreq_init_req_onehot

               if ( (sig_mode_select_zz_auto_order==1'b0) ) begin

		  //If the REQ_ORDER_fifo's last element (dout_pre) is for bresp init 
		  if ( (zzreq_init_req_onehot[i]==1'b1) && (REQ_ORDER_dout_pre==i && REQ_ORDER_dout_pre_valid==1'b1) && (REQ_ORDER_empty==1'b0) ) begin
		     zzreq_init_ser[i]       <= 1'b1;          //zzreq_init is served
		     REQ_ORDER_rden      <= 1'b1;          //issue read from the fifo
		     //k represents bits of description number
		     for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_DESC_REQ_ID_din_array_match_axi4lite
			DESC_REQ_ID_din_sig[k][0]        <= REQ_ORDER_dout_pre[k];
		     end
		     //If a descriptor for bresp init is not last element of the REQ_ORDER_fifo
		  end else if ( (zzreq_init_req_onehot[i]==1'b1) ) begin
		     zzreq_init_serfailed[i] <= 1'b1;
		  end
		  
		  
               end

	    end  

	 end

      end
   end  







   ////////////////////////////////////////////////////////////////////
   //
   // FSM to fetch desc IDs from FIFO.
   //
   /////////////////////////////////////////////////////////////////

   localparam 
     FETCH_REQ_FIFO_IDLE = 1'b0,
     FETCH_REQ_FIFO_READ = 1'b1;

   always@ (posedge clk) 
     begin
     	if(~resetn) 
     	  begin
     	     DESC_REQ_ID_rden<=0;
             fetch_req_fifo_state<=FETCH_REQ_FIFO_IDLE;
       	  end 
       	else 
     	  begin
             case (fetch_req_fifo_state) 
     	       FETCH_REQ_FIFO_IDLE:
     		 //Pop fifo only if it's not empty
     		 if(~DESC_REQ_ID_empty && ~desc_allocation_in_progress)
     		   begin
     		      DESC_REQ_ID_rden<=1;
     		      fetch_req_fifo_state<=FETCH_REQ_FIFO_READ;
     		   end
     	       FETCH_REQ_FIFO_READ:
     		 //If Slave is accepting AW and AR Go and send
     		 //Next AW or AR on the bus
     		 if(aznext) begin
     		    DESC_REQ_ID_rden<=0;
     		    fetch_req_fifo_state<=FETCH_REQ_FIFO_IDLE;
     		 end
     		 else begin
     		    DESC_REQ_ID_rden<=0;
     		    fetch_req_fifo_state<=FETCH_REQ_FIFO_READ;
     		 end
     	     endcase
     	  end
     end



   ///////////////////////////////////////////////////////////////////////////////////////
		 //
   // Fifo to store desc id of read requests
   //
   ///////////////////////////////////////////////////////////////////////////////////////

   sync_fifo #(
               .WIDTH		                                        (DESC_IDX_WIDTH) 
               ,.DEPTH		                                        (MAX_DESC)
	       ) DESC_REQUEST_ID_fifo (
				       .clk	                                                        (clk)
				       ,.rst_n	                                                (resetn)
				       ,.dout	                                                        (DESC_REQ_ID_dout)
				       ,.full	                                                        (DESC_REQ_ID_full)
				       ,.empty	                                                (DESC_REQ_ID_empty)
				       ,.wren	                                                        (DESC_REQ_ID_wren)
				       ,.rden	                                                        (DESC_REQ_ID_rden)
				       ,.din	                                                        (DESC_REQ_ID_din)
				       );

   //sync_fifo #(.DEPTH(MAX_DESC),.WIDTH(DESC_IDX_WIDTH)) DESC_REQUEST_ID_fifo
   //      (
   //       .clk(clk),
   //       .rst_n(resetn),
   //       .din(desc_write_id),
   //       .wren(desc_write_en),
   //       .empty(DESC_REQ_ID_empty),
   //       .full(DESC_REQ_ID_full),
   //       .dout(DESC_REQ_ID_dout),
   //       .rden(DESC_REQ_ID_rden)
   //       );
   //

endmodule



// Local Variables:
// verilog-library-directories:("./")
// End:



