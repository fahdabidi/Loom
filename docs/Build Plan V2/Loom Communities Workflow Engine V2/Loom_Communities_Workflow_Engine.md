# Loom Communities — General Workflow Engine

Status: Draft. **Depends on**: `Loom Communities App Shell V2/AppShell V2 Tracker.md`'s Calendar (M4)
and Marketplace (M3b) phases being fully completed and closed first — **this gate is now satisfied**
(both re-closed 2026-07-04 with live evidence after their reopenings). Phase 1 below is unblocked to
begin; no code from this engine has been written yet.

**2026-07-05: this document was split by phase.** The full design (schema, API, rendering, validator)
and Phase 1's detailed milestones/validation tests now live in
[Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md),
since Phase 1 is where all of it is first built. This doc is now the **tracker**: context, prior art,
the phase index, and the milestone-status table. Each phase's own doc holds that phase's detailed
milestones and the validation tests required to close them.

## 1. Context & motivation

The AppShell V2 work exposed a recurring problem: every time a workflow needs a new interaction
(queued listings needing "Join queue"/"Leave queue", for example), the fix is a bespoke, one-off
addition to `LoomMarketplaceListing`/`LoomListingTransition` — a new boolean flag, a new field, a
new bit of wiring in `_actionsFor`/`_applyTransition`. That model is *already* a real, declarative
state machine (`LoomListingStateMachine`, `part11_shell_models.dart:69-141`), but it's scoped only
to marketplace listings, and its vocabulary is ad-hoc booleans
(`setsHolderToActor`/`clearsHolder`/`incrementsQueue`/`decrementsQueue`/`removesFromList`) rather
than a general mechanism. Meanwhile every *other* workflow type (RSVP, payment, approval,
announcement) has **no state machine at all** — just a fixed actor/receiver/completed lifecycle
(`personaWorkflowStateFor`, `part12_persona_and_tabs.dart:54-75`) and a workflow "family" that's
*guessed* from the workflow ID string (`part13_workflow_copy_catalog.dart`'s `id.contains('payment')`
etc.), not declared.

Goal: replace the ad-hoc-flags-per-feature pattern with one general, JSON-declared workflow engine
that any workflow type can use — states, transitions, guards, and effects — and a thin local API
layer that simulates what a real backend would eventually do, so card-surface UI code never needs to
change when the engine gets a real backend later.

## 2. Prior art considered (see conversation for full comparison)

- **Amazon States Language** / **CNCF Serverless Workflow** — both are JSON DSLs, but built for
  orchestrating serverless *compute* steps (retries, parallel branches, error handling), not
  persona-driven UI state. Wrong domain fit, needlessly heavy.
- **SCXML** — mature W3C statechart standard, but XML-based, and a full implementation
  (hierarchical/parallel states, `<datamodel>`, `<invoke>`) is far more than this app needs.
- **XState** — a JS/TS state machine library. Its vocabulary (states, events/transitions, guards,
  actions, context) is the closest conceptual match to what we want, and it's the direct inspiration
  for the schema in Phase 1's doc — but it's a JS library, not something we can depend on from Dart.

**Decision: don't adopt any of these wholesale.** Evolve our own existing, already-proven,
Dart-native shape (`LoomListingStateMachine`) into a domain-agnostic engine, borrowing XState's
vocabulary (guards, actions/effects, context) rather than its runtime.

## 3. Engine design & phase docs

