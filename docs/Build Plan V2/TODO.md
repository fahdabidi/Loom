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

## Open

### WHERE THIS ACTUALLY STANDS — 2026-09-01

Written because "BACKEND SERVICES BUILD-OUT — COMPLETE" is true and reads as far more finished than
the project is. The backend was one workstream.

**71 open items in the four §8 queues** — ACWS 24, Build 39, Community JSON 7, TabId 1 — plus **93**
checkboxes still open inside the migrated §9 bodies. The body count is falling as the staleness sweep
works through it (121 → 93 so far); a checkbox in a §9 block is a record of what was true the day it
was written, not current state.

#### Proven live, and re-verified rather than recalled

| | |
| --- | --- |
| B1–B8 | built, deployed, load-bearing, exercised against the running stack |
| Android sign-in | **works end to end on `emulator-5554`** — Keycloak page, token stored, gate error changed to one only an authenticated caller reaches |
| Packages | 10/10 shipped carry `experience.notifications`; all on `specVersion: 4` |
| Accounts | 35 across 11 communities, every one through `requestGroupMembership` → `decideGroupMembership` |
| Security | **the whole confirmed privilege-escalation class closed and proven live** — group endpoints (0.3.5) and app-level setAppAccess/revokeAppAccess (0.3.6), each verified by re-running the exact exploit: member 403, was 200 |
| Resilience | Postgres-restart recovery proven by deleting `postgres-0` — same pod, 24s |
| Suites | all five re-measured 2026-09-01: judges **485**, app shell **371** (+2), engine **316** (+1 credentialed), workflow service **148** (+1 credentialed), demo **160** |

#### The one thing blocking the critical path

**The deployed authorization state was hand-assembled and diverges from the generated tooling in two
dimensions**, so no vocabulary-driven provisioning operation is safe to run:

- *Grants*: the 11 community admin roles hold five `community.*` governance permissions each, by the
  2026-08-30 hand-grant. The deriver has no path to reproduce them.
- *Catalog*: the live `permission` table has 127 ids (21 hand-added stopgaps incl. `community.*`), and
  no `calendar.*` — even after `0.3.6` bundles the 111-id vocabulary, because deploying the image does
  not write the catalog.

`install` and `replacePermissionCatalog` are both vocabulary-driven, so running either to add
`calendar.*` would drop the hand-added `community.*` and delete undeclared roles. The decision is a
governance-model choice, detailed in `Access Control` §8: either `community.*` gets its own generated
source the catalog build includes, or the provisioning ops become merge-safe against permissions they
do not own.

Everything downstream waits on it: `calendar.create` cannot reach a role until it is in the catalog,
so instance creation stays refused (`403`), which blocks the reminder-chain proof, the capture
campaign, and the production bar.

#### Decisions waiting on the user

- **role deletion** — A declare admin in packages / B reserved naming / C provenance tracking
- **fan-passport identity** — decided (seeding mints the passport first); the **re-keying** step is
  what still needs a go-ahead, since it rewrites memberships
- **B25 table unit** — are Masjid's 3 persona rows B25 rows at all, and are Data Portability's 9
  identical rows nine proofs or one?
- **`community.surface.navigation.*` vs `community.manage_settings`** — the fourth spec decision,
  which gates Phase E

#### Measurement, and why the production bar number is not yet meaningful

`c14` and `c16` are both **diagnosed**: `c16` was never an app defect — all ten findings were
evidence-shape problems, and the judge now says so. `c14`'s artifact is ~97% scaffold. The denominator
is wrong too: 12 of 79 rows name a workflow their package does not ship, and **9 of those 12 are not
community workflows at all**. Repairing measurement precedes measuring.

### BACKEND SERVICES BUILD-OUT — complete 2026-08-31

B1–B8 are built, deployed and load-bearing, verified end-to-end against the running stack.
**The full record moved to `Access Control and Workflow Service Tracker` §9** on 2026-08-31 — what
was built, what was measured, the four-state vocabulary, the group-to-community mapping, and the
corrections made along the way. Checkbox status was re-verified against the repository during that
move rather than carried over on trust.

Still open, as rows in that tracker's **§8**:

