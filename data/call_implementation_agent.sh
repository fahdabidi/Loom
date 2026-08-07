#!/bin/bash
# data/call_implementation_agent.sh
#
# Direct invocation of the Implementation Agent (Codex CLI, WSL) from the
# Verification Agent's own session -- replaces the old mailbox+manually-
# resumed-session handoff. Adapted from the "Running an unattended
# Implementation/Verification agent loop" reference guide (2026-07-11),
# stripped of the Task Scheduler/overnight-nudge parts since this script is
# meant to be invoked directly, once per turn, not on a timer.
#
# Usage:
#   bash data/call_implementation_agent.sh <path-to-prompt-file> [--fresh]
#
# Canonical dispatch-and-watch recipe (run each half from the verification
# agent's own shell, NOT from inside this script):
#   bash data/wsl_dispatch_tracker.sh baseline <label>
#   setsid nohup bash data/call_implementation_agent.sh <ticket> --fresh \
#     < /dev/null > .codex-logs/<label>_dispatch.out.log 2>&1 & disown
#   sleep 3   # let the dispatch's own WSL session actually establish first
#   bash data/wsl_dispatch_tracker.sh capture <label>
#   # ... then attach ONE Monitor to the log via watch_dispatch_log.sh, NOT a
#   # raw `tail -F | grep` -- that old pattern never exited on its own (grep
#   # had no -m1, since a vsock alert mid-run must NOT end the watch, only
#   # genuine completion should) and leaked a live wsl.exe/wslhost.exe session
#   # for up to the full 30-minute Monitor timeout every time it matched.
#   # Found 2026-07-22 after CALR.5a burned 4 consecutive vsock-blocked
#   # rounds: one leaked Monitor pipeline alone accounted for most of that
#   # session's live wsl.exe count. watch_dispatch_log.sh emits the same
#   # vsock-alert/completion signals but kills its own `tail -F` and exits
#   # itself a few seconds after the real completion line, so no separate
#   # TaskStop call is needed and nothing lingers:
#   wsl.exe -e bash -lc 'cd "<repo>" && bash data/watch_dispatch_log.sh <label>'
#   # ... once the dispatch has genuinely completed (Monitor fired on
#   # "codex exec exited with status", not just a vsock alert mid-run), do
#   # BOTH of the following as one paired step (either order), BEFORE running
#   # `flutter analyze`/the test suite, not after:
#   bash data/wsl_dispatch_tracker.sh cleanup <label>
#   # ... AND commit the round's real edits (once confirmed present via
#   # `git status`/`git diff`) immediately, right alongside cleanup -- not
#   # deferred until independent verification passes. Only after BOTH commit
#   # and cleanup are done does independent verification start. See
#   # codex_dispatch_reliability memory, Failure 8: holding a brand-new
#   # (untracked, `??`) file uncommitted across multiple fix-rounds means
#   # `git diff` shows NOTHING for its content changes no matter how many
#   # times it's edited, since `git diff` only ever compares tracked/staged
#   # content against HEAD -- this cost three redundant dispatch rounds on
#   # CALR.4g round 5, re-fixing a file that had already been fixed.
#   # Committing each round immediately keeps the file tracked from then on,
#   # so every later `git diff` is trustworthy.
#   bash data/handoff_gate.sh <label>   # verifies all of the above before
#   # you proceed -- checks the dispatch actually finished, WSL cleanup is
#   # confirmed closed for this label, the working tree is clean (already
#   # committed), and the tracked-file count looks sane (OneDrive corruption
#   # check). Exits nonzero with exactly what's missing if not truly ready;
#   # only run flutter analyze/the test suite after this prints "READY FOR
#   # VALIDATION".
# This script writes its own PID to .codex-logs/.last_dispatch.pid on every
# run (kept for `kill -0` checks if ever needed) -- do not substitute a
# `pgrep -f "codex exec"`-style check; see the comment at the `mkdir -p
# .codex-logs` line below for why that has failed twice in practice.
#
# `wsl_dispatch_tracker.sh`'s `cleanup` step is the proactive counterpart to
# the reactive `wsl.exe --shutdown` mitigation used after repeated vsock
# blocks: it diffs the wsl.exe/wslhost.exe process set before vs. after this
# specific dispatch to identify exactly which new processes it caused (never
# a single PID followed through the launcher chain -- the launcher itself
# exits in seconds on its own and isn't what lingers), kills any that are
# still alive once the dispatch has finished, and RE-VERIFIES via another
# process-set check that they are actually gone before logging the session
# as closed in `.codex-logs/.dispatch_wsl_tracker.log` -- never assume a kill
# succeeded without confirming it. Never targets `wslservice.exe` (the
# persistent Windows-side management service) or `vmmemWSL` (the shared VM
# hosting ALL concurrent WSL activity, including any other agentic session
# on this machine) -- both are explicitly excluded, killing either would take
# down far more than just this one dispatch.
#
# Session-wide WSL concurrency budget (user-requested, 2026-07-22): this
# dispatch = 1 session, the Monitor watch above = 1 session, and the
# verification agent's OWN ad-hoc wsl.exe calls (status checks, log reads,
# git commands) should be routed through `data/wsl_slot.sh` to cap them at 2
# concurrent -- e.g. `bash data/wsl_slot.sh "wsl.exe -e bash -lc '...'"` --
# keeping total concurrent WSL sessions across all categories bounded (<=4)
# instead of growing unboundedly, which is itself a contributor to vsock
# exhaustion (see the memory note this script's own history is tracked in:
# codex_dispatch_reliability, Failure 6).
#
# By default this resumes the most recent Codex session for this repo
# (`resume --last`), so context/continuity builds across calls the same way
# it would in the guide's overnight loop. Pass --fresh to start a brand-new
# session instead (e.g. the very first call, or after a long gap where
# resuming stale context would do more harm than good).
#
# Requires: `trust_level = "trusted"` for this repo path already set in
# ~/.codex/config.toml (WSL side) -- done once, not by this script.
#
# Model: defaults to GPT-5.3-Codex-Spark at XHIGH reasoning effort (switched
# 2026-08-07 per user direction). Config: ~/.codex/gpt5_3_spark_xhigh.config.toml
# (model = "gpt-5.3-codex-spark", model_reasoning_effort = "xhigh",
# model_verbosity = "medium", model_context_window = 272000) -- a first-party
# Codex/OpenAI model, no gateway dependency, no preflight health check needed.
# Smoke-tested 2026-08-07 (`codex exec -p gpt5_3_spark_xhigh --sandbox
# read-only "Reply with exactly: PROFILE_OK"` -> correct reply, exit 0)
# before being made the default -- not yet proven on a real ticket-length
# dispatch.
#
# Model history, for reference (all still fully set up and usable via
# CODEX_IMPLEMENTATION_PROFILE=<name>, none removed):
#   - GPT-5.3-Codex-Spark @ xhigh -- the current default as of 2026-08-07.
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
# gateway, WSL key all still in place -- nothing was torn down):
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
#     127.0.0.1) with GATEWAY_API_KEY set in its .env -- WSL2 here is
#     NAT-mode, not mirrored, so `localhost` does NOT bridge Windows<->WSL2; a
#     loopback-only bind is unreachable from WSL no matter what.
#   - a Windows Firewall inbound-allow rule for TCP 8787 (the box's existing
#     "Node.js JavaScript Runtime" rules include a conflicting Block that
#     otherwise wins).
#   - the shared gateway token saved at ~/.deepseek_gateway_key (WSL side,
#     chmod 600, outside the repo -- never commit this) -- matches
#     GATEWAY_API_KEY in the gateway's own .env.
#   - ~/.codex/deepseek_v4_pro_medium.config.toml / deepseek_v4_pro_high.config.toml /
#     deepseek_v4_pro.config.toml (xhigh) / deepseek_v4_flash.config.toml
#     (lighter model, high) plus a [model_providers.deepseek_v4_gateway]
#     block (base_url pointed at the WSL default-route IP, e.g. 172.31.16.1,
#     not 127.0.0.1; env_key = "DEEPSEEK_GATEWAY_KEY") in the main
#     config.toml.
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
# KNOWN ISSUE (root-caused 2026-07-21, real, cited, not a local misconfiguration):
# codex exec inside this WSL distro intermittently fails its very first shell command with
# `WSL (N - ) ERROR: UtilBindVsockAnyPort:NNN: socket failed 1` and then exits 0 having done
# nothing (no file changes, no commit) -- indistinguishable from success in exit code alone,
# only visible by reading its own transcript. This is an EXACT match for a still-open upstream
# bug against this exact tool: https://github.com/openai/codex/issues/8322. The underlying WSL2
# mechanism is documented separately: each WSL "session" (roughly, each fresh wsl.exe/interop
# invocation chain) consumes ~9 vsock connections (7 for a Relay process + 2 for SessionLeader),
# WSL2's own relay enforces a hard, NOT-user-tunable cap on total vsock connections (confirmed by
# WSL maintainers -- no .wslconfig key, no kernel module parameter, nothing in the Windows
# registry), and heavy/sustained concurrent WSL usage exhausts it, causing new session attempts to
# time out: https://github.com/microsoft/WSL/issues/40650. A long verification session like this
# one (many `wsl.exe -e bash -lc` calls for dispatch + polling + independent test/analyze runs,
# often overlapping) is exactly the usage pattern that triggers it -- confirmed directly in this
# repo's own environment: 11 wsl.exe/wslhost.exe processes were still alive and growing after
# several hours of a single session, several clearly orphaned (5+ hours old). Ruled out as the
# cause: systemd's `RestrictAddressFamilies` (a different, unrelated trigger for the same error
# message, reported elsewhere) -- confirmed absent from anything in this invocation path, since
# `codex exec` here runs as a plain foreground/background script, never as a systemd unit.
#
# No permanent fix exists upstream as of this writing. Practical mitigation, evidenced but
# partial (reduces, does not eliminate, the stale wsl.exe/wslhost.exe process count in this
# environment -- something else here re-establishes a session within seconds): run
# `wsl.exe --shutdown` from PowerShell/cmd (NOT from inside this script -- it would kill the very
# WSL session running the dispatch) between ticket phases, or after two consecutive vsock-blocked
# rounds, before retrying. This has zero effect on committed work (nothing persistent lives only
# in the WSL VM's memory) -- it only resets the relay/session state. The retry-until-it-lands
# pattern already used throughout this cycle (a blocked round makes zero file changes and is
# always safe to just retry) remains the correct default; reach for `wsl --shutdown` when retries
# alone stop working.

