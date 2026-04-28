# `hydro-cal` 计算内容完整梳理

本文档对 `hydro-cal/` 目录下的代码、数据与算法做完整说明，主要回答两件事：
**（1）模型在物理上算的是什么？（2）代码在工程上是怎么组织的？**

---

## 1. 一句话定位

`hydro-cal` 是一个 **二维浅水方程（Shallow Water Equations, SWE）求解器** 的
**CUDA 原生 API 重构版本**，用有限体积法在四边形非结构网格上推进水深 `H`、流速
`U/V`、水位 `Z`，主要用于 **大尺度河道 / 流域水动力仿真**（当前数据集
约 20.7 万单元，对应一片真实地形）。

数值核心是 **Osher 近似 Riemann 求解器**，配合多种边界条件（水位、流量、
水位-流量关系、堤、溃口、开边界等）。整个时间循环全部跑在 GPU 上，
通过 `MeshView / CellView / SideView` 把数据 Struct-of-Arrays 化，
并提供普通 Kernel-Launch 与 CUDA Graph 两种执行模式。

---

## 2. 物理模型（控制方程）

二维守恒形浅水方程，通量分解到每条边上：

```
∂H/∂t  + ∇·(H U)              = 0
∂(HU)/∂t + ∇·(H U⊗U) + g H ∇Z = -g n² |U| U / H^(1/3)
```

- `H` 水深，`Z = H + ZBC` 自由水面高程，`ZBC` 河床高程
- `U=(U,V)` 二维流速
- `g = 9.81 m/s²`，重力加速度（代码中常量 `4.905 = g/2`、`9.81`、`39.24 = 4g²`、
  `313.92 = 32 g²` 等多处出现）
- 摩阻：Manning 公式，`FNC = g · n²`，源项里以 `WSF = FNC·|U|/H^(1/3)` 出现
- 时间推进：显式一阶（参见 `UpdateCellKernel`）

每条边的通量记作 `FLR = (FLUX0, FLUX1, FLUX2, FLUX3)`：
- `FLUX0` = 法向质量通量（连续方程贡献）
- `FLUX1` = 法向动量通量
- `FLUX2` = 切向动量通量
- `FLUX3` = 静水压力项 `½ g H²`（代码里写成 `4.905 * H * H`）

`UpdateCellKernel` 把 4 条边的通量按方向余弦旋回 (x, y) 坐标，得到单元的
ΔH、ΔU、ΔV，再加上摩阻项推进到下一时刻。

---

## 3. 目录与文件总览

```
hydro-cal/
├── README.md                 ← 仅放性能数据（vs 原二维模型 ~2× 加速）
├── BINFOR/                   ← 网格 / 时间 / 全局参数 (输入)
├── SOURCES/                  ← 拓扑 / 边界单元映射 (输入)
├── BOUNDE/                   ← 边界条件时间序列 (输入)
│   ├── NQ/   流量边界  Q(t)
│   ├── NZ/   水位边界  Z(t)
│   └── NZQ/  水位-流量关系 Z↔Q
├── WQPAR/                    ← 水质模块系数（本次未启用）
└── SOURCE/                   ← C++/CUDA 源码
    ├── CMakeLists.txt
    ├── doc/hy.md             ← 原作者用伪代码描述模型
    ├── include/
    │   ├── common.hpp        ← 类型别名 / 模型常量 / blockSize
    │   ├── functors.cuh      ← Kernel 与 device 函数声明
    │   ├── utils.hpp         ← 文本输入读取小工具
    │   └── mesh/{mesh,cell,side}.hpp
    └── src/
        ├── main.cpp          ← 入口 / 时间循环 / CUDA Graph
        ├── mesh.cpp          ← Host 端数据加载 + 预处理 + 输出
        ├── cell.cpp / side.cpp ← Host→Device 拷贝
        └── functors.cu       ← 全部 GPU Kernel 与 Riemann 求解
```

---

## 4. 数据结构（Host vs Device 双套）

文件：`SOURCE/include/mesh/{mesh,cell,side}.hpp`、`SOURCE/include/common.hpp`

