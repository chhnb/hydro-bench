# v87_habsql

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and caches a repeated floating-point prefix in one CalculateFluxKernel nonboundary branch.

In the ZC <= cells.ZBC[pos] branch, the parent wrote FLUX1 and FLUX2 with the repeated left-associated prefix H1 * fabs(QL[1]):

- H1 * fabs(QL[1]) * QL[1]
- H1 * fabs(QL[1]) * QL[2]

This node introduces a local Real H_abs_ql = H1 * fabs(QL[1]) and uses H_abs_ql * QL[1] and H_abs_ql * QL[2] in the existing FLUX_VAL call.

No branch predicates, helper calls, flux store targets, UpdateCellKernel code, launch wrappers, or other expressions are changed.

## Correctness

The cached H_abs_ql value is exactly the first multiply that the parent evaluated independently for both FLUX1 and FLUX2. Each final flux expression keeps the same multiplication order after that prefix: the cached prefix is multiplied by QL[1] for FLUX1 and by QL[2] for FLUX2.

Because H1 and QL[1] are unchanged throughout this branch, reusing the rounded prefix should preserve the frozen native CUDA baseline trajectory bit-exactly while removing duplicate fabs/multiply work.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39379
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23432
