#
# Copyright (c) 2024 Zero ASIC.
# Written by Edgar E. Iglesias.
#
# SPDX-License-Identifier: MIT

-include ../../../.config.mk
include ../../Rules.mk

CPPFLAGS += -I ../../../ -I ../../ -I .
CXXFLAGS += -O3 -g

OBJS_COMMON += ../../../trace/trace.o
OBJS_COMMON += ../../test-modules/memory.o
ALL_OBJS += $(OBJS_COMMON) test-umi.o

TARGETS += test-umi-dw32   \
	   test-umi-dw64   \
	   test-umi-dw128  \
	   test-umi-dw256  \
	   test-umi-dw512  \
	   test-umi-dw1024

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

test-umi-%: test-umi.cc $(OBJS_COMMON)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -DDW=$(subst test-umi-dw,,$@) $^ -o $@ $(LDFLAGS) $(LDLIBS)

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(TARGETS)
	$(RM) $(TARGETS:=.d)
