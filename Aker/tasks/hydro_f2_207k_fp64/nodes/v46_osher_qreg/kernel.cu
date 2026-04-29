#include "functors.cuh"
#include <cuda_runtime.h>
#include <cstdio>


__global__ void dummyIntKernel(int n) {
    if (threadIdx.x==0 && blockIdx.x==0) printf("device dummyIntKernel n=%d\n", n);
}
__global__ void dummyPtrKernel(const Real* p) {
    if (threadIdx.x==0 && blockIdx.x==0) printf("device dummyPtrKernel p=%p\n", (void*)p);
}
__global__ void dummyCellViewKernel(CellView c) {
    if (threadIdx.x==0 && blockIdx.x==0) {
        printf("device dummyCellViewKernel H=%p QW=%p H[1]=%f\n", (void*)c.H, (void*)c.QW, c.H[1]);
    }
}
__global__ void dummyMeshViewKernel(MeshView m) {
    if (threadIdx.x==0 && blockIdx.x==0) {
        printf("device dummyMeshViewKernel CELL=%d H=%p QW=%p\n", m.CELL, (void*)m.cells.H, (void*)m.cells.QW);
    }
}


// 在 host 中按顺序调用并打印返回值
void RunLaunchTests(const MeshView& mesh) {
    // 清除旧错误
    cudaGetLastError();

    dummyIntKernel<<<1,1>>>(123);
    printf("dummyInt launch err=%s\n", cudaGetErrorString(cudaGetLastError()));
    cudaDeviceSynchronize();

    dummyPtrKernel<<<1,1>>>(mesh.cells.H);
    printf("dummyPtr launch err=%s\n", cudaGetErrorString(cudaGetLastError()));
    cudaDeviceSynchronize();

    dummyCellViewKernel<<<1,1>>>(mesh.cells);
    printf("dummyCellView launch err=%s\n", cudaGetErrorString(cudaGetLastError()));
    cudaDeviceSynchronize();

    dummyMeshViewKernel<<<1,1>>>(mesh);
    printf("dummyMeshView launch err=%s\n", cudaGetErrorString(cudaGetLastError()));
    cudaDeviceSynchronize();
}

__device__ __forceinline__
void BOUNDA(MeshView& mesh, SideView& sides, CellView& cells, int kt, int jt, int pos, int idx, Real KP, Real CL, Real H_pre, Real U_pre, Real V_pre, Real Z_pre, Real ZC, Real UC, Real VC, Real FIL, Real (&QL)[3]);

