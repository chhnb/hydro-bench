# F2_207K_fp64 CalculateFluxKernel NCU Dynamic Summary

All rows are median per profiled `CalculateFluxKernel` / Taichi
`calculate_flux` launch on A100 `sm_80`. The profile used 20 launches after a
10-launch skip.

| metric | Taichi | native v0 | Aker v42 | v42 / Taichi |
|---|---:|---:|---:|---:|
| time_us | 84.7 | 117.9 | 111.7 | 1.32x |
| warp_inst_M | 12.4 | 20.2 | 19.5 | 1.56x |
| pred_on_thread_inst_M | 192.0 | 225.6 | 219.8 | 1.14x |
| fp64_pred_on_M | 50.4 | 85.6 | 83.5 | 1.66x |
| dadd_dmul_dfma_M | 38.6 | 70.5 | 68.5 | 1.77x |
| branch_warp_K | 740 | 1068 | 1045 | 1.41x |
| global_ld_warp_K | 482 | 527 | 412 | 0.85x |
| global_st_warp_K | 104 | 416 | 416 | 4.01x |
| dram_read_MB | 36.3 | 40.1 | 39.9 | 1.10x |
| dram_write_MB | 36.2 | 37.0 | 36.8 | 1.02x |
| active_threads_per_inst | 16.0 | 11.8 | 11.9 | 0.74x |
| registers_per_thread | 80 | 62 | 64 | 0.80x |
| waves_per_sm | 10.0 | 7.5 | 7.5 | 0.75x |

Interpretation:

- The native CUDA flux gap is not primarily DRAM bandwidth: DRAM read/write
  bytes are close between Taichi and native.
- Aker v42 still executes about 1.56x more warp-level SASS instructions than
  Taichi and about 1.66x more predicated-on FP64 thread instructions.
- The biggest arithmetic gap is in `DADD/DMUL/DFMA`: v42 executes about 1.77x
  Taichi's predicated-on thread instructions in this group.
- Native has more branch work and poorer lane utilization: active threads per
  executed instruction are about 11.9 for v42 versus 16.0 for Taichi.
- v42 reduced some global load warp instructions versus native v0, but stores
  remain much higher than Taichi in this metric, and the dominant residual gap
  remains FP64 arithmetic plus branch/predicate efficiency.

Raw CSV files:

- `taichi_fp64_calculate_flux.csv`
- `native_v0_calculate_flux.csv`
- `aker_best_v42_calculate_flux.csv`
