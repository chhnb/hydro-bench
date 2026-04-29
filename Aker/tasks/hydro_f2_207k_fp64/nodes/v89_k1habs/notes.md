# v89_k1habs

Parent: v75_k1args

## Change

This node starts from v75_k1args and caches the repeated H1 * fabs(QL[1]) prefix in the bed-exposed CalculateFluxKernel branch where ZC <= cells.ZBC[pos].

The parent computed that prefix once for FLUX1 and again for FLUX2. This node introduces Real H_abs_ql = H1 * fabs(QL[1]); and uses H_abs_ql * QL[1] and H_abs_ql * QL[2] in the existing FLUX_VAL call.

No branch condition, helper dispatch, memory address, update kernel code, launch wrapper, or other flux expression is changed.

## Correctness

H_abs_ql is computed from the exact operands and order used by the parent prefix. The downstream products keep the same left-associated prefix multiplied by QL[1] and QL[2], so the stored FLUX1 and FLUX2 values should be bit-exact.

The change is local scalar common-subexpression reuse and should preserve the frozen native CUDA baseline trajectory.

## Validation

Host-side broker validation completed successfully.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39749
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=24023
- host validation: existing OK reports reused
