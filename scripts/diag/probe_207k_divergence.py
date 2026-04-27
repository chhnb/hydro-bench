"""Bisect when the F2_207K_fp64 alignment divergence appears.

Originally hypothesised as a "day-rollover" bug (step 7200 = day 0->1
boundary). The probe disproves that hypothesis:

  step= 3600 (mid day 0): H max=1.7e-9   (within fp64 tolerance)
  step= 6000              : H max=1.3e-10 (still tight)
  step= 6800              : H max=3.0e-7  (still tight)
  step= 6850              : H max=4.7e-3  (DIVERGED)
  step= 7000              : H max=2.2e-2
  step= 7200 (day 1, kt=1): H max=1.3e-2  (no specific day boundary effect)

So the divergence happens between step 6800 and 6850 — mid-day-0,
nowhere near the day rollover. Localising to cell 156712:

  step=6800 : native_H=2.752007e+00 (WET),    taichi_H=2.752007e+00 (WET)
  step=6810 : native=2.749548e+00,            taichi=2.749548e+00
  step=6840 : native=2.755737e+00,            taichi=2.755731e+00 (diff 6e-6)
  step=6850 : native=2.759089e+00,            taichi=2.754354e+00 (diff 5e-3)

Cell 156712 sits at high elevation (ZBC=2935m) with all four edges
KLAS=0 (interior). H stays > HM2 throughout the bisected range, so
it's not a wet/dry transition flip. The diff amplifies 1000x in 10
steps — chaotic instability in a steep-gradient / high-flow region.

Run::

    python scripts/diag/probe_207k_divergence.py

Required for Round 3: drill into the OSHER solver's hot path on this
cell and identify the specific PTX-level rounding that triggers
amplification. Likely candidates are the K1/K2 case dispatch in
``osher`` when the flow is right at the boundary between subcritical
and supercritical (CA vs UA, QL[1] vs CL_v).
"""
import os
import sys

import numpy as np

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts"))
from check_correctness import dump_native_at_step, dump_taichi_at_step  # noqa: E402

CASE = "F2_207K_fp64"
PROBE_CELL = 156712
HM1 = 0.001
HM2 = 0.01


def main():
    print(f"Bisecting {CASE} divergence ...")
    for step in (3600, 6000, 6800, 6840, 6850, 7000, 7200):
        n = dump_native_at_step(CASE, step)
        t = dump_taichi_at_step(CASE, step)
        if n is None or t is None:
            print(f"  step={step}: dump failed")
            continue
        diff = np.abs(n["H"].astype(np.float64) - t["H"].astype(np.float64))
        print(f"  step={step:>5d}: H max={diff.max():.3e}  argmax_cell={int(diff.argmax())}  "
              f"taichi.H[{PROBE_CELL}]={float(t['H'][PROBE_CELL]):.6e}  "
              f"native.H[{PROBE_CELL}]={float(n['H'][PROBE_CELL]):.6e}")


if __name__ == "__main__":
    main()
