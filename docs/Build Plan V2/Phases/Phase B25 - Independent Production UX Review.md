# Phase B25 - Independent Production UX Review

## Achieves

Run a post-implementation product UX review and remediation loop that is independent from the workflow
implementation checklist. The goal is to critique the visible product experience as a real community
app, find improvement opportunities, apply fixes, retest, and pass the UX only when it meets
production-grade standards.

This phase is separate from workflow compliance. B21-B24 can prove that workflows, personas, backend
state, and screenshot evidence exist; B25 must decide whether the resulting app feels like a modern,
domain-native product for the target users. B25 is not complete after a failed review. A failed review
starts a remediation loop that continues until all blocker and major UX findings are resolved.

B25 must not equate "no forbidden workflow copy is visible" with "production UX." A screen can remove
implementation language and still fail if it looks like a generic demo scaffold, uses repetitive
workflow cards as the product, has thin placeholder content, relies on checklist-style dialogs, exposes
clipped or overlapped controls, lacks community identity, or does not provide the actual domain surface
a real user would expect.

## Deliverables

- Independent UX review report covering every example and test community after B22-B24.
- Complete product UX screen inventory and review matrix at
  `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`, with one row for every
  implemented screen, state, dialog, card, feed item, form, confirmation, error, empty state, persona
  variant, and action result.
- Per-community production UX blueprint at
  `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`. Each community/test app must define
  target personas, community identity, home information architecture, expected primary surfaces,
  workflow-to-surface mapping, realistic content requirements, visual/interaction standard, and
  concrete pass examples before the review can pass.
- Severity-ranked findings: blocker, major, minor, or polish.
- Annotated screenshot references from the visible Android emulator and final evidence bundle.
- Design-quality assessment across information architecture, visual hierarchy, interaction clarity,
  semantic labels, mobile layout, accessibility, empty/loading/error states, trust/privacy/payment
  clarity, persona relevance, multi-persona handoffs, content tone, and overall product fit.
- Product-readiness assessment that explicitly checks whether each community home is organized around
  domain-native sections and content, not around workflow categories, testing states, or implementation
  taxonomy.
- Exposed-implementation audit for labels and copy such as `Community workflows`, `[category] surface`,
  `workflow`, `evidence`, role-state rationale, metadata-only cards, generic checklist cards, and any
  equivalent language a real user would not expect.
- Domain-content audit for realistic announcement bodies, authors, timestamps, audiences, event
  date/time/location/capacity, donation details, receipts, privacy/protected-data indicators, and next
  steps where those concepts apply.
- Modern product UI audit covering layout polish, visual hierarchy, typography, spacing, component
  variety, brand/community identity, imagery or rich domain cues where useful, information density,
  repeated-card fatigue, chip/button overuse, default-scaffold feel, and whether the UI looks shippable
  to real community members rather than only usable by QA.
- Screen-specific critique audit proving the reviewer made an independent judgment for each screen.
  Boilerplate matrix rows that repeat the same generic rationale across unrelated screens are invalid
  B25 evidence.
- Interaction-polish audit for clipping, occlusion, sticky/FAB overlap, unreachable content, awkward
  modal sizing, blocked reading paths, unclear disabled/waiting states, and action placement. These
  issues must be ranked by production impact, not automatically downgraded to polish.
- Domain-surface depth audit that verifies workflows are represented by real product surfaces, such as
  feeds, inbox items, detail pages, compose screens, event detail/RSVP flows, donation/payment flows,
  volunteer signup forms, care request forms, admin review screens, receipt/history surfaces, and
  receiver states, instead of only generic workflow cards with improved labels.
- Remediation plan and retest evidence for resolved findings.
- B25 remediation loop log at
  `docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md`, recording each review-fix-retest
  iteration, fixes applied, tests run, screenshots refreshed, remaining blocker/major findings, and the
  iteration decision.
- Per-iteration git commit evidence. Each B25 review/remediation iteration must be committed before the
  next UX feedback loop or correction batch starts, and the remediation log must record that commit SHA.
- Machine-readable review evidence at
  `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json` using schema version 4. The
  JSON must include the review standard version, superseded prior run IDs, blueprint path, every screen
  row with a unique row ID, screenshot hash, captured-at timestamp, app commit SHA, emulator/device
  metadata, visible-text extract, UI-pattern classification, screen-specific critique,
  finding-to-remediation links, before/after screenshot references for fixed issues, unresolved severity
  counts, rerun requirements, and the final pass/fail decision.
