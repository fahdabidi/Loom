# Phase B22 - Domain-Specific Workflow Surfaces

## Achieves

Replace generic workflow harness UI with production-level workflow surfaces that match the domain task
and the B21 production UX contract matrix.

## Deliverables

- Production event and RSVP surfaces with event details, schedule/location/capacity when available,
  RSVP state, confirmation, and cancel/change behavior when supported.
- Production payment, donation, dues, and ad-off surfaces with amount, payer, visibility or entitlement
  choice, Loom payment surface handoff, receipt, settlement/utility state where relevant, and failure
  or retry state.
- Production form, protected care, volunteer, exchange, critique, and gear surfaces with labeled
  fields, protected/private indicators, validation, submit/review, saved state, and recipient/admin
  review state.
- Production announcement, publishing, notification, and digest surfaces with compose/source selection,
  audience, preview, publish/send action, recipient inbox/feed/search state, and citation/source state
  for AI output.
- Production approval, moderation, search/AI, export/migration, messages, connections, ads, and shell
  surfaces with domain-specific actions and state.
- Automated failure gate for generic harness labels or implementation-oriented copy on production
  workflow screens.
- B22 API Review and B22 UX Decisions.

## Completed When

Every example/test workflow can be completed through a production-like surface with user-meaningful
labels, inputs, validation, and results. Tests fail if production workflow screens expose generic
labels such as `Complete` or `Complete workflow`, or copy such as `Can perform this workflow` and
`workflow evidence`.

## Prompt To Use

Use this prompt when executing B22:

```text
You are implementing Phase B22: Domain-Specific Workflow Surfaces.

Use the approved B21 production UX contract matrix as the source of truth. Replace every generic
workflow checklist/card/dialog path with a domain-specific production surface. Keep App Shell-owned
surfaces intact: top ad banner, Messages, Connections, Loom payment surface, and ad-off behavior.

For each workflow category, implement the expected user-facing screen, required inputs, validation,
review/preview state when appropriate, semantic action labels, success/result state, and backend
assertions. Do not use generic buttons such as Complete or Complete workflow for production workflow
actions. Do not show implementation copy such as workflow evidence, local route, or Can perform this
workflow on user-facing surfaces.

Add widget/integration tests that fail when generic harness copy appears on production screens. Update
screenshots and evidence manifests for entry, input, validation/review, action, and result states.

Run the affected Demo App workflow tests, production UX failure gate, manifest gate, B22 phase gate,
analyze, boundary lint, and diff check. Record B22 API Review and B22 UX Decisions.
```

## Evidence To Record

Before/after screenshots, per-category workflow evidence, generic-copy gate output, widget/integration
test output, backend assertion output, manifest rows, phase gate, analyzer, boundary lint, diff check,
and commit SHA.
