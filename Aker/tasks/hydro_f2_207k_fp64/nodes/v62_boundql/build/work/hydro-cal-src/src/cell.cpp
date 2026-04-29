#include "mesh/cell.hpp"
#include "mesh/mesh.hpp"
#include "utils.hpp"
#include <fstream>
#include <iostream>

// ------------------- CellData -------------------
// 数据由 MeshData 负责加载和管理

// ------------------- CellView -------------------
void CellView::FromHost(const MeshData& mesh_data) {
    int num_cells = mesh_data.CELL;
    CellData cell_data = mesh_data.cells;

    // 1. 初始化 device view
    cudaMalloc((void**)&H, num_cells * sizeof(Real));
    cudaMalloc((void**)&U, num_cells * sizeof(Real));
    cudaMalloc((void**)&V, num_cells * sizeof(Real));
    cudaMalloc((void**)&W, num_cells * sizeof(Real));
    cudaMalloc((void**)&Z, num_cells * sizeof(Real));

    CUDA_CHECK(cudaGetLastError());

    // 只读 view
    IntView1d NHQ1_rw; RealView1d ZBC_rw; RealView1d ZB1_rw; RealView1d AREA_rw;
    RealView1d FNC_rw; RealView1d BoundaryFeature_rw;
    RealView1d ZW_rw; RealView1d QW_rw; RealView1d QT_rw; RealView1d DQT_rw; RealView1d ZT_rw; RealView1d DZT_rw;  

    cudaMalloc((void**)&NHQ1_rw, num_cells * sizeof(int));
    cudaMalloc((void**)&ZBC_rw, num_cells * sizeof(Real));
    cudaMalloc((void**)&ZB1_rw, num_cells * sizeof(Real));
    cudaMalloc((void**)&AREA_rw, num_cells * sizeof(Real));
    cudaMalloc((void**)&FNC_rw, num_cells * sizeof(Real));
    cudaMalloc((void**)&BoundaryFeature_rw, num_cells * sizeof(Real));

    CUDA_CHECK(cudaGetLastError());

    // 二维矩阵初始化
    cudaMalloc((void**)&ZW_rw, num_cells * mesh_data.NHQ * sizeof(Real));
    cudaMalloc((void**)&QW_rw, num_cells * mesh_data.NHQ * sizeof(Real));
    cudaMalloc((void**)&QT_rw, num_cells * mesh_data.NDAYS * sizeof(Real));
    cudaMalloc((void**)&DQT_rw, num_cells * mesh_data.NDAYS * sizeof(Real));
    cudaMalloc((void**)&ZT_rw, num_cells * mesh_data.NDAYS * sizeof(Real));
    cudaMalloc((void**)&DZT_rw, num_cells * mesh_data.NDAYS * sizeof(Real));

    CUDA_CHECK(cudaGetLastError());

    // 2. 拷贝数据到 device view
    // (1)一维特征
    cudaMemcpy(H, cell_data.H.data(), sizeof(Real) * num_cells, cudaMemcpyHostToDevice);
    cudaMemcpy(U, cell_data.U.data(), sizeof(Real) * num_cells, cudaMemcpyHostToDevice);
    cudaMemcpy(V, cell_data.V.data(), sizeof(Real) * num_cells, cudaMemcpyHostToDevice);
    cudaMemcpy(W, cell_data.W.data(), sizeof(Real) * num_cells, cudaMemcpyHostToDevice);
    cudaMemcpy(Z, cell_data.Z.data(), sizeof(Real) * num_cells, cudaMemcpyHostToDevice);

    CUDA_CHECK(cudaGetLastError());

    cudaMemcpy(ZBC_rw, cell_data.ZBC.data(), sizeof(Real) * num_cells, cudaMemcpyHostToDevice);
    cudaMemcpy(ZB1_rw, cell_data.ZB1.data(), sizeof(Real) * num_cells, cudaMemcpyHostToDevice);
    cudaMemcpy(AREA_rw, cell_data.AREA.data(), sizeof(Real) * num_cells, cudaMemcpyHostToDevice);
    cudaMemcpy(FNC_rw, cell_data.FNC.data(), sizeof(Real) * num_cells, cudaMemcpyHostToDevice);

    CUDA_CHECK(cudaGetLastError());

    NHQ1 = NHQ1_rw;
    ZBC = ZBC_rw;
    ZB1 = ZB1_rw;
    AREA = AREA_rw;
    FNC = FNC_rw;

    // (2) 一维边界特征: 将 TOPD, TOPW 统一到 BoundaryFeature 属性中
    Vec boundaryFeature_host = Vec(num_cells, 0.0);

    // TODO: KLAS = 7, TOPD 属性未初始化
    // for(int i = 0; i < mesh_data.MDI.size(); i++) {
    //     int pos = mesh_data.MDI[i] - 1;                    // 单元格索引
    //     boundaryFeature_host(pos) = mesh_data.TOPD[i];
    // }
    
    // KLAS = 6, TOPW 属性
    for(size_t i = 0; i < mesh_data.MBW.size(); i++) {
        int pos = mesh_data.MBW[i] - 1;                       // 单元格索引
        boundaryFeature_host[pos] = mesh_data.TOPW[i];
    }


    cudaMemcpy(BoundaryFeature_rw, boundaryFeature_host.data(), sizeof(Real) * num_cells, cudaMemcpyHostToDevice);
    BoundaryFeature = BoundaryFeature_rw;

    CUDA_CHECK(cudaGetLastError());

    // (3) 二维特征
    Veci nhq1_host(num_cells, 0.0);
    Vec zw_host(num_cells * mesh_data.NHQ, 0.0);
    Vec qw_host(num_cells * mesh_data.NHQ, 0.0);
    Vec qt_host(num_cells * mesh_data.NDAYS, 0.0);
    Vec dqt_host(num_cells * mesh_data.NDAYS, 0.0);
    Vec zt_host(num_cells * mesh_data.NDAYS, 0.0);
    Vec dzt_host(num_cells * mesh_data.NDAYS, 0.0);
    
    // ZW, QW（保持行优先）
    // NHQ1 从 NZQ(MBZQ.size()) 拓展到 CELL
    for (size_t i = 0; i < mesh_data.MBZQ.size(); i++) {
        int pos = mesh_data.MBZQ[i] - 1;
        for (int j = 0; j < mesh_data.NHQ; j++) {
            zw_host[pos * mesh_data.NHQ + j] = cell_data.ZW[j][i];
            qw_host[pos * mesh_data.NHQ + j] = cell_data.QW[j][i];
        }
        nhq1_host[pos] = cell_data.NHQ1[i];
    }

    // QT, DQT（列优先）
    for (size_t i = 0; i < mesh_data.MBQ.size(); i++) {
        int pos = mesh_data.MBQ[i] - 1;
        for (int j = 0; j < mesh_data.NDAYS; j++) {
            qt_host[j * num_cells + pos]  = mesh_data.QT[i][j];
            dqt_host[j * num_cells + pos] = mesh_data.DQT[i][j];
        }
    }

    // ZT, DZT（列优先）
    for (size_t i = 0; i < mesh_data.MBZ.size(); i++) {
        int pos = mesh_data.MBZ[i] - 1;
        for (int j = 0; j < mesh_data.NDAYS; j++) {
            zt_host[j * num_cells + pos]  = mesh_data.ZT[i][j];
            dzt_host[j * num_cells + pos] = mesh_data.DZT[i][j];
        }
    }

    // 拷贝到 device
    cudaMemcpy(NHQ1_rw, nhq1_host.data(), sizeof(int) * num_cells, cudaMemcpyHostToDevice);
    cudaMemcpy(ZW_rw, zw_host.data(), num_cells * mesh_data.NHQ * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(QW_rw, qw_host.data(), num_cells * mesh_data.NHQ * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(QT_rw, qt_host.data(), num_cells * mesh_data.NDAYS * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(DQT_rw, dqt_host.data(), num_cells * mesh_data.NDAYS * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(ZT_rw, zt_host.data(), num_cells * mesh_data.NDAYS * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(DZT_rw, dzt_host.data(), num_cells * mesh_data.NDAYS * sizeof(Real), cudaMemcpyHostToDevice);

    CUDA_CHECK(cudaGetLastError());

    ZW = ZW_rw;
    QW = QW_rw;
    QT = QT_rw;
    DQT = DQT_rw;
    ZT = ZT_rw;
    DZT = DZT_rw;
}

void CellView::ToHost(MeshData& host_data) const {
    int num_cells = host_data.CELL;
    CellData& cell_data = host_data.cells;

    // 从 device view 拷贝数据到 host
    cudaMemcpy(cell_data.H.data(), H, num_cells * sizeof(Real), cudaMemcpyDeviceToHost);
    cudaMemcpy(cell_data.U.data(), U, num_cells * sizeof(Real), cudaMemcpyDeviceToHost);
    cudaMemcpy(cell_data.V.data(), V, num_cells * sizeof(Real), cudaMemcpyDeviceToHost);
    cudaMemcpy(cell_data.W.data(), W, num_cells * sizeof(Real), cudaMemcpyDeviceToHost);
    cudaMemcpy(cell_data.Z.data(), Z, num_cells * sizeof(Real), cudaMemcpyDeviceToHost);

}
 