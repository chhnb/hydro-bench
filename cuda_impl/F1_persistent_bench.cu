/**
 * F1 (shallow_water) persistent benchmark.
 * Usage:
 *   ./persistent_bench_f1 <data_dir> <CEL> [nsteps=900] [nruns=10] [max_regs=0]
 *
 * data_dir must contain:
 *   driver_f1.ptx (in POC_ROOT), flux_func.ptx, update_func.ptx (converted from raw)
 *   flux_raw.ptx, update_raw.ptx (for Graph baseline)
 *   20 field binaries: NAC, KLAS (i32 each), SIDE..SLSIN (5 f64 arrays), AREA, ZBC, FNC,
 *                      H_pre..W_pre, H_res..W_res (f64)
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
    if (fread(buf, 1, sz, f) != (size_t)sz) exit(1);
    buf[sz] = 0; fclose(f);
    if (out_sz) *out_sz = sz;
    return buf;
}

int main(int argc, char** argv) {
    if (argc < 3) {
        printf("Usage: %s <data_dir> <CEL> [nsteps=900] [nruns=10] [max_regs=0]\n", argv[0]);
        return 1;
    }
    const char* data_dir = argv[1];
    int CEL = atoi(argv[2]);
    int nsteps   = argc > 3 ? atoi(argv[3]) : 900;
    int nruns    = argc > 4 ? atoi(argv[4]) : 10;
    int max_regs = argc > 5 ? atoi(argv[5]) : 0;
    int fp_sz = 8;  // F1 is fp64

    const char* POC_ROOT = getenv("HYDRO_BENCH_CUDA_DIR") ? getenv("HYDRO_BENCH_CUDA_DIR") : ".";

    CK(cuInit(0));
    CUdevice dev; CK(cuDeviceGet(&dev, 0));
    CUcontext ctx; CK(cuCtxCreate(&ctx, 0, dev));

    // --- cuLink driver_f1 + flux_func + update_func ---
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
    std::string driver_path = std::string(POC_ROOT) + "/driver_f1.ptx";
    std::string flux_path   = std::string(data_dir) + "/flux_func.ptx";
    std::string update_path = std::string(data_dir) + "/update_func.ptx";

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
    CK(cuModuleGetFunction(&persistent_fn, mod, "persistent_driver_f1"));
    int pd_regs;
    cuFuncGetAttribute(&pd_regs, CU_FUNC_ATTRIBUTE_NUM_REGS, persistent_fn);

    // --- Load 20 F1 fields ---
    // (5, CEL+1) i32: NAC, KLAS
    // (5, CEL+1) f64: SIDE, COSF, SINF, SLCOS, SLSIN
    // (CEL+1) f64: AREA, ZBC, FNC, H_pre, U_pre, V_pre, Z_pre, W_pre, H_res, U_res, V_res, Z_res, W_res
    const int N5 = 5 * (CEL + 1);
    const int N1 = CEL + 1;
    size_t sizes[20];
    const char* names[] = {
        "NAC", "KLAS",                                      // i32 (5, CEL+1)
        "SIDE", "COSF", "SINF", "SLCOS", "SLSIN",            // f64 (5, CEL+1)
        "AREA", "ZBC", "FNC",                                // f64 (CEL+1)
        "H_pre", "U_pre", "V_pre", "Z_pre", "W_pre",          // f64 (CEL+1)
        "H_res", "U_res", "V_res", "Z_res", "W_res"           // f64 (CEL+1)
    };
    sizes[0] = sizes[1] = (size_t)N5 * 4;
    for (int i = 2; i < 7; i++) sizes[i] = (size_t)N5 * fp_sz;
    for (int i = 7; i < 20; i++) sizes[i] = (size_t)N1 * fp_sz;

    size_t total = 0; for (int i = 0; i < 20; i++) total += sizes[i];
    char* host = (char*)malloc(total); size_t off = 0;
    for (int i = 0; i < 20; i++) {
        std::string p = std::string(data_dir) + "/" + names[i] + ".bin";
        FILE* f = fopen(p.c_str(), "rb");
        if (!f) { printf("Cannot open %s\n", p.c_str()); exit(1); }
        if (fread(host + off, 1, sizes[i], f) != sizes[i]) exit(1);
        fclose(f); off += sizes[i];
    }

    CUdeviceptr base; CK(cuMemAlloc(&base, total));
    CK(cuMemcpyHtoD(base, host, total));

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

    int dev_sms;
    CK(cuDeviceGetAttribute(&dev_sms, CU_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT, dev));
    int max_blocks_per_sm = 0;
    CK(cuOccupancyMaxActiveBlocksPerMultiprocessor(&max_blocks_per_sm, persistent_fn, 128, 0));
    int coop_blocks = dev_sms * max_blocks_per_sm;
    if (coop_blocks < 1) coop_blocks = dev_sms;

    void* pd_params[] = { &nsteps, &arg };

    // Warmup
    {
        CK(cuMemcpyHtoD(base, host, total));
        int warmup_steps = 10;
        void* wp[] = { &warmup_steps, &arg };
        CK(cuLaunchCooperativeKernel(persistent_fn,
            coop_blocks, 1, 1, 128, 1, 1, 0, 0, wp));
        CK(cuCtxSynchronize());
    }

    std::vector<double> times_p;
    for (int r = 0; r < nruns; r++) {
        CK(cuMemcpyHtoD(base, host, total));
        cudaEvent_t st, ed; cudaEventCreate(&st); cudaEventCreate(&ed);
        cudaEventRecord(st);
        CK(cuLaunchCooperativeKernel(persistent_fn,
            coop_blocks, 1, 1, 128, 1, 1, 0, 0, pd_params));
        cudaEventRecord(ed); cudaEventSynchronize(ed);
        float ms; cudaEventElapsedTime(&ms, st, ed);
        times_p.push_back(ms * 1000.0 / nsteps);
        cudaEventDestroy(st); cudaEventDestroy(ed);
    }
    std::sort(times_p.begin(), times_p.end());
    double persistent_us = times_p[nruns/2];

    // --- Graph baseline ---
    CUmodule flux_raw_mod, update_raw_mod;
    std::string flux_raw_s = std::string(data_dir) + "/flux_raw.ptx";
    std::string update_raw_s = std::string(data_dir) + "/update_raw.ptx";
    data = read_file(flux_raw_s.c_str(), &sz);
    CK(cuModuleLoadData(&flux_raw_mod, data)); free(data);
    data = read_file(update_raw_s.c_str(), &sz);
    CK(cuModuleLoadData(&update_raw_mod, data)); free(data);

    CUfunction flux_entry, update_entry;
    CK(cuModuleGetFunction(&flux_entry, flux_raw_mod,
        "shallow_water_step_real_c80_0_kernel_0_range_for"));
    CK(cuModuleGetFunction(&update_entry, update_raw_mod,
        "transfer_real_c82_0_kernel_0_range_for"));

    int step_grid = (CEL + 127) / 128;
    int xfer_grid = (CEL + 127) / 128;
    void* k_params[] = { &arg };

    CUstream stream; CK(cuStreamCreate(&stream, CU_STREAM_NON_BLOCKING));
    CUgraph graph;
    CK(cuStreamBeginCapture(stream, CU_STREAM_CAPTURE_MODE_GLOBAL));
    for (int s = 0; s < nsteps; s++) {
        CK(cuLaunchKernel(flux_entry, step_grid, 1, 1, 128, 1, 1, 0, stream, k_params, 0));
        CK(cuLaunchKernel(update_entry, xfer_grid, 1, 1, 128, 1, 1, 0, stream, k_params, 0));
    }
    CK(cuStreamEndCapture(stream, &graph));
    CUgraphExec graphExec; CK(cuGraphInstantiate(&graphExec, graph, 0));

    CK(cuMemcpyHtoD(base, host, total));
    CK(cuGraphLaunch(graphExec, stream));
    CK(cuStreamSynchronize(stream));

    std::vector<double> times_g;
    for (int r = 0; r < nruns; r++) {
        CK(cuMemcpyHtoD(base, host, total));
        cudaEvent_t st, ed; cudaEventCreate(&st); cudaEventCreate(&ed);
        cudaEventRecord(st, (cudaStream_t)stream);
        CK(cuGraphLaunch(graphExec, stream));
        cudaEventRecord(ed, (cudaStream_t)stream);
        cudaEventSynchronize(ed);
        float ms; cudaEventElapsedTime(&ms, st, ed);
        times_g.push_back(ms * 1000.0 / nsteps);
        cudaEventDestroy(st); cudaEventDestroy(ed);
    }
    std::sort(times_g.begin(), times_g.end());
    double graph_us = times_g[nruns/2];

    printf("CASE_RESULT case=F1_6.7K_fp64 CEL=%d max_regs=%d pd_regs=%d "
           "coop_blocks=%d graph_blocks=%d persistent_us=%.4f graph_us=%.4f ratio=%.4f\n",
        CEL, max_regs, pd_regs, coop_blocks, step_grid + xfer_grid,
        persistent_us, graph_us, persistent_us / graph_us);

    return 0;
}
