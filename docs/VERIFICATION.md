# Verification Plan and Evidence

## Recorded evidence

The following Vivado 2026.1 XSim behavioral simulation passes were reported by the user:

- **SHA-256 compression:** `sha256_compress_tb` passed the padded `abc` known-answer test with digest `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`.
- **SHA256d header:** `sha256d_header_tb` passed its 80-byte header/nonce vector with digest `1b66432a604a4e02b273ebf91734407740e08a4e70a4548da2baad31b51b2c38`.
- **Mining controller:** user reported its testbench passed. The testbench checks immediate match and nonce-range exhaustion.
- **UART loopback:** `uart_loopback_tb` passed with byte `a5` received and no fatal error.
- **UART mining integration:** user reported `uart_miner_tb` passed. The test sends a work packet and checks the status, nonce, and SHA256d digest response.

These are behavioral simulation results, not board-level validation. The integrated bitstream was generated and the FPGA configuration completed with `End of startup status: HIGH`. A physical UART work-packet exchange has not yet been retained as evidence.

## Rolling-schedule regression

On 2026-11-18, the compression core was changed from a 64-word, load-time schedule expansion to a 16-word rolling schedule. The local XSim regression passed SHA-256 empty-message and `abc` vectors, the SHA256d 80-byte header vector, mining-controller checks, UART loopback, and the complete UART work-packet flow. Exact test names and outputs are recorded in `reports/ROLLING-SCHEDULE-REGRESSION-2026-11-18.md`.

The rolling-schedule revision (EXP-001) routed at WNS −5.001 ns; that figure is superseded by EXP-002 (WNS +1.441 ns). The −84.022 ns figure belongs only to the original 64-word schedule.

## EXP-002 regression

After the shift-register restructuring and the UART hardening, the following passed in Vivado XSim 2026.1 (command-line `xvlog`/`xelab`/`xsim`, run 2026-11-18): SHA-256 empty and `abc` vectors; the SHA256d header vector `1b66432a…2c38`; mining-controller immediate match and exhaustion; UART loopback `a5`; the 37-byte UART work-packet response; a truncated packet producing exactly one `0xEE` byte; and a valid packet accepted after that timeout. The routed implementation of the same RTL is timing-clean (`reports/TIMING-CLOSURE-2026-11-18.md`).

The direct SHA-256 vectors use only the standard IV. Non-IV chaining states are exercised only through the SHA256d header test; add random-state vectors against `python/sha256_compress_ref.py` before publication.

## Display regression

After adding the front-panel display (2026-11-18), all XSim testbenches passed. New: `display_tb` checks `bin2bcd` against known values (0, 7, 1234, 493210, 12345678, 99999999), scans all eight digits of `seven_seg_driver` against an independent segment table in hex and decimal-blanking modes, and checks `perf_monitor` rate, hash count, elapsed time, rate hold, and clear-on-start. `uart_miner_tb` checks the display values after a one-nonce search. Routed WNS is +1.129 ns. The display and switches have not yet been verified on the board.

## Board-level evidence

On 2026-11-18, `uart_miner_timing_clean.bit` (routed WNS +1.441 ns) was programmed onto a Nexys A7-100T. Reported by the user from `python/uart_miner_host.py` on COM7 (115200 baud), with the header bytes `00..4f`, an all-`ff` target, and nonce range `0x2a` to `0x2a`: the board returned `FOUND nonce=0x0000002a` and digest `86bef4c1c6dd1f3a6c456465f26af381e57fc3a8670c066979a37584306802e1`. This matches the XSim result and an independent Python `hashlib` double SHA-256 of the same header. Terminal output was pasted by the user and is not retained as a log file. Hash rate has not been measured.

## Planned checks

- **Reference model:** independent Python SHA-256d/header reference and explicit serialization helpers.
- **SHA-256 unit checks:** additional vectors, block-boundary padding cases, and endian-sensitive cases.
- **SHA256d checks:** nonce variation, midstate equivalence, and final digest byte order.
- **Comparator/controller checks:** target below/equal/above, reset, nonce progression, exhaustion, stop, and restart.
- **UART checks:** malformed packets, framing errors, payload boundaries, and host/FPGA transactions at the board's actual baud rate.
- **Implementation checks:** Vivado synthesis, timing/resource reports, then board-level UART and mining smoke tests. The initial routed report fails the 100 MHz setup constraint and is recorded in `reports/BASELINE-2026-11-18.md`.

Record tool version, procedure, input, expected and observed output for each future test. User-reported results are labeled as such until logs are retained in the project.
