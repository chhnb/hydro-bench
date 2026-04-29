# v90_k3f0

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and reuses freshly computed KLAS3 FLR0 values locally.

In both CalculateKlas3 boundary branches, the parent writes FLR(0) and then immediately forms FLR(1) by reading FLR(0) back through the macro-backed sides.FLUX0[idx] location. This node introduces a local Real flux0 for the existing H_pre * QL[1] and HB1 * URB products, stores FLR(0) from that local, and uses the same local for the dependent FLR(1) multiplication.

No KLAS3 dispatch, table lookup, URB iteration, branch predicate, flux store target, UpdateCellKernel code, launch wrapper, or floating-point operation order is otherwise changed.

## Correctness

The local flux0 values are exactly the products the parent wrote to FLR(0). No code writes sides.FLUX0[idx] between each FLR(0) store and the following FLR(1) expression, so reading the local register supplies the same bits as the immediate macro read-back.

Each FLR(1) expression keeps the same multiplication order: first H_pre * QL[1], then * QL[1] in the simple branch; first HB1 * URB, then * URB in the iterative branch. This should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=14628 run_ms=40357
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23608
