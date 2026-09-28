# B14 UX judge — Neighborhood Book Club & Riverside Youth Soccer (fresh capture 2026-09-28)

Judge pass over the canonical `--mode full-b25` frames at `/home/fahd/b25evidence/B14/screenshots/`,
three frames per row (start / primary_action / primary_result), reconciled against each community's
product doc. All 24 frames were readable, non-zero-byte, and every frame carries the app's
`LOCAL ENGINE` badge — these captures depict the local-engine harness, and nothing below claims any
backend effect; every statement is about what the pixels show.

## Overall summary

- **PASS (with noted findings): 5 rows** — `book-nomination`, `book-search-ai-digest`,
  `book-shared-library-item`, `book-selection-publish`, `soccer-reminder-notification`.
- **FAIL: 3 rows** — `book-export-metadata` and `soccer-export-metadata` (both result frames show a
  **cancelled, self-declared "off-path" export state** rather than the result of the primary export
  action), and `soccer-waiver-document` (acknowledgement — the doc's core guardian job — is absent
  from the surface, which instead shows placeholder text "Member state unavailable").
- The most valuable cross-cutting finding: **both portability rows end in `Export cancelled` with
  the UI's own banner "This is an off-path export state."** In the Youth Soccer row the visible
  filled primary was `Start export or transfer`, yet the result card's history records "Owner
  cancelled portability operation" — the captured result is the receipt of a *different* action
  than the one the action frame presents. Whatever the harness tapped, these frames do not prove
  the export happy path for either community.
- State labels (new check): rendered on every Book Club card (`Submitted`, `Selected for ballot`,
  `Digest open`, `Draft listing`, `In library`, `Published`, `Cancelled`) and on both Soccer export
  frames (`Minor-data redaction reviewed`, `Export cancelled`). **Not confirmable** for
  `soccer-waiver-document` and `soccer-reminder-notification` — in all frames for those two rows the
  card's top (where the state chip renders) is scrolled off-screen. Unproven, not proven-absent.
- Minor global note: the `Submitted` state chip renders with an orange warning-triangle icon
  (Book Club nomination, Soccer-styled equivalents). A normal, successful state wearing an alert
  icon reads as an error to a member.

---

## Neighborhood Book Club

### 1. Book nomination — PASS with findings

**Workflow:** `book-nomination`

- **Decision legible?** Partially. The start frame is the community landing (persona proof:
  "Signed in as Shipped book-member — Member", Books tab), not the nomination surface. The action
  frame has scrolled past the form fields; only the `Submit nomination` button and a neighbouring
  `Selected for ballot` card (The Song of Achilles, by Madeline Miller, Cycle: September 2026) are
  visible, so the title/author/rationale *being decided* are not themselves in frame.
- **Primary action semantic?** Yes — `Submit nomination`, the doc's own verb.
- **Durable receipt?** Yes. The result frame shows a **new** card in state `Submitted` carrying
  "The Night Watchman", "by Louise Erdrich", "Genre", "Cycle: October 2026", above the pre-existing
  `Selected for ballot` card. A real new nomination is visible with real content.
- **State label?** Present (`Submitted`, `Selected for ballot`).
- **Doc reconciliation.** §6 requires "book title/author/reason and submitted state"; the B25
  addendum requires "title/author/rationale, ballot state, edit path, submitted result, and member
  receiver state". Delivered: title, author, ballot state, submitted result. **Not delivered in any
  of the three frames: the rationale/reason, and the edit/withdraw path** (no edit or withdraw
  affordance is visible). Those two gaps are why this is a qualified pass, not a clean one.

### 2. Search / AI digest — PASS with findings

**Workflow:** `book-search-ai-digest`

- **Decision legible?** Yes at the card level. The action frame shows a fully populated existing
  digest: state `Digest open`, Query "Best discussion questions for The Song of Achilles?",
  "Waiting for an answer", Sources "Madeline Miller official reading guide" with a real URL and
  "Added 2026-07-18" — real content, not filler.
- **Primary action semantic?** The digest card's own actions are semantic (`Save digest`,
  `Edit query`, `Add citation`, `Report stale citation`, `Withdraw`). But the creation action
  visible at the top of the action frame is a generic **`Submit`** — the only generic primary label
  in the Book Club set. The doc's addendum row for this workflow accepts "submit, save, send", so
  this is doc-conformant, but it is the weakest label on show and worth naming.
- **Durable receipt?** Yes. The result frame shows a **new** `Digest open` card with the new query
  "What historical context does Circe draw on?" above the original Achilles digest.
- **State label?** Present (`Digest open`).
- **Doc reconciliation.** §7 promises "members receive answer with citations and source visibility"
  (§6: "query/citations/summary"). The new digest shows the query and "Waiting for an answer" —
  **no answer, no summary, and no citations are visible on the newly created digest in these
  frames**. The interaction (ask → durable open digest) is proven; the doc's promised *answer with
  citations* is not delivered anywhere in this sequence. That is consistent with the known missing
  external search/AI platform service, but as captured, the receiver-state promise on doc line
  "members receive answer with citations" is unmet.

### 3. Shared library item — PASS with findings

