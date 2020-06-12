
# PCIe EP Bridge use-model

PCIe EP Bridge use-model with Device Under Test (DUT) and PCIe Sub-system

```

                               _____________________________________________________
 ___________________          +          _________________________________          +         ___________________
+                   +         |        +                                 +          |        +                   +
|                   |         +        |                                 |          +------->+CLK                |
|              M_AXI+--------+)+------>+S_AXI_PCIE_M0,                   |                   |                   |
|                   |         +        |S_AXI_PCIE_S0         S_AXI_USR_0+<------------------+ M_PCIE            |
|                   |         |        |                                 |                   |                   |
|            AXI_CLK+---------+-------^+CLK                   M_AXI_USR_0+------------------>+ S_PCIE            |
|                   |                  |                                 |                   |                   |
|          AXI_RST_N+----------------->+RESETN                           |                   |                   |
|                   |                  |                       USR_RESETN+------------------>+RSTN               |
|  PCIE CORE        |                  |                                 |                   |                   |
|      &            |                  |            PCIE EP              |                   |                   |
|   AXI+MM          |                  |             BRIDGE              |                   |        PCIE DUT   |
|   BRIDGE          |                  |                                 |                   |                   |
|                   |                  |                                 |                   |                   |
|              S_AXI+<-----------------+M_AXI_PCIE_M0,        USR_IRQ_REQ+<------------------+INTR_OUT           |
|                   |                  |M_AXI_PCIE_S0                    |                   |                   |
|                   |                  |                      USR_IRQ_ACK+------------------>+INTR_IN            |
|             IRQ_IN+<-----------------+IRQ_REQ                          |                   |                   |
|                   |                  |                      C2H_GPIO_IN+<------------------+GPIO_OUT           |
|            IRQ_ACK+----------------->+IRQ_ACK                          |                   |                   |
|                   |                  |                     H2C_GPIO_OUT+------------------>+GPIO_IN            |
+___________________+                  +_________________________________+                   +___________________+


```

# Introduction

This document covers the micro architecture details of the PCIe EP bridge. The
PCIe EP Bridge is referred to as "EP Bridge" from here on for simplicity. The EP
bridge communicates with x86 Host via PCIe Controller and associated AXI-MM
Bridge. The AXI-MM Bridge converts the PCIe transaction layer packets into
AXI-MM protocol to communicate with user design components in the FPGA. The
Device Under Test's (DUT) PCIe Master interface is connected to the Slave PCIe
port of the Slave bridge.

Features supported:

- DUT Protocol support - AXI4 and AXI4-Lite
- DUT AXI Data widths - 32, 64,128-bit
- Slave AXI interface to configure bridge registers - 32-bit AXI4-Lite slave
- Outstanding Transactions - As per AXI Master, Slave Bridge
- Mode of operation : Mode_0, Mode_1
- Interrupt support : Legacy PCIe only

Features not supported:

 - AXI AXUSER limitation as per AXI Master, Slave Bridge
 - MSI and MSI-X interrupts towards x86


# Top level block diagram

```

              +-----------------------------------+
              |                                   |
              |                                   |
              |                                   | usr_resetn
              |       +--------------------+      +---------------->
   clk        |       |                    |      |
 +------------>       |                    |      |
  resetn      |       |                    |      |
 +------------>       |                    |      |  M_AXI_USR_0
              |       |                    |      <------------------>
              |       |  PCIe-AXI Master   |      |   32b,64b,128b
              |       |  Bridge            |      |
S_AXI_PCIE_M0,|       |                    |      |  S_AXI_USR_0
S_AXI_PCIE_S0 |       |                    |      <------------------>
  <----------->       |                    |      |   32b,64b,128b
          32b |       |                    |      |
              |       +--------------------+      |
              |                                   |
              |                                   |
M_AXI_PCIE_M0,|                                   | usr_irq_req
M_AXI_PCIE_S0 |       +--------------------+      <---------------------+
   <----------+       |                    |      | 64b
         128b |       |                    |      |
              |       |                    |      | usr_irq_ack
              |       |                    |      +--------------------->
              |       |                    |      | 64b
              |       |   PCIe-AXI Slave   |      |
      irq_req |       |   Bridge           |      |
    <---------+       |                    |      | c2h_gpio_in
           2b |       |                    |      <---------------------+
              |       |                    |      | 256b
      irq_ack |       |                    |      |
    +---------+       |                    |      | h2c_gpio_out
           2b |       +--------------------+      +---------------------->
              |                                   | 256b
              +-----------------------------------+

```



N_NUM_MASTER_BRIDGE AXI-Master and N_NUM_SLAVE_BRIDGE AXI-Slave Bridges are
connected. Here, N_NUM_MASTER_BRIDGE and N_NUM_SLAVE_BRIDGE is of value 1. These
bridges are called "PCIe-AXI Master Bridge" and "PCIe-AXI Slave Bridge" from now
on.


