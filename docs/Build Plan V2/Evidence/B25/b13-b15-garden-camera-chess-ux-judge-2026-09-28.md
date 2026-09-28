# UX judge — B13/B15 remaining rows: Garden Club, Camera Club, Chess Club (2026-09-28)

Judge pass over the canonical `--mode full-b25` capture of 2026-09-28. Frames read from
`/home/fahd/b25evidence/B13/screenshots/` and `/home/fahd/b25evidence/B15/screenshots/` — all 21
core frames plus the `alternate_action`/`result_receiver` extras for the five rows that have them
(23 frames total). Product docs reconciled: `garden-club-product-experience.md`,
`camera-club-product-experience.md`, `chess-club-product-experience.md` (persona tables and B25
addendum tables).

## Overall summary

**Five PASS, one FAIL, one UNPROVEN.**

- `garden-export-custom-schemas` **FAILS** on the established export discriminator: the result frame
  shows the operation *starting* ("Export operation in progress") but nothing ever shows the export
  *happening* — no generated state, no History entry, no checksum, and `Download: Unavailable` in
  every frame. Same single class as `book-export-metadata`, `soccer-export-metadata` and
  `export-checksum-evidence`.
- `chess-export-package` is the counterexample that lands on the **pass** side of the same
  discriminator, alongside `export-import-preview` and `export-transfer-rollback`: "Export
  generated" state chip **plus** a History entry naming the action, the actor (`chess-owner-22`) and
  this run's timestamp — and a second history entry for the rollback. The one doc-required element it
  does not show is a checksum value, which is the same campaign-wide integrity-service gap, recorded
  here as a finding rather than a second failure class.
- `gear-loan-request` is **UNPROVEN** exactly as the recorded history warned: owner and requester
  carry the identical label ("Camera Club Member") and the requesting session sees the owner-side
  Approve/Decline buttons immediately after requesting — the frames affirmatively suggest a
  self-transaction, so the two-party claim cannot be counted.

**Where I agree with the two sibling passes:** the export failures are one class, and the
discriminator is whether a legible receipt renders, not the word "export" — my two export rows split
exactly along that line. State labels are cropped out of every `primary_action` frame (card header
scrolled above the viewport); I treated that as unproven-not-failed and recovered the label from the
result frame in every case. Every frame carries the `LOCAL ENGINE` badge; noted once here — nothing
below proves remote-path behaviour, and I did not charge it to any row.

**Where I add to the siblings:** the local-engine identity aliasing (role-id-shaped names standing
in for people: rosters listing `camera-club-organizer`, comments authored by `camera-club-member`,
pairings "Assigned By Fan Id: chess-organizer") is visible in four of these seven rows. It is
background noise everywhere except `gear-loan-request`, where it is precisely what makes the
two-party claim unjudgeable. Harness filler also leaks into load-bearing fields in two rows
("Evidence pickupWindow" as a pickup window, "Evidence commentBody" as a comment body) — legible as
receipts, but generic filler standing in for real content.

---

## Garden Club — phase B13

**Workflow:** `garden-tool-giveaway`
**Outcome:** PASS

- **Decision legibility:** Strong. Start frame is the Marketplace browse view with two fully
  distinguished listings: "Cedar compost bin" (`Mode: Giveaway`, `Availability: Available`,
  `Condition: Good`) beside "Club hand-tool set" (`Mode: Loan`, `Availability: On Loan`) — a member
  can tell what is claimable and what is not. The action frame's detail dialog gives transfer terms,
  pickup instructions, reuse note, `Transfer: Awaiting claim`, `Claim: Not claimed`.
- **Primary action label:** **"Claim giveaway"** — exactly the doc's domain verb (doc row 118:
  "claim giveaway"), not a generic Submit.
- **Result receipt:** Durable. State chip **"Ownership transferred"** plus a
  `Claimed 2026-09-28T21:06:10.401301Z` chip — this run's timestamp on the claim.
- **State label:** Cropped in the action frame (dialog scrolled past the header); recovered in the
  result frame ("Ownership transferred"). Unproven-at-action-moment, proven at result, per the
  cropping rule.
