#!/bin/bash
# dispatch_health.sh <log-path> [label]
#
# Decide whether a running codex dispatch is actually PROGRESSING, or is alive
# but stuck. Written 2026-08-19 after a loop reported "running normally" across
# several ticks on the strength of log mtime alone.
#
# WHY MTIME ALONE IS NOT ENOUGH: freshness proves the process is alive. It does
# not prove it is getting anywhere. A dispatch that is retrying, rate-limited or
# spinning on a failed tool call can keep touching its log indefinitely.
#
# WHY CPU IS NOT A SIGNAL EITHER (measured, not assumed): a codex dispatch is
# I/O-bound -- it spends its time waiting on model responses, not computing. Its
# node process reports ~0 cumulative CPU seconds even while working normally and
# does not appear among the machine's top CPU consumers at all. An earlier cut of
# this script treated CPU as evidence of work and would have called every healthy
# dispatch frozen.
#
# So the two signals that mean anything here are:
#
#   1. FILES WRITTEN   - newest mtime across modified tracked files, plus the
#                        modified-file count. A dispatch doing real work edits
#                        files. This is the strong signal.
#   2. LOG GROWTH      - bytes appended. The event stream advancing means the
#                        model round-trip is still completing. Weaker: a long
#                        single edit can be quiet for a while, and a rate-limited
#                        retry loop can be noisy while achieving nothing.
#
# A stall is only called after being seen TWICE in a row, because one quiet tick
# during a long single edit is normal and must never trigger a restart.
#
# Exit codes:  0 PROGRESSING   1 SUSPECT (first quiet tick)   2 FROZEN/DEAD
#              3 DONE          4 UNKNOWN (no baseline yet; baseline written)

set -uo pipefail

LOG="${1:?usage: dispatch_health.sh <log-path> [label]}"
LABEL="${2:-$(basename "$LOG" .log)}"
STATE="/tmp/dispatch_health_${LABEL}.state"
REPO="${LOOM_REPO:-$HOME/Loom}"

now=$(date +%s)

if grep -aq 'codex exec exited with status' "$LOG" 2>/dev/null; then
  echo "VERDICT: DONE"
  grep -a 'codex exec exited with status' "$LOG" | tail -1
  rm -f "$STATE"
  exit 3
fi

# ps -eo comm matches the process NAME only. pgrep -f matches its own command
# line and returns false positives -- it reported RUNNING three times in one
# session for dispatches that had already exited.
if ! ps -eo comm --no-headers | grep -qE '^node'; then
  echo "VERDICT: DEAD (no node process, and no exit line in the log)"
  echo "  It died without writing its exit line. Partial work is still in the"
  echo "  working tree -- inspect that before re-dispatching, do not assume the"
  echo "  tree is clean."
  rm -f "$STATE"
  exit 2
fi

log_size=$(stat -c %s "$LOG" 2>/dev/null || echo 0)

cd "$REPO" 2>/dev/null || { echo "VERDICT: UNKNOWN (repo not found at $REPO)"; exit 4; }
files=$(git status --short 2>/dev/null | grep -c '^ M')
newest=0
while read -r f; do
  [ -f "$f" ] || continue
  m=$(stat -c %Y "$f" 2>/dev/null || echo 0)
  [ "$m" -gt "$newest" ] && newest=$m
done < <(git status --short 2>/dev/null | awk '{print $2}')

if [ ! -f "$STATE" ]; then
  printf 'ts_prev=%s size_prev=%s files_prev=%s newest_prev=%s strikes=0\n' \
    "$now" "$log_size" "$files" "$newest" > "$STATE"
  echo "VERDICT: UNKNOWN (no baseline; recorded one)"
  echo "  log_size=$log_size files_modified=$files"
  echo "  Re-run on the next tick for a real reading."
  exit 4
fi

ts_prev=0; size_prev=0; files_prev=0; newest_prev=0; strikes=0
# shellcheck disable=SC1090
. "$STATE"

elapsed=$(( now - ts_prev ))
d_size=$(( log_size - size_prev ))
d_files=$(( files - files_prev ))
wrote=0; [ "$newest" -gt "$newest_prev" ] && wrote=1
since_write=$(( now - newest ))

echo "since last check: ${elapsed}s"
printf '  log grew        : %+d bytes\n' "$d_size"
printf '  files modified  : %d (was %d)\n' "$files" "$files_prev"
printf '  wrote a file    : %s\n' "$([ "$wrote" = 1 ] && echo yes || echo no)"
if [ "$newest" -gt 0 ]; then
  printf '  last file write : %ds ago\n' "$since_write"
else
  echo '  last file write : (nothing modified yet)'
fi

progress=no
[ "$wrote" = 1 ] && progress=yes
[ "$d_files" -ne 0 ] && progress=yes

# A short window proves nothing. Codex routinely spends several minutes on one
# edit or one long read, so a quiet 30-second gap is not evidence of a stall --
# counting it as a strike would escalate a healthy dispatch to FROZEN purely
# because the caller looked twice in quick succession. Only windows at least
# this long are allowed to accumulate a strike.
MIN_WINDOW=${DISPATCH_HEALTH_MIN_WINDOW:-600}

if [ "$progress" = yes ]; then
  strikes=0
  verdict="PROGRESSING"; code=0
elif [ "$elapsed" -lt "$MIN_WINDOW" ]; then
  verdict="INCONCLUSIVE (only ${elapsed}s since last check; need ${MIN_WINDOW}s to judge, strikes unchanged at $strikes)"; code=0
elif [ "$d_size" -gt 20000 ]; then
  strikes=$(( strikes + 1 ))
  if [ "$strikes" -ge 3 ]; then
    verdict="FROZEN (log streaming but no file written across $strikes checks -- likely a retry loop)"; code=2
  else
    verdict="SUSPECT (streaming, but nothing written; strike $strikes of 3)"; code=1
  fi
else
  strikes=$(( strikes + 1 ))
  if [ "$strikes" -ge 2 ]; then
    verdict="FROZEN (log static and nothing written across $strikes checks)"; code=2
  else
    verdict="SUSPECT (log static and nothing written; strike $strikes of 2)"; code=1
  fi
fi

printf 'ts_prev=%s size_prev=%s files_prev=%s newest_prev=%s strikes=%s\n' \
  "$now" "$log_size" "$files" "$newest" "$strikes" > "$STATE"

echo "VERDICT: $verdict"

if [ "$code" -ge 1 ]; then
  echo
  echo "last events seen in the log:"
  tail -c 400000 "$LOG" 2>/dev/null | tr -d '\000' | sed 's/\x1b\[[0-9;]*m//g' \
    | grep -aE '^exec |^\+\+\+ b/|"(command|path)":' \
    | tail -5 | cut -c1-118 | sed 's/^/  /'
  echo
  echo "if this is FROZEN: kill the node process, inspect the partial diff,"
  echo "then re-dispatch with --fresh. Do not re-dispatch on top of a session"
  echo "whose state you have not looked at."
fi

exit "$code"