- Screenshot freshness and evidence-integrity audit. Every referenced screenshot must exist, be captured
  from the latest app commit or explicitly linked to the commit it represents, and be newer than the
  remediation it claims to prove. Stale screenshots invalidate the review.
- Boilerplate critique audit. The review must reject matrix rows whose critique/rationale is repeated
  across unrelated screens or cannot identify visible elements from the screenshot.
- Primary-surface classification audit. Every primary workflow surface must be classified as
  `domain-native`, `secondary-supporting`, or `generic-workflow-card`. Primary workflows cannot pass as
  `generic-workflow-card`, checklist modal, metadata page, or a repeated card with better copy.
- Production UX judge scorecard at
  `docs/Build Plan V2/Evidence/B25/production-ux-criteria-scorecard.json` and
  `docs/Build Plan V2/Evidence/B25/production-ux-criteria-scorecard.md`. The scorecard must assign a
  scope, direct question, score, and pass/fail verdict to each B25 pass criterion from artifacts only.
- B25 iteration scorecard after every review/remediation pass. Write both per-run and latest files:
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-<run-id>.json`,
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-<run-id>.md`,
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-latest.json`, and
  `docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-latest.md`. The scorecard must state what
  passed or failed, current critical/blocker and major counts, how many critical/blocker and major
  findings were resolved in the pass, how many new ones appeared, judge failures, and the next action.
- Holistic product UX direct-question scorecard in the machine-readable evidence. It must answer
  whether the whole experience feels production-grade, whether the UI is modern/easy/appealing,
  whether navigation and information architecture center community jobs-to-be-done, and whether the
  overall visible UI avoids blocking or major layout/content defects.
- Workflow/persona direct-question scorecards in the machine-readable evidence. Every workflow/persona
  pair must have its own answers about task clarity, domain-native primary surface, natural actions,
  input/validation/result states, receiver or unauthorized states, and whether that specific workflow
  feels production-grade on its own.
- Owner-accepted minor issue list, if any minor issues remain.
- Final pass/fail UX decision.
- B25 API Review if any API or platform contract issue is discovered, and B25 UX Decisions.

## Completed When

The independent review finds no unresolved blocker or major UX issues. Minor findings are either fixed,
explicitly accepted by the owner, or tracked with rationale. The final report states why the experience
does or does not meet production-grade UX standards for the target personas.

B25 cannot pass until the production UX blueprint exists, covers every community/test app and persona,
and is used as the explicit target for the screen review. If the blueprint is missing, incomplete,
generic, or disconnected from the implemented UI, the review must fail before any pass decision.

The phase must remain incomplete when the visible app still exposes workflow machinery as the main user
experience, lacks domain-native information architecture, lacks realistic content for the task, or reads
like a QA/test harness even if all workflow automation passes.

The phase must also remain incomplete when the visible app looks materially below modern production app
quality: default demo styling dominates, controls overlap content, text is clipped or obscured,
repeated cards are the primary experience, modals read like implementation checklists, domain content is
too abstract to help a real user, or community identity and visual hierarchy are too weak to guide the
target persona.

The phase must also remain incomplete when any implemented user-facing screen/state is missing from the
screen review matrix, lacks a screenshot reference, lacks a product-UX verdict, or has an unresolved
blocker or major finding.

The phase must also remain incomplete when the evidence is internally inconsistent: a screenshot is
stale, a row claims remediation against an older image, a screenshot hash is missing, a row lacks
visible-text extraction, critiques are boilerplate, or the JSON/markdown/tracker disagree about
unresolved findings.

The phase must also remain incomplete when either direct-question pass is absent or weak. The holistic
pass must judge the whole product experience. The workflow/persona pass must judge each workflow for
each persona separately. A broad statement that the app looks good cannot substitute for per-workflow
evidence, and many local workflow passes cannot substitute for a coherent production-grade overall UI.

The phase must also remain incomplete when any primary workflow surface is still represented only by a
generic workflow card, checklist/review modal, metadata/settings page, or repeated card shell. These may
remain only as secondary-supporting surfaces with explicit owner acceptance; they cannot be the primary
production UX for events, donations, forms, messaging, care, volunteer, admin review, search, export, or
other user-facing community jobs.

If any blocker or major finding exists, B25 must enter the remediation loop: cluster findings by root
cause, apply UX/content/code fixes, rebuild and relaunch the visible Demo App, recapture screenshots,
rerun workflow and product UX evidence, regenerate the screen review matrix, and rerun the independent
product UX review. Commit that complete iteration before starting the next UX feedback loop or
correction batch. Repeat until blocker and major counts are zero. Do not stop at a failed review unless
the owner explicitly asks for review-only planning or pauses implementation.

## Required B25 v4 Gate Sequence

1. **Evidence integrity reset:** mark the prior B25 v3 pass as superseded, clear status placeholders,
   and create or refresh `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`.
2. **Live app capture:** relaunch the Demo App on the Android emulator from the current app commit and
   capture fresh screenshots for every screen/persona/state.
3. **Evidence collector:** run the deterministic B25 evidence collector to convert live workflow UI
   evidence into schema v4 B25 artifacts with screenshot hashes, timestamps, emulator/device metadata,
   visible text source, and app commit SHA:

   ```powershell
   wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id b25-v4-pass-1 --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md'
   ```

   The collector is not the judge. It may mark B25 as failed/pending until the independent UX review
   fills screen-specific critiques, holistic direct-question answers, workflow/persona scorecards,
   findings, remediation links, and final decision.
4. **Workflow/persona coverage collector:** run the deterministic coverage collector to prove the
   evidence has explicit entry/action/result screenshots for every workflow/persona combination before
   the independent judge sees it:

   ```powershell
   wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md'
   ```

   The coverage collector is still not a product-quality judge. It fails when screenshots are missing,
   personas are generic, or workflow/persona evidence cannot be tied to concrete screen rows.
5. **Visual inspection auditor:** run the deterministic visual auditor to inspect the actual screenshot
   pixels/layout before the independent judge. It must attach `visualInspection` to every screen row
   and fail on missing screenshots, checklist-modal-like overlays, repeated-card shells, thin-content
   screens, weak visual identity, or other visual signals that a fresh reviewer would flag:

   ```powershell
   wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_visual_inspection_auditor.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-visual-inspection-audit.md'
   ```

   This tool is not a subjective design reviewer, but it blocks the specific false-pass class where a
   screen passes because rows exist even though the screenshot visibly looks like a QA scaffold,
   repeated generic cards, or a checklist modal.
   If this tool exits nonzero, keep its JSON/markdown output and continue through the independent and
   production judges in the same pass so remediation tickets and the iteration scorecard are generated.
6. **Complete screen inventory:** inventory every user-facing screen, state, dialog, card, feed item,
   form, confirmation, error, empty state, persona variant, and action result. Do not sample.
7. **Schema v4 evidence generation:** write `independent-production-ux-review.json` with v4 fields:
   screenshot hash/timestamp, app commit SHA, visible text, UI-pattern classification,
   primary/secondary surface type, row-specific critique, findings, remediation IDs, and unresolved
   severity counts.
8. **Independent UX Judge:** run the distinct independent UX judge tool. It consumes only the evidence,
   screenshots, blueprint, workflow/persona coverage matrix, and pass criteria. It must write
   holistic direct-question answers, workflow/persona scorecards, screen-specific critiques, exact
   findings tied to screen rows/screenshots/personas/workflows, UX reference patterns to copy, and
   remediation-ticket inputs:

   ```powershell
   wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md'
   ```

   The independent judge must not receive worker implementation notes. It must not pass a row that
   cannot be justified from visible UI. For failed rows, it must search the internet or open-source
   projects for comparable production patterns when network access is available, record the selected
   references and URLs, and state what a worker should copy or adapt. If live research is unavailable,
   it must use the built-in B25 reference catalog and preserve refresh queries in the ticket.
9. **Holistic direct-question pass:** answer the whole-product questions in
   `holisticQuestionAnswers`:

   - Does the whole experience feel like a real production community app for the target users, not
     merely an implemented workflow harness?
   - Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona?
   - Is the overall information architecture organized around community content and real
     jobs-to-be-done instead of workflow lists or validation surfaces?
   - Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold,
     repeated-card, checklist-modal, and thin-content defects?

10. **Workflow/persona direct-question pass:** for every workflow/persona pair, write a
   `workflowPersonaScorecards` row answering:

   - Can this persona immediately understand what they are supposed to do?
   - Is the primary UI designed around the real community task rather than workflow mechanics?
   - Is the primary surface domain-native, not a generic card, checklist modal, or metadata page?
   - Are action labels natural and specific to the user job?
   - Are required inputs, validation, empty/error/review states, and success/result states clear?
   - If another persona receives or acts on the state, is that receiver UX clear?
   - Are unauthorized, read-only, hidden, or disabled states appropriate for this persona?
   - Does this workflow UI feel production-grade on its own?

11. **Production UX judge scorecard:** run the deterministic production judge against the independent
   judge's v4 evidence:

   ```powershell
   wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md'
   ```

   The production judge validates the independent judge output, emits the scorecard, and generates
   remediation tickets. It must fail if either the holistic direct-question pass or any
   workflow/persona direct-question pass is missing, partial, unsupported by visible evidence, or below
   the score threshold.
12. **Iteration scorecard:** generate a B25 iteration scorecard from the review JSON and judge scorecard:

   ```powershell
   wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md'
   ```

   Copy or write the same scorecard under a run-specific filename before the iteration commit. If this
   is not the first pass, pass the previous run-specific scorecard with `--previous` so the tool can
   count blocker/major findings resolved and introduced in the current pass.
13. **Domain-native surface gate:** fail every primary workflow still implemented as a generic repeated
   card, checklist/review dialog, metadata page, or improved-copy workflow shell. For each failure,
   create a target product-surface replacement plan.
14. **Remediation loop:** for blocker/major findings, implement the grouped fixes, rebuild, relaunch,
   recapture affected screenshots, regenerate v4 evidence, rerun tests/review, and commit the full
   iteration before the next UX feedback or remediation batch.
15. **Final production certification:** pass only when there are zero unresolved blocker/major findings,
   every screen row has fresh screenshot evidence and screen-specific critique, every primary workflow
   is domain-native, the holistic direct-question pass is green, every workflow/persona direct-question
   pass is green, the production UX judge scorecard has no blocking criterion failures, all required
   tests/gates pass, every pass has a B25 iteration scorecard proving convergence, and the tracker
   records the final iteration commit.

## Required B25 Agent/Tool Split

Use the split defined in [../Tools/ux-gate-judge-tools.md](../Tools/ux-gate-judge-tools.md):

| Role | B25 responsibility |
| --- | --- |
| Worker Agent | Applies UX/content/code/test fixes from a remediation plan. |
| Evidence Collector Tool | Captures screenshots, hashes, timestamps, visible text, app commit SHA, device metadata, and command output. |
| Visual Inspection Auditor Tool | Decodes screenshots and records pixel/layout signals for checklist modals, repeated-card shells, thin content, weak identity, default-scaffold feel, and missing/undecodable images. |
| Independent UX Judge Agent | Reviews only artifacts and screenshots, inspects the visual audit output, scores direct-question passes, and emits screen-specific critique/findings. |
| Production UX Judge CLI | Deterministically validates the independent judge output and emits the scorecard/tickets. |
| Remediation Planner | Converts judge failures into fix batches for the Worker Agent. |

The Worker Agent may not mark B25 complete. Only the Independent UX Judge output, Production UX Judge
scorecard, and deterministic phase gates can allow closeout.

## Prompt To Use

Use this prompt when executing B25:

```text
You are performing Phase B25: Independent Production UX Review.

