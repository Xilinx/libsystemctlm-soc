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
 *   synchronizer for input data_in.
 *   Minimum value for SYNC_FF is 2
 *
 */

module synchronizer #(
		      parameter SYNC_FF                              = 2
		      ,parameter D_WIDTH                              = 64
		      )  (
			  input [D_WIDTH-1:0] data_in
			  ,input ck
			  ,input rn 
			  ,output wire [D_WIDTH-1:0] q_out
			  );



   reg [D_WIDTH-1:0] 			      sync_reg [SYNC_FF-1:0];
   integer 				      k;

   always @(posedge ck) begin
      if (!rn) begin
	 for (k = 0; k <= SYNC_FF-1; k=k+1) begin
            sync_reg[k] <= 'h0;
	 end
      end else begin
	 sync_reg[0] <= data_in;
	 for (k = 1; k <= SYNC_FF-1; k=k+1) begin
            sync_reg[k] <= sync_reg[k-1];
	 end
      end
   end

   assign q_out = sync_reg[SYNC_FF-1];

endmodule