- **Doc reconciliation:** Row 118 requires "browse/list views, owner privacy, claimant state, pickup
  coordination, and the ownership-transfer result the owner receives." Browse ✓, owner privacy ✓
  (the action frame shows "Owner contact: Protected until ownership handoff" and "Claimant contact:
  Protected until ownership handoff" — the privacy requirement rendered literally), claimant state ✓
  (Awaiting claim → transferred), pickup ✓ (see finding). The **owner-received** transfer result is
  not in these frames — this row's persona is the member/claimant; the owner-side receipt would need
  an owner session and is not charged to this row.
- **Findings (pass with findings):** the result's pickup field reads **"Pickup: Evidence
  pickupWindow"** — harness filler in a load-bearing coordination field, where the sibling loan
  listing shows a real value ("Pickup: Saturday mornings"). Owner renders as the role-shaped
  "Garden Coordinator" (identity aliasing).

**Workflow:** `garden-export-custom-schemas`
**Outcome:** FAIL

- **Decision legibility:** Good, ironically. Start frame confirms the persona ("Signed in as Shipped
  garden-coordinator — Coordinator… owns club exports"); the action frame shows a coherent export
  card: "Ready for verified export", `Mode: Export`, `2 schemas selected`,
  `Destination: Neighborhood Association archive`, `Redaction: Approved`, status text "Redaction
  approved; ready to run. The platform will generate and verify the package…", with **Export**,
  **Change scope**, **Cancel transfer**.
- **Primary action label:** **"Export"** — the domain verb.
- **Result receipt — this is where it fails.** The result frame shows the state chip move to
  **"Export operation in progress"** / `Status: Generating export package`, with new actions
  "Confirm completion" / "Record export error". That proves the tap fired and the state machine
  advanced. It never shows the export **happening**: no generated/complete state, **no History
  entry** (the pass-side rows show action + actor + timestamp; this shows none), **no checksum
  anywhere in any frame**, and `Download: Unavailable` in start, action, result and receiver frames
  alike. The `result_receiver` frame ends the story at **"Cancelled"** ("This is an off-path export
  state", `Status: Operation cancelled`) — an honest, legible off-path label, but a continuation
  state for cancellation, not a completion receipt.
- **Doc reconciliation — quoting the lines it misses.** Row 58 requires the context pack to show
  "selected garden_event and plant_exchange schemas, redaction preview, **checksum**, destination,
  change-scope path, **download/export status**"; the frames show only a `2 schemas` count — the
  schema *names* never render — and no checksum ever. Row 79: "export disabled until redaction
  preview and **checksum pass**" — no checksum exists on any frame to have passed. Row 119: "Fresh
  screenshots must show status, **receipt/history/confirmation**, and any receiver or continuation
  state" — status yes; receipt/history/confirmation absent.
- **Agreement with siblings:** this is the same one-class failure as `book-export-metadata`,
  `soccer-export-metadata` and `export-checksum-evidence` — the platform generation the status text
  promises ("the platform will generate and verify the package") has no evidence anywhere in the
  run. The state-machine half works; the platform-service half is what fails. I am not marking this
  UNPROVEN: the frames are perfectly legible, and what they legibly show is the doc-promised
  deliverable not being delivered.

---

## Camera Club — phase B15

**Workflow:** `photo-walk-rsvp`
**Outcome:** PASS

- **Decision legibility:** Real content throughout: "Route: Battery Spencer to Kirby Cove…",
  `06:15`, "Battery Spencer trailhead, Sausalito", "Led by Maya Chen", "Weather Checklist Notes",
  plus a per-role attendee roster and the explicit line "No response record is available for you for
  this event" before responding — the member knows exactly what they are deciding.
- **Primary action label:** **"Going"**, alongside "Maybe", "Not attending", "Add reminder" — the
  doc's own verbs (row 93: "rsvp, attend, going"), not a generic Submit.
- **Result receipt:** Durable. The Going roster now lists **"Evidence camera-club-member"** — the
  signed-in actor by name — the Going button renders selected/inactive, and a **"Cancel RSVP"**
  affordance appeared (the doc's required change path). That is an attendee-state update visible on
  the surface, not a bounce back to the start screen.
- **State label:** The event card's header/state chip is scrolled above the viewport in both action
  and result frames — unproven at the action moment per the cropping rule; the roster change is the
  receipt. **Capacity** (named in doc row 54's context pack) is likewise not visible in any frame —
  not-visible is not not-rendered, so recorded as unproven, not as a miss.
- **Findings:** roster entries are role-id-shaped (`camera-club-organizer`, `camera-club-member`)
  with the actor as "Evidence camera-club-member" — the local-engine identity aliasing; capacity not
  visible in shot.

**Workflow:** `critique-submission`
**Outcome:** PASS

- **Decision legibility:** Real critique content: titles "Lighthouse at dusk" and "Night market
  reflections", prompts ("Weekly theme: silhouettes", "Color and motion"), author chip "By Camera
  Club Member", and a substantive reviewer comment from `camera-club-organizer` dated
  2026-08-12 — plus a visibly different neighbouring card in state "Critique reviewed", so the
  member can see what review looks like.
- **Primary action label:** **"Reply"** — one of the doc's named member verbs (row 94: "submit
  critique, review critique, **comment**"). The captured instance was already submitted, so the
  exercised primaries are comment and withdraw rather than first submission.
- **Result receipt:** Durable, twice over. The receiver frame shows a **new comment authored by
  `camera-club-member`, body "Evidence commentBody", timestamped `2026-09-28T21:30:03.779296Z`**
  (this run), with the comment counter moving 1 → **"2 comments"**; and the alternate action
  **"Withdraw critique"** produced a red **"Critique withdrawn"** state chip on the same card. Both
  receipts name the state or the actor and carry the run's timestamp.
- **State label:** cropped at the action moment (card scrolled to its buttons); recovered in the
  receiver frame ("Critique withdrawn", and "Critique reviewed" on the sibling card).
- **Findings:** the doc's context pack (row 55) lists a **consent note** — not visible in any frame
  (unproven, not absent). The media field renders as a text chip **"Photo Image"** rather than any
  image — a placeholder-shaped rendering for the "image/work title" the doc names; title is real,
  image is not shown. Comment body is harness filler ("Evidence commentBody"). None of these
  contradict the doc lines exercised by this row's primary/alternate verbs, so pass-with-findings.

**Workflow:** `gear-loan-request`
**Outcome:** UNPROVEN

- **What the frames do prove:** the request mechanics. Browse view with two "Gear listing" cards
  (Canon 70-200mm f/2.8 lens, Fujifilm X100V walk kit); a detail dialog with `Mode: Loan`,
  `Condition: Excellent — minor cosmetic wear only`, `Status: Available`, `0 custody events`,
  `0 borrowers or claimants`; primary action **"Request loan"** (the doc's domain verb, row 95);
  result `Status: Available` → **`Status: Requested`** with a **"Requested by: Camera Club
  Member"** chip — a durable receipt of the request. The receiver frame additionally shows the
  alternate action's receipt: **"1 reported issues"** after Report damage.
- **Why the row is unproven — the two-party caution bites, on the evidence, not on precedent.** The
  item reads **"Owner: Camera Club Member"** and the request receipt reads **"Requested by: Camera
  Club Member"** — the identical label on both sides of the transaction. And immediately after
  requesting, the *same session* is offered the owner-side controls **"Approve request" /
  "Decline request"** alongside the requester's "Cancel request". The frames therefore do not let me
  tell lender from borrower; what they most plausibly depict is the same identity on both sides —
  exactly the self-transaction the previous judge pass warned this row can silently prove. Per the
  ticket's instruction I am marking the two-party claim unproven rather than assuming either way,
  and since a two-party loan is what this row exists to evidence, the row lands UNPROVEN rather
  than PASS — and not FAIL, because nothing in the frames shows the product misbehaving.
- **Doc reconciliation:** row 95's must-show list is partially delivered (browse ✓, listing detail ✓,
  condition ✓, custody count ✓, queue affordance "Join queue" ✓); queue *position*, pickup/return
  timing and any return/transfer result are not in these frames. Row 64's receiver claim ("owner/
  reviewer sees borrower…") is exactly the half that cannot be attributed to a distinct owner here.

---

## Chess Club — phase B15

**Workflow:** `chess-rules-documents`
**Outcome:** PASS

- **Decision legibility:** Start frame shows the persona ("Signed in as Evidence chess-member —
  Player") and a concrete document card: **"Club rapid and ladder rules"**, `Version 2026.2`, state
  **"Rules available"**, `0 document actions`. The action frame presents the doc's two explicit open
  modes plus download: **"Open embedded"**, **"Open external"**, **"Download"** — matching the doc's
  intent that this is a link library with two URL open modes (row 207).
- **Primary action label:** **"Download"** — the doc's domain verb (row 189).
- **Result receipt:** Durable. State chip **"Rules available" → "Downloaded"** and the action
  counter **`0 document actions` → `1 document actions`** — a state change plus a recorded action,
  and the Download button correctly no longer offered.
- **State label:** visible in both start and result frames; no cropping issue on this row.
- **Doc reconciliation:** row 189's member half is delivered (title ✓, embedded/external choice ✓,
  download state ✓). The same row's organizer half ("the organizer archives a superseded version",
  "archived-document state") is not in these member-persona frames; row 154's "organizer can see
  which materials were opened, **if tracked**" is self-qualified. Open *history* is evidenced only
  as the actions counter, not an expanded history list.
- **Findings:** the card shows **"Member state unavailable. Member state is available when connected
  to a community."** in every frame — diagnostic-toned text rendered to a member who *is* inside a
  community screen, on the local engine. It reads as an internal condition leaking into product
  copy; worth a look, but it does not block the row's claim.

**Workflow:** `chess-export-package`
**Outcome:** PASS

- **Decision legibility:** Start frame: "Signed in as Evidence chess-owner — Owner… owns its
  data-export responsibilities", Admin tab "Tuned for Owner", export card **"Ready to export"** with
  scope "August ladder and match archive", `3 data groups`, "Ready to generate".
- **Primary action label:** **"Generate export"** — the doc's domain verb (row 186), with "Cancel
  export" beside it.
- **Result receipt — the full pass shape, twice.** Result frame: state chip **"Export generated"**,
  status "Export generated; integrity metadata is platform-managed", a run timestamp chip
  (`2026-09-28T21:26:59.617068Z`), and a **History** entry —
  `{action: generated, actorFanId: chess-owner-22, at: 2026-09-28T21:26:59.617100Z}` — action,
  actor and timestamp all named, plus new **"Download export"** and **"Rollback"** affordances. The
  receiver frame then shows the rollback receipted the same way: state **"Export rolled back"**
  ("This is an off-path export state"), a **second** History entry
  `{action: rolled-back, actorFanId: chess-owner-22, at: 2026-09-28T21:27:18.185969Z}`, and the
  doc's recovery verbs ("Generate again", "Change scope", "Cancel export") — row 151's "retry is
  available after rollback" rendered literally. This is the same receipt shape that passed
  `export-import-preview` and `export-transfer-rollback`, and it is why this export row passes while
  Garden's fails.
- **State label:** visible in start, result and receiver frames.
- **Findings:** the one doc-required element the frames do not show is **the checksum value**. Row
  186: "Fresh screenshots must show … **the real platform-generated checksum after generation**";
  the frames show only the text "integrity metadata is platform-managed". The doc's own header
  already discloses the underlying gap (line 22: "`chess-export-package`'s `generate-export` effect
  hardcodes `\"checksum\": \"sha256-chess-2026\"`") — this is the campaign-wide export-integrity
  limit, not a Chess-specific regression, and with every other receipt in place I record it as a
  finding on a PASS rather than a second failure. Two cosmetic notes: History renders as raw
  key-value text (`{action: …, actorFanId: …}`) rather than formatted copy, and the pairing card
  beneath shows the identity aliasing again ("Assigned By Fan Id: chess-organizer").

---

## Frame accounting

| Row | Frames read |
|---|---|
| garden-tool-giveaway | start, primary_action, primary_result (3) |
| garden-export-custom-schemas | start, primary_action, primary_result, alternate_action, result_receiver (5) |
| photo-walk-rsvp | start, primary_action, primary_result (3 of 5; alternate/receiver not needed for the verdict) |
| critique-submission | all 5 |
| gear-loan-request | all 5 |
| chess-rules-documents | start, primary_action, primary_result (3) |
| chess-export-package | all 5 |

No frame was unreadable; no row lands in a could-not-judge bucket. Nothing in this file asserts a
backend effect — every receipt cited is pixels on a frame, and all frames are local-engine
(`LOCAL ENGINE` badge present throughout).
