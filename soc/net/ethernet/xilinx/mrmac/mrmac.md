# Xilinx MRMAC - SystemC/TLM-2.0 model

## Introduction

The Xilinx Mulirate Ethernet MAC (MRMAC) is an Ethernet MAC integrated into some
Versal devices. You can find more information about it here [PG314].

## Model

This model emulates a single channel instance. To create the 4-channel MRMAC
composition used in some Versal devices, you'll need to instantiate 4 instances
of this model.

### Accuracy

This is a functional LT TLM-2.0 model. It is not cycle accurate and it abstracts away
many low-level details in the communication.

The PCS is modelled very abstractly. There won't ever be any errors, the link is always
up and there's no training or such low-level details going on.

### Ports

| Port           | Description |
|----------------|-------------|
| mac_rx_socket  | AXI4-Stream channel where the MAC will send packets towards user-logic       |
| mac_tx_socket  | AXI4-Stream channel where the MAC will recieve packets from the user-logic   |
| phy_tx_socket  | GTM/GTY interface where the MAC will send packets towards physical layer     |
| phy_rx_socket  | GTM/GTY interface where the MAC will reieve packets from the physical layer  |
| reg_socket     | APB memory-mapped interface where the MAC will respond to registrer accesses |
| rst            | Reset signal                                                                 |

### GTM/GTY interfaces

The interface towards the GTM/GTY is modelled by a TLM socket.
Generic payloads carry Ethernet frames. These frames are raw Ethernet frames without
any particular encoding or FEC.

### AXI4-Stream interfaces

The AXI4-Stream interfaces towards the user-logic are modelled as TLM sockets using
libsystemctlm-soc's generic attributes to signal AXI4-Stream's TLAST signal as EOP.
libsystemctlm-soc's generic attributes is an optional TLM-2.0 extension [genattr].

### Limitations

The model does not emulate the IEEE 1588 Timestamping features.
The model does not emulate FEC.

References:  
[PG314]: https://docs.xilinx.com/r/1.3-English/pg314-versal-mrmac/Introduction  
[genattr]: https://github.com/Xilinx/libsystemctlm-soc/blob/master/tlm-extensions/genattr.h  

