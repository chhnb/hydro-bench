"""Reproducible diagnostic for the F1_207K_fp32 step=1 alignment mismatch.

Runs F1_207K_fp32 for one step on both Taichi and the native CUDA fp32
binary, then localizes where the two diverge. The output groups divergent
cells by their KLAS edge signature so the boundary-condition path can be
distinguished from the interior solver.

Usage:
    python scripts/diag/probe_f1_207k_fp32_step1.py

Prerequisites:
    - cuda_native_impl/F2_hydro_native_fp32 built (see cuda_native_impl/fp32_src/build.sh)
    - venv at /home/scratch.huanhuanc_gpu/hydro-bench/venv (or override PY_BIN)

Output: per-field max/mean diff, KLAS-signature histogram of divergent
cells, top-10 worst-cell records with KLAS+NAC, and per-KLAS flux diff.
"""
import os
import sys
import struct
import subprocess

import numpy as np

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NATIVE_DIR = os.path.join(REPO, "cuda_native_impl")
PY_BIN = os.path.join(REPO, "venv", "bin", "python")
if not os.path.isfile(PY_BIN):
    PY_BIN = "/home/scratch.huanhuanc_gpu/spmd/spmd-venv/bin/python"

CASE = "F1_207K_fp32"
NATIVE_BIN = os.path.join(NATIVE_DIR, "F2_hydro_native_fp32")
NATIVE_CWD = os.path.join(NATIVE_DIR, "F1_207K_native_data", "run")
SZ = 4
DTYPE = np.float32


def run_native_step1():
    dump = f"/tmp/probe_native_{CASE}_step1.bin"
    if os.path.exists(dump):
        os.remove(dump)
    r = subprocess.run(
        [NATIVE_BIN, "1", "1", "--dump", dump],
        cwd=NATIVE_CWD,
        capture_output=True,
        text=True,
        timeout=120,
    )
    if r.returncode != 0 or not os.path.exists(dump):
        raise RuntimeError(f"native dump failed: rc={r.returncode}\n{r.stderr[-500:]}")
    return read_native_dump(dump)


def read_native_dump(path):
    with open(path, "rb") as f:
        cell = struct.unpack("i", f.read(4))[0]
        H = np.frombuffer(f.read(cell * SZ), dtype=DTYPE).copy()
        U = np.frombuffer(f.read(cell * SZ), dtype=DTYPE).copy()
        V = np.frombuffer(f.read(cell * SZ), dtype=DTYPE).copy()
        Z = np.frombuffer(f.read(cell * SZ), dtype=DTYPE).copy()
        nsides = cell * 4
        f.read(nsides * SZ * 3)  # SLCOS, SLSIN, SIDE
        F0 = np.frombuffer(f.read(nsides * SZ), dtype=DTYPE).copy()
        F1 = np.frombuffer(f.read(nsides * SZ), dtype=DTYPE).copy()
        F2 = np.frombuffer(f.read(nsides * SZ), dtype=DTYPE).copy()
        F3 = np.frombuffer(f.read(nsides * SZ), dtype=DTYPE).copy()
    return cell, H, U, V, Z, F0, F1, F2, F3


def run_taichi_step1():
    dump = f"/tmp/probe_taichi_{CASE}_step1.bin"
    if os.path.exists(dump):
        os.remove(dump)
    code = f"""
import sys, struct
sys.path.insert(0, {os.path.join(REPO, 'taichi_impl')!r})
from F1_hydro_taichi_2kernel_fp32 import run_real
res = run_real(steps=1, backend='cuda', mesh='20w')
step_fn, sync_fn, H, U, V, Z, F0, F1, F2, F3 = res[:10]
step_fn(); sync_fn()
arrs = [a.to_numpy() for a in (H, U, V, Z, F0, F1, F2, F3)]
with open({dump!r}, 'wb') as f:
    f.write(struct.pack('i', arrs[0].size))
    for a in arrs:
        f.write(a.tobytes())
print('TAICHI_DUMP_OK')
"""
    r = subprocess.run([PY_BIN, "-c", code], capture_output=True, text=True, timeout=240)
    if "TAICHI_DUMP_OK" not in r.stdout:
        raise RuntimeError(f"taichi dump failed: rc={r.returncode}\n{r.stderr[-500:]}")
    with open(dump, "rb") as f:
        cell = struct.unpack("i", f.read(4))[0]
        H = np.frombuffer(f.read(cell * SZ), dtype=DTYPE).copy()
        U = np.frombuffer(f.read(cell * SZ), dtype=DTYPE).copy()
        V = np.frombuffer(f.read(cell * SZ), dtype=DTYPE).copy()
        Z = np.frombuffer(f.read(cell * SZ), dtype=DTYPE).copy()
        nsides = cell * 4
        F0 = np.frombuffer(f.read(nsides * SZ), dtype=DTYPE).copy()
        F1 = np.frombuffer(f.read(nsides * SZ), dtype=DTYPE).copy()
        F2 = np.frombuffer(f.read(nsides * SZ), dtype=DTYPE).copy()
        F3 = np.frombuffer(f.read(nsides * SZ), dtype=DTYPE).copy()
    return cell, H, U, V, Z, F0, F1, F2, F3


