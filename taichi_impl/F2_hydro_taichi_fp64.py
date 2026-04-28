"""F2: Refactored Hydro-Cal — Taichi (fp64, edge-parallel flux + cell-parallel update).

Two-kernel design matching the refactored CUDA kernel:
  1. CalculateFluxKernel: 1 thread per edge (4*CELL), computes flux per edge
  2. UpdateCellKernel:    1 thread per cell (CELL),   accumulates fluxes, updates state

fp64 version — all fields and computations use double precision.
"""
import os
import sys
import numpy as np
import taichi as ti

sys.path.insert(0, os.path.dirname(__file__))
from mesh_loader_f2 import load_mesh

# ---------------------------------------------------------------------------
# Constants (fp64)
# ---------------------------------------------------------------------------
G: ti.f64 = 9.81
HALF_G: ti.f64 = 4.905
C0: ti.f64 = 1.33
C1: ti.f64 = 1.7
VMIN: ti.f64 = 0.001
QLUA: ti.f64 = 0.0
BRDTH: ti.f64 = 100.0


def run(days=10, backend="cuda", mesh="default", steps=None):
    ti.init(arch=ti.cuda if backend == "cuda" else ti.cpu, default_fp=ti.f64, fast_math=False)
    mesh_data = load_mesh(mesh=mesh, dtype=np.float64)
    mesh = mesh_data

    CELL = mesh["CELL"]
    NE = 4 * CELL
    HM1 = float(mesh["HM1"])
    HM2 = float(mesh["HM2"])
    DT = float(mesh["DT"])
    JL = float(mesh["JL"])
    NHQ = int(mesh["NHQ"])
    steps_per_day = mesh["steps_per_day"]
    steps_in_day = max(steps_per_day - 1, 1)
    total_steps = steps if steps is not None else steps_in_day * days

    # --- Fields: edges [4*CELL] ---
    NAC   = ti.field(ti.i32, shape=NE)
    KLAS  = ti.field(ti.f64, shape=NE)
    SIDE  = ti.field(ti.f64, shape=NE)
    COSF  = ti.field(ti.f64, shape=NE)
    SINF  = ti.field(ti.f64, shape=NE)
    SLCOS = ti.field(ti.f64, shape=NE)
    SLSIN = ti.field(ti.f64, shape=NE)
    FLUX0 = ti.field(ti.f64, shape=NE)
    FLUX1 = ti.field(ti.f64, shape=NE)
    FLUX2 = ti.field(ti.f64, shape=NE)
    FLUX3 = ti.field(ti.f64, shape=NE)

    # --- Fields: cells [CELL] ---
    H    = ti.field(ti.f64, shape=CELL)
    U    = ti.field(ti.f64, shape=CELL)
    V    = ti.field(ti.f64, shape=CELL)
    Z    = ti.field(ti.f64, shape=CELL)
    W    = ti.field(ti.f64, shape=CELL)
    ZBC  = ti.field(ti.f64, shape=CELL)
    ZB1  = ti.field(ti.f64, shape=CELL)
    AREA = ti.field(ti.f64, shape=CELL)
    FNC  = ti.field(ti.f64, shape=CELL)
    BoundaryFeature = ti.field(ti.f64, shape=CELL)
    NHQ1 = ti.field(ti.i32, shape=CELL)

    # --- Fields: boundary data [NDAYS*CELL] ---
    NDAYS = mesh["NDAYS"]
    ZT  = ti.field(ti.f64, shape=NDAYS * CELL)
    DZT = ti.field(ti.f64, shape=NDAYS * CELL)
    QT  = ti.field(ti.f64, shape=NDAYS * CELL)
    DQT = ti.field(ti.f64, shape=NDAYS * CELL)
    ZW = ti.field(ti.f64, shape=max(CELL * NHQ, 1))
    QW = ti.field(ti.f64, shape=max(CELL * NHQ, 1))

    # --- Load data into fields ---
    NAC.from_numpy(mesh["NAC"])
    KLAS.from_numpy(mesh["KLAS"])
    SIDE.from_numpy(mesh["SIDE"])
    COSF.from_numpy(mesh["COSF"])
    SINF.from_numpy(mesh["SINF"])
    SLCOS.from_numpy(mesh["SLCOS"])
    SLSIN.from_numpy(mesh["SLSIN"])
    H.from_numpy(mesh["H"])
    U.from_numpy(mesh["U"])
    V.from_numpy(mesh["V"])
    Z.from_numpy(mesh["Z"])
    W.from_numpy(mesh["W"])
    ZBC.from_numpy(mesh["ZBC"])
    ZB1.from_numpy(mesh["ZB1"])
    AREA.from_numpy(mesh["AREA"])
    FNC.from_numpy(mesh["FNC"])
    BoundaryFeature.from_numpy(mesh["BoundaryFeature"])
    NHQ1.from_numpy(mesh["NHQ1"])
    ZT.from_numpy(mesh["ZT"])
    DZT.from_numpy(mesh["DZT"])
    QT.from_numpy(mesh["QT"])
    DQT.from_numpy(mesh["DQT"])
    ZW.from_numpy(mesh["ZW"])
    QW.from_numpy(mesh["QW"])

    # ------------------------------------------------------------------
    # Taichi functions
    # ------------------------------------------------------------------
    @ti.func
    def half_g_h2(h: ti.f64) -> ti.f64:
        return (ti.cast(4.905, ti.f64) * h) * h

    @ti.func
    def qf_accum(fl0: ti.f64, fl1: ti.f64, fl2: ti.f64, fl3: ti.f64,
                 sign: ti.template(), h: ti.f64, u: ti.f64, v: ti.f64) -> ti.types.vector(4, ti.f64):
        q0 = h * u
        q1 = q0 * u
        q2 = q0 * v
        q3 = half_g_h2(h)
        s = ti.cast(sign, ti.f64)
        fl0 = fl0 + q0 * s
        fl1 = fl1 + q1 * s
        fl2 = fl2 + q2 * s
        fl3 = fl3 + q3 * s
        return ti.Vector([fl0, fl1, fl2, fl3])

    @ti.func
    def qs_accum(kind: ti.template(), sign: ti.template(),
                 QL: ti.types.vector(3, ti.f64), QR: ti.types.vector(3, ti.f64),
                 fil: ti.f64, fir: ti.f64,
                 fl0: ti.f64, fl1: ti.f64, fl2: ti.f64, fl3: ti.f64) -> ti.types.vector(6, ti.f64):
        h = ti.cast(0.0, ti.f64)
        u = ti.cast(0.0, ti.f64)
        v = ti.cast(0.0, ti.f64)
        if ti.static(kind == 1):
            h = QL[0]
            u = QL[1]
            v = QL[2]
        elif ti.static(kind == 2):
            u = fil / 3.0
            h = (u * u) / 9.81
            v = QL[2]
        elif ti.static(kind == 3):
            u = (fil + fir) / 2.0
            fil = fil - u
            h = (fil * fil) / 39.24
            v = QL[2]
        elif ti.static(kind == 5):
            u = (fil + fir) / 2.0
            fir = fir - u
            h = (fir * fir) / 39.24
            v = QR[2]
        elif ti.static(kind == 6):
            u = fir / 3.0
            h = (u * u) / 9.81
            v = QR[2]
        else:
            h = QR[0]
            u = QR[1]
            v = QR[2]

        flr = qf_accum(fl0, fl1, fl2, fl3, sign, h, u, v)
        return ti.Vector([fil, fir, flr[0], flr[1], flr[2], flr[3]])

    @ti.func
    def osher(QL: ti.types.vector(3, ti.f64),
              QR: ti.types.vector(3, ti.f64),
              FIL_in: ti.f64, H_pos: ti.f64) -> ti.types.vector(4, ti.f64):
        CR = ti.sqrt(G * QR[0])
        FIR_v = QR[1] - 2.0 * CR
        UA = (FIL_in + FIR_v) / 2.0
        CA = ti.abs((FIL_in - FIR_v) / 4.0)
        CL_v = ti.sqrt(G * H_pos)

        fl0 = ti.cast(0.0, ti.f64)
        fl1 = ti.cast(0.0, ti.f64)
        fl2 = ti.cast(0.0, ti.f64)
        fl3 = ti.cast(0.0, ti.f64)
        K2 = 0
        if CA < UA:
            K2 = 1
        elif UA >= 0.0 and UA < CA:
            K2 = 2
        elif UA >= -CA and UA < 0.0:
            K2 = 3
        else:
            K2 = 4

        K1 = 0
        if QL[1] < CL_v and QR[1] >= -CR:
            K1 = 1
        elif QL[1] >= CL_v and QR[1] >= -CR:
            K1 = 2
        elif QL[1] < CL_v and QR[1] < -CR:
            K1 = 3
        else:
            K1 = 4

        fil = FIL_in
        fir = FIR_v

        if K1 == 1:
            if K2 == 1:
                state = qs_accum(2, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            elif K2 == 2:
                state = qs_accum(3, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            elif K2 == 3:
                state = qs_accum(5, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            else:
                state = qs_accum(6, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
        elif K1 == 2:
            if K2 == 1:
                state = qs_accum(1, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            elif K2 == 2:
                state = qs_accum(1, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(2, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(3, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            elif K2 == 3:
                state = qs_accum(1, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(2, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(5, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            else:
                state = qs_accum(1, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(2, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(6, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
        elif K1 == 3:
            if K2 == 1:
                state = qs_accum(2, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(6, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(7, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            elif K2 == 2:
                state = qs_accum(3, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(6, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(7, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            elif K2 == 3:
                state = qs_accum(5, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(6, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(7, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            else:
                state = qs_accum(7, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
        else:  # K1 == 4
            if K2 == 1:
                state = qs_accum(1, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(6, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(7, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            elif K2 == 2:
                state = qs_accum(1, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(2, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(3, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(6, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(7, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            elif K2 == 3:
                state = qs_accum(1, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(2, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(5, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(6, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(7, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
            else:
                state = qs_accum(1, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(2, -1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
                state = qs_accum(7, 1, QL, QR, fil, fir, fl0, fl1, fl2, fl3)
                fil = state[0]; fir = state[1]; fl0 = state[2]; fl1 = state[3]; fl2 = state[4]; fl3 = state[5]
        return ti.Vector([fl0, fl1, fl2, fl3])

    @ti.func
    def bounda_klas1(H_pre: ti.f64, QL_u: ti.f64, QL_v: ti.f64,
                     pos: ti.i32, jt: ti.i32) -> ti.types.vector(4, ti.f64):
        """CalculateKlas1: water level boundary (iterative Riemann solver)."""
        HB1 = ZT[jt * CELL + pos] + DZT[jt * CELL + pos] * ti.cast(jt, ti.f64) - ZBC[pos]
        HB1 = ti.max(HB1, HM2)
        FIAL = QL_u + 6.264 * ti.sqrt(H_pre)
        UR0 = QL_u
        URB = UR0
        for _ in range(30):
            FIAR = URB - 6.264 * ti.sqrt(HB1)
            URB = (FIAL + FIAR) * (FIAL - FIAR) * (FIAL - FIAR) / HB1 / 313.92
            if ti.abs(URB - UR0) <= 0.0001:
                break
            UR0 = URB
        f0 = HB1 * URB
        f1 = f0 * URB
        f2 = ti.cast(0.0, ti.f64)
        f3 = half_g_h2(HB1)
        return ti.Vector([f0, f1, f2, f3])

    @ti.func
    def bounda_klas10(H_pre: ti.f64, FIL: ti.f64, pos: ti.i32, idx: ti.i32,
                      kt: ti.i32, jt: ti.i32) -> ti.types.vector(4, ti.f64):
        """CalculateKlas10: discharge boundary (iterative HB solver).
        Mirrors functors.cu:163-191 — two-step FLUX0 assignment + real break."""
        flux0 = -(QT[jt * CELL + pos] + DQT[jt * CELL + pos] * ti.cast(kt, ti.f64))
        flux0 = flux0 / SIDE[idx]
        QB2 = flux0 * flux0
        HB0 = H_pre
        HB = ti.cast(0.0, ti.f64)
        for _ in range(20):
            W_temp = FIL - flux0 / HB0
            HB = W_temp * W_temp / 39.24
            if ti.abs(HB0 - HB) <= 0.005:
                break
            HB0 = HB0 * 0.5 + HB * 0.5
        f1 = ti.cast(0.0, ti.f64)
        if HB > 1.0:
            f1 = QB2 / HB
        f3 = half_g_h2(HB)
        return ti.Vector([flux0, f1, ti.cast(0.0, ti.f64), f3])

    @ti.func
    def copysign_native(x: ti.f64, sign: ti.f64) -> ti.f64:
        return ti.select(sign < 0.0, -ti.abs(x), ti.abs(x))

    @ti.func
    def qd_native(ZL: ti.f64, ZR: ti.f64, ZB: ti.f64) -> ti.f64:
        ZU = ti.max(ZL, ZR)
        ZD = ti.min(ZL, ZR)
        H0 = ZU - ZB
        HS = ZD - ZB
        DELTA = HS / H0
        out = ti.cast(0.0, ti.f64)
        if DELTA <= 0.667:
            out = copysign_native(0.384 * ti.pow(H0, ti.cast(1.5, ti.f64)), ZL - ZR)
        else:
            DH = ZU - ZD
            if DH > 0.09:
                out = copysign_native(4.43 * HS * ti.sqrt(DH), ZL - ZR)
            else:
                out = copysign_native(4.43 * HS * 0.3 * DH / 0.1, ZL - ZR)
        return out

    @ti.func
    def laqp_native(X: ti.f64, pos: ti.i32, MS: ti.i32) -> ti.f64:
        base = pos * NHQ
        Y = ti.cast(0.0, ti.f64)
        if MS > 0:
            if X < QW[base]:
                Y = ZW[base]
            elif X > QW[base + MS - 1]:
                Y = ZW[base + MS - 1]
            else:
                found = False
                for i in ti.static(range(max(NHQ - 1, 1))):
                    if i < MS - 1 and not found:
                        a0 = QW[base + i]
                        a1 = QW[base + i + 1]
                        if X >= a0 and X <= a1:
                            b0 = ZW[base + i]
                            b1 = ZW[base + i + 1]
                            Y = b0 + (b1 - b0) / (a1 - a0) * (X - a0)
                            found = True
        return Y

    @ti.func
    def bounda_klas3(H_pre: ti.f64, U_pre: ti.f64, V_pre: ti.f64,
                     Z_pre: ti.f64, QL_u: ti.f64, QL_v: ti.f64,
                     pos: ti.i32, idx: ti.i32) -> ti.types.vector(3, ti.f64):
        cos_val = COSF[idx]
        sin_val = SINF[idx]
        side_val = SIDE[idx]
        QZH3 = (U_pre * cos_val + V_pre * sin_val) * H_pre * side_val
        QZH3 = ti.max(QZH3, ti.cast(0.0, ti.f64))

        ZQH1 = laqp_native(QZH3, pos, NHQ1[pos])
        ZQH11 = ZQH1 - Z_pre
        HB1 = ZQH1 - ZBC[pos]
        HB1 = ti.max(HB1, HM2)
        ql_u = ti.max(QL_u, ti.cast(0.0, ti.f64))

        f0 = ti.cast(0.0, ti.f64)
        f1 = ti.cast(0.0, ti.f64)
        f3 = ti.cast(0.0, ti.f64)
        if QZH3 <= QW[pos * NHQ + 1] or HB1 <= HM2 or ZQH11 >= 0.1:
            f0 = H_pre * ql_u
            f1 = f0 * ql_u
            f3 = half_g_h2(H_pre)
        else:
            FIAL = ql_u + 6.264 * ti.sqrt(H_pre)
            UR0 = ql_u
            URB = UR0
            for _ in range(30):
                FIAR = URB - 6.264 * ti.sqrt(HB1)
                URB = (FIAL + FIAR) * (FIAL - FIAR) * (FIAL - FIAR) / HB1 / 313.92
                if ti.abs(URB - UR0) <= 0.001:
                    break
                UR0 = URB
            f0 = HB1 * URB
            f1 = f0 * URB
            f3 = half_g_h2(HB1)
        return ti.Vector([f0, f1, f3])

    @ti.func
    def bounda_klas6(H_pre: ti.f64, Z_pre: ti.f64, ZC: ti.f64,
                     UC: ti.f64, VC: ti.f64, QL_u: ti.f64, QL_v: ti.f64,
                     pos: ti.i32, idx: ti.i32) -> ti.types.vector(4, ti.f64):
        TOP = BoundaryFeature[pos]
        zbc = ZBC[pos]
        f0 = ti.cast(0.0, ti.f64)
        f1 = ti.cast(0.0, ti.f64)
        f2 = ti.cast(0.0, ti.f64)
        f3 = ti.cast(0.0, ti.f64)
        if Z_pre <= TOP and ZC <= TOP:
            f3 = half_g_h2(H_pre)
        elif Z_pre > TOP and ZC <= TOP:
            f0 = C0 * ti.pow(Z_pre - TOP, ti.cast(1.5, ti.f64))
            f1 = f0 * QL_u
            f2 = f0 * QL_v
            f3 = 4.905 * ti.pow(TOP - zbc, ti.cast(2.0, ti.f64))
        elif Z_pre <= TOP and ZC > TOP:
            f0 = -C0 * ti.pow(ZC - TOP, ti.cast(1.5, ti.f64))
            f1 = f0 * ti.min(UC * COSF[idx] + VC * SINF[idx], ti.cast(0.0, ti.f64))
            f2 = f0 * (VC * COSF[idx] - UC * SINF[idx])
            f3 = 4.905 * ti.pow(Z_pre - zbc, ti.cast(2.0, ti.f64))
        elif Z_pre > TOP and ZC > TOP:
            DZ = ti.abs(Z_pre - ZC)
            HD = ti.cast(0.0, ti.f64)
            UN = ti.cast(0.0, ti.f64)
            VT = ti.cast(0.0, ti.f64)
            SH = ti.cast(0.0, ti.f64)
            CE = ti.cast(0.0, ti.f64)
            if Z_pre <= ZC:
                HD = Z_pre - TOP
                UN = ti.min(UC * COSF[idx] + VC * SINF[idx], ti.cast(0.0, ti.f64))
                VT = VC * COSF[idx] - UC * SINF[idx]
                SH = HD + DZ
                CE = ti.min(ti.cast(1.0, ti.f64), 1.05 * ti.pow(DZ / SH, ti.cast(0.33333, ti.f64)))
                if Z_pre < ZC and UN > 0.0:
                    UN = 0.0
                f0 = copysign_native(CE * C1 * ti.pow(SH, ti.cast(1.5, ti.f64)), Z_pre - ZC)
                f1 = f0 * ti.abs(UN)
                f2 = f0 * VT
                f3 = 4.905 * ti.pow(TOP - zbc, ti.cast(2.0, ti.f64))
            else:
                HD = ZC - TOP
                UN = ti.max(QL_u, ti.cast(0.0, ti.f64))
                VT = QL_v
                SH = HD + DZ
                CE = ti.min(ti.cast(1.0, ti.f64), 1.05 * ti.pow(DZ / SH, ti.cast(0.33333, ti.f64)))
                f0 = copysign_native(CE * C1 * ti.pow(SH, ti.cast(1.5, ti.f64)), Z_pre - ZC)
                f1 = (Z_pre - ZC) * ti.abs(UN) * UN
                f2 = (Z_pre - ZC) * ti.abs(UN) * VT
                f3 = 4.905 * ti.pow(TOP - zbc, ti.cast(2.0, ti.f64))
        return ti.Vector([f0, f1, f2, f3])

    @ti.func
    def bounda_klas7(H_pre: ti.f64, Z_pre: ti.f64, ZC: ti.f64,
                     HB: ti.f64, pos: ti.i32, idx: ti.i32) -> ti.types.vector(4, ti.f64):
        TOP = BoundaryFeature[pos]
        f0 = ti.cast(0.0, ti.f64)
        f1 = ti.cast(0.0, ti.f64)
        f2 = ti.cast(0.0, ti.f64)
        f3 = ti.cast(0.0, ti.f64)
        if Z_pre > TOP or ZC > TOP:
            KLAS[idx] = 0.0
            CQ = qd_native(Z_pre, ZC, TOP)
            CB = BRDTH / SIDE[idx]
            f0 = CQ * CB
            f1 = CB * copysign_native(CQ * CQ / HB, CQ)
            f3 = half_g_h2(HB)
        else:
            f3 = half_g_h2(H_pre)
        return ti.Vector([f0, f1, f2, f3])

    # ------------------------------------------------------------------
    # Kernel 1: CalculateFluxKernel — 1 thread per edge
    # ------------------------------------------------------------------
    @ti.kernel
    def calculate_flux(kt: ti.i32, jt: ti.i32):
        for idx in range(NE):
            cell_i = idx // 4
            KP = ti.cast(KLAS[idx], ti.i32)
            NC_raw = NAC[idx]
            NC = NC_raw - 1  # convert 1-indexed to 0-indexed; -1 means no neighbor

            H1 = H[cell_i]
            U1 = U[cell_i]
            V1 = V[cell_i]
            BI = ZBC[cell_i]
            ZI = ti.max(Z[cell_i], ZB1[cell_i])

            COSJ = COSF[idx]
            SINJ = SINF[idx]

            QL = ti.Vector([H1, U1 * COSJ + V1 * SINJ, V1 * COSJ - U1 * SINJ])
            CL_v = ti.sqrt(G * H1)
            FIL_v = QL[1] + 2.0 * CL_v
            HC = ti.cast(0.0, ti.f64)
            BC = ti.cast(0.0, ti.f64)
            ZC = ti.cast(0.0, ti.f64)
            UC = ti.cast(0.0, ti.f64)
            VC = ti.cast(0.0, ti.f64)
            if NC != -1:
                HC = ti.max(H[NC], HM1)
                BC = ZBC[NC]
                ZC = ti.max(BC, Z[NC])
                UC = U[NC]
                VC = V[NC]

            f0 = ti.cast(0.0, ti.f64)
            f1 = ti.cast(0.0, ti.f64)
            f2 = ti.cast(0.0, ti.f64)
            f3 = ti.cast(0.0, ti.f64)

            if (KP >= 1 and KP <= 8) or KP >= 10:
                # BOUNDA dispatch
                CL_b = ti.sqrt(G * H1)
                if QL[1] > CL_b and H1 < HM2:
                    # Supercritical outflow
                    f0 = H1 * QL[1]
                    f1 = f0 * QL[1]
                    f2 = f0 * QL[2]
                    f3 = half_g_h2(H1)
                else:
                    f2_b = ti.cast(0.0, ti.f64)
                    if QL[1] > 0.0:
                        f2_b = H1 * QL[1] * QL[2]
                    f2 = f2_b
                    HB = ti.cast(0.0, ti.f64)
                    if KP == 10:
                        result10 = bounda_klas10(H1, FIL_v, cell_i, idx, kt, jt)
                        f0 = result10[0]
                        f1 = result10[1]
                        f2 = result10[2]
                        f3 = result10[3]
                    elif KP == 3:
                        result3 = bounda_klas3(H1, U1, V1, Z[cell_i], QL[1], QL[2], cell_i, idx)
                        f0 = result3[0]
                        f1 = result3[1]
                        f3 = result3[2]
                    elif KP == 1:
                        result1 = bounda_klas1(H1, QL[1], QL[2], cell_i, jt)
                        f0 = result1[0]
                        f1 = result1[1]
                        f3 = result1[3]
                    elif KP == 4:
                        f0 = 0.0
                        f1 = 0.0
                        f2 = 0.0
                        f3 = half_g_h2(H1)
                    elif KP == 5:
                        ql_u = ti.max(QL[1], ti.cast(0.0, ti.f64))
                        f0 = H1 * ql_u
                        f1 = f0 * ql_u
                        f3 = half_g_h2(H1) * (1.0 - JL) * (1.0 - JL)
                    elif KP == 6:
                        result6 = bounda_klas6(H1, Z[cell_i], ZC, UC, VC, QL[1], QL[2], cell_i, idx)
                        f0 = result6[0]
                        f1 = result6[1]
                        f2 = result6[2]
                        f3 = result6[3]
                    elif KP == 7:
                        result7 = bounda_klas7(H1, Z[cell_i], ZC, HB, cell_i, idx)
                        f0 = result7[0]
                        f1 = result7[1]
                        f2 = result7[2]
                        f3 = result7[3]
            elif H1 <= HM1 and HC <= HM1:
                pass  # both dry
            elif ZI <= BC:
                f0 = -C1 * ti.pow(HC, ti.cast(1.5, ti.f64))
                f1 = H1 * QL[1] * ti.abs(QL[1])
                f3 = half_g_h2(H1)
            elif ZC <= BI:
                f0 = C1 * ti.pow(H1, ti.cast(1.5, ti.f64))
                f1 = H1 * ti.abs(QL[1]) * QL[1]
                f2 = H1 * ti.abs(QL[1]) * QL[2]
            elif H1 <= HM2:
                if ZC > ZI:
                    DH = ti.max(ZC - BI, HM1)
                    UN = -C1 * ti.sqrt(DH)
                    f0 = DH * UN
                    f1 = f0 * UN
                    f2 = f0 * (VC * COSJ - UC * SINJ)
                    f3 = half_g_h2(H1)
                else:
                    f0 = C1 * ti.pow(H1, ti.cast(1.5, ti.f64))
                    f3 = half_g_h2(H1)
            elif HC <= HM2:
                if ZI > ZC:
                    DH = ti.max(ZI - BC, HM1)
                    UN = C1 * ti.sqrt(DH)
                    HC1 = ZC - BI
                    f0 = DH * UN
                    f1 = f0 * UN
                    f2 = f0 * QL[2]
                    f3 = half_g_h2(HC1)
                else:
                    f0 = -C1 * ti.pow(HC, ti.cast(1.5, ti.f64))
                    f1 = H1 * QL[1] * QL[1]
                    f3 = half_g_h2(H1)
            else:
                # Both wet — Osher Riemann solver
                if KP == 0 and cell_i < NC:
                    QR_h = ti.max(ZC - BI, HM1)
                    UR = UC * COSJ + VC * SINJ
                    ratio = ti.min(HC / QR_h, ti.cast(1.5, ti.f64))
                    QR_u = UR * ratio
                    if HC <= HM2 or QR_h <= HM2:
                        QR_u = copysign_native(VMIN, UR)
                    QR_v_ = VC * COSJ - UC * SINJ
                    QR_vec = ti.Vector([QR_h, QR_u, QR_v_])
                    FLR_OS = osher(QL, QR_vec, FIL_v, H1)
                    f0 = FLR_OS[0]
                    f1 = FLR_OS[1] + (1.0 - ratio) * HC * UR * UR / 2.0
                    f2 = FLR_OS[2]
                    f3 = FLR_OS[3]
                else:
                    COSJ1 = -COSJ
                    SINJ1 = -SINJ
                    QL1 = ti.Vector([
                        H[NC],
                        U[NC] * COSJ1 + V[NC] * SINJ1,
                        V[NC] * COSJ1 - U[NC] * SINJ1,
                    ])
                    CL1 = ti.sqrt(G * H[NC])
                    FIL1 = QL1[1] + 2.0 * CL1
                    HC2 = ti.max(H1, HM1)
                    ZC1 = ti.max(BI, Z[cell_i])
                    QR1_h = ti.max(ZC1 - BC, HM1)
                    UR1 = U1 * COSJ1 + V1 * SINJ1
                    ratio1 = ti.min(HC2 / QR1_h, ti.cast(1.5, ti.f64))
                    QR1_u = UR1 * ratio1
                    if HC2 <= HM2 or QR1_h <= HM2:
                        QR1_u = copysign_native(VMIN, UR1)
                    QR1_v_ = V1 * COSJ1 - U1 * SINJ1
                    QR1_vec = ti.Vector([QR1_h, QR1_u, QR1_v_])
                    FLR1 = osher(QL1, QR1_vec, FIL1, H[NC])
                    f0 = -FLR1[0]
                    f1 = FLR1[1] + (1.0 - ratio1) * HC2 * UR1 * UR1 / 2.0
                    f2 = FLR1[2]
                    ZA = ti.sqrt(FLR1[3] / ti.cast(4.905, ti.f64)) + BC
                    HC3 = ti.max(ZA - BI, ti.cast(0.0, ti.f64))
                    f3 = half_g_h2(HC3)

            FLUX0[idx] = f0
            FLUX1[idx] = f1
            FLUX2[idx] = f2
            FLUX3[idx] = f3

    # ------------------------------------------------------------------
    # Kernel 2: UpdateCellKernel — 1 thread per cell
    # ------------------------------------------------------------------
    @ti.kernel
    def update_cell():
        for i in range(CELL):
            H1 = H[i]
            U1 = U[i]
            V1 = V[i]
            BI = ZBC[i]

            WH = ti.cast(0.0, ti.f64)
            WU = ti.cast(0.0, ti.f64)
            WV = ti.cast(0.0, ti.f64)

            for j in ti.static(range(4)):
                idx = 4 * i + j
                SL = SIDE[idx]
                SLCA = SLCOS[idx]
                SLSA = SLSIN[idx]
                FLR_1 = FLUX1[idx] + FLUX3[idx]
                FLR_2 = FLUX2[idx]
                WH += SL * FLUX0[idx]
                WU += SLCA * FLR_1 - SLSA * FLR_2
                WV += SLSA * FLR_1 + SLCA * FLR_2

            DTA = 1.0 * ti.cast(DT, ti.f64) / (1.0 * AREA[i])
            WDTA = 1.00 * DTA
            H2 = ti.max(H1 - WDTA * WH + QLUA, HM1)
            Z2 = H2 + BI

            U2 = ti.cast(0.0, ti.f64)
            V2 = ti.cast(0.0, ti.f64)
            if H2 > HM1:
                if H2 <= HM2:
                    U2 = copysign_native(ti.min(VMIN, ti.abs(U1)), U1)
                    V2 = copysign_native(ti.min(VMIN, ti.abs(V1)), V1)
                else:
                    QX1 = H1 * U1
                    QY1 = H1 * V1
                    DTAU = WDTA * WU
                    DTAV = WDTA * WV
                    WSF = FNC[i] * ti.sqrt(U1 * U1 + V1 * V1) / ti.pow(H1, ti.cast(0.33333, ti.f64))
                    U2 = (QX1 - DTAU - ti.cast(DT, ti.f64) * WSF * U1) / H2
                    V2 = (QY1 - DTAV - ti.cast(DT, ti.f64) * WSF * V1) / H2
                    U2 = copysign_native(ti.min(ti.abs(U2), ti.cast(15.0, ti.f64)), U2)
                    V2 = copysign_native(ti.min(ti.abs(V2), ti.cast(15.0, ti.f64)), V2)

            H[i] = H2
            U[i] = U2
            V[i] = V2
            Z[i] = Z2
            W[i] = ti.sqrt(U2 * U2 + V2 * V2)

    # ------------------------------------------------------------------
    # Step function
    # ------------------------------------------------------------------
    def step_fn(on_step=None):
        """Run the configured number of steps.

        on_step: optional callable invoked as ``on_step(step_index)`` after
            each step has been synced. The first completed step has
            index 1. When omitted (default), the loop runs without
            yielding control, preserving the existing all-at-once behavior.
        """
        step = 0
        day_limit = mesh["NDAYS"] if steps is not None else min(days, mesh["NDAYS"])
        for day in range(day_limit):
            for kt in range(1, steps_per_day):
                if step >= total_steps:
                    return
                calculate_flux(kt, day)
                update_cell()
                step += 1
                if on_step is not None:
                    ti.sync()
                    on_step(step)

    def sync_fn():
        ti.sync()

    # Warm-compile
    calculate_flux(0, 0)
    update_cell()
    ti.sync()
    # Reload initial state after warm-compile
    H.from_numpy(mesh["H"])
    U.from_numpy(mesh["U"])
    V.from_numpy(mesh["V"])
    Z.from_numpy(mesh["Z"])
    W.from_numpy(mesh["W"])
    FLUX0.fill(0)
    FLUX1.fill(0)
    FLUX2.fill(0)
    FLUX3.fill(0)

    return step_fn, sync_fn, H, U, V, Z, FLUX0, FLUX1, FLUX2, FLUX3


if __name__ == "__main__":
    import time
    days = 10
    result = run(days=days, backend="cuda")
    step_fn, sync_fn, H_field = result[:3]
    sync_fn()
    t0 = time.perf_counter()
    step_fn()
    sync_fn()
    t1 = time.perf_counter()
    elapsed = (t1 - t0) * 1000
    print(f"{days} days: {elapsed:.1f} ms  ({elapsed/days:.2f} ms/day)")
    h = H_field.to_numpy()
    print(f"H range: [{h.min():.6f}, {h.max():.6f}]")
