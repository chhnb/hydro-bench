#!/bin/bash
# Run native-hydro Aker directly inside an already allocated A100 shell.
#
# Usage:
#   bash scripts/run_aker_hydro_direct.sh
#   bash scripts/run_aker_hydro_direct.sh <rounds> [task] [case]
#
# Examples:
#   bash scripts/run_aker_hydro_direct.sh 1
#   bash scripts/run_aker_hydro_direct.sh 5 hydro_f2_207k_fp64 F2_207K_fp64
#
# Optional env overrides:
#   AKER_BACKEND=codex|claude
#   TASK_ROOT=Aker/tasks
#   STEPS=1,10,100,899,7199
#   PERF_STEPS=100
#   PERF_REPEAT=3
#   GPU_ARCH=sm_80
#   PARALLEL=1
#   TIMEOUT_SEC=14400

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_DIR"

ROUNDS=${1:-1}
TASK=${2:-hydro_f2_207k_fp64}
CASE=${3:-F2_207K_fp64}

TASK_ROOT=${TASK_ROOT:-Aker/tasks}
STEPS=${STEPS:-1,10,100,899,7199}
PERF_STEPS=${PERF_STEPS:-100}
PERF_REPEAT=${PERF_REPEAT:-3}
GPU_ARCH=${GPU_ARCH:-sm_80}
PARALLEL=${PARALLEL:-1}
TIMEOUT_SEC=${TIMEOUT_SEC:-14400}

export PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/bin:$REPO_DIR/.local_venv/bin:$PATH
export LD_LIBRARY_PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/lib64:${LD_LIBRARY_PATH:-}
export AKER_TEST_ACC_TIMEOUT_SEC=${AKER_TEST_ACC_TIMEOUT_SEC:-$TIMEOUT_SEC}
export AKER_TEST_PERF_TIMEOUT_SEC=${AKER_TEST_PERF_TIMEOUT_SEC:-$TIMEOUT_SEC}

CODEX_NATIVE="$REPO_DIR/.no-such-codex"
if [[ -x /home/tools_ai/openai/codex/latest/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex/codex ]]; then
    CODEX_NATIVE=/home/tools_ai/openai/codex/latest/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex/codex
fi

if [[ -z "${AKER_BACKEND:-}" ]]; then
    if command -v codex >/dev/null 2>&1 && codex --version >/dev/null 2>&1; then
        export AKER_BACKEND=codex
    elif command -v claude >/dev/null 2>&1 && claude --version >/dev/null 2>&1; then
        export AKER_BACKEND=claude
    elif [[ -x "$CODEX_NATIVE" ]] && "$CODEX_NATIVE" --version >/dev/null 2>&1; then
        export AKER_BACKEND=codex
        export AKER_CODEX_BINARY="$CODEX_NATIVE"
    else
        echo "ERROR: neither codex nor claude backend is runnable on PATH." >&2
        exit 2
    fi
fi

if [[ "$AKER_BACKEND" == "codex" ]]; then
    if command -v codex >/dev/null 2>&1 && codex --version >/dev/null 2>&1; then
        :
    elif [[ -x "$CODEX_NATIVE" ]] && "$CODEX_NATIVE" --version >/dev/null 2>&1; then
        export AKER_CODEX_BINARY="$CODEX_NATIVE"
        echo "[backend] codex wrapper is broken; using native binary: $AKER_CODEX_BINARY"
    else
        echo "ERROR: AKER_BACKEND=codex but no runnable codex binary was found." >&2
        exit 2
    fi
elif [[ "$AKER_BACKEND" == "claude" ]]; then
    if ! command -v claude >/dev/null 2>&1 || ! claude --version >/dev/null 2>&1; then
        echo "ERROR: AKER_BACKEND=claude but claude is not runnable." >&2
        exit 2
    fi
fi

case "$CASE" in
    *_fp32)
        BENCH="$REPO_DIR/cuda_native_impl/fp32_src/hydro_native_benchmark"
        ;;
    *_fp64)
        BENCH="$REPO_DIR/cuda_native_impl/hydro_native_benchmark"
        ;;
    *)
        echo "ERROR: cannot infer precision from CASE=$CASE" >&2
        exit 2
        ;;
esac

case "$CASE" in
    F1_6.7K_fp32) DATA_RUN="$REPO_DIR/cuda_native_impl/F1_fp32_native_data/run" ;;
    F1_6.7K_fp64) DATA_RUN="$REPO_DIR/cuda_native_impl/F1_native_data/run" ;;
    F1_207K_fp32|F1_207K_fp64) DATA_RUN="$REPO_DIR/cuda_native_impl/F1_207K_native_data/run" ;;
    F2_24K_fp32|F2_24K_fp64) DATA_RUN="$REPO_DIR/cuda_native_impl/F2_24K_native_data/run" ;;
    F2_207K_fp32|F2_207K_fp64) DATA_RUN="$REPO_DIR/cuda_native_impl/F2_207K_native_data/run" ;;
    *)
        echo "ERROR: unknown case $CASE" >&2
        exit 2
        ;;
