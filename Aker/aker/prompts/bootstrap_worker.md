# Role

You are bootstrapping a kernel-exploration workspace. A canonical kernel
specification (`spec.md`) already exists in the working directory. Your job
is to produce:

1. A naive, correctness-first CUDA C implementation, registered as the
   first graph node `v0_naive_cuda`. This is NOT a privileged "reference";
   it is simply the first entry in the graph — the simplest correct thing
   you can write so the graph has a place to start.
2. A shared test library (`testlib.py`) plus two CLI scripts
   (`test_acc.py`, `test_perf.py`) that every future node in this graph
   will reuse — unchanged — to record precision observations and runtime
   measurements.
3. Produce the node's `report_acc.json` and `report_perf.json` by
   running the tests.

**Do NOT write `leaderboard.jsonl` or `leaderboard.md`.** Python owns
both files — after bootstrap finishes, Python reads your `meta.json` +
`report_*.json` and produces the leaderboard itself.

You are NOT optimizing anything. `v0_naive_cuda` is allowed — expected —
to be slow.

**Precision testing is observation-only.** Each run records statistics of
the kernel's own output (dtype, shape, device, NaN/Inf counts, value range
and moments, and decoded-form stats if applicable). There is NO
ground-truth comparison, NO reference kernel, NO pass/fail gate, and NO
cross-node diffing. Correctness judgement is deferred entirely to
downstream stages (selector LLM, human review, ad-hoc diffing). Do not
import or reference any node from within `test_acc.py` except the one
specified by `--version`.

---

# Output contract

Write exactly these files in the current working directory:

```
testlib.py
test_acc.py
test_perf.py
nodes/
  v0_naive_cuda/
    kernel.cu
    kernel.py
    meta.json
    notes.md              (short — v0 is intentionally the unbiased baseline)
    report_acc.json       (produced by running the accuracy job)
    report_perf.json      (produced by running the perf job)
```

Do not create any other files. Do not create or touch
`leaderboard.jsonl` / `leaderboard.md`. Do not modify `spec.md`.

**GPU access is brokered.** A single broker process owns the GPU and
runs one job at a time FIFO with per-job timeouts (hard-kill on
expiry). You cannot run `python test_acc.py` / `python test_perf.py`
/ `ncu` / `nvidia-smi` directly — your sandbox has
`CUDA_VISIBLE_DEVICES=""` set. Instead, once the test files and v0
node directory are fully written, submit through `akerjob`:

```
akerjob test_acc  --node v0_naive_cuda
akerjob test_perf --node v0_naive_cuda
```

`akerjob` blocks until the broker returns. Under the hood the broker
runs exactly `python test_acc.py --version v0_naive_cuda` / `python
test_perf.py --version v0_naive_cuda` in a subprocess with the real
CUDA device, so your test scripts still need to implement the
`--version <node_id>` CLI they normally would.

Both must exit 0 and produce the respective report JSON files with
plausible content (no NaN/Inf in outputs, output dtypes/shapes match
spec §3, runtime a positive number). A line on stderr like
`[akerjob] {"status": "OK", ...}` confirms the broker's view.

Your final reply must be a single line in this exact form:

    BOOTSTRAP: v0_naive_cuda runtime=<mean><unit> status=OK

For example: `BOOTSTRAP: v0_naive_cuda runtime=1.23ms status=OK`

---

# The uniform node interface (MUST hold for every future node)

Every graph node — present and future — lives under `nodes/<node_id>/` and
exposes the same interface:

- `kernel.cu` — the CUDA C implementation.
- `kernel.py` — a thin Python wrapper that compiles `kernel.cu` through
  `torch.utils.cpp_extension.load()` and exports a callable `kernel(...)`
  whose signature matches `spec.md §3` exactly.
- `meta.json` — node metadata.
- `notes.md` — design document describing the current state of the
  kernel (core strategy, key decisions, alternatives considered,
  invariants). Future workers read this when picking this node as a
  base. For `v0_naive_cuda` specifically this is intentionally brief
  — see the `notes.md` contract below.
- `report_acc.json` — output of `test_acc.py --version <node_id>`.
- `report_perf.json` — output of `test_perf.py --version <node_id>`.

This uniform interface is the spine of the whole system. The test scripts
take a `--version <id>` argument, dynamically import the corresponding
`kernel.py`, call `kernel(...)` on generated inputs, and record their
measurements in the node's dir. They do not care whether the underlying
CUDA is naive, uses Tensor Cores, async copies, TMA, or any other
technique — as long as the interface holds.

