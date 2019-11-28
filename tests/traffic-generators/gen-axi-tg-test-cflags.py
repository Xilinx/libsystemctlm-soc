#!/usr/bin/env python

import sys
import os
import re

def usage(err):
	print("USAGE: %s filename" % sys.argv[0])
	sys.exit(err)

def match_axi_version(f):
	m = re.match('axilite', f)
	if m:
		print("-D__AXI_VERSION_AXILITE__")

	m = re.match('axi(\d+)', f)
	if m:
		print("-D__AXI_VERSION_AXI" + m.group(1) + "__")

def match_address_width(f):
	m = re.match('aw(\d+)', f)
	if m:
		print("-DAXI_ADDR_WIDTH=" + m.group(1))

def match_data_width(f):
	m = re.match('dw(\d+)', f)
	if m:
		print("-DAXI_DATA_WIDTH=" + m.group(1))

def match_id_width(f):
	m = re.match('idw(\d+)', f)
	if m:
		print("-DAXI_ID_WIDTH=" + m.group(1))

def match_cacheline_sz(f):
	m = re.match('cl(\d+)', f)
	if m:
		print("-DCACHELINE_SIZE=" + m.group(1))

def main():
	if len(sys.argv) < 2:
		usage(1)

	filename = os.path.basename(sys.argv[1])

	fields = filename.split('-')
	for f in fields:
		match_axi_version(f)
		match_address_width(f)
		match_data_width(f)
		match_id_width(f)
		match_cacheline_sz(f)

if __name__ == "__main__":
	main()
