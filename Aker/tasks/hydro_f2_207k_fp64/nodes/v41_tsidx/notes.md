# v41_tsidx

Parent: v27_ratio_reg

## Change

This node starts from v27_ratio_reg and caches the boundary time-series row index in two KLAS helpers.

CalculateKlas10 now computes int time_idx = jt * mesh.CELL + pos once, then uses it for the paired QT and DQT loads. CalculateKlas1 does the same for the paired ZT and DZT loads.

The loaded arrays, helper dispatch, flux stores, and all floating-point formulas are otherwise unchanged.

## Correctness

The new time_idx value is exactly the integer expression that the parent used separately for each paired load. Reusing it addresses the same elements in QT/DQT and ZT/DZT.

No floating-point operation is reordered or removed; only duplicate integer index arithmetic is eliminated before the same global loads. The native CUDA trajectory should therefore remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39809
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23639