__global__
void CalculateFluxKernel(MeshView d_mesh, int kt, int jt){

    MeshView& mesh = d_mesh;
    CellView& cells = mesh.cells;
    SideView& sides = mesh.sides;

    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    // 边界检查
    if (idx < 0 || idx >= mesh.CELL * 4) return;

    // 边对应的单元格索引
    int pos = idx / 4;     
    if (pos < 0 || pos >= mesh.CELL) return; 

    // printf("kt: %d, pos: %d, idx: %d\n", kt, pos, idx);

    // Cell 属性：上一时间步的 Cell 迭代结果
    Real U1 = cells.U[pos];
    Real V1 = cells.V[pos];
    Real H1 = cells.H[pos];
    Real Z1 = cells.Z[pos];
    Real v_ZB1 = cells.ZB1[pos];

    // printf("kt: %d, pos: %d, U1: %f, V1: %f, H1: %f, Z1: %f, v_ZB1: %f\n", kt, pos, U1, V1, H1, Z1, v_ZB1);
    // if(kt == 1 && pos < 100)
    //     printf("pos: %d, U1: %f, V1: %f, H1: %f, Z1: %f, v_ZB1: %f\n", pos, U1, V1, H1, Z1, v_ZB1);
    
    // Side 属性
    int NC = sides.NAC[idx] - 1;
    Real KP = sides.KLAS[idx];
    Real COSJ = sides.COSF[idx];
    Real SINJ = sides.SINF[idx];

    // 通量数组
    Real QL[3];
    Real QL1[3];
    Real QR[3];
    Real QR1[3];
    Real FLR_OSHER[4];

    QL[0] = H1;
    QL[1] = U1 * COSJ + V1 * SINJ;
    QL[2] = V1 * COSJ - U1 * SINJ;
    Real CL = sqrt(9.81 * H1);  
    Real FIL = QL[1] + 2 * CL;
    Real HN, HC, BC, ZC, UC, VC;
    Real ZI = fmax(Z1, v_ZB1);

    // 邻接 Cell 属性
    if (NC == -1){
        HN = 0; HC = 0; BC = 0; ZC = 0; UC = 0; VC = 0;
    }else{
        HN = cells.H[NC];
        HC = fmax(HN, mesh.HM1);
        BC = cells.ZBC[NC];
        ZC = fmax(BC, cells.Z[NC]);
        UC = cells.U[NC];
        VC = cells.V[NC];
    }

    // 特殊边界
    if ((KP >= 1 && KP <= 8) || KP >= 10)
    {
        BOUNDA(mesh, sides, cells, kt, jt, pos, idx, KP, CL, H1, U1, V1, Z1, ZC, UC, VC, FIL, QL);
    }
    else if (H1 <= mesh.HM1 && HC <= mesh.HM1)
    {
        FLUX_VAL(0, 0, 0, 0);
    }
    else if (ZI <= BC)
    {
        FLUX_VAL(-modelConstants::C1 * pow(HC, 1.5), H1 * QL[1] * fabs(QL[1]), 0, 4.905 * H1 * H1);
    }
    else if (ZC <= cells.ZBC[pos])
    {
        FLUX_VAL(modelConstants::C1 * pow(H1, 1.5), H1 * fabs(QL[1]) * QL[1], H1 * fabs(QL[1]) * QL[2], 0);
    }
    else if (H1 <= mesh.HM2)
    {
        if (ZC > ZI) {
            Real DH = fmax(ZC - cells.ZBC[pos], mesh.HM1);
            Real UN = -modelConstants::C1 * sqrt(DH);
            FLUX_VAL(DH * UN, FLR(0) * UN, FLR(0) * (VC * COSJ - UC * SINJ), 4.905 * H1 * H1);
        }
        else {
            FLUX_VAL(modelConstants::C1 * pow(H1, 1.5), 0, 0, 4.905 * H1 * H1);
        }
    }
    else if (HC <= mesh.HM2)
    {
        if (ZI > ZC) {
            Real DH = fmax(ZI - BC, mesh.HM1);
            Real UN = modelConstants::C1 * sqrt(DH);
            Real HC1 = ZC - cells.ZBC[pos];
            FLUX_VAL(DH * UN, FLR(0) * UN, FLR(0) * QL[2], 4.905 * HC1 * HC1);
        }
        else {
            FLUX_VAL(-modelConstants::C1 * pow(HC, 1.5), H1 * QL[1] * QL[1], 0, 4.905 * H1 * H1);
        }
    }
    // 内部边界
    else    
    {
        if (KP == 0 && pos < NC) {
            QR[0] = fmax(ZC - cells.ZBC[pos], mesh.HM1);
            Real UR = UC * COSJ + VC * SINJ;
            Real depth_ratio = fmin(HC / QR[0], (Real)1.5);
            QR[1] = UR * depth_ratio;
            if (HC <= mesh.HM2 || QR[0] <= mesh.HM2) {
                QR[1] = copysign(modelConstants::VMIN, UR);
            }
            QR[2] = VC * COSJ - UC * SINJ;

            OSHER(pos, CL,  QL, QR, FIL, FLR_OSHER);

            FLR(1) = FLR_OSHER[1] + (1 - depth_ratio) * HC * UR * UR / 2;
            FLUX_VAL(FLR_OSHER[0], FLR(1), FLR_OSHER[2], FLR_OSHER[3]);
        }
        else {
            Real HC2 = fmax(H1, mesh.HM1);
            Real ZC1 = fmax(cells.ZBC[pos], Z1);
            Real COSJ1 = 0.0;
            Real SINJ1 = 0.0;
            Real CL1 = sqrt(9.81 * HN);
            
            COSJ1 = -COSJ;
            SINJ1 = -SINJ;

            QL1[0] = HN;
            QL1[1] = UC * COSJ1 + VC * SINJ1;
            QL1[2] = VC * COSJ1 - UC * SINJ1;
            Real FIL1 = QL1[1] + 2 * CL1;

            QR1[0] = fmax(ZC1 - BC, mesh.HM1);
            Real UR1 = U1 * COSJ1 + V1 * SINJ1;
            Real depth_ratio1 = fmin(HC2 / QR1[0], (Real)1.5);
            QR1[1] = UR1 * depth_ratio1;
            if (HC2 <= mesh.HM2 || QR1[0] <= mesh.HM2) {
                QR1[1] = copysign(modelConstants::VMIN, UR1);
            }
            QR1[2] = V1 * COSJ1 - U1 * SINJ1;
            
            // 注意：这里与 cuda 版本不同的是直接传递 H_pre[NC]
            OSHER(pos, CL1, QL1, QR1, FIL1, FLR_OSHER);

            FLR(1) = FLR_OSHER[1] + (1 - depth_ratio1) * HC2 * UR1 * UR1 / 2;
            FLR(0) = -FLR_OSHER[0];
            FLR(2) = FLR_OSHER[2];
            Real ZA = sqrt(FLR_OSHER[3] / 4.905) + BC;
            Real HC3 = 0;
            if (ZA > cells.ZBC[pos]) {
                HC3 = ZA - cells.ZBC[pos];
            }
            FLR(3) = 4.905*HC3 * HC3;
        }
    }
}

