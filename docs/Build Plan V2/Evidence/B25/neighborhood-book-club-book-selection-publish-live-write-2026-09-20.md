**Workflow:** `book-selection-publish` in Neighborhood Book Club
**Outcome:** Both halves of the proof standard were met — signed in as `fan-book-organizer-1`, the previously-invisible `draft` card rendered on the Admin tab and its `Publish announcement` action was tapped through the real UI, driving instance `...qsyoqyf6su57` to the terminal state `published`, independently confirmed in Postgres.

**Package identity:** `Loom_Communities_Workflow_Engine_BookClub_Example.jsonc`
- `"skillVersion": "3.6.0"`
- `sha256 = 71e1f0688b7dffd1b29cb90a1066998f003abdf920523cac8dcb535837726957`

**Date:** 2026-09-20 (device 00:51–00:54 PDT = 07:51–07:54 UTC)

---

## Why this row was re-driven

A previous walkthrough drove this same row and correctly recorded it as **NOT proven**: the
instance persisted in `draft`, every call returned `200`, and **no card rendered for anyone —
including its own creator**, so `publish-announcement` had nothing to tap. The cause was a
platform defect: the remote instance projection omitted creator identity, so the client decoded
every instance with `createdByFanId: ''`, and a binding whose only audience is `actor` (which
falls back to the creator) matched nobody.

The fix (`8d33a8af`, shipped in `loom-workflow-service:1.0.9` plus the client half in the APK) had
been verified **at the service boundary only**. This run's entire purpose was to establish the
remaining, unproven claim: **that the card now renders and the action is tappable on the device.**

I drove **the existing draft**, not a new instance — deliberately, because it is the same row that
previously rendered for nobody, which makes it a stronger proof than a fresh instance would be.

## Identity

| | |
|---|---|
| Account | `loom-book-organizer-1` |
| Fan id | `fan-book-organizer-1` |
| Role | `book-organizer` (app shell showed "Signed in as Book Organizer 1 / Organizer") |

**Disclosed honestly: I did not type the password.** The app carried a stored session for this
account (it was reinstalled with `adb install -r`, which preserves app data), so selecting
"Book Organizer 1" at the community entry gate signed in with no Keycloak form. Per CLAUDE.md a
cached `currentSession` is a *selection*, not a token, so I did not treat the green sign-in screen
as proof of identity. Three independent facts establish that the token was real and belonged to
`fan-book-organizer-1`:

1. **It is a live remote token.** Every engine call logged
   `LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/
   scope=ext_neighborhood_book_club outcome=ok status=200 error=-` — no `authentication_required`,
   no `401`. A cached selection without a token cannot produce a `200` from the remote engine.
2. **The render itself is an identity proof.** The draft's only binding is
   `audience: "actor"`, which resolves to the creator `fan-book-organizer-1`. Had I held any other
   fan's token, the card could not have rendered at all.
3. **The write landed under the right fan.** `created_by_fan_id` on the mutated row is
   `fan-book-organizer-1`, and the service enforces the transition guard
   `allowedRoleIds: ["book-organizer"]`.

## Baseline, measured in this session before touching anything

The brief's hint ("about **1** rows") was stale for the table total and correct for the type:

- `select count(*) from workflow_instances` → **97** rows (not ~1).
- `where workflow_type='book-selection-publish'` → **exactly 1** row, the earlier run's draft.

Pre-existing row, before any action by me:

```
instance_id       | community_neighborhood_book_club_book-selection-publish_qsyoqyf6su57
created_by_fan_id | fan-book-organizer-1
current_state     | draft
created_at        | 1789884566078   (2026-09-20T06:09:26Z)
instance_data     | {"selectedBookTitle":"Piranesi B25 Sep19","audience":"All members",
                     "message":"B25 live write Sep19"}
```

I distinguish my work by **instance id and `updated_at`**, not by any change in row count — the
count is unchanged at 1, because I advanced an existing instance rather than creating one.

## The path I drove

1. Launched the app. Launch screen showed **"Loaded 10 example communities"**, confirming the
   preload flag is compiled into this build (APK installed 2026-09-20 00:49:23 PDT, i.e. the
   rebuild carrying the client half of the fix).
2. Tapped **Neighborhood Book Club** → community entry gate identity picker.
3. Selected **Book Organizer 1** (`fan-book-organizer-1`) → "Signed in as Book Organizer 1 /
   Organizer", 2 available community roles.
4. Tapped the **Admin** tab — this is where `book-selection-publish` binds
   (`tabId: "admin"`, `audience: "actor"`, `cardSurfaceFamily: "formEntry"`).
