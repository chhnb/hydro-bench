# aker 并行化设计方案

**状态**：设计稿 v2，待 review
**日期**：2026-04-24（v1: 2026-04-23）
**作者**：设计草案由模型起草，决策由项目负责人拍板

> v2 变更：根据第一轮 review 反馈补写了 §6.8（`CUDA_VISIBLE_DEVICES`
> 物理隔离）、§6.9（compile/load 路径取舍）、§6.10（audit 校验项清单）、
> §6.11（broker crash 与 pool 清理）；修订 P6、新增 P16–P21；§6.3 增
> 加 reservation 级顶层超时、日志文件名改用 `reservation_id`；§11 把
> compile 路径验证实验列为实施前置。
>
> v3 变更（第二轮 review）：§6.9 实验设计改为双进程拓扑 + load-then-fire
> kernel；§6.10 A4 判据从"open 冻结"改为"close 时刻已 committed"；§6.8
> 对 (b) 下 P17 强度的表述从"半套"改为"几乎完整"；§6.11 增加 slot OOM
> /SIGKILL 时主进程的 reservation 补救 + 客户端 `socket.settimeout`；
> §6.7 设备锁加 stale PID takeover；§6.3 close status 枚举补齐；§6.9
> 方案 (c) 成本重估；其他小修。
>
> v4 变更：集中新增 §6.12（并发读写协议总览）把 leaderboard 写路径、
> graph 信息读路径、2 把文件锁、slot 视图一致性边界四件事一节讲清楚；
> P20 扩展为"jsonl 和 md 都只由主进程写"。

> 项目整体目标、阶段划分、已固化决策见 `README.md` 与 `dev/plan.md`。本
> 文档聚焦一个问题：**如何把 iterate 阶段从严格串行改成同一 task 内多
> worker 并发扩图**，以及这样做引入的一致性与资源竞争问题如何解决。
> 用词遵循 `dev/plan.md` 的惯例：新增的设计决策编号为 **P1, P2, …**。

---

## 1. 为什么做这件事

当前 `iterate.run(task_dir, rounds=N)` 一轮一个节点严格串行：worker 写代码 → 跑
acc/perf → reviewer 看 → audit → 下一轮。每轮里 **GPU 测量是瓶颈之一**
（代码生成本身就几分钟，再加 compile + acc + perf），把这段时间串起来
浪费。

直觉：**代码生成可以并行，GPU 测量必须串行**——这两者粒度差一个量级，把
它们绑在同一串行链路上等于把廉价操作也串了。只要把"谁能用 GPU"和"谁在写
代码"解耦，就能把 1-5 个 worker 的 wall-clock 大幅压下来。

预期场景：

- **并发度**：1–5 个 worker，共享一张 GPU
- **进程模型**：multiprocessing（不用线程，隔离干净、不共享 GIL、codex
  本身就是 subprocess 不怕 fork 开销）
- **同 task**：所有 worker 跑在同一个 `task_dir/` 下，共同扩展同一张图
- **Codex session 寿命**：每个 slot 独立维护自己的随机寿命（保持 D17 不变）

---

## 2. 串行模型下的共享状态

当前一个 task 下的共享状态，按"改不可逆"程度排序：

| # | 共享状态 | 写入时机 | 读取时机 |
|---|---|---|---|
| S1 | `nodes/v<N>_<tag>/` 目录（`kernel.cu`/`meta.json`/`notes.md`/`report_*.json`/`profile/`） | worker 写 | worker 读（下一轮）+ reviewer 读 + Python 扫图 |
| S2 | `leaderboard.jsonl`（append-only） | worker 写 | worker 读 + Python 扫图 |
| S3 | `leaderboard.md`（每轮重生） | worker / Python 写 | 人读 |
| S4 | `_iterate_logs/round_NNN.md` | review_loop 写 | 调试 |
| S5 | **GPU 本身**（物理资源） | `test_perf.py` 占用 → 测 CUDA event | — |

S1–S4 是文件状态，S5 是物理资源。串行下这 5 项自然一致，并发下要逐项处理。

---

## 3. 并发下的失败模式

| # | 失败模式 | 影响的共享状态 | 后果 |
|---|---|---|---|
| C1 | 两 worker 挑到同一个 `v<N>_<tag>` | S1 | 目录名冲突 / 互相覆盖 |
| C2 | round 号冲突 | S4 | 日志互盖 |
| C3 | `leaderboard.jsonl` 并发 append 撕裂 | S2 | 脏 jsonl |
| C4 | `leaderboard.md` 并发重生互盖 | S3 | 中间态不一致（可恢复） |
| C5 | worker A 启动快照里没有 B 还没完成的 v19 | S1 | 方向重复探索——**浪费、非正确性** |
| C6 | audit 用 `after - before`，期间 B 提交会让 A 看到两个"新节点" | — | 误报 FAIL_AUDIT |
| C7 | 两个 test_perf 同时跑，GPU 抢占 | S5 | **mean_ms 失真，最阴险**——不 crash 只骗人 |
| C8 | reviewer 读到 peer worker 半成品目录 | S1 | 评审评论错目标（可控） |
| C9 | 某轮 test_perf 死循环卡住 | S5 | 阻塞整个 GPU，后续所有轮都动不了 |

**C7、C9 最危险**。串行下它们本来不存在；并发一上来就会撞上。C1–C4 是老
生常谈，靠 ID 分配 + 文件锁可以解决。C5/C8 是允许接受的代价（只会浪费，
不会错算）。C6 需要重写 audit 的"新节点识别"逻辑。

---

## 4. 设计原则（把 idea.md §4 照进来）

`dev/idea.md` §4 的原则："**sandbox 是最 load-bearing 的。'不许编辑' 作
为 prompt 指令会被违反；作为 OS 权限不会。**" 同一句话在 GPU 独占上的等
价：

> "GPU 每次只给一个 worker" 作为 prompt 会违反；作为**架构级串行化**不会。

所以本方案的核心不是"加锁"，而是**把 GPU 访问从 worker 的直接调用改成
向中心 broker 提交异步 job**。锁变成队列的副作用而不是显式机制。

---

## 5. 架构总览

```
┌───────────────────── aker run ─────────────────────┐
│                                                    │
│   multiprocessing.Pool(size=N)                     │
│                                                    │
│   ┌──────┐  ┌──────┐  ┌──────┐                    │
│   │slot 1│  │slot 2│  │slot 3│  …  N 个进程        │
│   │      │  │      │  │      │     各自跑 codex    │
│   │codex │  │codex │  │codex │     session + review │
│   └──┬───┘  └──┬───┘  └──┬───┘                    │
│      │         │         │                         │
│      │   unix socket     │                         │
│      └────────┬──────────┘                         │
│               ▼                                    │
│       ┌───────────────┐                            │
│       │  GPU Broker   │   单进程，FIFO 队列         │
│       │  (1 process)  │   一次只跑 1 个 subprocess │
│       └───────┬───────┘                            │
│               ▼                                    │
│    subprocess: test_acc.py / test_perf.py /        │
│                ncu / cuobjdump / ...               │
└────────────────────────────────────────────────────┘
```

