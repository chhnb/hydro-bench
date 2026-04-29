#!/bin/bash
# Slurm entrypoint for detached native CUDA baseline-vs-candidate checks.
#
# Submit via:
#   bash scripts/submit_native_alignment.sh F2_207K_fp64 1,10,100,899
#
# Optional env overrides:
#   GPU_ARCH=sm_80
#   OUT_DIR=results/native_alignment/<name>
#   BUILD_BASELINE=0
#   BUILD_CANDIDATE=0
#   STATE_MAX_ABS=0
#   STATE_P99=0
#   FLUX_MAX_ABS=0
#   FLUX_P99=0

#SBATCH --job-name=hydro-native-align
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=04:00:00
#SBATCH --output=results/slurm/%x-%j.out
#SBATCH --error=results/slurm/%x-%j.err

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_DIR"

CASE=${1:?usage: slurm_native_alignment.sbatch <case> <steps>}
STEPS=${2:?usage: slurm_native_alignment.sbatch <case> <steps>}

GPU_ARCH=${GPU_ARCH:-sm_80}
OUT_DIR=${OUT_DIR:-results/native_alignment/${CASE}_$(date +%Y%m%dT%H%M%S)}
BUILD_BASELINE=${BUILD_BASELINE:-0}
BUILD_CANDIDATE=${BUILD_CANDIDATE:-1}
STATE_MAX_ABS=${STATE_MAX_ABS:-0}
STATE_P99=${STATE_P99:-0}
FLUX_MAX_ABS=${FLUX_MAX_ABS:-0}
FLUX_P99=${FLUX_P99:-0}

mkdir -p results/slurm "$OUT_DIR"

echo "repo:      $REPO_DIR"
echo "case:      $CASE"
echo "steps:     $STEPS"
echo "gpu_arch:  $GPU_ARCH"
echo "out_dir:   $OUT_DIR"
echo "job_id:    ${SLURM_JOB_ID:-none}"
echo "node:      ${SLURMD_NODENAME:-unknown}"
echo

export PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/bin:$PATH
export LD_LIBRARY_PATH=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/lib64:${LD_LIBRARY_PATH:-}

nvidia-smi -L || true
nvcc --version | sed -n '1,4p'

if [[ "$BUILD_BASELINE" == "1" ]]; then
    echo
    echo "[build] frozen fp64 baseline"
    bash cuda_native_impl/baselines/native_cuda_v0/fp64/build.sh "$GPU_ARCH"
    echo
    echo "[build] frozen fp32 baseline"
    bash cuda_native_impl/baselines/native_cuda_v0/fp32/build.sh "$GPU_ARCH"
fi

if [[ "$BUILD_CANDIDATE" == "1" ]]; then
    case "$CASE" in
        *_fp32)
            echo
            echo "[build] current fp32 candidate"
            bash cuda_native_impl/fp32_src/build.sh "$GPU_ARCH"
            ;;
        *_fp64)
            echo
            echo "[build] current fp64 candidate"
            bash cuda_native_impl/build.sh "$GPU_ARCH"
            ;;
        *)
            echo "ERROR: cannot infer precision from CASE=$CASE" >&2
            exit 2
            ;;
    esac
fi

echo
echo "[check] baseline vs candidate"
python scripts/check_native_alignment.py "$CASE" \
    --steps "$STEPS" \
    --out-dir "$OUT_DIR" \
    --state-max-abs "$STATE_MAX_ABS" \
    --state-p99 "$STATE_P99" \
    --flux-max-abs "$FLUX_MAX_ABS" \
    --flux-p99 "$FLUX_P99"

echo
echo "done: $OUT_DIR/SUMMARY.md"
