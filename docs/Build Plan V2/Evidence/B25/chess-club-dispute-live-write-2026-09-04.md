# Chess Club — live result-dispute write (B25 gap closure)

**Date:** 2026-09-04 (device local, America/Los_Angeles — `adb shell date` =
`Fri Sep  4 18:49:55 PDT 2026`; engine stamps are UTC, so the dispute effect lands at
`2026-09-05T01:49:01.263438Z`, which is 18:49 local on 2026-09-04)
**Device:** `emulator-5554`, Android, 1080x2400
**adb path:** Windows-hosted emulator reached over an SSH reverse tunnel to adb on
`127.0.0.1:5037`; every command issued as `adb -s emulator-5554 …`. `get-state` = `device` before
and after the run. No `kill-server`/`start-server`/`connect`/`disconnect` was issued, no `-a`, and
no `ANDROID_ADB_SERVER_ADDRESS`/`PORT` was set.
**App:** `com.example.loom_communities_demo/.MainActivity`
**Workflow:** `chess-match-result` in Chess Club

## Outcome

**This row is closed.** A `chess-match-result` instance was created from nothing by a freshly minted
Player persona, driven `draft → submitted → disputed`, and the terminal-for-this-row state
**"Result disputed"** carries a history entry naming that persona as the disputing actor. All three
writes were real submits — nothing was cancelled.

The blocked premise is resolved exactly as the ticket predicted. The earlier walkthrough could not
prove disputes because the one seeded result's `participantFanIds` are un-sign-in-able ids, and
`dispute-result` guards on `actorInList: participantFanIds`. The Matches-tab **"Record match"** FAB
prefills `participantFanIds: ["$actor"]`, so the creator is automatically a participant and clears
that guard without needing a second persona or an opponent.

## Persona

Created live in-app during this run; the id is as displayed by the in-app "Account role and
permissions" dialog.

| Display name | Account / fan id | Role (label) | Role id |
|---|---|---|---|
| Nadia Petrova | `chess-member-20` | Player | `chess-member` |

Created at the community entry gate. **The role dropdown defaulted to Organizer** and was switched
to **Player** before Sign Up. Player is the label for `chess-member` — confirmed against the
package's `roles` block (`roleId: chess-member`, `label: "Player"`, `roleLabel: "Member"`), which is
the exact role id `dispute-result` requires in `allowedRoleIds`.

## Step-by-step

| # | Step | Result | Screenshot |
|---|---|---|---|
| 0 | Community list "Loom Communities", 10 example communities loaded | — | `chess-dispute_00_start.png` |
| 1 | Open **Chess Club** | Entry gate, **no** existing accounts | `chess-dispute_01_chess_open.png` |
| 2 | Type display name "Nadia Petrova" | Accepted | `chess-dispute_02_name.png`, `chess-dispute_03_kb_down.png` |
| 3 | Open Role dropdown | Three roles offered: Organizer, Player, Owner | `chess-dispute_04_roles.png` |
| 4 | Select **Player**, Sign Up | Signed in as Nadia Petrova / Player ("Member — Schedules and plays matches, reports results…") | `chess-dispute_05_player.png`, `chess-dispute_06_signedup.png` |
| 5 | Identity dialog → record id | **ID: chess-member-20**, Player radio selected. Dismissed with **Cancel** — no role change made | `chess-dispute_07_members.png` |
| 6 | **Matches** tab | Tab open, create FAB present | `chess-dispute_08_matches.png` |
| 7 | Tap FAB | Two creates offered: **Record match** and **Propose match** | `chess-dispute_09_fab.png` |
| 8 | Choose **Record match** | `chess-match-result` draft form opens | `chess-dispute_10_form.png` |
| 9 | Fill all six required text fields | See values below | `chess-dispute_11_filled.png`, `chess-dispute_12_verify_top.png` |
| 10 | **Create** (real submit, participant picker deliberately left untouched) | Dialog closed, instance created | `chess-dispute_13_create_attempt.png` |
| 11 | Scroll Matches to the new card | State **"Draft result"**, all six values rendered | `chess-dispute_14_list1.png`, `chess-dispute_15_found.png` |
| 12 | Scroll to the card's participant control | **`Participant Fan Ids: chess-member-20`** — prefill verified, not assumed. **"Submit score"** offered | `chess-dispute_16_participants.png` |
| 13 | Apply **"Submit score"** (real submit) | State **"Result submitted"**; history gains `score-submitted` | `chess-dispute_17_submit.png` |
| 14 | Apply **"Dispute result"** (real submit) | State **"Result disputed"**; history gains `disputed` | `chess-dispute_18_dispute.png` |
| 15 | Scroll to card top | State badge **"Result disputed"** in negative tone | `chess-dispute_19_disputed_card.png` |

### Values written

All invented but plausible; no placeholders.

| Field | Value |
|---|---|
| `resultTitle` | Round 3 ladder - Petrova vs Whitfield |
| `playerOneName` (White) | Nadia Petrova |
| `playerTwoName` (Black) | Marcus Whitfield |
| `roundLabel` | Ladder round 3 |
| `score` | 1-0 |
| `outcome` | White wins |
| `participantFanIds` | `["chess-member-20"]` — supplied by the create prefill, not typed |

