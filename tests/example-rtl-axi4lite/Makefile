#
# Copyright (c) 2018 Xilinx Inc.
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

-include ../../.config.mk
include ../Rules.mk

VFLAGS=-Wno-fatal --pins-bv 2
VM_SC=0
VM_TRACE=1

ifeq "$(VM_TRACE)" "1"
VFLAGS += --trace -CFLAGS -DVL_TIME_STAMP64
CC_VERILATED_OBJS_COMMON += verilated_vcd_c.o
VERILATED_OBJS_COMMON += verilated_vcd_sc.o
CXXFLAGS += -DVM_TRACE=1 -DVL_TIME_STAMP64
endif

CPPFLAGS += -I $(VOBJ_DIR)
CPPFLAGS += -I $(CC_VOBJ_DIR)
CPPFLAGS += -I $(VERILATOR_ROOT)/include

CPPFLAGS += -I ../../ -I ../ -I .
CXXFLAGS += -Wall -O3 -g

AXILITE_DEV_DPI_H += $(CC_VOBJ_DIR)/Vaxilite_dev_dpi.h
AXILITE_DEV_H += $(VOBJ_DIR)/Vaxilite_dev.h
AXILITE_DEV_DPI_LIB += $(CC_VOBJ_DIR)/Vaxilite_dev_dpi__ALL.a
AXILITE_DEV_LIB += $(VOBJ_DIR)/Vaxilite_dev__ALL.a
EXAMPLE_RTL_AXI4LITE_OBJS += example-rtl-axi4lite.o $(VERILATED_O)
EXAMPLE_RTL_AXI4LITE_DPI_OBJS += example-rtl-axi4lite-dpi.o vtimestamp.o $(VERILATED_O)
ALL_OBJS += $(EXAMPLE_RTL_AXI4LITE_OBJS) $(EXAMPLE_RTL_AXI4LITE_DPI_OBJS)

TARGETS += example-rtl-axi4lite example-rtl-axi4lite-dpi

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

$(EXAMPLE_RTL_AXI4LITE_OBJS): $(AXILITE_DEV_H)
$(EXAMPLE_RTL_AXI4LITE_DPI_OBJS): $(AXILITE_DEV_DPI_H)

include $(VERILATOR_ROOT)/include/verilated.mk

example-rtl-axi4lite: $(EXAMPLE_RTL_AXI4LITE_OBJS) $(AXILITE_DEV_LIB) $(VERILATED_OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

example-rtl-axi4lite-dpi: $(EXAMPLE_RTL_AXI4LITE_DPI_OBJS) $(AXILITE_DEV_DPI_LIB) $(CC_VERILATED_OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(TARGETS:=.vcd)
	$(RM) -r $(VOBJ_DIR)
	$(RM) -r $(CC_VOBJ_DIR)
	$(RM) $(TARGETS)
