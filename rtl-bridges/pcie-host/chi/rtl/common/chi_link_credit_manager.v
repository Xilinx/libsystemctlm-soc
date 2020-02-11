/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Heramb Aligave.
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
 *   chi link layer credit manager
 *
 */
module  chi_link_credit_manager 
  (
   input 	clk,
   input 	resetn,
   input 	dec_credits,
   input 	incr_credits,
   input [4:0] 	refill_credits,
  
  
   output reg 	credits_available,
   output [3:0] cur_credits,
   output 	credit_maxed
   );

   
   wire 	credit_update ;
   wire [3:0] 	incremented_credits; 
   wire [3:0] 	decremented_credits;
   

   reg [3:0] 	current_credit;

   assign cur_credits = current_credit;
   
   assign credit_maxed   = current_credit >= 'hE;
   assign credit_update = incr_credits || dec_credits || refill_credits[4];
   assign incremented_credits = incr_credits ? current_credit + 1'b1 : refill_credits[4] ? refill_credits[3:0] : current_credit;

   assign decremented_credits = dec_credits ? incr_credits ? current_credit :current_credit - 1'b1 : incremented_credits;

   
   always@(posedge clk) begin
      if(~resetn) begin
         credits_available  <= 1'b0;
         current_credit  <= 4'b0;
      end
      if(current_credit == 4'hE & ~credit_update)
	current_credit <= 4'hE;
      else if(current_credit == 4'h0 & dec_credits)
	current_credit <= 0;
      else if (credit_update) begin
         credits_available  <= (decremented_credits != 4'b0);
         current_credit  <= decremented_credits;
      end 
   end
endmodule
