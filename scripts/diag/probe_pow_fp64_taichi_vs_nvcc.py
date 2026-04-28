"""Bit-exact comparison: Taichi-CUDA pow(x, 1.5) vs nvcc-CUDA pow(x, 1.5).

Background: F2_207K_fp64 long-step (>~35000) drift is bit-level. Algorithm
is identical, but the PTX of Taichi calculate_flux has 361 fma.rn.f64 vs
native's 39. Most of the gap is inside __nv_pow inlining (4 ti.pow(*, 1.5)
sites in OSHER + 1 in update_cell). This probe asks: when both backends
call __nv_pow with the same fp64 input, do they return bit-identical
fp64? If yes, the divergence is purely from the SURROUNDING fma
contractions of the user algorithm; if no, the libdevice expansion path
itself differs and we cannot match bit-exact without unifying compilers.

Run::

    python scripts/diag/probe_pow_fp64_taichi_vs_nvcc.py

Outputs: prints up to 32 (x, taichi_pow, nvcc_pow, diff_ulp) rows for x
sampled across the hydro-realistic range [HM1, ~50.0].
"""
import os
import struct
import subprocess
import sys
import tempfile

import numpy as np

# Cover the realistic H range encountered in F2_207K runs:
# - HM1=0.001 (dry threshold)
# - HM2=0.01 (shallow guard)
# - typical wet H up to ~50 m
SAMPLE_X = np.array(
    [
        0.001, 0.0015, 0.005, 0.01, 0.0123456789,
        0.05, 0.1, 0.5, 1.0, 1.234567890123456,
        2.0, 3.14159265358979, 5.0, 9.81, 10.0,
        25.0, 50.0,
    ],
    dtype=np.float64,
)
EXPONENT = 1.5


def fp64_to_u64(x):
    return int.from_bytes(struct.pack("<d", float(x)), "little")


def ulp_diff(a, b):
    return abs(fp64_to_u64(a) - fp64_to_u64(b))


# ---- Taichi side ----
def taichi_pow():
    import taichi as ti
    ti.init(arch=ti.cuda, default_fp=ti.f64, fast_math=False)

    n = len(SAMPLE_X)
    xf = ti.field(dtype=ti.f64, shape=n)
    yf = ti.field(dtype=ti.f64, shape=n)

    @ti.kernel
    def k():
        for i in range(n):
            yf[i] = ti.pow(xf[i], ti.cast(EXPONENT, ti.f64))

    xf.from_numpy(SAMPLE_X)
    k()
    return yf.to_numpy()


# ---- nvcc CUDA side ----
NVCC_SRC = r"""
#include <cstdio>
#include <cstdint>

extern "C" __global__
void pow_kern(const double *x, double *y, int n, double e) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = pow(x[i], e);
}
"""


def nvcc_pow():
    import ctypes

    with tempfile.TemporaryDirectory() as td:
        src = os.path.join(td, "pow.cu")
        with open(src, "w") as f:
            f.write(NVCC_SRC)

        # Driver-API path is heavy; use a thin runtime-API host that
        # launches the kernel via cuModuleLoad. Easier: build a shared
        # lib whose host side launches the kernel with --fmad=false.
        host_src = os.path.join(td, "host.cu")
        with open(host_src, "w") as f:
            f.write(NVCC_SRC + r"""
extern "C" int run(const double *xin, double *yout, int n, double e) {
    double *dx, *dy;
    cudaMalloc(&dx, n*sizeof(double));
    cudaMalloc(&dy, n*sizeof(double));
    cudaMemcpy(dx, xin, n*sizeof(double), cudaMemcpyHostToDevice);
    int bs = 32;
    int gs = (n + bs - 1) / bs;
    pow_kern<<<gs, bs>>>(dx, dy, n, e);
    cudaDeviceSynchronize();
    cudaMemcpy(yout, dy, n*sizeof(double), cudaMemcpyDeviceToHost);
    cudaFree(dx);
    cudaFree(dy);
    return 0;
}
""")
        lib = os.path.join(td, "libpow.so")
        # --fmad=false matches the native build (-O3 --fmad=false).
        r = subprocess.run(
            ["nvcc", "-O3", "--fmad=false", "-Xcompiler", "-fPIC",
             "-shared", host_src, "-o", lib],
            capture_output=True, text=True,
        )
        if r.returncode != 0:
            sys.stderr.write(r.stderr)
            raise RuntimeError("nvcc build failed")

        dll = ctypes.CDLL(lib)
        dll.run.argtypes = [
            ctypes.POINTER(ctypes.c_double),
            ctypes.POINTER(ctypes.c_double),
            ctypes.c_int, ctypes.c_double,
        ]
        dll.run.restype = ctypes.c_int

        n = len(SAMPLE_X)
        xin = (ctypes.c_double * n)(*SAMPLE_X)
        yout = (ctypes.c_double * n)()
        dll.run(xin, yout, n, EXPONENT)
        return np.array(list(yout), dtype=np.float64)


def main():
    print(f"=== pow(x, {EXPONENT}) bit-exact: Taichi-CUDA vs nvcc-CUDA(--fmad=false) ===")
    print()

    t = taichi_pow()
    n = nvcc_pow()

    print(f"{'x':>22}  {'taichi (hex)':>20}  {'nvcc (hex)':>20}  {'ulp':>6}  {'identical':>10}")
    n_match = 0
    n_diff = 0
    max_ulp = 0
    for i, x in enumerate(SAMPLE_X):
        ulp = ulp_diff(t[i], n[i])
        if ulp == 0:
            n_match += 1
        else:
            n_diff += 1
            max_ulp = max(max_ulp, ulp)
        print(
            f"{x:>22.16e}  {fp64_to_u64(t[i]):>020X}  {fp64_to_u64(n[i]):>020X}  "
            f"{ulp:>6d}  {'YES' if ulp == 0 else 'no':>10}"
        )

    print()
    print(f"Total samples: {len(SAMPLE_X)}")
    print(f"  bit-exact match: {n_match}")
    print(f"  bit-different : {n_diff}  (max ulp = {max_ulp})")
    print()
    if n_diff == 0:
        print("VERDICT: __nv_pow path is bit-identical between Taichi and nvcc.")
        print("         Therefore the 361-vs-39 fma gap surrounds pow, not inside.")
        print("         Divergence comes from user-algorithm fma contraction order.")
    else:
        print("VERDICT: __nv_pow path differs at fp64 ULP level between Taichi and nvcc.")
        print("         Cannot achieve bit-exact match without unifying the compiler.")


if __name__ == "__main__":
    main()
