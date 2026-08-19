#!/bin/bash
# data/call_skill_authoring_agent.sh
#
# Dispatches the `loom-calendar-experience-authoring` Skill to a Codex CLI
# agent running in a ChatGPT-equivalent emulation: zero local repo access,
# zero shell/file tools beyond what Codex's own sandbox always grants, live
# GitHub reads as the only way to see `docs/references/**`. This is the
# THIRD channel the Skill is proven on (see SKILL.md's channel list), built
# 2026-08-11 at explicit user request: "The tool emulates the chatgpt
# envionment (including the AI model) using the codex cli."
#
# Community JSON (docs/references/communities/*.jsonc) must NEVER be
# hand-authored directly -- see this repo's own standing rule (surfaced hard,
# 2026-08-11, after a direct hand-authoring pass had to be fully reverted).
# This script is the sanctioned in-repo-session mechanism for producing it:
# dispatch this, review the agent's returned JSON, THEN (only with the
# user's fresh, explicit, per-instance approval) it becomes a real file.
#
# Usage:
#   bash data/call_skill_authoring_agent.sh <target-doc-file> [label]
#
#   <target-doc-file>  A local file whose full text becomes the "target
#                       product doc" section of the prompt -- i.e. what the
#                       agent is being asked to author against. Read locally
#                       and embedded verbatim; the agent itself never fetches
#                       this file (matches codex-dispatch/INSTRUCTIONS.md's
#                       "given to you at dispatch time" framing -- everything
#                       ELSE it needs, it fetches live from GitHub itself).
#   [label]             Optional short slug for this run's log directory
#                        (default: derived from the target file's basename +
#                        a timestamp). Used only for .codex-logs/ naming.
#
# What this script does NOT do (by design, unlike call_implementation_agent.sh):
#   - No git operations of any kind -- the dispatched agent never touches this
#     repo's git state, so there is no git-safety preamble, no pre/post
#     tracked-file-count integrity check, no commit. Its ENTIRE output is
#     text (JSON + traceability table + gaps section), captured to a file for
#     the calling session (you) to review and, if and when approved, turn
#     into a real committed file yourself -- through the normal edit/commit
#     path, never by this script.
#   - No live validator call from inside the dispatch -- confirmed by direct
#     testing (2026-08-11) that this sandbox's shell-level network access
#     cannot reach arbitrary HTTPS endpoints (a plain curl to the validator's
#     own health-check URL fails at DNS resolution). The only network path
#     confirmed reliable from inside the sandbox is Codex's own built-in
#     `github.fetch_file` tool. codex-dispatch/INSTRUCTIONS.md's validation
#     section has the agent run a rigorous MANUAL self-check instead and say
#     so plainly. Real validator confirmation is this script's caller's job,
#     immediately after the dispatch returns: run the returned JSON through
#     `dart run packages/tooling/loom_ux_judges/bin/validator_server.dart`
#     (or the community_package_validator CLI) yourself, from your own
#     unsandboxed shell, before treating the output as validator-clean.
#
# Preflight (fatal if it fails, see below): confirms local HEAD matches
# `origin/main`. This tool's entire premise is that the dispatched agent
# reads live, current `docs/references/**` content via GitHub -- if local
# has unpushed doc changes, the agent would author against stale docs
# without anyone knowing. Push first (see loom_commit_push_authorization
# memory -- spec-doc/skill-bundle pushes for this workflow are
# pre-authorized) or pass ALLOW_STALE_PUSH=1 to bypass deliberately (e.g. a
# throwaway mechanism smoke-test where doc currency doesn't matter).
#
# Model: gpt5_6_sol_xhigh ("GPT 5.6 Sol on High Reasoning",
# ~/.codex/gpt5_6_sol_xhigh.config.toml -- model = "gpt-5.6-sol",
# model_reasoning_effort = "xhigh"). This profile already existed (created
# 2026-08-01, not by this script) -- confirmed by direct read, not assumed.
# Override with CODEX_SKILL_AUTHORING_PROFILE=<name>.
#
# Isolation mechanism (the actual "turn off repo access" implementation):
# `-C <fresh scratch dir under $HOME, OUTSIDE this repo entirely>` sets the
# agent's working root to a directory with zero Loom content, `--add-dir` is
# deliberately NEVER passed (nothing else becomes writable/visible), and
# `--skip-git-repo-check` allows Codex to run outside a git repo at all
# (the scratch dir isn't one). A fresh directory per dispatch, never reused,
# so no output from a prior run can leak into a later one as unearned
# context. `--ephemeral` additionally skips persisting Codex's own session
# files, matching the "stateless external provider" premise -- no --resume
# capability is offered by this script, deliberately: each dispatch should
# stand on its own, exactly like a fresh ChatGPT conversation would.
#
# Migrated off WSL2 onto a VirtualBox Ubuntu VM 2026-08-12 -- see
# docs/Build Plan V2/Tools/wsl-to-virtualbox-migration.md. Runs INSIDE the
# guest (~/Loom/data/), invoked from the host via
# `ssh loom-vm '. ~/.loom-env.sh && ...'`. This channel already had zero git
# operations of its own beyond the HEAD==origin/main preflight below, and no
# git-shim/vsock-detector code to strip -- the smallest port of the three.

