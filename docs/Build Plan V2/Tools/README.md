# Loom Agent Tooling — standalone adoption guide

This directory is a **self-contained toolkit** for running an unattended, independently-verified
implementation pipeline on top of an AI coding CLI (Codex) plus an in-session review layer (Claude Code
subagents). It was built and hardened inside the Loom repo across roughly a month of real dispatch rounds —
every guard, script, and doc here exists because a specific failure happened first. Everything you need to
adopt it in another project is in this directory: the scripts (`code/`), the per-tool docs, and this README
as the index.

**This is not a framework you install** — it's a small set of bash scripts plus a documented set of prompt
contracts for dispatching subagents. Copy what you need, adjust paths, done.

## Why this exists

Two AI workers do the actual work, and neither is trusted blind:

- **The Implementation Agent** (Codex CLI) writes code and commits it. It runs unattended, in the
  background, in its own sandbox — it cannot be watched line-by-line.
- **You** (the orchestrating Claude Code session) never trust its own self-report. Every ticket is
  independently re-verified: real `analyze`/test runs outside its sandbox, real diff reads, and for
  shared-code changes, a dedicated **Regression Impact Judge** dispatch that checks every other consumer of
  the changed code, not just the ticket's own test.

That discipline — dispatch, then independently verify, every single time, no exceptions — is the one rule
that matters more than any individual script below. Every guard/tool here exists to make that discipline
cheap enough to actually follow every round instead of skipping it under time pressure.

## Roles at a glance

| Role | Mechanism | Model (recommended) | Purpose | Doc |
|---|---|---|---|---|
| **Implementation Agent** | Codex CLI, WSL, backgrounded | GPT-5.3-Codex-Spark @ `xhigh` reasoning | Writes and commits real code/JSON changes against a ticket | `dispatch-pipeline-tools.md` |
| **Root Cause Agent** | Codex CLI, WSL, backgrounded, read-only by contract | GPT-5.6-Sol @ `xhigh` reasoning | Diagnoses a bug that has resisted your own hypothesis-and-test budget; never edits code | `root-cause-agent-tool.md` |
| **Regression Impact Judge** | Claude Code `Agent` tool (`general-purpose`), in-session | Inherit orchestrator model (Sonnet/Opus 5) | Verifies a shared-code fix against *every* real consumer, not just the ticket's own test | `regression-impact-judge-tool.md` |
| **Skill Output Judge** | Claude Code `Agent` tool (`general-purpose`), in-session | Inherit orchestrator model | Independently reviews one authored artifact (e.g. a community JSON package) against its source spec | see `Community JSON Migration Tracker.md` §1c for the worked pattern |
| **LLM Vision UX Judge** | Claude Code `Agent` tool, in-session (Phase A) / headless `claude` CLI (Phase B, planned) | Inherit orchestrator model (Phase A); Sonnet/Opus via CLI (Phase B) | Reviews rendered UI screenshots against a rubric + product doc | `ux-gate-judge-tools.md` |
| **Skill Retrospective** | `SendMessage` resuming the *original* authoring agent (not a fresh one) | N/A — resumes existing session | Turns a judge-found defect into a durable prompting/doc fix, by asking the agent that made the mistake why | `skill-retrospective-tool.md` |
| **Deterministic judge CLIs** (B11–B25) | Plain Dart CLI binaries, no LLM | N/A | Structural/grammar/evidence-completeness checks that don't need judgment calls | `ux-gate-judge-tools.md` |
| **Community package validator** | Plain Dart CLI + optional HTTP server | N/A | JSON-grammar guard: catches invalid workflow shapes, missing guards, bad references | `validator-tool.md` |
| **Community-authoring Skill** | Prompt bundle (`SKILL.md` + docs), dispatched via the `Agent` tool, a zero-tool-access external channel (e.g. custom GPT), or `call_skill_authoring_agent.sh` (Codex CLI, zero-repo-access, live GitHub fetch) | Inherit dispatching session's model, or GPT-5.6-Sol @ `xhigh` for the Codex channel | Authors a new engine-native JSON package from a product doc, following a fixed procedure + a growing "solved patterns" bank | `community-authoring-skill-tool.md` |

