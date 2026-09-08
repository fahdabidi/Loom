#!/bin/bash
# check_published_definitions.sh -- is every declared workflow type actually published?
#
# The third member of a family this repo already gates twice: the OpenAPI spec twins
# (check_spec_parity.sh) and the generated permissions-vocabulary twin. All three are
# a file or row that must mirror another and silently doesn't.
#
# This one had no gate until 2026-09-08, and the cost was concrete. Three declared
# workflow types were absent from the deployed catalog -- ad-off-notification,
# export-notification and hoa-document-access-request. Data Portability's case was the
# worst: all SEVEN of its createInstance effects, across six workflows, targeted
# export-notification, so the community had no working notification path at all.
#
# What makes it invisible is that a createInstance naming an unpublished type
# **returns success and does nothing**. No test fails, no route errors, no probe changes
# colour, and the transition that carries the effect completes normally. It was found
# only because a live walkthrough went looking for the instance the effect should have
# created.
#
# Usage:  bash check_published_definitions.sh [loom-repo]
# Exit:   0 every declared type is published, 1 drift found, 2 prerequisites missing.
#
# Requires kubectl access to the loom namespace (it reads the deployed catalog, not a file --
# the whole point is that the deployed copy is the thing that drifts).
set -uo pipefail
LOOM="${1:-$HOME/Loom}"
ASSETS="$LOOM/app/packages/core/loom_communities_app_shell/assets"
[ -d "$ASSETS" ] || { echo "not found: $ASSETS"; exit 2; }
command -v kubectl >/dev/null || { echo "kubectl not on PATH"; exit 2; }

PW="$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)"
[ -n "$PW" ] || { echo "could not read postgres-credentials"; exit 2; }

PUB="$(mktemp)"; trap 'rm -f "$PUB"' EXIT
kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" \
  psql -U loom -d loom_workflow_service -tAc \
  'select workflow_type from workflow_definitions order by 1' > "$PUB" 2>/dev/null
published=$(grep -c . "$PUB")
[ "$published" -gt 0 ] || { echo "no published definitions read -- check the cluster"; exit 2; }

# Control: a type that must always be present. If this fails the query is broken,
# not the catalog -- the distinction that makes an empty result mean something.
if ! grep -qx 'hoa-dues-payment' "$PUB"; then
  echo "CONTROL FAILED: hoa-dues-payment absent -- the query is wrong, not the catalog"; exit 2
fi

missing=0
for f in "$ASSETS"/Loom_Communities_Workflow_Engine_*.jsonc; do
  name=$(basename "$f" | sed 's/Loom_Communities_Workflow_Engine_//; s/_Example\.jsonc//')
  while IFS= read -r w; do
    [ -n "$w" ] || continue
    grep -qx "$w" "$PUB" || { printf "  MISSING  %-26s %s\n" "$name" "$w"; missing=$((missing+1)); }
  done < <(grep -oE '"workflowType"[[:space:]]*:[[:space:]]*"[^"]+"' "$f" | sed 's/.*: *"//; s/"$//' | sort -u)
done

echo "  ---"
printf "  published: %s   declared-but-unpublished: %s\n" "$published" "$missing"
if [ "$missing" -gt 0 ]; then
  echo "  DRIFT -- re-publish before trusting any effect that targets these types:"
  echo "    cd app/packages/core/loom_workflow_service"
  echo "    dart run bin/publish_workflow_definitions.dart          # dry run first"
  echo "    dart run bin/publish_workflow_definitions.dart --write"
  exit 1
fi
echo "  every declared workflow type is published"
