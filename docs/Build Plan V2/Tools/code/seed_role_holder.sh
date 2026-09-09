#!/bin/bash
# data/seed_role_holder.sh <slug> <groupId> <roleId> <adminUser>
#
# Adds ONE additional test user holding <roleId> in <groupId>, through the real
# authorization flow -- never a direct database insert. The 2026-08-30 seeding
# run established that path and it is the one that proves the security boundary:
# a fan requests membership for themselves, and a community admin approves and
# grants the role. A fan cannot self-approve.
#
# Why this exists: the user's locked decision is that every role gets SEVERAL
# seeded backend users, and community JSON carries no user ids. The 2026-08-30
# run created exactly one account per role and recorded that a second was "cheap
# to add and has not been done" -- which is what left 36 of 37 roles with a
# single holder and silently killed every two-party same-role interaction.
#
# Convention (from that run): Keycloak `loom-<slug>`, fan id `fan-<slug>`,
# password LoomTest123!. The fanId ATTRIBUTE is load-bearing: an account without
# it authenticates and then fails every authorization check, so this script
# verifies the claim in a real token rather than trusting the create.
set -euo pipefail
SLUG="${1:?usage: seed_role_holder.sh <slug> <groupId> <roleId> <adminUser>}"
GROUP="${2:?groupId}"
ROLE="${3:?roleId}"
ADMIN="${4:?admin keycloak username}"
# The deployed service requires X-Loom-Actor even though the OpenAPI description
# for requestGroupMembership says the fan "is taken from the token rather than
# the path". Drift between the written contract and the running service, found
# 2026-09-08 by the 400 it returns. Derive the admin's fan id from the seeded
# convention: keycloak `loom-<slug>` -> fan `fan-<slug>`.
ADMIN_FAN="fan-${ADMIN#loom-}"
APP_ID="${LOOM_APP_ID:-loom_communities}"
PASS="LoomTest123!"
USERNAME="loom-$SLUG"
FANID="fan-$SLUG"

cleanup() { [ -n "${KC_PF:-}" ] && kill "$KC_PF" 2>/dev/null; [ -n "${AA_PF:-}" ] && kill "$AA_PF" 2>/dev/null; true; }
trap cleanup EXIT

kubectl port-forward -n loom svc/keycloak 18081:8080 >/dev/null 2>&1 & KC_PF=$!
kubectl port-forward -n loom svc/app-access 18080:8080 >/dev/null 2>&1 & AA_PF=$!
sleep 6

KU=$(kubectl get secret keycloak-admin-credentials -n loom -o jsonpath='{.data.username}' | base64 -d)
KP=$(kubectl get secret keycloak-admin-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
KT=$(curl -s -d "client_id=admin-cli" -d "username=$KU" -d "password=$KP" -d "grant_type=password" \
  http://127.0.0.1:18081/realms/master/protocol/openid-connect/token | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
[ -n "$KT" ] || { echo "FAIL: no keycloak admin token"; exit 1; }

# 1. Create the account (409 = already there, which is fine and idempotent).
cat > /tmp/seed_user.json <<JSON
{"username":"$USERNAME","firstName":"Test","lastName":"$ROLE","email":"$USERNAME@loom.test",
 "emailVerified":true,"enabled":true,"attributes":{"fanId":["$FANID"]},
 "credentials":[{"type":"password","value":"$PASS","temporary":false}]}
JSON
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $KT" \
  -H "Content-Type: application/json" --data @/tmp/seed_user.json \
  "http://127.0.0.1:18081/admin/realms/loom/users")
echo "  [$USERNAME] keycloak create: $CODE"
case "$CODE" in 201|409) ;; *) echo "FAIL: unexpected create status"; exit 1 ;; esac

# 2. Prove the fanId claim is really in a token. The create succeeding is not
#    evidence of this -- the attribute is what the mapper emits.
FT=$(curl -s -d "client_id=loom-test-client" -d "username=$USERNAME" -d "password=$PASS" \
  -d "grant_type=password" -d "scope=openid" \
  http://127.0.0.1:18081/realms/loom/protocol/openid-connect/token | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
[ -n "$FT" ] || { echo "FAIL: $USERNAME cannot obtain a token"; exit 1; }
# JWT payloads are base64url WITHOUT padding, so a bare `base64 -d` exits
# non-zero and, under `set -euo pipefail`, killed this script silently after the
# create step -- no message, no clue. Pad to a multiple of 4 first, and tolerate
# a decode failure explicitly rather than letting it end the run.
PAYLOAD=$(echo "$FT" | cut -d. -f2 | tr '_-' '/+')
case $(( ${#PAYLOAD} % 4 )) in 2) PAYLOAD="$PAYLOAD==";; 3) PAYLOAD="$PAYLOAD=";; esac
CLAIM=$(printf '%s' "$PAYLOAD" | base64 -d 2>/dev/null | grep -o '"fanId":"[^"]*' | cut -d'"' -f4 || true)
[ "$CLAIM" = "$FANID" ] || { echo "FAIL: token fanId is '$CLAIM', expected '$FANID'"; exit 1; }
echo "  [$USERNAME] fanId claim verified in a real token: $CLAIM"

# 3. The fan requests membership FOR THEMSELVES (fan comes from the token).
RC=$(curl -s -o /tmp/seed_req.json -w "%{http_code}" -X POST -H "Authorization: Bearer $FT" \
  -H "Content-Type: application/json" -H "X-Loom-Correlation-Id: $(cat /proc/sys/kernel/random/uuid)" \
  -H "Idempotency-Key: $(cat /proc/sys/kernel/random/uuid)" \
  -H "X-Loom-Actor: $FANID" \
  -d '{}' "http://127.0.0.1:18080/v1/apps/$APP_ID/groups/$GROUP/membership-requests")
echo "  [$USERNAME] membership request: $RC"
case "$RC" in 200|201|409) ;; *) echo "FAIL: request rejected"; head -c 300 /tmp/seed_req.json; exit 1 ;; esac

# 4. The community admin approves and grants the role. A fan cannot self-approve;
#    that separation is the whole point of using this path.
AT=$(curl -s -d "client_id=loom-test-client" -d "username=$ADMIN" -d "password=$PASS" \
  -d "grant_type=password" -d "scope=openid" \
  http://127.0.0.1:18081/realms/loom/protocol/openid-connect/token | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
[ -n "$AT" ] || { echo "FAIL: admin $ADMIN cannot obtain a token"; exit 1; }
DC=$(curl -s -o /tmp/seed_dec.json -w "%{http_code}" -X POST -H "Authorization: Bearer $AT" \
  -H "Content-Type: application/json" -H "X-Loom-Correlation-Id: $(cat /proc/sys/kernel/random/uuid)" \
  -H "Idempotency-Key: $(cat /proc/sys/kernel/random/uuid)" \
  -H "X-Loom-Actor: $ADMIN_FAN" \
  -d "{\"decision\":\"approve\",\"roleIds\":[\"$ROLE\"]}" \
  "http://127.0.0.1:18080/v1/apps/$APP_ID/groups/$GROUP/membership-requests/$FANID/decision")
echo "  [$USERNAME] admin decision: $DC"
case "$DC" in 200|201) ;; *) echo "FAIL: approval rejected"; head -c 300 /tmp/seed_dec.json; exit 1 ;; esac
grep -o '"state":"[^"]*"' /tmp/seed_dec.json | head -1 | sed 's/^/  /'
echo "  [$USERNAME] DONE"
