"""Bit-exact ULP probe across ALL fp64 ops used in OSHER + update_cell.

Goal: find every place Taichi-CUDA and nvcc-CUDA disagree at fp64 level,
not just pow(x, 1.5). Tests one-input math (pow/sqrt/log/exp/cbrt) and
multi-input arithmetic that the LLVM/PTX compilers may contract into
fma differently.

Output: prints a per-op summary (bit-equal / total, max ulp), and lists
the first 5 differing samples per op so we can see which inputs trigger.

Run via slurm on a GLIBC>=2.36 node, e.g.::

    sbatch ... --wrap='cd repo; venv/bin/python scripts/diag/probe_fp64_op_alignment.py'
"""
import os
import struct
import subprocess
import sys
import tempfile

import numpy as np

# Realistic shallow-water values: dry threshold up to ~50m wet column.
SAMPLE_X = np.array(
    [
        0.001, 0.0015, 0.005, 0.01, 0.0123456789,
        0.05, 0.1, 0.5, 1.0, 1.234567890123456,
        2.0, 3.14159265358979, 5.0, 9.81, 10.0,
        25.0, 50.0,
    ],
    dtype=np.float64,
)
# 2-arg samples (a, b) that look like Riemann/flux arithmetic.
SAMPLE_AB = np.array(
    [
        (1.234, 5.678),
        (0.01, 100.0),
        (2.0, 2.0),
        (9.81, 1.5),
        (0.0123456, 0.987654),
        (50.0, 0.001),
        (1e-6, 1e6),
        (3.14159, 2.71828),
    ],
    dtype=np.float64,
)
# 3-arg samples (a, b, c) for fma-style: a*b+c or a*b-c
SAMPLE_ABC = np.array(
    [
        (1.234, 5.678, 9.012),
        (0.5, 0.5, 0.25),
        (9.81, 0.5, 0.0001),
        (2.0, 3.0, -6.0),
        (1e10, 1e-10, 1.0),
        (1.5, 1.5, 2.25),
    ],
    dtype=np.float64,
)


def fp64_to_u64(x):
    return int.from_bytes(struct.pack("<d", float(x)), "little")


def ulp_diff(a, b):
    return abs(fp64_to_u64(a) - fp64_to_u64(b))


# ---- Taichi side ----
def taichi_run():
    import taichi as ti
    ti.init(arch=ti.cuda, default_fp=ti.f64, fast_math=False)

    n1 = len(SAMPLE_X)
    n2 = len(SAMPLE_AB)
    n3 = len(SAMPLE_ABC)

    x = ti.field(dtype=ti.f64, shape=n1)
    a2 = ti.field(dtype=ti.f64, shape=n2)
    b2 = ti.field(dtype=ti.f64, shape=n2)
    a3 = ti.field(dtype=ti.f64, shape=n3)
    b3 = ti.field(dtype=ti.f64, shape=n3)
    c3 = ti.field(dtype=ti.f64, shape=n3)

    out_pow15 = ti.field(dtype=ti.f64, shape=n1)
    out_pow033333 = ti.field(dtype=ti.f64, shape=n1)
    out_sqrt = ti.field(dtype=ti.f64, shape=n1)
    out_log = ti.field(dtype=ti.f64, shape=n1)
    out_exp_log_15 = ti.field(dtype=ti.f64, shape=n1)
    out_x_sqrt_x = ti.field(dtype=ti.f64, shape=n1)

    out_a_mul_sqrt_b = ti.field(dtype=ti.f64, shape=n2)
    out_sqrt_a_mul_b = ti.field(dtype=ti.f64, shape=n2)

    out_ab_plus_c = ti.field(dtype=ti.f64, shape=n3)  # a*b+c
    out_ab_minus_c = ti.field(dtype=ti.f64, shape=n3)  # a*b-c
    out_ab_minus_cd = ti.field(dtype=ti.f64, shape=n3)  # a*b - c*c (uses c twice)

    @ti.kernel
    def k():
        for i in range(n1):
            xv = x[i]
            out_pow15[i] = ti.pow(xv, ti.cast(1.5, ti.f64))
            out_pow033333[i] = ti.pow(xv, ti.cast(0.33333, ti.f64))
            out_sqrt[i] = ti.sqrt(xv)
            out_log[i] = ti.log(xv)
            out_exp_log_15[i] = ti.exp(ti.cast(1.5, ti.f64) * ti.log(xv))
            out_x_sqrt_x[i] = xv * ti.sqrt(xv)
        for i in range(n2):
            av = a2[i]
            bv = b2[i]
            out_a_mul_sqrt_b[i] = av * ti.sqrt(bv)
            out_sqrt_a_mul_b[i] = ti.sqrt(av * bv)
        for i in range(n3):
            av = a3[i]
            bv = b3[i]
            cv = c3[i]
            out_ab_plus_c[i] = av * bv + cv
            out_ab_minus_c[i] = av * bv - cv
            out_ab_minus_cd[i] = av * bv - cv * cv

    x.from_numpy(SAMPLE_X)
    a2.from_numpy(SAMPLE_AB[:, 0].copy())
    b2.from_numpy(SAMPLE_AB[:, 1].copy())
    a3.from_numpy(SAMPLE_ABC[:, 0].copy())
    b3.from_numpy(SAMPLE_ABC[:, 1].copy())
    c3.from_numpy(SAMPLE_ABC[:, 2].copy())
    k()

    return {
        "pow15": out_pow15.to_numpy(),
        "pow033333": out_pow033333.to_numpy(),
        "sqrt": out_sqrt.to_numpy(),
        "log": out_log.to_numpy(),
        "exp_log_15": out_exp_log_15.to_numpy(),
        "x_sqrt_x": out_x_sqrt_x.to_numpy(),
        "a_mul_sqrt_b": out_a_mul_sqrt_b.to_numpy(),
        "sqrt_a_mul_b": out_sqrt_a_mul_b.to_numpy(),
        "ab_plus_c": out_ab_plus_c.to_numpy(),
        "ab_minus_c": out_ab_minus_c.to_numpy(),
        "ab_minus_cd": out_ab_minus_cd.to_numpy(),
    }


