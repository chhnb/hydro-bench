# v75_k1args

Parent: v42_rowoff

## Change

This retry starts again from v42_rowoff. It restores the original CalculateKlas1 signature because the FLR store macro in that helper requires sides and idx.

The actual optimization now caches the boundary time-series index used by CalculateKlas1. The parent computed jt * mesh.CELL + pos once for cells.ZT and again for cells.DZT in the HB1 expression. This node introduces int ts_idx = jt * mesh.CELL + pos and uses cells.ZT[ts_idx] and cells.DZT[ts_idx].

No helper dispatch, FLR store, URB iteration, UpdateCellKernel code, launch wrapper, or floating-point expression order is otherwise changed.

## Correctness

ts_idx is exactly the integer expression previously used in both array subscripts. The ZT and DZT loads therefore address the same elements as the parent.

HB1 still combines the loaded ZT value, loaded DZT value, kt, and cells.ZBC[pos] with the same floating-point operands and order. This is only integer index reuse, so it should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes fresh validation results.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39464
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23263

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=38537
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23121
