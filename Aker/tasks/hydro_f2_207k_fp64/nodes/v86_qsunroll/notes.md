# v86_qsunroll

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and unrolls the fixed four-component flux accumulation inside the OSHER QS helper.

Each active QS template arm still calls QF exactly as before, then applies the same updates in the same component order: FLUX_OSHER[0] through FLUX_OSHER[3], each with F[n] * j. The only source change is replacing the constant-trip-count for loop with those four explicit statements.

No OSHER switch dispatch, QF arithmetic, KLAS helper logic, CalculateFluxKernel branch order, UpdateCellKernel code, launch wrapper, or floating-point operation order is otherwise changed.

## Correctness

The parent loop always executes i = 0, 1, 2, 3 and performs FLUX_OSHER[i] += F[i] * j. The replacement statements perform the same four additions in the same order with the same F entries, same j value, and same destination elements.

Because no arithmetic tree, helper call order, or memory address changes, this should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=14878 run_ms=39675
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23488
