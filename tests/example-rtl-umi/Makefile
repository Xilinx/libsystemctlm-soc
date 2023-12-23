#
# Copyright (c) 2024 Zero ASIC.
# Written by Edgar E. Iglesias.
#
# SPDX-License-Identifier: MIT
#
-include ../../.config.mk
include ../Rules.mk

UMI_DIR = ../../submodules/umi

# Create a SystemC executable
VFLAGS = -exe -sc -build
VFLAGS += -Wall -Wno-fatal --pins-bv 2
VFLAGS += --trace
VFLAGS += -y $(UMI_DIR)/umi/rtl/
VFLAGS += -y $(UMI_DIR)/submodules/lambdalib/ramlib/rtl/
VFLAGS += -y $(UMI_DIR)/submodules/lambdalib/stdlib/rtl/

CPPFLAGS += -I ../../../ -I ../../ -I .
CXXFLAGS += -Wall -O3 -g

ALL_OBJS += $(EXAMPLE_RTL_UMI_OBJS)

VFILES = umi_dev.v
SCFILES = example-rtl-umi.cc ../../trace/trace.cc

# Conditionalize build on having the UMI submodule.
ifeq ($(shell test -d $(UMI_DIR) && echo -n yes),yes)
    TARGETS += $(VOBJ_DIR)/example-rtl-umi
endif

all: $(TARGETS)

.PHONY: $(VOBJ_DIR)/example-rtl-umi
$(VOBJ_DIR)/example-rtl-umi:
	verilator -CFLAGS "$(CPPFLAGS)" $(VFLAGS) $(SCFILES) $(VFILES) -o example-rtl-umi

clean:
	$(RM) -r $(VOBJ_DIR)
	$(RM) $(TARGETS:=.vcd)