5. Scrolled down. **The card rendered.** This is the finding this run existed to establish.
6. Tapped **Publish announcement**.

### What the card showed (the load-bearing observation)

The `formEntry` card rendered fully, for its creator, with:

- state badge **Draft**
- `Selected Book Title: Piranesi B25 Sep19`
- `For: All members`
- `Scheduled At:` *(empty)*
- `Message: B25 live write Sep19`
- `Save changes` — disabled, "No changes to save yet"
- **`Preview announcement`** — present
- **`Publish announcement`** — present, enabled, primary tone

Before tapping, I confirmed the on-screen card was the same instance as the DB row by matching
`instance_data` (`selectedBookTitle`, `audience`, `message`) — not by position on screen.

**`Schedule later` was absent, and that is correct, not a defect.** Its guard is
`formula: "if(scheduledAt == null, false, true)"` and `scheduledAt` is genuinely absent from the
stored `instance_data`. That is an unsatisfied precondition, exactly as the ticket anticipated.

## Half 1 — live UI result

After the tap, the `formEntry` card was replaced by the `statusTimeline` summary binding showing
**Published** in positive/green tone, with no action buttons (correct: `published` is
`isTerminal: true`).

Additionally — and beyond the minimum bar — the published announcement now also renders on the
**Home** tab as a `notificationInbox` summary card (`Published` / `Piranesi B25 Sep19` /
`For All members` / `message`). That is the third binding,
`{ states: ["published"], audience: "any", tabId: "home" }`. So **all three render bindings
declared for this workflow now behave correctly**, where previously the `actor`-audience one
rendered for nobody.

No ANR or crash dialog: `dumpsys window lastanr` reported `<no ANR has occurred since boot>`, and
logcat contained no `FATAL EXCEPTION`.

## Half 2 — independent DB confirmation, same session

```
PW=$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" psql -U loom \
  -d loom_workflow_service -c "select ... from workflow_instances \
  where workflow_type='book-selection-publish';"
```

```
instance_id       | community_neighborhood_book_club_book-selection-publish_qsyoqyf6su57
workflow_type     | book-selection-publish
created_by_fan_id | fan-book-organizer-1
current_state     | published
created_at        | 1789884566078   (2026-09-20T06:09:26Z)
updated_at        | 1789890810158   (2026-09-20T07:53:30Z)
instance_data     | {"selectedBookTitle":"Piranesi B25 Sep19","audience":"All members",
                     "message":"B25 live write Sep19",
                     "publishedAt":"2026-09-20T07:53:30.158921Z"}
```

## Do the two halves agree?

**Yes, and on four independent points:**

| | UI | Postgres |
|---|---|---|
| State | `Published` badge, terminal, no actions | `current_state = published` |
| Instance | `Piranesi B25 Sep19` / `All members` / `B25 live write Sep19` | same three `instance_data` fields |
| Identity | signed in as Book Organizer 1 | `created_by_fan_id = fan-book-organizer-1` |
| Time | tapped at device 00:53:30 PDT | `updated_at` = 2026-09-20T07:53:30Z |

The declared effect of `publish-announcement` —
`{ "op": "set", "key": "publishedAt", "value": "$timestamp" }` — **fired and persisted**. That
matters beyond the state change: it shows the engine executed the authored transition, rather than
the state merely being flipped. Per CLAUDE.md's "a tap that returned is not a transition that
happened", the tap was not treated as proof; the stored postcondition is.

## Defects observed

**None.** Specifically, none of the four failure shapes the ticket asked me to discriminate
occurred: the card was not absent, the action was not absent, the action was not disabled, and the
state did persist. The platform defect that caused the earlier run's failure is confirmed repaired
**on the UI path**, which is the claim that was previously unproven.

No transition was fired through the API. Every state change came from a real tap on the device.

## Environment

| | |
|---|---|
| workflow-service | `loom-workflow-service:1.0.9` (cluster `1/1 Running`) |
| app-access | `0.3.10` |
| APK | installed 2026-09-20 00:49:23 PDT, `POST_NOTIFICATIONS` granted |
| Device | `emulator-5554` on the Windows host, via the existing tunnel (plain `adb`) |
| Engine mode | `mode=remote`, `http://192.168.56.10:30083/`, all calls `status=200` |

## Scope note

I changed no application code, no community JSON, and no tracker — this commit adds only this
manifest. No test suites were run, because nothing was built or modified that any suite covers;
the deliverable here is the live walkthrough and its confirmation.
