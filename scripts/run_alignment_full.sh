#!/usr/bin/env bash
# Run the full alignment matrix: 4 cases × 2 precisions × N step checkpoints.
#
# For each (case, precision) the upgraded check_correctness.py runs Taichi
# once and dumps at every requested step via the on_step callback, while
# native CUDA runs once per step in dump mode. Per-(case, step) JSON
# reports land in ``results/alignment/{case}_step{N}.json`` and a
# Markdown summary is written to ``results/alignment/SUMMARY.md``.
#
# Usage::
#
#     bash scripts/run_alignment_full.sh           # default checkpoints
#     STEPS=1,100,900 bash scripts/run_alignment_full.sh   # custom
#     CASES="F2_24K_fp32 F2_207K_fp32" STEPS=1,100 bash scripts/run_alignment_full.sh

set -u
cd "$(dirname "$0")/.."

PY="$(realpath ./venv/bin/python 2>/dev/null || true)"
if [ -z "$PY" ] || [ ! -x "$PY" ]; then
    PY="/home/scratch.huanhuanc_gpu/spmd/spmd-venv/bin/python"
fi

STEPS="${STEPS:-1,100,900,7200,36000,72000}"
CASES="${CASES:-F1_6.7K_fp64 F1_6.7K_fp32 F2_24K_fp64 F2_24K_fp32 F1_207K_fp64 F1_207K_fp32 F2_207K_fp64 F2_207K_fp32}"

OUT_DIR="results/alignment"
mkdir -p "$OUT_DIR"

# Clear ONLY the (case, step) artifacts this invocation will rewrite.
# Other (case, step) JSONs in OUT_DIR survive so partial reruns merge
# into SUMMARY.md instead of erasing unrelated rows. Per-checkpoint
# native_outputs/ and taichi_outputs/ are cleared with the same scope.
IFS=',' read -r -a STEP_ARR <<< "$STEPS"
for case in $CASES; do
    for step in "${STEP_ARR[@]}"; do
        step=$(echo "$step" | tr -d ' ')
        rm -f "$OUT_DIR/${case}_step${step}.json"
        rm -rf "$OUT_DIR/native_outputs/${case}_step${step}"
        rm -rf "$OUT_DIR/taichi_outputs/${case}_step${step}"
    done
done
# SUMMARY.md is rewritten at end-of-run by the aggregator below; do NOT
# delete it here, the per-case Python script merges into the existing
# table.

n_pass=0
n_fail=0
echo "Running alignment matrix:"
echo "  STEPS=$STEPS"
echo "  CASES=$CASES"
echo

for case in $CASES; do
    echo "=== $case ==="
    if "$PY" scripts/check_correctness.py "$case" --steps "$STEPS" --out-dir "$OUT_DIR"; then
        :
    else
        echo "  (one or more checkpoints failed)"
    fi
    echo
done

echo
echo "Aggregating per-(case, step) JSONs into SUMMARY.md ..."
"$PY" - <<PY
import glob, json, os
out_dir = "$OUT_DIR"
rows = []
for path in sorted(glob.glob(os.path.join(out_dir, "*_step*.json"))):
    try:
        with open(path) as f:
            rows.append(json.load(f))
    except Exception:
        pass
rows.sort(key=lambda r: (r["case"], r["step"]))
lines = [
    "# Alignment Validation Summary",
    "",
    "| case | step | precision | verdict | H max_abs | U max_abs | V max_abs | Z max_abs | mass rel | KE rel | momentum_x rel | klas1_inflow rel | reason |",
    "|------|------|-----------|---------|-----------|-----------|-----------|-----------|----------|--------|----------------|------------------|--------|",
]
for r in rows:
    H = r["fields"]["H"]
    U = r["fields"]["U"]
    V = r["fields"]["V"]
    Z = r["fields"]["Z"]
    cons = r["conservation"]
    lines.append(
        f"| {r['case']} | {r['step']} | {r['precision']} | {r['verdict']} | "
        f"{H['max_abs']:.3e} | {U['max_abs']:.3e} | {V['max_abs']:.3e} | {Z['max_abs']:.3e} | "
        f"{cons['mass']['rel_diff']:.3e} | {cons['kinetic_energy']['rel_diff']:.3e} | "
        f"{cons['momentum_x']['rel_diff']:.3e} | {cons['klas1_inflow']['rel_diff']:.3e} | "
        f"{r['reason']} |"
    )
n_pass = sum(1 for r in rows if r["verdict"] == "PASS")
n_fail = sum(1 for r in rows if r["verdict"] != "PASS")
lines.insert(2, f"**{n_pass} PASS / {n_fail} FAIL of {len(rows)} entries.**")
lines.insert(3, "")
with open(os.path.join(out_dir, "SUMMARY.md"), "w") as f:
    f.write("\n".join(lines) + "\n")
print(f"  {n_pass} PASS / {n_fail} FAIL of {len(rows)} entries")
PY

echo "Done. See $OUT_DIR/SUMMARY.md"
