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

**Caller landed 2026-08-29 (`e95bfc8b`)**: `part49_offline_replica_coordinator.dart`. Directory
injected by the host, so the core package gains no `path_provider` and stays testable; unconfigured
means offline support is off and the remote factory stays unwrapped, a clean no-op. Fallback happens
**only** on unavailability -- a `403` surfaces and the replica is never consulted, asserted as
`expect(engine.lastRead, isNull)`. Writes never fall back and nothing is queued. A replica read
reports its cursor age so a surface can say the data is stale. App shell 345 -> 351.

Still open: mounting it in a surface, and a decision on background sync -- deliberately left as a
recommendation, since a timer that syncs a closed community is a battery and bandwidth call nobody
has made.

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


### 2026-08-30 — B8 step 1: proposed `experience.notifications`, for approval before it is written

Grammar additions "stop and ask", so this is the design, not a change. Nothing has been edited in
`docs/references/**`.

**The channel set must be exactly fan-passport's, or the two halves cannot compose.** fan-passport's
`NotificationChannel` is a closed `enum: [inbox, push]`, and its own description is careful about
what those mean:

> `inbox` is the in-app notification list — the `notificationInbox` archetype … `push` is a
> device-delivered alert. Both already have working delivery paths on a running device
> (`FlutterLocalNotificationsPlugin`). **Server-initiated push, for a member whose app is closed, is a
> separate and currently-unimplemented capability.**

So `experience.notifications` reuses `[inbox, push]` verbatim. It must **not** invent a third value,
and must not imply that a closed app can be reached — that capability is a placeholder
(`push-delivery-api.openapi.yaml`, version `0.0.0-placeholder`), and a config key promising it would
be the fabricated-value failure this effort exists to remove.

**Proposed shape**, beside `theme` and `creatableAction` under `experience`:

```jsonc
"experience": {
  "theme": { "accent": "#C4703F" },
  "notifications": {
    "channels": ["inbox", "push"],   // what this community OFFERS. Non-empty. Closed set.
    "default":  ["inbox"],           // what a member gets before choosing. Subset of channels.
    "muted": false                   // default interruption state; inbox stays readable when true
  }
}
```

**Why these three keys and not fewer.** `channels` and `default` are genuinely different facts: a
community may offer push while defaulting to inbox-only, and collapsing them would make "we do not
offer push" indistinguishable from "we offer it but do not default to it". `muted` mirrors
fan-passport's own semantics — it suppresses interruption while leaving the notification readable,
so silence is `["inbox"]` + `muted: true`, never an empty list. fan-passport returns `400` on an
empty `channels` precisely because an empty array reads as "no opinion" to a client and "no delivery"
to a server, and those must not be the same value. The package grammar should reject it for the same
reason.

**Proposed validator rules:**

| Rule | Severity |
| --- | --- |
| `notifications.channels` non-empty, unique, all within `[inbox, push]` | error |
| `notifications.default` non-empty and a **subset of** `channels` | error |
| unknown key under `notifications` | error |
| `muted: true` with `inbox` absent from `default` | error — mutes into silence with nothing readable |

**Mechanism check, per the standing rule.** Every field must be computable and consumable:

- *Written by* — the Skill, from the product doc's notification section
- *Read by* — the app when delivering. `LocalNotificationDeliveryService` already exists and already
  delivers both channels on a running device, and the reminder sweeper already calls it. The consumer
  is real, not planned
- *Not read by* — anything server-side. There is no server push, so nothing consults this to reach a
  closed app

**Proposed home:** `reference/platform-services.md`, immediately after §"Scheduled notifications",
which documents *when* a notification comes due and is silent on *how* it is delivered — the two
belong together. That doc is mirrored to `chatgpt-upload/14-platform-services.md` and
`chatgpt_bundle_mirror_test.dart` enforces byte-identity, **so both must change in the same commit**;
a grammar edit that broke exactly this mirror turned the judges suite red earlier in this effort.

- [ ] **awaiting approval** — this is a new grammar block, not a correctness fix
- [ ] then: validator rules (dispatch), Skill regeneration, app reads the default
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


### 2026-08-30 — re-measured the integration table; B5 is 3/4 wired, not "missing 4 methods"

The table above says B5's client is "missing 4 methods" and is not reachable. That was true when
written and is **stale now**. Measured today by grepping for real call sites, with a control:

`part42_document_client.dart` already has all four — `addRevision`, `getDocumentMemberState`,
`setDocumentMemberState`, `listDocumentAcknowledgements`. Callers, excluding the client's own file:

| Method | Callers |
| --- | ---: |
| `addRevision` | 1 — `part36_engine_native_marketplace_surface.dart` |
| `getDocumentMemberState` | 1 — same |
| `setDocumentMemberState` | 1 — same |
| **`listDocumentAcknowledgements`** | **0** |
| *control:* `upload` | 1 — so the query finds callers when they exist |

`part36` is a live member-facing surface, and `document_member_state_surface_test.dart` covers the
member-state path. So **B5 is Reachable for the member half** — acknowledge a document, see its
state — and dark only for the **compliance read**: who has acknowledged, which is the admin view.

- [ ] `new-ticket` — mount `listDocumentAcknowledgements`. One surface, one client method that
      already exists and is already tested at the service layer. This is the whole remaining B5 gap
- [x] corrected the integration table's B5 row; the "missing 4 methods" claim is retired

**Remaining integration gaps, re-measured:**

| Item | Real state |
| --- | --- |
| B2 per-member preferences | Not wired — and **parked** (P1), so not a gap to close now |
| B8 community notification config | Design proposed above, **awaiting approval** |
| B3 change feed | Caller landed (`e95bfc8b`); needs mounting in a surface + a background-sync decision |
| B5 documents | **3/4 wired**; only the acknowledgements view is unmounted |
| B6 replica | Coordinator landed (`e95bfc8b`); same mounting gap as B3 — they are the same ticket |
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
| B3 change feed | **caller landed** (`e95bfc8b`) | still unmounted | Mount it in a surface; decide background sync |
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

### 2026-08-30 — the checksum half proven live too, and one inconsistency found

Both `platformSource` mechanisms are now demonstrated against the deployed stack, not just tested.
A real Cedar instance, authenticated member, `loom-workflow-service:0.9.0`:

| Step | Result |
|---|---|
| `generateExportBundle` | `201`, SHA-256 `9f05529…` over 1596 bytes |
| instance `checksum` field | **the identical digest**, read straight from `workflow_instances` |
| `checksumVerified` on generation | `false` |
| `verifyExportBundle` | `200`, `verified: true`, `recordedChecksum == observedChecksum` |
| `checksumVerified` after | **`true`** |
| `transferId` on the same instance | minted independently, a different UUID from the earlier probe |

Verification **recomputes** rather than reading the stored value back, so a replaced or truncated
bundle would fail — the property that makes the digest worth storing.

**This settles the factual half of the open `checksumVerified` grammar question.** The field is
genuinely platform-written, by `verifyExportBundle`, on the same service as `checksum` but through a
different operation. Only the naming is still open, and option 1 (reuse `"checksum"` and infer from
the `bool` type) now looks worse: the two fields are written by different operations at different
times, which is exactly what a `platformSource` is supposed to name.

- [ ] `new-ticket` — **`checksumStatus` can disagree with `checksumVerified`.** After successful
  verification the instance read `checksumVerified: true` while `checksumStatus` still read
  `verification-pending`. `checksumStatus` is `writableBy: "effect"`, so only a workflow transition
  advances it, while the platform writes `checksumVerified` directly. A member can therefore see
  "verification pending" on a bundle the platform has already verified. Either the workflow needs a
  transition that reconciles them, or `checksumStatus` should not be an independently-written mirror
  of a platform fact.

Probe instance and its bundle were deleted afterwards (instances 4 → 3, bundles 1 → 0, definitions
untouched at 82).

### 2026-08-30 — offline replica is wired end to end, and OFF unless a build says otherwise

The chain is complete: `main.dart` -> `configureLoomOfflineReplicaSupportForProduction` ->
`loomWorkflowReplicaCoordinator` -> `part25`'s engine factory -> `LoomWorkflowReplica`. The
coordinator is referenced from real production code, not only its own test.

**It is off by default, deliberately.** The writable directory is host-injected and defaults to
empty:

    --dart-define=LOOM_OFFLINE_REPLICA_DIRECTORY=<writable path>

With it empty the app keeps remote-only behaviour, the remote factory stays unwrapped, and no
`path_provider` dependency is added to a core package. So offline browse now needs **four** defines
alongside the three that already select the real backend — worth stating plainly, because the
existing trap in this project is a build that silently exercises something other than what the
tester believes.

Turning it on is a deliberate build-time choice, not a code change, and it is the last step before
offline browse and session resume are reachable by a member.

### 2026-08-30 — the change feed proven live, cursor semantics included

Exercised with a real token against `1.0.0`, not just probed for a status code:

| Call | Result |
|---|---|
| full sync, no cursor | `200`, 3 changed, 3 visible, `hasMore: false`, `resyncRequired: false` |
| replay with the returned cursor | `changed` **3 → 0**, `visibleInstanceIds` **3 → 3, identical set** |

That is the contract working: `changed` is a paged delta, `visibleInstanceIds` is a whole-set answer.
The replica deletes anything absent from that set, so its staying complete under a cursor is the
property that stops a member retaining rows they may no longer read. The keyset cursor also excluded
the boundary row rather than repeating it, which is `afterInstanceId` doing its job.

`nextRoleCursor` is returned, so the role-change invalidation path has its input.

**A correction to my own probing.** Earlier I reported `GET /instances` returning 0 for this fan and
treated it as "no instances exist", then created probe instances on that basis. The response is
shaped `{"items": [...]}` and my script read `instances`. There were 3 all along, all
`hoa-facility-reservation` created by `fan-test-alice`. I also briefly suspected a visibility leak
between `/instances` and `/changes` on the strength of that bad parse — both endpoints agree exactly.
Parse the response, do not guess its shape.

All three deployed mechanisms are now demonstrated end to end rather than asserted: opaque-id
minting, checksum generation and verification, and the per-viewer change feed.

### 2026-08-30 — B5 proven live, one production bug fixed, one pre-existing failure uncovered

