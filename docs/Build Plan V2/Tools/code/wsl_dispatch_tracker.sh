#!/bin/bash
# data/wsl_dispatch_tracker.sh
#
# Tracks the real Windows PIDs of the wsl.exe/wslhost.exe processes a single
# implementation-agent dispatch causes to appear, and cleans them up
# explicitly once the dispatch completes -- rather than relying on WSL2's own
# idle-timeout teardown, which this environment has repeatedly been observed
# NOT to reclaim reliably (orphaned wsl.exe/wslhost.exe processes surviving
# 5+ hours, see codex_dispatch_reliability memory, Failure 4). User-requested
# 2026-07-22 as a proactive companion to the reactive `wsl --shutdown`
# mitigation already in use.
#
# Why a before/after PID-set diff, not a single captured PID: the Windows
# process that LAUNCHES a dispatch (`wsl.exe -e bash -lc '...setsid nohup
# ... & disown...'`) exits within a few seconds on its own once it has
# backgrounded the real, long-running work inside WSL -- it is never the
# thing that lingers. What actually needs tracking is whatever NEW
# wsl.exe/wslhost.exe/wslrelay.exe/msrdc.exe processes appear as a side
# effect of that dispatch establishing its own WSL session, which is only
# identifiable by diffing the process set before vs. after, not by following
# one PID through the launcher chain (confirmed empirically: the launcher's
# own resolved PID is a short-lived, distinct process from the session that
# actually persists).
#
# Usage (three steps around a single dispatch):
#   bash data/wsl_dispatch_tracker.sh baseline <label>
#   # ... launch the dispatch ...
#   bash data/wsl_dispatch_tracker.sh capture <label>
#   # ... wait for the dispatch to complete (existing Monitor/pidfile) ...
#   bash data/wsl_dispatch_tracker.sh cleanup <label>
#
# Tracker log: .codex-logs/.dispatch_wsl_tracker.log (append-only, one line
# per lifecycle event, human-readable).
#
# Deliberately excluded from tracking/killing: wslservice.exe (the persistent
# Windows-side WSL management service -- always running, never dispatch-
# specific) and vmmemWSL (the shared lightweight VM hosting ALL WSL activity,
# including any other concurrent WSL usage on this machine -- killing it
# would tear down every other WSL session too, not just this dispatch's).
#
# `cleanup` also runs a zombie sweep (added 2026-07-22, user-requested after
# CALR.5a hit 3 consecutive vsock-blocked dispatch rounds traced to stale
# wslhost.exe processes ~2 hours old with no live wsl.exe launcher, found via
# `Get-Process -Name wsl,wslhost,wslservice`). This is NOT the same check as
# "parent process gone": every legitimate dispatch's own wslhost.exe
# outlives its wsl.exe launcher by design (`setsid nohup ... & disown`
# backgrounds the real session, and the launcher exits within seconds on its
# own) -- so a parent-liveness check would flag every healthy in-flight
# session as a false positive. The actual zombie signal empirically observed
# both times is AGE: processes idle for far longer than any real dispatch in
# this workflow takes. `sweep-zombies [max-age-minutes]` (default 60) kills
# any wsl.exe/wslhost.exe older than that threshold, logs what it found
# before killing (audit trail, same convention as the rest of this log), and
# is called automatically at the end of `cleanup` so this happens for free
# after every dispatch, not just when explicitly invoked. Still never
# touches wslservice.exe/vmmemWSL.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TRACKER="$REPO_ROOT/.codex-logs/.dispatch_wsl_tracker.log"
mkdir -p "$REPO_ROOT/.codex-logs"

SUBCOMMAND="${1:?usage: wsl_dispatch_tracker.sh <baseline|capture|cleanup|sweep-zombies> <label|max-age-minutes>}"

snapshot_pids() {
  ps -W 2>/dev/null \
    | grep -iE 'wsl' \
    | grep -viE 'wslservice|vmmemwsl' \
    | awk '{print $4}' \
    | sort -u
}