---

# File contract: `nodes/v0_naive_cuda/kernel.cu`

Write the simplest CUDA C program that correctly implements the math in
`spec.md §4`. Correctness by the spec is the only goal.

- Use the most straightforward parallel mapping (one thread per output
  element, or one block per natural reduction group). Do not tile, do not
  vectorize, do not use shared memory unless the algorithm genuinely
  requires it for a reduction. Do not use Tensor Cores or any hardware
  intrinsic beyond plain arithmetic and the dtype cast functions provided
  by `<cuda_fp8.h>` / `<cuda_fp16.h>` / etc.
- Handle every edge case defined in `spec.md §4` explicitly (zero-block
  fallbacks, saturation, rounding modes).
- Expose a single `forward` function via pybind11:

  ```cpp
  #include <torch/extension.h>
  // ... kernel code and forward(...) implementation ...

  PYBIND11_MODULE(TORCH_EXTENSION_NAME, m) {
      m.def("forward", &forward, "naive CUDA implementation");
  }
  ```

- `forward` takes one `torch::Tensor` per spec §3 tensor input (in the same
  order) and any scalar parameters, and returns a `std::tuple<torch::Tensor, ...>`
  whose elements are the spec §3 outputs (in the same order). If there is
  exactly one output, return it directly.
- Validate inputs with `TORCH_CHECK` at the top of `forward` (contiguity,
  dtype, device, divisibility constraints implied by spec §3).

Forbidden in `kernel.cu` (mirroring `spec.md §9`):

- No fallback to any PyTorch op-library implementation of the target
  operation.
- No extra CUDA streams; use the default stream only.
- No asynchronous work that is not captured by the caller's timing events.
- No hardcoding of results for specific input shapes or pointer addresses.

---

# File contract: `nodes/v0_naive_cuda/kernel.py`

A minimal wrapper. Every future node copies this shape exactly. Use this
template verbatim unless the spec signature demands otherwise:

```python
"""kernel.py — uniform node entry. Compiles kernel.cu and exposes kernel(*)."""

from __future__ import annotations

from pathlib import Path
from torch.utils.cpp_extension import load

_HERE = Path(__file__).parent

_mod = load(
    name=_HERE.name,                         # unique per node dir
    sources=[str(_HERE / "kernel.cu")],
    extra_cuda_cflags=["-O3", "--use_fast_math"],
    verbose=False,
)

def kernel(<args per spec §3>):
    return _mod.forward(<args>)
```

Fill in `<args per spec §3>` with the exact argument list and order from
`spec.md §3`. Return values follow the same order.

---

# File contract: `nodes/v0_naive_cuda/meta.json`

```json
{
    "node_id": "v0_naive_cuda",
    "parents": [],
    "action": "bootstrap",
    "direction": null,
    "rationale": "simplest CUDA C implementation; first graph node",
    "techniques": ["cuda_naive"],
    "created_at": "<ISO-8601 UTC timestamp>"
}
```

Future nodes will have non-empty `parents`, an `action` of `"mutate"` or
`"merge"`, a `direction` string, a `techniques` list of tags
(e.g. `"wmma"`, `"async_copy"`, `"tile_128x64"`), and a `rationale`
paragraph.

---

# File contract: `nodes/v0_naive_cuda/notes.md`

For `v0_naive_cuda` specifically, `notes.md` is intentionally brief
(2–4 sentences). v0 is the graph's unbiased starting point — future
nodes should be free to diverge arbitrarily without being anchored to
any "optimization rationale" from v0. Write only:

- What v0 is: the naive baseline, one thread per output element (or
  the analogous simplest mapping for this task).
- Its role: the first graph node, not a performance reference.
- A one-sentence reminder that future nodes may produce bit-exactly
  different outputs and still be correct — v0 is not ground truth.

Do NOT include "optimization hints", technique suggestions, or any
prose that implies a direction future workers should or should not
take. Keep v0's `notes.md` deliberately inert.

Future non-bootstrap nodes will produce a longer, design-focused
`notes.md` (200–600 words) per the iterate-phase prompt.

---

# File contract: `testlib.py`

Shared task-specific utilities imported by both `test_acc.py` and
`test_perf.py`. Keep it self-contained — no imports of specific node
implementations, no hidden global state.

Must provide:

- `load_kernel(version: str) -> Callable`:
    Resolve `version` to a node directory under `nodes/`. Accept either an
    exact directory name (`v0_naive_cuda`) or a `v<N>` prefix that matches
    a single directory. Dynamically import its `kernel.py` and return the
    `kernel` callable. Raise a clear error if ambiguous or missing.