- [x] server-initiated push: **DECIDED 2026-09-05 — stays a placeholder, not now.** Scoped: the spec already answers the design questions (provider-agnostic contract, must report per-device failure not swallow it, dead-token pruning distinct from transient failure); the one remaining call was which provider(s) to integrate (FCM alone vs. FCM+APNs), which needs real infrastructure (a Firebase project or Apple certs, credentials in the cluster). User declined to commit to that now — the three open-app delivery paths (in-app inbox, local device notification, reminder sweep) already work. Revisit by asking the same provider question when this is prioritized again. → ACWS §8
- [x] delivery failures: **CLOSED `46193031`** — `LoomReminderSweeper.sweep()` now logs both failure paths (debugPrint, the existing convention) and exposes `deliveryFailureCount`, with zero change to its never-throw/retry-on-failure resilience contract. Verified: my own re-run of app_shell +376 ~2 All tests passed. A separate catch in local_workflow_engine_api.dart:1549 was confirmed dead code (fires only for a workflowType no shipped community declares) and correctly left alone; `_hydrateSourceFields`'s own silent catch is a different, data-hydration concern, reported but not fixed here. → ACWS §8
- [x] change feed: **CLOSED, was stale — it IS deployed.** Proven by live request against `loom-workflow-service:1.0.3` (deployed == manifest, no drift): `GET /v1/communities/{id}/changes` returns **401 authentication_required** (route exists, wants auth) while a nonexistent collection under the identical valid `X-Loom-Correlation-Id` returns **404 route_not_found** — a working control, so the 401 means present, not missing. Note the first attempt used `/v1/changes` and 404d; the real shape is `/v1/communities/{id}/changes` (`_matchesCollection`, workflow_service.dart:255). Verified 2026-09-04. → ACWS §8
- [ ] `app_group.external_resource_*` NULL for all 24 groups → ACWS §8 `needs-spec-decision`
- [ ] never derive the community key from the group id — underscored vs hyphenated → ACWS §8
- [x] fan → community: **CLOSED, was stale** — `GET /v1/fans/{fanId}/communities` (`listFanCommunities`) ships in the app-access spec and the app adopted it (part37/part39/part40). Verified 2026-09-04. → ACWS §8

### Cross-cutting — the record moved to its owning trackers, 2026-08-31

Thirty-six dated entries from 2026-08-29 → 2026-08-31 were migrated out of this file, each to the
tracker that owns the work. Checkbox status was not carried over on trust. Where to find them:

| What | Now lives in |
|---|---|
| Backend build-out as it happened — B4 minting, checksums, change feed, B5 proofs; the security escalation and its fix; the two-hour outage and the resilience defect; admin-role provisioning | `Access Control and Workflow Service Tracker` §9 |
| Production bar and device history — the membership blocker, the device runs, the legacy-fallback render, the Android sign-in dead end, and the three ways the B25 measurement is unreliable | `Build Tracker` §9 |
| Package regeneration — Book Club, the stale marker, B8 across eleven communities, the absent-block default | `Community JSON Migration Tracker` §9 |

Open items from those entries are rows in the same trackers' **§8** queues, not here:

- [x] community isolation: **CLOSED, was stale** — no longer a bare WHERE clause; `FORCE ROW LEVEL SECURITY` + the `community_isolation` policy ship in postgres_connection.dart and were proven enforcing live 2026-09-03. Verified 2026-09-04. → ACWS §8
- [x] `1bc87122` idempotency unified — item_queue.join was the last hand-rolled copy; document/export_bundle already used runIdempotent. Verified against live PG with BOTH credential sets (153 +1 skipped); admin-only skipped the one test covering the changed class. → ACWS §8
- [ ] ten of eleven communities still have no members → Build Tracker §8
- [x] authenticated walkthrough — **sign-in PROVEN on device**, and the follow-on 401 fixed: `JWT_ISSUER` now matches the advertised host, app-access returns 200 with real membership → Build Tracker §8
- [ ] the B25 denominator overstates: 12 rows — 3 renames, 9 not community workflows at all → Build Tracker §8
- [ ] walkthrough evidence records no package identity, so staleness is undetectable → Build Tracker §8
- [ ] pass-42 blockers — `c14` vision review is ~97% scaffold (7 of 204 screens carry real evidence); **`c16` judge FIXED `ab8720f0`** — it now reports zero capability failures and names all ten as evidence-shape problems, so what remains is regenerating the artifact in the documented schema → Build Tracker §8

