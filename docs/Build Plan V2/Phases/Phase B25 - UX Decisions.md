# Phase B25 - UX Decisions

## Decisions

- Review the product experience outside-in rather than verifying only that workflow requirements were
  implemented.
- Split workflow compliance from product UX review. Passing B21-B24 proves execution and evidence, but
  B25 must independently decide whether the visible app feels like a production community product.
- Require a complete screen-by-screen review matrix before B25 can pass. The matrix must inventory every
  implemented screen, state, dialog, card, feed item, form, confirmation, error, empty state, persona
  variant, and action result across every example/test community and persona.
- Do not allow sampling. Every matrix row needs screenshot evidence, real-user task framing, a product
  UX verdict, critique across IA/content/visual/interaction/accessibility/mobile quality, severity,
  required fix or owner-acceptance rationale, and retest result.
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
- Supersede the prior B25 pass. The existing evidence proved workflow-compliance improvements, but the
  visible app still needs a stricter product UX review against the revised criteria before B25 can be
  considered complete.

## Evidence

- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md`
- Prior `wf_independent-production-ux-review` pass is superseded by the product-UX review v2 criteria
  and must be rerun through the remediation loop until it passes.
