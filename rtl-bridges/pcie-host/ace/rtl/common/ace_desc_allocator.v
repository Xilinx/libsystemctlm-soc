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
 *     Descriptor allocator
 *
 *
 */

`include "ace_defines_common.vh"

module ace_desc_allocator #(

			    parameter ADDR_WIDTH                                           = 64    
			    ,parameter DATA_WIDTH                                           = 128   
			    ,parameter RAM_SIZE                                             = 16384    
			    ,parameter MAX_DESC                                             = 16                   

			    )(

			      //Clock and reset
			      input clk 
			      ,input resetn 

			      ,input txn_valid
			      ,output reg desc_alc_valid
			      ,output [(`CLOG2(MAX_DESC))-1:0] desc_alc_idx 

			      //Registers
			      ,input [MAX_DESC-1:0] desc_avail	

			      );

   /////////////
  localparam DESC_IDX_WIDTH                                               = `CLOG2(MAX_DESC);
   localparam RAM_OFFSET_WIDTH                                             = `CLOG2((RAM_SIZE*8)/DATA_WIDTH);

   wire 			    DESC_wren;	
   reg 				    DESC_rden;	
   wire [DESC_IDX_WIDTH-1:0] 	    DESC_din;	
   wire [DESC_IDX_WIDTH-1:0] 	    DESC_dout;	
   wire 			    DESC_full;	
   wire 			    DESC_empty;

   reg [MAX_DESC-1:0] 		    desc_freeup;

   reg 				    desc_txn_valid;
   reg 				    desc_fifo;

   reg [MAX_DESC-1:0] 		    desc_avail_ff;	

   reg 				    txn_valid_ff;

   wire 			    gnt_vld;
   wire [DESC_IDX_WIDTH-1:0] 	    gnt_idx;

   /************************Descriptor Allocator Begin************************
    *
    * A descriptor is made available when SW gives ownership to HW for
    * initiating new transation 
    * This block allocates a new descriptor number to request when at
    * least one descriptor is available.
    *
    */


   //////////////////////Descriptor FIFO PUSH logic//////////////////////

   //////////////////////
  //Signal : desc_freeup
   //Description:
   //  Generate a 1-cycle pulse when SW gives ownership to HW and descriptor is not busy
   //////////////////////

   always @(posedge clk) begin
      if (resetn==0) begin
	 desc_avail_ff <= 'h0;
      end else begin
	 desc_avail_ff <= desc_avail;
      end
   end
   generate        		
      genvar gi;
      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_gi
	 always @(posedge clk) begin
	    if (resetn == 1'b0) begin
	       desc_freeup[gi] <= 1'b0;  
	    end else if (desc_avail[gi]==1'b1 && desc_avail_ff[gi]==1'b0) begin //Positive edge detection
	       desc_freeup[gi] <= 1'b1;
	    end else begin
	       desc_freeup[gi] <= 1'b0;
	    end
	 end
      end
   endgenerate 


   //////////////////////
   //Grant Controller
   //Description :
   //  There can be multiple bits of value '1' in desc_freeup. Grant allocator
   //  grants to each of the bits but one after the other, so that its index can
   //  be pushed to descriptor FIFO(DESC_fifo).
   //////////////////////

   grant_controller #(
		      .MAX_DESC		                        (MAX_DESC)
		      ,.EDGE_TYP		                        (1)      //Posedge
		      ) i_grant_controller (
					    .det_out                                       ()
					    ,.req_out                                       ()
					    ,.gnt_out                                       ()
					    ,.gnt_vld                                       (gnt_vld)
					    ,.gnt_idx                                       (gnt_idx)
					    ,.clk		                                (clk)
					    ,.rst_n		                                (resetn)
					    ,.din		                                (desc_freeup)
					    );
   
   assign DESC_wren = gnt_vld;
   assign DESC_din = gnt_idx;  

   //////////////////////Descriptor FIFO POP logic//////////////////////

   always @(posedge clk) begin
      if (resetn==0) begin
	 txn_valid_ff <= 'h0;
      end else begin
	 txn_valid_ff <= txn_valid;
      end
   end        		
   //desc_txn_valid signal becomes 'high' when a new read txn request comes 
   //and remains 'high' until a new descriptor is allocated by reading DESC_fifo. 
   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 desc_txn_valid <= 1'b0;
	 //if descriptor is read from DESC_fifo  
      end else if (desc_fifo==1'b1) begin
	 desc_txn_valid <= 1'b0;
	 //when new read txn request arrives 
      end else if (txn_valid==1'b1 && txn_valid_ff==1'b0) begin 
	 desc_txn_valid <= 1'b1;
      end
   end


   //When write and read request come together, priority is given to read.
   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 DESC_rden <= 1'b0;
	 desc_fifo <= 1'b0;
      end else if (DESC_rden==1'b1) begin
	 DESC_rden <= 1'b0;
	 desc_fifo <= 1'b0;
      end else if (DESC_rden==1'b0 && DESC_empty==1'b0 && desc_txn_valid==1'b1) begin
	 DESC_rden <= 1'b1;
	 desc_fifo <= 1'b1;
      end else begin
	 DESC_rden <= 1'b0;
	 desc_fifo <= 1'b0;
      end
   end

   always @(posedge clk) begin
      desc_alc_valid <= desc_fifo;
   end

   assign desc_alc_idx = DESC_dout;  

   //////////////////////Descriptor FIFO//////////////////////
   sync_fifo #(
               .WIDTH		                        (DESC_IDX_WIDTH)
               ,.DEPTH		                        (MAX_DESC)
	       ) DESC_fifo (
			    .dout	                                        (DESC_dout)
			    ,.full	                                        (DESC_full)
			    ,.empty	                                (DESC_empty)
			    ,.clk	                                        (clk)
			    ,.rst_n	                                (resetn)
			    ,.wren	                                        (DESC_wren)
			    ,.rden	                                        (DESC_rden)
			    ,.din	                                        (DESC_din)
			    );
   
   /************************Descriptor Allocator End************************/

endmodule
