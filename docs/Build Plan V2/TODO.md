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

### BACKEND SERVICES BUILD-OUT — the autonomous queue, in order (armed 2026-08-28)

Each loop tick reports position in THIS list. A service is not "done" until it is built, deployed,
reachable from the app, and a member-visible behaviour depends on it.

**B1. Item queue — deploy and wire. DONE 2026-08-28.** Service built, deployed as `loom-workflow-service:0.5.0`, routes verified live with a negative control, app client and surface wired, and `join_queue`/`leave_queue` exempted from `transition_has_no_observable_effect` because the service now completes them. Six dead buttons are live.
- [x] service built, 12 tests, workflow service 89 → 107
- [x] startup no longer gated on the offer-hold config (`b9df5a35`)
- [x] build `loom-workflow-service:0.5.0` — failed once (I ran `docker image prune` mid-build), rebuilding
- [x] manifest: image tag + `LOOM_QUEUE_OFFER_HOLD_WINDOWS_SECONDS` in `~/loom-backend/deploy/k8s/workflow-service.yaml`. **86400 in it is a flagged guess, not a product decision**
- [x] import image, apply, verify the six routes answer
- [x] app queue client — five operations. **`advance` stays server-side**: without notification delivery nobody can be told their turn came, and shipping it would be a button that silently does nothing
- [x] wire the `equipment-loan` surface: join, leave, position, queue length
- [x] app queue client + surface wiring (`3e5efcb6`) — app shell 320 → 325, resolves by `action` not transition id, UUID correlation ids, unavailable rendered distinctly from not-queued
- **CORRECTED (a note, not a task): the packages do NOT need regenerating.** This entry originally said to regenerate the three communities so the transitions "call the service". They already declare `action: join_queue`/`leave_queue`, and the app resolves the affordance by action and calls the service itself — so the transitions are correct as authored. What was actually needed is a validator exemption: `join_queue`/`leave_queue` join `upload` in `_platformCompletedActions`, because the queue service records membership outside workflow JSON exactly as the Document Library API writes uploaded content. **Regenerating them to append to a `queuedFanIds` instance field would have been actively wrong** — two sources of truth for queue membership, disagreeing the moment anything touched one and not the other

**B2. Notification channels — preference store DEPLOYED, app integration outstanding.**

Status 2026-08-28: fan-passport `0.3.1` is live with the two preference operations. Verified against
the database rather than the rollout: `flyway_schema_history` shows V3 applied,
`notification_preference` and `notification_preference_channel` exist with the right columns, and the
`inbox|push` CHECK constraint is enforced by Postgres and not only by the API.

- [x] spec on fan-passport, both copies byte-identical
- [x] implementation, 31/31 tests
- [x] `platform_default` pseudo-key removed — it existed only because I typed `platformDefault` as
      `CommunityNotificationPreference`, which requires a `communityId` that a platform default does
      not have. A schema demanding an identifier for something with no identity produces a fabricated
      identifier every time
- [x] deployed and migration verified in the live database
- [ ] **app client + settings surface — nothing in the app reads or writes a preference yet.** Deployed
      is not integrated
- [ ] **provider-agnostic push contract**, for the closed-app case. The device path only fires while
      the app runs

**Also true, and easy to lose:** delivery failures are invisible. The delivery service swallows every
platform error by design ("best-effort"), so a failed delivery is indistinguishable from a successful
one. Fine until something depends on delivery having happened — the queue's "you're next" will.

**CORRECTED 2026-08-28 — the original entry overstated this gap.**

My original entry said delivery was "interface only" and that the reminder sweep "has never delivered
to a real recipient". Both were wrong, and wrong the same way: I read names and inferred instead of
reading code.

Already built and working:
- **In-app inbox** — `notificationInbox` is a real archetype with **20 render bindings across 7
  communities**. Its 🟡 GENERIC marking means it renders through the shared card template rather than a
  bespoke widget, not that it is unbuilt.
- **Device notification** — `LocalNotificationDeliveryService` calls
  `FlutterLocalNotificationsPlugin.show()` with a real channel, initialised for Android, iOS, macOS and
  Linux. "Local" means device-local, not fake.
- **The sweep that feeds them** — `part44_reminder_sweeper.dart` already calls
  `dueNotifications({asOf})` and delivers what members scheduled.

Actually missing, and this is the whole of B2:
- [ ] `new-ticket` — **per-member notification preference.** No per-member preference storage exists
  anywhere in the app or services. By user decision it belongs on **fan-passport**, which already owns
  per-fan follows, consent grants and `creator-category-permission-policies` — a `PUT` settings shape
  it can follow. Per fan, per community, choosing among channels that already work. **Both specs must
  change together**: `~/loom-backend/spec/identity/fan-passport-api.openapi.yaml` and
  `~/Loom/docs/API/OpenAPI/identity/fan-passport-api.openapi.yaml` are byte-identical today
- [ ] `new-ticket` — **server-initiated push**, for the closed-app case: the device path only fires
  while the app is running. By user decision, spec it **provider-agnostic** — a swappable interface and
  no vendor, the way `messaging-api.openapi.yaml` marks a boundary without committing
- [ ] `needs-verification` — **delivery failures are currently invisible.** The service swallows every
  platform error by design ("best-effort", so a denied permission never reaches the engine). Correct
  for the engine; it also means a failed delivery is indistinguishable from a successful one, which
  matters once anything depends on delivery having happened

**B3. Per-viewer change feed — DONE 2026-08-29.** Deployed as `loom-workflow-service:0.6.0` and
verified live: the real route answers `400 invalid_correlation_id` where an invented sibling path
answers `404 route_not_found`, then `401` with a valid correlation id. The real-vs-fake comparison
is the proof -- fan-passport answers `401` to routed and unrouted paths alike, so a bare probe of
*that* service would have shown nothing.

`GET /communities/{id}/changes` is implemented in the workflow service (`86f79b0d`), workflow service
107 → 113. It resolves visibility through the engine's existing per-fan path rather than
reimplementing it, and exposes `updatedAt`, which had been stored and maintained on every transition
all along and never returned.

**The endpoint surfaced two holes in its own spec, both by an implementation refusing to build around
them.** Worth recording because both would have shipped as working-looking code:

1. `resyncRequired` was required and nothing was provided to compute it from — the request carried no
   role information and the response was closed. Fixed by an opaque `roleCursor`/`nextRoleCursor` pair.
2. An inclusive timestamp-only cursor **cannot advance** when more instances share a millisecond than
   fit in a page — the client re-requests page one forever. I had reasoned about exactly this collision
   and chose inclusive anyway, having considered only the single-instance case. Fixed by making the
   cursor the pair `(updatedSince, afterInstanceId)` ordered by `(updatedAt, instanceId)`, which is a
   total order needing no new column, writer or migration.

- [x] spec, including the per-viewer semantics and `visibleInstanceIds` for disappearance
- [x] implementation, 8 tests, all five suites green
- [ ] cursor amended to a keyset pair — spec landed `033371c3`, implementation re-dispatched
- [ ] not deployed; it ships with the next workflow-service image

**Superseded 2026-08-29 (kept for the reasoning):**

I wrote that "instances carry no `version` or `updatedAt`". Wrong: `workflow_instances.updated_at`
exists as a BIGINT and is genuinely maintained — the engine writes it on every transition
(`SET current_state = ?, instance_data = ?, updated_at = ?`), and live data confirms it moves
independently of `created_at`. I had read `database.dart`, seen `version` only on definitions, and
generalised.

I also wrote that B3 depends on the group→community mapping gap. It does not.
`RemoteWorkflowEngineApi` is constructed with a `communityId`, so a feed is scoped by its caller and
never has to enumerate a viewer's communities. That blocker belongs to the settings surface alone.

So what actually remains:

- [ ] `new-ticket` — **expose `updatedAt` on the instance in the API response.** It is stored and never
  returned
- [x] `DONE 2026-08-29` — **a changed-since query**, shipped as `GET /communities/{id}/changes`
  rather than as a parameter on `GET /instances`
- [x] `RESOLVED 2026-08-29` — **`updated_at` is a millisecond timestamp, and a cursor wants a total
  order.** Decided: a keyset pair `(updatedAt, instanceId)`, ordered `updated_at ASC, instance_id`,
  with a test that fails against the old timestamp-only cursor (`e969bd3a`). Original note follows.
  **`updated_at` is a millisecond timestamp, and a cursor wants a total order.** Two instances updated in the same millisecond are indistinguishable, so a client resuming
  at that timestamp either repeats or skips. A monotonic per-community sequence would be exact; reusing
  the timestamp is cheaper and occasionally wrong. Worth deciding rather than discovering
- [x] `RESOLVED 2026-08-29` — **the feed must be per-viewer.** Built, deployed in `0.6.0`, resolves
  through the engine's existing per-fan path; disappearance handled by returning the full
  `visibleInstanceIds` set, cursor invalidated by `roleCursor`. Original note follows.
  **the feed must be per-viewer, and that is the hard part.**
  `readVisibleInstance(instanceId, fanId)` resolves visibility per fan, so there is no community-wide
  answer to "what changed". It must report **disappearances** — an instance leaving your visibility is
  an event, not an absence — and invalidate the cursor when the caller's roles change, or a replica is
  not merely stale but wrong

**B4. ID generation — GRAMMAR + SERVICE BUILT 2026-08-29 (`ac01492a`, `a0349863`). Packages not yet
regenerated.**

Decided with the user: a `platformSource` key, and **export/transfer ids only**.

`writableBy: "platform"` said only *that* a service writes a field -- a `checksum` and a `receiptId`
are both `"type": "text?"` with `"writableBy": "platform"` and otherwise identical. `platformSource`
names the mechanism (`checksum` | `opaqueId`). Minting is server-side, once, into a declared empty
field, never rewritten, encoding nothing readable.

**Scope is narrower than the markers suggest, on purpose.** Only `transferId` and `exportReceiptId`
are minted, where a bundle really is produced. `receiptId`, `paymentConfirmationId` and
`settlementId` stay declared-and-unwritten alongside payment, which is deferred: a receipt id for a
payment that never happened is a confirmation number for a transaction that did not occur. An empty
field there is a true statement about the world.

The missing-`platformSource` finding is a **warning, not an error**, because 138 shipped fields
declare `writableBy: "platform"` without one. A validator that fails the corpus it ships with teaches
everyone to ignore it. Promote once regeneration has moved the corpus.

- [x] `DONE 2026-08-29` — all five regenerated through the Skill: Youth Soccer (`4933a3de`),
      Garden (`629b4309`), Cedar (`5e96e434`), DataPortability (`9d84bf88`), Book Club (`6caf719d`).
      Corpus now carries **7 `platformSource: "checksum"` and 6 `"opaqueId"`**, matching the measured
      inventory of 6 export/transfer ids exactly. The "verify Book Club against `c0e0355b^`"
      instruction was **retired, not followed** — see the re-assessment above.
- [x] `DONE` — minting deployed in `0.8.0`, and `0.9.0` now carries it plus the health probes

**B5. Document member state + versioning — DONE 2026-08-29.** Built (`6099d40f`), deployed in
`loom-workflow-service:0.7.0` and verified live by method: POST `/revisions` answers 401 while a fake
sibling answers 404. A GET against `/revisions` also answers 404 and is *correct* -- the route is
POST-only -- so probing with the wrong verb would have produced a false defect report.
Service-assigned `version` (a caller-supplied one is rejected, not ignored), per-member
`read`/`saved`/`acknowledged`, and acknowledgements bound to the version. Workflow service 113 -> 125.

