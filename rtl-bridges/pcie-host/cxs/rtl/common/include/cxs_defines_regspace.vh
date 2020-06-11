/*
 * Copyright (c) 2020 Xilinx Inc.
 * Written by Heramb Aligave.
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
 *   
 *
 */
// OFFSET ADDR of REGS

`define BRIDGE_IDENTIFICATION_REG_ADDR    'h0
`define BRIDGE_IDENTIFICATION_ID     'hC3A89FE1
`define LAST_BRIDGE_REG_ADDR              'h4
`define VERSION_REG_ADDR             'h20   
`define BRIDGE_TYPE_REG_ADDR         'h24   
`define MODE_SELECT_REG_ADDR         'h38   
`define RESET_REG_ADDR               'h3C   
`define H2C_INTR_0_REG_ADDR          'h40   
`define H2C_INTR_1_REG_ADDR          'h44
`define H2C_INTR_2_REG_ADDR          'h48
`define H2C_INTR_3_REG_ADDR          'h4C
`define C2H_INTR_0_STATUS_REG_ADDR   'h60   
`define C2H_INTR_TOGGLE_STATUS_0_REG_ADDR   'h64   
`define C2H_INTR_TOGGLE_CLEAR_0_REG_ADDR    'h68   
`define C2H_INTR_TOGGLE_ENABLE_0_REG_ADDR   'h6C
`define C2H_INTR_1_STATUS_REG_ADDR   'h70   
`define C2H_INTR_TOGGLE_STATUS_1_REG_ADDR   'h74   
`define C2H_INTR_TOGGLE_CLEAR_1_REG_ADDR    'h78   
`define C2H_INTR_TOGGLE_ENABLE_1_REG_ADDR   'h7C
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

`define H2C_GPIO_0_REG_ADDR   'hC0    
`define H2C_GPIO_1_REG_ADDR   'hC4    
`define H2C_GPIO_2_REG_ADDR   'hC8    
`define H2C_GPIO_3_REG_ADDR   'hCC    
`define H2C_GPIO_4_REG_ADDR   'hD0    
`define H2C_GPIO_5_REG_ADDR   'hD4    
`define H2C_GPIO_6_REG_ADDR   'hD8    
`define H2C_GPIO_7_REG_ADDR   'hDC    

`define INTR_STATUS_REG_ADDR                         'h208   
`define INTR_ERROR_STATUS_REG_ADDR                   'h20C   
`define INTR_ERROR_CLEAR_REG_ADDR                    'h210   
`define INTR_ERROR_ENABLE_REG_ADDR                   'h214
`define CXS_BRIDGE_FLIT_CONFIG_REG_ADDR              'h300   
`define CXS_BRIDGE_CONFIGURE_REG_ADDR                'h304
`define CXS_BRIDGE_RX_REFILL_CREDITS_REG_ADDR        'h308   
`define CXS_BRIDGE_LOW_POWER_REG_ADDR                'h30C   
`define CXS_BRIDGE_CHANNEL_TX_STS_REG_ADDR           'h330   
`define CXS_BRIDGE_CHANNEL_RX_STS_REG_ADDR           'h334
`define TX_OWNERSHIP_REG_ADDR                        'h338   
`define TX_OWNERSHIP_FLIP_REG_ADDR                   'h33c   
`define RX_OWNERSHIP_REG_ADDR                        'h340   
`define RX_OWNERSHIP_FLIP_REG_ADDR                   'h344   
`define RX_GOOD_TLP_REG_ADDR                         'h348   
`define RX_ERROR_TLP_REG_ADDR                        'h34c   
`define CXS_BRIDGE_RX_CUR_CREDIT_REG_ADDR            'h350
`define CXS_BRIDGE_TX_CUR_CREDIT_REG_ADDR            'h354
`define INTR_FLIT_TXN_STATUS_REG_ADDR                'h3A0
`define INTR_FLIT_TXN_CLEAR_REG_ADDR                 'h3A4
`define INTR_FLIT_TXN_ENABLE_REG_ADDR                'h3A8


`define MAX_NUM_CREDITS   'hF
`define INTR_ACK
// Used for Calculating DATA RAM address bits
`define CLOG2(x) \
   (x <= 2)             ? 1     : \
   (x <= 4)             ? 2     : \
   (x <= 8)             ? 3     : \
   (x <= 16)            ? 4     : \
   (x <= 32)            ? 5     : \
   (x <= 64)            ? 6     : \
   (x <= 128)           ? 7     : \
   (x <= 256)           ? 8     : \
   (x <= 512)           ? 9     : \
   (x <= 1024)          ? 10    : \
   (x <= 2048)          ? 11    : \
   (x <= 4096)          ? 12    : \
   (x <= 8192)          ? 13    : \
   (x <= 16384)         ? 14    : \
   (x <= 32768)         ? 15    : \
   (x <= 65536)         ? 16    : \
   (x <= 131072)         ? 17    : \
   -1
