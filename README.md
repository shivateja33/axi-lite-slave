# axi-lite-slave
AXI-Lite Slave peripheral module with read/write support

# AXI-Lite Slave Peripheral (SystemVerilog)

This repository contains a SystemVerilog implementation of an AXI-Lite slave peripheral. It supports both **read** and **write** operations, with support for byte-level masking using `WSTRB` and properly synchronized AXI-Lite handshakes.

---

##  Features

-  Compliant AXI-Lite write path:
  - Separate handling of `AW` and `W` channels
  - Register address latching
  - Byte-enable support via `WSTRB`
  - Correct generation of `BVALID` and `BRESP`

- Compliant AXI-Lite read path:
  - Captures `ARADDR` and drives `RDATA`
  - Valid `RRESP` and `RVALID` signaling
  - Supports 32-bit registers with word alignment

-  Supports:
  - 3 user-defined registers: `reg0`, `reg1`, `reg2`
  - Word-aligned address decoding using bits `[4:2]`