The subtle one, and the one a green test could most easily have faked by deleting rows: a revision
invalidates acknowledgements **without rewriting any record**. Proven -- after a bump the
acknowledgement is still present at `version: 1` with `stale: true`, `currentVersion` reads 2, and a
`currentVersionOnly` query returns empty. Ships in the next image alongside anything else pending.

**B6. Session resume — BUILT 2026-08-29 (`c7ca5900`), not yet mounted in the UI.**
`LoomWorkflowReplica` over `WorkflowDatabase.file()` (which had existed all along and was called
from nowhere), fed by B3's change feed, with a read-only facade. App shell 330 -> 337.

The security property is the **deletion** rule, not the sync. An instance can leave a member's view
without changing -- someone else's transition, or their own role changing -- so it never appears in
an `updatedSince` window. Anything absent from `visibleInstanceIds` is deleted locally; a replica
applying only `changed` would keep rows its owner may no longer read.

Per-fan isolation is enforced by the store, not by convention: a singleton row pins each database
file to one `(fanId, communityId)` pair and a mistaken reuse fails closed. Proven at both layers --
querying Alice's replica as Bob throws, and reopening Alice's file as Bob throws.

Still open: giving it a caller. **Not blocked** -- the app already runs on the backend by default,
so this is a ticket about when to sync and when to read the replica, not an architecture decision.

**P1. PARKED until after production — everything that is a member's own choice.** User decision
2026-08-29: "Lets park everything that is a members choice for the moment. Put this into the tracker
as an item we will get back to after production as a separate effort."

**Parked, and deliberately NOT deleted.** All of it is built, tested and in some cases deployed and
serving. Nothing here is a gap to close before production; it is finished work waiting for a product
moment.

| Thing | State | Where |
|---|---|---|
| Per-member notification preferences | **deployed and serving** | fan-passport `0.3.1`, tables `notification_preference` + `notification_preference_channel` (Flyway `V3`) |
| Preference API | live | `listNotificationPreferences`, `setCommunityNotificationPreference` |
| App client | built, uncalled | `part47_notification_preferences_client.dart` |
| Preference control widget | built, unmounted | `CommunityNotificationPreferenceControl` |
| `source: member \| default` distinction | implemented | distinguishes "chose these values" from "never chose", which the platform default later diverges from |

**Do not delete or roll back the `V3` migration.** It is additive, it costs nothing at rest, and
removing it would destroy the distinction above, which cannot be reconstructed once lost -- a member
who never chose and a member who chose today's default look identical afterwards.

**Do not "finish" this by mounting the control.** It is parked, not unfinished.

**Boundary, stated because it is easy to over-apply.** Parked means a member's *preference* -- a
setting they configure. It does **not** cover per-member workflow records: B5's document
`read`/`saved`/`acknowledged` state stays in scope, because "who acknowledged the current version of
the CC&Rs" is a record with product and legal meaning, not a choice about how the app behaves.

**Consequence for B8:** notification delivery becomes **community configuration only** -- what the
community offers and its default. No per-member overlay is read while this is parked.

**Deferred by user decision, not forgotten:** payment processing, external search/AI answer.

**B8. Notification delivery is community CONFIGURATION, in the package JSON.** User direction
2026-08-29, and it dissolves the settings-screen blocker for the delivery half of B2:

> "If by notification prefs you mean how to deliver notifications which we said was a configuration.
> These should be implemented as JSON configuration settings. It belongs side by side with the
> community `theme` i.e. where we store the communities Fab experience, the color scheme, text sizes
> etc."

`experience` already carries exactly this class of thing -- `theme` (`accent`, `tabThemes`) and
`creatableAction` (`multiActionStyle`, `presentationStyle`, the FAB presentation). Delivery config
sits beside them as `experience.notifications`.

**This does not replace the per-member store, and must not be read as reversing it.** Those are two
different facts:

| Where | What it answers |
|---|---|
| `experience.notifications` (package JSON) | Which channels this community offers, and the default before anyone chooses |
| fan-passport `0.3.1` (deployed) | This member's own deviation from that default |

A community package is identical for every member, so a per-member preference cannot live in it.
The JSON supplies the offered channels and the default; the store records one member's departure
from it. The earlier decision to put per-member preferences on fan-passport stands.

**Scope narrowed 2026-08-29:** community configuration only. The per-member overlay is parked (P1),
so the app reads the community default and stops there.

- [ ] design `experience.notifications` and add it to the grammar docs
- [ ] validator: known keys + a closed channel set
- [ ] regenerate packages through the Skill
- [ ] app reads the community default. **No member overlay** -- that is parked in P1

### Status vocabulary — four states, because "done" was hiding the difference

Measured 2026-08-29 by looking for real call sites, after the labels in my own reports drifted apart:
B2 was written as "mounting blocked" and B3 as "done, deployed" while both were in the **same** state.

| Term | Means |
|---|---|
| **Built** | In `main`, suites green |
| **Deployed** | Answering in the cluster (backend only) |
| **Wired** | An app client exists **and something calls it** |
| **Reachable** | A member can get to it from a surface |

| | Built | Deployed | Wired | Reachable |
|---|---|---|---|---|
| B1 item queue | yes | yes | yes -- `part36` | **yes** |
| B2 notification preferences | yes | yes | no | no |
| B3 change feed | yes | yes | no | no |
| B5 document versioning | yes | yes | client exists, **missing 4 methods** | no |
| B6 replica | yes | n/a | no | no |

`LoomItemQueueClient` and `LoomExportBundleClient` are called from
`part36_engine_native_marketplace_surface.dart`. `NotificationPreferencesClient` and
`LoomWorkflowReplica` are referenced by nothing outside their own part files.

**CORRECTION 2026-08-29 (second, and larger): the app already runs on the backend by default.**

I wrote that the app uses `LocalWorkflowEngineApi` over an in-memory database and that dispatches
were forbidden from changing that seam because switching engines was an unmade architecture
decision. All three parts were wrong.

- `LOOM_ENV` defaults to **`dev`, the real backend**. `apps/loom_communities_demo/lib/main.dart`
  calls `configureEngineNativeCommunityEngineFactoryForProduction(...)` with the remote factory
  whenever the environment resolves. The in-memory engine is an explicit opt-in (`LOOM_ENV=local`),
  tests force it via `debugForceLoomLocalBackend` from `flutter_test_config.dart`, and a typo'd
  `LOOM_ENV` **throws** rather than falling back. `part40_service_environments.dart` says why: "a
  capture that quietly ran against a local engine while appearing to prove the deployed stack is the
  exact failure the backend migration exists to prevent."
- The dispatch instruction "do not change the default engine seam" meant *do not break the local
  path the tests run on*. I turned a test-compatibility constraint into an architectural blocker.
- **`LocalWorkflowEngineApi` is the backend's own engine**, not a client stand-in. The workflow
  service constructs it as `LocalWorkflowEngineApi(db: _database)` over Postgres; "local" means
  in-process. Removing it would delete the live backend implementation.

I found the third only because a case-sensitive grep for `engineNativeCommunityEngineFactory` missed
`configureEngineNativeCommunityEngineFactoryForProduction` and told me nothing called it. **A grep
that returns nothing is not evidence of absence.**

Consequence: **B3 is not blocked on a decision.** The engine already points at the backend. It is
dark only because `LoomWorkflowReplica` has no caller, which is a ticket.

**CORRECTION 2026-08-29: "app dark" is not one condition, and B5 is the cheapest item here, not a
blocked one.** I had recorded B5 as having no client at all. `part42_document_client.dart` exists
with `upload`, `download`, `access` and `delete`, and `LoomDocumentClient` is called from
`part36_engine_native_marketplace_surface.dart` -- members use the document library today. What is
missing is four client methods for B5's new operations plus the surface calls. Purely additive, no
decision required.

B3 is dark for a different reason entirely, and the difference matters more than the shared label:

| | Client | Surface | What it needs |
|---|---|---|---|
| B3 change feed | built, referenced only by its own test | **none -- it is not a screen feature** | A caller: something to decide when to sync and when to read the replica offline |
| B5 document versioning | exists, missing 4 methods | **already live** | Add the methods, call them |

B3 is infrastructure with no owner: nothing decides when to sync. **This is not an engine
question** -- see the engine correction above; the app already targets the backend by default.
Neither B3 nor B5 needs a decision.

**B1 is the only one a member can use.** Do not write "done" for anything that is merely deployed --
a service answering `401` to a probe proves the route exists, not that the product does anything.

**SUPERSEDED 2026-08-29 — this no longer blocks four items.** It read: "One decision blocks four
items. There is no app-level settings or profile screen, so B2, B3, B5 and B6 all have nowhere to
live." Two things dissolved it. Notification delivery is package configuration beside `theme` (B8),
not a settings screen. And B3/B5/B6 were never waiting on chrome -- B5's surface is already live and
B3/B6 need a caller, not a screen. No app-level settings screen is required by anything currently
open.

**B7. DONE 2026-08-29 — publisher built (`21f4adc0`) and 82 definitions published live.**
`bin/publish_workflow_definitions.dart`, dry-run by default, reading the same package assets the app
ships. All 10 communities, 82 workflows; the tool round-trips each community through
`loadDefinitionsForCommunity` after writing, which is the only way to catch the silent failure --
an id that is not exactly `{communityId}_{workflowType}` yields an empty community and no error.

Live state now: **82 definitions across 10 communities**, up from 7 across 1.

**Cedar's rows were not identical to the shipped package.** 6 of its 7 definitions changed hash on
publish; only `hoa-committee-decision` was unchanged. I kept only md5s beforehand, not the original
JSON, so **whether that is semantic drift or serialisation differences is not established** -- do
not repeat this claim in the stronger form. The lesson is to snapshot content, not hashes, before
overwriting anything. The backend now matches the shipped package by construction either way.

**Latent hazard, not introduced here:** both the publisher CLI and the service entrypoint default
`LOOM_POSTGRES_DATABASE` to `loom_app_access`, while definitions live in `loom_workflow_service`.
Production is correct only because the manifest sets it explicitly. A manual CLI run without that
variable would target the wrong database -- and a manual run is exactly what this tool is for.

_Superseded description:_ The services are built; the content is not loaded. Measured against the live cluster
2026-08-29, not inferred:

- `workflow_definitions` holds **7 rows, every one of them Cedar** (`hoa-architectural-request`,
  `-committee-decision`, `-dues-payment`, `-member-document`, `-facility-reservation`,
  `-owner-notification`, `-export-evidence`), all at version 4.
- `workflow_instances` holds **3 rows, all Cedar**, and those are residue from B3's own end-to-end
  test.
- `workflow_documents`, `workflow_item_queue_entries` and `workflow_export_bundles` are **empty**.

So nine of the ten communities exist only as client-side JSON packages and are unknown to the
backend. Every service route answers and every suite is green, which is exactly what makes this
worth writing down: the backend can look finished while the product does nothing, because nothing
has been published into it. A definition-publishing path is the missing piece, and it is a real
item, not a cleanup.

**Correction to my own reporting:** I first recorded `workflow_definitions` as empty. That query
had errored on a column the table does not have, with stderr suppressed -- a failure and a zero
look identical through `2>/dev/null`. The counts above were re-run with errors visible.

### Group-to-community mapping: measured

Confirms the 2026-08-29 entry below and adds the numbers.

- 24 groups, **0** with `external_resource_type` and **0** with `external_resource_id`.
- Most communities carry a duplicate pair of spellings (`...ad-free-community` and
  `...ad_free_community`), and both are empty, so picking one is harmless there.
