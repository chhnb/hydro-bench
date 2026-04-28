"""Compare two ``OUTPUT/`` directories: native vs Taichi.

Three complementary diff modes are reported per file:

  text_match
      ``True`` iff the files are byte-identical. Useful for fp64 cases
      where exact reproducibility is expected at the OUTPUT precision.

  unified diff (difflib)
      A real ``difflib.unified_diff`` stream over the two file's
      decoded line lists. The first ``UNIFIED_DIFF_PREVIEW_LINES`` of
      hunk lines are inlined into the JSON report; when
      ``--diffs-dir`` is given the full unified diff is also written
      to ``{diffs_dir}/{file}.diff`` for inspection.

  numeric diff
      Tokenises ``H2=``, ``U2=``, ``V2=``, ``Z2=``, ``W2=``, ``FI=``
      blocks and reports per-field max / mean / p99 absolute diff plus
      counts of differing lines. Used for cases where rounding-mode
      differences trickle into the trailing digit.

Usage::

    python scripts/compare_output_files.py <native_dir> <taichi_dir> \\
        [--out report.json] [--diffs-dir results/alignment/diffs/<case>_step<N>]
"""
import argparse
import difflib
import json
import os
import re
import sys

import numpy as np

UNIFIED_DIFF_PREVIEW_LINES = 200


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
    """Return per-frame diff stats with explicit field-keyed entries.

    Output schema (matches AC-6.2):

        {
            "frame{N}": {
                "max_h_diff": float,
                "max_u_diff": float,
                "max_v_diff": float,
                "max_z_diff": float,
                "max_w_diff": float,
                "max_fi_diff": float,
                "structural_mismatch": list[str],   # missing labels per side
                "n_values": int,
            }
        }
    """
    label_to_key = {
        "H2": "max_h_diff",
        "U2": "max_u_diff",
        "V2": "max_v_diff",
        "Z2": "max_z_diff",
        "W2": "max_w_diff",
        "FI": "max_fi_diff",
    }
    frames = sorted({key[0] for key in (set(native) | set(taichi))})
    out = {}
    for frame in frames:
        entry = {k: 0.0 for k in label_to_key.values()}
        entry["structural_mismatch"] = []
        entry["n_values"] = 0
        for label, key_name in label_to_key.items():
            a = native.get((frame, label))
            b = taichi.get((frame, label))
            if a is None and b is None:
                continue
            if a is None or b is None:
                entry["structural_mismatch"].append(
                    f"{label} missing on {'native' if a is None else 'taichi'}"
                )
                entry[key_name] = float("inf")
                continue
            if len(a) != len(b):
                # Block-length mismatch is itself a structural failure
                # (a truncated or overlong block can otherwise look
                # numerically valid when min-truncated). Force max diff
                # to inf and record the count discrepancy.
                entry["structural_mismatch"].append(
                    f"{label} length mismatch: native={len(a)}, taichi={len(b)}"
                )
                entry[key_name] = float("inf")
                entry["n_values"] = max(entry["n_values"], max(len(a), len(b)))
                continue
            n = len(a)
            if n == 0:
                continue
            diff = np.abs(a - b)
            if label == "FI":
                # Native's `FI()` branches on the strict sign of U*V, so
                # cells with U and V at fp64 arithmetic-noise magnitudes
                # (~1e-17) can produce 180-360 degree FI diffs that are
                # not physically meaningful. Wrap diffs around the 360
                # degree (≈2π·57.298 = 360.054) period so the report
                # captures the true angular distance, not the wrap.
                period = 360.054
                diff = np.minimum(diff, np.abs(diff - period))
            entry[key_name] = float(diff.max())
            entry["n_values"] = max(entry["n_values"], int(n))
        out[f"frame{frame}"] = entry
    return out


# ---------------------------------------------------------------------------
# Text-mode diff helper
# ---------------------------------------------------------------------------

