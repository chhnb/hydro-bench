# v98_k5f0

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and caches the freshly computed KLAS5 boundary flux0 value in a local scalar inside BOUNDA.

In the parent KLAS5 arm, after clamping QL[1], the code wrote:

- FLR(0) = H_pre * QL[1]
- FLR(1) = FLR(0) * QL[1]

Because FLR is macro-backed by the side flux arrays, the second line can read back the value just stored to FLUX0. This node introduces Real flux0 = H_pre * QL[1], stores FLR(0) = flux0, and forms FLR(1) = flux0 * QL[1].

No BOUNDA dispatch order, KLAS5 predicate, QL clamp, JL factor expression, helper signature, UpdateCellKernel code, launch wrapper, or other flux expression is changed.

## Correctness

The new flux0 scalar is exactly the value previously stored by FLR(0). FLR(1) keeps the same multiplication order as the parent after that value: (H_pre * QL[1]) is multiplied by QL[1].

The stored FLR(0), FLR(1), and FLR(3) values therefore use the same operands and order as v42_rowoff, while avoiding an immediate read-back of FLR(0). This should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39469
- test_perf: status=OK rc=0 queue_wait_ms=0 run_ms=23544
