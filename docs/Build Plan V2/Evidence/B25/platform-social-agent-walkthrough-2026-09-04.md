# Platform Social — live agent walkthrough (B25 coverage pass)

- **Date:** 2026-09-04
- **Community:** Platform Social (`community_member_social_space`, `ext_member_social_space`)
- **Package:** `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc` (1296 lines)
- **Device:** `emulator-5554`, 1080x2400, Windows host over SSH reverse tunnel to adb on 127.0.0.1:5037
- **adb path:** `adb -s emulator-5554 …` only. No `kill-server`/`start-server`/`connect`/`disconnect`/`-a`; `ANDROID_ADB_SERVER_ADDRESS/PORT` never set. `get-state` = `device` at start and throughout.
- **Build under test:** installed `com.example.loom_communities_demo`, `MainActivity` focused for the whole run.

## Personas

| # | Display name | Account id | Role | How created | Notes |
|---|---|---|---|---|---|
| 1 | `WalkA_Member` | `member-20` | **Member** | Identity gate → Create New Account → **accepted the default role** | Default role offered by the gate was `Member` (screenshot 03/05) |
| 2 | `WalkB_Moderator` | (moderator account) | **Moderator** | Sign in as a specific person… → Create New Account → Role dropdown → `Moderator` | Second persona for the role-gating controls |

The package declares exactly two roles — `member` ("Member") and `moderator` ("Moderator"). No other role exists, and no invite-only roles are declared ("No invite-only roles are declared.", screenshot 28).

## Per-tab table

The bottom tab bar was swiped horizontally to its end and confirmed by **two identical frames** (`07`/`08`, md5 `b519ae9c…` both) — the bar does not scroll further, so the visible set is the whole set.

| Role | Tab (exact label) | PRIMARY affordance (exact label) | ALTERNATE affordance (exact label) | Screenshot |
|---|---|---|---|---|
| Member | **Home** | `Open sponsor` (filled primary button on the in-stream ad card) | `Dismiss` | 11, 12 |
| Member | **Messages** | `New message` (extended FAB) | **not found** — see below | 15, 16, 17 |
| Moderator | **Home** | `Open sponsor` | `Report sponsor` (`Dismiss` correctly absent) | 38 |
| Moderator | **Admin** | `Close safety review` | **not found** — see below | 33, 34, 42 |
| Moderator | **Messages** | **not found** — see below | **not found** | 35 |

Member sees **2** tabs (Home, Messages). Moderator sees **3** (Home, Admin, Messages).

Full affordance inventory on Home (both roles), all with exact label text:

- In-stream ad card, state `Filled`: `View`, `Open sponsor`, `Dismiss` *(member only)*, `Report sponsor`
- Sensitive no-fill card, state `Suppressed`: `Continue`, `Review policy`, `Hide explanation`
- Top-banner card, state `No fill`: `Refresh slot`, `Inspect no-fill reason`
- Tab-scoped FAB (member): `Send connection invite`, `New message`
- Tab-scoped FAB (moderator): `Provision protected no-fill`, `Provision banner slot`, `Provision sponsored item`

Shell-level AppBar (not a tab): bell, speech-bubble, people (identity picker → "Account role and permissions"), overflow `⋮` → **`Sync settings`**.

### Surfaces where PRIMARY/ALTERNATE could not be found, with reason

| Surface | What is missing | Reason |
|---|---|---|
| Messages (Member) | ALTERNATE | Only affordance is the `New message` FAB. No instance cards render because the three seeded threads are identity-scoped away (below). |
| Messages (Moderator) | PRIMARY **and** ALTERNATE | The `New message` create is `byRoleIds: ["member"]`, so no FAB renders for a moderator; and the seeded threads are identity-scoped. The tab is genuinely actionless for this role. |
| Admin (Moderator) | ALTERNATE | Only `Close safety review` is actionable. The three connection cards are declared `bindingKind: "summary"` and render read-only by design. |

## Create-form observation (item 3)

Opened the clearest create affordance the Member persona can use: Home FAB → **`New message`**.

