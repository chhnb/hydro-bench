# aker 开发计划

**最后更新**：2026-04-23

> 用户入口、安装、命令速查见 `README.md`。这个文档记录**设计决策**和
> **开发节奏**，不重复 README 的使用说明。

---

## 1. 项目目标

从用户的自然语言需求出发，自动产出在指定硬件上高度优化的 GPU kernel 实现。
系统的核心是一个 **kernel 版本图**：

- 每个节点是一份 kernel 实现（目前锁定 CUDA C）
- 每条边代表"从一个版本到另一个版本做的一次优化变换"（mutate）或"融合多
  个版本的 idea"（merge）
- 迭代由两个 Codex session 驱动：**worker** 读 leaderboard + 图历史 →
  从第一性原理找瓶颈 → 决策 → 实现 → 自测 → 贡献回 leaderboard；
  **reviewer** 读磁盘状态 → 按契约检查 → 发出 `VERDICT: PASS` 或 `RETRY`。
  Python 只负责进程编排、文件 audit、图结构维护，不做任何 LLM 推理。

---

## 2. 三阶段架构

```
用户 NL ──▶ [spec_generator.md]  ──▶ spec.md
                                        │
                                        ▼
             [bootstrap_worker.md] ◀─▶ [bootstrap_reviewer.md]
                     │                     ▲
                     └─────┬───────────────┘
                           ▼
             nodes/v0_naive_cuda/
             + testlib.py / test_acc.py / test_perf.py
             + leaderboard.{jsonl,md}
                           │
                           ▼
             [iterate_worker.md]  ◀─▶  [iterate_reviewer.md]
                  (每轮一对 session，共享同一个 graph summary)
                           │
                           ▼
             nodes/v1_*/, v2_*/, ...
             + 持续更新 leaderboard
```

CLI（`aker/cli.py`）用两条命令覆盖全流程：

- `aker new <task> "<desc>"`：spec 阶段 + bootstrap 阶段（幂等——如果 `spec.md`
  已存在就跳过 spec；`nodes/v0_naive_cuda/` 已存在就跳过 bootstrap）
- `aker run <task> --rounds N`：连跑 N 轮 iterate

Python 侧模块分工：`spec.py` / `bootstrap.py` / `iterate.py` 各自 `run(task_dir,...)` →
`<Phase>Report`；`review_loop.py` 提供通用 worker+reviewer 循环；`graph.py` 提供扫描
节点、组装图摘要、backfill 历史字段等纯 Python 逻辑。

---

## 3. 目标目录布局

```
Aker/
├── README.md                       # 用户入口文档
├── setup.py                        # pip install -e . 入口
├── aker/                           # Python 包，按层分子包
│   ├── __init__.py
│   ├── __main__.py                 # python -m aker …
│   ├── cli.py                      # 用户 CLI：aker new / aker run
│   │
│   ├── infra/                      # 低层原语
│   │   ├── codex.py                # CodexClient + CodexSession
│   │   └── locks.py                # fcntl 封装（reservations / leaderboard）
│   │
│   ├── gpu/                        # GPU 服务层（§6.1–§6.2）
│   │   ├── broker.py               # FIFO 队列 + subprocess runner + 超时
│   │   ├── client.py                # unix socket 客户端 + BrokerGone
│   │   └── worker_cli.py            # `akerjob` 入口（sandbox 内调用）
│   │
│   ├── state/                      # on-disk 状态模型
│   │   ├── graph.py                # scan_nodes / scan_in_flight / summary
│   │   ├── reservation.py          # N 分配 + open/close 事件 + sweep
│   │   └── leaderboard.py          # row 组装 + .jsonl append + .md regen
│   │
│   ├── phases/                     # 编排层
│   │   ├── review_loop.py          # 通用 worker+reviewer 循环
│   │   ├── spec.py                 # spec.run(task_dir, description)
│   │   ├── bootstrap.py            # bootstrap.run(task_dir)
│   │   └── iterate.py              # iterate.run(task_dir, rounds=N, parallel=M)
│   │
│   └── prompts/
│       ├── spec_generator.md
│       ├── bootstrap_worker.md
│       ├── bootstrap_reviewer.md
│       ├── bootstrap_worker_fix.md
│       ├── bootstrap_reviewer_recheck.md
│       ├── iterate_worker.md
│       ├── iterate_reviewer.md
│       ├── iterate_worker_fix.md
│       └── iterate_reviewer_recheck.md
├── dev/
│   ├── plan.md                     # 本文档
│   └── parallel.md                 # 并发方案设计（v4）
├── tasks/<task_name>/              # 每个任务一个子目录（.gitignore 掉）
│   ├── spec.md
│   ├── testlib.py / test_acc.py / test_perf.py
│   ├── leaderboard.{jsonl,md}
│   ├── _bootstrap_log.md
│   ├── _iterate_logs/<reservation_id>.md
│   ├── _reservations.jsonl         # reservation 事件日志
│   ├── _gpu_jobs.jsonl             # broker 审计
│   ├── _orphans/                   # crash 搬运的 staging 目录
│   ├── .broker.sock                # per-run unix socket（ephemeral）
│   ├── .broker.heartbeat           # broker mtime heartbeat
│   ├── .reservations.lock          # fcntl 锁文件
│   ├── .leaderboard.lock           # fcntl 锁文件
│   └── nodes/v<N>_<tag>/
│       ├── kernel.cu
│       ├── kernel.py
│       ├── meta.json
│       ├── notes.md                # 设计文档（core strategy / rejected alternatives / invariants）
│       ├── report_acc.json
│       ├── report_perf.json
│       ├── audit.json              # Python 写的本轮 audit 结果（§6.10）
│       └── profile/                # 可选：ncu / SASS 原始产物（v1 未实现）
└── tests/                          # 薄 harness
    ├── test_codex.py
    ├── test_spec.py
    ├── test_bootstrap.py
    ├── test_iterate.py
    ├── test_broker.py              # broker + akerjob 端到端
    ├── test_reservation.py         # N 分配 / sweep / in-flight
    └── test_leaderboard.py         # row 组装 + md 排序
```

