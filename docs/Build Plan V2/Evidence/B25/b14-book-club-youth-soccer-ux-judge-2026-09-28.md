# B14 UX judge — Neighborhood Book Club & Riverside Youth Soccer (2026-09-28)

Judge pass over the freshly captured `--mode full-b25` frames at
`/home/fahd/b25evidence/B14/screenshots/`, eight rows (5 Book Club, 3 Youth Soccer), each judged as
a start → primary-action → primary-result sequence, reconciled against
`neighborhood-book-club-product-experience.md` and `riverside-youth-soccer-product-experience.md`
(persona tables and B25 addendum tables). Where a row's named frames were ambiguous I consulted the
same run's `alternate_action`/`result_receiver` frames for context and say so explicitly.

## Overall summary

**5 PASS, 2 FAIL, 1 UNPROVEN.**

- The two FAILs are **one class, and it is the known portability class**: both `*-export-metadata`
  rows captured a **cancellation** as the row's outcome. Neither community's frames show an export
  actually completing, and no frame anywhere shows a **checksum**, which both docs make part of the
  export contract. The cancel → retry loop itself works and leaves excellent receipts — but that is
  the docs' *alternate* path, not the primary flow.
- The state-label feature is broadly working: every card that was fully in frame rendered a
  declared state label (`Submitted`, `Selected for ballot`, `Published`, `Digest open`,
  `Draft listing`, `In library`, `Minor-data redaction reviewed`, `Export cancelled`,
  `Access requested`, `Reminders muted`). No fully-visible card lacked one.
- Campaign-wide polish findings that recur across rows: **raw ISO-8601 timestamps with microsecond
  precision shown to end users** (`2026-09-28T21:11:54.703676Z`, three rows across both
  communities); the **app bar title renders as a single truncated letter** next to the LOCAL ENGINE
  pill in every frame; and every frame carries the **LOCAL ENGINE** badge — these frames depict the
  local-engine harness, so per standing evidence rules they support UI/UX claims only, not claims
  about the remote backend.

---

## Neighborhood Book Club

**Workflow:** `book-nomination`
**Outcome:** PASS

- **Legibility:** Start frame shows the community header and the signed-in member identity with a
  role description ("Nominates books, votes, RSVPs…"). The action frame shows an existing
  `Selected for ballot` card (The Song of Achilles, author, genre, cycle) for context.
- **Primary action:** `Submit nomination` — the exact domain verb the doc's primary list names
  ("submit nomination, nominate book, save nomination").
- **Result:** Durable. A new card appears in `Submitted` state — The Night Watchman, by Louise
  Erdrich, Genre, Cycle: October 2026 — above the pre-existing `Selected for ballot` card. This is
  a new persisted-looking entity with its own state, not a return to the start screen.
