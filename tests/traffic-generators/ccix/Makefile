#
# Copyright (c) 2020 Xilinx Inc.
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

TARGETS += ccix-tg-test
TARGETS += ccix-rand-tg-test

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)
-include $(wildcard *-tg-test.d)
-include $(wildcard *-rand-tg-test.d)

.PRECIOUS: %-rand-tg-test.o  %-tg-test.o $(OBJS_COMMON)
%-tg-test.o: ccix-tg-test.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

%-tg-test: %-tg-test.o $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

%-rand-tg-test.o: ccix-rand-tg-test.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

%-rand-tg-test: %-rand-tg-test.o $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(wildcard *-tg-test.o) $(wildcard *-tg-test.d)
	$(RM) $(wildcard *-tg-test) $(wildcard *-tg-test.vcd)
	$(RM) $(TARGETS)
