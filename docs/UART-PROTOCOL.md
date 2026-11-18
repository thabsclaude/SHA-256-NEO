# UART Work Packet Protocol

The FPGA UART uses 115200 baud, 8 data bits, no parity, and one stop bit (8-N-1). The host sends exactly one packet while the miner is idle:

| Field | Size | Encoding |
|---|---:|---|
| Command | 1 byte | ASCII `W` (`0x57`) |
| Header | 80 bytes | SHA input byte order; nonce bytes are replaced by the nonce field |
| Target | 32 bytes | unsigned big-endian 256-bit integer |
| Nonce start | 4 bytes | big-endian unsigned integer |
| Nonce end | 4 bytes | big-endian unsigned integer, inclusive |

The FPGA responds with exactly 37 bytes: status (`0x01` found, `0x00` exhausted), nonce (4-byte big-endian), then digest (32 bytes in SHA-256 output byte order). On exhaustion the nonce and digest fields are zero.

The receiver recognizes `W` only when idle. If more than 100 ms (`RX_TIMEOUT_CLKS`) passes between bytes of a packet, the FPGA discards the partial packet and sends a single error byte `0xEE`; the host may then send a new `W` packet without resetting. There is no checksum, escaping, or retransmission. The `RESET` button and `UART_RX` pin are synchronized to the 100 MHz clock inside the design.
