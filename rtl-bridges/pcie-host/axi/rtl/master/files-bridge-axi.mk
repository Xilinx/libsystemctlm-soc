#
# Copyright (c) 2019 Xilinx Inc.
# Written by Alok Mistry.
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

RTL_BRIDGE_AXI4LITE_MASTER_V += $(RTL_BRIDGE_AXI_DIR)/master/axi4_lite_master.v
RTL_BRIDGE_AXI4LITE_MASTER_V += $(RTL_BRIDGE_COMMON_MASTER_V)

RTL_BRIDGE_AXI3_MASTER_V += $(RTL_BRIDGE_AXI_DIR)/master/axi3_master.v
RTL_BRIDGE_AXI3_MASTER_V += $(RTL_BRIDGE_COMMON_MASTER_V)

RTL_BRIDGE_AXI4_MASTER_V += $(RTL_BRIDGE_AXI_DIR)/master/axi4_master.v
RTL_BRIDGE_AXI4_MASTER_V += $(RTL_BRIDGE_COMMON_MASTER_V)

RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_AXI_DIR)/master/axi_master_common.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_AXI_DIR)/master/host_master_m.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_AXI_DIR)/master/intr_handler_master.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_AXI_DIR)/master/regs_master.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_AXI_DIR)/master/user_master_control.v

RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_COMMON_V)