# ---- nvcc CUDA side ----
NVCC_KERNELS = r"""
extern "C" __global__
void k_pow15(const double *x, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = pow(x[i], 1.5); }
extern "C" __global__
void k_pow033333(const double *x, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = pow(x[i], 0.33333); }
extern "C" __global__
void k_sqrt(const double *x, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = sqrt(x[i]); }
extern "C" __global__
void k_log(const double *x, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = log(x[i]); }
extern "C" __global__
void k_exp_log_15(const double *x, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = exp(1.5 * log(x[i])); }
extern "C" __global__
void k_x_sqrt_x(const double *x, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = x[i] * sqrt(x[i]); }
extern "C" __global__
void k_a_mul_sqrt_b(const double *a, const double *b, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = a[i] * sqrt(b[i]); }
extern "C" __global__
void k_sqrt_a_mul_b(const double *a, const double *b, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = sqrt(a[i] * b[i]); }
extern "C" __global__
void k_ab_plus_c(const double *a, const double *b, const double *c, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = a[i] * b[i] + c[i]; }
extern "C" __global__
void k_ab_minus_c(const double *a, const double *b, const double *c, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = a[i] * b[i] - c[i]; }
extern "C" __global__
void k_ab_minus_cd(const double *a, const double *b, const double *c, double *y, int n) { int i = blockIdx.x*blockDim.x+threadIdx.x; if (i<n) y[i] = a[i] * b[i] - c[i] * c[i]; }

extern "C" int run_1arg(int kid, const double *xin, double *yout, int n);
extern "C" int run_2arg(int kid, const double *ain, const double *bin, double *yout, int n);
extern "C" int run_3arg(int kid, const double *ain, const double *bin, const double *cin, double *yout, int n);

extern "C" int run_1arg(int kid, const double *xin, double *yout, int n) {
    double *dx, *dy;
    cudaMalloc(&dx, n*sizeof(double));
    cudaMalloc(&dy, n*sizeof(double));
    cudaMemcpy(dx, xin, n*sizeof(double), cudaMemcpyHostToDevice);
    int bs=32, gs=(n+bs-1)/bs;
    if (kid==0) k_pow15<<<gs,bs>>>(dx,dy,n);
    else if (kid==1) k_pow033333<<<gs,bs>>>(dx,dy,n);
    else if (kid==2) k_sqrt<<<gs,bs>>>(dx,dy,n);
    else if (kid==3) k_log<<<gs,bs>>>(dx,dy,n);
    else if (kid==4) k_exp_log_15<<<gs,bs>>>(dx,dy,n);
    else if (kid==5) k_x_sqrt_x<<<gs,bs>>>(dx,dy,n);
    cudaDeviceSynchronize();
    cudaMemcpy(yout, dy, n*sizeof(double), cudaMemcpyDeviceToHost);
    cudaFree(dx); cudaFree(dy);
    return 0;
}
extern "C" int run_2arg(int kid, const double *ain, const double *bin, double *yout, int n) {
    double *da,*db,*dy;
    cudaMalloc(&da,n*sizeof(double)); cudaMalloc(&db,n*sizeof(double)); cudaMalloc(&dy,n*sizeof(double));
    cudaMemcpy(da,ain,n*sizeof(double),cudaMemcpyHostToDevice);
    cudaMemcpy(db,bin,n*sizeof(double),cudaMemcpyHostToDevice);
    int bs=32, gs=(n+bs-1)/bs;
    if (kid==0) k_a_mul_sqrt_b<<<gs,bs>>>(da,db,dy,n);
    else if (kid==1) k_sqrt_a_mul_b<<<gs,bs>>>(da,db,dy,n);
    cudaDeviceSynchronize();
    cudaMemcpy(yout,dy,n*sizeof(double),cudaMemcpyDeviceToHost);
    cudaFree(da); cudaFree(db); cudaFree(dy);
    return 0;
}
extern "C" int run_3arg(int kid, const double *ain, const double *bin, const double *cin, double *yout, int n) {
    double *da,*db,*dc,*dy;
    cudaMalloc(&da,n*sizeof(double)); cudaMalloc(&db,n*sizeof(double));
    cudaMalloc(&dc,n*sizeof(double)); cudaMalloc(&dy,n*sizeof(double));
    cudaMemcpy(da,ain,n*sizeof(double),cudaMemcpyHostToDevice);
    cudaMemcpy(db,bin,n*sizeof(double),cudaMemcpyHostToDevice);
    cudaMemcpy(dc,cin,n*sizeof(double),cudaMemcpyHostToDevice);
    int bs=32, gs=(n+bs-1)/bs;
    if (kid==0) k_ab_plus_c<<<gs,bs>>>(da,db,dc,dy,n);
    else if (kid==1) k_ab_minus_c<<<gs,bs>>>(da,db,dc,dy,n);
    else if (kid==2) k_ab_minus_cd<<<gs,bs>>>(da,db,dc,dy,n);
    cudaDeviceSynchronize();
    cudaMemcpy(yout,dy,n*sizeof(double),cudaMemcpyDeviceToHost);
    cudaFree(da); cudaFree(db); cudaFree(dc); cudaFree(dy);
    return 0;
}
"""


