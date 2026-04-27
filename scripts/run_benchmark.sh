#!/bin/bash
# Run Taichi + CUDA benchmarks on all (or one) hydro case.
#
# Usage:
#   bash run_benchmark.sh             # all 5 cases
#   bash run_benchmark.sh F2_24K_fp32 # single case
set -e

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RESULT_DIR="$REPO_DIR/results"
mkdir -p "$RESULT_DIR"

if [[ -n "$1" ]]; then
    CASES=("$1")
else
    CASES=(F1_6.7K_fp64 F2_24K_fp32 F2_24K_fp64 F2_207K_fp32 F2_207K_fp64)
fi

PYTHON="$REPO_DIR/venv/bin/python"
if [[ ! -x "$PYTHON" ]]; then
    echo "ERROR: venv missing. Run 'bash setup.sh' first."
    exit 1
fi

OUT="$RESULT_DIR/all_results.jsonl"
> "$OUT"

for case in "${CASES[@]}"; do
    echo "=== $case ==="

    # --- Taichi side ---
    echo "  [taichi] running..."
    TAICHI_OUT=$("$PYTHON" "$REPO_DIR/scripts/run_taichi.py" "$case" 100 2>&1 | grep "^RESULT=" || true)
    if [[ -n "$TAICHI_OUT" ]]; then
        echo "    $TAICHI_OUT" | sed 's/RESULT=//' >> "$OUT"
        echo "    OK: $(echo $TAICHI_OUT | sed 's/RESULT=//' | python3 -c "import json,sys; r=json.load(sys.stdin); print(f'{r[\"us_per_step\"]:.2f} us/step')")"
    else
        echo "    FAILED"
    fi

    # --- CUDA side ---
    echo "  [cuda]   running..."
    CUDA_OUT=$(bash "$REPO_DIR/scripts/run_cuda.sh" "$case" 2>&1 | grep "^RESULT=" || true)
    if [[ -n "$CUDA_OUT" ]]; then
        echo "    $CUDA_OUT" | sed 's/RESULT=//' >> "$OUT"
        echo "    OK: $(echo $CUDA_OUT | sed 's/RESULT=//' | python3 -c "import json,sys; r=json.load(sys.stdin); print(f'graph={r[\"graph_us\"]:.2f} us/step')")"
    else
        echo "    FAILED"
    fi
done

echo
echo "=== Comparison ==="
"$PYTHON" "$REPO_DIR/scripts/compare.py" "$OUT"
