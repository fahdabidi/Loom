# B25 Product Docs To Evidence Workflow Reconciliation LLM Gate

This is an LLM reviewer gate, not a deterministic CLI. Use it during B25 after full screenshot
capture, coverage collection, visual inspection, and deterministic review scaffold generation, and
before the LLM Vision UX Judge and Production UX Judge close the pass.

The purpose is to prevent Product Docs V2 and the implemented UI from drifting apart. The reviewer must
compare the community product docs to the current screenshot-backed evidence and decide whether the
docs fully specify the workflows the app implements, whether the app implements every workflow the
docs specify, and whether screenshots reveal missing product requirements that must be added to the
docs before remediation continues.

## Inputs

Provide the LLM reviewer only evidence and product artifacts, not worker implementation notes:

- Every relevant `docs/Product Docs V2/Community Examples/*-product-experience.md` file, or the
  standalone Skill equivalent at `<extension-workspace>/docs/product/community-product-experience.md`.
- The `## 6. Workflow-To-Surface Mapping` section from each product doc.
- The same product doc's `## 7. Persona And State Matrix`.
- The same product doc's `## 8. Content And Seed Data Requirements`.
- The same product doc's `## 9. Visual And Interaction Standard`.
- The same product doc's `### B25 Semantic Interaction Models`.
- The same product doc's `### B25 Card Surface Registry Mapping`.
- Current `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`.
- Current `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`.
- Current `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`.
- Current `docs/Build Plan V2/Evidence/B25/workflow-persona-coverage-matrix.md`.
- Current screenshot paths, screenshot hashes, visible-text extracts, device metadata, and app commit
  SHA referenced by the review JSON.
- Current B12-B20 `workflow-ui-evidence.json` manifests and `B20/all-workflow-ui-evidence.json`.

## Product Doc Fields To Treat As Canonical

The community product docs currently use this Section 6 table shape:

| Field | Reviewer meaning |
| --- | --- |
| `Workflow` | Canonical workflow ID. Match exact IDs first. If evidence uses a title or route instead of the ID, match only with high-confidence community/persona/test evidence and record the uncertainty. |
| `Persona` | The persona expected to perform or receive the workflow. Cross-check against screen row persona, persona picker state, and Section 7 actor/receiver/read-only states. |
| `Product surface` | The intended product surface, such as event detail, announcement compose/feed, payment, export wizard, message thread, plant exchange form, protected care review, or roster. Generic surfaces like "workflow card", "evidence detail", or vague "action surface" are product-doc gaps unless explicitly secondary/supporting. |
| `Required visible proof` | The minimum user-visible content and state that screenshots must prove. Treat this as a floor, not a ceiling; if the screenshot shows a richer interaction that is not documented, flag a product-doc expansion. |
| `Loom APIs/rules/events` | The platform contracts, rules, events, or backend services the workflow claims to use. Cross-check with the card-surface registry's API contract where available. |
| `Test/evidence IDs` | The phases or evidence bundles where the workflow should appear. Missing B25 screenshot rows for a B25-listed workflow are implementation/evidence gaps. |

Use these companion sections to validate Section 6:

- Section 7 must define actor, receiver, read-only, disabled/hidden, and unauthorized behavior.
- Section 8 must provide realistic seed/content requirements sufficient for screenshot review.
- Section 9 must define the visual/interaction standard for this community.
- `### B25 Semantic Interaction Models` must define expected decision, required primary actions,
  required alternate/change/reject actions, and result/receiver state for each primary workflow.
- `### B25 Card Surface Registry Mapping` must define card surface family, API contract, required
  interactions/actions, and renderer/fake-backend support for each workflow.

## Reconciliation Checks

For each community product doc, perform these checks:

1. **Doc to evidence coverage.** For every Section 6 workflow row, find matching B25 screen rows,
   workflow/persona coverage rows, lifecycle scorecards, and screenshots. Fail if a documented
   workflow has no fresh screenshot-backed evidence for its persona and product surface.
2. **Evidence to doc coverage.** For every implemented/captured workflow, screen row, action result,
   dialog, form, feed item, or interaction in screenshots, find a matching Section 6 row and companion
   Section 7/B25 semantic interaction row. Fail if the UI implements or exposes a flow not documented
   in the product doc.
3. **Visible proof completeness.** For every Section 6 row, inspect screenshots and visible text for
   the required visible proof. Fail if the UI only shows vague workflow text, status chips, or a
   generic action card instead of the required domain content.
4. **Persona/state completeness.** Cross-check Section 7 against the screenshots. Fail if actor,
   receiver, read-only, disabled/hidden, or unauthorized states are required but not screenshot-backed,
   or if screenshots show persona behavior not documented.