Two roles here (Regression Impact Judge, Skill Output Judge, LLM Vision UX Judge Phase A, Skill Retrospective)
are **prompt-defined, not code** — there is no registered custom subagent type file backing them (this repo
has none under `.claude/agents/`). They are dispatched via the generic `Agent` tool with `subagent_type:
general-purpose` (or `Explore` for pure read-only investigation) and a written brief that *is* the role
definition. Their "implementation" is the prompt contract documented in each tool's `.md` file — copy that
contract verbatim into your dispatch prompt to reuse the role in another project.

## Directory map

```
docs/Build Plan V2/Tools/
├── README.md                              <- you are here: master index, setup, roles, pipeline
├── code/                                  <- actual, runnable scripts (copy to <repo>/data/)
│   ├── call_implementation_agent.sh       <- dispatch the Implementation Agent
│   ├── call_root_cause_agent.sh           <- dispatch the Root Cause Agent
│   ├── call_skill_authoring_agent.sh      <- dispatch the community-authoring Skill (Codex, zero-repo-access)
│   ├── wsl_dispatch_tracker.sh            <- baseline/capture/cleanup WSL process tracking
│   ├── watch_dispatch_log.sh              <- self-terminating completion watcher
│   ├── handoff_gate.sh                    <- pre-verification handoff gate (5 checks)
│   ├── wsl_slot.sh                        <- concurrency gate for ad-hoc wsl.exe calls
│   ├── verify_apk_freshness.sh            <- stale-build guard for Flutter/Gradle debug APKs
│   └── loom-vm.ps1                        <- (VirtualBox env only) host-side VM control: power,
│                                             config, console screenshots, and in-guest commands
│                                             with no SSH -- wsl-to-virtualbox-migration.md §8
├── dispatch-pipeline-tools.md             <- full doc for every script in code/, with setup + guards
├── root-cause-agent-tool.md               <- Root Cause Agent role doc
├── regression-impact-judge-tool.md        <- Regression Impact Judge role doc
├── skill-retrospective-tool.md            <- Skill Retrospective process doc
├── ux-gate-judge-tools.md                 <- full B11-B25 deterministic + LLM-vision judge suite
├── b25-remediation-ticket-template.md     <- heavy schema-v4 ticket format (Remediation Planner path)
├── b25-product-doc-workflow-reconciliation-llm-gate.md
├── validator-tool.md                      <- community_package_validator.dart / validator_server.dart
├── community-authoring-skill-tool.md      <- the loom-calendar-experience-authoring Skill, as a tool
├── reference-ticket-template.md           <- the lightweight `## Context/## Scope/...` ticket format + example
├── reference-tracker-template.md          <- the tracker-doc format used to sequence a batch of tickets
└── wsl-to-virtualbox-migration.md         <- moving this toolkit off WSL2 onto a VirtualBox Ubuntu VM
```

Everything under `code/` is copied verbatim from this repo's own (gitignored) `data/` directory — see
"Setup in a new project" below for how to place it. Everything else is documentation; the Dart CLI judge
suite (`loom_ux_judges`) is a normal tracked package under `app/packages/tooling/loom_ux_judges/` in *this*
repo and is not duplicated here — adopt it by copying that package directory, described in
`ux-gate-judge-tools.md` and `validator-tool.md`.

## Deprecated tooling — deliberately not carried forward

An earlier **mailbox + file-watcher handoff** (`clear_mailbox.py`, `file_watcher.py`, `heartbeat_loop.sh`,
`verification_feedback_protocol.md` — all lived in `data/` in this repo, 2026-07-05 through 07-09) is **not
included here**. It worked by having the Implementation Agent poll/write a shared mailbox file via an MCP
server, with a manually-resumed session on the other end. `call_implementation_agent.sh`'s own header states
it plainly: *"replaces the old mailbox+manually-resumed-session handoff."* The direct-dispatch scripts in
`code/` (baseline → background dispatch → watch → cleanup → gate) are strictly better: no MCP server to keep
alive, no polling loop, no risk of two watchers racing to claim one delivery (a real bug the mailbox
mechanism hit and had to patch around). If you find a reference to the mailbox mechanism elsewhere in this
project's docs, treat it as historical only — do not reintroduce it.

Similarly, `b25_workflow_lifecycle_judge.dart` is kept in the Dart judge suite only as a compatibility alias
— use `b25_workflow_interaction_model_judge.dart` in new work (see `ux-gate-judge-tools.md`).

## Setup in a new project

1. **Install Codex CLI inside WSL** (this pipeline assumes Windows host + WSL2 + OneDrive/cloud-synced repo
   path — if your project isn't on that exact stack, most of the guards below are irrelevant and you can
   skip straight to the dispatch scripts' core logic):
   ```bash
   # inside WSL
   npm install -g @openai/codex   # or use `npx --yes @openai/codex` per-call, as the scripts already do
   ```
2. **Mark your repo trusted**, one time, in `~/.codex/config.toml` (WSL side):
   ```toml
   [projects."/mnt/c/Users/<you>/path/to/your-repo"]
   trust_level = "trusted"
   ```
3. **Add model profiles** you intend to use. Minimum viable set (the two this pipeline defaults to):
   ```toml
   # ~/.codex/gpt5_3_spark_xhigh.config.toml  (Implementation Agent default)
   model = "gpt-5.3-codex-spark"
   model_reasoning_effort = "xhigh"
   model_verbosity = "medium"
   model_context_window = 272000
   ```
   ```toml
   # ~/.codex/gpt5_6_sol_xhigh.config.toml  (Root Cause Agent default)
   model = "gpt-5.6-sol"
   model_reasoning_effort = "xhigh"
   model_verbosity = "medium"
   model_context_window = 272000
   ```
   Smoke-test a profile before trusting it on a real ticket:
   ```bash
   codex exec -p gpt5_3_spark_xhigh --sandbox read-only "Reply with exactly: PROFILE_OK"
   ```
4. **If your repo sits on a OneDrive-synced Windows path accessed from WSL** (the exact combination that
   caused every git-index-corruption incident behind the guards in `call_implementation_agent.sh`): install
   a native-git shim so dispatched agents use `git.exe`, not WSL's own git, for every git operation:
   ```bash
   mkdir -p ~/.codex-git-shim
   printf '#!/bin/bash\nexec git.exe "$@"\n' > ~/.codex-git-shim/git
   chmod +x ~/.codex-git-shim/git
   ```
   `call_implementation_agent.sh`/`call_root_cause_agent.sh` already prepend this shim to `PATH` if present
   — nothing else to wire up. If your repo is *not* on OneDrive/a cloud-sync path, you can skip this; the
   scripts degrade gracefully (the `if [ -x ... ]` check just no-ops).
5. **Copy the scripts** into your own repo's `data/` directory (the scripts compute their own repo root as
   `$(dirname "$0")/..`, so they must live exactly one directory below repo root — `data/` is the convention
   used here, but any single-level subdirectory name works as long as you're consistent):
   ```bash
   mkdir -p data
   cp docs/Build Plan V2/Tools/code/*.sh data/
   chmod +x data/*.sh
   ```
6. **Gitignore `data/`** if you don't want dispatch logs/PID files/trackers committed (this repo does
   exactly that — see `.gitignore:1`). The one exception worth tracking is the scripts themselves if you
   want them versioned for your team; this repo made the opposite choice (scripts live only on disk,
   re-derived from this guide) — pick whichever fits your project.
7. **(Optional) Install the headless Claude Code CLI** if you plan to build the automated (Phase B)
   LLM Vision UX Judge described in `ux-gate-judge-tools.md`:
   ```bash
   npm install -g @anthropic-ai/claude-code
   claude auth login --claudeai   # one-time browser OAuth against your existing Claude subscription
   claude auth status             # confirm "loggedIn": true
   ```
   Confirmed working non-interactively, vision included:
   ```bash
   claude -p "Reply with exactly the word OK" --output-format json
   claude -p "Describe this screenshot: heading text, primary button label and color" \
     --output-format json --allowedTools Read --dangerously-skip-permissions
   ```

## The core dispatch pipeline — worked example, start to finish

This is the exact recipe every real ticket in this project's history followed. Copy it verbatim for a new
ticket; the only things that change per-round are `<ticket>` and `<label>`.

```bash
# 0. Author the ticket file first (see reference-ticket-template.md for the exact section
#    structure and a filled-out worked example). Save it as data/v3_ticket_<slug>.md.
#    If this ticket serves a tracker doc (reference-tracker-template.md's §8 queue), the row for
#    it should already exist there BEFORE you dispatch -- see step 2's env vars below.

# 1. Baseline — snapshot the WSL process set before this dispatch starts
bash data/wsl_dispatch_tracker.sh baseline <label>

# 2. Dispatch, backgrounded — NEVER run call_implementation_agent.sh in the foreground; it
#    blocks your session for the full dispatch duration (often 5-20+ minutes).
#    DISPATCH_TRACKER_FILE/DISPATCH_TODO_ITEM (optional but recommended) name which tracker and
#    which §8 queue row this dispatch serves -- every call_*.sh script logs a start/finish marker
#    and prints a completion reminder for step 7.5 below when these are set. Omit only for a
#    genuinely untracked, one-off dispatch.
DISPATCH_TRACKER_FILE="docs/Build Plan V2/<Your Tracker>.md" \
DISPATCH_TODO_ITEM="<the exact §8 row title>" \
setsid nohup bash data/call_implementation_agent.sh data/v3_ticket_<slug>.md --fresh \
  < /dev/null > .codex-logs/<label>_dispatch.out.log 2>&1 & disown
sleep 3   # let the dispatch's own WSL session actually establish before capturing

# 3. Capture — diff the process set to identify exactly what THIS dispatch spawned
bash data/wsl_dispatch_tracker.sh capture <label>

# 4. Watch for genuine completion (NOT a raw `tail -F | grep` — see watch_dispatch_log.sh's own
#    header for why that leaks WSL sessions indefinitely)
wsl.exe -e bash -lc 'cd "/path/to/your-repo" && bash data/watch_dispatch_log.sh <label>'

# 5. Once genuinely complete (the watcher fired on "codex exec exited with status", not just a
#    mid-run vsock alert) -- do BOTH of the following together, as one paired step, BEFORE
#    running any analyze/test command:
bash data/wsl_dispatch_tracker.sh cleanup <label>
#    ...and confirm + commit the round's real edits (git status/git diff first) right alongside
#    cleanup. Do not defer the commit until after your own verification passes — an uncommitted,
#    untracked (`??`) file makes every later `git diff` show nothing for its content changes no
#    matter how many times it's edited, which has cost entire wasted re-fix rounds in practice.

# 6. Gate check — must print "READY FOR VALIDATION" before you touch anything else
bash data/handoff_gate.sh <label>

# 7. Independent verification (yours, never the dispatch's own self-report):
#    - `flutter analyze` (or your stack's equivalent) clean on every touched package
#    - full test suite, no unexplained pass-count drop from baseline
#    - for a shared-code change: a dedicated Regression Impact Judge dispatch
#      (regression-impact-judge-tool.md) against every real consumer
#    - for a UI-touching fix: live re-verification on a real device/emulator, not analyze/test alone

# 7.5. Fold the outcome into the TODO record — do this every time, even when nothing changes.
#      Read the dispatch's STATUS.md "## Proposed next steps" block (reference-ticket-template.md),
#      weigh each item against what you actually verified in step 7, then write the confirmed ones
#      into the tracker's §8 Live TODO / Next Steps Queue (reference-tracker-template.md) and add/
#      remove the matching one-line rollup in docs/Build Plan V2/TODO.md. This is never automatic —
#      the dispatch script's own completion banner (see the Guards table below) exists only to make
#      this step impossible to silently forget, not to do it for you.
```

**Session-wide WSL concurrency budget: cap total concurrent `wsl.exe` subprocesses at 4.** One dispatch (step
2) + one watcher (step 4) = 2 already-reserved slots. Route any *additional* ad-hoc `wsl.exe` calls (status
checks, log reads, one-off git commands) through `data/wsl_slot.sh` rather than firing them unbounded — see
`dispatch-pipeline-tools.md` for why (a hard, non-tunable WSL2 vsock connection cap that this exact usage
pattern exhausts).

## Guards and CLI checks — what clears each gate

| Guard | What it checks | Command | Clears when |
|---|---|---|---|
| Handoff gate | Dispatch finished, WSL cleaned up, tree committed, tracked-file count sane, HEAD resolves | `bash data/handoff_gate.sh <label>` | Prints `READY FOR VALIDATION`, exit 0 |
| Vsock exhaustion detector | Codex's own transcript for the known WSL2 vsock-exhaustion signature | built into `call_implementation_agent.sh`/`call_root_cause_agent.sh`, greps their own output | Absence of a `DISPATCH_HIT_VSOCK=1` banner in the dispatch log |
| Git integrity guard | Tracked-file count didn't collapse (silent tree-corruption signature) | built into `call_implementation_agent.sh`, pre/post `git ls-files \| wc -l` diff | No `GIT INTEGRITY ALERT` banner |
| WSL concurrency slot | Ad-hoc `wsl.exe` call count under the session cap | `bash data/wsl_slot.sh "<command>"` | Acquires a slot within `WSL_SLOT_TIMEOUT` (default 120s) |
| APK freshness guard | A built debug APK actually contains a just-added symbol, not a stale cached build | `bash data/verify_apk_freshness.sh <apk> <must-contain-string>` | Every named string found ≥1 time in the compiled kernel |
| JSON/grammar validator | A community/workflow JSON package is structurally valid (guards present, no dangling references, no destructive exits without a guard) | `dart run loom_ux_judges:community_package_validator --package <file>` | Zero errors (warnings are advisory) |
| B25 evidence/UX gates | Screenshot coverage, persona coverage, interaction-model correctness, LLM-vision review freshness | see `ux-gate-judge-tools.md` for the full chain | `production_ux_judge.dart` exits 0 |
| TODO-fold reminder | Every dispatch (`DISPATCH_TRACKER_FILE` set or not) prints a fixed completion banner naming step 7.5 above — never silently skippable | built into all three `call_*.sh` scripts, printed unconditionally right before exit | Not a pass/fail gate — a reminder; the real gate is you actually doing step 7.5 |
| Tracker-queue consistency check | `DISPATCH_TODO_ITEM`'s text actually appears in `DISPATCH_TRACKER_FILE` before dispatch starts | built into all three `call_*.sh` scripts, a non-blocking grep at dispatch start | Warns only if not found — does not block the dispatch, since prose wording can legitimately differ |

## Recommended models

- **Implementation Agent** (writes code): a strong, high-reasoning-effort coding model. This project defaults
  to GPT-5.3-Codex-Spark @ `xhigh` — chosen and smoke-tested for real ticket-length prompts, not just a
  one-line reply. If you substitute a different model/provider, smoke-test it the same way
  (`codex exec -p <profile> --sandbox read-only "Reply with exactly: PROFILE_OK"`) *and* on one real
  ticket before trusting it as your default — this project's own history includes a model that passed the
  one-line smoke test but never completed a real ticket-length prompt (see `dispatch-pipeline-tools.md`'s
  model-history note).
- **Root Cause Agent** (diagnoses, never writes): a high-reasoning-effort model tuned for careful multi-file
  tracing over raw code-writing speed — this project uses GPT-5.6-Sol @ `xhigh`.
- **Judges dispatched via the `Agent` tool** (Regression Impact Judge, Skill Output Judge, LLM Vision UX
  Judge Phase A, Skill Retrospective): inherit whatever model is running your orchestrating Claude Code
  session (Sonnet 5 or Opus 5) — these are in-session dispatches, not a separate CLI invocation, so there is
  no separate model choice to make.
- **Headless `claude` CLI** (LLM Vision UX Judge Phase B, if built): your Claude subscription's own default,
  invoked via `claude -p "..."` — confirmed working non-interactively including vision, no separate API key
  needed if you're already authenticated via `claude auth login --claudeai`.

## Where to go next

- Writing your first ticket: `reference-ticket-template.md`
- Sequencing a batch of tickets: `reference-tracker-template.md`
- Full script-by-script reference (every flag, every guard, every incident that caused it):
  `dispatch-pipeline-tools.md`
- A bug that's resisting normal investigation: `root-cause-agent-tool.md`
- About to mark a shared-code ticket done: `regression-impact-judge-tool.md`
- A judge just found a real defect in an authored artifact: `skill-retrospective-tool.md`
- Reviewing rendered UI, not just code: `ux-gate-judge-tools.md`
- Validating a JSON/config package before it ships: `validator-tool.md`
- Authoring a new artifact from a spec doc, not just fixing one: `community-authoring-skill-tool.md`
- Moving this toolkit off WSL2 onto a VirtualBox Ubuntu VM: `wsl-to-virtualbox-migration.md` —
  note that roughly half the scripts in `code/` exist only to work around WSL2/OneDrive
  pathologies and are **deleted rather than ported** in that environment
