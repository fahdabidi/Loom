# Dispatch pipeline — script-by-script reference

The seven scripts in `code/`, in the order you actually touch them during one dispatch round. Each section
covers: what it does, why it exists (the real incident, where applicable), usage, and the exact guard/exit
behavior. See `README.md` for the end-to-end worked recipe that chains all seven together.

All seven expect to live at `<repo-root>/data/<script>.sh` — they compute `REPO_ROOT` as
`$(dirname "$0")/..`, so keep them one directory below your repo root (see `README.md` "Setup in a new
project").

---

## 1. `call_implementation_agent.sh` — dispatch the Implementation Agent

**Role:** writes and commits real code/config/JSON changes against a ticket. Runs Codex CLI inside WSL,
always backgrounded by the caller (never run this in the foreground — see README).

**Usage:**
```bash
bash data/call_implementation_agent.sh <path-to-ticket-file> [--fresh]
```
- Omit `--fresh` to resume the most recent Codex session (`resume --last`) — cheaper, keeps continuity
  across rounds on the same ticket.
- Pass `--fresh` to start a brand-new session — use for the first dispatch of a new ticket, or after a long
  gap where stale resumed context would do more harm than good.
- `CODEX_IMPLEMENTATION_PROFILE=<name>` overrides the model profile for one call;
  `CODEX_IMPLEMENTATION_PROFILE=""` falls back to Codex's own built-in default model.
- `CODEX_IMPLEMENTATION_SANDBOX=<mode>` overrides sandbox mode (default `workspace-write`).

**Model default:** `gpt5_3_spark_xhigh` (GPT-5.3-Codex-Spark @ `xhigh` reasoning effort). Full model history
is kept in the script's own header for reference — every profile ever used stays configured and reachable
via the env override, none are torn down when the default changes. Worth reading once: it documents a real
case (DeepSeek V4 Pro @ `high`) that passed a trivial one-line smoke test but never completed a real
ticket-length prompt after 10+ minutes — the lesson being **smoke-test AND one real ticket** before trusting
a new model/profile as your default, not the smoke test alone.

**Built-in safety mechanisms (all automatic, nothing to wire up per-dispatch):**
- **Git-safety preamble**, prepended to every ticket's prompt automatically: explains that this repo (if on
  OneDrive) intermittently produces transient `index.lock`/"unable to write new index file" errors, and
  gives the dispatched agent an exact, narrow recovery procedure (`rm -f .git/index.lock`, retry once, then
  STOP and report rather than improvising broader git surgery). This exists because an earlier incident had
  a dispatched agent "recover" from a transient lock error by running broad `git rm --cached`-style commands
  that then got committed, silently collapsing the tracked tree while `git status` still reported clean.
- **Native-git shim enforcement**: if `~/.codex-git-shim/git` exists (see README setup step 4), it's
  prepended to `PATH` so every git call the dispatched agent makes uses `git.exe`, not WSL's own git —
  closes a root-caused OneDrive+v9fs git-index corruption path.
- **Pre/post tracked-file-count + HEAD integrity guard**: snapshots `git ls-files | wc -l` and
  `git rev-parse HEAD` before and after. If HEAD moved and the tracked-file count dropped ≥20%, prints a
  `GIT INTEGRITY ALERT` banner with the exact before/after counts and a recovery command — this catches a
  collapsed-and-recommitted tree, which reports a clean `git status` and would otherwise pass unnoticed.
