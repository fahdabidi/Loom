#!/bin/bash
# data/call_root_cause_agent.sh
#
# Direct invocation of the Root Cause Agent. Added 2026-08-01 after
# CAL.Notify2.9's own regression investigation exhausted the verification
# agent's own hypothesis-and-test budget without pinning the exact mechanism
# (systematically ruled out five candidate causes, each confirmed NOT
# responsible, with the true mechanism still unidentified).
#
# Migrated off WSL2 onto a VirtualBox Ubuntu VM 2026-08-12 -- see
# docs/Build Plan V2/Tools/wsl-to-virtualbox-migration.md. Runs INSIDE the
# guest (~/Loom/data/), invoked from the host via
# `ssh loom-vm '. ~/.loom-env.sh && ...'`, not via `wsl.exe`.
#
# Switched Codex CLI -> Muse Code CLI 2026-09-07, then back to Codex CLI the
# same day (both user-directed) -- model `gpt-6-astra` at reasoning
# effort `high`. This required upgrading the VM's Codex CLI itself: the
# installed 0.147.0 rejected `gpt-6-astra` with "requires a newer version of
# Codex"; `npm install -g @openai/codex@0.153.4` fixed it, confirmed live
# (`codex exec -p gpt6_astra_high --sandbox read-only "Reply with exactly:
# PROFILE_OK"` -> correct reply, exit 0). Profile:
# ~/.codex/gpt6_astra_high.config.toml (model = "gpt-6-astra",
# model_reasoning_effort = "high", model_verbosity = "medium",
# model_context_window = 272000, service_tier = "fast").
#
# PERSISTENT SESSION, user-directed 2026-09-07: this agent must never start a
# fresh session by default -- every dispatch resumes the SAME session id, so
# it accumulates codebase familiarity across every investigation rather than
# starting cold each time. Mechanism: the session's Codex thread id is
# captured once (from the `thread.started` event in `--json` output, which
# every dispatch now uses) and persisted at
# `.codex-logs/.root_cause_agent_session_id`. Every later dispatch reads that
# id and resumes it. There is deliberately NO flag to force a fresh session --
# that was the previous script's footgun (a caller could omit `--fresh` by
# habit or by intent and silently get an unrelated resumed session, or worse,
# rely on `resume --last` picking up whatever ANY other Codex dispatch on this
# box last touched). If the accumulated session ever needs to be abandoned
# (corrupted, too large, or a deliberate reset), delete that file by hand --
# an out-of-band, deliberate action, not a script flag.
#
# Discovered the hard way (confirmed live, not guessed) while wiring this up:
# `codex exec resume <SESSION_ID> [OPTIONS] [PROMPT]` does NOT accept
# `-p/--profile`, `--sandbox`, or `--add-dir` -- only `-c/--config` and
# `-m/--model` (its own `--help` lists the full set; anything else is a hard
# parse error, e.g. "unexpected argument '--sandbox' found"). So the sandbox
# mode and every `--add-dir` grant are fixed FOREVER at the seed (first-ever)
# invocation and cannot be changed by any later resume -- get them right once.
# The model/profile settings, by contrast, must be RE-SPECIFIED via `-c` on
# every resume (there is no profile layering on `resume`), which is why the
# resume branch below spells out every `gpt6_astra_high.config.toml` value as
# its own `-c key=value` rather than `-p gpt6_astra_high`. Confirmed live that
# the thread id is stable across a resume (resuming
# `01a07e37-e580-7e83-a65e-a2a6bec42e89` and asking the agent to quote what it
# was told in the previous turn got the previous turn's exact text back, and
# the emitted `thread_id` in the `--json` stream was byte-identical to the id
# passed in) -- this is a real continued conversation, not a fresh session
# that happens to share a label.
#
# ROLE, not a variant of the implementation agent: this agent NEVER writes or
# modifies implementation code, never applies a patch against source files,
# never commits, never touches the frozen fixture. It runs with
# `--sandbox workspace-write` plus network access and `--add-dir` grants for
# the repo's `.git` and `/tmp` (past reports have been written to `/tmp`) --
# there is no filesystem-level restriction to one output file. Enforcement is:
# (a) the prompt preamble below, repeated and explicit on every turn
# (deliberately not trimmed away on resume -- a long-lived session is exactly
# where a rule stated once, hundreds of turns ago, is most likely to drift),
# and (b) the verification agent (you) MUST `git status`/`git diff` after
# every run and treat ANY change outside the one designated report file as a
# violation to investigate, not to silently accept or commit. Codex's own
# workspace-write sandbox never restricted writes to a single file; real
# enforcement was always the prompt + the post-hoc audit below, not the
# sandbox boundary.
#
# Two, and only two, valid outcomes for a Root Cause Agent report:
#   1. A confident root-cause diagnosis + a specific, concrete recommended
#      fix described in prose (file/function/mechanism-level, not a diff) --
#      handed back to the verification agent to turn into a real
#      implementation ticket.
#   2. A precise, minimal specification of what additional instrumentation,
#      tracing, or tests are needed to narrow the mechanism further -- exact
#      file:line locations to instrument, exact values to print, exact
#      scenarios to run -- handed back to the verification agent to turn into
#      an instrumentation ticket for the implementation agent.
# A report that does neither (e.g. "try X and see if it works") is incomplete
# -- re-dispatch with that fed back, don't accept it as final.
#
# Two jobs, not one (recorded 2026-09-07 in the ACWS tracker and TODO.md):
# scoping a non-trivial change BEFORE an implementation ticket is written --
# what it actually touches, the real mechanism, what it would break -- not
# only debugging something that already broke.
#
# Usage:
#   bash data/call_root_cause_agent.sh <path-to-brief-file>
#
# No mode argument. Every dispatch resumes the one persistent session; see
# the PERSISTENT SESSION note above for how to deliberately reset it.
#
# Same dispatch-and-watch recipe as data/call_implementation_agent.sh
# (dispatch over ssh loom-vm, watch via watch_dispatch_log.sh) -- reuse that
# recipe verbatim, this script only differs in role/model/sandbox scope, not
# in dispatch mechanics. `watch_dispatch_log.sh` recognizes
# "codex exec exited with status" as the real completion line -- unchanged
# from before the Muse detour, no update needed there.
#
# The brief file you pass in should include: the current diff/commit(s) under
# investigation (or, for a scoping dispatch, what change is being considered
# and why), the full ruled-in/ruled-out matrix so far (do not make the agent
# re-derive work already done), any trace/log output already captured, and
# the exact report file path to write to.

