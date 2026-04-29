#!/bin/bash
# Detached Slurm runner for native-hydro Aker iterations.
#
# Submit via:
#   bash scripts/submit_aker_hydro_run.sh hydro_f2_207k_fp64 5

#SBATCH --job-name=aker-hydro
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=04:00:00
#SBATCH --output=results/slurm/%x-%j.out
#SBATCH --error=results/slurm/%x-%j.err

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_DIR"

TASK=${1:?usage: slurm_aker_hydro_run.sbatch <task> <rounds> [parallel]}
ROUNDS=${2:?usage: slurm_aker_hydro_run.sbatch <task> <rounds> [parallel]}
PARALLEL=${3:-1}

TASK_ROOT=${TASK_ROOT:-$REPO_DIR/Aker/tasks}
TIMEOUT_SEC=${TIMEOUT_SEC:-14400}
AKER_BACKEND=${AKER_BACKEND:-codex}
AKER_TEST_ACC_TIMEOUT_SEC=${AKER_TEST_ACC_TIMEOUT_SEC:-14400}
AKER_TEST_PERF_TIMEOUT_SEC=${AKER_TEST_PERF_TIMEOUT_SEC:-14400}
AKER_LOG_LEVEL=${AKER_LOG_LEVEL:-INFO}

CODEX_NATIVE=/home/tools_ai/openai/codex/latest/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex/codex
if [[ "$AKER_BACKEND" == "codex" ]] && ! codex --version >/dev/null 2>&1 && [[ -x "$CODEX_NATIVE" ]]; then
    export AKER_CODEX_BINARY="$CODEX_NATIVE"
fi

export AKER_BACKEND AKER_TEST_ACC_TIMEOUT_SEC AKER_TEST_PERF_TIMEOUT_SEC AKER_LOG_LEVEL
export PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/bin:$REPO_DIR/.local_venv/bin:$PATH
export LD_LIBRARY_PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/lib64:${LD_LIBRARY_PATH:-}

mkdir -p results/slurm

echo "repo:      $REPO_DIR"
echo "task_root: $TASK_ROOT"
echo "task:      $TASK"
echo "rounds:    $ROUNDS"
echo "parallel:  $PARALLEL"
echo "backend:   $AKER_BACKEND"
echo "job_id:    ${SLURM_JOB_ID:-none}"
echo "node:      ${SLURMD_NODENAME:-unknown}"
echo

nvidia-smi -L || true

echo
echo "[seed] v0 leaderboard row if needed"
aker --task-root "$TASK_ROOT" hydro-seed "$TASK" || true

echo
echo "[run] Aker native-hydro iteration"
aker --task-root "$TASK_ROOT" --timeout-sec "$TIMEOUT_SEC" run "$TASK" \
    --rounds "$ROUNDS" \
    --parallel "$PARALLEL"
