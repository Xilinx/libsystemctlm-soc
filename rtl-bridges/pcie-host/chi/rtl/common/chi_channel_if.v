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
 *   chi channel module for all tx/rx channel
 *
 */
module  chi_channel_if
  #(
    parameter BRIDGE_MODE                 = "HN_F", //Allowed values : HN_F, RN_F
    parameter CHI_CHN_REQ_WIDTH           = 121,  //Allowed values : AXI4, AXI4LITE, AXI3
    parameter CHI_CHN_RSP_WIDTH           = 51,  //Allowed values : 7 to 11
    parameter CHI_CHN_DAT_WIDTH           = 705,  //Allowed values : 45 to 52
    parameter CHI_CHN_SNP_WIDTH           = 88,  //Allowed values : 16.32,64 
    parameter CHI_CHN_REQ_SNP_WIDTH       = ((BRIDGE_MODE == "HN_F") ? CHI_CHN_REQ_WIDTH : CHI_CHN_SNP_WIDTH),
    parameter CHI_CHN_SNP_REQ_WIDTH       = ((BRIDGE_MODE == "HN_F") ? CHI_CHN_SNP_WIDTH : CHI_CHN_REQ_WIDTH) 
    )
   (
    input 				     clk,
    input 				     resetn,
   
    input 				     configure_bridge, 
    input 				     go_to_lp, 
    input 				     flits_in_progress, 
    input [4:0] 			     rxreq_rxsnp_refill_credits, 
    input [4:0] 			     rxrsp_refill_credits, 
    input [4:0] 			     rxdat_refill_credits, 
   
    input 				     chi_syscoreq_hn,
    output 				     chi_syscoack_hn, 
    input 				     chi_syscoack_rn,
    output 				     chi_syscoreq_rn, 
    output 				     syscoreq_i,
    output 				     syscoack_i,
    input 				     syscoreq_o,
    input 				     syscoack_o,
   
    input 				     CHI_RXSACTIVE,
    output reg 				     CHI_TXSACTIVE,

    output 				     CHI_TXLINKACTIVEREQ,
    input 				     CHI_TXLINKACTIVEACK,
    input 				     CHI_RXLINKACTIVEREQ,
    output 				     CHI_RXLINKACTIVEACK,

    input 				     CHI_TXRSPLCRDV,
    output reg 				     CHI_TXRSPFLITPEND,
    output reg 				     CHI_TXRSPFLITV,
    output reg [CHI_CHN_RSP_WIDTH-1:0] 	     CHI_TXRSPFLIT,

    input 				     CHI_TXDATLCRDV,
    output reg 				     CHI_TXDATFLITPEND,
    output reg 				     CHI_TXDATFLITV,
    output reg [CHI_CHN_DAT_WIDTH - 1 : 0]   CHI_TXDATFLIT,

    input 				     CHI_TXSNP_TXREQ_LCRDV,
    output reg 				     CHI_TXSNP_TXREQ_FLITPEND,
    output reg 				     CHI_TXSNP_TXREQ_FLITV,
    output reg [CHI_CHN_SNP_REQ_WIDTH-1:0]   CHI_TXSNP_TXREQ_FLIT,

    output 				     CHI_RXREQ_RXSNP_LCRDV,
    input 				     CHI_RXREQ_RXSNP_FLITPEND,
    input 				     CHI_RXREQ_RXSNP_FLITV,
    input [CHI_CHN_REQ_SNP_WIDTH - 1 : 0]    CHI_RXREQ_RXSNP_FLIT,

    output 				     CHI_RXRSPLCRDV,
    input 				     CHI_RXRSPFLITPEND,
    input 				     CHI_RXRSPFLITV,
    input [CHI_CHN_RSP_WIDTH - 1 : 0] 	     CHI_RXRSPFLIT,

    output 				     CHI_RXDATLCRDV,
    input 				     CHI_RXDATFLITPEND,
    input 				     CHI_RXDATFLITV,
    input [CHI_CHN_DAT_WIDTH - 1 : 0] 	     CHI_RXDATFLIT,

    input 				     CHI_TXRSP_Pending,
    input 				     CHI_TXRSP_Valid,//Data Valid from TXRSP Memory
    input [CHI_CHN_RSP_WIDTH -1 :0] 	     CHI_TXRSP_Data,//Data from TXRSP Memory
    input 				     CHI_TXDAT_Pending,
    input 				     CHI_TXDAT_Valid, //Data Valid from TXDAT Memory
    input [CHI_CHN_DAT_WIDTH -1 :0] 	     CHI_TXDAT_Data, //Data from TXDAT Memory  
    input 				     CHI_TXSNP_TXREQ_Pending,
    input 				     CHI_TXSNP_TXREQ_Valid, 
    input [CHI_CHN_SNP_REQ_WIDTH -1 :0]      CHI_TXSNP_TXREQ_Data,//Data from TXSNP_TXREQ_ Memory

    input 				     CHI_RXREQ_RXSNP_Received,
    input 				     CHI_RXRSP_Received,
    input 				     CHI_RXDAT_Received,
    output 				     CHI_TXSNP_TXREQ_flit_transmit,
    output 				     CHI_TXRSP_flit_transmit,
    output 				     CHI_TXDAT_flit_transmit,
    output [3:0] 			     rxdat_current_credits,
    output [3:0] 			     rxreq_rxsnp_current_credits,
    output [3:0] 			     rxrsp_current_credits,
    output [3:0] 			     txdat_current_credits,
    output [3:0] 			     txsnp_txreq_current_credits,
    output [3:0] 			     txrsp_current_credits,
    input 				     rxreq_rxsnp_ownership,
    input 				     rxrsp_ownership,
    input 				     rxdat_ownership,
    input [14:0] 			     rxreq_rxsnp_ownership_flip_pulse,
    input [14:0] 			     rxrsp_ownership_flip_pulse,
    input [14:0] 			     rxdat_ownership_flip_pulse,
    output reg 				     CHI_RXREQ_RXSNP_Pending,
    output reg 				     CHI_RXREQ_RXSNP_Valid,
    output reg [CHI_CHN_REQ_SNP_WIDTH -1 :0] CHI_RXREQ_RXSNP_Data,
    output reg 				     CHI_RXRSP_Pending,
    output reg 				     CHI_RXRSP_Valid,
    output reg [CHI_CHN_RSP_WIDTH -1 :0]     CHI_RXRSP_Data,
    output reg 				     CHI_RXDAT_Pending,
    output reg 				     CHI_RXDAT_Valid,
    output reg [CHI_CHN_DAT_WIDTH -1 :0]     CHI_RXDAT_Data,
   
    output [1:0] 			     Tx_Link_Status,
    output [1:0] 			     Rx_Link_Status
   
    );

   localparam STOP         = 2'b00,
     ACTIVATING   = 2'b01, 
     DEACTIVATING = 2'b10,
     RUN          = 2'b11;

   wire 				     init_done;
   

   reg 					     CHI_TXSACTIVE_i;
   
   reg 					     m_chi_txlinkactivereq_i;
   reg 					     m_chi_txlinkactiveack_i;
   reg 					     m_chi_rxlinkactivereq_i;
   reg 					     m_chi_rxlinkactiveack_i;

   wire 				     txsnp_txreq_incr_credits;
   wire [4:0] 				     txsnp_txreq_refill_credits; 
   wire 				     txsnp_txreq_dec_credits; 
   wire 				     txsnp_txreq_credits_available;
   wire 				     txrsp_incr_credits; 
   wire [4:0] 				     txrsp_refill_credits;  
   wire 				     txrsp_dec_credits;  
   wire 				     txrsp_credits_available; 
   wire 				     txdat_incr_credits; 
   wire [4:0] 				     txdat_refill_credits;
   wire 				     txdat_dec_credits;
   wire 				     txdat_credits_available;
   wire 				     rxreq_rxsnp_incr_credits;
   wire 				     rxreq_rxsnp_dec_credits; 
   wire 				     rxreq_rxsnp_credits_available;
   reg 					     rxreq_rxsnp_credits_available_ff;
   wire 				     rxreq_rxsnp_credit_received; 
   wire 				     rxrsp_incr_credits;
   wire 				     rxrsp_dec_credits;
   wire 				     rxrsp_credits_available;
   reg 					     rxrsp_credits_available_ff;
   wire 				     rxrsp_credit_received;
   wire 				     rxdat_incr_credits; 
   wire 				     rxdat_dec_credits; 
   wire 				     rxdat_credits_available;
   reg 					     rxdat_credits_available_ff;
   wire 				     rxdat_credit_received;
   
   wire 				     all_rx_credits_received;
   wire 				     all_tx_credits_sent;

   reg [1:0] 				     tx_link_status_i;
   reg [1:0] 				     rx_link_status_i;

   wire [3:0] 				     txdat_current_credits_i;
   wire [3:0] 				     txsnp_txreq_current_credits_i;
   wire [3:0] 				     txrsp_current_credits_i;
   wire [3:0] 				     tx_rx_link_status;

   assign txdat_current_credits = txdat_current_credits_i;
   assign txsnp_txreq_current_credits = txsnp_txreq_current_credits_i;
   assign txrsp_current_credits = txrsp_current_credits_i;
   assign tx_rx_link_status = {tx_link_status_i,rx_link_status_i};

   assign all_rx_credits_received = rxdat_credit_received & rxrsp_credit_received & rxreq_rxsnp_credit_received;
   assign all_tx_credits_sent     = (txrsp_current_credits_i == 0) & (txsnp_txreq_current_credits_i == 0) & (txdat_current_credits_i == 0);


   //*************************************************************************************************/
   //Resetting the configure bridge will not have affect as that is not
   //Link Layer State Machine
   //*************************************************************************************************/
   always @ (posedge clk ) 
     begin  
	if( ~resetn) begin 
           m_chi_txlinkactivereq_i <= 1'b0;
           m_chi_rxlinkactiveack_i <= 1'b0;
           tx_link_status_i        <= STOP;
           rx_link_status_i        <= STOP;
	end
	else begin
           // TxStop/RxStop
	   case(tx_rx_link_status)
	     4'b0000:begin
		m_chi_txlinkactivereq_i <= 1'b0;
                m_chi_rxlinkactiveack_i <= 1'b0;
		if (configure_bridge & ~go_to_lp) begin
                   // Remote Initiate
                   if (m_chi_rxlinkactivereq_i)
                     rx_link_status_i <= ACTIVATING;
                end
                // Local Initiate
                if (configure_bridge & ~go_to_lp)begin
                   tx_link_status_i        <= ACTIVATING;
                   m_chi_txlinkactivereq_i <= 1'b1;
                end 
             end
             4'b0001: begin
                m_chi_txlinkactivereq_i <= 1'b0;
                m_chi_rxlinkactiveack_i <= 1'b0;
                // Local Initiate 
                if (configure_bridge & ~go_to_lp ) begin
                   tx_link_status_i        <= ACTIVATING;
                   m_chi_txlinkactivereq_i <= 1'b1;
                end 
             end
             4'b0100: begin
                m_chi_txlinkactivereq_i <= 1'b1;
                m_chi_rxlinkactiveack_i <= 1'b0;
                // Remote Initiate
                if (m_chi_rxlinkactivereq_i  & configure_bridge)
                  rx_link_status_i <= ACTIVATING;
             end
             4'b0101: begin
		m_chi_txlinkactivereq_i <= 1'b1;
                m_chi_rxlinkactiveack_i <= 1'b1;
                rx_link_status_i        <= RUN;
                if (m_chi_txlinkactiveack_i ) 
                  tx_link_status_i <= RUN;
             end
             4'b1101: begin
                m_chi_txlinkactivereq_i <= 1'b1;
                m_chi_rxlinkactiveack_i <= 1'b1;
                rx_link_status_i        <= RUN;
             end
	     4'b0111:begin
                m_chi_txlinkactivereq_i <= 1'b1;
                m_chi_rxlinkactiveack_i <= 1'b1;
                if (m_chi_txlinkactiveack_i )
                  tx_link_status_i <= RUN;
             end
             4'b1111 : begin
		m_chi_txlinkactivereq_i <= 1'b1;
                m_chi_rxlinkactiveack_i <= 1'b1;
                // Remote deactivation
                if (~m_chi_rxlinkactivereq_i )
                  rx_link_status_i <= DEACTIVATING;
                // Local deactivation
                if (configure_bridge  & go_to_lp) begin
                   tx_link_status_i        <= DEACTIVATING;
                   m_chi_txlinkactivereq_i <= 1'b0;
                end 
             end
             4'b1110: begin
                m_chi_txlinkactivereq_i <= 1'b1;
                m_chi_rxlinkactiveack_i <= 1'b1;
                // Local deactivation
                if (configure_bridge & go_to_lp ) begin
                   tx_link_status_i        <= DEACTIVATING;
                   m_chi_txlinkactivereq_i <= 1'b0;
                end 
             end
             4'b1011: begin
		m_chi_rxlinkactiveack_i <= 1'b1;
                m_chi_txlinkactivereq_i <= 1'b0;
                if (~m_chi_rxlinkactivereq_i  )
                  rx_link_status_i  <= DEACTIVATING;
             end
             4'b1010,4'b0010: begin
		m_chi_txlinkactivereq_i <= 0;
                m_chi_rxlinkactiveack_i <= 0;
		if(~m_chi_txlinkactiveack_i)
		  tx_link_status_i <= STOP;
		//when all the credits are received by the initiator
                if (all_rx_credits_received) begin
                   // m_chi_rxlinkactiveack_i <= 0;
                   rx_link_status_i <= STOP;
		end
             end
             4'b1000: begin
                m_chi_txlinkactivereq_i <= 0;
                m_chi_rxlinkactiveack_i <= 0;
                //if (~m_chi_txlinkactiveack_i )  
                if (~m_chi_txlinkactiveack_i & all_tx_credits_sent)  
		  tx_link_status_i <= STOP;
             end
             default: begin end
	   endcase
           m_chi_txlinkactiveack_i <= CHI_TXLINKACTIVEACK;
           m_chi_rxlinkactivereq_i <= CHI_RXLINKACTIVEREQ;
	end 
     end 

   assign Tx_Link_Status        = tx_link_status_i;
   assign Rx_Link_Status        = rx_link_status_i;

   assign CHI_TXLINKACTIVEREQ = m_chi_txlinkactivereq_i;
   assign CHI_RXLINKACTIVEACK = m_chi_rxlinkactiveack_i;
   
   //**************************************************************************************************/
   ///TXSACTIVE allowed to be 1 always
   //**************************************************************************************************/
   
   always @ (posedge clk ) 
     begin  
	if( ~resetn) 
          CHI_TXSACTIVE  <= 1'b0;
	else begin
           CHI_TXSACTIVE <= flits_in_progress |  (tx_link_status_i == DEACTIVATING & txrsp_current_credits_i !=0);
	end 
     end 

   reg syscoreq_int;
   reg syscoack_int;
   reg m_chi_syscoack_q;
   reg m_chi_syscoreq_q;

   
   //**************************************************************************************************/
   ///Syscoreq/syscoack assignment frm registers based on Bridge Mode 
   //**************************************************************************************************/
   always @ (posedge clk ) 
     begin  
        if(~resetn) begin 
           syscoreq_int   <= 0;
           m_chi_syscoack_q   <= 0;
           m_chi_syscoreq_q   <= 0;
           syscoack_int   <= 0;
        end
        else begin
           syscoreq_int <= chi_syscoreq_hn ;
           syscoack_int <= ( BRIDGE_MODE == "HN_F" ) ? syscoack_o : 1'b0; ;
           m_chi_syscoack_q   <=   chi_syscoack_rn;
           m_chi_syscoreq_q   <=  ( BRIDGE_MODE == "HN_F" ) ? 1'b0 : syscoreq_o;
        end 
     end 

   assign chi_syscoack_hn   =  syscoack_int;
   assign syscoreq_i        = ( BRIDGE_MODE == "HN_F" ) ? syscoreq_int : 1'b0;
   assign syscoack_i        = ( BRIDGE_MODE == "RN_F" ) ? m_chi_syscoack_q : 1'b0;
   assign chi_syscoreq_rn   = m_chi_syscoreq_q;
   


   //**************************************************************************************************/
   //RX REQ Flit registering 
   //**************************************************************************************************/
   always @ (posedge clk ) 
     begin  
        if(~resetn) begin 
           CHI_RXREQ_RXSNP_Pending  <= 1'b0;
           CHI_RXREQ_RXSNP_Valid    <= 1'b0;
           CHI_RXREQ_RXSNP_Data     <= 0;
        end
	else begin
           CHI_RXREQ_RXSNP_Pending  <= CHI_RXREQ_RXSNP_FLITPEND;
           CHI_RXREQ_RXSNP_Valid    <= CHI_RXREQ_RXSNP_FLITV;
           CHI_RXREQ_RXSNP_Data     <= CHI_RXREQ_RXSNP_FLIT;
	end 
     end 
   
   //**************************************************************************************************/
   //RX RSP Flit registering 
   //**************************************************************************************************/
   always @ (posedge clk ) 
     begin  
        if(~resetn) begin 
           CHI_RXRSP_Pending <= 1'b0;
           CHI_RXRSP_Valid   <= 1'b0;
           CHI_RXRSP_Data    <=CHI_RXRSPFLIT;
	end
	else begin
           CHI_RXRSP_Pending <= CHI_RXRSPFLITPEND;
           CHI_RXRSP_Valid   <= CHI_RXRSPFLITV;
           CHI_RXRSP_Data    <= CHI_RXRSPFLIT;
	end 
     end 
   
   
   //**************************************************************************************************/
   //RX DAT Flit registering 
   //**************************************************************************************************/
   always @ (posedge clk ) 
     begin  
        if(~resetn) begin 
           CHI_RXDAT_Pending <= 1'b0;
           CHI_RXDAT_Valid <= 1'b0;
           CHI_RXDAT_Data    <= CHI_RXDATFLIT;
	end
	else begin
           CHI_RXDAT_Pending <= CHI_RXDATFLITPEND;
           CHI_RXDAT_Valid <= CHI_RXDATFLITV;
           CHI_RXDAT_Data    <= CHI_RXDATFLIT;
	end 
     end

   //**************************************************************************************************/
   //TX RSP Flit registering 
   //TXPending,TXValid is asserted when normal function LINK is UP,and when LINK is
   //deactivating 
   //TXFLIT is 0 when Link is Deactivating
   //**************************************************************************************************/
   
   always @ (posedge clk ) 
     begin  
        if(~resetn) begin 
           CHI_TXRSPFLITPEND <= 1'b0;
           CHI_TXRSPFLITV    <= 1'b0;
           CHI_TXRSPFLIT     <= 0;
	end
	else begin
           CHI_TXRSPFLITPEND <= CHI_TXRSP_Pending | (tx_link_status_i == DEACTIVATING & txrsp_current_credits_i !=0);
           CHI_TXRSPFLITV    <= CHI_TXRSP_Valid | (tx_link_status_i == DEACTIVATING & txrsp_current_credits_i !=0);
	   if  (tx_link_status_i == DEACTIVATING) //Txn ID =0, Opcode = 0
             CHI_TXRSPFLIT <= 0;
	   else
             CHI_TXRSPFLIT     <= CHI_TXRSP_Data;
	end 
     end 
   
   
   always @ (posedge clk ) 
     begin  
        if(~resetn) begin 
           CHI_TXDATFLITPEND <= 1'b0;
           CHI_TXDATFLITV    <= 1'b0;
           CHI_TXDATFLIT     <= 0;
        end
	else begin
           CHI_TXDATFLITPEND <= CHI_TXDAT_Pending | (tx_link_status_i == DEACTIVATING & txdat_current_credits_i !=0);
           CHI_TXDATFLITV    <= CHI_TXDAT_Valid | (tx_link_status_i == DEACTIVATING & txdat_current_credits_i !=0);
	   if(tx_link_status_i == DEACTIVATING) //Txn ID =0, Opcode = 0
             CHI_TXDATFLIT     <= 0;
	   else
             CHI_TXDATFLIT     <= CHI_TXDAT_Data;
	end 
     end 

   
   always @ (posedge clk ) 
     begin  
        if(~resetn) begin 
           CHI_TXSNP_TXREQ_FLITPEND <= 1'b0;
           CHI_TXSNP_TXREQ_FLITV   <= 1'b0;
           CHI_TXSNP_TXREQ_FLIT    <= 0;
	end
	else begin
           CHI_TXSNP_TXREQ_FLITPEND <= CHI_TXSNP_TXREQ_Pending | (tx_link_status_i == DEACTIVATING & txsnp_txreq_current_credits_i !=0);
           CHI_TXSNP_TXREQ_FLITV    <= CHI_TXSNP_TXREQ_Valid | (tx_link_status_i == DEACTIVATING & txsnp_txreq_current_credits_i !=0);
	   if (tx_link_status_i == DEACTIVATING ) //Txn ID =0, Opcode = 0
             CHI_TXSNP_TXREQ_FLIT     <= 0;
           else
             CHI_TXSNP_TXREQ_FLIT     <= CHI_TXSNP_TXREQ_Data;
	end 
     end 
   

   
   
   //**************************************************************************************************/
   //Transmit Side Credit Manager 
   //Refill Credits initially during Link UP
   //Increments Credits when received from DUT
   //Decrement Credits when Flits transmitted or when Link is Deactivating
   //**************************************************************************************************/

   chi_link_credit_manager u_CHI_TXSNP_TXREQ_Credit
     (
      .clk(clk),
      .resetn(resetn),
      .incr_credits(txsnp_txreq_incr_credits),
      .refill_credits({1'b0,txsnp_txreq_refill_credits[3:0]}),
      .dec_credits(txsnp_txreq_dec_credits),
      .credits_available(txsnp_txreq_credits_available),
      .cur_credits(txsnp_txreq_current_credits_i),
      .credit_maxed()
      );

   assign CHI_TXSNP_TXREQ_flit_transmit  = txsnp_txreq_credits_available;
   assign txsnp_txreq_incr_credits     = CHI_TXSNP_TXREQ_LCRDV;
   assign txsnp_txreq_refill_credits[3:0]     = 4'b1111;
   //Decrement when normal flit transfer or when L-Credit Return
   assign txsnp_txreq_dec_credits      = CHI_TXSNP_TXREQ_Valid | (tx_link_status_i == DEACTIVATING);

   chi_link_credit_manager u_CHI_TXRSP_Credit
     (
      .clk(clk),
      .resetn(resetn),
      .incr_credits(txrsp_incr_credits),
      .refill_credits({1'b0,txrsp_refill_credits[3:0]}),
      .dec_credits(txrsp_dec_credits),
      .credits_available(txrsp_credits_available),
      .cur_credits(txrsp_current_credits_i),
      .credit_maxed()
      );

   assign CHI_TXRSP_flit_transmit  = txrsp_credits_available;

   assign txrsp_incr_credits     = CHI_TXRSPLCRDV;
   assign txrsp_refill_credits[3:0]     = 4'b1111;
   //Decrement when normal flit transfer or when L-Credit Return
   assign txrsp_dec_credits      = CHI_TXRSP_Valid | (tx_link_status_i == DEACTIVATING);

   chi_link_credit_manager u_CHI_TXDAT_Credit
     (
      .clk(clk),
      .resetn(resetn),
      .incr_credits(txdat_incr_credits),
      .refill_credits({1'b0,txdat_refill_credits[3:0]}),
      .dec_credits(txdat_dec_credits),
      .credits_available(txdat_credits_available),
      .cur_credits(txdat_current_credits_i),
      .credit_maxed()
      );


   assign CHI_TXDAT_flit_transmit  = txdat_credits_available;
   assign txdat_incr_credits     = CHI_TXDATLCRDV; 
   assign txdat_refill_credits[3:0]     = 4'b1111;
   //Decrement when normal flit transfer or when L-Credit Return
   assign txdat_dec_credits      = CHI_TXDAT_Valid | (tx_link_status_i == DEACTIVATING); 
   
   //**************************************************************************************************/
   //Receive  Side Credit Manager 
   //Refill Credits initially during Link UP to be sent to DUT
   //Increments Credits when Flip received
   //Decrement Credits when Software programs rx ownership Flip
   //**************************************************************************************************/
   chi_link_credit_manager u_CHI_RXDAT_Credit
     (
      .clk(clk),
      .resetn(resetn),
      .incr_credits(rxdat_incr_credits),
      .dec_credits(rxdat_dec_credits),
      .refill_credits(rxdat_refill_credits),
      .credits_available(rxdat_credits_available),
      .cur_credits(rxdat_current_credits),
      .credit_maxed(rxdat_credit_received)
      );

   always@ (posedge clk)
     begin
	if(~resetn) begin
	   rxdat_credits_available_ff <= 0;
	end
	else begin
	   rxdat_credits_available_ff <= rxdat_credits_available;
	end
     end
   
   reg [3:0] rxdat_dec_count;
   reg 	     rxdat_give_back_credit;
   wire [3:0] rxdat_flip_pulse_count;

   assign rxdat_flip_pulse_count = 
				   rxdat_ownership_flip_pulse[0]
				   + rxdat_ownership_flip_pulse[1]
				   + rxdat_ownership_flip_pulse[2]
				   + rxdat_ownership_flip_pulse[3]
				   + rxdat_ownership_flip_pulse[4]
				   + rxdat_ownership_flip_pulse[5]
				   + rxdat_ownership_flip_pulse[6]
				   + rxdat_ownership_flip_pulse[7]
				   + rxdat_ownership_flip_pulse[8]
				   + rxdat_ownership_flip_pulse[9]
				   + rxdat_ownership_flip_pulse[10]
				   + rxdat_ownership_flip_pulse[11]
				   + rxdat_ownership_flip_pulse[12]
				   + rxdat_ownership_flip_pulse[13]
				   + rxdat_ownership_flip_pulse[14];
   
   
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
	 rxdat_dec_count <= 0;
	 rxdat_give_back_credit <= 0;
      end
      else if(rxdat_refill_credits[4]) begin
	 rxdat_dec_count <= rxdat_refill_credits[3:0];
	 rxdat_give_back_credit <= 0;
      end
      else if(|rxdat_ownership_flip_pulse) begin
	 rxdat_dec_count <= rxdat_dec_count + rxdat_flip_pulse_count;
	 rxdat_give_back_credit <= 0;
      end
      else if((|rxdat_dec_count) && (rx_link_status_i == RUN)) begin
	 rxdat_dec_count <= rxdat_dec_count - 1;
	 rxdat_give_back_credit <= 1;
      end
      else begin
	 rxdat_dec_count <= rxdat_dec_count;
	 rxdat_give_back_credit <= 0;
      end
   end

   assign CHI_RXDATLCRDV     = rxdat_dec_credits;
   assign rxdat_incr_credits = CHI_RXDAT_Received;
   assign rxdat_dec_credits  = rxdat_credits_available & rxdat_give_back_credit;
   
   chi_link_credit_manager u_CHI_RXREQ_RXSNP_Credit
     (
      .clk(clk),
      .resetn(resetn),
      .incr_credits(rxreq_rxsnp_incr_credits),
      .dec_credits(rxreq_rxsnp_dec_credits),
      .refill_credits(rxreq_rxsnp_refill_credits),
      .credits_available(rxreq_rxsnp_credits_available),
      .cur_credits(rxreq_rxsnp_current_credits),
      .credit_maxed(rxreq_rxsnp_credit_received)
      );

   
   always@ (posedge clk)
     begin
	if(~resetn) begin
	   rxreq_rxsnp_credits_available_ff <= 0;
	end
	else begin
	   rxreq_rxsnp_credits_available_ff <= rxreq_rxsnp_credits_available;
	end
     end

   reg [3:0] rxreq_rxsnp_dec_count;
   reg 	     rxreq_rxsnp_give_back_credit;
   wire [3:0] rxreq_rxsnp_flip_pulse_count;

   assign rxreq_rxsnp_flip_pulse_count = 
					 rxreq_rxsnp_ownership_flip_pulse[0]
					 + rxreq_rxsnp_ownership_flip_pulse[1]
					 + rxreq_rxsnp_ownership_flip_pulse[2]
					 + rxreq_rxsnp_ownership_flip_pulse[3]
					 + rxreq_rxsnp_ownership_flip_pulse[4]
					 + rxreq_rxsnp_ownership_flip_pulse[5]
					 + rxreq_rxsnp_ownership_flip_pulse[6]
					 + rxreq_rxsnp_ownership_flip_pulse[7]
					 + rxreq_rxsnp_ownership_flip_pulse[8]
					 + rxreq_rxsnp_ownership_flip_pulse[9]
					 + rxreq_rxsnp_ownership_flip_pulse[10]
					 + rxreq_rxsnp_ownership_flip_pulse[11]
					 + rxreq_rxsnp_ownership_flip_pulse[12]
					 + rxreq_rxsnp_ownership_flip_pulse[13]
					 + rxreq_rxsnp_ownership_flip_pulse[14];
   
   
   //**************************************************************************************************/
   ///*
   // * To monitor flip regs pulse so that we can know
   // * how many credits we need to give back.
   // * i.e if user asserted 0x3 in flip_reg means we need to 
   // * give 2 credits back.
   // * If while we are decrementing count, user gives again a new flip
   // * then we will stop sending credits back and add new count and
   // * then again start giving it back!.
   // */
   //**************************************************************************************************/
   always@( posedge clk) begin
      if(~resetn) begin
	 rxreq_rxsnp_dec_count <= 0;
	 rxreq_rxsnp_give_back_credit <= 0;
      end
      else if(rxreq_rxsnp_refill_credits[4]) begin
	 rxreq_rxsnp_dec_count <= rxreq_rxsnp_refill_credits[3:0];
	 rxreq_rxsnp_give_back_credit <= 0;
      end
      else if(|rxreq_rxsnp_ownership_flip_pulse) begin
	 rxreq_rxsnp_dec_count <= rxreq_rxsnp_dec_count + rxreq_rxsnp_flip_pulse_count;
	 rxreq_rxsnp_give_back_credit <= 0;
      end
      else if((|rxreq_rxsnp_dec_count) && (rx_link_status_i == RUN)) begin
	 rxreq_rxsnp_dec_count <= rxreq_rxsnp_dec_count - 1;
	 rxreq_rxsnp_give_back_credit <= 1;
      end
      else begin
	 rxreq_rxsnp_dec_count <= rxreq_rxsnp_dec_count;
	 rxreq_rxsnp_give_back_credit <= 0;
      end
   end


   

   assign CHI_RXREQ_RXSNP_LCRDV    = rxreq_rxsnp_dec_credits;// giving credits to Transmit side for receiving flits
   assign rxreq_rxsnp_incr_credits = CHI_RXREQ_RXSNP_Received;//getting back credits when flit is stored.
   assign rxreq_rxsnp_dec_credits  = (rxreq_rxsnp_credits_available & rxreq_rxsnp_give_back_credit);

   

   chi_link_credit_manager u_CHI_RXRSP_Credit
     (
      .clk(clk),
      .resetn(resetn),
      .incr_credits(rxrsp_incr_credits),
      .dec_credits(rxrsp_dec_credits),
      .refill_credits(rxrsp_refill_credits),
      .credits_available(rxrsp_credits_available),
      .cur_credits(rxrsp_current_credits),
      .credit_maxed(rxrsp_credit_received)
      );


   always@ (posedge clk)
     begin
	if(~resetn) begin
	   rxrsp_credits_available_ff <= 0;
	end
	else begin
	   rxrsp_credits_available_ff <= rxrsp_credits_available;
	end
     end

   reg [3:0] rxrsp_dec_count;
   reg 	     rxrsp_give_back_credit;
   wire [3:0] rxrsp_flip_pulse_count;

   assign rxrsp_flip_pulse_count = 
				   rxrsp_ownership_flip_pulse[0]
				   + rxrsp_ownership_flip_pulse[1]
				   + rxrsp_ownership_flip_pulse[2]
				   + rxrsp_ownership_flip_pulse[3]
				   + rxrsp_ownership_flip_pulse[4]
				   + rxrsp_ownership_flip_pulse[5]
				   + rxrsp_ownership_flip_pulse[6]
				   + rxrsp_ownership_flip_pulse[7]
				   + rxrsp_ownership_flip_pulse[8]
				   + rxrsp_ownership_flip_pulse[9]
				   + rxrsp_ownership_flip_pulse[10]
				   + rxrsp_ownership_flip_pulse[11]
				   + rxrsp_ownership_flip_pulse[12]
				   + rxrsp_ownership_flip_pulse[13]
				   + rxrsp_ownership_flip_pulse[14];
   
   
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
	 rxrsp_dec_count <= 0;
	 rxrsp_give_back_credit <= 0;
      end
      else if(rxrsp_refill_credits[4]) begin
	 rxrsp_dec_count <= rxrsp_refill_credits[3:0];
	 rxrsp_give_back_credit <= 0;
      end
      else if(|rxrsp_ownership_flip_pulse) begin
	 rxrsp_dec_count <= rxrsp_dec_count + rxrsp_flip_pulse_count;
	 rxrsp_give_back_credit <= 0;
      end
      else if((|rxrsp_dec_count) && (rx_link_status_i == RUN)) begin
	 rxrsp_dec_count <= rxrsp_dec_count - 1;
	 rxrsp_give_back_credit <= 1;
      end
      else begin
	 rxrsp_dec_count <= rxrsp_dec_count;
	 rxrsp_give_back_credit <= 0;
      end
   end


   
   assign CHI_RXRSPLCRDV     = rxrsp_dec_credits;
   assign rxrsp_incr_credits = CHI_RXRSP_Received;// That Flit is received
   assign rxrsp_dec_credits  = (rxrsp_credits_available & rxrsp_give_back_credit);
   //sent only when allowed by software here
endmodule

