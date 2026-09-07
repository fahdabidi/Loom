# B25 Production UX Blueprint

Purpose: define the production UX bar used by B25 before each screenshot review pass. This blueprint
is the shared bar; the community-specific source of truth is the Product Docs V2 community experience
doc for each reviewed community.

## Required Inputs

| Artifact | Requirement |
| --- | --- |
| Product Docs V2 community experience docs | Every reviewed community/test app must have a doc under `docs/Product Docs V2/Community Examples/` with product promise, personas/jobs, IA, home requirements, domain-native surfaces, workflow-to-surface mapping, persona/state matrix, seed content, visual standard, and B25 review log. |
| Fresh screenshots | Every reviewed screen row must have screenshot path, hash, timestamp, device metadata, app commit SHA, visible text, and screenshot-specific critique. |
| Workflow/persona coverage | Every workflow/persona combination must have entry, action/review, result/receiver, error/empty/disabled/hidden states where applicable. |
| Independent UX review | The reviewer must answer direct holistic and workflow/persona questions from the screenshots and product docs, not from implementation intent. |
| Production judge scorecard | The deterministic judge must verify Product Doc coverage, visual inspection, direct-question quality, workflow/persona scorecards, screen matrix completeness, and zero unresolved blocker/major findings. |

## Production Experience Bar

The app passes B25 only when a fresh reviewer can say all of the following from the evidence:

- The experience feels like a real production community product for the target user, not a workflow
  harness or validation screen.
- The UI looks modern, intentional, visually appealing, easy to use, and easy to navigate.
- The main user-facing screens are organized around community content and jobs-to-be-done.
- Primary workflows use domain-native product surfaces, not generic workflow cards or checklist modals.
- Each screen is judged against the matching community product experience doc.
- The visible UI has no blocking or major overlap, clipping, crowding, default scaffold,
  repeated-card, checklist-modal, or thin-content findings.
- The community's **UI/Usability Score is 8.0 or higher** (see below). Workflow/persona affordance
  coverage proves the app is *complete*; this score proves it is *good* — a community can have every
  row's primary and alternate affordance present and still read as unfinished or hard to use, and the
  score exists to catch that.

## UI/Usability Score

A single number per community, 0.0–10.0 with one decimal place, distinct from the per-row/per-question
0–100 confidence scores elsewhere in the judge's output (those gate individual criteria; this one is a
holistic community-level grade). It is the average of five sub-scores, each independently scored
0.0–10.0 by the judge from the same screenshot evidence used for the rest of the review, each with its
own one-line justification citing specific screens:

| Sub-score | What it measures | A 10 looks like | A 3 or below looks like |
| --- | --- | --- | --- |
| Visual polish & native fidelity | Real archetype-native widgets used throughout, not `GenericWorkflowInstanceCard` fallbacks; nothing reads as a debug/validation screen. | Every primary surface is a purpose-built, domain-native widget. | Workflow cards render as generic list tiles or raw field dumps. |
| Information hierarchy | The thing the user needs most (status, next action, who's waiting on whom) is visually dominant; secondary metadata doesn't compete with it. | One glance tells you what state something is in and what to do next. | Every field looks equally important; the user has to read the whole card to find the status. |
| Interaction affordance clarity | Primary and alternate actions are visibly present as real controls (buttons, menus), not hidden behind an undiscoverable gesture; acting on something gives visible feedback. | Buttons/menus for every required action are visible without hunting; state changes are confirmed on-screen. | An action exists only as a hidden long-press or swipe with no visible entry point. |
| Consistency | Spacing, typography, iconography, and tone match across screens and personas within the community. | The community reads as one coherently designed product end to end. | Different screens look like they came from different apps. |
| Error/edge-state handling | Empty, loading, and error states look designed, not blank or broken. | An empty list explains itself; an error state offers a next step. | A blank white screen with no explanation, or a raw exception string. |

**Scoring is evidence-bound, same as every other judge finding**: a sub-score without a specific
screenshot citation is not a valid score. Do not average toward a round number — if the evidence only
supports a 6, report a 6, even if four of the five sub-scores are 9s. A community with a real, cited
weakness (e.g., a generic-card fallback on one primary surface) should not clear 8.0 by dilution.

**Gate:** production requires BOTH the existing 100% B25 row coverage (primary + alternate affordance
per row, proven by live walkthrough and UX judge) AND a UI/Usability Score of 8.0 or higher. Either one
failing means the community is not production-ready. Report both numbers together — coverage percentage
and the UI/Usability Score — in every scorecard, never one without the other.

## Community Product Experience Docs

Each reviewed community/test app must have a Product Docs V2 community-specific experience doc before
remediation continues. For native Loom repo development, these docs live under:

```text
docs/Product Docs V2/Community Examples/<community>-product-experience.md
```

For standalone Skill-created extensions, the same content lives inside the generated extension working
repo:

```text
docs/Product Experience/<extension-id>-product-experience.md
```

B25 native repo runs validate the Product Docs V2 location. The Skill validates the extension-local
location and may use the native docs only as reference examples.

## Review Sequence

1. Product Experience Steward updates missing or thin community product docs.
2. Worker Agent implements or remediates UI against those docs.
3. Evidence Collector captures fresh workflow/persona screenshots, visible text, hashes, timestamps,
   device metadata, and app commit SHA.
4. Independent UX Judge reviews only Product Docs, screenshots, visible text, scorecards, and pass
   criteria.
5. Production UX Judge validates schema v4 evidence and emits remediation tickets.
6. Remediation Planner turns tickets into product-spec, evidence, and UI batches.
7. Iteration scorecard records pass/fail counts, new issues, resolved blocker/major issues, and
   convergence.
8. Commit the iteration before the next UX feedback loop.

## Community Coverage

The B25 collector writes `productDocCoverage` into `independent-production-ux-review.json`. A row
passes only when the doc exists, has all required sections, contains no placeholders, is not thin, maps
workflows to domain-native product surfaces, and has a B25 review/remediation log.
