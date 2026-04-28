#include "functors.cuh"
#include "mesh/side.hpp"
#include "mesh/cell.hpp"
#include "mesh/mesh.hpp"
#include <cstdio>
#include <ctime>
#include <string>


//--------------------------------------
// 普通版本的时间步仿真
//--------------------------------------
void RunSimulation(MeshView& mesh_view, MeshData& mesh_data,
                   int total_days, int steps_per_day) {
    for (int day = 0; day < total_days; day++) {

        clock_t start_time = clock();

        for (int step = 1; step < steps_per_day; step++) {
            // 计算边通量
            CalculateFlux(mesh_view, step, day);

            // 更新单元格状态
            UpdateCell(mesh_view, step, day);
        }

        clock_t end_time = clock();
        double compute_duration = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;

        // 输出结果
        double copy_duration = 0.0;
        double io_duration = 0.0;
        if ((day + 1) % mesh_data.NTOUTPUT == 0) {
            clock_t copy_start = clock();
            mesh_view.ToHost(mesh_data);
            clock_t copy_end = clock();
            copy_duration = ((double)(copy_end - copy_start)) / CLOCKS_PER_SEC;

            clock_t io_start = clock();
            mesh_data.outputToFile(day, steps_per_day - 1);
            clock_t io_end = clock();
            io_duration = ((double)(io_end - io_start)) / CLOCKS_PER_SEC;
        }

        double total_duration = compute_duration + copy_duration + io_duration;
        printf("Day %d / %d Done. Compute: %.6f s, Copy: %.6f s, I/O: %.6f s, Total: %.6f s\n",
               day + 1, total_days, compute_duration, copy_duration, io_duration, total_duration);
    }
}


//--------------------------------------
// CUDA Graph 版本的仿真
//--------------------------------------
void RunSimulationGraph(MeshView& mesh_view, MeshData& mesh_data,
                        int total_days, int steps_per_day) {
    cudaGraph_t graph;
    cudaGraphExec_t graphExec;
    cudaStream_t stream;

    CUDA_CHECK(cudaStreamCreateWithFlags(&stream, cudaStreamNonBlocking));

    bool graphCreated = false;

    for (int day = 0; day < total_days; ++day) {
        clock_t start_time = clock();

        if (!graphCreated) {
            CUDA_CHECK(cudaStreamBeginCapture(stream, cudaStreamCaptureModeGlobal));

            for (int step = 1; step < steps_per_day; ++step) {
                // 捕获阶段传入同一个 stream
                CalculateFlux(mesh_view, step, day, stream);
                UpdateCell(mesh_view, step, day, stream);
            }

            CUDA_CHECK(cudaStreamEndCapture(stream, &graph));
            CUDA_CHECK(cudaGraphInstantiate(&graphExec, graph, NULL, NULL, 0));
            graphCreated = true;
        }

        // 启动 Graph（等价于执行多个 Kernel 串联）
        CUDA_CHECK(cudaGraphLaunch(graphExec, stream));
        CUDA_CHECK(cudaStreamSynchronize(stream));

        clock_t end_time = clock();
        double compute_duration = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;

        // 输出结果
        double copy_duration = 0.0;
        double io_duration = 0.0;
        if ((day + 1) % mesh_data.NTOUTPUT == 0) {
            clock_t copy_start = clock();
            mesh_view.ToHost(mesh_data);
            clock_t copy_end = clock();
            copy_duration = ((double)(copy_end - copy_start)) / CLOCKS_PER_SEC;

            clock_t io_start = clock();
            mesh_data.outputToFile(day, steps_per_day - 1);
            clock_t io_end = clock();
            io_duration = ((double)(io_end - io_start)) / CLOCKS_PER_SEC;
        }

        double total_duration = compute_duration + copy_duration + io_duration;
        printf("Day %d / %d Done. Compute: %.6f s, Copy: %.6f s, I/O: %.6f s, Total: %.6f s\n",
               day + 1, total_days, compute_duration, copy_duration, io_duration, total_duration);
    }

    // 释放资源
    CUDA_CHECK(cudaGraphExecDestroy(graphExec));
    CUDA_CHECK(cudaGraphDestroy(graph));
    CUDA_CHECK(cudaStreamDestroy(stream));
}


//--------------------------------------
// 主函数入口
//--------------------------------------
int main(int argc, char* argv[]) {
    // 检查参数：如果第一个参数不是 --graph，则作为数据路径
    std::string model_data_path = "../../";
    bool useGraph = false;
    
    if (argc > 1) {
        if (std::string(argv[1]) == "--graph") {
            useGraph = true;
        } else {
            model_data_path = argv[1];
            if (argc > 2 && std::string(argv[2]) == "--graph") {
                useGraph = true;
            }
        }
    }
    
    // 确保路径以 / 结尾
    if (model_data_path.back() != '/') {
        model_data_path += "/";
    }

    // 1. 初始化 Mesh 数据（Host）
    MeshData mesh_data(model_data_path);

    // 强制每天输出
    mesh_data.NTOUTPUT = 1;

    // 2. 创建 Device 端 MeshView
    MeshView mesh_view(mesh_data);

    printf(mesh_data.NTOUTPUT == 1 ? 
        "Output every day.\n" : 
        "Output every %d days.\n", mesh_data.NTOUTPUT);

    // 3. 定义时间步参数
    int total_days = mesh_data.NDAYS;                  // 总天数
    int steps_per_day = mesh_data.MDT / mesh_data.DT;  // 每天的步数

    // 输出初始状态
    mesh_data.outputToFile(0, 0);

    // 4. 选择运行模式（已在上面解析）
    if (useGraph) {
        printf("Running with CUDA Graph optimization...\n");
        RunSimulationGraph(mesh_view, mesh_data, total_days, steps_per_day);
    } else {
        printf("Running with standard simulation loop...\n");
        RunSimulation(mesh_view, mesh_data, total_days, steps_per_day);
    }

    return 0;
}
