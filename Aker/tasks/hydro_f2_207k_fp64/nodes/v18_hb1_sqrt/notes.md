# v18_hb1_sqrt

Parent: v17_bound_cl

## Change

This node starts from v17_bound_cl and hoists an invariant square root out of two boundary fixed-point loops.

CalculateKlas3 already clamps HB1 before entering its URB iteration, and CalculateKlas1 does the same after loading the boundary target depth. In both helpers the parent recomputed sqrt(HB1) on every loop iteration while HB1 stayed unchanged. This node computes Real sqrt_HB1 = sqrt(HB1) once before each loop and uses that register in the existing FIAR expression.

No helper dispatch order, loop exit condition, flux expression, launch wrapper, or state update is otherwise changed.

## Correctness

HB1 is assigned and clamped before the new sqrt_HB1 value is computed, and neither loop writes HB1. Each loop executes at least one iteration on the paths where the hoist is introduced, so the square root value is the same value the parent computed in the first and later iterations.

The FIAR expression still multiplies by 6.264 at the same point inside the loop and the URB update keeps the same operands and order. The change only avoids recomputing an invariant square root, so the baseline trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39952
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23521
