#!/bin/bash
# app/packages/core/loom_workflow_service/build.sh
#
# Builds the loom-workflow-service Docker image. Requires the workspace to
# already be bootstrapped (melos bootstrap / flutter pub get at the repo's
# app/ root) -- see Dockerfile's own header comment for why this stages a
# pre-resolved workspace rather than resolving inside Docker.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

echo "Staging build context in $SCRATCH ..."
mkdir -p "$SCRATCH/home/fahd"
cp -r "$HOME/.pub-cache" "$SCRATCH/home/fahd/.pub-cache"
mkdir -p "$SCRATCH/home/fahd/Loom"
cp -r "$REPO_ROOT/app" "$SCRATCH/home/fahd/Loom/app"
cp "$(dirname "${BASH_SOURCE[0]}")/Dockerfile" "$SCRATCH/Dockerfile"

echo "Building loom-workflow-service:0.1.0 ..."
docker build --tag loom-workflow-service:0.1.0 "$SCRATCH"

echo "Built. Import into a k3s node with:"
echo "  docker save loom-workflow-service:0.1.0 | sudo k3s ctr images import -"
