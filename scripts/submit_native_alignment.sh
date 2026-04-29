#!/bin/bash
# Submit a detached A100 Slurm job for native CUDA baseline-vs-candidate checks.
#
# Usage:
#   bash scripts/submit_native_alignment.sh F2_207K_fp64 1,10,100,899
#   bash scripts/submit_native_alignment.sh F2_207K_fp32 1,10,100,899
#
# Optional env overrides:
#   SLURM_ACCOUNT=dlsim_a100-80gb-pcie
#   SLURM_PARTITION='a100-80gb-pcie@ts2/h12sswnt/1gpu-16cpu-128gb'
#   SLURM_TIME=04:00:00
#   GPU_ARCH=sm_80
#   OUT_DIR=results/native_alignment/my_run

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_DIR"

CASE=${1:?usage: bash scripts/submit_native_alignment.sh <case> <steps>}
STEPS=${2:?usage: bash scripts/submit_native_alignment.sh <case> <steps>}

SLURM_ACCOUNT=${SLURM_ACCOUNT:-${SLURM_JOB_ACCOUNT:-dlsim_a100-80gb-pcie}}
SLURM_PARTITION=${SLURM_PARTITION:-${SLURM_JOB_PARTITION:-a100-80gb-pcie@ts2/h12sswnt/1gpu-16cpu-128gb}}
SLURM_TIME=${SLURM_TIME:-04:00:00}

mkdir -p results/slurm

echo "Submitting native alignment job"
echo "  case:      $CASE"
echo "  steps:     $STEPS"
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
    scripts/slurm_native_alignment.sbatch "$CASE" "$STEPS"
