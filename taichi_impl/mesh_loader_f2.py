"""Load the real hydro-cal mesh for the refactored kernel (F2).

Data layout: edges stored as flat [4*CELL] arrays (0-indexed).
Cells stored as [CELL] arrays (0-indexed).
NAC stores 1-indexed neighbor IDs (0 means no neighbor).

This loader reads from data/ directory and returns numpy arrays
in the EXACT layout expected by the refactored CUDA kernel.
"""
import math
import os
import numpy as np

_BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(_BASE_DIR, "..", "data", "F2_24K_text")

# Available mesh datasets
MESH_DATASETS = {
    "default": os.path.join(_BASE_DIR, "..", "data", "F2_24K_text"),       # 24,020 cells
    "20w":     os.path.join(_BASE_DIR, "..", "data", "F2_207K_text"),    # 207,234 cells
}


def _boundary_interp(t_query, xp, fp):
    """Mirror native ``MeshData::BOUNDRYinterp`` (mesh.cpp:523-533).

    Linear interpolation through the (xp, fp) pairs. Native returns 0 when the
    query is outside [xp[0], xp[-1]]; np.interp would clamp to fp[0]/fp[-1],
    which silently diverges from native on data sets where the BC table does
    not bracket the simulation window. Use this helper to keep Taichi
    bit-for-bit aligned with native semantics.
    """
    t_query = np.asarray(t_query, dtype=np.float64)
    xp = np.asarray(xp, dtype=np.float64)
    fp = np.asarray(fp, dtype=np.float64)
    out = np.zeros_like(t_query)
    if xp.size < 2:
        return out
    in_range = (t_query >= xp[0]) & (t_query <= xp[-1])
    if not np.any(in_range):
        return out
    idx = np.searchsorted(xp, t_query, side='right') - 1
    idx = np.clip(idx, 0, xp.size - 2)
    i = idx[in_range]
    out[in_range] = fp[i] + (fp[i + 1] - fp[i]) / (xp[i + 1] - xp[i]) * (t_query[in_range] - xp[i])
    return out


def _read_lines(filename, data_dir=None):
    """Read non-empty, non-comment lines from a data file."""
    path = os.path.join(data_dir or DATA_DIR, filename)
    with open(path, 'r', encoding='latin-1') as f:
        lines = []
        for line in f:
            s = line.strip()
            if s and not s.startswith("!") and not s.startswith("#"):
                lines.append(s)
        return lines


