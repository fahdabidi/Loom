#!/bin/bash
# data/verify_apk_freshness.sh
#
# Cheap guard against silently stale Flutter/Gradle builds. Added after a
# real incident (2026-08-02/03): `flutter build apk --debug` reported success
# but silently reused a 9-day-old cached APK -- Gradle's incremental
# up-to-date check was fooled, most likely because this repo lives on a
# WSL2-mounted Windows path (/mnt/c/..., drvfs), where file-change signals
# don't always reliably reach Gradle's mtime-based staleness detection. The
# stale APK's compiled Dart kernel was missing a formula function
# (`combineDateAndTime`) added a week after that cached build was produced,
# which only surfaced as a live runtime crash during a device walkthrough --
# something none of `flutter analyze`/`flutter test`/the JSON validators
# could ever catch, since none of them build or run a compiled APK.
#
# This script extracts assets/flutter_assets/kernel_blob.bin from a built
# debug APK and greps it directly for a string that should be present if the
# build is current (e.g. a function/class name from the most recent
# engine-touching commit). Zero matches means the APK almost certainly
# predates that change -- do a real `flutter clean` and rebuild before
# trusting anything installed from it.
#
# Usage:
#   bash data/verify_apk_freshness.sh <path-to-apk> <must-contain-string> [<must-contain-string> ...]
#
# Example (the exact incident this script would have caught):
#   bash data/verify_apk_freshness.sh \
#     app/apps/loom_communities_demo/build/app/outputs/flutter-apk/app-debug.apk \
#     combineDateAndTime
#
# Exit 0 if every string is found at least once; exit 1 (with a clear
# message naming the missing string) otherwise. Intended as a pre-flight
# check before any live emulator/device walkthrough in this repo -- run it
# right after `flutter build apk`, before `adb install`.

set -euo pipefail

APK_PATH="${1:?usage: verify_apk_freshness.sh <apk-path> <must-contain-string> [...]}"
shift
if [ "$#" -eq 0 ]; then
  echo "ERROR: at least one must-contain string is required" >&2
  exit 1
fi

if [ ! -f "$APK_PATH" ]; then
  echo "ERROR: APK not found: $APK_PATH" >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

unzip -q -o -d "$WORKDIR" "$APK_PATH" assets/flutter_assets/kernel_blob.bin
KERNEL="$WORKDIR/assets/flutter_assets/kernel_blob.bin"

if [ ! -f "$KERNEL" ]; then
  echo "ERROR: $APK_PATH has no assets/flutter_assets/kernel_blob.bin -- is this a release/AOT build?" >&2
  echo "This script only supports debug (JIT/kernel-blob) builds." >&2
  exit 1
fi

echo "Checking $APK_PATH (kernel_blob.bin: $(wc -c < "$KERNEL") bytes)"

STATUS=0
for needle in "$@"; do
  count="$(grep -a -c "$needle" "$KERNEL" || true)"
  if [ "$count" -eq 0 ]; then
    echo "MISSING: \"$needle\" not found in compiled kernel -- this build is likely stale. Run a real \`flutter clean\` and rebuild." >&2
    STATUS=1
  else
    echo "OK: \"$needle\" found ($count occurrence(s))"
  fi
done

exit "$STATUS"
