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
import xml.etree.ElementTree as ET

ns = {
	'ipxact' : 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'
}

def to_vlnv(attr):
	return (attr['vendor'],
		attr['library'],
		attr['name'],
		attr['version'])

class IpxactObject:

	ipxact_obj_tags = [
			'{' + ns['ipxact'] + '}design',
			'{' + ns['ipxact'] + '}designConfiguration',
			'{' + ns['ipxact'] + '}component',
			'{' + ns['ipxact'] + '}busDefinition',
			'{' + ns['ipxact'] + '}abstractionDefinition',
			'{' + ns['ipxact'] + '}abstractor',
			]

	def __init__(self, tree):
		self.tree = tree
		self.root = tree.getroot()

	def get_vlnv(self):
		root = self.root

		vendor = root.find('ipxact:vendor', ns)
		lib = root.find('ipxact:library', ns)
		name = root.find('ipxact:name', ns)
		version = root.find('ipxact:version', ns)

		return vendor.text, lib.text, name.text, version.text

	def dump_views(self):
		print '[Platform]'
		print self.get_vlnv()
		model = self.root.find('ipxact:model', ns)
		views = model.find('ipxact:views', ns)

		print '[Views]'
		for view in views.findall('ipxact:view', ns):
			self.dump_view(view)

	def dump_view(self, view):
		start_idx = len(ns['ipxact']) + 2
		print '[View]'
		for c in view:
			print c.tag[start_idx:] + ': ' + c.text

class Registry:

	def __init__(self, paths, verbose):
		self.ipxact_objects = []
		self.verbose = verbose

		for path in paths:
			for dir, subdir, files in os.walk(path):
				for file in files:
					filepath = dir + '/' + file
					self.try_append_ipxact_object(filepath)

	def try_append_ipxact_object(self, file):
		tree = self.get_ipxact_object_from_file(file)

		if tree:
			object = IpxactObject(tree)

			if self.get_ipxact_object(object.get_vlnv()) is None:

				if self.verbose:
					if self.verbose > 1:
						idx = len(ns['ipxact']) + 2
						root = object.root
						vlnv = object.get_vlnv()

						fmt = '[{0}]: {1}'
						fmt +='\n\n\t * [{2}]\n\n'

						print fmt.format(root.tag[idx:],
								vlnv,
								file)
					else:
						print object.get_vlnv()

				file_abspath = os.path.abspath(file)

				self.ipxact_objects.append(
						(object, file_abspath))


	def get_ipxact_object_from_file(self, file):
		if file.endswith('.xml'):
			tree = ET.parse(file)
			root = tree.getroot()
			if root.tag in IpxactObject.ipxact_obj_tags:
				return tree

		return None

	def get_ipxact_object(self, vlnv):
		for object, file in self.ipxact_objects:
			if object.get_vlnv() == vlnv:
				return object
		return None

	def get_ipxact_object_xml(self, vlnv):
		for object, file in self.ipxact_objects:
			if object.get_vlnv() == vlnv:
				return file
		return None
