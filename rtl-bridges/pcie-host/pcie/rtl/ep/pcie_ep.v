/*
 * Copyright (c) 2020 Xilinx Inc. 
 * Written by Meera Bagdai. 
 * 
 * Permission is hereby granted free of charge to any person obtaining a copy 
 * of this software and associated documentation files (the 'Software') to deal 
 * in the Software without restriction including without limitation the rights 
 * to use copy modify merge publish distribute sublicense and/or sell 
 * copies of the Software and to permit persons to whom the Software is 
 * furnished to do so subject to the following conditions: 
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS' WITHOUT WARRANTY OF ANY KIND EXPRESS OR
 * IMPLIED INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM DAMAGES OR OTHER
 * LIABILITY WHETHER IN AN ACTION OF CONTRACT TORT OR OTHERWISE ARISING FROM
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Description:	
 *
 *
 */

`include "defines_common.vh"
`include "defines_pcie.vh"

module pcie_ep #(
		         parameter PCIE_EP_LAST_BRIDGE            = 0 //If pcie_ep is last bridge in design

                        ,parameter IS_REAL_PCIE                   = 1 //Is it really a pcie_ep bridge. Do not modify this parameter.

                        ,parameter NUM_MASTER_BRIDGE              = 1 //Allowed values : 1 to 6
                        ,parameter NUM_SLAVE_BRIDGE               = 1 //Allowed values : 0 to 6
                        
                        ,parameter S_AXI_ADDR_WIDTH               = 64 //Allowed values : 32,64   
                        
                        ,parameter M_AXI_ADDR_WIDTH               = 64  //Allowed values : Upto 64  
                        
                        ,parameter USR_RST_NUM                    = 1 //Allowed values : 1 to 31

                        ,parameter M_AXI_USR_0_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter M_AXI_USR_1_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter M_AXI_USR_2_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter M_AXI_USR_3_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter M_AXI_USR_4_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter M_AXI_USR_5_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter S_AXI_USR_0_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter S_AXI_USR_1_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter S_AXI_USR_2_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter S_AXI_USR_3_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter S_AXI_USR_4_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        ,parameter S_AXI_USR_5_PROTOCOL           = "AXI4" //Allowed values : AXI4, AXI4LITE
                        
                        ,parameter M_AXI_USR_0_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter M_AXI_USR_0_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter M_AXI_USR_0_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter M_AXI_USR_0_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_0_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_0_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_0_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_0_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter M_AXI_USR_1_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter M_AXI_USR_1_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter M_AXI_USR_1_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter M_AXI_USR_1_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_1_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_1_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_1_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_1_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter M_AXI_USR_2_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter M_AXI_USR_2_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter M_AXI_USR_2_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter M_AXI_USR_2_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_2_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_2_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_2_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_2_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter M_AXI_USR_3_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter M_AXI_USR_3_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter M_AXI_USR_3_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter M_AXI_USR_3_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_3_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_3_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_3_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_3_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter M_AXI_USR_4_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter M_AXI_USR_4_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter M_AXI_USR_4_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter M_AXI_USR_4_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_4_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_4_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_4_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_4_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter M_AXI_USR_5_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter M_AXI_USR_5_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter M_AXI_USR_5_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter M_AXI_USR_5_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_5_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_5_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_5_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter M_AXI_USR_5_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter S_AXI_USR_0_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter S_AXI_USR_0_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter S_AXI_USR_0_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter S_AXI_USR_0_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_0_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_0_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_0_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_0_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter S_AXI_USR_1_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter S_AXI_USR_1_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter S_AXI_USR_1_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter S_AXI_USR_1_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_1_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_1_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_1_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_1_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter S_AXI_USR_2_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter S_AXI_USR_2_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter S_AXI_USR_2_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter S_AXI_USR_2_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_2_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_2_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_2_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_2_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter S_AXI_USR_3_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter S_AXI_USR_3_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter S_AXI_USR_3_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter S_AXI_USR_3_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_3_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_3_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_3_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_3_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter S_AXI_USR_4_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter S_AXI_USR_4_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter S_AXI_USR_4_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter S_AXI_USR_4_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_4_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_4_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_4_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_4_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        
                        ,parameter S_AXI_USR_5_ADDR_WIDTH         = 64  //Allowed values : Upto 64  
                        ,parameter S_AXI_USR_5_DATA_WIDTH         = 128 //Allowed values : 32,64,128
                        ,parameter S_AXI_USR_5_ID_WIDTH           = 16  //Allowed values : 1 to 16
                        ,parameter S_AXI_USR_5_AWUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_5_WUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_5_BUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_5_ARUSER_WIDTH       = 32  //Allowed values : 1 to 32  
                        ,parameter S_AXI_USR_5_RUSER_WIDTH        = 32  //Allowed values : 1 to 32  
                        )(
                          
                          //Clock and reset
                           input 							clk 
                          ,input 							resetn 
                          
                          //DUT Interrupt
                          ,input [63:0] 					        usr_irq_req
                          ,output [63:0] 			                        usr_irq_ack                          
                          
                          //DUT GPIO
                          ,input [255:0] 						c2h_gpio_in
			  ,output [255:0] 						h2c_gpio_out
                          
                          //Usr Reset
                          ,output [USR_RST_NUM-1:0]                                     usr_resetn

                          //System Interrupt
                          ,output [NUM_MASTER_BRIDGE+NUM_SLAVE_BRIDGE-1:0]              irq_req
                          ,input [NUM_MASTER_BRIDGE+NUM_SLAVE_BRIDGE-1:0]               irq_ack
                          
                          //AXI4-Lite slave interface is used for configuration of Bridge.
                          //"s_axi_pcie_m<NUM>" is used for AXI-master-bridge. 
                          //"s_axi_pcie_s<NUM>" is used for AXI-slave-bridge
                          `d_axi4lite_s(s_axi_pcie_m0, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_m1, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_m2, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_m3, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_m4, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_m5, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_s0, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_s1, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_s2, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_s3, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_s4, S_AXI_ADDR_WIDTH, 32) 
                          `d_axi4lite_s(s_axi_pcie_s5, S_AXI_ADDR_WIDTH, 32) 

                          //AXI4 master interface is used for data-transfer to/from host in mode-1.
                          //"m_axi_pcie_m<NUM>" is used for AXI-master-bridge. 
                          //"m_axi_pcie_s<NUM>" is used for AXI-slave-bridge
                          `d_axi4_m(m_axi_pcie_m0, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_m1, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_m2, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_m3, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_m4, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_m5, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_s0, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_s1, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_s2, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_s3, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_s4, M_AXI_ADDR_WIDTH, 128, 16, 32) 
                          `d_axi4_m(m_axi_pcie_s5, M_AXI_ADDR_WIDTH, 128, 16, 32) 

                          //AXI master/slave interface is to be connected to DUT.
                          //"m_axi_usr_<NUM>" is AXI master interface which used for AXI-master-bridge.
                          //"s_axi_usr_<NUM>" is AXI slave interface which used for AXI-slave-bridge.
                          `d_axi_m(m_axi_usr_0, M_AXI_USR_0_PROTOCOL, M_AXI_USR_0_ADDR_WIDTH, M_AXI_USR_0_DATA_WIDTH, M_AXI_USR_0_ID_WIDTH, M_AXI_USR_0_AWUSER_WIDTH, M_AXI_USR_0_WUSER_WIDTH, M_AXI_USR_0_BUSER_WIDTH, M_AXI_USR_0_ARUSER_WIDTH, M_AXI_USR_0_RUSER_WIDTH) 
                          `d_axi_m(m_axi_usr_1, M_AXI_USR_1_PROTOCOL, M_AXI_USR_1_ADDR_WIDTH, M_AXI_USR_1_DATA_WIDTH, M_AXI_USR_1_ID_WIDTH, M_AXI_USR_1_AWUSER_WIDTH, M_AXI_USR_1_WUSER_WIDTH, M_AXI_USR_1_BUSER_WIDTH, M_AXI_USR_1_ARUSER_WIDTH, M_AXI_USR_1_RUSER_WIDTH) 
                          `d_axi_m(m_axi_usr_2, M_AXI_USR_2_PROTOCOL, M_AXI_USR_2_ADDR_WIDTH, M_AXI_USR_2_DATA_WIDTH, M_AXI_USR_2_ID_WIDTH, M_AXI_USR_2_AWUSER_WIDTH, M_AXI_USR_2_WUSER_WIDTH, M_AXI_USR_2_BUSER_WIDTH, M_AXI_USR_2_ARUSER_WIDTH, M_AXI_USR_2_RUSER_WIDTH) 
                          `d_axi_m(m_axi_usr_3, M_AXI_USR_3_PROTOCOL, M_AXI_USR_3_ADDR_WIDTH, M_AXI_USR_3_DATA_WIDTH, M_AXI_USR_3_ID_WIDTH, M_AXI_USR_3_AWUSER_WIDTH, M_AXI_USR_3_WUSER_WIDTH, M_AXI_USR_3_BUSER_WIDTH, M_AXI_USR_3_ARUSER_WIDTH, M_AXI_USR_3_RUSER_WIDTH) 
                          `d_axi_m(m_axi_usr_4, M_AXI_USR_4_PROTOCOL, M_AXI_USR_4_ADDR_WIDTH, M_AXI_USR_4_DATA_WIDTH, M_AXI_USR_4_ID_WIDTH, M_AXI_USR_4_AWUSER_WIDTH, M_AXI_USR_4_WUSER_WIDTH, M_AXI_USR_4_BUSER_WIDTH, M_AXI_USR_4_ARUSER_WIDTH, M_AXI_USR_4_RUSER_WIDTH) 
                          `d_axi_m(m_axi_usr_5, M_AXI_USR_5_PROTOCOL, M_AXI_USR_5_ADDR_WIDTH, M_AXI_USR_5_DATA_WIDTH, M_AXI_USR_5_ID_WIDTH, M_AXI_USR_5_AWUSER_WIDTH, M_AXI_USR_5_WUSER_WIDTH, M_AXI_USR_5_BUSER_WIDTH, M_AXI_USR_5_ARUSER_WIDTH, M_AXI_USR_5_RUSER_WIDTH) 
                          `d_axi_s(s_axi_usr_0, S_AXI_USR_0_PROTOCOL, S_AXI_USR_0_ADDR_WIDTH, S_AXI_USR_0_DATA_WIDTH, S_AXI_USR_0_ID_WIDTH, S_AXI_USR_0_AWUSER_WIDTH, S_AXI_USR_0_WUSER_WIDTH, S_AXI_USR_0_BUSER_WIDTH, S_AXI_USR_0_ARUSER_WIDTH, S_AXI_USR_0_RUSER_WIDTH) 
                          `d_axi_s(s_axi_usr_1, S_AXI_USR_1_PROTOCOL, S_AXI_USR_1_ADDR_WIDTH, S_AXI_USR_1_DATA_WIDTH, S_AXI_USR_1_ID_WIDTH, S_AXI_USR_1_AWUSER_WIDTH, S_AXI_USR_1_WUSER_WIDTH, S_AXI_USR_1_BUSER_WIDTH, S_AXI_USR_1_ARUSER_WIDTH, S_AXI_USR_1_RUSER_WIDTH) 
                          `d_axi_s(s_axi_usr_2, S_AXI_USR_2_PROTOCOL, S_AXI_USR_2_ADDR_WIDTH, S_AXI_USR_2_DATA_WIDTH, S_AXI_USR_2_ID_WIDTH, S_AXI_USR_2_AWUSER_WIDTH, S_AXI_USR_2_WUSER_WIDTH, S_AXI_USR_2_BUSER_WIDTH, S_AXI_USR_2_ARUSER_WIDTH, S_AXI_USR_2_RUSER_WIDTH) 
                          `d_axi_s(s_axi_usr_3, S_AXI_USR_3_PROTOCOL, S_AXI_USR_3_ADDR_WIDTH, S_AXI_USR_3_DATA_WIDTH, S_AXI_USR_3_ID_WIDTH, S_AXI_USR_3_AWUSER_WIDTH, S_AXI_USR_3_WUSER_WIDTH, S_AXI_USR_3_BUSER_WIDTH, S_AXI_USR_3_ARUSER_WIDTH, S_AXI_USR_3_RUSER_WIDTH) 
                          `d_axi_s(s_axi_usr_4, S_AXI_USR_4_PROTOCOL, S_AXI_USR_4_ADDR_WIDTH, S_AXI_USR_4_DATA_WIDTH, S_AXI_USR_4_ID_WIDTH, S_AXI_USR_4_AWUSER_WIDTH, S_AXI_USR_4_WUSER_WIDTH, S_AXI_USR_4_BUSER_WIDTH, S_AXI_USR_4_ARUSER_WIDTH, S_AXI_USR_4_RUSER_WIDTH) 
                          `d_axi_s(s_axi_usr_5, S_AXI_USR_5_PROTOCOL, S_AXI_USR_5_ADDR_WIDTH, S_AXI_USR_5_DATA_WIDTH, S_AXI_USR_5_ID_WIDTH, S_AXI_USR_5_AWUSER_WIDTH, S_AXI_USR_5_WUSER_WIDTH, S_AXI_USR_5_BUSER_WIDTH, S_AXI_USR_5_ARUSER_WIDTH, S_AXI_USR_5_RUSER_WIDTH) 

);

