"""Multi-checkpoint Taichi vs native CUDA alignment validator.

For each requested case and step checkpoint, the script:
  1. Runs native CUDA via the appropriate benchmark binary in --dump mode.
  2. Runs Taichi once per case, using the new ``on_step`` callback to
     dump per-checkpoint state without restarting the Taichi process.
  3. Computes per-field distribution statistics (max/mean/p50/p90/p99/p99.9
     plus threshold counts at 1e-7, 1e-5, 1e-3, 1e-1) and worst-3 cells
     (with KLAS edge classes from the mesh loader).
  4. Computes conservation quantities (mass, momentum X/Y, kinetic
     energy, potential energy, KLAS=10 inflow, KLAS=1 inflow) and
     compares relative diffs.
  5. Emits a JSON report per (case, step) and appends a Markdown row to
     ``results/alignment/SUMMARY.md``.

Usage::

    python scripts/check_correctness.py <case> [--steps 1,100,900] [--out-dir DIR]
    python scripts/check_correctness.py all [--steps 1,100,900]
    python scripts/check_correctness.py <case> <step>           # legacy single step

Cases::

    F1_6.7K_{fp32,fp64}   F1_207K_{fp32,fp64}
    F2_24K_{fp32,fp64}    F2_207K_{fp32,fp64}
    all                   shorthand for all eight

The script supports the 207K cases (the prior "skip" comment is
historical — boundary timeseries are loaded by the mesh loaders).
"""
import argparse
import json
import os
import re
import struct
import subprocess
import sys

import numpy as np

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NATIVE_DIR = os.path.join(REPO_DIR, "cuda_native_impl")
TAICHI_DIR = os.path.join(REPO_DIR, "taichi_impl")
RESULTS_DIR = os.path.join(REPO_DIR, "results", "alignment")

PY_VENV = os.path.join(REPO_DIR, "venv", "bin", "python")
PY = PY_VENV if os.path.isfile(PY_VENV) else "/home/scratch.huanhuanc_gpu/spmd/spmd-venv/bin/python"

ALL_CASES = [
    "F1_6.7K_fp32", "F1_6.7K_fp64",
    "F1_207K_fp32", "F1_207K_fp64",
    "F2_24K_fp32",  "F2_24K_fp64",
    "F2_207K_fp32", "F2_207K_fp64",
]
GRAVITY = 9.81

# Strict thresholds taken verbatim from the immutable Acceptance
# Criteria in scripts/alignment_plan.md. Do not weaken these.
TOLERANCES = {
    "fp64_state_max_abs": 1e-9,
    "fp64_state_p99": 1e-11,
    "fp64_conservation_rel": 1e-12,
    "fp32_step1_state_max_abs": 1e-6,
    "fp32_step1_flux_max_abs": 1e-5,
    "fp32_step1_bit_exact_frac": 0.99,
    "fp32_long_conservation_rel": 1e-5,
    "fp32_long_p99": 1e-3,
    # AC-10: OUTPUT files for fp32 step >= 100 must be >= 99% lines
    # identical and H-deviating lines must be |Δ| < 0.01.
    "fp32_long_output_lines_match_frac": 0.99,
    "fp32_long_output_h_max_abs": 0.01,
}


# ---------------------------------------------------------------------------
# Case configuration
# ---------------------------------------------------------------------------

def case_config(case):
    """Return ``(native_binary, native_data_subdir, real_size_bytes)``."""
    table = {
        "F1_6.7K_fp32":  ("F2_hydro_native_fp32", "F1_fp32_native_data", 4),
        "F1_6.7K_fp64":  ("F1_hydro_native_fp64", "F1_native_data",      8),
        "F1_207K_fp32":  ("F2_hydro_native_fp32", "F1_207K_native_data", 4),
        "F1_207K_fp64":  ("F1_hydro_native_fp64", "F1_207K_native_data", 8),
        "F2_24K_fp32":   ("F2_hydro_native_fp32", "F2_24K_native_data",  4),
        "F2_24K_fp64":   ("F1_hydro_native_fp64", "F2_24K_native_data",  8),
        "F2_207K_fp32":  ("F2_hydro_native_fp32", "F2_207K_native_data", 4),
        "F2_207K_fp64":  ("F1_hydro_native_fp64", "F2_207K_native_data", 8),
    }
    if case not in table:
        raise ValueError(f"Unknown case: {case}")
    return table[case]


def case_precision(case):
    return "fp64" if case.endswith("fp64") else "fp32"


def case_size(case):
    return 4 if case_precision(case) == "fp32" else 8


def case_dtype(case):
    return np.float32 if case_size(case) == 4 else np.float64


# ---------------------------------------------------------------------------
# Mesh-side metadata: load AREA, KLAS, NAC, SIDE for conservation + worst-cell
# ---------------------------------------------------------------------------

def load_mesh_metadata(case):
    """Load AREA (per cell), KLAS / NAC / SIDE (per edge) via the mesh loader.

    Returns a tuple ``(area, klas_edge, nac_edge, side_edge)`` of numpy
    arrays. The arrays are 0-indexed and use the same per-cell layout that
    the Taichi side produces.
    """
    sys.path.insert(0, TAICHI_DIR)
    if case.startswith("F1"):
        import mesh_loader_f1 as mlf1

        mesh_name = "20w" if "207K" in case else "default"
        m = mlf1.load_hydro_mesh(mesh=mesh_name, dtype=np.float64)
        cel = m["CEL"]
        klas2d = m["KLAS"]
        nac2d = m["NAC"]
        side2d = m["SIDE"]
        klas_edge = np.zeros(cel * 4, dtype=np.int32)
        nac_edge = np.zeros(cel * 4, dtype=np.int32)
        side_edge = np.zeros(cel * 4, dtype=np.float64)
        for c in range(cel):
            for j in range(4):
                klas_edge[4 * c + j] = int(klas2d[j + 1, c + 1])
                nac_edge[4 * c + j] = int(nac2d[j + 1, c + 1])
                side_edge[4 * c + j] = float(side2d[j + 1, c + 1])
        area = np.asarray(m["AREA"])[1:].astype(np.float64).copy()
    else:
        import mesh_loader_f2 as mlf2

        mesh_name = "20w" if "207K" in case else "default"
        m = mlf2.load_mesh(mesh=mesh_name, dtype=np.float64)
        klas_edge = np.asarray(m["KLAS"]).astype(np.int32).copy()
        nac_edge = np.asarray(m["NAC"]).astype(np.int32).copy()
        side_edge = np.asarray(m["SIDE"]).astype(np.float64).copy()
        area = np.asarray(m["AREA"]).astype(np.float64).copy()
    return area, klas_edge, nac_edge, side_edge


