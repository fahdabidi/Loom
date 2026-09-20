**Workflow:** `book-discussion-message` in Neighborhood Book Club
**Outcome:** Both halves of the proof standard were met — a new thread was created and replied to through the real UI as `fan-book-member-2`, then archived to the terminal state by a second, separately authenticated identity `fan-book-organizer-1`, with every step independently confirmed in Postgres.

**Package identity:** `Loom_Communities_Workflow_Engine_BookClub_Example.jsonc`
- `"skillVersion": "3.6.0"`
- `sha256 = 71e1f0688b7dffd1b29cb90a1066998f003abdf920523cac8dcb535837726957`
- `cmp`-identical to the locked reference copy `docs/references/communities/Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc`

**Date:** 2026-09-20 (device 01:26–01:40 PDT = 08:26–08:40 UTC)

---

## This is a two-party run

This row is not organizer-only, and that was used deliberately: the member half and the organizer
half were driven by **two different fan ids, each authenticated through its own Keycloak login**,
acting on **one instance**. `post-message` was fired by the member; `archive-thread` — which the
package guards to `book-organizer` alone — by the organizer.

| | Member half | Organizer half |
|---|---|---|
| Keycloak account | `loom-book-member-2` | `loom-book-organizer-1` |
| Fan id | `fan-book-member-2` | `fan-book-organizer-1` |
| Role | `book-member` (Member) | `book-organizer` (Organizer) |
| Fired | create thread, `post-message` | `archive-thread` |

Both logins used the documented password `LoomTest123!`. **It was revealed with the eye control and
read before each submit** — it displayed exactly `LoomTest123!` both times, twelve characters, with
no shell-escaping backslash. No credential was created or reset.

### Identity was proven by refusal, not by a green screen

A success screen proves a token exists, not whose it is. The app's anti-impersonation guard was used
as the actual instrument, and it answered in both directions:

1. **Member half.** Holding the `loom-book-member-2` token, tapping **Book Member 1**
   (`fan-book-member-1`) did **not** proceed — the account list stayed put. Tapping **Test
   book-member-2** immediately entered the community. A wrong account refused and the right one
   accepted, on the same token.
2. **Organizer half.** After clearing, holding the `loom-book-organizer-1` token, tapping **Test
   book-member-2** — *the identity that had just worked minutes earlier* — was now **refused**. That
   is the decisive check: it rules out the stale-SSO failure in which the old fan is silently
   re-issued a token.

I did **not** observe an explicit `LoomAuthException(accountNotFound)` string on screen or in
logcat; what was observed is that selection did not proceed. I am recording the refusal at that
strength rather than quoting an error I did not see.

**Two independent corroborations**, both structural rather than cosmetic:

- **The tab set differs by role.** The `admin` tab declares `visibleRoleIds: ["book-organizer"]`. As
  member-2 the bottom nav held Home / Calendar / Marketplace / Books / Documents / Discussions and
  **no Admin tab anywhere**; as organizer-1 **Admin was present**. Authorization, not decoration.
- **The row itself** carries `created_by_fan_id = fan-book-member-2`, and the stored message carries
  `senderFanId = fan-book-member-2` — the authoritative record of whose token wrote each part.

Chrome **and** app data were cleared between the two identities (`pm clear` on both
`com.android.chrome` and `com.example.loom_communities_demo`). Each clear was confirmed to have
worked: the app returned `LoomAuthNotLoggedInException: No Loom authentication session is stored`
with the "Continue to secure sign-in" route present, and Keycloak presented a **real login form with
empty fields** rather than re-issuing silently. After each clear the launch screen read **"Loaded 10
example communities"**, confirming the preload flag is compiled into this build.

Every transition below was fired by tapping the real UI. Nothing was driven through the API.

## Baseline — measured, not trusted

Queried before touching the device:

- `book-discussion-message` rows: **1** — an `open` thread, prompt `Control thread`, created
  `2026-09-09 01:32:19 UTC` by `fan-book-member-2`. A prior run's; **not mine**, and not treated as
  my evidence.
- **Control**, so an empty result would mean absent rather than a broken query: six sibling `book-*`
  types were each present with 1 row (`book-export-metadata`, `book-meeting-rsvp`,
  `book-meeting-rsvp-response`, `book-nomination`, `book-selection-publish`, `book-vote`).
- Whole table: **98** instances (→ **99** after this run).
- `book-discussion-message` is **published at `version 4`**, so `createInstance` could not silently
  no-op.

The brief's hint (1 row of this type, 98 overall) was accurate. **I chose to create my own thread
rather than reply to the existing one**, so my work is distinguished by its own instance id and
`created_at` — not by the count moving. The pre-existing control thread was deliberately left
untouched, and its `updated_at` is still `2026-09-09 01:32:19`, which doubles as a control proving
the Reply I fired was bound to the correct instance.

## What was driven, in order

All on the **Discussions** tab (`tabId: "discussions"`, `cardSurfaceFamily: "discussionThread"`).

| # | Identity | UI action | State after | Evidence |
|---|---|---|---|---|
| 0 | member-2 | FAB → **New thread**, `prompt` entered, **Create** | `open` | card rendered, `0 replies` |
| 1 | member-2 | **Reply**, `body` entered, **Reply** | `open` (`to: null`) | message rendered; `1 replies` |
| 2 | organizer-1 | **Archive** | **`archived`** (terminal) | red `Archived` badge, all actions gone |

Final UI state: my card shows a red **`Archived`** badge, retains the prompt chip and the member's
message, and offers **no action buttons at all** — correct, since every transition declares
`from: ["open"]` and `archived` is `isTerminal: true`.

