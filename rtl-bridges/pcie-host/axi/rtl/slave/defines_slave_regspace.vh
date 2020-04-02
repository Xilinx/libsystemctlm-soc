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
 *
 *
 */

// OFFSET ADDR of REGS

`define BRIDGE_IDENTIFICATION_REG_ADDR 'h0
`define BRIDGE_POSITION_REG_ADDR 	   'h4
`define VERSION_REG_ADDR             'h20     
`define BRIDGE_TYPE_REG_ADDR         'h24     
`define MODE_SELECT_REG_ADDR         'h38     
`define RESET_REG_ADDR               'h3C

`define H2C_INTR_0_REG_ADDR          'h40    
`define H2C_INTR_1_REG_ADDR          'h44
`define H2C_INTR_2_REG_ADDR          'h48    
`define H2C_INTR_3_REG_ADDR          'h4C    

`define C2H_INTR_STATUS_0_REG_ADDR  	    'h60
`define INTR_C2H_TOGGLE_STATUS_0_REG_ADDR   'h64
`define INTR_C2H_TOGGLE_CLEAR_0_REG_ADDR    'h68
`define INTR_C2H_TOGGLE_ENABLE_0_REG_ADDR   'h6C

`define C2H_INTR_STATUS_1_REG_ADDR  	    'h70
`define INTR_C2H_TOGGLE_STATUS_1_REG_ADDR   'h74
`define INTR_C2H_TOGGLE_CLEAR_1_REG_ADDR    'h78
`define INTR_C2H_TOGGLE_ENABLE_1_REG_ADDR   'h7C


`define C2H_GPIO_0_REG_ADDR   'h80    
`define C2H_GPIO_1_REG_ADDR   'h84    
`define C2H_GPIO_2_REG_ADDR   'h88    
`define C2H_GPIO_3_REG_ADDR   'h8C    
`define C2H_GPIO_4_REG_ADDR   'h90    
`define C2H_GPIO_5_REG_ADDR   'h94    
`define C2H_GPIO_6_REG_ADDR   'h98    
`define C2H_GPIO_7_REG_ADDR   'h9C    
`define C2H_GPIO_8_REG_ADDR   'hA0    
`define C2H_GPIO_9_REG_ADDR   'hA4    
`define C2H_GPIO_10_REG_ADDR  'hA8    
`define C2H_GPIO_11_REG_ADDR  'hAC    
`define C2H_GPIO_12_REG_ADDR  'hB0    
`define C2H_GPIO_13_REG_ADDR  'hB4    
`define C2H_GPIO_14_REG_ADDR  'hB8    
`define C2H_GPIO_15_REG_ADDR  'hBC    


`define H2C_GPIO_0_REG_ADDR      'hC0    
`define H2C_GPIO_1_REG_ADDR      'hC4    
`define H2C_GPIO_2_REG_ADDR      'hC8    
`define H2C_GPIO_3_REG_ADDR      'hCC    
`define H2C_GPIO_4_REG_ADDR      'hD0    
`define H2C_GPIO_5_REG_ADDR      'hD4    
`define H2C_GPIO_6_REG_ADDR      'hD8    
`define H2C_GPIO_7_REG_ADDR      'hDC    
`define H2C_GPIO_8_REG_ADDR      'hE0    
`define H2C_GPIO_9_REG_ADDR      'hE4    
`define H2C_GPIO_10_REG_ADDR     'hE8    
`define H2C_GPIO_11_REG_ADDR     'hEC    
`define H2C_GPIO_12_REG_ADDR     'hF0    
`define H2C_GPIO_13_REG_ADDR     'hF4    
`define H2C_GPIO_14_REG_ADDR     'hF8    
`define H2C_GPIO_15_REG_ADDR     'hFC    

`define H2C_PULSE_0_REG_ADDR     'h100    
`define H2C_PULSE_1_REG_ADDR     'h104   


`define AXI_BRIDGE_CONFIG_REG_ADDR   'h200   
`define AXI_MAX_DESC_REG_ADDR        'h204   
`define INTR_STATUS_REG_ADDR         'h208   
`define INTR_ERROR_STATUS_REG_ADDR   'h20C   
`define INTR_ERROR_CLEAR_REG_ADDR    'h210   
`define INTR_ERROR_ENABLE_REG_ADDR   'h214   

`define BRIDGE_RD_USER_CONFIG_REG_ADDR                'h218
`define BRIDGE_WR_USER_CONFIG_REG_ADDR                'h21C

`define ADDR_IN_0_REG_ADDR                'h220
`define ADDR_IN_1_REG_ADDR                'h224
`define ADDR_IN_2_REG_ADDR                'h228
`define ADDR_IN_3_REG_ADDR                'h22C
`define TRANS_MASK_0_REG_ADDR             'h230
`define TRANS_MASK_1_REG_ADDR             'h234
`define TRANS_MASK_2_REG_ADDR             'h238
`define TRANS_MASK_3_REG_ADDR             'h23C
`define TRANS_ADDR_0_REG_ADDR             'h240
`define TRANS_ADDR_1_REG_ADDR             'h244
`define TRANS_ADDR_2_REG_ADDR             'h248
`define TRANS_ADDR_3_REG_ADDR             'h24C

`define OWNERSHIP_REG_ADDR           'h300   
`define OWNERSHIP_FLIP_REG_ADDR      'h304   
`define STATUS_RESP_REG_ADDR         'h308   
`define INTR_TXN_AVAIL_STATUS_REG_ADDR    'h30C   
`define INTR_TXN_AVAIL_CLEAR_REG_ADDR     'h310   
`define INTR_TXN_AVAIL_ENABLE_REG_ADDR    'h314   
`define STATUS_RESP_COMP_REG_ADDR         'h318
`define STATUS_BUSY_REG_ADDR              'h31C
`define INTR_COMP_STATUS_REG_ADDR    'h320   
`define INTR_COMP_CLEAR_REG_ADDR     'h324 
`define INTR_COMP_ENABLE_REG_ADDR    'h328 
  
`define RESP_ORDER_REG_ADDR             'h32C   
`define RESP_FIFO_FREE_LEVEL_REG_ADDR   'h330

`define DESC_0_BASE_ADDR 'h3000
`define DESC_0_TXN_TYPE_REG_ADDR             `DESC_0_BASE_ADDR + 'h00     
`define DESC_0_SIZE_REG_ADDR                 `DESC_0_BASE_ADDR + 'h04     
`define DESC_0_DATA_OFFSET_REG_ADDR          `DESC_0_BASE_ADDR + 'h08     
`define DESC_0_DATA_HOST_ADDR_0_REG_ADDR     `DESC_0_BASE_ADDR + 'h10     
`define DESC_0_DATA_HOST_ADDR_1_REG_ADDR     `DESC_0_BASE_ADDR + 'h14     
`define DESC_0_DATA_HOST_ADDR_2_REG_ADDR     `DESC_0_BASE_ADDR + 'h18     
`define DESC_0_DATA_HOST_ADDR_3_REG_ADDR     `DESC_0_BASE_ADDR + 'h1C     
`define DESC_0_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_0_BASE_ADDR + 'h20     
`define DESC_0_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_0_BASE_ADDR + 'h24     
`define DESC_0_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_0_BASE_ADDR + 'h28     
`define DESC_0_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_0_BASE_ADDR + 'h2C     
`define DESC_0_AXSIZE_REG_ADDR               `DESC_0_BASE_ADDR + 'h30     
`define DESC_0_ATTR_REG_ADDR                 `DESC_0_BASE_ADDR + 'h34     
`define DESC_0_AXADDR_0_REG_ADDR             `DESC_0_BASE_ADDR + 'h40     
`define DESC_0_AXADDR_1_REG_ADDR             `DESC_0_BASE_ADDR + 'h44     
`define DESC_0_AXADDR_2_REG_ADDR             `DESC_0_BASE_ADDR + 'h48     
`define DESC_0_AXADDR_3_REG_ADDR             `DESC_0_BASE_ADDR + 'h4C     
`define DESC_0_AXID_0_REG_ADDR               `DESC_0_BASE_ADDR + 'h50     
`define DESC_0_AXID_1_REG_ADDR               `DESC_0_BASE_ADDR + 'h54     
`define DESC_0_AXID_2_REG_ADDR               `DESC_0_BASE_ADDR + 'h58     
`define DESC_0_AXID_3_REG_ADDR               `DESC_0_BASE_ADDR + 'h5C     
`define DESC_0_AXUSER_0_REG_ADDR             `DESC_0_BASE_ADDR + 'h60     
`define DESC_0_AXUSER_1_REG_ADDR             `DESC_0_BASE_ADDR + 'h64     
`define DESC_0_AXUSER_2_REG_ADDR             `DESC_0_BASE_ADDR + 'h68     
`define DESC_0_AXUSER_3_REG_ADDR             `DESC_0_BASE_ADDR + 'h6C     
`define DESC_0_AXUSER_4_REG_ADDR             `DESC_0_BASE_ADDR + 'h70     
`define DESC_0_AXUSER_5_REG_ADDR             `DESC_0_BASE_ADDR + 'h74     
`define DESC_0_AXUSER_6_REG_ADDR             `DESC_0_BASE_ADDR + 'h78     
`define DESC_0_AXUSER_7_REG_ADDR             `DESC_0_BASE_ADDR + 'h7C     
`define DESC_0_AXUSER_8_REG_ADDR             `DESC_0_BASE_ADDR + 'h80     
`define DESC_0_AXUSER_9_REG_ADDR             `DESC_0_BASE_ADDR + 'h84     
`define DESC_0_AXUSER_10_REG_ADDR            `DESC_0_BASE_ADDR + 'h88     
`define DESC_0_AXUSER_11_REG_ADDR            `DESC_0_BASE_ADDR + 'h8C     
`define DESC_0_AXUSER_12_REG_ADDR            `DESC_0_BASE_ADDR + 'h90     
`define DESC_0_AXUSER_13_REG_ADDR            `DESC_0_BASE_ADDR + 'h94     
`define DESC_0_AXUSER_14_REG_ADDR            `DESC_0_BASE_ADDR + 'h98     
`define DESC_0_AXUSER_15_REG_ADDR            `DESC_0_BASE_ADDR + 'h9C     
`define DESC_0_XUSER_0_REG_ADDR              `DESC_0_BASE_ADDR + 'hA0     
`define DESC_0_XUSER_1_REG_ADDR              `DESC_0_BASE_ADDR + 'hA4     
`define DESC_0_XUSER_2_REG_ADDR              `DESC_0_BASE_ADDR + 'hA8     
`define DESC_0_XUSER_3_REG_ADDR              `DESC_0_BASE_ADDR + 'hAC     
`define DESC_0_XUSER_4_REG_ADDR              `DESC_0_BASE_ADDR + 'hB0     
`define DESC_0_XUSER_5_REG_ADDR              `DESC_0_BASE_ADDR + 'hB4     
`define DESC_0_XUSER_6_REG_ADDR              `DESC_0_BASE_ADDR + 'hB8     
`define DESC_0_XUSER_7_REG_ADDR              `DESC_0_BASE_ADDR + 'hBC     
`define DESC_0_XUSER_8_REG_ADDR              `DESC_0_BASE_ADDR + 'hC0     
`define DESC_0_XUSER_9_REG_ADDR              `DESC_0_BASE_ADDR + 'hC4     
`define DESC_0_XUSER_10_REG_ADDR             `DESC_0_BASE_ADDR + 'hC8     
`define DESC_0_XUSER_11_REG_ADDR             `DESC_0_BASE_ADDR + 'hCC     
`define DESC_0_XUSER_12_REG_ADDR             `DESC_0_BASE_ADDR + 'hD0     
`define DESC_0_XUSER_13_REG_ADDR             `DESC_0_BASE_ADDR + 'hD4     
`define DESC_0_XUSER_14_REG_ADDR             `DESC_0_BASE_ADDR + 'hD8     
`define DESC_0_XUSER_15_REG_ADDR             `DESC_0_BASE_ADDR + 'hDC     
`define DESC_0_WUSER_0_REG_ADDR              `DESC_0_BASE_ADDR + 'hE0     
`define DESC_0_WUSER_1_REG_ADDR              `DESC_0_BASE_ADDR + 'hE4     
`define DESC_0_WUSER_2_REG_ADDR              `DESC_0_BASE_ADDR + 'hE8     
`define DESC_0_WUSER_3_REG_ADDR              `DESC_0_BASE_ADDR + 'hEC     
`define DESC_0_WUSER_4_REG_ADDR              `DESC_0_BASE_ADDR + 'hF0     
`define DESC_0_WUSER_5_REG_ADDR              `DESC_0_BASE_ADDR + 'hF4     
`define DESC_0_WUSER_6_REG_ADDR              `DESC_0_BASE_ADDR + 'hF8     
`define DESC_0_WUSER_7_REG_ADDR              `DESC_0_BASE_ADDR + 'hFC     
`define DESC_0_WUSER_8_REG_ADDR              `DESC_0_BASE_ADDR + 'h100    
`define DESC_0_WUSER_9_REG_ADDR              `DESC_0_BASE_ADDR + 'h104    
`define DESC_0_WUSER_10_REG_ADDR             `DESC_0_BASE_ADDR + 'h108    
`define DESC_0_WUSER_11_REG_ADDR             `DESC_0_BASE_ADDR + 'h10C    
`define DESC_0_WUSER_12_REG_ADDR             `DESC_0_BASE_ADDR + 'h110    
`define DESC_0_WUSER_13_REG_ADDR             `DESC_0_BASE_ADDR + 'h114    
`define DESC_0_WUSER_14_REG_ADDR             `DESC_0_BASE_ADDR + 'h118    
`define DESC_0_WUSER_15_REG_ADDR             `DESC_0_BASE_ADDR + 'h11C    


