/**
 * Taichi + Persistent (cooperative kernel) benchmark.
 *
 * Usage:
 *   ./persistent_bench <data_dir> <NE> <CELL> <fp32|fp64> [nsteps=900] [nruns=10] [max_regs=0]
 *
 * The data_dir must contain:
 *   - flux_func.ptx  (converted from flux_raw.ptx via ptx_entry_to_func.py)
 *   - update_func.ptx
 *   - flux_raw.ptx   (for Graph baseline, unchanged .entry form)
 *   - update_raw.ptx
 *   - NAC.bin, KLAS.bin, ..., DZT.bin  (22 field binaries)
 *
 * and a driver.ptx in the persistent_poc root.
 */
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <string>
#include <vector>
#include <algorithm>
#include <cuda.h>
#include <cuda_runtime.h>

#define CK(x) do { CUresult e = (x); \
    if (e) { const char* err = 0; cuGetErrorString(e, &err); \
             printf("CU err %d at %d: %s\n", e, __LINE__, err ? err : "?"); exit(1); } \
    } while (0)

static void* read_file(const char* path, size_t* out_sz) {
    FILE* f = fopen(path, "rb");
    if (!f) { printf("Cannot open %s\n", path); exit(1); }
    fseek(f, 0, SEEK_END); long sz = ftell(f); fseek(f, 0, SEEK_SET);
    char* buf = (char*)malloc(sz + 1);
    if (fread(buf, 1, sz, f) != (size_t)sz) { printf("fread short read %s\n", path); exit(1); }
    buf[sz] = 0; fclose(f);
    if (out_sz) *out_sz = sz;
    return buf;
}

