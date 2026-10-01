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
#
# RECURSIVE since 2026-09-12, and the reason is worth keeping. These globs were flat, so a judge
# artifact one directory down was invisible -- and there are 28 of them, in phase-a-*/ and
# phase-a-legacy/*/ subdirectories, all matching these exact filename patterns. Measured that day:
# the flat and recursive scans produce the SAME bar, because every workflowId those 28 name is
# already covered by a top-level artifact. So this was a latent fragility, not a live undercount,
# and the fix is recorded as such rather than as a correction to any past figure.
# It is still worth fixing: the identical mistake on the WALKTHROUGH half did bite on 2026-09-09,
# when three completed runs were invisible because their manifests were filed outside this exact
# directory. A future judge run filed one level down would have been lost the same silent way.
find "$EVID" \
  \( -name 'llm-vision-ux-review*.json' -o -name 'independent-production-ux-review*.json' \) \
  -print0 2>/dev/null \
  | xargs -0 grep -hoE '"workflowId": "[a-z0-9_-]+"' 2>/dev/null \
  | sed 's/.*: "//;s/"//' | sort -u > "$WORK/judged.txt"
# Judge verdicts also arrive as markdown, and the JSON-only scan could not see them. A UX judge run
# on 2026-09-09 produced a PASS for garden-tool-loan that this tool would have ignored, because the
# verdict was a .md outside the JSON glob -- the measurement could not see the work that had just
# been done for it. Scan both: the historical JSON artifacts, and verdict markdown that names its
# workflow the same way the walkthrough manifests do.
find "$EVID" \( -name '*ux-judge*.md' -o -name 'ux-judge-verdict.md' \) -print0 2>/dev/null \
  | xargs -0 grep -hoE '\*\*Workflow:\*\* `[a-z0-9-]+`' 2>/dev/null \
  | grep -oE '`[a-z0-9-]+`' | tr -d '`' >> "$WORK/judged.txt"
sort -u -o "$WORK/judged.txt" "$WORK/judged.txt"
JUDGED_TYPES=$(wc -l < "$WORK/judged.txt")

# --- the judge half, by OUTCOME rather than by mention ---------------------------------------------
# Added 2026-09-28, after proving the gap with five concrete rows. Everything above answers "does a
# verdict NAME this row", which counted a FAILED row exactly like a passing one: on 2026-09-28 five
# rows judged FAIL (book-export-metadata, soccer-export-metadata, export-checksum-evidence,
# garden-export-custom-schemas, soccer-waiver-document) all sat inside the reported figure.
#
# The judge dispatcher now requires `**Outcome:** PASS|FAIL|UNPROVEN` on the line after each
# `**Workflow:**`. This reads that pair.
#
# DELIBERATELY ADDITIVE, and that is the whole design. The 51 pre-2026-09-28 verdicts carry no
# outcome line, so requiring PASS would have collapsed the bar to near zero -- technically honest and
# genuinely misleading, since many of those rows did pass. So the coverage figure is KEPT and
# relabelled, a confirmed-pass figure is added beside it, and the rows with no parseable outcome are
# PRINTED. A silently dropped input hides the case that disproves you, and the gap between the two
# numbers is the actual state of knowledge.
# ENGINE PROVENANCE, added 2026-10-01 for the user's live-backend decision. A PASS verdict is only
# bar-eligible if its frames came from the LIVE BACKEND; the 21 rows judged 2026-09-28 were judged on
# in-memory-engine frames, so their judge half does not count under that decision. The script used to
# print CONFIRMED=10 with no idea which engine produced the pixels -- a figure that was correct under a
# superseded standard and would have gone on being quoted. So the verdict must now SAY, in an
# `**Engine:**` line beside its `**Outcome:**` line, and a verdict that does not say lands in its own
# printed bucket rather than in the proven column. Same additive design as the outcome block above:
# nothing is dropped, the gap between the columns is the state of knowledge.
#
# The parser was restructured to buffer per row block and flush at the NEXT Workflow line, because the
# earlier version cleared `pending` the moment it saw an Outcome -- which would have silently discarded
# any Engine line written AFTER the outcome, and nothing guarantees the order. A/B'd against the
# previous implementation: PASS/FAIL/UNPROVEN/no-outcome counts are identical, so the restructure
# changes nothing about the outcome half.
: > "$WORK/judged_pass.txt"; : > "$WORK/judged_fail.txt"; : > "$WORK/judged_unproven.txt"
: > "$WORK/judged_nooutcome.txt"; : > "$WORK/judged_live.txt"; : > "$WORK/judged_notlive.txt"
while IFS= read -r -d '' vf; do
  awk '
    function flush() {
      if (pending != "") {
        print (out == "" ? "NOOUTCOME" : out) "\t" (eng == "" ? "UNRECORDED" : eng) "\t" pending
      }
      pending = ""; out = ""; eng = ""
    }
    # A new Workflow line flushes the PREVIOUS block. This has to be handled here rather than in
    # its own rule: awk takes the first matching rule and this pattern matches too, so a separate
    # `pending != "" && /Workflow/` rule can never fire. The first version of this counted 7 (one
    # per FILE) where the honest answer was 59 (one per ROW) -- a count measuring the thing counted
    # rather than the thing asked about, in the tool built to stop exactly that.
    /^\*\*Workflow:\*\* `[a-z0-9-]+`/ {
      flush()
      match($0, /`[a-z0-9-]+`/); pending = substr($0, RSTART+1, RLENGTH-2)
      next
    }
    # First outcome and first engine per block win. Neither clears `pending`, so the two lines may
    # appear in either order.
    pending != "" && /^\*\*Outcome:\*\*[[:space:]]*(PASS|FAIL|UNPROVEN)/ {
      if (out == "") { o = $0; match(o, /(PASS|FAIL|UNPROVEN)/); out = substr(o, RSTART, RLENGTH) }
      next
    }
    pending != "" && /^\*\*Engine:\*\*/ {
      if (eng == "") {
        e = $0; sub(/^\*\*Engine:\*\*[[:space:]]*/, "", e); gsub(/[^A-Za-z_-]/, "", e)
        eng = (e == "" ? "UNRECORDED" : e)
      }
      next
    }
    END { flush() }
  ' "$vf"
