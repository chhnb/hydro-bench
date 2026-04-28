#!/usr/bin/env bash
# Build two minimal nvcc kernels (pow(H,1.5) vs H*sqrt(H)) with the SAME
# flags as the native build (-O3 --fmad=false) and dump PTX. Used to
# answer: is __nv_pow itself responsible for FMA expansion, or is the
# polynomial expansion only in libdevice's pow path?
#
# Output: /tmp/pow15_ptx_signature.txt summarising fma.rn.f64 counts in
# both kernels, plus a side-by-side count table.
set -u
export PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/bin:$PATH

WORK=$(mktemp -d)
SRC="$WORK/pow15.cu"
PTX="$WORK/pow15.ptx"

cat >"$SRC" <<'CU'
extern "C" __global__
void k_pow15(const double *x, double *y, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = pow(x[i], 1.5);
}
extern "C" __global__
void k_xsqrtx(const double *x, double *y, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = x[i] * sqrt(x[i]);
}
extern "C" __global__
void k_pow33(const double *x, double *y, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = pow(x[i], 0.33333);
}
CU

nvcc -O3 --fmad=false -arch=sm_80 -ptx "$SRC" -o "$PTX" 2>&1 | head -20

OUT=/tmp/pow15_ptx_signature.txt
{
    echo "=== PTX signature: pow(x,1.5) vs x*sqrt(x) vs pow(x,0.33333) ==="
    echo "Compile flags: nvcc -O3 --fmad=false -arch=sm_80 -ptx"
    echo
    echo "Kernel boundaries:"
    grep -n "^.entry\|^.visible .entry\|.func " "$PTX" | head -40
    echo
    echo "Total fma.rn.f64 in entire PTX:"
    grep -c "fma.rn.f64" "$PTX"
    echo
    echo "fma.rn.f64 count per kernel block (between adjacent .entry boundaries):"

    awk '
        /^.weak .entry|^.visible .entry|^.entry/ {
            if (current != "") { print current ": " count " fma.rn.f64"; }
            current = $0; count = 0; next
        }
        /fma.rn.f64/ { count++ }
        END { if (current != "") print current ": " count " fma.rn.f64"; }
    ' "$PTX"

    echo
    echo "PTX file: $PTX"
} | tee "$OUT"
