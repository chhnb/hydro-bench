# v42_rowoff

Parent: v27_ratio_reg

## Change

This node starts from v27_ratio_reg and caches the boundary table row offset inside CalculateKlas3.

The parent computes size_t(pos) * size_t(mesh.NHQ) once for QW_row and again for ZW_row. This node introduces size_t row_offset = size_t(pos) * size_t(mesh.NHQ), then forms both row pointers from that cached offset.

No helper dispatch, interpolation logic, flux expression, update kernel, launch wrapper, or floating-point operation order is otherwise changed.

## Correctness

row_offset is exactly the integer product used by the parent for both boundary table addresses. The resulting QW_row and ZW_row pointers therefore address the same elements as before.

The LAQP call and every floating-point expression keep the same operands and order. This is only integer index reuse, so it should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=7989 run_ms=39838
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23631
