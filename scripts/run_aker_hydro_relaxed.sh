#!/bin/bash
# One-command launcher for the relaxed numerical Aker hydro track.
#
# Default track:
#   - task:  hydro_f2_207k_fp64_relaxed_s899
#   - case:  F2_207K_fp64
#   - steps: 1,10,100,899
#   - gate:  state max<=1e-12 / p99<=1e-13, flux max<=1e-9 / p99<=1e-11
#
# Usage:
#   bash scripts/run_aker_hydro_relaxed.sh
#   bash scripts/run_aker_hydro_relaxed.sh <rounds> [task] [case]
#
# Common overrides:
#   PARALLEL=5 TIMEOUT_SEC=21600 bash scripts/run_aker_hydro_relaxed.sh 50
#   INIT_ONLY=1 bash scripts/run_aker_hydro_relaxed.sh
#   RELAXED_LONG=1 bash scripts/run_aker_hydro_relaxed.sh 50
#
# Threshold overrides:
#   STATE_MAX_ABS=1e-12 STATE_P99=1e-13 FLUX_MAX_ABS=1e-9 FLUX_P99=1e-11 \
#     bash scripts/run_aker_hydro_relaxed.sh 50

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_DIR"

if [[ "${RELAXED_LONG:-0}" == "1" ]]; then
    DEFAULT_TASK=hydro_f2_207k_fp64_relaxed_7199
    DEFAULT_STEPS=1,10,100,899,7199
    DEFAULT_STATE_MAX_ABS=1e-9
    DEFAULT_STATE_P99=1e-12
    DEFAULT_FLUX_MAX_ABS=1e-7
    DEFAULT_FLUX_P99=1e-10
else
    DEFAULT_TASK=hydro_f2_207k_fp64_relaxed_s899
    DEFAULT_STEPS=1,10,100,899
    DEFAULT_STATE_MAX_ABS=1e-12
    DEFAULT_STATE_P99=1e-13
    DEFAULT_FLUX_MAX_ABS=1e-9
    DEFAULT_FLUX_P99=1e-11
fi

ROUNDS=${1:-${ROUNDS:-50}}
TASK=${2:-${TASK:-$DEFAULT_TASK}}
CASE=${3:-${CASE:-F2_207K_fp64}}

TASK_ROOT=${TASK_ROOT:-Aker/tasks}
STEPS=${STEPS:-$DEFAULT_STEPS}
PERF_STEPS=${PERF_STEPS:-100}
PERF_REPEAT=${PERF_REPEAT:-3}
GPU_ARCH=${GPU_ARCH:-sm_80}
PARALLEL=${PARALLEL:-5}
TIMEOUT_SEC=${TIMEOUT_SEC:-21600}
AKER_BACKEND=${AKER_BACKEND:-codex}

STATE_MAX_ABS=${STATE_MAX_ABS:-$DEFAULT_STATE_MAX_ABS}
STATE_P99=${STATE_P99:-$DEFAULT_STATE_P99}
FLUX_MAX_ABS=${FLUX_MAX_ABS:-$DEFAULT_FLUX_MAX_ABS}
FLUX_P99=${FLUX_P99:-$DEFAULT_FLUX_P99}

export PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/bin:$REPO_DIR/.local_venv/bin:$PATH
export LD_LIBRARY_PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/lib64:${LD_LIBRARY_PATH:-}

TASK_DIR="$TASK_ROOT/$TASK"
CONFIG="$TASK_DIR/task_config.json"

echo "repo:       $REPO_DIR"
echo "task_root:  $TASK_ROOT"
echo "task:       $TASK"
echo "case:       $CASE"
echo "rounds:     $ROUNDS"
echo "parallel:   $PARALLEL"
echo "backend:    $AKER_BACKEND"
echo "steps:      $STEPS"
echo "thresholds: state max=$STATE_MAX_ABS p99=$STATE_P99; flux max=$FLUX_MAX_ABS p99=$FLUX_P99"
echo

if [[ ! -f "$CONFIG" ]]; then
    echo "[init] creating relaxed native-hydro task"
    aker --task-root "$TASK_ROOT" hydro-init "$TASK" \
        --repo-root "$REPO_DIR" \
        --case "$CASE" \
        --steps "$STEPS" \
        --perf-steps "$PERF_STEPS" \
        --perf-repeat "$PERF_REPEAT" \
        --gpu-arch "$GPU_ARCH"
else
    echo "[init] task already exists: $TASK_DIR"
fi

