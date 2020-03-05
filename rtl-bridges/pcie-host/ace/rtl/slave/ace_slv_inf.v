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
 *   This module handles ACE-usr interface and SW registers. 
 * 
 */

`include "ace_defines_common.vh"
`include "ace_defines_slv.vh"

module ace_slv_inf #(

                      parameter ACE_PROTOCOL                   = "FULLACE" 
                      
                      ,parameter ADDR_WIDTH                     = 64 
                      ,parameter XX_DATA_WIDTH                  = 128       
                      ,parameter SN_DATA_WIDTH                  = 128       
                      ,parameter ID_WIDTH                       = 16 
                      ,parameter AWUSER_WIDTH                   = 32 
                      ,parameter WUSER_WIDTH                    = 32 
                      ,parameter BUSER_WIDTH                    = 32 
                      ,parameter ARUSER_WIDTH                   = 32 
                      ,parameter RUSER_WIDTH                    = 32 
                      
                      ,parameter CACHE_LINE_SIZE                = 64 
                      ,parameter XX_MAX_DESC                    = 16         
                      ,parameter SN_MAX_DESC                    = 16        
                      ,parameter XX_RAM_SIZE                    = 16384     
                      ,parameter SN_RAM_SIZE                    = 1024       

                      )(

                        //Clock and reset
                        input clk 
			,input resetn
   
			//S_ACE_USR
			,input [ID_WIDTH-1:0] s_ace_usr_awid 
			,input [ADDR_WIDTH-1:0] s_ace_usr_awaddr 
			,input [7:0] s_ace_usr_awlen
			,input [2:0] s_ace_usr_awsize 
			,input [1:0] s_ace_usr_awburst 
			,input s_ace_usr_awlock 
			,input [3:0] s_ace_usr_awcache 
			,input [2:0] s_ace_usr_awprot 
			,input [3:0] s_ace_usr_awqos 
			,input [3:0] s_ace_usr_awregion 
			,input [AWUSER_WIDTH-1:0] s_ace_usr_awuser 
			,input [2:0] s_ace_usr_awsnoop 
			,input [1:0] s_ace_usr_awdomain 
			,input [1:0] s_ace_usr_awbar 
			,input s_ace_usr_awunique 
			,input s_ace_usr_awvalid 
			,output s_ace_usr_awready 
			,input [XX_DATA_WIDTH-1:0] s_ace_usr_wdata 
			,input [(XX_DATA_WIDTH/8)-1:0] s_ace_usr_wstrb
			,input s_ace_usr_wlast 
			,input [WUSER_WIDTH-1:0] s_ace_usr_wuser 
			,input s_ace_usr_wvalid 
			,output s_ace_usr_wready 
			,output [ID_WIDTH-1:0] s_ace_usr_bid 
			,output [1:0] s_ace_usr_bresp 
			,output [BUSER_WIDTH-1:0] s_ace_usr_buser 
			,output s_ace_usr_bvalid 
			,input s_ace_usr_bready 
			,input s_ace_usr_wack 
			,input [ID_WIDTH-1:0] s_ace_usr_arid 
			,input [ADDR_WIDTH-1:0] s_ace_usr_araddr 
			,input [7:0] s_ace_usr_arlen 
			,input [2:0] s_ace_usr_arsize 
			,input [1:0] s_ace_usr_arburst 
			,input s_ace_usr_arlock 
			,input [3:0] s_ace_usr_arcache 
			,input [2:0] s_ace_usr_arprot 
			,input [3:0] s_ace_usr_arqos 
			,input [3:0] s_ace_usr_arregion 
			,input [ARUSER_WIDTH-1:0] s_ace_usr_aruser 
			,input [3:0] s_ace_usr_arsnoop 
			,input [1:0] s_ace_usr_ardomain 
			,input [1:0] s_ace_usr_arbar 
			,input s_ace_usr_arvalid 
			,output s_ace_usr_arready 
			,output [ID_WIDTH-1:0] s_ace_usr_rid 
			,output [XX_DATA_WIDTH-1:0] s_ace_usr_rdata 
			,output [3:0] s_ace_usr_rresp 
			,output s_ace_usr_rlast 
			,output [RUSER_WIDTH-1:0] s_ace_usr_ruser 
			,output s_ace_usr_rvalid 
			,input s_ace_usr_rready 
			,input s_ace_usr_rack 
			,output [ADDR_WIDTH-1:0] s_ace_usr_acaddr 
			,output [3:0] s_ace_usr_acsnoop 
			,output [2:0] s_ace_usr_acprot 
			,output s_ace_usr_acvalid 
			,input s_ace_usr_acready 
			,input [4:0] s_ace_usr_crresp 
			,input s_ace_usr_crvalid 
			,output s_ace_usr_crready 
			,input [SN_DATA_WIDTH-1:0] s_ace_usr_cddata 
			,input s_ace_usr_cdlast 
			,input s_ace_usr_cdvalid 
			,output s_ace_usr_cdready 
   
			//RAM commands  
			//RDATA_RAM
			,output [(`CLOG2((XX_RAM_SIZE*8)/XX_DATA_WIDTH))-1:0] uc2rb_rd_addr 
			,input [XX_DATA_WIDTH-1:0] rb2uc_rd_data 
   
			//WDATA_RAM and WSTRB_RAM                               
			,output uc2rb_wr_we 
			,output [(XX_DATA_WIDTH/8)-1:0] uc2rb_wr_bwe //Generate all 1s always.     
			,output [(`CLOG2((XX_RAM_SIZE*8)/XX_DATA_WIDTH))-1:0] uc2rb_wr_addr 
			,output [XX_DATA_WIDTH-1:0] uc2rb_wr_data 
			,output [(XX_DATA_WIDTH/8)-1:0] uc2rb_wr_wstrb 
   
			//CDDATA_RAM                               
			,output uc2rb_sn_we 
			,output [(SN_DATA_WIDTH/8)-1:0] uc2rb_sn_bwe //Generate all 1s always.     
			,output [(`CLOG2((SN_RAM_SIZE*8)/SN_DATA_WIDTH))-1:0] uc2rb_sn_addr 
			,output [SN_DATA_WIDTH-1:0] uc2rb_sn_data 
   
			,output [XX_MAX_DESC-1:0] rd_uc2hm_trig 
			,input [XX_MAX_DESC-1:0] rd_hm2uc_done
			,output [XX_MAX_DESC-1:0] wr_uc2hm_trig 
			,input [XX_MAX_DESC-1:0] wr_hm2uc_done
   
			//pop request to FIFO
			,input rd_req_fifo_pop_desc_conn 
			,input wr_req_fifo_pop_desc_conn 
			,input sn_resp_fifo_pop_desc_conn
			,input sn_data_fifo_pop_desc_conn
   
			//output from FIFO
			,output [(`CLOG2(XX_MAX_DESC))-1:0] rd_req_fifo_out
			,output rd_req_fifo_out_valid //it is one clock cycle pulse
			,output [(`CLOG2(XX_MAX_DESC))-1:0] wr_req_fifo_out
			,output wr_req_fifo_out_valid //it is one clock cycle pulse
			,output [(`CLOG2(SN_MAX_DESC))-1:0] sn_resp_fifo_out
			,output sn_resp_fifo_out_valid //it is one clock cycle pulse
			,output [(`CLOG2(SN_MAX_DESC))-1:0] sn_data_fifo_out
			,output sn_data_fifo_out_valid //it is one clock cycle pulse
   
   
			//Declare all signals
			,input [0:0] int_bridge_identification_last_bridge
			,input [7:0] int_version_major_ver
			,input [7:0] int_version_minor_ver
			,input [7:0] int_bridge_type_type
			,input [0:0] int_bridge_config_extend_wstrb
			,input [7:0] int_bridge_config_id_width
			,input [2:0] int_bridge_config_data_width
			,input [9:0] int_bridge_rd_user_config_ruser_width
			,input [9:0] int_bridge_rd_user_config_aruser_width
			,input [9:0] int_bridge_wr_user_config_buser_width
			,input [9:0] int_bridge_wr_user_config_wuser_width
			,input [9:0] int_bridge_wr_user_config_awuser_width
			,input [7:0] int_rd_max_desc_resp_max_desc
			,input [7:0] int_rd_max_desc_req_max_desc
			,input [7:0] int_wr_max_desc_resp_max_desc
			,input [7:0] int_wr_max_desc_req_max_desc
			,input [7:0] int_sn_max_desc_data_max_desc
			,input [7:0] int_sn_max_desc_resp_max_desc
			,input [7:0] int_sn_max_desc_req_max_desc
			,input [0:0] int_reset_dut_srst_3
			,input [0:0] int_reset_dut_srst_2
			,input [0:0] int_reset_dut_srst_1
			,input [0:0] int_reset_dut_srst_0
			,input [0:0] int_reset_srst
			,input [0:0] int_mode_select_mode_0_1
			,input [0:0] int_intr_status_sn_data_fifo_nonempty
			,input [0:0] int_intr_status_sn_resp_fifo_nonempty
			,input [0:0] int_intr_status_sn_req_comp
			,input [0:0] int_intr_status_wr_resp_comp
			,input [0:0] int_intr_status_wr_req_fifo_nonempty
			,input [0:0] int_intr_status_rd_resp_comp
			,input [0:0] int_intr_status_rd_req_fifo_nonempty
			,input [0:0] int_intr_status_c2h
			,input [0:0] int_intr_status_error
			,input [0:0] int_intr_error_status_err_1
			,input [0:0] int_intr_error_clear_clr_err_2
			,input [0:0] int_intr_error_clear_clr_err_1
			,input [0:0] int_intr_error_clear_clr_err_0
			,input [0:0] int_intr_error_enable_en_err_2
			,input [0:0] int_intr_error_enable_en_err_1
			,input [0:0] int_intr_error_enable_en_err_0
			,input [15:0] int_rd_req_free_desc_desc
			,input [0:0] int_rd_resp_fifo_push_desc_valid
			,input [3:0] int_rd_resp_fifo_push_desc_desc_index
			,input [15:0] int_rd_resp_intr_comp_clear_clr_comp
			,input [15:0] int_rd_resp_intr_comp_enable_en_comp
			,input [15:0] int_wr_req_free_desc_desc
			,input [0:0] int_wr_resp_fifo_push_desc_valid
			,input [3:0] int_wr_resp_fifo_push_desc_desc_index
			,input [15:0] int_wr_resp_intr_comp_clear_clr_comp
			,input [15:0] int_wr_resp_intr_comp_enable_en_comp
			,input [0:0] int_sn_req_fifo_push_desc_valid
			,input [3:0] int_sn_req_fifo_push_desc_desc_index
			,input [15:0] int_sn_req_intr_comp_clear_clr_comp
			,input [15:0] int_sn_req_intr_comp_enable_en_comp
			,input [15:0] int_sn_resp_free_desc_desc
			,input [15:0] int_sn_data_free_desc_desc
			,input [0:0] int_intr_fifo_enable_en_sn_data_fifo_nonempty
			,input [0:0] int_intr_fifo_enable_en_sn_resp_fifo_nonempty
			,input [0:0] int_intr_fifo_enable_en_wr_req_fifo_nonempty
			,input [0:0] int_intr_fifo_enable_en_rd_req_fifo_nonempty
			,output [0:0] int_intr_error_status_err_0
			,output [0:0] int_rd_req_fifo_pop_desc_valid
			,output [3:0] int_rd_req_fifo_pop_desc_desc_index
			,output [4:0] int_rd_req_fifo_fill_level_fill
			,output [4:0] int_rd_resp_fifo_free_level_free
			,output [15:0] int_rd_resp_intr_comp_status_comp
			,output [0:0] int_wr_req_fifo_pop_desc_valid
			,output [3:0] int_wr_req_fifo_pop_desc_desc_index
			,output [4:0] int_wr_req_fifo_fill_level_fill
			,output [4:0] int_wr_resp_fifo_free_level_free
			,output [15:0] int_wr_resp_intr_comp_status_comp
			,output [4:0] int_sn_req_fifo_free_level_free
			,output [15:0] int_sn_req_intr_comp_status_comp
			,output [0:0] int_sn_resp_fifo_pop_desc_valid
			,output [3:0] int_sn_resp_fifo_pop_desc_desc_index
			,output [4:0] int_sn_resp_fifo_fill_level_fill
			,output [0:0] int_sn_data_fifo_pop_desc_valid
			,output [3:0] int_sn_data_fifo_pop_desc_desc_index
			,output [4:0] int_sn_data_fifo_fill_level_fill
   
   
   
`include "ace_slv_int_desc_port.vh"


			);

   localparam MAX_DESC                                                     = XX_MAX_DESC;

   localparam XX_RAM_OFFSET_WIDTH                                          = `CLOG2((XX_RAM_SIZE*8)/XX_DATA_WIDTH);
   localparam XX_DESC_IDX_WIDTH                                            = `CLOG2(XX_MAX_DESC);

   localparam SN_RAM_OFFSET_WIDTH                                          = `CLOG2((SN_RAM_SIZE*8)/XX_DATA_WIDTH);
   localparam SN_DESC_IDX_WIDTH                                            = `CLOG2(SN_MAX_DESC);


   localparam RD_MAX_DESC                                                  = XX_MAX_DESC;
   localparam RD_RAM_SIZE                                                  = XX_RAM_SIZE;
   localparam WR_MAX_DESC                                                  = XX_MAX_DESC;
   localparam WR_RAM_SIZE                                                  = XX_RAM_SIZE;
   
   localparam RD_DATA_WIDTH                                                = XX_DATA_WIDTH;
   localparam WR_DATA_WIDTH                                                = XX_DATA_WIDTH;

   localparam RD_DESC_IDX_WIDTH                                            = `CLOG2(RD_MAX_DESC);
   localparam RD_RAM_OFFSET_WIDTH                                          = `CLOG2((RD_RAM_SIZE*8)/RD_DATA_WIDTH);
   localparam RLAST_WIDTH                                                  = 1;            //rlast width
   localparam RRESP_WIDTH                                                  = (ACE_PROTOCOL=="FULLACE") ? (4) :
                                                                             (2) ;            //rresp width

   localparam WSTRB_WIDTH                                                  = (WR_DATA_WIDTH/8);
   localparam WR_DESC_IDX_WIDTH                                            = `CLOG2(WR_MAX_DESC);
   localparam WR_RAM_OFFSET_WIDTH                                          = `CLOG2((WR_RAM_SIZE*8)/WR_DATA_WIDTH);
   localparam WLAST_WIDTH                                                  = 1;            //wlast width
   localparam BRESP_WIDTH                                                  = 2;            //bresp width

   localparam CRRESP_WIDTH                                                  = 5;

   localparam RDATA_RAM_STRT_ADDR                                          = RD_RAM_SIZE*2;
   localparam RDATA_RAM_END_ADDR                                           = RDATA_RAM_STRT_ADDR+RD_RAM_SIZE-4;

   localparam WDATA_RAM_STRT_ADDR                                          = RDATA_RAM_END_ADDR+4;
   localparam WDATA_RAM_END_ADDR                                           = WDATA_RAM_STRT_ADDR+WR_RAM_SIZE-4;
   localparam WSTRB_RAM_STRT_ADDR                                          = WDATA_RAM_END_ADDR+4;
   localparam WSTRB_RAM_END_ADDR                                           = WSTRB_RAM_STRT_ADDR+WR_RAM_SIZE-4;


   localparam AXLEN_WIDTH                                                  = 8;
   localparam AXSIZE_WIDTH                                                 = 3;
   localparam AXBURST_WIDTH                                                = 2;
   localparam AXLOCK_WIDTH                                                 = 1;
   localparam AXCACHE_WIDTH                                                = 4;
   localparam AXPROT_WIDTH                                                 = 3;
   localparam AXQOS_WIDTH                                                  = 4;
   localparam AXREGION_WIDTH                                               = 4;

   localparam ARSNOOP_WIDTH                                                = 4;
   localparam AWSNOOP_WIDTH                                                = 3;

   localparam ACSNOOP_WIDTH                                                = 4;
   localparam ACPROT_WIDTH                                                 = 3;

   localparam AXDOMAIN_WIDTH                                               = 2;
   localparam AXBAR_WIDTH                                                  = 2;

   localparam AWUNIQUE_WIDTH                                               = 1;



   ////////////////////////////////

   //Loop variables
   integer 		      i;
   integer 		      j;
   integer 		      k;

   //generate variable
   genvar 		      gi;

   wire 		      wlast_error_status;
   wire 		      cdlast_error_status;

   //Descriptor 2d vectors
   wire [13:0] 		      int_rd_resp_desc_n_data_offset_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_data_size_size [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xid_0_xid [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xid_1_xid [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xid_2_xid [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xid_3_xid [RD_MAX_DESC-1:0];
   wire [4:0] 		      int_rd_resp_desc_n_resp_resp [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_data_host_addr_0_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_data_host_addr_1_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_data_host_addr_2_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_data_host_addr_3_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_0_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_10_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_11_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_12_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_13_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_14_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_15_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_1_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_2_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_3_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_4_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_5_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_6_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_7_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_8_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_resp_desc_n_xuser_9_xuser [RD_MAX_DESC-1:0];
   wire [2:0] 		      int_rd_req_desc_n_attr_axprot [RD_MAX_DESC-1:0];
   wire [1:0] 		      int_rd_req_desc_n_attr_axburst [RD_MAX_DESC-1:0];
   wire [3:0] 		      int_rd_req_desc_n_attr_axqos [RD_MAX_DESC-1:0];
   wire [3:0] 		      int_rd_req_desc_n_attr_axregion [RD_MAX_DESC-1:0];
   wire [2:0] 		      int_rd_req_desc_n_axsize_axsize [RD_MAX_DESC-1:0];
   wire [1:0] 		      int_rd_req_desc_n_attr_axbar [RD_MAX_DESC-1:0];
   wire [1:0] 		      int_rd_req_desc_n_attr_axdomain [RD_MAX_DESC-1:0];
   wire [3:0] 		      int_rd_req_desc_n_attr_axsnoop [RD_MAX_DESC-1:0];
   wire [0:0] 		      int_rd_req_desc_n_attr_axlock [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axaddr_0_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axaddr_1_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axaddr_2_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axaddr_3_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axid_0_axid [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axid_1_axid [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axid_2_axid [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axid_3_axid [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_0_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_10_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_11_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_12_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_13_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_14_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_15_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_1_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_2_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_3_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_4_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_5_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_6_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_7_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_8_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_axuser_9_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_rd_req_desc_n_size_txn_size [RD_MAX_DESC-1:0];
   wire [3:0] 		      int_rd_req_desc_n_attr_axcache [RD_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xid_0_xid [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xid_1_xid [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xid_2_xid [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xid_3_xid [WR_MAX_DESC-1:0];
   wire [4:0] 		      int_wr_resp_desc_n_resp_resp [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_data_host_addr_0_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_data_host_addr_1_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_data_host_addr_2_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_data_host_addr_3_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wstrb_host_addr_0_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wstrb_host_addr_1_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wstrb_host_addr_2_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wstrb_host_addr_3_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_0_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_10_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_11_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_12_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_13_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_14_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_15_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_1_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_2_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_3_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_4_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_5_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_6_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_7_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_8_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_resp_desc_n_xuser_9_xuser [WR_MAX_DESC-1:0];
   wire [2:0] 		      int_wr_req_desc_n_attr_axprot [WR_MAX_DESC-1:0];
   wire [1:0] 		      int_wr_req_desc_n_attr_axburst [WR_MAX_DESC-1:0];
   wire [13:0] 		      int_wr_req_desc_n_data_offset_addr [WR_MAX_DESC-1:0];
   wire [3:0] 		      int_wr_req_desc_n_attr_axqos [WR_MAX_DESC-1:0];
   wire [3:0] 		      int_wr_req_desc_n_attr_axregion [WR_MAX_DESC-1:0];
   wire [0:0] 		      int_wr_req_desc_n_attr_awunique [WR_MAX_DESC-1:0];
   wire [2:0] 		      int_wr_req_desc_n_axsize_axsize [WR_MAX_DESC-1:0];
   wire [1:0] 		      int_wr_req_desc_n_attr_axbar [WR_MAX_DESC-1:0];
   wire [1:0] 		      int_wr_req_desc_n_attr_axdomain [WR_MAX_DESC-1:0];
   wire [3:0] 		      int_wr_req_desc_n_attr_axsnoop [WR_MAX_DESC-1:0];
   wire [0:0] 		      int_wr_req_desc_n_attr_axlock [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axaddr_0_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axaddr_1_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axaddr_2_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axaddr_3_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axid_0_axid [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axid_1_axid [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axid_2_axid [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axid_3_axid [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_0_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_10_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_11_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_12_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_13_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_14_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_15_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_1_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_2_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_3_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_4_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_5_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_6_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_7_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_8_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_axuser_9_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_size_txn_size [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_0_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_10_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_11_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_12_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_13_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_14_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_15_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_1_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_2_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_3_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_4_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_5_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_6_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_7_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_8_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		      int_wr_req_desc_n_wuser_9_wuser [WR_MAX_DESC-1:0];
   wire [3:0] 		      int_wr_req_desc_n_attr_axcache [WR_MAX_DESC-1:0];
   wire [0:0] 		      int_wr_req_desc_n_txn_type_wr_strb [WR_MAX_DESC-1:0];
   wire [2:0] 		      int_sn_req_desc_n_attr_acprot [SN_MAX_DESC-1:0];
   wire [3:0] 		      int_sn_req_desc_n_attr_acsnoop [SN_MAX_DESC-1:0];
   wire [31:0] 		      int_sn_req_desc_n_acaddr_0_addr [SN_MAX_DESC-1:0];
   wire [31:0] 		      int_sn_req_desc_n_acaddr_1_addr [SN_MAX_DESC-1:0];
   wire [31:0] 		      int_sn_req_desc_n_acaddr_2_addr [SN_MAX_DESC-1:0];
   wire [31:0] 		      int_sn_req_desc_n_acaddr_3_addr [SN_MAX_DESC-1:0];
   wire [4:0] 		      int_sn_resp_desc_n_resp_resp [SN_MAX_DESC-1:0];



   ///////////////////////
   //2-D array of descriptor fields
   //////////////////////

`include "ace_usr_slv_desc_2d.vh"

   ///////////////////////
   //Tie unused signals
   //////////////////////

   generate

      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_unused_desc_sig

	 assign int_rd_req_desc_n_axaddr_2_addr[gi] = 32'h0;
	 assign int_rd_req_desc_n_axaddr_3_addr[gi] = 32'h0;
	 assign int_wr_req_desc_n_axaddr_2_addr[gi] = 32'h0;
	 assign int_wr_req_desc_n_axaddr_3_addr[gi] = 32'h0;
	 assign int_rd_req_desc_n_axid_1_axid[gi] = 32'h0;
	 assign int_rd_req_desc_n_axid_2_axid[gi] = 32'h0;
	 assign int_rd_req_desc_n_axid_3_axid[gi] = 32'h0;
	 assign int_wr_req_desc_n_axid_1_axid[gi] = 32'h0;
	 assign int_wr_req_desc_n_axid_2_axid[gi] = 32'h0;
	 assign int_wr_req_desc_n_axid_3_axid[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_10_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_11_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_12_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_13_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_14_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_15_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_1_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_2_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_3_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_4_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_5_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_6_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_7_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_8_axuser[gi] = 32'h0;
	 assign int_rd_req_desc_n_axuser_9_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_10_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_11_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_12_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_13_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_14_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_15_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_1_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_2_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_3_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_4_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_5_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_6_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_7_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_8_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_axuser_9_axuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_10_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_11_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_12_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_13_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_14_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_15_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_1_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_2_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_3_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_4_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_5_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_6_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_7_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_8_wuser[gi] = 32'h0;
	 assign int_wr_req_desc_n_wuser_9_wuser[gi] = 32'h0;

      end

   endgenerate  

   ///////////////////////
   //Update error from UC(User-Control) block
   //////////////////////

   assign int_intr_error_status_err_0 = ( wlast_error_status | cdlast_error_status );

   ///////////////////////
   //AR-Channel
   //Description :
   //////////////////////
   

   
   localparam RD_REQ_INFBUS_WIDTH                                          = (   ID_WIDTH
										 + ADDR_WIDTH
										 + AXLEN_WIDTH
										 + AXSIZE_WIDTH 
										 + AXBURST_WIDTH
										 + AXLOCK_WIDTH
										 + AXCACHE_WIDTH
										 + AXPROT_WIDTH
										 + AXQOS_WIDTH
										 + AXREGION_WIDTH
										 + ARUSER_WIDTH
										 + ARSNOOP_WIDTH
										 + AXDOMAIN_WIDTH
										 + AXBAR_WIDTH
										 );


   localparam RD_REQ_TR_DESCBUS_WIDTH                                      = RD_REQ_INFBUS_WIDTH; 

   localparam RD_REQ_AW_INFBUS_WIDTH_DUMMY                                 = 1; 


   wire [RD_REQ_INFBUS_WIDTH-1:0]                                          rd_req_infbus;

   wire [XX_DESC_IDX_WIDTH-1:0] 					   rd_req_fifo_dout;
   wire                                                                    rd_req_fifo_dout_valid;  //it is one clock cycle pulse
   wire [XX_DESC_IDX_WIDTH:0] 						   rd_req_fifo_fill_level;
   wire [XX_DESC_IDX_WIDTH:0] 						   rd_req_fifo_free_level;

   wire [XX_MAX_DESC-1:0] 						   rd_req_desc_avail;
   wire                                                                    rd_req_fifo_rden;   //should be one clock cycle pulse

   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_0;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_1;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_2;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_3;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_4;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_5;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_6;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_7;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_8;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_9;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_A;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_B;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_C;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_D;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_E;
   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_F;

   wire [RD_REQ_TR_DESCBUS_WIDTH-1 :0] 					   rd_req_tr_descbus_n[XX_MAX_DESC-1:0];
   
   //wire rd_req_fifo_pop_desc_conn_pulse;
   reg 									   rd_req_fifo_pop_desc_conn_pulse;

   reg 									   rd_req_fifo_pop_desc_conn_ff;

   assign int_rd_req_fifo_pop_desc_valid = 'b0;
   assign int_rd_req_fifo_pop_desc_desc_index = 'b0;

   `FF_RSTLOW(clk,resetn,rd_req_fifo_pop_desc_conn,rd_req_fifo_pop_desc_conn_ff)

   //assign rd_req_fifo_pop_desc_conn_pulse = ( (rd_req_fifo_pop_desc_conn) & (~rd_req_fifo_pop_desc_conn_ff) );

   assign rd_req_fifo_out = rd_req_fifo_dout; 
   assign rd_req_fifo_out_valid = rd_req_fifo_dout_valid;

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 rd_req_fifo_pop_desc_conn_pulse <= 1'b0;
      end else if (rd_req_fifo_pop_desc_conn==1'b1 && rd_req_fifo_pop_desc_conn_ff==1'b0) begin //Positive edge detection
	 rd_req_fifo_pop_desc_conn_pulse <= 1'b1;
      end else begin
	 rd_req_fifo_pop_desc_conn_pulse <= 1'b0;
      end
   end


   assign rd_req_infbus                                                    = {   s_ace_usr_arid 
										 , s_ace_usr_araddr 
										 , s_ace_usr_arlen 
										 , s_ace_usr_arsize 
										 , s_ace_usr_arburst 
										 , s_ace_usr_arlock 
										 , s_ace_usr_arcache 
										 , s_ace_usr_arprot 
										 , s_ace_usr_arqos 
										 , s_ace_usr_arregion 
										 , s_ace_usr_aruser 
										 , s_ace_usr_arsnoop 
										 , s_ace_usr_ardomain 
										 , s_ace_usr_arbar 
										 };

   assign rd_req_tr_descbus_n['h0] = rd_req_tr_descbus_0;
   assign rd_req_tr_descbus_n['h1] = rd_req_tr_descbus_1;
   assign rd_req_tr_descbus_n['h2] = rd_req_tr_descbus_2;
   assign rd_req_tr_descbus_n['h3] = rd_req_tr_descbus_3;
   assign rd_req_tr_descbus_n['h4] = rd_req_tr_descbus_4;
   assign rd_req_tr_descbus_n['h5] = rd_req_tr_descbus_5;
   assign rd_req_tr_descbus_n['h6] = rd_req_tr_descbus_6;
   assign rd_req_tr_descbus_n['h7] = rd_req_tr_descbus_7;
   assign rd_req_tr_descbus_n['h8] = rd_req_tr_descbus_8;
   assign rd_req_tr_descbus_n['h9] = rd_req_tr_descbus_9;
   assign rd_req_tr_descbus_n['hA] = rd_req_tr_descbus_A;
   assign rd_req_tr_descbus_n['hB] = rd_req_tr_descbus_B;
   assign rd_req_tr_descbus_n['hC] = rd_req_tr_descbus_C;
   assign rd_req_tr_descbus_n['hD] = rd_req_tr_descbus_D;
   assign rd_req_tr_descbus_n['hE] = rd_req_tr_descbus_E;
   assign rd_req_tr_descbus_n['hF] = rd_req_tr_descbus_F;

   
   generate

      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_int_rd_req_desc

	 assign int_rd_req_desc_n_axid_0_axid[gi][31:0]	  = { {(32-ID_WIDTH){1'b0}} , rd_req_tr_descbus_n[gi][(RD_REQ_TR_DESCBUS_WIDTH-1) -: (ID_WIDTH)] };
	 assign {int_rd_req_desc_n_axaddr_1_addr[gi][31:0],int_rd_req_desc_n_axaddr_0_addr[gi][31:0]} =
												       { {(64-ADDR_WIDTH){1'b0}} , rd_req_tr_descbus_n[gi][(RD_REQ_TR_DESCBUS_WIDTH-ID_WIDTH-1) -: (ADDR_WIDTH)] };				
	 assign int_rd_req_desc_n_size_txn_size[gi][31:0]	  = ((rd_req_tr_descbus_n[gi][(RD_REQ_TR_DESCBUS_WIDTH-ID_WIDTH-ADDR_WIDTH-1) -: (AXLEN_WIDTH)]+1)*XX_DATA_WIDTH/8);
	 ;				
	 
	 
	 assign {int_rd_req_desc_n_axsize_axsize[gi][2:0],int_rd_req_desc_n_attr_axburst[gi][1:0],int_rd_req_desc_n_attr_axlock[gi][0:0],int_rd_req_desc_n_attr_axcache[gi][3:0],int_rd_req_desc_n_attr_axprot[gi][2:0],int_rd_req_desc_n_attr_axqos[gi][3:0],int_rd_req_desc_n_attr_axregion[gi][3:0]} 
           = rd_req_tr_descbus_n[gi][(RD_REQ_TR_DESCBUS_WIDTH-ID_WIDTH-ADDR_WIDTH-AXLEN_WIDTH-1) -: (AXSIZE_WIDTH +AXBURST_WIDTH +AXLOCK_WIDTH +AXCACHE_WIDTH +AXPROT_WIDTH +AXQOS_WIDTH +AXREGION_WIDTH)];
	 
	 
	 assign int_rd_req_desc_n_axuser_0_axuser[gi][31:0]	  = { {(32-ARUSER_WIDTH){1'b0}} , rd_req_tr_descbus_n[gi][(ARSNOOP_WIDTH+AXDOMAIN_WIDTH+AXBAR_WIDTH) +: (ARUSER_WIDTH)] };				
	 
	 
	 assign {int_rd_req_desc_n_attr_axsnoop[gi][3:0],int_rd_req_desc_n_attr_axdomain[gi][1:0],int_rd_req_desc_n_attr_axbar[gi][1:0]}
           = rd_req_tr_descbus_n[gi][(0) +: (ARSNOOP_WIDTH+AXDOMAIN_WIDTH+AXBAR_WIDTH)];
	 
	 
      end
   endgenerate

   assign rd_req_desc_avail = int_rd_req_free_desc_desc[XX_MAX_DESC-1:0];

   assign rd_req_fifo_rden = rd_req_fifo_pop_desc_conn_pulse;

   assign int_rd_req_fifo_fill_level_fill = rd_req_fifo_fill_level;

   ace_ctrl_ready #(
                    // Parameters
                    .ACE_PROTOCOL           (ACE_PROTOCOL),
                    .ACE_CHANNEL            ("SLV_RD_REQ"),
                    .ADDR_WIDTH             (ADDR_WIDTH),
                    .DATA_WIDTH             (XX_DATA_WIDTH),
                    .ID_WIDTH               (ID_WIDTH),
                    .AWUSER_WIDTH           (AWUSER_WIDTH),
                    .WUSER_WIDTH            (WUSER_WIDTH),
                    .BUSER_WIDTH            (BUSER_WIDTH),
                    .ARUSER_WIDTH           (ARUSER_WIDTH),
                    .RUSER_WIDTH            (RUSER_WIDTH),
                    .INFBUS_WIDTH           (RD_REQ_INFBUS_WIDTH),
                    .TR_DESCBUS_WIDTH       (RD_REQ_TR_DESCBUS_WIDTH),
                    .AW_INFBUS_WIDTH        (RD_REQ_AW_INFBUS_WIDTH_DUMMY),
                    .AW_TR_DESCBUS_WIDTH    (1),
                    .CACHE_LINE_SIZE        (CACHE_LINE_SIZE),
                    .MAX_DESC               (XX_MAX_DESC),
                    .RAM_SIZE               (XX_RAM_SIZE)
		    ) ar_ace_ctrl_ready (
					 // Outputs
					 .infbus_ready         (s_ace_usr_arready),
					 .inf_xack             (),
					 .aw_infbus_ready      (),
					 .tr_descbus_0         (rd_req_tr_descbus_0),
					 .tr_descbus_1         (rd_req_tr_descbus_1),
					 .tr_descbus_2         (rd_req_tr_descbus_2),
					 .tr_descbus_3         (rd_req_tr_descbus_3),
					 .tr_descbus_4         (rd_req_tr_descbus_4),
					 .tr_descbus_5         (rd_req_tr_descbus_5),
					 .tr_descbus_6         (rd_req_tr_descbus_6),
					 .tr_descbus_7         (rd_req_tr_descbus_7),
					 .tr_descbus_8         (rd_req_tr_descbus_8),
					 .tr_descbus_9         (rd_req_tr_descbus_9),
					 .tr_descbus_A         (rd_req_tr_descbus_A),
					 .tr_descbus_B         (rd_req_tr_descbus_B),
					 .tr_descbus_C         (rd_req_tr_descbus_C),
					 .tr_descbus_D         (rd_req_tr_descbus_D),
					 .tr_descbus_E         (rd_req_tr_descbus_E),
					 .tr_descbus_F         (rd_req_tr_descbus_F),
					 .fifo_dout            (rd_req_fifo_dout),            
					 .fifo_dout_valid      (rd_req_fifo_dout_valid),      
					 .fifo_fill_level      (rd_req_fifo_fill_level),
					 .fifo_free_level      (rd_req_fifo_free_level),
					 .uc2rb_we             (),
					 .uc2rb_bwe            (),
					 .uc2rb_addr           (),
					 .uc2rb_data           (),
					 .uc2rb_wstrb          (),
					 .uc2hm_trig           (),
					 // Inputs
					 .clk                  (clk),
					 .resetn               (resetn),
					 .infbus               (rd_req_infbus),  //ar channel
					 .infbus_last          (1'b1),
					 .infbus_valid         (s_ace_usr_arvalid),
					 .aw_infbus            ({RD_REQ_AW_INFBUS_WIDTH_DUMMY{1'b0}}),
					 .aw_infbus_len        (8'b0),
					 .aw_infbus_id         ({ID_WIDTH{1'b0}}),
					 .aw_infbus_valid      (1'b0),
					 .int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					 .error_clear          (1'b0),
					 .desc_avail           (rd_req_desc_avail),
					 .fifo_rden            (rd_req_fifo_rden),
					 .hm2uc_done           ({XX_MAX_DESC{1'b0}})
					 );
   
   ///////////////////////
     //R-Channel
   //Description :
   //////////////////////

   localparam RD_RESP_INFBUS_WIDTH                                         = {   XX_DATA_WIDTH 
										 + ID_WIDTH
										 + RRESP_WIDTH
										 + RUSER_WIDTH
										 };

   localparam RD_RESP_FR_DESCBUS_WIDTH                                     = RD_RESP_INFBUS_WIDTH;

   wire [RD_RESP_INFBUS_WIDTH-1:0]                                         rd_resp_infbus;

   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_n[XX_MAX_DESC-1:0];

   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_0;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_1;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_2;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_3;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_4;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_5;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_6;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_7;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_8;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_9;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_A;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_B;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_C;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_D;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_E;
   wire [RD_RESP_FR_DESCBUS_WIDTH-1 :0] 				   rd_resp_fr_descbus_F;

   wire [7:0] 								   rd_resp_fr_descbus_len_0;
   wire [7:0] 								   rd_resp_fr_descbus_len_1;
   wire [7:0] 								   rd_resp_fr_descbus_len_2;
   wire [7:0] 								   rd_resp_fr_descbus_len_3;
   wire [7:0] 								   rd_resp_fr_descbus_len_4;
   wire [7:0] 								   rd_resp_fr_descbus_len_5;
   wire [7:0] 								   rd_resp_fr_descbus_len_6;
   wire [7:0] 								   rd_resp_fr_descbus_len_7;
   wire [7:0] 								   rd_resp_fr_descbus_len_8;
   wire [7:0] 								   rd_resp_fr_descbus_len_9;
   wire [7:0] 								   rd_resp_fr_descbus_len_A;
   wire [7:0] 								   rd_resp_fr_descbus_len_B;
   wire [7:0] 								   rd_resp_fr_descbus_len_C;
   wire [7:0] 								   rd_resp_fr_descbus_len_D;
   wire [7:0] 								   rd_resp_fr_descbus_len_E;
   wire [7:0] 								   rd_resp_fr_descbus_len_F;

   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_0;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_1;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_2;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_3;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_4;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_5;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_6;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_7;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_8;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_9;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_A;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_B;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_C;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_D;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_E;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   rd_resp_fr_descbus_dtoffset_F;

   wire [XX_DESC_IDX_WIDTH:0] 						   rd_resp_fifo_fill_level;
   wire [XX_DESC_IDX_WIDTH:0] 						   rd_resp_fifo_free_level;

   wire [XX_MAX_DESC-1:0] 						   rd_resp_intr_comp_status_comp;

   reg                                                                     rd_resp_fifo_wren;
   wire [XX_DESC_IDX_WIDTH-1:0] 					   rd_resp_fifo_din;

   reg                                                                     rd_resp_push;
   reg                                                                     rd_resp_push_ff;

   assign int_rd_resp_fifo_free_level_free = rd_resp_fifo_free_level;

   `FF_RSTLOW(clk,resetn,int_rd_resp_fifo_push_desc_valid,rd_resp_push)
   `FF_RSTLOW(clk,resetn,rd_resp_push,rd_resp_push_ff)

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 rd_resp_fifo_wren <= 1'b0;  
      end else if (rd_resp_push==1'b1 && rd_resp_push_ff==1'b0) begin //Positive edge detection
	 rd_resp_fifo_wren <= 1'b1;
      end else begin
	 rd_resp_fifo_wren <= 1'b0;
      end
   end

   synchronizer#(
		 .SYNC_FF                                                       (2)  
		 ,.D_WIDTH                                                       (XX_DESC_IDX_WIDTH)
		 ) sync_rd_resp_fifo_din (
					  .ck                                                           (clk) 
					  ,.rn                                                           (resetn) 
					  ,.data_in                                                      (int_rd_resp_fifo_push_desc_desc_index) 
					  ,.q_out                                                        (rd_resp_fifo_din)
					  );   



   assign int_rd_resp_intr_comp_status_comp = rd_resp_intr_comp_status_comp;

   assign {   s_ace_usr_rdata 
              , s_ace_usr_rid
              , s_ace_usr_rresp
              , s_ace_usr_ruser
	      }                        = rd_resp_infbus;

   assign rd_resp_fr_descbus_0 = rd_resp_fr_descbus_n['h0];
   assign rd_resp_fr_descbus_1 = rd_resp_fr_descbus_n['h1];
   assign rd_resp_fr_descbus_2 = rd_resp_fr_descbus_n['h2];
   assign rd_resp_fr_descbus_3 = rd_resp_fr_descbus_n['h3];
   assign rd_resp_fr_descbus_4 = rd_resp_fr_descbus_n['h4];
   assign rd_resp_fr_descbus_5 = rd_resp_fr_descbus_n['h5];
   assign rd_resp_fr_descbus_6 = rd_resp_fr_descbus_n['h6];
   assign rd_resp_fr_descbus_7 = rd_resp_fr_descbus_n['h7];
   assign rd_resp_fr_descbus_8 = rd_resp_fr_descbus_n['h8];
   assign rd_resp_fr_descbus_9 = rd_resp_fr_descbus_n['h9];
   assign rd_resp_fr_descbus_A = rd_resp_fr_descbus_n['hA];
   assign rd_resp_fr_descbus_B = rd_resp_fr_descbus_n['hB];
   assign rd_resp_fr_descbus_C = rd_resp_fr_descbus_n['hC];
   assign rd_resp_fr_descbus_D = rd_resp_fr_descbus_n['hD];
   assign rd_resp_fr_descbus_E = rd_resp_fr_descbus_n['hE];
   assign rd_resp_fr_descbus_F = rd_resp_fr_descbus_n['hF];


   generate
      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_rd_resp_fr_descbus_n

	 assign rd_resp_fr_descbus_n[gi] = {   {XX_DATA_WIDTH{1'b0}}
					       , int_rd_resp_desc_n_xid_0_xid[gi][(0) +: (ID_WIDTH)]
					       , int_rd_resp_desc_n_resp_resp[gi][(0) +: (RRESP_WIDTH)] 
					       , int_rd_resp_desc_n_xuser_0_xuser[gi][(0) +: (RUSER_WIDTH)] 
					       };

      end
   endgenerate
   
   assign rd_resp_fr_descbus_len_0 = ( ((int_rd_resp_desc_n_data_size_size['h0]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_1 = ( ((int_rd_resp_desc_n_data_size_size['h1]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_2 = ( ((int_rd_resp_desc_n_data_size_size['h2]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_3 = ( ((int_rd_resp_desc_n_data_size_size['h3]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_4 = ( ((int_rd_resp_desc_n_data_size_size['h4]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_5 = ( ((int_rd_resp_desc_n_data_size_size['h5]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_6 = ( ((int_rd_resp_desc_n_data_size_size['h6]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_7 = ( ((int_rd_resp_desc_n_data_size_size['h7]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_8 = ( ((int_rd_resp_desc_n_data_size_size['h8]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_9 = ( ((int_rd_resp_desc_n_data_size_size['h9]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_A = ( ((int_rd_resp_desc_n_data_size_size['hA]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_B = ( ((int_rd_resp_desc_n_data_size_size['hB]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_C = ( ((int_rd_resp_desc_n_data_size_size['hC]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_D = ( ((int_rd_resp_desc_n_data_size_size['hD]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_E = ( ((int_rd_resp_desc_n_data_size_size['hE]*8)/XX_DATA_WIDTH) - 1 );
   assign rd_resp_fr_descbus_len_F = ( ((int_rd_resp_desc_n_data_size_size['hF]*8)/XX_DATA_WIDTH) - 1 );

   assign rd_resp_fr_descbus_dtoffset_0 = (int_rd_resp_desc_n_data_offset_addr['h0]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_1 = (int_rd_resp_desc_n_data_offset_addr['h1]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_2 = (int_rd_resp_desc_n_data_offset_addr['h2]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_3 = (int_rd_resp_desc_n_data_offset_addr['h3]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_4 = (int_rd_resp_desc_n_data_offset_addr['h4]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_5 = (int_rd_resp_desc_n_data_offset_addr['h5]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_6 = (int_rd_resp_desc_n_data_offset_addr['h6]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_7 = (int_rd_resp_desc_n_data_offset_addr['h7]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_8 = (int_rd_resp_desc_n_data_offset_addr['h8]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_9 = (int_rd_resp_desc_n_data_offset_addr['h9]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_A = (int_rd_resp_desc_n_data_offset_addr['hA]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_B = (int_rd_resp_desc_n_data_offset_addr['hB]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_C = (int_rd_resp_desc_n_data_offset_addr['hC]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_D = (int_rd_resp_desc_n_data_offset_addr['hD]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_E = (int_rd_resp_desc_n_data_offset_addr['hE]*8/XX_DATA_WIDTH);
   assign rd_resp_fr_descbus_dtoffset_F = (int_rd_resp_desc_n_data_offset_addr['hF]*8/XX_DATA_WIDTH);

   ace_ctrl_valid #(
                    // Parameters
                    .ACE_PROTOCOL          (ACE_PROTOCOL),
                    .ACE_CHANNEL           ("SLV_RD_RESP"),
                    .ADDR_WIDTH            (ADDR_WIDTH),
                    .DATA_WIDTH            (XX_DATA_WIDTH),
                    .ID_WIDTH              (ID_WIDTH),
                    .AWUSER_WIDTH          (AWUSER_WIDTH),
                    .WUSER_WIDTH           (WUSER_WIDTH),
                    .BUSER_WIDTH           (BUSER_WIDTH),
                    .ARUSER_WIDTH          (ARUSER_WIDTH),
                    .RUSER_WIDTH           (RUSER_WIDTH),
                    .INFBUS_WIDTH          (RD_RESP_INFBUS_WIDTH),
                    .FR_DESCBUS_WIDTH      (RD_RESP_FR_DESCBUS_WIDTH),
                    .CACHE_LINE_SIZE       (CACHE_LINE_SIZE),
                    .MAX_DESC              (XX_MAX_DESC),
                    .RAM_SIZE              (XX_RAM_SIZE)
		    ) r_ace_ctrl_valid (
					// Outputs
					.infbus               (rd_resp_infbus),  //r channel
					.infbus_last          (s_ace_usr_rlast),
					.infbus_valid         (s_ace_usr_rvalid),
					.fifo_fill_level      (rd_resp_fifo_fill_level),
					.fifo_free_level      (rd_resp_fifo_free_level),
					.intr_comp_status_comp(rd_resp_intr_comp_status_comp),
					.uc2rb_addr           (uc2rb_rd_addr),
					.uc2hm_trig           (rd_uc2hm_trig),
					// Inputs
					.clk                  (clk),
					.resetn               (resetn),
					.infbus_ready         (s_ace_usr_rready),
					.inf_xack             (s_ace_usr_rack),
					.fr_descbus_0         (rd_resp_fr_descbus_0),
					.fr_descbus_1         (rd_resp_fr_descbus_1),
					.fr_descbus_2         (rd_resp_fr_descbus_2),
					.fr_descbus_3         (rd_resp_fr_descbus_3),
					.fr_descbus_4         (rd_resp_fr_descbus_4),
					.fr_descbus_5         (rd_resp_fr_descbus_5),
					.fr_descbus_6         (rd_resp_fr_descbus_6),
					.fr_descbus_7         (rd_resp_fr_descbus_7),
					.fr_descbus_8         (rd_resp_fr_descbus_8),
					.fr_descbus_9         (rd_resp_fr_descbus_9),
					.fr_descbus_A         (rd_resp_fr_descbus_A),
					.fr_descbus_B         (rd_resp_fr_descbus_B),
					.fr_descbus_C         (rd_resp_fr_descbus_C),
					.fr_descbus_D         (rd_resp_fr_descbus_D),
					.fr_descbus_E         (rd_resp_fr_descbus_E),
					.fr_descbus_F         (rd_resp_fr_descbus_F),
					.fr_descbus_len_0     (rd_resp_fr_descbus_len_0),
					.fr_descbus_len_1     (rd_resp_fr_descbus_len_1),
					.fr_descbus_len_2     (rd_resp_fr_descbus_len_2),
					.fr_descbus_len_3     (rd_resp_fr_descbus_len_3),
					.fr_descbus_len_4     (rd_resp_fr_descbus_len_4),
					.fr_descbus_len_5     (rd_resp_fr_descbus_len_5),
					.fr_descbus_len_6     (rd_resp_fr_descbus_len_6),
					.fr_descbus_len_7     (rd_resp_fr_descbus_len_7),
					.fr_descbus_len_8     (rd_resp_fr_descbus_len_8),
					.fr_descbus_len_9     (rd_resp_fr_descbus_len_9),
					.fr_descbus_len_A     (rd_resp_fr_descbus_len_A),
					.fr_descbus_len_B     (rd_resp_fr_descbus_len_B),
					.fr_descbus_len_C     (rd_resp_fr_descbus_len_C),
					.fr_descbus_len_D     (rd_resp_fr_descbus_len_D),
					.fr_descbus_len_E     (rd_resp_fr_descbus_len_E),
					.fr_descbus_len_F     (rd_resp_fr_descbus_len_F),
					.fr_descbus_dtoffset_0(rd_resp_fr_descbus_dtoffset_0),
					.fr_descbus_dtoffset_1(rd_resp_fr_descbus_dtoffset_1),
					.fr_descbus_dtoffset_2(rd_resp_fr_descbus_dtoffset_2),
					.fr_descbus_dtoffset_3(rd_resp_fr_descbus_dtoffset_3),
					.fr_descbus_dtoffset_4(rd_resp_fr_descbus_dtoffset_4),
					.fr_descbus_dtoffset_5(rd_resp_fr_descbus_dtoffset_5),
					.fr_descbus_dtoffset_6(rd_resp_fr_descbus_dtoffset_6),
					.fr_descbus_dtoffset_7(rd_resp_fr_descbus_dtoffset_7),
					.fr_descbus_dtoffset_8(rd_resp_fr_descbus_dtoffset_8),
					.fr_descbus_dtoffset_9(rd_resp_fr_descbus_dtoffset_9),
					.fr_descbus_dtoffset_A(rd_resp_fr_descbus_dtoffset_A),
					.fr_descbus_dtoffset_B(rd_resp_fr_descbus_dtoffset_B),
					.fr_descbus_dtoffset_C(rd_resp_fr_descbus_dtoffset_C),
					.fr_descbus_dtoffset_D(rd_resp_fr_descbus_dtoffset_D),
					.fr_descbus_dtoffset_E(rd_resp_fr_descbus_dtoffset_E),
					.fr_descbus_dtoffset_F(rd_resp_fr_descbus_dtoffset_F),
					.int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					.fifo_wren            (rd_resp_fifo_wren),
					.fifo_din             (rd_resp_fifo_din),
					.intr_comp_clear_clr_comp(int_rd_resp_intr_comp_clear_clr_comp),
					.rb2uc_data           (rb2uc_rd_data),
					.rb2uc_wstrb          ({WSTRB_WIDTH{1'b0}}),
					.hm2uc_done           (rd_hm2uc_done)
					);
   


   ///////////////////////
     //AW,W-Channel
   //Description :
   //////////////////////

   localparam AW_REQ_INFBUS_WIDTH                                          = (   ID_WIDTH
										 + ADDR_WIDTH
										 + AXLEN_WIDTH
										 + AXSIZE_WIDTH 
										 + AXBURST_WIDTH
										 + AXLOCK_WIDTH
										 + AXCACHE_WIDTH
										 + AXPROT_WIDTH
										 + AXQOS_WIDTH
										 + AXREGION_WIDTH
										 + AWUSER_WIDTH
										 + AWSNOOP_WIDTH
										 + AXDOMAIN_WIDTH
										 + AXBAR_WIDTH
										 + AWUNIQUE_WIDTH
										 );

   localparam WR_REQ_INFBUS_WIDTH                                          = (   XX_DATA_WIDTH
										 + WSTRB_WIDTH
										 + WUSER_WIDTH
										 );


   localparam WR_REQ_TR_DESCBUS_WIDTH                                      = WR_REQ_INFBUS_WIDTH; 

   localparam AW_REQ_TR_DESCBUS_WIDTH                                      = AW_REQ_INFBUS_WIDTH; 



   wire [AW_REQ_INFBUS_WIDTH-1:0]                                          aw_req_infbus;
   wire [WR_REQ_INFBUS_WIDTH-1:0] 					   wr_req_infbus;

   wire [XX_DESC_IDX_WIDTH-1:0] 					   wr_req_fifo_dout;
   wire                                                                    wr_req_fifo_dout_valid;  //it is one clock cycle pulse
   wire [XX_DESC_IDX_WIDTH:0] 						   wr_req_fifo_fill_level;
   wire [XX_DESC_IDX_WIDTH:0] 						   wr_req_fifo_free_level;

   wire [XX_MAX_DESC-1:0] 						   wr_req_desc_avail;
   wire                                                                    wr_req_fifo_rden;   //should be one clock cycle pulse
   wire [XX_MAX_DESC-1:0] 						   wr_req_hm2uc_done;

   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_0;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_1;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_2;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_3;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_4;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_5;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_6;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_7;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_8;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_9;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_A;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_B;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_C;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_D;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_E;
   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_F;

   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_0;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_1;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_2;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_3;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_4;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_5;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_6;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_7;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_8;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_9;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_A;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_B;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_C;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_D;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_E;
   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_F;

   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_0;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_1;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_2;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_3;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_4;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_5;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_6;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_7;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_8;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_9;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_A;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_B;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_C;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_D;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_E;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_req_tr_descbus_dtoffset_F;


   wire [WR_REQ_TR_DESCBUS_WIDTH-1 :0] 					   wr_req_tr_descbus_n[XX_MAX_DESC-1:0];

   wire [AW_REQ_TR_DESCBUS_WIDTH-1 :0] 					   aw_req_tr_descbus_n[XX_MAX_DESC-1:0];
   
   wire [XX_MAX_DESC-1:0] 						   wr_req_txn_type_wr_strb;

   //wire wr_req_fifo_pop_desc_conn_pulse;
   reg 									   wr_req_fifo_pop_desc_conn_pulse;

   reg 									   wr_req_fifo_pop_desc_conn_ff;

   assign int_wr_req_fifo_pop_desc_valid = 'b0;
   assign int_wr_req_fifo_pop_desc_desc_index = 'b0;

   
   `FF_RSTLOW(clk,resetn,wr_req_fifo_pop_desc_conn,wr_req_fifo_pop_desc_conn_ff)

   //assign wr_req_fifo_pop_desc_conn_pulse = ( (wr_req_fifo_pop_desc_conn) & (~wr_req_fifo_pop_desc_conn_ff) );

   assign wr_req_fifo_out = wr_req_fifo_dout; 
   assign wr_req_fifo_out_valid = wr_req_fifo_dout_valid;

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 wr_req_fifo_pop_desc_conn_pulse <= 1'b0;
      end else if (wr_req_fifo_pop_desc_conn==1'b1 && wr_req_fifo_pop_desc_conn_ff==1'b0) begin //Positive edge detection
	 wr_req_fifo_pop_desc_conn_pulse <= 1'b1;
      end else begin
	 wr_req_fifo_pop_desc_conn_pulse <= 1'b0;
      end
   end



   assign aw_req_infbus                                                    = {   s_ace_usr_awid 
										 , s_ace_usr_awaddr 
										 , s_ace_usr_awlen 
										 , s_ace_usr_awsize 
										 , s_ace_usr_awburst 
										 , s_ace_usr_awlock 
										 , s_ace_usr_awcache 
										 , s_ace_usr_awprot 
										 , s_ace_usr_awqos 
										 , s_ace_usr_awregion 
										 , s_ace_usr_awuser 
										 , s_ace_usr_awsnoop 
										 , s_ace_usr_awdomain 
										 , s_ace_usr_awbar 
										 , s_ace_usr_awunique
										 };
   assign wr_req_infbus                                                    = {   s_ace_usr_wdata
										 , s_ace_usr_wstrb 
										 , s_ace_usr_wuser
										 };



   assign wr_req_tr_descbus_n['h0] = wr_req_tr_descbus_0;
   assign wr_req_tr_descbus_n['h1] = wr_req_tr_descbus_1;
   assign wr_req_tr_descbus_n['h2] = wr_req_tr_descbus_2;
   assign wr_req_tr_descbus_n['h3] = wr_req_tr_descbus_3;
   assign wr_req_tr_descbus_n['h4] = wr_req_tr_descbus_4;
   assign wr_req_tr_descbus_n['h5] = wr_req_tr_descbus_5;
   assign wr_req_tr_descbus_n['h6] = wr_req_tr_descbus_6;
   assign wr_req_tr_descbus_n['h7] = wr_req_tr_descbus_7;
   assign wr_req_tr_descbus_n['h8] = wr_req_tr_descbus_8;
   assign wr_req_tr_descbus_n['h9] = wr_req_tr_descbus_9;
   assign wr_req_tr_descbus_n['hA] = wr_req_tr_descbus_A;
   assign wr_req_tr_descbus_n['hB] = wr_req_tr_descbus_B;
   assign wr_req_tr_descbus_n['hC] = wr_req_tr_descbus_C;
   assign wr_req_tr_descbus_n['hD] = wr_req_tr_descbus_D;
   assign wr_req_tr_descbus_n['hE] = wr_req_tr_descbus_E;
   assign wr_req_tr_descbus_n['hF] = wr_req_tr_descbus_F;

   assign aw_req_tr_descbus_n['h0] = aw_req_tr_descbus_0;
   assign aw_req_tr_descbus_n['h1] = aw_req_tr_descbus_1;
   assign aw_req_tr_descbus_n['h2] = aw_req_tr_descbus_2;
   assign aw_req_tr_descbus_n['h3] = aw_req_tr_descbus_3;
   assign aw_req_tr_descbus_n['h4] = aw_req_tr_descbus_4;
   assign aw_req_tr_descbus_n['h5] = aw_req_tr_descbus_5;
   assign aw_req_tr_descbus_n['h6] = aw_req_tr_descbus_6;
   assign aw_req_tr_descbus_n['h7] = aw_req_tr_descbus_7;
   assign aw_req_tr_descbus_n['h8] = aw_req_tr_descbus_8;
   assign aw_req_tr_descbus_n['h9] = aw_req_tr_descbus_9;
   assign aw_req_tr_descbus_n['hA] = aw_req_tr_descbus_A;
   assign aw_req_tr_descbus_n['hB] = aw_req_tr_descbus_B;
   assign aw_req_tr_descbus_n['hC] = aw_req_tr_descbus_C;
   assign aw_req_tr_descbus_n['hD] = aw_req_tr_descbus_D;
   assign aw_req_tr_descbus_n['hE] = aw_req_tr_descbus_E;
   assign aw_req_tr_descbus_n['hF] = aw_req_tr_descbus_F;

   assign int_wr_req_desc_n_data_offset_addr['h0] = (wr_req_tr_descbus_dtoffset_0);
   assign int_wr_req_desc_n_data_offset_addr['h1] = (wr_req_tr_descbus_dtoffset_1);
   assign int_wr_req_desc_n_data_offset_addr['h2] = (wr_req_tr_descbus_dtoffset_2);
   assign int_wr_req_desc_n_data_offset_addr['h3] = (wr_req_tr_descbus_dtoffset_3);
   assign int_wr_req_desc_n_data_offset_addr['h4] = (wr_req_tr_descbus_dtoffset_4);
   assign int_wr_req_desc_n_data_offset_addr['h5] = (wr_req_tr_descbus_dtoffset_5);
   assign int_wr_req_desc_n_data_offset_addr['h6] = (wr_req_tr_descbus_dtoffset_6);
   assign int_wr_req_desc_n_data_offset_addr['h7] = (wr_req_tr_descbus_dtoffset_7);
   assign int_wr_req_desc_n_data_offset_addr['h8] = (wr_req_tr_descbus_dtoffset_8);
   assign int_wr_req_desc_n_data_offset_addr['h9] = (wr_req_tr_descbus_dtoffset_9);
   assign int_wr_req_desc_n_data_offset_addr['hA] = (wr_req_tr_descbus_dtoffset_A);
   assign int_wr_req_desc_n_data_offset_addr['hB] = (wr_req_tr_descbus_dtoffset_B);
   assign int_wr_req_desc_n_data_offset_addr['hC] = (wr_req_tr_descbus_dtoffset_C);
   assign int_wr_req_desc_n_data_offset_addr['hD] = (wr_req_tr_descbus_dtoffset_D);
   assign int_wr_req_desc_n_data_offset_addr['hE] = (wr_req_tr_descbus_dtoffset_E);
   assign int_wr_req_desc_n_data_offset_addr['hF] = (wr_req_tr_descbus_dtoffset_F);

   generate

      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_int_wr_req_desc

	 assign int_wr_req_desc_n_wuser_0_wuser[gi][31:0]	  = { {(32-WUSER_WIDTH){1'b0}} , wr_req_tr_descbus_n[gi][(0) +: (WUSER_WIDTH)] };
      end
   endgenerate

   
   generate

      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_int_aw_req_desc

	 assign int_wr_req_desc_n_axid_0_axid[gi][31:0]	  = { {(32-ID_WIDTH){1'b0}} , aw_req_tr_descbus_n[gi][(AW_REQ_TR_DESCBUS_WIDTH-1) -: (ID_WIDTH)] };
	 assign {int_wr_req_desc_n_axaddr_1_addr[gi][31:0],int_wr_req_desc_n_axaddr_0_addr[gi][31:0]} =
												       { {(64-ADDR_WIDTH){1'b0}} , aw_req_tr_descbus_n[gi][(AW_REQ_TR_DESCBUS_WIDTH-ID_WIDTH-1) -: (ADDR_WIDTH)] };				
	 assign int_wr_req_desc_n_size_txn_size[gi][31:0]	  = ((aw_req_tr_descbus_n[gi][(AW_REQ_TR_DESCBUS_WIDTH-ID_WIDTH-ADDR_WIDTH-1) -: (AXLEN_WIDTH)]+1)*XX_DATA_WIDTH/8);
	 ;				
	 
	 
	 assign {int_wr_req_desc_n_axsize_axsize[gi][2:0],int_wr_req_desc_n_attr_axburst[gi][1:0],int_wr_req_desc_n_attr_axlock[gi][0:0],int_wr_req_desc_n_attr_axcache[gi][3:0],int_wr_req_desc_n_attr_axprot[gi][2:0],int_wr_req_desc_n_attr_axqos[gi][3:0],int_wr_req_desc_n_attr_axregion[gi][3:0]} 
           = aw_req_tr_descbus_n[gi][(AW_REQ_TR_DESCBUS_WIDTH-ID_WIDTH-ADDR_WIDTH-AXLEN_WIDTH-1) -: (AXSIZE_WIDTH +AXBURST_WIDTH +AXLOCK_WIDTH +AXCACHE_WIDTH +AXPROT_WIDTH +AXQOS_WIDTH +AXREGION_WIDTH)];
	 
	 
	 assign int_wr_req_desc_n_axuser_0_axuser[gi][31:0]	  = { {(32-AWUSER_WIDTH){1'b0}} , aw_req_tr_descbus_n[gi][(AWSNOOP_WIDTH+AXDOMAIN_WIDTH+AXBAR_WIDTH+AWUNIQUE_WIDTH) +: (AWUSER_WIDTH)] };				
	 
	 
	 assign int_wr_req_desc_n_attr_axsnoop[gi][3] = 'b0;   

	 assign {int_wr_req_desc_n_attr_axsnoop[gi][2:0],int_wr_req_desc_n_attr_axdomain[gi][1:0],int_wr_req_desc_n_attr_axbar[gi][1:0],int_wr_req_desc_n_attr_awunique[gi][0:0]}
           = aw_req_tr_descbus_n[gi][(0) +: (AWSNOOP_WIDTH+AXDOMAIN_WIDTH+AXBAR_WIDTH+AWUNIQUE_WIDTH)];
	 
	 
      end
   endgenerate

   generate 
      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_int_wr_req_desc_n_txn_type_wr_strb

	 assign int_wr_req_desc_n_txn_type_wr_strb[gi]  = wr_req_txn_type_wr_strb[gi];

      end
   endgenerate

   assign wr_req_desc_avail = int_wr_req_free_desc_desc[XX_MAX_DESC-1:0];

   assign wr_req_fifo_rden = wr_req_fifo_pop_desc_conn_pulse;

   assign wr_req_hm2uc_done = {XX_MAX_DESC{1'b0}};

   assign int_wr_req_fifo_fill_level_fill = wr_req_fifo_fill_level;

   ace_ctrl_ready #(
                    // Parameters
                    .ACE_PROTOCOL           (ACE_PROTOCOL),
                    .ACE_CHANNEL            ("SLV_WR_REQ"),
                    .ADDR_WIDTH             (ADDR_WIDTH),
                    .DATA_WIDTH             (XX_DATA_WIDTH),
                    .ID_WIDTH               (ID_WIDTH),
                    .AWUSER_WIDTH           (AWUSER_WIDTH),
                    .WUSER_WIDTH            (WUSER_WIDTH),
                    .BUSER_WIDTH            (BUSER_WIDTH),
                    .ARUSER_WIDTH           (ARUSER_WIDTH),
                    .RUSER_WIDTH            (RUSER_WIDTH),
                    .INFBUS_WIDTH           (WR_REQ_INFBUS_WIDTH),
                    .TR_DESCBUS_WIDTH       (WR_REQ_TR_DESCBUS_WIDTH),
                    .AW_INFBUS_WIDTH        (AW_REQ_INFBUS_WIDTH),
                    .AW_TR_DESCBUS_WIDTH    (AW_REQ_TR_DESCBUS_WIDTH),
                    .CACHE_LINE_SIZE        (CACHE_LINE_SIZE),
                    .MAX_DESC               (XX_MAX_DESC),
                    .RAM_SIZE               (XX_RAM_SIZE)
		    ) aw_w_ace_ctrl_ready (
					   // Outputs
					   .infbus_ready         (s_ace_usr_wready),
					   .inf_xack             (),
					   .aw_infbus_ready      (s_ace_usr_awready),
					   .txn_type_wr_strb     (wr_req_txn_type_wr_strb),
					   .error_status         (wlast_error_status),
					   .tr_descbus_0         (wr_req_tr_descbus_0),
					   .tr_descbus_1         (wr_req_tr_descbus_1),
					   .tr_descbus_2         (wr_req_tr_descbus_2),
					   .tr_descbus_3         (wr_req_tr_descbus_3),
					   .tr_descbus_4         (wr_req_tr_descbus_4),
					   .tr_descbus_5         (wr_req_tr_descbus_5),
					   .tr_descbus_6         (wr_req_tr_descbus_6),
					   .tr_descbus_7         (wr_req_tr_descbus_7),
					   .tr_descbus_8         (wr_req_tr_descbus_8),
					   .tr_descbus_9         (wr_req_tr_descbus_9),
					   .tr_descbus_A         (wr_req_tr_descbus_A),
					   .tr_descbus_B         (wr_req_tr_descbus_B),
					   .tr_descbus_C         (wr_req_tr_descbus_C),
					   .tr_descbus_D         (wr_req_tr_descbus_D),
					   .tr_descbus_E         (wr_req_tr_descbus_E),
					   .tr_descbus_F         (wr_req_tr_descbus_F),
					   .aw_tr_descbus_0      (aw_req_tr_descbus_0),
					   .aw_tr_descbus_1      (aw_req_tr_descbus_1),
					   .aw_tr_descbus_2      (aw_req_tr_descbus_2),
					   .aw_tr_descbus_3      (aw_req_tr_descbus_3),
					   .aw_tr_descbus_4      (aw_req_tr_descbus_4),
					   .aw_tr_descbus_5      (aw_req_tr_descbus_5),
					   .aw_tr_descbus_6      (aw_req_tr_descbus_6),
					   .aw_tr_descbus_7      (aw_req_tr_descbus_7),
					   .aw_tr_descbus_8      (aw_req_tr_descbus_8),
					   .aw_tr_descbus_9      (aw_req_tr_descbus_9),
					   .aw_tr_descbus_A      (aw_req_tr_descbus_A),
					   .aw_tr_descbus_B      (aw_req_tr_descbus_B),
					   .aw_tr_descbus_C      (aw_req_tr_descbus_C),
					   .aw_tr_descbus_D      (aw_req_tr_descbus_D),
					   .aw_tr_descbus_E      (aw_req_tr_descbus_E),
					   .aw_tr_descbus_F      (aw_req_tr_descbus_F),
					   .tr_descbus_dtoffset_0(wr_req_tr_descbus_dtoffset_0),
					   .tr_descbus_dtoffset_1(wr_req_tr_descbus_dtoffset_1),
					   .tr_descbus_dtoffset_2(wr_req_tr_descbus_dtoffset_2),
					   .tr_descbus_dtoffset_3(wr_req_tr_descbus_dtoffset_3),
					   .tr_descbus_dtoffset_4(wr_req_tr_descbus_dtoffset_4),
					   .tr_descbus_dtoffset_5(wr_req_tr_descbus_dtoffset_5),
					   .tr_descbus_dtoffset_6(wr_req_tr_descbus_dtoffset_6),
					   .tr_descbus_dtoffset_7(wr_req_tr_descbus_dtoffset_7),
					   .tr_descbus_dtoffset_8(wr_req_tr_descbus_dtoffset_8),
					   .tr_descbus_dtoffset_9(wr_req_tr_descbus_dtoffset_9),
					   .tr_descbus_dtoffset_A(wr_req_tr_descbus_dtoffset_A),
					   .tr_descbus_dtoffset_B(wr_req_tr_descbus_dtoffset_B),
					   .tr_descbus_dtoffset_C(wr_req_tr_descbus_dtoffset_C),
					   .tr_descbus_dtoffset_D(wr_req_tr_descbus_dtoffset_D),
					   .tr_descbus_dtoffset_E(wr_req_tr_descbus_dtoffset_E),
					   .tr_descbus_dtoffset_F(wr_req_tr_descbus_dtoffset_F),
					   .fifo_dout            (wr_req_fifo_dout),            
					   .fifo_dout_valid      (wr_req_fifo_dout_valid),      
					   .fifo_fill_level      (wr_req_fifo_fill_level),
					   .fifo_free_level      (wr_req_fifo_free_level),
					   .uc2rb_we             (uc2rb_wr_we),
					   .uc2rb_bwe            (uc2rb_wr_bwe),
					   .uc2rb_addr           (uc2rb_wr_addr),
					   .uc2rb_data           (uc2rb_wr_data),
					   .uc2rb_wstrb          (uc2rb_wr_wstrb),
					   .uc2hm_trig           (wr_uc2hm_trig),
					   // Inputs
					   .clk                  (clk),
					   .resetn               (resetn),
					   .infbus               (wr_req_infbus),  //w channel
					   .infbus_last          (s_ace_usr_wlast),
					   .infbus_valid         (s_ace_usr_wvalid),
					   .aw_infbus            (aw_req_infbus),  //aw channel
					   .aw_infbus_len        (s_ace_usr_awlen),
					   .aw_infbus_id         (s_ace_usr_awid),
					   .aw_infbus_valid      (s_ace_usr_awvalid),
					   .int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					   .error_clear          (int_intr_error_clear_clr_err_0),
					   .desc_avail           (wr_req_desc_avail),
					   .fifo_rden            (wr_req_fifo_rden),
					   .hm2uc_done           (wr_hm2uc_done)
					   );
   
   ///////////////////////
     //B-Channel
   //Description :
   //////////////////////
   
   localparam WR_RESP_INFBUS_WIDTH                                         = {   ID_WIDTH
										 + BRESP_WIDTH
										 + BUSER_WIDTH
										 };

   localparam WR_RESP_FR_DESCBUS_WIDTH                                     = WR_RESP_INFBUS_WIDTH;

   wire [WR_RESP_INFBUS_WIDTH-1:0]                                         wr_resp_infbus;

   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_n[XX_MAX_DESC-1:0];

   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_0;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_1;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_2;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_3;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_4;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_5;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_6;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_7;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_8;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_9;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_A;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_B;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_C;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_D;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_E;
   wire [WR_RESP_FR_DESCBUS_WIDTH-1 :0] 				   wr_resp_fr_descbus_F;

   wire [7:0] 								   wr_resp_fr_descbus_len_0;
   wire [7:0] 								   wr_resp_fr_descbus_len_1;
   wire [7:0] 								   wr_resp_fr_descbus_len_2;
   wire [7:0] 								   wr_resp_fr_descbus_len_3;
   wire [7:0] 								   wr_resp_fr_descbus_len_4;
   wire [7:0] 								   wr_resp_fr_descbus_len_5;
   wire [7:0] 								   wr_resp_fr_descbus_len_6;
   wire [7:0] 								   wr_resp_fr_descbus_len_7;
   wire [7:0] 								   wr_resp_fr_descbus_len_8;
   wire [7:0] 								   wr_resp_fr_descbus_len_9;
   wire [7:0] 								   wr_resp_fr_descbus_len_A;
   wire [7:0] 								   wr_resp_fr_descbus_len_B;
   wire [7:0] 								   wr_resp_fr_descbus_len_C;
   wire [7:0] 								   wr_resp_fr_descbus_len_D;
   wire [7:0] 								   wr_resp_fr_descbus_len_E;
   wire [7:0] 								   wr_resp_fr_descbus_len_F;

   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_0;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_1;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_2;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_3;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_4;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_5;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_6;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_7;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_8;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_9;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_A;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_B;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_C;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_D;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_E;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_resp_fr_descbus_dtoffset_F;

   wire [XX_DESC_IDX_WIDTH:0] 						   wr_resp_fifo_fill_level;
   wire [XX_DESC_IDX_WIDTH:0] 						   wr_resp_fifo_free_level;

   wire [XX_MAX_DESC-1:0] 						   wr_resp_intr_comp_status_comp;

   reg                                                                     wr_resp_fifo_wren;
   wire [XX_DESC_IDX_WIDTH-1:0] 					   wr_resp_fifo_din;

   reg                                                                     wr_resp_push;
   reg                                                                     wr_resp_push_ff;

   assign int_wr_resp_fifo_free_level_free = wr_resp_fifo_free_level;

   `FF_RSTLOW(clk,resetn,int_wr_resp_fifo_push_desc_valid,wr_resp_push)
   `FF_RSTLOW(clk,resetn,wr_resp_push,wr_resp_push_ff)

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 wr_resp_fifo_wren <= 1'b0;  
      end else if (wr_resp_push==1'b1 && wr_resp_push_ff==1'b0) begin //Positive edge detection
	 wr_resp_fifo_wren <= 1'b1;
      end else begin
	 wr_resp_fifo_wren <= 1'b0;
      end
   end

   synchronizer#(
		 .SYNC_FF                                                       (2)  
		 ,.D_WIDTH                                                       (XX_DESC_IDX_WIDTH)
		 ) sync_wr_resp_fifo_din (
					  .ck                                                           (clk) 
					  ,.rn                                                           (resetn) 
					  ,.data_in                                                      (int_wr_resp_fifo_push_desc_desc_index) 
					  ,.q_out                                                        (wr_resp_fifo_din)
					  );   




   assign int_wr_resp_intr_comp_status_comp = wr_resp_intr_comp_status_comp;

   assign {   s_ace_usr_bid
              , s_ace_usr_bresp
              , s_ace_usr_buser
	      }                        = wr_resp_infbus;

   assign wr_resp_fr_descbus_0 = wr_resp_fr_descbus_n['h0];
   assign wr_resp_fr_descbus_1 = wr_resp_fr_descbus_n['h1];
   assign wr_resp_fr_descbus_2 = wr_resp_fr_descbus_n['h2];
   assign wr_resp_fr_descbus_3 = wr_resp_fr_descbus_n['h3];
   assign wr_resp_fr_descbus_4 = wr_resp_fr_descbus_n['h4];
   assign wr_resp_fr_descbus_5 = wr_resp_fr_descbus_n['h5];
   assign wr_resp_fr_descbus_6 = wr_resp_fr_descbus_n['h6];
   assign wr_resp_fr_descbus_7 = wr_resp_fr_descbus_n['h7];
   assign wr_resp_fr_descbus_8 = wr_resp_fr_descbus_n['h8];
   assign wr_resp_fr_descbus_9 = wr_resp_fr_descbus_n['h9];
   assign wr_resp_fr_descbus_A = wr_resp_fr_descbus_n['hA];
   assign wr_resp_fr_descbus_B = wr_resp_fr_descbus_n['hB];
   assign wr_resp_fr_descbus_C = wr_resp_fr_descbus_n['hC];
   assign wr_resp_fr_descbus_D = wr_resp_fr_descbus_n['hD];
   assign wr_resp_fr_descbus_E = wr_resp_fr_descbus_n['hE];
   assign wr_resp_fr_descbus_F = wr_resp_fr_descbus_n['hF];


   generate
      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_wr_resp_fr_descbus_n

	 assign wr_resp_fr_descbus_n[gi] = {   int_wr_resp_desc_n_xid_0_xid[gi][(0) +: (ID_WIDTH)]
					       , int_wr_resp_desc_n_resp_resp[gi][(0) +: (BRESP_WIDTH)] 
					       , int_wr_resp_desc_n_xuser_0_xuser[gi][(0) +: (BUSER_WIDTH)] 
					       };

      end
   endgenerate
   
   assign wr_resp_fr_descbus_len_0 = 'b0;
   assign wr_resp_fr_descbus_len_1 = 'b0;
   assign wr_resp_fr_descbus_len_2 = 'b0;
   assign wr_resp_fr_descbus_len_3 = 'b0;
   assign wr_resp_fr_descbus_len_4 = 'b0;
   assign wr_resp_fr_descbus_len_5 = 'b0;
   assign wr_resp_fr_descbus_len_6 = 'b0;
   assign wr_resp_fr_descbus_len_7 = 'b0;
   assign wr_resp_fr_descbus_len_8 = 'b0;
   assign wr_resp_fr_descbus_len_9 = 'b0;
   assign wr_resp_fr_descbus_len_A = 'b0;
   assign wr_resp_fr_descbus_len_B = 'b0;
   assign wr_resp_fr_descbus_len_C = 'b0;
   assign wr_resp_fr_descbus_len_D = 'b0;
   assign wr_resp_fr_descbus_len_E = 'b0;
   assign wr_resp_fr_descbus_len_F = 'b0;

   assign wr_resp_fr_descbus_dtoffset_0 = 'b0;
   assign wr_resp_fr_descbus_dtoffset_1 = 'b0;
   assign wr_resp_fr_descbus_dtoffset_2 = 'b0;
   assign wr_resp_fr_descbus_dtoffset_3 = 'b0;
   assign wr_resp_fr_descbus_dtoffset_4 = 'b0;
   assign wr_resp_fr_descbus_dtoffset_5 = 'b0;
   assign wr_resp_fr_descbus_dtoffset_6 = 'b0;
   assign wr_resp_fr_descbus_dtoffset_7 = 'b0;
   assign wr_resp_fr_descbus_dtoffset_8 = 'b0;
   assign wr_resp_fr_descbus_dtoffset_9 = 'b0;
   assign wr_resp_fr_descbus_dtoffset_A = 'b0;
   assign wr_resp_fr_descbus_dtoffset_B = 'b0;
   assign wr_resp_fr_descbus_dtoffset_C = 'b0;
   assign wr_resp_fr_descbus_dtoffset_D = 'b0;
   assign wr_resp_fr_descbus_dtoffset_E = 'b0;
   assign wr_resp_fr_descbus_dtoffset_F = 'b0;

   ace_ctrl_valid #(
                    // Parameters
                    .ACE_PROTOCOL          (ACE_PROTOCOL),
                    .ACE_CHANNEL           ("SLV_WR_RESP"),
                    .ADDR_WIDTH            (ADDR_WIDTH),
                    .DATA_WIDTH            (XX_DATA_WIDTH),
                    .ID_WIDTH              (ID_WIDTH),
                    .AWUSER_WIDTH          (AWUSER_WIDTH),
                    .WUSER_WIDTH           (WUSER_WIDTH),
                    .BUSER_WIDTH           (BUSER_WIDTH),
                    .ARUSER_WIDTH          (ARUSER_WIDTH),
                    .RUSER_WIDTH           (RUSER_WIDTH),
                    .INFBUS_WIDTH          (WR_RESP_INFBUS_WIDTH),
                    .FR_DESCBUS_WIDTH      (WR_RESP_FR_DESCBUS_WIDTH),
                    .CACHE_LINE_SIZE       (CACHE_LINE_SIZE),
                    .MAX_DESC              (XX_MAX_DESC),
                    .RAM_SIZE              (XX_RAM_SIZE)
		    ) b_ace_ctrl_valid (
					// Outputs
					.infbus               (wr_resp_infbus),  //b channel
					.infbus_last          (),
					.infbus_valid         (s_ace_usr_bvalid),
					.fifo_fill_level      (wr_resp_fifo_fill_level),
					.fifo_free_level      (wr_resp_fifo_free_level),
					.intr_comp_status_comp(wr_resp_intr_comp_status_comp),
					.uc2rb_addr           (),
					.uc2hm_trig           (),
					// Inputs
					.clk                  (clk),
					.resetn               (resetn),
					.infbus_ready         (s_ace_usr_bready),
					.inf_xack             (s_ace_usr_wack),
					.fr_descbus_0         (wr_resp_fr_descbus_0),
					.fr_descbus_1         (wr_resp_fr_descbus_1),
					.fr_descbus_2         (wr_resp_fr_descbus_2),
					.fr_descbus_3         (wr_resp_fr_descbus_3),
					.fr_descbus_4         (wr_resp_fr_descbus_4),
					.fr_descbus_5         (wr_resp_fr_descbus_5),
					.fr_descbus_6         (wr_resp_fr_descbus_6),
					.fr_descbus_7         (wr_resp_fr_descbus_7),
					.fr_descbus_8         (wr_resp_fr_descbus_8),
					.fr_descbus_9         (wr_resp_fr_descbus_9),
					.fr_descbus_A         (wr_resp_fr_descbus_A),
					.fr_descbus_B         (wr_resp_fr_descbus_B),
					.fr_descbus_C         (wr_resp_fr_descbus_C),
					.fr_descbus_D         (wr_resp_fr_descbus_D),
					.fr_descbus_E         (wr_resp_fr_descbus_E),
					.fr_descbus_F         (wr_resp_fr_descbus_F),
					.fr_descbus_len_0     (wr_resp_fr_descbus_len_0),
					.fr_descbus_len_1     (wr_resp_fr_descbus_len_1),
					.fr_descbus_len_2     (wr_resp_fr_descbus_len_2),
					.fr_descbus_len_3     (wr_resp_fr_descbus_len_3),
					.fr_descbus_len_4     (wr_resp_fr_descbus_len_4),
					.fr_descbus_len_5     (wr_resp_fr_descbus_len_5),
					.fr_descbus_len_6     (wr_resp_fr_descbus_len_6),
					.fr_descbus_len_7     (wr_resp_fr_descbus_len_7),
					.fr_descbus_len_8     (wr_resp_fr_descbus_len_8),
					.fr_descbus_len_9     (wr_resp_fr_descbus_len_9),
					.fr_descbus_len_A     (wr_resp_fr_descbus_len_A),
					.fr_descbus_len_B     (wr_resp_fr_descbus_len_B),
					.fr_descbus_len_C     (wr_resp_fr_descbus_len_C),
					.fr_descbus_len_D     (wr_resp_fr_descbus_len_D),
					.fr_descbus_len_E     (wr_resp_fr_descbus_len_E),
					.fr_descbus_len_F     (wr_resp_fr_descbus_len_F),
					.fr_descbus_dtoffset_0(wr_resp_fr_descbus_dtoffset_0),
					.fr_descbus_dtoffset_1(wr_resp_fr_descbus_dtoffset_1),
					.fr_descbus_dtoffset_2(wr_resp_fr_descbus_dtoffset_2),
					.fr_descbus_dtoffset_3(wr_resp_fr_descbus_dtoffset_3),
					.fr_descbus_dtoffset_4(wr_resp_fr_descbus_dtoffset_4),
					.fr_descbus_dtoffset_5(wr_resp_fr_descbus_dtoffset_5),
					.fr_descbus_dtoffset_6(wr_resp_fr_descbus_dtoffset_6),
					.fr_descbus_dtoffset_7(wr_resp_fr_descbus_dtoffset_7),
					.fr_descbus_dtoffset_8(wr_resp_fr_descbus_dtoffset_8),
					.fr_descbus_dtoffset_9(wr_resp_fr_descbus_dtoffset_9),
					.fr_descbus_dtoffset_A(wr_resp_fr_descbus_dtoffset_A),
					.fr_descbus_dtoffset_B(wr_resp_fr_descbus_dtoffset_B),
					.fr_descbus_dtoffset_C(wr_resp_fr_descbus_dtoffset_C),
					.fr_descbus_dtoffset_D(wr_resp_fr_descbus_dtoffset_D),
					.fr_descbus_dtoffset_E(wr_resp_fr_descbus_dtoffset_E),
					.fr_descbus_dtoffset_F(wr_resp_fr_descbus_dtoffset_F),
					.int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					.fifo_wren            (wr_resp_fifo_wren),
					.fifo_din             (wr_resp_fifo_din),
					.intr_comp_clear_clr_comp(int_wr_resp_intr_comp_clear_clr_comp),
					.rb2uc_data           ({XX_DATA_WIDTH{1'b0}}),
					.rb2uc_wstrb          ({WSTRB_WIDTH{1'b0}}),
					.hm2uc_done           ({XX_MAX_DESC{1'b0}})
					);
   

   ///////////////////////
     //AC-Channel
   //Description :
   //////////////////////

   localparam SN_REQ_INFBUS_WIDTH                                         = {    ADDR_WIDTH 
										 + ACSNOOP_WIDTH
										 + ACPROT_WIDTH
										 };

   localparam SN_REQ_FR_DESCBUS_WIDTH                                     = SN_REQ_INFBUS_WIDTH;

   wire [SN_REQ_INFBUS_WIDTH-1:0]                                         sn_req_infbus;

   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_n[SN_MAX_DESC-1:0];

   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_0;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_1;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_2;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_3;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_4;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_5;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_6;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_7;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_8;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_9;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_A;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_B;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_C;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_D;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_E;
   wire [SN_REQ_FR_DESCBUS_WIDTH-1 :0] 					  sn_req_fr_descbus_F;

   wire [7:0] 								  sn_req_fr_descbus_len_0;
   wire [7:0] 								  sn_req_fr_descbus_len_1;
   wire [7:0] 								  sn_req_fr_descbus_len_2;
   wire [7:0] 								  sn_req_fr_descbus_len_3;
   wire [7:0] 								  sn_req_fr_descbus_len_4;
   wire [7:0] 								  sn_req_fr_descbus_len_5;
   wire [7:0] 								  sn_req_fr_descbus_len_6;
   wire [7:0] 								  sn_req_fr_descbus_len_7;
   wire [7:0] 								  sn_req_fr_descbus_len_8;
   wire [7:0] 								  sn_req_fr_descbus_len_9;
   wire [7:0] 								  sn_req_fr_descbus_len_A;
   wire [7:0] 								  sn_req_fr_descbus_len_B;
   wire [7:0] 								  sn_req_fr_descbus_len_C;
   wire [7:0] 								  sn_req_fr_descbus_len_D;
   wire [7:0] 								  sn_req_fr_descbus_len_E;
   wire [7:0] 								  sn_req_fr_descbus_len_F;

   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_0;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_1;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_2;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_3;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_4;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_5;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_6;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_7;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_8;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_9;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_A;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_B;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_C;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_D;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_E;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					  sn_req_fr_descbus_dtoffset_F;

   wire [SN_DESC_IDX_WIDTH:0] 						  sn_req_fifo_fill_level;
   wire [SN_DESC_IDX_WIDTH:0] 						  sn_req_fifo_free_level;

   wire [SN_MAX_DESC-1:0] 						  sn_req_intr_comp_status_comp;

   reg 									  sn_req_fifo_wren;
   wire [SN_DESC_IDX_WIDTH-1:0] 					  sn_req_fifo_din;

   reg 									  sn_req_push;
   reg 									  sn_req_push_ff;

   wire [63:0] 								  fr_acaddr[SN_MAX_DESC-1:0];


   assign int_sn_req_fifo_free_level_free = sn_req_fifo_free_level;

   `FF_RSTLOW(clk,resetn,int_sn_req_fifo_push_desc_valid,sn_req_push)
   `FF_RSTLOW(clk,resetn,sn_req_push,sn_req_push_ff)

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 sn_req_fifo_wren <= 1'b0;  
      end else if (sn_req_push==1'b1 && sn_req_push_ff==1'b0) begin //Positive edge detection
	 sn_req_fifo_wren <= 1'b1;
      end else begin
	 sn_req_fifo_wren <= 1'b0;
      end
   end

   synchronizer#(
		 .SYNC_FF                                                       (2)  
		 ,.D_WIDTH                                                       (SN_DESC_IDX_WIDTH)
		 ) sync_sn_req_fifo_din (
					 .ck                                                           (clk) 
					 ,.rn                                                           (resetn) 
					 ,.data_in                                                      (int_sn_req_fifo_push_desc_desc_index) 
					 ,.q_out                                                        (sn_req_fifo_din)
					 );   



   assign int_sn_req_intr_comp_status_comp = sn_req_intr_comp_status_comp;

   assign {   s_ace_usr_acaddr
              , s_ace_usr_acsnoop
              , s_ace_usr_acprot
	      }                        = sn_req_infbus;

   assign sn_req_fr_descbus_0 = sn_req_fr_descbus_n['h0];
   assign sn_req_fr_descbus_1 = sn_req_fr_descbus_n['h1];
   assign sn_req_fr_descbus_2 = sn_req_fr_descbus_n['h2];
   assign sn_req_fr_descbus_3 = sn_req_fr_descbus_n['h3];
   assign sn_req_fr_descbus_4 = sn_req_fr_descbus_n['h4];
   assign sn_req_fr_descbus_5 = sn_req_fr_descbus_n['h5];
   assign sn_req_fr_descbus_6 = sn_req_fr_descbus_n['h6];
   assign sn_req_fr_descbus_7 = sn_req_fr_descbus_n['h7];
   assign sn_req_fr_descbus_8 = sn_req_fr_descbus_n['h8];
   assign sn_req_fr_descbus_9 = sn_req_fr_descbus_n['h9];
   assign sn_req_fr_descbus_A = sn_req_fr_descbus_n['hA];
   assign sn_req_fr_descbus_B = sn_req_fr_descbus_n['hB];
   assign sn_req_fr_descbus_C = sn_req_fr_descbus_n['hC];
   assign sn_req_fr_descbus_D = sn_req_fr_descbus_n['hD];
   assign sn_req_fr_descbus_E = sn_req_fr_descbus_n['hE];
   assign sn_req_fr_descbus_F = sn_req_fr_descbus_n['hF];



   generate
      for (gi=0; gi<=SN_MAX_DESC-1; gi=gi+1) begin: gen_sn_req_fr_descbus_n

	 assign fr_acaddr[gi] = {int_sn_req_desc_n_acaddr_1_addr[gi],int_sn_req_desc_n_acaddr_0_addr[gi]};
	 
	 assign sn_req_fr_descbus_n[gi] = {   fr_acaddr[gi][(0) +: (ADDR_WIDTH)]
					      , int_sn_req_desc_n_attr_acsnoop[gi][(0) +: (ACSNOOP_WIDTH)]
					      , int_sn_req_desc_n_attr_acprot[gi][(0) +: (ACPROT_WIDTH)] 
					      };

      end
   endgenerate
   
   assign sn_req_fr_descbus_len_0 = 'b0;
   assign sn_req_fr_descbus_len_1 = 'b0;
   assign sn_req_fr_descbus_len_2 = 'b0;
   assign sn_req_fr_descbus_len_3 = 'b0;
   assign sn_req_fr_descbus_len_4 = 'b0;
   assign sn_req_fr_descbus_len_5 = 'b0;
   assign sn_req_fr_descbus_len_6 = 'b0;
   assign sn_req_fr_descbus_len_7 = 'b0;
   assign sn_req_fr_descbus_len_8 = 'b0;
   assign sn_req_fr_descbus_len_9 = 'b0;
   assign sn_req_fr_descbus_len_A = 'b0;
   assign sn_req_fr_descbus_len_B = 'b0;
   assign sn_req_fr_descbus_len_C = 'b0;
   assign sn_req_fr_descbus_len_D = 'b0;
   assign sn_req_fr_descbus_len_E = 'b0;
   assign sn_req_fr_descbus_len_F = 'b0;

   assign sn_req_fr_descbus_dtoffset_0 = 'b0;
   assign sn_req_fr_descbus_dtoffset_1 = 'b0;
   assign sn_req_fr_descbus_dtoffset_2 = 'b0;
   assign sn_req_fr_descbus_dtoffset_3 = 'b0;
   assign sn_req_fr_descbus_dtoffset_4 = 'b0;
   assign sn_req_fr_descbus_dtoffset_5 = 'b0;
   assign sn_req_fr_descbus_dtoffset_6 = 'b0;
   assign sn_req_fr_descbus_dtoffset_7 = 'b0;
   assign sn_req_fr_descbus_dtoffset_8 = 'b0;
   assign sn_req_fr_descbus_dtoffset_9 = 'b0;
   assign sn_req_fr_descbus_dtoffset_A = 'b0;
   assign sn_req_fr_descbus_dtoffset_B = 'b0;
   assign sn_req_fr_descbus_dtoffset_C = 'b0;
   assign sn_req_fr_descbus_dtoffset_D = 'b0;
   assign sn_req_fr_descbus_dtoffset_E = 'b0;
   assign sn_req_fr_descbus_dtoffset_F = 'b0;

   ace_ctrl_valid #(
                    // Parameters
                    .ACE_PROTOCOL          (ACE_PROTOCOL),
                    .ACE_CHANNEL           ("SLV_SN_REQ"),
                    .ADDR_WIDTH            (ADDR_WIDTH),
                    .DATA_WIDTH            (SN_DATA_WIDTH),
                    .ID_WIDTH              (ID_WIDTH),
                    .AWUSER_WIDTH          (AWUSER_WIDTH),
                    .WUSER_WIDTH           (WUSER_WIDTH),
                    .BUSER_WIDTH           (BUSER_WIDTH),
                    .ARUSER_WIDTH          (ARUSER_WIDTH),
                    .RUSER_WIDTH           (RUSER_WIDTH),
                    .INFBUS_WIDTH          (SN_REQ_INFBUS_WIDTH),
                    .FR_DESCBUS_WIDTH      (SN_REQ_FR_DESCBUS_WIDTH),
                    .CACHE_LINE_SIZE       (CACHE_LINE_SIZE),
                    .MAX_DESC              (SN_MAX_DESC),
                    .RAM_SIZE              (SN_RAM_SIZE)
		    ) ac_ace_ctrl_valid (
					 // Outputs
					 .infbus               (sn_req_infbus),  //ac channel
					 .infbus_last          (),
					 .infbus_valid         (s_ace_usr_acvalid),
					 .fifo_fill_level      (sn_req_fifo_fill_level),
					 .fifo_free_level      (sn_req_fifo_free_level),
					 .intr_comp_status_comp(sn_req_intr_comp_status_comp),
					 .uc2rb_addr           (),
					 .uc2hm_trig           (),
					 // Inputs
					 .clk                  (clk),
					 .resetn               (resetn),
					 .infbus_ready         (s_ace_usr_acready),
					 .inf_xack             (1'b0),
					 .fr_descbus_0         (sn_req_fr_descbus_0),
					 .fr_descbus_1         (sn_req_fr_descbus_1),
					 .fr_descbus_2         (sn_req_fr_descbus_2),
					 .fr_descbus_3         (sn_req_fr_descbus_3),
					 .fr_descbus_4         (sn_req_fr_descbus_4),
					 .fr_descbus_5         (sn_req_fr_descbus_5),
					 .fr_descbus_6         (sn_req_fr_descbus_6),
					 .fr_descbus_7         (sn_req_fr_descbus_7),
					 .fr_descbus_8         (sn_req_fr_descbus_8),
					 .fr_descbus_9         (sn_req_fr_descbus_9),
					 .fr_descbus_A         (sn_req_fr_descbus_A),
					 .fr_descbus_B         (sn_req_fr_descbus_B),
					 .fr_descbus_C         (sn_req_fr_descbus_C),
					 .fr_descbus_D         (sn_req_fr_descbus_D),
					 .fr_descbus_E         (sn_req_fr_descbus_E),
					 .fr_descbus_F         (sn_req_fr_descbus_F),
					 .fr_descbus_len_0     (sn_req_fr_descbus_len_0),
					 .fr_descbus_len_1     (sn_req_fr_descbus_len_1),
					 .fr_descbus_len_2     (sn_req_fr_descbus_len_2),
					 .fr_descbus_len_3     (sn_req_fr_descbus_len_3),
					 .fr_descbus_len_4     (sn_req_fr_descbus_len_4),
					 .fr_descbus_len_5     (sn_req_fr_descbus_len_5),
					 .fr_descbus_len_6     (sn_req_fr_descbus_len_6),
					 .fr_descbus_len_7     (sn_req_fr_descbus_len_7),
					 .fr_descbus_len_8     (sn_req_fr_descbus_len_8),
					 .fr_descbus_len_9     (sn_req_fr_descbus_len_9),
					 .fr_descbus_len_A     (sn_req_fr_descbus_len_A),
					 .fr_descbus_len_B     (sn_req_fr_descbus_len_B),
					 .fr_descbus_len_C     (sn_req_fr_descbus_len_C),
					 .fr_descbus_len_D     (sn_req_fr_descbus_len_D),
					 .fr_descbus_len_E     (sn_req_fr_descbus_len_E),
					 .fr_descbus_len_F     (sn_req_fr_descbus_len_F),
					 .fr_descbus_dtoffset_0(sn_req_fr_descbus_dtoffset_0),
					 .fr_descbus_dtoffset_1(sn_req_fr_descbus_dtoffset_1),
					 .fr_descbus_dtoffset_2(sn_req_fr_descbus_dtoffset_2),
					 .fr_descbus_dtoffset_3(sn_req_fr_descbus_dtoffset_3),
					 .fr_descbus_dtoffset_4(sn_req_fr_descbus_dtoffset_4),
					 .fr_descbus_dtoffset_5(sn_req_fr_descbus_dtoffset_5),
					 .fr_descbus_dtoffset_6(sn_req_fr_descbus_dtoffset_6),
					 .fr_descbus_dtoffset_7(sn_req_fr_descbus_dtoffset_7),
					 .fr_descbus_dtoffset_8(sn_req_fr_descbus_dtoffset_8),
					 .fr_descbus_dtoffset_9(sn_req_fr_descbus_dtoffset_9),
					 .fr_descbus_dtoffset_A(sn_req_fr_descbus_dtoffset_A),
					 .fr_descbus_dtoffset_B(sn_req_fr_descbus_dtoffset_B),
					 .fr_descbus_dtoffset_C(sn_req_fr_descbus_dtoffset_C),
					 .fr_descbus_dtoffset_D(sn_req_fr_descbus_dtoffset_D),
					 .fr_descbus_dtoffset_E(sn_req_fr_descbus_dtoffset_E),
					 .fr_descbus_dtoffset_F(sn_req_fr_descbus_dtoffset_F),
					 .int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					 .fifo_wren            (sn_req_fifo_wren),
					 .fifo_din             (sn_req_fifo_din),
					 .intr_comp_clear_clr_comp(int_sn_req_intr_comp_clear_clr_comp),
					 .rb2uc_data           ({SN_DATA_WIDTH{1'b0}}),
					 .rb2uc_wstrb          ({WSTRB_WIDTH{1'b0}}),
					 .hm2uc_done           ({SN_MAX_DESC{1'b0}})
					 );
   

   ///////////////////////
     //CR-Channel
   //Description :
   //////////////////////
   
   
   localparam SN_RESP_INFBUS_WIDTH                                          = (   CRRESP_WIDTH
										  );


   localparam SN_RESP_TR_DESCBUS_WIDTH                                      = SN_RESP_INFBUS_WIDTH; 

   localparam SN_RESP_AW_INFBUS_WIDTH_DUMMY                                 = 1; 


   wire [SN_RESP_INFBUS_WIDTH-1:0]                                          sn_resp_infbus;

   wire [SN_DESC_IDX_WIDTH-1:0] 					    sn_resp_fifo_dout;
   wire 								    sn_resp_fifo_dout_valid;  //it is one clock cycle pulse
   wire [SN_DESC_IDX_WIDTH:0] 						    sn_resp_fifo_fill_level;
   wire [SN_DESC_IDX_WIDTH:0] 						    sn_resp_fifo_free_level;

   wire [SN_MAX_DESC-1:0] 						    sn_resp_desc_avail;
   wire 								    sn_resp_fifo_rden;   //should be one clock cycle pulse

   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_0;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_1;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_2;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_3;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_4;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_5;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_6;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_7;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_8;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_9;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_A;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_B;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_C;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_D;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_E;
   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_F;

   wire [SN_RESP_TR_DESCBUS_WIDTH-1 :0] 				    sn_resp_tr_descbus_n[SN_MAX_DESC-1:0];
   
   //wire sn_resp_fifo_pop_desc_conn_pulse;
   reg 									    sn_resp_fifo_pop_desc_conn_pulse;

   reg 									    sn_resp_fifo_pop_desc_conn_ff;

   assign int_sn_resp_fifo_pop_desc_valid = 'b0;
   assign int_sn_resp_fifo_pop_desc_desc_index = 'b0;

   `FF_RSTLOW(clk,resetn,sn_resp_fifo_pop_desc_conn,sn_resp_fifo_pop_desc_conn_ff)

   //assign sn_resp_fifo_pop_desc_conn_pulse = ( (sn_resp_fifo_pop_desc_conn) & (~sn_resp_fifo_pop_desc_conn_ff) );

   assign sn_resp_fifo_out = sn_resp_fifo_dout; 
   assign sn_resp_fifo_out_valid = sn_resp_fifo_dout_valid;

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 sn_resp_fifo_pop_desc_conn_pulse <= 1'b0;
      end else if (sn_resp_fifo_pop_desc_conn==1'b1 && sn_resp_fifo_pop_desc_conn_ff==1'b0) begin //Positive edge detection
	 sn_resp_fifo_pop_desc_conn_pulse <= 1'b1;
      end else begin
	 sn_resp_fifo_pop_desc_conn_pulse <= 1'b0;
      end
   end


   assign sn_resp_infbus                                                    = {   s_ace_usr_crresp 
										  };

   assign sn_resp_tr_descbus_n['h0] = sn_resp_tr_descbus_0;
   assign sn_resp_tr_descbus_n['h1] = sn_resp_tr_descbus_1;
   assign sn_resp_tr_descbus_n['h2] = sn_resp_tr_descbus_2;
   assign sn_resp_tr_descbus_n['h3] = sn_resp_tr_descbus_3;
   assign sn_resp_tr_descbus_n['h4] = sn_resp_tr_descbus_4;
   assign sn_resp_tr_descbus_n['h5] = sn_resp_tr_descbus_5;
   assign sn_resp_tr_descbus_n['h6] = sn_resp_tr_descbus_6;
   assign sn_resp_tr_descbus_n['h7] = sn_resp_tr_descbus_7;
   assign sn_resp_tr_descbus_n['h8] = sn_resp_tr_descbus_8;
   assign sn_resp_tr_descbus_n['h9] = sn_resp_tr_descbus_9;
   assign sn_resp_tr_descbus_n['hA] = sn_resp_tr_descbus_A;
   assign sn_resp_tr_descbus_n['hB] = sn_resp_tr_descbus_B;
   assign sn_resp_tr_descbus_n['hC] = sn_resp_tr_descbus_C;
   assign sn_resp_tr_descbus_n['hD] = sn_resp_tr_descbus_D;
   assign sn_resp_tr_descbus_n['hE] = sn_resp_tr_descbus_E;
   assign sn_resp_tr_descbus_n['hF] = sn_resp_tr_descbus_F;

   
   generate

      for (gi=0; gi<=SN_MAX_DESC-1; gi=gi+1) begin: gen_int_sn_resp_desc

	 assign int_sn_resp_desc_n_resp_resp[gi][4:0]	  = sn_resp_tr_descbus_n[gi][(SN_RESP_TR_DESCBUS_WIDTH-1) -: (CRRESP_WIDTH)];
	 
      end
   endgenerate

   assign sn_resp_desc_avail = int_sn_resp_free_desc_desc[SN_MAX_DESC-1:0];

   assign sn_resp_fifo_rden = sn_resp_fifo_pop_desc_conn_pulse;

   assign int_sn_resp_fifo_fill_level_fill = sn_resp_fifo_fill_level;

   ace_ctrl_ready #(
                    // Parameters
                    .ACE_PROTOCOL           (ACE_PROTOCOL),
                    .ACE_CHANNEL            ("SLV_SN_RESP"),
                    .ADDR_WIDTH             (ADDR_WIDTH),
                    .DATA_WIDTH             (SN_DATA_WIDTH),
                    .ID_WIDTH               (ID_WIDTH),
                    .AWUSER_WIDTH           (AWUSER_WIDTH),
                    .WUSER_WIDTH            (WUSER_WIDTH),
                    .BUSER_WIDTH            (BUSER_WIDTH),
                    .ARUSER_WIDTH           (ARUSER_WIDTH),
                    .RUSER_WIDTH            (RUSER_WIDTH),
                    .INFBUS_WIDTH           (SN_RESP_INFBUS_WIDTH),
                    .TR_DESCBUS_WIDTH       (SN_RESP_TR_DESCBUS_WIDTH),
                    .AW_INFBUS_WIDTH        (SN_RESP_AW_INFBUS_WIDTH_DUMMY),
                    .AW_TR_DESCBUS_WIDTH    (1),
                    .CACHE_LINE_SIZE        (CACHE_LINE_SIZE),
                    .MAX_DESC               (SN_MAX_DESC),
                    .RAM_SIZE               (SN_RAM_SIZE)
		    ) cr_ace_ctrl_ready (
					 // Outputs
					 .infbus_ready         (s_ace_usr_crready),
					 .inf_xack             (),
					 .aw_infbus_ready      (),
					 .tr_descbus_0         (sn_resp_tr_descbus_0),
					 .tr_descbus_1         (sn_resp_tr_descbus_1),
					 .tr_descbus_2         (sn_resp_tr_descbus_2),
					 .tr_descbus_3         (sn_resp_tr_descbus_3),
					 .tr_descbus_4         (sn_resp_tr_descbus_4),
					 .tr_descbus_5         (sn_resp_tr_descbus_5),
					 .tr_descbus_6         (sn_resp_tr_descbus_6),
					 .tr_descbus_7         (sn_resp_tr_descbus_7),
					 .tr_descbus_8         (sn_resp_tr_descbus_8),
					 .tr_descbus_9         (sn_resp_tr_descbus_9),
					 .tr_descbus_A         (sn_resp_tr_descbus_A),
					 .tr_descbus_B         (sn_resp_tr_descbus_B),
					 .tr_descbus_C         (sn_resp_tr_descbus_C),
					 .tr_descbus_D         (sn_resp_tr_descbus_D),
					 .tr_descbus_E         (sn_resp_tr_descbus_E),
					 .tr_descbus_F         (sn_resp_tr_descbus_F),
					 .fifo_dout            (sn_resp_fifo_dout),            
					 .fifo_dout_valid      (sn_resp_fifo_dout_valid),      
					 .fifo_fill_level      (sn_resp_fifo_fill_level),
					 .fifo_free_level      (sn_resp_fifo_free_level),
					 .uc2rb_we             (),
					 .uc2rb_bwe            (),
					 .uc2rb_addr           (),
					 .uc2rb_data           (),
					 .uc2rb_wstrb          (),
					 .uc2hm_trig           (),
					 // Inputs
					 .clk                  (clk),
					 .resetn               (resetn),
					 .infbus               (sn_resp_infbus),  //cr channel
					 .infbus_last          (1'b1),
					 .infbus_valid         (s_ace_usr_crvalid),
					 .aw_infbus            ({SN_RESP_AW_INFBUS_WIDTH_DUMMY{1'b0}}),
					 .aw_infbus_len        (8'b0),
					 .aw_infbus_id         ({ID_WIDTH{1'b0}}),
					 .aw_infbus_valid      (1'b0),
					 .int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					 .error_clear          (1'b0),
					 .desc_avail           (sn_resp_desc_avail),
					 .fifo_rden            (sn_resp_fifo_rden),
					 .hm2uc_done           ({SN_MAX_DESC{1'b0}})
					 );
   
   ///////////////////////
     //CD-Channel
   //Description :
   //////////////////////
   
   localparam SN_DATA_AW_INFBUS_WIDTH_DUMMY                                 = 1; 

   localparam SN_DATA_INFBUS_WIDTH                                          = (   SN_DATA_WIDTH
										  );


   localparam SN_DATA_TR_DESCBUS_WIDTH                                      = SN_DATA_INFBUS_WIDTH; 

   wire [SN_DATA_INFBUS_WIDTH-1:0]                                          sn_data_infbus;

   wire [SN_DESC_IDX_WIDTH-1:0] 					    sn_data_fifo_dout;
   wire 								    sn_data_fifo_dout_valid;  //it is one clock cycle pulse
   wire [SN_DESC_IDX_WIDTH:0] 						    sn_data_fifo_fill_level;
   wire [SN_DESC_IDX_WIDTH:0] 						    sn_data_fifo_free_level;

   wire [SN_MAX_DESC-1:0] 						    sn_data_desc_avail;
   wire 								    sn_data_fifo_rden;   //should be one clock cycle pulse
   wire [SN_MAX_DESC-1:0] 						    sn_data_hm2uc_done;

   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_0;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_1;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_2;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_3;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_4;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_5;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_6;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_7;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_8;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_9;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_A;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_B;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_C;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_D;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_E;
   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_F;

   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_0;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_1;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_2;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_3;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_4;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_5;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_6;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_7;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_8;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_9;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_A;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_B;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_C;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_D;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_E;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					    sn_data_tr_descbus_dtoffset_F;


   wire [SN_DATA_TR_DESCBUS_WIDTH-1 :0] 				    sn_data_tr_descbus_n[SN_MAX_DESC-1:0];

   //wire sn_data_fifo_pop_desc_conn_pulse;
   reg 									    sn_data_fifo_pop_desc_conn_pulse;

   reg 									    sn_data_fifo_pop_desc_conn_ff;

   assign int_sn_data_fifo_pop_desc_valid = 'b0;
   assign int_sn_data_fifo_pop_desc_desc_index = 'b0;

   
   `FF_RSTLOW(clk,resetn,sn_data_fifo_pop_desc_conn,sn_data_fifo_pop_desc_conn_ff)

   //assign sn_data_fifo_pop_desc_conn_pulse = ( (sn_data_fifo_pop_desc_conn) & (~sn_data_fifo_pop_desc_conn_ff) );

   assign sn_data_fifo_out = sn_data_fifo_dout; 
   assign sn_data_fifo_out_valid = sn_data_fifo_dout_valid;

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 sn_data_fifo_pop_desc_conn_pulse <= 1'b0;
      end else if (sn_data_fifo_pop_desc_conn==1'b1 && sn_data_fifo_pop_desc_conn_ff==1'b0) begin //Positive edge detection
	 sn_data_fifo_pop_desc_conn_pulse <= 1'b1;
      end else begin
	 sn_data_fifo_pop_desc_conn_pulse <= 1'b0;
      end
   end



   assign sn_data_infbus                                                    = {   s_ace_usr_cddata
										  };



   assign sn_data_tr_descbus_n['h0] = sn_data_tr_descbus_0;
   assign sn_data_tr_descbus_n['h1] = sn_data_tr_descbus_1;
   assign sn_data_tr_descbus_n['h2] = sn_data_tr_descbus_2;
   assign sn_data_tr_descbus_n['h3] = sn_data_tr_descbus_3;
   assign sn_data_tr_descbus_n['h4] = sn_data_tr_descbus_4;
   assign sn_data_tr_descbus_n['h5] = sn_data_tr_descbus_5;
   assign sn_data_tr_descbus_n['h6] = sn_data_tr_descbus_6;
   assign sn_data_tr_descbus_n['h7] = sn_data_tr_descbus_7;
   assign sn_data_tr_descbus_n['h8] = sn_data_tr_descbus_8;
   assign sn_data_tr_descbus_n['h9] = sn_data_tr_descbus_9;
   assign sn_data_tr_descbus_n['hA] = sn_data_tr_descbus_A;
   assign sn_data_tr_descbus_n['hB] = sn_data_tr_descbus_B;
   assign sn_data_tr_descbus_n['hC] = sn_data_tr_descbus_C;
   assign sn_data_tr_descbus_n['hD] = sn_data_tr_descbus_D;
   assign sn_data_tr_descbus_n['hE] = sn_data_tr_descbus_E;
   assign sn_data_tr_descbus_n['hF] = sn_data_tr_descbus_F;

   assign sn_data_desc_avail = int_sn_data_free_desc_desc[SN_MAX_DESC-1:0];

   assign sn_data_fifo_rden = sn_data_fifo_pop_desc_conn_pulse;

   assign sn_data_hm2uc_done = {SN_MAX_DESC{1'b0}};

   assign int_sn_data_fifo_fill_level_fill = sn_data_fifo_fill_level;

   ace_ctrl_ready #(
                    // Parameters
                    .ACE_PROTOCOL           (ACE_PROTOCOL),
                    .ACE_CHANNEL            ("SLV_SN_DATA"),
                    .ADDR_WIDTH             (ADDR_WIDTH),
                    .DATA_WIDTH             (SN_DATA_WIDTH),
                    .ID_WIDTH               (ID_WIDTH),
                    .AWUSER_WIDTH           (AWUSER_WIDTH),
                    .WUSER_WIDTH            (WUSER_WIDTH),
                    .BUSER_WIDTH            (BUSER_WIDTH),
                    .ARUSER_WIDTH           (ARUSER_WIDTH),
                    .RUSER_WIDTH            (RUSER_WIDTH),
                    .INFBUS_WIDTH           (SN_DATA_INFBUS_WIDTH),
                    .TR_DESCBUS_WIDTH       (SN_DATA_TR_DESCBUS_WIDTH),
                    .AW_INFBUS_WIDTH        (SN_DATA_AW_INFBUS_WIDTH_DUMMY),
                    .AW_TR_DESCBUS_WIDTH    (AW_REQ_TR_DESCBUS_WIDTH),
                    .CACHE_LINE_SIZE        (CACHE_LINE_SIZE),
                    .MAX_DESC               (SN_MAX_DESC),
                    .RAM_SIZE               (SN_RAM_SIZE)
		    ) cd_ace_ctrl_ready (
					 // Outputs
					 .infbus_ready         (s_ace_usr_cdready),
					 .inf_xack             (),
					 .aw_infbus_ready      (),
					 .txn_type_wr_strb     (),
					 .error_status         (cdlast_error_status),
					 .tr_descbus_0         (sn_data_tr_descbus_0),
					 .tr_descbus_1         (sn_data_tr_descbus_1),
					 .tr_descbus_2         (sn_data_tr_descbus_2),
					 .tr_descbus_3         (sn_data_tr_descbus_3),
					 .tr_descbus_4         (sn_data_tr_descbus_4),
					 .tr_descbus_5         (sn_data_tr_descbus_5),
					 .tr_descbus_6         (sn_data_tr_descbus_6),
					 .tr_descbus_7         (sn_data_tr_descbus_7),
					 .tr_descbus_8         (sn_data_tr_descbus_8),
					 .tr_descbus_9         (sn_data_tr_descbus_9),
					 .tr_descbus_A         (sn_data_tr_descbus_A),
					 .tr_descbus_B         (sn_data_tr_descbus_B),
					 .tr_descbus_C         (sn_data_tr_descbus_C),
					 .tr_descbus_D         (sn_data_tr_descbus_D),
					 .tr_descbus_E         (sn_data_tr_descbus_E),
					 .tr_descbus_F         (sn_data_tr_descbus_F),
					 .aw_tr_descbus_0      (),
					 .aw_tr_descbus_1      (),
					 .aw_tr_descbus_2      (),
					 .aw_tr_descbus_3      (),
					 .aw_tr_descbus_4      (),
					 .aw_tr_descbus_5      (),
					 .aw_tr_descbus_6      (),
					 .aw_tr_descbus_7      (),
					 .aw_tr_descbus_8      (),
					 .aw_tr_descbus_9      (),
					 .aw_tr_descbus_A      (),
					 .aw_tr_descbus_B      (),
					 .aw_tr_descbus_C      (),
					 .aw_tr_descbus_D      (),
					 .aw_tr_descbus_E      (),
					 .aw_tr_descbus_F      (),
					 .tr_descbus_dtoffset_0(sn_data_tr_descbus_dtoffset_0),
					 .tr_descbus_dtoffset_1(sn_data_tr_descbus_dtoffset_1),
					 .tr_descbus_dtoffset_2(sn_data_tr_descbus_dtoffset_2),
					 .tr_descbus_dtoffset_3(sn_data_tr_descbus_dtoffset_3),
					 .tr_descbus_dtoffset_4(sn_data_tr_descbus_dtoffset_4),
					 .tr_descbus_dtoffset_5(sn_data_tr_descbus_dtoffset_5),
					 .tr_descbus_dtoffset_6(sn_data_tr_descbus_dtoffset_6),
					 .tr_descbus_dtoffset_7(sn_data_tr_descbus_dtoffset_7),
					 .tr_descbus_dtoffset_8(sn_data_tr_descbus_dtoffset_8),
					 .tr_descbus_dtoffset_9(sn_data_tr_descbus_dtoffset_9),
					 .tr_descbus_dtoffset_A(sn_data_tr_descbus_dtoffset_A),
					 .tr_descbus_dtoffset_B(sn_data_tr_descbus_dtoffset_B),
					 .tr_descbus_dtoffset_C(sn_data_tr_descbus_dtoffset_C),
					 .tr_descbus_dtoffset_D(sn_data_tr_descbus_dtoffset_D),
					 .tr_descbus_dtoffset_E(sn_data_tr_descbus_dtoffset_E),
					 .tr_descbus_dtoffset_F(sn_data_tr_descbus_dtoffset_F),
					 .fifo_dout            (sn_data_fifo_dout),            
					 .fifo_dout_valid      (sn_data_fifo_dout_valid),      
					 .fifo_fill_level      (sn_data_fifo_fill_level),
					 .fifo_free_level      (sn_data_fifo_free_level),
					 .uc2rb_we             (uc2rb_sn_we),
					 .uc2rb_bwe            (uc2rb_sn_bwe),
					 .uc2rb_addr           (uc2rb_sn_addr),
					 .uc2rb_data           (uc2rb_sn_data),
					 .uc2rb_wstrb          (),
					 .uc2hm_trig           (),
					 // Inputs
					 .clk                  (clk),
					 .resetn               (resetn),
					 .infbus               (sn_data_infbus),  //cd channel
					 .infbus_last          (s_ace_usr_cdlast),
					 .infbus_valid         (s_ace_usr_cdvalid),
					 .aw_infbus            ({SN_DATA_AW_INFBUS_WIDTH_DUMMY{1'b0}}),
					 .aw_infbus_len        (8'b0),
					 .aw_infbus_id         ({ID_WIDTH{1'b0}}),
					 .aw_infbus_valid      (1'b0),
					 .int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					 .error_clear          (int_intr_error_clear_clr_err_0),
					 .desc_avail           (sn_data_desc_avail),
					 .fifo_rden            (sn_data_fifo_rden),
					 .hm2uc_done           ({SN_MAX_DESC{1'b0}})
					 );
   
   

endmodule        

// Local Variables:
// verilog-library-directories:("./")
// verilog-library-directories:("../../common/rtl/")
// End:

