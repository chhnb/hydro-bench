# v56_k6geom

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and passes the side-normal geometry values already loaded by CalculateFluxKernel into the KLAS6 boundary helper.

CalculateFluxKernel loads sides.COSF[idx] and sides.SINF[idx] into COSJ and SINJ before any boundary dispatch. The parent KLAS6 helper reloaded those same arrays while projecting the neighbor velocity in two KLAS6 branches. This node adds COSJ and SINJ parameters to BOUNDA and CalculataKlas6, forwards the caller registers, and replaces the KLAS6 sides.COSF[idx] and sides.SINF[idx] reads with those parameters.

The v42 KLAS3 row_offset reuse, KLAS3 projection code, KLAS1/KLAS10 time-series indexing, OSHER logic, UpdateCellKernel, and launch wrappers are otherwise unchanged.

## Correctness

The forwarded COSJ and SINJ values are loaded from the exact side-normal addresses that KLAS6 used in the parent. Neither CalculateFluxKernel nor any helper writes the side geometry arrays, so the helper reloads would observe the same Real values.

The KLAS6 projection formulas keep the same operand order: UC * COS + VC * SIN and VC * COS - UC * SIN. Only the source of COS and SIN changes from repeated global loads to already-loaded registers. This should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=4513 run_ms=39473
- test_perf: status=OK rc=0 queue_wait_ms=23610 run_ms=23589

## Host validation
- host validation: existing OK reports reused