### 2026-08-30 — this file stopped following its own header — RESOLVED 2026-08-31

The header has said "this is an index, not a memory" since it was written. By 2026-08-30 the file was
**2,633 lines** of narrative — findings, corrections, dated session entries — and the per-tracker §8
queues it points at had gone quiet, because detail was being written here instead of there.

**Resolved by the A1 migration on 2026-08-31** (`3054337c`, `4fe6230f`, `326d3a6b`): the record moved
to the tracker that owns each piece of work, open items became §8 rows, and this file went back to
being an index — 2,633 lines to under 300.

Two things made the drift easy to miss. **`Build Tracker` had no §8 at all**, so the one tracker that
owns the production bar had nowhere to put an open item and everything about it landed here by
default. And a narrative entry is genuinely useful when written — the cost only appears later, when
the same finding is unfindable because it sits in a chronological stream instead of beside the work
it concerns.

### PRODUCTION READINESS, the bar, and the platform phases — moved 2026-08-31

The production-readiness measurement, the 2026-08-25 resequencing decision, the bar's definition and
the platform-phase state moved to **`Build Tracker` §9**. The writer-declaration pass and the
tab-audience work moved to **`Community JSON Migration Tracker` §10**; the in-memory-engine finding
to **`Access Control and Workflow Service Tracker` §9**.

**Those blocks arrived carrying 54 open checkboxes that were not re-adjudicated during the move**, and
several are already known false — the checksum service *was* proven live on 2026-08-30, the five rows
"blocked on a missing owner/admin identity" were unblocked when eleven admin roles were created, and
the "7 rows" unshippable count was superseded by the 12-row finding. A staleness sweep is owed and is
itself a `needs-verification` row in each tracker's §8. Do not treat a checkbox inside a §9/§10 block
as current state.

The live threads, one line each:

- [ ] staleness sweep of the migrated blocks — 54 unadjudicated checkboxes → all three trackers §8
- [ ] `permissions.md` §4/§6 contradict, §4 hard-locked; blocks the `.create` vocabulary → Build §8
- [ ] the live cluster holds hand-made state that exists nowhere in git → Build §8
- [ ] pre-GA credential debt: plaintext test creds, cleartext JWT, 35 accounts sharing one password → Build §8
- [ ] six fakes back 53 platform APIs; retiring `LocalAuthApi` means *building* one → Build §8
- [ ] Garden walkthrough stall, reproducing on both hosts → Build §8
- [ ] platform phases A, A.1, B, C, D, E, G.4 → Build §8
- [ ] outstanding Skill dispatches: DataPortability, AdFree, Camera (rejected), Book Club (held), Garden (not installed) → CJM §8
- [ ] six dead queue transitions → CJM §8
- [ ] the `chmod 444` guard is not durable → CJM §8
- [ ] `WorkflowDatabase.memory()` is the app's only engine database → ACWS §8

### Spec decisions that block other work

The two `needs-spec-decision` items that were listed here — `deliver_reminder`'s 2-of-4 applicability
and the two permission vocabularies — are stated once under **Blocked on the user** above, with the
other two. A decision recorded in more than one place is what inflated the backlog to 17.

- [ ] `new-milestone` — **Document ACL**: `sharedWith` is one flat `fanId` list, so there is exactly one permission level ("shared" = "can read") and sharing with a group is impossible. Sequenced AFTER Phase F — see [Document ACL Spec Proposal.md](Document%20ACL%20Spec%20Proposal.md)
- [ ] `new-milestone` — **Spec-version compatibility hardening**: Layers 1–3 land with the v4-only cut; Layer 4 (packages declaring `requiresCapabilities`) needs a spec decision — see [Spec Version Compatibility.md](Spec%20Version%20Compatibility.md)

### Known defects and debt

