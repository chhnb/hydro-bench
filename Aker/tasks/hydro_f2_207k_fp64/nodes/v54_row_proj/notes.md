# v54_row_proj

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and reuses the owner normal velocity already stored in QL[1] when CalculateKlas3 forms QZH3. The parent reloaded sides.COSF[idx] and sides.SINF[idx] and recomputed U_pre * cos + V_pre * sin before multiplying by H_pre and sides.SIDE[idx]. This node removes those two KLAS3 geometry locals and changes QZH3 to QL[1] * H_pre * side_val.

The v42 row_offset cache for QW_row and ZW_row, the side length load, QZH3 clamp, LAQP lookup, helper dispatch, flux stores, UpdateCellKernel, and launch wrappers are otherwise unchanged.

## Correctness

At the KLAS3 call site, U_pre and V_pre are the same owner-cell velocity values used to compute QL[1], and BOUNDA has not modified QL[1] before calling CalculateKlas3. The side-normal geometry arrays are not written by CalculateFluxKernel. Reusing QL[1] therefore supplies the same rounded Real projection value that the parent recomputed, and QZH3 keeps the same projection * H_pre * side_val multiply order after that value.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39741
- test_perf: status=OK rc=0 queue_wait_ms=39287 run_ms=23449
