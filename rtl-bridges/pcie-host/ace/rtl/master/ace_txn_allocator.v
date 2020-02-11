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
 *   It comprises of 3 blocks as following
 *     Descriptor allocator
 *     Addresss allocator (RDATA or WDATA/WSTRB RAM offset allocator)
 *     Transaction allocator
 *
 *
 */

`include "ace_defines_common.vh"

module ace_txn_allocator #(

			   parameter CHANNEL_TYPE                                         = "RD"  //Allowed values : "RD", "WR", "SN"    
			   ,parameter ADDR_WIDTH                                           = 64    
			   ,parameter DATA_WIDTH                                           = 128   
			   ,parameter RAM_SIZE                                             = 16384    
			   ,parameter MAX_DESC                                             = 16                   
			   ,parameter CACHE_LINE_SIZE                                      = 64                   

			   )(

			     //Clock and reset
			     input clk 
			     ,input resetn 
   
			     //Channel variables
			     ,input txn_valid
			     ,input [7:0] txn_size //AXLEN (Request is (AXLEN+1))
			     ,output reg alc_valid
			     ,output [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0] alc_offset //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [9:0]
			     ,output reg [(`CLOG2(MAX_DESC))-1:0] alc_idx //For MAX_DESC=8, it is [2:0] 
   
			     //Control variables
			     ,input [MAX_DESC-1:0] desc_avail 
			     ,input [MAX_DESC-1:0] addr_avail

			     );

   /////////////
  localparam DESC_IDX_WIDTH                                               = `CLOG2(MAX_DESC);
   localparam RAM_OFFSET_WIDTH                                             = `CLOG2((RAM_SIZE*8)/DATA_WIDTH);

   localparam TXN_IDLE                                                      = 2'b00;
   localparam TXN_DESC_AVAIL                                                = 2'b01;
   localparam TXN_ADDR_AVAIL                                                = 2'b10;
   localparam TXN_DESC_ADDR_AVAIL                                           = 2'b11;

   wire 			   desc_alc_valid;
   wire [DESC_IDX_WIDTH-1:0] 	   desc_alc_idx;	

   wire 			   addr_alc_valid;
   wire [RAM_OFFSET_WIDTH-1:0] 	   addr_alc_offset;           
   wire [DESC_IDX_WIDTH-1:0] 	   addr_alc_node_idx;         

   reg [DESC_IDX_WIDTH-1:0] 	   alc_node_idx;	

   reg [1:0] 			   txn_state;
   
   reg 				   txn_valid_pulse;

   reg [RAM_OFFSET_WIDTH-1:0] 	   alc_offset_rdwr;
   reg [RAM_OFFSET_WIDTH-1:0] 	   alc_offset_sn;

   //////////////////////
  //2-D array of descriptor fields
   //////////////////////

   /************************Descriptor Allocator Begin************************/

   ///////////////////////
   //Channel Descriptor Allocator
   //////////////////////

   ace_desc_allocator #(
			.ADDR_WIDTH		                        (ADDR_WIDTH)
			,.DATA_WIDTH		                        (DATA_WIDTH)
			,.RAM_SIZE		                        (RAM_SIZE)
			,.MAX_DESC		                        (MAX_DESC)
			) i_ace_desc_allocator (
						.clk	                                        (clk)
						,.resetn	                                (resetn)
						,.txn_valid                                     (txn_valid)
						,.desc_alc_valid                                (desc_alc_valid)
						,.desc_alc_idx	                                (desc_alc_idx)
						,.desc_avail                                    (desc_avail)
						);

   /************************Descriptor Allocator End************************/

   /************************Address Allocator Begin************************
    *
    * RDATA(for read) and WDATA/WSTRB(for write) RAM offset allocator and deallocator 
    *
    */

   ///////////////////////
   //Channel Address Allocator
   //////////////////////

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 txn_valid_pulse    <= 1'b0;
      end else if (txn_valid_pulse==1'b1) begin
	 txn_valid_pulse    <= 1'b0;
      end else if (txn_valid==1'b1) begin
	 txn_valid_pulse    <= 1'b1;
      end else begin
	 txn_valid_pulse    <= 1'b0;
      end
   end

   generate

      if ( (CHANNEL_TYPE=="SN") ) begin

	 assign addr_alc_valid  = txn_valid_pulse; 
	 assign addr_alc_offset = 'b0;   

      end else begin

	 ace_addr_allocator #(
			      .ADDR_WIDTH		                        (ADDR_WIDTH)
			      ,.DATA_WIDTH		                        (DATA_WIDTH)
			      ,.RAM_SIZE		                        (RAM_SIZE)
			      ,.MAX_DESC		                        (MAX_DESC)
			      ) i_ace_addr_allocator (
						      .addr_alc_valid	                        (addr_alc_valid)
						      ,.addr_alc_offset                               (addr_alc_offset)
						      ,.clk	                                        (clk)
						      ,.resetn	                                (resetn)
						      ,.txn_valid	                                (txn_valid)
						      ,.txn_size	                                (txn_size)
						      ,.txn_cmpl	                                (addr_avail)
						      ,.addr_alc_node_idx                             (addr_alc_node_idx) 
						      ,.alc_valid                                     (alc_valid)
						      ,.alc_desc_idx                                  (alc_idx) 
						      ,.alc_node_idx                                  (alc_node_idx) 
						      );

      end


   endgenerate

   /************************Address Allocator End************************/

   /************************Transaction Allocator Begin************************
    *
    * Read and write transaction allocator allocates descriptor number and dataram offset. 
    *
    */


   ///////////////////////
   //Signal :
   //  alc_valid
   //  alc_idx
   //  alc_offset
   //  alc_node_idx
   //Description :
   //  Generate alc_valid When descriptor and offset both are available for a read request.
   //////////////////////

   assign alc_offset = (CHANNEL_TYPE=="SN") ?
                       alc_offset_sn
                       : alc_offset_rdwr ;

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 alc_idx <= 'b0;
	 alc_offset_sn <= 'b0;
      end else if (desc_alc_valid==1'b1) begin
	 alc_idx <= desc_alc_idx;
	 alc_offset_sn <= ( (CACHE_LINE_SIZE*8/DATA_WIDTH) * (desc_alc_idx) );
      end
   end

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 alc_offset_rdwr <= 'b0;
      end else if (addr_alc_valid==1'b1) begin
	 alc_offset_rdwr <= addr_alc_offset;
      end
   end

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 alc_node_idx <= 'b0;
      end else if (addr_alc_valid==1'b1) begin
	 alc_node_idx <= addr_alc_node_idx;
      end
   end

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 txn_state <= TXN_IDLE;
      end else begin 
	 case(txn_state)
	   TXN_IDLE: begin
	      case({addr_alc_valid,desc_alc_valid}) 
		2'b00: begin
		   txn_state<= TXN_IDLE;
		   alc_valid<= 1'b0;
		end 2'b01: begin
		   txn_state<= TXN_DESC_AVAIL;
		   alc_valid<= 1'b0;
		end 2'b10: begin
		   txn_state<= TXN_ADDR_AVAIL;
		   alc_valid<= 1'b0;
		end 2'b11: begin
		   txn_state<= TXN_DESC_ADDR_AVAIL;
		   alc_valid<= 1'b1;
		end
	      endcase 
	   end TXN_DESC_AVAIL: begin
	      if (addr_alc_valid==1'b1) begin 
		 txn_state<= TXN_DESC_ADDR_AVAIL;
		 alc_valid<= 1'b1;
	      end else begin
		 txn_state<= txn_state;
		 alc_valid<= 1'b0;
	      end
	   end TXN_ADDR_AVAIL: begin
	      if (desc_alc_valid==1'b1) begin 
		 txn_state<= TXN_DESC_ADDR_AVAIL;
		 alc_valid<= 1'b1;
	      end else begin
		 txn_state<= txn_state;
		 alc_valid<= 1'b0;
	      end
	   end TXN_DESC_ADDR_AVAIL: begin
	      txn_state<= TXN_IDLE;
	      alc_valid<= 1'b0;
	   end default: begin
	      txn_state<= txn_state;
	      alc_valid<= 1'b0;
	   end
	 endcase
      end
   end 

   /************************Transaction Allocator End************************/

endmodule        

// Local Variables:
// verilog-library-directories:("./")
// End:
