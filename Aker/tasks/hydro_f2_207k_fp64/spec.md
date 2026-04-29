# native_hydro_functors

## Goal

Optimize the native CUDA hydro-cal kernels in `functors.cu` while preserving the
frozen native CUDA baseline trajectory.

The candidate node supplies one file, `kernel.cu`, which replaces
`hydro-cal-src/src/functors.cu` for the configured precision and is compiled
against the native benchmark harness.

## Target Kernels

- `CalculateFluxKernel`
- `UpdateCellKernel`
- All device helper functions in the same `functors.cu` may be changed only as
  required by those kernels.

## Correctness

Correctness is baseline-vs-candidate native CUDA alignment for `F2_207K_fp64` at
checkpoints `1,10,100,899,7199`. The default threshold is exact equality for
`H/U/V/Z/W/F0/F1/F2/F3`; any drift must be treated as a failed attempt unless
the human operator explicitly relaxes thresholds in `task_config.json`.

## Performance

Primary metric is async native benchmark milliseconds per hydro step on
`F2_207K_fp64`, using `perf_steps=100` and `perf_repeat=3`.

## SASS / PTX Profile Artifacts

Use these fp64 artifacts for performance analysis of the flux gap. Paths are
relative to this task directory unless noted otherwise.

- Taichi fp64 direct kernel artifacts:
  - SASS: `profile_sass/taichi_fp64/calculate_flux.sass`
  - SASS: `profile_sass/taichi_fp64/update_cell.sass`
  - PTX: `profile_sass/taichi_fp64/calculate_flux.ptx`
  - PTX: `profile_sass/taichi_fp64/update_cell.ptx`
  - LLVM IR: `profile_sass/taichi_fp64/calculate_flux.opt.ll`
  - LLVM IR: `profile_sass/taichi_fp64/update_cell.opt.ll`
  - ptxas logs: `profile_sass/taichi_fp64/calculate_flux.ptxas.log`,
    `profile_sass/taichi_fp64/update_cell.ptxas.log`
- Native CUDA v0 baseline artifacts:
  - Full SASS: `profile_sass/native_cuda_fp64/full.sass`
  - Flux SASS: `profile_sass/native_cuda_fp64/CalculateFluxKernel.sass`
  - Update SASS: `profile_sass/native_cuda_fp64/UpdateCellKernel.sass`
- Current Aker best native CUDA reference (`v42_rowoff`) artifacts:
  - Full SASS: `profile_sass/aker_best_v42_fp64/full.sass`
  - Flux SASS: `profile_sass/aker_best_v42_fp64/CalculateFluxKernel.sass`
  - Update SASS: `profile_sass/aker_best_v42_fp64/UpdateCellKernel.sass`
- Opcode summaries and static instruction counts sit next to each `.sass` file
  as `*.opcode_counts.txt` and `*.instruction_count.txt`.
- NCU dynamic CalculateFluxKernel profile:
  - Summary: `profile_sass/ncu_dynamic/summary.md`
  - Taichi CSV: `profile_sass/ncu_dynamic/taichi_fp64_calculate_flux.csv`
  - Native v0 CSV: `profile_sass/ncu_dynamic/native_v0_calculate_flux.csv`
  - Aker best v42 CSV:
    `profile_sass/ncu_dynamic/aker_best_v42_calculate_flux.csv`

The Taichi SASS was produced by running the Taichi fp64 implementation once,
persisting its dumped PTX, assembling with `ptxas -arch=sm_80`, and then running
`nvdisasm -c` on the resulting cubin. The native CUDA SASS was produced with
`cuobjdump --dump-sass` from the corresponding native benchmark binary.

First-pass context: NCU timing shows Taichi `calculate_flux` is much faster than
native CUDA on `F2_207K_fp64` (about `64.7 us` vs native v0 `118.0 us`; current
Aker best is still around `108.5 us` for flux). The SASS files above are meant
to explain that gap. Treat static SASS counts as hints only; use NCU dynamic
metrics for final conclusions because branch predicates and boundary-class
frequency control how much of the static code executes.

## Constraints

- Do not edit files outside the node directory.
- Do not change data loaders, mesh definitions, or benchmark semantics.
- Do not change floating-point operation order unless the attempt is explicitly
  marked failed or human guidance allows relaxed alignment thresholds.
- Preserve the public host wrappers `CalculateFlux(...)` and `UpdateCell(...)`.