def load_klas_nac():
    sys.path.insert(0, os.path.join(REPO, "taichi_impl"))
    import mesh_loader_f1 as mlf1

    m = mlf1.load_hydro_mesh(mesh="20w")
    cel = m["CEL"]
    klas2d = m["KLAS"]
    nac2d = m["NAC"]
    klas = np.zeros(cel * 4, dtype=np.int32)
    nac = np.zeros(cel * 4, dtype=np.int32)
    for c in range(cel):
        for j in range(4):
            klas[4 * c + j] = int(klas2d[j + 1, c + 1])
            nac[4 * c + j] = int(nac2d[j + 1, c + 1])
    return cel, klas, nac


def main():
    print("[1/3] Native CUDA step=1 dump ...")
    nc, nH, nU, nV, nZ, nF0, nF1, nF2, nF3 = run_native_step1()

    print("[2/3] Taichi step=1 dump ...")
    tc, tH, tU, tV, tZ, tF0, tF1, tF2, tF3 = run_taichi_step1()

    n = min(nc, tc)
    nH, tH = nH[:n], tH[:n]
    nU, tU = nU[:n], tU[:n]
    nV, tV = nV[:n], tV[:n]
    nZ, tZ = nZ[:n], tZ[:n]

    print(f"\n[3/3] Cells: native={nc}, taichi={tc}, comparing {n}")
    print(f"=== Per-field diff ===")
    for name, na, ta in (("H", nH, tH), ("U", nU, tU), ("V", nV, tV), ("Z", nZ, tZ)):
        d = np.abs(na - ta)
        print(f"  {name}: max={d.max():.6e}  mean={d.mean():.6e}  nonzero={(d > 0).sum()}/{n}")

    cel, klas, nac = load_klas_nac()
    diff_h = np.abs(nH - tH)
    nonzero = np.where(diff_h > 0)[0]
    print(f"\nDivergent cells (H_diff > 0): {len(nonzero)} / {n}")
    if len(nonzero) == 0:
        return

    from collections import Counter

    sigs = Counter(tuple(sorted(set(klas[4 * c : 4 * (c + 1)].tolist()))) for c in nonzero)
    print("KLAS edge signature histogram (top 10):")
    for sig, count in sorted(sigs.items(), key=lambda x: -x[1])[:10]:
        print(f"  {sig}: {count} cells")

    print("\nTop-10 cells by H diff:")
    top = np.argsort(diff_h)[-10:][::-1]
    for c in top:
        kl = klas[4 * c : 4 * (c + 1)].tolist()
        ne = nac[4 * c : 4 * (c + 1)].tolist()
        print(
            f"  cell={c:6d}  native={nH[c]:.6e}  taichi={tH[c]:.6e}  "
            f"diff={diff_h[c]:.6e}  KLAS={kl}  NAC={ne}"
        )

    print("\nFlux diff per edge KLAS class:")
    for kv in (0, 1, 4, 10):
        mask = klas == kv
        if not mask.any():
            continue
        f0d = np.abs(nF0 - tF0)[mask]
        f3d = np.abs(nF3 - tF3)[mask]
        print(f"  KLAS={kv}: edges={mask.sum()}  F0_max={f0d.max():.6e}  F3_max={f3d.max():.6e}")


if __name__ == "__main__":
    main()
