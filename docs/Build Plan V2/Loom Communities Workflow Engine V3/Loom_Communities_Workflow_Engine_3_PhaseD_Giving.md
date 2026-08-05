# Phase D — Giving tab (quarterly dues)

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). Phase A, B, and C are all closed.

## Process note (2026-08-05, before starting)

Investigated current reality before dispatching anything, since this doc predates and was never updated
after an earlier "GP.1/GP.2" pass (2026-07-17, commits `fb788051`/`bad6f1bb`/`08bb3b2a`) already did real
work here — the same kind of stale-doc situation Phase C's own process note found for Marketplace.

- **D.1 and D.2 are substantially done.** GP.2 widened `_enabledTabs` to include `'giving'`, wired
  `part02_tab_shell.dart`'s Giving dispatch through `_hasEngineNativeBinding` to the real
  `EngineNativeListSurface` (the same generic pipeline Calendar/Home/Marketplace use — not a bespoke
  widget), and added `v3_milestone_gp2_giving_end_to_end_test.dart`, which proves the real seeded
  `dues-2026-q3-member` instance renders through `GenericWorkflowInstanceCard` with real `$15.00`/"Quarterly
  club dues" data and a real "Pay $15" button. Independently re-verified as part of this session's own
  full-suite runs throughout Phase C (this test has been green in every run).
- **What GP.2's test does *not* prove**: it never taps Pay. No automated test transitions the instance to
  `paid`, checks `receiptStatus`/`paidAt`, or drives Marketplace's `borrow` guard through the real Giving UI
  (Marketplace's own C.3 test seeds `paid` directly via `applyTransition`, bypassing the Giving UI entirely).
  D.3 and D.4 are genuinely open.
- **A real bug already found**: during Phase C's C.7 live walk, I personally paid dues through the real
  Giving UI on a real emulator and saw a `receiptStatus` fact pill rendered as the literal text
  "receiptStatus" — the same class of unlabeled-field-name bug fixed for Marketplace's `queueLength`/
  `isAvailable` (Phase C.7 fix1, commit `ae3282e2`), but never fixed here since it was explicitly out of
  scope for that ticket.
- **D.5-D.7 are untouched** — no test or screenshot evidence confirms the tab theme cascade, no formal
  decision is recorded for D.6, and D.7's live walk was only ever a byproduct of Phase C's own walk, not a
  dedicated Giving audit.

**Conclusion**: this phase is closer to "close out what's already real and fill genuine gaps" than "build
from scratch" — mirroring Phase C's own discovery. D.1/D.2 get checked off with evidence below; D.3-D.7
proceed as originally scoped.

## Goal

The smallest phase — a two-state payment workflow — but it carries two things worth getting right: the
**tab theme cascade** and the **platform-services boundary**.

## What must genuinely work

| Workflow type | Instance | Must genuinely work |
|---|---|---|
| `tabletop-club-dues-payment` | `dues-2026-q3-member` (`unpaid`) | Pay → `paid` (terminal), sets `receiptStatus` + `paidAt` (`$timestamp`). Once paid, **Marketplace's `borrow` guard is satisfied** — the cross-workflow link is the real proof this workflow means something. |

## Two things this phase must prove

**1. The tab theme cascade actually applies.** The JSON gives the Giving tab a deeper accent
(`tabThemes: { "giving": { "accent": "#8A5A34" } }`) than the community's `#C4703F`. This is a
**deliberate, tested feature** (`b26_package_driven_experience_test.dart`), not a bug — Giving must
visibly render in the deeper terracotta while every other tab uses the community accent. If it doesn't,
the cascade is broken and that's a real finding.

**2. The platform-services boundary is honest.** A real receipt id cannot be a field formula — payment
processing and ID generation are **opaque platform services** (ComputationModel.md §8): they'd call a
gateway in production and are **demo-stubbed** (canned success + generated id) here. The JSON deliberately
does **not** hardcode a `receiptId`, because a hardcoded id masquerading as a generated one is exactly
the anti-pattern the archetype audit flagged.

**Decision required in this phase:** either (a) implement the ID-generation platform service for real
(engine-provided, community-agnostic, demo-stubbed), or (b) ship without a receipt id and record it as a
named gap. **Do not** fake it with a hardcoded string.

## User stories

- *As a member, I see my outstanding dues and pay them.*
- *As a member, after paying I see a receipt/confirmation and my status is "paid".*
- *As a member, paying dues unlocks borrowing from the library.*
- *As anyone, the Giving tab is visibly themed differently — and the difference comes from the JSON, not
  from hardcoded widget colors.*

## Milestones

| # | Milestone | Notes |
|---|---|---|
| D.1 | ✅ Closed (GP.2, 2026-07-17, commit `bad6f1bb`; confirmed still green throughout this session). Turn on `tabId: "giving"` in the binding dispatcher | Same flip as B.1/C.1. |
| D.2 | ✅ Closed (GP.2). `paymentCheckout` rendering through the generic card | Renders via the real `EngineNativeListSurface`/`GenericWorkflowInstanceCard` pipeline, not a bespoke widget. Real fact pills present (amount, purpose, entitlement) — the `receiptStatus` unlabeled-field-name bug found in C.7 is a D.3-adjacent gap (it only appears post-payment), tracked there, not blocking this closure. |
| D.3 | Pay transition, real effects, and fix the `receiptStatus` render bug | Tap Pay for real in a widget test; assert `receiptStatus`/`paidAt` (via `$timestamp`) update for real on the instance. Also fix `receiptStatus` rendering as its literal field name instead of a real value or a proper label — same class of bug as Marketplace's C.7 fix1 (computed/effect-written field with no `labelTemplate` leaking raw). |
| D.4 | **Cross-workflow proof**: paying here satisfies Marketplace's `borrow` guard | The same guard C.3 already proved at the engine level — now drive it through the *real Giving UI* pay action, then confirm Marketplace's `borrow` becomes available, end to end in one test. |
| D.5 | Tab theme cascade verified visually | Screenshot showing Giving in `#8A5A34` while Calendar/Home use `#C4703F`. |
| D.6 | Receipt-id platform service: implement **or** record as a named gap | An explicit decision, written down. No hardcoded receipt ids. |
| D.7 | Live walk + evidence matrix + random regression re-check | Full-tab audit. |

## Definition of done

- [x] Giving renders from JSON; zero bespoke Dart for the dues workflow (D.1/D.2, GP.2).
- [ ] Paying dues genuinely unlocks Marketplace borrowing (cross-workflow guard, end-to-end) (D.4).
- [ ] The Giving tab's distinct accent comes from the JSON cascade, verified on-device (D.5).
- [ ] Receipt id is either really generated or honestly absent — never faked (D.6).
