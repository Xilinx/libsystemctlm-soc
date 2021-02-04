# Launching the refdesign-sim demo

## Overview

Instructions for how to run an Ubuntu based guest system with Xilinx QEMU
together with the PCIe EP refdesign-sim demo are found below. More
information about the PCIe EP HW bridges are found in
[../../../docs/pcie-rtl-bridges/overview.md](../../../docs/pcie-rtl-bridges/overview.md).

## Preparing the Ubuntu cloud image VM

Download the the Ubuntu cloud image.

```
~$ cd ~/Downloads/
~$ wget https://cloud-images.ubuntu.com/releases/focal/release-20210125/ubuntu-20.04-server-cloudimg-amd64.img
~$ wget https://cloud-images.ubuntu.com/releases/focal/release-20210125/unpacked/ubuntu-20.04-server-cloudimg-amd64-vmlinuz-generic
~$ wget https://cloud-images.ubuntu.com/releases/focal/release-20210125/unpacked/ubuntu-20.04-server-cloudimg-amd64-initrd-generic
```

Resize the image to 10G.

```
~$ qemu-img resize ~/Downloads/ubuntu-20.04-server-cloudimg-amd64.img 10G
```

Create a disk image with user-data to be used for starting the cloud
image.

```
~$ sudo apt-get install cloud-image-utils
~$ cd ~/Downloads
~$ cat >user-data <<EOF
#cloud-config
password: pass
chpasswd: { expire: False }
ssh_pwauth: True
EOF
~$ cloud-localds user-data.img user-data
```


## Launch the cloud image

Launch the Ubuntu cloud image in QEMU using the following command (please
change 'accel=kvm' to 'accel=tcg' and remove '-enable-kvm' in case the user is
not allowed to use kvm):

```
$ mkdir /tmp/machine-x86
$ qemu-system-x86_64                                                              \
    -M q35,accel=kvm,kernel-irqchip=split -m 4G -smp 4 -enable-kvm                \
    -device virtio-net-pci,netdev=net0 -netdev type=user,id=net0                  \
    -serial mon:stdio -machine-path /tmp/machine-x86 -display none                \
    -device intel-iommu,intremap=on,device-iotlb=on                               \
    -device ioh3420,id=rootport,slot=0 -device ioh3420,id=rootport1,slot=1        \
    -drive file=~/Downloads/ubuntu-20.04-server-cloudimg-amd64.img,format=qcow2   \
    -drive file=~/Downloads/user-data.img,format=raw                              \
    -kernel ~/Downloads/ubuntu-20.04-server-cloudimg-amd64-vmlinuz-generic        \
    -append "root=/dev/sda1 ro console=tty1 console=ttyS0 intel_iommu=on"         \
    -initrd ~/Downloads/ubuntu-20.04-server-cloudimg-amd64-initrd-generic
```

Above command provides network access through a virtio-net-pci device. Once the
system has booted login with the user 'ubuntu' and password 'pass'.

## Required packages in the Ubuntu cloud image

Login into the Ubuntu cloud image and install below packages:
```
$ sudo apt-get update
$ sudo apt-get install git build-essential autoconf flex bison
```

Verify that the command line contains *intel_iommu=on*:
```
$ cat /proc/cmdline
"...ro quiet splash intel_iommu=on..."
```


## Install SystemC in the Ubuntu cloud image

Download and install SystemC 2.3.2 by issuing the following commands in
the VM:

```
$ mkdir ~/Downloads
$ cd ~/Downloads/
$ wget http://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.2.tar.gz
$ tar xzf systemc-2.3.2.tar.gz
$ cd systemc-2.3.2
$ ./configure --prefix=/opt/systemc-2.3.2
$ make
$ sudo make install
```

## Install Verilator in the Ubuntu cloud image

Download and install Verilator v4.010 by issuing the following commands in
the VM:

```
$ mkdir ~/github
$ cd ~/github/
$ git clone http://git.veripool.org/git/verilator -b v4.010
$ cd verilator
$ autoconf
$ ./configure
$ make
$ sudo make install
```

## Build libsystemctlm-soc PCIe RTL VFIO demos in the Ubuntu cloud image

Clone and build libsystemctlm-soc's PCIe VFIO demos by issuing the
following commands in the VM:

```
$ cd ~/github/
$ git clone https://github.com/Xilinx/libsystemctlm-soc.git
$ cd libsystemctlm-soc
$ cat <<EOF > .config.mk
SYSTEMC = /opt/systemc-2.3.2/
EOF
$ cd tests/rtl-bridges/pcie
$ make
```

Below two VFIO test demos will be found inside the directory after the
build:

```
$ ls test-pcie-ep-master-vfio test-pcie-ep-slave-vfio
```

## Launching QEMU and the refdesign-sim demo

Instructions on how to hotplug the PCIe EP in the refdesign-sim demo into QEMU
can be found inside:
[../../../docs/pcie-rtl-bridges/overview.md](../../../docs/pcie-rtl-bridges/overview.md)
(please note to use the following machine path: /tmp/machine-x86).

## Exercising the refdesign-sim demo with VFIO test applications

After connecting the PCIe EP in the refdesign-sim with QEMU it is possible to
run the VFIO tests demos inside the Ubuntu VM for exercising the EP. This is
done by issuing below commmands inside the VM (the commands are explained in
more detail inside [../axi/README.md](../axi/README.md)):

```
$ cd ~/github/libsystemctlm-soc/tests/rtl-bridges/pcie
$ sudo modprobe vfio-pci nointxmask=1
$ sudo sh -c 'echo 10ee d004 > /sys/bus/pci/drivers/vfio-pci/new_id'
$ # Find the iommu group
$ ls -l /sys/bus/pci/devices/0000\:01\:00.0/iommu_group
$ # The iommu group was 3
$ sudo ./test-pcie-ep-master-vfio 0000:01:00.0 3 0

        SystemC 2.3.2-Accellera --- Jan  8 2021 14:33:28
        Copyright (c) 1996-2017 by all Contributors,
        ALL RIGHTS RESERVED
Device supports 9 regions, 5 irqs
mapped 0 at 0x7fb2352b3000

Info: (I702) default timescale unit used for tracing: 1 ps (./test-pcie-ep-master-vfio.vcd)
Bridge ID c3a89fe1
Position 0
version=100
type=12 pcie-axi-master
Bridge version 1.0
Bridge data-width 128
Bridge nr-descriptors: 16
--------------------------------------------------------------------------------
[15 us]

Write : 0x0, length = 16384, streaming_width = 16384

data = { 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0....
```

A VCD file (refdesign-sim.vcd) will be created in the host directory from where
the refdesign-sim demo was launched after running the test. That VCD file can
be inspected with gtkwave. Example command lines for installing and launching
gtkwave on a Debian / Ubuntu system are found below.

```
$ sudo apt-get install gtkwave
$ gtkwave refdesign-sim.vcd
```