### 4.1 全局类型
```cpp
using Real = float;             // 单精度
using RealView1d = Real*;       // 设备端裸指针 view
constexpr int blockSize = 256;
```

### 4.2 Host 容器（`*Data`，AoS→SoA `std::vector`）

| 容器 | 关键字段 | 含义 |
|---|---|---|
| `MeshData` | `NDAYS, CELL, NHQ, NQ, NZ, NZQ, NWE, NDI, MDT, DT, NTOUTPUT, HM1, HM2, JL` | 全局标量参数 |
| `MeshData` | `NV, NAP, FNC0, XP, YP, MBZ/NNZ, MBQ/NNQ, MBW/TOPW, MBZQ/NNZQ, ZT/QT, DZT/DQT` | 节点坐标、边界单元映射、边界时间序列与差分 |
| `CellData` | `H, U, V, W, Z, ZBC, ZB1, AREA, FNC, NHQ1, ZW, QW` | 单元守恒量、河床、几何、水位-流量关系 |
| `SideData` | `KLAS, NAC, SIDE, COSF, SINF, SLCOS, SLSIN` | 边类型、邻接单元、边长、方向余弦、几何系数 |

### 4.3 Device 容器（`*View`，全部裸 `Real*`）

`MeshView` 把若干 `const` 标量字段加 `CellView`、`SideView`，然后
`FromHost(host)` 在 `cell.cpp / side.cpp` 中：
1. `cudaMalloc` 全部数组
2. `cudaMemcpy` 拷贝初始值
3. `cudaMemset` 把 `FLUX0..3` 清零

> 注意：`KLAS` 在 host 端是 `Vec`（float 数组），device 端是 `RealView1d` —— 类型故意设成 `Real`，
> 因为 `BOUNDA` 里写过 `sides.KLAS[idx] = 0` 会修改它，存浮点便于和别的 Real 数组共用工具。

---

## 5. 输入文件清单（一一对应代码读取顺序）

读取入口：`MeshData::InitFromFile(filePath)`（`mesh.cpp:7`）。

### 5.1 `BINFOR/`：标量参数 + 初值
| 文件 | 解析后字段 | 实际内容（当前数据） |
|---|---|---|
| `TIME.DAT` | `MDT, NDAYS, NTOUTPUT` | 3600s, 50d, 50 |
| `GIRD.DAT` | `NOD, CELL` | 节点 210193, 单元 207234 |
| `DEPTH.DAT` | `HM1, HM2` | 干判阈 0.001m，浅水阈 0.01m |
| `BOUNDARY.DAT` | `NZ, NQ, NZQ, NHQ, NWE, NDI` | 34 / 58 / 0 / 200 / 0 / 0 |
| `CALTIME.DAT` | 起算时刻 + `DT` | 2025-08-02 00:00, dt=0.5s |
| `JL.DAT` | `JL` | 开边界损失系数 0.0003 |
| `MODEL.DAT` | 模块开关 | 仅启用水动力 |
| `INITIALLEVEL.DAT` | `cells.Z` | 每单元初始水位（≈2925.24m 山区高程） |
| `INITIALU1/V1.DAT` | `cells.U/V` | 全 0 冷启动 |
| `CV.DAT` | `FNC0` | Manning n=0.021 |

### 5.2 `SOURCES/`：网格拓扑 + 边界单元映射
| 文件 | 字段 | 含义 |
|---|---|---|
| `PNAC.DAT` | `sides.NAC[CELL×4]` | 每单元 4 条边各自的**邻居单元号**（0 表外边界） |
| `PNAP.DAT` | `NAP[4][CELL]` | 每单元 4 个**节点号**（用来求面积、边长） |
| `PKLAS.DAT` | `sides.KLAS[CELL×4]` | 每条边的**类型 / 边界种类码**（0=内边，1/3/4/5/6/7/10=各类边界） |
| `PZBC.DAT` | `cells.ZBC` | 单元河床高程 |
| `PXY.DAT` | `XP, YP` | 节点坐标（米） |
| `MBZ.DAT / NNZ` | `MBZ, NNZ` | 水位边界单元号 + 关联的 NZ 站 ID（共 NZ=34 个单元） |
| `MBQ.DAT / NNQ` | `MBQ, NNQ` | 流量边界单元号 + 关联的 NQ 站 ID（共 NQ=58 个单元，对应 2 站入流） |
| `MBW.DAT / TOPW` | 堤顶高度 | 本数据集为空（`NWE=0`） |
| `MBZQ.DAT / NNZQ` | 水位-流量关系映射 | 本数据集为空（`NZQ=0`） |

