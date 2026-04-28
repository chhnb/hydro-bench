"""Localize the first divergent step on F1_6.7K_fp64 between 900 and 7200.

The SUMMARY.md row for F1_6.7K_fp64 step=7200 reports
``H.max_abs=2.132e-14`` — still within fp64 noise — but step=36000 jumps
to ``H.max_abs=1.606e-05`` and step=72000 to ``5.785e-02``. So the
algorithmic mismatch enters somewhere between step 7200 and 36000. To
narrow the search this probe sweeps a half-decade-spaced ladder and
prints (max_abs, argmax cell, U/V at that cell) so a follow-up round
can drill into the first cell that crosses 1e-9.

The smaller F1_6.7K mesh (6,675 cells vs F1_207K's 207,234) makes
each step fast enough to iterate on the divergence localisation
without paying the 207K Taichi compile + per-step cost. Once the F1
codepath is aligned, the same fix should carry over to F1_207K /
F2_207K (same hydro kernels).

Run::

    python scripts/diag/probe_f1_6.7k_divergence.py
"""
import os
import sys

import numpy as np

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts"))

from check_correctness import dump_native_at_step, dump_taichi_multi_step  # noqa: E402

CASE = "F1_6.7K_fp64"
LADDER = (7200, 10000, 14000, 18000, 22000, 26000, 30000, 36000)


def main():
    print(f"Bisecting {CASE} divergence between step 7200 and 36000 ...")
    # Run Taichi once over the whole ladder via on_step (single warmup).
    taichi_states = dump_taichi_multi_step(CASE, list(LADDER))
    for step in LADDER:
        n = dump_native_at_step(CASE, step)
        t = taichi_states.get(step)
        if n is None or t is None:
            print(f"  step={step}: dump failed")
            continue
        H_n = n["H"].astype(np.float64)
        H_t = t["H"].astype(np.float64)
        m = min(len(H_n), len(H_t))
        diff = np.abs(H_n[:m] - H_t[:m])
        i = int(diff.argmax())
        print(
            f"  step={step:>6d}: H max={diff.max():.3e}  argmax_cell={i}  "
            f"native.U={float(n['U'][i]):+.6e}  taichi.U={float(t['U'][i]):+.6e}  "
            f"native.V={float(n['V'][i]):+.6e}  taichi.V={float(t['V'][i]):+.6e}"
        )


if __name__ == "__main__":
    main()