`define DESC_1_BASE_ADDR 'h3200

`define DESC_1_TXN_TYPE_REG_ADDR             `DESC_1_BASE_ADDR + 'h00     
`define DESC_1_SIZE_REG_ADDR                 `DESC_1_BASE_ADDR + 'h04     
`define DESC_1_DATA_OFFSET_REG_ADDR          `DESC_1_BASE_ADDR + 'h08     
`define DESC_1_DATA_HOST_ADDR_0_REG_ADDR     `DESC_1_BASE_ADDR + 'h10     
`define DESC_1_DATA_HOST_ADDR_1_REG_ADDR     `DESC_1_BASE_ADDR + 'h14     
`define DESC_1_DATA_HOST_ADDR_2_REG_ADDR     `DESC_1_BASE_ADDR + 'h18     
`define DESC_1_DATA_HOST_ADDR_3_REG_ADDR     `DESC_1_BASE_ADDR + 'h1C     
`define DESC_1_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_1_BASE_ADDR + 'h20     
`define DESC_1_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_1_BASE_ADDR + 'h24     
`define DESC_1_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_1_BASE_ADDR + 'h28     
`define DESC_1_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_1_BASE_ADDR + 'h2C     
`define DESC_1_AXSIZE_REG_ADDR               `DESC_1_BASE_ADDR + 'h30     
`define DESC_1_ATTR_REG_ADDR                 `DESC_1_BASE_ADDR + 'h34     
`define DESC_1_AXADDR_0_REG_ADDR             `DESC_1_BASE_ADDR + 'h40     
`define DESC_1_AXADDR_1_REG_ADDR             `DESC_1_BASE_ADDR + 'h44     
`define DESC_1_AXADDR_2_REG_ADDR             `DESC_1_BASE_ADDR + 'h48     
`define DESC_1_AXADDR_3_REG_ADDR             `DESC_1_BASE_ADDR + 'h4C     
`define DESC_1_AXID_0_REG_ADDR               `DESC_1_BASE_ADDR + 'h50     
`define DESC_1_AXID_1_REG_ADDR               `DESC_1_BASE_ADDR + 'h54     
`define DESC_1_AXID_2_REG_ADDR               `DESC_1_BASE_ADDR + 'h58     
`define DESC_1_AXID_3_REG_ADDR               `DESC_1_BASE_ADDR + 'h5C     
`define DESC_1_AXUSER_0_REG_ADDR             `DESC_1_BASE_ADDR + 'h60     
`define DESC_1_AXUSER_1_REG_ADDR             `DESC_1_BASE_ADDR + 'h64     
`define DESC_1_AXUSER_2_REG_ADDR             `DESC_1_BASE_ADDR + 'h68     
`define DESC_1_AXUSER_3_REG_ADDR             `DESC_1_BASE_ADDR + 'h6C     
`define DESC_1_AXUSER_4_REG_ADDR             `DESC_1_BASE_ADDR + 'h70     
`define DESC_1_AXUSER_5_REG_ADDR             `DESC_1_BASE_ADDR + 'h74     
`define DESC_1_AXUSER_6_REG_ADDR             `DESC_1_BASE_ADDR + 'h78     
`define DESC_1_AXUSER_7_REG_ADDR             `DESC_1_BASE_ADDR + 'h7C     
`define DESC_1_AXUSER_8_REG_ADDR             `DESC_1_BASE_ADDR + 'h80     
`define DESC_1_AXUSER_9_REG_ADDR             `DESC_1_BASE_ADDR + 'h84     
`define DESC_1_AXUSER_10_REG_ADDR            `DESC_1_BASE_ADDR + 'h88     
`define DESC_1_AXUSER_11_REG_ADDR            `DESC_1_BASE_ADDR + 'h8C     
`define DESC_1_AXUSER_12_REG_ADDR            `DESC_1_BASE_ADDR + 'h90     
`define DESC_1_AXUSER_13_REG_ADDR            `DESC_1_BASE_ADDR + 'h94     
`define DESC_1_AXUSER_14_REG_ADDR            `DESC_1_BASE_ADDR + 'h98     
`define DESC_1_AXUSER_15_REG_ADDR            `DESC_1_BASE_ADDR + 'h9C     
`define DESC_1_XUSER_0_REG_ADDR              `DESC_1_BASE_ADDR + 'hA0     
`define DESC_1_XUSER_1_REG_ADDR              `DESC_1_BASE_ADDR + 'hA4     
`define DESC_1_XUSER_2_REG_ADDR              `DESC_1_BASE_ADDR + 'hA8     
`define DESC_1_XUSER_3_REG_ADDR              `DESC_1_BASE_ADDR + 'hAC     
`define DESC_1_XUSER_4_REG_ADDR              `DESC_1_BASE_ADDR + 'hB0     
`define DESC_1_XUSER_5_REG_ADDR              `DESC_1_BASE_ADDR + 'hB4     
`define DESC_1_XUSER_6_REG_ADDR              `DESC_1_BASE_ADDR + 'hB8     
`define DESC_1_XUSER_7_REG_ADDR              `DESC_1_BASE_ADDR + 'hBC     
`define DESC_1_XUSER_8_REG_ADDR              `DESC_1_BASE_ADDR + 'hC0     
`define DESC_1_XUSER_9_REG_ADDR              `DESC_1_BASE_ADDR + 'hC4     
`define DESC_1_XUSER_10_REG_ADDR             `DESC_1_BASE_ADDR + 'hC8     
`define DESC_1_XUSER_11_REG_ADDR             `DESC_1_BASE_ADDR + 'hCC     
`define DESC_1_XUSER_12_REG_ADDR             `DESC_1_BASE_ADDR + 'hD0     
`define DESC_1_XUSER_13_REG_ADDR             `DESC_1_BASE_ADDR + 'hD4     
`define DESC_1_XUSER_14_REG_ADDR             `DESC_1_BASE_ADDR + 'hD8     
`define DESC_1_XUSER_15_REG_ADDR             `DESC_1_BASE_ADDR + 'hDC     
`define DESC_1_WUSER_0_REG_ADDR              `DESC_1_BASE_ADDR + 'hE0     
`define DESC_1_WUSER_1_REG_ADDR              `DESC_1_BASE_ADDR + 'hE4     
`define DESC_1_WUSER_2_REG_ADDR              `DESC_1_BASE_ADDR + 'hE8     
`define DESC_1_WUSER_3_REG_ADDR              `DESC_1_BASE_ADDR + 'hEC     
`define DESC_1_WUSER_4_REG_ADDR              `DESC_1_BASE_ADDR + 'hF0     
`define DESC_1_WUSER_5_REG_ADDR              `DESC_1_BASE_ADDR + 'hF4     
`define DESC_1_WUSER_6_REG_ADDR              `DESC_1_BASE_ADDR + 'hF8     
`define DESC_1_WUSER_7_REG_ADDR              `DESC_1_BASE_ADDR + 'hFC     
`define DESC_1_WUSER_8_REG_ADDR              `DESC_1_BASE_ADDR + 'h100    
`define DESC_1_WUSER_9_REG_ADDR              `DESC_1_BASE_ADDR + 'h104    
`define DESC_1_WUSER_10_REG_ADDR             `DESC_1_BASE_ADDR + 'h108    
`define DESC_1_WUSER_11_REG_ADDR             `DESC_1_BASE_ADDR + 'h10C    
`define DESC_1_WUSER_12_REG_ADDR             `DESC_1_BASE_ADDR + 'h110    
`define DESC_1_WUSER_13_REG_ADDR             `DESC_1_BASE_ADDR + 'h114    
`define DESC_1_WUSER_14_REG_ADDR             `DESC_1_BASE_ADDR + 'h118    
`define DESC_1_WUSER_15_REG_ADDR             `DESC_1_BASE_ADDR + 'h11C    

`define DESC_2_BASE_ADDR 'h3400
`define DESC_2_TXN_TYPE_REG_ADDR             `DESC_2_BASE_ADDR + 'h00     
`define DESC_2_SIZE_REG_ADDR                 `DESC_2_BASE_ADDR + 'h04     
`define DESC_2_DATA_OFFSET_REG_ADDR          `DESC_2_BASE_ADDR + 'h08     
`define DESC_2_DATA_HOST_ADDR_0_REG_ADDR     `DESC_2_BASE_ADDR + 'h10     
`define DESC_2_DATA_HOST_ADDR_1_REG_ADDR     `DESC_2_BASE_ADDR + 'h14     
`define DESC_2_DATA_HOST_ADDR_2_REG_ADDR     `DESC_2_BASE_ADDR + 'h18     
`define DESC_2_DATA_HOST_ADDR_3_REG_ADDR     `DESC_2_BASE_ADDR + 'h1C     
`define DESC_2_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_2_BASE_ADDR + 'h20     
`define DESC_2_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_2_BASE_ADDR + 'h24     
`define DESC_2_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_2_BASE_ADDR + 'h28     
`define DESC_2_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_2_BASE_ADDR + 'h2C     
`define DESC_2_AXSIZE_REG_ADDR               `DESC_2_BASE_ADDR + 'h30     
`define DESC_2_ATTR_REG_ADDR                 `DESC_2_BASE_ADDR + 'h34     
`define DESC_2_AXADDR_0_REG_ADDR             `DESC_2_BASE_ADDR + 'h40     
`define DESC_2_AXADDR_1_REG_ADDR             `DESC_2_BASE_ADDR + 'h44     
`define DESC_2_AXADDR_2_REG_ADDR             `DESC_2_BASE_ADDR + 'h48     
`define DESC_2_AXADDR_3_REG_ADDR             `DESC_2_BASE_ADDR + 'h4C     
`define DESC_2_AXID_0_REG_ADDR               `DESC_2_BASE_ADDR + 'h50     
`define DESC_2_AXID_1_REG_ADDR               `DESC_2_BASE_ADDR + 'h54     
`define DESC_2_AXID_2_REG_ADDR               `DESC_2_BASE_ADDR + 'h58     
`define DESC_2_AXID_3_REG_ADDR               `DESC_2_BASE_ADDR + 'h5C     
`define DESC_2_AXUSER_0_REG_ADDR             `DESC_2_BASE_ADDR + 'h60     
`define DESC_2_AXUSER_1_REG_ADDR             `DESC_2_BASE_ADDR + 'h64     
`define DESC_2_AXUSER_2_REG_ADDR             `DESC_2_BASE_ADDR + 'h68     
`define DESC_2_AXUSER_3_REG_ADDR             `DESC_2_BASE_ADDR + 'h6C     
`define DESC_2_AXUSER_4_REG_ADDR             `DESC_2_BASE_ADDR + 'h70     
`define DESC_2_AXUSER_5_REG_ADDR             `DESC_2_BASE_ADDR + 'h74     
`define DESC_2_AXUSER_6_REG_ADDR             `DESC_2_BASE_ADDR + 'h78     
`define DESC_2_AXUSER_7_REG_ADDR             `DESC_2_BASE_ADDR + 'h7C     
`define DESC_2_AXUSER_8_REG_ADDR             `DESC_2_BASE_ADDR + 'h80     
`define DESC_2_AXUSER_9_REG_ADDR             `DESC_2_BASE_ADDR + 'h84     
`define DESC_2_AXUSER_10_REG_ADDR            `DESC_2_BASE_ADDR + 'h88     
`define DESC_2_AXUSER_11_REG_ADDR            `DESC_2_BASE_ADDR + 'h8C     
`define DESC_2_AXUSER_12_REG_ADDR            `DESC_2_BASE_ADDR + 'h90     
`define DESC_2_AXUSER_13_REG_ADDR            `DESC_2_BASE_ADDR + 'h94     
`define DESC_2_AXUSER_14_REG_ADDR            `DESC_2_BASE_ADDR + 'h98     
`define DESC_2_AXUSER_15_REG_ADDR            `DESC_2_BASE_ADDR + 'h9C     
`define DESC_2_XUSER_0_REG_ADDR              `DESC_2_BASE_ADDR + 'hA0     
`define DESC_2_XUSER_1_REG_ADDR              `DESC_2_BASE_ADDR + 'hA4     
`define DESC_2_XUSER_2_REG_ADDR              `DESC_2_BASE_ADDR + 'hA8     
`define DESC_2_XUSER_3_REG_ADDR              `DESC_2_BASE_ADDR + 'hAC     
`define DESC_2_XUSER_4_REG_ADDR              `DESC_2_BASE_ADDR + 'hB0     
`define DESC_2_XUSER_5_REG_ADDR              `DESC_2_BASE_ADDR + 'hB4     
`define DESC_2_XUSER_6_REG_ADDR              `DESC_2_BASE_ADDR + 'hB8     
`define DESC_2_XUSER_7_REG_ADDR              `DESC_2_BASE_ADDR + 'hBC     
`define DESC_2_XUSER_8_REG_ADDR              `DESC_2_BASE_ADDR + 'hC0     
`define DESC_2_XUSER_9_REG_ADDR              `DESC_2_BASE_ADDR + 'hC4     
`define DESC_2_XUSER_10_REG_ADDR             `DESC_2_BASE_ADDR + 'hC8     
`define DESC_2_XUSER_11_REG_ADDR             `DESC_2_BASE_ADDR + 'hCC     
`define DESC_2_XUSER_12_REG_ADDR             `DESC_2_BASE_ADDR + 'hD0     
`define DESC_2_XUSER_13_REG_ADDR             `DESC_2_BASE_ADDR + 'hD4     
`define DESC_2_XUSER_14_REG_ADDR             `DESC_2_BASE_ADDR + 'hD8     
`define DESC_2_XUSER_15_REG_ADDR             `DESC_2_BASE_ADDR + 'hDC     
`define DESC_2_WUSER_0_REG_ADDR              `DESC_2_BASE_ADDR + 'hE0     
`define DESC_2_WUSER_1_REG_ADDR              `DESC_2_BASE_ADDR + 'hE4     
`define DESC_2_WUSER_2_REG_ADDR              `DESC_2_BASE_ADDR + 'hE8     
`define DESC_2_WUSER_3_REG_ADDR              `DESC_2_BASE_ADDR + 'hEC     
`define DESC_2_WUSER_4_REG_ADDR              `DESC_2_BASE_ADDR + 'hF0     
`define DESC_2_WUSER_5_REG_ADDR              `DESC_2_BASE_ADDR + 'hF4     
`define DESC_2_WUSER_6_REG_ADDR              `DESC_2_BASE_ADDR + 'hF8     
`define DESC_2_WUSER_7_REG_ADDR              `DESC_2_BASE_ADDR + 'hFC     
`define DESC_2_WUSER_8_REG_ADDR              `DESC_2_BASE_ADDR + 'h100    
`define DESC_2_WUSER_9_REG_ADDR              `DESC_2_BASE_ADDR + 'h104    
`define DESC_2_WUSER_10_REG_ADDR             `DESC_2_BASE_ADDR + 'h108    
`define DESC_2_WUSER_11_REG_ADDR             `DESC_2_BASE_ADDR + 'h10C    
`define DESC_2_WUSER_12_REG_ADDR             `DESC_2_BASE_ADDR + 'h110    
`define DESC_2_WUSER_13_REG_ADDR             `DESC_2_BASE_ADDR + 'h114    
`define DESC_2_WUSER_14_REG_ADDR             `DESC_2_BASE_ADDR + 'h118    
`define DESC_2_WUSER_15_REG_ADDR             `DESC_2_BASE_ADDR + 'h11C    

