#!/usr/bin/env bash
# check_role_parity.sh -- does every role a community package DECLARES actually exist in App Access?
#
# Why this exists. On 2026-09-05 a Skill regeneration renamed Masjid Nur's domain role
# `masjid-admin` -> `owner`. The 2026-08-26 install had succeeded, so the OLD role kept its 23
# permissions and kept working; nothing failed, no probe went red, no test broke. Only the NEW
# name had no row, and four transitions guarded on `byRoleIds: ["owner"]` became unreachable by
# anyone. It surfaced weeks later, only because a walkthrough tried to use the role.
#
# A roleId rename is a MIGRATION, not an edit. Install is not idempotent across one: the sweep
# deletes roles the package does not declare, and after a rename the package no longer declares
# the old name either -- so the stale role survives and the new one is never created.
#
# Run this after any package regeneration that touches roles, and as part of the post-deploy audit.
# Exit 1 on drift.
#
#   bash "docs/Build Plan V2/Tools/code/check_role_parity.sh"
#
# Reads only. It derives the DECLARED set from the shipped packages via the client-side plan
# deriver, and the LIVE set from app_access. It does not write, install, or repair anything.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
ASSETS="$REPO_ROOT/app/packages/core/loom_communities_app_shell/assets"
TOOL="$REPO_ROOT/app/packages/tooling/loom_app_access_provisioning"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Roles that are live-only ON PURPOSE. Each needs a reason, not just an entry -- an allowlist
# nobody justifies stops being a check and becomes a place to hide drift.
#   cedar_commons_hoa_*  : the UNDERSCORED duplicate group, pending its deletion decision
#   tabletop-*           : tabletop-club is a test fixture, never a shipped community
ALLOW_LIVE_ONLY='^loom_communities_cedar_commons_hoa\||^loom_communities_tabletop-club\|'

echo "=== deriving DECLARED roles from the shipped packages ==="
( cd "$TOOL" && dart run bin/derive_app_access_provisioning_plan.dart "$ASSETS" ) \
  > "$WORK/raw.json" 2>"$WORK/derive.err"
if [ ! -s "$WORK/raw.json" ]; then
  echo "FAIL: the plan deriver produced nothing. stderr:"; cat "$WORK/derive.err"; exit 1
fi
# The Dart toolchain prints "Running build hooks..." to stdout ahead of the JSON.
sed '0,/{/s/^[^{]*{/{/' "$WORK/raw.json" > "$WORK/plan.json"

python3 - "$WORK/plan.json" "$WORK/declared.txt" <<'PY'
import json, sys
plan = json.load(open(sys.argv[1]))
pairs = set()
for c in plan["communities"]:
    handle = c["request"]["communityHandle"]
    group = "loom_communities_" + handle
    for role in c["request"]["roles"]:
        pairs.add((group, role["roleId"]))
    # install also generates the governance admin from the vocabulary's idTemplate
    pairs.add((group, handle + "-admin"))
open(sys.argv[2], "w").write("\n".join(sorted(g + "|" + r for g, r in pairs)) + "\n")
print("declared role rows: %d" % len(pairs))
PY

echo "=== reading LIVE roles from app_access ==="
PW="$(kubectl get secret -n loom postgres-credentials -o jsonpath='{.data.password}' | base64 -d)"
[ -n "$PW" ] || { echo "FAIL: could not read the postgres password"; exit 1; }
kubectl exec -n loom postgres-0 -- env PGPASSWORD="$PW" psql -U loom -d loom_app_access -A -t -F'|' \
  -c "select group_id||'|'||role_id from app_role where group_id like 'loom_communities_%' order by 1;" \
  | tr -d ' \r' | grep -v '^$' | sort > "$WORK/live.txt"
echo "live role rows: $(wc -l < "$WORK/live.txt")"

# A control. If this row is missing the query is broken, not the corpus -- an empty diff from a
# broken query looks exactly like a clean bill of health.
CONTROL='loom_communities_chess-club|chess-owner'
if ! grep -qxF "$CONTROL" "$WORK/live.txt"; then
  echo "FAIL: control row '$CONTROL' is absent, so this query proves nothing about the rest."
  exit 1
fi
echo "control present: $CONTROL"

sort "$WORK/declared.txt" | grep -v '^$' > "$WORK/d.txt"
comm -13 "$WORK/live.txt" "$WORK/d.txt" > "$WORK/missing.txt"
comm -23 "$WORK/live.txt" "$WORK/d.txt" | grep -Ev "$ALLOW_LIVE_ONLY" > "$WORK/extra.txt"

STATUS=0
if [ -s "$WORK/missing.txt" ]; then
  echo
  echo "DRIFT -- DECLARED by a package but NOT provisioned in App Access:"
  sed 's/^/  /' "$WORK/missing.txt"
  echo "  Every transition guarded on one of these is unreachable by any account."
  echo "  Repair with createRole + setRolePermissions, NOT installCommunityPackage --"
  echo "  its sweep deletes undeclared group roles bypassing deleteRole's holder checks."
  STATUS=1
fi
if [ -s "$WORK/extra.txt" ]; then
  echo
  echo "DRIFT -- LIVE in App Access but declared by NO package (rename residue, or hand-made):"
  sed 's/^/  /' "$WORK/extra.txt"
  echo "  A stale role keeps working silently, which is why a rename fails invisibly."
  STATUS=1
fi
[ "$STATUS" = "0" ] && echo && echo "OK: package-declared roles and provisioned roles agree."
exit "$STATUS"
