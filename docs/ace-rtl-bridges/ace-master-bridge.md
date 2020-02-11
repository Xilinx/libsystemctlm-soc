**Table of Content**

   * [ACE Master Bridge use-model](#ace-master-bridge-use-model)
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
      * [User Master Control (UC)](#user-master-control-uc)
         * [ACE RD transaction](#ace-rd-transaction)
         * [ACE WR transaction](#ace-wr-transaction)
         * [ACE SN transaction](#ace-sn-transaction)
         * [AXIID Store](#axiid-store)
         * [Host Master Control](#host-master-control)
      * [Interrupt Handler](#interrupt-handler)
   * [Error Handling/Reporting](#error-handlingreporting)

# ACE Master Bridge use-model

System Level view and connections with ACE Bridges in FPGA

ACE Master Bridge use-model with ACE Slave Device Under Test (DUT) and PCIe Sub-system

```
        
                                  _______________________________________________
         ______________          +          ___________________________          +         ______________
        +              +         |        +                           +          |        +              +
        |              |         +        |                           |          +------->+CLK           |
        |         M_AXI+--------+)+------>+S_AXI                      |                   |              |
        |              |         +        |                  M_ACE_USR+------------------>+S_ACE         |
        |       AXI_CLK+---------+------->+CLK                        |                   |              |
        |              |                  |                 USR_RESETN+------------------>+RSTN          |
        |     AXI_RST_N+----------------->+RESETN                     |                   |              |
        |              |                  |                           |                   |              |
        |              |                  |                           |                   |              |
        |   PCIe Core  |                  |                           |                   | ACE Slave    |
        |       &      |                  |        ACE MASTER         |                   | DUT          |
        |    AXI+MM    |                  |         BRIDGE            |                   |              |
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

This document covers the micro architecture details of the ACE Master bridge.
The ACE Master Bridge is referred to as "Master Bridge" from here on for
simplicity. The Master bridge communicates with x86 Host via PCIe Controller
and associated AXI-MM Bridge. The AXI-MM Bridge converts the PCIe transaction
layer packets into AXI-MM protocol to communicate with user design components
in the FPGA.  The Device Under Test's (DUT) ACE Slave is connected to the
Master ACE port of the Master bridge.

- Features supported

	- ACE Data width - 128-bit 
	- Slave AXI interface to configure bridge registers - 32-bit AXI4 Lite slave
	- Outstanding Transactions 
                - Multiple outstanding transactions on write and snoop channel. 
                - Maximum 16 outstanding transactions on read channel.
        - Read reordering
                - Read data reordering depth is 16
	- Mode of operation : Mode_0
	- Interrupt support : Legacy PCIe only


- Features supported but not tested

	- Modes of operation : Mode_1


- Features not supported

	- WUSER for each beat of a transaction : Software can program only single value per descriptor into the Master Bridge. Master Bridge will keep WUSER Constant throughout single transfer for corresponding descriptor.
	- RUSER for each beat of a transaction : Master Bridge will always provide RUSER corresponding to RLAST.  intermediate RUSER will be ignore/Not stored.  
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
 resetn      | | |  and   | +---------------------------------------------------+  |   |                  |    |  M_ACE_USR
+------------> | | Address| |                 RAM Controller                    |  |   |                  |    |
     S_AXI   | | | Decoder| | +---------+  +---------+  +--------+  +---------+ |  |   | User Master      |    <------------------>
   AXI4lite  | | |        | | |  Read   |  |  Write  |  |  Wstrb |  |Snoop(CD)  |  |<-->    Control       |    |
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
     128b    |           |                      |       |              |                                       |    c2h_gpio_in
             |           |                      |       |              |                                       |
             |           |                      |       |              <-------------------------------------------------------------+
             |           |                      |       +-----+----^---+                                       |     64b
     irq_out |           |                      |             |    |                                           |
             |           +----------------------+             |    |                                           |   c2h_gpio_in
   <----------------------------------------------------------+    |                                           |
             |                                                     |                                           <----------------------
    irq_ack  |                                                     |                                           |    256b
             |                                                     |                                           |
   +---------------------------------------------------------------+                                           |  h2c_gpio_out
             |                                                                                                 |
             |                                                                                                 +---------------------->
             +-------------------------------------------------------------------------------------------------+    256b

```

# RTL file hierarchy and organization

```
  ace_mst.v
  |-->acefull_mst.v (i_acefull_mst)
  |   |-->ace_mst_allprot.v (i_ace_mst_allprot)
  |   |   |-->ace_usr_mst_control.v (i_ace_usr_mst_control)
  |   |   |   |-->ace_usr_mst_control_field(i_ace_usr_mst_control_field)
  |   |   |   |   |-->ace_mst_inf.v (i_ace_mst_inf)
  |   |   |   |   |   |-->ace_ctrl_ready.v (ac_ace_ctrl_ready)
  |   |   |   |   |   |-->ace_axid_store.v (ace_arid_store)
  |   |   |   |   |   |-->ace_ctrl_valid.v (ar_ace_ctrl_valid)
  |   |   |   |   |   |-->ace_ctrl_valid.v (aw_ace_ctrl_valid)
  |   |   |   |   |   |-->ace_ctrl_ready.v (b_ace_ctrl_ready)
  |   |   |   |   |   |-->ace_ctrl_valid.v (cd_ace_ctrl_valid)
  |   |   |   |   |   |-->ace_ctrl_valid.v (cr_ace_ctrl_valid)
  |   |   |   |   |   |-->ace_mst_rd_resp_ready.v (r_ace_mst_rd_resp_ready)
  |   |   |   |   |   |-->ace_ctrl_valid.v (w_ace_ctrl_valid)
  |   |-->ace_regs_mst.v (i_ace_regs_mst)
  |   |   -->wstrb_ram.v (u_wstrb_ram)
  |   |   -->wdata_ram.v (u_wdata_ram)
  |   |   -->rdata_ram.v (u_rdata_ram)
  |   |   -->cddata_ram.v (u_cddata_ram)
  |   |-->ace_intr_handler_mst.v (i_ace_intr_handler_mst)
  |   |-->ace_host_mst_mst.v (i_ace_host_mst_mst)
  |   |   |-->host_master_m.v (write_host_master_m)
  |   |   |   |-->axi_master_control.v(axi_master_control_inst_host)
  |   |   |   |   |-->wdata_channel_control_uc_master.v (wdata_control)
  |   |   |   |   |-->sync_fifo.v (rdata_fifo)
  |   |   |   |   |-->descriptor_allocator_uc_master.v (descriptor_allocator)
  |   |   |   |   |-->sync_fifo.v (bresp_fifo)
  |   |   |   |   |-->axid_store.v (awid_store)
  |   |   |   |   |-->axid_store.v (arid_store)
  |   |   |-->host_master_m.v (read_host_master_m)
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
|m_ace_usr_*      |    M_ACE_USR	|   -	  |  ACE Master interface towards DUT.                |
|s_axi_*	  |    S_AXI	        |   -	  |  AXI4 Slave Interface towards XDMA.               |
|m_axi_*	  |    M_AXI	        |   -	  |  AXI4 Master Interface towards XDMA.              |


# Clocks

The Bridge IP uses a single clock "clk". This clock typically is connected from
PCIe controller's user clock domain. For Xilinx FPGA solutions, it is XDMA IP's
axi_aclk.

All the interfaces of the Master bridge operate on the same clock domain. User
needs to take care of clock conversions if needed to convert to a different
clock domain.

|Clock Name   |	Associated Interface 	|
|-------------|-------------------------|
|clk          |  S_AXI                  |
|clk          |  M_AXI                  |
|clk          |  M_ACE_USR              |


# Resets


The below table contains information about the resets used in the design.

|Clock Name   |	Associated Interface 	|
|-------------|-------------------------|
|resetn       |  S_AXI                  |
|resetn       |  M_AXI                  |
|resetn       |  M_ACE_USR              |
|---------------------------------------|
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

                +-----------------------------------------------------------------+
                |                        Register Block                           |
                |                                                                 |
                |  +-------+  +---------+                   +----------------+    |
                |  |       |  |         |                   |                |    |
                |  |       |  |         |                   |                |    |
                |  |       |  |         +------------------->    Registers   <-------------------->
                |  |       |  |         |                   |                |    |Register Access
                |  |       |  |         |                   |                |    |to UC & HM
                |  |       |  |         |                   +----------------+    |
                |  |       |  |         |                                         |
                |  |       |  |         |            +-------------------------+  |
                |  |       |  |         |            |                         |  |
                |  | AXI   |  | Address +------------>                         |  |
                |  | Slave |  | Decoder |            |Write    WRDATA      Read|  |
      AXI4_LITE |  | FSM   |  |         |            |port     RAM         port+----------------->
      <------------>       |  |         |            |                         |  |Read Access to
                |  |       |  |         |    +------->                         |  |only UC Block
                |  |       |  |         |     From HM+-------------------------+  |
                |  |       |  |         |     (mode+1)                            |
                |  |       |  |         |             +------------------------+  |
                |  |       |  |         |             |                        |  |
                |  |       |  |         +------------->                        |  |
                |  |       |  |         |             |Write    WSTRB      Read+------------------>
                |  |       |  |         |             |port     RAM        port|  |Read Access to
                |  |       |  |         |    +-------->                        |  |only UC Block
                |  |       |  |         |     From HM +------------------------+  |
                |  |       |  |         |     (mode+1)                            |
                |  |       |  |         |             +-------------------------+ |
                |  |       |  |         |             |                         | |
                |  |       |  |         |             |                         | |
                |  |       |  |         <-------------+Read      RD DATA   Write+------------------>
                |  |       |  |         |             |port      RAM       port | |Write Access to
                |  |       |  |         |    <--------+                         | |only UC Block
                |  |       |  |         |     To HM   +-------------------------+ |
                |  |       |  |         |     (mode+1)                            |
                |  |       |  |         |             +------------------------+  |
                |  |       |  |         |             |                        |  |
                |  |       |  |         +------------->         CD DATA        |  |
                |  |       |  |         |             |Write    RAM        Read+------------------>
                |  |       |  |         |             |port                port|  |Read Access to
                |  |       |  |         |             |                        |  |only UC Block
                |  +-------+  +---------+             +------------------------+  |
                |                                                                 |
                +-----------------------------------------------------------------+

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
The address decoder block converts the AXI4Lite transactions
into register reads and writes. The AXI4Lite transactions are targeted to one of
the following regions of the register space.

### Registers
The Master Bridge contains the following type of registers.

General Config and Status Registers: Contains many control and status registers
of the bridge carrying general information pertaining to a bridge and are
independent of the protocol.  

Protocol Specific Registers: Contains control and status registers which
pertain to a specific protocol. For ACE Bridge, these registers carry
information pertaining to ACE protocol like BRIDGE_CONFIG_REG,
INTR_STATUS_REG etc.

Descriptors: The descriptors contain information/attributes for
generating ACE transactions. The Host software programs the DESC_N* registers to
inform the HW bridge on the nature of ACE transaction to be generated. 

### WR DataRAM 
The WDATA (Write data) of the ACE Transactions is saved in WR DataRAM. This
will be a Simple Dual PORT RAM, one port for WRITE, one port for READ. In the
current bridge design, the size of the Write DataRAM is 16KB.

### WSTRB RAM
The WSTRB (Write strobe) of the ACE Transactions is saved in WSTRB RAM. This
will be a Simple Dual PORT RAM, one port for WRITE, one port for READ. In the
current bridge design, the size of the WSTRB RAM is 2KB. The logic expands
wstrb of 1-bit per Byte to 8-bits per Byte thus SW sees WSTRB RAM as 16 KB.

### RD DataRAM
The RDATA (Read data, which is response for a read request) of the AXI
Transactions is saved in RD DataRAM. This will be a Simple Dual PORT RAM, one
port for WRITE, one port for READ. In the current bridge design, the size of
the RD DataRAM is 16KB.

### CD DataRAM
The CDDATA (snoop data) of the ACE Transactions is saved in CD DataRAM. This
will be a Simple Dual PORT RAM, one port for WRITE, one port for READ. In the
current bridge design, the size of the Write DataRAM is 1KB.

###  RAM Access

Following are the DataRAM access rules: 

RD,WR DataRAM, WSTRB RAM
        - In Mode 0: Register Block can only write to the WR DataRAM/WSTRB RAM
          (no read access) & only Read from RD DataRAM (no write access).
        - In Mode 1: Register block cannot access DataRAMs. The host master
          control block (described in following sections)  has Write access to
          WR DataRAM and Read access to RD DataRAM.

CD DataRAM
        - Mode-1 is not applicable to snoop data. Therefore, always Register
          Block will have only write access to CD DataRAM (no read access).

## User Master Control (UC)


User Master Control Block interfaces with DUT over the M_ACE_USR interface. Main
functionality of this block is to transfer data from WR DataRam as WDATA of the
M_ACE_USR interface for ACE write transactions. For ACE Read transactions,
transfer RDATA received from DUT into the RD DataRAM. For ACE Snoop
transactions, transfer data from CD DataRam as CDDATA of the M_ACE_USR
interface.

### ACE RD transaction

```

                   +-------------------------------------------------------------------+
                   |                                                                   |
                   | Usr Master Read Path                                              |
                   |                                                                   |
                   |                                                                   |
                   |    +-----------+   +-----------+    +----------+   +---------+    |
   Register        |    |           |   |           |    |          |   |         |    |     M_ACE_USR
                   |    |           |   |           |    |          |   |         |    |
    +-------------------> ORDER_fifo+---> addr_     +----> IDX_fifo +--->USR_fifo +-+----------------->
                   |    |           |   |           |    |          |   |         | |  |
                   |    |           |   |  allocator|    |          |   |         | |  |    (AR_channel)
                   |    |           |   |           |    |          |   |         | |  |
                   |    |           |   |           |    |          |   |         | |  |
                   |    +-----------+   +-----------+    +----------+   +---------+ |  |
                   |                                                                |  |
                   |                                          +------------+        |  |
                   |                                          |            |        |  |
                   |                                          |            |        |  |
                   |                                     +----+ ARID store <--------+  |
                   |                                     |    |            |           |
                   |                                     |    |            |           |
                   |                                     |    |            |           |
                   |                                     |    +------------+           |
                   |                                     |                             |
                   |                 +-------------+     |       +------------+        |
                   |                 |             |     |       |            |        |
     Register      |                 |             |     |       |            |        |   M_ACE_USR
                   |                 | ORDER_fifo  |     |       | USR_fifo   |        |
      <------------------------------+             <-----v-------+            <-----------------------+
                   |                 |             |             |            |        |
                   |                 |             |   +---------+            |        |   (R_channel)
                   |                 |             |   |   +-----+            |        |
                   |                 +-------------+   |   |     +------------+        |
Write to RD DATA   |                                   |   |                           |
   RAM             |                                   |   |                           |   M_ACE_USR
     <-------------------------------------------------+   |                           |
                   |                                       +-------------------------------------------->
                   |                                                                   |   (RACK)
                   |                                                                   |
                   +-------------------------------------------------------------------+
```

When SW writes to RD_REQ_FIFO_PUSH_DESC_REG, the read-request descriptor is
stored into AR-ORDER_fifo.

On non-empty condition of AR-ORDER_fifo, the address allocation of RDDATA RAM
is performed for requested size. Then, descriptor is popped out and stored into
AR-IDX_fifo.

Descriptor number is popped from AR-IDX_fifo. All AR-channel signals are stored
into AR-USR_fifo. The signals are popped from AR-USR_fifo and AR-request is
generated towards DUT. 

Upon generating AR, the RD_REQ_INTR_COMP_STATUS_REG bit is asserted and update
RD_REQ_COMP in ISR. Also, the descriptor and arid is provided to ARID-store
block. 

All R-signals are stored in B-USR_fifo.

Upon getting available descriptors via RD_RESP_FREE_DESC_REG for one or more
descriptors from SW, it waits for non-empty condition of R-USR_fifo. Once there
is one or more entries in R-USR_fifo, the ARID-store block will provide
matching descriptor (rid should match with arid). The offset counter per
descriptor for RDDATA RAM is maintained for subsequent out-of-order
R-transfers.

Upon rlast, rack is generated towards DUT.

The descriptor is stored to R-ORDER_fifo to let software know the order of
incoming rlasts. The ISR (Interrupt Status Register) is updated on non-empty
condition of this R-ORDER_fifo.



### ACE WR transaction
```

                  +-------------------------------------------------------------+
                  |                                                             |
                  |   USR Master Write Path                                     |
                  |                                                             |
                  |                                                             |
                  |     +------------+     +-------------+     +------------+   |
                  |     |            |     |             |     |            |   |
                  |     |            |     |             |     |            |   |    M_ACE_USR
   Register       |     | ORDER_fifo |     |  IDX_fifo   |     |  USR_fifo  |   |
       +------------+--->            +----->             +----->            +---------------->
                  | |   |            |     |             |     |            |   |  (AW_channel)
                  | |   |            |     |             |     |            |   |
                  | |   |            |     |             |     |            |   |
                  | |   +------------+     +-------------+     +------------+   |
                  | |                                                           |
                  | |                                                           |
                  | |                                                           |
                  | |                                                           |
                  | |    +-----------+    +-------------+      +------------+   |
                  | |    |           |    |             |      |            |   |     M_ACE_USR
                  | +----> ORDER_fifo|    |  IDX_fifo   |      | USR_fifo   |   |
                  |      |           +---->             +------>            +------------------>
                  |      |           |    |             |      |            |   |    (W_channel)
                  |      |           |    |             |      |            |   |
                  |      |           |    |             |  +--->            |   |
                  |      +-----------+    +-------------+  |   +------------+   |
                  |                                        |                    |
 Read from        |                                        |                    |
        +--------------------------------------------------+                    |
WR DATA RAM &     |                       +---------------+                     |
WSTRB RAM         |      +------------+   | desc_allocator|    +------------+   |
                  |      |            |   |               <----+            |   |    M_ACE_USR
   Register       |      | ORDER_fifo |   |               |    | USR_fifo   |   |
        <----------------+            |   +------+--------+    |            <------------------+
                  |      |            |          |             |            |   |    (B_channel)
                  |      |            <----------v---------+---+            |   |
                  |      |            |                    |   |            |   |
                  |      +------------+                    |   +------------+   |
                  |                                        |                    |   M_ACE_USR
                  |                                        |                    |
                  |                                        +----------------------------------->
                  |                                                             |
                  +-------------------------------------------------------------+    (WACK)

```

When SW writes to WR_REQ_FIFO_PUSH_DESC_REG, the write-request descriptor is
stored into AW-ORDER_fifo, W-ORDER_fifo.

For mode-1, "uc2hm_trig" control signal to Host master control is
generated. Upon receiving "hm2uc_done" from Host master control, W-request
for corresponding descriptor should be generated.

On non-empty condition of AW-ORDER_fifo, descriptor is popped out and stored
into AW-IDX_fifo.

On non-empty condition of W-ORDER_fifo (and "hm2uc_done" in mode-1 case),
descriptor is popped out and stored into W-IDX_fifo.

Descriptor number is popped from AW-IDX_fifo. All AW-channel signals are stored
into AW-USR_fifo. The signals are popped from AW-USR_fifo and AW-request is
generated towards DUT. 

Later, descriptor number is popped from W-IDX_fifo and corresponding wdata is
read out from WDATA RAM. All W-channel signals are stored into W-USR_fifo. The
signals are popped from W-USR_fifo and W-request is generated towards DUT. 

Upon generating AW and corrosponding wlast the WR_REQ_INTR_COMP_STATUS_REG bit
is asserted and update WR_REQ_COMP in ISR.  

All B-signals are stored in B-USR_fifo.

Upon getting available descriptors via WR_RESP_FREE_DESC_REG for one or more
descriptors from SW, it waits for non-empty condition of B-USR_fifo. Once there
is one or more entries in B-USR_fifo, the desc_allocator block will calculate
descriptor. 

wack is generated towards DUT.

The descriptor is stored to B-ORDER_fifo to let software know the order of
incoming B-responses. The ISR (Interrupt Status Register) is updated on
non-empty condition of this B-ORDER_fifo.


### ACE SN transaction
```

                 +-----------------------------------------------------------+
                 |                                                           |
                 | USR Master Snoop Path                                     |
                 |                    +---------------+                      |
                 |                    |desc_allocator <-----------+          |
                 |                    |               |           |          |
                 |   +------------+   +-------+-------+     +-----+------+   |
                 |   |            |           |             |            |   |   M_ACE_USR
Register         |   | ORDER_fifo |           |             |  USR_fifo  |   |
 <-------------------+            <-----------v-------------+            <---------------+
                 |   |            |                         |            |   |  (AC_channel)
                 |   |            |                         |            |   |
                 |   +------------+                         +------------+   |
                 |                                                           |
                 |                                                           |
                 |                                                           |
                 |                                                           |
                 |                                                           |
                 |    +-----------+      +-----------+      +------------+   |
                 |    |           |      |           |      |            |   |   M_ACE_USR
Register         |    | ORDER_fifo|      | IDX_fifo  |      | USR_fifo   |   |
+--------------------->           +------>           +----->+            +------------------->
                 |    |           |      |           |      |            |   |   (CR_channel)
                 |    |           |      |           |      |            |   |
                 |    +-----------+      +-----------+      +------------+   |
                 |                                                           |
                 |                                                           |
                 |                                                           |
                 |                                                           |
                 |                                                           |
                 |    +------------+     +-----------+      +------------+   |
                 |    |            |     |           |      |            |   |   M_ACE_USR
Register         |    | ORDER_fifo |     | IDX_fifo  |      | USR_fifo   |   |
 +-------------------->            +----->           +------>            +------------------>
                 |    |            |     |           |      |            |   |   (CD_channel)
                 |    |            |     |           |      |            |   |
                 |    +------------+     +-----------+  +--->            |   |
                 |                                      |   +------------+   |
                 |                                      |                    |
                 |                                      |                    |
   +----------------------------------------------------+                    |
Read from        |                                                           |
CD DATA RAM      +-----------------------------------------------------------+

```

All AC-signals are stored in request-USR_fifo.

Upon getting available descriptors via SN_REQ_FREE_DESC_REG for one or more
descriptors from SW, it waits for non-empty condition of request-USR_fifo. Once
there is one or more entries in request-USR_fifo, the desc_allocator block will
calculate descriptor. This descriptor is stored to request-ORDER_fifo to let
software know the order of incoming AC-requests. The ISR (Interrupt Status
Register) is updated on non-empty condition of this ORDER_fifo.

When SW writes to SN_RESP_FIFO_PUSH_DESC_REG, the snoop-response descriptor is
stored into response-ORDER_fifo. 

On non-empty condition of response-ORDER_fifo, descriptor is popped out and
stored into response-IDX_fifo.

Later, descriptor number is popped from response-IDX_fifo. All CR-channel
signals are stored into response-USR_fifo. The signals are popped from
response-USR_fifo and snoop response is generated towards DUT. 

Upon generating response, corresponding SN_RESP_INTR_COMP_STATUS_REG bit is
asserted and update CD_RESP_COMP in ISR.

When SW writes to SN_DATA_FIFO_PUSH_DESC_REG, the snoop-data descriptor is
stored into data-ORDER_fifo. 

On non-empty condition of data-ORDER_fifo, descriptor is popped out and stored
into data-IDX_fifo.

Later, descriptor number is popped from data-IDX_fifo and corresponding cddata
is read out from CDDATA RAM. All CD-channel signals are stored into
data-USR_fifo. The signals are popped from data-USR_fifo and snoop data is
generated towards DUT. 

Upon generating cdlast, corresponding SN_DATA_INTR_COMP_STATUS_REG bit is
asserted and update CD_DATA_COMP in ISR.

### AXIID Store
```

                +------------------------------------------------------------------------------------+
                |                                                                                    |
                | +-----------------------+                                                          |
                | | +------------------------+                                                       |
                | | | +------------------------+                                                     |
                | | | | +--------------------------+                                                 |
                | | | | |                          |                                                 |
                | +-+ | |                          |                                                 |
                |   | | |                          |                                                 |
                |   +-+ |  FIFO_ID_Reg[Max_Desc]   <------+                                          |
                |     | |                          |      |                                          |
    Axi_Aclk    |     +-+                          |      |                                          |
+--------------->       +--------------+-----------+      |                                          |
                |                      |                  |                                          |
  Axi_aresetn   |          +-----------+           +------+------+                                   |
+--------------->          |                       |             |                                   | Desc_allocation_in_progress
                |          |                       |             |         +----------------+        +----------------------------->
      axnext    | +--------v-----+         +------->             |         | +----------------+      |
+---------------> |              |         |       |             +----+    | | +-----------------+   |
                | |              |         |       |    New ID   |    |    | | | +-----------------+ | Axid_response_id[MAX_DESC]
 M_Axi_usr_Axid | |              +---------+       |  Allocation |    |    | | | |                 | +----------------------------->
+---------------> |              |                 |             |    +----> | | |                 | |
                | |              |                 +-------------+         | | | |                 | |
   Axid_read_en | |    AXID      |                                         | | | |    AXID Fifo    | | Fifo_id_reg_Valid
+---------------> |  Comparision +---------+       +-------------+    +----> | | |    [MAX_DESC]   | +----------------------------->
                | |              |         |       |             |    |    +-+ | |                 | |
   Desc_req_id  | |              |         |       |             |    |      +-+ |                 | |
+---------------> |              |         |       |             |    |        +-+                 | | Fifo_id_reg[MAX_DESC]
                | +--------------+         +-------> Existing ID +----+          +-----------------+ +----------------------------->
                |                                  |    Storage  |                                   |
                |                                  |             |                                   |
                |                                  |             |                                   |
                |                                  +-------------+                                   |
                +------------------------------------------------------------------------------------+

```

The purpose of AXID_Store module is to store AXI IDs which are active/pending
on AXI BUS, ( i.e AXI ID request went on bus and waiting for response ). The
number of FIFOs is equal to the parameter MAX_DESC, to enable MAX_DESC
outstanding requests with unique AWID/ARID on bus. Each Fifo has an associated
register "fifo_id_reg". It stores AXI ID associated to corresponding fifo, so
DESC_ID of all request with similar AXI IDs are stored in single Fifo.
AXID_Store block takes input from AXI BUS, It monitors AXVALID & AXREADY
assertion on AXI BUS. When AXVALID & AXREADY is asserted, the pulse triggers
axi id compare logic. If AXI ID is new, a new fifo_id_reg will be populated
with new AXI ID and the corresponding DESC_ID will be stored into the Fifo. If
AXI ID already existed ( i.e there was already a request with same ID on bus
and response hasn't arrived yet ), compare logic will find fifo_id_reg which
matches with AXI ID. Then, it pushes the DESC_ID into corresponding Fifo. Same
logic is used for AXI Write and AXI Read Requests.

### Host Master Control
```

                   +-------------------------------------------------+
                   |                                                 |
                   | +--------------------------------------------+  |
                   | |                                            |  |
                   | | Ownership Control & Data Packing/Unpacking |  |
       RDATA       | |                                            |  |
+------------------> |                                            |  |
                   | +--------------------------------------------+  |AXI4-128 Bit data width
       WDATA       |                                                 <------------------------>
<------------------+                                                 |
                   | +--------------------------------------------+  |
       WSTRB       | |                                            |  |
<------------------+ |                                            |  |
                   | |                                            |  |
Registers Interface| |              AXI_Master_Control            |  |
<------------------> |                                            |  |
                   | |                                            |  |
                   | |                                            |  |
                   | +--------------------------------------------+  |
                   |                                                 |
                   +-------------------------------------------------+
			   
```

HOST Master Control Block is used only in Mode-1 operation of the
bridge. The bridge uses M_AXI interface to drive read/write requests towards x86
host via the PCIe controller and AXI-MM logic. 

AXI WR transactions: 

In Mode-1, SW driver fills WDATA and WSTRB in its memory and programs
the addresses pointing to the host buffer. Once User Master gets Ownership, it
will trigger Host Master Control to fetch WDATA and WSTRB from Host Buffers and
place it in WR DataRAM and WR StrbRAMs respectively. After the data transfer is
done it will continue its operation as Mode-0. 

In case user sets WSTRB bit in register to be "1", Host Master Control
will issue two reads, one for WDATA and second for WSTRB. After fetching
WDATA/WSTRB, Host Master Control will place it in the WDATA RAM and WSTRB RAM.
From then on, User Master Control will initiate its normal Mode-0 Operation of
waiting for response of Write request & completing ownership.

AXI RD transactions:

In Mode-1, SW driver allocates a buffer in its memory to store RDATA and
programs the address pointing to the host buffer. Once User Master gets
Ownership, it will issue a read request, and upon getting response, the Host
Master Control block issues a write request to write RDATA from RD DataRAM into
Host buffers and once transfer is done it will continue its operation as Mode-0.

NOTE: Host address should always be 4KB aligned


## Interrupt Handler 


For propagating interrupts from x86 Host to DUT in the FPGA and vice-versa, the
Master Bridge has provision for generating interrupts.  Interrupts from Host to
the FPGA DUT are called Host to Card (H2C) interrupts and from FPGA DUT to x86
Host are called Card to Host (C2H) interrupts.

The H2C interrupts generated by Host can be connected to DUT by using
h2c_irq_out ports. 

The DUT generated interrupts should be connected to c2h_irq_in ports. These
interrupts can be translated to Legacy/MSI or MSI-X interrupts over PCIe
controller to Host.

The Bridge also generates interrupts to Host for indicating transaction
completions. The interrupt handler block streamlines the C2H interrupts and its
own completion interrupts and forwards to PCIe controller solution. The bridge
uses "irq_out" to generate interrupts and waits for an acknowledgement
"irq_ack" before sending the next interrupt. The "irq_ack" is sent by the PCIe
controller after the "irq_out" translates to a PCIE Legacy interrupt Message
TLP on the PCIe link. 

The interrupt clear and mask registers control enablement and disablement of
the interrupts as per software's discretion.


# Error Handling/Reporting


Bridge generates Errors in case of following protocol violations. 

- Incorrect RID
	- If DUT Provides incorrect RID in the response.

- RLAST Assertion
        - If DUT Asserts incorrect RLAST. ( i.e RLAST is earlier/later than
          actual last cycle)









