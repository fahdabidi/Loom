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

### WHERE THIS ACTUALLY STANDS — 2026-08-31

Written because "BACKEND SERVICES BUILD-OUT — COMPLETE" is true and reads as far more finished than
the project is. **161 items open, 105 closed.** The backend was one workstream.

#### Done and verified live

| | |
| --- | --- |
| B1–B8 | built, deployed, load-bearing; exercised against the running stack |
| Packages | 11/11 on `specVersion: 4`, all regenerated today, each diffed and validated with a control |
| Accounts | 35 across 11 communities, every one through `requestGroupMembership` → `decideGroupMembership` |
| Security | privilege escalation closed (`403 fan_identity_mismatch`), verified live |
| Resilience | Postgres-restart recovery proven by deleting `postgres-0`: same pod, `restarts=0`, 24s |
| Tooling | build context 6.885 GB → 917.9 MB; APK buildable on the VM; spec-parity check in both repos |
| Device | `emulator-5554` runs code built at `c969a991` |

#### The production bar is 3 of 79, and **both numbers are unreliable**

- **Denominator overstates.** 12 rows name workflows their package does not ship. The reachability
  sweep also only checks that a row's workflow and role *exist*, never that the role can *act* — so
  the true unprovable count is **≥ 12** and is discoverable only by running walkthroughs.
- **Numerator is unverifiable.** The 3 proven Camera Club rows carry no package identity and classify
  as `unknown` under the provenance model shipped today.
- **The last judge pass failed.** `b25-v4-pass-42`: judge status `fail`, 16/18 criteria, **2 blocking
  criterion failures** — and an **empty findings table**, so what failed was not recorded. Its own
  next action says to remediate, rebuild, recapture and rerun. That never happened.

#### Proposed order, and why

**1. Repair the ability to measure, before measuring.** Three things make the current numbers
meaningless, and all are cheap relative to a walkthrough campaign:

- the 12 rows that name non-existent workflows — correct or strike them (`needs-skill-dispatch`)
- pass-42's 2 blocking failures with no findings recorded — establish what actually failed, or rerun
  to regenerate them
- re-prove the 3 Camera Club rows so they carry package identity, or accept them as `unknown`
  deliberately

**2. Then the walkthrough campaign.** Start with the five rows the account seeding unblocked, because
they are the ones whose blocker we removed and understand. Rebuild the APK before every capture — a
build went stale within two hours today.

**3. In parallel, the work that does not need a device:** 59 `new-ticket`, 19 `needs-verification`.
Several "verification" items are stale claims rather than real work — three were closed today by
checking rather than building.

**4. Larger phases** (17 `new-milestone`) — Phase A/A.1 bookkeeping and response-row fan-out, C auth
broker, D deploy, E access authority, G.4 Ad-Free revert, the export checksum service. These are
features, not cleanup, and want sequencing decisions.

#### Blocked on the user

**13 `needs-decision` + 4 `needs-spec-decision`.** These gate other work and cannot be resolved by
building. They should be triaged as a batch rather than discovered one at a time mid-task.


#### Decision backlog triaged 2026-08-31 — 12 of 13 were already answered

Pulled the `needs-decision` list to run through with the user and found most of it stale. Closing
with what resolved each, rather than asking questions that already have answers:

| Item | Resolved by |
| --- | --- |
| who creates community membership | 35 accounts seeded through `requestGroupMembership` → `decideGroupMembership` |
| Android interactive login unimplemented | **built** — `7a69f845` |
| pick the platform to unblock | user chose Android; login built, APK installs, app runs |
| the fix creates a bootstrap problem | **retracted** — `setGroupMembership` never required an existing admin |
| who holds `admin` for each community | eleven `<prefix>-admin` roles + eleven admin accounts |
| who holds `admin` | same |
| which fan id holds `admin` | same |
| who holds `admin` (step 2) | same — this question was recorded **four times** in four places |
| background sync policy | all four policies shipped, member-chosen — `c969a991` |
| OpenAPI twin parity | parity script in both repos + rules — `95192515`, `0561007` |
| the stray app-level `admin` role | deleted through the `deleteRole` endpoint built for it |
| canonical group spelling | **not a decision** — `LOOM_COMMUNITY_GROUP_IDS` already determines it (hyphenated) |

