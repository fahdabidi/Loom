# UX judge verdict — Ad-Free Community / `ad-off-community-checkout` (B25 row)

**Date judged:** 2026-09-09
**Verdict: PASS** on the B25 bar (primary + alternate/change/reject affordances visibly present and
comprehensible to the driving persona), judged from the pixels in this directory against
`MANIFEST.md`, with one visibility finding on the `createInstance` effect (below) and several ticket
discrepancies recorded for the dispatcher.

## Ticket vs manifest — the manifest wins, and here is where they disagreed

The judge ticket carried stale specifics from a sibling ticket. Judged against what is actually here:

| Ticket claimed | Actually |
|---|---|
| path `…/b25-ad-off-community-checkout-20260909/` | directory is `b25-adfree-community-checkout-20260909/` |
| `manifest.md` | `MANIFEST.md` |
| "14 judge-relevant frames" | 38 frames, `01`–`39` (no `27`; two captures went to /tmp per manifest) |
| entry 29, action 39, result 40, regression 42, terminal 43 | frames 40–43 do not exist; the last frame is `39-funded.png` |
| "created … to `published`, then driven to the terminal state `delisted`" | flow is create → `unfunded` → `reviewing` → `funding-pending` → **`funded`** |
| driven as role `member` | manifest and pixels both say role `ad-off-owner` ("Owner"); frames 14/15/30 read "Signed in as Ad Off Owner 1 — Owner" |

## What the frames show (all statements below are from pixels I viewed)

- **Entry / create (primary):** frame 15 — Giving tab active, FAB **"Fund community ad-off"**
  clearly visible. Frame 16 — create dialog "Fund community ad-off" with all seven fields
  (Funding amount, Currency, Coverage Duration Days, Coverage Description, Paying with,
  Utility impact, Allocation) and **Create** (primary) + **Cancel** (reject).
- **`unfunded`:** frame 32 — the created card with every typed value visible
  ("Community ad suppression", "Community operations card", "Funds ad-free access",
  "Ad-serving replacement"), a disabled "Save changes" with honest helper text
  ("No changes to save yet."), and primary transition **"Give community ad-off"**.
- **`reviewing`:** frame 35 — badge "Review community funding", chips Funding amount: 250 /
  Coverage: 90 days / Community ad suppression / Utility impact. Primary **"Checkout funding"**,
  change **"Change amount or payment"**, reject **"Cancel funding"**. A textbook
  primary/change/reject triple, all on one screen.
- **`funding-pending`:** frame 36 — badge "Funding awaiting verification" (correctly warning-toned),
  primary **"Record verified funding"**, alternate **"Record funding failure"**, reject
  **"Cancel funding"**. Frame 37 — the "Record verified funding" dialog prompting for
  **Coverage Ends At**, with its own Cancel + confirm.
- **`funded` (final frame, 39):** badge "Community ad-off funded", chips including
  **Funded 2026-09-09T19:51:58.411618Z** and **Coverage ends 2026-12-08** — both agreeing with the
  manifest's database read-back — and the sole remaining exit **"Request funding refund"**.

**Affordance matching:** all matches above are whole-label, distinct button spans. Primary and
alternate labels share the word "funding" across *separate* buttons, which is not containment; no
span claimed as an alternate was also counted as primary.

**Comprehensibility to the persona:** the Owner's role blurb on screen ("Records payment outcomes,
funds community ad-off, and audits settlement and utility allocation", frames 14/15/30) matches the
affordances offered; every state badge is plain-language and correctly toned (info for review,
warning for awaiting verification, success for funded, red for cancel/refund). Comprehensible.

## The `createInstance` effect: proven in the database, NOT visible in the frames

The ticket asked specifically. The manifest (and Postgres, per the dispatcher) prove
`ad-off-settlement-utility` was spawned in `allocated` with a back-reference to this checkout.
**No frame shows any settlement or allocation surface.** The run ends at frame 39, which shows the
funded checkout card and the entitlement card below it; nothing on that screen names the settlement
instance, and no later frame exists. The Owner's own role description promises "audits settlement
and utility allocation", so a surface plausibly exists (perhaps on the Admin tab) — but it was not
captured, and I will not infer it. **Finding: the effect's result has no visible consequence in this
evidence set.** This does not fail the B25 bar for `ad-off-community-checkout` (the row's own
affordances are fully proven), but "member sees the settlement appear" remains unproven by pixels.

## Incidental observations

- Frame 30 is named `created` but shows the top of the Giving tab (community header), not the new
  card; the card itself is proven by frame 32. Harmless naming, worth knowing when citing frames.
- Frame 31's "Suppression proof ready" card references a *different, pre-existing* instance
  (`ad-off-member-checkout_9kmvxftjpbjr`, fan `fan-ad-off-member-1`) — background content, not
  evidence about this row.
- Nothing in any viewed frame contradicts the manifest. Screen text agrees with the manifest's
  stored `instance_data` on every value I could see, including the two fields retyped after the
  documented `adb input text` truncation.

## What I could not judge

- Frames 40–43 (named in the ticket): do not exist; nothing to judge.
- Visibility of the settlement instance: no frame shows it (detailed above).
- Frames 01–13 (launch/sign-in chrome) and 17–29 (form-filling intermediates): not individually
  reviewed beyond the manifest's account; none is load-bearing for the affordance bar, which is
  carried entirely by frames 15, 16, 32, 35, 36, 37 and 39.
