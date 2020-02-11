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
# 
# Description: 
#  		COMMON Filelist for HN-F and RN-F 
# 
# 


RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/chi_bridge.v
RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/chi_channel_if.v
RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/chi_intr_handler.v
RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/chi_link_credit_manager.v
RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/chi_register_interface.v
RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/chi_rxflit_ram.v
RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/chi_txflit_mgmt.v
RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/chi_txflit_ram.v

RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/include/chi_defines_field.vh
RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/include/chi_defines_intr.vh
RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/include/chi_defines_regspace.vh
RTL_BRIDGE_CHI_COMMON_V += $(RTL_BRIDGE_CHI_DIR)/common/include/defines_common.vh