localparam RAM_SIZE                       = 16384; //Size of RAM in Bytes
localparam MAX_DESC                       = 16; //Max number of descriptors 
localparam EXTEND_WSTRB                   = 1;

localparam S_AXI_DATA_WIDTH               = 32; //Allowed values : 32    

localparam M_AXI_DATA_WIDTH               = 128; //Allowed values : 128
localparam M_AXI_ID_WIDTH                 = 16; //Allowed values : log2(MAX_DESC) to 16
localparam M_AXI_USER_WIDTH               = 32; //Allowed values : 1 to 32  

localparam M_USR_RST_NUM_0                = USR_RST_NUM; //Allowed values : 1 to 31
localparam M_USR_RST_NUM_1                = 1; //Allowed values : 1 to 31
localparam M_USR_RST_NUM_2                = 1; //Allowed values : 1 to 31
localparam M_USR_RST_NUM_3                = 1; //Allowed values : 1 to 31
localparam M_USR_RST_NUM_4                = 1; //Allowed values : 1 to 31
localparam M_USR_RST_NUM_5                = 1; //Allowed values : 1 to 31
localparam S_USR_RST_NUM_0                = 1; //Allowed values : 1 to 31
localparam S_USR_RST_NUM_1                = 1; //Allowed values : 1 to 31
localparam S_USR_RST_NUM_2                = 1; //Allowed values : 1 to 31
localparam S_USR_RST_NUM_3                = 1; //Allowed values : 1 to 31
localparam S_USR_RST_NUM_4                = 1; //Allowed values : 1 to 31
localparam S_USR_RST_NUM_5                = 1; //Allowed values : 1 to 31