# ---------------------------------------------------------------------------
# Dump helpers: native CUDA + Taichi (single dump per call)
# ---------------------------------------------------------------------------

def _read_state_dump(path, sz, has_geom_block):
    dtype = np.float32 if sz == 4 else np.float64
    with open(path, "rb") as f:
        cell = struct.unpack("i", f.read(4))[0]
        H = np.frombuffer(f.read(cell * sz), dtype=dtype).copy()
        U = np.frombuffer(f.read(cell * sz), dtype=dtype).copy()
        V = np.frombuffer(f.read(cell * sz), dtype=dtype).copy()
        Z = np.frombuffer(f.read(cell * sz), dtype=dtype).copy()
        nsides = cell * 4
        if has_geom_block:
            f.read(nsides * sz * 3)  # SLCOS, SLSIN, SIDE
        F0 = np.frombuffer(f.read(nsides * sz), dtype=dtype).copy()
        F1 = np.frombuffer(f.read(nsides * sz), dtype=dtype).copy()
        F2 = np.frombuffer(f.read(nsides * sz), dtype=dtype).copy()
        F3 = np.frombuffer(f.read(nsides * sz), dtype=dtype).copy()
    W = np.sqrt(U * U + V * V).astype(dtype)
    return {"cell": cell, "H": H, "U": U, "V": V, "Z": Z, "W": W,
            "F0": F0, "F1": F1, "F2": F2, "F3": F3}


def dump_native_at_step(case, step, output_dir=None):
    """Run the native binary for ``step`` steps in dump mode.

    When ``output_dir`` is given, the run is invoked with
    ``--with-output --ntoutput 1`` and the case's ``OUTPUT/`` directory
    is copied into ``output_dir`` after the run, so subsequent
    checkpoints don't overwrite each other.
    """
    import shutil

    bin_name, data_subdir, sz = case_config(case)
    bin_path = os.path.join(NATIVE_DIR, bin_name)
    cwd = os.path.join(NATIVE_DIR, data_subdir, "run")
    case_output_dir = os.path.join(NATIVE_DIR, data_subdir, "OUTPUT")
    dump_file = os.path.join(cwd, f"native_dump_{case}_{step}_{os.getpid()}.bin")
    if os.path.exists(dump_file):
        os.remove(dump_file)

    cmd = [bin_path, str(step), "1", "--dump", dump_file]
    if output_dir is not None:
        cmd += ["--with-output", "--ntoutput", "1"]
        # Truncate any prior OUTPUT files so the upcoming run starts clean.
        for fn in ("H2U2V2.OUT", "ZUV.OUT", "SIDE.OUT", "XY-TEC.DAT", "TIMELOG.OUT"):
            p = os.path.join(case_output_dir, fn)
            try:
                open(p, "w").close()
            except FileNotFoundError:
                pass
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=1800)
    if r.returncode != 0 or not os.path.exists(dump_file):
        sys.stderr.write(f"  native dump FAILED for {case} step={step}: rc={r.returncode}\n")
        sys.stderr.write(f"    stderr tail: {r.stderr[-500:]}\n")
        return None
    if output_dir is not None:
        os.makedirs(output_dir, exist_ok=True)
        for fn in ("H2U2V2.OUT", "ZUV.OUT", "SIDE.OUT", "XY-TEC.DAT", "TIMELOG.OUT"):
            src = os.path.join(case_output_dir, fn)
            if os.path.exists(src):
                shutil.copy(src, os.path.join(output_dir, fn))
    return _read_state_dump(dump_file, sz, has_geom_block=True)


def dump_taichi_at_step(case, step, output_dir=None):
    """Run Taichi from a fresh subprocess to ``step`` steps and dump.

    When ``output_dir`` is given, the Taichi side also writes the five
    native-format OUTPUT files at the initial frame (jt=0, kt=1) and
    again at the final step using ``output_writer.OutputWriter``.
    """
    sz = case_size(case)
    case_kind = "F1" if case.startswith("F1") else "F2"
    fp_kind = "fp64" if case.endswith("fp64") else "fp32"
    mesh_name = "20w" if "207K" in case else "default"
    bin_path = os.path.join(NATIVE_DIR, f"{case}_taichi_dump_{step}_{os.getpid()}.bin")
    if os.path.exists(bin_path):
        os.remove(bin_path)
    output_dir_repr = repr(output_dir) if output_dir is not None else "None"

    code = f"""
import os, sys, struct
import numpy as np
sys.path.insert(0, {TAICHI_DIR!r})

case_kind = {case_kind!r}
fp_kind = {fp_kind!r}
mesh_name = {mesh_name!r}
step = {step}
bin_path = {bin_path!r}
output_dir = {output_dir_repr}

if case_kind == 'F1':
    if fp_kind == 'fp64':
        from F1_hydro_taichi_2kernel_fp64 import run_real as run_case
        from mesh_loader_f1 import load_hydro_mesh as load_mesh
        mesh_dict = load_mesh(mesh=mesh_name, dtype=np.float64)
    else:
        from F1_hydro_taichi_2kernel_fp32 import run_real as run_case
        from mesh_loader_f1 import load_hydro_mesh as load_mesh
        mesh_dict = load_mesh(mesh=mesh_name, dtype=np.float32)
    res = run_case(steps=step, backend='cuda', mesh=mesh_name)
    mdt = float(mesh_dict.get('MDT', 3600))
    dt = float(mesh_dict.get('DT', 1.0))
    ndays = int(mesh_dict.get('NDAYS', 50))
else:
    if fp_kind == 'fp64':
        from F2_hydro_taichi_fp64 import run as run_case
        from mesh_loader_f2 import load_mesh
        mesh_dict = load_mesh(mesh=mesh_name, dtype=np.float64)
    else:
        from F2_hydro_taichi_fp32 import run as run_case
        from mesh_loader_f2 import load_mesh
        mesh_dict = load_mesh(mesh=mesh_name, dtype=np.float32)
    res = run_case(days=1, backend='cuda', mesh=mesh_name, steps=step)
    mdt = float(mesh_dict['MDT'])
    dt = float(mesh_dict['DT'])
    ndays = int(mesh_dict['NDAYS'])

step_fn, sync_fn, H, U, V, Z, F0, F1, F2, F3 = res[:10]
steps_per_day = max(int(round(mdt / dt)), 1)

writer = None
if output_dir is not None:
    from output_writer import OutputWriter
    writer = OutputWriter(output_dir, mesh_dict, dt, ndays)
    # Initial frame matches native's outputToFile(0, 1) at first call.
    writer.write_frame(0, 1, {{
        'H': H.to_numpy(),
        'U': U.to_numpy(),
        'V': V.to_numpy(),
        'Z': Z.to_numpy(),
    }})


def final_dump():
    arrs = [a.to_numpy() for a in (H, U, V, Z, F0, F1, F2, F3)]
    with open(bin_path, 'wb') as f:
        f.write(struct.pack('i', arrs[0].size))
        for a in arrs:
            f.write(a.tobytes())
    if writer is not None:
        # Translate the linear step index back into (jt, kt). Step ``s``
        # comes from the loop ``for day; for kt in range(1, steps_per_day)``,
        # so kt = ((s-1) % (steps_per_day-1)) + 1, day = (s-1) // (steps_per_day-1).
        last_step = step
        per_day = max(steps_per_day - 1, 1)
        kt = ((last_step - 1) % per_day) + 1
        day = (last_step - 1) // per_day
        writer.write_frame(day, kt + 1, {{
            'H': arrs[0], 'U': arrs[1], 'V': arrs[2], 'Z': arrs[3],
        }})
        writer.close()


step_fn()
sync_fn()
final_dump()
print('TAICHI_DONE', flush=True)
"""
    r = subprocess.run([PY, "-c", code], capture_output=True, text=True, timeout=1800)
    if r.returncode != 0 or "TAICHI_DONE" not in r.stdout:
        sys.stderr.write(f"  Taichi run FAILED for {case} step={step}: rc={r.returncode}\n")
        sys.stderr.write(f"    stderr tail: {r.stderr[-800:]}\n")
        return None
    if not os.path.exists(bin_path):
        return None
    return _read_state_dump(bin_path, sz, has_geom_block=False)