### 5.3 `BOUNDE/`：边界**时间序列**
读取入口：`take_boundary_for_two_d`（`mesh.cpp:377`）

- `NQ/NQ%04d.DAT`：第一行点数 N，后续 N 行 `t_hr  Q(t)`
- `NZ/NZ%04d.DAT`：第一行点数 N，后续 N 行 `t_hr  Z(t)`
- `NZQ/NZQ%04d.DAT`：第一行点数 N，后续 N 行 `Z  Q`（水位-流量曲线）

代码先按 `BOUNDRYinterp` 线性插值到每个 `jt`（天/大步），再按 `K0 = MDT/DT` 计算
**子步的差分增量** `DZT, DQT`，运行时按 `Z(t)= ZT[jt] + DZT[jt] * kt` 逐步累加，
避免每个子步重复插值。

### 5.4 `WQPAR/`：水质参数
当前 `MODEL.DAT` 只启用水动力（`MODEL.DAT` 的 `0   水质`），这些文件未参与计算。

---

## 6. 网格几何预处理（`MeshData::preCalculate`，`mesh.cpp:283`）

每个 cell 的 4 条边：
- 用 `NAP[j][i]` 拿到节点 `(N1, N2)`，计算 `DX, DY` 与 `SIDE = sqrt(DX² + DY²)`
- `SINF = DX/SIDE`、`COSF = DY/SIDE`（注意：这是把法向投到 (x,y) 坐标系的方向余弦）
- `SLCOS = SIDE * COSF`、`SLSIN = SIDE * SINF`（更新单元时直接用，省一次乘法）

每个 cell 面积：用对角线把四边形拆成两个三角形，叉乘绝对值之和的一半。

干湿初始化：若 `Z[i] ≤ ZBC[i]`，强制 `H = HM1`、`Z = ZB1 = ZBC + HM1`。

摩阻常数：`cells.FNC[i] = 9.81 * FNC0[i]² = g · n²`。

---

## 7. 时间循环（`SOURCE/src/main.cpp`）

```cpp
total_days    = NDAYS;           // = 50
steps_per_day = MDT / DT;        // 3600 / 0.5 = 7200

for (day = 0; day < total_days; day++)
    for (step = 1; step < steps_per_day; step++) {
        CalculateFlux(mesh_view, step, day);   // 每边一个线程
        UpdateCell  (mesh_view, step, day);    // 每单元一个线程
    }
    // 每 NTOUTPUT 天 ToHost + outputToFile
```

两种实现：
1. **`RunSimulation`**：朴素循环，每个子步两次 kernel launch + `cudaDeviceSynchronize`
2. **`RunSimulationGraph`**：第一天用 `cudaStreamBeginCapture / EndCapture`
   把 7200 步的 kernel 序列录成一个 `cudaGraphExec_t`，之后每天只需 `cudaGraphLaunch`，
   省掉每子步的启动开销

输出（`mesh_data.outputToFile`）：
- `SIDE.OUT`：边几何（COSF/SINF/SIDE/AREA），仅首步写一次
- `H2U2V2.OUT`：每输出步 H、U、V
- `ZUV.OUT`：Z、W=√(U²+V²)、流向角 FI
- `XY-TEC.DAT`：Tecplot FEQUADRILATERAL 格式（节点坐标 + 单元变量 + 单元-节点表）
- `TIMELOG.OUT`：归一化时间戳

---

## 8. GPU Kernel 总览（`SOURCE/src/functors.cu`）

### 8.1 `CalculateFluxKernel`（每边一个线程，N = CELL×4）
按每个边的 `KLAS`（边类型）分发：

