"""Localize the first divergent step on F1_6.7K_fp64 starting at 900.

The SUMMARY.md rows for F1_6.7K_fp64 show

    step=900   H.max_abs=1.78e-14  (fp64 noise)
    step=7200  H.max_abs=2.13e-14  (fp64 noise)
    step=36000 H.max_abs=1.61e-05  (above 1e-9)
    step=72000 H.max_abs=5.79e-02  (gross divergence)

So the algorithmic mismatch crosses 1e-9 somewhere between step 7200
and 36000. Codex's round-3 review demanded a probe that starts in the
still-clean window (i.e. 900 upward) so the first crossing can be
isolated, not just confirmed-divergent at a later step.

Strategy: walk a fine ladder from 900 upward and, for each step,
print ``H max_abs``, ``argmax_cell`` index, the ``KLAS`` of that cell
and its four neighbours, and the per-side ``H/U/V/Z/F0..F3`` at the
divergent cell. The first row whose ``H.max_abs`` crosses ``1e-9`` is
the localized divergence step; the cell + KLAS + flux pair is the
input to the round-5 OSHER alignment work building on
``probe_207k_divergence.py`` and ``probe_osher_cell.py``.

The smaller F1_6.7K mesh (6,675 cells vs F1_207K's 207,234) keeps the
per-step native dump fast enough that this ladder runs in a few
minutes once the GPU is free.

Run::

    python scripts/diag/probe_f1_6.7k_divergence.py
"""
import os
import sys

import numpy as np

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts"))

from check_correctness import dump_native_at_step, dump_taichi_multi_step, load_mesh_metadata  # noqa: E402

CASE = "F1_6.7K_fp64"
# Round 5 fine-bisect: round-4 + round-5 first pass localized the
# crossing to (35500, 36000). Within that 500-step window the H state
# jumps by ~10 orders of magnitude in one shot, so the actual entry
# is within ~50 steps. Sample at 50-step resolution inside (35500,
# 36000) to nail the entry step. The earlier 30K..35500 sweep is
# preserved as the long-baseline view.
LADDER = (
    900, 7200, 18000, 30000,
    35500, 35550, 35600, 35650, 35700, 35750, 35800, 35850, 35900,
    35950, 36000,
)


def main():
    print(f"Bisecting {CASE} divergence starting at step 900 ...")
    area, klas_edge, nac_edge, side_edge = load_mesh_metadata(CASE)
    n_cells = int(len(area))

    # Run Taichi once over the whole ladder via on_step (single warmup).
    taichi_states = dump_taichi_multi_step(CASE, list(LADDER))
    first_crossing = None
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
        max_abs = float(diff.max())
        i = int(diff.argmax())
        cell_klas = [int(klas_edge[4 * i + j]) for j in range(4)] if 4 * i + 3 < len(klas_edge) else []
        # Neighbour KLAS for the diverging cell -- the OSHER probe
        # path needs both the cell's edge classifications and what's
        # across each edge.
        neighbour_klas = []
        for j in range(4):
            neigh = int(nac_edge[4 * i + j]) - 1
            if 0 <= neigh < n_cells:
                neighbour_klas.append([int(klas_edge[4 * neigh + k]) for k in range(4)])
            else:
                neighbour_klas.append(None)
        crossed = max_abs >= 1e-9
        marker = "  *FIRST CROSSING*" if crossed and first_crossing is None else ""
        if crossed and first_crossing is None:
            first_crossing = step
        print(
            f"  step={step:>6d}: H max={max_abs:.3e}  argmax_cell={i}  "
            f"klas={cell_klas}  H_native={float(n['H'][i]):+.6e}  "
            f"H_taichi={float(t['H'][i]):+.6e}{marker}"
        )
        if crossed and first_crossing == step:
            print(f"    neighbour_klas={neighbour_klas}")
            print(f"    U_native={float(n['U'][i]):+.6e}  U_taichi={float(t['U'][i]):+.6e}")
            print(f"    V_native={float(n['V'][i]):+.6e}  V_taichi={float(t['V'][i]):+.6e}")
            print(f"    Z_native={float(n['Z'][i]):+.6e}  Z_taichi={float(t['Z'][i]):+.6e}")
            for j in range(4):
                ei = 4 * i + j
                print(f"    edge j={j}: F0_native={float(n['F0'][ei]):+.6e} F0_taichi={float(t['F0'][ei]):+.6e}  "
                      f"F1 d={float(n['F1'][ei]) - float(t['F1'][ei]):+.6e}")

    if first_crossing is None:
        print(f"\nNo crossing of 1e-9 in the ladder; extend it past {LADDER[-1]}.")
    else:
        print(f"\nFirst H.max_abs >= 1e-9 step: {first_crossing}.")


if __name__ == "__main__":
    main()
