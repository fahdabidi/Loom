# Phase B25 - UX Decisions

## Decisions

- Review the product experience outside-in rather than verifying only that workflow requirements were
  implemented.
- Split workflow compliance from product UX review. Passing B21-B24 proves execution and evidence, but
  B25 must independently decide whether the visible app feels like a production community product.
- Require a complete screen-by-screen review matrix before B25 can pass. The matrix must inventory every
  implemented screen, state, dialog, card, feed item, form, confirmation, error, empty state, persona
  variant, and action result across every example/test community and persona.
- Require B25 schema version 4 evidence. Every screen row must include screenshot hash, captured-at
  timestamp, app commit SHA, emulator/device metadata, visible-text extraction, UI-pattern
  classification, primary/secondary surface type, row-specific critique, severity, finding IDs,
  remediation IDs, and retest result.
- Reject stale evidence. A screenshot is invalid when it predates the app commit/remediation it claims
  to prove, when a resolved finding points to a pre-fix image, or when the JSON/markdown/tracker
  disagree about the current review run.
- Do not allow sampling. Every matrix row needs screenshot evidence, real-user task framing, a product
  UX verdict, critique across IA/content/visual/interaction/accessibility/mobile quality, severity,
  required fix or owner-acceptance rationale, and retest result.
- Do not allow boilerplate critique. Every row must describe visible UI elements and visible text from
  the screenshot. Reused generic rationale across unrelated screens invalidates the review.
- Classify the primary UI pattern for every workflow surface. Primary workflows must use domain-native
  surfaces; a generic workflow card, checklist/review modal, metadata/settings page, or repeated card
  shell is a major finding even when labels are improved.
- Separate the B25 roles. The Worker Agent implements fixes, the Evidence Collector Tool captures
  artifacts, the Production UX Judge Agent scores artifacts only, and the Remediation Planner turns
  judge failures into the next fix batch.
- Require the production UX judge scorecard. B25 cannot pass until
  `production-ux-criteria-scorecard.json` and `.md` assign score/verdict/blocksPass/why/requiredFix to
  every B25 pass criterion with no blocking failures.
- Require direct questions in the B25 judge. Declarative criteria such as "looks modern" are not enough;
  the judge must answer concrete questions like "Is the UI modern, easy to use, easy to navigate, and
  visually appealing for the target persona?" from screenshots and visible text.
- Split the judge into one holistic product UX pass plus many workflow/persona passes. The holistic pass
  protects whole-app coherence, navigation, visual identity, and product feel. The workflow/persona
  passes protect task-level usability, domain-native surfaces, natural actions, validation/result
  states, receiver states, and unauthorized/read-only behavior.
- Require both direct-question passes to be green. A polished overall shell cannot hide a weak workflow,
  and many technically usable workflow screens cannot hide an incoherent or non-production overall UI.
- Batch workflow/persona review in small evidence groups when needed. Do not ask the judge to summarize
  all workflows in one answer; every workflow/persona answer must cite visible screenshot evidence and
  a screen-specific critique.
- Require an iteration scorecard after every B25 pass. The scorecard must show whether the pass
  succeeded, current critical/blocker and major counts, unresolved counts, how many blocker/major
  findings were resolved in that pass, how many new blocker/major findings appeared, judge failures, and
  the next action. This makes convergence visible instead of relying on a single final pass/fail row.
- Treat exposed workflow machinery as a major or blocker UX issue when it appears in user-facing UI:
  `Community workflows`, `[category] surface`, framework rationale copy, metadata-only cards, global
  workflow lists, or test-harness state language.
- Require domain-native information architecture. Community homes and workflow entry points should be
  organized around real user content such as announcements, upcoming events, donations, volunteer needs,
  care requests, documents, messages, teams, facilities, or equivalent sections for the community.
- Require realistic domain content and affordances before a UX pass: announcement bodies/authors/times,
  event date/time/location/capacity, donation/payment details and receipts, protected-data indicators,
  recipient states, and clear next actions where applicable.
- Rank findings as blocker, major, minor, or polish.
- Require no unresolved blocker or major findings before passing.
- Treat B25 as an iterative remediation loop. A failed review is not the terminal output of the phase;
  it creates a remediation batch, implementation pass, rebuilt/relaunched app, refreshed screenshots,
  regenerated screen matrix, and rerun review.
- Require a B25 remediation loop log for each iteration, including review result, root-cause clusters,
  fixes applied, tests run, screenshots refreshed, remaining blocker/major findings, and latest
  pass/fail decision.
- Require a git commit after each B25 review/remediation iteration before the next UX feedback loop or
  correction batch starts. This preserves review evidence, fixes, refreshed screenshots or screenshot
  references, tests, remaining findings, and tracker updates as an auditable boundary.
- Supersede the prior B25 pass. The existing v3 evidence proved prototype/demo-harness improvements,
  but the visible app still needs a stricter v4 product UX review against screenshot freshness,
  non-boilerplate critique, and domain-native primary-surface criteria before B25 can be considered
  complete.

## Evidence

- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/production-ux-criteria-scorecard.json`
- `docs/Build Plan V2/Evidence/B25/production-ux-criteria-scorecard.md`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md`
- Prior `wf_independent-production-ux-review` pass is superseded by the product-UX review v4 criteria
  and must be rerun through the remediation loop until it passes.
- Every B25 remediation-loop row must include the git commit SHA for that iteration before a subsequent
  UX feedback/remediation iteration begins.
