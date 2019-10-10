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
import collections
import re
from registry import *

class VerilogComponent:

	def __init__(self, args, comp, comp_inst, comp_typename, comp_dir):
		self.args = args
		self.comp = comp
		self.comp_inst = comp_inst
		self.comp_typename = comp_typename
		self.comp_dir = comp_dir

		self.var_files_v = ''
		self.var_files_h = ''
		self.var_lib = ''
		self.vflags_extra = ''

	def get_comp_files(self):
		comp = self.comp
		comp_inst = self.comp_inst

		files = []
		inc_dirs = []

		if comp_inst is None:
			print 'Verilog component instance not found'
			sys.exit(1)

		filesets = comp.root.find('ipxact:fileSets', ns)
		if filesets is None:
			if self.args.verbose:
				print 'ipxact:fileSets not found!'
			return

		fs_ref = comp_inst.find('ipxact:fileSetRef', ns)
		if fs_ref is None:
			if self.args.verbose:
				print 'ipxact:fileSetRef not found!'
			return

		local_name = fs_ref.find('ipxact:localName', ns)
		if local_name is None:
			if self.args.verbose:
				print 'ipxact:localName not found!'
			return

		#
		# Find referenced fileSet
		#
		comp_fs = None
		for fs in filesets:
			fs_name = fs.find('ipxact:name', ns)
			if fs_name.text == local_name.text:
				comp_fs = fs
				break

		if comp_fs is not None:
			for f in comp_fs:
				name = f.find('ipxact:name', ns)
				is_include = f.find('ipxact:isIncludeFile', ns)

				if name is not None:
					file = self.comp_dir + name.text
					dir = os.path.dirname(
							os.path.abspath(file))

					if (is_include is None or
						is_include == False):
						files.append(
							os.path.abspath(file))

					if dir not in inc_dirs:
						inc_dirs.append(dir)

		return files, inc_dirs

	def gen_makefile(self):
		args = self.args
		files, inc_dirs = self.get_comp_files()

		var_name = self.comp_typename.upper()

		var_files_v = '{}_V = \\\n'.format(var_name)
		is_first = True

		for f in files:
			if not is_first:
				var_files_v += ' \\\n'

			var_files_v += '\t{}'.format(f)

			is_first = False

		var_files_v += '\n'

		#
		# Top is first file and that must match the comp name
		#
		var_files_h = '{}_H = {}.h\n'.format(var_name,
							self.comp_typename)

		var_lib = '{0}_LIB = $(VOBJ_DIR)/{1}__ALL.a\n'.format(var_name,
							self.comp_typename)
		if len(inc_dirs) > 0:
			vflags_extra = 'VFLAGS_{0} = '.format(var_name)
			for d in inc_dirs:
				vflags_extra += '-y ' + d + ' '
			vflags_extra += ' '

		rule = '$({0}_LIB): $({0}_V)\n'.format(var_name)

		rule += '\t$(VENV) $(VERILATOR) $(VFLAGS)'

		if len(inc_dirs) > 0:
			rule += ' $(VFLAGS_{0})'.format(var_name)

		rule +=' -sc $^\n'

		fmt = '\t$(MAKE) -C $(VOBJ_DIR) -f {0}.mk OPT="$(CXXFLAGS)"\n'
		rule += fmt.format(self.comp_typename)

		fmt  = '\t$(MAKE) -C $(VOBJ_DIR) -f {0}.mk '
		fmt += 'OPT="$(CXXFLAGS)" verilated.o\n\n'
		rule += fmt.format(self.comp_typename)

		self.var_files_v = var_files_v
		self.var_files_h = var_files_h
		self.var_lib = var_lib
		self.vflags_extra = vflags_extra + '\n'
		self.rule = rule

		#
		# Generated verilator.o rule
		#
		fmt  = '\t$(MAKE) -C $(VOBJ_DIR) -f {0}.mk '
		fmt += 'OPT="$(CXXFLAGS)" verilated.o\n\n'

		rule = '$(VOBJ_DIR)/verilated.o: $({0}_LIB)\n'.format(var_name)
		rule += fmt.format(self.comp_typename)

		self.verilator_o_rule = rule