依赖方向严格：`cli → phases → {state, gpu} → infra`；`state` 之间单向
（leaderboard / reservation 都依赖 infra.locks；graph 在运行时按需导入
reservation 以避免循环）。gpu/worker_cli 仅依赖 gpu/client；broker 与
client 独立无相互依赖。

---

## 4. 核心设计决策（已固化，改动需要重新讨论）

| # | 决策 | 依据 |
|---|---|---|
| D1 | Codex 作为唯一 AI 底座，分两个角色（worker / reviewer），两条独立 session | worker 写代码、reviewer 审契约，天然 soft check；用同一底座避免多 LLM 协调问题 |
| D2 | 三阶段用独立 prompt + 磁盘文件传状态，不用结构化数据 | "不要格式化数据"；磁盘就是协议 |
| D3 | spec 只描述 WHAT，绝不描述 HOW（accumulator dtype / tile size / 指令名等） | 避免早期锚定，留给下游探索 |
| D4 | 精度测试纯观测，不设阈值，不做跨节点对照 | 每种实现精度特性不同；硬阈值会误伤正确实现 |
| D5 | 性能唯一评估指标是 runtime；诊断指标（带宽/TC 利用率）只报告不 gate | 只有一个目标函数才有清晰的 rank |
| D6 | 无 baseline（不和 torch eager / torch.compile 对比） | 很多 kernel 可能是首次实现，没有 baseline 可比 |
| D7 | 所有节点统一接口：`kernel.cu` + `kernel.py`（5 行 `torch.utils.cpp_extension.load()` 包装）| 测试基础设施复用的前提 |
| D8 | 全 CUDA C（包括 v0），不写 PyTorch reference | PyTorch 和 CUDA C 的 fp8/nvfp4 等类型接得不干净 |
| D9 | 测试脚本拆成 `test_acc.py` + `test_perf.py` + `testlib.py`，CLI 用 `--version v<N>` | 独立 re-run 某一类测试 |
| D10 | v0 不是"reference"，只是"graph 的第一个节点" | 不给它特殊地位；未来节点产出不同 bit-exact 也算正确 |
| D11 | 反 reward-hacking 规则直接写进 spec §9 和各 prompt | 从源头堵漏；文献里多篇的教训 |
| D12 | Shape 大小由 LLM 自行推理，不在 prompt 里写死数字 | 避免 anchoring；不同 kernel saturation 阈值不同 |
| D13 | worker + reviewer 的 prose 完全自由；Python 只靠**一个**硬信号 `VERDICT: PASS/RETRY` 决定循环终止 | "不要硬格式规定 LLM 推理内容，但程序没法像人一样 check 自然语言，终止信号需要 hard token" |
| D14 | 每节点 `notes.md` 作为 design doc，与 `meta.json.rationale` 职责分离 | `rationale` 记 delta（对父节点的变更理由）；`notes.md` 记 state（当前 kernel 是什么，为什么这么写）——让从 v<N> 起新工作的 worker 能快速理解历史 |
| D15 | NCU / SASS 的原始产物持久化到 `nodes/<id>/profile/`（可选） | 跨节点 diff profile 指标是定位瓶颈的最快方式；只留文字结论就丢了原始数据 |
| D16 | NCU/SASS 是 late-stage 工具，高层想法还有收益时不碰 | 过早 profile 把图锚在第一个 naive 实现的瓶颈上，陷入局部最优 |
| D17 | iterate worker session 在随机 `[1,5]` 轮后 renew；reviewer 每轮 fresh | trade-off：fresh session 丢掉上轮推理肌肉；长 session 容易陷错误 mental model。reviewer 久了会对 PASS 松懈 |
| D18 | `iterate_worker.md` 用"第一性原理找瓶颈"框定方向选择，不列优化 checklist | 清单式 prompt 会让 AI 机械对号入座，反而限制想象力 |
| D19 | mutate 和 merge 从 iterate 第一轮起并行开放，不强制顺序 | 原先 D13 计划"先只 mutate"；实测到第 17 轮 AI 自然触发第一次 merge（session carry 刚好让它记得之前的节点） |
| D20 | 用户接口就两条命令（`aker new` + `aker run`），中间态和错误恢复靠幂等性而非额外命令 | bootstrap 崩了重跑 `aker new` 即可续做；减少命令表面积 |

