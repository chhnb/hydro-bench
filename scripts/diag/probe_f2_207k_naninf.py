"""Localize F2_207K_fp64 first-NaN/Inf step.

SUMMARY.md row F2_207K_fp64 step=36000 reports 15,023 inf cells in
Taichi while native is fully finite at the same step. F1_207K shares
the mesh but has different boundary forcing and stays finite. So the
inf is Taichi-specific and BC-dependent. This probe walks Taichi
state every 100 steps from 35000 to 36000, counts non-finite cells
per step, and prints the first step + first non-finite cell + prev
step state at that cell, so the round-7 fix knows exactly which
Taichi kernel branch / wet-dry guard to inspect.

Run::

    python scripts/diag/probe_f2_207k_naninf.py
"""
import os
import sys

import numpy as np

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts"))

from check_correctness import dump_taichi_multi_step, load_mesh_metadata  # noqa: E402

CASE = "F2_207K_fp64"
COARSE_STEP = 100
COARSE_LO = 33200
COARSE_HI = 34200


def count_nonfinite(state):
    H = state["H"].astype(np.float64)
    U = state["U"].astype(np.float64)
    V = state["V"].astype(np.float64)
    nf = ~(np.isfinite(H) & np.isfinite(U) & np.isfinite(V))
    return int(nf.sum()), nf


def main():
    print(f"=== {CASE} NaN/Inf first-emergence probe ===")
    area, klas_edge, nac_edge, side_edge = load_mesh_metadata(CASE)
    n_cells = int(len(area))

    # Coarse pass: every 100 steps from 35000 to 36000.
    coarse_ladder = list(range(COARSE_LO, COARSE_HI + 1, COARSE_STEP))
    print(f"\nCoarse pass: {len(coarse_ladder)} checkpoints from {COARSE_LO} to {COARSE_HI}")
    states = dump_taichi_multi_step(CASE, coarse_ladder)
    first_inf_step = None
    for s in coarse_ladder:
        st = states.get(s)
        if st is None:
            print(f"  step={s}: dump failed")
            continue
        n_nf, _ = count_nonfinite(st)
        marker = "  *FIRST NON-FINITE*" if n_nf > 0 and first_inf_step is None else ""
        print(f"  step={s:>6d}: non-finite cells={n_nf}/{n_cells}{marker}")
        if n_nf > 0 and first_inf_step is None:
            first_inf_step = s

    if first_inf_step is None:
        print(f"\nNo non-finite in coarse range; extend window.")
        return

    # Fine pass: every step in (first_inf_step - COARSE_STEP, first_inf_step].
    fine_lo = first_inf_step - COARSE_STEP + 1
    fine_hi = first_inf_step
    fine_ladder = list(range(fine_lo, fine_hi + 1))
    print(f"\nFine pass: {len(fine_ladder)} steps from {fine_lo} to {fine_hi}")
    states_fine = dump_taichi_multi_step(CASE, fine_ladder)
    fine_first = None
    prev_state = None
    for s in fine_ladder:
        st = states_fine.get(s)
        if st is None:
            print(f"  step={s}: dump failed")
            continue
        n_nf, mask = count_nonfinite(st)
        if n_nf > 0 and fine_first is None:
            fine_first = s
            print(f"  step={s:>6d}: non-finite cells={n_nf}  *FIRST FINE*")
            # Dump first non-finite cell metadata
            i = int(np.flatnonzero(mask)[0])
            klas_i = [int(klas_edge[4 * i + j]) for j in range(4)] if 4 * i + 3 < len(klas_edge) else []
            print(f"    first non-finite cell={i}  klas={klas_i}")
            print(f"    H_taichi={float(st['H'][i])!r}")
            print(f"    U_taichi={float(st['U'][i])!r}")
            print(f"    V_taichi={float(st['V'][i])!r}")
            print(f"    Z_taichi={float(st['Z'][i])!r}")
            # Trigger-step fluxes (calculated by step s's calculate_flux,
            # consumed by step s's update_cell to produce the inf state).
            print(f"    --- trigger-step fluxes at cell={i} ---")
            for j in range(4):
                ei = 4 * i + j
                print(
                    f"    edge j={j}: F0={float(st['F0'][ei]):+.6e}  "
                    f"F1={float(st['F1'][ei]):+.6e}  "
                    f"F2={float(st['F2'][ei]):+.6e}  "
                    f"F3={float(st['F3'][ei]):+.6e}"
                )
            if prev_state is not None:
                pst = prev_state["state"]
                ps = prev_state["step"]
                print(f"    --- one step earlier (step={ps}, same cell={i}) ---")
                print(f"    H_taichi_prev={float(pst['H'][i])!r}")
                print(f"    U_taichi_prev={float(pst['U'][i])!r}")
                print(f"    V_taichi_prev={float(pst['V'][i])!r}")
                print(f"    Z_taichi_prev={float(pst['Z'][i])!r}")
                # Per-edge fluxes at i
                for j in range(4):
                    ei = 4 * i + j
                    nb = int(nac_edge[4 * i + j]) - 1
                    nb_klas = (
                        [int(klas_edge[4 * nb + k]) for k in range(4)]
                        if 0 <= nb < n_cells else None
                    )
                    print(
                        f"    edge j={j}: klas={int(klas_edge[ei])} neighbour={nb} "
                        f"neighbour_klas={nb_klas}  "
                        f"F0_prev={float(pst['F0'][ei]):+.6e}  "
                        f"F1_prev={float(pst['F1'][ei]):+.6e}  "
                        f"F2_prev={float(pst['F2'][ei]):+.6e}  "
                        f"F3_prev={float(pst['F3'][ei]):+.6e}"
                    )
                if 0 <= nb < n_cells:
                    print(f"    --- neighbour cell={nb} state at step={ps} ---")
                    print(f"      H={float(pst['H'][nb])!r}  U={float(pst['U'][nb])!r}  V={float(pst['V'][nb])!r}  Z={float(pst['Z'][nb])!r}")
            break
        else:
            prev_state = {"step": s, "state": st}

    if fine_first is None:
        print("Coarse said non-finite, fine pass did not -- contradiction; check probe.")


if __name__ == "__main__":
    main()
