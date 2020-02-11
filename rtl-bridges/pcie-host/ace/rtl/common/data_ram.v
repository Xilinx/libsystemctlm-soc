/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Kunal Varshney. 
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
 * Port A is always Write port and port B is alwyas Read port
 *
 */

module data_ram #(
		  parameter AWIDTH = 12,  // Address Width
		  parameter DWIDTH = 128,  // Data Width
		  parameter OREG_A = "TRUE",  // Optional Port A output pipeline registers
		  parameter OREG_B = "TRUE"   // Optional Port B output pipeline registers  
		  )( 
		     input 		       clk,
		     input 		       en_a, //  Port A enable. Enables or disables the read/write access to the block RAM memory core.             
		     input 		       en_b, //  Port B enable. Enables or disables the read/write access to the block RAM memory core.             
		     input 		       we_a,
		     input 		       we_b,
		     input [(DWIDTH/8 -1) : 0] byte_en_a,
		     input [(DWIDTH/8 -1) : 0] byte_en_b,
		     input 		       rst_a, //enout0,
		     input 		       rst_b,
		     input [AWIDTH-1:0]        addr_a,
		     input [AWIDTH-1:0]        addr_b,
		     input [DWIDTH-1:0]        wr_data_a,
		     input [DWIDTH-1:0]        wr_data_b,
		     input 		       OREG_CE_A,
		     input 		       OREG_CE_B, 
		     output [DWIDTH-1:0]       rd_data_a,
		     output [DWIDTH-1:0]       rd_data_b
		     );
   

   reg [DWIDTH-1:0] 			       mem[(1<<AWIDTH)-1:0];        // Memory Declaration 
   reg [DWIDTH-1:0] 			       memreg_b;

   reg [DWIDTH-1:0] 			       memreg_b_reg;

   integer 				       byte_index;
   
   // RAM : Read has one latency, Write has one latency as well.
   // Write Logic
   always @ (posedge clk)
     begin
        if(en_a) begin
           if(we_a) begin
              for ( byte_index = 0; byte_index <= (DWIDTH/8)-1; byte_index = byte_index+1 )
                if ( byte_en_a[byte_index] == 1 ) begin
		   //              mem[addr_a] <= wr_data_a;
                   mem[addr_a][(byte_index*8) +: 8] <= wr_data_a[(byte_index*8) +: 8];
                end
           end
        end
     end // always @ (posedge clk)

   always @ (posedge clk)
     begin
        if(rst_b) begin
           memreg_b <=   'b0;
        end else begin
           if(en_b) begin
              if(~we_b) begin
                 memreg_b <= mem[addr_b];
              end else begin
                 memreg_b <=   memreg_b;
              end
           end else begin
              memreg_b <=   memreg_b;
           end
        end 
     end 
   
   always @ (posedge clk)
     begin
        if (OREG_CE_B==1'b1) begin
           memreg_b_reg <= memreg_b;
        end else begin
           memreg_b_reg <= memreg_b_reg;
        end  
     end

   assign rd_data_a =  {DWIDTH{1'b0}}; 

   generate 
      if (OREG_B=="TRUE") begin
         assign rd_data_b =  memreg_b_reg;
      end else begin
         assign rd_data_b = memreg_b ;
      end
   endgenerate

endmodule        

/* data_ram.v ends here */
