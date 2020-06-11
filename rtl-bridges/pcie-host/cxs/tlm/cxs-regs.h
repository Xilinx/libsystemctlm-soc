/*
 * Copyright (c) 2020 Xilinx Inc.
 * Written by Francisco Iglesias.
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
 */

#ifndef __CXS_REGS_H__
#define __CXS_REGS_H__

#define BRIDGE_IDENTIFICATION_REG_ADDR		0x0
#define BRIDGE_IDENTIFICATION_ID		0xC3A89FE1
#define LAST_BRIDGE_REG_ADDR			0x4
#define VERSION_REG_ADDR			0x20
#define BRIDGE_TYPE_REG_ADDR			0x24
#define MODE_SELECT_REG_ADDR			0x38
#define RESET_REG_ADDR				0x3C
#define H2C_INTR_0_REG_ADDR			0x40
#define H2C_INTR_1_REG_ADDR			0x44
#define H2C_INTR_2_REG_ADDR			0x48
#define H2C_INTR_3_REG_ADDR			0x4C
#define C2H_INTR_0_STATUS_REG_ADDR		0x60
#define C2H_INTR_TOGGLE_STATUS_0_REG_ADDR	0x64
#define C2H_INTR_TOGGLE_CLEAR_0_REG_ADDR	0x68
#define C2H_INTR_TOGGLE_ENABLE_0_REG_ADDR	0x6C
#define C2H_INTR_1_STATUS_REG_ADDR		0x70
#define C2H_INTR_TOGGLE_STATUS_1_REG_ADDR	0x74
#define C2H_INTR_TOGGLE_CLEAR_1_REG_ADDR	0x78
#define C2H_INTR_TOGGLE_ENABLE_1_REG_ADDR	0x7C
#define C2H_GPIO_0_REG_ADDR			0x80
#define C2H_GPIO_1_REG_ADDR			0x84
#define C2H_GPIO_2_REG_ADDR			0x88
#define C2H_GPIO_3_REG_ADDR			0x8C
#define C2H_GPIO_4_REG_ADDR			0x90
#define C2H_GPIO_5_REG_ADDR			0x94
#define C2H_GPIO_6_REG_ADDR			0x98
#define C2H_GPIO_7_REG_ADDR			0x9C
#define C2H_GPIO_8_REG_ADDR			0xA0
#define C2H_GPIO_9_REG_ADDR			0xA4
#define C2H_GPIO_10_REG_ADDR			0xA8
#define C2H_GPIO_11_REG_ADDR			0xAC
#define C2H_GPIO_12_REG_ADDR			0xB0
#define C2H_GPIO_13_REG_ADDR			0xB4
#define C2H_GPIO_14_REG_ADDR			0xB8
#define C2H_GPIO_15_REG_ADDR			0xBC

#define H2C_GPIO_0_REG_ADDR			0xC0
#define H2C_GPIO_1_REG_ADDR			0xC4
#define H2C_GPIO_2_REG_ADDR			0xC8
#define H2C_GPIO_3_REG_ADDR			0xCC
#define H2C_GPIO_4_REG_ADDR			0xD0
#define H2C_GPIO_5_REG_ADDR			0xD4
#define H2C_GPIO_6_REG_ADDR			0xD8
#define H2C_GPIO_7_REG_ADDR			0xDC

#define INTR_STATUS_REG_ADDR			0x208
#define INTR_ERROR_STATUS_REG_ADDR		0x20C
#define INTR_ERROR_CLEAR_REG_ADDR		0x210
#define INTR_ERROR_ENABLE_REG_ADDR		0x214
#define CXS_BRIDGE_FLIT_CONFIG_REG_ADDR		0x300
#define CXS_BRIDGE_CONFIGURE_REG_ADDR		0x304
#define CXS_BRIDGE_RX_REFILL_CREDITS_REG_ADDR	0x308
#define CXS_BRIDGE_LOW_POWER_REG_ADDR		0x30C
#define CXS_BRIDGE_CHANNEL_TX_STS_REG_ADDR	0x330
#define CXS_BRIDGE_CHANNEL_RX_STS_REG_ADDR	0x334
#define TX_OWNERSHIP_REG_ADDR			0x338
#define TX_OWNERSHIP_FLIP_REG_ADDR		0x33c
#define RX_OWNERSHIP_REG_ADDR			0x340
#define RX_OWNERSHIP_FLIP_REG_ADDR		0x344
#define RX_GOOD_TLP_REG_ADDR			0x348
#define RX_ERROR_TLP_REG_ADDR			0x34c
#define CXS_BRIDGE_RX_CUR_CREDIT_REG_ADDR	0x350
#define CXS_BRIDGE_TX_CUR_CREDIT_REG_ADDR	0x354
#define INTR_FLIT_TXN_STATUS_REG_ADDR		0x3A0
#define INTR_FLIT_TXN_CLEAR_REG_ADDR		0x3A4
#define INTR_FLIT_TXN_ENABLE_REG_ADDR		0x3A8

#define RX_BASE_DATA				0x3100
#define RX_BASE_CNTL				0x3C00

#define TX_BASE_DATA				0x4100
#define TX_BASE_CNTL				0x4C00

#endif