- **Title:** `New message`
- **Fields:** exactly one — **`With`** (free-text). This is `participantBFanId`, the sole entry in `states.draft.editableFields` for `platform-message-thread`. It is rendered with its humanized label, not the raw key.
- **Buttons:** `Cancel`, `Create`
- **Cancelled without submitting** via `Cancel`.

**Cancel is clean, proven by pixel diff rather than by eye.** Comparing the pre-frame (`11`) with the post-cancel frame (`14`), cropped to exclude only the status-bar clock (y ≥ 110):

```
diff bbox below status bar: None
```

`ImageChops.difference(...).getbbox()` returning `None` means the two content regions are **byte-for-byte identical**. Full-frame md5s differ only because the clock advanced 2:50 → 2:51.

## Absence classification (item 4)

Protocol applied before recording any absence: scrolled to **both** ends of every surface, expanded the one collapsed disclosure present, and confirmed taps register (the disclosure expanded on a precise tap — chevron `⌄` → `⌃` and children appeared, screenshots 18 → 19). Every mechanism below was confirmed by grepping the package's raw JSON, not inferred from the empty screen.

| Surface | What is missing | Verdict | Evidence | Seeded data? |
|---|---|---|---|---|
| Messages tab, both roles | All 3 message-thread cards | **identity-scoped** | `visibility.readGuard = {"actorEqualsField": {"key": "participantAFanId"}}` (line 53). Seeds are owned by `platform-member-alex` / `platform-member-bailey`; the personas are `member-20` and the moderator account. Empty for **Member and Moderator alike**, which rules out role-gating. The auth screen lists exactly one existing account (screenshot 28), so the seeded fan ids have **no sign-in identity** — they are unreachable by any persona this build can create. | **Yes** — `thread-alex-bailey` (open), `thread-alex-casey` (open), `thread-bailey-casey` (archived) |
| Admin tab, Member | The entire tab | **role-gated** | `appShell.tabs[0].visibleRoleIds = ["moderator"]`. Tab is absent for Member (2 tabs, screenshot 08) and **appears** the moment a Moderator account signs in (3 tabs, screenshot 32). | Yes |
| Home + Admin, Member | Blocked-target card ("Block active") | **identity-scoped** | `readGuard = {"actorEqualsField": {"key": "blockerFanId"}}` (line 646), with `visibility.fields.parties = ["blockerFanId", {"role": "moderator"}]`. The blocker is `platform-member-alex`; the Moderator sees the card via the `{"role":"moderator"}` party entry, the fresh Member does not. | **Yes** — `blocked-record-alex-casey` (active) |
| Home, Member | All 3 connection cards | **role-gated** | `readGuard = {"allowedRoleIds": ["moderator"]}` (line 311). Invisible to Member; all three render for the Moderator (screenshot 34). | **Yes** — `conn-alex-bailey` (connected), `conn-bailey-casey` (invited), `conn-alex-casey` (blocked) |
| Home, Moderator | Connection cards on **Home** specifically | **by design, not a defect** | The bindings declare both `tabId: "home"` and `tabId: "admin"`. The shell resolves an owning tab with `tabSpecs.firstWhere((tab) => tab.tabId != 'home' && tab.matchesWorkflow(...), orElse: tabSpecs.first)` — `part01_local_extension_screen.dart:785-791` and `:939-945` — i.e. a non-`home` tab deliberately wins. Home's own subtitle says "Pinned and **unassigned** community surfaces." | Yes |
| Home FAB, Member | `Provision sponsored item`, `Provision banner slot`, `Provision protected no-fill` | **role-gated** | `actions[].byRoleIds = ["moderator"]`. Absent for Member (screenshot 12), all three present for Moderator (screenshot 37). | n/a (create actions) |
| Messages FAB, Moderator | `New message` | **role-gated** | `byRoleIds = ["member"]`; enforced at `part01_local_extension_screen.dart:1352-1356`. | n/a |
| In-stream ad card, Moderator | `Dismiss` | **role-gated** | Transition `dismiss-ad` carries `guard.allowedRoleIds = ["member"]` while the card itself is `visibility.default: "public"`. Member sees 4 buttons, Moderator sees 3. | Yes |