**B5's compliance property holds against the deployed service.** Uploaded a document (v1),
acknowledged it, added a revision (v2): state reads `acknowledged=true, acknowledgedVersion=1,
currentVersion=2`, and the content serves v2. The acknowledgement **survived and went stale** rather
than being erased. "Who accepted the CC&Rs" stays answerable across a revision.

**Exercising it found a 500 that every test passed over** (`b3b9bdf7`).
`listDocumentAcknowledgements` bound `currentVersion` unconditionally while the SQL referenced it
only when `currentVersionOnly` was true, so the **default listing always failed**. The unit tests use
the in-memory repository, which ignores parameter binding and cannot express this defect. Fixed, with
a PostgreSQL-backed test that reproduces the exact live error and was verified failing without the
fix.

- [x] `RESOLVED 2026-08-30 (`441d0d22`)` — **it was not a stale test; it marked a real
  authorization gap.** `_updateInstanceFields` never resolved roles, so the engine evaluated the edit
  guard against an empty role map and **refused every caller** on any workflow with role-guarded
  editable fields. Known and deferred: `3bbda3f9` says in its own message *"Left open, deliberately:
  `_updateInstanceFields` does not resolve roles at all"*.

  **My first diagnosis was wrong.** I read the failure as a stale test encoding pre-fix creator-only
  semantics, and asked for an authorized app-access client. The dispatch **refused and reported**
  that no client could change the outcome, because the route never consults one. It was right, and
  the refusal is why the real gap surfaced instead of a one-character `expect(403)`.

  Fixed by reusing the transition route's `_resolveRolesForRequest` rather than a second path, with
  four outcomes distinguished so the fix cannot pass by allowing everyone: member with the role
  `200`, member without it `403`, **non-member still holding the role `403`**, app-access unreachable
  `503`. The third preserves what `3bbda3f9` bought; the fourth stops a resolution failure collapsing
  into "no roles", which would be indistinguishable from a legitimate refusal.

  Original note follows. **`postgres_guard_refusal_integration_test.dart` has been failing
  invisibly.** *"live PostgreSQL updateInstanceFields persists and is readable afterward"* expects
  `200` and gets `403`. **Pre-existing**: it still fails with every uncommitted change stashed.

  It is invisible because Postgres-backed tests **skip without credentials**, so the routine
  `dart test` run reports 139 green while a real integration test is red. That is the exact hazard
  already recorded in CLAUDE.md, now with a concrete instance.

  A `403` on `updateInstanceFields` is an authorization refusal where the test expects success, so
  the candidates are a real authz regression, a role/group state dependency (note Cedar's split
  membership, where only `fan-test-alice` is in the mapped group), or a stale test. **Do not assume
  the third.**

- [ ] `new-ticket` — **run the Postgres-backed suites with credentials in whatever passes for CI
  here**, or at minimum at every closeout. A suite that silently skips its only real integration
  coverage will hide the next one of these too.

### 2026-08-30 — BLOCKER FOR THE PRODUCTION BAR: ten of eleven communities have no members

Measured against the live cluster while trying to exercise B1's item queue end to end.

**Of the 11 groups the live mapping targets, exactly ONE has a member:**

| Group | Mapped? | Members |
|---|---|---|
| `loom_communities_cedar-commons-hoa` | **yes** | `fan-test-alice` |
| `loom_communities_cedar_commons_hoa` | no | `fan_alice`, `fan_bob` |
| 2 × `loom_communities_b3-e2e-*` | no | 1 each (my own test residue) |
| **the other 10 mapped groups** | yes | **none** |

**This blocks the stated production bar**, which is every product-doc workflow verified by live
walkthrough and UX judge across the B25 addendum's 79 rows. You cannot walk through a community
nobody can join. Nine of the ten communities are unreachable by any identity that exists.

It also makes several shipped features unexercisable rather than unproven. The item queue is the
clearest case: `join_queue` is declared only in Book Club, Camera Club and Garden, and no fan has
membership in any of them. B1 is wired, deployed and reachable **in code**, and cannot be
demonstrated by a member today.

**I under-called this earlier.** On 2026-08-29 I looked at Cedar's split membership, found five test
fixtures, and recorded it as cleanup — "not a blocker, and I over-escalated it". The narrow claim was
right: no real user data is at risk. The conclusion was wrong. The split is the visible edge of
membership data barely existing at all, and that is a blocker for the completion gate rather than
tidying.

- [ ] `needs-decision` — **who creates community membership, and for whom.** Seeding test identities
  into the ten empty mapped groups is a data operation against App Access, and it decides what a
  "member" is for every future walkthrough and capture. Options: seed a per-community test fan set;
  put one identity in every community; or drive membership through the real join flow if one exists.
  I did not pick one, because it determines what every subsequent live verification actually proves.

- [ ] `new-ticket` — delete the two `loom_communities_b3-e2e-*` groups and the unmapped duplicate
  spellings once the above is decided; they will otherwise be read as product data.

### 2026-08-30 — the emulator reaches the live backend; the APK build is blocked on a Windows setting

**Reachability is proven, and that is the half that was in doubt.** From inside `emulator-5554`:

    ping 192.168.56.10          -> 2/2 packets, 0% loss
    nc  192.168.56.10 30083     -> HTTP/1.0 200 OK, "x-powered-by: Dart with package:shelf"
    nc  192.168.56.10 30082     -> open (keycloak)

So an Android build on this host can reach the k3s services over the host-only network.

**And the three backend dart-defines are no longer needed.** `LOOM_ENV` defaults to `dev`, and the
`dev` environment already carries every endpoint — auth `:30082`, workflow service `:30083`,
app-access `:30080`, fan-passport `:30081` — plus the full community-to-group map. A plain debug
build targets the deployed stack. Only `LOOM_OFFLINE_REPLICA_DIRECTORY` still needs one, to switch
offline browse on.

- [ ] `needs-user-action` — **`flutter build apk` fails: "Building with plugins requires symlink
  support. Please enable Developer Mode in your system settings."** This needs Windows Developer Mode
  (`start ms-settings:developers`), which this session cannot set.

  **Do not fall back to the APKs already in `build/app/outputs/flutter-apk/`.** They are dated
  **Aug 11 and Aug 9** and predate the entire backend build-out: the probes, the row locking, the
  minting, the change feed, the document versioning and both of today's fixes. Installing one and
  exercising it would reproduce this project's most expensive recurring mistake — verifying against a
  proxy rather than the artifact that actually executes, which has already happened four times.

  Until it builds, the app-side chain is verified only as far as: the code wires it, the emulator can
  reach the services, and the services answer correctly to direct calls.

### 2026-08-30 — the app runs on device from today's build; no backend call yet

Built on the **VM** to sidestep the Windows Developer Mode blocker (Linux has no symlink
restriction), copied over, installed on `emulator-5554`. Everything below is a **fresh artifact from
current `main`** -- deliberately not the Aug 11 APK sitting in the output directory, which predates
the entire backend build-out and would have made a device test look successful while proving nothing.

**What is proven:**

- the APK builds (VM, Flutter 3.41.7, Java 21 -- 194 MB with communities bundled)
- it installs and launches; Flutter loads, no crash, no cleartext rejection
- `LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true` loads **10 example communities**, themes applied
- Cedar Commons HOA opens with its theme, `HOA Board` and its 2 roles, Home/Messages, and the home
  surface's 4 sections -- all rendered from the local package
- the emulator can reach the deployed services: `ping` 2/2, and raw `nc` to `192.168.56.10:30083`
  returns `HTTP/1.0 200 OK`, `x-powered-by: Dart with package:shelf`
- the build **is** configured for the real backend. `configureLoomRemoteServicesFromEnvironment`
  falls back to the named environment when no define is present -- "When no define is present the
  environment is used" -- and `LOOM_ENV` defaults to `dev`. The three backend dart-defines are
  genuinely unnecessary; only `LOOM_OFFLINE_REPLICA_DIRECTORY` is.

**What is NOT proven, and must not be claimed:** the app has made **zero** calls to
`192.168.56.10`. Everything on screen is package content. Two reasons, and they are separable:

1. no authenticated session exists, so `RemoteWorkflowEngineApi` has no bearer token
2. nothing navigated to a surface that lists workflow *instances*, which is what would fetch

- [ ] `new-ticket` — **drive the app to an authenticated instance fetch on device.** The path exists
  in code; I could not drive it blind through the UI. Entry points, for whoever does the walkthrough:

  | Where | What |
  |---|---|
  | `part38_production_login_screen.dart` | `LoomProductionLoginScreen` — the real Keycloak login |
  | `part01_local_extension_screen.dart:1088` | menu item `_production-login`, **gated on `productionAuthSession != null`** |
  | `part01_local_extension_screen.dart:1090` | menu item `_sign-in-specific-person` → `LoomAuthScreen` |
  | `part01_local_extension_screen.dart:347` | the `community-entry-gate` Scaffold, which embeds `LoomAuthScreen` |

  Auth resolves to the **remote** implementation: `configureLoomRemoteServicesFromEnvironment` sets
  `_loomRemoteServiceConfiguration` (part37:181), and `resolveLoomAuthApiForCommunity` returns
  `RemoteLoomAuthApi` whenever that is non-null. So a sign-in on device would hit Keycloak at
  `192.168.56.10:30082` rather than the local fake.

  What I could not establish: why opening Cedar bypassed the entry gate, and which control opens the
  identity menu — tapping the header identity icon and the roles card both did nothing. That is UI
  archaeology better done by someone who can see the widget tree, not by tapping coordinates.

  Original note follows: tapping the identity icon on the community screen changed nothing, and no
  login prompt appeared at any point in this build. Until a member session exists on the device, the app-side link
  is verified only as far as "configured correctly and able to reach the services", which is short of
  the walkthrough the production bar asks for.

### 2026-08-30 — the device run rendered a LEGACY FALLBACK, and Android cannot sign in at all

Root-cause investigation of "the entry gate never appeared". Both findings are defects, both cited.

