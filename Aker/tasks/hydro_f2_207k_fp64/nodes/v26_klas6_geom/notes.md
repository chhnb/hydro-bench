# v26_klas6_geom

Parent: v18_hb1_sqrt

## Change

This node starts from v18_hb1_sqrt and reuses side geometry already loaded by CalculateFluxKernel.

CalculateFluxKernel loads sides.COSF[idx] and sides.SINF[idx] into COSJ and SINJ before dispatching boundary sides. The parent CalculataKlas6 helper reloads the same two values from global memory when it projects the neighbor velocity into normal and tangential components. This node adds COSJ and SINJ parameters to BOUNDA and CalculataKlas6, passes the caller registers through, and replaces the KLAS6 helper reloads with those arguments.

No helper dispatch condition, flux formula, launch wrapper, state update, or OSHER path is otherwise changed.

## Correctness

The new COSJ and SINJ arguments are loaded from exactly the same sides.COSF[idx] and sides.SINF[idx] addresses that CalculataKlas6 used before. They are loaded earlier in the same CalculateFluxKernel thread, and no code writes those geometry arrays between the original load and the KLAS6 call.

The KLAS6 projection expressions keep the same operands and order: UC * COSJ + VC * SINJ and VC * COSJ - UC * SINJ. This is only load reuse through helper arguments, so it should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=14653 run_ms=39928
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23677

## Host validation
- host validation: existing OK reports reused