set -euo pipefail

PROMPT_FILE="${1:?usage: call_implementation_agent.sh <prompt-file> [--fresh]}"
MODE="${2:-}"
SANDBOX_MODE="${CODEX_IMPLEMENTATION_SANDBOX:-workspace-write}"
PROFILE="${CODEX_IMPLEMENTATION_PROFILE-gpt5_3_spark_xhigh}"
PROFILE_ARGS=()
if [ -n "$PROFILE" ]; then
  PROFILE_ARGS=(-p "$PROFILE")
fi

GATEWAY_KEY_FILE="$HOME/.deepseek_gateway_key"
GATEWAY_HEALTH_URL="${CODEX_GATEWAY_HEALTH_URL:-http://172.31.16.1:8787/health}"
if [[ "$PROFILE" == deepseek_* ]]; then
  if [ ! -f "$GATEWAY_KEY_FILE" ]; then
    echo "ERROR: profile '$PROFILE' selected but $GATEWAY_KEY_FILE is missing." >&2
    echo "       (the shared WSL<->gateway bridge token; not the DeepSeek API key itself)" >&2
    exit 1
  fi
  DEEPSEEK_GATEWAY_KEY="$(cat "$GATEWAY_KEY_FILE")"
  export DEEPSEEK_GATEWAY_KEY
  HEALTH_STATUS="$(curl -s -m 5 -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer $DEEPSEEK_GATEWAY_KEY" "$GATEWAY_HEALTH_URL" || true)"
  if [ "$HEALTH_STATUS" != "200" ]; then
    echo "ERROR: DeepSeek gateway not reachable/healthy at $GATEWAY_HEALTH_URL (HTTP $HEALTH_STATUS)." >&2
    echo "       Check: gateway running on Windows (Start-Gateway.ps1), bound to 0.0.0.0," >&2
    echo "       firewall rule for 8787 still present, and the WSL default-route IP hasn't" >&2
    echo "       changed (ip route show | grep default)." >&2
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