__device__ __forceinline__
void CalculateKlas10(MeshView& mesh, SideView& sides, CellView& cells, int kt, int jt, int idx, int pos, Real H_pre, Real FIL, Real& HB){
    //=============================  数据划分 ===========================
    // int pos_near = find_in_vec(MBQ, MBQ_LEN, pos + 1);
    // FLUX[0] = -(QT[pos_near][jt] + DQT[pos_near] * kt);
    Real flux0 = -(cells.QT[jt * mesh.CELL + pos] + cells.DQT[jt * mesh.CELL + pos] * kt);
    //===================================================================

    flux0 = flux0 / sides.SIDE[idx];
    sides.FLUX0[idx] = flux0;
    Real QB2 = flux0 * flux0;
    Real HB0 = H_pre;

    for (int K = 1; K <= 20; K++) {
        Real W_temp = FIL - flux0 / HB0;
        HB = W_temp * W_temp / 39.24;
        if (fabs(HB0 - HB) <= 0.005)
            break;
        HB0 = HB0 * 0.5 + HB * 0.5;
    }

    if (HB <= 1) {
        sides.FLUX1[idx] = 0;
    }
    else {
        sides.FLUX1[idx] = QB2 / HB;
    }
    sides.FLUX2[idx] = 0;
    sides.FLUX3[idx] = 4.905 * HB * HB;
}

__device__ __forceinline__
void CalculateKlas7(MeshView& mesh, SideView& sides, CellView& cells, int idx, int pos, Real H_pre, Real Z_pre, Real ZC, Real& HB){
    //=============================  数据划分 ===========================
    // int pos_near = find_in_vec(MDI, MDI_LEN, pos + 1);
    // float TOP = TOPD[pos_near];
    Real TOP = cells.BoundaryFeature[pos];
    //===================================================================
    if (Z_pre > TOP || ZC > TOP) {
        sides.KLAS[idx] = 0;
        Real CQ = QD(Z_pre, ZC, TOP);
        Real CB = modelConstants::BRDTH / sides.SIDE[idx];
        FLR(0) = CQ * CB;
        FLR(1) = CB * copysign(CQ * CQ / HB, CQ);
        FLR(3) = 4.905 * HB * HB;
        return;
    }
    else {
        FLR(0) = 0;
        FLR(1) = 0;
        FLR(2) = 0;
        FLR(3) = 4.905 * H_pre * H_pre;
    }
}