## The final state, and its history entry

Card state badge: **"Result disputed"** (negative tone), matching the package's
`states.disputed.label`. The `resultHistory` list on the card reads, in order:

```
Action: score-submitted
Actor Fan Id: chess-member-20
At: 2026-09-05T01:48:47.317964Z
Score: 1-0
Outcome: White wins

Action: disputed
Actor Fan Id: chess-member-20
At: 2026-09-05T01:49:01.263438Z
```

That second entry is the proof this row needed: **action `disputed`, actor `chess-member-20`
(the live persona created in step 4), with a real timestamp** — a participant disputing their own
match result, live, on device.

## Step 8 (Resolve dispute) — deliberately not fired

`resolve-dispute` **was offered and enabled** to this persona (visible as a primary "Resolve
dispute" button in `chess-dispute_18_dispute.png`), which is consistent with its guard
`allowedRoleIds: ["chess-organizer", "chess-member"]` and its lack of an `actorInList` clause.

It was **not** tapped. The ticket marks it optional and not required to close the row, and the
deliverable asks for the final disputed state confirmed — firing it would have moved the instance to
`final` ("Saved result") and left no live instance in the disputed state. The instance is therefore
left in **"Result disputed"** so the live artifact matches this manifest.

## Product finding — create form's participant picker does not show the prefill

Not a blocker for this row, and the underlying behaviour is correct, but it reads as broken.

In the "Record match" create dialog, the **Participant Fan Ids** control rendered
**"No members selected"** with all three checkboxes (Organizer / Player / Owner) unchecked —
see `chess-dispute_10_form.png` and `chess-dispute_12_verify_top.png` — even though the render
binding declares `prefill.participantFanIds: ["$actor"]`.

I tested this rather than assuming it, per the ticket: I tapped **Create** without touching the
picker. The create succeeded, and the resulting instance shows
`Participant Fan Ids: chess-member-20` (`chess-dispute_16_participants.png`). So **the prefill does
apply at instance creation; the create form's member picker simply does not reflect prefilled
values in its own display.**

Two consequences worth recording:

- A user cannot tell from the form that they are already a participant. The natural reading of
  "No members selected" against a **required** field is that the form is incomplete, which invites
  them to check a box redundantly or to abandon the create.
- The required-field indication is inconsistent with the picker's display: `participantFanIds` is
  `required: true`, yet Create proceeded with the picker showing nothing selected. That is correct
  behaviour given the prefill, but only because the prefill is invisible here.

The picker also labels its rows by **role** ("Organizer", "Player", "Owner") rather than by person,
which in a community with one account per role is ambiguous about who would actually be added.

## Stability

No crash, no ANR, no blank frame. `logcat -d -t 600` matched
`FATAL EXCEPTION|ANR in|Force finishing` **0** times, and no Flutter exception/error lines were
present. `mCurrentFocus` was
`Window{be5510b u0 com.example.loom_communities_demo/com.example.loom_communities_demo.MainActivity}`
at the start of the run and unchanged after the dispute write.

## Does this close the B25 disputes row?

**Yes.** The row was blocked on a single point — no sign-in-able persona was a participant on any
`chess-match-result` instance, so `dispute-result`'s `actorInList: participantFanIds` guard could
never be satisfied by a real actor. This run created such a participant legitimately, through the
product's own "Record match" create path, and then exercised the dispute transition for real.

What is now proven live, end to end, by one persona:

- `chess-match-result` create via the Matches **"Record match"** FAB → state `draft`
- the `$actor` participant prefill actually lands in instance data (`chess-member-20`)
- `submit-result` (`draft → submitted`), guard `allowedRoleIds: [chess-member]` + `actorInList` — passes
- `dispute-result` (`submitted → disputed`), same guard shape — **passes, by a live participant**
- both transitions' `append` effects write real `resultHistory` entries with actor and timestamp
- the `disputed` render binding shows the instance on the Matches tab with its negative-tone badge

Not proven by this run, and out of its scope: the `disputed` render binding on the **admin** tab
(`cardSurfaceFamily: approvalQueueItem`) was not visited, and `resolve-dispute`, `void-result`,
`correct-result`, `undo-result` and `record-standings-impact` were not fired — `resolve-dispute` was
observed as offered only.

## Independent verification (orchestrator, by eye)
`chess-dispute_19_disputed_card.png` pulled byte-identically and viewed: confirms the "Result
disputed" state badge (red/negative tone), all field values (Round 3 ladder - Petrova vs Whitfield,
White: Nadia Petrova, Black: Marcus Whitfield, Score: 1-0, White wins), and the history entry
"Action: score-submitted / Actor Fan Id: chess-member-20". Genuinely closed, single-persona, real
submits throughout.

## B25 tally update
Chess Club's disputes row is now CLOSED via live single-persona write. 3 of 5 original isolated gaps
now closed (Cedar dues, Camera Club Critique, Chess disputes). 2 remain, both genuinely different in
kind: Book Club Messages and Garden Club Messages -- no package-declared messaging workflow exists in
either, confirmed by a working cross-community control (Chess Club's own package has 33 `message`
occurrences and a working Messages tab). Closing these needs a new Skill-authored capability or
explicit acceptance as out of scope -- a product decision, not a live-drive fix.
