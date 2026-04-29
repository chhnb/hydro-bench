# Reviewer feedback — fix and re-validate

The reviewer flagged issues in your native-hydro node.

Modify only your assigned node directory for this round:

- `nodes/.v<N>_<tag>.tmp/` if still staging, or
- `nodes/v<N>_<tag>/` if already committed.

Do not touch `spec.md`, `task_config.json`, `testlib.py`, `test_acc.py`,
`test_perf.py`, `leaderboard.*`, baseline files, `cuda_native_impl/`, or peer
nodes.

Some worker sessions do not have Bash or full-access permissions. Use whatever
file read/write/edit mechanism is available, and do not ask for permission
solely to run shell commands.

Do not run `akerjob`, `nvcc`, the benchmark, or GPU tools directly. After your
fix turn, the trusted Aker host process will run brokered validation, update
`meta.json`, append host-validation notes, and commit the staging directory.

If validation reports are absent while the node is still staged, leave
`meta.attempt_status` as `"FAIL"` with
`"failure_reason": "pending host validation"`.

---

## Reviewer verdict

<<REVIEWER_VERDICT>>

---

Now fix the issue and reply:

```text
HYDRO_NODE: <node_id> status=<OK|FAIL> reason=<short reason>
```
