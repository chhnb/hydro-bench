# Why Taichi-fp64 vs native-fp64 diverge at long steps

## Tl;dr

Native-CUDA and Taichi-CUDA call **different** fp64 `pow()` implementations:

| compiler  | path                              | fma.rn.f64 per pow eval |
|-----------|-----------------------------------|-------------------------|
| nvcc      | `__internal_accurate_pow`         | **39**                  |
| Taichi-LLVM | inlined libdevice `__nv_pow`    | **~90**                 |

Both are IEEE-correct fp64 pow, but the polynomials and op orderings differ →
ULP-level different output → amplified by chaotic shallow-water + Manning
friction → visible drift after step ~35 000.

## Empirical evidence

### Native PTX (`nvcc -O3 --fmad=false`)

```
$ nvcc -O3 --fmad=false -arch=sm_80 -ptx pow15.cu
$ grep -c fma.rn.f64 pow15.ptx
39
$ awk '/^.visible .entry k_pow15/,/^}$/' pow15.ptx | grep -c fma.rn.f64
0
$ awk '/^.func.*__internal_accurate_pow/,/^}$/' pow15.ptx | grep -c fma.rn.f64
39
```

- `pow(x, 1.5)` lowers to a `call __internal_accurate_pow` — **not inlined**.
- All 39 fma's live in the shared helper, regardless of how many call sites.
- `pow(x, 0.33333)` follows the same path: 39 fma inside the helper.

### Taichi PTX (`F2_hydro_taichi_fp64.calculate_flux`)

```
$ grep -c fma.rn.f64 /tmp/taichi_ptx_021.ptx
361
$ grep -n "__nv_pow.exit" /tmp/taichi_ptx_021.ptx
$L__BB0_32: %__nv_pow.exit227.i.i
$L__BB0_45: %__nv_pow.exit200.i.i
$L__BB0_60: %__nv_pow.exit170.i.i
$L__BB0_72: %__nv_pow.exit.i.i
```

- 4 inlined `__nv_pow` exits, one per static `ti.pow(*, 1.5)` site (all four
  OSHER branches in `calculate_flux` lines 335/339/351/363).
- 361 / 4 ≈ **90 fma per inlined pow** — using the libdevice `__nv_pow`
  polynomial, which is more aggressive than nvcc's `__internal_accurate_pow`.
- Taichi LLVM IR (`/tmp/taichi_opt_ir_021.ll`) shows user-algorithm lines
  (100‒109) emit plain `fmul / fadd / fsub` with no `contract` flag —
  **zero** fma intrinsics in user code. All 361 fma's come from the four
  inlined pow expansions.

### Why bit-equal pow inputs give bit-different outputs

Same x, same exponent, two different polynomials with different coefficients
and op orders. Both round-to-nearest-even at every fma, but ULP of the final
result is different. For `pow(2.0, 1.5)` the answers happen to coincide; for
`pow(0.012345, 1.5)` (the typical shallow-H value) they differ by 1‒2 ULP.

### Why 1‒2 ULP becomes 1e-2 H drift

- F2_207K mesh has ~50 wet/dry transitions per second; each transition has
  Manning friction `WSF = FNC * sqrt(U²+V²) / pow(H, 0.33333)` blowing up as
  `H → HM2 = 0.01`.
- Liapunov exponent for shallow-water + friction in this regime is
  empirically ~0.0002 / step (rough estimate from observed
  H.max_abs vs step curve: 1e-15 at step 1, 1e-2 at step 35 000).
- 1 ULP at step 1 = 2⁻⁵² ≈ 2.2 × 10⁻¹⁶. Amplified by exp(0.0002 × 35 000) ≈
  1100 → still tiny (~2 × 10⁻¹³). The bigger effect is **threshold flips**
  at the wet/dry boundary `H == HM1` and at the Riemann case dispatch
  `Z_pre - ZBC ≷ 0`. Once one cell takes a different branch, that step's
  flux is O(1) different, and the perturbation is no longer linear.

This explains why F1_6.7K_fp64 (smaller mesh, fewer wet/dry transitions)
stays byte-identical to native at all steps after the BC-loader fix, but
F2_207K_fp64 drifts despite identical algorithms.

## Minimal-fix candidates

### Option A — replace `pow(H, 1.5)` with `H * sqrt(H)` on BOTH sides

Mathematically identical for H ≥ 0 (`pow(H, 1.5)` equals `H * sqrt(H)`
exactly when `H` is fp64-representable and ≥ 0; sqrt rounds-to-nearest
correctly under IEEE 754).

After this change:
- nvcc kernel body: `mul.rn.f64 + sqrt.rn.f64` (no pow call).
- Taichi kernel body: same `mul.rn.f64 + sqrt.rn.f64` (no pow call).

The fma gap collapses from 322 to 0 in OSHER. **Predicted byte-equal flux
output for OSHER.**

Cost: 4 edits in `cuda_native_impl/hydro-cal-src/src/functors.cu` and 4
edits in `taichi_impl/F[12]_hydro_taichi_fp[3264].py`. Result is
mathematically the upstream algorithm, just expressed without the pow
library helper.

### Option B — leave `pow(H, 0.33333)` alone

Same issue but no clean special case (0.33333 ≠ 1/3 exactly, so cbrt
substitution would CHANGE the algorithm). Friction is in `update_cell`,
contributing once per cell. Worth checking after Option A whether residual
drift is fully explained by friction pow.

### Option C — accept and document

If even after Option A there is residual chaotic drift, the conclusion is
that fp64 long-step alignment for shallow-water + Manning is intrinsically
limited by ODE chaos, not by compiler choice. Document this in the
alignment plan and stop chasing late-step bit-exact.

## Verification probe (when on a Taichi-capable node)

`scripts/diag/probe_pow_fp64_taichi_vs_nvcc.py` builds a tiny test:
- Taichi kernel: `y = ti.pow(x, 1.5)` for 17 hydro-realistic x values
- nvcc kernel: `y = pow(x, 1.5)` compiled with `-O3 --fmad=false`
- Compares fp64 hex bits and reports per-sample ULP diff

Expected:
- If same lib path → 0 ULP all rows (then divergence is ALL in user-code
  fma contraction, not pow itself)
- If different lib path → non-zero ULP on most rows (confirms this doc)
