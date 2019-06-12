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

CPPFLAGS += -I ../../../ -I ../../ -I ../ -I .
CXXFLAGS += -O3 -g

TARGETS += pc-chi-ch-lcredits-test
TARGETS += pc-chi-requests-test
TARGETS += pc-chi-data-flits-test
TARGETS += pc-chi-snoop-requests-test
TARGETS += pc-chi-rsp-test
TARGETS += pc-chi-txn-structures-test
TARGETS += pc-chi-request-retry-test

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(wildcard *-test.d)

.PRECIOUS: %-test.o
%-test.o: %-test.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<

%-test: %-test.o
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

clean:
	$(RM) $(TARGETS:%=%.o)
	$(RM) $(TARGETS:%=%.d) $(wildcard *-test.vcd)
	$(RM) $(TARGETS)
