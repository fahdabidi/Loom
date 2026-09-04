# Live walkthrough — Export and Migration (B25 coverage pass)

- **Date of run:** 2026-09-04 (05:11–05:33 device time; filename retains the ticket's 2026-09-03 slug)
- **Community:** Export and Migration — `community_data_portability` / `ext_data_portability_community`
- **Package:** `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc` (2460 lines, specVersion 4)
- **Build:** `com.example.loom_communities_demo` / `MainActivity`, 1080x2400
- **adb path:** `adb -s emulator-5554` only, over the pre-wired Windows SSH reverse tunnel to 127.0.0.1:5037. `get-state` = `device` at start and end. No `kill-server`/`start-server`/`connect`/`disconnect`/`-a`, no `ANDROID_ADB_SERVER_ADDRESS`/`PORT` set at any point.

## Personas

| # | Display name | Role chosen | Role assigned (as shown in-app) | Fan id |
|---|---|---|---|---|
| 1 | Priya Export | **accepted the default** | **Owner/Admin** — "Owner - Selects export scope, verifies packages, transfers data, and starts rollbacks." | `portability-owner-20` |
| 2 | Sam Member | Member (explicit, for the role-gate test) | **Member** — "Member - Reads applicable migration, redaction, and portability notices." | not surfaced in-app |

The sign-up gate's default `Role` value was **Owner/Admin**; persona 1 accepted it unchanged (screenshots 03, 05). The gate footer read "…to continue to **Export and Migration**", confirming the correct community before sign-up.

Seeded instances all carry `createdByFanId: "portability-owner"`, which is **not** the same principal as persona 1's `portability-owner-20`. Seeded data was nonetheless fully visible to persona 1, which establishes that these workflows are **role**-guarded (`readGuard.allowedRoleIds`), not actor-guarded — there is no `readGuard.actorEqualsField` anywhere in the package.

## Per-tab table

The bottom tab bar **does** scroll horizontally. Four tabs are visible at rest; swiping left revealed three more, and a repeated swipe produced two byte-identical frames (`18`/`19`, both 237,603 B) confirming the end. **7 tabs total** for the Owner persona.

| # | Tab | PRIMARY affordance (exact label) | ALTERNATE affordance (exact label) | Notes |
|---|---|---|---|---|
| 1 | Home | `Download full bundle` | `Change scope` | Also `Enable transfer`, `Export verification record`, `Cancel transfer`, `Save changes` (disabled, "No changes to save yet.") |
| 2 | Admin | `+` speed-dial FAB → 8 create actions | `Roll back transfer` | Only tab with a create FAB |
| 3 | Export | `Start transfer` | `Change scope` | Also `Confirm redaction`, `Record validation failure`, `Change redaction`, `Cancel` |
| 4 | Transfer | `Roll back transfer` | `Cancel replay` | Also `Cancel rollback`, `Cancel transfer` |
| 5 | Documents | `Download redacted bundle` | `Change redaction` | Also `Download full bundle`, `Cancel transfer` |
| 6 | Audit | `Enable transfer` | `Export verification record` | Single card (checksum evidence) |
| 7 | Messages | **none found** | **none found** | See absence table |

Tab visibility matched the package's `visibleRoleIds` exactly. As **Member**, only **Home** and **Messages** rendered — Admin, Export, Transfer, Documents and Audit all disappeared (screenshot 49). That is a positive, decisive demonstration of role gating.

The Admin `+` speed-dial exposed 8 create actions: `New provider transfer`, `New checksum evidence`, `New redacted bundle`, `New full bundle`, `New schema listing`, `New protected-data review`, `New import replay`, `New export or import preview`. There is no "New rollback" — consistent with rollback being reached from an existing transfer.

## Create-form observation

Opened Admin `+` → **`New full bundle`** (screenshot 16).

| Field label as rendered | Backing key | Notes |
|---|---|---|
| `Bundle Label` | `bundleLabel` | correct Title Case |
| `components` | `scope` | **mangled — see rendering bug R3** |
| `Destination` | `destination` | correct |
| `Member Notice` | `memberNotice` | correct |

Buttons: `Cancel`, `Create`. **Cancelled without submitting.** The cancel is clean: pre-frame `14` (237,146 B) and post-frame `17` (237,109 B) are visually identical — same scroll offset, same cards, same FAB; the 37-byte delta is the status-bar clock (5:16 in both, differing antialiasing) and no new instance appeared anywhere in the tab afterwards.

## Absence classification

Only one surface had no actionable affordance. Before recording it absent I scrolled both ends (screenshots 26 top / 27 bottom, and 25 — bottom frame reproduced byte-identically at 158,046 B), expanded the one disclosure present, and confirmed taps register on this surface (the "Local package details" disclosure toggled its chevron and revealed content, screenshot 11).

| Surface | What is missing | Verdict | Evidence | Seeded data? |
|---|---|---|---|---|
| **Messages** tab | No compose control, no conversation list, no empty-state copy — only the tab header card and the shared "Local package details" footer | **unseeded / unwritable** (not package-backed at all) | Control: `grep -c '"tabId"'` = **53** hits across 6 distinct ids (`home, admin, export, transfer, documents, audit`), so the query demonstrably works. `grep -c '"tabId": "messages"'` = **0**; `grep -ic 'conversation\|directMessage\|"social"'` = **0**. The tab is injected by the app shell, not declared by the package. **Not role-gated:** identical and equally empty under the second persona (Member, screenshot 54) as under Owner. | No — and none is possible: no workflow in the package binds to a `messages` tab |

Two candidate absences were investigated and **withdrawn** — both were my own search error, not product gaps:

- **Rollback card "missing" from Transfer.** My first pass used 900 px swipes and skipped it. Re-scanning in 600 px steps found `Rollback available` / `Roll back transfer` / `Cancel rollback` present on Transfer (screenshot T3) and on Admin (36). This is exactly the "a search that finds nothing is not evidence of absence" trap; recording it would have been a false finding.
- **Rollback card absent from Home.** Correct *by design*: its Home `renderBinding` covers only `["running","complete","failed"]` and the seeded instance is `available`. Its presence in `pinnedWorkflowIds` does not override the binding.

## Rendering bugs

| # | Bug | Where seen | Detail |
|---|---|---|---|
| **R1** | **Bare camelCase key rendered as a chip label instead of the field's value** | Home (Owner, screenshots 08/09); Home (Member, M3 / 51 / 52); replay card (50) | Three distinct fields observed: `memberNotice`, `safeMemberNotice`, `affectedMemberNotice`. The chip shows the *key*; sibling chips in the same card show *values*. **The same instance renders correctly elsewhere** — on Admin (12) and Documents (22) the identical `full-bundle`/`redacted-bundle` cards show "This backup contains community records under the protected-data policy." So this is a surface-specific rendering defect, not an authoring omission. Screenshot 51 is the cleanest reproduction: within one card, `redactionSummary` renders as a titled block with its text while `memberNotice` renders as the bare key. Common factor: `type: "textarea"` with `displayContexts: ["tile", …]` and **no `labelTemplate`**. |
| **R2** | **Raw ISO-8601 timestamps shown to the user as chips** | Admin (12), Documents (22), Audit (23), Transfer (32), Export (29) | e.g. `2026-08-10T08:00:00Z`, `2026-08-10T08:07:00Z`, `2026-08-09T11:00:00Z`. These are `type: "date?"` fields with no `labelTemplate`; they are surfaced verbatim rather than humanized. |
| **R3** | **Create-form field label derived from an unresolved `labelTemplate`** | New full bundle form (16) | `scope` is declared `"labelTemplate": "{value.length} components"`. With no value bound, the form label renders as lowercase **`components`** instead of "Scope", sitting alongside correctly-cased `Bundle Label` / `Destination` / `Member Notice`. |
| **R4** | **`{value.length}` not interpolated in the detail region — missing count** | Home (08/09), replay card (50) | `auditHistory` is declared `"labelTemplate": "{value.length} audit entries"` and renders as bare **`audit entries`** with the number absent, even where the list has 1 entry. The same `{value.length}` construct *does* resolve for `scope` as a chip ("3 components", "4 components"), so the failure is specific to the detail/history region. |
| **R5** | **Raw Dart map literal rendered to the user** | Audit tab (23, 24) | Under the `History` heading: `{result: passed, at: 2026-08-10T08:12:00Z, by: portability-owner}` — an unformatted `Map.toString()`, with braces, a raw timestamp and a raw role id. The same `auditHistory` data renders as a structured block on Home ("Result: / At: / By:") and as a dot-separated line on Export/Transfer ("previewed · portability-owner · 2026-08-09T09:00:00Z"). **Three different renderings of one field across three surfaces**; the Audit one is the only raw-literal leak. |
| **R6** | **Raw role ids shown where a person is meant** | Home, Export, Transfer, Audit | History lines attribute actions to `portability-owner` / `portability-receiving-provider` — role slugs, not display names. |
| **R7** | **Near-invisible disclosure header** | every tab (11, 21, 24, 25, 33) | The "Local package details" row renders in near-white on a near-white background, effectively illegible; its chevron and its content are legible. |
| **R8** | **State chip washed out to near-illegibility** | Transfer / Admin as Owner (31, 35) | `Replay validation failed` renders as pale amber-on-amber. The same state chip renders in legible red for the Member persona (50), so the amber tone variant is the problem. |

## Product finding — edit affordance offered to a role the package forbids

On **Member**'s Home, the `export-redacted-bundle` card (state `complete`) renders an editable `Redaction validation` text field and a `Save changes` button. Tapping the field **focused it and opened the soft keyboard** — `dumpsys input_method` reported `mInputShown=true` (screenshot 52 shows the focused green underline, cursor handle and keyboard).

The package forbids this: `export-redacted-bundle` → state `complete` → `"editableFields": ["redactionValidationResult"], "editGuard": { "allowedRoleIds": ["portability-owner"] }`. Sam Member is `portability-member`. The identical pattern exists on `export-full-bundle` state `complete` (`verificationResult`, same owner-only guard), which also renders as an editable field with `Save changes` for Member.

**Scope of what was verified:** I stopped at focus. I did **not** type and did **not** press `Save changes`, so I did not establish whether the engine would reject the write — nothing was mutated. The confirmed defect is that the **UI presents an edit affordance to a role the editGuard excludes**; whether the write would also be accepted is untested and should be treated as open.

## Stability

| Check | Result |
|---|---|
| `adb -s emulator-5554 get-state` | `device` at start and at end |
| `mCurrentFocus` | `com.example.loom_communities_demo/.MainActivity` throughout — never null, never a system dialog |
| ANR | **0** (`grep -ac "ANR in"`) |
| FATAL EXCEPTION | **0** (`grep -ac "FATAL EXCEPTION"`) |
| logcat control | 122,385 total lines; **1,157** lines matching `loom` — the grep demonstrably works, so the two zeros above are real absences |
| Other exceptions | 193 total; **11** touch the app, all `W WindowManager: Exception thrown during dispatchAppVisibility … EXITING`. All timestamped 22:36–04:51, i.e. **outside** this session's 05:11–05:33 window; they are system teardown warnings from earlier app exits, not Dart errors |
| Blank/blank-ish frames | One over-scroll into empty space on Admin (34, 59,503 B) — recovered by scrolling back; not a render failure |
| Crashes / restarts | None |

`grep -ac` was used throughout; `grep -c … || echo 0` was deliberately avoided.

## Screenshot index

All at 1080x2400, in `/tmp` (PNGs are gitignored; this manifest is the durable record).

| File | Bytes | Frame |
|---|---:|---|
| export-migration_01_list.png | 315,846 | Community list, top |
| export-migration_02_scroll.png | 263,048 | List scrolled to Export and Migration card |
| export-migration_03_gate.png | 123,639 | Identity gate; footer names the community; default role Owner/Admin |
| export-migration_04_signupform.png | 177,200 | Display name entered |
| export-migration_05_presignup.png | 126,948 | Pre-sign-up, default role unchanged |
| export-migration_06_home.png | 225,279 | Home as Priya Export / Owner/Admin |
| export-migration_07_home_b.png | 185,554 | Home — Download full bundle / Change scope |
| export-migration_08_membernotice_bug.png | 163,645 | **R1** `memberNotice` chip; **R4** "audit entries" |
| export-migration_09_home_c.png | 156,517 | Home — transfer card, R4, R6 |
| export-migration_10_home_end.png | 156,120 | Home end (identical to 09) |
| export-migration_11_disclosure.png | 183,758 | Disclosure expanded — tap registers; **R7** |
| export-migration_12_admin.png | 187,216 | Admin — memberNotice renders correctly here; **R2** |
| export-migration_13_admin_top.png | 237,141 | Admin top |
| export-migration_14_pre_create.png | 237,146 | **Pre-create frame** |
| export-migration_15_create_menu.png | 361,353 | Speed-dial, 8 create actions |
| export-migration_16_createform.png | 147,910 | New full bundle form; **R3** |
| export-migration_17_post_cancel.png | 237,109 | **Post-cancel frame — matches 14** |
| export-migration_18_tabbar_1.png | 237,603 | Tab bar scrolled |
| export-migration_19_tabbar_2.png | 237,603 | Identical to 18 → end of tab bar |
| export-migration_20_documents.png | 223,000 | Documents top |
| export-migration_21_documents_b.png | 147,712 | Documents end — "No seed files recorded." |
| export-migration_22_documents_mid.png | 204,974 | Documents — Download redacted bundle / Change redaction |
| export-migration_23_audit.png | 204,226 | Audit — **R5** raw map literal |
| export-migration_24_audit_b.png | 159,371 | Audit — Enable transfer / Export verification record |
| export-migration_25_messages.png | 158,046 | Messages — no affordance |
| export-migration_26_messages_top.png | 206,212 | Messages scrolled to top |
| export-migration_27_messages_bottom.png | 158,046 | Messages bottom (identical to 25) |
| export-migration_28_tabbar_home.png | 157,034 | Tab bar returned to start |
| export-migration_29_export.png | 215,125 | Export tab; **R6** |
| export-migration_30_export_b.png | 156,819 | Export — Start transfer / Change scope |
| export-migration_31_transfer.png | 223,637 | Transfer top; **R8** |
| export-migration_32_transfer_b.png | 183,989 | Transfer — verification card |
| export-migration_33_transfer_mid.png | 151,509 | Transfer end |
| export-migration_34_admin_end.png | 59,503 | Admin over-scroll (empty) |
| export-migration_35_admin_last.png | 183,886 | Admin — replay card |
| export-migration_36_admin_tail.png | 177,445 | Admin — **rollback card present** |
| export-migration_37_identity.png | 261,818 | Identity dialog; fan id `portability-owner-20` |
| export-migration_38_member.png | 223,054 | After Member radio tap — role unchanged |
| export-migration_39_identity2.png | 258,747 | Verification: still Owner/Admin |
| export-migration_40_after_member_tap.png | 223,716 | Second attempt via row tap |
| export-migration_41_verify_role.png | 258,755 | Still Owner/Admin |
| export-migration_42_back_list.png | 263,295 | Back to community list |
| export-migration_43_gate2.png | 225,349 | Re-entry resumed the existing session |
| export-migration_44_overflow.png | 231,350 | Overflow menu — only "Sync settings" |
| export-migration_45_specific_person.png | 172,788 | Account picker |
| export-migration_46_createform2.png | 173,626 | Create-account form |
| export-migration_47_roledropdown.png | 185,328 | Role dropdown, 3 roles |
| export-migration_48_member_selected.png | 174,885 | Sam Member / Member selected |
| export-migration_49_member_home.png | 205,489 | **Member sees only Home + Messages** |
| export-migration_50_member_editprobe.png | 159,194 | **R1** `safeMemberNotice`, `affectedMemberNotice`; **R4** |
| export-migration_51_member_field.png | 188,601 | **R1** cleanest repro (block vs bare key in one card) |
| export-migration_52_member_editprobe2.png | 204,958 | **Member edit affordance** — focused field + keyboard |
| export-migration_53_member_editproof.png | 197,055 | Keyboard dismissed, nothing mutated |
| export-migration_54_member_messages.png | 172,788 | Messages as Member — identical, not role-gated |
| export-migration_M1–M5.png | 205,449 / 169,522 / 192,439 / 192,591 / 183,748 | Member Home, stepped |
| export-migration_T1–T6.png | 223,636 / 187,427 / 178,695 / 177,714 / 163,746 / 152,049 | Transfer, stepped in 600 px increments (T3 holds the rollback card) |

## Pipeline result

**Functional end-to-end.** The rig drove a real emulator through a two-persona walkthrough of all 7 tabs without a single crash, ANR or blank render. Community selection, identity gate, account creation, role assignment, role-scoped tab visibility, workflow card rendering, create-form open/cancel, and disclosure expansion all behaved. Nine seeded workflow instances rendered across the six package-declared tabs with correct state labels, tones, transitions and role gating.

The defects found are **presentation-layer**, not structural: five distinct value-rendering failures (R1–R5) all trace to one root cause — **the card renderer falls back to raw output when a declared field lacks a resolvable `labelTemplate`**, emitting the field key (R1), a raw ISO timestamp (R2), an unsubstituted template (R3, R4), or a Dart map literal (R5). One behavioural finding (the Member-visible edit affordance) is a genuine role-gating gap in the UI layer.

## B25 coverage

**Provable now from this run**

- Community discovery, open, and identity gate for `community_data_portability`, with the gate footer naming the community before sign-up.
- Persona creation on the **default** role, with the assigned role recorded exactly as the app states it (Owner/Admin).
- Complete tab enumeration including horizontally-scrolled tabs, with end-of-bar proven by byte-identical frames.
- PRIMARY and ALTERNATE affordances with exact label text for **6 of 7** tabs.
- Create-form open → field inventory → cancel-without-submit, with a clean pre/post frame match.
- Role gating proven **positively** by a second persona: Member loses 5 of 7 tabs, exactly matching `visibleRoleIds`.
- Absence classification for the one affordance-free surface, with a working-query control (53 hits) alongside the zero result, plus a cross-role check.
- Stability: 0 FATAL, 0 ANR against a 1,157-line control.

**Blocked, and why**

- **PRIMARY/ALTERNATE for the Messages tab** — cannot be recorded, because the tab is not package-backed (0 declarations against a 53-hit control). This is a coverage gap in the *package*, not a walkthrough failure; nothing in this community can populate that tab.
- **Whether the Member edit actually commits** — untested by choice. Confirming it requires typing into a seeded instance and pressing `Save changes`, which would mutate seeded state during a read-only walkthrough. Verified only as far as "the affordance is presented and focusable".
- **Transitions were never fired.** Every button (`Download full bundle`, `Start transfer`, `Roll back transfer`, `Cancel transfer`, …) was inventoried but not pressed, so no state machine was exercised end-to-end. Terminal states, effect writes and `$timestamp`/`$actor` substitution remain unproven on device.
- **Checksum and opaque-id fields** are declared-but-never-seeded by deliberate design (the package header says so), and no `Checksum:` chip appeared anywhere. They need platform services and remain correctly unproven rather than faked.

## Independent verification (orchestrator, by eye)
`export-migration_52_member_editprobe2.png` pulled byte-identically and viewed: **confirms the
role-gating finding is real.** The Member persona's "Redaction validation" field shows a genuine focus
state — green underline, blinking-cursor handle, soft keyboard open, text pre-filled "passed" — on a
workflow (`export-redacted-bundle`, state `complete`) whose package-declared `editGuard.allowedRoleIds`
is `["portability-owner"]` only. Sam Member holds role `portability-member`. Also confirms the bare
`memberNotice` chip bug on the same card.

## Flagging this finding distinctly
Unlike every other absence found across the 8 prior walkthroughs (which resolved to *correctly*
role-gated or identity-scoped behavior), **this is the first UI-layer enforcement gap found in the
entire grind** — a control the package explicitly forbids a role from using is nonetheless rendered,
enabled, and focusable for that role. The agent correctly stopped short of typing/submitting, so
whether the backend write path would also incorrectly accept it from Member is **unverified and
open** — that is a distinct, narrower question from "should the UI show this at all." Given the
target security model's point #2 (actions scoped to role) and point #4 (all data access via APIs,
so a client-side rendering bug should not translate into a privilege escalation if the API enforces
its own guard), the API-side check is the one that actually matters for safety; but the UI bug is a
real defect regardless of what the API does, and is worth a root-cause/fix pass.

## Running tally (9 rigorous walkthroughs)
Cedar (1: dues), Book Club (1: Messages), Chess (1: disputes), Masjid Nur (0), Youth Soccer (0),
Garden Club (1: Messages), Camera Club (2), Ad-Free Community (0), Export and Migration (0 package
gaps, but **1 UI role-gating defect** — the first of its kind in the grind — plus 8 rendering bugs,
all traced to one root cause: the card renderer falling back to raw output when a field's
`labelTemplate` doesn't resolve).