- `aker run` 启动时 fork 出 **1 个 broker** + **N 个 worker slot**
- 结束时杀掉进程组
- broker 生命周期 = `aker run` 进程生命周期（**不做常驻 daemon**，见 P5）
- 多 aker run 同时在一张 GPU 上跑 → 不支持；靠 per-device flock 拒绝（P13）

---

## 6. 组件设计

### 6.1 Broker（`aker/broker.py`）

**职责**：

1. 在 `task_dir/.broker.sock` 上听一个 unix socket
2. 维护 **FIFO 队列**，一次只允许一个 subprocess 在跑
3. 执行提交的 job（下面四种），带每种的默认超时
4. 超时：SIGTERM → 10s → SIGKILL，返回 TIMEOUT + partial stdout/stderr
5. 写 `task_dir/_gpu_jobs.jsonl`（审计；**best-effort append、不 fsync**——
   该文件不在 audit / reservation 的不变量关键路径上，SIGKILL 丢最后几条
   不影响 session 正确性）

**支持的 job 种类**（初版）：

| kind | 默认超时 | 报告写入位置 |
|---|---|---|
| `test_acc` | 300s | `nodes/<node_id>/report_acc.json` |
| `test_perf` | 600s | `nodes/<node_id>/report_perf.json` |
| `profile_ncu` | 900s | `nodes/<node_id>/profile/ncu_*.txt` |

**不经 broker 的分析工具**：`cuobjdump --dump-sass <.so>` 和 `nvdisasm`
是纯静态 ELF/cubin 读取，不触 device，不占 GPU。worker 在自己 sandbox
里直接跑即可，不需要 FIFO 串行化。

**不经 broker**（继续在 worker 本地并行执行）：

- 文件读写（kernel.cu / notes.md / meta.json / ...）
- 具体 compile / load 如何处置**见 §6.9**。初版 P6 把这里写成"compile
  并发、torch 内置锁够用"是过度简化——`torch.utils.cpp_extension.load()`
  既 compile 又 load，后者会 init CUDA context，直接冲击 broker 的
  "GPU 唯一持有者"不变量。§6.9 列三条备选路径并指定验证实验。

**协议**（JSON over unix socket，一问一答阻塞式）：

请求：
```json
{
  "kind": "test_perf",
  "node_id": "v18_foo",
  "task_dir": "/abs/path/to/tasks/fp8_cast",
  "extra_args": [],
  "client_timeout_sec": 900
}
```

响应：
```json
{
  "job_id": "job-0042",
  "status": "OK" | "TIMEOUT" | "SUBPROCESS_NONZERO" | "BROKER_ERROR",
  "queue_wait_ms": 1200,
  "run_ms": 45000,
  "stdout": "...",
  "stderr": "...",
  "report_path": "nodes/v18_foo/report_perf.json"
}
```

**关键不变量**：broker 是 GPU 的**唯一持有者**（P1）。不再有 fcntl 锁、
不再改 testlib.py、不给 LLM 做 gpu_exclusive() 上下文管理器——独占性由
"一次只跑 1 个 subprocess"这条架构级约束隐式保证。

### 6.2 Worker CLI（`akerjob`，`aker/worker_cli.py`）

**独立 console script**，和用户面向的 `aker` 彻底分开（P2）。

```
akerjob test_acc   --node <id>
akerjob test_perf  --node <id>
akerjob profile ncu   --node <id> [--sections ...]
```

**task 归属不走 `--task` 参数**，走环境变量：

```
AKER_BROKER_SOCK=/abs/path/to/tasks/fp8_cast/.broker.sock
AKER_TASK_DIR=/abs/path/to/tasks/fp8_cast
```

这两个 env 由 `aker run` 在 spawn worker slot 时注入 slot 进程；slot
spawn codex subprocess 时继承下去；LLM 的 shell 再继承；`akerjob` 从 env
读取。好处：

- 命令表面干净——LLM 只写 `--node v18`
- **LLM 无法误写错 task**（env 固定，不在它能修改的地方）
- 多 `aker run` 跑不同 task 时每个 slot 自动绑自己那份 env

`setup.py` 里注册两个 entry point：

```python
entry_points={
    "console_scripts": [
        "aker    = aker.cli:main",           # user-facing
        "akerjob = aker.worker_cli:main",    # internal; runs inside codex sandbox
    ],
}
```

### 6.3 Reservation（`aker/reservation.py`）

**Python 侧分配节点版本号 N**（P3）。LLM 不再从 graph summary 里推断
"下一个该用哪个号"，而是被告知 `N = 18`，由它选 `<tag>`。

**数据结构**：`task_dir/_reservations.jsonl`，一行一次 reservation 事件。

```jsonl
{"event":"open","reservation_id":"r-20260424-001","reserved_n":18,"slot_id":"s2","pid":12345,"start_ts":"..."}
{"event":"close","reservation_id":"r-20260424-001","status":"committed","end_ts":"..."}
```

**`close.status` 枚举**（v3 补齐）：

| status | 触发场景 |
|---|---|
| `committed` | audit 全部通过，节点正常落盘（包括 `attempt_status=FAIL` 但契约合规） |
| `audit_failed` | review PASS 但 §6.10 的 A1–A9 至少一条违反 |
| `bailed_no_node` | LLM session 主动放弃、没写出任何目录；无 audit 意义上的错误，单纯"这一号作废" |
| `crashed` | slot 或 broker 异常（OOM / SIGKILL / BROKER_GONE / 超时），reservation 未能走到正常 close |

无论哪种 close 结果，P4 仍生效——N 永久 retired。

**分配规则**：在 `.reservations.lock` 下 `N = max(所有曾出现过的 N) + 1`。
**N 永不重用**（P4）——即使 crash，v18 被永久 retired。代价只是节点号出
现空洞，换来 audit/leaderboard 的不变性极简。

**状态派生**（避免维护独立状态机）：

| 衍生状态 | 判据 |
|---|---|
| committed | `nodes/v<N>_<tag>/meta.json` 存在且可解析 |
| in-flight | reservation 的 close 事件未出现 **且** 磁盘上未出现 `v<N>_*/` 目录 |
| crashed / stale | reservation open 超过 **`reservation_timeout_sec`**（默认 3600s，P18）且无对应目录 |