class SC_Generator:

	def __init__(self, reg, platform, design, design_cfg, args):
		self.reg = reg
		self.platform = platform
		self.design = design
		self.design_cfg = design_cfg
		self.args = args

		#
		# Generated
		#
		self.translated_abs_def = {}
		self.class_signals = {}
		self.class_specialized = {}

		self.classes_generated = ''
		self.classes_bus_sig_inst_generated = ''

		self.classes_bus_sig_init = []

		self.class_inst_generated = ''

		self.class_init = []
		self.class_init_generated = ''

		self.bus_sig_cons_generated = ''
		self.specialized_cons = {}

		self.port_signals = {}
		self.ext_port_sig = {}

		self.adhoc_sig_init = []
		self.adhoc_sig_generated = ''
		self.adhoc_sig_cons_generated = ''
		self.reset_code_generated = ''
		self.end_of_elaboration = ''

		self.sc_main_prologue = self.gen_sc_main_prologue()
		self.sc_main_epilogue = self.gen_sc_main_epilogue()

		self.trace_sig = []

		self.verilog_comp = {}
		self.verilator_cmd_args = ''
		self.sc_time_res_generated = ''

		self.def_includes = ''
		self.def_namespaces = ''

		self.include_files_generated = ''
		self.include_files = []
		self.include_dirs = []

		self.c_files = []
		self.cc_files = []

		self.defines = {}
		self.defines_generated = ''
		self.referenced_define = []

		self.top_generated = ''
		self.top_instatiation = ''

		self.reset_signal = self.get_reset_signal()
		self.clock_signal = self.get_clock_signal()

	def get_reset_signal(self):
		params = self.platform.root.find('ipxact:parameters', ns)

		if params is not None:
			for p in params:
				name = p.find('ipxact:name', ns)
				if name.text == 'resetPort':
					reset_signal = p.find(
							'ipxact:value', ns)

					return reset_signal.text

		return ''

	def get_clock_signal(self):
		params = self.platform.root.find('ipxact:parameters', ns)

		if params is not None:
			for p in params:
				name = p.find('ipxact:name', ns)
				if name.text == 'clockPort':
					clock_signal = p.find(
							'ipxact:value', ns)

					return clock_signal.text

		return ''

	def get_run_time(self):
		params = self.platform.root.find('ipxact:parameters', ns)

		#
		# Extract run_time and the time unit (default ms)
		#
		run_time = None
		t_u = 'SC_MS'

		if params is not None:
			for p in params:
				name = p.find('ipxact:name', ns)
				if name.text == 'runTime':
					v = p.find('ipxact:value', ns)
					run_time = v.text
				elif name.text == 'runTimeTimeUnit':
					v = p.find('ipxact:value', ns)
					t_u = self.translate_time_unit(v.text)

		if run_time is not None:
			return '{}, {}'.format(run_time, t_u)
		else:
			return ''

	def gen_sc_main_prologue(self):
		sc_main = 'int sc_main(int argc, char *argv[])\n{\n'
		return sc_main

	def gen_sc_main_epilogue(self):
		epi = '\tsc_start('

		epi += self.get_run_time()

		epi += ');\n\n'
		epi += '\tif (trace_fp)\n\t{\n'
		epi += '\t\tsc_close_vcd_trace_file(trace_fp);\n\t}\n\n'

		epi += '\treturn 0;\n}'
		return epi

	def get_comp_view_from_design_cfg(self, comp_inst_name):
		root = self.design_cfg.root

		for view_cfg in root.findall('ipxact:viewConfiguration', ns):
			inst_name = view_cfg.find('ipxact:instanceName', ns)
			if inst_name.text == comp_inst_name.text:
				view = view_cfg.find('ipxact:view', ns)
				return view.attrib['viewRef']

		return None

	def translate_comp_inst(self, design_comp_inst):
		comp_inst_name = design_comp_inst.find(
						'ipxact:instanceName', ns)

		comp_ref = design_comp_inst.find('ipxact:componentRef', ns)

		comp_vlnv = to_vlnv(comp_ref.attrib)

		if self.args.verbose:
			print '\n[Translate componentInstance]: ', comp_vlnv

		comp_view = None
		if self.design_cfg is not None:
			comp_view = self.get_comp_view_from_design_cfg(
								comp_inst_name)

		if self.args.verbose:
			print '\n* View:', comp_view

		#
		# Get component
		#
		comp = self.reg.get_ipxact_object(comp_vlnv)

		#
		# Extract type from the component
		#
		model = comp.root.find('ipxact:model', ns)
		instantiations = model.find('ipxact:instantiations', ns)

		if comp_view is not None:
			# Get comp inst ref
			views = model.find('ipxact:views', ns)
			for view in views:
				name = view.find('ipxact:name', ns)
				if name.text == comp_view:
					break

			comp_inst_ref = view.find(
					'ipxact:componentInstantiationRef', ns)

			if comp_inst_ref is None:
				raise Exception('componentInstantiationRef' +
						' not found!')

			# Get comp inst
			tag = 'ipxact:componentInstantiation'
			for inst in instantiations.findall(tag, ns):
				name = inst.find('ipxact:name', ns)
				if name.text == comp_inst_ref.text:
					break

			assert(inst is not None)
			comp_inst = inst
		elif instantiations is not None:
			tag = 'ipxact:componentInstantiation'
			comp_inst = instantiations.find(tag, ns)
		else:
			comp_inst = None

		#
		# Generate class instatiation and initializer
		#
		c_inst, c_init = self.gen_class_inst_and_init(comp,
							comp_inst,
							comp_vlnv,
							design_comp_inst)

		self.class_inst_generated += c_inst
		self.class_init.append(c_init)

	def gen_class_inst_and_init(self, comp, comp_inst,
					comp_vlnv, design_comp_inst):

		comp_module_name = None
		comp_language = None

		comp_inst_name = design_comp_inst.find(
					'ipxact:instanceName', ns)

		if  comp_inst is not None:
			comp_module_name = comp_inst.find(
						'ipxact:moduleName', ns)

			comp_language = comp_inst.find('ipxact:language', ns)

		comp_params = self.get_comp_params(comp)

		typed_params, nontyped_params = self.get_mod_params(comp_inst)

		conf_elem_vals = self.get_conf_element_values(design_comp_inst)

		comp_typename = ''

		if comp_language is not None:
			if comp_language.text == 'Verilog':
				comp_typename = 'V'

		elif self.args.verbose:
			print '\t- Language not specified, default to SystemC'

		if comp_module_name is not None:
			comp_typename += comp_module_name.text
		else:
			name = comp.root.find('ipxact:name', ns)
			comp_typename += name.text

		#
		# Generate defines
		#
		for p_name, val in comp_params.items():
			define_name = '{}_{}'.format(comp_inst_name.text,
							p_name)

			self.defines[define_name] = val

		#
		# Override defines with the configureble elements value
		#
		for p_name, val in conf_elem_vals.items():
			define_name = '{}_{}'.format(comp_inst_name.text,
							p_name)

			if (define_name in self.defines and
				self.defines[define_name].endswith('"')):
				val = '"' + val + '"'

			self.defines[define_name] = val

		#
		# Add template params to the type
		#
		if len(typed_params) > 0:
			comp_typename += '<\n\t\t'

			#
			# generated define
			#
			is_first = True
			for p_name, val in typed_params.items():

				if is_first == False:
					comp_typename += ',\n\t\t'

				#
				# Check if we are referencing a component
				# parameter
				#
				define_name = '{}_{}'.format(
						comp_inst_name.text, val)

				if define_name not in self.defines:
					#
					# Assume val is the value to use here
					# (set the define val to this)
					#
					define_name = '{}_{}'.format(
							comp_inst_name.text,
							p_name)

					self.defines[define_name] = val

				comp_typename += define_name

				self.referenced_define.append(define_name)

				is_first = False

			comp_typename += '>'

		if self.args.verbose:
			print '* typename:', comp_typename, '\n'

		if comp_language is not None:
			xml = self.reg.get_ipxact_object_xml(comp_vlnv)
			comp_dir = os.path.dirname(xml) + '/'

			if comp_language.text != 'Verilog':
				self.extract_files_and_deps(comp,
							comp_inst,
							comp_dir)
			else:
				#
				# Add verilate generated include files
				#
				fmt = '#include <{}.h>\n'

				self.include_files.append(
					fmt.format(comp_typename))

				if comp_typename not in self.verilog_comp:
					v_comp = VerilogComponent(
								self.args,
								comp,
								comp_inst,
								comp_typename,
								comp_dir)

					self.verilog_comp[comp_typename] = (
									v_comp)

		#
		# Generate instance
		#
		c_inst_fmt = '\t{0} {1};\n'
		c_init_fmt = '\t{0}('

		#
		# Skip the sc_module_name on plain C++
		#
		is_first_arg = True
		if comp_language is None or comp_language.text != 'C++':
			c_init_fmt +='"{0}"'
			is_first_arg = False

		#
		# Constructor args
		#
		if comp_language is None or comp_language.text != 'Verilog':
			# Assume SystemC
			for val in nontyped_params.values():
				#
				# Check if we are referencing a component
				# parameter
				#
				define_name = '{}_{}'.format(
						comp_inst_name.text, val)

				if define_name in self.defines:
					#
					# Referincing a component parameter,
					# use the define name as parameter
					#
					val = define_name
					self.referenced_define.append(val)

				if is_first_arg:
					c_init_fmt += val
					is_first_arg = False
				else:
					c_init_fmt += ', ' + val

		c_init_fmt +=')'

		c_inst = c_inst_fmt.format(comp_typename, comp_inst_name.text)
		c_init = c_init_fmt.format(comp_inst_name.text)

		# Debug
		if self.args.verbose:
			print '\n* Generated instantiation:'
			print  c_inst
			print '* Generated initializer:'
			print c_init

			if comp_language is not None:
				m = '\n* Component language:'
				m += '{}'.format(comp_language.text)
			else:
				# Assume SystemC
				m = '\n* Component language: SystemC'

			print m

		return c_inst, c_init

	def get_comp_params(self, comp):
		comp_params = comp.root.find('ipxact:parameters', ns)

		params = collections.OrderedDict()

		if comp_params is not None:
			for p in comp_params:
				name = p.find('ipxact:name', ns)
				val = p.find('ipxact:value', ns)

				if name is not None and val is not None:
					is_str = False

					if ('type' not in p.attrib or
						p.attrib['type'] == 'string'):
						is_str = True

					if is_str == True:
						params[name.text] = '"'
						params[name.text] += val.text
						params[name.text] += '"'
					else:
						params[name.text] = val.text

		return params

	def get_conf_element_values(self, design_comp_inst):
		conf_el = collections.OrderedDict()

		comp_ref = design_comp_inst.find('ipxact:componentRef', ns)

		if comp_ref is not None:
			conf_elem_vals = comp_ref.find(
					'ipxact:configurableElementValues', ns)

			if conf_elem_vals is not None:
				for e in conf_elem_vals:
					name = e.attrib['referenceId']
					val = e.text

					conf_el[name] = val

		return conf_el

	def get_mod_params(self, comp_inst):
		module_params = None

		if comp_inst is not None:
			module_params = comp_inst.find('ipxact:moduleParameters', ns)

		typed_params = collections.OrderedDict()
		nontyped_params = collections.OrderedDict()

		if module_params is not None:
			for p in module_params:
				name = p.find('ipxact:name', ns)
				val = p.find('ipxact:value', ns)

				if name is not None and val is not None:
					attr = p.attrib
					key = 'usageType'

					is_str = False
					if ('dataType' not in p.attrib or
						p.attrib['dataType'] == 'string'):
						is_str = True

					if is_str == True:
						v = '"' + val.text + '"'
					else:
						v = val.text

					if key in attr and attr[key] == 'typed':
						typed_params[name.text] = v
					else:
						nontyped_params[name.text] = v

		return typed_params, nontyped_params

	def add_include_file(self, comp_dir, file):
		fmt = '#include <{}>\n'

		inc_file = os.path.basename(file)
		inc_dir = os.path.dirname(os.path.abspath(comp_dir + file))

		if self.args.verbose > 1:
			print '\t\t* Adding include file:', inc_file
			print '\t\t* Adding include dir:', inc_dir, '\n'

		self.include_dirs.append(inc_dir)
		self.include_files.append(fmt.format(inc_file))

	def extract_files_and_deps(self, comp, comp_inst, comp_dir):
		#
		# Extract include files
		#
		filesets = comp.root.find('ipxact:fileSets', ns)

		if filesets is None:
			if self.args.verbose:
				print '- ipxact:fileSets not found!'
			return

		fs_ref = comp_inst.find('ipxact:fileSetRef', ns)
		if fs_ref is None:
			if self.args.verbose:
				print '- ipxact:fileSetRef not found!'
			return

		local_name = fs_ref.find('ipxact:localName', ns)
		if local_name is None:
			if self.args.verbose:
				print '- ipxact:localName not found!'
			return

		#
		# Find referenced fileSet
		#
		comp_fs = None
		for fs in filesets:
			fs_name = fs.find('ipxact:name', ns)
			if fs_name.text == local_name.text:
				comp_fs = fs
				break

		if comp_fs is not None:
			if self.args.verbose:
				print '* Component files:'

			for f in comp_fs:
				name = f.find('ipxact:name', ns)
				is_include = f.find('ipxact:isIncludeFile', ns)

				if name is not None:
					if self.args.verbose:
						m = '\t- {}'.format(name.text)
						print m

					if (is_include is not None and
						is_include.text == 'true'):
							self.add_include_file(
								comp_dir,
								name.text)
					else:
						src_f = os.path.abspath(
							comp_dir + name.text)

						m = '\t\t* Adding '
						if src_f.endswith('.cc'):
							m += '.cc file: '
							m += '{}'.format(src_f)
							m += '\n'
							if self.args.verbose > 1:
								print m

							self.cc_files.append(
									src_f)

						elif src_f.endswith('.c'):
							m += '.c file:'
							m += '{}'.format(src_f)
							m += '\n'
							if self.args.verbose > 1:
								print m

							self.c_files.append(
									src_f)

				for dep in f.findall('ipxact:dependency', ns):
					inc_dir = os.path.abspath(
							comp_dir + dep.text)

					if self.args.verbose > 1:
						dep_str = '\t\t* [dependency]:'
						dep_str += 'Adding include dir:'
						print dep_str, inc_dir

					self.include_dirs.append(inc_dir)

		elif self.args.verbose:
			print 'ComponentInstance referenced fileSet not found!'

	def translate_component_instances(self):
		root = self.design.root

		comp_instances = root.find('ipxact:componentInstances', ns)

		for comp_inst in comp_instances:
			self.translate_comp_inst(comp_inst)

	def get_comp_by_design_instance_name(self, comp_inst_name, design = None):
		if design is None:
			design = self.design

		root = design.root

		comp_instances = root.find('ipxact:componentInstances', ns)

		for comp_inst in comp_instances:
			name = comp_inst.find('ipxact:instanceName', ns)
			if name.text == comp_inst_name:
				break

		comp_ref = comp_inst.find('ipxact:componentRef', ns)

		comp_vlnv = to_vlnv(comp_ref.attrib)

		comp = self.reg.get_ipxact_object(comp_vlnv)

		if comp is None:
			raise Exception('comp: ' + comp_vlnv + ' not found!')

		return comp

	#
	# From an abstractionDefinition
	#
	def get_wire_width(self, wire, logical_name):
		on_master = wire.find('ipxact:onMaster', ns)
		on_system = wire.find('ipxact:onSystem', ns)
		width = None

		# Check on_master
		if on_master is not None:
			width = on_master.find('ipxact:width', ns)

		# Check on_system
		if width is None and on_system is not None:
			width = on_system.find('ipxact:width', ns)

		if width is None:
			raise Exception('width not found on:',
					logical_name.text)

		return width

	def translate_specialized_classes(self):
		root = self.design.root
		comp_instances = root.find('ipxact:componentInstances', ns)

		for comp_inst in comp_instances:
			comp_ref = comp_inst.find('ipxact:componentRef', ns)

			if comp_ref.attrib['name'] in self.class_specialized:
				# Already generated
				continue

			if comp_ref.attrib['name'] == 'signal_inverter':
				c = 'class signal_inverter:\n'
				c += '\tpublic sc_core::sc_module\n'
				c += '{\n'
				c += 'public:\t\n'
				c += '\tSC_HAS_PROCESS(signal_inverter);\n'
				c += '\tsc_in<bool> in;\n'
				c += '\tsc_out<bool> out;\n'

				c += '\tsignal_inverter(sc_core::sc_module_name'
				c += ' name):\n'

				c += '\t\tsc_core::sc_module(name),\n'
				c += '\t\tin("in"),\n'
				c += '\t\tout("out")\n'
				c += '\t{\n\t\tSC_METHOD(invert_signal);\n'
				c += '\t\tsensitive << in;\n'
				c += '\t}\n'
				c += '\tvoid invert_signal(void)\n\t{\n'
				c += '\t\tout.write(!in.read());\n'
				c += '\t}\n'
				c += '};\n'
				self.class_specialized['signal_inverter'] = c
				self.classes_generated += c
			elif comp_ref.attrib['name'] == 'xilinx_zynqmp':
				inst_name = comp_inst.find(
						'ipxact:instanceName', ns)
				name = inst_name.text

				emu_bin = name + '_EMULATOR'
				emu_args = name + '_EMULATOR_ARGS'
				sk_descr = name + '_SK_DESCR'

				#
				# Generate the class definition
				#
				c = 'class emulator_launch:\n'
				c += '\tpublic sc_core::sc_module\n'
				c += '{\n'
				c += 'public:\t\n'

				c += '\temulator_launch(sc_core::sc_module_name'
				c += ' name):\n'

				c += '\t\tsc_core::sc_module(name)\n'
				c += '\t{\n'

				c += '\t\tsignal(SIGCHLD, '
				c += 'emulator_launch::sigchild_handler);\n'

				c += '\t\tif (fork() == 0) {\n'
				c += '\t\t\tstd::system('
				c += '{} " " {});\n'.format(emu_bin, emu_args)
				c += '\t\t}\n'
				c += '\t}\n'
				c += '\tstatic void sigchild_handler(int sig)\n'
				c += '\t{\n'
				c += '\t\texit(0);\n'
				c += '\t}\n'
				c += '};\n'
				self.class_specialized['emulator_launch'] = c
				self.classes_generated += c

				#
				# Generated include files
				#
				self.include_files.append('#include <signal.h>\n')

				#
				# Generated defines
				#
				self.referenced_define.append(emu_bin)
				self.referenced_define.append(emu_args)
				self.referenced_define.append(sk_descr)

				#
				# Instantiate the class
				#
				c_inst = '\temulator_launch emulator;\n'
				c_init = '\temulator("emulator")'

				self.class_inst_generated += c_inst
				self.class_init.append(c_init)

	def gen_end_of_elaboration(self):
		root = self.design.root
		comp_instances = root.find('ipxact:componentInstances', ns)

		for comp_inst in comp_instances:
			comp_ref = comp_inst.find('ipxact:componentRef', ns)
			if comp_ref.attrib['name'] == 'xilinx_zynqmp':

				comp_inst_name = comp_inst.find(
							'ipxact:instanceName', ns)

				inst = comp_inst_name.text

				code = '\t\t' + inst + '.tie_off();\n'

				self.end_of_elaboration += code
			elif comp_ref.attrib['name'] == 'TLMTrafficGenerator':
				#
				# look for start delay param
				#
				comp_inst_name = comp_inst.find(
							'ipxact:instanceName', ns)

				inst = comp_inst_name.text

				p = inst + '_' + 'START_DELAY'

				if p in self.defines:
					start_delay = self.defines[p]

					#
					# Get time unit
					#
					p = inst + '_' + 'START_DELAY_TIME_UNIT'
					def_val = self.defines[p]

					# rm '"'
					def_val = def_val[1:3]

					t_u = self.translate_time_unit(def_val)

					code  = '\t\t' + inst + '.setStartDelay'
					code += '(sc_time({}, {}));\n'.format(
							start_delay, t_u)

					self.end_of_elaboration += code

	def translate_abs_def(self, abs_def_vlnv):
		root = self.design.root

		if self.args.verbose:
			print '\n[Translate abstractionDefinition]: {}'.format(
				abs_def_vlnv)

		abs_def = self.reg.get_ipxact_object(abs_def_vlnv)
		bus_type = abs_def.root.find('ipxact:busType', ns)

		#
		# Start generating the class
		#
		c_name = '{}Signals'.format(bus_type.attrib['name'])
		fmt = 'class {}:\n\tpublic sc_core::sc_module\n{{\npublic:\n'
		c_generated = fmt.format(c_name)

		#
		# Generating the class signals
		#
		c_signals = []
		for port in abs_def.root.find('ipxact:ports', ns):
			logical_name = port.find('ipxact:logicalName', ns)
			if logical_name is None:
				raise Exception('logicalName not found on port')

			wire = port.find('ipxact:wire', ns)
			if wire is None:
				raise Exception('on_master not found on:',
						logical_name.text)

			width = self.get_wire_width(wire, logical_name)

			sig_name = logical_name.text
			if width.text == '1':
				fmt = '\tsc_signal<bool> {};\n'
				c_generated += fmt.format(sig_name)
			else:
				w = width.text
				fmt = '\tsc_signal<sc_bv<{}>> {};\n'
				c_generated += fmt.format(w, sig_name)

			c_signals.append(sig_name)

		last_port = port

		#
		# Constructor
		#
		fmt = '\n\t{}Signals(sc_core::sc_module_name name) :\n'
		c_generated += fmt.format(bus_type.attrib['name'])
		c_generated += '\t\tsc_core::sc_module(name),\n'

		for port in abs_def.root.find('ipxact:ports', ns):
			logical_name = port.find('ipxact:logicalName', ns)
			sig_name = logical_name.text

			sig_init = '\t\t{0}("{0}")'.format(sig_name)

			if port != last_port:
				sig_init += ','

			sig_init += '\n'

			c_generated += sig_init

		c_generated += '\t{}\n};\n'

		#
		# Store the generated class
		#
		self.translated_abs_def[abs_def_vlnv] = c_name
		self.class_signals[c_name] = c_signals
		self.classes_generated += c_generated

	def has_transactional_ports(self, abs_def_vlnv):
		root = self.design.root

		abs_def = self.reg.get_ipxact_object(abs_def_vlnv)

		for port in abs_def.root.find('ipxact:ports', ns):
			transactional_p = port.find('ipxact:transactional', ns)
			if transactional_p is not None:
				return True

		return False

	#
	# Translates abstractionDefinitions (non tlm) to classes with signals
	# (and instantiates the class for the interconnection)
	#
	def translate_non_tlm_abs_def(self, icn):
		root = self.design.root

		#
		# Get the abstractionDefinition
		#
		icn_inst_name = icn.find('ipxact:name', ns)
		active_if = icn.find('ipxact:activeInterface', ns)

		comp = self.get_comp_by_design_instance_name(
				active_if.attrib['componentRef'])

		bus_ifs = comp.root.find('ipxact:busInterfaces', ns)

		for bus_if in bus_ifs:
			name = bus_if.find('ipxact:name', ns)
			if name.text == active_if.attrib['busRef']:
				break

		abs_types = bus_if.find('ipxact:abstractionTypes', ns)
		abs_type = abs_types.find('ipxact:abstractionType', ns)
		abs_def_ref = abs_type.find('ipxact:abstractionRef', ns)

		abs_def_vlnv = to_vlnv(abs_def_ref.attrib)

		#
		# Don't generate a class for tlm inititator / target sockets
		#
		if self.has_transactional_ports(abs_def_vlnv):
			return

		#
		# Translate found abstractionDefinition
		#
		if abs_def_vlnv not in self.translated_abs_def:
			self.translate_abs_def(abs_def_vlnv)

		#
		# Trace generated signals
		#
		c_name = self.translated_abs_def[abs_def_vlnv]

		for sig in self.class_signals[c_name]:
			instance_sig = '{}.{}'.format(icn_inst_name.text, sig)
			self.trace_sig.append(instance_sig)

		#
		# Instantiate signal class
		#
		fmt = '\t{0} {1};\n'
		self.classes_bus_sig_inst_generated += fmt.format(
						c_name, icn_inst_name.text)
		#
		# Initialize signal class
		#
		fmt = '\t\t{0}("{0}")'
		self.classes_bus_sig_init.append(
				fmt.format(icn_inst_name.text))

	#
	# Fetch if port type is of type array or ptr
	#
	def get_trans_type_def(self, comp, port_ref):
		is_ptr = False
		array_idx = None

		port = self.get_comp_model_port(comp, port_ref)
		if port is None:
			return is_ptr, array_idx

		trans = port.find('ipxact:transactional', ns)
		if trans is None:
			return is_ptr, array_idx

		t_defs = trans.find('ipxact:transTypeDefs', ns)
		if t_defs is None:
			return is_ptr, array_idx

		t_def = t_defs.find('ipxact:transTypeDef', ns)
		if t_def is None:
			return is_ptr, array_idx

		t_name = t_def.find('ipxact:typeName', ns)
		if t_name is None:
			return is_ptr, array_idx

		if '*' in t_name.text:
				is_ptr = True;

		if '[]' in t_name.text:
			p = re.compile('\d+$')
			array_idx = p.search(port_ref).group()

		return is_ptr, array_idx

	def get_design_cfg_vlnv_from_instantiations(self,
						instantiations,
						d_cfg_inst_ref):

		d_cfg_inst_tag = 'ipxact:designConfigurationInstantiation'
		d_cfg_ref_tag = 'ipxact:designConfigurationRef'

		for d_cfg_inst in instantiations.findall(d_cfg_inst_tag, ns):
			name = d_cfg_inst.find('ipxact:name', ns)
			if name is None:
				raise Exception('design cfg inst without name')

			if name.text == d_cfg_inst_ref.text:

				d_cfg_ref = d_cfg_inst.find(d_cfg_ref_tag, ns)
				if d_cfg_ref is None:
					m = 'No design cfg ref in'
					m += 'design cfg inst'
					raise Exception(m)

				return to_vlnv(d_cfg_ref.attrib)

		return None

	def get_design_vlnv_from_instantiations(self,
						instantiations,
						d_inst_ref):

		d_inst_tag = 'ipxact:designInstantiation'
		d_ref_tag = 'ipxact:designRef'

		for d_inst in instantiations.findall(d_inst_tag, ns):
			name = d_inst.find('ipxact:name', ns)
			if name is None:
				raise Exception('design inst without name')

			if name.text == d_inst_ref.text:
				d_ref = d_inst.find(d_ref_tag, ns)

				if d_ref is None:
					m = 'No design ref in'
					m += 'design inst'
					raise Exception(m)

				return to_vlnv(d_ref.attrib)
		return None

	def get_inner_comp_port(self, comp_design, active_if, lookup_log_name):
		inst_name = active_if.attrib['componentRef']
		comp = self.get_comp_by_design_instance_name(
						inst_name, comp_design)

		bus_ifs = comp.root.find('ipxact:busInterfaces', ns)
		for bus_if in bus_ifs:
			name = bus_if.find('ipxact:name', ns)
			if name.text == active_if.attrib['busRef']:
				break

		abs_types = bus_if.find('ipxact:abstractionTypes', ns)
		abs_type = abs_types.find('ipxact:abstractionType', ns)
		port_maps = abs_type.find('ipxact:portMaps', ns)

		for p_map in port_maps:
			log_port = p_map.find('ipxact:logicalPort', ns)
			log_name = log_port.find('ipxact:name', ns)
			phys_port = p_map.find('ipxact:physicalPort', ns)
			phys_name = phys_port.find('ipxact:name', ns)

			if log_name.text == lookup_log_name.text:
				return phys_name.text

		return None

	#
	# If the component contains a design we assume it is hierarchical,
	# currently only supports one component view
	#
	def get_hier_bus_if_connection(self, comp, bus_if, log_name):
		comp_design = self.get_comp_design(comp)
		if comp_design is None:
			return None, None

		#
		# Traverse interconnections and look for an hierInterface
		#
		icns = comp_design.root.find('ipxact:interconnections', ns)
		if icns is not None:
			for icn in icns:
				hier_if = icn.find('ipxact:hierInterface', ns)
				if hier_if is not None:
					bus_ref= hier_if.attrib['busRef']
					name = bus_if.find('ipxact:name', ns)

					if name.text == bus_ref:
						tag = 'ipxact:activeInterface'
						a_if = icn.find(tag, ns)
						p_name = self.get_inner_comp_port(
								comp_design,
								a_if,
								log_name)
						i = a_if.attrib['componentRef']
						return i, p_name

		return None, None

	#
	# If the component contains a design we assume it is hierarchical,
	# currently only supports one component view
	#
	def get_hier_ext_port_connections(self, comp):
		comp_design = self.get_comp_design(comp)
		if comp_design is None:
			return None

		#
		# Traverse adhoc connections
		#
		adhoc_cons = comp_design.root.find(
				'ipxact:adHocConnections', ns)

		if adhoc_cons is None:
			return None

		e_p_ref_tag = 'ipxact:externalPortReference'
		i_p_ref_tag = 'ipxact:internalPortReference'

		inst_names = []
		for con in adhoc_cons:
			name, p_refs = self.get_adhoc_name_port_refs(con)
			e_p_ref = p_refs.findall(e_p_ref_tag, ns)

			if e_p_ref is not None:
				i_p_refs = p_refs.findall(i_p_ref_tag, ns)

				for ref in i_p_refs:
					comp_ref = ref.attrib['componentRef']
					inst_names.append(comp_ref)


		if len(inst_names) > 0:
			return inst_names

		return None

	def get_comp_design(self, comp):
		model = comp.root.find('ipxact:model', ns)
		if model is None:
			raise Exception('component without model')

		instantiations = model.find('ipxact:instantiations', ns)
		if instantiations is None:
			raise Exception('component without model')

		views = model.find('ipxact:views', ns)
		if views is None:
			raise Exception('component without views')

		view = views.find('ipxact:view', ns)
		if view is None:
			raise Exception('component without view')

		d_inst_ref = view.find('ipxact:designInstantiationRef', ns)
		if d_inst_ref is None:

			d_cfg_inst_ref = view.find(
				'ipxact:designConfigurationInstantiationRef',
				ns)

			if d_cfg_inst_ref is None:
				#
				# Component is not hierarchical (has no design
				# nor design cfg)
				#
				return None

			d_cfg_vlnv = self.get_design_cfg_vlnv_from_instantiations(
								instantiations,
								d_cfg_inst_ref)
			if d_cfg_vlnv is None:
				m = 'Did not find desing cfg inst ref '
				m += 'in the comp'
				raise Exception(m)

			d_cfg = self.reg.get_ipxact_object(d_cfg_vlnv)
			d_ref = d_cfg.root.find('ipxact:designRef', ns)
			d_vlnv = to_vlnv(d_ref)
		else:
			d_vlnv = self.get_design_vlnv_from_instantiations(
								instantiations,
								d_inst_ref)
			if d_vlnv is None:
				m = 'Did not find desing inst ref '
				m += 'in the comp'
				raise Exception(m)

		return self.reg.get_ipxact_object(d_vlnv)

	def translate_comp_bus_if_port_maps(self, icn):
		root = self.design.root
		fmt ='\t\t{}({});\n'

		icn_inst_name = icn.find('ipxact:name', ns)

		for active_if in icn.findall('ipxact:activeInterface', ns):

			comp_inst = active_if.attrib['componentRef']
			comp = self.get_comp_by_design_instance_name(comp_inst)

			bus_ifs = comp.root.find('ipxact:busInterfaces', ns)

			for bus_if in bus_ifs:
				name = bus_if.find('ipxact:name', ns)
				if name.text == active_if.attrib['busRef']:
					break

			abs_types = bus_if.find('ipxact:abstractionTypes', ns)
			abs_type = abs_types.find('ipxact:abstractionType', ns)

			#
			# Check if this is a transactional busInterface
			#
			abs_def_ref = abs_type.find('ipxact:abstractionRef', ns)
			abs_def_vlnv = to_vlnv(abs_def_ref.attrib)
			is_tlm = self.has_transactional_ports(abs_def_vlnv)

			port_maps = abs_type.find('ipxact:portMaps', ns)

			if is_tlm:
				p_map = port_maps.find('ipxact:portMap', ns)
				log_port = p_map.find('ipxact:logicalPort', ns)
				log_name = log_port.find('ipxact:name', ns)
				phys_port = p_map.find(
						'ipxact:physicalPort', ns)

				phys_name = phys_port.find('ipxact:name', ns)
				is_master = bus_if.find('ipxact:master', ns)

				socket = phys_name.text

				#
				# Check if it is a hierarchical comp and if
				# this is an hierarchical interface connected
				# to an inner component instance bus interface
				#
				inner_inst, p_name = self.get_hier_bus_if_connection(
							comp, bus_if, log_name)

				if inner_inst is not None and p_name is not None:
					socket = inner_inst + '.' + p_name

				#
				# Generate initiator / target names
				#
				s_fmt = '{}.{}'

				#
				# Check if it is an array or pointer (or both)
				#
				is_ptr, array_idx = self.get_trans_type_def(
							comp,
							phys_name.text)


				if array_idx is not None:
					p = re.compile('_\d+$')
					socket = p.sub('', socket)
					socket += '[' + array_idx + ']'


				if is_master is not None:
					tlm_init_socket = s_fmt.format(comp_inst,
									socket)
					if is_ptr:
						fmt = '\t\t{}->bind({});\n'

				else:
					if is_ptr:
						s_fmt = '*' + s_fmt

					tlm_tgt_socket = s_fmt.format(comp_inst,
									socket)

			elif port_maps is not None:
				for p_map in port_maps:
					log_port = p_map.find(
							'ipxact:logicalPort', ns)
					log_name = log_port.find(
							'ipxact:name', ns)
					phys_port = p_map.find(
							'ipxact:physicalPort', ns)
					phys_name = phys_port.find(
							'ipxact:name', ns)

					bus_sig = log_name.text
					comp_port_name = phys_name.text

					#
					# Check if it is a hierarchical comp
					# and if this is an hierarchical
					# interface connected to an inner
					# component instance bus interface
					#
					inner_inst, p_name = self.get_hier_bus_if_connection(
								comp,
								bus_if,
								log_name)

					if (inner_inst is not None and
						p_name is not None):

						comp_port_name = inner_inst
						comp_port_name += '.' + p_name

					icn_inst = icn_inst_name.text

					comp_port = '{}.{}'.format(comp_inst,
								comp_port_name)

					bus_sig = '{}.{}'.format(icn_inst,
								bus_sig)

					self.bus_sig_cons_generated += fmt.format(
								comp_port,
								bus_sig)

		#
		# TLM connections have 2 active_ifs (an init socket and a
		# target socket)
		#
		if is_tlm:
			if self.args.verbose > 1:
				m = '\n* Connect: {} -> {}\n'.format(
					tlm_init_socket, tlm_tgt_socket)
				print m

			self.bus_sig_cons_generated += fmt.format(
						tlm_init_socket, tlm_tgt_socket)

	def translate_non_tlm_abs_defs(self):
		root = self.design.root

		icns = root.find('ipxact:interconnections', ns)

		if icns is not None:
			# Generate signal classes
			for icn in icns:
				self.translate_non_tlm_abs_def(icn)

	def get_active_if_port(self, active_if):
		comp_inst = active_if.attrib['componentRef']
		comp = self.get_comp_by_design_instance_name(comp_inst)

		bus_ifs = comp.root.find('ipxact:busInterfaces', ns)

		bus_if = None
		for b_if in bus_ifs:
			name = b_if.find('ipxact:name', ns)
			if name.text == active_if.attrib['busRef']:
				bus_if = b_if
				break

		abs_types = bus_if.find('ipxact:abstractionTypes', ns)
		abs_type = abs_types.find('ipxact:abstractionType', ns)

		#
		# Check if this is a transactional busInterface
		#
		abs_def_ref = abs_type.find('ipxact:abstractionRef', ns)
		abs_def_vlnv = to_vlnv(abs_def_ref.attrib)

		port_maps = abs_type.find('ipxact:portMaps', ns)

		p_map = port_maps.find('ipxact:portMap', ns)
		phys_port = p_map.find('ipxact:physicalPort', ns)
		phys_name = phys_port.find('ipxact:name', ns)
		is_master = bus_if.find('ipxact:master', ns)

		socket = phys_name.text

		#
		# Check if it is an array or pointer (or both)
		#
		is_ptr, array_idx = self.get_trans_type_def(
					comp,
					phys_name.text)


		#
		# Generate initiator / target names
		#
		s_fmt = '{}.{}'

		if array_idx is not None:
			p = re.compile('_\d+$')
			socket = p.sub('', socket)
			socket += '[' + array_idx + ']'

		if is_ptr:
			s_fmt = '*' + s_fmt

		return s_fmt.format(comp_inst, socket)

	def translate_iconnect_i_sk(self, icn, iconnect_if, comp, master):
		as_ref = master.find('ipxact:addressSpaceRef', ns)
		base = as_ref.find('ipxact:baseAddress', ns)
		addr_spaces = comp.root.find('ipxact:addressSpaces', ns)

		addr_space = None
		for a_space in addr_spaces:
			name = a_space.find('ipxact:name', ns)
			if name.text == as_ref.attrib['addressSpaceRef']:
				addr_space = a_space
				break

		if addr_space is None:
			raise Exception('AddressSpace not found:',
					as_ref['addressSpaceRef'])

		range = addr_space.find('ipxact:range', ns)
		if range is None:
			raise Exception('range not found on:',
					as_ref['addressSpaceRef'])

		tlm_tgt_socket = ''
		for active_if in icn.findall('ipxact:activeInterface', ns):
			if active_if == iconnect_if:
				continue

			tlm_tgt_socket = self.get_active_if_port(active_if)

		#
		# Generate the connection
		#

		fmt = '\t\t{0}.memmap'
		fmt += '(0x{1}, 0x{2} - 1, ADDRMODE_RELATIVE, -1, {3});\n'

		iconnect_inst = iconnect_if.attrib['componentRef']
		base_addr = base.text[2:]
		region_size = range.text[2:]

		self.specialized_cons[iconnect_if.attrib['busRef']] = fmt.format(
								iconnect_inst,
								base_addr,
								region_size,
								tlm_tgt_socket)

	def translate_traffic_desc_icn(self, icn, random_traffic_if):
		tg_inst = None
		rt_inst = random_traffic_if.attrib['componentRef']
		rt_bus_ref = random_traffic_if.attrib['busRef']

		for active_if in icn.findall('ipxact:activeInterface', ns):
			if active_if == random_traffic_if:
				continue
			tg_inst = active_if.attrib['componentRef']


		#
		# Add the traffic description to the traffic generator
		#
		fmt = '\t\t{}.addTransfers({});\n'
		self.specialized_cons[rt_bus_ref] = fmt.format(tg_inst, rt_inst)

	def specialized_icn_translation(self, icn):

		for active_if in icn.findall('ipxact:activeInterface', ns):
			inst_name = active_if.attrib['componentRef']
			comp = self.get_comp_by_design_instance_name(inst_name)

			if comp is None:
				msg = 'Could not find component for instance:'
				raise Exception(msg, inst_name)

			name = comp.root.find('ipxact:name', ns)

			if self.args.verbose > 1:
				m = '* Attempt specialized_icn_translation on: '
				m += name.text
				print m

			if name.text == 'iconnect':
				bus_ifs = comp.root.find('ipxact:busInterfaces', ns)

				bus_if = None
				for b_if in bus_ifs:
					name = b_if.find('ipxact:name', ns)
					if name.text == active_if.attrib['busRef']:
						bus_if = b_if
						break

				if bus_if is None:
					msg = 'Could not find component busInterface:'
					raise Exception(msg, active_if.attrib['busRef'])

				master = bus_if.find('ipxact:master', ns)
				if master is not None:
					self.translate_iconnect_i_sk(
							icn, active_if, comp, master)

					if self.args.verbose > 1:
						m = '\t- Found specialized!'
						print m

					return True
			elif name.text == 'RandomTraffic':
				self.translate_traffic_desc_icn(icn, active_if)

				if self.args.verbose > 1:
					m = '\t- Found specialized!'
					print m

				return True

		return False

	def translate_interconnections(self):
		root = self.design.root

		icns = root.find('ipxact:interconnections', ns)

		if icns is not None:
			# Generate signals connections
			for icn in icns:
				if self.args.verbose:
					icn_inst_name = icn.find('ipxact:name', ns)
					m = '\n[Translate interconnection]: '
					m += icn_inst_name.text
					print m
				#
				# Try specialized translations
				#
				if not self.specialized_icn_translation(icn):
					self.translate_comp_bus_if_port_maps(icn)
					if self.args.verbose > 1:
						m = '\t- Translated non specialized!'
						print m

	def get_comp_model_port(self, comp, port_ref):
		model = comp.root.find('ipxact:model', ns)
		ports = model.find('ipxact:ports', ns)

		for p in ports:
			name = p.find('ipxact:name', ns)
			if name.text == port_ref:
				return p

		return None

	def get_port_driver(self, port_ref):
		root = self.platform.root

		model = root.find('ipxact:model', ns)
		ports = model.find('ipxact:ports', ns)

		found = False
		for p in ports:
			name = p.find('ipxact:name', ns)
			if name.text == port_ref:
				found = True
				break

		if found:
			drivers = p.find('ipxact:drivers', ns)
			if drivers is not None:
				return drivers.find('ipxact:driver', ns)

		return None

	def get_adhoc_name_port_refs(self, con):
		name = con.find('ipxact:name', ns)
		port_refs = con.find('ipxact:portReferences', ns)

		return name, port_refs

	def get_port_type(self, p_ref):
		comp_ref = p_ref.attrib['componentRef']
		port_ref = p_ref.attrib['portRef']

		comp = self.get_comp_by_design_instance_name(comp_ref)
		if comp is None:
			return None

		port = self.get_comp_model_port(comp, port_ref)
		if port is None:
			return None

		wire = port.find('ipxact:wire', ns)
		if wire is None:
			return None

		t_defs = wire.find('ipxact:wireTypeDefs', ns)
		if t_defs is None:
			return None

		t_def = t_defs.find('ipxact:wireTypeDef', ns)
		if t_def is None:
			return None

		return t_def.find('ipxact:typeName', ns)

	#
	# Adhoc con p_ref (internal port reference) to sig name
	#
	def to_sig_name(self, p_ref):
		comp_ref = p_ref.attrib['componentRef']
		port_ref = p_ref.attrib['portRef']

		fmt = '{}.{}'

		#
		# Get bit from the part select
		#
		bit = self.get_part_select_bit(p_ref)

		if bit is not None:
			fmt += '[' + bit + ']'

		return fmt.format(comp_ref, port_ref)

	def to_port_name(self, p_ref):
		return self.to_sig_name(p_ref)

	def adhoc_con_get_sc_signal(self, con):
		i_p_ref_tag = 'ipxact:internalPortReference'

		p_refs = con.find('ipxact:portReferences', ns)

		for p_ref in p_refs.findall(i_p_ref_tag, ns):
			p_type = self.get_port_type(p_ref)

			if p_type is not None and 'sc_signal' in p_type.text:
				return p_ref

		return None

	#
	# Extract bit from design adhoc con part select range
	#
	def get_part_select_bit(self, p_ref):
		#
		# If it is a a vector get the bit
		#
		part_sel = p_ref.find('ipxact:partSelect', ns)
		if part_sel is None:
			return None

		range = part_sel.find('ipxact:range', ns)
		if range is None:
			return None

		#
		# Only support one bit ranges when connecting adhoc connections
		#
		left = range.find('ipxact:left', ns)
		if range is None:
			return None

		return left.text

	def translate_adhoc_connections(self):
		root = self.design.root
		processed_cons = []

		adhoc_cons = root.find('ipxact:adHocConnections', ns)

		if adhoc_cons is None:
			if self.args.verbose:
				print ' - No adHocConnections found!'
			return

		if self.args.verbose:
			print '\n[Translate adHocConnections]'

		#
		# Look for connections not requiring a signal generation (one
		# of the ports is of type sc_signal)
		#
		if self.args.verbose > 1:
			print '\n* Translate specialized connections'

		for con in adhoc_cons:
			sig_p_ref = self.adhoc_con_get_sc_signal(con)

			if sig_p_ref is not None:
				#
				# There is port of type sc_signal
				#
				p_refs = con.find('ipxact:portReferences', ns)
				tag = 'ipxact:internalPortReference'

				for p_ref in p_refs.findall(tag, ns):

					if p_ref is not sig_p_ref:
						port = self.to_port_name(p_ref)

						sig = self.to_sig_name(sig_p_ref)

						fmt = '\t\t{}({});\n'
						self.adhoc_sig_cons_generated += \
							fmt.format(port, sig)

				processed_cons.append(con)

		#
		# Generate signals for all external ports first
		#
		if self.args.verbose > 1:
			print '* Translate external port connections'

		for con in adhoc_cons:

			if con in processed_cons:
				continue

			name, p_refs = self.get_adhoc_name_port_refs(con)
			refs = p_refs.findall('ipxact:externalPortReference', ns)
			num_ext = len(refs)

			for p_ref in p_refs.findall(
					'ipxact:externalPortReference', ns):

				port_ref = p_ref.attrib['portRef']
				driver = self.get_port_driver(port_ref)

				if num_ext == 1:
					#
					# Generate a signal for the ext port
					#
					port_sig = port_ref
				else:
					#
					# Here we need a signal for where to
					# connect multiple ext ports
					#
					port_sig = name.text

				if port_ref not in self.ext_port_sig:
					self.ext_port_sig[port_ref] = (port_sig,
									driver)

		#
		# Generate signals for the internal ports
		#
		if self.args.verbose > 1:
			print '* Translate internal port connections'

		for con in adhoc_cons:

			if con in processed_cons:
				continue

			name, p_refs = self.get_adhoc_name_port_refs(con)
			ext_port_ref = p_refs.find(
					'ipxact:externalPortReference', ns)

			# If one of the ports is already connected to a signal:
			# connect all other ports to the same signal
			# (adhoc_con_sig) in this adHocConnection
			adhoc_con_sig = self.get_adhoc_con_signal(p_refs)

			for p_ref in p_refs.findall('ipxact:internalPortReference', ns):
				comp_ref = p_ref.attrib['componentRef']
				port_ref = p_ref.attrib['portRef']

				port = '{}.{}'.format(comp_ref, port_ref)

				if port not in self.port_signals:
					#
					# Check if it is a hierarchical comp and if
					# this is an external port connected to multiple
					# inner component instance port
					#
					comp = self.get_comp_by_design_instance_name(
									comp_ref)
					inner_instances = self.get_hier_ext_port_connections(
									comp)

					if ext_port_ref is not None:
						# Connect all signals in this
						# adHocCon to the ext port's
						# signal

						ext_p = ext_port_ref.attrib['portRef']
						sig, d = self.ext_port_sig[ext_p]

						if inner_instances is not None:
							n_fmt = '{}.{}.{}'
							for inst in inner_instances:
								p_name = n_fmt.format(
									comp_ref,
									inst,
									port_ref)

								self.port_signals[p_name] = sig
						else:
							self.port_signals[port] = sig

					elif adhoc_con_sig is not None:
						if inner_instances is not None:
							n_fmt = '{}.{}.{}'
							for inst in inner_instances:
								p_name = n_fmt.format(
									comp_ref,
									inst,
									port_ref)

								self.port_signals[p_name] = adhoc_con_sig
						else:
							self.port_signals[port] = adhoc_con_sig
					else:
						if inner_instances is not None:
							n_fmt = '{}.{}.{}'
							for inst in inner_instances:
								p_name = n_fmt.format(
									comp_ref,
									inst,
									port_ref)

								self.port_signals[p_name] = name.text
						else:
							self.port_signals[port] = name.text

		for port, sig in self.port_signals.items():
			fmt = '\t\t{}({});\n'
			self.adhoc_sig_cons_generated += fmt.format(port, sig)

	def get_adhoc_con_signal(self, p_refs):
		for p_ref in p_refs.findall('ipxact:internalPortReference', ns):
			comp_ref = p_ref.attrib['componentRef']
			port_ref = p_ref.attrib['portRef']

			port = '{}.{}'.format(comp_ref, port_ref)

			if port in self.port_signals:
				return self.port_signals[port]

		return None

	def gen_adhoc_signal_inst_and_init(self):
		#
		# Parse external port signals and look for the clock and reset
		#
		sc_signals = {}

		for sig in self.ext_port_sig.values():
			if sig not in sc_signals:
				sc_signals[sig] = True

		#
		# Add internal port signals
		#
		for sig in self.port_signals.values():
			found = False

			for s, d in sc_signals.keys():
				if s == sig:
					found = True

			if found == False:
				sig_key = (sig, None)
				sc_signals[sig_key] = True

		for sig, driver in sc_signals.keys():

			single_shot_driver = None
			clock_driver = None

			if driver is not None:
				clock_driver = driver.find(
						'ipxact:clockDriver', ns)

				if clock_driver is None:
					tag = 'ipxact:singleShotDriver'

					single_shot_driver = driver.find(
								tag, ns)

			#
			# Parse clockDriver
			#
			is_clock = False
			is_reset = False

			if clock_driver is not None:
				self.parse_clock_driver(clock_driver, sig)
				is_clock = True

			elif sig == self.clock_signal:
				self.parse_clock_driver_with_params(sig)
				is_clock = True

			#
			# Generated singleShotinstatiation code
			#
			if single_shot_driver is not None:
				self.gen_reset_code(single_shot_driver, sig)
				is_reset = True

			elif sig == self.reset_signal:
				self.gen_reset_code_with_params(sig)
				is_reset = True

			if is_clock == False and is_reset == False:
				# Generate a signal
				fmt = '\tsc_signal<bool> {0};\n'
				self.adhoc_sig_generated += fmt.format(sig)

				fmt = '\t\t{0}("{0}")'
				self.adhoc_sig_init.append(fmt.format(sig))

			self.trace_sig.append(sig)

	def parse_clock_driver_with_params(self, sig):
		params = self.platform.root.find('ipxact:parameters', ns)

		for p in params:
			n = p.find('ipxact:name', ns)
			v = p.find('ipxact:value', ns)

			if n.text == 'clockPeriod':
				period_val = v.text
			elif n.text == 'clockPulseDuration':
				pulse_dur = v.text
			elif n.text == 'clockTimeUnit':
				t_u = self.translate_time_unit(v.text)

		duty_cycle = float(pulse_dur) / float(period_val)

		period = int(float(period_val))

		#
		# Generate sc_clock
		#
		fmt = '\tsc_clock {0};\n'
		self.adhoc_sig_generated += fmt.format(sig)

		fmt = '\t\t{0}("{0}", '
		fmt += 'sc_time({1}, {2}), {3})'
		self.adhoc_sig_init.append(
			fmt.format(sig, period, t_u, duty_cycle))

	def parse_clock_driver(self, clock_driver, sig):
		period_tag = 'ipxact:clockPeriod'
		duration_tag = 'ipxact:clockPulseDuration'

		period_e = clock_driver.find(period_tag, ns)
		pulse_duration_e = clock_driver.find(duration_tag, ns)

		period_val = float(period_e.text)
		pd = float(pulse_duration_e.text)

		#
		# Fixup time units
		#
		per_t_u = 'SC_NS'
		if 'units' in period_e.attrib:
			if period_e.attrib['units'] == 'ps':
				per_t_u = 'SC_PS'

		pd_t_u = 'SC_NS'
		if 'units' in pulse_duration_e.attrib:
			if pulse_duration_e.attrib['units'] == 'ps':
				pd_t_u = 'SC_PS'

		if pd_t_u != per_t_u:
			if per_t_u == 'SC_NS':
				per_t_u = 'SC_PS'
				period_val *= 1000
			else:
				# pd_t_u is 'SC_PS'
				pd_t_u = 'SC_PS'
				pd *= 1000

		#
		# Calculate duty cycle
		#
		duty_cycle = pd / period_val

		period = int(period_val)
		duty_cycle

		#
		# Generate sc_clock
		#
		fmt = '\tsc_clock {0};\n'
		self.adhoc_sig_generated += fmt.format(sig)

		fmt = '\t\t{0}("{0}", '
		fmt += 'sc_time({1}, {2}), {3})'
		self.adhoc_sig_init.append(
			fmt.format(sig, period, per_t_u, duty_cycle))

	def gen_reset_code(self, single_shot_driver, sig):
		offset_e = single_shot_driver.find(
					'ipxact:singleShotOffset', ns)
		val_e = single_shot_driver.find(
					'ipxact:singleShotValue', ns)
		duration_e = single_shot_driver.find(
					'ipxact:singleShotDuration', ns)

		offset = int(float(offset_e.text))
		val = int(val_e.text)
		dur = int(float(duration_e.text))

		#
		# Setup time units
		#
		offset_t_u = 'SC_NS'
		if 'units' in offset_e.attrib:
			if offset_e.attrib['units'] == 'ps':
				offset_t_u = 'SC_PS'

		dur_t_u = 'SC_NS'
		if 'units' in duration_e.attrib:
			if duration_e.attrib['units'] == 'ps':
				dur_t_u = 'SC_PS'

		reset_code = ''

		v_assert = 'true' if val == '1' else 'false'
		v_deassert = 'false' if val == '1' else 'true'

		if offset > 0:
			fmt = '\ttop.{}.write({});\n'
			reset_code += fmt.format(sig, v_deassert)

			fmt = '\tsc_start({}, {});\n'
			reset_code += fmt.format(offset, offset_t_u)

		reset_code += '\t{top.}.write({});\n'.format(sig, v_assert)
		reset_code += '\tsc_start({}, {});\n'.format(dur, dur_t_u)
		reset_code += '\t{top.}.write({});\n'.format(sig, v_deassert)

		self.reset_code_generated = reset_code

		fmt = '\tsc_signal<bool> {0};\n'
		self.adhoc_sig_generated += fmt.format(sig)

		fmt = '\t\t{0}("{0}")'
		self.adhoc_sig_init.append(fmt.format(sig))

	def translate_time_unit(self, t_u):
		sc_t_u = { 'ps': 'SC_PS', 'us': 'SC_US', 'ms': 'SC_MS' }
		return sc_t_u[t_u] if t_u in sc_t_u else 'SC_NS'

	def gen_reset_code_with_params(self, sig):
		params = self.platform.root.find('ipxact:parameters', ns)

		for p in params:
			n = p.find('ipxact:name', ns)
			v = p.find('ipxact:value', ns)

			if n.text == 'singleShotOffset':
				offset = int(v.text)
			elif n.text == 'singleShotDuration':
				dur = v.text
			elif n.text == 'singleShotValue':
				val = v.text
			elif n.text == 'singleShotTimeUnit':
				t_u = self.translate_time_unit(v.text)

		reset_code = ''

		v_assert = 'true' if val == '1' else 'false'
		v_deassert = 'false' if val == '1' else 'true'

		if offset > 0:
			fmt = '\ttop.{}.write({});\n'
			reset_code += fmt.format(sig, v_deassert)

			fmt = '\tsc_start({}, {});\n'
			reset_code += fmt.format(offset, t_u)

		reset_code += '\ttop.{}.write({});\n'.format(sig, v_assert)
		reset_code += '\tsc_start({}, {});\n'.format(dur, t_u)
		reset_code += '\ttop.{}.write({});\n'.format(sig, v_deassert)

		self.reset_code_generated = reset_code

		#
		# Generate rst signal
		#
		fmt = '\tsc_signal<bool> {0};\n'
		self.adhoc_sig_generated += fmt.format(sig)

		fmt = '\t\t{0}("{0}")'
		self.adhoc_sig_init.append(fmt.format(sig))

	def gen_sig_tracing(self):

		self.signal_tracing = '\tsc_trace_file *trace_fp;\n'
		self.signal_tracing += '\ttrace_fp = '
		self.signal_tracing += 'sc_create_vcd_trace_file("trace");\n\n'

		for sig in self.trace_sig:
			fmt = '\tsc_trace(trace_fp,\n'
			fmt += '\t\ttop.{0},\n'
			fmt += '\t\ttop.{0}.name());\n'
			self.signal_tracing += fmt.format(sig)

	def gen_verilator_cmd_args(self):
		self.verilator_cmd_args = '\tVerilated::commandArgs(argc, argv);\n'

	def gen_default_sc_include_files(self):
		self.def_includes  = '#define SC_INCLUDE_DYNAMIC_PROCESSES\n'
		self.def_includes += '#include "systemc"\n'
		self.def_includes += '#include "tlm.h"\n'
		self.def_includes += '#include "tlm_utils/simple_initiator_socket.h"\n'
		self.def_includes += '#include "tlm_utils/simple_target_socket.h"\n\n'
		self.def_includes += '#include "tlm_utils/tlm_quantumkeeper.h"\n\n'

	def gen_default_namespaces(self):
		self.def_namespaces  = 'using namespace sc_core;\n'
		self.def_namespaces += 'using namespace sc_dt;\n'
		self.def_namespaces += 'using namespace std;\n\n'

	def gen_defines(self):
		for name, val in sorted(self.defines.items()):
			if name in self.referenced_define:
				fmt = '#define {} {}\n'
				self.defines_generated += fmt.format(name, val)

	def gen_include_files(self):
		for f in set(self.include_files):
			self.include_files_generated += f

	def gen_class_initializers(self):
		is_first = True
		for f in self.class_init:

			if is_first == False:
				self.class_init_generated += ',\n'
			is_first = False

			self.class_init_generated += '\t' + f

	#
	# Create the top class
	#
	def gen_top_class(self):
		c = 'SC_MODULE(Top)\n'
		c += '{\n'
		c += 'public:\t\n'
		c += '\tSC_HAS_PROCESS(Top);\n'

		#
		# Instantiate
		#
		c += '\n\t// Generated signal classes\n'
		c += self.classes_bus_sig_inst_generated

		c += '\n\t// Generated class instances\n'
		c += self.class_inst_generated

		c += '\n\t// Generated adhoc connections signals\n'
		c += self.adhoc_sig_generated

		#
		# Constructor
		#
		c += '\n\t// Generated Constructor\n'
		c += '\tTop(sc_core::sc_module_name name, char **argv):\n'
		c += '\t\tsc_core::sc_module(name)'

		#
		# Add initializers
		#
		if len(self.classes_bus_sig_init) > 0:
			c += ',\n\n\t\t// classes_bus_sig_init'
			for sig_init in self.classes_bus_sig_init:
				c += ',\n' + sig_init

		if len(self.class_init_generated) > 0:
			c += ',\n\n\t\t// classes_bus_sig_init'
			c += ',\n' + self.class_init_generated

		if len(self.adhoc_sig_init) > 0:
			c += ',\n\n\t\t// adhoc_sig_init'
			for sig_init in self.adhoc_sig_init:
				c += ',\n' + sig_init

		#
		# Constructor body
		#
		c += '\n\t{\n'

		#
		# Generated the global quantum setup
		#
		c += '\t\tm_qk.set_global_quantum(sc_time((double) '
		c += str(self.args.global_quantum)
		c += ', SC_NS));\n'

		#
		# Add connections
		#
		c += '\n\t\t// specialized_cons\n'
		for k, v in sorted(self.specialized_cons.items()):
			c += v

		c += '\n\t\t// bus_sig_cons_generated\n'
		c += self.bus_sig_cons_generated

		c += '\n\t\t// adhoc_sig_cons_generated\n'
		c += self.adhoc_sig_cons_generated

		c += '\n\t\t// end_of_elaboration\n'
		c += self.end_of_elaboration

		c += '\t}\n'

		#
		# Instantiate the quantumkeeper
		#
		c += '\n\ttlm_utils::tlm_quantumkeeper m_qk;\n'

		c += '};\n'

		self.top_generated = c
		self.top_instatiation = '\tTop top("top", argv);\n'

	def gen_sc_time_resolution(self):
		sc_time_res = '\tsc_set_time_resolution('
		sc_time_res += str(self.args.sc_time_resolution)
		sc_time_res += ', SC_PS);\n'
		self.sc_time_res_generated = sc_time_res

	def gen_sc_sim(self):

		if self.args.quiet == False:
			line = '-' * 80
			print '\n' + line
			print 'Start translating:'
			print self.design.get_vlnv()
			print line + '\n'

		filename = '{}/sc_sim.cc'.format(self.args.outdir)

		self.gen_default_sc_include_files()
		self.gen_default_namespaces()

		self.translate_specialized_classes()
		self.translate_non_tlm_abs_defs()
		self.translate_component_instances()
		self.translate_interconnections()
		self.translate_adhoc_connections()

		self.gen_adhoc_signal_inst_and_init()
		self.gen_end_of_elaboration()
		self.gen_sig_tracing()
		self.gen_defines()
		self.gen_include_files()
		self.gen_class_initializers()
		self.gen_top_class()
		self.gen_sc_time_resolution()

		if len(self.verilog_comp) > 0:
			self.gen_verilator_cmd_args()

		sc_sim_generated = [
			#
			# Includes
			#
			('[default_includes]', self.def_includes),
			('[default_namespaces]', self.def_namespaces),
			('[include_files_generated]',
				self.include_files_generated),

			#
			# defines
			#
			('[defines_generated]', self.defines_generated),

			#
			# Generated classes
			#
			('[classes_generated]', self.classes_generated),

			('[top_generated]', self.top_generated),

			#
			# sc_main
			#
			('[sc_main_prologue]', self.sc_main_prologue),

			('[verilator_cmd_args]', self.verilator_cmd_args),

			('[sc_time_res_generated]', self.sc_time_res_generated),

			('[top_instatiation]', self.top_instatiation),

			('[trace_sig]', self.signal_tracing),

			('[reset_code_generated]', self.reset_code_generated),

			('[sc_main_epilogue]', self.sc_main_epilogue)
		]

		if self.args.verbose:
			print '\n[Generate {}]\n'.format(filename)

		if not self.args.quiet:
			for debug, output in sc_sim_generated:
				if self.args.verbose:
					print debug
				print output

		#
		# Write file
		#
		with open(filename, 'w') as f:
			for debug, output in sc_sim_generated:
				f.write(output)
