#!/bin/bash
# Submit detached A100 Slurm job for native-hydro Aker iterations.
#
# Usage:
#   bash scripts/submit_aker_hydro_run.sh hydro_f2_207k_fp64 5
#   bash scripts/submit_aker_hydro_run.sh hydro_f2_207k_fp64 10 2

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_DIR"

TASK=${1:?usage: bash scripts/submit_aker_hydro_run.sh <task> <rounds> [parallel]}
ROUNDS=${2:?usage: bash scripts/submit_aker_hydro_run.sh <task> <rounds> [parallel]}
PARALLEL=${3:-1}

SLURM_ACCOUNT=${SLURM_ACCOUNT:-${SLURM_JOB_ACCOUNT:-dlsim_a100-80gb-pcie}}
SLURM_PARTITION=${SLURM_PARTITION:-${SLURM_JOB_PARTITION:-a100-80gb-pcie@ts2/h12sswnt/1gpu-16cpu-128gb}}
SLURM_TIME=${SLURM_TIME:-04:00:00}

mkdir -p results/slurm

echo "Submitting Aker native-hydro job"
echo "  task:      $TASK"
echo "  rounds:    $ROUNDS"
echo "  parallel:  $PARALLEL"
echo "  account:   $SLURM_ACCOUNT"
echo "  partition: $SLURM_PARTITION"
echo "  time:      $SLURM_TIME"
echo

sbatch \
    --account="$SLURM_ACCOUNT" \
    --partition="$SLURM_PARTITION" \
    --time="$SLURM_TIME" \
    --gres=gpu:1 \
    --export=ALL \
    scripts/slurm_aker_hydro_run.sbatch "$TASK" "$ROUNDS" "$PARALLEL"