`define DESC_3_BASE_ADDR 'h3600
`define DESC_3_TXN_TYPE_REG_ADDR             `DESC_3_BASE_ADDR + 'h00     
`define DESC_3_SIZE_REG_ADDR                 `DESC_3_BASE_ADDR + 'h04     
`define DESC_3_DATA_OFFSET_REG_ADDR          `DESC_3_BASE_ADDR + 'h08     
`define DESC_3_DATA_HOST_ADDR_0_REG_ADDR     `DESC_3_BASE_ADDR + 'h10     
`define DESC_3_DATA_HOST_ADDR_1_REG_ADDR     `DESC_3_BASE_ADDR + 'h14     
`define DESC_3_DATA_HOST_ADDR_2_REG_ADDR     `DESC_3_BASE_ADDR + 'h18     
`define DESC_3_DATA_HOST_ADDR_3_REG_ADDR     `DESC_3_BASE_ADDR + 'h1C     
`define DESC_3_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_3_BASE_ADDR + 'h20     
`define DESC_3_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_3_BASE_ADDR + 'h24     
`define DESC_3_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_3_BASE_ADDR + 'h28     
`define DESC_3_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_3_BASE_ADDR + 'h2C     
`define DESC_3_AXSIZE_REG_ADDR               `DESC_3_BASE_ADDR + 'h30     
`define DESC_3_ATTR_REG_ADDR                 `DESC_3_BASE_ADDR + 'h34     
`define DESC_3_AXADDR_0_REG_ADDR             `DESC_3_BASE_ADDR + 'h40     
`define DESC_3_AXADDR_1_REG_ADDR             `DESC_3_BASE_ADDR + 'h44     
`define DESC_3_AXADDR_2_REG_ADDR             `DESC_3_BASE_ADDR + 'h48     
`define DESC_3_AXADDR_3_REG_ADDR             `DESC_3_BASE_ADDR + 'h4C     
`define DESC_3_AXID_0_REG_ADDR               `DESC_3_BASE_ADDR + 'h50     
`define DESC_3_AXID_1_REG_ADDR               `DESC_3_BASE_ADDR + 'h54     
`define DESC_3_AXID_2_REG_ADDR               `DESC_3_BASE_ADDR + 'h58     
`define DESC_3_AXID_3_REG_ADDR               `DESC_3_BASE_ADDR + 'h5C     
`define DESC_3_AXUSER_0_REG_ADDR             `DESC_3_BASE_ADDR + 'h60     
`define DESC_3_AXUSER_1_REG_ADDR             `DESC_3_BASE_ADDR + 'h64     
`define DESC_3_AXUSER_2_REG_ADDR             `DESC_3_BASE_ADDR + 'h68     
`define DESC_3_AXUSER_3_REG_ADDR             `DESC_3_BASE_ADDR + 'h6C     
`define DESC_3_AXUSER_4_REG_ADDR             `DESC_3_BASE_ADDR + 'h70     
`define DESC_3_AXUSER_5_REG_ADDR             `DESC_3_BASE_ADDR + 'h74     
`define DESC_3_AXUSER_6_REG_ADDR             `DESC_3_BASE_ADDR + 'h78     
`define DESC_3_AXUSER_7_REG_ADDR             `DESC_3_BASE_ADDR + 'h7C     
`define DESC_3_AXUSER_8_REG_ADDR             `DESC_3_BASE_ADDR + 'h80     
`define DESC_3_AXUSER_9_REG_ADDR             `DESC_3_BASE_ADDR + 'h84     
`define DESC_3_AXUSER_10_REG_ADDR            `DESC_3_BASE_ADDR + 'h88     
`define DESC_3_AXUSER_11_REG_ADDR            `DESC_3_BASE_ADDR + 'h8C     
`define DESC_3_AXUSER_12_REG_ADDR            `DESC_3_BASE_ADDR + 'h90     
`define DESC_3_AXUSER_13_REG_ADDR            `DESC_3_BASE_ADDR + 'h94     
`define DESC_3_AXUSER_14_REG_ADDR            `DESC_3_BASE_ADDR + 'h98     
`define DESC_3_AXUSER_15_REG_ADDR            `DESC_3_BASE_ADDR + 'h9C     
`define DESC_3_XUSER_0_REG_ADDR              `DESC_3_BASE_ADDR + 'hA0     
`define DESC_3_XUSER_1_REG_ADDR              `DESC_3_BASE_ADDR + 'hA4     
`define DESC_3_XUSER_2_REG_ADDR              `DESC_3_BASE_ADDR + 'hA8     
`define DESC_3_XUSER_3_REG_ADDR              `DESC_3_BASE_ADDR + 'hAC     
`define DESC_3_XUSER_4_REG_ADDR              `DESC_3_BASE_ADDR + 'hB0     
`define DESC_3_XUSER_5_REG_ADDR              `DESC_3_BASE_ADDR + 'hB4     
`define DESC_3_XUSER_6_REG_ADDR              `DESC_3_BASE_ADDR + 'hB8     
`define DESC_3_XUSER_7_REG_ADDR              `DESC_3_BASE_ADDR + 'hBC     
`define DESC_3_XUSER_8_REG_ADDR              `DESC_3_BASE_ADDR + 'hC0     
`define DESC_3_XUSER_9_REG_ADDR              `DESC_3_BASE_ADDR + 'hC4     
`define DESC_3_XUSER_10_REG_ADDR             `DESC_3_BASE_ADDR + 'hC8     
`define DESC_3_XUSER_11_REG_ADDR             `DESC_3_BASE_ADDR + 'hCC     
`define DESC_3_XUSER_12_REG_ADDR             `DESC_3_BASE_ADDR + 'hD0     
`define DESC_3_XUSER_13_REG_ADDR             `DESC_3_BASE_ADDR + 'hD4     
`define DESC_3_XUSER_14_REG_ADDR             `DESC_3_BASE_ADDR + 'hD8     
`define DESC_3_XUSER_15_REG_ADDR             `DESC_3_BASE_ADDR + 'hDC     
`define DESC_3_WUSER_0_REG_ADDR              `DESC_3_BASE_ADDR + 'hE0     
`define DESC_3_WUSER_1_REG_ADDR              `DESC_3_BASE_ADDR + 'hE4     
`define DESC_3_WUSER_2_REG_ADDR              `DESC_3_BASE_ADDR + 'hE8     
`define DESC_3_WUSER_3_REG_ADDR              `DESC_3_BASE_ADDR + 'hEC     
`define DESC_3_WUSER_4_REG_ADDR              `DESC_3_BASE_ADDR + 'hF0     
`define DESC_3_WUSER_5_REG_ADDR              `DESC_3_BASE_ADDR + 'hF4     
`define DESC_3_WUSER_6_REG_ADDR              `DESC_3_BASE_ADDR + 'hF8     
`define DESC_3_WUSER_7_REG_ADDR              `DESC_3_BASE_ADDR + 'hFC     
`define DESC_3_WUSER_8_REG_ADDR              `DESC_3_BASE_ADDR + 'h100    
`define DESC_3_WUSER_9_REG_ADDR              `DESC_3_BASE_ADDR + 'h104    
`define DESC_3_WUSER_10_REG_ADDR             `DESC_3_BASE_ADDR + 'h108    
`define DESC_3_WUSER_11_REG_ADDR             `DESC_3_BASE_ADDR + 'h10C    
`define DESC_3_WUSER_12_REG_ADDR             `DESC_3_BASE_ADDR + 'h110    
`define DESC_3_WUSER_13_REG_ADDR             `DESC_3_BASE_ADDR + 'h114    
`define DESC_3_WUSER_14_REG_ADDR             `DESC_3_BASE_ADDR + 'h118    
`define DESC_3_WUSER_15_REG_ADDR             `DESC_3_BASE_ADDR + 'h11C    
         
`define DESC_4_BASE_ADDR 'h3800
`define DESC_4_TXN_TYPE_REG_ADDR             `DESC_4_BASE_ADDR + 'h00     
`define DESC_4_SIZE_REG_ADDR                 `DESC_4_BASE_ADDR + 'h04     
`define DESC_4_DATA_OFFSET_REG_ADDR          `DESC_4_BASE_ADDR + 'h08     
`define DESC_4_DATA_HOST_ADDR_0_REG_ADDR     `DESC_4_BASE_ADDR + 'h10     
`define DESC_4_DATA_HOST_ADDR_1_REG_ADDR     `DESC_4_BASE_ADDR + 'h14     
`define DESC_4_DATA_HOST_ADDR_2_REG_ADDR     `DESC_4_BASE_ADDR + 'h18     
`define DESC_4_DATA_HOST_ADDR_3_REG_ADDR     `DESC_4_BASE_ADDR + 'h1C     
`define DESC_4_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_4_BASE_ADDR + 'h20     
`define DESC_4_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_4_BASE_ADDR + 'h24     
`define DESC_4_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_4_BASE_ADDR + 'h28     
`define DESC_4_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_4_BASE_ADDR + 'h2C     
`define DESC_4_AXSIZE_REG_ADDR               `DESC_4_BASE_ADDR + 'h30     
`define DESC_4_ATTR_REG_ADDR                 `DESC_4_BASE_ADDR + 'h34     
`define DESC_4_AXADDR_0_REG_ADDR             `DESC_4_BASE_ADDR + 'h40     
`define DESC_4_AXADDR_1_REG_ADDR             `DESC_4_BASE_ADDR + 'h44     
`define DESC_4_AXADDR_2_REG_ADDR             `DESC_4_BASE_ADDR + 'h48     
`define DESC_4_AXADDR_3_REG_ADDR             `DESC_4_BASE_ADDR + 'h4C     
`define DESC_4_AXID_0_REG_ADDR               `DESC_4_BASE_ADDR + 'h50     
`define DESC_4_AXID_1_REG_ADDR               `DESC_4_BASE_ADDR + 'h54     
`define DESC_4_AXID_2_REG_ADDR               `DESC_4_BASE_ADDR + 'h58     
`define DESC_4_AXID_3_REG_ADDR               `DESC_4_BASE_ADDR + 'h5C     
`define DESC_4_AXUSER_0_REG_ADDR             `DESC_4_BASE_ADDR + 'h60     
`define DESC_4_AXUSER_1_REG_ADDR             `DESC_4_BASE_ADDR + 'h64     
`define DESC_4_AXUSER_2_REG_ADDR             `DESC_4_BASE_ADDR + 'h68     
`define DESC_4_AXUSER_3_REG_ADDR             `DESC_4_BASE_ADDR + 'h6C     
`define DESC_4_AXUSER_4_REG_ADDR             `DESC_4_BASE_ADDR + 'h70     
`define DESC_4_AXUSER_5_REG_ADDR             `DESC_4_BASE_ADDR + 'h74     
`define DESC_4_AXUSER_6_REG_ADDR             `DESC_4_BASE_ADDR + 'h78     
`define DESC_4_AXUSER_7_REG_ADDR             `DESC_4_BASE_ADDR + 'h7C     
`define DESC_4_AXUSER_8_REG_ADDR             `DESC_4_BASE_ADDR + 'h80     
`define DESC_4_AXUSER_9_REG_ADDR             `DESC_4_BASE_ADDR + 'h84     
`define DESC_4_AXUSER_10_REG_ADDR            `DESC_4_BASE_ADDR + 'h88     
`define DESC_4_AXUSER_11_REG_ADDR            `DESC_4_BASE_ADDR + 'h8C     
`define DESC_4_AXUSER_12_REG_ADDR            `DESC_4_BASE_ADDR + 'h90     
`define DESC_4_AXUSER_13_REG_ADDR            `DESC_4_BASE_ADDR + 'h94     
`define DESC_4_AXUSER_14_REG_ADDR            `DESC_4_BASE_ADDR + 'h98     
`define DESC_4_AXUSER_15_REG_ADDR            `DESC_4_BASE_ADDR + 'h9C     
`define DESC_4_XUSER_0_REG_ADDR              `DESC_4_BASE_ADDR + 'hA0     
`define DESC_4_XUSER_1_REG_ADDR              `DESC_4_BASE_ADDR + 'hA4     
`define DESC_4_XUSER_2_REG_ADDR              `DESC_4_BASE_ADDR + 'hA8     
`define DESC_4_XUSER_3_REG_ADDR              `DESC_4_BASE_ADDR + 'hAC     
`define DESC_4_XUSER_4_REG_ADDR              `DESC_4_BASE_ADDR + 'hB0     
`define DESC_4_XUSER_5_REG_ADDR              `DESC_4_BASE_ADDR + 'hB4     
`define DESC_4_XUSER_6_REG_ADDR              `DESC_4_BASE_ADDR + 'hB8     
`define DESC_4_XUSER_7_REG_ADDR              `DESC_4_BASE_ADDR + 'hBC     
`define DESC_4_XUSER_8_REG_ADDR              `DESC_4_BASE_ADDR + 'hC0     
`define DESC_4_XUSER_9_REG_ADDR              `DESC_4_BASE_ADDR + 'hC4     
`define DESC_4_XUSER_10_REG_ADDR             `DESC_4_BASE_ADDR + 'hC8     
`define DESC_4_XUSER_11_REG_ADDR             `DESC_4_BASE_ADDR + 'hCC     
`define DESC_4_XUSER_12_REG_ADDR             `DESC_4_BASE_ADDR + 'hD0     
`define DESC_4_XUSER_13_REG_ADDR             `DESC_4_BASE_ADDR + 'hD4     
`define DESC_4_XUSER_14_REG_ADDR             `DESC_4_BASE_ADDR + 'hD8     
`define DESC_4_XUSER_15_REG_ADDR             `DESC_4_BASE_ADDR + 'hDC     
`define DESC_4_WUSER_0_REG_ADDR              `DESC_4_BASE_ADDR + 'hE0     
`define DESC_4_WUSER_1_REG_ADDR              `DESC_4_BASE_ADDR + 'hE4     
`define DESC_4_WUSER_2_REG_ADDR              `DESC_4_BASE_ADDR + 'hE8     
`define DESC_4_WUSER_3_REG_ADDR              `DESC_4_BASE_ADDR + 'hEC     
`define DESC_4_WUSER_4_REG_ADDR              `DESC_4_BASE_ADDR + 'hF0     
`define DESC_4_WUSER_5_REG_ADDR              `DESC_4_BASE_ADDR + 'hF4     
`define DESC_4_WUSER_6_REG_ADDR              `DESC_4_BASE_ADDR + 'hF8     
`define DESC_4_WUSER_7_REG_ADDR              `DESC_4_BASE_ADDR + 'hFC     
`define DESC_4_WUSER_8_REG_ADDR              `DESC_4_BASE_ADDR + 'h100    
`define DESC_4_WUSER_9_REG_ADDR              `DESC_4_BASE_ADDR + 'h104    
`define DESC_4_WUSER_10_REG_ADDR             `DESC_4_BASE_ADDR + 'h108    
`define DESC_4_WUSER_11_REG_ADDR             `DESC_4_BASE_ADDR + 'h10C    
`define DESC_4_WUSER_12_REG_ADDR             `DESC_4_BASE_ADDR + 'h110    
`define DESC_4_WUSER_13_REG_ADDR             `DESC_4_BASE_ADDR + 'h114    
`define DESC_4_WUSER_14_REG_ADDR             `DESC_4_BASE_ADDR + 'h118    
`define DESC_4_WUSER_15_REG_ADDR             `DESC_4_BASE_ADDR + 'h11C    

