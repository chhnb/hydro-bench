# Real root cause of Taichi-vs-native fp64 drift: hardcoded `unsafe-fp-math=true`

## What we proved (empirical)

Probe `scripts/diag/probe_fp64_op_alignment.py` on `ipp1-1621` (slurm
batch, GLIBC 2.39, Taichi 1.8.0):

| op                | #diff/total | max ULP                 | bit-equal? |
|-------------------|-------------|-------------------------|------------|
| `pow(x, 1.5)`     | 4 / 17      | 1                       | mostly     |
| `pow(x, 0.33333)` | 2 / 17      | 1                       | mostly     |
| `sqrt`, `log`     | 0 / 17      | 0                       | YES        |
| `exp(c·log(x))`   | 0 / 17      | 0                       | YES        |
| `x * sqrt(x)`     | 0 / 17      | 0                       | YES        |
| `a * sqrt(b)`     | 0 / 8       | 0                       | YES        |
| `a*b + c`         | 0 / 6       | 0                       | (no cancel)|
| `a*b - c*c`       | 0 / 6       | 0                       | (no cancel)|
| **`a*b - c`**     | **1 / 6**   | **catastrophic (~10¹⁶)**| **NO**     |

The `ab_minus_c` row is the smoking gun. Input `(a,b,c) = (1e10, 1e-10, 1.0)`:

```
Taichi:  3.643e-17    (= residue from fma(a,b,-c) infinite-precision then round-once)
nvcc:    0.0          (= mul produces 1.0 exactly, then 1.0 - 1.0 = 0.0)
```

## What's wrong

Dumped Taichi's optimized LLVM IR for `y = a*b - c` (file
`_ir_dump/taichi_opt_ir_004.ll`):

```llvm
%9 = fmul double %6, %8        ; plain fmul, no `contract` flag
%12 = fsub double %9, %11      ; plain fsub, no `contract` flag

; --- but ---
attributes #0 = {
    mustprogress nofree nounwind willreturn
    "denormal-fp-math-f32"="preserve-sign"
    "unsafe-fp-math"="true"     ; <-- HERE
}
```

**Taichi 1.8 hardcodes `unsafe-fp-math=true` on every kernel function**,
regardless of `ti.init(fast_math=False)`. With this attribute set, the
NVPTX backend is free to fuse `fmul + fsub` into a single `fma.rn.f64`
even though the per-op IR has no `contract` flag.

PTX confirms:

```ptx
neg.f64       %fd4, %fd3            ; fd4 = -c
fma.rn.f64    %fd5, %fd1, %fd2, %fd4 ; fd5 = a*b + (-c) = fma(a, b, -c)
```

## Flag enumeration: nothing in Python API turns it off

Probe `scripts/diag/probe_taichi_fma_flags.py` tested 14 combinations
(every plausible `ti.init` kwarg + 6 env vars). **All return 3.643e-17.**
The hardcoding is in Taichi's C++ `taichi_python.so`, not exposed.

## Why `pow` ULP diffs are smaller than this fma diff

`pow` returns 1 ULP off because the two libdevice paths
(`__internal_accurate_pow` vs `__nv_pow`) implement equivalent
polynomials with slightly different op orders. That's fundamental and
not user-controllable.

`a*b - c` differing by 10¹⁶ ULP at *one* sample is much larger and
**every** Riemann/flux ops in OSHER + update_cell hits this pattern
many times per cell per step. This is the dominant amplifier of
F2_207K_fp64 long-step drift.

## Three fix paths

### Path 1 — change native to allow fma (one-line, low risk)

Edit `cuda_native_impl/build.sh`:

```diff
- nvcc -O3 -arch=$ARCH -rdc=true --std=c++17 --fmad=false \
+ nvcc -O3 -arch=$ARCH -rdc=true --std=c++17 \
```

Both compilers now contract `a*b ± c` into fma. Predicted impact:
F2_207K_fp64 H drift should reduce from ~1e-2 toward fp64 noise (with
residual coming only from pow 1-ULP path).

**Risk**: native bench output diverges from upstream `/spmd/hydro-cal`
*if upstream also uses `--fmad=false`*. Need to check upstream build
flags; if they match this change, no risk.

### Path 2 — patch Taichi C++ source to honour `fast_math=False`

Find the line in `taichi/codegen/llvm/codegen_llvm.cpp` (or wherever
`unsafe-fp-math` attribute is set on every function), gate it on the
`fast_math` config flag, rebuild Taichi from source.

**Cost**: a few hours of source navigation + Taichi build (LLVM 15
required). High value: `fast_math=False` finally means what it says.

### Path 3 — accept and document

If Path 1 affects upstream parity and Path 2 is too expensive, accept
that fp64 byte-equal alignment between Taichi 1.8 and nvcc-with-fmad-off
is **not achievable without modifying one of the toolchains**. Document
this and define alignment success at "≤1 ULP per op" rather than bit-equal.

## Recommendation

Try Path 1 first as a low-cost experiment. Run the alignment matrix once
with native built without `--fmad=false`, see if F2_207K drift drops to
near-zero. If yes, choose between (a) keep native fmad-on permanently
(documenting the deviation from upstream build flags), (b) escalate to
Path 2 for a clean Taichi-side fix.

If the result is "no, drift stays at 1e-2 even with both fma'ing the
same way", then there's a third unknown source we haven't found yet,
and we'd need to keep digging.
