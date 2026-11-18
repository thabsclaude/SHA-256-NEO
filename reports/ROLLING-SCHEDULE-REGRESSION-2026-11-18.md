# Rolling-schedule regression: 2026-11-18

## Purpose

This regression validates the first timing-directed RTL change: replacing the 64-word combinational SHA-256 message schedule with a 16-word rolling schedule. The public interface and 64-round compression latency remain unchanged.

## Tool and procedure

The checks ran locally with Vivado XSim 2026.1 build 6511674. Each listed test was compiled, elaborated, and run to `$finish` through the XSim command-line tools on 2026-11-18.

| Testbench | Result | Observed evidence |
|---|---|---|
| `sha256_compress_tb` | Pass | SHA-256 of empty message and `abc` matched standard known-answer digests |
| `sha256d_header_tb` | Pass | 80-byte header/nonce SHA256d vector: `1b66432a604a4e02b273ebf91734407740e08a4e70a4548da2baad31b51b2c38` |
| `mining_core_tb` | Pass | Immediate target match and two-nonce exhaustion path passed |
| `uart_loopback_tb` | Pass | UART byte `a5` returned correctly |
| `uart_miner_tb` | Pass | 120-byte work packet and 37-byte result response passed |

## Interpretation

This confirms functional equivalence for the covered flows. It does not establish the new clock limit, resource use, board behavior, or a hash rate. Those require a routed Vivado implementation report for this exact RTL revision.

## Next measurement

Run `source scripts/build_uart_miner.tcl` inside the Vivado GUI. The script writes timing, utilization, and DRC reports to `reports/generated/`. If the routed WNS is negative, it exits without generating a new bitstream; record the failure before choosing the next architectural change.
