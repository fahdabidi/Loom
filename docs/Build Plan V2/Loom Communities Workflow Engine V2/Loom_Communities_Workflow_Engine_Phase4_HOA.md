# Phase 4 — Second Community, Full Tab Reimplementation: HOA (Cedar Commons)

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
Phases [1](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md),
[2](./Loom_Communities_Workflow_Engine_Phase2_Calendar.md), and
[3](./Loom_Communities_Workflow_Engine_Phase3_Giving.md) being fully closed.

Status: not started.

## 1. Scope & goal

Prove the schema generalizes beyond Tabletop's three patterns (loan/giveaway marketplace, RSVP
calendar, dues payment) before building any automation or touching the Skill. Full tab detail
(personas, cards, per-archetype customizations) already lives in
[Loom_Communities_Workflow_Engine_HOA.md](./Loom_Communities_Workflow_Engine_HOA.md) — this doc adds
the phase's milestones and validation bar.

**Why HOA, not another option**: surveyed the other built-out community examples first (Mosque,
Book Club, Youth Soccer, Garden Club, Chess Club, Camera Club — via `docs/Build Plan V2/Phases/`,
`docs/Product Docs V2/Community Examples/`, and B14 evidence folders). Garden Club and Camera Club
are dominated by direct re-skins of the same loan/giveaway + RSVP patterns Tabletop already covers —
weak contrast. HOA's tab IA (Home, **Board**, **Documents**, Payments, **Requests**, Messages) is the
best genuine contrast: **Documents** is a wholly new card-surface family (library/permissioned
reading, nothing like it in Tabletop), and **Requests**/**Board** (architectural-request →
committee-decision, submitted by the homeowner via `formEntry`, tracked by both sides via
`statusTimeline`) is a multi-step approval/case-task workflow — the "approval/review" family the
schema hasn't been proven against yet. Only HOA's Payments tab overlaps with what Marketplace/Giving
already proved. Mosque is a strong runner-up (Care/protected-vault and Admin/announcements+
volunteer-signup are equally novel) if HOA surfaces a blocking issue.

This is a **reimplementation with parity**, not a redesign — HOA's existing customizations/UI (per
[Loom_Communities_Workflow_Engine_HOA.md](./Loom_Communities_Workflow_Engine_HOA.md)'s
Personas/Tabs/Customizations tables) are the acceptance bar.

## 2. Milestones

### Milestone 4.1 — Documents tab (`documentLibrary`)
Reimplement HOA's Documents tab: categorized library/folders, document detail, embedded-vs-external
open choice, version/access/acknowledgement state, audit trail.

**Validation tests required to close this milestone:**
- [ ] Unit test: the HOA documents fixture parses and passes the Phase 1 §7c validator.
- [ ] Widget test: category/folder navigation, document detail open (both embedded and external-open
  paths), version display, and access-request gating each work as their own test.
- [ ] Widget test: audit trail records and displays an entry on document open/acknowledge — assert
  the actual entry content (who, when, what action), not just "a list item appeared."
- [ ] Live emulator walk: screenshot evidence of the new Documents tab matching the existing
  implementation's behavior for both personas (homeowner, board).
- [ ] Full `flutter test` suite green, exact pass count cited, zero regressions elsewhere.

### Milestone 4.2 — Requests + Board (submitted `formEntry`, tracked `statusTimeline`, reviewed `dashboard` queue)
Reimplement the architectural-request workflow: homeowner submits via `formEntry`, both sides track
progress via role-keyed `statusTimeline` bindings (Phase 1 §2a's actor/receiver split), board persona
also sees a `dashboard` review queue.

**Validation tests required to close this milestone:**
<br>
**This is the milestone most likely to be the "did the schema actually have to change" test case
(§3 below) — give it the most scrutiny.**
- [ ] Unit test: the HOA architectural-request fixture (submit → under-review → changes-needed →
  approved/rejected → reopened, per
  [Loom_Communities_Workflow_Engine_HOA.md](./Loom_Communities_Workflow_Engine_HOA.md)) parses and
  passes the Phase 1 §7c validator, including its multi-role `renderBindings` (homeowner `actor`,
  board `receiver`/reviewer) staying under the ≤32/≤16 cap.
- [ ] Widget test: homeowner's `formEntry` submission creates an instance in the initial state, with
  `editableFields` (Phase 1 §7a-i) matching the fixture's declared per-state editability.
- [ ] Widget test: homeowner's `statusTimeline` view (role: actor/tracking) and board's
  `statusTimeline` view (role: receiver/reviewer) render from the **same instance**, showing the
  correct state-specific alternate actions on the reviewer side (request changes, reopen, appeal,
  retry) via `availableTransitions`, not hardcoded per-surface logic.
- [ ] Widget test: board's `dashboard` review queue lists pending requests and tapping one navigates
  to the same `statusTimeline` reviewer surface (proves the queue is a pointer, not a duplicate
  render, per Phase 1 §2a's `bindingKind: "summary"` vs `"primary"` distinction).
- [ ] Full behavioral-parity walk against every state transition named in
  [Loom_Communities_Workflow_Engine_HOA.md](./Loom_Communities_Workflow_Engine_HOA.md)'s Requests/Board
  section: submit, approve, reject/send-back, request-changes, reopen — each with its own test.
- [ ] Live emulator walk: screenshot evidence of both personas' views of the same request instance,
  at least one state transition performed on-device by the board persona and reflected live (or on
  next load, whichever the implementation's refresh model is) in the homeowner's view.
- [ ] Full `flutter test` suite green, exact pass count cited.

### Milestone 4.3 — Payments tab (reuse Phase 3's `payment` family)
Reimplement HOA dues on the `payment` `cardSurfaceFamily` built in Phase 3 — the one HOA tab expected
to require no new schema capability.

**Validation tests required to close this milestone:**
- [ ] Unit test: HOA dues fixture parses and passes the validator, reusing the exact `payment` family
  template from Phase 3 with zero template changes (confirm via diff that the template file itself
  is untouched — only the fixture/JSON differs).
- [ ] Widget test: full HOA dues pay/receipt/history flow, parity with existing implementation.
- [ ] Live emulator walk: screenshot evidence of HOA Payments tab on-device.
- [ ] Full `flutter test` suite green, exact pass count cited.

### Milestone 4.4 — Generality finding (mandatory evidence artifact, not optional)
A written note — added to this doc once each milestone above is closed — stating explicitly what, if
anything, the schema had to be *changed* to support across all three tabs (new guard/effect ops, a
new `cardSurfaceFamily` concept, anything `instanceDataSchema` couldn't express cleanly).

**Validation required to close this milestone:**
- [ ] The finding is written and cites, for each of Milestones 4.1-4.3, either "no schema change
  needed" or the specific change made and why the existing primitives couldn't express it.
- [ ] If nothing needed to change, that finding is stated plainly as the strongest possible signal
  the schema is genuinely general — not hedged or omitted.
- [ ] If something DID need to change, a follow-up note on whether Phase 1's design docs
  (state machine schema, `instanceDataSchema`, or the archetype catalog) need a corresponding update,
  filed as a fast-follow task before Phase 5 begins.