esac

build_native_benchmark() {
    echo "[build] native benchmark for $CASE (arch=$GPU_ARCH)"
    if [[ "$CASE" == *_fp32 ]]; then
        bash cuda_native_impl/fp32_src/build.sh "$GPU_ARCH"
    else
        bash cuda_native_impl/build.sh "$GPU_ARCH"
    fi
}

run_smoke_test() {
    (
        cd "$DATA_RUN"
        "$BENCH" 1 1 >"$SMOKE_LOG" 2>&1
    )
}

report_smoke_failure() {
    echo "ERROR: native CUDA benchmark failed. Tail:" >&2
    tail -n 80 "$SMOKE_LOG" >&2 || true
    echo >&2
    echo "This shell can see a GPU, but CUDA runtime could not run the benchmark." >&2
    echo "Use a different A100 shell or submit with scripts/submit_aker_hydro_run.sh." >&2
}

echo "repo:       $REPO_DIR"
echo "task_root:  $TASK_ROOT"
echo "task:       $TASK"
echo "case:       $CASE"
echo "rounds:     $ROUNDS"
echo "parallel:   $PARALLEL"
echo "backend:    $AKER_BACKEND"
echo "gpu_arch:   $GPU_ARCH"
echo "steps:      $STEPS"
echo

echo "[check] GPU visibility"
nvidia-smi -L
echo

if [[ ! -x "$BENCH" ]]; then
    echo "[build] native benchmark binary missing"
    build_native_benchmark
fi

SMOKE_LOG=/tmp/aker_hydro_smoke_${USER:-user}_$$.log
echo "[check] CUDA runtime smoke test"
if ! run_smoke_test; then
    if grep -Eq 'GLIBCXX_[0-9]|GLIBC_[0-9]' "$SMOKE_LOG"; then
        echo "[build] existing benchmark is ABI-incompatible with this shell; rebuilding"
        build_native_benchmark
        echo "[check] CUDA runtime smoke test after rebuild"
        if ! run_smoke_test; then
            report_smoke_failure
            exit 3
        fi
    else
        report_smoke_failure
        exit 3
    fi
fi
tail -n 12 "$SMOKE_LOG" || true
rm -f "$SMOKE_LOG"
echo

if [[ ! -f "$TASK_ROOT/$TASK/task_config.json" ]]; then
    echo "[init] creating native-hydro task"
    aker --task-root "$TASK_ROOT" hydro-init "$TASK" \
        --repo-root "$REPO_DIR" \
        --case "$CASE" \
        --steps "$STEPS" \
        --perf-steps "$PERF_STEPS" \
        --perf-repeat "$PERF_REPEAT" \
        --gpu-arch "$GPU_ARCH"
else
    echo "[init] task already exists: $TASK_ROOT/$TASK"
    HYDRO_TASK_CONFIG="$TASK_ROOT/$TASK/task_config.json" \
    HYDRO_REPO_ROOT="$REPO_DIR" \
    HYDRO_CASE="$CASE" \
    HYDRO_STEPS="$STEPS" \
    HYDRO_PERF_STEPS="$PERF_STEPS" \
    HYDRO_PERF_REPEAT="$PERF_REPEAT" \
    HYDRO_GPU_ARCH="$GPU_ARCH" \
    python -c 'import json, os, pathlib
p = pathlib.Path(os.environ["HYDRO_TASK_CONFIG"])
d = json.loads(p.read_text())
d.update({
    "mode": "native_hydro",
    "repo_root": os.environ["HYDRO_REPO_ROOT"],
    "case": os.environ["HYDRO_CASE"],
    "steps": os.environ["HYDRO_STEPS"],
    "perf_steps": int(os.environ["HYDRO_PERF_STEPS"]),
    "perf_repeat": int(os.environ["HYDRO_PERF_REPEAT"]),
    "gpu_arch": os.environ["HYDRO_GPU_ARCH"],
})
p.write_text(json.dumps(d, indent=2) + "\n")'
fi
echo

echo "[seed] v0 baseline row"
aker --task-root "$TASK_ROOT" hydro-seed "$TASK"
echo

echo "[run] Aker native-hydro iteration"
aker --task-root "$TASK_ROOT" --timeout-sec "$TIMEOUT_SEC" run "$TASK" \
    --rounds "$ROUNDS" \
    --parallel "$PARALLEL"

echo
echo "[result] leaderboard"
cat "$TASK_ROOT/$TASK/leaderboard.md"
