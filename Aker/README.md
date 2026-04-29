# aker

Grow a graph of CUDA kernel implementations by asking an LLM to keep
mutating the fastest one. Given a natural-language description of a
kernel, `aker` drives a codex agent through three phases:

1. **spec** — turn the description into a rigorous `spec.md`.
2. **bootstrap** — write the simplest correct CUDA C implementation
   (`v0_naive_cuda`), plus the shared test infrastructure every future
   node reuses.
3. **iterate** — each round, read the current graph + leaderboard, pick
   a base node, propose an optimization, implement it, test it,
   rank it. A second codex agent reviews the result.

Every node is a directory. Every edge is an idea. Over rounds the graph
accumulates *directions tried*, *techniques used*, *profile artifacts*,
and *design notes* — inputs that future rounds read before picking the
next move.

---

## Prerequisites

- **CUDA**. The worker compiles `kernel.cu` with
  `torch.utils.cpp_extension.load()`, so a working `nvcc` + driver + GPU
  are required. Developed against NVIDIA H20 (Hopper) / CUDA 12.4, but
  the pipeline is hardware-agnostic.
- **PyTorch**. Used for kernel loading, timing (CUDA events), and input
  generation.
- **`codex` CLI**. This project is a thin orchestrator around codex
  exec; the binary must be on PATH. Tested against codex 0.120+.
- **Python 3.9+**.

Optional (recommended when optimization plateaus):

- **Nsight Compute (`ncu`)** and **`cuobjdump` / `nvdisasm`** on PATH.
  When present, the worker may profile a kernel and persist the raw
  output under `nodes/<id>/profile/` for later cross-node comparison.

---

## Install

```bash
git clone <this repo>
cd Aker
pip install -e . --user   # adds `aker` to ~/.local/bin
```

The `--user` flag matters. On some systems `pip install -e .` without
`--user` writes the package metadata to a site-packages directory that
is not on the default `python3`'s `sys.path`, which produces the
misleading error:

```
importlib.metadata.PackageNotFoundError: aker
```

when you run `aker`. If you hit that, uninstall (`pip uninstall aker`),
remove any stale `/usr/bin/aker` or `/usr/local/bin/aker`, and reinstall
with `--user`.

If `~/.local/bin` is not on your `PATH`, either add it or just skip the
install and use `python -m aker` everywhere `aker` appears below — that
works with zero install.

---

## Quickstart

Two commands take you from a sentence to an iterating graph:

```bash
# 1. Create the task, generate spec.md, bootstrap the first kernel.
aker new fp8_cast "使用 cuda c，实现一个 1D 张量的量化 cast：输入为 FP8 E4M3 编码的元素和每 1024 个元素共享的 float32 输入量化因子，输出为 NVFP4 E2M1 编码的元素和每 16 个输出元素共享的 FP8 E4M3 输出量化因子。逻辑上先将输入 FP8 E4M3 元素按其 1024 元素分组 scale 还原为实数值 ，再按 16 元素分组生成输出 scale，并将每个实数值量化为带该输出 scale 的 NVFP4 E2M1 值。输入 array 和输出 array 均为长度规整的 1D 数据；输出 NVFP4 元素按每个 uint8 存放两个 4-bit 元素的方式表示"

# 2. Iterate. Each round adds one new node to the graph.
aker run fp8_cast --rounds 10

# Or iterate in parallel — 4 worker slots sharing the GPU:
aker run fp8_cast --rounds 10 --parallel 4
```

Each round takes a few minutes (worker compiles + tests, reviewer
checks). After `--rounds N` rounds you will have up to N new kernel
implementations ranked under `tasks/fp8_cast/leaderboard.md`.

`--parallel N` runs N worker+reviewer sessions concurrently against the
same task. A GPU broker serializes the actual GPU work FIFO across
slots, so only one kernel compiles/tests at a time — but codex
reasoning, file I/O, and reviewer passes overlap. Recommended range is
`1–5`. `--rounds` is the total budget across all slots, not per-slot.

`aker new` is idempotent: if `spec.md` already exists it skips the spec
phase; if `nodes/v0_naive_cuda/` is already present it skips bootstrap.
So if bootstrap crashes partway through, just run the same command
again.

---

## Task directory layout

```
tasks/fp8_cast/
├── spec.md                    # authoritative task specification
├── testlib.py                 # shared test utilities (don't edit)
├── test_acc.py                # precision-observation CLI
├── test_perf.py               # runtime-measurement CLI
├── leaderboard.jsonl          # append-only, one row per successful node
├── leaderboard.md             # human-readable, regenerated each round
├── _bootstrap_log.md          # worker↔reviewer transcript for bootstrap
├── _iterate_logs/             # one per iterate round
│   └── round_001.md
└── nodes/
    ├── v0_naive_cuda/
    │   ├── kernel.cu          # the CUDA C implementation
    │   ├── kernel.py          # thin PyTorch wrapper (uniform signature)
    │   ├── meta.json          # node metadata: parents, action, direction,
    │   │                      #                techniques, rationale
    │   ├── notes.md           # design doc — core strategy, rejected
    │   │                      #             alternatives, invariants
    │   ├── report_acc.json    # per-shape output statistics
    │   ├── report_perf.json   # CUDA-event timings
    │   └── profile/           # optional: ncu / SASS dumps if profiled
    ├── v1_…/
    └── …
```

