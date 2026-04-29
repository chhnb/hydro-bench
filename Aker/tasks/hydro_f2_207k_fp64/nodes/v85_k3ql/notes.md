# v85_k3ql

Parent: v75_k1args

## Change

This node starts from v75_k1args and reuses the owner normal velocity already stored in QL[1] when CalculateKlas3 forms QZH3.

The parent loaded sides.COSF[idx] and sides.SINF[idx] and recomputed U_pre * cos + V_pre * sin in CalculateKlas3. This node removes those geometry reload locals and changes QZH3 to QL[1] * H_pre * side_val.

No table lookup, helper dispatch, branch condition, flux store, UpdateCellKernel code, launch wrapper, or memory address is otherwise changed.

## Correctness

At the KLAS3 call site, U_pre and V_pre are the same owner-cell velocity values used by CalculateFluxKernel to compute QL[1], and BOUNDA has not modified QL[1] before dispatching KLAS3. The side-normal geometry arrays are not written by CalculateFluxKernel.

Reusing QL[1] therefore supplies the same rounded Real projection value that the parent recomputed. QZH3 keeps the same projection * H_pre * side_val multiply order after that value, so the frozen native CUDA trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39747
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23525
