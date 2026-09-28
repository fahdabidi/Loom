# B16 UX judge — Ad-Free Community & Data Portability Community (capture of 2026-09-28)

Judge pass over six rows from the canonical `--mode full-b25` run of 2026-09-28. Frames read from
`/home/fahd/b25evidence/B16/screenshots/` (all 18 required PNGs present, none zero-byte). Each row was
judged as a three-frame sequence (`start` → `primary_action` → `primary_result`) against the community's
product doc (§5/§6/§7 and the B25 semantic interaction model addendum).

## Overall summary

**Five of six rows pass; one fails.**

- **Pass:** `ad-off-member-checkout`, `ad-off-entitlement-status`, `ad-off-ad-suppression`,
  `export-import-preview`, `export-transfer-rollback`.
- **Fail:** `export-checksum-evidence` — the result frame's only visible change is a new **unlabeled raw
  ISO timestamp chip**; no state change, no history entry, no visible exported record, and the
  doc-required checksum digest is not visible in any of the three frames.

**On the sibling pass's export-row finding** (the B14 judge failed `book-export-metadata` and
`soccer-export-metadata` because the result frame did not show an export had happened): I reach the
**same finding for one row and the opposite for two, and the frames themselves explain the split.**
`export-checksum-evidence` fails on exactly the sibling's grounds — an action that leaves no legible
receipt. But `export-import-preview` and `export-transfer-rollback` pass because their result frames show
precisely what the failed rows lacked: a changed state chip (`Operation running` / `Rollback running`)
**plus a History entry naming the action, the actor, and this run's timestamp** ("transfer started ·
portability-owner-20 · 2026-09-28T21:42:25Z"; "rollback started · portability-owner-20 ·
2026-09-28T21:45:54Z"). This is not an echo of the sibling verdict and not a contradiction of it: the
receipt mechanism exists in this package and renders well on the transfer/rollback cards, and the failing
row is the one card where it doesn't fire.

Cross-cutting observations (not per-row failures):

1. **Every frame carries the `LOCAL ENGINE` badge.** These are local-engine captures, consistent with the
   known capture-harness context. Nothing here proves remote-path behavior, and the absence of a
   platform-computed checksum value cannot be attributed to either the product or the platform service
   from these frames alone.
2. **State labels at the primary-action moment are systematically unproven, not failed.** In all six
   `primary_action` frames the harness has scrolled to the action button and the card's state chip is
   cropped above the viewport. Per the ticket's rule I record these as *unproven*. Five of six rows prove
   the state label in the `primary_result` frame instead; `export-checksum-evidence` never shows one.
3. **Raw backend serialization leaks on Data Portability's verification card.** Its History renders as a
   literal map — `{result: passed, at: 2026-08-10T08:12:00Z, by: portability-owner}` — while the
   transfer and rollback cards render the same concept legibly ("rollback started · actor · time").
   Unlabeled bare-ISO-timestamp chips (`2026-08-10T09:00:00Z`, `2026-09-28T21:44:57.286377Z`) appear on
   several cards. The doc's §9 names exactly this anti-pattern: "rows that expose backend terms without
   explaining what the owner should decide."
4. **The app-bar community title is truncated to a sliver** next to the LOCAL ENGINE chip on every frame
   (a lone "A"/"E" glyph). Minor, but it costs the start frames some "whose community is this" context.

---

## Ad-Free Community

Doc: `docs/references/communities/ad-free-community-product-experience.md`.

### Row 1 — personal ad-off checkout (member)

**Workflow:** `ad-off-member-checkout`

**Verdict: PASS.**

- **Decision legibility:** the start frame is the community entry surface: community name, promise ("Turn
  off ads with clear purchase, entitlement, receipt, and community-funding proof."), signed-in persona
  ("Shipped ad-off-member", role Member with a real job description), Giving tab active, and a
  **"Buy ad-off"** FAB — the doc §3's "Turn off ads" entry point in domain words. Real content, no filler.
- **Primary action:** the action frame shows the checkout card in a failure state offering **"Retry
  payment"** (with "Cancel checkout" as the escape). "Retry payment" is one of the doc's required primary
  actions for this row and is the domain verb, not a generic Submit.
- **Result:** a genuine state change: the card now shows the **"Review payment"** state chip with
  Price: 49.0, Plan: Annual ad-off, the disclosure line "Suppresses eligible ads for one annual term.",
  "Paying with Card ending 1123", and the doc's required next actions (Edit payment / Checkout / Cancel
  checkout). Failed → review is exactly the retry semantics §7 describes.
