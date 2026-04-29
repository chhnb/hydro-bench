#pragma once
#include <common.hpp>

struct MeshData;

/**
 * @struct SideData
 * @brief Host 端边数据容器（Struct of Array 风格）
 */
struct SideData {
    int cellNum;  // 单元格数量
    int sideNum;  // 边数量

    Vec NAC;
    Vec KLAS;
    Vec SIDE;
    Vec COSF;
    Vec SINF;
    Vec SLCOS;
    Vec SLSIN;

    SideData() = default;
};

/**
 * @struct SideView
 * @brief Device 端边数据容器（Struct of Array 风格）
 */
struct SideView {
    RealView1d KLAS;

    ConstRealView1d NAC;
    ConstRealView1d SIDE;
    ConstRealView1d COSF;
    ConstRealView1d SINF;
    ConstRealView1d SLCOS;
    ConstRealView1d SLSIN;


    RealView1d FLUX0;
    RealView1d FLUX1;
    RealView1d FLUX2;
    RealView1d FLUX3;

    SideView() = default;

    // Host -> Device
    void FromHost(const MeshData& meshData);

    // Device -> Host
    void ToHost(MeshData& host_data) const;
};
