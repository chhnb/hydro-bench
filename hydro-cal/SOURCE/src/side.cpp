#include "mesh/side.hpp"
#include "mesh/mesh.hpp"
#include "utils.hpp"
#include <fstream>
#include <iostream>

// ------------------- SideData -------------------


// ------------------- SideView -------------------
void SideView::FromHost(const MeshData& mesh_data) {
    int num_sides = mesh_data.sidesNum;
    SideData host_data = mesh_data.sides;

    cudaMalloc((void**)&KLAS,  num_sides * sizeof(Real));

    RealView1d NAC_rw; RealView1d SIDE_rw; RealView1d COSF_rw; RealView1d SINF_rw;
    RealView1d SLCOS_rw; RealView1d SLSIN_rw;
    cudaMalloc((void**)&NAC_rw,   num_sides * sizeof(Real));
    cudaMalloc((void**)&SIDE_rw,  num_sides * sizeof(Real));
    cudaMalloc((void**)&COSF_rw,  num_sides * sizeof(Real));
    cudaMalloc((void**)&SINF_rw,  num_sides * sizeof(Real));
    cudaMalloc((void**)&SLCOS_rw, num_sides * sizeof(Real));
    cudaMalloc((void**)&SLSIN_rw, num_sides * sizeof(Real));

    // 分配 FLUX 数组
    cudaMalloc((void**)&FLUX0, num_sides * sizeof(Real));
    cudaMalloc((void**)&FLUX1, num_sides * sizeof(Real));
    cudaMalloc((void**)&FLUX2, num_sides * sizeof(Real));
    cudaMalloc((void**)&FLUX3, num_sides * sizeof(Real));

    cudaMemcpy(KLAS,  host_data.KLAS.data(),  num_sides * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(NAC_rw,   host_data.NAC.data(),   num_sides * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(SIDE_rw,  host_data.SIDE.data(),  num_sides * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(COSF_rw,  host_data.COSF.data(),  num_sides * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(SINF_rw,  host_data.SINF.data(),  num_sides * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(SLCOS_rw, host_data.SLCOS.data(), num_sides * sizeof(Real), cudaMemcpyHostToDevice);
    cudaMemcpy(SLSIN_rw, host_data.SLSIN.data(), num_sides * sizeof(Real), cudaMemcpyHostToDevice);

    NAC   = NAC_rw;
    SIDE  = SIDE_rw;
    COSF  = COSF_rw;
    SINF  = SINF_rw;
    SLCOS = SLCOS_rw;
    SLSIN = SLSIN_rw;

    // FLUX 初始化为 0
    cudaMemset(FLUX0, 0, num_sides * sizeof(Real));
    cudaMemset(FLUX1, 0, num_sides * sizeof(Real));
    cudaMemset(FLUX2, 0, num_sides * sizeof(Real));
    cudaMemset(FLUX3, 0, num_sides * sizeof(Real));
}

void SideView::ToHost(MeshData& host_data) const {
}
