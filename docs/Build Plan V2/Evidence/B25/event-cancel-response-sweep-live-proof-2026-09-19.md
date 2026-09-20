# Live proof — cancelling an event sweeps its response rows (`workflow-service:1.0.8`)

**Date:** 2026-09-19 (UTC 2026-09-20T00:07–00:09)
**Community:** Garden Club (`community_garden_club`)
**Workflows:** `garden-event-rsvp` (parent), `garden-event-rsvp-response` (response table)
**Deployed image:** `loom-workflow-service:1.0.8`, pod started `2026-09-19T23:29:46Z`
**Engine hook under test:** `_sweepEventRsvpResponseRows`, commit `2e29b792`
**Package:** `Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc`,
`skillVersion 3.6.0`, `sha256 e82a8b39015268dba34e2782bb81613e247fa7c7f7e94e402a80309c5b439d97`
**Deployed definition version:** 4 (both `garden-event-rsvp` and `garden-event-rsvp-response`)

---

## Verdict, stated exactly

**PROVEN at the service/engine boundary.** A freshly created event was cancelled against the
deployed `workflow-service:1.0.8`, and both of its response rows left their distinct non-terminal
states (`going`, `maybe`) for `cancelled` in the same write. Before-and-after reads were taken from
Postgres in one session, with negative controls.

**NOT PROVEN: the UI path.** The cancel was driven through the deployed HTTP API with real
Keycloak-authenticated bearer tokens, **not** through a tap in the app. The Android emulator was
unreachable from this dispatch (see *Blocked* below). Per `CLAUDE.md`, an API-driven proof
"proves the service boundary, not that any UI path reaches it — a different claim wearing similar
evidence." That second claim remains open and needs a device walkthrough.

---

## Identities — real tokens, verified claims

Both obtained from `http://192.168.56.10:30082/realms/loom/protocol/openid-connect/token`
(client `loom-test-client`, password grant), and each decoded to confirm the `fanId` claim before
any write. No login form was bypassed and no credential was created or reset.

| Keycloak user | `fanId` claim | HTTP |
|---|---|---|
| `loom-garden-coordinator-1` | `fan-garden-coordinator-1` | 200 |
| `loom-garden-member-1` | `fan-garden-member-1` | 200 |

Role authority comes from the deployed definitions: `cancel-event` is guarded
`allowedRoleIds: ["garden-coordinator"]`, and the create action is `byRoleIds: ["garden-coordinator"]`
— so the coordinator both created and cancelled, which is what the package requires.

---

## Setup

| Step | Actor | Result |
|---|---|---|
| `POST /v1/communities/community_garden_club/instances` | `fan-garden-coordinator-1` | 201 — event `community_garden_club_garden-event-rsvp_p8pjguzd6hgx`, state `open` |
| platform fan-out on create | — | two response rows materialized, both `pending` |
| `POST .../instances/<member row>/transitions` `respond-going` | `fan-garden-member-1` | 200 — `pending` → `going` |
| `POST .../instances/<coord row>/transitions` `respond-maybe` | `fan-garden-coordinator-1` | 200 — `pending` → `maybe` |

Two **different** non-terminal states, which is the point: a sweep handling only one state would
look correct against two identical rows.

---

## BEFORE the cancel — control read (`2026-09-20T00:09:02Z`)

    instance_id                                                   | workflow_type              | current_state | created_at    | updated_at
    community_garden_club_garden-event-rsvp_p8pjguzd6hgx          | garden-event-rsvp          | open          | 1789862923886 | 1789862923886
    community_garden_club_garden-event-rsvp-response_r85wqeo84nhq | garden-event-rsvp-response | going         | 1789862924034 | 1789862932506
    community_garden_club_garden-event-rsvp-response_j7k789hq1mn8 | garden-event-rsvp-response | maybe         | 1789862924034 | 1789862935213

Both response rows have `updated_at > created_at`, so each had a **real transition**, not a bare
insert. Without this read a sweep that did nothing would be indistinguishable from one with nothing
to do.

## THE CANCEL (`2026-09-20T00:09:06Z`)

`POST /v1/communities/community_garden_club/instances/community_garden_club_garden-event-rsvp_p8pjguzd6hgx/transitions`
body `{"transitionId":"cancel-event"}`, as `fan-garden-coordinator-1` → **HTTP 200**, `currentState: "cancelled"`.

## AFTER the cancel — read (`2026-09-20T00:09:13Z`)

    instance_id                                                   | workflow_type              | current_state | created_at    | updated_at
    community_garden_club_garden-event-rsvp_p8pjguzd6hgx          | garden-event-rsvp          | cancelled     | 1789862923886 | 1789862946807
    community_garden_club_garden-event-rsvp-response_r85wqeo84nhq | garden-event-rsvp-response | cancelled     | 1789862924034 | 1789862946807
    community_garden_club_garden-event-rsvp-response_j7k789hq1mn8 | garden-event-rsvp-response | cancelled     | 1789862924034 | 1789862946807

