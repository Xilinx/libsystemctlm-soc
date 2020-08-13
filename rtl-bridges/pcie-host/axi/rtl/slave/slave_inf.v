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
 *   This module handles AXI-usr interface and SW registers. 
 * 
 */

`include "defines_common.vh"
`include "defines_slave.vh"

module slave_inf #(

         parameter EN_INTFS_AXI4                                        =  1 
        ,parameter EN_INTFS_AXI4LITE                                    =  0 
        ,parameter EN_INTFS_AXI3                                        =  0 
                        
        ,parameter ADDR_WIDTH                                           = 64    
        ,parameter DATA_WIDTH                                           = 128               
        ,parameter ID_WIDTH                                             = 16  
        ,parameter AWUSER_WIDTH                                         = 32    
        ,parameter WUSER_WIDTH                                          = 32    
        ,parameter BUSER_WIDTH                                          = 32    
        ,parameter ARUSER_WIDTH                                         = 32    
        ,parameter RUSER_WIDTH                                          = 32    
        ,parameter RAM_SIZE                                             = 16384             
        ,parameter MAX_DESC                                             = 16                   
        ,parameter FORCE_RESP_ORDER                                     = 1

)(

        //Clock and reset
         input 	     	                                                axi_aclk		
        ,input 	     	                                                axi_aresetn		
 		
        //S_AXI_USR
        ,input [ID_WIDTH-1:0]                                           s_axi_usr_awid
        ,input [ADDR_WIDTH-1:0]                                         s_axi_usr_awaddr
        ,input [7:0]                                                    s_axi_usr_awlen
        ,input [2:0]                                                    s_axi_usr_awsize
        ,input [1:0]                                                    s_axi_usr_awburst
        ,input [1:0]                                                    s_axi_usr_awlock
        ,input [3:0]                                                    s_axi_usr_awcache
        ,input [2:0]                                                    s_axi_usr_awprot
        ,input [3:0]                                                    s_axi_usr_awqos
        ,input [3:0]                                                    s_axi_usr_awregion 
        ,input [AWUSER_WIDTH-1:0]                                       s_axi_usr_awuser
        ,input                                                          s_axi_usr_awvalid
        ,output reg                                                     s_axi_usr_awready
        ,input [DATA_WIDTH-1:0]                                         s_axi_usr_wdata
        ,input [(DATA_WIDTH/8)-1:0]                                     s_axi_usr_wstrb
        ,input                                                          s_axi_usr_wlast
        ,input [ID_WIDTH-1:0]                                           s_axi_usr_wid
        ,input [WUSER_WIDTH-1:0]                                        s_axi_usr_wuser
        ,input                                                          s_axi_usr_wvalid
        ,output reg                                                     s_axi_usr_wready
        ,output [ID_WIDTH-1:0]                                          s_axi_usr_bid
        ,output [1:0]                                                   s_axi_usr_bresp
        ,output [BUSER_WIDTH-1:0]                                       s_axi_usr_buser
        ,output reg                                                     s_axi_usr_bvalid
        ,input                                                          s_axi_usr_bready
        ,input [ID_WIDTH-1:0]                                           s_axi_usr_arid
        ,input [ADDR_WIDTH-1:0]                                         s_axi_usr_araddr
        ,input [7:0]                                                    s_axi_usr_arlen
        ,input [2:0]                                                    s_axi_usr_arsize
        ,input [1:0]                                                    s_axi_usr_arburst
        ,input [1:0]                                                    s_axi_usr_arlock
        ,input [3:0]                                                    s_axi_usr_arcache
        ,input [2:0]                                                    s_axi_usr_arprot
        ,input [3:0]                                                    s_axi_usr_arqos
        ,input [3:0]                                                    s_axi_usr_arregion 
        ,input [ARUSER_WIDTH-1:0]                                       s_axi_usr_aruser
        ,input                                                          s_axi_usr_arvalid
        ,output reg                                                     s_axi_usr_arready
        ,output [ID_WIDTH-1:0]                                          s_axi_usr_rid
        ,output [DATA_WIDTH-1:0]                                        s_axi_usr_rdata
        ,output [1:0]                                                   s_axi_usr_rresp
        ,output                                                         s_axi_usr_rlast
        ,output [RUSER_WIDTH-1:0]                                       s_axi_usr_ruser
        ,output reg                                                     s_axi_usr_rvalid
        ,input                                                          s_axi_usr_rready


        //RDATA_RAM signals
        ,output reg  [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0]            uc2rb_rd_addr	   //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [9:0]
        ,input 	[DATA_WIDTH-1:0]                                        rb2uc_rd_data
        
        //WDATA_RAM and WSTRB_RAM signals				
        ,output	reg       	                                        uc2rb_wr_we	   
        ,output	     [(DATA_WIDTH/8)-1:0]                               uc2rb_wr_bwe       //Generate all 1s always. For DATA_WIDTH=128, it is [15:0] 	
        ,output	reg  [(`CLOG2((RAM_SIZE*8)/DATA_WIDTH))-1:0]            uc2rb_wr_addr	   //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [9:0]
        ,output	reg  [DATA_WIDTH-1:0]                                   uc2rb_wr_data      	
        ,output	reg  [(DATA_WIDTH/8)-1:0]                               uc2rb_wr_wstrb     //For DATA_WIDTH=128, it is [15:0]	
              		                                	
        ,output	reg  [MAX_DESC-1:0]                                     uc2hm_trig
        ,input 	[MAX_DESC-1:0]                                          hm2uc_done
      

        //Declare all signals
        ,input  [7:0]				                        int_version_major_ver
        ,input  [7:0]				                        int_version_minor_ver
        ,input  [7:0]				                        int_bridge_type_type
        ,input  [7:0]				                        int_axi_bridge_config_user_width
        ,input  [7:0]				                        int_axi_bridge_config_id_width
        ,input  [2:0]				                        int_axi_bridge_config_data_width
        ,input       				                        int_reset_dut_srst_3
        ,input       				                        int_reset_dut_srst_2
        ,input       				                        int_reset_dut_srst_1
        ,input       				                        int_reset_dut_srst_0
        ,input       				                        int_reset_srst
        ,input       				                        int_mode_select_imm_bresp
        ,input       				                        int_mode_select_mode_2
        ,input       				                        int_mode_select_mode_0_1
        ,output reg [MAX_DESC-1:0]		                        int_ownership_own
        ,input  [MAX_DESC-1:0]			                        int_ownership_flip_flip
        ,input  [MAX_DESC-1:0]			                        int_status_resp_comp_resp_comp
        ,input  [31:0]				                        int_status_resp_resp
        ,output reg [MAX_DESC-1:0]		                        int_status_busy_busy
        ,output [`CLOG2(MAX_DESC):0]		                        int_resp_fifo_free_level_level
        ,input       				                        int_intr_status_comp
        ,input       				                        int_intr_status_c2h
        ,input       				                        int_intr_status_error
        ,input       				                        int_intr_status_txn_avail
        ,output reg [MAX_DESC-1:0]		                        int_intr_txn_avail_status_avail
        ,input  [MAX_DESC-1:0]			                        int_intr_txn_avail_clear_clr_avail
        ,input  [MAX_DESC-1:0]			                        int_intr_txn_avail_enable_en_avail
        ,output reg [MAX_DESC-1:0]		                        int_intr_comp_status_comp
        ,input  [MAX_DESC-1:0]			                        int_intr_comp_clear_clr_comp
        ,input  [MAX_DESC-1:0]			                        int_intr_comp_enable_en_comp
        ,input       				                        int_intr_error_status_err_2
        ,input       				                        int_intr_error_status_err_1
        ,output reg    				                        int_intr_error_status_err_0
        ,input       				                        int_intr_error_clear_clr_err_2
        ,input       				                        int_intr_error_clear_clr_err_1
        ,input       				                        int_intr_error_clear_clr_err_0
        ,input       				                        int_intr_error_enable_en_err_2
        ,input       				                        int_intr_error_enable_en_err_1
        ,input       				                        int_intr_error_enable_en_err_0
        ,input  [31:0]				                        int_intr_h2c_0_h2c
        ,input  [31:0]				                        int_intr_h2c_1_h2c
        ,input  [31:0]				                        int_intr_c2h_0_status_c2h
        ,input  [31:0]				                        int_intr_c2h_1_status_c2h
        ,input  [31:0]				                        int_c2h_gpio_0_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_1_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_2_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_3_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_4_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_5_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_6_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_7_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_8_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_9_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_10_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_11_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_12_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_13_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_14_status_gpio
        ,input  [31:0]				                        int_c2h_gpio_15_status_gpio
        ,input  [31:0]				                        int_addr_in_0_addr
        ,input  [31:0]				                        int_addr_in_1_addr
        ,input  [31:0]				                        int_addr_in_2_addr
        ,input  [31:0]				                        int_addr_in_3_addr
        ,input  [31:0]				                        int_trans_mask_0_addr
        ,input  [31:0]				                        int_trans_mask_1_addr
        ,input  [31:0]				                        int_trans_mask_2_addr
        ,input  [31:0]				                        int_trans_mask_3_addr
        ,input  [31:0]				                        int_trans_addr_0_addr
        ,input  [31:0]				                        int_trans_addr_1_addr
        ,input  [31:0]				                        int_trans_addr_2_addr
        ,input  [31:0]				                        int_trans_addr_3_addr
        ,input  [31:0]                                                  int_resp_order_field

        `include "int_desc_output.vh"
        `include "int_desc_input.vh"


);

localparam DESC_IDX_WIDTH                                               = `CLOG2(MAX_DESC);
localparam WSTRB_WIDTH                                                  = (DATA_WIDTH/8);
localparam XLAST_WIDTH                                                  = 1;            //wlast/rlast width
localparam XRESP_WIDTH                                                  = 2;            //bresp/rresp width
localparam RAM_OFFSET_WIDTH                                             = `CLOG2((RAM_SIZE*8)/DATA_WIDTH);
localparam RDATA_RAM_STRT_ADDR                                          = RAM_SIZE*2;
localparam RDATA_RAM_END_ADDR                                           = RDATA_RAM_STRT_ADDR+RAM_SIZE-4;
localparam WDATA_RAM_STRT_ADDR                                          = RDATA_RAM_END_ADDR+4;
localparam WDATA_RAM_END_ADDR                                           = WDATA_RAM_STRT_ADDR+RAM_SIZE-4;
localparam WSTRB_RAM_STRT_ADDR                                          = WDATA_RAM_END_ADDR+4;
localparam WSTRB_RAM_END_ADDR                                           = WSTRB_RAM_STRT_ADDR+RAM_SIZE-4;

localparam WR_INF_IDLE                                                  = 2'b00;                        
localparam WR_INF_WAIT_ALC                                              = 2'b01;                           
localparam WR_INF_FILL_AWFIFO                                           = 2'b10;                            
localparam WR_INF_TXN_DONE                                              = 2'b11;                           

localparam WR_IDLE                                                      = 3'b000;                        
localparam WR_NEW_TXN                                                   = 3'b001;                           
localparam WR_NEW_WAIT                                                  = 3'b010;                            
localparam WR_CON_TXN                                                   = 3'b011;                           
localparam WR_CON_WAIT                                                  = 3'b100;                           
localparam WR_WAIT_WDATA                                                = 3'b101;                              

localparam WR_RESP_IDLE                                                 = 2'b00;
localparam WR_RESP_STRT                                                 = 2'b01;
localparam WR_RESP_WAIT                                                 = 2'b10;

localparam RD_INF_IDLE                                                  = 2'b00;                        
localparam RD_INF_WAIT_ALC                                              = 2'b01;                           
localparam RD_INF_FILL_ARFIFO                                           = 2'b10;                            
localparam RD_INF_TXN_DONE                                              = 2'b11;                           

localparam RD_DATA_IDLE                                                 = 3'b000;
localparam RD_DATA_NEW                                                  = 3'b001;
localparam RD_DATA_NEW_RDRAM                                            = 3'b010;
localparam RD_DATA_CON_RDRAM                                            = 3'b011;
localparam RD_DATA_CON_WAIT                                             = 3'b100;

localparam RD_RESP_IDLE                                                 = 2'b000;
localparam RD_RESP_STRT                                                 = 2'b001;
localparam RD_RESP_WAIT                                                 = 2'b010;

localparam WR_IDLE_DONE                                                 = 2'b00;
localparam WR_HM2UC_DONE                                                = 2'b01;
localparam WR_BRESP_DONE                                                = 2'b10;
localparam WR_HM2UC_BRESP_DONE                                          = 2'b11;

localparam W_FIFO_WIDTH                                                 = (EN_INTFS_AXI3==1'b1) ? (XLAST_WIDTH+ID_WIDTH+WSTRB_WIDTH+DATA_WIDTH) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (WSTRB_WIDTH+DATA_WIDTH) :
                                                                          (XLAST_WIDTH+WUSER_WIDTH+WSTRB_WIDTH+DATA_WIDTH) ;

localparam W_FIFO_LAST                                                  = (EN_INTFS_AXI3==1'b1) ? (XLAST_WIDTH+ID_WIDTH+WSTRB_WIDTH+DATA_WIDTH-1) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (XLAST_WIDTH+WUSER_WIDTH+WSTRB_WIDTH+DATA_WIDTH-1) ;

localparam W_FIFO_USER_MSB                                              = (EN_INTFS_AXI3==1'b1) ? (0) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (WUSER_WIDTH+WSTRB_WIDTH+DATA_WIDTH-1) ;

localparam W_FIFO_USER_LSB                                              = (EN_INTFS_AXI3==1'b1) ? (0) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (WSTRB_WIDTH+DATA_WIDTH) ;

localparam W_FIFO_ID_MSB                                                = (EN_INTFS_AXI3==1'b1) ? (ID_WIDTH+WSTRB_WIDTH+DATA_WIDTH-1) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (0) ;

localparam W_FIFO_ID_LSB                                                = (EN_INTFS_AXI3==1'b1) ? (WSTRB_WIDTH+DATA_WIDTH) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (0) ;

localparam W_FIFO_STRB_MSB                                              = (WSTRB_WIDTH+DATA_WIDTH-1) ;

localparam W_FIFO_STRB_LSB                                              = (DATA_WIDTH) ;

localparam W_FIFO_DATA_MSB                                              = (DATA_WIDTH-1) ;

localparam W_FIFO_DATA_LSB                                              = (0) ;

localparam B_FIFO_WIDTH                                                 = (EN_INTFS_AXI3==1'b1) ? (XRESP_WIDTH+ID_WIDTH+DESC_IDX_WIDTH) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (XRESP_WIDTH+DESC_IDX_WIDTH) :
                                                                          (XRESP_WIDTH+BUSER_WIDTH+ID_WIDTH+DESC_IDX_WIDTH) ;

localparam B_FIFO_RESP_MSB                                              = (EN_INTFS_AXI3==1'b1) ? (XRESP_WIDTH+ID_WIDTH+DESC_IDX_WIDTH-1) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (XRESP_WIDTH+DESC_IDX_WIDTH-1) :
                                                                          (XRESP_WIDTH+BUSER_WIDTH+ID_WIDTH+DESC_IDX_WIDTH-1) ;

localparam B_FIFO_RESP_LSB                                              = (EN_INTFS_AXI3==1'b1) ? (ID_WIDTH+DESC_IDX_WIDTH) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (DESC_IDX_WIDTH) :
                                                                          (BUSER_WIDTH+ID_WIDTH+DESC_IDX_WIDTH) ;

localparam B_FIFO_USER_MSB                                              = (EN_INTFS_AXI3==1'b1) ? (0) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (BUSER_WIDTH+ID_WIDTH+DESC_IDX_WIDTH-1) ;

localparam B_FIFO_USER_LSB                                              = (EN_INTFS_AXI3==1'b1) ? (0) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (ID_WIDTH+DESC_IDX_WIDTH) ;

localparam B_FIFO_ID_MSB                                                = (EN_INTFS_AXI3==1'b1) ? (ID_WIDTH+DESC_IDX_WIDTH-1) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (ID_WIDTH+DESC_IDX_WIDTH-1) ;

localparam B_FIFO_ID_LSB                                                = (EN_INTFS_AXI3==1'b1) ? (DESC_IDX_WIDTH) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (DESC_IDX_WIDTH) ;

localparam B_FIFO_IDX_MSB                                               = (DESC_IDX_WIDTH-1) ;

localparam B_FIFO_IDX_LSB                                               = (0) ;

localparam R_FIFO_WIDTH                                                 = (EN_INTFS_AXI3==1'b1) ? (XLAST_WIDTH+XRESP_WIDTH+ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (XRESP_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH) :
                                                                          (XLAST_WIDTH+XRESP_WIDTH+RUSER_WIDTH+ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH) ;

localparam R_FIFO_LAST                                                  = (EN_INTFS_AXI3==1'b1) ? (XLAST_WIDTH+XRESP_WIDTH+ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH-1) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (XRESP_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH-1) :
                                                                          (XLAST_WIDTH+XRESP_WIDTH+RUSER_WIDTH+ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH-1) ;

localparam R_FIFO_RESP_MSB                                              = (EN_INTFS_AXI3==1'b1) ? (XRESP_WIDTH+ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH-1) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (XRESP_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH-1) :
                                                                          (XRESP_WIDTH+RUSER_WIDTH+ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH-1) ;

localparam R_FIFO_RESP_LSB                                              = (EN_INTFS_AXI3==1'b1) ? (ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (DATA_WIDTH+DESC_IDX_WIDTH) :
                                                                          (RUSER_WIDTH+ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH) ;

localparam R_FIFO_USER_MSB                                              = (EN_INTFS_AXI3==1'b1) ? (0) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (RUSER_WIDTH+ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH-1) ;

localparam R_FIFO_USER_LSB                                              = (EN_INTFS_AXI3==1'b1) ? (0) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH) ;

localparam R_FIFO_ID_MSB                                                = (EN_INTFS_AXI3==1'b1) ? (ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH-1) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH-1) ;

localparam R_FIFO_ID_LSB                                                = (EN_INTFS_AXI3==1'b1) ? (DATA_WIDTH+DESC_IDX_WIDTH) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (0) :
                                                                          (DATA_WIDTH+DESC_IDX_WIDTH) ;

localparam R_FIFO_DATA_MSB                                              = (DATA_WIDTH+DESC_IDX_WIDTH-1) ;

localparam R_FIFO_DATA_LSB                                              = (DESC_IDX_WIDTH) ;

localparam R_FIFO_IDX_MSB                                               = (DESC_IDX_WIDTH-1) ;

localparam R_FIFO_IDX_LSB                                               = (0) ;

localparam SYNC_R_DIN_MISC_D_WIDTH                                      = (EN_INTFS_AXI3==1'b1) ? (XLAST_WIDTH+XRESP_WIDTH+ID_WIDTH) :
                                                                          (EN_INTFS_AXI4LITE==1'b1) ? (XRESP_WIDTH) :
                                                                          (XLAST_WIDTH+XRESP_WIDTH+RUSER_WIDTH+ID_WIDTH) ;
                                                                          
//Loop variables
integer                                                                 i;
integer                                                                 j;
integer                                                                 k;

//generate variable
genvar                                                                  gi;

reg  [0:0]	                                                        int_desc_n_txn_type_wr_strb [MAX_DESC-1:0];
reg  [0:0]	                                                        int_desc_n_txn_type_wr_rd [MAX_DESC-1:0];
reg  [3:0]	                                                        int_desc_n_attr_axregion [MAX_DESC-1:0];
reg  [3:0]	                                                        int_desc_n_attr_axqos [MAX_DESC-1:0];
reg  [2:0]	                                                        int_desc_n_attr_axprot [MAX_DESC-1:0];
reg  [3:0]	                                                        int_desc_n_attr_axcache [MAX_DESC-1:0];
reg  [1:0]	                                                        int_desc_n_attr_axlock [MAX_DESC-1:0];
reg  [1:0]	                                                        int_desc_n_attr_axburst [MAX_DESC-1:0];
reg  [31:0]	                                                        int_desc_n_axid_0_axid [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axid_1_axid [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axid_2_axid [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axid_3_axid [MAX_DESC-1:0];
reg  [31:0]	                                                        int_desc_n_axuser_0_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_1_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_2_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_3_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_4_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_5_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_6_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_7_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_8_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_9_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_10_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_11_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_12_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_13_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_14_axuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axuser_15_axuser [MAX_DESC-1:0];
reg  [15:0]	                                                        int_desc_n_size_txn_size [MAX_DESC-1:0];
reg  [2:0]	                                                        int_desc_n_axsize_axsize [MAX_DESC-1:0];
reg  [31:0]	                                                        int_desc_n_axaddr_0_addr [MAX_DESC-1:0];
reg  [31:0]	                                                        int_desc_n_axaddr_1_addr [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axaddr_2_addr [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_axaddr_3_addr [MAX_DESC-1:0];
reg  [31:0]	                                                        int_desc_n_data_offset_addr [MAX_DESC-1:0];
reg  [31:0]	                                                        int_desc_n_wuser_0_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_1_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_2_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_3_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_4_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_5_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_6_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_7_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_8_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_9_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_10_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_11_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_12_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_13_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_14_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wuser_15_wuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_data_host_addr_0_addr [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_data_host_addr_1_addr [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_data_host_addr_2_addr [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_data_host_addr_3_addr [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wstrb_host_addr_0_addr [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wstrb_host_addr_1_addr [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wstrb_host_addr_2_addr [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_wstrb_host_addr_3_addr [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_0_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_1_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_2_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_3_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_4_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_5_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_6_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_7_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_8_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_9_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_10_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_11_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_12_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_13_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_14_xuser [MAX_DESC-1:0];
wire [31:0]	                                                        int_desc_n_xuser_15_xuser [MAX_DESC-1:0];


//Write Channel
reg  [1:0]                                                              wr_inf_state;
wire [DESC_IDX_WIDTH-1:0]                                               AW_dout [MAX_DESC-1 : 0];
wire [DESC_IDX_WIDTH-1:0]                                               AW_dout_pre [MAX_DESC-1 : 0];
wire [MAX_DESC-1 : 0]                                                   AW_dout_pre_valid;
wire [MAX_DESC-1 : 0]                                                   AW_full;
wire [MAX_DESC-1 : 0]                                                   AW_empty;
reg  [MAX_DESC-1 : 0]                                                   AW_wren;
reg  [MAX_DESC-1 : 0]                                                   AW_rden;
reg  [DESC_IDX_WIDTH-1:0]                                               AW_din [MAX_DESC-1 : 0];
reg  [MAX_DESC-1 : 0]                                                   awid_matched;
reg  [MAX_DESC-1 : 0]                                                   AW_fifo_new;
wire [MAX_DESC-1 : 0]                                                   AW_fifo_valid;
reg  [ID_WIDTH-1:0]                                                     AW_fifo_awid[MAX_DESC-1 : 0];

reg                                                                     wr_txn_valid;
reg                                                                     wr_txn_valid_ff;
reg [7:0]                                                               wr_txn_size;              //AXLEN (Request is (AXLEN+1))
wire                                                                    wr_alc_valid;
reg                                                                     wr_alc_valid_ff;
wire [RAM_OFFSET_WIDTH-1:0]                                             wr_alc_offset;      //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [10:0]
wire [DESC_IDX_WIDTH-1:0]                                               wr_alc_idx;         //For MAX_DESC=16, it is [3:0] 
reg  [DESC_IDX_WIDTH-1:0]                                               wr_alc_idx_ff;      //For MAX_DESC=16, it is [3:0] 

reg  [RAM_OFFSET_WIDTH-1:0]                                             wr_desc_offset [MAX_DESC-1:0];
reg  [RAM_OFFSET_WIDTH-1:0]                                             wr_fifo_pop_offset[MAX_DESC-1:0];
reg  [DESC_IDX_WIDTH-1:0]                                               wr_fifo_pop_idx;

wire [DESC_IDX_WIDTH-1:0]                                               AW_W_dout;
wire                                                                    AW_W_full;
wire                                                                    AW_W_empty;
wire                                                                    AW_W_wren;
reg                                                                     AW_W_rden;
wire [DESC_IDX_WIDTH-1:0]                                               AW_W_din;

wire                                                                    W_full;
wire                                                                    W_empty;
wire                                                                    W_almost_full;
wire                                                                    W_almost_empty;
reg                                                                     W_wren;
reg                                                                     W_rden;

reg  [W_FIFO_WIDTH-1:0]                                                 W_din; 
wire [W_FIFO_WIDTH-1:0]                                                 W_dout; 
reg                                                                     wlast;
reg  [7:0]                                                              wlast_cntr;
reg  [7:0]                                                              awlen_sig;
reg  [MAX_DESC-1:0]                                                     error_wr_wlast;  
reg  [MAX_DESC-1:0]                                                     wr_req_avail;
reg  [DESC_IDX_WIDTH-1:0]                                               wr_alc_idx_current;
reg  [2:0]                                                              wr_state;
        
reg       	                                                        W_rden_ff;		

reg  [MAX_DESC-1:0]                                                     bresp_init_req;
reg  [MAX_DESC-1:0]                                                     bresp_init_req_proc;  //process bresp init request 
reg  [MAX_DESC-1:0]                                                     bresp_init_ser;
reg  [MAX_DESC-1:0]                                                     bresp_init_serfailed;  //it is just valid for value-1 of bresp_init_req_proc_onehot. //Serice failed.
wire [MAX_DESC-1:0]                                                     bresp_init_req_proc_onehot;  //One hot Vector
reg  [MAX_DESC-1:0]                                                     bresp_init_ff;

reg  [MAX_DESC-1:0]                                                     bresp_init_order_req;
reg  [DESC_IDX_WIDTH-1:0]                                               wr_resp_order_desc_idx;
reg  [MAX_DESC-1:0]                                                     bresp_init_order_ser;

reg  [MAX_DESC-1:0]                                                     bresp_init;
reg  [MAX_DESC-1:0]                                                     bresp_done; 


wire [BUSER_WIDTH-1:0]                                                  imm_bresp_mode_buser;

reg		                                                        B_wren;	
reg 		                                                        B_rden;	
wire [B_FIFO_WIDTH-1:0]                                                 B_din;	
wire [B_FIFO_WIDTH-1:0]                                                 B_dout;	
wire  		                                                        B_full;	
wire  		                                                        B_empty;

reg 		                                                        BIDX_wren;	
reg 		                                                        BIDX_rden;	
reg  [DESC_IDX_WIDTH-1:0]                                               BIDX_din;	
//reg  [DESC_IDX_WIDTH-1:0]                                               BIDX_din_sig[MAX_DESC-1:0];	
reg  [MAX_DESC-1:0]                                                     BIDX_din_sig[DESC_IDX_WIDTH-1:0];	
wire [DESC_IDX_WIDTH-1:0]                                               BIDX_dout;	
wire  		                                                        BIDX_full;	
wire  		                                                        BIDX_empty;
                                                                         
wire                                                                    bresp_gnt_vld;
wire [DESC_IDX_WIDTH-1:0]                                               bresp_gnt_idx;

wire [DESC_IDX_WIDTH-1:0]                                               b_idx;

reg  [1:0]                                                              wr_resp_state;

wire [MAX_DESC-1:0]                                                     wr_txn_cmpl;

reg  [1:0]                                                              wr_done_state[MAX_DESC-1:0];
reg  [1:0]                                                              wr_done_nextstate[MAX_DESC-1:0];

reg  [MAX_DESC-1:0]                                                     bresp_ana_done;  

wire [MAX_DESC-1:0]                                                     wr_txn_avail;

wire [DESC_IDX_WIDTH-1:0]                                               WR_RESP_ORDER_dout;
wire [DESC_IDX_WIDTH-1:0]                                               WR_RESP_ORDER_dout_pre;
wire                                                                    WR_RESP_ORDER_dout_pre_valid;
wire                                                                    WR_RESP_ORDER_full;
wire                                                                    WR_RESP_ORDER_empty;
wire                                                                    WR_RESP_ORDER_wren;
reg                                                                     WR_RESP_ORDER_rden;
wire [DESC_IDX_WIDTH-1:0]                                               WR_RESP_ORDER_din;
wire [DESC_IDX_WIDTH:0]                                                 WR_RESP_ORDER_fifo_counter;

//Read Channel
reg  [1:0]                                                              rd_inf_state;
wire [DESC_IDX_WIDTH-1:0]                                               AR_dout [MAX_DESC-1 : 0];
wire [DESC_IDX_WIDTH-1:0]                                               AR_dout_pre [MAX_DESC-1 : 0];
wire [MAX_DESC-1 : 0]                                                   AR_full;
wire [MAX_DESC-1 : 0]                                                   AR_empty;
reg  [MAX_DESC-1 : 0]                                                   AR_wren;
reg  [MAX_DESC-1 : 0]                                                   AR_rden;
reg  [DESC_IDX_WIDTH-1:0]                                               AR_din [MAX_DESC-1 : 0];
reg  [MAX_DESC-1 : 0]                                                   arid_matched;
reg  [MAX_DESC-1 : 0]                                                   AR_fifo_new;
wire [MAX_DESC-1 : 0]                                                   AR_fifo_valid;
reg  [ID_WIDTH-1:0]                                                     AR_fifo_arid[MAX_DESC-1 : 0];

reg                                                                     rd_txn_valid;
reg [7:0]                                                               rd_txn_size;              //AXLEN (Request is (AXLEN+1))
wire                                                                    rd_alc_valid;
wire [RAM_OFFSET_WIDTH-1:0]                                             rd_alc_offset;  //For RAM_SIZE=16384 and DATA_WIDTH=128, it is [10:0]
wire [DESC_IDX_WIDTH-1:0]                                               rd_alc_idx;     //For MAX_DESC=16, it is [3:0] 

reg  [MAX_DESC-1:0]                                                     rd_req_avail;
reg  [DESC_IDX_WIDTH-1:0]                                               rd_alc_idx_current;

reg  [RAM_OFFSET_WIDTH-1:0]                                             rd_desc_offset [MAX_DESC-1:0];


reg  [MAX_DESC-1:0]                                                     rresp_init_req;
reg  [MAX_DESC-1:0]                                                     rresp_init_req_proc;
reg  [MAX_DESC-1:0]                                                     rresp_init_ser;
reg  [MAX_DESC-1:0]                                                     rresp_init_serfailed;  //it is just valid for value-1 of rresp_init_req_onehot. //Ser failed.
wire [MAX_DESC-1:0]                                                     rresp_init_req_onehot;  //One hot Vector
reg  [MAX_DESC-1:0]                                                     rresp_init_ff;

reg  [MAX_DESC-1:0]                                                     rresp_init_order_req;
reg  [DESC_IDX_WIDTH-1:0]                                               rd_resp_order_desc_idx;
reg  [MAX_DESC-1:0]                                                     rresp_init_order_ser;

reg  [MAX_DESC-1:0]                                                     rresp_init;
reg  [MAX_DESC-1:0]                                                     rresp_done; 

wire		                                                        R_wren;	
reg 		                                                        R_rden;	
wire [R_FIFO_WIDTH-1:0]                                                 R_din;	
wire [R_FIFO_WIDTH-1:0]                                                 R_dout;	
wire  		                                                        R_full;	
wire  		                                                        R_empty;
wire                                                                    R_almost_full;
wire                                                                    R_almost_empty;

reg 		                                                        RIDX_wren;	
reg 		                                                        RIDX_rden;	
reg  [DESC_IDX_WIDTH-1:0]                                               RIDX_din;	
//reg  [DESC_IDX_WIDTH-1:0]                                               RIDX_din_sig[MAX_DESC-1:0];	
reg  [MAX_DESC-1:0]                                                     RIDX_din_sig[DESC_IDX_WIDTH-1:0];	
wire [DESC_IDX_WIDTH-1:0]                                               RIDX_dout;	
wire  		                                                        RIDX_full;	
wire  		                                                        RIDX_empty;

wire [MAX_DESC-1:0]                                                     rd_txn_cmpl;

reg  [2:0]                                                              rd_data_state;
reg                                                                     uc2rb_rd_valid;
reg  [RAM_OFFSET_WIDTH-1:0]                                             rd_offset;
reg  [7:0]                                                              rdata_count;       
reg  [7:0]                                                              arlen;             
reg  [DESC_IDX_WIDTH-1:0]                                               rd_idx;            
reg  [R_FIFO_WIDTH-1:0]                                                 r_din;	
                                                         
reg  [1:0]                                                              rd_resp_state;

wire [MAX_DESC-1:0]                                                     rd_txn_avail;

wire                                                                    rresp_gnt_vld;
wire [DESC_IDX_WIDTH-1:0]                                               rresp_gnt_idx;

wire [DESC_IDX_WIDTH-1:0]                                               r_idx;

wire [DESC_IDX_WIDTH-1:0]                                               RD_RESP_ORDER_dout;
wire [DESC_IDX_WIDTH-1:0]                                               RD_RESP_ORDER_dout_pre;
wire                                                                    RD_RESP_ORDER_dout_pre_valid;
wire                                                                    RD_RESP_ORDER_full;
wire                                                                    RD_RESP_ORDER_empty;
wire                                                                    RD_RESP_ORDER_wren;
reg                                                                     RD_RESP_ORDER_rden;
wire [DESC_IDX_WIDTH-1:0]                                               RD_RESP_ORDER_din;
wire [DESC_IDX_WIDTH:0]                                                 RD_RESP_ORDER_fifo_counter;


//Common signals for write and read channel
reg  [DESC_IDX_WIDTH-1:0]                                               sig_resp_order_desc_idx;
reg                                                                     sig_resp_order_valid;

wire [DESC_IDX_WIDTH:0]                                                 resp_free_entry;

wire [DESC_IDX_WIDTH-1:0]                                               resp_desc_idx;
wire                                                                    resp_valid;

wire                                                                    resp_order_field_valid;
reg                                                                     resp_order_field_valid_ff;

reg  [MAX_DESC-1:0]                                                     req_avail;
reg  [MAX_DESC-1:0]                                                     txn_avail;

reg  [MAX_DESC-1:0]                                                     hm2uc_done_pulse;

wire [MAX_DESC-1:0]                                                     hm2uc_bresp_done;

reg  [MAX_DESC-1:0]                                                     int_ownership_own_ff;	

reg  [MAX_DESC-1:0]                                                     hm2uc_done_ff;

reg  [MAX_DESC-1:0]                                                     txn_avail_ff;
        
reg  [MAX_DESC-1:0]     			                        int_intr_txn_avail_clear_clr_avail_ff;

reg  [MAX_DESC-1:0]                                                     comp_ff;
        
reg  [MAX_DESC-1:0]     			                        int_intr_comp_clear_clr_comp_ff;

reg  [MAX_DESC-1:0]                                                     error_wr_buser;  
reg  [MAX_DESC-1:0]                                                     error_wr_bresp;  

reg  [MAX_DESC-1:0]                                                     txn_cmpl;
wire [MAX_DESC-1:0]                                                     comp;

reg  [MAX_DESC-1:0]                                                     ownership_cntl_hw;      

reg  [MAX_DESC-1:0]                                                     req_avail_ff;      

reg  [MAX_DESC-1:0]                                                     txn_cmpl_ff;      

reg  [MAX_DESC-1:0]                                                     ownership_cntl_hw_ff;
        
reg  [MAX_DESC-1:0]     			                        int_ownership_flip_flip_ff;

wire                                                                    error_ctl;
reg                                                                     error_ctl_hw;

reg                                                                     int_intr_error_clear_clr_err_0_ff;
reg                                                                     error_ctl_hw_ff;

///////////////////////
//2-D array of descriptor fields
//////////////////////

`include "user_slave_desc_2d.vh"

///////////////////////
//Tie unused signals
//////////////////////

generate

for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_unused_desc_sig

  assign int_desc_n_axaddr_2_addr[gi] = 32'h0;
  assign int_desc_n_axaddr_3_addr[gi] = 32'h0;
  assign int_desc_n_axid_1_axid[gi] = 32'h0;
  assign int_desc_n_axid_2_axid[gi] = 32'h0;
  assign int_desc_n_axid_3_axid[gi] = 32'h0;
  assign int_desc_n_axuser_1_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_2_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_3_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_4_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_5_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_6_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_7_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_8_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_9_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_10_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_11_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_12_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_13_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_14_axuser[gi] = 32'h0;
  assign int_desc_n_axuser_15_axuser[gi] = 32'h0;
  assign int_desc_n_wuser_1_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_2_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_3_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_4_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_5_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_6_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_7_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_8_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_9_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_10_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_11_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_12_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_13_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_14_wuser[gi] = 32'h0;
  assign int_desc_n_wuser_15_wuser[gi] = 32'h0;

end

endgenerate  


///////////////////////
//Instantiate Transation Allocator
//Description :
//  txn_allocator allocates descriptor number and offset of data/strb-RAM for write
//  and/or read requests.
//////////////////////

txn_allocator #(
         .ADDR_WIDTH		                                        (ADDR_WIDTH)
        ,.DATA_WIDTH		                                        (DATA_WIDTH)
        ,.ID_WIDTH		                                        (ID_WIDTH)
	,.AWUSER_WIDTH                                                  (AWUSER_WIDTH)
	,.WUSER_WIDTH                                                   (WUSER_WIDTH)
	,.BUSER_WIDTH                                                   (BUSER_WIDTH)
	,.ARUSER_WIDTH                                                  (ARUSER_WIDTH)
	,.RUSER_WIDTH                                                   (RUSER_WIDTH)
        ,.RAM_SIZE		                                        (RAM_SIZE)
        ,.MAX_DESC		                                        (MAX_DESC)
) i_txn_allocator (
         .rd_alc_valid		                                        (rd_alc_valid)
        ,.rd_alc_offset		                                        (rd_alc_offset)
        ,.rd_alc_idx		                                        (rd_alc_idx)
        ,.wr_alc_valid		                                        (wr_alc_valid)
        ,.wr_alc_offset		                                        (wr_alc_offset)
        ,.wr_alc_idx		                                        (wr_alc_idx)
        ,.axi_aclk		                                        (axi_aclk)
        ,.axi_aresetn		                                        (axi_aresetn)
        ,.int_ownership_own		                                (int_ownership_own)
        ,.int_status_busy_busy	                                        (int_status_busy_busy)
        ,.rd_txn_cmpl	                                                (rd_txn_cmpl)
        ,.wr_txn_cmpl	                                                (wr_txn_cmpl)
        ,.rd_txn_valid		                                        (rd_txn_valid)
        ,.rd_txn_size		                                        (rd_txn_size)
        ,.wr_txn_valid		                                        (wr_txn_valid)
        ,.wr_txn_size		                                        (wr_txn_size)
        `include "txn_allocator_inst.vh"        
);

///////////////////////
//Description: 
//  At any clock-edge, int_desc_n_* signals can be updated either by AR or AW channel. 
//  Here, priority is given to AR-channel. 
//  AR-channel can update the signals once txn allocation is done (on rd_alc_valid).
//  AW-channel can update the signals once txn allocation is done (on wr_alc_valid/wr_alc_valid_ff/both).
//Signal :
//  int_desc_n_data_offset_addr                   
//  int_desc_n_txn_type_wr_rd                     
//  int_desc_n_axid_0_axid                        
//  int_desc_n_axaddr_0_addr                      
//  int_desc_n_axaddr_1_addr                      
//  int_desc_n_size_txn_size                      
//  int_desc_n_axsize_axsize                      
//  int_desc_n_attr_axburst                       
//  int_desc_n_attr_axlock                        
//  int_desc_n_attr_axcache                       
//  int_desc_n_attr_axprot                        
//  int_desc_n_attr_axqos                         
//  int_desc_n_attr_axregion                      
//  int_desc_n_axuser_0_axuser                    
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    wr_txn_valid_ff <= 'h0;
  end else begin
    wr_txn_valid_ff <= wr_txn_valid;
  end
end
always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    wr_alc_valid_ff <= 'h0;
  end else begin
    wr_alc_valid_ff <= wr_alc_valid;
  end
end
always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    wr_alc_idx_ff <= 'h0;
  end else begin
    wr_alc_idx_ff <= wr_alc_idx;
  end
end

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_int_desc_n_data_offset_addr
      int_desc_n_data_offset_addr[i]         <= 'b0;
      int_desc_n_txn_type_wr_rd[i]           <= 'b0;
      int_desc_n_axid_0_axid[i]              <= 'b0;
      int_desc_n_axaddr_0_addr[i]            <= 'b0;
      int_desc_n_axaddr_1_addr[i]            <= 'b0;
      int_desc_n_size_txn_size[i]            <= 'b0;
      int_desc_n_axsize_axsize[i]            <= 'b0;
      int_desc_n_attr_axburst[i]             <= 'b0;
      int_desc_n_attr_axlock[i]              <= 'b0;
      int_desc_n_attr_axcache[i]             <= 'b0;
      int_desc_n_attr_axprot[i]              <= 'b0;
      int_desc_n_attr_axqos[i]               <= 'b0;
      int_desc_n_attr_axregion[i]            <= 'b0;
      int_desc_n_axuser_0_axuser[i]          <= 'b0;
    end

  //update the signals once txn allocation is done ((on rd_alc_valid)) 
  end else if (rd_txn_valid==1'b1 && rd_alc_valid==1'b1) begin 
    int_desc_n_data_offset_addr[rd_alc_idx]         <= (rd_alc_offset*DATA_WIDTH/8);
    int_desc_n_txn_type_wr_rd[rd_alc_idx]           <= 1'b1;        //Read Transaction
    `IF_INTFS_AXI4
    int_desc_n_attr_axqos[rd_alc_idx]               <= s_axi_usr_arqos;
    int_desc_n_attr_axregion[rd_alc_idx]            <= s_axi_usr_arregion;
    int_desc_n_axuser_0_axuser[rd_alc_idx]          <= s_axi_usr_aruser;
    int_desc_n_size_txn_size[rd_alc_idx]            <= (s_axi_usr_arlen[7:0]+1)*DATA_WIDTH/8;
    int_desc_n_attr_axlock[rd_alc_idx]              <= {1'b0,s_axi_usr_arlock[0]};
    `END_INTFS
    `IF_INTFS_AXI3
    int_desc_n_size_txn_size[rd_alc_idx]            <= (s_axi_usr_arlen[3:0]+1)*DATA_WIDTH/8;
    int_desc_n_attr_axlock[rd_alc_idx]              <= s_axi_usr_arlock[1:0];
    `END_INTFS
    `IF_INTFS_AXI4_OR_AXI3
    int_desc_n_axid_0_axid[rd_alc_idx]              <= { {(32-ID_WIDTH){1'b0}}, s_axi_usr_arid };
    int_desc_n_axsize_axsize[rd_alc_idx]            <= s_axi_usr_arsize;
    int_desc_n_attr_axburst[rd_alc_idx]             <= s_axi_usr_arburst;
    int_desc_n_attr_axcache[rd_alc_idx]             <= s_axi_usr_arcache;
    `END_INTFS
    `IF_INTFS_AXI4LITE
    int_desc_n_size_txn_size[rd_alc_idx]            <= ('h0+1)*DATA_WIDTH/8;
    `END_INTFS
    int_desc_n_axaddr_0_addr[rd_alc_idx]            <= s_axi_usr_araddr[31:0];
    int_desc_n_axaddr_1_addr[rd_alc_idx]            <= s_axi_usr_araddr[63:32];
    int_desc_n_attr_axprot[rd_alc_idx]              <= s_axi_usr_arprot;
  
  //update the signals once txn allocation is done (on wr_alc_valid)
  end else if (wr_txn_valid==1'b1 && wr_alc_valid==1'b1) begin
    int_desc_n_data_offset_addr[wr_alc_idx]           <= (wr_alc_offset*DATA_WIDTH/8);
    int_desc_n_txn_type_wr_rd[wr_alc_idx]             <= 1'b0;        //Write Transaction
    `IF_INTFS_AXI4         
    int_desc_n_attr_axqos[wr_alc_idx]                 <= s_axi_usr_awqos;
    int_desc_n_attr_axregion[wr_alc_idx]              <= s_axi_usr_awregion;
    int_desc_n_axuser_0_axuser[wr_alc_idx]            <= s_axi_usr_awuser;
    int_desc_n_size_txn_size[wr_alc_idx]              <= (s_axi_usr_awlen[7:0]+1)*DATA_WIDTH/8;
    int_desc_n_attr_axlock[wr_alc_idx]                <= {1'b0,s_axi_usr_awlock[0]};
    `END_INTFS
    `IF_INTFS_AXI3
    int_desc_n_size_txn_size[wr_alc_idx]              <= (s_axi_usr_awlen[3:0]+1)*DATA_WIDTH/8;
    int_desc_n_attr_axlock[wr_alc_idx]                <= s_axi_usr_awlock[1:0];
    `END_INTFS
    `IF_INTFS_AXI4_OR_AXI3        
    int_desc_n_axid_0_axid[wr_alc_idx]                <= { {(32-ID_WIDTH){1'b0}}, s_axi_usr_awid};
    int_desc_n_axsize_axsize[wr_alc_idx]              <= s_axi_usr_awsize;
    int_desc_n_attr_axburst[wr_alc_idx]               <= s_axi_usr_awburst;
    int_desc_n_attr_axcache[wr_alc_idx]               <= s_axi_usr_awcache;
    `END_INTFS
    `IF_INTFS_AXI4LITE
    int_desc_n_size_txn_size[wr_alc_idx]              <= ('h0+1)*DATA_WIDTH/8;
    `END_INTFS
    int_desc_n_axaddr_0_addr[wr_alc_idx]              <= s_axi_usr_awaddr[31:0];
    int_desc_n_axaddr_1_addr[wr_alc_idx]              <= s_axi_usr_awaddr[63:32];
    int_desc_n_attr_axprot[wr_alc_idx]                <= s_axi_usr_awprot;
  
  //update the signals once txn allocation is done (on wr_alc_valid_ff)
  end else if (wr_txn_valid_ff==1'b1 && wr_alc_valid_ff==1'b1) begin
    int_desc_n_data_offset_addr[wr_alc_idx_ff]         <= (wr_alc_offset*DATA_WIDTH/8);
    int_desc_n_txn_type_wr_rd[wr_alc_idx_ff]           <= 1'b0;        //Write Transaction
    `IF_INTFS_AXI4         
    int_desc_n_attr_axqos[wr_alc_idx_ff]               <= s_axi_usr_awqos;
    int_desc_n_attr_axregion[wr_alc_idx_ff]            <= s_axi_usr_awregion;
    int_desc_n_axuser_0_axuser[wr_alc_idx_ff]          <= s_axi_usr_awuser;
    int_desc_n_size_txn_size[wr_alc_idx_ff]            <= (s_axi_usr_awlen[7:0]+1)*DATA_WIDTH/8;
    int_desc_n_attr_axlock[wr_alc_idx_ff]              <= {1'b0,s_axi_usr_awlock[0]};
    `END_INTFS
    `IF_INTFS_AXI3
    int_desc_n_size_txn_size[wr_alc_idx_ff]            <= (s_axi_usr_awlen[3:0]+1)*DATA_WIDTH/8;
    int_desc_n_attr_axlock[wr_alc_idx_ff]              <= s_axi_usr_awlock[1:0];
    `END_INTFS
    `IF_INTFS_AXI4_OR_AXI3        
    int_desc_n_axid_0_axid[wr_alc_idx_ff]              <= { {(32-ID_WIDTH){1'b0}}, s_axi_usr_awid};
    int_desc_n_axsize_axsize[wr_alc_idx_ff]            <= s_axi_usr_awsize;
    int_desc_n_attr_axburst[wr_alc_idx_ff]             <= s_axi_usr_awburst;
    int_desc_n_attr_axcache[wr_alc_idx_ff]             <= s_axi_usr_awcache;
    `END_INTFS
    `IF_INTFS_AXI4LITE
    int_desc_n_size_txn_size[wr_alc_idx_ff]            <= ('h0+1)*DATA_WIDTH/8;
    `END_INTFS
    int_desc_n_axaddr_0_addr[wr_alc_idx_ff]            <= s_axi_usr_awaddr[31:0];
    int_desc_n_axaddr_1_addr[wr_alc_idx_ff]            <= s_axi_usr_awaddr[63:32];
    int_desc_n_attr_axprot[wr_alc_idx_ff]              <= s_axi_usr_awprot;
  
  end
end  

///////////////////////
//Description: 
//  Response order from SW
//////////////////////

`FF_RSTLOW(axi_aclk,axi_aresetn,resp_order_field_valid,resp_order_field_valid_ff)

assign resp_order_field_valid = int_resp_order_field[31];

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    sig_resp_order_desc_idx <= 'b0;
    sig_resp_order_valid    <= 'b0;  
  end else if (sig_resp_order_valid==1'b1) begin 
    sig_resp_order_valid    <= 'b0;  
  end else if (resp_order_field_valid==1'b1 && resp_order_field_valid_ff==1'b0) begin 
    sig_resp_order_valid       <= 1'b1;
    sig_resp_order_desc_idx    <= int_resp_order_field[DESC_IDX_WIDTH-1:0];  
  end else begin 
    sig_resp_order_valid <= 'b0;
  end
end


		  
///////////////////////
//AW-Channel
//////////////////////

//AW_fifo PUSH logic

// awready generation if transaction allocation is successful. 
// This signal is always one clock pulse. 

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
      wr_txn_valid         <= 1'b0;
      s_axi_usr_awready    <= 1'b0;
      wr_alc_idx_current   <= 'b0;
      wr_inf_state         <= WR_INF_IDLE;
      AW_fifo_new    <= 'b0 ;
      awid_matched   <= 'b0;
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AW_wren_reset
        AW_wren[i] <= 'b0;
        AW_din[i]  <= 'b0;
        AW_fifo_awid[i] <= 'b0;
      end
  end else begin 

    case(wr_inf_state)

    WR_INF_IDLE: begin
      //Request for allocation when awvalid and awready is high and there is no pending request
      if (s_axi_usr_awvalid==1'b1 && s_axi_usr_awready==1'b0 && wr_txn_valid==1'b0) begin
        wr_inf_state                              <= WR_INF_WAIT_ALC;
        wr_txn_valid                              <= 1'b1;  
        wr_txn_size                               <= (EN_INTFS_AXI3==1'b1) ? {4'b0,s_axi_usr_awlen[3:0]} : (EN_INTFS_AXI4LITE==1'b1) ? 'h0 : s_axi_usr_awlen[7:0] ;
      end else begin
        wr_inf_state                              <= WR_INF_IDLE;
      end
    
    //Wait till txn allocation is completed  
    end WR_INF_WAIT_ALC: begin
      //If allocation completes
      if (wr_txn_valid==1'b1 && wr_alc_valid==1'b1) begin 
        wr_inf_state                              <= WR_INF_FILL_AWFIFO;   
        wr_txn_valid                              <= 1'b0;      // de-assert allocation request
        wr_desc_offset[wr_alc_idx]                <= wr_alc_offset;
        wr_alc_idx_current                        <= wr_alc_idx;
        s_axi_usr_awready                         <= 1'b1;      //assert awready
        `IF_INTFS_AXI4_OR_AXI3 
        for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_awid_matched
          awid_matched[i]                         <= ( (AW_fifo_valid[i]==1'b1) && (AW_fifo_awid[i]==s_axi_usr_awid) ) ? 1'b1 : 1'b0;
        end
        AW_fifo_new                               <= ((~AW_fifo_valid))&(-(~AW_fifo_valid)) ;   //One-hot vector. Priority to LSB first.
        `END_INTFS
      //Wait until allocation is done
      end else begin
        wr_inf_state                              <= WR_INF_WAIT_ALC;
      end
    
    //PUSH desc-idx to AW_fifo
    end WR_INF_FILL_AWFIFO: begin
      if (s_axi_usr_awvalid==1'b1 && s_axi_usr_awready==1'b1) begin 
        wr_inf_state                              <= WR_INF_TXN_DONE;
        s_axi_usr_awready                         <= 1'b0;
        `IF_INTFS_AXI4_OR_AXI3        
        if ( (|awid_matched)==1'b1 ) begin   //AW_fifo exists with matching awid
          for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AW_wren_matched
            if (awid_matched[i]==1'b1) begin
              AW_wren[i] <= 1'b1;                 
              AW_din[i]  <= wr_alc_idx_current;
            end
          end
        end else begin  //Add in new AW_fifo
          for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AW_wren_new
            if (AW_fifo_new[i]==1'b1) begin
              AW_wren[i] <= 1'b1;                 
              AW_din[i]  <= wr_alc_idx_current;
              AW_fifo_awid[i]     <= s_axi_usr_awid;
            end
          end
        end  
        `END_INTFS
        `IF_INTFS_AXI4LITE 
        AW_wren[0] <= 1'b1;                 
        AW_din[0]  <= wr_alc_idx_current;
        `END_INTFS
      end else begin
        wr_inf_state                              <= WR_INF_FILL_AWFIFO;
      end

    //AW-channel ohandshaking done, make AW_wren signal low
    end WR_INF_TXN_DONE: begin
      wr_inf_state                                <= WR_INF_IDLE;
      `IF_INTFS_AXI4_OR_AXI3        
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AW_wren_low
        AW_wren[i] <= 1'b0;                 
      end
      `END_INTFS
      `IF_INTFS_AXI4LITE 
      AW_wren[0] <= 1'b0;                 
      `END_INTFS
    end default: begin
      wr_inf_state <= wr_inf_state;

    end
    endcase
  end
end  

// An AW_fifo is valid when it's not empty

generate

`IF_INTFS_AXI4_OR_AXI3        
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_AW_fifo_valid
  assign AW_fifo_valid[gi] = ~AW_empty[gi];
end
`END_INTFS

endgenerate  



//AW_fifo instantiation
generate

`IF_INTFS_AXI4_OR_AXI3 

// MAX_DESC AW_fifo are instantiated. 
// Each AW_fifo has unique awid (AW_fifo_awid).
// AW_fifo stores description index. 
// The fifo can store upto MAX_DESC description indices.
// If the awid does not match with AW_fifo_awid of any fifo, a new fifo is filled and AW_fifo_awid is updated.
// If the awid matches with AW_fifo_awid of any fifo, the desc index of that txn is pushed into same fifo.

for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_AW_fifo
sync_fifo #(
          .WIDTH		                                        (DESC_IDX_WIDTH)
         ,.DEPTH		                                        (MAX_DESC)
) AW_fifo (
          .dout	                                                        (AW_dout[gi])
         ,.dout_pre	                                                (AW_dout_pre[gi])
         ,.dout_pre_valid                                               (AW_dout_pre_valid[gi])
         ,.full	                                                        (AW_full[gi])
         ,.empty	                                                (AW_empty[gi])
         ,.clk	                                                        (axi_aclk)
         ,.rst_n	                                                (axi_aresetn)
         ,.wren	                                                        (AW_wren[gi])
         ,.rden	                                                        (AW_rden[gi])
         ,.din	                                                        (AW_din[gi])
);
end
`END_INTFS

`IF_INTFS_AXI4LITE 

// One AW_fifo is instantiated as there is no awid in AXI4LITE.
// AW_fifo stores description index. 
// The fifo can store upto MAX_DESC description indices.
// With every new aw request, the desc index of the txn is pushed into fifo.

sync_fifo #(
          .WIDTH		                                        (DESC_IDX_WIDTH)
         ,.DEPTH		                                        (MAX_DESC)
) AW_fifo (
          .dout	                                                        (AW_dout[0])
         ,.dout_pre	                                                (AW_dout_pre[0])
         ,.dout_pre_valid                                               (AW_dout_pre_valid[0])
         ,.full	                                                        (AW_full[0])
         ,.empty	                                                (AW_empty[0])
         ,.clk	                                                        (axi_aclk)
         ,.rst_n	                                                (axi_aresetn)
         ,.wren	                                                        (AW_wren[0])
         ,.rden	                                                        (AW_rden[0])
         ,.din	                                                        (AW_din[0])
);
`END_INTFS
endgenerate


//AW_W_fifo PUSH logic

//Upon write txn allocation, fill AW_W_fifo with allocated desc index
assign AW_W_wren  = (wr_txn_valid==1'b1 && wr_alc_valid==1'b1); 
assign AW_W_din   = wr_alc_idx;

//AW_W_fifo instantiation

// AW_W_fifo is used for AW-Channel and W-channel
// Description :
//   This FIFO is required to store the order of AW requests. Output from this
//   FIFO is used to process W-channel data.

sync_fifo #(
          .WIDTH		                                        (DESC_IDX_WIDTH)
         ,.DEPTH		                                        (MAX_DESC)
) AW_W_fifo (
          .dout	                                                        (AW_W_dout)
         ,.full	                                                        (AW_W_full)
         ,.empty	                                                (AW_W_empty)
         ,.clk	                                                        (axi_aclk)
         ,.rst_n	                                                (axi_aresetn)
         ,.wren	                                                        (AW_W_wren)
         ,.rden	                                                        (AW_W_rden)
         ,.din	                                                        (AW_W_din)
);
  

//////////////////////
//W-Channel
//////////////////////

//wready remains '1' if W_fifo has space left.
always @(posedge axi_aclk) begin
if (axi_aresetn == 1'b0) begin
 s_axi_usr_wready                               <= 1'b0;
end else if (!W_almost_full) begin 
 s_axi_usr_wready                               <= 1'b1;
end else begin 
 s_axi_usr_wready                               <= 1'b0;
end
end

//W_fifo PUSH logic

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
   W_wren                                         <= 1'b0;
  
  //Upon wvalid and wready, push data into W_fifo.
  end else if (s_axi_usr_wvalid==1'b1 && s_axi_usr_wready==1'b1) begin         
   W_wren                                         <= 1'b1;
   `IF_INTFS_AXI4 
   W_din                                          <= { s_axi_usr_wlast
                                                      ,s_axi_usr_wuser 
                                                      ,s_axi_usr_wstrb 
                                                      ,s_axi_usr_wdata };
   `END_INTFS
   `IF_INTFS_AXI4LITE 
   W_din                                          <= { s_axi_usr_wstrb 
                                                      ,s_axi_usr_wdata };
   `END_INTFS
   `IF_INTFS_AXI3 
   W_din                                          <= { s_axi_usr_wlast
                                                      ,s_axi_usr_wid 
                                                      ,s_axi_usr_wstrb 
                                                      ,s_axi_usr_wdata };
   `END_INTFS
  
  end else begin         
   W_wren                                         <= 1'b0;
  end
end

//W_fifo instantiation

// W_fifo holds wdata, wstrb along with all w-channel sideband signals.
 

sync_fifo #(
          //Ref:  .WIDTH		                                        (1+ID_WIDTH+WUSER_WIDTH+WSTRB_WIDTH+DATA_WIDTH)
          .WIDTH		                                        (W_FIFO_WIDTH)  
         ,.DEPTH		                                        (8) 
         ,.ALMOST_FULL_DEPTH		                                (8-2)      //DEPTH-2           
         ,.ALMOST_EMPTY_DEPTH		                                (2)         // Not used
) W_fifo (
          .dout	                                                        (W_dout)
         ,.full	                                                        (W_full)
         ,.empty	                                                (W_empty)
         ,.almost_full	                                                (W_almost_full)
         ,.almost_empty	                                                (W_almost_empty)
         ,.clk	                                                        (axi_aclk)
         ,.rst_n	                                                (axi_aresetn)
         ,.wren	                                                        (W_wren)
         ,.rden	                                                        (W_rden)
         ,.din	                                                        (W_din)
);


//AW_W_fifo POP logic and W_fifo POP logic

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    W_rden_ff    <= 1'b0;
    uc2rb_wr_we  <= 1'b0;
  end else begin
    W_rden_ff    <= W_rden;
    uc2rb_wr_we  <= W_rden_ff;
  end
end

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    uc2rb_wr_data   <= 'b0;
    uc2rb_wr_wstrb  <= 'b0;
  end else begin
    uc2rb_wr_data   <= W_dout[W_FIFO_DATA_MSB : W_FIFO_DATA_LSB]; 
    uc2rb_wr_wstrb  <= W_dout[W_FIFO_STRB_MSB : W_FIFO_STRB_LSB];
  end
end

// Below state machine starts processing one transaction and returns to idle
// state again upon writing all transfers of that transaction to internal RAMs.
// For AXI4/AXI3, after processing wlast and for AXI4LITE, after processing
// one transfer, the state machine returns back to idle state.

always @(posedge axi_aclk) begin
if (axi_aresetn == 1'b0) begin
  wr_state                                              <= WR_IDLE;
  AW_W_rden                                             <= 1'b0;
  W_rden                                                <= 1'b0;
  wr_req_avail                                          <= 'b0;
  wlast <= 'b0;
  wlast_cntr                                            <= 'b0;
  awlen_sig                                             <= 'b0;
  error_wr_wlast                                        <= 'b0;   
  for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_int_desc_n_txn_type_wr_strb
    int_desc_n_txn_type_wr_strb[i]           <= 'b0;
  end  

end else begin         

  case(wr_state)

  WR_IDLE: begin

    wr_req_avail   <= 'b0;
    //If AW-request and W-request both are available
    if(AW_W_empty==1'b0 && W_empty==1'b0) begin
      wr_state <= WR_NEW_TXN;
      AW_W_rden <= 1'b1;
      W_rden <= 1'b1;
      `IF_INTFS_AXI4_OR_AXI3 
      awlen_sig <= 'b0;
      wlast_cntr <= 'b0;
      `END_INTFS
    
    //If AW-request or W-request is unavailable
    end else begin
      wr_state <= wr_state;
      AW_W_rden <= 1'b0;
      W_rden <= 1'b0;
      `IF_INTFS_AXI4_OR_AXI3 
      wlast_cntr <= 'b0;
      awlen_sig <= 'b0;
      `END_INTFS
    end  

  // New transaction from AW_W_fifo and W_fifo 
  end WR_NEW_TXN: begin
    wr_state <= WR_NEW_WAIT; 
    AW_W_rden <= 1'b0;
    W_rden <= 1'b0;
    `IF_INTFS_AXI4_OR_AXI3 
    wlast_cntr <= 'b0;
    awlen_sig <= 'b0;
    error_wr_wlast <= 'b0;        //as it is one clock-cycle pulse
    `END_INTFS
  
  // Wait for processing of AW and W channel signals for new transaction
  end WR_NEW_WAIT: begin
    
    //update the offsets for wdata in WDATA_RAM/WSTRB_RAM 
    wr_fifo_pop_offset[AW_W_dout]                       <= wr_desc_offset[AW_W_dout]+1;
    //WDATA_RAM/WSTRB_RAM addr 
    uc2rb_wr_addr                                       <= wr_desc_offset[AW_W_dout];
    `IF_INTFS_AXI4 
    int_desc_n_wuser_0_wuser[AW_W_dout]                 <= W_dout[W_FIFO_USER_MSB: W_FIFO_USER_LSB];
    `END_INTFS
    `IF_INTFS_AXI4_OR_AXI3 
    wlast                                               <= W_dout[W_FIFO_LAST]; 
    //Count number of transfers
    wlast_cntr                                          <= wlast_cntr+1;
    //calculate awlen
    awlen_sig                                           <= (((int_desc_n_size_txn_size[AW_W_dout]*8)/DATA_WIDTH)-1);
    `END_INTFS
    //Store descriptor index from AW_W_fifo for further processing of
    //W-channel transfers
    wr_fifo_pop_idx                                     <= AW_W_dout;
    //Compute wstrb control bit
    int_desc_n_txn_type_wr_strb[AW_W_dout]              <= ~(&W_dout[W_FIFO_STRB_MSB : W_FIFO_STRB_LSB]);  // <= ~(&wstrb)
    
    `IF_INTFS_AXI4_OR_AXI3 
    
    if (W_dout[W_FIFO_LAST]==1'b1) begin //wlast==1'b1
      wr_state <= WR_IDLE;
      wr_req_avail[AW_W_dout] <= 1'b1;
      W_rden <= 1'b0;
      //If wlast occurs before expected
      if ( (((int_desc_n_size_txn_size[AW_W_dout]*8)/DATA_WIDTH)-1) != 'b0  ) begin //awlen!=0
        error_wr_wlast[AW_W_dout] <= 1'b1;
      end else begin
        error_wr_wlast[AW_W_dout] <= 1'b0;
      end  
   
   //If wlast is not present in first transfer, process further w-channel
   //transfers 
    end else if (W_dout[W_FIFO_LAST]==1'b0) begin //wlast==1'b0
      if (W_empty==1'b0) begin
        W_rden <= 1'b1;
        //Continue processing further w-channel transfers
        wr_state <= WR_CON_TXN;  
      end else begin
        W_rden <= 1'b0;
        //Wait till next w-channel transfers are available
        wr_state <= WR_WAIT_WDATA;
      end  
      //If wlast was expected(number of transfers is equal to 1) but didn't arrive
      if ( (((int_desc_n_size_txn_size[AW_W_dout]*8)/DATA_WIDTH)-1) == 'b0  ) begin //awlen==0
        error_wr_wlast[AW_W_dout] <= 1'b1;
      end else begin
        error_wr_wlast[AW_W_dout] <= 1'b0;
      end  
    end 
    
    `END_INTFS
    
    `IF_INTFS_AXI4LITE 
    
    //AXI4LITE has always one transfer in a transaction. So, no need to
    //process further for w-channel
    wr_state <= WR_IDLE;
    wr_req_avail[AW_W_dout] <= 1'b1;
    W_rden <= 1'b0;
    
    `END_INTFS
  
  //Continue processing further w-channel transfers
  end WR_CON_TXN: begin
    wr_state <= WR_CON_WAIT; 
    W_rden <= 1'b0;
    `IF_INTFS_AXI4_OR_AXI3 
    wlast_cntr <= wlast_cntr;
    error_wr_wlast <= 'b0;   //as it is one clock-cycle pulse
    `END_INTFS
  
  // Wait for processing of AW and W channel signals for same transaction
  end WR_CON_WAIT: begin

    wr_fifo_pop_offset[wr_fifo_pop_idx]                 <= wr_fifo_pop_offset[wr_fifo_pop_idx]+1;
    uc2rb_wr_addr                                       <= wr_fifo_pop_offset[wr_fifo_pop_idx];
    wr_fifo_pop_idx                                     <= wr_fifo_pop_idx;
    int_desc_n_txn_type_wr_strb[wr_fifo_pop_idx]        <= (int_desc_n_txn_type_wr_strb[wr_fifo_pop_idx]) | (~(&W_dout[WSTRB_WIDTH+DATA_WIDTH-1 : DATA_WIDTH]));  // (int_desc_n_txn_type_wr_strb[wr_fifo_pop_idx]) | (~(&wstrb))
    
    `IF_INTFS_AXI4 
    int_desc_n_wuser_0_wuser[wr_fifo_pop_idx]           <= W_dout[W_FIFO_USER_MSB: W_FIFO_USER_LSB];
    `END_INTFS
    
    `IF_INTFS_AXI4_OR_AXI3 
    wlast                                               <= W_dout[W_FIFO_LAST]; 
    //Count number of transfers
    wlast_cntr                                          <= wlast_cntr+1;
    
    if (W_dout[W_FIFO_LAST]==1'b1) begin //wlast==1'b1
      wr_state <= WR_IDLE;
      wr_req_avail[wr_fifo_pop_idx] <= 1'b1;
      W_rden <= 1'b0;
      //If wlast occurs before expected
      if ( wlast_cntr != awlen_sig  ) begin //wlast_cntr!=awlen
        error_wr_wlast[wr_fifo_pop_idx] <= 1'b1;
      end else begin
        error_wr_wlast[wr_fifo_pop_idx] <= 1'b0;
      end  
    
    end else if (W_dout[W_FIFO_LAST]==1'b0) begin  //wlast==1'b0
      if (W_empty==1'b0) begin
        W_rden <= 1'b1;
        //Continue processing further w-channel transfers
        wr_state <= WR_CON_TXN;
      end else begin
        W_rden <= 1'b0;
        //Wait till next w-channel transfers are available
        wr_state <= WR_WAIT_WDATA;
      end  
      //If wlast was expected(number of transfers is equal to (awlen_sig+1)) but didn't arrive
      if ( wlast_cntr == awlen_sig  ) begin //wlast_cntr==awlen
        error_wr_wlast[wr_fifo_pop_idx] <= 1'b1;
      end else begin
        error_wr_wlast[wr_fifo_pop_idx] <= 1'b0;
      end 
    end 
    `END_INTFS
    
    `IF_INTFS_AXI4LITE 
    wr_state <= WR_IDLE;
    wr_req_avail[wr_fifo_pop_idx] <= 1'b1;
    W_rden <= 1'b0;
    `END_INTFS

  // Wait for processing of W channel signals for same transaction
  end WR_WAIT_WDATA: begin
    if (W_empty==1'b0) begin
      W_rden <= 1'b1;
      wr_state <= WR_CON_TXN;
    end else begin
      wr_state <= WR_WAIT_WDATA;
    end      
    `IF_INTFS_AXI4_OR_AXI3 
    wlast_cntr <= wlast_cntr;
    error_wr_wlast <= 'b0;   //as it is one clock-cycle pulse
    `END_INTFS
  
  end default: begin
    wr_state <= wr_state;
  end
  
  endcase
end
end 

assign uc2rb_wr_bwe = {(DATA_WIDTH/8){1'b1}}; 

//////////////////////
//B-Channel
//////////////////////

//WR_RESP_ORDER_fifo and RD_RESP_ORDER_fifo PUSH logic

assign int_resp_fifo_free_level_level = resp_free_entry;

assign resp_free_entry = ( (RD_RESP_ORDER_fifo_counter+WR_RESP_ORDER_fifo_counter) <= MAX_DESC )  
                         ? ( MAX_DESC-(RD_RESP_ORDER_fifo_counter+WR_RESP_ORDER_fifo_counter) )
                         : ('b0) ;


//Write to fifo only if total entries in both fifos are less than MAX_DESC.
assign resp_valid    = ( (|resp_free_entry)  & sig_resp_order_valid );

assign resp_desc_idx = sig_resp_order_desc_idx;

//Write to WR_RESP_ORDER_fifo only if response order is decided by SW
assign WR_RESP_ORDER_wren = ( (FORCE_RESP_ORDER == 1'b1) && (int_mode_select_imm_bresp==1'b0) ) ? 
                             ( (int_desc_n_txn_type_wr_rd[resp_desc_idx]==1'b0) ? resp_valid : 'b0)
                           : 'b0 ;  
assign WR_RESP_ORDER_din = resp_desc_idx ;

//Write to RD_RESP_ORDER_fifo only if response order is decided by SW
assign RD_RESP_ORDER_wren = (FORCE_RESP_ORDER == 1'b1) ? 
                             ( (int_desc_n_txn_type_wr_rd[resp_desc_idx]==1'b1) ? resp_valid : 'b0)
                           : 'b0 ;  
assign RD_RESP_ORDER_din = resp_desc_idx; 


//WR_RESP_ORDER_fifo instantiation

// WR_RESP_ORDER_fifo stores description index. 
// The fifo can store upto MAX_DESC description indices.

sync_fifo #(
          .WIDTH                                                        (DESC_IDX_WIDTH)
         ,.DEPTH                                                        (MAX_DESC)
) WR_RESP_ORDER_fifo (
          .clk                                                          (axi_aclk)
         ,.rst_n                                                        (axi_aresetn)
         ,.dout                                                         (WR_RESP_ORDER_dout)
         ,.dout_pre                                                     (WR_RESP_ORDER_dout_pre)
         ,.dout_pre_valid                                               (WR_RESP_ORDER_dout_pre_valid)
         ,.full                                                         (WR_RESP_ORDER_full)
         ,.empty                                                        (WR_RESP_ORDER_empty)
         ,.wren                                                         (WR_RESP_ORDER_wren)
         ,.rden                                                         (WR_RESP_ORDER_rden)
         ,.din                                                          (WR_RESP_ORDER_din)
         ,.fifo_counter                                                 (WR_RESP_ORDER_fifo_counter)
);


//AW_fifo or WR_RESP_ORDER_fifo POP logic, BIDX_fifo PUSH logic

//Index is popped from AW_fifo if force_resp_order is '0' or imm_bresp is '1', else index id popped up from WR_RESP_ORDER_fifo.
//The popped up index is pushed into BIDX_fifo

// bresp_init indicates generation of wr-response towards DUT should be initiated.


//Description for AW_fifo logic :
// bresp_init indicates generation of wr-response towards DUT should be initiated.
//
// The data transfers for a sequence of write transactions with the same awid value must complete in the order 
// in which the master issued the addresses.
//
// Each AW_fifo shows the order of descriptors which has same awid. A desc index is popped out
// from AW_fifo if bresp_init of that desc is high. Then, this desc index is pushed into BIDX_fifo.
//
// If multiple descriptors with different awid(meaning, multiple descriptors are stored in different fifos) have bresp_init as high, then lower order 
// descriptor gets priority to be pushed into BIDX_fifo. 

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    bresp_init_ff <= 'h0;
  end else begin
    bresp_init_ff <= bresp_init;
  end
end        		

// bresp_init_order_req is used for ordering. It becomes 'high' when a new bresp_init comes and remains 
// 'high' until corrosponding index is pushed into BIDX_fifo

generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_bresp_init_order_req
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      bresp_init_order_req[gi] <= 1'b0;  
    // bresp_init is served (required index is pushed into BIDX_fifo)
    end else if (bresp_init_order_ser[gi]==1'b1) begin   
      bresp_init_order_req[gi] <= 1'b0;
    //Actual new bresp_init occurs
    end else if (bresp_init[gi]==1'b1 && bresp_init_ff[gi]==1'b0) begin  
      bresp_init_order_req[gi] <= 1'b1;
    end
  end
end
endgenerate

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    WR_RESP_ORDER_rden <= 1'b0;  
    bresp_init_order_ser <= 'b0;
    wr_resp_order_desc_idx <= 'b0;
  end else if (WR_RESP_ORDER_rden==1'b1) begin   
    WR_RESP_ORDER_rden <= 1'b0;
    wr_resp_order_desc_idx <= 'b0;
    bresp_init_order_ser <= 'b0;
  end else if (WR_RESP_ORDER_dout_pre_valid==1'b1 && bresp_init_order_req[WR_RESP_ORDER_dout_pre]==1'b1) begin   
    WR_RESP_ORDER_rden <= 1'b1;
    wr_resp_order_desc_idx <= WR_RESP_ORDER_dout_pre;
    for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_bresp_init_order_ser
      if (i==WR_RESP_ORDER_dout_pre) begin
        bresp_init_order_ser[i] <= 1'b1; 
      end else begin
        bresp_init_order_ser[i] <= 1'b0; 
      end
    end
  end
end


// bresp_init_req becomes 'high' when a new bresp_init comes and remains 
// 'high' until corrosponding index is pushed into BIDX_fifo

generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_bresp_init_req
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      bresp_init_req[gi] <= 1'b0;  
    // bresp_init is served (required index is pushed into BIDX_fifo)
    end else if (bresp_init_ser[gi]==1'b1) begin   
      bresp_init_req[gi] <= 1'b0;
    //Actual new bresp_init occurs
    end else if (bresp_init[gi]==1'b1 && bresp_init_ff[gi]==1'b0) begin  
      bresp_init_req[gi] <= 1'b1;
    end
  end
end
endgenerate

generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_bresp_init_req_proc
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      bresp_init_req_proc[gi] <= 1'b0;  
    // bresp_init is served (required index is pushed into BIDX_fifo)
    end else if (bresp_init_ser[gi]==1'b1) begin   
      bresp_init_req_proc[gi] <= 1'b0;
    //Failed serving bresp_init (required index is not pushed into BIDX_fifo yet)
    end else if (bresp_init_serfailed[gi]==1'b1) begin   
      bresp_init_req_proc[gi] <= 1'b0;
    end else begin
      bresp_init_req_proc[gi] <= bresp_init_req[gi];
    end
  end
end
endgenerate

// If multiple decriptors have bresp_init_req as 'high' , lower most index is
//  selected for process.
 
assign bresp_init_req_proc_onehot = (bresp_init_req_proc)&(-bresp_init_req_proc);      //One-hot vector. Priority to LSB first.


// If read issues to any of AW_fifo, fill BIDX_fifo with index which popped
// from that AW_fifo. 
// NOTE : The implementation is such that at a time only one AW_fifo has AW_rden 
// to be 'high'


always @(posedge axi_aclk) begin
  `IF_INTFS_AXI4_OR_AXI3 
  BIDX_wren <= ( (FORCE_RESP_ORDER==1'b0) || (int_mode_select_imm_bresp==1'b1) ) ?
                           (|AW_rden)
                         : (WR_RESP_ORDER_rden);   
  
  for (i=0; i<=DESC_IDX_WIDTH-1; i=i+1) begin: for_BIDX_din_axi4_or_axi3
    BIDX_din[i]  <= ( (FORCE_RESP_ORDER==1'b0) || (int_mode_select_imm_bresp==1'b1) ) ?
  
                           // If read issues to any of AW_fifo, fill BIDX_fifo with index which popped
                           // from that AW_fifo. 
                           // NOTE : The implementation is such that at a time only one AW_fifo has AW_rden 
                           // to be 'high'
                           (|BIDX_din_sig[i])
  
                           // If read issues to the WR_RESP_ORDER_fifo, fill BIDX_fifo with index which popped
                           // from the WR_RESP_ORDER_fifo. 
                         : wr_resp_order_desc_idx[i];    
   
  end
  `END_INTFS
  
  // If read issues to the AW_fifo, fill BIDX_fifo with index which popped
  // from the AW_fifo. 
  
  `IF_INTFS_AXI4LITE 
  BIDX_wren <= ( (FORCE_RESP_ORDER==1'b0) || (int_mode_select_imm_bresp==1'b1) ) ?
                           (AW_rden[0])
                         : (WR_RESP_ORDER_rden);   
  
  for (i=0; i<=DESC_IDX_WIDTH-1; i=i+1) begin: for_BIDX_din_axi4lite
    BIDX_din[i]  <= ( (FORCE_RESP_ORDER==1'b0) || (int_mode_select_imm_bresp==1'b1) ) ?
  
                           // If read issues to any of AW_fifo, fill BIDX_fifo with index which popped
                           // from that AW_fifo. 
                           // NOTE : The implementation is such that at a time only one AW_fifo has AW_rden 
                           // to be 'high'
                           BIDX_din_sig[i][0]
  
                           // If read issues to the WR_RESP_ORDER_fifo, fill BIDX_fifo with index which popped
                           // from the WR_RESP_ORDER_fifo. 
                         : wr_resp_order_desc_idx[i];    
  end
  `END_INTFS
  
end

always @(posedge axi_aclk) begin
  
  if (axi_aresetn == 1'b0) begin
    bresp_init_ser       <= 'b0;
    AW_rden              <= 'b0;
    //WR_RESP_ORDER_rden   <= 'b0;
    bresp_init_serfailed <= 'b0;
    for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_BIDX_din_array_reset
      BIDX_din_sig[k] <= 'b0;
    end
  end else begin

    //If any of the bresp_init was served
    if (|bresp_init_ser==1'b1) begin      
      bresp_init_ser       <= 'b0;
      AW_rden              <= 'b0;
      //WR_RESP_ORDER_rden   <= 'b0;
      bresp_init_serfailed <= 'b0;
      for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_BIDX_din_array_clear
        BIDX_din_sig[k] <= 'b0;
      end

    end else begin

      // i represents descriptor number
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_bresp_init_req_onehot

        if ( (FORCE_RESP_ORDER==1'b0) || (int_mode_select_imm_bresp==1'b1) ) begin

          `IF_INTFS_AXI4_OR_AXI3 
          //j represents AW_fifo number
          for (j=0; j<=MAX_DESC-1; j=j+1) begin: for_AW_rden
            //If a AW_fifo's last element (dout_pre) is for bresp init 
            if ( (bresp_init_req_proc_onehot[i]==1'b1) && (AW_dout_pre[j]==i) && (AW_empty[j]==1'b0) ) begin
              bresp_init_ser[i]   <= 1'b1;        //bresp_init is served
              AW_rden[j]          <= 1'b1;        //issue read from that fifo
              //k represents bits of description number
              for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_BIDX_din_array_match_axi4_or_axi3
                BIDX_din_sig[k][i] <= AW_dout_pre[j][k];
              end
            //If a descriptor for bresp init is not last element of any AW_fifo
            end else if ( (bresp_init_req_proc_onehot[i]==1'b1) ) begin
              bresp_init_serfailed[i] <= 1'b1;    //bresp_init is failed to serve
            end
          end
          `END_INTFS

          `IF_INTFS_AXI4LITE 
          //If the AW_fifo's last element (dout_pre) is for bresp init 
          if ( (bresp_init_req_proc_onehot[i]==1'b1) && (AW_dout_pre[0]==i) && (AW_empty[0]==1'b0) ) begin
            bresp_init_ser[i]   <= 1'b1;          //bresp_init is served
            AW_rden[0]          <= 1'b1;          //issue read from the fifo
            //k represents bits of description number
            for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_BIDX_din_array_match_axi4lite
              BIDX_din_sig[k][0]        <= AW_dout_pre[0][k];
            end
          //If a descriptor for bresp init is not last element of the AW_fifo
          end else if ( (bresp_init_req_proc_onehot[i]==1'b1) ) begin
            bresp_init_serfailed[i] <= 1'b1;
          end
          `END_INTFS

        end


      end  

    end

  end
end  

//BIDX_fifo instantiation

// BIDX_fifo stores the descriptor indices in such order that bridge
// generates write responses towards DUT.


sync_fifo #(
          .WIDTH		                                        (DESC_IDX_WIDTH) 
         ,.DEPTH		                                        (MAX_DESC)
) BIDX_fifo (
          .dout	                                                        (BIDX_dout)
         ,.full	                                                        (BIDX_full)
         ,.empty	                                                (BIDX_empty)
         ,.clk	                                                        (axi_aclk)
         ,.rst_n	                                                (axi_aresetn)
         ,.wren	                                                        (BIDX_wren)
         ,.rden	                                                        (BIDX_rden)
         ,.din	                                                        (BIDX_din)
);

//BIDX_fifo POP logic, B_fifo PUSH logic

// BIDX_rden is one clock cycle pulse. 
// Whenever BIDX_fifo is non-empty read it.


always @(posedge axi_aclk) begin
  
  if (axi_aresetn == 1'b0) begin
      BIDX_rden         <= 1'b0;
  
  end else begin
    if (BIDX_rden==1'b1) begin  
      BIDX_rden         <= 1'b0;   //because BIDX_rden is one clock cycle pulse.
    //BIDX_fifo is not empty
    end else if (BIDX_empty==1'b0) begin  
      BIDX_rden         <= 1'b1;
    end else begin
      BIDX_rden         <= 1'b0;
    end
  end

end

// The B_wren is one clock cycle pulse.
// Whenever there is read from BIDX_fifo, write into B_fifo.


always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
      B_wren         <= 1'b0;
  end else begin
      B_wren         <= BIDX_rden;
  end
end

generate

// Write all signals of b-channel for descriptor index which was read out from
// BIDX_fifo to B_fifo. B_fifo also stores the descriptor index to its lower
// most bits.


`IF_INTFS_AXI4 


if (BUSER_WIDTH <= AWUSER_WIDTH) begin
assign imm_bresp_mode_buser  = int_desc_n_axuser_0_axuser[BIDX_dout][BUSER_WIDTH-1:0];
end else begin
assign imm_bresp_mode_buser  = {  {(BUSER_WIDTH-AWUSER_WIDTH){1'b0}}  , int_desc_n_axuser_0_axuser[BIDX_dout][AWUSER_WIDTH-1:0]};
end

assign B_din  = (int_mode_select_imm_bresp==1'b0) ?  
                                                     { int_status_resp_resp[(BIDX_dout*2)+1],int_status_resp_resp[BIDX_dout*2]
                                                      ,int_desc_n_xuser_0_xuser[BIDX_dout][BUSER_WIDTH-1:0]
                                                      ,int_desc_n_axid_0_axid[BIDX_dout][ID_WIDTH-1:0]
                                                      ,BIDX_dout}   
                                                  :
                                                     { (int_desc_n_attr_axlock[BIDX_dout][0]==1'b1) ? 2'b01 : 2'b00   //exclusive or normal access
                                                      ,imm_bresp_mode_buser
                                                      ,int_desc_n_axid_0_axid[BIDX_dout][ID_WIDTH-1:0]
                                                      ,BIDX_dout};   
`END_INTFS

`IF_INTFS_AXI4LITE 
assign B_din  = (int_mode_select_imm_bresp==1'b0) ?  
                                                     { int_status_resp_resp[(BIDX_dout*2)+1],int_status_resp_resp[BIDX_dout*2]
                                                      ,BIDX_dout}   
                                                  :
                                                     { 2'b0
                                                      ,BIDX_dout};   
`END_INTFS

`IF_INTFS_AXI3 
assign B_din  = (int_mode_select_imm_bresp==1'b0) ?  
                                                     { int_status_resp_resp[(BIDX_dout*2)+1],int_status_resp_resp[BIDX_dout*2]
                                                      ,int_desc_n_axid_0_axid[BIDX_dout][ID_WIDTH-1:0]
                                                      ,BIDX_dout}   
                                                  :
                                                     { (int_desc_n_attr_axlock[BIDX_dout][1:0]==2'b1) ? 2'b01 : 2'b00   //exclusive or normal access
                                                      ,int_desc_n_axid_0_axid[BIDX_dout][ID_WIDTH-1:0]
                                                      ,BIDX_dout};   
`END_INTFS

endgenerate

//B_fifo instantiation

// B_fifo stores all signals of b-channel in such order that bridge
// generates write responses towards DUT. 
// B_fifo also stores the descriptor index to its lower most bits.


sync_fifo #(
          //Ref:  .WIDTH		                                        (2+BUSER_WIDTH+ID_WIDTH+DESC_IDX_WIDTH)
          .WIDTH		                                        (B_FIFO_WIDTH)  
         ,.DEPTH		                                        (MAX_DESC)
) B_fifo (
          .dout	                                                        (B_dout)
         ,.full	                                                        (B_full)
         ,.empty	                                                (B_empty)
         ,.clk	                                                        (axi_aclk)
         ,.rst_n	                                                (axi_aresetn)
         ,.wren	                                                        (B_wren)
         ,.rden	                                                        (B_rden)
         ,.din	                                                        (B_din)
);

//B-Channel : AXI and control signal (b_idx, bresp_done) generation.

// Signals of b-channel and b_idx are read out values from B_fifo.


assign s_axi_usr_bresp          = B_dout[B_FIFO_RESP_MSB:B_FIFO_RESP_LSB]; 
assign b_idx                    = B_dout[B_FIFO_IDX_MSB:B_FIFO_IDX_LSB];

generate

`IF_INTFS_AXI4 
assign s_axi_usr_buser          = B_dout[B_FIFO_USER_MSB:B_FIFO_USER_LSB];
`END_INTFS

`IF_INTFS_AXI4_OR_AXI3 
assign s_axi_usr_bid            = B_dout[B_FIFO_ID_MSB:B_FIFO_ID_LSB];
`END_INTFS

endgenerate

// bresp_done is one clock cycle pulse.
// It indicates that write response is accepted by DUT.


generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_bresp_done
  always @(posedge axi_aclk) begin
    
    if (axi_aresetn == 1'b0) begin
      bresp_done[gi] <= 1'b0;   
    //If bvalid and bready are 'high'
    end else if (s_axi_usr_bvalid==1'b1 && s_axi_usr_bready==1'b1 && b_idx==gi) begin
      bresp_done[gi] <= 1'b1;
    end else begin
      bresp_done[gi] <= 1'b0;
    end
  
  end
end
endgenerate

// bvalid becomes 'high' when a read issues to B_fifo. It remains
// 'high' till bready is detected as logic 'high' .

 
always @(posedge axi_aclk) begin
  
  if (axi_aresetn == 1'b0) begin
    s_axi_usr_bvalid <= 1'b0;
  //If bvalid and bready are 'high'
  end else if (s_axi_usr_bvalid==1'b1 && s_axi_usr_bready==1'b1) begin
    s_axi_usr_bvalid <= 1'b0;   //bvalid becomes 'low'
  //If read issues to B_fifo
  end else if (B_rden==1'b1) begin
    s_axi_usr_bvalid <= 1'b1;   //bvalid becomes 'high' 
  end else begin
    s_axi_usr_bvalid <= s_axi_usr_bvalid;  //bvalid retains its value
  end

end      

//B_fifo POP logic

// B_rden is one clock cycle pulse.


always @(posedge axi_aclk) begin 
if (axi_aresetn == 1'b0) begin
  wr_resp_state <= WR_RESP_IDLE;
  B_rden        <= 1'b0;
end else begin 
  case(wr_resp_state)

  WR_RESP_IDLE: begin
    //If B_fifo is not empty
    if (B_empty == 1'b0) begin
      wr_resp_state <= WR_RESP_STRT;
      B_rden        <= 1'b1;      //issue read to B_fifo
    //wait till B_fifo gets any element
    end else begin
      wr_resp_state <= WR_RESP_IDLE;
      B_rden        <= 1'b0;
    end

  end WR_RESP_STRT: begin
    wr_resp_state <= WR_RESP_WAIT;  
    B_rden        <= 1'b0;      // B_rden becomes 'low' as it is one clock cycle pulse

  end WR_RESP_WAIT: begin
    
    //If bvalid and bready are 'high'
    if (s_axi_usr_bvalid==1'b1 && s_axi_usr_bready==1'b1) begin
      
      //If B_fifo is not empty
      if (B_empty == 1'b0) begin
        wr_resp_state <= WR_RESP_STRT;
        B_rden        <= 1'b1;  //issue a new read to B_fifo
      //wait till B_fifo gets any element
      end else begin
        wr_resp_state <= WR_RESP_IDLE;
        B_rden        <= 1'b0;
      end
    
    // Wait till bready is detected as 'high'
    end else begin
      wr_resp_state <= WR_RESP_WAIT;
      B_rden        <= 1'b0;
    end


  end default: begin
    wr_resp_state <= wr_resp_state;
    B_rden        <= 1'b0;
  
  end  
  endcase
end
end 


///////////////////////
//AR-Channel
//////////////////////

//AR_fifo PUSH logic

// arready generation if transaction allocation is successful. 
// This signal is always one clock pulse. 


always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
      rd_inf_state         <= RD_INF_IDLE;
      rd_txn_valid         <= 1'b0;
      s_axi_usr_arready    <= 1'b0;
      rd_req_avail         <= 'b0;
      rd_alc_idx_current   <= 'b0;
      AR_fifo_new          <= 'b0 ;
      arid_matched         <= 'b0;
      AR_wren              <= 'b0;
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AR_wren_reset
        AR_din[i]       <= 'b0;
        AR_fifo_arid[i] <= 'b0;
      end
  end else begin 

    case(rd_inf_state)
    RD_INF_IDLE: begin
      //Request for allocation when arvalid and arready is high and there is no pending request
      if (s_axi_usr_arvalid==1'b1 && s_axi_usr_arready==1'b0 && rd_txn_valid==1'b0) begin
        rd_inf_state                              <= RD_INF_WAIT_ALC;
        rd_txn_valid                              <= 1'b1;
        rd_txn_size                               <= (EN_INTFS_AXI3==1'b1) ? {4'b0,s_axi_usr_arlen[3:0]} : (EN_INTFS_AXI4LITE==1'b1) ? 'h0 : s_axi_usr_arlen[7:0];
      end else begin
        rd_inf_state                              <= RD_INF_IDLE;
      end
    
    //Wait till txn allocation is completed  
    end RD_INF_WAIT_ALC: begin
      //If allocation completes
      if (rd_txn_valid==1'b1 && rd_alc_valid==1'b1) begin 
        rd_inf_state                              <= RD_INF_FILL_ARFIFO;
        
        rd_txn_valid                              <= 1'b0;      // de-assert allocation request
        rd_desc_offset[rd_alc_idx]                <= rd_alc_offset;
        rd_alc_idx_current                        <= rd_alc_idx;
        rd_req_avail[rd_alc_idx]                  <= 1'b1;
        s_axi_usr_arready                         <= 1'b1;      //assert arready
        `IF_INTFS_AXI4_OR_AXI3 
        for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_arid_matched
          arid_matched[i]                         <= ( (AR_fifo_valid[i]==1'b1) && (AR_fifo_arid[i]==s_axi_usr_arid) ) ? 1'b1 : 1'b0;
        end
        AR_fifo_new                               <= ((~AR_fifo_valid))&(-(~AR_fifo_valid)) ;   //One-hot vector. Priority to LSB first.
        `END_INTFS
      //Wait until allocation is done
      end else begin
        rd_inf_state                              <= RD_INF_WAIT_ALC;
      end
    
    //PUSH desc-idx to AR_fifo
    end RD_INF_FILL_ARFIFO: begin
      if (s_axi_usr_arvalid==1'b1 && s_axi_usr_arready==1'b1) begin 
        rd_inf_state                              <= RD_INF_TXN_DONE;
        s_axi_usr_arready                         <= 1'b0;
        rd_req_avail[rd_alc_idx_current]          <= 1'b0;
        `IF_INTFS_AXI4_OR_AXI3        
        if ( (|arid_matched)==1'b1 ) begin   //AR_fifo exixtes with matching arid
          for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AR_wren_matched
            if (arid_matched[i]==1'b1) begin
              AR_wren[i] <= 1'b1;                 
              AR_din[i]  <= rd_alc_idx_current;
            end
          end
        end else begin //Add in new AR_fifo
          for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AR_wren_new
            if (AR_fifo_new[i]==1'b1) begin
              AR_wren[i] <= 1'b1;                 
              AR_din[i]  <= rd_alc_idx_current;
              AR_fifo_arid[i]     <= s_axi_usr_arid;
            end
          end
        end  
        `END_INTFS
        `IF_INTFS_AXI4LITE 
        AR_wren[0] <= 1'b1;                 
        AR_din[0]  <= rd_alc_idx_current;
        `END_INTFS
      end else begin
        rd_inf_state                              <= RD_INF_FILL_ARFIFO;
      
      end

    //AR-channel ohandshaking done, make AR_wren signal low
    end RD_INF_TXN_DONE: begin
      rd_inf_state                                <= RD_INF_IDLE;
      `IF_INTFS_AXI4_OR_AXI3        
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_AR_wren_low
        AR_wren[i] <= 1'b0;                 
      end
      `END_INTFS
      `IF_INTFS_AXI4LITE 
      AR_wren[0] <= 1'b0;                 
      `END_INTFS
    end default: begin
      rd_inf_state <= rd_inf_state;

    end
    endcase
  end
end  

// An AR_fifo is valid when it's not empty

generate

`IF_INTFS_AXI4_OR_AXI3        
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_AR_fifo_valid
  assign AR_fifo_valid[gi] = ~AR_empty[gi];
end
`END_INTFS

endgenerate  



//AR_fifo instantiation

generate

`IF_INTFS_AXI4_OR_AXI3 

// MAX_DESC AR_fifo are instantiated. 
// Each AR_fifo has unique arid (AR_fifo_arid).
// AR_fifo stores description index. 
// The fifo can store upto MAX_DESC description indices.
// If the arid does not match with AR_fifo_arid of any fifo, a new fifo is filled and AR_fifo_arid is updated.
// If the arid matches with AR_fifo_arid of any fifo, the desc index of that txn is pushed into same fifo.

for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_AR_fifo
sync_fifo #(
          .WIDTH		                                        (DESC_IDX_WIDTH)
         ,.DEPTH		                                        (MAX_DESC)
) AR_fifo (
          .dout	                                                        (AR_dout[gi])
         ,.dout_pre	                                                (AR_dout_pre[gi])
         ,.full	                                                        (AR_full[gi])
         ,.empty	                                                (AR_empty[gi])
         ,.clk	                                                        (axi_aclk)
         ,.rst_n	                                                (axi_aresetn)
         ,.wren	                                                        (AR_wren[gi])
         ,.rden	                                                        (AR_rden[gi])
         ,.din	                                                        (AR_din[gi])
);
end
`END_INTFS

`IF_INTFS_AXI4LITE 

// One AR_fifo is instantiated as there is no arid in AXI4LITE.
// AR_fifo stores description index. 
// The fifo can store upto MAX_DESC description indices.
// With every new ar request, the desc index of the txn is pushed into fifo.

sync_fifo #(
          .WIDTH		                                        (DESC_IDX_WIDTH)
         ,.DEPTH		                                        (MAX_DESC)
) AR_fifo (
          .dout	                                                        (AR_dout[0])
         ,.dout_pre	                                                (AR_dout_pre[0])
         ,.full	                                                        (AR_full[0])
         ,.empty	                                                (AR_empty[0])
         ,.clk	                                                        (axi_aclk)
         ,.rst_n	                                                (axi_aresetn)
         ,.wren	                                                        (AR_wren[0])
         ,.rden	                                                        (AR_rden[0])
         ,.din	                                                        (AR_din[0])
);
`END_INTFS
endgenerate

//////////////////////
//R-Channel
//////////////////////

//RD_RESP_ORDER_fifo instantiation

// RD_RESP_ORDER_fifo stores description index. 
// The fifo can store upto MAX_DESC description indices.

sync_fifo #(
          .WIDTH                                                        (DESC_IDX_WIDTH)
         ,.DEPTH                                                        (MAX_DESC)
) RD_RESP_ORDER_fifo (
          .clk                                                          (axi_aclk)
         ,.rst_n                                                        (axi_aresetn)
         ,.dout                                                         (RD_RESP_ORDER_dout)
         ,.dout_pre                                                     (RD_RESP_ORDER_dout_pre)
         ,.dout_pre_valid                                               (RD_RESP_ORDER_dout_pre_valid)
         ,.full                                                         (RD_RESP_ORDER_full)
         ,.empty                                                        (RD_RESP_ORDER_empty)
         ,.wren                                                         (RD_RESP_ORDER_wren)
         ,.rden                                                         (RD_RESP_ORDER_rden)
         ,.din                                                          (RD_RESP_ORDER_din)
         ,.fifo_counter                                                 (RD_RESP_ORDER_fifo_counter)
);

//AR_fifo or RD_RESP_ORDER_fifo POP logic, RIDX_fifo PUSH logic

//Index is popped from AR_fifo if force_resp_order is '0' else index id popped up from RD_RESP_ORDER_fifo.
//The popped up index is pushed into RIDX_fifo

// rresp_init indicates generation of rd-response towards DUT should be initiated.


//Description for AR_fifo logic :
// rresp_init indicates generation of rd-response towards DUT should be initiated.
//
// The data transfers for a sequence of read transactions with the same arid value must complete in the order 
// in which the master issued the addresses.
//
// Each AR_fifo shows the order of descriptors which has same arid. A desc index is popped out
// from AR_fifo if rresp_init of that desc is high. Then, this desc index is pushed into BIDX_fifo.
//
// If multiple descriptors with different arid(meaning, multiple descriptors are stored in different fifos) have rresp_init as high, then lower order 
// descriptor gets priority to be pushed into BIDX_fifo. 

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    rresp_init_ff <= 'h0;
  end else begin
    rresp_init_ff <= rresp_init;
  end
end        		

// rresp_init_order_req is used for ordering. It becomes 'high' when a new rresp_init comes and remains 
// 'high' until corrosponding index is pushed into RIDX_fifo

generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_rresp_init_order_req
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      rresp_init_order_req[gi] <= 1'b0;  
    // rresp_init is served (required index is pushed into RIDX_fifo)
    end else if (rresp_init_order_ser[gi]==1'b1) begin   
      rresp_init_order_req[gi] <= 1'b0;
    //Actual new rresp_init occurs
    end else if (rresp_init[gi]==1'b1 && rresp_init_ff[gi]==1'b0) begin  
      rresp_init_order_req[gi] <= 1'b1;
    end
  end
end
endgenerate

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    RD_RESP_ORDER_rden <= 1'b0;  
    rresp_init_order_ser <= 'b0;
    rd_resp_order_desc_idx <= 'b0;
  end else if (RD_RESP_ORDER_rden==1'b1) begin   
    RD_RESP_ORDER_rden <= 1'b0;
    rd_resp_order_desc_idx <= 'b0;
    rresp_init_order_ser <= 'b0;
  end else if (RD_RESP_ORDER_dout_pre_valid==1'b1 && rresp_init_order_req[RD_RESP_ORDER_dout_pre]==1'b1) begin   
    RD_RESP_ORDER_rden <= 1'b1;
    rd_resp_order_desc_idx <= RD_RESP_ORDER_dout_pre;
    for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_rresp_init_order_ser
      if (i==RD_RESP_ORDER_dout_pre) begin
        rresp_init_order_ser[i] <= 1'b1; 
      end else begin
        rresp_init_order_ser[i] <= 1'b0; 
      end
    end
  end
end


// rresp_init_req becomes 'high' when a new rresp_init comes and remains 
// 'high' until corrosponding index is pushed into RIDX_fifo

generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_rresp_init_req
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      rresp_init_req[gi] <= 1'b0;  
    // rresp_init is served (required index is pushed into RIDX_fifo)
    end else if (rresp_init_ser[gi]==1'b1) begin   
      rresp_init_req[gi] <= 1'b0;
    //Actual new rresp_init occurs
    end else if (rresp_init[gi]==1'b1 && rresp_init_ff[gi]==1'b0) begin //Positive edge detection
      rresp_init_req[gi] <= 1'b1;
    end
  end
end
endgenerate

generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_rresp_init_req_proc
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      rresp_init_req_proc[gi] <= 1'b0;  
    // rresp_init is served (required index is pushed into RIDX_fifo)
    end else if (rresp_init_ser[gi]==1'b1) begin   
      rresp_init_req_proc[gi] <= 1'b0;
    //Failed serving rresp_init (required index is not pushed into RIDX_fifo yet)
    end else if (rresp_init_serfailed[gi]==1'b1) begin   
      rresp_init_req_proc[gi] <= 1'b0;
    end else begin
      rresp_init_req_proc[gi] <= rresp_init_req[gi];
    end
  end
end
endgenerate

// If multiple decriptors have rresp_init_req as 'high' , lower most index is
//  selected for process.
 
assign rresp_init_req_onehot = (rresp_init_req_proc)&(-rresp_init_req_proc);      //One-hot vector. Priority to LSB first.


// If read issues to any of AR_fifo, fill RIDX_fifo with index which popped
// from that AR_fifo. 
// NOTE : The implementation is such that at a time only one AR_fifo has AR_rden 
// to be 'high'

always @(posedge axi_aclk) begin
  `IF_INTFS_AXI4_OR_AXI3 
  RIDX_wren <= ( (FORCE_RESP_ORDER==1'b0) ) ?
                           (|AR_rden)
                         : (RD_RESP_ORDER_rden);
  
  for (i=0; i<=DESC_IDX_WIDTH-1; i=i+1) begin: for_RIDX_din_axi4_or_axi3
    RIDX_din[i]  <= ( (FORCE_RESP_ORDER==1'b0) ) ?
  
                           // If read issues to any of AR_fifo, fill RIDX_fifo with index which popped
                           // from that AR_fifo. 
                           // NOTE : The implementation is such that at a time only one AR_fifo has AR_rden 
                           // to be 'high'
                           (|RIDX_din_sig[i])
  
                           // If read issues to the RD_RESP_ORDER_fifo, fill RIDX_fifo with index which popped
                           // from the RD_RESP_ORDER_fifo. 
                         : rd_resp_order_desc_idx[i];
    
  end
  `END_INTFS
  
  // If read issues to the AR_fifo, fill RIDX_fifo with index which popped
  // from the AR_fifo. 
  
  `IF_INTFS_AXI4LITE 
  RIDX_wren <= ( (FORCE_RESP_ORDER==1'b0) ) ?
                           (AR_rden[0])
                         : (RD_RESP_ORDER_rden);
  
  for (i=0; i<=DESC_IDX_WIDTH-1; i=i+1) begin: for_RIDX_din_axi4lite
    RIDX_din[i] <= ( (FORCE_RESP_ORDER==1'b0) ) ?
                           (RIDX_din_sig[i][0])
                         : (rd_resp_order_desc_idx[i]);
  end
  `END_INTFS
end

always @(posedge axi_aclk) begin
  
  if (axi_aresetn == 1'b0) begin
    rresp_init_ser   <= 'b0;
    AR_rden          <= 'b0;
    //RD_RESP_ORDER_rden   <= 'b0;
    rresp_init_serfailed <= 'b0;
    for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_RIDX_din_array_reset
      RIDX_din_sig[k] <= 'b0;
    end
  end else begin
  
    //If any of the rresp_init was served
    if (|rresp_init_ser==1'b1) begin     
      rresp_init_ser   <= 'b0;
      AR_rden          <= 'b0;
      //RD_RESP_ORDER_rden   <= 'b0;
      rresp_init_serfailed <= 'b0;
      for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_RIDX_din_array_clear
        RIDX_din_sig[k] <= 'b0;
      end
    
    end else begin
    
      // i represents descriptor number
      for (i=0; i<=MAX_DESC-1; i=i+1) begin: for_rresp_init_req_onehot

        if ( (FORCE_RESP_ORDER==1'b0) ) begin

          `IF_INTFS_AXI4_OR_AXI3 
          //j represents AW_fifo number
          for (j=0; j<=MAX_DESC-1; j=j+1) begin: for_AR_rden
            //If a AR_fifo's last element (dout_pre) is for rresp init 
            if ( (rresp_init_req_onehot[i]==1'b1) && (AR_dout_pre[j]==i) && (AR_empty[j]==1'b0) ) begin
              rresp_init_ser[i]   <= 1'b1;  //rresp_init is served
              AR_rden[j]          <= 1'b1;  //issue read from that fifo
              //k represents bits of description number
              for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_RIDX_din_array_match_axi4_or_axi3
                RIDX_din_sig[k][i] <= AR_dout_pre[j][k];
              end
            //If a descriptor for rresp init is not last element of any AR_fifo
            end else if ( (rresp_init_req_onehot[i]==1'b1) ) begin
              rresp_init_serfailed[i] <= 1'b1;  //rresp_init is failed to serve
            end
          end
          `END_INTFS

          `IF_INTFS_AXI4LITE 
          //If the AR_fifo's last element (dout_pre) is for rresp init 
          if ( (rresp_init_req_onehot[i]==1'b1) && (AR_dout_pre[0]==i) && (AR_empty==1'b0) ) begin
            rresp_init_ser[i]   <= 1'b1;  //rresp_init is served
            AR_rden[0]          <= 1'b1;  //issue read from the fifo
            //k represents bits of description number
            for (k=0; k<=DESC_IDX_WIDTH-1; k=k+1) begin: for_RIDX_din_array_match_axi4lite
              RIDX_din_sig[k][0]        <= AR_dout_pre[0][k];
            end
          //If a descriptor for rresp init is not last element of the AR_fifo
          end else if ( (rresp_init_req_onehot[i]==1'b1) ) begin
            rresp_init_serfailed[i] <= 1'b1;
          end
          `END_INTFS

        end
      end  

    end

  end
end  



//RIDX_fifo instantiation

// RIDX_fifo stores the descriptor indices in such order that bridge
// generates read responses towards DUT.

sync_fifo #(
          .WIDTH		                                        (DESC_IDX_WIDTH) 
         ,.DEPTH		                                        (MAX_DESC)
) RIDX_fifo (
          .dout	                                                        (RIDX_dout)
         ,.full	                                                        (RIDX_full)
         ,.empty	                                                (RIDX_empty)
         ,.clk	                                                        (axi_aclk)
         ,.rst_n	                                                (axi_aresetn)
         ,.wren	                                                        (RIDX_wren)
         ,.rden	                                                        (RIDX_rden)
         ,.din	                                                        (RIDX_din)
);

//RIDX_fifo POP logic, R_fifo PUSH logic


//R_wren is 3 clock cycle delayed value of uc2rb_rd_valid
//R_din is 3 clock cycle delayed value of r_din (except data of r-channel, that is not delayed )


assign R_din[DATA_WIDTH+DESC_IDX_WIDTH-1:DESC_IDX_WIDTH] = rb2uc_rd_data;

synchronizer#(
         .SYNC_FF                                                       (3)  
        ,.D_WIDTH                                                       (1)
) sync_uc2rb_rd_valid (
         .data_in                                                       (uc2rb_rd_valid) 
         ,.ck                                                           (axi_aclk) 
         ,.rn                                                           (axi_aresetn) 
         ,.q_out                                                        (R_wren)
);   

synchronizer#(
         .SYNC_FF                                                       (3)  
        ,.D_WIDTH                                                       (SYNC_R_DIN_MISC_D_WIDTH)
) sync_r_din_misc (
          .ck                                                           (axi_aclk) 
         ,.rn                                                           (axi_aresetn) 
         ,.data_in                                                      (r_din[R_FIFO_WIDTH-1 : R_FIFO_DATA_MSB+1])
         ,.q_out                                                        (R_din[R_FIFO_WIDTH-1 : R_FIFO_DATA_MSB+1])
);   

synchronizer#(
         .SYNC_FF                                                       (3)  
        ,.D_WIDTH                                                       (DESC_IDX_WIDTH)
) sync_r_din_idx (
         .data_in                                                       (r_din[R_FIFO_IDX_MSB:R_FIFO_IDX_LSB]) 
         ,.ck                                                           (axi_aclk) 
         ,.rn                                                           (axi_aresetn) 
         ,.q_out                                                        (R_din[R_FIFO_IDX_MSB:R_FIFO_IDX_LSB])
);

// RIDX_rden is one clock cycle pulse. 

// Below state machine pops one descriptor index from RIDX_fifo and read all
// data from RDATA_RAM for that descriptor and stores into R_fifo. Then, it
// returns to idle state again.

always @(posedge axi_aclk) begin
if (axi_aresetn == 1'b0) begin
    rd_data_state     <= RD_DATA_IDLE;
    RIDX_rden         <= 1'b0;
    uc2rb_rd_valid    <= 1'b0;
    uc2rb_rd_addr     <= 'b0;
    r_din             <= 'b0;

end else begin
  case(rd_data_state)
  
  RD_DATA_IDLE: begin
    r_din               <= 'b0;
    //If RIDX_fifo is non-empty
    if (RIDX_empty==1'b0) begin   
      rd_data_state     <= RD_DATA_NEW;
      RIDX_rden         <= 1'b1;
      uc2rb_rd_valid    <= 1'b0;
      uc2rb_rd_addr     <= 'b0;
    //Wait till RIDX_fifo gets any element
    end else begin
      rd_data_state     <= RD_DATA_IDLE;
      RIDX_rden         <= 1'b0;
      uc2rb_rd_valid    <= 1'b0;
      uc2rb_rd_addr     <= 'b0;
    end  
  
  end RD_DATA_NEW: begin
    //If R_fifo is not almost full 
    if (R_almost_full==1'b0) begin
      rd_data_state     <= RD_DATA_NEW_RDRAM;
      RIDX_rden         <= 1'b0;
      uc2rb_rd_valid    <= 1'b0;
      uc2rb_rd_addr     <= 'b0;
    end else begin
      rd_data_state     <= RD_DATA_NEW;
      RIDX_rden         <= 1'b0;
      uc2rb_rd_valid    <= 1'b0;
      uc2rb_rd_addr     <= 'b0;
    end
  
  //Read data of new descriptor's first transfer from internal RDATA_RAM
  end RD_DATA_NEW_RDRAM: begin
    uc2rb_rd_valid    <= 1'b1;
    uc2rb_rd_addr     <= (int_desc_n_data_offset_addr[RIDX_dout]*8/DATA_WIDTH);
    rd_offset         <= (int_desc_n_data_offset_addr[RIDX_dout]*8/DATA_WIDTH)+1;  //Next uc2rb_rd_addr of same descriptor
    rdata_count       <= 'b0;   //initialize transfer count of a descriptor
    arlen             <= (int_desc_n_size_txn_size[RIDX_dout]*8/DATA_WIDTH)-1;
    rd_idx            <= RIDX_dout;
    r_din[R_FIFO_IDX_MSB:R_FIFO_IDX_LSB] <= RIDX_dout;  //r_idx <= 
    
    `IF_INTFS_AXI4 
    r_din[R_FIFO_WIDTH-1 : R_FIFO_DATA_MSB+1] <= {
                                                ((int_desc_n_size_txn_size[RIDX_dout]*8/DATA_WIDTH)-1 == 1'b0) //rlast <= (arlen==1'b0);
                                               ,int_status_resp_resp[(RIDX_dout*2)+1],int_status_resp_resp[RIDX_dout*2]  //rresp      
                                               ,int_desc_n_xuser_0_xuser[RIDX_dout][RUSER_WIDTH-1:0] //ruser          
                                               ,int_desc_n_axid_0_axid[RIDX_dout][ID_WIDTH-1:0] };  //rid   
    `END_INTFS
    `IF_INTFS_AXI4LITE 
    r_din[R_FIFO_WIDTH-1 : R_FIFO_DATA_MSB+1] <= {
                                                int_status_resp_resp[(RIDX_dout*2)+1],int_status_resp_resp[RIDX_dout*2] };  //rresp      
    `END_INTFS
    `IF_INTFS_AXI3 
    r_din[R_FIFO_WIDTH-1 : R_FIFO_DATA_MSB+1] <= {
                                                ((int_desc_n_size_txn_size[RIDX_dout]*8/DATA_WIDTH)-1 == 1'b0) //rlast <= (arlen==1'b0);
                                               ,int_status_resp_resp[(RIDX_dout*2)+1],int_status_resp_resp[RIDX_dout*2]  //rresp      
                                               ,int_desc_n_axid_0_axid[RIDX_dout][ID_WIDTH-1:0] };  //rid   
    `END_INTFS

    `IF_INTFS_AXI4_OR_AXI3 
    //If arlen is 0, no need to read further from RDATA_RAM 
    if ((int_desc_n_size_txn_size[RIDX_dout]*8/DATA_WIDTH)-1=='b0) begin //arlen=='b0
      rd_data_state <= RD_DATA_IDLE;
      RIDX_rden <= 1'b0;
    //If R_fifo is not almost full 
    end else if (R_almost_full==1'b0) begin  
      rd_data_state <= RD_DATA_CON_RDRAM;
      RIDX_rden <= 1'b0;
    end else begin
      rd_data_state <= RD_DATA_CON_WAIT;
      RIDX_rden <= 1'b0;
    end
    `END_INTFS

    `IF_INTFS_AXI4LITE
    //AXI4LITE transaction always has single beat, so no need to read further
    //from RDATA_RAM 
    rd_data_state <= RD_DATA_IDLE;
    RIDX_rden <= 1'b0;
    `END_INTFS

  end RD_DATA_CON_RDRAM: begin
    uc2rb_rd_valid    <= 1'b1;
    uc2rb_rd_addr     <= rd_offset;
    rd_offset         <= rd_offset+1;    
    rdata_count       <= rdata_count+1'b1;  //Calculate transfer count of a descriptor
    r_din[DESC_IDX_WIDTH-1:0] <= rd_idx;  //r_idx 

    `IF_INTFS_AXI4 
    r_din[R_FIFO_WIDTH-1 : R_FIFO_DATA_MSB+1] <= {
                                                (rdata_count == (arlen-1)) //rlast 
                                               ,int_status_resp_resp[(rd_idx*2)+1],int_status_resp_resp[rd_idx*2]  //rresp      
                                               ,int_desc_n_xuser_0_xuser[rd_idx][RUSER_WIDTH-1:0] //ruser          
                                               ,int_desc_n_axid_0_axid[rd_idx][ID_WIDTH-1:0] };  //rid   
    `END_INTFS
    `IF_INTFS_AXI4LITE 
    r_din[R_FIFO_WIDTH-1 : R_FIFO_DATA_MSB+1] <= {
                                                int_status_resp_resp[(rd_idx*2)+1],int_status_resp_resp[rd_idx*2] };  //rresp      
    `END_INTFS
    `IF_INTFS_AXI3 
    r_din[R_FIFO_WIDTH-1 : R_FIFO_DATA_MSB+1] <= {
                                                (rdata_count == (arlen-1)) //rlast 
                                               ,int_status_resp_resp[(rd_idx*2)+1],int_status_resp_resp[rd_idx*2]  //rresp      
                                               ,int_desc_n_axid_0_axid[rd_idx][ID_WIDTH-1:0] };  //rid   
    `END_INTFS

    if (rdata_count == (arlen-1)) begin //rlast reached 
      rd_data_state <= RD_DATA_IDLE;
    end else if (R_almost_full==1'b0) begin  
      rd_data_state <= RD_DATA_CON_RDRAM;
    end else begin
      rd_data_state <= RD_DATA_CON_WAIT;
    end
    RIDX_rden <= 1'b0;
  
  end RD_DATA_CON_WAIT: begin
    //If R_fifo is not almost full 
    if (R_almost_full==1'b0) begin  
      rd_data_state <= RD_DATA_CON_RDRAM;
    end else begin
      rd_data_state <= RD_DATA_CON_WAIT;
    end
    RIDX_rden         <= 1'b0;
    uc2rb_rd_valid    <= 1'b0;
    uc2rb_rd_addr     <= uc2rb_rd_addr;
  
  end default: begin
    rd_data_state     <= rd_data_state;
    RIDX_rden         <= 1'b0;
    uc2rb_rd_valid    <= 1'b0;
    uc2rb_rd_addr     <= 'b0;
  end
  
  endcase
end
end
  
//R_fifo instantiation

// R_fifo holds rdata along with all r-channel sideband signals. 

sync_fifo #(
          //Ref:  .WIDTH		                                        (1+2+RUSER_WIDTH+ID_WIDTH+DATA_WIDTH+DESC_IDX_WIDTH)
          .WIDTH		                                        (R_FIFO_WIDTH)  
         ,.DEPTH		                                        (32)        //Any random number
         ,.ALMOST_FULL_DEPTH		                                (32-5)      //DEPTH-5
         ,.ALMOST_EMPTY_DEPTH		                                (2)         //Not used
) R_fifo (
          .dout	                                                        (R_dout)
         ,.full	                                                        (R_full)
         ,.empty	                                                (R_empty)
         ,.almost_full	                                                (R_almost_full)
         ,.almost_empty	                                                (R_almost_empty)
         ,.clk	                                                        (axi_aclk)
         ,.rst_n	                                                (axi_aresetn)
         ,.wren	                                                        (R_wren)
         ,.rden	                                                        (R_rden)
         ,.din	                                                        (R_din)
);

//R-Channel : AXI and control signal (r_idx, rresp_done) generation.

// Signals of r-channel and r_idx are read out values from R_fifo.

assign s_axi_usr_rresp = R_dout[R_FIFO_RESP_MSB:R_FIFO_RESP_LSB];      	
assign s_axi_usr_rdata = R_dout[R_FIFO_DATA_MSB:R_FIFO_DATA_LSB];                                                           	
assign r_idx           = R_dout[R_FIFO_IDX_MSB:R_FIFO_IDX_LSB];                    	

generate

`IF_INTFS_AXI4_OR_AXI3
assign s_axi_usr_rlast = R_dout[R_FIFO_LAST];                                                      	
assign s_axi_usr_rid   = R_dout[R_FIFO_ID_MSB:R_FIFO_ID_LSB];                                       	
`END_INTFS

`IF_INTFS_AXI4 
assign s_axi_usr_ruser = R_dout[R_FIFO_USER_MSB:R_FIFO_USER_LSB];                   	
`END_INTFS

endgenerate


// rresp_done is one clock cycle pulse.
// It indicates that read response is accepted by DUT.

generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_rresp_done
  
  `IF_INTFS_AXI4_OR_AXI3 
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      rresp_done[gi] <= 1'b0;
    //If rvalid and rready and rlast are 'high'
    end else if (s_axi_usr_rvalid==1'b1 && s_axi_usr_rready==1'b1 && s_axi_usr_rlast==1'b1 && r_idx==gi) begin
      rresp_done[gi] <= 1'b1;
    end else begin
      rresp_done[gi] <= 1'b0;
    end
  end
  `END_INTFS
  
  `IF_INTFS_AXI4LITE 
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      rresp_done[gi] <= 1'b0;
    //If rvalid and rready are 'high'
    end else if (s_axi_usr_rvalid==1'b1 && s_axi_usr_rready==1'b1 && r_idx==gi) begin
      rresp_done[gi] <= 1'b1;
    end else begin
      rresp_done[gi] <= 1'b0;
    end
  end
  `END_INTFS

end
endgenerate

// rvalid becomes 'high' when a read issues to R_fifo. It remains
// 'high' till rready is detected as logic 'high' .

always @(posedge axi_aclk) begin
  
  if (axi_aresetn == 1'b0) begin
    s_axi_usr_rvalid <= 1'b0;
  //If rvalid and rready are 'high'
  end else if (s_axi_usr_rvalid==1'b1 && s_axi_usr_rready==1'b1) begin
    s_axi_usr_rvalid <= 1'b0;  //rvalid becomes 'low'
  //If read issues to R_fifo
  end else if (R_rden==1'b1) begin
    s_axi_usr_rvalid <= 1'b1;  //bvalid becomes 'high'
  end else begin
    s_axi_usr_rvalid <= s_axi_usr_rvalid;  //rvalid retains its value
  end

end      

//R_fifo POP logic

// R_rden is one clock cycle pulse.


always @(posedge axi_aclk) begin 
if (axi_aresetn == 1'b0) begin
  rd_resp_state <= RD_RESP_IDLE;
  R_rden        <= 1'b0;
end else begin 
  case(rd_resp_state)

  RD_RESP_IDLE: begin
    //If R_fifo is not empty
    if (R_empty == 1'b0) begin
      rd_resp_state <= RD_RESP_STRT;
      R_rden        <= 1'b1;    //issue read to R_fifo
    //Wait till R_fifo gets any element
    end else begin
      rd_resp_state <= RD_RESP_IDLE;
      R_rden        <= 1'b0;    //R_rden becomes 'low' as it is one clock cycle pulse
    end
  
  end RD_RESP_STRT: begin
    rd_resp_state <= RD_RESP_WAIT;  
    R_rden        <= 1'b0;  // R_rden becomes 'low' as it is one clock cycle pulse
  
  end RD_RESP_WAIT: begin

    //If rvalid and rready are 'high'
    if (s_axi_usr_rvalid==1'b1 && s_axi_usr_rready==1'b1) begin
  
      //If R_fifo is not empty
      if (R_empty == 1'b0) begin
        rd_resp_state <= RD_RESP_STRT;
        R_rden        <= 1'b1;  //issue a new read to R_fifo
      //wait till R_fifo gets any element
      end else begin
        rd_resp_state <= RD_RESP_IDLE;
        R_rden        <= 1'b0;
      end
  
    // Wait till rready is detected as 'high'
    end else begin
      rd_resp_state <= RD_RESP_WAIT;
      R_rden        <= 1'b0;
    end
  
  end default: begin
    rd_resp_state <= rd_resp_state;
    R_rden        <= 1'b0;
  
  end  
  endcase
end
end 

//////////////////////
//Signal :
//  req_avail
//Description :
//  This signal indicates write(AW and W)/read(AR) transaction request availability from DUT.
//////////////////////

//Update req_avail based on write or read 
generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_req_avail
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      req_avail[gi] <= 1'b0;
    end else begin
      if (int_desc_n_txn_type_wr_rd[gi]==1'b0) begin
        req_avail[gi] <= wr_req_avail[gi];
      end else begin
        req_avail[gi] <= rd_req_avail[gi];
      end   
    end
  end
end
endgenerate

//////////////////////
//Signal :
//  txn_avail
//Description :
//  Transaction availablity indication from bridge to SW.
//////////////////////

assign wr_txn_avail = (int_mode_select_mode_0_1==1'b0) ? 
                           ((int_mode_select_imm_bresp==1'b0) ? wr_req_avail : bresp_done)              //Mode-0
                         : 
                           ((int_mode_select_imm_bresp==1'b0) ? hm2uc_done_pulse : hm2uc_bresp_done);   //Mode-1


assign rd_txn_avail = rd_req_avail;   
                      

//Update txn_avail based on write or read 
generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_txn_avail
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      txn_avail[gi] <= 1'b0;
    end else begin
      if (int_desc_n_txn_type_wr_rd[gi]==1'b0) begin
        txn_avail[gi] <= wr_txn_avail[gi];
      end else begin
        txn_avail[gi] <= rd_txn_avail[gi];
      end   
    end
  end
end
endgenerate

//////////////////////
//Signal :
//  rresp_init
//Description :
//  This signal initiates rresp generation towards DUT.
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    int_ownership_own_ff <= 'h0;
  end else begin
    int_ownership_own_ff <= int_ownership_own;
  end
end


//Update rresp_init in case of read
generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_rresp_init
  always @(posedge axi_aclk) begin
    
    if (axi_aresetn == 1'b0) begin
      rresp_init[gi] <= 1'b0;
    
    end else begin   
      
      //If mode-0
      if (int_mode_select_mode_0_1==1'b0) begin  
       
        //In case of read, when transaction is in progress, wait for ownership from Host 
        if (int_desc_n_txn_type_wr_rd[gi]==1'b1 && int_ownership_own[gi]==1'b1 && int_ownership_own_ff[gi]==1'b0 && int_status_busy_busy[gi]==1'b1) begin
          rresp_init[gi] <= 1'b1;      
        end else begin
          rresp_init[gi] <= 1'b0;      
        end

      //If mode-1
      end else begin   
       
        //Initiate rd-response as soon as HM has fetched rdata from host buffer to RDATA_RAM
        if (int_desc_n_txn_type_wr_rd[gi]==1'b1 && hm2uc_done_pulse[gi]==1'b1 ) begin  
          rresp_init[gi] <= 1'b1;      
        end else begin
          rresp_init[gi] <= 1'b0;      
        end

      end

    end

  end
end
endgenerate


//////////////////////
//Signal :
//  bresp_init
//Description :
//  This signal initiates bresp generation towards DUT.
//////////////////////

//Update bresp_init in case of write
generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_bresp_init
  always @(posedge axi_aclk) begin
    
    if (axi_aresetn == 1'b0) begin
      bresp_init[gi] <= 1'b0;
    
    end else begin
         
      if (int_mode_select_imm_bresp==1'b0) begin  
        //In case of write, when transaction is in progress, wait for ownership from Host 
        if (int_desc_n_txn_type_wr_rd[gi]==1'b0 && int_ownership_own[gi]==1'b1 && int_ownership_own_ff[gi]==1'b0 && int_status_busy_busy[gi]==1'b1) begin 
          bresp_init[gi] <= 1'b1;      
        end else begin
          bresp_init[gi] <= 1'b0;      
        end
      //In case of imm_bresp mode, initiate wr-response as soon as write request is available
      end else begin
          bresp_init[gi] <= wr_req_avail[gi];
      end

    end
  end
end
endgenerate


//////////////////////
//Signal :
//  uc2hm_trig
//Description :
//  Trigger HM to send/fetch data to/from SW based on write/read transaction
//  correspondingly.
//////////////////////

//int_mode_select_imm_bresp
//0 : Wait for response from Host.
//1 : Generate immediate BRESP to DUT

//Update uc2hm_trig based on write or read 
generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_uc2hm_trig
  always @(posedge axi_aclk) begin
    
    if (axi_aresetn == 1'b0) begin
      uc2hm_trig[gi] <= 1'b0;
    
    //If mode-1
    end else if (int_mode_select_mode_0_1==1'b1)begin 
      
      //In case of write
      if (int_desc_n_txn_type_wr_rd[gi]==1'b0) begin 
        uc2hm_trig[gi] <= wr_req_avail[gi];
      //In case of read, when transaction is in progress, wait for ownership from Host 
      end else if (int_desc_n_txn_type_wr_rd[gi]==1'b1 && int_ownership_own[gi]==1'b1 && int_ownership_own_ff[gi]==1'b0 && int_status_busy_busy[gi]==1'b1) begin  
        uc2hm_trig[gi] <= 1'b1; 
      end else begin 
        uc2hm_trig[gi] <= 1'b0; 
      end   

    end
  
  end
end
endgenerate

//////////////////////
//Signal :
//  hm2uc_done_pulse
//Description: 
//  Detect positive edge of hm2uc_done and generate 1-cycle pusle as hm2uc_done_pulse
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    hm2uc_done_ff <= 'h0;
  end else begin
    hm2uc_done_ff <= hm2uc_done;
  end
end
generate        		
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_hm2uc_done_pulse
always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    hm2uc_done_pulse[gi] <= 1'b0;  
  end else if (hm2uc_done[gi]==1'b1 && hm2uc_done_ff[gi]==1'b0) begin //Positive edge detection
    hm2uc_done_pulse[gi] <= 1'b1;
  end else begin
    hm2uc_done_pulse[gi] <= 1'b0;
  end
end
end
endgenerate

//////////////////////
//Signal :
//  hm2uc_bresp_done
//Description :
//  This signal holds true if imm_bresp=1.
//  This signal indicates when bresp is generated towards DUT and HM has
//  transferred wdata to SW. 
//////////////////////

generate        		
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_wr_done_state
always @(posedge axi_aclk) begin 
if (axi_aresetn == 1'b0) begin
  wr_done_state[gi] <= WR_IDLE_DONE;
end else begin 
  case(wr_done_state[gi])
  WR_IDLE_DONE: begin
   case({bresp_done[gi],hm2uc_done_pulse[gi]}) 
   2'b00: begin
     wr_done_state[gi]<= WR_IDLE_DONE;
   end 2'b01: begin
     wr_done_state[gi]<= WR_HM2UC_DONE;
   end 2'b10: begin
     wr_done_state[gi]<= WR_BRESP_DONE;
   end 2'b11: begin
     wr_done_state[gi]<= WR_HM2UC_BRESP_DONE;
   end
   endcase 
  end WR_HM2UC_DONE: begin
    if (bresp_done[gi]==1'b1) begin 
      wr_done_state[gi]<= WR_HM2UC_BRESP_DONE;
    end else begin
      wr_done_state[gi]<= wr_done_state[gi];
    end
  end WR_BRESP_DONE: begin
    if (hm2uc_done_pulse[gi]==1'b1) begin 
      wr_done_state[gi]<= WR_HM2UC_BRESP_DONE;
    end else begin
      wr_done_state[gi]<= wr_done_state[gi];
    end
  end WR_HM2UC_BRESP_DONE: begin
    wr_done_state[gi]<= WR_IDLE_DONE;
  end default: begin
    wr_done_state[gi]<= wr_done_state[gi];
  end
  endcase
end
end 
end
endgenerate

generate        		
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_hm2uc_bresp_done
  assign hm2uc_bresp_done[gi] = (wr_done_state[gi] ==  WR_HM2UC_BRESP_DONE);
end
endgenerate


///////////////////////
//Signal :
//  int_intr_txn_avail_status_avail
//Description:
//  Update int_intr_txn_avail_status_avail based on txn_avail(from bridge) or int_intr_txn_avail_clear_clr_avail(from sw)
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    int_intr_txn_avail_clear_clr_avail_ff <= 'h0;
  end else begin
    int_intr_txn_avail_clear_clr_avail_ff <= int_intr_txn_avail_clear_clr_avail;
  end
end        		
always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    txn_avail_ff <= 'h0;
  end else begin
    txn_avail_ff <= txn_avail;
  end
end
generate        		
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_int_intr_txn_avail_status_avail
always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    int_intr_txn_avail_status_avail[gi] <= 1'b0;  
  end else if (txn_avail[gi]==1'b1 && txn_avail_ff[gi]==1'b0) begin //Positive edge detection
    int_intr_txn_avail_status_avail[gi] <= 1'b1;
  end else if (int_intr_txn_avail_clear_clr_avail[gi]==1'b1 && int_intr_txn_avail_clear_clr_avail_ff[gi]==1'b0) begin //Positive edge detection
    int_intr_txn_avail_status_avail[gi] <= 1'b0;
  end
end
end
endgenerate

///////////////////////
//Signal :
//  int_intr_comp_status_comp
//Description:
//  Update int_intr_comp_status_comp based on comp(from bridge) or int_intr_comp_clear_clr_comp(from sw)
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    int_intr_comp_clear_clr_comp_ff <= 'h0;
  end else begin
    int_intr_comp_clear_clr_comp_ff <= int_intr_comp_clear_clr_comp;
  end
end        		
always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    comp_ff <= 'h0;
  end else begin
    comp_ff <= comp;
  end
end
generate        		
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_int_intr_comp_status_comp
always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    int_intr_comp_status_comp[gi] <= 1'b0;  
  end else if (comp[gi]==1'b1 && comp_ff[gi]==1'b0) begin //Positive edge detection
    int_intr_comp_status_comp[gi] <= 1'b1;
  end else if (int_intr_comp_clear_clr_comp[gi]==1'b1 && int_intr_comp_clear_clr_comp_ff[gi]==1'b0) begin //Positive edge detection
    int_intr_comp_status_comp[gi] <= 1'b0;
  end
end
end
endgenerate

//////////////////////
//Signal :
//  bresp_ana_done
//Description : 
//  bresp-analysis done in case of imm_bresp=1'b1
//////////////////////

generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_bresp_ana_done
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      bresp_ana_done[gi] <= 1'b0;
    end else begin     
      if (int_mode_select_imm_bresp==1'b1) begin  //Generate immediate BRESP to DUT
        if (int_desc_n_txn_type_wr_rd[gi]==1'b0 && int_ownership_own[gi]==1'b1 && int_ownership_own_ff[gi]==1'b0 && int_status_busy_busy[gi]==1'b1) begin  //Positive edge detection  //in case of write
          bresp_ana_done[gi] <= 1'b1;
          `IF_INTFS_AXI4 
          error_wr_buser[gi] <= (int_desc_n_xuser_0_xuser[gi] != int_desc_n_axuser_0_axuser[gi]);
          error_wr_bresp[gi] <=     ( (int_desc_n_attr_axlock[gi][0]==1'b1) && (int_status_resp_resp[(gi*2)+1:gi*2] != 2'b1) )   //exclusive request
                                 || ( (int_desc_n_attr_axlock[gi][0]==1'b0) && (int_status_resp_resp[(gi*2)+1:gi*2] != 2'b0) ) ; //normal request
          `END_INTFS
          `IF_INTFS_AXI4LITE
          error_wr_bresp[gi] <=  (int_status_resp_resp[(gi*2)+1:gi*2] != 2'b0) ; 
          `END_INTFS
          `IF_INTFS_AXI3
          error_wr_bresp[gi] <=     ( (int_desc_n_attr_axlock[gi][1:0]==2'b1) && (int_status_resp_resp[(gi*2)+1:gi*2] != 2'b1) )   //exclusive request
                                 || ( (int_desc_n_attr_axlock[gi][1:0]==2'b0) && (int_status_resp_resp[(gi*2)+1:gi*2] != 2'b0) ) ; //normal request
          `END_INTFS
        end else begin
          `IF_INTFS_AXI4 
          error_wr_buser[gi] <= 1'b0;
          `END_INTFS
          bresp_ana_done[gi] <= 1'b0;
          error_wr_bresp[gi] <= 1'b0;
        end
      end else begin
        `IF_INTFS_AXI4 
        error_wr_buser[gi] <= 1'b0;
        `END_INTFS
        bresp_ana_done[gi] <= 1'b0;
        error_wr_bresp[gi] <= 1'b0;
      end
    end
  end 
end
endgenerate
        

//////////////////////
//Signal :
//  txn_cmpl
//  comp
//Description :
//  Transaction completion indication from bridge to SW.
//////////////////////

assign wr_txn_cmpl = ((int_mode_select_imm_bresp==1'b0) ? bresp_done : bresp_ana_done); 

assign rd_txn_cmpl = rresp_done; 


//Update txn_cmpl based on write or read 
generate
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_txn_cmpl
  always @(posedge axi_aclk) begin
    if (axi_aresetn == 1'b0) begin
      txn_cmpl[gi] <= 1'b0;
    end else begin
      if (int_desc_n_txn_type_wr_rd[gi]==1'b0) begin
        txn_cmpl[gi] <= wr_txn_cmpl[gi];
      end else begin
        txn_cmpl[gi] <= rd_txn_cmpl[gi];
      end   
    end
  end
end
endgenerate

assign comp = txn_cmpl;

//////////////////////
//Signal :
//  int_status_busy_busy
//Description :
//  Transaction busy status.
//////////////////////

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    req_avail_ff <= 'h0;
  end else begin
    req_avail_ff <= req_avail;
  end
end
always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    txn_cmpl_ff <= 'h0;
  end else begin
    txn_cmpl_ff <= txn_cmpl;
  end
end
generate        		
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_int_status_busy_busy
always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    int_status_busy_busy[gi] <= 1'b0;  
  end else if (req_avail[gi]==1'b1 && req_avail_ff[gi]==1'b0) begin //Positive edge detection  
    int_status_busy_busy[gi] <= 1'b1; 
  end else if (txn_cmpl[gi]==1'b1 && txn_cmpl_ff[gi]==1'b0) begin //Positive edge detection
    int_status_busy_busy[gi] <= 1'b0;
  end
end
end
endgenerate  


//////////////////////
//Signal :
//  ownership_cntl_hw
//Description :
//  Transaction ownership control from bridge.
//  It is one clock pulse signal.
//////////////////////

generate        		
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_ownership_cntl_hw
always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    ownership_cntl_hw[gi] <= 1'b0;  
  end else if (txn_avail[gi]==1'b1 && txn_avail_ff[gi]==1'b0) begin //Positive edge detection
    ownership_cntl_hw[gi] <= 1'b1;
  end else if (txn_cmpl[gi]==1'b1 && txn_cmpl_ff[gi]==1'b0) begin //Positive edge detection
    ownership_cntl_hw[gi] <= 1'b1;
  end else begin
    ownership_cntl_hw[gi] <= 1'b0;
  end
end
end
endgenerate  

///////////////////////
//Signal :
//  int_ownership_own
//Description:
//  Update int_ownership_own based on ownership_cntl_hw(from bridge) or int_ownership_flip_flip(from sw)
//////////////////////

//int_ownership_own
//0: Ownership is with SW
//1: Ownership is with HW

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    int_ownership_flip_flip_ff <= 'h0;
  end else begin
    int_ownership_flip_flip_ff <= int_ownership_flip_flip;
  end
end        		
always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    ownership_cntl_hw_ff <= 'h0;
  end else begin
    ownership_cntl_hw_ff <= ownership_cntl_hw;
  end
end
generate        		
for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: for_int_ownership_own
always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    int_ownership_own[gi] <= 1'b0;  
  end else if (ownership_cntl_hw[gi]==1'b1 && ownership_cntl_hw_ff[gi]==1'b0) begin //Positive edge detection
    int_ownership_own[gi] <= 1'b0;
  end else if (int_ownership_flip_flip[gi]==1'b1 && int_ownership_flip_flip_ff[gi]==1'b0) begin //Positive edge detection
    int_ownership_own[gi] <= 1'b1;
  end
end
end
endgenerate

///////////////////////
//Signal :
//  int_intr_error_status_err_0
//Description:
//  Update int_intr_error_status_err_0 based on error_ctl_hw(from bridge) or int_intr_error_clear_clr_err_0(from sw)
//////////////////////

generate 

`IF_INTFS_AXI4 
assign error_ctl =   (|error_wr_buser) 
                   | (|error_wr_bresp) 
                   | (|error_wr_wlast) ;
`END_INTFS
`IF_INTFS_AXI4LITE 
assign error_ctl =   (|error_wr_bresp) ;
`END_INTFS
`IF_INTFS_AXI3 
assign error_ctl =   (|error_wr_bresp) 
                   | (|error_wr_wlast) ;
`END_INTFS

endgenerate

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    error_ctl_hw <= 'h0;
  end else begin
    error_ctl_hw <= error_ctl;
  end
end        		

always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    int_intr_error_clear_clr_err_0_ff <= 'h0;
  end else begin
    int_intr_error_clear_clr_err_0_ff <= int_intr_error_clear_clr_err_0;
  end
end        		
always @(posedge axi_aclk) begin
  if (axi_aresetn==0) begin
    error_ctl_hw_ff <= 'h0;
  end else begin
    error_ctl_hw_ff <= error_ctl_hw;
  end
end

always @(posedge axi_aclk) begin
  if (axi_aresetn == 1'b0) begin
    int_intr_error_status_err_0 <= 1'b0;  
  end else if (error_ctl_hw==1'b1 && error_ctl_hw_ff==1'b0) begin //Positive edge detection
    int_intr_error_status_err_0 <= 1'b1;
  end else if (int_intr_error_clear_clr_err_0==1'b1 && int_intr_error_clear_clr_err_0_ff==1'b0) begin //Positive edge detection
    int_intr_error_status_err_0 <= 1'b0;
  end
end


endmodule        


