# 
# Copyright (c) 2020 Xilinx Inc.
# Written by Heramb Aligave.
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
# 
# Description: 
#  		COMMON Filelist for CXS 
# 
# 


RTL_BRIDGE_CXS_COMMON_V += $(RTL_BRIDGE_CXS_DIR)/common/cxs_channel_if.v
RTL_BRIDGE_CXS_COMMON_V += $(RTL_BRIDGE_CXS_DIR)/common/cxs_intr_handler.v
RTL_BRIDGE_CXS_COMMON_V += $(RTL_BRIDGE_CXS_DIR)/common/cxs_link_credit_manager.v
RTL_BRIDGE_CXS_COMMON_V += $(RTL_BRIDGE_CXS_DIR)/common/cxs_register_interface.v
RTL_BRIDGE_CXS_COMMON_V += $(RTL_BRIDGE_CXS_DIR)/common/cxs_rxflit_ram.v
RTL_BRIDGE_CXS_COMMON_V += $(RTL_BRIDGE_CXS_DIR)/common/cxs_txflit_mgmt.v
RTL_BRIDGE_CXS_COMMON_V += $(RTL_BRIDGE_CXS_DIR)/common/cxs_txflit_ram.v
RTL_BRIDGE_CXS_COMMON_V += $(RTL_BRIDGE_CXS_DIR)/common/cxs_bridge.v
RTL_BRIDGE_CXS_COMMON_V += $(RTL_BRIDGE_CXS_DIR)/common/include/cxs_defines_regspace.vh

