#include "mesh/mesh.hpp"
#include "utils.hpp"
#include <sstream>
#include <cstdio>

// ------------------- MeshData -------------------
void MeshData::InitFromFile(const std::string& filePath) {
    std::string dummy;

    // 1. 加载 Mesh 的全局属性
    io::readData(filePath + "BINFOR/TIME.DAT", MDT, NDAYS, NTOUTPUT);
    io::readData(filePath + "BINFOR/GIRD.DAT", NOD, CELL);
    io::readData(filePath + "BINFOR/DEPTH.DAT", HM1, HM2);
    io::readData(filePath + "BINFOR/BOUNDARY.DAT", NZ, NQ, NZQ, NHQ, NWE, NDI);
    io::readData(filePath + "BINFOR/CALTIME.DAT", dummy, DT);
    io::readData(filePath + "BINFOR/JL.DAT", JL);

    sidesNum = CELL * 4;  // 四边形网格

    // 2. 加载文件输入
    loadFromFilePNAC(filePath + "SOURCES/PNAC.DAT");
    loadFromFilePNAP(filePath + "SOURCES/PNAP.DAT");
    loadFromFilePKLAS(filePath + "SOURCES/PKLAS.DAT");
    loadFromFilePZBC(filePath + "SOURCES/PZBC.DAT");
    loadFromFilePXY(filePath + "SOURCES/PXY.DAT");
    loadFromFileMBZ(filePath + "SOURCES/MBZ.DAT");
    loadFromFileMBQ(filePath + "SOURCES/MBQ.DAT");
    loadFromFileMBW(filePath + "SOURCES/MBW.DAT");
    loadFromFileMBZQ(filePath + "SOURCES/MBZQ.DAT");
    loadFromFileInitLevel(filePath + "BINFOR/INITIALLEVEL.DAT");
    loadFromFileU1(filePath + "BINFOR/INITIALU1.DAT");
    loadFromFileV1(filePath + "BINFOR/INITIALV1.DAT");
    loadFromFileCV(filePath + "BINFOR/CV.DAT");
  
    // 3. 数据预处理
    preCalculate();

    // 4. 边界插值处理
    take_boundary_for_two_d(filePath);

}

void MeshData::loadFromFilePNAC(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);
    
    int NO;
    std::string line;
    std::getline(file, line);
    sides.NAC.resize(sidesNum);

    for (int i = 0; i < CELL; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> NO;
        for (int j = 0; j < 4; j++) {
            iss >> sides.NAC[i * 4 + j];
        }
    }
    file.close();
}

void MeshData::loadFromFilePNAP(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    int NO;
    std::string line;
    std::getline(file, line);
    // NAP 没有在 Device 上使用，不将其按边展开
    NAP.resize(4, std::vector<int>(CELL));

    for (int i = 0; i < CELL; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> NO;
        for (int j = 0; j < 4; j++) {
        iss >> NAP[j][i];
        }
    }
    file.close();
}

void MeshData::loadFromFilePKLAS(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    int NO;
    std::string line;
    std::getline(file, line);
    sides.KLAS.resize(sidesNum);
    for (int i = 0; i < CELL; i++) {
      std::getline(file, line);
      std::istringstream iss(line);
      iss >> NO;
      for (int j = 0; j < 4; j++) {
        iss >> sides.KLAS[i * 4 + j];
      }
    }
    file.close();
}

void MeshData::loadFromFilePZBC(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    std::string line;
    std::getline(file, line);
    cells.ZBC.resize(CELL, 0);

    for (int i = 0; i < CELL; i++) {
      std::getline(file, line);
      std::istringstream iss(line);
      iss >> cells.ZBC[i];
    }
    file.close();
}

void MeshData::loadFromFilePXY(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    int NO;
    std::string line;
    std::getline(file, line);
    XP.resize(NOD, 0);
    YP.resize(NOD, 0);
    for (int i = 0; i < NOD; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> NO;
        iss >> XP[i];
        iss >> YP[i];
    }
    file.close();
}

