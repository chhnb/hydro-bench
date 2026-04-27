"""Compare F1 vs F2 mesh loader geometry output for the 207K mesh.

The two loaders read the same input files (md5-identical), but F1's
loader computes SIDE/COSF/SINF/AREA in fp64 throughout, while F2's loader
respects the caller's `dtype` argument. The native fp32 build computes
the same geometry directly in fp32. Hence the F2 loader matches native
fp32 bit-for-bit while the F1 loader does not — and that explains why
F1_207K_fp32 step=1 has H max_abs=4e-5 (vs sub-ulp on F2).

Run: python scripts/diag/probe_loader_geometry.py
"""
import os
import sys

import numpy as np

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "taichi_impl"))


def main():
    import mesh_loader_f1 as mlf1
    import mesh_loader_f2 as mlf2

    # F1 loader now accepts a `dtype` kwarg (default fp64). Pass fp32 so the
    # geometry math runs in fp32 and matches F2's fp32 output.
    m1 = mlf1.load_hydro_mesh(mesh="20w", dtype=np.float32)
    m2 = mlf2.load_mesh(mesh="20w", dtype=np.float32)

    cel = m1["CEL"]

    def f1_cell(arr):
        # F1 stores cells as 1-indexed length CEL+1. Drop the sentinel.
        return np.asarray(arr)[1:].astype(np.float32)

    def f1_edges(arr2d):
        # F1 edges are 2D [j+1, cell+1]. Reshape to flat [4*cell + j].
        a = np.asarray(arr2d)[1:, 1:]  # (4, CEL)
        return a.T.reshape(-1).astype(np.float32)

    pairs = [
        ("H_init", f1_cell(m1["H"]), m2["H"]),
        ("Z_init", f1_cell(m1["Z"]), m2["Z"]),
        ("ZBC", f1_cell(m1["ZBC"]), m2["ZBC"]),
        ("ZB1", f1_cell(m1["ZB1"]), m2["ZB1"]),
        ("AREA", f1_cell(m1["AREA"]), m2["AREA"]),
        ("KLAS", f1_edges(m1["KLAS"]), m2["KLAS"].astype(np.float32)),
        ("NAC", f1_edges(m1["NAC"]), m2["NAC"].astype(np.float32)),
        ("SIDE", f1_edges(m1["SIDE"]), m2["SIDE"]),
        ("COSF", f1_edges(m1["COSF"]), m2["COSF"]),
        ("SINF", f1_edges(m1["SINF"]), m2["SINF"]),
        ("SLCOS", f1_edges(m1["SLCOS"]), m2["SLCOS"]),
        ("SLSIN", f1_edges(m1["SLSIN"]), m2["SLSIN"]),
    ]

    print(f"F1 loader vs F2 loader (mesh=20w, dtype=fp32)")
    print(f"{'field':<10s} {'max_abs_diff':>14s} {'nonzero':>10s} / total")
    for name, a, b in pairs:
        a = np.asarray(a, dtype=np.float64).flatten()
        b = np.asarray(b, dtype=np.float64).flatten()
        n = min(len(a), len(b))
        a, b = a[:n], b[:n]
        diff = np.abs(a - b)
        print(f"  {name:<10s} {diff.max():>14.6e} {int((diff > 0).sum()):>10d} / {n}")


if __name__ == "__main__":
    main()
