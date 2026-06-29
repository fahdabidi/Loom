# B25 Remediation Ticket Template

Use this template whenever the Production UX Judge finds a blocking or major B25 issue. The ticket is
the handoff artifact from the Judge Agent to the Remediation Planner and Worker Agent. It must be
specific enough that the next worker can implement a fix without relying on the prior worker's intent
or a generic pass/fail summary.

## Required Ticket Fields

| Field | Required content |
| --- | --- |
| `ticketId` | Stable ID for the remediation ticket, such as `B25-RT-001-b25-c04-modern-intentional-ui`. |
| `ticketSchemaVersion` | Current schema version. Use `3` for tickets with worker-readiness, evidence-repair work items, and UI-remediation work items. |
| `phase` | `B25`. |
| `reviewRunId` | The review pass that produced the ticket, such as `b25-v4-pass-1`. |
| `status` | `open`, `in-progress`, `resolved`, `owner-accepted`, or `deferred-with-rationale`. |
| `severity` | `critical-blocker`, `major`, `minor`, or `polish`. |
| `priority` | `P0` for blockers, `P1` for major production UX failures, `P2` for minor/polish. |
| `sourceCriterionId` | Failed production UX criterion ID. |
| `sourceFindingIds` | Related finding IDs from the review JSON. |
| `directQuestion` | The exact direct question the evidence failed to satisfy. |
| `whyItFailed` | Evidence-grounded explanation of why the criterion failed. |
| `remediationMode` | `evidence-repair-first`, `evidence-repair-before-ui-remediation`, `ui-remediation-ready`, `closeout-after-all-remediation`, or `review-only`. |
| `workerReadiness` | Whether a Worker Agent can implement UI changes now, or whether evidence repair/rejudge must happen first. |
| `firstRequiredStep` | The first action the next pass must take before implementation or closeout. |
| `implementationBlockedBy` | Concrete blockers that prevent direct UI implementation, such as generic personas, missing screenshot-derived visible text, or missing screen-specific critique. |
| `affectedScope` | Communities, personas, workflows, screen rows, and screenshots affected. |
| `affectedCoverageRowIds` | Machine-readable workflow/persona coverage row IDs affected by this ticket. |
| `affectedScreenRowIds` | Machine-readable screen row IDs affected by this ticket. |
| `affectedCoverageRows` | Concrete workflow/persona coverage rows, including coverage row ID, community, workflow, persona/personaId, missing evidence, screen row IDs, screenshot paths, and target production surface. |
| `affectedScreenRows` | Concrete screen rows, including screen row ID, community, workflow, persona, screen/state, screenshot path/hash/timestamp, app commit SHA, visible text excerpt, current classification, exact UX failure, target production surface, likely files/widgets, and row-level acceptance criteria. |
| `failingWorkflowPersonaScorecards` | Failing workflow/persona scorecards, including failed direct questions, screen row IDs, screenshot paths, and required fixes. |
| `failingDirectQuestions` | Holistic or workflow/persona direct questions that failed, including score, why, required fix, and evidence used. |
| `evidenceRepairWorkItems` | Smaller community/workflow/persona work items for fixing evidence quality before UI implementation. Each item includes affected row IDs, screenshot paths/hashes, visible text excerpts, current failures, worker actions, and acceptance criteria. |
| `uiRemediationWorkItems` | Smaller community/workflow/persona work items for actual UI/design implementation once evidence repair has passed. Each item names the target production surface, likely files/widgets, worker actions, and acceptance criteria. |
| `likelyFilesOrWidgets` | Specific code, test, evidence, or documentation files likely needing updates. |
| `concreteAcceptanceCriteria` | Screen/workflow/persona-specific checks the remediation must satisfy before rerun. |
| `problemStatement` | Plain-language user-facing problem, not implementation jargon. |
| `rootCauseHypothesis` | Likely UX/design root cause behind the failure. |
| `targetExperience` | What the user should see, understand, and be able to do after the fix. |
| `uxPrinciples` | Production UX principles being enforced. |
| `concreteImprovements` | Specific UI/content/IA changes to make. |
| `implementationGuidance` | Likely files/components/surfaces to inspect or change. |
| `contentGuidance` | Copy/content changes needed to make the screen domain-native and useful. |
| `visualGuidance` | Layout, spacing, hierarchy, component, navigation, or polish changes needed. |
| `evidenceToCollect` | Screenshots, visible text, scorecards, or manifests required after the fix. |
| `acceptanceChecks` | Conditions that must be true before the ticket can close. |
| `rerunCommands` | Commands to regenerate evidence, rerun the judge, and regenerate the iteration scorecard for the current remediation pass. Do not include the Remediation Planner here; the planner runs only at the start of the next pass if the committed pass still fails. |
| `nonGoals` | What not to do, especially superficial fixes that would not satisfy the criterion. |
| `commitBoundary` | Reminder that the iteration must be committed before the next UX feedback loop. |