- **Vsock-exhaustion detector**: greps the dispatch's own transcript for
  `UtilBindVsockAnyPort|UtilAcceptVsock|accept4 failed`. If found, prints a `DISPATCH_HIT_VSOCK=1` banner —
  this failure mode exits 0 (looks like success) while having done nothing, a known upstream WSL2/Codex
  interaction (cited in the script's header: openai/codex#8322, microsoft/WSL#40650). **Always check
  `git status`/`git diff` after a vsock hit** before assuming nothing happened — it can strike either before
  any edit (safe to just retry) or after real edits, if only the dispatch's *own* post-edit
  verification/commit attempt hit the wall (in which case real, uncommitted work may already be sitting in
  the tree — review and finish committing it yourself rather than discarding it).
- **Own-PID tracking**: writes its own PID to `.codex-logs/.last_dispatch.pid` on every run, letting a caller
  that backgrounded the whole script poll for completion reliably later
  (`while kill -0 "$(cat .codex-logs/.last_dispatch.pid)" 2>/dev/null; do sleep 5; done`). Deliberately not a
  `pgrep -f "codex exec"`-style check — that pattern has twice produced wrong answers in practice (matches
  the wrapper script's own command text; or misses the real process, which is actually launched via a
  versioned `npm exec @openai/codex` wrapper, not a literal `codex exec` argv[0]).

**Requires:** `trust_level = "trusted"` for your repo path in `~/.codex/config.toml` (one-time, see README).

---

## 2. `call_root_cause_agent.sh` — dispatch the Root Cause Agent

**Role:** diagnoses a bug that has resisted your own hypothesis-and-test budget. Read-only by contract — see
`root-cause-agent-tool.md` for the full role write-up (contract, brief-writing guidance, what happens to the
report). This doc covers only the script mechanics.

**Usage:**
```bash
bash data/call_root_cause_agent.sh <path-to-brief-file> [--fresh]
```
Same flags/env-override shape as the Implementation Agent script
(`CODEX_ROOT_CAUSE_PROFILE`/`CODEX_ROOT_CAUSE_SANDBOX`). **Model default:** `gpt5_6_sol_xhigh`
(GPT-5.6-Sol @ `xhigh`).

**Differs from `call_implementation_agent.sh` in exactly three ways:** the role preamble (injects a strict
"never edit any implementation file, produce exactly one of two outcomes" contract — see
`root-cause-agent-tool.md`), the default model profile, and its post-run integrity check is stricter: **any**
HEAD movement at all (not just a ≥20% file-count drop) prints a `VIOLATION: HEAD moved` banner, since this
agent should never commit anything, ever. A clean run also prints nothing under "working tree dirty" — the
report file itself is the only expected change, and the script prints every line of `git status --short` if
the tree isn't clean so you can eyeball exactly what changed beyond the report.

---

## 3. `wsl_dispatch_tracker.sh` — track and clean up the WSL processes a dispatch spawns

**Why it exists:** WSL2's own idle-timeout teardown has repeatedly failed to reclaim orphaned
`wsl.exe`/`wslhost.exe` processes in this environment (observed surviving 5+ hours). This script tracks
*which specific* Windows processes a single dispatch causes to appear (by diffing the process set
before/after — never by following one PID through the launcher chain, since the launching `wsl.exe` process
exits within seconds on its own once it has backgrounded the real work), and kills+reverifies them once the
dispatch completes.

**Usage (three-step lifecycle around one dispatch):**
```bash
bash data/wsl_dispatch_tracker.sh baseline <label>
# ... launch the dispatch ...
bash data/wsl_dispatch_tracker.sh capture <label>
# ... wait for completion ...
bash data/wsl_dispatch_tracker.sh cleanup <label>
```
Plus a standalone maintenance command:
```bash
bash data/wsl_dispatch_tracker.sh sweep-zombies [max-age-minutes]   # default 60
```
`cleanup` calls this automatically at the end, so a normal dispatch round gets it for free.

**Never targets** `wslservice.exe` (the persistent Windows-side management service) or `vmmemWSL` (the
shared VM hosting *all* concurrent WSL activity on the machine, including unrelated sessions) — both
explicitly excluded by name-match filtering; killing either would take down far more than the one dispatch.

**Log:** `.codex-logs/.dispatch_wsl_tracker.log` (append-only, one line per lifecycle event — `baseline`,
`capture`/`dispatch_launched`, `cleanup`/`wsl_session_closed_confirmed` or `_FAILED`, and every
`zombie_sweep` run). `handoff_gate.sh` reads this log to confirm cleanup actually happened for a given label.

---

## 4. `watch_dispatch_log.sh` — self-terminating completion watcher

**Why it exists:** the naive pattern — a `Monitor`/`tail -F <log> | grep -E '...'` watch — never exits on its
own. `grep` without `-m1` doesn't stop on the first match (intentionally: a mid-run vsock alert is noise you
want to keep watching past, not treat as completion), and `tail -F` runs forever regardless. The `Monitor`
tool fires a notification on a match but does **not** kill the underlying process — only a real timeout or
explicit stop does. The result, confirmed in this project's own history: every dispatch-watching Monitor
that ever matched real completion kept its `tail -F` (and the WSL session backing it) alive for up to the
full watch timeout afterward. Across a run with many dispatch rounds, these accumulate and were a real,
confirmed contributor to WSL2 vsock-port exhaustion — stopping one leaked watch pipeline dropped the live
`wsl.exe` count from 6 to 2 immediately in one measured incident.

**Usage** (as a `Monitor`/background-watch command, replacing the raw `tail -F | grep`):
```bash
wsl.exe -e bash -lc 'cd "<repo>" && bash data/watch_dispatch_log.sh <label> [post-completion-sleep-seconds]'
```
`<label>` must match the label used for this dispatch's `.codex-logs/<label>_dispatch.out.log`. The script
streams vsock-alert lines through as they occur (so you still see them as progress/noise signals), and the
moment it sees the real `codex exec exited with status` line, it prints it, waits `post-completion-sleep-
seconds` (default 5, letting any trailing buffered output flush), then kills its own `tail -F` and exits —
ending the watch on its own, no separate stop call needed.

---

## 5. `handoff_gate.sh` — pre-verification handoff gate

**Why it exists:** a real incident cost three redundant dispatch rounds re-fixing a file that was *already*
fixed, because it sat uncommitted (untracked, `??`) across multiple rounds — `git diff` shows nothing for an
untracked file's content changes no matter how many times it's edited, so nobody noticed the fix had already
landed. This script exists purely to catch that class of incomplete handoff **before** you spend time on
`analyze`/test runs against a tree that isn't actually in the state you think it's in.

