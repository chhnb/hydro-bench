# v80_k1boundql

Parent: v75_k1args

## Change

This node starts from v75_k1args and caches the incoming BOUNDA normal velocity in a local ql_normal scalar.

BOUNDA checks QL[1] against CL, then reads the same value again to form flux0, FLUX1, and the pre-dispatch FLUX2 value. The new scalar is read before any helper-specific code can mutate QL[1], and only those pre-dispatch uses are replaced.

## Correctness

ql_normal is exactly QL[1] on BOUNDA entry. The comparison and flux products keep the same operands and multiplication order, and KLAS5 plus other helper paths that can modify QL[1] remain unchanged.

## Validation

Host-side broker validation is pending. meta.json intentionally keeps attempt_status as FAIL with failure_reason set to pending host validation until the trusted host writes reports.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39953
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=25033