`define DESC_5_BASE_ADDR 'h3A00
`define DESC_5_TXN_TYPE_REG_ADDR             `DESC_5_BASE_ADDR + 'h00     
`define DESC_5_SIZE_REG_ADDR                 `DESC_5_BASE_ADDR + 'h04     
`define DESC_5_DATA_OFFSET_REG_ADDR          `DESC_5_BASE_ADDR + 'h08     
`define DESC_5_DATA_HOST_ADDR_0_REG_ADDR     `DESC_5_BASE_ADDR + 'h10     
`define DESC_5_DATA_HOST_ADDR_1_REG_ADDR     `DESC_5_BASE_ADDR + 'h14     
`define DESC_5_DATA_HOST_ADDR_2_REG_ADDR     `DESC_5_BASE_ADDR + 'h18     
`define DESC_5_DATA_HOST_ADDR_3_REG_ADDR     `DESC_5_BASE_ADDR + 'h1C     
`define DESC_5_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_5_BASE_ADDR + 'h20     
`define DESC_5_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_5_BASE_ADDR + 'h24     
`define DESC_5_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_5_BASE_ADDR + 'h28     
`define DESC_5_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_5_BASE_ADDR + 'h2C     
`define DESC_5_AXSIZE_REG_ADDR               `DESC_5_BASE_ADDR + 'h30     
`define DESC_5_ATTR_REG_ADDR                 `DESC_5_BASE_ADDR + 'h34     
`define DESC_5_AXADDR_0_REG_ADDR             `DESC_5_BASE_ADDR + 'h40     
`define DESC_5_AXADDR_1_REG_ADDR             `DESC_5_BASE_ADDR + 'h44     
`define DESC_5_AXADDR_2_REG_ADDR             `DESC_5_BASE_ADDR + 'h48     
`define DESC_5_AXADDR_3_REG_ADDR             `DESC_5_BASE_ADDR + 'h4C     
`define DESC_5_AXID_0_REG_ADDR               `DESC_5_BASE_ADDR + 'h50     
`define DESC_5_AXID_1_REG_ADDR               `DESC_5_BASE_ADDR + 'h54     
`define DESC_5_AXID_2_REG_ADDR               `DESC_5_BASE_ADDR + 'h58     
`define DESC_5_AXID_3_REG_ADDR               `DESC_5_BASE_ADDR + 'h5C     
`define DESC_5_AXUSER_0_REG_ADDR             `DESC_5_BASE_ADDR + 'h60     
`define DESC_5_AXUSER_1_REG_ADDR             `DESC_5_BASE_ADDR + 'h64     
`define DESC_5_AXUSER_2_REG_ADDR             `DESC_5_BASE_ADDR + 'h68     
`define DESC_5_AXUSER_3_REG_ADDR             `DESC_5_BASE_ADDR + 'h6C     
`define DESC_5_AXUSER_4_REG_ADDR             `DESC_5_BASE_ADDR + 'h70     
`define DESC_5_AXUSER_5_REG_ADDR             `DESC_5_BASE_ADDR + 'h74     
`define DESC_5_AXUSER_6_REG_ADDR             `DESC_5_BASE_ADDR + 'h78     
`define DESC_5_AXUSER_7_REG_ADDR             `DESC_5_BASE_ADDR + 'h7C     
`define DESC_5_AXUSER_8_REG_ADDR             `DESC_5_BASE_ADDR + 'h80     
`define DESC_5_AXUSER_9_REG_ADDR             `DESC_5_BASE_ADDR + 'h84     
`define DESC_5_AXUSER_10_REG_ADDR            `DESC_5_BASE_ADDR + 'h88     
`define DESC_5_AXUSER_11_REG_ADDR            `DESC_5_BASE_ADDR + 'h8C     
`define DESC_5_AXUSER_12_REG_ADDR            `DESC_5_BASE_ADDR + 'h90     
`define DESC_5_AXUSER_13_REG_ADDR            `DESC_5_BASE_ADDR + 'h94     
`define DESC_5_AXUSER_14_REG_ADDR            `DESC_5_BASE_ADDR + 'h98     
`define DESC_5_AXUSER_15_REG_ADDR            `DESC_5_BASE_ADDR + 'h9C     
`define DESC_5_XUSER_0_REG_ADDR              `DESC_5_BASE_ADDR + 'hA0     
`define DESC_5_XUSER_1_REG_ADDR              `DESC_5_BASE_ADDR + 'hA4     
`define DESC_5_XUSER_2_REG_ADDR              `DESC_5_BASE_ADDR + 'hA8     
`define DESC_5_XUSER_3_REG_ADDR              `DESC_5_BASE_ADDR + 'hAC     
`define DESC_5_XUSER_4_REG_ADDR              `DESC_5_BASE_ADDR + 'hB0     
`define DESC_5_XUSER_5_REG_ADDR              `DESC_5_BASE_ADDR + 'hB4     
`define DESC_5_XUSER_6_REG_ADDR              `DESC_5_BASE_ADDR + 'hB8     
`define DESC_5_XUSER_7_REG_ADDR              `DESC_5_BASE_ADDR + 'hBC     
`define DESC_5_XUSER_8_REG_ADDR              `DESC_5_BASE_ADDR + 'hC0     
`define DESC_5_XUSER_9_REG_ADDR              `DESC_5_BASE_ADDR + 'hC4     
`define DESC_5_XUSER_10_REG_ADDR             `DESC_5_BASE_ADDR + 'hC8     
`define DESC_5_XUSER_11_REG_ADDR             `DESC_5_BASE_ADDR + 'hCC     
`define DESC_5_XUSER_12_REG_ADDR             `DESC_5_BASE_ADDR + 'hD0     
`define DESC_5_XUSER_13_REG_ADDR             `DESC_5_BASE_ADDR + 'hD4     
`define DESC_5_XUSER_14_REG_ADDR             `DESC_5_BASE_ADDR + 'hD8     
`define DESC_5_XUSER_15_REG_ADDR             `DESC_5_BASE_ADDR + 'hDC     
`define DESC_5_WUSER_0_REG_ADDR              `DESC_5_BASE_ADDR + 'hE0     
`define DESC_5_WUSER_1_REG_ADDR              `DESC_5_BASE_ADDR + 'hE4     
`define DESC_5_WUSER_2_REG_ADDR              `DESC_5_BASE_ADDR + 'hE8     
`define DESC_5_WUSER_3_REG_ADDR              `DESC_5_BASE_ADDR + 'hEC     
`define DESC_5_WUSER_4_REG_ADDR              `DESC_5_BASE_ADDR + 'hF0     
`define DESC_5_WUSER_5_REG_ADDR              `DESC_5_BASE_ADDR + 'hF4     
`define DESC_5_WUSER_6_REG_ADDR              `DESC_5_BASE_ADDR + 'hF8     
`define DESC_5_WUSER_7_REG_ADDR              `DESC_5_BASE_ADDR + 'hFC     
`define DESC_5_WUSER_8_REG_ADDR              `DESC_5_BASE_ADDR + 'h100    
`define DESC_5_WUSER_9_REG_ADDR              `DESC_5_BASE_ADDR + 'h104    
`define DESC_5_WUSER_10_REG_ADDR             `DESC_5_BASE_ADDR + 'h108    
`define DESC_5_WUSER_11_REG_ADDR             `DESC_5_BASE_ADDR + 'h10C    
`define DESC_5_WUSER_12_REG_ADDR             `DESC_5_BASE_ADDR + 'h110    
`define DESC_5_WUSER_13_REG_ADDR             `DESC_5_BASE_ADDR + 'h114    
`define DESC_5_WUSER_14_REG_ADDR             `DESC_5_BASE_ADDR + 'h118    
`define DESC_5_WUSER_15_REG_ADDR             `DESC_5_BASE_ADDR + 'h11C    

`define DESC_6_BASE_ADDR 'h3C00
`define DESC_6_TXN_TYPE_REG_ADDR             `DESC_6_BASE_ADDR + 'h00     
`define DESC_6_SIZE_REG_ADDR                 `DESC_6_BASE_ADDR + 'h04     
`define DESC_6_DATA_OFFSET_REG_ADDR          `DESC_6_BASE_ADDR + 'h08     
`define DESC_6_DATA_HOST_ADDR_0_REG_ADDR     `DESC_6_BASE_ADDR + 'h10     
`define DESC_6_DATA_HOST_ADDR_1_REG_ADDR     `DESC_6_BASE_ADDR + 'h14     
`define DESC_6_DATA_HOST_ADDR_2_REG_ADDR     `DESC_6_BASE_ADDR + 'h18     
`define DESC_6_DATA_HOST_ADDR_3_REG_ADDR     `DESC_6_BASE_ADDR + 'h1C     
`define DESC_6_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_6_BASE_ADDR + 'h20     
`define DESC_6_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_6_BASE_ADDR + 'h24     
`define DESC_6_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_6_BASE_ADDR + 'h28     
`define DESC_6_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_6_BASE_ADDR + 'h2C     
`define DESC_6_AXSIZE_REG_ADDR               `DESC_6_BASE_ADDR + 'h30     
`define DESC_6_ATTR_REG_ADDR                 `DESC_6_BASE_ADDR + 'h34     
`define DESC_6_AXADDR_0_REG_ADDR             `DESC_6_BASE_ADDR + 'h40     
`define DESC_6_AXADDR_1_REG_ADDR             `DESC_6_BASE_ADDR + 'h44     
`define DESC_6_AXADDR_2_REG_ADDR             `DESC_6_BASE_ADDR + 'h48     
`define DESC_6_AXADDR_3_REG_ADDR             `DESC_6_BASE_ADDR + 'h4C     
`define DESC_6_AXID_0_REG_ADDR               `DESC_6_BASE_ADDR + 'h50     
`define DESC_6_AXID_1_REG_ADDR               `DESC_6_BASE_ADDR + 'h54     
`define DESC_6_AXID_2_REG_ADDR               `DESC_6_BASE_ADDR + 'h58     
`define DESC_6_AXID_3_REG_ADDR               `DESC_6_BASE_ADDR + 'h5C     
`define DESC_6_AXUSER_0_REG_ADDR             `DESC_6_BASE_ADDR + 'h60     
`define DESC_6_AXUSER_1_REG_ADDR             `DESC_6_BASE_ADDR + 'h64     
`define DESC_6_AXUSER_2_REG_ADDR             `DESC_6_BASE_ADDR + 'h68     
`define DESC_6_AXUSER_3_REG_ADDR             `DESC_6_BASE_ADDR + 'h6C     
`define DESC_6_AXUSER_4_REG_ADDR             `DESC_6_BASE_ADDR + 'h70     
`define DESC_6_AXUSER_5_REG_ADDR             `DESC_6_BASE_ADDR + 'h74     
`define DESC_6_AXUSER_6_REG_ADDR             `DESC_6_BASE_ADDR + 'h78     
`define DESC_6_AXUSER_7_REG_ADDR             `DESC_6_BASE_ADDR + 'h7C     
`define DESC_6_AXUSER_8_REG_ADDR             `DESC_6_BASE_ADDR + 'h80     
`define DESC_6_AXUSER_9_REG_ADDR             `DESC_6_BASE_ADDR + 'h84     
`define DESC_6_AXUSER_10_REG_ADDR            `DESC_6_BASE_ADDR + 'h88     
`define DESC_6_AXUSER_11_REG_ADDR            `DESC_6_BASE_ADDR + 'h8C     
`define DESC_6_AXUSER_12_REG_ADDR            `DESC_6_BASE_ADDR + 'h90     
`define DESC_6_AXUSER_13_REG_ADDR            `DESC_6_BASE_ADDR + 'h94     
`define DESC_6_AXUSER_14_REG_ADDR            `DESC_6_BASE_ADDR + 'h98     
`define DESC_6_AXUSER_15_REG_ADDR            `DESC_6_BASE_ADDR + 'h9C     
`define DESC_6_XUSER_0_REG_ADDR              `DESC_6_BASE_ADDR + 'hA0     
`define DESC_6_XUSER_1_REG_ADDR              `DESC_6_BASE_ADDR + 'hA4     
`define DESC_6_XUSER_2_REG_ADDR              `DESC_6_BASE_ADDR + 'hA8     
`define DESC_6_XUSER_3_REG_ADDR              `DESC_6_BASE_ADDR + 'hAC     
`define DESC_6_XUSER_4_REG_ADDR              `DESC_6_BASE_ADDR + 'hB0     
`define DESC_6_XUSER_5_REG_ADDR              `DESC_6_BASE_ADDR + 'hB4     
`define DESC_6_XUSER_6_REG_ADDR              `DESC_6_BASE_ADDR + 'hB8     
`define DESC_6_XUSER_7_REG_ADDR              `DESC_6_BASE_ADDR + 'hBC     
`define DESC_6_XUSER_8_REG_ADDR              `DESC_6_BASE_ADDR + 'hC0     
`define DESC_6_XUSER_9_REG_ADDR              `DESC_6_BASE_ADDR + 'hC4     
`define DESC_6_XUSER_10_REG_ADDR             `DESC_6_BASE_ADDR + 'hC8     
`define DESC_6_XUSER_11_REG_ADDR             `DESC_6_BASE_ADDR + 'hCC     
`define DESC_6_XUSER_12_REG_ADDR             `DESC_6_BASE_ADDR + 'hD0     
`define DESC_6_XUSER_13_REG_ADDR             `DESC_6_BASE_ADDR + 'hD4     
`define DESC_6_XUSER_14_REG_ADDR             `DESC_6_BASE_ADDR + 'hD8     
`define DESC_6_XUSER_15_REG_ADDR             `DESC_6_BASE_ADDR + 'hDC     
`define DESC_6_WUSER_0_REG_ADDR              `DESC_6_BASE_ADDR + 'hE0     
`define DESC_6_WUSER_1_REG_ADDR              `DESC_6_BASE_ADDR + 'hE4     
`define DESC_6_WUSER_2_REG_ADDR              `DESC_6_BASE_ADDR + 'hE8     
`define DESC_6_WUSER_3_REG_ADDR              `DESC_6_BASE_ADDR + 'hEC     
`define DESC_6_WUSER_4_REG_ADDR              `DESC_6_BASE_ADDR + 'hF0     
`define DESC_6_WUSER_5_REG_ADDR              `DESC_6_BASE_ADDR + 'hF4     
`define DESC_6_WUSER_6_REG_ADDR              `DESC_6_BASE_ADDR + 'hF8     
`define DESC_6_WUSER_7_REG_ADDR              `DESC_6_BASE_ADDR + 'hFC     
`define DESC_6_WUSER_8_REG_ADDR              `DESC_6_BASE_ADDR + 'h100    
`define DESC_6_WUSER_9_REG_ADDR              `DESC_6_BASE_ADDR + 'h104    
`define DESC_6_WUSER_10_REG_ADDR             `DESC_6_BASE_ADDR + 'h108    
`define DESC_6_WUSER_11_REG_ADDR             `DESC_6_BASE_ADDR + 'h10C    
`define DESC_6_WUSER_12_REG_ADDR             `DESC_6_BASE_ADDR + 'h110    
`define DESC_6_WUSER_13_REG_ADDR             `DESC_6_BASE_ADDR + 'h114    
`define DESC_6_WUSER_14_REG_ADDR             `DESC_6_BASE_ADDR + 'h118    
`define DESC_6_WUSER_15_REG_ADDR             `DESC_6_BASE_ADDR + 'h11C    