**Usage:**
```bash
bash data/handoff_gate.sh <label>
```
**Five checks, in order** (each prints `[OK]`/`[FAIL]`/`[INFO]`):
1. The most recent dispatch process (`.codex-logs/.last_dispatch.pid`) has actually exited.
2. `wsl_dispatch_tracker.sh`'s log shows a confirmed `wsl_session_closed_confirmed` event for this label —
   i.e., cleanup was actually run, not skipped.
3. `git status --short` is empty — everything from this round is committed.
4. `git ls-files | wc -l` is ≥100 (a cheap sanity check against catastrophic index corruption — a collapsed
   tree that happens to be fully committed would otherwise pass check 3 silently).
5. `git rev-parse HEAD` resolves to a real commit.

**Exit 0** and prints `READY FOR VALIDATION` only if all five pass. **Exit 1** and prints exactly what's
missing otherwise — fix that specific thing, then re-run, rather than proceeding to `analyze`/tests on a
handoff this gate flagged incomplete. This script never commits or cleans up anything itself — it only
checks and reports; you still run steps 1-2 above yourself if they're missing.

---

## 6. `wsl_slot.sh` — concurrency gate for ad-hoc `wsl.exe` calls

**Why it exists:** WSL2 enforces a hard, non-tunable cap on total vsock connections (confirmed by WSL
maintainers — no `.wslconfig` key, no registry setting reaches it). Each fresh `wsl.exe` invocation consumes
a slice of that budget. A dispatch (1 session) + a watcher (1 session) are already two of your four-session
budget (see README's stated cap of 4 concurrent `wsl.exe` subprocesses) — every *additional* ad-hoc call
(status checks, git commands, log reads) should be routed through this gate rather than fired unbounded,
since unbounded ad-hoc calls are exactly the usage pattern that has exhausted the cap in practice.

**Usage:**
```bash
bash data/wsl_slot.sh "<full command line to run, usually a wsl.exe invocation>"
```
Env overrides: `WSL_SLOT_MAX` (default 2), `WSL_SLOT_TIMEOUT` seconds (default 120).

**Implementation notes:** gating happens entirely in git-bash/MSYS space via an atomic `mkdir` lock, *before*
the wrapped command runs — critical, because the vsock connection is consumed the instant `wsl.exe` starts,
not by anything that runs inside the WSL VM itself; a gate implemented inside WSL would already be too late.
Self-healing: each slot records the PID holding it, and a slot whose PID is no longer alive (a prior
invocation died without reaching its own cleanup) is reclaimed rather than permanently starving future
calls. This is not OS-level enforcement — it only bounds invocations that are actually routed through it, so
it works only as long as ad-hoc `wsl.exe` calls are consistently issued through this wrapper.

---

## 7. `verify_apk_freshness.sh` — stale-build guard (Flutter/Gradle-specific, generalizable)

**Why it exists:** a real incident where `flutter build apk --debug` reported success but silently reused a
9-day-old cached APK — Gradle's incremental up-to-date check was fooled, most likely because the repo lives
on a WSL2-mounted Windows path (`/mnt/c/...`, drvfs) where file-change signals don't always reliably reach
Gradle's mtime-based staleness detection. The stale build was missing a function added a week after that
cached build was produced, which only surfaced as a live runtime crash during a device walkthrough —
something none of `flutter analyze`/`flutter test`/the JSON validators could ever catch, since none of them
build or run a compiled artifact.

**Usage:**
```bash
bash data/verify_apk_freshness.sh <path-to-apk> <must-contain-string> [<must-contain-string> ...]
```
Example (the exact incident this would have caught):
```bash
bash data/verify_apk_freshness.sh \
  app/apps/loom_communities_demo/build/app/outputs/flutter-apk/app-debug.apk \
  combineDateAndTime
```
Extracts `assets/flutter_assets/kernel_blob.bin` from the APK and greps it for each named string. Exit 0 if
every string is found ≥1 time; exit 1 naming exactly which string is missing otherwise. Debug (JIT/kernel-
blob) builds only — a release/AOT build has no `kernel_blob.bin` and the script says so explicitly rather
than silently passing.

**Generalizing beyond Flutter:** the pattern (extract a build artifact's embedded source-derived strings,
grep for a symbol that should only be present if the build is current) applies to any build system with a
similarly opaque "did it actually rebuild" question — swap the extraction step for your own build's
equivalent (a source map, a compiled bundle, a debug symbol table) and keep the rest.

---

## Model history and DeepSeek gateway (reference, not required for adoption)

`call_implementation_agent.sh`'s header keeps a full, dated history of every model/profile ever used as the
Implementation Agent default, including a still-configured (but currently unused) DeepSeek V4 local gateway
setup — Windows-side gateway process, firewall rule, WSL-side shared token, and per-model `config.toml`
profiles. None of this is required to adopt the pipeline; it's kept as a working example of how to wire in
an alternative model provider via Codex's `model_providers` config block, and as a cautionary record of a
real setup bug (a health-check that silently rejected every poll due to a missing auth header, causing
false-negative startup timeouts) for anyone building a similar gateway. See the script's own header comment
for full config-file contents and setup steps if you need this path.
