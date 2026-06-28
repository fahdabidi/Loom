# Phase B21 - Production Workflow UX Contract Matrix

## Achieves

Define the production UX contract for every workflow/persona row before app code changes. This phase
converts the B12-B20 technical evidence into user-facing workflow requirements that reject generic
workflow cards, metadata-only screens, and test-harness copy.

## Deliverables

- Production workflow UX contract matrix for every example and test app.
- Workflow-type pattern map for event/RSVP, payment, forms, announcements, approvals, search/AI,
  export/migration, messages, connections, ads, and platform shell workflows.
- Persona-specific screen map for actor, receiver, read-only, disabled, hidden, and unrelated states.
- Generic-copy audit covering existing workflow cards, dialogs, button labels, helper copy, and
  evidence-only text.
- Screenshot evidence plan with entry, input, validation/review, action, result, persona switch,
  receiver state, and unauthorized persona evidence IDs.
- B21 API Review and B21 UX Decisions.

## Completed When

Every workflow/persona row has a reviewed production UX contract and no row is allowed to proceed with
`Complete`, `Complete workflow`, `Can perform this workflow`, `workflow evidence`, `local route`, or
equivalent implementation-oriented copy as the intended user experience.

## UX Contract Judge Gate

Run `ux_contract_judge.dart` against the B21 contract evidence before B22 implementation starts:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/ux_contract_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B21/ux-contract-evidence.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B21/ux-contract-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B21/ux-contract-scorecard.md'
```

The judge must fail if any workflow/persona row lacks real user goal, domain surface, inputs,
validation, semantic action, success state, receiver state, or screenshot plan. The Worker Agent may not
start B22 from an unjudged or failed B21 contract.

## Prompt To Use

Use this prompt when executing B21:

```text
You are implementing Phase B21: Production Workflow UX Contract Matrix.

Do not edit app code in this phase. Review Build Tracker B12-B20, all existing example workflow docs,
evidence manifests, screenshots, persona matrices, seed data, and current Demo App workflow UX.

Create a production workflow UX contract matrix with one row per community/workflow/persona state.
For each row, specify:
- community/test app and workflow ID
- workflow category and real user goal
- initiating persona, receiving persona, approving persona, read-only persona, and unauthorized persona
- prerequisite state and dependency chain
- Loom-owned services and extension-owned data touched
- production screen name and required sections
- required inputs, validation, loading, empty, error, review, success, receipt, and audit states
- semantic primary action label and secondary/destructive actions
- receiver/read-only/hidden/disabled UX behavior and reason copy
- backend assertions and screenshot evidence IDs

Reject any workflow contract that only renders metadata, a generic checklist, a generic completion
dialog, or implementation/test-harness copy. Button labels must describe the action the user is taking,
such as Publish announcement, RSVP to event, Submit care request, Approve request, Pay dues, Send invite,
Export data, or Start transfer.

Produce B21 API Review, B21 UX Decisions, the production UX matrix, and a gap report. Stop for owner
review before Phase B22 implementation.
```

## Evidence To Record

Matrix path, generic-copy audit path, UX contract judge scorecard, prompt transcript, owner review
notes, manifest rows, phase gate, boundary lint, diff check, and commit SHA.