**reservation 级顶层超时（P18）**：reservation 贯穿整个 round（codex 生
成 + 多次 broker job + reviewer 审），不能和单个 job timeout（300~900s）
耦合。单独给一个顶层上限 `reservation_timeout_sec`，默认 3600s 兜底；超
过即判 stale。和 `--timeout-sec`（codex session 上限）取 max 更稳。

**日志文件名对齐（解决 C2）**：`_iterate_logs/round_NNN.md` 在并发下语
义不清，改用 `reservation_id` 作主键：`_iterate_logs/<reservation_id>.md`
（形如 `r-20260424-001.md`）。一个 reservation 对应一个 round 日志、一
条 jsonl 条目、一个 N。

**孤儿处理**（P7）：next round 启动时 Python 扫 reservations，stale 的：

- 如果 `nodes/.v<N>_*.tmp/` 存在 → `shutil.move` 到 `_orphans/<ts>_v<N>_*/`
- 如果 `nodes/v<N>_*/` 已存在但未 close（意味着 crash 在 rename 之后、
  close 之前）→ 按正常 committed 处理，再补一条 close 事件
- reservation 标记为 crashed

### 6.4 Staging rename（解决 C8）

Worker 把所有文件先写到 `nodes/.v<N>_<tag>.tmp/`，**全部写完后** `os.rename`
到 `nodes/v<N>_<tag>/`。同分区内 rename 原子，reviewer 不可能看到半成
品。

这点**进 prompt 硬约束**（iterate_worker / bootstrap_worker 各改一段）。
rename 失败也由 worker 自己处理——Python 侧不介入，因为介入就要介入写
入过程。

### 6.5 Graph summary 的 in-flight section（`aker/graph.py`）

当前 `format_graph_summary` 只扫 `nodes/`。新增：扫 `_reservations.jsonl` 里
没 close 的项，在 summary 末尾加一段：

```
## In-flight (other workers are currently working on these — do not branch from them)
- v19 — parent v17, direction: "warp-specialized epilogue" (started 03:41, slot 2)
- v20 — (no meta yet, slot 3 still generating)
```

- direction / parent 通过 peek `nodes/.v<N>_*.tmp/meta.json`（若已写）获取
- 没有 meta 就只显示 "no meta yet"
- **JSON parse 竞态兜底**：peek 时另一个 worker 可能正在写这份 meta.json，
  POSIX 下读不会坏文件但可能拿到半成品。`json.loads` 抛异常时 fallback 到
  "no meta yet"，不报错

**Prompt 硬约束**（iterate_worker.md 加一段）：

> In-flight entries are informational only, intended to help you avoid
> duplicating a direction another worker is already exploring. You MUST
> NOT list an in-flight node in your `parents` field; only committed
> nodes are valid parents.

Reviewer 的 prompt 也加一句"只评审 new_node_id 这一个目录"——避免评审时
对 peer 在写一半的 `v20` 发表意见（P10）。

### 6.6 Worker pool 调度（`aker/iterate.py`）

**`--parallel N`**，默认 1（向后兼容）。

```python
# 伪代码
import multiprocessing as mp
mp.set_start_method("spawn", force=True)   # P16：不用 fork
broker = spawn_broker(task_dir)
try:
    with mp.Pool(N) as pool:
        rounds_iter = iter(range(1, total_rounds + 1))
        # 每个 slot 循环取 next round，直到用完
        for _ in pool.imap_unordered(run_one_round, rounds_iter):
            pass
finally:
    broker.terminate(); broker.wait()
```

**启动方式固定 `spawn`（P16）**：默认 `fork` 在 Linux 下会把父进程状态
原样复制到 slot，任何父进程里有过的 CUDA/torch 预初始化都会污染子进程
——broadcast 到每个 slot，后面又各自 import torch 就容易触发诡异的
context 错误。`spawn` 从零启动干净。代价是 slot 启动慢 ~0.5s，对 codex
session（分钟级）可忽略。

**不 stagger**（P11）：N 个 slot 启动时齐刷刷冲进来，broker FIFO 自然
串行化。初始 snapshot 相同导致方向撞车是接受的代价——1–5 并发下多样性
够用。

**每 slot 独立 session 寿命 RNG**：`rng_seed` 参数经过 `base_seed +
slot_id` 派生，保持确定性。

**`leaderboard.md` 的写入者**：由 **主进程**在每次 reservation close 后
统一重生（不由 slot 写），持 `.leaderboard.lock`。slot 只 append
`leaderboard.jsonl`（同样持该锁）。避免 C4：多 slot 重生 `.md` 互盖。

### 6.7 设备级防御（P13）

`aker run` 启动时：

```python
import fcntl, hashlib, os, sys
raw = os.environ.get("CUDA_VISIBLE_DEVICES", "0")
# normalize 成稳定形式：逗号分割 → sort → 连字符连；过长时改用 hash
parts = sorted(p.strip() for p in raw.split(",") if p.strip())
norm = "-".join(parts) if parts else "0"
if len(norm) > 32:
    norm = hashlib.sha1(norm.encode()).hexdigest()[:16]
lock_path = f"/tmp/aker_gpu_{norm}.lock"
lock_fd = open(lock_path, "a+")
try:
    fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    # lock 被持有——但可能是 stale（上次 aker run SIGKILL 没清理）
    lock_fd.seek(0); prev_pid_str = lock_fd.read().strip()
    try:
        prev_pid = int(prev_pid_str)
        os.kill(prev_pid, 0)  # 进程还在？
        sys.exit(f"GPU device {raw!r} already managed by aker run PID {prev_pid}")
    except (ValueError, ProcessLookupError):
        # stale → takeover：重新尝试拿锁
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
# 拿到了；覆写 PID
lock_fd.seek(0); lock_fd.truncate()
lock_fd.write(f"{os.getpid()}\n"); lock_fd.flush()
```

简单、粗暴、够用。拒绝同一物理 GPU 上并存两个 **活着的** `aker run`，但
允许自动 takeover 被 SIGKILL 留下的遗留锁。

**已知小洞**：不同顺序（`0,1` vs `1,0`）经 normalize 后会命中同一锁；但
**设备列表相同**这件事本身就是"同一组 GPU"，撞锁是期望行为。真正的小
洞是用户 **同时** 设 `CUDA_VISIBLE_DEVICES=0` 和未设（默认 0）——前者锁
名 `aker_gpu_0.lock`，后者 fallback 也是 `"0"`，会相撞——也属于期望行
为。没有真正的逃逸路径。

### 6.8 `CUDA_VISIBLE_DEVICES=""` 物理屏蔽 codex sandbox（P17）