def nvcc_run():
    import ctypes
    with tempfile.TemporaryDirectory() as td:
        src = os.path.join(td, "k.cu")
        with open(src, "w") as f:
            f.write(NVCC_KERNELS)
        lib = os.path.join(td, "libk.so")
        # --fmad=false matches the native build flags exactly.
        r = subprocess.run(
            ["nvcc", "-O3", "--fmad=false", "-Xcompiler", "-fPIC",
             "-shared", src, "-o", lib],
            capture_output=True, text=True,
        )
        if r.returncode != 0:
            sys.stderr.write(r.stderr)
            raise RuntimeError("nvcc build failed")

        dll = ctypes.CDLL(lib)
        for fn in ("run_1arg", "run_2arg", "run_3arg"):
            getattr(dll, fn).restype = ctypes.c_int

        n1 = len(SAMPLE_X)
        n2 = len(SAMPLE_AB)
        n3 = len(SAMPLE_ABC)

        def call_1(kid):
            xin = (ctypes.c_double * n1)(*SAMPLE_X)
            yout = (ctypes.c_double * n1)()
            dll.run_1arg(kid, xin, yout, n1)
            return np.array(list(yout), dtype=np.float64)

        def call_2(kid):
            ain = (ctypes.c_double * n2)(*SAMPLE_AB[:, 0])
            bin_ = (ctypes.c_double * n2)(*SAMPLE_AB[:, 1])
            yout = (ctypes.c_double * n2)()
            dll.run_2arg(kid, ain, bin_, yout, n2)
            return np.array(list(yout), dtype=np.float64)

        def call_3(kid):
            ain = (ctypes.c_double * n3)(*SAMPLE_ABC[:, 0])
            bin_ = (ctypes.c_double * n3)(*SAMPLE_ABC[:, 1])
            cin = (ctypes.c_double * n3)(*SAMPLE_ABC[:, 2])
            yout = (ctypes.c_double * n3)()
            dll.run_3arg(kid, ain, bin_, cin, yout, n3)
            return np.array(list(yout), dtype=np.float64)

        return {
            "pow15": call_1(0),
            "pow033333": call_1(1),
            "sqrt": call_1(2),
            "log": call_1(3),
            "exp_log_15": call_1(4),
            "x_sqrt_x": call_1(5),
            "a_mul_sqrt_b": call_2(0),
            "sqrt_a_mul_b": call_2(1),
            "ab_plus_c": call_3(0),
            "ab_minus_c": call_3(1),
            "ab_minus_cd": call_3(2),
        }


