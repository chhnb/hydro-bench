"""Probe FI() parity between native ``MeshData::FI`` and Python
``output_writer._flow_angle``.

The two implementations agree byte-for-byte when called with identical
fp64 ``(u, v)`` inputs (see the test grid below). The residual ZUV.OUT
FI rounding mismatch at ``F2_24K_fp64`` step >= 900 is therefore NOT a
formula-translation bug — it is the downstream amplification of
fp64 state noise:

  cell 1186  step=900:
      native U=5.2109009834e-09  V=1.1437611750e-09  →  FI=12.3802387069
      taichi U=5.2109019965e-09  V=1.1437629708e-09  →  FI=12.3802552132
                  dU=+1.0e-15        dV=+1.8e-15           dFI≈+1.7e-5

The 1e-15 fp64 noise on U/V at magnitudes near the 1e-9 snap-to-zero
threshold gets amplified by ``atan2``'s gain (~|V|⁻¹ at small V/U) into
a ~1e-5 degree FI noise, enough to flip the 4-decimal half-way
rounding. The fix path is to tighten upstream state parity
(conservation/divergence work) so U/V agree at fp64 ULP level.

Run::

    python scripts/diag/probe_fi_parity.py
"""
import math
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts"))
sys.path.insert(0, os.path.join(REPO, "taichi_impl"))

from output_writer import _flow_angle  # noqa: E402


def native_FI_in_python(X, Y):
    """Statement-by-statement port of ``MeshData::FI`` (mesh.cpp:841)."""
    if abs(X) < 1e-9:
        X = 0.0
    if abs(Y) < 1e-9:
        Y = 0.0
    MPI = 3.1416
    if X * Y != 0.0:
        W = math.atan2(abs(Y), abs(X))
        if X * Y > 0.0:
            FI = W if X > 0.0 else MPI + W
        else:
            FI = MPI - W if Y > 0.0 else 2 * MPI - W
    else:
        FI = 0.0
        if X == 0.0 and Y >= 0.0:
            FI = MPI / 2
        if X == 0.0 and Y < 0.0:
            FI = 3 * MPI / 2
        if Y == 0.0 and X >= 0.0:
            FI = 0.0
        if Y == 0.0 and X < 0.0:
            FI = MPI
    return FI * 57.298


GRID = [
    (1.0, 0.5),
    (0.001, 0.0001),
    (1e-9, 1e-9),
    (1e-10, 1e-9),
    (5e-10, 5e-10),
    (-0.1, 0.05),
    (0.1, -0.05),
    (-0.1, -0.05),
    (1e-15, 1e-15),
    (0.05, 0.0),
    (0.0, 0.05),
    (1.5, 1e-9),
    (0.123456789, 0.987654321),
    # Real-world cells from F2_24K_fp64 step=900 (native-side U/V values
    # that fed FI on the native writer):
    (5.2109009834378765e-09, 1.1437611750067024e-09),
    (9.432925251900152e-08, 1.4433338950897618e-09),
    (2.8888893602684582e-08, 6.4591058956440735e-09),
]


def main():
    n_diff = 0
    for u, v in GRID:
        a = _flow_angle(u, v)
        b = native_FI_in_python(u, v)
        if a != b:
            n_diff += 1
            print(f"  FAIL u={u!r}, v={v!r}: python={a!r} native={b!r}")
    print(f"Probed {len(GRID)} cases, {n_diff} disagreements (expect 0).")


if __name__ == "__main__":
    main()
