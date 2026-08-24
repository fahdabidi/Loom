#!/bin/bash
# data/call_ux_judge_agent.sh
#
# Dispatches the UX Review judge to a Claude Code CLI agent on Sonnet.
#
# WHY CLAUDE AND NOT CODEX/DEEPSEEK: judging UX means LOOKING at the captured
# screenshots. The DeepSeek gateway is text-only and refuses image content
# outright ("unsupported content type: input_image"), which killed a capture
# run on 2026-08-23 the moment the agent tried to inspect a frame. Claude reads
# images, so the judge can do the one thing a UX judge exists to do.
#
# Sonnet by deliberate choice: this is high-volume, well-specified perceptual
# work over many screenshots, not open-ended design. Opus is reserved for the
# live verification agent, which has to drive a device and reason about failure.
#
# Usage:
#   bash data/call_ux_judge_agent.sh <prompt-file> [label]
#
# The judge is REVIEW-ONLY. It reads screenshots and evidence and writes its
# verdict; it must not edit application code to make a verdict pass. That is
# enforced by prompt and checked by the git guard below, not by sandboxing --
# so read its diff before trusting it, exactly as with any other dispatch.
set -euo pipefail

PROMPT_FILE="${1:?usage: call_ux_judge_agent.sh <prompt-file> [label]}"
LABEL="${2:-uxjudge-$(date +%Y%m%d-%H%M%S)}"
MODEL="${CLAUDE_UX_JUDGE_MODEL:-sonnet}"

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

LOG_DIR="$REPO_ROOT/.codex-logs/ux-judge/$LABEL"
mkdir -p "$LOG_DIR"
OUTPUT_CAPTURE="$LOG_DIR/output.log"

# Git integrity guard -- identical intent to call_implementation_agent.sh: a
# collapsed tracked-file count or a moved HEAD is a loud failure, because a
# review agent should never do either.
PRE_TRACKED_COUNT="$(cd "$REPO_ROOT" && git ls-files | wc -l)"
PRE_HEAD="$(cd "$REPO_ROOT" && git rev-parse HEAD)"

echo "=== Invoking UX Review Judge (Claude Code CLI) ==="
echo "Repo:        $REPO_ROOT"
echo "Prompt file: $PROMPT_FILE ($(wc -l < "$PROMPT_FILE") lines)"
echo "Model:       $MODEL"
echo "Label:       $LABEL"
echo "Log:         $OUTPUT_CAPTURE"
echo "Role:        REVIEW ONLY -- reads screenshots and evidence, writes a verdict"
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
if [ "$POST_TRACKED_COUNT" -lt "$PRE_TRACKED_COUNT" ] || [ "$POST_HEAD" != "$PRE_HEAD" ]; then
  echo "!!! GIT INTEGRITY ALERT !!!" >&2
  echo "  tracked files: $PRE_TRACKED_COUNT -> $POST_TRACKED_COUNT" >&2
  echo "  HEAD:          $PRE_HEAD -> $POST_HEAD" >&2
  echo "  A review agent must not delete tracked files or move HEAD." >&2
  exit 1
fi

DIRTY="$(cd "$REPO_ROOT" && git status --porcelain)"
if [ -n "$DIRTY" ]; then
  echo "WARNING: working tree left dirty after this run (visibility only):"
  echo "$DIRTY"
else
  echo "Working tree clean."
fi
exit "$STATUS"
