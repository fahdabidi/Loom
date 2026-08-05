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
| D.3 | ✅ Closed (2026-08-05, commit `2c79617b`). Pay transition, real effects, and fix the `receiptStatus` render bug | New test taps the real "Pay $15" button and confirms `currentState: paid`, `receiptStatus: complete`, `paidAt` set for real. The render bug had a different root cause than Marketplace's (Giving uses the shared `GenericWorkflowInstanceCard`, not a bespoke card): `_isVisibleField` fell back to the field *key* as a label for any unlabeled field, so `receiptStatus` literally rendered as "receiptStatus". Fixed by suppressing effect-owned fields with no declared `labelTemplate` (`paidAt`, which has a real label, still renders correctly). Verified independently: `flutter analyze` clean, 174/175 green (only the known a11 flake). First-try success. |
| D.4 | ✅ Closed (2026-08-05, commit `4f596188`). **Cross-workflow proof**: paying here satisfies Marketplace's `borrow` guard | New test drives the real UI chain end to end: confirms `Request loan` absent on Catan while unpaid (via the real widget tree, not an engine query), taps the real Giving "Pay $15" button, then confirms `Request loan` appears on Catan afterward — all through real widget assertions. This is the exact manual proof from Phase C's C.7 live walk, now a permanent automated test. Verified independently: `flutter analyze` clean, 175/176 green (only the known a11 flake). First-try success. |
| D.5 | ✅ Closed (2026-08-05, commit `fce01baf`). Tab theme cascade verified visually | A real bug, found via my own live emulator spot-check (Marketplace vs. Giving looked visually indistinguishable): the JSON-resolved `#8A5A34` accent was already threading correctly to `_SelectedTabHeader`, but `EngineNativeArchetypeCard`'s generic-card dispatch branches dropped the resolved `LoomCardTheme` before reaching `GenericWorkflowInstanceCard` — so Giving's card content (fact pills, Pay button) silently fell back to ambient/community styling. Fixed by threading `modernTheme` through `GenericWorkflowInstanceCard` and `WorkflowActionButtonRow`, fully additive (every new param defaults to null, falling back to prior styling via `??` — confirmed zero risk to other tabs/`EquipmentLoanArchetypeCard`'s existing calls). New widget-level color assertions added rather than relying on a screenshot, per the ticket's own instruction once eyeballing two similar browns turned out to be unreliable. Verified independently: `flutter analyze` clean, 175/176 app-shell green (only the known a11 flake) plus `b26_package_driven_experience_test.dart` (different package) unaffected at 3/3. |
| D.6 | ✅ Closed (2026-08-05, decision recorded). Receipt-id platform service: implement **or** record as a named gap | **Decision: (b) — ship without a receipt id, recorded as a named gap.** Payment processing and ID generation are opaque platform services (ComputationModel.md §8), not field math — a real implementation would mean standing up new engine-provided, community-agnostic infrastructure (even demo-stubbed) purely to generate a fake-but-real-looking id string for a demo dues payment. That's disproportionate to this milestone's actual goal (proving the workflow renders and transitions correctly from JSON), and the JSON's own comment already argues against faking it: "a hardcoded id masquerading as a generated one is exactly the anti-pattern the audit flagged." `receiptStatus`/`paidAt` (D.3) already give a real, honest confirmation that payment succeeded — the absence of a `receiptId` field is the correct, honest state, not an oversight. Revisit only if a future phase actually needs a real platform-services boundary (e.g. a second payment-driven workflow that would otherwise duplicate this decision). |
| D.7 | ✅ Closed (2026-08-05). Live walk + evidence matrix + random regression re-check | See closure evidence below. |

### D.7 closure evidence (2026-08-05)

Live walk on the same real Android emulator used for Phase C's C.7 (rebuilt APK with all D.1-D.6 fixes,
fresh Tabletop Club install, real "Add local community" flow):

- Paid dues for real as Member: the "Pay $15" button now renders in the real, distinctly deeper themed
  brown (visually confirming D.5's fix on-device, not just via widget-test color assertions) — before the
  fix it was indistinguishable from the community's default teal/orange styling.
- The `receiptStatus` raw-field-name pill (D.3's bug) is confirmed gone in this same rebuild.
- Random regression spot-check: Home (tournament ballot, vote counts, "Propose a game" FAB) and Calendar
  (Month/Week/Day/Pending scope selector, real July 2026 grid with seeded events) both render correctly —
  no regressions from any of D.1-D.6's changes, including the shared-file changes in D.5
  (`part18_marketplace_rendering.dart`, `part26_generic_instance_card.dart`) that touch code paths used by
  Marketplace and other generic-card tabs too.
- Full automated suites green throughout: `loom_communities_app_shell` (175/176, only the known a11 flake)
  and `b26_package_driven_experience_test.dart` (a different package, 3/3, confirming the theme-cascade fix
  didn't regress its own existing regression guard).

## Definition of done

- [x] Giving renders from JSON; zero bespoke Dart for the dues workflow (D.1/D.2, GP.2).
- [x] Paying dues genuinely unlocks Marketplace borrowing (cross-workflow guard, end-to-end) (D.4).
- [x] The Giving tab's distinct accent comes from the JSON cascade, verified on-device (D.5).
- [x] Receipt id is either really generated or honestly absent — never faked (D.6: decided honestly absent, recorded above).
