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
# The pub cache must keep the pre-resolved package sources, but it has no use
# for VCS metadata in an AOT compilation.
rsync -a --exclude='.git/' "$HOME/.pub-cache/" "$SCRATCH/home/fahd/.pub-cache/"
mkdir -p "$SCRATCH/home/fahd/Loom"
# Dart compiles against app/.dart_tool/package_config.json (see Dockerfile),
# so retain that workspace-root directory and its cached sqlite3 build hook.
# Every member's own .dart_tool, along with Flutter/build-runner outputs and
# tests, is regenerable and outside the entrypoint's import graph.
rsync -a \
  --exclude='/apps/**/build/' \
  --exclude='/packages/**/build/' \
  --exclude='/apps/**/.dart_tool/' \
  --exclude='/packages/**/.dart_tool/' \
  --exclude='/apps/**/test/' \
  --exclude='/packages/**/test/' \
  --exclude='/apps/**/test_fixtures/' \
  --exclude='/packages/**/test_fixtures/' \
  --exclude='/.dart_tool/build/' \
  --exclude='/.dart_tool/test/' \
  --exclude='/.dart_tool/test_tmp/' \
  --exclude='/.dart_tool/pub/bin/test/' \
  --exclude='.git/' \
  "$REPO_ROOT/app/" "$SCRATCH/home/fahd/Loom/app/"
cp "$(dirname "${BASH_SOURCE[0]}")/Dockerfile" "$SCRATCH/Dockerfile"

echo "Building loom-workflow-service:$IMAGE_TAG ..."
docker build --tag "loom-workflow-service:$IMAGE_TAG" "$SCRATCH"

echo "Built. Import into a k3s node with:"
echo "  docker save loom-workflow-service:$IMAGE_TAG | sudo k3s ctr images import -"
