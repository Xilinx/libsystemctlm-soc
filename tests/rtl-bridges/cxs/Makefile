#
# Copyright (c) 2020 Xilinx Inc.
# Written by Francisco Iglesias
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
VFLAGS += --unroll-count 100000
VFLAGS += --unroll-stmts 100000
VFLAGS += --output-split-cfuncs 500
# FIXME: These should really go away
VFLAGS += -Wno-PINMISSING -Wno-COMBDLY

VM_SC=1
# Enable tracing of internal signals with +trace
VM_TRACE=1

# Trade optimization for compile-time.
OPT_FAST ?= -O2 -fno-stack-protector -fno-var-tracking-assignments
OPT_SLOW ?= -O1 -fstrict-aliasing -fno-var-tracking-assignments
export OPT_FAST
export OPT_SLOW

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

RTL_BRIDGE_CXS_DIR = ../../../rtl-bridges/pcie-host/cxs/rtl
RTL_BRIDGE_CXS_COMMON_DIR = $(RTL_BRIDGE_CXS_DIR)/common
RTL_BRIDGE_CXS_INC_DIR = $(RTL_BRIDGE_CXS_COMMON_DIR)/include
RTL_BRIDGE_CXS_TOP_DIR = $(RTL_BRIDGE_CXS_DIR)/cxs

include $(RTL_BRIDGE_CXS_COMMON_DIR)/files-bridge-cxs-common.mk
include $(RTL_BRIDGE_CXS_TOP_DIR)/files-bridge-cxs.mk

VFLAGS_RTL_BRIDGE_CXS +=-I$(RTL_BRIDGE_CXS_COMMON_DIR)
VFLAGS_RTL_BRIDGE_CXS +=-I$(RTL_BRIDGE_CXS_INC_DIR)
VFLAGS_RTL_BRIDGE_CXS +=-I$(RTL_BRIDGE_CXS_TOP_DIR)

CXS_DEV_V += $(RTL_BRIDGE_CXS_V)
CXS_DEV_H += $(VOBJ_DIR)/Vcxs_bridge_top.h
CXS_DEV_LIB += $(VOBJ_DIR)/Vcxs_bridge_top__ALL.a

CXS_TEST_OBJS += cxs-test.o $(VERILATED_O)
ALL_OBJS += $(CXS_TEST_OBJS)

CXS_LBACK_TEST_OBJS += cxs-loopback-test.o $(VERILATED_O)
ALL_OBJS += $(CXS_LBACK_TEST_OBJS)

CXS_LBACK_VFIO_OBJS += test-pcie-cxs-loopback-vfio.o
ALL_OBJS += $(CXS_LBACK_VFIO_OBJS)

TARGETS += cxs-test
TARGETS += cxs-loopback-test
TARGETS += test-pcie-cxs-loopback-vfio

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

include $(VERILATOR_ROOT)/include/verilated.mk

$(CXS_DEV_LIB): $(CXS_DEV_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_CXS) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f Vcxs_bridge_top.mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f Vcxs_bridge_top.mk verilated.o

$(CXS_TEST_OBJS): $(CXS_DEV_LIB)

cxs-test: $(CXS_TEST_OBJS) $(CXS_DEV_LIB) $(VERILATED_OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

cxs-loopback-test: $(CXS_LBACK_TEST_OBJS) $(CXS_DEV_LIB) $(VERILATED_OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

test-pcie-cxs-loopback-vfio: $(CXS_LBACK_VFIO_OBJS) $(OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(TARGETS:=.vcd)
	$(RM) -r $(VOBJ_DIR)
	$(RM) $(TARGETS)
