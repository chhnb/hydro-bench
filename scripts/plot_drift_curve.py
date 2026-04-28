"""Plot the drift-growth curve for the F2_207K_fp32 case (or any case).

Per the original alignment plan section "Stage 7: 定位长 step 漂移源", we
want a visual of how the alignment-error metrics grow as a function of
step count for a long-step fp32 case. This script reads every existing
``results/alignment/{case}_step{N}.json`` and emits a textual drift
table plus, optionally, a matplotlib line chart.

Usage::

    python scripts/plot_drift_curve.py F2_207K_fp32
    python scripts/plot_drift_curve.py F2_207K_fp32 --save drift.png

The textual table is always printed; matplotlib is only required for
``--save``.
"""
import argparse
import glob
import json
import os
import sys


def collect(case, results_dir):
    paths = sorted(
        glob.glob(os.path.join(results_dir, f"{case}_step*.json")),
        key=lambda p: int(os.path.basename(p).split("step")[1].split(".")[0]),
    )
    rows = []
    for path in paths:
        try:
            with open(path) as f:
                r = json.load(f)
        except Exception:
            continue
        H = r["fields"]["H"]
        U = r["fields"]["U"]
        rows.append({
            "step": r["step"],
            "h_max_abs": H["max_abs"],
            "h_p99": H["percentiles"].get("99", H["percentiles"].get(99, 0.0)),
            "u_max_abs": U["max_abs"],
            "mass_rel": r["conservation"]["mass"]["rel_diff"],
            "ke_rel": r["conservation"]["kinetic_energy"]["rel_diff"],
            "momentum_x_rel": r["conservation"]["momentum_x"]["rel_diff"],
            "klas1_inflow_rel": r["conservation"]["klas1_inflow"]["rel_diff"],
            "verdict": r["verdict"],
        })
    return rows


def print_table(rows):
    print(f"{'step':>8s}  {'H max':>11s}  {'H p99':>11s}  {'U max':>11s}  "
          f"{'mass rel':>11s}  {'KE rel':>11s}  {'momentumX':>11s}  "
          f"{'klas1in':>11s}  verdict")
    for r in rows:
        print(
            f"{r['step']:>8d}  {r['h_max_abs']:11.3e}  {r['h_p99']:11.3e}  "
            f"{r['u_max_abs']:11.3e}  {r['mass_rel']:11.3e}  {r['ke_rel']:11.3e}  "
            f"{r['momentum_x_rel']:11.3e}  {r['klas1_inflow_rel']:11.3e}  "
            f"{r['verdict']}"
        )


def save_plot(case, rows, out_path):
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib not installed; skipping plot.")
        return False
    steps = [r["step"] for r in rows]
    fig, ax = plt.subplots(2, 1, figsize=(8, 6), sharex=True)
    ax[0].set_yscale("log")
    ax[0].plot(steps, [r["h_max_abs"] for r in rows], "o-", label="H max_abs")
    ax[0].plot(steps, [r["u_max_abs"] for r in rows], "s-", label="U max_abs")
    ax[0].plot(steps, [r["h_p99"] for r in rows], "^-", label="H p99")
    ax[0].set_ylabel("per-field abs diff")
    ax[0].set_title(f"Alignment drift over step count: {case}")
    ax[0].legend()
    ax[0].grid(True, which="both", alpha=0.3)
    ax[1].set_yscale("log")
    ax[1].plot(steps, [r["mass_rel"] for r in rows], "o-", label="mass rel")
    ax[1].plot(steps, [r["ke_rel"] for r in rows], "s-", label="KE rel")
    ax[1].plot(steps, [r["momentum_x_rel"] for r in rows], "^-", label="momentum_x rel")
    ax[1].plot(steps, [r["klas1_inflow_rel"] for r in rows], "v-", label="klas1_inflow rel")
    ax[1].set_xlabel("step")
    ax[1].set_ylabel("conservation rel diff")
    ax[1].legend()
    ax[1].grid(True, which="both", alpha=0.3)
    fig.tight_layout()
    fig.savefig(out_path, dpi=120)
    print(f"Saved plot to {out_path}")
    return True


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("case", help="Case name (e.g. F2_207K_fp32)")
    p.add_argument("--results-dir", default="results/alignment",
                   help="Directory containing per-(case, step) JSON reports")
    p.add_argument("--save", default=None,
                   help="Optional path to save a matplotlib plot")
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    rows = collect(args.case, args.results_dir)
    if not rows:
        print(f"No JSON reports found for {args.case} in {args.results_dir}")
        return 1
    print(f"Drift curve: {args.case} ({len(rows)} checkpoints)")
    print_table(rows)
    if args.save:
        save_plot(args.case, rows, args.save)
    return 0


if __name__ == "__main__":
    sys.exit(main())
