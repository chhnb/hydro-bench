/**
 * F2 Hydro-Cal Native Benchmark — EXACT copy of original hydro-cal kernel code.
 *
 * All hydro-cal source files are copied into hydro-cal-src/ (no external dependency).
 * Kernel code is bit-identical to the original implementation.
 *
 * Build:
 *   cd F2_hydro_native && bash build.sh
 *
 * Run (from hydro-cal root, where BINFOR/ etc. exist):
 *   cd /home/scratch.huanhuanc_gpu/spmd/hydro-cal
 *   /path/to/F2_hydro_native/hydro_native_benchmark [steps] [repeat] [--dump file.bin]
 */

#include "functors.cuh"
#include "mesh/mesh.hpp"
#include <cuda_runtime.h>
#include <cstdio>
#include <cstring>
#include <chrono>
#include <vector>
#include <algorithm>
#include <string>

int main(int argc, char* argv[]) {
    // Parse args
    int steps = 899;    // default: 1 day
    int repeat = 10;
    bool do_dump = false;
    std::string dump_file = "native_state.bin";

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--dump") == 0 && i + 1 < argc) {
            do_dump = true;
            dump_file = argv[++i];
        } else if (i == 1) {
            steps = atoi(argv[i]);
        } else if (i == 2) {
            repeat = atoi(argv[i]);
        }
    }

    // Load mesh from original data path (expects to run from hydro-cal root)
    const std::string model_data_path = "../";
    MeshData mesh_data(model_data_path);
    MeshView mesh_view(mesh_data);

    int CELL = mesh_data.CELL;
    int steps_per_day = mesh_data.MDT / mesh_data.DT;

    printf("=== F2 Hydro-Cal Native Benchmark (original kernel code) ===\n");
    printf("CELL=%d, steps=%d, steps_per_day=%d, repeat=%d\n",
           CELL, steps, steps_per_day, repeat);

    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    printf("GPU: %s, SMs=%d\n\n", prop.name, prop.multiProcessorCount);

    // Helper: save current H/U/V/Z to host vectors for state reset
    auto saveState = [&](std::vector<float>& sH, std::vector<float>& sU,
                         std::vector<float>& sV, std::vector<float>& sZ) {
        mesh_view.ToHost(mesh_data);
        sH.assign(mesh_data.cells.H.begin(), mesh_data.cells.H.end());
        sU.assign(mesh_data.cells.U.begin(), mesh_data.cells.U.end());
        sV.assign(mesh_data.cells.V.begin(), mesh_data.cells.V.end());
        sZ.assign(mesh_data.cells.Z.begin(), mesh_data.cells.Z.end());
    };

    // Helper: restore state from host vectors
    auto restoreState = [&](const std::vector<float>& sH, const std::vector<float>& sU,
                            const std::vector<float>& sV, const std::vector<float>& sZ) {
        std::copy(sH.begin(), sH.end(), mesh_data.cells.H.begin());
        std::copy(sU.begin(), sU.end(), mesh_data.cells.U.begin());
        std::copy(sV.begin(), sV.end(), mesh_data.cells.V.begin());
        std::copy(sZ.begin(), sZ.end(), mesh_data.cells.Z.begin());
        // Re-upload to device
        mesh_view.FromHost(mesh_data);
    };

    // Helper: run N steps using the original kernels
    auto runSteps = [&](int n) {
        int s = 0;
        for (int day = 0; day < mesh_data.NDAYS && s < n; day++) {
            for (int kt = 1; kt < steps_per_day && s < n; kt++) {
                CalculateFlux(mesh_view, kt, day);
                UpdateCell(mesh_view);
                s++;
            }
        }
    };

    // Save initial state for reset between runs
    std::vector<float> init_H, init_U, init_V, init_Z;
    saveState(init_H, init_U, init_V, init_Z);

    // ===== Dump mode =====
    if (do_dump) {
        printf("Running %d steps and dumping to %s...\n", steps, dump_file.c_str());
        runSteps(steps);
        CUDA_CHECK(cudaDeviceSynchronize());

        mesh_view.ToHost(mesh_data);
        FILE* f = fopen(dump_file.c_str(), "wb");
        fwrite(&CELL, sizeof(int), 1, f);
        fwrite(mesh_data.cells.H.data(), sizeof(float), CELL, f);
        fwrite(mesh_data.cells.U.data(), sizeof(float), CELL, f);
        fwrite(mesh_data.cells.V.data(), sizeof(float), CELL, f);
        fwrite(mesh_data.cells.Z.data(), sizeof(float), CELL, f);
        const int NSIDES = CELL * 4;
        fwrite(mesh_data.sides.SLCOS.data(), sizeof(float), NSIDES, f);
        fwrite(mesh_data.sides.SLSIN.data(), sizeof(float), NSIDES, f);
        fwrite(mesh_data.sides.SIDE.data(),  sizeof(float), NSIDES, f);
        std::vector<Real> flux0(NSIDES), flux1(NSIDES), flux2(NSIDES), flux3(NSIDES);
        cudaMemcpy(flux0.data(), mesh_view.sides.FLUX0, NSIDES*sizeof(Real), cudaMemcpyDeviceToHost);
        cudaMemcpy(flux1.data(), mesh_view.sides.FLUX1, NSIDES*sizeof(Real), cudaMemcpyDeviceToHost);
        cudaMemcpy(flux2.data(), mesh_view.sides.FLUX2, NSIDES*sizeof(Real), cudaMemcpyDeviceToHost);
        cudaMemcpy(flux3.data(), mesh_view.sides.FLUX3, NSIDES*sizeof(Real), cudaMemcpyDeviceToHost);
        fwrite(flux0.data(), sizeof(float), NSIDES, f);
        fwrite(flux1.data(), sizeof(float), NSIDES, f);
        fwrite(flux2.data(), sizeof(float), NSIDES, f);
        fwrite(flux3.data(), sizeof(float), NSIDES, f);
        fclose(f);
        printf("Dumped %d cells.\n", CELL);

        float hmin = *std::min_element(mesh_data.cells.H.begin(), mesh_data.cells.H.end());
        float hmax = *std::max_element(mesh_data.cells.H.begin(), mesh_data.cells.H.end());
        printf("H range: [%.6f, %.6f]\n", hmin, hmax);
        return 0;
    }

    // ===== Sync loop benchmark =====
    printf("--- Sync Loop ---\n");
    {
        // Warmup
        restoreState(init_H, init_U, init_V, init_Z);
        runSteps(std::min(steps, 10));
        CUDA_CHECK(cudaDeviceSynchronize());

        std::vector<double> times;
        for (int r = 0; r < repeat; r++) {
            restoreState(init_H, init_U, init_V, init_Z);
            CUDA_CHECK(cudaDeviceSynchronize());

            auto t0 = std::chrono::high_resolution_clock::now();
            int s = 0;
            for (int day = 0; day < mesh_data.NDAYS && s < steps; day++) {
                for (int kt = 1; kt < steps_per_day && s < steps; kt++) {
                    CalculateFlux(mesh_view, kt, day);
                    UpdateCell(mesh_view);
                    CUDA_CHECK(cudaDeviceSynchronize());
                    s++;
                }
            }
            auto t1 = std::chrono::high_resolution_clock::now();
            times.push_back(std::chrono::duration<double, std::milli>(t1 - t0).count());
        }
        std::sort(times.begin(), times.end());
        double median = times[repeat / 2];
        printf("Sync:  median=%.3f ms, %.2f us/step\n", median, median / steps * 1000.0);
    }

    // ===== Async loop benchmark =====
    printf("\n--- Async Loop ---\n");
    {
        restoreState(init_H, init_U, init_V, init_Z);
        runSteps(std::min(steps, 10));
        CUDA_CHECK(cudaDeviceSynchronize());

        std::vector<double> times;
        for (int r = 0; r < repeat; r++) {
            restoreState(init_H, init_U, init_V, init_Z);
            CUDA_CHECK(cudaDeviceSynchronize());

            auto t0 = std::chrono::high_resolution_clock::now();
            runSteps(steps);
            CUDA_CHECK(cudaDeviceSynchronize());
            auto t1 = std::chrono::high_resolution_clock::now();
            times.push_back(std::chrono::duration<double, std::milli>(t1 - t0).count());
        }
        std::sort(times.begin(), times.end());
        double median = times[repeat / 2];
        printf("Async: median=%.3f ms, %.2f us/step\n", median, median / steps * 1000.0);
    }

    // ===== CUDA Graph benchmark =====
    printf("\n--- CUDA Graph ---\n");
    {
        restoreState(init_H, init_U, init_V, init_Z);

        cudaStream_t stream;
        CUDA_CHECK(cudaStreamCreate(&stream));
        cudaGraph_t graph;
        cudaGraphExec_t graphExec;

        // Capture one step (kt=1, day=0 — fixed for graph replay)
        CUDA_CHECK(cudaStreamBeginCapture(stream, cudaStreamCaptureModeGlobal));
        CalculateFlux(mesh_view, 1, 0, stream);
        UpdateCell(mesh_view, stream);
        CUDA_CHECK(cudaStreamEndCapture(stream, &graph));
        CUDA_CHECK(cudaGraphInstantiate(&graphExec, graph, nullptr, nullptr, 0));

        // Warmup
        for (int s = 0; s < 20; s++)
            CUDA_CHECK(cudaGraphLaunch(graphExec, stream));
        CUDA_CHECK(cudaStreamSynchronize(stream));

        std::vector<double> times;
        for (int r = 0; r < repeat; r++) {
            restoreState(init_H, init_U, init_V, init_Z);
            CUDA_CHECK(cudaStreamSynchronize(stream));

            auto t0 = std::chrono::high_resolution_clock::now();
            for (int s = 0; s < steps; s++)
                CUDA_CHECK(cudaGraphLaunch(graphExec, stream));
            CUDA_CHECK(cudaStreamSynchronize(stream));
            auto t1 = std::chrono::high_resolution_clock::now();
            times.push_back(std::chrono::duration<double, std::milli>(t1 - t0).count());
        }
        std::sort(times.begin(), times.end());
        double median = times[repeat / 2];
        printf("Graph: median=%.3f ms, %.2f us/step\n", median, median / steps * 1000.0);

        CUDA_CHECK(cudaGraphExecDestroy(graphExec));
        CUDA_CHECK(cudaGraphDestroy(graph));
        CUDA_CHECK(cudaStreamDestroy(stream));
    }

    // ===== Final state dump for verification =====
    printf("\n--- State after %d steps (async) ---\n", steps);
    {
        restoreState(init_H, init_U, init_V, init_Z);
        runSteps(steps);
        CUDA_CHECK(cudaDeviceSynchronize());
        mesh_view.ToHost(mesh_data);
        float hmin = *std::min_element(mesh_data.cells.H.begin(), mesh_data.cells.H.end());
        float hmax = *std::max_element(mesh_data.cells.H.begin(), mesh_data.cells.H.end());
        printf("H range: [%.6f, %.6f]\n", hmin, hmax);
    }

    return 0;
}
