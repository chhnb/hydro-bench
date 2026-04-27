"""Load the real hydro-cal mesh from data/ directory.

Reads all input files, computes geometry (SIDE, COSF, SINF, AREA),
and returns a dict of 1-indexed numpy arrays ready for the benchmark kernels.
"""
import math
import os
import numpy as np

_BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(_BASE_DIR, "..", "data", "F1_text")

# Available mesh datasets
MESH_DATASETS = {
    "default": os.path.join(_BASE_DIR, "..", "data", "F1_text"),       # 6,675 cells
    "20w":     os.path.join(_BASE_DIR, "..", "data", "F1_207K_text"),    # 207,234 cells
}


def _read_lines(filename, data_dir=None):
    """Read non-empty, non-comment lines from a data file."""
    path = os.path.join(data_dir or DATA_DIR, filename)
    with open(path, "r") as f:
        lines = []
        for line in f:
            s = line.strip()
            if s and not s.startswith("!") and not s.startswith("#"):
                lines.append(s)
        return lines


def load_hydro_mesh(mesh="default", dtype=np.float64):
    """Load the full hydro-cal 2D mesh and return a dict of arrays.

    Args:
        mesh: Dataset name ("default" for 6675 cells, "20w" for 207234 cells)
              or a path to a custom data directory.
        dtype: numpy dtype for floating-point arrays. Pass np.float32 for the
              fp32 entrypoint so that geometry arithmetic (XP, YP, SIDE, COSF,
              SINF, AREA) runs in fp32 directly — matching the native CUDA fp32
              build, which uses ``Real = float`` throughout ``preCalculate``.
              Default ``np.float64`` preserves the existing fp64 behavior.

    Returns dict with keys:
        CEL, NOD, HM1, HM2, NZ, NQ,
        NAC, KLAS, SIDE, COSF, SINF, SLCOS, SLSIN,
        AREA, ZBC, ZB1, FNC, NV,
        H, U, V, Z, W,
        MBQ, NNQ, MBZ, NNZ,
        XC, YC
    All cell arrays are 1-indexed (index 0 unused).
    2D arrays are [5][CEL+1] (edge index 1..4).
    """
    dtype = np.dtype(dtype)
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
    CEL = int(lines[1].split()[0])

    # ---- DEPTH.DAT: HM1, HM2 ----
    lines = rd("DEPTH.DAT")
    HM1 = float(lines[0].split()[0])
    HM2 = float(lines[1].split()[0])

    # ---- BOUNDARY.DAT ----
    lines = rd("BOUNDARY.DAT")
    NZ = int(lines[0].split()[0])
    NQ = int(lines[1].split()[0])

    # ---- CALTIME.DAT: DT (timestep size in seconds) ----
    if os.path.exists(os.path.join(data_dir, "CALTIME.DAT")):
        ct_lines = rd("CALTIME.DAT")
        DT = float(ct_lines[1].split()[0]) if len(ct_lines) > 1 else 1.0
    else:
        DT = 1.0

    # ---- TIME.DAT: MDT, NDAYS (for ZT timeseries indexing) ----
    if os.path.exists(os.path.join(data_dir, "TIME.DAT")):
        time_lines = rd("TIME.DAT")
        MDT = int(time_lines[0].split()[0])
        NDAYS = int(time_lines[1].split()[0])
    else:
        MDT, NDAYS = 3600, 50

    # ---- PXY.DAT: node coordinates ----
    lines = rd("PXY.DAT")
    # Native fp32 build reads coordinates straight into ``std::vector<float>``,
    # so the origin shift below runs in fp32. Match that by allocating in
    # the caller's dtype and assigning text→dtype directly.
    XP = np.zeros(NOD + 1, dtype=dtype)
    YP = np.zeros(NOD + 1, dtype=dtype)
    for k in range(1, NOD + 1):
        parts = lines[k].split()
        XP[k] = dtype.type(float(parts[1]))
        YP[k] = dtype.type(float(parts[2]))
    # Normalize to origin (fp32 - fp32 in fp32 mode).
    XP[1:] -= XP[1:].min()
    YP[1:] -= YP[1:].min()

    # ---- PNAP.DAT: cell-to-node ----
    lines = rd("PNAP.DAT")
    NAP = np.zeros((5, CEL + 1), dtype=np.int32)
    for k in range(1, CEL + 1):
        parts = lines[k].split()
        for j in range(1, 5):
            NAP[j][k] = int(parts[j])

    # ---- PNAC.DAT: cell neighbors ----
    lines = rd("PNAC.DAT")
    NAC = np.zeros((5, CEL + 1), dtype=np.int32)
    for k in range(1, CEL + 1):
        parts = lines[k].split()
        for j in range(1, 5):
            NAC[j][k] = int(parts[j])

    # ---- PKLAS.DAT: edge types ----
    lines = rd("PKLAS.DAT")
    KLAS = np.zeros((5, CEL + 1), dtype=np.int32)
    for k in range(1, CEL + 1):
        parts = lines[k].split()
        for j in range(1, 5):
            KLAS[j][k] = int(parts[j])

    # ---- PZBC.DAT: bed elevation ----
    lines = rd("PZBC.DAT")
    # First line is header "PZBC" or count — skip non-numeric
    ZBC = np.zeros(CEL + 1, dtype=dtype)
    idx = 0
    for line in lines:
        try:
            val = float(line)
            idx += 1
            if idx <= CEL:
                ZBC[idx] = dtype.type(val)
        except ValueError:
            continue

    # ---- MBQ.DAT: Q boundaries ----
    lines = rd("MBQ.DAT")
    NQ_actual = int(lines[0]) if lines else 0
    MBQ = np.zeros(NQ_actual + 1, dtype=np.int32)
    NNQ = np.zeros(NQ_actual + 1, dtype=np.int32)
    for k in range(1, NQ_actual + 1):
        parts = lines[k].split()
        MBQ[k] = int(parts[1])
        NNQ[k] = int(parts[2])

    # ---- MBZ.DAT: Z boundaries ----
    lines = rd("MBZ.DAT")
    NZ_actual = int(lines[0]) if lines else 0
    MBZ = np.zeros(max(NZ_actual + 1, 1), dtype=np.int32)
    NNZ = np.zeros(max(NZ_actual + 1, 1), dtype=np.int32)
    for k in range(1, NZ_actual + 1):
        parts = lines[k].split()
        MBZ[k] = int(parts[1])
        NNZ[k] = int(parts[2])

    # ---- Initial conditions ----
    def _read_cell_values(filename):
        lines = rd(filename)
        arr = np.zeros(CEL + 1, dtype=dtype)
        idx = 0
        for line in lines:
            try:
                val = float(line)
                idx += 1
                if idx <= CEL:
                    arr[idx] = dtype.type(val)
            except ValueError:
                continue
        return arr

    Z_init = _read_cell_values("INITIALLEVEL.DAT")
    U_init = _read_cell_values("INITIALU1.DAT")
    V_init = _read_cell_values("INITIALV1.DAT")
    CV = _read_cell_values("CV.DAT")  # Manning n

    # ---- CONLINK.TXT: 1D-2D coupling (optional) ----
    conlink_path = os.path.join(data_dir, "CONLINK.TXT")
    if os.path.exists(conlink_path):
        lines = rd("CONLINK.TXT")
        NLINK0 = int(lines[0]) if lines else 0
    else:
        lines = []
        NLINK0 = 0
    # Modify KLAS for coupling boundaries
    for k in range(1, NLINK0 + 1):
        parts = lines[k].split()
        bnd_edge = int(parts[2])   # NLINK2[1] = 2D boundary edge number
        bnd_type = int(parts[3])   # NLINK2[2] = boundary type (13 or 14)
        # Find cells with MBQ matching this edge and set KLAS
        if bnd_type == 13:
            for i in range(1, NQ_actual + 1):
                if NNQ[i] == bnd_edge:
                    cell = MBQ[i]
                    for j in range(1, 5):
                        if NAC[j][cell] == 0 and KLAS[j][cell] == 0:
                            KLAS[j][cell] = 13

    # ---- Compute geometry ----
    # All arithmetic runs in the caller's dtype to match native CUDA's
    # ``preCalculate`` (which uses ``Real = float`` in the fp32 build).
    NV = np.zeros(CEL + 1, dtype=np.int32)
    SIDE = np.zeros((5, CEL + 1), dtype=dtype)
    COSF = np.zeros((5, CEL + 1), dtype=dtype)
    SINF = np.zeros((5, CEL + 1), dtype=dtype)
    AREA = np.zeros(CEL + 1, dtype=dtype)
    XC = np.zeros(CEL + 1, dtype=dtype)
    YC = np.zeros(CEL + 1, dtype=dtype)

    # Use 0-d arrays so accumulations stay in dtype precision rather than
    # being upcast to Python float (= fp64).
    zero = dtype.type(0)
    half = dtype.type(0.5)

    for i in range(1, CEL + 1):
        if NAP[1][i] == 0:
            continue

        # Determine vertex count
        na4 = NAP[4][i]
        if na4 == 0 or na4 == NAP[1][i]:
            NV[i] = 3
        else:
            NV[i] = 4

        nw = [0, NAP[1][i], NAP[2][i], NAP[3][i], NAP[4][i]]

        # Centroid
        sx = zero
        sy = zero
        for j in range(1, NV[i] + 1):
            sx = sx + XP[nw[j]]
            sy = sy + YP[nw[j]]
        XC[i] = sx / dtype.type(NV[i])
        YC[i] = sy / dtype.type(NV[i])

        # Area: triangle (1,2,3) — match native's ``fabs(...)/2.0`` ordering.
        x1, y1 = XP[nw[1]], YP[nw[1]]
        x2, y2 = XP[nw[2]], YP[nw[2]]
        x3, y3 = XP[nw[3]], YP[nw[3]]
        AREA[i] = np.abs((y3 - y1) * (x2 - x1) - (x3 - x1) * (y2 - y1)) * half
        if NV[i] == 4:
            x4, y4 = XP[nw[4]], YP[nw[4]]
            AREA[i] = AREA[i] + np.abs((y4 - y1) * (x3 - x1) - (x4 - x1) * (y3 - y1)) * half

        # Edge geometry
        for j in range(1, NV[i] + 1):
            n1 = nw[j]
            n2 = nw[(j % NV[i]) + 1]
            dx = XP[n1] - XP[n2]
            dy = YP[n2] - YP[n1]
            length = np.sqrt(dx * dx + dy * dy)
            SIDE[j][i] = length
            if length > 0:
                SINF[j][i] = dx / length
                COSF[j][i] = dy / length

    SLCOS = (SIDE * COSF).astype(dtype, copy=False)
    SLSIN = (SIDE * SINF).astype(dtype, copy=False)

    # ---- Derived arrays ----
    HM1_d = dtype.type(HM1)
    ZB1 = (ZBC + HM1_d).astype(dtype, copy=False)
    FNC = (dtype.type(9.81) * CV * CV).astype(dtype, copy=False)

    # Native CUDA mesh.cpp clamps Z and H for dry cells:
    #   if Z[i] <= ZBC[i]: H[i] = HM1; Z[i] = ZB1[i] (= ZBC + HM1)
    #   else: H[i] = Z[i] - ZBC[i]
    # Replicate exactly to match native's initial state bit-for-bit.
    Z = Z_init.copy()
    H = (Z - ZBC).astype(dtype, copy=False)
    dry_mask = Z <= ZBC
    H[dry_mask] = HM1_d
    Z[dry_mask] = ZB1[dry_mask]
    ghost_mask = NAP[1] == 0
    H[ghost_mask] = zero
    W = np.sqrt(U_init * U_init + V_init * V_init).astype(dtype, copy=False)
    Z_init = Z  # so the dict below picks up clamped Z

    # ---- BC timeseries: per-cell ZT/DZT for KLAS=1 boundary cells ----
    #      and per-cell QT/DQT for KLAS=10 boundary cells.
    # Native CUDA mesh.cpp reads MBZ/MBQ.DAT to get boundary cells (1-indexed),
    # then BOUNDE/NZ/NZ{group:04d}.DAT and BOUNDE/NQ/NQ{group:04d}.DAT for
    # each group's water-level / flow-rate timeseries.
    # Layout: flat [NDAYS * CELL] arrays, 0-indexed by cell.
    ZT = np.zeros(NDAYS * CEL, dtype=np.float64)
    DZT = np.zeros(NDAYS * CEL, dtype=np.float64)
    QT = np.zeros(NDAYS * CEL, dtype=np.float64)
    DQT = np.zeros(NDAYS * CEL, dtype=np.float64)
    K0 = int(MDT / DT) if DT > 0 else 1

    def _load_bounde_group(subdir_name, prefix):
        bounde_dir = os.path.join(data_dir, "BOUNDE", subdir_name)
        out = {}
        if not os.path.isdir(bounde_dir):
            return out
        for fn in os.listdir(bounde_dir):
            if not (fn.startswith(prefix) and fn.endswith(".DAT")):
                continue
            try:
                gid = int(fn[len(prefix):len(prefix)+4])
            except ValueError:
                continue
            vals = []
            with open(os.path.join(bounde_dir, fn), 'r', encoding='latin-1') as f:
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
                            # temporary even in the fp64 build.
                            vals.append(float(np.float32(float(parts[1]))))
                        except ValueError:
                            continue
            if vals:
                out[gid] = vals
        return out
    def _read_mbx(filename):
        path = os.path.join(data_dir, filename)
        if not os.path.exists(path):
            return []
        out = []
        for line in rd(filename):
            parts = line.split()
            if len(parts) >= 3:
                try:
                    out.append((int(parts[1]) - 1, int(parts[2])))  # (cell_0idx, group_id)
                except ValueError:
                    continue
        return out

    # KLAS=1: water level
    if NZ > 0:
        MBZ_cells = _read_mbx("MBZ.DAT")
        nz_data = _load_bounde_group("NZ", "NZ")
        # group_size: how many cells share a group (Native divides timeseries value)
        group_count_z = {}
        for _, gid in MBZ_cells:
            group_count_z[gid] = group_count_z.get(gid, 0) + 1
        for cell_0idx, group_id in MBZ_cells:
            if group_id in nz_data:
                wl = nz_data[group_id]
                for day in range(NDAYS):
                    z_day = wl[min(day, len(wl) - 1)]
                    ZT[day * CEL + cell_0idx] = z_day
                    if day < NDAYS - 1 and K0 > 0:
                        z_next = wl[min(day + 1, len(wl) - 1)]
                        DZT[day * CEL + cell_0idx] = (z_next - z_day) / K0

    # KLAS=10: flow rate (per cell = Q_group / group_size, divided in native)
    if NQ > 0:
        MBQ_cells = _read_mbx("MBQ.DAT")
        nq_data = _load_bounde_group("NQ", "NQ")
        group_count_q = {}
        for _, gid in MBQ_cells:
            group_count_q[gid] = group_count_q.get(gid, 0) + 1
        for cell_0idx, group_id in MBQ_cells:
            if group_id in nq_data:
                qs = nq_data[group_id]
                kl = max(group_count_q.get(group_id, 1), 1)
                for day in range(NDAYS):
                    q_day = float(np.float32(np.float32(qs[min(day, len(qs) - 1)]) / np.float32(kl)))
                    QT[day * CEL + cell_0idx] = q_day
                    if day < NDAYS - 1 and K0 > 0:
                        q_next = float(np.float32(np.float32(qs[min(day + 1, len(qs) - 1)]) / np.float32(kl)))
                        DQT[day * CEL + cell_0idx] = (q_next - q_day) / K0

    return dict(
        CEL=CEL, NOD=NOD, HM1=HM1, HM2=HM2, NZ=NZ, NQ=NQ, DT=DT,
        MDT=MDT, NDAYS=NDAYS,
        NAC=NAC, KLAS=KLAS, SIDE=SIDE, COSF=COSF, SINF=SINF,
        SLCOS=SLCOS, SLSIN=SLSIN,
        AREA=AREA, ZBC=ZBC, ZB1=ZB1, FNC=FNC, NV=NV,
        H=H, U=U_init.copy(), V=V_init.copy(), Z=Z_init.copy(), W=W,
        MBQ=MBQ, NNQ=NNQ, MBZ=MBZ, NNZ=NNZ,
        ZT=ZT, DZT=DZT, QT=QT, DQT=DQT,
        XC=XC, YC=YC,
    )


