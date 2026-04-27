#!/bin/bash
# Run hand-written native CUDA hydro on a single case.
#
# Usage:
#   bash run_native_cuda.sh <case> [steps=900] [repeat=3]
#
# Cases:
#   F1_6.7K_fp64
#   F2_24K_fp32, F2_24K_fp64
#   (F2_207K_* — skipped: TIME.DAT format incompatibility)
set -e

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
NATIVE_DIR="$REPO_DIR/cuda_native_impl"

CASE=$1
NSTEPS=${2:-900}
NRUNS=${3:-3}

if [[ -z "$CASE" ]]; then
    echo "Usage: bash run_native_cuda.sh <case> [nsteps] [nruns]"
    exit 1
fi

# Pick the right binary
case "$CASE" in
    F1_6.7K_fp64)
        BIN="$NATIVE_DIR/F1_hydro_native_fp64"
        DATA_DIR="$NATIVE_DIR/F1_native_data"
        ;;
    F1_6.7K_fp32)
        BIN="$NATIVE_DIR/F2_hydro_native_fp32"
        DATA_DIR="$NATIVE_DIR/F1_fp32_native_data"
        ;;
    F1_207K_fp64)
        BIN="$NATIVE_DIR/F1_hydro_native_fp64"
        DATA_DIR="$NATIVE_DIR/F1_207K_native_data"
        ;;
    F1_207K_fp32)
        BIN="$NATIVE_DIR/F2_hydro_native_fp32"
        DATA_DIR="$NATIVE_DIR/F1_207K_native_data"
        ;;
    F2_24K_fp32)
        BIN="$NATIVE_DIR/F2_hydro_native_fp32"
        DATA_DIR="$NATIVE_DIR/F2_24K_native_data"
        ;;
    F2_24K_fp64)
        BIN="$NATIVE_DIR/F1_hydro_native_fp64"
        DATA_DIR="$NATIVE_DIR/F2_24K_native_data"
        ;;
    F2_207K_fp32)
        BIN="$NATIVE_DIR/F2_hydro_native_fp32"
        DATA_DIR="$NATIVE_DIR/F2_207K_native_data"
        ;;
    F2_207K_fp64)
        BIN="$NATIVE_DIR/F1_hydro_native_fp64"
        DATA_DIR="$NATIVE_DIR/F2_207K_native_data"
        ;;
    *)
        echo "ERROR: unknown case '$CASE'"
        exit 1
        ;;
esac

if [[ ! -x "$BIN" ]]; then
    echo "ERROR: binary not found: $BIN"
    echo "  Run: cd cuda_native_impl && bash build.sh sm_80"
    exit 1
fi

if [[ ! -d "$DATA_DIR/run" ]]; then
    echo "ERROR: data dir not setup: $DATA_DIR/run"
    exit 1
fi

cd "$DATA_DIR/run"
OUT=$("$BIN" "$NSTEPS" "$NRUNS" 2>&1)

# Parse: "Graph: median=X ms, Y us/step"
GRAPH_US=$(echo "$OUT" | grep "^Graph:" | grep -oE '[0-9.]+ us/step' | grep -oE '[0-9.]+' | head -1)
SYNC_US=$(echo "$OUT" | grep "^Sync:" | grep -oE '[0-9.]+ us/step' | grep -oE '[0-9.]+' | head -1)
ASYNC_US=$(echo "$OUT" | grep "^Async:" | grep -oE '[0-9.]+ us/step' | grep -oE '[0-9.]+' | head -1)

echo "RESULT={\"case\": \"$CASE\", \"framework\": \"native_cuda\", \"sync_us\": ${SYNC_US:-null}, \"async_us\": ${ASYNC_US:-null}, \"graph_us\": ${GRAPH_US:-null}, \"steps\": $NSTEPS}"