void MeshData::loadFromFileMBZ(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);
    
    std::string line;
    std::getline(file, line);
    std::istringstream iss(line);
    iss >> NNZ0;

    int NO;
    MBZ.resize(NZ, 0);
    NNZ.resize(NZ, 0);
    for (int i = 0; i < NZ; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> NO;
        iss >> MBZ[i];
        iss >> NNZ[i];
    }
    file.close();
}

void MeshData::loadFromFileMBQ(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    std::string line;
    std::getline(file, line);
    std::istringstream iss(line);
    iss >> NNQ0;
    int NO;
    MBQ.resize(NQ, 0);
    NNQ.resize(NQ, 0);
    for (int i = 0; i < NQ; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> NO;
        iss >> MBQ[i];
        iss >> NNQ[i];
    }
    file.close();
}

void MeshData::loadFromFileMBW(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    std::string line;
    std::getline(file, line);
    std::istringstream iss(line);
    iss >> NWE;
    int NO;
    MBW.resize(NWE, 0);
    TOPW.resize(NWE, 0);
    for (int i = 0; i < NWE; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> NO;
        iss >> MBW[i];
        iss >> TOPW[i];
    }
    file.close();
}

void MeshData::loadFromFileMBZQ(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    std::string line;
    std::getline(file, line);
    std::istringstream iss(line);
    iss >> NNZQ0;
    int NO;
    MBZQ.resize(NZQ, 0);
    NNZQ.resize(NZQ, 0);
    for (int i = 0; i < NZQ; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> NO;
        iss >> MBZQ[i];
        iss >> NNZQ[i];
    }
    file.close();
}

void MeshData::loadFromFileInitLevel(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    std::string line;
    std::getline(file, line);
    cells.Z.resize(CELL);
    for (int i = 0; i < CELL; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> cells.Z[i];
    }
    file.close();
}

void MeshData::loadFromFileU1(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    std::string line;
    std::getline(file, line);
    cells.U.resize(CELL);
    for (int i = 0; i < CELL; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> cells.U[i];
    }
    file.close();
}

void MeshData::loadFromFileV1(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    std::string line;
    std::getline(file, line);
    cells.V.resize(CELL);
    for (int i = 0; i < CELL; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> cells.V[i];
    }
    file.close();
}

void MeshData::loadFromFileCV(const std::string& fileName) {
    std::ifstream file(fileName);
    io::AssertFileOpen(file, fileName);

    std::string line;
    std::getline(file, line);
    FNC0.resize(CELL, 0);
    for (int i = 0; i < CELL; i++) {
        std::getline(file, line);
        std::istringstream iss(line);
        iss >> FNC0[i];
    }
    file.close();
}