- [ ] `new-milestone` — **NEXT UP (user-queued 2026-08-27): the export checksum service.** 10 markers across **8 workflows in 6 communities** — Book Club, Cedar, Chess, Data Portability (x3), Garden, Youth Soccer — all declaring `checksum`, plus Cedar's `checksumStatus` and Garden's `checksumVerified`, so verification is in scope not just generation. `migration-export-api.openapi.yaml` has 4 create-job operations and **no checksum concept**, so spec-first: write the contract, then the service. Same shape as the document library — effects are data-only, so the service writes the field rather than an effect calling out. Payment stays deferred and is only **4** markers, all of which already have an honest offline path; the 3 previously bucketed with them are id-generation wearing a payment label
- [ ] `needs-verification` — **deploy `loom-workflow-service:0.4.0` and prove reminders live**; the running 0.3.0 predates the `dueNotifications` endpoint, so `set_reminder` still delivers nothing against the cluster — build in flight 2026-08-27
- [ ] `new-milestone` — **archetype-owned bookkeeping is unimplemented**, so `grant_access`/`share` cannot populate the shared-with field a grant reads; blocks Cedar's `explicitReaderFanIds` ever being filled — see [document-library.md §6](../references/archetypes/document-library.md)
- [ ] `new-ticket` — **Cedar's seeded documents carry no file**: JSON cannot hold bytes, so the document surface renders nothing to open until a post-install fixture uploads through the API — delivery step, not a package one (`729c802f`)
- [x] `new-ticket` — **CLOSED 2026-09-05.** Masjid Nur's calendar tab was a list, not a calendar: `mosque-volunteer-signup` bound a `formEntry` "summary" onto the calendar tab alongside `mosque-event-rsvp`'s `event-rsvp` binding, violating [calendar.md §2](../references/archetypes/calendar.md)'s "exactly one tab-native archetype per tab" rule. Fixed via a surgical Skill dispatch (removed the one renderBinding), verified via real validator (0 errors, same 9 pre-existing warnings) and a diff showing exactly 7 lines removed. Broke one demo-app test that had encoded the bug as expected behavior (`b46_mosque_engine_migration_test.dart`, fixed via the implementation agent). ux_judges/app_shell/demo-app all reconfirmed clean (`68e4fee8`).
- [ ] `new-ticket` — **Cedar declares `request_access`/`withdraw_access_request` with no granting counterpart**; filling it needs archetype bookkeeping above, so left open rather than filled with an inert transition (`bfb1fabd` records the same trap)
- [x] `new-ticket` — **STALE, already fixed — CLOSED 2026-09-05.** This row described a real gap (`_updateInstanceFields` evaluated role guards against an empty role map, refusing every caller) but the gap was closed 2026-08-30, before this row was ever removed: `441d0d22` extracts and calls `_resolveRolesForRequest` before the guard, with test coverage distinguishing member-with-role (200), member-without-role (403), non-member-holding-role (403), and app-access-unreachable (503). Independently re-verified today, not just recalled: ran `postgres_guard_refusal_integration_test.dart` directly with both Postgres credential sets — all 5 tests pass, 0 skipped. Full workflow_service suite with both credentials: 153 passed / 1 skipped / 0 failed, matching the documented baseline exactly.
- [ ] `new-ticket` — **`SurfaceQuery.dateWindowStart/End` is declared and never plumbed**: the service builds `SurfaceQuery(sort:)` only and the calendar pages every instance and filters on device — a community with years of events transfers all of them to draw one month
- [ ] `new-ticket` — **the engine's `workflowType == 'notification'` delivery branch is dead and mistimed**; no package uses that type and it fires at creation, ignoring `dueAt`. Left in place with the finding recorded at the site; deleting it is separate work (`bf1acf6d`)
- [x] `CLOSED ON MEASUREMENT 2026-08-29` — **recurrence has no scheduled top-up.** Measured, and it is
  not a defect: **series cannot be infinite.** The validator requires `recurrenceRule.count`
  (`missing_recurrence_count`) and bounds it to 1-366 (`invalid_recurrence_count`), so the grammar
  cannot express an open-ended series. The three packages that use the effect -- Garden, Book Club,
  Tabletop -- all pass `count` as a **required transition input**, so an organiser says "weekly, N
  times" and N instances are generated at once. Nothing needs topping up. The original note read:
  "`generateRecurringInstances` runs only when a transition is applied, so a series never extends
  itself. Whether that is a defect depends on whether series are finite — unmeasured." The answer is
  finite, by enforcement rather than by convention.

