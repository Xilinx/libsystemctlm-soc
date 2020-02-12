#
# Copyright (c) 2020 Xilinx Inc.
# Written by Meera Bagdai.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

RTL_BRIDGE_ACEFULL_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/acefull_mst.v
RTL_BRIDGE_ACEFULL_MASTER_V += $(RTL_BRIDGE_COMMON_MASTER_V)

RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_txn_allocator.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_usr_mst_control.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_usr_mst_control_field.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/host_master_m.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_mst_rd_resp_ready.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_regs_mst.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_axid_store.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_host_mst_mst.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_intr_handler_mst.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_mst_allprot.v
RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_mst_inf.v

RTL_BRIDGE_COMMON_MASTER_V += $(RTL_BRIDGE_COMMON_V)