void MeshData::preCalculate() {
    Veci NW(4, 0);

    XIMIN = *std::min_element(XP.begin(), XP.end());
    YIMIN = *std::min_element(YP.begin(), YP.end());
    for (int i = 0; i < NOD; i++) {
        XP[i] -= XIMIN;
        YP[i] -= YIMIN;
    }

    NV.resize(CELL, 0);
    cells.ZB1.resize(CELL, 0);
    cells.AREA.resize(CELL, 0);
    sides.SIDE.resize(sidesNum, 0);
    sides.SINF.resize(sidesNum, 0);
    sides.COSF.resize(sidesNum, 0);

    for (int i = 0; i < CELL; i++) {
        if (NAP[0][i] == 0) {
            continue;
        }
        cells.ZB1[i] = cells.ZBC[i] + HM1;
        NV[i] = 4;
        int NA = NAP[3][i];
        if (NA == 0 || NA == NAP[0][i]) {
            NV[i] = 3;
        }
        for (int j = 0; j < NV[i]; j++) {
            NW[j] = NAP[j][i];
        }

        Real XP1 = XP[NW[0] - 1];
        Real XP2 = XP[NW[1] - 1];
        Real XP3 = XP[NW[2] - 1];
        Real YP1 = YP[NW[0] - 1];
        Real YP2 = YP[NW[1] - 1];
        Real YP3 = YP[NW[2] - 1];

        cells.AREA[i] = fabs(((YP3 - YP1) * (XP2 - XP1) - (XP3 - XP1) * (YP2 - YP1))/ 2.0);

        if (NV[i] == 4) {
            Real XP4 = XP[NW[3] - 1];
            Real YP4 = YP[NW[3] - 1];
            cells.AREA[i] += fabs(((YP4 - YP1) * (XP3 - XP1) - (XP4 - XP1) * (YP3 - YP1)) / 2.0);
        }
        for (int j = 0; j < NV[i]; j++) {
            int N1 = NW[j] - 1;
            int N2 = NW[(j + 1) % NV[i]] - 1;
            Real DX = XP[N1] - XP[N2];
            Real DY = YP[N2] - YP[N1];

            int sideIdx = i * 4 + j;
            sides.SIDE[sideIdx] = std::sqrt(DX * DX + DY * DY);
            if (sides.SIDE[sideIdx] > 0.0) {
                sides.SINF[sideIdx] = DX / sides.SIDE[sideIdx];
                sides.COSF[sideIdx] = DY / sides.SIDE[sideIdx];
            }
        }
    }

    for (int i = 0; i < CELL; i++) {
        cells.ZB1[i] = cells.ZBC[i] + HM1;
    }

    cells.H.resize(CELL, 0);
    cells.W.resize(CELL, 0);            // 初始化 W
    cells.FNC.resize(CELL, 0);
    sides.SLCOS.resize(sidesNum, 0);
    sides.SLSIN.resize(sidesNum, 0);

    for (int i = 0; i < CELL; i++) {
        if (NAP[0][i] == 0) {
            continue;
        }
        if (cells.Z[i] <= cells.ZBC[i]) {
            cells.H[i] = HM1;
            cells.Z[i] = cells.ZB1[i];
        }
        else {
            cells.H[i] = cells.Z[i] - cells.ZBC[i];
        }
    }

    for (int i = 0; i < CELL; i++) {
        cells.FNC[i] = 9.81 * FNC0[i] * FNC0[i];
        // 忽略了 H,U,V,Z,W 的二维初始化
        for (int j = 0; j < NV[i]; j++) {
            int sideidx = i * 4 + j;
            sides.SLCOS[sideidx] = sides.SIDE[sideidx] * sides.COSF[sideidx];
            sides.SLSIN[sideidx] = sides.SIDE[sideidx] * sides.SINF[sideidx];
        }
    }
}

