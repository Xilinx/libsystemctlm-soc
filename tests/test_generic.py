import pytest
import os
import fnmatch
import subprocess

tg_testnames = fnmatch.filter(os.listdir(os.path.dirname(__file__) + "/traffic-generators/"), '*-tg-test')
testnames = ['./traffic-generators/{0}'.format(i) for i in tg_testnames]
config_parser_test = ["./traffic-generators/config-parser/config-parser-test",
"tp=./traffic-generators/config-parser/test_files/", "-p"]

testnames.append('./tlm-aligner/tlm-aligner-test')
pc_testnames = fnmatch.filter(os.listdir(os.path.dirname(__file__) + "/checkers/"), '*-test')
pctests = ['./checkers/{0}'.format(i) for i in pc_testnames ]

@pytest.mark.parametrize("filename", testnames)
def test_axi_tg_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", pctests)
def test_checker_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

def test_config_parser():
	assert(subprocess.call(config_parser_test) ==0)
