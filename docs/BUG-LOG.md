# Issue Log

| ID | Date | Description | Evidence | Status | Resolution |
|---|---|---|---|---|---|
| TIM-001 | 2026-11-18 | Baseline `sha256_compress` expanded schedule words 16 to 63 during block load, producing a 166-level critical path. | Routed timing report: WNS −84.022 ns; 93.943 ns worst data path to `w_reg[63][29]`. | Closed | Replaced by a rolling schedule (EXP-001, WNS −5.001 ns), then restructured (EXP-002). Routed WNS +1.441 ns at 100 MHz. |
| RST-001 | 2026-11-18 | `RESET` is an external push-button signal used directly by sequential logic. | Current `uart_miner` top-level RTL and XDC. | Closed (debounce deferred) | `uart_miner` now passes `RESET` through a two-flop synchronizer. A glitch on button release is harmless because reset is idempotent, so debounce was not added. |
| UART-001 | 2026-11-18 | A malformed or truncated work packet leaves the receiver in packet-collection state until reset. | Protocol and RTL have no timeout/error state. | Closed | A gap of `RX_TIMEOUT_CLKS` (default 10,000,000 clocks, 100 ms) abandons the packet and returns one `0xEE` byte. XSim covers the timeout and recovery by a following valid packet. |
| UART-002 | 2026-11-18 | `UART_RX` was sampled with no synchronizer. | Source inspection. | Closed | Added a two-flop synchronizer. |
| BUILD-001 | 2026-11-18 | `scripts/build_uart_miner.tcl` failed here: `get_files` with a path containing a space matched nothing, and the status check rejected Vivado's `route_design Complete, Failed Timing!` message. | Vivado batch log. | Closed | Files are matched by name and the status check accepts any `route_design Complete*` string. |
| BUILD-002 | 2026-11-18 | Vivado batch start from the project directory failed with `Failed to install all user apps` (Common 17-356). | `vivado.log` from the Codex session. | Mitigated | The same command succeeded when launched from a different working directory. Root cause not isolated. |
