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

-include ../../../.config.mk
include ../../Rules.mk

CPPFLAGS += -I ../../../ -I ../../ -I .
CXXFLAGS += -g

GEN_FLAGS=../gen-axi-tg-test-cflags.py

OBJS_COMMON += ../../test-modules/memory.o
ALL_OBJS += $(OBJS_COMMON) $(RAND_TG_TEST_OBJS)

TARGETS += axilite-aw32-dw32-al-tg-test
TARGETS += axilite-aw64-dw64-al-tg-test

TARGETS += axilite-aw32-dw32-rand-tg-test
TARGETS += axilite-aw64-dw64-rand-tg-test

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)
-include $(wildcard *-al-tg-test.d)
-include $(wildcard *-rand-tg-test.d)

.PRECIOUS: %-al-tg-test.o $(OBJS_COMMON)
axilite-%-al-tg-test.o: axilite-tg-test.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

axilite-%-al-tg-test: axilite-%-al-tg-test.o $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

.PRECIOUS: %-rand-tg-test.o
%-rand-tg-test.o: axilite-rand-tg-test.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

%-rand-tg-test: %-rand-tg-test.o $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(wildcard *-tg-test.o) $(wildcard *-tg-test.d)
	$(RM) $(wildcard *-tg-test) $(wildcard *-tg-test.vcd)
	$(RM) $(TARGETS)