void MeshData::take_boundary_for_two_d(const std::string& filePath){

    Real STIME = 0, STIME1;
    std::string pointname;
    std::string current_line;

    int NZTEMP, NQTEMP, NHQTEMP;
    ZT.resize(NZ, vector<Real>(NDAYS));

    for (int k = 1; k <= NNZ0; k++) {
        std::stringstream ss;
        ss << std::setfill('0') << std::setw(4) << k;
        pointname = filePath + "BOUNDE/NZ/NZ" + ss.str() + ".DAT";
        std::cout << pointname << std::endl;

        std::ifstream NZ_file(pointname);
        io::AssertFileOpen(NZ_file, pointname);

        std::getline(NZ_file, current_line);
        NZTEMP = io::readFromLine<int>(current_line);
        
        Vec QZSTIME1(NZTEMP, 0);
        Vec QZSTEMP1(NZTEMP, 0);
        for (int i = 0; i < NZTEMP; i++) {
            std::getline(NZ_file, current_line);
            std::istringstream iss(current_line);
            iss >> QZSTIME1[i];
            iss >> QZSTEMP1[i];
        }
        for (int i = 0; i < NDAYS; i++) {
            STIME1 = STIME + i / (24.0 * 3600.0 / MDT);
            float ZTTEMP = BOUNDRYinterp(STIME1, NZTEMP, QZSTIME1, QZSTEMP1);
            for (int j = 0; j < NZ; j++) {
                if (NNZ[j] == k)
                    ZT[j][i] = ZTTEMP;
            }
        }
    }

    QT.resize(NQ, vector<Real>(NDAYS));
    printf("------------------------ NQ=%d, NDAYS=%d ---------------------------\n", NQ, NDAYS);
    for (int k = 1; k <= NNQ0; k++) {
        std::stringstream ss;
        ss << std::setfill('0') << std::setw(4) << k;
        pointname = filePath + "BOUNDE/NQ/NQ" + ss.str() + ".DAT";
        std::cout << pointname << std::endl;

        std::ifstream NQ_file(pointname);
        io::AssertFileOpen(NQ_file, pointname);
        std::getline(NQ_file, current_line);
        NQTEMP = io::readFromLine<int>(current_line);
        Vec QZSTIME2(NQTEMP, 0);
        Vec QZSTEMP2(NQTEMP, 0);

        int kl = 0;
        for (int j = 1; j <= NQ; j++) {
            if(k == NNQ[j - 1]) kl++;
        }

        for (int i = 0; i < NQTEMP; i++) {
            std::getline(NQ_file, current_line);
            std::istringstream iss(current_line);
            iss >> QZSTIME2[i];
            iss >> QZSTEMP2[i];
        }

        for (int i = 0; i < NDAYS; i++) {
            STIME1 = STIME + i / (24.0 * 3600.0 / MDT);
            float QTTEMP = BOUNDRYinterp(STIME1, NQTEMP, QZSTIME2, QZSTEMP2);
            for (int j = 0; j < NQ; j++) {
                if (NNQ[j] == k)
                    QT[j][i] = QTTEMP / kl;
            }
        }
    }

    // TODO: DT, QT 预处理插值, 提前计算
    int K0 = MDT / DT;
    DZT.resize(NZ, vector<Real>(NDAYS, 0));
    DQT.resize(NQ, vector<Real>(NDAYS, 0));

    for (int jt = 0; jt < NDAYS; jt++) {
        for (int l = 0; l < NZ; l++) {
            if (jt != NDAYS - 1) {
                DZT[l][jt] = (ZT[l][jt + 1] - ZT[l][jt]) / K0;
            }
        }
        for (int l = 0; l < NQ; l++) {
            if (jt != NDAYS - 1) {
                DQT[l][jt] = (QT[l][jt + 1] - QT[l][jt]) / K0;
            }
        }
    }

    printf("------------------------ NNZQ0=%d, NZQ=%d ---------------------------\n", NNZQ0, NZQ);
    cells.NHQ1.resize(NZQ, 0);
    cells.ZW.resize(NHQ, std::vector<Real>(NZQ));
    cells.QW.resize(NHQ, std::vector<Real>(NZQ));
    for (int k = 1; k <= NNZQ0; k++) {
        std::stringstream ss;
        ss << std::setfill('0') << std::setw(4) << k;
        pointname = filePath + "BOUNDE/NZQ/NZQ" + ss.str() + ".DAT";
        std::cout << pointname << std::endl;

        std::ifstream NZQ_file(pointname);
        io::AssertFileOpen(NZQ_file, pointname);
        std::getline(NZQ_file, current_line);

        NHQTEMP = io::readFromLine<int>(current_line);
        Vec ZQTEMP2(NHQ, 0);
        Vec QZTEMP2(NHQ, 0);
        Vec AQZH0(NZQ, 0);
        Vec AQZH1(NHQ, 0);

        for (int i = 0; i < NHQTEMP; i++) {        //读入每条水位流量关系线上的Z和Q
            std::getline(NZQ_file, current_line);
            std::istringstream iss(current_line);
            iss >> ZQTEMP2[i];
            iss >> QZTEMP2[i];
            //printf("%d, %d ,%f ,%f----\n", i, NHQTEMP, ZQTEMP2[i], QZTEMP2[i]);

            for (int j = 0; j < NZQ; j++) {                     //开始所以水位流量关系线循环   
                if (NNZQ[j] == k) {                             //判断单元是否在这条线上
                  int MBZQTEMP = (int)MBZQ[j] - 1;              //如果单元在线上，给出单元序号
                  cells.NHQ1[j] = NHQTEMP;                      //将次水位流量关系线的点数量赋值给每个单元     
                  for (int jj = 0; jj < 4; jj++) {              //计算此条线上每个单元对应水位下的过水面积H*SIDE
                      int sidesIdx = MBZQTEMP * 4 + jj;
                      if (sides.KLAS[sidesIdx] == 3) {
                          AQZH0[j] = fmax((ZQTEMP2[i] - cells.ZBC[MBZQTEMP]), HM2) * sides.SIDE[sidesIdx];
                      }
                  }
                  AQZH1[i] += AQZH0[j];                   //计算此条线上每个单元对应水位下的过水面积H*SIDE进行线上累加
                }
            }

            for (int j = 0; j < NZQ; j++) {
                if (NNZQ[j] == k) {
                    cells.ZW[i][j] = ZQTEMP2[i];
                    cells.QW[i][j] = QZTEMP2[i] * AQZH0[j] / AQZH1[i];
                    //printf("------------------------MBZQ=%d,%f-----\n", j, MBZQ[j]);
                    //if ((int)MBZQ[j] == 505) {
                        //printf("------ NZQ=%d, NDAYS=%d,%f ,,%f ,%f,%f-----\n", k, j, MBZQ[j], SIDE[3][MBZQ[j]-1], ZW[i][j], QW[i][j]);
                    //}
                }
            }
        }
    }
}