def dump_taichi_multi_step(case, steps, out_dir_base=None):
    """Run Taichi ONCE per case and capture state at every requested step.

    Uses the ``on_step(step_index)`` callback exposed by all four fp64
    Taichi entry points to dump per-checkpoint state without restarting
    the Taichi process. When ``out_dir_base`` is given, each checkpoint
    also gets its own ``{out_dir_base}/{case}_step{N}/`` directory with
    the five OUTPUT files (initial frame at jt=0,kt=1 plus the frame at
    that step).

    Returns ``{step: state_dict}`` covering exactly the requested
    checkpoints (any missing entries indicate a Taichi failure).
    """
    sz = case_size(case)
    case_kind = "F1" if case.startswith("F1") else "F2"
    fp_kind = "fp64" if case.endswith("fp64") else "fp32"
    mesh_name = "20w" if "207K" in case else "default"
    max_step = max(steps)
    pid = os.getpid()
    bin_dir = os.path.join(NATIVE_DIR, f".taichi_multi_{case}_{pid}")
    os.makedirs(bin_dir, exist_ok=True)
    sorted_steps = sorted(set(int(s) for s in steps))
    step_set_repr = repr(sorted_steps)
    out_dir_base_repr = repr(out_dir_base) if out_dir_base is not None else "None"
    case_repr = repr(case)

    code = f"""
import os, sys, struct
import numpy as np
sys.path.insert(0, {TAICHI_DIR!r})

case_kind = {case_kind!r}
fp_kind = {fp_kind!r}
mesh_name = {mesh_name!r}
checkpoint_steps = set({step_set_repr})
max_step = {max_step}
bin_dir = {bin_dir!r}
case_name = {case_repr}
out_dir_base = {out_dir_base_repr}

if case_kind == 'F1':
    if fp_kind == 'fp64':
        from F1_hydro_taichi_2kernel_fp64 import run_real as run_case
        from mesh_loader_f1 import load_hydro_mesh as load_mesh
        mesh_dict = load_mesh(mesh=mesh_name, dtype=np.float64)
    else:
        from F1_hydro_taichi_2kernel_fp32 import run_real as run_case
        from mesh_loader_f1 import load_hydro_mesh as load_mesh
        mesh_dict = load_mesh(mesh=mesh_name, dtype=np.float32)
    res = run_case(steps=max_step, backend='cuda', mesh=mesh_name)
else:
    if fp_kind == 'fp64':
        from F2_hydro_taichi_fp64 import run as run_case
        from mesh_loader_f2 import load_mesh
        mesh_dict = load_mesh(mesh=mesh_name, dtype=np.float64)
    else:
        from F2_hydro_taichi_fp32 import run as run_case
        from mesh_loader_f2 import load_mesh
        mesh_dict = load_mesh(mesh=mesh_name, dtype=np.float32)
    res = run_case(days=1, backend='cuda', mesh=mesh_name, steps=max_step)

step_fn, sync_fn, H, U, V, Z, F0, F1, F2, F3 = res[:10]
mdt = float(mesh_dict.get('MDT', 3600))
dt = float(mesh_dict.get('DT', 1.0))
ndays = int(mesh_dict.get('NDAYS', 50))
steps_per_day = max(int(round(mdt / dt)), 1)
per_day = max(steps_per_day - 1, 1)
# Alignment runs use NTOUTPUT=1 (every day) per the plan; native's
# runStepsWithOutput cadence overrides TIME.DAT's value with --ntoutput
# 1. Mirror that here so the Taichi writer produces the same frame set.
ntoutput = 1

# Pre-create per-checkpoint OutputWriters keyed by step. Each writer
# accumulates the SAME native-frame-set up to its checkpoint:
#   1. Initial frame at jt=0, kt=1.
#   2. End-of-day frames at every step s where s % per_day == 0 and
#      ((s/per_day) % NTOUTPUT == 0), for s < checkpoint.
#   3. Final frame at the checkpoint step itself (with whatever
#      (day, kt+1) that step lands on, even if mid-day).
# This matches native's runStepsWithOutput exactly: native writes at
# end-of-day plus a forced final-frame write when s == n.
writers = {{}}
if out_dir_base is not None:
    from output_writer import OutputWriter
    for s in checkpoint_steps:
        d = os.path.join(out_dir_base, f"{{case_name}}_step{{s}}")
        os.makedirs(d, exist_ok=True)
        w = OutputWriter(d, mesh_dict, dt, ndays)
        w.write_frame(0, 1, {{
            'H': H.to_numpy(), 'U': U.to_numpy(),
            'V': V.to_numpy(), 'Z': Z.to_numpy(),
        }})
        writers[s] = w


def _dump_state(step_idx):
    arrs = [a.to_numpy() for a in (H, U, V, Z, F0, F1, F2, F3)]
    bin_path = os.path.join(bin_dir, f"step_{{step_idx}}.bin")
    with open(bin_path, 'wb') as f:
        f.write(struct.pack('i', arrs[0].size))
        for a in arrs:
            f.write(a.tobytes())


def on_step_cb(s):
    is_checkpoint = s in checkpoint_steps
    is_eod = (s % per_day == 0) and (((s // per_day)) % ntoutput == 0)
    if not (is_checkpoint or is_eod):
        return
    if is_checkpoint:
        _dump_state(s)
    if not writers:
        return
    kt = ((s - 1) % per_day) + 1
    day = (s - 1) // per_day
    state_arrs = None
    for cp in list(writers.keys()):
        if s == cp:
            # Final frame for this writer (whether or not also EOD).
            if state_arrs is None:
                state_arrs = {{
                    'H': H.to_numpy(), 'U': U.to_numpy(),
                    'V': V.to_numpy(), 'Z': Z.to_numpy(),
                }}
            writers[cp].write_frame(day, kt + 1, state_arrs)
            writers[cp].close()
            del writers[cp]
        elif is_eod and s < cp:
            # End-of-day frame for a writer whose checkpoint is later.
            if state_arrs is None:
                state_arrs = {{
                    'H': H.to_numpy(), 'U': U.to_numpy(),
                    'V': V.to_numpy(), 'Z': Z.to_numpy(),
                }}
            writers[cp].write_frame(day, kt + 1, state_arrs)


step_fn(on_step=on_step_cb)
sync_fn()
print('TAICHI_DONE', flush=True)
"""
    r = subprocess.run([PY, "-c", code], capture_output=True, text=True, timeout=3600)
    if r.returncode != 0 or "TAICHI_DONE" not in r.stdout:
        sys.stderr.write(f"  Taichi multi-step run FAILED for {case}: rc={r.returncode}\n")
        sys.stderr.write(f"    stderr tail: {r.stderr[-800:]}\n")
        return {}
    states = {}
    for s in sorted_steps:
        bp = os.path.join(bin_dir, f"step_{s}.bin")
        if os.path.isfile(bp):
            states[s] = _read_state_dump(bp, sz, has_geom_block=False)
            os.remove(bp)
    try:
        os.rmdir(bin_dir)
    except OSError:
        pass
    return states


