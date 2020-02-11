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
 *   RX Ram module, to store incoming flits
 *
 */

module chi_rxflit_ram 
  #(
    parameter AWIDTH = 12,  // Address Width
    parameter WWIDTH = 128,  // Data Width
    parameter RWIDTH = 32,  // Data Width
    parameter OREG_A = "TRUE",  // Optional Port A output pipeline registers
    parameter OREG_B = "TRUE"   // Optional Port B output pipeline registers  
    )( 
       input 			  clk,
       input 			  en_a, //  Port A enable. Enables or disables the read/write access to the block RAM memory core.             
       input 			  en_b, //  Port B enable. Enables or disables the read/write access to the block RAM memory core.             
       input 			  we_a,
       input 			  we_b,
       input [(WWIDTH/32 -1) : 0] word_en_a,
       input [(WWIDTH/32 -1) : 0] word_en_b,
       input 			  rst_a, //enout0,
       input 			  rst_b,
       input [AWIDTH-1:0] 	  addr_a,
       input [AWIDTH-1:0] 	  addr_b,
       input [WWIDTH-1:0] 	  wr_data_a,
       input [WWIDTH-1:0] 	  wr_data_b,
       input 			  OREG_CE_A,
       input 			  OREG_CE_B, 
       output [WWIDTH-1:0] 	  rd_data_a,
       output [RWIDTH-1:0] 	  rd_data_b
       );
   

   reg [WWIDTH-1:0] 		  mem[(1<<AWIDTH)-1:0];        // Memory Declaration 
   reg [WWIDTH-1:0] 		  memreg_a;
   reg [RWIDTH-1:0] 		  memreg_b;

   reg [WWIDTH-1:0] 		  memreg_a_reg;
   reg [RWIDTH-1:0] 		  memreg_b_reg;

   integer 			  word_index;
   
   // RAM : Read has one latency, Write has one latency as well.
   // Write Logic
   always @ (posedge clk)
     begin
        if(en_a) begin
           if(we_a) begin
              mem[addr_a] <= wr_data_a;
           end
        end
     end
   
   

   

   // Read Logic
   always @ (posedge clk)
     begin
        if(rst_a) begin
           memreg_a <=   'b0;
        end else begin
           if(en_a) begin
              if(~we_a) begin
                 memreg_a <= mem[addr_a];
              end else begin
                 memreg_a <=   memreg_a;
              end
           end else begin
              memreg_a <=   memreg_a;
           end
        end 
     end  

   always @ (posedge clk)
     begin
        if(rst_b) begin
           memreg_b <=   'b0;
        end else begin
           if(en_b) begin
              if(~we_b) begin
		 for ( word_index = 0; word_index <= (WWIDTH/32)-1; word_index = word_index+1 )
                   if ( word_en_b[word_index] == 1 ) begin
                      memreg_b <= mem[addr_b][(word_index*32) +: 32]; 
		   end
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
        if (OREG_CE_A==1'b1) begin
           memreg_a_reg <= memreg_a;
        end else begin
           memreg_a_reg <= memreg_a_reg;
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

   generate 
      if (OREG_A=="TRUE") begin
         assign rd_data_a =  memreg_a_reg; 
      end else begin
         assign rd_data_a = memreg_a ; 
      end
   endgenerate

   generate 
      if (OREG_B=="TRUE") begin
         assign rd_data_b =  memreg_b_reg;
      end else begin
         assign rd_data_b = memreg_b ;
      end
   endgenerate

endmodule        
