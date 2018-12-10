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

CPPFLAGS += -I ../../ -I ../ -I .
CXXFLAGS += -Wall -O3 -g

OBJS_COMMON += ../test-modules/memory.o
TLM_ALIGNER_TEST_OBJS += tlm-aligner-test.o
TLM_EXMON_TEST_OBJS += tlm-exmon-test.o
TLM_WRAP_EXPANDER_TEST_OBJS += tlm-wrap-expander-test.o
ALL_OBJS += $(OBJS_COMMON) $(TLM_ALIGNER_TEST_OBJS)
ALL_OBJS += $(TLM_EXMON_TEST_OBJS)
ALL_OBJS += $(TLM_WRAP_EXPANDER_TEST_OBJS)

TARGETS += tlm-aligner-test
TARGETS += tlm-exmon-test
TARGETS += tlm-wrap-expander-test

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

.PRECIOUS: $(OBJS_COMMON)
tlm-aligner-test: $(TLM_ALIGNER_TEST_OBJS) $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

tlm-exmon-test: $(TLM_EXMON_TEST_OBJS) $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

tlm-wrap-expander-test: $(TLM_WRAP_EXPANDER_TEST_OBJS) $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(TARGETS)