- **Doc reconciliation:** §6 requires "price, payer, payment method, disclosure, review/…/failure states,
  linked entitlement continuation". Price, method, disclosure, and the review/failure states are all on
  screen; the linked continuation is visible as the adjacent **"Entitlement active"** card (renewal
  2026-09-15, expiry 2026-10-15, plan, affected ad surfaces) and **"Receipt issued"** card (Payer: Ad Off
  Member, Amount: 4.99). That is the §7 receiver state ("confirmation creates entitlement, receipt, and
  suppression rows") visible in the same sequence.
- **State label:** cropped out of the action frame (unproven at that moment); proven in the result frame
  ("Review payment", plus "Entitlement active" / "Receipt issued" on the sibling cards).
- **Nit:** "Price: 49.0" is not currency-formatted; the receipt card says "Amount: 4.99" — two adjacent
  money values in different formats, neither carrying a currency symbol.

### Row 2 — private entitlement status (member)

**Workflow:** `ad-off-entitlement-status`

**Verdict: PASS.**

- **Decision legibility:** same real entry surface; the entitlement card (action frame) shows the doc's
  required content: active state, Active since / Renews 2026-09-15 / Entitlement ends 2026-10-15,
  Plan: Monthly ad-off, and the affected ad surfaces list.
- **Primary action:** **"Manage subscription"** (with **"Deactivate ad-off"** as the destructive
  alternate). Both are named in the doc's B25 addendum for this row ("manage subscription…" primary;
  "deactivate ad-off" alternate). Domain verbs, correctly weighted (manage primary, deactivate red).
- **Result:** a durable, legible state change: the card's chip is now **"Plan change requested"**
  (warning-styled), a new field "Requested plan: Evidence requestedPlan" records what was asked for, and
  the follow-up actions are the doc's "keep current plan" and "deactivate ad-off". Active →
  change-requested is exactly the doc's required state set.
- **Doc reconciliation:** §7 says "member requests/withdraws plan changes… each management action is
  available only in its matching lifecycle state" — the frames show precisely that lifecycle step. The
  "Requested plan" value is the harness's typed evidence string ("Evidence requestedPlan"), which proves
  the field round-tripped and renders; it also shows the plan change is captured as free text rather than
  a plan selection, which is worth knowing but is the walkthrough's input, not a rendering defect.
- **State label:** cropped in the action frame (unproven at that moment); proven in the result frame.

### Row 3 — private ad-suppression proof (member)

**Workflow:** `ad-off-ad-suppression`

**Verdict: PASS, with two real product findings.**

- **Decision legibility:** the suppression card (action frame) shows "Ads suppressed now: No" (partially
  cropped), the suppressed-surfaces list, and the entitlement linkage — enough for a member to know what
  they are acknowledging.
- **Primary action:** **"Mark reviewed"** — the doc's named primary. **"Restore ad-off"** is present
  (correctly, since suppression is inactive: §7 says restoration is hidden only *while suppression is
  active*), and the result frame offers **"Review later"**, the doc's named alternate.
- **Result:** durable receipt: the state chip is now **"Suppression proof reviewed"** (green). The
  suppressed-surfaces list and the linked-entitlement panel persist below it.
- **Finding 1 — the suppression "reason" is static, not entitlement-derived.** The card asserts "Ads
  suppressed because this member has an active ad-off entitlement." directly above "Ads suppressed now:
  No" and a linked entitlement showing `$state: inactive` (cancelled at 2026-09-28T21:40:15Z, i.e. by an
  earlier action in this same run). The doc (§6) requires a "live entitlement-derived suppression state"
  and a no-fill/ad-off *reason*; the live state chip is correctly derived, but the reason sentence
  contradicts it. A member reading this card is told simultaneously that ads are suppressed because of an
  active entitlement and that ads are not suppressed. The frames cannot show which layer holds the stale
  string, only that the rendered card contradicts itself.
