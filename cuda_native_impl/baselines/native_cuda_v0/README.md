# native_cuda_v0

Frozen copy of the native CUDA implementation before kernel optimization.

This baseline is used by `scripts/check_native_alignment.py` to compare
candidate native CUDA binaries against the original native CUDA trajectory.
It intentionally reuses the existing `cuda_native_impl/*_native_data`
directories instead of copying large input datasets.

Build:

```bash
bash cuda_native_impl/baselines/native_cuda_v0/fp64/build.sh sm_80
bash cuda_native_impl/baselines/native_cuda_v0/fp32/build.sh sm_80
```

Compare:

```bash
python scripts/check_native_alignment.py F2_207K_fp64 --steps 1,10,100,899
python scripts/check_native_alignment.py F2_207K_fp32 --steps 1,10,100,899
```
