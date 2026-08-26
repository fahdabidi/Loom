# App Access is provisioned for one community, under a different id space

**Date:** 2026-08-25
**Cluster:** k3s on the Loom VM, all five `loom` pods `1/1` (app-access, fan-passport,
keycloak, postgres, workflow-service)
**Method:** direct HTTP calls to the deployed App Access service via NodePort 30080,
authenticated with the same `loom-workflow-service` client-credentials token the workflow
service itself uses. Every quoted response below is text the service emitted about itself.

## Why this was looked at

Item 1c established that the workflow service never resolves a fan's role. The obvious
next step was to wire role resolution in. Before writing that, I checked whether the
thing it would resolve *against* actually holds the roles — because a fix that resolves
correctly against an empty or mismatched store would look finished and still deny
everything.

It does not hold them. Two separate blockers came out of it, both of which would have
survived a "successful" 1c.

## Finding 1 — the community-to-group map is empty, so nothing can be created

The deployed workflow service reads `LOOM_COMMUNITY_GROUP_IDS` from the
`workflow-service-config` secret. Its value is, in full:

    {}

`MapCommunityGroupIdResolver.resolveGroupId` returns `null` for every community id
against that map. `workflow_service.dart:398-415` then does this, before App Access is
consulted at all:

```dart
final groupId = await _communityGroupIdResolver.resolveGroupId(communityId);
if (groupId == null || groupId.trim().isEmpty) {
  return _error(
    request: request,
    statusCode: 503,
    code: 'authorization_service_unavailable',
    message: 'Workflow creation authorization is unavailable.',
  );
}
```

So **every create-instance request against the deployed service returns 503**. This is
the concrete reason every live community returned `{"items":[],...}` when queried, and
the reason item 1b ("create an instance, then confirm queryInstances returns it") could
not be run. The earlier reading — that 1b just needed test data authored — was wrong:
the service cannot create an instance for any community, with any data.

Note this fails *closed*, which is correct behaviour for an unresolvable group. The
defect is the empty configuration, not the guard.

## Finding 2 — App Access has one real community, under different role ids

`GET /v1/apps` returns exactly one app:

    {"items":[{"appId":"loom_communities","displayName":"Loom Communities",
     "status":"active","permissionCatalogVersion":"2026-08-13.1",
     "createdAt":"2026-08-13T20:19:14.789166Z"}],...}

The real appId is `loom_communities`, with underscores.

`GET /v1/apps/loom_communities/groups` returns three groups, only one of which is a real
community:

| groupId | what it is |
|---|---|
| `loom_communities_cedar_commons_hoa` | Cedar Commons HOA — the only real community |
| `loom_communities_b3-e2e-1786833477749221-856954` | throwaway "Workflow B.3 test" group |
| `loom_communities_b3-e2e-1786833499047237-857472` | throwaway "Workflow B.3 test" group |

**Nine of the ten communities have no App Access group at all.**

`GET /v1/apps/loom_communities/roles` returns four roles, and this is the part that
matters most:

| App Access `roleId` | group |
|---|---|
| `cedar_commons_hoa_admin` | `loom_communities_cedar_commons_hoa` |
| `cedar_commons_hoa_member` | `loom_communities_cedar_commons_hoa` |
| `b3-event-creator-1786833477749221-856954` | b3-e2e test group |
| `b3-event-creator-1786833499047237-857472` | b3-e2e test group |

Cedar's shipped package guards name entirely different ids:

    "roleId": "hoa-member"
    "roleId": "hoa-board"
    "allowedRoleIds": ["hoa-board"]     (x14 in the package)
    "allowedRoleIds": ["hoa-member"]    (x5 in the package)

These are two different id spaces. `cedar_commons_hoa_member` vs `hoa-member` is a
prefix-and-separator difference that a normalisation rule could just about bridge — but
`cedar_commons_hoa_admin` vs `hoa-board` cannot be bridged by any rule, because `admin`
and `board` are simply different words.

**This is the trap.** Had 1c landed on its own, role resolution would have worked
perfectly, returned `cedar_commons_hoa_admin`, registered it with the engine, and every
`allowedRoleIds: ["hoa-board"]` guard would still have failed — now with a plausible-
looking real role instead of an obvious sentinel, which is strictly harder to diagnose.

## The fix, and why this particular one