- **Finding 2 — raw internal fields on a member surface.** The "Linked Entitlements" panel renders
  `Member Fan Id: ad-off-member`, `$state: inactive`, `$id: ad-off-entitlement-active` — dollar-sigil
  engine keys and a fan-id, verbatim. The doc's identity promise ("What this must not feel like: abstract
  entitlement and ad-decision status chips") and §9's no-backend-terms standard both argue this panel
  should be projected, not dumped.
- **State label:** cropped in the action frame (unproven at that moment); proven in the result frame.

---

## Data Portability Community

Doc: `docs/references/communities/data-portability-community-product-experience.md`.

### Row 4 — export/import preview (owner)

**Workflow:** `export-import-preview`

**Verdict: PASS.**

- **Decision legibility:** the start frame shows the Export and Migration entry surface with the owner
  persona ("Owner - Selects export scope, verifies packages, transfers data, and starts rollbacks") and
  the owner tab set (Admin/Export/Transfer/Documents — §3.1's required owner tabs, remapped per the doc's
  own 2026-08-10 correction onto real tab ids). The preview card itself (result frame) carries the doc §6
  proof: "3 components selected", the redaction preview ("Phone numbers are excluded; member IDs are
  pseudonymized."), "Destination: Northstar Community Cloud", and the member-facing notice text ("Your
  profile and event participation are included; private contact details are redacted.").
- **Primary action:** **"Start transfer"** (green primary; "Cancel" red alternate) — one of the doc's
  required primary actions, in domain words.
- **Result:** the strongest receipt in this pass: the state chip flips to **"Operation running"**,
  "Operation: Transfer" appears, and the **History section gains a new entry — "transfer started ·
  portability-owner-20 · 2026-09-28T21:42:25.723061Z"** — this run's own write, timestamped, alongside
  the pre-existing "previewed · portability-owner · 2026-08-09" entry. Follow-up actions (Confirm
  complete / Record error / Cancel transfer) match the doc's cancel/retry model.
- **Doc reconciliation:** §6's "change-scope path" is the one required element not visible in this row's
  three frames (a "Change scope" button exists in this package — it is visible on the full-bundle card in
  row 5's frames — but not on this card within the captured viewport). Recorded as not shown, not as
  absent. Everything else the row requires is on screen.
- **State label:** cropped in the action frame (unproven at that moment); proven in the result frame.
- **Note:** History records the actor as `portability-owner-20` while the sign-in banner says "Evidence
  portability-owner" — an id-versus-label mismatch a real owner would find mildly confusing, though the
  attribution itself is real.

### Row 5 — checksum verification (owner)

**Workflow:** `export-checksum-evidence`

**Verdict: FAIL — the primary action leaves no legible receipt, and the doc-required checksum is not
visible in any frame.**

- **What the frames show:** the verification card (header and state chip cropped in *all three* frames)
  with "Four files covering members, events, messages, and documents.", **"Verification: Passed"**,
  "Transfer: Disabled", a date chip, the raw-map History `{result: passed, at: 2026-08-10T08:12:00Z, by:
  portability-owner}`, and two actions: **"Enable transfer"** and **"Export verification record"**.
- **What changed after the action:** exactly one thing — a new, **unlabeled** chip reading
  `2026-09-28T21:44:57.286377Z` (this run's clock) appears among the card's fields. "Transfer: Disabled"
  is unchanged (so the action taken was not Enable transfer), the History gains no entry, no state chip
  is visible before or after, and no exported record, confirmation, or checksum surface appears.
- **Why this fails:** the ticket's own rubric — a result that "merely returns to where it started" is a
  finding — almost applies; this is one notch above it. The timestamp delta does prove *something
  persisted* (I am not claiming the write failed; I cannot see the backend either way). But as evidence
  that an owner "could see that it happened," an unlabeled raw ISO-8601 chip appearing mid-card is not a
  receipt a real owner could read. Compare rows 4 and 6, where the same package renders "…started · actor
  · time" History entries for their actions: the mechanism exists and this card does not use it. **This is
  the same finding the sibling pass recorded against both of its export rows**, reached independently from
  these frames; the difference here is only that a pixel delta exists at all.
- **The checksum question, answered as the ticket asks:** no checksum digest is visible in any of the
  three frames. The doc is unusually specific here: since 2026-08-27 checksum generation **is**
  implemented ("the workflow service computes a real SHA-256… a checksum field is `writableBy:
  'platform'`"), §5 lists checksum as required visible content with "hidden checksum" as the named
  anti-pattern, and §6 requires "checksum, verification result, retry path" for this row. Of those three,
  only the verification result ("Verification: Passed") is on screen; retry path and checksum are not. **I
  cannot tell from these frames which of three explanations holds:** (a) the digest field sits in the
  card's cropped upper region; (b) the field is honestly empty because these are `LOCAL ENGINE` captures
  and the computing service lives in the workflow service (the doc's caveat also notes this workflow
  records a digest *another workflow* produced rather than generating one); or (c) it is genuinely
  unrendered. Per the honesty rules I am not choosing: the row fails on the receipt regardless, and the
  checksum's visibility is recorded as **unproven** with the three candidate explanations above for
  whoever re-captures. What these frames *do* establish is that no frame in this row proves the doc's
  checksum promise.
- **State label:** never visible in any of the three frames — unproven for the entire row (the only row
  in this pass where that is true).
- **Additional finding:** the raw-map History rendering (`{result: passed, at: …, by: …}`) is a
  serialization leak, inconsistent with the legible History rendering on this same package's transfer and
  rollback cards.

### Row 6 — transfer rollback (owner)

**Workflow:** `export-transfer-rollback`

**Verdict: PASS.**

- **Decision legibility:** the action frame shows the rollback card's actions in context with the
  transfer it would unwind visible below ("Awaiting provider verification", "Northstar provider
  migration", From: Data Portability Community / To: Northstar Community Cloud, "3 components").
- **Primary action:** **"Roll back transfer"** (green primary; "Cancel rollback" red alternate) — the
  doc's rollback verb exactly.
- **Result:** state chip **"Rollback running"**, plus every §6-required element: the rollback reason
  ("Destination validation found an unexpected document count."), source and destination, availability
  ("Available: Yes", "Status: Running"), and a **new History entry from this run — "rollback started ·
  portability-owner-20 · 2026-09-28T21:45:54.502562Z"**. Follow-ups (Confirm rollback complete / Record
  rollback failure / Cancel rollback) are the doc's confirm/result/audit model.
- **Doc reconciliation:** §6 also lists "completed state" as required visible proof; these three frames
  end at "running" — completion sits behind "Confirm rollback complete", which a single-action sequence
  cannot also take. Recorded as not captured by this row's frame budget rather than as a product gap; the
  running-state receipt plus the named completion action is what the addendum's "status,
  receipt/history/confirmation" sentence asks for.
- **State label:** cropped in the action frame (unproven at that moment); proven in the result frame.
- Same minor note as row 4: History actor `portability-owner-20` vs sign-in label "Evidence
  portability-owner"; and this row's start frame already carries row 5's `2026-09-28T21:44:57.286377Z`
  chip on the verification card — the rows share one mutating surface, which is expected within a single
  canonical run but means row-start frames are not pristine.

---

## Tally

| Row | Workflow | Verdict | State label |
| --- | --- | --- | --- |
| 1 | `ad-off-member-checkout` | PASS | unproven at action; proven at result |
| 2 | `ad-off-entitlement-status` | PASS | unproven at action; proven at result |
| 3 | `ad-off-ad-suppression` | PASS (2 findings) | unproven at action; proven at result |
| 4 | `export-import-preview` | PASS | unproven at action; proven at result |
| 5 | `export-checksum-evidence` | **FAIL** | unproven in all three frames |
| 6 | `export-transfer-rollback` | PASS | unproven at action; proven at result |

Judged from frames alone; no application code, test, or package was modified. No backend effect is
claimed anywhere above beyond what a pixel delta can support.
