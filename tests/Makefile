#
# Copyright (c) 2018 Xilinx Inc.
# Written by Francisco Iglesias,
#            Edgar E. Iglesias
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

-include ../.config.mk

SUBDIRS_EXAMPLES += example-rtl-axi4
SUBDIRS_EXAMPLES += example-rtl-axi4lite
SUBDIRS_EXAMPLES += example-rtl-mixed

SUBDIRS += $(SUBDIRS_EXAMPLES)
SUBDIRS += tlm-modules
SUBDIRS += traffic-generators/axi/
SUBDIRS += traffic-generators/axilite/
SUBDIRS += traffic-generators/axis/
SUBDIRS += traffic-generators/ace/
SUBDIRS += traffic-generators/chi/
SUBDIRS += traffic-generators/ccix/
SUBDIRS += checkers/axi
SUBDIRS += checkers/axilite
SUBDIRS += checkers/ace
SUBDIRS += checkers/acelite
SUBDIRS += checkers/chi
SUBDIRS += rtl-bridges/axi
SUBDIRS += rtl-bridges/ace
SUBDIRS += rtl-bridges/chi
SUBDIRS += rtl-bridges/cxs
SUBDIRS += rtl-bridges/pcie

ifeq "$(HAVE_CONFIG_PARSER)" "y"
SUBDIRS += traffic-generators/config-parser/
SUBDIRS += traffic-generators/axi/cp-tg/
SUBDIRS += traffic-generators/axilite/cp-tg/
endif

PYTEST ?=py.test
PYTEST_HTML_ARGS ?=--self-contained-html --html=report.html

all: $(SUBDIRS)

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@

examples: $(SUBDIRS_EXAMPLES)

.PHONY: examples-run
examples-run: examples
	$(PYTEST) -s -m 'examples' $(PYTEST_ARGS)

check: $(SUBDIRS)
	$(PYTEST) $(PYTEST_ARGS)

check-report: $(SUBDIRS)
	$(PYTEST) $(PYTEST_HTML_ARGS) $(PYTEST_ARGS)
	zip report.zip report.html `find . -name \*vcd`

$(SUBDIRS:%=%-clean):
	$(MAKE) -C $(@:-clean=) clean

clean: $(SUBDIRS:%=%-clean)
	$(RM) -r pysimgen
