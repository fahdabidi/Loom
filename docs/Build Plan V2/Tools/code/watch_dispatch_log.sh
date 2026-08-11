#!/bin/bash
# data/watch_dispatch_log.sh <label> [post-completion-sleep-seconds]
#
# Self-terminating replacement for the old inline `tail -F <log> | grep -E
# '...vsock-patterns...|^codex exec exited with status'` Monitor command.
#
# Why this exists (found 2026-07-22, mid CALR.5a): that old pattern never
# exits on its own -- grep has no -m1 (would wrongly stop on the FIRST vsock
# alert, which is only a transient noise signal we want to keep watching
# past), and `tail -F` never exits by itself. The Monitor tool fires a
# notification on every matching line but does NOT kill the underlying
# process when a match occurs -- only a real timeout or explicit TaskStop
# does. Result: every dispatch-watching Monitor that ever matched the real
# "codex exec exited with status" completion line kept its `tail -F` (and
# the wsl.exe/wslhost.exe process backing it) alive indefinitely afterward,
# for up to the full 30-minute Monitor timeout, silently holding a WSL
# session open. Across a long session with many dispatch rounds (9 in one
# evening, CALR.4b + CALR.5a combined) these accumulate and were a real,
# confirmed contributor to WSL2 vsock-port exhaustion -- stopping ONE leaked
# Monitor pipeline dropped the live wsl.exe count from 6 to 2 immediately.
#
# This script watches for the same signals but is itself responsible for
# ending the watch: it keeps emitting vsock alert lines as they occur (so
# the verification agent still sees them as noise/progress signals), but the
# moment it sees the REAL completion line ("codex exec exited with status"),
# it prints that line, waits a few seconds (letting any trailing buffered
# output flush -- Monitor batches stdout arriving within 200ms of each
# other), then kills its own `tail -F` and exits -- ending the Monitor watch
# on its own, with no separate TaskStop call required.
#
# Usage (as a Monitor `command`, replacing the old raw tail|grep):
#   wsl.exe -e bash -lc 'cd "<repo>" && bash data/watch_dispatch_log.sh <label>'
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

if [ ! -f "$LOG" ]; then
  echo "watch_dispatch_log.sh: log not found: $LOG" >&2
  exit 1
fi

exec 3< <(tail -F "$LOG")
TAILPID=$!

cleanup() {
  kill "$TAILPID" >/dev/null 2>&1
}
trap cleanup EXIT

while IFS= read -r line <&3; do
  if [[ "$line" =~ UtilBindVsockAnyPort:[0-9]+:\ socket\ failed ]] \
    || [[ "$line" =~ UtilAcceptVsock:[0-9]+.*socket\ failed ]] \
    || [[ "$line" =~ accept4\ failed\ [0-9] ]]; then
    echo "$line"
  elif [[ "$line" =~ ^codex\ exec\ exited\ with\ status ]]; then
    echo "$line"
    sleep "$POST_SLEEP"
    break
  fi
done

exit 0
