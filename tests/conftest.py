import pytest
import sys
import os
from py.xml import html

@pytest.mark.optionalhook
def pytest_html_results_table_header(cells):
	cells.insert(2, html.th('Waveform'))
	cells.pop()

@pytest.mark.optionalhook
def pytest_html_results_table_row(report, cells):
	waveform = html.td("N/A")
	if report.trace:
		waveform = html.td(html.a("waveform-trace", href=report.trace))

	cells.insert(2, waveform)
	cells.pop()

@pytest.mark.hookwrapper
def pytest_runtest_makereport(item, call):
	outcome = yield
	report = outcome.get_result()
	report.trace = None
	try:
		report.trace = item.funcargs["filename"]
		report.trace += '.vcd'
	except:
		pass

def pytest_configure(config):
	# Register additional markers
	config.addinivalue_line("markers" ,"axi4: AMBA AXI 4")
	config.addinivalue_line("markers" ,"bridge: A protocol bridge")
	config.addinivalue_line("markers" ,"ccix: CCIX")
	config.addinivalue_line("markers" ,"checker: A protocol checker")
	config.addinivalue_line("markers" ,"examples: Example setups")
	config.addinivalue_line("markers" ,"hw_bridge: A HW bridge / transactor")
	config.addinivalue_line("markers" ,"mrmac: Xilinx MRMAC")
	config.addinivalue_line("markers" ,"pcie: PCI-express")
	config.addinivalue_line("markers" ,"tg: A traffic generator")
	config.addinivalue_line("markers" ,"qdma: Xilinx QDMA")
	config.addinivalue_line("markers" ,"hsc: Xilinx HSC")
