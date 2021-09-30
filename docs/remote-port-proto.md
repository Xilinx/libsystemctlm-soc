# The Remote-Port protocol

#### Table of Content
   * [1 Introduction](#1-introduction)
   * [2 Setup phase](#2-setup-phase)
   * [3 Base header](#3-base-header)
   * [4 HELLO packet](#4-hello-packet)
   * [5 READ packet](#5-read-packet)
     * [5.4 Extended READ packet](#54-extended-read-packet)
   * [6 WRITE packet](#6-write-packet)
     * [6.3 Extended WRITE packet](#63-extended-write-packet)
   * [7 INTERRUPT packet](#7-interrupt-packet)
   * [8 SYNC packet](#8-sync-packet)
   * [9 ATS REQUEST packet](#9-ats-request-packet)
   * [10 ATS INVALIDATE packet](#10-ats-invalidate-packet)
   * [11 CFG packet](#11-cfg-packet)
   * [References](#references)


# 1 Introduction

Remote-Port (RP) is an inter-simulator protocol. It assumes a reliable
point to point communication with the remote simulation environment.

This document contains a description of the Remote-Port protocol version
4.3. While the Remote-Port protocol attempts to be backwards compatible,
this document might lack descriptions of additions and modifications to
future versions of the protocol. The latest version of the protocol will
always be found implemented in [1] and [2]. These implementations can also
be considered reference implementations. It is therefore strongly
recommended to read and follow the implementations in [1] an [2] for
keeping up to date with the most recent version of the protocol.

# 2 Setup phase

In the setup phase a mandatory HELLO packet is exchanged with optional CFG
packets following. The HELLO packet transmitted contains the supported
Remote-Port version and also additional capability support at the issuing
simulator side (see Table 2 for a list of capabilities that can be
supported). HELLO packets are useful to ensure that both sides are
speaking the same protocol and using compatible versions.


#### Picture 1 HELLO packet exchange
```
Simulator 1            Simulator 2
    |                     |
    |     Remote-Port     |
    |     +---------+     |
    |-----|  HELLO  |---->|
    |     +---------+     |
    |                     |
    |     +---------+     |
    |<----|  HELLO  |-----|
    |     +---------+     |
    |                     |
```

Once the HELLO packet exchange has been performed the session is
considered to be up and communication through various other commands can
begin.

# 3 Base header

All Remote-Port packets start with the base header depicted in Picture 2.
The base header is followed by a command specific header and payload.

#### Picture 2 The Remote-Port packet base header
```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |               command                |
      +--------------------------------------+
      |               length                 |
      +--------------------------------------+
      |               ID                     |
      +--------------------------------------+
      |               flags                  |
      +--------------------------------------+
      |               device                 |
      +--------------------------------------+
```

### 3.1 Command

The 'command' field specifies the packet's command type, see table 1 for
valid command types.

#### Table 1

|Command |                |
|--------|----------------|
|0	 | NOP            |
|1	 | HELLO          |
|2	 | CFG            |
|3	 | READ           |
|4	 | WRITE          |
|5	 | INTERRUPT      |
|6	 | SYNC           |
|7	 | ATS REQUEST    |
|8	 | ATS INVALIDATE |

### 3.2 Length

The 'length' field contains the length in bytes of the payload that
follows the base header (the length of the command specific header plus if
included the data payload).

### 3.3 ID

The packet 'ID' must be unique for each outgoing command (request) packet.
In case the command expects a response packet the same ID as in the
request packet must be used in the response packet from the peer simulator
(the ID is used to match the request packet with it's response packet at
the command issuing simulator).

### 3.4 Flags

The 'flags' fields carry additional information about the packet marked
with bit flags that or'ed in into the field (see Table 2 for valid flags).

#### Table 2

|Flags   |                 |
|--------|-----------------|
|0x1	 | Optional packet |
|0x2	 | Response packet |
|0x4	 | Posted packet   |

The 'Optional' flag marks the packet as optional to process (the current
version of the protocol has not specified any optional packets).

The 'Response' flag is unset for command packets and set on command
response packets.

The 'Posted' flag is set on command packets that do not require a command
response packet from the peer. If the peer decides to respond with a
response packet, it is required that the response packet also contains the
'Posted' flag set (and the response packet must be ignored at the command
issuing simulator).

### 3.5 Device

The 'device' field contains the ID of a Remote-Port device intended to
receive and process the Remote-Port packet. A Remote-Port device is a
device that processes a subset of the Remote-Port commands inside a
Remote-Port implementation. A device might for example only handle READ
and WRITE commands while another device is made to only process INTERRUPT
commands.  Also by assigning an ID to each Remote-Port device it is
possible to have multiple of the same type instantiated, e.g. it is
possible to have one device handling READ and WRITES to an area of the
memory map and a second device of the same type but with a different ID
handling READ and WRITE commands to a second memory area. Picture 3
depicts this scenario where all read and write transactions targeting the
Remote-Port devices inside simulator 1 are propagated over and processed
by the devices with the same ID in simulator 2 (the devices in simulator 2
converts the transactions to TLM transactions into two different TLM based
memories). The 'device' field can thus also be seen as an ID of a virtual
channel through which commands (and command responses) propagate between
devices (with the same ID) in the simulators.

#### Picture 3
```
 Simulator 1                            Simulator 2 (SystemC / TLM 2.0)
    ...                                    ...
+---------------+                      +--------------+      +----------+
|  RP device    |    Remote-Port       |  RP device   | TLM  |   TLM    |
|               |----------------------|              |------|  Memory  |
|  Device ID 5  |    Channel ID 5      |  Device ID   |------|    0     |
|               |----------------------|      5       |      +----------+
| Handles area: |                      |              |
|  0x0 - 0x80   |                      +--------------+
+---------------+
+---------------+                      +--------------+
|  RP device    |    Remote-Port       |  RP device   |      +----------+
|               |----------------------|              | TLM  |   TLM    |
| Handles area: |    Channel ID 9      |  Device ID   |------|  Memory  |
| 0x80 - 0x100  |----------------------|      9       |------|    1     |
|               |                      |              |      +----------+
|  device ID 9  |                      +--------------+
+---------------+
    ...                                    ...
```

Examples of Remote-Port devices found in [2] are listed below.

* A Remote-Port memory master device that generates read and write
  transactions over the Remote-Port

* A Remote-Port memory slave device that processes incoming Remote-Port
  read and write transactions (generated by a memory master device in the
  peer simulator)

* A Remote-Port gpio device transmitting and receiving wire updates
  through INTERRUPT command packets

* A Remote-Port ATS device processing incoming ATS REQUEST packets and
  generating ATS INVALIDATE packets

# 4 HELLO packet

The HELLO packet consists of the base header followed by fields
specifying the Remote-Port version and also an array of additional
capabilities supported at the issuing simulator side.

#### Picture 4 HELLO packet

```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |            command 1 (HELLO)         |
      +--------------------------------------+
      |             length                   |
      +--------------------------------------+
      |             id                       |   Base header
      +--------------------------------------+
      |             flags                    |
      +--------------------------------------+
      |             device                   |
      +--------------16+15-------------------+   ---------
      | major version  |  minor version      |   HELLO packet specific
      +----------------+---------------------+   header.
      |        capabilities offset           |
      +--------------16+15-------------------+
      |  reserved0     | capabilities length |
      +----------------+---------------------+   ---------
                     ....
      +--------------------------------------+
      |             capability0              |   Only if capabilities offset
      +--------------------------------------+   and length are specified
                     ....
      +--------------------------------------+
      |             capabilityN              |
      +--------------------------------------+
```

## 4.1 Base header fields

The 'command' field in the base header is '1', HELLO (see table 1).

The 'flags' field is unused.

The 'length' field specifies in bytes the length of the HELLO packet
specific header plus the length of the payload (capabilities array).

The 'device' field contains the ID of the target Remote-Port device for
the packet.

While unused it is recommended that the 'ID' field is unique at the issuing
simulator side.

## 4.2 The major and minor version fields

The major and minor version fields contain the Remote-Port protocol
version supported at the packet issuing side.

## 4.3 Capabilities

HELLO packets may contain an array of capabilities specifying additional
feature support at the issuing simulator side. For capabilities to be
used they have to be supported by both sides of the communication. The
'capabilities offset' field in the HELLO packet header specify the starting
location in the packet where the capabilities are found. The 'capabilities
length' field contain the number of capabilities found in the packet
(starting at the 'capability offset'). Each capability is described with
32 bits. The capabilities supported in the protocol are listed in Table 3.

#### Table 3

|Capability   |                                                       |
|-------------|-------------------------------------------------------|
|0x1	      | Extended bus accesses format support                  |
|0x2	      | Byte enable support                                   |
|0x3	      | Posted wire update support                            |
|0x4	      | Address translation services support                  |

# 5 READ packet

A read transaction over the Remote-Port is performed using two READ
packets, a READ request packet containing the transaction attributes and a
READ response packet containing the read data as payload. The read
data payload is placed immediately after the READ packet header in the
response.


#### Picture 5 Read Transaction

```
Simulator 1                    Simulator 2
    |                              |
    |         Remote-Port          |
    |       +--------------+       |
    |-------| Read request |------>|
    |       +--------------+       |
    |                              |
    |       +--------------+       |
    |       |    Read      |       |
    |<------|  response    |-------|
    |       |..............|       |
    |       |  Read data   |       |
    |       +--------------+       |
```

#### Picture 6 The READ packet

```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |            command 3 (READ)          |
      +--------------------------------------+
      |             length                   |
      +--------------------------------------+
      |             id                       |   Base header
      +--------------------------------------+
      |             flags                    |
      +--------------------------------------+   ---------
      |            timestamp_63_32           |
      +--------------------------------------+   READ command packet
      |            timestamp_31_0            |   specific header.
      +--------------------------------------+
      |           attributes_63_32           |
      +--------------------------------------+
      |           attributes_31_0            |
      +--------------------------------------+
      |            address_63_32             |
      +--------------------------------------+
      |            address_31_0              |
      +--------------------------------------+
      |              length                  |
      +--------------------------------------+
      |              width                   |
      +--------------------------------------+
      |            streaming_width           |
      +----------------+---------------------+
                       |      master_id      |
                       +---------------------+   ---------
                     ....
      +--------------------------------------+
      |               data                   |   Data is only included in
      +--------------------------------------+   READ response packets
```

## 5.1 Base header fields

The 'command' field in the base header is '3' for READ (see table 1).

The READ request packet has the response flag unset in the 'flags' fields.
The READ response packet has the flag set.

The request's 'length' field specifies in bytes the length of the command
specific READ packet header. The response's 'length' field specifies in
bytes the length of the READ command specific packet header plus the data
read length.

The 'device' field contains the ID of the target Remote-Port device for the
READ request or response packet.

The 'ID' field in the READ request packet must be unique at the issuing
simulator side. The receiving simulator must respond with a READ response
packet containing the same ID as it's matching request packet.

## 5.2 READ command specific packet fields

The 64 bit 'timestamp' field is used for synchronizing the simulators
communicating over the Remote-Port. In the request it carries the current
time at the packet issuing simulator. In the response the timestamp
carries the current time of responding simulator (after the transaction
has been processed).

The 64 bit 'address' field contains the address to read from in the
transaction.

The 'length' field contains the number of bytes to read in the transaction.

The 'width' field contains the width of each beat in bytes. It should be
set to zero for unknown widths which will let the remote side choose.

The 'streaming_width' field is specified in bytes and must be a multiple
of 'width'. The address of the read transaction wraps at 'address' plus
'streaming_width' and starts repeating itself from 'address' again. For
incremental (normal) read accesses the 'streaming_width' should be set to
the same as the length field.

The 'master_id' contains an implementation specific id of the requester.

### 5.3 The attributes field

The 64 bit 'attributes' field carry flags listed in Table 4 and also the
transaction response status (see Table 5) in response packets.

#### Picture 7 attributes
```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |             reserved                 |  attributes[63:32]
      +--------------------------------------+
      |     reserved          | RS |  flags  |  attributes[31:0]
      +--------------------------------------+
bit                           |3  0|
```

#### Table 4 Attribute flags (bits[7:0])

| Attribute flags |                        |
|-----------------|------------------------|
|0x1	          | End of packet          |
|0x2	          | Secure                 |
|0x4	          | Extended packet format |
|0x8	          | Physical address       |

The 'End of packet' flag signals the end of packet when modeling stream
channels. The 'Secure' flag marks the transaction as secure and otherwise
it is a non-secure transaction in the context of AMBA TrustZone. The
'Extended packet format' flag marks the packet to have the Extended packet
format (see below). The 'Physical address' flag is used when the address
in the transaction is a physical address that do not need a virtual to
physical translation.

#### Table 5 Response statuses (RS) (bits[11:8])

| RS |                      |
|----|----------------------|
|0x0 | Ok                   |
|0x1 | Bus generic error    |
|0x2 | Address decode error |

## 5.4 Extended READ packet

When both simulators communicating over the Remote-Port advertise support
for the 'Extended bus access format' capability (in the HELLO packets) the
READ packet contains additional fields if the 'Extended packet format'
flag (see Table 4) is set in the 'attributes' field.

#### Picture 8 The extended READ packet
```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |            command 3 (READ)          |
      +--------------------------------------+
      |             length                   |
      +--------------------------------------+
      |             id                       |   Base header
      +--------------------------------------+
      |             flags                    |
      +--------------------------------------+   ---------
      |            timestamp_63_32           |
      +--------------------------------------+   READ command packet
      |            timestamp_31_0            |   specific header.
      +--------------------------------------+
      |           attributes_63_32           |
      +--------------------------------------+
      |           attributes_31_0            |
      +--------------------------------------+
      |            address_63_32             |
      +--------------------------------------+
      |            address_31_0              |
      +--------------------------------------+
      |              length                  |
      +--------------------------------------+
      |              width                   |
      +--------------------------------------+
      |            streaming_width           |
      +------------------+-------------------+   --------
      |  master_id_31_16 |    master_id      |   Extended READ packet fields.
      +------------------+-------------------+
      |            master_id_63_62           |
      +--------------------------------------+
      |             data_offset              |
      +--------------------------------------+
      |             next_offset              |
      +--------------------------------------+
      |          byte_enable_offset          |
      +--------------------------------------+
      |          byte_enable_length          |
      +--------------------------------------+   --------
                     ....
      +--------------------------------------+
      |               data                   |   Data is only included in
      +--------------------------------------+   READ response packets
                     ....
      +--------------------------------------+
      |             byte enables             |   Byte enables if included
      +--------------------------------------+   in the packet
                     ....
```


The first two fields of the extended header, 'master_id_31_16' and
'master_id_63_32', extends the 'master_id' field to 64 bits.

The 'data_offset' field contains the offset in the packet to the first
payload data byte. The 'next_offset' field contains the offset to the next
header extension and 0 if there are no more extensions in the packet (this
is for future usage, the current version of the Remote-Port protocol has
not specified any extensions yet).

The 'byte_enable_offset' field contains the offset to the first byte
enable byte. The 'byte_enable_len' field contains the number of byte enable
bytes found starting at the 'byte_enable_offset'. If no byte enables are
included in the packet both fields must contain 0. Also it is required
that both simulator sides have advertised support for byte enables through
the 'Byte enables' capability for allow usage of byte enables.

# 6 WRITE packet

A WRITE transaction over the Remote-Port is performed using two WRITE
packets, a WRITE request packet (containing the transaction attributes and
including the write data as payload) and a WRITE response packet.

#### Picture 9 Write Transaction

```
Simulator 1                    Simulator 2
    |                              |
    |         Remote-Port          |
    |      +----------------+      |
    |      |     Write      |      |
    |------|    request     |----->|
    |      |................|      |
    |      |   Write data   |      |
    |      +----------------+      |
    |                              |
    |      +----------------+      |
    |<-----| Write response |------|
    |      +----------------+      |
    |                              |
```

#### Picture 10 The WRITE packet
```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |            command 4 (WRITE)         |
      +--------------------------------------+
      |             length                   |
      +--------------------------------------+
      |             id                       |   Base header
      +--------------------------------------+
      |             flags                    |
      +--------------------------------------+   ---------
      |            timestamp_63_32           |
      +--------------------------------------+   WRITE command packet
      |            timestamp_31_0            |   specific header.
      +--------------------------------------+
      |           attributes_63_32           |
      +--------------------------------------+
      |           attributes_31_0            |
      +--------------------------------------+
      |            address_63_32             |
      +--------------------------------------+
      |            address_31_0              |
      +--------------------------------------+
      |              length                  |
      +--------------------------------------+
      |              width                   |
      +--------------------------------------+
      |            streaming_width           |
      +------------------+-------------------+
                         |      master_id    |
                         +-------------------+   ---------
                     ....
      +--------------------------------------+
      |               data                   |   Write data payload is only
      +--------------------------------------+   included in WRITE request
                                                 packets.
```

## 6.1 Base header fields

The 'command' field in the base header is '4' for WRITE (see table 1).

The WRITE request packet has the response flag unset in the 'flags'
field. The WRITE response packet has the flag set.

The WRITE request's 'length' field specifies in bytes the length of the
WRITE command specific packet header plus the length of the write data
(payload). The WRITE response's 'length' field specifies in bytes the
WRITE packet header (responses do not contain payload data).

The 'device' field contains the ID of the target Remote-Port device for the
WRITE request or response.

The 'ID' field in the WRITE request packet must be unique at the issuing
simulator side. The receiving simulator must respond with a WRITE response
packet containing the same ID as it's matching request packet.

## 6.2 WRITE command specific packet fields

The 64 bit 'timestamp' field is used for synchronizing the simulators
communicating over the Remote-Port. In the request it carries the current
time at the packet issuing simulator. In the response the timestamp
carries the current time of responding simulator (after the transaction
has been processed).

The 64 bit 'address' field contains the address to write to in the
transaction.

The 'length' field contains the number of bytes to be written in the
transaction.

The 'width' field contains the width of each beat in bytes. It should be
set to zero for unknown widths which will let the remote side choose.

The 'streaming_width' field is specified in bytes and must be a multiple
of 'width'. The address of the read transaction wraps at 'address' plus
'streaming_width' and starts repeating itself from 'address' again. For
incremental (normal) read accesses the 'streaming_width' should be set to
the same as the length field.

The 'master_id' contains an implementation specific id of the requester.

The 64 bit 'attributes' field carry the flags listed in Table 4 and also
the transaction response status (see Table 5) in response packets.

## 6.3 Extended WRITE packet

When both simulators communicating over the Remote-Port advertise support
for the 'Extended bus access format' capability (in the HELLO packets) the
WRITE packet contains additional fields if the 'Extended packet format'
flag (see Table 4) is set in the 'attributes' field. The additional fields
are interpreted identically as for equivalent fields of the Extended READ
packet (see above).

#### Picture 11 Extended WRITE packet
```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |            command 4 (WRITE)         |
      +--------------------------------------+
      |             length                   |
      +--------------------------------------+
      |             id                       |   Base header
      +--------------------------------------+
      |             flags                    |
      +--------------------------------------+   ---------
      |            timestamp_63_32           |
      +--------------------------------------+   WRITE command packet
      |            timestamp_31_0            |   specific header.
      +--------------------------------------+
      |           attributes_63_32           |
      +--------------------------------------+
      |           attributes_31_0            |
      +--------------------------------------+
      |            address_63_32             |
      +--------------------------------------+
      |            address_31_0              |
      +--------------------------------------+
      |              length                  |
      +--------------------------------------+
      |              width                   |
      +--------------------------------------+
      |            streaming_width           |
      +------------------+-------------------+   --------
      | master_id_31_16  |    master_id      |   Extended WRITE packet fields.
      +------------------+-------------------+
      |            master_id_63_62           |
      +--------------------------------------+
      |             data_offset              |
      +--------------------------------------+
      |             next_offset              |
      +--------------------------------------+
      |          byte_enable_offset          |
      +--------------------------------------+
      |          byte_enable_length          |
      +--------------------------------------+   --------
                     ....
      +--------------------------------------+
      |               data                   |   Data is only included in
      +--------------------------------------+   WRITE request packets
                     ....
      +--------------------------------------+
      |             byte enables             |   Byte enables if included
      +--------------------------------------+   in the packet
                     ....
```


# 7 INTERRUPT packet

INTERRUPT packets are for requesting wire (line) updates at the peer
simulator. INTERRUPT packets by default are posted (no response packet
should be transmitted). If both simulators in the communication have
advertised the 'Posted wire update support' capability in the HELLO
packet, the 'Posted packet' flag (see Table 2) of the INTERRUPT packet
must be respected. This means that if the INTERRUPT packet has the flag
unset the receiver side must reply with an INTERRUPT response packet. If
the INTERRUPT packet has the flags set no response packet is required.

#### Picture 12 INTERRUPT Request
```
Simulator 1                Simulator 2
    |                          |
    |       Remote-Port        |
    |     +------------+       |
    |-----|  INTERRUPT |------>|
    |     |  Request   |       |
    |     +------------+       |
    |                          |
    |     +------------+       |
    |     |  INTERRUPT |       |
    |<----|  response  |-------|
    |     +------------+       |
         (When not posted)
```

#### Picture 13 INTERRUPT packet
```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |            command 5 (INTERRUPT)     |
      +--------------------------------------+
      |             length                   |
      +--------------------------------------+
      |             id                       |   Base header
      +--------------------------------------+
      |             flags                    |
      +--------------------------------------+   ---------
      |            timestamp_63_32           |
      +--------------------------------------+   INTERRUPT command packet
      |            timestamp_31_0            |   specific header.
      +--------------------------------------+
      |             vector_63_32             |
      +--------------------------------------+
      |             vector_31_0              |
      +--------------------------------------+
      |              line                    |
      +--------------------------------------+
                                   |  value  |
                                   +---------+
bit                                |7       0|
```

## 7.1 Base header fields

The 'command' field in the base header is '5' for INTERRUPT (see table 1).

The INTERRUPT request packet has the response flag unset in the 'flags'
field. The INTERRUPT response packet has the flag set.

The 'length' field specifies in bytes the length of the INTERRUPT command
specific packet header both in the request and in the response packet.

The 'device' field contains the ID of the target Remote-Port device for the
INTERRUPT request or response packet.

The 'ID' field in the INTERRUPT request packet must be unique at the
issuing simulator side. The receiving simulator must respond with an
INTERRUPT response packet containing the same ID as it's matching request
packet.

## 7.2 INTERRUPT command specific packet fields

The 64 bit 'timestamp' field is used for synchronizing the simulators
communicating over the Remote-Port. In the request it carries the current
time at the packet issuing simulator. In the response the timestamp
carries the current time of responding simulator (after the command has
been processed).

The 64 bit 'vector' field carries the ID of the target vector of lines
containing the line to toggle.

The 'line' field specify the line in the vector to toggle.

The 'value' field carries the new state of the line.

# 8 SYNC packet

The SYNC packet's purpose is to carry a timestamp with the current
simulation time that is used for synchronizing the simulators on both ends
of the communication.

#### Picture 14 SYNC handshake
```
Simulator 1                Simulator 2
    |                          |
    |       Remote-Port        |
    |     +------------+       |
    |-----|  SYNC      |------>|
    |     |  Request   |       |
    |     +------------+       |
    |                          |
    |     +------------+       |
    |     |  SYNC      |       |
    |<----|  response  |-------|
    |     +------------+       |
```

#### Picture 15 SYNC packet
```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |            command 6 (SYNC)          |
      +--------------------------------------+
      |             length                   |
      +--------------------------------------+
      |             id                       |   Base header
      +--------------------------------------+
      |             flags                    |
      +--------------------------------------+   ---------
      |            timestamp_63_32           |
      +--------------------------------------+   SYNC command
      |            timestamp_31_0            |   specific header.
      +--------------------------------------+
```

## 8.1 Base header fields

The 'command' field in the base header is '6' for SYNC (see table 1).

The SYNC request packet has the response flag unset in the 'flags'
field. The SYNC response packet has the flag set.

The 'length' field specifies in bytes the length of the SYNC command
specific packet header both in the request and in the response packet.

The 'device' field contains the ID of the target Remote-Port device for
the SYNC request or response packet.

The 'ID' field in the SYNC request packet must be unique at the issuing
simulator side. The receiving simulator must respond with a SYNC response
packet containing the same ID as it's matching request packet.

## 8.2 SYNC command specific packet fields

The 64 bit 'timestamp' field is used for synchronizing the simulators
communicating over the Remote-Port and carries the current time at the
packet issuing simulator.

# 9 ATS REQUEST packet

ATS REQUEST packets are used for requesting virtual to physical address
translations from a simulator. ATS REQUEST packets are only allowed to be used
when the simulators at both ends have advertised the 'Address translation
services' capability in the HELLO packet exchange. If an ATS REQUEST succeeds
the requesting simulator obtains the physical addresses for a range of virtual
addresses starting at the requested virtual address. Remote-Port READ and WRITE
transactions using already translated physical addresses must set the 'Physical
address' flag in the attributes.


#### Picture 16 ATS REQUEST
```
Simulator 1                Simulator 2
    |                          |
    |       Remote-Port        |
    |     +--------------+     |
    |-----|  ATS REQUEST |---->|
    |     |  REQUEST     |     |
    |     +--------------+     |
    |                          |
    |     +--------------+     |
    |     |  ATS REQUEST |     |
    |<----|  response    |-----|
    |     +--------------+     |
    |                          |
    |     +--------------+     |  If the READ request uses an
    |-----| READ request |---->|  already translated physical
    |     +--------------+     |  address it must have the
               ...                'Physical address' flag set.
```

#### Picture 17 ATS REQUEST packet
```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |            command 7 (ATS REQUEST)   |
      +--------------------------------------+
      |             length                   |
      +--------------------------------------+
      |             id                       |   Base header
      +--------------------------------------+
      |             flags                    |
      +--------------------------------------+   ---------
      |            timestamp_63_32           |
      +--------------------------------------+   ATS REQUEST command
      |            timestamp_31_0            |   specific header.
      +--------------------------------------+
      |           attributes_63_32           |
      +--------------------------------------+
      |           attributes_31_0            |
      +--------------------------------------+
      |            address_63_32             |
      +--------------------------------------+
      |            address_31_0              |
      +--------------------------------------+
      |            length_63_32              |
      +--------------------------------------+
      |            length_31_0               |
      +--------------------------------------+
      |              result                  |
      +--------------------------------------+
      |             reserved0                |
      +--------------------------------------+
      |             reserved1                |
      +--------------------------------------+
      |             reserved2                |
      +--------------------------------------+
      |             reserved3                |
      +--------------------------------------+
      |             reserved4                |
      +--------------------------------------+
      |             reserved5                |
      +--------------------------------------+
      |             reserved6                |
      +--------------------------------------+
      |             reserved7                |
      +--------------------------------------+
```

## 9.1 Base header fields

The 'command' field in the base header is '7' for ATS REQUEST (see table 1).

The ATS REQUEST packet has the response flag unset in the 'flags'
field. The ATS REQUEST response packet has the flag set.

The 'length' field specifies in bytes the length of the ATS REQUEST
command specific packet header both in the request and in the response
packet.

The 'device' field contains the ID of the target Remote-Port device for the
ATS REQUEST or ATS REQUEST response packet.

The 'ID' field in the ATS REQUEST request packet must be unique at the
issuing simulator side. The receiving simulator must respond with an ATS
REQUEST response packet containing the same ID as it's matching request
packet.

## 9.2 ATS REQUEST command specific packet fields

The 64 bit 'timestamp' field is used for synchronizing the simulators
communicating over the Remote-Port. In the request it carries the current
time at the packet issuing simulator. In the response the timestamp
carries the current time of responding simulator (after the command has
been processed).

The 64 bit 'attributes' field carries flags listed in Table 6. The flags
are or'ed in into the 'attributes' field when used simultaneously.

#### Table 6 ATS REQUEST attribute flags

|Flag |        |
|-----|--------|
|0x1  | Exec   |
|0x2  | Read   |
|0x4  | Write  |

In an ATS REQUEST packet the attributes field carries the requested
attributes of the memory region to translate (Exec, Read and Write). In an
ATS REQUEST response packet the attributes field carries the resulting
attributes after the address translation has been performed (that are valid for
the returned translated physical memory region).

The 64 bit 'address' field in an ATS REQUEST packet contains the virtual
address to translate. In the ATS REQUEST response packet the 'address'
field contains the translated physical address that corresponds to the
virtual address in the ATS REQUEST packet.

The 'length' field in ATS REQUEST packet is unused. In the ATS REQUEST
response packet the 'length' contains the size of the translated physical
region (starting from the physical 'address' in the response).

The 'result' field is unused in ATS REQUEST packets and must be 0. ATS
REQUEST response packets carry the translation result in the field. Table
7 lists valid values for the field.

#### Table 7 ATS result

|Result |       |
|-------|-------|
|0x0    | Ok    |
|0x1    | Error |

# 10 ATS INVALIDATE packet

ATS INVALIDATE packets are used for invalidating previously translated
address ranges obtained through ATS REQUEST packets. ATS INVALIDATE
packets are only allowed to be used when the simulators at both ends have
advertised the 'Address translation services' capability in the HELLO
packet exchange.


#### Picture 18 ATS INVALIDATE
```
Simulator 1                Simulator 2
    |                          |
    |       Remote-Port        |
    |    +----------------+    |
    |----| ATS INVALIDATE |--->|
    |    | request        |    |
    |    +----------------+    |
    |                          |
    |    +----------------+    |
    |<---| ATS INVALIDATE |----|
    |    | response       |    |
    |     +--------------+     |
```

#### Picture 19 ATS INVALIDATE packet
```
Octet |   +0   |   +1    |   +2    |   +3    |
bit   |7  ... 0|7  ...  0|7  ...  0|7  ...  0|
      +--------------------------------------+
      |           command 7 (ATS INVALIDATE) |
      +--------------------------------------+
      |             length                   |
      +--------------------------------------+
      |             id                       |   Base header
      +--------------------------------------+
      |             flags                    |
      +--------------------------------------+   ---------
      |            timestamp_63_32           |
      +--------------------------------------+   ATS INVALIDATE comm
      |            timestamp_31_0            |   specific header.
      +--------------------------------------+
      |           attributes_63_32           |
      +--------------------------------------+
      |           attributes_31_0            |
      +--------------------------------------+
      |            address_63_32             |
      +--------------------------------------+
      |            address_31_0              |
      +--------------------------------------+
      |            length_63_32              |
      +--------------------------------------+
      |            length_31_0               |
      +--------------------------------------+
      |              result                  |
      +--------------------------------------+
      |             reserved0                |
      +--------------------------------------+
      |             reserved1                |
      +--------------------------------------+
      |             reserved2                |
      +--------------------------------------+
      |             reserved3                |
      +--------------------------------------+
      |             reserved4                |
      +--------------------------------------+
      |             reserved5                |
      +--------------------------------------+
      |             reserved6                |
      +--------------------------------------+
      |             reserved7                |
      +--------------------------------------+
```

## 10.1 Base header fields

The 'command' field in the base header is '8' for ATS INVALIDATE (see table 1).

The ATS INVALIDATE packet has the response flag unset in the 'flags'
field. The ATS INVALIDATE response packet has the flag set.

The 'length' field specifies in bytes the length of the ATS INVALIDATE
command specific packet header both in the request and in the response
packet.

The 'device' field contains the ID of the target Remote-Port device for the
ATS INVALIDATE request or response packet.

The 'ID' field in the ATS INVALIDATE request packet must be unique at the
issuing simulator side. The receiving simulator must respond with an ATS
INVALIDATE response packet containing the same ID as it's matching request
packet.

## 10.2 ATS INVALIDATE command specific packet fields

The 64 bit 'timestamp' field is used for synchronizing the simulators
communicating over the Remote-Port. In the request it carries the current
time at the packet issuing simulator. In the response the timestamp
carries the current time of responding simulator (after the command has
been processed).

The attributes field in the ATS INVALIDATE packet is unused and must be 0.

The 64 bit 'address' field in an ATS INVALIDATE request packet contains
the virtual (untranslated) address of the region to invalidate. The
'address' field is unused in the response packet.

The 'length' field in the ATS INVALIDATE request packet contains the
length of the region to invalidate in bytes. The field is unused in the
response packet.

The 'result' field is unused in ATS INVALIDATE request packet and must be
0. ATS INVALIDATE response packets carry the result of the invalidation in
the field (see Table 7 for valid 'result' values).

# 11 CFG packet

CFG packets are for future usage an intended for negotiating
configuration options. The current version of the Remote-Port protocol has
not specified any CFG packets.

# References

[1] libsystemctlm-soc, [https://github.com/Xilinx/libsystemctlm-soc](https://github.com/Xilinx/libsystemctlm-soc)

[2] Xilinx/QEMU, [https://github.com/Xilinx/qemu](https://github.com/Xilinx/qemu)