set -euo pipefail

PROMPT_FILE="${1:?usage: call_root_cause_agent.sh <brief-file>}"
MODEL="${CODEX_ROOT_CAUSE_MODEL:-gpt-6-astra}"
REASONING_EFFORT="${CODEX_ROOT_CAUSE_REASONING_EFFORT:-high}"
PROFILE="${CODEX_ROOT_CAUSE_PROFILE:-gpt6_astra_high}"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: brief file not found: $PROMPT_FILE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Non-interactive shells (via `ssh loom-vm 'cmd'`) skip ~/.bashrc entirely --
# resolve the toolchain PATH explicitly. Never substitute `bash -l`.
. "$HOME/.loom-env.sh"

ROLE_PREAMBLE='# ROLE: Root Cause Agent -- read this before anything else

You are the Root Cause Agent for this repository -- either scoping a non-trivial change before an
implementation ticket is written, or investigating a bug that has resisted the verification agent'"'"'s own
hypothesis-and-test budget. You are NOT an implementation agent. This is a long-lived, persistent session:
you carry context across every dispatch made to you, so treat earlier turns in this conversation as real
prior investigation, not as something to re-derive.

**You must NEVER:**
- Edit, create, or delete any implementation file (`.dart`, `.jsonc`, `.md` reference docs, anything under
  `app/` or `docs/references/`) -- not even a "small diagnostic tweak." Not even something you are highly
  confident is the fix. That decision belongs to the user, after you report, via a separate implementation
  ticket.
- Modify anything other than the ONE report file path given to you below.
- Run `git add`/`git commit`, or any command that mutates repository state.
- Add print statements, comment out code, or otherwise "just check" something by editing a real file. If you
  want to know what a value would be at runtime, reason about it from the code, or explicitly request that
  exact instrumentation be added by a future round -- do not add it yourself.

