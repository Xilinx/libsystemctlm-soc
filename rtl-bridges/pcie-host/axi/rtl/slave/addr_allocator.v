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
 *   RDATA or WDATA/WSTRB RAM offset allocator and deallocator
 *
 *
 */

`include "defines_common.vh"

module addr_allocator #(

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

        //Channel Signals
        ,input                                                          txn_valid
        ,input  [7:0]                                                   txn_size          //AXLEN (Request is (AXLEN+1))
        ,output reg                                                     addr_alc_valid
        ,output reg [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0]             addr_alc_offset   //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [9:0]
        ,output reg [(`CLOG2(MAX_DESC))-1:0]                            addr_alc_node_idx //For MAX_DESC=16, it is [3:0]

        ,input                                                          alc_valid
        ,input  [(`CLOG2(MAX_DESC))-1:0]                                alc_desc_idx      //For MAX_DESC=16, it is [3:0]
        ,input  [(`CLOG2(MAX_DESC))-1:0]                                alc_node_idx      //For MAX_DESC=16, it is [3:0]
        
        ,input  [MAX_DESC-1:0]                                          txn_cmpl

);

//Module control parameters
localparam DESC_IDX_WIDTH                                               = `CLOG2(MAX_DESC);
localparam RAM_OFFSET_WIDTH                                             = `CLOG2((RAM_SIZE*8)/DATA_WIDTH);
localparam [31:0] RAM_MAX_LOCATION                                      = (RAM_SIZE*8)/DATA_WIDTH; //For RAM_SIZE=16384 and DATA_WIDTH=128, it is 1024

//Service control FSM state
localparam SER_IDLE                                                     = 2'b00;
localparam SER_ALC                                                      = 2'b01;
localparam SER_WAIT_DEALC                                               = 2'b10;
localparam SER_DEALC                                                    = 2'b11;

//Node Index
localparam NODE_0                                                       = 16'h0001; 
localparam NODE_1                                                       = 16'h0002; 
localparam NODE_2                                                       = 16'h0004; 
localparam NODE_3                                                       = 16'h0008; 
localparam NODE_4                                                       = 16'h0010; 
localparam NODE_5                                                       = 16'h0020; 
localparam NODE_6                                                       = 16'h0040; 
localparam NODE_7                                                       = 16'h0080; 
localparam NODE_8                                                       = 16'h0100; 
localparam NODE_9                                                       = 16'h0200; 
localparam NODE_A                                                       = 16'h0400; 
localparam NODE_B                                                       = 16'h0800; 
localparam NODE_C                                                       = 16'h1000; 
localparam NODE_D                                                       = 16'h2000; 
localparam NODE_E                                                       = 16'h4000; 
localparam NODE_F                                                       = 16'h8000; 

//Allocation FSM state
localparam ALC_IDLE                                                     = 4'h0;
localparam ALC_NEW_LL                                                   = 4'h1;
localparam ALC_UD_LL                                                    = 4'h2;
localparam ALC_CAL_DIFF_OFFSET                                          = 4'h3;
localparam ALC_CAL_SPACE_NODE                                           = 4'h4;
localparam ALC_CHECK_AVAIL                                              = 4'h5;
localparam ALC_FAILED                                                   = 4'h6;
localparam ALC_CAL_IDX                                                  = 4'h7;
localparam ALC_ADD_NODE                                                 = 4'h8;

//Deallocation FSM state
localparam DEALC_IDLE                                                   = 3'b000;
localparam DEALC_CAL_SUB_VEC                                            = 3'b001;
localparam DEALC_CAL_SUBCNT                                             = 3'b010;
localparam DEALC_CAL_LL_IDX                                             = 3'b011;
localparam DEALC_CAL_NEXT_VEC                                           = 3'b100;
localparam DEALC_UPDATE_LL                                              = 3'b101;

//Loop iteration signal
integer                                                                 i;
integer                                                                 j;

//Service control signal
reg                                                                     ser_valid;      // service valid
reg                                                                     ser_dealc_alc;  // 0:service allocation, 1:service deallocation
reg  [1:0]                                                              ser_state;


//Allocation Signal
reg                                                                     txn_valid_ff;

reg                                                                     addr_txn_valid;
wire [7:0]                                                              addr_txn_size;

reg                                                                     addr_txn_valid_ff;

reg                                                                     pre_addr_alc_valid;

reg                                                                     addr_alc_failed; //Allocation failed due to lack of space/nodes
reg                                                                     pre_addr_alc_failed;

reg                                                                     alc_valid_ff;

