# B16 UX judge verdict — Ad-Free Community + Data Portability Community (2026-09-28)

Judge pass over six rows from the canonical `--mode full-b25` capture of 2026-09-28.
Frames read from `/home/fahd/b25evidence/B16/screenshots/` (start / primary_action /
primary_result per row, plus alternate_action / result_receiver where present). Product docs
reconciled: `ad-free-community-product-experience.md` and
`data-portability-community-product-experience.md` (persona tables, §5/§6, B25 addendum).

## Overall summary

**Five of six rows PASS; one (`export-checksum-evidence`) is UNPROVEN.** Every frame carries the
`LOCAL ENGINE` badge — the known campaign-wide limitation that judge-half frames depict the local
engine, recorded here once rather than per row.

On the sibling pass's export finding: **I do not inherit it, and for two of my four
export/transfer rows I reach the opposite conclusion, with a stated reason.** The sibling failed
`book-export-metadata` and `soccer-export-metadata` because the result frame did not show an
export had happened. Data Portability's `export-import-preview` and `export-transfer-rollback`
differ in a way visible in the pixels: their result frames each show an **appended History entry
with a fresh actor-and-timestamp line** (`transfer started · portability-owner-20 ·
2026-09-28T21:42:25Z`; `rollback started · portability-owner-20 · 2026-09-28T21:45:54Z`) plus an
orange running-state chip — a durable receipt of exactly the kind the sibling found missing. So
the sibling's finding is not campaign-wide across all export-class rows; it is about workflows
whose result surface renders no receipt. **One of my rows partially reproduces the sibling's
finding**: `export-checksum-evidence`'s only visible change is a single *unlabeled* ISO-timestamp
chip — a durable write, but one no member could read as a receipt — and that row I mark UNPROVEN
rather than FAIL because the card's state header and any checksum chip above the fold are cropped
out of every frame for this card.

Cross-row coherence worth recording: the ad-suppression result shows `Ads suppressed now: No`
with the linked entitlement's `$state: inactive` and `Cancelled At: 2026-09-28T21:40:15Z` — the
cancellation written minutes earlier by this same run's entitlement walkthrough. The
suppression state is being **derived live from the entitlement**, not parroted from seed data,
which is precisely what the doc requires ("Query-backed entitlement state").

---

## Row 1 — Ad-Free: member checkout

**Workflow:** `ad-off-member-checkout`
**Outcome:** PASS