**Workflow:** `book-shared-library-item`

- **Decision legible?** Yes. Start frame is the landing with the Marketplace tab and a
  `List an item` FAB; the action frame is the item detail dialog "Circe (hardcover)": state
  `Draft listing`, chips for title, `Book` format, `Good` condition, `Loan` mode,
  `Owner: Book Member` — the member is looking at their own draft listing and deciding to publish.
- **Primary action semantic?** Yes — `Publish listing` ("list item" is in the doc's required
  primary actions for this persona).
- **Durable receipt?** Yes. The same dialog transitions to state **`In library`**, and the action
  set changes to owner controls `Pause listing` / `Delist` — a visible, durable state change.
- **State label?** Present (`Draft listing` → `In library`).
- **Findings.**
  1. The result dialog shows **`Available` and `Overdue` chips simultaneously** — contradictory
     availability facts on one card. The action frame already showed `Overdue` on a *draft* listing
     that had never been published or lent, which cannot be a real overdue loan.
  2. Doc §6 requires "owner/current holder, queue position, due date, loan/giveaway mode, return or
     transfer state". Delivered: owner, loan mode, condition, format. **Not visible in these
     frames: queue position, due date, current holder** (the `Overdue` chip appears with no due
     date behind it). Privacy-safe holder labelling could not be assessed.

### 4. Selection publish — PASS

**Workflow:** `book-selection-publish`

- **Decision legible?** Yes. Start frame proves the persona ("Signed in as Shipped book-organizer —
  Organizer", Admin tab: "Role-specific publishing, approvals, and operations. Tuned for
  Organizer."). The action frame (Admin tab) shows the `Publish announcement` primary above a
  ballot context that makes the decision concrete: an existing `Published` card (The Song of
  Achilles → For All members) and a `Submitted` nomination (Circe, by Madeline Miller, Cycle:
  September 2026) with `Select for ballot`.
- **Primary action semantic?** Yes — `Publish announcement`.
- **Durable receipt?** Yes. The result frame shows a **new** `Published` card "Circe — For All
  members" stacked above the earlier "The Song of Achilles — For All members" one. Audience is
  explicit on both.
- **State label?** Present (`Published`, `Submitted`).
- **Doc reconciliation.** §7: "owner publishes selected book announcement to members" — delivered
  as far as one persona's frames can show (member receipt and "publish hidden for members" are
  member-side claims these organizer frames cannot prove, and I do not infer them). Delivery
  timing/scheduling from the addendum's alternates is not shown but is not required for the primary
  path. This is the cleanest row of the eight.

### 5. Export metadata — FAIL

**Workflow:** `book-export-metadata`

