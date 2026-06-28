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
- Treat `holisticQuestionAnswers` as a required evidence contract. It must answer direct questions about
  whole-product production feel, modern visual design, navigation/IA, community jobs-to-be-done, and
  blocking layout/content defects.
- Treat `workflowPersonaScorecards` as a required evidence contract. It must include one scorecard per
  workflow/persona pair with direct answers about task clarity, domain-native surface, natural actions,
  input/validation/result states, receiver/unauthorized states, and workflow-level production quality.
- Require `production_ux_judge.dart` output as the final criteria scorecard. The scorecard is a
  separate artifact from the review JSON and must assign scope/question/score/verdict/blocksPass/why/
  requiredFix to each B25 pass criterion. The judge must fail if the holistic direct-question pass or
  any workflow/persona direct-question pass is missing, partial, unsupported, or below threshold.
- Require `b25_iteration_scorecard.dart` output after every review/remediation pass. The iteration
  scorecard is a separate convergence artifact from the review JSON and judge scorecard. It must record
  current critical/blocker and major counts, unresolved counts, resolved blocker/major counts for the
  pass, newly introduced blocker/major counts, judge failures, and required next action.

## Result

No Loom runtime API contract changes are required for B25. The review-evidence contract changes from
schema v3 to schema v4 and must be implemented in the B25 review generator, tests, phase gate inputs,
judge tool scorecard, and tracker evidence before the phase can pass again. Schema v4 now includes both
the holistic product UX direct-question block and the per-workflow/persona direct-question block as
phase-blocking evidence. Every B25 pass must also emit an iteration scorecard so reviewers can see
whether the remediation loop is converging toward zero unresolved blocker/major findings.
