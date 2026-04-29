"""Native hydro-cal task setup for Aker.

This mode keeps Aker's graph/review/leaderboard machinery but swaps the
node contract from a PyTorch extension to a native CUDA `functors.cu`
candidate that is compiled against the hydro benchmark harness.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from aker.state.leaderboard import commit_row, regenerate_md


TESTLIB = r'''from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from pathlib import Path


TASK_DIR = Path(__file__).resolve().parent


def load_config() -> dict:
    return json.loads((TASK_DIR / "task_config.json").read_text())


def repo_root() -> Path:
    return Path(load_config()["repo_root"]).resolve()


def case_precision(case: str) -> str:
    return "fp64" if case.endswith("fp64") else "fp32"


def source_root_for(case: str) -> Path:
    root = repo_root()
    if case_precision(case) == "fp32":
        return root / "cuda_native_impl" / "fp32_src"
    return root / "cuda_native_impl"


def baseline_binary_for(case: str) -> Path:
    precision = case_precision(case)
    return repo_root() / "cuda_native_impl" / "baselines" / "native_cuda_v0" / precision / "hydro_native_benchmark"


def node_dir(node_id: str) -> Path:
    d = TASK_DIR / "nodes" / node_id
    if not d.is_dir():
        raise FileNotFoundError(f"node not found: {d}")
    return d


def node_build_dir(node_id: str) -> Path:
    return node_dir(node_id) / "build"


def candidate_binary(node_id: str) -> Path:
    return node_build_dir(node_id) / "hydro_native_benchmark"


def build_candidate(node_id: str) -> Path:
    cfg = load_config()
    case = cfg["case"]
    src_root = source_root_for(case)
    nd = node_dir(node_id)
    build_dir = node_build_dir(node_id)
    work_dir = build_dir / "work"
    out_bin = candidate_binary(node_id)

    if work_dir.exists():
        shutil.rmtree(work_dir)
    build_dir.mkdir(parents=True, exist_ok=True)
    work_dir.mkdir(parents=True, exist_ok=True)

    shutil.copy2(src_root / "benchmark.cu", work_dir / "benchmark.cu")
    shutil.copytree(src_root / "hydro-cal-src", work_dir / "hydro-cal-src")
    shutil.copy2(nd / "kernel.cu", work_dir / "hydro-cal-src" / "src" / "functors.cu")

    arch = cfg.get("gpu_arch", "sm_80")
    nvcc = os.environ.get("NVCC") or "nvcc"
    cmd = [
        nvcc, "-O3", f"-arch={arch}", "-rdc=true", "--std=c++17",
        "-I", str(work_dir / "hydro-cal-src" / "include"),
        str(work_dir / "benchmark.cu"),
        str(work_dir / "hydro-cal-src" / "src" / "functors.cu"),
        str(work_dir / "hydro-cal-src" / "src" / "mesh.cpp"),
        str(work_dir / "hydro-cal-src" / "src" / "cell.cpp"),
        str(work_dir / "hydro-cal-src" / "src" / "side.cpp"),
        "-o", str(out_bin),
        "-lcudadevrt",
    ]
    env = os.environ.copy()
    cuda_bin = "/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/bin"
    cuda_lib = "/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/lib64"
    env["PATH"] = cuda_bin + os.pathsep + env.get("PATH", "")
    env["LD_LIBRARY_PATH"] = cuda_lib + os.pathsep + env.get("LD_LIBRARY_PATH", "")
    result = subprocess.run(cmd, cwd=TASK_DIR, capture_output=True, text=True, env=env)
    (build_dir / "build_cmd.json").write_text(json.dumps({
        "cmd": cmd,
        "returncode": result.returncode,
        "stdout": result.stdout[-4000:],
        "stderr": result.stderr[-4000:],
    }, indent=2))
    if result.returncode != 0:
        raise RuntimeError(f"candidate build failed rc={result.returncode}\n{result.stderr[-2000:]}")
    return out_bin


def parse_steps(raw) -> list[int]:
    if isinstance(raw, list):
        return [int(x) for x in raw]
    return [int(x.strip()) for x in str(raw).split(",") if x.strip()]


def parse_benchmark_output(text: str, steps: int) -> dict:
    out = {"raw_tail": text[-4000:]}
    patterns = {
        "sync": r"^Sync:\s+median=([0-9.]+) ms,\s+([0-9.]+) us/step",
        "async": r"^Async:\s+median=([0-9.]+) ms,\s+([0-9.]+) us/step",
        "graph": r"^Graph:\s+median=([0-9.]+) ms,\s+([0-9.]+) us/step",
    }
    for key, pat in patterns.items():
        m = re.search(pat, text, flags=re.MULTILINE)
        if m:
            out[key] = {
                "median_ms_total": float(m.group(1)),
                "us_per_step": float(m.group(2)),
                "ms_per_step": float(m.group(2)) / 1000.0,
            }
    if "async" not in out and "graph" not in out and "sync" not in out:
        raise RuntimeError("could not parse benchmark output")
    out["steps"] = steps
    return out
'''


TEST_ACC = r'''#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from testlib import TASK_DIR, baseline_binary_for, build_candidate, load_config, repo_root


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", required=True)
    args = ap.parse_args()

    cfg = load_config()
    node_id = args.version
    node_dir = TASK_DIR / "nodes" / node_id
    report_path = node_dir / "report_acc.json"
    node_dir.mkdir(parents=True, exist_ok=True)

    try:
        cand = build_candidate(node_id)
        out_dir = node_dir / "native_alignment"
        cmd = [
            sys.executable,
            str(repo_root() / "scripts" / "check_native_alignment.py"),
            cfg["case"],
            "--steps", str(cfg.get("steps", "1,10,100,899,7199")),
            "--baseline", str(baseline_binary_for(cfg["case"])),
            "--candidate", str(cand),
            "--out-dir", str(out_dir),
            "--state-max-abs", str(cfg.get("state_max_abs", 0)),
            "--state-p99", str(cfg.get("state_p99", 0)),
            "--flux-max-abs", str(cfg.get("flux_max_abs", 0)),
            "--flux-p99", str(cfg.get("flux_p99", 0)),
        ]
        result = subprocess.run(cmd, cwd=repo_root(), capture_output=True, text=True)
        step_reports = []
        total_nan = 0
        total_inf = 0
        drift_count = 0
        fail_count = 0
        for path in sorted(out_dir.glob(f"{cfg['case']}_step*.json")):
            row = json.loads(path.read_text())
            step_reports.append({
                "step": row.get("step"),
                "verdict": row.get("verdict"),
                "reason": row.get("reason"),
                "path": str(path),
            })
            if row.get("verdict") == "DRIFT":
                drift_count += 1
            if row.get("verdict") == "FAIL":
                fail_count += 1
            for stats in (row.get("fields") or {}).values():
                total_nan += int(stats.get("candidate_nan_count") or 0)
                total_inf += int(stats.get("candidate_inf_count") or 0)
        status = "OK" if result.returncode == 0 and drift_count == 0 and fail_count == 0 else "FAIL"
        report = {
            "node_id": node_id,
            "summary": {
                "status": status,
                "total_nan_count": total_nan,
                "total_inf_count": total_inf,
                "drift_count": drift_count,
                "fail_count": fail_count,
                "returncode": result.returncode,
            },
            "observations": step_reports,
            "stdout_tail": result.stdout[-4000:],
            "stderr_tail": result.stderr[-4000:],
        }
        report_path.write_text(json.dumps(report, indent=2, allow_nan=True))
        return 0 if status == "OK" else 1
    except Exception as exc:
        report = {
            "node_id": node_id,
            "summary": {
                "status": "FAIL",
                "total_nan_count": 0,
                "total_inf_count": 0,
                "error": f"{type(exc).__name__}: {exc}",
            },
            "observations": [],
        }
        report_path.write_text(json.dumps(report, indent=2))
        print(report["summary"]["error"], file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
'''


TEST_PERF = r'''#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

from testlib import TASK_DIR, build_candidate, load_config, parse_benchmark_output, repo_root


def data_run_dir(case: str) -> Path:
    table = {
        "F1_6.7K_fp32": "F1_fp32_native_data",
        "F1_6.7K_fp64": "F1_native_data",
        "F1_207K_fp32": "F1_207K_native_data",
        "F1_207K_fp64": "F1_207K_native_data",
        "F2_24K_fp32": "F2_24K_native_data",
        "F2_24K_fp64": "F2_24K_native_data",
        "F2_207K_fp32": "F2_207K_native_data",
        "F2_207K_fp64": "F2_207K_native_data",
    }
    return repo_root() / "cuda_native_impl" / table[case] / "run"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", required=True)
    args = ap.parse_args()

    cfg = load_config()
    node_id = args.version
    node_dir = TASK_DIR / "nodes" / node_id
    report_path = node_dir / "report_perf.json"
    try:
        cand = build_candidate(node_id)
        steps = int(cfg.get("perf_steps", 100))
        repeat = int(cfg.get("perf_repeat", 3))
        cmd = [str(cand), str(steps), str(repeat)]
        result = subprocess.run(
            cmd,
            cwd=data_run_dir(cfg["case"]),
            capture_output=True,
            text=True,
            timeout=float(cfg.get("perf_timeout_sec", 1800)),
        )
        text = result.stdout + "\n" + result.stderr
        parsed = parse_benchmark_output(text, steps)
        primary = parsed.get("async") or parsed.get("graph") or parsed.get("sync")
        status = "OK" if result.returncode == 0 and primary else "FAIL"
        report = {
            "node_id": node_id,
            "status": status,
            "measurements": [
                {
                    "shape": "primary",
                    "mean_ms": primary["ms_per_step"] if primary else None,
                    "steps": steps,
                    "repeat": repeat,
                    "metric": "async_ms_per_step",
                }
            ],
            "parsed": parsed,
            "returncode": result.returncode,
            "stdout_tail": result.stdout[-4000:],
            "stderr_tail": result.stderr[-4000:],
        }
        report_path.write_text(json.dumps(report, indent=2, allow_nan=True))
        return 0 if status == "OK" else 1
    except Exception as exc:
        report = {
            "node_id": node_id,
            "status": "FAIL",
            "measurements": [],
            "error": f"{type(exc).__name__}: {exc}",
        }
        report_path.write_text(json.dumps(report, indent=2))
        print(report["error"], file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
'''


def _find_repo_root(start: Path) -> Path:
    cur = start.resolve()
    for p in (cur, *cur.parents):
        if (p / "cuda_native_impl").is_dir() and (p / "scripts").is_dir():
            return p
    raise FileNotFoundError(
        f"could not find hydro-bench repo root from {start}; pass --repo-root"
    )


def _source_functors(repo_root: Path, case: str) -> Path:
    if case.endswith("fp32"):
        return repo_root / "cuda_native_impl" / "fp32_src" / "hydro-cal-src" / "src" / "functors.cu"
    return repo_root / "cuda_native_impl" / "hydro-cal-src" / "src" / "functors.cu"


def init_task(
    task_dir: Path | str,
    *,
    repo_root: Path | str | None = None,
    case: str = "F2_207K_fp64",
    steps: str = "1,10,100,899,7199",
    perf_steps: int = 100,
    perf_repeat: int = 3,
    gpu_arch: str = "sm_80",
    run_tests: bool = False,
) -> Path:
    task_dir = Path(task_dir).resolve()
    root = Path(repo_root).resolve() if repo_root else _find_repo_root(Path.cwd())
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "nodes").mkdir(exist_ok=True)

    cfg = {
        "mode": "native_hydro",
        "repo_root": str(root),
        "case": case,
        "steps": steps,
        "perf_steps": perf_steps,
        "perf_repeat": perf_repeat,
        "gpu_arch": gpu_arch,
        "state_max_abs": 0,
        "state_p99": 0,
        "flux_max_abs": 0,
        "flux_p99": 0,
    }
    (task_dir / "task_config.json").write_text(json.dumps(cfg, indent=2))

    spec = f"""# native_hydro_functors