def compare(name, taichi_arr, nvcc_arr, samples):
    n = len(taichi_arr)
    n_match = 0
    n_diff = 0
    max_ulp = 0
    diffs = []
    for i in range(n):
        u = ulp_diff(taichi_arr[i], nvcc_arr[i])
        if u == 0:
            n_match += 1
        else:
            n_diff += 1
            max_ulp = max(max_ulp, u)
            diffs.append((i, samples[i], taichi_arr[i], nvcc_arr[i], u))
    return n_match, n_diff, max_ulp, diffs


def main():
    print("=" * 78)
    print("fp64 op-alignment probe: Taichi-CUDA vs nvcc-CUDA(--fmad=false)")
    print("=" * 78)

    t = taichi_run()
    n = nvcc_run()

    one_arg = ["pow15", "pow033333", "sqrt", "log", "exp_log_15", "x_sqrt_x"]
    two_arg = ["a_mul_sqrt_b", "sqrt_a_mul_b"]
    three_arg = ["ab_plus_c", "ab_minus_c", "ab_minus_cd"]

    print()
    print(f"{'op':<24}  {'#total':>7}  {'#match':>7}  {'#diff':>6}  {'max ulp':>7}")
    print("-" * 78)

    rows = []
    for name in one_arg:
        m, d, mu, diffs = compare(name, t[name], n[name], SAMPLE_X)
        rows.append((name, len(t[name]), m, d, mu, diffs))
        print(f"{name:<24}  {len(t[name]):>7d}  {m:>7d}  {d:>6d}  {mu:>7d}")
    for name in two_arg:
        m, d, mu, diffs = compare(name, t[name], n[name], SAMPLE_AB)
        rows.append((name, len(t[name]), m, d, mu, diffs))
        print(f"{name:<24}  {len(t[name]):>7d}  {m:>7d}  {d:>6d}  {mu:>7d}")
    for name in three_arg:
        m, d, mu, diffs = compare(name, t[name], n[name], SAMPLE_ABC)
        rows.append((name, len(t[name]), m, d, mu, diffs))
        print(f"{name:<24}  {len(t[name]):>7d}  {m:>7d}  {d:>6d}  {mu:>7d}")

    print()
    print("=" * 78)
    print("First 5 differing samples per op (where diff>0):")
    print("=" * 78)
    for name, _total, _m, d, _mu, diffs in rows:
        if d == 0:
            continue
        print(f"\n[{name}]")
        for i, sample, tval, nval, u in diffs[:5]:
            print(f"  i={i}  input={sample}")
            print(f"    taichi=  {fp64_to_u64(tval):020X}  ({tval!r})")
            print(f"    nvcc  =  {fp64_to_u64(nval):020X}  ({nval!r})  ulp={u}")

    print()
    print("=" * 78)
    print("Verdict")
    print("=" * 78)
    bit_equal_ops = [r[0] for r in rows if r[3] == 0]
    bit_diff_ops = [(r[0], r[3], r[1], r[4]) for r in rows if r[3] > 0]
    print(f"\nBit-equal ops ({len(bit_equal_ops)}):")
    for op in bit_equal_ops:
        print(f"  {op}")
    print(f"\nBit-different ops ({len(bit_diff_ops)}):")
    for op, d, total, mu in bit_diff_ops:
        print(f"  {op}  ({d}/{total} differ, max ulp = {mu})")


if __name__ == "__main__":
    main()
