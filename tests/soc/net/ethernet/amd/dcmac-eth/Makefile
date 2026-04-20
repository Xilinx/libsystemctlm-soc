#
# Copyright (c) 2025 Advanced Micro Devices Inc.
#
# SPDX-License-Identifier: MIT

TOP := ../../../../../..
-include $(TOP)/.config.mk
include $(TOP)/tests/Rules.mk

CPPFLAGS += -I $(TOP)/ -I .
CXXFLAGS += -Wall -O0 -g

CHECK_OBJS += check-dcmac-eth.o
CHECK_OBJS += $(TOP)/trace/trace.o
CHECK_OBJS += $(TOP)/soc/net/ethernet/amd/dcmac/dcmac-eth.o
CHECK_OBJS += $(TOP)/soc/net/ethernet/amd/dcmac/dcmac-ethmac.o
ALL_OBJS += $(OBJS_COMMON) $(CHECK_OBJS)

TARGETS += check-dcmac-eth

################################################################################

all: $(TARGETS)

## Dep generation ##
-include $(ALL_OBJS:.o=.d)

check-dcmac-eth: $(CHECK_OBJS) $(OBJS_COMMON)
	$(LINK.cc) $^ $(LDLIBS) -o $@

clean:
	$(RM) $(ALL_OBJS) $(ALL_OBJS:.o=.d)
	$(RM) $(TARGETS:=.vcd)
	$(RM) $(TARGETS)
