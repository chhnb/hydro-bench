#!/usr/bin/env python3
"""Compare frozen native CUDA baseline vs current native CUDA candidate.

This is intentionally separate from ``check_correctness.py``. That script
compares native CUDA against Taichi; this one compares two native CUDA
binaries that use the same input data and dump format.

The benchmark dump contains:
  - post-step cell state: H/U/V/Z plus derived W
  - final-step flux arrays: F0/F1/F2/F3

Default thresholds are exact equality. For an optimization that deliberately
changes floating-point order, pass explicit tolerances and keep the JSON
reports as review artifacts.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import struct
import subprocess
import sys
from pathlib import Path
from typing import Any

import numpy as np


REPO_DIR = Path(__file__).resolve().parents[1]
NATIVE_DIR = REPO_DIR / "cuda_native_impl"
BASELINE_ROOT = NATIVE_DIR / "baselines" / "native_cuda_v0"

STATE_FIELDS = ("H", "U", "V", "Z", "W")
FLUX_FIELDS = ("F0", "F1", "F2", "F3")
ALL_FIELDS = STATE_FIELDS + FLUX_FIELDS


def case_config(case: str) -> tuple[str, int]:
    """Return ``(native_data_subdir, real_size_bytes)`` for a case."""
    table = {
        "F1_6.7K_fp32": ("F1_fp32_native_data", 4),
        "F1_6.7K_fp64": ("F1_native_data", 8),
        "F1_207K_fp32": ("F1_207K_native_data", 4),
        "F1_207K_fp64": ("F1_207K_native_data", 8),
        "F2_24K_fp32": ("F2_24K_native_data", 4),
        "F2_24K_fp64": ("F2_24K_native_data", 8),
        "F2_207K_fp32": ("F2_207K_native_data", 4),
        "F2_207K_fp64": ("F2_207K_native_data", 8),
    }
    try:
        return table[case]
    except KeyError as exc:
        raise ValueError(f"unknown case: {case}") from exc


def case_precision(case: str) -> str:
    return "fp64" if case.endswith("fp64") else "fp32"


def default_binary(case: str, side: str) -> Path:
    precision = case_precision(case)
    if side == "baseline":
        return BASELINE_ROOT / precision / "hydro_native_benchmark"
    if precision == "fp32":
        return NATIVE_DIR / "fp32_src" / "hydro_native_benchmark"
    return NATIVE_DIR / "hydro_native_benchmark"


def parse_steps(raw: str) -> list[int]:
    out: list[int] = []
    for item in raw.split(","):
        item = item.strip()
        if not item:
            continue
        step = int(item)
        if step <= 0:
            raise ValueError(f"steps must be positive, got {step}")
        out.append(step)
    if not out:
        raise ValueError("empty --steps")
    return sorted(set(out))


def read_state_dump(path: Path, real_size: int) -> dict[str, np.ndarray]:
    dtype = np.float32 if real_size == 4 else np.float64
    with path.open("rb") as f:
        cell_raw = f.read(4)
        if len(cell_raw) != 4:
            raise ValueError(f"{path}: missing cell count")
        cell = struct.unpack("i", cell_raw)[0]
        H = np.frombuffer(f.read(cell * real_size), dtype=dtype).copy()
        U = np.frombuffer(f.read(cell * real_size), dtype=dtype).copy()
        V = np.frombuffer(f.read(cell * real_size), dtype=dtype).copy()
        Z = np.frombuffer(f.read(cell * real_size), dtype=dtype).copy()
        nsides = cell * 4
        # Geometry block: SLCOS, SLSIN, SIDE. Kept in the dump for downstream
        # diagnostics but not needed for field equality checks.
        f.read(nsides * real_size * 3)
        F0 = np.frombuffer(f.read(nsides * real_size), dtype=dtype).copy()
        F1 = np.frombuffer(f.read(nsides * real_size), dtype=dtype).copy()
        F2 = np.frombuffer(f.read(nsides * real_size), dtype=dtype).copy()
        F3 = np.frombuffer(f.read(nsides * real_size), dtype=dtype).copy()
    W = np.sqrt(U * U + V * V).astype(dtype)
    return {
        "H": H,
        "U": U,
        "V": V,
        "Z": Z,
        "W": W,
        "F0": F0,
        "F1": F1,
        "F2": F2,
        "F3": F3,
    }


def run_dump(
    *,
    binary: Path,
    case: str,
    step: int,
    label: str,
    out_dir: Path,
    timeout_sec: float,
) -> tuple[dict[str, np.ndarray] | None, dict[str, Any]]:
    data_subdir, real_size = case_config(case)
    cwd = NATIVE_DIR / data_subdir / "run"
    dump_dir = out_dir / "dumps"
    dump_dir.mkdir(parents=True, exist_ok=True)
    dump_path = dump_dir / f"{label}_{case}_step{step}_{os.getpid()}.bin"

    meta: dict[str, Any] = {
        "binary": str(binary),
        "cwd": str(cwd),
        "dump": str(dump_path),
        "returncode": None,
        "stdout_tail": "",
        "stderr_tail": "",
    }

    if not binary.is_file():
        meta["error"] = f"binary not found: {binary}"
        return None, meta
    if not os.access(binary, os.X_OK):
        meta["error"] = f"binary is not executable: {binary}"
        return None, meta
    if not cwd.is_dir():
        meta["error"] = f"case run directory not found: {cwd}"
        return None, meta

    cmd = [str(binary), str(step), "1", "--dump", str(dump_path)]
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout_sec,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        meta["error"] = f"timeout after {timeout_sec}s"
        meta["stdout_tail"] = (exc.stdout or "")[-2000:]
        meta["stderr_tail"] = (exc.stderr or "")[-2000:]
        return None, meta

    meta["returncode"] = result.returncode
    meta["stdout_tail"] = result.stdout[-2000:]
    meta["stderr_tail"] = result.stderr[-2000:]

    if result.returncode != 0:
        meta["error"] = f"binary exited with {result.returncode}"
        return None, meta
    if not dump_path.is_file():
        meta["error"] = f"dump file was not written: {dump_path}"
        return None, meta

    try:
        return read_state_dump(dump_path, real_size), meta
    except Exception as exc:  # noqa: BLE001
        meta["error"] = f"failed to read dump: {type(exc).__name__}: {exc}"
        return None, meta


def percentile_block(diff: np.ndarray) -> dict[str, float]:
    if diff.size == 0:
        return {"p50": 0.0, "p90": 0.0, "p99": 0.0, "p999": 0.0}
    return {
        "p50": float(np.percentile(diff, 50)),
        "p90": float(np.percentile(diff, 90)),
        "p99": float(np.percentile(diff, 99)),
        "p999": float(np.percentile(diff, 99.9)),
    }


def field_stats(name: str, baseline: np.ndarray, candidate: np.ndarray) -> dict[str, Any]:
    n = min(len(baseline), len(candidate))
    b = baseline[:n].astype(np.float64)
    c = candidate[:n].astype(np.float64)
    finite = np.isfinite(b) & np.isfinite(c)
    diff_full = np.full(n, np.inf, dtype=np.float64)
    diff_full[finite] = np.abs(b[finite] - c[finite])
    diff = diff_full[finite]

    out: dict[str, Any] = {
        "n_baseline": int(len(baseline)),
        "n_candidate": int(len(candidate)),
        "n_compared": int(n),
        "n_finite_pairs": int(finite.sum()),
        "baseline_nan_count": int(np.isnan(b).sum()),
        "candidate_nan_count": int(np.isnan(c).sum()),
        "baseline_inf_count": int(np.isinf(b).sum()),
        "candidate_inf_count": int(np.isinf(c).sum()),
        "shape_match": int(len(baseline)) == int(len(candidate)),
    }

    if diff.size == 0:
        out.update(
            {
                "all_nonfinite": True,
                "max_abs": math.inf,
                "mean_abs": math.inf,
                "bit_exact_frac": 0.0,
                "percentiles": percentile_block(diff),
                "threshold_counts": {},
                "worst": [],
            }
        )
        return out

    thresholds = (0.0, 1e-13, 1e-11, 1e-9, 1e-7, 1e-5, 1e-3, 1e-1)
    out.update(
        {
            "all_nonfinite": False,
            "max_abs": float(diff.max()),
            "mean_abs": float(diff.mean()),
            "bit_exact_frac": float((diff == 0.0).sum()) / float(diff.size),
            "percentiles": percentile_block(diff),
            "threshold_counts": {
                f"diff_gt_{threshold:.0e}": int((diff > threshold).sum())
                for threshold in thresholds
            },
        }
    )

    worst_idx = np.argsort(diff_full)[-5:][::-1]
    worst = []
    is_flux = name in FLUX_FIELDS
    for idx in worst_idx:
        if not np.isfinite(diff_full[idx]):
            continue
        record = {
            "idx": int(idx),
            "baseline": float(b[idx]),
            "candidate": float(c[idx]),
            "abs_diff": float(diff_full[idx]),
        }
        if is_flux:
            record["cell"] = int(idx // 4)
            record["edge_j"] = int(idx % 4)
        worst.append(record)
    out["worst"] = worst
    return out


def check_verdict(
    fields: dict[str, dict[str, Any]],
    *,
    state_max_abs: float,
    state_p99: float,
    flux_max_abs: float,
    flux_p99: float,
) -> tuple[str, str]:
    for name, stats in fields.items():
        if not stats.get("shape_match", False):
            return "FAIL", f"{name} shape mismatch"
        if stats.get("baseline_nan_count", 0) or stats.get("candidate_nan_count", 0):
            return "FAIL", f"{name} has NaN"
        if stats.get("baseline_inf_count", 0) or stats.get("candidate_inf_count", 0):
            return "FAIL", f"{name} has Inf"
        max_limit = state_max_abs if name in STATE_FIELDS else flux_max_abs
        p99_limit = state_p99 if name in STATE_FIELDS else flux_p99
        if float(stats.get("max_abs", math.inf)) > max_limit:
            return "DRIFT", f"{name}.max_abs={stats['max_abs']:.3e} > {max_limit:.3e}"
        if float(stats.get("percentiles", {}).get("p99", math.inf)) > p99_limit:
            return "DRIFT", f"{name}.p99={stats['percentiles']['p99']:.3e} > {p99_limit:.3e}"
    return "PASS", "within thresholds"


def write_summary(out_dir: Path, rows: list[dict[str, Any]]) -> None:
    lines = [
        "| case | step | verdict | reason | H max | U max | V max | Z max | F0 max | F1 max | F2 max | F3 max |",
        "|---|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in rows:
        f = row.get("fields", {})
        def fmt(field: str) -> str:
            val = f.get(field, {}).get("max_abs")
            if val is None:
                return "?"
            return f"{float(val):.3e}"

        lines.append(
            f"| {row['case']} | {row['step']} | {row['verdict']} | {row['reason']} | "
            f"{fmt('H')} | {fmt('U')} | {fmt('V')} | {fmt('Z')} | "
            f"{fmt('F0')} | {fmt('F1')} | {fmt('F2')} | {fmt('F3')} |"
        )
    (out_dir / "SUMMARY.md").write_text("\n".join(lines) + "\n")


def evaluate_step(args: argparse.Namespace, case: str, step: int) -> dict[str, Any]:
    baseline_state, baseline_meta = run_dump(
        binary=Path(args.baseline).resolve(),
        case=case,
        step=step,
        label="baseline",
        out_dir=Path(args.out_dir),
        timeout_sec=args.timeout_sec,
    )
    candidate_state, candidate_meta = run_dump(
        binary=Path(args.candidate).resolve(),
        case=case,
        step=step,
        label="candidate",
        out_dir=Path(args.out_dir),
        timeout_sec=args.timeout_sec,
    )

    row: dict[str, Any] = {
        "case": case,
        "step": step,
        "precision": case_precision(case),
        "baseline": baseline_meta,
        "candidate": candidate_meta,
        "fields": {},
        "verdict": "FAIL",
        "reason": "",
    }

    missing = []
    if baseline_state is None:
        missing.append("baseline")
    if candidate_state is None:
        missing.append("candidate")
    if missing:
        row["reason"] = f"dump failed: {','.join(missing)}"
        return row

    fields = {
        name: field_stats(name, baseline_state[name], candidate_state[name])
        for name in ALL_FIELDS
    }
    row["fields"] = fields
    verdict, reason = check_verdict(
        fields,
        state_max_abs=args.state_max_abs,
        state_p99=args.state_p99,
        flux_max_abs=args.flux_max_abs,
        flux_p99=args.flux_p99,
    )
    row["verdict"] = verdict
    row["reason"] = reason
    return row


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Compare frozen native CUDA baseline against current candidate.",
    )
    p.add_argument("case", help="case name, e.g. F2_207K_fp64 or F2_207K_fp32")
    p.add_argument(
        "--steps",
        default="1,10,100,899",
        help="comma-separated checkpoints (default: 1,10,100,899)",
    )
    p.add_argument(
        "--baseline",
        default=None,
        help="baseline binary path (default: cuda_native_impl/baselines/native_cuda_v0/<precision>/hydro_native_benchmark)",
    )
    p.add_argument(
        "--candidate",
        default=None,
        help="candidate binary path (default: current native binary for the case precision)",
    )
    p.add_argument(
        "--out-dir",
        default="results/native_alignment",
        help="directory for JSON reports and SUMMARY.md",
    )
    p.add_argument("--timeout-sec", type=float, default=1800.0)
    p.add_argument("--state-max-abs", type=float, default=0.0)
    p.add_argument("--state-p99", type=float, default=0.0)
    p.add_argument("--flux-max-abs", type=float, default=0.0)
    p.add_argument("--flux-p99", type=float, default=0.0)
    return p


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        steps = parse_steps(args.steps)
        case_config(args.case)
    except Exception as exc:  # noqa: BLE001
        parser.error(str(exc))

    if args.baseline is None:
        args.baseline = str(default_binary(args.case, "baseline"))
    if args.candidate is None:
        args.candidate = str(default_binary(args.case, "candidate"))

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"case:      {args.case}")
    print(f"steps:     {','.join(str(s) for s in steps)}")
    print(f"baseline:  {Path(args.baseline).resolve()}")
    print(f"candidate: {Path(args.candidate).resolve()}")
    print(f"out-dir:   {out_dir.resolve()}")

    rows = []
    for step in steps:
        print(f"\n[step={step}] running baseline/candidate dumps ...", flush=True)
        row = evaluate_step(args, args.case, step)
        rows.append(row)
        report_path = out_dir / f"{args.case}_step{step}.json"
        report_path.write_text(json.dumps(row, indent=2, allow_nan=True))
        fields = row.get("fields", {})
        h_max = fields.get("H", {}).get("max_abs", "?")
        f0_max = fields.get("F0", {}).get("max_abs", "?")
        print(
            f"  -> {row['verdict']}: {row['reason']} "
            f"(H.max={h_max}, F0.max={f0_max})"
        )

    write_summary(out_dir, rows)
    verdicts = {row["verdict"] for row in rows}
    if "FAIL" in verdicts:
        return 2
    if "DRIFT" in verdicts:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
