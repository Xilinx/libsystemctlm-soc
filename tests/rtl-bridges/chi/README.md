# CHI RTL Bridge test-suite

## Simulation

Three simulations tests are found in this directory, one excersing the CHI RN-F
HW bridge (chi-rnf-test), a second exercising the CHI HN-F HW bridge
(chi-hnf-test) and a third test where the HW bridges are connected in a
loopbacked fashion. The first two tests start by running a specified traffic
description (for generating specific CHI transactions) through the bridges and
continues with running randomized traffic (resulting in randomized CHI
transactions). The third tests runs randomized CHI traffic.

All tests are hooked up to the py.test test-suite that runs from the
top of the project.

## VFIO tests

The VFIO based test found in the directory requires a PCIe attached HW Bridge
with a specific memory map. An Open Source implementation of such a design can
be found here, https://github.com/edgarigl/posh-rtl-bridges-refdesigns.

The test runs on a HW configuration where an CHI RN-F HW bridge and an CHI HN-F
HW bridge are connected in a loopbacked fashion. A TLM RN-F is then used for
running randomized CHI traffic through the HW bridges. A second TLM RN-F is also
connected in the test and is used for generating snoop traffic through the HW
bridges (via the TLM CHI interconnect). Finally a TLM Slave Node memory
connected to the interconnect receives the end memory transactions.

## Running the VFIO test

Please read the AXI HW bridge test [README.md](../axi/README.md) for a more
detailed explanation of how a system can be configured for VFIO use.

Below are sample command lines after configuring a system for VFIO use
(following above README) and programming the CHI bit-stream generated through
the git repository mention above onto a locally attached Xilinx Alveo u250.
These command lines might need minor modifications depending on which pci bus
the Alveo 250 device gets attached to.

```
$ lspci -v -d 10ee:
17:00.0 FLASH memory: Xilinx Corporation Device 903f
        Subsystem: Xilinx Corporation Device 0007
        Flags: fast devsel, IRQ 53
        Memory at ac000000 (64-bit, non-prefetchable) [size=64M]
        Memory at a8000000 (64-bit, non-prefetchable) [size=64M]
        Memory at a4000000 (64-bit, non-prefetchable) [size=64M]
        Capabilities: [40] Power Management version 3
        Capabilities: [70] Express Endpoint, MSI 00
        Capabilities: [100] Advanced Error Reporting
        Capabilities: [1c0] #19
...
$ modprobe vfio-pci nointxmask=1
$ echo 10ee 903f > /sys/bus/pci/drivers/vfio-pci/new_id
$ lspci -v -d 10ee:
17:00.0 FLASH memory: Xilinx Corporation Device 903f
        Subsystem: Xilinx Corporation Device 0007
        Flags: fast devsel, IRQ 53
        Memory at ac000000 (64-bit, non-prefetchable) [size=64M]
        Memory at a8000000 (64-bit, non-prefetchable) [size=64M]
        Memory at a4000000 (64-bit, non-prefetchable) [size=64M]
        Capabilities: [40] Power Management version 3
        Capabilities: [70] Express Endpoint, MSI 00
        Capabilities: [100] Advanced Error Reporting
        Capabilities: [1c0] #19
------> Kernel driver in use: vfio-pci

$ test-pcie-chi-rnf-hnf-loopback-vfio 0000:17:00.0 26

        SystemC 2.3.2-Accellera --- Feb  1 2020 16:32:47
        Copyright (c) 1996-2017 by all Contributors,
        ALL RIGHTS RESERVED
Device supports 9 regions, 5 irqs
mapped 0 at 0x7f71ce555000
mapped 2 at 0x7f71ca555000
mapped 4 at 0x7f71c6555000

Info: (I702) default timescale unit used for tracing: 1 ps
(test-pcie-chi-rnf-hnf-loopback-vfio.vcd)
version=100
version=100
type=b
type=a
--------------------------------------------------------------------------------
[100 us]

Read: 0x21c, length = 368, streaming_width = 137

.
.
.

```