# Non-login shells (this one included, when invoked via `wsl bash -lc`) don't
# always have nvm's node on PATH -- resolve it explicitly rather than assume.
NVM_NODE_BIN=""
if [ -d "$HOME/.nvm/versions/node" ]; then
  NVM_NODE_BIN="$(ls -d "$HOME"/.nvm/versions/node/*/bin 2>/dev/null | sort -V | tail -n1)"
fi
if [ -n "$NVM_NODE_BIN" ]; then
  export PATH="$NVM_NODE_BIN:$PATH"
fi

# Force every `git` call the implementation agent makes inside its own
# sandbox (not just this wrapper script's own pre/post checks below, which
# already used git.exe) onto native Windows git.exe rather than WSL's git.
# Root cause this closes: this repo's .git lives under OneDrive's Files-
# On-Demand cloud filter driver AND is accessed from WSL through the v9fs
# translation layer for /mnt/c -- that combination breaks git's atomic
# index-rename guarantee under load, confirmed twice (2026-07-20) as
# `fatal: .git/index: index file smaller than expected` mid-dispatch.
# Native git.exe on NTFS removes the v9fs half of that combination. The
# shim is a thin `exec git.exe "$@"` wrapper at ~/.codex-git-shim/git,
# prepended to PATH so it resolves ahead of WSL's own /usr/bin/git.
if [ -x "$HOME/.codex-git-shim/git" ]; then
  export PATH="$HOME/.codex-git-shim:$PATH"