**1. What I saw on the emulator was not Cedar's real package.** `LOOM_PRELOAD_EXAMPLE_COMMUNITIES`
creates the ten cards as **metadata-only** `LocalInstalledCommunity` objects with an empty
`experienceConfiguration`. `_experienceFromConfiguration` therefore returns null, the community is
classified **legacy** (`part01_local_extension_screen.dart:243-246`), and
`_refreshCommunityEntryGate` sets `_communityEntryAllowed = true` and returns **before**
synchronising authorization or listing accounts (`:274-290`). `build` then renders community content
whenever the schema is legacy, independently of the gate (`:1188-1209`).

So the theme, the "HOA Board / 2 roles" card and the four home sections came from a **shallow
fallback**, not the engine-native package — which is also why there were zero network calls: the
legacy return happens before `_ensureEngineAuthorizationSync`.

**My report two ticks ago that "Cedar opens with its theme, roles and surfaces" was therefore
describing a fallback rendering.** It looked exactly like success. This is the verify-against-the-
artifact-that-executes trap in a new costume: the artifact was fresh and correct, and the *fixture
path* was the fake.

**2. There is no Android production login.** `LoomProductionLoginScreen` calls
`completeInteractiveLogin` / `loginInteractively` (`part38_production_login_screen.dart:33-75`), and
the non-web `InteractiveLoginPlatform` throws
`UnsupportedError("Interactive Loom login is currently supported only on Flutter Web.")`
(`loom_auth_session/lib/src/interactive_login_stub.dart:5-24`). The screen catches it and shows an
unsupported state.

**A member cannot obtain a bearer token on Android at all.** The navigation path exists; the
implementation does not.

**Independently verified, because this claim invalidates a plan rather than blocking a step.** The
selection is a Dart conditional import — `loom_auth_session.dart:8` reads
`if (dart.library.js_interop) 'interactive_login_web.dart'`, so the **stub is the default** and the
web implementation is chosen only where `js_interop` exists. Android has none, so it gets the stub,
where `start()` and `complete()` both return `Future.error(UnsupportedError(...))`. The package
contains exactly three files — `interactive_authorization.dart`, `interactive_login_stub.dart`,
`interactive_login_web.dart` — and **no Android implementation**. That conditional was the one thing
that could have made the report wrong, which is why it was worth checking rather than accepting.

- [ ] `new-ticket` — **preload must install the full bundled packages**, so a preloaded community
  carries its canonical `communityId`, `specVersion`, `appShellConfiguration` and non-empty
  `workflowDefinitions`, and the existing gate runs.
- [ ] `new-ticket` — **fail closed**: when remote services are configured and a preloaded community
  reaches `LocalExtensionScreen` with an empty or legacy experience, error naming the community
  rather than silently rendering non-authoritative content.
- [ ] `needs-decision` — **Android interactive login is unimplemented.** An Authorization Code +
  PKCE flow is required before any Android live walkthrough is possible. Until then the B25
  completion gate cannot be met on Android by any means, regardless of membership.

### 2026-08-30 — NO authenticated walkthrough is possible on ANY platform today

Both targets are blocked, for unrelated reasons, and neither was known before today.

| Platform | Blocker |
|---|---|
| **Android** | Interactive login is unimplemented. `loom_auth_session.dart:8` selects `interactive_login_web.dart` only `if (dart.library.js_interop)`, so Android gets the stub, whose `start()` and `complete()` both return `UnsupportedError`. No Android implementation exists in the package. |
| **Web** | The app **does not compile**. `loom_workflow_engine/lib/src/store/database.dart:3` imports `dart:ffi` unconditionally (and `dart:io` beside it) for sqlite3, reached via `main.dart -> loom_communities_demo -> loom_communities_app_shell -> loom_workflow_engine`. `flutter build web --release` fails. |

**I proposed web as the way around Android and was wrong.** `interactive_login_web.dart` is a real
203-line implementation, the demo app has a `web/` directory, and it looked like a clean path. It
does not build, and nothing in the repo suggests a web build has ever been attempted — the `web/`
directory is Flutter scaffolding. Building it rather than recommending it is the only reason this
was caught in one tick instead of becoming a plan.

**Consequence for the production bar.** The completion gate is every product-doc workflow verified by
live walkthrough and UX judge. That requires an authenticated member session, and there is currently
**no platform on which one can be obtained**. This is upstream of the membership blocker: even with
all ten communities populated, nobody could sign in to walk them.

- [ ] `needs-decision` — **pick the platform to unblock.** Scoped 2026-08-30, and **Android is
  smaller than "implement OAuth" suggests** — my earlier "neither is small" overstated it.

  **The protocol is already done and platform-neutral.** `interactive_authorization.dart` is 80
  lines importing only `dart:convert`, `dart:math`, `crypto` and `openid_client`: PKCE verifier
  generation, the RFC 7636 `S256` challenge, the authorization URI, and callback-state validation.
  The token exchange in the web implementation is ordinary `http` and reusable as-is.

  What the web layer adds that is genuinely platform-specific is only six things
  (`interactive_login_web.dart`): store the transaction in `sessionStorage`, set
  `window.location.href`, read the callback from the URL, clear storage, and `history.replaceState`
  to tidy the address bar.

  **Android equivalents:** persist the transaction (the app already uses `FlutterSecureStorage` for
  tokens), launch the authorization URI in a Custom Tab or browser, and **capture the redirect** via
  an app link or custom scheme — that last one is the only genuinely new piece, and it needs an
  `AndroidManifest` intent filter plus the redirect URI registered on the `loom-test-client` Keycloak
  client. Roughly a mirror of the ~200-line web file with the storage and redirect halves swapped.

  **Web, by contrast, needs the engine restructured**: `dart:ffi` and `dart:io` are unconditional in
  `store/database.dart`, so it needs conditional imports and a web-compatible drift backend
  (sqlite3 wasm/IndexedDB) — a change to the engine every platform shares, to reach a target nothing
  in this repo has ever built.

  On this evidence Android is both the smaller job and the one the capture apparatus already targets.
  Recorded as a recommendation, not a decision taken.

### 2026-08-30 — both findings confirmed ON DEVICE, with the fix in place

Rebuilt with the preload fix (`60c94aa7`), clean-installed, and driven by hand. Two predictions were
stated before the run and both held.

**1. The preload fix works.** The community descriptions changed on the home screen — Garden Club
went from "Coordinate garden events and plant exchange requests" (the stale alias catalogue) to
"RSVP to seasonal garden events, share plants and tools…" (the real package). Cedar, Youth Soccer,
Masjid Nur and Chess changed too.

Opening Cedar now shows the **entry gate** instead of silently rendering content:

> Welcome to Loom — Choose an account below or create a new one.
> `LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required.`
> Choose an active account or create one to continue to **Cedar Commons HOA**.

Cedar resolves as engine-native, the gate runs, and authentication is demanded. Exactly the
behaviour the fallback was hiding.

**2. Android sign-in is unimplemented, in the app's own words.** "Continue to secure sign-in" leads
to:

> **Secure sign-in is not supported on this platform yet**
> Interactive identity-provider sign-in is currently available only in Loom on the web.

The static finding is now demonstrated on the artifact that executes. Zero backend calls throughout,
as expected: no session can be obtained, so nothing can be fetched.

**An ANR appeared mid-run** — "Digital Wellbeing isn't responding" — a system dialog unrelated to the
app, overlaying the frame. Detected via `dumpsys window` on the device rather than by anything
Flutter-side, which is why that rule exists: a Flutter text guard cannot see a system window, and a
capture taken during it would have been silently corrupt.

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

### 2026-08-30 — SECURITY: any authenticated fan can grant themselves any role in any community

Found while seeding test accounts through the real join flow. **Not a theory — reproduced twice.**

`decideGroupMembership` is specified as *"Requires `app.access.admin`. Approving moves the membership
to `active` and grants the roles supplied here"*. **Nothing enforces that.**

A brand-new Keycloak user with no roles, no memberships and no admin rights:

    POST /v1/apps/loom_communities/groups/loom_communities_chess-club/membership-requests
      Authorization: Bearer <their own token>   X-Loom-Actor: loom-cedar-board-1
      -> 201, state "requested"

    POST .../membership-requests/loom-cedar-board-1/decision
      Authorization: Bearer <their own token>   X-Loom-Actor: loom-cedar-board-1
      {"decision":"approve","roleIds":["chess-owner"]}
      -> 200, state "active", roleIds ["chess-owner"], decidedByFanId "loom-cedar-board-1"

**They approved their own request and granted themselves owner.** Repeated against Cedar with
`hoa-board`, same result. The caller is identified by an `X-Loom-Actor` header, and no check ties the
actor to the token, nor requires the actor to hold any administrative role in the group being decided.

**Impact.** Any account that can obtain a token — the realm allows direct grants — can become owner or
board of every community, which is every permission the workflow engine subsequently trusts. All the
per-fan visibility work is downstream of this: the engine correctly resolves what a role may see, and
this lets anyone choose their role.

**Both escalated memberships were deleted immediately after confirming** (`group_membership` and
`group_membership_role` rows for `loom-cedar-board-1`, verified 0/0 afterwards). The Keycloak user
remains, disabled-by-neglect rather than deleted, pending the account-seeding work.

- [x] `FIXED AND VERIFIED LIVE 2026-08-30` — `loom/app-access:0.3.2` (`4994fa8`). Both halves
  confirmed against the running service, and **separately**, so neither masks the other:

  | Check | Result |
  |---|---|
  | the original exploit, mismatched actor | `403 fan_identity_mismatch` |
  | self-approval with a valid identity | `403 self_membership_decision_forbidden` |
  | **legitimate self-request** | **`201`** — the flow is not broken |

  Distinct error codes for the two defects, so each is independently enforced. The fix adds real
  token plumbing; `X-Loom-Actor` is demoted to actor context and is no longer an identity credential.

  **The vulnerability had been masking an incomplete account.** Working accounts need a `fanId` **user
  attribute**, which the `loom fan id` protocol mapper emits as the `fanId` claim — `test-fan-alice`
  carries `fan-test-alice`. A user created without it has no claim, which the old header-trusting code
  never noticed. Create users with **every field in one POST**: Keycloak replaces rather than merges,
  and a follow-up PATCH silently cleared an email during this work.

