

# Introduction

This document gives architecture, data flow and system level details of the
PCIE Hardware Bridge.

|Acronyms|                                               |
|--------|-----------------------------------------------|
|QEMU	 | Quick Emulator                                |
|AXI	 | Advanced eXtensible Interface                 |
|ACE	 | AXI Coherency Extensions                      |
|XDMA	 | Xilinx DMA IP                                 |
|FPGA	 | Field Programmable Gate Array                 |
|PCIe	 | Peripheral Component Interconnect Express     |
|DUT	 | Device Under Test                             |
|EP	 | End Point                                     |
|MSI	 | Message Signaled Interrupt                    |
|MSI-X	 | Message Signaled Interrupt - Extended         |
|BAR	 | Base Address Register                         |
|TLM	 | Transaction-level Modeling                    |
|DESC	 | Descriptor                                    |
|C2H	 | Card to Host                                  |
|H2C	 | Host to card                                  |


# System Details



 - DUT will be implemented in FPGA
 - QEMU and  LibSystemCTLM-SoC run on x86 host 
 - PCIe protocol used as medium to connect x86 (as Root Complex) with FPGA (as EndPoint)
 - PCIe FPGA Bridge supports 2 modes of operation	
        1. Mode_0: Register Access mode ( Preferable for smaller size
        transactions) 
        2. Mode_1: Indirect DMA Mode (Gives better performance and
        efficient for larger size transactions) 
        For more details refer AXI-Bridge documents.

Please refer pcie-ep-bridge.md for PCIE EP Bridge Micro-architecture.


# Software-Hardware Flow



## PCIe EP HW Bridge ( pcie2tlm-hw-bridge )

Same as AXI Master, Slave Bridge


# Bridge Discovery Mechanism

Following is the sequence to identify number of bridges in the design and their
addresses.

While building design using bridges,

- User will have to make sure that Bridges are connected to BAR-0 starting from
  offset 0x0.  
- All bridges should be connected to consecutive locations without any gap in
  between. [ Every 128 KB from ( BAR-0 + 0x0 ) will have a new Bridge ]. Also,
  all PCIe-AXI Bridges will be connected consecutively without any gap or any
  other kind of bridge in between.  
- In the last PCIe-AXI-bridge of PCIe Bridge, user will have to set parameter
  PCIE_LAST_BRIDGE=1, which will be propagated into the field PCIE_LAST_BRIDGE
  of register BRIDE_POSITION_REG and available for software to read.  
- In the last bridge of design, user will have to set parameter LAST_BRIDGE=1,
  which will be propagated into the field LAST_BRIDGE of register
  BRIDE_POSITION_REG and available for software to read.  

For software to identify bridges,

- Upon start, Software will start traversing through BAR-0 offset 0x0.  
- Software will read the PCIE_LAST_BRIDGE Field of BRIDGE_POSITON_REG for each
  PCIe-AXI Master or Slave bridge. And software will read the LAST_BRIDGE Field
  of BRIDGE_POSITON_REG for each bridge.  
  - If PCIE_LAST_BRIDGE of PCIe-AXI Master or Slave Bridge is "1", It will stop
    finding more PCIe-AXI bridges, else Software will go to next 128 KB offset
    and do the same process until it gets PCIE_LAST_BRIDGE = "1".  
  - If LAST_BRIDGE is "1", It will stop finding more bridges, else Software will
    go to next 128 KB offset and do the same process until it gets LAST_BRIDGE =
    "1". 

> **NOTE** : If a PCIe-AXI Bridge's PCIE_LAST_BRIDGE and LAST_BRIDGE in
BRIDGE_POSITON_REG is "1", it means the Bridge is last PCIe-AXI Bridge in PCIe
Bridge and last Bridge in EndPoint.




