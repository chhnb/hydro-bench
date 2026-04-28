"""Reproduce the native CUDA ``OUTPUT/`` files from Taichi-side state.

Native ``MeshData::outputToFile(jt, kt)`` writes five files:

    H2U2V2.OUT   header + H2= / U2= / V2= blocks (10-per-line, an extra
                 5-space-prefixed newline every 100 cells, ``setw(10)
                 fixed setprecision(4)`` numeric format).
    ZUV.OUT      same header + Z2= / W2= / FI= blocks.
    SIDE.OUT     one-time geometry dump at (jt=0, kt=1): COSF / SINF /
                 SIDE / AREA blocks using the default ostream precision.
    XY-TEC.DAT   TEC visualization with VARIABLES + ZONE headers, X / Y
                 coordinates (in original-frame units), then H2 / Z2 /
                 U2 / V2 / W2 cell-centred values, then NAP cell
                 connectivity.
    TIMELOG.OUT  one float per frame: ``jt2 / NDAYS`` with ``setprecision(4)``.

This module reproduces those formats byte-for-byte for the deterministic
parts (header line, 10x100 newline cadence, fixed-precision values).
The mesh loaders now expose ``NAP``, ``XP``, ``YP``, ``XIMIN``, and
``YIMIN`` so the writer can reconstruct the original-frame coordinates
that native writes via ``XP[i] + XIMIN``.
"""
import math
import os

import numpy as np


def _fmt10_4(v):
    """Reproduce C++ ``setw(10) fixed setprecision(4)`` for finite floats.

    Sub-noise-floor values (magnitude < 5e-5) round to ``0.0000`` at
    4-decimal precision. The C++ default formatter preserves the sign,
    so a sub-ulp negative noise value formats as ``-0.0000`` while the
    same physical zero from the other side formats as ``0.0000``. To
    keep the writer canonical (positive zero for any value below the
    noise floor), we coerce magnitude < 1e-9 to positive zero before
    formatting.
    """
    val = float(v)
    if abs(val) < 1e-9:
        val = 0.0
    return f"{val:10.4f}"


def _dt_field(dt, fixed_p4):
    """Reproduce native ``setw(3) << DT`` where DT is ``Real``.

    The native C++ stream carries ``std::fixed`` + ``std::setprecision(4)``
    state across frames once the first H2= block has been written. This
    means:

      * On the very first frame (no H2= block yet), DT prints with the
        default ostream precision (``  4`` for an integer DT, ``0.5``
        for fractional).
      * On every subsequent frame, DT prints in ``fixed`` precision 4
        (``4.0000``, ``0.5000``).

    ``fixed_p4`` selects between the two regimes.
    """
    if fixed_p4:
        return f"{float(dt):.4f}"
    if float(dt).is_integer():
        return f"{int(dt):>3d}"
    text = f"{float(dt):g}"
    if len(text) < 3:
        text = " " * (3 - len(text)) + text
    return text


def _header_line(jt2, kt, dt, fixed_p4):
    """Native header bytes (between the leading two blank lines and trailing newline)."""
    return (
        f" JT={jt2:>5d}"
        f"  KT={kt - 1:>5d}"
        f"  DT={_dt_field(dt, fixed_p4)}"
        f" SEC"
        f"  T={0:>2d}H"
        f"  NSF={0:>2d}/0"
        f"  WEC=0/"
        f"  CQL=0"
        f"  INE=0"
    )


def _write_block_10x100(stream, cell_values):
    """Write ``cell_values`` matching native's per-block newline cadence.

    Native (in pseudo-code):
        for i in range(N):
            if i % 10 == 0:
                stream.write("\\n     ")
            if i != 0 and i % 100 == 0:
                stream.write("\\n     ")
            stream.write(setw(10) fixed setprecision(4) << v)
    """
    for i, v in enumerate(cell_values):
        if i % 10 == 0:
            stream.write("\n     ")
        if i != 0 and i % 100 == 0:
            stream.write("\n     ")
        stream.write(_fmt10_4(v))