Only `spec.md`, `testlib.py`, `test_acc.py`, `test_perf.py`,
`leaderboard.*`, and `nodes/<id>/` are first-class on-disk state.
Everything else (logs, `__pycache__/`, etc.) is disposable.

---

## Command reference

### `aker new <task_name> [description]`

Create `tasks/<task_name>/`, run the spec phase if `spec.md` is missing,
then run the bootstrap phase if `nodes/v0_naive_cuda/` is missing.
`[description]` is required on first run and ignored if `spec.md`
already exists.

Options:

- `--spec-timeout-sec <s>` — codex timeout for spec phase (default `1800`).
- `--bootstrap-max-retries <k>` — worker↔reviewer retries (default `3`).
- `--model <name>` — codex model override.
- `--timeout-sec <s>` — per-session timeout for bootstrap (default `3600`).

### `aker run <task_name> --rounds N`

Run N iterate rounds against an already-bootstrapped task. Each round
spawns one worker+reviewer dialog, which adds exactly one new node.

Options:

- `--rounds N` — how many new nodes to attempt, total across all slots
  (default `1`).
- `--parallel N` — number of concurrent worker slots (default `1`;
  recommended `1–5`). GPU work is serialized by a broker process;
  LLM reasoning and file I/O overlap.
- `--max-retries K` — worker↔reviewer retries per round (default `5`).
- `--rng-seed N` — seed for the worker-session lifespan RNG, for
  reproducibility.
- `--model <name>` — codex model override.
- `--timeout-sec <s>` — per-session timeout (default `3600`).

### Globals (accepted by any subcommand)

- `--task-root <dir>` — where task directories live (default `./tasks`).
- `--log-level <level>` — `DEBUG` / `INFO` / `WARNING` (default `INFO`).

---

## How iteration works

Each round Python hands the worker a graph summary it builds from
`nodes/*/meta.json` and `leaderboard.jsonl`: a runtime-sorted
leaderboard followed by a per-node block listing `parents` / `direction`
/ `techniques` / `rationale` and a pointer to `notes.md` (and
`profile/` if present).

The worker:

1. Reads the summary and, per the prompt, reasons from first principles
   about where time is actually going in the current best kernel.
2. Picks a base (or bases, for a merge), a direction, and a new
   `v<N>_<tag>` id.
3. Writes `kernel.cu` / `kernel.py` / `meta.json` / `notes.md`, runs
   `test_acc.py` + `test_perf.py`, appends to `leaderboard.jsonl`.

The reviewer (a second codex session with read-only sandbox) then
inspects the new node against the contract in its prompt. Its reply
ends with a single line `VERDICT: PASS` or `VERDICT: RETRY` — the only
hard-format signal the system relies on.

If `RETRY`, the worker fixes in place (same session). Up to
`--max-retries` cycles per round.

On `PASS`, Python runs a disk audit: exactly one new node appeared,
meta.json has the required fields and valid parents, `attempt_status`
matches the leaderboard / report files.

Sessions are **not** preserved across rounds indefinitely. Each new
worker session runs for a random number of rounds drawn from uniform
`[1, 5]` before being renewed — a trade-off between *losing
accumulated reasoning* (fresh every round) and *getting stuck in a
local mental model* (never refreshing). Pass `--rng-seed` to make the
draws deterministic. The reviewer is always fresh per round.

---

## Development

```bash
# Run one round against an existing task dir (no install needed):
python3 -m aker run _try_fp8_nvfp4_cast --rounds 1

# Or invoke the underlying Python API directly:
python3 -c "from aker import iterate; iterate.run('tasks/_try_fp8_nvfp4_cast', rounds=3)"
```

The `tests/test_*.py` scripts are thin smoke harnesses around each
phase (`test_spec.py`, `test_bootstrap.py`, `test_iterate.py`).
They hard-code the `_try_fp8_nvfp4_cast` sample task and dump verbose
output — useful during development, not required for normal use.

---

## What this is not

- **Not** a general-purpose kernel library. Each run targets one task
  the user describes in natural language; the output is one graph of
  implementations for that task, pinned to one hardware target.
- **Not** hardware-aware planning. The LLM is the planner; `aker` only
  drives sessions, manages the graph, and enforces a thin on-disk
  contract.
- **Not** deterministic. Codex output varies across invocations;
  `--rng-seed` controls session lifespan but not codex itself.
