#
# Copyright (c) 2019 Xilinx Inc.
# Written by Meera Bagdai.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

RTL_BRIDGE_AXI4LITE_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/axi4lite_slave.v
RTL_BRIDGE_AXI4LITE_SLAVE_V += $(RTL_BRIDGE_COMMON_SLAVE_V)

RTL_BRIDGE_AXI4_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/axi4_slave.v
RTL_BRIDGE_AXI4_SLAVE_V += $(RTL_BRIDGE_COMMON_SLAVE_V)

RTL_BRIDGE_AXI3_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/axi3_slave.v
RTL_BRIDGE_AXI3_SLAVE_V += $(RTL_BRIDGE_COMMON_SLAVE_V)

RTL_BRIDGE_COMMON_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/addr_allocator.v
RTL_BRIDGE_COMMON_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/axi_slave_allprot.v
RTL_BRIDGE_COMMON_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/grant_controller.v
RTL_BRIDGE_COMMON_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/intr_handler_slave.v
RTL_BRIDGE_COMMON_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/regs_slave.v
RTL_BRIDGE_COMMON_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/slave_inf.v
RTL_BRIDGE_COMMON_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/txn_allocator.v
RTL_BRIDGE_COMMON_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/user_slave_control_field.v
RTL_BRIDGE_COMMON_SLAVE_V += $(RTL_BRIDGE_AXI_DIR)/slave/user_slave_control.v

RTL_BRIDGE_COMMON_SLAVE_V += $(RTL_BRIDGE_COMMON_V)