def _flow_angle(u, v):
    """Replicate native ``MeshData::FI`` (mesh.cpp:828). Result in
    degrees scaled by 57.298.

    Native uses *sequential* ``if`` (not else-if) for the X*Y == 0
    branch, so when both X and Y are zero the second matching branch
    OVERWRITES the first:

        if (X == 0 && Y >= 0) FI = π/2;
        if (X == 0 && Y < 0) FI = 3π/2;
        if (Y == 0 && X >= 0) FI = 0;       # overwrites the X==0 case for (0, 0)
        if (Y == 0 && X < 0) FI = π;

    So FI(0, 0) = 0 in native (despite the X == 0 first match
    returning π/2). The Python implementation must mirror this
    overwrite-by-later-match semantics rather than the first-match
    semantics of an elif chain.

    Note on sub-ulp U/V noise: native's `FI()` branches on the
    strict sign of U*V, so two implementations that agree at the
    cell-physics level can disagree by 180-360 degrees on cells
    whose U and V have arithmetic-noise magnitudes (~1e-17).
    """
    # Snap sub-noise-floor inputs to zero so two implementations that
    # agree at the cell-physics level but disagree on sub-ulp U/V
    # produce the same FI (matches the equivalent snap in
    # ``cuda_native_impl/hydro-cal-src/src/mesh.cpp::FI``).
    if abs(u) < 1e-9:
        u = 0.0
    if abs(v) < 1e-9:
        v = 0.0
    MPI = 3.1416
    if u * v != 0.0:
        w = math.atan2(abs(v), abs(u))
        if u * v > 0.0:
            fi = w if u > 0.0 else MPI + w
        else:
            fi = MPI - w if v > 0.0 else 2.0 * MPI - w
    else:
        # Sequential `if`s: later matches overwrite earlier matches,
        # so (0, 0) ends up as 0 (the third branch overwrites the
        # first). Only the v != 0 cases hit the first / second
        # branches and are not overwritten.
        fi = 0.0  # default for unreachable inputs
        if u == 0.0 and v >= 0.0:
            fi = MPI / 2.0
        if u == 0.0 and v < 0.0:
            fi = 3.0 * MPI / 2.0
        if v == 0.0 and u >= 0.0:
            fi = 0.0
        if v == 0.0 and u < 0.0:
            fi = MPI
    return fi * 57.298


# ---------------------------------------------------------------------------
# Mesh metadata extraction (handles both F1 and F2 dict layouts)
# ---------------------------------------------------------------------------

def _flatten_mesh(mesh):
    """Normalise an F1 (1-indexed 2D arrays, key ``CEL``) or F2 (flat 0-indexed,
    key ``CELL``) mesh dict into the per-edge / per-cell flat arrays this
    writer needs.

    Returns dict with keys ``cell``, ``klas``, ``cosf``, ``sinf``, ``side``,
    ``area``, ``zbc``, ``nap`` (shape (cell, 4) cell-major), ``xp``, ``yp``,
    ``ximin``, ``yimin``, ``hm1``.
    """
    if "CEL" in mesh:  # F1
        cell = int(mesh["CEL"])
        nedge = cell * 4
        klas = np.zeros(nedge, dtype=np.int32)
        cosf = np.zeros(nedge, dtype=np.float64)
        sinf = np.zeros(nedge, dtype=np.float64)
        side = np.zeros(nedge, dtype=np.float64)
        for c in range(cell):
            for j in range(4):
                klas[4 * c + j] = int(mesh["KLAS"][j + 1, c + 1])
                cosf[4 * c + j] = float(mesh["COSF"][j + 1, c + 1])
                sinf[4 * c + j] = float(mesh["SINF"][j + 1, c + 1])
                side[4 * c + j] = float(mesh["SIDE"][j + 1, c + 1])
        area = np.asarray(mesh["AREA"])[1:].astype(np.float64).copy()
        zbc = np.asarray(mesh["ZBC"])[1:].astype(np.float64).copy()
        nap = np.asarray(mesh["NAP"])[1:, 1:].T.astype(np.int32).copy()  # (cell, 4)
        xp = np.asarray(mesh["XP"])[1:].astype(np.float64).copy()
        yp = np.asarray(mesh["YP"])[1:].astype(np.float64).copy()
    else:
        cell = int(mesh["CELL"])
        klas = np.asarray(mesh["KLAS"]).astype(np.int32).copy()
        cosf = np.asarray(mesh["COSF"]).astype(np.float64).copy()
        sinf = np.asarray(mesh["SINF"]).astype(np.float64).copy()
        side = np.asarray(mesh["SIDE"]).astype(np.float64).copy()
        area = np.asarray(mesh["AREA"]).astype(np.float64).copy()
        zbc = np.asarray(mesh["ZBC"]).astype(np.float64).copy()
        nap_raw = np.asarray(mesh["NAP"])
        nap = nap_raw[1:, 1:].T.astype(np.int32).copy()  # (cell, 4)
        xp = np.asarray(mesh["XP"])[1:].astype(np.float64).copy()
        yp = np.asarray(mesh["YP"])[1:].astype(np.float64).copy()
    return {
        "cell": cell,
        "klas": klas,
        "cosf": cosf,
        "sinf": sinf,
        "side": side,
        "area": area,
        "zbc": zbc,
        "nap": nap,
        "xp": xp,
        "yp": yp,
        "ximin": float(mesh["XIMIN"]),
        "yimin": float(mesh["YIMIN"]),
        "hm1": float(mesh["HM1"]),
    }


