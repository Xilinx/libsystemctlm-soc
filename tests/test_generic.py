import pytest
import os
import fnmatch
import subprocess

tg_axi_testnames = fnmatch.filter(os.listdir(os.path.dirname(__file__) + "/traffic-generators/axi/"), '*-tg-test')
testnames_axi = ['./traffic-generators/axi/{0}'.format(i) for i in tg_axi_testnames]
config_parser_test = ["./traffic-generators/config-parser/config-parser-test",
"tp=./traffic-generators/config-parser/test_files/", "-p"]

pc_axi_testnames = fnmatch.filter(os.listdir(os.path.dirname(__file__) + "/checkers/axi/"), '*-test')
pc_axi_tests = ['./checkers/axi/{0}'.format(i) for i in pc_axi_testnames]

cp_tg_axi_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
				"/traffic-generators/axi/cp-tg/"), '*-tg-test')

tlm_modules_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/tlm-modules/"), '*-test')
tests_tlm_modules = ['./tlm-modules/{0}'.format(i) for i in tlm_modules_tests]

tg_axilite_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/traffic-generators/axilite/"), '*-tg-test')
tests_tg_axilite = ['./traffic-generators/axilite/{0}'.format(i) for i in tg_axilite_tests]

pc_axilite_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/checkers/axilite/"), '*-test')
tests_pc_axilite = ['./checkers/axilite/{0}'.format(i) for i in pc_axilite_tests]

cp_tg_axilite_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/traffic-generators/axilite/cp-tg/"), '*-tg-test')

tg_axis_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/traffic-generators/axis/"), '*-tg-test')
tests_tg_axis = ['./traffic-generators/axis/{0}'.format(i) for i in tg_axis_tests]

tg_ace_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/traffic-generators/ace/"), '*-tg-test')
tests_tg_ace = ['./traffic-generators/ace/{0}'.format(i) for i in tg_ace_tests]

pc_ace_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/checkers/ace/"), '*-test')
tests_pc_ace = ['./checkers/ace/{0}'.format(i) for i in pc_ace_tests]

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

@pytest.mark.parametrize("filename", tests_tlm_modules)
def test_tlm_modules_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", tests_tg_axilite)
def test_tg_axilite_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", tests_pc_axilite)
def test_checker_axilite_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", cp_tg_axilite_tests)
def test_cp_tg_axilite(filename):
	dir_path = os.path.normpath(os.path.dirname(__file__) +
					"/traffic-generators/axilite/cp-tg")
	assert(subprocess.call([dir_path + "/" + filename,
				dir_path + "/tests/*"]) == 0)

@pytest.mark.parametrize("filename", tests_tg_axis)
def test_tg_axis_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", tests_tg_ace)
def test_tg_ace_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", tests_pc_ace)
def test_checker_ace_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)
