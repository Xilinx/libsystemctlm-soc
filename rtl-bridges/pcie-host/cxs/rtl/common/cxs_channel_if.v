/*
 * Copyright (c) 2020 Xilinx Inc.
 * Written by Heramb Aligave.
 *            .
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
 *   cxs channel module for all tx/rx channel
 *
 */
module  cxs_channel_if
  #(
    parameter       CXS_DATA_FLIT_WIDTH         = 256,//256,512,1024 
    parameter       CXS_CNTL_WIDTH              = 14//14.36,44
    )
   (
    input 				clk,
    input 				resetn,
   
    input 				cxs_configure_bridge, 
    input 				cxs_go_to_lp_rx, 
    input 				cxs_credit_return_tx, 
    input [4:0] 			rx_refill_credits, 
   
    output 				CXS_ACTIVE_REQ_TX,
    input 				CXS_ACTIVE_ACK_TX,
    input 				CXS_DEACT_HINT_TX,
    input 				CXS_ACTIVE_REQ_RX,
    output 				CXS_ACTIVE_ACK_RX, 
    output 				CXS_DEACT_HINT_RX,
    

    // CXS Transmit Channel
    output reg [CXS_DATA_FLIT_WIDTH-1:0] CXS_DATA_TX,
    output reg [CXS_CNTL_WIDTH -1:0]     CXS_CNTL_TX,
    output reg                          CXS_VALID_TX,
    output reg				CXS_CRDRTN_TX,
    input 				CXS_CRDGNT_TX,
    output 				CXS_CRDRTN_CHK_TX,
    output [(CXS_DATA_FLIT_WIDTH/8)-1:0] CXS_DATA_CHK_TX,
    output                              CXS_CNTL_CHK_TX,
    output                              CXS_VALID_CHK_TX,
    input 				CXS_CRDGNT_CHK_TX,

    // CXS RECEIVE CHANNEL 
    input  [CXS_DATA_FLIT_WIDTH-1:0]    CXS_DATA_RX,
    input  [CXS_CNTL_WIDTH -1:0]        CXS_CNTL_RX,
    input 				CXS_VALID_RX,
    input 				CXS_CRDRTN_RX,
    output                              CXS_CRDGNT_RX,
    input 				CXS_CRDRTN_CHK_RX,
    input [(CXS_DATA_FLIT_WIDTH/8)-1:0] CXS_DATA_CHK_RX,
    input                               CXS_CNTL_CHK_RX,
    input                               CXS_VALID_CHK_RX,
    output 				CXS_CRDGNT_CHK_RX,

      

    input 				 CXS_TX_Valid,//Data Valid from TX Memory
    input [CXS_DATA_FLIT_WIDTH-1 :0] 	 CXS_TX_Data,//Data from TX Data Memory
    input [CXS_CNTL_WIDTH -1 :0]   	 CXS_TX_Cntl,//Data from TX CNTL Memory

    input 				 CXS_RX_Flit_received,
    output 				 CXS_TX_Flit_transmit,
    output [3:0] 			 rx_current_credits,
    output [3:0] 			 tx_current_credits,
    input 				 rx_ownership,
    input [14:0] 			 rx_ownership_flip_pulse,
    output reg 				 CXS_RX_Valid,
    output reg [CXS_DATA_FLIT_WIDTH -1 :0]   CXS_RX_Data,
    output reg [CXS_CNTL_WIDTH -1 :0]        CXS_RX_Cntl,
   
    output [1:0] 			Tx_Link_Status,
    output [1:0] 			Rx_Link_Status
   
    );

   localparam STOP         = 2'b00,
              ACTIVATING   = 2'b01, 
              DEACTIVATING = 2'b10,
              RUN          = 2'b11;

   
   reg 					     cxs_txactivereq_i;
   reg 					     cxs_txactiveack_i;
   reg 					     cxs_rxactivereq_i;
   reg 					     cxs_rxactiveack_i;
   reg                                       cxs_rx_credit_return; 

   wire 				     tx_incr_credits;
   wire [4:0] 				     tx_refill_credits; 
   wire 				     tx_dec_credits; 
   wire 				     tx_credits_available;
   wire 				     rx_incr_credits;
   wire 				     rx_dec_credits; 
   wire 				     rx_credits_available;
   wire 				     rx_credit_received; 
   
   wire 				     all_rx_credits_received;
   wire 				     all_tx_credits_sent;

   reg [1:0] 				     tx_link_status_i;
   reg [1:0] 				     rx_link_status_i;

   wire [3:0] 				     tx_current_credits_i;
   wire [3:0] 				     tx_rx_link_status;

   assign tx_current_credits = tx_current_credits_i;
   assign tx_rx_link_status = {tx_link_status_i,rx_link_status_i};

   assign all_rx_credits_received = rx_credit_received;
   assign all_tx_credits_sent     = (tx_current_credits_i == 0);

  reg cxs_rxdeacthint_i;
  reg cxs_txdeacthint_i;
  reg cxs_go_to_lp_rx_d;

   always @ (posedge clk ) 
     begin  
	if( ~resetn) 
	  cxs_go_to_lp_rx_d <= 1'b0;
	  else
           cxs_go_to_lp_rx_d <= cxs_go_to_lp_rx;
   end
  wire low_power_out =  cxs_go_to_lp_rx_d & ~cxs_go_to_lp_rx;
   //*************************************************************************************************/
   //Resetting the configure bridge will not have affect as that is not
   //Link Layer State Machine
   //*************************************************************************************************/
   always @ (posedge clk ) 
     begin  
	if( ~resetn) begin 
           cxs_txactivereq_i <= 1'b0;
           cxs_rxactiveack_i <= 1'b0;
           cxs_rxdeacthint_i <= 1'b0;
           cxs_txdeacthint_i <= 1'b0;
           tx_link_status_i        <= STOP;
           rx_link_status_i        <= STOP;
	end
	else begin
           // TxStop/RxStop
	   case(tx_rx_link_status)
	     4'b0000:begin
		cxs_txactivereq_i <= 1'b0;
                cxs_rxactiveack_i <= 1'b0;
		//State machine triggers at configure bridge and no low power
		if (cxs_configure_bridge & ~cxs_go_to_lp_rx) begin
                   // Remote Initiate
                   if (cxs_rxactivereq_i)
                     rx_link_status_i <= ACTIVATING;
                end
                // Local Initiate
		//State machine triggers at configure bridge and no Deactivate
		//hint
                if (cxs_configure_bridge & ~cxs_txdeacthint_i)begin
                   tx_link_status_i        <= ACTIVATING;
                   cxs_txactivereq_i <= 1'b1;
                end 
             end
             4'b0001: begin
                cxs_txactivereq_i <= 1'b0;
                cxs_rxactiveack_i <= 1'b0;
                // Local Initiate 
                if (cxs_configure_bridge & ~cxs_txdeacthint_i ) begin
                   tx_link_status_i        <= ACTIVATING;
                   cxs_txactivereq_i <= 1'b1;
                end 
             end
             4'b0100: begin
                cxs_txactivereq_i <= 1'b1;
                cxs_rxactiveack_i <= 1'b0;
                // Remote Initiate
                if (cxs_rxactivereq_i  & cxs_configure_bridge)
                  rx_link_status_i <= ACTIVATING;
             end
             4'b0101: begin
		cxs_txactivereq_i <= 1'b1;
                cxs_rxactiveack_i <= 1'b1;
                rx_link_status_i        <= RUN;
                if (cxs_txactiveack_i ) 
                  tx_link_status_i <= RUN;
             end
             4'b1101: begin
                cxs_txactivereq_i <= 1'b1;
                cxs_rxactiveack_i <= 1'b1;
                rx_link_status_i        <= RUN;
             end
	     4'b0111:begin
                cxs_txactivereq_i <= 1'b1;
                cxs_rxactiveack_i <= 1'b1;
                if (cxs_txactiveack_i )
                  tx_link_status_i <= RUN;
             end
             4'b1111 : begin
		cxs_txactivereq_i <= 1'b1;
                cxs_rxactiveack_i <= 1'b1;
                // Remote deactivation
                if (~cxs_rxactivereq_i  )
                  rx_link_status_i <= DEACTIVATING;
                // Local deactivation
		//State machine deactivates at txdeacthint signal 
                if ( cxs_txdeacthint_i |  cxs_go_to_lp_rx) begin
                   tx_link_status_i        <= DEACTIVATING;
                   cxs_txactivereq_i <= 1'b0;
                end 
             end
             4'b1110: begin
                cxs_txactivereq_i <= 1'b1;
                cxs_rxactiveack_i <= 1'b1;
                // Local deactivation
                if (cxs_txdeacthint_i |  cxs_go_to_lp_rx) begin
                   tx_link_status_i        <= DEACTIVATING;
                   cxs_txactivereq_i <= 1'b0;
                end 
             end
             4'b1011: begin
		cxs_rxactiveack_i <= 1'b1;
                cxs_txactivereq_i <= 1'b0;
                if (~cxs_rxactivereq_i  )
                  rx_link_status_i  <= DEACTIVATING;
             end
             4'b1010,4'b0010: begin
		cxs_txactivereq_i <= 0;
		if(~cxs_txactiveack_i)
		  tx_link_status_i <= STOP;
		//when all the credits are received by the initiator
                if (all_rx_credits_received) begin
                   cxs_rxactiveack_i <= 0;
                   rx_link_status_i <= STOP;
		end
             end
             4'b1000: begin
                cxs_txactivereq_i <= 0;
                cxs_rxactiveack_i <= 0;
                if (~cxs_txactiveack_i & all_tx_credits_sent)  
		  tx_link_status_i <= STOP;
             end
             default: begin end
	   endcase
           cxs_txactiveack_i <=  CXS_ACTIVE_ACK_TX;
           cxs_rxactivereq_i <=  CXS_ACTIVE_REQ_RX;
	   cxs_txdeacthint_i <=  CXS_DEACT_HINT_TX;
	   cxs_rxdeacthint_i <=  cxs_go_to_lp_rx;
	end 
     end 

   assign Tx_Link_Status        = tx_link_status_i;
   assign Rx_Link_Status        = rx_link_status_i;

   assign CXS_ACTIVE_REQ_TX =  cxs_txactivereq_i;
   assign CXS_ACTIVE_ACK_RX =  cxs_rxactiveack_i;
   assign CXS_DEACT_HINT_RX =  cxs_rxdeacthint_i;
   
  
   //**************************************************************************************************/
   //RX  Flit registering 
   //**************************************************************************************************/
    always @ (posedge clk ) 
     begin
      CXS_RX_Data     <=  CXS_DATA_RX;
     end
   always @ (posedge clk ) 
     begin  
        if(~resetn) begin 
           CXS_RX_Valid    <= 1'b0;
           CXS_RX_Cntl     <= 0;
           cxs_rx_credit_return     <= 0;
        end
	else begin
           CXS_RX_Valid    <=  CXS_VALID_RX;
           CXS_RX_Cntl     <=  CXS_CNTL_RX;
	   cxs_rx_credit_return   <= CXS_CRDRTN_RX;
	end 
     end 
   
   //**************************************************************************************************/
   //TX  Flit registering 
   //TXValid is asserted when normal function LINK is UP,and when LINK is
   //deactivating 
   //TXFLIT is 0 when Link is Deactivating
   //**************************************************************************************************/
   
    assign CXS_CRDRTN_CHK_TX = 0;//No Replication
    assign CXS_CRDGNT_CHK_RX = 0;//No Replication
    assign CXS_VALID_CHK_TX = 0;//No Replication
    assign CXS_DATA_CHK_TX = 0;//if CXS_DATACHECK=0,Else put Parity
    assign CXS_CNTL_CHK_TX = 0;//if CXS_DATACHECK=0,Else put Parity
    always @ (posedge clk ) 
     begin  
        if(~resetn) begin 
           CXS_DATA_TX    <= 0;
           CXS_CNTL_TX    <= 0;
           CXS_VALID_TX   <= 1'b0;
	   CXS_CRDRTN_TX  <= 1'b0;
	end
	else begin
           CXS_VALID_TX    <= CXS_TX_Valid & ~cxs_credit_return_tx; 
	   if  (tx_link_status_i == DEACTIVATING) begin
             CXS_DATA_TX <= 0;
             CXS_CNTL_TX <= 0;
	     end
	   else begin
             CXS_DATA_TX     <= CXS_TX_Data;
             CXS_CNTL_TX     <= CXS_TX_Cntl;
	     end
	    //either this returns credit or through CXSTXVALID and when all
	    //transmit done, note this
            CXS_CRDRTN_TX <=  (~CXS_TX_Valid & tx_current_credits_i !=0 & cxs_credit_return_tx) | cxs_txdeacthint_i ;
	end 
     end 
   
   
   //**************************************************************************************************/
   //Transmit Side Credit Manager 
   //Refill Credits initially during Link UP
   //Increments Credits when received from DUT
   //Decrement Credits when Flits transmitted or when Link is Deactivating
   //**************************************************************************************************/

   cxs_link_credit_manager u_CXS_TX_Credit
     (
      .clk(clk),
      .resetn(resetn),
      .incr_credits(tx_incr_credits),
      .refill_credits({1'b0,tx_refill_credits[3:0]}),
      .dec_credits(tx_dec_credits),
      .credits_available(tx_credits_available),
      .cur_credits(tx_current_credits_i),
      .credit_maxed()
      );

   assign CXS_TX_Flit_transmit  = tx_credits_available;
   assign tx_incr_credits     = CXS_CRDGNT_TX;
   assign tx_refill_credits[3:0]     = 4'b1111;
   //Decrement when normal flit transfer or when L-Credit Return
   assign tx_dec_credits      = CXS_TX_Valid | (tx_link_status_i == DEACTIVATING) | (cxs_credit_return_tx & ~CXS_TX_Valid);

   
   //**************************************************************************************************/
   //Receive  Side Credit Manager 
   //Refill Credits initially during Link UP to be sent to DUT
   //Increments Credits when Flip received
   //Decrement Credits when Software programs rx ownership Flip
   //**************************************************************************************************/
   cxs_link_credit_manager u_CXS_RX_Credit
     (
      .clk(clk),
      .resetn(resetn),
      .incr_credits(rx_incr_credits),
      .dec_credits(rx_dec_credits),
      .refill_credits(rx_refill_credits),
      .credits_available(rx_credits_available),
      .cur_credits(rx_current_credits),
      .credit_maxed(rx_credit_received)
      );

     
   reg [3:0] rx_dec_count;
   reg 	     rx_give_back_credit;
   wire [3:0] rx_flip_pulse_count;

   assign rx_flip_pulse_count = 
				   rx_ownership_flip_pulse[0]
				   + rx_ownership_flip_pulse[1]
				   + rx_ownership_flip_pulse[2]
				   + rx_ownership_flip_pulse[3]
				   + rx_ownership_flip_pulse[4]
				   + rx_ownership_flip_pulse[5]
				   + rx_ownership_flip_pulse[6]
				   + rx_ownership_flip_pulse[7]
				   + rx_ownership_flip_pulse[8]
				   + rx_ownership_flip_pulse[9]
				   + rx_ownership_flip_pulse[10]
				   + rx_ownership_flip_pulse[11]
				   + rx_ownership_flip_pulse[12]
				   + rx_ownership_flip_pulse[13]
				   + rx_ownership_flip_pulse[14];
   
   
   //**************************************************************************************************/
   // * To monitor flip regs pulse so that we can know
   // * how many credits we need to give back.
   // * i.e if user asserted 0x3 in flip_reg means we need to 
   // * give 2 credits back.
   // * If while we are decrementing count, user gives again a new flip
   // * then we will stop sending credits back and add new count and
   // * then again start giving it back!.
   //**************************************************************************************************/
   
   
   always@( posedge clk) begin
      if(~resetn) begin
	 rx_dec_count <= 0;
	 rx_give_back_credit <= 0;
      end
      else if(rx_refill_credits[4]) begin
	 rx_dec_count <= rx_refill_credits[3:0];
	 rx_give_back_credit <= 0;
      end
      else if(|rx_ownership_flip_pulse) begin
	 rx_dec_count <= rx_dec_count + rx_flip_pulse_count;
	 rx_give_back_credit <= 0;
      end
      else if(low_power_out) begin
	 rx_dec_count <= rx_current_credits; 
	 rx_give_back_credit <= 0;
      end
      else if((|rx_dec_count) && (rx_link_status_i == RUN)) begin
	 rx_dec_count <= rx_dec_count - 1;
	 rx_give_back_credit <= 1;
      end
      else begin
	 rx_dec_count <= rx_dec_count;
	 rx_give_back_credit <= 0;
      end
   end

   assign CXS_CRDGNT_RX     = rx_dec_credits;
   assign rx_incr_credits =  CXS_RX_Flit_received| cxs_rx_credit_return;
   assign rx_dec_credits  = rx_credits_available & rx_give_back_credit;
   
endmodule

