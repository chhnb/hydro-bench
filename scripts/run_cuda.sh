#!/bin/bash
# Run a single CUDA case and emit RESULT line.
#
# Usage:
#   bash run_cuda.sh <case>
#
# Cases:
#   F1_6.7K_fp64, F2_24K_fp32, F2_24K_fp64, F2_207K_fp32, F2_207K_fp64
set -e

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CASE=$1
NSTEPS=${2:-900}
NRUNS=${3:-3}

if [[ -z "$CASE" ]]; then
    echo "Usage: bash run_cuda.sh <case> [nsteps=900] [nruns=3]"
    exit 1
fi

DATA_DIR="$REPO_DIR/data/$CASE"
if [[ ! -d "$DATA_DIR" ]]; then
    echo "ERROR: data dir not found: $DATA_DIR"
    exit 1
fi

# Set HYDRO_BENCH_CUDA_DIR so the bench can find driver.ptx
export HYDRO_BENCH_CUDA_DIR="$REPO_DIR/cuda_impl"

if [[ "$CASE" == F1* ]]; then
    BIN="$REPO_DIR/cuda_impl/F1_persistent_bench"
    # F1 binary args: <data_dir> <CEL> [nsteps] [nruns] [max_regs]
    CELL=$(echo "$CASE" | grep -oE "[0-9.]+K" | sed 's/K//' | awk '{print int($1*1000)}')
    [[ "$CASE" == F1_6.7K* ]] && CELL=6675
    OUT=$("$BIN" "$DATA_DIR" "$CELL" "$NSTEPS" "$NRUNS" 0 2>&1 | grep "^CASE_RESULT" | tail -1)
else
    BIN="$REPO_DIR/cuda_impl/F2_persistent_bench"
    # F2 binary args: <data_dir> <NE> <CELL> <prec> [nsteps] [nruns] [max_regs]
    if [[ "$CASE" == F2_24K* ]]; then
        CELL=24020; NE=96080
    elif [[ "$CASE" == F2_207K* ]]; then
        CELL=207234; NE=828936
    fi
    PREC=fp32
    [[ "$CASE" == *fp64* ]] && PREC=fp64
    OUT=$("$BIN" "$DATA_DIR" "$NE" "$CELL" "$PREC" "$NSTEPS" "$NRUNS" 0 2>&1 | grep "^CASE_RESULT" | tail -1)
fi

# Parse: persistent_us=X graph_us=Y
PERSISTENT_US=$(echo "$OUT" | grep -oE 'persistent_us=[0-9.]+' | grep -oE '[0-9.]+')
GRAPH_US=$(echo "$OUT" | grep -oE 'graph_us=[0-9.]+' | grep -oE '[0-9.]+')

# Emit RESULT JSON line for the runner to parse
echo "RESULT={\"case\": \"$CASE\", \"framework\": \"cuda\", \"persistent_us\": $PERSISTENT_US, \"graph_us\": $GRAPH_US, \"steps\": $NSTEPS}"
