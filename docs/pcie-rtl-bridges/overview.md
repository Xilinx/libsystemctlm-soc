# PCIe EP HW Bridges

## Acronyms

|Acronym |                                               |
|--------|-----------------------------------------------|
|ACE	 | AXI Coherency Extensions                      |
|AXI	 | Advanced eXtensible Interface                 |
|BAR	 | Base Address Register                         |
|C2H	 | Card to Host                                  |
|DESC	 | Descriptor                                    |
|DUT	 | Device Under Test                             |
|EP	 | End Point                                     |
|FPGA	 | Field Programmable Gate Array                 |
|H2C	 | Host to card                                  |
|MSI	 | Message Signaled Interrupt                    |
|MSI-X	 | Message Signaled Interrupt - Extended         |
|TLM	 | Transaction-level Modeling                    |
|PCIe	 | Peripheral Component Interconnect Express     |
|QEMU	 | Quick Emulator                                |
|XDMA	 | Xilinx DMA IP                                 |

## Overview

A PCIe capable system is composed of multiple components. There's
a host with System memory, integrated devices, a PCIe Root Complex,
a PCIe fabric and PCIe endpoints.

The PCIe Root Complex is responsible for bridging communication
between the PCIe fabric and endpoints with the hosts System
memory and other integrated devices.
```
 +---------+----+       +--------+
 | Host    | RC | <---> | PCIe   | <----> PCIe Endpoint
 |         +----|       | Fabric | <----> PCIe Endpoint
 | Integrated   |       +--------+ <----> PCIe Endpoint
 |  Devices     |
 +--------------+
```
Deep diving into a single PCI endpoint, it is composed
of multiple components itself. In this context we are
mainly interested in the digital logic, typically
implemented in one or more chips on the endpoint board/card.
These chips can either be ASIC's or re-programmable FPGA's.
In either case, the digital logic can further be split into
multiple layers.

```
   PIPE  +-----------+   USR-IF  +------------+
  <----> | PCIe Core | <-------> | Endpoint   |
         +-----------+           | User-Logic |
                                 +------------+
```

There's the PCIe Core the implements the lower layers of the
PCIe protocol and then there's the Endpoint User-Logic that
implements a unique device with features such as an Ethernet
MAC or a GPU.

There are multiple vendors of PCIe cores and these cores expose
slightly different interfaces towards the User Logic.

The PCIe EP HW bridges in this projects are primarily implementing the
ability to co-simulate Endpoint User-Logic RTL with high-level models
of a Xilinx PCIe Core and a Host.

By enabling this co-simulation to work with QEMU/KVM, the host can be
a KVM accelerated virtual machine running almost at native speed,
co-simulating with a PCIe card simulated in RTL.

## Primary setup

The co-simulation framework support variety of ways to simulate PCIe systems
but the primary way is the following:

  * The host is modelled by QEMU/KVM
    * The host is typically an x86 host emulated/virtualized on an x86 host
  * The PCIe Root Complex and parts of the fabric reside in QEMU
  * Parts of the PCIe fabric can be modelled in System/RTL
  * The PCIe EndPoint will be modelled in SystemC combined with RTL simulations or HW in the loop
  * The PCIe EndPoint User-Logic is RTL and can be:
    * RTL co-simulated
    * Synthesized onto an FPGA and co-simulated (Hardware in the loop)
  * The simulated PCIe EP can be hot-plugged and unplugged
  * The simulated PCIe EP can DMA into the host
  * The simulated PCIe EP can raise interrups to the host (Legacy, MSI and MSI-X)
  * Multiple PCIe EP's can be simulated simultaneously

## Emulating the host

The host and PCIe Root Complex can be emulated by using Xilinx QEMU/KVM.
https://github.com/Xilinx/qemu

Any QEMU machine with PCI support will do but we've been testing with x86 hosts
emulated/virtualized on x86 hosts.

On the VM, you can run a stock Ubuntu.

First create a machine directory:
```
mkdir machine-x86/
```

This is the QEMU command-line we've been using to launch the VM:

```
qemu-system-x86_64 -M q35,accel=kvm,kernel-irqchip=split		\
	-device intel-iommu,intremap=on,device-iotlb=on			\
	-cpu host -smp 8 -m 8G						\
	-netdev user,hostfwd=tcp:127.0.0.1:2225-10.0.2.15:22,id=n0	\
	-device virtio-net,netdev=n0					\
	-drive file=hd0.qcow2,format=qcow2				\
	-machine-path machine-x86/					\
	-serial mon:stdio 						\
	-device ioh3420,id=rootport,slot=0				\
	-device ioh3420,id=rootport1,slot=1
```

## Hotplug a PCIe card

Since we used the ```-serial mon:stdio``` option with QEMU, we can press ctrl+a + c
to get into the console.

On the console we need to issuse the following command to instantiate a remote-port
adaptor to connect QEMU with a SystemC simulation.

```
device_add remote-port-pci-adaptor,bus=rootport1,id=rp0
```

We expect to see something like the following:
```
Failed to connect socket machine-x86//qemu-rport-_machine_peripheral_rp0_rp: Connection refused
info: QEMU waiting for connection on: disconnected:unix:machine-x86//qemu-rport-_machine_peripheral_rp0_rp,server
```

QEMU is now waiting for the SystemC simulator to connect.

An example of a PCIe EP can be found here:
https://github.com/Xilinx/libsystemctlm-soc/blob/master/tests/rtl-bridges/pcie/refdesign-sim.cc

We'll run that one from a shell (not in the QEMU console):
```
./refdesign-sim unix:./machine-x86/qemu-rport-_machine_peripheral_rp0_rp 1000
```

Now the communication is established and we'll hotplug in the EP from the QEMU console:

```
device_add remote-port-pci-device,bus=rootport,rp-adaptor0=rp,rp-chan0=0,vendor-id=0x10ee,device-id=0xd004,class-id=0x0700,revision=0x12,nr-io-bars=0,nr-mm-bars=1,bar-size0=0x100000,id=pcidev1
```

From within the guest, you'll now be able to see the Remote-port adaptor and the EP with lspci -vv.
