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
# Rows that are not workflows at all. Masjid's product doc header states that `wf_`-prefixed ids are
# literal Dart `testWidgets` names for the B18/B19/B20 integration tests, that no
# `LoomWorkflowDefinition` with those ids exists, and that no JSON should ever be authored for them --
# yet its own addendum tables still list five of them, which is what inflated the quoted denominator.
#
# The exclusion lives HERE and not in the product doc. Annotating the doc's first column was tried on
# 2026-09-09 and broke `b25_interaction_model_asset_conformance_test.dart`: that column is a parsed
# contract, the interaction-model asset is generated from it, and the annotation became part of a
# `workflowId` VALUE. Marking a row for humans corrupted a machine key. The `wf_` prefix is already an
# unambiguous namespace marker, so match on it and leave the doc alone.
DISCLAIMED=$(grep -cE $'\t(⛔|wf_)' "$WORK/rows.tsv" || true)
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
  case "$wf" in ⛔*|wf_*) continue;; esac
  grep -qx "$wf" "$WORK/proven.txt" && MATCHED=$((MATCHED+1))
done < "$WORK/rows.tsv"

# --- the judge half: keyed by workflowId, which IS the bar's key -----------------------------------
# An earlier version of this script claimed the judge half was UNCOMPUTABLE because the artifacts
# are keyed by screenRowId and there are 204 of those against a 72-row bar. That was wrong, and the
# error is worth naming: screenRowId is a SCREEN (roughly three per row -- entry, action, result),
# and it is *derived from* workflowId, so its embedded slug looks like a bar key without being one.
# The real key was there all along: 95 artifacts carry a "workflowId" field whose values are genuine
# workflow types, alongside a "persona". Do not join on the screenRowId slug; join on workflowId.
#
# Some workflowId values are comma-joined lists or prose, so restrict to single clean tokens.
# And restrict to the ACTUAL judge artifacts: this directory also holds remediation plans,
# iteration scorecards, freshness gates and reconciliation reports, several of which carry a
# workflowId of their own. Globbing *.json returned the same 55 here -- by coincidence, not by
# construction. Check what a directory holds before globbing it.
grep -hoE '"workflowId": "[a-z0-9_-]+"' \
  "$EVID"/llm-vision-ux-review*.json \
  "$EVID"/independent-production-ux-review*.json 2>/dev/null \
  | sed 's/.*: "//;s/"//' | sort -u > "$WORK/judged.txt"
# Judge verdicts also arrive as markdown, and the JSON-only scan could not see them. A UX judge run
# on 2026-09-09 produced a PASS for garden-tool-loan that this tool would have ignored, because the
# verdict was a .md outside the JSON glob -- the measurement could not see the work that had just
# been done for it. Scan both: the historical JSON artifacts, and verdict markdown that names its
# workflow the same way the walkthrough manifests do.
grep -hoE '\*\*Workflow:\*\* `[a-z0-9-]+`' "$EVID"/*ux-judge*.md 2>/dev/null \
  | grep -oE '`[a-z0-9-]+`' | tr -d '`' >> "$WORK/judged.txt"
sort -u -o "$WORK/judged.txt" "$WORK/judged.txt"
JUDGED_TYPES=$(wc -l < "$WORK/judged.txt")
JUDGE=$(ls "$EVID" 2>/dev/null | grep -icE 'judge|ux-review' || true)
SCREENS=$(grep -hoE '"screenRowId": "b25-v4-row-[0-9]+' "$EVID"/*.json 2>/dev/null \
  | grep -oE 'row-[0-9]+' | sort -u | wc -l)

JUDGED_ROWS=0
while IFS=$'\t' read -r _c wf; do
  case "$wf" in ⛔*|wf_*) continue;; esac
  grep -qx "$wf" "$WORK/judged.txt" && JUDGED_ROWS=$((JUDGED_ROWS+1))
done < "$WORK/rows.tsv"

# Both halves, for the same row.
BOTH=0
while IFS=$'\t' read -r _c wf; do
  case "$wf" in ⛔*|wf_*) continue;; esac
  if grep -qx "$wf" "$WORK/judged.txt" && grep -qx "$wf" "$WORK/proven.txt"; then
    BOTH=$((BOTH+1))
  fi
done < "$WORK/rows.tsv"

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
    distinct workflowId values judged $JUDGED_TYPES
    REAL ROWS WITH A JUDGE ARTIFACT   $JUDGED_ROWS
    distinct screenRowId values       $SCREENS   (screens, ~3 per row -- NOT a bar key)

  both halves
    REAL ROWS WITH WALKTHROUGH+JUDGE  $BOTH   <-- the bar

  A row needs BOTH halves. An earlier version of this script called the judge half
  UNCOMPUTABLE because the artifacts are keyed by screenRowId and there are $SCREENS of
  those against a $REAL-row bar. That was wrong. screenRowId is a SCREEN -- roughly three
  per row -- and it is derived from workflowId, so its slug resembles a bar key without
  being one. The real key was always there: the artifacts carry "workflowId" and "persona".

  Caveat on the judge column: this counts rows with a judge artifact NAMING the workflow.
  It does not yet check that artifact's verdict for that row, so treat $JUDGED_ROWS and
  $BOTH as coverage, not as passes.

  Manifests written before 2026-09-09 record no package identity, so a match proves the
  row against whatever the package was that day, not against the package today.
REPORT
