#!/bin/bash
# app/packages/core/loom_workflow_service/build.sh
#
# Builds the loom-workflow-service Docker image. Requires the workspace to
# already be bootstrapped (melos bootstrap / flutter pub get at the repo's
# app/ root) -- see Dockerfile's own header comment for why this stages a
# pre-resolved workspace rather than resolving inside Docker.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
# The deployed tag has been bumped by hand before now (0.1.0 -> 0.2.1),
# which left this script building a version nobody deploys. Take it from
# the environment so the two cannot drift again.
IMAGE_TAG="${IMAGE_TAG:-0.1.0}"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

echo "Staging build context in $SCRATCH ..."
mkdir -p "$SCRATCH/home/fahd"
cp -r "$HOME/.pub-cache" "$SCRATCH/home/fahd/.pub-cache"
mkdir -p "$SCRATCH/home/fahd/Loom"
cp -r "$REPO_ROOT/app" "$SCRATCH/home/fahd/Loom/app"
cp "$(dirname "${BASH_SOURCE[0]}")/Dockerfile" "$SCRATCH/Dockerfile"

echo "Building loom-workflow-service:$IMAGE_TAG ..."
docker build --tag "loom-workflow-service:$IMAGE_TAG" "$SCRATCH"

echo "Built. Import into a k3s node with:"
echo "  docker save loom-workflow-service:$IMAGE_TAG | sudo k3s ctr images import -"