## Markdown Shape

Each ticket Markdown section should use this structure:

```markdown
## B25-RT-001-b25-c04-modern-intentional-ui

| Field | Value |
| --- | --- |
| Status | open |
| Severity | major |
| Priority | P1 |
| Source criterion | b25-c04-modern-intentional-ui |
| Source findings | B25-HOLISTIC-UNPROVEN |
| Direct question | Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? |
| Remediation mode | evidence-repair-before-ui-remediation |
| Worker readiness | not ready for UI implementation until evidence repair work items are completed and the independent judge reruns |
| First required step | Complete evidenceRepairWorkItems, then rerun collector/judge tools before assigning UI work. |

### Implementation Blocked By

- Affected rows still use generic or missing persona data.
- Visible text is not proven from screenshot OCR/manual extraction.
- Screen-specific critiques are incomplete or reusable.

### Why It Failed

Evidence-grounded explanation.

### Affected Scope

- Communities:
- Personas:
- Workflows:
- Screen rows:
- Screenshots:

### Affected Workflow/Persona Coverage

| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `b25-wp-...` | fail | Example Community | `workflow-id` | member | specific persona/personaId | 3 | Event detail with RSVP action and result state |

### Affected Screen Rows

| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b25-v4-row-...` | Example Community | `workflow-id` | member | action | `/path/screenshot.png` | `abc123...` | Visible text excerpt | generic / unverified | Exact reason this row failed | Target production surface |

### Evidence Repair Work Items

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-example-workflow-member` | evidence-repair | Example Community | `workflow-id` | member | 3 | 1 | Event detail with RSVP action and result state |  |

### UI Remediation Work Items

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-example-workflow-member` | ui-remediation | Example Community | `workflow-id` | member | 3 | 1 | Event detail with RSVP action and result state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### Failing Direct Questions

| Question | Scope | Score | Why | Required fix |
| --- | --- | ---: | --- | --- |
| Is the primary surface domain-native? | workflow-persona | 35 | Evidence shows generic surface. | Replace with target domain surface and recapture. |

### Likely Files / Widgets

- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`

### Target Experience

What the target user should experience after the fix.

### Concrete Improvements

- Specific UI/content/IA change.
- Specific UI/content/IA change.

### Implementation Guidance

- Likely files/components/surfaces.
- Tests or helpers likely needing updates.

### Evidence To Collect

- Fresh screenshot rows.
- Visible text extracts.
- Holistic or workflow/persona answers.

### Acceptance Checks

- Judge criterion no longer blocks pass.
- Screenshots and hashes are fresh.
- Iteration scorecard shows the ticket resolved or non-blocking.

### Concrete Acceptance Criteria

- Affected screen row has a specific persona/personaId.
- Visible text is extracted from the screenshot or manually transcribed from the screenshot.
- Screen-specific critique names visible UI, visible text, persona, workflow, and exact issue.
- Primary surface is the target domain-native surface, not a generic card/checklist/metadata page.
- Workflow/persona scorecard passes after rerun.

### Rerun Commands

- `...`

### Non-Goals

- Do not rename a generic card and call it domain-native.
- Do not pass without fresh screenshots.
```

## Quality Bar

A remediation ticket is invalid if it only says "fix UX" or repeats the failed criterion. It must name
the user-facing problem, describe the target experience, identify the artifacts to update, and define
how the next pass will prove the fix.

The ticket is not an implementation plan by itself. The next pass sends committed tickets and the
iteration scorecard to the Remediation Planner, which creates the ordered fix batches for the Worker
Agent.
