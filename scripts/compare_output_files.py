"""Compare two ``OUTPUT/`` directories: native vs Taichi.

Two complementary diff modes are reported per file:

  text_match
      ``True`` iff the files are byte-identical. Useful for fp64 cases
      where exact reproducibility is expected at the OUTPUT precision.

  numeric diff
      Tokenises ``H2=``, ``U2=``, ``V2=``, ``Z2=``, ``W2=``, ``FI=``
      blocks and reports per-field max / mean / p99 absolute diff plus
      counts of differing lines. Used for fp32 cases where rounding-
      mode differences trickle into the trailing digit.

Usage::

    python scripts/compare_output_files.py <native_dir> <taichi_dir> [--out report.json]
"""
import argparse
import json
import os
import re
import sys

import numpy as np


# ---------------------------------------------------------------------------
# Tokenizer for H2= / U2= / V2= / Z2= / W2= / FI= blocks
# ---------------------------------------------------------------------------

_BLOCK_RE = re.compile(r"^\s*(H2|U2|V2|Z2|W2|FI)=\s*(.*)$")
_FRAME_RE = re.compile(r"^\s*JT=\s*(\d+)\s+KT=\s*(\d+)")
_FLOAT_RE = re.compile(r"-?\d+\.\d+(?:[eE][+-]?\d+)?")


def parse_blocks(path):
    """Parse a H2U2V2.OUT or ZUV.OUT file into ``{(frame, label): np.ndarray}``."""
    out = {}
    if not os.path.isfile(path):
        return out
    frame = -1
    cur_label = None
    cur_values = []

    def flush():
        if cur_label is not None and cur_values:
            out.setdefault((frame, cur_label), [])
            out[(frame, cur_label)] = np.array(cur_values, dtype=np.float64)

    with open(path, "r", encoding="latin-1") as f:
        for line in f:
            m = _FRAME_RE.match(line)
            if m:
                flush()
                frame = int(m.group(1))
                cur_label = None
                cur_values = []
                continue
            m = _BLOCK_RE.match(line)
            if m:
                flush()
                cur_label = m.group(1)
                cur_values = [float(x) for x in _FLOAT_RE.findall(m.group(2))]
                continue
            if cur_label is not None:
                cur_values.extend(float(x) for x in _FLOAT_RE.findall(line))
        flush()
    return out


def diff_blocks(native, taichi):
    """Return per-(frame, label) diff stats from two parsed dicts."""
    keys = sorted(set(native) | set(taichi))
    out = {}
    for key in keys:
        a = native.get(key)
        b = taichi.get(key)
        frame, label = key
        if a is None or b is None:
            out[f"frame{frame}.{label}"] = {"missing": True,
                                            "native_present": a is not None,
                                            "taichi_present": b is not None}
            continue
        n = min(len(a), len(b))
        diff = np.abs(a[:n] - b[:n])
        out[f"frame{frame}.{label}"] = {
            "n_values": int(n),
            "max_abs": float(diff.max()) if n else 0.0,
            "mean_abs": float(diff.mean()) if n else 0.0,
            "p99": float(np.percentile(diff, 99)) if n else 0.0,
            "n_diff_gt_1e-3": int((diff > 1e-3).sum()),
            "n_diff_gt_1e-1": int((diff > 1e-1).sum()),
        }
    return out


# ---------------------------------------------------------------------------
# Text-mode diff helper
# ---------------------------------------------------------------------------

def text_diff_stats(path_a, path_b):
    """Count non-matching lines + flag whether files are byte-identical."""
    if not (os.path.isfile(path_a) and os.path.isfile(path_b)):
        return {
            "exists_a": os.path.isfile(path_a),
            "exists_b": os.path.isfile(path_b),
            "text_match": False,
        }
    with open(path_a, "rb") as fa:
        ba = fa.read()
    with open(path_b, "rb") as fb:
        bb = fb.read()
    if ba == bb:
        return {"text_match": True, "diff_lines": 0, "size_a": len(ba), "size_b": len(bb)}
    # Line-level diff (text mode)
    la = ba.decode("latin-1").splitlines()
    lb = bb.decode("latin-1").splitlines()
    n = min(len(la), len(lb))
    diff_lines = sum(1 for i in range(n) if la[i] != lb[i])
    diff_lines += abs(len(la) - len(lb))
    return {
        "text_match": False,
        "diff_lines": diff_lines,
        "lines_a": len(la),
        "lines_b": len(lb),
        "size_a": len(ba),
        "size_b": len(bb),
    }


# ---------------------------------------------------------------------------
# Compare full directories
# ---------------------------------------------------------------------------

FILES = ("H2U2V2.OUT", "ZUV.OUT", "SIDE.OUT", "XY-TEC.DAT", "TIMELOG.OUT")


def compare_dirs(native_dir, taichi_dir):
    report = {"native_dir": native_dir, "taichi_dir": taichi_dir, "files": {}}
    for name in FILES:
        a = os.path.join(native_dir, name)
        b = os.path.join(taichi_dir, name)
        entry = {"text": text_diff_stats(a, b)}
        if name in ("H2U2V2.OUT", "ZUV.OUT"):
            entry["numeric"] = diff_blocks(parse_blocks(a), parse_blocks(b))
        report["files"][name] = entry
    return report


def summarize(report):
    lines = []
    for name, entry in report["files"].items():
        text = entry["text"]
        lines.append(f"  {name}:")
        if text.get("text_match"):
            lines.append("    text_match: True (byte-identical)")
        else:
            lines.append(
                f"    text_match: False (diff_lines={text.get('diff_lines', 'N/A')}, "
                f"lines_a={text.get('lines_a', 'N/A')}, lines_b={text.get('lines_b', 'N/A')})"
            )
        if "numeric" in entry:
            num = entry["numeric"]
            if not num:
                lines.append("    numeric: no parseable blocks")
                continue
            for label in ("H2", "U2", "V2", "Z2", "W2", "FI"):
                rows = [v for (k, v) in num.items() if k.endswith("." + label) and "max_abs" in v]
                if not rows:
                    continue
                max_abs = max(r["max_abs"] for r in rows)
                p99 = max(r["p99"] for r in rows)
                lines.append(f"    {label}: max_abs={max_abs:.4e}, p99={p99:.4e}, "
                             f"frames={len(rows)}")
    return "\n".join(lines)


def main(argv=None):
    p = argparse.ArgumentParser(
        description="Compare two native-style OUTPUT/ directories byte-and-numerically."
    )
    p.add_argument("native_dir", help="Path to native-side OUTPUT/")
    p.add_argument("taichi_dir", help="Path to Taichi-side OUTPUT/")
    p.add_argument("--out", default=None, help="Optional JSON report path")
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    report = compare_dirs(args.native_dir, args.taichi_dir)
    print(summarize(report))
    if args.out:
        with open(args.out, "w") as f:
            json.dump(report, f, indent=2)
        print(f"\nReport written to {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
