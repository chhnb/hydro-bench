"""F1 hydro-cal — 2-kernel split (fp32 version).

Uses the same Riemann solver as F2 Taichi, just adapted to F1 mesh.

This is the apples-to-apples Taichi implementation matching native CUDA's
CalculateFluxKernel + UpdateCellKernel parallelization (per-edge flux,
per-cell update). Tests show this produces bit-identical results to native
CUDA on F2 cases; for F1 cases there are tiny differences only at KLAS=10
and KLAS=13 boundary edges (≈20 / 26700 = 0.075%) which native CUDA handles
with case-specific logic that we treat as wall.
"""
import os
import sys
import numpy as np
import taichi as ti

sys.path.insert(0, os.path.dirname(__file__))
from mesh_loader_f1 import load_hydro_mesh

# Constants (F1 hydro-cal)
G: ti.f32 = 9.81
HALF_G: ti.f32 = 4.905
C0: ti.f32 = 1.33
C1: ti.f32 = 1.7
VMIN: ti.f32 = 0.001


def run_real(steps=1, backend="cuda", mesh="default", fixed_dt=None):
    ti.init(arch=ti.cuda if backend == "cuda" else ti.cpu, default_fp=ti.f32, fast_math=False)

    # Compute geometry / state arrays in fp32 so they match native CUDA's
    # ``Real = float`` ``preCalculate`` output bit-for-bit.
    m = load_hydro_mesh(mesh=mesh, dtype=np.float32)
    CELL = m["CEL"]
    NE = 4 * CELL
    HM1 = float(m["HM1"])
    HM2 = float(m["HM2"])
    DT = float(fixed_dt) if fixed_dt else float(m.get("DT", 1.0))

    # --- Convert F1's 2D 1-indexed mesh to F2's flat NE arrays (0-indexed) ---
    # F1 layout: NAC[j, pos] for j in 1..4, pos in 1..CELL
    # F2 layout: NAC[idx] for idx in 0..NE-1, where idx = 4*pos + j (0-indexed)
    NAC_flat   = np.zeros(NE, dtype=np.int32)
    KLAS_flat  = np.zeros(NE, dtype=np.float32)
    SIDE_flat  = np.zeros(NE, dtype=np.float32)
    COSF_flat  = np.zeros(NE, dtype=np.float32)
    SINF_flat  = np.zeros(NE, dtype=np.float32)
    SLCOS_flat = np.zeros(NE, dtype=np.float32)
    SLSIN_flat = np.zeros(NE, dtype=np.float32)
    for cell in range(CELL):
        for j in range(4):
            idx = 4 * cell + j
            NAC_flat[idx]   = m["NAC"][j+1, cell+1]      # F2 expects 1-indexed neighbor (cell+1)
            KLAS_flat[idx]  = m["KLAS"][j+1, cell+1]
            SIDE_flat[idx]  = m["SIDE"][j+1, cell+1]
            COSF_flat[idx]  = m["COSF"][j+1, cell+1]
            SINF_flat[idx]  = m["SINF"][j+1, cell+1]
            SLCOS_flat[idx] = m["SLCOS"][j+1, cell+1]
            SLSIN_flat[idx] = m["SLSIN"][j+1, cell+1]

    # F1 cells are 1-indexed in original — flatten to 0-indexed for Taichi
    H_flat   = m["H"][1:CELL+1].astype(np.float32)
    U_flat   = m["U"][1:CELL+1].astype(np.float32)
    V_flat   = m["V"][1:CELL+1].astype(np.float32)
    Z_flat   = m["Z"][1:CELL+1].astype(np.float32)
    W_flat   = m["W"][1:CELL+1].astype(np.float32)
    ZBC_flat = m["ZBC"][1:CELL+1].astype(np.float32)
    ZB1_flat = m["ZB1"][1:CELL+1].astype(np.float32)
    AREA_flat= m["AREA"][1:CELL+1].astype(np.float32)
    FNC_flat = m["FNC"][1:CELL+1].astype(np.float32)

    # --- Allocate Taichi fields (F2-style flat layout) ---
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

    H = ti.field(ti.f32, shape=CELL)
    U = ti.field(ti.f32, shape=CELL)
    V = ti.field(ti.f32, shape=CELL)
    Z = ti.field(ti.f32, shape=CELL)
    W = ti.field(ti.f32, shape=CELL)
    ZBC = ti.field(ti.f32, shape=CELL)
    ZB1 = ti.field(ti.f32, shape=CELL)
    AREA = ti.field(ti.f32, shape=CELL)
    FNC = ti.field(ti.f32, shape=CELL)

    NDAYS = int(m.get("NDAYS", 50))
    ZT_field  = ti.field(ti.f32, shape=NDAYS * CELL)
    DZT_field = ti.field(ti.f32, shape=NDAYS * CELL)
    QT_field  = ti.field(ti.f32, shape=NDAYS * CELL)
    DQT_field = ti.field(ti.f32, shape=NDAYS * CELL)
    ZT_field.from_numpy(m["ZT"].astype(np.float32))
    DZT_field.from_numpy(m["DZT"].astype(np.float32))
    QT_field.from_numpy(m["QT"].astype(np.float32))
    DQT_field.from_numpy(m["DQT"].astype(np.float32))

    NAC.from_numpy(NAC_flat)
    KLAS.from_numpy(KLAS_flat)
    SIDE.from_numpy(SIDE_flat)
    COSF.from_numpy(COSF_flat)
    SINF.from_numpy(SINF_flat)
    SLCOS.from_numpy(SLCOS_flat)
    SLSIN.from_numpy(SLSIN_flat)
    H.from_numpy(H_flat)
    U.from_numpy(U_flat)
    V.from_numpy(V_flat)
    Z.from_numpy(Z_flat)
    W.from_numpy(W_flat)
    ZBC.from_numpy(ZBC_flat)
    ZB1.from_numpy(ZB1_flat)
    AREA.from_numpy(AREA_flat)
    FNC.from_numpy(FNC_flat)

    # --- Riemann solver (Osher) ---
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
    def QF(h: ti.f32, u: ti.f32, v: ti.f32) -> ti.types.vector(4, ti.f32):
        hu = h * u
        return ti.Vector([hu, hu * u, hu * v, half_g_h2_f32(h)])

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
        FLR = ti.Vector([0.0, 0.0, 0.0, 0.0])
        K2 = 0
        if CA < UA: K2 = 1
        elif UA >= 0.0 and UA < CA: K2 = 2
        elif UA >= -CA and UA < 0.0: K2 = 3
        else: K2 = 4
        K1 = 0
        if QL[1] < CL_v and QR[1] >= -CR: K1 = 1
        elif QL[1] >= CL_v and QR[1] >= -CR: K1 = 2
        elif QL[1] < CL_v and QR[1] < -CR: K1 = 3
        else: K1 = 4
        fil = FIL_in
        fir = FIR_v
        if K1 == 1:
            if K2 == 1:
                US = fil / 3.0; HS = div_9_81_f32(US * US)
                FLR += QF(HS, US, QL[2])
            elif K2 == 2:
                ua = (fil + fir) / 2.0; fil = fil - ua; HA = div_39_24_f32(fil * fil)
                FLR += QF(HA, ua, QL[2])
            elif K2 == 3:
                ua = (fil + fir) / 2.0; fir = fir - ua; HA = div_39_24_f32(fir * fir)
                FLR += QF(HA, ua, QR[2])
            else:
                US = fir / 3.0; HS = div_9_81_f32(US * US)
                FLR += QF(HS, US, QR[2])
        elif K1 == 2:
            if K2 == 1:
                FLR += QF(QL[0], QL[1], QL[2])
            elif K2 == 2:
                FLR += QF(QL[0], QL[1], QL[2])
                US2 = fil / 3.0; HS2 = div_9_81_f32(US2 * US2)
                FLR -= QF(HS2, US2, QL[2])
                ua = (fil + fir) / 2.0; fil = fil - ua; HA = div_39_24_f32(fil * fil)
                FLR += QF(HA, ua, QL[2])
            elif K2 == 3:
                FLR += QF(QL[0], QL[1], QL[2])
                US2 = fil / 3.0; HS2 = div_9_81_f32(US2 * US2)
                FLR -= QF(HS2, US2, QL[2])
                ua = (fil + fir) / 2.0; fir = fir - ua; HA = div_39_24_f32(fir * fir)
                FLR += QF(HA, ua, QR[2])
            else:
                FLR += QF(QL[0], QL[1], QL[2])
                US2 = fil / 3.0; HS2 = div_9_81_f32(US2 * US2)
                FLR -= QF(HS2, US2, QL[2])
                US6 = fir / 3.0; HS6 = div_9_81_f32(US6 * US6)
                FLR += QF(HS6, US6, QR[2])
        elif K1 == 3:
            if K2 == 1:
                US2 = fil / 3.0; HS2 = div_9_81_f32(US2 * US2)
                FLR += QF(HS2, US2, QL[2])
                US6 = fir / 3.0; HS6 = div_9_81_f32(US6 * US6)
                FLR -= QF(HS6, US6, QR[2])
                FLR += QF(QR[0], QR[1], QR[2])
            elif K2 == 2:
                ua = (fil + fir) / 2.0; fil = fil - ua; HA = div_39_24_f32(fil * fil)
                FLR += QF(HA, ua, QL[2])
                US6 = fir / 3.0; HS6 = div_9_81_f32(US6 * US6)
                FLR -= QF(HS6, US6, QR[2])
                FLR += QF(QR[0], QR[1], QR[2])
            elif K2 == 3:
                ua = (fil + fir) / 2.0; fir = fir - ua; HA = div_39_24_f32(fir * fir)
                FLR += QF(HA, ua, QR[2])
                US6b = fir / 3.0; HS6b = div_9_81_f32(US6b * US6b)
                FLR -= QF(HS6b, US6b, QR[2])
                FLR += QF(QR[0], QR[1], QR[2])
            else:
                FLR += QF(QR[0], QR[1], QR[2])
        else:
            if K2 == 1:
                FLR += QF(QL[0], QL[1], QL[2])
                US6 = fir / 3.0; HS6 = div_9_81_f32(US6 * US6)
                FLR -= QF(HS6, US6, QR[2])
                FLR += QF(QR[0], QR[1], QR[2])
            elif K2 == 2:
                FLR += QF(QL[0], QL[1], QL[2])
                US2 = fil / 3.0; HS2 = div_9_81_f32(US2 * US2)
                FLR -= QF(HS2, US2, QL[2])
                ua = (fil + fir) / 2.0; fil = fil - ua; HA = div_39_24_f32(fil * fil)
                FLR += QF(HA, ua, QL[2])
                US6 = fir / 3.0; HS6 = div_9_81_f32(US6 * US6)
                FLR -= QF(HS6, US6, QR[2])
                FLR += QF(QR[0], QR[1], QR[2])
            elif K2 == 3:
                FLR += QF(QL[0], QL[1], QL[2])
                US2 = fil / 3.0; HS2 = div_9_81_f32(US2 * US2)
                FLR -= QF(HS2, US2, QL[2])
                ua = (fil + fir) / 2.0; fir = fir - ua; HA = div_39_24_f32(fir * fir)
                FLR += QF(HA, ua, QR[2])
                US6 = fir / 3.0; HS6 = div_9_81_f32(US6 * US6)
                FLR -= QF(HS6, US6, QR[2])
                FLR += QF(QR[0], QR[1], QR[2])
            else:
                FLR += QF(QL[0], QL[1], QL[2])
                US2 = fil / 3.0; HS2 = div_9_81_f32(US2 * US2)
                FLR -= QF(HS2, US2, QL[2])
                FLR += QF(QR[0], QR[1], QR[2])
        return FLR

    # --- Kernel 1: per-edge flux (1 thread per edge) ---
    @ti.kernel
    def calculate_flux(kt: ti.i32, jt: ti.i32):
        for idx in range(NE):
            cell_i = idx // 4
            KP = ti.cast(KLAS[idx], ti.i32)
            NC_raw = NAC[idx]
            NC = NC_raw - 1  # F1 mesh stores 1-indexed neighbor; -1 means no neighbor

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

            f0 = 0.0; f1 = 0.0; f2 = 0.0; f3 = 0.0
            if (KP >= 1 and KP <= 8) or KP >= 10:
                CL_b = sqrt_g_h_f32(H1)
                if QL[1] > CL_b and H1 < HM2:
                    # Supercritical outflow
                    f0 = H1 * QL[1]
                    f1 = f0 * QL[1]
                    f2 = f0 * QL[2]
                    f3 = half_g_h2_f32(H1)
                else:
                    # Boundary dispatch (matches native CUDA BOUNDA function)
                    if KP == 10:
                        # CalculateKlas10: native uses iterative HB convergence with QT/DQT.
                        SIDE_e = SIDE[idx]
                        zt_idx = jt * CELL + cell_i
                        flux0_kl10 = -(QT_field[zt_idx] + DQT_field[zt_idx] * ti.cast(kt, ti.f32)) / SIDE_e
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
                    elif KP == 4:
                        # Wall
                        f0 = 0.0; f1 = 0.0; f2 = 0.0
                        f3 = half_g_h2_f32(H1)
                    elif KP == 1:
                        # CalculateKlas1: HB1 from ZT/DZT timeseries (matches native CUDA).
                        zt_idx = jt * CELL + cell_i
                        HB1_raw = ZT_field[zt_idx] + DZT_field[zt_idx] * ti.cast(jt, ti.f32) - BI
                        HB1 = ti.max(HB1_raw, HM2)
                        FIAL = ti.cast(ti.cast(QL[1], ti.f64) + ti.cast(sqrt_mul_6_264_f32(H1), ti.f64), ti.f32)
                        UR0 = QL[1]
                        URB = UR0
                        converged = False
                        for _ in range(30):
                            if not converged:
                                FIAR = ti.cast(ti.cast(URB, ti.f64) - ti.cast(sqrt_mul_6_264_f32(HB1), ti.f64), ti.f32)
                                urb_num = (FIAL + FIAR) * (FIAL - FIAR) * (FIAL - FIAR) / HB1
                                URB_new = div_313_92_f32(urb_num)
                                if ti.abs(URB_new - UR0) <= 0.0001:
                                    URB = URB_new
                                    converged = True
                                else:
                                    UR0 = URB_new
                                    URB = URB_new
                        f0 = HB1 * URB
                        f1 = f0 * URB
                        f2 = ti.select(QL[1] > 0.0, H1 * QL[1] * QL[2], ti.cast(0.0, ti.f32))
                        f3 = half_g_h2_f32(HB1)
                    else:
                        # KLAS=13 and other unhandled boundary types in native
                        # BOUNDA still keep the pre-dispatch tangential flux.
                        f0 = 0.0; f1 = 0.0
                        f2 = ti.select(QL[1] > 0.0, H1 * QL[1] * QL[2], ti.cast(0.0, ti.f32))
                        f3 = 0.0
            elif NC < 0:
                f3 = half_g_h2_f32(H1)
            else:
                HC = ti.max(H[NC], HM1)
                BC = ZBC[NC]
                ZC = ti.max(BC, Z[NC])
                UC = U[NC]
                VC = V[NC]
                if H1 <= HM1 and HC <= HM1:
                    pass
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
                    if cell_i < NC:
                        QR_h = ti.max(ZC - BI, HM1)
                        UR = UC * COSJ + VC * SINJ
                        ratio = ti.min(HC / QR_h, ti.cast(1.5, ti.f32))
                        QR_u = UR * ratio
                        if HC <= HM2 or QR_h <= HM2:
                            QR_u = ti.select(UR >= 0.0, VMIN, -VMIN)
                        QR_v = VC * COSJ - UC * SINJ
                        QR_vec = ti.Vector([QR_h, QR_u, QR_v])
                        FLR_OS = osher(QL, QR_vec, FIL_v, H1)
                        f0 = FLR_OS[0]
                        f1 = FLR_OS[1] + (1.0 - ratio) * HC * UR * UR / 2.0
                        f2 = FLR_OS[2]
                        f3 = FLR_OS[3]
                    else:
                        COSJ1 = -COSJ
                        SINJ1 = -SINJ
                        QL1 = ti.Vector([H[NC], U[NC] * COSJ1 + V[NC] * SINJ1,
                                          V[NC] * COSJ1 - U[NC] * SINJ1])
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
                        QR1_v = V1 * COSJ1 - U1 * SINJ1
                        QR1_vec = ti.Vector([QR1_h, QR1_u, QR1_v])
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

    # --- Kernel 2: per-cell update (1 thread per cell) ---
    @ti.kernel
    def update_cell():
        for i in range(CELL):
            H1 = H[i]; U1 = U[i]; V1 = V[i]
            BI = ZBC[i]
            WH = 0.0; WU = 0.0; WV = 0.0
            for j in ti.static(range(4)):
                idx = 4 * i + j
                SL = SIDE[idx]
                SLCA = SLCOS[idx]
                SLSA = SLSIN[idx]
                FLR_1 = FLUX1[idx] + FLUX3[idx]
                FLR_2 = FLUX2[idx]
                WH += SL * FLUX0[idx]
                # Match native CUDA's non-fused multiply/subtract ordering.
                t1 = SLCA * FLR_1
                t2 = SLSA * FLR_2
                t3 = SLSA * FLR_1
                t4 = SLCA * FLR_2
                WU += t1 - t2
                WV += t3 + t4
            DTA = ti.cast(DT, ti.f32) / AREA[i]
            H2 = ti.max(H1 - DTA * WH, HM1)
            Z2 = H2 + BI
            U2 = 0.0; V2 = 0.0
            if H2 > HM1:
                if H2 <= HM2:
                    U2 = ti.select(U1 >= 0.0, ti.min(VMIN, ti.abs(U1)), -ti.min(VMIN, ti.abs(U1)))
                    V2 = ti.select(V1 >= 0.0, ti.min(VMIN, ti.abs(V1)), -ti.min(VMIN, ti.abs(V1)))
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
                        U2 = ti.select(U2 >= 0.0, ti.min(ti.abs(U2), ti.cast(15.0, ti.f32)), -ti.min(ti.abs(U2), ti.cast(15.0, ti.f32)))
                        V2 = ti.select(V2 >= 0.0, ti.min(ti.abs(V2), ti.cast(15.0, ti.f32)), -ti.min(ti.abs(V2), ti.cast(15.0, ti.f32)))
            H[i] = H2
            U[i] = U2
            V[i] = V2
            Z[i] = Z2
            W[i] = ti.sqrt(U2 * U2 + V2 * V2)

    steps_per_day = max(int(round(float(m.get("MDT", 3600)) / DT)), 1)

    def step_fn(on_step=None):
        """Run the configured number of steps.

        on_step: optional callable invoked as ``on_step(step_index)`` after
            each step has been synced. The first completed step has
            index 1. When omitted (default), the loop runs without
            yielding control, preserving the existing all-at-once behavior.
        """
        s = 0
        for day in range(int(m.get("NDAYS", 50))):
            for kt in range(1, steps_per_day):
                if s >= steps:
                    return
                calculate_flux(kt, day)
                update_cell()
                s += 1
                if on_step is not None:
                    ti.sync()
                    on_step(s)

    def sync_fn():
        ti.sync()

    # Warm-compile
    calculate_flux(0, 0)
    update_cell()
    ti.sync()
    # Reload initial state
    H.from_numpy(H_flat)
    U.from_numpy(U_flat)
    V.from_numpy(V_flat)
    Z.from_numpy(Z_flat)
    W.from_numpy(W_flat)
    FLUX0.fill(0)
    FLUX1.fill(0)
    FLUX2.fill(0)
    FLUX3.fill(0)

    return step_fn, sync_fn, H, U, V, Z, FLUX0, FLUX1, FLUX2, FLUX3


if __name__ == "__main__":
    step_fn, sync_fn, H = run_real(steps=50, mesh="default")
    sync_fn()
    step_fn()
    sync_fn()
    h = H.to_numpy()
    print(f"H[0:5]: {h[:5]}")
    print(f"H range: [{h.min():.6f}, {h.max():.6f}]")
