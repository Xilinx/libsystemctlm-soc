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

`include "defines_common.vh"

module txn_allocator #(

         parameter ADDR_WIDTH                                           = 64    
        ,parameter DATA_WIDTH                                           = 128   
        ,parameter ID_WIDTH                                             = 16  
        ,parameter AWUSER_WIDTH                                         = 32    
        ,parameter WUSER_WIDTH                                          = 32    
        ,parameter BUSER_WIDTH                                          = 32    
        ,parameter ARUSER_WIDTH                                         = 32    
        ,parameter RUSER_WIDTH                                          = 32    
        ,parameter RAM_SIZE                                             = 16384    
        ,parameter MAX_DESC                                             = 16                   

)(

        //Clock and reset
         input 	     	                                                axi_aclk		
        ,input 	     	                                                axi_aresetn		

        //Read Channel
        ,input                                                          rd_txn_valid
        ,input [7:0]                                                    rd_txn_size     //AXLEN (Request is (AXLEN+1))
        ,output reg                                                     rd_alc_valid
        ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0]             rd_alc_offset   //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [9:0]
        ,output reg [(`CLOG2(MAX_DESC))-1:0]                            rd_alc_idx      //For MAX_DESC=16, it is [3:0] 


        //Write Channel
        ,input                                                          wr_txn_valid
        ,input [7:0]                                                    wr_txn_size     //AXLEN (Request is (AXLEN+1))
        ,output reg                                                     wr_alc_valid
        ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0]             wr_alc_offset   //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [9:0]
        ,output reg [(`CLOG2(MAX_DESC))-1:0]                            wr_alc_idx      //For MAX_DESC=16, it is [3:0] 
        
        //Registers
        ,input  [MAX_DESC-1:0]                                          int_ownership_own	
        ,input  [MAX_DESC-1:0]                                          int_status_busy_busy	
        ,input  [MAX_DESC-1:0]                                          rd_txn_cmpl
        ,input  [MAX_DESC-1:0]                                          wr_txn_cmpl
        `include "int_desc_all_as_input.vh"    


);

localparam DESC_IDX_WIDTH                                               = `CLOG2(MAX_DESC);
localparam RAM_OFFSET_WIDTH                                             = `CLOG2((RAM_SIZE*8)/DATA_WIDTH);

localparam RD_IDLE                                                      = 2'b00;
localparam RD_DESC_AVAIL                                                = 2'b01;
localparam RD_ADDR_AVAIL                                                = 2'b10;
localparam RD_DESC_ADDR_AVAIL                                           = 2'b11;

localparam WR_IDLE                                                      = 2'b00;
localparam WR_DESC_AVAIL                                                = 2'b01;
localparam WR_ADDR_AVAIL                                                = 2'b10;
localparam WR_DESC_ADDR_AVAIL                                           = 2'b11;

wire		                                                        DESC_wren;	
reg 		                                                        DESC_rden;	
wire [DESC_IDX_WIDTH-1:0]                                               DESC_din;	
wire [DESC_IDX_WIDTH-1:0]                                               DESC_dout;	
wire  		                                                        DESC_full;	
wire  		                                                        DESC_empty;

reg  [MAX_DESC-1:0]                                                     desc_freeup;

reg                                                                     rd_desc_txn_valid;
reg                                                                     rd_desc_fifo;
reg                                                                     rd_desc_alc_valid;
wire [DESC_IDX_WIDTH-1:0]                                               rd_desc_alc_idx;	

reg                                                                     wr_desc_txn_valid;
reg                                                                     wr_desc_fifo;
reg                                                                     wr_desc_alc_valid;
wire [DESC_IDX_WIDTH-1:0]                                               wr_desc_alc_idx;	

reg  [MAX_DESC-1:0]                                                     int_ownership_own_ff;	

reg                                                                     rd_txn_valid_ff;
reg                                                                     wr_txn_valid_ff;

wire                                                                    rd_addr_alc_valid;
wire [RAM_OFFSET_WIDTH-1:0]                                             rd_addr_alc_offset;           
wire [DESC_IDX_WIDTH-1:0]                                               rd_addr_alc_node_idx;         

reg  [DESC_IDX_WIDTH-1:0]                                               rd_alc_node_idx;	

wire                                                                    wr_addr_alc_valid;
wire [RAM_OFFSET_WIDTH-1:0]                                             wr_addr_alc_offset;           
wire [DESC_IDX_WIDTH-1:0]                                               wr_addr_alc_node_idx;         

reg  [DESC_IDX_WIDTH-1:0]                                               wr_alc_node_idx;	

reg  [1:0]                                                              rd_txn_state;
reg  [1:0]                                                              rd_txn_nextstate;

reg  [1:0]                                                              wr_txn_state;
reg  [1:0]                                                              wr_txn_nextstate;

wire                                                                    gnt_vld;
wire [DESC_IDX_WIDTH-1:0]                                               gnt_idx;


//////////////////////
//2-D array of descriptor fields
//////////////////////

`include "user_slave_desc_2d_all_internal.vh"

/************************Descriptor Allocator Begin************************
 *
 * MAX_DESC descriptors are shared between read and write channel.
 *
 * A descriptor is made available when SW gives ownership to HW for
 * initiating new transation (means when SW gives ownership to HW and descriptor is not busy).
 * This block allocates a new descriptor number to write/rd request when at
 * least one descriptor is available.
 *
 */


//////////////////////Descriptor FIFO PUSH logic//////////////////////

//////////////////////
//Signal : desc_freeup
//Description:
//  Generate a 1-cycle pulse when SW gives ownership to HW and descriptor is not busy
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    int_ownership_own_ff <= 'h0;
  end else begin
    int_ownership_own_ff <= int_ownership_own;
  end
end
generate        		
genvar gi;
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_gi
always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    desc_freeup[gi] <= 1'b0;  
  end else if (int_ownership_own[gi]==1'b1 && int_ownership_own_ff[gi]==1'b0 && int_status_busy_busy[gi]==1'b0) begin //Positive edge detection
    desc_freeup[gi] <= 1'b1;
  end else begin
    desc_freeup[gi] <= 1'b0;
  end
end
end
endgenerate 


//////////////////////
//Grant Controller
//Description :
//  There can be multiple bits of value '1' in desc_freeup. Grant allocator
//  grants to each of the bits but one after the other, so that its index can
//  be pushed to descriptor FIFO(DESC_fifo).
//////////////////////

grant_controller #(
         .MAX_DESC		                        (MAX_DESC)
        ,.EDGE_TYP		                        (1)      //Posedge
) i_grant_controller (
         .det_out                                       ()
        ,.req_out                                       ()
        ,.gnt_out                                       ()
        ,.gnt_vld                                       (gnt_vld)
        ,.gnt_idx                                       (gnt_idx)
        ,.clk		                                (axi_aclk)
        ,.rst_n		                                (axi_aresetn)
        ,.din		                                (desc_freeup)
);
		  
assign DESC_wren = gnt_vld;
assign DESC_din = gnt_idx;  

//////////////////////Descriptor FIFO POP logic//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    rd_txn_valid_ff <= 'h0;
  end else begin
    rd_txn_valid_ff <= rd_txn_valid;
  end
end        		
//rd_desc_txn_valid signal becomes 'high' when a new read txn request comes 
//and remains 'high' until a new descriptor is allocated by reading DESC_fifo. 
always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    rd_desc_txn_valid <= 1'b0;
  //if descriptor is read from DESC_fifo  
  end else if (rd_desc_fifo==1'b1) begin
    rd_desc_txn_valid <= 1'b0;
  //when new read txn request arrives 
  end else if (rd_txn_valid==1'b1 && rd_txn_valid_ff==1'b0) begin 
    rd_desc_txn_valid <= 1'b1;
  end
end


always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    wr_txn_valid_ff <= 'h0;
  end else begin
    wr_txn_valid_ff <= wr_txn_valid;
  end
end        		
//wr_desc_txn_valid signal becomes 'high' when a new write txn request comes 
//and remains 'high' until a new descriptor is allocated by reading DESC_fifo. 
always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    wr_desc_txn_valid <= 1'b0;  
  //if descriptor is read from DESC_fifo  
  end else if (wr_desc_fifo==1'b1) begin
    wr_desc_txn_valid <= 1'b0;
  //when new write txn request arrives
  end else if (wr_txn_valid==1'b1 && wr_txn_valid_ff==1'b0) begin 
    wr_desc_txn_valid <= 1'b1;
  end
end

//When write and read request come together, priority is given to read.
always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    DESC_rden <= 1'b0;
    rd_desc_fifo <= 1'b0;
    wr_desc_fifo <= 1'b0;
  end else if (DESC_rden==1'b1) begin
        DESC_rden <= 1'b0;
        rd_desc_fifo <= 1'b0;
        wr_desc_fifo <= 1'b0;
  end else if (DESC_rden==1'b0 && DESC_empty==1'b0) begin
    case({wr_desc_txn_valid,rd_desc_txn_valid})
      2'b00: begin
        DESC_rden <= 1'b0;
        rd_desc_fifo <= 1'b0;
        wr_desc_fifo <= 1'b0;
      end 2'b01: begin
        DESC_rden <= 1'b1;
        rd_desc_fifo <= 1'b1;
        wr_desc_fifo <= 1'b0;
      end 2'b10: begin
        DESC_rden <= 1'b1;
        rd_desc_fifo <= 1'b0;
        wr_desc_fifo <= 1'b1;
      end 2'b11: begin
        DESC_rden <= 1'b1;
        rd_desc_fifo <= 1'b1;
        wr_desc_fifo <= 1'b0;
      end 
    endcase
  end else begin
    DESC_rden <= 1'b0;
    rd_desc_fifo <= 1'b0;
    wr_desc_fifo <= 1'b0;
  end
end

always @(posedge axi_aclk) begin
  rd_desc_alc_valid <= rd_desc_fifo;
  wr_desc_alc_valid <= wr_desc_fifo;
end

assign rd_desc_alc_idx = DESC_dout;  
assign wr_desc_alc_idx = DESC_dout;  

//////////////////////Descriptor FIFO//////////////////////
sync_fifo #(
          .WIDTH		                        (DESC_IDX_WIDTH)
         ,.DEPTH		                        (MAX_DESC)
) DESC_fifo (
          .dout	                                        (DESC_dout)
         ,.full	                                        (DESC_full)
         ,.empty	                                (DESC_empty)
         ,.clk	                                        (axi_aclk)
         ,.rst_n	                                (axi_aresetn)
         ,.wren	                                        (DESC_wren)
         ,.rden	                                        (DESC_rden)
         ,.din	                                        (DESC_din)
);
   
/************************Descriptor Allocator End************************/


/************************Address Allocator Begin************************
 *
 * RDATA(for read) and WDATA/WSTRB(for write) RAM offset allocator and deallocator 
 *
 */

///////////////////////
//Read-Channel Address Allocator
//////////////////////

addr_allocator #(
         .ADDR_WIDTH		                        (ADDR_WIDTH)
        ,.DATA_WIDTH		                        (DATA_WIDTH)
        ,.ID_WIDTH		                        (ID_WIDTH)
	,.AWUSER_WIDTH                                  (AWUSER_WIDTH)
	,.WUSER_WIDTH                                   (WUSER_WIDTH)
	,.BUSER_WIDTH                                   (BUSER_WIDTH)
	,.ARUSER_WIDTH                                  (ARUSER_WIDTH)
	,.RUSER_WIDTH                                   (RUSER_WIDTH)
        ,.RAM_SIZE		                        (RAM_SIZE)
        ,.MAX_DESC		                        (MAX_DESC)
) rd_addr_allocator (
         .addr_alc_valid	                        (rd_addr_alc_valid)
        ,.addr_alc_offset                               (rd_addr_alc_offset)
        ,.axi_aclk	                                (axi_aclk)
        ,.axi_aresetn	                                (axi_aresetn)
        ,.txn_valid	                                (rd_txn_valid)
        ,.txn_size	                                (rd_txn_size)
        ,.txn_cmpl	                                (rd_txn_cmpl)
        ,.addr_alc_node_idx                             (rd_addr_alc_node_idx) 
        ,.alc_valid                                     (rd_alc_valid)
        ,.alc_desc_idx                                  (rd_alc_idx) 
        ,.alc_node_idx                                  (rd_alc_node_idx) 
);

///////////////////////
//Write-Channel Address Allocator
//////////////////////

addr_allocator #(
         .ADDR_WIDTH		                        (ADDR_WIDTH)
        ,.DATA_WIDTH		                        (DATA_WIDTH)
        ,.ID_WIDTH		                        (ID_WIDTH)
	,.AWUSER_WIDTH                                  (AWUSER_WIDTH)
	,.WUSER_WIDTH                                   (WUSER_WIDTH)
	,.BUSER_WIDTH                                   (BUSER_WIDTH)
	,.ARUSER_WIDTH                                  (ARUSER_WIDTH)
	,.RUSER_WIDTH                                   (RUSER_WIDTH)
        ,.RAM_SIZE		                        (RAM_SIZE)
        ,.MAX_DESC		                        (MAX_DESC)
) wr_addr_allocator (
         .addr_alc_valid	                        (wr_addr_alc_valid)
        ,.addr_alc_offset                               (wr_addr_alc_offset)
        ,.axi_aclk	                                (axi_aclk)
        ,.axi_aresetn	                                (axi_aresetn)
        ,.txn_valid	                                (wr_txn_valid)
        ,.txn_size	                                (wr_txn_size)
        ,.txn_cmpl	                                (wr_txn_cmpl)
        ,.addr_alc_node_idx                             (wr_addr_alc_node_idx) 
        ,.alc_valid                                     (wr_alc_valid)
        ,.alc_desc_idx                                  (wr_alc_idx) 
        ,.alc_node_idx                                  (wr_alc_node_idx) 
);

/************************Address Allocator End************************/

/************************Transaction Allocator Begin************************
 *
 * Read and write transaction allocator allocates descriptor number and dataram offset. 
 *
 */


///////////////////////
//Signal :
//  rd_alc_valid
//  rd_alc_idx
//  rd_alc_offset
//  rd_alc_node_idx
//Description :
//  Generate rd_alc_valid When descriptor and offset both are available for a read request.
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    rd_alc_idx <= 'b0;
  end else if (rd_desc_alc_valid==1'b1) begin
    rd_alc_idx <= rd_desc_alc_idx;
  end
end

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    rd_alc_offset <= 'b0;
  end else if (rd_addr_alc_valid==1'b1) begin
    rd_alc_offset <= rd_addr_alc_offset;
  end
end

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    rd_alc_node_idx <= 'b0;
  end else if (rd_addr_alc_valid==1'b1) begin
    rd_alc_node_idx <= rd_addr_alc_node_idx;
  end
end

always @(posedge axi_aclk) begin
if (axi_aresetn == 1'b0) begin
  rd_txn_state <= RD_IDLE;
end else begin 
  case(rd_txn_state)
  RD_IDLE: begin
   case({rd_addr_alc_valid,rd_desc_alc_valid}) 
   2'b00: begin
     rd_txn_state<= RD_IDLE;
     rd_alc_valid<= 1'b0;
   end 2'b01: begin
     rd_txn_state<= RD_DESC_AVAIL;
     rd_alc_valid<= 1'b0;
   end 2'b10: begin
     rd_txn_state<= RD_ADDR_AVAIL;
     rd_alc_valid<= 1'b0;
   end 2'b11: begin
     rd_txn_state<= RD_DESC_ADDR_AVAIL;
     rd_alc_valid<= 1'b1;
   end
   endcase 
  end RD_DESC_AVAIL: begin
    if (rd_addr_alc_valid==1'b1) begin 
      rd_txn_state<= RD_DESC_ADDR_AVAIL;
      rd_alc_valid<= 1'b1;
    end else begin
      rd_txn_state<= rd_txn_state;
      rd_alc_valid<= 1'b0;
    end
  end RD_ADDR_AVAIL: begin
    if (rd_desc_alc_valid==1'b1) begin 
      rd_txn_state<= RD_DESC_ADDR_AVAIL;
      rd_alc_valid<= 1'b1;
    end else begin
      rd_txn_state<= rd_txn_state;
      rd_alc_valid<= 1'b0;
    end
  end RD_DESC_ADDR_AVAIL: begin
    rd_txn_state<= RD_IDLE;
    rd_alc_valid<= 1'b0;
  end default: begin
    rd_txn_state<= rd_txn_state;
    rd_alc_valid<= 1'b0;
  end
  endcase
end
end 

///////////////////////
//Signal :
//  wr_alc_valid
//  wr_alc_idx
//  wr_alc_offset
//  wr_alc_node_idx
//Description :
//  Generate wr_alc_valid When descriptor and offset both are available for a write request.
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    wr_alc_idx <= 'b0;
  end else if (wr_desc_alc_valid==1'b1) begin
    wr_alc_idx <= wr_desc_alc_idx;
  end
end

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    wr_alc_offset <= 'b0;
  end else if (wr_addr_alc_valid==1'b1) begin
    wr_alc_offset <= wr_addr_alc_offset;
  end
end

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    wr_alc_node_idx <= 'b0;
  end else if (wr_addr_alc_valid==1'b1) begin
    wr_alc_node_idx <= wr_addr_alc_node_idx;
  end
end

always @(posedge axi_aclk) begin
if (axi_aresetn == 1'b0) begin
  wr_txn_state <= WR_IDLE;
end else begin 
  case(wr_txn_state)
  WR_IDLE: begin
   case({wr_addr_alc_valid,wr_desc_alc_valid}) 
   2'b00: begin
     wr_txn_state<= WR_IDLE;
     wr_alc_valid<= 1'b0;
   end 2'b01: begin
     wr_txn_state<= WR_DESC_AVAIL;
     wr_alc_valid<= 1'b0;
   end 2'b10: begin
     wr_txn_state<= WR_ADDR_AVAIL;
     wr_alc_valid<= 1'b0;
   end 2'b11: begin
     wr_txn_state<= WR_DESC_ADDR_AVAIL;
     wr_alc_valid<= 1'b1;
   end
   endcase 
  end WR_DESC_AVAIL: begin
    if (wr_addr_alc_valid==1'b1) begin 
      wr_txn_state<= WR_DESC_ADDR_AVAIL;
      wr_alc_valid<= 1'b1;
    end else begin
      wr_txn_state<= wr_txn_state;
      wr_alc_valid<= 1'b0;
    end
  end WR_ADDR_AVAIL: begin
    if (wr_desc_alc_valid==1'b1) begin 
      wr_txn_state<= WR_DESC_ADDR_AVAIL;
      wr_alc_valid<= 1'b1;
    end else begin
      wr_txn_state<= wr_txn_state;
      wr_alc_valid<= 1'b0;
    end
  end WR_DESC_ADDR_AVAIL: begin
    wr_txn_state<= WR_IDLE;
    wr_alc_valid<= 1'b0;
  end default: begin
    wr_txn_state<= wr_txn_state;
    wr_alc_valid<= 1'b0;
  end
  endcase
end
end 

/************************Transaction Allocator End************************/

endmodule        