**动机**：§8 prompt 改动清单里那句"禁止 LLM 直接跑 `python test_*.py` /
`ncu` / `nvidia-smi`"只是 prompt 约束——按 idea.md §4 的原则，这种约
束会被违反。对应的物理化做法：**slot 在 spawn codex subprocess 时，把
`CUDA_VISIBLE_DEVICES=""` 写进子进程环境**。LLM 无论怎么写 `python -c
"import torch; torch.zeros(1).cuda()"` 都只会看到 "no CUDA GPU"，唯一
能真正触到 device 的路径只剩 `akerjob → broker`——因为 broker 是**另
一个进程**，它的 env 由 `aker run` 主进程独立设置，继承不到 codex 这一
路的空值。

**与 §6.9 的相互约束（v3 修订）**：即便 §6.9 选路径 (b)，P17 的实际保
护范围比初版估的更完整——

- **slot 进程**（父，multiprocessing worker）持有真 `CUDA_VISIBLE_DEVICES`，
  给自己在 (b) 下做 `load()` 用
- **codex subprocess** 由 slot spawn，其 env 被显式覆盖为
  `CUDA_VISIBLE_DEVICES=""`
- LLM 在 codex sandbox 里起 shell → 新 Python 进程 → 继承 codex env →
  `CUDA_VISIBLE_DEVICES=""` → 新进程看不到 device；即使它 `import torch`
  也拿不到 slot 进程里已建立的 context（**进程间 CUDA context 不共享**）

所以 (b) 下 LLM 通过 Python 间接摸 GPU 的唯一路径就是不存在的。真正的
差别只剩 "**worker 进程本身**会在其生命周期内持有 CUDA context"，而那个
进程里根本没有 LLM 代码在跑。结论：**(b) 下 P17 几乎完整，只在"slot 进
程自己是否占 context"这件无关 LLM 的事上比 (a)/(c) 少一层**。

这点修正会让 (b) 方案的吸引力略增——§6.9 实验阈值（2%）仍可按原定。

nvcc 编译本身不依赖可见 device（靠 `TORCH_CUDA_ARCH_LIST`），所以 (a)
方案里 worker 端的编译（若有）也不受影响。

### 6.9 Compile / load 的路径取舍（取代旧 P6）

`torch.utils.cpp_extension.load()` 是 compile + load + import 一体的，
**load 这一步会 init CUDA context**。如果 worker 在 broker 外调用
`load()`：

- 多 worker 并发 load 不同扩展名时不共享 torch 的 build lock（其 lock 是
  per-extension-name 的），nvcc 会打架——CPU/IO 吵架还好
- 更要命的是 **context init 会和 broker 里正在跑的 test_perf 物理重叠**
  ——对方在测 CUDA event，你这边 `cuCtxCreate` 抢 SM 时钟 / 显存带
  宽，mean_ms 抖动——正是 C7 "最阴险"的那一条

"broker 是 GPU 唯一持有者"的不变量从 day 1 就破了。旧 P6 "torch 内部
build lock 够用"是错的：那把锁只管编译不管 context。

**三条备选**：

| 路径 | 做什么 | 代价 | 物理隔离（配 P17） |
|---|---|---|---|
| **(a)** 全进 broker | `load()` 和测量都在 broker 子进程里；worker 只写文件。cold compile 随测量一起串行。 | cold compile 变串行：N=5 时整体并行收益缩水（compile 占 round 时间 10–30%） | 完美：codex sandbox 可设 `CUDA_VISIBLE_DEVICES=""` |
| **(b)** worker 本地 load，broker 只测 | worker compile + load → context init 发生在 worker 进程；broker 子进程单独 init 一份 context 跑测量 | 保留并行收益；**风险**是 context init 和 peer 的 test_perf 物理重叠污染 timing | 见 §6.8 v3 修订：几乎完整，只在 slot 进程本身占 context 这件事上少一层 |
| **(c)** 拆开：worker 编译到 `.so`，broker 负责 import | 调 `torch.utils.cpp_extension._write_ninja_file_and_compile_objects` / `_run_ninja_build` 等半公开 helper（下划线但稳定多年），约 30–50 行胶水，另加跨 nvcc 版本 flag 继承性测试 | 保留并行 compile + 完整物理隔离 | 完美：worker 端可 `CUDA_VISIBLE_DEVICES=""` |

**方案当前倾向 (b)**，**作为实施前置必须跑验证实验**——见 §11。判定结
果分三档：

- 扰动 ≤ 2%：选 (b)
- 扰动 > 2% 但 (a) 的 compile 串行代价可接受（实测 round wall-clock 退
  化 ≤ 30%）：回退 (a)
- 扰动 > 2% 且 (a) 代价不可接受：准备 (c)（约 50 行胶水 + flag 兼容性
  测试），不作为"万不得已"

**验证实验**（P19 的兑现动作，实施 §12 步骤 1 之前必须完成）：

v3 修订：实验拓扑必须严格模拟方案 (b) 在生产中的进程结构，否则"通过"
意义不大。

**进程拓扑**：
- **Process A**（扮演 broker 子进程）：独立 `spawn` 出来的 Python 进程，
  自己的 CUDA context；反复跑 `test_perf.py` 对**同一个稳态 kernel**（提
  前 warm 完），记录 `mean_ms` 分布
- **Process B×k**（扮演 peer slot 进程，k ∈ {0, 1, 3, 5}）：每个独立
  `spawn`，各自 `import torch` → `torch.utils.cpp_extension.load()` 不
  同 module name 的小 kernel → **加载后必须真正在 GPU 上发射一次该
  kernel（跑一个 launch + sync）** → 延时 X 秒 → 下一次 load 不同 name
  的 kernel，循环 M 次

"load 完必须发一次 kernel" 这步是关键：光 `load()` 返回只能确认 ninja/
nvcc 跑完，context init 的完整路径要等到第一次 kernel launch 才触到。
初版实验只测"cold compile"会漏掉正是 C7 要担心的那层抢占。

**测量**：
- A 在 k=0 时的 mean_ms 分布（基线）
- A 在 k ∈ {1, 3, 5} 时的 mean_ms 分布
- 对比：中位数漂移、CV（变异系数）、P95 尾部。分开看三个，任一显著变
  化都视为污染

**判定**：若中位数漂移 > 2% 或 P95 尾部恶化 > 2%（绝对阈值），**否决 (b)**。

实验脚本产物落 `dev/experiments/compile_isolation/`，作为决策证据保留。

### 6.10 Audit 校验项清单（reservation 驱动）

原 §9 表格里一句"audit 从 after - before 改为 reservation 驱动"掩盖了
语义变化。当前 audit 依赖图的整体 diff 才能发现"忘 meta.json / 写错
parent / 多写一个节点"等错误；并发下 diff 语义坏掉，必须把检查点重新
落到 reservation 视角，**一条一条列清楚**：