reg  [3:0]                                                              alc_state;
reg  [RAM_OFFSET_WIDTH:0]                                               diff_offset[MAX_DESC-1:0]; 
reg  [RAM_OFFSET_WIDTH:0]                                               diff_offset_curr_next_nowrap[MAX_DESC-1:0]; 
reg  [RAM_OFFSET_WIDTH:0]                                               diff_offset_curr_next_wrap[MAX_DESC-1:0]; 
reg  [RAM_OFFSET_WIDTH:0]                                               diff_offset_last_head_nowrap[MAX_DESC-1:0]; 
reg  [RAM_OFFSET_WIDTH:0]                                               diff_offset_last_head_wrap[MAX_DESC-1:0]; 
reg  [MAX_DESC-1:0]                                                     is_wrap_around; 
reg  [MAX_DESC-1:0]                                                     space_avail;//space_avail[*]=1, means sufficient space available after *-node for requested size
reg  [MAX_DESC-1:0]                                                     pos_node_vec; //One hot Vector //Only one Node can say that there is space after me //POS : Possible
reg  [DESC_IDX_WIDTH-1:0]                                               pos_node_idx; 
reg                                                                     pos_node_vld;
reg  [MAX_DESC-1:0]                                                     node_avail;   //free nodes
reg  [MAX_DESC-1:0]                                                     new_node_vec; //One hot Vector //new_node_vec[*]=1, means new node index=*  
reg  [DESC_IDX_WIDTH-1:0]                                               new_node_idx;
reg                                                                     new_node_vld;

//Deallocation Signal
wire [MAX_DESC-1:0]                                                     freeup_valid;     
reg  [MAX_DESC-1:0]                                                     freeup_valid_ff;     

wire                                                                    addr_freeup_valid;      
reg                                                                     addr_freeup_valid_ff;   
reg  [MAX_DESC-1:0]                                                     addr_freeup_desc_vec; 
reg  [MAX_DESC-1:0]                                                     addr_freeup_desc_vec_save; 

reg  [MAX_DESC-1:0]                                                     addr_dealc_valid;  
reg  [MAX_DESC-1:0]                                                     pre_addr_dealc_valid;  

wire [MAX_DESC-1:0]                                                     dealc_service_vld;  
reg  [MAX_DESC-1:0]                                                     dealc_service_vld_ff;  

reg  [2:0]                                                              dealc_state;
reg  [MAX_DESC-1:0]                                                     addr_freeup_logical_vec; 
reg  [MAX_DESC-1:0]                                                     dealc_sub_vec[MAX_DESC-1:0];
reg  [DESC_IDX_WIDTH-1:0]                                               dealc_subcnt[MAX_DESC-1:0];
reg  [MAX_DESC-1:0]                                                     dealc_head_vec;
reg  [MAX_DESC-1:0]                                                     dealc_next_vec[MAX_DESC-1:0];

//Linked-list Control signals
reg  [DESC_IDX_WIDTH-1:0]                                               head_ptr;      //Points to start of LL
reg                                                                     head_ptr_vld;  //Indication weather LL exists or not

//Linked-list node (max number of nodes = MAX_DESC)
reg  [MAX_DESC-1:0]                                                     node_vld; 
reg  [RAM_OFFSET_WIDTH-1:0]                                             data_strt_offset[MAX_DESC-1:0]; 
reg  [RAM_OFFSET_WIDTH-1:0]                                             data_end_offset[MAX_DESC-1:0]; 
reg  [DESC_IDX_WIDTH-1:0]                                               data_ll_idx[MAX_DESC-1:0];        
reg  [DESC_IDX_WIDTH-1:0]                                               data_desc_idx[MAX_DESC-1:0];        
reg  [MAX_DESC-1:0]                                                     data_desc_idx_vld;        
reg  [DESC_IDX_WIDTH-1:0]                                               next[MAX_DESC-1:0];             
reg  [MAX_DESC-1:0]                                                     next_vld;             //if next_vld[*]=1'b0, means next[*]=NULL

//////////////////////
//Signal:
//  data_desc_idx
//Description :
//  Assign descriptor index to the node when there is alc_valid(offset and
//  descriptor both are available).
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    alc_valid_ff <= 'h0;
  end else begin
    alc_valid_ff <= alc_valid;
  end
end        		

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_data_desc_idx
      data_desc_idx[i] <= 'h0;
    end
  //when descriptor and offset are available
  end else if (alc_valid==1'b1 && alc_valid_ff==1'b0) begin
    data_desc_idx[alc_node_idx] <= alc_desc_idx;
  end
end        		

//////////////////////
//Signal:
//  data_desc_idx_vld
//Description :
//  Validate data_desc_idx of the node when there is alc_valid(offset and
//  descriptor both are available).
//  Invalidate data_desc_idx while freeing up the node. (Deallocation)
//////////////////////
     		
always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    dealc_service_vld_ff <= 'h0;
  end else begin
    dealc_service_vld_ff <= dealc_service_vld;
  end
end
assign dealc_service_vld = (ser_valid==1'b1 && ser_dealc_alc==1'b1);        		

