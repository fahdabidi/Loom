#!/bin/bash
# data/call_live_verification_agent.sh
#
# Dispatches the live walkthrough to a Claude Code CLI agent on Opus.
#
# WHY CLAUDE AND NOT CODEX/DEEPSEEK: driving the walkthrough means inspecting
# what actually rendered on the device. The DeepSeek gateway is text-only and
# refuses image content ("unsupported content type: input_image"), which killed
# a capture run on 2026-08-23 the moment the agent tried to inspect a frame.
#
# Opus by deliberate choice, unlike the Sonnet UX judge: this agent drives a
# real emulator, diagnoses why a workflow did not reach a state, and decides
# whether a failure is a product defect or a harness problem. That is
# open-ended reasoning under partial information, which is where the stronger
# model earns its cost. Judging captured frames against a fixed rubric is not.
#
# Usage:
#   bash data/call_live_verification_agent.sh <prompt-file> [label]
#
# THE DELIVERABLE IS A COMMITTED MANIFEST, not screenshots. `*.png` is
# gitignored (.gitignore:7), so every captured frame is a transient artifact of
# the run. Only the evidence manifest is durable. Two earlier runs captured
# real frames and banked nothing -- one restored its evidence instead of
# committing, the other aborted before writing a completed phase manifest --
# leaving the durably-proven count at zero despite real captures. A run that
# does not commit its manifest has proven nothing.
#
# This agent MAY commit its evidence manifest. The git guard below therefore
# permits HEAD to move, but still fails loudly if tracked files disappear.
set -euo pipefail

PROMPT_FILE="${1:?usage: call_live_verification_agent.sh <prompt-file> [label]}"
LABEL="${2:-liveverify-$(date +%Y%m%d-%H%M%S)}"
MODEL="${CLAUDE_LIVE_VERIFICATION_MODEL:-opus}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Toolchain env: the Linux VM has ~/.loom-env.sh; Windows (Git Bash) does not,
# so fall back to the repo-local data/loom-env.sh. One script body, either host.
if [ -f "$HOME/.loom-env.sh" ]; then
  . "$HOME/.loom-env.sh"
elif [ -f "$SCRIPT_DIR/loom-env.sh" ]; then
  . "$SCRIPT_DIR/loom-env.sh"
else
  echo "ERROR: no toolchain env found (~/.loom-env.sh or $SCRIPT_DIR/loom-env.sh)" >&2
  exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

# Same stable-prefix assembly as the Codex dispatches: invariant rules first,
# ticket last. Anthropic caches on prefix too, so this is not DeepSeek-specific.
DISPATCH_PREAMBLE_FILE="${CODEX_DISPATCH_PREAMBLE:-$REPO_ROOT/data/dispatch_preamble.md}"
if [ -f "$DISPATCH_PREAMBLE_FILE" ]; then
  PROMPT="$(cat "$DISPATCH_PREAMBLE_FILE")
$(cat "$PROMPT_FILE")"
else
  PROMPT="$(cat "$PROMPT_FILE")"
fi

LOG_DIR="$REPO_ROOT/.codex-logs/live-verification/$LABEL"
mkdir -p "$LOG_DIR"
OUTPUT_CAPTURE="$LOG_DIR/output.log"

# Git integrity guard -- identical intent to call_implementation_agent.sh: a
# collapsed tracked-file count or a moved HEAD is a loud failure, because a
# review agent should never do either.
PRE_TRACKED_COUNT="$(cd "$REPO_ROOT" && git ls-files | wc -l)"
PRE_HEAD="$(cd "$REPO_ROOT" && git rev-parse HEAD)"

echo "=== Invoking Live Verification Agent (Claude Code CLI) ==="
echo "Repo:        $REPO_ROOT"
echo "Prompt file: $PROMPT_FILE ($(wc -l < "$PROMPT_FILE") lines)"
echo "Model:       $MODEL"
echo "Label:       $LABEL"
echo "Log:         $OUTPUT_CAPTURE"
echo "Role:        LIVE WALKTHROUGH -- drives the emulator, captures evidence, banks the manifest"
echo "================================================================"

echo $$ > "$REPO_ROOT/.last_dispatch.pid"

set +e
claude -p "$PROMPT" \
  --model "$MODEL" \
  --add-dir "$REPO_ROOT" \
  --dangerously-skip-permissions \
  2>&1 | tee "$OUTPUT_CAPTURE"
STATUS="${PIPESTATUS[0]}"
set -e

echo "================================================================"
echo "claude exited with status $STATUS"

POST_TRACKED_COUNT="$(cd "$REPO_ROOT" && git ls-files | wc -l)"
POST_HEAD="$(cd "$REPO_ROOT" && git rev-parse HEAD)"
if [ "$POST_TRACKED_COUNT" -lt "$PRE_TRACKED_COUNT" ]; then
  echo "!!! GIT INTEGRITY ALERT !!!" >&2
  echo "  tracked files: $PRE_TRACKED_COUNT -> $POST_TRACKED_COUNT" >&2
  echo "  Capturing evidence never deletes tracked files." >&2
  exit 1
fi
if [ "$POST_HEAD" != "$PRE_HEAD" ]; then
  # Expected: banking the manifest is this agent's whole purpose.
  echo "HEAD moved (evidence banked): $PRE_HEAD -> $POST_HEAD"
  (cd "$REPO_ROOT" && git log --oneline "$PRE_HEAD..$POST_HEAD")
fi

DIRTY="$(cd "$REPO_ROOT" && git status --porcelain)"
if [ -n "$DIRTY" ]; then
  echo "WARNING: working tree left dirty after this run (visibility only):"
  echo "$DIRTY"
else
  echo "Working tree clean."
fi
exit "$STATUS"
