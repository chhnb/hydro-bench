# v67_qspos

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and removes the unused pos argument from the QS helper template used by OSHER.

The parent QS signature accepts int pos, but the helper body never reads it. OSHER passes its own pos value through every QS call solely to satisfy that unused parameter.

This node changes QS to take int j followed directly by QL, QR, FIL, FIR, and FLR_OSHER, and removes the forwarded pos argument from every QS call inside OSHER. OSHER itself keeps the same signature and call sites. All switch cases, QF calls, flux accumulation expressions, and launch wrappers are otherwise unchanged.

## Correctness

Because QS never observes pos, removing that parameter cannot change branch selection, helper dispatch, memory addresses, or floating-point operands. OSHER still receives pos exactly as before, but no longer forwards it into a helper that ignores it.

Every QF call and every FLUX_OSHER accumulation keeps the same operands and order. This is only unused helper argument cleanup, so the frozen native CUDA trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39817
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23818
