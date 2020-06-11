# CXS RTL Bridge test-suite

## Simulation

Two simulations tests are found in this directory, one excersing a CXS HW
bridge connected to a SW [TLM to CXS
bridge](../../../tlm-bridges/tlm2cxs-bridge.h) and a second test
exercising two CXS HW bridges connected in a loopbacked fashion. Both
tests start by running a specified traffic description (for generating
specific CCIX transactions) and continue with running randomized traffic
(resulting in randomized CCIX transactions through the bridges).

Both tests are hooked up to the py.test test-suite that runs from the
top of the project.

## VFIO test

The VFIO based test found in the directory requires a PCIe attached HW Bridge
with a specific memory map. An Open Source implementation of such a design can
be found here, https://github.com/edgarigl/posh-rtl-bridges-refdesigns.

The test runs on a HW configuration where two CXS HW bridges are connected
in a loopbacked fashion. Similar to the simulation tests the VFIO test
start by running a specified traffic description (for generating specific
CCIX transactions) and ends with running randomized traffic through the
CXS HW bridges.

## Running the VFIO test

Please read the AXI HW bridge test [README.md](../axi/README.md) for a more
detailed explanation of how a system can be configured for VFIO use.

Below are sample command lines after configuring a system for VFIO use
(following above README) and programming the CXS bit-stream generated through
the git repository mention above onto a locally attached Xilinx Alveo u250.
These command lines might need minor modifications depending on which pci bus
the Alveo 250 device gets attached to.

```
$ lspci -v -d 10ee:
65:00.0 FLASH memory: Xilinx Corporation Device 903f
        Subsystem: Xilinx Corporation Device 0007
        Flags: fast devsel, IRQ 66
        Memory at cc000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Memory at d0000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Memory at d4000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Capabilities: [40] Power Management version 3
        Capabilities: [70] Express Endpoint, MSI 00
        Capabilities: [100] Advanced Error Reporting
        Capabilities: [1c0] #19
...
$ modprobe vfio-pci nointxmask=1
$ echo 10ee 903f > /sys/bus/pci/drivers/vfio-pci/new_id
$ lspci -v -d 10ee:
65:00.0 FLASH memory: Xilinx Corporation Device 903f
        Subsystem: Xilinx Corporation Device 0007
        Flags: fast devsel, IRQ 66
        Memory at cc000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Memory at d0000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Memory at d4000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Capabilities: [40] Power Management version 3
        Capabilities: [70] Express Endpoint, MSI 00
        Capabilities: [100] Advanced Error Reporting
        Capabilities: [1c0] #19
------> Kernel driver in use: vfio-pci

$ test-pcie-cxs-loopback-vfio 0000:65:00.0 26

        SystemC 2.3.2-Accellera --- Feb  7 2020 14:24:55
        Copyright (c) 1996-2017 by all Contributors,
        ALL RIGHTS RESERVED
Device supports 9 regions, 5 irqs
mapped 0 at 0x7f8721a23000
mapped 2 at 0x7f871da23000
mapped 4 at 0x7f8719a23000

Info: (I702) default timescale unit used for tracing: 1 ps (test-pcie-cxs-loopback-vfio.vcd)
version=100
version=100
type=c
type=c
--------------------------------------------------------------------------------
[500 us]

Write : 0x0, length = 4, streaming_width = 4

data = { 0xff, 0xff, 0xff, 0xff, }

.
.
.

```