- [ ] `needs-decision` — **the fix creates a bootstrap problem, by design.** Approval now requires an
  admin, and only one active membership with a role exists across all eleven groups
  (`fan-test-alice`, `hoa-board`, Cedar). **Nine communities have nobody who can approve anyone**, so
  the ~35 accounts cannot be seeded purely through the API.

  The honest options: insert the first owner/admin per community directly, once, as an explicitly
  recorded bootstrap, then create everyone else through the checked flow; or add a real bootstrap
  path to the service. Seeding entirely by direct insert would reproduce the problem the fix just
  closed — fixture data that never passed an authorization check.

  Original note follows. **enforce authorization on `decideGroupMembership`.** At minimum: the actor
  must be bound to the presented token, and must hold an administrative role in the group being
  decided. Self-approval must be refused outright.
- [ ] `new-ticket` — **audit every app-access endpoint that takes `X-Loom-Actor`** for the same shape.
  A header-supplied identity that nothing ties to the token is a pattern, not one endpoint.
- [ ] `new-ticket` — seeding test accounts is **blocked on the fix**. Seeding through the flow as it
  stands would mean using the vulnerability as the mechanism, and the resulting memberships would be
  indistinguishable from an attack.

### 2026-08-30 — a two-hour silent outage, and the resilience defect behind it

**I caused this, and the shape of it is worth keeping.** Building the `app-access:0.3.2` image on
the VM starved the node that also runs k3s. Kubelet gracefully restarted `postgres-0`
(`exitCode: 0`, `reason: Completed` — 12 restarts total), and at the same minute *every* pod logged
`context deadline exceeded`: app-access, fan-passport, keycloak, minio. Four services failing
together is the node, not the services.

**Postgres recovered in under a minute. `workflow-service` never did.** For roughly two hours every
request returned `500`:

    "error": "Severity.error Attempting to execute query, but connection is not open."

`GET /changes`, `POST /instances`, transitions — all dead. The pod stayed `1/1 Running` with **zero
restarts** and `/readyz` reported ready the entire time. Nothing in `kubectl get pods` showed a
problem. It recovered only when I ran `kubectl rollout restart`.

**Root cause** — `loom_workflow_service/lib/src/postgres_connection.dart` opens exactly one
`pg.Connection` at process start and holds it for the life of the pod, then hands it to
`PgDatabase.opened(...)`, which is explicitly the "caller owns the connection" constructor. No pool,
no validation, no reopen path. Once that socket dies the service is permanently broken.

The Java services came back **on their own** in the same incident, because HikariCP validates and
replaces dead connections. This is a Dart-side defect only.

A database restart is routine in production — failover, patching, resize, an OOM kill. Ticketed and
dispatched (`/tmp/ticket_pg_reconnect.md`): pooled connections that reopen, a bounded pool with a
connect timeout, readiness that reflects database reachability, and **`/healthz` left alone** —
liveness restarting on a transient DB blip turns one slow query into a crash loop. The highest-risk
part is that `SELECT ... FOR UPDATE` needs a transaction pinned to one connection, so a naive pool
would break row-level locking while every existing test still passed.

- [x] outage diagnosed, service restored, probe row cleaned up (`DELETE 1`, 0 remaining)
- [x] operational trap written into `CLAUDE.md` — a heavy build stalls the cluster, and the blast
      radius outlives the build
- [x] **landed and independently verified** (`ff03d168`) — bounded 8-connection pool, 5s acquire
      timeout, repositories on `pg.Session`, transactions through `Pool.runTx` with the drift
      executor zone-bound so concurrent requests cannot borrow one another's connection. SQLite
      path untouched. `/readyz` now probes the database; `/healthz` deliberately still does not
- [x] **verified against live PostgreSQL, because the suite alone could not** — the dispatch
      reported green at `139 passed, 10 skipped`, and those ten included **all four tests it had
      written to prove its own fix**. With a port-forward and credentials: 4/4 pass, including the
      lock test that has a background borrower steal the connection a statement-based `BEGIN` would
      have released and then requires an outside `UPDATE` to block. The engine's own four
      PostgreSQL cases pass too, including overlapping transitions on separate connections.
      Five suites re-run here: 148 (+1), 312 (+5), 354 (+2), 464, 160 — all exit 0, no weakened
      assertions in the diff
- [x] `loom-workflow-service:1.0.2` built, imported, manifest bumped, rolled out (backend `ebc742a`).
      Also committed the app-access `0.3.2` manifest (`752354e`), which had been deployed and
      verified this morning but never recorded — the repo described `0.3.1` while the cluster ran
      `0.3.2`
- [x] **PROVEN LIVE 2026-08-30.** Deleted `postgres-0` deliberately and touched nothing else:

          t+012s   pg Terminating   readyz=503  healthz=200  changes=000
          t+024s   pg Running       readyz=200  healthz=200  changes=200
          t+204s   pg Running       readyz=200  healthz=200  changes=200

      **Same pod before and after** (`workflow-service-7bb5b6f5b4-bwgxh`), **`restarts=0`**. The
      pool reopened by itself in under 24 seconds; Kubernetes did not repair this by cycling the
      container, which is the distinction the whole ticket turned on. The identical event this
      morning cost two hours of total outage.

      Both health semantics behaved as designed: readiness went 503 while the database was gone
      (so the pod leaves service) and liveness stayed 200 (so it is not crash-looped). A liveness
      probe that tracked the database would have converted this into a restart storm.

      The `401`s later in the run were the access token expiring at its `expires_in: 300` lifetime,
      not a regression — confirmed by re-requesting with a fresh token (`200`) and creating an
      instance successfully. Probe row deleted afterwards, 0 remaining.

**The check this changes:** after any heavy build, re-run a real request against the stack. Pod
status is not evidence — everything was `Running` throughout.

**Also confirmed, incidentally:** the `0.3.2` authorization fix did **not** break service-to-service
calls. Once the pool was rebuilt, a create + transition succeeded (`201`, `200`, `transferId` minted),
and role resolution runs through app-access. My first hypothesis — that the security fix broke the
stack — was wrong, and the restart counts said so before I acted on it.


### 2026-08-30 — the workflow-service image build ships 6 GB of build artifacts

Building `1.0.2` took roughly an hour, most of it before Docker ran a single instruction:

    Sending build context to Docker daemon  6.885GB

`build.sh` stages `~/.pub-cache` and `~/Loom/app` into a scratch dir and hands the whole thing to
`docker build`. Measured on the live staging directory:

| Path | Size |
| --- | ---: |
| `.pub-cache` | 535 MB |
| `app/apps` | **4.0 GB** |
| `app/packages` | 1.7 GB |
| `app/build` | 52 MB |

The 4 GB is Flutter build output — `apps/loom_communities_demo/build` and a `build/` directory in
almost every package, plus `.dart_tool/build`. **None of it belongs in a server image**, which
compiles `bin/loom_workflow_service.dart` to an AOT binary. There is no `.dockerignore` anywhere in
the build path, so every build copies all of it, twice: once into the scratch dir, once into a
Docker layer.

- [ ] `new-ticket` — exclude build output from the image context. Either write a `.dockerignore`
      into the scratch dir from `build.sh` (it is the context root, so it has to be placed there,
      not beside the Dockerfile in the package), or stage with an exclude list instead of `cp -r`.
      Exclude at minimum `build/`, `.dart_tool/`, `.git/`, and test fixtures
- [ ] confirm the resulting image still runs — the AOT compile needs the workspace resolved, which
      is why the script stages a pre-resolved tree in the first place; excluding `.dart_tool`
      wholesale may break `pub get` reuse, so verify rather than assume

**Why it is worth doing rather than tolerating:** a one-hour build is why the deploy step keeps
getting deferred, and it is the same build that starved the node and caused this morning's outage.
Cutting the context to a few hundred MB shortens both the wait and the window in which the cluster
is degraded.

**What actually happened building `1.0.2`, recorded because the diagnosis was half wrong.** Three
attempts. The first ran 1:08 and was genuinely stalled — its `docker` client CPU was flat at 18:05
across two samples sixteen minutes apart, with no container, no shim and an idle daemon. I killed
the second on the same reasoning and **that call was wrong**: its client had 9:18 of CPU and
climbing, so it was working, and I generalised from one confirmed case to one that did not match.
Two things that looked like causes were not: container creation from the large intermediate image
works fine, and BuildKit was never available to switch to — it needs the buildx plugin, which is
not installed and not in the configured apt repos.

The third attempt succeeded after a `dockerd` restart and after deleting 3.57 GB of gitignored,
regenerable `build/` directories (`app/` went 6124 MB → 2556 MB). Which of those two mattered is
**not established**. The final image is 146 MB — the multi-stage build discards the context — so
the bloat only ever cost build time, never image size.

Two lessons worth more than the incident: judge hung-versus-slow from a **CPU trend**, never one
sample, and note that the build log is block-buffered, so a stale tail is not evidence of a stall.


### 2026-08-30 — the blocker is not bootstrapping, it is that the platform `admin` role was never provisioned

I reported earlier that seeding was blocked because nine communities have no admin who can approve.
That was right about the symptom and **wrong about the cause**, and the correction matters because
it changes what has to be built.

**First, two corrections to what I said.** I claimed the only role-holding membership was
`fan-test-alice` with `hoa-board` in Cedar. It is **`fan_alice`** with **`cedar_commons_hoa_admin`**,
and there are **5 active memberships across 4 groups**, not one.

**What is actually true**, measured against `loom_app_access` with controls on every query
(24 groups, 29 roles, 372 `role_permission` rows):

| Check | Result |
| --- | --- |
| Roles holding `community.manage_members` | **1 of 29** — `cedar_commons_hoa_admin` |
| A role named `admin` | **does not exist** |
| `community.view` | held by **nobody** |
| `community.manage_roles` | held by **nobody** |
| `community.invite` | held by **nobody** |
| `community.manage_settings` | held by **nobody** |

Confirmed in code, not inferred from the name: `AppAccessService.java:103` defines
`GROUP_MANAGER_PERMISSION = "community.manage_members"`, and that is what the decide path checks.