Do not treat this as a workflow implementation checklist. Assume B21-B24 may have passed their planned
requirements, then independently review the actual visible UX as a product reviewer with a high
production bar. Workflow compliance is not product UX quality.

Do not treat absence of implementation words as sufficient. A UI that merely replaces workflow terms
with domain-ish labels can still fail. Your standard is a modern production community product: polished,
domain-specific, visually coherent, content-rich enough to be useful, and natural for the current
persona.

Use the visible Android emulator, final B12-B24 screenshot evidence, installed example/test
communities, personas, and workflow surfaces. Walk the app as real users in each persona would. Your
job is to find UX issues, improvement opportunities, confusing interactions, weak content, missing
states, visual hierarchy problems, accessibility gaps, trust/privacy/payment clarity problems, mobile
layout issues, poor persona fit, and awkward multi-persona handoffs.

Before writing the review, create a complete screen inventory. Include every community and test app,
every persona, every user-facing screen, every state of that screen, dialogs, cards, feed rows, forms,
confirmations, errors, empty states, persona variants, and action results. Do not sample. Each inventory
row must have a screenshot or evidence reference.

Before assigning any pass verdict, create or update the per-community production UX blueprint. For each
community/test app, define:
- target personas and their real jobs-to-be-done
- community identity and visual cues expected in a production app
- home screen information architecture and priority content
- required product surfaces, such as feed, inbox, event details, donation/payment, care/volunteer form,
  admin compose/review, receipt/history, export/status, messages/connections, or settings
