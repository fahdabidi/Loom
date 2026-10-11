#!/usr/bin/env bash
# check_tracker_row_detail_parity.sh — do TODO.md rows and their details agree about status?
#
# WHY. `TODO.md` carries one-line rows; the substance lives in `TODO-open-detail.md` behind a
# `#row-N` anchor. The two drift in BOTH directions, measured 2026-10-10:
#   * five CLOSED rows had details still asserting a live defect — one opened as a `new-ticket`
#     with six parity violations outstanding, two led with "STILL TRUE" verdicts dated three days
#     before their own closures;
#   * one OPEN row said Book Club regeneration was HELD while its own detail had recorded
#     "HOLD RELEASED 2026-09-25" for 25 days, over work that had since shipped.
# That second direction is the expensive one: a stale prohibition costs capability rather than
# time and never surfaces as a failure, because nobody reports work they correctly declined.
#
# WHAT IT CANNOT DO. It compares STATUS MARKERS, not substance. A detail that is factually stale
# while carrying the word CLOSED passes here. It is a drift detector, not a reviewer.
#
# A NOTE ON THE PATTERNS, because my own first version under-detected. I scored a detail as
# action-inviting on `new-ticket`, `needs-` and "not dispatched", and missed **"STILL TRUE"** —
# the most assertive phrase in the corpus — catching it only by hand-reading the two rows the
# sweep had scored harmless. Add to OPEN_PAT when a new assertive phrasing appears.
# RUNTIME: this takes OVER 200 SECONDS on Windows and about a minute on the VM. It spawns three
# subprocesses per row (grep + awk + sed inside detail_block) across ~38 rows, and Windows process
# creation is slow. On 2026-10-11 a `timeout 150` and then a `timeout 200` both killed it at 0 bytes
# output, which reads exactly like a hang -- it is not. Hung and slow differ in a trend, not in one
# sample: give it 600s before concluding anything, and capture the status from the command itself
# rather than through a pipe whose last stage always succeeds.
set -uo pipefail
cd "$(dirname "$0")/../../../.." || exit 2
T="docs/Build Plan V2/TODO.md"
D="docs/Build Plan V2/TODO-open-detail.md"
[ -f "$T" ] || { echo "ERROR: missing $T" >&2; exit 2; }
[ -f "$D" ] || { echo "ERROR: missing $D" >&2; exit 2; }

CLOSED_PAT='CLOSED|SHIPPED|DONE|✅|FIXED AND VERIFIED|HOLD RELEASED|do not act on this entry'
OPEN_PAT='STILL TRUE|not dispatched|Ticketed, not|new-ticket|new-milestone|needs-'

detail_block() { # $1 anchor -> prints that entry's lines
  local a="$1" L E
  L=$(grep -n "^### $a " "$D" | head -1 | cut -d: -f1) || return 1
  [ -n "$L" ] || return 1
  E=$(awk -v s="$L" 'NR>s && /^### row-/{print NR; exit}' "$D")
  [ -n "$E" ] || E=$(( $(wc -l < "$D") + 1 ))
  sed -n "${L},$((E-1))p" "$D"
}

bad=0; checked=0; noanchor=0
while IFS=: read -r ln rest; do
  [ -n "${ln:-}" ] || continue
  # Anchor on the LINK, not on any `row-N` text in the row. A row's PROSE can legitimately
  # mention another row ("...belonging to row-197"), and the old `grep -oE 'row-[0-9]+' | head -1`
  # took the FIRST match anywhere in the line -- so on 2026-10-11 a row whose prose cited row-197
  # resolved to row-197 and was compared against the wrong entry. The link is the contract; the
  # prose is not. Same shape as the label "service" matching inside "workflow-service **404**".
  a=$(printf '%s' "$rest" | grep -oE 'TODO-open-detail\.md#row-[0-9]+' | head -1 | grep -oE 'row-[0-9]+')
  [ -n "$a" ] || continue
  if ! blk=$(detail_block "$a"); then
    echo "MISSING ANCHOR  $a  (referenced from $T line $ln)"; noanchor=$((noanchor+1)); bad=$((bad+1)); continue
  fi
  checked=$((checked+1))
  closed_row=0
  case "$rest" in *'- [x]'*) closed_row=1 ;; esac
  dc=$(printf '%s' "$blk" | grep -cE "$CLOSED_PAT" || true)
  do_=$(printf '%s' "$blk" | grep -cE "$OPEN_PAT" || true)
  if [ "$closed_row" = "1" ] && [ "$dc" = "0" ]; then
    echo "STALE DETAIL    $a  (row closed at $T:$ln, detail has no closure marker; action-inviting hits=$do_)"
    bad=$((bad+1))
  fi
  if [ "$closed_row" = "0" ] && [ "$dc" != "0" ]; then
    echo "STALE ROW       $a  (row OPEN at $T:$ln, detail already records closure)"
    echo "                ^ this is the EXPENSIVE direction: an open row over finished work reads as a live instruction"
    bad=$((bad+1))
  fi
done < <(grep -nE "^[[:space:]]*- \[[ x]\].*TODO-open-detail\.md#row-[0-9]+" "$T")

echo "----"
echo "linked rows checked: $checked   missing anchors: $noanchor   disagreements: $bad"
if [ "$bad" -gt 0 ]; then
  echo "Fix whichever side is stale and say which — a stale ROW withholds work, a stale DETAIL invites"
  echo "redoing it. Keep the original reasoning; stamp the status."
  exit 1
fi
echo "OK: every linked row agrees with its detail about status."
echo "NOTE: this compares status MARKERS, not substance. A detail can be stale and still pass."
exit 0