S_AXI_PCIE_M0 is AXI4-Lite slave interface is used for configuration of
AXI-Master Bridge and S_AXI_PCIE_S0 is AXI4-Lite slave interface is used for
configuration of AXI-Slave Bridge M_AXI_PCIE_M0 is AXI4 Master interface towards
XDMA for AXI-Master-Bridge and M_AXI_PCIE_S0 is AXI4 Master interface towards
XDMA for AXI-Slave-Bridge.  M_AXI_USR_0 is AXI master interface is to be
connected to DUT and S_AXI_USR_0 is AXI slave interface is to be connected to
DUT.

Clock pin "clk" and reset pin "resetn" are common for all PCIe-AXI Bridges.

Pin irq_req and irq_ack is connected to each of the PCIe-AXI Bridge. i.e.
irq_req (bit-0) is connected to irq_req of PCIe-AXI Master Bridge-0, irq_req
(bit-1) is connected to irq_req of PCIe-AXI Slave Bridge-0. 

Pin usr_irq_req is connected to c2h_intr_in and usr_irq_ack is connected to
h2c_pulse_out of PCIe-AXI Master Bridge-0.

Other signals i.e. usr_resetn, c2h_gpio_in, h2c_gpio_out are connected to
corresponding pins of PCIe-AXI Master Bridge-0 only.



# RTL file hierarchy and organization

```
   pcie_ep.v
   |--> axi_master.v (axi_master_0) 
   |    |--> axi4_master.v / axi4_lite_master.v
   |    |    |--> axi_master_common.v
   |--> axi_slave.v (axi_slave_0)
   |    |--> axi4_slave.v / axi4lite_slave.v
   |    |    |--> axi_slave_allprot.v (i_axi_slave_allprot)
```

# Port Description

| Name                | Width/interface                           | I/O | Description                                                              |
|---------------------|-------------------------------------------|-----|--------------------------------------------------------------------------|
| clk                 | [0:0]                                     | I   | Clock Signal                                                             |
| resetn              | [0:0]                                     | I   | Active -Low reset                                                        |
| usr_resetn          | [USR_RST_NUM-1:0]                         | O   | Active -Low reset                                                        |
| irq_req             | [NUM_MASTER_BRIDGE+NUM_SLAVE_BRIDGE-1:0]  | O   | Interrupt to XDMA                                                        |
| irq_ack             | [NUM_MASTER_BRIDGE+NUM_SLAVE_BRIDGE-1:0]  | I   | Interrupt acknowledgement from XDMA                                      |
| usr_irq_req         | [63:0]                                    | I   | Interrupt from DUT                                                       |
| usr_irq_ack         | [63:0]                                    | O   | Interrupt acknowledgement from DUT                                       |
| c2h_gpio_in         | [255:0]                                   | I   | Card to Host control signals                                             |
| h2c_gpio_out        | [255:0]                                   | O   | Host to Card control signals                                             |
| s_axi_pcie_m<NUM>_* | S_AXI_PCIE_M<NUM>                         | -   | AXI4-Lite slave interface is used for configuration of AXI-Master Bridge |
| s_axi_pcie_s<NUM>_* | S_AXI_PCIE_S<NUM>                         | -   | AXI4-Lite slave interface is used for configuration of AXI-Slave Bridge  |
| m_axi_pcie_m<NUM>_* | M_AXI_PCIE_M<NUM>                         | -   | AXI4 Master interface towards XDMA for AXI-Master-Bridge                 |
| m_axi_pcie_s<NUM>_* | M_AXI_PCIE_S<NUM>                         | -   | AXI4 Master interface towards XDMA for AXI-Slave-Bridge                  |
| m_axi_usr_<NUM>_*   | M_AXI_USR_<NUM>                           | -   | AXI master interface is to be connected to DUT                           |
| s_axi_usr_<NUM>_*   | S_AXI_USR_<NUM>                           | -   | AXI slave interface is to be connected to DUT                            |

# Clocks
The Bridge IP uses a single clock "clk". This clock typically is connected from
PCIe controller's user clock domain. For Xilinx FPGA solutions, it is XDMA IP's
axi_aclk.

All the interfaces of the EP bridge operate on the same clock domain. User needs
to take care of clock conversions if needed to convert to a different clock
domain.

|Clock Name   |Associated Interface     |
|-------------|-------------------------|
|clk          |  All AXI interfaces     |

# Resets
The below table contains information about the resets used in the design.

|Reset Name   |	Associated Interface    |
|-------------|-------------------------|
|resetn       |  All AXI interfaces     |
|usr_resetn   |  -                      |

**resetn**
Design uses only one ACTIVE_LOW reset. This "resetn" is synchronised with
"clk".  Typically this is connected to axi_aresetn port of XDMA IP for Xilinx
use case.

**usr_resetn**
ACTIVE_LOW user soft reset.
Software can issue a soft reset to the user logic by setting bits DUT_SRST  in
RESET_REG.
usr_resetn is generated by ANDing resetn & corresponding DUT_SRST bit of
RESET_REG.


# Hardware Block Description

The pcie_ep module is wrapper of AXI-Master-Bridge and AXI-Slave-Bridge. For
more info on AXI-Bridge, read respective documents.

# Interrupt Handler

Same as AXI Master, Slave Bridge

# Error Handling/Reporting

Bridge generates Errors in case of protocol violations as per individual
PCIe-AXI Master and Slave Bridge.

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

