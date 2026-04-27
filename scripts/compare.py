"""Parse JSONL results from run_benchmark.sh and print comparison table.

Usage:
    python compare.py results.jsonl
"""
import json
import sys
from collections import defaultdict


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "results/all_results.jsonl"
    by_case = defaultdict(dict)
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except Exception:
                continue
            case = r["case"]
            fw = r["framework"]
            by_case[case][fw] = r

    print("\n┌──────────────────┬───────────────┬─────────────────┬──────────────────┬──────────────┐")
    print("│ Case             │ Taichi μs/step│ CUDA Graph μs/st│ Ratio (T/C)      │ Speedup CUDA │")
    print("├──────────────────┼───────────────┼─────────────────┼──────────────────┼──────────────┤")
    for case in sorted(by_case.keys()):
        d = by_case[case]
        t = d.get("taichi", {}).get("us_per_step")
        c = d.get("cuda", {}).get("graph_us")
        if t is None and c is None:
            continue
        t_str = f"{t:.2f}" if t else "-"
        c_str = f"{c:.2f}" if c else "-"
        if t and c:
            ratio = t / c
            ratio_str = f"{ratio:.2f}x"
            if t < c:
                winner = f"Taichi {c/t:.2f}x faster"
            else:
                winner = f"CUDA {t/c:.2f}x faster"
        else:
            ratio_str = "-"
            winner = "-"
        print(f"│ {case:16s} │ {t_str:>13s} │ {c_str:>15s} │ {ratio_str:>16s} │ {winner:12s} │")
    print("└──────────────────┴───────────────┴─────────────────┴──────────────────┴──────────────┘")
    print()
    print("Notes:")
    print("  - Taichi μs/step is plain Taichi (sync mode, with Python loop).")
    print("    Includes Python overhead per kernel call.")
    print("  - CUDA Graph μs/step is pure GPU compute (Python overhead amortized).")
    print("  - Ratio = Taichi / CUDA. Lower is better for Taichi.")


if __name__ == "__main__":
    main()
