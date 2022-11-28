import pytest
import os
import fnmatch
import subprocess
import shutil
import errno

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

pc_acelite_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/checkers/acelite/"), '*-test')
tests_pc_acelite = ['./checkers/acelite/{0}'.format(i) for i in pc_acelite_tests]

tg_chi_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/traffic-generators/chi/"), '*-tg-test')
tests_tg_chi = ['./traffic-generators/chi/{0}'.format(i) for i in tg_chi_tests]

pc_chi_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/checkers/chi/"), '*-test')
tests_pc_chi = ['./checkers/chi/{0}'.format(i) for i in pc_chi_tests]

tg_ccix_tests = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/traffic-generators/ccix/"), '*-tg-test')
tests_tg_ccix = ['./traffic-generators/ccix/{0}'.format(i) for i in tg_ccix_tests]

hwb_axi_testnames = fnmatch.filter(os.listdir(os.path.dirname(__file__) + "/rtl-bridges/axi/"), '*-test-pcie-master')
hwb_axi_testnames += fnmatch.filter(os.listdir(os.path.dirname(__file__) + "/rtl-bridges/axi/"), '*-test-pcie-slave')
hwb_axi_testnames += fnmatch.filter(os.listdir(os.path.dirname(__file__) + "/rtl-bridges/axi/"), 'test-slave-directed')
hwb_axi_tests = ['./rtl-bridges/axi/{0}'.format(i) for i in hwb_axi_testnames]

hwb_ace_testnames = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/rtl-bridges/ace/"), '*-test')
hwb_ace_tests = ['./rtl-bridges/ace/{0}'.format(i) for i in hwb_ace_testnames]

hwb_chi_testnames = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/rtl-bridges/chi/"), '*-test')
hwb_chi_tests = ['./rtl-bridges/chi/{0}'.format(i) for i in hwb_chi_testnames]

hwb_cxs_testnames = fnmatch.filter(os.listdir(os.path.dirname(__file__) +
					"/rtl-bridges/cxs/"), '*-test')
hwb_cxs_tests = ['./rtl-bridges/cxs/{0}'.format(i) for i in hwb_cxs_testnames]

hwb_pcie_testnames = ["test-pcie-ep"]
hwb_pcie_tests = ['./rtl-bridges/pcie/{0}'.format(i) for i in hwb_pcie_testnames]

mrmac_tests = ['./soc/net/ethernet/check-mrmac']

qdma_tests = ['./soc/pci/xilinx/check-qdma']

hsc_tests = ['./soc/crypto/xilinx/check-hsc']

@pytest.mark.parametrize("filename", testnames_axi)
def test_tg_axi_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", pc_axi_tests)
def test_checker_axi_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

def test_config_parser():
	if not os.path.exists(config_parser_test[0]):
		pytest.xfail("Config-parser not available")
	assert(subprocess.call(config_parser_test) ==0)

@pytest.mark.parametrize("filename", cp_tg_axi_tests)
def test_cp_tg_axi(filename):
	dir_path = os.path.normpath(os.path.dirname(__file__) +
					"/traffic-generators/axi/cp-tg")
	if not os.path.exists(dir_path + "/" + filename):
		pytest.xfail("Config-parser not available")
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
	if not os.path.exists(dir_path + "/" + filename):
		pytest.xfail("Config-parser not available")
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

@pytest.mark.parametrize("filename", tests_pc_acelite)
def test_checker_acelite_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", tests_tg_chi)
def test_tg_chi_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.parametrize("filename", tests_pc_chi)
def test_checker_chi_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.ccix
@pytest.mark.parametrize("filename", tests_tg_ccix)
def test_tg_ccix_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

def get_ipxact_tests():
	ex_path = os.path.dirname(__file__)
	ex_path += '/../packages/ipxact/xilinx.com/examples/'
	tests = []

	for ex in os.listdir(ex_path):
		for ver in os.listdir(ex_path + '/' + ex):
			plat  = ex_path + '/' + ex + '/' + ver + '/'
			plat += ex + '.1.0.xml'
			plat = os.path.normpath(plat)

			out = os.path.dirname(__file__)
			for d in ['/pysimgen', ex, ver]:
				out += '/' + d
				try:
					os.makedirs(out)
				except OSError as e:
					if e.errno != errno.EEXIST:
						raise e

			tests += [(plat, out)]
	return tests

@pytest.mark.parametrize("platform, outdir", get_ipxact_tests())
def test_pysimgen_tests(platform, outdir):
	path_exe = os.path.dirname(__file__)
	path_exe += '/../tools/pysimgen/pysimgen'
	path_exe = os.path.normpath(path_exe)
	libs = os.path.normpath(os.path.dirname(__file__) + '/../')

	cfg = os.path.normpath(os.path.dirname(__file__) + '/../.config.mk')
	if os.path.exists(cfg):
		shutil.copy(cfg, outdir)

	pysimgen = [ path_exe, '-p', platform, '-l', libs ]
	pysimgen += [ '-o', outdir, '--build', '--run', '-q' ]
	assert(subprocess.call(pysimgen, cwd = outdir) == 0)

@pytest.mark.hw_bridge
@pytest.mark.parametrize("filename", hwb_axi_tests)
def test_hwb_axi_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.hw_bridge
@pytest.mark.parametrize("filename", hwb_ace_tests)
def test_hwb_ace_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.hw_bridge
@pytest.mark.parametrize("filename", hwb_chi_tests)
def test_hwb_chi_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.hw_bridge
@pytest.mark.parametrize("filename", hwb_cxs_tests)
def test_hwb_cxs_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.pcie
@pytest.mark.hw_bridge
@pytest.mark.parametrize("filename", hwb_pcie_tests)
def test_hwb_pcie_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.mrmac
@pytest.mark.parametrize("filename", mrmac_tests)
def test_mrmac_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.qdma
@pytest.mark.parametrize("filename", qdma_tests)
def test_qdma_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)

@pytest.mark.hsc
@pytest.mark.parametrize("filename", hsc_tests)
def test_hsc_tests(filename):
	path_exe = os.path.normpath(os.path.dirname(__file__) + '/' + filename)
	assert(subprocess.call([path_exe]) == 0)
