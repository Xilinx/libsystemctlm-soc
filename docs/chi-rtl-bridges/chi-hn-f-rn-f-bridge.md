
# CHI Bridge Architecture
## Introduction
This document covers the microarchitecture details of the CHI Bridge. The bridge can be configured to work as RN_F or HN_F bridge based on the parameter BRIDGE_MODE. The inner sub-blocks design remain the same.The CHI version takes VERSION B as default standard and it also supports VERSION C features. The bridge architecture is primarily designed to support the link layer features of CHI protocol, while the higher layer protocols such as the Network layer and Coherence protocol are soft coded in TLM Models, which means the Hardware Cache Coherency management is done in through TLM Models. The link layer essentially transmits and receives transactions through well formed packets called FLITs. These FLITs are programmed and sent and received from software over AXI channel into the bridge.

### Features Supported:
- CHI version : version B and version C
- Link layer features: data width(cache line size) :512
- Node ID width: 7 
- Address width :48
- Number of link layer credits :15
- AXI interface features: AXI4Lite, Data Width :32, Address :32
- DCT
- DMT
- Atomic transaction, Exclusive transactions
- DVM
- Request retries

### Features not supported
- RSVDC Field
- Low Power Mode
- Data packetization, Cache stashing, Data source & Trace tag
- Poison and Data check is not supported

# Block diagram of CHI bridge
```

     +------------------------------------------------------------------------------------+
     |                    +----------------------------------+    +---------------------+ |
     |  +-----------+     |          REGISTERS               +--->+LINK  +------------+ |CHI_TXREQ/CHI_TXSNP
    clk |           +---->+----------------------------------+    |LAYER |TXREQ/SNP CM| +-+---->
   +-+-->AXI SLAVE  |                                             |I/f   +------------+ | |
     |  |&          |     +----------------------------------+    |      +------------+ |CHI_TXRSP
reset|  |ADDRESS    |     |  TXREQ/     TXRSP     TXDAT      |    |      | TXRSP CM   | +-+---->
 +----->+DECODER    +---->+  TXSNP MEM  MEMORY    MEMORY     +--->+      +------------+ | |
     |  |           |     |  +-------+ +--------+ +--------+ |    |      +------------+ |CHI_TXDAT
S_AXI|  |           ^     |  |       | |        | |        | |    |      |TXDAT CM    | +------>
+------->           +-----+  +-------+ +--------+ +--------+ |    |      +------------+ |CHI_TXLINKACTIVEREQ
     |  +-----------+     |                                  |    |      +------------+ +------------>
     |                    |                       RXSNP/     |    |      |Link Layer  | |CHI_TXLINKACTIVEACK
     |  +-----------+     |  RXRSP     RXDAT      RXREQ      +<---+      |state       | +<------------+
     |  |           |     |  MEMORY    MEMORY     MEMORY     |    |      |machine     | |CHI_SYSCOREQ
 irq_ack INTERRUPT  |     |  +-------+ +--------+ +--------+ |    |      |            | +------------>
  +---->|           ^     |  |       | |        | |        | |    |      |            | |CHI_SYSCOACK
irq_out |HANDLER    +-----+  +-------+ +--------+ +--------+ |    |      |            | +<-----------+
  <--+--+           |     |                                  |    |      |            | |CHI_TXSACTIVE
     |  |           |     |           MEMORY                 |    |      |            | +------------>
     |  +-----------+     +----------------------------------+    |      |            | |CHI_RXSACTIVE
     |                                                            |      |            | +<------------+
     |                                                            |      |            | |CHI_RXLINKACTIVEACK
     |                                                            |      +------------+ +---------------->
     |                                                            |                     |CHI_RXLINKACTIVEREQ
     |                                                            |      +------------+ +<----------------+
     |                                                            |      |RXRSP CM    | |CHI_RXRSP
     |                                                            |      +------------+ +<--------+
     |                                                            |      +------------+ |CHI_RXDAT
     |                                                            |      |RXDAT CM    | +<--------+
     |                                                            |      +------------+ |CHI_RXSNP/CHI_RXREQ
     |                                                            |      +------------+ <-+-----------+
     |                                                            |      |RXSNP/REQ CM| | |
     |                                                            |      +------------+ | |
     |                                                            |                     | |
     |                                                            +---------------------+ |
     |                                                                                    |
     +------------------------------------------------------------------------------------+
```

