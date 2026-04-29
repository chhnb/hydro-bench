# Reviewer feedback — fix and re-validate

The reviewer inspected your new node and flagged the issues below. You
still have the full context of your previous turn; this is a
continuation, not a restart.

Address every item. Modify only what the reviewer flagged plus whatever
the fix naturally entails (rerunning the tests via `akerjob`, amending
`meta.json` if the failure/success status flipped). Do NOT touch
`leaderboard.jsonl` / `leaderboard.md` — Python owns those.

If your fix switches to a different `<tag>` (keeping the same assigned
`N`), rename or recreate the directory accordingly. If it was already
renamed from `.v<N>_<tag>.tmp` to `v<N>_<tag>`, a second rename is
allowed; just make sure exactly one `v<N>_*` directory remains on disk
at the end. Use GPU only via `akerjob` — never `python test_*.py`
directly.

**If you decide to abandon your current staging attempt entirely**
(for instance: the reviewer told you the direction is a duplicate, or
you are switching to a totally different approach under the same
assigned `N`): **`rm -rf` the staging directory completely**. Do NOT
rename it to an invented suffix (`.peer_backup`, `.backup`, `.old`,
or anything else). The system only recognizes two legitimate dot-
prefix patterns: `nodes/.v<N>_<tag>.tmp/` (active staging) and
`nodes/v<N>_<tag>/` (final committed). Anything else is tracked as
an orphan and will be moved out of `nodes/` next run. Do NOT touch
peer workers' `.v<M>_*.tmp/` or `v<M>_<tag>/` directories under any
circumstances, even if a confused reviewer suggests otherwise —
refuse the suggestion in your reply and flag it.

If the reviewer's verdict also contains a direct answer to a question
you asked last turn, treat that answer as authoritative and proceed
accordingly.

---

## Reviewer verdict

<<REVIEWER_VERDICT>>

---

Now fix, re-run tests as needed, keep `meta.attempt_status` consistent
with what actually happened, and report back.
