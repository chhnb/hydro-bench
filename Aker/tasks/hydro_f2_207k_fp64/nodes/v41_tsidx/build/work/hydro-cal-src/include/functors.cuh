#pragma once
#include "mesh/mesh.hpp"
#include <cuda_runtime.h>


__global__
void CalculateFluxKernel(MeshView d_mesh, CellView cells, int kt, int jt);

__device__ __forceinline__
void CalculateKlas10(MeshView& mesh, SideView& sides, CellView& cells, int kt, int jt,
    int idx, int pos, Real H_pre, Real FIL, Real& HB);

__device__ __forceinline__
void CalculateKlas7(MeshView& mesh, SideView& sides, CellView& cells, int idx, int pos,
    Real H_pre, Real Z_pre, Real ZC, Real& HB);

__device__ __forceinline__
void CalculataKlas6(MeshView& mesh, SideView& sides, CellView& cells, int idx, int pos,
    Real H_pre, Real Z_pre, Real ZC, Real UC, Real VC, Real (&QL)[3]);

__device__ __forceinline__
void CalculateKlas3(MeshView& mesh, SideView& sides, CellView& cells, int idx, int pos,
    Real H_pre, Real U_pre, Real V_pre, Real Z_pre, Real (&QL)[3]);

__device__ __forceinline__
void CalculateKlas1(MeshView& mesh, SideView& sides, CellView& cells, int kt, int jt, int idx,
    int pos, Real H_pre, Real (&QL)[3]);

__device__ __forceinline__
Real QD(Real ZL, Real ZR, Real ZB);

__device__ __forceinline__
void LAQP(Real X, Real& Y, ConstRealView1d A, ConstRealView1d B, int MS);

template <int T>
__device__ __forceinline__
void QS(int j, int pos, const Real(&QL)[3], const Real(&QR)[3], Real& FIL, Real& FIR,
    Real(&FLUX_OSHER)[4]);

__device__ __forceinline__
void QF(Real h, Real u, Real v, Real(&F)[4]);

__device__ __forceinline__
void BOUNDA(MeshView& mesh, SideView& sides, CellView& cells, int kt, int jt, int pos,
    int idx, Real H_pre, Real U_pre, Real V_pre, Real Z_pre, Real ZC, Real UC, Real VC, Real FIL, Real (&QL)[3]);

__device__ __forceinline__
void OSHER(int pos, Real H_pre, Real(&QL)[3], Real(&QR)[3], Real& FIL, Real(&FLR_OSHER)[4]);

/**
 * @brief 更新单元格状态
 */
__global__
void UpdateCellKernel(MeshView d_mesh);


void RunLaunchTests(const MeshView& mesh);

void CalculateFlux(const MeshView& mesh, int kt, int jt, cudaStream_t stream);

void UpdateCell(const MeshView& mesh, cudaStream_t stream);

void CalculateFlux(const MeshView& mesh, int kt, int jt);

void UpdateCell(const MeshView& mesh);