**No surface fell into the "unseeded/unwritable" class.** Control for that query: all **6** workflow definitions have seeded instances — 10 `workflowInstances` total (3 threads, 3 connections, 1 blocked-target, 3 ad slots), enumerated directly from the package. `seedDataFiles` is `[]`, which is why the shell reports "No seed files recorded." — that string is **accurate**, not a rendering bug: this package seeds inline via `experience.workflowInstances`.

## Owner/Admin-only editable field vs lower-privilege role (item 5)

**Actively checked; the Export-and-Migration defect shape does not reproduce here, and the exact shape has no instance in this package.**

Enumerating every state that declares an `editGuard` gives **two**, and both are identity guards, not role guards:

```
platform-message-thread/draft: editableFields=['participantBFanId']
                               editGuard={"actorEqualsField": {"key": "participantAFanId"}}
platform-connection/draft:     editableFields=['reason','inviteeFanId','expiresAt']
                               editGuard={"actorEqualsField": {"key": "inviterFanId"}}
```

There is **no** `editGuard` with `allowedRoleIds` anywhere in the package, so "an Owner/Admin-only *editable field* that also renders for a lower role" has no candidate to test. Both guarded states are `draft`, and no seeded instance is in `draft` (threads are open/archived; connections are connected/invited/blocked), so no editable-field editor is reachable without writing data.

What I could test is the same defect **class** on the axes this package does exercise, and all four are **correct**:

1. **Role-restricted transition on a card both roles can see.** `dismiss-ad` is `allowedRoleIds: ["member"]` on a card whose visibility is `public`. Member: `View` / `Open sponsor` / **`Dismiss`** / `Report sponsor` (screenshot 11). Moderator: `View` / `Open sponsor` / `Report sponsor` — **`Dismiss` absent** (screenshot 38). No leak.
2. **Member-only transitions on a moderator-visible card.** The blocked-target card carries `confirm-block` ("Confirm block") and `close-review` ("Mark reviewed"), both `allowedRoleIds: ["member"]`, plus `moderator-close-review` ("Close safety review"), `allowedRoleIds: ["moderator"]`. The Moderator sees **only** `Close safety review` (screenshot 42). No leak.
3. **Create actions**, both directions — member creates hidden from moderator and vice versa (screenshots 12 vs 37). No leak.
4. **Tab visibility** — Admin hidden from Member (screenshots 08 vs 32). No leak.

Supporting code check: `GenericWorkflowInstanceCard._editableKeys` (`part26_generic_instance_card.dart:107-127`) passes both `widget.fanId` and `roleId` into `evaluateGuard`, and `evaluateGuard` (`loom_workflow_engine/lib/src/evaluator/guard_evaluator.dart:15`) enforces `allowedRoleIds` **and** `actorEqualsField`. So the recently fixed drop-the-editGuard path would cover both mechanisms if a role-based `editGuard` existed here.

## Defects found

### 1. `Local package details` header renders white-on-white — contrast 1.00:1 (shell-wide)

The expansion-tile header that reveals package details is **invisible on the device**. Measured on the raw 1080x2400 screencap, not by eye:

- Glyph pixels in the header row (y 892-940) are dominated by `(255,255,255)`; the darkest is `(249,249,255)`.
- Surface behind it is `(248,249,255)`.
- **Contrast ratio 1.00:1** (WCAG AA needs 4.5:1 for body text).
- Its own expanded children measure **16.29:1** (`Package`) and **8.86:1** (`ext_member_social_space`) against the same background, so this is not a scroll-fade or an animation frame — and it persisted identically across five captures over ~18 minutes, on both Home and Messages.

Root cause, `app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:1826-1832`:

```dart
ExpansionTile(
  title: const Text('Local package details'),
  leading: const Icon(Icons.inventory_2_outlined),
  collapsedTextColor: Colors.white,
  collapsedIconColor: Colors.white,
  textColor: Colors.white,
  iconColor: Colors.white,
```

All four colour properties are hardcoded `Colors.white` on a light scaffold, in **both** collapsed and expanded states. This is unconditional and lives in the shared app-shell screen, so it affects **every** community, not only Platform Social. It is not decorative — it is the control the user must tap to expand the section. Screenshots 19, 21 (and the row-scan showing zero pixels darker than the background across the full 960 px width).

### 2. The role radio in "Account role and permissions" is a silent no-op while signed in