int main(int argc, char** argv) {
    if (argc < 5) {
        printf("Usage: %s <data_dir> <NE> <CELL> <fp32|fp64> [nsteps=900] [nruns=10] [max_regs=0]\n", argv[0]);
        return 1;
    }
    const char* data_dir = argv[1];
    int NE = atoi(argv[2]);
    int CELL = atoi(argv[3]);
    const char* prec = argv[4];
    int fp_sz = (strcmp(prec, "fp64") == 0) ? 8 : 4;
    int nsteps = argc > 5 ? atoi(argv[5]) : 900;
    int nruns  = argc > 6 ? atoi(argv[6]) : 10;
    int max_regs = argc > 7 ? atoi(argv[7]) : 0;

    const char* POC_ROOT = getenv("HYDRO_BENCH_CUDA_DIR") ? getenv("HYDRO_BENCH_CUDA_DIR") : ".";

    CK(cuInit(0));
    CUdevice dev; CK(cuDeviceGet(&dev, 0));
    CUcontext ctx; CK(cuCtxCreate(&ctx, 0, dev));

    // ----- cuLink driver + flux_func + update_func -----
    CUlinkState link;
    CUjit_option opts[4]; void* vals[4]; int nopts = 0;
    opts[nopts] = CU_JIT_LOG_VERBOSE; vals[nopts] = (void*)(uintptr_t)1; nopts++;
    if (max_regs > 0) {
        opts[nopts] = CU_JIT_MAX_REGISTERS;
        vals[nopts] = (void*)(uintptr_t)max_regs;
        nopts++;
    }
    CK(cuLinkCreate(nopts, opts, vals, &link));

    size_t sz; void* data;
    std::string driver_path = std::string(POC_ROOT) + "/driver.ptx";
    std::string flux_path   = std::string(data_dir) + "/flux_func.ptx";
    std::string update_path = std::string(data_dir) + "/update_func.ptx";
    std::string flux_raw    = std::string(data_dir) + "/flux_raw.ptx";
    std::string update_raw  = std::string(data_dir) + "/update_raw.ptx";

    data = read_file(driver_path.c_str(), &sz);
    CK(cuLinkAddData(link, CU_JIT_INPUT_PTX, data, sz, "driver", 0, 0, 0)); free(data);
    data = read_file(flux_path.c_str(), &sz);
    CK(cuLinkAddData(link, CU_JIT_INPUT_PTX, data, sz, "flux", 0, 0, 0)); free(data);
    data = read_file(update_path.c_str(), &sz);
    CK(cuLinkAddData(link, CU_JIT_INPUT_PTX, data, sz, "update", 0, 0, 0)); free(data);

    void* cubin; size_t cubin_sz;
    CK(cuLinkComplete(link, &cubin, &cubin_sz));

    CUmodule mod; CK(cuModuleLoadData(&mod, cubin));
    CK(cuLinkDestroy(link));

    CUfunction persistent_fn;
    CK(cuModuleGetFunction(&persistent_fn, mod, "persistent_driver"));

    int pd_regs;
    cuFuncGetAttribute(&pd_regs, CU_FUNC_ATTRIBUTE_NUM_REGS, persistent_fn);

    // ----- Load 22 fields -----
    // Read NDAYS from meta.json (different per mesh: 50 for 20w, 2000 for default)
    int NDAYS = 50;
    {
        std::string mp = std::string(data_dir) + "/meta.json";
        FILE* mf = fopen(mp.c_str(), "r");
        if (mf) {
            char buf[1024] = {0};
            (void)fread(buf, 1, sizeof(buf) - 1, mf); fclose(mf);
            const char* p = strstr(buf, "\"NDAYS\"");
            if (p) sscanf(p, "\"NDAYS\": %d", &NDAYS);
        }
        printf("NDAYS=%d\n", NDAYS);
    }
    // NAC is always i32 (4 bytes); rest are fp_sz bytes.
    size_t sizes[] = {
        (size_t)NE*4,                         // NAC
        (size_t)NE*fp_sz,(size_t)NE*fp_sz,(size_t)NE*fp_sz,(size_t)NE*fp_sz,
        (size_t)NE*fp_sz,(size_t)NE*fp_sz,                                   // SIDE..SLSIN
        (size_t)NE*fp_sz,(size_t)NE*fp_sz,(size_t)NE*fp_sz,(size_t)NE*fp_sz, // FLUX0..FLUX3
        (size_t)CELL*fp_sz,(size_t)CELL*fp_sz,(size_t)CELL*fp_sz,(size_t)CELL*fp_sz,
        (size_t)CELL*fp_sz,(size_t)CELL*fp_sz,(size_t)CELL*fp_sz,
        (size_t)CELL*fp_sz,(size_t)CELL*fp_sz,                               // H..FNC
        (size_t)NDAYS*CELL*fp_sz,(size_t)NDAYS*CELL*fp_sz                    // ZT, DZT
    };
    const char* names[] = {"NAC","KLAS","SIDE","COSF","SINF","SLCOS","SLSIN",
                           "FLUX0","FLUX1","FLUX2","FLUX3",
                           "H","U","V","Z","W","ZBC","ZB1","AREA","FNC","ZT","DZT"};
    size_t total = 0; for (int i = 0; i < 22; i++) total += sizes[i];

    char* host = (char*)malloc(total); size_t off = 0;
    for (int i = 0; i < 22; i++) {
        std::string p = std::string(data_dir) + "/" + names[i] + ".bin";
        FILE* f = fopen(p.c_str(), "rb");
        if (!f) { printf("Cannot open %s\n", p.c_str()); exit(1); }
        if (fread(host + off, 1, sizes[i], f) != sizes[i]) {
            printf("Short read %s (expected %zu)\n", p.c_str(), sizes[i]); exit(1);
        }
        fclose(f); off += sizes[i];
    }

    CUdeviceptr base; CK(cuMemAlloc(&base, total));
    CK(cuMemcpyHtoD(base, host, total));

    // ----- Fake RuntimeContext -----
    char fake_rt[512] = {0};
    *(unsigned long long*)(fake_rt + 88) = (unsigned long long)base;
    CUdeviceptr d_rt; CK(cuMemAlloc(&d_rt, 512));
    CK(cuMemcpyHtoD(d_rt, fake_rt, 512));

    int extra_args[2] = {1, 0};
    CUdeviceptr d_ea; CK(cuMemAlloc(&d_ea, 8));
    CK(cuMemcpyHtoD(d_ea, extra_args, 8));

    struct __attribute__((aligned(8))) TaichiArg {
        void* args; void* runtime; int pad, pad2; void* extra_args;
    } arg = { (void*)d_ea, (void*)d_rt, 0, 0, (void*)d_ea };

    // ----- Cooperative launch config -----
    int dev_sms;
    CK(cuDeviceGetAttribute(&dev_sms, CU_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT, dev));
    int max_blocks_per_sm = 0;
    CK(cuOccupancyMaxActiveBlocksPerMultiprocessor(&max_blocks_per_sm, persistent_fn, 128, 0));
    int coop_blocks = dev_sms * max_blocks_per_sm;
    if (coop_blocks < 1) coop_blocks = dev_sms;  // safety

    void* pd_params[] = { &nsteps, &arg };

    // Warmup persistent
    {
        CK(cuMemcpyHtoD(base, host, total));
        int warmup_steps = 10;
        void* warmup_params[] = { &warmup_steps, &arg };
        CK(cuLaunchCooperativeKernel(persistent_fn,
            coop_blocks, 1, 1, 128, 1, 1, 0, 0, warmup_params));
        CK(cuCtxSynchronize());
    }

    std::vector<double> times_persistent;
    for (int r = 0; r < nruns; r++) {
        CK(cuMemcpyHtoD(base, host, total));
        cudaEvent_t start, stop; cudaEventCreate(&start); cudaEventCreate(&stop);
        cudaEventRecord(start);
        CK(cuLaunchCooperativeKernel(persistent_fn,
            coop_blocks, 1, 1, 128, 1, 1, 0, 0, pd_params));
        cudaEventRecord(stop); cudaEventSynchronize(stop);
        float ms; cudaEventElapsedTime(&ms, start, stop);
        times_persistent.push_back(ms * 1000.0 / nsteps);
        cudaEventDestroy(start); cudaEventDestroy(stop);
    }
    std::sort(times_persistent.begin(), times_persistent.end());
    double persistent_us = times_persistent[nruns/2];

    // ----- Graph baseline using raw .entry PTX -----
    CUmodule flux_raw_mod, update_raw_mod;
    data = read_file(flux_raw.c_str(), &sz);
    CK(cuModuleLoadData(&flux_raw_mod, data)); free(data);
    data = read_file(update_raw.c_str(), &sz);
    CK(cuModuleLoadData(&update_raw_mod, data)); free(data);

    CUfunction flux_entry, update_entry;
    CK(cuModuleGetFunction(&flux_entry, flux_raw_mod,
        "calculate_flux_c80_0_kernel_0_range_for"));
    CK(cuModuleGetFunction(&update_entry, update_raw_mod,
        "update_cell_c82_0_kernel_0_range_for"));

    int flux_grid = (NE + 127) / 128;
    int update_grid = (CELL + 127) / 128;
    void* k_params[] = { &arg };

    CUstream stream; CK(cuStreamCreate(&stream, CU_STREAM_NON_BLOCKING));
    CUgraph graph;
    CK(cuStreamBeginCapture(stream, CU_STREAM_CAPTURE_MODE_GLOBAL));
    for (int s = 0; s < nsteps; s++) {
        CK(cuLaunchKernel(flux_entry, flux_grid, 1, 1, 128, 1, 1, 0, stream, k_params, 0));
        CK(cuLaunchKernel(update_entry, update_grid, 1, 1, 128, 1, 1, 0, stream, k_params, 0));
    }
    CK(cuStreamEndCapture(stream, &graph));
    CUgraphExec graphExec; CK(cuGraphInstantiate(&graphExec, graph, 0));

    CK(cuMemcpyHtoD(base, host, total));
    CK(cuGraphLaunch(graphExec, stream));
    CK(cuStreamSynchronize(stream));

    std::vector<double> times_graph;
    for (int r = 0; r < nruns; r++) {
        CK(cuMemcpyHtoD(base, host, total));
        cudaEvent_t st, ed; cudaEventCreate(&st); cudaEventCreate(&ed);
        cudaEventRecord(st, (cudaStream_t)stream);
        CK(cuGraphLaunch(graphExec, stream));
        cudaEventRecord(ed, (cudaStream_t)stream);
        cudaEventSynchronize(ed);
        float ms; cudaEventElapsedTime(&ms, st, ed);
        times_graph.push_back(ms * 1000.0 / nsteps);
        cudaEventDestroy(st); cudaEventDestroy(ed);
    }
    std::sort(times_graph.begin(), times_graph.end());
    double graph_us = times_graph[nruns/2];

    // ----- One-line machine-readable output -----
    printf("CASE_RESULT data=%s prec=%s NE=%d CELL=%d max_regs=%d pd_regs=%d "
           "coop_blocks=%d graph_blocks=%d persistent_us=%.4f graph_us=%.4f ratio=%.4f\n",
        data_dir, prec, NE, CELL, max_regs, pd_regs, coop_blocks, flux_grid + update_grid,
        persistent_us, graph_us, persistent_us / graph_us);

    return 0;
}