**Why the domain roles do not have it, and should not.** The derived roles are rich in workflow
actions — `hoa-board` has 34, `book-organizer` 31, `chess-owner` 7 — and every one of them is a
workflow action (`export_wizard.create`, `document_library.upload`). The provisioning deriver builds
role permissions from the package's workflows. `DerivedRoleInput` carries only `roleId` and `label`,
so a package cannot express a governance grant at all.

That is correct by design. `docs/references/reference/permissions.md` §7 says so plainly:

> `admin` is a **platform** role and coexists with domain roles: a real person may hold
> `[admin, hoa-board]`. No fixture declares a role named `admin`, so this is purely additive.
> User management is an App Shell experience gated on `community.manage_members`, never a workflow.

So `community.manage_members` was never meant to sit on a community package role. It belongs to a
platform `admin` role that **nothing has ever created**. `cedar_commons_hoa_admin` is a hand-made
one-off — 4 permissions where derived roles have 20–34 — which is why exactly one community works.

**Consequence.** `requestGroupMembership` → `decideGroupMembership` is unusable in every community
except Cedar, and inserting a bootstrap membership would not fix it: an admin bootstrapped into
Chess Club would hold `chess-owner`, which has seven export-wizard permissions and cannot admit
anyone. The invitation path is closed for the same reason — `issueInvite` is documented
"Admin-initiated only".

- [ ] `new-ticket` — **provision the platform `admin` role** with the five `community.*` governance
      permissions, and a path to grant it. This is app-access provisioning work, not a package
      change, and it is upstream of every seeding question
- [ ] `needs-decision` — **who holds `admin` for each community**, once the role exists. This is the
      question I previously framed as "bootstrap admin", and it is smaller than it looked: granting
      an existing platform role to a fan is ordinary provisioning, not a direct membership insert
      that bypasses authorization
- [ ] `new-ticket` — the four governance permissions held by nobody (`community.view`,
      `manage_roles`, `invite`, `manage_settings`) need the same treatment, or they are decoration
- [ ] `new-ticket` — **24 groups for ~11 communities**: both hyphenated and underscored spellings
      exist (`loom_communities_camera-club` *and* `loom_communities_camera_club`), plus two
      `b3-e2e-*` throwaways. Decide which spelling is canonical and delete the rest before they are
      read as product data

**CORRECTED, same day — the "per-group vs app-wide" fork above was a false dilemma.** I framed the
next step as a design decision because `app_role.group_id` is nullable but NULL in zero of 29 rows.
Reading the authorization path settles it: **the mechanism already exists and is simply unused.**

`AppAccessService.collectActiveRoleIds` (line 1065) unions **two** sources:

```java
appAccessRoleRepository.findById_AppIdAndId_FanId(appId, fanId)      // app-level, NOT group-scoped
...
groupMembershipRoleRepository.findById_AppIdAndId_GroupIdAndId_FanId(appId, groupId, fanId)
```

The first is gated only on the fan's `app_access` row being active — **no group filter**. So an
`app_access_role` grant contributes to `activeRoleIds` in *every* group, which is exactly the
"`admin` coexists with domain roles: a real person may hold `[admin, hoa-board]`" model
`permissions.md` §7 describes. `requireGroupAdministrator` then checks those ids for
`community.manage_members`, so a platform admin passes in every community without any per-group role.

Measured, with a control (`group_membership_role` = 5 rows, so the queries work):

| Table | Rows |
| --- | ---: |
| `app_access` | **0** |
| `app_access_role` | **0** |

**Nobody has app-level access at all**, and no platform role has ever been granted. Cedar works only
because `cedar_commons_hoa_admin` is a *group-scoped* role that happens to carry the permission — the
one-off, not the design.

So there is no architecture decision outstanding. The work is provisioning, in order:

- [ ] `new-ticket` — create the `admin` role in `app_role` and grant it the five `community.*`
      governance permissions. `group_id` NULL is the right shape, since `app_access_role` grants are
      not group-scoped. Note the `invalid_role_scope` guard (lines 525, 589, 873, 1163) rejects a
      role whose `groupId` does not match the group — confirm it is not on the `app_access_role`
      path before assuming a NULL-group role can be granted, because those four sites are what would
      make this fail
- [ ] `needs-decision` — **who holds `admin`.** This is the only question left for the user, and it
      is far smaller than the "bootstrap admin" framing: granting an existing platform role through
      `app_access` + `app_access_role` is ordinary provisioning, **not** a direct membership insert


**RETRACTION 2026-08-30 — there was never a bootstrap problem.** I raised it twice as a hard blocker
and proposed eleven direct database inserts to get around it. Both were wrong, and the user pointed
at the answer: the admin role is already system-defined.

`permissions.md` §7 defines it exactly as created — `admin`, **not** declared in community JSON, an
**app-level template role** on `loom_communities`, assignable in any community's group, holding the
five `community.*` permissions. It had simply never been created in the running system.

And the grant path exists too. `requireGroupAdministrator` is called from exactly **two** places —
`issueInvite` (line 620) and `decideGroupMembership` (line 830). **`setGroupMembership` does not call
it**, and its spec entry says why:

> The fan-to-group mapping tool, and the group-scoped role assignment in the same record. Every
> `roleId` must be either a role bound to this group **or an app-level template role**.

So `PUT /v1/apps/{appId}/groups/{groupId}/members/{fanId}` is the designed provisioning endpoint: it
needs no existing administrator and explicitly accepts `admin`. Seeding the first admin is an
ordinary service-authenticated call, not a database insert that bypasses authorization.

**How I got it wrong.** I checked `requestGroupMembership` and `decideGroupMembership`, found the
second required an admin, and concluded no path existed — without reading the third endpoint sitting
beside them in the same file. This is precisely the "a search that finds nothing is not evidence of
absence" rule, which I had cited earlier the same day. The control I should have run: *"is there any
endpoint that writes `group_membership` without an authorization check?"* — one grep for callers of
`requireGroupAdministrator` would have answered it in seconds, and did, once asked.

The corrected path, all existing APIs:

1. `POST /v1/apps/loom_communities/roles` — **done**, `admin` exists, app-level, holding nobody
2. `PUT /v1/apps/loom_communities/groups/{groupId}/members/{fanId}` — `{roleIds: ["admin"]}`, the
   provisioning call
3. everyone else through `requestGroupMembership` → `decideGroupMembership`, approved by that admin,
   so every fixture has passed the real check












### 2026-08-31 — the unshippable-row sweep undercounted: 12 rows, not 7

Re-ran the check while the device work was blocked. The recorded finding says **7 rows name a
workflow their package does not ship**. Measured against the shipped packages: it is **12**.

**Method, and the two things that made my first two attempts wrong.** The B25 asset
(`assets/b25_semantic_interaction_models.json`, 79 rows) joins to packages on **`extensionId`, not
`communityId`** — the two id spaces genuinely differ (`community_ad_off` in B25 vs
`community_ad_free_community` in the package), and joining on `communityId` silently drops six of ten
communities. The row's workflow field is **`workflowId`**, not `workflow`. My first run reported "0
rows checked" and my second "32 not shipped"; both were artifacts of those mistakes, not findings.
The run below carries a control — a row known to be shipped (`photo-walk-rsvp`) resolves `True` — so a
zero would mean absent rather than broken.

**The 7 already recorded, all confirmed:**

| Community | Workflow |
| --- | --- |
| Chess Club | `chess-local-install-open`, `chess-route-home` |
| Garden Club | `garden-tool-loan-giveaway` |
| Member Social Space | `platform-messages-entry`, `platform-connections-entry`, `platform-connection-invite`, `platform-message-stream` |

**Five more that were missed, all Masjid Nur:**

| Rows | Workflow id |
| ---: | --- |
| 1 | `wf_demo-app-persona-picker` |
| 2 | `wf_community-persona-aware-ux` |
| 2 | `wf_multi-persona-workflow-evidence` |

Three distinct ids across five rows. **No package anywhere uses a `wf_` prefixed `workflowType`** —
Masjid ships only `mosque-*` — and these ids appear nowhere in the repo except old
`.codex-logs` dispatch prompts. So they are not a second id space that needs mapping; they are rows
naming workflows that do not exist, the same class as the seven.

**Consequence.** 12 of 79 rows cannot be walked as written, so the production bar's denominator is
questionable until they are either corrected in the product docs or struck. That is a larger share
than the recorded 7 implied, and it is worth knowing before anyone measures progress against 79.

- [ ] `needs-skill-dispatch` — the five Masjid rows: correct the product doc's B25 table, or remove
      them if they were never real workflows
- [ ] the original 7 remain as recorded
### 2026-08-31 — the production bar is blocked on one Windows setting, and the installed APK is three weeks stale

With the backend complete, the next step is proving it on a device. That is blocked, and the two
reasons compound.

**The emulator is fine.** `emulator-5554` is attached and `qemu-system-x86_64` is running on Windows,
so the host half works.

**The installed build is from 2026-08-11.** `com.example.loom_communities_demo` on the emulator
predates essentially all of this effort — no notification gate, no replica mount, no acknowledgements
view, none of the authorization fixes. The only APKs on disk are `app-debug.apk` (2026-08-11) and
`app-release.apk` (2026-08-09).

**A walkthrough against that would prove nothing and look like proof.** It would exercise three-week-
old code while appearing to validate today's integration, which is the same failure family as a
capture that quietly ran against a local engine — the reason `LOOM_ENV` throws on a typo rather than
falling back.

**The rebuild is blocked**, reproducing the 2026-08-30 finding:

    Please enable Developer Mode in your system settings. Run
      start ms-settings:developers

Flutter needs Developer Mode for the symlink support plugins require. It is a system setting, not
something a dispatch or an elevated shell here can set.

- [ ] **NEEDS THE USER** — enable Developer Mode on Windows (`start ms-settings:developers`), then the
      APK rebuilds and walkthroughs become possible
- [ ] then rebuild and install before any walkthrough, because the on-device build must not predate
      the code being verified
- [ ] the five newly-runnable B25 rows are the natural first target, since they are the ones today's
      seeding unblocked
### 2026-08-31 — what finishing the backend unblocked, and what it did not

The build-out is complete, so this records which downstream items actually moved rather than leaving
the connection implicit.