# ---------------------------------------------------------------------------
# Stats + conservation
# ---------------------------------------------------------------------------

def _percentile_in_dtype(arr_diff_abs):
    if arr_diff_abs.size == 0:
        return {p: 0.0 for p in (50, 90, 99, 99.9)}
    return {
        50: float(np.percentile(arr_diff_abs, 50)),
        90: float(np.percentile(arr_diff_abs, 90)),
        99: float(np.percentile(arr_diff_abs, 99)),
        99.9: float(np.percentile(arr_diff_abs, 99.9)),
    }


def _per_field_stats(name, native_arr, taichi_arr, klas_edge=None, nac_edge=None,
                     n_cells=None):
    n_native = len(native_arr)
    n_taichi = len(taichi_arr)
    n = min(n_native, n_taichi)
    # Drop any 1-indexed sentinel from Taichi side defensively.
    if n_taichi == n_native + 1:
        taichi_arr = taichi_arr[1:]
        n = n_native
    a = native_arr[:n].astype(np.float64)
    b = taichi_arr[:n].astype(np.float64)
    finite = np.isfinite(a) & np.isfinite(b)
    if not finite.any():
        return {"all_nonfinite": True}
    a_f = a[finite]
    b_f = b[finite]
    diff = np.abs(a_f - b_f)
    pct = _percentile_in_dtype(diff)
    counts = {f"diff_gt_{t:.0e}": int((diff > t).sum()) for t in (1e-13, 1e-11, 1e-9, 1e-7)}
    bit_exact_frac = float((diff == 0).sum()) / float(len(diff))
    out = {
        "max_abs": float(diff.max()),
        "mean_abs": float(diff.mean()),
        "percentiles": pct,
        "threshold_counts": counts,
        "bit_exact_frac": bit_exact_frac,
        "n_finite": int(finite.sum()),
        "n_total": int(n),
    }

    is_edge = name.startswith("F") and len(name) == 2  # F0..F3
    diff_full = np.abs(a - b)
    diff_full[~finite] = -1.0
    top_idx = np.argsort(diff_full)[-3:][::-1]
    top = []
    for i in top_idx:
        if diff_full[i] < 0:
            continue
        record = {"idx": int(i), "native": float(a[i]), "taichi": float(b[i]),
                  "abs_diff": float(diff_full[i])}
        if klas_edge is not None and n_cells is not None:
            cell_i = int(i // 4) if is_edge else int(i)
            local_klas = [int(klas_edge[4 * cell_i + k]) for k in range(4)]
            if is_edge:
                edge_j = int(i % 4)
                record["cell"] = cell_i
                record["edge_j"] = edge_j
                record["klas"] = int(klas_edge[i])
            else:
                record["klas"] = local_klas
            # neighbor_klas is the KLAS edge list of each NEIGHBOUR cell
            # (across each of the four edges of cell_i). NAC stores the
            # neighbour cell index 1-indexed; 0 means no neighbour.
            if nac_edge is not None:
                neighbours = []
                for k in range(4):
                    neigh = int(nac_edge[4 * cell_i + k]) - 1  # 0-indexed
                    if neigh < 0 or neigh >= n_cells:
                        neighbours.append(None)
                    else:
                        neighbours.append([int(klas_edge[4 * neigh + j]) for j in range(4)])
                record["neighbor_klas"] = neighbours
            else:
                record["neighbor_klas"] = []
        top.append(record)
    out["worst_cells"] = top
    return out


def _kahan_sum(arr):
    """Neumaier-Kahan compensated summation.

    For an array of length N, naive ``sum`` accumulates O(N · eps)
    relative error. Kahan-Neumaier reduces that to O(eps) regardless
    of N. This matters for the cancellation-heavy conservation sums
    (momentum, BC inflow) where the value floor is dominated by
    summation noise rather than per-cell state divergence.
    """
    s = 0.0
    c = 0.0
    for x in arr:
        t = s + x
        if abs(s) >= abs(x):
            c += (s - t) + x
        else:
            c += (x - t) + s
        s = t
    return float(s + c)


def _conservation_metrics(state, area, klas_edge, side_edge):
    H = state["H"].astype(np.float64)
    U = state["U"].astype(np.float64)
    V = state["V"].astype(np.float64)
    n = min(len(H), len(area))
    H = H[:n]
    U = U[:n]
    V = V[:n]
    a = area[:n]
    F0 = state["F0"].astype(np.float64)
    n_e = min(len(F0), len(klas_edge), len(side_edge))
    F0 = F0[:n_e]
    klas_e = klas_edge[:n_e]
    side_e = side_edge[:n_e]
    # Use Kahan summation throughout so the calculator's own noise
    # floor is O(eps), not O(N · eps). This separates pure-summation
    # error from real per-cell state divergence between native and
    # Taichi.
    mass = _kahan_sum(H * a)
    momx = _kahan_sum(H * U * a)
    momy = _kahan_sum(H * V * a)
    kin = _kahan_sum(0.5 * H * (U * U + V * V) * a)
    pot = _kahan_sum(0.5 * GRAVITY * H * H * a)
    klas10_mask = klas_e == 10
    klas1_mask = klas_e == 1
    klas10_inflow = _kahan_sum(F0 * side_e * klas10_mask)
    klas1_inflow = _kahan_sum(F0 * side_e * klas1_mask)
    return {
        "mass": mass,
        "momentum_x": momx,
        "momentum_y": momy,
        "kinetic_energy": kin,
        "potential_energy": pot,
        "klas10_inflow": klas10_inflow,
        "klas1_inflow": klas1_inflow,
    }


def _conservation_diffs(native_metrics, taichi_metrics):
    out = {}
    for k in native_metrics:
        n = native_metrics[k]
        t = taichi_metrics[k]
        denom = max(abs(n), 1e-30)
        out[k] = {
            "native": n,
            "taichi": t,
            "abs_diff": abs(n - t),
            "rel_diff": abs(n - t) / denom,
        }
    return out


def _top_cell_contributors(native_state, taichi_state, area, klas_edge, side_edge,
                           top_k=5):
    """Identify the top-K cells/edges contributing to the dominant
    conservation rel_diff terms (momentum_x and klas1_inflow).

    For ``momentum_x`` the per-cell contribution is
    ``H[i] * U[i] * area[i]``; the per-cell delta is the |native-Taichi|
    of that product. For ``klas1_inflow`` the per-edge contribution is
    ``F0[e] * side[e]`` masked to KLAS == 1; the per-edge delta is the
    same |native-Taichi| over those edges only. The returned dict feeds
    a ``contributors`` block in the JSON report so future rounds can
    drill into the few cells whose accumulation order or BC handling
    actually moves the rel_diff above 1e-12.
    """
    out = {}
    nH = native_state["H"].astype(np.float64)
    nU = native_state["U"].astype(np.float64)
    tH = taichi_state["H"].astype(np.float64)
    tU = taichi_state["U"].astype(np.float64)
    n = min(len(nH), len(area))
    a = area[:n]
    momx_native = nH[:n] * nU[:n] * a
    momx_taichi = tH[:n] * tU[:n] * a
    momx_delta = np.abs(momx_native - momx_taichi)
    top = np.argsort(momx_delta)[::-1][:top_k]
    out["momentum_x"] = [
        {"idx": int(i),
         "native_contrib": float(momx_native[i]),
         "taichi_contrib": float(momx_taichi[i]),
         "abs_delta": float(momx_delta[i]),
         "klas": [int(klas_edge[4 * int(i) + j]) for j in range(4)]
                 if 4 * int(i) + 3 < len(klas_edge) else []}
        for i in top
    ]

    nF0 = native_state["F0"].astype(np.float64)
    tF0 = taichi_state["F0"].astype(np.float64)
    n_e = min(len(nF0), len(klas_edge), len(side_edge))
    klas1_mask = klas_edge[:n_e] == 1
    if klas1_mask.any():
        klas1_idx = np.flatnonzero(klas1_mask)
        side1 = side_edge[klas1_idx]
        nf1 = nF0[klas1_idx] * side1
        tf1 = tF0[klas1_idx] * side1
        d1 = np.abs(nf1 - tf1)
        top1 = np.argsort(d1)[::-1][:top_k]
        out["klas1_inflow"] = [
            {"edge_idx": int(klas1_idx[i]),
             "cell": int(klas1_idx[i]) // 4,
             "edge_j": int(klas1_idx[i]) % 4,
             "native_contrib": float(nf1[i]),
             "taichi_contrib": float(tf1[i]),
             "abs_delta": float(d1[i])}
            for i in top1
        ]
    else:
        out["klas1_inflow"] = []
    return out


def _verdict_for(case, step, field_stats, cons_diffs, health):
    """Classify a (case, step) result as PASS / FAIL based on plan thresholds.

    fp64 (any step):
        all conservation rel_diff < 1e-12, all state field max_abs < 1e-9,
        p99 < 1e-11, no NaN/Inf.
    fp32 step=1:
        bit_exact_frac >= 0.99 for state, max_abs < 1e-6 (state), max_abs <
        1e-5 (flux), no NaN/Inf.
    fp32 step >= 100:
        all conservation rel_diff < 1e-5, p99 < 1e-3 per field, no NaN/Inf.
    """
    prec = case_precision(case)
    state_fields = ("H", "U", "V", "Z", "W")
    flux_fields = ("F0", "F1", "F2", "F3")
    if not all(field_stats[f] and not field_stats[f].get("all_nonfinite", False)
               for f in state_fields):
        return "FAIL", "non-finite cells in state"
    if health.get("nan_count", 0) > 0 or health.get("inf_count", 0) > 0:
        return "FAIL", f"NaN/Inf detected: {health}"

    output_block = field_stats.get("_output", None)

    if prec == "fp64":
        for f in state_fields:
            s = field_stats[f]
            if s["max_abs"] >= TOLERANCES["fp64_state_max_abs"]:
                return "FAIL", f"{f}.max_abs={s['max_abs']:.3e} >= 1e-9"
            if s["percentiles"][99] >= TOLERANCES["fp64_state_p99"]:
                return "FAIL", f"{f}.p99={s['percentiles'][99]:.3e} >= 1e-11"
        for k, v in cons_diffs.items():
            if v["rel_diff"] >= TOLERANCES["fp64_conservation_rel"]:
                return "FAIL", f"conservation/{k} rel={v['rel_diff']:.3e} >= 1e-12"
        if output_block is not None:
            for fname, info in output_block.items():
                if not info.get("text_match", False):
                    return "FAIL", f"OUTPUT/{fname} not byte-identical"
        return "PASS", "fp64 thresholds met"

    if step == 1:
        for f in state_fields:
            s = field_stats[f]
            if s["bit_exact_frac"] < TOLERANCES["fp32_step1_bit_exact_frac"]:
                return "FAIL", f"{f}.bit_exact_frac={s['bit_exact_frac']:.4f} < 0.99"
            if s["max_abs"] >= TOLERANCES["fp32_step1_state_max_abs"]:
                return "FAIL", f"{f}.max_abs={s['max_abs']:.3e} >= 1e-6"
        for f in flux_fields:
            s = field_stats[f]
            if s and not s.get("all_nonfinite", False):
                if s["max_abs"] >= TOLERANCES["fp32_step1_flux_max_abs"]:
                    return "FAIL", f"{f}.max_abs={s['max_abs']:.3e} >= 1e-5"
        if output_block is not None:
            for fname, info in output_block.items():
                if not info.get("text_match", False):
                    return "FAIL", f"OUTPUT/{fname} not byte-identical at step=1"
        return "PASS", "fp32 step=1 thresholds met"

    for f in state_fields:
        s = field_stats[f]
        if s["percentiles"][99] >= TOLERANCES["fp32_long_p99"]:
            return "FAIL", f"{f}.p99={s['percentiles'][99]:.3e} >= 1e-3"
    for k, v in cons_diffs.items():
        if v["rel_diff"] >= TOLERANCES["fp32_long_conservation_rel"]:
            return "FAIL", f"conservation/{k} rel={v['rel_diff']:.3e} >= 1e-5"
    if output_block is not None:
        for fname, info in output_block.items():
            frac_ok = info.get("lines_match_frac", 0.0)
            if frac_ok < TOLERANCES["fp32_long_output_lines_match_frac"]:
                return "FAIL", (f"OUTPUT/{fname} lines_match_frac={frac_ok:.4f} "
                               f"< {TOLERANCES['fp32_long_output_lines_match_frac']}")
            h_max = info.get("max_h_diff", 0.0)
            if h_max >= TOLERANCES["fp32_long_output_h_max_abs"]:
                return "FAIL", (f"OUTPUT/{fname} max_h_diff={h_max:.3e} "
                               f">= {TOLERANCES['fp32_long_output_h_max_abs']}")
    return "PASS", "fp32 long-step thresholds met"


# ---------------------------------------------------------------------------
# Main per-(case, step) evaluation
# ---------------------------------------------------------------------------

def _run_output_comparison(native_dir, taichi_dir, diffs_dir=None):
    """Invoke the OUTPUT comparator and adapt its result to verdict format.

    When ``diffs_dir`` is given, the comparator also writes per-file
    ``difflib.unified_diff`` artifacts to that directory.
    """
    import compare_output_files as cmp_mod

    report = cmp_mod.compare_dirs(native_dir, taichi_dir, diffs_dir=diffs_dir)
    out = {}
    for fname, entry in report["files"].items():
        text = entry.get("text", {})
        info = {
            "text_match": bool(text.get("text_match", False)),
            "diff_lines": int(text.get("diff_lines", 0)),
            "lines_a": int(text.get("lines_a", 0)),
            "lines_b": int(text.get("lines_b", 0)),
            "max_h_diff": 0.0,
            "max_u_diff": 0.0,
            "max_v_diff": 0.0,
            "max_z_diff": 0.0,
            "max_w_diff": 0.0,
            "max_fi_diff": 0.0,
            "structural_mismatch": [],
        }
        if not info["text_match"] and info["lines_a"] > 0:
            matched = max(info["lines_a"], info["lines_b"]) - info["diff_lines"]
            info["lines_match_frac"] = max(0.0, matched / max(info["lines_a"], info["lines_b"]))
        else:
            info["lines_match_frac"] = 1.0 if info["text_match"] else 0.0
        for fkey in ("H2", "U2", "V2", "Z2", "W2", "FI"):
            pass
        for frame_key, frame in entry.get("numeric", {}).items():
            for key in ("max_h_diff", "max_u_diff", "max_v_diff", "max_z_diff",
                        "max_w_diff", "max_fi_diff"):
                info[key] = max(info[key], float(frame.get(key, 0.0)))
            for sm in frame.get("structural_mismatch", []):
                info["structural_mismatch"].append(f"{frame_key}: {sm}")
        out[fname] = info
    return out


def evaluate_case(case, steps, out_dir):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    bin_name, _, _ = case_config(case)
    bin_path = os.path.join(NATIVE_DIR, bin_name)
    if not os.path.isfile(bin_path):
        sys.stderr.write(f"SKIP {case}: native binary not found at {bin_path}\n")
        return []

    print(f"\n=== {case} (steps={steps}) ===")
    area, klas_edge, nac_edge, side_edge = load_mesh_metadata(case)
    n_cells = int(len(area))

    rows = []
    # Single Taichi run per case: on_step captures every requested
    # checkpoint without restarting the Taichi process. Each checkpoint
    # gets its own ``taichi_outputs/{case}_step{N}/`` directory written
    # from inside the same run.
    taichi_outputs_root = os.path.join(out_dir, "taichi_outputs")
    for step in steps:
        d = os.path.join(taichi_outputs_root, f"{case}_step{step}")
        if os.path.isdir(d):
            for fn in os.listdir(d):
                p = os.path.join(d, fn)
                if os.path.isfile(p):
                    os.remove(p)
    print(f"  Running Taichi once with on_step over checkpoints {steps} ...", flush=True)
    taichi_states = dump_taichi_multi_step(case, steps, out_dir_base=taichi_outputs_root)

    for step in steps:
        print(f"  [step={step}] comparing against native ...", flush=True)
        native_out = os.path.join(out_dir, "native_outputs", f"{case}_step{step}")
        if os.path.isdir(native_out):
            for fn in os.listdir(native_out):
                p = os.path.join(native_out, fn)
                if os.path.isfile(p):
                    os.remove(p)
        taichi_out = os.path.join(taichi_outputs_root, f"{case}_step{step}")

        native_state = dump_native_at_step(case, step, output_dir=native_out)
        taichi_state = taichi_states.get(step)
        if native_state is None or taichi_state is None:
            # Per Codex review (round 2/3): silent-skip lets a partial
            # matrix masquerade as completed. Emit an explicit FAIL
            # row plus a placeholder JSON whose schema is identical to
            # a normal report (every required block present, every
            # required key populated with default-FAIL stats), so
            # validate_alignment_json.py still passes on a missing-
            # artifact report.
            missing = []
            if native_state is None:
                missing.append("native")
            if taichi_state is None:
                missing.append("taichi")
            reason = f"dump missing on side(s): {','.join(missing)}"
            print(f"    -> FAIL: {reason}")
            field_placeholder = {
                "max_abs": float("inf"),
                "mean_abs": float("inf"),
                "percentiles": {"50": float("inf"), "90": float("inf"),
                                "99": float("inf"), "99.9": float("inf")},
                "threshold_counts": {"diff_gt_1e-13": 0, "diff_gt_1e-11": 0,
                                     "diff_gt_1e-09": 0, "diff_gt_1e-07": 0},
                "bit_exact_frac": 0.0,
                "n_finite": 0,
                "n_total": 0,
                "worst_cells": [],
                "all_nonfinite": True,
            }
            output_file_placeholder = {
                "text_match": False,
                "lines_match_frac": 0.0,
                "max_h_diff": float("inf"),
                "max_u_diff": float("inf"),
                "max_v_diff": float("inf"),
                "max_z_diff": float("inf"),
                "max_w_diff": float("inf"),
                "max_fi_diff": float("inf"),
                "structural_mismatch": [reason],
            }
            placeholder = {
                "case": case,
                "step": step,
                "precision": case_precision(case),
                "fields": {f: dict(field_placeholder)
                           for f in ("H", "U", "V", "Z", "W", "F0", "F1", "F2", "F3")},
                "output_files": {fname: dict(output_file_placeholder)
                                 for fname in ("H2U2V2.OUT", "ZUV.OUT", "SIDE.OUT",
                                               "XY-TEC.DAT", "TIMELOG.OUT")},
                "conservation": {k: {"native": float("nan"), "taichi": float("nan"),
                                     "abs_diff": float("inf"), "rel_diff": float("inf")}
                                 for k in ("mass", "momentum_x", "momentum_y",
                                           "kinetic_energy", "potential_energy",
                                           "klas10_inflow", "klas1_inflow")},
                "contributors": {"momentum_x": [], "klas1_inflow": []},
                "health": {"missing_sides": missing},
                "verdict": "FAIL",
                "reason": reason,
            }
            os.makedirs(out_dir, exist_ok=True)
            with open(os.path.join(out_dir, f"{case}_step{step}.json"), "w") as f:
                json.dump(placeholder, f, indent=2)
            rows.append(placeholder)
            continue

        field_stats = {}
        for f in ("H", "U", "V", "Z", "W"):
            field_stats[f] = _per_field_stats(f, native_state[f], taichi_state[f],
                                              klas_edge=klas_edge, nac_edge=nac_edge,
                                              n_cells=n_cells)
        for f in ("F0", "F1", "F2", "F3"):
            field_stats[f] = _per_field_stats(f, native_state[f], taichi_state[f],
                                              klas_edge=klas_edge, nac_edge=nac_edge,
                                              n_cells=n_cells)

        native_metrics = _conservation_metrics(native_state, area, klas_edge, side_edge)
        taichi_metrics = _conservation_metrics(taichi_state, area, klas_edge, side_edge)
        cons_diffs = _conservation_diffs(native_metrics, taichi_metrics)
        contributors = _top_cell_contributors(
            native_state, taichi_state, area, klas_edge, side_edge, top_k=5,
        )

        H_native = native_state["H"]
        H_taichi = taichi_state["H"]
        n = min(len(H_native), len(H_taichi))
        health = {
            "n_cells": n,
            "finite_native": int(np.isfinite(H_native[:n]).sum()),
            "finite_taichi": int(np.isfinite(H_taichi[:n]).sum()),
            "nan_count": int((~np.isfinite(H_native[:n])).sum() + (~np.isfinite(H_taichi[:n])).sum()),
            "inf_count": int(np.isinf(H_native[:n]).sum() + np.isinf(H_taichi[:n]).sum()),
            "h_native_min": float(H_native[:n].min()),
            "h_native_max": float(H_native[:n].max()),
            "h_taichi_min": float(H_taichi[:n].min()),
            "h_taichi_max": float(H_taichi[:n].max()),
        }

        # OUTPUT-file comparator results (Taichi side wrote both initial
        # and final-step frames; native side wrote the same via
        # `--with-output --ntoutput 1`). Per-file unified diffs land in
        # results/alignment/diffs/{case}_step{N}/ for inspection.
        diffs_dir = os.path.join(out_dir, "diffs", f"{case}_step{step}")
        output_block = _run_output_comparison(native_out, taichi_out, diffs_dir=diffs_dir)
        field_stats["_output"] = output_block

        verdict, reason = _verdict_for(case, step, field_stats, cons_diffs, health)
        report = {
            "case": case,
            "step": step,
            "precision": case_precision(case),
            "fields": {k: v for k, v in field_stats.items() if k != "_output"},
            "output_files": output_block,
            "conservation": cons_diffs,
            "contributors": contributors,
            "health": health,
            "verdict": verdict,
            "reason": reason,
        }

        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, f"{case}_step{step}.json")
        with open(out_path, "w") as f:
            json.dump(report, f, indent=2)
        print(f"    -> {verdict}: {reason}  [{out_path}]")
        rows.append(report)
    return rows


# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

_SUMMARY_HEADER = (
    "| case | step | precision | verdict | H max_abs | U max_abs | V max_abs | Z max_abs "
    "| mass rel | KE rel | momentum_x rel | klas1_inflow rel | reason |"
)
_SUMMARY_DIVIDER = (
    "|------|------|-----------|---------|-----------|-----------|-----------|-----------"
    "|----------|--------|----------------|------------------|--------|"
)


def _row_to_md(r):
    H = r["fields"]["H"]
    U = r["fields"]["U"]
    V = r["fields"]["V"]
    Z = r["fields"]["Z"]
    cons = r["conservation"]
    return (
        f"| {r['case']} | {r['step']} | {r.get('precision', '')} | {r['verdict']} | "
        f"{H['max_abs']:.3e} | {U['max_abs']:.3e} | {V['max_abs']:.3e} | {Z['max_abs']:.3e} | "
        f"{cons['mass']['rel_diff']:.3e} | {cons['kinetic_energy']['rel_diff']:.3e} | "
        f"{cons['momentum_x']['rel_diff']:.3e} | {cons['klas1_inflow']['rel_diff']:.3e} | "
        f"{r['reason']} |"
    )


_JSON_NAME_RE = re.compile(r"^(?P<case>.+)_step(?P<step>\d+)\.json$")


