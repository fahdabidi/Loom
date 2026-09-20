# B25 live-write evidence — Neighborhood Book Club `book-selection-publish` — **PARTIAL / BLOCKED**

**Workflow:** `book-selection-publish` in Neighborhood Book Club
**Outcome:** **Not fully proven.** A real row WAS created live through the real UI and confirmed in Postgres, but the workflow could **not** be advanced past its initial `draft` state, because no surface in the shipped app renders the draft — so `publish-announcement` has no affordance to tap. The row is real; the terminal state was never reached.

(The success phrase is deliberately absent from this file, including from any quotation, because
`check_b25_status.sh` matches it with a case-insensitive grep anywhere in the manifest. A partial
run must not be counted as a proof.)

**Package identity:** `Loom_Communities_Workflow_Engine_BookClub_Example.jsonc`
- `skillVersion`: `3.6.0`, `specVersion`: `4`
- `sha256`: `71e1f0688b7dffd1b29cb90a1066998f003abdf920523cac8dcb535837726957`
- The locked reference copy `docs/references/communities/Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc` is `cmp`-identical to the app-shell asset driven here.

## Identity

- Keycloak account **`loom-book-organizer-1`**, fan id **`fan-book-organizer-1`**, role **`book-organizer`** (Organizer).
- Proven three independent ways, not assumed:
  1. The app's own "Account role and permissions" sheet read **"Signed in as Book Organizer 1 … ID: fan-book-organizer-1"**, with **Organizer** selected.
  2. A password-grant token request against `loom-test-client` returned HTTP 200 with claims `fanId=fan-book-organizer-1`, `preferred_username=loom-book-organizer-1`.
  3. The row the run produced carries `created_by_fan_id = fan-book-organizer-1` — the authoritative record of whose token wrote it.
- No credential was created or reset. `loom-book-member-1` was never used.

## Baseline — measured, not trusted

Queried before touching the device:

- `book-selection-publish` rows: **0**.
- Control, so an empty result means absent rather than a broken query: five other `book-*` types were present (`book-discussion-message`, `book-meeting-rsvp`, `book-meeting-rsvp-response`, `book-nomination`, `book-vote`, 1 row each).
- Whole table: **96** instances. The brief's hint of "about 0 rows" was right for this type and wrong for the table; the type-scoped number is the one used here.
- `workflow_definitions` carries `book-selection-publish` at **version 4** (all 12 `book-*` types at version 4), so the unpublished-type failure mode does not apply.

## What was driven

1. Book Club → **Admin** tab (package-gated `visibleRoleIds: ["book-organizer"]`, and visible).
2. Create FAB → offered **"New export"** and **"New announcement"**; tapped **New announcement**.
3. Filled `Selected Book Title` = `Piranesi B25 Sep19`, `For` = `All members`, `Message` = `B25 live write Sep19`. `Scheduled At` was left empty **deliberately**, so `schedule-announcement` is correctly withheld by its `formula: "if(scheduledAt == null, false, true)"` guard. That is the designed precondition, not a defect.
4. **Create** → the dialog closed and the instance was written.

### The row

    instance_id        community_neighborhood_book_club_book-selection-publish_qsyoqyf6su57
    community_id       community_neighborhood_book_club
    workflow_type      book-selection-publish
    created_by_fan_id  fan-book-organizer-1
    current_state      draft
    created_at         1789884566078  (2026-09-20 06:09:26 UTC)

Distinguished by its own instance id and `created_at`, not by a change in the row count.

**Stored values match what was typed, with no truncation** — checked against the row rather than the screen, because `adb shell input text` truncates silently:

    {"selectedBookTitle":"Piranesi B25 Sep19","audience":"All members","message":"B25 live write Sep19"}

So the UI and the database agree on everything the creation step claimed.

## Where it stopped

**The `draft` renders on no surface, so `publish-announcement` cannot be tapped.**

