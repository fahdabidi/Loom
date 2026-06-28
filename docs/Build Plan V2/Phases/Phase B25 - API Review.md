# Phase B25 - API Review

## Scope

B25 is an independent product UX review. It does not require Loom runtime API changes, but it does
require stricter review-evidence contracts because B25 v4 supersedes the prior v3 pass.

## Decision

- Use the visible Android emulator, production UX contracts, widget tests, and refreshed screenshots as
  review inputs.
- Record UX findings separately from workflow checklist completion.
- Fail the phase if any blocker or major UX finding remains unresolved.
- Require schema version 4 evidence for `independent-production-ux-review.json`.
- Treat screenshot metadata as a review contract: screenshot path, hash, captured-at timestamp,
  emulator/device metadata, and app commit SHA are required for every screen row.
- Treat UI-pattern classification as a review contract: primary workflow rows classified as
  `generic-workflow-card`, checklist modal, metadata page, or repeated-card shell cannot pass.
- Treat visible-text extraction and screen-specific critique as required evidence. Boilerplate rows are
  invalid even if the JSON schema parses.

## Result

No Loom runtime API contract changes are required for B25. The review-evidence contract changes from
schema v3 to schema v4 and must be implemented in the B25 review generator, tests, phase gate inputs,
and tracker evidence before the phase can pass again.