`define DESC_7_BASE_ADDR 'h3E00
`define DESC_7_TXN_TYPE_REG_ADDR             `DESC_7_BASE_ADDR + 'h00     
`define DESC_7_SIZE_REG_ADDR                 `DESC_7_BASE_ADDR + 'h04      
`define DESC_7_DATA_OFFSET_REG_ADDR          `DESC_7_BASE_ADDR + 'h08      
`define DESC_7_DATA_HOST_ADDR_0_REG_ADDR     `DESC_7_BASE_ADDR + 'h10      
`define DESC_7_DATA_HOST_ADDR_1_REG_ADDR     `DESC_7_BASE_ADDR + 'h14      
`define DESC_7_DATA_HOST_ADDR_2_REG_ADDR     `DESC_7_BASE_ADDR + 'h18      
`define DESC_7_DATA_HOST_ADDR_3_REG_ADDR     `DESC_7_BASE_ADDR + 'h1C      
`define DESC_7_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_7_BASE_ADDR + 'h20      
`define DESC_7_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_7_BASE_ADDR + 'h24      
`define DESC_7_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_7_BASE_ADDR + 'h28      
`define DESC_7_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_7_BASE_ADDR + 'h2C      
`define DESC_7_AXSIZE_REG_ADDR               `DESC_7_BASE_ADDR + 'h30      
`define DESC_7_ATTR_REG_ADDR                 `DESC_7_BASE_ADDR + 'h34      
`define DESC_7_AXADDR_0_REG_ADDR             `DESC_7_BASE_ADDR + 'h40      
`define DESC_7_AXADDR_1_REG_ADDR             `DESC_7_BASE_ADDR + 'h44      
`define DESC_7_AXADDR_2_REG_ADDR             `DESC_7_BASE_ADDR + 'h48      
`define DESC_7_AXADDR_3_REG_ADDR             `DESC_7_BASE_ADDR + 'h4C      
`define DESC_7_AXID_0_REG_ADDR               `DESC_7_BASE_ADDR + 'h50      
`define DESC_7_AXID_1_REG_ADDR               `DESC_7_BASE_ADDR + 'h54      
`define DESC_7_AXID_2_REG_ADDR               `DESC_7_BASE_ADDR + 'h58      
`define DESC_7_AXID_3_REG_ADDR               `DESC_7_BASE_ADDR + 'h5C      
`define DESC_7_AXUSER_0_REG_ADDR             `DESC_7_BASE_ADDR + 'h60      
`define DESC_7_AXUSER_1_REG_ADDR             `DESC_7_BASE_ADDR + 'h64      
`define DESC_7_AXUSER_2_REG_ADDR             `DESC_7_BASE_ADDR + 'h68      
`define DESC_7_AXUSER_3_REG_ADDR             `DESC_7_BASE_ADDR + 'h6C      
`define DESC_7_AXUSER_4_REG_ADDR             `DESC_7_BASE_ADDR + 'h70      
`define DESC_7_AXUSER_5_REG_ADDR             `DESC_7_BASE_ADDR + 'h74      
`define DESC_7_AXUSER_6_REG_ADDR             `DESC_7_BASE_ADDR + 'h78      
`define DESC_7_AXUSER_7_REG_ADDR             `DESC_7_BASE_ADDR + 'h7C      
`define DESC_7_AXUSER_8_REG_ADDR             `DESC_7_BASE_ADDR + 'h80      
`define DESC_7_AXUSER_9_REG_ADDR             `DESC_7_BASE_ADDR + 'h84      
`define DESC_7_AXUSER_10_REG_ADDR            `DESC_7_BASE_ADDR + 'h88      
`define DESC_7_AXUSER_11_REG_ADDR            `DESC_7_BASE_ADDR + 'h8C      
`define DESC_7_AXUSER_12_REG_ADDR            `DESC_7_BASE_ADDR + 'h90      
`define DESC_7_AXUSER_13_REG_ADDR            `DESC_7_BASE_ADDR + 'h94      
`define DESC_7_AXUSER_14_REG_ADDR            `DESC_7_BASE_ADDR + 'h98      
`define DESC_7_AXUSER_15_REG_ADDR            `DESC_7_BASE_ADDR + 'h9C      
`define DESC_7_XUSER_0_REG_ADDR              `DESC_7_BASE_ADDR + 'hA0      
`define DESC_7_XUSER_1_REG_ADDR              `DESC_7_BASE_ADDR + 'hA4      
`define DESC_7_XUSER_2_REG_ADDR              `DESC_7_BASE_ADDR + 'hA8      
`define DESC_7_XUSER_3_REG_ADDR              `DESC_7_BASE_ADDR + 'hAC      
`define DESC_7_XUSER_4_REG_ADDR              `DESC_7_BASE_ADDR + 'hB0      
`define DESC_7_XUSER_5_REG_ADDR              `DESC_7_BASE_ADDR + 'hB4      
`define DESC_7_XUSER_6_REG_ADDR              `DESC_7_BASE_ADDR + 'hB8      
`define DESC_7_XUSER_7_REG_ADDR              `DESC_7_BASE_ADDR + 'hBC      
`define DESC_7_XUSER_8_REG_ADDR              `DESC_7_BASE_ADDR + 'hC0      
`define DESC_7_XUSER_9_REG_ADDR              `DESC_7_BASE_ADDR + 'hC4      
`define DESC_7_XUSER_10_REG_ADDR             `DESC_7_BASE_ADDR + 'hC8      
`define DESC_7_XUSER_11_REG_ADDR             `DESC_7_BASE_ADDR + 'hCC      
`define DESC_7_XUSER_12_REG_ADDR             `DESC_7_BASE_ADDR + 'hD0      
`define DESC_7_XUSER_13_REG_ADDR             `DESC_7_BASE_ADDR + 'hD4      
`define DESC_7_XUSER_14_REG_ADDR             `DESC_7_BASE_ADDR + 'hD8      
`define DESC_7_XUSER_15_REG_ADDR             `DESC_7_BASE_ADDR + 'hDC      
`define DESC_7_WUSER_0_REG_ADDR              `DESC_7_BASE_ADDR + 'hE0      
`define DESC_7_WUSER_1_REG_ADDR              `DESC_7_BASE_ADDR + 'hE4      
`define DESC_7_WUSER_2_REG_ADDR              `DESC_7_BASE_ADDR + 'hE8      
`define DESC_7_WUSER_3_REG_ADDR              `DESC_7_BASE_ADDR + 'hEC      
`define DESC_7_WUSER_4_REG_ADDR              `DESC_7_BASE_ADDR + 'hF0      
`define DESC_7_WUSER_5_REG_ADDR              `DESC_7_BASE_ADDR + 'hF4      
`define DESC_7_WUSER_6_REG_ADDR              `DESC_7_BASE_ADDR + 'hF8      
`define DESC_7_WUSER_7_REG_ADDR              `DESC_7_BASE_ADDR + 'hFC      
`define DESC_7_WUSER_8_REG_ADDR              `DESC_7_BASE_ADDR + 'h100     
`define DESC_7_WUSER_9_REG_ADDR              `DESC_7_BASE_ADDR + 'h104     
`define DESC_7_WUSER_10_REG_ADDR             `DESC_7_BASE_ADDR + 'h108     
`define DESC_7_WUSER_11_REG_ADDR             `DESC_7_BASE_ADDR + 'h10C     
`define DESC_7_WUSER_12_REG_ADDR             `DESC_7_BASE_ADDR + 'h110     
`define DESC_7_WUSER_13_REG_ADDR             `DESC_7_BASE_ADDR + 'h114     
`define DESC_7_WUSER_14_REG_ADDR             `DESC_7_BASE_ADDR + 'h118     
`define DESC_7_WUSER_15_REG_ADDR             `DESC_7_BASE_ADDR + 'h11C     

`define DESC_8_BASE_ADDR 'h4000
`define DESC_8_TXN_TYPE_REG_ADDR             `DESC_8_BASE_ADDR + 'h00     
`define DESC_8_SIZE_REG_ADDR                 `DESC_8_BASE_ADDR + 'h04     
`define DESC_8_DATA_OFFSET_REG_ADDR          `DESC_8_BASE_ADDR + 'h08     
`define DESC_8_DATA_HOST_ADDR_0_REG_ADDR     `DESC_8_BASE_ADDR + 'h10     
`define DESC_8_DATA_HOST_ADDR_1_REG_ADDR     `DESC_8_BASE_ADDR + 'h14     
`define DESC_8_DATA_HOST_ADDR_2_REG_ADDR     `DESC_8_BASE_ADDR + 'h18     
`define DESC_8_DATA_HOST_ADDR_3_REG_ADDR     `DESC_8_BASE_ADDR + 'h1C     
`define DESC_8_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_8_BASE_ADDR + 'h20     
`define DESC_8_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_8_BASE_ADDR + 'h24     
`define DESC_8_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_8_BASE_ADDR + 'h28     
`define DESC_8_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_8_BASE_ADDR + 'h2C     
`define DESC_8_AXSIZE_REG_ADDR               `DESC_8_BASE_ADDR + 'h30     
`define DESC_8_ATTR_REG_ADDR                 `DESC_8_BASE_ADDR + 'h34     
`define DESC_8_AXADDR_0_REG_ADDR             `DESC_8_BASE_ADDR + 'h40     
`define DESC_8_AXADDR_1_REG_ADDR             `DESC_8_BASE_ADDR + 'h44     
`define DESC_8_AXADDR_2_REG_ADDR             `DESC_8_BASE_ADDR + 'h48     
`define DESC_8_AXADDR_3_REG_ADDR             `DESC_8_BASE_ADDR + 'h4C     
`define DESC_8_AXID_0_REG_ADDR               `DESC_8_BASE_ADDR + 'h50     
`define DESC_8_AXID_1_REG_ADDR               `DESC_8_BASE_ADDR + 'h54     
`define DESC_8_AXID_2_REG_ADDR               `DESC_8_BASE_ADDR + 'h58     
`define DESC_8_AXID_3_REG_ADDR               `DESC_8_BASE_ADDR + 'h5C     
`define DESC_8_AXUSER_0_REG_ADDR             `DESC_8_BASE_ADDR + 'h60     
`define DESC_8_AXUSER_1_REG_ADDR             `DESC_8_BASE_ADDR + 'h64     
`define DESC_8_AXUSER_2_REG_ADDR             `DESC_8_BASE_ADDR + 'h68     
`define DESC_8_AXUSER_3_REG_ADDR             `DESC_8_BASE_ADDR + 'h6C     
`define DESC_8_AXUSER_4_REG_ADDR             `DESC_8_BASE_ADDR + 'h70     
`define DESC_8_AXUSER_5_REG_ADDR             `DESC_8_BASE_ADDR + 'h74     
`define DESC_8_AXUSER_6_REG_ADDR             `DESC_8_BASE_ADDR + 'h78     
`define DESC_8_AXUSER_7_REG_ADDR             `DESC_8_BASE_ADDR + 'h7C     
`define DESC_8_AXUSER_8_REG_ADDR             `DESC_8_BASE_ADDR + 'h80     
`define DESC_8_AXUSER_9_REG_ADDR             `DESC_8_BASE_ADDR + 'h84     
`define DESC_8_AXUSER_10_REG_ADDR            `DESC_8_BASE_ADDR + 'h88     
`define DESC_8_AXUSER_11_REG_ADDR            `DESC_8_BASE_ADDR + 'h8C     
`define DESC_8_AXUSER_12_REG_ADDR            `DESC_8_BASE_ADDR + 'h90     
`define DESC_8_AXUSER_13_REG_ADDR            `DESC_8_BASE_ADDR + 'h94     
`define DESC_8_AXUSER_14_REG_ADDR            `DESC_8_BASE_ADDR + 'h98     
`define DESC_8_AXUSER_15_REG_ADDR            `DESC_8_BASE_ADDR + 'h9C     
`define DESC_8_XUSER_0_REG_ADDR              `DESC_8_BASE_ADDR + 'hA0     
`define DESC_8_XUSER_1_REG_ADDR              `DESC_8_BASE_ADDR + 'hA4     
`define DESC_8_XUSER_2_REG_ADDR              `DESC_8_BASE_ADDR + 'hA8     
`define DESC_8_XUSER_3_REG_ADDR              `DESC_8_BASE_ADDR + 'hAC     
`define DESC_8_XUSER_4_REG_ADDR              `DESC_8_BASE_ADDR + 'hB0     
`define DESC_8_XUSER_5_REG_ADDR              `DESC_8_BASE_ADDR + 'hB4     
`define DESC_8_XUSER_6_REG_ADDR              `DESC_8_BASE_ADDR + 'hB8     
`define DESC_8_XUSER_7_REG_ADDR              `DESC_8_BASE_ADDR + 'hBC     
`define DESC_8_XUSER_8_REG_ADDR              `DESC_8_BASE_ADDR + 'hC0     
`define DESC_8_XUSER_9_REG_ADDR              `DESC_8_BASE_ADDR + 'hC4     
`define DESC_8_XUSER_10_REG_ADDR             `DESC_8_BASE_ADDR + 'hC8     
`define DESC_8_XUSER_11_REG_ADDR             `DESC_8_BASE_ADDR + 'hCC     
`define DESC_8_XUSER_12_REG_ADDR             `DESC_8_BASE_ADDR + 'hD0     
`define DESC_8_XUSER_13_REG_ADDR             `DESC_8_BASE_ADDR + 'hD4     
`define DESC_8_XUSER_14_REG_ADDR             `DESC_8_BASE_ADDR + 'hD8     
`define DESC_8_XUSER_15_REG_ADDR             `DESC_8_BASE_ADDR + 'hDC     
`define DESC_8_WUSER_0_REG_ADDR              `DESC_8_BASE_ADDR + 'hE0     
`define DESC_8_WUSER_1_REG_ADDR              `DESC_8_BASE_ADDR + 'hE4     
`define DESC_8_WUSER_2_REG_ADDR              `DESC_8_BASE_ADDR + 'hE8     
`define DESC_8_WUSER_3_REG_ADDR              `DESC_8_BASE_ADDR + 'hEC     
`define DESC_8_WUSER_4_REG_ADDR              `DESC_8_BASE_ADDR + 'hF0     
`define DESC_8_WUSER_5_REG_ADDR              `DESC_8_BASE_ADDR + 'hF4     
`define DESC_8_WUSER_6_REG_ADDR              `DESC_8_BASE_ADDR + 'hF8     
`define DESC_8_WUSER_7_REG_ADDR              `DESC_8_BASE_ADDR + 'hFC     
`define DESC_8_WUSER_8_REG_ADDR              `DESC_8_BASE_ADDR + 'h100    
`define DESC_8_WUSER_9_REG_ADDR              `DESC_8_BASE_ADDR + 'h104    
`define DESC_8_WUSER_10_REG_ADDR             `DESC_8_BASE_ADDR + 'h108    
`define DESC_8_WUSER_11_REG_ADDR             `DESC_8_BASE_ADDR + 'h10C    
`define DESC_8_WUSER_12_REG_ADDR             `DESC_8_BASE_ADDR + 'h110    
`define DESC_8_WUSER_13_REG_ADDR             `DESC_8_BASE_ADDR + 'h114    
`define DESC_8_WUSER_14_REG_ADDR             `DESC_8_BASE_ADDR + 'h118    
`define DESC_8_WUSER_15_REG_ADDR             `DESC_8_BASE_ADDR + 'h11C    

