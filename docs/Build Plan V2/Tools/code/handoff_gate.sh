#!/bin/bash
# data/handoff_gate.sh
#
# Pre-validation gate: checks that the implementation-to-verification handoff
# for a given dispatch `<label>` is actually complete and clean BEFORE
# `flutter analyze`/the test suite runs. Built 2026-07-22 at explicit user
# request, after CALR.4g round 5 wasted three redundant dispatch rounds
# re-fixing an already-fixed file because it sat uncommitted (untracked, `??`)
# across multiple rounds -- `git diff` shows nothing for an untracked file's
# content changes no matter how many times it's edited, so nobody noticed the
# fix had already landed. See codex_dispatch_reliability memory, Failure 8,
# and the V3 tracker's §6 "Committed handoff, every time" rule (corrected the
# same day) for the full story.
#
# This script does not itself commit or clean up anything -- it only CHECKS
# and reports. The verification agent is still the one who runs
# `wsl_dispatch_tracker.sh cleanup <label>` and `git commit` themselves; this
# gate exists to catch it if either step was skipped or only partially done,
# rather than silently proceeding to verification on a dirty/incomplete
# handoff.
#
# Usage:
#   bash data/handoff_gate.sh <label>
#
# Exit 0 and prints "READY FOR VALIDATION" only if every check below passes.
# Exit 1 and prints exactly what's missing otherwise -- fix that first, then
# re-run this script, rather than proceeding to flutter analyze/test on a
# handoff this script flagged as incomplete.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 1

LABEL="${1:-}"
FAILURES=0

pass() { echo "  [OK]   $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }
info() { echo "  [INFO] $1"; }

echo "=== Handoff gate: label='${LABEL:-<none given>}' ==="

# 1. Dispatch completion (only checked if a label was given and its pidfile-era
#    marker exists; this repo's dispatches write a shared .last_dispatch.pid,
#    which only reflects the MOST RECENT dispatch -- so this check is a
#    same-turn convenience, not a durable per-label record).
if [ -f ".codex-logs/.last_dispatch.pid" ]; then
  LAST_PID="$(cat .codex-logs/.last_dispatch.pid 2>/dev/null || true)"
  if [ -n "$LAST_PID" ] && kill -0 "$LAST_PID" 2>/dev/null; then
    fail "The most recent dispatch (PID $LAST_PID) is still running -- wait for it to finish before validating."
  else
    pass "Most recent dispatch process has exited."
  fi
else
  info "No .codex-logs/.last_dispatch.pid found (no dispatch has run yet this session, or logs were cleared)."
fi

# 2. WSL session cleanup confirmed for this label.
if [ -n "$LABEL" ]; then
  TRACKER=".codex-logs/.dispatch_wsl_tracker.log"
  if [ -f "$TRACKER" ]; then
    LAST_EVENT_FOR_LABEL="$(grep " LABEL=$LABEL " "$TRACKER" | tail -1)"
    if [ -z "$LAST_EVENT_FOR_LABEL" ]; then
      fail "No wsl_dispatch_tracker.sh events found for label '$LABEL' -- did you run baseline/capture/cleanup for it?"
    elif echo "$LAST_EVENT_FOR_LABEL" | grep -q "EVENT=wsl_session_closed_confirmed"; then
      pass "WSL session cleanup confirmed closed for label '$LABEL'."
    else
      fail "Label '$LABEL's last tracker event is NOT a confirmed close: $LAST_EVENT_FOR_LABEL -- run 'bash data/wsl_dispatch_tracker.sh cleanup $LABEL'."
    fi
  else
    fail "No $TRACKER found at all -- WSL cleanup has never been run this session."
  fi
else
  info "No label given -- skipping per-dispatch WSL cleanup check."
fi

# 3. Git working tree is clean (everything from this round has been committed
#    already -- the corrected rule: commit BEFORE verifying, not after).
DIRTY="$(git status --short)"
if [ -z "$DIRTY" ]; then
  pass "Working tree is clean -- this round's edits are already committed."
else
  fail "Working tree is NOT clean -- commit these before running flutter analyze/tests:"
  echo "$DIRTY" | sed 's/^/         /'
fi

# 4. Tracked-file count sanity (catches the OneDrive git-index-corruption
#    failure mode: a collapsed tree still reports a bad `git status` as
#    "clean" if everything happens to already be committed in that collapsed
#    state, so this is a genuinely separate check, not redundant with #3).
TRACKED_COUNT="$(git ls-files | wc -l)"
if [ "$TRACKED_COUNT" -lt 100 ]; then
  fail "git ls-files reports only $TRACKED_COUNT tracked files -- expected thousands. Possible index corruption (see onedrive_git_corruption memory). STOP, do not proceed, investigate before validating anything."
else
  pass "Tracked-file count looks sane ($TRACKED_COUNT files)."
fi

# 5. HEAD is a real, resolvable commit.
HEAD_SHA="$(git rev-parse HEAD 2>/dev/null || true)"
if [ -n "$HEAD_SHA" ]; then
  pass "HEAD resolves cleanly: $HEAD_SHA"
else
  fail "git rev-parse HEAD failed -- repo may be in a broken state."
fi

echo "==================================================="
if [ "$FAILURES" -eq 0 ]; then
  echo "READY FOR VALIDATION -- all handoff checks passed."
  exit 0
else
  echo "NOT READY -- $FAILURES check(s) failed above. Fix them, then re-run this script before validating."
  exit 1
fi