在 `reservation.close()` 调用前，Python 对 `reserved_n = N` 执行以下检
查（任何一条失败即 `status="audit_failed"` 并 append `audit_errors`）：

| # | 检查 | 覆盖的老问题 |
|---|---|---|
| A1 | 恰好存在一个 `nodes/v<N>_<tag>/` 目录（tag 由 LLM 选但 N 必须匹配 reservation） | "写错 N"、"忘 rename" |
| A2 | 该目录下 `kernel.cu` / `kernel.py` / `meta.json` / `notes.md` 齐全 | 同原 `_audit_files` |
| A3 | `meta.json` 可解析；`node_id` 字段与目录名一致；包含必需字段 `parents / action / direction / techniques / attempt_status` | 同原 `_audit_meta` 的前半 |
| A4 | `meta.parents` 的每个 id 在 **audit 时刻（即 close 即将发生那瞬）** 属于 committed 节点集合；等价说：parent 对应的 reservation 已 `close.status=committed` 且其目录可扫到 | 执行 P9 的正确性边界；**不能完全信 prompt** |
| A5 | `action=mutate` → 恰好 1 个 parent；`action=merge` → ≥ 2 个 parent | 同原 |
| A6 | `attempt_status=OK` → `report_acc.json` / `report_perf.json` 齐全且 summary.status=OK；leaderboard.jsonl 多出该 node_id 的行；`runtime_ms_primary` 正有限 | 同原 `_audit_successful_attempt` |
| A7 | `attempt_status=FAIL` → `meta.failure_reason` 非空；leaderboard **未**出现该 node_id | 同原 `_audit_failed_attempt` |
| A8 | `nodes/` 下不存在其他以 `v<N>_` 开头的目录（防御 LLM 写两个） | "多写一个节点" |
| A9 | `_staging`（`.v<N>_*.tmp/`）已经 rename 完毕，不存在残留 | 确认 P8 执行 |

**A4 最关键**：parent 不得指向 in-flight peer。这是 P9 硬约束的**唯一
执行点**，不执行则"graph summary 里看见就随手引用"直接绕过。

**判据选择（v3 修订）**：committed 集合按 **close 时刻快照**判定——不
是 open 时冻结。初版选"open 冻结"是为了避免"引用时 in-flight、close 时
committed"的时序矛盾，但它会和 §6.5 的 graph summary 冲突：

- A 在 T0 open，graph summary 里 committed = {v1..v17}
- B 在 T0+Δ open，T0+2Δ close 为 committed v18
- A 的 codex session 里后续工具调用（长 session 会反复刷 graph 状态）
  看到 v18 已在 committed section，LLM 写入 `parents: [v18]`
- 按 "open 冻结" 判据 → v18 不在 A 的 T0 快照 → A4 误报 audit_failed
  → reservation 报废、N 被 retire。代价远大于 "接受 v18 做父"

改用 "close 时快照" 后这个误报消失。真正要禁的只是 **引用仍在 in-flight
的 peer**，"close 时已 committed" 这条判据就够了。

"close 时 peer 刚好 close" 的乐观竞态（A 引用 v19 时 v19 还 in-flight，
close 时 v19 已 committed）在新判据下是 PASS——这完全合理，那一刻
parent 就是 committed 的真节点。

`nodes/v<N>_<tag>/` 下专门立一个 `audit.json`（Python 写，非 LLM 产物）
记录本轮 audit 结果，方便后续调试。

### 6.11 Broker crash 与 Pool 清理的交互

P5 说 "broker crash → aker run 退出"——但 `multiprocessing.Pool` 和一
个正在 `socket.recv` 的 slot 之间有一套需要显式安排的动作，否则表现会
是"slot 卡着不退、pool 不缩、主进程 join 挂住"。

**场景 A：broker 死，slot 活**。期望序列：

1. broker 子进程死（OOM / 段错误 / 被人 `kill -9`）
2. 所有 slot 的 `akerjob` 调用处于 `recv()` 或已发送 `send()`——socket
   立刻收到 `BrokenPipeError` / `ConnectionResetError` / `EOFError`
3. **`akerjob` 内部捕获**这三类异常，退出码约定为 **`EXIT_BROKER_GONE=97`**
   并打印明确原因到 stderr
4. Slot 进程里的 round 驱动代码看到 97，**立刻 append 一条**
   `reservation close status="crashed" reason="broker_gone"`，然后 raise
   一个 `BrokerGoneError`
5. Pool worker 抛异常 → `imap_unordered` 在主进程一侧迭代时 re-raise
6. 主进程 `except BrokerGoneError: pool.terminate(); pool.join(timeout=10);`
   然后 sys.exit(非零)
7. 主进程 atexit 清理 `/tmp/aker_gpu_*.lock`

**场景 B：slot 被 SIGKILL（OOM killer / `kill -9`），broker 活**（v3 新
增——初版漏掉了）：slot 没机会跑 atexit / finally，reservation 留 open；
heartbeat 没断，`broker_gone` 路径不触发；**如果不主动处理，in-flight
section 里会挂一个永远写不完的"幽灵节点"直到 reservation_timeout_sec
到期**（默认 3600s）——1h 内所有 peer 的 graph summary 被污染。

必须在当次 session 处理。两条互补机制：

1. **主进程 Pool worker 死亡回调**：`multiprocessing.Pool` 自身没有 per-
   worker death hook，改用 `concurrent.futures.ProcessPoolExecutor`（能
   在 `future.result()` 上拿到 `BrokenProcessPool` + `exitcode`），或
   自己薄封装 `Process` 列表手动 `join`。主进程检测到 slot 非零退出后，
   扫 `_reservations.jsonl`，把该 `slot_id` 下所有 `open` 条目补写
   `close status=crashed reason=slot_crashed`，再决定是否替换 slot 继续
   消费后续 round。
2. **主进程 atexit 兜底**：`aker run` 进程退出前（正常或异常）扫一次
   `_reservations.jsonl`，所有仍 open 的条目补 `close status=crashed
   reason=aker_run_exit`。这是兜底的兜底，成本 ~0。

**客户端 socket timeout（v3 补）**：heartbeat "每 5s 更新 mtime / slot
recv 阻塞 > 15s 时 poll" 的逻辑需要 slot 能从 `recv()` 里醒过来才能 poll。
默认 socket 无 timeout = 无限阻塞，heartbeat 兜底永远不触发。**所以
`akerjob` 客户端建连后必须 `sock.settimeout(job_timeout_sec + 60)`**
（60s 余量覆盖 queue wait），在 `socket.timeout` 异常里检查 heartbeat
的 mtime；超过 15s 没更新 → 判 broker 死 → 走场景 A 流程。

