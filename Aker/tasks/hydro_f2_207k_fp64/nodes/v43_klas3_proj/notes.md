# v43_klas3_proj

Parent: v27_ratio_reg

## Change

This node starts from v27_ratio_reg and reuses the owner normal velocity already stored in QL[1] when CalculateKlas3 forms QZH3.

CalculateFluxKernel computes QL[1] as U1 * COSJ + V1 * SINJ before dispatching boundary helpers. The parent CalculateKlas3 reloaded sides.COSF[idx] and sides.SINF[idx] and recomputed the same U_pre * cos + V_pre * sin projection only to multiply by H_pre and sides.SIDE[idx].

This node removes the two KLAS3 geometry reload locals and changes QZH3 to QL[1] * H_pre * side_val. The side length load, QZH3 clamp, LAQP lookup, later QL[1] clamp, flux stores, OSHER paths, UpdateCellKernel, and launch wrappers are otherwise unchanged.

## Correctness

At the KLAS3 call site, U_pre and V_pre are the same U1 and V1 values used to compute QL[1], and the helper has not modified QL[1] before QZH3 is formed. The side-normal geometry arrays are not written by the flux kernel.

The reused QL[1] register therefore contains the same rounded Real value as the parent projection expression. All following comparisons and flux arithmetic consume the same QZH3 value with the same multiply order after that projection value.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=40153
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23621