- workflow-to-surface mapping, including actor, receiver, read-only, disabled, and hidden states
- realistic seed/content requirements needed to make the screen useful
- visual quality bar, including hierarchy, spacing, typography, component variety, and mobile behavior
- concrete pass examples and known anti-patterns for that community

If a community's blueprint is missing or only restates workflow metadata, mark that community as failed
and add a remediation item before evaluating screens.

For every screen inventory row, perform a critique at the same level of depth as a product review, not
a checklist. Answer:
- Does this feel like a real production product screen for the target user?
- Does it expose implementation, test, or workflow language?
- Is the information architecture domain-native?
- Is the content realistic, specific, and useful?
- Are labels, actions, and result states natural?
- Is the screen visually modern, scannable, accessible, and mobile-appropriate?
- Does the screen have clear hierarchy, spacing, typography, and visual rhythm?
- Does it look like a custom community product rather than a default Material demo scaffold?
- Are controls, floating buttons, chips, app bars, dialogs, and bottom areas free of overlap,
  clipping, crowding, and accidental occlusion?
- Does the screen avoid repetitive generic card patterns when a feed, detail page, form, inbox, receipt,
  calendar/event, donation, volunteer, care, admin, or member-specific surface would be more natural?
- Does the screen include enough domain-specific data for the user to understand and act without
  reading workflow mechanics?
