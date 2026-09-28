# UX judge verdict — remaining B13/B15 rows: Garden Club, Camera Club, Chess Club (2026-09-28)

Judge pass over the canonical `--mode full-b25` capture of 2026-09-28. Frames read from
`/home/fahd/b25evidence/B13/screenshots/` and `/home/fahd/b25evidence/B15/screenshots/`. Seven rows
judged; every frame for every row was readable. Every frame carries the `LOCAL ENGINE` badge, so
nothing below proves remote-path behaviour — recorded once here, not per row.

## Overall summary

**Six rows pass, one fails.** The failure is `garden-export-custom-schemas`, and it falls on exactly
the side of the export discriminator the two sibling passes established: its primary action
registers (the state chip changes to "Export operation in progress"), but **no receipt of the export
ever renders** — no History entry, no checksum, download stays Unavailable, and the captured run
ends in a "Cancelled" state the surface itself flags as off-path. By contrast
`chess-export-package` is the strongest receipt in this set: state chip, run timestamp, and a
History entry naming the action and actor — the same shape that passed `export-import-preview` and
`export-transfer-rollback`.

Where I agree with the sibling passes: the export discriminator (a legible receipt, not the word
"export") is the right test, and it cleanly splits my two export rows; the state-label cropping rule
held (labels missing at the action moment were found in result frames, and I marked
cropped-not-rendered elements unproven, not failed); the `LOCAL ENGINE` badge is present throughout.
Where I add to them: the discriminator needs a middle case named — Garden's export shows *initiation*
evidence (a real state change) that the failed book/soccer export rows lacked, yet still no receipt
that the export happened. Initiation evidence alone does not pass an export row.

One systemic observation for `gear-loan-request`: the recorded self-transaction hazard is visible
on-screen this run — owner and requester render with the identical label and one signed-in member is
offered both sides' actions simultaneously. The two-party claim is unproven, as the caution
instructed.

Harness-injected filler ("Evidence pickupWindow", "Evidence commentBody") renders in three result
frames. I have treated these as harness-typed values faithfully rendered, not product defects, but
they are noted per row because they stand in for real content in committed evidence.

---

## Row 1 — Garden Club: tool giveaway (member) — **PASS**

**Workflow:** `garden-tool-giveaway`

- **Decision legibility: yes.** Start frame is the Marketplace tab with the member role description
  visible ("RSVPs to events, offers or requests plants, borrows or gives away items…"). The Cedar
  compost bin card reads Mode: Giveaway, Availability: Available, Condition: Good, alongside a
  contrasting loan-mode item (Club hand-tool set, On Loan) — real, distinguishable content. The
  action-moment dialog adds transfer terms, pickup instructions, reuse note, "Transfer: Awaiting
  claim", "Claim: Not claimed", and owner/claimant contact both "Protected until ownership handoff"
  (the owner-privacy element the doc requires).
- **Primary action: semantically right.** Exact label: **"Claim giveaway"** — the domain verb, not a
  generic Submit.
- **Result: durable receipt.** State chip **"Ownership transferred"**, Owner: Garden Coordinator,
  and a claim receipt chip **"Claimed 2026-09-28T21:06:10.401301Z"** — this run's own timestamp.
- **State label:** visible in start ("Available to cl…", truncated by chip width) and in the result
  ("Ownership transferred"); partially cropped at the top of the action dialog — found in the result
  frame per the cropping rule.