`define DESC_9_BASE_ADDR 'h4200
`define DESC_9_TXN_TYPE_REG_ADDR             `DESC_9_BASE_ADDR + 'h00     
`define DESC_9_SIZE_REG_ADDR                 `DESC_9_BASE_ADDR + 'h04     
`define DESC_9_DATA_OFFSET_REG_ADDR          `DESC_9_BASE_ADDR + 'h08     
`define DESC_9_DATA_HOST_ADDR_0_REG_ADDR     `DESC_9_BASE_ADDR + 'h10     
`define DESC_9_DATA_HOST_ADDR_1_REG_ADDR     `DESC_9_BASE_ADDR + 'h14     
`define DESC_9_DATA_HOST_ADDR_2_REG_ADDR     `DESC_9_BASE_ADDR + 'h18     
`define DESC_9_DATA_HOST_ADDR_3_REG_ADDR     `DESC_9_BASE_ADDR + 'h1C     
`define DESC_9_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_9_BASE_ADDR + 'h20     
`define DESC_9_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_9_BASE_ADDR + 'h24     
`define DESC_9_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_9_BASE_ADDR + 'h28     
`define DESC_9_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_9_BASE_ADDR + 'h2C     
`define DESC_9_AXSIZE_REG_ADDR               `DESC_9_BASE_ADDR + 'h30     
`define DESC_9_ATTR_REG_ADDR                 `DESC_9_BASE_ADDR + 'h34     
`define DESC_9_AXADDR_0_REG_ADDR             `DESC_9_BASE_ADDR + 'h40     
`define DESC_9_AXADDR_1_REG_ADDR             `DESC_9_BASE_ADDR + 'h44     
`define DESC_9_AXADDR_2_REG_ADDR             `DESC_9_BASE_ADDR + 'h48     
`define DESC_9_AXADDR_3_REG_ADDR             `DESC_9_BASE_ADDR + 'h4C     
`define DESC_9_AXID_0_REG_ADDR               `DESC_9_BASE_ADDR + 'h50     
`define DESC_9_AXID_1_REG_ADDR               `DESC_9_BASE_ADDR + 'h54     
`define DESC_9_AXID_2_REG_ADDR               `DESC_9_BASE_ADDR + 'h58     
`define DESC_9_AXID_3_REG_ADDR               `DESC_9_BASE_ADDR + 'h5C     
`define DESC_9_AXUSER_0_REG_ADDR             `DESC_9_BASE_ADDR + 'h60     
`define DESC_9_AXUSER_1_REG_ADDR             `DESC_9_BASE_ADDR + 'h64     
`define DESC_9_AXUSER_2_REG_ADDR             `DESC_9_BASE_ADDR + 'h68     
`define DESC_9_AXUSER_3_REG_ADDR             `DESC_9_BASE_ADDR + 'h6C     
`define DESC_9_AXUSER_4_REG_ADDR             `DESC_9_BASE_ADDR + 'h70     
`define DESC_9_AXUSER_5_REG_ADDR             `DESC_9_BASE_ADDR + 'h74     
`define DESC_9_AXUSER_6_REG_ADDR             `DESC_9_BASE_ADDR + 'h78     
`define DESC_9_AXUSER_7_REG_ADDR             `DESC_9_BASE_ADDR + 'h7C     
`define DESC_9_AXUSER_8_REG_ADDR             `DESC_9_BASE_ADDR + 'h80     
`define DESC_9_AXUSER_9_REG_ADDR             `DESC_9_BASE_ADDR + 'h84     
`define DESC_9_AXUSER_10_REG_ADDR            `DESC_9_BASE_ADDR + 'h88     
`define DESC_9_AXUSER_11_REG_ADDR            `DESC_9_BASE_ADDR + 'h8C     
`define DESC_9_AXUSER_12_REG_ADDR            `DESC_9_BASE_ADDR + 'h90     
`define DESC_9_AXUSER_13_REG_ADDR            `DESC_9_BASE_ADDR + 'h94     
`define DESC_9_AXUSER_14_REG_ADDR            `DESC_9_BASE_ADDR + 'h98     
`define DESC_9_AXUSER_15_REG_ADDR            `DESC_9_BASE_ADDR + 'h9C     
`define DESC_9_XUSER_0_REG_ADDR              `DESC_9_BASE_ADDR + 'hA0     
`define DESC_9_XUSER_1_REG_ADDR              `DESC_9_BASE_ADDR + 'hA4     
`define DESC_9_XUSER_2_REG_ADDR              `DESC_9_BASE_ADDR + 'hA8     
`define DESC_9_XUSER_3_REG_ADDR              `DESC_9_BASE_ADDR + 'hAC     
`define DESC_9_XUSER_4_REG_ADDR              `DESC_9_BASE_ADDR + 'hB0     
`define DESC_9_XUSER_5_REG_ADDR              `DESC_9_BASE_ADDR + 'hB4     
`define DESC_9_XUSER_6_REG_ADDR              `DESC_9_BASE_ADDR + 'hB8     
`define DESC_9_XUSER_7_REG_ADDR              `DESC_9_BASE_ADDR + 'hBC     
`define DESC_9_XUSER_8_REG_ADDR              `DESC_9_BASE_ADDR + 'hC0     
`define DESC_9_XUSER_9_REG_ADDR              `DESC_9_BASE_ADDR + 'hC4     
`define DESC_9_XUSER_10_REG_ADDR             `DESC_9_BASE_ADDR + 'hC8     
`define DESC_9_XUSER_11_REG_ADDR             `DESC_9_BASE_ADDR + 'hCC     
`define DESC_9_XUSER_12_REG_ADDR             `DESC_9_BASE_ADDR + 'hD0     
`define DESC_9_XUSER_13_REG_ADDR             `DESC_9_BASE_ADDR + 'hD4     
`define DESC_9_XUSER_14_REG_ADDR             `DESC_9_BASE_ADDR + 'hD8     
`define DESC_9_XUSER_15_REG_ADDR             `DESC_9_BASE_ADDR + 'hDC     
`define DESC_9_WUSER_0_REG_ADDR              `DESC_9_BASE_ADDR + 'hE0     
`define DESC_9_WUSER_1_REG_ADDR              `DESC_9_BASE_ADDR + 'hE4     
`define DESC_9_WUSER_2_REG_ADDR              `DESC_9_BASE_ADDR + 'hE8     
`define DESC_9_WUSER_3_REG_ADDR              `DESC_9_BASE_ADDR + 'hEC     
`define DESC_9_WUSER_4_REG_ADDR              `DESC_9_BASE_ADDR + 'hF0     
`define DESC_9_WUSER_5_REG_ADDR              `DESC_9_BASE_ADDR + 'hF4     
`define DESC_9_WUSER_6_REG_ADDR              `DESC_9_BASE_ADDR + 'hF8     
`define DESC_9_WUSER_7_REG_ADDR              `DESC_9_BASE_ADDR + 'hFC     
`define DESC_9_WUSER_8_REG_ADDR              `DESC_9_BASE_ADDR + 'h100    
`define DESC_9_WUSER_9_REG_ADDR              `DESC_9_BASE_ADDR + 'h104    
`define DESC_9_WUSER_10_REG_ADDR             `DESC_9_BASE_ADDR + 'h108    
`define DESC_9_WUSER_11_REG_ADDR             `DESC_9_BASE_ADDR + 'h10C    
`define DESC_9_WUSER_12_REG_ADDR             `DESC_9_BASE_ADDR + 'h110    
`define DESC_9_WUSER_13_REG_ADDR             `DESC_9_BASE_ADDR + 'h114    
`define DESC_9_WUSER_14_REG_ADDR             `DESC_9_BASE_ADDR + 'h118    
`define DESC_9_WUSER_15_REG_ADDR             `DESC_9_BASE_ADDR + 'h11C    

`define DESC_10_BASE_ADDR 'h4400
`define DESC_10_TXN_TYPE_REG_ADDR             `DESC_10_BASE_ADDR + 'h00   
`define DESC_10_SIZE_REG_ADDR                 `DESC_10_BASE_ADDR + 'h04   
`define DESC_10_DATA_OFFSET_REG_ADDR          `DESC_10_BASE_ADDR + 'h08   
`define DESC_10_DATA_HOST_ADDR_0_REG_ADDR     `DESC_10_BASE_ADDR + 'h10   
`define DESC_10_DATA_HOST_ADDR_1_REG_ADDR     `DESC_10_BASE_ADDR + 'h14   
`define DESC_10_DATA_HOST_ADDR_2_REG_ADDR     `DESC_10_BASE_ADDR + 'h18   
`define DESC_10_DATA_HOST_ADDR_3_REG_ADDR     `DESC_10_BASE_ADDR + 'h1C   
`define DESC_10_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_10_BASE_ADDR + 'h20   
`define DESC_10_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_10_BASE_ADDR + 'h24   
`define DESC_10_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_10_BASE_ADDR + 'h28   
`define DESC_10_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_10_BASE_ADDR + 'h2C   
`define DESC_10_AXSIZE_REG_ADDR               `DESC_10_BASE_ADDR + 'h30   
`define DESC_10_ATTR_REG_ADDR                 `DESC_10_BASE_ADDR + 'h34   
`define DESC_10_AXADDR_0_REG_ADDR             `DESC_10_BASE_ADDR + 'h40   
`define DESC_10_AXADDR_1_REG_ADDR             `DESC_10_BASE_ADDR + 'h44   
`define DESC_10_AXADDR_2_REG_ADDR             `DESC_10_BASE_ADDR + 'h48   
`define DESC_10_AXADDR_3_REG_ADDR             `DESC_10_BASE_ADDR + 'h4C   
`define DESC_10_AXID_0_REG_ADDR               `DESC_10_BASE_ADDR + 'h50   
`define DESC_10_AXID_1_REG_ADDR               `DESC_10_BASE_ADDR + 'h54   
`define DESC_10_AXID_2_REG_ADDR               `DESC_10_BASE_ADDR + 'h58   
`define DESC_10_AXID_3_REG_ADDR               `DESC_10_BASE_ADDR + 'h5C   
`define DESC_10_AXUSER_0_REG_ADDR             `DESC_10_BASE_ADDR + 'h60   
`define DESC_10_AXUSER_1_REG_ADDR             `DESC_10_BASE_ADDR + 'h64   
`define DESC_10_AXUSER_2_REG_ADDR             `DESC_10_BASE_ADDR + 'h68   
`define DESC_10_AXUSER_3_REG_ADDR             `DESC_10_BASE_ADDR + 'h6C   
`define DESC_10_AXUSER_4_REG_ADDR             `DESC_10_BASE_ADDR + 'h70   
`define DESC_10_AXUSER_5_REG_ADDR             `DESC_10_BASE_ADDR + 'h74   
`define DESC_10_AXUSER_6_REG_ADDR             `DESC_10_BASE_ADDR + 'h78   
`define DESC_10_AXUSER_7_REG_ADDR             `DESC_10_BASE_ADDR + 'h7C   
`define DESC_10_AXUSER_8_REG_ADDR             `DESC_10_BASE_ADDR + 'h80   
`define DESC_10_AXUSER_9_REG_ADDR             `DESC_10_BASE_ADDR + 'h84   
`define DESC_10_AXUSER_10_REG_ADDR            `DESC_10_BASE_ADDR + 'h88   
`define DESC_10_AXUSER_11_REG_ADDR            `DESC_10_BASE_ADDR + 'h8C   
`define DESC_10_AXUSER_12_REG_ADDR            `DESC_10_BASE_ADDR + 'h90   
`define DESC_10_AXUSER_13_REG_ADDR            `DESC_10_BASE_ADDR + 'h94   
`define DESC_10_AXUSER_14_REG_ADDR            `DESC_10_BASE_ADDR + 'h98   
`define DESC_10_AXUSER_15_REG_ADDR            `DESC_10_BASE_ADDR + 'h9C   
`define DESC_10_XUSER_0_REG_ADDR              `DESC_10_BASE_ADDR + 'hA0   
`define DESC_10_XUSER_1_REG_ADDR              `DESC_10_BASE_ADDR + 'hA4   
`define DESC_10_XUSER_2_REG_ADDR              `DESC_10_BASE_ADDR + 'hA8   
`define DESC_10_XUSER_3_REG_ADDR              `DESC_10_BASE_ADDR + 'hAC   
`define DESC_10_XUSER_4_REG_ADDR              `DESC_10_BASE_ADDR + 'hB0   
`define DESC_10_XUSER_5_REG_ADDR              `DESC_10_BASE_ADDR + 'hB4   
`define DESC_10_XUSER_6_REG_ADDR              `DESC_10_BASE_ADDR + 'hB8   
`define DESC_10_XUSER_7_REG_ADDR              `DESC_10_BASE_ADDR + 'hBC   
`define DESC_10_XUSER_8_REG_ADDR              `DESC_10_BASE_ADDR + 'hC0   
`define DESC_10_XUSER_9_REG_ADDR              `DESC_10_BASE_ADDR + 'hC4   
`define DESC_10_XUSER_10_REG_ADDR             `DESC_10_BASE_ADDR + 'hC8   
`define DESC_10_XUSER_11_REG_ADDR             `DESC_10_BASE_ADDR + 'hCC   
`define DESC_10_XUSER_12_REG_ADDR             `DESC_10_BASE_ADDR + 'hD0   
`define DESC_10_XUSER_13_REG_ADDR             `DESC_10_BASE_ADDR + 'hD4   
`define DESC_10_XUSER_14_REG_ADDR             `DESC_10_BASE_ADDR + 'hD8   
`define DESC_10_XUSER_15_REG_ADDR             `DESC_10_BASE_ADDR + 'hDC   
`define DESC_10_WUSER_0_REG_ADDR              `DESC_10_BASE_ADDR + 'hE0   
`define DESC_10_WUSER_1_REG_ADDR              `DESC_10_BASE_ADDR + 'hE4   
`define DESC_10_WUSER_2_REG_ADDR              `DESC_10_BASE_ADDR + 'hE8   
`define DESC_10_WUSER_3_REG_ADDR              `DESC_10_BASE_ADDR + 'hEC   
`define DESC_10_WUSER_4_REG_ADDR              `DESC_10_BASE_ADDR + 'hF0   
`define DESC_10_WUSER_5_REG_ADDR              `DESC_10_BASE_ADDR + 'hF4   
`define DESC_10_WUSER_6_REG_ADDR              `DESC_10_BASE_ADDR + 'hF8   
`define DESC_10_WUSER_7_REG_ADDR              `DESC_10_BASE_ADDR + 'hFC   
`define DESC_10_WUSER_8_REG_ADDR              `DESC_10_BASE_ADDR + 'h100  
`define DESC_10_WUSER_9_REG_ADDR              `DESC_10_BASE_ADDR + 'h104  
`define DESC_10_WUSER_10_REG_ADDR             `DESC_10_BASE_ADDR + 'h108  
`define DESC_10_WUSER_11_REG_ADDR             `DESC_10_BASE_ADDR + 'h10C  
`define DESC_10_WUSER_12_REG_ADDR             `DESC_10_BASE_ADDR + 'h110  
`define DESC_10_WUSER_13_REG_ADDR             `DESC_10_BASE_ADDR + 'h114  
`define DESC_10_WUSER_14_REG_ADDR             `DESC_10_BASE_ADDR + 'h118  
`define DESC_10_WUSER_15_REG_ADDR             `DESC_10_BASE_ADDR + 'h11C  