Real MeshData::BOUNDRYinterp(Real THOURS, int NZQSTEMP, Vec ZQSTIME, Vec ZQSTEMP) {
    Real result = 0;
    for (int i = 1; i <= NZQSTEMP; i++) {
        if (THOURS >= ZQSTIME[i - 1] && THOURS <= ZQSTIME[i]) {
            result = ZQSTEMP[i-1] + (ZQSTEMP[i] - ZQSTEMP[i - 1]) /
                (ZQSTIME[i] - ZQSTIME[i - 1]) *
                (THOURS - ZQSTIME[i - 1]);
        }
    }
    return result;
}

void MeshData::outputToFile(int jt, int kt){
    if (!SIDE_file.is_open() || !ZUV_file.is_open() || !H2U2V2_file.is_open() || !XY_TEC_file.is_open() || !TIMELOG_file.is_open()) {
            std::cerr << "BAD FILE OUTPUT" << std::endl;
            exit(1);
    }
    
    // 优化：设置更大的缓冲区以减少系统调用
    const size_t buffer_size = 2 * 1024 * 1024; // 2MB 缓冲区
    static char h2u2v2_buffer[buffer_size];
    static char zuv_buffer[buffer_size];
    static char xytec_buffer[buffer_size * 2]; // XY_TEC 需要更大缓冲区
    
    H2U2V2_file.rdbuf()->pubsetbuf(h2u2v2_buffer, buffer_size);
    ZUV_file.rdbuf()->pubsetbuf(zuv_buffer, buffer_size);
    XY_TEC_file.rdbuf()->pubsetbuf(xytec_buffer, buffer_size * 2);
    
    // 首次输出预处理特征数据
    if(jt== 0 && kt==1){
        SIDE_file << "COSF" << std::endl;
        for (int i = 0; i < CELL; i++) {
            SIDE_file << i + 1 << "    ";
            for (int k = 0; k < 4; k++) {
                SIDE_file << sides.COSF[4 * i + k] << "     ";
            }
            SIDE_file << std::endl;
        }
        SIDE_file << "SINF" << std::endl;
        for (int i = 0; i < CELL; i++) {
            SIDE_file << i + 1 << "    ";
            for (int k = 0; k < 4; k++) {
                SIDE_file << sides.SINF[4 * i + k] << "     ";
            }
            SIDE_file << std::endl;
        }
        SIDE_file << "SIDE" << std::endl;
        for (int i = 0; i < CELL; i++) {
            SIDE_file << i + 1 << "    ";
            for (int k = 0; k < 4; k++) {
                SIDE_file << sides.SIDE[4 * i + k] << "     ";
            }
            SIDE_file << std::endl;
        }
        SIDE_file << "AREA" << std::endl;
        for (int i = 0; i < CELL; i++) {
            SIDE_file << i + 1 << "    ";
            SIDE_file << cells.AREA[i] << std::endl;
        }
    }

    int jt2 = jt;
    if(kt != 1){jt2++;}

    H2U2V2_file << " " << std::endl;
    H2U2V2_file << " " << std::endl;
    H2U2V2_file << std::setw(1) << " " << std::setw(3) << "JT=" << std::setw(5)
        << jt2 << std::setw(2) << " " << "KT=" << std::setw(5) << kt - 1
        << std::setw(2) << " " << "DT=" << std::setw(3) << DT
        << std::setw(1) << " "
        << "SEC" << std::setw(2) << " " << "T=" << std::setw(2) << 0
        << std::setw(1) << "H" << std::setw(2) << " "
        << "NSF=" << std::setw(2) << 0 << "/" << 0 << std::setw(2) << " "
        << "WEC=" << std::fixed << std::setprecision(2) << 0 << "/"
        << std::setw(2) << " " << "CQL=" << std::fixed
        << std::setprecision(2) << 0 << std::setw(2) << " "
        << "INE=" << std::setw(1) << 0 << std::endl;



    ZUV_file << " " << std::endl;
    ZUV_file << " " << std::endl;
    ZUV_file << std::setw(1) << " " << std::setw(3) << "JT=" << std::setw(5) << jt2
        << std::setw(2) << " " << "KT=" << std::setw(5) << kt - 1
        << std::setw(2) << " " << "DT=" << std::setw(3) << DT << std::setw(1)
        << " "
        << "SEC" << std::setw(2) << " " << "T=" << std::setw(2) << 0
        << std::setw(1) << "H" << std::setw(2) << " "
        << "NSF=" << std::setw(2) << 0 << "/" << 0 << std::setw(2) << " "
        << "WEC=" << std::fixed << std::setprecision(2) << 0 << "/"
        << std::setw(2) << " " << "CQL=" << std::fixed
        << std::setprecision(2) << 0 << std::setw(2) << " "
        << "INE=" << std::setw(1) << 0 << std::endl;

    // 优化：使用字符串缓冲区批量写入
    std::ostringstream h2_buf;
    h2_buf << "     \n     H2=";
    
    char num_buf[32];
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i > 0) {
            h2_buf << "\n     ";
        }
        if (i % 100 == 0 && i > 0) {
            h2_buf << "\n     ";
        }

        Real H20 = cells.H[i];
        if(cells.H[i] <= HM1){ H20 = 0;}
        
        // 使用 sprintf 替代流格式化，更快
        std::snprintf(num_buf, sizeof(num_buf), "%10.4f", H20);
        h2_buf << num_buf;
    }
    h2_buf << "\n     \n     ";
    H2U2V2_file << h2_buf.str();

    // 优化：U2 数据批量写入
    std::ostringstream u2_buf;
    u2_buf << "U2=";
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i > 0) {
            u2_buf << "\n     ";
        }
        if (i % 100 == 0 && i > 0) {
            u2_buf << "\n     ";
        }

        Real U20 = cells.U[i];
        if(cells.H[i] <= HM1){ U20 = 0;}
        
        std::snprintf(num_buf, sizeof(num_buf), "%10.4f", U20);
        u2_buf << num_buf;
    }
    u2_buf << "\n     \n     ";
    H2U2V2_file << u2_buf.str();

    // 优化：V2 数据批量写入
    std::ostringstream v2_buf;
    v2_buf << "V2=";
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i > 0) {
            v2_buf << "\n     ";
        }
        if (i % 100 == 0 && i > 0) {
            v2_buf << "\n     ";
        }

        Real V20 = cells.V[i];
        if(cells.H[i] <= HM1){ V20 = 0;}
        
        std::snprintf(num_buf, sizeof(num_buf), "%10.4f", V20);
        v2_buf << num_buf;
    }
    v2_buf << " \n";
    H2U2V2_file << v2_buf.str();

    H2U2V2_file << " " << std::endl;

    // 优化：ZUV 数据批量写入
    std::ostringstream zuv_buf;
    zuv_buf << "     \n     Z2=";
    
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i > 0) {
            zuv_buf << "\n     ";
        }
        if (i % 100 == 0 && i > 0) {
            zuv_buf << "\n     ";
        }

        Real Z20 = cells.Z[i];
        if(cells.H[i] <= HM1){ Z20 = cells.ZBC[i];}
        
        std::snprintf(num_buf, sizeof(num_buf), "%10.4f", Z20);
        zuv_buf << num_buf;
    }
    zuv_buf << "\n     \n     W2=";
    
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i > 0) {
            zuv_buf << "\n     ";
        }
        if (i % 100 == 0 && i > 0) {
            zuv_buf << "\n     ";
        }

        float W2 = 0;
        if(cells.H[i] > HM1){ W2 = std::sqrt(cells.U[i]*cells.U[i] + cells.V[i]*cells.V[i]);}
        
        std::snprintf(num_buf, sizeof(num_buf), "%10.4f", W2);
        zuv_buf << num_buf;
    }
    zuv_buf << "\n     \n     FI=";
    
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i > 0) {
            zuv_buf << "\n     ";
        }
        if (i % 100 == 0 && i > 0) {
            zuv_buf << "\n     ";
        }

        Real FI2 = 0;
        if(cells.H[i] > HM1){ 
            Real U20 = cells.U[i];
            Real V20 = cells.V[i];
            if(cells.H[i] <= HM1){ U20 = 0; V20 = 0;}
            FI2= FI(U20,V20)*(Real)57.298;
        }
        
        std::snprintf(num_buf, sizeof(num_buf), "%10.4f", FI2);
        zuv_buf << num_buf;
    }
    zuv_buf << " \n";
    ZUV_file << zuv_buf.str();


    Real jt3 = (Real)jt2 / NDAYS;
    TIMELOG_file << std::fixed << std::setprecision(4) << jt3 << std::endl;

    XY_TEC_file
        << " VARIABLES = \"X\", \"Y\", \"H2\", \"Z2\",\"U2\",\"V2\",\"W2\""
        << std::endl;
    XY_TEC_file
        << "ZONE N=" << NOD << ", E=" << CELL << ", DATAPACKING=BLOCK, ZONETYPE=FEQUADRILATERAL"
        << std::endl;
    XY_TEC_file << "VARLOCATION=([3-7]=CELLCENTERED)" << std::endl;


    // 优化：XY_TEC 数据批量写入
    std::ostringstream xytec_buf;
    xytec_buf.precision(4);
    xytec_buf << std::fixed;
    
    // X 坐标
    for (int i = 0; i < NOD; i++) {
        if (i % 10 == 0 && i != 0) {
            xytec_buf << "\n";
        }
        std::snprintf(num_buf, sizeof(num_buf), "%.4f ", XP[i] + XIMIN);
        xytec_buf << num_buf;
    }
    xytec_buf << "\n";
    
    // Y 坐标
    for (int i = 0; i < NOD; i++) {
        if (i % 10 == 0 && i != 0) {
            xytec_buf << "\n";
        }
        std::snprintf(num_buf, sizeof(num_buf), "%.4f ", YP[i] + YIMIN);
        xytec_buf << num_buf;
    }
    xytec_buf << "\n";
    
    // H2
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i != 0) {
            xytec_buf << "\n";
        }
        Real H20 = cells.H[i];
        if(H20 <= HM1){ H20 = 0;}
        std::snprintf(num_buf, sizeof(num_buf), "%.4f ", H20);
        xytec_buf << num_buf;
    }
    
    // Z2
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i != 0) {
            xytec_buf << "\n";
        }
        Real Z20 = cells.Z[i];
        if(cells.H[i] <= HM1){ Z20 = cells.ZBC[i];}
        std::snprintf(num_buf, sizeof(num_buf), "%.4f ", Z20);
        xytec_buf << num_buf;
    }
    xytec_buf << "\n";
    
    // U2
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i != 0) {
            xytec_buf << "\n";
        }
        Real U20 = cells.U[i];
        if(cells.H[i] <= HM1){ U20 = 0;}
        std::snprintf(num_buf, sizeof(num_buf), "%.4f ", U20);
        xytec_buf << num_buf;
    }
    xytec_buf << "\n";
    
    // V2
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i != 0) {
            xytec_buf << "\n";
        }
        Real V20 = cells.V[i];
        if(cells.H[i] <= HM1){ V20 = 0;}
        std::snprintf(num_buf, sizeof(num_buf), "%.4f ", V20);
        xytec_buf << num_buf;
    }
    xytec_buf << "\n";
    
    // W2
    for (int i = 0; i < CELL; i++) {
        if (i % 10 == 0 && i != 0) {
            xytec_buf << "\n";
        }
        float W2 = 0;
        if(cells.H[i] > HM1){ W2 = std::sqrt(cells.U[i] * cells.U[i] + cells.V[i] * cells.V[i]);}
        std::snprintf(num_buf, sizeof(num_buf), "%.4f ", W2);
        xytec_buf << num_buf;
    }
    xytec_buf << "\n";
    
    XY_TEC_file << xytec_buf.str();

    for (int i = 0; i < CELL; i++) {
        for (int k = 0; k < 4; k++) {
            XY_TEC_file << NAP[k][i] << " ";
        }
        XY_TEC_file << std::endl;
    }
}