Two things worth keeping from this:

- **The same question was open four times** in four locations, each phrased slightly differently. A
  decision recorded wherever it was encountered, rather than once, inflates the backlog and makes the
  remaining count meaningless.
- **One was never a decision at all.** Canonical group spelling was already determined by deployed
  configuration; asking the user would have been asking them to choose something the system had
  chosen. That is the third time this session I framed a determined fact as a question.

**Genuinely open: 1 `needs-decision` + 4 `needs-spec-decision`.** Not 17.

### BACKEND SERVICES BUILD-OUT — complete 2026-08-31

B1–B8 are built, deployed and load-bearing, verified end-to-end against the running stack.
**The full record moved to `Access Control and Workflow Service Tracker` §9** on 2026-08-31 — what
was built, what was measured, the four-state vocabulary, the group-to-community mapping, and the
corrections made along the way. Checkbox status was re-verified against the repository during that
move rather than carried over on trust.

Still open, as rows in that tracker's **§8**:

- [ ] server-initiated push is a placeholder pinned `0.0.0-placeholder`; nothing implements it → ACWS §8
- [ ] delivery failures are invisible — best-effort swallows every platform error → ACWS §8
- [ ] the change feed is built but **not deployed**; ships with the next workflow-service image → ACWS §8
- [ ] `app_group.external_resource_*` NULL for all 24 groups → ACWS §8 `needs-spec-decision`
- [ ] never derive the community key from the group id — underscored vs hyphenated → ACWS §8
- [ ] fan → community takes three hops; no single call answers it → ACWS §8

### Cross-cutting — the record moved to its owning trackers, 2026-08-31

Thirty-six dated entries from 2026-08-29 → 2026-08-31 were migrated out of this file, each to the
tracker that owns the work. Checkbox status was not carried over on trust. Where to find them:

| What | Now lives in |
|---|---|
| Backend build-out as it happened — B4 minting, checksums, change feed, B5 proofs; the security escalation and its fix; the two-hour outage and the resilience defect; admin-role provisioning | `Access Control and Workflow Service Tracker` §9 |
| Production bar and device history — the membership blocker, the device runs, the legacy-fallback render, the Android sign-in dead end, and the three ways the B25 measurement is unreliable | `Build Tracker` §9 |
| Package regeneration — Book Club, the stale marker, B8 across eleven communities, the absent-block default | `Community JSON Migration Tracker` §9 |

Open items from those entries are rows in the same trackers' **§8** queues, not here:

- [ ] community isolation is a `WHERE community_id = ?` clause nothing enforces → ACWS §8
- [ ] idempotency is reimplemented in three repositories that will diverge silently → ACWS §8
- [ ] ten of eleven communities still have no members → Build Tracker §8
- [ ] Android cannot obtain a bearer token, so no authenticated walkthrough is possible → Build Tracker §8
- [ ] the B25 denominator overstates: 12 rows name workflows their package does not ship → Build Tracker §8
- [ ] walkthrough evidence records no package identity, so staleness is undetectable → Build Tracker §8
- [ ] pass-42's two blockers — `c14` judge never run, `c16` capability gap → Build Tracker §8

### 2026-08-30 — this file no longer follows its own header, and has not for a week