- **Doc reconciliation** (garden doc row 118: frames "must show browse/list views, owner privacy,
  claimant state, pickup coordination, and the ownership-transfer result the owner receives"):
  browse ✓, owner privacy ✓, claimant state ✓, ownership-transfer result ✓ — but the result shown is
  on the claimant's own screen; **"the result the owner receives" is not separately proven**, and on
  the local engine's single-identity model it cannot be. Unproven element, not a failure of what was
  captured.
- **Findings:** pickup coordination renders as **"Pickup: Evidence pickupWindow"** — a
  harness-typed placeholder standing where a real pickup window should be; the pickup *mechanism*
  rendered, its content is filler.

## Row 2 — Garden Club: export with custom schemas (coordinator) — **FAIL**

**Workflow:** `garden-export-custom-schemas`

- **Decision legibility: yes.** Start frame shows "Signed in as Shipped garden-coordinator —
  Coordinator … owns club exports", Documents tab. The action-moment card is fully legible: state
  "Ready for verified export", Mode: Export, "2 schemas selected", Destination: Neighborhood
  Association archive, Redaction: Approved, Download: Unavailable.
- **Primary action: semantically right.** Exact label: **"Export"**, with "Change scope" and
  "Cancel transfer" as secondaries — matching the doc's interaction set.
- **Result: NO durable receipt — this is the failure.** The result frame shows the state chip change
  to **"Export operation in progress"** / Status: "Generating export package", with next-step
  actions (Confirm completion / Record export error). That proves the tap registered and the state
  machine advanced — more than the failed `book-export-metadata`/`soccer-export-metadata` rows
  showed — but **nothing in any frame evidences the export itself**: no History entry (this card
  renders no History section at all, unlike Chess's export card), no checksum, no confirmation,
  Download: Unavailable in every frame. The `result_receiver` frame then shows the workflow in
  **"Cancelled"** with the surface's own warning **"This is an off-path export state"** — the
  captured run ended by cancelling the export, so no completion receipt could exist.
- **State label:** visible at every step; the cropping rule was not needed to reach this verdict.
- **Doc reconciliation — the doc line decides this row.** Garden doc row 119: *"Fresh screenshots
  must show status, receipt/history/confirmation, and any receiver or continuation state for this
  persona."* Status ✓; **receipt/history/confirmation ✗** — none renders. Row 58 additionally lists
  "checksum" among the surface's content and row 79 says *"export disabled until redaction preview
  and checksum pass"*; no checksum appears in any frame.
- **Agreement with siblings:** same verdict axis as the three failed export rows, and I agree with
  their reasoning; the one distinction worth recording is that this row shows real state-machine
  progress where those showed none. That distinction does not rescue the row.

## Row 3 — Camera Club: photo walk RSVP (member) — **PASS**

**Workflow:** `photo-walk-rsvp`

- **Decision legibility: yes.** Start frame: "Signed in as Evidence camera-club-member — Member",
  Walks tab described as "Named photo-walk routes, dates, times, locations, capacity, RSVP status".
  The action-moment card shows a concrete event: Route: Battery Spencer to Kirby Cove, 06:15,
  Battery Spencer trailhead Sausalito, Led by Maya Chen, an attendee roster, and the explicit line
  "No response record is available for you for this event."
- **Primary action: semantically right.** Exact label: **"Going"**, alongside "Maybe", "Not
  attending", "Add reminder" — the doc's RSVP verbs verbatim.
- **Result: durable receipt.** The roster now lists **"Evidence camera-club-member" under Going**
  (the acting persona by name), the Going button renders selected/inactive, and a **"Cancel RSVP"**
  action appears — the doc's "confirmed RSVP remains visible" and change path in one frame.
- **State label:** the event card's header/state chip is above the viewport at the action moment
  (the documented cropping), and the receipt here is the roster rather than a state chip —
  attendee-state update is what the doc (row 62) says changes. Not a finding.
- **Doc reconciliation** (rows 54/62/93): route/date/time/location ✓, RSVP choice ✓, change path ✓,
  confirmed state ✓. **Capacity is listed as surface content (row 54) and is not visible in any
  captured frame** — unproven (likely above the crop), not failed. Roster entries
  `camera-club-member` / `camera-club-organizer` are role-id-shaped identities from the local
  engine's aliasing; the acting persona is distinguishable ("Evidence camera-club-member").

## Row 4 — Camera Club: critique submission (member) — **PASS**

**Workflow:** `critique-submission`

- **Decision legibility: yes.** The acted critique ("Lighthouse at dusk", Photo Image, Prompt:
  Weekly theme: silhouettes, By Camera Club Member) carries a real prior organizer comment ("The
  silhouette reads clearly. Please also consider whether a tighter crop…", 2026-08-18) — genuine
  reviewable content, and a second critique in "Critique reviewed" state sits alongside for
  contrast.
- **Primary action: semantically right.** Exact label: **"Reply"** — "comment" is one of the doc's
  named primary interactions for this row (row 94: "submit critique, review critique, comment"), so
  a reply on an already-submitted critique is a legitimate primary here, though note the *submit*
  verb itself was not the one exercised.
- **Result: durable receipt.** The receiver frame shows the new comment attributed to
  **camera-club-member**, body "Evidence commentBody", timestamped **2026-09-28T21:30:03.779296Z**
  (this run), and the count moved to **"2 comments"**. The alternate action ("Withdraw critique")
  produced a second receipt: state chip **"Critique withdrawn"** in red on the acted card.
- **State label:** cropped above the viewport in start/action frames; found in the receiver frame
  ("Critique withdrawn") per the cropping rule.
- **Doc reconciliation** (rows 55/63/94): title ✓, prompt ✓, comments/reviewer visibility ✓,
  edit/withdraw path ✓, result state ✓. **The consent note (row 55) is not visible in any captured
  frame** — unproven, not failed. The comment body is harness filler ("Evidence commentBody"),
  rendered faithfully.

## Row 5 — Camera Club: gear loan request (member) — **PASS, two-party claim UNPROVEN**

**Workflow:** `gear-loan-request`

- **Decision legibility: yes.** Start frame: Gear tab, two real listings (Canon 70-200mm f/2.8,
  Fujifilm X100V walk kit). The action dialog shows Mode: Loan, Condition: "Excellent — minor
  cosmetic wear only", Owner, Status: Available, 0 custody events, 0 borrowers or claimants,
  Borrower/claim count: 0 — the doc's condition/custody/roster elements.
- **Primary action: semantically right.** Exact label: **"Request loan"** (with Report damage,
  Pause listing, Delist as the owner-side secondaries visible pre-action).
- **Result: durable receipt.** **Status: Available → "Status: Requested"** plus a new chip
  **"Requested by: Camera Club Member"**. The alternate action (Report damage) left its own receipt
  in the receiver frame: **"1 reported issues"** (from 0).
- **The two-party caution — the frames cannot tell the parties apart, so the two-party claim is
  unproven.** Affirmatively so, not merely by absence: the owner chip and the requester chip carry
  the **identical label "Camera Club Member"**, and after the request the *same signed-in member's*
  dialog offers **"Approve request" and "Decline request" (owner verbs) alongside "Cancel request"
  (borrower verb) simultaneously**. That is the recorded self-transaction shape on screen. What is
  proven: a member can request a loan and the request leaves a legible receipt. What is not proven:
  that lender and borrower are different parties, or that an owner separately receives this request.
- **State label:** visible throughout inside the dialog (Status chips); no cropping issue.
- **Doc reconciliation** (rows 56/64/95): browse ✓, owner/holder ✓ (label only), condition ✓,
  borrower/claim count ✓, request/change path ✓, report damage ✓. **Queue position and
  pickup/return timing are not visible in any frame** (Join queue is offered but never shows a
  position) — unproven. **Rendering finding:** after the action, the chip renders as
  "Borrower/claim count:" with an **empty value** (it read "0" pre-action) — a blank-value chip in
  committed evidence.

## Row 6 — Chess Club: rules documents (member) — **PASS**

**Workflow:** `chess-rules-documents`

- **Decision legibility: yes.** Start frame: "Signed in as Evidence chess-member — Player",
  Documents tab, card "Club rapid and ladder rules", state "Rules available", Version 2026.2,
  "0 document actions".
- **Primary action: semantically right.** The action frame offers the doc's two explicit open modes
  plus download: **"Open embedded"**, "Open external", **"Download"**. The exercised primary was
  Download (per the result).
- **Result: durable receipt.** State chip **"Rules available" → "Downloaded"**, action count
  **"0 document actions" → "1 document actions"**, and the Download button is gone from the action
  set — three consistent marks of the recorded action.
- **State label:** visible in every frame; no cropping issue.
- **Doc reconciliation** (rows 139/154/189/207): title ✓, embedded/external choice ✓, download
  state ✓, source/version ✓. Doc row 189 also requires *"open history … and the archived-document
  state"*: open history renders **only as a count** (no entry detail), and the
  **archived-document state was not captured** — archiving is the organizer's action and this is the
  member row, so that element is unproven here rather than failed, but the addendum line as written
  is not fully delivered by this row's frames.
- **Findings:** the card renders **"Member state unavailable. Member state is available when
  connected to a community."** while a signed-in community member is using it — on the local engine
  this reads as a confusing contradiction standing where member acknowledgment state should be.
  Minor: "1 document actions" pluralization.

## Row 7 — Chess Club: export package (owner) — **PASS**, with one doc-required element missing

**Workflow:** `chess-export-package`

- **Decision legibility: yes.** Start frame: "Signed in as Evidence chess-owner — Owner … owns its
  data-export responsibilities", Admin tab ("export controls. Tuned for Owner"), card "Ready to
  export", "August ladder and match archive", "3 data groups", "Ready to generate".
- **Primary action: semantically right.** Exact label: **"Generate export"** (with "Cancel export"
  adjacent).
- **Result: the strongest durable receipt in this set.** State chip **"Export generated"**, status
  "Export generated; integrity metadata is platform-managed", a run-timestamp chip
  **2026-09-28T21:26:59.617068Z**, and a **History entry: `{action: generated, actorFanId:
  chess-owner-22, at: 2026-09-28T21:26:59.617100Z}`** — action, actor and timestamp named. This is
  the exact receipt shape that passed `export-import-preview` and `export-transfer-rollback`, and I
  agree with that discriminator. Post-generation actions ("Download export", "Rollback") appear,
  matching the doc's "rollback and download are unavailable until generated".
- **State label:** cropped at the action moment (card header above viewport); found in start and
  result frames per the cropping rule.
- **Doc reconciliation — one required element does not render.** Chess doc row 186: *"Fresh
  screenshots must show selected scope, generated/downloaded status …, and the real
  platform-generated checksum after generation."* Scope ✓, generated status ✓, but **no checksum
  value appears anywhere in the result frame** — the card is fully visible from state chip to the
  Rollback button, and integrity is represented only by the prose "integrity metadata is
  platform-managed". Per the honesty rules I do not infer from the UI whether a checksum was written
  backend-side; what the doc demands the screenshot show, the screenshot does not show. (The doc's
  own header note records that the package's `generate-export` effect hardcodes
  `"checksum": "sha256-chess-2026"` while §204 requires the export-bundle service, not a JSON
  effect, to write the real checksum — this capture displays neither.)

---

## Cross-row notes

- **Agreement with sibling passes:** export discriminator applied and it split my two export rows
  (Chess pass, Garden fail); cropping rule applied (Garden giveaway dialog header, Camera critique
  card header, Chess export header — all recovered from result frames; Camera capacity, Camera
  consent note marked unproven rather than failed); `LOCAL ENGINE` badge on all 26 frames read.
- **Disagreement/refinement:** none with the verdicts; one refinement to the discriminator — a
  changed state chip alone (initiation evidence) should not pass an export row, or Garden's row
  would have passed while producing no receipt, no checksum and a cancelled run.
- **Harness filler in committed evidence:** "Evidence pickupWindow" (Garden giveaway),
  "Evidence commentBody" (Camera critique). Faithfully rendered by the product; still generic
  filler standing in for real content in the frames.
- **Not judged here:** nothing — all seven assigned rows were judgeable from the frames provided.
