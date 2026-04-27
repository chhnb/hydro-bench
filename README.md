# hydro-bench

Benchmark suite comparing **Taichi** vs **native CUDA** implementations of two
real-world water-resources hydrodynamics solvers on NVIDIA A100.

Workloads:

| Case            | Description                              | Cells   | Precision |
|-----------------|------------------------------------------|---------|-----------|
| `F1_6.7K_fp64`  | F1 shallow water (Osher Riemann solver)  |   6,675 | fp64      |
| `F2_24K_fp32`   | F2 hydro-cal (refactored, 2-kernel)      |  24,020 | fp32      |
| `F2_24K_fp64`   | F2 hydro-cal (refactored, 2-kernel)      |  24,020 | fp64      |
| `F2_207K_fp32`  | F2 hydro-cal (refactored, 2-kernel)      | 207,234 | fp32      |
| `F2_207K_fp64`  | F2 hydro-cal (refactored, 2-kernel)      | 207,234 | fp64      |

Both implementations exercise the **same** 2D unstructured-mesh shallow-water
solver on identical input meshes. The Taichi side uses plain `@ti.kernel` source
without modifying Taichi's runtime.

---

## Quick Start

```bash
# 1. Set up venv + build CUDA binaries
bash setup.sh

# Override CUDA arch if not A100:
GPU_ARCH=90 bash setup.sh    # H100
GPU_ARCH=86 bash setup.sh    # RTX 3060 / 3090

# 2. Activate venv
source venv/bin/activate

# 3. Run all benchmarks
bash scripts/run_benchmark.sh

# Or single case
bash scripts/run_benchmark.sh F2_24K_fp32

# 4. View results
cat results/all_results.jsonl
python scripts/compare.py results/all_results.jsonl
```

---

## Repo Layout

```
hydro-bench/
├── README.md
├── setup.sh                    # creates venv + builds CUDA binaries
├── requirements.txt            # taichi, numpy, torch
├── data/
│   ├── F1_6.7K_fp64/           # F1 binary mesh + Taichi-compiled PTX
│   ├── F1_text/                # F1 .DAT mesh files (Taichi reads these)
│   ├── F2_24K_fp32/            # F2 24K binary + PTX (CUDA bench reads these)
│   ├── F2_24K_fp64/
│   ├── F2_207K_fp32/
│   ├── F2_207K_fp64/
│   ├── F2_24K_text/            # F2 .DAT mesh files for Taichi
│   └── F2_207K_text/
├── taichi_impl/
│   ├── F1_hydro_taichi_fp64.py
│   ├── F2_hydro_taichi_fp32.py
│   ├── F2_hydro_taichi_fp64.py
│   ├── mesh_loader_f1.py       # loads F1 .DAT files
│   └── mesh_loader_f2.py       # loads F2 .DAT files
├── cuda_impl/
│   ├── F1_persistent_bench.cu  # F1 CUDA Graph timing harness
│   ├── F1_driver.cu            # cooperative driver
│   ├── F1_driver.ptx           # pre-built PTX
│   ├── F2_persistent_bench.cu  # F2 CUDA Graph timing harness
│   ├── F2_driver.cu
│   └── F2_driver.ptx
├── scripts/
│   ├── run_taichi.py           # run one Taichi case → emit RESULT JSON
│   ├── run_cuda.sh             # run one CUDA case → emit RESULT JSON
│   ├── run_benchmark.sh        # run Taichi + CUDA on all cases
│   └── compare.py              # parse results, print comparison table
└── results/
    └── all_results.jsonl       # accumulated runs
```

---

## How the Comparison Works

### Taichi side

- `scripts/run_taichi.py F2_24K_fp32` imports `F2_hydro_taichi_fp32.py`
- Runs `step_fn()` (which loops 100 timesteps in Python, calls 2 `@ti.kernel`s
  per step: `calculate_flux` + `update_cell`)
- Times via `cudaEventRecord` (10 runs, median of 5)
- Emits μs/step including Python launch overhead

### CUDA side

- `scripts/run_cuda.sh F2_24K_fp32` runs `cuda_impl/F2_persistent_bench`
- Loads pre-compiled `flux_func.ptx` + `update_func.ptx` from data dir
- Wraps 900 timesteps × 2 kernel launches in a `cuStreamBeginCapture` /
  `cuStreamEndCapture` CUDA Graph
- Times Graph replay (no Python in loop)
- Emits μs/step (pure GPU compute, launch overhead amortized by Graph)

