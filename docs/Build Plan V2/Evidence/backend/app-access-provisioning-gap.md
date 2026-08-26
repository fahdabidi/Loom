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