def load_mesh(mesh="default", dtype=np.float32):
    """Load the refactored hydro-cal mesh.

    Args:
        mesh: Dataset name ("default" for 24020 cells, "20w" for 207234 cells)
        dtype: float type for geometry/state arrays (np.float32 or np.float64)
              or a path to a custom data directory.

    Returns dict with:
        CELL, NOD, HM1, HM2, DT, MDT, NDAYS, JL,
        # Cell arrays [CELL] (0-indexed)
        H, U, V, Z, W, ZBC, ZB1, AREA, FNC,
        # Side arrays [4*CELL] (edge j of cell i at index 4*i+j)
        NAC, KLAS, SIDE, COSF, SINF, SLCOS, SLSIN,
        FLUX0, FLUX1, FLUX2, FLUX3,  (output buffers)
        # Boundary data
        QT, DQT, ZT, DZT, NQ, NZ, NHQ,
        BoundaryFeature,
        # Mesh geometry
        XC, YC, NV
    """
    if mesh in MESH_DATASETS:
        data_dir = MESH_DATASETS[mesh]
    elif os.path.isdir(mesh):
        data_dir = mesh
    else:
        raise ValueError(f"Unknown mesh '{mesh}'. Available: {list(MESH_DATASETS.keys())}")

    def rd(filename):
        return _read_lines(filename, data_dir=data_dir)

    # ---- GIRD.DAT: NOD, CEL ----
    lines = rd("GIRD.DAT")
    NOD = int(lines[0].split()[0])
    CELL = int(lines[1].split()[0])

    # ---- DEPTH.DAT: HM1, HM2 ----
    lines = rd("DEPTH.DAT")
    HM1 = float(lines[0].split()[0])
    HM2 = float(lines[1].split()[0])

    # ---- TIME.DAT: MDT, NDAYS ----
    lines = rd("TIME.DAT") if os.path.exists(os.path.join(data_dir, "TIME.DAT")) else ["3600", "50", "1"]
    MDT = int(lines[0].split()[0])
    NDAYS = int(lines[1].split()[0])

    # ---- CALTIME.DAT: DT ----
    lines = rd("CALTIME.DAT") if os.path.exists(os.path.join(data_dir, "CALTIME.DAT")) else ["0", "4"]
    DT = float(lines[1].split()[0])

    # ---- JL.DAT ----
    JL = 0.0
    if os.path.exists(os.path.join(data_dir, "JL.DAT")):
        lines = rd("JL.DAT")
        if lines:
            JL = float(lines[0].split()[0])

    # ---- BOUNDARY.DAT ----
    lines = rd("BOUNDARY.DAT")
    NZ = int(lines[0].split()[0])
    NQ = int(lines[1].split()[0])
    NZQ = int(lines[2].split()[0]) if len(lines) > 2 else 0
    NHQ = int(lines[3].split()[0]) if len(lines) > 3 else 5
    NWE = int(lines[4].split()[0]) if len(lines) > 4 else 0
    NDI = int(lines[5].split()[0]) if len(lines) > 5 else 0

    # ---- PXY.DAT: node coordinates ----
    lines = rd("PXY.DAT")
    XP = np.zeros(NOD + 1, dtype=dtype)
    YP = np.zeros(NOD + 1, dtype=dtype)
    for k in range(1, NOD + 1):
        parts = lines[k].split()
        XP[k] = float(parts[1])
        YP[k] = float(parts[2])
    XIMIN = dtype(XP[1:].min())
    YIMIN = dtype(YP[1:].min())
    XP[1:] -= XIMIN
    YP[1:] -= YIMIN

    # ---- PNAP.DAT: cell-to-node ----
    lines = rd("PNAP.DAT")
    NAP = np.zeros((5, CELL + 1), dtype=np.int32)
    for k in range(1, CELL + 1):
        parts = lines[k].split()
        for j in range(1, 5):
            NAP[j][k] = int(parts[j])

    # ---- PNAC.DAT: cell neighbors (1-indexed, 0=no neighbor) ----
    lines = rd("PNAC.DAT")
    # Refactored layout: NAC[4*cell + edge], stores 1-indexed (kernel does NC-1)
    NAC = np.zeros(4 * CELL, dtype=np.int32)
    for k in range(1, CELL + 1):
        parts = lines[k].split()
        for j in range(1, 5):
            NAC[4 * (k - 1) + (j - 1)] = int(parts[j])

    # ---- PKLAS.DAT: edge types ----
    lines = rd("PKLAS.DAT")
    KLAS = np.zeros(4 * CELL, dtype=np.float32)  # float in refactored version
    for k in range(1, CELL + 1):
        parts = lines[k].split()
        for j in range(1, 5):
            KLAS[4 * (k - 1) + (j - 1)] = float(parts[j])

    # ---- PZBC.DAT: bed elevation ----
    lines = rd("PZBC.DAT")
    ZBC = np.zeros(CELL, dtype=dtype)
    idx = 0
    for line in lines:
        try:
            val = float(line)
            if idx < CELL:
                ZBC[idx] = val
                idx += 1
        except ValueError:
            continue

    # ---- Initial conditions ----
    def _read_cell_values(filename):
        lines = rd(filename)
        arr = np.zeros(CELL, dtype=dtype)
        idx = 0
        for line in lines:
            try:
                val = float(line)
                if idx < CELL:
                    arr[idx] = val
                    idx += 1
            except ValueError:
                continue
        return arr

    Z_init = _read_cell_values("INITIALLEVEL.DAT")
    U_init = _read_cell_values("INITIALU1.DAT")
    V_init = _read_cell_values("INITIALV1.DAT")
    CV = _read_cell_values("CV.DAT")

    # ---- Compute geometry ----
    NV = np.zeros(CELL, dtype=np.int32)
    SIDE = np.zeros(4 * CELL, dtype=dtype)
    COSF = np.zeros(4 * CELL, dtype=dtype)
    SINF = np.zeros(4 * CELL, dtype=dtype)
    AREA = np.zeros(CELL, dtype=dtype)
    XC = np.zeros(CELL, dtype=dtype)
    YC = np.zeros(CELL, dtype=dtype)

    for i in range(CELL):
        ci = i + 1  # 1-indexed for NAP
        if NAP[1][ci] == 0:
            continue
        na4 = NAP[4][ci]
        if na4 == 0 or na4 == NAP[1][ci]:
            NV[i] = 3
        else:
            NV[i] = 4

        nw = [0, NAP[1][ci], NAP[2][ci], NAP[3][ci], NAP[4][ci]]
        sx = sy = 0.0
        for j in range(1, NV[i] + 1):
            sx += XP[nw[j]]
            sy += YP[nw[j]]
        XC[i] = sx / NV[i]
        YC[i] = sy / NV[i]

        x1, y1 = XP[nw[1]], YP[nw[1]]
        x2, y2 = XP[nw[2]], YP[nw[2]]
        x3, y3 = XP[nw[3]], YP[nw[3]]
        AREA[i] = abs((y3 - y1) * (x2 - x1) - (x3 - x1) * (y2 - y1)) / 2.0
        if NV[i] == 4:
            x4, y4 = XP[nw[4]], YP[nw[4]]
            AREA[i] += abs((y4 - y1) * (x3 - x1) - (x4 - x1) * (y3 - y1)) / 2.0

        for j in range(1, NV[i] + 1):
            n1 = nw[j]
            n2 = nw[(j % NV[i]) + 1]
            dx = XP[n1] - XP[n2]
            dy = YP[n2] - YP[n1]
            length = math.sqrt(dx * dx + dy * dy)
            edge_idx = 4 * i + (j - 1)
            SIDE[edge_idx] = length
            if length > 0:
                SINF[edge_idx] = dx / length
                COSF[edge_idx] = dy / length

    SLCOS = SIDE * COSF
    SLSIN = SIDE * SINF
    ZB1 = ZBC + HM1
    FNC = (9.81 * CV * CV).astype(dtype)

    # Native mesh.cpp only clamps dry cells:
    #   if Z <= ZBC: H = HM1 and Z = ZBC + HM1
    #   else:        H = Z - ZBC
    # Shallow wet cells with 0 < H < HM1 must not be clamped here; the
    # update kernel applies HM1 after the first timestep.
    Z = Z_init.copy()
    H = Z - ZBC
    dry_mask = Z <= ZBC
    H[dry_mask] = HM1
    Z[dry_mask] = ZB1[dry_mask]
    ghost_mask = NAP[1, 1:CELL + 1] == 0
    H[ghost_mask] = 0.0
    W = np.sqrt(U_init ** 2 + V_init ** 2).astype(dtype)

    # FLUX buffers (output, initialized to 0)
    FLUX0 = np.zeros(4 * CELL, dtype=dtype)
    FLUX1 = np.zeros(4 * CELL, dtype=dtype)
    FLUX2 = np.zeros(4 * CELL, dtype=dtype)
    FLUX3 = np.zeros(4 * CELL, dtype=dtype)

    # Boundary data: ZT/DZT for KLAS=1 (water level), QT/DQT for KLAS=10 (flow)
    ZT = np.zeros(NDAYS * CELL, dtype=dtype)
    DZT = np.zeros(NDAYS * CELL, dtype=dtype)
    QT = np.zeros(NDAYS * CELL, dtype=dtype)
    DQT = np.zeros(NDAYS * CELL, dtype=dtype)
    BoundaryFeature = np.zeros(CELL, dtype=dtype)
    NHQ1 = np.zeros(CELL, dtype=np.int32)
    ZW = np.zeros(max(CELL * NHQ, 1), dtype=dtype)
    QW = np.zeros(max(CELL * NHQ, 1), dtype=dtype)

    K0 = int(MDT / DT)  # steps per day

    # ---- MBZ.DAT: water level boundary cells (KLAS=1) ----
    mbz_path = os.path.join(data_dir, "MBZ.DAT")
    MBZ_cells = []  # list of (cell_0indexed, group_id)
    if NZ > 0 and os.path.exists(mbz_path):
        lines_mbz = rd("MBZ.DAT")
        # Skip header lines (first line is count or descriptor)
        for line in lines_mbz:
            parts = line.split()
            if len(parts) >= 3:
                try:
                    idx = int(parts[0])
                    cell_id = int(parts[1])  # 1-indexed
                    group_id = int(parts[2])
                    MBZ_cells.append((cell_id - 1, group_id))  # convert to 0-indexed
                except ValueError:
                    continue

        # Load NZ boundary time series from BOUNDE/NZ/NZxxxx.DAT.
        # Each file is a (time_in_days, water_level) sequence with the
        # leading row being the count of data points. Native's
        # ``BOUNDRYinterp`` linearly interpolates between (time, value)
        # pairs and HOLDS the last value beyond the file's time range.
        # The previous Taichi loader treated the file's i-th value as
        # "water level on day i", which silently zero-fills days beyond
        # the file's last index when the file's time-stamps actually
        # span the full simulation window. For NZ0001.DAT the two-point
        # series ``(t=-1, Z=2925.24)`` and ``(t=60, Z=2925.24)`` is meant
        # to mean "Z=2925.24 throughout day 0..59", but the old loader
        # filled only days 0,1 and left day 2..NDAYS-1 = 0. That broke
        # KLAS=1 boundaries on F2_207K_fp64 starting at step=14399 (the
        # cell 207225 collapse).
        bounde_dir = os.path.join(data_dir, "BOUNDE", "NZ")
        nz_data = {}  # group_id -> list of (time_days, water_level)
        for gid in range(1, NZ + 1):
            nz_file = os.path.join(bounde_dir, f"NZ{gid:04d}.DAT")
            if os.path.exists(nz_file):
                pairs = []
                with open(nz_file, 'r', encoding='latin-1') as f:
                    first_line = True
                    for line in f:
                        s = line.strip()
                        if not s:
                            continue
                        if first_line:
                            first_line = False
                            parts = s.split()
                            if len(parts) == 1:
                                # Header is the count of data points.
                                continue
                        parts = s.split()
                        if len(parts) >= 2:
                            try:
                                pairs.append((float(parts[0]), float(parts[1])))
                            except ValueError:
                                continue
                if pairs:
                    pairs.sort(key=lambda p: p[0])
                    nz_data[gid] = pairs

        # Vectorized BOUNDRYinterp per group: precompute the per-day
        # interpolated series once (with fp32 truncation matching native's
        # `float ZTTEMP` cast), then scatter to all cells in the group.
        # Avoids the O(NDAYS * pairs) Python linear search that made
        # F2_24K (NDAYS=2000, ~19k pairs/group) effectively hang.
        # Native mesh.cpp:407 computes STIME1 = i / (24*3600/MDT) = i*MDT/86400
        # in fp32, so the time axis is in *days* with MDT-step granularity, not
        # plain day index. For F2_207K (MDT=3600), step i is i/24 day = i hour.
        days_arr = (np.arange(NDAYS, dtype=np.float64) * (MDT / 86400.0)).astype(np.float32).astype(np.float64)
        nz_per_day = {}
        for gid, pairs in nz_data.items():
            xp = np.array([p[0] for p in pairs], dtype=np.float64)
            fp = np.array([p[1] for p in pairs], dtype=np.float64)
            # _boundary_interp mirrors native BOUNDRYinterp: 0 outside range
            # (mesh.cpp:523-533). Earlier the loader used np.interp which holds
            # endpoints; that diverges from native when the BC table does not
            # bracket the simulation window.
            z = _boundary_interp(days_arr, xp, fp).astype(np.float32).astype(np.float64)
            nz_per_day[gid] = z

        for cell_0idx, group_id in MBZ_cells:
            if group_id in nz_per_day:
                z = nz_per_day[group_id]
                base_idx = np.arange(NDAYS) * CELL + cell_0idx
                ZT[base_idx] = z
                if K0 > 0 and NDAYS > 1:
                    dzt_base = np.arange(NDAYS - 1) * CELL + cell_0idx
                    DZT[dzt_base] = (z[1:] - z[:-1]) / K0

    # ---- MBQ.DAT: flow boundary cells (KLAS=10) ----
    lines_mbq = rd("MBQ.DAT")
    NQ_actual = int(lines_mbq[0]) if lines_mbq else 0

    # Load NQ flow-rate timeseries: same logic as ZT/NZ above.
    if NQ > 0:
        MBQ_cells = []
        for line in lines_mbq:
            parts = line.split()
            if len(parts) >= 3:
                try:
                    cell_id = int(parts[1])
                    group_id = int(parts[2])
                    MBQ_cells.append((cell_id - 1, group_id))
                except ValueError:
                    continue
        bounde_nq = os.path.join(data_dir, "BOUNDE", "NQ")
        nq_data = {}
        group_count_q = {}
        for _, gid in MBQ_cells:
            group_count_q[gid] = group_count_q.get(gid, 0) + 1
        # Same (time, value) interpretation as NZ above: each NQ file
        # is a sequence of (time_in_days, discharge) pairs, and native
        # BOUNDRYinterp linearly interpolates between them, holding
        # endpoints. Replace the previous "i-th value = day i" reading.
        if os.path.isdir(bounde_nq):
            for fn in os.listdir(bounde_nq):
                if not (fn.startswith("NQ") and fn.endswith(".DAT")):
                    continue
                try:
                    gid = int(fn[2:6])
                except ValueError:
                    continue
                pairs = []
                with open(os.path.join(bounde_nq, fn), 'r', encoding='latin-1') as f:
                    first = True
                    for line in f:
                        s = line.strip()
                        if not s:
                            continue
                        parts = s.split()
                        if first and len(parts) == 1:
                            first = False
                            continue
                        first = False
                        if len(parts) >= 2:
                            try:
                                # Native stores BOUNDRYinterp output in a float
                                # temporary even when Real is double.
                                pairs.append((float(parts[0]),
                                              float(np.float32(float(parts[1])))))
                            except ValueError:
                                continue
                if pairs:
                    pairs.sort(key=lambda p: p[0])
                    nq_data[gid] = pairs
        # Same vectorization pattern as ZT/NZ above. The native code
        # divides BOUNDRYinterp's fp32 output by group size in fp32
        # before storing, so the per-day per-group series is precomputed
        # in fp32 and then scattered to each cell in the group.
        # Time axis is i*MDT/86400 in fp32 (mesh.cpp:444), not plain day index.
        days_arr = (np.arange(NDAYS, dtype=np.float64) * (MDT / 86400.0)).astype(np.float32).astype(np.float64)
        nq_per_day = {}
        for gid, pairs in nq_data.items():
            xp = np.array([p[0] for p in pairs], dtype=np.float64)
            fp = np.array([p[1] for p in pairs], dtype=np.float64)
            # See _boundary_interp note above: native returns 0 outside table.
            q_full = _boundary_interp(days_arr, xp, fp).astype(np.float32)
            nq_per_day[gid] = q_full

        for cell_0idx, group_id in MBQ_cells:
            if group_id in nq_per_day:
                kl = max(group_count_q.get(group_id, 1), 1)
                q = (nq_per_day[group_id] / np.float32(kl)).astype(np.float32).astype(np.float64)
                base_idx = np.arange(NDAYS) * CELL + cell_0idx
                QT[base_idx] = q
                if K0 > 0 and NDAYS > 1:
                    dqt_base = np.arange(NDAYS - 1) * CELL + cell_0idx
                    DQT[dqt_base] = (q[1:] - q[:-1]) / K0

    # ---- MBW.DAT: weir top elevation for KLAS=6 ----
    # Native CellView::FromHost currently maps TOPW into BoundaryFeature.
    # TOPD/MDI for KLAS=7 is intentionally not mapped in native (TODO
    # there), so it remains zero here as well.
    if NWE > 0 and os.path.exists(os.path.join(data_dir, "MBW.DAT")):
        lines_mbw = rd("MBW.DAT")
        for line in lines_mbw[1:]:
            parts = line.split()
            if len(parts) >= 3:
                try:
                    cell_id = int(parts[1])
                    topw = float(parts[2])
                except ValueError:
                    continue
                if 1 <= cell_id <= CELL:
                    BoundaryFeature[cell_id - 1] = topw

    # ---- MBZQ.DAT + BOUNDE/NZQ: rating-curve data for KLAS=3 ----
    if NZQ > 0 and NHQ > 0 and os.path.exists(os.path.join(data_dir, "MBZQ.DAT")):
        lines_mbzq = rd("MBZQ.DAT")
        NNZQ0 = int(lines_mbzq[0].split()[0]) if lines_mbzq else 0
        MBZQ = np.zeros(NZQ, dtype=np.int32)
        NNZQ = np.zeros(NZQ, dtype=np.int32)
        row = 0
        for line in lines_mbzq[1:]:
            parts = line.split()
            if len(parts) >= 3 and row < NZQ:
                try:
                    MBZQ[row] = int(parts[1])
                    NNZQ[row] = int(parts[2])
                    row += 1
                except ValueError:
                    continue

        nzq_dir = os.path.join(data_dir, "BOUNDE", "NZQ")
        for group_id in range(1, NNZQ0 + 1):
            nzq_file = os.path.join(nzq_dir, f"NZQ{group_id:04d}.DAT")
            if not os.path.exists(nzq_file):
                continue
            rows = []
            with open(nzq_file, "r", encoding="latin-1") as f:
                for raw in f:
                    s = raw.strip()
                    if s:
                        rows.append(s)
            if not rows:
                continue
            try:
                nhq_temp = min(int(rows[0].split()[0]), NHQ)
            except ValueError:
                continue

            group_rows = np.where(NNZQ == group_id)[0]
            for i in range(nhq_temp):
                if i + 1 >= len(rows):
                    break
                parts = rows[i + 1].split()
                if len(parts) < 2:
                    continue
                try:
                    zq = float(parts[0])
                    qq = float(parts[1])
                except ValueError:
                    continue

                aqzh0 = np.zeros(NZQ, dtype=np.float64)
                aqzh1 = 0.0
                for j in group_rows:
                    cell_0idx = int(MBZQ[j]) - 1
                    if cell_0idx < 0 or cell_0idx >= CELL:
                        continue
                    NHQ1[cell_0idx] = nhq_temp
                    for jj in range(4):
                        edge_idx = cell_0idx * 4 + jj
                        if int(KLAS[edge_idx]) == 3:
                            aqzh0[j] = max(zq - float(ZBC[cell_0idx]), float(HM2)) * float(SIDE[edge_idx])
                    aqzh1 += aqzh0[j]

                for j in group_rows:
                    cell_0idx = int(MBZQ[j]) - 1
                    if cell_0idx < 0 or cell_0idx >= CELL:
                        continue
                    base = cell_0idx * NHQ + i
                    ZW[base] = zq
                    if aqzh1 != 0.0:
                        QW[base] = qq * aqzh0[j] / aqzh1

    steps_per_day = int(MDT / DT)

    return dict(
        CELL=CELL, NOD=NOD, HM1=dtype(HM1), HM2=dtype(HM2),
        DT=dtype(DT), MDT=MDT, NDAYS=NDAYS, JL=dtype(JL),
        steps_per_day=steps_per_day, NQ=NQ, NZ=NZ, NZQ=NZQ,
        NHQ=NHQ, NWE=NWE, NDI=NDI,
        H=H, U=U_init.astype(dtype), V=V_init.astype(dtype),
        Z=Z.astype(dtype), W=W,
        ZBC=ZBC, ZB1=ZB1.astype(dtype), AREA=AREA, FNC=FNC.astype(dtype),
        NAC=NAC, NAP=NAP, KLAS=KLAS, SIDE=SIDE, COSF=COSF, SINF=SINF,
        SLCOS=SLCOS.astype(dtype), SLSIN=SLSIN.astype(dtype),
        FLUX0=FLUX0, FLUX1=FLUX1, FLUX2=FLUX2, FLUX3=FLUX3,
        ZT=ZT, DZT=DZT, QT=QT, DQT=DQT, BoundaryFeature=BoundaryFeature,
        NHQ1=NHQ1, ZW=ZW, QW=QW,
        XP=XP, YP=YP, XIMIN=XIMIN, YIMIN=YIMIN,
        XC=XC, YC=YC, NV=NV,
    )


if __name__ == "__main__":
    import sys
    mesh_name = sys.argv[1] if len(sys.argv) > 1 else "default"
    mesh = load_mesh(mesh=mesh_name)
    print(f"Loaded mesh: {mesh['CELL']} cells")
    print(f"HM1={mesh['HM1']}, HM2={mesh['HM2']}, DT={mesh['DT']}")
    print(f"Steps/day={mesh['steps_per_day']}, NDAYS={mesh['NDAYS']}")
    print(f"H range: [{mesh['H'].min():.4f}, {mesh['H'].max():.4f}]")
    print(f"Z range: [{mesh['Z'].min():.4f}, {mesh['Z'].max():.4f}]")
    print(f"AREA range: [{mesh['AREA'][mesh['AREA']>0].min():.1f}, {mesh['AREA'].max():.1f}]")
    print(f"SIDE range: [{mesh['SIDE'][mesh['SIDE']>0].min():.1f}, {mesh['SIDE'].max():.1f}]")

    from collections import Counter
    klas_counts = Counter()
    for v in mesh['KLAS']:
        klas_counts[int(v)] += 1
    print(f"KLAS types: {dict(klas_counts)}")