- [ ] `new-ticket` — **`b25_capture_workflow_screenshots.dart` uninstalls the demo app on teardown**, so the next capture run finds nothing installed. `flutter drive` rebuilds and reinstalls, so a run recovers on its own — but any check of `adb shell pm list packages` between runs will correctly report the app absent, which reads like a broken environment. Either stop uninstalling or say so in the capture output
- [ ] `needs-debug-agent` — CJM.16 Messages-tab fix, landing with Phase F rather than as its own dispatch — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-ticket` — Cedar Commons HOA fast-follow: dead-end document access-request flow, overclaimed traceability row — see [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md)
- [ ] `new-ticket` — eager response-row fan-out (D2) is specified but **no code implements it**; land it with Phase A, or revisit D4's validator exemption — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-ticket` — **30** hardcoded `tabId == '…'` comparisons across **16** files (re-measured 2026-08-24; the previously recorded "73 across 8" no longer matches the tree), including a validator rule keyed on the literal `calendar` — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `needs-skill-dispatch` — **Ad-Free product doc enrichment, redo under hard rule 14b.** The 2026-08-24 convergence dispatch returned a materially better doc (24 → 54 named interactions) that also rewrote the B25 header to five columns, which makes the judge parse **zero** rows for that community. The enrichment is worth keeping; the table shape is not negotiable
- [ ] `needs-verification` — D3 ratchet: promote `orphaned_response_rows` warning→error at Phase F closeout — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `needs-verification` — `visibleTo` dropped in favour of the existing `LoomWorkflowState.readGuard`; its guarantee still needs to land as a validator rule — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `needs-live-validation` — §6 step 7 product-doc reconciliation gate: confirmed closed only for Cedar Commons HOA, unconfirmed for the other 9 — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `new-milestone` — §7 step 8: legacy Dart catalog + bespoke-widget removal, now unblocked but not yet scoped into tickets — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `new-ticket` — backlog of deferred polish findings (ISO-8601 date humanization, `maxLines` truncation, contradictory chip pairs) across multiple communities, not yet consolidated — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `new-ticket` — **rotate three exposed secrets before GA**: Google client secret, Facebook app secret, DeepSeek API key. Deferred by user decision until production-ready, which makes it a release blocker rather than a backlog item

## Untracked / ad hoc

Items not tied to a formal tracker doc — the fallback location when a `call_*.sh` dispatch ran without
`DISPATCH_TRACKER_FILE` set. Empty right now.

## Recently closed