**不变量**：不管哪种 crash，每个在跑的 reservation 最终都有一条 `close`
事件，当次 session 内就补上。`_reservations.jsonl` 不会留长期 open 的孤
儿条目——连 1h 级污染 in-flight section 的情况也不会发生。下次 `aker
run` 启动时的 stale 检测（§6.3）只用于处理极端情况：主进程本身被 SIGKILL，
连 atexit 都没跑。

Broker 自己写一条 heartbeat（`task_dir/.broker.heartbeat`，每 5s 更新
mtime）供上面的 `socket.timeout` 分支查。

### 6.12 并发读写协议总览（leaderboard + graph 信息）

§6.3 / §6.5 / §6.6 里零散讲过各自的写者和锁，这一节集中梳一遍，方便
review 复核"哪些写必须加锁、哪些读不用锁、为什么不用"。

#### 6.12.1 Leaderboard 的写路径（唯一写者：主进程）

**原则**：`leaderboard.jsonl` 和 `leaderboard.md` 都**只由 `aker run` 主
进程写**。slot 不写，LLM 不写。这是 P20 的扩展——初版 P20 只说 .md 归
主进程；v3 扩展到 .jsonl 也归主进程。

| 步骤 | 谁做 | 产物 |
|---|---|---|
| 1. 跑 acc / perf job | LLM 通过 `akerjob` → broker | `nodes/<id>/report_acc.json` / `report_perf.json`（broker 写规范位置） |
| 2. 写 kernel.* / meta.json / notes.md | LLM 在 staging → `os.rename` | `nodes/v<N>_<tag>/`（P8 原子落盘） |
| 3. slot 跑 audit（§6.10）| slot 进程 | 通过 pipe 把 audit 结果 + 目标 row 送主进程 |
| 4. commit transaction | 主进程持 `.leaderboard.lock` | append `leaderboard.jsonl` → regen `leaderboard.md` → 在 `.reservations.lock` 下 append close 事件 |

**为什么不让 slot 直接 append jsonl**：POSIX append 对单行确实原子，多
slot 并发 append 也不撕裂；但 `.md` 的全量 regen 不是 append，多写者会
互盖。如果 slot 自己追 jsonl、主进程再重生 .md，中间会出现 "jsonl 已更
新、.md 还没刷" 的窗口，peer 读到 stale .md 并不致命但让"读一致性"的心
智模型变脏。全部收到主进程写更清爽，锁持有时间 <10ms 毫无成本。

**leaderboard row 的来源**：主进程从 **`meta.json` + `report_perf.json`
+ `report_acc.json`** 组装 row，**不**让 LLM 写 row（和 P12 "attempt_
status 由 LLM 写"不矛盾——status 是 LLM 的判断，row 是事实数据的汇编）。
相应 prompt 需要一条硬约束：LLM 不得直接 `>> leaderboard.jsonl`。

#### 6.12.2 Graph 信息的读路径（零锁）

所有 reader（slot 构造 graph summary、主进程统计、人工 `cat`）**一律不
拿锁**。靠三条 POSIX / 文件系统性质兜底：

| 状态 | 写方式 | 读方怎么保证不坏 |
|---|---|---|
| `nodes/v<N>_<tag>/`（committed 节点目录）| slot `os.rename` 从 `.tmp` 搬过来——**目录级原子** | scan 看到目录时所有文件已齐；若 `meta.json` 解析失败 → 跳过该条目（视为损坏），不 panic |
| `nodes/.v<N>_*.tmp/`（staging，给 in-flight peek 用）| slot 逐文件写，**非原子** | peek `meta.json` 时 `json.JSONDecodeError` fallback 为 "no meta yet"（§6.5）|
| `leaderboard.jsonl` | 单写者（主进程）锁内 append 整行 | **单行 < `PIPE_BUF` (4KB) → POSIX 保证 append 原子**；读者解析最后一行失败（正在写）→ 丢弃尾行，不报错 |
| `_reservations.jsonl` | 多写者（slot 分配 N / slot close / 主进程 sweep）锁内 append 整行 | 同上 |
| `leaderboard.md` | 单写者锁内全量 rewrite | 读者任意时刻读可能是旧版本——非机器 consumer，人读，不影响 |

**核心不变量**：`os.rename` 原子 + 单行 < `PIPE_BUF` 的 append 原子 + 读
者解析失败即跳过。满足这三条时，读一致性等价于"read-committed"——读到
的状态是某个合法快照，但可能立即过时。这就是 slot 的 graph summary 对
peer 可见性的语义。

#### 6.12.3 一共 2 把文件锁

| 锁 | 保护的写 | 持有者 | 典型持有时长 |
|---|---|---|---|
| `.reservations.lock` | `_reservations.jsonl` 的 append；N 分配的 "read-max → write-open" 原子化 | slot（分配 / close）+ 主进程（sweep / close） | <5 ms |
| `.leaderboard.lock` | `leaderboard.jsonl` append + `leaderboard.md` regen | 主进程（唯一） | <50 ms（regen .md 是主成本） |

**没有图级别的读锁，没有 node 级别的锁，没有 GPU flock**。GPU 的独占由
broker 串行化承担（P1），不在本节讨论范围内。

#### 6.12.4 Slot 视图 vs 全局视图的一致性边界

- Slot `s_i` 在 T0 扫一次图生成 graph summary 喂 LLM；期间 peer 新
  committed 的节点对 `s_i` 不可见
- 方向重复只是浪费，不错算（C5 已接受）
- **A4 audit 用 close 时的 fresh 快照**判定（§6.10 v3）——不是 T0 快
  照。LLM 若在长 session 里后续工具调用刷到新 committed 的 v18 并引
  用，close 时 v18 仍 committed → A4 PASS，不会被初始快照的 staleness
  误判
- In-flight peer 在 close 时仍 in-flight → A4 FAIL；LLM 引用 in-flight
  是 prompt 明禁项（P9）

这是整个并发一致性最容易绕糊涂的一步，集中记一下。

---

## 7. 决策汇总（编号接 plan.md）

