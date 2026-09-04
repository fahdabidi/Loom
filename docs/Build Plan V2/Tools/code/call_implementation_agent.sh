#!/bin/bash
# data/call_implementation_agent.sh
#
# Direct invocation of the Implementation Agent (Codex CLI, VirtualBox VM) from
# the Verification Agent's own session -- replaces the old mailbox+manually-
# resumed-session handoff. Adapted from the "Running an unattended
# Implementation/Verification agent loop" reference guide (2026-07-11),
# stripped of the Task Scheduler/overnight-nudge parts since this script is
# meant to be invoked directly, once per turn, not on a timer.
#
# Migrated off WSL2 onto a VirtualBox Ubuntu VM 2026-08-12 -- see
# docs/Build Plan V2/Tools/wsl-to-virtualbox-migration.md for the full
# migration record and rationale (vsock exhaustion, orphaned wslhost.exe
# processes, and OneDrive/v9fs git index corruption all stop applying once
# this runs on native ext4 with no cloud-sync driver underneath). This script
# now runs INSIDE the guest (~/Loom/data/), invoked from the host via
# `ssh loom-vm '. ~/.loom-env.sh && ...'`, not via `wsl.exe`.
#
# Usage:
#   bash data/call_implementation_agent.sh <path-to-prompt-file> [--fresh]
#
# Canonical dispatch-and-watch recipe (run each half from the verification
# agent's own shell, NOT from inside this script):
#   ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && \
#     setsid nohup bash data/call_implementation_agent.sh <ticket> --fresh \
#     < /dev/null > .codex-logs/<label>_dispatch.out.log 2>&1 & disown'
#   # ... then WRAP THIS IN A Monitor (persistent: true). Event-based waking is
#   # the only kind proven reliable here -- see loop.md section 4a: timers
#   # (ScheduleWakeup/cron) missed every single firing across two overnight
#   # stalls, while every Monitor fired promptly. Never poll, never sleep-loop.
#   ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && bash data/watch_dispatch_log.sh <label>'
#   # That script self-terminates and emits exactly one of:
#   #   codex exec exited with status <n>  -> normal completion
#   #   DISPATCH-DIED: ...                 -> process vanished, no completion
#   #                                         line (killed/crashed/OOM)
#   #   DISPATCH-SIGNAL: <line>            -> usage limit / panic / fatal seen
#   #                                         mid-run (informational, continues)
#   # Do NOT filter the Monitor down to only the success line: a dispatch that
#   # dies silently must still wake you. Silence must never be the signal.
#   # ... once the dispatch has genuinely completed (watcher fired on
#   # "codex exec exited with status"), commit the round's real edits (once
#   # confirmed present via `git status`/`git diff`) immediately -- not
#   # deferred until independent verification passes. See
#   # codex_dispatch_reliability memory, Failure 8: holding a brand-new
#   # (untracked, `??`) file uncommitted across multiple fix-rounds means
#   # `git diff` shows NOTHING for its content changes no matter how many
#   # times it's edited, since `git diff` only ever compares tracked/staged
#   # content against HEAD -- this cost three redundant dispatch rounds on
#   # CALR.4g round 5, re-fixing a file that had already been fixed.
#   # Committing each round immediately keeps the file tracked from then on,
#   # so every later `git diff` is trustworthy.
#   ssh loom-vm 'cd ~/Loom && bash data/handoff_gate.sh'   # verifies all of
#   # the above before you proceed -- checks the dispatch actually finished,
#   # the working tree is clean (already committed), and the tracked-file
#   # count looks sane. Exits nonzero with exactly what's missing if not truly
#   # ready; only run flutter analyze/the test suite after this prints
#   # "READY FOR VALIDATION".
# This script writes its own PID to .codex-logs/.last_dispatch.pid on every
# run (kept for `kill -0` checks if ever needed) -- do not substitute a
# `pgrep -f "codex exec"`-style check; see the comment at the `mkdir -p
# .codex-logs` line below for why that has failed twice in practice.
#
# By default this resumes the most recent Codex session for this repo
# (`resume --last`), so context/continuity builds across calls the same way
# it would in the guide's overnight loop. Pass --fresh to start a brand-new
# session instead (e.g. the very first call, or after a long gap where
# resuming stale context would do more harm than good).
#
# Requires: `trust_level = "trusted"` for this repo path already set in
# ~/.codex/config.toml (guest side, `/home/fahd/Loom`) -- done once, not by
# this script.
#
# Model: defaults to GPT-5.6-Luna at XHIGH reasoning effort WITH FAST MODE
# (switched 2026-09-03 per user direction). Config:
# ~/.codex/gpt5_6_luna_xhigh.config.toml (model = "gpt-5.6-luna",
# model_reasoning_effort = "xhigh", model_verbosity = "medium",
# model_context_window = 272000, service_tier = "fast" -- the CLI key for
# Codex "Speed: Fast", ~1.5x speed for more usage) -- a first-party Codex/OpenAI
# model, no gateway dependency, no preflight health check needed. Smoke-tested
# 2026-09-03 (`codex exec -p gpt5_6_luna_xhigh --sandbox read-only "Reply with
# exactly: PROFILE_OK" < /dev/null` -> banner showed model: gpt-5.6-luna,
# reasoning effort: xhigh; correct reply; exit 0) before being made the default.
#
# Model history, for reference (all still fully set up and usable via
# CODEX_IMPLEMENTATION_PROFILE=<name>, none removed):
#   - GPT-5.6-Luna @ xhigh + fast ("gpt5_6_luna_xhigh", service_tier = "fast")
#     -- the current default as of 2026-09-03, per user direction.
#   - GPT-5.6-Terra @ xhigh + fast ("gpt5_6_terra_xhigh") -- the default from
#     2026-08-07 through 2026-09-03 (also carried service_tier = "fast").
#   - GPT-5.3-Codex-Spark @ xhigh ("gpt5_3_spark_xhigh") -- default 2026-08-07.
#   - GPT-5.6-Luna @ max ("gpt5_6_luna_max") -- the default immediately prior,
#     2026-07-31 through 2026-08-07.
#   - GPT-5.6-Terra @ medium -- the original default, and briefly the default
#     again from 2026-07-21.
#   - DeepSeek V4 Pro @ high -- tried as the default 2026-07-20/21, but only
#     ever proven to work on trivial one-line prompts (~5s); on an actual
#     ticket-length prompt (git-safety preamble + real instructions) it never
#     completed after 10+ minutes and had to be killed. Never reverted to as
#     default.
#   - DeepSeek V4 Pro @ medium -- the fix for the above (the identical stuck
#     ticket completed correctly in ~25s under medium) -- was the default for
#     part of 2026-07-21 before switching back to GPT-5.6-Terra.
#   - DeepSeek V4 Pro @ xhigh, DeepSeek V4 Flash @ high -- available, never
#     defaulted to, untested for ticket-length prompts.
#
# DeepSeek setup, kept intact for a future switch back (config files,
# gateway, key all still in place -- nothing was torn down). This block is
# INERT unless a deepseek_* profile is revived:
#   - served through a local Codex<->DeepSeek gateway
#     (C:\Users\fahd_\OneDrive\Documents\Codex-DeepSeek-V4-Gateway-1.0.0-windows,
#     a Windows process) -- MUST be running (`.\start-gateway.cmd` from that
#     folder, or `.\scripts\Start-Gateway.ps1 -Background`) before dispatching
#     with any deepseek_* profile, or its preflight health check below fails
#     fast. Confirmed 2026-07-21: this gateway process does not survive
#     indefinitely / can be killed by unrelated system activity -- check it's
#     actually still running (`Get-Process -Id (Get-Content .runtime\
#     gateway.pid)`) before assuming a past "started successfully" still
#     holds hours later.
#   - the gateway runs on the Windows side, bound to 0.0.0.0 (not the default
#     127.0.0.1) with GATEWAY_API_KEY set in its .env. On the VM, the gateway
#     is reachable at the HOST's LAN IP (not a WSL default-route IP -- that
#     address was WSL-specific and is meaningless from the guest), e.g.
#     http://192.168.50.x:8787/health, plus a Windows Firewall rule allowing
#     8787 from the LAN (not just from WSL).
#   - a Windows Firewall inbound-allow rule for TCP 8787 (the box's existing
#     "Node.js JavaScript Runtime" rules include a conflicting Block that
#     otherwise wins).
#   - the shared gateway token saved at ~/.deepseek_gateway_key (guest side,
#     chmod 600, outside the repo -- never commit this) -- matches
#     GATEWAY_API_KEY in the gateway's own .env.
#   - ~/.codex/deepseek_v4_pro_medium.config.toml / deepseek_v4_pro_high.config.toml /
#     deepseek_v4_pro.config.toml (xhigh) / deepseek_v4_flash.config.toml
#     (lighter model, high) plus a [model_providers.deepseek_v4_gateway]
#     block (base_url pointed at the host's LAN IP; env_key =
#     "DEEPSEEK_GATEWAY_KEY") in the main config.toml.
#   - BUG FIXED 2026-07-20/21 in that gateway's own scripts\Start-Gateway.ps1:
#     its Wait-ForGateway health-check polled /health with no Authorization
#     header, but /health requires the same Bearer GATEWAY_API_KEY real
#     clients use -- every poll was silently rejected with an auth error,
#     so startup always timed out and killed the process even when the
#     gateway was actually healthy the whole time. Now sends the header
#     (read from .env via the script's existing Get-LocalSetting helper).
#
# To switch back to DeepSeek V4 Pro medium (or any other profile) for a
# single dispatch without changing this file's default:
#   CODEX_IMPLEMENTATION_PROFILE=deepseek_v4_pro_medium bash data/call_implementation_agent.sh <ticket> [--fresh]
# Override with CODEX_IMPLEMENTATION_PROFILE="" to fall back to Codex's own
# built-in default model (e.g. for a quick one-off without any profile).
#
# HISTORICAL NOTE (resolved by this migration, kept for context): under WSL2,
# `codex exec` intermittently failed its very first shell command with
# `WSL ERROR: UtilBindVsockAnyPort:NNN: socket failed 1` and exited 0 having
# done nothing -- a hard, non-tunable WSL2 vsock connection-count cap
# (openai/codex#8322, microsoft/WSL#40650). This does not apply on a
# VirtualBox VM reached over SSH; the detector and its `wsl.exe --shutdown`
# mitigation have been removed from this script. See
# docs/Build Plan V2/Tools/dispatch-pipeline-tools.md for the full incident
# history if ever relevant again in a different environment.