localparam PCIE_LAST_BRIDGE_M0 = ( (NUM_SLAVE_BRIDGE=='h0) && (NUM_MASTER_BRIDGE=='h1) );
localparam PCIE_LAST_BRIDGE_M1 = ( (NUM_SLAVE_BRIDGE=='h0) && (NUM_MASTER_BRIDGE=='h2) );
localparam PCIE_LAST_BRIDGE_M2 = ( (NUM_SLAVE_BRIDGE=='h0) && (NUM_MASTER_BRIDGE=='h3) );
localparam PCIE_LAST_BRIDGE_M3 = ( (NUM_SLAVE_BRIDGE=='h0) && (NUM_MASTER_BRIDGE=='h4) );
localparam PCIE_LAST_BRIDGE_M4 = ( (NUM_SLAVE_BRIDGE=='h0) && (NUM_MASTER_BRIDGE=='h5) );
localparam PCIE_LAST_BRIDGE_M5 = ( (NUM_SLAVE_BRIDGE=='h0) && (NUM_MASTER_BRIDGE=='h6) );
localparam PCIE_LAST_BRIDGE_S0 = ( (NUM_SLAVE_BRIDGE=='h1) );
localparam PCIE_LAST_BRIDGE_S1 = ( (NUM_SLAVE_BRIDGE=='h2) );
localparam PCIE_LAST_BRIDGE_S2 = ( (NUM_SLAVE_BRIDGE=='h3) );
localparam PCIE_LAST_BRIDGE_S3 = ( (NUM_SLAVE_BRIDGE=='h4) );
localparam PCIE_LAST_BRIDGE_S4 = ( (NUM_SLAVE_BRIDGE=='h5) );
localparam PCIE_LAST_BRIDGE_S5 = ( (NUM_SLAVE_BRIDGE=='h6) );

localparam LAST_BRIDGE_M0 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_M0 ; 
localparam LAST_BRIDGE_M1 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_M1 ; 
localparam LAST_BRIDGE_M2 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_M2 ; 
localparam LAST_BRIDGE_M3 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_M3 ; 
localparam LAST_BRIDGE_M4 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_M4 ; 
localparam LAST_BRIDGE_M5 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_M5 ; 
localparam LAST_BRIDGE_S0 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_S0 ; 
localparam LAST_BRIDGE_S1 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_S1 ; 
localparam LAST_BRIDGE_S2 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_S1 ; 
localparam LAST_BRIDGE_S3 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_S3 ; 
localparam LAST_BRIDGE_S4 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_S4 ; 
localparam LAST_BRIDGE_S5 = (PCIE_EP_LAST_BRIDGE==1'b0) ? 1'b0 : PCIE_LAST_BRIDGE_S5 ; 
                          
wire [127:0]                                            h2c_intr_out;
wire [`MAX_NUM_MASTER_BR_SUP+`MAX_NUM_SLAVE_BR_SUP-1:0]                                              irq_out_net;
wire [`MAX_NUM_MASTER_BR_SUP+`MAX_NUM_SLAVE_BR_SUP-1:0]                                              irq_ack_net;
wire [31:0]                                             irq_ack_dummy;
wire                                                    m_irq_out_0;
wire                                                    m_irq_out_1;
wire                                                    m_irq_out_2;
wire                                                    m_irq_out_3;
wire                                                    m_irq_out_4;
wire                                                    m_irq_out_5;
wire                                                    s_irq_out_0;
wire                                                    s_irq_out_1;
wire                                                    s_irq_out_2;
wire                                                    s_irq_out_3;
wire                                                    s_irq_out_4;
wire                                                    s_irq_out_5;
wire                                                    m_irq_ack_0;
wire                                                    m_irq_ack_1;
wire                                                    m_irq_ack_2;
wire                                                    m_irq_ack_3;
wire                                                    m_irq_ack_4;
wire                                                    m_irq_ack_5;
wire                                                    s_irq_ack_0;
wire                                                    s_irq_ack_1;
wire                                                    s_irq_ack_2;
wire                                                    s_irq_ack_3;
wire                                                    s_irq_ack_4;
wire                                                    s_irq_ack_5;

wire [127:0] 						m_h2c_intr_out_0;
wire [63:0] 						m_c2h_intr_in_0;
wire [63:0] 			                        m_h2c_pulse_out_0;                          
wire [255:0] 						m_c2h_gpio_in_0;
wire [255:0] 						m_h2c_gpio_out_0;
                          
wire [127:0] 						m_h2c_intr_out_1;
wire [63:0] 						m_c2h_intr_in_1;
wire [63:0] 			                        m_h2c_pulse_out_1;                          
wire [255:0] 						m_c2h_gpio_in_1;
wire [255:0] 						m_h2c_gpio_out_1;

wire [127:0] 						m_h2c_intr_out_2;
wire [63:0] 						m_c2h_intr_in_2;
wire [63:0] 			                        m_h2c_pulse_out_2;                          
wire [255:0] 						m_c2h_gpio_in_2;
wire [255:0] 						m_h2c_gpio_out_2;

wire [127:0] 						m_h2c_intr_out_3;
wire [63:0] 						m_c2h_intr_in_3;
wire [63:0] 			                        m_h2c_pulse_out_3;                          
wire [255:0] 						m_c2h_gpio_in_3;
wire [255:0] 						m_h2c_gpio_out_3;

wire [127:0] 						m_h2c_intr_out_4;
wire [63:0] 						m_c2h_intr_in_4;
wire [63:0] 			                        m_h2c_pulse_out_4;                          
wire [255:0] 						m_c2h_gpio_in_4;
wire [255:0] 						m_h2c_gpio_out_4;

wire [127:0] 						m_h2c_intr_out_5;
wire [63:0] 						m_c2h_intr_in_5;
wire [63:0] 			                        m_h2c_pulse_out_5;                          
wire [255:0] 						m_c2h_gpio_in_5;
wire [255:0] 						m_h2c_gpio_out_5;

wire [127:0] 						s_h2c_intr_out_0;
wire [63:0] 						s_c2h_intr_in_0;
wire [63:0] 			                        s_h2c_pulse_out_0;                          
wire [255:0] 						s_c2h_gpio_in_0;
wire [255:0] 						s_h2c_gpio_out_0;
                          
wire [127:0] 						s_h2c_intr_out_1;
wire [63:0] 						s_c2h_intr_in_1;
wire [63:0] 			                        s_h2c_pulse_out_1;                          
wire [255:0] 						s_c2h_gpio_in_1;
wire [255:0] 						s_h2c_gpio_out_1;

wire [127:0] 						s_h2c_intr_out_2;
wire [63:0] 						s_c2h_intr_in_2;
wire [63:0] 			                        s_h2c_pulse_out_2;                          
wire [255:0] 						s_c2h_gpio_in_2;
wire [255:0] 						s_h2c_gpio_out_2;

wire [127:0] 						s_h2c_intr_out_3;
wire [63:0] 						s_c2h_intr_in_3;
wire [63:0] 			                        s_h2c_pulse_out_3;                          
wire [255:0] 						s_c2h_gpio_in_3;
wire [255:0] 						s_h2c_gpio_out_3;

wire [127:0] 						s_h2c_intr_out_4;
wire [63:0] 						s_c2h_intr_in_4;
wire [63:0] 			                        s_h2c_pulse_out_4;                          
wire [255:0] 						s_c2h_gpio_in_4;
wire [255:0] 						s_h2c_gpio_out_4;

wire [127:0] 						s_h2c_intr_out_5;
wire [63:0] 						s_c2h_intr_in_5;
wire [63:0] 			                        s_h2c_pulse_out_5;                          
wire [255:0] 						s_c2h_gpio_in_5;
wire [255:0] 						s_h2c_gpio_out_5;


assign h2c_intr_out = m_h2c_intr_out_0;
assign usr_irq_ack = m_h2c_pulse_out_0;                          
assign h2c_gpio_out = m_h2c_gpio_out_0;
                    
assign m_c2h_intr_in_0 = usr_irq_req;
assign m_c2h_gpio_in_0 = c2h_gpio_in;

assign m_c2h_intr_in_1 = 'b0;
assign m_c2h_gpio_in_1 = 'b0;

assign m_c2h_intr_in_2 = 'b0;
assign m_c2h_gpio_in_2 = 'b0;

assign m_c2h_intr_in_3 = 'b0;
assign m_c2h_gpio_in_3 = 'b0;

assign m_c2h_intr_in_4 = 'b0;
assign m_c2h_gpio_in_4 = 'b0;

assign m_c2h_intr_in_5 = 'b0;
assign m_c2h_gpio_in_5 = 'b0;

assign s_c2h_intr_in_0 = 'b0;
assign s_c2h_gpio_in_0 = 'b0;

assign s_c2h_intr_in_1 = 'b0;
assign s_c2h_gpio_in_1 = 'b0;

assign s_c2h_intr_in_2 = 'b0;
assign s_c2h_gpio_in_2 = 'b0;

assign s_c2h_intr_in_3 = 'b0;
assign s_c2h_gpio_in_3 = 'b0;

assign s_c2h_intr_in_4 = 'b0;
assign s_c2h_gpio_in_4 = 'b0;

assign s_c2h_intr_in_5 = 'b0;
assign s_c2h_gpio_in_5 = 'b0;

assign irq_req[NUM_MASTER_BRIDGE+NUM_SLAVE_BRIDGE-1:0] = {
                                                             irq_out_net[`MAX_NUM_MASTER_BR_SUP+NUM_SLAVE_BRIDGE-1:`MAX_NUM_MASTER_BR_SUP]
                                                           , irq_out_net[NUM_MASTER_BRIDGE-1:0]
                                                         };
assign irq_out_net[`MAX_NUM_MASTER_BR_SUP+`MAX_NUM_SLAVE_BR_SUP-1:0] = {   
                                                                         s_irq_out_5
                                                                       , s_irq_out_4
                                                                       , s_irq_out_3
                                                                       , s_irq_out_2
                                                                       , s_irq_out_1
                                                                       , s_irq_out_0
                                                                       , m_irq_out_5
                                                                       , m_irq_out_4
                                                                       , m_irq_out_3
                                                                       , m_irq_out_2
                                                                       , m_irq_out_1
                                                                       , m_irq_out_0 };

assign irq_ack_dummy = {'b0, irq_ack[NUM_MASTER_BRIDGE+NUM_SLAVE_BRIDGE-1:0]};
assign irq_ack_net[`MAX_NUM_MASTER_BR_SUP+`MAX_NUM_SLAVE_BR_SUP-1:`MAX_NUM_MASTER_BR_SUP] = irq_ack_dummy[(NUM_MASTER_BRIDGE+NUM_SLAVE_BRIDGE-1) : NUM_MASTER_BRIDGE];
assign irq_ack_net[NUM_MASTER_BRIDGE-1:0] = irq_ack_dummy[NUM_MASTER_BRIDGE-1:0];

assign {   
           s_irq_ack_5 
         , s_irq_ack_4 
         , s_irq_ack_3 
         , s_irq_ack_2 
         , s_irq_ack_1 
         , s_irq_ack_0 
         , m_irq_ack_5 
         , m_irq_ack_4 
         , m_irq_ack_3 
         , m_irq_ack_2 
         , m_irq_ack_1 
         , m_irq_ack_0 } = irq_ack_net[`MAX_NUM_MASTER_BR_SUP+`MAX_NUM_SLAVE_BR_SUP-1:0];

///////////////////////
//Instantiation of AXI-master-bridge, AXI-slave-bridge.
//////////////////////

generate 

if (NUM_MASTER_BRIDGE>='h1) begin : gen_axi_master_0

axi_master#(
                   .AXI_PROTOCOL                 (M_AXI_USR_0_PROTOCOL)
                  ,.M_AXI_USR_ADDR_WIDTH         (M_AXI_USR_0_ADDR_WIDTH)
                  ,.M_AXI_USR_DATA_WIDTH         (M_AXI_USR_0_DATA_WIDTH)
                  ,.M_AXI_USR_ID_WIDTH           (M_AXI_USR_0_ID_WIDTH)
                  ,.M_AXI_USR_AWUSER_WIDTH       (M_AXI_USR_0_AWUSER_WIDTH)
                  ,.M_AXI_USR_WUSER_WIDTH        (M_AXI_USR_0_WUSER_WIDTH)
                  ,.M_AXI_USR_BUSER_WIDTH        (M_AXI_USR_0_BUSER_WIDTH)
                  ,.M_AXI_USR_ARUSER_WIDTH       (M_AXI_USR_0_ARUSER_WIDTH)
                  ,.M_AXI_USR_RUSER_WIDTH        (M_AXI_USR_0_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (M_USR_RST_NUM_0)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_M0)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_M0)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_master_0 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          (usr_resetn)
                   ,.c2h_intr_in         (m_c2h_intr_in_0)
                   ,.c2h_gpio_in         (m_c2h_gpio_in_0)
                   ,.irq_ack             (m_irq_ack_0)
                   ,.irq_out             (m_irq_out_0)
                   ,.h2c_intr_out        (m_h2c_intr_out_0)
		   ,.h2c_gpio_out        (m_h2c_gpio_out_0)
                   ,.h2c_pulse_out	 (m_h2c_pulse_out_0)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_m0)
                   `c_axi4(m_axi, m_axi_pcie_m0) 
                   `c_axi(m_axi_usr, m_axi_usr_0)
);

end else begin 

assign m_irq_out_0 = 1'b0;  

end

if (NUM_MASTER_BRIDGE>='h2) begin : gen_axi_master_1

axi_master#(
                   .AXI_PROTOCOL                 (M_AXI_USR_1_PROTOCOL)
                  ,.M_AXI_USR_ADDR_WIDTH         (M_AXI_USR_1_ADDR_WIDTH)
                  ,.M_AXI_USR_DATA_WIDTH         (M_AXI_USR_1_DATA_WIDTH)
                  ,.M_AXI_USR_ID_WIDTH           (M_AXI_USR_1_ID_WIDTH)
                  ,.M_AXI_USR_AWUSER_WIDTH       (M_AXI_USR_1_AWUSER_WIDTH)
                  ,.M_AXI_USR_WUSER_WIDTH        (M_AXI_USR_1_WUSER_WIDTH)
                  ,.M_AXI_USR_BUSER_WIDTH        (M_AXI_USR_1_BUSER_WIDTH)
                  ,.M_AXI_USR_ARUSER_WIDTH       (M_AXI_USR_1_ARUSER_WIDTH)
                  ,.M_AXI_USR_RUSER_WIDTH        (M_AXI_USR_1_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (M_USR_RST_NUM_1)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_M1)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_M1)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_master_1 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (m_c2h_intr_in_1)
                   ,.c2h_gpio_in         (m_c2h_gpio_in_1)
                   ,.irq_ack             (m_irq_ack_1)
                   ,.irq_out             (m_irq_out_1)
                   ,.h2c_intr_out        (m_h2c_intr_out_1)
		   ,.h2c_gpio_out        (m_h2c_gpio_out_1)
                   ,.h2c_pulse_out	 (m_h2c_pulse_out_1)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_m1)
                   `c_axi4(m_axi, m_axi_pcie_m1) 
                   `c_axi(m_axi_usr, m_axi_usr_1)
);

end else begin 

assign m_irq_out_1 = 1'b0;  

end

if (NUM_MASTER_BRIDGE>='h3) begin : gen_axi_master_2

axi_master#(
                   .AXI_PROTOCOL                 (M_AXI_USR_2_PROTOCOL)
                  ,.M_AXI_USR_ADDR_WIDTH         (M_AXI_USR_2_ADDR_WIDTH)
                  ,.M_AXI_USR_DATA_WIDTH         (M_AXI_USR_2_DATA_WIDTH)
                  ,.M_AXI_USR_ID_WIDTH           (M_AXI_USR_2_ID_WIDTH)
                  ,.M_AXI_USR_AWUSER_WIDTH       (M_AXI_USR_2_AWUSER_WIDTH)
                  ,.M_AXI_USR_WUSER_WIDTH        (M_AXI_USR_2_WUSER_WIDTH)
                  ,.M_AXI_USR_BUSER_WIDTH        (M_AXI_USR_2_BUSER_WIDTH)
                  ,.M_AXI_USR_ARUSER_WIDTH       (M_AXI_USR_2_ARUSER_WIDTH)
                  ,.M_AXI_USR_RUSER_WIDTH        (M_AXI_USR_2_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (M_USR_RST_NUM_2)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_M2)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_M2)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_master_2 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (m_c2h_intr_in_2)
                   ,.c2h_gpio_in         (m_c2h_gpio_in_2)
                   ,.irq_ack             (m_irq_ack_2)
                   ,.irq_out             (m_irq_out_2)
                   ,.h2c_intr_out        (m_h2c_intr_out_2)
		   ,.h2c_gpio_out        (m_h2c_gpio_out_2)
                   ,.h2c_pulse_out	 (m_h2c_pulse_out_2)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_m2)
                   `c_axi4(m_axi, m_axi_pcie_m2) 
                   `c_axi(m_axi_usr, m_axi_usr_2)
);

end else begin 

assign m_irq_out_2 = 1'b0;  

end

if (NUM_MASTER_BRIDGE>='h4) begin : gen_axi_master_3

axi_master#(
                   .AXI_PROTOCOL                 (M_AXI_USR_3_PROTOCOL)
                  ,.M_AXI_USR_ADDR_WIDTH         (M_AXI_USR_3_ADDR_WIDTH)
                  ,.M_AXI_USR_DATA_WIDTH         (M_AXI_USR_3_DATA_WIDTH)
                  ,.M_AXI_USR_ID_WIDTH           (M_AXI_USR_3_ID_WIDTH)
                  ,.M_AXI_USR_AWUSER_WIDTH       (M_AXI_USR_3_AWUSER_WIDTH)
                  ,.M_AXI_USR_WUSER_WIDTH        (M_AXI_USR_3_WUSER_WIDTH)
                  ,.M_AXI_USR_BUSER_WIDTH        (M_AXI_USR_3_BUSER_WIDTH)
                  ,.M_AXI_USR_ARUSER_WIDTH       (M_AXI_USR_3_ARUSER_WIDTH)
                  ,.M_AXI_USR_RUSER_WIDTH        (M_AXI_USR_3_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (M_USR_RST_NUM_3)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_M3)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_M3)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_master_3 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (m_c2h_intr_in_3)
                   ,.c2h_gpio_in         (m_c2h_gpio_in_3)
                   ,.irq_ack             (m_irq_ack_3)
                   ,.irq_out             (m_irq_out_3)
                   ,.h2c_intr_out        (m_h2c_intr_out_3)
		   ,.h2c_gpio_out        (m_h2c_gpio_out_3)
                   ,.h2c_pulse_out	 (m_h2c_pulse_out_3)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_m3)
                   `c_axi4(m_axi, m_axi_pcie_m3) 
                   `c_axi(m_axi_usr, m_axi_usr_3)
);

end else begin 

assign m_irq_out_3 = 1'b0;  

end

if (NUM_MASTER_BRIDGE>='h5) begin : gen_axi_master_4

axi_master#(
                   .AXI_PROTOCOL                 (M_AXI_USR_4_PROTOCOL)
                  ,.M_AXI_USR_ADDR_WIDTH         (M_AXI_USR_4_ADDR_WIDTH)
                  ,.M_AXI_USR_DATA_WIDTH         (M_AXI_USR_4_DATA_WIDTH)
                  ,.M_AXI_USR_ID_WIDTH           (M_AXI_USR_4_ID_WIDTH)
                  ,.M_AXI_USR_AWUSER_WIDTH       (M_AXI_USR_4_AWUSER_WIDTH)
                  ,.M_AXI_USR_WUSER_WIDTH        (M_AXI_USR_4_WUSER_WIDTH)
                  ,.M_AXI_USR_BUSER_WIDTH        (M_AXI_USR_4_BUSER_WIDTH)
                  ,.M_AXI_USR_ARUSER_WIDTH       (M_AXI_USR_4_ARUSER_WIDTH)
                  ,.M_AXI_USR_RUSER_WIDTH        (M_AXI_USR_4_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (M_USR_RST_NUM_4)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_M4)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_M4)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_master_4 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (m_c2h_intr_in_4)
                   ,.c2h_gpio_in         (m_c2h_gpio_in_4)
                   ,.irq_ack             (m_irq_ack_4)
                   ,.irq_out             (m_irq_out_4)
                   ,.h2c_intr_out        (m_h2c_intr_out_4)
		   ,.h2c_gpio_out        (m_h2c_gpio_out_4)
                   ,.h2c_pulse_out	 (m_h2c_pulse_out_4)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_m4)
                   `c_axi4(m_axi, m_axi_pcie_m4) 
                   `c_axi(m_axi_usr, m_axi_usr_4)
);

end else begin 

assign m_irq_out_4 = 1'b0;  

end

if (NUM_MASTER_BRIDGE>='h6) begin : gen_axi_master_5

axi_master#(
                   .AXI_PROTOCOL                 (M_AXI_USR_5_PROTOCOL)
                  ,.M_AXI_USR_ADDR_WIDTH         (M_AXI_USR_5_ADDR_WIDTH)
                  ,.M_AXI_USR_DATA_WIDTH         (M_AXI_USR_5_DATA_WIDTH)
                  ,.M_AXI_USR_ID_WIDTH           (M_AXI_USR_5_ID_WIDTH)
                  ,.M_AXI_USR_AWUSER_WIDTH       (M_AXI_USR_5_AWUSER_WIDTH)
                  ,.M_AXI_USR_WUSER_WIDTH        (M_AXI_USR_5_WUSER_WIDTH)
                  ,.M_AXI_USR_BUSER_WIDTH        (M_AXI_USR_5_BUSER_WIDTH)
                  ,.M_AXI_USR_ARUSER_WIDTH       (M_AXI_USR_5_ARUSER_WIDTH)
                  ,.M_AXI_USR_RUSER_WIDTH        (M_AXI_USR_5_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (M_USR_RST_NUM_5)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_M5)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_M5)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_master_5 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (m_c2h_intr_in_5)
                   ,.c2h_gpio_in         (m_c2h_gpio_in_5)
                   ,.irq_ack             (m_irq_ack_5)
                   ,.irq_out             (m_irq_out_5)
                   ,.h2c_intr_out        (m_h2c_intr_out_5)
		   ,.h2c_gpio_out        (m_h2c_gpio_out_5)
                   ,.h2c_pulse_out	 (m_h2c_pulse_out_5)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_m5)
                   `c_axi4(m_axi, m_axi_pcie_m5) 
                   `c_axi(m_axi_usr, m_axi_usr_5)
);

end else begin 

assign m_irq_out_5 = 1'b0;  

end

if (NUM_SLAVE_BRIDGE>='h1) begin : gen_axi_slave_0

axi_slave#(
                   .AXI_PROTOCOL                 (S_AXI_USR_0_PROTOCOL)
                  ,.S_AXI_USR_ADDR_WIDTH         (S_AXI_USR_0_ADDR_WIDTH)
                  ,.S_AXI_USR_DATA_WIDTH         (S_AXI_USR_0_DATA_WIDTH)
                  ,.S_AXI_USR_ID_WIDTH           (S_AXI_USR_0_ID_WIDTH)
                  ,.S_AXI_USR_AWUSER_WIDTH       (S_AXI_USR_0_AWUSER_WIDTH)
                  ,.S_AXI_USR_WUSER_WIDTH        (S_AXI_USR_0_WUSER_WIDTH)
                  ,.S_AXI_USR_BUSER_WIDTH        (S_AXI_USR_0_BUSER_WIDTH)
                  ,.S_AXI_USR_ARUSER_WIDTH       (S_AXI_USR_0_ARUSER_WIDTH)
                  ,.S_AXI_USR_RUSER_WIDTH        (S_AXI_USR_0_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (S_USR_RST_NUM_0)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_S0)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_S0)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_slave_0 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (s_c2h_intr_in_0)
                   ,.c2h_gpio_in         (s_c2h_gpio_in_0)
                   ,.irq_ack             (s_irq_ack_0)
                   ,.irq_out             (s_irq_out_0)
                   ,.h2c_intr_out        (s_h2c_intr_out_0)
		   ,.h2c_gpio_out        (s_h2c_gpio_out_0)
                   ,.h2c_pulse_out	 (s_h2c_pulse_out_0)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_s0)
                   `c_axi4(m_axi, m_axi_pcie_s0) 
                   `c_axi(s_axi_usr, s_axi_usr_0)
);

end else begin 

assign s_irq_out_0 = 1'b0;  

end

if (NUM_SLAVE_BRIDGE>='h2) begin : gen_axi_slave_1

axi_slave#(
                   .AXI_PROTOCOL                 (S_AXI_USR_1_PROTOCOL)
                  ,.S_AXI_USR_ADDR_WIDTH         (S_AXI_USR_1_ADDR_WIDTH)
                  ,.S_AXI_USR_DATA_WIDTH         (S_AXI_USR_1_DATA_WIDTH)
                  ,.S_AXI_USR_ID_WIDTH           (S_AXI_USR_1_ID_WIDTH)
                  ,.S_AXI_USR_AWUSER_WIDTH       (S_AXI_USR_1_AWUSER_WIDTH)
                  ,.S_AXI_USR_WUSER_WIDTH        (S_AXI_USR_1_WUSER_WIDTH)
                  ,.S_AXI_USR_BUSER_WIDTH        (S_AXI_USR_1_BUSER_WIDTH)
                  ,.S_AXI_USR_ARUSER_WIDTH       (S_AXI_USR_1_ARUSER_WIDTH)
                  ,.S_AXI_USR_RUSER_WIDTH        (S_AXI_USR_1_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (S_USR_RST_NUM_1)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_S1)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_S1)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_slave_1 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (s_c2h_intr_in_1)
                   ,.c2h_gpio_in         (s_c2h_gpio_in_1)
                   ,.irq_ack             (s_irq_ack_1)
                   ,.irq_out             (s_irq_out_1)
                   ,.h2c_intr_out        (s_h2c_intr_out_1)
		   ,.h2c_gpio_out        (s_h2c_gpio_out_1)
                   ,.h2c_pulse_out	 (s_h2c_pulse_out_1)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_s1)
                   `c_axi4(m_axi, m_axi_pcie_s1) 
                   `c_axi(s_axi_usr, s_axi_usr_1)
);

end else begin 

assign s_irq_out_1 = 1'b0;  

end

if (NUM_SLAVE_BRIDGE>='h3) begin : gen_axi_slave_2

axi_slave#(
                   .AXI_PROTOCOL                 (S_AXI_USR_2_PROTOCOL)
                  ,.S_AXI_USR_ADDR_WIDTH         (S_AXI_USR_2_ADDR_WIDTH)
                  ,.S_AXI_USR_DATA_WIDTH         (S_AXI_USR_2_DATA_WIDTH)
                  ,.S_AXI_USR_ID_WIDTH           (S_AXI_USR_2_ID_WIDTH)
                  ,.S_AXI_USR_AWUSER_WIDTH       (S_AXI_USR_2_AWUSER_WIDTH)
                  ,.S_AXI_USR_WUSER_WIDTH        (S_AXI_USR_2_WUSER_WIDTH)
                  ,.S_AXI_USR_BUSER_WIDTH        (S_AXI_USR_2_BUSER_WIDTH)
                  ,.S_AXI_USR_ARUSER_WIDTH       (S_AXI_USR_2_ARUSER_WIDTH)
                  ,.S_AXI_USR_RUSER_WIDTH        (S_AXI_USR_2_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (S_USR_RST_NUM_2)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_S2)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_S2)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_slave_2 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (s_c2h_intr_in_2)
                   ,.c2h_gpio_in         (s_c2h_gpio_in_2)
                   ,.irq_ack             (s_irq_ack_2)
                   ,.irq_out             (s_irq_out_2)
                   ,.h2c_intr_out        (s_h2c_intr_out_2)
		   ,.h2c_gpio_out        (s_h2c_gpio_out_2)
                   ,.h2c_pulse_out	 (s_h2c_pulse_out_2)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_s2)
                   `c_axi4(m_axi, m_axi_pcie_s2) 
                   `c_axi(s_axi_usr, s_axi_usr_2)
);

end else begin 

assign s_irq_out_2 = 1'b0;  

end

if (NUM_SLAVE_BRIDGE>='h4) begin : gen_axi_slave_3

axi_slave#(
                   .AXI_PROTOCOL                 (S_AXI_USR_3_PROTOCOL)
                  ,.S_AXI_USR_ADDR_WIDTH         (S_AXI_USR_3_ADDR_WIDTH)
                  ,.S_AXI_USR_DATA_WIDTH         (S_AXI_USR_3_DATA_WIDTH)
                  ,.S_AXI_USR_ID_WIDTH           (S_AXI_USR_3_ID_WIDTH)
                  ,.S_AXI_USR_AWUSER_WIDTH       (S_AXI_USR_3_AWUSER_WIDTH)
                  ,.S_AXI_USR_WUSER_WIDTH        (S_AXI_USR_3_WUSER_WIDTH)
                  ,.S_AXI_USR_BUSER_WIDTH        (S_AXI_USR_3_BUSER_WIDTH)
                  ,.S_AXI_USR_ARUSER_WIDTH       (S_AXI_USR_3_ARUSER_WIDTH)
                  ,.S_AXI_USR_RUSER_WIDTH        (S_AXI_USR_3_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (S_USR_RST_NUM_3)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_S3)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_S3)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_slave_3 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (s_c2h_intr_in_3)
                   ,.c2h_gpio_in         (s_c2h_gpio_in_3)
                   ,.irq_ack             (s_irq_ack_3)
                   ,.irq_out             (s_irq_out_3)
                   ,.h2c_intr_out        (s_h2c_intr_out_3)
		   ,.h2c_gpio_out        (s_h2c_gpio_out_3)
                   ,.h2c_pulse_out	 (s_h2c_pulse_out_3)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_s3)
                   `c_axi4(m_axi, m_axi_pcie_s3) 
                   `c_axi(s_axi_usr, s_axi_usr_3)
);

end else begin 

assign s_irq_out_3 = 1'b0;  

end

if (NUM_SLAVE_BRIDGE>='h5) begin : gen_axi_slave_4

axi_slave#(
                   .AXI_PROTOCOL                 (S_AXI_USR_4_PROTOCOL)
                  ,.S_AXI_USR_ADDR_WIDTH         (S_AXI_USR_4_ADDR_WIDTH)
                  ,.S_AXI_USR_DATA_WIDTH         (S_AXI_USR_4_DATA_WIDTH)
                  ,.S_AXI_USR_ID_WIDTH           (S_AXI_USR_4_ID_WIDTH)
                  ,.S_AXI_USR_AWUSER_WIDTH       (S_AXI_USR_4_AWUSER_WIDTH)
                  ,.S_AXI_USR_WUSER_WIDTH        (S_AXI_USR_4_WUSER_WIDTH)
                  ,.S_AXI_USR_BUSER_WIDTH        (S_AXI_USR_4_BUSER_WIDTH)
                  ,.S_AXI_USR_ARUSER_WIDTH       (S_AXI_USR_4_ARUSER_WIDTH)
                  ,.S_AXI_USR_RUSER_WIDTH        (S_AXI_USR_4_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (S_USR_RST_NUM_4)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_S4)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_S4)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_slave_4 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (s_c2h_intr_in_4)
                   ,.c2h_gpio_in         (s_c2h_gpio_in_4)
                   ,.irq_ack             (s_irq_ack_4)
                   ,.irq_out             (s_irq_out_4)
                   ,.h2c_intr_out        (s_h2c_intr_out_4)
		   ,.h2c_gpio_out        (s_h2c_gpio_out_4)
                   ,.h2c_pulse_out	 (s_h2c_pulse_out_4)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_s4)
                   `c_axi4(m_axi, m_axi_pcie_s4) 
                   `c_axi(s_axi_usr, s_axi_usr_4)
);

end else begin 

assign s_irq_out_4 = 1'b0;  

end

if (NUM_SLAVE_BRIDGE>='h6) begin : gen_axi_slave_5

axi_slave#(
                   .AXI_PROTOCOL                 (S_AXI_USR_5_PROTOCOL)
                  ,.S_AXI_USR_ADDR_WIDTH         (S_AXI_USR_5_ADDR_WIDTH)
                  ,.S_AXI_USR_DATA_WIDTH         (S_AXI_USR_5_DATA_WIDTH)
                  ,.S_AXI_USR_ID_WIDTH           (S_AXI_USR_5_ID_WIDTH)
                  ,.S_AXI_USR_AWUSER_WIDTH       (S_AXI_USR_5_AWUSER_WIDTH)
                  ,.S_AXI_USR_WUSER_WIDTH        (S_AXI_USR_5_WUSER_WIDTH)
                  ,.S_AXI_USR_BUSER_WIDTH        (S_AXI_USR_5_BUSER_WIDTH)
                  ,.S_AXI_USR_ARUSER_WIDTH       (S_AXI_USR_5_ARUSER_WIDTH)
                  ,.S_AXI_USR_RUSER_WIDTH        (S_AXI_USR_5_RUSER_WIDTH)
                  ,.USR_RST_NUM                  (S_USR_RST_NUM_5)
	          ,.PCIE_LAST_BRIDGE             (PCIE_LAST_BRIDGE_S5)
		  ,.LAST_BRIDGE		         (LAST_BRIDGE_S5)
                  ,.S_AXI_ADDR_WIDTH             (S_AXI_ADDR_WIDTH)
                  ,.S_AXI_DATA_WIDTH             (S_AXI_DATA_WIDTH)
                  ,.M_AXI_ADDR_WIDTH             (M_AXI_ADDR_WIDTH)
                  ,.M_AXI_DATA_WIDTH             (M_AXI_DATA_WIDTH)
                  ,.M_AXI_ID_WIDTH               (M_AXI_ID_WIDTH)
                  ,.M_AXI_USER_WIDTH             (M_AXI_USER_WIDTH)
                  ,.RAM_SIZE                     (RAM_SIZE)
                  ,.MAX_DESC                     (MAX_DESC)
	          ,.PCIE_AXI                     (IS_REAL_PCIE)
		  ,.EXTEND_WSTRB		 (EXTEND_WSTRB)
) axi_slave_5 (
                    .axi_aclk            (clk)
                   ,.axi_aresetn         (resetn)
                   ,.usr_resetn          ()
                   ,.c2h_intr_in         (s_c2h_intr_in_5)
                   ,.c2h_gpio_in         (s_c2h_gpio_in_5)
                   ,.irq_ack             (s_irq_ack_5)
                   ,.irq_out             (s_irq_out_5)
                   ,.h2c_intr_out        (s_h2c_intr_out_5)
		   ,.h2c_gpio_out        (s_h2c_gpio_out_5)
                   ,.h2c_pulse_out	 (s_h2c_pulse_out_5)                                      
                   `c_axi4lite(s_axi, s_axi_pcie_s5)
                   `c_axi4(m_axi, m_axi_pcie_s5) 
                   `c_axi(s_axi_usr, s_axi_usr_5)
);

end else begin 

assign s_irq_out_5 = 1'b0;  

end

endgenerate

endmodule