`define DESC_11_BASE_ADDR 'h4600
`define DESC_11_TXN_TYPE_REG_ADDR             `DESC_11_BASE_ADDR + 'h00   
`define DESC_11_SIZE_REG_ADDR                 `DESC_11_BASE_ADDR + 'h04   
`define DESC_11_DATA_OFFSET_REG_ADDR          `DESC_11_BASE_ADDR + 'h08   
`define DESC_11_DATA_HOST_ADDR_0_REG_ADDR     `DESC_11_BASE_ADDR + 'h10   
`define DESC_11_DATA_HOST_ADDR_1_REG_ADDR     `DESC_11_BASE_ADDR + 'h14   
`define DESC_11_DATA_HOST_ADDR_2_REG_ADDR     `DESC_11_BASE_ADDR + 'h18   
`define DESC_11_DATA_HOST_ADDR_3_REG_ADDR     `DESC_11_BASE_ADDR + 'h1C   
`define DESC_11_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_11_BASE_ADDR + 'h20   
`define DESC_11_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_11_BASE_ADDR + 'h24   
`define DESC_11_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_11_BASE_ADDR + 'h28   
`define DESC_11_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_11_BASE_ADDR + 'h2C   
`define DESC_11_AXSIZE_REG_ADDR               `DESC_11_BASE_ADDR + 'h30   
`define DESC_11_ATTR_REG_ADDR                 `DESC_11_BASE_ADDR + 'h34   
`define DESC_11_AXADDR_0_REG_ADDR             `DESC_11_BASE_ADDR + 'h40   
`define DESC_11_AXADDR_1_REG_ADDR             `DESC_11_BASE_ADDR + 'h44   
`define DESC_11_AXADDR_2_REG_ADDR             `DESC_11_BASE_ADDR + 'h48   
`define DESC_11_AXADDR_3_REG_ADDR             `DESC_11_BASE_ADDR + 'h4C   
`define DESC_11_AXID_0_REG_ADDR               `DESC_11_BASE_ADDR + 'h50   
`define DESC_11_AXID_1_REG_ADDR               `DESC_11_BASE_ADDR + 'h54   
`define DESC_11_AXID_2_REG_ADDR               `DESC_11_BASE_ADDR + 'h58   
`define DESC_11_AXID_3_REG_ADDR               `DESC_11_BASE_ADDR + 'h5C   
`define DESC_11_AXUSER_0_REG_ADDR             `DESC_11_BASE_ADDR + 'h60   
`define DESC_11_AXUSER_1_REG_ADDR             `DESC_11_BASE_ADDR + 'h64   
`define DESC_11_AXUSER_2_REG_ADDR             `DESC_11_BASE_ADDR + 'h68   
`define DESC_11_AXUSER_3_REG_ADDR             `DESC_11_BASE_ADDR + 'h6C   
`define DESC_11_AXUSER_4_REG_ADDR             `DESC_11_BASE_ADDR + 'h70   
`define DESC_11_AXUSER_5_REG_ADDR             `DESC_11_BASE_ADDR + 'h74   
`define DESC_11_AXUSER_6_REG_ADDR             `DESC_11_BASE_ADDR + 'h78   
`define DESC_11_AXUSER_7_REG_ADDR             `DESC_11_BASE_ADDR + 'h7C   
`define DESC_11_AXUSER_8_REG_ADDR             `DESC_11_BASE_ADDR + 'h80   
`define DESC_11_AXUSER_9_REG_ADDR             `DESC_11_BASE_ADDR + 'h84   
`define DESC_11_AXUSER_10_REG_ADDR            `DESC_11_BASE_ADDR + 'h88   
`define DESC_11_AXUSER_11_REG_ADDR            `DESC_11_BASE_ADDR + 'h8C   
`define DESC_11_AXUSER_12_REG_ADDR            `DESC_11_BASE_ADDR + 'h90   
`define DESC_11_AXUSER_13_REG_ADDR            `DESC_11_BASE_ADDR + 'h94   
`define DESC_11_AXUSER_14_REG_ADDR            `DESC_11_BASE_ADDR + 'h98   
`define DESC_11_AXUSER_15_REG_ADDR            `DESC_11_BASE_ADDR + 'h9C   
`define DESC_11_XUSER_0_REG_ADDR              `DESC_11_BASE_ADDR + 'hA0   
`define DESC_11_XUSER_1_REG_ADDR              `DESC_11_BASE_ADDR + 'hA4   
`define DESC_11_XUSER_2_REG_ADDR              `DESC_11_BASE_ADDR + 'hA8   
`define DESC_11_XUSER_3_REG_ADDR              `DESC_11_BASE_ADDR + 'hAC   
`define DESC_11_XUSER_4_REG_ADDR              `DESC_11_BASE_ADDR + 'hB0   
`define DESC_11_XUSER_5_REG_ADDR              `DESC_11_BASE_ADDR + 'hB4   
`define DESC_11_XUSER_6_REG_ADDR              `DESC_11_BASE_ADDR + 'hB8   
`define DESC_11_XUSER_7_REG_ADDR              `DESC_11_BASE_ADDR + 'hBC   
`define DESC_11_XUSER_8_REG_ADDR              `DESC_11_BASE_ADDR + 'hC0   
`define DESC_11_XUSER_9_REG_ADDR              `DESC_11_BASE_ADDR + 'hC4   
`define DESC_11_XUSER_10_REG_ADDR             `DESC_11_BASE_ADDR + 'hC8   
`define DESC_11_XUSER_11_REG_ADDR             `DESC_11_BASE_ADDR + 'hCC   
`define DESC_11_XUSER_12_REG_ADDR             `DESC_11_BASE_ADDR + 'hD0   
`define DESC_11_XUSER_13_REG_ADDR             `DESC_11_BASE_ADDR + 'hD4   
`define DESC_11_XUSER_14_REG_ADDR             `DESC_11_BASE_ADDR + 'hD8   
`define DESC_11_XUSER_15_REG_ADDR             `DESC_11_BASE_ADDR + 'hDC   
`define DESC_11_WUSER_0_REG_ADDR              `DESC_11_BASE_ADDR + 'hE0   
`define DESC_11_WUSER_1_REG_ADDR              `DESC_11_BASE_ADDR + 'hE4   
`define DESC_11_WUSER_2_REG_ADDR              `DESC_11_BASE_ADDR + 'hE8   
`define DESC_11_WUSER_3_REG_ADDR              `DESC_11_BASE_ADDR + 'hEC   
`define DESC_11_WUSER_4_REG_ADDR              `DESC_11_BASE_ADDR + 'hF0   
`define DESC_11_WUSER_5_REG_ADDR              `DESC_11_BASE_ADDR + 'hF4   
`define DESC_11_WUSER_6_REG_ADDR              `DESC_11_BASE_ADDR + 'hF8   
`define DESC_11_WUSER_7_REG_ADDR              `DESC_11_BASE_ADDR + 'hFC   
`define DESC_11_WUSER_8_REG_ADDR              `DESC_11_BASE_ADDR + 'h100  
`define DESC_11_WUSER_9_REG_ADDR              `DESC_11_BASE_ADDR + 'h104  
`define DESC_11_WUSER_10_REG_ADDR             `DESC_11_BASE_ADDR + 'h108  
`define DESC_11_WUSER_11_REG_ADDR             `DESC_11_BASE_ADDR + 'h10C  
`define DESC_11_WUSER_12_REG_ADDR             `DESC_11_BASE_ADDR + 'h110  
`define DESC_11_WUSER_13_REG_ADDR             `DESC_11_BASE_ADDR + 'h114  
`define DESC_11_WUSER_14_REG_ADDR             `DESC_11_BASE_ADDR + 'h118  
`define DESC_11_WUSER_15_REG_ADDR             `DESC_11_BASE_ADDR + 'h11C  

`define DESC_12_BASE_ADDR 'h4800
`define DESC_12_TXN_TYPE_REG_ADDR             `DESC_12_BASE_ADDR + 'h00   
`define DESC_12_SIZE_REG_ADDR                 `DESC_12_BASE_ADDR + 'h04   
`define DESC_12_DATA_OFFSET_REG_ADDR          `DESC_12_BASE_ADDR + 'h08   
`define DESC_12_DATA_HOST_ADDR_0_REG_ADDR     `DESC_12_BASE_ADDR + 'h10   
`define DESC_12_DATA_HOST_ADDR_1_REG_ADDR     `DESC_12_BASE_ADDR + 'h14   
`define DESC_12_DATA_HOST_ADDR_2_REG_ADDR     `DESC_12_BASE_ADDR + 'h18   
`define DESC_12_DATA_HOST_ADDR_3_REG_ADDR     `DESC_12_BASE_ADDR + 'h1C   
`define DESC_12_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_12_BASE_ADDR + 'h20   
`define DESC_12_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_12_BASE_ADDR + 'h24   
`define DESC_12_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_12_BASE_ADDR + 'h28   
`define DESC_12_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_12_BASE_ADDR + 'h2C   
`define DESC_12_AXSIZE_REG_ADDR               `DESC_12_BASE_ADDR + 'h30   
`define DESC_12_ATTR_REG_ADDR                 `DESC_12_BASE_ADDR + 'h34   
`define DESC_12_AXADDR_0_REG_ADDR             `DESC_12_BASE_ADDR + 'h40   
`define DESC_12_AXADDR_1_REG_ADDR             `DESC_12_BASE_ADDR + 'h44   
`define DESC_12_AXADDR_2_REG_ADDR             `DESC_12_BASE_ADDR + 'h48   
`define DESC_12_AXADDR_3_REG_ADDR             `DESC_12_BASE_ADDR + 'h4C   
`define DESC_12_AXID_0_REG_ADDR               `DESC_12_BASE_ADDR + 'h50   
`define DESC_12_AXID_1_REG_ADDR               `DESC_12_BASE_ADDR + 'h54   
`define DESC_12_AXID_2_REG_ADDR               `DESC_12_BASE_ADDR + 'h58   
`define DESC_12_AXID_3_REG_ADDR               `DESC_12_BASE_ADDR + 'h5C   
`define DESC_12_AXUSER_0_REG_ADDR             `DESC_12_BASE_ADDR + 'h60   
`define DESC_12_AXUSER_1_REG_ADDR             `DESC_12_BASE_ADDR + 'h64   
`define DESC_12_AXUSER_2_REG_ADDR             `DESC_12_BASE_ADDR + 'h68   
`define DESC_12_AXUSER_3_REG_ADDR             `DESC_12_BASE_ADDR + 'h6C   
`define DESC_12_AXUSER_4_REG_ADDR             `DESC_12_BASE_ADDR + 'h70   
`define DESC_12_AXUSER_5_REG_ADDR             `DESC_12_BASE_ADDR + 'h74   
`define DESC_12_AXUSER_6_REG_ADDR             `DESC_12_BASE_ADDR + 'h78   
`define DESC_12_AXUSER_7_REG_ADDR             `DESC_12_BASE_ADDR + 'h7C   
`define DESC_12_AXUSER_8_REG_ADDR             `DESC_12_BASE_ADDR + 'h80   
`define DESC_12_AXUSER_9_REG_ADDR             `DESC_12_BASE_ADDR + 'h84   
`define DESC_12_AXUSER_10_REG_ADDR            `DESC_12_BASE_ADDR + 'h88   
`define DESC_12_AXUSER_11_REG_ADDR            `DESC_12_BASE_ADDR + 'h8C   
`define DESC_12_AXUSER_12_REG_ADDR            `DESC_12_BASE_ADDR + 'h90   
`define DESC_12_AXUSER_13_REG_ADDR            `DESC_12_BASE_ADDR + 'h94   
`define DESC_12_AXUSER_14_REG_ADDR            `DESC_12_BASE_ADDR + 'h98   
`define DESC_12_AXUSER_15_REG_ADDR            `DESC_12_BASE_ADDR + 'h9C   
`define DESC_12_XUSER_0_REG_ADDR              `DESC_12_BASE_ADDR + 'hA0   
`define DESC_12_XUSER_1_REG_ADDR              `DESC_12_BASE_ADDR + 'hA4   
`define DESC_12_XUSER_2_REG_ADDR              `DESC_12_BASE_ADDR + 'hA8   
`define DESC_12_XUSER_3_REG_ADDR              `DESC_12_BASE_ADDR + 'hAC   
`define DESC_12_XUSER_4_REG_ADDR              `DESC_12_BASE_ADDR + 'hB0   
`define DESC_12_XUSER_5_REG_ADDR              `DESC_12_BASE_ADDR + 'hB4   
`define DESC_12_XUSER_6_REG_ADDR              `DESC_12_BASE_ADDR + 'hB8   
`define DESC_12_XUSER_7_REG_ADDR              `DESC_12_BASE_ADDR + 'hBC   
`define DESC_12_XUSER_8_REG_ADDR              `DESC_12_BASE_ADDR + 'hC0   
`define DESC_12_XUSER_9_REG_ADDR              `DESC_12_BASE_ADDR + 'hC4   
`define DESC_12_XUSER_10_REG_ADDR             `DESC_12_BASE_ADDR + 'hC8   
`define DESC_12_XUSER_11_REG_ADDR             `DESC_12_BASE_ADDR + 'hCC   
`define DESC_12_XUSER_12_REG_ADDR             `DESC_12_BASE_ADDR + 'hD0   
`define DESC_12_XUSER_13_REG_ADDR             `DESC_12_BASE_ADDR + 'hD4   
`define DESC_12_XUSER_14_REG_ADDR             `DESC_12_BASE_ADDR + 'hD8   
`define DESC_12_XUSER_15_REG_ADDR             `DESC_12_BASE_ADDR + 'hDC   
`define DESC_12_WUSER_0_REG_ADDR              `DESC_12_BASE_ADDR + 'hE0   
`define DESC_12_WUSER_1_REG_ADDR              `DESC_12_BASE_ADDR + 'hE4   
`define DESC_12_WUSER_2_REG_ADDR              `DESC_12_BASE_ADDR + 'hE8   
`define DESC_12_WUSER_3_REG_ADDR              `DESC_12_BASE_ADDR + 'hEC   
`define DESC_12_WUSER_4_REG_ADDR              `DESC_12_BASE_ADDR + 'hF0   
`define DESC_12_WUSER_5_REG_ADDR              `DESC_12_BASE_ADDR + 'hF4   
`define DESC_12_WUSER_6_REG_ADDR              `DESC_12_BASE_ADDR + 'hF8   
`define DESC_12_WUSER_7_REG_ADDR              `DESC_12_BASE_ADDR + 'hFC   
`define DESC_12_WUSER_8_REG_ADDR              `DESC_12_BASE_ADDR + 'h100  
`define DESC_12_WUSER_9_REG_ADDR              `DESC_12_BASE_ADDR + 'h104  
`define DESC_12_WUSER_10_REG_ADDR             `DESC_12_BASE_ADDR + 'h108  
`define DESC_12_WUSER_11_REG_ADDR             `DESC_12_BASE_ADDR + 'h10C  
`define DESC_12_WUSER_12_REG_ADDR             `DESC_12_BASE_ADDR + 'h110  
`define DESC_12_WUSER_13_REG_ADDR             `DESC_12_BASE_ADDR + 'h114  
`define DESC_12_WUSER_14_REG_ADDR             `DESC_12_BASE_ADDR + 'h118  
`define DESC_12_WUSER_15_REG_ADDR             `DESC_12_BASE_ADDR + 'h11C  

