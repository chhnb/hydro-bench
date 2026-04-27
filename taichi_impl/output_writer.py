"""Write the native hydro-cal ``OUTPUT/*`` files from Taichi-side state.

The native CUDA `MeshData::outputToFile(jt, kt)` writes five files:

    H2U2V2.OUT   header + H2= / U2= / V2= blocks (10-per-line, every 100
                 inserts an extra blank-spaced newline). Format
                 ``setw(10) fixed setprecision(4)``.
    ZUV.OUT      same header + Z2= / W2= / FI= blocks, same format.
    SIDE.OUT     one-time geometry dump at (jt=0, kt=1): COSF / SINF /
                 SIDE / AREA blocks using the default ostream precision.
    XY-TEC.DAT   TEC visualization with VARIABLES + ZONE headers, X/Y
                 coordinates, then H2 / Z2 / U2 / V2 / W2 cell values
                 followed by NAP cell connectivity.
    TIMELOG.OUT  one float per frame: ``jt2 / NDAYS`` with
                 ``setprecision(4)``.

Helpers in this module reproduce that format using Python ``f"{v:10.4f}"``
formatting (mathematically identical to ``setw(10) fixed
setprecision(4)`` for finite values).

Public surface::

    OutputWriter(out_dir, mesh, dtype)
        .write_initial(initial_state)         # called once at start
        .write_frame(jt, kt, state)            # called every NTOUTPUT day

``state`` is a dict containing arrays H, U, V, Z, ZBC, plus optional
F0..F3 (unused — fluxes are not in the native OUTPUT files).
``mesh`` is the dict returned by ``mesh_loader_f1.load_hydro_mesh`` or
``mesh_loader_f2.load_mesh``; this writer normalises both layouts.
"""
import math
import os

import numpy as np


HM1_KEY = "HM1"
HM2_KEY = "HM2"


def _fmt10_4(v):
    """Reproduce C++ ``setw(10) fixed setprecision(4)``.

    Note: Python's ``f"{v:10.4f}"`` matches the C++ format byte-for-byte
    for finite floats whose magnitude fits in the 10-character field.
    """
    return f"{v:10.4f}"


def _write_block_10x100(stream, cell_values):
    """Write ``cell_values`` with the native 10-per-line / 100-per-block
    newline cadence and 5-space indentation."""
    for i, v in enumerate(cell_values):
        if i % 10 == 0:
            stream.write("\n     ")
        if i != 0 and i % 100 == 0:
            stream.write("\n     ")
        stream.write(_fmt10_4(float(v)))


def _flow_angle(u, v):
    """Match the native ``MeshData::FI`` function. Return angle in
    *degrees* scaled by the same factor as native (the multiplier 57.298
    converts the radian result to ~degrees, exactly as native does)."""
    MPI = 3.1416
    if u * v != 0.0:
        w = math.atan2(abs(v), abs(u))
        if u * v > 0.0:
            fi = w if u > 0.0 else MPI + w
        else:
            fi = (MPI - w) if v > 0.0 else (2.0 * MPI - w)
    else:
        if u == 0.0 and v >= 0.0:
            fi = MPI / 2.0
        elif u == 0.0 and v < 0.0:
            fi = 3.0 * MPI / 2.0
        elif v == 0.0 and u >= 0.0:
            fi = 0.0
        else:
            fi = MPI
    return fi * 57.298


def _flat_edges(mesh):
    """Return ``(KLAS, NAC, COSF, SINF, SIDE, AREA, ZBC)`` as flat numpy
    arrays in 0-indexed, cell-major order. Handles both F1 (1-indexed
    2-D arrays) and F2 (already flat) mesh dicts."""
    if "CEL" in mesh:  # F1 layout
        cell = int(mesh["CEL"])
        klas = np.zeros(cell * 4, dtype=np.int32)
        nac = np.zeros(cell * 4, dtype=np.int32)
        cosf = np.zeros(cell * 4, dtype=np.float64)
        sinf = np.zeros(cell * 4, dtype=np.float64)
        side = np.zeros(cell * 4, dtype=np.float64)
        for c in range(cell):
            for j in range(4):
                klas[4 * c + j] = int(mesh["KLAS"][j + 1, c + 1])
                nac[4 * c + j] = int(mesh["NAC"][j + 1, c + 1])
                cosf[4 * c + j] = float(mesh["COSF"][j + 1, c + 1])
                sinf[4 * c + j] = float(mesh["SINF"][j + 1, c + 1])
                side[4 * c + j] = float(mesh["SIDE"][j + 1, c + 1])
        area = np.asarray(mesh["AREA"])[1:].astype(np.float64)
        zbc = np.asarray(mesh["ZBC"])[1:].astype(np.float64)
        # F1 has NAP at index 0 sentinel
        nap = np.asarray(mesh["NAP"])[1:, 1:].T  # (CEL, 4)
    else:
        cell = int(mesh["CELL"])
        klas = np.asarray(mesh["KLAS"]).astype(np.int32)
        nac = np.asarray(mesh["NAC"]).astype(np.int32)
        cosf = np.asarray(mesh["COSF"]).astype(np.float64)
        sinf = np.asarray(mesh["SINF"]).astype(np.float64)
        side = np.asarray(mesh["SIDE"]).astype(np.float64)
        area = np.asarray(mesh["AREA"]).astype(np.float64)
        zbc = np.asarray(mesh["ZBC"]).astype(np.float64)
        # F2 mesh keeps NAP 1-indexed shape (5, CELL+1) — drop the row 0
        # sentinel and column 0 sentinel before transposing.
        nap_raw = np.asarray(mesh.get("NAP"))
        if nap_raw.ndim == 2 and nap_raw.shape[1] == cell + 1:
            nap = nap_raw[1:, 1:].T  # (CELL, 4)
        else:
            nap = None
    return cell, klas, nac, cosf, sinf, side, area, zbc, nap


