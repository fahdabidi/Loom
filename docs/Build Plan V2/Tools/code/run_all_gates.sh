#!/usr/bin/env bash
# run_all_gates.sh — run every gate in this directory and report one consolidated table.
#
# WHY THIS EXISTS. There were 10 gates here and nothing ran them together, which is the failure
# CLAUDE.md records in its own words: "that gate existed and reported six real violations for days
# while nobody ran it: a gate nobody runs is a gate that does not exist." Two of those gates I
# added myself and then invoked only from memory, so this is that lesson applied to my own work.
#
# THREE OUTCOMES, and the third is the point. PASS, FAIL, and SKIPPED-with-a-reason. A skipped
# gate is never silently omitted and never counted as a pass; the summary names it and says why.
# Only FAIL makes this script exit non-zero -- the same deliberate choice as the dispatcher's
# verification gate, where punishing an honest gap would push the next run toward faking numbers.
#
# INTERPRETER PROBING, because a presence check can pass for the wrong reason. On Windows
# `command -v python3` resolves to the Microsoft Store STUB, which prints "Python was not found"
# and exits non-zero. So this probes that the interpreter actually RUNS before using it, rather
# than trusting that it resolves.
#
# --with-cluster also runs the three gates that need kubectl and live credentials. Without it they
# are SKIPPED, because a cluster gate that cannot reach the cluster is not a result.
set -uo pipefail
cd "$(dirname "$0")/../../../.." || exit 2
GDIR="docs/Build Plan V2/Tools/code"
WITH_CLUSTER=0
[ "${1:-}" = "--with-cluster" ] && WITH_CLUSTER=1

PY=""
for cand in python3 python; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'pass' >/dev/null 2>&1; then PY="$cand"; break; fi
done

# check_spec_parity.sh is OFFLINE but VM-ONLY: it compares the Loom repo against the
# BACKEND repo, which exists only on the VM. Measured 2026-10-10 -- it exits 2 on Windows
# with "not found", and passes on the VM (8 identical, 0 differ, 0 missing). That is a host
# requirement, not a defect, so reporting FAIL here would make this runner permanently red
# on the machine it is most often invoked from -- the always-noisy guard this project warns
# gets scrolled past.
OFFLINE_SH="check_ticket_baselines.sh check_tracker_row_detail_parity.sh check_b25_status.sh"
NEEDS_BACKEND_SH="check_spec_parity.sh"
OFFLINE_PY="check_orphan_summary_bindings.py check_b25_judge_verdicts.py audit_visibility_expressiveness.py"
CLUSTER_SH="check_role_parity.sh check_permission_parity.sh check_published_definitions.sh"

pass=0; fail=0; skip=0
declare -a ROWS=()

record() { ROWS+=("$1|$2|$3"); case "$2" in PASS) pass=$((pass+1));; FAIL) fail=$((fail+1));; *) skip=$((skip+1));; esac; }

run_gate() { # $1 label, $2... command
  local label="$1"; shift
  local out rc
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" = "0" ]; then record "$label" PASS "exit 0"
  else
    record "$label" FAIL "exit $rc -- $(printf '%s' "$out" | grep -viE '^$' | tail -1 | cut -c1-72)"
  fi
}

for g in $OFFLINE_SH; do
  [ -f "$GDIR/$g" ] || { record "$g" SKIPPED "not present in $GDIR"; continue; }
  run_gate "$g" bash "$GDIR/$g"
done

for g in $OFFLINE_PY; do
  [ -f "$GDIR/$g" ] || { record "$g" SKIPPED "not present"; continue; }
  [ -n "$PY" ] || { record "$g" SKIPPED "no WORKING python interpreter (a resolvable stub is not one)"; continue; }
  run_gate "$g" "$PY" "$GDIR/$g"
done

for g in $NEEDS_BACKEND_SH; do
  [ -f "$GDIR/$g" ] || { record "$g" SKIPPED "not present"; continue; }
  if [ ! -d "$HOME/loom-backend" ]; then
    record "$g" SKIPPED "needs the loom-backend repo at $HOME/loom-backend (VM-only); passes there"
    continue
  fi
  run_gate "$g" bash "$GDIR/$g"
done

for g in $CLUSTER_SH; do
  [ -f "$GDIR/$g" ] || { record "$g" SKIPPED "not present"; continue; }
  if [ "$WITH_CLUSTER" = "0" ]; then
    record "$g" SKIPPED "needs kubectl + live credentials; re-run with --with-cluster"
    continue
  fi
  run_gate "$g" bash "$GDIR/$g"
done

echo "======================================================================"
printf '%-38s %-8s %s\n' "GATE" "VERDICT" "DETAIL"
for r in "${ROWS[@]}"; do
  IFS='|' read -r a b c <<< "$r"
  printf '%-38s %-8s %s\n' "$a" "$b" "$c"
done
echo "----------------------------------------------------------------------"
echo "pass=$pass  fail=$fail  skipped=$skip"
[ "$WITH_CLUSTER" = "0" ] && echo "NOTE: cluster gates were SKIPPED, not passed. Re-run with --with-cluster on a host that can reach it."
[ -z "$PY" ] && echo "NOTE: python gates were SKIPPED -- no working interpreter here. The VM has one at /usr/bin/python3."
if [ "$fail" -gt 0 ]; then
  echo "At least one gate FAILED. A skipped gate is not a pass; read the table before concluding anything."
  exit 1
fi
echo "No gate FAILED. This is not 'everything is verified' -- $skip gate(s) did not run."
exit 0