# Hardware Block Description:

The CHI Bridge for both HN_F and RN_F mode consists of the following sub-blocks:
   -  Link layer state machine,
   -  Credit managers for different channels for transmit and receive channels.
   -  Memory for storing transmit and receive Flits for all the channels.
   -  Register block for programming the CHI bridge.

Based on BRIDGE_MODE, when bridge is in HN_F Mode, CHI_TXREQ/CHI_TXSNP as shown in block diagram, transmits Snoop requests and the receive channel CHI_RXSNP/CHI_RXREQ receives CHI requests on CHI_RXREQ channel. When CHI Bridge is configured as RN_F Bridge, then CHI_TXREQ/CHI_TXSNP function as transmitting CHI requests whereas the receive channel CHI_RXSNP/CHI_RXREQ receives Snoop requests from RN_F DUT. The memory names and sizes are assigned accordingly.
They are TXREQ, TXRSP, TXDAT for transmit and RXRSP, RXSNP, RXDAT for receive respectively.
Data sent on channels is controlled by a link layer state machine working in tandem for transmit and receive side with the Home Node(DUT) side. Block diagram shows I/O signals mainly participating in CHI transactions.

### Clocks
The Bridge IP requires a single clock "clk". This clock typically is connected with XDMA IP's clk for Xilinx use case.
     
|clock name  | associated interface |
|--|--|
| clk | S_AXI |
| clk  | CHI |


#### Resets
------------------------------------------------------------------------
|Name  | Associate Interface | Description                             |
| -----|-------------------  |-----------------------------------------|
|resetn|S_AXI|Design uses only one ACTIVE LOW reset.The reset is       | 
|	   |     | synchronised with clk.                                |    
|resetn|CHI  |Design uses only one ACTIVE LOW reset.The reset is       | 
|	   |     | synchronised with clk.                                  |
|usr_resetn[usr_rst_num-1:0] | |ACTIVE LOW user soft reset. This reset is generated by ANDing resetn and RESET_REG 																						
### Port Map
Bridge top level and block level port map can be found below:

|Name       | Width  		| I/O Interface | Description 		 			 |
| -----------|---------------|----------------|------------------------------|
|clk             |1                   |Input		  	 | Clock					     |
|resetn     | 1             |Input           |Reset Active Low               | 
|user_resetn|[usr_rstn-1:0] |Output		     | User Reset Active Low.        |
| irq_out	| 1				| Output		 | Interrupt to XDMA.            |
| irq_ack   | 1             | Input 	     |Interrupt Acknowledgement from 														XDMA.                    |
|h2c_intr_out| [127:0]      | Output	     | Host to Card Interrupt.       |
|h2c_gpio_out|[255:0]       | Output         | Gpio Output                   |
|c2h_intr_in |[63:0]        | Input          | Card to Host Interrupt        |
|c2h_gpio_in|[255:0]        | Input          | Card to Host Control Signals  |
| s_axi_*   |          | --             |AXI4-Lite Slave Interface           |
|chi_*/    |           | --             | CHI Interface       |

  			    

### RTL Hierarchy
-   chi_bridge_rn_top.v/chi_bridge_hn_top.v
   -   u_chi_bridge (chi_bridge.v)
       -   u_chi_channel_if (chi_channel_if.v)
           -   u_CHI_TXSNP_TXREQ_Credit (chi_link_credit_manager.v)
           -   u_CHI_TXRSP_Credit (chi_link_credit_manager.v)
           -   u_CHI_TXDAT_Credit (chi_link_credit_manager.v)
           -   u_CHI_RXREQ_RXSNP_Credit (chi_link_credit_manager.v)
           -   u_CHI_RXRSP_Credit (chi_link_credit_manager.v)
           -   u_CHI_RXDAT_Credit (chi_link_credit_manager.v)
       -   u_regs (chi_register_interface.v)
           -   u_chi_txflit_txsnp_txreq_mgmt (chi_txflit_mgmt.v)
           -   u_chi_txflit_txdat_mgmt (chi_txflit_mgmt.v)
           -   u_chi_txflit_txrsp_mgmt (chi_txflit_mgmt.v)
           -   u_chi_txflit_txsnp_txreq_ram(chi_txflit_ram.v)
           -   u_chi_txflit_txdat_ram (chi_txflit_ram.v)
           -   u_chi_txflit_txrsp_ram (chi_txflit_ram.v)
           -   u_chi_txflit_rxreq_rxsnp_ram (chi_rxflit_ram.v)
           -   u_chi_txflit_rxdat_ram(chi_rxflit_ram.v)
           -   u_chi_txflit_rxrsp_ram (chi_rxflit_ram.v)
       -   u_chi_intr_handler(chi_intr_handler)
       
