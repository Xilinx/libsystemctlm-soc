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
 *   It stores AXID generated on the DUT Interface into FIFOs & fetches
 *   them back as an response comes.
 *
 */

`include "defines_common.vh"

module axid_store 
  #(
    parameter 
    MAX_DESC=16,
    M_AXI_USR_ID_WIDTH=4
    )
   (

    // Clk & Reset
    input 			    axi_aclk,
    input 			    axi_aresetn,
   
    // axnext indicates axvalid/axready handshake on the bus
    input 			    axnext,
   
    // AXID Comes directly from AXI BUS.
    input [M_AXI_USR_ID_WIDTH-1:0]  m_axi_usr_axid,

    // Used when matching response ID with stored AXID and then
    // deallocating it from Fifo
    input [MAX_DESC-1:0] 	    axid_read_en,

    // when pushing new AXID into fIfo, corresponding desc ID
    input [(`CLOG2(MAX_DESC))-1:0]  desc_req_id,

   
    // These are AXID output of each fifo, they are used
    // by other modules to compare response.
    // Generally Fifo points to last data that was read, but
    // in this case, Fifo is modified to put Next data to be read
    // on bus, before even reading it!.
    // It helps to identify order of read responses of same ID request
    // without popping the Fifo.
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id0,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id1,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id2,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id3,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id4,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id5,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id6,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id7,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id8,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id9,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id10,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id11,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id12,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id13,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id14,
    output [(`CLOG2(MAX_DESC))-1:0] axid_response_id15,

   
    //For other blocks to know what all AXID are on bus
    output reg [MAX_DESC-1:0] 	    fifo_id_reg_valid_ff,

    // Each fifo is associated with a unique ID. 
    //For other blocks to know id of each fifo.
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg0,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg1,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg2,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg3,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg4,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg5,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg6,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg7,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg8,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg9,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg10,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg11,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg12,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg13,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg14,
    output [M_AXI_USR_ID_WIDTH-1:0] fifo_id_reg15,
   
    //For handshake with other blocks so that they don't start early
    output reg 			    desc_allocation_in_progress
    );

   

   integer 			    k;
   
   //its 2D array which indicated unique id that went on BUS.
   reg [M_AXI_USR_ID_WIDTH-1:0]     fifo_id_reg[MAX_DESC-1:0];
   //from grant control to get first empty fifo
   reg [(`CLOG2(MAX_DESC))-1:0]     fifo_id_reg_valid_allocate_ff;
   //handshake signal
   reg 				    desc_allocation_is_done;
   reg [MAX_DESC-1:0] 		    axid_write_en_reg;
   reg [MAX_DESC-1:0] 		    send_transfer;
   reg [MAX_DESC-1:0] 		    axid_write_en_reg_allocate;
   reg [MAX_DESC-1:0] 		    axid_read_en_reg_ff;


   
   wire [MAX_DESC-1:0] 		    fifo_id_reg_valid;
   wire [MAX_DESC-1:0] 		    axid_write_en_reg_combined;
   wire [MAX_DESC-1:0] 		    axid_read_en_reg;
   wire [(`CLOG2(MAX_DESC))-1:0]    axid_response_id_reg[MAX_DESC-1:0];
   wire [MAX_DESC-1:0] 		    axid_empty;
   wire [(`CLOG2(MAX_DESC))-1:0]    fifo_id_reg_valid_allocate;
   

   // Fifo id reg valid is indicated by fifo empty
   assign fifo_id_reg_valid = ~axid_empty;
   assign axid_read_en_reg=axid_read_en;


   /////////////////////////////////////////////////////////////////////////
   //
   // Mapping 1D-2D regs.
   //
   ////////////////////////////////////////////////////////////////////////
   
   assign axid_response_id0 = axid_response_id_reg[0];
   assign axid_response_id1 = (MAX_DESC>1) ? axid_response_id_reg[1] : 0;
   assign axid_response_id2 = (MAX_DESC>2) ? axid_response_id_reg[2] : 0;
   assign axid_response_id3 = (MAX_DESC>3) ? axid_response_id_reg[3] : 0;
   assign axid_response_id4 = (MAX_DESC>4) ? axid_response_id_reg[4] : 0;
   assign axid_response_id5 = (MAX_DESC>5) ? axid_response_id_reg[5] : 0;
   assign axid_response_id6 = (MAX_DESC>6) ? axid_response_id_reg[6] : 0;
   assign axid_response_id7 = (MAX_DESC>7) ? axid_response_id_reg[7] : 0;
   assign axid_response_id8 = (MAX_DESC>8) ? axid_response_id_reg[8] : 0;
   assign axid_response_id9 = (MAX_DESC>9) ? axid_response_id_reg[9] : 0;
   assign axid_response_id10= (MAX_DESC>10) ? axid_response_id_reg[10] : 0;
   assign axid_response_id11= (MAX_DESC>11) ? axid_response_id_reg[11] : 0;
   assign axid_response_id12= (MAX_DESC>12) ? axid_response_id_reg[12] : 0;
   assign axid_response_id13= (MAX_DESC>13) ? axid_response_id_reg[13] : 0;
   assign axid_response_id14= (MAX_DESC>14) ? axid_response_id_reg[14] : 0;
   assign axid_response_id15= (MAX_DESC>15) ? axid_response_id_reg[15] : 0;


   assign fifo_id_reg0 = fifo_id_reg[0];
   assign fifo_id_reg1 = (MAX_DESC > 1) ? fifo_id_reg[1] : 0;
   assign fifo_id_reg2 = (MAX_DESC > 2) ? fifo_id_reg[2] : 0;
   assign fifo_id_reg3 = (MAX_DESC > 3) ? fifo_id_reg[3] : 0;
   assign fifo_id_reg4 = (MAX_DESC > 4) ? fifo_id_reg[4] : 0;
   assign fifo_id_reg5 = (MAX_DESC > 5) ? fifo_id_reg[5] : 0;
   assign fifo_id_reg6 = (MAX_DESC > 6) ? fifo_id_reg[6] : 0;
   assign fifo_id_reg7 = (MAX_DESC > 7) ? fifo_id_reg[7] : 0;
   assign fifo_id_reg8 = (MAX_DESC > 8) ? fifo_id_reg[8] : 0;
   assign fifo_id_reg9 = (MAX_DESC > 9) ? fifo_id_reg[9] : 0;
   assign fifo_id_reg10= (MAX_DESC > 10) ? fifo_id_reg[10] : 0;
   assign fifo_id_reg11= (MAX_DESC > 11) ? fifo_id_reg[11] : 0;
   assign fifo_id_reg12= (MAX_DESC > 12) ? fifo_id_reg[12] : 0;
   assign fifo_id_reg13= (MAX_DESC > 13) ? fifo_id_reg[13] : 0;
   assign fifo_id_reg14= (MAX_DESC > 14) ? fifo_id_reg[14] : 0;
   assign fifo_id_reg15= (MAX_DESC > 15) ? fifo_id_reg[15] : 0;

   /////////////////////////////////////////////////////////////////////////
   //
   // Fifo to store desc request which are writes 
   //
   ////////////////////////////////////////////////////////////////////////
   
   genvar 			    i;
   generate 
      for(i=0;i<MAX_DESC;i=i+1) begin:fifo_id_write
	 sync_fifo
	    #(
	      .DEPTH(MAX_DESC), 
	      .WIDTH((`CLOG2(MAX_DESC)))
	      )
	 fifo_id_wr_reg 
	    (
	     .clk(axi_aclk),
	     .rst_n(axi_aresetn),
	     .din(desc_req_id),
	     .wren(axid_write_en_reg_combined[i]),
	     .empty(axid_empty[i]),
	     .full(), //Not used full as requests will never exceed MAX_DESC
	     // This is early output, i.e without even reading data, fifo is always
	     // pointing to what will be next output. So, logic can see what is going to come
	     // and read it repetitively, and still preserve it in fifo. Once the early output data is
	     // processed, it can be popped from fifo.
	     // Use case: When issuing outstanding read requests with different ID, multiple
	     // fifos will be filled with all descriptor IDs. Now when response comes out of order,
	     // the response handling logic just sees what is the Desc ID of corresponding fifo (by loking at
	     // AXID. It need not pop it, as there will multiple data beats that are going to come)
	    
	     .dout_pre(axid_response_id_reg[i]),
	     //.buf_out(axid_response_id_reg[i]),
	     .rden(axid_read_en_reg[i])
	     //.fifo_counter(wdata_fifo_counter),
	     );
      end
   endgenerate
   
   
   
   ////////////////////////////////////////////////////////////////
	      // 
   // Control bit to indicate that AXID allocation is done
   //
   ///////////////////////////////////////////////////////////////
   
   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 desc_allocation_in_progress<=0;
      end
      else if(axnext) begin
	 desc_allocation_in_progress<=1;
      end
      else if(|axid_write_en_reg_combined) begin
	 desc_allocation_in_progress<=0;
      end
      else begin
	 desc_allocation_in_progress<=desc_allocation_in_progress;
      end
   end

   //////////////////////////////////////////////////////////////////////////
   //
   // Logic to identify if the current axid on the bus is unique or already sent before
   // If unique than populate new fifo, if existing than push into existing fifo.
   //
   // Below logic runs in parallel for all MAX_DESC Fifos, in case it maches with anyone 
   // corresponding axid_write_en_reg will trigger, and desc_id will be pushed
   // else it will trigger "send_transfer" which is used in the next cycle to identify 
   // which Fifos are availalbe
   //
   ////////////////////////////////////////////////////////////////////////////////////


   always@(posedge axi_aclk) begin
      for(k=0;k<MAX_DESC;k=k+1) begin	
	 if(~axi_aresetn) begin
	    send_transfer[k]<=0;
	    axid_write_en_reg[k]<=0;
	 end
	 //See if during the transfer, your axid matches with any of the register
	 //If it matches and push the data in it.
	 else if(axnext && (m_axi_usr_axid ==fifo_id_reg[k]) && fifo_id_reg_valid_ff[k]) begin
	    axid_write_en_reg[k]<=1;
	    
	 end
	 else if(axnext) begin
	    axid_write_en_reg[k]<=0;
	    send_transfer[k]<=1;
	 end
	 else	begin
	    axid_write_en_reg[k]<=0;
	    send_transfer[k]<=0;
	 end
      end
   end
   /* NOTE: fifo_id_reg_valid_allocate_ff updates after two cycles, 
    So the next axnext should not come within two cycles of first one */



   /////////////////////////////////////////////////////////////////////////////////////
   //
   // In case new transfer is having unique ID, it won't match with any of the
   // fifo_id_reg. So if none of them matches, "send_transfer" will be all High
   // and fifo_id_reg_valid_allocate will indicate that which is the first empty Fifo,
   // and first empty fifo will be reserved now.
   //
   ///////////////////////////////////////////////////////////////////////////////////
   always@(posedge axi_aclk) begin
      if(~axi_aresetn) begin
	 for(k=0;k<MAX_DESC;k=k+1)
	   begin :for_fifo_id_reg_init_rst
	      fifo_id_reg[k]<=0;
	   end
	 axid_write_en_reg_allocate<=0;
      end
      //allocate only if none of them matches
      else if(send_transfer == {MAX_DESC{1'b1}}) begin
	 fifo_id_reg[fifo_id_reg_valid_allocate_ff]<=m_axi_usr_axid;
	 axid_write_en_reg_allocate[fifo_id_reg_valid_allocate_ff]<=1;
      end
      else begin
	 axid_write_en_reg_allocate<=0;
      end
   end

   assign axid_write_en_reg_combined= axid_write_en_reg_allocate |
				      axid_write_en_reg ;
   
   //flopping reg_valid as to reduce llogic levels.
   `FF(axi_aclk,~axi_aresetn,fifo_id_reg_valid,fifo_id_reg_valid_ff)
   
   //flopping reg_valid allocate to reuce llogic levels
   `FF(axi_aclk,~axi_aresetn,fifo_id_reg_valid_allocate,fifo_id_reg_valid_allocate_ff)

   ////////////////////////////////////////////////////////////////////
   //
   // Grant controller is to see out of all fifo which is the first one
   // to be filled. e.g Fifo_empty[0:3]='b1100. Output will be "2"
   // 1) din='b00111000, gnt_idx = "3"
   // 2) din='b00111010, gnt_idx = "1"
   //
   ///////////////////////////////////////////////////////////////////

   
   grant_controller_master g1 (
      
			       .clk(axi_aclk),
			       .rst_n(axi_aresetn),
			       .din(~fifo_id_reg_valid_ff),
			       .gnt_vld(),
			       .gnt_idx(fifo_id_reg_valid_allocate)
			       );


endmodule
