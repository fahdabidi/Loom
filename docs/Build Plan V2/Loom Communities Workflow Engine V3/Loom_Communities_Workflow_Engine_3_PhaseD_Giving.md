# Phase D — Giving tab (quarterly dues)

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). **Blocked on Phase A.**

> **Scoping note.** Firm on scope, light on snippets — detailed kickoffs are written after Phase A's
> human gate, against the revised JSON.

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
| D.1 | Turn on `tabId: "giving"` in the binding dispatcher | Same flip as B.1/C.1. |
| D.2 | `paymentCheckout` rendering through the generic card | Fact pills from the schema (`amountLabel`, `purpose`, `cadence`, `entitlement`), each with its own `displayIcon` — **not** the shared checkmark the audit found on every pill. |
| D.3 | Pay transition, real effects | `receiptStatus`, `paidAt` via `$timestamp`. |
| D.4 | **Cross-workflow proof**: paying here satisfies Marketplace's `borrow` guard | The same test from C.5, now driven by really paying rather than seeding `paid`. |
| D.5 | Tab theme cascade verified visually | Screenshot showing Giving in `#8A5A34` while Calendar/Home use `#C4703F`. |
| D.6 | Receipt-id platform service: implement **or** record as a named gap | An explicit decision, written down. No hardcoded receipt ids. |
| D.7 | Live walk + evidence matrix + random regression re-check | Full-tab audit. |

## Definition of done

- [ ] Giving renders from JSON; zero bespoke Dart for the dues workflow.
- [ ] Paying dues genuinely unlocks Marketplace borrowing (cross-workflow guard, end-to-end).
- [ ] The Giving tab's distinct accent comes from the JSON cascade, verified on-device.
- [ ] Receipt id is either really generated or honestly absent — never faked.
