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
CXXFLAGS += -O3 -g

GEN_FLAGS=../gen-axi-tg-test-cflags.py

OBJS_COMMON += ../../test-modules/memory.o
RAND_TG_TEST_OBJS += rand-tg-test.o
ALL_OBJS += $(OBJS_COMMON) $(RAND_TG_TEST_OBJS)

# Address width variations
TARGETS += axi3-aw24-dw32-idw8-axi-tg-test
TARGETS += axi3-aw32-dw32-idw8-axi-tg-test
TARGETS += axi3-aw40-dw32-idw8-axi-tg-test
TARGETS += axi3-aw44-dw32-idw8-axi-tg-test
TARGETS += axi3-aw52-dw32-idw8-axi-tg-test
TARGETS += axi3-aw64-dw32-idw8-axi-tg-test

# Data width variations
TARGETS += axi3-aw64-dw64-idw8-axi-tg-test

# Large DW tests
TARGETS += axi3-aw32-dw128-idw1-axi-tg-test
TARGETS += axi3-aw64-dw256-idw2-axi-tg-test
TARGETS += axi3-aw64-dw1024-idw2-axi-tg-test
TARGETS += axi4-aw32-dw128-idw1-axi-tg-test
TARGETS += axi4-aw64-dw256-idw2-axi-tg-test
TARGETS += axi4-aw64-dw1024-idw2-axi-tg-test

# ID Width variations
TARGETS += axi3-aw64-dw64-idw1-axi-tg-test
TARGETS += axi3-aw64-dw64-idw2-axi-tg-test
TARGETS += axi3-aw64-dw64-idw32-axi-tg-test
TARGETS += axi3-aw64-dw64-idw64-axi-tg-test

# Address width variations
TARGETS += axi4-aw24-dw32-idw8-axi-tg-test
TARGETS += axi4-aw32-dw32-idw8-axi-tg-test
TARGETS += axi4-aw40-dw32-idw8-axi-tg-test
TARGETS += axi4-aw44-dw32-idw8-axi-tg-test
TARGETS += axi4-aw52-dw32-idw8-axi-tg-test
TARGETS += axi4-aw64-dw32-idw8-axi-tg-test

# Data width variations
TARGETS += axi4-aw64-dw64-idw8-axi-tg-test

# ID Width variations
TARGETS += axi4-aw64-dw64-idw2-axi-tg-test
TARGETS += axi4-aw64-dw64-idw32-axi-tg-test
TARGETS += axi4-aw64-dw64-idw64-axi-tg-test

TARGETS += axi4-aw8-dw8-idw1-rand-tg-test
TARGETS += axi4-aw24-dw16-idw2-rand-tg-test
TARGETS += axi4-aw32-dw32-idw4-rand-tg-test
TARGETS += axi4-aw64-dw64-idw8-rand-tg-test
TARGETS += axi4-aw64-dw128-idw16-rand-tg-test
TARGETS += axi4-aw64-dw256-idw32-rand-tg-test
TARGETS += axi4-aw64-dw512-idw64-rand-tg-test
TARGETS += axi4-aw64-dw1024-idw128-rand-tg-test

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)
-include $(wildcard *-axi-tg-test.d)
-include $(wildcard *-rand-tg-test.d)

.PRECIOUS: %-axi-tg-test.o $(OBJS_COMMON)
%-axi-tg-test.o: axi-tg-test.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

%-axi-tg-test: %-axi-tg-test.o $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

%-rand-tg-test.o: rand-tg-test.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

%-rand-tg-test: %-rand-tg-test.o $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(wildcard *-tg-test.o) $(wildcard *-tg-test.d)
	$(RM) $(wildcard *-tg-test) $(wildcard *-tg-test.vcd)
	$(RM) $(TARGETS)
