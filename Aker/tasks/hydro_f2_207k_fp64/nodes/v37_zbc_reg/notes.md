# v37_zbc_reg

Parent: v27_ratio_reg

## Change

This node starts from v27_ratio_reg and caches the current cell bed elevation used by the remaining nonboundary CalculateFluxKernel branches. After the special-boundary path, the dry zero-flux path, and the ZI <= BC path have all exited, the code loads cells.ZBC[pos] once into ZBCP. The following ZC comparison, shallow-cell branches, and internal-edge reconstruction reuse ZBCP instead of reloading cells.ZBC[pos].

The existing v27 depth-ratio reuse, helper dispatch, OSHER calls, launch wrappers, and UpdateCellKernel are otherwise unchanged.

## Correctness

ZBCP is loaded from the same cells.ZBC[pos] address immediately before the first original use in this part of the branch chain. No code in CalculateFluxKernel writes cells.ZBC, and the branch conditions still execute in the same order: ZC <= ZBCP is the original ZC <= cells.ZBC[pos] test, followed by the same H1, HC, and internal-edge branches. Each flux expression keeps the same operands and floating-point operation order; only repeated global loads of the same value are removed.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=40016
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23668