**Provision App Access with the package `roleId` verbatim.** No mapping table, no
normalisation rule, no translation layer in the service.

This was checked before being chosen rather than assumed. Role ids across all eleven
shipped packages:

| package | role ids |
|---|---|
| AdFreeCommunity | `ad-off-member`, `ad-off-owner` |
| CameraClub | `camera-club-organizer`, `camera-club-member` |
| CedarCommonsHOA | `hoa-member`, `hoa-board` |
| ChessClub | `chess-organizer`, `chess-member`, `chess-owner` |
| DataPortabilityCommunity | `portability-owner`, `portability-member`, `portability-receiving-provider` |
| GardenClub | `garden-member`, `garden-coordinator` |
| MasjidNur | `masjid-admin`, `community-member` |
| MemberSocialSpace | `member`, `moderator` |
| NeighborhoodBookClub | `book-member`, `book-organizer` |
| Phase1_TabletopClub | `tabletop-organizer`, `tabletop-member` |
| RiversideYouthSoccer | `soccer-guardian`, `soccer-coach`, `soccer-owner` |

Checked for collisions across the whole set: **zero duplicates.** Package role ids are
already globally unique, so App Access can adopt them as its own ids with no risk of two
communities claiming one role id — and roles are group-scoped there anyway, so the
guarantee is belt-and-braces.

The package JSON is upstream of everything else by standing project rule, so making the
store match the package keeps one source of truth. A mapping table would be a second one,
and it would drift the first time a package added a role.

Provisioning should therefore be **derived from the shipped packages**, not hand-created:
for each package, create the group, create each declared role with the package's own
`roleId`, and emit the resulting community-to-group mapping as the JSON that fills
`LOOM_COMMUNITY_GROUP_IDS`. That one script closes both findings at once, and re-running
it after a package changes keeps the store honest.

## One incidental detail worth keeping

App Access rejects a non-UUID correlation id:

    HTTP 400
    {"code":"invalid_request","message":"Invalid value for X-Loom-Correlation-Id",
     "details":[{"target":"X-Loom-Correlation-Id",
                 "reason":"Expected type class java.util.UUID"}]}

The workflow service already validates inbound `x-loom-correlation-id` against a UUID
pattern and forwards it unchanged, so it complies today. This is recorded so that any new
App Access call added later forwards the request's id rather than inventing one.

## Status

- Finding 1 tracked as TODO item **1d**
- Finding 2 tracked as TODO item **1e**
- The engine's one-role-per-fan limit, found in the same pass, is item **1f** and is
  folded into the 1c implementation dispatch as Part 1

## Addendum — who may create a workflow, measured across all 95 workflows

The provisioning plan needs a `.create` permission per workflow, and the packages never
state creation authority directly. The first rule I wrote down was an inference from
reading **one** package (Cedar): "grant create to the roles guarding transitions out of
`initialState`". That is the same shape of mistake this project has been caught by
before — a sweep validated against one kind of case — so it was checked against all 11
packages and all 95 workflows before being built on.

It holds for **84 of 95**. The 11 exceptions are not noise, and classifying them turned
the fallback from a guess into a derived rule:

| case | count | rule |
|---|---|---|
| Role-guarded transition out of `initialState` | 84 | those roles get `.create` |
| Only ever produced by a `createInstance` effect | 7 | **nobody** gets `.create` |
| Neither | 4 | package never says — spec gap |

**The 7 system-created ones** — `notification`, `book-notification`,
`garden-notification`, `soccer-reminder-notification`, `mosque-neutral-notification`,
`tournament-vote`, `mosque-donor-visibility` — are each produced by another workflow's
`createInstance` effect. A person never calls the create endpoint for them; the engine
creates them server-side while applying a transition, so no App Access create check ever
runs. Granting a role permission to create one would be inventing an authority that
nothing exercises.

**The 4 remaining ones are a real gap in the packages:**

| package | workflow |
|---|---|
| CameraClub | `critique-submission` |
| GardenClub | `plant-exchange-submission` |
| MasjidNur | `mosque-donation-payment` |
| MasjidNur | `mosque-care-request` |

A person creates each of these — nothing creates them by effect — but no package states
who is allowed to. Worth noting that `critique-submission` is one of the three Camera
Club rows already counted as proven against the local engine, which is exactly how a gap
like this stays invisible: the local engine never consulted App Access, so creation
authority was never asked for.

