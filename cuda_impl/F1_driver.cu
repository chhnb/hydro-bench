/**
 * Persistent driver for F1 (shallow_water_step_real + transfer_real).
 * Compile: nvcc -arch=sm_80 -ptx -rdc=true driver_f1.cu -o driver_f1.ptx
 */
#include <cooperative_groups.h>
namespace cg = cooperative_groups;

struct TaichiArg {
    void* args; void* runtime; int pad, pad2; void* extra_args;
};

extern "C" __device__ void
shallow_water_step_real_c80_0_kernel_0_range_for(TaichiArg arg);

extern "C" __device__ void
transfer_real_c82_0_kernel_0_range_for(TaichiArg arg);

extern "C" __global__ void
persistent_driver_f1(int nsteps, TaichiArg arg) {
    cg::grid_group grid = cg::this_grid();
    for (int s = 0; s < nsteps; s++) {
        shallow_water_step_real_c80_0_kernel_0_range_for(arg);
        grid.sync();
        transfer_real_c82_0_kernel_0_range_for(arg);
        grid.sync();
    }
}
