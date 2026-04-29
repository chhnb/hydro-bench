# v48_tsidx_row

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and caches the boundary time-series index in the two helpers that read paired time-dependent boundary arrays. CalculateKlas10 now computes int time_idx = jt * mesh.CELL + pos once and uses it for the QT and DQT loads. CalculateKlas1 computes the same local index once and uses it for the ZT and DZT loads.

The v42 KLAS3 row_offset change, helper dispatch, flux stores, UpdateCellKernel, and launch wrappers are otherwise unchanged.

## Correctness

time_idx is exactly the integer expression the parent used separately for each paired load. Reusing it addresses the same QT/DQT and ZT/DZT elements. No floating-point operation is reordered or removed; the same loaded values feed the same formulas in the same order, so the frozen native CUDA trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=40230
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=24060