| # | 决策 | 依据 |
|---|---|---|
| **P1** | GPU 独占改为 broker 架构化，不用 fcntl 文件锁、不改 testlib.py | 对齐 idea.md §4："物理保证不靠措辞"。锁变副作用，API 更干净 |
| **P2** | `akerjob` 独立 console script，与用户 CLI `aker` 分离 | 用户界面和内部 RPC 是两套协议，不能混同一个 binary |
| **P3** | 节点版本号 N 由 Python 分配，`<tag>` 由 LLM 选 | 解决 C1/C6；prompt 里多一句 "N=18 已分给你" 比让 LLM 推导更稳 |
| **P4** | N 永不重用，即使 crash 也 retire | 换 audit/leaderboard 不变性最简；号段空洞不值得在乎 |
| **P5** | Broker 生命周期 = `aker run` 进程生命周期，不做常驻 daemon | 避免 stale state、多 task 冲突、孤儿 broker |
| **P6** | ~~Compile 不走 broker，保持并发~~ **(v2 修订)** → 见 §6.9：在 (a)/(b)/(c) 三条路径间，**实施前跑验证实验定夺**；当前倾向 (b)，失败回退 (a)；P17 的强度跟随该选择 | 旧表述把 torch build lock 当 GPU 锁，错；`load()` 会 init CUDA context，会污染 broker 里的 perf 测量 |
| **P7** | Crash 后孤儿目录 → `shutil.move` 到 `_orphans/`，不删 | 保守；留调试证据 |
| **P8** | Staging rename：worker 先写 `.v<N>_<tag>.tmp/`，再 `os.rename` | 同分区 rename 原子，解决 C8 |
| **P9** | In-flight 节点在 graph summary 单列一段，prompt 硬约束禁作父 | 让 AI 能避开重复方向、同时保持正确性边界 |
| **P10** | Reviewer 看到 peer 半成品目录靠 prompt 约束，不引入隔离机制 | 误判代价小；结构复杂度大得多，不值 |
| **P11** | Worker slot 启动不 stagger | 1–5 并发下方向多样性够用；加 stagger 是过度工程 |
| **P12** | `attempt_status` 仍由 LLM 自己写，broker 不代管 | 收紧 LLM 表达空间违反 idea.md §2 |
| **P13** | 同物理 GPU 拒绝第二个 `aker run`，靠 `/tmp/aker_gpu_<dev>.lock` | 简单防御；不解决分布式问题但堵住误用 |
| **P14** | 跨进程 session carry **不做**（各 slot 独立） | 和当前单进程行为一致，简化 |
| **P15** | 不做迁移 | 已 bootstrap 的旧 task 不跑新版；无兼容负担 |
| **P16** | multiprocessing 启动方式强制 `spawn`，不用 `fork` | 父进程任何 CUDA/torch 预初始化都会污染 slot；`spawn` 从零启动干净。启动成本是秒级（torch import 链路），对分钟级 session 可忽略 |
| **P17** | `CUDA_VISIBLE_DEVICES=""` 注入 codex sandbox，把"LLM 不得直接摸 GPU"从 prompt 级升级为物理级 | 对齐 idea.md §4；**(b) 下也几乎完整**（v3 修订，见 §6.8）——codex subprocess 新起的 Python 进程看不到 device，也拿不到 slot 进程的 context（CUDA context 进程间不共享）|
| **P18** | reservation 级顶层超时 `reservation_timeout_sec`（默认 3600s）独立于 per-job timeout | round 包含多个 job + codex 生成，不能拿单 job timeout 做基准 |
| **P19** | §6.9 compile 路径选定前必须跑独立验证实验测定 context init 对 perf timing 的扰动 | mean_ms 是唯一目标函数，1–2% 以上的污染等于整个 leaderboard 失真 |
| **P20** | `leaderboard.jsonl` 和 `leaderboard.md` 都**只由主进程写**（v3 扩展，不再让 slot append jsonl）；row 由主进程从 `meta.json` + 报告文件组装；LLM 禁写 leaderboard.* | 让读一致性的心智模型更干净——两个文件同属一把锁、同一个 commit transaction；详见 §6.12 |
| **P21** | 日志文件名从 `round_NNN.md` 改为 `<reservation_id>.md`，jsonl / 日志 / N 一一对应 | 解决 C2；并发下 "round" 无单一语义 |

---

## 8. Prompt 改动清单

| 文件 | 改动 |
|---|---|
| `iterate_worker.md` | 1. 把"请自行决定 `v<N>`"改成"你被分配了 N=<<ASSIGNED_N>>，请选一个 `<tag>`"。<br>2. GPU 调用改 `akerjob` 路径，禁止直接跑 `python test_*.py` / `ncu` / `nvidia-smi`。<br>3. 新增 in-flight section 的解释 + "parents 只能含 committed 节点"硬约束。<br>4. Staging rename 契约："write to `nodes/.v<N>_<tag>.tmp/` first, then os.rename"。 |
| `iterate_worker_fix.md` | GPU 调用改 `akerjob` 路径。 |
| `iterate_reviewer.md` | "只评审 `new_node_id` 这一个目录，不对其他 `v<N>` 目录发表意见"。 |
| `iterate_reviewer_recheck.md` | 同上。 |
| `bootstrap_worker.md` | 同 iterate_worker 第 2 条（GPU 路径统一）。N=0 不需要分配。|
| `bootstrap_reviewer.md` / `bootstrap_reviewer_recheck.md` | 同 reviewer。 |
| `spec_generator.md` | 无改动。 |

新增 prompt 占位符：`<<ASSIGNED_N>>`（Python 侧在 `load_prompts` 里注入）。

---

## 9. 对现有模块的影响

| 模块 | 改动 |
|---|---|
| `aker/cli.py` | 新增 `--parallel N` 参数 |
| `aker/iterate.py` | 重写 `run()`：device lock → fork broker → pool.map → join；audit 从 `after - before` 改为 reservation 驱动 |
| `aker/bootstrap.py` | 单次性调用 broker；不用 pool |
| `aker/graph.py` | `format_graph_summary` 增加 in-flight section |
| `aker/review_loop.py` | 无大改（它不直接跑 GPU） |
| `aker/codex.py` | spawn codex subprocess 时传 env（含 `AKER_BROKER_SOCK` / `AKER_TASK_DIR`）；根据 §6.9 选项**同时注入 `CUDA_VISIBLE_DEVICES=""`**（P17），让 sandbox 物理隔离 GPU |
| `aker/prompts/*.md` | 见上节 |
| `aker/broker.py` | **新文件** |
| `aker/worker_cli.py` | **新文件** |
| `aker/reservation.py` | **新文件** |
| `aker/gpu_client.py` | **新文件**（`akerjob` 用的 socket 客户端） |
| `setup.py` | 新增 entry point |
| `tests/` | 新增 `test_broker.py`、`test_reservation.py`；`test_iterate.py` 加并发 case |

---

## 10. 非目标

以下问题在本方案**不解决**，留给后续：

1. **多机 / 多 GPU 分布式**。本方案锁定单机单 GPU。多 GPU 需要 broker 感
   知 device、reservation 感知 slot → device 映射——不是小增量。
2. **跨 `aker run` 进程共享 broker**。P5 明确选了 per-process；未来若要
   让多 task 公平使用同一张 GPU，需要常驻 daemon + 任务优先级，重写量
   大。