- **What the frames show.** Start: organizer landing (persona proof fine). Action frame: the top of
  a card cut off, showing only a red **`Cancel`** button — **no export verb is visible anywhere in
  the action frame** (`export` / `download export` / `start transfer` are the doc's primary verbs).
  Result frame: the export card in state **`Cancelled`** (faded, top-cropped) with the UI's own
  orange banner **"This is an off-path export state"**, chips "Scope: Nominations and vote history,
  Q3 2026", "Export cancelled", timestamp `2026-09-28T21:11:54.703676Z`, and a `Retry` action.
- **Judgement.** The result is a genuine durable receipt — of a **cancellation**. As a sequence it
  does not show a member-legible export decision, does not present a semantic export primary, and
  ends in a state the product itself labels off-path. The doc's B25 row cannot be counted proven by
  these frames.
- **Doc reconciliation.** §6 required visible proof is "scope/checksum/redaction"; §7: "export
  disabled until checksum and redaction preview pass". **Scope is shown; checksum and redaction are
  never visible in any of the three frames.** That is a direct screens-vs-doc disagreement, quoting
  the doc's §6 row: "book-export-metadata | organizer | Export status | scope/checksum/redaction".
- **State label?** Present (`Cancelled`), plus the off-path banner — the banner itself is good UX.

---

## Riverside Youth Soccer

### 6. Waiver document — FAIL

**Workflow:** `soccer-waiver-document`

- **What the frames show.** Start: landing with persona proof ("Signed in as Shipped
  soccer-guardian — Guardian") and a Documents tab "Waivers, policies, versions, acknowledgement,
  and access requests. Tuned for Guardian." The action and result frames show the document card
  mid-scroll: the literal text **"Member state unavailable. Member state is available when
  connected to a community."** followed by **two identical `Open document` buttons**, then
  `Request access`, `Mark unread`, `Publish linked waiver version`, `Download document`,
  `Ask coach`. The result frame differs only by a chip at top: **"Document history: 2 entries"**.
- **Findings, in order of severity.**
  1. **There is no `Acknowledge waiver` action anywhere**, and the acknowledgement state renders as
     the placeholder "Member state unavailable". The doc's persona row requires primary actions
     "open document, **acknowledge waiver**, download document" and §6 requires "…acknowledgement,
     access state, and authorized guardian share set" — quoting §7: "guardian opens and
     acknowledges a waiver/policy". The core guardian job is missing from the captured surface.
  2. **Placeholder/error text on a member-facing card.** "Member state is available when connected
     to a community" is developer-voiced filler in place of the acknowledgement/access state.
  3. **Two adjacent buttons with the identical label `Open document`.** The doc requires an
     "embedded/external open" *choice*; two same-named buttons make the choice illegible.
  4. **`Publish linked waiver version` is offered to a guardian.** The doc's guardian alternates
     are "request access, open external, mark unread, ask coach" — publish is not a guardian verb
     and reads as an admin action leaking into this persona's surface.
  5. Waiver **title/version and the authorized guardian share set are not visible** in any of the
     three frames, and no state label chip is in frame (top of card cropped) — unproven.
- **Receipt.** The only visible change is "Document history: 2 entries" — a countable, durable-ish
  receipt that something was opened, but with the above gaps the row is not proven as the doc's
  guardian acknowledgement journey.

### 7. Reminder notification — PASS with findings

**Workflow:** `soccer-reminder-notification`

- **Decision legible?** Yes. The action frame shows a rich practice-reminder context: `Upcoming
  practice` card "Riverside Rapids U12 practice", "0 / 18 going", Time 17:30, Location Riverside
  Sports Complex, Field North Field 2, session note, "Reminder: In-app remind…", "Reminder text:
  Practice starts at 5:30 PM on…" — real content a guardian can act on, plus the reminder card's
  `Open schedule` action at top.
- **Primary action semantic?** Yes — `Open schedule` is one of the doc's required guardian
  primaries ("receive reminder, mark read, open schedule").
- **Durable receipt?** Yes. The result frame's reminder card now carries **"Schedule opened
  2026-09-28T21:17:48.939249Z"** and "Change requests: 0", with `Mark read` as the filled primary
  and `Mute reminders` / `Request change` / `Open schedule` beneath — the schedule-opened receipt
  is recorded on the card with a timestamp, and the read-state continuation (`Mark read`) plus the
  doc's alternates (mute, request change) are all present.
- **State label?** Not visible — in both action and result frames the card's top (state chip
  position) is cropped. Unproven for this row.
- **Doc reconciliation.** §7/§119-121 require "sender, message body, audience/channel, timestamp,
  related schedule, and receiver/read state". Delivered: body, channel (In-app), related schedule
  (with receipt), read state (Mark read). **Not visible in these frames: the sender and the
  audience.** Partial against the doc's receiver-state row, hence a qualified pass.

### 8. Export metadata — FAIL

**Workflow:** `soccer-export-metadata`

- **Decision legible?** Emphatically yes — the best decision context in the whole set. Start frame:
  persona "Evidence soccer-owner — League Owner" with the Coach & Owner tab ("owner export
  controls. Tuned for League Owner.") and the export card in state **`Minor-data redaction
  reviewed`**: "Fall 2026 team metadata export", "Scope: Team names, Player display labels,
  Approval status, Waiver status", "Redacted: Full birth date, Medical notes, Home address, Private
  receipt". The action frame adds "Redaction approved: Yes" and a History entry "Owner confirmed
  minor-data redaction preview · soccer-owner · 2026-08-12T07:45:00-07:00", with actions
  `Change scope`, **`Start export or transfer`** (filled primary), `Cancel export`. This satisfies
  the doc's "export disabled without scope/redaction preview" context requirement and shows exactly
  what a protected-youth-data export will and will not contain.
- **Primary action semantic?** Yes — `Start export or transfer` is precisely the doc's verb set.
- **The failure.** The result frame shows state **`Export cancelled`** with the banner **"This is
  an off-path export state"** and a new History entry: **"Owner cancelled portability operation ·
  soccer-owner-21 · 2026-09-28T21:18:38.765303Z"**, primary now `Retry export`. The action frame's
  filled primary was *Start export or transfer*, but the receipt on record is a **cancellation** —
  the result frame documents a different action than the one the sequence presents as primary. The
  export itself (started/completed status, checksum, transfer status per §6 "redaction/checksum/
  scope" and §7 "receiving provider sees transfer status") is never shown.
- **Also noted.** The history attributes the cancellation to actor `soccer-owner-21` while the
  earlier entry says `soccer-owner` — an inconsistent actor identifier surfaced to the user on the
  same card.
- **State label?** Present in both start (`Minor-data redaction reviewed`) and result
  (`Export cancelled`).
- **Verdict.** As with Book Club's export row, the frames prove a legible cancel/retry path and
  excellent redaction disclosure, but they do not prove the export journey the B25 row exists to
  prove. Not proven.

---

## Notes for the dispatcher (not verdicts)

- The two export rows fail the same way in both communities — result = `Export cancelled`,
  self-labelled off-path, primary export result never captured. That pattern is worth checking in
  the capture harness's action selection for portability cards before re-running, since the Soccer
  action frame plainly offered `Start export or transfer` as the filled primary.
- Extra frames exist in the capture directory beyond the ticketed three per row
  (`alternate_action`, `result_receiver`, several `*_unavailable` rows for workflows outside this
  ticket). I judged only the eight ticketed rows on their three ticketed frames.
- I did not run the app, edit any code, test, or package; this file is the sole deliverable.
