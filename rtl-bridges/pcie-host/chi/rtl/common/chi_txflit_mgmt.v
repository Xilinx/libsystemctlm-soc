/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Heramb Aligave.
 *            Alok Mistry.
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
 *   chi tx side flit management
 *
 */


module  chi_txflit_mgmt  
  (
   input 	    clk, 
   input 	    rst_n,
  
   //to/from register interface
   input [14:0]     own_flit, 
   input 	    credit_avail, 
   input 	    link_up, 
   input 	    clear_ownership,
   output reg 	    read_req,
   output reg 	    flit_pending,
   output reg [3:0] read_addr, 
   output reg 	    flit_valid, 
   output [14:0]    ownership     
   );


   

   parameter IDLE=3'b000,
     READ_REQ=3'b001, 
     WAIT_FOR_FLIT =3'b010,
     SEND_FLIT =3'b011,
     CHECK_CREDIT=3'b100;

   wire [2:0] 	    flit_mgmt_state;
   reg [2:0] 	    flit_mgmt_state_i;
   reg 		    own_flit_prg;
   reg [14:0] 	    own_reg;
   wire [14:0] 	    own_flip;
   reg [14:0] 	    update_own_reg;
   

   assign own_flip = own_flit;
   assign ownership = own_reg;
   
   integer 	    k;
   
   //************************************************************************************************/
   //Setting the Ownership Register as Flits are sent
   //************************************************************************************************/
   always@( posedge clk) begin
      for(k=0;k<15;k=k+1) begin
	 if(~rst_n) begin
	    own_reg[k] <= 0;
	 end
	 else if (~own_reg[k])begin
	    own_reg[k] <= own_flip[k];
	 end
	 else begin
	    if(update_own_reg[k]) begin
	       own_reg[k]<= ~update_own_reg[k];
	    end
	    else begin
	       own_reg[k]<= own_reg[k];
	    end
	 end
      end
   end
   
   
   assign flit_mgmt_state = flit_mgmt_state_i;


   //************************************************************************************************/
   //Resetting the configure bridge will not have affect as that is not
   //a graceful exit
   //State machine or transmitting Flit
   //Flits are received from Memory it takes few cycles to read Flit once read
   //request is given.
   //Flits are sent only when Link is Up and Credits are available
   //************************************************************************************************/
   always @ (posedge clk ) 
     begin  
	if( ~rst_n) begin 
           flit_mgmt_state_i        <= IDLE;
	   own_flit_prg             <= 0;
	   read_req                 <= 1'b0;
	   flit_valid               <= 1'b0;
	   read_addr <= 0;
	   flit_pending <= 1'b0;
	   update_own_reg <=0 ;
	end
	else begin
           own_flit_prg <= |own_reg;
	   read_req <= 1'b0;
	   flit_valid <= 1'b0;
	   flit_pending <= 1'b0;
	   case(flit_mgmt_state)
	     IDLE:begin
		if (own_flit_prg & credit_avail) 
		  //credits available and flits to be sent
                  flit_mgmt_state_i <= READ_REQ;
                else 
                  flit_mgmt_state_i <= IDLE;
	     end
             READ_REQ: begin
	        if  (own_flit_prg & credit_avail) begin
	           read_req <= 1'b1;
		   flit_mgmt_state_i <= WAIT_FOR_FLIT;
                end 
		else
		  flit_mgmt_state_i <= IDLE;
	     end
             WAIT_FOR_FLIT : begin
	        flit_pending <= 1'b1;
	        if(read_addr   < 4'he)
                  read_addr <= read_addr + 1'b1;
                else if (read_addr == 4'he)
                  read_addr <= 0;

		update_own_reg[read_addr] <= 1'b1;
		//Don't update here, do it once gone out of bridge
                flit_mgmt_state_i <= SEND_FLIT;
	     end
             SEND_FLIT: begin
		if(link_up) begin                           
		   flit_valid <= 1'b1;
                   flit_mgmt_state_i <= CHECK_CREDIT;
		end
	     end
             CHECK_CREDIT: begin
                if  (own_flit_prg & credit_avail) begin
		   update_own_reg <= 0;
                   flit_mgmt_state_i        <= READ_REQ;
		end
		else begin
		   update_own_reg <= 0;
		   flit_mgmt_state_i        <= IDLE;
		end
	     end
             default : begin flit_mgmt_state_i <= IDLE; end			
	   endcase
	end 
     end 

   
   

endmodule