- **Decision legible:** Yes. Start frame shows the community entry ("Turn off ads with clear
  purchase, entitlement, receipt, and community-funding proof"), signed in as *Shipped
  ad-off-member*, Member persona description, Giving tab active, and a `+ Buy ad-off` FAB. Tabs
  are Home / Giving / Messages — exactly the Member row of doc §3.1.
- **Primary action:** The action frame shows **"Retry payment"** (with **"Cancel checkout"** as
  the destructive alternate) — `retry payment` is one of the doc's required primary actions for
  this row. Domain verb, not a generic Submit.
- **Result:** The card that offered Retry payment now renders at state **"Review payment"** with
  `Price: 49.0`, `Plan: Annual ad-off`, `Suppresses eligible ads for one annual term.`,
  `Paying with Card ending 1123`, and actions Edit payment / **Checkout** / Cancel checkout — the
  doc's required price / payment method / coverage content, and a real state change
  (failure-path → review), matching the doc's review/failure/cancel state set. The
  result_receiver frame additionally shows the editable "Ad-off offer" form with a
  **"Disclosure accepted"** toggle — the doc's "disclosure is required before submission".
- **State label:** "Review payment" visible in the result; "Entitlement active" and "Receipt
  issued" visible on sibling cards. The *pre-action* card's own state chip is cropped above the
  viewport in the action frame (only its buttons are visible) — that one label is unproven, not
  failed.
- **Findings (non-failing):** the FAB reads "Buy ad-off" where doc §3 says "Turn off ads" —
  same domain verb, different wording. Payer identity appears as "Payer: Ad Off Member" on the
  receipt card, satisfying the payer requirement.

## Row 2 — Ad-Free: entitlement status

**Workflow:** `ad-off-entitlement-status`
**Outcome:** PASS

- **Decision legible:** Yes. The action frame shows the entitlement card in state
  **"Entitlement active"** with `Active since 2026-08-15…`, `Renews 2026-09-15`, `Entitlement
  ends 2026-10-15`, `Plan: Monthly ad-off`, and `Ad-free surfaces: Home feed promotions, Giving
  surfaces, Community ad slots` — the doc's required active state / renewal / affected surfaces,
  all present.
- **Primary action:** **"Manage subscription"** — the doc's first-listed required primary for
  this row — with "Deactivate ad-off" as the destructive alternate.
- **Result:** The same card now renders at state **"Plan change requested"** (orange warning
  chip) with a new field `Requested plan: Evidence requestedPlan` and actions **"Keep current
  plan"** / "Deactivate ad-off". That is the doc's change-requested state, a durable and legible
  state transition with the changed data visible.
- **State label:** Both "Entitlement active" (before) and "Plan change requested" (after) fully
  visible. Proven.
- **Findings (non-failing):** the requested-plan value is walkthrough-typed filler
  ("Evidence requestedPlan"), not a plausible plan name — acceptable as harness input, but it is
  the one generic-filler value on an otherwise realistic surface.

## Row 3 — Ad-Free: ad suppression

**Workflow:** `ad-off-ad-suppression`
**Outcome:** PASS

- **Decision legible:** Yes. The action frame shows the suppression-proof card (suppressed
  surfaces list, `Ads suppressed now: No` chip partially visible at top) with its two actions,
  plus a separate "New notification" card ("Ad-off checkout needs another attempt", "Notice:
  Checkout Retry", **Mark read**) — the doc's notification-delivery promise visibly rendered.
- **Primary action:** **"Mark reviewed"** — the doc's required primary — with "Restore ad-off"
  also offered.
- **Result:** State chip **"Suppression proof reviewed"** (green), suppressed surfaces list, the
  no-fill reason line, `Ads suppressed now: No`, and alternate **"Review later"** — the doc's
  required alternate — plus "Restore ad-off". The Linked Entitlements panel shows
  `$state: inactive`, `Change Requested At: 2026-09-28T21:39:55Z`, `Cancelled At:
  2026-09-28T21:40:15Z` — this run's own earlier writes, proving the suppression state is
  **entitlement-derived live**, which is what doc §6 requires ("Query-backed entitlement state").
  "Restore ad-off" being visible while suppression is inactive matches §7 ("restoration …
  hidden while entitlement-derived suppression is active" — it is inactive here, so shown is
  correct). No ad-click action appears anywhere, as §B25 requires.
- **State label:** "Suppression proof ready" (before, visible in the row-2 action frame) and
  "Suppression proof reviewed" (after). Proven.
- **Findings (non-failing):** the static description field still reads "Ads suppressed because
  this member has an active ad-off entitlement" while the derived chip says `Ads suppressed
  now: No` — the sentence is stored copy that no longer matches the derived state. Content
  inconsistency worth a ticket, not a workflow failure; the derived chip is the one the doc
  binds to the entitlement.

## Row 4 — Data Portability: export/import preview

**Workflow:** `export-import-preview`
**Outcome:** PASS

- **Decision legible:** Yes. Start frame: Export and Migration entry, signed in as *Evidence
  portability-owner*, Owner/Admin persona ("Selects export scope, verifies packages, transfers
  data, and starts rollbacks"), tabs Admin / Export / Transfer / Documents.
- **Primary action:** **"Start transfer"** (green), with **"Cancel"** as the reject path — a
  required primary from the doc's B25 addendum ("export, download export, start transfer,
  import data").
- **Result:** The card renders at **"Operation running"** with `Partner provider transfer
  preview`, `Operation: Transfer`, `3 components selected`, the redaction line "Phone numbers
  are excluded; member IDs are pseudonymized", `Destination: Northstar Community Cloud`, and a
  **History** section whose second entry is fresh from this run: `transfer started ·
  portability-owner-20 · 2026-09-28T21:42:25.723061Z`, followed by continuation actions
  **Confirm complete** / Record error / Cancel transfer. This is the doc §6 required proof
  (selected scope, redaction preview, destination) plus the addendum's "status,
  receipt/history/confirmation" — a genuine durable receipt, the exact thing the sibling pass
  found missing on its export rows.
- **State label:** "Operation running" visible in the result. The pre-action card's own state
  chip is cropped in the action frame (buttons only) — unproven for that single frame, not
  failed.
- **Doc reconciliation:** conforms. Change-scope path exists on the surface (a "Change scope"
  action is visible on the sibling full-bundle card; this card's own alternate is Cancel).

## Row 5 — Data Portability: checksum evidence

**Workflow:** `export-checksum-evidence`
**Outcome:** UNPROVEN

- **What the frames show:** the verification card with `Four files covering members, events,
  messages, and documents.`, `Verification: Passed`, `Transfer: Disabled`, a seeded history line
  `{result: passed, at: 2026-08-10T08:12:00Z, by: portability-owner}`, and actions **"Enable
  transfer"** / **"Export verification record"**. After the action, exactly one visible change:
  a new chip reading `2026-09-28T21:44:57.286377Z` — an **unlabeled** ISO timestamp — which does
  persist (it is still on the card in the next row's start frame), while both actions remain
  offered and `Transfer: Disabled` is unchanged.
- **Why UNPROVEN rather than PASS:** the card's **state header is cropped out of frame in every
  frame** for this card (all three frames start mid-card), so I cannot see its state label or
  anything above the fold — including whether a **checksum value** is rendered there. Doc §5
  requires "checksum, counts, pass/fail" on this surface and names "hidden checksum" as the
  anti-pattern; doc §6 requires "checksum, verification result, retry path". Verification
  result: proven ✓. Checksum: **not visible in any frame, and not provable absent** — cropping
  means not-visible ≠ not-rendered. Retry path: not visible. And the one visible result of the
  action is a chip a member cannot read: no label, no record id, no state change.
- **Why UNPROVEN rather than FAIL:** unlike the sibling pass's failed export rows, there *is* a
  visible durable write (the timestamp chip survives into the following row's frames), so "the
  result frame shows nothing happened" would be inaccurate. I reach a finding **adjacent to the
  sibling's** — the result does not show a *legible* export receipt — but the decisive evidence
  (state label, checksum chip) sits above the captured viewport, so the honest verdict is
  unproven, not failed.
- **On the checksum-gap caution:** for this community the missing-service explanation does
  **not** apply — the doc's 2026-08-27 header update says checksum generation *is* implemented
  ("the workflow service computes a real SHA-256 … a checksum field is `writableBy:
  \"platform\"`"), with the caveat that this workflow "records the digest of a bundle another
  workflow produced rather than generating one itself". So if the checksum truly is absent from
  the card (rather than cropped), that is a real finding against these frames on this community,
  not an honest declared gap — the declared gap here is the **transfer ID**, not the checksum. I
  cannot tell from these frames which it is, and say so rather than choosing.
- **Recapture suggestion:** this card needs one frame scrolled to its top (state chip + any
  checksum field) for the row to be judgeable.

## Row 6 — Data Portability: transfer rollback

**Workflow:** `export-transfer-rollback`
**Outcome:** PASS

- **Decision legible:** Yes. The action frame shows **"Roll back transfer"** (green) /
  **"Cancel rollback"** (red), with the schema-scope card and the "Awaiting provider
  verification" migration card (`Northstar provider migration`, `From: Data Portability
  Community`, `To: Northstar Community Cloud`) giving real context for what is being rolled
  back.
- **Primary action:** **"Roll back transfer"** — the domain verb, matching the doc's
  rollback path.
- **Result:** The rollback card renders at **"Rollback running"** (orange) with `Northstar
  rollback request`, `From: Data Portability Community`, `To: Northstar Community Cloud`, the
  rollback reason **"Destination validation found an unexpected document count."**,
  `Available: Yes`, `Status: Running`, a fresh chip `2026-09-28T21:45:54.502524Z`, and a
  **History** entry from this run: `rollback started · portability-owner-20 ·
  2026-09-28T21:45:54.502562Z`, with continuation actions **Confirm rollback complete** /
  Record rollback failure / Cancel rollback. Doc §6 required proof — rollback reason,
  source/destination, rollback availability — all visible; durable receipt via the history
  entry.
- **State label:** "Rollback running" visible in the result; the pre-action card's own chip is
  cropped in the action frame (buttons only) — unproven for that frame, not failed.
- **Findings (non-failing):** the doc's card-registry row also lists a "completed state"; these
  frames end at Running with "Confirm rollback complete" offered but not exercised, which is
  consistent with a three-frame arc — noting it so nobody reads this PASS as covering the
  completed state.

---

## Tally

| Row | Outcome |
| --- | --- |
| `ad-off-member-checkout` | PASS |
| `ad-off-entitlement-status` | PASS |
| `ad-off-ad-suppression` | PASS |
| `export-import-preview` | PASS |
| `export-checksum-evidence` | UNPROVEN |
| `export-transfer-rollback` | PASS |