Provisioning grants all declared roles for those four as a deliberate stopgap, marked
`"creationAuthority": "unstated"` in the plan so it cannot be mistaken for a decision.
The real fix is a spec decision about whether packages should state creation authority
explicitly — escalated rather than silently resolved, since community JSON is authored
only by the Skill.

## Addendum 2 — applying the plan found a third blocker in the same chain

Applied the derived plan against the live cluster 2026-08-25. Groups succeeded: **11
created**, and the pre-existing `loom_communities_cedar_commons_hoa` was matched rather
than duplicated, which is the idempotency claim holding up under a real run.

Roles then failed on the first attempt:

    POST /v1/apps/loom_communities/roles -> HTTP 400
    {"code":"unknown_permission_id",
     "message":"Unknown permission ids: payment_checkout.create",
     "details":[{"target":"permissionIds",
                 "reason":"All permission ids must already exist in the app catalog"}]}

App Access requires every permission id a role references to exist already in the app's
**permission catalog**. Provisioning never registered any.

### A wrong turn worth recording

My first reproduction of that 400 omitted the `Idempotency-Key` header, got
`missing_request_parameter`, and I briefly recorded that as the root cause. It was not —
the applier does send that header on every mutating call. **My probe was missing a header
the real client sends, so I was diagnosing my own curl rather than the applier.** Re-running
the probe with the same headers the applier uses produced the actual error above. A
reproduction is only evidence if it reproduces the real caller's request.

### The measurement

| | count |
|---|---|
| Catalog holds | 69 |
| Plan needs | 65 |
| Overlap | 31 |
| **Missing from catalog** | **34** |
| Catalog entries the plan never uses | 38 |

The 34 missing include **every `.create` id** — `payment_checkout.create`,
`document_library.create`, `equipment_loan.create`, `export_wizard.create`,
`approval_queue_item.create`, `notification_inbox.create`, `search_ai_answer.create`,
`status_timeline.create`, `table.create`.

That is the part that matters. `workflow_service.dart:385-415` gates creation on
`resolver.permissionId(family, 'create')` — exactly `<prefix>.create`. Not one of those
exists in the catalog, so **creation could never have been authorised even after roles
were provisioned.** The catalog's own vocabulary is different in kind: it carries
`payment_checkout.pay`, `.view`, `.refund`, `.view_receipt`,
`notification_inbox.send`, `.dismiss`, `.mark_read`, `status_timeline.advance`. It was
authored 2026-08-13 independently of the packages.

This is the same shape as Finding 2, one layer down: two independently-authored
vocabularies for the same concept. Resolved the same way and for the same reason — the
packages are upstream of the store, so the catalog is extended to hold what the packages
need. Adding permissions is additive and safe; bending package vocabulary to match a
separately-authored catalog would not be. The 38 unused catalog entries are left alone.

## Addendum 3 — only 55% of transitions declare an `action`

Found while checking whether the deriver was under-deriving permissions. It was not; two
apparent anomalies were the deriver being faithful to its inputs:

- `ad-off-member` derived a single permission because **AdFreeCommunity declares no
  `action` on any of its 53 transitions**, so no per-action permission is derivable.
- `portability-member` derived none because it guards no transition out of `initialState`
  — its four appearances are in `visibility.readGuard`, not transition guards. (I initially
  read those as transition guards from a raw grep; they are not.)

Measured across all 11 packages:

| package | transitions | with `action` | |
|---|---|---|---|
| AdFreeCommunity | 53 | 0 | **none** |
| MemberSocialSpace | 27 | 0 | **none** |
| ChessClub | 38 | 10 | 26% |
| MasjidNur | 69 | 24 | 34% |
| RiversideYouthSoccer | 74 | 33 | 44% |
| CedarCommonsHOA | 74 | 40 | 54% |
| Phase1_TabletopClub | 48 | 35 | 72% |
| NeighborhoodBookClub | 68 | 50 | 73% |
| CameraClub | 34 | 26 | 76% |
| GardenClub | 46 | 39 | 84% |
| DataPortabilityCommunity | 80 | 80 | 100% |
| **total** | **611** | **337** | **55%** |

