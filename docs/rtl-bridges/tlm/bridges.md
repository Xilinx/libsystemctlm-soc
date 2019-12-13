# TLM HW Bridges

| Abbreviation | Explanation                 |
|--------------|-----------------------------|
| GP           | Generic Payload             |
| HWB          | Hardware Bridge             |
| MM           | Memory Manager              |
| TLM          | Transaction level modelling |
| TG           | Traffic Generator           |

## Overview

The TLM HW Bridges implement a SystemC TLM integration for RTL HW Bridges.
The purpose of these TLM modules is to on one side, act as a driver for the
HWB by issuing register reads/writes, receiving interrupts and setting
up DMA transactions. On the other side, these bridges expose the capabilities
of the HWB through TLM constructs such as TLM sockets and SystemC signals.

Since these TLM modules run in the SystemC framework, in user-space, we either
need to interact with the HWB by means of a kernel driver or by using
a kernel API allowing drivers to run in user-space. The current implementation
uses the latter, the VFIO interface for Linux. Only Linux is supported at this
stage.

By using VFIO in user-space, the TLM HWB implementation does not require users
to install a custom driver into their Operating System. The simulation bridge
will work on any system with VFIO support.

```
                        .___________.
                TLM     |           |   VFIO
Simulation  <---------->|  TLM HWB  |<--------> HW
              SystemC   |           |
                        `-----------'
```

## tlm2vfio-bridge.h

The TLM2VFIO bridge accepts TLM GPs and converts the transaction described
in the GP into equivalent load/stores that get issued into VFIO mapped
regions. This becomes the way for the simulation to access HW registers.

This bridge is also responsible for forwarding interrupts from the hardware
(captured by means of VFIO) and propagating those interrupts onto a SystemC
signal.

```
                          .___________.
                 TLM GP   |           |  VFIO Memory load/stores
Simulation     ---------->| TLM2VFIO  |-------------------------->  HW
                          |           |
                   IRQs   |           |  IRQs
               <----------|           |<-------------------------
                          `-----------'
```

### tlm_mm_vfio

In addition to the bridging functions, the tlm2vfio-bridge.h file also
implements a VFIO GP allocator or memory manager suitable for DMA purposes.
It's an index based allocator that pre-allocates all the GP buffers linearly
in virtual memory, pins the pages to a specific VA-PA mapping and configures
any IOMMUs between the HWB and host memory so that the HWB see's a
linear address-region. This makes it possible for a HWB to DMA payload
straight into GP buffers in user-space.

The current implementation of the GP memory manager tlm_mm_vfio has a couple
of known limitations. One of them is that tlm_mm_vfio only creates and handles
mappings for one HWB per VFIO device (i.e one mapping per PCIe EP). This
means that we can currently only use one HWB with direct DMA (mode1) support
per PCIe EP.

## tlm2axi-hw-bridge.h

The TLM2AXI HWB accepts TLM GPs and by means of driving a HWB via TLM2VFIO
injects the equivalent transaction on the HW side.

Currently, the TLM2AXI HWB only works in mode0, i.e the incoming GP buffers
are copied over to HWB internal RAMs. Fixing this, means we need to modify
any relevant TLM initiators (likely the TLM TGs and remote-port) to use
the tlm_mm_vfio memory manager to allocate buffers. We'd also need to lift
the limitations of single bridge per PCIe EP from the MM.


```
            ._______________.                     .__________.  ._____.
   TLM GP   |               |  TLM GP Reg-access  |          |  |     | AXI Txn
 ---------->|  TLM2AXI HWB  |<------------------->| TLM2VFIO |--| HWB | -------->
            |               |       IRQs          |          |  |     |
            `---------------'                     `----------'  `-----`
```

## axi2tlm-hw-bridge.h

The AXI2TLM HWB traps any AXI transactions on the HW side and converts those into
TLM GPs by means of driving the AXI Slave HWB. These GPs are then injected into
the TLM simulation.

```
            ._______________.                     ._____.
   TLM GP   |               |  TLM GP Reg-access  |     |  AXI Txn
 <----------|  AXI2TLM HWB  |<------------------->| HWB |<---------
            |               |       IRQs          |     | 
            `---------------'                     `-----'
```