def _scan_json_artifacts(out_dir):
    """Read every ``{case}_step{N}.json`` file in ``out_dir``.

    Returns a ``{(case, step): report_dict}`` map. Files that fail to
    parse are skipped with a stderr warning so a single corrupt JSON
    cannot block the rest of the summary.
    """
    found = {}
    if not os.path.isdir(out_dir):
        return found
    for name in os.listdir(out_dir):
        m = _JSON_NAME_RE.match(name)
        if not m:
            continue
        path = os.path.join(out_dir, name)
        try:
            with open(path) as f:
                report = json.load(f)
        except (OSError, json.JSONDecodeError) as exc:
            sys.stderr.write(f"  WARN: could not load {path}: {exc}\n")
            continue
        case = report.get("case") or m.group("case")
        step = int(report.get("step", m.group("step")))
        found[(case, step)] = report
    return found


def write_summary_md(rows, out_dir):
    """Rebuild SUMMARY.md authoritatively from JSON artifacts on disk.

    Rows from this invocation overwrite their JSON files first; the
    summary is then assembled by scanning every ``{case}_step{N}.json``
    actually present in ``out_dir``. Stale rows whose JSONs were deleted
    are dropped — the SUMMARY.md is a faithful index of on-disk JSONs.
    """
    summary_path = os.path.join(out_dir, "SUMMARY.md")
    artifacts = _scan_json_artifacts(out_dir)
    # Reports from this invocation are already on disk (written before
    # write_summary_md is called), so artifacts already includes them.
    # The ``rows`` argument is kept for backwards compatibility with
    # callers that pass the in-memory list, but is intentionally
    # unused — disk is the source of truth.
    _ = rows
    if not artifacts:
        # Empty out_dir: rewrite an empty (header-only) summary so a
        # subsequent inspector sees an authoritative blank table rather
        # than a stale one.
        body = [
            "# Alignment Validation Summary",
            "",
            "**0 PASS / 0 FAIL of 0 entries.**",
            "",
            _SUMMARY_HEADER,
            _SUMMARY_DIVIDER,
        ]
        with open(summary_path, "w") as f:
            f.write("\n".join(body) + "\n")
        print(f"\nSummary written to {summary_path} (0 rows — no JSON artifacts found)")
        return
    n_pass = sum(1 for k in artifacts if artifacts[k].get("verdict") == "PASS")
    n_fail = len(artifacts) - n_pass
    body = [
        "# Alignment Validation Summary",
        "",
        f"**{n_pass} PASS / {n_fail} FAIL of {len(artifacts)} entries.**",
        "",
        _SUMMARY_HEADER,
        _SUMMARY_DIVIDER,
    ]
    for key in sorted(artifacts):
        body.append(_row_to_md(artifacts[key]))
    with open(summary_path, "w") as f:
        f.write("\n".join(body) + "\n")
    print(f"\nSummary written to {summary_path} ({len(artifacts)} rows: {n_pass} PASS / {n_fail} FAIL)")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def parse_args(argv):
    p = argparse.ArgumentParser(
        description=(
            "Multi-checkpoint alignment validator. "
            "Backwards-compatible legacy form: 'check_correctness.py <case> <step>'."
        )
    )
    p.add_argument("case", help="Case name (e.g. F2_207K_fp32) or 'all'")
    p.add_argument("step_or_steps", nargs="?", default=None,
                   help="Legacy single-step value when --steps is not provided.")
    p.add_argument("--steps", default=None,
                   help="Comma-separated step list. Overrides positional argument.")
    p.add_argument("--out-dir", default=RESULTS_DIR,
                   help="Directory for JSON reports + SUMMARY.md")
    return p.parse_args(argv)