No functional impact today, because the workflow service enforces only `<prefix>.create`
and never a per-transition permission. Recorded because it is a live trap: if permission
enforcement is ever extended to transitions, AdFree and MemberSocialSpace have no
derivable permissions at all and would fail closed on every action, which would read as a
product bug rather than a missing `action` field.

## Addendum 4 — CORRECTION: this was built in the wrong place, and 1g was wrong

Two dispatches produced a client-side deriver and applier that read the packages, derived
role permissions, and wrote groups, roles and catalog entries to App Access. That was the
wrong design, and `docs/references/reference/permissions.md` says so explicitly:

> **Where this runs.** In the **App Access service**, via
> `POST /v1/apps/{appId}/community-installations`. **Not in the client, and not in the
> authoring toolchain.**

That endpoint exists and is implemented on the deployed service
(`AppAccessController.installCommunityPackage`). One call per community performs the whole
operation: create the group, register the roles, derive the permissions, grant them.

I found this only after the applier failed three times in a row. Each failure was diagnosed
correctly and each fix was locally reasonable, but the sequence should have prompted the
question earlier: **when a component keeps hitting walls that a service-side API would not
have, check whether the work belongs on the other side of the boundary.** The spec had said
so all along, in a file already sitting in the repo.

### What was wrong, precisely

1. **The permission catalog cannot be written the way the applier tried.**
   `/v1/apps/{appId}/permissions` supports **GET and PUT only** — PUT being
   `replacePermissionCatalog`, which replaces the *whole* catalog. The deployed service
   answers POST with a 500 (`HttpRequestMethodNotSupportedException`) rather than a 405,
   which is a server bug in its own right but not the cause.

2. **The derived plan contained 4 permission ids that do not exist in the vocabulary**:
   `document_library.create`, `equipment_loan.create`, `export_wizard.create`,
   `search_ai_answer.create`. All four are **bespoke** archetypes, and bespoke archetypes
   carry a fixed action list with no `create` in it. The client-side rule invented them.

3. **The create-permission rule I specified was wrong.** permissions.md step 6 is:
   "For each `create` action's `byRoleIds`, add the archetype's `create` permission."
   I had specified "the roles guarding transitions out of `initialState`" — a plausible
   inference, measured carefully across all 95 workflows, and still wrong, because it
   measured the wrong field.

4. **Item 1g is RETRACTED.** It claimed four workflows "never say who may create them."
   They do: creation authority is `byRoleIds` on create actions, and every shipped package
   declares them — 2 to 11 per package, 70 across the corpus, including all four workflows
   I named. The finding was an artifact of looking at transition guards.

   Worth being precise about why that one slipped through: the sweep behind 1g *was*
   validated across all 11 packages and all 95 workflows, which is the discipline this
   project keeps insisting on. Breadth did not help, because every reading looked at the
   same wrong field. **Validating a sweep against many cases does not validate the sweep's
   premise** — for that, the spec has to be read.

### The authoritative permission set

`docs/references/generated/permissions-vocabulary.json` defines **97** permission ids and
is GENERATED from `archetype_resolver.dart` by
`app/packages/tooling/loom_ux_judges/bin/generate_permissions_vocabulary.dart`, explicitly
so that "the derivation rules defined in permissions.md exist in exactly one place." It is
consumed by both the Dart validator and the Java App Access installer.

The deployed catalog holds 69, of which 26 are not in the vocabulary and **54 vocabulary
ids are missing**. The backend's own copy of the vocabulary file differs from the Loom
repo's by exactly one id (`event_rsvp.deliver_reminder`), so a stale file is not the
explanation — the deployed catalog was seeded from something older than either. Left
alone deliberately: catalog reconciliation is its own decision, and a partial PUT would
silently delete the 26 entries the packages do not use.

### What survives

The group creation from the first run stands — 11 groups exist with the right ids, and
installation is idempotent over them. The package loading and archetype resolution survive.
The error-body surfacing added by the second dispatch earned its keep immediately: it is
the only reason the 500 above was diagnosable at all.

Items 1d and 1e are unaffected in substance — the group map is still empty and the role id
spaces still differ. What changed is the mechanism that closes them: one install call per
community, not a client-side reimplementation.

## Addendum 5 — it works: 9 of 11 communities installed, and why it took four attempts