| KLAS | 含义 | 入口 |
|---|---|---|
| 1 | **水位边界 ZT(t)** | `CalculateKlas1` —— 不动点迭代解 Riemann 不变量得 URB |
| 3 | **水位-流量关系 Z=f(Q)** | `CalculateKlas3` —— `LAQP` 线性查表 + 不动点迭代 |
| 4 | **陆地（无通量）** | 只算静水压力 FLR(3) |
| 5 | **开边界** | `JL` 衰减项进入 FLR(3) |
| 6 | **堤 / 溢流堰** | `CalculataKlas6` —— 自由 / 淹没出流公式 (`C1 * H^1.5`) |
| 7 | **溃口** | `CalculateKlas7` —— Villemonte 公式 `QD()`（堰流） |
| 8/2 | 已预留 | `BOUNDA` 入口里被拦截到默认分支 |
| 10 | **流量边界 QT(t)** | `CalculateKlas10` —— 不动点迭代求边水深 HB |
| 0 | **内部边** | 走 Osher 求解器 |

`BOUNDA(...)` 是上述 1/3/4/5/6/7/10 的总入口。

内部边（KP==0）的流程：
1. 取本单元的左态 QL = (H, U·cos+V·sin, V·cos−U·sin)
2. 取邻居单元的右态 QR
3. 干湿/浅水分支：完全干、对岸更高、本侧更浅、对岸更浅各有简化解析公式
4. 一般情况（双方都"够湿"）调用 **`OSHER(...)` 求解器**：
   - 用左/右黎曼不变量 `FIL = U_L + 2 c_L`、`FIR = U_R - 2 c_R`
   - 按 `(K1, K2) ∈ {1,2,3,4} × {1,2,3,4}` 共 16 种波结构组合
     调用 `QS<T>` 模板（T = 1..7 对应不同的解析积分子段），把通量 `QF()`
     按段累加到 `FLR_OSHER[0..3]`
   - **去重计数**：为了避免双向重复算一条边，KP==0 时只在 `pos < NC` 一侧走 OSHER，
     另一侧直接复用 `-FLR_OSHER[0]`（`functors.cu:108-160`）

### 8.2 `UpdateCellKernel`（每单元一个线程，N = CELL）
```cpp
for j in 0..3:           // 4 条边
    WH +=    SIDE   * FLUX0
    WU +=  SLCOS*(FLUX1+FLUX3) - SLSIN*FLUX2
    WV +=  SLSIN*(FLUX1+FLUX3) + SLCOS*FLUX2

DTA = DT / AREA
H2  = max(H1 - DTA*WH, HM1)        ← 连续方程 + 干阈
Z2  = H2 + ZBC

if H2 ≤ HM1 :  U2 = V2 = 0
elif H2 ≤ HM2 : U2 = sign(U1)·min(VMIN,|U1|), 同理 V2     ← 限速
else:
    QX = H1·U1; QY = H1·V1
    WSF = FNC * |U|/H1^(1/3)
    U2 = (QX − DTA·WU − DT·WSF·U1)/H2     ← 显式动量更新含摩阻
    V2 = (QY − DTA·WV − DT·WSF·V1)/H2
    U2,V2 → clip 到 ±15 m/s
```

---

## 9. 模型常量与魔术数对照表（`common.hpp` + `functors.cu`）

| 名称 | 值 | 含义 |
|---|---|---|
| `S0` | 0.0002 | 河床比降（当前未直接使用，预留） |
| `DX2` | 5000.0 | 网格特征长度（兼容字段） |
| `BRDTH` | 100.0 | 溃口典型宽度，用于 KLAS=7 |
| `C0` | 1.33 | 宽顶堰流量系数（KLAS=6） |
| `C1` | 1.7 | 自由出流系数 |
| `VMIN` | 0.001 | 最小速度 |
| `QLUA` | 0.0 | 单元侧向源汇（如降雨/抽水），当前为 0 |
| `4.905` | g/2 | 静水压力 ½ g H² |
| `9.81` | g | 重力加速度 |
| `39.24` | 4 g² 的 1/(4·9.81)? | 实为 4g 的 1/相关推导，代码里 `HB = W²/39.24` 即 `H = (FIL−Q/H₀)²/(4g)` |
| `6.264` | 2√(g) ≈ 2·√9.81 | 出现在 `FIAL = U + 2c` 形式中 |
| `313.92` | 32 g² | KLAS=3 不动点迭代里 `URB = ΔΦ³ / HB / 313.92` |