__device__ __forceinline__
void CalculataKlas6(MeshView& mesh, SideView& sides, CellView& cells, int idx, int pos, Real H_pre, Real Z_pre, Real ZC, Real UC, Real VC, Real (&QL)[3]){
    // =============================  数据划分 ===========================
    // int pos_near = find_in_vec(MBW, MBW_LEN, pos + 1);
    // float TOP = TOPW[pos_near];
    Real TOP = cells.BoundaryFeature[pos];
    Real ZBC = cells.ZBC[pos];
    // ===================================================================
    if (Z_pre <= TOP && ZC <= TOP) {
        FLR(0) = 0;
        FLR(1) = 0;
        FLR(2) = 0;
        FLR(3) = 4.905 * H_pre * H_pre;
    }
    else if (Z_pre > TOP && ZC <= TOP) {
        FLR(0) = modelConstants::C0 * pow(Z_pre - TOP, 1.5);
        FLR(1) = FLR(0) * QL[1];
        FLR(2) = FLR(0) * QL[2];
        FLR(3) = 4.905 * pow(TOP - ZBC, 2);
    }
    else if (Z_pre <= TOP && ZC > TOP) {
        FLR(0) = -modelConstants::C0 * pow(ZC - TOP, 1.5);
        FLR(1) = FLR(0) * fmin(UC * sides.COSF[idx] + VC * sides.SINF[idx], (Real)0.0);
        FLR(2) = FLR(0) * (VC * sides.COSF[idx] - UC * sides.SINF[idx]);
        FLR(3) = 4.905 * pow(Z_pre - ZBC, 2);
    }
    else if (Z_pre > TOP && ZC > TOP) {
        Real DZ = fabs(Z_pre - ZC);
        Real HD;
        Real UN;
        Real VT;
        Real SH;
        Real CE;
        if (Z_pre <= ZC) {
            HD = Z_pre - TOP;
            UN = fmin(UC * sides.COSF[idx] + VC * sides.SINF[idx], (Real)0.0);
            VT = VC * sides.COSF[idx] - UC * sides.SINF[idx];

            SH = HD + DZ;
            CE = fmin(1.0, 1.05 * pow(DZ / SH, 0.33333));
            if (Z_pre < ZC && UN > 0.0) {
                UN = 0.0;
            }
            FLR(0) = copysign(CE * modelConstants::C1 * pow(SH, 1.5), Z_pre - ZC);
            FLR(1) = FLR(0) * fabs(UN);
            FLR(2) = FLR(0) * VT;
            FLR(3) = 4.905 * pow(TOP - ZBC, 2);
        }
        else {
            HD = ZC - TOP;
            UN = fmax(QL[1], (Real)0.0);
            VT = QL[2];
            SH = HD + DZ;
            CE = fmin(1.0, 1.05 * pow(DZ / SH, 0.33333));
            FLR(0) = copysign(CE * modelConstants::C1 * pow(SH, 1.5), Z_pre - ZC);
            FLR(1) = (Z_pre - ZC) * fabs(UN) * UN;
            FLR(2) = (Z_pre - ZC) * fabs(UN) * VT;
            FLR(3) = 4.905 * pow(TOP - ZBC, 2);
        }
    }
}