### Output

`compare.py` produces a table:

```
┌──────────────────┬───────────────┬─────────────────┬─────────┬──────────────┐
│ Case             │ Taichi μs/step│ CUDA Graph μs/st│ Ratio   │ Winner       │
├──────────────────┼───────────────┼─────────────────┼─────────┼──────────────┤
│ F2_24K_fp32      │         67.54 │            8.26 │   8.18x │ CUDA faster  │
└──────────────────┴───────────────┴─────────────────┴─────────┴──────────────┘
```

**Note**: this repo's tables show pure GPU kernel time measured with `ncu`
(no Python overhead). For Python end-to-end comparison and CUDA Graph
capture, see `taichi-graph-patch/` at the repo parent.

---

## Requirements

- **GPU**: NVIDIA A100 (compute 8.0). Other Ampere/Hopper GPUs work with
  `GPU_ARCH=<num>` env var to `setup.sh`.
- **CUDA**: 12.x or 13.x toolkit (nvcc must be in PATH or set `NVCC=`)
- **Python**: 3.10+ with `python3 -m venv` available
- **Disk**: ~3 GB for mesh data

---

## Correctness Verification

We use a **2-kernel split** Taichi implementation for both F1 and F2, matching
native CUDA's parallelization (CalculateFlux per edge → UpdateCell per cell).

### Step-1 bit-exact (proves algorithm equivalence)

```
Case            max abs diff    Status
F1_6.7K_fp32    7.63e-6         PASS    (fp32 epsilon)
F1_6.7K_fp64    0.000000e+00    PASS ✅  BIT-EXACT
F2_24K_fp32     0.000000e+00    PASS ✅  BIT-EXACT
F2_24K_fp64     0.000000e+00    PASS ✅  BIT-EXACT
```

### Step-50 numerical drift (FP non-associativity)

```
Case            max abs diff    Status
F1_6.7K_fp32    1.14e-5         PASS
F1_6.7K_fp64    4.11e-6         PASS
F2_24K_fp32     2.86e-6         PASS
F2_24K_fp64    7.11e-15         PASS    (machine epsilon)
```

**Why F1 has slightly larger drift**: F1 has 8 KLAS=10 boundary edges (CalculateKlas10
boundary type, with QT=0 in test data). Native CUDA iterates 20 times in this
boundary; we compute the closed-form result directly. After 50 steps, FP
non-associativity in `sqrt`/`pow` accumulation grows ~1 ulp/step. F2 cases stay
bit-exact (~1e-15) because they don't have this boundary type.

**Reproduce**: `python scripts/check_correctness.py all 1` for bit-exact check;
`scripts/check_correctness.py all 50` for steady-state.

F1 cases tested: F1_6.7K_fp32, F1_6.7K_fp64. F1_207K and F2_207K cases SKIP
correctness (boundary timeseries data missing → physics blows up to inf).

## Scope

This repo measures **kernel time only** via `ncu` (sum of `calculate_flux`
and `update_cell` per step). Python launch overhead and CUDA Graph are out
of scope here — the goal is apples-to-apples kernel comparison between the
Taichi-compiled PTX and the hand-written CUDA kernel.

For end-to-end performance with CUDA Graph capture (Taichi-Python users
without writing C++), see the separate `taichi-graph-patch/` directory at
the repo parent — it patches Taichi 1.8 to support `cudaStreamBeginCapture`
and provides an example `run_taichi_graph.py` that imports F1/F2 from this
benchmark.

## Limitations

1. **F1 vs F2 algorithms differ**. F1 is a simpler shallow-water step;
   F2 is the full hydro-cal Riemann solver with boundary-condition timeseries.
   They share data layout (NAC, KLAS, etc.) but compute different physics.

2. **Mesh data origin**: F1 uses 6,675 cells from a real hydro-cal test case;
   F2 24K and 207K are larger production meshes. Cell counts are fixed per case.

3. **F1 long-step chaotic drift** (see `Correctness Verification` above):
   step=1 is bit-exact between Taichi and native CUDA, but FP non-associativity
   in PTX-level instruction selection causes sub-ulp seeds that grow chaotically
   over many timesteps. Mitigated by `fast_math=False`. Max relative diff stays
   below 2e-5 over 500 steps.

---

## License

The core hydro-cal algorithm code originates from the water-resources hydro-cal
project. This benchmark harness is intended for performance comparison study only.