- [x] `new-milestone` — **the reminder service**, the half of `set_reminder` that never existed (`bf1acf6d`, spec `b6d5f24a`). `RemoteWorkflowEngineApi.dueNotifications` threw, naming its own cause, and nothing called it on either engine; six workflows let a member ask to be reminded and nothing ever reminded them. `GET /v1/communities/{id}/notifications/due?asOf=` scopes by the engine's read model rather than a recipient filter of its own, because the local engine returns the whole community's due instances — right on one member's device, a leak over HTTP. `asOf` is the caller's instant so an offline device gets its backlog. `LoomReminderSweeper` delivers once, retries failures, never throws, and is wired to community open.
- [x] `new-milestone` — **`calendar` is a real archetype, placeable in any tab** (`b6ce5515`). `event-rsvp` minus `respond`/`withdraw_response`/`join_waitlist` and minus every attendance array. Placement was already archetype-driven — the tab id is only a join key — so a community can call the tab `prayer-times` and get a month grid. Touched nine registries; `permissions.md` §4 had to move first because the spec-sync test compares the two by set equality. One injectivity assertion removed rather than updated, with the rationale in the test.
- [x] `new-milestone` — **document library, end to end**: spec (`2ba56eac`, corrected `0f871c7c`), endpoints + 8 infrastructure-free tests (`01957d62`), app client (`add0b384`), upload wired into the card surface (`fc04103f`), Cedar regenerated to store files (`729c802f`), validator rules in the authoring validator (`6e38c315`). Access derives from the workflow — no new authorization model.
- [x] `new-ticket` — **`membersOnly` meant creator-only server-side** (`3bbda3f9`). The service never installed an `ActiveMembershipLookup`, so `_isActiveMember` fell through to false and every member saw only their own instances. The app shell had always installed one, so the same workflow answered differently on device and server.
- [x] `new-ticket` — **a state `readGuard` was ignored unless `visibility.default` was `guarded`** (`dc78f7f1`). Three shipped workflows declared guards that never ran: Cedar's board-only documents were readable by every member, Book Club's drafts by anyone at all. The filtering shortcut needed the same correction or the fix would have been inert for exactly the worst case.
- [x] `new-milestone` — **`sharingGrantable` implemented** (`ca5f617e`), declared since the contracts were written and read by nothing. A grant is an alternative to a transition's guard, never a clause in it, because guards are AND-only. The grantable set comes from the contract so no package can add `delete` to it.
- [x] `new-ticket` — **Youth Soccer's waiver library called a URL paste an upload** (`bfb1fabd`), which after the document API meant it granted file-storage authority for a paste. The Skill fixed it from a brief carrying no document instructions at all.
- [x] `new-ticket` — **Skill taught what my briefs were carrying** (`a358b536`, `e079b9e4`): where a brief and the fetched package disagree the package wins; an action legal for its family is not a reason to declare it; document libraries decide stored-vs-linked from the product doc; revise a product doc, never replace it. Proven by re-running the same dispatch against a brief stripped to 21 lines of identifiers — byte-identical package.
- [x] `needs-spec-decision` — **Calendar's hardcoded `send-reminder` transition id** — closed on measurement 2026-08-27: the literal is gone from the app shell (only a copy-catalog label key remains), fixed 2026-08-20 per `permissions.md`'s own note and never struck here.

- [x] `needs-debug-agent` — **CJM.18 fixed and verified 2026-08-24** (`cd40d07f`). `_authApiForCommunity` cached resolver closures written `(_) =>` that discarded their own `communityExtensionId` and closed over whichever community was current. Both now honour the argument, the experience resolves fresh per call, and re-hydration drops the cached API. Verified red-then-green: against unpatched code both new tests fail with `Role "community-b-role" is not declared by community "ext_cjm18_community_b"` — the same shape as the original field report, so the regression test reproduces the real defect. Demo 153 → 155.
- [x] `new-ticket` — **capture integrity, both defects** (`3c6496cb`). A second bare-`adb` call site at `b25_capture_workflow_screenshots.dart:532` (the earlier fix covered only the guard file, because the ticket scoped the audit to it); and byte-identical frames counted as fresh evidence. Duplicate frames now fail the workflow with `screenshotStatus: failed-duplicate-frame` and are excluded from the count, and the detector explicitly refuses to guess whether identical bytes mean an unchanged screen or a bad write. The adb half was **proven in situ** with adb off PATH — unit tests passing had not been enough the first time. Judges 430 → 432.
- [x] `new-ticket` — **one source of role truth** (`b820cf9f`). Eight of ten communities had catalog roleIds disagreeing with their shipped `roles[]`. The fallback is kept because it is genuinely reached pre-install, but synced for all 10, with 6 dead ids deleted and 2 live ones repointed across 8 test files. A parity gate now compares each fallback set against the package's parsed `roles[]`; verified red by reintroducing Soccer's bare ids. Two things established first and worth keeping: `actorIdentities` is **derived** from `roles[]`, not a JSON key, so packages must never declare one (hard rule 13 — that would be authoring a user); and the walkthrough reads the package, not the catalog, so this was stale duplication rather than a live wrong-identity bug. Demo 155 → 156.
- [x] `needs-spec-decision` — **`owner` reserved as a standard platform role** (`1d74a97c`), ratified by the user and specified in `docs/references/reference/identity-types.md` §2a: the person who sets the community up and approves who is allowed in, named `<prefix>-owner`, exactly one per community. Admission authority belongs to App Access and must never be encoded in package JSON. There was no standard role vocabulary in the spec before this.

