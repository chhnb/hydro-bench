# v96_k1f0

Parent: v75_k1args

## Change

This node starts from v75_k1args and changes only CalculateKlas1.

At the end of the KLAS1 boundary solve, the parent stores FLR(0) = HB1 * URB and immediately reads FLR(0) back through the macro-backed sides.FLUX0[idx] storage to compute FLR(1). This node keeps that freshly computed value in a local Real flux0, stores FLR(0) from it, then computes FLR(1) as flux0 * URB.

No helper dispatch, branch condition, URB iteration, UpdateCellKernel code, launch wrapper, or other floating-point expression is changed.

## Correctness

flux0 is exactly the old HB1 * URB expression. FLR(1) still multiplies that same rounded product by URB with the same left-to-right multiplication order, but avoids the immediate macro-backed readback of FLR(0). FLR(0) and FLR(3) are stored with the same values as the parent, so the frozen native CUDA trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes fresh validation results.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39707
- test_perf: status=OK rc=0 queue_wait_ms=0 run_ms=23657