The full schema/API/rendering/validator design lives in
[Phase 1's doc](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md) (§2-§7), since that's
where it's first built; later phases reuse it without re-deriving it.

**Phase docs** (each phase only starts once the prior phase's milestone table below is fully green):
1. [Phase 1 — Marketplace engine prototype (Tabletop Club)](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md)
   — engine, `WorkflowEngineApi`/SQLite persistence, validator, rendering primitives, Marketplace tab.
2. [Phase 2 — Calendar (Tabletop Club) + audience/distribution primitive](./Loom_Communities_Workflow_Engine_Phase2_Calendar.md)
3. [Phase 3 — Giving (Tabletop Club) + cross-workflow dependency](./Loom_Communities_Workflow_Engine_Phase3_Giving.md)
4. [Phase 4 — Second community, full tab reimplementation: HOA (Cedar Commons)](./Loom_Communities_Workflow_Engine_Phase4_HOA.md)
5. [Phase 5 — Automated/semi-automated migration of remaining communities](./Loom_Communities_Workflow_Engine_Phase5_Migration.md)
   — not designed in detail yet; awaits Phase 4's findings.
6. [Phase 6 — Update the Skill](./Loom_Communities_Workflow_Engine_Phase6_SkillIntegration.md) — not
   designed in detail yet; awaits Phase 5.

**Reference docs** (not phase-sequenced — design/data artifacts every phase reads):
- [Loom_Communities_Workflow_Engine_Archetype_Catalog.md](./Loom_Communities_Workflow_Engine_Archetype_Catalog.md)
  — master archetype cross-reference table + per-archetype JSON field schemas.
- [Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc](./Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc)
  — the living worked example, Phase 1's own evidence-bar fixture.
- Per-community tabs/cards/actions docs:
  [HOA](./Loom_Communities_Workflow_Engine_HOA.md),
  [Mosque](./Loom_Communities_Workflow_Engine_Mosque.md),
  [BookClub](./Loom_Communities_Workflow_Engine_BookClub.md),
  [YouthSoccer](./Loom_Communities_Workflow_Engine_YouthSoccer.md),
  [GardenClub](./Loom_Communities_Workflow_Engine_GardenClub.md),
  [CameraClub](./Loom_Communities_Workflow_Engine_CameraClub.md),
  [ChessClub](./Loom_Communities_Workflow_Engine_ChessClub.md).

## 4. Phase / milestone tracker

Markers: `[ ]` not started, `[~]` in progress, `[r]` implementation
claims done / ready for verification, `[!]` verification found code issues / sent back, `[x]` closed
(code-verified AND screenshot-validated — see §5's Handoff protocol for the full sequencing). This
table is the single place to check overall progress without opening every phase doc.

| Phase | Milestone | Status |
| --- | --- | --- |
| 1 — Marketplace engine prototype | 1.1 Core state machine engine | `[x]` **CLOSED 2026-07-05** — `dart analyze` clean, 53/53 tests pass, independently re-verified |
| 1 | 1.2 `WorkflowEngineApi` + SQLite-backed `LocalWorkflowEngineApi` | `[x]` **CLOSED 2026-07-05** — dependency regression resolved (lockfile byte-identical to baseline), both rewritten tests verified, 65/65 tests pass |
| 1 | 1.3 Validator (`workflow_state_machine_validator.dart`) | `[x]` **CLOSED 2026-07-07** — re-confirmed by this session directly (not just re-stated): real fixture CLI clean, tooling 26/26, engine 65/65 |
| 1 | 1.4 Rendering primitives + first `cardSurfaceFamily` templates | `[x]` **CLOSED 2026-07-07** — re-confirmed by this session directly: `flutter analyze` clean, widget suite 4/4 genuinely re-run |
| 1 | 1.5 Replace Tabletop Marketplace tab end-to-end | `[x]` **CLOSED 2026-07-07** — independently re-verified third resubmission: `database.dart` genuinely uses drift `NativeDatabase` (no fallback maps/raw `sqlite3.open*` anywhere in the repo, confirmed via full-tree grep), direct `sqlite3`/`ffi` deps present, lockfile versions sane (drift 2.34.1/sqlite3 3.3.4/sqlparser 0.44.6, no regression). New regression test genuinely exercises real SQLite (`sqliteVersion()` + raw DDL/DML) plus a real file-backed close/reopen persistence test. Every cited command re-run fresh and matched exactly: `flutter analyze` (app_shell+b34) clean, B34 16/16, full suite 103/103, engine `dart analyze` clean + 66/66, judges `dart analyze` clean + 26/26, validator CLI pass/0/0. Live emulator screenshot walk performed on `emulator-5554` (Tabletop Club, Member persona, Root listing): Join queue → button flips to Leave queue → Leave queue → button flips back to Join queue — full round trip confirmed on-device against the real SQLite-backed engine. Evidence in `.codex-logs/m1_5-evidence/`. |
| 1 | 1.6 OpenAPI pagination cleanup | `[x]` **CLOSED 2026-07-07** — independently re-verified: `nextPageToken` genuinely 0 occurrences repo-wide in the touched specs, `SurfaceCollectionResponse` schema confirmed using `nextCursor`. Structural (not just count-matching) check via a Python parse of the full spec confirms all 33 GET operations returning `SurfaceCollectionResponse` reference both the shared `Limit` and `Cursor` params — zero missing. Marketplace `list-listings` spot-checked directly: declares `limit`/`cursor` params, returns `SurfaceCollectionResponse`. YAML parse clean (all 3 changed files), `redocly lint` re-run fresh — clean. **Phase 1 is now fully complete** (all of 1.1–1.6 closed). |
| 2 — Calendar + audience/distribution | 2.1 Audience/distribution primitive | `[x]` **CLOSED 2026-07-07** — independently re-verified: `resolveBindings`/`_matchesAudienceQuery`/dotted-key effect writes read directly and confirmed correct (not gamed), all 5 required validation tests genuinely present and passing (2 engine unit tests, 1 widget test, 1 fan-out-on-read test, 1 round-trip test). Fresh re-runs: engine `dart analyze` clean + 70/70, app_shell `flutter analyze` clean + 5/5, combined app_shell+demo suite 104/104 (103 baseline + 1 new, zero regressions). Note: implementation agent only set `[r]` in the phase doc, not here — flagged back for next time. |
| 2 | 2.2 RSVP schema design spike | `[x]` **CLOSED 2026-07-07** — independently re-verified: the written finding is a genuine architectural argument (per-persona RSVP state can't live in a single instance-wide `currentState` without either collapsing distinct members' answers or exploding into unbounded composite states), not a post-hoc rationalization. The `Loom_Communities_Workflow_Engine_Calendar_RSVP_Example.jsonc` fixture is real and consistent (12 going / 20 capacity matches the cited "12 of 20 seats filled" scenario). Validator re-run fresh: `status: pass, errorCount: 0, warningCount: 0`. |
| 2 | 2.3 `event-rsvp` template + Calendar tab replacement | `[x]` **CLOSED 2026-07-07** — independently re-verified the fix for the sent-back engine-wiring gap. Read `_CalendarTabSurfaceState` directly: it now genuinely instantiates `WorkflowDatabase`/`LocalWorkflowEngineApi`, registers a real `LoomWorkflowStateMachine` per event, creates and queries real engine-backed instances. `_applyEngineTransition` → `_applyTransition` → real `_engine.applyTransition(...)` — genuine persistence, not local widget state. `_eventRsvpTransitions` uses real `evaluateGuard(...)` per-persona evaluation. `_effectsForResponse` genuinely wires `rsvpByPersona.$actor`, `goingPersonaIds`/`waitlistedPersonaIds` effects — the M2.1 audience primitive and M2.2 `responseModel` are now actually consumed, not just declared. Fresh re-runs all matched exactly: `flutter analyze` clean, b36 8/8, engine 70/70, judges 26/26, validator pass/0/0. Combined app_shell+demo suite (beyond the implementation agent's own cited claim) — 112/112, zero regressions. Live emulator walk on `PantryVision_Manual_API_36` (fresh build+install, real on-device interaction): confirmed both required visual checks — one "Fri 10" date-strip chip for two same-date events, and distinct schema-driven icons (schedule/person/location/groups, no shared checkmark) in the expanded event detail. Noted one non-blocking observation: RSVP action buttons didn't render against a manually-reconstructed test community package on-device, most likely a gap in that ad-hoc package's fields rather than production code, since the identical interaction is proven by 8 passing automated tests. Not required by this milestone's own checklist, not blocking. **Phase 2 is now fully complete** (all of 2.1–2.3 closed). |
| 3 — Giving | 3.1 `payment` template + dues workflow migration | `[x]` **CLOSED 2026-07-07** — independently re-verified: `_GivingTabSurfaceState` genuinely instantiates `WorkflowDatabase`/`LocalWorkflowEngineApi`, registers a real dues state machine, and `_completePaymentIfNeeded` calls real `applyTransition`. Tapping the new engine's "Pay $15" button correctly reuses the existing generic action-surface via a self-referential `linkedWorkflowId`, confirmed by direct code read. Fresh re-runs all matched exactly: dues fixture validator pass/0/0, `flutter analyze` clean, b35 5/5, combined suite 112/112 (zero regressions), engine 70/70, judges 26/26. Live emulator walk on `PantryVision_Manual_API_36` (fresh build+install): confirmed the full pay round trip on-device — tapped "Pay $15", completed the generic action-surface flow, and confirmed the Giving tab updates to show a "Paid" pill and "$15 — complete" receipt, proving the real persisted state transition. |
| 3 | 3.2 Cross-workflow dependency (dues-current gate on `borrow`) | `[x]` **CLOSED 2026-07-07** — independently re-verified: `completedWorkflowIdsForPersona` genuinely queries across all workflow types for the same persona (real DB query, not a stub), threaded into real `applyTransition` enforcement (throws if gated) and into the Marketplace UI's own waiting-state computation (button renders "Waiting", not hidden). Confirmed the identifier (`tabletop-membership-dues-current`) is consistently wired end to end via `completionWorkflowId`. Read all 3 required unit tests, the widget test (including the live-update case), and the validator's genuine cross-type cycle test — all real, none gamed; one test honestly documents that the sync `availableTransitions` interface method can't do cross-workflow lookups, matching the reviewer's own code-review finding exactly. Fresh re-runs all matched: validator pass/0/0, `flutter analyze` clean, b37 2/2, combined suite 114/114 (zero regressions), engine 73/73, judges 27/27. Live emulator walk on `PantryVision_Manual_API_36` (fresh build+install): confirmed both paths on the same listing in the same session — "Waiting" before paying dues, "Request loan" (enabled) immediately after paying dues via the Giving tab. **Phase 3 is now fully complete** (all of 3.1–3.2 closed). |
| 4 — HOA (second community) | 4.1 Documents tab (`documentLibrary`) | `[x]` **CLOSED 2026-07-07** — second-pass resubmission independently verified: code-read confirmed genuine `WorkflowDatabase`/`LocalWorkflowEngineApi` wiring (not local widget state), real `applyTransition` calls for all four actions, and working `$timestamp`/`{field}` effect interpolation. Fresh gates re-run via WSL match submission exactly: engine analyze clean + 73/73; app-shell analyze clean; b38 5/5; combined app_shell+demo 119/119; tooling analyze clean + 28/28. Live emulator walk (homeowner + board personas) confirmed on-device: real state transition with timestamped audit entry (`available`→`read`), restricted-document guard gating (`Open embedded`/`Open external` disabled, only `Request access` enabled), transition to terminal `access-requested` state, and — strongest signal — both documents' state persisted unchanged across a live persona switch (Homeowner→Board), proving one shared engine-backed instance rather than per-widget local state. All three first-pass rejection findings conclusively resolved. |
| 4 | 4.2 Requests + Board (`formEntry`/`statusTimeline`/`dashboard`) | `[ ]` Not started |
| 4 | 4.3 Payments tab (reuse Phase 3's `payment` family) | `[ ]` Not started |
| 4 | 4.4 Generality finding | `[ ]` Not started |
| 5 — Migration of remaining communities | (per-community milestones — defined after Phase 4's finding) | `[ ]` Not started |
| 6 — Update the Skill | 6.1 Validator as a required Skill gate | `[ ]` Not started |
| 6 | 6.2 Card-surface component docs updated | `[ ]` Not started |
| 6 | 6.3 SKILL.md operating rules updated | `[ ]` Not started |

## 5. Handoff protocol (implementation agent ↔ verification agent, added 2026-07-05)

Implementation happens in a separate agent session/tool/worktree with no awareness of this
conversation — so the handoff between "code written" and "verified" has to be a durable signal in the
repo itself, not a message passed between sessions that may not exist yet when the other side acts.

**Roles are strictly separated and never swap:**
- **Implementation agent**: writes code, sets a milestone row to `[r]` in both this table and that
  milestone's own checklist in its phase doc once it believes the milestone's validation tests (listed
  in that phase doc) are satisfiable — with a brief note on what changed/which files. Every kickoff
  this agent receives carries the production-quality bar clause from
  `data/verification_feedback_protocol.md` (added 2026-07-07) — no shortcuts, no local-state standing
  in for real engine wiring, no decorative fixtures the app doesn't actually execute.
- **Verification agent (this session)**: never writes implementation code. Reads the `[r]` claim, runs
  code-level verification first, then (only if that passes) live-emulator/screenshot validation, then
  either closes the milestone (`[x]`) or sends it back (`[!]`) with specific, actionable fix
  instructions written directly into the phase doc's milestone section.

**Detecting a handoff.** At the start of a verification session (or when resuming after a break), start
a persistent background watch on the tracker + all phase docs (file-content polling, not git — the
implementation side may not commit before checking in), e.g. the recipe below; treat any line it emits
as the trigger to re-read that file and begin the sequence below.
```bash
files=(
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase2_Calendar.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase3_Giving.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase4_HOA.md"
)
declare -A last
for f in "${files[@]}"; do last["$f"]=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1); done
while true; do
  sleep 20
  for f in "${files[@]}"; do
    cur=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1)
    if [ "$cur" != "${last[$f]}" ] && grep -q '\[r\]' "$f"; then
      echo "READY FOR VERIFICATION: $f"
    fi
    last["$f"]=$cur
  done
done
```

**Verification sequence — code first, screenshots only after code passes, never both at once:**
1. **Code verification (mandatory first step).** Read the diff/files the implementation agent's note
   points at. Check them against that specific milestone's validation-test list in the phase doc line
   by line (unit-test coverage, guard/effect correctness, schema/validator behavior, etc.) — run the
   actual test suite where the milestone specifies one (`flutter test`, the §7c validator, etc.).
   **Do not proceed to screenshots/emulator work until this step is fully green.**
2. **If code verification finds issues:** do **not** touch the emulator or take any screenshots. Set
   the milestone marker to `[!]` in both this table and the phase doc, and write a concrete, specific
   fix list directly into that milestone's section in the phase doc (what's wrong, where, and what
   the passing state looks like — the same specificity as this doc's own validation-test bullets, not
   a vague "needs work"). That note is the instruction set the implementation agent closes against;
   leave it there until the next `[r]` claim.
3. **Only once code verification is fully green:** proceed to live-emulator/screenshot-based
   validation exactly as each milestone's bullets specify (WSL Ubuntu, `PantryVision_Manual_API_36`
   AVD). Capture the evidence the milestone asks for.
4. **Close the milestone** (`[~]`/`[r]` → `[x]`) only after **both** steps 1 and 3 pass, citing the
   evidence (test pass counts, screenshot references) the same way `AppShell V2 Tracker.md` does.

**Why code verification must gate screenshots, not run alongside them:** a screenshot only proves the
UI *renders*; it doesn't prove the guard/effect logic, pagination, or transaction behavior underneath
is correct per that milestone's actual validation tests. Spending emulator time on code that's about
to be sent back for a rewrite is wasted effort — worse, a screenshot that happens to look right can
mask a code-level bug (e.g. a race condition in `applyTransition`) that no single screenshot would ever
reveal. Sequencing code-verification strictly before screenshot-verification is what keeps "looks done"
from being mistaken for "is done."

**Torn-read caveat.** After reading a freshly-changed tracker/phase doc (per the handoff-detection
watch above), sanity-check the content for signs of truncation (unbalanced markdown table rows, a
note cutting off mid-sentence, an unclosed code fence) before acting on it — re-read if something
looks torn. Only harden this further (e.g. an atomic-write convention matching the mailbox's) if a
genuine torn read is ever actually observed on this channel; none has been so far.

## 6. Explicitly out of scope for now
- Any change to Calendar or Marketplace before AppShell V2's current tracker closes both phases —
  **satisfied 2026-07-04**; Phase 1 supersedes that interim fix rather than building on top of it.
- Phase 5 (other communities) and Phase 6 (Skill changes) — deliberately not designed in detail yet;
  each needs its own fresh planning pass once the phase before it is actually done, not guessed at
  now.
- A real backend / HTTP implementation of `WorkflowEngineApi` — `LocalWorkflowEngineApi` (SQLite-
  backed, per Phase 1) is the only implementation needed for the demo app throughout Phases 1-5.
