# Re-review after worker fix

Re-inspect only the assigned native-hydro target:

`nodes/v<<ASSIGNED_N>>_<tag>/`

Scope is narrow:

1. Check whether the previous RETRY issues were fixed.
2. Check only newly broken required artifacts introduced by the fix.

Do not expand scope and do not review peer nodes or staging directories for
other version indices.

---

## Worker's reply from this turn

<<WORKER_FINAL_MESSAGE>>

---

Last line must be exactly:

```text
VERDICT: PASS
VERDICT: RETRY
```
