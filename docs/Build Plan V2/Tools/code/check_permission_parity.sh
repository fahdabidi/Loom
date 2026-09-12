#!/usr/bin/env bash
# check_permission_parity.sh -- do the LIVE App Access grants equal the
# permission sets each community package DERIVES?
#
# Why this exists, and how it differs from its sibling. `check_role_parity.sh`
# compares role EXISTENCE, which is exactly why it stayed green through the
# Masjid incident: on 2026-09-05 a regeneration renamed `masjid-admin` ->
# `owner`, the old role kept its 23 permissions and kept working, and the new
# name had no row at all -- four transitions became unreachable by anyone and
# nothing failed for weeks. A role can exist and still hold the wrong set.
# This gate compares **exact permission-id sets**, not counts, because
# swapping one wrong permission preserves the count.
#
# WHAT IT IS NOT. This gate **detects** drift; it does not prevent it, and
# nothing stops a deployment because of it unless the deployment depends on it
# passing. Write-time enforcement is a separate, already-landed concern.
#
# HOW IT WORKS, and why it is split this way:
#   expected -- one READ-ONLY call to POST /v1/apps/{appId}/community-permission-exports
#               per shipped package. The expected sets come from App Access's
#               real CommunityPermissionDeriver, never from a second
#               implementation of the derivation rules; a reimplementation
#               drifts, and the gate would then be diffing two guesses.
#   actual   -- one read of live `role_permission` the same way
#               `check_role_parity.sh` already reads it (direct
#               `kubectl exec postgres-0 -- psql`), so this needs Postgres
#               access but not a second HTTP round trip per role.
#
# IT WRITES NOTHING. No create, no grant, no reconcile. `role_permission` is
# the only grant table -- there is no per-fan and no per-instance grant -- so
# a permission attached to a workflow node would land on the role and widen
# authorization for every holder and every instance permanently. Node
# awareness lives in the analysis and the runtime report, never in granting.
#
# IT NEVER TREATS AN EMPTY SET AS A FAILURE. A read-only role derives nothing
# and is CORRECT: `portability-member` appears in five `readGuard`s and in no
# transition guard or create action, so it is owed no permission. The gate
# keys on whether the package PERMITS the role to act at all, never on the set
# being non-empty. Flagging it would prove the rule was implemented as
# "non-empty" instead of "permitted to act".
#
# Anything it could not process is PRINTED, and counts as drift. A silently
# skipped community hides exactly the case that would disprove the gate.
#
# Exit 1 on drift, matching the sibling gates' convention.
#
#   bash "docs/Build Plan V2/Tools/code/check_permission_parity.sh"
#   bash "docs/Build Plan V2/Tools/code/check_permission_parity.sh" --community=garden-club
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
PACKAGES="$REPO_ROOT/app/packages/core/loom_communities_app_shell/assets"
TOOL="$REPO_ROOT/app/packages/tooling/loom_permission_parity_gate"

# The dispatch host keeps its toolchain in a profile script that a
# non-interactive shell does not read -- without this, `dart` is simply
# "command not found".
[ -f "$HOME/.loom-env.sh" ] && . "$HOME/.loom-env.sh"

# App Access is reached through its NodePort from the host; Keycloak's token
# endpoint likewise. Both are overridable so the gate can be pointed at
# another cluster without editing this file.
export LOOM_APP_ACCESS_BASE_URL="${LOOM_APP_ACCESS_BASE_URL:-http://127.0.0.1:30080}"
export LOOM_KEYCLOAK_TOKEN_URL="${LOOM_KEYCLOAK_TOKEN_URL:-http://127.0.0.1:30082/realms/loom/protocol/openid-connect/token}"

# A DEDICATED provisioning identity, never the running workflow-service's own
# client. An earlier draft of this script defaulted to `loom-workflow-service`
# because that client already had the right grant shape (client-credentials) --
# but that client is the real, always-on identity the deployed workflow-service
# pod authenticates with for its own live traffic. Granting it provisioning
# authority (installCommunityPackage, createRole/deleteRole, role migration)
# would give a standing production identity capabilities it has no legitimate
# operational need for -- exactly the escalation shape P1 exists to prevent.
# Found and reverted 2026-09-12; `loom-app-access-provisioner` is a separate
# client created solely to hold the `app-access-provisioner` realm role, so a
# compromise of its secret is contained to "can run this gate," nothing else.
export LOOM_APP_ACCESS_CLIENT_ID="${LOOM_APP_ACCESS_CLIENT_ID:-loom-app-access-provisioner}"
if [ -z "${LOOM_APP_ACCESS_CLIENT_SECRET:-}" ]; then
  LOOM_APP_ACCESS_CLIENT_SECRET="$(kubectl get secret -n loom app-access-provisioner-credentials \
    -o jsonpath='{.data.client-secret}' 2>/dev/null | base64 -d)"
fi
[ -n "${LOOM_APP_ACCESS_CLIENT_SECRET:-}" ] || {
  echo "FAIL: could not read LOOM_APP_ACCESS_CLIENT_SECRET and none was supplied."
  exit 1
}
export LOOM_APP_ACCESS_CLIENT_SECRET
export LOOM_APP_ID="${LOOM_APP_ID:-loom_communities}"

cd "$TOOL"
exec dart run bin/check_permission_parity.dart "$PACKAGES" "$@"