def main(argv=None):
    args = parse_args(argv if argv is not None else sys.argv[1:])
    if args.steps:
        steps = [int(s) for s in args.steps.split(",") if s.strip()]
    elif args.step_or_steps:
        steps = [int(args.step_or_steps)]
    else:
        steps = [50]
    if args.case == "all":
        cases = ALL_CASES
    else:
        cases = [args.case]

    # AC-2.3 idempotence: per-(case, step) JSONs are owned by THIS
    # invocation and rewritten from scratch. SUMMARY.md is merged: rows
    # from this run overwrite matching keys but earlier rows for other
    # (case, step) combinations survive. That way a partial run does
    # not erase prior successful results.
    os.makedirs(args.out_dir, exist_ok=True)
    for case in cases:
        for step in steps:
            stale = os.path.join(args.out_dir, f"{case}_step{step}.json")
            if os.path.exists(stale):
                os.remove(stale)

    all_rows = []
    for case in cases:
        rows = evaluate_case(case, steps, args.out_dir)
        all_rows.extend(rows)
    write_summary_md(all_rows, args.out_dir)
    failed = [r for r in all_rows if r["verdict"] != "PASS"]
    print(f"\n{len(all_rows) - len(failed)} PASS / {len(failed)} FAIL of {len(all_rows)} entries.")
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