- **State labels:** `Submitted` and `Selected for ballot` both render.
- **Doc reconciliation:** The flow row ("member submits a concrete book nomination with
  title/author/rationale") is substantially delivered. Two of the doc's required elements are *not*
  visible in the captured frames: the **rationale** (the doc requires "title/author/rationale" and
  "submit disabled without title, author, and rationale" — no rationale chip renders on either
  nomination card) and the **edit path** ("edit nomination, withdraw nomination"). Findings, not
  failures: the captured primary flow itself is proven.

**Workflow:** `book-search-ai-digest`
**Outcome:** PASS

- **Legibility:** The action frame shows an existing `Digest open` card with a real query ("Best
  discussion questions for The Song of Achilles?"), a Sources section naming "Madeline Miller
  official reading guide" with its URL, and an added date — plenty of context.
- **Primary action:** The captured button is a generic **`Submit`**. Normally that would be a
  semantic-verb finding, but the doc's own addendum row for this workflow lists exactly "submit,
  save, send" as the primary verbs, so the screens match the doc as written. The doc's verb row is
  itself generic boilerplate — worth tightening doc-side.
- **Result:** Durable. A **new** `Digest open` card appears ("What historical context does Circe
  draw on?", "Waiting for an answer") above the earlier one, with Save digest / Edit query / Add
  citation / Report stale citation / Withdraw actions.
- **State labels:** `Digest open` renders on both cards.
- **Doc reconciliation — disagreement to record:** the flow row promises *"members receive answer
  with citations and source visibility"* (line: "book-search-ai-digest | member asks for cited club
  digest/search result | members receive answer with citations and source visibility | …"). No
  frame shows an answer; both digests sit at "Waiting for an answer". The *ask* half is proven; the
  *answer* half is not shown in any frame of this run. (Consistent with the known missing external
  search/AI platform service — but that inference is from project records, not from these pixels.)

**Workflow:** `book-shared-library-item`
**Outcome:** PASS

- **Legibility:** The action frame is the item detail dialog for "Circe (hardcover)" in
  `Draft listing` state with format (Book), condition (Good), mode (Loan), and a privacy-safe owner
  label ("Owner: Book Member") — exactly the decision context a lister needs.
- **Primary action:** `Publish listing` — domain verb, correct for a draft.
- **Result:** Durable state change: the same dialog now shows `In library` with an `Available` chip
  and the follow-on owner actions `Pause listing` and `Delist`. The background grid also shows the
  card's badge moved from `Draft listing` to `In library`.
- **State labels:** `Draft listing` → `In library`, both rendered; grid cards labelled too.
- **Doc reconciliation:** "list item" is in the doc's primary verb list, so this is a legitimate
  primary flow for the row. Two findings: (1) the dialog shows **`Overdue` alongside `Available`**
  — a just-published, never-loaned item cannot be overdue, and it shows `Overdue` even in the
  Draft dialog; contradictory chips on one card. (2) The doc's required "queue position" and
  "due date" are not visible in these frames (`Overdue` renders with no date). The doc's other
  required elements (title/format, owner privacy label, custody/condition, loan mode) are present.

**Workflow:** `book-selection-publish`
**Outcome:** PASS

- **Legibility:** Start frame shows the organizer identity ("Curates the ballot, publishes the
  selection…") and the Admin tab ("Role-specific publishing, approvals, and operations. Tuned for
  Organizer."). The action frame shows the ballot pipeline: a `Published` selection (The Song of
  Achilles, For All members) and `Submitted` nominations with `Select for ballot` buttons.
- **Primary action:** `Publish announcement` — domain verb, matches the doc's primary list
  ("publish announcement, send announcement, post announcement…").
- **Result:** Durable. A **new** `Published` card for **Circe — For All members** appears above the
  earlier Song of Achilles one. Clear receipt that the publish happened, with audience shown.
- **State labels:** `Published` and `Submitted` render throughout.
- **Doc reconciliation:** The flow row ("owner publishes selected book announcement to members") is
  delivered by the organizer persona the addendum table names. One gap: the surface row promises
  "selected book/audience/timing" — **timing** is not visible on the published card (book and
  audience are). Receiver state ("members receive selected book and meeting update") was not part
  of this row's captured frames.

**Workflow:** `book-export-metadata`
**Outcome:** FAIL

- **What the frames show:** The action frame's captured primary control is a red **`Cancel`**
  button. The result frame shows the export card in **`Cancelled`** state with the app's own banner
  *"This is an off-path export state"*, chips "Scope: Nominations and vote history, Q3 2026",
  "Export cancelled", a raw timestamp `2026-09-28T21:11:54.703676Z`, and a `Retry` button. The
  run's receiver frame then shows retry working: state back to `Draft` with "Retry started" and
  `Preview redaction` / `Cancel` actions.
- **Why FAIL:** The doc's primary flow for this row is an export, not a cancellation. Flow row:
  *"book-export-metadata | owner exports book club metadata with redaction/checksum |
  provider/import reviewer sees verified export status | … | export disabled until checksum and
  redaction preview pass"*. The addendum row lists "export, download export, start transfer, import
  data" as primaries and files "cancel transfer … retry" under alternates. The captured sequence
  exercises only the alternate cancel/retry loop; **no frame shows an export completing, a
  download, or any checksum**. The result screen itself declares the outcome off-path.
- **What is honestly proven:** cancel produces a real state change with a timestamped receipt, the
  off-path state is clearly labelled, and retry restores `Draft`. Good UX on the branch that ran —
  but the row's documented primary capability is not demonstrated, and this is the same class as
  the Youth Soccer export row below.

---

## Riverside Youth Soccer

**Workflow:** `soccer-waiver-document`
**Outcome:** UNPROVEN

- **What the named frames show:** Start is the community landing (guardian identity, Documents tab
  blurb "Waivers, policies, versions, acknowledgement, and access requests. Tuned for Guardian.").
  The action frame is the document card's action list — **two identical `Open document` buttons**,
  `Request access`, `Mark unread`, `Publish linked waiver version`, `Download document`,
  `Ask coach` — with the text *"Member state unavailable. Member state is available when connected
  to a community."* rendered mid-card. The card's title, version and state label are **above the
  crop in both the action and result frames**. The result frame is essentially the same surface
  scrolled slightly, newly revealing a "Document history: 2 entries" chip — **no visible state
  change, no receipt, no confirmation.**
- **Why UNPROVEN:** From the named sequence I cannot tell what the primary action did. If it was
  `Open document`, its effect (an embedded/external viewer) is not captured, and the result frame
  is indistinguishable from the action frame. That is precisely "a screen that merely returns to
  where it started". I am not marking FAIL because nothing here contradicts the doc — the run's
  receiver frame proves the surface is alive: it shows the card in `Access requested` state with
  "2026 Player Safety and Participation Waiver", "Version: v3.2", embedded/external open chips,
  "Access: Members may open; acknowledgement is tracked", "Authorized guardians: 1", "Acknowledged
  2026-08-10T16:50:00-07:00", "Document history: 3 entries" and a `Withdraw access request` action
  — i.e. the *Request access* alternate produced a durable, state-labelled receipt. But that is an
  alternate, and the row's primary sequence as captured proves nothing.
- **Doc reconciliation:** The doc requires *"Fresh screenshots must show title/version/source,
  embedded/external open options, acknowledgement state, authorized-guardian access proof, access
  guard, and registration-status linkage"* — the named action/result frames show none of the
  identity elements (all cropped); the receiver frame shows most of them. Registration-status
  linkage appears in no frame. Additional findings: (1) duplicated `Open document` button; (2)
  **`Publish linked waiver version` renders for the guardian persona** — the doc's guardian verb
  lists ("open document, acknowledge waiver, download document" / "request access, open external,
  mark unread, ask coach") include no publish verb, so a publish affordance on the guardian's card
  is a persona-surface disagreement worth checking against the package's guards; (3) the "Member
  state unavailable…" internal-limitation copy is user-visible.

**Workflow:** `soccer-reminder-notification`
**Outcome:** PASS

- **Legibility:** Start shows the guardian identity ("…follows schedules, and receives
  reminders"). The action frame shows the reminder's practice context: "Riverside Rapids U12
  practice", 0/18 going, Time 17:30, Location Riverside Sports Complex, Field North Field 2,
  reminder channel and message-text chips, plus the roster row (Jordan R.).
- **Primary action:** `Open schedule` — one of the doc's named primary verbs ("receive reminder,
  mark read, open schedule").
- **Result:** Durable receipt: the card now carries a **"Schedule opened
  2026-09-28T21:17:48.939249Z"** chip and "Change requests: 0", with `Mark read`,
  `Mute reminders`, `Request change`, `Open schedule` available. The run's receiver frame further
  shows the full card in `Reminders muted` state with sender ("Sent by: Soccer Coach"), recipient,
  audience ("Guardians for this practice"), channel ("In-app reminder center"), message body
  ("Practice starts at 5:30 PM on North Field 2. Bring water and shin guards."), "Sent
  2026-08-12T09:00:00-07:00", "Delivery: Sent", and a "Muted …" receipt — everything the doc's
  "Fresh screenshots must show sender, message body, audience/channel, timestamp, related
  schedule, and receiver/read state" list demands is visible across the sequence.
- **State labels:** Not visible in the named action/result frames (card cropped above the action
  list); `Reminders muted` renders in the receiver frame, and `Upcoming practice` labels the
  schedule card. Recorded as a cropping finding, not a product one.
- **Findings:** raw ISO-8601 microsecond timestamps shown to the user ("Schedule opened
  2026-09-28T21:17:48.939249Z", "Muted 2026-09-28T21:18:07.407199Z"); the read-state verb pair
  (`Mark read` present) is consistent with the doc's read-state requirement.

**Workflow:** `soccer-export-metadata`
**Outcome:** FAIL

- **What the frames show:** Start and action frames give the best decision context of the whole
  batch: owner identity ("Creates redacted, portable league metadata exports"), card in
  **`Minor-data redaction reviewed`** state, "Fall 2026 team metadata export", "Scope: Team names,
  Player display labels, Approval status, Waiver status", "Redacted: Full birth date, Medical
  notes, Home address, Private receipt", "Redaction approved: Yes", and a History entry ("Owner
  confirmed minor-data redaction preview · soccer-owner · 2026-08-12T07:45:00-07:00"). The action
  frame's filled primary button is **`Start export or transfer`**, with `Change scope` and
  `Cancel export` as alternates.
- **Why FAIL:** Despite `Start export or transfer` being the rendered primary, the result frame
  shows the card in **`Export cancelled`** state — banner *"This is an off-path export state"* —
  and the History has gained *"Owner cancelled portability operation · soccer-owner-21 ·
  2026-09-28T21:18:38.765303Z"*. The recorded interaction was the **cancel**, not the export. The
  doc's flow row promises *"owner exports team metadata | receiving provider sees transfer status |
  export summary readable"* — no frame shows an export completing, a transfer status, or a
  checksum. Same one-class failure as `book-export-metadata`: the portability primary flow is not
  demonstrated in either community; only the cancel/retry alternate is.
- **What is honestly proven:** the redaction-review context is excellent (scope + redacted fields +
  approval + attributed history); the cancel produced a state-labelled, timestamped, actor-
  attributed history receipt; `Retry export` is offered from the cancelled state. The off-path
  branch is well built — it is just not the row's documented capability.
- **Additional findings:** raw ISO-8601 microsecond timestamp again; the History actor renders as
  `soccer-owner-21` for the cancel while the earlier entry says `soccer-owner` — two identifier
  shapes for the same persona in one history list, worth a look at which identity the cancel path
  stamps.

---

## Cross-row findings (for the tracker, not counted against any single row)

1. **Portability primary flow unproven in both communities (the two FAILs).** Both export rows
   ended in `Cancelled` with the app's own "off-path" banner. No export completion, download, or
   checksum appears in any of this run's frames for either community.
2. **Raw machine timestamps in user-facing chips** across three rows and both communities
   (microsecond ISO-8601 with `Z`/offset). One formatting pass would clear the whole class.
3. **App bar title truncated to a single letter** beside the LOCAL ENGINE pill in every frame of
   both communities.
4. **`book-shared-library-item` shows `Overdue` on a never-loaned listing** (and alongside
   `Available` after publish) — contradictory status chips on one card.
5. **Guardian sees `Publish linked waiver version`** on the waiver card — an affordance the doc
   does not give that persona.
6. **"Member state unavailable. Member state is available when connected to a community."** is
   internal-limitation copy rendered verbatim to the user on the waiver card.
7. All frames carry the **LOCAL ENGINE** badge: this evidence supports walkthrough-half UI claims
   only; nothing here proves remote-backend behaviour, per the standing evidence rules.
