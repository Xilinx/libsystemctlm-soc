# Pytest module to run the examples.
import pytest
import os
import fnmatch
import subprocess

testnames = ['./example-rtl-axi4/example-rtl-axi4',
	     './example-rtl-axi4lite/example-rtl-axi4lite',
	     './example-rtl-mixed/example-rtl-mixed']

# Add UMI example if available.
try:
    testnames_umi = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
                    "/example-rtl-umi/obj_dir/"), 'example-rtl-umi')
except Exception:
    testnames_umi = []
    pass

@pytest.mark.checker
@pytest.mark.tg
@pytest.mark.axi4
@pytest.mark.bridge
@pytest.mark.examples
@pytest.mark.parametrize("filename", testnames)
def test_axi_tg_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", testnames_umi)
def test_umi_example(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/example-rtl-umi/obj_dir/' + filename)
	assert(subprocess.call([path_exe]) == 0)
