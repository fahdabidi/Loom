#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$APP_DIR/../../.." && pwd)"
EVIDENCE_ROOT="$REPO_ROOT/docs/Build Plan V2/Evidence"
LOG_PATH="$EVIDENCE_ROOT/B20/flutter-drive-workflow-ui-evidence.log"

mkdir -p "$EVIDENCE_ROOT/B20"

cd "$APP_DIR"
export WORKFLOW_EVIDENCE_ROOT="$EVIDENCE_ROOT"
export WORKFLOW_EVIDENCE_COMMAND_OUTPUT="$LOG_PATH"

flutter drive \
  --driver=test_driver/workflow_ui_evidence_test.dart \
  --target=integration_test/workflow_ui_evidence_test.dart \
  -d emulator-5554 \
  > "$LOG_PATH" 2>&1

cat "$LOG_PATH"