5. **Lifecycle completeness.** Cross-check the B25 semantic interaction table and card-surface registry.
   Fail if the product doc or UI lacks required primary actions, alternate/change/reject/defer actions,
   result states, receiver states, or API-backed interactions.
6. **Surface mapping quality.** Fail if the product doc maps a primary workflow to a generic card,
   checklist modal, metadata surface, or vague product surface when the workflow requires a
   domain-native surface.
7. **Product-doc expansion from screenshots.** If screenshots show interactions such as `Change
   response`, `Edit offer`, `Waiting`, `Sent`, roster counts, receipt states, privacy checks, or other
   UI states that are not explicitly captured in Sections 6/7/8/semantic/card-registry rows, create a
   product-doc update finding so the docs become the source of truth for that behavior.
8. **Implementation remediation from docs.** If the product doc clearly requires richer domain content
   or lifecycle actions than the screenshot provides, create an implementation remediation finding
   rather than weakening the doc.

## Required Direct Questions

Ask these questions for each community:

- Does `## 6. Workflow-To-Surface Mapping` list every workflow visible in the current screenshots and
  review rows?
- Does every Section 6 workflow have fresh screenshot evidence for the named persona and product
  surface?
- Does the screenshot evidence prove the `Required visible proof` field with visible UI, not only test
  assertions or source code?
- Does Section 7 explain every actor, receiver, read-only, disabled/hidden, and unauthorized state that
  appears in the screenshots?
- Do the B25 semantic interaction rows define the actual primary, alternate/change/reject, result, and
  receiver states shown or required by the UI?
- Does the card-surface registry define the API contract and interactions needed by the visible
  surface?
- Are there screenshots showing extra screens, interactions, states, or flows that the product doc must
  add before the implementation can be judged complete?
- Are there product-doc workflows that are missing, unreachable, generic, or insufficiently implemented
  in the Demo App screenshots?

## Output JSON

Write:

`docs/Build Plan V2/Evidence/B25/llm-product-doc-workflow-reconciliation-<run-id>.json`

Use this shape:

```json
{
  "schemaVersion": 1,
  "reviewerType": "llm-product-doc-workflow-reconciliation",
  "currentReviewRunId": "<run-id>",
  "freshReview": true,
  "appCommitSha": "<sha>",
  "reviewedProductDocPaths": [],
  "reviewedEvidencePaths": [],
  "reviewedScreenRowIds": [],
  "reviewedScreenshotHashes": [],
  "communityResults": [
    {
      "communityName": "<name>",
      "productDocPath": "<path>",
      "status": "pass|fail",
      "declaredWorkflowIds": [],
      "implementedWorkflowIds": [],
      "section6RowsReviewed": [],
      "missingFromProductDoc": [],
      "missingFromEvidence": [],
      "visibleProofGaps": [],
      "personaStateGaps": [],
      "interactionModelGaps": [],
      "surfaceMappingGaps": [],
      "screenshotBackedExamples": []
    }
  ],
  "findings": [
    {
      "findingId": "LLM-B25-WR-001",
      "severity": "blocker|major|minor|polish",
      "gapType": "product-doc-missing-workflow|implementation-missing-workflow|product-doc-interaction-gap|surface-mismatch|evidence-extra-undocumented-flow|visible-proof-gap|persona-state-gap",
      "communityName": "<name>",
      "workflowId": "<workflow-id>",
      "persona": "<persona>",
      "affectedProductDocPath": "<path>",
      "affectedProductDocSections": ["## 6. Workflow-To-Surface Mapping"],
      "affectedScreenRowIds": [],
      "affectedScreenshotPaths": [],
      "affectedScreenshotHashes": [],
      "visibleTextExcerpt": "<text from evidence>",
      "requiredFix": "<specific product-doc or implementation fix>",
      "ticketMode": "product-doc-update|implementation-remediation|evidence-recapture|mixed"
    }
  ],
  "finalDecision": "pass|fail"
}
```

## Output Markdown

Write:

`docs/Build Plan V2/Evidence/B25/llm-product-doc-workflow-reconciliation-<run-id>.md`

Include:

- summary pass/fail decision;
- communities reviewed;
- product doc rows missing evidence;
- evidence rows missing product doc coverage;
- product-doc sections that must be updated before UI remediation;
- UI/implementation gaps where the product doc is clear but screenshots fail to implement it;
- ticket-ready finding list with affected product doc path, workflow, persona, screen rows,
  screenshots, visible text, and required fix.

## Pass/Fail Rule

B25 cannot close with unresolved blocker or major reconciliation findings. These findings must be
converted into B25 remediation tickets. Product-doc findings must update the relevant product doc before
the Worker Agent changes UI. Implementation findings must update UI/content/seed data/tests and then
recapture screenshots. Evidence findings must recapture or repair screenshot evidence before the next
judge pass.