- **Cedar is the exception and the reason this cannot be derived**:
  `loom_communities_cedar_commons_hoa` has 2 members and `loom_communities_cedar-commons-hoa` has 1.
  Both are real; nothing distinguishes which the workflow community means.
- Test residue is in the same table and will be mistaken for product data by anyone who reads it
  later: two `loom_communities_b3-e2e-*` groups with 1 member each, and
  `loom_communities_verify_tabletop_club`.

### 2026-08-29 — CORRECTED: the mapping exists, and it selects the group holding only the test fan

**My earlier heading here said "nothing authoritatively maps a group to a community". That was
wrong**, and wrong in the direction that wastes the most work: it framed a decision as missing when
it had already been made and deployed. `LOOM_COMMUNITY_GROUP_IDS` is a required env var on
workflow-service, supplied from the `workflow-service-config` secret as `community-group-ids`, and
it maps **all 11 communities**. `community_group_id_resolver.dart` states the rule outright: a
community id and handle cannot be derived from one another, so callers must supply an explicit
mapping. I looked only at `app_group.external_resource_*`, found NULLs, and concluded nothing
existed.

**The live mapping selects the hyphenated Cedar group, and that has a consequence:**

| group | mapped? | members |
|---|---|---|
| `loom_communities_cedar-commons-hoa` | **yes** | `fan-test-alice` |
| `loom_communities_cedar_commons_hoa` | no | `fan_alice`, `fan_bob` |

So the workflow service recognises exactly **one** Cedar member, and it is the end-to-end test fan.
The two seeded members are in the group nothing points at, and are invisible to every per-member
backend feature -- the change feed included. The duplicate spellings are two naming conventions
(hyphenated live/test, underscored seed/demo) that were never reconciled, not an ambiguity.

`community_verify_tabletop_club` is also in the live mapping, so test residue has reached
production config.

The open question is therefore **not** "who owns the mapping write" but "which group is canonical
per community, and who moves the members" -- a smaller and much better-posed question.

#### Superseded framing, kept for the reasoning it contains

Found while trying to mount the notification-preference control, which must show a member their
communities. It blocks more than that: **any** per-member, per-community feature needs this, including
B3's per-viewer change feed.

- [ ] `needs-spec-decision` — **the mapping columns exist and are empty.** `app_group` carries
  `external_resource_type` and `external_resource_id` — exactly the shape needed to point a group at
  its workflow community — and they are **NULL for all 24 groups**. The schema anticipated this and
  nothing populates it. Filling them is probably the smallest correct fix, and it is a decision about
  who owns that write, not a ticket
- [ ] `needs-verification` — **do not derive the community key from the group id.** It looks derivable:
  group `loom_communities_cedar_commons_hoa`, community `community_cedar_commons_hoa`. But both a
  hyphenated and an underscored group exist for the same community and **both have members**, so the
  derivation is right for one and wrong for the other with nothing to distinguish them. This repeats
  the standing rule already in memory: read both identifiers, never derive one from the other
- [ ] `new-ticket` — **fan → community requires three hops today**: `getAppAccess(appId, fanId)` returns
  `roleIds`, a role carries a `groupId`, and a group id embeds a community name by convention rather
  than by contract. The first two hops are real API; the third is string manipulation against data
  that demonstrably has two spellings

### Cross-cutting, found while building the above

- [ ] `new-ticket` — **community isolation is a `WHERE community_id = ?` clause.** Not schema-per-tenant, not row-level security; one missing predicate leaks across communities and nothing structural prevents it. Wants a test that runs every repository query against a two-community fixture
- [ ] `new-ticket` — **idempotency is reimplemented per repository.** `document_repository`, the bundle repository and the queue repository each carry their own `idempotency_key` column and index. Three implementations of one contract will drift; wants one shared table keyed by `(community, route, key)`
- [x] `DECIDED 2026-08-29` — **archetype backends stay in `loom_workflow_service`, with enforced
  module boundaries.** User direction: "We are making all code production ready. So implement this in
  the most robust production ready way. With no shortcuts."

  **Robust points at staying together here, and that is the argument, not convenience.** 15 call
  sites resolve permission by asking the engine "could this caller invoke action X". Splitting leaves
  two options and both are worse: duplicate the authorization logic, giving **two sources of truth
  about who may do what** — divergence there is a security bug, not a wrong answer — or an
  authorization round-trip per request, which adds a failure mode and latency while keeping the
  coupling. One in-process authorization path is the safer system.

  Obligations that come with the decision, so "keep together" is not "leave alone":
  - module boundaries enforced (separate libraries, no cross-imports) so extraction stays mechanical
  - `workflow_service.dart` is **4,484 lines** of an 8,075-line package; decompose per domain
  - revisit only on a real operational difference (bundle downloads saturating the pod), never on
    "documents are a different noun"

### 2026-08-29 — the Book Club "regression" has been overtaken by the backend

`c0e0355b` removed eleven instance fields from Book Club while making an unrelated and correct
change, and was recorded as a shipped regression. Re-examined today against `c0e0355b^`, the removal
splits three ways and **only the first was ever wrong**:

| Removed | Verdict now |
|---|---|
| `reminderAt`, `reminderSentAt` | **Correct** — the documented §15 conversion to a declared `reminder` block removes the formula field |
| `acknowledgedByFanIds`, `savedByFanIds`, `accessRequestedFanIds`, `approvedFanIds` | **Correct now** — per-member document state is owned by the deployed member-state API |
| `queuedFanIds`, `myQueuePosition`, `queueLength`, `currentHolderFanId`, `currentHolderDisplay` | **Correct now** — queue membership, position and custody are owned by the deployed item queue service |

They were a regression **at the time** because they were removed before anything replaced them. B1
and B5 have since shipped the services that own those facts, and B5's own spec names a `fanId[]` of
readers as the anti-pattern it exists to replace: it grows without bound and rides along on every
read of the instance.

**So do not restore them.** Re-adding would create a second, diverging source of truth for who holds
an item and who acknowledged a document. `verify_community_package.py` against `c0e0355b^` reports
`VERIFY FAIL` and will keep doing so; that comparison is now the wrong baseline, and the standing
instruction to "verify Book Club against `c0e0355b^`, not HEAD" is **retired** — HEAD is the correct
baseline for this package again.

Left open, and genuinely unresolved: the shared-library and reading-material surfaces still *declare*
those experiences in the product doc while the JSON no longer carries the fields and the app does not
yet call the services for this community. That is a wiring gap, not a data-loss gap, and it belongs
with B3/B6-style app work rather than with a regeneration.

### 2026-08-29 — one stale marker left, and a small grammar gap behind it

Every remaining `NEEDS IMPLEMENTATION` marker is a correctly deferred service — payment gateway and
payment ids (AdFree 6, Cedar 2, Mosque 2, Youth Soccer 1, Garden 1), and AI answer generation
(Book Club 1, Mosque 1) — **except one.**

Garden's `checksumVerified` carries: *"checksum verification is unavailable with the checksum
service."* **That is no longer true.** `export-bundle-api.openapi.yaml` implements
`verifyExportBundle`, and the spec states plainly that `checksumVerified` gets `false` on generation
and *"only `verifyExportBundle` may set"* it true. The comment describes a gap that has been closed
since 2026-08-27.

- [ ] `needs-spec-decision` — **what `platformSource` does a `checksumVerified` field declare?** The
  closed set is `checksum` and `opaqueId`, and neither fits: the field is a verification **result**,
  a bool set by a different operation on the same service, not a hash value produced at transition
  time. Three options, none obviously right:
  1. reuse `"checksum"`, letting the service infer from the field's `bool` type — implicit typing,
     and the kind of thing that reads as clever until it is wrong
  2. add a third value such as `"checksumVerification"` — explicit, but a grammar addition
  3. leave it `writableBy: "platform"` with no `platformSource` — honest today, and it keeps the
     missing-`platformSource` warning pointing at a field that genuinely has an unnamed writer

  Small, and blocking nothing. Worth deciding rather than guessing, because option 1 is the tempting
  one and the least reversible.

- [ ] `new-ticket` — **delete Garden's stale `checksumVerified` comment** regardless of which option
  wins. A `NEEDS IMPLEMENTATION` note that outlives its implementation is worse than none: the next
  reader trusts it and re-reports a closed gap.

### 2026-08-29 — the deployed definitions were stale, and nothing said so

Publishing happened before the five `platformSource` regenerations, so the backend's stored copies
predated the grammar: **0 of 82 carried `platformSource`**, confirmed against a control query showing
80 carried `writableBy`.

Opaque-id minting was built, tested, deployed in `0.8.0` and correct — and could not have fired for
any community, because the definition the service reads is its own stored copy, not the package in
the repo. Every suite stayed green throughout; there is no test that can see this.

Re-published: 82 upserted, 0 inserts, total still 82, and stored definitions carrying
`platformSource` went 0 → 8. Rule added to CLAUDE.md: **publish after any package change**, and
verify with a control query rather than trusting a zero.

### 2026-08-29 — B4 minting PROVEN LIVE, against the deployed stack

Not a unit test. A real instance, created through the API as an authenticated member, against
`loom-workflow-service:0.9.0` and the re-published definitions:

| Step | Result |
|---|---|
| create `hoa-export-evidence` | `201`, state `draft`, `transferId` **null** |
| apply `preview-export` | state `preview`, `transferId` = `84d40a00-34e5-4f61-9bba-9269962ed540` |
| apply `approve-redaction` | state `redaction-approved`, `transferId` **identical** |
| `checksum` throughout | **null** — it belongs to the export bundle service, not to minting |

So the whole chain holds end to end: grammar -> package -> published definition -> deployed service
-> a minted, opaque, immutable value. The id is a v4 UUID encoding no community, instance, workflow,
fan, counter or timestamp, and the second transition proved the never-rewritten rule rather than
asserting it.

This is the check that would have failed silently an hour earlier, when the deployed definitions
still predated the grammar. A green suite could not have told the difference.

**The probe instance was deleted afterwards** (instances 4 -> 3, definitions untouched at 82).
Leaving it would have been exactly the residue already criticised in the `b3-e2e` groups and
`verify_tabletop_club`: test data that a later reader mistakes for product data.

### PRODUCTION READINESS — measured 2026-08-29, not assumed

- [x] `DONE 2026-08-29` — **liveness and readiness probes**, shipped in `0.9.0` (`c0ce568d`,
  backend `cb7dce7`). `/healthz` returns `{"status":"live"}` and `/readyz` `{"status":"ready"}`,
  both unauthenticated, both registered on the deployment. Liveness deliberately does **not** check
  Postgres: a liveness probe that tracks dependencies makes Kubernetes kill healthy pods during a
  blip, turning a brief outage into a crash loop that outlasts it. Readiness tolerates 300s of cold
  start so it cannot kill the pod mid-migration. Image and probes applied together -- probes against
  `0.8.0`, where `/readyz` was a 404, would have failed readiness permanently. Original note follows.
  **workflow-service has no liveness or readiness probe, and no health endpoint.** `/health`,
  `/healthz`, `/readyz` all `404`. It is the **only** application service without them; app-access,
  fan-passport and keycloak have both, postgres has `pg_isready`. **Four rollouts happened today and
  every one put the pod into service before it had connected to Postgres** — they looked clean only
  because the service wins that race when starting fast. Dispatched.
- [x] `DONE 2026-08-29` — **`LOOM_POSTGRES_DATABASE` default corrected** to `loom_workflow_service`,
  now a single named constant resolved in one place rather than two duplicated literals. Original
  note follows. **`LOOM_POSTGRES_DATABASE` defaults to `loom_app_access`** in both the service entrypoint and
  the publisher CLI, while definitions live in `loom_workflow_service`. Production is correct only
  because the manifest overrides it; a manual publisher run without it hits the wrong database.
  Dispatched with the probes.