- What is the real user trying to do here?
- What is missing, confusing, too dense, too technical, or visually weak?
- What must change before this row can pass?
- Which internet, design-system, or open-source reference pattern should the worker copy or adapt?
- Which parts of that reference pattern apply to this workflow/persona, and which parts should not be
  copied because Loom or the community context differs?

After the row-level critique, run the UX Judge in two direct-question passes. First answer the holistic
product questions once for the whole app/community experience. Then answer the workflow/persona
questions for each workflow/persona pair. Keep workflow/persona batches small enough that each answer
references visible text, screenshot evidence, and the real user task; do not collapse all workflows
into a single generic pass statement.

Before any pass verdict, run the visual inspection audit over every screenshot-backed screen row. The
audit must decode the actual screenshot pixels and record `visualInspection.status`, metrics, signals,
summary, and finding IDs. Treat missing/undecodable screenshots, checklist-modal-like overlays,
repeated-card shells, weak visual identity, thin content, default-scaffold visual treatment, or other
failed visual signals as major findings unless the row is explicitly outside the user-facing production
surface. A row cannot pass merely because no textual critique failure was found.

Do not use repeated boilerplate rationale across matrix rows. Each screen/state must receive a specific
critique grounded in what is visible in the screenshot and what that persona is trying to do. If the
matrix cannot explain why a particular screen is production-grade beyond generic language, mark the row
as failed or incomplete.

First ask whether the screen looks like a real product for this community. A Masjid member should see
announcements, events, donations, volunteer needs, care requests, or messages. A garden club member
should see garden tasks, events, plant exchanges, harvests, or requests. Do not accept a generic
workflow list, category chips, surface labels, implementation rationale, or metadata cards as the
primary production UX.

Fail the review when user-facing UI exposes implementation taxonomy, including but not limited to:
`Community workflows`, `[category] surface`, `workflow evidence`, `workflow`, `surface`, `Action
available for this role`, `Receives the result after the responsible role submits it`, or other text
that describes the framework instead of the community task.

