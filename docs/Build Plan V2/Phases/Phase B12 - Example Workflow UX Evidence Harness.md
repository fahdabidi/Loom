# Phase B12 - Example Workflow UX Evidence Harness

## Goal

Create the repeatable evidence gate that proves visible workflow completion for every Loom
Communities example and test app.

## Required Deliverables

- `workflow-ui-evidence.json` evidence schema.
- Android emulator screenshot capture through `flutter drive`.
- Host-side screenshot writer and evidence manifest writer.
- B12 harness test proving every target has workflows and screenshot IDs.
- Evidence output under `docs/Build Plan V2/Evidence/B12/`.

## Completion Gate

Run from WSL Ubuntu:

```bash
cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/apps/loom_communities_demo"
flutter drive \
  --driver=test_driver/workflow_ui_evidence_test.dart \
  --target=integration_test/workflow_ui_evidence_test.dart \
  -d emulator-5554
```

The phase is complete only when the driver writes the B12 evidence manifest, screenshots exist, and
the focused B12 widget test plus normal gates pass.
