# CHI Bridges

## Introduction

This document gives architecture, data flow and system level details of the
CHI Hardware Bridges.

|Acronyms|                                               |
|--------|-----------------------------------------------|
|QEMU	 | Quick Emulator                                |
|AXI	 | Advanced eXtensible Interface                 |
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




## CHI Bridges use-model


CHI RN-F and HN-F Bridge use-model with CHI HN-F and RN-F Device Under Tests (DUT) and PCIe Sub-system is shown in below diagram.


```

                            ___________________________________________________________________________________________________________
                            |    ___________________________________________|__________                                                 |                         
    ______________          |   |     ___________________________       |   |          |          ___________________________           |         ______________
   |              |         |   |    |                           |      |   |          |         |                           |          |        |              |         
   |              |         |   |    |                           |      |   |----------(---+---->|CLK                        |          |------->|CLK           |
   |              |         |   |    |                           |      |              |   |     |                        CHI|------------------>|CHI           |
   |       AXI_CLK|---------+---)--->|*_ACLK                     |      +--------------(---(---->|RESETN                     |                   |              |
   |              |         |   |    |                           |                     |   |     |                 USR_RESETN|------------------>|RSTN          |
   |   AXI_ARESETN|---------)---+--->|*_ARESETN                  |                     |   |     |                           |                   |              |
   |              |         |   |    |                           |                     |   |     |                           |                   |              |
   |         M_AXI|---------)---)--->|S00_AXI             M00_AXI|---------------------(---(---->|S_AXI                      |                   |              |
   |              |         |   |    |                           |                     |   |     |                           |                   |              |
   |              |         |   |    |            AXI            |                     |   |     |                           |                   |              |          
   |              |         |   |    |        INTERCONNECT       |                     |   |     |        CHI RN-F           |                   |  CHI HN-F    | 
   |              |         |   |    |                           |                     |   |     |         BRIDGE            |                   |     DUT      |
   |              |         |   |    |                           |                     |   |     |                           |                   |              |
   |              |         |   |    |                           |                     |   |     |                           |                   |              |
   |              |         |   |    |                    M01_AXI|-----------          |   |     |               H2C_INTR_OUT|------------------>|INTR_IN       |
   |              |         |   |    |                           |          |          |   |     |                           |                   |              |
   |              |         |   |    |                           |          |          |   |     |                C2H_INTR_IN|<------------------|INTR_OUT      |
   |              |         |   |    |                           |  |-------|----------(---(-----|IRQ_OUT                    |                   |              |
   |   PCIe Core  |         |   |    |                           |  |       |          |   |     |                C2H_GPIO_IN+<------------------+GPIO_OUT      |
   |       &      |         |   |    |                           |  |  -----|----------(---(---->|IRQ_ACK                    |                   |              |
   |    AXI-MM    |         |   |    |                           |  |  |    |          |   |     |               H2C_GPIO_OUT+------------------>|GPIO_IN       |
   |    Bridge    |         |   |    |___________________________|  |  |    |          |   |     |___________________________|                   |______________|
   |              |         |___|___________________________________|__|____|   _______|___|____________________________________________
   |              |         					    |  |    |          |   |      ___________________________           |         ______________
   |              |         					    |  |    |          |   |     |                           |          |        |              |         
   |              |         					    |  |    |----------(---(---->|                           |          |------->|CLK           |
   |              |         					    |  |               |   |     |S_AXI                      |                   |              |
   |              |         					    |  |               |   |     |                        CHI|<------------------|CHI           |
   |              |         					    |  |               |   ----->|CLK                        |                   |              |
   |              |         					    |  |               |         |                 USR_RESETN|------------------>|RSTN          |
   |              |         					    |  |               |-------->|RESETN                     |                   |              |
   |              |         					    |  |                         |                           |                   |              |
   |              |         					    |  |                         |                           |                   |              |
   |              |         					    |  |                         |                           |                   |              |          
   |              |         					    |  |                         |        CHI HN-F           |                   |  CHI RN-F    | 
   |              |         					    |  |                         |         BRIDGE            |                   |     DUT      |
   |              |         					    |  |                         |                           |                   |              |
   |              |         					    |  |                         |                           |                   |              |
   |              |         					    |  |			 |               H2C_INTR_OUT|------------------>|INTR_IN       |
   |              |						    |  |                         |                           |                   |              |
   |              |                  				    |  |                         |                C2H_INTR_IN|<------------------|INTR_OUT      |
   |        IRQ_IN|<----------       				    |  |       ------------------|IRQ_OUT                    |                   |              |
   |              |          |       				    |  |       |                 |                C2H_GPIO_IN+<------------------+GPIO_OUT      |
   |       IRQ_ACK|------    |       				    |  |       | +-------------->|IRQ_ACK                    |                   |              |
   |              |     |    |       				    |  |       | |               |               H2C_GPIO_OUT+------------------>|GPIO_IN       |
   |______________|     |    |       				    |  |       | |               |___________________________|                   |______________|
                        |    |       				    |  |       | |      
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



# System Details


- DUT will be implemented in FPGA
- QEMU and  LibSystemCTLM-SoC run on x86 host 
- PCIe protocol used as medium to connect x86 (as Root Complex) with FPGA (as EndPoint)
- Supports CHI protocol
- CHI FPGA Bridges supports only mode-0 of operation
	
	1. Mode_0: Register Access mode  
  In this mode, software programs the attributes in the BAR mapped Protocol Bridge's address/register space. The protocol bridges then create protocol based pin wiggling onto the DUT. The Write/read/snoop data corresponding to the CHI flits are written/read by Host software. If the DUT has the CHI RN-F, then the CHI HN-F is in SystemC/TLM framework on x86, and vice versa.  The attributes of the CHI transactions are required for the TLM Traffic generator to generate transactions/response towards CHI HN-F/RN-F on SystemC side.

# Software-Hardware Flow

- Flit Transmission Flow in a Bridge:
	-  Software reads CHI_FLIT_CONFIG_REG.CHI_BRIDGE_FEATURE_EN_REG to understand the Bridge features.
	-  Software programs BRIDGE_CONFIGURE_REG,REFILL_CREDITS_REG for all 3 receive channels.
	-  If Interrupt Mode required Software programs INTR_FLIT_TXN_ENABLE_REG.
	-  Once the Link comes up, checked through CHI_BRIDGE_TX_STS_REG and CHI_BRIDGE_RX_STS_REG,
	-  Software programs Flits into TXREQ Memory and also sets TXREQ_OWNERSHIP_FLIP_REG based on the number of flits to be sent.
	-  Once a Flits Request is transmitted over TXREQ Channel, an interrupt is raised with INTR_FLIT_TXN_STATUS_REG having field TXREQ_FLIT_SENT set to 1.
	-  Upon checking the interrupt, or even in Polling the INTR_FLIT_TXN_STATUS_REG and when set, software clears the status with INTR_FLIT_TXN_CLEAR_REG for the corresponding bit which has been set in INTR_FLIT_TXN_STATUS_REG.
- Flit Reception Flow in a Bridge:
	- Software reads CHI_FLIT_CONFIG_REG.CHI_BRIDGE_FEATURE_EN_REG to understand the Bridge features.
 	- Software programs BRIDGE_CONFIGURE_REG,REFILL_CREDITS_REG for all 3 receive channels.	
 	- If Interrupt Mode required Software programs INTR_FLIT_TXN_ENABLE_REG.
 	- When Link is UP, it can receive responses or data or requests on receive channels.	
 	- When Request is received in a Bridge, it is stored in RXREQ Memory and the TAKE_RXREQ_OWNERSHIP field is set in the RXREQ_OWNERSHIP_REG register in the order of incoming flits.
 	- If the INTR_FLIT_TXN_ENABLE_REG is set, an interrupt is raised with RXREQ_FLIT_RECEIVED field in the INTR_FLIT_TXN_STATUS_REG set. 
 	- Upon receiving the interrupt , or even in Polling the INTR_FLIT_TXN_STATUS_REG and when set ,software clear the status with setting the INTR_FLIT_TXN_CLEAR_REG for the field corresponding to RXREQ_FLIT_RECEIVED.
 	- It later reads the RXREQ Flit from the RXREQ Memory over AXI4 Lite bus and later sets the RXREQ_OWNERSHIP_FLIP register.
 	- This shall reset the RXREQ_OWNERSHIP_REG for as many flits received.
