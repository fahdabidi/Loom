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
- The `## 3.1 Persona Tabs, Pins, And Customization` section from each product doc.
- The `## 6. Workflow-To-Surface Mapping` section from each product doc.
- The same product doc's `## 7. Persona And State Matrix`.
- The same product doc's `## 8. Content And Seed Data Requirements`.
- The same product doc's `## 9. Visual And Interaction Standard`.
- The same product doc's `### B25 Semantic Interaction Models`.
- The same product doc's `### B25 Card Surface Registry Mapping`.
- Current `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`.
- The App Shell component guide at
  `docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md`.
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

- Section 3.1 must define persona-specific tabs, pinning policy, required Home and
  Messages/Communication, custom labels/icons/order/visibility, hidden/disabled rules, surface-to-tab
  assignment, presentation defaults, and customization knobs.
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
3. **Persona navigation coverage.** Cross-check Section 3.1 against screenshots and evidence. Fail if
   Home or Messages/Communication is missing, a persona lacks the documented custom tabs, a restricted
   tab leaks to an unauthorized persona, a declared pinned surface is absent, the pinning policy is
   ambiguous, or a long generic home list remains where Section 3.1 calls for a tabbed information
   architecture.
4. **Customization proof.** Fail if the product doc declares a community-card, tab, typography,
   density, icon, color, or surface presentation customization that is not visible in screenshots, or
   if screenshots show customization not reflected in Section 3.1.
5. **Visible proof completeness.** For every Section 6 row, inspect screenshots and visible text for
   the required visible proof. Fail if the UI only shows vague workflow text, status chips, or a
   generic action card instead of the required domain content.
6. **Persona/state completeness.** Cross-check Section 7 against the screenshots. Fail if actor,
   receiver, read-only, disabled/hidden, or unauthorized states are required but not screenshot-backed,
   or if screenshots show persona behavior not documented.
7. **Lifecycle completeness.** Cross-check the B25 semantic interaction table and card-surface registry.
   Fail if the product doc or UI lacks required primary actions, alternate/change/reject/defer actions,
   result states, receiver states, or API-backed interactions.
8. **Surface mapping quality.** Fail if the product doc maps a primary workflow to a generic card,
   checklist modal, metadata surface, or vague product surface when the workflow requires a
   domain-native surface.
9. **Product-doc expansion from screenshots.** If screenshots show interactions such as `Change
   response`, `Edit offer`, `Waiting`, `Sent`, roster counts, receipt states, privacy checks, or other
   UI states that are not explicitly captured in Sections 6/7/8/semantic/card-registry rows, create a
   product-doc update finding so the docs become the source of truth for that behavior.
10. **Implementation remediation from docs.** If the product doc clearly requires richer domain content
   or lifecycle actions than the screenshot provides, create an implementation remediation finding
   rather than weakening the doc.

## Hard App Shell Capability Utilization Gate

This is a required sub-review. It is not advisory. The reviewer must inspect current screenshots,
screen rows, Product Docs V2 Section 3.1, and the App Shell component guide, then decide whether the
implementation actually uses the central App Shell capabilities where the product docs require them.

Evaluate these capabilities from screenshots, not source-code intent:

- persona-specific tabs, including required Home and Messages/Communication tabs;
- community-defined custom tab labels, icons, ordering, and persona visibility;
- explicit persona/tab pinning policy: either `pinnedSurfaces: none` with rationale or declared pinned
  surfaces with screenshot proof inside the relevant tab;
- minimized, medium/in-focus, and expanded/maximized surface states;
- scroll-driven focus where the first/visible card becomes medium and off-focus cards become minimized;
- tap-to-expand behavior that opens a richer product surface rather than merely running a workflow;
- community-list card presentation states on the main Loom Communities screen;
- renderer selection by card-surface family;
- community theme, typography, density, color, button, badge, edit-field, and tab customization tokens;
- tab overflow behavior with no clipping or inaccessible tabs.

The B25 evidence collector must include `wf_app-shell-capability-evidence` screenshots from B20.
Use those rows as the first place to verify shell capabilities:

- `B20_app_shell_main_community_list_states` for main community launch-card states;
- `B20_app_shell_garden_home_medium_minimized_stack` and
  `B20_app_shell_garden_home_expanded_surface` for minimized/medium/expanded workflow presentation;
