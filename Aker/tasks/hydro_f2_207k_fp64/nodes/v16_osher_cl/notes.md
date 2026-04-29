# v16_osher_cl

Parent: v15_klas_arg

## Change

This node starts from `v15_klas_arg` and changes only the `OSHER` helper call contract inside `functors.cu`.

Both `CalculateFluxKernel` call sites already compute the wave speed used to form the incoming `FIL`: `CL = sqrt(9.81 * H1)` for the forward internal edge and `CL1 = sqrt(9.81 * HN)` for the reverse internal edge. The two `OSHER` calls now pass `CL` and `CL1` as the second argument. The `OSHER` definition keeps the same C++ type signature but names that second `Real` parameter `CL` and removes the internal `sqrt(9.81 * H_pre)` recomputation.

No flux expression, helper branch order, launch wrapper, or state update is otherwise changed.

## Correctness

The value passed to `OSHER` is the exact same expression the parent recomputed inside `OSHER`; it is already held in a local `Real` register before the call. The helper only uses this value for the existing `QL[1]` versus `CL` comparisons.

All other floating-point expressions keep the same operands and order. This change removes redundant square-root work but does not change the OSHER path selected for exact baseline alignment.

## Validation

Host-side broker validation is pending. `meta.json` intentionally sets `attempt_status` to `FAIL` and `failure_reason` to `pending host validation` until the Aker host writes `report_acc.json` and `report_perf.json`.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39894
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23839