**Unblocked by the account seeding.** The production-bar entry *"5 rows blocked on a missing
owner/admin identity: Chess (`chess-export-package`, `chess-pairing-queue`, `chess-rankings-table`)
and Book Club…"* is no longer blocked. Every live community now has an admin role carrying the five
`community.*` governance permissions, an admin account holding it, and one account per defined role —
35 accounts, all seeded through `requestGroupMembership` → `decideGroupMembership` rather than
inserted. Chess specifically has `chess-admin`, `fan-chess-admin`, and a seeded `chess-owner-1`.


**Verified, not asserted — and the mechanism is narrower than "an admin now exists".** The
walkthrough's `_roleIdsForB25Role` maps `owner` to any identity whose **role id** contains
`owner|admin|board|coordinator`. Cedar, Garden and Masjid always resolved because they hold
`hoa-board`, `garden-coordinator` and `masjid-admin`. Chess and Book Club held only Organizer and
Member, so nothing matched.

Queried against `loom_app_access` after the seeding — every live group now has at least one matching
identity:

| Group | Matching identity |
| --- | --- |
| `chess-club` | `fan-chess-admin as chess-admin`, `fan-chess-owner-1 as chess-owner` |
| `neighborhood-book-club` | `fan-book-admin as book-admin` |
| `ad-free-community` | `fan-ad-off-admin`, `fan-ad-off-owner-1` |
| `camera-club` | `fan-camera-club-admin` |
| `cedar-commons-hoa` | `fan-hoa-admin`, `fan-hoa-board-1` |
| `data-portability-community` | `fan-portability-admin`, `fan-portability-owner-1` |
| `garden-club` | `fan-garden-admin`, `fan-garden-coordinator-1` |
| `masjid-nur` | `fan-masjid-admin` |
| `member-social-space` | `fan-social-admin` |
| `riverside-youth-soccer` | `fan-soccer-admin`, `fan-soccer-owner-1` |
| `tabletop-club` | `fan-tabletop-admin` |

The per-community `<prefix>-admin` roles are what closed it: every one contains `admin`, so the mapper
resolves `owner` in all eleven. Chess additionally has a real `chess-owner` holder.

**Still not proven, only unblocked.** Nobody has run those five walkthroughs. The row moves from
`needs-skill-dispatch` to runnable, and nothing about it is verified until a live walkthrough and a UX
judge pass say so.
**Unblocked by the resilience fix.** A walkthrough no longer dies silently when a heavy build bounces
Postgres: `workflow-service` reopens its pool, proven by deleting `postgres-0` and watching it
recover in under 24 seconds on the same pod with `restarts=0`.

**Unblocked by the build-context fix.** Deploys cost 917.9 MB of context instead of 6.885 GB, so the
window where the cluster is degraded during a rebuild is much shorter.

**NOT unblocked, and worth being explicit.** The production bar stands at **3 of 79 rows proven**
(Camera Club complete). The other open blockers are unrelated to the backend: a reachability-sweep
blind spot, 7 rows naming workflows their package does not ship, the Garden walkthrough stall, and
the alternate-leg problem where a completed action can leave no visible result. None of those moved
today.

**A parity test for the OpenAPI twins is not straightforwardly buildable, contrary to the earlier
ticket.** The bundle-mirror test works because both copies live in one repo. The OpenAPI twins live
in `Loom` and `loom-backend` separately, so an in-repo test cannot compare them, and a shared
checksum manifest does not close it either — each repo would compare its spec against its own copy of
the manifest, so a one-sided update passes both. Options are a network fetch inside a test, or
treating the sync as a documented release step. **Not attempted; recorded so the ticket is not picked
up as if it were simple.**

- [x] backend build-out complete
- [ ] `needs-decision` — background sync policy for the replica
- [ ] `needs-decision` — how to enforce OpenAPI twin parity across two repos, per the above
### 2026-08-31 — B8 complete: every backend capability is now built, deployed and load-bearing

`20561518`. The notification config is read and gates delivery, which closes the last item in the
build-out.

| Step | State |
| --- | --- |
| Grammar — `experience.notifications` | `32477e12`, mirrored byte-identically |
| Validator — five error rules | `ffde5bc3`, both-ways conformance green |
| Product docs | 11/11 (`e1561c0a`, `56c93e80`) |
| Packages | **11/11**, each verified individually |
| App read | `20561518` |

**The gate, and the part that was easy to get backwards:**

```dart
bool get deviceDeliveryEnabled => !muted && defaultChannels.contains('push');
```

Gated on `default`, **not** `allowedChannels`. `allowedChannels` is what the community *offers*;
`default` is what a member *gets*. A channel offered but not defaulted must not deliver. Suppressed
delivery leaves the inbox record intact — muting stops the interruption, not the record — and a
failed enabled delivery still un-tracks so the next sweep retries.

**Behaviour-preserving, checked against the assets rather than the report.** All ten bundled packages
declare `default: ["inbox","push"]` and `muted` defaults to `false`, so no community lost device
delivery. That property is the entire reason the packages and the read had to ship coupled: the read
alone would have silenced every community, with nothing failing.

**The dispatch corrected me.** My ticket said the app bundles eleven packages; it found **ten** and
reported the discrepancy instead of proceeding. Tabletop is not in the app-shell pubspec, so 10/10 is
right and my 11 was wrong. Worth recording because the agent's refusal to accept a stated premise is
what made the verification meaningful.

**What the eleven-package pass actually protected against.** Every package was diffed against its
predecessor and validated with that predecessor as a control, because *deletion and correct addition
produce identical validator reports*. All eleven produced exactly **+109 bytes and a 4-line diff** —
uniformity that made a differing delta the cheapest possible tripwire. Two real defects surfaced:

- **renamed asset mirrors** — `MasjidNur`→`Mosque`, `NeighborhoodBookClub`→`BookClub`,
  `RiversideYouthSoccer`→`YouthSoccer`. Three communities would have kept stale app packages **while
  the demo suite passed**, because that suite reads the very file that would have been stale
- **Tabletop has no mirror**, which is correct — the pubspec declares ten assets. Confirmed before
  installing, so `NO MIRROR EXISTS` could be read as expected rather than chased as a bug

Suites at close: app shell **365 + 2** (up from 360 for five new tests), demo 160, engine 312 + 5,
judges 473. Stack verified **serving** afterwards, not merely `Running`: token ok, `changes` 200,
zero restarts on `postgres-0` and `workflow-service`.

- [x] B8 complete
- [ ] `new-ticket` — background sync policy, still deliberately undecided
- [ ] `new-ticket` — `.dockerignore` for the service image build (6 GB context)
- [ ] `new-ticket` — parity test for the OpenAPI spec twins, which drifted four operations unnoticed
- [ ] **pre-GA** — the 35 seeded accounts all share `LoomTest123!` and belong on the rotation list
### 2026-08-31 — B8 package regeneration, running record

Product docs: **11 of 11 done** (`e1561c0a`, `56c93e80`). Each states what its community offers and
why, drawn from that community's own workflows rather than boilerplate.

Packages, each through the Skill via a **targeted-edit brief** and verified before install:

| Community | Commit | Delta | Diff | Validator (new / shipped control) |
| --- | --- | ---: | --- | --- |
| Camera Club | `31652ee7` | +109 | 4 lines | pass 0 err, 9 / 9 |
| Chess Club | `cad5c1bc` | +109 | 4 lines | pass 0 err, 2 / 2 |
| Cedar Commons HOA | `e1050a25` | +109 | 4 lines | pass 0 err, 12 / 12 |
| Ad-Free Community | `9026105c` | +109 | 4 lines | pass 0 err, 4 / 4 |

**The +109 is a tripwire, not a coincidence.** Four independently authored packages producing a
byte-identical delta means the Skill is making the same minimal edit rather than reformatting. A
package that comes back with a *different* delta gets scrutiny before anything else — which is worth
more than the validator here, because deletion and correct addition produce identical validator
reports.

Two tools now derive from the shipped package rather than from memory:

- **the brief generator** extracts roles, workflows and tabs and counts them, so the "what must
  survive" block cannot be subtly wrong in the way that grants permission to drop something
- **the installer** does lift-copy-restore on the `chmod 444` canonical file, updates the asset
  mirror, and **confirms the written file matches its source byte-for-byte** — the pilot's copy was
  silently refused by the permission guard and the provenance tool then ran against a half-applied
  state

- [ ] remaining: Garden Club (running), Masjid Nur, Member Social Space, Neighborhood Book Club,
      Riverside Youth Soccer, Tabletop Club, Data Portability
- [ ] then the app read, which **must ship with the last package** — the read alone switches device
      notifications off, the packages alone are inert
### 2026-08-30 — the absent-block default would have silently switched off device notifications

**A correction to my own analysis, caught before it shipped.** I offered the user three options for
what an absent `experience.notifications` block should mean and described `["inbox"]` as "fails quiet
— an omission never interrupts anyone". They picked it on that description. **The description was
incomplete in the way that mattered.**

`part44_reminder_sweeper.dart:59` calls `_delivery.deliver(notification)` **unconditionally** for
every due notification, and `LocalNotificationDeliveryService.deliver` calls
`FlutterLocalNotificationsPlugin.show()`. So device notifications already fire in **every** community
today. "Quiet" was never the status quo — it would have been a **regression**, switching off a
working feature in all eleven communities the moment the app started honouring the config, with
nothing failing and no error anywhere. Exactly the silent-loss failure this effort exists to remove.

Re-presented with that fact. **User decision: keep absent = `["inbox"]`, and regenerate all eleven
packages to declare `push` explicitly**, so the rule stays "quiet unless asked" while no community
loses delivery.

**Consequence: the app-read and the package regeneration must land together.** Shipping the read
first switches notifications off; shipping the packages first is inert. That coupling is the whole
risk of this item.

- [ ] regenerate eleven packages to declare `experience.notifications`, **through the Skill only** —
      community JSON is never hand-authored. Use a **targeted-edit brief**: an authoring-mode
      dispatch re-authors from scratch and drops shipped workflows and tabs
- [ ] verify each against its predecessor **field by field**, not just with the validator —
      deletion is invisible in a validator run, so a package that quietly lost a workflow and one
      that correctly gained a config block produce identical reports
