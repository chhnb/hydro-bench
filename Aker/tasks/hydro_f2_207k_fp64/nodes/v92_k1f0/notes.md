# v92_k1f0

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and caches the freshly computed KLAS1 boundary flux0 value in a local scalar.

At the end of CalculateKlas1, the parent wrote:

- FLR(0) = HB1 * URB
- FLR(1) = FLR(0) * URB

Because FLR is macro-backed by the side flux arrays, the second line may read back the value just stored to FLUX0. This node introduces Real flux0 = HB1 * URB, stores FLR(0) = flux0, and forms FLR(1) = flux0 * URB.

No KLAS1 iteration logic, branch predicate, helper signature, UpdateCellKernel code, launch wrapper, or other flux expression is changed. The similar KLAS3 pattern is intentionally left as in the parent because that direction already has a committed node.

## Correctness

The new flux0 scalar is exactly the value previously stored by FLR(0). FLR(1) keeps the same multiplication order as the parent after that value: (HB1 * URB) is multiplied by URB.

The stored FLR(0), FLR(1), and FLR(3) values therefore use the same operands and order as v42_rowoff, while avoiding an immediate read-back of FLR(0). This should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39911
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23625

## Host validation
- host validation: existing OK reports reused

## Host validation
- host validation: existing OK reports reused