__device__ __forceinline__
void CalculateKlas3(MeshView& mesh, SideView& sides, CellView& cells, int idx, int pos, Real H_pre, Real U_pre, Real V_pre, Real Z_pre, Real (&QL)[3]){
    Real ZQH1;
    Real QZH3;
    Real cos_val = sides.COSF[idx];
    Real sin_val = sides.SINF[idx];
    Real side_val = sides.SIDE[idx];
    QZH3 = (U_pre * cos_val + V_pre * sin_val) * H_pre * side_val;
    QZH3 = fmax(QZH3, (Real)0.0);


    //=============================  数据划分 ===========================
    // int pos_near = find_in_vec(MBZQ, MBZQ_LEN, pos + 1);
    // for (int i = 0; i < (int)NHQ1[pos_near]; i++) {
    //     WZ[i] = ZW[i][pos_near];
    //     WQ[i] = QW[i][pos_near];
    // }
    // LAQP(QZH3, ZQH1, WQ, WZ, (int)NHQ1[pos_near]);
    size_t row_offset = size_t(pos) * size_t(mesh.NHQ);
    const Real* QW_row = cells.QW + row_offset;
    const Real* ZW_row = cells.ZW + row_offset;
    LAQP(QZH3, ZQH1, QW_row, ZW_row, cells.NHQ1[pos]);
    //===================================================================

    Real ZQH11 = ZQH1 - Z_pre;
    Real HB1 = ZQH1 - cells.ZBC[pos];
    HB1 = fmax(HB1, mesh.HM2);

    if (QZH3 <= QW_row[1] || HB1 <= mesh.HM2 || ZQH11 >= 0.1) {
        QL[1] = fmax(QL[1], (Real)0.0);
        FLR(0) = H_pre * QL[1];
        FLR(1) = FLR(0) * QL[1];
        FLR(3) = 4.905 * H_pre * H_pre;
    }
    else {
        QL[1] = fmax(QL[1], (Real)0.0);
        Real FIAL = QL[1] + 6.264 * sqrt(H_pre);
        Real sqrt_HB1 = sqrt(HB1);
        Real UR0 = QL[1];
        Real URB = UR0;
        for (int IURB = 1; IURB <= 30; IURB++) {
            Real FIAR = URB - 6.264 * sqrt_HB1;
            URB = (FIAL + FIAR) * (FIAL - FIAR) * (FIAL - FIAR) / HB1 / 313.92;
            if (fabs(URB - UR0) <= 0.001)
                break;
            UR0 = URB;
        }
        FLR(0) = HB1 * URB;
        FLR(1) = FLR(0) * URB;
        FLR(3) = 4.905 * HB1 * HB1;
    }
}

__device__ __forceinline__
void CalculateKlas1(MeshView& mesh, SideView& sides, CellView& cells, int kt, int jt, int idx, int pos, Real H_pre, Real (&QL)[3]){
    //=============================  数据划分 ===========================
    // int pos_near = find_in_vec(MBZ, MBZ_LEN, pos + 1);
    // float HB1 = ZT[pos_near][jt] + DZT[pos_near] * t - ZBC[pos];
    // §6.3: Fortran Main.for:827 uses *KT not *jt.
    Real HB1 = cells.ZT[jt * mesh.CELL + pos] + cells.DZT[jt * mesh.CELL + pos] * kt - cells.ZBC[pos];
    //===================================================================
    HB1 = fmax(HB1, mesh.HM2);
    Real FIAL = QL[1] + 6.264 * sqrt(H_pre);
    Real sqrt_HB1 = sqrt(HB1);
    Real UR0 = QL[1];
    Real URB = UR0;
    for (int IURB = 1; IURB <= 30; IURB++) {
        Real FIAR = URB - 6.264 * sqrt_HB1;
        URB = (FIAL + FIAR) * (FIAL - FIAR) * (FIAL - FIAR) / HB1 / 313.92;
        if (fabs(URB - UR0) <= 0.0001)
            break;
        UR0 = URB;
    }
    FLR(0) = HB1 * URB;
    FLR(1) = FLR(0) * URB;
    FLR(3) = 4.905 * HB1 * HB1;
}

__device__ __forceinline__
Real QD(Real ZL, Real ZR, Real ZB){
    const Real CM = 0.384;
    const Real SIGMA = 0.667;
    const Real FI = 4.43;

    Real ZU = fmax(ZL, ZR);
    Real ZD = fmin(ZL, ZR);
    Real H0 = ZU - ZB;
    Real HS = ZD - ZB;
    Real DELTA = HS / H0;

    Real QD;

    if (DELTA <= SIGMA) {
        QD = copysign(CM * pow(H0, 1.5), ZL - ZR);
    }
    else {
        Real DH = ZU - ZD;
        if (DH > 0.09) {
            QD = copysign(FI * HS * sqrt(DH), ZL - ZR);
        }
        else {
            QD = copysign(FI * HS * 0.3 * DH / 0.1, ZL - ZR);
        }
    }
    return QD;
}

__device__ __forceinline__
void LAQP(Real X, Real& Y, ConstRealView1d A, ConstRealView1d B, int MS){
    if (MS <= 0) return;
    
    if (X < A[0]) {
        Y = B[0];
        return;
    }

    if (X > A[MS - 1]) {
        Y = B[MS - 1];
        return;
    }
    
    for (int i = 0; i < MS - 1; i++) {
        if (X >= A[i] && X <= A[i + 1]) {
            Y = B[i] + (B[i + 1] - B[i]) / (A[i + 1] - A[i]) * (X - A[i]);
            return;
        }
    }
}

