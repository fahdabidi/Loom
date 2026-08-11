#!/bin/bash
# data/wsl_slot.sh
#
# Concurrency gate for the verification agent's own AD-HOC wsl.exe invocations
# (status checks, git commands, log reads, one-off diagnostics) -- everything
# EXCEPT the implementation-agent dispatch itself (which tracks its own single
# session via .codex-logs/.last_dispatch.pid, see call_implementation_agent.sh)
# and the vsock/completion Monitor (which is its own single persistent
# session). Caps THIS "own terminal" category at MAX_SLOTS concurrent wsl.exe
# invocations, so total concurrent WSL sessions across all three categories
# stays bounded (dispatch=1 + monitor=1 + terminal<=2 = 4 max), instead of
# growing unboundedly every time a new ad-hoc check gets issued -- see the
# codex_dispatch_reliability memory note (Failure 4/5): each fresh wsl.exe
# invocation consumes a slice of a hard, non-tunable, machine-wide vsock
# connection cap, and a verification session issuing many overlapping
# wsl.exe calls is exactly the usage pattern that exhausts it.
#
# Usage:
#   bash data/wsl_slot.sh "<full command line to run, usually a wsl.exe invocation>"
#
# Env overrides: WSL_SLOT_MAX (default 2), WSL_SLOT_TIMEOUT seconds (default 120).
#
# Implementation notes:
# - Gating happens entirely in git-bash/MSYS space (mkdir as the atomic
#   primitive) BEFORE the wrapped command runs -- critical, because the vsock
#   connection is consumed the instant wsl.exe itself starts, not by anything
#   that runs inside the WSL VM. A gate implemented inside WSL would be too
#   late to prevent the very cost it's trying to bound.
# - Self-healing: each slot directory records the PID that holds it
#   (`slot<i>/pid`). If that PID is no longer alive (a prior invocation died
#   without reaching its own cleanup -- e.g. killed, timed out, tool crashed),
#   the slot is treated as stale and reclaimed rather than permanently
#   starving future calls.
# - Not a strict OS-level enforcement mechanism -- it only gates invocations
#   that are actually routed through this script. It works as long as ad-hoc
#   wsl.exe calls are consistently issued via this wrapper rather than called
#   directly.

set -uo pipefail

MAX_SLOTS="${WSL_SLOT_MAX:-2}"
TIMEOUT_SECONDS="${WSL_SLOT_TIMEOUT:-120}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLOT_DIR="$SCRIPT_DIR/../.codex-logs/.wsl_terminal_slots"
mkdir -p "$SLOT_DIR"

if [ "$#" -lt 1 ]; then
  echo "usage: wsl_slot.sh \"<command to run>\"" >&2
  exit 2
fi
CMD="$1"
SLOT=""

acquire() {
  local i dir held_pid
  for ((i = 0; i < MAX_SLOTS; i++)); do
    dir="$SLOT_DIR/slot$i"
    if mkdir "$dir" 2>/dev/null; then
      echo "$$" > "$dir/pid"
      SLOT="$dir"
      return 0
    fi
    held_pid="$(cat "$dir/pid" 2>/dev/null || true)"
    if [ -n "$held_pid" ] && ! kill -0 "$held_pid" 2>/dev/null; then
      rm -rf "$dir" 2>/dev/null
      if mkdir "$dir" 2>/dev/null; then
        echo "$$" > "$dir/pid"
        SLOT="$dir"
        return 0
      fi
    fi
  done
  return 1
}

DEADLINE=$(($(date +%s) + TIMEOUT_SECONDS))
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  if acquire; then
    break
  fi
  sleep 1
done

if [ -z "$SLOT" ]; then
  echo "wsl_slot: timed out after ${TIMEOUT_SECONDS}s waiting for a free terminal slot (cap=$MAX_SLOTS already in use)" >&2
  exit 1
fi

cleanup() { rm -rf "$SLOT" 2>/dev/null; }
trap cleanup EXIT

# Log the real Windows PID of the launched wsl.exe process (not this wrapper
# script's own PID, and not git-bash's virtualized MSYS PID either) to a
# shared ledger, so a live PowerShell `Get-Process wsl,wslhost` snapshot can
# be cross-referenced against known-mine PIDs -- any PID NOT in this ledger
# is presumably launched by something else (another terminal, an editor's WSL
# extension, a separate agentic session).
#
# Two PID spaces are in play here and must not be confused:
# - `$!` after backgrounding gives git-bash's own MSYS-virtualized PID for the
#   child process -- NOT the real Windows PID `Get-Process`/`Get-Process -Id`
#   would recognize (confirmed empirically 2026-07-22: Get-Process -Id
#   <that number> found nothing).
# - The real Windows PID is git-bash's own `ps -W`'s `WINPID` column, looked
#   up by matching the MSYS PID in the `PID` column of that same `ps -W` row.
LEDGER="$SCRIPT_DIR/../.codex-logs/.wsl_pid_ledger.log"
eval "$CMD" &
MSYS_PID=$!
WIN_PID="$(ps -W 2>/dev/null | awk -v p="$MSYS_PID" '$1 == p {print $4; exit}')"
echo "$(date '+%Y-%m-%dT%H:%M:%S%z') MSYS_PID=$MSYS_PID WINPID=${WIN_PID:-unknown} PURPOSE=terminal CMD=${CMD:0:120}" >> "$LEDGER"
wait "$MSYS_PID"
