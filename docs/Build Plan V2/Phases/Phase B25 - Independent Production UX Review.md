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
  `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json` using schema version 3. The
  JSON must include the review standard version, superseded prior run IDs, blueprint path, every screen
  row with a unique row ID and screen-specific critique, finding-to-remediation links, before/after
  screenshot references for fixed issues, unresolved severity counts, rerun requirements, and the final
  pass/fail decision.
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

If any blocker or major finding exists, B25 must enter the remediation loop: cluster findings by root
cause, apply UX/content/code fixes, rebuild and relaunch the visible Demo App, recapture screenshots,
rerun workflow and product UX evidence, regenerate the screen review matrix, and rerun the independent
product UX review. Commit that complete iteration before starting the next UX feedback loop or
correction batch. Repeat until blocker and major counts are zero. Do not stop at a failed review unless
the owner explicitly asks for review-only planning or pauses implementation.

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

For the machine-readable JSON evidence, record schemaVersion 3 and include:
- reviewStandardVersion: `b25-production-ux-v3`
- currentReviewRunId and any supersededReviewRunIds
- status and finalDecision
- blueprintPath and blueprintCoverage for every community/test app
- screenRows with unique rowId, community, persona, screen type, screenshot references, product verdict,
  row-specific critique, severity, finding IDs, remediation IDs, and retest result
- findings with stable IDs, severity, affected rows, root-cause theme, required fix, and blocksPass
- remediationIterations with fixes applied, tests run, screenshots refreshed, and remaining blocker or
  major counts
- unresolvedBlockerFindings, unresolvedMajorFindings, ownerAcceptedMinorFindings, and trackedPolish
- requiresRemediation, requiresRerun, and b25CanPass

The JSON evidence is invalid if rows reuse boilerplate critique, omit screenshot references, omit
blueprint coverage, lack stable finding/remediation IDs, or claim pass while unresolved blocker/major
findings remain.

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
- The visible UI has no blocking or major overlap, clipping, crowding, default-scaffold, repeated-card,
  checklist-modal, or thin-content findings.
- Every implemented screen/state/dialog/card/feed/action result appears in the screen review matrix with
  screenshot evidence and a pass verdict, owner-accepted minor issue, or tracked polish finding.
- The schema version 3 JSON evidence is complete, non-boilerplate, screenshot-backed, and internally
  consistent with the markdown review, screen matrix, remediation loop, and tracker.
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

Production UX blueprint, independent UX review report, product UX screen review matrix, schema version 3
machine-readable review JSON, B25 remediation loop log, findings table, screenshot paths, remediation
evidence, retest output, final pass/fail statement, manifest rows, phase gate, analyzer, boundary lint,
diff check, per-iteration commit SHAs, and final closeout commit SHA.
