# CXS TLM HW Bridge

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

A more detailed description of how the HW bridges operate can be found in
[../../rtl-bridges/bridges.md](../../rtl-bridges/tlm/bridges.md).

## tlm2cxs-hw-bridge.h

The TLM2CXS HWB accepts TLM GPs (describing CCIX messages) and by means of
driving a HWB via TLM2VFIO injects a TLP containg the CCIX message on the
HW side. The incoming TLM GPs are expected to be in the format generated
by the CCIX port in the
[iconnect-chi](../../../tlm-modules/iconnect-chi.h).

The TLM2CXS HWB also receives CXS TLPs through the HWB (and TLM2VFIO) and
extracts and forwards the CCIX messages in the TLP (the CCIX messages are
described with TLM GPs in the format expected by iconnect-chi's CCIX
port).


```
             ._______________.                     .__________.  ._____.
   TX TLM GP |               |  TLM GP Reg-access  |          |  |     |
 ----------->|  TLM2CXS HWB  |<------------------->| TLM2VFIO |--| HWB | -------->
   RX TLM GP |               |       IRQs          |          |  |     |    CXS
 <-----------|               |                     |          |  |     | <--------
             `---------------'                     `----------'  `-----`
```

## HWB Usage examples

Inside the [CXS RTL bridge test directory](../../../tests/rtl-bridges/cxs)
a VFIO tests is found demonstrating how to connect the CXS HWB bridge.
More information about the tests can be found in the
[README.md](../../../tests/rtl-bridges/cxs/README.md) located in the test
directory.

## iconnect-chi & CCIX Port

More information about iconnect-chi and the CCIX port can be found inside
[docs/components-chi.txt](../../components-chi.txt).
