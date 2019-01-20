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

-include ../../../../.config.mk
include ../../../Rules.mk

CPPFLAGS += -I . -I ../../../ -I ../../../../
CXXFLAGS += -g

CPPFLAGS += -I ../../../../tlm-bridges/
CPPFLAGS += -I ../../../../traffic-generators/
CPPFLAGS += -I ../../../../traffic-generators/config-parser/

GEN_FLAGS=../../gen-axi-tg-test-cflags.py
OBJ_DIR = .obj_dir
OBJ_DIR_CREATED = $(OBJ_DIR)/.created

CP_SRCS=$(wildcard ../../../../traffic-generators/config-parser/*.cc)
CP_OBJS=$(patsubst %.cc, %.o, $(CP_SRCS))

OBJS_COMMON += ../../../test-modules/memory.o
OBJS_COMMON += $(addprefix $(OBJ_DIR)/, $(notdir $(CP_OBJS)))

ALL_OBJS += $(OBJS_COMMON)

# Address width variations
TARGETS += axi4-aw32-dw32-idw8-cp-tg-test

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)
-include $(wildcard *-axi-tg-test.d)
-include $(wildcard *-rand-tg-test.d)

$(OBJ_DIR_CREATED):
	mkdir -p $(dir $@)
	touch $@

$(OBJ_DIR)/%.o: ../../../../traffic-generators/config-parser/%.cc $(OBJ_DIR_CREATED)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<

.PRECIOUS: %-tg-test.o ../../../test-modules/memory.o
axi4-aw32-dw32-idw8-cp-tg-test.o: axi-cp-tg-test.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(shell $(GEN_FLAGS) $@) -c -o $@ $<

axi4-aw32-dw32-idw8-cp-tg-test: axi4-aw32-dw32-idw8-cp-tg-test.o $(OBJS_COMMON)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(wildcard *-tg-test.o) $(wildcard *-tg-test.d)
	$(RM) $(wildcard *-tg-test) $(wildcard *-tg-test.vcd)
	$(RM) $(TARGETS)
	$(RM) -r $(OBJ_DIR)
