# v88_k1osneg

Parent: v75_k1args

## Change

This node starts from v75_k1args and caches the negative thresholds used by OSHER branch classification.

The parent evaluates -CA twice while choosing K2 and -CR four times while choosing K1. This node introduces neg_CA = -CA before the K2 comparisons and neg_CR = -CR before the K1 comparisons, then reuses those locals in the existing conditions.

No QS dispatch, flux accumulation, CalculateFluxKernel path, UpdateCellKernel path, KLAS helper, launch wrapper, or KLAS1 time-series index logic is otherwise changed.

## Correctness

CA and CR are already computed and are not modified before the classification tests. Unary negation of a Real value is exact, including signed zero, so neg_CA and neg_CR are the same comparison operands that the parent formed inline.

The branch chain keeps the same order and the same strict and non-strict comparisons. All downstream QS calls and floating-point flux expressions are unchanged, so this should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39856
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23609
