"""Per-step bisect of the F1_6.7K_fp64 divergence trigger.

Round 5 narrowed the entry to a 50-step window (35950, 36000). The
H.max_abs profile inside the window was probed at 50-step resolution
and showed fp64 noise (4e-14) right up to step=35950, then 1.61e-05
at step=36000 — a single-event trigger.

This probe walks every step from ``WINDOW_LO`` (default 35950) to
``WINDOW_HI`` (default 36000) on both sides:

  - Taichi: one in-process run via ``dump_taichi_multi_step`` with
    ``on_step`` capturing every step in the window.
  - Native: ``WINDOW_HI - WINDOW_LO + 1`` native binary invocations
    (each runs from initial state up to step ``s``). For F1_6.7K each
    run is fast enough (~5-10s) that 51 of them finish in <10 min.

For each step it prints H.max_abs and the argmax cell's metadata
(KLAS, H/U/V/Z on both sides, per-edge F0..F3 deltas). The first
step whose H.max_abs crosses ``1e-12`` is the trigger step; round-7
work picks up the OSHER intermediates at that exact (step, cell).

Run::

    python scripts/diag/probe_f1_6.7k_step_trigger.py
"""
import os
import sys

import numpy as np

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts"))

from check_correctness import (  # noqa: E402
    dump_native_at_step,
    dump_taichi_multi_step,
    load_mesh_metadata,
)

CASE = "F1_6.7K_fp64"
WINDOW_LO = 35950
WINDOW_HI = 36000
TRIGGER_THRESHOLD = 1e-12

# Conserve Taichi compile budget by always sweeping from WINDOW_LO-1
# to WINDOW_HI inclusive. The earlier-step diff at WINDOW_LO-1 anchors
# the noise-floor baseline so the per-step delta is interpretable.
LADDER = list(range(WINDOW_LO, WINDOW_HI + 1))


def _summarize(step, n, t, klas_edge, nac_edge, n_cells):
    H_n = n["H"].astype(np.float64)
    H_t = t["H"].astype(np.float64)
    m = min(len(H_n), len(H_t))
    diff = np.abs(H_n[:m] - H_t[:m])
    max_abs = float(diff.max())
    i = int(diff.argmax())
    cell_klas = (
        [int(klas_edge[4 * i + j]) for j in range(4)]
        if 4 * i + 3 < len(klas_edge) else []
    )
    return max_abs, i, cell_klas, diff


def main():
    print(f"Per-step bisect of {CASE} trigger inside ({WINDOW_LO}, {WINDOW_HI})")
    area, klas_edge, nac_edge, side_edge = load_mesh_metadata(CASE)
    n_cells = int(len(area))

    print(f"  Running Taichi once over {len(LADDER)} checkpoints ...")
    taichi_states = dump_taichi_multi_step(CASE, LADDER)

    trigger_step = None
    for step in LADDER:
        n = dump_native_at_step(CASE, step)
        t = taichi_states.get(step)
        if n is None or t is None:
            print(f"  step={step}: dump failed")
            continue
        max_abs, i, cell_klas, _diff = _summarize(
            step, n, t, klas_edge, nac_edge, n_cells,
        )
        crossed = max_abs >= TRIGGER_THRESHOLD
        marker = "  *TRIGGER*" if crossed and trigger_step is None else ""
        print(
            f"  step={step:>6d}: H max_abs={max_abs:.3e}  "
            f"argmax_cell={i}  klas={cell_klas}{marker}"
        )
        if crossed and trigger_step is None:
            trigger_step = step
            # Dump full divergence metadata at the trigger step.
            print(f"    --- trigger metadata at step={step}, cell={i} ---")
            print(f"    H_native={float(n['H'][i]):+.16e}")
            print(f"    H_taichi={float(t['H'][i]):+.16e}")
            print(f"    U_native={float(n['U'][i]):+.16e}  U_taichi={float(t['U'][i]):+.16e}")
            print(f"    V_native={float(n['V'][i]):+.16e}  V_taichi={float(t['V'][i]):+.16e}")
            print(f"    Z_native={float(n['Z'][i]):+.16e}  Z_taichi={float(t['Z'][i]):+.16e}")
            for j in range(4):
                ei = 4 * i + j
                f0d = float(n["F0"][ei]) - float(t["F0"][ei])
                f1d = float(n["F1"][ei]) - float(t["F1"][ei])
                f2d = float(n["F2"][ei]) - float(t["F2"][ei])
                f3d = float(n["F3"][ei]) - float(t["F3"][ei])
                neigh = int(nac_edge[4 * i + j]) - 1
                neigh_klas = (
                    [int(klas_edge[4 * neigh + k]) for k in range(4)]
                    if 0 <= neigh < n_cells else None
                )
                print(
                    f"    edge j={j}: klas={int(klas_edge[ei])} neighbour_cell={neigh} "
                    f"neighbour_klas={neigh_klas}"
                )
                print(
                    f"      F0_native={float(n['F0'][ei]):+.6e}  d={f0d:+.6e}   "
                    f"F1 d={f1d:+.6e}   F2 d={f2d:+.6e}   F3 d={f3d:+.6e}"
                )
            # Also dump the previous step's diff at this cell so we
            # can see what was already off ONE STEP BEFORE the trigger.
            prev_step = step - 1
            n_prev = dump_native_at_step(CASE, prev_step) if prev_step >= WINDOW_LO else None
            t_prev = taichi_states.get(prev_step)
            if n_prev is not None and t_prev is not None:
                print(f"    --- one step earlier (step={prev_step}, same cell={i}) ---")
                print(
                    f"    H_native={float(n_prev['H'][i]):+.16e}  "
                    f"H_taichi={float(t_prev['H'][i]):+.16e}  "
                    f"|d|={abs(float(n_prev['H'][i]) - float(t_prev['H'][i])):.3e}"
                )
                print(
                    f"    U_native={float(n_prev['U'][i]):+.16e}  "
                    f"U_taichi={float(t_prev['U'][i]):+.16e}  "
                    f"|d|={abs(float(n_prev['U'][i]) - float(t_prev['U'][i])):.3e}"
                )

    if trigger_step is None:
        print(f"\nNo crossing of {TRIGGER_THRESHOLD} in window; bisect lower / extend window.")
    else:
        print(f"\nFirst step with H.max_abs >= {TRIGGER_THRESHOLD:.0e}: {trigger_step}")
        print(f"  Window narrowed from ({WINDOW_LO}, {WINDOW_HI}) to single step.")


if __name__ == "__main__":
    main()
