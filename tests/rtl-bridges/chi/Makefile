#
# Copyright (c) 2020 Xilinx Inc.
# Written by Francisco Iglesias,
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

RTL_BRIDGE_CHI_DIR = ../../../rtl-bridges/pcie-host/chi/rtl
RTL_BRIDGE_CHI_COMMON_DIR = $(RTL_BRIDGE_CHI_DIR)/common
RTL_BRIDGE_CHI_INC_DIR = $(RTL_BRIDGE_CHI_COMMON_DIR)/include
RTL_BRIDGE_CHI_HNF_DIR = $(RTL_BRIDGE_CHI_DIR)/hn-f
RTL_BRIDGE_CHI_RNF_DIR = $(RTL_BRIDGE_CHI_DIR)/rn-f

include $(RTL_BRIDGE_CHI_COMMON_DIR)/files-bridge-chi-common.mk
include $(RTL_BRIDGE_CHI_HNF_DIR)/files-bridge-chi-hn-f.mk
include $(RTL_BRIDGE_CHI_RNF_DIR)/files-bridge-chi-rn-f.mk

VFLAGS_RTL_BRIDGE_CHI_MASTER +=-I$(RTL_BRIDGE_CHI_COMMON_DIR)
VFLAGS_RTL_BRIDGE_CHI_MASTER +=-I$(RTL_BRIDGE_CHI_INC_DIR)
VFLAGS_RTL_BRIDGE_CHI_MASTER +=-I$(RTL_BRIDGE_CHI_HNF_DIR)
VFLAGS_RTL_BRIDGE_CHI_MASTER +=-I$(RTL_BRIDGE_CHI_RNF_DIR)

CHI_HNF_DEV_V += $(RTL_BRIDGE_CHI_HN_F_V)
CHI_HNF_DEV_H += $(VOBJ_DIR)/Vchi_bridge_hn_top.h
CHI_HNF_DEV_LIB += $(VOBJ_DIR)/Vchi_bridge_hn_top__ALL.a
CHI_HNF_RTL_TEST_OBJS += chi-hnf-test.o $(VERILATED_O)
ALL_OBJS += $(CHI_HNF_RTL_TEST_OBJS) $(CHI_HNF_CHNLS_TEST_OBJS)

CHI_RNF_DEV_V += $(RTL_BRIDGE_CHI_RN_F_V)
CHI_RNF_DEV_H += $(VOBJ_DIR)/Vchi_bridge_rn_top.h
CHI_RNF_DEV_LIB += $(VOBJ_DIR)/Vchi_bridge_rn_top__ALL.a
CHI_RNF_RTL_TEST_OBJS += chi-rnf-test.o $(VERILATED_O)
ALL_OBJS += $(CHI_RNF_RTL_TEST_OBJS)

CHI_RNF_HNF_LBACK_TEST_OBJS += chi-rnf-hnf-loopback-test.o
CHI_RNF_HNF_LBACK_TEST_OBJS += $(VERILATED_O)
ALL_OBJS += $(CHI_RNF_HNF_LBACK_TEST_OBJS)

CHI_RNF_HNF_LBACK_VFIO_OBJS += test-pcie-chi-rnf-hnf-loopback-vfio.o

ALL_OBJS += $(CHI_SC_HNF_VFIO_OBJS) $(CHI_RNF_HNF_LBACK_VFIO_OBJS)

TARGETS += chi-hnf-test
TARGETS += chi-rnf-test
TARGETS += chi-rnf-hnf-loopback-test

TARGETS += test-pcie-chi-rnf-hnf-loopback-vfio

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

include $(VERILATOR_ROOT)/include/verilated.mk

$(CHI_HNF_DEV_LIB): $(CHI_HNF_DEV_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_CHI_MASTER) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f Vchi_bridge_hn_top.mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f Vchi_bridge_hn_top.mk verilated.o

$(CHI_RNF_DEV_LIB): $(CHI_RNF_DEV_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_CHI_MASTER) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f Vchi_bridge_rn_top.mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f Vchi_bridge_rn_top.mk verilated.o

$(CHI_HNF_RTL_TEST_OBJS): $(CHI_HNF_DEV_LIB)

$(CHI_RNF_RTL_TEST_OBJS): $(CHI_RNF_DEV_LIB)

$(CHI_RNF_HNF_LBACK_TEST_OBJS): $(CHI_HNF_DEV_LIB) $(CHI_RNF_DEV_LIB)

chi-hnf-test: $(CHI_HNF_RTL_TEST_OBJS) $(CHI_HNF_DEV_LIB) $(VERILATED_OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

chi-rnf-test: $(CHI_RNF_RTL_TEST_OBJS) $(CHI_RNF_DEV_LIB) $(VERILATED_OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

test-pcie-chi-rnf-hnf-loopback-vfio: $(CHI_RNF_HNF_LBACK_VFIO_OBJS) $(OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

chi-rnf-hnf-loopback-test: $(CHI_RNF_HNF_LBACK_TEST_OBJS) $(VERILATED_OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) $(CHI_RNF_DEV_LIB) $(CHI_HNF_DEV_LIB) -o $@

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(TARGETS:=.vcd)
	$(RM) -r $(VOBJ_DIR)
	$(RM) $(TARGETS)
