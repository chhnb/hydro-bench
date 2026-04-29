# v63_laqploads

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and caches the LAQP interpolation table values used inside the per-row bracket loop.

The parent tests X against A[i] and A[i + 1], then reloads those same A entries and B[i] when computing the interpolated Y value. This node introduces local Ai, Aip1, and Bi scalars for the matched loop iteration and reuses them in the same interpolation expression.

No KLAS3 row-offset logic, helper dispatch, flux expression outside LAQP, UpdateCellKernel code, launch wrapper, or floating-point operation order is otherwise changed.

## Correctness

Ai, Aip1, and Bi are loaded from the exact same table addresses that the parent reads in the same loop iteration. The branch condition uses the same A values, and the interpolation keeps the same arithmetic tree with the cached scalars substituted for repeated loads.

The boundary lookup row pointers and all downstream flux calculations remain unchanged, so this should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39676
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23440
