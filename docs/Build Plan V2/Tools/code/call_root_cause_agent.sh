#!/bin/bash
# data/call_root_cause_agent.sh
#
# Direct invocation of the Root Cause Agent (Codex CLI, WSL, profile
# gpt5_6_sol_xhigh -- model gpt-5.6-sol at reasoning_effort=xhigh). Added
# 2026-08-01 after CAL.Notify2.9's own regression investigation exhausted the
# verification agent's own hypothesis-and-test budget without pinning the
# exact mechanism (systematically ruled out five candidate causes, each
# confirmed NOT responsible, with the true mechanism still unidentified).
#
# ROLE, not a variant of the implementation agent: this agent NEVER writes or
# modifies implementation code, never runs `apply_patch` against source
# files, never commits, never touches the frozen fixture. Its sandbox is
# workspace-write only so it CAN write its own single report file -- nothing
# else. Enforcement is: (a) the prompt preamble below, repeated and explicit,
# and (b) the verification agent (you) MUST `git status`/`git diff` after
# every run and treat ANY change outside the one designated report file as a
# violation to investigate, not to silently accept or commit.
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
# Usage:
#   bash data/call_root_cause_agent.sh <path-to-brief-file> [--fresh]
#
# Same dispatch-and-watch recipe as data/call_implementation_agent.sh
# (wsl_dispatch_tracker.sh baseline/capture/cleanup, watch_dispatch_log.sh or
# a grep-based poll loop if tail -F proves unreliable on a given host) --
# reuse that recipe verbatim, this script only differs in role/profile/sandbox
# scope, not in dispatch mechanics.
#
# The brief file you pass in should include: the current diff/commit(s) under
# investigation, the full ruled-in/ruled-out matrix so far (do not make the
# agent re-derive work already done), any trace/log output already captured,
# and the exact report file path to write to.

set -euo pipefail

PROMPT_FILE="${1:?usage: call_root_cause_agent.sh <brief-file> [--fresh]}"
MODE="${2:-}"
SANDBOX_MODE="${CODEX_ROOT_CAUSE_SANDBOX:-workspace-write}"
PROFILE="${CODEX_ROOT_CAUSE_PROFILE-gpt5_6_sol_xhigh}"
PROFILE_ARGS=()
if [ -n "$PROFILE" ]; then
  PROFILE_ARGS=(-p "$PROFILE")
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: brief file not found: $PROMPT_FILE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NVM_NODE_BIN=""
if [ -d "$HOME/.nvm/versions/node" ]; then
  NVM_NODE_BIN="$(ls -d "$HOME"/.nvm/versions/node/*/bin 2>/dev/null | sort -V | tail -n1)"
fi
if [ -n "$NVM_NODE_BIN" ]; then
  export PATH="$NVM_NODE_BIN:$PATH"
fi
if [ -x "$HOME/.codex-git-shim/git" ]; then
  export PATH="$HOME/.codex-git-shim:$PATH"
fi

ROLE_PREAMBLE='# ROLE: Root Cause Agent -- read this before anything else

You are the Root Cause Agent for this repository, invoked because a bug has resisted the verification
agent'"'"'s own hypothesis-and-test budget. You are NOT an implementation agent.

**You must NEVER:**
- Edit, create, or delete any implementation file (`.dart`, `.jsonc`, `.md` reference docs, anything under
  `app/` or `docs/references/`) -- not even a "small diagnostic tweak." Not even something you are highly
  confident is the fix. That decision belongs to the user, after you report, via a separate implementation
  ticket.
- Run `apply_patch` against anything other than the ONE report file path given to you below.
- Run `git add`/`git commit`, or any command that mutates repository state.
- Add print statements, comment out code, or otherwise "just check" something by editing a real file. If you
  want to know what a value would be at runtime, reason about it from the code, or explicitly request that
  exact instrumentation be added by a future round -- do not add it yourself.

**Your job**, given the brief below (code, diffs, an existing ruled-in/ruled-out matrix, and any captured
trace/log output): produce EXACTLY ONE of two outcomes, written to the exact report file path specified in
the brief:

1. **A confident root-cause diagnosis + a concrete recommended fix.** State the mechanism precisely (which
   function, which line, which interaction, why it produces the observed symptom) and describe the fix at the
   level of "change X to do Y because Z" -- prose/pseudocode is fine, a literal diff is not required (that is
   the implementation agent'"'"'s job once you hand this off). Only report this outcome if you are genuinely
   confident, not merely suspicious -- a wrong confident diagnosis costs a full wasted implementation round.
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

PRE_TRACKED_COUNT="$(git.exe ls-files | wc -l)"
PRE_HEAD="$(git.exe rev-parse HEAD)"

echo "=== Invoking Root Cause Agent (codex exec) ==="
echo "Repo: $REPO_ROOT"
echo "Brief file: $PROMPT_FILE ($(wc -l < "$PROMPT_FILE") lines)"
echo "Mode: $([ "$MODE" = "--fresh" ] && echo "fresh session" || echo "resume --last")"
echo "Sandbox: $SANDBOX_MODE"
echo "Profile: ${PROFILE:-<none -- Codex default model>}"
echo "===================================================="

cd "$REPO_ROOT"

# --- TODO-tracking hooks (optional; see docs/Build Plan V2/Tools/reference-tracker-
# template.md's §8 "Live TODO / Next Steps Queue" -- see call_implementation_agent.sh's
# own header comment for the full rationale, identical behavior here.
mkdir -p "$REPO_ROOT/.codex-logs"
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

mkdir -p .codex-logs
echo "$$" > .codex-logs/.last_dispatch.pid

CODEX_OUTPUT_CAPTURE="$(mktemp)"
set +e
if [ "$MODE" = "--fresh" ]; then
  npx --yes @openai/codex exec \
    "${PROFILE_ARGS[@]}" \
    --sandbox "$SANDBOX_MODE" \
    --add-dir "$REPO_ROOT/.git" \
    "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
else
  npx --yes @openai/codex exec \
    "${PROFILE_ARGS[@]}" \
    --sandbox "$SANDBOX_MODE" \
    --add-dir "$REPO_ROOT/.git" \
    resume --last "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
fi
STATUS="${PIPESTATUS[0]}"
set -e

echo "===================================================="
echo "codex exec exited with status $STATUS"

if grep -qE "UtilBindVsockAnyPort|UtilAcceptVsock|accept4 failed" "$CODEX_OUTPUT_CAPTURE"; then
  echo "##################################################################"
  echo "# DISPATCH_HIT_VSOCK=1 -- WSL vsock error appeared this run.     #"
  echo "##################################################################"
  echo "Same known issue as the implementation agent's own dispatch script. A fresh retry is safe --"
  echo "this agent never commits, and its own report file (if any) is easy to check for completeness."
fi
rm -f "$CODEX_OUTPUT_CAPTURE"

POST_TRACKED_COUNT="$(git.exe ls-files | wc -l)"
POST_HEAD="$(git.exe rev-parse HEAD)"
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

DIRTY="$(git.exe status --short)"
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