fi

# Prepended to every dispatch's actual prompt (not something the ticket author
# has to remember to include). Root cause: this repo lives inside OneDrive
# (Files On-Demand), whose sync engine races with git's own atomic index
# rewrites -- confirmed cause of "fatal: unable to write new index file" and
# similar errors, twice now (2026-07-15/16). The error itself is transient and
# harmless if handled correctly; the actual damage both times came from an
# agent improvising a "fix" (wiping/resetting the index, a broad `git rm
# --cached`-style recovery) that then got committed, collapsing the tracked
# tree to almost nothing while `git status` still reported clean.
GIT_SAFETY_PREAMBLE='# Git safety (read before any git operation -- this repo lives on OneDrive, which intermittently causes git index errors)

This repository is on a OneDrive-synced path. OneDrive'"'"'s background sync occasionally races with
git'"'"'s own atomic index writes, producing errors like `fatal: unable to write new index file` or a
stale/stuck `.git/index.lock`. This is a KNOWN, TRANSIENT environment quirk -- it is not a sign that
anything is actually broken, and it does not require -- and must never receive -- any creative recovery.

If you hit an index-lock or "unable to write new index file" error on `git add`/`git commit`:
1. `rm -f .git/index.lock` (only the lock file, nothing else), wait ~2 seconds, retry the SAME command
   once.