- [ ] **Every service runs a single replica**, so any restart is downtime. Separate decision:
  replica counts, PDBs and whether the Dart service is safe to run concurrently.
- [x] `WRONG, CORRECTED 2026-08-29` — **minio has no liveness probe.** It has both, and always did:
  httpGet `/minio/health/live` (15s delay, 20s period) and `/minio/health/ready` (5s/5s). My audit
  queried `livenessProbe.exec.command`, which only matches exec-style probes, so an httpGet probe
  read as absent. Nothing to do.
- [ ] TLS: a JWT crosses the dev link in plaintext, with an Android cleartext exemption that must not
  outlive it. Already on the pre-GA list; restated here because "production ready" now includes it.




### 2026-08-28 — where the writer pass and the archetype backends actually stand

**Writer-declaration pass — 7 of 10 installed.** Book Club (partially, see below), Garden, Mosque,
MemberSocialSpace, Chess (twice: writers, then tab audiences), Cedar, Youth Soccer.

- [ ] `needs-skill-dispatch` — **DataPortability (6 prefill) and AdFree (4 orphan) were never dispatched.** Briefs are built and current at `data/{dataportability,adfreecommunity}_brief.md`
- [ ] `needs-skill-dispatch` — **Camera Club's regeneration was REJECTED, not installed.** It moved the reminder from the per-member `photo-walk-response` row to the parent event and deleted each member's `reminderOffsetHours` — the same collapse that shipped in Book Club and became solved-patterns §19. Camera's own product doc argues the per-member design explicitly at §119–129. Re-dispatch against rule 5f; the output in `~/.codex-skill-authoring-scratch/camera-writers/` is the rejected one, do not install it
- [ ] `needs-skill-dispatch` — **Book Club is knowingly damaged and held.** `c0e0355b` removed its per-member `send-reminder`, the shared-library queue/custody fields and the reading-material access lists; its own doc requires all of them. A verified restore exists at `~/.codex-skill-authoring-scratch/bookclub-restore-r2/` and is deliberately NOT installed — held until the listing/loan backend exists, by user decision, so it can be regenerated once against the new API rather than restoring instance-data fields the backend supersedes. **Verify any Book Club output against `c0e0355b^`, not against HEAD** — HEAD is the damaged state and a diff against it reports the loss as faithfully preserved

**Archetype backends.** The pattern is now three specs and two services.

- [x] `new-milestone` — **export bundles + checksum**: spec, service, app client, all committed and green
- [x] `new-milestone` — **document library gains version and per-member state**: `Document.version` is service-assigned and bumps on revision; `read`/`saved`/`acknowledged` move off instance data; acknowledgement binds to the version so a revision invalidates it without rewriting a record. **Spec only — not built**
- [x] `new-milestone` — **item queue service built** (`b77d0cfd`), 12 tests, workflow service 89 → 101
- [ ] `needs-verification` — **b77d0cfd MUST NOT BE DEPLOYED as-is.** `_queueOfferHoldWindows` throws at line 38 of `main`, before Postgres opens, so the service will not start without `LOOM_QUEUE_OFFER_HOLD_WINDOWS_SECONDS`. Deploying it without the manifest entry takes down documents, exports and notifications too. Fix dispatched: startup tolerates absence, malformed config still fails loudly, `advanceItemQueue` alone refuses per-community
- [ ] `new-ticket` — **the six dead queue transitions are still dead.** `join-queue`/`leave-queue` in Book Club, Camera and Garden have zero effects. The service exists; nothing points at it. Needs a Skill regeneration per community plus an app-shell client, neither started
- [ ] `new-milestone` — **messaging is a boundary, not an implementation.** `messaging-api.openapi.yaml` is `0.0.0-placeholder`; `messaging_feature_not_available` warns on the 8 thread-state transitions that do nothing

**Validator rules added this pass** — four defect classes that were previously invisible to every check: `effect_writable_field_has_no_effect` (60), `prefill_written_field_not_platform` (128), `transition_has_no_observable_effect` (36 measured — my ad-hoc scan said 37; now **30** after `join_queue`/`leave_queue` became platform-completed), `messaging_feature_not_available` (8). Judges 434 → 461.

### 2026-08-28 — the app's engine is in-memory, so nothing survives a restart

- [ ] `new-ticket` — **`WorkflowDatabase.memory()` is the app's only engine database.** Both construction sites use it — `part02_tab_shell.dart:754` and `part25_engine_native_community_store.dart:227` — so in a default local build every loan, RSVP, custody handoff, due date and acknowledgement lives for the life of the process and no longer. Close the app and the community resets to seed data. `WorkflowDatabase.file(path)` exists in `store/database.dart:54` and the app never calls it. **Needs a decision before it is a ticket:** is local persistence wanted (`WorkflowDatabase.file()` on device), or is the local engine deliberately an ephemeral demo shell whose replacement is the remote engine, making local persistence irrelevant? The answer changes the fix entirely
- [ ] `needs-verification` — **in-memory also means per-device, which is the worse half.** Two members hold private copies and never see each other's state, so one borrowing an item does not make it unavailable to another. Lending, queueing and RSVP capacity are all inherently multi-party, so local-only is not a degraded version of those features — it is a different thing that resembles them. Any B25 row proven against a default build proves single-device behaviour only
- [x] `needs-verification` — **corrected my own claim that "the loan lifecycle already works".** It does not. The effects are correctly authored and the state machine is right — that part stands — but authored is not backed. `listing-loan-api.openapi.yaml`'s framing paragraph is rewritten: the queue is *unauthored*, custody and loans are *authored but unbacked*, and both need the service

### 2026-08-28 — a tab you may read but not act on is invisible — CLOSED

- [x] `new-ticket` — **`roleHasPermission` conflated "can act" with "can see". Fixed `3006fa29`.** A role is now admitted if it can act OR if the bound workflow's visibility admits it to read, with read resolution moved into a shared `read_visibility_resolver.dart` in the engine so the tab rail and the instance list cannot disagree. `visibleRoleIds` remains an absolute override. Blast radius was 5 role-tab grants, all in Chess, no removals — predicted independently before reading the agent's report, and the two lists matched
- [x] `new-ticket` — **PREREQUISITE done `2e8541af`:** Chess declares tab audiences (`admin: ["chess-organizer", "chess-owner"]`). Sequencing mattered — shipping the shell fix first would have widened an exposure rather than closing it
- [x] `needs-verification` — **demo suite green at 160/160**, first time since Chess declared the tabs its doc requires
- [ ] `new-ticket` — **SECURITY-ADJACENT, found incidentally and now fixed, but worth a corpus check: Chess's `admin` tab was visible to members.** The demo test asserted it — `chess-member` persona, `community-tab-admin` `findsOneWidget` — and that assertion was *correct about the old behaviour*. With no `visibleRoleIds` declared, a member holding any transition on any admin-tab workflow reached the whole tab. The other nine communities all declared audiences and were unaffected, so the exposure was Chess-only. **The open item is the general one:** nothing fails a build when a community declares an `admin`-ish tab with no `visibleRoleIds`. Rule 5e and solved-patterns §18 tell the Skill to declare them, but a validator rule would catch a package that does not — consider `tab_without_declared_audience` as a warning


- [ ] `needs-verification` — **my corpus scan of this defect over-counted twice and is not evidence.** It first said 8 by not following `responseTable` into response workflows, which the real derivation does — that produced false hits on Camera and Garden calendars, where members obviously do RSVP. Refined to 6, still wrong, because it ignored `visibleRoleIds`: AdFree's `admin` hidden from a member is correct behaviour, not a defect. Only the Chess `rankings` case is proven, and it was proven by rendering the UI rather than by reading JSON. Re-measure with the real derivation before quoting any number

### 2026-08-27 — the writer-declaration pass, and what it opened up

Landed today, all pushed and green (judges 440, engine 312, app shell 308, workflow service 75):

- [x] `new-milestone` — **`writableBy` gained `platform`, and `effect` stopped meaning two things.** `effect` had been covering both "a JSON effect writes this" and "something outside the package fills this in", so a field nothing wrote was indistinguishable from one the platform wrote. `InstanceDataField` gained `isMemberWritable`/`isMachineWritten`; six call sites now ask the question they mean. Documented in `field-types.md`, `workflow-grammar.md`, `05-validation.md` and the Skill's instructions
- [x] `new-milestone` — **two validator rules that make writer defects checkable.** `effect_writable_field_has_no_effect` (60 findings, was 64) and `prefill_written_field_not_platform` (128 findings). Both warnings, deliberately: the packages did not break, the grammar learned to tell things apart. All 10 packages remain `pass` with **zero errors**. Promote to errors once the corpus has moved
- [x] `needs-skill-dispatch` — **Book Club regenerated**: checksum, transferId and the AI digest answer now say `platform`. Four orphan findings → zero. Verified by my own validator run plus a field-by-field diff, not the agent's report
- [x] `new-milestone` — **solved-patterns §15 and §16**, the reminder conversion and the prefill writer, each with the plausible-wrong JSON beside the correct JSON. Written after a prose-only rule produced a destructive reading

Open, in order:

- [ ] `needs-skill-dispatch` — **regenerate the remaining 8 communities for writer declarations.** Cedar (16 prefill + 6 orphan), Chess (18+6), Mosque (29+7), Youth Soccer (14+4), Garden (13+12), MemberSocialSpace (22+17), CameraClub (9+4), AdFree (0+4), DataPortability (6+0). Briefs are built at `data/<community>_brief.md` with identifiers re-derived from the shipped package, not from notes. **Book Club needs one more pass too** — its `ownerFanId` is `formEntry` and should be `platform` (its single remaining prefill finding)
- [ ] `needs-verification` — **Garden Club is regenerated but NOT installed.** Run 1 deleted `reminderAt` *and* `reminderOffsetHours`, removing a capability the product doc promises; run 2, against the corrected instructions, declared the `reminder` block correctly and kept the offset. Re-dispatch once more so the prefill fields land as `platform` in the same pass, then install
- [ ] `new-ticket` — **the `chmod 444` anti-hand-editing guard is not durable.** All eleven packages are 444 again as of 2026-08-27 (AdFreeCommunity and ChessClub had drifted to 664), but git does not track that permission bit, so a fresh clone gets them writable and the guard silently disappears. It is a local speed bump, not an enforced rule — the actual enforcement is the standing instruction in CLAUDE.md. If it should be real, it needs something the repo carries: a test that fails when a community `*.jsonc` changes without a corresponding Skill dispatch record, or a committed pre-commit hook plus a documented install step. Worth deciding rather than leaving a guard that looks stronger than it is
- [ ] `new-milestone` — **the export checksum service** (user-queued 2026-08-27, still next after the writer pass): 10 markers across 8 workflows in 6 communities. Spec-first — `migration-export-api` has no checksum concept, and nothing produces an export *bundle* for one to hash
- [ ] `needs-verification` — **`dueNotifications` has never been proven live.** `loom-workflow-service:0.4.0` is deployed with the endpoint; no community is provisioned into the service with a reminder-bearing instance, so the sweep has never returned a real row

### RESEQUENCED 2026-08-25 — backend migration comes BEFORE the production bar

**User decision.** The live walkthrough and UX judge now run only **after** the app is fully migrated
to the real backends. Every B25 row proven so far was proven against `LocalWorkflowEngineApi`
in-process; switching the app to remote authority afterwards would change the thing those rows were
proven against, so proving them first is wasted work.

Order: **bring k3s up → verify the deployed services → wire the app to the real backends → retire the
fakes in that path → THEN capture and judge.**

