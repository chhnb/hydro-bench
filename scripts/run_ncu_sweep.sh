#!/bin/bash
# Profile pure GPU kernel time for Taichi vs Taichi-PTX-via-Graph vs Native CUDA.
# Uses ncu (NVIDIA Compute Profiler).
set -e

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RESULT_DIR="$REPO_DIR/results"
mkdir -p "$RESULT_DIR"
OUT="$RESULT_DIR/ncu_results.jsonl"
> "$OUT"

CASES=(F1_6.7K_fp32 F1_6.7K_fp64 F1_207K_fp32 F1_207K_fp64 F2_24K_fp32 F2_24K_fp64 F2_207K_fp32 F2_207K_fp64)

for case in "${CASES[@]}"; do
    echo "=== $case ==="
    for fw in taichi cuda native_cuda; do
        echo "  [$fw] profiling..."
        OUTPUT=$(bash "$REPO_DIR/scripts/run_ncu.sh" "$case" "$fw" 50 20 2>&1 | grep "^RESULT=" || true)
        if [[ -n "$OUTPUT" ]]; then
            echo "$OUTPUT" | sed 's/RESULT=//' >> "$OUT"
            TOTAL=$(echo "$OUTPUT" | sed 's/RESULT=//' | python3 -c "
import json, sys
r = json.load(sys.stdin)
if 'error' in r:
    print(f'(skipped: {r[\"error\"]})')
else:
    t = r.get('total_kernel_ns', 0) / 1000
    print(f'{t:.2f} us total')
")
            echo "    $TOTAL"
        else
            echo "    FAILED"
        fi
    done
done

echo
echo "==============================================================================="
echo " Pure GPU kernel time (ncu profiled, A100 sm_80)"
echo "==============================================================================="
python3 <<PYEOF
import json
from collections import defaultdict

data = defaultdict(dict)
with open("$OUT") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        r = json.loads(line)
        if "error" in r:
            data[r["case"]][r["framework"]] = None
        else:
            data[r["case"]][r["framework"]] = r.get("total_kernel_ns", 0) / 1000

print()
print(f"{'Case':<18s} {'Taichi':>10s} {'CUDA':>10s} {'Native':>10s} {'T vs Native':>16s}")
print(f"{'':<18s} {'(us)':>10s} {'(via Taichi)':>10s} {'CUDA (us)':>10s}")
print("-" * 75)
for case in ["F1_6.7K_fp64", "F2_24K_fp32", "F2_24K_fp64", "F2_207K_fp32", "F2_207K_fp64"]:
    if case not in data:
        continue
    t = data[case].get("taichi")
    c = data[case].get("cuda")
    n = data[case].get("native_cuda")
    t_str = f"{t:.2f}" if t else "-"
    c_str = f"{c:.2f}" if c else "-"
    n_str = f"{n:.2f}" if n else "n/a"
    if t and n:
        winner = f"Taichi {n/t:.2f}x" if t < n else f"Native {t/n:.2f}x"
    else:
        winner = "-"
    print(f"{case:<18s} {t_str:>10s} {c_str:>10s} {n_str:>10s} {winner:>16s}")
print()
print("Notes:")
print("  - 'Taichi'         = run Taichi @ti.kernel via Python (ncu profiles process)")
print("  - 'CUDA via Taichi'= load Taichi-compiled PTX in CUDA Graph (cuda_impl/)")
print("  - 'Native CUDA'    = hand-written CUDA hydro kernels (cuda_native_impl/)")
print("  - All numbers are pure GPU kernel time (sum of flux + update per timestep).")
PYEOF