---

## 5. 实现进度

### 已完成

- [x] **CodexClient + CodexSession**（`aker/codex.py`）
  - `codex exec` 一次性 + `codex exec resume` 多轮对话
  - 工作目录快照 + diff 报告 `files_created` / `files_modified`
  - `final_message` 通过 `-o` 单独捕获
  - 可配置 `--model` / `--sandbox` / `--skip-git-repo-check` / `--ephemeral`
  - 从 stderr banner 解析 session id，支持跨轮 resume

- [x] **Spec 阶段**
  - `aker/prompts/spec_generator.md`：9 小节结构，WHAT-not-HOW 黑名单，反 reward-hacking
  - `aker/spec.py::run(task_dir, description)` → `SpecReport`

- [x] **Bootstrap 阶段**
  - worker + reviewer 双 codex 循环（`review_loop.py`）
  - `aker/prompts/bootstrap_{worker,reviewer,worker_fix,reviewer_recheck}.md`
  - `aker/bootstrap.py::run()` + audit（文件齐全 / leaderboard 有效行 / report_acc 无 NaN/Inf）

- [x] **Iterate 阶段**
  - `aker/graph.py`：`scan_nodes` / `format_graph_summary`（leaderboard 表 + per-node detail + notes.md/profile 指针）/ `backfill_v0_meta` / `backfill_notes_md`
  - `aker/iterate.py::run(task_dir, rounds=N)` + audit（新节点唯一性 / meta 字段 / parents 存在 / OK 节点的 leaderboard 行 / FAIL 节点的 failure_reason）
  - `aker/prompts/iterate_{worker,reviewer,worker_fix,reviewer_recheck}.md`
  - 第一性原理瓶颈分析、NCU/SASS 使用与持久化指引

- [x] **Worker session 随机寿命 carry**
  - 每新建一个 worker session 独立 `randint(worker_session_min_rounds, worker_session_max_rounds)`；可选 `rng_seed`
  - crash 自动强制下轮起新 session
  - reviewer 每轮 fresh

- [x] **CLI + 安装**
  - `aker/cli.py` 子命令 `new` / `run`
  - `aker/__main__.py` 支持 `python -m aker …`
  - `setup.py` 注册 `aker` console script

- [x] **文档**
  - `README.md`：用户入口
  - `dev/plan.md`：本文档

### 已实测但尚未触发的能力

- **NCU / SASS profile 持久化**
  管道就绪：prompt 指引 worker 在瓶颈期把输出 dump 到 `profile/`；`graph.py` 扫 `profile/` 并在 summary 里标出哪些节点可以跨 diff。
  截至第 17 轮 AI 从未主动 profile——每轮总能找到高层想法推进，没陷到需要 microarch 分析的程度。等瓶颈期实际到来才能验证闭环。

### 待办

- [ ] **Crash 后的 partial node 清理**
  如果 worker 崩在写文件中途（或 retry 换 node_id 时漏删旧目录），`nodes/` 下会有孤儿目录污染下一轮 graph summary。
  目前靠 `iterate_worker_fix.md` 里一句 prompt 要求 worker 自己清理；缺 Python 侧兜底（比如 audit 检测到多余目录时迁到 `_orphans/`）。

- [ ] **spec 迁移策略**
  用户中途改 spec（比如换 primary shape）时，历史 leaderboard 条目如何标记？`report_*.json` 已经记 `spec_version_hash`，但没有失效/迁移机制。

