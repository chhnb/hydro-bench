# v27_ratio_reg

Parent: v18_hb1_sqrt

## Change

This node starts from v18_hb1_sqrt and keeps the internal-edge reconstructed depth ratio in a local register.

In the forward internal side path, CalculateFluxKernel already evaluates fmin(HC / QR[0], 1.5) to build QR[1]. The parent recomputed the same divide and min after OSHER when assembling FLR(1). This node stores that value as depth_ratio and reuses it in the post-OSHER FLR(1) expression.

The reverse internal side path receives the same treatment: fmin(HC2 / QR1[0], 1.5) is stored as depth_ratio1 for QR1[1] and then reused for FLR(1).

No helper dispatch, OSHER call, flux store, update kernel, launch wrapper, or arithmetic ordering inside the final FLR(1) multiply chain is otherwise changed.

## Correctness

Both ratios are computed from the same operands at the same point where the parent computed them for QR or QR1 reconstruction. OSHER does not modify QR[0] or QR1[0], and HC, HC2, UR, and UR1 are unchanged across the call.

The reused register therefore contains the exact value that the parent recomputed after OSHER. The FLR(1) expression still evaluates (1 - ratio) * H * U * U / 2 in the same order, with only the redundant divide/min removed.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=41826
- test_perf: status=OK rc=0 queue_wait_ms=2 run_ms=23836