- `generate_inputs(shape_name: str, seed: int) -> tuple[torch.Tensor, ...]`:
    Materialize input tensors following `spec.md §6` exactly (distribution,
    dtype casts, device). `shape_name` is one of `"smoke"`, `"primary"`,
    `"generalization"`, or an edge-case name listed in the spec.
    **Must be vectorized.** Use `torch.randn` / `torch.randint` /
    `torch.empty` + `.to(dtype)` / tensor-level arithmetic. Do NOT loop
    over elements in Python — the primary shape will be large enough to
    stress the GPU (see `test_perf.py` contract), and a Python-level
    loop over that many elements would dominate total test time.

- `tensor_stats(t: torch.Tensor, *, decoder=None) -> dict`:
    Return raw tensor metadata: `{dtype, shape, device, numel}`. For
    floating-point dtypes, also include `{nan_count, inf_count, min, max,
    mean, abs_mean, std}` computed in float32. For integer-encoded /
    byte-packed outputs (e.g. `uint8` nibble-packing for NVFP4) raw
    moments on the bytes are not meaningful; instead, call the optional
    `decoder` callable to materialize a float32 decoded form per
    `spec.md §4`, and nest its stats under a `"decoded"` sub-dict. If no
    decoder is provided for a non-float dtype, omit the numeric moments.

- `time_kernel(kernel_fn, inputs, warmup: int, iters: int) -> dict`:
    Run the kernel `warmup` times, then time `iters` iterations using
    `torch.cuda.Event(enable_timing=True)` on the default CUDA stream,
    bracketed by `torch.cuda.synchronize()`. Return
    `{mean_ms, std_ms, min_ms, max_ms, iters}`. No extra streams. No
    asynchronous work outside the timed region.

- `SHAPES` (dict): the shape configurations from `spec.md §6`, keyed by
  their names, values as `dict[str, int]` of symbolic-dim values.

- `SEEDS` (list[int]): the seed list from `spec.md §6`.

- `EDGE_CASES` (list[dict]): the edge-case configurations from spec §6,
  each with a `name` and enough parameters for `generate_inputs` to
  reproduce.

- `decode_outputs(*outputs) -> tuple[torch.Tensor, ...]` (optional): if
  `spec.md §4` defines a decoded real-valued form of the outputs (e.g.,
  `y_real = decode_fp4(q) * decode_fp8(scale_inner) * scale_outer`),
  implement it here so both test scripts can call it. This function is
  task-specific. If the spec does not have a decoded form, omit this
  helper.

Keep it stateless and functional. No globals beyond the three config
constants above.

---

# File contract: `test_acc.py`

A precision-observation CLI. NO ground-truth comparison. NO pass/fail.
It runs the kernel on each (shape, seed) combination and each edge case,
records output statistics, and writes them to `<node_dir>/report_acc.json`.

## CLI

```
python test_acc.py --version <node_id_or_prefix>
```

## Responsibilities

1. `kernel_fn = testlib.load_kernel(args.version)`. Do NOT import any
   other node.
2. For each `(shape_name, seed)` in `SHAPES × SEEDS`:
   - generate inputs via `testlib.generate_inputs(shape_name, seed)`
   - call `kernel_fn(*inputs)` inside a `try/except`; on exception,
     record `{status: "FAIL", error: <str>}` for the case and continue
   - for each returned output tensor, compute
     `testlib.tensor_stats(t, decoder=...)` (supplying the task-specific
     decoder when meaningful)
3. For each entry in `EDGE_CASES`, do the same using its `name` as the
   `shape_name` key.
4. Write `<node_dir>/report_acc.json`:

```json
{
    "node_id": "...",
    "spec_version_hash": "<sha256 of spec.md>",
    "created_at": "...",
    "observations": [
        {
            "kind": "shape" | "edge_case",
            "name": "primary" | "all_zero" | ...,
            "seed": 0,
            "status": "OK" | "FAIL",
            "error": null,
            "outputs": [
                {
                    "name": "y_q_packed",
                    "dtype": "uint8",
                    "shape": [134217728],
                    "device": "cuda:0",
                    "numel": 134217728,
                    "decoded": {
                        "nan_count": 0,
                        "inf_count": 0,
                        "min": -192.0,
                        "max": 192.0,
                        "mean": 0.01,
                        "abs_mean": 45.3,
                        "std": 63.5
                    }
                }
            ]
        }
    ],
    "summary": {
        "status": "OK" | "FAIL",
        "failed_cases": [],
        "total_nan_count": 0,
        "total_inf_count": 0
    }
}
```