template <int T>
__device__ __forceinline__
void QS(int j, int pos, const Real(&QL)[3], const Real(&QR)[3], Real& FIL, Real& FIR, Real(&FLUX_OSHER)[4]){
    
    Real F[4];
    
    if constexpr (T == 1) {
        QF(QL[0], QL[1], QL[2], F);
        for (int i = 0; i < 4; i++) {
            FLUX_OSHER[i] += F[i] * j;
        }
    }
    else if constexpr (T == 2) {
        Real US = FIL / 3;
        Real HS = US * US / 9.81;
        QF(HS, US, QL[2], F);
        for (int i = 0; i < 4; i++) {
            FLUX_OSHER[i] += F[i] * j;
        }
    }
    else if constexpr (T == 3) {
        Real UA = (FIL + FIR) / 2;
        FIL = FIL - UA; // 此处FIL已更新
        Real HA = FIL * FIL / 39.24;
        QF(HA, UA, QL[2], F);
        for (int i = 0; i < 4; i++) {
            FLUX_OSHER[i] += F[i] * j;
        }
    }
    else if constexpr (T == 4) {
        return;
    }
    else if constexpr (T == 5) {
        Real UA = (FIL + FIR) / 2;
        FIR = FIR - UA;
        Real HA = FIR * FIR / 39.24;
        QF(HA, UA, QR[2], F);
        for (int i = 0; i < 4; i++) {
            FLUX_OSHER[i] += F[i] * j;
        }
    }
    else if constexpr (T == 6) {
        Real US = FIR / 3;
        Real HS = US * US / 9.81;
        QF(HS, US, QR[2], F);
        for (int i = 0; i < 4; i++) {
            FLUX_OSHER[i] += F[i] * j;
        }
    }
    else if constexpr (T == 7) {
        QF(QR[0], QR[1], QR[2], F);
        for (int i = 0; i < 4; i++) {
            FLUX_OSHER[i] += F[i] * j;
        }
    }
    else {
        std::exit(1);
    }
}

__device__ __forceinline__
void QF(Real h, Real u, Real v, Real(&F)[4]){
    F[0] = h * u;
    F[1] = F[0] * u;
    F[2] = F[0] * v;
    F[3] = 4.905 * h * h;
}

__device__ __forceinline__
void BOUNDA(MeshView& mesh, SideView& sides, CellView& cells, int kt, int jt, int pos, int idx, Real KP, Real CL, Real H_pre, Real U_pre, Real V_pre, Real Z_pre, Real ZC, Real UC, Real VC, Real FIL, Real (&QL)[3]){
    
    // §6.11c: Fortran Main.for:718 uses just `QL(2).GT.CL`.
    if (QL[1] > CL)
    {
        Real flux0 = H_pre * QL[1];
        sides.FLUX0[idx] = flux0;
        sides.FLUX1[idx] = flux0 * QL[1];
        sides.FLUX2[idx] = flux0 * QL[2];
        sides.FLUX3[idx] = 4.905 * H_pre * H_pre;
    }
    else{
        Real HB;
        sides.FLUX2[idx] = 0; 
        
        if (QL[1] > 0){
            sides.FLUX2[idx] = H_pre * QL[1] * QL[2];
        }
        if (KP == 10)
        {
            CalculateKlas10(mesh, sides, cells, kt, jt, idx, pos, H_pre, FIL, HB);
        }
        else if (KP == 3)  
        {
            CalculateKlas3(mesh, sides, cells, idx, pos, H_pre, U_pre, V_pre, Z_pre, QL);
        }
        else if (KP == 1) 
        {
            CalculateKlas1(mesh, sides, cells, kt, jt, idx, pos, H_pre, QL);
        }
        else if (KP == 4)
        {
            FLR(0) = 0;
            FLR(1) = 0;
            FLR(2) = 0;
            FLR(3) = 4.905 * H_pre * H_pre;
        }
        else if (KP == 5)
        {
            QL[1] = fmax(QL[1], (Real)0.0);
            FLR(0) = H_pre * QL[1];
            FLR(1) = FLR(0) * QL[1];
            FLR(3) = 4.905 * H_pre * H_pre * (1.0 - mesh.JL) * (1.0 - mesh.JL);
        }
        else if (KP == 6)
        {
            CalculataKlas6(mesh, sides, cells, idx, pos, H_pre, Z_pre, ZC, UC, VC, QL);
        }
        else if (KP == 7)
        {
            CalculateKlas7(mesh, sides, cells, idx, pos, H_pre, Z_pre, ZC, HB);
        }
    }
    
}