Real MeshData::FI(Real X, Real Y) {
    Real W, FI, MPI = 3.1416;

    // Check if X and Y are not both zero
    if (X * Y != 0.0) {
        W = atan2(fabs(Y), fabs(X));  // Compute angle using atan2
        if (X * Y > 0.0) {
            if (X > 0.0) {
                FI = W;  // First quadrant or third quadrant
            } else {
                FI = MPI + W;  // Second quadrant
            }
        } else {
            if (Y > 0.0) {
                FI = MPI - W;  // Fourth quadrant
            } else {
                FI = 2 * MPI - W;  // Third quadrant
            }
        }
    } else {
        // Handle special cases where one or both values are zero
        if (X == 0.0 && Y >= 0.0) FI = MPI / 2;  // 90 degrees
        if (X == 0.0 && Y < 0.0) FI = 3 * MPI / 2; // 270 degrees
        if (Y == 0.0 && X >= 0.0) FI = 0.0;        // 0 degrees
        if (Y == 0.0 && X < 0.0) FI = MPI;        // 180 degrees
    }

    return FI;  // Return the computed angle
}

// ------------------- MeshView -------------------

// Host -> Device
void MeshView::FromHost(const MeshData& meshData) {

    cells.FromHost(meshData);
    sides.FromHost(meshData);
}

// Device -> Host
void MeshView::ToHost(MeshData& meshData) const {
    cells.ToHost(meshData);
    sides.ToHost(meshData);
}
