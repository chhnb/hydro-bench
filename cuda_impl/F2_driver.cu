/**
 * Persistent driver kernel that calls Taichi-compiled flux + update as device
 * functions, using cooperative_groups::grid.sync() between phases.
 *
 * Compile with:
 *   nvcc -arch=sm_80 -ptx -rdc=true driver.cu -o driver.ptx
 *
 * Then cuLink with flux_func.ptx + update_func.ptx.
 */
#include <cooperative_groups.h>

namespace cg = cooperative_groups;

// 32-byte struct matches Taichi's RuntimeContext param layout.
// Offsets used by Taichi PTX:
//   +0  : args*      (unused by flux/update in this workload)
//   +8  : runtime*   (Taichi reads roots[0] at runtime+88)
//   +16 : i32 (pad)
//   +24 : extra_args*
struct TaichiArg {
    void* args;
    void* runtime;
    int   pad;
    int   pad2;
    void* extra_args;
};

extern "C" __device__ void
calculate_flux_c80_0_kernel_0_range_for(TaichiArg arg);

extern "C" __device__ void
update_cell_c82_0_kernel_0_range_for(TaichiArg arg);

extern "C" __global__ void
persistent_driver(int nsteps, TaichiArg arg)
{
    cg::grid_group grid = cg::this_grid();
    for (int s = 0; s < nsteps; s++) {
        calculate_flux_c80_0_kernel_0_range_for(arg);
        grid.sync();
        update_cell_c82_0_kernel_0_range_for(arg);
        grid.sync();
    }
}
