#!/bin/bash
# data/watch_dispatch_log.sh <label> [post-completion-sleep-seconds]
#
# Self-terminating completion watcher, designed to be wrapped in a Monitor.
#
# WHY A MONITOR, AND WHY THIS SCRIPT (measured 2026-08-18): time-based waking
# is unreliable in this setup and event-based waking is not. Over two overnight
# stalls, `ScheduleWakeup` (a 25-minute relative delay silently registered as a
# daily absolute one-shot) and `CronCreate` (~32 consecutive missed firings)
# never fired once, while every Monitor fired correctly and promptly. Host
# sleep, reboot, editor restart and session death were all ruled out with
# evidence -- the session was alive the whole time. So: never poll, never sleep
# on a timer, and never assume a scheduled wake-up will arrive. Wrap this script
# in a Monitor and let the event wake you. See loop.md section 4a.
#
# Canonical use (from the verification agent's own shell, as a Monitor command):
#   ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && bash data/watch_dispatch_log.sh <label>'
#
# This replaces BOTH older patterns, each of which had a real failure mode:
#   - `tail -F <log> | grep ...`  -- never exits on its own; holds the SSH
#     channel open indefinitely past real completion.
#   - `while kill -0 "$(cat .codex-logs/.last_dispatch.pid)"; do sleep 5; done`
#     -- a poll loop; burns a turn per poll and reports nothing about *why* the
#     dispatch ended.
#
# WHAT IT EMITS (each line is a Monitor event; all three end the watch except
# DISPATCH-SIGNAL, which is informational and keeps watching):
#   codex exec exited with status <n>   -- the real completion line (Codex-based dispatches)
#   muse exec exited with status <n>    -- the real completion line (Muse-based dispatches,
#                                          e.g. the root cause agent since 2026-09-07)
#   DISPATCH-DIED: ...                  -- the dispatch process vanished with no
#                                          completion line (killed, OOM, crash)
#   DISPATCH-SIGNAL: <line>             -- a failure signature seen mid-run
#                                          (usage limit, panic, fatal); surfaced
#                                          immediately, watch continues
#
# The DISPATCH-DIED case is the important addition. The previous version matched
# only the completion line, so a dispatch killed without emitting it left this
# watcher blocked forever -- the Monitor never fired and the loop stalled
# silently, indistinguishable from "still running". Monitor's own guidance is
# the rule here: if the process died right now, the filter must still emit
# something. Silence must never be the failure signal.
#
# COMPLETION-LINE FALSE POSITIVE (found 2026-09-11, DeepSeek V4 Flash dispatch
# of ticket P4): a dispatch's own transcript can legitimately contain a
# VERBATIM DUMP of an earlier dispatch's log -- e.g. the agent `cat`s or reads
# a prior .codex-logs/*.log file while investigating tooling conventions -- and
# if that older file itself starts a line with "codex exec exited with
# status <n>" (the wrapper's own completion line, from whichever run produced
# it), that text streams through `tail -F` like any other new output and
# matches the case pattern below, indistinguishable from a real completion.
# An anchored/exact-prefix match does NOT help: the embedded line legitimately
# starts a real line too, it's just not *this* dispatch's own exit line.
# Confirmed live: P4's log had "codex exec exited with status 0" mid-transcript
# (an embedded dump) while `codex exec` was still genuinely running, followed
# nearly 700 lines and several more minutes later by the true final line,
# "codex exec exited with status 1". A naive first-match check reported
# completion (and the wrong status) while the dispatch was still working.
#
# The fix: the wrapper's OWN completion line is followed almost immediately by
# the wrapper process itself exiting (a few lines of git-status bookkeeping,
# then EOF) -- typically under a second, never more than a few. An EMBEDDED
# occurrence has no such property: the process that would need to exit is the
# dispatch's own long-running `codex exec`/`claude`/`muse` child, which keeps
# running for as long as the dispatch has left, often minutes. So on a match,
# this script no longer trusts the text alone -- it confirms the tracked
# DISPATCH_PID actually exits within COMPLETION_CONFIRM_GRACE seconds before
# reporting completion. If the pid is still alive once that window elapses,
# the match is treated as an embedded false positive and the watch continues
# silently. (When no PID file is available at all, this check is skipped and
# the text match is trusted directly, same as before 2026-09-11 -- there is no
# liveness signal to confirm against in that degraded mode either way.)
#
# HISTORICAL NOTE (resolved by the WSL2->VirtualBox migration, kept for
# context): under WSL2, this script also watched for vsock-exhaustion alert
# lines, since a leaked `tail -F | grep` Monitor pipeline held a live
# wsl.exe/wslhost.exe session open for up to 30 minutes past real completion --
# a real, confirmed contributor to vsock exhaustion (stopping ONE leaked
# pipeline dropped the live wsl.exe count from 6 to 2 immediately, found
# 2026-07-22). Over SSH there is no equivalent process-leak failure mode, but
# self-termination still matters: an unbounded `tail -F` wastes a watcher slot
# and an SSH channel for no reason once the dispatch is done. See
# docs/Build Plan V2/Tools/wsl-to-virtualbox-migration.md.
#
# <label> must match the label used for this dispatch's
# .codex-logs/<label>_dispatch.out.log (the file call_implementation_agent.sh
# writes to, per the canonical dispatch recipe in that script's own header).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LABEL="${1:?usage: watch_dispatch_log.sh <label> [post-completion-sleep-seconds]}"
POST_SLEEP="${2:-5}"
LOG="$REPO_ROOT/.codex-logs/${LABEL}_dispatch.out.log"
# Which pid file identifies this dispatch's process. The implementation agent
# writes .last_dispatch.pid; the Skill-authoring agent writes
# .last_skill_authoring_dispatch.pid. Watching the wrong one is not a harmless
# mismatch -- it reads a *stale, already-finished* pid from an earlier dispatch
# and reports DISPATCH-DIED immediately, for a run that is alive and healthy.
# Observed 2026-08-18 on the AdFreeCommunity regeneration. Set DISPATCH_PID_FILE
# (absolute, or relative to .codex-logs/) when watching a Skill dispatch.
PID_FILE_NAME="${DISPATCH_PID_FILE:-.last_dispatch.pid}"
case "$PID_FILE_NAME" in
  /*) PID_FILE="$PID_FILE_NAME" ;;
  *)  PID_FILE="$REPO_ROOT/.codex-logs/$PID_FILE_NAME" ;;
esac

# How long to wait for a trailing completion line after the process disappears,
# before declaring it died. Covers the normal race where the process exits a
# moment before its final line is flushed to the log.
DEATH_GRACE="${DEATH_GRACE:-15}"

# How long to wait, after seeing what looks like the completion line, for the
# tracked DISPATCH_PID to actually exit before trusting it. The wrapper's real
# exit line is followed by a handful of fast git-status commands then EOF --
# well under this window in practice. An embedded false positive (see above)
# leaves the pid alive far longer, since the dispatch itself is still running.
COMPLETION_CONFIRM_GRACE="${COMPLETION_CONFIRM_GRACE:-20}"

if [ ! -f "$LOG" ]; then
  echo "watch_dispatch_log.sh: log not found: $LOG" >&2
  exit 1
fi

DISPATCH_PID=""
if [ -f "$PID_FILE" ]; then
  DISPATCH_PID="$(tr -d '[:space:]' < "$PID_FILE" 2>/dev/null || true)"
fi

exec 3< <(tail -F "$LOG" 2>/dev/null)
TAILPID=$!

cleanup() {
  kill "$TAILPID" >/dev/null 2>&1
}
trap cleanup EXIT

dispatch_is_alive() {
  # No usable PID -- degrade to log-only watching rather than reporting a
  # death we cannot actually confirm.
  [ -z "$DISPATCH_PID" ] && return 0
  kill -0 "$DISPATCH_PID" 2>/dev/null
}

# Confirms a matched completion line is the wrapper's own, not an embedded
# false positive (see the 2026-09-11 note above), by waiting up to
# COMPLETION_CONFIRM_GRACE seconds for DISPATCH_PID to actually exit. With no
# PID available there is nothing to confirm against, so the match is trusted
# directly, same as this script's behavior before that fix existed.
confirm_real_completion() {
  [ -z "$DISPATCH_PID" ] && return 0
  local waited=0
  while dispatch_is_alive; do
    if [ "$waited" -ge "$COMPLETION_CONFIRM_GRACE" ]; then
      return 1
    fi
    sleep 1
    waited=$((waited + 1))
  done
  return 0
}

death_deadline=""

while true; do
  if IFS= read -r -t 5 line <&3; then
    case "$line" in
      # "claude exited with status" added 2026-09-10 with the implementation
      # agent's move to the Claude Code CLI. It also makes this watcher work for
      # the UX judge and live verification agents, which have always used that
      # wording and which this watcher could never see.
      "codex exec exited with status"*|"muse exec exited with status"*|"claude exited with status"*)
        if confirm_real_completion; then
          echo "$line"
          sleep "$POST_SLEEP"
          exit 0
        fi
        # DISPATCH_PID outlived the grace window -- this was an embedded
        # occurrence (e.g. a dumped older log), not this dispatch's own exit
        # line. Keep watching; do not exit, do not treat it as a signal.
        continue
        ;;
      *"hit your usage limit"*|*"panic:"*|*"FAILED ("*|"fatal:"*)
        # Surface immediately so the watching session sees the real reason
        # while the run is still ending, but keep watching for the exit line.
        echo "DISPATCH-SIGNAL: $line"
        ;;
    esac
    continue
  fi

  # read timed out: no new log output in the last 5s. Check liveness.
  if dispatch_is_alive; then
    death_deadline=""
    continue
  fi

  # Process is gone. Give the log a grace period to flush a completion line
  # that may still be in transit before declaring an abnormal death.
  if [ -z "$death_deadline" ]; then
    death_deadline=$(( $(date +%s) + DEATH_GRACE ))
    continue
  fi
  if [ "$(date +%s)" -lt "$death_deadline" ]; then
    continue
  fi

  echo "DISPATCH-DIED: pid ${DISPATCH_PID:-unknown} for '$LABEL' exited without a completion line (killed, crashed, or OOM). Check $LOG and the VM's state before re-dispatching."
  exit 3
done
