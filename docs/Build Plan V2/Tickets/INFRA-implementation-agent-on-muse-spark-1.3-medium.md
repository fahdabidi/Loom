# INFRA — run the implementation agent on Muse `muse-spark-1.3` at `medium`

**Status:** DONE 2026-10-18 (user-directed), verified through the dispatcher itself. One decision about
CLAUDE.md is open and is the user's — see the last section.

## Change

`data/call_implementation_agent.sh` defaults: `IMPLEMENTATION_ENGINE` `claude` → **`muse`**,
`MUSE_IMPLEMENTATION_REASONING_EFFORT` `xhigh` → **`medium`**; `MUSE_IMPLEMENTATION_MODEL` was already
`muse-spark-1.3`. The engine comment block was rewritten to match. The Claude engine stays selectable
with `IMPLEMENTATION_ENGINE=claude`.

All three copies updated and checked by checksum, because a commit proves nothing about a gitignored
`data/` script: Windows `data/`, the tracked mirror `docs/Build Plan V2/Tools/code/`, and the VM's
`~/Loom/data/` all read md5 `07b267920598afe55b8df08c4390cac9`.

## Verified before and after switching

- **Before:** CLAUDE.md recorded that on 2026-09-14 the Meta API refused `muse-spark-1.3` for this
  account. Re-tested after a fresh `muse login`: the catalog now lists `muse-spark-1.3` and
  `muse-spark-1.3-contributor`, and a bare `muse exec --model muse-spark-1.3 --reasoning-effort medium`
  replied `READY`, exit 0.
- **After, through the real dispatcher** with a smoke ticket in `/tmp` (so no real ticket was stamped),
  no overrides: banner `Engine: muse`, `Model: muse-spark-1.3`, `Reasoning effort: medium`; the agent
  replied with the exact `<<<SUITES_RUN: ...NOT_RUN(smoke-test)...>>>` marker; `muse exec exited with
  status 0`; `Working tree clean`; `DISPATCH_VERIFICATION: incomplete` — the correct verdict for an
  all-`NOT_RUN` marker (a missing marker would read `failed`).

## OPEN — Muse skips CLAUDE.md entirely

Every Muse run prints:

    muse: warning: rules file at /home/fahd/Loom/CLAUDE.md is 324953 bytes, over the 256000 byte
    load limit; it is skipped for this session

So a Muse implementation agent works **without the project's rules file**. Dispatches still function —
the dispatch preamble and the ticket carry the essential contract, including the `SUITES_RUN` marker the
dispatcher enforces — but nothing else in CLAUDE.md reaches the agent. Much of CLAUDE.md's bulk is the
validation role's own institutional memory, a large part added in the 2026-10 sessions.

**Options, for the user to choose:**
1. **Split CLAUDE.md** below 256 KB: keep project-wide rules in it, move the validation agent's
   incident write-ups into a separate file it reads itself. Restructures the user's instructions file.
2. **A dedicated, short rules file for implementation agents** (if Muse loads one alongside CLAUDE.md —
   unverified) carrying only what an implementer must obey.
3. **Accept it**: keep every agent-facing rule in `dispatch_preamble.md` or the ticket, and treat
   CLAUDE.md as the validation agent's file. Costs nothing now; tickets must stay self-contained.

Until decided, this file's rule stands: **anything an implementation agent must obey goes in the ticket
or the preamble**, never only in CLAUDE.md.