set -euo pipefail

PROMPT_FILE="${1:?usage: call_implementation_agent.sh <prompt-file> [--fresh]}"
MODE="${2:-}"
SANDBOX_MODE="${CODEX_IMPLEMENTATION_SANDBOX:-workspace-write}"
PROFILE="${CODEX_IMPLEMENTATION_PROFILE-gpt5_6_luna_xhigh}"
PROFILE_ARGS=()
if [ -n "$PROFILE" ]; then
  PROFILE_ARGS=(-p "$PROFILE")
fi

GATEWAY_KEY_FILE="$HOME/.deepseek_gateway_key"
GATEWAY_HEALTH_URL="${CODEX_GATEWAY_HEALTH_URL:-http://127.0.0.1:8791/health}"
if [[ "$PROFILE" == deepseek_* ]]; then
  # The gateway now runs ON THIS VM, bound to loopback (~/deepseek-gateway).
  # src/config.mjs only requires GATEWAY_API_KEY when the bind host is NOT
  # loopback, so a bridge token is optional here. The WSL-era arrangement
  # needed the token, a Windows firewall rule for 8787, AND a host LAN IP that
  # went stale whenever DHCP moved -- it broke on all three. If a token file
  # does exist we still send it, so a remote gateway keeps working unchanged.
  CURL_AUTH=()
  if [ -f "$GATEWAY_KEY_FILE" ]; then
    DEEPSEEK_GATEWAY_KEY="$(cat "$GATEWAY_KEY_FILE")"
    export DEEPSEEK_GATEWAY_KEY
    CURL_AUTH=(-H "Authorization: Bearer $DEEPSEEK_GATEWAY_KEY")
  fi
  HEALTH_STATUS="$(curl -s -m 5 -o /dev/null -w '%{http_code}' \
    "${CURL_AUTH[@]}" "$GATEWAY_HEALTH_URL" || true)"
  if [ "$HEALTH_STATUS" != "200" ]; then
    echo "ERROR: DeepSeek gateway not reachable/healthy at $GATEWAY_HEALTH_URL (HTTP $HEALTH_STATUS)." >&2
    echo "       Start it:  nohup ~/deepseek-gateway/start.sh > /tmp/ds_gateway.log 2>&1 &" >&2
    echo "       It requires ~/.deepseek_api_key (chmod 600) to exist." >&2
    echo "       To bypass and use Codex's default model instead: CODEX_IMPLEMENTATION_PROFILE=\"\"" >&2
    exit 1
  fi
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Non-interactive shells (this one included, when invoked via `ssh loom-vm
# 'cmd'`) skip ~/.bashrc entirely (Ubuntu's stock .bashrc returns early for
# non-interactive shells) -- resolve the toolchain PATH explicitly via the
# guest's own env file rather than assume it's already on PATH. Do not
# substitute `bash -l`: a login shell reads .profile, whose PATH ordering
# differs and omits the Android SDK.
. "$HOME/.loom-env.sh"

# --- Prompt assembly: stable prefix first, ticket last ------------------
# DeepSeek caches on the PREFIX of a request -- there is no session id to
# reuse the way OpenAI models do. A request whose leading tokens match an
# earlier request bills those tokens at a fraction of the input rate, and the
# gateway logs the hit as `cached_tokens` in /tmp/ds_gateway.log.
#
# So the invariant standing rules lead every dispatch, byte-identical, and the
# ticket -- the part that differs every time -- trails. Before this, PROMPT was
# the ticket alone, so consecutive dispatches shared no prefix at all and the
# cache could never hit. Do NOT interpolate anything variable (dates, paths,
# ticket names) into the preamble: one changed byte near the front discards the
# cache for everything after it.
DISPATCH_PREAMBLE_FILE="${CODEX_DISPATCH_PREAMBLE:-$REPO_ROOT/data/dispatch_preamble.md}"
if [ -f "$DISPATCH_PREAMBLE_FILE" ]; then
  PROMPT="$(cat "$DISPATCH_PREAMBLE_FILE")
$(cat "$PROMPT_FILE")"
else
  PROMPT="$(cat "$PROMPT_FILE")"
fi

# --- Git integrity guard -----------------------------------------------
# Snapshot the tracked-file count and HEAD now, and hard-fail loudly after
# the run if it collapsed, rather than relying on the dirty-tree check below
# to notice -- a bad commit that matches a bad working tree still reports
# "clean" via plain `git status`. Not a git.exe/native-git distinction here:
# the guest's own git on native ext4 has no index-corruption failure mode to
# guard against, but this collapsed-tree check is still cheap, general
# insurance against any bad automated git surgery, not just an OneDrive-
# specific one, so it stays.
PRE_TRACKED_COUNT="$(git ls-files | wc -l)"
PRE_HEAD="$(git rev-parse HEAD)"

echo "=== Invoking Implementation Agent (codex exec) ==="
echo "Repo: $REPO_ROOT"
echo "Prompt file: $PROMPT_FILE ($(wc -l < "$PROMPT_FILE") lines)"
echo "Mode: $([ "$MODE" = "--fresh" ] && echo "fresh session" || echo "resume --last")"
echo "Sandbox: $SANDBOX_MODE"
echo "Profile: ${PROFILE:-<none -- Codex default model>}"
echo "===================================================="

cd "$REPO_ROOT"

# --- TODO-tracking hooks (optional; see docs/Build Plan V2/Tools/reference-tracker-
# template.md's §8 "Live TODO / Next Steps Queue" and reference-ticket-template.md's
# "## Proposed next steps" -- this only logs and reminds, it never writes tracker
# content itself; folding a dispatch's outcome into a tracker is always a manual,
# orchestrator-owned step, done during independent verification, not automated here.
mkdir -p "$REPO_ROOT/.codex-logs"
TODO_LOG="$REPO_ROOT/.codex-logs/.dispatch_todo_log.log"
echo "DISPATCH_STARTED $(date -u +%Y-%m-%dT%H:%M:%SZ) script=call_implementation_agent.sh ticket=\"$PROMPT_FILE\" tracker=\"${DISPATCH_TRACKER_FILE:-}\" item=\"${DISPATCH_TODO_ITEM:-}\"" >> "$TODO_LOG"
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

# Record this script's OWN pid so a caller that backgrounds this whole script
# (setsid nohup bash call_implementation_agent.sh ... & disown) has a
# reliable, repeatable way to detect completion later. DO NOT poll it in a
# sleep loop -- watch_dispatch_log.sh reads this file and turns process death
# into an event (DISPATCH-DIED), so a Monitor wrapping that script covers both
# normal completion and abnormal death without a single poll. The old
# `while kill -0 "$(cat .codex-logs/.last_dispatch.pid)"; do sleep 5; done`
# recipe is retired: it burned a turn per poll and reported nothing about
# *why* a dispatch ended.
# The pid file also replaces fragile pgrep-by-command-substring checks (e.g. `pgrep -f
# "codex exec"`), which have twice produced wrong answers in practice: an
# unanchored pattern matches the wrapper shell command's own text (it
# contains "codex exec" as a literal substring of the script being run,
# so the wait loop never sees "not running" and spins forever), while an
# anchored `^codex exec` pattern misses the real process entirely, since
# codex is actually launched via an `npm exec @openai/codex exec ...`
# wrapper whose child binary lives at a versioned
# `.../codex-linux-x64/vendor/.../bin/codex` path, not a literal `codex exec`
# argv[0]. A PID captured directly from this script's own `$$` has none of
# that ambiguity -- it is exactly the process the caller backgrounded, full
# stop. Kept as a *fixed* filename (not per-label) because this workflow only
# ever runs one dispatch at a time; a second dispatch legitimately overwrites
# it.
mkdir -p .codex-logs
echo "$$" > .codex-logs/.last_dispatch.pid

# Dart/Flutter write to these two cache dirs (package cache, tool config/cache)
# outside the repo root when running `pub get`/`flutter analyze`/`flutter test`.
# Without granting them explicitly, --sandbox workspace-write makes those
# commands fail with a read-only-filesystem error -- confirmed 2026-07-15 when
# an implementation-agent run reported it "could not execute flutter tools due
# to a read-only filesystem" and skipped its own verification, shipping code
# that didn't even compile (import_directive_after_part_directive). Granting
# these closes that excuse; an agent that still skips verification after this
# has no legitimate reason to.
PUB_CACHE_DIR="${PUB_CACHE:-$HOME/.pub-cache}"
FLUTTER_CONFIG_DIR="$HOME/.config/flutter"

# The Flutter SDK itself must be writable too:  runs
# update_engine_version.sh, which writes bin/cache/engine.stamp before any test
# starts. Without this the run dies with "engine.stamp: Read-only file system".
FLUTTER_BIN="$(command -v flutter || true)"
if [ -n "$FLUTTER_BIN" ]; then
  FLUTTER_SDK_DIR="$(dirname "$(dirname "$(readlink -f "$FLUTTER_BIN")")")"
else
  FLUTTER_SDK_DIR="$HOME/flutter"
fi

# flutter_tester binds a localhost control socket per test file. Under a
# default workspace-write sandbox that bind returns EPERM, so EVERY Flutter
# widget suite fails to start -- not a test failure, a harness failure, and one
# that reads like 54 real regressions in the log. Verified 2026-08-21: with this
# enabled plus FLUTTER_SDK_DIR granted, a real widget suite runs to
# "All tests passed!" in-sandbox. Before this, agents could not verify their own
# widget-test work at all and had to predict results, which they got wrong.
CODEX_SANDBOX_NETWORK_CONFIG="sandbox_workspace_write.network_access=true"

# Captured to a side file (via `tee`) so a transcript survives for post-
# mortems without losing the live streaming to stdout that callers tail for
# progress. `${PIPESTATUS[0]}` (not `$?`, which would be tee's exit status)
# preserves codex's own real exit code through the pipe.
CODEX_OUTPUT_CAPTURE="$(mktemp)"
# Disabled around the pipeline itself: with `set -e -o pipefail` active, a
# non-zero exit from EITHER half of `codex exec | tee` would abort the script
# right here, before STATUS is even captured -- silently skipping the git-
# integrity guard below exactly when it matters most.
set +e
if [ "$MODE" = "--fresh" ]; then
  npx --yes @openai/codex exec \
    "${PROFILE_ARGS[@]}" \
    --sandbox "$SANDBOX_MODE" \
    --add-dir "$REPO_ROOT/.git" \
    --add-dir "$PUB_CACHE_DIR" \
    --add-dir "$FLUTTER_CONFIG_DIR" \
    --add-dir "$FLUTTER_SDK_DIR" \
    -c "$CODEX_SANDBOX_NETWORK_CONFIG" \
    "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
else
  npx --yes @openai/codex exec \
    "${PROFILE_ARGS[@]}" \
    --sandbox "$SANDBOX_MODE" \
    --add-dir "$REPO_ROOT/.git" \
    --add-dir "$PUB_CACHE_DIR" \
    --add-dir "$FLUTTER_CONFIG_DIR" \
    --add-dir "$FLUTTER_SDK_DIR" \
    -c "$CODEX_SANDBOX_NETWORK_CONFIG" \
    resume --last "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
fi
STATUS="${PIPESTATUS[0]}"
set -e

echo "===================================================="
echo "codex exec exited with status $STATUS"

rm -f "$CODEX_OUTPUT_CAPTURE"

DIRTY="$(git status --porcelain)"
if [ -n "$DIRTY" ]; then
  echo "WARNING: working tree left dirty after this run (visibility only, not auto-fixing):"
  echo "$DIRTY"
else
  echo "Working tree clean."
fi

# --- Git integrity guard (post-run check) -------------------------------
# See the matching comment above PRE_TRACKED_COUNT. A HEAD that moved AND
# lost the vast majority of its tracked files is not a normal outcome of any
# legitimate ticket -- it means the tracked tree was collapsed (accidentally
# or via improvised git surgery) and then committed over. This is separate
# from, and more serious than, the plain dirty-tree warning above: a
# collapsed-and-recommitted tree reports CLEAN, so the check above alone
# would miss it silently.
POST_TRACKED_COUNT="$(git ls-files | wc -l)"
POST_HEAD="$(git rev-parse HEAD)"
if [ "$POST_HEAD" != "$PRE_HEAD" ] && [ "$PRE_TRACKED_COUNT" -gt 0 ]; then
  DROP_PCT=$(( (PRE_TRACKED_COUNT - POST_TRACKED_COUNT) * 100 / PRE_TRACKED_COUNT ))
  if [ "$DROP_PCT" -ge 20 ]; then
    echo "##################################################################"
    echo "# GIT INTEGRITY ALERT -- tracked file count collapsed this run.  #"
    echo "##################################################################"
    echo "Before: $PRE_TRACKED_COUNT files tracked at $PRE_HEAD"
    echo "After:  $POST_TRACKED_COUNT files tracked at $POST_HEAD  (-$DROP_PCT%)"
    echo "Do NOT trust this run's commit(s) as-is. Before doing anything else:"
    echo "  git log --oneline -5"
    echo "  git diff --stat $PRE_HEAD $POST_HEAD"
    echo "Identify the last commit whose tree size is consistent with"
    echo "$PRE_TRACKED_COUNT files, then reset main to it (mixed reset only,"
    echo "never --hard, so any genuinely new uncommitted work is preserved):"
    echo "  git reset <last-good-commit>"
  fi
fi

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) DISPATCH_FINISHED status=$STATUS" >> "$TODO_LOG"
echo "##################################################################"
echo "# NEXT STEP: fold this dispatch's outcome into the TODO record. #"
echo "##################################################################"
if [ -n "${DISPATCH_TRACKER_FILE:-}" ]; then
  echo "Review the agent's STATUS.md '## Proposed next steps' against what you actually verified, then"
  echo "update '$DISPATCH_TRACKER_FILE''s §8 Live TODO / Next Steps Queue and docs/Build Plan V2/TODO.md's"
  echo "rollup accordingly. Do this every time, even when nothing needs to change."
else
  echo "No DISPATCH_TRACKER_FILE was set -- decide whether docs/Build Plan V2/TODO.md needs a new entry"
  echo "for this dispatch's outcome."
fi

exit "$STATUS"
