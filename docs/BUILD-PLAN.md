# Staged Build Plan

This is a proposed sequence. Completion is recorded only after implementation and evidence exist.

1. **Hardware bring-up**: confirm board/device, clock and reset, board constraints, and a minimal observable design. Record the board revision and Vivado results.
2. **SHA-256**: implement and verify one-block SHA-256 behavior against independent known-answer vectors, including padding and byte/word conventions.
3. **SHA256d**: implement the 80-byte Bitcoin header double hash, including midstate reuse and nonce substitution; compare against an independent software reference.
4. **Mining controller**: sequence work, nonce issuance, hash completion, comparator results, and stop/restart behavior.
5. **UART**: define and implement framed host communication; exercise loading work and collecting status/results.
6. **Parallel engines**: replicate or pipeline engines only after the single-engine behavior is established; measure resource use and throughput.
7. **Optimization**: profile timing, area, and throughput, then make measured changes and preserve correctness evidence.

## Current status

- Steps 1-5 are implemented and simulated (XSim); see `VERIFICATION.md`.
- Step 7 has begun: the single engine meets 100 MHz timing (WNS +1.441 ns); see `reports/TIMING-CLOSURE-2026-11-18.md`.
- Not done: board-level UART exchange and hash-rate measurement, midstate reuse, parallel engines (step 6), and comparator-path optimization.