sweep_zombies() {
  local max_age_minutes="${1:-60}"
  # PowerShell owns process start-time/age -- ps -W has no reliable start-time
  # column across WSL/Windows process-table translation. Never touches
  # wslservice.exe/vmmemWSL (filtered by name match, same exclusion as
  # snapshot_pids above).
  local found
  found="$(powershell.exe -NoProfile -Command "
    \$cutoff = (Get-Date).AddMinutes(-$max_age_minutes)
    Get-Process -Name wsl,wslhost -ErrorAction SilentlyContinue |
      Where-Object { \$_.StartTime -lt \$cutoff } |
      ForEach-Object { \"\$(\$_.Id) \$(\$_.ProcessName) \$(\$_.StartTime)\" }
  " 2>/dev/null | tr -d '\r')"
  if [ -z "$found" ]; then
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') LABEL=zombie_sweep EVENT=none_found MAX_AGE_MIN=$max_age_minutes" >> "$TRACKER"
    return 0
  fi
  echo "$(date '+%Y-%m-%dT%H:%M:%S%z') LABEL=zombie_sweep EVENT=found MAX_AGE_MIN=$max_age_minutes DETAIL=$(echo "$found" | tr '\n' ';')" >> "$TRACKER"
  echo "$found" | while read -r pid name start; do
    [ -z "$pid" ] && continue
    powershell.exe -NoProfile -Command "Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue" >/dev/null 2>&1
  done
  sleep 2
  local still
  still="$(powershell.exe -NoProfile -Command "
    (Get-Process -Name wsl,wslhost -ErrorAction SilentlyContinue |
      Where-Object { \$_.Id -in ($(echo "$found" | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')) }).Id
  " 2>/dev/null | tr -d '\r')"
  if [ -z "$still" ]; then
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') LABEL=zombie_sweep EVENT=killed_and_reverified" >> "$TRACKER"
  else
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') LABEL=zombie_sweep EVENT=kill_FAILED WINPIDS=$(echo "$still" | tr '\n' ',' | sed 's/,$//')" >> "$TRACKER"
  fi
}

if [ "$SUBCOMMAND" = "sweep-zombies" ]; then
  sweep_zombies "${2:-60}"
  exit 0
fi

LABEL="${2:?usage: wsl_dispatch_tracker.sh <baseline|capture|cleanup> <label>}"
BASELINE_FILE="$REPO_ROOT/.codex-logs/.wsl_baseline_$LABEL.pids"
DISPATCH_PIDS_FILE="$REPO_ROOT/.codex-logs/.wsl_dispatch_$LABEL.pids"

case "$SUBCOMMAND" in
  baseline)
    snapshot_pids > "$BASELINE_FILE"
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') LABEL=$LABEL EVENT=baseline_captured COUNT=$(wc -l < "$BASELINE_FILE")" >> "$TRACKER"
    ;;
  capture)
    if [ ! -f "$BASELINE_FILE" ]; then
      echo "wsl_dispatch_tracker: no baseline found for label '$LABEL' -- run 'baseline' first" >&2
      exit 1
    fi
    snapshot_pids > "${DISPATCH_PIDS_FILE}.after"
    comm -13 "$BASELINE_FILE" "${DISPATCH_PIDS_FILE}.after" > "$DISPATCH_PIDS_FILE"
    PID_LIST="$(tr '\n' ',' < "$DISPATCH_PIDS_FILE" | sed 's/,$//')"
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') LABEL=$LABEL EVENT=dispatch_launched WINPIDS=${PID_LIST:-none}" >> "$TRACKER"
    ;;
  cleanup)
    if [ ! -f "$DISPATCH_PIDS_FILE" ]; then
      echo "wsl_dispatch_tracker: no captured dispatch PIDs for label '$LABEL' -- run 'capture' first" >&2
      exit 1
    fi
    CURRENT="$(snapshot_pids)"
    STILL_ALIVE="$(comm -12 "$DISPATCH_PIDS_FILE" <(echo "$CURRENT") 2>/dev/null || true)"
    if [ -z "$STILL_ALIVE" ]; then
      echo "$(date '+%Y-%m-%dT%H:%M:%S%z') LABEL=$LABEL EVENT=wsl_session_closed_confirmed NOTE=already_exited_on_own" >> "$TRACKER"
      sweep_zombies 60
      exit 0
    fi
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') LABEL=$LABEL EVENT=killing_lingering_pids WINPIDS=$(echo "$STILL_ALIVE" | tr '\n' ',' | sed 's/,$//')" >> "$TRACKER"
    for pid in $STILL_ALIVE; do
      powershell.exe -NoProfile -Command "Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue" >/dev/null 2>&1
    done
    sleep 2
    CURRENT_AFTER_KILL="$(snapshot_pids)"
    STILL_ALIVE_AFTER="$(comm -12 "$DISPATCH_PIDS_FILE" <(echo "$CURRENT_AFTER_KILL") 2>/dev/null || true)"
    if [ -z "$STILL_ALIVE_AFTER" ]; then
      echo "$(date '+%Y-%m-%dT%H:%M:%S%z') LABEL=$LABEL EVENT=wsl_session_closed_confirmed NOTE=killed_and_reverified" >> "$TRACKER"
    else
      echo "$(date '+%Y-%m-%dT%H:%M:%S%z') LABEL=$LABEL EVENT=wsl_session_close_FAILED WINPIDS=$(echo "$STILL_ALIVE_AFTER" | tr '\n' ',' | sed 's/,$//')" >> "$TRACKER"
      sweep_zombies 60
      exit 1
    fi
    sweep_zombies 60
    ;;
  *)
    echo "usage: wsl_dispatch_tracker.sh <baseline|capture|cleanup|sweep-zombies> <label|max-age-minutes>" >&2
    exit 2
    ;;
esac