- [x] `new-ticket` — **Phase F's fixture half is done**, verified 2026-08-24: all 11 packages declare `specVersion: 4`, zero legacy triple fields, `pendingMigration` is empty (emptied 2026-08-19/20), and `missing_visibility_fields` findings across the corpus are **0**. The entry recording "32 expected findings until Phase F backfills" no longer describes the tree.
- [x] `new-ticket` — **All 11 shipped packages validate clean through the validator API**, now gated by `shipped_corpus_validation_test.dart`. Ad-Free, Book Club and Soccer were regenerated through the Skill on 2026-08-24 to close 4 `invalid_visibility_field_type` errors that rules added after authoring had never been re-run against.
- [x] `needs-debug-agent` — app-shell test failures (last recorded `+236 -4`, and separately "3 of 7 target failures remain") — closed on measurement 2026-08-24: **271 passed / 0 failed**, with the total up from 248, so nothing was deleted to get there.
- [x] `new-milestone` — demo app never migrated to specVersion 4 and never in the verification loop (last recorded 56 passed / 73 failed) — closed on measurement 2026-08-24: **153 passed / 0 failed**.
- [x] `new-ticket` — 7 `$viewer == '<roleId>'` comparisons that can never be true — closed on measurement 2026-08-24: **zero** remain across all 11 packages.
- [x] `new-ticket` — Dart never enforces a tab's `requiredPermission` (`enforceRequiredPermission` defaulted to **false**) — closed: it now defaults to **true** (`part11_shell_models.dart:608`).
- [x] `needs-skill-dispatch` — 10 communities declare `requiredPermission` on no tab — **obsolete**: Phase G removed `requiredPermission` from the grammar, and **0** corpus files reference it.
- [x] `needs-skill-dispatch` — Tabletop Club regeneration reverted over `formula` + `required: true` on `queueLength` — closed 2026-08-24: the shipped file carries the formula without `required`, validates at 0 errors, and Tabletop is a reference example rather than one of the ten B25 product communities.
- [x] `new-ticket` — 2 pre-existing failures surfaced during the VM migration — both closed on measurement 2026-08-24: `loom_api_contracts` analyzes clean, and `v3_milestone_phasee_purchase_proposal_test` passes inside the green app-shell suite.
- [x] `new-ticket` — **Skill channel drift**: `chatgpt-upload` was missing hard rules 14/14a entirely, so runs on that channel were authorised to ship packages never compared against their product doc. Ported, and gated by `skill_channel_parity_test.dart` (verified red on removal).
- [x] `new-ticket` — **ChatGPT bundle rot**: 7 mirrored files stale against `docs/references`, including `04-validation.md` 114 lines behind and `16-spec-version.json`. Refreshed via SKILL.md's own recipe, gated by `chatgpt_bundle_mirror_test.dart`.
- [x] `new-ticket` — **Worked example taught retired vocabulary** under a specVersion 4 header (46 errors). Regenerated through the Skill: 0 errors, teaching comments preserved.
- [x] `new-ticket` — **`data/` partially tracked despite `.gitignore`**: 2 dispatch scripts were committed before the ignore, so `git reset --hard` kept reverting them to DeepSeek and only some agents lost their GPT-5.6 profile. Untracked; the adoption kit is the single source.
- [x] `new-ticket` — `_fileSha256`'s Windows `certutil` fallback was unreachable (`Process.runSync` throws on a missing binary). Fixed; judges suite 427/1 → 428/0 on Windows.
- [x] `new-ticket` — Milestone 1 (registry + `table`/`documentLibrary`/`searchAiAnswer`/`exportWizard` widgets) — all 5 sub-tickets done, closed 2026-08-12. See [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md).
- [x] `needs-skill-dispatch` — Milestone 1.5 (Skill-dispatched JSON authoring, 7 communities) — all 7 done, closed 2026-08-12. See [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md).
- [x] `blocked` — WSL2 dispatch pipeline unreliable (vsock exhaustion, zombie wslhost) — closed 2026-08-12, migrated to a VirtualBox VM and verified end to end. See [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md).
- [x] `needs-skill-dispatch` — Milestone 2 (retire archetype-pending `NEEDS IMPLEMENTATION` comments) — closed 2026-08-13, all 7 communities via narrow surgical-edit Skill dispatches. See [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md).