- [ ] **并发 iterator**
  目前 `iterate.run` 严格串行。后续可能要 N 个 worker 并发扩图——需要解决 leaderboard 并发写、node id 分配冲突。

- [ ] **图可视化**
  `nodes/ + leaderboard.jsonl` 完全可以渲染成 graphviz DAG；优先级低。

- [ ] **Leaderboard 筛选**
  图大了之后 `leaderboard.md` 会难读，可能要分页或只留 Pareto 前沿。

---

## 6. 里程碑

| Milestone | 交付 | 状态 |
|---|---|---|
| **M-A** spec 阶段跑通 | CodexClient 能调；spec_generator prompt 产出可接受 | ✅ 完成 |
| **M-B** bootstrap worker+reviewer 循环跑通 | v0 节点、test infra、leaderboard 全部产出，review 首轮 PASS | ✅ 完成 |
| **M-C** iterate MVP | 能连跑 N 轮，每轮加一个节点，自动 audit | ✅ 完成（已跑到 v17，含 1 个 merge 节点） |
| **M-D** CLI + README | `aker new` / `aker run`，`pip install -e .` | ✅ 完成 |
| **M-E** merge 支持 | iterate prompt 和 audit 都认 merge | ✅ 完成（第 17 轮自然触发第一次） |
| **M-F** NCU 持久化管道 | 产物落 `profile/`，下轮图摘要标记 | ✅ 代码就位；⏳ 等 AI 真的在实跑中 profile |
| **M-G** session carry 机制 | 随机寿命 worker 跨轮保留记忆 | ✅ 完成 |
| **M-H** Crash / orphan 清理 | Python 兜底，不依赖 AI 自觉 | ⏳ 未开始 |

---

## 7. 开放问题（到点再决定）

- **Termination 规则**：目前靠用户指定 `--rounds N`。未来可能要"连续 K 轮无改进自动停" / "预算上限" / "Pareto 前沿饱和"等。
- **Merge 频率**：AI 对 merge 偏保守（17 轮才首次触发）。是否要在 prompt 或外层策略里软鼓励？目前观察是 session carry 生效的那轮才出现 merge——可能寿命策略本身就是 merge 触发的杠杆。
- **Spec 版本化**：同上"已知待办"，实施路径未定。
- **跨进程 session 持久化**：目前 `--rounds 1` 连续调用之间不共享 worker session。跨进程需要状态文件 + stale session 处理；当前不做。
- **Reviewer 严格度**：到第 17 轮 reviewer 只触发过 1 次 RETRY——这是 prompt 太宽还是 worker 太稳？样本还不够说明问题。
- **多硬件目标**：当前 prompt 里写死 Hopper 指令（`cp.async` / TMA / `ldmatrix`）。要支持别的卡需要抽出"target-hw"段或在 spec 里动态注入。

---

## 8. 文献支撑

本项目的设计取舍大量借鉴了对 23 篇 LLM-driven kernel generation 论文的综合。关键参考点：

- **worker + reviewer 双 codex** 类似 CUDA Agent 的 coder/checker 分离，但我们的 reviewer read-only sandbox 更强制化
- **uniform interface + 复用测试** 对应 Sakana robust-kbench 的 ParallelKernelExecutor 模式
- **反 reward-hacking 清单** 综合了 CUDA-L1 v2 / Sakana / CUDA Agent 的经验
- **LLM 自主推理 shape sizing** 借鉴 GPU Kernel Scientist 的"由 LLM 自己决定实验参数"
- **"精度观测不 gate"** 对齐 Sakana 的 soft-verification 思路（尽管他们仍有硬阈值，我们更激进）
- **graph 迭代 + Codex 自主 planner** 最接近 K-Search 的 intent-tree + AlphaEvolve 的 program database 组合
- **跨节点 profile diff** 对应某些论文里"对比快慢版本 NCU 指标找关联"的做法——我们通过持久化 `profile/` 让这个 workflow 跨轮可用
- **第一性原理 bottleneck 分析** 替代清单式 optimization menu，来自对"prompt 越具体越锚定"这个观察的直接应对

---

## 9. 文档间职责划分

- **`README.md`**：用户入口。怎么装、怎么跑、每个命令是啥。
- **`dev/plan.md`**（本文档）：开发决策记录 + 待办。改动实现需要先核对 §4 的决策。
- **`aker/prompts/*.md`**：对 codex 的契约，是"需求文档"的另一种形式。改 prompt 等同于改 product spec。
- **`tasks/<name>/spec.md`**：单个任务的 task spec，由 AI 生成，人工可改。
- **`tasks/<name>/nodes/<id>/notes.md`**：单个 kernel 的 design doc，由 AI 生成。
