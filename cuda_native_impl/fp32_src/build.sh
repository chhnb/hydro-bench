#!/bin/bash
# Build the native hydro-cal benchmark (self-contained, no external deps)
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/bin:$PATH
export LD_LIBRARY_PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/lib64:$LD_LIBRARY_PATH

# Detect GPU arch
ARCH=${1:-sm_80}  # default A100; pass sm_86 for 3060, sm_90 for B200

# --fmad=false disables FMA contraction in nvcc, eliminating the
# worst PTX-codegen divergence with Taichi for long-step
# trajectories. We tested adding --ftz=true --prec-div=false
# --prec-sqrt=true: that nudges fp32 step=1 U bit_exact_frac
# from ~0.65 to ~0.93 (still under AC-9's 0.99 threshold for the
# V field which starts at zero) but makes fp32 long-step chaotic
# divergence ~100x worse because each side walks its own
# different trajectory. Long-step alignment is more valuable than
# the marginal step=1 gain, so we stay with --fmad=false only.
# Achieving AC-9's 0.99 bit_exact_frac fully would require
# modifying Taichi's PTX codegen to disable FTZ + LLVM FMA
# contraction at the kernel level.
nvcc -O3 -arch=$ARCH -rdc=true --std=c++17 --fmad=false \
    -I"$DIR/hydro-cal-src/include" \
    "$DIR/benchmark.cu" \
    "$DIR/hydro-cal-src/src/functors.cu" \
    "$DIR/hydro-cal-src/src/mesh.cpp" \
    "$DIR/hydro-cal-src/src/cell.cpp" \
    "$DIR/hydro-cal-src/src/side.cpp" \
    -o "$DIR/hydro_native_benchmark" \
    -lcudadevrt

echo "Built: $DIR/hydro_native_benchmark (arch=$ARCH)"
