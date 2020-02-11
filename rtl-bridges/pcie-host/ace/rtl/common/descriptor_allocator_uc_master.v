/*
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Alok Mistry.
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
 *   Descriptor Allocator to store ownership flip request
 *
 *
 */

`include "defines_common.vh"

module  descriptor_allocator_uc_master  
  #(
    parameter 
    MAX_DESC=16
    )
   (
    //Clks & Reset
    input 			    axi_aclk,
    input 			    axi_aresetn,
   
    // arnext &  awnext indicates axvalid/axready handshake
    input 			    arnext,
    input 			    awnext,
   
    // Getting txn type of each descriptors into this block
    input 			    desc_0_txn_type,
    input 			    desc_1_txn_type,
    input 			    desc_2_txn_type,
    input 			    desc_3_txn_type,
    input 			    desc_4_txn_type,
    input 			    desc_5_txn_type,
    input 			    desc_6_txn_type,
    input 			    desc_7_txn_type,
    input 			    desc_8_txn_type,
    input 			    desc_9_txn_type,
    input 			    desc_10_txn_type,
    input 			    desc_11_txn_type,
    input 			    desc_12_txn_type,
    input 			    desc_13_txn_type,
    input 			    desc_14_txn_type,
    input 			    desc_15_txn_type,

    // wdata_pending_fifo_full indicateds that all axi requests
    // are now filled into fifo, no more are allowed ( Ideally should
    // Never be full as ownership is allowed til MAX_DESC
    input 			    wdata_pending_fifo_full,

    // When write and read are begin sent to bus,
    // other blocks are processing it for futher info,
    // So halting fetching new desc ID untill current one
    // is processed by other blocks
    input 			    wr_desc_allocation_in_progress,
    input 			    rd_desc_allocation_in_progress,

    // used to create a pulse once any ownership is given
    input [MAX_DESC-1:0] 	    uc2rb_ownership_reg,

    // Outputs
    // For other blocks to know which WR/RD DESC ID is to be
    // placed on BUS
    output [(`CLOG2(MAX_DESC))-1:0] write_request_id,
    output [(`CLOG2(MAX_DESC))-1:0] read_request_id,

    // Corresponding Enables, when en =1, on the next cycle
    // *request_id is valid. This is basically same as FIFO EN
    output 			    read_request_en,
    output 			    write_request_en
    );



   // Regs & Wire
   
   reg [MAX_DESC-1:0] 		    OWNERSHIP_reg_ff;
   reg [MAX_DESC-1:0] 		    OWNERSHIP_reg_ff2;
   reg [MAX_DESC-1:0] 		    desc_fifo_write_pend;
   reg [MAX_DESC-1:0] 		    desc_fifo_write_done;
   reg 				    desc_alloc_fifo_state;
   reg [(`CLOG2(MAX_DESC))-1:0]     desc_write_id;
   reg 				    desc_write_en;
   reg 				    desc_rd_req_read_en;
   reg 				    desc_wr_req_read_en;
   reg 				    fetch_rd_req_fifo_state;
   reg 				    fetch_wr_req_fifo_state;
   
   
   wire [MAX_DESC-1:0] 		    int_wire_desc_n_txn_type_wr_rd;
   wire [MAX_DESC-1:0] 		    OWNERSHIP_reg_pulse;
   wire 			    desc_rd_req_fifo_full;
   wire 			    desc_rd_req_fifo_empty;
   wire 			    desc_wr_req_fifo_full;
   wire 			    desc_wr_req_fifo_empty;
   wire [(`CLOG2(MAX_DESC))-1:0]    desc_rd_req_id_out;
   wire [(`CLOG2(MAX_DESC))-1:0]    desc_wr_req_id_out;


   ////////////////////////////////////////////////
   //
   //	write and read request_id out
   //
   //////////////////////////////////////////////

   assign write_request_id = desc_wr_req_id_out;
   assign read_request_id = desc_rd_req_id_out;

   assign read_request_en = desc_rd_req_read_en;
   assign write_request_en = desc_wr_req_read_en;

   // 1D-2D Mapping
   assign int_wire_desc_n_txn_type_wr_rd[0] = desc_0_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[1] = desc_1_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[2] = desc_2_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[3] = desc_3_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[4] = desc_4_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[5] = desc_5_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[6] = desc_6_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[7] = desc_7_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[8] = desc_8_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[9] = desc_9_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[10] = desc_10_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[11] = desc_11_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[12] = desc_12_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[13] = desc_13_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[14] = desc_14_txn_type;
   assign int_wire_desc_n_txn_type_wr_rd[15] = desc_15_txn_type;



   ///////////////////////////////////////////////////
   //
   // Creating Pulse from ownership reg
   //
   //////////////////////////////////////////////////
   
   `FF(axi_aclk,~axi_aresetn, uc2rb_ownership_reg[MAX_DESC-1:0], OWNERSHIP_reg_ff )
   `FF(axi_aclk,~axi_aresetn, OWNERSHIP_reg_ff, OWNERSHIP_reg_ff2 )

   assign OWNERSHIP_reg_pulse = (uc2rb_ownership_reg & ~OWNERSHIP_reg_ff2);


   ///////////////////////////////////////////////////////////////////////////
   //
   // Detecting Ownership pulse and putting it in write_pending register
   //
   ///////////////////////////////////////////////////////////////////////////
   genvar 			    i;
   generate
      for(i=0;i<MAX_DESC;i=i+1) begin:desc_fifo_pen
	 always @ (posedge axi_aclk)
	   begin
	      
	      if(~axi_aresetn) begin
		 desc_fifo_write_pend[i] <= 0;
	      end
	      else if(OWNERSHIP_reg_pulse[i] && (~desc_fifo_write_pend[i])) begin
		 desc_fifo_write_pend[i]<=1;
	      end
	      else if (desc_fifo_write_done[i]) begin
		 desc_fifo_write_pend[i]<=0;
	      end
	   end
      end
   endgenerate
   
   


   ////////////////////////////////////////////////////////////////////
   //
   // FSM to write IDs from pending reg into into FIFO.
   //
   /////////////////////////////////////////////////////////////////

   localparam DESC_ALLOC_FIFO_IDLE =1'b0,DESC_ALLOC_FIFO_WRITE = 1'b1;
   
   always@ (posedge axi_aclk) 
     begin
	if(~axi_aresetn) 
	  begin
	     desc_write_en<=0;
	     desc_fifo_write_done<=0;
	     desc_alloc_fifo_state <= DESC_ALLOC_FIFO_IDLE;
	  end
	else 
	  begin
	     case (desc_alloc_fifo_state) 
	       DESC_ALLOC_FIFO_IDLE: 
		 // desc_fifo_write_pend[x] stays 1, untill that desc entry is
		 // not pushed into Fifo. Scanning of desc starts from 0, so highest prioriy
		 // is given to 0 always.
		 // desc_fifo_write_done[x] indicates that corresponding desc entry is done into
		 // fifo, so it is removed from desc_fifo_write_pend[x]
		 if(desc_fifo_write_pend[0] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<=0;
		    desc_write_en<=1;
		    desc_fifo_write_done[0]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
		 else if(desc_fifo_write_pend[1] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<=1;
		    desc_write_en<=1;
		    desc_fifo_write_done[1]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
		 else if(desc_fifo_write_pend[2] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<=2;
		    desc_write_en<=1;
		    desc_fifo_write_done[2]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
		 else if(desc_fifo_write_pend[3] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<=3;
		    desc_write_en<=1;
		    desc_fifo_write_done[3]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
		 else if(desc_fifo_write_pend[4] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<=4;
		    desc_write_en<=1;
		    desc_fifo_write_done[4]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
	       
		 else if(desc_fifo_write_pend[5] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<=5;
		    desc_write_en<=1;
		    desc_fifo_write_done[5]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
	       
		 else if(desc_fifo_write_pend[6] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<=6;
		    desc_write_en<=1;
		    desc_fifo_write_done[6]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
		 else if(desc_fifo_write_pend[7] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<=7;
		    desc_write_en<=1;
		    desc_fifo_write_done[7]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
	       
		 else if(desc_fifo_write_pend[8] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<=8;
		    desc_write_en<=1;
		    desc_fifo_write_done[8]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
		 else if(desc_fifo_write_pend[9] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<=9;
		    desc_write_en<=1;
		    desc_fifo_write_done[9]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
		 else if(desc_fifo_write_pend[10] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<='hA;
		    desc_write_en<=1;
		    desc_fifo_write_done[10]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
	       
		 else if(desc_fifo_write_pend[11] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<='hB;
		    desc_write_en<=1;
		    desc_fifo_write_done[11]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
		 else if(desc_fifo_write_pend[12] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<='hC;
		    desc_write_en<=1;
		    desc_fifo_write_done[12]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
		 else if(desc_fifo_write_pend[13] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<='hD;
		    desc_write_en<=1;
		    desc_fifo_write_done[13]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
	       
		 else if(desc_fifo_write_pend[14] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<='hE;
		    desc_write_en<=1;
		    desc_fifo_write_done[14]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
	       
		 else if(desc_fifo_write_pend[15] && ~desc_rd_req_fifo_full && ~desc_wr_req_fifo_full) begin
		    desc_write_id<='hF;
		    desc_write_en<=1;
		    desc_fifo_write_done[15]<=1;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_WRITE;
		 end
	       
	       //If no pending keep en low
		 else begin
		    desc_write_id<=0;
		    desc_write_en<=0;
		    desc_fifo_write_done<=0;
		    desc_alloc_fifo_state <= DESC_ALLOC_FIFO_IDLE;
		 end
	       
	       DESC_ALLOC_FIFO_WRITE: 
		 //In the next cycle deasert write_en	
		 begin
		    desc_write_id<=0;
		    desc_write_en<=0;
		    desc_alloc_fifo_state<=DESC_ALLOC_FIFO_IDLE;
		 end
	       default: desc_alloc_fifo_state <= DESC_ALLOC_FIFO_IDLE;
	     endcase
	  end
     end
   
   


   ////////////////////////////////////////////////////////////////////
		 //
   // FSM to fetch desc IDs from rd FIFO.
   //
   /////////////////////////////////////////////////////////////////

   localparam 
     FETCH_RD_REQ_FIFO_IDLE = 1'b0,
     FETCH_RD_REQ_FIFO_READ = 1'b1;

   always@ (posedge axi_aclk) 
     begin
	if(~axi_aresetn) 
	  begin
	     desc_rd_req_read_en<=0;
	     fetch_rd_req_fifo_state<=FETCH_RD_REQ_FIFO_IDLE;
	  end 
	else 
	  begin
	     case (fetch_rd_req_fifo_state) 
	       FETCH_RD_REQ_FIFO_IDLE:
		 //Pop fifo only if it's not empty
		 if(~desc_rd_req_fifo_empty && ~rd_desc_allocation_in_progress)
		   begin
		      desc_rd_req_read_en<=1;
		      fetch_rd_req_fifo_state<=FETCH_RD_REQ_FIFO_READ;
		   end
	       FETCH_RD_REQ_FIFO_READ:
		 //If Slave is accepting AW and AR Go and send
		 //Next AW or AR on the bus
		 if(arnext) begin
		    desc_rd_req_read_en<=0;
		    fetch_rd_req_fifo_state<=FETCH_RD_REQ_FIFO_IDLE;
		 end
		 else begin
		    desc_rd_req_read_en<=0;
		    fetch_rd_req_fifo_state<=FETCH_RD_REQ_FIFO_READ;
		 end
	     endcase
	  end
     end
   
   ////////////////////////////////////////////////////////////////////
		 //
   // FSM to fetch desc IDs from wr FIFO.
   //
   /////////////////////////////////////////////////////////////////
   
   localparam 
     FETCH_WR_REQ_FIFO_IDLE = 1'b0,
     FETCH_WR_REQ_FIFO_READ = 1'b1;
   
   always@ (posedge axi_aclk) 
     begin
	if(axi_aresetn==0) 
	  begin
	     desc_wr_req_read_en<=0;
	     fetch_wr_req_fifo_state<=FETCH_WR_REQ_FIFO_IDLE;
	  end 
	else 
	  begin
	     case (fetch_wr_req_fifo_state) 
	       FETCH_WR_REQ_FIFO_IDLE:
		 //Pop fifo only if it's not empty & no any axi transfer
		 //is in progress ( indicated by wdata_pending_fifo_full ).
		 if(~desc_wr_req_fifo_empty && ~wdata_pending_fifo_full && ~wr_desc_allocation_in_progress) 
		   begin
		      desc_wr_req_read_en<=1;
		      fetch_wr_req_fifo_state<=FETCH_WR_REQ_FIFO_READ;
		   end
	       FETCH_WR_REQ_FIFO_READ:
		 //If Slave is accepting AW then send
		 //Next AW on the bus
		 if(awnext) begin
		    desc_wr_req_read_en<=0;
		    fetch_wr_req_fifo_state<=FETCH_WR_REQ_FIFO_IDLE;
		 end
		 else begin
		    desc_wr_req_read_en<=0;
		    fetch_wr_req_fifo_state<=FETCH_WR_REQ_FIFO_READ;
		 end
	     endcase
	  end
     end


   ///////////////////////////////////////////////////////////////////////////////////////
		 //
   // Fifo to store desc id of write requests.
   //
   ///////////////////////////////////////////////////////////////////////////////////////
   
   sync_fifo #(.DEPTH(MAX_DESC),.WIDTH((`CLOG2(MAX_DESC)))) desc_wr_request_id_fifo
     (
      .clk(axi_aclk),
      .rst_n(axi_aresetn),
      .din(desc_write_id),
      .wren(desc_write_en && ~int_wire_desc_n_txn_type_wr_rd[desc_write_id]),
      .empty(desc_wr_req_fifo_empty),
      .full(desc_wr_req_fifo_full),
      .dout(desc_wr_req_id_out),
      .rden(desc_wr_req_read_en)
      );

   ///////////////////////////////////////////////////////////////////////////////////////
   //
   // Fifo to store desc id of read requests
   //
   ///////////////////////////////////////////////////////////////////////////////////////
   
   sync_fifo #(.DEPTH(MAX_DESC),.WIDTH((`CLOG2(MAX_DESC)))) desc_rd_request_id_fifo
     (
      .clk(axi_aclk),
      .rst_n(axi_aresetn),
      .din(desc_write_id),
      .wren(desc_write_en && int_wire_desc_n_txn_type_wr_rd[desc_write_id]),
      .empty(desc_rd_req_fifo_empty),
      .full(desc_rd_req_fifo_full),
      .dout(desc_rd_req_id_out),
      .rden(desc_rd_req_read_en)
      );


endmodule
