#!/bin/bash
# data/make_b25_brief.sh <slug> <CommunityDisplayName> <workflowType> <keycloakUser> <fanId> <roleId> <baselineCount>
#
# Emits a B25 re-verification brief on stdout. Written after the first Cedar dispatch stalled 44
# minutes at the Keycloak form because its brief omitted credentials that were documented all along;
# every trap that cost time there is now baked in rather than re-remembered per community.
set -euo pipefail
SLUG="${1:?slug}"; NAME="${2:?display name}"; WF="${3:?workflowType}"
KCUSER="${4:?keycloak user}"; FANID="${5:?fan id}"; ROLE="${6:?roleId}"; BASE="${7:?baseline count}"
cat <<EOF
# B25 re-verification — $NAME, \`$WF\`

## Why this exists

A previous dispatch claimed a live write for this community. That claim is **reopened and
untrusted**: no corresponding row exists in the database today. Do not look for the old instance and
do not treat its absence as your failure — **you are creating a new one.**

## Sign-in — you have real credentials, use them

The app cannot write anything until you are authenticated: the remote engine refuses to send a
request without a bearer token, and the only token source is a stored OAuth session from a real
Keycloak login. A first attempt at this campaign stalled 44 minutes at the Keycloak form for want of
a password. You have one.

- Keycloak realm \`loom\` at \`192.168.56.10:30082\`, OAuth client \`loom-test-client\`
- Seeded convention: username \`loom-<slug>\`, fan id \`fan-<slug>\`, **password \`LoomTest123!\`**
- Sign in as **\`$KCUSER\`** (fan id \`$FANID\`, role \`$ROLE\`). If the workflow genuinely requires a
  different role, other seeded accounts for this community follow the same convention — **say so
  explicitly if you escalate**, and name the account you used.

Verified working 2026-09-08: a password-grant token request against \`loom-test-client\` returned
HTTP 200 with a real access token. If Keycloak rejects it in the browser, that is a real finding —
report it precisely rather than retrying blindly.

Two device traps that already cost time:
- Chrome's **first-run onboarding** intercepts the OAuth redirect the first time. Dismiss it.
- The identity picker **cannot impersonate**: the app compares the selected account id against the
  token's \`fanId\` and rejects a mismatch. Sign in as the identity you intend to act as.

## The proof standard (both halves required, in this one session)

1. **Drive \`$WF\` live on the device through the real UI**, as the role you authenticated as, to a
   terminal or clearly-advanced state.
2. **Independently confirm the row in Postgres, in this same session:**

       PW=\$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
       kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="\$PW" psql -U loom -d loom_workflow_service \
         -c "select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at from workflow_instances where workflow_type='$WF' order by created_at desc limit 5;"

**A screenshot alone is not sufficient. A row alone is not sufficient.** Report both, and say plainly
whether they agree — including \`created_by_fan_id\` and whether it matches the identity you drove.

## Baseline measured immediately before this dispatch — your control

\`workflow_instances\` held **$BASE** rows total, and **zero** of \`workflow_type = '$WF'\`. Any such row
afterwards is necessarily yours. A query returning nothing is a real negative result — report it.

## Rules

- **Report honestly, including failure.** If you cannot complete it — a permission refusal, a missing
  affordance, a crash, a screen you cannot pass — stop and report exactly where and what the device
  showed. A truthful "blocked at step N because X" is valuable. Never describe an outcome you did not
  observe, and never approximate a state you did not reach.
- **Do not use \`integration_test/on_device_remote_backend_proof_test.dart\` as a substitute.** It
  authenticates and then calls the engine directly rather than driving the UI, so it proves a
  different boundary — and it is stale.
- **Do not modify application code, community JSON, or any tracker**, and **do not create or reset any
  credential**. You may commit an evidence manifest, nothing else.
- Remote communities legitimately start **empty** (deliberate 2026-09-07 decision). Creating the
  instance is the point; there is no seed row to find.
- Detect ANR/crash dialogs via \`adb\` — Flutter-side text checks cannot see system dialogs.
- Backend is current: \`app-access:0.3.10\`, catalog reconciled (137 ids, all 9 \`calendar.*\`). A
  \`403\`/\`unknown_permission_id\` would be a genuine new finding, not an expected condition.

## Deliverable

The account and fan id you authenticated as, the path you drove, the final UI state, the DB row
(instance id, \`created_by_fan_id\`, \`current_state\`, created_at) or its absence, whether the two
agree, and any defect observed.
EOF
