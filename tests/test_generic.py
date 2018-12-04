import pytest
import os
import fnmatch
import subprocess

tg_axi_testnames = fnmatch.filter(os.listdir(os.path.dirname(__file__) + "/traffic-generators/axi/"), '*-tg-test')
testnames_axi = ['./traffic-generators/axi/{0}'.format(i) for i in tg_axi_testnames]
config_parser_test = ["./traffic-generators/config-parser/config-parser-test",
"tp=./traffic-generators/config-parser/test_files/", "-p"]

testnames_axi.append('./tlm-aligner/tlm-aligner-test')
pc_axi_testnames = fnmatch.filter(os.listdir(os.path.dirname(__file__) + "/checkers/axi/"), '*-test')
pc_axi_tests = ['./checkers/axi/{0}'.format(i) for i in pc_axi_testnames]

cp_tg_axi_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
				"/traffic-generators/axi/cp-tg/"), '*-tg-test')

@pytest.mark.parametrize("filename", testnames_axi)
def test_tg_axi_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", pc_axi_tests)
def test_checker_axi_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

def test_config_parser():
	assert(subprocess.call(config_parser_test) ==0)

@pytest.mark.parametrize("filename", cp_tg_axi_tests)
def test_cp_tg_axi(filename):
	dir_path = os.path.normpath(os.path.dirname(__file__) +
					"/traffic-generators/axi/cp-tg")
	assert(subprocess.call([dir_path + "/" + filename,
				dir_path + "/tests/*"]) == 0)
