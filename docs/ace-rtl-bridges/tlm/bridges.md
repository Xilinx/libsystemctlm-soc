# ACE TLM HW Bridges

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
[../../rtl-bridges/bridges.md](../../rlt-bridges).

## tlm2ace-hw-bridge.h

The TLM2ACE HWB accepts TLM GPs (ACE) and by means of driving a HWB via TLM2VFIO
injects the equivalent transaction on the HW side. The TLM GP is expected to be
in the format [cache-ace](../../../tlm-modules/cache-ace.h) generates ACE TLM GP
transactions. The TLM2ACE HWB also receives ACE snoop transactions through the
HWB (and TLM2VFIO) and forwards this as ACE snoop TLM GPs to the TLM side (in
the format expected by [cache-ace](../../../tlm-modules/cache-ace.h)).

Currently, the TLM2ACE HWB only works in mode0, i.e the incoming GP buffers
are copied over to HWB internal RAMs. Fixing this, means we need to modify
any relevant TLM initiators (likely the TLM TGs and cache-ace) to use
the tlm_mm_vfio memory manager to allocate buffers. We'd also need to lift
the limitations of single bridge per PCIe EP from the MM.


```
            ._______________.                     .__________.  ._____.
   TLM GP   |               |  TLM GP Reg-access  |          |  |     | ACE Txn
 ---------->|  TLM2ACE HWB  |<------------------->| TLM2VFIO |--| HWB | -------->
   SNP GP   |               |       IRQs          |          |  |     |
 <----------|               |                     |          |  |     |
            `---------------'                     `----------'  `-----`
```

## ace2tlm-hw-bridge.h

The ACE2TLM HWB traps any ACE transactions on the HW side and converts those
into TLM GPs (ACE) that are forwarded and injected into the TLM side. The
generated ACE TLM GPs are in the format expected by
[iconnect-ace](../../../tlm-modules/iconnect-ace.h). The ACE2TLM HWB bridge also
accepts TLM GP snoop transactions on the TLM side (in the same format generated
by [iconnect-ace](../../../tlm-modules/iconnect-ace.h)) and injects the
equivalent transactions on the HW side through the HWB (and TLM2VFIO).

```
            ._______________.                     ._____.
   TLM GP   |               |  TLM GP Reg-access  |     |  ACE Txn
 <----------|  ACE2TLM HWB  |<------------------->| HWB |<---------
   SNP GP   |               |       IRQs          |     |
 ---------->|               |                     |     |
            `---------------'                     `-----'
```

## HWB Usage examples

Inside the [ACE RTL bridge test directory](../../../tests/rtl-bridges/ace) 2
VFIO tests are found demonstrating how to connect the ACE HWB bridges. More
information about the tests can be found in the
[README.md](../../../tests/rtl-bridges/ace/README.md) located in the test
directory.

## cache-ace & iconnect-ace

More information about cache-ace and iconnect-ace can be found inside
[docs/components-ace.txt](../../components-ace.txt).
