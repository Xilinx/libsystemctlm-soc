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
 *   Synchronous FIFO works on single clock input clk.
 *
 *
 */

`include "defines_common.vh"

module sync_fifo #(

         parameter WIDTH                                = 4
        ,parameter DEPTH                                = 16
        ,parameter ALMOST_FULL_DEPTH                    = 14
        ,parameter ALMOST_EMPTY_DEPTH                   = 2
)(
         input 			                            clk
        ,input 			                            rst_n
        ,input 			                            wren
        ,input 			                            rden
        ,input      [WIDTH-1:0] 	                    din
        ,output reg [WIDTH-1:0]                             dout
        ,output reg [WIDTH-1:0]                             dout_pre
        ,output reg                                         dout_pre_valid
        ,output reg 		                            full
        ,output reg                                         empty
        ,output reg [`CLOG2(DEPTH) :0]                      fifo_counter
        ,output reg 		                            almost_full
        ,output reg 		                            almost_empty
 );




localparam CLOG2_DEPTH                                  = `CLOG2(DEPTH);


reg  [CLOG2_DEPTH -1:0]                                 rd_ptr;           // pointer to read address
reg  [CLOG2_DEPTH -1:0]                                 wr_ptr;           // pointer to write address  
reg  [WIDTH-1:0]                                        buf_mem[DEPTH -1 : 0];  
reg                                                     empty_ff;

always @(fifo_counter)
begin
   almost_empty         <= (fifo_counter>=0 && fifo_counter<=ALMOST_EMPTY_DEPTH);
   almost_full          <= (fifo_counter<=DEPTH && fifo_counter>=ALMOST_FULL_DEPTH);
end

always @( posedge clk)
begin
   empty_ff <= empty;
end
always @( posedge clk or negedge rst_n)
begin
   if( rst_n==1'b0 )
      dout_pre <= 0;
   else
   begin
      if( rden && !empty )
         dout_pre <= buf_mem[rd_ptr+1];

      else
         dout_pre <= buf_mem[rd_ptr];
   end
end

//Alternative logic to generate dout_pre_valid is 
//assign dout_pre_valid= ( (empty==1'b0) && (empty_ff==1'b0) );

always @(posedge clk or negedge rst_n)
begin
   if( rst_n==1'b0 ) begin
       fifo_counter     <= 'b0;
       empty            <= 1'b1;
       full             <= 1'b0;
       dout_pre_valid   <= 1'b0;

   end else if( (!full && wren) && ( !empty && rden ) ) begin
       fifo_counter     <= fifo_counter;
       empty            <= empty;
       full             <= full;
       dout_pre_valid   <= ~empty;

   end else if( !full && wren ) begin
       fifo_counter     <= (fifo_counter + 1);
       empty            <= 1'b0;
       full             <= ( (~fifo_counter[CLOG2_DEPTH]) && (&fifo_counter[CLOG2_DEPTH-1:0]) );   //( fifo_counter == {(CLOG2_DEPTH){1'b1}} )
       dout_pre_valid   <= ~empty;

   end else if( !empty && rden ) begin
       fifo_counter     <= (fifo_counter - 1);
       empty            <= ( (~(|fifo_counter[CLOG2_DEPTH:1])) && (fifo_counter[0]) );   //(fifo_counter=='b1)
       full             <= 1'b0;
       dout_pre_valid   <= ( (~empty) && (|fifo_counter[CLOG2_DEPTH:1]) );   //( (empty=='b0) && (fifo_counter>'b1) )

   end else begin
      fifo_counter      <= fifo_counter;
      empty             <= empty;
      full              <= full;
      dout_pre_valid    <= ~empty;
   end
end

always @( posedge clk or negedge rst_n)
begin
   if( rst_n==1'b0 )
      dout <= 0;
   else
   begin
      if( rden && !empty )
         dout <= buf_mem[rd_ptr];

      else
         dout <= dout;

   end
end

always @(posedge clk)
begin

   if( wren && !full )
      buf_mem[ wr_ptr ] <= din;

   else
      buf_mem[ wr_ptr ] <= buf_mem[ wr_ptr ];
end

always @( posedge clk or negedge rst_n)
begin
   if( rst_n==1'b0 )
   begin
      wr_ptr <= 0;
      rd_ptr <= 0;
   end
   else
   begin
      if( !full && wren )    wr_ptr <= wr_ptr + 1;
          else  wr_ptr <= wr_ptr;

      if( !empty && rden )   rd_ptr <= rd_ptr + 1;
      else rd_ptr <= rd_ptr;
   end

end
endmodule