generate
genvar gi;
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_data_desc_idx_vld
  always @(posedge axi_aclk) begin
    if (axi_aresetn==0) begin
      data_desc_idx_vld[gi] <= 1'b0;
    end else if (addr_freeup_desc_vec[data_desc_idx[gi]]==1'b1 && dealc_service_vld==1'b1 && dealc_service_vld_ff==1'b0) begin //Positive edge detection
      data_desc_idx_vld[gi] <= 1'b0;
    end else if (gi==alc_node_idx && alc_valid==1'b1 && alc_valid_ff==1'b0) begin //Positive edge detection
      data_desc_idx_vld[gi] <= 1'b1;
    end
  end        		
end
endgenerate

//////////////////////
//Allocation request 
//Signal:
//  addr_txn_valid
//  addr_txn_size
//Description :
//  Actual address allocation request with size.
//  addr_txn_valid goes high when new request comes and goes low when
//  allocation is done successfully.
//////////////////////

assign addr_txn_size = txn_size;

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    txn_valid_ff <= 'h0;
  end else begin
    txn_valid_ff <= txn_valid;
  end
end        		

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    addr_txn_valid <= 1'b0;  
  end else if (pre_addr_alc_valid==1'b1) begin
    addr_txn_valid <= 1'b0;
  end else if (txn_valid==1'b1 && txn_valid_ff==1'b0) begin //Positive edge detection
    addr_txn_valid <= 1'b1;
  end
end

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    addr_txn_valid_ff <= 'h0;
  end else begin
    addr_txn_valid_ff <= addr_txn_valid_ff;
  end
end        		


//////////////////////
//Deallocation request 
//Signal:
//  addr_freeup_valid
//  addr_freeup_desc_vec
//Description :
//  Actual deallocation request with descriptor index vector.
//
//  addr_freeup_valid goes high on transaction completition and goes low when
//  deallocation is done successfully.
//
//  Deallocator logic frees up offsets(memory) of all descriptors for which it 
//  sees freeup-requests at the begining of deallocation.
//
//  If there are any new deallocation/freeup-requests while current deallocation 
//  is in progress, they cannot be served but rather be stored in 
//  addr_freeup_desc_vec_save. These requests are served in next deallocation operation.
//////////////////////

assign freeup_valid = txn_cmpl;

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    freeup_valid_ff <= 'h0;
  end else begin
    freeup_valid_ff <= freeup_valid;
  end
end        		

generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_addr_freeup_desc_vec_save
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      addr_freeup_desc_vec_save[gi] <= 1'b0;  
    end else if (pre_addr_dealc_valid[gi]==1'b1) begin
      addr_freeup_desc_vec_save[gi] <= 1'b0;
    end else if (freeup_valid[gi]==1'b1 && freeup_valid_ff[gi]==1'b0) begin //Positive edge detection      
      addr_freeup_desc_vec_save[gi] <= 1'b1;
    end
  end
end
endgenerate

generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_addr_freeup_desc_vec
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      addr_freeup_desc_vec[gi] <= 1'b0;  
    end else if (pre_addr_dealc_valid[gi]==1'b1) begin
      addr_freeup_desc_vec[gi] <= 1'b0;
    end else if (ser_valid==1'b1 && ser_dealc_alc==1'b1) begin      
      addr_freeup_desc_vec[gi] <= addr_freeup_desc_vec[gi];
    end else begin     
      addr_freeup_desc_vec[gi] <= addr_freeup_desc_vec_save[gi];
    end
  end
end
endgenerate

assign addr_freeup_valid = |addr_freeup_desc_vec; 

//////////////////////
//Signal :
//  ser_dealc_alc 
//Description:
//  Serve deallocation or allocation request
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    ser_state         <= SER_IDLE;
    ser_valid <= 1'b0;  
    ser_dealc_alc <= 1'b0;  
  end else begin
    case(ser_state)
    SER_IDLE: begin
      //Give priority to allocation
      if (addr_txn_valid==1'b1) begin
        ser_valid       <= 1'b1;
        ser_dealc_alc   <= 1'b0;
        ser_state       <= SER_ALC;
      end else if (addr_freeup_valid==1'b1) begin
        ser_valid       <= 1'b1;
        ser_dealc_alc   <= 1'b1;
        ser_state       <= SER_DEALC;
      end else begin
        ser_valid       <= 1'b0;
        ser_dealc_alc   <= 1'b0;
        ser_state       <= SER_IDLE;
      end  
    end SER_ALC: begin
      //If allocation is done, serve deallocation request,if any
      if (pre_addr_alc_valid==1'b1) begin
        if (addr_freeup_valid==1'b1) begin 
          ser_valid <= 1'b1;
          ser_dealc_alc <= 1'b1;
          ser_state         <= SER_DEALC;
        end else begin
          ser_valid <= 1'b0;
          ser_dealc_alc <= 1'b0;
          ser_state         <= SER_IDLE;
        end
      //If allocation is failed due to lack of nodes or space in RAM,
      //deallocation is must 
      end else if (pre_addr_alc_failed==1'b1) begin
        if (addr_freeup_valid==1'b1) begin 
          ser_valid     <= 1'b1;
          ser_dealc_alc <= 1'b1;
          ser_state     <= SER_DEALC;
        end else begin
          ser_valid     <= 1'b0;
          ser_dealc_alc <= 1'b0;
          ser_state     <= SER_WAIT_DEALC;
        end
      //Allocation is in progress  
      end else begin
        ser_valid   <= 1'b1;
        ser_dealc_alc   <= 1'b0;
        ser_state           <= ser_state;
      end 
    end SER_WAIT_DEALC: begin
      //Must wait till deallocation request appears
      if (addr_freeup_valid==1'b1) begin 
        ser_valid <= 1'b1;
        ser_dealc_alc <= 1'b1;
        ser_state         <= SER_DEALC;
      end else begin
        ser_valid <= 1'b0;
        ser_dealc_alc <= 1'b0;
        ser_state         <= ser_state;
      end
    
    end SER_DEALC: begin
      //If deallocation is done, serve allocation/deallocation request,if any. (Give priority to allocation)
      if (|pre_addr_dealc_valid==1'b1) begin
        if(addr_txn_valid==1'b1) begin
          ser_valid <= 1'b1;
          ser_dealc_alc <= 1'b0;
          ser_state         <= SER_ALC;
        end else begin
          ser_valid <= 1'b0;
          ser_dealc_alc <= 1'b0;
          ser_state         <= SER_IDLE;
        end  
      //If deallocation is in progress
      end else begin
        ser_valid   <= 1'b1;
        ser_dealc_alc   <= 1'b1;
        ser_state           <= ser_state;
      end  
    end default: begin
      ser_valid   <= ser_valid;
      ser_dealc_alc   <= ser_dealc_alc;
      ser_state           <= ser_state;
    end
    endcase
  end
end  

//////////////////////
//Signal :
//  addr_alc_valid
//  addr_alc_failed
//  addr_dealc_valid
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    addr_alc_valid   <= 1'b0;
    addr_alc_failed  <= 1'b0;              
  end else begin
    addr_alc_valid   <= pre_addr_alc_valid;
    addr_alc_failed  <= pre_addr_alc_failed;              
  end
end

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    addr_dealc_valid <= 'b0;
  end else begin
    addr_dealc_valid <= pre_addr_dealc_valid;
  end
end

//////////////////////
//Signal:
//
//  Allocation 
//    pre_addr_alc_valid (one clock cycle pulse) indicating allocation will
//    complete in next cycle.
//
//    pre_addr_alc_failed (One clock cycle pulse) indicating allocation will 
//    fail in next cycle.      
//
//    addr_alc_offset
// 
// addr_alc_node_idx
// 
// Deallocation
//
//    pre_addr_dealc_valid
//
//Description: 
//
//Upon allocation/deallocation request, update linked-list.
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    //LL signals on reset
    head_ptr            <= 'b0;
    head_ptr_vld        <= 1'b0;  
    for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_node_vld_reset
      node_vld[i]            <= 1'b0;
      data_strt_offset[i]    <= 'b0;
      data_end_offset[i]     <= 'b0;
      data_ll_idx[i]         <= 'b0;
      next[i]                <= 'b0;
      next_vld[i]            <= 1'b0;
    end  
    //Allocation control signals on reset
    alc_state            <= ALC_IDLE;
    pre_addr_alc_valid   <= 1'b0;
    pre_addr_alc_failed  <= 1'b0;              
    is_wrap_around       <= 'b0;          
    space_avail          <= 'b0;       
    pos_node_vec         <= 'b0;        
    pos_node_idx         <= 'b0;        
    pos_node_vld         <= 'b0;        
    node_avail           <= 'b0;      
    new_node_vec         <= 'b0;        
    new_node_idx         <= 'b0;        
    new_node_vld         <= 'b0;        
    for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_diff_offset_reset
      diff_offset[i]                   <= 'b0;  
      diff_offset_curr_next_nowrap[i]  <= 'b0;                   
      diff_offset_curr_next_wrap[i]    <= 'b0;                 
      diff_offset_last_head_nowrap[i]  <= 'b0;                   
      diff_offset_last_head_wrap[i]    <= 'b0;                 
    end
    //Deallocation control signals on reset
    dealc_state                 <= DEALC_IDLE;
    pre_addr_dealc_valid        <= 'b0;
    dealc_head_vec              <= 'b0;
    addr_freeup_logical_vec     <= 'b0;
    for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_dealc_subcnt_reset
      dealc_sub_vec[i]     <= 'b0;
      dealc_subcnt[i]      <= 'b0;
      dealc_next_vec[i]    <= 'b0;
    end
  end else if (ser_valid==1'b1 && ser_dealc_alc==1'b0) begin           //Service ALLOCATION
    case(alc_state)

    ALC_IDLE: begin
      //linked-list is not present
      if (head_ptr_vld==1'b0) begin     
        alc_state          <= ALC_NEW_LL;
        pre_addr_alc_valid <= 1'b1;
        pre_addr_alc_failed     <= 1'b0; 
      //linked-list is present             
      end else begin                    
        alc_state          <= ALC_UD_LL;
        pre_addr_alc_valid <= 1'b0;
        pre_addr_alc_failed     <= 1'b0;              
      end

    end ALC_NEW_LL: begin
      alc_state          <= ALC_IDLE;
      pre_addr_alc_valid <= 1'b0;
      pre_addr_alc_failed     <= 1'b0;              
      addr_alc_offset           <= 'b0;
      addr_alc_node_idx         <= 'b0;
      //Update Head Pointer
      head_ptr_vld              <= 1'b1; 
      head_ptr                  <= 'b0; 
      //Prepare a new node        
      node_vld[0]               <= 1'b1;         
      data_strt_offset[0]       <= 'b0;               
      data_end_offset[0]        <= { {(RAM_OFFSET_WIDTH-8){1'b0}}, addr_txn_size };
      data_ll_idx[0]            <= 'b0;              
      next[0]                   <= 'b0;    
      next_vld[0]               <= 1'b0;        //NULL

    end ALC_UD_LL: begin
      alc_state          <= ALC_CAL_DIFF_OFFSET;
      pre_addr_alc_valid <= 1'b0;
      pre_addr_alc_failed     <= 1'b0;              
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_is_wrap_around
        if (node_vld[i]==1'b1) begin
          //Check if wrap-around of RAM is present between current and next node
          if (next_vld[i]==1'b1) begin
            if (data_strt_offset[next[i]]>data_end_offset[i]) begin
              is_wrap_around[i] <= 1'b0;
            end else begin 
              is_wrap_around[i] <= 1'b1; //wrap-around of RAM
            end
          //Check if wrap-around of RAM is present between last node and head node
          end else begin
            if (data_strt_offset[head_ptr]>data_end_offset[i]) begin
              is_wrap_around[i] <= 1'b0;
            end else begin 
              is_wrap_around[i] <= 1'b1; //wrap-around of RAM
            end
          end 
        end else begin
          is_wrap_around[i] <= 1'b0;
        end  
      end
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_diff_offset_curr_next_nowrap
        diff_offset_curr_next_nowrap[i]   <= (data_strt_offset[next[i]]-data_end_offset[i]-1'h1);        
        diff_offset_curr_next_wrap[i]     <= (RAM_MAX_LOCATION[RAM_OFFSET_WIDTH-1:0]-1-data_end_offset[i]+data_strt_offset[next[i]]);   
        diff_offset_last_head_nowrap[i]   <= (data_strt_offset[head_ptr]-data_end_offset[i]-1'h1);    
        diff_offset_last_head_wrap[i]     <= (RAM_MAX_LOCATION[RAM_OFFSET_WIDTH-1:0]-1-data_end_offset[i]+data_strt_offset[head_ptr]);   
      end

    end ALC_CAL_DIFF_OFFSET: begin
      alc_state          <= ALC_CAL_SPACE_NODE;
      pre_addr_alc_valid <= 1'b0;
      pre_addr_alc_failed     <= 1'b0;              
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_diff_offset
        if (node_vld[i]==1'b1) begin
          //Calculate space between current and next node
          if (next_vld[i]==1'b1) begin
            if (is_wrap_around[i]==1'b0) begin
              diff_offset[i] <= diff_offset_curr_next_nowrap[i];
            end else begin 
              diff_offset[i] <= diff_offset_curr_next_wrap[i]; //wrap-around of RAM
            end
          //Calculate space between last node and head node
          end else begin
            if (is_wrap_around[i]==1'b0) begin
              diff_offset[i] <= diff_offset_last_head_nowrap[i];
            end else begin 
              diff_offset[i] <= diff_offset_last_head_wrap[i]; //wrap-around of RAM
            end
          end 
        end else begin
          diff_offset[i] <= 'b0;
        end  
      end
    
    end ALC_CAL_SPACE_NODE: begin
      alc_state          <= ALC_CHECK_AVAIL;
      pre_addr_alc_valid <= 1'b0;
      pre_addr_alc_failed     <= 1'b0;              
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_space_offset
        space_avail[i] <= ( (diff_offset[i] >= (addr_txn_size+1)) ? 1'b1 : 1'b0 );
      end
      node_avail <= ~node_vld;  //Available free nodes
    
    end ALC_CHECK_AVAIL: begin
      //If one of the node is free and space is available, add a new node 
      if ( (|node_avail == 1'b1) && (|space_avail == 1'b1) ) begin  
        alc_state          <= ALC_CAL_IDX;
        pre_addr_alc_valid <= 1'b0;
        pre_addr_alc_failed     <= 1'b0;   
      //Else, allocation failed           
      end else begin                 
        alc_state          <= ALC_FAILED;
        pre_addr_alc_valid <= 1'b0;
        pre_addr_alc_failed     <= 1'b1;              
      end
      //Calculate node vectors
      pos_node_vec <= (space_avail)&(-space_avail);  //Only one Node can say that there is space after me
      new_node_vec <= (node_avail)&(-node_avail);    //One hot Vector
    
    end ALC_FAILED: begin
      alc_state          <= ALC_IDLE;
      pre_addr_alc_valid <= 1'b0;
      pre_addr_alc_failed     <= 1'b0;              
    
    end ALC_CAL_IDX: begin
      alc_state          <= ALC_ADD_NODE;
      pre_addr_alc_valid <= 1'b1;
      pre_addr_alc_failed     <= 1'b0;              
      //Calculate index from one-hot vecor 
      case(pos_node_vec)
        NODE_0: begin         
           pos_node_idx <= 'h0; 
           pos_node_vld <= 1'b1;                                          
        end NODE_1: begin         
           pos_node_idx <= 'h1; 
           pos_node_vld <= 1'b1;                                         
        end NODE_2: begin         
           pos_node_idx <= 'h2; 
           pos_node_vld <= 1'b1;                                         
        end NODE_3: begin         
           pos_node_idx <= 'h3; 
           pos_node_vld <= 1'b1;                                         
        end NODE_4: begin         
           pos_node_idx <= 'h4; 
           pos_node_vld <= 1'b1;                                         
        end NODE_5: begin         
           pos_node_idx <= 'h5; 
           pos_node_vld <= 1'b1;                                         
        end NODE_6: begin         
           pos_node_idx <= 'h6; 
           pos_node_vld <= 1'b1;                                         
        end NODE_7: begin         
           pos_node_idx <= 'h7; 
           pos_node_vld <= 1'b1;                                         
        end NODE_8: begin         
           pos_node_idx <= 'h8; 
           pos_node_vld <= 1'b1;                                         
        end NODE_9: begin         
           pos_node_idx <= 'h9; 
           pos_node_vld <= 1'b1;                                         
        end NODE_A: begin         
           pos_node_idx <= 'hA; 
           pos_node_vld <= 1'b1;                                         
        end NODE_B: begin         
           pos_node_idx <= 'hB; 
           pos_node_vld <= 1'b1;                                         
        end NODE_C: begin         
           pos_node_idx <= 'hC; 
           pos_node_vld <= 1'b1;                                         
        end NODE_D: begin         
           pos_node_idx <= 'hD; 
           pos_node_vld <= 1'b1;                                         
        end NODE_E: begin         
           pos_node_idx <= 'hE; 
           pos_node_vld <= 1'b1;                                         
        end NODE_F: begin         
           pos_node_idx <= 'hF; 
           pos_node_vld <= 1'b1;                                         
        end default: begin       
           pos_node_idx <= 'h0; 
           pos_node_vld <= 1'b0;                                         
        end
      endcase
      //Calculate index from one-hot vecor 
      case(new_node_vec)
        NODE_0: begin         
           new_node_idx <= 'h0; 
           new_node_vld <= 1'b1;                                          
        end NODE_1: begin         
           new_node_idx <= 'h1; 
           new_node_vld <= 1'b1;                                         
        end NODE_2: begin         
           new_node_idx <= 'h2; 
           new_node_vld <= 1'b1;                                         
        end NODE_3: begin         
           new_node_idx <= 'h3; 
           new_node_vld <= 1'b1;                                         
        end NODE_4: begin         
           new_node_idx <= 'h4; 
           new_node_vld <= 1'b1;                                         
        end NODE_5: begin         
           new_node_idx <= 'h5; 
           new_node_vld <= 1'b1;                                         
        end NODE_6: begin         
           new_node_idx <= 'h6; 
           new_node_vld <= 1'b1;                                         
        end NODE_7: begin         
           new_node_idx <= 'h7; 
           new_node_vld <= 1'b1;                                         
        end NODE_8: begin         
           new_node_idx <= 'h8; 
           new_node_vld <= 1'b1;                                         
        end NODE_9: begin         
           new_node_idx <= 'h9; 
           new_node_vld <= 1'b1;                                         
        end NODE_A: begin         
           new_node_idx <= 'hA; 
           new_node_vld <= 1'b1;                                         
        end NODE_B: begin         
           new_node_idx <= 'hB; 
           new_node_vld <= 1'b1;                                         
        end NODE_C: begin         
           new_node_idx <= 'hC; 
           new_node_vld <= 1'b1;                                         
        end NODE_D: begin         
           new_node_idx <= 'hD; 
           new_node_vld <= 1'b1;                                         
        end NODE_E: begin         
           new_node_idx <= 'hE; 
           new_node_vld <= 1'b1;                                         
        end NODE_F: begin         
           new_node_idx <= 'hF; 
           new_node_vld <= 1'b1;                                         
        end default: begin       
           new_node_idx <= 'h0; 
           new_node_vld <= 1'b0;                                         
        end
      endcase
    
    end ALC_ADD_NODE: begin
      alc_state          <= ALC_IDLE;
      pre_addr_alc_valid <= 1'b0;
      pre_addr_alc_failed     <= 1'b0;              
      addr_alc_offset                        <= data_end_offset[pos_node_idx]+1;
      addr_alc_node_idx                      <= new_node_idx;
      if (next_vld[pos_node_idx]==1'b0) begin //Add node at the end of LL
        //Add node at last
        next[new_node_idx]                   <= 'b0;   
        next_vld[new_node_idx]               <= 1'b0;    //NULL
        //Update LL
        next[pos_node_idx]                   <= new_node_idx;  
        next_vld[pos_node_idx]               <= 1'b1;    
      end else begin  //Add node in middle of LL
        //Add node in middle
        next[new_node_idx]                   <= next[pos_node_idx];    
        next_vld[new_node_idx]               <= 1'b1;    
        //Update LL
        next[pos_node_idx]                   <= new_node_idx;  
        //next_vld[pos_node_idx]             <= 1'b1;    
      end  
      //Update LL-indices
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_data_ll_idx_alc
        if ( (data_ll_idx[i]>data_ll_idx[pos_node_idx]) && (node_vld[i]==1'b1) ) begin
          data_ll_idx[i] <= data_ll_idx[i]+1;
        end
      end  
      //Prepare a new node        
      node_vld[new_node_idx]               <= 1'b1;         
      data_strt_offset[new_node_idx]       <= data_end_offset[pos_node_idx]+1;               
      data_end_offset[new_node_idx]        <= data_end_offset[pos_node_idx]+1+addr_txn_size;              
      data_ll_idx[new_node_idx]            <= data_ll_idx[pos_node_idx]+1;              
      
    end default: begin
      alc_state                 <= alc_state;
      pre_addr_alc_valid        <= 1'b0;
      pre_addr_alc_failed       <= 1'b0;              
    end
    endcase


  end else if (ser_valid==1'b1 && ser_dealc_alc==1'b1) begin           //Service DEALLOCATION  
    case(dealc_state)

    DEALC_IDLE: begin
      dealc_state          <= DEALC_CAL_SUB_VEC;
      pre_addr_dealc_valid <= 'b0;
      //Invalidate the nodes which needs to be removed.
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_addr_freeup_logical_vec
        addr_freeup_logical_vec[i] <= (node_vld[i]==1'b1 && data_desc_idx_vld[i]==1'b1 && addr_freeup_desc_vec[data_desc_idx[i]]==1'b1) ? 1'b1 : 1'b0;
        node_vld[i]                <= (node_vld[i]==1'b1 && data_desc_idx_vld[i]==1'b1 && addr_freeup_desc_vec[data_desc_idx[i]]==1'b1) ? 1'b0 : node_vld[i];
      end
      
    end DEALC_CAL_SUB_VEC: begin
      dealc_state          <= DEALC_CAL_SUBCNT;
      pre_addr_dealc_valid <= 'b0;
      //Calculate subtraction vector for each node
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_dealc_sub_vec_i
        if (node_vld[i]==1'b1) begin
          for (j=0; j<=MAX_DESC-1; j=j+1) begin: for_dealc_sub_vec_j_A
            if (addr_freeup_logical_vec[j]==1'b1) begin
              dealc_sub_vec[i][j] <= (data_ll_idx[j] < data_ll_idx[i]) ? 1'b1 : 1'b0;
            end else begin
              dealc_sub_vec[i][j] <= 1'b0;
            end
          end
        end else begin
          for (j=0; j<=MAX_DESC-1; j=j+1) begin: for_dealc_sub_vec_j_B
            dealc_sub_vec[i][j] <= 1'b0;
          end
        end
      end
        
    end DEALC_CAL_SUBCNT: begin
      dealc_state          <= DEALC_CAL_LL_IDX;
      pre_addr_dealc_valid <= 'b0;
      //Calculate subtraction count for each node
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_dealc_subcnt
        if (node_vld[i]==1'b1) begin
            dealc_subcnt[i] <= ((({ {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][ 0] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][ 1] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][ 2] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][ 3] }) 
                               + ({ {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][ 4] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][ 5] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][ 6] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][ 7] }))
                              + (({ {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][ 8] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][ 9] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][10] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][11] }) 
                               + ({ {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][12] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][13] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][14] } + { {(DESC_IDX_WIDTH-1){1'b0}}, dealc_sub_vec[i][15] })));
        end else begin
            dealc_subcnt[i] <= 'b0;
        end
      end

    end DEALC_CAL_LL_IDX: begin
      dealc_state          <= DEALC_CAL_NEXT_VEC;
      pre_addr_dealc_valid <= 'b0;
      //Calculate ll-idx as per new Linked-list 
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_data_ll_idx_dealc
        if (node_vld[i]==1'b1) begin
            data_ll_idx[i]  <= data_ll_idx[i]-dealc_subcnt[i]; 
        end else begin
            data_ll_idx[i]  <= 'b0; 
        end
      end
    
    end DEALC_CAL_NEXT_VEC: begin
      dealc_state          <= DEALC_UPDATE_LL;
      pre_addr_dealc_valid <= addr_freeup_desc_vec;
      //Calculate head vector for LL
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_dealc_head_vec_i
        if (data_ll_idx[i]=='b0 && node_vld[i]==1'b1) begin
          dealc_head_vec[i] <= 1'b1;
        end else begin
          dealc_head_vec[i] <= 1'b0;
        end
      end    
      //Calculate next vector for each node
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_dealc_next_vec_i
        if (node_vld[i]==1'b1) begin
          for (j=0; j<=MAX_DESC-1; j=j+1) begin: for_dealc_next_vec_j_A
            if ( (data_ll_idx[i]<=MAX_DESC-2) && ((data_ll_idx[i]+1)==data_ll_idx[j]) && (node_vld[j]==1'b1) ) begin
              dealc_next_vec[i][j] <= 1'b1;
            end else begin
              dealc_next_vec[i][j] <= 1'b0;
            end
          end
        end else begin
          for (j=0; j<=MAX_DESC-1; j=j+1) begin: for_dealc_next_vec_j_B
            dealc_next_vec[i][j] <= 1'b0;
          end
        end
      end

    end DEALC_UPDATE_LL: begin
      dealc_state          <= DEALC_IDLE;
      pre_addr_dealc_valid <= 'b0;
      //Update Head Pointer
      //Calculate index from one-hot vecor 
      case(dealc_head_vec)
        NODE_0: begin         
           head_ptr <= 'h0; 
           head_ptr_vld <= 1'b1;                                          
        end NODE_1: begin         
           head_ptr <= 'h1; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_2: begin         
           head_ptr <= 'h2; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_3: begin         
           head_ptr <= 'h3; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_4: begin         
           head_ptr <= 'h4; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_5: begin         
           head_ptr <= 'h5; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_6: begin         
           head_ptr <= 'h6; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_7: begin         
           head_ptr <= 'h7; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_8: begin         
           head_ptr <= 'h8; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_9: begin         
           head_ptr <= 'h9; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_A: begin         
           head_ptr <= 'hA; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_B: begin         
           head_ptr <= 'hB; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_C: begin         
           head_ptr <= 'hC; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_D: begin         
           head_ptr <= 'hD; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_E: begin         
           head_ptr <= 'hE; 
           head_ptr_vld <= 1'b1;                                         
        end NODE_F: begin         
           head_ptr <= 'hF; 
           head_ptr_vld <= 1'b1;                                         
        end default: begin       
           head_ptr <= 'h0; 
           head_ptr_vld <= 1'b0;                                         
        end
      endcase
      //Update LL
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_next_next_vld_i
        if (node_vld[i]==1'b1) begin
          //Calculate index from one-hot vecor 
          case(dealc_next_vec[i])
            NODE_0: begin         
               next[i] <= 'h0; 
               next_vld[i] <= 1'b1;                                          
            end NODE_1: begin         
               next[i] <= 'h1; 
               next_vld[i] <= 1'b1;                                         
            end NODE_2: begin         
               next[i] <= 'h2; 
               next_vld[i] <= 1'b1;                                         
            end NODE_3: begin         
               next[i] <= 'h3; 
               next_vld[i] <= 1'b1;                                         
            end NODE_4: begin         
               next[i] <= 'h4; 
               next_vld[i] <= 1'b1;                                         
            end NODE_5: begin         
               next[i] <= 'h5; 
               next_vld[i] <= 1'b1;                                         
            end NODE_6: begin         
               next[i] <= 'h6; 
               next_vld[i] <= 1'b1;                                         
            end NODE_7: begin         
               next[i] <= 'h7; 
               next_vld[i] <= 1'b1;                                         
            end NODE_8: begin         
               next[i] <= 'h8; 
               next_vld[i] <= 1'b1;                                         
            end NODE_9: begin         
               next[i] <= 'h9; 
               next_vld[i] <= 1'b1;                                         
            end NODE_A: begin         
               next[i] <= 'hA; 
               next_vld[i] <= 1'b1;                                         
            end NODE_B: begin         
               next[i] <= 'hB; 
               next_vld[i] <= 1'b1;                                         
            end NODE_C: begin         
               next[i] <= 'hC; 
               next_vld[i] <= 1'b1;                                         
            end NODE_D: begin         
               next[i] <= 'hD; 
               next_vld[i] <= 1'b1;                                         
            end NODE_E: begin         
               next[i] <= 'hE; 
               next_vld[i] <= 1'b1;                                         
            end NODE_F: begin         
               next[i] <= 'hF; 
               next_vld[i] <= 1'b1;                                         
            end default: begin       
               next[i] <= 'h0; 
               next_vld[i] <= 1'b0;                                         
            end
          endcase
        end else begin
          next[i]      <= 'b0;
          next_vld[i] <= 1'b0;
        end  
      end  
    
    end default: begin
      dealc_state          <= dealc_state;
      pre_addr_dealc_valid <= 'b0;
    end
    endcase
     

  end else begin   //If there is no service of allocation/deallocation  
      //Allocation control signals
      alc_state          <= ALC_IDLE;
      pre_addr_alc_valid <= 1'b0;
      pre_addr_alc_failed     <= 1'b0;              
      //Deallocation control signals
      dealc_state          <= DEALC_IDLE;
      pre_addr_dealc_valid <= 'b0;
  end
end  




endmodule


