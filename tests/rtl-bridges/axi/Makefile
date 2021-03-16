#
# Copyright (c) 2019 Xilinx Inc.
# Written by Edgar E. Iglesias,
#            Alok Mistry.
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

AXI4_MASTER_TOP = axi4_master
AXI4LITE_MASTER_TOP = axi4_lite_master
AXI3_MASTER_TOP = axi3_master

AXI4_SLAVE_TOP = axi4_slave
AXI4LITE_SLAVE_TOP = axi4lite_slave
AXI3_SLAVE_TOP = axi3_slave

CPPFLAGS += -I $(VOBJ_DIR)
CPPFLAGS += -I $(VERILATOR_ROOT)/include

CPPFLAGS += -I ../../../ -I ../../ -I .
CXXFLAGS += -Wall -O3 -g

OBJS_COMMON += ../../test-modules/memory.o
OBJS_COMMON += ../../../trace/trace.o

RTL_BRIDGE_AXI_DIR = ../../../rtl-bridges/pcie-host/axi/rtl/

include $(RTL_BRIDGE_AXI_DIR)/common/files-bridge-axi-common.mk

include $(RTL_BRIDGE_AXI_DIR)/master/files-bridge-axi.mk
RTL_BRIDGE_AXI4_MASTER_LIB = $(VOBJ_DIR)/V$(AXI4_MASTER_TOP)__ALL.a
RTL_BRIDGE_AXI4LITE_MASTER_LIB = $(VOBJ_DIR)/V$(AXI4LITE_MASTER_TOP)__ALL.a
RTL_BRIDGE_AXI3_MASTER_LIB = $(VOBJ_DIR)/V$(AXI3_MASTER_TOP)__ALL.a

V_LDLIBS += $(RTL_BRIDGE_AXI4_MASTER_LIB)
V_LDLIBS += $(RTL_BRIDGE_AXI4LITE_MASTER_LIB)
V_LDLIBS += $(RTL_BRIDGE_AXI3_MASTER_LIB)

VFLAGS_RTL_BRIDGE_AXI_MASTER =-I$(RTL_BRIDGE_AXI_DIR)/common/
VFLAGS_RTL_BRIDGE_AXI_MASTER +=-I$(RTL_BRIDGE_AXI_DIR)/master/

TEST_PCIE_AXI4_MASTER_OBJS += $(VERILATED_O)

include $(RTL_BRIDGE_AXI_DIR)/slave/files-bridge-axi.mk
RTL_BRIDGE_AXI4_SLAVE_LIB = $(VOBJ_DIR)/V$(AXI4_SLAVE_TOP)__ALL.a
RTL_BRIDGE_AXI4LITE_SLAVE_LIB = $(VOBJ_DIR)/V$(AXI4LITE_SLAVE_TOP)__ALL.a
RTL_BRIDGE_AXI3_SLAVE_LIB = $(VOBJ_DIR)/V$(AXI3_SLAVE_TOP)__ALL.a

V_LDLIBS += $(RTL_BRIDGE_AXI4_SLAVE_LIB)
V_LDLIBS += $(RTL_BRIDGE_AXI4LITE_SLAVE_LIB)
V_LDLIBS += $(RTL_BRIDGE_AXI3_SLAVE_LIB)

VFLAGS_RTL_BRIDGE_AXI_SLAVE =-I$(RTL_BRIDGE_AXI_DIR)/common/
VFLAGS_RTL_BRIDGE_AXI_SLAVE +=-I$(RTL_BRIDGE_AXI_DIR)/slave/
TEST_PCIE_AXI4_SLAVE_OBJS += $(VERILATED_O)

TEST_PCIE_AXI4_MASTER_VFIO_OBJS += test-pcie-axi4-master-vfio.o
TEST_PCIE_AXI4_SLAVE_CDMA_VFIO_OBJS += test-pcie-axi4-slave-cdma-vfio.o

TEST_SLAVE_DIRECTED_OBJS += test-slave-directed.o
TEST_SLAVE_DIRECTED_OBJS += $(VERILATED_O)

ifeq "$(VM_TRACE)" "1"
VFLAGS += --trace
VERILATED_OBJS_COMMON += verilated_vcd_c.o
VERILATED_OBJS_COMMON += verilated_vcd_sc.o
CXXFLAGS += -DVM_TRACE=1
endif

VERILATED_OBJS_COMMON += $(OBJS_COMMON)

ALL_OBJS += $(TEST_PCIE_AXI4_MASTER_VFIO_OBJS)
ALL_OBJS += $(TEST_PCIE_AXI4_MASTER_OBJS)
ALL_OBJS += $(TEST_PCIE_AXI4LITE_MASTER_OBJS)
ALL_OBJS += $(TEST_PCIE_AXI3_MASTER_OBJS)
ALL_OBJS += $(TEST_PCIE_AXI4_SLAVE_OBJS)
ALL_OBJS += $(VERILATED_OBJS_COMMON)

