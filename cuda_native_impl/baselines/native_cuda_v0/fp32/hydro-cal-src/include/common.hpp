#pragma once

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <numeric>
#include <sstream>
#include <vector>
#include <cuda_runtime.h>

using Real = float;
using std::string;
using std::vector;
using Vec = vector<Real>;
using Vec2 = vector<vector<Real>>;
using Vec3 = vector<vector<vector<Real>>>;
using Veci = vector<int>;
using Vec2i = vector<vector<int>>;

using RealView1d = Real*;
using RealView2d = Real**;
using IntView1d    = int*;
using ConstRealView1d = const Real*;
using ConstRealView2d = const Real**;
using ConstIntView1d = const int*;      // 常量视图，有助于编译器优化
using ConstIntView2d = const int**;    // 常量视图，有助于编译器优化



#define FLUX_VAL(A, B, C, D) \
    sides.FLUX0[idx] = A;              \
    sides.FLUX1[idx] = B;              \
    sides.FLUX2[idx] = C;              \
    sides.FLUX3[idx] = D


#define FLR(i) sides.FLUX##i[idx]


namespace modelConstants {
    inline constexpr Real S0    = 0.0002;
    inline constexpr Real DX2   = 5000.0;
    inline constexpr Real BRDTH = 100.0;
    inline constexpr Real C0    = 1.33;
    inline constexpr Real C1    = 1.7;
    inline constexpr Real VMIN  = 0.001;
    inline constexpr Real QLUA  = 0.0;
} // namespace model



// 简化的错误检查宏
#define CUDA_CHECK(cmd) do { cudaError_t e = cmd; if (e != cudaSuccess) { \
    fprintf(stderr, "CUDA error %s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(e)); \
    exit(EXIT_FAILURE); } } while (0)

// 向上取整计算网格尺寸
static inline int div_up(int a, int b){ return (a + b - 1) / b; }

// 每个线程块的线程数量（可调整）
constexpr int blockSize = 256;