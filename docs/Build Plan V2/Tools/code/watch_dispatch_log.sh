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
#   codex exec exited with status <n>   -- the real completion line
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
PID_FILE="$REPO_ROOT/.codex-logs/.last_dispatch.pid"

# How long to wait for a trailing completion line after the process disappears,
# before declaring it died. Covers the normal race where the process exits a
# moment before its final line is flushed to the log.
DEATH_GRACE="${DEATH_GRACE:-15}"

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

death_deadline=""

while true; do
  if IFS= read -r -t 5 line <&3; then
    case "$line" in
      "codex exec exited with status"*)
        echo "$line"
        sleep "$POST_SLEEP"
        exit 0
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