## Goal

Optimize the native CUDA hydro-cal kernels in `functors.cu` while preserving the
frozen native CUDA baseline trajectory.

The candidate node supplies one file, `kernel.cu`, which replaces
`hydro-cal-src/src/functors.cu` for the configured precision and is compiled
against the native benchmark harness.

## Target Kernels

- `CalculateFluxKernel`
- `UpdateCellKernel`
- All device helper functions in the same `functors.cu` may be changed only as
  required by those kernels.

## Correctness

Correctness is baseline-vs-candidate native CUDA alignment for `{case}` at
checkpoints `{steps}`. The default threshold is exact equality for
`H/U/V/Z/W/F0/F1/F2/F3`; any drift must be treated as a failed attempt unless
the human operator explicitly relaxes thresholds in `task_config.json`.

## Performance

Primary metric is async native benchmark milliseconds per hydro step on
`{case}`, using `perf_steps={perf_steps}` and `perf_repeat={perf_repeat}`.

## Constraints

- Do not edit files outside the node directory.
- Do not change data loaders, mesh definitions, or benchmark semantics.
- Do not change floating-point operation order unless the attempt is explicitly
  marked failed or human guidance allows relaxed alignment thresholds.
- Preserve the public host wrappers `CalculateFlux(...)` and `UpdateCell(...)`.
"""
    (task_dir / "spec.md").write_text(spec)
    (task_dir / "testlib.py").write_text(TESTLIB)
    (task_dir / "test_acc.py").write_text(TEST_ACC)
    (task_dir / "test_perf.py").write_text(TEST_PERF)

    v0 = task_dir / "nodes" / "v0_naive_cuda"
    v0.mkdir(exist_ok=True)
    shutil.copy2(_source_functors(root, case), v0 / "kernel.cu")
    meta = {
        "node_id": "v0_naive_cuda",
        "parents": [],
        "action": "bootstrap",
        "direction": "frozen current native CUDA functors.cu baseline",
        "rationale": "Seed node copied from the current native hydro-cal functors.cu before Aker optimization.",
        "techniques": ["native_cuda", "baseline"],
        "attempt_status": "OK",
        "created_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    (v0 / "meta.json").write_text(json.dumps(meta, indent=2))
    (v0 / "notes.md").write_text(
        "# v0_naive_cuda\n\n"
        "Frozen copy of the current native `functors.cu`. Future nodes should "
        "mutate this file only through their own node-local `kernel.cu`, then "
        "validate baseline-vs-candidate drift across the configured hydro "
        "checkpoints before claiming success.\n"
    )

    if run_tests:
        py = sys.executable
        subprocess.run([py, "test_acc.py", "--version", "v0_naive_cuda"], cwd=task_dir, check=True)
        subprocess.run([py, "test_perf.py", "--version", "v0_naive_cuda"], cwd=task_dir, check=True)
        commit_row(task_dir, "v0_naive_cuda")
    else:
        regenerate_md(task_dir)

    return task_dir


def seed_v0(task_dir: Path | str, *, force: bool = False) -> dict:
    task_dir = Path(task_dir).resolve()
    if not (task_dir / "task_config.json").is_file():
        raise FileNotFoundError(f"task_config.json missing: {task_dir}")
    cfg = json.loads((task_dir / "task_config.json").read_text())
    if cfg.get("mode") != "native_hydro":
        raise ValueError(f"{task_dir} is not a native_hydro task")

    jsonl = task_dir / "leaderboard.jsonl"
    if jsonl.is_file() and not force and _v0_reports_match_config(task_dir, cfg):
        for line in jsonl.read_text().splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if row.get("node_id") == "v0_naive_cuda":
                return {"skipped": True, "reason": "v0 already present in leaderboard"}

    py = sys.executable
    subprocess.run([py, "test_acc.py", "--version", "v0_naive_cuda"], cwd=task_dir, check=True)
    subprocess.run([py, "test_perf.py", "--version", "v0_naive_cuda"], cwd=task_dir, check=True)
    _remove_leaderboard_node(task_dir, "v0_naive_cuda")
    row = commit_row(task_dir, "v0_naive_cuda")
    return {"skipped": False, "row": row}


def _parse_steps(raw) -> set[int]:
    if isinstance(raw, list):
        return {int(x) for x in raw}
    return {int(x.strip()) for x in str(raw).split(",") if x.strip()}


def _v0_reports_match_config(task_dir: Path, cfg: dict) -> bool:
    acc_path = task_dir / "nodes" / "v0_naive_cuda" / "report_acc.json"
    perf_path = task_dir / "nodes" / "v0_naive_cuda" / "report_perf.json"
    if not acc_path.is_file() or not perf_path.is_file():
        return False
    try:
        acc = json.loads(acc_path.read_text())
        perf = json.loads(perf_path.read_text())
    except json.JSONDecodeError:
        return False
    if (acc.get("summary") or {}).get("status") != "OK":
        return False
    if perf.get("status") != "OK":
        return False
    got_steps = {
        int(obs["step"])
        for obs in acc.get("observations") or []
        if isinstance(obs, dict) and obs.get("step") is not None
    }
    return got_steps == _parse_steps(cfg.get("steps", ""))


def _remove_leaderboard_node(task_dir: Path, node_id: str) -> None:
    jsonl = task_dir / "leaderboard.jsonl"
    if not jsonl.is_file():
        return
    kept: list[dict] = []
    for line in jsonl.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if row.get("node_id") != node_id:
            kept.append(row)
    jsonl.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in kept))
    regenerate_md(task_dir)
