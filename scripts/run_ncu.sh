#!/bin/bash
# Profile a hydro case with ncu to extract pure GPU kernel time.
#
# Usage:
#   bash run_ncu.sh <case> <framework>
#     framework: taichi or cuda
#
# Output: per-kernel mean GPU time in nanoseconds.
set -e

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
NCU=${NCU:-$(which ncu 2>/dev/null || echo "")}
[[ -z "$NCU" ]] && NCU=/home/scratch.huanhuanc_gpu/spmd/cuda-toolkit/bin/ncu

CASE=$1
FRAMEWORK=$2
NSKIP=${3:-50}    # warmup kernels to skip
NCOUNT=${4:-30}   # kernels to profile

if [[ -z "$CASE" || -z "$FRAMEWORK" ]]; then
    echo "Usage: bash run_ncu.sh <case> <taichi|cuda>"
    exit 1
fi

DATA_DIR="$REPO_DIR/data/$CASE"
TMPCSV=$(mktemp /tmp/ncu_XXXXXX.csv)

if [[ "$FRAMEWORK" == "taichi" ]]; then
    PY="$REPO_DIR/venv/bin/python"
    [[ ! -x "$PY" ]] && PY=/home/scratch.huanhuanc_gpu/spmd/spmd-venv/bin/python
    "$NCU" --csv --launch-skip "$NSKIP" --launch-count "$NCOUNT" \
        --metrics gpu__time_duration.sum \
        "$PY" "$REPO_DIR/scripts/run_taichi.py" "$CASE" 200 \
        2>/dev/null | grep range_for > "$TMPCSV"
elif [[ "$FRAMEWORK" == "native_cuda" ]]; then
    # Hand-written CUDA — runs from native_data/run cwd
    NATIVE_DIR="$REPO_DIR/cuda_native_impl"
    case "$CASE" in
        F1_6.7K_fp64)
            BIN="$NATIVE_DIR/F1_hydro_native_fp64"
            CWD="$NATIVE_DIR/F1_native_data/run"
            ;;
        F1_6.7K_fp32)
            BIN="$NATIVE_DIR/F2_hydro_native_fp32"
            CWD="$NATIVE_DIR/F1_fp32_native_data/run"
            ;;
        F1_207K_fp64)
            BIN="$NATIVE_DIR/F1_hydro_native_fp64"
            CWD="$NATIVE_DIR/F1_207K_native_data/run"
            ;;
        F1_207K_fp32)
            BIN="$NATIVE_DIR/F2_hydro_native_fp32"
            CWD="$NATIVE_DIR/F1_207K_native_data/run"
            ;;
        F2_24K_fp32)
            BIN="$NATIVE_DIR/F2_hydro_native_fp32"
            CWD="$NATIVE_DIR/F2_24K_native_data/run"
            ;;
        F2_24K_fp64)
            BIN="$NATIVE_DIR/F1_hydro_native_fp64"
            CWD="$NATIVE_DIR/F2_24K_native_data/run"
            ;;
        F2_207K_fp32)
            BIN="$NATIVE_DIR/F2_hydro_native_fp32"
            CWD="$NATIVE_DIR/F2_207K_native_data/run"
            ;;
        F2_207K_fp64)
            BIN="$NATIVE_DIR/F1_hydro_native_fp64"
            CWD="$NATIVE_DIR/F2_207K_native_data/run"
            ;;
        *)
            echo "RESULT={\"case\": \"$CASE\", \"framework\": \"native_cuda\", \"error\": \"unsupported case\"}"
            exit 0
            ;;
    esac
    cd "$CWD"
    "$NCU" --csv --launch-skip "$NSKIP" --launch-count "$NCOUNT" \
        --metrics gpu__time_duration.sum \
        "$BIN" 200 2 \
        2>/dev/null | grep -E "(CalculateFluxKernel|UpdateCellKernel)" > "$TMPCSV"
elif [[ "$FRAMEWORK" == "cuda" ]]; then
    export HYDRO_BENCH_CUDA_DIR="$REPO_DIR/cuda_impl"
    if [[ "$CASE" == F1* ]]; then
        BIN="$REPO_DIR/cuda_impl/F1_persistent_bench"
        CELL=6675
        "$NCU" --csv --launch-skip "$NSKIP" --launch-count "$NCOUNT" \
            --metrics gpu__time_duration.sum \
            "$BIN" "$DATA_DIR" "$CELL" 900 2 0 \
            2>/dev/null | grep range_for > "$TMPCSV"
    else
        BIN="$REPO_DIR/cuda_impl/F2_persistent_bench"
        if [[ "$CASE" == F2_24K* ]]; then CELL=24020; NE=96080
        elif [[ "$CASE" == F2_207K* ]]; then CELL=207234; NE=828936
        fi
        PREC=fp32
        [[ "$CASE" == *fp64* ]] && PREC=fp64
        "$NCU" --csv --launch-skip "$NSKIP" --launch-count "$NCOUNT" \
            --metrics gpu__time_duration.sum \
            "$BIN" "$DATA_DIR" "$NE" "$CELL" "$PREC" 900 2 0 \
            2>/dev/null | grep range_for > "$TMPCSV"
    fi
else
    echo "ERROR: unknown framework '$FRAMEWORK'"
    exit 1
fi

# Parse CSV, compute mean per kernel name
python3 <<PYEOF
import csv, json, statistics
from collections import defaultdict

times = defaultdict(list)
with open("$TMPCSV") as f:
    for row in csv.reader(f):
        if len(row) < 14: continue
        kname = row[4]
        try:
            ns = int(row[-1])
        except ValueError:
            continue
        times[kname].append(ns)

result = {"case": "$CASE", "framework": "$FRAMEWORK"}
total_ns = 0
for kname, vals in times.items():
    if "_c" in kname and "kernel_0_range_for" in kname:
        short = kname.split("_c")[0]
    elif "Kernel" in kname:
        short = "calculate_flux" if "Flux" in kname else "update"
    else:
        short = kname.split("_kernel")[0]
    mean_ns = statistics.median(vals)
    result[short] = {"mean_ns": mean_ns, "count": len(vals), "min_ns": min(vals), "max_ns": max(vals)}
    total_ns += mean_ns
result["total_kernel_ns"] = total_ns
print("RESULT=" + json.dumps(result))
PYEOF

rm -f "$TMPCSV"