set -euo pipefail

TARGET_DOC="${1:?usage: call_skill_authoring_agent.sh <target-doc-file> [label]}"
if [ ! -f "$TARGET_DOC" ]; then
  echo "ERROR: target doc file not found: $TARGET_DOC" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

LABEL="${2:-$(basename "$TARGET_DOC" | sed 's/\.[^.]*$//')-$(date +%Y%m%d-%H%M%S)}"
PROFILE="${CODEX_SKILL_AUTHORING_PROFILE-gpt5_6_sol_xhigh}"
PROFILE_ARGS=()
if [ -n "$PROFILE" ]; then
  PROFILE_ARGS=(-p "$PROFILE")
fi

INSTRUCTIONS_FILE="$REPO_ROOT/.agents/skills/loom-calendar-experience-authoring/codex-dispatch/INSTRUCTIONS.md"
if [ ! -f "$INSTRUCTIONS_FILE" ]; then
  echo "ERROR: instructions file not found: $INSTRUCTIONS_FILE" >&2
  exit 1
fi

# --- Preflight: local HEAD must match origin/main -----------------------
CURRENT_HEAD="$(git rev-parse HEAD)"
git fetch origin main --quiet
ORIGIN_MAIN="$(git rev-parse origin/main)"
if [ "$CURRENT_HEAD" != "$ORIGIN_MAIN" ] && [ "${ALLOW_STALE_PUSH:-0}" != "1" ]; then
  echo "ERROR: local HEAD ($CURRENT_HEAD) != origin/main ($ORIGIN_MAIN)." >&2
  echo "       This dispatch's entire premise is reading LIVE docs/references/** via GitHub --" >&2
  echo "       an unpushed local doc change would silently be invisible to the agent." >&2
  echo "       Push first, or set ALLOW_STALE_PUSH=1 to bypass deliberately." >&2
  exit 1
fi
if [ -n "$(git status --porcelain -- docs/references .agents/skills/loom-calendar-experience-authoring)" ]; then
  echo "WARNING: uncommitted changes under docs/references/ or the Skill bundle -- the dispatched" >&2
  echo "         agent will NOT see these (it reads GitHub, not this working tree)." >&2
fi

# --- Scratch dir: fresh, outside the repo, never reused ------------------
SCRATCH_ROOT="$HOME/.codex-skill-authoring-scratch"
SCRATCH_DIR="$SCRATCH_ROOT/$LABEL"
mkdir -p "$SCRATCH_DIR"

LOG_DIR="$REPO_ROOT/.codex-logs/skill-authoring/$LABEL"
mkdir -p "$LOG_DIR"
JSON_LOG="$LOG_DIR/events.jsonl"
LAST_MESSAGE_FILE="$LOG_DIR/final_answer.md"

# --- Prompt assembly ------------------------------------------------------
PROMPT_FILE="$LOG_DIR/prompt.md"
{
  cat "$INSTRUCTIONS_FILE"
  echo
  echo "---"
  echo
  echo "## Target product doc (supplied directly, do not attempt to fetch this one)"
  echo
  cat "$TARGET_DOC"
} > "$PROMPT_FILE"

echo "=== Invoking Skill-authoring Agent (codex exec, GitHub-fetch channel) ==="
echo "Repo:            $REPO_ROOT (origin/main @ $ORIGIN_MAIN)"
echo "Target doc:      $TARGET_DOC"
echo "Prompt file:     $PROMPT_FILE ($(wc -l < "$PROMPT_FILE") lines)"
echo "Scratch dir:     $SCRATCH_DIR (fresh, zero repo content, --add-dir never granted)"
echo "Profile:         ${PROFILE:-<none -- Codex default model>}"
echo "Label:           $LABEL"
echo "Event log:       $JSON_LOG"
echo "Final answer:    $LAST_MESSAGE_FILE"
echo "============================================================================"

