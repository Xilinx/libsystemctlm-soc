#
# Copyright (c) 2018 Xilinx Inc.
# Written by Edgar E. Iglesias.
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

# Point to where the systemc library is installed
SYSTEMC ?= /usr/local/systemc-2.3.2/
SYSTEMC_INCLUDE ?=$(SYSTEMC)/include/
SYSTEMC_LIBDIR ?= $(SYSTEMC)/lib-linux64

CPPFLAGS = -I $(SYSTEMC)/include/
LDFLAGS = -L $(SYSTEMC_LIBDIR) -Wl,-rpath,$(SYSTEMC_LIBDIR)

# uncomment the following into .config.mk to enable static systemc linkage.
#LDLIBS_SYSTEMC += -Wl,-Bstatic -lsystemc -Wl,-Bdynamic
LDLIBS_SYSTEMC += -lsystemc
LDLIBS   += -pthread $(LDLIBS_SYSTEMC)

# For dependency generation
CFLAGS += -MMD
CXXFLAGS += -MMD

# For dependency generation
CXXFLAGS += -Wall -Wno-strict-overflow

# Verilator
VERILATOR ?=verilator

VERILATOR_ROOT?=$(shell $(VERILATOR) --getenv VERILATOR_ROOT 2>/dev/null || echo -n /usr/share/verilator)
VOBJ_DIR ?=obj_dir
VENV=SYSTEMC_INCLUDE=$(SYSTEMC_INCLUDE) SYSTEMC_LIBDIR=$(SYSTEMC_LIBDIR)
VERILATED_O=$(VOBJ_DIR)/verilated.o

# VM_TRACE enables internal signals tracing with verilator
# if the SystemC application supports it.
VM_TRACE?=0
# VM_COVERAGE enables coverage analysis if the SystemC application
# supports it.
#
# See man verilator for more information.
VM_COVERAGE?=0

VFLAGS += --MMD

verilated_%.o: $(VERILATOR_ROOT)/include/verilated_%.cpp

#
# This Rule describes howto run a verilog top module through verilator
# creating a Vmodule_ALL.a library and the corresponding header files
# for SystemC to use.
#
$(VOBJ_DIR)/V%__ALL.a $(VOBJ_DIR)/V%.h: %.v
	$(VENV) $(VERILATOR) $(VFLAGS) -sc $^
	$(MAKE) -C $(VOBJ_DIR) -f V$(<:.v=.mk) OPT="$(CXXFLAGS)"
	$(MAKE) -C $(VOBJ_DIR) -f V$(<:.v=.mk) OPT="$(CXXFLAGS)" verilated.o