done < <(find "$EVID" \( -name '*ux-judge*.md' -o -name 'ux-judge-verdict.md' \) -print0 2>/dev/null) \
  | while IFS=$'\t' read -r outcome engine wf; do
      [ -n "$wf" ] || continue
      case "$outcome" in
        PASS)      echo "$wf" >> "$WORK/judged_pass.txt" ;;
        FAIL)      echo "$wf" >> "$WORK/judged_fail.txt" ;;
        UNPROVEN)  echo "$wf" >> "$WORK/judged_unproven.txt" ;;
        *)         echo "$wf" >> "$WORK/judged_nooutcome.txt" ;;
      esac
      # "live" means the frames are known to come from the deployed services. The accepted set is
      # NOT a guess: the harness writes `engine` from `LoomServiceBindingMode.name`, and that enum
      # (part52_service_binding_report.dart:4) has exactly three values -- remote, local,
      # unconfigured -- which map one-to-one onto the three buckets here. `remote` is live; `local`
      # and `unconfigured` are not. The synonyms below are tolerated for hand-written verdicts only.
      # IF THAT ENUM IS RENAMED, THIS GUARD GOES SILENTLY ALWAYS-ZERO, which is the exact failure
      # this gate was built to stop -- so the coupling is named here rather than left implicit.
      case "$engine" in
        remote|live|remote-backend|liveBackend)  echo "$wf" >> "$WORK/judged_live.txt" ;;
        *)                                       echo "$wf" >> "$WORK/judged_notlive.txt" ;;
      esac
    done
for f in judged_pass judged_fail judged_unproven judged_nooutcome judged_live judged_notlive; do
  [ -s "$WORK/$f.txt" ] && sort -u -o "$WORK/$f.txt" "$WORK/$f.txt" || : > "$WORK/$f.txt"
done
# A row is only "no outcome" if it never got one in ANY verdict.
if [ -s "$WORK/judged_nooutcome.txt" ]; then
  comm -23 "$WORK/judged_nooutcome.txt" <(cat "$WORK/judged_pass.txt" "$WORK/judged_fail.txt" \
    "$WORK/judged_unproven.txt" | sort -u) > "$WORK/nooutcome_only.txt" || true
else
  : > "$WORK/nooutcome_only.txt"
