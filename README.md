# SHA-256 NEO

SHA-256 NEO is an educational FPGA proof-of-work demonstrator for the Digilent Nexys A7-100T. It accepts an 80-byte header, a target, and a nonce range over USB-UART, then evaluates sequential SHA256d candidates in FPGA fabric.

This repository records the design's measured history. The current revision is functionally verified in XSim and **meets the 100 MHz timing constraint** (routed WNS +1.441 ns) on `xc7a100tcsg324-1`. It has not yet been run on the board with a retained UART exchange, and no hash rate has been measured.

## Design at a glance

```text
Python host ── USB-UART ── uart_miner ── mining_core ── sha256d_header
                                                        └─ sha256_compress
```

The current datapath is sequential at the nonce level and performs three 64-round SHA-256 compression operations per candidate: the first header block, the padded second header block, and the second SHA-256 hash.

## Evidence and current limitation

The known-answer SHA-256, SHA256d header, mining-controller, UART loopback, UART work-packet, and UART timeout/recovery tests pass in Vivado XSim.

| Revision | WNS at 100 MHz | LUTs |
|---|---:|---:|
| Baseline (64-word schedule) | −84.022 ns | 9,562 |
| Rolling schedule | −5.001 ns | 3,025 |
| Shift-register schedule, pre-registered `h+K+W` | **+1.441 ns** | 2,151 |

See the [baseline report](reports/BASELINE-2026-11-18.md) and [timing-closure report](reports/TIMING-CLOSURE-2026-11-18.md).

## Repository layout

| Path | Purpose |
|---|---|
| `rtl/` | Synthesizable Verilog datapath, controller, and UART modules |
| `testbench/` | XSim behavioral testbenches |
| `constraints/` | Nexys A7-100T pin and clock constraints |
| `python/` | Independent compression reference and UART host program |
| `scripts/` | Reproducible Vivado batch-flow scripts |
| `reports/` | Published baseline and later measured results |
| `docs/` | Architecture, protocol, verification, issue, and optimization records |

## Reproduce the baseline

1. Open `FPGA Bitcoin Miner.xpr` in Vivado 2026.1.
2. Set `uart_miner` as the design top and enable `constraints/uart_miner.xdc`.
3. Disable `constraints/led_blinker.xdc` for this top-level design.
4. Run the behavioral testbenches listed in `docs/VERIFICATION.md`.
5. Run synthesis, implementation, and bitstream generation.
6. Preserve the timing summary and utilization report with the date, tool version, device, and commit ID.

Alternatively, run `vivado -mode batch -source scripts/build_uart_miner.tcl` from a directory other than the project folder. It writes reports to `reports/generated/` and writes `uart_miner_timing_clean.bit` only when setup timing is met.

Next: program the timing-clean bitstream, record a physical UART exchange, and measure hash rate.
