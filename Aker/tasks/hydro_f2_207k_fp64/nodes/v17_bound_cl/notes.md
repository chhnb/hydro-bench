# v17_bound_cl

Parent: v16_osher_cl

## Change

This node starts from v16_osher_cl and reuses the wave speed already computed in CalculateFluxKernel for the boundary helper.

CalculateFluxKernel computes CL = sqrt(9.81 * H1) before deciding whether the side enters BOUNDA. The parent BOUNDA helper receives H1 as H_pre and recomputes sqrt(9.81 * H_pre) only for the supercritical boundary check. This node passes the existing CL into BOUNDA as an additional Real argument and removes the redundant helper-local square root.

No boundary helper dispatch order, flux expression, launch wrapper, or state update is otherwise changed.

## Correctness

The passed CL is produced by the exact expression used by the parent helper, with H_pre equal to the caller value H1. There is no write to cells.H[pos] or to the local H1 value between the caller computation and the helper call.

All floating-point flux expressions keep the same operands and order. The only removed operation is a duplicate square root used for the existing QL[1] > CL branch comparison, so the baseline trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=40891
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=24235

## Host validation
- host validation: existing OK reports reused