The stale image was the wall. `loom/app-access:0.2.0` predated the endpoint's
implementation and answered `501 installCommunityPackage is not implemented yet`, while
the source has implemented it since `a96c184` (2026-08-15) and contains no such string.
Rebuilt as `loom/app-access:0.3.0`, imported into k3s containerd, manifest bumped, rolled
out. That is the third time in this session I called something "implemented" after
checking a proxy for it rather than the thing that runs — first a curl missing the real
client's headers, then a controller instead of a running binary. **Verify against the
artifact that actually executes.**

With the real service running, three further gates fell in order, each one only visible
after the previous cleared:

1. **`payment_checkout.advance/create/terminate` unknown.** The server derives
   paymentCheckout as a **generic** archetype (create/advance/terminate/view) while the
   deployed catalog held a bespoke-era `pay`/`refund`/`view_receipt`. Resolved by
   reconciling the catalog — see below.
2. **`equipment_loan.create` unknown.** See "the vocabulary gap" below; this one is a real
   inconsistency, not stale data.
3. **`cardSurfaceFamily must not be null`** for `tournament-vote` and `notification`, the
   only 2 of 95 workflows with no render bindings of their own. permissions.md step 3d
   already covers them — "a workflow with no bindings and no responseTable owner derives
   nothing at all" — so they must be omitted from the request rather than sent as null.
   Fix dispatched.

### The catalog was reconciled by UNION, not replace

The only write is `PUT` = replace-the-whole-catalog, so this needed care. Replacing with
the vocabulary's 97 would have **deleted 26 ids the packages do not use**, including
`community.manage_members`, `community.invite`, `community.manage_roles` and
`community.manage_settings` — app-level permissions not derived from any archetype, one of
which the existing `cedar_commons_hoa_admin` role actually holds.

So the PUT carried the **union**: 69 existing preserved byte-for-byte, 54 vocabulary ids
added, **0 deleted**. Verified after the write: 127 present, `payment_checkout.create`
present, `community.manage_members` still there. That answers item 1k, and the answer is
union rather than replace, for a concrete reason rather than caution.

### A real vocabulary gap, not stale data

`permissions.md` step 6 says "For each `create` action's `byRoleIds`, add the archetype's
**create** permission", and the server's deriver does exactly that. But the generated
vocabulary defines `.create` for only some archetypes:

| kind | has `.create` |
|---|---|
| all 7 generic archetypes | yes |
| bespoke `event-rsvp`, `votePoll` | yes |
| bespoke `documentLibrary`, `equipment-loan`, `exportWizard`, `searchAiAnswer` | **no** |

Those four are exactly the ids flagged earlier as "invented by the client-side rule". They
were not invented — the derivation rule genuinely requires them, and the shipped packages
declare create actions for those families. **The generated vocabulary is missing them**,
which means `archetype_resolver.dart`'s bespoke action lists are. Added to the catalog to
unblock (127 total), and filed as **1l** to fix at the source, since the vocabulary exists
precisely so these rules live in one place.

### Result

Nine communities installed with package-verbatim role ids and server-derived permissions:

    hoa-board            34 permissions      hoa-member           20
    masjid-admin         23                  community-member     21
    garden-coordinator   21                  garden-member        11
    camera-club-organizer 18                 camera-club-member   11
    chess-organizer      16                  chess-member          8
    chess-owner           7                  portability-owner    10
    member                8                  moderator             4
    ad-off-member         3                  ad-off-owner          3
    portability-receiving-provider 5         portability-member    0

`portability-member` at 0 is expected and already understood: it guards no transition and
appears only in `visibility.readGuard`. It is what `rolesWithNoPermissions` is for.

Remaining: Neighborhood Book Club, Riverside Youth Soccer and Tabletop Club, all behind
the `cardSurfaceFamily` fix.

### One piece of cruft to clean up

The server derives `groupId` from `communityHandle`, so installation created
`loom_communities_cedar-commons-hoa` (hyphens). My earlier client-side applier had created
`loom_communities_cedar_commons_hoa` (underscores) from the community **id**. Those 11
earlier groups are now orphaned duplicates holding no roles. They are inert, but they
should be removed once installation is complete — and the `LOOM_COMMUNITY_GROUP_IDS` map
must be built from the **server-returned** groupIds, not from the earlier plan, or every
community will resolve to an empty group.
