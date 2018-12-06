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

CPPFLAGS += -I $(VOBJ_DIR)
CPPFLAGS += -I $(VERILATOR_ROOT)/include

CPPFLAGS += -I ../../ -I ../ -I .
CXXFLAGS += -Wall -O3 -g

AXILITE_DEV_V += axilite_dev.v
AXILITE_DEV_H += $(VOBJ_DIR)/Vaxilite_dev.h
AXILITE_DEV_LIB += $(VOBJ_DIR)/Vaxilite_dev__ALL.a
EXAMPLE_RTL_AXI4LITE_OBJS += example-rtl-axi4lite.o $(VERILATED_O)
ALL_OBJS += $(EXAMPLE_RTL_AXI4LITE_OBJS)

TARGETS += example-rtl-axi4lite

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

$(EXAMPLE_RTL_AXI4LITE_OBJS): $(AXILITE_DEV_H)

example-rtl-axi4lite: $(EXAMPLE_RTL_AXI4LITE_OBJS) $(AXILITE_DEV_LIB)
	$(LINK.cc) $^ $(LDLIBS) -o $@

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(TARGETS:=.vcd)
	$(RM) -r $(VOBJ_DIR)
	$(RM) $(TARGETS)
