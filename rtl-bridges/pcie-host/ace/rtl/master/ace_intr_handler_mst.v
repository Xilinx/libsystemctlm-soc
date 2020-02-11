/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Meera Bagdai. 
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
 *   Interrupt handler for Mst
 *
 */
`include "ace_defines_intr.vh"
module ace_intr_handler_mst #(

				 parameter ACE_PROTOCOL                      = "FULLACE" 
				 
				 )(
				   input clk 
				   ,input resetn 
   
				   ,output reg irq_out 
				   ,input irq_ack 
				   //DUT Interrupt
				   ,output reg [127:0] h2c_intr_out
				   ,input [63:0] c2h_intr_in
				   //DUT GPIO
				   ,input [255:0] c2h_gpio_in
				   ,output [255:0] h2c_gpio_out
   
   
   
				   // IH to RB
				   ,output reg [31:0] ih2rb_c2h_intr_status_0_reg 
				   ,output reg [31:0] ih2rb_c2h_intr_status_1_reg
				   ,output reg [31:0] ih2rb_intr_c2h_toggle_status_0_reg 
				   ,output reg [31:0] ih2rb_intr_c2h_toggle_status_1_reg 
				   ,output reg [31:0] ih2rb_c2h_gpio_0_reg
				   ,output reg [31:0] ih2rb_c2h_gpio_1_reg
				   ,output reg [31:0] ih2rb_c2h_gpio_2_reg
				   ,output reg [31:0] ih2rb_c2h_gpio_3_reg
				   ,output reg [31:0] ih2rb_c2h_gpio_4_reg
				   ,output reg [31:0] ih2rb_c2h_gpio_5_reg
				   ,output reg [31:0] ih2rb_c2h_gpio_6_reg
				   ,output reg [31:0] ih2rb_c2h_gpio_7_reg 
   
   
				   ,output reg [31:0] ih2rb_c2h_intr_status_0_reg_we 
				   ,output reg [31:0] ih2rb_c2h_intr_status_1_reg_we
				   ,output reg [31:0] ih2rb_intr_c2h_toggle_status_0_reg_we 
				   ,output reg [31:0] ih2rb_intr_c2h_toggle_status_1_reg_we 
				   ,output reg [31:0] ih2rb_c2h_gpio_0_reg_we
				   ,output reg [31:0] ih2rb_c2h_gpio_1_reg_we
				   ,output reg [31:0] ih2rb_c2h_gpio_2_reg_we
				   ,output reg [31:0] ih2rb_c2h_gpio_3_reg_we
				   ,output reg [31:0] ih2rb_c2h_gpio_4_reg_we
				   ,output reg [31:0] ih2rb_c2h_gpio_5_reg_we
				   ,output reg [31:0] ih2rb_c2h_gpio_6_reg_we
				   ,output reg [31:0] ih2rb_c2h_gpio_7_reg_we
   
   
				   // Registers from RB                    
   
				   ,input [31:0] version_reg 
				   ,input [31:0] h2c_intr_0_reg 
				   ,input [31:0] h2c_intr_1_reg 
				   ,input [31:0] h2c_intr_2_reg 
				   ,input [31:0] h2c_intr_3_reg 
				   ,input [31:0] c2h_intr_status_0_reg 
				   ,input [31:0] c2h_intr_status_1_reg 
				   ,input [31:0] intr_c2h_toggle_status_0_reg 
				   ,input [31:0] intr_c2h_toggle_status_1_reg 
				   ,input [31:0] intr_c2h_toggle_enable_0_reg 
				   ,input [31:0] intr_c2h_toggle_enable_1_reg 
				   ,input [31:0] c2h_gpio_0_reg 
				   ,input [31:0] c2h_gpio_1_reg 
				   ,input [31:0] c2h_gpio_2_reg 
				   ,input [31:0] c2h_gpio_3_reg 
				   ,input [31:0] c2h_gpio_4_reg 
				   ,input [31:0] c2h_gpio_5_reg 
				   ,input [31:0] c2h_gpio_6_reg 
				   ,input [31:0] c2h_gpio_7_reg 
				   ,input [31:0] c2h_gpio_8_reg 
				   ,input [31:0] c2h_gpio_9_reg 
				   ,input [31:0] c2h_gpio_10_reg 
				   ,input [31:0] c2h_gpio_11_reg 
				   ,input [31:0] c2h_gpio_12_reg 
				   ,input [31:0] c2h_gpio_13_reg 
				   ,input [31:0] c2h_gpio_14_reg 
				   ,input [31:0] c2h_gpio_15_reg 
				   ,input [31:0] h2c_gpio_0_reg 
				   ,input [31:0] h2c_gpio_1_reg 
				   ,input [31:0] h2c_gpio_2_reg 
				   ,input [31:0] h2c_gpio_3_reg 
				   ,input [31:0] h2c_gpio_4_reg 
				   ,input [31:0] h2c_gpio_5_reg 
				   ,input [31:0] h2c_gpio_6_reg 
				   ,input [31:0] h2c_gpio_7_reg 
   
   
				   ,input [31:0] intr_error_status_reg 
				   ,input [31:0] intr_error_enable_reg 
   
				   ,input [31:0] rd_req_intr_comp_status_reg 
				   ,input [31:0] rd_req_intr_comp_enable_reg
				   ,input [31:0] wr_req_intr_comp_status_reg 
				   ,input [31:0] wr_req_intr_comp_enable_reg
				   ,input [31:0] sn_resp_intr_comp_status_reg 
				   ,input [31:0] sn_resp_intr_comp_enable_reg
				   ,input [31:0] sn_data_intr_comp_status_reg 
				   ,input [31:0] sn_data_intr_comp_enable_reg
   
				   ,input [31:0] rd_resp_fifo_fill_level_reg
				   ,input [31:0] wr_resp_fifo_fill_level_reg
				   ,input [31:0] sn_req_fifo_fill_level_reg
				   ,input [31:0] intr_fifo_enable_reg
   
				   ,input [31:0] intr_c2h_toggle_clear_0_reg
				   ,input [31:0] intr_c2h_toggle_clear_1_reg
   
				   );
   


   wire [63:0] 				 c2h_intr_in_posedge;
   wire [63:0] 				 c2h_intr_in_negedge;

   wire [31:0] 				 c2h_intr_in_posedge_0;
   wire [31:0] 				 c2h_intr_in_negedge_0;

   wire [31:0] 				 c2h_intr_in_posedge_1;
   wire [31:0] 				 c2h_intr_in_negedge_1;
   
   
   reg [63:0] 				 c2h_intr_in_ff;

   wire 				 intr_fifo_enable_en_sn_req_fifo_nonempty;
   wire 				 intr_fifo_enable_en_wr_resp_fifo_nonempty;
   wire 				 intr_fifo_enable_en_rd_resp_fifo_nonempty;

   assign intr_fifo_enable_en_sn_req_fifo_nonempty = intr_fifo_enable_reg[2];
   assign intr_fifo_enable_en_wr_resp_fifo_nonempty = intr_fifo_enable_reg[1];
   assign intr_fifo_enable_en_rd_resp_fifo_nonempty = intr_fifo_enable_reg[0];

   assign h2c_gpio_out = { h2c_gpio_7_reg, h2c_gpio_6_reg, h2c_gpio_5_reg, h2c_gpio_4_reg, h2c_gpio_3_reg, h2c_gpio_2_reg, h2c_gpio_1_reg, h2c_gpio_0_reg };
   
   
   always@( posedge clk)
     begin
	if (~resetn)
	  begin
	     c2h_intr_in_ff<=0;
	  end
	else
	  begin
	     c2h_intr_in_ff<=c2h_intr_in;
	  end
     end
   

   assign c2h_intr_in_posedge = c2h_intr_in & ~c2h_intr_in_ff ;
   assign c2h_intr_in_negedge = ~c2h_intr_in & c2h_intr_in_ff ;

   assign c2h_intr_in_posedge_0 = c2h_intr_in_posedge[31:0]  ;
   assign c2h_intr_in_negedge_0 = c2h_intr_in_negedge[31:0]  ;

   assign c2h_intr_in_posedge_1 =c2h_intr_in_posedge[63:32] ;
   assign c2h_intr_in_negedge_1 =c2h_intr_in_negedge[63:32] ;

   

   integer i;
   // Getting the status of c2h intr in register
   always@(posedge clk)
     begin
	for (i = 0; i < 32; i = i + 1) begin
	   if(~resetn) begin
	      ih2rb_c2h_intr_status_0_reg[i] <= 1'b0;
	      ih2rb_c2h_intr_status_0_reg_we[i] <= 1'b0;
	   end
	   else begin
	      ih2rb_c2h_intr_status_0_reg[i] <= c2h_intr_in[i];
	      ih2rb_c2h_intr_status_0_reg_we[i] <= 1'b1;
	   end
	end
     end


   // Getting the status of c2h intr in register
   always@(posedge clk)
     begin
	for (i = 0; i < 32; i = i + 1) begin
	   if(~resetn) begin
	      ih2rb_c2h_intr_status_1_reg[i] <= 1'b0;
	      ih2rb_c2h_intr_status_1_reg_we[i] <= 1'b0;
	   end
	   else begin
	      ih2rb_c2h_intr_status_1_reg[i] <= c2h_intr_in[i+32];
	      ih2rb_c2h_intr_status_1_reg_we[i] <= 1'b1;
	   end
	end
     end


   
   // Toggle_status register indicates if there was any Posedge or Negedge on
   // the c2h_intr_*
   always @(posedge clk)
     begin
	for (i = 0; i < 32; i = i + 1) begin
           if (~resetn)
	     begin
		ih2rb_intr_c2h_toggle_status_0_reg[i] <= 'h0;
		ih2rb_intr_c2h_toggle_status_0_reg_we[i] <= 'h0;
	     end
	   // If toggle_status bit is low, then look for any pulse, posedge or negedge
           else if (~ih2rb_intr_c2h_toggle_status_0_reg[i])
	     begin
		// When there is a pulse for posedge or Negedge, set the toggle_status bit to 1/
		// Provided toggle_status bit was 0 before, else don't do anything
		ih2rb_intr_c2h_toggle_status_0_reg[i] <= ( c2h_intr_in_posedge_0[i] | c2h_intr_in_negedge_0[i] ) ;
		ih2rb_intr_c2h_toggle_status_0_reg_we[i] <= 1'b1;
	     end
	   // If toggle_status bit is not low, means due to posedge/negedge it got high,
	   // then wait for Clear to be 1. till then keep toggle_status bit to 1.
	   // If clear becomes 1, then again wait for posedge/negedge 
	   else if (~intr_c2h_toggle_clear_0_reg[i])
	     begin
		ih2rb_intr_c2h_toggle_status_0_reg[i] <= 1'b1 ;
		ih2rb_intr_c2h_toggle_status_0_reg_we[i] <= 1'b1;
	     end
	   else
	     begin
		ih2rb_intr_c2h_toggle_status_0_reg[i] <= 1'b0 ;
		ih2rb_intr_c2h_toggle_status_0_reg_we[i] <= 1'b1;
	     end
	end 
     end // always @ (posedge clk)


   always @(posedge clk)
     begin
	for (i = 0; i < 32; i = i + 1) begin
           if (~resetn)
	     begin
		ih2rb_intr_c2h_toggle_status_1_reg[i] <= 'h0;
		ih2rb_intr_c2h_toggle_status_1_reg_we[i] <= 'h0;
	     end
	   // If toggle_status bit is low, then look for any pulse, posedge or negedge
           else if (~ih2rb_intr_c2h_toggle_status_1_reg[i])
	     begin
		// When there is a pulse for posedge or Negedge, set the toggle_status bit to 1/
		// Provided toggle_status bit was 0 before, else don't do anything
		ih2rb_intr_c2h_toggle_status_1_reg[i] <= ( c2h_intr_in_posedge_1[i] | c2h_intr_in_negedge_1[i] ) ;
		ih2rb_intr_c2h_toggle_status_1_reg_we[i] <= 1'b1;
	     end
	   // If toggle_status bit is not low, means due to posedge/negedge it got high,
	   // then wait for Clear to be 1. till then keep toggle_status bit to 1.
	   // If clear becomes 1, then again wait for posedge/negedge 
	   else if (~intr_c2h_toggle_clear_1_reg[i])
	     begin
		ih2rb_intr_c2h_toggle_status_1_reg[i] <= 1'b1 ;
		ih2rb_intr_c2h_toggle_status_1_reg_we[i] <= 1'b1;
	     end
	   else
	     begin
		ih2rb_intr_c2h_toggle_status_1_reg[i] <= 1'b0 ;
		ih2rb_intr_c2h_toggle_status_1_reg_we[i] <= 1'b1;
	     end
	end 
     end // always @ (posedge clk)


   
   
   always @(posedge clk)
     begin
        if (~resetn)
          begin
             ih2rb_c2h_gpio_0_reg <= 'h0;
             ih2rb_c2h_gpio_0_reg_we <= 'h0;
          end
        else
          begin
             ih2rb_c2h_gpio_0_reg <= c2h_gpio_in[31:0];
             ih2rb_c2h_gpio_0_reg_we <= {32{1'b1}};
          end
     end // always @ (posedge clk)


   always @(posedge clk)
     begin
        if (~resetn)
          begin
             ih2rb_c2h_gpio_1_reg <= 'h0;
             ih2rb_c2h_gpio_1_reg_we <= 'h0;
          end
        else
          begin
             ih2rb_c2h_gpio_1_reg <= c2h_gpio_in[63:32];
             ih2rb_c2h_gpio_1_reg_we <= {32{1'b1}};
          end
     end // always @ (posedge clk)


   
   always @(posedge clk)
     begin
        if (~resetn)
          begin
             ih2rb_c2h_gpio_2_reg <= 'h0;
             ih2rb_c2h_gpio_2_reg_we <= 'h0;
          end
        else
          begin
             ih2rb_c2h_gpio_2_reg <= c2h_gpio_in[95:64];
             ih2rb_c2h_gpio_2_reg_we <= {32{1'b1}};
          end
     end // always @ (posedge clk)



   always @(posedge clk)
     begin
        if (~resetn)
          begin
             ih2rb_c2h_gpio_3_reg <= 'h0;
             ih2rb_c2h_gpio_3_reg_we <= 'h0;
          end
        else
          begin
             ih2rb_c2h_gpio_3_reg <= c2h_gpio_in[127:96];
             ih2rb_c2h_gpio_3_reg_we <= {32{1'b1}};
          end
     end // always @ (posedge clk)



   always @(posedge clk)
     begin
        if (~resetn)
          begin
             ih2rb_c2h_gpio_4_reg <= 'h0;
             ih2rb_c2h_gpio_4_reg_we <= 'h0;
          end
        else
          begin
             ih2rb_c2h_gpio_4_reg <= c2h_gpio_in[159:128];
             ih2rb_c2h_gpio_4_reg_we <= {32{1'b1}};
          end
     end // always @ (posedge clk)



   always @(posedge clk)
     begin
        if (~resetn)
          begin
             ih2rb_c2h_gpio_5_reg <= 'h0;
             ih2rb_c2h_gpio_5_reg_we <= 'h0;
          end
        else
          begin
             ih2rb_c2h_gpio_5_reg <= c2h_gpio_in[191:160];
             ih2rb_c2h_gpio_5_reg_we <= {32{1'b1}};
          end
     end // always @ (posedge clk)



   always @(posedge clk)
     begin
        if (~resetn)
          begin
             ih2rb_c2h_gpio_6_reg <= 'h0;
             ih2rb_c2h_gpio_6_reg_we <= 'h0;
          end
        else
          begin
             ih2rb_c2h_gpio_6_reg <= c2h_gpio_in[223:192];
             ih2rb_c2h_gpio_6_reg_we <= {32{1'b1}};
          end
     end // always @ (posedge clk)



   always @(posedge clk)
     begin
        if (~resetn)
          begin
             ih2rb_c2h_gpio_7_reg <= 'h0;
             ih2rb_c2h_gpio_7_reg_we <= 'h0;
          end
        else
          begin
             ih2rb_c2h_gpio_7_reg <= c2h_gpio_in[255:224];
             ih2rb_c2h_gpio_7_reg_we <= {32{1'b1}};
          end
     end // always @ (posedge clk)

   


   
   always @(posedge clk)
     begin
        if (~resetn)
          h2c_intr_out <= 'h0;
        else 
          h2c_intr_out <= { h2c_intr_3_reg, h2c_intr_2_reg, h2c_intr_1_reg, h2c_intr_0_reg };
     end
   


`ifdef INTR_ACK
   // FSM

   reg [1:0] state;
   reg [1:0] next_state;

   localparam IDLE = 2'b00;
   localparam ASSERT_INTR = 2'b01;
   localparam ASSERT_ACK = 2'b10;
   localparam DEASSERT_INTR = 2'b11;

   

   always @(posedge clk) // always block to update state
     begin
	if (~resetn)
	  state <= IDLE;
	else
	  state <= next_state;
     end


   always @(*) // always block to compute nextstate
     begin
        case(state)
          IDLE:begin 
             if(
		(|({(intr_c2h_toggle_status_0_reg & intr_c2h_toggle_enable_0_reg)
		    || (intr_c2h_toggle_status_1_reg & intr_c2h_toggle_enable_1_reg)}))
		|| (|(intr_error_status_reg & intr_error_enable_reg))
		|| (|(rd_req_intr_comp_status_reg & rd_req_intr_comp_enable_reg))
		|| (|(wr_req_intr_comp_status_reg & wr_req_intr_comp_enable_reg))
		|| (|(sn_resp_intr_comp_status_reg & sn_resp_intr_comp_enable_reg))
		|| (|(sn_data_intr_comp_status_reg & sn_data_intr_comp_enable_reg))
		|| (|(rd_resp_fifo_fill_level_reg) & intr_fifo_enable_en_rd_resp_fifo_nonempty)
		|| (|(wr_resp_fifo_fill_level_reg) & intr_fifo_enable_en_wr_resp_fifo_nonempty)
		|| (|(sn_req_fifo_fill_level_reg) & intr_fifo_enable_en_sn_req_fifo_nonempty)
		)
               next_state <= ASSERT_INTR;
             else
               next_state <= IDLE;
          end
          ASSERT_INTR:begin
             if(irq_ack)
               next_state <= ASSERT_ACK ;
             else
               next_state <= ASSERT_INTR;
          end
          ASSERT_ACK:begin
             if(~(
		  (|({(intr_c2h_toggle_status_0_reg & intr_c2h_toggle_enable_0_reg)
		      || (intr_c2h_toggle_status_1_reg & intr_c2h_toggle_enable_1_reg)}))
		  || (|(intr_error_status_reg & intr_error_enable_reg))
		  || (|(rd_req_intr_comp_status_reg & rd_req_intr_comp_enable_reg))
		  || (|(wr_req_intr_comp_status_reg & wr_req_intr_comp_enable_reg))
		  || (|(sn_resp_intr_comp_status_reg & sn_resp_intr_comp_enable_reg))
		  || (|(sn_data_intr_comp_status_reg & sn_data_intr_comp_enable_reg))
		  || (|(rd_resp_fifo_fill_level_reg) & intr_fifo_enable_en_rd_resp_fifo_nonempty)
		  || (|(wr_resp_fifo_fill_level_reg) & intr_fifo_enable_en_wr_resp_fifo_nonempty)
		  || (|(sn_req_fifo_fill_level_reg) & intr_fifo_enable_en_sn_req_fifo_nonempty)
		  )
		)
               next_state <= DEASSERT_INTR;
             else
               next_state <= ASSERT_ACK;
          end
          DEASSERT_INTR: begin
             if (irq_ack)
               next_state <= IDLE;
             else
               next_state <= DEASSERT_INTR;
          end
        endcase
     end



   always @(*) // always block to compute output
			     begin
				case(state)
				  IDLE: irq_out <= 1'b0;
				  ASSERT_INTR: irq_out <= 1'b1;
				  ASSERT_ACK:  irq_out <= 1'b1;
				  DEASSERT_INTR: irq_out <= 1'b0;
				endcase
			     end

`else  

   assign irq_out = (
		     (|({(intr_c2h_toggle_status_0_reg & intr_c2h_toggle_enable_0_reg)
			 || (intr_c2h_toggle_status_1_reg & intr_c2h_toggle_enable_1_reg)}))
		     || (|(intr_error_status_reg & intr_error_enable_reg))
		     || (|(rd_req_intr_comp_status_reg & rd_req_intr_comp_enable_reg))
		     || (|(wr_req_intr_comp_status_reg & wr_req_intr_comp_enable_reg))
		     || (|(sn_resp_intr_comp_status_reg & sn_resp_intr_comp_enable_reg))
		     || (|(sn_data_intr_comp_status_reg & sn_data_intr_comp_enable_reg))
		     || (|(rd_resp_fifo_fill_level_reg) & intr_fifo_enable_en_rd_resp_fifo_nonempty)
		     || (|(wr_resp_fifo_fill_level_reg) & intr_fifo_enable_en_wr_resp_fifo_nonempty)
		     || (|(sn_req_fifo_fill_level_reg) & intr_fifo_enable_en_sn_req_fifo_nonempty)
		     );
`endif   

endmodule // intr_handler_mst

/* intr_handler_mst.v ends here */