- [x] `new-milestone` — **1. Cluster up and verified 2026-08-25. Phases C and D are DONE, not "specified".** `sudo systemctl start k3s` was the entire gap. All five services returned `1/1`: app-access, fan-passport, keycloak, postgres, workflow-service, deployed 6–12 days ago. **Proven end to end**, not inferred: a real fan JWT from Keycloak's `loom-test-client` carrying `fanId: fan-test-alice`, validated by the workflow service, authorised through App Access, reaching Postgres — `GET /v1/communities/{id}/instances` returns `HTTP 200 {"items":[],"pageInfo":{...}}` for camera/chess/ad-off. The service also correctly rejects a missing `X-Loom-Correlation-Id` with `400 invalid_correlation_id`, so its contract is enforced, not permissive
- [x] `new-milestone` — **1c. BLOCKS STEP 2: the deployed workflow service cannot pass any `allowedRoleIds` guard.** Root-caused 2026-08-25, report at [Evidence/backend/publish-guard-root-cause.md](Evidence/backend/publish-guard-root-cause.md). The service authenticates a `fanId` but never resolves and registers that fan's real community role before role-guarded engine calls. Verified directly, not taken on report: `WorkflowRequestIdentity` carries only `fanId` (`identity.dart:11`), and `workflow_service.dart:27` defines `_unresolvedRoleId = 'loom-role-resolution-pending'` — a sentinel that cannot match any package role. The apply-transition route registers no role at all. `AppAccessDecisionClient` returns only a boolean while App Access **already exposes** the answer as `EffectivePermissions.roleIds`; it simply is not plumbed through. **Wire this BEFORE step 2** — otherwise the app gets pointed at a service where no guarded transition can ever succeed, and it would surface much later looking like a product bug. Note the service is `app/packages/core/loom_workflow_service` in THIS repo, not in `loom-backend` **CLOSED 2026-08-25 in `56dd4bce`.** Fixed as specified: one shared resolver at all three sites, `resolveRoleIds` against the deployed `effective-permissions` endpoint, and an EMPTY role set registered on every failure path so a cached engine cannot authorize a later request after a failed resolution. Verified independently rather than from the agent report — the diff removes zero assertions, all three test files are purely additive, and engine went 281 -> 284 passed, exactly the three required tests. App shell held at 273.
- [x] `new-milestone` — **1d. BLOCKS STEP 2 AND 1b: the deployed service's community-to-group map is empty, so it cannot create any instance at all.** Read live from the `workflow-service-config` secret 2026-08-25: `community-group-ids` is literally `{}`. `MapCommunityGroupIdResolver.resolveGroupId` therefore returns null for every community, and `workflow_service.dart:398-415` turns that into a **503 `authorization_service_unavailable` before App Access is ever consulted**. This is the concrete reason every live community holds `"items":[]`, and why 1b could not be run — not missing test data, but a service that cannot create. App Access has exactly **one real community group provisioned** (`loom_communities_cedar_commons_hoa`) plus two throwaway `b3-e2e-*` test groups; the other nine communities have no group at all. **CLOSED 2026-08-26.** All 11 communities installed via `POST /v1/apps/{appId}/community-installations` (`"failures": []`); the map was written from the **server-returned** groupIds — handle-derived and hyphenated, e.g. `loom_communities_cedar-commons-hoa`, NOT the community id — then the deployment was RESTARTED so it re-reads `LOOM_COMMUNITY_GROUP_IDS`, which a secret edit alone does not do to a running pod
- [x] `new-milestone` — **1e. BLOCKS STEP 2: App Access role ids and package role ids are different id spaces, so fixing 1c alone would still deny every guard.** Measured live against the deployed App Access: it holds `cedar_commons_hoa_admin` and `cedar_commons_hoa_member`, while Cedar's shipped package guards name `hoa-board` and `hoa-member`. `board` vs `admin` is not a naming convention, so no normalisation rule can bridge it. **The chosen fix is to provision App Access with the package `roleId` verbatim**, which was checked before being chosen: role ids across all 11 shipped packages contain **zero duplicates**, so package ids are already globally unique and App Access can adopt them as-is with no translation layer to drift. Derive provisioning from the shipped packages — the same script that fills 1d's mapping — rather than hand-creating groups. Had 1c landed alone, roles would have resolved correctly and every guard would still have failed, with a different wrong value. **CLOSED 2026-08-26.** Live roles now carry package-verbatim ids with permissions derived by App Access itself: `hoa-board` 34, `hoa-member` 20, Book Club 57, Soccer 46, Tabletop 37. Chain proven end to end — granting `hoa-board` to `fan-test-alice` moved effective-permissions from `roleIds:[] permissionIds:[]` to `roleIds:['hoa-board'] permissionIds:34`. Note the fix was NOT the client-side provisioner this row anticipated; App Access derives it server-side from submitted inputs (see 1j)
- [x] `needs-verification` — **1f. The engine can hold only ONE role per fan.** `_roleIdByFanId` is a `Map<String,String>` (`local_workflow_engine_api.dart:159`) and `evaluateGuard` compares a single `roleId`, but `EffectivePermissions.roleIds` is a list and a Cedar board member is also a homeowner. Registering resolved roles without widening this would silently drop all but one and deny legitimate actions. Folded into the 1c dispatch as Part 1: `setRolesForFan` with any-match guard semantics, replacing rather than accumulating so a revoked role stops passing **CLOSED 2026-08-25 in `56dd4bce`** as Part 1. `setRolesForFan` replaces the whole set and stores a defensive unmodifiable copy; `evaluateGuard` passes when ANY held role matches, and `.any()` on an empty set is false, so an empty set still fails closed.
- [x] `needs-skill-dispatch` — **1g. Four workflows never say who may create them — a spec gap, not a code gap.** Provisioning needs a `.create` permission per workflow and the packages never state creation authority directly, so the rule was measured across all 95 workflows in all 11 packages 2026-08-25 rather than inferred from one: **84** grant it implicitly (a role-guarded transition leaves `initialState`, and whoever may act on a fresh instance is whoever may create it), **7** need no create permission at all (nothing but a `createInstance` effect produces them — the engine creates them server-side mid-transition, so no App Access create check ever runs), and **4 are genuinely unstated**: CameraClub `critique-submission`, GardenClub `plant-exchange-submission`, MasjidNur `mosque-donation-payment` and `mosque-care-request`. A person creates each of those four, but no package says who may. Provisioning grants all declared roles for them as a stopgap marked `"creationAuthority": "unstated"` so it cannot be mistaken for a decision. **Needs a spec decision first, then a Skill dispatch** — community JSON is authored only by the Skill. Worth noting `critique-submission` is one of the three Camera Club rows already counted as proven: the local engine never consulted App Access, so creation authority was never asked for, which is exactly how this stayed invisible **RETRACTED 2026-08-25 — this finding was wrong.** Packages DO declare creation authority: `permissions.md` step 6 is "For each `create` action's `byRoleIds`, add the archetype's `create` permission", and every shipped package declares `byRoleIds` (2-11 each, 70 corpus-wide) including all four workflows named above. The claim came from measuring transition guards instead of create actions. Note the sweep behind it WAS validated across all 11 packages and all 95 workflows — breadth did not save it, because every reading looked at the same wrong field. Validating a sweep against many cases does not validate its premise; only the spec does. No Skill dispatch needed
- [ ] `new-milestone` — **1h. BLOCKS STEP 2: the App Access permission catalog holds none of the `.create` ids the workflow service enforces.** Found by applying the plan for real 2026-08-25, not by inspection. Groups applied cleanly (**11 created**, Cedar matched rather than duplicated — idempotency held under a live run), then the first role POST returned `400 unknown_permission_id`: "All permission ids must already exist in the app catalog". Measured: catalog **69**, plan needs **65**, overlap only **31**, so **34 are missing** — and those 34 include **every `.create` id** (`payment_checkout.create`, `document_library.create`, `equipment_loan.create`, `export_wizard.create`, `approval_queue_item.create`, `notification_inbox.create`, `search_ai_answer.create`, `status_timeline.create`, `table.create`). `workflow_service.dart:385-415` gates creation on exactly `<prefix>.create`, so **creation could never have been authorised even once roles existed**. Same shape as 1e one layer down — two independently-authored vocabularies (the catalog is `payment_checkout.pay`/`.view`/`.refund`, authored 2026-08-13 apart from the packages) — and resolved the same way, by extending the store to hold what the packages need. The 38 catalog entries the plan never uses are left untouched. Fix dispatched: permissions phase before groups and roles, plus surfacing the HTTP response body, which the applier was discarding and which is why this needed a live probe to diagnose **SUPERSEDED 2026-08-25 by 1j.** The catalog is not writable the way this assumed: `/v1/apps/{appId}/permissions` is GET and PUT only (PUT replaces the WHOLE catalog), and the deployed service answers POST with a 500. More importantly the whole approach was wrong — see 1j
- [ ] `needs-verification` — **1i. Only 55% of transitions declare an `action`, and two packages declare none.** Measured across all 11 packages 2026-08-25 (611 transitions, 337 with an `action`): AdFreeCommunity **0 of 53**, MemberSocialSpace **0 of 27**, ChessClub 26%, MasjidNur 34%, Soccer 44%, Cedar 54%, up to DataPortability at 100%. No functional impact today because the workflow service enforces only `<prefix>.create` and never a per-transition permission — recorded because it is a live trap: if enforcement is ever extended to transitions, those two communities have no derivable permissions at all and would fail closed on every action, reading as a product bug rather than a missing field. Also the reason `ad-off-member` derives a single permission, which looked like a deriver bug and is not
- [x] `new-milestone` — **1j. CLOSES 1d AND 1e THE RIGHT WAY: provision via App Access's own `POST /v1/apps/{appId}/community-installations`, not a client-side reimplementation.** `docs/references/reference/permissions.md` states where the derivation runs: "In the **App Access service**... **Not in the client, and not in the authoring toolchain.**" That endpoint exists and is implemented (`AppAccessController.installCommunityPackage`); one call per community creates the group, registers the roles, derives the permissions and grants them. The caller submits only derivation inputs — `roles[{roleId,label}]` and per workflow `{workflowType, cardSurfaceFamily, createRoleIds, transitions[{transitionId, action, tone, isTerminal, allowedRoleIds}]}` — and gets back `{groupId, rolesRegistered, removedRoleIds, permissionsGranted, rolesWithNoPermissions, findings}`, 422 when findings are non-empty. `groupId` from each result is what fills `LOOM_COMMUNITY_GROUP_IDS`, closing 1d; package-verbatim `roleId`s close 1e. **The lesson worth keeping**: the applier failed three times, each diagnosed correctly and each fix locally reasonable, before I asked whether the work belonged on the other side of the service boundary — the spec had said so all along, in a file already in the repo. When a component keeps hitting walls a service-side API would not have, check the boundary before writing the next fix. Rework dispatched **CLOSED 2026-08-26** — all 11 installed, no failures
- [ ] `needs-verification` — **1k. The deployed permission catalog is out of sync with the generated vocabulary, and is deliberately being left alone.** `docs/references/generated/permissions-vocabulary.json` is authoritative at **97** ids, GENERATED from `archetype_resolver.dart` by `loom_ux_judges/bin/generate_permissions_vocabulary.dart` so the permissions.md rules "exist in exactly one place", and consumed by both the Dart validator and the Java installer. The deployed catalog holds **69**: 26 not in the vocabulary, and **54 vocabulary ids missing**. The backend's own copy of the vocabulary differs from the Loom repo's by exactly one id (`event_rsvp.deliver_reminder`), so a stale file is not the cause — the catalog was seeded from something older than either. Not touched, for a concrete reason: the only write is `PUT` = replace-whole-catalog, so a partial write silently deletes the 26 entries the packages do not use. Needs a decision — reconcile by regenerating and PUTting the full 97, or leave until installations report what they actually need. Watch `rolesWithNoPermissions` and `findings` from 1j's install calls: they are the evidence for which it is **ANSWERED 2026-08-25: reconciled by UNION, not replace.** PUT carried 69 existing preserved byte-for-byte plus 54 vocabulary ids added, **0 deleted** — because replacing with the vocabulary's 97 would have deleted 26 ids the packages do not use, including `community.manage_members`/`invite`/`manage_roles`/`manage_settings`, app-level permissions no archetype derives and one of which an existing role holds. Verified after the write: 127 present, `payment_checkout.create` present, `community.manage_members` still there
- [ ] `new-ticket` — **1l. The generated permissions vocabulary is missing `.create` for four bespoke archetypes that the derivation rule requires.** `permissions.md` step 6 is "For each `create` action's `byRoleIds`, add the archetype's **create** permission", and App Access's own deriver does exactly that — but `docs/references/generated/permissions-vocabulary.json` defines `.create` for all 7 generic archetypes and for bespoke `event-rsvp` and `votePoll`, while **`documentLibrary`, `equipment-loan`, `exportWizard` and `searchAiAnswer` have none**. The shipped packages declare create actions for those families, so the live install failed on `equipment_loan.create` until the id was added to the catalog by hand. These are the same four ids earlier recorded as "invented by the client-side rule" — they were **not** invented; the rule genuinely requires them and the vocabulary omits them. Since the vocabulary is GENERATED from `archetype_resolver.dart` by `loom_ux_judges/bin/generate_permissions_vocabulary.dart` precisely so these rules "exist in exactly one place", the real fix is in the resolver's bespoke action lists, then regenerate. Added to the live catalog as a stopgap (127 ids) so installation could proceed; that stopgap is exactly the kind of second source of truth the generator exists to prevent, so it should not outlive the fix
- [ ] `needs-skill-dispatch` — **1l is BLOCKED ON A SPEC DECISION: `permissions.md` §4 and §6 contradict each other, and §4 is hard-locked.** The dispatch correctly refused to make the change and reported instead of editing a locked document or weakening a test — verified independently rather than taken on its word. **§4** gives `equipment-loan` twelve actions (`view`, `list_item`, `pause_listing`, `delist`, `request`, `decide_request`, `withdraw_request`, `claim`, `join_queue`, `leave_queue`, `take_custody`, `return`) and **no `create`**; same for `documentLibrary` (§4 from line 200), `exportWizard` (224) and `searchAiAnswer` (283). **§6** says "For each `create` action's `byRoleIds`, add the archetype's **create** permission." Both cannot hold: the shipped packages declare create actions with `byRoleIds` for those families, and App Access's own deriver demands `<prefix>.create` — which is why the live install failed until four ids were hand-added to the catalog. **The lock is real and deliberate**: `loom_ux_judges/test/archetype_resolver_spec_sync_test.dart` parses each §4 table and asserts set equality against `ArchetypeResolver.bespokeVocabularies`, so the resolver cannot gain `create` while the document lacks it — the test exists precisely to stop the machine-readable and human-readable definitions drifting. **The decision**: either §4 gains `create` for those four families (making the doc match what the packages and the deployed deriver already do), or §6 / the packages / the deriver are wrong and the four hand-added catalog ids should be removed instead. §4 looks like the incomplete one, but that is a spec judgement, not a dispatch's call. Until it is resolved the four catalog entries stay as a **marked stopgap and a known second source of truth**. Note this is the one blocker of the session that is genuinely a specification question rather than a code or configuration gap
- [ ] `new-ticket` — **1m. CORRECTED 2026-08-29: those App Access groups are NOT orphaned or inert, and members are split across them.** This row said they were leftovers from the superseded client-side applier, inert, worth deleting. Measured in the live database: `loom_communities_cedar-commons-hoa` has **1 member** and `loom_communities_cedar_commons_hoa` has **2** — two group ids for one community, both in use. Deleting either loses real memberships. **So "who belongs to this community" has no correct answer today**, because no query returns both and nothing says they are the same community
- [x] `new-milestone` — **1n. BLOCKS 1b: a column rename shipped without a migration, so no instance can be created against the deployed database.** `POST /instances` returns `500 workflow_service_error` and the service logs **nothing at all**. Root-caused to commit `7449587a`, which renamed the persisted creator column from `created_by_persona_id` to `created_by_fan_id` across the table declaration, inserts, fan queries and row decoding, but added **no forward migration** — and `WorkflowDatabase._migrate` issues only `CREATE TABLE IF NOT EXISTS`, which does nothing to an existing table. Verified directly against the live database rather than from the report: `workflow_instances` still ends in `created_by_persona_id` with no `created_by_fan_id`, so PostgreSQL raises SQLSTATE `42703` at statement preparation. **Why every test missed it**: `WorkflowDatabase.memory()` builds the table fresh from the current declaration so there is nothing to upgrade, and the PostgreSQL integration tests create a fresh temporary schema — so the whole suite exercises the new schema and never an upgrade from the old one. A green suite against a fresh schema says nothing about a database that already exists. Fix dispatched: an idempotent rename guarded on schema metadata, failing startup if BOTH columns exist rather than guessing which holds real data **CLOSED 2026-08-26 in `d97f8bd5`.** Idempotent rename guarded on schema metadata, applied before any instance read or write, failing startup when BOTH columns exist rather than guessing which holds real data. Verified against REAL PostgreSQL in an isolated schema, not only SQLite — and the regression pre-creates the LEGACY table with a row, asserting the pre-existing value survives the rename. Confirmed live: the column renamed itself on first database access after rollout.
- [x] `new-ticket` — **1o. The workflow service cannot report its own failures.** A handled 500 writes no exception, no stack trace and no request line to stdout or stderr: the terminal branch is `catch (_)`, which discards both; `_error` only builds the JSON response; and `bin/loom_workflow_service.dart` passes the handler straight to `shelf_io.serve` with no logging middleware. The correlation id survives only in the response body, so there is nothing to correlate it *to*. This is why 1n needed a live database probe to diagnose at all. Being fixed alongside 1n: log one structured stderr record at the catch boundary — correlation id, method, path, error type, message, stack — while the client-facing response stays byte-identical, and never logging JWTs, request bodies, instance data or credentials. **The client response is not the bug; the silence is.** Worth generalising at GA review: any service that fails closed also has to say why, or a fail-closed path is indistinguishable from an outage **CLOSED 2026-08-26 in `d97f8bd5`.** Each unexpected-500 branch now writes one structured record — correlation id, method, path, error type, message, stack — while the client response stays byte-identical; the test asserts BOTH halves, and that authorization-header and instance-data sentinels are absent. **It paid for itself within the hour**: the very next defect (1b's query failure) was traced from a pod stack trace that, before this, would have gone nowhere.
- [x] `needs-verification` — **1a. Two gate tests now RUN; one fails for real.** Postgres keyset-query test **passes** against live Postgres. Postgres upsert/transition test **fails**: `Bad state: Transition publish is not available for member` at `local_workflow_engine_api.dart:937`, where the fixture declares `publish` `from:["draft"] to:"published"` guarded `allowedRoleIds:["member"]` and the actor IS `member`. **This test may never have passed** — it only runs when `LOOM_POSTGRES_PASSWORD` is set and the cluster has been down. Needs root-cause, not inspection **ROOT-CAUSED 2026-08-25 — the test is wrong, not the engine.** `postgres_database_integration_test.dart` passes `member` as a **fanId** to `applyTransition`, while the fixture guards on `allowedRoleIds: ["member"]` — a **roleId** — and the file never calls `setRoleForFan` or `setRolesForFan` at all. The engine is correct to refuse: `guard_evaluator.dart` states an individual fan id is never treated as a role id, and a role-gated check fails closed when no role is registered. **It cannot ever have passed**: the fixture guard and the fail-closed rule that refuses it landed in the SAME commit `13fb5f49` (2026-08-22), and it went unnoticed for three days because it only runs with `LOOM_POSTGRES_PASSWORD` against a live cluster that was down — so it SKIPPED rather than failed, exactly the trap CLAUDE.md names. Fix is to register the role the engine legitimately requires, never to relax the guard or the fixture. Ticket written, queued behind the provisioning dispatch
- [x] `needs-verification` — **1b. The remote-API live test is unblocked but not yet run.** It needs a creatable workflow type and valid initial instance data in addition to the JWT and community id, and every live community currently holds `"items":[]`. Create an instance via `POST /v1/communities/{id}/instances`, then confirm `queryInstances` returns it — which is exactly what the test asserts **CLOSED 2026-08-26.** The round-trip works end to end against the real stack: `POST /instances` → HTTP 201, `GET /instances` → `items: 2`. Real Keycloak fan JWT → App Access authorization → workflow service → engine → Postgres → back out through visibility filtering. Authorization proven correct in BOTH directions — `hoa-architectural-request` correctly refused (403) for a board member since its `createRoleIds` is `['hoa-member']`, while `hoa-facility-reservation` was permitted. It took four blockers to get here, each invisible until the previous cleared: the empty group map (1d), the stale app-access image, the missing column migration (1n), and a package formula that threw on an absent optional flag (485a092c). Note the second returned instance is one created BEFORE the formula fix — republishing repaired the already-persisted row with no data backfill.
- [ ] `new-ticket` — **the live cluster holds state that exists nowhere in git.** `test-fan-alice`/`test-fan-bob`, their `fanId` attributes, and the realm's `loom-test-client` were created against the running Keycloak — `loom-backend` contains no provisioning script, realm import, or even a mention (`deploy/keycloak/` holds only a Dockerfile). Rebuild the cluster and every live test silently reverts to skipping. Same class as `k3s` being `disabled`: infrastructure that works today and cannot be reconstructed tomorrow
- [ ] `new-ticket` — **test credentials are committed in plaintext**: `loom_auth_session_live_test.dart` carries `test-fan-alice` / `LoomTest123!`. Acceptable for a dev fixture, but it belongs on the pre-GA rotation list alongside the Google, Facebook and DeepSeek secrets
- [x] `new-milestone` — **2. Wire the app to the real backends.** `RemoteWorkflowEngineApi` exists (613 lines, tested) and is **not wired in** — only `part37_remote_auth_session.dart` references it outside tests. Fan Passport and App Access Dart clients already exist in `loom_api_contracts`. This is the largest genuinely-unstarted piece **SEAM LANDED 2026-08-26 in `3527c408`** (+ reset-test restoration `099240d9`). Production selection seam kept SEPARATE from the `@visibleForTesting` override; default stays local so all app-shell tests pass untouched, and the suite moves 273 -> 274. See 2a: this is a seam, not a switch — the app is capable of remote, not yet using it.
- [x] `needs-verification` — **2a. Step 2 landed a SEAM, not a switch: the app uses the real backend only when built with `--dart-define`, and defaults to local otherwise.** `main.dart` calls `configureLoomRemoteServicesFromEnvironment()` and installs the remote factory only when it returns non-null; `part37_remote_auth_session.dart:47-58` reads `LOOM_AUTH_TOKEN_ENDPOINT`, `LOOM_AUTH_CLIENT_ID` and `LOOM_WORKFLOW_SERVICE_BASE_URI` via **`String.fromEnvironment`**, which is **compile-time**, not runtime — so enabling remote means building with `--dart-define=...`, and an unconfigured build silently stays local. That default is deliberate and correct (it is why all 274 app-shell tests pass untouched), but it means **"the app is fully migrated" is not yet true** — it is *capable* of remote, not *using* it. Two consequences: **(1) step 3 is premature** — retiring the local backends would break every unconfigured build, including the whole test suite, so the app must first be proven working against the real backend with the defines supplied; **(2) the B25 captures build the demo APK**, so they must pass the same three defines or they will capture a locally-backed app while believing it is remote — which would silently reproduce exactly the problem the resequencing exists to prevent, since rows would again be proven against the local engine. Also unverified: whether the Android emulator on Windows can reach the workflow service on the VM (`192.168.56.10:30083` host-only, or via a forward) — that is a hard precondition for capture and has never been exercised
- [x] `needs-verification` — **2b. Emulator-to-VM networking WORKS; only the Keycloak leg is unsettled.** Measured 2026-08-26 from the running `emulator-5554` on Windows against the VM's host-only address, which had never been exercised and was 2a's hard precondition for capture. Established: the emulator **pings 192.168.56.10** (2/2 packets, ~42ms); **workflow service :30083 answers `HTTP/1.0 400 Bad Request`** and **app-access :30080 answers `HTTP/1.1 401`** — both real service responses, so TCP and HTTP both traverse. Keycloak **:30082 accepts the TCP connection** (port probe returns OPEN) but returns no HTTP response to `nc`, even at a 30s timeout, while the same endpoint returns `HTTP 200` to Windows `curl`. Since two other JVM services on the same host respond through the identical path, this reads as an `nc` half-close artifact rather than a connectivity failure — **but that is a hypothesis, not a result**, and the emulator image has no `curl` or `wget` to settle it. The decisive test is the real client: build the demo APK with the three `--dart-define`s and see whether it can obtain a token. Do not record capture as unblocked until that happens, and do not record Keycloak as broken on the strength of a `nc` quirk
- [x] `needs-verification` — **2d. The remote-backed APK builds, installs and launches — but the app has NOT been observed using the backend, and that gap is the whole of what remains in step 2.** Measured 2026-08-26. **Proven**: `flutter build apk --debug` succeeds with all three `--dart-define`s; the network security config reaches the **merged** manifest (`android:networkSecurityConfig="@xml/network_security_config"`, verified in `build/app/intermediates/merged_manifest/debug/...`, with no blanket `usesCleartextTraffic`); the APK installs and launches on `emulator-5554` with **zero** cleartext errors, socket exceptions or Flutter exceptions in logcat. **Not proven**: that the app talks to the real backend. Keycloak and workflow-service logs show **no activity at all** in the launch window, which is consistent with the app authenticating only on a user action rather than at startup — so absence of errors here is absence of evidence, not evidence of success. **A failed verification worth recording**: I tried to confirm the defines were baked in by scanning the APK for `192.168.56.10` and got 0 — then ran a control for strings that MUST be present (`cedar`, `loom_communities`, `LOOM_AUTH_CLIENT_ID`) and got 0 for those too. The method is broken (Dart's `kernel_blob.bin` does not yield to `strings` that way), so the original 0 was meaningless. Had the control not been run it would have read as proof the defines never took. **The remaining step is a runtime one**: drive the app to a screen that actually calls the backend — a targeted `flutter drive` with the same three defines — and confirm the request arrives by watching Keycloak and workflow-service logs from the service side, not the app side. Until that lands, step 3 stays blocked and captures must not run. **CLOSED 2026-08-26 — it landed.** Proven on device and cross-checked against Postgres rather than accepted from the client: the app returned `instanceId=community_cedar_commons_hoa_hoa-facility-reservation_3pbmhxf5srqh` with `instanceCount=3`, and both match live `workflow_instances` rows exactly — an in-memory engine cannot fabricate an id created earlier by a direct `POST` to the deployed service. The engine was asserted to be `RemoteWorkflowEngineApi` through the **production** factory, not the `@visibleForTesting` override. Note Keycloak logged nothing in the window and the workflow service has no request-level logging, so the **database cross-check is what carries this**, not a log line. Evidence: [Evidence/backend/step2-proven-on-device.md](Evidence/backend/step2-proven-on-device.md)
- [ ] `new-milestone` — **3. Retire the local backends in that path — SCOPE RESOLVED 2026-08-25.** `LocalWorkflowEngineApi`, `LocalAuthApi`, `LocalInAppBackend`, plus only the six `Community*` fakes the communities app actually touches: `CommunityFoundationFake`, `CommunityRegistryControlPlaneFake`, `CommunityEconomicServicesFake`, `CommunityEngineServicesFake`, `CommunityExperienceServicesFake`, `CommunityOpsServicesFake` — referenced from exactly two files, `test/b1b_publish_discover_install_test.dart` and `test/workflow_test_harness.dart`. **The other ~31 fakes are LEFT ALONE — not ported, not deleted.** They back `loom_demo`, a different app that is not part of the production bar; `FanWalletFake` for instance appears only in `apps/loom_demo/`. Porting 37 Dart fakes into real services was never the plan and is not required by this goal. Revisit only if `loom_demo` itself heads for production **SCOPE CORRECTED 2026-08-25:** read literally this row would break the backend. `LocalWorkflowEngineApi` is constructed in exactly four non-test places, and one is `loom_workflow_service/lib/src/workflow_service.dart` — the deployed service uses it as its own in-process engine, and it is what `RemoteWorkflowEngineApi` ultimately talks to. So retire the APP's two constructions (`part02_tab_shell.dart`, `part25_engine_native_community_store.dart`); the class itself STAYS, because the workflow service is its legitimate remaining consumer.
- [ ] `needs-verification` — **3a. Step 3's scope as written is wrong in three ways, measured 2026-08-26 before dispatching it.** The row claims the six `Community*` fakes are "referenced from exactly two files". They are referenced from **14**: six are the fakes' own definitions in `packages/core/loom_fake_backend/lib/` (one per fake, not consumers), and **eight are test files** — `b1b_publish_discover_install_test` and `workflow_test_harness` as claimed, plus `a1_foundation_components_test`, `a2_registry_control_plane_test`, `a3_experience_services_test`, `a4a_ops_services_test`, `a4b_economic_services_test` and `a5_engine_services_test`, which are **the fakes' own test suites**. Retiring the fakes means retiring those suites too, which is four times the stated blast radius. **Second**: `LocalAuthApi` is not test-only — it is constructed in production at `part01_local_extension_screen.dart:195`, and as a **fallback**: `widget.authApi ?? LocalAuthApi(...)`. That is the same seam shape as the engine factory, so retiring it means **supplying a real auth API as the default**, a migration step, not a deletion. Deleting it outright breaks the local extension screen. **Third**: `LocalInAppBackend` is not in the communities app at all — `class LocalInAppBackend` lives in `packages/core/loom_demo_local_backend/`, and this same row already carves `loom_demo` out of scope ("the other ~31 fakes back `loom_demo` and are LEFT ALONE"). Its only appearance in the app shell is a **documentation string** in `part13_workflow_copy_catalog.dart:456` describing it — copy, not a code dependency. So it is either out of scope by the row's own carve-out, or its retirement is a product-copy change, and those two readings need different work. **Rewrite this row before dispatching it.** The pattern is the same one that made step 2 look like "two construction sites" when one was a private in-memory Messages store: a tracker row written from a plausible reading rather than a measurement, and taken literally it would have deleted production code and six test suites
- [ ] `new-ticket` — **3b. NEEDS A USER DECISION: the six fakes back **53 distinct platform APIs**, and the cluster runs **five** services — so "retire the local backends" is not achievable as written, and the fake-backed share of the production bar is much larger than the four services already agreed.** Measured 2026-08-26 by enumerating every `implements *Api` across the six `Community*Fake` files: 53 distinct APIs including `CommunityWalletApi`, `CommunityMessagingApi`, `CommunityDocumentsApi`, `CommunityModerationApi`, `CommunityNotificationApi`, `CommunitySearchApi`, `CommunityExportApi`, `CommunityAuditApi`, `CommunityRuleEngineApi`, `CommunitySettlementApi`, `CommunityFraudApi`, `CommunityKeyManagementApi` and forty more. Deployed: **app-access, fan-passport, keycloak, postgres, workflow-service**. Only a handful have any plausible counterpart — `CommunityPassportApi` to fan-passport, `CommunityWorkflowApi` to workflow-service, `CommunityMembershipApi`/`CommunityRolePolicyApi` to app-access — leaving roughly **forty-something APIs with no real service to migrate to**. **Why this matters beyond step 3**: item 4 records that four platform services stay fake by user decision (payment, id generation, external search/AI, checksum) and that roughly 22 of the 79 B25 rows must therefore be recorded as proven-against-fakes rather than fully real. That accounting was built on four fakes. With 53 fake-backed APIs the real figure is materially higher, and **the honest number needs recomputing before any row is called production-proven** — otherwise the bar certifies rows against fakes while reading as real, which is the same class of error as capturing with a locally-backed build. **What IS retirable** is what has a real replacement: the app's workflow engine (done in step 2) and `LocalAuthApi` (Keycloak and fan-passport both exist, so it is a migration to a real default rather than a deletion). The rest is not a retirement task at all — it is a decision about how much of the platform stays fake for GA, and it belongs to the user, not to a dispatch
- [ ] `new-ticket` — **3c. CORRECTION to my own 3a note: retiring `LocalAuthApi` is BUILDING a remote auth API, not wiring one — so step 3 has no unblocked sub-item left.** 3a said Keycloak and fan-passport both exist so this was "a migration to a real default rather than a deletion". True in principle, understated in practice: `LocalAuthApi` is the **only** production implementation of `LoomAuthApi` (`part30_local_auth_api.dart:10`); the only other implementation anywhere is `TestActiveAuthApi` in a test helper. There is no remote or HTTP-backed `LoomAuthApi`. So the work is writing one against Keycloak and fan-passport, wiring it as the default behind the same seam pattern the engine now uses, and keeping `LocalAuthApi` available for tests — a substantial build touching authentication, not the wiring job step 2 turned out to be. **Step 3 is therefore fully blocked pending decisions**: the six `Community*` fakes on 3b (53 fake-backed APIs against 5 real services), `LocalInAppBackend` out of scope by the row's own `loom_demo` carve-out or else a product-copy change, and `LocalAuthApi` on whether building a real auth API is in GA scope at all — which is the same question 3b asks, since it is one more of the 53. Recorded rather than scoped into a dispatch, because inventing a large auth build to keep the loop busy would be the wrong call while the underlying question of how much platform stays fake is still open
- [ ] `new-ticket` — **DEBT I INTRODUCED: this file's own convention says index, and I wrote essays into it.** The header states "This is an index, not a memory. One line per open item... Never write item detail directly here — if you're about to write more than one line for an item, that content belongs in the tracker, not here." Across 2026-08-25/26 I added roughly fifteen backend-migration rows carrying full context, measurements, verbatim service responses and reasoning. The longest is **2,607 characters** against a **~361** median for older rows. The detail belongs in `Access Control and Workflow Service Tracker.md` §8, with one-line pointers here. **Why it was left rather than fixed on the spot**: migrating fifteen dense rows is a mechanical edit with real information-loss risk, and this same file has already absorbed three shell-quoting accidents this session — a NUL byte that made git treat it as binary, and twice backticks expanded as commands, eating an instance id and a class name out of closure text. Doing that migration deliberately, with the file read back afterwards, is worth more than doing it fast at the end of a long session. **Nothing is lost meanwhile** — every row's evidence also exists in `Evidence/backend/*.md`, which is where the durable record actually lives; the cost is a bloated index, not missing information
- [ ] `new-ticket` — **4. THREE platform services stay fake — checksum was pulled out of this list by user decision 2026-08-27** ("we need checksum service built and fully integrated into the app", superseding the 2026-08-25 decision that had grouped it with the others). Still fake: payment processing, ID generation, external search/AI answer. None exist in any form. They back `paymentCheckout` (5 communities), `exportWizard` (6) and `searchAiAnswer` (2), and ~22 of the 79 rows name export/payment/checkout/receipt/search/digest workflows. Those rows will be proven against fakes and must be recorded as such rather than counted as fully real
- [x] `new-milestone` — **4a. THE EXPORT CHECKSUM SERVICE IS BUILT AND INTEGRATED. Closed 2026-08-27.** Five commits: spec `33ecde09`, service `79da87b1`, app client `79784c13`, spec auth fix `2aed5d25`, trigger fix `af77cb29`. What existed before: a contract field, a fake at `community_ops_fake.dart:349` returning `'checksum_<id>_<count>_<r|full>'` that hashed nothing and was reachable only from tests, a `'Verify checksum'` const string in a hardcoded affordance list, no checksum concept in `migration-export-api`, no checksum code in `loom-backend`, and no `crypto` import or `sha256` computation anywhere in the app. Now: `export-bundle-api.openapi.yaml` (4 operations), real SHA-256 over the bytes actually served, MinIO-backed storage reusing `DocumentObjectStore`, and an app client wired to the export surface. **7 of 8 checksum-bearing workflows generate end to end.** Verified from my own shell, not from agent reports: workflow service 75 → 84, app shell 308 → 317, engine 312 and judges 440 unmoved
- [x] `needs-verification` — **the verifier genuinely recomputes.** The failure mode this had to avoid is invisible: a verifier comparing a stored value to itself passes for truncated, replaced or missing bytes and looks identical to a working one in every log. Confirmed by reading the handler — it fetches from object storage, runs `sha256.convert(bytes)` fresh, and compares against both the recorded digest and byte length. The test that would catch the broken version exists: overwrite the stored object with `'tampered bytes'`, assert `verified: false`, `observedChecksum != recorded`, and that the instance still holds the original checksum ("mismatch must preserve evidence")
- [x] `new-ticket` — **the `run`-based authorization model was wrong and is fixed.** I specified `run` for generation by analogy with document `upload`. `run` is generic — Garden uses it for `start-export`, `start-transfer` and `start-import` alike; Book Club only for transfer — and in 6 of 8 workflows the completing transition is `record_outcome` into a state with no `run` available, so the rule would have returned 403 across most of the corpus while looking well specified. The implementation agent refused to build against it rather than shipping a path that reports "unavailable" while appearing integrated. All four export routes now gate on `download`, and generation triggers on entering a download-capable state derived from the machine's own transitions — no state name hardcoded
- [ ] `new-ticket` — **Data Portability `export-checksum-evidence` declares no `download` transition**, so it does not generate a bundle and intentionally was not coded around. It is a verification evidence record for a bundle another workflow produced. If it should instead record a digest from a sibling export, that is a product-doc question for the Skill, not an app change
- [ ] `needs-verification` — **the checksum service has never run against the live cluster.** All proof so far is in-process tests. It needs deploying with the workflow service and exercising against real Postgres + MinIO before any B25 row that names an export counts as proven
- [ ] `new-ticket` — **`CommunityExportFake` still returns its fabricated checksum string.** Nothing in the app reaches it, but it backs `loom_fake_backend` tests. Retiring it belongs with the wider fake-retirement work in step 3, not here
- [ ] `needs-verification` — **5. Only then** capture and judge the 79 rows against the real stack

**Standing rule, user instruction 2026-08-25:** after each implementation cycle, commit and push to
GitHub, then sync the Windows repo. Applies to `loom-backend` as well as `Loom` — backend work lives
in a separate repository this tracker cannot see.

### The production bar — deferred until the migration above completes

- [ ] `needs-skill-dispatch` — **5 rows blocked on a missing owner/admin identity: Chess (`chess-export-package`, `chess-pairing-queue`, `chess-rankings-table`) and Book Club (`book-selection-publish`, `book-export-metadata`).** Both ship only Organizer + Member. **CORRECTED 2026-08-24 — the earlier "11 rows" in this row was wrong**: the walkthrough's `_roleIdsForB25Role` already maps `owner` → any identity containing owner/admin/board/coordinator, and `donor` → member, so Cedar (`hoa-board`), Garden (`garden-coordinator`) and Masjid (`mosque-admin`) resolve today and were never blocked. The original cross-check used a naive regex that did not model that mapper — it validated against three *workflow*-missing ground truths and none for roles, so the role half was never checked. `owner` is ratified by the user as a standard platform persona: sets up the community, approves who has access. Note its approval authority is App Access's to enforce, not something package JSON may declare (hard rule 13)
- [ ] `needs-skill-dispatch` — **Ad-Free `ad-off-community-checkout` names the wrong persona.** Its B25 row says `member`, but the doc's own persona table assigns "Fund/sponsor community ad-off" to **Owner**, and the package ships `ad-off-owner`. The walkthrough fails with "could not derive an actionable instance, actorIdentity, and tab ... for B25 product-doc role `member`" — the role exists, it simply cannot act on that workflow. Doc-internal contradiction, same class as Chess; converge through the Skill
- [ ] `needs-verification` — **the reachability sweep has a third blind spot, wider than the role half already corrected.** It checks whether a row's workflow and role *exist*, not whether that role can *act* on that workflow. Ad-Free above passes both existence checks and still fails live. So the real unprovable-row count is ≥ the 7 + 5 already recorded, and is only discoverable by running walkthroughs. Do not quote a total from the sweep as if it were complete
- [ ] `needs-verification` — **7 rows name a workflow their package does not ship**: Chess `chess-local-install-open`/`chess-route-home`, Garden `garden-tool-loan-giveaway`, and Member Social Space's four `platform-*` rows. This half of the reachability sweep stands — it was validated against the Chess walkthrough failure, the B15 manifest's own `productFindings`, and the known Garden mismatch. Method and full list: [Evidence/B25/b25-row-reachability-2026-08-24.md](Evidence/B25/b25-row-reachability-2026-08-24.md)
- [ ] `new-ticket` — **A COMPLETED ACTION CAN LEAVE NO VISIBLE RESULT. Root-caused 2026-08-24** — full report at [Evidence/B25/alternate-action-root-cause.md](Evidence/B25/alternate-action-root-cause.md), read it rather than re-deriving. **CORRECTION: an earlier version of this row called it a harness defect. It is a product rendering defect.** Both alternate transitions land, dispatch and apply; the engine is correct. `critique-submission` binds to `statusTimeline`, which `EngineNativeArchetypeCard` has no case for, so it falls through to `GenericWorkflowInstanceCard` — which never renders `currentState`, so withdrawing only removes buttons. `gear-loan-request` appends to `issueLog`, declared `detail`-context-only, while the walkthrough captures the marketplace tile that filters it out. Two suspects were investigated and **ruled out**: `warnIfMissed: false` hiding a missed tap, and the unchecked third classification path — both still worth hardening, neither causal. Product-rendering fix dispatched; caps what every community can prove, since every row needs an alternate leg
- [ ] `new-ticket` — **the alternate leg proves an ENGINE postcondition, never a VISIBLE one.** `_expectShippedInstanceState` / `_expectShippedInstanceDataChanged` both ran and genuinely passed for the two rows above, so `b25ActionProofStatus: pass` was emitted while nothing a person could see had changed. This is the gap that let a false pass through, and it is deliberately a SEPARATE ticket from the rendering fix — the product and the definition of proof-of-the-product must not move in one dispatch. Require a visible postcondition after the engine one: for `stateChanging`, the target state's declared label visible on the source instance; for `sourceInstanceEffect`, a changed key's rendered value or an explicit acknowledgement, failing loudly with the changed keys and their display contexts if every one is excluded by the active context
- [ ] `needs-live-validation` — **3 of 79 B25 rows proven — Camera Club is COMPLETE** (`photo-walk-rsvp`, `critique-submission`, `gear-loan-request`), walkthrough + UX judge, 2026-08-25, verdict at [Evidence/B25/verdicts/camera-club-b15-ux-verdict-2026-08-25-pass4-PASS.md](Evidence/B25/verdicts/camera-club-b15-ux-verdict-2026-08-25-pass4-PASS.md). It took four judging passes and two fixes — a product one so completed actions render a result, and a capture one so result frames are scrolled to their subject. The judge was told to discard its prior verdicts and re-examined the row it had already passed three times. Soccer's `soccer-team-roster` passes the walkthrough but is **not** judged, so it does not count. Next reachable: Ad-Free (6 rows, B16, persona contradiction now converged), Data Portability (9, B16), Soccer (8, B14) — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-ticket` — **`Borrower/claim count: 0` never increments** even once a gear loan reaches `Status: Requested`. The Camera product doc names borrower/claim count as required visible proof, so an owner scanning that count alone would miss a pending request. Found by the UX judge, non-blocking for the row
- [ ] `new-ticket` — **`critique-submission`'s comment attribution drops the evidence-run identity prefix**, so a comment reads as though a different member wrote it than the one who acted. Found by the UX judge, non-blocking for the row
- [ ] `needs-verification` — **the flagship alternate affordance is displayed but never exercised** on two rows: `Cancel RSVP` for `photo-walk-rsvp` and `Cancel request` for `gear-loan-request`. Both rows pass on a different valid term from their synonym set, which the bar permits — but the most prominent control in each case is unverified by any capture. Worth deciding whether the bar should prefer the flagship path when one exists
- [ ] `needs-debug-agent` — **Garden walkthrough stall**, unfixed and reproducing on both hosts; fails in ~4 min with a diagnostic. The `garden-tool-loan-giveaway` doc/package id mismatch was the trigger; the stall behaviour still needs closing — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — 3 of the 6 product defects found by walking real shipped packages remain open — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)

### Platform phases — no backend is in the loop yet

- [ ] `new-milestone` — **Phase A**: engine implements per-person bookkeeping and response-row fan-out. Scope is smaller than the §8 entry's original text: the 6 visibility models **are** now enforced (`local_workflow_engine_api.dart`, `authz_p4a_visibility_filtering_test`), so bookkeeping and fan-out are what remain. Blocks B and F — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase A.1**: `event-rsvp` response rows become canonical; migrates Masjid Nur's `mosque-event-rsvp` and Tabletop's `tournament-event` — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase B**: all 5 workflow-service operations implemented, App Access-authorized and verified live; only k3s deployment remains — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase C**: auth — Keycloak-as-broker (Google/Apple/Facebook), all 3 services as resource servers. Zero JWT/OAuth2 code exists in either Java service today — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase D**: deploy — App Access derivation endpoint, and redeploy both Java services (running images predate their V2 migrations) — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase E**: app shell asks the access authority instead of deriving locally; hide `tabId`s the caller lacks access to — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase G.4**: Ad-Free revert, the last open piece of Phase G (G.1–G.3 done 2026-08-20) — see [Tab Visibility Derivation Spec Proposal.md](Tab%20Visibility%20Derivation%20Spec%20Proposal.md)
- [ ] `needs-verification` — 3 engine tests skip for want of a deployed backend: 2 need `LOOM_POSTGRES_PASSWORD` (k3s PostgreSQL port-forward), 1 needs a real fan JWT plus a live community id. These are the concrete acceptance gate for Phases B/C/D — un-skipping them is how those phases get proven rather than asserted

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