2. If it fails again, STOP. Do not try anything else. In particular, NEVER run any of: `git reset --hard`,
   `git rm -r --cached .` (or any broad `--cached` unstage), deleting/recreating `.git/index` by hand, or
   `git init`/re-adding the whole tree "to be safe". Every one of these can silently collapse the tracked
   tree if run while the index is already in a bad state -- exactly the failure mode this note exists to
   prevent. Report the exact error in your status file and leave the working tree as-is; the verification
   agent (running outside this sandbox, on the real filesystem) will resolve it.
3. Before your FINAL commit of this ticket, sanity-check with `git ls-files | wc -l` and confirm the
   count is in the same ballpark as before you started (thousands of files, not a handful) -- if it
   collapsed, you have hit this bug; stop and report rather than committing over it.

---

'

PROMPT="$GIT_SAFETY_PREAMBLE$(cat "$PROMPT_FILE")"

# --- Git integrity guard -----------------------------------------------
# This repo lives inside OneDrive (Files On-Demand), which actively syncs
# and re-uploads `.git/index`/`.git/HEAD` etc. while WSL-side git tries to
# rewrite them atomically. Confirmed root cause (2026-07-15/16, second
# occurrence) of "fatal: unable to write new index file" mid-dispatch. The
# real damage isn't that error itself (transient, retriable) -- it's an
# implementation-agent session reacting to it by improvising further git
# surgery (an index wipe, a bogus `git rm -r --cached`-style operation)
# that then gets COMMITTED, silently collapsing the tracked tree to almost
# nothing. `git status` alone can't catch this after the fact -- a bad
# commit that matches a bad working tree still reports "clean". So: snapshot
# the tracked-file count now, and hard-fail loudly after the run if it
# collapsed, rather than relying on the dirty-tree check below to notice.
PRE_TRACKED_COUNT="$(git.exe ls-files | wc -l)"
PRE_HEAD="$(git.exe rev-parse HEAD)"

echo "=== Invoking Implementation Agent (codex exec) ==="
echo "Repo: $REPO_ROOT"
echo "Prompt file: $PROMPT_FILE ($(wc -l < "$PROMPT_FILE") lines)"
echo "Mode: $([ "$MODE" = "--fresh" ] && echo "fresh session" || echo "resume --last")"
echo "Sandbox: $SANDBOX_MODE"
echo "Profile: ${PROFILE:-<none -- Codex default model>}"
echo "===================================================="

cd "$REPO_ROOT"

# Record this script's OWN pid so a caller that backgrounds this whole script
# (setsid nohup bash call_implementation_agent.sh ... & disown) has a
# reliable, repeatable way to poll for completion later -- `while kill -0
# "$(cat .codex-logs/.last_dispatch.pid)" 2>/dev/null; do sleep 5; done`.
# This replaces fragile pgrep-by-command-substring checks (e.g. `pgrep -f
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

# Captured to a side file (via `tee`) so it can be greeped for the vsock
# failure signature below WITHOUT losing the live streaming to stdout that
# callers tail for progress. `${PIPESTATUS[0]}` (not `$?`, which would be
# tee's exit status) preserves codex's own real exit code through the pipe.
CODEX_OUTPUT_CAPTURE="$(mktemp)"
# Disabled around the pipeline itself: with `set -e -o pipefail` active, a
# non-zero exit from EITHER half of `codex exec | tee` would abort the script
# right here, before STATUS is even captured -- silently skipping the vsock
# detector and the git-integrity guard below exactly when they matter most.
set +e
if [ "$MODE" = "--fresh" ]; then
  npx --yes @openai/codex exec \
    "${PROFILE_ARGS[@]}" \
    --sandbox "$SANDBOX_MODE" \
    --add-dir "$REPO_ROOT/.git" \
    --add-dir "$PUB_CACHE_DIR" \
    --add-dir "$FLUTTER_CONFIG_DIR" \
    "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
else
  npx --yes @openai/codex exec \
    "${PROFILE_ARGS[@]}" \
    --sandbox "$SANDBOX_MODE" \
    --add-dir "$REPO_ROOT/.git" \
    --add-dir "$PUB_CACHE_DIR" \
    --add-dir "$FLUTTER_CONFIG_DIR" \
    resume --last "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
