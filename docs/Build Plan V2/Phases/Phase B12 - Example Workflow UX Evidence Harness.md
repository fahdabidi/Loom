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
cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app"
dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart \
  --device emulator-5554 \
  --evidence-root ../docs/Build\ Plan\ V2/Evidence
```

The phase is complete only when the driver writes the B12 evidence manifest, screenshots exist, and
the focused B12 widget test plus normal gates pass.