### Hardware Block Description
####  Register Block
 ````
       
                                                             +------------------------+
                                                             |                        |
                                                +----------->+      REGISTERS         |
                                                |            |                        |
                                                |            +------------------------+
           +------------------+      +----------+-----+      +-------------------------+TXREQ/TXSNP FLITVALID
           |                  |      |                |      |         +------------+  |& FLIT
           |                  |      |                |      |         |TXREQ/TXSNP +---------->
           |                  |      |                +----->+         +------------+  |
           |                  |      |                |      |                         |TXRSP FLIT VALID
           |                  |      |                |      |         +------------+  |& FLIT
           |                  |      |                |      |         |TXRSP MEM   +---------->
           |                  |      |                +----->+         +------------+  |
           |                  |      |                |      |                         |TXDAT FLIT VALID
           |                  |      |                |      |         +------------+  |& FLIT
           |                  |      |                +----->+         |TXDAT MEM   +---------->
           |                  |      |                |      |         +------------+  |
           |                  |      |                |      |                         |
           |                  |      |                |      |                         |
S_AXI4-Lite|                  |      |  ADDRESS       |      |                         |
  -------->+  AXI SLAVE FSM   |      |  DECODER       |      |                         |
           |                  |      |                |      |                         |RXREQ/RXSNP FLIT VALID
           |                  |      |                |      |          +------------+ |& FLIT
           |                  |      |                +<-----+          |RXSNP/RXREQ +<---------+
           |                  |      |                |      |          +------------+ |
           |                  |      |                |      |                         |
           |                  |      |                |      |                         |RXRSP FLIT VALID &
           |                  |      |                |      |          +------------+ |FLIT
           |                  |      |                |      |          |RXRSP MEM   <---------+
           |                  |      |                +<-----+          +------------+ |
           |                  |      |                |      |                         |RXDAT FLIT VALID
           |                  |      |                |      |          +------------+ |& FLIT
           |                  |      |                +<-----+          |RXDAT MEM   +<---------+
           |                  |      |                |      |          +------------+ |
           |                  |      |                |      |                         |
           +------------------+      +----------------+      +-------------------------+

 ````       
The Register block implements the register space as per CHI bridge requirements. The Register block is accessible via AXI4-Lite interface. The bridge register space is mapped to one of the PCIE BASE Address Registers (BARs). The overall memory requirement for bridge is 128KB and depends mainly on size of the channel memories. Below is the mention of memory size requirement per channel.
The register offsets are defined for each of the registers. The register map sheet elaborates on address spaces of each of these.
The Register block consists of programmable Registers, status Registers and memories for transmitting and receiving Flits to/from link layer interface. register and memory access from system side is done through AXI4-Lite interface, where axi transactions has a AXI4 Slave FSM from which address and data are passed onto the Address Decoder.
Both Address Decoder and AXI4 Slave FSM are not separate sub-blocks but built in within the Register Interface block.

#### Address Decoder
The address decoder block converts the AXI4 transactions into register reads and writes. The AXI-4Lite transactions are targeted to one of the following regions of the register space.
- General Registers: These Registers which are not part of the Data Path of CHI Bridge, but are used in Bridge Identification, External interrupts, GPIO interface.
- Protocol Specific Registers: Protocol Specific registers: contain many configuration and status registers which pertain to datapath of CHI Bridge
- Memories: CHI Bridge uses memories for Flit storage where Flits are sent from system side to the CHI link layer, and are read over on AXI4-Lite interface as Flits are received from CHI link layer interface. This happens only when CHI link is UP. Register Block works in close relation to Link Layer Interface block as described later. Register Interface also interfaces with Interrupt Handler block for Interrupt generation.

#### DAT Channel Memory Calculation
DAT Flit Width supported = 705.
For the given DAT Width there are 23 32-bit parallel memories that are 15 deep.
Since there are 2 Data channels, TXDAT and RXDAT, max memory requirement for each DAT channel= 243215=12Kb

