#!/bin/bash
# Build the native hydro-cal benchmark (self-contained, no external deps)
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/bin:$PATH
export LD_LIBRARY_PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/lib64:$LD_LIBRARY_PATH

# Detect GPU arch
ARCH=${1:-sm_80}  # default A100; pass sm_86 for 3060, sm_90 for B200

nvcc -O3 -arch=$ARCH -rdc=true --std=c++17 \
    -I"$DIR/hydro-cal-src/include" \
    "$DIR/benchmark.cu" \
    "$DIR/hydro-cal-src/src/functors.cu" \
    "$DIR/hydro-cal-src/src/mesh.cpp" \
    "$DIR/hydro-cal-src/src/cell.cpp" \
    "$DIR/hydro-cal-src/src/side.cpp" \
    -o "$DIR/hydro_native_benchmark" \
    -lcudadevrt

echo "Built: $DIR/hydro_native_benchmark (arch=$ARCH)"
