#
# Copyright (c) 2018 Xilinx Inc.
# Written by Sakis Panou,
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
include ../../../tests/Rules.mk


# Variables
APP=config-parser-test
VALGRIND=valgrind
ARGS ?=

CPPFLAGS += -I ../../../
CPPFLAGS += -I ../../../tlm-bridges/
CPPFLAGS += -I ../../../traffic-generators/
CPPFLAGS += -I ../../../traffic-generators/config-parser/
CXXFLAGS += -O3 -g

VALGRINDFLAGS ?= --leak-check=full -v

CONFIG_PARSER_CC_OBJS= $(patsubst %.cc,%.o,$(wildcard ../../../traffic-generators/config-parser/*.cc))
CONFIG_PARSER_TEST_CC_OBJS=$(patsubst %.cc,%.o,$(wildcard *.cc))
OBJS=$(CONFIG_PARSER_CC_OBJS) $(CONFIG_PARSER_TEST_CC_OBJS)
DEPS=$(patsubst %.o,%.d,$(OBJS))

all: $(APP)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

$(APP): $(OBJS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(LDLIBS) $(OBJS) -o $(APP)

clean:
	$(RM) $(OBJS) $(DEPS) $(APP)

memcheck: $(APP)
	$(VALGRIND) $(VALGRINDFLAGS) ./$(APP) $(ARGS)