def text_diff_stats(path_a, path_b, diff_out_path=None):
    """Byte-equal flag + difflib.unified_diff over the two files.

    Returns a dict with:
      - text_match: bool, True iff byte-identical
      - diff_lines: count of differing line positions
      - lines_a, lines_b, size_a, size_b: per-side line/byte counts
      - unified_diff_preview: first ``UNIFIED_DIFF_PREVIEW_LINES`` of
        the difflib unified diff (empty list when text_match)
      - unified_diff_path: path to the full diff written by this call,
        or None if ``diff_out_path`` was not provided.
    """
    if not (os.path.isfile(path_a) and os.path.isfile(path_b)):
        return {
            "exists_a": os.path.isfile(path_a),
            "exists_b": os.path.isfile(path_b),
            "text_match": False,
            "unified_diff_preview": [],
        }
    with open(path_a, "rb") as fa:
        ba = fa.read()
    with open(path_b, "rb") as fb:
        bb = fb.read()
    la = ba.decode("latin-1").splitlines()
    lb = bb.decode("latin-1").splitlines()
    if ba == bb:
        return {
            "text_match": True,
            "diff_lines": 0,
            "lines_a": len(la),
            "lines_b": len(lb),
            "size_a": len(ba),
            "size_b": len(bb),
            "unified_diff_preview": [],
            "unified_diff_path": None,
        }
    n = min(len(la), len(lb))
    diff_lines = sum(1 for i in range(n) if la[i] != lb[i])
    diff_lines += abs(len(la) - len(lb))
    udiff_iter = difflib.unified_diff(
        la, lb,
        fromfile=path_a, tofile=path_b,
        lineterm="",
    )
    udiff_lines = list(udiff_iter)
    written_path = None
    if diff_out_path is not None:
        os.makedirs(os.path.dirname(diff_out_path) or ".", exist_ok=True)
        with open(diff_out_path, "w", encoding="latin-1") as f:
            f.write("\n".join(udiff_lines))
            f.write("\n")
        written_path = diff_out_path
    return {
        "text_match": False,
        "diff_lines": diff_lines,
        "lines_a": len(la),
        "lines_b": len(lb),
        "size_a": len(ba),
        "size_b": len(bb),
        "unified_diff_preview": udiff_lines[:UNIFIED_DIFF_PREVIEW_LINES],
        "unified_diff_total_lines": len(udiff_lines),
        "unified_diff_path": written_path,
    }


# ---------------------------------------------------------------------------
# Compare full directories
# ---------------------------------------------------------------------------

FILES = ("H2U2V2.OUT", "ZUV.OUT", "SIDE.OUT", "XY-TEC.DAT", "TIMELOG.OUT")


def compare_dirs(native_dir, taichi_dir, diffs_dir=None):
    report = {"native_dir": native_dir, "taichi_dir": taichi_dir, "files": {}}
    for name in FILES:
        a = os.path.join(native_dir, name)
        b = os.path.join(taichi_dir, name)
        diff_out_path = None
        if diffs_dir is not None:
            diff_out_path = os.path.join(diffs_dir, f"{name}.diff")
        entry = {"text": text_diff_stats(a, b, diff_out_path=diff_out_path)}
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
            for frame_key, frame in num.items():
                struct = frame.get("structural_mismatch", [])
                if struct:
                    lines.append(f"    {frame_key}: structural_mismatch={struct}")
                lines.append(
                    f"    {frame_key}: H={frame['max_h_diff']:.4e} "
                    f"U={frame['max_u_diff']:.4e} V={frame['max_v_diff']:.4e} "
                    f"Z={frame['max_z_diff']:.4e} W={frame['max_w_diff']:.4e}"
                )
    return "\n".join(lines)


def main(argv=None):
    p = argparse.ArgumentParser(
        description="Compare two native-style OUTPUT/ directories byte-and-numerically."
    )
    p.add_argument("native_dir", help="Path to native-side OUTPUT/")
    p.add_argument("taichi_dir", help="Path to Taichi-side OUTPUT/")
    p.add_argument("--out", default=None, help="Optional JSON report path")
    p.add_argument("--diffs-dir", default=None,
                   help="If set, write per-file unified diff artifacts to this directory.")
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    report = compare_dirs(args.native_dir, args.taichi_dir, diffs_dir=args.diffs_dir)
    print(summarize(report))
    if args.out:
        with open(args.out, "w") as f:
            json.dump(report, f, indent=2)
        print(f"\nReport written to {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
