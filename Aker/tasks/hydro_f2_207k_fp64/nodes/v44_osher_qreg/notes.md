# v44_osher_qreg

Parent: v27_ratio_reg

## Change

This node starts from v27_ratio_reg and caches the two normal-state scalars used by OSHER K1 classification. OSHER now loads QR[1] into qr_normal immediately after CR is computed, uses that register to form FIR, and reuses it in the K1 branch comparisons. It also loads QL[1] once into ql_normal before the K1 if/else chain and uses that register for the existing comparisons.

No QS dispatch order, switch structure, flux accumulation expression, CalculateFluxKernel path, UpdateCellKernel path, or launch wrapper is otherwise changed.

## Correctness

qr_normal and ql_normal are loaded from the same QR[1] and QL[1] elements that the parent read. OSHER does not modify QL or QR before K1 classification, and the comparisons still use the same operands with the same <, >=, and -CR expressions. FIR keeps the original QR[1] - 2 * CR operation order, with QR[1] supplied from the cached register, so the frozen native CUDA trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39841
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23593
