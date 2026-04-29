# v35_rev_zbc

Parent: v27_ratio_reg

## Change

This node starts from v27_ratio_reg and caches the current cell bed elevation in the reverse internal-edge branch of CalculateFluxKernel.

In the parent, that branch reads cells.ZBC[pos] while forming ZC1, then reads the same address again after the OSHER call for the ZA > cells.ZBC[pos] check and the HC3 subtraction. This node introduces Real ZBCP = cells.ZBC[pos] immediately before ZC1, uses ZBCP in the existing fmax, and reuses it in the later ZA comparison and subtraction.

No OSHER call, helper dispatch, flux store, update kernel, launch wrapper, or floating-point expression order is otherwise changed.

## Correctness

ZBCP is loaded from the exact cells.ZBC[pos] address used by the parent. The reverse internal branch does not write cells.ZBC, and OSHER only reads its local QL, QR, FIL, and FLR_OSHER arguments, so the value remains invariant across the branch.

The fmax, comparison, and subtraction keep the same operands and order with the global load replaced by a register. This should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=9150 run_ms=40233
- test_perf: status=OK rc=0 queue_wait_ms=0 run_ms=23621