#### REQ Response Memory Calculation:
REQ Flit Width = 121 there are 4 32 bit-parallel memories that are 15 deep.
TXREQ max memory requirement for REQ channels = 43215 ~2 Kb

#### RSP Response Memory Calculation
RSP Flit Width supported = 51, so there are 2 32-bits of memory and 15 deep
Since there are 2 channels, TXRSP and RXRSP, max memory requirement for each RSP channels = 23215= 960b ~1KB

#### SNP Response Memory Calculation:
SNP Flit Width supported = 88, There are 3 32 bit-parallel memories that are 15 deep.
There is only one Snoop channel, so max. memory requirement = 33215=1.44Kb ~2KB

#### Link Layer Interface
A Central Link Layer state machine keeps running in tune with DUT transmit and receive CHI signals. The Link Layer interface is tightly coupled with Register interface.
The Link Layer interface implements the link layer of the CHI Layer where it has a central state machine that controls the channels. The state machine keeps the link state based on grant/request mechanism based on the readiness of the upper layers, once the Link comes up, Flits are exchanged based on credit exchange for Flit transfers and reception. The Credit Levels for both receive and transmit per channel are maintained in Credit Manager Block. Upto 15 credits are transmitted and received for receive and transmit channels respectively. Other auxiliary signals of CHI layer are also controlled from Link Layer Interface. The Link Layer Interface works closely with Register interface into receiving and transmitting Flits from application layer or the software.
The Block Diagram shows the Link Layer interface for RN_F CHI Bridge , but the block remains the same for HN_F Bridge as well, except for Channel names change as already explained before.

```
                                                     +-----------------------+
                                LINK LAYER CONTROL   |LINK LAYER INTERFACE   |
+----------------------------+  SIGNALS              |       +-------------+ |  CHI_TXREQ
|                            +<----------------------+       |TXREQ/TXSNP  | +---------------->
|      REGISTERS             |                       |       +-------------+ |
|                            |  TRANSMIT FLIT &      |       +-------------+ | CHI_TXRSP
+----------------------------+  TRANSMIT FLIT        |       |TXRSP CM     | +---------------->
 +---------------------------+  VALID                |       +-------------+ |
 |  +--------------------+   +---------------------->+       +-------------+ | CHI_TXDAT
 |  |  TXREQ/TXSNP       |   |                       |       |TXDAT CM     | +---------------->
 |  |  MEMORY            |   |                       |       +-------------+ |
 |  +--------------------+   |                       |                       |CHI_TXLINKACTIVEREQ
 |  |  TXRSP MEMORY      |   |                       |       +-------------+ +---------------->
 |  |                    |   |                       |       |             | |CHI_TXLINKACTIVEACK
 |  +--------------------+   |                       |       |             | +<-----------------+
 |  |                    |   |                       |       |  LINK       | |CHI_SYSCOREQ
 |  |   TXDAT MEMORY     |   |                       |       |  LAYER      | +------------------->
 |  +--------------------+   |                       |       |  STATE      | |CHI_SYSCOACK
 |                           |                       |       | MACHINE     | +<-------------------+
 |                           |                       |       |             | |CHI_TXSACTIVE
 |                           |                       |       |             | +------------------->
 |                           |                       |       |             | |CHI_RXSACTIVE
 |                           |                       |       |             | +<-------------------+
 |                           |                       |       |             | |CHI_RXLINKACTIVEREQ
 |   +------------------+    |                       |       |             | +<--------------------+
 |   | RXREQ/RXSNP      |    |                       |       |             | |CHI_RXLINKACTIVEACK
 |   | MEMORY           |    |                       |       +-------------+ +--------------------->
 |   +------------------+    |                       |                       |
 |   | RXRSP MEMORY     |    |                       |        +------------+ |CHI_RXSNP/CHI_RXREQ
 |   |                  |    |RECEIVE FLIT &         |        |RXSNP/RXREQ | +<-------------------+
 |   +------------------+    |RECEIVE FLIT           |        +------------+ |
 |   |RXDAT MEMORY      |    |VALID                  |        +------------+ |CHI_RXRSP
 |   |                  |    +<----------------------+        |RXRSP CM    | +<-------------------+
 |   +------------------+    |                       |        +------------+ |
 +---------------------------+                       |        +------------+ |CHI_RXDAT
                                                     |        |RXDAT CM    | +<-------------------+
                                                     |        +------------+ |
                                                     +-----------------------+
```