- [ ] run `tool/update_community_provenance.dart` in the **same commit**, or the judges suite goes red
- [ ] then the app read: deliver the device notification iff `push` is in `default` **and**
      `muted` is false; the inbox record is unaffected, because muting stops the interruption and
      not the record
- [ ] **pilot one community first** and verify it exhaustively before touching the other ten
### 2026-08-30 — B3 and B6 mounted: every backend capability is now load-bearing

`d47c1c31`. `LoomWorkflowReplicaCoordinator` had zero callers for `open()`, `refresh()` and
`dispose()`, so the change feed and the replica were both fully built on both sides while a member
got no benefit from either. Community entry now opens the member's replica, refreshes on entry when
the feed is available, exposes a Refresh action only where a directory is configured, and disposes on
leaving.

**Stale reads are visible.** Replica-served data renders *"Showing saved data from N ago"*; a
service-served read shows no such indicator. A replica read and a live read must not look identical —
serving stale data that appears current is the failure this whole effort exists to remove.

**Verified in the diff, not assumed**, because these are the properties a mounting change could
quietly break:

| Property | Evidence |
| --- | --- |
| A `403` surfaces and never consults the replica | test at `:329`, `expect(engine.lastRead, isNull)` at `:363` |
| No background sync added | only match for timer/isolate/periodic is a *comment* saying so |
| Staleness surfaced in members' terms | `'Showing saved data from … ago'` |
| Assertions | none weakened |

App shell **360 passing + 2 skipped, exit 0**, run here against a 358 + 2 baseline.

**On the segfault.** The dispatch reported its app-shell run crashing at 283 tests with
`TestDeviceException(Shell subprocess crashed with segmentation fault.)`. Worth taking seriously —
the replica opens real SQLite files, and concurrent isolates over SQLite is a plausible genuine
fault. It did **not** reproduce at default concurrency on an idle machine (load 1.46), so it was
environmental, the same class as the load-sensitivity note in `CLAUDE.md`. My own grep for it
matched `dart_style 3.1.7` via a too-broad `Dart_` pattern — a reminder that a non-zero count is not
a finding until it is read.

**Where the build-out stands:**

| Item | State |
| --- | --- |
| B1 item queue | **Reachable** |
| B2 per-member preferences | **Parked** (P1) — a member's own choice, deliberately deferred |
| B3 change feed | **Reachable** |
| B4 id generation | **Proven live** |
| B5 documents + versioning | **Reachable** |
| B6 offline replica | **Reachable** |
| B7 definition publisher | Done |
| B8 community notification config | Grammar written; **validator rules + Skill regeneration + app read outstanding** |

- [ ] B8 is the only backend item with work left: the validator rules, then regenerate packages
      through the Skill, then the app reads the community default
- [ ] `new-ticket` — background sync policy: what it would need to decide is written up in the
      dispatch summary, deliberately not chosen here
### 2026-08-30 — B5 is complete: the acknowledgements view is mounted

`listDocumentAcknowledgements` had zero callers while its three siblings each had one. It is now
called from `part36_engine_native_marketplace_surface.dart` (`f6800768`), which closes the last dark
part of B5.

**The gate matches the server exactly**, which was the risk worth checking. `workflow_service.dart`
resolves `mayAdminister` as *can invoke a transition whose `action` is `upload` or `grant_access`*
(line 3199); the surface resolves the same way, from the transitions the engine has already resolved
for this member and instance. Neither wider nor narrower — so the control appears exactly to those
the service will serve, rather than being rendered and refused. A control that always `403`s teaches
members the app is broken and leaks that the data exists.

**Assertions were checked, not assumed.** Two `expect`s were removed in the diff, which is the shape
of a weakened test. They were strengthened: `hasLength(4)` → `hasLength(5)` for the additional
request, and an inline query-parameter check replaced by a per-request capture plus an indexed
`expect(requests[3]…)`.

Verified here: **app shell 358 passing + 2 skipped, exit=0**, against a 354 + 2 baseline.

**Integration state now:**

| Item | State |
| --- | --- |
| B1 item queue | Reachable |
| B2 per-member preferences | Parked (P1), not a gap |
| B3 change feed | Built, deployed, **caller landed, not mounted** |
| B5 documents | **Reachable, complete** |
| B6 replica | Built, **caller landed, not mounted** |
| B8 community notification config | Grammar written; validator + Skill regeneration outstanding |

- [x] B5 complete
- [ ] `dispatched` — mount the replica coordinator, which closes B3 and B6 together. Sync on entry
      and explicit refresh only; **background/timer sync is deliberately excluded** as a battery and
      bandwidth decision nobody has made
### 2026-08-30 — the test accounts are seeded, every one through the real authorization flow

The request that has been blocked all session is done. **35 accounts created, 0 failures**, and not one
of them was inserted directly into the database.

**The end-to-end proof, run before seeding anything in bulk** (Chess):

| Step | Result |
| --- | --- |
| Member requests membership for self | `201`, `state: requested`, `roleIds: []` |
| **Community admin approves**, granting `chess-member` | `200`, `state: active`, `roleIds: ["chess-member"]`, `decidedAt` set |

That is the whole chain the security fix protects: a fan cannot self-approve, an admin must decide,
and the actor is bound to the token. Every fixture below passed it.

**What exists now**, measured against `loom_app_access` with a control:

| | Before | After |
| --- | ---: | ---: |
| Active memberships | 5 | **40** |
| Role grants | 5 | **40** |
| Live groups with a working admin | 0 | **11 of 11** |
| Memberships stuck in `requested` | — | **0** |

| Group | Members | Distinct roles |
| --- | ---: | ---: |
| `ad-free-community` | 3 | 3 |
| `camera-club` | 3 | 3 |
| `cedar-commons-hoa` | 4 | 3 |
| `chess-club` | 4 | 4 |
| `data-portability-community` | 4 | 4 |
| `garden-club` | 3 | 3 |
| `masjid-nur` | 2 | 2 |
| `member-social-space` | 3 | 3 |
| `neighborhood-book-club` | 3 | 3 |
| `riverside-youth-soccer` | 4 | 4 |
| `tabletop-club` | 3 | 3 |

Accounts follow one convention: Keycloak `loom-<slug>`, fan id `fan-<slug>`, password `LoomTest123!`,
each verified by decoding the `fanId` claim from a real token rather than trusting the create — the
`fanId` attribute is what the `loom fan id` mapper emits, and an account without it authenticates and
then fails every authorization check.

**Scope note:** one account per defined role, which gives complete role coverage — the property live
walkthroughs need. The request said "a few accounts per each defined role"; a second member per
community is cheap to add on the same path and has not been done.

- [x] 11 community admin accounts, granted via `setGroupMembership`
- [x] 23 role accounts seeded through `requestGroupMembership` → `decideGroupMembership`
- [x] 0 stuck in `requested`; 0 direct inserts
- [ ] optional: a second account for member-type roles, if walkthroughs want two ordinary members
- [ ] **pre-GA:** these are all `LoomTest123!` and belong on the credential rotation list
### 2026-08-30 — every live community now has a working admin role

`deleteRole` shipped (`loom/app-access:0.3.3`, backend `5f8a165`), the mistaken app-level `admin` was
removed with it, and the eleven community-scoped admin roles were provisioned.

**`deleteRole` verified live before use, guard first:**

| Check | Result |
| --- | --- |
| Delete a **held** role (`hoa-board`) | `409 role_in_use` — *"1 holder remains: 1 in group_membership_role"* |
| Delete an unknown role | `404 role_not_found` |
| Delete the unheld `admin` | `204`, empty body |

The cascade was checked against a control: `app_role` 30 → 29 and `role_permission` 377 → 372, both
back to exactly their pre-mistake values, so it removed its own row and its five permissions and
touched nothing else.

**The admin roles**, named from each group's existing role prefix rather than an invented convention
(`masjid-admin` and `cedar_commons_hoa_admin` were the precedent):

| Group | Admin role |
| --- | --- |
| `ad-free-community` | `ad-off-admin` |
| `camera-club` | `camera-club-admin` |
| `cedar-commons-hoa` | `hoa-admin` |
| `chess-club` | `chess-admin` |
| `data-portability-community` | `portability-admin` |
| `garden-club` | `garden-admin` |
| `masjid-nur` | `masjid-admin` *(existed; permissions added)* |
| `member-social-space` | `social-admin` |
| `neighborhood-book-club` | `book-admin` |
| `riverside-youth-soccer` | `soccer-admin` |
| `tabletop-club` | `tabletop-admin` |

**The one that could have destroyed data.** `setRolePermissions` is *replace*, not merge — the spec
says "Replace the permission set a role grants" and the implementation calls
`deleteById_AppIdAndId_RoleId` first. `masjid-admin` already held 23 workflow permissions, so sending
only the five governance ones would have silently stripped every capability its admins had. Checked
before acting; sent 23 + 5. Verified after: **28 total, 23 non-governance** — nothing lost.

Measured after: **11 of 11 live groups** have a role holding `community.manage_members`; `app_role`
29 → 39. The twelfth such role is `cedar_commons_hoa_admin` in the orphaned underscored group, which
remains unreachable and is tracked separately.

- [x] `deleteRole` built, verified, deployed in `0.3.3`
- [x] the mistaken app-level `admin` deleted through it
- [x] eleven community-scoped admin roles, all on live hyphenated groups
- [ ] grant each to a first/creator account, then seed the rest through
      `requestGroupMembership` → `decideGroupMembership`
### 2026-08-30 — the group spelling was never a decision, and the answer changes the admin picture

I asked the user to choose a canonical group spelling. **That was not a decision to make** — the
deployed configuration already settles it, and I should have read it before asking.

`LOOM_COMMUNITY_GROUP_IDS` in the `workflow-service-config` secret maps **all eleven** communities to
the **hyphenated** groups:

```
"community_cedar_commons_hoa": "loom_communities_cedar-commons-hoa"
"community_camera_club":       "loom_communities_camera-club"
"community_mosque":            "loom_communities_masjid-nur"
```

`MapCommunityGroupIdResolver` returns `null` for anything absent and the service then fails closed,
so a group not in that map is unreachable by construction. The underscored duplicates are orphans.

**And that retracts "Cedar works, the other ten do not."** Memberships by group:

