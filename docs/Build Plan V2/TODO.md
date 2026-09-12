# Live TODO — cross-effort rollup

**This is an index, not a memory.** One line per open item, newest/most-relevant first, each linking to its
full entry (context, source, exact wording) in the owning tracker's own `## 8. Live TODO / Next Steps Queue`
section (`docs/Build Plan V2/Tools/reference-tracker-template.md` defines that section's shape and the fixed
tag taxonomy used everywhere below). Never write item detail directly here — if you're about to write more
than one line for an item, that content belongs in the tracker, not here.

**How this file gets updated:** propose-then-promote, never a dispatched agent editing this file directly.
An Implementation Agent proposes next steps in its own STATUS.md (`## Proposed next steps`); during your own
independent-verification step, you review that proposal, write the confirmed items into the owning tracker's
§8, and add/remove the matching one-line rollup here. Every `call_*.sh` dispatch script prints a reminder
banner at completion so this step is never silently skipped — see `docs/Build Plan V2/Tools/README.md`'s core
pipeline step 5.5.

**Use the Root Cause Agent (`data/call_root_cause_agent.sh`) for two jobs, across every tracker this
file rolls up, not only the one it's traditionally been used for.** (1) To scope a non-trivial change
*before* writing an implementation ticket — what it actually touches, the real mechanism, what it would
break — rather than writing a ticket from an assumed mechanism and finding out it was wrong a full
implementation round later. (2) Its standing job: anything resisting normal investigation — a stubborn
defect, a stalled walkthrough, an unclear suite failure — goes to it before spending more implementation
rounds guessing. Never write a ticket that asserts a mechanism nobody has actually traced.

**Verification sweep 2026-08-24.** Every checkable claim below was re-measured against the working tree
rather than carried forward, and nine items closed on measurement alone — they had been fixed by later work
and never struck. Suite baselines quoted inside older tracker entries are stale by construction; the current
numbers are judges **432**, app shell **271**, engine **281 (+3 skipped)**, demo **156**, zero failures on
Windows.

**Backend-integration sweep 2026-08-26/27.** The app now runs on the real backends by default and the
document library exists end to end. Current baselines: judges **434**, app shell **307**, engine **299
(+4 skipped)**, workflow service **75 (+5)**, demo **160**, app-access **49**.

**A pattern this sweep kept finding: declared and never read.** Seven constants, fields or code paths
existed and nothing consumed them — `sharingGrantable`, a state `readGuard` under a non-`guarded`
default, `explicitReaderFanIds` (`writableBy: None`), the renderer contract's `calendar`
surface-family, `SurfaceQuery.dateWindowStart/End`, the engine's `workflowType == 'notification'`
delivery branch, and `dueNotifications` itself. None failed anything. **A grep for a declaration
proves it exists, not that anything reads it** — check the consumer.

**A measurement caveat worth carrying.** Two sweeps run that day were wrong in the same way: they read an
artifact instead of the code path that consumes it. `grep actorIdentities` over the packages returned zero
and was read as "packages declare no identities" — they are *derived* from `roles[]` at load. A role
cross-check that ignored `_roleIdsForB25Role`'s synonym fallbacks reported 11 blocked rows when the real
number is 5. Both had been "validated", but only against cases of one kind. **Validate a sweep against a
known answer for every kind of thing it claims to find, not just one.**

**Restructured 2026-09-12.** This file had drifted into the opposite of its own stated design:
87 closed rows against 36 open ones, multi-paragraph entries where the header demands one line,
and two tags (`needs-spec-decision`, `needs-user-decision`) outside the fixed taxonomy. The order
below is deliberate — **what unblocks the production bar first**. Nothing was deleted: every open
row's full text is in [TODO-open-detail.md](TODO-open-detail.md), and every closed row is in
[TODO-closed.md](TODO-closed.md).

