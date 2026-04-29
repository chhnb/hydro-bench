# Example: FP8 (E4M3) → NVFP4 cast on RTX 5060 (Blackwell sm_120)

A 1D dtype-cast kernel with **block-wise scale reconstruction on the input
side and block-wise scale generation on the output side**. This is the
first end-to-end case for `aker` on the Blackwell architecture.

## Natural-language description (verbatim user input)

在当前的 5060 cuda c 上实现一个 fp8 (e4m3) cast 到 nvfp4 的 kernel，其中
fp8 的元素，每 1024 个值共享一个 fp32 的 scale factor；而 nvfp4 的元素，
每 16 个值共享一个 fp8 (e4m3) 的 scale factor；

## Shape of the problem

- **Input**: a 1D array of FP8 E4M3 values + a parallel array of FP32
  scale factors, one per 1024-element block of the FP8 array.
- **Output**: a 1D array of NVFP4 E2M1 values (packed two-per-byte in
  `uint8`) + a parallel array of FP8 E4M3 scale factors, one per
  16-element block of the NVFP4 array.

Logical pipeline, conceptually:

1. `x_real[i] = decode_fp8(x_fp8[i]) * scale_inner[i // 1024]` → real
   value in FP32.
2. Per 16-element output block, compute an FP8 scale so the block's
   real values map into NVFP4's representable range.
3. `y_q[i] = quantize_nvfp4(x_real[i] / scale_outer[i // 16])`; pack
   two 4-bit values per `uint8`.

## How to run

```bash
# 1. Bootstrap: spec → v0_naive_cuda → seed leaderboard.
aker new fp8_nvfp4_cast "$(cat examples/fp8_nvfp4_cast.md | \
    awk '/verbatim user input/{flag=1; next} /^## Shape/{flag=0} flag' | \
    sed '/^$/d')"

# 2. Iterate with 3 concurrent slots for 20 rounds.
aker run fp8_nvfp4_cast --rounds 20 --parallel 3
```

Or pass the description directly on the command line (recommended — the
`awk` trick above is brittle):

```bash
aker new fp8_nvfp4_cast "在当前的 5060 cuda c 上实现一个 fp8 (e4m3) cast 到 nvfp4 的 kernel，其中 fp8 的元素，每 1024 个值共享一个 fp32 的 scale factor；而 nvfp4 的元素，每 16 个值共享一个 fp8 (e4m3) 的 scale factor；"
aker run fp8_nvfp4_cast --rounds 20 --parallel 3
```

## Target hardware notes (informational only — don't feed to LLM)

- **RTX 5060** is Blackwell, architecture sm_120. The spec generator is
  expected to infer target capability from `nvidia-smi` / `torch.cuda`
  reads the worker does inside its sandbox; aker does not hardcode an
  SM target.
- FP8 E4M3 → NVFP4 is a common prequantization step in modern inference
  stacks (e.g. DeepSeek-V3 weight prepack, Blackwell's NVFP4 GEMM path).
  A fast 1D cast makes it a reasonable first optimization target.
