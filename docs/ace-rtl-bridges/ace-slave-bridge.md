**Table of Content**

   * [ACE Slave Bridge use-model](#ace-slave-bridge-use-model)
   * [Introduction](#introduction)
   * [Top level block diagram](#top-level-block-diagram)
   * [RTL file hierarchy and organization](#rtl-file-hierarchy-and-organization)
   * [Port Description](#port-description)
   * [Clocks](#clocks)
   * [Resets](#resets)
   * [Hardware Block Description](#hardware-block-description)
      * [Register Block](#register-block)
         * [Address Decoder](#address-decoder)
         * [Registers](#registers)
         * [WR DataRAM](#wr-dataram)
         * [WSTRB RAM](#wstrb-ram)
         * [RD DataRAM](#rd-dataram)
         * [CD DataRAM](#cd-dataram)
         * [RAM Access](#ram-access)
      * [User Slave Control (UC)](#user-slave-control-uc)
         * [ACE RD transaction](#ace-rd-transaction)
         * [ACE WR transaction](#ace-wr-transaction)
         * [ACE SN transaction](#ace-sn-transaction)
         * [TXN Allocator](#txn-allocator)
         * [Descriptor Allocator](#descriptor-allocator)
         * [Host Master Control](#host-master-control)
      * [Interrupt Handler](#interrupt-handler)
   * [Error Handling/Reporting](#error-handlingreporting)



# ACE Slave Bridge use-model

ACE Slave Bridge use-model with ACE Master Device Under Test (DUT) and PCIe Sub-system

```

                          _______________________________________________
 ______________          +          ___________________________          +         ______________
+              +         |        +                           +          |        +              +
|              |         +        |                           |          +------->+CLK           |
|         M_AXI+--------+)+------>+S_AXI                      |                   |              |
|              |         +        |                  S_ACE_USR+<------------------+M_ACE         |
|       AXI_CLK+---------+------->+CLK                        |                   |              |
|              |                  |                 USR_RESETN+------------------>+RSTN          |
|     AXI_RST_N+----------------->+RESETN                     |                   |              |
|              |                  |                           |                   |              |
|              |                  |                           |                   |              |
|   PCIe Core  |                  |                           |                   |              |
|       &      |                  |        ACE Slave          |                   |  ACE MASTER  |
|    AXI+MM    |                  |         BRIDGE            |                   |     DUT      |
|    Bridge    |                  |                           |                   |              |
|              |                  |                           |                   |              |
|              |                  |               H2C_INTR_OUT+------------------>+INTR_IN       |
|         S_AXI+<-----------------+M_AXI                      |                   |              |
|              |                  |                C2H_INTR_IN+<------------------+INTR_OUT      |
|        IRQ_IN+<-----------------+IRQ_OUT                    |                   |              |
|              |                  |                C2H_GPIO_IN+<------------------+GPIO_OUT      |
|       IRQ_ACK+----------------->+IRQ_ACK                    |                   |              |
|              |                  |               H2C_GPIO_OUT+------------------>+GPIO_IN       |
+______________+                  +___________________________+                   +______________+

```

# Introduction

This document covers the micro architecture details of the ACE Slave bridge.
The ACE Slave Bridge is referred to as "Slave Bridge" from here on for
simplicity. The Slave bridge communicates with x86 Host via PCIe Controller and
associated AXI-MM Bridge. The AXI-MM Bridge converts the PCIe transaction layer
packets into AXI-MM protocol to communicate with user design components in the
FPGA. The Device Under Test's (DUT) ACE Master interface is connected to the
Slave ACE port of the Slave bridge.

- Features supported:

	- ACE Data widths - 128-bit 
	- Slave AXI interface to configure bridge registers - 32-bit AXI4 Lite slave
	- Outstanding Transactions 
                - Multiple outstanding transactions on write and snoop channel. 
                - Maximum 16 outstanding transactions on read channel.
	- Mode of operation : Mode_0
	- Interrupt support : Legacy PCIe only


- Features supported but not tested

	- Modes of operation : Mode_1


- Features not supported:

        - AWUSER, BUSER, ARUSER supported. But value of WUSER for only last
          wdata cycle is captured in registers and only constant values of
          RUSER for all rdata cycles will be provided to DUT. 

	- MSI and MSI-X interrupts towards x86  

# Top level block diagram


```

             +-------------------------------------------------------------------------------------------------+
             |                                                                                                 |
             | +-------------------------------------------------------------------+   +------------------+    |   usr_resetn
             | |                               Register Block                      |   |                  |    |
             | | +--------+ +---------------------------------------------------+  |   |                  |    +---------------->
  clk        | | |  AXI   | |                     Registers                     |  |   |                  |    |
+------------> | | Slave  | +---------------------------------------------------+  |   |                  |    |
 resetn      | | |  and   | +---------------------------------------------------+  |   |                  |    |  S_ACE_USR
+------------> | | Address| |                 RAM Controller                    |  |   |                  |    |
     S_AXI   | | | Decoder| | +---------+  +---------+  +--------+  +---------+ |  |   | User Slave       |    <------------------>
   AXI4lite  | | |        | | |  Read   |  |  Write  |  |  Wstrb |  |Snoop(CD)| |  +<-->    Control       |    |
 <-----------> | +--------+ | | DataRAM |  | DataRAM |  |   RAM  |  |DataRAM  | |  |   |                  |    |   128b
     32b     | | +-------+  | +---------+  +---------+  +--------+  +---------+ |  |   |                  |    |
             | | |control|  +---------------------------------------------------+  |   |                  |    |
             | | | Logic |                       ^                                 |   |                  |    |
             | | |       |                       |                                 |   |                  |    |
             | | |       <-----------------------+                                 |   |                  |    |
             | | +-------+                                                         |   |                  |    |
             | +-------------------------------------^--------^--------------------+   |                  |    |
             |                                       |        |                        |                  |    |
             |           +----------------------+    |        |                        |                  |    |    h2c_intr_out
             |           |                      |    |  +-----v--------+               +------------------+_   |
     M_AXI   |           |                      |    |  | Interrupt    +------------------------------------------------------------>
             |           |                      |    |  | Handler      |                                       |    128b
  <---------------------->  Host Master Control <----+  |              |                                       |
     128b    |           |                      |       |              |                                       |   c2h_intr_in
             |           |                      |       |              |                                       |
             |           |                      |       |              <-------------------------------------------------------------+
             |           |                      |       +-----+----^---+                                       |     64b
     irq_out |           |                      |             |    |                                           |
             |           +----------------------+             |    |                                           |   c2h_gpio_in
   <----------------------------------------------------------+    |                                           |
             |                                                     |                                           <---------------------+
    irq_ack  |                                                     |                                           |    256b
             |                                                     |                                           |
   +---------------------------------------------------------------+                                           |  h2c_gpio_out
             |                                                                                                 |
             |                                                                                                 +---------------------->
             +-------------------------------------------------------------------------------------------------+    256b

```

# RTL file hierarchy and organization

```
  ace_slv.v
  |-->acefull_slv.v (i_acefull_slv)
  |   |-->ace_slv_allprot.v (i_ace_slv_allprot)
  |   |   |-->ace_usr_slv_control.v (i_ace_usr_slv_control)
  |   |   |   |-->ace_usr_slv_control_field(i_ace_usr_slv_control_field)
  |   |   |   |   |-->ace_slv_inf.v (i_ace_slv_inf)
  |   |   |   |   |   |-->ace_ctrl_valid.v (r_ace_ctrl_valid)
  |   |   |   |   |   |-->ace_ctrl_ready.v (cr_ace_ctrl_ready)
  |   |   |   |   |   |-->ace_ctrl_ready.v (cd_ace_ctrl_ready)
  |   |   |   |   |   |-->ace_ctrl_valid.v (b_ace_ctrl_valid)
  |   |   |   |   |   |-->ace_ctrl_ready.v (aw_w_ace_ctrl_ready)
  |   |   |   |   |   |-->ace_ctrl_ready.v (ar_ace_ctrl_ready)
  |   |   |   |   |   |-->ace_ctrl_valid.v (ac_ace_ctrl_valid)
  |   |-->ace_regs_slv.v (i_ace_regs_slv)
  |   |   -->wstrb_ram.v (u_wstrb_ram)
  |   |   -->wdata_ram.v (u_wdata_ram)
  |   |   -->rdata_ram.v (u_rdata_ram)
  |   |   -->cddata_ram.v (u_cddata_ram)
  |   |-->ace_intr_handler_slv.v (i_ace_intr_handler_slv)
  |   |-->ace_host_master_slv.v (i_ace_host_master_slv)
  |   |   |-->host_master_s.v (write_host_master_s)
  |   |   |   |-->axi_master_control.v(axi_master_control_inst_host)
  |   |   |   |   |-->wdata_channel_control_uc_master.v (wdata_control)
  |   |   |   |   |-->sync_fifo.v (rdata_fifo)
  |   |   |   |   |-->descriptor_allocator_uc_master.v (descriptor_allocator)
  |   |   |   |   |-->sync_fifo.v (bresp_fifo)
  |   |   |   |   |-->axid_store.v (awid_store)
  |   |   |   |   |-->axid_store.v (arid_store)
  |   |   |-->host_master_s.v (read_host_master_s)
  |   |   |   |-->axi_master_control.v(axi_master_control_inst_host)
  |   |   |   |   |-->wdata_channel_control_uc_master.v (wdata_control)
  |   |   |   |   |-->sync_fifo.v (rdata_fifo)
  |   |   |   |   |-->descriptor_allocator_uc_master.v (descriptor_allocator)
  |   |   |   |   |-->sync_fifo.v (bresp_fifo)
  |   |   |   |   |-->axid_store.v (awid_store)
  |   |   |   |   |-->axid_store.v (arid_store)

```


# Port Description

  
|Name	          |  Width/Interface	|   I/O   |	Description                                   |                  
|-----------------|---------------------|---------|---------------------------------------------------|
|clk              |    [0:0] 	        |   I	  |  Clock Signal                                     |
|resetn           |    [0;0]            |   I	  |  Active -Low reset                                |
|usr_resetn	  |    [USR_RST_NUM-1:0]|   O	  |  Active -Low reset                                |
|irq_out	  |    [0:0]	        |   O	  |  Interrupt to XDMA                                |
|irq_ack	  |    [0:0]	        |   I	  |  Interrupt acknowledgement from XDMA              |
|h2c_intr_out     |    [127:0]	        |   O	  |  Host to Card interrupt                           |
|c2h_intr_in      |    [63:0]	        |   I	  |  Card to Host interrupt                           |
|c2h_gpio_in      |    [255:0]	        |   I	  |  Card to Host control signals                     |
|h2c_gpio_out     |    [255:0]	        |   O	  |  Host to Card control signals                     |
|s_ace_usr_*      |    S_ACE_USR	|   -	  |  ACE slave interface towards DUT.                 |
|s_axi_*	  |    S_AXI	        |   -	  |  AXI4 Slave Interface towards XDMA.               |
|m_axi_*	  |    M_AXI	        |   -	  |  AXI4 Master Interface towards XDMA.              |


# Clocks

The Bridge IP uses a single clock "clk". This clock typically is connected from
PCIe controller's user clock domain. For Xilinx FPGA solutions, it is XDMA IP's
axi_aclk.

All the interfaces of the Slave bridge operate on the same clock domain. User
needs to take care of clock conversions if needed to convert to a different
clock domain.

|Clock Name   |Associated Interface     |
|-------------|-------------------------|
|clk          |  S_AXI                  |
|clk          |  M_AXI                  |
|clk          |  S_ACE_USR              |


# Resets

The below table contains information about the resets used in the design.

|Reset Name   |	Associated Interface 	|
|-------------|-------------------------|
|resetn       |  S_AXI                  |
|resetn       |  M_AXI                  |
|resetn       |  S_ACE_USR              |
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


## Register Block


```

           +-------------------------------------------------------------------------+
           |                              Register Block                             |
           |                                                                         |
           |  +-----------+  +-----------+                     +----------------+    |
           |  |           |  |           |                     |                |    |
           |  |           |  |           |                     |                |    |
           |  |           |  |           +--------------------->    Registers   <-------------------->
           |  |           |  |           |                     |                |    |Register Access
           |  |           |  |           |                     |                |    |to UC & HM
           |  |           |  |           |                     |                |    |
           |  |           |  |           |                     +----------------+    |
           |  |           |  |           |                                           |
           |  |           |  |           |              +-------------------------+  |
           |  |           |  |           |              |                         |  |
           |  |   AXI     |  |  Address  +-------------->                         |  |
           |  |   Slave   |  |  Decoder  |              |Write    RD DATA     Read|  |
  AXI4_LITE|  |   FSM     |  |           |              |port     RAM         port+--------------------->
<------------->           |  |           |              |                         |  |Read Access to 
           |  |           |  |           |      +------->                         |  |only UC Block
           |  |           |  |           |       From HM+-------------------------+  |
           |  |           |  |           |       (mode+1)                            |
           |  |           |  |           |               +------------------------+  |
           |  |           |  |           |               |                        |  |
           |  |           |  |           <---------------+                        |  |
           |  |           |  |           |               |Read     WSTRB     Write<---------------------
           |  |           |  |           |               |port     RAM        port|  |Write Access to 
           |  |           |  |           |      <--------+                        |  |only UC Block
           |  |           |  |           |          To HM+------------------------+  |
           |  |           |  |           |       (mode+1)                            |
           |  |           |  |           |               +-------------------------+ |
           |  |           |  |           |               |                         | |
           |  |           |  |           |               |                         | |
           |  |           |  |           <---------------+Read      WR DATA   Write<---------------------+
           |  |           |  |           |               |port      RAM       port | |Write Access to
           |  |           |  |           |      <--------+                         | |only UC Block
           |  |           |  |           |       To HM   +-------------------------+ |
           |  |           |  |           |       (mode+1)                            |
           |  |           |  |           |               +-------------------------+ |
           |  |           |  |           |               |                         | |
           |  |           |  |           |               |                         | |
           |  |           |  |           <---------------+Read     CD DATA    Write<---------------------+
           |  |           |  |           |               |port     RAM        port | |Write Access to 
           |  |           |  |           |               |                         | |only UC Block
           |  +-----------+  +-----------+               +-------------------------+ |
           |                                                                         |
           +-------------------------------------------------------------------------+

```

The register block implements the register space required as per Bridge's
requirements. The register block is accessible via an 32-bit AXI4 Lite
interface. The Bridge register space can be mapped to one of the PCIe Base
Address Registers (BARs). The overall addressing requirement for Bridge is 128
kB and it depends mainly on size of the RD/WR Data RAM. 

Currently, the RD/WR Data RAM, WSTRB RAM is 16KB, CD Data RAM is 1 KB. The
number of descriptors for read-request, read-response, write-request,
write-response, snoop-request, snoop-response, snoop-data is 16.  

### Address Decoder 
The address decoder block converts the AXI4Lite transactions into register
reads and writes. The AXI4Lite transactions are targeted to one of the
following regions of the register space.

### Registers

The Slave Bridge contains the following type of registers

General Registers : Contain many control and status registers of the bridge carrying general
information pertaining to a bridge and are independent of the protocol.  

General Config and Status Registers: Contain control and status registers
which pertain to a specific protocol. For ACE Bridge, these registers carry
information pertaining to ACE protocol like BRIDGE_CONFIG_REG,
INTR_STATUS_REG etc.

Descriptors: The descriptors contain information/attributes for
generating ACE transactions. The Host software programs the DESC_N* registers to
inform the HW bridge on the nature of ACE transaction to be generated. 


### WR DataRAM
The WDATA (Write data) of the ACE Transactions is saved in WR
DataRAM. This will be a Simple Dual PORT RAM, one port for WRITE, one port for
READ. In the current bridge design, the size of the Write DataRAM is 16KB.

### WSTRB RAM
The WSTRB (Write strobe) of the ACE Transactions is saved in WSTRB RAM. This
will be a Simple Dual PORT RAM, one port for WRITE, one port for READ.  In the
current bridge design, the size of the WSTRB RAM is 2KB.  The logic expands
wstrb of 1-bit per Byte to 8-bits per Byte thus SW sees WSTRB RAM as 16 KB.

### RD DataRAM
The RDATA (Read data, which is response for a read request) of the
ACE Transactions is saved in RD DataRAM. This will be a Dual PORT RAM, one port
for WRITE, one port for READ. In the current bridge design, the size of the RD
 DataRAM is 16KB.

### CD DataRAM
The CDDATA (snoop data) of the ACE Transactions is saved in CD
DataRAM. This will be a Simple Dual PORT RAM, one port for WRITE, one port for
READ. In the current bridge design, the size of the Write DataRAM is 1KB.

###  RAM Access

Following is the RAM access rules: 

- RD,WR DataRAM, WSTRB RAM
	- In Mode 0: Software driver can only read from the WR DataRAM/WSTRB RAM (no write access) and only Write into the RD DataRAM (no read access).  
	- In Mode 1: Software cannot access WR,RD DataRAM, WSTRB RAM. The host master control block (described in following sections) has read access to WR DataRAM
and Write access to RD DataRAM.

- CD DataRAM
	-Mode-1 is not applicable to snoop data. Therefore, always Register Block will
have only Write access to CD DataRAM (no read access).

## User Slave Control (UC)


User Slave Control Block interfaces with DUT over the S_ACE_USR interface. 

Main functionality of this block is to transfer data from RD DataRam as RDATA of
the S_ACE_USR interface for ACE read transactions. For ACE write transactions,
transfer WDATA received from DUT into the WR DataRAM. For ACE snop transactions,
transfer CDDATA received from DUT into the CD DataRAM.

### ACE RD transaction



```

               +-----------------------------------------------------------------------+
               |                                                                       |
               |  Usr Slave Read Path                                                  |
               |                                                                       |
               |                        +---------------+                              |
               |                        |               |                              |
               |                        |desc_allocator <-------------+                |
               |                        |               |             |                |
               |                        +-----+---------+             |                |
               |    +------------+            |                +------+------+         |
  Register     |    |            |            |                |             |         |    S_ACE_USR
               |    |            |            |                |             |         |
   <----------------+ ORDER_fifo <------------v----------------+ USR_fifo    <--------------------------+
               |    |            |                             |             |         |    (AR_channel)
               |    |            |                             |             |         |
               |    |            |                             |             |         |
               |    +------------+                             +-------------+         |
               |                                                                       |
               |                                                                       |
               |    +------------+        +------------+       +-------------+         |
               |    |            |        |            |       |             |         |
  Register     |    |            |        |            |       |             |         |    S_ACE_USR
               |    |            |        |            |       |             |         |
   +--------------->+ ORDER_fifo +--------> IDX_fifo   +--------> USR_fifo   +---+-------------------->
               |    |            |        |            |       |             |   |     |    (R_channel)
               |    |            |        |            |       |             |   |     |
               |    |            |  +----->            |       |             |   |     |
               |    |            |  |     |            |       |             |   |     |
               |    +------------+  |     +------------+       +-------------+   |     |
               |                    |                                            |     |
 Read from     |                    |                                            |     |
   +--------------------------------+                                            |     |
RD DATA RAM    |                                   +------------+                |     |
               |                                   |            |                |     |
               |                                   |            |                |     |
 Register      |                                   |            |                |     |
               |                                   | XACK_fifo  +----------------+     |
  <---------------------------------------^--------+            |                      |
               |                          |        |            |                      |
               |                          |        |            |                      |     S_ACE_USR
               |                          |        +------------+                      |
               |                          +-----------------------------------------------------------+
               |                                                                       |      (RACK)
               |                                                                       |
               +-----------------------------------------------------------------------+

```

All AR-signals are stored in request-USR_fifo.

Upon getting available descriptors via RD_REQ_FREE_DESC_REG for one or more
descriptors from SW, it waits for non-empty condition of request-USR_fifo. Once
there is one or more entries in request-USR_fifo, the desc_allocator block will
calculate descriptor. This descriptor is stored to request-ORDER_fifo to let
software know the order of incoming AR-requests. The ISR (Interrupt Status
Register) is updated on non-empty condition of this ORDER_fifo.

When SW writes to RD_RESP_FIFO_PUSH_DESC_REG, the read-response descriptor is
stored into response-ORDER_fifo. 

For mode-1, "uc2hm_trig" control signal to Host master control is
generated. Upon receiving "hm2uc_done" from Host master control, read response
for corresponding descriptor should be generated.

On non-empty condition of response-ORDER_fifo (and "hm2uc_done" in mode-1
case), descriptor is popped out and stored into IDX_fifo.

Later, descriptor number is popped from IDX_fifo and corresponding rdata is
read out from RDATA RAM. All R-channel signals are stored into
response-USR_fifo. The signals are popped from USR_fifo and read response is
generated towards DUT.  Upon generating rlast the descriptor in stored in
XACK_fifo.

Upon receiving rack, a descriptor is popped out from XACK_fifo and
corresponding RD_RESP_INTR_COMP_STATUS_REG bit is asserted and update
RD_RESP_COMP in ISR.

### ACE WR transaction


```

                     +-------------------------------------------------------------------+
                     |                                                                   |
                     | Usr Slave Write Path                                              |
                     |                                                                   |
                     |                          +-----------+                            |
 Write to WR DATA RAM|                          |           |                            | S_ACE_USR
   <--------------------------------------------+           |                            |
       & WSTRB RAM   |                          |USR_fifo   <----------------------------------------+
                     |                     +----+           |                            | (W_channel)
                     |                     |    |           |                            |
                     |                     |    |           |                            |
                     |     +------------+  |    +-----------+                            |
                     |     |            |  |                                             |
                     |     |            |  |                                             |
     Register        |     | ORDER_fifo <--+     +------------+      +---------------+   |
    <----------------------+            |  |     |            |      |               |   |
                     |     |            |  |     |            |      |               |   | S_ACE_USR
                     |     |            |  |     | AW_W_fifo  |      | Txn_allocator |   |
                     |     |            |  +-----+            <------+               <-------------+
                     |     +------------+        |            |      |               |   | (AW_channel)
                     |                           |            |      |               |   |
                     |                           +------------+      +---------------+   |
                     |                                                                   |
                     |                                                                   |
                     |                                                                   |
                     |                                                                   |
                     |                                                                   |
                     |    +-----------+        +-------------+      +------------+       |
                     |    |           |        |             |      |            |       |
                     |    |           |        |             |      |            |       | S_ACE_USR
      Register       |    | ORDER_fifo|        |  IDX_fifo   |      | USR_fifo   |       |
    +--------------------->           +-------->             +------->           +---+------------>
                     |    |           |        |             |      |            |   |   | (B_channel)
                     |    |           |        |             |      |            |   |   |
                     |    +-----------+        +-------------+      +------------+   |   |
                     |                                                               |   |
                     |                                                               |   |
                     |                                              +------------+   |   |
                     |                                              |            |   |   |
                     |                                              |            |   |   |
     Register        |                                              | XACK_fifo  |   |   |
     <-------------------------------------------------^------------+            <---+   |
                     |                                 |            |            |       |
                     |                                 |            |            |       |
                     |                                 |            |            |       |
                     |                                 |            +------------+       | S_ACE_USR
                     |                                 |                                 |
                     |                                 +----------------------------------------------
                     |                                                                   | (WACK)
                     +-------------------------------------------------------------------+

```

Upon getting available descriptors via WR_REQ_FREE_DESC_REG for one or more
descriptors from SW, it waits for AW to arrive from DUT. Once a
request arrives, the TXN allocator block will calculate descriptor and
corresponding offset address. These descriptors are stored in AW_W_fifo for
transaction ordering.

All W-signals are stored in request-USR_fifo.

In Mode-0, the descriptor number is popped from AW_W_fifo and content from
request-USR_fifo goes to WDATA and WSTRB RAMs. This descriptor is stored to
request-ORDER_fifo to let software know the order of incoming AW-requests. 

In Mode-1, the descriptor number is popped from AW_W_fifo and content from
request-USR_fifo goes to WDATA and WSTRB RAMs. Then it signals (via
"uc2hm_trig" control signal)  Host master control; which will write the
WSTRB/WDATA into host buffers. Upon receiving "hm2uc_done" from Host master
control, descriptor is stored to request-ORDER_fifo to let software know the
order of incoming AW-requests.


This descriptor is stored to request-ORDER_fifo to let software know the order
of incoming AW-requests. The ISR (Interrupt Status Register) is updated on
non-empty condition of this ORDER_fifo.

When SW writes to WR_RESP_FIFO_PUSH_DESC_REG, the write-response descriptor is
stored into response-ORDER_fifo. 

On non-empty condition of ORDER_fifo, descriptor is popped out and stored into
IDX_fifo.

Later, descriptor number is popped from IDX_fifo and all B-channel signals are
stored into response-USR_fifo. The signals are popped from USR_fifo and write
response is generated towards DUT. Also, the descriptor in stored in XACK_fifo.

Upon receiving wack, a descriptor is popped out from XACK_fifo and
corresponding WR_RESP_INTR_COMP_STATUS_REG bit is asserted and update
WR_RESP_COMP in ISR.



### ACE SN transaction



```

                 +-----------------------------------------------------------+
                 |                                                           |
                 | USR Slave Snoop Path                                      |
                 |                                                           |
                 |                                                           |
                 |   +------------+     +-------------+     +------------+   |
                 |   |            |     |             |     |            |   |
                 |   |            |     |             |     |            |   |
Register         |   | ORDER_fifo |     |  IDX_fifo   |     |  USR_fifo  |   |   S_ACE_USR
    +---------------->            +----->             +----->            +---------->
                 |   |            |     |             |     |            |   |  (AC_channel)
                 |   |            |     |             |     |            |   |
                 |   |            |     |             |     |            |   |
                 |   +------------+     +-------------+     +------------+   |
                 |                                                           |
                 |                     +----------------+                    |
                 |                     |                <--------+           |
                 |                     | desc_allocator |        |           |
                 |    +-----------+    |                |   +----+-------+   |
                 |    |           |    +-------+--------+   |            |   |
Register         |    | ORDER_fifo|            |            | USR_fifo   |   |   S_ACE_USR
     <----------------+           |            |            |            <-----------+
                 |    |           |            |            |            |   |   (CR_channel)
                 |    |           <------------v------------+            |   |
                 |    |           |                         |            |   |
                 |    +-----------+                         +------------+   |
                 |                     +---------------+                     |
                 |                     | Txn_allocator |                     |
                 |                     |               <----------+          |
                 |                     +-------+-------+          |          |
                 |    +------------+           |            +-----+------+   |
                 |    |            |           |            |            |   |
Register         |    | ORDER_fifo |           |            | USR_fifo   |   |   S_ACE_USR
     <----------------+            <-----------v------------+            <------------+
                 |    |            |                        |            |   |   (CD_channel)
                 |    |            |                        |            |   |
                 |    |            |                     +--+            |   |
                 |    +------------+                     |  +------------+   |
                 |                                       |                   |
                 |                                       |                   |
     <---------------------------------------------------++                  |
Write to         |                                                           |
CD DATA RAM      +-----------------------------------------------------------+

```

When SW writes to SN_REQ_FIFO_PUSH_DESC_REG, the snoop-request descriptor is
stored into AC-ORDER_fifo.

On non-empty condition of AC-ORDER_fifo, descriptor is popped out and stored into
AC-IDX_fifo.

Descriptor number is popped from AC-IDX_fifo. All AC-channel signals are stored
into AC-USR_fifo. The signals are popped from AC-USR_fifo and AC-request is
generated towards DUT. 

Upon generating AC, the SN_REQ_INTR_COMP_STATUS_REG bit is asserted and update
SN_REQ_COMP in ISR.  

All CR-signals are stored in CR-USR_fifo.

Upon getting available descriptors via SN_RESP_FREE_DESC_REG for one or more
descriptors from SW, it waits for non-empty condition of CR-USR_fifo. Once there
is one or more entries in CR-USR_fifo, the desc_allocator block will provide
descriptor.

The descriptor is stored to CR-ORDER_fifo to let software know the order of
incoming snoop-responses. The ISR (Interrupt Status Register) is updated on non-empty
condition of this CR-ORDER_fifo.

All CD-signals are stored in CD-USR_fifo.

Upon getting available descriptors via SN_DATA_FREE_DESC_REG for one or more
descriptors from SW, it waits for non-empty condition of CD-USR_fifo. Once there
is one or more entries in CD-USR_fifo, the txn_allocator block will provide
descriptor and offset address.

Upon cdlast, the descriptor is stored to CD-ORDER_fifo to let software know the order of
incoming cdlasts. The ISR (Interrupt Status Register) is updated on non-empty
condition of this CD-ORDER_fifo.



### TXN Allocator

```
         +-----------------------------------------------------------------+
         |                                                                 |
         |  User TXN Allocator                                             |
         |                                                                 |
         |       +--------------------------------+      +--------------+  |
         |       |     Descriptor Allocator       |      |              |  |
         |       |     +-----------+              |      |              |  |
         |       |     |           |              |      |              |  |
         |       |     |           |              +----->+              |  |
         |   +-->+     | DESC_fifo |              |      |              |  |
         |   |   |     |           |              |      |              |  |
         |   |   |     |           |              |      |              |  |
         |   |   |     +-----------+              |      |              |  |
         |   |   +--------------------------------+      |              |  |
         |   |                                           |              |  |
         |   |   +--------------------------------+      |              |  |
    txn  |   |   |     Address Allocator          |      |              |  |Allocation
+------------+   |  +---------------------------+ |      | Transaction  +------------>
         |   |   |  |                           | |      |  Allocator   |  |
         |   |   |  |           Address         | |      |              |  |
         |   |   |  |           Allocator       | |      |              |  |
         |   |   |  |                           | |      |              |  |
         |   |   |  |      +-----------------+  | |      |              |  |
         |   |   |  |    +-----------------+ |  | |      |              |  |
         |   |   |  |  +-----------------+ | |  | |      |              |  |
         |   |   |  |  |                 | | |  | +------>              |  |
         |   +--->  |  |                 | | |  | |      |              |  |
         |       |  |  |                 | | |  | |      |              |  |
         |       |  |  |   Linked List   | | |  | |      |              |  |
         |       |  |  |                 | | |  | |      |              |  |
         |       |  |  |                 | | |  | |      |              |  |
         |       |  |  |                 | +-+  | |      |              |  |
         |       |  |  |                 +-+    | |      |              |  |
         |       |  |  +-----------------+      | |      |              |  |
         |       |  |                           | |      |              |  |
         |       |  +---------------------------+ |      |              |  |
         |       +--------------------------------+      +--------------+  |
         |                                                                 |
         +-----------------------------------------------------------------+


```

It comprises of 3 main blocks
Descriptor allocator 
Addresss allocator 
Transaction allocator

Addresss Allocator: 

For RD/WR txn :
Offset addresses for write data RAM and wstrb are RAM
will be always same. Therefore, Address identical allocation block is used for
write and read path. Address allocation block implements a linked list of
nodes which indicate busy/used regions of memory. Each node carries information
of memory start and end offset, node index of its own in linked list and
descriptor number. The memory start/end offset of these nodes are always in
ascended sorting order. Linked list can have upto MAX_DESC number of nodes.

Upon reset, linked list has no nodes or in other words linked list doesn't
exist. Upon AXI request from DUT with length AXLEN, memory start address is
computed and a new node is created with difference of memory start and end
address(data fields) equal to AXLEN. This process repeats for further AXI
requests as well. 

When one or more descriptors are being freed up, the corresponding nodes will be
removed from linked list. Thus, Linked list will always indicate only busy or in
progress region of memory only.

For Snoop txn :
Snoop data is always of CACHE_LINE_SIZE (64 Bytes), MAX_DESC is 16, size of
CDDATA RAM is 1 kByte. This means there would always be space for CDDATA.

Offset address of any snoop descriptor is calculated by
(DESC_N*CACHE_LINE_SIZE).

Transaction Allocator: 
When both descriptor number and offset address of
internal RAM is allocated to txn, transaction allocation is
completed. This block is important because number of logic cycles consumed by
above both blocks may or may not be same as they depend on availability of
descriptor and memory.

### Descriptor Allocator

```

                    +----------------------------------+
                    |       Descriptor Allocator       |
                    |       +-----------------+        |
                    |       |                 |        |
                    |       |                 |        |
                    |       |                 |        |
                    |       |                 |        |    Allocattion
       txn          |       |                 |        +-------------------->
    +---------------+       |    DESC_fifo    |        |
                    |       |                 |        |
                    |       |                 |        |
                    |       |                 |        |
                    |       |                 |        |
                    |       |                 |        |
                    |       +-----------------+        |
                    +----------------------------------+

```

A descriptor number is pushed into DESC_fifo when SW writes to FREE_DESC_REG.
This block allocates a new descriptor number to txn when at least one
descriptor is available or when DESC_fifo is not empty.  


### Host Master Control


```

                   +--------------------------------------------------------------+
                   |                                                              |
                   | +--------------------------------------------------------+   |
                   | |                                                        |   |
                   | |                                                        |   |
                   | |      Ownership Control & Data Packing/Unpacking        |   |
       RDATA       | |                                                        |   |
<------------------+ |                                                        |   |
                   | +--------------------------------------------------------+   |AXI4-128 Bit data width
       WDATA       |                                                              <----------------------->
+------------------>                                                              |
                   |     +-----------------------------------------------+        |
       WSTRB       |     |                                               |        |
+------------------>     |                                               |        |
                   |     |                                               |        |
Registers Interface|     |                                               |        |
<------------------>     |           AXI_Master_Control                  |        |
                   |     |                                               |        |
                   |     |                                               |        |
                   |     |                                               |        |
                   |     +-----------------------------------------------+        |
                   |                                                              |
                   +--------------------------------------------------------------+

```



HOST Master Control Block is used only in Mode-1 operation of the bridge. The
bridge uses M_AXI interface to drive read/write requests towards x86 host via
the PCIe controller and AXI-MM logic. 

AXI WR transaction: 
Once User Slave Control receives a Write Request, after accepting WR Request and
getting all data into the WR DATA RAM & WSTRB RAM, User Slave Control will
trigger Host Master Control to push WDATA & WSTRB from WDATA RAM & WSTRB RAM to
Host Buffers. Host Master Control will issue two write requests, one for WDATA
and second for WSTRB at the Host Addresses provided in registers. After pushing
WDATA & WSTRB is done, User Slave Control will initiate its normal Mode-0
Operation of completing register updates and giving responses back.

AXI RD transaction:
Once User Slave Control gets a Read Request, after accepting RD Request, it will
trigger Host Master Control to fetch RDATA from Host Buffers. Host Master
Control will issue a read request to fetch RDATA from Host Address provided in
registers. After fetching RDATA, Host Master Control will place it in the RDATA
RAM. User Slave Control initiates its normal Mode-0 Operation of giving response
of Read request.


## Interrupt Handler 

For propagating interrupts from x86 Host to DUT in the FPGA
and vice-versa, the Master Bridge has provision for generating interrupts.
Interrupts from Host to the FPGA DUT are called Host to Card (H2C) interrupts
and from FPGA DUT tox86 Host are called Card to Host (C2H) interrupts.

The H2C interrupts generated by Host can be connected to DUT by using
h2c_irq_out ports. 

The DUT generated interrupts should be connected to c2h_irq_in
ports. These interrupts can be translated to Legacy/MSI or MSI-X interrupts over
PCIe controller to Host.

The Bridge also generates interrupts to Host for indicating transaction
completions. The interrupt handler block streamlines the C2H interrupts and its
own completion interrupts and forwards to PCIe controller solution. The bridge
uses "irq_out" to generate interrupts and waits for an acknowledgement "irq_ack"
before sending the next interrupt. The "irq_ack" is sent by the PCIe controller
after the "irq_out" translates to a PCIE Legacy interrupt Message TLP on the
PCIe link.

The interrupt clear and mask registers control enablement and disablement of the
interrupts as per software's discretion.


# Error Handling/Reporting


Bridge generates Errors in case of following protocol violations. 

- Incorrect WLAST Assertion:
        - If DUT Asserts incorrect WLAST. ( i.e. for a WR transaction, number
          of wdata transfers does not match with awlen)

- Incorrect CDLAST Assertion
        - If DUT Asserts incorrect CDLAST. ( i.e. for a Snoop transaction,
          number of cddata transfers does not match with equation of
          (CACHE_LINE_SIZE/data-width) )






