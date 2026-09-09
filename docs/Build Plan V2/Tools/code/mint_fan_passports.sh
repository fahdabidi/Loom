#!/bin/bash
# data/mint_fan_passports.sh [fan-id-suffix-filter]
#
# Mints the missing Fan Passport record for seeded test fans.
#
# WHY THIS EXISTS -- a failure worth not repeating. On 2026-09-08 I seeded 23
# additional role holders, verified them in App Access (`group_membership_role`
# showed 24 of 37 roles with 2+ holders), and reported the job done. Every one of
# them was unusable: the seeding wrote Keycloak + App Access and skipped Fan
# Passport, so not one of the 23 could sign in. They had been seeded specifically
# to unblock two-party interactions.
#
# The mistake was verifying the layer I had just written to instead of the
# capability. A fan needs THREE things to be real:
#   1. a Keycloak account carrying the `fanId` attribute (authentication)
#   2. a Fan Passport record                            (identity)
#   3. an App Access membership + role grant            (authorization)
# Missing any one of them still looks correct from the other two.
#
# Order matters: the passport is minted FIRST in a clean seeding run. This script
# is the repair path for fans that already exist without one.
set -euo pipefail
FILTER="${1:--2}"
PASS="LoomTest123!"

cleanup() { [ -n "${KC_PF:-}" ] && kill "$KC_PF" 2>/dev/null; [ -n "${FP_PF:-}" ] && kill "$FP_PF" 2>/dev/null; true; }
trap cleanup EXIT

kubectl port-forward -n loom svc/keycloak 18081:8080 >/dev/null 2>&1 & KC_PF=$!
kubectl port-forward -n loom svc/fan-passport 18082:8080 >/dev/null 2>&1 & FP_PF=$!
sleep 6

KU=$(kubectl get secret keycloak-admin-credentials -n loom -o jsonpath='{.data.username}' | base64 -d)
KP=$(kubectl get secret keycloak-admin-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
KT=$(curl -s -d "client_id=admin-cli" -d "username=$KU" -d "password=$KP" -d "grant_type=password" \
  http://127.0.0.1:18081/realms/master/protocol/openid-connect/token | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
[ -n "$KT" ] || { echo "FAIL: no keycloak admin token"; exit 1; }

USERS=$(curl -s -H "Authorization: Bearer $KT" "http://127.0.0.1:18081/admin/realms/loom/users?max=300" \
  | grep -o '"username":"[^"]*' | cut -d'"' -f4 | grep -- "$FILTER$" || true)
[ -n "$USERS" ] || { echo "no users match filter '$FILTER'"; exit 0; }
echo "candidates: $(echo "$USERS" | wc -l)"

OK=0; SKIP=0; FAIL=0
for U in $USERS; do
  FT=$(curl -s -d "client_id=loom-test-client" -d "username=$U" -d "password=$PASS" -d "grant_type=password" \
    -d "scope=openid" http://127.0.0.1:18081/realms/loom/protocol/openid-connect/token \
    | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
  if [ -z "$FT" ]; then echo "  $U: no token (skipping)"; FAIL=$((FAIL+1)); continue; fi
  DISPLAY="Test ${U#loom-}"
  CODE=$(curl -s -o /tmp/mint.json -w "%{http_code}" -X POST \
    -H "Authorization: Bearer $FT" -H "Content-Type: application/json" \
    -H "X-Loom-Correlation-Id: $(cat /proc/sys/kernel/random/uuid)" \
    -H "Idempotency-Key: $(cat /proc/sys/kernel/random/uuid)" \
    -d "{\"displayName\":\"$DISPLAY\"}" "http://127.0.0.1:18082/v1/fan-passports")
  case "$CODE" in
    200|201) echo "  $U: minted ($CODE)"; OK=$((OK+1)) ;;
    409)     echo "  $U: already had one ($CODE)"; SKIP=$((SKIP+1)) ;;
    *)       echo "  $U: FAILED ($CODE) $(head -c 160 /tmp/mint.json)"; FAIL=$((FAIL+1)) ;;
  esac
done
echo "minted=$OK already=$SKIP failed=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
