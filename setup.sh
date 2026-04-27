#!/bin/bash
# hydro-bench: setup virtual env, install deps, build CUDA binaries.
#
# Usage:
#   bash setup.sh                  # full setup
#   bash setup.sh --venv-only      # skip CUDA build
#   bash setup.sh --cuda-only      # skip venv
set -e

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$REPO_DIR"

VENV_DIR="$REPO_DIR/venv"
DO_VENV=1
DO_CUDA=1
for arg in "$@"; do
    case "$arg" in
        --venv-only) DO_CUDA=0 ;;
        --cuda-only) DO_VENV=0 ;;
        --help|-h)
            echo "Usage: bash setup.sh [--venv-only|--cuda-only]"
            exit 0
            ;;
    esac
done

# ----- 1. Python venv + dependencies -----
if [[ $DO_VENV == 1 ]]; then
    echo "[1/3] Creating Python venv at $VENV_DIR..."
    if [[ ! -d "$VENV_DIR" ]]; then
        python3 -m venv "$VENV_DIR"
    fi
    "$VENV_DIR/bin/pip" install --upgrade pip
    "$VENV_DIR/bin/pip" install -r "$REPO_DIR/requirements.txt"
    echo "  venv ready: $VENV_DIR"
fi

# ----- 2. CUDA toolkit detection -----
NVCC=${NVCC:-$(which nvcc 2>/dev/null || echo "")}
if [[ -z "$NVCC" || ! -x "$NVCC" ]]; then
    # Fall back to common locations
    for p in /usr/local/cuda/bin/nvcc /opt/cuda/bin/nvcc; do
        if [[ -x "$p" ]]; then NVCC=$p; break; fi
    done
fi
if [[ -z "$NVCC" || ! -x "$NVCC" ]]; then
    echo "ERROR: nvcc not found. Set NVCC env var, e.g.:"
    echo "  NVCC=/path/to/cuda/bin/nvcc bash setup.sh"
    exit 1
fi
echo "  Using nvcc: $NVCC"
"$NVCC" --version | grep release

# ----- 3. Build CUDA harness -----
if [[ $DO_CUDA == 1 ]]; then
    echo "[2/3] Building CUDA persistent_bench binaries..."
    cd "$REPO_DIR/cuda_impl"
    # Detect SM architecture from GPU
    GPU_ARCH=${GPU_ARCH:-80}  # default A100 sm_80; override via env
    echo "  Target SM: $GPU_ARCH (override via GPU_ARCH=<num> bash setup.sh)"

    # Build driver PTX (already provided as .ptx, but rebuild if .cu modified)
    "$NVCC" -arch=sm_$GPU_ARCH -ptx -rdc=true F1_driver.cu -o F1_driver.ptx
    "$NVCC" -arch=sm_$GPU_ARCH -ptx -rdc=true F2_driver.cu -o F2_driver.ptx

    # Build executables
    "$NVCC" -O3 -arch=sm_$GPU_ARCH -rdc=true F1_persistent_bench.cu \
        -o F1_persistent_bench -lcuda -lcudadevrt
    "$NVCC" -O3 -arch=sm_$GPU_ARCH -rdc=true F2_persistent_bench.cu \
        -o F2_persistent_bench -lcuda -lcudadevrt
    echo "  built: cuda_impl/F1_persistent_bench, cuda_impl/F2_persistent_bench"
fi

echo "[3/3] Setup complete."
echo
echo "To run benchmarks:"
echo "  source venv/bin/activate"
echo "  bash scripts/run_benchmark.sh        # all 5 cases"
echo "  bash scripts/run_benchmark.sh F2_24K_fp32   # single case"
