#
# Copyright (c) 2020 Xilinx Inc.
# Written by Francisco Iglesias,
#            Edgar E. Iglesias.
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

-include ../../../.config.mk
include ../../Rules.mk

VFLAGS =-Wno-fatal --pins-bv 2 --sc
VFLAGS =-Wno-fatal --pins-bv 2 --sc
VFLAGS += --unroll-count 100000                                                                                                                    
VFLAGS += --unroll-stmts 100000
VFLAGS += --output-split-cfuncs 500
# FIXME: These should really go away                                                                                                               
VFLAGS += -Wno-PINMISSING -Wno-COMBDLY

VM_SC=1
VM_TRACE=1

ifeq "$(VM_TRACE)" "1"
VFLAGS += --trace
VERILATED_OBJS_COMMON += verilated_vcd_c.o
VERILATED_OBJS_COMMON += verilated_vcd_sc.o
CPPFLAGS += -DVM_TRACE=1
endif

CPPFLAGS += -I $(VOBJ_DIR)
CPPFLAGS += -I $(VERILATOR_ROOT)/include

CPPFLAGS += -I ../../../ -I ../../ -I .
CXXFLAGS += -Wall -O3 -g

OBJS_COMMON += ../../test-modules/memory.o

VERILATED_OBJS_COMMON += $(OBJS_COMMON)
ALL_OBJS += $(VERILATED_OBJS_COMMON)

RTL_BRIDGE_ACE_DIR = ../../../rtl-bridges/pcie-host/ace/rtl
RTL_BRIDGE_ACE_COMON_DIR = $(RTL_BRIDGE_ACE_DIR)/common
VFLAGS_RTL_BRIDGE_ACE_SLV  = -I$(RTL_BRIDGE_ACE_COMON_DIR)
VFLAGS_RTL_BRIDGE_ACE_SLV += -I$(RTL_BRIDGE_ACE_DIR)/slave

ACE_SLV_DEV_V += $(RTL_BRIDGE_ACE_DIR)/slave/ace_slv.v
ACE_SLV_DEV_H += $(VOBJ_DIR)/Vace_slv.h
ACE_SLV_DEV_LIB += $(VOBJ_DIR)/Vace_slv__ALL.a
ACE_SLV_RTL_TEST_OBJS += ace-slv-test.o $(VERILATED_O)
ACE_S_CACHE_SLV_VFIO_OBJS += test-pcie-ace-s-cache-slv-vfio.o

ALL_OBJS += $(ACE_SLV_RTL_TEST_OBJS) $(ACE_S_CACHE_SLV_VFIO_OBJS)

VFLAGS_RTL_BRIDGE_ACE_MST  = -I$(RTL_BRIDGE_ACE_COMON_DIR)
VFLAGS_RTL_BRIDGE_ACE_MST += -I$(RTL_BRIDGE_ACE_DIR)/master

ACE_MST_DEV_V += $(RTL_BRIDGE_ACE_DIR)/master/ace_mst.v
ACE_MST_DEV_H += $(VOBJ_DIR)/Vace_mst.h
ACE_MST_DEV_LIB += $(VOBJ_DIR)/Vace_mst__ALL.a
ACE_MST_RTL_TEST_OBJS += ace-mst-test.o $(VERILATED_O)
ACE_MST_SLV_LBACK_VFIO_OBJS += test-pcie-ace-mst-slv-loopback-vfio.o

ALL_OBJS += $(ACE_MST_RTL_TEST_OBJS) $(ACE_MST_SLV_LBACK_VFIO_OBJS)

TARGETS += ace-mst-test
TARGETS += test-pcie-ace-mst-slv-loopback-vfio

TARGETS += ace-slv-test
TARGETS += test-pcie-ace-s-cache-slv-vfio

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

include $(VERILATOR_ROOT)/include/verilated.mk

$(ACE_SLV_DEV_LIB): $(ACE_SLV_DEV_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_ACE_SLV) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f Vace_slv.mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f Vace_slv.mk verilated.o

$(ACE_MST_DEV_LIB): $(ACE_MST_DEV_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_ACE_MST) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f Vace_mst.mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f Vace_mst.mk verilated.o

$(ACE_SLV_RTL_TEST_OBJS): $(ACE_SLV_DEV_LIB)

$(ACE_MST_RTL_TEST_OBJS): $(ACE_MST_DEV_LIB)

ace-slv-test: $(ACE_SLV_RTL_TEST_OBJS) $(ACE_SLV_DEV_LIB) $(VERILATED_OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

ace-mst-test: $(ACE_MST_RTL_TEST_OBJS) $(ACE_MST_DEV_LIB) $(VERILATED_OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

test-pcie-ace-s-cache-slv-vfio: $(ACE_S_CACHE_SLV_VFIO_OBJS) $(OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

test-pcie-ace-mst-slv-loopback-vfio: $(ACE_MST_SLV_LBACK_VFIO_OBJS) $(OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(TARGETS:=.vcd)
	$(RM) -r $(VOBJ_DIR)
	$(RM) $(TARGETS)
