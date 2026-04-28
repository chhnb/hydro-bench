"""Validate that an alignment JSON report conforms to the AC-2 schema.

Per AC-2.2: each per-(case, step) JSON must include the per-field
distribution stats (max_abs, mean_abs, p50/p90/p99/p99.9, threshold
counts at 1e-7 / 1e-5 / 1e-3 / 1e-1, top-3 worst cells with
neighbor_klas) for all nine fields (H, U, V, Z, W, F0, F1, F2, F3),
the conservation block (mass, momentum_x, momentum_y, kinetic_energy,
potential_energy, klas10_inflow, klas1_inflow), the output_files
block (per AC-6), and the verdict string.

Usage::

    python scripts/validate_alignment_json.py results/alignment/F2_24K_fp32_step1.json
    python scripts/validate_alignment_json.py results/alignment/  # validates every *_step*.json

Returns exit code 0 if all reports validate, 1 otherwise.
"""
import argparse
import glob
import json
import os
import sys

REQUIRED_FIELDS = ("H", "U", "V", "Z", "W", "F0", "F1", "F2", "F3")
REQUIRED_CONSERVATION = (
    "mass", "momentum_x", "momentum_y",
    "kinetic_energy", "potential_energy",
    "klas10_inflow", "klas1_inflow",
)
REQUIRED_THRESHOLD_KEYS = (
    "diff_gt_1e-07", "diff_gt_1e-05", "diff_gt_1e-03", "diff_gt_1e-01",
)
REQUIRED_PERCENTILE_KEYS = ("50", "90", "99", "99.9")


def _validate_field(name, block, errors):
    if not isinstance(block, dict):
        errors.append(f"fields/{name}: not a dict")
        return
    if block.get("all_nonfinite"):
        return
    for k in ("max_abs", "mean_abs", "bit_exact_frac", "n_finite", "n_total"):
        if k not in block:
            errors.append(f"fields/{name}: missing '{k}'")
    pct = block.get("percentiles", {})
    for k in REQUIRED_PERCENTILE_KEYS:
        # JSON keys are strings even if Python keys are floats
        if k not in pct and float(k) not in pct:
            errors.append(f"fields/{name}/percentiles: missing key {k}")
    counts = block.get("threshold_counts", {})
    for k in REQUIRED_THRESHOLD_KEYS:
        if k not in counts:
            errors.append(f"fields/{name}/threshold_counts: missing key {k}")
    worst = block.get("worst_cells", [])
    if not isinstance(worst, list):
        errors.append(f"fields/{name}/worst_cells: not a list")


def _validate_report(report, errors):
    for k in ("case", "step", "precision", "fields", "conservation",
              "output_files", "health", "verdict", "reason"):
        if k not in report:
            errors.append(f"top-level: missing key '{k}'")

    fields = report.get("fields", {})
    for name in REQUIRED_FIELDS:
        if name not in fields:
            errors.append(f"fields: missing '{name}'")
            continue
        _validate_field(name, fields[name], errors)

    cons = report.get("conservation", {})
    for k in REQUIRED_CONSERVATION:
        if k not in cons:
            errors.append(f"conservation: missing '{k}'")
            continue
        v = cons[k]
        if not isinstance(v, dict):
            errors.append(f"conservation/{k}: not a dict")
            continue
        for sub in ("native", "taichi", "abs_diff", "rel_diff"):
            if sub not in v:
                errors.append(f"conservation/{k}: missing '{sub}'")

    output_files = report.get("output_files", {})
    if not isinstance(output_files, dict):
        errors.append("output_files: not a dict")

    if report.get("verdict") not in ("PASS", "FAIL"):
        errors.append(f"verdict: must be 'PASS' or 'FAIL', got {report.get('verdict')!r}")


def validate_path(path):
    """Validate a single JSON file. Returns list of error strings (empty = OK)."""
    errors = []
    try:
        with open(path) as f:
            report = json.load(f)
    except Exception as exc:
        return [f"cannot open/parse: {exc}"]
    _validate_report(report, errors)
    return errors


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("path", help="JSON file or directory containing *_step*.json")
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    if os.path.isdir(args.path):
        paths = sorted(glob.glob(os.path.join(args.path, "*_step*.json")))
    else:
        paths = [args.path]

    n_ok = 0
    n_fail = 0
    for path in paths:
        errors = validate_path(path)
        if errors:
            n_fail += 1
            print(f"FAIL {path}")
            for e in errors:
                print(f"  - {e}")
        else:
            n_ok += 1
    print(f"\n{n_ok} OK / {n_fail} FAIL of {len(paths)} reports")
    return 0 if n_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
