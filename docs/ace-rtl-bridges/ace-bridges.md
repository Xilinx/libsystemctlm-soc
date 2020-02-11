**Table of Content**
 
   * [Introduction](#introduction)
   * [System Details](#system-details)
   * [Managing WR/RD DATARAM](#managing-wrrd-dataram)
   * [ACE Bridges use-model](#ace-bridges-use-model)
   * [Software-Hardware Flow](#software-hardware-flow)
      * [ACE Master HW Bridge ( tlm2ace-hw-bridge )](#ace-master-hw-bridge--tlm2ace-hw-bridge-)
         * [Mode_0 : Register Access (RD/WR Transactions)](#mode_0--register-access-rdwr-transactions)
         * [Mode_1 : Indirect DMA  (RD/WR Transactions)](#mode_1--indirect-dma--rdwr-transactions)
         * [Snoop Transactions](#snoop-transactions)
      * [ACE Slave HW Bridge ( ace2tlm-hw-bridge )](#ace-slave-hw-bridge--ace2tlm-hw-bridge-)
         * [Mode_0 : Register Access (RD/WR Transactions)](#mode_0--register-access-rdwr-transactions-1)
         * [Mode_1 : Indirect DMA  (RD/WR Transactions)](#mode_1--indirect-dma--rdwr-transactions-1)
         * [Snoop Transactions](#snoop-transactions-1)
   * [Bridge Discovery Mechanism](#bridge-discovery-mechanism)


# Introduction

This document gives architecture, data flow and system level details of the
ACE Hardware Bridges.

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
- Supports ACE protocol
- ACE FPGA Bridges supports 2 modes of operation
	
	1. Mode_0: Register Access mode ( Preferable for smaller size transactions) In
this mode, software programs the attributes in the BAR mapped Protocol Bridge's address/register space. The protocol bridges then create protocol based pin wiggling onto the DUT. The Write/read/snoop data corresponding to the ACE transactions are written/read by Host software. If the DUT has the ACE Master, then the ACE Slave is in SystemC/TLM framework on x86, and vice versa.  The attributes of the ACE transactions are required for the TLM Traffic generator to generate transactions/response towards ACE Master/Slave on SystemC side.

	2. Mode_1: Indirect DMA Mode (Gives better performance and efficient for larger
size transactions) In this mode, software programs the attributes in the BAR mapped Protocol Bridge's address/register space. The protocol bridges then create protocol based pin wiggling onto the DUT. The Write/read data corresponding to the ACE transactions are written/read by protocol bridge to/from Host memory into its Data RAM.If the DUT has the ACE Master, then the ACE Slave is in SystemC/TLM framework on x86, and vice versa. The attributes of the ACE transactions are required for the TLM Traffic generator to generate transactions/response towards ACE Master/Slave on SystemC side.

**NOTE : Mode-1 mode is only supported for write/read transactions. Snoop
transactions always follow mode-0.**


Please refer ace-master-bridge.txt for ACE Master Bridge Micro-architecture.

Please refer ace-slave-bridge.txt for ACE Slave Bridge Micro-architecture.

# Managing WR/RD DATARAM


The WR/RD DataRam is actually set of BAR mapped registers and the access to
the registers has to be DWORD aligned.

In the below diagram, Consider SW needs to program three descriptors: 

```
	+--------+--------+--------+---------+---------------------+
	|        |        |        |         |                     |
	|   4    |   3    |   2    |  1      |    0xC000           |
	+----------------------------------------------------------+
	|        |        |        |         |                     |
	|   8    |   7    |   6    |   5     |    0xC004           |
	+----------------------------------------------------------+
	|        |        |        |         |                     |
	|   X    |   X    |   10   |   9     |    0xC008           |
	+----------------------------------------------------------+
	|        |        |        |         |                     |
	|   4    |   3    |   2    |   1     |    0xC00C           |
	+----------------------------------------------------------+
	|        |        |        |         |                     |
	|   8    |   7    |   6    |   5     |    0xC010           |
	+----------------------------------------------------------+
	|        |        |        |         |                     |
	|   12   |   11   |   10   |   9     |    0xC014           |
	+----------------------------------------------------------+
	|        |        |        |         |                     |
	|   16   |   15   |   14   |   13    |    0xC018           |
	+-------++--------+-----+--+---------+-------+-------------+
	        |               |                    |
	        |               |                    |
	--------++--------+-----+--+---------+-------+-------------+
	|        |        |        |         |                     |
	|   4    |   3    |   2    |   1     |    0xFFF0           |
	+----------------------------------------------------------+
	|        |        |        |         |                     |
	|   8    |   7    |   6    |   5     |    0xFFF4           |
	+----------------------------------------------------------+
	|        |        |        |         |                     |
	|   12   |   11   |   10   |   9     |    0xFFF8           |
	+----------------------------------------------------------+
	|        |        |        |         |                     |
	|   X    |   X    |   X    |   13    |    0xFFFC           |
	+--------+--------+--------+---------+---------------------+

```
DESC1 : WR transaction of 10 Bytes (Shown in Row 1-2-3 ) 
DESC2:  WR transaction of 16 Bytes (Shown in Row 4-5-6-7 ) 
DESC3:  WR transaction of 13 Bytes (Shown in 8-9-10-11 )

Consider offset address of WR DataRam for DESC 1 is 0xC000 (start address of
WR DataRam). Since size of transaction of this DESC is 10 Bytes in size, it
will occupy space up-till address 0xC008, in which only 2 Bytes are valid.
This is controlled by byte enables in PCIe and eventually as WSTRB on ACE
interface.

Since, WR DataRam is DWORD aligned, the starting address of DESC 2 can only be
at next DWORD aligned address i.e. 0xC00C as shown in the figure. 

Since, each DESC has individual OFFSET_ADDR register, it is not necessary that
WR DataRam has to be filled contiguously. As shown in below figure, DESC 3, of
13 bytes bytes transaction size, can start from address 0xFFF0 and end at
0xFFFC (which is the end address of WR DataRam).

This example is for WR DataRam, However similar rules for RD DataRam will also
apply.


# ACE Bridges use-model


ACE Master and Slave Bridge use-model with ACE Master and Slave Device Under Tests (DUT) and PCIe Sub-system is shown in below diagram.


```

                            ___________________________________________________________________________________________________________
                            |    ___________________________________________|__________                                                 |                         
    ______________          |   |     ___________________________       |   |          |          ___________________________           |         ______________
   |              |         |   |    |                           |      |   |          |         |                           |          |        |              |         
   |              |         |   |    |                           |      |   |----------(---+---->|CLK                        |          |------->|CLK           |
   |              |         |   |    |                           |      |              |   |     |                  M_ACE_USR|------------------>|S_ACE         |
   |       AXI_CLK|---------+---)--->|*_ACLK                     |      +--------------(---(---->|RESETN                     |                   |              |
   |              |         |   |    |                           |                     |   |     |                 USR_RESETN|------------------>|RSTN          |
   |   AXI_ARESETN|---------)---+--->|*_ARESETN                  |                     |   |     |                           |                   |              |
   |              |         |   |    |                           |                     |   |     |                           |                   |              |
   |         M_AXI|---------)---)--->|S00_AXI             M00_AXI|---------------------(---(---->|S_AXI                      |                   |              |
   |              |         |   |    |                           |                     |   |     |                           |                   |              |
   |              |         |   |    |            AXI            |                     |   |     |                           |                   |              |          
   |              |         |   |    |        INTERCONNECT       |                     |   |     |        ACE MASTER         |                   |  ACE SLAVE   | 
   |              |         |   |    |                           |                     |   |     |         BRIDGE            |                   |     DUT      |
   |              |         |   |    |                           |                     |   |     |                           |                   |              |
   |              |         |   |    |                           |                     |   |     |                           |                   |              |
   |              |         |   |    |                    M01_AXI|-----------          |   |     |               H2C_INTR_OUT|------------------>|INTR_IN       |
   |              |         |   |    |                           |          |  +-------(---(-----|M_AXI                      |                   |              |
   |              |         |   |    |                           |          |  |       |   |     |                C2H_INTR_IN|<------------------|INTR_OUT      |
   |              |         |   |    |                           |  |-------|--|-------(---(-----|IRQ_OUT                    |                   |              |
   |   PCIe Core  |         |   |    |                           |  |       |  |       |   |     |                C2H_GPIO_IN+<------------------+GPIO_OUT      |
   |       &      |         |   |    |                           |  |  -----|--|-------(---(---->|IRQ_ACK                    |                   |              |
   |    AXI-MM    |         |   |    |                           |  |  |    |  |       |   |     |               H2C_GPIO_OUT+------------------>+GPIO_IN       |
   |    Bridge    |         |   |    |___________________________|  |  |    |  |       |   |     |___________________________|                   |______________|
   |              |         |___|___________________________________|__|____|  |_______|___|____________________________________________
   |              |         |   |     ___________________________   |  |    |  |       |   |      ___________________________           |         ______________
   |              |         |   |    |                           |  |  |    |  |       |   |     |                           |          |        |              |         
   |              |         |   |    |                           |  |  |    |--)-------(---(---->|                           |          |------->|CLK           |
   |              |         |   |    |                           |  |  |       |       |   |     |S_AXI                      |                   |              |
   |              |         |   |    |                    S00_AXI|<-)--)--------       |   |     |                  S_ACE_USR|<------------------|M_ACE         |
   |              |         +---)--->|*_ACLK                     |  |  |               |   ----->|CLK                        |                   |              |
   |              |             |    |                           |  |  |               |         |                 USR_RESETN|------------------>|RSTN          |
   |              |             ---->|*_ARESETN                  |  |  |               |-------->|RESETN                     |                   |              |
   |              |                  |                           |  |  |                         |                           |                   |              |
   |              |                  |                           |  |  |                         |                           |                   |              |
   |              |                  |                           |  |  |                         |                           |                   |              |          
   |              |                  |           AXI             |  |  |                         |        ACE SLAVE          |                   |  ACE MASTER  | 
   |              |                  |       INTERCONNECT        |  |  |                         |         BRIDGE            |                   |     DUT      |
   |              |                  |                           |  |  |                         |                           |                   |              |
   |              |                  |                           |  |  |                         |                           |                   |              |
   |              |                  |                    S01_AXI|<-)--)-------------------------|M_AXI          H2C_INTR_OUT|------------------>|INTR_IN       |
   |         S_AXI|<-----------------|M00_AXI                    |  |  |                         |                           |                   |              |
   |              |                  |                           |  |  |                         |                C2H_INTR_IN|<------------------|INTR_OUT      |
   |        IRQ_IN|<----------       |                           |  |  |       ------------------|IRQ_OUT                    |                   |              |
   |              |          |       |                           |  |  |       |                 |                C2H_GPIO_IN+<------------------+GPIO_OUT      |
   |       IRQ_ACK|------    |       |                           |  |  |       | +-------------->|IRQ_ACK                    |                   |              |
   |              |     |    |       |                           |  |  |       | |               |               H2C_GPIO_OUT+------------------>+GPIO_IN       |
   |______________|     |    |       |___________________________|  |  |       | |               |___________________________|                   |______________|
                        |    |                                      |  |       | |      
                        |    |                                      |  |       | |      
                        |    |       _____________________________  |  |       | |      
                        |    |       |                           |<-|  |       | |      
                        |    |-------|      CONCATENATION        |     |       | |      
                        |            |___________________________|<----)-------+ |      
                        |                                              |         |      
                        |            _____________________________     |         |      
                        |            |                           |-----|         |      
                        |----------->|        SPLITTER           |               |      
                                     |___________________________|----------------      
                                       
```



# Software-Hardware Flow



## ACE Master HW Bridge ( tlm2ace-hw-bridge )



### Mode_0 : Register Access (RD/WR Transactions)

In Mode_0, WDATA/RDATA is stored in BAR mapped registers of the ACE Protocol
HW bridge; Software will read them from register space and provide the
information to TLM Traffic generator.

**Initial Configuration**

1. SW (Software) to read BRIDGE_CONFIG registers to know bridge capability.

2. SW to program MODE_0_1 Bit in MODE_SELECT Register to select mode_0 i.e.
Register Access mode 

3. SW to program INTR_ERROR_ENABLE_REG, RD_REQ_INTR_COMP_ENABLE_REG,
INTR_FIFO_ENABLE_REG, WR_REQ_INTR_COMP_ENABLE_REG,
SN_RESP_INTR_COMP_ENABLE_REG, SN_DATA_INTR_COMP_ENABLE_REG  for interrupt mode.
This step is not required in polling mode.  

4. SW to program request descriptors (Registers of type Descriptor (DESC_*))
based on number of outstanding transaction to indicate various attributes of
the WR/RD transaction like: DUT address, length, size, exclusive, lock, etc.
along with offset address of the data RAM.  

5. In case of WR transaction SW has to fill WR Data and WSTRB RAM at
programmed offset address. Refer section "Managing WR/RD DATARAM" for more
details.

6. SW to program RD_RESP_FREE_DESC_REG, WR_RESP_FREE_DESC_REG Register as 0xFFFF
to HW, to indicate that Bridge can accept read, write response from DUT. 
  

**Data Flow**

1. SW to write descriptor number in RD_REQ_FIFO_PUSH_DESC_REG,
WR_REQ_FIFO_PUSH_DESC_REG.  

2. SW to wait for interrupt and then read INTR_STATUS_REG or poll
INTR_STATUS_REG register depending on Intr/poll mode of operation.
	2.a If ERROR field of INTR_STATUS_REG is set, it means some system
error has occurred. Read INTR_ERROR_STATUS_REG to identify the cause of error.
SW to take appropriate action based on severity. i,e SW can issue soft-reset
by writing into RESET_REG.
        2.b If RD_REQ_COMP field of INTR_STATUS_REG is set, it means
        read-request was accepted by DUT. SW to read RD_REQ_INTR_COMP_STATUS_REG
        to check which transaction got completed.
	2.c If WR_REQ_COMP field of INTR_STATUS_REG is set, it means
        write-request was accepted by DUT. SW to read WR_REQ_INTR_COMP_STATUS_REG
        to check which transaction got completed.
	2.d If field RD_RESP_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one read-response available from DUT with or without ACE (RRESP) error. 
	2.e If field WR_RESP_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one write-response available from DUT with or without ACE (BRESP) error.

3. In interrupt mode
        3.a SW to set respective bits of RD_REQ_INTR_COMP_CLEAR_REG and
        WR_REQ_INTR_COMP_CLEAR_REG.
        3.b SW to read RD_RESP_FIFO_POP_DESC_REG, WR_RESP_FIFO_POP_DESC_REG to
        know descriptor of read, write-response.
        3.c For interrupt mode, HW to de-assert irq_out.


4. SW to read read-response and write-response descriptors to determine response
from corresponding ACE BRESP/RRESP fields of each transaction.

5. For RD transactions, SW to read the data (RDATA) from offset
address(RD_RESP_DESC_0_DATA_OFFSET_REG). In case of RRESP error, SW can ignore
the RDATA in Bridge's DATA RAM.

6. SW to program the next descriptor if any, and program RD_RESP_FREE_DESC_REG,
WR_RESP_FREE_DESC_REG and write descriptor number in RD_REQ_FIFO_PUSH_DESC_REG,
WR_REQ_FIFO_PUSH_DESC_REG.


### Mode_1 : Indirect DMA  (RD/WR Transactions)

In Mode_1, Software configures the HW bridge with address in host memory
from/to where WDATA/RDATA need to be copied to in host memory.

**Initial Configuration**

1. SW to read BRIDGE_CONFIG registers to know bridge capability.

2. SW to program MODE_0_1 Bit in MODE_SELECT Register to select mode_0 i.e.
Indirect DMA mode 

3. SW to program INTR_ERROR_ENABLE_REG, RD_REQ_INTR_COMP_ENABLE_REG,
INTR_FIFO_ENABLE_REG, WR_REQ_INTR_COMP_ENABLE_REG,
SN_RESP_INTR_COMP_ENABLE_REG, SN_DATA_INTR_COMP_ENABLE_REG  for interrupt mode.
This step is not required in polling mode.  

4. SW to program request descriptors (Registers of type Descriptor (DESC_*))
based on number of outstanding transaction to indicate various attributes of
the WR/RD transaction like: DUT address, length, size, exclusive, lock, etc.
along with offset address of the data RAM.  

5. In addition to the attributes programmed in Mode_0, SW has to program host
address of the data ( and STRB in case Writes ) into the Bridge.  

6. SW to program RD_RESP_FREE_DESC_REG, WR_RESP_FREE_DESC_REG Register as 0xFFFF
to HW, to indicate that Bridge can accept read, write response from DUT. 
  
7. For WR transactions, HW bridge will fetch data from HOST address and fill
DATA RAM at programmed offset address.

8. For RD transactions, HW bridge will populate RDATA from DATA RAM into HOST
addresses upon getting response from DUT.

**Data Flow**

1. SW to write descriptor number in RD_REQ_FIFO_PUSH_DESC_REG,
WR_REQ_FIFO_PUSH_DESC_REG.  

2. SW to wait for interrupt and then read INTR_STATUS_REG or poll
INTR_STATUS_REG register depending on Intr/poll mode of operation.
	2.a If ERROR field of INTR_STATUS_REG is set, it means some system
error has occurred. Read INTR_ERROR_STATUS_REG to identify the cause of error.
SW to take appropriate action based on severity. i,e SW can issue soft-reset
by writing into RESET_REG.
        2.b If RD_REQ_COMP field of INTR_STATUS_REG is set, it means
        read-request was accepted by DUT. SW to read RD_REQ_INTR_COMP_STATUS_REG
        to check which transaction got completed.
	2.c If WR_REQ_COMP field of INTR_STATUS_REG is set, it means
        write-request was accepted by DUT. SW to read WR_REQ_INTR_COMP_STATUS_REG
        to check which transaction got completed.
	2.d If field RD_RESP_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one read-response available from DUT with or without ACE (RRESP) error. 
	2.e If field WR_RESP_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one write-response available from DUT with or without ACE (BRESP) error.

3. In interrupt mode
        3.a SW to set respective bits of RD_REQ_INTR_COMP_CLEAR_REG and
        WR_REQ_INTR_COMP_CLEAR_REG.
        3.b SW to read RD_RESP_FIFO_POP_DESC_REG, WR_RESP_FIFO_POP_DESC_REG to
        know descriptor of read, write-response.
        3.c For interrupt mode, HW to de-assert irq_out.


4. SW to read read-response and write-response descriptors to determine response
from corresponding ACE BRESP/RRESP fields of each transaction.

5. For RD transactions, SW to read the data (RDATA) from host memory. In case of
RRESP error, SW can ignore the RDATA in Bridge's DATA RAM.

6. SW to program the next descriptor if any, and program RD_RESP_FREE_DESC_REG,
WR_RESP_FREE_DESC_REG and write descriptor number in RD_REQ_FIFO_PUSH_DESC_REG,
WR_REQ_FIFO_PUSH_DESC_REG.


### Snoop Transactions

**Configuration & Attributes Steps**

1. SW to read BRIDGE_CONFIG registers to know bridge capability.

2. SW to program INTR_ERROR_ENABLE_REG ,RD_RESP_INTR_COMP_ENABLE_REG
,INTR_FIFO_ENABLE_REG ,WR_RESP_INTR_COMP_ENABLE_REG ,SN_REQ_INTR_COMP_ENABLE_REG
for interrupt mode.

3. SW to program SN_REQ_FREE_DESC_REG Register as 0xFFFF
to HW, to indicate that Bridge can accept snoop request from DUT. 
  

**Data Flow**

1. SW to wait for interrupt and then read  INTR_STATUS_REG or poll
INTR_STATUS_REG register.

	1.a If field ERROR of INTR_STATUS_REG is set, system error has
occurred. Read INTR_ERROR_STATUS_REG for further details. SW to take
appropriate actions i.e. issue soft-reset.
	1.b If field SN_REQ_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one snoop-request available from DUT. 

2. SW to read SN_REQ_FIFO_POP_DESC_REG to know descriptor of snoop-request.
        2.a For interrupt mode, HW to de-assert irq_out.

3. SW to write CRRESP in snoop-response descriptors. 

4. SW to write cddata starting from address (DESC_N*CACHE_LINE_SIZE) to CD
DATARAM, if required.

5. SW to write snoop-response descriptor number in SN_RESP_FIFO_PUSH_DESC_REG
and snoop-data descriptor number in SN_DATA_FIFO_PUSH_DESC_REG.

6. HW to generate snoop response and snoop-data(if any).

7. HW updates SN_RESP_COMP, SN_DATA_COMP in
INTR_STATUS_REG (and for interrupt mode, generate interrupt). 

8. For interrupt mode
        8.a SW to set respective bits of SN_RESP_INTR_COMP_CLEAR_REG,
        SN_RESP_INTR_COMP_CLEAR_REG.
	8.b For interrupt mode, HW to de-assert irq_out.

9. SW to program SN_REQ_FREE_DESC_REG to indicate that Bridge can accept snoop
request from DUT, if any.


## ACE Slave HW Bridge ( ace2tlm-hw-bridge )


### Mode_0 : Register Access (RD/WR Transactions)

**Configuration & Attributes Steps**

1. SW to read BRIDGE_CONFIG registers to know bridge capability.

2. SW to program MODE_0_1 Bit in MODE_SELECT Register to select mode_0 i.e.
register access mode

3. SW to program INTR_ERROR_ENABLE_REG ,RD_RESP_INTR_COMP_ENABLE_REG
,INTR_FIFO_ENABLE_REG ,WR_RESP_INTR_COMP_ENABLE_REG ,SN_REQ_INTR_COMP_ENABLE_REG
for interrupt mode.

4. SW to program RD_REQ_FREE_DESC_REG, WR_REQ_FREE_DESC_REG Register as 0xFFFF
to HW, to indicate that Bridge can accept read, write request from DUT. 
  

**Data Flow**

1. SW to wait for interrupt and then read  INTR_STATUS_REG or poll
INTR_STATUS_REG register.

	1.a If field ERROR of INTR_STATUS_REG is set, system error has
occurred. Read INTR_ERROR_STATUS_REG for further details. SW to take
appropriate actions i.e. issue soft-reset.
	1.b If field RD_REQ_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one read-request available from DUT. 
	1.b If field WR_REQ_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one write-request available from DUT.

2. SW to read RD_REQ_FIFO_POP_DESC_REG, WR_REQ_FIFO_POP_DESC_REG to know
descriptor of read, write-request.
        2.a For interrupt mode, HW to de-assert irq_out.

3. In case of WR, SW to read data,STRB starting from address
WR_REQ_DESC_N_DATA_OFFSET_REG  from DATARAM based on transaction size.

4. In case of RD, SW to write data starting from address
RD_RESP_DESC_N_DATA_SIZE_REG  from DATARAM based on transaction size.

5. SW to write descriptor number in RD_RESP_FIFO_PUSH_DESC_REG,
WR_RESP_FIFO_PUSH_DESC_REG.  

6. HW to generate write,read response.

7. Upon receiving RACK,WACK from DUT, HW updates RD_RESP_COMP, WR_RESP_COMP in
INTR_STATUS_REG (and for interrupt mode, generate interrupt). 

8. For interrupt mode
        8.a SW to set respective bits of RD_RESP_INTR_COMP_CLEAR_REG,
        WR_RESP_INTR_COMP_CLEAR_REG.
	8.b For interrupt mode, HW to de-assert irq_out.

9. SW to program RD_REQ_FREE_DESC_REG, WR_REQ_FREE_DESC_REG Register, to
indicate that Bridge can accept read, write request from DUT, if any.


### Mode_1 : Indirect DMA  (RD/WR Transactions)

**Configuration & Attributes Steps**

1. SW to read BRIDGE_CONFIG registers to know bridge capability.

2. SW will program MODE_0_1 Bit in MODE_SELECT Register to select mode_1 i.e.
Indirect DMA mode

3. SW to program INTR_ERROR_ENABLE_REG ,RD_RESP_INTR_COMP_ENABLE_REG
,INTR_FIFO_ENABLE_REG ,WR_RESP_INTR_COMP_ENABLE_REG ,SN_REQ_INTR_COMP_ENABLE_REG
for interrupt mode.

4. In addition to the attributes programmed in Mode_0, SW has to program host
address of the data ( and STRB in case Writes ) into the Bridge.

5. SW to program RD_REQ_FREE_DESC_REG, WR_REQ_FREE_DESC_REG Register as 0xFFFF
to HW, to indicate that Bridge can accept read, write request from DUT. 
  

**Data Flow**

1. SW to wait for interrupt and then read  INTR_STATUS_REG or poll
INTR_STATUS_REG register.

	1.a If field ERROR of INTR_STATUS_REG is set, system error has
occurred. Read INTR_ERROR_STATUS_REG for further details. SW to take
appropriate actions i.e. issue soft-reset.
	1.b If field RD_REQ_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one read-request available from DUT. 
	1.b If field WR_REQ_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one write-request available from DUT.

2. SW to read RD_REQ_FIFO_POP_DESC_REG, WR_REQ_FIFO_POP_DESC_REG to know
descriptor of read, write-request.
        2.a For interrupt mode, HW to de-assert irq_out.

3. In case of WR, it means write-data is available at Host memory.

4. In case of RD, SW to fill read-data in Host memory. 

5. SW to write descriptor number in RD_RESP_FIFO_PUSH_DESC_REG,
WR_RESP_FIFO_PUSH_DESC_REG.  

6. In case of RD, HW to fetch rdata from Host memory to RD DATARAM and
generate read response to the DUT.

7. In case of WR, HW to generate write response to DUT.


8. Upon receiving RACK,WACK from DUT, HW updates RD_RESP_COMP, WR_RESP_COMP in
INTR_STATUS_REG (and for interrupt mode, generate interrupt). 

9. For interrupt mode
        8.a SW to set respective bits of RD_RESP_INTR_COMP_CLEAR_REG,
        WR_RESP_INTR_COMP_CLEAR_REG.
	8.b For interrupt mode, HW to de-assert irq_out.

10. SW to program RD_REQ_FREE_DESC_REG, WR_REQ_FREE_DESC_REG Register, to
indicate that Bridge can accept read, write request from DUT, if any.


### Snoop Transactions

CDDATA is stored in BAR mapped registers of the ACE Protocol HW bridge;
Software will read them from register space and provide the information to TLM
Traffic generator.

**Initial Configuration **

1. SW (Software) to read BRIDGE_CONFIG registers to know bridge capability.

2. SW to program INTR_ERROR_ENABLE_REG, RD_REQ_INTR_COMP_ENABLE_REG,
INTR_FIFO_ENABLE_REG, WR_REQ_INTR_COMP_ENABLE_REG,
SN_RESP_INTR_COMP_ENABLE_REG, SN_DATA_INTR_COMP_ENABLE_REG  for interrupt mode.
This step is not required in polling mode.  

3. SW to program snoop-request descriptors (Registers of type Descriptor (DESC_*))
based on number of outstanding transaction to indicate various attributes of
the snoop transaction like: ACADDR, snoop type, prot.

4. SW to program SN_RESP_FREE_DESC_REG, SN_DATA_FREE_DESC_REG Register as 0xFFFF
to HW, to indicate that Bridge can accept read, write response from DUT. 
  

**Data Flow**

1. SW to write descriptor number in SN_REQ_FIFO_PUSH_DESC_REG.

2. SW to wait for interrupt and then read INTR_STATUS_REG or poll
INTR_STATUS_REG register depending on Intr/poll mode of operation.
	2.a If ERROR field of INTR_STATUS_REG is set, it means some system
error has occurred. Read INTR_ERROR_STATUS_REG to identify the cause of error.
SW to take appropriate action based on severity. i,e SW can issue soft-reset
by writing into RESET_REG.
        2.b If SN_REQ_COMP field of INTR_STATUS_REG is set, it means
        snoop-request was accepted by DUT. SW to read SN_REQ_INTR_COMP_STATUS_REG
        to check which transaction got completed.
	2.c If field SN_RESP_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one snoop-response available from DUT with or without ACE (ACRESP) error. 
	2.d If field SN_DATA_FIFO_NONEMPTY of INTR_STATUS_REG is set, at least
        one snoop-data transaction available from DUT.

3. In interrupt mode
        3.a SW to set respective bits of SN_REQ_INTR_COMP_CLEAR_REG.
        3.b SW to read SN_RESP_FIFO_POP_DESC_REG, SN_DATA_FIFO_POP_DESC_REG to
        know descriptor of snoop-response, snoop-data.
        3.c For interrupt mode, HW to de-assert irq_out.


4. SW to read snoop-response descriptors to determine response.

5. SW to read the data (CDDATA) from offset address (DESC_N*CACHE_LINE_SIZE).

6. SW to program the next descriptor if any, and program SN_RESP_FREE_DESC_REG,
SN_DATA_FREE_DESC_REG and write descriptor number in SN_REQ_FIFO_PUSH_DESC_REG.



# Bridge Discovery Mechanism


Following is the sequence to identify number of bridges in the design and their
addresses.

While building design using bridges,

1. User will have to make sure that Bridges are connected to BAR-0 starting from
offset 0x0.  2. All bridges should be connected to consecutive locations without
any gap in between. [ Every 128 KB from ( BAR-0 + 0x0 ) will have a new Bridge ]
3. In the Last bridge, user will have to set parameter LAST_BRIDGE=1, which will
be propagated into the field LAST_BRIDGE of register BRIDE_POSITION_REG and
available for software to read.

For software to identify bridges,

1. Upon start, Software will start traversing through BAR-0 offset 0x0.  2.
Software will read the LAST_BRIDGE Field of BRIDGE_POSITON_REG for each bridge.
3. If LAST_BRIDGE is "1", It will stop finding more bridges, else Software will
go to 0x0 + ( 128 KB ) and do the same process until it gets LAST_BRIDGE = "1".




