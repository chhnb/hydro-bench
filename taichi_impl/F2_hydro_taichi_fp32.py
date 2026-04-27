"""F2: Refactored Hydro-Cal — Taichi (fp32, edge-parallel flux + cell-parallel update).

Two-kernel design matching the refactored CUDA kernel:
  1. CalculateFluxKernel: 1 thread per edge (4*CELL), computes flux per edge
  2. UpdateCellKernel:    1 thread per cell (CELL),   accumulates fluxes, updates state
"""
import os
import sys
import numpy as np
import taichi as ti

sys.path.insert(0, os.path.dirname(__file__))
from mesh_loader_f2 import load_mesh

# ---------------------------------------------------------------------------
# Constants (fp32)
# ---------------------------------------------------------------------------
G: ti.f32 = 9.81
HALF_G: ti.f32 = 4.905
C0: ti.f32 = 1.33
C1: ti.f32 = 1.7
VMIN: ti.f32 = 0.001
QLUA: ti.f32 = 0.0
BRDTH: ti.f32 = 100.0


def run(days=10, backend="cuda", mesh="default", steps=None):
    ti.init(arch=ti.cuda if backend == "cuda" else ti.cpu, default_fp=ti.f32, fast_math=False)
    mesh_data = load_mesh(mesh=mesh)
    mesh = mesh_data

    CELL = mesh["CELL"]
    NE = 4 * CELL
    HM1 = float(mesh["HM1"])
    HM2 = float(mesh["HM2"])
    DT = float(mesh["DT"])
    steps_per_day = mesh["steps_per_day"]
    steps_in_day = max(steps_per_day - 1, 1)
    total_steps = steps if steps is not None else steps_in_day * days

    # --- Fields: edges [4*CELL] ---
    NAC   = ti.field(ti.i32, shape=NE)
    KLAS  = ti.field(ti.f32, shape=NE)
    SIDE  = ti.field(ti.f32, shape=NE)
    COSF  = ti.field(ti.f32, shape=NE)
    SINF  = ti.field(ti.f32, shape=NE)
    SLCOS = ti.field(ti.f32, shape=NE)
    SLSIN = ti.field(ti.f32, shape=NE)
    FLUX0 = ti.field(ti.f32, shape=NE)
    FLUX1 = ti.field(ti.f32, shape=NE)
    FLUX2 = ti.field(ti.f32, shape=NE)
    FLUX3 = ti.field(ti.f32, shape=NE)

    # --- Fields: cells [CELL] ---
    H    = ti.field(ti.f32, shape=CELL)
    U    = ti.field(ti.f32, shape=CELL)
    V    = ti.field(ti.f32, shape=CELL)
    Z    = ti.field(ti.f32, shape=CELL)
    W    = ti.field(ti.f32, shape=CELL)
    ZBC  = ti.field(ti.f32, shape=CELL)
    ZB1  = ti.field(ti.f32, shape=CELL)
    AREA = ti.field(ti.f32, shape=CELL)
    FNC  = ti.field(ti.f32, shape=CELL)

    # --- Fields: boundary data [NDAYS*CELL] ---
    NDAYS = mesh["NDAYS"]
    ZT  = ti.field(ti.f32, shape=NDAYS * CELL)
    DZT = ti.field(ti.f32, shape=NDAYS * CELL)
    QT  = ti.field(ti.f32, shape=NDAYS * CELL)
    DQT = ti.field(ti.f32, shape=NDAYS * CELL)

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
    ZT.from_numpy(mesh["ZT"])
    DZT.from_numpy(mesh["DZT"])
    QT.from_numpy(mesh["QT"])
    DQT.from_numpy(mesh["DQT"])

    # ------------------------------------------------------------------
    # Taichi functions
    # ------------------------------------------------------------------
    @ti.func
    def f64_ratio(num: ti.template(), den: ti.template()) -> ti.f64:
        return ti.cast(num, ti.f64) / ti.cast(den, ti.f64)

    @ti.func
    def half_g_h2_f32(h: ti.f32) -> ti.f32:
        return ti.cast(f64_ratio(4905, 1000) * ti.cast(h, ti.f64) * ti.cast(h, ti.f64), ti.f32)

    @ti.func
    def sqrt_g_h_f32(h: ti.f32) -> ti.f32:
        return ti.sqrt(ti.cast(f64_ratio(981, 100) * ti.cast(h, ti.f64), ti.f32))

    @ti.func
    def div_9_81_f32(x: ti.f32) -> ti.f32:
        return ti.cast(ti.cast(x, ti.f64) / f64_ratio(981, 100), ti.f32)

    @ti.func
    def div_39_24_f32(x: ti.f32) -> ti.f32:
        return ti.cast(ti.cast(x, ti.f64) / f64_ratio(3924, 100), ti.f32)

    @ti.func
    def sqrt_div_4_905_f32(x: ti.f32) -> ti.f32:
        return ti.sqrt(ti.cast(ti.cast(x, ti.f64) / f64_ratio(4905, 1000), ti.f32))

    @ti.func
    def sqrt_mul_6_264_f32(h: ti.f32) -> ti.f32:
        return ti.cast(f64_ratio(6264, 1000) * ti.cast(ti.sqrt(h), ti.f64), ti.f32)

    @ti.func
    def div_313_92_f32(x: ti.f32) -> ti.f32:
        return ti.cast(ti.cast(x, ti.f64) / f64_ratio(31392, 100), ti.f32)

    @ti.func
    def rn_f32(x: ti.f32) -> ti.f32:
        return ti.bit_cast(ti.bit_cast(x, ti.i32), ti.f32)

    @ti.func
    def qf_accum(fl0: ti.f32, fl1: ti.f32, fl2: ti.f32, fl3: ti.f32,
                 sign: ti.template(), h: ti.f32, u: ti.f32, v: ti.f32) -> ti.types.vector(4, ti.f32):
        q0 = h * u
        q1 = q0 * u
        q2 = q0 * v
        q3 = half_g_h2_f32(h)
        s = ti.cast(sign, ti.f32)
        fl0 = fl0 + q0 * s
        fl1 = fl1 + q1 * s
        fl2 = fl2 + q2 * s
        fl3 = fl3 + q3 * s
        return ti.Vector([fl0, fl1, fl2, fl3])

    @ti.func
    def qs_accum(kind: ti.template(), sign: ti.template(),
                 QL: ti.types.vector(3, ti.f32), QR: ti.types.vector(3, ti.f32),
                 fil: ti.f32, fir: ti.f32,
                 fl0: ti.f32, fl1: ti.f32, fl2: ti.f32, fl3: ti.f32) -> ti.types.vector(6, ti.f32):
        h = ti.cast(0.0, ti.f32)
        u = ti.cast(0.0, ti.f32)
        v = ti.cast(0.0, ti.f32)
        if ti.static(kind == 1):
            h = QL[0]
            u = QL[1]
            v = QL[2]
        elif ti.static(kind == 2):
            u = fil / 3.0
            h = div_9_81_f32(u * u)
            v = QL[2]
        elif ti.static(kind == 3):
            u = (fil + fir) / 2.0
            fil = fil - u
            h = div_39_24_f32(fil * fil)
            v = QL[2]
        elif ti.static(kind == 5):
            u = (fil + fir) / 2.0
            fir = fir - u
            h = div_39_24_f32(fir * fir)
            v = QR[2]
        elif ti.static(kind == 6):
            u = fir / 3.0
            h = div_9_81_f32(u * u)
            v = QR[2]
        else:
            h = QR[0]
            u = QR[1]
            v = QR[2]

        flr = qf_accum(fl0, fl1, fl2, fl3, sign, h, u, v)
        return ti.Vector([fil, fir, flr[0], flr[1], flr[2], flr[3]])

    @ti.func
    def native_mul_pow_f32(c: ti.f32, x: ti.f32, p: ti.f64) -> ti.f32:
        return ti.cast(ti.cast(c, ti.f64) * ti.pow(ti.cast(x, ti.f64), p), ti.f32)

    @ti.func
    def osher(QL: ti.types.vector(3, ti.f32),
              QR: ti.types.vector(3, ti.f32),
              FIL_in: ti.f32, H_pos: ti.f32) -> ti.types.vector(4, ti.f32):
        CR = sqrt_g_h_f32(QR[0])
        FIR_v = QR[1] - 2.0 * CR
        UA = (FIL_in + FIR_v) / 2.0
        CA = ti.abs((FIL_in - FIR_v) / 4.0)
        CL_v = sqrt_g_h_f32(H_pos)

        fl0 = ti.cast(0.0, ti.f32)
        fl1 = ti.cast(0.0, ti.f32)
        fl2 = ti.cast(0.0, ti.f32)
        fl3 = ti.cast(0.0, ti.f32)
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
    def bounda_klas1(H_pre: ti.f32, QL_u: ti.f32, QL_v: ti.f32,
                     pos: ti.i32, jt: ti.i32) -> ti.types.vector(4, ti.f32):
        """CalculateKlas1: water level boundary (iterative Riemann solver)."""
        HB1 = ZT[jt * CELL + pos] + DZT[jt * CELL + pos] * ti.cast(jt, ti.f32) - ZBC[pos]
        HB1 = ti.max(HB1, HM2)
        FIAL = ti.cast(ti.cast(QL_u, ti.f64) + ti.cast(sqrt_mul_6_264_f32(H_pre), ti.f64), ti.f32)
        UR0 = QL_u
        URB = UR0
        for _ in range(30):
            FIAR = ti.cast(ti.cast(URB, ti.f64) - ti.cast(sqrt_mul_6_264_f32(HB1), ti.f64), ti.f32)
            urb_num = (FIAL + FIAR) * (FIAL - FIAR) * (FIAL - FIAR) / HB1
            URB = div_313_92_f32(urb_num)
            if ti.abs(URB - UR0) <= 0.0001:
                break
            UR0 = URB
        f0 = HB1 * URB
        f1 = f0 * URB
        f2 = ti.cast(0.0, ti.f32)
        f3 = half_g_h2_f32(HB1)
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
            ZI = ti.max(Z[cell_i], BI)

            COSJ = COSF[idx]
            SINJ = SINF[idx]

            QL = ti.Vector([H1, U1 * COSJ + V1 * SINJ, V1 * COSJ - U1 * SINJ])
            CL_v = sqrt_g_h_f32(H1)
            FIL_v = QL[1] + 2.0 * CL_v

            f0 = ti.cast(0.0, ti.f32)
            f1 = ti.cast(0.0, ti.f32)
            f2 = ti.cast(0.0, ti.f32)
            f3 = ti.cast(0.0, ti.f32)

            if (KP >= 1 and KP <= 8) or KP >= 10:
                # BOUNDA dispatch
                CL_b = sqrt_g_h_f32(H1)
                if QL[1] > CL_b and H1 < HM2:
                    # Supercritical outflow
                    f0 = H1 * QL[1]
                    f1 = f0 * QL[1]
                    f2 = f0 * QL[2]
                    f3 = half_g_h2_f32(H1)
                else:
                    f2_b = ti.cast(0.0, ti.f32)
                    if QL[1] > 0.0:
                        f2_b = H1 * QL[1] * QL[2]
                    if KP == 1:
                        result = bounda_klas1(H1, QL[1], QL[2], cell_i, jt)
                        f0 = result[0]
                        f1 = result[1]
                        f2 = f2_b
                        f3 = result[3]
                    elif KP == 4:
                        f0 = 0.0; f1 = 0.0; f2 = 0.0
                        f3 = half_g_h2_f32(H1)
                    elif KP == 10:
                        # CalculateKlas10: iterative HB convergence with QT/DQT.
                        SIDE_e = SIDE[idx]
                        FIL_v = QL[1] + 2.0 * sqrt_g_h_f32(H1)
                        flux0_kl10 = -(QT[jt * CELL + cell_i] + DQT[jt * CELL + cell_i] * ti.cast(kt, ti.f32)) / SIDE_e
                        QB2 = flux0_kl10 * flux0_kl10
                        HB0 = H1
                        HB = ti.cast(0.0, ti.f32)
                        converged_k10 = False
                        for _ in range(20):
                            if not converged_k10:
                                W_temp = FIL_v - flux0_kl10 / HB0
                                HB = div_39_24_f32(W_temp * W_temp)
                                if ti.abs(HB0 - HB) <= 0.005:
                                    converged_k10 = True
                                else:
                                    HB0 = HB0 * 0.5 + HB * 0.5
                        f0 = flux0_kl10
                        f1 = ti.select(HB <= 1.0, ti.cast(0.0, ti.f32), QB2 / HB)
                        f2 = 0.0
                        f3 = half_g_h2_f32(HB)
                    else:
                        # Other boundary types — treat as wall
                        f0 = 0.0; f1 = 0.0; f2 = 0.0
                        f3 = half_g_h2_f32(H1)
            elif NC < 0:
                # No neighbor (shouldn't happen for KP==0, but safety)
                f3 = half_g_h2_f32(H1)
            else:
                # Interior edge (KP == 0)
                HC = ti.max(H[NC], HM1)
                BC = ZBC[NC]
                ZC = ti.max(BC, Z[NC])
                UC = U[NC]
                VC = V[NC]

                if H1 <= HM1 and HC <= HM1:
                    pass  # both dry
                elif ZI <= BC:
                    f0 = -native_mul_pow_f32(C1, HC, 1.5)
                    f1 = H1 * QL[1] * ti.abs(QL[1])
                    f3 = half_g_h2_f32(H1)
                elif ZC <= BI:
                    f0 = native_mul_pow_f32(C1, H1, 1.5)
                    f1 = H1 * ti.abs(QL[1]) * QL[1]
                    f2 = H1 * ti.abs(QL[1]) * QL[2]
                elif H1 <= HM2:
                    if ZC > ZI:
                        DH = ti.max(ZC - BI, HM1)
                        UN = -C1 * ti.sqrt(DH)
                        f0 = DH * UN
                        f1 = f0 * UN
                        f2 = f0 * (VC * COSJ - UC * SINJ)
                        f3 = half_g_h2_f32(H1)
                    else:
                        f0 = native_mul_pow_f32(C1, H1, 1.5)
                        f3 = half_g_h2_f32(H1)
                elif HC <= HM2:
                    if ZI > ZC:
                        DH = ti.max(ZI - BC, HM1)
                        UN = C1 * ti.sqrt(DH)
                        HC1 = ZC - BI
                        f0 = DH * UN
                        f1 = f0 * UN
                        f2 = f0 * QL[2]
                        f3 = half_g_h2_f32(HC1)
                    else:
                        f0 = -native_mul_pow_f32(C1, HC, 1.5)
                        f1 = H1 * QL[1] * QL[1]
                        f3 = half_g_h2_f32(H1)
                else:
                    # Both wet — Osher Riemann solver
                    if cell_i < NC:
                        QR_h = ti.max(ZC - BI, HM1)
                        UR = UC * COSJ + VC * SINJ
                        ratio = ti.min(HC / QR_h, ti.cast(1.5, ti.f32))
                        QR_u = UR * ratio
                        if HC <= HM2 or QR_h <= HM2:
                            QR_u = ti.select(UR >= 0.0, VMIN, -VMIN)
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
                        CL1 = sqrt_g_h_f32(H[NC])
                        FIL1 = QL1[1] + 2.0 * CL1
                        HC2 = ti.max(H1, HM1)
                        ZC1 = ti.max(BI, ZI)
                        QR1_h = ti.max(ZC1 - BC, HM1)
                        UR1 = U1 * COSJ1 + V1 * SINJ1
                        ratio1 = ti.min(HC2 / QR1_h, ti.cast(1.5, ti.f32))
                        QR1_u = UR1 * ratio1
                        if HC2 <= HM2 or QR1_h <= HM2:
                            QR1_u = ti.select(UR1 >= 0.0, VMIN, -VMIN)
                        QR1_v_ = V1 * COSJ1 - U1 * SINJ1
                        QR1_vec = ti.Vector([QR1_h, QR1_u, QR1_v_])
                        FLR1 = osher(QL1, QR1_vec, FIL1, H[NC])
                        f0 = -FLR1[0]
                        f1 = FLR1[1] + (1.0 - ratio1) * HC2 * UR1 * UR1 / 2.0
                        f2 = FLR1[2]
                        ZA = sqrt_div_4_905_f32(FLR1[3]) + BC
                        HC3 = ti.max(ZA - BI, ti.cast(0.0, ti.f32))
                        f3 = half_g_h2_f32(HC3)

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

            WH = ti.cast(0.0, ti.f32)
            WU = ti.cast(0.0, ti.f32)
            WV = ti.cast(0.0, ti.f32)

            for j in ti.static(range(4)):
                idx = 4 * i + j
                SL = SIDE[idx]
                SLCA = SLCOS[idx]
                SLSA = SLSIN[idx]
                FLR_1 = FLUX1[idx] + FLUX3[idx]
                FLR_2 = FLUX2[idx]
                rhs_h = SL * FLUX0[idx]
                # Match native CUDA's non-fused multiply/subtract ordering as closely as Taichi allows.
                t1 = SLCA * FLR_1
                t2 = SLSA * FLR_2
                t3 = SLSA * FLR_1
                t4 = SLCA * FLR_2
                rhs_u = t1 - t2
                rhs_v = t3 + t4
                WH = WH + rhs_h
                WU = WU + rhs_u
                WV = WV + rhs_v

            DTA = ti.cast(DT, ti.f32) / AREA[i]
            DTAH = rn_f32(DTA * WH)
            H2 = ti.max(rn_f32(H1 - DTAH), HM1)
            Z2 = H2 + BI

            U2 = ti.cast(0.0, ti.f32)
            V2 = ti.cast(0.0, ti.f32)
            if H2 > HM1:
                if H2 <= HM2:
                    U2 = ti.select(U1 >= 0.0,
                                   ti.min(VMIN, ti.abs(U1)),
                                   -ti.min(VMIN, ti.abs(U1)))
                    V2 = ti.select(V1 >= 0.0,
                                   ti.min(VMIN, ti.abs(V1)),
                                   -ti.min(VMIN, ti.abs(V1)))
                else:
                    QX1 = H1 * U1
                    QY1 = H1 * V1
                    DTAU = DTA * WU
                    DTAV = DTA * WV
                    WSF_num = FNC[i] * ti.sqrt(U1 * U1 + V1 * V1)
                    WSF = ti.cast(ti.cast(WSF_num, ti.f64) / ti.pow(ti.cast(H1, ti.f64), f64_ratio(33333, 100000)), ti.f32)
                    U2 = (QX1 - DTAU - ti.cast(DT, ti.f32) * WSF * U1) / H2
                    V2 = (QY1 - DTAV - ti.cast(DT, ti.f32) * WSF * V1) / H2
                    if H2 > HM2:
                        U2 = ti.select(U2 >= 0.0,
                                       ti.min(ti.abs(U2), ti.cast(15.0, ti.f32)),
                                       -ti.min(ti.abs(U2), ti.cast(15.0, ti.f32)))
                        V2 = ti.select(V2 >= 0.0,
                                       ti.min(ti.abs(V2), ti.cast(15.0, ti.f32)),
                                       -ti.min(ti.abs(V2), ti.cast(15.0, ti.f32)))

            H[i] = H2
            U[i] = U2
            V[i] = V2
            Z[i] = Z2
            W[i] = ti.sqrt(U2 * U2 + V2 * V2)

    # ------------------------------------------------------------------
    # Step function
    # ------------------------------------------------------------------
    def step_fn():
        step = 0
        day_limit = mesh["NDAYS"] if steps is not None else min(days, mesh["NDAYS"])
        for day in range(day_limit):
            for kt in range(1, steps_per_day):
                if step >= total_steps:
                    return
                calculate_flux(kt, day)
                update_cell()
                step += 1

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
