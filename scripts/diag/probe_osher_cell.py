"""Per-edge flux divergence probe on F2_207K_fp64 cell 156712.

Used to localise the chaotic divergence around step 6840-6850. The
probe shows that the four edges of cell 156712 already diverge by
~1e-5 at step 6800, well before the cell-state explosion. The
divergence amplifies through the OSHER Riemann solver's nonlinear
case dispatch: tiny fp64 ULP differences in QL[1] vs CL_v or CA vs
UA flip the K1/K2 branch dispatch on each side, producing different
flux formulas at the same physical edge.

Sample output (excerpt)::

    === step=6800 cell=156712 ===
      H: native=2.7506451999e+00  taichi=2.7506432703e+00
      edge j=0: F0 diff=0.000e+00 F1 diff=1.702e-05 F3 diff=4.737e-05
      edge j=1: F0 diff=1.692e-05 F1 diff=7.048e-06 F3 diff=8.683e-05
      edge j=2: F0 diff=4.390e-06 F1 diff=1.104e-05 F3 diff=1.161e-04
      edge j=3: F0 diff=1.081e-05 F1 diff=1.575e-05 F3 diff=3.666e-05

    === step=6840 cell=156712 ===
      edge j=0: F0 diff=0.000e+00 F1 diff=1.105e-03 F3 diff=9.831e-06
      edge j=1: F0 diff=7.887e-04 F1 diff=1.554e-04 F3 diff=3.208e-03

The amplification factor between step 6800 and step 6840 is ~100x —
classic chaotic feedback through OSHER's nonlinear branches.

To resolve AC-8 fully, a follow-up round must instrument the OSHER
function on both sides (native ``OSHER`` in functors.cu and Taichi
``osher`` in F2_hydro_taichi_fp64.py) and compare K1/K2/UA/CA/CL/CR
intermediates at the first diverging edge, then re-align the Taichi
branch dispatch to native exactly.
"""
import os
import sys

import numpy as np

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts"))
from check_correctness import dump_native_at_step, dump_taichi_at_step  # noqa: E402

CELL = 156712


def main():
    for step in (6800, 6820, 6830, 6840):
        n = dump_native_at_step("F2_207K_fp64", step)
        t = dump_taichi_at_step("F2_207K_fp64", step)
        if n is None or t is None:
            continue
        print(f"\n=== step={step} cell={CELL} ===")
        print(f"  H: native={n['H'][CELL]:.10e}  taichi={t['H'][CELL]:.10e}")
        print(f"  U: native={n['U'][CELL]:.10e}  taichi={t['U'][CELL]:.10e}")
        print(f"  V: native={n['V'][CELL]:.10e}  taichi={t['V'][CELL]:.10e}")
        for j in range(4):
            idx = 4 * CELL + j
            d = lambda f: abs(float(n[f][idx]) - float(t[f][idx]))
            print(
                f"  edge j={j}: F0 diff={d('F0'):.3e} F1 diff={d('F1'):.3e} "
                f"F3 diff={d('F3'):.3e}"
            )


if __name__ == "__main__":
    main()
