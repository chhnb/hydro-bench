#pragma once
#include <common.hpp>

struct MeshData;

/**
 * @brief Host 端 Cell 数据容器（Array 风格）
 */
struct CellData {
    Vec H, U, V, W, Z;
    
    Vec ZBC;
    Vec ZB1;
    Vec AREA;
    Vec FNC;
    Veci NHQ1;

    Vec2 ZW;
    Vec2 QW;

    // 构造函数
    CellData() = default;
};

/**
 * @brief Device 端 Cell 数据（Kokkos View）
 */
struct CellView {
    RealView1d H;
    RealView1d U;
    RealView1d V;
    RealView1d W;
    RealView1d Z;

    ConstIntView1d NHQ1;
    ConstRealView1d ZBC;
    ConstRealView1d ZB1;
    ConstRealView1d AREA;
    ConstRealView1d FNC;
    ConstRealView1d BoundaryFeature; // TOPD

    ConstRealView1d ZW;
    ConstRealView1d QW;
    ConstRealView1d QT; 
    ConstRealView1d DQT;
    ConstRealView1d ZT;
    ConstRealView1d DZT;


    CellView() = default;

    CellView(const MeshData& mesh_data) {
        FromHost(mesh_data);
    }

    // Host -> Device
    void FromHost(const MeshData& mesh_data);

    // Device -> Host
    void ToHost(MeshData& mesh_data) const;
};
