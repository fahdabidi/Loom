# UX judge verdict — Member Social Space, `platform-connection` — B25 row

**Workflow:** `platform-connection` in Member Social Space (`community_member_social_space`)
**Verdict:** PASS
**Judged:** 2026-09-09, model `fable`, against 16 frames from the same-day live walkthrough
**Walkthrough manifest:** `7116b523` — evidence/b25/social-platform-connection-20260909/manifest.md
**Frames:** gitignored and not committed; this verdict is the durable record of what they showed.

- **Judged:** 2026-09-09, all 16 frames itemised in `manifest.md` viewed. (The dispatch ticket said
  "14 judge-relevant frames" at a different path with garden-tool-loan's frame numbers, and described
  the row as driven to `published`/`delisted` — all four claims are stale copy-paste from the garden
  row's ticket. Judged against the directory and manifest that exist; the flow shown is
  `draft` → `invited` → `connected`, which is what this workflow's manifest claims.)
- **Verdict: PASS.** Both B25 affordances are visibly present and comprehensible to the `member`
  persona, and the two-party identity switch this run existed to prove is confirmed from pixels.

## The two-identity check — confirmed from frames 02/04 vs 11a/11/13

This was the ticket's specific concern: a stale Keycloak SSO cookie can silently re-issue the
previous user's token, making a one-person run look like two. The frames rule that out to the
extent pixels can:

1. **`02` (11:18):** real Keycloak form at `192.168.56.10:30082`, **both fields empty**, before
   party 1 signed in.
2. **`04` (11:21):** inside Platform Social, banner "Signed in as **Social Member 1**", role Member.
3. **`11a` (11:40):** the Keycloak form again, **both fields empty** — no SSO carryover after the
   identity switch. Distinct capture from `02` (status-bar clock differs; `02` shows a text cursor,
   `11a` does not).
4. **`11` (11:41):** the username field literally reads `loom-social-member-2`, character-exact,
   before submit.
5. **`13` (11:42):** banner "Signed in as **Test social-member-2**", role Member.
6. **`14` (11:43) → `16` (11:44):** that second session is the one offered Accept and the one whose
   Accept produced `Connected`.

Two distinct account names on the in-community banner, separated by a genuinely empty login form
with the second username typed into it. The frames clearly evidence the identity switch.

## B25 bar

- **Primary affordance:** **Accept** — prominent blue button on the invite card addressed to
  "Invitee: Fan Social Member 2", in the invitee's own session (frame `14`). For the inviter's half,
  **Send invite** on the `draft` card (frame `09`) is equally plain.
- **Alternate/change/reject affordance:** **Decline** (frame `14`, adjacent to Accept) as the
  reject; **Cancel invite** (frames `04b`, `10`) as the inviter's change/withdraw.
- Word-boundary discipline: "Accept" and "Decline" share no tokens. "Send invite" and
  "Cancel invite" share the token "invite" but are distinct buttons on distinct frames, and the
  spans claimed above are each counted once — no span claimed for the alternate also counts as
  primary.
- Comprehensibility: state chips ("Draft", "Invite sent", "Connected") and party chips
  ("Invited by …", "Invitee: …") name the parties in plain language on every card. A member persona
  can tell whose move it is.

## Frame-by-frame agreement with the manifest

| Frame | Claim | Verdict from pixels |
|---|---|---|
| 01 | entry gate, `LoomAuthNotLoggedInException` stated, unauthenticated | confirmed — also "Continue to secure sign-in" and "Check membership status" present |
| 02 | real Keycloak form, empty fields (party 1) | confirmed |
| 03 | account list after OAuth, grouped by role | confirmed (Member group: Social Member 1, Test social-member-2; admin; Moderator) |
| 04 | **entry (party 1)** — "Signed in as Social Member 1", role Member | confirmed |
| 04b | 2026-09-08 instance as inviter: `Cancel invite` / `Block` | confirmed — invitee chip reads "Fan Social Moderator 1", reason "Met at the community meetup" |
| 05 | speed dial with "Send connection invite" | confirmed (plus "New message") |
| 06 | empty create form: Reason, Invitee, Invite expires | confirmed |
| 07 | **action** — Reason `B25 re-verification connect`, Invitee `fan-social-member-2`, character-exact | confirmed — full value visible in field and keyboard suggestion bar |
| 09 | new instance in `draft`, invitee untruncated, `Send invite` offered | confirmed — also disabled "Save changes / No changes to save yet." |
| 10 | **result (party 1)** — `Invite sent`, invitee Member 2, reason chip present | confirmed (instance renders twice, once with reason chip — see observation 1) |
| 11a | Keycloak form again, empty — no SSO carryover | confirmed |
| 11 | member-2 credentials verified before submit | confirmed (password in cleartext — see observation 3) |
| 12 | account list, both members present under Member | confirmed |
| 13 | **entry (party 2)** — "Signed in as Test social-member-2", role Member | confirmed |
| 14 | **the key frame** — invitee offered `Accept` / `Decline` / `Block` | **confirmed** — on both renderings of the instance |
| 16 | **terminal result** — green `Connected`, only `Block` remains | confirmed — Accept and Decline gone, Cancel invite gone |

The manifest's party-scoped-visibility claim also holds in the pixels available: the 2026-09-08
invite addressed to Moderator 1 appears in member-1's session (`04b`, `05`, top of `10`) and does
not appear in the member-2 frames (`14`, `16`).

## What the frames cannot prove (not claimed)

That the token behind the second session carries `fanId = fan-social-member-2` is the walkthrough's
claim, resting on the app's selection-vs-token mismatch guard and the database readback
(`created_by_fan_id`, `respondedAt`); the frames only show the empty form, the typed username, and
the named banner. Likewise the database row and the package `sha256` are the walkthrough's half of
the proof standard. I judged pixels only. Frames `03` and `12` are content-identical account lists
and prove nothing about which session holds a token; they are supporting context, not identity
evidence — the identity evidence is items 1–6 above.

## Observations (none blocking)

1. **The by-design double render reads as a duplicate-invite bug.** Frames `10` and `14` show the
   same instance twice on Home with full action sets — once with the reason chip, once without.
   The manifest explains it (two `home` renderBindings, `approvalQueueItem` + `notificationInbox`)
   and its own author initially misread it. To an invitee it looks like two separate invites, and
   both offer Accept. Declared design, not a B25 failure — but it misled the walkthrough agent and
   it will mislead members.
2. **The unanswerable 2026-09-08 invite is visible in the frames.** `04b` shows the invite
   addressed to Fan Social Moderator 1 still in `Invite sent` — the manifest's finding that a
   free-text Invitee field accepts a fan who cannot respond is corroborated on screen.
3. **Frame `11` shows the shared test password in cleartext** (eye-toggle on, deliberately, to
   verify before submit). The frames are gitignored and the credential is the documented shared
   test convention; noting for completeness.
4. **The create dialog's confirm button is "Create"** (frames `06`/`07`), while the speed-dial
   entry is "Send connection invite" — creating lands you in `draft`, and the actual send is a
   second, clearly labelled step (`09`). Sensible; noted so nobody reads "Create" as the send.
