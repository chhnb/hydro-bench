# v83_k1k5jl

Parent: v75_k1args

## Change

This node starts from v75_k1args and caches the KLAS5 boundary factor 1.0 - mesh.JL inside BOUNDA.

The parent computes that subtraction twice in the FLR3 product for KP == 5. This node introduces Real jl_factor = 1.0 - mesh.JL immediately before the store and changes the store to use jl_factor * jl_factor.

No helper dispatch, branch order, CalculateFluxKernel path, UpdateCellKernel code, launch wrapper, or other flux expression is changed.

## Correctness

jl_factor is exactly the Real result of the original 1.0 - mesh.JL expression. mesh.JL is immutable during the helper call, so both original occurrences read the same value and produce the same scalar.

The FLR3 multiplication remains 4.905 * H_pre * H_pre * factor * factor, with the same left-to-right product structure after substituting the cached scalar. This should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39608
- test_perf: status=OK rc=0 queue_wait_ms=39774 run_ms=23457