if __name__ == "__main__":
    import sys
    mesh_name = sys.argv[1] if len(sys.argv) > 1 else "default"
    mesh = load_hydro_mesh(mesh=mesh_name)
    print(f"Loaded mesh: {mesh['CEL']} cells, {mesh['NOD']} nodes")
    print(f"HM1={mesh['HM1']}, HM2={mesh['HM2']}")
    print(f"NZ={mesh['NZ']}, NQ={mesh['NQ']}")
    print(f"H range: [{mesh['H'][1:].min():.4f}, {mesh['H'][1:].max():.4f}]")
    print(f"Z range: [{mesh['Z'][1:].min():.4f}, {mesh['Z'][1:].max():.4f}]")
    print(f"ZBC range: [{mesh['ZBC'][1:].min():.4f}, {mesh['ZBC'][1:].max():.4f}]")
    print(f"AREA range: [{mesh['AREA'][1:].min():.4f}, {mesh['AREA'][1:].max():.4f}]")
    print(f"SIDE[1] range: [{mesh['SIDE'][1][1:].min():.4f}, {mesh['SIDE'][1][1:].max():.4f}]")
    print(f"FNC range: [{mesh['FNC'][1:].min():.6f}, {mesh['FNC'][1:].max():.6f}]")
    # Count KLAS types
    from collections import Counter
    klas_counts = Counter()
    for j in range(1, 5):
        for i in range(1, mesh['CEL'] + 1):
            klas_counts[mesh['KLAS'][j][i]] += 1
    print(f"KLAS types: {dict(klas_counts)}")
