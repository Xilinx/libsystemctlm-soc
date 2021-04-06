#
# Copyright (c) 2020 Xilinx Inc.
# Written by Edgar E. Iglesias,
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
VM_TRACE=0

# Trade optimization for compile-time.
OPT_FAST ?= -O2 -fno-stack-protector -fno-var-tracking-assignments
OPT_SLOW ?= -O1 -fstrict-aliasing -fno-var-tracking-assignments
export OPT_FAST
export OPT_SLOW

PCIE_EP_TOP = pcie_ep

CPPFLAGS += -I $(VOBJ_DIR)
CPPFLAGS += -I $(VERILATOR_ROOT)/include

CPPFLAGS += -I ../../../ -I ../../ -I .
CPPFLAGS += -I ../../../libremote-port/
CXXFLAGS += -Wall -O3 -g

OBJS_COMMON += ../../test-modules/memory.o
OBJS_COMMON += ../../../trace/trace.o
OBJS_COMMON += ../../../soc/pci/core/pci-device-base.o
OBJS_COMMON += ../../../libremote-port/safeio.o
OBJS_COMMON += ../../../libremote-port/remote-port-proto.o
OBJS_COMMON += ../../../libremote-port/remote-port-sk.o
OBJS_COMMON += ../../../libremote-port/remote-port-tlm.o
OBJS_COMMON += ../../../libremote-port/remote-port-tlm-wires.o
OBJS_COMMON += ../../../libremote-port/remote-port-tlm-memory-master.o
OBJS_COMMON += ../../../libremote-port/remote-port-tlm-memory-slave.o
OBJS_COMMON += ../../../libremote-port/remote-port-tlm-pci-ep.o
OBJS_COMMON += ../../../libremote-port/remote-port-tlm-ats.o

RTL_BRIDGE_PCIE_DIR = ../../../rtl-bridges/pcie-host/pcie/rtl/
RTL_BRIDGE_AXI_DIR = ../../../rtl-bridges/pcie-host/axi/rtl/

include $(RTL_BRIDGE_PCIE_DIR)/ep/files.mk
include $(RTL_BRIDGE_AXI_DIR)/common/files-bridge-axi-common.mk
include $(RTL_BRIDGE_AXI_DIR)/master/files-bridge-axi.mk
include $(RTL_BRIDGE_AXI_DIR)/slave/files-bridge-axi.mk

RTL_BRIDGE_PCIE_EP_LIB = $(VOBJ_DIR)/V$(PCIE_EP_TOP)__ALL.a

V_LDLIBS += $(RTL_BRIDGE_PCIE_EP_LIB)

VFLAGS_RTL_BRIDGE_PCIE_EP +=-I$(RTL_BRIDGE_PCIE_DIR)/ep/
VFLAGS_RTL_BRIDGE_PCIE_EP +=-I$(RTL_BRIDGE_AXI_DIR)/common/
VFLAGS_RTL_BRIDGE_PCIE_EP +=-I$(RTL_BRIDGE_AXI_DIR)/master/
VFLAGS_RTL_BRIDGE_PCIE_EP +=-I$(RTL_BRIDGE_AXI_DIR)/slave/

TEST_PCIE_PCIE_EP_OBJS += test-pcie-ep.o
TEST_PCIE_PCIE_EP_OBJS += $(VERILATED_O)

TEST_PCIE_EP_MASTER_VFIO_OBJS += test-pcie-ep-master-vfio.o
TEST_PCIE_EP_SLAVE_VFIO_OBJS += test-pcie-ep-slave-vfio.o

QEMU_PCIE_VFIO_OBJS += qemu-pcie-vfio.o

REFDESIGN_SIM_OBJS += refdesign-sim.o
REFDESIGN_SIM_OBJS += $(VERILATED_O)

ifeq "$(VM_TRACE)" "1"
VFLAGS += --trace
VERILATED_OBJS_COMMON += verilated_vcd_c.o
VERILATED_OBJS_COMMON += verilated_vcd_sc.o
CXXFLAGS += -DVM_TRACE=1
endif

VERILATED_OBJS_COMMON += $(OBJS_COMMON)

ALL_OBJS += $(VERILATED_OBJS_COMMON)

TARGETS += test-pcie-ep
TARGETS += test-pcie-ep-master-vfio
TARGETS += test-pcie-ep-slave-vfio
TARGETS += qemu-pcie-vfio
TARGETS += refdesign-sim

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

include $(VERILATOR_ROOT)/include/verilated.mk

$(VERILATED_O) $(RTL_BRIDGE_PCIE_EP_LIB): $(RTL_BRIDGE_PCIE_EP_V)
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFLAGS_RTL_BRIDGE_PCIE_EP) $^
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(PCIE_EP_TOP).mk
	$(MAKE) -C $(VOBJ_DIR) CXXFLAGS="$(CXXFLAGS)" -f V$(PCIE_EP_TOP).mk verilated.o

test-pcie-ep.o: $(RTL_BRIDGE_PCIE_EP_LIB)

test-pcie-ep: $(TEST_PCIE_PCIE_EP_OBJS) $(VERILATED_OBJS_COMMON) $(V_LDLIBS)
	$(LINK.cc) $^ $(LDLIBS) -o $@

test-pcie-ep-master-vfio: $(TEST_PCIE_EP_MASTER_VFIO_OBJS) $(OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

test-pcie-ep-slave-vfio: $(TEST_PCIE_EP_SLAVE_VFIO_OBJS) $(OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

qemu-pcie-vfio: $(QEMU_PCIE_VFIO_OBJS) $(OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

refdesign-sim.o: $(RTL_BRIDGE_PCIE_EP_LIB)

refdesign-sim: $(REFDESIGN_SIM_OBJS) $(VERILATED_OBJS_COMMON) $(V_LDLIBS)
	$(LINK.cc) $^ $(LDLIBS) -o $@

vfio: test-pcie-ep-slave-vfio test-pcie-ep-master-vfio qemu-pcie-vfio

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(TARGETS:=.o) $(TARGETS:=.d)
	$(RM) $(TARGETS:=.vcd)
	$(RM) -r $(VOBJ_DIR)
	$(RM) $(TARGETS)
