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
`include "ace_defines_mst.vh"

module ace_mst_inf #(

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
   
		       //M_ACE_USR
		       ,output[ID_WIDTH-1:0] m_ace_usr_awid 
		       ,output[ADDR_WIDTH-1:0] m_ace_usr_awaddr 
		       ,output[7:0] m_ace_usr_awlen
		       ,output[2:0] m_ace_usr_awsize 
		       ,output[1:0] m_ace_usr_awburst 
		       ,output m_ace_usr_awlock 
		       ,output[3:0] m_ace_usr_awcache 
		       ,output[2:0] m_ace_usr_awprot 
		       ,output[3:0] m_ace_usr_awqos 
		       ,output[3:0] m_ace_usr_awregion 
		       ,output[AWUSER_WIDTH-1:0] m_ace_usr_awuser 
		       ,output[2:0] m_ace_usr_awsnoop 
		       ,output[1:0] m_ace_usr_awdomain 
		       ,output[1:0] m_ace_usr_awbar 
		       ,output m_ace_usr_awunique 
		       ,output m_ace_usr_awvalid 
		       ,input m_ace_usr_awready 
		       ,output[XX_DATA_WIDTH-1:0] m_ace_usr_wdata 
		       ,output[(XX_DATA_WIDTH/8)-1:0] m_ace_usr_wstrb
		       ,output m_ace_usr_wlast 
		       ,output[WUSER_WIDTH-1:0] m_ace_usr_wuser 
		       ,output m_ace_usr_wvalid 
		       ,input m_ace_usr_wready 
		       ,input [ID_WIDTH-1:0] m_ace_usr_bid 
		       ,input [1:0] m_ace_usr_bresp 
		       ,input [BUSER_WIDTH-1:0] m_ace_usr_buser 
		       ,input m_ace_usr_bvalid 
		       ,output m_ace_usr_bready 
		       ,output m_ace_usr_wack 
		       ,output[ID_WIDTH-1:0] m_ace_usr_arid 
		       ,output[ADDR_WIDTH-1:0] m_ace_usr_araddr 
		       ,output[7:0] m_ace_usr_arlen 
		       ,output[2:0] m_ace_usr_arsize 
		       ,output[1:0] m_ace_usr_arburst 
		       ,output m_ace_usr_arlock 
		       ,output[3:0] m_ace_usr_arcache 
		       ,output[2:0] m_ace_usr_arprot 
		       ,output[3:0] m_ace_usr_arqos 
		       ,output[3:0] m_ace_usr_arregion 
		       ,output[ARUSER_WIDTH-1:0] m_ace_usr_aruser 
		       ,output[3:0] m_ace_usr_arsnoop 
		       ,output[1:0] m_ace_usr_ardomain 
		       ,output[1:0] m_ace_usr_arbar 
		       ,output m_ace_usr_arvalid 
		       ,input m_ace_usr_arready 
		       ,input [ID_WIDTH-1:0] m_ace_usr_rid 
		       ,input [XX_DATA_WIDTH-1:0] m_ace_usr_rdata 
		       ,input [3:0] m_ace_usr_rresp 
		       ,input m_ace_usr_rlast 
		       ,input [RUSER_WIDTH-1:0] m_ace_usr_ruser 
		       ,input m_ace_usr_rvalid 
		       ,output m_ace_usr_rready 
		       ,output m_ace_usr_rack 
		       ,input [ADDR_WIDTH-1:0] m_ace_usr_acaddr 
		       ,input [3:0] m_ace_usr_acsnoop 
		       ,input [2:0] m_ace_usr_acprot 
		       ,input m_ace_usr_acvalid 
		       ,output m_ace_usr_acready 
		       ,output [4:0] m_ace_usr_crresp 
		       ,output m_ace_usr_crvalid 
		       ,input m_ace_usr_crready 
		       ,output [SN_DATA_WIDTH-1:0] m_ace_usr_cddata 
		       ,output m_ace_usr_cdlast 
		       ,output m_ace_usr_cdvalid 
		       ,input m_ace_usr_cdready 
   
		       //RAM commands  
		       //RDATA_RAM
		       ,output uc2rb_wr_we 
		       ,output [(XX_DATA_WIDTH/8)-1:0] uc2rb_wr_bwe //Generate all 1s always.     
		       ,output [(`CLOG2((XX_RAM_SIZE*8)/XX_DATA_WIDTH))-1:0] uc2rb_wr_addr 
		       ,output [XX_DATA_WIDTH-1:0] uc2rb_wr_data 
   
		       //WDATA_RAM and WSTRB_RAM                               
		       ,output [(`CLOG2((XX_RAM_SIZE*8)/XX_DATA_WIDTH))-1:0] uc2rb_rd_addr 
		       ,input [XX_DATA_WIDTH-1:0] rb2uc_rd_data 
		       ,input [(XX_DATA_WIDTH/8)-1:0] rb2uc_rd_wstrb
   
		       //CDDATA_RAM                               
		       ,output [(`CLOG2((SN_RAM_SIZE*8)/SN_DATA_WIDTH))-1:0] uc2rb_sn_addr 
		       ,input [SN_DATA_WIDTH-1:0] rb2uc_sn_data 
   
		       ,output [XX_MAX_DESC-1:0] rd_uc2hm_trig 
		       ,input [XX_MAX_DESC-1:0] rd_hm2uc_done
		       ,output [XX_MAX_DESC-1:0] wr_uc2hm_trig 
		       ,input [XX_MAX_DESC-1:0] wr_hm2uc_done
   
		       //pop request to FIFO
		       ,input rd_resp_fifo_pop_desc_conn 
		       ,input wr_resp_fifo_pop_desc_conn 
		       ,input sn_req_fifo_pop_desc_conn
   
		       //output from FIFO
		       ,output [(`CLOG2(XX_MAX_DESC))-1:0] rd_resp_fifo_out
		       ,output rd_resp_fifo_out_valid //it is one clock cycle pulse
		       ,output [(`CLOG2(XX_MAX_DESC))-1:0] wr_resp_fifo_out
		       ,output wr_resp_fifo_out_valid //it is one clock cycle pulse
		       ,output [(`CLOG2(SN_MAX_DESC))-1:0] sn_req_fifo_out
		       ,output sn_req_fifo_out_valid //it is one clock cycle pulse
   
   
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
		       ,input [0:0] int_intr_status_sn_data_comp
		       ,input [0:0] int_intr_status_sn_resp_comp
		       ,input [0:0] int_intr_status_sn_req_fifo_nonempty
		       ,input [0:0] int_intr_status_wr_resp_fifo_nonempty
		       ,input [0:0] int_intr_status_wr_req_comp
		       ,input [0:0] int_intr_status_rd_resp_fifo_nonempty
		       ,input [0:0] int_intr_status_rd_req_comp
		       ,input [0:0] int_intr_status_c2h
		       ,input [0:0] int_intr_status_error
		       ,input [0:0] int_intr_error_status_err_1
		       ,input [0:0] int_intr_error_clear_clr_err_2
		       ,input [0:0] int_intr_error_clear_clr_err_1
		       ,input [0:0] int_intr_error_clear_clr_err_0
		       ,input [0:0] int_intr_error_enable_en_err_2
		       ,input [0:0] int_intr_error_enable_en_err_1
		       ,input [0:0] int_intr_error_enable_en_err_0
		       ,input [0:0] int_rd_req_fifo_push_desc_valid
		       ,input [3:0] int_rd_req_fifo_push_desc_desc_index
		       ,input [15:0] int_rd_req_intr_comp_clear_clr_comp
		       ,input [15:0] int_rd_req_intr_comp_enable_en_comp
		       ,input [15:0] int_rd_resp_free_desc_desc
		       ,input [0:0] int_wr_req_fifo_push_desc_valid
		       ,input [3:0] int_wr_req_fifo_push_desc_desc_index
		       ,input [15:0] int_wr_req_intr_comp_clear_clr_comp
		       ,input [15:0] int_wr_req_intr_comp_enable_en_comp
		       ,input [15:0] int_wr_resp_free_desc_desc
		       ,input [15:0] int_sn_req_free_desc_desc
		       ,input [0:0] int_sn_resp_fifo_push_desc_valid
		       ,input [3:0] int_sn_resp_fifo_push_desc_desc_index
		       ,input [15:0] int_sn_resp_intr_comp_clear_clr_comp
		       ,input [15:0] int_sn_resp_intr_comp_enable_en_comp
		       ,input [0:0] int_sn_data_fifo_push_desc_valid
		       ,input [3:0] int_sn_data_fifo_push_desc_desc_index
		       ,input [15:0] int_sn_data_intr_comp_clear_clr_comp
		       ,input [15:0] int_sn_data_intr_comp_enable_en_comp
		       ,input [0:0] int_intr_fifo_enable_en_sn_req_fifo_nonempty
		       ,input [0:0] int_intr_fifo_enable_en_wr_resp_fifo_nonempty
		       ,input [0:0] int_intr_fifo_enable_en_rd_resp_fifo_nonempty
		       ,output [0:0] int_intr_error_status_err_0
		       ,output [4:0] int_rd_req_fifo_free_level_free
		       ,output [15:0] int_rd_req_intr_comp_status_comp
		       ,output [0:0] int_rd_resp_fifo_pop_desc_valid
		       ,output [3:0] int_rd_resp_fifo_pop_desc_desc_index
		       ,output [4:0] int_rd_resp_fifo_fill_level_fill
		       ,output [4:0] int_wr_req_fifo_free_level_free
		       ,output reg [15:0] int_wr_req_intr_comp_status_comp
		       ,output [0:0] int_wr_resp_fifo_pop_desc_valid
		       ,output [3:0] int_wr_resp_fifo_pop_desc_desc_index
		       ,output [4:0] int_wr_resp_fifo_fill_level_fill
		       ,output [0:0] int_sn_req_fifo_pop_desc_valid
		       ,output [3:0] int_sn_req_fifo_pop_desc_desc_index
		       ,output [4:0] int_sn_req_fifo_fill_level_fill
		       ,output [4:0] int_sn_resp_fifo_free_level_free
		       ,output [15:0] int_sn_resp_intr_comp_status_comp
		       ,output [4:0] int_sn_data_fifo_free_level_free
		       ,output [15:0] int_sn_data_intr_comp_status_comp
   
   
`include "ace_mst_int_desc_port.vh"


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
   integer 		     i;
   integer 		     j;
   integer 		     k;

   //generate variable
   genvar 		     gi;

   wire 		     r_channel_error_status;

   //Descriptor 2d vectors
   wire [2:0] 		     int_rd_req_desc_n_attr_axprot [RD_MAX_DESC-1:0];
   wire [1:0] 		     int_rd_req_desc_n_attr_axburst [RD_MAX_DESC-1:0];
   wire [3:0] 		     int_rd_req_desc_n_attr_axqos [RD_MAX_DESC-1:0];
   wire [3:0] 		     int_rd_req_desc_n_attr_axregion [RD_MAX_DESC-1:0];
   wire [2:0] 		     int_rd_req_desc_n_axsize_axsize [RD_MAX_DESC-1:0];
   wire [1:0] 		     int_rd_req_desc_n_attr_axbar [RD_MAX_DESC-1:0];
   wire [1:0] 		     int_rd_req_desc_n_attr_axdomain [RD_MAX_DESC-1:0];
   wire [3:0] 		     int_rd_req_desc_n_attr_axsnoop [RD_MAX_DESC-1:0];
   wire [0:0] 		     int_rd_req_desc_n_attr_axlock [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axaddr_0_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axaddr_1_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axaddr_2_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axaddr_3_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axid_0_axid [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axid_1_axid [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axid_2_axid [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axid_3_axid [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_0_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_10_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_11_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_12_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_13_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_14_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_15_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_1_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_2_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_3_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_4_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_5_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_6_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_7_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_8_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_axuser_9_axuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_req_desc_n_size_txn_size [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_data_host_addr_0_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_data_host_addr_1_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_data_host_addr_2_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_data_host_addr_3_addr [RD_MAX_DESC-1:0];
   wire [3:0] 		     int_rd_req_desc_n_attr_axcache [RD_MAX_DESC-1:0];
   wire [13:0] 		     int_rd_resp_desc_n_data_offset_addr [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_data_size_size [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xid_0_xid [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xid_1_xid [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xid_2_xid [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xid_3_xid [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_0_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_10_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_11_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_12_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_13_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_14_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_15_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_1_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_2_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_3_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_4_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_5_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_6_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_7_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_8_xuser [RD_MAX_DESC-1:0];
   wire [31:0] 		     int_rd_resp_desc_n_xuser_9_xuser [RD_MAX_DESC-1:0];
   wire [4:0] 		     int_rd_resp_desc_n_resp_resp [RD_MAX_DESC-1:0];
   wire [2:0] 		     int_wr_req_desc_n_attr_axprot [WR_MAX_DESC-1:0];
   wire [1:0] 		     int_wr_req_desc_n_attr_axburst [WR_MAX_DESC-1:0];
   wire [13:0] 		     int_wr_req_desc_n_data_offset_addr [WR_MAX_DESC-1:0];
   wire [3:0] 		     int_wr_req_desc_n_attr_axqos [WR_MAX_DESC-1:0];
   wire [3:0] 		     int_wr_req_desc_n_attr_axregion [WR_MAX_DESC-1:0];
   wire [0:0] 		     int_wr_req_desc_n_attr_awunique [WR_MAX_DESC-1:0];
   wire [WR_MAX_DESC-1:0]    int_wr_req_desc_n_txn_type_wr_strb;
   wire [2:0] 		     int_wr_req_desc_n_axsize_axsize [WR_MAX_DESC-1:0];
   wire [1:0] 		     int_wr_req_desc_n_attr_axbar [WR_MAX_DESC-1:0];
   wire [1:0] 		     int_wr_req_desc_n_attr_axdomain [WR_MAX_DESC-1:0];
   wire [3:0] 		     int_wr_req_desc_n_attr_axsnoop [WR_MAX_DESC-1:0];
   wire [0:0] 		     int_wr_req_desc_n_attr_axlock [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axaddr_0_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axaddr_1_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axaddr_2_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axaddr_3_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axid_0_axid [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axid_1_axid [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axid_2_axid [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axid_3_axid [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_0_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_10_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_11_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_12_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_13_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_14_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_15_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_1_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_2_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_3_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_4_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_5_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_6_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_7_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_8_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_axuser_9_axuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_data_host_addr_0_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_data_host_addr_1_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_data_host_addr_2_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_data_host_addr_3_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_size_txn_size [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wstrb_host_addr_0_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wstrb_host_addr_1_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wstrb_host_addr_2_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wstrb_host_addr_3_addr [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_0_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_10_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_11_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_12_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_13_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_14_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_15_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_1_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_2_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_3_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_4_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_5_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_6_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_7_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_8_wuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_req_desc_n_wuser_9_wuser [WR_MAX_DESC-1:0];
   wire [3:0] 		     int_wr_req_desc_n_attr_axcache [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xid_0_xid [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xid_1_xid [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xid_2_xid [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xid_3_xid [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_0_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_10_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_11_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_12_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_13_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_14_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_15_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_1_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_2_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_3_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_4_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_5_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_6_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_7_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_8_xuser [WR_MAX_DESC-1:0];
   wire [31:0] 		     int_wr_resp_desc_n_xuser_9_xuser [WR_MAX_DESC-1:0];
   wire [4:0] 		     int_wr_resp_desc_n_resp_resp [WR_MAX_DESC-1:0];
   wire [4:0] 		     int_sn_resp_desc_n_resp_resp [SN_MAX_DESC-1:0];
   wire [2:0] 		     int_sn_req_desc_n_attr_acprot [SN_MAX_DESC-1:0];
   wire [3:0] 		     int_sn_req_desc_n_attr_acsnoop [SN_MAX_DESC-1:0];
   wire [31:0] 		     int_sn_req_desc_n_acaddr_0_addr [SN_MAX_DESC-1:0];
   wire [31:0] 		     int_sn_req_desc_n_acaddr_1_addr [SN_MAX_DESC-1:0];
   wire [31:0] 		     int_sn_req_desc_n_acaddr_2_addr [SN_MAX_DESC-1:0];
   wire [31:0] 		     int_sn_req_desc_n_acaddr_3_addr [SN_MAX_DESC-1:0];


   ///////////////////////
   //2-D array of descriptor fields
   //////////////////////

`include "ace_usr_mst_desc_2d.vh"

   ///////////////////////
   //Tie unused signals
   //////////////////////

   generate

      for (gi=0; gi<=MAX_DESC-1; gi=gi+1) begin: gen_unused_desc_sig

	 assign int_sn_req_desc_n_acaddr_2_addr[gi] = 32'h0;
	 assign int_sn_req_desc_n_acaddr_3_addr[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xid_1_xid[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xid_2_xid[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xid_3_xid[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xid_1_xid[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xid_2_xid[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xid_3_xid[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_10_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_11_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_12_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_13_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_14_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_15_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_1_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_2_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_3_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_4_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_5_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_6_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_7_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_8_xuser[gi] = 32'h0;
	 assign int_rd_resp_desc_n_xuser_9_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_10_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_11_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_12_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_13_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_14_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_15_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_1_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_2_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_3_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_4_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_5_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_6_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_7_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_8_xuser[gi] = 32'h0;
	 assign int_wr_resp_desc_n_xuser_9_xuser[gi] = 32'h0;

      end

   endgenerate  

   ///////////////////////
   //Update error from UC(User-Control) block
   //////////////////////

   assign int_intr_error_status_err_0 = r_channel_error_status;


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



   localparam RD_REQ_FR_DESCBUS_WIDTH                                     = RD_REQ_INFBUS_WIDTH;

   wire [RD_REQ_INFBUS_WIDTH-1:0]                                         rd_req_infbus;

   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_n[XX_MAX_DESC-1:0];

   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_0;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_1;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_2;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_3;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_4;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_5;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_6;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_7;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_8;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_9;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_A;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_B;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_C;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_D;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_E;
   wire [RD_REQ_FR_DESCBUS_WIDTH-1 :0] 					  rd_req_fr_descbus_F;

   wire [7:0] 								  rd_req_fr_descbus_len_0;
   wire [7:0] 								  rd_req_fr_descbus_len_1;
   wire [7:0] 								  rd_req_fr_descbus_len_2;
   wire [7:0] 								  rd_req_fr_descbus_len_3;
   wire [7:0] 								  rd_req_fr_descbus_len_4;
   wire [7:0] 								  rd_req_fr_descbus_len_5;
   wire [7:0] 								  rd_req_fr_descbus_len_6;
   wire [7:0] 								  rd_req_fr_descbus_len_7;
   wire [7:0] 								  rd_req_fr_descbus_len_8;
   wire [7:0] 								  rd_req_fr_descbus_len_9;
   wire [7:0] 								  rd_req_fr_descbus_len_A;
   wire [7:0] 								  rd_req_fr_descbus_len_B;
   wire [7:0] 								  rd_req_fr_descbus_len_C;
   wire [7:0] 								  rd_req_fr_descbus_len_D;
   wire [7:0] 								  rd_req_fr_descbus_len_E;
   wire [7:0] 								  rd_req_fr_descbus_len_F;

   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_0;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_1;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_2;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_3;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_4;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_5;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_6;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_7;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_8;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_9;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_A;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_B;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_C;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_D;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_E;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_fr_descbus_dtoffset_F;

   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_0;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_1;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_2;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_3;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_4;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_5;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_6;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_7;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_8;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_9;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_A;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_B;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_C;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_D;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_E;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					  rd_req_data_offset_F;

   wire [XX_DESC_IDX_WIDTH:0] 						  rd_req_fifo_fill_level;
   wire [XX_DESC_IDX_WIDTH:0] 						  rd_req_fifo_free_level;

   wire [XX_MAX_DESC-1:0] 						  rd_req_intr_comp_status_comp;

   reg 									  rd_req_fifo_wren;
   wire [XX_DESC_IDX_WIDTH-1:0] 					  rd_req_fifo_din;

   reg 									  rd_req_push;
   reg 									  rd_req_push_ff;

   wire [63:0] 								  fr_araddr[XX_MAX_DESC-1:0];
   wire [7:0] 								  fr_arlen[XX_MAX_DESC-1:0];

   wire [XX_DESC_IDX_WIDTH-1:0] 					  rd_req_infbus_desc_idx;

   wire [XX_MAX_DESC-1:0] 						  rd_req_free_desc;

   assign int_rd_req_fifo_free_level_free = rd_req_fifo_free_level;

   `FF_RSTLOW(clk,resetn,int_rd_req_fifo_push_desc_valid,rd_req_push)
   `FF_RSTLOW(clk,resetn,rd_req_push,rd_req_push_ff)

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 rd_req_fifo_wren <= 1'b0;  
      end else if (rd_req_push==1'b1 && rd_req_push_ff==1'b0) begin //Positive edge detection
	 rd_req_fifo_wren <= 1'b1;
      end else begin
	 rd_req_fifo_wren <= 1'b0;
      end
   end

   synchronizer#(
		 .SYNC_FF                                                       (2)  
		 ,.D_WIDTH                                                       (XX_DESC_IDX_WIDTH)
		 ) sync_rd_req_fifo_din (
					 .ck                                                           (clk) 
					 ,.rn                                                           (resetn) 
					 ,.data_in                                                      (int_rd_req_fifo_push_desc_desc_index) 
					 ,.q_out                                                        (rd_req_fifo_din)
					 );   




   assign int_rd_req_intr_comp_status_comp = rd_req_intr_comp_status_comp;

   assign {  m_ace_usr_arid 
             , m_ace_usr_araddr 
             , m_ace_usr_arlen 
             , m_ace_usr_arsize 
             , m_ace_usr_arburst 
             , m_ace_usr_arlock 
             , m_ace_usr_arcache 
             , m_ace_usr_arprot 
             , m_ace_usr_arqos 
             , m_ace_usr_arregion 
             , m_ace_usr_aruser 
             , m_ace_usr_arsnoop 
             , m_ace_usr_ardomain 
             , m_ace_usr_arbar 
	     }                        = rd_req_infbus;

   

   assign rd_req_fr_descbus_0 = rd_req_fr_descbus_n['h0];
   assign rd_req_fr_descbus_1 = rd_req_fr_descbus_n['h1];
   assign rd_req_fr_descbus_2 = rd_req_fr_descbus_n['h2];
   assign rd_req_fr_descbus_3 = rd_req_fr_descbus_n['h3];
   assign rd_req_fr_descbus_4 = rd_req_fr_descbus_n['h4];
   assign rd_req_fr_descbus_5 = rd_req_fr_descbus_n['h5];
   assign rd_req_fr_descbus_6 = rd_req_fr_descbus_n['h6];
   assign rd_req_fr_descbus_7 = rd_req_fr_descbus_n['h7];
   assign rd_req_fr_descbus_8 = rd_req_fr_descbus_n['h8];
   assign rd_req_fr_descbus_9 = rd_req_fr_descbus_n['h9];
   assign rd_req_fr_descbus_A = rd_req_fr_descbus_n['hA];
   assign rd_req_fr_descbus_B = rd_req_fr_descbus_n['hB];
   assign rd_req_fr_descbus_C = rd_req_fr_descbus_n['hC];
   assign rd_req_fr_descbus_D = rd_req_fr_descbus_n['hD];
   assign rd_req_fr_descbus_E = rd_req_fr_descbus_n['hE];
   assign rd_req_fr_descbus_F = rd_req_fr_descbus_n['hF];
   

   
   generate
      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_rd_req_fr_descbus_n

	 assign fr_araddr[gi] = {int_rd_req_desc_n_axaddr_1_addr[gi],int_rd_req_desc_n_axaddr_0_addr[gi]};  
	 assign fr_arlen[gi] = ( ((int_rd_req_desc_n_size_txn_size[gi]*8)/XX_DATA_WIDTH) - 1 );  

	 assign rd_req_fr_descbus_n[gi] = {  int_rd_req_desc_n_axid_0_axid[gi][(0) +: (ID_WIDTH)]
					     , fr_araddr[gi][(0) +: (ADDR_WIDTH)] 
					     , fr_arlen[gi] 
					     , int_rd_req_desc_n_axsize_axsize[gi][(0) +: (AXSIZE_WIDTH)]
					     , int_rd_req_desc_n_attr_axburst[gi][(0) +: (AXBURST_WIDTH)]
					     , int_rd_req_desc_n_attr_axlock[gi][(0) +: (AXLOCK_WIDTH)]
					     , int_rd_req_desc_n_attr_axcache[gi][(0) +: (AXCACHE_WIDTH)]
					     , int_rd_req_desc_n_attr_axprot[gi][(0) +: (AXPROT_WIDTH)]
					     , int_rd_req_desc_n_attr_axqos[gi][(0) +: (AXQOS_WIDTH)]
					     , int_rd_req_desc_n_attr_axregion[gi][(0) +: (AXREGION_WIDTH)]
					     , int_rd_req_desc_n_axuser_0_axuser[gi][(0) +: (ARUSER_WIDTH)]
					     , int_rd_req_desc_n_attr_axsnoop[gi][(0) +: (ARSNOOP_WIDTH)]
					     , int_rd_req_desc_n_attr_axdomain[gi][(0) +: (AXDOMAIN_WIDTH)]
					     , int_rd_req_desc_n_attr_axbar[gi][(0) +: (AXBAR_WIDTH)]
					     };

      end
   endgenerate
   
   
   assign rd_req_fr_descbus_len_0 = 'b0;
   assign rd_req_fr_descbus_len_1 = 'b0;
   assign rd_req_fr_descbus_len_2 = 'b0;
   assign rd_req_fr_descbus_len_3 = 'b0;
   assign rd_req_fr_descbus_len_4 = 'b0;
   assign rd_req_fr_descbus_len_5 = 'b0;
   assign rd_req_fr_descbus_len_6 = 'b0;
   assign rd_req_fr_descbus_len_7 = 'b0;
   assign rd_req_fr_descbus_len_8 = 'b0;
   assign rd_req_fr_descbus_len_9 = 'b0;
   assign rd_req_fr_descbus_len_A = 'b0;
   assign rd_req_fr_descbus_len_B = 'b0;
   assign rd_req_fr_descbus_len_C = 'b0;
   assign rd_req_fr_descbus_len_D = 'b0;
   assign rd_req_fr_descbus_len_E = 'b0;
   assign rd_req_fr_descbus_len_F = 'b0;

   assign rd_req_fr_descbus_dtoffset_0 = 'b0;
   assign rd_req_fr_descbus_dtoffset_1 = 'b0;
   assign rd_req_fr_descbus_dtoffset_2 = 'b0;
   assign rd_req_fr_descbus_dtoffset_3 = 'b0;
   assign rd_req_fr_descbus_dtoffset_4 = 'b0;
   assign rd_req_fr_descbus_dtoffset_5 = 'b0;
   assign rd_req_fr_descbus_dtoffset_6 = 'b0;
   assign rd_req_fr_descbus_dtoffset_7 = 'b0;
   assign rd_req_fr_descbus_dtoffset_8 = 'b0;
   assign rd_req_fr_descbus_dtoffset_9 = 'b0;
   assign rd_req_fr_descbus_dtoffset_A = 'b0;
   assign rd_req_fr_descbus_dtoffset_B = 'b0;
   assign rd_req_fr_descbus_dtoffset_C = 'b0;
   assign rd_req_fr_descbus_dtoffset_D = 'b0;
   assign rd_req_fr_descbus_dtoffset_E = 'b0;
   assign rd_req_fr_descbus_dtoffset_F = 'b0;

   assign rd_req_free_desc = int_rd_resp_free_desc_desc;

   ace_ctrl_valid #(
                    // Parameters
                    .ACE_PROTOCOL          (ACE_PROTOCOL),
                    .ACE_CHANNEL           ("MST_RD_REQ"),
                    .ADDR_WIDTH            (ADDR_WIDTH),
                    .DATA_WIDTH            (XX_DATA_WIDTH),
                    .ID_WIDTH              (ID_WIDTH),
                    .AWUSER_WIDTH          (AWUSER_WIDTH),
                    .WUSER_WIDTH           (WUSER_WIDTH),
                    .BUSER_WIDTH           (BUSER_WIDTH),
                    .ARUSER_WIDTH          (ARUSER_WIDTH),
                    .RUSER_WIDTH           (RUSER_WIDTH),
                    .INFBUS_WIDTH          (RD_REQ_INFBUS_WIDTH),
                    .FR_DESCBUS_WIDTH      (RD_REQ_FR_DESCBUS_WIDTH),
                    .CACHE_LINE_SIZE       (CACHE_LINE_SIZE),
                    .MAX_DESC              (XX_MAX_DESC),
                    .RAM_SIZE              (XX_RAM_SIZE)
		    ) ar_ace_ctrl_valid (
					 // Outputs
					 .infbus               (rd_req_infbus),  //ar channel
					 .infbus_last          (),
					 .infbus_desc_idx      (rd_req_infbus_desc_idx),
					 .infbus_valid         (m_ace_usr_arvalid),
					 .fifo_fill_level      (rd_req_fifo_fill_level),
					 .fifo_free_level      (rd_req_fifo_free_level),
					 .intr_comp_status_comp(rd_req_intr_comp_status_comp),
					 .uc2rb_addr           (),
					 .uc2hm_trig           (),
					 .data_offset_0        (rd_req_data_offset_0),
					 .data_offset_1        (rd_req_data_offset_1),
					 .data_offset_2        (rd_req_data_offset_2),
					 .data_offset_3        (rd_req_data_offset_3),
					 .data_offset_4        (rd_req_data_offset_4),
					 .data_offset_5        (rd_req_data_offset_5),
					 .data_offset_6        (rd_req_data_offset_6),
					 .data_offset_7        (rd_req_data_offset_7),
					 .data_offset_8        (rd_req_data_offset_8),
					 .data_offset_9        (rd_req_data_offset_9),
					 .data_offset_A        (rd_req_data_offset_A),
					 .data_offset_B        (rd_req_data_offset_B),
					 .data_offset_C        (rd_req_data_offset_C),
					 .data_offset_D        (rd_req_data_offset_D),
					 .data_offset_E        (rd_req_data_offset_E),
					 .data_offset_F        (rd_req_data_offset_F),
					 // Inputs
					 .clk                  (clk),
					 .resetn               (resetn),
					 .infbus_ready         (m_ace_usr_arready),
					 .inf_xack             (1'b0),
					 .free_desc            (rd_req_free_desc),
					 .fr_descbus_0         (rd_req_fr_descbus_0),
					 .fr_descbus_1         (rd_req_fr_descbus_1),
					 .fr_descbus_2         (rd_req_fr_descbus_2),
					 .fr_descbus_3         (rd_req_fr_descbus_3),
					 .fr_descbus_4         (rd_req_fr_descbus_4),
					 .fr_descbus_5         (rd_req_fr_descbus_5),
					 .fr_descbus_6         (rd_req_fr_descbus_6),
					 .fr_descbus_7         (rd_req_fr_descbus_7),
					 .fr_descbus_8         (rd_req_fr_descbus_8),
					 .fr_descbus_9         (rd_req_fr_descbus_9),
					 .fr_descbus_A         (rd_req_fr_descbus_A),
					 .fr_descbus_B         (rd_req_fr_descbus_B),
					 .fr_descbus_C         (rd_req_fr_descbus_C),
					 .fr_descbus_D         (rd_req_fr_descbus_D),
					 .fr_descbus_E         (rd_req_fr_descbus_E),
					 .fr_descbus_F         (rd_req_fr_descbus_F),
					 .fr_descbus_len_0     (rd_req_fr_descbus_len_0),
					 .fr_descbus_len_1     (rd_req_fr_descbus_len_1),
					 .fr_descbus_len_2     (rd_req_fr_descbus_len_2),
					 .fr_descbus_len_3     (rd_req_fr_descbus_len_3),
					 .fr_descbus_len_4     (rd_req_fr_descbus_len_4),
					 .fr_descbus_len_5     (rd_req_fr_descbus_len_5),
					 .fr_descbus_len_6     (rd_req_fr_descbus_len_6),
					 .fr_descbus_len_7     (rd_req_fr_descbus_len_7),
					 .fr_descbus_len_8     (rd_req_fr_descbus_len_8),
					 .fr_descbus_len_9     (rd_req_fr_descbus_len_9),
					 .fr_descbus_len_A     (rd_req_fr_descbus_len_A),
					 .fr_descbus_len_B     (rd_req_fr_descbus_len_B),
					 .fr_descbus_len_C     (rd_req_fr_descbus_len_C),
					 .fr_descbus_len_D     (rd_req_fr_descbus_len_D),
					 .fr_descbus_len_E     (rd_req_fr_descbus_len_E),
					 .fr_descbus_len_F     (rd_req_fr_descbus_len_F),
					 .fr_descbus_dtoffset_0(rd_req_fr_descbus_dtoffset_0),
					 .fr_descbus_dtoffset_1(rd_req_fr_descbus_dtoffset_1),
					 .fr_descbus_dtoffset_2(rd_req_fr_descbus_dtoffset_2),
					 .fr_descbus_dtoffset_3(rd_req_fr_descbus_dtoffset_3),
					 .fr_descbus_dtoffset_4(rd_req_fr_descbus_dtoffset_4),
					 .fr_descbus_dtoffset_5(rd_req_fr_descbus_dtoffset_5),
					 .fr_descbus_dtoffset_6(rd_req_fr_descbus_dtoffset_6),
					 .fr_descbus_dtoffset_7(rd_req_fr_descbus_dtoffset_7),
					 .fr_descbus_dtoffset_8(rd_req_fr_descbus_dtoffset_8),
					 .fr_descbus_dtoffset_9(rd_req_fr_descbus_dtoffset_9),
					 .fr_descbus_dtoffset_A(rd_req_fr_descbus_dtoffset_A),
					 .fr_descbus_dtoffset_B(rd_req_fr_descbus_dtoffset_B),
					 .fr_descbus_dtoffset_C(rd_req_fr_descbus_dtoffset_C),
					 .fr_descbus_dtoffset_D(rd_req_fr_descbus_dtoffset_D),
					 .fr_descbus_dtoffset_E(rd_req_fr_descbus_dtoffset_E),
					 .fr_descbus_dtoffset_F(rd_req_fr_descbus_dtoffset_F),
					 .int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					 .txn_type_wr_strb     ({XX_MAX_DESC{1'b0}}),
					 .fifo_wren            (rd_req_fifo_wren),
					 .fifo_din             (rd_req_fifo_din),
					 .intr_comp_clear_clr_comp(int_rd_req_intr_comp_clear_clr_comp),
					 .rb2uc_data           ({XX_DATA_WIDTH{1'b0}}),
					 .rb2uc_wstrb          ({WSTRB_WIDTH{1'b0}}),
					 .hm2uc_done           ({XX_MAX_DESC{1'b0}})
					 );
   

   wire [XX_DESC_IDX_WIDTH-1:0]         arid_response_id0;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_id1;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_id2;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_id3;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_id4;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_id5;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_id6;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_id7;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_id8;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_id9;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_idA;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_idB;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_idC;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_idD;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_idE;
   wire [XX_DESC_IDX_WIDTH-1:0] 	arid_response_idF;

   wire [XX_MAX_DESC-1:0] 		rd_fifo_id_reg_valid;

   wire [ID_WIDTH-1:0] 			rd_fifo_id_reg0;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_reg1;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_reg2;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_reg3;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_reg4;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_reg5;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_reg6;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_reg7;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_reg8;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_reg9;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_regA;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_regB;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_regC;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_regD;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_regE;
   wire [ID_WIDTH-1:0] 			rd_fifo_id_regF;

   wire 				rd_desc_allocation_in_progress;  

   wire 				arnext;
   wire [XX_DESC_IDX_WIDTH-1:0] 	rd_desc_req_id;  

   wire [XX_MAX_DESC-1:0] 		arid_read_en;   //from r-channel
   
   assign arnext = m_ace_usr_arready && m_ace_usr_arvalid;

   assign rd_desc_req_id = rd_req_infbus_desc_idx;

   ace_axid_store #(
                    .MAX_DESC                    (XX_MAX_DESC)
                    ,.ID_WIDTH                    (ID_WIDTH)
		    )ace_arid_store (
				     // Outputs
				     .axid_response_id0           (arid_response_id0)
				     ,.axid_response_id1           (arid_response_id1)
				     ,.axid_response_id2           (arid_response_id2)
				     ,.axid_response_id3           (arid_response_id3)
				     ,.axid_response_id4           (arid_response_id4)
				     ,.axid_response_id5           (arid_response_id5)
				     ,.axid_response_id6           (arid_response_id6)
				     ,.axid_response_id7           (arid_response_id7)
				     ,.axid_response_id8           (arid_response_id8)
				     ,.axid_response_id9           (arid_response_id9)
				     ,.axid_response_id10          (arid_response_idA)
				     ,.axid_response_id11          (arid_response_idB)
				     ,.axid_response_id12          (arid_response_idC)
				     ,.axid_response_id13          (arid_response_idD)
				     ,.axid_response_id14          (arid_response_idE)
				     ,.axid_response_id15          (arid_response_idF)
				     ,.fifo_id_reg_valid_ff        (rd_fifo_id_reg_valid)
				     ,.fifo_id_reg0                (rd_fifo_id_reg0)
				     ,.fifo_id_reg1                (rd_fifo_id_reg1)
				     ,.fifo_id_reg2                (rd_fifo_id_reg2)
				     ,.fifo_id_reg3                (rd_fifo_id_reg3)
				     ,.fifo_id_reg4                (rd_fifo_id_reg4)
				     ,.fifo_id_reg5                (rd_fifo_id_reg5)
				     ,.fifo_id_reg6                (rd_fifo_id_reg6)
				     ,.fifo_id_reg7                (rd_fifo_id_reg7)
				     ,.fifo_id_reg8                (rd_fifo_id_reg8)
				     ,.fifo_id_reg9                (rd_fifo_id_reg9)
				     ,.fifo_id_reg10               (rd_fifo_id_regA)
				     ,.fifo_id_reg11               (rd_fifo_id_regB)
				     ,.fifo_id_reg12               (rd_fifo_id_regC)
				     ,.fifo_id_reg13               (rd_fifo_id_regD)
				     ,.fifo_id_reg14               (rd_fifo_id_regE)
				     ,.fifo_id_reg15               (rd_fifo_id_regF)
				     ,.desc_allocation_in_progress (rd_desc_allocation_in_progress)
				     // Inputs
				     ,.clk                         (clk)
				     ,.resetn                      (resetn)
				     ,.axnext                      (arnext)
				     ,.m_axi_usr_axid              (m_ace_usr_arid)
				     ,.desc_req_id                 (rd_desc_req_id)
				     ,.axid_read_en                (arid_read_en)
				     
				     );

   
   
   ///////////////////////
     //R-Channel
   //Description :
   //////////////////////
   
   localparam AW_REQ_INFBUS_WIDTH                                          = (1);

   localparam RD_RESP_INFBUS_WIDTH                                         = {   XX_DATA_WIDTH 
										 + ID_WIDTH
										 + RRESP_WIDTH
										 + RUSER_WIDTH
										 };




   localparam RD_RESP_TR_DESCBUS_WIDTH                                      = RD_RESP_INFBUS_WIDTH; 

   localparam AW_REQ_TR_DESCBUS_WIDTH                                      = AW_REQ_INFBUS_WIDTH; 



   wire [RD_RESP_INFBUS_WIDTH-1:0] 	rd_resp_infbus;

   wire [XX_DESC_IDX_WIDTH-1:0] 	rd_resp_fifo_dout;
   wire 				rd_resp_fifo_dout_valid;  //it is one clock cycle pulse
   wire [XX_DESC_IDX_WIDTH:0] 		rd_resp_fifo_fill_level;
   wire [XX_DESC_IDX_WIDTH:0] 		rd_resp_fifo_free_level;

   wire [XX_MAX_DESC-1:0] 		rd_resp_desc_avail;
   wire 				rd_resp_fifo_rden;   //should be one clock cycle pulse
   wire [XX_MAX_DESC-1:0] 		rd_resp_hm2uc_done;

   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_0;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_1;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_2;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_3;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_4;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_5;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_6;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_7;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_8;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_9;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_A;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_B;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_C;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_D;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_E;
   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_F;

   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_0;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_1;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_2;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_3;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_4;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_5;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_6;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_7;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_8;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_9;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_A;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_B;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_C;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_D;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_E;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_tr_descbus_dtoffset_F;

   wire [7:0] 				rd_resp_tr_descbus_len_0;
   wire [7:0] 				rd_resp_tr_descbus_len_1;
   wire [7:0] 				rd_resp_tr_descbus_len_2;
   wire [7:0] 				rd_resp_tr_descbus_len_3;
   wire [7:0] 				rd_resp_tr_descbus_len_4;
   wire [7:0] 				rd_resp_tr_descbus_len_5;
   wire [7:0] 				rd_resp_tr_descbus_len_6;
   wire [7:0] 				rd_resp_tr_descbus_len_7;
   wire [7:0] 				rd_resp_tr_descbus_len_8;
   wire [7:0] 				rd_resp_tr_descbus_len_9;
   wire [7:0] 				rd_resp_tr_descbus_len_A;
   wire [7:0] 				rd_resp_tr_descbus_len_B;
   wire [7:0] 				rd_resp_tr_descbus_len_C;
   wire [7:0] 				rd_resp_tr_descbus_len_D;
   wire [7:0] 				rd_resp_tr_descbus_len_E;
   wire [7:0] 				rd_resp_tr_descbus_len_F;

   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_0;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_1;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_2;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_3;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_4;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_5;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_6;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_7;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_8;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_9;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_A;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_B;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_C;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_D;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_E;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 	rd_resp_data_offset_F;


   wire [RD_RESP_TR_DESCBUS_WIDTH-1 :0] rd_resp_tr_descbus_n[XX_MAX_DESC-1:0];

   wire [XX_MAX_DESC-1:0] 		rd_resp_txn_type_wr_strb;

   wire 				rd_resp_update_intr_error_status_reg;
   
   wire 				ar_valid_ready;
   wire [XX_DESC_IDX_WIDTH-1:0] 	ar_valid_ready_desc_idx;
   reg [7:0] 				ar_valid_ready_arlen;
   wire [ID_WIDTH-1:0] 			ar_valid_ready_arid;
   
   wire [AXBAR_WIDTH-1+AXDOMAIN_WIDTH+ARSNOOP_WIDTH-1:0] ar_valid_ready_txn;
   
   assign ar_valid_ready = (m_ace_usr_arvalid & m_ace_usr_arready);
   assign ar_valid_ready_desc_idx = rd_req_infbus_desc_idx;
   assign ar_valid_ready_arid = m_ace_usr_arid;
   assign ar_valid_ready_txn = {m_ace_usr_arbar[0], m_ace_usr_ardomain, m_ace_usr_arsnoop };


   always @(*) begin 

      //If txn is of type - (AR, single R, RACK)
      if (    (ar_valid_ready_txn == `RD_TXN_CLEANUNIQUE_0  )
	      || (ar_valid_ready_txn == `RD_TXN_CLEANUNIQUE_1  )
	      || (ar_valid_ready_txn == `RD_TXN_MAKEUNIQUE_0   )
	      || (ar_valid_ready_txn == `RD_TXN_MAKEUNIQUE_1   )
	      || (ar_valid_ready_txn == `RD_TXN_CLEANSHARED_0  )
	      || (ar_valid_ready_txn == `RD_TXN_CLEANSHARED_1  )
	      || (ar_valid_ready_txn == `RD_TXN_CLEANSHARED_2  )
	      || (ar_valid_ready_txn == `RD_TXN_CLEANINVALID_0 )
	      || (ar_valid_ready_txn == `RD_TXN_CLEANINVALID_1 )
	      || (ar_valid_ready_txn == `RD_TXN_CLEANINVALID_2 )
	      || (ar_valid_ready_txn == `RD_TXN_MAKEINVALID_0  )
	      || (ar_valid_ready_txn == `RD_TXN_MAKEINVALID_1  )
	      || (ar_valid_ready_txn == `RD_TXN_MAKEINVALID_2  )
	      || (ar_valid_ready_txn == `RD_TXN_BARRIER_0      )
	      || (ar_valid_ready_txn == `RD_TXN_BARRIER_1      )
	      || (ar_valid_ready_txn == `RD_TXN_BARRIER_2      )
	      || (ar_valid_ready_txn == `RD_TXN_BARRIER_3      )
	      || (ar_valid_ready_txn == `RD_TXN_DVMCOMP_0      )
	      || (ar_valid_ready_txn == `RD_TXN_DVMCOMP_1      )
	      || (ar_valid_ready_txn == `RD_TXN_DVMMSG_0       )
	      || (ar_valid_ready_txn == `RD_TXN_DVMMSG_1       )
	      ) begin
	 ar_valid_ready_arlen <= 8'b0;
      end else begin
	 ar_valid_ready_arlen <= m_ace_usr_arlen;
      end

   end


   //wire rd_resp_fifo_pop_desc_conn_pulse;
   reg rd_resp_fifo_pop_desc_conn_pulse;

   reg rd_resp_fifo_pop_desc_conn_ff;

   assign int_rd_resp_fifo_pop_desc_valid = 'b0;
   assign int_rd_resp_fifo_pop_desc_desc_index = 'b0;

   
   `FF_RSTLOW(clk,resetn,rd_resp_fifo_pop_desc_conn,rd_resp_fifo_pop_desc_conn_ff)

   //assign rd_resp_fifo_pop_desc_conn_pulse = ( (rd_resp_fifo_pop_desc_conn) & (~rd_resp_fifo_pop_desc_conn_ff) );

   assign rd_resp_fifo_out = rd_resp_fifo_dout; 
   assign rd_resp_fifo_out_valid = rd_resp_fifo_dout_valid;

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 rd_resp_fifo_pop_desc_conn_pulse <= 1'b0;
      end else if (rd_resp_fifo_pop_desc_conn==1'b1 && rd_resp_fifo_pop_desc_conn_ff==1'b0) begin //Positive edge detection
	 rd_resp_fifo_pop_desc_conn_pulse <= 1'b1;
      end else begin
	 rd_resp_fifo_pop_desc_conn_pulse <= 1'b0;
      end
   end



   assign rd_resp_infbus                                                    = {  m_ace_usr_rdata 
										 , m_ace_usr_rid
										 , m_ace_usr_rresp
										 , m_ace_usr_ruser
										 };

   



   assign rd_resp_tr_descbus_n['h0] = rd_resp_tr_descbus_0;
   assign rd_resp_tr_descbus_n['h1] = rd_resp_tr_descbus_1;
   assign rd_resp_tr_descbus_n['h2] = rd_resp_tr_descbus_2;
   assign rd_resp_tr_descbus_n['h3] = rd_resp_tr_descbus_3;
   assign rd_resp_tr_descbus_n['h4] = rd_resp_tr_descbus_4;
   assign rd_resp_tr_descbus_n['h5] = rd_resp_tr_descbus_5;
   assign rd_resp_tr_descbus_n['h6] = rd_resp_tr_descbus_6;
   assign rd_resp_tr_descbus_n['h7] = rd_resp_tr_descbus_7;
   assign rd_resp_tr_descbus_n['h8] = rd_resp_tr_descbus_8;
   assign rd_resp_tr_descbus_n['h9] = rd_resp_tr_descbus_9;
   assign rd_resp_tr_descbus_n['hA] = rd_resp_tr_descbus_A;
   assign rd_resp_tr_descbus_n['hB] = rd_resp_tr_descbus_B;
   assign rd_resp_tr_descbus_n['hC] = rd_resp_tr_descbus_C;
   assign rd_resp_tr_descbus_n['hD] = rd_resp_tr_descbus_D;
   assign rd_resp_tr_descbus_n['hE] = rd_resp_tr_descbus_E;
   assign rd_resp_tr_descbus_n['hF] = rd_resp_tr_descbus_F;

   assign int_rd_resp_desc_n_data_offset_addr['h0] = (rd_resp_tr_descbus_dtoffset_0*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['h1] = (rd_resp_tr_descbus_dtoffset_1*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['h2] = (rd_resp_tr_descbus_dtoffset_2*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['h3] = (rd_resp_tr_descbus_dtoffset_3*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['h4] = (rd_resp_tr_descbus_dtoffset_4*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['h5] = (rd_resp_tr_descbus_dtoffset_5*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['h6] = (rd_resp_tr_descbus_dtoffset_6*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['h7] = (rd_resp_tr_descbus_dtoffset_7*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['h8] = (rd_resp_tr_descbus_dtoffset_8*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['h9] = (rd_resp_tr_descbus_dtoffset_9*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['hA] = (rd_resp_tr_descbus_dtoffset_A*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['hB] = (rd_resp_tr_descbus_dtoffset_B*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['hC] = (rd_resp_tr_descbus_dtoffset_C*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['hD] = (rd_resp_tr_descbus_dtoffset_D*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['hE] = (rd_resp_tr_descbus_dtoffset_E*XX_DATA_WIDTH/8);
   assign int_rd_resp_desc_n_data_offset_addr['hF] = (rd_resp_tr_descbus_dtoffset_F*XX_DATA_WIDTH/8);

   assign int_rd_resp_desc_n_data_size_size['h0] = ( ((rd_resp_tr_descbus_len_0+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['h1] = ( ((rd_resp_tr_descbus_len_1+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['h2] = ( ((rd_resp_tr_descbus_len_2+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['h3] = ( ((rd_resp_tr_descbus_len_3+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['h4] = ( ((rd_resp_tr_descbus_len_4+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['h5] = ( ((rd_resp_tr_descbus_len_5+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['h6] = ( ((rd_resp_tr_descbus_len_6+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['h7] = ( ((rd_resp_tr_descbus_len_7+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['h8] = ( ((rd_resp_tr_descbus_len_8+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['h9] = ( ((rd_resp_tr_descbus_len_9+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['hA] = ( ((rd_resp_tr_descbus_len_A+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['hB] = ( ((rd_resp_tr_descbus_len_B+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['hC] = ( ((rd_resp_tr_descbus_len_C+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['hD] = ( ((rd_resp_tr_descbus_len_D+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['hE] = ( ((rd_resp_tr_descbus_len_E+1)*XX_DATA_WIDTH)/8 );
   assign int_rd_resp_desc_n_data_size_size['hF] = ( ((rd_resp_tr_descbus_len_F+1)*XX_DATA_WIDTH)/8 );

   assign rd_resp_data_offset_0 = rd_req_data_offset_0;
   assign rd_resp_data_offset_1 = rd_req_data_offset_1;
   assign rd_resp_data_offset_2 = rd_req_data_offset_2;
   assign rd_resp_data_offset_3 = rd_req_data_offset_3;
   assign rd_resp_data_offset_4 = rd_req_data_offset_4;
   assign rd_resp_data_offset_5 = rd_req_data_offset_5;
   assign rd_resp_data_offset_6 = rd_req_data_offset_6;
   assign rd_resp_data_offset_7 = rd_req_data_offset_7;
   assign rd_resp_data_offset_8 = rd_req_data_offset_8;
   assign rd_resp_data_offset_9 = rd_req_data_offset_9;
   assign rd_resp_data_offset_A = rd_req_data_offset_A;
   assign rd_resp_data_offset_B = rd_req_data_offset_B;
   assign rd_resp_data_offset_C = rd_req_data_offset_C;
   assign rd_resp_data_offset_D = rd_req_data_offset_D;
   assign rd_resp_data_offset_E = rd_req_data_offset_E;
   assign rd_resp_data_offset_F = rd_req_data_offset_F;


   generate

      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_int_rd_resp_desc

	 assign int_rd_resp_desc_n_resp_resp[gi][4] = 1'b0;     //unused
	 assign int_rd_resp_desc_n_xid_0_xid[gi][31:ID_WIDTH] = 'b0;     //unused

	 assign {   int_rd_resp_desc_n_xid_0_xid[gi][(0) +: (ID_WIDTH)]
		    , int_rd_resp_desc_n_resp_resp[gi][(0) +: (RRESP_WIDTH)] 
		    , int_rd_resp_desc_n_xuser_0_xuser[gi][(0) +: (RUSER_WIDTH)] 
		    } = rd_resp_tr_descbus_n[gi][(RD_RESP_TR_DESCBUS_WIDTH-XX_DATA_WIDTH-1) : (0)];


      end
   endgenerate

   
   assign rd_resp_desc_avail = int_rd_resp_free_desc_desc[XX_MAX_DESC-1:0];

   assign rd_resp_fifo_rden = rd_resp_fifo_pop_desc_conn_pulse;

   assign rd_resp_hm2uc_done = {XX_MAX_DESC{1'b0}};

   assign int_rd_resp_fifo_fill_level_fill = rd_resp_fifo_fill_level;

   ace_mst_rd_resp_ready #(
                           // Parameters
                           .ACE_PROTOCOL      (ACE_PROTOCOL),
                           .ACE_CHANNEL       ("MST_RD_RESP"),
                           .ADDR_WIDTH        (ADDR_WIDTH),
                           .DATA_WIDTH        (XX_DATA_WIDTH),
                           .ID_WIDTH          (ID_WIDTH),
                           .AWUSER_WIDTH      (AWUSER_WIDTH),
                           .WUSER_WIDTH       (WUSER_WIDTH),
                           .BUSER_WIDTH       (BUSER_WIDTH),
                           .ARUSER_WIDTH      (ARUSER_WIDTH),
                           .RUSER_WIDTH       (RUSER_WIDTH),
                           .INFBUS_WIDTH      (RD_RESP_INFBUS_WIDTH),
                           .TR_DESCBUS_WIDTH  (RD_RESP_TR_DESCBUS_WIDTH),
                           .CACHE_LINE_SIZE   (CACHE_LINE_SIZE),
                           .MAX_DESC          (XX_MAX_DESC),
                           .RAM_SIZE          (XX_RAM_SIZE)
			   ) r_ace_mst_rd_resp_ready (
						      // Outputs
						      .infbus_ready                   (m_ace_usr_rready),
						      .inf_xack                       (m_ace_usr_rack),
						      .arid_read_en                   (arid_read_en),
						      .error_status                   (r_channel_error_status),                        
						      .tr_descbus_0                   (rd_resp_tr_descbus_0),
						      .tr_descbus_1                   (rd_resp_tr_descbus_1),
						      .tr_descbus_2                   (rd_resp_tr_descbus_2),
						      .tr_descbus_3                   (rd_resp_tr_descbus_3),
						      .tr_descbus_4                   (rd_resp_tr_descbus_4),
						      .tr_descbus_5                   (rd_resp_tr_descbus_5),
						      .tr_descbus_6                   (rd_resp_tr_descbus_6),
						      .tr_descbus_7                   (rd_resp_tr_descbus_7),
						      .tr_descbus_8                   (rd_resp_tr_descbus_8),
						      .tr_descbus_9                   (rd_resp_tr_descbus_9),
						      .tr_descbus_A                   (rd_resp_tr_descbus_A),
						      .tr_descbus_B                   (rd_resp_tr_descbus_B),
						      .tr_descbus_C                   (rd_resp_tr_descbus_C),
						      .tr_descbus_D                   (rd_resp_tr_descbus_D),
						      .tr_descbus_E                   (rd_resp_tr_descbus_E),
						      .tr_descbus_F                   (rd_resp_tr_descbus_F),
						      .tr_descbus_dtoffset_0          (rd_resp_tr_descbus_dtoffset_0),
						      .tr_descbus_dtoffset_1          (rd_resp_tr_descbus_dtoffset_1),
						      .tr_descbus_dtoffset_2          (rd_resp_tr_descbus_dtoffset_2),
						      .tr_descbus_dtoffset_3          (rd_resp_tr_descbus_dtoffset_3),
						      .tr_descbus_dtoffset_4          (rd_resp_tr_descbus_dtoffset_4),
						      .tr_descbus_dtoffset_5          (rd_resp_tr_descbus_dtoffset_5),
						      .tr_descbus_dtoffset_6          (rd_resp_tr_descbus_dtoffset_6),
						      .tr_descbus_dtoffset_7          (rd_resp_tr_descbus_dtoffset_7),
						      .tr_descbus_dtoffset_8          (rd_resp_tr_descbus_dtoffset_8),
						      .tr_descbus_dtoffset_9          (rd_resp_tr_descbus_dtoffset_9),
						      .tr_descbus_dtoffset_A          (rd_resp_tr_descbus_dtoffset_A),
						      .tr_descbus_dtoffset_B          (rd_resp_tr_descbus_dtoffset_B),
						      .tr_descbus_dtoffset_C          (rd_resp_tr_descbus_dtoffset_C),
						      .tr_descbus_dtoffset_D          (rd_resp_tr_descbus_dtoffset_D),
						      .tr_descbus_dtoffset_E          (rd_resp_tr_descbus_dtoffset_E),
						      .tr_descbus_dtoffset_F          (rd_resp_tr_descbus_dtoffset_F),
						      .tr_descbus_len_0               (rd_resp_tr_descbus_len_0),
						      .tr_descbus_len_1               (rd_resp_tr_descbus_len_1),
						      .tr_descbus_len_2               (rd_resp_tr_descbus_len_2),
						      .tr_descbus_len_3               (rd_resp_tr_descbus_len_3),
						      .tr_descbus_len_4               (rd_resp_tr_descbus_len_4),
						      .tr_descbus_len_5               (rd_resp_tr_descbus_len_5),
						      .tr_descbus_len_6               (rd_resp_tr_descbus_len_6),
						      .tr_descbus_len_7               (rd_resp_tr_descbus_len_7),
						      .tr_descbus_len_8               (rd_resp_tr_descbus_len_8),
						      .tr_descbus_len_9               (rd_resp_tr_descbus_len_9),
						      .tr_descbus_len_A               (rd_resp_tr_descbus_len_A),
						      .tr_descbus_len_B               (rd_resp_tr_descbus_len_B),
						      .tr_descbus_len_C               (rd_resp_tr_descbus_len_C),
						      .tr_descbus_len_D               (rd_resp_tr_descbus_len_D),
						      .tr_descbus_len_E               (rd_resp_tr_descbus_len_E),
						      .tr_descbus_len_F               (rd_resp_tr_descbus_len_F),
						      .fifo_dout                      (rd_resp_fifo_dout),
						      .fifo_dout_valid                (rd_resp_fifo_dout_valid),
						      .fifo_fill_level                (rd_resp_fifo_fill_level),
						      .fifo_free_level                (rd_resp_fifo_free_level),
						      .uc2rb_we                       (uc2rb_wr_we),
						      .uc2rb_bwe                      (uc2rb_wr_bwe),
						      .uc2rb_addr                     (uc2rb_wr_addr),
						      .uc2rb_data                     (uc2rb_wr_data),
						      .uc2rb_wstrb                    (),
						      .uc2hm_trig                     (rd_uc2hm_trig),
						      // Inputs
						      .clk                            (clk),
						      .resetn                         (resetn),
						      .infbus                         (rd_resp_infbus), //r channel
						      .infbus_last                    (m_ace_usr_rlast),
						      .infbus_valid                   (m_ace_usr_rvalid),
						      .arid_response_id0              (arid_response_id0),
						      .arid_response_id1              (arid_response_id1),
						      .arid_response_id2              (arid_response_id2),
						      .arid_response_id3              (arid_response_id3),
						      .arid_response_id4              (arid_response_id4),
						      .arid_response_id5              (arid_response_id5),
						      .arid_response_id6              (arid_response_id6),
						      .arid_response_id7              (arid_response_id7),
						      .arid_response_id8              (arid_response_id8),
						      .arid_response_id9              (arid_response_id9),
						      .arid_response_idA              (arid_response_idA),
						      .arid_response_idB              (arid_response_idB),
						      .arid_response_idC              (arid_response_idC),
						      .arid_response_idD              (arid_response_idD),
						      .arid_response_idE              (arid_response_idE),
						      .arid_response_idF              (arid_response_idF),
						      .rd_fifo_id_reg0                (rd_fifo_id_reg0),
						      .rd_fifo_id_reg1                (rd_fifo_id_reg1),
						      .rd_fifo_id_reg2                (rd_fifo_id_reg2),
						      .rd_fifo_id_reg3                (rd_fifo_id_reg3),
						      .rd_fifo_id_reg4                (rd_fifo_id_reg4),
						      .rd_fifo_id_reg5                (rd_fifo_id_reg5),
						      .rd_fifo_id_reg6                (rd_fifo_id_reg6),
						      .rd_fifo_id_reg7                (rd_fifo_id_reg7),
						      .rd_fifo_id_reg8                (rd_fifo_id_reg8),
						      .rd_fifo_id_reg9                (rd_fifo_id_reg9),
						      .rd_fifo_id_regA                (rd_fifo_id_regA),
						      .rd_fifo_id_regB                (rd_fifo_id_regB),
						      .rd_fifo_id_regC                (rd_fifo_id_regC),
						      .rd_fifo_id_regD                (rd_fifo_id_regD),
						      .rd_fifo_id_regE                (rd_fifo_id_regE),
						      .rd_fifo_id_regF                (rd_fifo_id_regF),
						      .rd_fifo_id_reg_valid           (rd_fifo_id_reg_valid),
						      .ar_valid_ready                 (ar_valid_ready),
						      .ar_valid_ready_desc_idx        (ar_valid_ready_desc_idx),
						      .ar_valid_ready_arlen           (ar_valid_ready_arlen),
						      .ar_valid_ready_arid            (ar_valid_ready_arid),
						      .data_offset_0                  (rd_resp_data_offset_0),
						      .data_offset_1                  (rd_resp_data_offset_1),
						      .data_offset_2                  (rd_resp_data_offset_2),
						      .data_offset_3                  (rd_resp_data_offset_3),
						      .data_offset_4                  (rd_resp_data_offset_4),
						      .data_offset_5                  (rd_resp_data_offset_5),
						      .data_offset_6                  (rd_resp_data_offset_6),
						      .data_offset_7                  (rd_resp_data_offset_7),
						      .data_offset_8                  (rd_resp_data_offset_8),
						      .data_offset_9                  (rd_resp_data_offset_9),
						      .data_offset_A                  (rd_resp_data_offset_A),
						      .data_offset_B                  (rd_resp_data_offset_B),
						      .data_offset_C                  (rd_resp_data_offset_C),
						      .data_offset_D                  (rd_resp_data_offset_D),
						      .data_offset_E                  (rd_resp_data_offset_E),
						      .data_offset_F                  (rd_resp_data_offset_F),
						      .int_mode_select_mode_0_1       (int_mode_select_mode_0_1),
						      .error_clear                    (int_intr_error_clear_clr_err_0),                        
						      .desc_avail                     ({XX_MAX_DESC{1'b0}}),
						      .fifo_rden                      (rd_resp_fifo_rden),
						      .hm2uc_done                     (rd_hm2uc_done)
						      );

   


   
   ///////////////////////
     //AW-Channel
   //Description :
   //////////////////////

   localparam WR_REQAW_INFBUS_WIDTH                                         = {  ID_WIDTH
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
										 };
   

   localparam WR_REQAW_FR_DESCBUS_WIDTH                                     = WR_REQAW_INFBUS_WIDTH;

   wire [WR_REQAW_INFBUS_WIDTH-1:0]                                         wr_reqaw_infbus;

   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_n[XX_MAX_DESC-1:0];

   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_0;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_1;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_2;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_3;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_4;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_5;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_6;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_7;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_8;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_9;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_A;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_B;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_C;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_D;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_E;
   wire [WR_REQAW_FR_DESCBUS_WIDTH-1 :0] 				    wr_reqaw_fr_descbus_F;

   wire [7:0] 								    wr_reqaw_fr_descbus_len_0;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_1;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_2;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_3;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_4;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_5;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_6;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_7;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_8;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_9;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_A;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_B;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_C;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_D;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_E;
   wire [7:0] 								    wr_reqaw_fr_descbus_len_F;

   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_0;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_1;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_2;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_3;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_4;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_5;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_6;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_7;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_8;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_9;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_A;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_B;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_C;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_D;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_E;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					    wr_reqaw_fr_descbus_dtoffset_F;

   wire [XX_DESC_IDX_WIDTH:0] 						    wr_reqaw_fifo_fill_level;
   wire [XX_DESC_IDX_WIDTH:0] 						    wr_reqaw_fifo_free_level;

   wire [XX_MAX_DESC-1:0] 						    wr_reqaw_intr_comp_status_comp;

   reg 									    wr_reqaw_fifo_wren;
   wire [XX_DESC_IDX_WIDTH-1:0] 					    wr_reqaw_fifo_din;

   reg 									    wr_reqaw_push;
   reg 									    wr_reqaw_push_ff;

   wire [63:0] 								    fr_awaddr[XX_MAX_DESC-1:0];
   wire [7:0] 								    fr_awlen[XX_MAX_DESC-1:0];


   `FF_RSTLOW(clk,resetn,int_wr_req_fifo_push_desc_valid,wr_reqaw_push)
   `FF_RSTLOW(clk,resetn,wr_reqaw_push,wr_reqaw_push_ff)

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 wr_reqaw_fifo_wren <= 1'b0;  
      end else if (wr_reqaw_push==1'b1 && wr_reqaw_push_ff==1'b0) begin //Positive edge detection
	 wr_reqaw_fifo_wren <= 1'b1;
      end else begin
	 wr_reqaw_fifo_wren <= 1'b0;
      end
   end

   synchronizer#(
		 .SYNC_FF                                                       (2)  
		 ,.D_WIDTH                                                       (XX_DESC_IDX_WIDTH)
		 ) sync_wr_reqaw_fifo_din (
					   .ck                                                           (clk) 
					   ,.rn                                                           (resetn) 
					   ,.data_in                                                      (int_wr_req_fifo_push_desc_desc_index) 
					   ,.q_out                                                        (wr_reqaw_fifo_din)
					   );   




   assign {   m_ace_usr_awid 
              , m_ace_usr_awaddr 
              , m_ace_usr_awlen 
              , m_ace_usr_awsize 
              , m_ace_usr_awburst 
              , m_ace_usr_awlock 
              , m_ace_usr_awcache 
              , m_ace_usr_awprot 
              , m_ace_usr_awqos 
              , m_ace_usr_awregion 
              , m_ace_usr_awuser 
              , m_ace_usr_awsnoop 
              , m_ace_usr_awdomain 
              , m_ace_usr_awbar 
              , m_ace_usr_awunique
	      }                        = wr_reqaw_infbus;
   

   assign wr_reqaw_fr_descbus_0 = wr_reqaw_fr_descbus_n['h0];
   assign wr_reqaw_fr_descbus_1 = wr_reqaw_fr_descbus_n['h1];
   assign wr_reqaw_fr_descbus_2 = wr_reqaw_fr_descbus_n['h2];
   assign wr_reqaw_fr_descbus_3 = wr_reqaw_fr_descbus_n['h3];
   assign wr_reqaw_fr_descbus_4 = wr_reqaw_fr_descbus_n['h4];
   assign wr_reqaw_fr_descbus_5 = wr_reqaw_fr_descbus_n['h5];
   assign wr_reqaw_fr_descbus_6 = wr_reqaw_fr_descbus_n['h6];
   assign wr_reqaw_fr_descbus_7 = wr_reqaw_fr_descbus_n['h7];
   assign wr_reqaw_fr_descbus_8 = wr_reqaw_fr_descbus_n['h8];
   assign wr_reqaw_fr_descbus_9 = wr_reqaw_fr_descbus_n['h9];
   assign wr_reqaw_fr_descbus_A = wr_reqaw_fr_descbus_n['hA];
   assign wr_reqaw_fr_descbus_B = wr_reqaw_fr_descbus_n['hB];
   assign wr_reqaw_fr_descbus_C = wr_reqaw_fr_descbus_n['hC];
   assign wr_reqaw_fr_descbus_D = wr_reqaw_fr_descbus_n['hD];
   assign wr_reqaw_fr_descbus_E = wr_reqaw_fr_descbus_n['hE];
   assign wr_reqaw_fr_descbus_F = wr_reqaw_fr_descbus_n['hF];


   generate
      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_wr_reqaw_fr_descbus_n

	 assign fr_awaddr[gi] = {int_wr_req_desc_n_axaddr_1_addr[gi],int_wr_req_desc_n_axaddr_0_addr[gi]};  
	 assign fr_awlen[gi] = ( ((int_wr_req_desc_n_size_txn_size[gi]*8)/XX_DATA_WIDTH) - 1 );  

	 assign wr_reqaw_fr_descbus_n[gi] = {  int_wr_req_desc_n_axid_0_axid[gi][(0) +: (ID_WIDTH)]
					       , fr_awaddr[gi][(0) +: (ADDR_WIDTH)] 
					       , fr_awlen[gi] 
					       , int_wr_req_desc_n_axsize_axsize[gi][(0) +: (AXSIZE_WIDTH)]
					       , int_wr_req_desc_n_attr_axburst[gi][(0) +: (AXBURST_WIDTH)]
					       , int_wr_req_desc_n_attr_axlock[gi][(0) +: (AXLOCK_WIDTH)]
					       , int_wr_req_desc_n_attr_axcache[gi][(0) +: (AXCACHE_WIDTH)]
					       , int_wr_req_desc_n_attr_axprot[gi][(0) +: (AXPROT_WIDTH)]
					       , int_wr_req_desc_n_attr_axqos[gi][(0) +: (AXQOS_WIDTH)]
					       , int_wr_req_desc_n_attr_axregion[gi][(0) +: (AXREGION_WIDTH)]
					       , int_wr_req_desc_n_axuser_0_axuser[gi][(0) +: (AWUSER_WIDTH)]
					       , int_wr_req_desc_n_attr_axsnoop[gi][(0) +: (AWSNOOP_WIDTH)]
					       , int_wr_req_desc_n_attr_axdomain[gi][(0) +: (AXDOMAIN_WIDTH)]
					       , int_wr_req_desc_n_attr_axbar[gi][(0) +: (AXBAR_WIDTH)]
					       , int_wr_req_desc_n_attr_awunique[gi][(0) +: (AWUNIQUE_WIDTH)]
					       };

      end
   endgenerate
   
   assign wr_reqaw_fr_descbus_len_0 = 'b0;
   assign wr_reqaw_fr_descbus_len_1 = 'b0;
   assign wr_reqaw_fr_descbus_len_2 = 'b0;
   assign wr_reqaw_fr_descbus_len_3 = 'b0;
   assign wr_reqaw_fr_descbus_len_4 = 'b0;
   assign wr_reqaw_fr_descbus_len_5 = 'b0;
   assign wr_reqaw_fr_descbus_len_6 = 'b0;
   assign wr_reqaw_fr_descbus_len_7 = 'b0;
   assign wr_reqaw_fr_descbus_len_8 = 'b0;
   assign wr_reqaw_fr_descbus_len_9 = 'b0;
   assign wr_reqaw_fr_descbus_len_A = 'b0;
   assign wr_reqaw_fr_descbus_len_B = 'b0;
   assign wr_reqaw_fr_descbus_len_C = 'b0;
   assign wr_reqaw_fr_descbus_len_D = 'b0;
   assign wr_reqaw_fr_descbus_len_E = 'b0;
   assign wr_reqaw_fr_descbus_len_F = 'b0;

   assign wr_reqaw_fr_descbus_dtoffset_0 = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_1 = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_2 = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_3 = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_4 = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_5 = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_6 = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_7 = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_8 = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_9 = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_A = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_B = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_C = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_D = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_E = 'b0;
   assign wr_reqaw_fr_descbus_dtoffset_F = 'b0;

   ace_ctrl_valid #(
                    // Parameters
                    .ACE_PROTOCOL          (ACE_PROTOCOL),
                    .ACE_CHANNEL           ("MST_WR_REQ_AW"),
                    .ADDR_WIDTH            (ADDR_WIDTH),
                    .DATA_WIDTH            (XX_DATA_WIDTH),
                    .ID_WIDTH              (ID_WIDTH),
                    .AWUSER_WIDTH          (AWUSER_WIDTH),
                    .WUSER_WIDTH           (WUSER_WIDTH),
                    .BUSER_WIDTH           (BUSER_WIDTH),
                    .ARUSER_WIDTH          (ARUSER_WIDTH),
                    .RUSER_WIDTH           (RUSER_WIDTH),
                    .INFBUS_WIDTH          (WR_REQAW_INFBUS_WIDTH),
                    .FR_DESCBUS_WIDTH      (WR_REQAW_FR_DESCBUS_WIDTH),
                    .CACHE_LINE_SIZE       (CACHE_LINE_SIZE),
                    .MAX_DESC              (XX_MAX_DESC),
                    .RAM_SIZE              (XX_RAM_SIZE)
		    ) aw_ace_ctrl_valid (
					 // Outputs
					 .infbus               (wr_reqaw_infbus),  //aw channel
					 .infbus_last          (),
					 .infbus_valid         (m_ace_usr_awvalid),
					 .fifo_fill_level      (wr_reqaw_fifo_fill_level),
					 .fifo_free_level      (wr_reqaw_fifo_free_level),
					 .intr_comp_status_comp(wr_reqaw_intr_comp_status_comp),
					 .uc2rb_addr           (),
					 .uc2hm_trig           (),
					 // Inputs
					 .clk                  (clk),
					 .resetn               (resetn),
					 .infbus_ready         (m_ace_usr_awready),
					 .inf_xack             ('b0),
					 .fr_descbus_0         (wr_reqaw_fr_descbus_0),
					 .fr_descbus_1         (wr_reqaw_fr_descbus_1),
					 .fr_descbus_2         (wr_reqaw_fr_descbus_2),
					 .fr_descbus_3         (wr_reqaw_fr_descbus_3),
					 .fr_descbus_4         (wr_reqaw_fr_descbus_4),
					 .fr_descbus_5         (wr_reqaw_fr_descbus_5),
					 .fr_descbus_6         (wr_reqaw_fr_descbus_6),
					 .fr_descbus_7         (wr_reqaw_fr_descbus_7),
					 .fr_descbus_8         (wr_reqaw_fr_descbus_8),
					 .fr_descbus_9         (wr_reqaw_fr_descbus_9),
					 .fr_descbus_A         (wr_reqaw_fr_descbus_A),
					 .fr_descbus_B         (wr_reqaw_fr_descbus_B),
					 .fr_descbus_C         (wr_reqaw_fr_descbus_C),
					 .fr_descbus_D         (wr_reqaw_fr_descbus_D),
					 .fr_descbus_E         (wr_reqaw_fr_descbus_E),
					 .fr_descbus_F         (wr_reqaw_fr_descbus_F),
					 .fr_descbus_len_0     (wr_reqaw_fr_descbus_len_0),
					 .fr_descbus_len_1     (wr_reqaw_fr_descbus_len_1),
					 .fr_descbus_len_2     (wr_reqaw_fr_descbus_len_2),
					 .fr_descbus_len_3     (wr_reqaw_fr_descbus_len_3),
					 .fr_descbus_len_4     (wr_reqaw_fr_descbus_len_4),
					 .fr_descbus_len_5     (wr_reqaw_fr_descbus_len_5),
					 .fr_descbus_len_6     (wr_reqaw_fr_descbus_len_6),
					 .fr_descbus_len_7     (wr_reqaw_fr_descbus_len_7),
					 .fr_descbus_len_8     (wr_reqaw_fr_descbus_len_8),
					 .fr_descbus_len_9     (wr_reqaw_fr_descbus_len_9),
					 .fr_descbus_len_A     (wr_reqaw_fr_descbus_len_A),
					 .fr_descbus_len_B     (wr_reqaw_fr_descbus_len_B),
					 .fr_descbus_len_C     (wr_reqaw_fr_descbus_len_C),
					 .fr_descbus_len_D     (wr_reqaw_fr_descbus_len_D),
					 .fr_descbus_len_E     (wr_reqaw_fr_descbus_len_E),
					 .fr_descbus_len_F     (wr_reqaw_fr_descbus_len_F),
					 .fr_descbus_dtoffset_0(wr_reqaw_fr_descbus_dtoffset_0),
					 .fr_descbus_dtoffset_1(wr_reqaw_fr_descbus_dtoffset_1),
					 .fr_descbus_dtoffset_2(wr_reqaw_fr_descbus_dtoffset_2),
					 .fr_descbus_dtoffset_3(wr_reqaw_fr_descbus_dtoffset_3),
					 .fr_descbus_dtoffset_4(wr_reqaw_fr_descbus_dtoffset_4),
					 .fr_descbus_dtoffset_5(wr_reqaw_fr_descbus_dtoffset_5),
					 .fr_descbus_dtoffset_6(wr_reqaw_fr_descbus_dtoffset_6),
					 .fr_descbus_dtoffset_7(wr_reqaw_fr_descbus_dtoffset_7),
					 .fr_descbus_dtoffset_8(wr_reqaw_fr_descbus_dtoffset_8),
					 .fr_descbus_dtoffset_9(wr_reqaw_fr_descbus_dtoffset_9),
					 .fr_descbus_dtoffset_A(wr_reqaw_fr_descbus_dtoffset_A),
					 .fr_descbus_dtoffset_B(wr_reqaw_fr_descbus_dtoffset_B),
					 .fr_descbus_dtoffset_C(wr_reqaw_fr_descbus_dtoffset_C),
					 .fr_descbus_dtoffset_D(wr_reqaw_fr_descbus_dtoffset_D),
					 .fr_descbus_dtoffset_E(wr_reqaw_fr_descbus_dtoffset_E),
					 .fr_descbus_dtoffset_F(wr_reqaw_fr_descbus_dtoffset_F),
					 .int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					 .txn_type_wr_strb     ({XX_MAX_DESC{1'b0}}),
					 .fifo_wren            (wr_reqaw_fifo_wren),
					 .fifo_din             (wr_reqaw_fifo_din),
					 .intr_comp_clear_clr_comp(int_wr_req_intr_comp_clear_clr_comp),
					 .rb2uc_data           ({XX_DATA_WIDTH{1'b0}}),
					 .rb2uc_wstrb          ({WSTRB_WIDTH{1'b0}}),
					 .hm2uc_done           ({XX_MAX_DESC{1'b0}})
					 );
   

   ///////////////////////
     //W-Channel
   //Description :
   //////////////////////
   

   localparam WR_REQW_INFBUS_WIDTH                                         = (   XX_DATA_WIDTH
										 + WSTRB_WIDTH
										 + WUSER_WIDTH
										 );


   

   localparam WR_REQW_FR_DESCBUS_WIDTH                                     = WR_REQW_INFBUS_WIDTH;

   wire [WR_REQW_INFBUS_WIDTH-1:0]                                         wr_reqw_infbus;

   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_n[XX_MAX_DESC-1:0];

   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_0;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_1;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_2;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_3;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_4;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_5;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_6;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_7;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_8;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_9;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_A;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_B;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_C;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_D;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_E;
   wire [WR_REQW_FR_DESCBUS_WIDTH-1 :0] 				   wr_reqw_fr_descbus_F;

   wire [7:0] 								   wr_reqw_fr_descbus_len_0;
   wire [7:0] 								   wr_reqw_fr_descbus_len_1;
   wire [7:0] 								   wr_reqw_fr_descbus_len_2;
   wire [7:0] 								   wr_reqw_fr_descbus_len_3;
   wire [7:0] 								   wr_reqw_fr_descbus_len_4;
   wire [7:0] 								   wr_reqw_fr_descbus_len_5;
   wire [7:0] 								   wr_reqw_fr_descbus_len_6;
   wire [7:0] 								   wr_reqw_fr_descbus_len_7;
   wire [7:0] 								   wr_reqw_fr_descbus_len_8;
   wire [7:0] 								   wr_reqw_fr_descbus_len_9;
   wire [7:0] 								   wr_reqw_fr_descbus_len_A;
   wire [7:0] 								   wr_reqw_fr_descbus_len_B;
   wire [7:0] 								   wr_reqw_fr_descbus_len_C;
   wire [7:0] 								   wr_reqw_fr_descbus_len_D;
   wire [7:0] 								   wr_reqw_fr_descbus_len_E;
   wire [7:0] 								   wr_reqw_fr_descbus_len_F;

   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_0;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_1;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_2;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_3;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_4;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_5;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_6;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_7;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_8;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_9;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_A;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_B;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_C;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_D;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_E;
   wire [XX_RAM_OFFSET_WIDTH-1:0] 					   wr_reqw_fr_descbus_dtoffset_F;

   wire [XX_DESC_IDX_WIDTH:0] 						   wr_reqw_fifo_fill_level;
   wire [XX_DESC_IDX_WIDTH:0] 						   wr_reqw_fifo_free_level;

   wire [XX_MAX_DESC-1:0] 						   wr_reqw_intr_comp_status_comp;

   reg                                                                     wr_reqw_fifo_wren;
   wire [XX_DESC_IDX_WIDTH-1:0] 					   wr_reqw_fifo_din;

   reg                                                                     wr_reqw_push;
   reg                                                                     wr_reqw_push_ff;

   wire [AXBAR_WIDTH-1+AXDOMAIN_WIDTH+AWSNOOP_WIDTH-1:0] 		   write_txn[XX_MAX_DESC-1:0];

   reg [XX_DESC_IDX_WIDTH-1:0] 						   wr_reqw_push_desc_ff;

   assign int_wr_req_fifo_free_level_free = (wr_reqaw_fifo_free_level<wr_reqw_fifo_free_level) ? (wr_reqaw_fifo_free_level) : (wr_reqw_fifo_free_level);  

   `FF_RSTLOW(clk,resetn,int_wr_req_fifo_push_desc_valid,wr_reqw_push)  
   `FF_RSTLOW(clk,resetn,wr_reqw_push,wr_reqw_push_ff)

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 wr_reqw_fifo_wren <= 1'b0;  
      end else if (wr_reqw_push==1'b1 && wr_reqw_push_ff==1'b0) begin //Positive edge detection
	 //If txn is of type - (AW, B, WACK)  (No W)
	 if (    (write_txn[wr_reqw_push_desc_ff] == `WR_TXN_EVICT_0        )
		 || (write_txn[wr_reqw_push_desc_ff] == `WR_TXN_EVICT_1        )
		 || (write_txn[wr_reqw_push_desc_ff] == `WR_TXN_BARRIER_0      )
		 || (write_txn[wr_reqw_push_desc_ff] == `WR_TXN_BARRIER_1      )
		 || (write_txn[wr_reqw_push_desc_ff] == `WR_TXN_BARRIER_2      )
		 || (write_txn[wr_reqw_push_desc_ff] == `WR_TXN_BARRIER_3      )
		 ) begin
	    wr_reqw_fifo_wren <= 1'b0;  //don't push desc to w-channel FIFO
	 end else begin
	    wr_reqw_fifo_wren <= 1'b1;
	 end
      end else begin
	 wr_reqw_fifo_wren <= 1'b0;
      end
   end

   `FF_RSTLOW(clk,resetn,int_wr_req_fifo_push_desc_desc_index,wr_reqw_push_desc_ff)

   synchronizer#(
		 .SYNC_FF                                                       (2)  
		 ,.D_WIDTH                                                       (XX_DESC_IDX_WIDTH)
		 ) sync_wr_reqw_fifo_din (
					  .ck                                                           (clk) 
					  ,.rn                                                           (resetn) 
					  ,.data_in                                                      (int_wr_req_fifo_push_desc_desc_index)
					  ,.q_out                                                        (wr_reqw_fifo_din)
					  );   




   generate 

      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_write_txn
	 
	 assign write_txn[gi]  = { 
				   int_wr_req_desc_n_attr_axbar[gi][(0) +: (AXBAR_WIDTH-1)]
				   , int_wr_req_desc_n_attr_axdomain[gi][(0) +: (AXDOMAIN_WIDTH)]
				   , int_wr_req_desc_n_attr_axsnoop[gi][(0) +: (AWSNOOP_WIDTH)]
				   };

      end

   endgenerate

   always @(*) begin 

      for (i=0; i<=XX_MAX_DESC-1; i=i+1) begin: for_write_txn

	 //If txn is of type - (AW, B, WACK)  (No W)
	 if (    (write_txn[i] == `WR_TXN_EVICT_0        )
		 || (write_txn[i] == `WR_TXN_EVICT_1        )
		 || (write_txn[i] == `WR_TXN_BARRIER_0      )
		 || (write_txn[i] == `WR_TXN_BARRIER_1      )
		 || (write_txn[i] == `WR_TXN_BARRIER_2      )
		 || (write_txn[i] == `WR_TXN_BARRIER_3      )
		 ) begin
	    int_wr_req_intr_comp_status_comp[i] <= ( wr_reqaw_intr_comp_status_comp[i] ); 
	 end else begin
	    int_wr_req_intr_comp_status_comp[i] <= ( wr_reqaw_intr_comp_status_comp[i] && wr_reqw_intr_comp_status_comp[i] ); 
	 end

      end

   end

   assign {   m_ace_usr_wdata
              , m_ace_usr_wstrb 
              , m_ace_usr_wuser
	      }                        = wr_reqw_infbus;

   

   assign wr_reqw_fr_descbus_0 = wr_reqw_fr_descbus_n['h0];
   assign wr_reqw_fr_descbus_1 = wr_reqw_fr_descbus_n['h1];
   assign wr_reqw_fr_descbus_2 = wr_reqw_fr_descbus_n['h2];
   assign wr_reqw_fr_descbus_3 = wr_reqw_fr_descbus_n['h3];
   assign wr_reqw_fr_descbus_4 = wr_reqw_fr_descbus_n['h4];
   assign wr_reqw_fr_descbus_5 = wr_reqw_fr_descbus_n['h5];
   assign wr_reqw_fr_descbus_6 = wr_reqw_fr_descbus_n['h6];
   assign wr_reqw_fr_descbus_7 = wr_reqw_fr_descbus_n['h7];
   assign wr_reqw_fr_descbus_8 = wr_reqw_fr_descbus_n['h8];
   assign wr_reqw_fr_descbus_9 = wr_reqw_fr_descbus_n['h9];
   assign wr_reqw_fr_descbus_A = wr_reqw_fr_descbus_n['hA];
   assign wr_reqw_fr_descbus_B = wr_reqw_fr_descbus_n['hB];
   assign wr_reqw_fr_descbus_C = wr_reqw_fr_descbus_n['hC];
   assign wr_reqw_fr_descbus_D = wr_reqw_fr_descbus_n['hD];
   assign wr_reqw_fr_descbus_E = wr_reqw_fr_descbus_n['hE];
   assign wr_reqw_fr_descbus_F = wr_reqw_fr_descbus_n['hF];


   generate
      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_wr_reqw_fr_descbus_n

	 assign wr_reqw_fr_descbus_n[gi] = {   {XX_DATA_WIDTH{1'b0}}
					       , {WSTRB_WIDTH{1'b0}}
					       , int_wr_req_desc_n_wuser_0_wuser[gi][(0) +: (WUSER_WIDTH)] 
					       };

      end
   endgenerate
   
   assign wr_reqw_fr_descbus_len_0 = ( ((int_wr_req_desc_n_size_txn_size['h0]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_1 = ( ((int_wr_req_desc_n_size_txn_size['h1]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_2 = ( ((int_wr_req_desc_n_size_txn_size['h2]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_3 = ( ((int_wr_req_desc_n_size_txn_size['h3]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_4 = ( ((int_wr_req_desc_n_size_txn_size['h4]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_5 = ( ((int_wr_req_desc_n_size_txn_size['h5]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_6 = ( ((int_wr_req_desc_n_size_txn_size['h6]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_7 = ( ((int_wr_req_desc_n_size_txn_size['h7]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_8 = ( ((int_wr_req_desc_n_size_txn_size['h8]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_9 = ( ((int_wr_req_desc_n_size_txn_size['h9]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_A = ( ((int_wr_req_desc_n_size_txn_size['hA]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_B = ( ((int_wr_req_desc_n_size_txn_size['hB]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_C = ( ((int_wr_req_desc_n_size_txn_size['hC]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_D = ( ((int_wr_req_desc_n_size_txn_size['hD]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_E = ( ((int_wr_req_desc_n_size_txn_size['hE]*8)/XX_DATA_WIDTH) - 1 );
   assign wr_reqw_fr_descbus_len_F = ( ((int_wr_req_desc_n_size_txn_size['hF]*8)/XX_DATA_WIDTH) - 1 );

   assign wr_reqw_fr_descbus_dtoffset_0 = (int_wr_req_desc_n_data_offset_addr['h0]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_1 = (int_wr_req_desc_n_data_offset_addr['h1]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_2 = (int_wr_req_desc_n_data_offset_addr['h2]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_3 = (int_wr_req_desc_n_data_offset_addr['h3]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_4 = (int_wr_req_desc_n_data_offset_addr['h4]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_5 = (int_wr_req_desc_n_data_offset_addr['h5]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_6 = (int_wr_req_desc_n_data_offset_addr['h6]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_7 = (int_wr_req_desc_n_data_offset_addr['h7]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_8 = (int_wr_req_desc_n_data_offset_addr['h8]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_9 = (int_wr_req_desc_n_data_offset_addr['h9]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_A = (int_wr_req_desc_n_data_offset_addr['hA]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_B = (int_wr_req_desc_n_data_offset_addr['hB]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_C = (int_wr_req_desc_n_data_offset_addr['hC]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_D = (int_wr_req_desc_n_data_offset_addr['hD]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_E = (int_wr_req_desc_n_data_offset_addr['hE]*8/XX_DATA_WIDTH);
   assign wr_reqw_fr_descbus_dtoffset_F = (int_wr_req_desc_n_data_offset_addr['hF]*8/XX_DATA_WIDTH);

   ace_ctrl_valid #(
                    // Parameters
                    .ACE_PROTOCOL          (ACE_PROTOCOL),
                    .ACE_CHANNEL           ("MST_WR_REQ_W"),
                    .ADDR_WIDTH            (ADDR_WIDTH),
                    .DATA_WIDTH            (XX_DATA_WIDTH),
                    .ID_WIDTH              (ID_WIDTH),
                    .AWUSER_WIDTH          (AWUSER_WIDTH),
                    .WUSER_WIDTH           (WUSER_WIDTH),
                    .BUSER_WIDTH           (BUSER_WIDTH),
                    .ARUSER_WIDTH          (ARUSER_WIDTH),
                    .RUSER_WIDTH           (RUSER_WIDTH),
                    .INFBUS_WIDTH          (WR_REQW_INFBUS_WIDTH),
                    .FR_DESCBUS_WIDTH      (WR_REQW_FR_DESCBUS_WIDTH),
                    .CACHE_LINE_SIZE       (CACHE_LINE_SIZE),
                    .MAX_DESC              (XX_MAX_DESC),
                    .RAM_SIZE              (XX_RAM_SIZE)
		    ) w_ace_ctrl_valid (
					// Outputs
					.infbus               (wr_reqw_infbus),  //w channel
					.infbus_last          (m_ace_usr_wlast),
					.infbus_valid         (m_ace_usr_wvalid),
					.fifo_fill_level      (wr_reqw_fifo_fill_level),
					.fifo_free_level      (wr_reqw_fifo_free_level),
					.intr_comp_status_comp(wr_reqw_intr_comp_status_comp),
					.uc2rb_addr           (uc2rb_rd_addr),
					.uc2hm_trig           (wr_uc2hm_trig),
					// Inputs
					.clk                  (clk),
					.resetn               (resetn),
					.infbus_ready         (m_ace_usr_wready),
					.inf_xack             ('b0),
					.fr_descbus_0         (wr_reqw_fr_descbus_0),
					.fr_descbus_1         (wr_reqw_fr_descbus_1),
					.fr_descbus_2         (wr_reqw_fr_descbus_2),
					.fr_descbus_3         (wr_reqw_fr_descbus_3),
					.fr_descbus_4         (wr_reqw_fr_descbus_4),
					.fr_descbus_5         (wr_reqw_fr_descbus_5),
					.fr_descbus_6         (wr_reqw_fr_descbus_6),
					.fr_descbus_7         (wr_reqw_fr_descbus_7),
					.fr_descbus_8         (wr_reqw_fr_descbus_8),
					.fr_descbus_9         (wr_reqw_fr_descbus_9),
					.fr_descbus_A         (wr_reqw_fr_descbus_A),
					.fr_descbus_B         (wr_reqw_fr_descbus_B),
					.fr_descbus_C         (wr_reqw_fr_descbus_C),
					.fr_descbus_D         (wr_reqw_fr_descbus_D),
					.fr_descbus_E         (wr_reqw_fr_descbus_E),
					.fr_descbus_F         (wr_reqw_fr_descbus_F),
					.fr_descbus_len_0     (wr_reqw_fr_descbus_len_0),
					.fr_descbus_len_1     (wr_reqw_fr_descbus_len_1),
					.fr_descbus_len_2     (wr_reqw_fr_descbus_len_2),
					.fr_descbus_len_3     (wr_reqw_fr_descbus_len_3),
					.fr_descbus_len_4     (wr_reqw_fr_descbus_len_4),
					.fr_descbus_len_5     (wr_reqw_fr_descbus_len_5),
					.fr_descbus_len_6     (wr_reqw_fr_descbus_len_6),
					.fr_descbus_len_7     (wr_reqw_fr_descbus_len_7),
					.fr_descbus_len_8     (wr_reqw_fr_descbus_len_8),
					.fr_descbus_len_9     (wr_reqw_fr_descbus_len_9),
					.fr_descbus_len_A     (wr_reqw_fr_descbus_len_A),
					.fr_descbus_len_B     (wr_reqw_fr_descbus_len_B),
					.fr_descbus_len_C     (wr_reqw_fr_descbus_len_C),
					.fr_descbus_len_D     (wr_reqw_fr_descbus_len_D),
					.fr_descbus_len_E     (wr_reqw_fr_descbus_len_E),
					.fr_descbus_len_F     (wr_reqw_fr_descbus_len_F),
					.fr_descbus_dtoffset_0(wr_reqw_fr_descbus_dtoffset_0),
					.fr_descbus_dtoffset_1(wr_reqw_fr_descbus_dtoffset_1),
					.fr_descbus_dtoffset_2(wr_reqw_fr_descbus_dtoffset_2),
					.fr_descbus_dtoffset_3(wr_reqw_fr_descbus_dtoffset_3),
					.fr_descbus_dtoffset_4(wr_reqw_fr_descbus_dtoffset_4),
					.fr_descbus_dtoffset_5(wr_reqw_fr_descbus_dtoffset_5),
					.fr_descbus_dtoffset_6(wr_reqw_fr_descbus_dtoffset_6),
					.fr_descbus_dtoffset_7(wr_reqw_fr_descbus_dtoffset_7),
					.fr_descbus_dtoffset_8(wr_reqw_fr_descbus_dtoffset_8),
					.fr_descbus_dtoffset_9(wr_reqw_fr_descbus_dtoffset_9),
					.fr_descbus_dtoffset_A(wr_reqw_fr_descbus_dtoffset_A),
					.fr_descbus_dtoffset_B(wr_reqw_fr_descbus_dtoffset_B),
					.fr_descbus_dtoffset_C(wr_reqw_fr_descbus_dtoffset_C),
					.fr_descbus_dtoffset_D(wr_reqw_fr_descbus_dtoffset_D),
					.fr_descbus_dtoffset_E(wr_reqw_fr_descbus_dtoffset_E),
					.fr_descbus_dtoffset_F(wr_reqw_fr_descbus_dtoffset_F),
					.int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					.txn_type_wr_strb     (int_wr_req_desc_n_txn_type_wr_strb),
					.fifo_wren            (wr_reqw_fifo_wren),
					.fifo_din             (wr_reqw_fifo_din),
					.intr_comp_clear_clr_comp(int_wr_req_intr_comp_clear_clr_comp),
					.rb2uc_data           (rb2uc_rd_data),
					.rb2uc_wstrb          (rb2uc_rd_wstrb),
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




   localparam WR_RESP_TR_DESCBUS_WIDTH                                      = WR_RESP_INFBUS_WIDTH; 

   localparam WR_RESP_AW_INFBUS_WIDTH_DUMMY                                 = 1; 


   wire [WR_RESP_INFBUS_WIDTH-1:0]                                          wr_resp_infbus;

   wire [XX_DESC_IDX_WIDTH-1:0] 					    wr_resp_fifo_dout;
   wire 								    wr_resp_fifo_dout_valid;  //it is one clock cycle pulse
   wire [XX_DESC_IDX_WIDTH:0] 						    wr_resp_fifo_fill_level;
   wire [XX_DESC_IDX_WIDTH:0] 						    wr_resp_fifo_free_level;

   wire [XX_MAX_DESC-1:0] 						    wr_resp_desc_avail;
   wire 								    wr_resp_fifo_rden;   //should be one clock cycle pulse

   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_0;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_1;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_2;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_3;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_4;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_5;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_6;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_7;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_8;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_9;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_A;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_B;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_C;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_D;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_E;
   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_F;

   wire [WR_RESP_TR_DESCBUS_WIDTH-1 :0] 				    wr_resp_tr_descbus_n[XX_MAX_DESC-1:0];
   
   //wire wr_resp_fifo_pop_desc_conn_pulse;
   reg 									    wr_resp_fifo_pop_desc_conn_pulse;

   reg 									    wr_resp_fifo_pop_desc_conn_ff;

   assign int_wr_resp_fifo_pop_desc_valid = 'b0;
   assign int_wr_resp_fifo_pop_desc_desc_index = 'b0;

   `FF_RSTLOW(clk,resetn,wr_resp_fifo_pop_desc_conn,wr_resp_fifo_pop_desc_conn_ff)

   //assign wr_resp_fifo_pop_desc_conn_pulse = ( (wr_resp_fifo_pop_desc_conn) & (~wr_resp_fifo_pop_desc_conn_ff) );

   assign wr_resp_fifo_out = wr_resp_fifo_dout; 
   assign wr_resp_fifo_out_valid = wr_resp_fifo_dout_valid;

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 wr_resp_fifo_pop_desc_conn_pulse <= 1'b0;
      end else if (wr_resp_fifo_pop_desc_conn==1'b1 && wr_resp_fifo_pop_desc_conn_ff==1'b0) begin //Positive edge detection
	 wr_resp_fifo_pop_desc_conn_pulse <= 1'b1;
      end else begin
	 wr_resp_fifo_pop_desc_conn_pulse <= 1'b0;
      end
   end

   assign wr_resp_infbus                                                    = {   m_ace_usr_bid
										  , m_ace_usr_bresp
										  , m_ace_usr_buser
										  };
   

   assign wr_resp_tr_descbus_n['h0] = wr_resp_tr_descbus_0;
   assign wr_resp_tr_descbus_n['h1] = wr_resp_tr_descbus_1;
   assign wr_resp_tr_descbus_n['h2] = wr_resp_tr_descbus_2;
   assign wr_resp_tr_descbus_n['h3] = wr_resp_tr_descbus_3;
   assign wr_resp_tr_descbus_n['h4] = wr_resp_tr_descbus_4;
   assign wr_resp_tr_descbus_n['h5] = wr_resp_tr_descbus_5;
   assign wr_resp_tr_descbus_n['h6] = wr_resp_tr_descbus_6;
   assign wr_resp_tr_descbus_n['h7] = wr_resp_tr_descbus_7;
   assign wr_resp_tr_descbus_n['h8] = wr_resp_tr_descbus_8;
   assign wr_resp_tr_descbus_n['h9] = wr_resp_tr_descbus_9;
   assign wr_resp_tr_descbus_n['hA] = wr_resp_tr_descbus_A;
   assign wr_resp_tr_descbus_n['hB] = wr_resp_tr_descbus_B;
   assign wr_resp_tr_descbus_n['hC] = wr_resp_tr_descbus_C;
   assign wr_resp_tr_descbus_n['hD] = wr_resp_tr_descbus_D;
   assign wr_resp_tr_descbus_n['hE] = wr_resp_tr_descbus_E;
   assign wr_resp_tr_descbus_n['hF] = wr_resp_tr_descbus_F;


   generate

      for (gi=0; gi<=XX_MAX_DESC-1; gi=gi+1) begin: gen_int_wr_resp_desc

	 assign int_wr_resp_desc_n_xid_0_xid[gi][31:0] = { {(32-ID_WIDTH){1'b0}} , wr_resp_tr_descbus_n[gi][(WR_RESP_TR_DESCBUS_WIDTH-1) -: (ID_WIDTH)] };
	 assign int_wr_resp_desc_n_resp_resp[gi][4:0] = { {(5-BRESP_WIDTH){1'b0}} , wr_resp_tr_descbus_n[gi][(WR_RESP_TR_DESCBUS_WIDTH-ID_WIDTH-1) -: (BRESP_WIDTH)] };                                
	 assign int_wr_resp_desc_n_xuser_0_xuser[gi][31:0] = (wr_resp_tr_descbus_n[gi][(WR_RESP_TR_DESCBUS_WIDTH-ID_WIDTH-BRESP_WIDTH-1) -: (BUSER_WIDTH)]);
         
      end
   endgenerate

   assign wr_resp_desc_avail = int_wr_resp_free_desc_desc[XX_MAX_DESC-1:0];

   assign wr_resp_fifo_rden = wr_resp_fifo_pop_desc_conn_pulse;

   assign int_wr_resp_fifo_fill_level_fill = wr_resp_fifo_fill_level;

   ace_ctrl_ready #(
                    // Parameters
                    .ACE_PROTOCOL           (ACE_PROTOCOL),
                    .ACE_CHANNEL            ("MST_WR_RESP"),
                    .ADDR_WIDTH             (ADDR_WIDTH),
                    .DATA_WIDTH             (XX_DATA_WIDTH),
                    .ID_WIDTH               (ID_WIDTH),
                    .AWUSER_WIDTH           (AWUSER_WIDTH),
                    .WUSER_WIDTH            (WUSER_WIDTH),
                    .BUSER_WIDTH            (BUSER_WIDTH),
                    .ARUSER_WIDTH           (ARUSER_WIDTH),
                    .RUSER_WIDTH            (RUSER_WIDTH),
                    .INFBUS_WIDTH           (WR_RESP_INFBUS_WIDTH),
                    .TR_DESCBUS_WIDTH       (WR_RESP_TR_DESCBUS_WIDTH),
                    .AW_INFBUS_WIDTH        (WR_RESP_AW_INFBUS_WIDTH_DUMMY),
                    .AW_TR_DESCBUS_WIDTH    (1),
                    .CACHE_LINE_SIZE        (CACHE_LINE_SIZE),
                    .MAX_DESC               (XX_MAX_DESC),
                    .RAM_SIZE               (XX_RAM_SIZE)
		    ) b_ace_ctrl_ready (
					// Outputs
					.infbus_ready         (m_ace_usr_bready),
					.inf_xack             (m_ace_usr_wack),
					.aw_infbus_ready      (),
					.tr_descbus_0         (wr_resp_tr_descbus_0),
					.tr_descbus_1         (wr_resp_tr_descbus_1),
					.tr_descbus_2         (wr_resp_tr_descbus_2),
					.tr_descbus_3         (wr_resp_tr_descbus_3),
					.tr_descbus_4         (wr_resp_tr_descbus_4),
					.tr_descbus_5         (wr_resp_tr_descbus_5),
					.tr_descbus_6         (wr_resp_tr_descbus_6),
					.tr_descbus_7         (wr_resp_tr_descbus_7),
					.tr_descbus_8         (wr_resp_tr_descbus_8),
					.tr_descbus_9         (wr_resp_tr_descbus_9),
					.tr_descbus_A         (wr_resp_tr_descbus_A),
					.tr_descbus_B         (wr_resp_tr_descbus_B),
					.tr_descbus_C         (wr_resp_tr_descbus_C),
					.tr_descbus_D         (wr_resp_tr_descbus_D),
					.tr_descbus_E         (wr_resp_tr_descbus_E),
					.tr_descbus_F         (wr_resp_tr_descbus_F),
					.fifo_dout            (wr_resp_fifo_dout),            
					.fifo_dout_valid      (wr_resp_fifo_dout_valid),      
					.fifo_fill_level      (wr_resp_fifo_fill_level),
					.fifo_free_level      (wr_resp_fifo_free_level),
					.uc2rb_we             (),
					.uc2rb_bwe            (),
					.uc2rb_addr           (),
					.uc2rb_data           (),
					.uc2rb_wstrb          (),
					.uc2hm_trig           (),
					// Inputs
					.clk                  (clk),
					.resetn               (resetn),
					.infbus               (wr_resp_infbus),  //b channel
					.infbus_last          (1'b1),
					.infbus_valid         (m_ace_usr_bvalid),
					.aw_infbus            ({WR_RESP_AW_INFBUS_WIDTH_DUMMY{1'b0}}),
					.aw_infbus_len        (8'b0),
					.aw_infbus_id         ({ID_WIDTH{1'b0}}),
					.aw_infbus_valid      (1'b0),
					.int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					.desc_avail           (wr_resp_desc_avail),
					.fifo_rden            (wr_resp_fifo_rden),
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


   localparam SN_REQ_TR_DESCBUS_WIDTH                                      = SN_REQ_INFBUS_WIDTH; 

   localparam SN_REQ_AW_INFBUS_WIDTH_DUMMY                                 = 1; 


   wire [SN_REQ_INFBUS_WIDTH-1:0]                                          sn_req_infbus;

   wire [SN_DESC_IDX_WIDTH-1:0] 					   sn_req_fifo_dout;
   wire                                                                    sn_req_fifo_dout_valid;  //it is one clock cycle pulse
   wire [SN_DESC_IDX_WIDTH:0] 						   sn_req_fifo_fill_level;
   wire [SN_DESC_IDX_WIDTH:0] 						   sn_req_fifo_free_level;

   wire [SN_MAX_DESC-1:0] 						   sn_req_desc_avail;
   wire                                                                    sn_req_fifo_rden;   //should be one clock cycle pulse

   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_0;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_1;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_2;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_3;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_4;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_5;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_6;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_7;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_8;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_9;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_A;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_B;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_C;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_D;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_E;
   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_F;

   wire [SN_REQ_TR_DESCBUS_WIDTH-1 :0] 					   sn_req_tr_descbus_n[SN_MAX_DESC-1:0];
   
   //wire sn_req_fifo_pop_desc_conn_pulse;
   reg 									   sn_req_fifo_pop_desc_conn_pulse;

   reg 									   sn_req_fifo_pop_desc_conn_ff;

   assign int_sn_req_fifo_pop_desc_valid = 'b0;
   assign int_sn_req_fifo_pop_desc_desc_index = 'b0;

   `FF_RSTLOW(clk,resetn,sn_req_fifo_pop_desc_conn,sn_req_fifo_pop_desc_conn_ff)

   //assign sn_req_fifo_pop_desc_conn_pulse = ( (sn_req_fifo_pop_desc_conn) & (~sn_req_fifo_pop_desc_conn_ff) );

   assign sn_req_fifo_out = sn_req_fifo_dout; 
   assign sn_req_fifo_out_valid = sn_req_fifo_dout_valid;

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 sn_req_fifo_pop_desc_conn_pulse <= 1'b0;
      end else if (sn_req_fifo_pop_desc_conn==1'b1 && sn_req_fifo_pop_desc_conn_ff==1'b0) begin //Positive edge detection
	 sn_req_fifo_pop_desc_conn_pulse <= 1'b1;
      end else begin
	 sn_req_fifo_pop_desc_conn_pulse <= 1'b0;
      end
   end


   assign sn_req_infbus                                                    = {   m_ace_usr_acaddr
										 , m_ace_usr_acsnoop
										 , m_ace_usr_acprot
										 };




   assign sn_req_tr_descbus_n['h0] = sn_req_tr_descbus_0;
   assign sn_req_tr_descbus_n['h1] = sn_req_tr_descbus_1;
   assign sn_req_tr_descbus_n['h2] = sn_req_tr_descbus_2;
   assign sn_req_tr_descbus_n['h3] = sn_req_tr_descbus_3;
   assign sn_req_tr_descbus_n['h4] = sn_req_tr_descbus_4;
   assign sn_req_tr_descbus_n['h5] = sn_req_tr_descbus_5;
   assign sn_req_tr_descbus_n['h6] = sn_req_tr_descbus_6;
   assign sn_req_tr_descbus_n['h7] = sn_req_tr_descbus_7;
   assign sn_req_tr_descbus_n['h8] = sn_req_tr_descbus_8;
   assign sn_req_tr_descbus_n['h9] = sn_req_tr_descbus_9;
   assign sn_req_tr_descbus_n['hA] = sn_req_tr_descbus_A;
   assign sn_req_tr_descbus_n['hB] = sn_req_tr_descbus_B;
   assign sn_req_tr_descbus_n['hC] = sn_req_tr_descbus_C;
   assign sn_req_tr_descbus_n['hD] = sn_req_tr_descbus_D;
   assign sn_req_tr_descbus_n['hE] = sn_req_tr_descbus_E;
   assign sn_req_tr_descbus_n['hF] = sn_req_tr_descbus_F;

   
   generate

      for (gi=0; gi<=SN_MAX_DESC-1; gi=gi+1) begin: gen_int_sn_req_desc

	 assign {int_sn_req_desc_n_acaddr_1_addr[gi][31:0],int_sn_req_desc_n_acaddr_0_addr[gi][31:0]}    = { {(64-ADDR_WIDTH){1'b0}} , sn_req_tr_descbus_n[gi][(SN_REQ_TR_DESCBUS_WIDTH-1) -: (ADDR_WIDTH)] };
	 assign {int_sn_req_desc_n_attr_acsnoop[gi][3:0],int_sn_req_desc_n_attr_acprot[gi][2:0]} =
												  sn_req_tr_descbus_n[gi][(0) +: (ACSNOOP_WIDTH+ACPROT_WIDTH)];

      end
   endgenerate

   assign sn_req_desc_avail = int_sn_req_free_desc_desc[SN_MAX_DESC-1:0];

   assign sn_req_fifo_rden = sn_req_fifo_pop_desc_conn_pulse;

   assign int_sn_req_fifo_fill_level_fill = sn_req_fifo_fill_level;

   ace_ctrl_ready #(
                    // Parameters
                    .ACE_PROTOCOL           (ACE_PROTOCOL),
                    .ACE_CHANNEL            ("MST_SN_REQ"),
                    .ADDR_WIDTH             (ADDR_WIDTH),
                    .DATA_WIDTH             (SN_DATA_WIDTH),
                    .ID_WIDTH               (ID_WIDTH),
                    .AWUSER_WIDTH           (AWUSER_WIDTH),
                    .WUSER_WIDTH            (WUSER_WIDTH),
                    .BUSER_WIDTH            (BUSER_WIDTH),
                    .ARUSER_WIDTH           (ARUSER_WIDTH),
                    .RUSER_WIDTH            (RUSER_WIDTH),
                    .INFBUS_WIDTH           (SN_REQ_INFBUS_WIDTH),
                    .TR_DESCBUS_WIDTH       (SN_REQ_TR_DESCBUS_WIDTH),
                    .AW_INFBUS_WIDTH        (SN_REQ_AW_INFBUS_WIDTH_DUMMY),
                    .AW_TR_DESCBUS_WIDTH    (1),
                    .CACHE_LINE_SIZE        (CACHE_LINE_SIZE),
                    .MAX_DESC               (SN_MAX_DESC),
                    .RAM_SIZE               (SN_RAM_SIZE)
		    ) ac_ace_ctrl_ready (
					 // Outputs
					 .infbus_ready         (m_ace_usr_acready),
					 .inf_xack             (),
					 .aw_infbus_ready      (),
					 .tr_descbus_0         (sn_req_tr_descbus_0),
					 .tr_descbus_1         (sn_req_tr_descbus_1),
					 .tr_descbus_2         (sn_req_tr_descbus_2),
					 .tr_descbus_3         (sn_req_tr_descbus_3),
					 .tr_descbus_4         (sn_req_tr_descbus_4),
					 .tr_descbus_5         (sn_req_tr_descbus_5),
					 .tr_descbus_6         (sn_req_tr_descbus_6),
					 .tr_descbus_7         (sn_req_tr_descbus_7),
					 .tr_descbus_8         (sn_req_tr_descbus_8),
					 .tr_descbus_9         (sn_req_tr_descbus_9),
					 .tr_descbus_A         (sn_req_tr_descbus_A),
					 .tr_descbus_B         (sn_req_tr_descbus_B),
					 .tr_descbus_C         (sn_req_tr_descbus_C),
					 .tr_descbus_D         (sn_req_tr_descbus_D),
					 .tr_descbus_E         (sn_req_tr_descbus_E),
					 .tr_descbus_F         (sn_req_tr_descbus_F),
					 .fifo_dout            (sn_req_fifo_dout),            
					 .fifo_dout_valid      (sn_req_fifo_dout_valid),      
					 .fifo_fill_level      (sn_req_fifo_fill_level),
					 .fifo_free_level      (sn_req_fifo_free_level),
					 .uc2rb_we             (),
					 .uc2rb_bwe            (),
					 .uc2rb_addr           (),
					 .uc2rb_data           (),
					 .uc2rb_wstrb          (),
					 .uc2hm_trig           (),
					 // Inputs
					 .clk                  (clk),
					 .resetn               (resetn),
					 .infbus               (sn_req_infbus),  //ac channel
					 .infbus_last          (1'b1),
					 .infbus_valid         (m_ace_usr_acvalid),
					 .aw_infbus            ({SN_REQ_AW_INFBUS_WIDTH_DUMMY{1'b0}}),
					 .aw_infbus_len        (8'b0),
					 .aw_infbus_id         ({ID_WIDTH{1'b0}}),
					 .aw_infbus_valid      (1'b0),
					 .int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					 .desc_avail           (sn_req_desc_avail),
					 .fifo_rden            (sn_req_fifo_rden),
					 .hm2uc_done           ({SN_MAX_DESC{1'b0}})
					 );
   

   
   ///////////////////////
     //CR-Channel
   //Description :
   //////////////////////

   localparam SN_RESP_INFBUS_WIDTH                                         = {   CRRESP_WIDTH
										 };

   localparam SN_RESP_FR_DESCBUS_WIDTH                                     = SN_RESP_INFBUS_WIDTH;

   wire [SN_RESP_INFBUS_WIDTH-1:0]                                         sn_resp_infbus;

   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_n[SN_MAX_DESC-1:0];

   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_0;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_1;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_2;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_3;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_4;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_5;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_6;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_7;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_8;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_9;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_A;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_B;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_C;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_D;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_E;
   wire [SN_RESP_FR_DESCBUS_WIDTH-1 :0] 				   sn_resp_fr_descbus_F;

   wire [7:0] 								   sn_resp_fr_descbus_len_0;
   wire [7:0] 								   sn_resp_fr_descbus_len_1;
   wire [7:0] 								   sn_resp_fr_descbus_len_2;
   wire [7:0] 								   sn_resp_fr_descbus_len_3;
   wire [7:0] 								   sn_resp_fr_descbus_len_4;
   wire [7:0] 								   sn_resp_fr_descbus_len_5;
   wire [7:0] 								   sn_resp_fr_descbus_len_6;
   wire [7:0] 								   sn_resp_fr_descbus_len_7;
   wire [7:0] 								   sn_resp_fr_descbus_len_8;
   wire [7:0] 								   sn_resp_fr_descbus_len_9;
   wire [7:0] 								   sn_resp_fr_descbus_len_A;
   wire [7:0] 								   sn_resp_fr_descbus_len_B;
   wire [7:0] 								   sn_resp_fr_descbus_len_C;
   wire [7:0] 								   sn_resp_fr_descbus_len_D;
   wire [7:0] 								   sn_resp_fr_descbus_len_E;
   wire [7:0] 								   sn_resp_fr_descbus_len_F;

   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_0;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_1;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_2;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_3;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_4;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_5;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_6;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_7;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_8;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_9;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_A;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_B;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_C;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_D;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_E;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_resp_fr_descbus_dtoffset_F;

   wire [SN_DESC_IDX_WIDTH:0] 						   sn_resp_fifo_fill_level;
   wire [SN_DESC_IDX_WIDTH:0] 						   sn_resp_fifo_free_level;

   wire [SN_MAX_DESC-1:0] 						   sn_resp_intr_comp_status_comp;

   reg                                                                     sn_resp_fifo_wren;
   wire [SN_DESC_IDX_WIDTH-1:0] 					   sn_resp_fifo_din;

   reg                                                                     sn_resp_push;
   reg                                                                     sn_resp_push_ff;

   assign int_sn_resp_fifo_free_level_free = sn_resp_fifo_free_level;

   `FF_RSTLOW(clk,resetn,int_sn_resp_fifo_push_desc_valid,sn_resp_push)
   `FF_RSTLOW(clk,resetn,sn_resp_push,sn_resp_push_ff)

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 sn_resp_fifo_wren <= 1'b0;  
      end else if (sn_resp_push==1'b1 && sn_resp_push_ff==1'b0) begin //Positive edge detection
	 sn_resp_fifo_wren <= 1'b1;
      end else begin
	 sn_resp_fifo_wren <= 1'b0;
      end
   end

   synchronizer#(
		 .SYNC_FF                                                       (2)  
		 ,.D_WIDTH                                                       (SN_DESC_IDX_WIDTH)
		 ) sync_sn_resp_fifo_din (
					  .ck                                                           (clk) 
					  ,.rn                                                           (resetn) 
					  ,.data_in                                                      (int_sn_resp_fifo_push_desc_desc_index) 
					  ,.q_out                                                        (sn_resp_fifo_din)
					  );   




   assign int_sn_resp_intr_comp_status_comp = sn_resp_intr_comp_status_comp;

   assign {   m_ace_usr_crresp
	      }                        = sn_resp_infbus;

   assign sn_resp_fr_descbus_0 = sn_resp_fr_descbus_n['h0];
   assign sn_resp_fr_descbus_1 = sn_resp_fr_descbus_n['h1];
   assign sn_resp_fr_descbus_2 = sn_resp_fr_descbus_n['h2];
   assign sn_resp_fr_descbus_3 = sn_resp_fr_descbus_n['h3];
   assign sn_resp_fr_descbus_4 = sn_resp_fr_descbus_n['h4];
   assign sn_resp_fr_descbus_5 = sn_resp_fr_descbus_n['h5];
   assign sn_resp_fr_descbus_6 = sn_resp_fr_descbus_n['h6];
   assign sn_resp_fr_descbus_7 = sn_resp_fr_descbus_n['h7];
   assign sn_resp_fr_descbus_8 = sn_resp_fr_descbus_n['h8];
   assign sn_resp_fr_descbus_9 = sn_resp_fr_descbus_n['h9];
   assign sn_resp_fr_descbus_A = sn_resp_fr_descbus_n['hA];
   assign sn_resp_fr_descbus_B = sn_resp_fr_descbus_n['hB];
   assign sn_resp_fr_descbus_C = sn_resp_fr_descbus_n['hC];
   assign sn_resp_fr_descbus_D = sn_resp_fr_descbus_n['hD];
   assign sn_resp_fr_descbus_E = sn_resp_fr_descbus_n['hE];
   assign sn_resp_fr_descbus_F = sn_resp_fr_descbus_n['hF];



   generate
      for (gi=0; gi<=SN_MAX_DESC-1; gi=gi+1) begin: gen_sn_resp_fr_descbus_n

	 assign sn_resp_fr_descbus_n[gi] = {   int_sn_resp_desc_n_resp_resp[gi][(0) +: (CRRESP_WIDTH)]
					       };

      end
   endgenerate
   
   assign sn_resp_fr_descbus_len_0 = 'b0;
   assign sn_resp_fr_descbus_len_1 = 'b0;
   assign sn_resp_fr_descbus_len_2 = 'b0;
   assign sn_resp_fr_descbus_len_3 = 'b0;
   assign sn_resp_fr_descbus_len_4 = 'b0;
   assign sn_resp_fr_descbus_len_5 = 'b0;
   assign sn_resp_fr_descbus_len_6 = 'b0;
   assign sn_resp_fr_descbus_len_7 = 'b0;
   assign sn_resp_fr_descbus_len_8 = 'b0;
   assign sn_resp_fr_descbus_len_9 = 'b0;
   assign sn_resp_fr_descbus_len_A = 'b0;
   assign sn_resp_fr_descbus_len_B = 'b0;
   assign sn_resp_fr_descbus_len_C = 'b0;
   assign sn_resp_fr_descbus_len_D = 'b0;
   assign sn_resp_fr_descbus_len_E = 'b0;
   assign sn_resp_fr_descbus_len_F = 'b0;

   assign sn_resp_fr_descbus_dtoffset_0 = 'b0;
   assign sn_resp_fr_descbus_dtoffset_1 = 'b0;
   assign sn_resp_fr_descbus_dtoffset_2 = 'b0;
   assign sn_resp_fr_descbus_dtoffset_3 = 'b0;
   assign sn_resp_fr_descbus_dtoffset_4 = 'b0;
   assign sn_resp_fr_descbus_dtoffset_5 = 'b0;
   assign sn_resp_fr_descbus_dtoffset_6 = 'b0;
   assign sn_resp_fr_descbus_dtoffset_7 = 'b0;
   assign sn_resp_fr_descbus_dtoffset_8 = 'b0;
   assign sn_resp_fr_descbus_dtoffset_9 = 'b0;
   assign sn_resp_fr_descbus_dtoffset_A = 'b0;
   assign sn_resp_fr_descbus_dtoffset_B = 'b0;
   assign sn_resp_fr_descbus_dtoffset_C = 'b0;
   assign sn_resp_fr_descbus_dtoffset_D = 'b0;
   assign sn_resp_fr_descbus_dtoffset_E = 'b0;
   assign sn_resp_fr_descbus_dtoffset_F = 'b0;

   ace_ctrl_valid #(
                    // Parameters
                    .ACE_PROTOCOL          (ACE_PROTOCOL),
                    .ACE_CHANNEL           ("MST_SN_RESP"),
                    .ADDR_WIDTH            (ADDR_WIDTH),
                    .DATA_WIDTH            (SN_DATA_WIDTH),
                    .ID_WIDTH              (ID_WIDTH),
                    .AWUSER_WIDTH          (AWUSER_WIDTH),
                    .WUSER_WIDTH           (WUSER_WIDTH),
                    .BUSER_WIDTH           (BUSER_WIDTH),
                    .ARUSER_WIDTH          (ARUSER_WIDTH),
                    .RUSER_WIDTH           (RUSER_WIDTH),
                    .INFBUS_WIDTH          (SN_RESP_INFBUS_WIDTH),
                    .FR_DESCBUS_WIDTH      (SN_RESP_FR_DESCBUS_WIDTH),
                    .CACHE_LINE_SIZE       (CACHE_LINE_SIZE),
                    .MAX_DESC              (SN_MAX_DESC),
                    .RAM_SIZE              (SN_RAM_SIZE)
		    ) cr_ace_ctrl_valid (
					 // Outputs
					 .infbus               (sn_resp_infbus),  //cr channel
					 .infbus_last          (),
					 .infbus_valid         (m_ace_usr_crvalid),
					 .fifo_fill_level      (sn_resp_fifo_fill_level),
					 .fifo_free_level      (sn_resp_fifo_free_level),
					 .intr_comp_status_comp(sn_resp_intr_comp_status_comp),
					 .uc2rb_addr           (),
					 .uc2hm_trig           (),
					 // Inputs
					 .clk                  (clk),
					 .resetn               (resetn),
					 .infbus_ready         (m_ace_usr_crready),
					 .inf_xack             (1'b0),
					 .fr_descbus_0         (sn_resp_fr_descbus_0),
					 .fr_descbus_1         (sn_resp_fr_descbus_1),
					 .fr_descbus_2         (sn_resp_fr_descbus_2),
					 .fr_descbus_3         (sn_resp_fr_descbus_3),
					 .fr_descbus_4         (sn_resp_fr_descbus_4),
					 .fr_descbus_5         (sn_resp_fr_descbus_5),
					 .fr_descbus_6         (sn_resp_fr_descbus_6),
					 .fr_descbus_7         (sn_resp_fr_descbus_7),
					 .fr_descbus_8         (sn_resp_fr_descbus_8),
					 .fr_descbus_9         (sn_resp_fr_descbus_9),
					 .fr_descbus_A         (sn_resp_fr_descbus_A),
					 .fr_descbus_B         (sn_resp_fr_descbus_B),
					 .fr_descbus_C         (sn_resp_fr_descbus_C),
					 .fr_descbus_D         (sn_resp_fr_descbus_D),
					 .fr_descbus_E         (sn_resp_fr_descbus_E),
					 .fr_descbus_F         (sn_resp_fr_descbus_F),
					 .fr_descbus_len_0     (sn_resp_fr_descbus_len_0),
					 .fr_descbus_len_1     (sn_resp_fr_descbus_len_1),
					 .fr_descbus_len_2     (sn_resp_fr_descbus_len_2),
					 .fr_descbus_len_3     (sn_resp_fr_descbus_len_3),
					 .fr_descbus_len_4     (sn_resp_fr_descbus_len_4),
					 .fr_descbus_len_5     (sn_resp_fr_descbus_len_5),
					 .fr_descbus_len_6     (sn_resp_fr_descbus_len_6),
					 .fr_descbus_len_7     (sn_resp_fr_descbus_len_7),
					 .fr_descbus_len_8     (sn_resp_fr_descbus_len_8),
					 .fr_descbus_len_9     (sn_resp_fr_descbus_len_9),
					 .fr_descbus_len_A     (sn_resp_fr_descbus_len_A),
					 .fr_descbus_len_B     (sn_resp_fr_descbus_len_B),
					 .fr_descbus_len_C     (sn_resp_fr_descbus_len_C),
					 .fr_descbus_len_D     (sn_resp_fr_descbus_len_D),
					 .fr_descbus_len_E     (sn_resp_fr_descbus_len_E),
					 .fr_descbus_len_F     (sn_resp_fr_descbus_len_F),
					 .fr_descbus_dtoffset_0(sn_resp_fr_descbus_dtoffset_0),
					 .fr_descbus_dtoffset_1(sn_resp_fr_descbus_dtoffset_1),
					 .fr_descbus_dtoffset_2(sn_resp_fr_descbus_dtoffset_2),
					 .fr_descbus_dtoffset_3(sn_resp_fr_descbus_dtoffset_3),
					 .fr_descbus_dtoffset_4(sn_resp_fr_descbus_dtoffset_4),
					 .fr_descbus_dtoffset_5(sn_resp_fr_descbus_dtoffset_5),
					 .fr_descbus_dtoffset_6(sn_resp_fr_descbus_dtoffset_6),
					 .fr_descbus_dtoffset_7(sn_resp_fr_descbus_dtoffset_7),
					 .fr_descbus_dtoffset_8(sn_resp_fr_descbus_dtoffset_8),
					 .fr_descbus_dtoffset_9(sn_resp_fr_descbus_dtoffset_9),
					 .fr_descbus_dtoffset_A(sn_resp_fr_descbus_dtoffset_A),
					 .fr_descbus_dtoffset_B(sn_resp_fr_descbus_dtoffset_B),
					 .fr_descbus_dtoffset_C(sn_resp_fr_descbus_dtoffset_C),
					 .fr_descbus_dtoffset_D(sn_resp_fr_descbus_dtoffset_D),
					 .fr_descbus_dtoffset_E(sn_resp_fr_descbus_dtoffset_E),
					 .fr_descbus_dtoffset_F(sn_resp_fr_descbus_dtoffset_F),
					 .int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					 .txn_type_wr_strb     ({SN_MAX_DESC{1'b0}}),
					 .fifo_wren            (sn_resp_fifo_wren),
					 .fifo_din             (sn_resp_fifo_din),
					 .intr_comp_clear_clr_comp(int_sn_resp_intr_comp_clear_clr_comp),
					 .rb2uc_data           ({SN_DATA_WIDTH{1'b0}}),
					 .rb2uc_wstrb          ({WSTRB_WIDTH{1'b0}}),
					 .hm2uc_done           ({SN_MAX_DESC{1'b0}})
					 );
   



   
   ///////////////////////
     //CD-Channel
   //Description :
   //////////////////////
   
   localparam SN_DATA_DUMMY_WIDTH                                          = 1;

   localparam SN_DATA_INFBUS_WIDTH                                         = {   SN_DATA_WIDTH 
										 + SN_DATA_DUMMY_WIDTH
										 };

   localparam SN_DATA_FR_DESCBUS_WIDTH                                     = SN_DATA_INFBUS_WIDTH;

   wire [SN_DATA_INFBUS_WIDTH-1:0]                                         sn_data_infbus;

   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_n[SN_MAX_DESC-1:0];

   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_0;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_1;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_2;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_3;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_4;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_5;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_6;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_7;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_8;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_9;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_A;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_B;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_C;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_D;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_E;
   wire [SN_DATA_FR_DESCBUS_WIDTH-1 :0] 				   sn_data_fr_descbus_F;

   wire [7:0] 								   sn_data_fr_descbus_len_0;
   wire [7:0] 								   sn_data_fr_descbus_len_1;
   wire [7:0] 								   sn_data_fr_descbus_len_2;
   wire [7:0] 								   sn_data_fr_descbus_len_3;
   wire [7:0] 								   sn_data_fr_descbus_len_4;
   wire [7:0] 								   sn_data_fr_descbus_len_5;
   wire [7:0] 								   sn_data_fr_descbus_len_6;
   wire [7:0] 								   sn_data_fr_descbus_len_7;
   wire [7:0] 								   sn_data_fr_descbus_len_8;
   wire [7:0] 								   sn_data_fr_descbus_len_9;
   wire [7:0] 								   sn_data_fr_descbus_len_A;
   wire [7:0] 								   sn_data_fr_descbus_len_B;
   wire [7:0] 								   sn_data_fr_descbus_len_C;
   wire [7:0] 								   sn_data_fr_descbus_len_D;
   wire [7:0] 								   sn_data_fr_descbus_len_E;
   wire [7:0] 								   sn_data_fr_descbus_len_F;

   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_0;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_1;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_2;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_3;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_4;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_5;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_6;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_7;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_8;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_9;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_A;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_B;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_C;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_D;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_E;
   wire [SN_RAM_OFFSET_WIDTH-1:0] 					   sn_data_fr_descbus_dtoffset_F;

   wire [SN_DESC_IDX_WIDTH:0] 						   sn_data_fifo_fill_level;
   wire [SN_DESC_IDX_WIDTH:0] 						   sn_data_fifo_free_level;

   wire [SN_MAX_DESC-1:0] 						   sn_data_intr_comp_status_comp;

   reg                                                                     sn_data_fifo_wren;
   wire [SN_DESC_IDX_WIDTH-1:0] 					   sn_data_fifo_din;

   reg                                                                     sn_data_push;
   reg                                                                     sn_data_push_ff;

   assign int_sn_data_fifo_free_level_free = sn_data_fifo_free_level;

   `FF_RSTLOW(clk,resetn,int_sn_data_fifo_push_desc_valid,sn_data_push)
   `FF_RSTLOW(clk,resetn,sn_data_push,sn_data_push_ff)

   always @(posedge clk) begin
      if (resetn == 1'b0) begin
	 sn_data_fifo_wren <= 1'b0;  
      end else if (sn_data_push==1'b1 && sn_data_push_ff==1'b0) begin //Positive edge detection
	 sn_data_fifo_wren <= 1'b1;
      end else begin
	 sn_data_fifo_wren <= 1'b0;
      end
   end

   synchronizer#(
		 .SYNC_FF                                                       (2)  
		 ,.D_WIDTH                                                       (SN_DESC_IDX_WIDTH)
		 ) sync_sn_data_fifo_din (
					  .ck                                                           (clk) 
					  ,.rn                                                           (resetn) 
					  ,.data_in                                                      (int_sn_data_fifo_push_desc_desc_index) 
					  ,.q_out                                                        (sn_data_fifo_din)
					  );   



   assign int_sn_data_intr_comp_status_comp = sn_data_intr_comp_status_comp;

   assign {   m_ace_usr_cddata 
	      }                        = sn_data_infbus[(SN_DATA_DUMMY_WIDTH) +: (SN_DATA_WIDTH)];

   assign sn_data_fr_descbus_0 = sn_data_fr_descbus_n['h0];
   assign sn_data_fr_descbus_1 = sn_data_fr_descbus_n['h1];
   assign sn_data_fr_descbus_2 = sn_data_fr_descbus_n['h2];
   assign sn_data_fr_descbus_3 = sn_data_fr_descbus_n['h3];
   assign sn_data_fr_descbus_4 = sn_data_fr_descbus_n['h4];
   assign sn_data_fr_descbus_5 = sn_data_fr_descbus_n['h5];
   assign sn_data_fr_descbus_6 = sn_data_fr_descbus_n['h6];
   assign sn_data_fr_descbus_7 = sn_data_fr_descbus_n['h7];
   assign sn_data_fr_descbus_8 = sn_data_fr_descbus_n['h8];
   assign sn_data_fr_descbus_9 = sn_data_fr_descbus_n['h9];
   assign sn_data_fr_descbus_A = sn_data_fr_descbus_n['hA];
   assign sn_data_fr_descbus_B = sn_data_fr_descbus_n['hB];
   assign sn_data_fr_descbus_C = sn_data_fr_descbus_n['hC];
   assign sn_data_fr_descbus_D = sn_data_fr_descbus_n['hD];
   assign sn_data_fr_descbus_E = sn_data_fr_descbus_n['hE];
   assign sn_data_fr_descbus_F = sn_data_fr_descbus_n['hF];


   generate
      for (gi=0; gi<=SN_MAX_DESC-1; gi=gi+1) begin: gen_sn_data_fr_descbus_n

	 assign sn_data_fr_descbus_n[gi] = {   {SN_DATA_WIDTH{1'b0}}
					       , {SN_DATA_DUMMY_WIDTH{1'b0}}
					       };

      end
   endgenerate
   
   assign sn_data_fr_descbus_len_0 = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_1 = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_2 = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_3 = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_4 = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_5 = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_6 = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_7 = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_8 = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_9 = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_A = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_B = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_C = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_D = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_E = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);
   assign sn_data_fr_descbus_len_F = ( ((CACHE_LINE_SIZE*8)/SN_DATA_WIDTH) -1);

   assign sn_data_fr_descbus_dtoffset_0 = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('h0) );
   assign sn_data_fr_descbus_dtoffset_1 = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('h1) );
   assign sn_data_fr_descbus_dtoffset_2 = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('h2) );
   assign sn_data_fr_descbus_dtoffset_3 = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('h3) );
   assign sn_data_fr_descbus_dtoffset_4 = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('h4) );
   assign sn_data_fr_descbus_dtoffset_5 = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('h5) );
   assign sn_data_fr_descbus_dtoffset_6 = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('h6) );
   assign sn_data_fr_descbus_dtoffset_7 = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('h7) );
   assign sn_data_fr_descbus_dtoffset_8 = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('h8) );
   assign sn_data_fr_descbus_dtoffset_9 = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('h9) );
   assign sn_data_fr_descbus_dtoffset_A = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('hA) );
   assign sn_data_fr_descbus_dtoffset_B = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('hB) );
   assign sn_data_fr_descbus_dtoffset_C = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('hC) );
   assign sn_data_fr_descbus_dtoffset_D = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('hD) );
   assign sn_data_fr_descbus_dtoffset_E = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('hE) );
   assign sn_data_fr_descbus_dtoffset_F = ( (CACHE_LINE_SIZE*8/SN_DATA_WIDTH) * ('hF) );

   ace_ctrl_valid #(
                    // Parameters
                    .ACE_PROTOCOL          (ACE_PROTOCOL),
                    .ACE_CHANNEL           ("MST_SN_DATA"),
                    .ADDR_WIDTH            (ADDR_WIDTH),
                    .DATA_WIDTH            (SN_DATA_WIDTH),
                    .ID_WIDTH              (ID_WIDTH),
                    .AWUSER_WIDTH          (AWUSER_WIDTH),
                    .WUSER_WIDTH           (WUSER_WIDTH),
                    .BUSER_WIDTH           (BUSER_WIDTH),
                    .ARUSER_WIDTH          (ARUSER_WIDTH),
                    .RUSER_WIDTH           (RUSER_WIDTH),
                    .INFBUS_WIDTH          (SN_DATA_INFBUS_WIDTH),
                    .FR_DESCBUS_WIDTH      (SN_DATA_FR_DESCBUS_WIDTH),
                    .CACHE_LINE_SIZE       (CACHE_LINE_SIZE),
                    .MAX_DESC              (SN_MAX_DESC),
                    .RAM_SIZE              (SN_RAM_SIZE)
		    ) cd_ace_ctrl_valid (
					 // Outputs
					 .infbus               (sn_data_infbus),  //cd channel
					 .infbus_last          (m_ace_usr_cdlast),
					 .infbus_valid         (m_ace_usr_cdvalid),
					 .fifo_fill_level      (sn_data_fifo_fill_level),
					 .fifo_free_level      (sn_data_fifo_free_level),
					 .intr_comp_status_comp(sn_data_intr_comp_status_comp),
					 .uc2rb_addr           (uc2rb_sn_addr),
					 .uc2hm_trig           (),
					 // Inputs
					 .clk                  (clk),
					 .resetn               (resetn),
					 .infbus_ready         (m_ace_usr_cdready),
					 .inf_xack             (1'b0),
					 .fr_descbus_0         (sn_data_fr_descbus_0),
					 .fr_descbus_1         (sn_data_fr_descbus_1),
					 .fr_descbus_2         (sn_data_fr_descbus_2),
					 .fr_descbus_3         (sn_data_fr_descbus_3),
					 .fr_descbus_4         (sn_data_fr_descbus_4),
					 .fr_descbus_5         (sn_data_fr_descbus_5),
					 .fr_descbus_6         (sn_data_fr_descbus_6),
					 .fr_descbus_7         (sn_data_fr_descbus_7),
					 .fr_descbus_8         (sn_data_fr_descbus_8),
					 .fr_descbus_9         (sn_data_fr_descbus_9),
					 .fr_descbus_A         (sn_data_fr_descbus_A),
					 .fr_descbus_B         (sn_data_fr_descbus_B),
					 .fr_descbus_C         (sn_data_fr_descbus_C),
					 .fr_descbus_D         (sn_data_fr_descbus_D),
					 .fr_descbus_E         (sn_data_fr_descbus_E),
					 .fr_descbus_F         (sn_data_fr_descbus_F),
					 .fr_descbus_len_0     (sn_data_fr_descbus_len_0),
					 .fr_descbus_len_1     (sn_data_fr_descbus_len_1),
					 .fr_descbus_len_2     (sn_data_fr_descbus_len_2),
					 .fr_descbus_len_3     (sn_data_fr_descbus_len_3),
					 .fr_descbus_len_4     (sn_data_fr_descbus_len_4),
					 .fr_descbus_len_5     (sn_data_fr_descbus_len_5),
					 .fr_descbus_len_6     (sn_data_fr_descbus_len_6),
					 .fr_descbus_len_7     (sn_data_fr_descbus_len_7),
					 .fr_descbus_len_8     (sn_data_fr_descbus_len_8),
					 .fr_descbus_len_9     (sn_data_fr_descbus_len_9),
					 .fr_descbus_len_A     (sn_data_fr_descbus_len_A),
					 .fr_descbus_len_B     (sn_data_fr_descbus_len_B),
					 .fr_descbus_len_C     (sn_data_fr_descbus_len_C),
					 .fr_descbus_len_D     (sn_data_fr_descbus_len_D),
					 .fr_descbus_len_E     (sn_data_fr_descbus_len_E),
					 .fr_descbus_len_F     (sn_data_fr_descbus_len_F),
					 .fr_descbus_dtoffset_0(sn_data_fr_descbus_dtoffset_0),
					 .fr_descbus_dtoffset_1(sn_data_fr_descbus_dtoffset_1),
					 .fr_descbus_dtoffset_2(sn_data_fr_descbus_dtoffset_2),
					 .fr_descbus_dtoffset_3(sn_data_fr_descbus_dtoffset_3),
					 .fr_descbus_dtoffset_4(sn_data_fr_descbus_dtoffset_4),
					 .fr_descbus_dtoffset_5(sn_data_fr_descbus_dtoffset_5),
					 .fr_descbus_dtoffset_6(sn_data_fr_descbus_dtoffset_6),
					 .fr_descbus_dtoffset_7(sn_data_fr_descbus_dtoffset_7),
					 .fr_descbus_dtoffset_8(sn_data_fr_descbus_dtoffset_8),
					 .fr_descbus_dtoffset_9(sn_data_fr_descbus_dtoffset_9),
					 .fr_descbus_dtoffset_A(sn_data_fr_descbus_dtoffset_A),
					 .fr_descbus_dtoffset_B(sn_data_fr_descbus_dtoffset_B),
					 .fr_descbus_dtoffset_C(sn_data_fr_descbus_dtoffset_C),
					 .fr_descbus_dtoffset_D(sn_data_fr_descbus_dtoffset_D),
					 .fr_descbus_dtoffset_E(sn_data_fr_descbus_dtoffset_E),
					 .fr_descbus_dtoffset_F(sn_data_fr_descbus_dtoffset_F),
					 .int_mode_select_mode_0_1(int_mode_select_mode_0_1),
					 .txn_type_wr_strb     ({SN_MAX_DESC{1'b0}}),
					 .fifo_wren            (sn_data_fifo_wren),
					 .fifo_din             (sn_data_fifo_din),
					 .intr_comp_clear_clr_comp(int_sn_data_intr_comp_clear_clr_comp),
					 .rb2uc_data           (rb2uc_sn_data),
					 .rb2uc_wstrb          ({WSTRB_WIDTH{1'b0}}),
					 .hm2uc_done           ({SN_MAX_DESC{1'b0}})
					 );
   



   

endmodule        

// Local Variables:
// verilog-library-directories:("./")
// End:

