# RTL Bridges test-suite

## Simulation

There's 6 AXI based test-suites that run under simulation.
AXI3, AXI4, AXI4Lite, for both master and slave bridges.

These tests get hooked up to the py.test test-suite that runs from the
top of the project.

## VFIO

These VFIO based tests require a PCIe attached HW Bridge with a specific
memory map. An Open Source implementation of such a design can be found
here, https://github.com/edgarigl/posh-rtl-bridges-refdesigns.

On some systems, you may need to configure BIOS settings to enable the
use of IOMMUs (VT - Virtualization Technologies). You may also need to
pass the intel_iommu=on or amd_iommu=on Linux kernel command-line
arguments.

On my system, after programming the bit-stream onto a locally attached
Xilinx Alveo u250, it shows up like this in lspci -vnn:

```
17:00.0 FLASH memory [0501]: Xilinx Corporation Device [10ee:903f]
        Subsystem: Xilinx Corporation Device [10ee:0007]
        Flags: fast devsel, IRQ 11
        Memory at a4000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Memory at a8000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Memory at ac000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Capabilities: [40] Power Management version 3
        Capabilities: [70] Express Endpoint, MSI 00
        Capabilities: [100] Advanced Error Reporting
        Capabilities: [1c0] #19
```

So, the next step is to insmod the vfio modules and configure the PCIe EP
for VFIO usage. We'll need to pass the Device ID which you can find in
the output of lspci:

```
modprobe vfio-pci nointxmask=1
echo 10ee 903f > /sys/bus/pci/drivers/vfio-pci/new_id
```

Now, lspci -v should show you that the kernel driver in use is vfio-pci:
```
17:00.0 FLASH memory [0501]: Xilinx Corporation Device [10ee:903f]
        Subsystem: Xilinx Corporation Device [10ee:0007]
        Flags: fast devsel, IRQ 11
        Memory at a4000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Memory at a8000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Memory at ac000000 (64-bit, non-prefetchable) [disabled] [size=64M]
        Capabilities: [40] Power Management version 3
        Capabilities: [70] Express Endpoint, MSI 00
        Capabilities: [100] Advanced Error Reporting
        Capabilities: [1c0] #19
------> Kernel driver in use: vfio-pci
```

Now we're ready to run the tests. The test programs take the PCIe BDF, the
IOMMU group that the EP was setup into and a bridge index.

The IOMMU group can be found with the following command:
```
ls -l /sys/bus/pci/devices/0000\:17\:00.0/iommu_group
lrwxrwxrwx 1 root root 0 Dec 13 02:20 /sys/bus/pci/devices/0000:17:00.0/iommu_group -> ../../../../kernel/iommu_groups/26
```

The BDF is 0000:17:00.0 in my setup.
The IOMMU Group is 26.
The bridge index is zero, since the reference design we're using only has one set of
HWBs.

```test-pcie-axi4-master-vfio 0000:17:00.0 26 0```

```
Device supports 9 regions, 5 irqs
mapped 0 at 0x7f814acf1000
mapped 2 at 0x7f8146cf1000
mapped 4 at 0x7f8142cf1000

Info: (I702) default timescale unit used for tracing: 1 ps (/scratch/edgari/tlm/libsystemctlm-soc/tests/rtl-bridges/test-pcie-axi4-master-vfio.vcd)
Bridge ID c3a89fe1
Position 0
version=100
type=2 axi4-master
Bridge version 1.0
Bridge data-width 128
Bridge nr-descriptors: 16
--------------------------------------------------------------------------------
[15 us]

Write : 0x0, length = 16384, streaming_width = 16384
```

If you need to reprogram the bit-stream and run again, you can in some cases avoid reboots
by issuing the following sequence to trig a PCIe rescan on Linux. From my experience, if
the the PCIe EP memory configuration does not change, this will work. Otherwise, new BARs
may or may not be discovered.

```
echo 10ee 903f > /sys/bus/pci/drivers/vfio-pci/remove_id
echo 0000:17:00.0 > /sys/bus/pci/devices/0000\:17\:00.0/driver/unbind
echo "1" >/sys/bus/pci/devices/0000\:17\:00.0/remove
echo "1" >/sys/bus/pci/rescan
sleep 1
echo 10ee 9031 > /sys/bus/pci/drivers/vfio-pci/new_id
```
