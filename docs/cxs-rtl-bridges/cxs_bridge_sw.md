
# CXS Bridges

# Introduction
The document provides system level details and the software flow of CXS Packets in CXS Bridge.
#
|Acronyms                      | |   
|---------------------------------|-------------------
|QEMU             	  |   Quick Emulator    
|AXI              	  |   Advanced eXtensible Interface              
|XDMA       		  |  Xilinx DMA IP  
|FPGA             	  |   Field Programmable Gate Array
|PCIe             | Peripheral Component Interconnect Express            
|DUT           	  |   Device Under Test 
|EP           	  | End Point        
|MSI         	 	  |  Message Signaled Interrupt        
|MSI-X          		  |   Message Signaled Interrupt-Extended      
|BAR           	  | Base Address Register          
|TLM        	  |   Transaction-level Modeling         
|DESC         	  |   Descriptor            
|C2H         	  |   Card to Host           
|H2C     	  |  Host to Card
      



    
  



## CXS Bridges use-model
 CXS Bridge use-model with another CXS Bridge as Device Under Tests (DUT) and PCIe Sub-system is shown in below diagram.
`````


                             +------------------------------------------------------------+
                             |                                                            |
                             |                                                            |
                           +-----------------------------------------------+--------+     |-------------------------------+
                           | |                                             |        |     |                               |
                           | |                                             |        |     |                               |
+--------------------+     | |     +---------------------------+           |     +--v-----v---------------------+         |
|                    |     | |     |                           |           |     |  CLK   RESETN           cxs_t+------------------->
|                    |     | |     |                           |           |     |                              |         |         |
|                    |     | |     |                           |           |     |                          cxs_r<--------------+   |
|                    |     | |     |                     M00_AXI---------------->+S_AXI                         |         |     |   |
|             AXI_CLK+-----+------>+ *_ACLK                    |           |     |                              |         |     |   |
|                    |       |     |                           |           |     |                              |         |     |   |
|                    |       |     |                           |           |     |       CXS Bridge 1           |         |     |   |
|         AXI_ARESETN+-------+---->+*_ARESETN                  |           |     |                              |         |     |   |
|                    |             |                           |           |     |                              |         |     |   |
|                    |             |    AXI Interconnect       |   +------------>+                      USER_   |         |     |   |
|               M_AXI+------------>+S00_AXI                    |   |       |     |                      RESETN  |         |     |   |
|                    |             |                           |   |   +---------+                              |         |     |   |
|                    |             |                           |   |   |   |     |                  C2H    C2H  |         |     |   |
|  PCIe Core &       |             |                           |   |   |   |     | H2CINTR  H2CGPIO INTRIN GPIO |         |     |   |
|  AXI MM Bridge     |             |                           |   |   |   |     +-OUT------OUT+-----^-----IN---+         |     |   |
|                    |             |                           |   |   |   |          |        |     |      |             |     |   |
|                    |             |                           |   |   |   |          v        |     |      |             |     |   |
|                    |             |                           |   |   |   |     +----+--------v-----+------+---+         |     |   |
|                    |             |                           |   |   |   |     | INTRIN   GPIOIN  INTR   GPIO |         |     |   |
|                    |             |                           |   |   |   |     |                  OUT    OUT  |         |     |   |
|                    |             |                    MO1_AXI+---------------->+S_AXI                         |         |     |   |
|                    |             |                           |   |   |   |     |                              |         |     |   |
|                    |             |                           |   |   |   +---->+CLK                           |         |     |   |
|                    |             |                           |   |   |         |                        RESETN+<--------+     |   |
|                    |             |                           |   |   |         |   CXS Bridge 2               |               |   |
|                    |             +---------------------------+   |   |         |                              |               |   |
|                    |                                             |   |         |                              |               |   |
|                    |                                             |   |         |                              |               |   |
|                    |             +--------------------------+    |   |         |                              |               |   |
|                    |             |                          +<-------+         |                         cxs_t+---------------+   |
|              IRQ_IN<-------------+ CONCATENATION            |    |             |                              |                   |
|                    |             |                          <------------------+                              |                   |
|                    |             +--------------------------+    |             |                         cxs_r+<------------------+
|             IRQ_ACK+------------+                                |             +---+--------------------------+
|                    |            +---------------------------+    |                 ^
+--------------------+            ||                          +----+                 |
                                  || SPLITTER                 |                      |
                                  >+                          +----------------------+
                                   +--------------------------+
`````
## Software-Hardware Flow

### Flit Transmission Flow in a Bridge:

- Software reads CXS_FLIT_CONFIG_REG to understand the Bridge features.
- Software programs CXS_BRIDGE_CONFIGURE_REG for link layer activation and REFILL_CREDITS_REG for Receive Interface
- Once the Link comes up, checked through CXS_BRIDGE_TX_STS_REG and CXS_BRIDGE_RX_STS_REG.
Software also read the TX_CURRENT_CREDIT_REG to ascertain the number of Flits there in the number of TLP(s) to be sent.
Software programs Flits consisting of TLP(s) into TX Data Memory and Control Field into TX Control Memory  and also sets TX_OWNERSHIP_FLIP_REG based on the number of flits to be sent.
- If the INTR_FLIT_TXN_ENABLE_REG is set, an interrupt is raised with TX_FLITS_TRANSMITTED field in the INTR_FLIT_TXN_STATUS_REG set.
- If Interrupt is disabled, software polls the INTR_FLIT_TXN_STATUS_REG to check if Flits are sent.
 In Polling the INTR_FLIT_TXN_STATUS_REG and when set, software clears the status with INTR_FLIT_TXN_CLEAR_REG for the corresponding bit which has been set in INTR_FLIT_TXN_STATUS_REG.

###  Flit Reception Flow in a Bridge:
- Software reads CXS_FLIT_CONFIG_REG  to understand the Bridge features.
- Software programs CXS_BRIDGE_CONFIGURE_REG for link layer activation and REFILL_CREDITS_REG for Receive Interface.
- If Interrupt Mode required Software programs INTR_FLIT_TXN_ENABLE_REG.
- When Link is UP, it can receive Flits on Receive CXS Interface.
- When Flit is received in a Bridge, it is stored in RX CXS Data Memory , the Control Field is stored in RX CXS Cntl Memory.
The TAKE_RX_OWNERSHIP field is set in the RX_OWNERSHIP_REG register in the order of incoming flits.
- If the INTR_FLIT_TXN_ENABLE_REG is set, an interrupt is raised with RX_FLIT_RECEIVED field in the INTR_FLIT_TXN_STATUS_REG set.
- Upon receiving the interrupt , or even in Polling the INTR_FLIT_TXN_STATUS_REG and when set ,software clear the status with setting the INTR_FLIT_TXN_CLEAR_REG for the field corresponding to RX_FLIT_RECEIVED.
- It later reads the RX Flit from the RX CXS Data Memory and Flit Control from RX CXS Control Memory over AXI4 Lite bus and later sets the RX_OWNERSHIP_FLIP register.
- This shall reset the RX_OWNERSHIP_REG for as many flits received.