#### Link Credit Manager
The Link Credit Manager maintains the number of credits required to transmit/receive flits on CHI channel. At a time maximum 15 credits can be sent or received, the credits are implied by virtue of pulse width of LCRDV Interface of CHI. On transmit side, when the link comes up, a default of 15 credits are sent on receive channel over LCRDV to the DUT . So the internal credit counter in receive side credit manager is 0.As Flits are received, credits are incremented in receive side for the given channel and they are decremented when software programs the ownership_flip register explained later in data flow description.
On transmit side credits are received on transmit channel from DUT over LCRDV interface, so internal credit counter for respective channel is incremented.When OWNERSHIP_FLIP Register is programmed for a given channel, Flits are transmitted with which credits are decremented into corresponding channel credit Manager. It is incremented again when credits are received from the DUT.

#### Interrupt Handler
For propagating interrupts from x86 Host to DUT in the FPGA and vice-versa, the CHI Bridge has provision for generating interrupts. Interrupts from Host to the FPGA DUT are called Host to Card (H2C) interrupts and from FPGA DUT to x86 Host are called Card to Host (C2H) interrupts.   
The H2C interrupts generated by Host can be connected to DUT by using h2c_intr_out ports. The software driver needs to program C2H_INTR_REG to generate C2H interrupts. The DUT generated interrupts should be connected to c2h_intr_in ports. These interrupts can be translated to Legacy/MSI or MSI-X interrupts over PCIe controller to Host.
The Bridge also generates interrupts to Host for indicating CHI Bridge Transmit and Receive Transaction occurrences by virtue of INTR_STATUS_REG with field 0 which indicates occurrence of transaction of event on any of the Transmit or Receive Channel. The interrupt handler block streamlines the C2H interrupts and its own transaction event interrupts and forwards to PCIe controller solution. The bridge uses “irq_out” to generate interrupts and waits for an acknowledgement “irq_ack” before sending the next interrupt. The “irq_ack” is sent by the PCIe controller after the “irq_out” translates to a PCIE Legacy interrupt Message TLP on the PCIe link.
The interrupt clear and mask registers control enablement and disablement of the interrupts as per software’s discretion.Interrupt Handler is not used in Polling Mode.

#### Link Initialization:
The General Data Flow Description describes how Flit flows across the Bridge in detail. The FLIT width configuration is read initially to help program the FLITs for transmission.The BRIDGE_CONFIGURE_REG is set to ‘1’ to initiate the CHI Link Bring up process. Upon seeing the BRIDGE_CONFIGURE_REG bit set, the link layer state machine activates and eventually goes to RUN state for both transmit and receive side and collects credits on transmit channels and sends credits equal to number of RX_ALLOW_CREDITS(typ.15) from receive channel to/from the neighbouring DUT for all the channels participating.The status of the link and the individual channel can be checked from CHI_BRDIGE_CHN_TX_STS_REG and CHI_BRIDGE_CHN_RX_STS_REG.

Following illustration of Read,Write and Snoop Requests describe the flow of Flits to/from the CHI Bridge.

#### Read Requests for RN_F Bridge :
After the link up, software can send CHI READ TXREQ Requests over AXI4-Lite Bus which shall eventually be sent based on the number of credits available which can be checked through the CHI_BRIDGE_TXREQ_CUR_CREDITS_REG. The AXI4-lite beats are stored sequentially in TXREQ memory in Registers block. Each Buffer is addressable through AXI4-Lite Bus with an offset address meant for a particular channel. Software must set the TXREQ_OWNERSHIP_FLIP bits in the TXREQ_OWNERSHIP_FLIP_REG for the number of Flits to be sent. The Flits are formed from TXREQ Memory and are sent over TXREQ channel. Upon sending a Flit, the status bit in INTR_FLIT_TXN_STATUS_REG corresponding to TXREQ channel is set and an interrupt is raised in INTR_FLIT_TXN_ENABLE_REG is set. Based on the number of credits available, software can choose to send more requests.
The DUT upon seeing the Read Requests responds with Read Data on RXDAT channel.
The RXDAT Data is stored in 32 bit parallel buffers in RXDAT Memory. side-by-side the bit in INTR_FLIT_TXN_STATUS_REG register corresponding to RXDAT Flit received is set , the RXDAT_OWNERSHIP bit is set to ‘1’ for the count of the Flit(s) received thereafter too, and an interrupt is raised by virtue of INTR_FLIT_TXN_STATUS_REG register if INTR_FLIT_TXN_ENABLE_REG is set. At this point, the credit that is consumed for Request Flit is not sent back to DUT until the software has read the Request Flit and RXDAT_OWNERSHIP_FLIP bit set by software. The FLIP bit resets the RXDAT_OWNERSHIP register for as many bits set in the FLIP register.
Software upon seeing the interrupt and clearing the interrupt bit by virtue of INTR_FLIT_TXN_CLEAR_REG, reads the Data Flit over AXI4-Lite channel. It then reads the CHI_BRIDGE_CHN_TX_STS_REG to see if transmit link status is in RUN state and TXRSP_CHANNEL_RDY bit is set, and sends the Response to be sent on TXRSP channel by loading the TXRSP Memory. It shall set the TXRSP_OWNERSHIP_FLIP bit in TXRSP_OWNERSHIP_FLIP_REG. The TXRSP Flit from Memory is sent over TXRSP channel and an interrupt is set for the field corresponding to TXRSP channel in INTR_FLIT_TXN_STATUS_REG and interrupt is raised if TXN_ENABLE is set.