Also fail the review when the product still looks like a QA/demo scaffold even without explicit
implementation terms. Treat the following as major findings:
- repeated workflow-card lists are the primary interaction model
- event, donation, care, volunteer, announcement, search, export, social, or admin actions lack real
  domain surfaces and instead open checklist/review dialogs
- chips and badges dominate the screen without adding user value
- labels are technically correct but awkward for users, such as abstract notification, citation,
  receipt, consent, or waiting-state phrasing without real context
- community cards use generic letter avatars when richer identity, imagery, or brand treatment is
  expected for the target product
- FABs, sticky controls, or system/debug chrome overlap content or obscure a card/action
- modals summarize validation requirements instead of showing the actual object being reviewed
- content is too generic to answer who, what, when, where, why, amount, audience, status, next step, or
  ownership questions
- screen structure and visual treatment are materially the same across unrelated communities that
  should have different jobs-to-be-done

For every reviewed workflow surface, verify the domain-native content and affordances a real user
expects:
- announcements: title, body, sender/author, audience, timestamp, delivery/read state
- events: title, date, time, location, capacity or attendance state, RSVP/change/cancel state
- payments/donations/dues: amount, payer context, visibility/privacy choice, receipt, failure/retry
- protected forms/care requests: public summary, private fields, privacy indicators, recipient state
- volunteer/tasks: shift/task details, owner, availability, signup/cancel state
- approvals/moderation: requested change, requester, approve/reject/comment actions, audit state
- search/AI/export/import: clear scope, source/citation/checksum/redaction, result or failure state
- social/messages/connections: thread participants, latest message preview, unread state, invite/block
  context, ad/sponsored disclosure where relevant
- community home/list: recognizable identity, useful summary, current activity, primary next action,
  and no overlapping shell controls

When a required domain concept is unavailable in seed data, the remediation is to improve seed content
or product copy, not to pass an abstract placeholder.

For each finding, record:
- community/test app
- persona and workflow, if relevant
- screenshot path or emulator capture
- severity: blocker, major, minor, or polish
- what a real user would experience
- why it matters
- recommended fix
- whether it blocks production UX pass

For each screen review matrix row, record:
- community/test app
- persona
- screen/state/dialog/card/feed/action result
- workflow or user job, if relevant
- screenshot/evidence reference
- real-user task
- product UX verdict: pass, fail, or needs owner acceptance
- exposed implementation language, if any
- IA/content critique
- visual/interaction critique
- accessibility/mobile critique
- severity
- required fix or owner-acceptance rationale
- retest result

For the machine-readable JSON evidence, record schemaVersion 4 and include:
- reviewStandardVersion: `b25-production-ux-v4`
- currentReviewRunId and any supersededReviewRunIds
- status and finalDecision
- blueprintPath and blueprintCoverage for every community/test app
- screenRows with unique rowId, community, persona, screen type, screenshot references, product verdict,
  screenshot hash, screenshotCapturedAt, appCommitSha, emulator/device metadata, visibleTextExtract,
  uiPatternClassification, primarySurfaceType, row-specific critique, severity, finding IDs,
  remediation IDs, and retest result
- findings with stable IDs, severity, affected rows, root-cause theme, required fix, and blocksPass
- holisticQuestionAnswers with direct questions, yes/no/partial answer, score, visible evidence,
  critique, and required fix
- workflowPersonaScorecards with one row per workflow/persona, each containing direct questions,
  answer, score, visible evidence, critique, and required fix
- visualInspection on every screen row, including decoded image metrics, visual signals, summary,
  finding IDs, and pass/fail status
- remediationIterations with fixes applied, tests run, screenshots refreshed, and remaining blocker or
  major counts
- iterationScorecardPath and priorIterationScorecardPath, when available
- unresolvedBlockerFindings, unresolvedMajorFindings, ownerAcceptedMinorFindings, and trackedPolish
- requiresRemediation, requiresRerun, and b25CanPass

The JSON evidence is invalid if rows reuse boilerplate critique, omit screenshot references, omit
screenshot hashes/timestamps, omit visible-text extracts, reference stale screenshots, omit blueprint
coverage, lack stable finding/remediation IDs, classify a primary workflow as generic-workflow-card, or
claim pass while unresolved blocker/major findings remain. It is also invalid if any screen row lacks
`visualInspection`, if visual inspection failed, or if the review claims a production-grade pass from
manual expected assertions rather than screenshot-derived visible text and actual pixels.

