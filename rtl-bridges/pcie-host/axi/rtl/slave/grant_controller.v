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
 *   Based on EDGE_TYP, detects positive/negative edge of each bit in vector din and gives grant
 *   to respective idx for 1-clock cycle (gnt_valid and gnt_idx).
 *
 *   Grant logic gives priority to lowest index first. 
 * 
 */

`include "defines_common.vh"

module grant_controller #(

         parameter MAX_DESC                                             = 16                   
        ,parameter EDGE_TYP                                             = 1                 //0 : negedge, 1 : posedge                   

)(

        //Clock and reset
         input 	     	                                                clk		
        ,input 	     	                                                rst_n		
        
        //Input data
        ,input  [MAX_DESC-1:0]                                          din		
        
        //Detection Signal
        ,output      [MAX_DESC-1:0]                                     det_out         //Optional output
        ,output      [MAX_DESC-1:0]                                     req_out         //Optional output
        ,output      [MAX_DESC-1:0]                                     gnt_out         //Optional output		
        ,output reg                                                     gnt_vld		
        ,output reg  [(`CLOG2(MAX_DESC))-1:0]                           gnt_idx 

);

//Arbiter Parameters
localparam GNT_0                                                        = 16'h0001; 
localparam GNT_1                                                        = 16'h0002; 
localparam GNT_2                                                        = 16'h0004; 
localparam GNT_3                                                        = 16'h0008; 
localparam GNT_4                                                        = 16'h0010; 
localparam GNT_5                                                        = 16'h0020; 
localparam GNT_6                                                        = 16'h0040; 
localparam GNT_7                                                        = 16'h0080; 
localparam GNT_8                                                        = 16'h0100; 
localparam GNT_9                                                        = 16'h0200; 
localparam GNT_A                                                        = 16'h0400; 
localparam GNT_B                                                        = 16'h0800; 
localparam GNT_C                                                        = 16'h1000; 
localparam GNT_D                                                        = 16'h2000; 
localparam GNT_E                                                        = 16'h4000; 
localparam GNT_F                                                        = 16'h8000; 

reg  [MAX_DESC-1:0]                                                     din_ff;
reg  [MAX_DESC-1:0]                                                     det_pos;        
reg  [MAX_DESC-1:0]                                                     req_pos;
reg  [MAX_DESC-1:0]                                                     det_neg;        
reg  [MAX_DESC-1:0]                                                     req_neg;

integer                                                                 k;

//Detection,Request,Grant Signal
wire [MAX_DESC-1:0]                                                     det;            
wire [MAX_DESC-1:0]                                                     req;
wire [MAX_DESC-1:0]                                                     gnt;              

//Arbiter Signals
wire [MAX_DESC-1:0]                                                     req_arb;        //Actual Input to Arbiter
wire [MAX_DESC-1:0]                                                     gnt_arb;        //Actual Output from Arbiter

assign det_out = det;		
assign req_out = req;		
assign gnt_out = gnt;		

//////////////////////
//Signal :
//  det_pos
//  det_neg
//Description :
//  det_pos/det_neg goes high at postive/negative edge of din. 
//  det_pos/det_neg is one clock-cycle pulse.
//////////////////////

always @(posedge clk) begin
  if (rst_n==0) begin
    din_ff <= {MAX_DESC{1'b0}};
  end else begin
    din_ff <= din;
  end
end        		

always @(posedge clk) begin
  if (rst_n==0) begin
    det_pos <= {MAX_DESC{1'b0}};
    det_neg <= {MAX_DESC{1'b0}};
  end else begin
    det_pos <= (din ^ din_ff) & din; 
    det_neg <= (din ^ din_ff) & ~din; 
  end
end        		

//////////////////////
//Signal :
//  req_pos
//  req_neg
//Description :
//  req_pos/req_neg goes high at postive/negative edge of din 
//  and goes low when grant is given. 
//////////////////////

generate 
genvar i;
for (i=0; i<=MAX_DESC-1; i=i+1) begin:gen_for 
  always @(posedge clk) begin
    if (rst_n==0) begin
      req_pos[i] <= 1'b0;
    end else if (req_pos[i]==1'b0) begin
      req_pos[i] <= (din[i] ^ din_ff[i]) & din[i]; 
    end else if (req_pos[i]==1'b1 && gnt[i]==1'b1) begin
      req_pos[i] <= 1'b0; 
    end else begin
      req_pos[i] <= req_pos[i];
    end
  end
  always @(posedge clk) begin
    if (rst_n==0) begin
      req_neg[i] <= 1'b0;
    end else if (req_neg[i]==1'b0) begin
      req_neg[i] <= (din[i] ^ din_ff[i]) & ~din[i]; 
    end else if (req_neg[i]==1'b1 && gnt[i]==1'b1) begin
      req_neg[i] <= 1'b0; 
    end else begin
      req_neg[i] <= req_neg[i];
    end
  end
end
endgenerate  		

//////////////////////
//Signal :
//  det
//  req
//Description :
//  Signal generation based on EDGE_TYP 
//////////////////////

generate 
if (EDGE_TYP==0) begin
  assign det = det_neg;
  assign req = req_neg;
end else begin
  assign det = det_pos;
  assign req = req_pos;
end
endgenerate  

//////////////////////
//Signal :
//  gnt_valid
//  gnt_idx
//Description :
//  Arbiter logic gives priority to lowest index first. 
//////////////////////

assign req_arb = req;           
assign gnt     = gnt_arb;       

assign gnt_arb = (req_arb)&(-req_arb);  //gnt_arb is one-hot vector

always @(posedge clk) begin
case(gnt_arb)
    GNT_0: begin         
    gnt_idx <= 'h0; 
    gnt_vld <= 1'b1;                                          
 end GNT_1: begin         
    gnt_idx <= 'h1; 
    gnt_vld <= 1'b1;                                         
 end GNT_2: begin         
    gnt_idx <= 'h2; 
    gnt_vld <= 1'b1;                                         
 end GNT_3: begin         
    gnt_idx <= 'h3; 
    gnt_vld <= 1'b1;                                         
 end GNT_4: begin         
    gnt_idx <= 'h4; 
    gnt_vld <= 1'b1;                                         
 end GNT_5: begin         
    gnt_idx <= 'h5; 
    gnt_vld <= 1'b1;                                         
 end GNT_6: begin         
    gnt_idx <= 'h6; 
    gnt_vld <= 1'b1;                                         
 end GNT_7: begin         
    gnt_idx <= 'h7; 
    gnt_vld <= 1'b1;                                         
 end GNT_8: begin         
    gnt_idx <= 'h8; 
    gnt_vld <= 1'b1;                                         
 end GNT_9: begin         
    gnt_idx <= 'h9; 
    gnt_vld <= 1'b1;                                         
 end GNT_A: begin         
    gnt_idx <= 'hA; 
    gnt_vld <= 1'b1;                                         
 end GNT_B: begin         
    gnt_idx <= 'hB; 
    gnt_vld <= 1'b1;                                         
 end GNT_C: begin         
    gnt_idx <= 'hC; 
    gnt_vld <= 1'b1;                                         
 end GNT_D: begin         
    gnt_idx <= 'hD; 
    gnt_vld <= 1'b1;                                         
 end GNT_E: begin         
    gnt_idx <= 'hE; 
    gnt_vld <= 1'b1;                                         
 end GNT_F: begin         
    gnt_idx <= 'hF; 
    gnt_vld <= 1'b1;                                         
 end default: begin       
    gnt_idx <= 'h0; 
    gnt_vld <= 1'b0;                                         
 end
endcase
end

endmodule