def _normalise_state(state, cell):
    def to_np(arr):
        a = np.asarray(arr)
        if a.size == cell + 1:
            a = a[1:]
        return a[:cell].astype(np.float64, copy=False)

    return to_np(state["H"]), to_np(state["U"]), to_np(state["V"]), to_np(state["Z"])


# ---------------------------------------------------------------------------
# Writer
# ---------------------------------------------------------------------------

class OutputWriter:
    """Stream-mode writer for the five native OUTPUT files."""

    def __init__(self, out_dir, mesh, dt, ndays):
        os.makedirs(out_dir, exist_ok=True)
        self.out_dir = out_dir
        self.dt = float(dt)
        self.ndays = int(ndays)
        meta = _flatten_mesh(mesh)
        self.cell = meta["cell"]
        self.klas = meta["klas"]
        self.cosf = meta["cosf"]
        self.sinf = meta["sinf"]
        self.side = meta["side"]
        self.area = meta["area"]
        self.zbc = meta["zbc"]
        self.nap = meta["nap"]
        self.xp = meta["xp"]
        self.yp = meta["yp"]
        self.ximin = meta["ximin"]
        self.yimin = meta["yimin"]
        self.hm1 = meta["hm1"]
        self.h2u2v2 = open(os.path.join(out_dir, "H2U2V2.OUT"), "w")
        self.zuv = open(os.path.join(out_dir, "ZUV.OUT"), "w")
        self.timelog = open(os.path.join(out_dir, "TIMELOG.OUT"), "w")
        self.xy_tec = open(os.path.join(out_dir, "XY-TEC.DAT"), "w")
        self.side_file = open(os.path.join(out_dir, "SIDE.OUT"), "w")
        self._side_written = False
        # Native C++ stream carries ``std::fixed << std::setprecision(4)``
        # across frames once the first H2= block has been written. We
        # mirror that state so DT formats identically.
        self._h2u2v2_p4 = False
        self._zuv_p4 = False

    def close(self):
        for f in (self.h2u2v2, self.zuv, self.timelog, self.xy_tec, self.side_file):
            try:
                f.close()
            except Exception:
                pass

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()

    # ---------------------------------------------------------------- SIDE.OUT
    def _write_side_once(self):
        if self._side_written:
            return
        self._side_written = True
        s = self.side_file
        cell = self.cell

        def cppfloat(v):
            """Reproduce C++ default ostream float rendering.

            C++ ``std::ostream`` defaults to general format with
            precision 6 (``cout.precision() == 6``), trimming trailing
            zeros. Python ``f"{v:.6g}"`` matches that behavior for
            finite floats.
            """
            return f"{float(v):.6g}"

        s.write("COSF\n")
        for i in range(cell):
            s.write(f"{i + 1}    ")
            for k in range(4):
                s.write(f"{cppfloat(self.cosf[4 * i + k])}     ")
            s.write("\n")
        s.write("SINF\n")
        for i in range(cell):
            s.write(f"{i + 1}    ")
            for k in range(4):
                s.write(f"{cppfloat(self.sinf[4 * i + k])}     ")
            s.write("\n")
        s.write("SIDE\n")
        for i in range(cell):
            s.write(f"{i + 1}    ")
            for k in range(4):
                s.write(f"{cppfloat(self.side[4 * i + k])}     ")
            s.write("\n")
        s.write("AREA\n")
        for i in range(cell):
            s.write(f"{i + 1}    {cppfloat(self.area[i])}\n")

    # ---------------------------------------------------------------- header
    def _write_header(self, stream, jt2, kt, fixed_p4):
        stream.write(" \n \n")
        stream.write(_header_line(jt2, kt, self.dt, fixed_p4))
        stream.write("\n")

    # ---------------------------------------------------------------- frame
    def write_frame(self, jt, kt, state):
        H, U, V, Z = _normalise_state(state, self.cell)
        wet = H > self.hm1
        h_clamped = np.where(wet, H, 0.0)
        u_clamped = np.where(wet, U, 0.0)
        v_clamped = np.where(wet, V, 0.0)
        z_clamped = np.where(wet, Z, self.zbc)
        # Native writes W2 as ``float`` (mesh.cpp:715), so the
        # fp32 truncation may flip 4-decimal rounding for values
        # right at the half-way point. Mirror the cast here.
        w2 = np.where(wet, np.sqrt(U * U + V * V).astype(np.float32).astype(np.float64), 0.0)

        jt2 = jt if kt == 1 else jt + 1

        if not self._side_written and jt == 0 and kt == 1:
            self._write_side_once()

        # H2U2V2.OUT
        self._write_header(self.h2u2v2, jt2, kt, self._h2u2v2_p4)
        self.h2u2v2.write("     \n     H2=")
        _write_block_10x100(self.h2u2v2, h_clamped)
        # The first H2= block sets fixed/setprecision(4) on the C++
        # stream; everything after carries that state.
        self._h2u2v2_p4 = True
        self.h2u2v2.write("\n     \n     U2=")
        _write_block_10x100(self.h2u2v2, u_clamped)
        self.h2u2v2.write("\n     \n     V2=")
        _write_block_10x100(self.h2u2v2, v_clamped)
        self.h2u2v2.write(" \n")

        # ZUV.OUT
        self._write_header(self.zuv, jt2, kt, self._zuv_p4)
        self.zuv.write("     \n     Z2=")
        _write_block_10x100(self.zuv, z_clamped)
        self._zuv_p4 = True
        self.zuv.write("\n     \n     W2=")
        _write_block_10x100(self.zuv, w2)
        self.zuv.write("\n     \n     FI=")
        fi_block = np.array([
            _flow_angle(float(U[i]) if wet[i] else 0.0,
                        float(V[i]) if wet[i] else 0.0)
            if wet[i] else 0.0
            for i in range(self.cell)
        ])
        _write_block_10x100(self.zuv, fi_block)
        self.zuv.write(" \n")

        # TIMELOG.OUT
        ratio = jt2 / float(self.ndays) if self.ndays else 0.0
        self.timelog.write(f"{ratio:.4f}\n")

        # XY-TEC.DAT
        self._write_xy_tec_frame(h_clamped, z_clamped, u_clamped, v_clamped, w2)

        for f in (self.h2u2v2, self.zuv, self.timelog, self.xy_tec):
            f.flush()

    # ---------------------------------------------------------------- XY-TEC
    def _write_xy_tec_frame(self, h, z, u, v, w):
        s = self.xy_tec
        nod = int(self.xp.size)
        s.write(' VARIABLES = "X", "Y", "H2", "Z2","U2","V2","W2"\n')
        s.write(f"ZONE N={nod}, E={self.cell}, DATAPACKING=BLOCK, ZONETYPE=FEQUADRILATERAL\n")
        s.write("VARLOCATION=([3-7]=CELLCENTERED)\n")

        # Native ``MeshData::outputToFile`` uses three different newline
        # cadences across the XY-TEC blocks (mesh.cpp:754-826):
        #   * Per-node (XP/YP):   newline at i%10==0 AND i!=0, trailing endl
        #   * H2 (per-cell):      newline at every i%10==0 (incl i=0),
        #                         NO trailing endl
        #   * Z2/U2/V2/W2:        newline at i%10==0 AND i!=0, trailing endl
        def fmt(val):
            v = float(val)
            if abs(v) < 1e-9:
                v = 0.0
            return f"{v:.4f}"

        def write_node(arr):
            for i, val in enumerate(arr):
                if i % 10 == 0 and i != 0:
                    s.write("\n")
                s.write(fmt(val) + " ")
            s.write("\n")

        def write_h2(arr):
            for i, val in enumerate(arr):
                if i % 10 == 0:
                    s.write("\n")
                s.write(fmt(val) + " ")

        def write_other(arr):
            for i, val in enumerate(arr):
                if i % 10 == 0 and i != 0:
                    s.write("\n")
                s.write(fmt(val) + " ")
            s.write("\n")

        # Native re-adds XIMIN / YIMIN before writing coordinates.
        write_node(self.xp + self.ximin)
        write_node(self.yp + self.yimin)
        write_h2(h)
        write_other(z)
        write_other(u)
        write_other(v)
        write_other(w)
        # Native emits "NAP[0] NAP[1] NAP[2] NAP[3] \n" — note the
        # trailing space before the newline (each value is followed by
        # a literal " " in the C++ loop).
        for i in range(self.cell):
            row = self.nap[i]
            s.write("".join(f"{int(x)} " for x in row) + "\n")


__all__ = ["OutputWriter"]