Severity rules:
- Blocker: prevents or seriously misleads task completion, creates privacy/payment/trust risk, exposes
  the wrong persona capability, breaks mobile layout, clips/occludes required content or action
  controls, or makes a required surface unusable.
- Major: the task works but the experience is confusing, unpolished, poorly labeled, missing important
  feedback, visually incoherent, inaccessible, exposes implementation taxonomy, lacks domain-native
  content/IA, relies on repetitive generic cards/checklist dialogs, has weak visual hierarchy or
  community identity, or is materially below production quality.
- Minor: small UX issue that should be fixed but does not materially undermine the task or production
  feel.
- Polish: optional improvement that would raise quality but does not block release. Do not classify
  overlap, clipping, generic demo scaffolding, thin domain content, checklist dialogs, or repeated-card
  primary UX as polish.

Pass criteria:
- No unresolved blocker or major findings.
- Minor findings are fixed, explicitly owner-accepted, or tracked with rationale.
- Every community/test app has a complete production UX blueprint and every reviewed screen is judged
  against that blueprint.
- The reviewer can state that the experience feels production-grade for the target user, not merely
  that workflows are implemented.
- The reviewer can state that the UI looks modern and intentionally designed, not only functional.
- The main user-facing screens are organized around community content and jobs-to-be-done, not a global
  workflow list or validation surface.
- Primary workflows use domain-specific product surfaces, not just generic cards with better labels.
- The holistic product UX direct-question pass is green.
- Every workflow/persona direct-question pass is green.
- Every screen row uses fresh screenshots captured from the app version under review, with screenshot
  hash, timestamp, device metadata, and app commit SHA recorded.
- Every screen row includes visible-text extraction and a screen-specific critique that cannot be reused
  unchanged for another unrelated screen.
- The visible UI has no blocking or major overlap, clipping, crowding, default-scaffold, repeated-card,
  checklist-modal, or thin-content findings.
- Every screen row has passing visual inspection based on screenshot pixels/layout, not only row
  metadata or expected assertions.
- Every implemented screen/state/dialog/card/feed/action result appears in the screen review matrix with
  screenshot evidence and a pass verdict, owner-accepted minor issue, or tracked polish finding.
- The schema version 4 JSON evidence is complete, non-boilerplate, screenshot-backed, fresh, and internally
  consistent with the markdown review, screen matrix, remediation loop, and tracker.
- The production UX judge scorecard assigns pass scores to every B25 pass criterion and has no blocking
  failures.
- Every review/remediation pass has an iteration scorecard that shows pass/fail, current unresolved
  critical/blocker and major counts, blocker/major findings resolved in the pass, new blocker/major
  findings introduced in the pass, judge failures, and next action.
- If a prior loop iteration failed, the remediation loop log proves that fixes were applied, screenshots
  were refreshed, evidence was regenerated, and the latest review now has zero unresolved blocker or
  major findings.

If the UX does not meet the bar, do not stop with only a failed report. Produce a remediation batch,
apply the fixes, retest, recapture evidence, rerun this review, and update the loop log. Keep the phase
incomplete until the latest loop iteration passes. Commit every completed B25 iteration before starting
the next feedback/remediation loop; the next loop may not begin from uncommitted review, evidence, test,
or remediation changes.
```

## Iteration Commit Gate

Before starting any next B25 UX feedback loop or correction batch:

- Stage only the current iteration's intended review, evidence, screenshot, test, remediation, tracker,
  and manifest changes.
- Run `git diff --staged` and confirm the staged scope belongs to the current B25 iteration.
- Run the affected validation commands listed in that iteration's remediation log.
- Commit the current iteration.
- Record the iteration commit SHA in
  `docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md` and this tracker.

The next UX feedback/remediation loop may not start from uncommitted B25 iteration changes.

## Evidence To Record

Production UX blueprint, independent UX review report, product UX screen review matrix, schema version 4
machine-readable review JSON, production UX judge scorecard, B25 iteration scorecards, B25 remediation
loop log, findings table, screenshot paths, remediation evidence, retest output, final pass/fail
statement, manifest rows, phase gate, analyzer, boundary lint, diff check, per-iteration commit SHAs,
and final closeout commit SHA.