**Your job**, given the brief below (code, diffs, an existing ruled-in/ruled-out matrix, and any captured
trace/log output): produce EXACTLY ONE of two outcomes, written to the exact report file path specified in
the brief:

1. **A confident root-cause diagnosis + a concrete recommended fix** (or, for a scoping dispatch, a
   confident account of the real mechanism and what a change would actually touch/break). State the mechanism
   precisely (which function, which line, which interaction, why it produces the observed symptom) and
   describe the fix at the level of "change X to do Y because Z" -- prose/pseudocode is fine, a literal diff
   is not required (that is the implementation agent'"'"'s job once you hand this off). Only report this
   outcome if you are genuinely confident, not merely suspicious -- a wrong confident diagnosis costs a full
   wasted implementation round.
2. **A precise instrumentation/tracing request.** If you cannot reach outcome 1 from what you were given,
   specify EXACTLY what would let you: exact file:line locations to add temporary logging, exactly what
   values to print at each, exactly what test/scenario to run to trigger them, and what you expect each
   candidate mechanism would look like in that output (so whoever reads the resulting log can tell which
   hypothesis it confirms). Vague requests ("add more logging around the mutation") are not acceptable --
   name the specific function, the specific variable, the specific comparison.

Do not hedge between the two. If you are not confident enough for outcome 1, you must produce outcome 2, not
a weaker version of outcome 1.

---

'

PROMPT="$ROLE_PREAMBLE$(cat "$PROMPT_FILE")"

PRE_TRACKED_COUNT="$(git ls-files | wc -l)"
PRE_HEAD="$(git rev-parse HEAD)"

cd "$REPO_ROOT"

mkdir -p "$REPO_ROOT/.codex-logs"
SESSION_ID_FILE="$REPO_ROOT/.codex-logs/.root_cause_agent_session_id"
SESSION_ID=""
if [ -f "$SESSION_ID_FILE" ]; then
  SESSION_ID="$(tr -d '[:space:]' < "$SESSION_ID_FILE")"
fi

echo "=== Invoking Root Cause Agent (codex exec) ==="
echo "Repo: $REPO_ROOT"
echo "Brief file: $PROMPT_FILE ($(wc -l < "$PROMPT_FILE") lines)"
if [ -n "$SESSION_ID" ]; then
  echo "Mode: resuming persistent session $SESSION_ID"
else
  echo "Mode: seeding the persistent session (none recorded yet at $SESSION_ID_FILE)"
fi
echo "Model: $MODEL"
echo "Reasoning effort: $REASONING_EFFORT"
echo "===================================================="

# --- TODO-tracking hooks (optional; see docs/Build Plan V2/Tools/reference-tracker-
# template.md's §8 "Live TODO / Next Steps Queue" -- see call_implementation_agent.sh's
# own header comment for the full rationale, identical behavior here.
TODO_LOG="$REPO_ROOT/.codex-logs/.dispatch_todo_log.log"
echo "DISPATCH_STARTED $(date -u +%Y-%m-%dT%H:%M:%SZ) script=call_root_cause_agent.sh brief=\"$PROMPT_FILE\" tracker=\"${DISPATCH_TRACKER_FILE:-}\" item=\"${DISPATCH_TODO_ITEM:-}\"" >> "$TODO_LOG"
if [ -n "${DISPATCH_TRACKER_FILE:-}" ]; then
  if [ -f "$REPO_ROOT/$DISPATCH_TRACKER_FILE" ]; then
    if [ -n "${DISPATCH_TODO_ITEM:-}" ] && ! grep -qF "$DISPATCH_TODO_ITEM" "$REPO_ROOT/$DISPATCH_TRACKER_FILE"; then
      echo "WARNING: DISPATCH_TODO_ITEM text not found in $DISPATCH_TRACKER_FILE -- confirm it's already" >&2
      echo "         queued in that tracker's §8 Live TODO / Next Steps Queue (wording may just differ)." >&2
    fi
  else
    echo "WARNING: DISPATCH_TRACKER_FILE '$DISPATCH_TRACKER_FILE' not found relative to repo root." >&2
  fi
else
  echo "NOTE: no DISPATCH_TRACKER_FILE set for this dispatch -- you decide whether" >&2
  echo "      docs/Build Plan V2/TODO.md needs a new entry once this completes." >&2
fi

echo "$$" > .codex-logs/.last_dispatch.pid

CODEX_OUTPUT_CAPTURE="$(mktemp)"
set +e

if [ -z "$SESSION_ID" ]; then
  # Seed run: this is the ONLY invocation where sandbox/add-dir/profile can be
  # set, since `resume` accepts none of them -- get every grant right here.
  codex exec \
    -p "$PROFILE" \
    --sandbox workspace-write \
    --add-dir "$REPO_ROOT/.git" \
    --add-dir /tmp \
    -c sandbox_workspace_write.network_access=true \
    --json \
    "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
else
  # Resume: no -p/--sandbox/--add-dir accepted here (confirmed live -- see
  # header). Every profile value re-specified as its own -c override.
  codex exec resume "$SESSION_ID" \
    -c model="$MODEL" \
    -c model_reasoning_effort="$REASONING_EFFORT" \
    -c model_verbosity="medium" \
    -c model_context_window=272000 \
    -c service_tier="fast" \
    -c sandbox_workspace_write.network_access=true \
    --json \
    "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
fi
STATUS="${PIPESTATUS[0]}"
set -e

echo "===================================================="
echo "codex exec exited with status $STATUS"

if [ -z "$SESSION_ID" ]; then
  NEW_SESSION_ID="$(grep -o '"thread_id":"[^"]*"' "$CODEX_OUTPUT_CAPTURE" | head -1 | sed 's/.*:"//; s/"$//')"
  if [ -n "$NEW_SESSION_ID" ]; then
    printf '%s\n' "$NEW_SESSION_ID" > "$SESSION_ID_FILE"
    echo "Persisted new session id for all future dispatches: $NEW_SESSION_ID ($SESSION_ID_FILE)"
  else
    echo "##################################################################"
    echo "# WARNING: no thread_id found in this seed run's output -- the session was NOT persisted. #"
    echo "# The NEXT dispatch will seed again instead of resuming this one. Check $CODEX_OUTPUT_CAPTURE. #"
    echo "##################################################################"
  fi
fi

rm -f "$CODEX_OUTPUT_CAPTURE"

POST_TRACKED_COUNT="$(git ls-files | wc -l)"
POST_HEAD="$(git rev-parse HEAD)"
if [ "$POST_HEAD" != "$PRE_HEAD" ]; then
  echo "##################################################################"
  echo "# VIOLATION: HEAD moved ($PRE_HEAD -> $POST_HEAD). The Root Cause Agent must never commit. #"
  echo "##################################################################"
fi
if [ "$POST_TRACKED_COUNT" -lt "$PRE_TRACKED_COUNT" ]; then
  echo "##################################################################"
  echo "# WARNING: tracked file count dropped ($PRE_TRACKED_COUNT -> $POST_TRACKED_COUNT). Investigate before trusting anything. #"
  echo "##################################################################"
fi

DIRTY="$(git status --short)"
if [ -n "$DIRTY" ]; then
  echo "WARNING: working tree is not clean after this run -- review every line below. Only the"
  echo "designated report file should appear here; anything else is a role violation to investigate,"
  echo "not to silently commit or discard:"
  echo "$DIRTY" | sed 's/^/  /'
fi

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) DISPATCH_FINISHED status=$STATUS" >> "$TODO_LOG"
echo "##################################################################"
echo "# NEXT STEP: fold this dispatch's outcome into the TODO record. #"
echo "##################################################################"
if [ -n "${DISPATCH_TRACKER_FILE:-}" ]; then
  echo "Review this agent's diagnosis/report against your own read, then update"
  echo "'$DISPATCH_TRACKER_FILE''s §8 Live TODO / Next Steps Queue and docs/Build Plan V2/TODO.md's rollup"
  echo "accordingly (typically: resolve the needs-debug-agent row, add a new-ticket row for the fix)."
else
  echo "No DISPATCH_TRACKER_FILE was set -- decide whether docs/Build Plan V2/TODO.md needs a new entry"
  echo "for this dispatch's outcome."
fi

exit "$STATUS"
