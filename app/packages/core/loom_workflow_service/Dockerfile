# Builds a self-contained native binary for loom_workflow_service.
#
# This package is a member of a melos workspace that also has 25 Flutter-SDK
# workspace members (feature packages, the app shells). `dart pub get` cannot
# resolve that workspace on its own -- only `flutter pub get` understands an
# `sdk: flutter` constraint -- and installing the full Flutter SDK just to
# resolve dependencies for a package that itself only needs plain Dart would
# make this build far heavier than it needs to be.
#
# Instead this Dockerfile compiles directly against a workspace that has
# already been resolved on the host (via `melos bootstrap` /
# `flutter pub get` at the workspace root) and never re-resolves anything
# itself. `.dart_tool/package_config.json` records that resolution using
# absolute `file://` paths rooted at the host's home directory, so the build
# context must replicate that exact absolute path layout -- see build.sh,
# which stages `~/.pub-cache` and `~/Loom/app` into a scratch directory before
# invoking `docker build` from there.
#
# The build stage's Dart SDK version must match the host's exactly (check
# with `dart --version` before building) -- a version mismatch invalidates
# native build hooks cached in .dart_tool (this project depends on `sqlite3`,
# which has one) and `dart compile exe` refuses to re-run them inline,
# failing with "does not support build hooks, use 'dart build' instead."
FROM dart:3.11.5 AS build

COPY home/fahd/.pub-cache /home/fahd/.pub-cache
COPY home/fahd/Loom/app /home/fahd/Loom/app

RUN dart compile exe \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /home/fahd/Loom/app/packages/core/loom_workflow_service/bin/loom_workflow_service.dart \
    -o /workflow_service

FROM debian:bookworm-slim AS runtime
# A numeric uid:gid, not a named user -- Kubernetes' runAsNonRoot check
# cannot verify a named user is non-root without inspecting the image, and
# refuses to start the container rather than guess. 100:101 matches the
# convention already used by the sibling app-access/fan-passport images.
RUN groupadd -g 101 loom && useradd -u 100 -g 101 -r loom
COPY --from=build /workflow_service /app/workflow_service
RUN chown loom:loom /app/workflow_service
USER loom

EXPOSE 8080
ENTRYPOINT ["/app/workflow_service"]
