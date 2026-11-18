# Proposed Architecture

## Current implementation

- The Vivado project targets `xc7a100tcsg324-1`, the Nexys A7-100T device.
- `uart_miner` is the integrated top-level design. It uses the 100 MHz oscillator, the USB-UART pins, the centre button as reset, and two LEDs for busy/found status.
- The host packet and response format are defined in `UART-PROTOCOL.md`.
- The first integrated implementation (baseline) failed 100 MHz setup timing by 84.022 ns; see `reports/BASELINE-2026-11-18.md`. The current revision meets timing with +1.441 ns slack; see `reports/TIMING-CLOSURE-2026-11-18.md`.
- `sha256_compress` runs 65 cycles per block: 64 rounds plus a finalization cycle. It uses a 16-word shift-register schedule and a pre-registered `h+K+W` term.

- Front panel: `perf_monitor` counts hashes per 1 s window, hashes per search, and search time in microseconds. `bin2bcd` and `seven_seg_driver` show one of four values chosen by SW1 and SW0 on the eight-digit display (see the README table).

## Design decisions (proposal)

The system is divided into a Python host and FPGA datapath/control:

1. **Python host controller** prepares an 80-byte header, sends a work packet, and receives status, candidate nonce, and digest. `python/uart_miner_host.py` implements the packet exchange.
2. **USB-UART communication** uses 115200 baud, 8-N-1. The request begins with `W`, then carries header, target, and inclusive nonce range.
3. **Header buffer** is the `work_header` register in `uart_miner`. It remains stable while `mining_core` searches.
4. **SHA-256 midstate calculation** is currently performed as the first compression pass of every candidate. Midstate reuse is deliberately deferred until the timing-clean compression engine exists.
5. **SHA256d hashing engine** computes the three compression passes needed for an 80-byte header. Its functional vector passed in XSim.
6. **Nonce generator** is sequential and searches an inclusive range.
7. **256-bit target comparator** implements an unsigned, inclusive `digest <= target` comparison in raw SHA-256 output order.
8. **Mining controller** launches the hash engine, consumes completion, advances the nonce, and captures a matching nonce/digest.

Conceptual flow: host prepares work → UART loads header/target → header buffer and midstate become ready → controller issues nonces → SHA256d engine hashes → target comparator checks each digest → controller reports a match or search status.

## Open questions

- Throughput has not been measured on hardware.
- The reset button is synchronized but not debounced.
- The UART packet has no checksum or escaping; a stalled packet times out with a `0xEE` reply.
- Work loading currently accepts only one request while idle. Stop, cancellation, nonce wrap, and restart semantics need specification.
- A Bitcoin network integration, block-template parsing, and byte-order conversion for real work are outside this baseline.
