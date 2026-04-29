# v71_k6dz

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and caches the signed depth delta in the fully-wet branch of CalculataKlas6.

The parent computes Z_pre - ZC once inside fabs, then recomputes the same subtraction for the copysign calls and for the two downstream flux products in the Z_pre > ZC sub-branch. This node introduces Real DZ_signed = Z_pre - ZC, computes DZ as fabs(DZ_signed), and reuses DZ_signed in those same sign and flux expressions.

No helper dispatch, side-geometry loads, KLAS3 row-offset logic, OSHER logic, UpdateCellKernel code, launch wrapper, or floating-point multiplication order is otherwise changed.

## Correctness

DZ_signed is exactly the Real result of the original Z_pre - ZC subtraction in the same KLAS6 branch. Replacing repeated uses of that subtraction with the cached scalar keeps the copysign sign source identical and keeps the FLR(1) and FLR(2) multiplication order as signed_delta * fabs(UN) * velocity.

The branch predicates are left as their original Z_pre/ZC comparisons, and all downstream flux calculations outside the repeated subtraction are unchanged. This should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39546
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23508
