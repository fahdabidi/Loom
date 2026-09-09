#!/usr/bin/env bash
# check_b25_status.sh -- what fraction of the B25 production bar is actually proven?
#
# Why this exists. The bar was quoted as "N of 79" for weeks. On 2026-09-09 the denominator turned
# out to be 72 (77 rows present, five of them Masjid's test-harness ids that its own product doc
# already disclaims), and the numerator had never been computed at all -- nobody had joined the two
# halves the bar requires. This script does the join, so the number is recomputable instead of
# remembered.
#
# The bar: each row needs BOTH a live walkthrough AND a UX judge pass. This reports the walkthrough
# half, which is the half with machine-readable evidence. It deliberately does NOT invent a combined
# figure -- see the note it prints.
#
#   bash "docs/Build Plan V2/Tools/code/check_b25_status.sh"
#
# Reads only. Exits 0 always: this is a report, not a gate. Nothing here should fail a build.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
DOCS="$REPO_ROOT/docs/references/communities"
EVID="$REPO_ROOT/docs/Build Plan V2/Evidence/B25"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# --- the denominator: rows in each product doc's B25 addendum table -------------------------------
# The separator line is "| --- | --- |" WITH a space after the pipe; a /^\|---/ pattern misses it and
# inflates every community by exactly one. That bug produced a count of 87 before it was caught.
for f in "$DOCS"/*-product-experience.md; do
  awk -v C="$(basename "$f" -product-experience.md)" '
    /^\| Workflow \| Persona \| Expected decision \|/{inb=1; next}
    inb && /^\| *-/{next}
    inb && /^\|/{split($0,a,"|"); gsub(/^ +| +$/,"",a[2]); print C"\t"a[2]; next}
    inb && !/^\|/{inb=0}' "$f"
done > "$WORK/rows.tsv"

TOTAL=$(wc -l < "$WORK/rows.tsv")
# Rows the product doc itself marks as not a workflow (Masjid's testWidgets ids).
DISCLAIMED=$(grep -c $'\t⛔' "$WORK/rows.tsv" || true)
REAL=$((TOTAL - DISCLAIMED))

# --- the walkthrough half: workflow types named INSIDE the live-write manifests --------------------
# Parse the file's own "**Workflow:** `type`" line rather than its filename: the filenames are
# community-and-slug (garden-club-tool-loan) while the rows are workflow types (garden-tool-loan),
# and no rule maps one to the other.
#
# A manifest naming a workflow is NOT evidence that workflow was proven. Two of these record
# BLOCKED runs ("Not proven. No live write was performed.") and one records PARTIAL. Counting any
# manifest that mentions a type would have scored a failed walkthrough as a pass -- it only
# happened to give the right answer because each blocked run has a later successful manifest for
# the same workflow. Require the success phrase, and report the rest separately.
: > "$WORK/proven.txt"; : > "$WORK/notproven.txt"
for m in "$EVID"/*live-write*.md; do
  [ -e "$m" ] || continue
  wf=$(grep -m1 -oE '\*\*Workflow:\*\* `[a-z0-9-]+`' "$m" | grep -oE '`[a-z0-9-]+`' | tr -d '`')
  [ -n "$wf" ] || continue
  if grep -qiE 'Both halves of the proof standard were met' "$m"; then
    echo "$wf" >> "$WORK/proven.txt"
  else
    echo "$wf	$(basename "$m")" >> "$WORK/notproven.txt"
  fi
done
sort -u -o "$WORK/proven.txt" "$WORK/proven.txt"
PROVEN_TYPES=$(wc -l < "$WORK/proven.txt")
# Workflows whose ONLY manifests are blocked/partial -- these must never be counted as proven.
BLOCKED_ONLY=0
if [ -s "$WORK/notproven.txt" ]; then
  while IFS=$'\t' read -r bwf _f; do
    grep -qx "$bwf" "$WORK/proven.txt" || BLOCKED_ONLY=$((BLOCKED_ONLY+1))
  done < "$WORK/notproven.txt"
fi

MANIFESTS=$(ls "$EVID"/*live-write*.md 2>/dev/null | wc -l)
UNPARSED=$((MANIFESTS - $(grep -lE '\*\*Workflow:\*\* `[a-z0-9-]+`' "$EVID"/*live-write*.md 2>/dev/null | wc -l)))

# A control. If this known-proven type is absent the parse is broken, not the evidence.
if ! grep -qx 'garden-tool-loan' "$WORK/proven.txt"; then
  echo "WARNING: control 'garden-tool-loan' not found among parsed manifests --"
  echo "         treat the numbers below as suspect; the parse, not the evidence, is likely wrong."
fi

# --- how many of the real rows have a live-write naming their workflow ----------------------------
MATCHED=0
while IFS=$'\t' read -r _c wf; do
  case "$wf" in ⛔*) continue;; esac
  grep -qx "$wf" "$WORK/proven.txt" && MATCHED=$((MATCHED+1))
done < "$WORK/rows.tsv"

JUDGE=$(ls "$EVID" 2>/dev/null | grep -icE 'judge|ux-review' || true)
# screenRowId values are SCREENS, not bar rows. There are 204 of them against a 72-row bar,
# and the ids read like b25-v4-row-NNN-<slug> which makes them look joinable. They are not.
SCREENS=$(grep -hoE '"screenRowId": "b25-v4-row-[0-9]+' "$EVID"/*.json 2>/dev/null \
  | grep -oE 'row-[0-9]+' | sort -u | wc -l)

cat <<REPORT

B25 status -- $(date +%Y-%m-%d)

  denominator
    rows in the addendum tables      $TOTAL
    marked NOT A WORKFLOW by the doc  -$DISCLAIMED
    REAL ROWS                         $REAL

  walkthrough half
    live-write manifests              $MANIFESTS   (unparsed: $UNPARSED)
    distinct workflow types PROVEN    $PROVEN_TYPES   (success phrase present)
    manifests recording NOT-proven    $(wc -l < "$WORK/notproven.txt" 2>/dev/null || echo 0)   (blocked or partial)
    workflows with ONLY a failed run  $BLOCKED_ONLY   (must never be counted)
    REAL ROWS WITH A LIVE WRITE       $MATCHED

  judge half
    judge/UX-review artifacts         $JUDGE
    distinct screenRowId values       $SCREENS   (SCREENS, not bar rows -- see below)

  A row is proven only with BOTH halves. This reports the walkthrough half ONLY, and the
  judge half is not merely uncounted -- it is UNCOMPUTABLE from these artifacts. They are
  keyed by screenRowId, and those are SCREENS: $SCREENS distinct values against a $REAL-row
  bar. No artifact records a judge verdict against a B25 row.

  The ids look like b25-v4-row-008-garden-export-custom-schemas-1, so screenRowId reads as
  a bar row and even embeds a plausible workflow slug. It is not one. Do NOT join on that
  slug -- the slugs are screen subjects, not workflow types, and the resemblance is what
  makes the wrong join attractive.

  So do NOT quote "$MATCHED of $REAL" as the bar. It is an upper bound on one half.

  Manifests written before 2026-09-09 record no package identity, so a match proves the
  row against whatever the package was that day, not against the package today.
REPORT