__device__ __forceinline__
void OSHER(int pos, Real CL, Real(&QL)[3], Real(&QR)[3], Real& FIL, Real(&FLR_OSHER)[4]){

    Real CR = sqrt(9.81 * QR[0]);
    Real qr_normal = QR[1];
    Real FIR = qr_normal - 2 * CR;
    Real UA = (FIL + FIR) / 2;
    Real CA = fabs((FIL - FIR) / 4);

    FLR_OSHER[0] = 0;
    FLR_OSHER[1] = 0;
    FLR_OSHER[2] = 0;
    FLR_OSHER[3] = 0;

    int K1, K2;

    if (CA < UA) {
        K2 = 1;
    }
    else if (UA >= 0.0 && UA < CA) {
        K2 = 2;
    }
    else if (UA >= -CA && UA < 0.0) {
        K2 = 3;
    }
    else if (UA < -CA) {
        K2 = 4;
    }

    Real ql_normal = QL[1];

    if (ql_normal < CL && qr_normal >= -CR) {
        K1 = 1;
    }
    else if (ql_normal >= CL && qr_normal >= -CR) {
        K1 = 2;
    }
    else if (ql_normal < CL && qr_normal < -CR) {
        K1 = 3;
    }
    else if (ql_normal >= CL && qr_normal < -CR) {
        K1 = 4;
    }

    switch (K1) {
    case 1:
        switch (K2) {
        case 1:
            QS<2>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 2:
            QS<3>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 3:
            QS<5>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 4:
            QS<6>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        default:
            break;
        }
        break;
    case 2:
        switch (K2) {
        case 1:
            QS<1>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 2:
            QS<1>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<2>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<3>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 3:
            QS<1>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<2>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<5>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 4:
            QS<1>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<2>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<6>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        default:
            break;
        }
        break;
    case 3:
        switch (K2) {
        case 1:
            QS<2>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<6>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<7>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 2:
            QS<3>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<6>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<7>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 3:
            QS<5>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<6>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<7>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 4:
            QS<7>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        default:
            break;
        }
        break;
    case 4:
        switch (K2) {
        case 1:
            QS<1>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<6>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<7>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 2:
            QS<1>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<2>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<3>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<6>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<7>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 3:
            QS<1>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<2>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<5>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<6>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<7>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        case 4:
            QS<1>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<2>(-1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            QS<7>(1, pos, QL, QR, FIL, FIR, FLR_OSHER);
            break;
        default:
            break;
        }
        break;
    default:
        break;
    }
}

/**
 * @brief 更新单元格状态
 */
__global__
void UpdateCellKernel(MeshView d_mesh){

    MeshView& mesh = d_mesh;
    CellView& cells = mesh.cells;
    SideView& sides = mesh.sides;

    int pos = blockIdx.x * blockDim.x + threadIdx.x;

    // 边界检查
    if (pos < 0 || pos >= mesh.CELL) return;

    // 1. 计算 WH, WU, WV
    Real WH = 0.0, WU = 0.0, WV = 0.0;

    Real side_len[4];
    int side_base = 4 * pos;
    for (int idx = side_base; idx < side_base + 4; idx++) {
        Real FLR_1 = sides.FLUX1[idx] + sides.FLUX3[idx];
        Real FLR_2 = sides.FLUX2[idx];
        Real SL = sides.SIDE[idx];
        Real SLCA = sides.SLCOS[idx];
        Real SLSA = sides.SLSIN[idx];

        side_len[idx - side_base] = SL;

        WH += SL * sides.FLUX0[idx];
        WU += SLCA * FLR_1 - SLSA * FLR_2;
        WV += SLSA * FLR_1 + SLCA * FLR_2;
    }

    // 2. 更新 H W U V Z
    Real QX1, QY1, DTAU, DTAV, WSF;
    
    Real H1 = cells.H[pos];
    Real U1 = cells.U[pos];
    Real V1 = cells.V[pos];
    // §6.11b: per-cell adaptive CFL DT2 (Fortran Main.for:412-427).
    Real s0 = side_len[0];
    Real s1 = side_len[1];
    Real s2 = side_len[2];
    Real s3 = side_len[3];
    Real SIDEX;
    if (s3 > 0.0) {
        SIDEX = fmin(0.5 * (s0 + s2), 0.5 * (s1 + s3));
    } else {
        Real SIDES = 0.5 * (s0 + s1 + s2);
        SIDEX = sqrt((SIDES - s0) * (SIDES - s1) * (SIDES - s2) / SIDES);
    }
    Real HSIDE = fmax(H1, mesh.HM1);
    Real DT2 = SIDEX / (U1 + sqrt(9.81 * HSIDE));
    DT2 = fmin((Real)mesh.DT, DT2);
    DT2 = fmax(DT2, (Real)mesh.DT / (Real)10.0);
    Real DTA = DT2 / cells.AREA[pos];
    Real WDTA = 1.00 * DTA;

    Real H2, U2, V2, Z2, W2;
    H2 = fmax(H1 - WDTA * WH + modelConstants::QLUA, mesh.HM1);
    Z2 = H2 + cells.ZBC[pos];
    if (H2 <= mesh.HM1) {
        U2 = 0.0;
        V2 = 0.0;
    }
    else {
        if (H2 <= mesh.HM2) {
            U2 = copysign(fmin(modelConstants::VMIN, fabs(U1)), U1);
            V2 = copysign(fmin(modelConstants::VMIN, fabs(V1)), V1);
        }
        else {
            QX1 = H1 * U1;
            QY1 = H1 * V1;
            DTAU = WDTA * WU;
            DTAV = WDTA * WV;
            WSF = cells.FNC[pos] * sqrt(U1 * U1 + V1 * V1) / pow(H1, 0.33333);
            U2 = (QX1 - DTAU - mesh.DT * WSF * U1) / H2;
            V2 = (QY1 - DTAV - mesh.DT * WSF * V1) / H2;
            // §6.11a: Fortran Main.for:456-457 uses 5.0 m/s cap.
            U2 = copysign(fmin(fabs(U2), (Real)5.0), U2);
            V2 = copysign(fmin(fabs(V2), (Real)5.0), V2);
        }
    }
    W2 = sqrt(U2 * U2 + V2 * V2);
    
    cells.H[pos] = H2;
    cells.U[pos] = U2;
    cells.V[pos] = V2;
    cells.Z[pos] = Z2;
    cells.W[pos] = W2;        
}


void CalculateFlux(const MeshView& mesh, int kt, int jt, cudaStream_t stream) {
    int N = mesh.CELL * 4;
    int numBlocks = div_up(N, blockSize);
    CalculateFluxKernel<<<numBlocks, blockSize, 0, stream>>>(mesh, kt, jt);
    CUDA_CHECK(cudaGetLastError());
}

void UpdateCell(const MeshView& mesh, cudaStream_t stream) {
    int N = mesh.CELL;
    int numBlocks = div_up(N, blockSize);
    UpdateCellKernel<<<numBlocks, blockSize, 0, stream>>>(mesh);
    CUDA_CHECK(cudaGetLastError());
}


void CalculateFlux(const MeshView& mesh, int kt, int jt){    
    int N = mesh.CELL * 4;
    int numBlocks = div_up(N, blockSize);

    CalculateFluxKernel<<<numBlocks, blockSize >>>(mesh, kt, jt);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());
}

void UpdateCell(const MeshView& mesh){
    int N = mesh.CELL;
    int numBlocks = div_up(N, blockSize);

    UpdateCellKernel<<<numBlocks, blockSize>>>(mesh);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());
}