- `B20_app_shell_hoa_documents_pinning_policy` for an explicit Documents-tab pinning policy;
- `B20_app_shell_soccer_roster_renderer_medium` and
  `B20_app_shell_soccer_roster_renderer_expanded` for card-surface renderer selection proof.

Fail this sub-review if any documented capability is not visible in fresh screenshots, if the reviewer
cannot tie a capability to affected screen rows and screenshot hashes, or if a screenshot shows generic
card-list behavior where the product doc requires App Shell customization.

## Required Direct Questions

Ask these questions for each community:

- Does `## 3.1 Persona Tabs, Pins, And Customization` define the tab/navigation/customization model
  needed for every persona visible in the current evidence?
- Do screenshots prove the documented tabs, explicit pinning policy, Home/Messages requirements,
  persona visibility, and customization knobs?
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
- Do current screenshots prove persona tabs, explicit and appropriate pinning policy,
  minimized/medium/expanded states,
  tap-to-expand behavior, community-list card states, renderer selection, and theme/customization tokens
  where Product Docs or the App Shell component guide require them?
- For each persona, does the visible tab model match Section 3.1 exactly, including Home,
  Messages/Communication, custom tabs, labels/icons/order, and tab visibility?
- For each persona/tab, is the pinning policy explicit and appropriate? If the policy declares no pinned
  surfaces, is the rationale sound for that tab's job-to-be-done? If it declares pinned surfaces, are
  those surfaces visible in the correct tab and not buried in a long generic workflow list?
- Do reviewed screenshots include enough before/after or entry/focus/expanded states to prove the
  presentation-state model is implemented, not just declared?
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
  "appShellCapabilityReview": {
    "status": "pass|fail",
    "reviewedCapabilities": [],
    "missingCapabilities": [],
    "communityResults": [
      {
        "communityName": "<name>",
        "persona": "<persona>",
        "tabsPass": true,
        "pinningPolicy": "none|declared-pinned-surfaces|ambiguous",
        "pinningPolicyRationale": "<why pinning is or is not appropriate for this persona/tab>",
        "pinningPolicyPass": true,
        "pinnedSurfacesExpected": false,
        "declaredPinnedSurfaceIds": [],
        "pinnedSurfacesPass": true,
        "presentationStatesPass": true,
        "mainCommunityCardStatesPass": true,
        "themeCustomizationPass": true,
        "rendererSelectionPass": true,
        "affectedScreenRowIds": [],
        "affectedScreenshotPaths": [],
        "affectedScreenshotHashes": [],
        "visibleTextExcerpt": "<visible text used by the reviewer>",
        "requiredFix": "<specific App Shell/product-doc/UI fix>"
      }
    ],
    "findings": []
  },
  "findings": [
    {
      "findingId": "LLM-B25-WR-001",
      "severity": "blocker|major|minor|polish",
      "gapType": "product-doc-missing-workflow|implementation-missing-workflow|product-doc-interaction-gap|surface-mismatch|evidence-extra-undocumented-flow|visible-proof-gap|persona-state-gap|app-shell-tabs-gap|app-shell-pinning-gap|app-shell-presentation-state-gap|app-shell-community-card-state-gap|app-shell-customization-gap|app-shell-renderer-selection-gap",
      "communityName": "<name>",
      "workflowId": "<workflow-id>",
      "persona": "<persona>",
      "affectedProductDocPath": "<path>",
      "affectedProductDocSections": ["## 3.1 Persona Tabs, Pins, And Customization", "## 6. Workflow-To-Surface Mapping"],
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
- App Shell capability utilization status, missing capabilities, affected communities/personas/screens,
  and screenshot-backed required fixes;
- UI/implementation gaps where the product doc is clear but screenshots fail to implement it;
- ticket-ready finding list with affected product doc path, workflow, persona, screen rows,
  screenshots, visible text, and required fix.

## Pass/Fail Rule

B25 cannot close with unresolved blocker or major reconciliation findings or with a failing
`appShellCapabilityReview`. These findings must be converted into B25 remediation tickets. Product-doc
findings must update the relevant product doc before the Worker Agent changes UI. App Shell findings
must be routed through the central app-shell model and then proven with fresh screenshots.
Implementation findings must update UI/content/seed data/tests and then recapture screenshots. Evidence
findings must recapture or repair screenshot evidence before the next judge pass.