TARGETS += axi3-test-pcie-master
TARGETS += axi4-test-pcie-master
TARGETS += axilite-test-pcie-master

TARGETS += axi3-test-pcie-slave
TARGETS += axi4-test-pcie-slave
TARGETS += axilite-test-pcie-slave

TARGETS += test-pcie-axi4-master-vfio
TARGETS += test-pcie-axi4-slave-cdma-vfio

TARGETS += test-slave-directed

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

include $(VERILATOR_ROOT)/include/verilated.mk

$(RTL_BRIDGE_AXI4_MASTER_LIB): $(RTL_BRIDGE_AXI4_MASTER_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_AXI_MASTER) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI4_MASTER_TOP).mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI4_MASTER_TOP).mk verilated.o

$(RTL_BRIDGE_AXI4LITE_MASTER_LIB): $(RTL_BRIDGE_AXI4LITE_MASTER_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_AXI_MASTER) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI4LITE_MASTER_TOP).mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI4LITE_MASTER_TOP).mk verilated.o

$(RTL_BRIDGE_AXI3_MASTER_LIB): $(RTL_BRIDGE_AXI3_MASTER_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_AXI_MASTER) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI3_MASTER_TOP).mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI3_MASTER_TOP).mk verilated.o


$(TEST_PCIE_AXI4_SLAVE_OBJS): $(RTL_BRIDGE_AXI4_SLAVE_LIB)

$(RTL_BRIDGE_AXI4_SLAVE_LIB): $(RTL_BRIDGE_AXI4_SLAVE_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_AXI_SLAVE) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI4_SLAVE_TOP).mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI4_SLAVE_TOP).mk verilated.o

$(TEST_PCIE_AXI4LITE_SLAVE_OBJS): $(RTL_BRIDGE_AXI4LITE_SLAVE_LIB)

$(RTL_BRIDGE_AXI4LITE_SLAVE_LIB): $(RTL_BRIDGE_AXI4LITE_SLAVE_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_AXI_SLAVE) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI4LITE_SLAVE_TOP).mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI4LITE_SLAVE_TOP).mk verilated.o


$(TEST_PCIE_AXI3_SLAVE_OBJS): $(RTL_BRIDGE_AXI3_SLAVE_LIB)

$(RTL_BRIDGE_AXI3_SLAVE_LIB): $(RTL_BRIDGE_AXI3_SLAVE_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_AXI_SLAVE) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI3_SLAVE_TOP).mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(AXI3_SLAVE_TOP).mk verilated.o

test-pcie-axi4-slave-cdma-vfio: $(TEST_PCIE_AXI4_SLAVE_CDMA_VFIO_OBJS) $(OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

test-pcie-axi4-master-vfio: $(TEST_PCIE_AXI4_MASTER_VFIO_OBJS) $(OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

GEN_FLAGS=../../traffic-generators/gen-axi-tg-test-cflags.py

.PRECIOUS: %-test-pcie-master.o
.PRECIOUS: %-test-pcie-slave.o
-include $(wildcard *-test-pcie-master.d)
-include $(wildcard *-test-pcie-slave.d)

%-test-pcie-master.o: test-pcie-master-axi.cc $(V_LDLIBS)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

%-test-pcie-master: %-test-pcie-master.o $(TEST_PCIE_AXI4_MASTER_OBJS) $(VERILATED_OBJS_COMMON) $(RTL_BRIDGE_AXI4_MASTER_LIB) $(RTL_BRIDGE_AXI3_MASTER_LIB) $(RTL_BRIDGE_AXI4LITE_MASTER_LIB) $(V_LDLIBS)
	$(LINK.cc) $^ $(LDLIBS) -o $@

%-test-pcie-slave.o: test-pcie-slave-axi.cc $(V_LDLIBS)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

%-test-pcie-slave: %-test-pcie-slave.o $(TEST_PCIE_AXI4_SLAVE_OBJS) $(VERILATED_OBJS_COMMON) $(RTL_BRIDGE_AXI4_SLAVE_LIB) $(V_LDLIBS)
	$(LINK.cc) $^ $(LDLIBS) -o $@

$(TEST_SLAVE_DIRECTED_OBJS): $(RTL_BRIDGE_AXI4_SLAVE_LIB)

test-slave-directed: $(TEST_SLAVE_DIRECTED_OBJS) $(VERILATED_OBJS_COMMON) $(RTL_BRIDGE_AXI4_SLAVE_LIB) $(V_LDLIBS)
	$(LINK.cc) $^ $(LDLIBS) -o $@

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(TARGETS:=.o) $(TARGETS:=.d)
	$(RM) $(TARGETS:=.vcd)
	$(RM) -r $(VOBJ_DIR)
	$(RM) $(TARGETS)