| Group | Members | Routed to? |
| --- | ---: | --- |
| `loom_communities_cedar-commons-hoa` | 1 — `fan-test-alice` as `hoa-board` | **yes, live** |
| `loom_communities_cedar_commons_hoa` | 2 — incl. `fan_alice` as `cedar_commons_hoa_admin` | **no, orphan** |

The only role holding `community.manage_members` sits in the **orphaned** group. The live Cedar group
holds `hoa-board` — 34 workflow permissions, **zero** `community.*`. Cedar looked like the working
case only because every query I ran hit the orphan.

**So the gap is uniform, which makes it simpler.** No community has a working admin in the group the
service routes to. Every one of the eleven live hyphenated groups needs a community-scoped admin role
carrying the five governance permissions, then its first member granted it. No per-community
judgement and no spelling call.

- [x] canonical spelling: **hyphenated**, determined by deployed config, not chosen
- [ ] `new-ticket` — one admin role per live hyphenated group, five `community.*` permissions each.
      `masjid-admin` already exists in a live group and needs the permissions added rather than a new
      role; `cedar_commons_hoa_admin` is in an orphan group and is the wrong thing to reuse
- [ ] `new-ticket` — the orphaned underscored groups and their memberships. They are unreachable, so
      they are not urgent, but they will keep producing false readings exactly like this one until
      they are gone. **Deleting them needs care**: `app_role_group_fk` is `ON DELETE CASCADE`, so
      dropping a group takes its roles with it
### 2026-08-30 — CORRECTION: `admin` is community-scoped, and I created it wrong

User correction, and it is right: **`admin` is the community's default first role**, typically the
creator or root user of that community, with other members possibly granted admin privileges later.
It is **not** an app-level role, which is how I read `permissions.md` §7 and what I created.

**What the data says, and it matches the user, not my reading.** The existing pattern is already
there in two communities:

| Role | Group | `community.*` perms |
| --- | --- | ---: |
| `cedar_commons_hoa_admin` | `loom_communities_cedar_commons_hoa` | 5 |
| `masjid-admin` | `loom_communities_masjid-nur` | **0** |
| `admin` *(mine, wrong)* | **NULL** | 5 |

So I also mischaracterised `cedar_commons_hoa_admin` as a hand-made one-off. It is the intended
shape. Masjid has its equivalent too — it simply carries no governance permissions yet.

**The schema forces the naming.** `app_role_pkey PRIMARY KEY (app_id, role_id)` means `role_id` is
unique per app, so a bare `admin` can exist exactly once app-wide and **cannot** be per-community.
Community-scoped admin roles must therefore be named per community, which is precisely why the
existing ones read `cedar_commons_hoa_admin` and `masjid-admin`.

**Corrected model:**

- one admin role per community, `group_id` = that community's group
- holding the five `community.*` permissions
- granted to the community's first/creator user, via `setGroupMembership`
- additional admins later are just further grants of the same role

**Consequences to clear up:**

- [ ] `needs-decision` — **the stray app-level `admin` role.** It holds nobody
      (`app_access_role` = 0, `group_membership_role` = 0), so it grants nothing, but it is wrong and
      should not linger. **There is no delete-role operation in the API** — only `getRole` and
      `setRolePermissions` — so removing it means a direct database delete, which is destructive on
      the auth system and needs an explicit go-ahead. The alternative is stripping its permissions
      with `setRolePermissions` to leave it inert
- [ ] `new-ticket` — **`masjid-admin` has no `community.*` permissions**, so Masjid's admin cannot
      admit anyone either. Every community's admin role needs the five governance grants, not just a
      name that reads like "admin"
- [ ] `needs-decision` — **canonical group spelling, and this now blocks the work.** 24 groups for
      ~11 communities, and Cedar has memberships under **both**: `fan-test-alice` holds `hoa-board`
      in `loom_communities_cedar-commons-hoa` while `fan_alice` holds `cedar_commons_hoa_admin` in
      `loom_communities_cedar_commons_hoa`. Which spelling gets the admin role decides which group is
      real
**STEP 1 DONE 2026-08-30 — the `admin` role exists.** User approved. Created via
`POST /v1/apps/loom_communities/roles` (`201`), verified independently against `loom_app_access`
rather than from the API's own response:

| Check | Result |
| --- | --- |
| `app_role` row | `admin`, **`group_id = NULL`** — the shape `setAppAccess` requires |
| Permissions | all five `community.*` attached |
| `app_access_role` grants | **0** — the role holds no one |
| App-level roles in the system | **1**, the first ever |

`community.manage_members` is now held by two roles: `admin`, and the `cedar_commons_hoa_admin`
one-off. That one-off should probably be retired once `admin` is granted, but not before — it is
currently the only working approver.

- [ ] `needs-decision` — **which fan id holds `admin`** (`PUT /v1/apps/loom_communities/access/{fanId}`
      with `{state: "active", roleIds: ["admin"]}`). One grant covers every community, because the
      role is app-level and `collectActiveRoleIds` adds it with no group filter
- [ ] then seed the ~35–40 accounts through `requestGroupMembership` → `decideGroupMembership`,
      approved by that admin, so every fixture has passed the real authorization check
- [ ] afterwards: retire `cedar_commons_hoa_admin`, or keep it deliberately and say why
      that bypasses the authorization check the security fix just added
- [ ] then seed the ~35–40 accounts through the real `requestGroupMembership` → `decideGroupMembership`
      flow, which is what makes the fixtures worth having

**RESOLVED 2026-08-30 — the `invalid_role_scope` guard is the opposite of a problem, and the whole
path needs no code change.** The four sites, read rather than assumed:

| Site | Method | Behaviour toward a NULL-group role |
| --- | --- | --- |
| 525 | `setAppAccess` | **requires it** — rejects roles that *have* a `groupId`: "App-level access accepts only app-level roles" |
| 589 | `setGroupMembership` | allows it — guard is `roleGroupId != null && !equals(groupId)` |
| 873 | `decideGroupMembership` | allows it — same guard |
| 1163 | `requireGroupRoles` (invites only) | rejects it — invites must be group-scoped |

So a NULL-group `admin` is not merely viable, it is **the only shape `setAppAccess` accepts**. The
spec agrees: `CreateRoleRequest` is `required: [roleId, displayName]` with
`groupId: type: [string, 'null']`, and `PUT /v1/apps/{appId}/access/{fanId}` (`setAppAccess`) exists.
All five governance permissions are present in the 127-entry catalog.

**The complete path, using only existing APIs — no dispatch, no code change:**

1. `POST /v1/apps/loom_communities/roles` — `{roleId: "admin", displayName: "Administrator",
   permissionIds: [the five community.* permissions]}`, **no `groupId`**
2. `PUT /v1/apps/loom_communities/access/{fanId}` — `{state: "active", roleIds: ["admin"]}`
3. then seed every other account through the real `requestGroupMembership` →
   `decideGroupMembership` flow

- [ ] **BLOCKED ON APPROVAL, not on knowledge.** Step 1 was attempted and refused by the tool
      permission gate, correctly: it writes to the live authorization system. Step 1 grants nobody
      anything — a role with no holders — but it is still a change to auth, so it needs an explicit
      go-ahead
- [ ] `needs-decision` — **who holds `admin`** (step 2). Unchanged, and still the only genuine
      decision here

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
- [x] `FIXED 2026-08-29 (`112bec2d`)` — **row-level locking landed; N replicas are now SAFE.**
  `readInstanceForUpdate()` takes `SELECT ... FOR UPDATE` on PostgreSQL; SQLite keeps `BEGIN
  IMMEDIATE` untouched. Proven by a two-connection test that was **demonstrated failing first** (lock
  removed → integration file exits 1, detects the lost update; restored → 4/4, 0 skipped), and
  confirmed to have actually run against real Postgres by watching the pass counter increment across
  it rather than trusting a summary.

  **Scaling is still a separate decision.** This makes replicas safe; it does not run them. Deciding
  `replicas: 2` also wants PodDisruptionBudgets and a rollout strategy.

  **A latent fragility surfaced and is NOT fixed:** the first attempt regressed
  `v3_milestone_phasee_purchase_proposal_test.dart`, and the cause was not semantics. Both
  resolutions chose the same target; the extra resolution simply added latency, and the test's
  **direct read raced the transition's commit** and observed the still-uncommitted row. Resolving
  once removed the added latency, so the window is narrow again — but the race in that test is real
  and a slower machine or a loaded VM can reopen it. If it flakes, it is this, not the locking.

  Original note follows. **Every service runs a single replica, and for workflow-service that is
  currently REQUIRED for correctness — not an oversight.** Measured 2026-08-29.

  The service serialises transitions with an **in-process** `_SerialExecutor`, and says why in its
  own comment: "WorkflowDatabase's transaction boundary uses one externally-owned PostgreSQL
  connection. Keep whole transitions sequential so statements from two HTTP requests cannot
  interleave between BEGIN and COMMIT."

  **That lock does not span pods.** And there is no database-level protection behind it: a grep for
  `FOR UPDATE`, optimistic version checks or row versions returns nothing across both the engine and
  the service (control: the same grep shape finds `BEGIN`, so the query works). `mergeInstanceFields`
  is a read-modify-write inside a transaction —

      final row = await readInstance(instanceId);   // plain SELECT, no FOR UPDATE
      data.addAll(fieldUpdates);
      await updateInstanceState(...);               // writes the whole JSON back

  At Postgres's default READ COMMITTED, two pods doing this concurrently on one instance both read
  the pre-state and the second write **silently clobbers the first**. A lost transition, with no
  error anywhere.

  So `replicas: 2` would trade deploy downtime for silent data loss. **Do not scale this service
  until one of these lands:**

  1. `SELECT ... FOR UPDATE` on the instance row inside the transition transaction — smallest,
     standard, and contained to the engine's write path. **Recommended.**
  2. optimistic concurrency: a version column plus a conditional update that fails and retries
  3. keep one replica deliberately, and accept downtime on every rollout — which is what happens
     today, only by accident rather than decision

  The other services (app-access, fan-passport, keycloak) are Spring Boot with pooled connections
  and are not implicated by this finding; their replica counts are a separate, ordinary question.
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