echo "[config] applying relaxed thresholds"
HYDRO_TASK_CONFIG="$CONFIG" \
HYDRO_REPO_ROOT="$REPO_DIR" \
HYDRO_CASE="$CASE" \
HYDRO_STEPS="$STEPS" \
HYDRO_PERF_STEPS="$PERF_STEPS" \
HYDRO_PERF_REPEAT="$PERF_REPEAT" \
HYDRO_GPU_ARCH="$GPU_ARCH" \
HYDRO_STATE_MAX_ABS="$STATE_MAX_ABS" \
HYDRO_STATE_P99="$STATE_P99" \
HYDRO_FLUX_MAX_ABS="$FLUX_MAX_ABS" \
HYDRO_FLUX_P99="$FLUX_P99" \
python - <<'PY'
import json
import os
from pathlib import Path

p = Path(os.environ["HYDRO_TASK_CONFIG"])
d = json.loads(p.read_text())
d.update({
    "mode": "native_hydro",
    "repo_root": os.environ["HYDRO_REPO_ROOT"],
    "case": os.environ["HYDRO_CASE"],
    "steps": os.environ["HYDRO_STEPS"],
    "perf_steps": int(os.environ["HYDRO_PERF_STEPS"]),
    "perf_repeat": int(os.environ["HYDRO_PERF_REPEAT"]),
    "gpu_arch": os.environ["HYDRO_GPU_ARCH"],
    "state_max_abs": float(os.environ["HYDRO_STATE_MAX_ABS"]),
    "state_p99": float(os.environ["HYDRO_STATE_P99"]),
    "flux_max_abs": float(os.environ["HYDRO_FLUX_MAX_ABS"]),
    "flux_p99": float(os.environ["HYDRO_FLUX_P99"]),
})
p.write_text(json.dumps(d, indent=2) + "\n")
PY

SPEC="$TASK_DIR/spec.md"
if [[ -f "$SPEC" ]] && ! grep -q "## Relaxed Numerical Track" "$SPEC"; then
    cat >>"$SPEC" <<EOF

## Relaxed Numerical Track

This task intentionally uses relaxed native-v0 alignment thresholds instead of
bit-exact equality. Current thresholds are:

- State fields \`H/U/V/Z/W\`: max_abs <= \`$STATE_MAX_ABS\`, p99 <= \`$STATE_P99\`
- Flux fields \`F0/F1/F2/F3\`: max_abs <= \`$FLUX_MAX_ABS\`, p99 <= \`$FLUX_P99\`

NaN/Inf, shape mismatch, benchmark failure, and reviewer policy failures remain
hard failures. Keep the exact task separate from this relaxed exploratory track.
EOF
fi

GUIDANCE_TTL=${GUIDANCE_TTL:-$((ROUNDS + PARALLEL + 5))}
if [[ "$GUIDANCE_TTL" -lt 10 ]]; then
    GUIDANCE_TTL=10
fi

echo "[guidance] writing relaxed-track guidance for $GUIDANCE_TTL reservation opens"
aker --task-root "$TASK_ROOT" hint "$TASK" --for "$GUIDANCE_TTL" <<EOF
This is the relaxed numerical track for F2_207K_fp64 native CUDA.

The exact track remains the deliverable-safe baseline. In this track, small
native-v0 drift is allowed by task_config.json: state max_abs=$STATE_MAX_ABS,
state p99=$STATE_P99, flux max_abs=$FLUX_MAX_ABS, flux p99=$FLUX_P99.
NaN/Inf and shape mismatch are still hard failures.

Use this freedom for optimizations that may change fp64 operation order slightly:
common-subexpression elimination, helper refactoring, branch simplification,
scratch reduction, and targeted CalculateFluxKernel restructuring. Do not change
the physical model, data layout, host wrapper signatures, or benchmark meaning.

Primary performance target remains async ms/step. Use profile_sass/ncu_dynamic
as guidance: reduce dynamic FP64 instruction count, branch/predicate work, and
redundant boundary/Osher helper work in CalculateFluxKernel.
EOF

if [[ "${INIT_ONLY:-0}" == "1" || "$ROUNDS" -lt 1 ]]; then
    echo
    echo "initialized relaxed task only; not starting Aker run"
    echo "start later with:"
    echo "  PARALLEL=$PARALLEL AKER_BACKEND=$AKER_BACKEND TIMEOUT_SEC=$TIMEOUT_SEC bash scripts/run_aker_hydro_relaxed.sh 50 $TASK $CASE"
    exit 0
fi

echo
echo "[run] launching relaxed Aker run"
AKER_BACKEND="$AKER_BACKEND" \
PARALLEL="$PARALLEL" \
TIMEOUT_SEC="$TIMEOUT_SEC" \
STEPS="$STEPS" \
PERF_STEPS="$PERF_STEPS" \
PERF_REPEAT="$PERF_REPEAT" \
GPU_ARCH="$GPU_ARCH" \
TASK_ROOT="$TASK_ROOT" \
bash scripts/run_aker_hydro_direct.sh "$ROUNDS" "$TASK" "$CASE"
