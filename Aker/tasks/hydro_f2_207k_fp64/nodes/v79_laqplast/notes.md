# v79_laqplast

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and caches the LAQP high-row index used by KLAS3 boundary interpolation.

The parent computes MS - 1 once for the upper endpoint test and again as the loop bound on every bracket-loop predicate. This node introduces int last = MS - 1 after the low-end check, uses A[last] and B[last] for the high-end return path, and uses last as the loop bound.

No KLAS3 row-offset logic, helper dispatch, table values, interpolation arithmetic, UpdateCellKernel code, launch wrapper, or floating-point operation order is otherwise changed.

## Correctness

The new last variable is exactly the same integer expression previously used in A[MS - 1], B[MS - 1], and i < MS - 1. LAQP still returns before last is formed when MS <= 0, so the valid-index domain matches the parent.

The same QW/ZW table elements are read, and the interpolation expression keeps the same operands and order. This is only integer index and loop-bound reuse, so it should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=40032
- test_perf: status=OK rc=0 queue_wait_ms=39066 run_ms=23600