fi
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
BOTH_CONFIRMED=0
JUDGE_PASS_ROWS=0
JUDGE_FAIL_ROWS=0
JUDGE_UNPROVEN_ROWS=0
JUDGE_NOOUTCOME_ROWS=0
JUDGE_PASS_NOT_LIVE_ROWS=0
while IFS=$'\t' read -r _c wf; do
  case "$wf" in ⛔*|wf_*) continue;; esac
  if grep -qx "$wf" "$WORK/judged.txt" && grep -qx "$wf" "$WORK/proven.txt"; then
    BOTH=$((BOTH+1))
  fi
  grep -qx "$wf" "$WORK/judged_pass.txt"      && JUDGE_PASS_ROWS=$((JUDGE_PASS_ROWS+1))
  grep -qx "$wf" "$WORK/judged_fail.txt"      && JUDGE_FAIL_ROWS=$((JUDGE_FAIL_ROWS+1))
  grep -qx "$wf" "$WORK/judged_unproven.txt"  && JUDGE_UNPROVEN_ROWS=$((JUDGE_UNPROVEN_ROWS+1))
  # UNKNOWN by SUBTRACTION, not by detecting an absent line. The first version emitted a
  # marker from the markdown parser and counted 23, but many historical artifacts name their
  # rows in JSON, which that parser never reads -- so they were "named" yet invisible to it,
  # and 36 rows fell into neither column. Named-minus-outcome is correct whatever the artifact
  # format, and it cannot silently lose a row: the four columns now sum to the named total.
  if grep -qx "$wf" "$WORK/judged.txt" \
     && ! grep -qx "$wf" "$WORK/judged_pass.txt" \
     && ! grep -qx "$wf" "$WORK/judged_fail.txt" \
     && ! grep -qx "$wf" "$WORK/judged_unproven.txt"; then
    JUDGE_NOOUTCOME_ROWS=$((JUDGE_NOOUTCOME_ROWS+1))
  fi
  # The strict bar, NARROWED 2026-10-01: a confirmed PASS verdict, a live write, AND frames whose
  # verdict records a LIVE-BACKEND engine -- all three, for the same row. Without the third clause
  # this printed 10 for rows judged entirely on in-memory-engine frames.
  if grep -qx "$wf" "$WORK/judged_pass.txt" && grep -qx "$wf" "$WORK/proven.txt" && grep -qx "$wf" "$WORK/judged_live.txt"; then
    BOTH_CONFIRMED=$((BOTH_CONFIRMED+1))
  elif grep -qx "$wf" "$WORK/judged_pass.txt" && grep -qx "$wf" "$WORK/proven.txt"; then
    JUDGE_PASS_NOT_LIVE_ROWS=$((JUDGE_PASS_NOT_LIVE_ROWS+1))
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
    rows NAMED by a judge artifact    $JUDGED_ROWS   (coverage -- says nothing about the verdict)
    distinct screenRowId values       $SCREENS   (screens, ~3 per row -- NOT a bar key)

  judge half, BY OUTCOME (added 2026-09-28; only verdicts carrying an **Outcome:** line)
    rows judged PASS                  $JUDGE_PASS_ROWS
    rows judged FAIL                  $JUDGE_FAIL_ROWS
    rows judged UNPROVEN              $JUDGE_UNPROVEN_ROWS
    rows named with NO outcome line   $JUDGE_NOOUTCOME_ROWS   (pre-2026-09-28 verdicts; unknown, not passing)

  both halves
    coverage: named + live write      $BOTH   (the OLD figure -- includes FAILED rows)
    PASS + live write, engine NOT live $JUDGE_PASS_NOT_LIVE_ROWS   (judged on in-memory frames, or the verdict never said)
    CONFIRMED: PASS + live write + live engine  $BOTH_CONFIRMED   <-- the only one that means proven

  A row needs BOTH halves. An earlier version of this script called the judge half
  UNCOMPUTABLE because the artifacts are keyed by screenRowId and there are $SCREENS of
  those against a $REAL-row bar. That was wrong. screenRowId is a SCREEN -- roughly three
  per row -- and it is derived from workflowId, so its slug resembles a bar key without
  being one. The real key was always there: the artifacts carry "workflowId" and "persona".

  Caveat on the judge column, NARROWED 2026-09-28: "$JUDGED_ROWS named" and "$BOTH coverage"
  still say nothing about any verdict -- a row judged FAIL is counted there exactly like a
  row judged PASS, which was proven with five concrete failures on 2026-09-28. The outcome
  block above is the one that reads verdicts, and CONFIRMED ($BOTH_CONFIRMED) is the only
  figure that means proven. The $JUDGE_NOOUTCOME_ROWS rows with no outcome line are
  pre-2026-09-28 verdicts: unknown, not passing. Re-judging them is what closes that gap;
  the judge dispatcher now requires an **Outcome:** line so no new verdict can join them.

  Manifests written before 2026-09-09 record no package identity, so a match proves the
  row against whatever the package was that day, not against the package today.
REPORT