Print a one-line summary to stdout after writing.

---

# File contract: `test_perf.py`

A runtime-measurement CLI.

## CLI

```
python test_perf.py --version <node_id_or_prefix>
```

## Responsibilities

1. `kernel_fn = testlib.load_kernel(args.version)`
2. On the `primary` shape (mandatory) — and the `generalization` shape if
   spec §7 includes it:
   - generate inputs with `seed=0` via `testlib.generate_inputs`
   - call `testlib.time_kernel(kernel_fn, inputs, warmup=<spec>,
     iters=<spec>)` using the warmup/iter counts from spec §7
3. v0 does NOT run NCU diagnostics; leave the diagnostic field as `null`
   with a note.

**Primary shape must be large enough for meaningful perf measurement.**
The kernel launch dispatches work to every SM on the target GPU, and
the scheduler assigns work to SMs in waves. If the primary shape only
fills a fraction of one wave, the measurement is dominated by launch
overhead / cold caches and tells you nothing about steady-state
throughput. Size the primary shape so the kernel runs multiple waves
across all SMs on the target hardware — back-of-envelope: enough
threads to cover all SMs × max blocks per SM several times over. If
the shape listed in `spec.md §6` looks borderline, still follow the
spec but flag it in your final reply so the user can adjust.
4. Write `<node_dir>/report_perf.json`:

```json
{
    "node_id": "...",
    "spec_version_hash": "<sha256 of spec.md>",
    "created_at": "...",
    "measurements": [
        {
            "shape": "primary",
            "mean_ms": 1.23,
            "std_ms": 0.04,
            "min_ms": 1.20,
            "max_ms": 1.35,
            "warmup_iters": 25,
            "timed_iters": 200
        }
    ],
    "diagnostic": {
        "kind": "dram_bandwidth_util_pct" | "tensor_core_util_pct",
        "value": null,
        "note": "NCU integration deferred to v1"
    },
    "status": "OK"
}
```

Print a one-line summary to stdout after writing.

---

# Leaderboard is NOT your concern

Python owns `leaderboard.jsonl` and `leaderboard.md`. Do not create
them, do not write to them, do not mention them in output files. After
this bootstrap round closes, Python will read your `meta.json` +
`report_*.json` and populate the leaderboard itself.

---

# Self-validation before declaring success

Before writing your final reply, verify:

- `nodes/v0_naive_cuda/kernel.cu` compiles under
  `torch.utils.cpp_extension.load()` (exercised by the test scripts).
- `nodes/v0_naive_cuda/report_acc.json` exists. `summary.status == "OK"`,
  `total_nan_count == 0`, `total_inf_count == 0`. For every observation,
  each output's declared dtype / shape / device matches spec §3.
- `nodes/v0_naive_cuda/report_perf.json` exists, `status == "OK"`, and
  `mean_ms` for the primary shape is a positive number.
- `leaderboard.jsonl` / `leaderboard.md` do NOT exist yet — and that is
  correct; Python will create them.

If any step fails, iterate inside this same invocation: read the error,
fix the offending file (usually `kernel.cu`, `testlib.py`, or one of the
test scripts), rerun. Do not record failure as success. If after
reasonable effort the bootstrap cannot produce a working first node,
explain what went wrong in the final reply
(`BOOTSTRAP: ... status=FAIL reason="<brief>"`) and leave the partial
files in place for human inspection.

---

# Rigor reminders

- `v0_naive_cuda` is NOT an optimization target and NOT a privileged
  reference. It is the simplest correct thing, so the graph has a place
  to start. Future nodes may produce bit-exactly different outputs and
  still be correct.
- Precision testing is observation-only. Do NOT implement any comparison
  against `v0_naive_cuda` or any other node. Do NOT compute
  `max_abs_error` against a ground truth — there is no ground truth at
  this layer. Each node's `report_acc.json` is a self-contained record
  of what that kernel produced.
- `testlib.py`, `test_acc.py`, and `test_perf.py` are the project's
  persistent test infrastructure. Every later node will be evaluated by
  re-running the same two scripts against its `--version`. Design them
  for reuse: clean functions, no ad-hoc hooks, no inline fixtures that
  bleed implementation details.
- Do NOT prescribe any optimization in `kernel.cu` comments or
  docstrings. Future agents will read this file; any optimization hint
  here biases them.

Now read `spec.md` and proceed.
