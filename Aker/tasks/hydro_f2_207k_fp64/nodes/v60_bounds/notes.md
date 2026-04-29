# v60_bounds

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and simplifies the launch bounds guards in CalculateFluxKernel and UpdateCellKernel.

CalculateFluxKernel computes idx from blockIdx.x, blockDim.x, and threadIdx.x, then computes pos as idx / 4. UpdateCellKernel computes pos from the same CUDA launch indices. These values cannot be negative for the configured launches.

This node changes the guards from idx < 0 or idx >= mesh.CELL * 4 to idx >= mesh.CELL * 4, and from pos < 0 or pos >= mesh.CELL to pos >= mesh.CELL. The upper-bound checks, helper dispatch, row-offset cache, flux expressions, update expressions, and launch wrappers are otherwise unchanged.

## Correctness

CUDA block and thread indices are nonnegative, and the wrapper launches use positive grid and block dimensions for this case. Therefore the removed negative branches were unreachable under the benchmark launches.

All remaining out-of-range threads still exit through the same upper-bound checks before any memory access. No floating-point expression, memory address for in-range threads, or operation order changes, so the frozen native CUDA trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39799
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23633
