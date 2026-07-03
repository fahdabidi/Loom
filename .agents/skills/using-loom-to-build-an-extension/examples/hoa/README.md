# HOA Example Extension

Status: Phase B4 local workflow example.

This example extension validates the HOA headline path in the Demo Loom Communities App with Local
Backend.

## Included Flow

- Dues payment.
- Member-visible governing document.
- Clubhouse reservation with reservation payment.
- Architectural request case.
- Committee workflow decision.
- Owner notification.
- Export bundle with document and operational component coverage.

## Validation

Run:

```bash
cd app
flutter test apps/loom_communities_demo/test/b4_hoa_workflow_test.dart
```

## UI Evidence

Phase B14 validates the HOA workflows through visible Demo App UI on Android emulator
`emulator-5554`. Evidence is recorded in
`docs/Build Plan V2/Evidence/B14/workflow-ui-evidence.json` with 7 HOA workflows and
start/action/completion screenshots under `docs/Build Plan V2/Evidence/B14/screenshots/`.