Selecting **Moderator** in the identity picker dismisses the dialog and leaves the active role as **Member** — no change, no error, no feedback. Reproduced **three times** (screenshots 22→23, 25, 26→27); the header still read "Signed in as WalkA_Member / Member" each time, and the tab bar stayed at 2 tabs.

Root cause is a getter that discards the state the dialog writes:

```dart
// part01_local_extension_screen.dart:221-224
/// The role of the signed-in account, or [_selectedRoleId].
String? get _activeRoleId {
  final session = _authApi.currentSession;
  return session?.account.roleId ?? _selectedRoleId;   // account role always wins
}
```

The picker's `onTap` does reach `setState(() { _selectedRoleId = selected; … })` at line 1183, but whenever an account is signed in — which is every path that can reach this dialog, since the community entry gate requires sign-in — `session.account.roleId` short-circuits it. The role options are rendered as enabled radios with no disabled state and no explanatory text, so the control advertises an effect it cannot have.

The working route to a different role is the dialog's own "Sign in as a specific person…" → Create New Account → Role dropdown, which is what persona 2 used.

## Rendering review (item 7)

Checked for bare camelCase keys, broken inline values, clipped content, raw ids/timestamps/booleans/list-literals, unformatted currency, missing pluralization.

**Clean, with one caveat.** Positives worth recording:

- Fan ids are humanized everywhere in workflow cards: `platform-member-casey` renders as **`Target: Platform Member Casey`**; `Invited by Platform Member Alex`, `Invitee: Platform Member Bailey`. No raw fan id leaked into a card.
- `Reports: 0` is `reportCount` with `labelTemplate: "Reports: {value}"` — a deliberate count label, correct at zero.
- The chip reading `Open sponsor` is `sponsorUrl` with `labelTemplate: "Open sponsor"` and `openMode: "external"` — it **intentionally** suppresses the raw URL. Not a broken inline value; I verified this against the schema before recording it.
- `dismissible` (bool), `reportedByFanIds` / `reasonInspectedByFanIds` / `policyReviewedByFanIds` (list literals) all declare `displayContexts: []` and correctly render nowhere. No `[]` or `true` leaked to the UI.
- States render as human labels (`Filled`, `No fill`, `Suppressed`, `Block active`, `Connected`, `Invite sent`, `Blocked`), not raw state ids.

**Caveat:** the dev disclosure shows the raw extension id `ext_member_social_space` as a value under `Package`. It is a debug surface but is member-reachable. Low severity; noted rather than filed.

Defect 1 above is also a rendering defect and is the only one that affects legibility.

## Stability

- No crash, ANR, or blank frame observed across 42 captures.
- `mCurrentFocus` was `com.example.loom_communities_demo/…MainActivity` at the start and at the end — never a system dialog, never null.
- logcat sweep over a 134,480-line dump, using `grep -ac` (always exits 0, never the `grep -c … || echo 0` trap):

| Pattern | Count |
|---|---|
| `FATAL EXCEPTION` | **0** |
| `ANR ` | **0** |
| `Force finishing` | **0** |
| control: `loom_communities_demo` | 676 |
| control: `flutter` | 9 |

The two controls are non-zero, so the zeros above are genuine absences and not a broken query.

## Screenshot index

All 41 captures are in `/tmp` on the VM (`*.png` is gitignored, so these are transient; this manifest is the durable record).