Swept every tab in the community as the signed-in organizer — Home, Calendar, Marketplace, Admin, Books, Documents, Discussions — scrolling each to its end. The announcement appears on none of them. The Admin tab, which is the only tab the package binds `draft` to, shows its header, the tab description, "Local package details" and the create FAB, and no instance card. This survived a **full app restart** (force-stop, relaunch, re-select account), and every engine call in the window logged `LOOM_BINDING service=workflow-engine mode=remote … outcome=ok status=200` — no error, no refusal, no `403`. No ANR or crash dialog occurred (`dumpsys window`: "no ANR has occurred since boot").

`Messages` was not swept: it is the not-yet-implemented tab and is out of scope by standing instruction.

## Cause — traced, not inferred

The instance is **returned to the app correctly**; it is lost at rendering. Each link was checked:

1. **The service returns it.** `GET /v1/communities/community_neighborhood_book_club/instances` as this fan → HTTP 200, 6 items, including this instance with `currentState: "draft"`. The payload contains **no `createdByFanId`**.
2. **The client substitutes an empty creator.** `remote_workflow_engine_api.dart:143` decodes every listed instance with `_decodeInstance(item, response, createdByFanId: '')`, and `:586` states the reason outright: *"The OpenAPI projection deliberately does not expose creator identity."*
3. **`actor` falls back to that empty creator.** `role_resolver.dart:30-33`: when no transition declares `actorEqualsField`, `actorFanId = instance.createdByFanId`, and `'actor'` is granted only when `viewerFanId == actorFanId`. With `''` on the remote path, no real fan can ever match.
4. **This workflow declares zero `actorEqualsField`** (measured across its four transitions), so it takes exactly that fallback.
5. **Its `draft`/`scheduled` bindings are `audience: "actor"` only** — there is no `receiver` binding for those states, so the one role the viewer *does* derive has nothing bound to it.

Net: on the remote path this instance renders for **nobody**, including its own author.

### Control, in the same session

Every card that did render in this community is an `audience: "any"` binding — `book-vote` (the ballot, Books tab), `book-meeting-rsvp` ("B25 Reverify Sep19", Home), `book-discussion-message` (Discussions, with live Reply/Mark read/Archive actions). Nothing bound only to `actor` rendered anywhere. So the discriminator is the binding audience, not the viewer, the session, the tab or the backend.

### Population — scoped by the class, not by this row

Within Book Club, exactly **two** workflows have `audience: "actor"` bindings **and** no `actorEqualsField` transition, which is the combination that takes the dead fallback:

| workflow | actor bindings | has `actorEqualsField` | exposed |
|---|---:|---|---|
| `book-selection-publish` | 2 | no | **yes** |
| `book-export-metadata` | 1 | no | **yes** |

Workflows whose `actor` bindings resolve through an `actorEqualsField` (`book-nomination`, `book-vote-response`, `book-shared-library-item`, `book-search-ai-digest`) read a field out of `instanceData`, which the remote projection *does* carry, so they are not affected by this mechanism. The wider corpus beyond Book Club was not swept here and is worth scoping before any fix.

### Relationship to the known Book Club defect

This is **not** the held `nominatorFanId` draft-visibility defect (row-247, `book-nomination`). That one is a field unstamped until submission. This one is more general: the creator identity is absent from the remote projection entirely, so it disables *every* `audience: "actor"` binding that falls back to the creator, regardless of package authoring. No package change would fix it, and none is proposed — Book Club's regeneration is held, and the JSON is Skill-authored only.

## Claim boundaries

- The row, its `created_by_fan_id`, its state and its `instance_data` were read directly from Postgres.
- The rendering absence is an observation over the seven swept tabs after a full restart, corroborated by the code trace and by the `audience: "any"` control cards rendering in the same session.
- `publish-announcement` was **never fired** — not through the UI, and deliberately not through the API either, since an API-fired transition would prove nothing about the UI path this row exists to test. The row is therefore left in `draft`, which is an accurate record of exactly where the product stops.

## Device hygiene

The soft keyboard collapsed the creation dialog's field area to zero height (the same trap a sibling run hit). It was disabled for the duration of form entry so focus could not shift layout, then **re-enabled and re-selected**; `default_input_method` and the enabled-IME list were verified back to their original values.
