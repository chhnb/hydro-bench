#pragma once
#include "mesh/cell.hpp"
#include "mesh/side.hpp"
#include "common.hpp"
#include <filesystem>

/**
 * @brief Mesh 数据容器: Host 端
 */
struct MeshData {
    // 核心计算数据
    int NDAYS;          // 天数
    int CELL;           // 单元格数量
    int NHQ;
    int NQ;
    int NZ;
    int NZQ;
    int NDI;
    int NWE;
    int NOD;
    int MDT;
    float DT;           // 时间步长, 可能为小数
    int NTOUTPUT;       // 输出时间步长
    int dummy;          // 占位符
    Real HM1, HM2;
    Real JL;

    CellData cells;
    SideData sides;

    // 预处理数据
    int sidesNum;       // 边数量
    int NNZ0;
    int NNQ0;
    int NNZQ0;
    Real XIMIN;
    Real YIMIN;

    Veci NV;
    Vec2i NAP;
    Vec FNC0;
    Vec XP, YP;         // 节点坐标
    Vec MBZ, NNZ;
    Vec MBQ, NNQ;
    Vec MBW, TOPW;
    Vec MBZQ, NNZQ;
    Vec2 ZT, QT;        // 边界插值数据
    Vec2 DZT, DQT;      // 边界插值数据
    
    // 输出文件句柄
    std::ofstream SIDE_file;
    std::ofstream ZUV_file;
    std::ofstream SHA_file;
    std::ofstream H2U2V2_file;
    std::ofstream XY_TEC_file;
    std::ofstream SHA_TEC_file;
    std::ofstream TIMELOG_file;


    MeshData() = default;

    MeshData(const std::string& filePath){

        // 从文件初始化模型
        InitFromFile(filePath);

        // 在打开文件之前创建文件夹
        namespace fs = std::filesystem;
        fs::path outputPath = filePath + "OUTPUT";

        // 创建文件夹（如果不存在）
        if (!fs::exists(outputPath)) {
            fs::create_directories(outputPath);
        }

        // 打开输出文件
        SIDE_file.open(filePath + "OUTPUT/SIDE.OUT", std::ios::out | std::ofstream::trunc);
        ZUV_file.open(filePath + "OUTPUT/ZUV.OUT", std::ios::out | std::ofstream::trunc);
        H2U2V2_file.open(filePath + "OUTPUT/H2U2V2.OUT", std::ios::out | std::ofstream::trunc);
        XY_TEC_file.open(filePath + "OUTPUT/XY-TEC.DAT", std::ios::out | std::ofstream::trunc);
        TIMELOG_file.open(filePath + "OUTPUT/TIMELOG.OUT", std::ios::out | std::ofstream::trunc);
    }

    ~MeshData() {
        if (SIDE_file.is_open()) SIDE_file.close();
        if (ZUV_file.is_open()) ZUV_file.close();
        if (SHA_file.is_open()) SHA_file.close();
        if (H2U2V2_file.is_open()) H2U2V2_file.close();
        if (XY_TEC_file.is_open()) XY_TEC_file.close();
        if (SHA_TEC_file.is_open()) SHA_TEC_file.close();
        if (TIMELOG_file.is_open()) TIMELOG_file.close();
    }

    // 从文件初始化模型：包括常量和 CellData、SideData
    void InitFromFile(const std::string& filePath);

    void loadFromFilePNAC(const std::string& filename);
    void loadFromFilePNAP(const std::string& filename);
    void loadFromFilePKLAS(const std::string& filename);
    void loadFromFilePZBC(const std::string& filename);
    void loadFromFilePXY(const std::string& filename);
    void loadFromFileMBZ(const std::string& filename);
    void loadFromFileMBQ(const std::string& filename);
    void loadFromFileMBW(const std::string& filename);
    void loadFromFileMBZQ(const std::string& filename);
    void loadFromFileInitLevel(const std::string& filename);
    void loadFromFileU1(const std::string& filename);
    void loadFromFileV1(const std::string& filename);
    void loadFromFileCV(const std::string& filename);

    // 数据预处理
    void preCalculate();
    void take_boundary_for_two_d(const std::string& filePath);
    Real BOUNDRYinterp(Real THOURS, int NZQSTEMP, Vec ZQSTIME, Vec ZQSTEMP);

    // 数据输出
    Real FI(Real X, Real Y);
    void outputToFile(int jt, int kt);
};

/**
 * @brief Mesh 数据容器: Device 端
 */
struct MeshView {
    const int NHQ;
    const int NQ;
    const int NZ;
    const int NWE;
    const int NDAYS;
    const int CELL;
    const float DT;
    const Real HM1, HM2;
    const Real JL;

    CellView cells;
    SideView sides;

    // todo: 构造函数内赋值常量; 初始化话 cells 和 sides
    MeshView() = default;

    MeshView(const MeshData& host)
        : NHQ(host.NHQ), NQ(host.NQ), NZ(host.NZ), NWE(host.NWE), NDAYS(host.NDAYS),
          CELL(host.CELL), DT(host.DT), HM1(host.HM1), HM2(host.HM2), JL(host.JL){
        FromHost(host);
    }

    // Host -> Device
    void FromHost(const MeshData& meshData);

    // Device -> Host
    void ToHost(MeshData& MeshData) const;
};