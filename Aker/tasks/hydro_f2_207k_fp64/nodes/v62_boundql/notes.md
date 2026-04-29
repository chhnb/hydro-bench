# v62_boundql

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and caches the incoming BOUNDA normal velocity QL[1] in a local ql_normal scalar.

BOUNDA checks QL[1] against CL for the supercritical boundary path, then reads QL[1] again to form flux0, FLUX1, and the pre-dispatch FLUX2 value. This node loads QL[1] once before those checks and reuses ql_normal for the comparison and the same flux expressions. The later helper-specific code that can clamp or modify QL[1], such as KLAS5, is left unchanged.

The v42 KLAS3 row_offset reuse, boundary helper dispatch order, OSHER logic, UpdateCellKernel, and launch wrappers are otherwise unchanged.

## Correctness

ql_normal is read from QL[1] immediately on entry to BOUNDA, before any code in BOUNDA mutates QL. The replaced uses are all before the helper dispatch code that may change QL[1].

The comparison ql_normal > CL uses the same Real value as QL[1] > CL. The flux expressions keep the same multiplication order, with ql_normal replacing the original QL[1] operand. No global memory address, branch order, helper call, or floating-point operation order is otherwise changed, so the frozen native CUDA baseline trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39588
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23541
