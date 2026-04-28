"""Find a Taichi flag that disables fma contraction of `a*b - c`.

Strategy: enumerate every plausible compile-config attr / env var that
might affect fma contraction. For each, run scripts/diag/_fma_flag_worker.py
in a fresh subprocess (Taichi singleton state means we can't reset
in-process). Worker computes `a*b - c` for the catastrophic-cancellation
input (1e10, 1e-10, 1.0). nvcc with --fmad=false returns 0.0; Taichi
default returns 3.643e-17 (= proof of fma). Goal: find a setting that
makes Taichi return 0.0 too.
"""
import os
import subprocess
import sys

WORKER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_fma_flag_worker.py")


def run_trial(name, init_kwargs=None, env_overrides=None):
    init_kwargs = init_kwargs or {}
    env = dict(os.environ)
    if env_overrides:
        env.update({k: str(v) for k, v in env_overrides.items()})

    args = [sys.executable, WORKER]
    for k, v in init_kwargs.items():
        args.append(f"{k}={v}")

    r = subprocess.run(args, capture_output=True, text=True, env=env, timeout=120)
    out = r.stdout
    result = None
    no_fma = None
    for line in out.splitlines():
        if line.startswith("RESULT="):
            try:
                result = float(line.split("=", 1)[1])
            except Exception:
                pass
        elif line.startswith("NO_FMA="):
            no_fma = line.split("=", 1)[1].strip()
    if result is None:
        tail = (r.stderr or out)[-300:]
        return f"  {name}: ERROR\n     stderr tail: ...{tail}"
    tag = " *** NO FMA (mul+sub kept) ***" if no_fma == "YES" else ""
    return f"  {name}: y = {result!r}{tag}"


def main():
    print("=" * 78)
    print("Taichi fma-contraction control flag enumeration")
    print("=" * 78)
    print(f"input: a=1e10, b=1e-10, c=1.0   (1.0 - 1.0 = 0.0 if no fma)")
    print(f"  fma path:  fma(1e10, 1e-10, -1.0) ≈ 3.643e-17")
    print(f"  no-fma:    1e10*1e-10 = 1.0 then 1.0 - 1.0 = 0.0")
    print()

    trials = [
        # init-kwargs variations
        ("fast_math=False (baseline)", {"fast_math": False}, None),
        ("fast_math=True",             {"fast_math": True},  None),
        ("fast_math=False, advanced_optimization=False",
         {"fast_math": False, "advanced_optimization": False}, None),
        ("fast_math=False, opt_level=0",
         {"fast_math": False, "opt_level": 0}, None),
        ("fast_math=False, opt_level=1",
         {"fast_math": False, "opt_level": 1}, None),
        ("fast_math=False, opt_level=2",
         {"fast_math": False, "opt_level": 2}, None),
        ("fast_math=False, opt_level=3",
         {"fast_math": False, "opt_level": 3}, None),
        ("fast_math=False, debug=True",
         {"fast_math": False, "debug": True}, None),
        # env-var variations
        ("env TI_USE_LLVM_FMA=0",
         {"fast_math": False}, {"TI_USE_LLVM_FMA": "0"}),
        ("env TI_LLVM_FAST_MATH=0",
         {"fast_math": False}, {"TI_LLVM_FAST_MATH": "0"}),
        ("env TI_LLVM_NO_FMA=1",
         {"fast_math": False}, {"TI_LLVM_NO_FMA": "1"}),
        ("env TI_DISABLE_FMA=1",
         {"fast_math": False}, {"TI_DISABLE_FMA": "1"}),
        ("env TI_NO_FMA=1",
         {"fast_math": False}, {"TI_NO_FMA": "1"}),
        ("env TI_LLVM_OPT_LEVEL=0",
         {"fast_math": False}, {"TI_LLVM_OPT_LEVEL": "0"}),
    ]

    for trial in trials:
        print(run_trial(*trial))


if __name__ == "__main__":
    main()