fi
STATUS="${PIPESTATUS[0]}"
set -e

echo "===================================================="
echo "codex exec exited with status $STATUS"

# --- WSL vsock exhaustion detector --------------------------------------
# See the KNOWN ISSUE note above this script's header. This failure mode
# exits 0, indistinguishable from "ran and found nothing to do" by exit code
# alone -- so detect it explicitly by grepping the actual transcript, and say
# so loudly rather than letting a caller assume a real attempt happened.
# NOTE: the error can appear at TWO different points, confirmed both ways in
# this repo's own history -- (a) on the agent's very first shell command,
# before any edit (the common case: zero file changes, fully safe to retry),
# or (b) later, if the agent already made real edits and only its OWN
# post-edit verification/commit attempt then hit the wall (real changes may
# already be sitting uncommitted in the working tree -- check `git status`/
# `git diff` before assuming there is nothing to salvage). This detector
# cannot tell which case occurred from the transcript alone.
if grep -qE "UtilBindVsockAnyPort|UtilAcceptVsock|accept4 failed" "$CODEX_OUTPUT_CAPTURE"; then
  echo "##################################################################"
  echo "# DISPATCH_HIT_VSOCK=1 -- WSL vsock error appeared this run.     #"
  echo "##################################################################"
  echo "Check 'git status'/'git diff' before assuming nothing happened -- this"
  echo "error can strike either before any edit (nothing to salvage, just"
  echo "retry) or after real edits, if only this run's OWN post-edit"
  echo "verification/commit attempt hit it (real changes may already be"
  echo "sitting uncommitted -- review and finish verifying/committing those"
  echo "yourself rather than discarding them). Either way, a fresh retry for"
  echo "whatever remains is safe. If this is the 2nd+ consecutive blocked"
  echo "attempt, run 'wsl.exe --shutdown' from PowerShell (never from inside"
  echo "this script) before retrying again."
  echo "See: https://github.com/openai/codex/issues/8322 and"
  echo "     https://github.com/microsoft/WSL/issues/40650"
fi
rm -f "$CODEX_OUTPUT_CAPTURE"

# This repository lives on a Windows OneDrive path. Keep all repository
# operations on Windows Git; WSL Git is used neither for commits nor for this
# final visibility check.
DIRTY="$(git.exe status --porcelain)"
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
# would miss it silently -- exactly what happened 2026-07-15/16.
POST_TRACKED_COUNT="$(git.exe ls-files | wc -l)"
POST_HEAD="$(git.exe rev-parse HEAD)"
if [ "$POST_HEAD" != "$PRE_HEAD" ] && [ "$PRE_TRACKED_COUNT" -gt 0 ]; then
  DROP_PCT=$(( (PRE_TRACKED_COUNT - POST_TRACKED_COUNT) * 100 / PRE_TRACKED_COUNT ))
  if [ "$DROP_PCT" -ge 20 ]; then
    echo "##################################################################"
    echo "# GIT INTEGRITY ALERT -- tracked file count collapsed this run.  #"
    echo "##################################################################"
    echo "Before: $PRE_TRACKED_COUNT files tracked at $PRE_HEAD"
    echo "After:  $POST_TRACKED_COUNT files tracked at $POST_HEAD  (-$DROP_PCT%)"
    echo "Do NOT trust this run's commit(s) as-is. Before doing anything else:"
    echo "  git.exe log --oneline -5"
    echo "  git.exe diff --stat $PRE_HEAD $POST_HEAD"
    echo "Identify the last commit whose tree size is consistent with"
    echo "$PRE_TRACKED_COUNT files, then reset main to it (mixed reset only,"
    echo "never --hard, so any genuinely new uncommitted work is preserved):"
    echo "  git.exe reset <last-good-commit>"
  fi
fi

exit "$STATUS"