### The guards were observed in both directions, which is the point of a two-party run

- **As member-2** the card offered **Reply, Mark read, Mark unread, Mute, Unmute** and **no
  Archive** — `archive-thread` is `allowedRoleIds: ["book-organizer"]`.
- **As organizer-1** the same card offered those five **plus Archive** (rendered destructive/red).
- **As organizer-1 only**, an editable **Prompt** field with a *Save changes* button appeared —
  `open` declares `editableFields: ["prompt"]` under `editGuard: allowedRoleIds: ["book-organizer"]`.
  The member never saw it. (No edit was made; it read *"No changes to save yet."*)

So the organizer-only capability was absent for the member and present for the organizer, on the
same instance, minutes apart.

### The `size(messages)` formula moved, and a sibling row held still

`messageCount` is `formula: "size(messages)"`. Before the reply my card read **`0 replies`**; after
it, **`1 replies`**, with the message rendered as `fan-book-member-2` / `reply-from-member2-sep20` /
`2026-09-20T08:34:55.664510Z`. The untouched control thread continued to read **`0 replies`**
throughout — so the count moved for the instance acted on and not for its neighbour.

### Typed values were settled against the row, not the screen

Both free-text fields were typed, and **the soft keyboard collapsed the dialog's fields to zero
height** on the create step — the documented IME trap; the prompt field was no longer visible at the
moment Create was tapped. Coordinates were therefore re-read from a screenshot taken *after* each
keyboard open, and both values were settled against the database rather than the screen. Both stored
in full, with no truncation:

- `prompt` = `B25-Sep20-member2-thread`
- `body` = `reply-from-member2-sep20`

Worth noting for future readers: the card's **chip** renders the prompt as *"B25 Sep20 Member2
Thread"* — hyphens spaced, title-cased for display. The stored value is the exact hyphenated string
above. The organizer's editable Prompt field showed the raw stored form verbatim. A reader comparing
only the chip against the database would see a spurious mismatch.

## The database half

```
instance_id       community_neighborhood_book_club_book-discussion-message_stb3qrgop4ot
community_id      community_neighborhood_book_club
workflow_type     book-discussion-message
created_by_fan_id fan-book-member-2
current_state     archived
created_at        1789893214308  (2026-09-20 08:33:34 UTC)
updated_at        1789893593889  (2026-09-20 08:39:53 UTC)
```

Full `instance_data` as stored:

```json
{
  "prompt": "B25-Sep20-member2-thread",
  "messages": [
    {
      "senderFanId": "fan-book-member-2",
      "body": "reply-from-member2-sep20",
      "timestamp": "2026-09-20T08:34:55.664510Z"
    }
  ]
}
```

**Do the two halves agree? Yes, exactly.** The terminal state the device showed (`Archived`) is the
`current_state` in the row. `created_by_fan_id` is the member identity that was authenticated and
drove creation. The message's `senderFanId` shows the effect's `"$actor"` resolved to the real
authenticated fan — **not** a role-id-shaped string, which is the aliasing hazard recorded for
`fanId` fields elsewhere in this project. The timestamp rendered on the card is byte-identical to the
stored value.

The state was read **after** the transition each time, and the target state was observed rather than
merely the object — `archived`, not "the row exists".

## The four honest gaps behaved as designed — recorded, not filed

`mark-thread-read`, `mark-thread-unread`, `mute-thread` and `unmute-thread` each carry a
`NEEDS IMPLEMENTATION (platform service)` annotation in the package: per-member read position,
unread state and mute state belong to a messaging service that does not exist yet. All four rendered
as tappable controls for both identities, which is the designed state — the promised control stays
visible rather than being silently dropped.

**None of them was tapped**, so this manifest asserts nothing about their runtime behaviour. They
are noted here only so a later reader does not mistake their presence for a defect, and they did not
block this row. `post-message` and `archive-thread` are the real capability, and both were proven.

## Render bindings — no regression from the `audience: "actor"` defect

Every render binding on this workflow is `audience: "any"`, so the creator-identity defect fixed in
`8d33a8af` (service `1.0.9`) does not apply here. Taking the four facts the brief asked to be kept
distinct, at each step: the card was **present**, the action was **present**, the action was
**enabled and tappable**, and the state **persisted** to the intended value. All four held
throughout, for both identities. No new finding.

The `archived` summary binding also rendered correctly to the organizer after the transition, and
the `open` binding continued to render the untouched control thread.

## Environment

- `loom-workflow-service:1.0.9`, `loom/app-access:0.3.11`, `loom/fan-passport:0.3.1`; all six `loom`
  pods `1/1 Running`.
- App telemetry confirms the deployed backend was exercised, not a local engine: `LOOM_BINDING
  service=app-access mode=remote endpoint=http://192.168.56.10:30080/ outcome=ok status=200` and the
  equivalent for `fan-passport`.
- No `403`, no `unknown_permission_id`, no error toast at any step.
- No crash or ANR: `FATAL EXCEPTION` / `ANR in` count was **0** across the run's logcat window, and
  focus stayed on `com.example.loom_communities_demo/.MainActivity` apart from the two deliberate
  Chrome OAuth excursions.
- Chrome's first-run onboarding intercepted the OAuth redirect on **both** logins (expected after
  `pm clear`) and was dismissed with *"Use without an account"* each time.
- No application code, community JSON, or tracker was modified. This manifest is the only file added.

## Scope note

Book Club's regeneration is held by user decision (row-247). Nothing here proposes a package change;
no defect was found that would need one.
