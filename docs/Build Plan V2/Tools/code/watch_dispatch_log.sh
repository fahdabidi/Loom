#!/bin/bash
# data/watch_dispatch_log.sh <label> [post-completion-sleep-seconds]
#
# Self-terminating completion watcher. A plain `tail -F <log> | grep ...`
# never exits on its own -- `tail -F` never stops by itself, and a watch
# tool that fires a notification on a matching line does not necessarily
# kill the underlying process when it matches. This script is itself
# responsible for ending the watch: the moment it sees the real completion
# line ("codex exec exited with status"), it prints that line, waits a few
# seconds for any trailing buffered output to flush, then kills its own
# `tail -F` and exits.
#
# HISTORICAL NOTE (resolved by the WSL2->VirtualBox migration, kept for
# context): under WSL2, this script also watched for vsock-exhaustion alert
# lines, since a leaked `tail -F | grep` Monitor pipeline held a live
# wsl.exe/wslhost.exe session open for up to 30 minutes past real
# completion -- a real, confirmed contributor to vsock exhaustion (stopping
# ONE leaked pipeline dropped the live wsl.exe count from 6 to 2
# immediately, found 2026-07-22). Over SSH there is no equivalent process-
# leak failure mode (an unclosed SSH channel is not scarce the way vsock
# ports were), but self-termination still matters: an unbounded `tail -F`
# holds the SSH channel open indefinitely, wasting a watcher slot for no
# reason once the dispatch is done. See
# docs/Build Plan V2/Tools/wsl-to-virtualbox-migration.md.
#
# Usage:
#   ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && bash data/watch_dispatch_log.sh <label>'
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
  if [[ "$line" =~ ^codex\ exec\ exited\ with\ status ]]; then
    echo "$line"
    sleep "$POST_SLEEP"
    break
  fi
done

exit 0
