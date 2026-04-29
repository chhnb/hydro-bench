# v33_ratio_trig

Parent: v27_ratio_reg

## Change

This node starts from v27_ratio_reg and threads the side-normal direction values already loaded in CalculateFluxKernel through the boundary dispatch path.

BOUNDA now receives the caller cached COSJ and SINJ values. It passes those registers to CalculateKlas3 and CalculataKlas6, and those helpers use the passed values instead of reloading sides.COSF[idx] and sides.SINF[idx].

The v27 internal-edge depth-ratio reuse is unchanged. No flux formula, branch order, OSHER call, update kernel, launch wrapper, or state store is otherwise changed.

## Correctness

CalculateFluxKernel loads COSJ and SINJ from the same idx immediately before boundary dispatch. The side geometry arrays are not written by these kernels, so the helper reloads would observe the same values.

The projection expressions keep the same operands in the same order: U * COS + V * SIN and V * COS - U * SIN. This change only forwards already-loaded registers into helper calls, so it should preserve the frozen native CUDA trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=40523
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=24004
