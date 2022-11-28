# Xilinx HSC - SystemC/TLM-2.0 model

## Introduction

The Xilinx High Speed Crypto (HSC) device is a high-performance, adaptable
encryption integrated hard IP.  You can find more information about it in
[PG372].

## Model

This model emulates the HSC bloc with 4 encoders and 4 decoders.

### Accuracy

This is a functional LT TLM-2.0 model.  It is not cycle accurate, the time it
takes to encode or decode packets is not representative.

### Limitations

Only the MACSec encryption is emulated with fixed port, and for simplicity the
AES algorithms are replaced and emulated by XOR'ing the datas with the keys.

### Ports

| Port                          | Description                                                |
|-------------------------------|------------------------------------------------------------|
| user_if_socket                | APB memory-mapped interface for configuration and status.  |
| plain_data_stream_inputs      | AXI4-S inputs (4 sockets) for encryption                   |
| encrypted_data_stream_outputs | AXI4-S encrypted outputs (4 sockets)                       |
| encrypted_data_stream_inputs  | AXI4-S inputs (4 sockets) for decryption                   |
| plain_data_stream_outputs     | AXI4-S decrypted outputs (4 sockets)                       |
| rst                           | Reset signal                                               |
| enc_igr_prtif_*               | Signal for the encoder ingress see in [PG372] for details. |
| dec_igr_prtif_*               | Signal for the decoder ingress see in [PG372] for details. |

### AXI4-Stream interfaces

The AXI4-Stream interfaces are modelled as TLM sockets using libsystemctlm-soc's
generic attributes to signal AXI4-Stream's TLAST signal as EOP.  See [genattr].

References:  
[PG372]: https://www.xilinx.com/content/dam/xilinx/support/documents/ip_documentation/hsc/v1_0/pg372-hsc.pdf  
[genattr]: https://github.com/Xilinx/libsystemctlm-soc/blob/master/tlm-extensions/genattr.h  