### Before → after, per row

| Instance | Fan | Before | After |
|---|---|---|---|
| `..._garden-event-rsvp_p8pjguzd6hgx` | created by `fan-garden-coordinator-1` | `open` | `cancelled` |
| `..._garden-event-rsvp-response_r85wqeo84nhq` | `fan-garden-member-1` | **`going`** | **`cancelled`** |
| `..._garden-event-rsvp-response_j7k789hq1mn8` | `fan-garden-coordinator-1` | **`maybe`** | **`cancelled`** |

**All three `updated_at` values are identical — `1789862946807` (`2026-09-20T00:09:06.807Z`).** The
parent and both response rows were written at the same instant, which is the observable signature of
the sweep running inside the parent's existing transaction, as `2e29b792` describes. Two rows in
different states converged on the response workflow's own `event-cancelled` transition
(`from: [pending, going, maybe, declined, waitlisted] → cancelled`).

### Corroboration from the service's own read projection

`responses` / `responseCounts` / `goingCount` are computed at read time (they are absent from the
stored `instance_data`), so they are an independent view of the same fact. Re-read after the cancel
via `GET /v1/communities/community_garden_club/instances?workflowType=garden-event-rsvp` as
`fan-garden-coordinator-1`:

    event state: cancelled
      row ...j7k789hq1mn8  fanId=fan-garden-coordinator-1  state=cancelled
      row ...r85wqeo84nhq  fanId=fan-garden-member-1       state=cancelled
      goingCount: 0   responseCounts: {"cancelled": 2}

`goingCount` is **0** and `responseCounts` is `{"cancelled": 2}` — the cancelled event no longer
advertises a live RSVP, which is the product outcome the hook exists to produce.

---

## Negative controls

1. **The pre-fix pair is still stale and was NOT retroactively touched.** Event
   `..._garden-event-rsvp_gwrvhmw1ztbk` (`cancelled`, `updated_at 1789220951913`) still has response
   row `..._garden-event-rsvp-response_g45yq8qnsj95` sitting at **`going`**, `updated_at`
   unchanged at `1789220907924` (2026-09-12). It was cancelled before the hook existed. This is the
   before-picture the ticket names, and it confirms the sweep is scoped to the event being
   cancelled rather than sweeping broadly.
2. **An uninvolved open event was untouched.** `..._garden-event-rsvp_4g0ny4uut0ay` (created
   `2026-09-20T00:07:24Z` during this session) remained `open` with `updated_at` unchanged.

---

## Blocked — the UI half

The instrumented/remote-wired APK on `emulator-5554` could not be reached from this dispatch. The
emulator lives on the Windows host; from the VM, **no port on `192.168.56.1` accepts a connection**:

    192.168.56.1:22    closed/filtered      192.168.56.1:5554  closed/filtered
    192.168.56.1:5037  closed/filtered      192.168.56.1:5555  closed/filtered
    192.168.56.1:3389  closed/filtered

The host itself pings (0% packet loss), so this is the Windows adb server listening on loopback only
rather than a down host. `adb -H 192.168.56.1 -P 5037` — the documented VM→Windows recovery — timed
out. The VM has no AVD (`~/.android/avd` empty, no `qemu-system-x86_64`), and `CLAUDE.md` forbids
recreating one.

To finish the UI half, the Windows adb server needs to be listening on the host-only interface
(`adb -a nodaemon server`, or an `adb.exe` started so port 5037 is reachable from `192.168.56.10`).
Nothing about the engine hook needs re-proving — only that a tap in the app reaches it.

---

## Side observation — fan-out is scoped to fans the cached engine has seen (NOT the ticket's subject)

Recorded because it cost a cycle here and may mislead a later reader; **it is an observation, not a
traced diagnosis.**

The first event created in this session (`..._4g0ny4uut0ay`, the first request after the pod's
23:29:46Z start) received **zero** response rows. The second (`..._p8pjguzd6hgx`), created after
both fans had each issued a `GET /instances`, received **two** — one per fan.

Consistent with the code: `_fanOutEventRsvpResponseRows` iterates `_roleIdsByFanId.keys`, and
`workflow_service.dart` populates that map via `setRolesForFan` **only for the requesting identity**,
on a per-community engine cached across requests. So the fan-out population is "fans that have made
a request since the pod started", not "members of the community". The older event
`..._gwrvhmw1ztbk` likewise carries exactly one response row.

Whether that is intended is not established here and was not investigated further — it is
independent of the cancel sweep, which is what this manifest proves.

---

## Reproduction

    PW=$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
    PGPASSWORD="$PW" psql -h 127.0.0.1 -p 15432 -U loom -d loom_workflow_service \
      -c "select instance_id, workflow_type, current_state, created_at, updated_at \
          from workflow_instances where workflow_type like 'garden-event-rsvp%' order by created_at;"
