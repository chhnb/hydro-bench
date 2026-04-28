"""Run a single Taichi hydro case and print kernel timing.

Usage:
    python scripts/run_taichi.py <case>

Case options:
    F1_6.7K_fp64
    F2_24K_fp32, F2_24K_fp64
    F2_207K_fp32, F2_207K_fp64

Output (single line, JSON):
    RESULT={"case": "...", "us_per_step": X, "h_first5": [...]}
"""
import os
import sys
import time
import json
import importlib

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO_DIR, "taichi_impl"))


def main():
    if len(sys.argv) < 2:
        print("Usage: run_taichi.py <case>")
        return 1

    case = sys.argv[1]
    steps = int(sys.argv[2]) if len(sys.argv) > 2 else 100

    import taichi as ti

    # Parse case
    if case.startswith("F1"):
        if "fp64" in case:
            from F1_hydro_taichi_2kernel_fp64 import run_real
        else:
            from F1_hydro_taichi_2kernel_fp32 import run_real
        # mesh: "default" for 6.7K, "20w" for 207K
        mesh = "20w" if "207K" in case else "default"
        result = run_real(steps=steps, backend="cuda", mesh=mesh)
        if isinstance(result, tuple) and len(result) >= 3:
            step_fn, sync_fn, H = result[:3]
        else:
            print(f"ERROR: F1 run_real returned unexpected: {type(result)}")
            return 1
    elif case.startswith("F2"):
        if "fp64" in case:
            from F2_hydro_taichi_fp64 import run
        else:
            from F2_hydro_taichi_fp32 import run
        mesh = "20w" if "207K" in case else "default"
        result = run(days=1, backend="cuda", mesh=mesh, steps=steps)
        step_fn, sync_fn, H = result[:3]
    else:
        print(f"ERROR: unknown case '{case}'")
        return 1

    # Warmup
    step_fn()
    sync_fn()
    ti.sync()

    # Time 10 runs, take median of 5
    times = []
    for _ in range(10):
        ti.sync()
        t0 = time.perf_counter()
        step_fn()
        ti.sync()
        t1 = time.perf_counter()
        times.append((t1 - t0) * 1e6 / steps)
    times.sort()
    median_us = times[5]

    h_arr = H.to_numpy()
    h_first5 = list(map(float, h_arr.flat[:5]))

    result = {
        "case": case,
        "us_per_step": median_us,
        "steps": steps,
        "h_first5": h_first5,
        "framework": "taichi",
    }
    print("RESULT=" + json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
