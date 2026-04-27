#!/bin/bash
# Build the native hydro-cal benchmark (self-contained, no external deps)
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/bin:$PATH
export LD_LIBRARY_PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/lib64:$LD_LIBRARY_PATH

# Detect GPU arch
ARCH=${1:-sm_80}  # default A100; pass sm_86 for 3060, sm_90 for B200

# --fmad=false disables the worst FMA/non-FMA divergences between
# Taichi's PTX (which still contracts via LLVM) and nvcc's PTX. We
# tried adding --ftz=true --prec-div=false to match Taichi's
# div.approx.ftz.f32 / mul.ftz.f32 / add.ftz.f32 emissions; that
# improved fp32 step=1 U bit_exact_frac from 0.65 to 0.93 but made
# the fp32 long-step chaotic divergence ~100x worse (each side
# walked its own different chaotic trajectory). Reverted to plain
# --fmad=false.
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
