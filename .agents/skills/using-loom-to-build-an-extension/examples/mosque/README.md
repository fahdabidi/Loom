# Mosque Example Extension

Status: Phase B5 local workflow example.

This example extension validates the mosque headline path in the Demo Loom Communities App with Local
Backend.

## Included Flow

- Public announcement.
- Community event and RSVP.
- Volunteer signup with protected contact field.
- Anonymous donor visibility preference.
- Donation payment and receipt.
- Protected care request.
- Neutral care-request notification.
- Public announcement search/AI citation.

## Validation

Run:

```bash
cd app
flutter test apps/loom_communities_demo/test/b5_mosque_workflow_test.dart
```

## UI Evidence

Phase B14 validates the Mosque workflows through visible Demo App UI on Android emulator
`emulator-5554`. Evidence is recorded in
`docs/Build Plan V2/Evidence/B14/workflow-ui-evidence.json` with 8 Mosque workflows and
start/action/completion screenshots under `docs/Build Plan V2/Evidence/B14/screenshots/`.