mkdir -p "$REPO_ROOT/.codex-logs"
echo "$$" > "$REPO_ROOT/.codex-logs/.last_skill_authoring_dispatch.pid"

# --- TODO-tracking hooks (optional; see docs/Build Plan V2/Tools/reference-tracker-
# template.md's §8 "Live TODO / Next Steps Queue" -- identical behavior to
# call_implementation_agent.sh's own hooks, see that script's header for full rationale.
TODO_LOG="$REPO_ROOT/.codex-logs/.dispatch_todo_log.log"
echo "DISPATCH_STARTED $(date -u +%Y-%m-%dT%H:%M:%SZ) script=call_skill_authoring_agent.sh label=$LABEL target=\"$TARGET_DOC\" tracker=\"${DISPATCH_TRACKER_FILE:-}\" item=\"${DISPATCH_TODO_ITEM:-}\"" >> "$TODO_LOG"
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

# Non-interactive shells (via `ssh loom-vm 'cmd'`) skip ~/.bashrc entirely --
# resolve the toolchain PATH explicitly. Never substitute `bash -l`.
. "$HOME/.loom-env.sh"

# --- Validator preflight -------------------------------------------------
# The dispatched agent validates its own draft over HTTP and iterates until it
# comes back clean (codex-dispatch/INSTRUCTIONS.md, "On validation"). That only
# works if the server is actually up, and a silently-absent validator sends the
# agent back to guessing without ever saying so. Start one if needed, and fail
# loudly rather than dispatch a run that cannot check its own output.
VALIDATOR_URL="${LOOM_VALIDATOR_URL:-http://127.0.0.1:8787}"
if ! curl -fsS -m 5 "$VALIDATOR_URL/health" >/dev/null 2>&1; then
  echo "Validator not responding at $VALIDATOR_URL -- starting one..."
  (
    cd "$REPO_ROOT/app/packages/tooling/loom_ux_judges" \
      && setsid nohup dart run bin/validator_server.dart --port 8787 \
           > /tmp/loom_validator_server.log 2>&1 &
    disown
  ) || true
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
    sleep 5
    curl -fsS -m 5 "$VALIDATOR_URL/health" >/dev/null 2>&1 && break
  done
fi
if ! curl -fsS -m 5 "$VALIDATOR_URL/health" >/dev/null 2>&1; then
  echo "FATAL: validator still unreachable at $VALIDATOR_URL after 60s." >&2
  echo "       See /tmp/loom_validator_server.log. Refusing to dispatch a run" >&2
  echo "       that cannot validate its own output." >&2
  exit 69
fi
echo "Validator healthy at $VALIDATOR_URL"

set +e
npx --yes @openai/codex exec \
  "${PROFILE_ARGS[@]}" \
  --sandbox workspace-write \
  -c sandbox_workspace_write.network_access=true \
  -C "$SCRATCH_DIR" \
  --skip-git-repo-check \
  --ephemeral \
  --json \
  --output-last-message "$LAST_MESSAGE_FILE" \
  - < "$PROMPT_FILE" | tee "$JSON_LOG"
STATUS="${PIPESTATUS[0]}"
set -e

echo "============================================================================"
echo "codex exec exited with status $STATUS"

if [ -f "$LAST_MESSAGE_FILE" ]; then
  echo "Final answer captured: $LAST_MESSAGE_FILE ($(wc -l < "$LAST_MESSAGE_FILE") lines)"
else
  echo "WARNING: no final-answer file produced -- inspect $JSON_LOG directly."
fi

echo
echo "NEXT STEP (this script does not do this for you): review $LAST_MESSAGE_FILE,"
echo "run its JSON through the real validator from your OWN shell before trusting it, and only"
echo "turn it into a real docs/references/communities/*.jsonc file with the user's explicit"
echo "per-instance approval."

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) DISPATCH_FINISHED status=$STATUS" >> "$TODO_LOG"
echo "##################################################################"
echo "# ALSO: fold this dispatch's outcome into the TODO record.      #"
echo "##################################################################"
if [ -n "${DISPATCH_TRACKER_FILE:-}" ]; then
  echo "Update '$DISPATCH_TRACKER_FILE''s §8 Live TODO / Next Steps Queue and docs/Build Plan V2/TODO.md's"
  echo "rollup once you've reviewed the output above -- do this every time, even if nothing changes."
else
  echo "No DISPATCH_TRACKER_FILE was set -- decide whether docs/Build Plan V2/TODO.md needs a new entry"
  echo "for this dispatch's outcome."
fi

exit "$STATUS"
