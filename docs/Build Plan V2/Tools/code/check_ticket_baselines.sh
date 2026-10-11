#!/usr/bin/env bash
# check_ticket_baselines.sh — do PENDING tickets state the recorded suite baselines?
#
# WHY. A ticket is read by someone about to do the work, so a stale number in one is an
# instruction to chase a phantom delta. Measured 2026-10-10: 21 tickets state a demo baseline
# across 13 distinct values, and one PENDING ticket said 310 against a measured 312 — written
# when 310 was right, stale once a later commit added two tests. A low baseline makes a correct
# run look inflated (that nearly triggered a fabricated-test investigation here) and equally
# lets a real deletion hide inside apparent growth.
#
# SCOPE, and it is deliberately narrow so this cannot become an always-noisy guard nobody reads:
# only tickets still PENDING dispatch are checked. A shipped ticket's baseline is a correct
# historical record of what was true when it ran, not drift, and flagging those would bury the
# one line that matters.
#
# WHAT IT CANNOT DO: tell you the recorded baseline is current. It checks agreement with
# suite_baselines.txt, nothing more. Keep that file honest by re-measuring.
# WHAT "PENDING" MEANS HERE, because a gate's own printed count has to be interpretable.
# Pending = a ticket whose Status line records no completed, superseded or deferred outcome.
# Excluded: "DISPATCHED AND SHIPPED", "SHIPPED", "SUPERSEDED", "NOTHING LEFT TO DISPATCH",
# "DONE", "POST-PRODUCTION" (user-deferred 2026-09-02) and scoping requests, which are not
# implementation tickets. Measured 2026-10-10: that leaves 6 -- the 5 awaiting dispatch plus
# GAP-permission-catalog-publishing, which is genuinely open with Part A done and Part B owed.
# The first version of this list omitted DONE and POST-PRODUCTION and printed 10, which was
# not wrong about anything it CHECKED (only 5 state a baseline at all) but was a loose number
# in a guard's own output, and this project is strict about those.
set -uo pipefail
cd "$(dirname "$0")/../../../.." || exit 2
BASE="docs/Build Plan V2/Tools/code/suite_baselines.txt"
DIR="docs/Build Plan V2/Tickets"
[ -f "$BASE" ] || { echo "ERROR: missing $BASE" >&2; exit 2; }
[ -d "$DIR" ] || { echo "ERROR: missing $DIR" >&2; exit 2; }

want() { grep -E "^$1=" "$BASE" | head -1 | cut -d= -f2; }
D=$(want demo); A=$(want "app shell"); J=$(want judges); E=$(want engine); S=$(want service)

checked=0; pending=0; bad=0
for f in "$DIR"/*.md; do
  [ -e "$f" ] || continue
  status=$(grep -m1 '^\*\*Status:\*\*' "$f" 2>/dev/null || true)
  # Pending = its Status line does not record a completed or superseded outcome.
  case "$status" in
    *"DISPATCHED AND SHIPPED"*|*SHIPPED*|*SUPERSEDED*|*"NOTHING LEFT TO DISPATCH"*) continue ;;
    *DONE*|*"POST-PRODUCTION"*|*"scoping request"*) continue ;;
  esac
  pending=$((pending+1))
  # Only tickets that actually state a baseline can disagree with one.
  # Match ONLY inside the "## Verification" section. A ticket's PROSE legitimately contains
  # strings like "workflow-service **404**" (a real HTTP status from a reachability probe), and
  # the old file-wide match with `head -1` took the FIRST hit anywhere, so prose appearing
  # before the Verification section always beat the real figure. Measured 2026-10-10: that is
  # exactly how this gate reported "states service 404, recorded baseline is 168".
  V=$(sed -n '/^## Verification/,$p' "$f")
  printf '%s' "$V" | grep -qE 'demo \*\*[0-9]+\*\*' || continue
  checked=$((checked+1))
  for pair in "demo:$D" "app shell:$A" "judges:$J" "engine:$E" "service:$S"; do
    label=${pair%%:*}; expected=${pair##*:}
    [ -n "$expected" ] || continue
    # (^|[^a-z-]) stops the label "service" from matching inside "workflow-service".
    found=$(printf '%s' "$V" | grep -ohE "(^|[^a-z-])$label \*\*[0-9]+\*\*" | head -1 | grep -oE '[0-9]+' || true)
    [ -n "$found" ] || continue
    if [ "$found" != "$expected" ]; then
      echo "DRIFT  $(basename "$f")"
      echo "       states $label $found, recorded baseline is $expected"
      bad=$((bad+1))
    fi
  done
done

echo "----"
echo "pending tickets: $pending   stating a baseline: $checked   disagreements: $bad"
if [ "$bad" -gt 0 ]; then
  echo "A pending ticket's baseline is an INSTRUCTION. Fix the ticket, or re-measure and"
  echo "update $BASE -- and say which you did, because the two mean different things."
  exit 1
fi
echo "OK: every pending ticket agrees with the recorded baseline."
echo "NOTE: this proves agreement with the record, NOT that the record is current."
exit 0
