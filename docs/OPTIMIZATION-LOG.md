# Optimization Log

The first routed build is retained as the architectural baseline. It is not a performance result: the 100 MHz timing constraint fails by 84.022 ns.

| ID | Date | Change | Evidence | Result | Correctness evidence |
|---|---|---|---|---|---|
| BL-001 | 2026-11-18 | Integrated sequential SHA256d engine, UART work loader, nonce controller, and target comparator | Routed Vivado 2026.1 reports | 9,562 LUTs, 5,520 registers; WNS −84.022 ns at 100 MHz | XSim unit, integration, and UART tests passed; timing failure prevents a board performance claim |
| EXP-001 | 2026-11-18 | Replaced all-at-once schedule expansion with a 16-word rolling schedule | Routed Vivado 2026.1 reports | 3,025 LUTs, 3,989 registers; WNS −5.001 ns (worst path 14.893 ns, 17 levels) | SHA-256 empty/`abc`, SHA256d, mining controller, UART loopback, and UART work-packet tests passed |
| EXP-002 | 2026-11-18 | Shift-register schedule with fixed taps, pre-registered `h+K+W`, feed-forward add moved to its own cycle (65 cycles/block) | Routed Vivado 2026.1 reports; `reports/TIMING-CLOSURE-2026-11-18.md` | 2,151 LUTs, 4,041 registers; **WNS +1.441 ns, WHS +0.028 ns, 0 failing endpoints** | All XSim testbenches passed |
| FEAT-001 | 2026-11-18 | Added front-panel display (hash rate, nonce, time, hash count) and switch mode select | Routed Vivado 2026.1 reports | 2,325 LUTs, 4,351 registers; WNS +1.129 ns, WHS +0.022 ns, 0 failing endpoints | All XSim testbenches passed, including `display_tb` |

## Next experiment

Timing is clean at 100 MHz, so the design is now a valid baseline for board work. Next: program `reports/generated/uart_miner_timing_clean.bit`, retain a physical UART exchange, and measure hash rate. Then pursue the parallel-engine and midstate-reuse steps in `BUILD-PLAN.md`. The remaining critical path is the 256-bit digest comparator in `mining_core`.