**The bar, re-measured 2026-09-12 rather than recalled** (`check_b25_status.sh`): **72 real rows ·
walkthrough half 10 · judge half 57 · both halves 10**. So 47 rows already hold a judge artifact and
lack only a live walkthrough — class 4 below is the single biggest lever, and nothing in class 3 or 5
moves the bar until those walkthroughs run.

**Off-taxonomy tags retired.** `needs-spec-decision` and `needs-user-decision` were never in the
template's fixed set. Both are now `blocked` — the template's own tag for "can't proceed until a named
external thing resolves" — with the decision stated as one answerable question in class 2, so they can
be batched rather than rediscovered one at a time.

## Open

### 1. Release blockers

- [ ] `needs-user-decision` — **The P4 parity gate WORKS, nobody has acted on what it reports, and it is reporting six live violations right now — including the Masjid over-grant the whole P-series was built for.** Measured by me 2026-09-12 by running `check_permission_parity.sh` against the live cluster. **P3 and P4 built the *prevention* (`role_kind`, the exact-set gate) and are correctly closed; the contaminated *data* was never cleaned.** That is this project's recorded "a capability has to be true at every layer" pattern — the gap moved layers rather than closing, and each layer's row reads as locally complete. **Violation 1, rule 1 (governance set), security-shaped:** `masjid-nur-admin` holds **28** permissions where all 14 other community admins hold exactly **5** — a perfect outlier. The 23 extras are the `owner` domain role's archetype permissions (`discussion_thread.*`, `document_library.*`, `event_rsvp.*`, `form_entry.*`, `search_ai_answer.*`, `approval_queue_item.*`), copied in by the 2026-09-02 SQL recipe whose own mapping said "preserve all 28 grants" and whose anomaly note flagged them "for user decision" — never resolved. **State the blast radius precisely, because I got this wrong once before:** the violation is real at the **App Access** layer, where `checkAccess` grants those domain allowances to anyone holding the admin role; it is **absent at the engine layer**, because `guard_evaluator.dart:29-37` intersects real role ids and never permissions, so the over-granted admin still fails the four `byRoleIds: ["owner"]` transitions. It is a standing privilege violation of `permissions.md:522`, not a live path to owner actions. **Violations 2-6, rule 2 (package-derived sets), and these are FUNCTIONAL, not cosmetic — they sit directly in the campaign's path:** `book-member` and `book-organizer` are each missing several derived permissions (`document_library.download`, `equipment_loan.*`, `event_rsvp.withdraw_response`); `soccer-owner` is missing `export_wizard.download`; `soccer-guardian` is missing `document_library.download`; and `soccer-coach` holds `document_library.upload` while the package derives `document_library.edit` — a mismatch, not just a gap. **Why this matters now:** Book Club (7 rows) and Youth Soccer (6 rows) are the next two clusters in the walkthrough queue, and a missing derived permission is exactly what produced the live `403` on Cedar's `hoa-facility-reservation` earlier in this campaign. `soccer-export-metadata` needs `export_wizard.download`; `soccer-waiver-document` is the one the `edit`/`upload` mismatch would hit. **Expect 403s on those rows unless this is fixed first.** **Why I did not just fix it:** every item here is a live authorization change to a running cluster — removing 23 grants from a real role, and adding grants to five others. I over-reached on exactly this kind of change once before (granting `app-access-provisioner` to the production workflow-service client unprompted) and the right move was to escalate rather than work around the block. **My recommendation, in order:** (1) remove the 23 non-derived grants from `masjid-nur-admin` via `setRolePermissions`, leaving the five `community.*` — surgical, and avoids `installCommunityPackage`'s sweep; (2) backfill the five package-derived gaps the same way, before Book Club and Youth Soccer are walked; (3) add `check_permission_parity.sh` to the post-deploy audit so its output is *read* rather than merely produced — a gate nobody runs is a gate that does not exist, which is precisely what happened here.
- [ ] `new-ticket` — Live cluster holds state that exists nowhere in git (`test-fan-alice`/`test-fan-bob` and their `fanId` claims) — [detail](TODO-open-detail.md#row-197)
- [ ] `new-ticket` — 68 seeded accounts share one password (`LoomTest123!`) — doubled since first written — [detail](TODO-open-detail.md#row-199)
- [ ] `new-ticket` — Rotate three exposed secrets before GA — Google client secret, Facebook app secret, DeepSeek API key — [detail](TODO-open-detail.md#row-298)

### 2. Decisions owed by the user

- [ ] `blocked` — **`transitionRelated` cannot deliver the cancellation sweep `event-rsvp.md` requires, and the two hard-locked reference docs contradict each other. Needs a spec decision.** Found 2026-09-12 by a Garden Club walkthrough, root-caused (session key `transition-related-silent-failure`), and the contradiction verified in both docs by me. **Observed live:** `cancel-event` declares five `transitionRelated` effects to release respondents; the call returned **200 and moved nothing** — the event is `cancelled` while its response row is still `going`, so a cancelled event advertises a live RSVP (`community_garden_club_garden-event-rsvp_gwrvhmw1ztbk` / `...-response_g45yq8qnsj95`). **The conflict:** `effects.md` §`transitionRelated` defines the mechanism as single-row best-effort — `limit` "currently only `1` is defined", applied to "the **first** matching row after sorting", with guard failure an explicit "silent-no-op" — and says outright that the gap it closes is *waitlist promotion*. `archetypes/event-rsvp.md` requires the opposite: "Cancelling **must sweep the rows** … the sweep must cover **EVERY** non-terminal state … Leaving those behind means a cancelled event still has rows claiming a live answer." The package did exactly what the archetype doc instructs (one effect per source state) and still failed. **Even with linkage fixed, `matches.first` strands every respondent after the first**, so any multi-person event under-applies silently. **This corrected my own premise:** I assumed the parent transition had already committed, making rollback impossible; parent and target effects actually run in the SAME transaction, and it is the swallowed guard refusal — silence — that permits a false success. **The decision, stated as one question:** should `transitionRelated` gain an explicit all-match, refusal-propagating mode for required cascades (keeping today's first-match best-effort semantics for promotion, which are separately specified and correct), or should the archetype stop expressing cancellation through this mechanism and get a different one? Not implementable either way without choosing — both docs are hard-locked, and this is the "never specify an effect without its mechanism" shape CLAUDE.md already records. **A STRUCTURAL FACT FOUND 2026-09-12 THAT MAY RESHAPE THIS QUESTION — read it before choosing between the two options below, because it suggests a third.** The `event-rsvp` archetype is expressed **two structurally different ways** across the shipped packages, and the "must sweep" requirement is only meaningful for one of them. I verified this by reading both packages:

| | Garden Club | Masjid Nur |
|---|---|---|
| RSVP storage | a **separate `garden-event-rsvp-response` workflow**, one instance per respondent | **lists on the event instance itself** — `goingFanIds`, `maybeFanIds`, `notGoingFanIds`, `waitlistFanIds` (15 occurrences) |
| `goingFanIds` in package | **0** | **15** |
| `transitionRelated` effects | **5**, on `cancel-event`, to release respondents | **0 — the package contains none at all** |
| `cancel-event` | declares the sweep, and the sweep **silently moves nothing** | plain `cancel`, no sweep declared |

**Masjid needs no sweep, and its absence is not a defect.** `event-rsvp.md`'s stated concern is that *"a cancelled event still has rows claiming a live answer"* — Masjid has **no such rows**. Cancelling the event row cancels the RSVPs because the RSVPs live *on* that row. So the archetype doc's cancellation requirement is written for the separate-response-row model and is vacuous for the in-instance-list model, while the doc itself does not say which representation it governs.

**Corpus context:** 6 of 10 packages use `transitionRelated` at all (Ad-Free 19, Cedar 12, Youth Soccer 8, Camera 6, Book Club 5, Garden 5); **4 use none** (Masjid, Member Social Space, Data Portability, Chess).

**So there is a third option to weigh alongside the two below:** the divergence may not be in `transitionRelated` at all, but in the archetype shipping **two representations** with a cancellation rule written for only one. If the in-instance-list model is the intended one, Garden's separate-response workflow is the thing to change and the mechanism gap becomes moot; if the separate-row model is intended, then Masjid is under-modelled and the sweep mechanism genuinely must work. **I am not choosing** — both docs are hard-locked and this is exactly the spec call that belongs to you. But choosing between "all-match mode" and "stop using `transitionRelated`" without knowing which representation the archetype is *for* would settle the mechanism while leaving the real inconsistency in place.

**The `{id}` half of this is now HALF-MEASURED, live, 2026-09-12 — and the measured half came back GOOD, which narrows the remaining work considerably.** I had a Data Portability walkthrough verify it as a side-measurement rather than reasoning about it. `export-protected-redaction`'s `preview-protected-redaction` transition carries a cross-type `createInstance` effect whose `fields` include `sourceInstanceId: "{id}"`. Driving it live produced `community_data_portability_export-notification_qniobzc2oaqc` holding `sourceInstanceId = community_data_portability_export-protected-redaction_o45jkphkf10j` — **exactly the parent instance's id.** I read that row out of Postgres myself. So **`{id}` interpolation in an effect's `fields` demonstrably works**, and the asymmetry this row describes is real rather than suspected: the same token behaves correctly in effect interpolation and (per the root-cause reading) as an ordinary data-field lookup inside a `transitionRelated` **filter**. **Why that matters for the decision you are being asked to make:** the filter-side fix is now "make the filter resolver receive the instance id the way effect interpolation already does", a consistency repair against a working reference implementation — not a new mechanism to design. That is a materially smaller and safer change than this row originally implied, and it is *independent* of the larger first-match-versus-all-match question above, which still needs your call. **Still unmeasured:** the filter path itself, which needs a live `transitionRelated` whose filter contains `{id}` — worth taking as a side-measurement on a future walkthrough the same way this one was, rather than as its own dispatch.
- [ ] `blocked` — `deriveInstanceRoles` picks the FIRST `actorEqualsField` guard — array order is not a business-party selector — [detail](TODO-open-detail.md#row-248)
- [ ] `blocked` — A payment-service stub needs a service-backed transition binding specified first — grammar gap, stops and asks — [detail](TODO-open-detail.md#row-251)
- [ ] `blocked` — Field-label humanization disagrees with itself across 4 sites in `part18`/`part26`/`part28` — [detail](TODO-open-detail.md#row-256)
- [ ] `blocked` — Garden Club: a silent borrower strands the owner's own listing, and there is no coordinator override — [detail](TODO-open-detail.md#row-259)
- [ ] `blocked` — `queryInstances` has no date-window parameter, so every calendar tab pages the whole instance set — [detail](TODO-open-detail.md#row-275)

### 3. Ready to ticket

- [x] `new-ticket` — DONE 2026-09-12 (`a8017525`): the four affected Masjid tables now carry a note after each block naming the five `wf_*` rows as test-harness ids. Deliberately NOT in the first column, which is a parsed contract — the note says so, since annotating it directly broke the asset conformance test once. Verified: bar still 72, both doc-parsing tests pass — [detail](TODO-open-detail.md#row-158)
- [x] `new-ticket` — CLOSED 2026-09-12 as not-actionable: the forward fix already landed — `make_b25_brief.sh` requires every future run to record the driven package's `skillVersion` AND `sha256`. The 11 pre-2026-09-08 manifests are unidentifiable **by construction** and cannot be retrofitted with an identity they never recorded; treat any of them as evidence only while its package asset is unchanged — [detail](TODO-open-detail.md#row-160)
- [ ] `new-ticket` — pass-42 blockers — `c14` vision review is ~97% scaffold (7 of 204 screens carry real evidence) — [detail](TODO-open-detail.md#row-161)
- [x] `new-ticket` — DONE 2026-09-12 (`f26dac6e`): typed `fanId`/`fanId[]` pickers in all four builders, backed by a real member directory, all four spellings including the nullable forms. Verified by me: app shell **414 passed / 2 skipped** (was 408+2), analyze clean, zero removed assertions, and the regression test proven discriminating by neutralising the fix — [detail](TODO-open-detail.md#row-269)
  - [ ] `blocked` — ↳ NOT closed by the above, as scoped: a directory of real members still contains a moderator-only fan, and no schema field declares role eligibility. Needs a grammar/product decision on how a `fanId` field states which roles are eligible — [detail](TODO-open-detail.md#row-210)
  - [x] `new-ticket` — ↳ CLOSED by the above: role ids can no longer reach a `fanId[]` field. The contaminated Chess row is preserved and visibly flagged rather than silently repaired — [detail](TODO-open-detail.md#row-268)
- [ ] `new-ticket` — Backlog of deferred polish findings (ISO-8601 humanization, `maxLines` truncation, contradictory chip pairs) — [detail](TODO-open-detail.md#row-297)
- [ ] `new-ticket` — Membership-assignment call needs a fan actor, which a client-credentials token structurally cannot supply — header fixed, identity question open — [detail](TODO-open-detail.md#row-353)

### 4. Live validation — the production bar

- [ ] `new-ticket` — **Campaign RESUMED and running 2026-09-12: the bar moved 10 → 15 of 72**, the first movement since the standard was set. Proven this session: Camera Club `photo-walk-rsvp` (after fixing the defect that blocked it) and `gear-loan-request` (full six-transition loan lifecycle), Garden Club `garden-event-rsvp`, Cedar `hoa-facility-reservation` — the last confirming the `calendar.*` grant fix end to end, since it is the row that used to 403 for both HOA roles. Cedar `hoa-architectural-request` was added 2026-09-12 (created live, driven to terminal `withdrawn`, verified independently in Postgres as `fan-hoa-member-1`). **42 rows still need only a walkthrough; 14 need both halves.** **Next, and it is the single biggest lever left: see [B25-data-portability-run-plan.md](B25-data-portability-run-plan.md).** All 8 remaining Data Portability rows are created by ONE role (`portability-owner`) from ONE tab (`admin`), 7 of them drivable end to end by that role alone, and `export-transfer-rollback` + `export-transfer-verification` can be banked in a SINGLE run because rollback has no create FAB and is only reachable from a transfer card. That cluster alone would move the bar 15 to 23. Pre-flight (all three seeding layers, the token fanId claim, published definitions, tab visibility) is verified in that plan -- do not re-litigate it. Drive selection from `Tools/code/list_b25_walkthrough_queue.py`, which names them — `check_b25_status.sh` reports only how many. **Two selection traps cost time here and are worth avoiding:** picking `chess-club-night` off the package rather than the queue got a real live write for a row that needs BOTH halves, so the live-write count rose and the bar did not; and a binding on `tabId: "messages"` will not render at all (AP-14, the shell ignores community bindings there), so check the tab before briefing a row — [detail](TODO-open-detail.md#row-209)
- [ ] `new-ticket` — Six fakes still back 53 distinct platform APIs while the cluster runs five real services — retiring them is unscoped — [detail](TODO-open-detail.md#row-213)
- [ ] `needs-verification` — Prove reminders live end to end — no reminder-bearing instance exists anywhere in the cluster to observe against — [detail](TODO-open-detail.md#row-245)
- [ ] `needs-live-validation` — §6 step 7 product-doc reconciliation gate — confirmed closed for Cedar Commons HOA only, 9 communities unconfirmed — [detail](TODO-open-detail.md#row-295)

### 5. Unscoped milestones

- [ ] `new-ticket` — Platform phases A, A.1, B, C, D, E, G.4 remain — [detail](TODO-open-detail.md#row-215)
- [ ] `new-ticket` — Outstanding Skill dispatches: DataPortability (6 prefill), AdFree (4 orphan), Camera (rejected), Book Club (held) — [detail](TODO-open-detail.md#row-216)
- [ ] `new-milestone` — Document ACL — `sharedWith` is one flat `fanId` list, so group sharing is impossible. Sequenced AFTER Phase F — [detail](TODO-open-detail.md#row-239)
- [ ] `new-milestone` — Spec-version compatibility hardening — Layer 4 (`requiresCapabilities`) needs a spec decision — [detail](TODO-open-detail.md#row-240)
- [ ] `new-milestone` — Archetype-owned bookkeeping unimplemented, so `grant_access`/`share` can never populate the field a grant reads — [detail](TODO-open-detail.md#row-246)
- [ ] `needs-skill-dispatch` — Book Club regeneration is HELD by user decision — dispatching now would bake in a known loss permanently — [detail](TODO-open-detail.md#row-247)
- [ ] `needs-skill-dispatch` — Ad-Free product-doc enrichment needs redoing under hard rule 14b — the shipped doc is fine; only the rejected dispatch output was not — [detail](TODO-open-detail.md#row-292)
- [ ] `new-milestone` — §7 step 8 — legacy Dart catalog + bespoke-widget removal, now unblocked and far more tractable than 'unscoped' suggests — [detail](TODO-open-detail.md#row-296)

### 6. Needs the Root Cause Agent

- [ ] `needs-debug-agent` — CJM.16 Messages-tab fix, landing with Phase F rather than as its own dispatch — [detail](TODO-open-detail.md#row-288)

### 7. Delegated — detail lives in the owning tracker

- [ ] `new-ticket` — Never derive the community key from the group id — underscored vs hyphenated — [detail](TODO-open-detail.md#row-138)
- [ ] `new-ticket` — Staleness sweep of the migrated blocks — 54 unadjudicated checkboxes, 12 adjudicated so far — [detail](TODO-open-detail.md#row-195)
- [ ] `new-ticket` — The `chmod 444` guard on community JSON is not durable — [detail](TODO-open-detail.md#row-230)

## Closed on evidence, 2026-09-12

Re-measured rather than carried forward, in the sweep that restructured this file:

- [x] Six "dead" queue transitions in Book Club, Camera and Garden — CLOSED 2026-09-12 on this row's own finding — its text already reads `NOT dead; that framing was a premise error, corrected 2026-09-08`. All six transitions route correctly through the shared `EquipmentLoanArchetypeCard`.
- [x] App Access policy endpoints had no caller authorization — Superseded and CLOSED 2026-09-12 by P1 (`loom-backend f134935`), deployed as `app-access 0.3.11` and verified live: a plain fan token on `installCommunityPackage` now returns `403 provisioning_principal_required`. The exposure this row describes is closed in the running cluster, not just in source.
- [x] Masjid over-grant root cause — the platform had no notion of role KIND — Superseded and CLOSED 2026-09-12 by P3 (`loom-backend 1b9b320`, `role_kind` + `RoleGrantCompatibilityValidator`) and P5 (`4668822`, actor-attributed policy audit), both deployed in `app-access 0.3.11`. The platform now has the notion of role KIND whose absence this row identified as the root cause.
- [x] Remote fixture upload for `hoa-member-document` instances — CLOSED 2026-09-12 on this row's own finding — its text already reads `OBSOLETE AS FRAMED, 2026-09-10`: the fixture step it describes cannot be performed because package seed data populates only the local engine, which is the 2026-09-07 decision, not a defect.

## Closed

Moved verbatim to [TODO-closed.md](TODO-closed.md) — 87 rows, kept rather than deleted. The
template's rule is that a closed row's rollup line leaves this index once closed; it had never
been applied, which is why the open queue was buried.