3. **Pareto 前沿裁剪 / leaderboard 分页**。图大了之后再做，和并发正交。
4. **LLM 可见的队列深度 / ETA**。故意不给——属于控制流信息，给 LLM 没
   用、徒增 prompt 噪声。
5. **Thundering-herd 方向撞车**。接受代价。
6. **已 bootstrap 任务的迁移**（P15）。

---

## 11. 待 review 的关键点

按"如果 reviewer 反对，会推翻多少代码"降序：

1. **Broker 架构 vs 文件锁**（P1）——最上层的抉择。如果 reviewer 认为 "broker 太重，几行 flock 就够"，整个方案推倒。理由在 §4。
2. **Compile 路径取舍**（§6.9 + P6 修订 + P19）——决定 P17 的强度、决
   定整个方案的并行实际收益。**实施前必须跑验证实验定夺**，见 §6.9 步
   骤。结果会直接反写到 §12 步骤 0。
3. **节点号 Python 分配**（P3）——会动到 prompt 和 audit 两处。替代方
   案是 staging 目录 + commit 时 rename 分配号。后者 LLM prompt 不用
   改，但 audit 复杂度提升。
4. **`CUDA_VISIBLE_DEVICES=""` 注入 codex sandbox**（P17）——新增物理
   屏蔽；和 §6.9 选项耦合。如果 reviewer 认为 prompt-only 够了，可以省
   掉这步。
5. **Broker 生命周期 per-process**（P5）——如果将来要跨 task 并发，要
   重做。现在选这个是为了简单。
6. **Audit 校验项清单**（§6.10）——每条都是有针对性的，但如 A8 "不得
   同时存在两个 `v<N>_*` 目录" 可能和某些边缘场景（rename 失败恢复中）
   冲突；reviewer 可逐条扫。
7. **超时默认值**（§6.1 表格 + P18 reservation 级 3600s）——大概率需
   要实跑调。
8. **Broker crash 清理序列**（§6.11）——一串协议，任何一步漏了都会出
   现"卡死不退"的状态。落地时要写集成测试。

---

## 12. 实施顺序

0. **验证实验**（§6.9 步骤）：context init 对 perf timing 的扰动测量。
   结果决定路径 (a)/(b)/(c)，**这一步不通过不进入后续步骤**。产物落
   `dev/experiments/compile_isolation/` 留档。
1. `aker/broker.py` + `aker/gpu_client.py` + `aker/worker_cli.py`（独立
   可测，不依赖别的改动）
2. `setup.py` entry point 注册 + 端到端手测 `akerjob ...`（伪 job 即可）
3. `aker/reservation.py`（含 `reservation_id` 分配、jsonl 事件、stale 检
   测）+ `graph.py` 的 in-flight section（含 §6.5 peek JSON 兜底）
4. Prompt 改造（iterate/bootstrap 全套，包括 `<<ASSIGNED_N>>` 占位符）
5. `aker/iterate.py` 重写：device lock（§6.7 normalize + stale PID take-
   over）、broker 生命周期（§6.11 两种 crash 场景的清理序列）、`Process
   PoolExecutor`（拿 per-worker death hook）、P16 `spawn`、audit 按
   §6.10 逐条落位、`CUDA_VISIBLE_DEVICES=""` 无条件注入（§6.8 v3 修订：
   (b) 下也装）
6. `--parallel N` 暴露到 `aker run`
7. 端到端：`--parallel 1`（回归串行行为）→ `--parallel 3` → `--parallel 5`
8. 故障注入测试：手动 `kill -9` broker 验证 §6.11 场景 A；手动
   `kill -9` slot 验证场景 B 的 in-flight 幽灵清理；手动 `kill -9` aker
   run 主进程验证下次启动的 stale 兜底 + 锁 takeover；并发下强行让两个
   slot 同时完成验证 A8。

每步交付时附：单测 + 一个手工跑过的示例 round。

---

## 13. 与 idea.md 的原则对照

| idea.md 原则 | 本方案怎么体现 |
|---|---|
| §1 图就是记忆 | 不变——reservation 只是让"节点出现"这一步变原子，图结构不动 |
| §2 格式只用于控制流 | P12：不代管 `attempt_status`；job 响应结构是**文件/网络协议**不是推理格式 |
| §3 prompt 反 anchoring | 不变。新增的 in-flight section 是**诊断信息**（别人在做什么）而非清单 |
| §4 sandbox 是物理约束 | **核心映射**：GPU 独占 = broker 架构化，不是 prompt 措辞 |
| §5 记忆长度 trade-off | 不变——session 寿命 RNG 迁移到每个 slot 独立 |

---

## 14. 开放问题

1. 若某个 job 跑到 TIMEOUT，worker 收到 status=TIMEOUT 后的行为 prompt 要
   指导多强？"可以 retry 一次" vs "立即标记 FAIL"？倾向前者，但需要
   round 级预算的约束，避免 worker 无限 retry。
2. broker 自身 crash 的处理：目前计划是 `aker run` 直接退出（broker 是
   监督者之一，它挂等于 session 不可控）。是否需要 broker 自动重启？倾
   向 **否**，crash 留给 reviewer 上下文分析。（落地协议见 §6.11）
3. reservation crash 重建：如果 `aker run` 进程整体 crash 重启，上次留
   下的 open reservation 怎么处理？倾向：`aker run` 启动时检测上一轮的
   `_reservations.jsonl` 里未 close 的项，统统 close 为 `crashed` 状态，
   并搬运对应孤儿目录。
4. **§6.9 实验的阈值选 2%**（perf 扰动超过即否决 (b)）：这个数字的定量
   依据是"当前 leaderboard 行距"——v17 之前近半数节点相邻 mean_ms 差
   2–5%，污染 2% 足以翻转排序。reviewer 若有更严标准请直接改。
5. **P3 "脏相"**：Python 预分配 N=18 给 LLM 后，LLM 可能在 kernel.cu 注
   释或 notes.md 里写 "v18 是我的尝试"。如果这个 reservation crash、N=
   18 被 retire（P4）、该代码文本流到别处，会产生 git blame 时的小迷
   惑。非正确性问题，刻意不治。留个印象。
6. **§6.11 的 heartbeat 粒度**：broker 每 5s 更新 mtime，slot 在 recv
   阻塞 > 15s 时查一次——这两个数字目前拍脑袋，等并发实跑看体验。
7. **A8（同 N 不得有两个目录）与 rename 失败恢复的冲突**：若 worker 执
   行 `os.rename` 中途崩（概率极低但非零），可能同时残留 `.v<N>_*.tmp/`
   和 `v<N>_*/`——严格 A8 会误报。缓解：A8 只查 `v<N>_*` 正式名，`.tmp`
   前缀不算。实施时注意这个边界。
