# v30_trig_arg

Parent: v18_hb1_sqrt

## Change

This node starts from v18_hb1_sqrt and threads the side-normal direction values already loaded in CalculateFluxKernel through the boundary dispatch path. BOUNDA now receives the caller cached COSJ and SINJ values, then passes them to CalculateKlas3 and CalculataKlas6. Those helpers use the passed registers instead of reloading sides.COSF[idx] and sides.SINF[idx].

No flux formula, branch order, wrapper, launch geometry, or state update is otherwise changed.

## Correctness

CalculateFluxKernel loaded COSJ and SINJ from the same side index immediately before boundary dispatch. The candidate only reuses those values inside the same thread and kernel invocation, and the side geometry arrays are not written on these paths. The arithmetic expressions in CalculateKlas3 and CalculataKlas6 keep the same operands in the same order, so the native baseline trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=40204
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23792