`define DESC_13_BASE_ADDR 'h4A00
`define DESC_13_TXN_TYPE_REG_ADDR             `DESC_13_BASE_ADDR + 'h00   
`define DESC_13_SIZE_REG_ADDR                 `DESC_13_BASE_ADDR + 'h04   
`define DESC_13_DATA_OFFSET_REG_ADDR          `DESC_13_BASE_ADDR + 'h08   
`define DESC_13_DATA_HOST_ADDR_0_REG_ADDR     `DESC_13_BASE_ADDR + 'h10   
`define DESC_13_DATA_HOST_ADDR_1_REG_ADDR     `DESC_13_BASE_ADDR + 'h14   
`define DESC_13_DATA_HOST_ADDR_2_REG_ADDR     `DESC_13_BASE_ADDR + 'h18   
`define DESC_13_DATA_HOST_ADDR_3_REG_ADDR     `DESC_13_BASE_ADDR + 'h1C   
`define DESC_13_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_13_BASE_ADDR + 'h20   
`define DESC_13_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_13_BASE_ADDR + 'h24   
`define DESC_13_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_13_BASE_ADDR + 'h28   
`define DESC_13_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_13_BASE_ADDR + 'h2C   
`define DESC_13_AXSIZE_REG_ADDR               `DESC_13_BASE_ADDR + 'h30   
`define DESC_13_ATTR_REG_ADDR                 `DESC_13_BASE_ADDR + 'h34   
`define DESC_13_AXADDR_0_REG_ADDR             `DESC_13_BASE_ADDR + 'h40   
`define DESC_13_AXADDR_1_REG_ADDR             `DESC_13_BASE_ADDR + 'h44   
`define DESC_13_AXADDR_2_REG_ADDR             `DESC_13_BASE_ADDR + 'h48   
`define DESC_13_AXADDR_3_REG_ADDR             `DESC_13_BASE_ADDR + 'h4C   
`define DESC_13_AXID_0_REG_ADDR               `DESC_13_BASE_ADDR + 'h50   
`define DESC_13_AXID_1_REG_ADDR               `DESC_13_BASE_ADDR + 'h54   
`define DESC_13_AXID_2_REG_ADDR               `DESC_13_BASE_ADDR + 'h58   
`define DESC_13_AXID_3_REG_ADDR               `DESC_13_BASE_ADDR + 'h5C   
`define DESC_13_AXUSER_0_REG_ADDR             `DESC_13_BASE_ADDR + 'h60   
`define DESC_13_AXUSER_1_REG_ADDR             `DESC_13_BASE_ADDR + 'h64   
`define DESC_13_AXUSER_2_REG_ADDR             `DESC_13_BASE_ADDR + 'h68   
`define DESC_13_AXUSER_3_REG_ADDR             `DESC_13_BASE_ADDR + 'h6C   
`define DESC_13_AXUSER_4_REG_ADDR             `DESC_13_BASE_ADDR + 'h70   
`define DESC_13_AXUSER_5_REG_ADDR             `DESC_13_BASE_ADDR + 'h74   
`define DESC_13_AXUSER_6_REG_ADDR             `DESC_13_BASE_ADDR + 'h78   
`define DESC_13_AXUSER_7_REG_ADDR             `DESC_13_BASE_ADDR + 'h7C   
`define DESC_13_AXUSER_8_REG_ADDR             `DESC_13_BASE_ADDR + 'h80   
`define DESC_13_AXUSER_9_REG_ADDR             `DESC_13_BASE_ADDR + 'h84   
`define DESC_13_AXUSER_10_REG_ADDR            `DESC_13_BASE_ADDR + 'h88   
`define DESC_13_AXUSER_11_REG_ADDR            `DESC_13_BASE_ADDR + 'h8C   
`define DESC_13_AXUSER_12_REG_ADDR            `DESC_13_BASE_ADDR + 'h90   
`define DESC_13_AXUSER_13_REG_ADDR            `DESC_13_BASE_ADDR + 'h94   
`define DESC_13_AXUSER_14_REG_ADDR            `DESC_13_BASE_ADDR + 'h98   
`define DESC_13_AXUSER_15_REG_ADDR            `DESC_13_BASE_ADDR + 'h9C   
`define DESC_13_XUSER_0_REG_ADDR              `DESC_13_BASE_ADDR + 'hA0   
`define DESC_13_XUSER_1_REG_ADDR              `DESC_13_BASE_ADDR + 'hA4   
`define DESC_13_XUSER_2_REG_ADDR              `DESC_13_BASE_ADDR + 'hA8   
`define DESC_13_XUSER_3_REG_ADDR              `DESC_13_BASE_ADDR + 'hAC   
`define DESC_13_XUSER_4_REG_ADDR              `DESC_13_BASE_ADDR + 'hB0   
`define DESC_13_XUSER_5_REG_ADDR              `DESC_13_BASE_ADDR + 'hB4   
`define DESC_13_XUSER_6_REG_ADDR              `DESC_13_BASE_ADDR + 'hB8   
`define DESC_13_XUSER_7_REG_ADDR              `DESC_13_BASE_ADDR + 'hBC   
`define DESC_13_XUSER_8_REG_ADDR              `DESC_13_BASE_ADDR + 'hC0   
`define DESC_13_XUSER_9_REG_ADDR              `DESC_13_BASE_ADDR + 'hC4   
`define DESC_13_XUSER_10_REG_ADDR             `DESC_13_BASE_ADDR + 'hC8   
`define DESC_13_XUSER_11_REG_ADDR             `DESC_13_BASE_ADDR + 'hCC   
`define DESC_13_XUSER_12_REG_ADDR             `DESC_13_BASE_ADDR + 'hD0   
`define DESC_13_XUSER_13_REG_ADDR             `DESC_13_BASE_ADDR + 'hD4   
`define DESC_13_XUSER_14_REG_ADDR             `DESC_13_BASE_ADDR + 'hD8   
`define DESC_13_XUSER_15_REG_ADDR             `DESC_13_BASE_ADDR + 'hDC   
`define DESC_13_WUSER_0_REG_ADDR              `DESC_13_BASE_ADDR + 'hE0   
`define DESC_13_WUSER_1_REG_ADDR              `DESC_13_BASE_ADDR + 'hE4   
`define DESC_13_WUSER_2_REG_ADDR              `DESC_13_BASE_ADDR + 'hE8   
`define DESC_13_WUSER_3_REG_ADDR              `DESC_13_BASE_ADDR + 'hEC   
`define DESC_13_WUSER_4_REG_ADDR              `DESC_13_BASE_ADDR + 'hF0   
`define DESC_13_WUSER_5_REG_ADDR              `DESC_13_BASE_ADDR + 'hF4   
`define DESC_13_WUSER_6_REG_ADDR              `DESC_13_BASE_ADDR + 'hF8   
`define DESC_13_WUSER_7_REG_ADDR              `DESC_13_BASE_ADDR + 'hFC   
`define DESC_13_WUSER_8_REG_ADDR              `DESC_13_BASE_ADDR + 'h100  
`define DESC_13_WUSER_9_REG_ADDR              `DESC_13_BASE_ADDR + 'h104  
`define DESC_13_WUSER_10_REG_ADDR             `DESC_13_BASE_ADDR + 'h108  
`define DESC_13_WUSER_11_REG_ADDR             `DESC_13_BASE_ADDR + 'h10C  
`define DESC_13_WUSER_12_REG_ADDR             `DESC_13_BASE_ADDR + 'h110  
`define DESC_13_WUSER_13_REG_ADDR             `DESC_13_BASE_ADDR + 'h114  
`define DESC_13_WUSER_14_REG_ADDR             `DESC_13_BASE_ADDR + 'h118  
`define DESC_13_WUSER_15_REG_ADDR             `DESC_13_BASE_ADDR + 'h11C  

`define DESC_14_BASE_ADDR 'h4C00
`define DESC_14_TXN_TYPE_REG_ADDR             `DESC_14_BASE_ADDR + 'h00   
`define DESC_14_SIZE_REG_ADDR                 `DESC_14_BASE_ADDR + 'h04   
`define DESC_14_DATA_OFFSET_REG_ADDR          `DESC_14_BASE_ADDR + 'h08   
`define DESC_14_DATA_HOST_ADDR_0_REG_ADDR     `DESC_14_BASE_ADDR + 'h10   
`define DESC_14_DATA_HOST_ADDR_1_REG_ADDR     `DESC_14_BASE_ADDR + 'h14   
`define DESC_14_DATA_HOST_ADDR_2_REG_ADDR     `DESC_14_BASE_ADDR + 'h18   
`define DESC_14_DATA_HOST_ADDR_3_REG_ADDR     `DESC_14_BASE_ADDR + 'h1C   
`define DESC_14_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_14_BASE_ADDR + 'h20   
`define DESC_14_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_14_BASE_ADDR + 'h24   
`define DESC_14_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_14_BASE_ADDR + 'h28   
`define DESC_14_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_14_BASE_ADDR + 'h2C   
`define DESC_14_AXSIZE_REG_ADDR               `DESC_14_BASE_ADDR + 'h30   
`define DESC_14_ATTR_REG_ADDR                 `DESC_14_BASE_ADDR + 'h34   
`define DESC_14_AXADDR_0_REG_ADDR             `DESC_14_BASE_ADDR + 'h40   
`define DESC_14_AXADDR_1_REG_ADDR             `DESC_14_BASE_ADDR + 'h44   
`define DESC_14_AXADDR_2_REG_ADDR             `DESC_14_BASE_ADDR + 'h48   
`define DESC_14_AXADDR_3_REG_ADDR             `DESC_14_BASE_ADDR + 'h4C   
`define DESC_14_AXID_0_REG_ADDR               `DESC_14_BASE_ADDR + 'h50   
`define DESC_14_AXID_1_REG_ADDR               `DESC_14_BASE_ADDR + 'h54   
`define DESC_14_AXID_2_REG_ADDR               `DESC_14_BASE_ADDR + 'h58   
`define DESC_14_AXID_3_REG_ADDR               `DESC_14_BASE_ADDR + 'h5C   
`define DESC_14_AXUSER_0_REG_ADDR             `DESC_14_BASE_ADDR + 'h60   
`define DESC_14_AXUSER_1_REG_ADDR             `DESC_14_BASE_ADDR + 'h64   
`define DESC_14_AXUSER_2_REG_ADDR             `DESC_14_BASE_ADDR + 'h68   
`define DESC_14_AXUSER_3_REG_ADDR             `DESC_14_BASE_ADDR + 'h6C   
`define DESC_14_AXUSER_4_REG_ADDR             `DESC_14_BASE_ADDR + 'h70   
`define DESC_14_AXUSER_5_REG_ADDR             `DESC_14_BASE_ADDR + 'h74   
`define DESC_14_AXUSER_6_REG_ADDR             `DESC_14_BASE_ADDR + 'h78   
`define DESC_14_AXUSER_7_REG_ADDR             `DESC_14_BASE_ADDR + 'h7C   
`define DESC_14_AXUSER_8_REG_ADDR             `DESC_14_BASE_ADDR + 'h80   
`define DESC_14_AXUSER_9_REG_ADDR             `DESC_14_BASE_ADDR + 'h84   
`define DESC_14_AXUSER_10_REG_ADDR            `DESC_14_BASE_ADDR + 'h88   
`define DESC_14_AXUSER_11_REG_ADDR            `DESC_14_BASE_ADDR + 'h8C   
`define DESC_14_AXUSER_12_REG_ADDR            `DESC_14_BASE_ADDR + 'h90   
`define DESC_14_AXUSER_13_REG_ADDR            `DESC_14_BASE_ADDR + 'h94   
`define DESC_14_AXUSER_14_REG_ADDR            `DESC_14_BASE_ADDR + 'h98   
`define DESC_14_AXUSER_15_REG_ADDR            `DESC_14_BASE_ADDR + 'h9C   
`define DESC_14_XUSER_0_REG_ADDR              `DESC_14_BASE_ADDR + 'hA0   
`define DESC_14_XUSER_1_REG_ADDR              `DESC_14_BASE_ADDR + 'hA4   
`define DESC_14_XUSER_2_REG_ADDR              `DESC_14_BASE_ADDR + 'hA8   
`define DESC_14_XUSER_3_REG_ADDR              `DESC_14_BASE_ADDR + 'hAC   
`define DESC_14_XUSER_4_REG_ADDR              `DESC_14_BASE_ADDR + 'hB0   
`define DESC_14_XUSER_5_REG_ADDR              `DESC_14_BASE_ADDR + 'hB4   
`define DESC_14_XUSER_6_REG_ADDR              `DESC_14_BASE_ADDR + 'hB8   
`define DESC_14_XUSER_7_REG_ADDR              `DESC_14_BASE_ADDR + 'hBC   
`define DESC_14_XUSER_8_REG_ADDR              `DESC_14_BASE_ADDR + 'hC0   
`define DESC_14_XUSER_9_REG_ADDR              `DESC_14_BASE_ADDR + 'hC4   
`define DESC_14_XUSER_10_REG_ADDR             `DESC_14_BASE_ADDR + 'hC8   
`define DESC_14_XUSER_11_REG_ADDR             `DESC_14_BASE_ADDR + 'hCC   
`define DESC_14_XUSER_12_REG_ADDR             `DESC_14_BASE_ADDR + 'hD0   
`define DESC_14_XUSER_13_REG_ADDR             `DESC_14_BASE_ADDR + 'hD4   
`define DESC_14_XUSER_14_REG_ADDR             `DESC_14_BASE_ADDR + 'hD8   
`define DESC_14_XUSER_15_REG_ADDR             `DESC_14_BASE_ADDR + 'hDC   
`define DESC_14_WUSER_0_REG_ADDR              `DESC_14_BASE_ADDR + 'hE0   
`define DESC_14_WUSER_1_REG_ADDR              `DESC_14_BASE_ADDR + 'hE4   
`define DESC_14_WUSER_2_REG_ADDR              `DESC_14_BASE_ADDR + 'hE8   
`define DESC_14_WUSER_3_REG_ADDR              `DESC_14_BASE_ADDR + 'hEC   
`define DESC_14_WUSER_4_REG_ADDR              `DESC_14_BASE_ADDR + 'hF0   
`define DESC_14_WUSER_5_REG_ADDR              `DESC_14_BASE_ADDR + 'hF4   
`define DESC_14_WUSER_6_REG_ADDR              `DESC_14_BASE_ADDR + 'hF8   
`define DESC_14_WUSER_7_REG_ADDR              `DESC_14_BASE_ADDR + 'hFC   
`define DESC_14_WUSER_8_REG_ADDR              `DESC_14_BASE_ADDR + 'h100  
`define DESC_14_WUSER_9_REG_ADDR              `DESC_14_BASE_ADDR + 'h104  
`define DESC_14_WUSER_10_REG_ADDR             `DESC_14_BASE_ADDR + 'h108  
`define DESC_14_WUSER_11_REG_ADDR             `DESC_14_BASE_ADDR + 'h10C  
`define DESC_14_WUSER_12_REG_ADDR             `DESC_14_BASE_ADDR + 'h110  
`define DESC_14_WUSER_13_REG_ADDR             `DESC_14_BASE_ADDR + 'h114  
`define DESC_14_WUSER_14_REG_ADDR             `DESC_14_BASE_ADDR + 'h118  
`define DESC_14_WUSER_15_REG_ADDR             `DESC_14_BASE_ADDR + 'h11C  

`define DESC_15_BASE_ADDR 'h4E00
`define DESC_15_TXN_TYPE_REG_ADDR             `DESC_15_BASE_ADDR + 'h00   
`define DESC_15_SIZE_REG_ADDR                 `DESC_15_BASE_ADDR + 'h04   
`define DESC_15_DATA_OFFSET_REG_ADDR          `DESC_15_BASE_ADDR + 'h08   
`define DESC_15_DATA_HOST_ADDR_0_REG_ADDR     `DESC_15_BASE_ADDR + 'h10   
`define DESC_15_DATA_HOST_ADDR_1_REG_ADDR     `DESC_15_BASE_ADDR + 'h14   
`define DESC_15_DATA_HOST_ADDR_2_REG_ADDR     `DESC_15_BASE_ADDR + 'h18   
`define DESC_15_DATA_HOST_ADDR_3_REG_ADDR     `DESC_15_BASE_ADDR + 'h1C   
`define DESC_15_WSTRB_HOST_ADDR_0_REG_ADDR    `DESC_15_BASE_ADDR + 'h20   
`define DESC_15_WSTRB_HOST_ADDR_1_REG_ADDR    `DESC_15_BASE_ADDR + 'h24   
`define DESC_15_WSTRB_HOST_ADDR_2_REG_ADDR    `DESC_15_BASE_ADDR + 'h28   
`define DESC_15_WSTRB_HOST_ADDR_3_REG_ADDR    `DESC_15_BASE_ADDR + 'h2C   
`define DESC_15_AXSIZE_REG_ADDR               `DESC_15_BASE_ADDR + 'h30   
`define DESC_15_ATTR_REG_ADDR                 `DESC_15_BASE_ADDR + 'h34   
`define DESC_15_AXADDR_0_REG_ADDR             `DESC_15_BASE_ADDR + 'h40   
`define DESC_15_AXADDR_1_REG_ADDR             `DESC_15_BASE_ADDR + 'h44   
`define DESC_15_AXADDR_2_REG_ADDR             `DESC_15_BASE_ADDR + 'h48   
`define DESC_15_AXADDR_3_REG_ADDR             `DESC_15_BASE_ADDR + 'h4C   
`define DESC_15_AXID_0_REG_ADDR               `DESC_15_BASE_ADDR + 'h50   
`define DESC_15_AXID_1_REG_ADDR               `DESC_15_BASE_ADDR + 'h54   
`define DESC_15_AXID_2_REG_ADDR               `DESC_15_BASE_ADDR + 'h58   
`define DESC_15_AXID_3_REG_ADDR               `DESC_15_BASE_ADDR + 'h5C   
`define DESC_15_AXUSER_0_REG_ADDR             `DESC_15_BASE_ADDR + 'h60   
`define DESC_15_AXUSER_1_REG_ADDR             `DESC_15_BASE_ADDR + 'h64   
`define DESC_15_AXUSER_2_REG_ADDR             `DESC_15_BASE_ADDR + 'h68   
`define DESC_15_AXUSER_3_REG_ADDR             `DESC_15_BASE_ADDR + 'h6C   
`define DESC_15_AXUSER_4_REG_ADDR             `DESC_15_BASE_ADDR + 'h70   
`define DESC_15_AXUSER_5_REG_ADDR             `DESC_15_BASE_ADDR + 'h74   
`define DESC_15_AXUSER_6_REG_ADDR             `DESC_15_BASE_ADDR + 'h78   
`define DESC_15_AXUSER_7_REG_ADDR             `DESC_15_BASE_ADDR + 'h7C   
`define DESC_15_AXUSER_8_REG_ADDR             `DESC_15_BASE_ADDR + 'h80   
`define DESC_15_AXUSER_9_REG_ADDR             `DESC_15_BASE_ADDR + 'h84   
`define DESC_15_AXUSER_10_REG_ADDR            `DESC_15_BASE_ADDR + 'h88   
`define DESC_15_AXUSER_11_REG_ADDR            `DESC_15_BASE_ADDR + 'h8C   
`define DESC_15_AXUSER_12_REG_ADDR            `DESC_15_BASE_ADDR + 'h90   
`define DESC_15_AXUSER_13_REG_ADDR            `DESC_15_BASE_ADDR + 'h94   
`define DESC_15_AXUSER_14_REG_ADDR            `DESC_15_BASE_ADDR + 'h98   
`define DESC_15_AXUSER_15_REG_ADDR            `DESC_15_BASE_ADDR + 'h9C   
`define DESC_15_XUSER_0_REG_ADDR              `DESC_15_BASE_ADDR + 'hA0   
`define DESC_15_XUSER_1_REG_ADDR              `DESC_15_BASE_ADDR + 'hA4   
`define DESC_15_XUSER_2_REG_ADDR              `DESC_15_BASE_ADDR + 'hA8   
`define DESC_15_XUSER_3_REG_ADDR              `DESC_15_BASE_ADDR + 'hAC   
`define DESC_15_XUSER_4_REG_ADDR              `DESC_15_BASE_ADDR + 'hB0   
`define DESC_15_XUSER_5_REG_ADDR              `DESC_15_BASE_ADDR + 'hB4   
`define DESC_15_XUSER_6_REG_ADDR              `DESC_15_BASE_ADDR + 'hB8   
`define DESC_15_XUSER_7_REG_ADDR              `DESC_15_BASE_ADDR + 'hBC   
`define DESC_15_XUSER_8_REG_ADDR              `DESC_15_BASE_ADDR + 'hC0   
`define DESC_15_XUSER_9_REG_ADDR              `DESC_15_BASE_ADDR + 'hC4   
`define DESC_15_XUSER_10_REG_ADDR             `DESC_15_BASE_ADDR + 'hC8   
`define DESC_15_XUSER_11_REG_ADDR             `DESC_15_BASE_ADDR + 'hCC   
`define DESC_15_XUSER_12_REG_ADDR             `DESC_15_BASE_ADDR + 'hD0   
`define DESC_15_XUSER_13_REG_ADDR             `DESC_15_BASE_ADDR + 'hD4   
`define DESC_15_XUSER_14_REG_ADDR             `DESC_15_BASE_ADDR + 'hD8   
`define DESC_15_XUSER_15_REG_ADDR             `DESC_15_BASE_ADDR + 'hDC   
`define DESC_15_WUSER_0_REG_ADDR              `DESC_15_BASE_ADDR + 'hE0   
`define DESC_15_WUSER_1_REG_ADDR              `DESC_15_BASE_ADDR + 'hE4   
`define DESC_15_WUSER_2_REG_ADDR              `DESC_15_BASE_ADDR + 'hE8   
`define DESC_15_WUSER_3_REG_ADDR              `DESC_15_BASE_ADDR + 'hEC   
`define DESC_15_WUSER_4_REG_ADDR              `DESC_15_BASE_ADDR + 'hF0   
`define DESC_15_WUSER_5_REG_ADDR              `DESC_15_BASE_ADDR + 'hF4   
`define DESC_15_WUSER_6_REG_ADDR              `DESC_15_BASE_ADDR + 'hF8   
`define DESC_15_WUSER_7_REG_ADDR              `DESC_15_BASE_ADDR + 'hFC   
`define DESC_15_WUSER_8_REG_ADDR              `DESC_15_BASE_ADDR + 'h100  
`define DESC_15_WUSER_9_REG_ADDR              `DESC_15_BASE_ADDR + 'h104  
`define DESC_15_WUSER_10_REG_ADDR             `DESC_15_BASE_ADDR + 'h108  
`define DESC_15_WUSER_11_REG_ADDR             `DESC_15_BASE_ADDR + 'h10C  
`define DESC_15_WUSER_12_REG_ADDR             `DESC_15_BASE_ADDR + 'h110  
`define DESC_15_WUSER_13_REG_ADDR             `DESC_15_BASE_ADDR + 'h114  
`define DESC_15_WUSER_14_REG_ADDR             `DESC_15_BASE_ADDR + 'h118  
`define DESC_15_WUSER_15_REG_ADDR             `DESC_15_BASE_ADDR + 'h11C  
         
