好的 ✅
我帮你把**水利问题模型**完整梳理一下：

* 先定义 **数据结构**（包括 `Mesh`、`Cell`、`Side`、`BoundaryCondition` 等）。
* 然后定义 **计算过程**（时间步循环、边流量计算、Cell 更新）。
* 特别对 **内部边界**（`Internal`）做了 **复杂流程标注**，以提示需要进一步展开。

下面给出完整伪代码：

```pseudo
# =====================
# 数据结构定义
# =====================

# 网格结构
type Mesh:
    cells: List[Cell]
    sides: List[Side]

# 单元格
type Cell:
    id: int
    sides: List[Side]
    h: float   # 水深
    u: float   # x方向速度
    v: float   # y方向速度

# 边
type Side:
    id: int
    cell_left: Cell
    cell_right: Cell
    boundary: BoundaryCondition
    flr0: float
    flr1: float
    flr2: float
    flr3: float

# 边界条件
type BoundaryCondition:
    klas: KlasType
    values: Dict   # 存储不同分类对应的值，如 {QT: ..., ZT: ..., ZW: ..., QW: ..., ...}

# 边界类型枚举
enum KlasType:
    Flow        # 流量边界（QT）
    WaterLevel  # 水位边界（ZT）
    ZQRelation  # 水位-流量关系（ZW, QW）
    Dyke        # 堤（TOPW）
    Open        # 开边界（JL）
    Breach      # 溃口（TOPD）
    Internal    # 内部边界（复杂流程）
    Land        # 陆地边界（无需存值）


# =====================
# 计算过程
# =====================

procedure Simulate(mesh: Mesh, time_steps: int, dt: float):
    for t in 1..time_steps:

        # Step 1: 遍历所有边，计算 flr0, flr1, flr2, flr3
        for each side in mesh.sides:
            side.flr0, side.flr1, side.flr2, side.flr3 = ComputeFlux(side, t)

        # Step 2: 遍历所有cell，更新状态
        for each cell in mesh.cells:
            prev_h = cell.h
            prev_u = cell.u
            prev_v = cell.v

            # 新状态依赖于：上一时刻状态 + 本时刻边flux
            cell.h = UpdateCellDepth(cell.sides, prev_h)
            cell.u = UpdateCellVelocityU(cell.sides, prev_u)
            cell.v = UpdateCellVelocityV(cell.sides, prev_v)


# =====================
# 边流量计算
# =====================

function ComputeFlux(side: Side, t: int) -> (float, float, float, float):

    if side.boundary.klas == Flow:
        QT = side.boundary.values["QT"]
        return FluxFromFlow(QT)

    if side.boundary.klas == WaterLevel:
        ZT = side.boundary.values["ZT"]
        return FluxFromWaterLevel(ZT)

    if side.boundary.klas == ZQRelation:
        ZW = side.boundary.values["ZW"]
        QW = side.boundary.values["QW"]
        return FluxFromZQRelation(ZW, QW)

    if side.boundary.klas == Dyke:
        TOPW = side.boundary.values["TOPW"]
        return FluxFromDyke(TOPW)

    if side.boundary.klas == Open:
        JL = side.boundary.values["JL"]
        return FluxFromOpenBoundary(JL)

    if side.boundary.klas == Breach:
        TOPD = side.boundary.values["TOPD"]
        return FluxFromBreach(TOPD)

    if side.boundary.klas == Land:
        return FluxForLandBoundary()

    if side.boundary.klas == Internal:
        # ⚠️ 内部边界：此处存在复杂流程
        #   - 需要计算相邻 cell 的状态耦合
        #   - 可能涉及 Riemann 问题求解
        #   - 考虑静水压力、动量守恒、连续性方程
        #   - 需要特殊数值格式（如 Godunov、Roe、HLL 等）
        return FluxForInternalBoundary(side)

    # 默认返回零流量
    return (0, 0, 0, 0)


# =====================
# Cell 状态更新
# =====================

function UpdateCellDepth(sides: List[Side], prev_h: float) -> float:
    # h(t+1) = h(t) + sum(flr0) * Δt
    return prev_h + SumOverSides(sides, "flr0")

function UpdateCellVelocityU(sides: List[Side], prev_u: float) -> float:
    # u(t+1) = u(t) + sum(flr1, flr3) * Δt
    return prev_u + CombineFlux(sides, ["flr1", "flr3"])

function UpdateCellVelocityV(sides: List[Side], prev_v: float) -> float:
    # v(t+1) = v(t) + sum(flr2) * Δt
    return prev_v + SumOverSides(sides, "flr2")
```

---

这里我特别标注了 **内部边界 (Internal)**：

* 不是直接用初始化值，而是要解耦 **相邻 Cell 的状态**。
* 可能涉及 **Riemann 问题求解**，包括守恒方程、静水压力、流量平衡。
* 这部分需要展开成 **数值格式**（Godunov, Roe, HLL 等）。

要不要我帮你把 **内部边界的复杂流程**单独展开，写一版伪代码？