---

## 10. 当前数据集的物理规模（来自实际输入）

- 域：约 21 万节点 / 20.7 万四边形单元（真实 DEM 网格）
- 河床高程：~2900–2940 m，初始水位 2925.24 m（典型山区/水库尺度）
- 总仿真时长：50 天，时间步 0.5 s ⇒ 每天 7200 步，全程 360 000 步
- 入流：2 个流量站（约 9 840 m³/s）、34 个水位单元（下游恒定 2925.24 m）
- 摩阻：Manning n = 0.021（混凝土/平整渠道量级）
- 当前 `RunSimulation` 每天约 **0.11–0.14 s 计算时间**（GPU），
  原模型约 **0.26–0.30 s**（README）

---

## 11. 调用链速查

```
main()
└── MeshData mesh_data(path)
│   └── InitFromFile()
│       ├── 读 BINFOR/*.DAT 标量
│       ├── loadFromFilePNAC / PNAP / PKLAS / PZBC / PXY  (拓扑+几何)
│       ├── loadFromFileMBZ / MBQ / MBW / MBZQ           (边界单元映射)
│       ├── loadFromFileInitLevel / U1 / V1 / CV          (初值 + 糙率)
│       ├── preCalculate()                               (面积/边长/方向余弦/FNC)
│       └── take_boundary_for_two_d()                    (BOUNDE 时间序列 → ZT/QT/DZT/DQT)
│
└── MeshView mesh_view(mesh_data)
│   ├── CellView::FromHost  (cudaMalloc + cudaMemcpy)
│   └── SideView::FromHost  (cudaMalloc + cudaMemcpy + cudaMemset FLUX)
│
└── RunSimulation / RunSimulationGraph
    └── for day, for step:
        ├── CalculateFluxKernel<<<...>>>
        │   └── BOUNDA (KLAS=1/3/4/5/6/7/10 各自分支)
        │   └── OSHER  (内部边 Riemann)
        └── UpdateCellKernel<<<...>>>
        ├── (每 NTOUTPUT 天) MeshView::ToHost → outputToFile
```

---

## 12. 需要注意的几点

1. **单精度 `Real = float`**：所有 GPU 数组都是 `float`；`CalculateFlux` 里
   `pow(., 1.5)`、`sqrtf` 也都是 32-bit。这是和上层 hydro-bench 校验体系
   `taichi_impl/F2_hydro_taichi_fp64.py` 等比对时差异的来源之一。
2. **`KLAS` 类型不一致**：host 是 `Vec`(float)、device `RealView1d`，
   `BOUNDA` 里有 `sides.KLAS[idx] = 0` 这类写操作（KLAS=7 触发后会"打开"成 0）。
3. **CellView `NHQ1` 实际只为 `NZQ` 单元有效**：当前数据 `NZQ=0`，
   ZW/QW 数组按 `CELL × NHQ` 分配（约 `207234*200*4B ≈ 158 MB`），
   绝大部分槽位是 0。这是为了保持 KLAS=3 分支的全局可寻址。
4. **CUDA Graph 模式假设 `step` 范围、kernel 形状每天不变**：
   当前 `mesh_view, mesh_data` 不变 ⇒ 第一天捕获的 graph 可以重复 launch。
5. **输出维持原 Fortran 风格文本格式**：`%10.4f`、每 10 列换行，
   是为了与历史 1D/2D 模型的对照工具兼容。

---

## 13. 与本仓库其他实现的关系

仓库里另有 `taichi_impl/`、`cuda_impl/`、`cuda_native_impl/`，
`hydro-cal/SOURCE/` 是 **`cuda_native_impl` 的对照源**——就是 README 里说的
"采用 cuda 原生 API 进行的二维计算模型重构版本"，相对原 2D 模型加速约 2 倍。
后续在做对齐 / 性能比对（`results/alignment/...`）时，
**hydro-cal 是参考实现 (golden)**，taichi 等其它后端按它的数值结果对账。
