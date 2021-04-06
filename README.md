![Xilinx Logo](https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Xilinx_logo_2008.svg/320px-Xilinx_logo_2008.svg.png)

# LibSystemCTLM-SoC

This library contains various SystemC/TLM-2.0 modules that enable co-simulation of Xilinx QEMU, SystemC/TLM-2.0 models and RTL.

QEMU gets connected by libremote-port. It implements a socket based transaction protocol by serializing/de-serializing QEMU transactions and TLM Generic Payloads.

RTL needs to be converted to something that interfaces with SystemC by a tool such as Verilator or equivalent commercial tools.

## Quickstart

There are two ways to run the examples

#### Using Docker Image
`docker run --hostname builder -it xilinxset/eri-july-2019:full`

Full description on how to run the examples can be found here: https://hub.docker.com/r/xilinxset/eri-july-2019

#### Setting up your environment locally
Assuming you've installed the [Dependencies](#dependencies) and created the [Configuration](#configuration) file.

To run the examples, change directory to the test directory and run:
```
cd tests/
make examples-run

```
You'll then for example get a build of the example-rtl-axi4 example that includes a verilog AXI4 device hooked up to co-simulate with SystemC/TLM. A VCD trace should have been generated that you can look at:

`gtkwave example-rtl-axi4/example-rtl-axi4.vcd`

## Dependencies

You'll need to install the following packages:
`apt-get install gcc g++ verilator libsystemc-dev gtkwave rapidjson-dev python-pytest python-pytest-xdist`

On some distros, the libsystemc-dev package may not exist, in that case you'll need to install SystemC manually.
The SystemC libraries can be found here:http://www.accellera.org/downloads/standards/systemc

To be able to generate the HTML test reports, you'll need to install pytest-html. This may not be available on your distro but can be found with `pip:pip install pytest-html`

Please note that you'll need GCC v5.4.0 at minimum to build this software.

## Limitations

Building and running libsystemctlm-soc is not supported for Cent OS.

CentOS 7 - The default gcc version for this distro is 4.8.5, you'll need to manually build and install GCC 5.4.0 and above. Calling convention for pytest differs, should be called as py.test instead of pytest.


## Configuration

To run the test-suites and examples, libsystemctlm-soc by default assumes that the SystemC libraries are installed under `/usr/local/systemc-2.3.2/`

If you are using a different version or have installed the libraries on some other location, you'll need to create a `.config.mk` file to specify this.

Also, if you used specific c++ flags to build the SystemC libraries, such as manually specifying `-std=gnu++17` or something like that, you can specify that in the config files.

Here's an example with SystemC installed under `/opt/`:
`SYSTEMC = /opt/systemc-2.3.2`

Here's another example with SystemC installed under `/opt/` and built with gnu++17.
`SYSTEMC = /opt/systemc-2.3.2
CXXFLAGS +=-std=gnu++17`

### How To Embed Into Your Project

This repository contains the code and header files required to connect your SystemC application with Xilinx's QEMU. There are three directories.
```
 libsystemctlm-soc
  |
  |-zynq
  |  Contains the wrapper files required to interface a Zynq-7000 QEMU model
  |    of the PS with a SystemC model of the PL.
  |-zynqmp
  |  Contains the wrapper files required to interface a ZynqMP QEMU model
  |    of the PS with a SystemC model of the PL.
  |-libremote-port
  |  Contains the communitcation library for Remote-Port (RP) that is used for
  |   inter-simulator communication.
 ```

### Including in your project

To include this library in your project you can follow the steps below. This
assumes that you have cloned this repo in the root direcotry of your project.

See: https://github.com/Xilinx/systemctlm-cosim-demo for an example project using this
library.

Include this in your Makefile for Zynq-7000 projects:
```
  LIBSOC_ZYNQ_PATH=$(LIBSOC_PATH)/zynq
  SC_OBJS += $(LIBSOC_ZYNQ_PATH)/xilinx-zynq.o
  CPPFLAGS += -I $(LIBSOC_ZYNQ_PATH)
```
Include this in your Makefile for ZynqMP projects:
```
  LIBSOC_ZYNQMP_PATH=$(LIBSOC_PATH)/zynqmp
  SC_OBJS += $(LIBSOC_ZYNQMP_PATH)/xilinx-zynqmp.o
  CPPFLAGS += -I $(LIBSOC_ZYNQMP_PATH)
```
Include this in your Makefile for all projects:
 ```
  LIBSOC_PATH=libsystemctlm-soc
  CPPFLAGS += -I $(LIBSOC_PATH)

  LIBRP_PATH=$(LIBSOC_PATH)/libremote-port
  C_OBJS += $(LIBRP_PATH)/safeio.o
  C_OBJS += $(LIBRP_PATH)/remote-port-proto.o
  C_OBJS += $(LIBRP_PATH)/remote-port-sk.o
  SC_OBJS += $(LIBRP_PATH)/remote-port-tlm.o
  SC_OBJS += $(LIBRP_PATH)/remote-port-tlm-memory-master.o
  SC_OBJS += $(LIBRP_PATH)/remote-port-tlm-memory-slave.o
  SC_OBJS += $(LIBRP_PATH)/remote-port-tlm-wires.o
  SC_OBJS += $(LIBRP_PATH)/remote-port-tlm-ats.o
  SC_OBJS += $(LIBRP_PATH)/remote-port-tlm-pci-ep.o
  CPPFLAGS += -I $(LIBRP_PATH)
```
