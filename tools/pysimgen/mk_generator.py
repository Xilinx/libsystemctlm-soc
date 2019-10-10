"""
Copyright (c) 2019 Xilinx Inc.
Written by Francisco Iglesias.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""

import os
import sc_generator
import re

class MK_Generator:
	def __init__(self, args, sc_gen):
		self.args = args
		self.sc_gen = sc_gen

		self.cxx_flags = ''
		self.cflags = ''
		self.srcs = ''
		self.objs = ''

		self.sc_sim_rule = ''
		self.objs_rules = ''

		self.v_comp_vars = ''
		self.v_comp_rules = ''

	def gen_prologue(self):
		args = self.args

		p ='-include .config.mk\n'
		p +='SYSTEMC ?= {}\n'.format(args.systemc_path)
		p += 'SYSTEMC_INCLUDE ?=$(SYSTEMC)/include/\n'
		p += 'SYSTEMC_LIBDIR ?= $(SYSTEMC)/lib-linux64\n'
		p += 'CPPFLAGS = -I $(SYSTEMC)/include/\n'

		p += 'LDFLAGS = -L $(SYSTEMC_LIBDIR) '
		p += '-Wl,-rpath,$(SYSTEMC_LIBDIR)\n'

		p += 'LDLIBS_SYSTEMC += -lsystemc\n'
		p += 'LDLIBS   += -pthread $(LDLIBS_SYSTEMC)\n'
		p += 'CFLAGS += -MMD\n'
		p += 'CXXFLAGS += -MMD\n'
		p += 'CXXFLAGS += -Wall -Wno-strict-overflow\n'
		p += 'VERILATOR ?=' + args.verilator + '\n'

		p += 'VERILATOR_ROOT=$(shell $(VERILATOR) --getenv '
		p += 'VERILATOR_ROOT 2>/dev/null || echo -n '
		p += '/usr/share/verilator)\n'

		p += 'VOBJ_DIR ?={}/obj_dir\n'.format(args.outdir)

		p += 'VENV=SYSTEMC_INCLUDE=$(SYSTEMC_INCLUDE) '
		p += 'SYSTEMC_LIBDIR=$(SYSTEMC_LIBDIR)\n'

		p += 'VFLAGS=-Wno-fatal --pins-bv 2 --Mdir $(VOBJ_DIR)\n'

		self.prologue = p

	def gen_sc_sim_variables_rules(self):
		sc_gen = self.sc_gen

		#
		# CXXFLAGS
		#
		cxx_flags = ''

		for d in set(sc_gen.include_dirs):
			cxx_flags += 'CXXFLAGS += -I {}\n'.format(d)

		self.cxx_flags = cxx_flags

		if len(self.sc_gen.verilog_comp) > 0:
			self.cxx_flags += 'CXXFLAGS += -I $(VOBJ_DIR)\n'
			self.cxx_flags += 'CXXFLAGS += '
			self.cxx_flags += '-I $(VERILATOR_ROOT)/include\n'

		#
		# SRCS
		#
		if len(sc_gen.cc_files) > 0:
			self.srcs = 'SRCS = '
			for f in set(sc_gen.cc_files):
				self.srcs += '\\\n\t'
				self.srcs += f

		#
		# c files rules, CFLAGS, OBJS
		#
		if len(sc_gen.cc_files) > 0:
			p = re.compile('.c$')

			cflags = ''
			for d in set(sc_gen.include_dirs):
				cflags += 'CFLAGS += -I {}\n'.format(d)

			self.objs = 'OBJS = '
			for f in set(sc_gen.c_files):
				c_file = os.path.basename(f)
				dir = os.path.dirname(f)
				o_file = p.sub('.o', c_file)

				self.objs += '\\\n\t'
				self.objs += o_file

				# Generate rule
				r = '{}: {}\n'.format(o_file, f)
				r += '\t$(CC) $(CFLAGS) -c -o $@ $<\n\n'

				self.objs_rules += r
		#
		# sc_sim rule
		#
		self.sc_sim_rule = 'sc_sim:'
		if len(self.sc_gen.verilog_comp) > 0:
			is_first = True
			for v_comp_name in sc_gen.verilog_comp.keys():
				var_name = v_comp_name.upper()
				var_lib = ' $({0}_LIB)'.format(var_name)

				if not is_first:
					self.sc_sim_rule += ' '

				self.sc_sim_rule += var_lib

			self.sc_sim_rule += ' $(VOBJ_DIR)/verilated.o'

		if len(sc_gen.c_files) > 0:
			self.sc_sim_rule += ' $(OBJS)'

		self.sc_sim_rule += ' sc_sim.cc'

		if len(sc_gen.cc_files) > 0:
			self.sc_sim_rule += ' $(SRCS)'

		self.sc_sim_rule += '\n'

	def gen_verilog_comp_variables_rules(self):
		#
		# Generate verilog components makefile variables / rules
		#
		gen_verilator_o_rule = True
		for v_comp in self.sc_gen.verilog_comp.values():
			v_comp.gen_makefile()

			self.v_comp_vars += v_comp.var_files_v
			self.v_comp_vars += v_comp.var_files_h
			self.v_comp_vars += v_comp.var_lib
			self.v_comp_vars += v_comp.vflags_extra

			self.v_comp_rules += v_comp.rule

			#
			# Only generate the verilator.o rule once
			#
			if gen_verilator_o_rule:
				self.v_comp_rules += v_comp.verilator_o_rule
				gen_verilator_o_rule = False

	def gen_makefile(self):
		sc_gen = self.sc_gen
		filename = '{}/Makefile'.format(self.args.outdir)

		#
		# Generate
		#
		self.gen_prologue()
		self.gen_sc_sim_variables_rules()
		self.gen_verilog_comp_variables_rules()

		makefile_generated = [
			('[prologue]', self.prologue),
			('[cxx_flags]', self.cxx_flags),
			('[cflags]', self.cflags),
			('[srcs]', self.srcs),
			('[objs]', self.objs),
			('[v_comp_vars]', self.v_comp_vars),
			('[sc_sim_rule]', self.sc_sim_rule),
			('[objs_rules]', self.objs_rules),
			('[v_comp_rules]', self.v_comp_rules),
		]

		#
		# Debug
		#
		if self.args.verbose:
			print '\n[Generate {}]\n'.format(filename)

		if not self.args.quiet:
			for debug, output in makefile_generated:
				if self.args.verbose:
					print debug
				print output

		#
		# Write file
		#
		with open(filename, 'w') as f:
			for debug, output in makefile_generated:
				f.write(output + '\n')
