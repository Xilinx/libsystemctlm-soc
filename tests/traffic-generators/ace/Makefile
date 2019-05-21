#
# Copyright (c) 2019 Xilinx Inc.
# Written by Francisco Iglesias.
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

CPPFLAGS += -I ../../../ -I ../../ -I .
CXXFLAGS += -O3 -g

GEN_FLAGS=../gen-axi-tg-test-cflags.py

OBJS_COMMON += ../../test-modules/memory.o
ALL_OBJS += $(OBJS_COMMON)

# Data width variations
TARGETS += ace-aw64-dw32-ace-tg-test
TARGETS += ace-aw64-dw64-ace-tg-test
TARGETS += ace-aw64-dw128-ace-tg-test
TARGETS += ace-aw64-dw256-ace-tg-test
TARGETS += ace-aw64-dw512-ace-tg-test
TARGETS += ace-aw64-dw1024-cl128-ace-tg-test

# Data width variations
TARGETS += ace-aw64-dw16-rand-tg-test
TARGETS += ace-aw64-dw32-rand-tg-test
TARGETS += ace-aw64-dw64-rand-tg-test
TARGETS += ace-aw64-dw128-rand-tg-test
TARGETS += ace-aw64-dw256-rand-tg-test
TARGETS += ace-aw64-dw512-rand-tg-test
TARGETS += ace-aw64-dw1024-cl128-rand-tg-test

# Address width variations
TARGETS += ace-aw24-dw64-rand-tg-test
TARGETS += ace-aw32-dw64-rand-tg-test
TARGETS += ace-aw40-dw64-rand-tg-test
TARGETS += ace-aw44-dw64-rand-tg-test
TARGETS += ace-aw52-dw64-rand-tg-test

# Cache line size variations
TARGETS += ace-aw24-dw32-cl16-rand-tg-test
TARGETS += ace-aw24-dw32-cl64-rand-tg-test
TARGETS += ace-aw32-dw64-cl32-rand-tg-test
TARGETS += ace-aw32-dw64-cl128-rand-tg-test
TARGETS += ace-aw32-dw64-cl256-rand-tg-test
TARGETS += ace-aw40-dw128-cl64-rand-tg-test
TARGETS += ace-aw40-dw128-cl128-rand-tg-test
TARGETS += ace-aw40-dw128-cl256-rand-tg-test
TARGETS += ace-aw44-dw64-cl128-rand-tg-test
TARGETS += ace-aw52-dw256-cl256-rand-tg-test

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)
-include $(wildcard *-ace-tg-test.d)
-include $(wildcard *-ace-rand-tg-test.d)

.PRECIOUS: %-ace-tg-test.o $(OBJS_COMMON)
%-ace-tg-test.o: ace-tg-test.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

%-ace-tg-test: %-ace-tg-test.o $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

%-rand-tg-test.o: ace-rand-tg-test.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

%-rand-tg-test: %-rand-tg-test.o $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(wildcard *-tg-test.o) $(wildcard *-tg-test.d)
	$(RM) $(wildcard *-tg-test) $(wildcard *-tg-test.vcd)
	$(RM) $(TARGETS)