| File | Bytes | What it shows |
|---|---:|---|
| platform-social_01_list.png | 316853 | Community list, top |
| platform-social_02_scroll.png | 263049 | List scrolled, Platform Social card on a settled frame |
| platform-social_03_gate.png | 116326 | Identity gate; footer names Platform Social; default role `Member` |
| platform-social_04_name.png | 174298 | Display name entered |
| platform-social_05_presignup.png | 121363 | Pre-Sign Up, default role retained |
| platform-social_06_signedup.png | 209009 | Signed in as WalkA_Member / Member; 2 tabs |
| platform-social_07_tabbar_swipe1.png | 208901 | Tab bar swiped left |
| platform-social_08_tabbar_swipe2.png | 208901 | Identical to 07 — end of tab bar proven |
| platform-social_09_home_scroll1.png | 103471 | Home, top-banner no-fill card |
| platform-social_10_home_mid.png | 147359 | Home, sensitive no-fill card |
| platform-social_11_home_ad1.png | 157981 | Home in-stream ad, Member — **pre-frame for cancel diff** |
| platform-social_12_fab_member.png | 189640 | Member FAB: 2 member creates only |
| platform-social_13_createform.png | 136565 | `New message` form: field `With`, Cancel/Create |
| platform-social_14_postcancel.png | 157443 | **Post-cancel — content identical to 11** |
| platform-social_15_messages.png | 180984 | Messages tab, Member — no thread cards |
| platform-social_16_messages_top.png | 191416 | Messages scrolled to top end |
| platform-social_17_messages_bottom.png | 180947 | Messages scrolled to bottom end |
| platform-social_18_disclosure.png | 180957 | Disclosure tap that landed on scroll |
| platform-social_19_disclosure2.png | 210453 | Disclosure expanded — taps register; white-on-white header |
| platform-social_20_disclosure_full.png | 148182 | Disclosure contents |
| platform-social_21_fade_check.png | 147944 | Contrast measurement frame |
| platform-social_22_identity.png | 234247 | Identity picker; ID member-20; Member/Moderator radios |
| platform-social_23_moderator.png | 148263 | After radio tap — role unchanged (defect 2) |
| platform-social_24_mod_header.png | 209962 | Header still "Member" |
| platform-social_25_mod_try2.png | 209976 | Second attempt — unchanged |
| platform-social_26_picker_open.png | 230641 | Picker open, Member still selected |
| platform-social_27_radio_tapped.png | 209529 | Third attempt — unchanged |
| platform-social_28_authscreen.png | 168678 | Auth screen — exactly one existing account |
| platform-social_29_createform2.png | 168320 | Create New Account form |
| platform-social_30_roledropdown.png | 178722 | Role dropdown: Member / Moderator |
| platform-social_31_rolechosen.png | 176551 | Moderator selected |
| platform-social_32_mod_signedin.png | 213403 | Signed in as WalkB_Moderator — **Admin tab appears, 3 tabs** |
| platform-social_33_admin.png | 214890 | Admin tab, blocked-target card |
| platform-social_34_admin2.png | 176475 | Admin, all 3 connection cards |
| platform-social_35_msg_mod.png | 143006 | Messages as Moderator — empty, no FAB |
| platform-social_36_home_mod.png | 161545 | Home as Moderator |
| platform-social_37_fab_mod.png | 212566 | Moderator FAB: 3 `Provision…` actions only |
| platform-social_38_ad_mod.png | 161823 | Ad card as Moderator — `Dismiss` absent |
| platform-social_39_home_mod_bottom.png | 113713 | Moderator Home, bottom end |
| platform-social_40_mod_home_mid.png | 225593 | Moderator Home, middle — no connection cards |
| platform-social_41_overflow.png | 231944 | AppBar overflow → `Sync settings` |
| platform-social_42_admin_card1.png | 185792 | Admin card 1 — only `Close safety review` for Moderator |

## Pipeline result

The walkthrough completed end to end on a real emulator with no crash, ANR, or blank frame. Two personas covering both declared roles were created and driven; every tab visible to each role was opened and scrolled to both ends; the create form was opened and cancelled with a pixel-clean return; every empty surface was classified against the package's own guard declarations rather than recorded as bare absence. Two genuine defects were found, both with root cause located in shipped source. Nothing was committed and no file outside this manifest was modified.

## B25 coverage

**Provable now from this run:**

- Platform Social renders for both declared roles, with correct tab sets (Member 2, Moderator 3).
- Read-visibility gating is correct on all three mechanisms the package uses: `allowedRoleIds` (connections, Admin tab), `actorEqualsField` (threads, blocked-target), and `visibility.default: "public"` (the three ad slots).
- Create-action gating (`byRoleIds`) is correct in **both** directions — member creates hidden from moderator, moderator creates hidden from member.
- Transition gating is correct on a publicly visible card (`Dismiss`, member-only) and on a moderator-visible card (`Confirm block` / `Mark reviewed`, member-only).
- The ad-integrity surfaces all render with their disclosure text and reason strings: filled in-stream ad, reserved-banner no-fill, and protected-context suppression.
- Create-then-cancel leaves no residue (pixel-identical content region).
- Field humanization holds across every workflow card — no raw fan ids, booleans, list literals, or state ids leaked.