#### Write Requests for RN_F Bridge:
After the link up, software can send CHI READ TXREQ Requests over AXI4-Lite Bus which shall eventually be sent based on the number of credits available which can eb checked through the CHI_BRIDGE_TXREQ_CUR_CREDITS_REG. The AXI4-lite beats are stored sequentially in TXREQ memory in Registers block. Each buffer is addressable through AXI4-Lite bus with an offset address meant for a particular channel. Software must set the TXREQ_OWNERSHIP_FLIP bits in the TXREQ_OWNERSHIP_FLIP_REG for the number of Flits to be sent. The Flits are formed from TXREQ Memory and are sent over TXREQ channel. Upon sending a Flit, the status bit in INTR_FLIT_TXN_STATUS_REG corresponding to TXREQ channel is set and an interrupt is raised in INTR_FLIT_TXN_ENABLE_REG is set. Based on the number of credits available, software can choose to send more Requests.

The DUT upon seeing the Write Requests responds with Response on RXRSP channel. The Flits are received on RXRSP Memory, side-by-side the bit in INTR_FLIT_TXN_STATUS_REG register corresponding to RXRSP Flit received is set , the RXRSP_OWNERSHIP_REG bit is set to ‘1’ for the number of Response Flit received and an interrupt is raised if the INTR_FLIT_TXN_ENABLE bit is set for the RSP channel. At this point, the credit that is consumed for Response Flit is not sent back to DUT until the software has read the Request Flit and RXRSP_OWNERSHIP_FLIP bit set by software. The FLIP bit resets the RXRSP_OWNERSHIP bit for as many bits set in the FLIP register.
Upon receiving the responses, any Write Data is sent over the TXDAT CHI channel through AXI4-Lite bus and stored into the TXDAT memory after which software shall raise an interrupt if interrupt enable is set for the TXDAT channel field.

#### Snoop Requests for RN_F Bridge:
Snoop Requests can be received on RXSNP channel even when Read/Writes are happening, however, the link initialization has to happen.
When a Snoop Request appears on RXSNP channel, it is stored in RXSNP memory , side-by-side the bit in INTR_FLIT_TXN_STATUS_REG register corresponding to RXSNP Flit received is set , the RXSNP_OWNERSHIP bit is set to ‘1’ , INTR_FLIT_TXN_STATUS_REG for field corresponding to RXSNP channel is also set. An interrupt is raised in INTR_FLIT_TXN_ENABLE bit for RXSNP channel is set. At this point, the credit that is consumed for Snoop Request Flit is not sent back to DUT until the software has read the Request Flit and RXSNP_OWNERSHIP_FLIP bit set by software. The FLIP bit resets the RXSNP_OWNERSHIP bit for as many bits set in the FLIP register.
The software upon seeing the Snoop Requests responds with Response on TXDAT channel through AXI4-lite bus and stored into the TXDAT Memory after which software shall set TXDAT_OWNERSHIP_FLIP_REG to ‘1’ .Following snoop response would be sent over the TXRSP channel. An interrupt is raised following the transmission of the Flit over the TXDAT channel if INTR_FLIT_TXN_ENABLE_REG is set.