Its header says: **"This is an index, not a memory. One line per open item... Never write item
detail directly here"** — detail belongs in the owning tracker's `## 8. Live TODO / Next Steps
Queue`.

The file is **1260 lines**. Roughly 830 were added on 2026-08-29/30 by me, as multi-paragraph
findings. **But the drift predates that**: dated detail sections run back through 08-28, 08-27 and
08-25, so the convention had already lapsed before this effort started, and today's entries match
existing practice rather than departing from it.

Noting it rather than fixing it, deliberately. Relocating only the newest sections would leave the
file *less* internally consistent than it is now, and mass-restructuring 1260 lines of accumulated
context is a large, hard-to-review change with real potential to lose the reasoning these entries
exist to carry.

- [ ] `needs-decision` — **either move the detail into
  `Access Control and Workflow Service Tracker.md` §8 and restore this file to a one-line index, or
  amend the header to describe what this file has actually become.** A stated convention that the
  document visibly ignores is worse than either, because a reader cannot tell which parts to trust —
  the same failure as a tracker whose checkboxes contradict its own header, which cost real time here
  on 2026-08-29.


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

- [ ] `needs-spec-decision` — `deliver_reminder` applies cleanly to 2 of 4 candidates; Chess and Soccer expose a contradiction inside `permissions.md` itself and are deliberately UNAPPLIED — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `needs-spec-decision` — two permission vocabularies that do not meet: `community.surface.navigation.*` (app-shell only, decided by string suffix) vs `permissions.md`'s `community.manage_settings` (App Access). Prerequisite for Phase E — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Document ACL**: `sharedWith` is one flat `fanId` list, so there is exactly one permission level ("shared" = "can read") and sharing with a group is impossible. Sequenced AFTER Phase F — see [Document ACL Spec Proposal.md](Document%20ACL%20Spec%20Proposal.md)
- [ ] `new-milestone` — **Spec-version compatibility hardening**: Layers 1–3 land with the v4-only cut; Layer 4 (packages declaring `requiresCapabilities`) needs a spec decision — see [Spec Version Compatibility.md](Spec%20Version%20Compatibility.md)

### Known defects and debt

- [ ] `new-milestone` — **NEXT UP (user-queued 2026-08-27): the export checksum service.** 10 markers across **8 workflows in 6 communities** — Book Club, Cedar, Chess, Data Portability (x3), Garden, Youth Soccer — all declaring `checksum`, plus Cedar's `checksumStatus` and Garden's `checksumVerified`, so verification is in scope not just generation. `migration-export-api.openapi.yaml` has 4 create-job operations and **no checksum concept**, so spec-first: write the contract, then the service. Same shape as the document library — effects are data-only, so the service writes the field rather than an effect calling out. Payment stays deferred and is only **4** markers, all of which already have an honest offline path; the 3 previously bucketed with them are id-generation wearing a payment label
- [ ] `needs-verification` — **deploy `loom-workflow-service:0.4.0` and prove reminders live**; the running 0.3.0 predates the `dueNotifications` endpoint, so `set_reminder` still delivers nothing against the cluster — build in flight 2026-08-27
- [ ] `new-milestone` — **archetype-owned bookkeeping is unimplemented**, so `grant_access`/`share` cannot populate the shared-with field a grant reads; blocks Cedar's `explicitReaderFanIds` ever being filled — see [document-library.md §6](../references/archetypes/document-library.md)
- [ ] `new-ticket` — **Cedar's seeded documents carry no file**: JSON cannot hold bytes, so the document surface renders nothing to open until a post-install fixture uploads through the API — delivery step, not a package one (`729c802f`)
- [ ] `new-ticket` — **Masjid Nur's calendar tab is a list, not a calendar**: `mosque-volunteer-signup` uses `shiftDate`/`shiftTime` on a calendar-rendered tab, and a mixed-archetype tab degrades wholesale — now a documented contract violation, fixable by Skill regeneration — see [calendar.md §2](../references/archetypes/calendar.md)
- [ ] `new-ticket` — **Cedar declares `request_access`/`withdraw_access_request` with no granting counterpart**; filling it needs archetype bookkeeping above, so left open rather than filled with an inert transition (`bfb1fabd` records the same trap)
- [ ] `new-ticket` — **`_updateInstanceFields` resolves no roles**, unlike the four read/execute paths the membership fix covered — separate question, untouched (`3bbda3f9`)
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