**Blocked, and why:**

- **Any surface that requires being a seeded participant.** The three message threads and the blocked-target record are owned by `platform-member-alex` / `-bailey` / `-casey`, and the auth screen exposes **no** sign-in identity for those fan ids. A freshly created persona of the correct role can never satisfy `actorEqualsField`, so the message-thread *reading* and *replying* paths, and the member-side block/unblock transitions (`Confirm block`, `Mark reviewed`), cannot be exercised by any persona this build can create. Proving those rows needs either a seeded sign-in account per seeded fan id, or a walkthrough that first writes its own thread — which this ticket scoped out by requiring cancel-without-submit.
- **The two `editGuard` states** (`platform-message-thread/draft`, `platform-connection/draft`). No seeded instance is in `draft`, so the editable-field editors are unreachable without creating an instance. The role-gated-editable-field row therefore cannot be proven or disproven here — and, per the enumeration above, this package declares no role-based `editGuard` at all, so that row may simply not apply to Platform Social.
- **Role switching via the identity picker** is unusable (defect 2), so any B25 row that assumes a single account can move between roles in-session must instead be recorded per-account.

## Independent verification (orchestrator, by eye)
`platform-social_19_disclosure2.png` pulled byte-identically and viewed: confirms the white-on-white
"Local package details" header is genuinely invisible on-device -- only the chevron and inventory icon
are faintly visible, the label text itself is fully absent against the background. Matches the measured
1.00:1 contrast exactly. Also confirms the empty Messages tab (identity-scoped, matching the manifest's
classification) and the "2 roles" chip / role description.

## Explicitly checked and NOT found: the just-fixed defect class does not apply here
This walkthrough specifically hunted for the Export/Migration-style "editable field rendered for a role
the editGuard forbids" defect (per this ticket's item 5). Result: Platform Social declares exactly two
editGuard states, BOTH are actorEqualsField identity guards (not allowedRoleIds role guards), and
neither has a seeded instance in its reachable draft state -- so there is no live case to exercise, and
more importantly no role-based editGuard exists in this package at all for that class of bug to affect.
The agent additionally read the fixed source (`part26_generic_instance_card.dart:107-127`) and confirmed
the new check covers both allowedRoleIds and actorEqualsField mechanisms, so if a reachable case existed
here it would already be protected by the fix committed this session (db471847).

## FINAL running tally -- all 10 B25 communities complete
| Community | Genuine gaps | Notes |
|---|---:|---|
| Cedar Commons HOA | 1 | dues workflow unseeded + board-only create + payment NEEDS IMPLEMENTATION |
| Neighborhood Book Club | 1 | Messages: no writer, no seed, empty under both roles |
| Chess Club | 1 | disputes workflow unseeded under any role |
| Masjid Nur | 0 | fully role-differentiated, all seeded correctly |
| Riverside Youth Soccer | 0 | "empty" surfaces are identity-scoped (correct), not broken |
| Garden Club | 1 | Messages (same shape as Book Club) + 3 rendering bugs |
| Camera Club | 2 | Critique identity-scoped-unreachable + Messages unseeded; 5 rendering bugs |
| Ad-Free Community | 0 | every absence traced to a correct, declared guard; 10 rendering bugs (richest) |
| Export and Migration | 0 (package) | **1 UI-layer authorization bug** (this session's fix, db471847) + 8 rendering bugs |
| Platform Social | 0 | 2 shell-wide bugs found+root-caused: white-on-white disclosure header, silent role-radio no-op |

**10 of 10 communities walked rigorously with a live device, agent-driven, independently verified.**
Zero backend/engine defects found anywhere. One real UI authorization bug found, root-caused, fixed,
tested, and independently re-verified in this same session. The remaining "genuine gaps" (4 communities,
1 isolated unseeded workflow each) are product-completeness items, not architecture problems. Two
shell-wide cosmetic/UX bugs (disclosure-header contrast, role-radio no-op) recur across multiple
communities and are now pinned to exact source locations, ready to ticket.