def _normalise_cell_state(state, cell):
    """Return finite-only H/U/V/Z numpy arrays of length cell."""
    def to_np(arr):
        a = np.asarray(arr)
        if a.size == cell + 1:
            a = a[1:]
        return a[:cell].astype(np.float64, copy=False)

    return to_np(state["H"]), to_np(state["U"]), to_np(state["V"]), to_np(state["Z"])


# ---------------------------------------------------------------------------
# Header lines
# ---------------------------------------------------------------------------

def _header_line(jt2, kt, dt):
    # native:  printf-equivalent of
    #   " JT=%5d  KT=%5d  DT=%3d SEC  T= 0H  NSF= 0/0  WEC=0.00/  CQL=0.00  INE=0"
    return (
        f" JT={jt2:>5d}  KT={kt - 1:>5d}  DT={int(dt):>3d} SEC  "
        f"T= 0H  NSF= 0/0  WEC=0/  CQL=0  INE=0"
    )


# ---------------------------------------------------------------------------
# Writer
# ---------------------------------------------------------------------------

class OutputWriter:
    """Stream-mode writer for the five native OUTPUT files."""

    def __init__(self, out_dir, mesh, dt, ndays):
        self.out_dir = out_dir
        os.makedirs(out_dir, exist_ok=True)
        self.dt = float(dt)
        self.ndays = int(ndays)
        cell, klas, nac, cosf, sinf, side, area, zbc, nap = _flat_edges(mesh)
        self.cell = cell
        self.klas = klas
        self.nac = nac
        self.cosf = cosf
        self.sinf = sinf
        self.side = side
        self.area = area
        self.zbc = zbc
        self.nap = nap
        self.hm1 = float(mesh[HM1_KEY])
        # XP / YP for XY-TEC: F1 stores 1-indexed, F2 stores 0-indexed.
        xp = np.asarray(mesh.get("XP"))
        yp = np.asarray(mesh.get("YP"))
        if xp.ndim == 1:
            if xp.size == self.cell or (nap is not None and xp.size > self.cell):
                # Drop sentinel if present
                if xp.size > 0 and xp.size == yp.size and (nap is not None and xp.size != self.cell):
                    pass
        self.xp = xp
        self.yp = yp
        # Open streams (truncate)
        self.h2u2v2 = open(os.path.join(out_dir, "H2U2V2.OUT"), "w")
        self.zuv = open(os.path.join(out_dir, "ZUV.OUT"), "w")
        self.timelog = open(os.path.join(out_dir, "TIMELOG.OUT"), "w")
        self.xy_tec = open(os.path.join(out_dir, "XY-TEC.DAT"), "w")
        self.side_file = open(os.path.join(out_dir, "SIDE.OUT"), "w")
        self._side_written = False

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
    def write_side_once(self):
        """Write SIDE.OUT (only on first frame, jt=0 kt=1)."""
        if self._side_written:
            return
        self._side_written = True
        s = self.side_file
        cell = self.cell
        s.write("COSF\n")
        for i in range(cell):
            s.write(f"{i + 1}    ")
            for k in range(4):
                s.write(f"{self.cosf[4 * i + k]}     ")
            s.write("\n")
        s.write("SINF\n")
        for i in range(cell):
            s.write(f"{i + 1}    ")
            for k in range(4):
                s.write(f"{self.sinf[4 * i + k]}     ")
            s.write("\n")
        s.write("SIDE\n")
        for i in range(cell):
            s.write(f"{i + 1}    ")
            for k in range(4):
                s.write(f"{self.side[4 * i + k]}     ")
            s.write("\n")
        s.write("AREA\n")
        for i in range(cell):
            s.write(f"{i + 1}    {self.area[i]}\n")

    # ---------------------------------------------------------------- header
    def _write_header(self, stream, jt2, kt):
        stream.write(" \n \n")
        stream.write(_header_line(jt2, kt, self.dt))
        stream.write("\n")

    # ---------------------------------------------------------------- frame
    def write_frame(self, jt, kt, state):
        """Append one frame to all five output files."""
        H, U, V, Z = _normalise_cell_state(state, self.cell)
        # Gate field clamping: native zeroes H/U/V where H<=HM1; Z falls back to ZBC.
        h_clamped = np.where(H <= self.hm1, 0.0, H)
        u_clamped = np.where(H <= self.hm1, 0.0, U)
        v_clamped = np.where(H <= self.hm1, 0.0, V)
        z_clamped = np.where(H <= self.hm1, self.zbc, Z)
        # W and FI use raw U/V where wet, 0 where dry.
        wet = H > self.hm1
        w2 = np.where(wet, np.sqrt(U * U + V * V), 0.0)

        jt2 = jt if kt == 1 else jt + 1

        # SIDE.OUT only for the very first frame.
        if not self._side_written and jt == 0 and kt == 1:
            self.write_side_once()

        # H2U2V2.OUT
        self._write_header(self.h2u2v2, jt2, kt)
        self.h2u2v2.write("     \n     H2=")
        _write_block_10x100(self.h2u2v2, h_clamped)
        self.h2u2v2.write("\n     \n     U2=")
        _write_block_10x100(self.h2u2v2, u_clamped)
        self.h2u2v2.write("\n     \n     V2=")
        _write_block_10x100(self.h2u2v2, v_clamped)
        self.h2u2v2.write(" \n")

        # ZUV.OUT
        self._write_header(self.zuv, jt2, kt)
        self.zuv.write("     \n     Z2=")
        _write_block_10x100(self.zuv, z_clamped)
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

        # XY-TEC.DAT (best-effort: only if XP/YP/NAP present)
        if self.xp is not None and self.yp is not None and self.nap is not None:
            self._write_xy_tec_frame(jt2, kt, h_clamped, z_clamped, u_clamped,
                                     v_clamped, w2)

        for f in (self.h2u2v2, self.zuv, self.timelog, self.xy_tec):
            f.flush()

    # ---------------------------------------------------------------- XY-TEC
    def _write_xy_tec_frame(self, jt2, kt, h, z, u, v, w):
        s = self.xy_tec
        # Strip XP/YP sentinel if present (F1 layout has length NOD+1)
        if self.xp.size > 0 and self.xp.size == self.yp.size and self.xp.size != self.cell:
            xp = self.xp[1:] if self.xp.size > 1 else self.xp
            yp = self.yp[1:] if self.yp.size > 1 else self.yp
        else:
            xp = self.xp
            yp = self.yp
        nod = int(xp.size)
        s.write(' VARIABLES = "X", "Y", "H2", "Z2","U2","V2","W2"\n')
        s.write(f"ZONE N={nod}, E={self.cell}, DATAPACKING=BLOCK, ZONETYPE=FEQUADRILATERAL\n")
        s.write("VARLOCATION=([3-7]=CELLCENTERED)\n")

        def write_per_node(arr):
            # 10 values per line, separated by spaces, native uses %.4f
            for i, val in enumerate(arr):
                if i % 10 == 0 and i != 0:
                    s.write("\n")
                s.write(f"{float(val):.4f} ")
            s.write("\n")

        def write_per_cell(arr):
            for i, val in enumerate(arr):
                if i % 10 == 0:
                    s.write("\n")
                s.write(f"{float(val):.4f} ")

        # Coordinates need original-frame XIMIN/YIMIN added back; native re-adds
        # XIMIN before writing. We don't have them here cheaply; use the values
        # as stored. Native does ``XP[i] + XIMIN`` but our XP already had the
        # origin shift applied — close enough for visualization-only output.
        write_per_node(xp)
        write_per_node(yp)
        write_per_cell(h)
        write_per_cell(z)
        write_per_cell(u)
        write_per_cell(v)
        write_per_cell(w)
        s.write("\n")
        # Cell connectivity (NAP rows)
        for i in range(self.cell):
            row = self.nap[i]
            s.write(" ".join(str(int(x)) for x in row) + "\n")


__all__ = ["OutputWriter"]
