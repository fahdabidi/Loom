# Camera Club — `critique-submission` live write, re-verified with database proof

**Date:** 2026-09-08 (device local, America/Los_Angeles = UTC-7; engine stamps are UTC, so
`09:18:18Z` and `09:19:27Z` are 02:18 and 02:19 local)
**Device:** `emulator-5554`, Android 16 (SDK 36), `sdk_gphone64_x86_64`, 1080x2400
**adb path:** the emulator is **Windows-hosted**; this session ran **on the Loom VM itself**
(`fahd-VirtualBox`), which has no AVD and no `qemu-system` process. It was reached by talking to the
**Windows host's adb server** — `adb -H 192.168.56.1 -P 5037`. See Finding 5.
**App:** `com.example.loom_communities_demo/.MainActivity`, APK installed 2026-09-08 00:17:13
**Workflow:** `critique-submission` in Camera Club (`community_camera_club`)
**Supersedes:** `camera-club-critique-live-write-2026-09-04.md`, whose claim was reopened for having
no corresponding database row.

## Outcome

Both halves of the proof standard were met **in one session**, and the UI evidence and the Postgres
row are reported together and **agree**.

- Signed in for real as `loom-camera-member-1` through the in-app OAuth flow against Keycloak.
- Created a `critique-submission` **from nothing** through the real UI ("New critique" FAB on the
  Critique tab), reaching `draft`.
- Drove `submit` through the real UI, reaching **`submitted`** — a clearly-advanced state.
- Read the row back from Postgres with `kubectl exec … psql` after each step.

**No role escalation was needed.** `camera-club-member` is sufficient for both the create action and
the `submit` transition; only `review`/`request-changes` require `camera-club-organizer`.

## Baseline — confirmed, not stale

The ticket's control was *"`workflow_instances` held **6** rows total, and **zero** of
`workflow_type = 'critique-submission'`."*

**That was exactly correct** at this session's first database read (01:56 local, before any device
interaction):

```
 count
-------
     6

      workflow_type       | count
--------------------------+-------
 hoa-facility-reservation |     3
 hoa-dues-payment         |     2
 hoa-owner-notification   |     1
```

Zero `critique-submission` rows. The single row below is therefore necessarily this session's.

## Identity

Seeded Keycloak account on the documented convention, **authenticated for real** against realm
`loom` at `192.168.56.10:30082` via the in-app OAuth flow (Chrome custom tab) — not selected from a
list. Password `LoomTest123!` was accepted. No credential was created or reset.

| Display name | fan id | Keycloak username | Role (label) | Role id |
|---|---|---|---|---|
| Camera Member 1 | `fan-camera-member-1` | `loom-camera-member-1` | Member | `camera-club-member` |

Independent control before driving the UI — a direct password grant against `loom-test-client`
returned HTTP 200 with `preferred_username: loom-camera-member-1` and **`fanId: fan-camera-member-1`**.

## Path driven

1. Community list → **Camera Club** → community entry gate.
2. Entry gate → selected **Camera Member 1** (`fan-camera-member-1`). Signed in.
3. Bottom nav → **Critique** tab. Empty, as expected for a remote community.
4. **"New critique"** FAB → `New critique` dialog. Filled all five required `formEntry` fields:
   `photoTitle`, `promptOrTopic`, `notes`, `consentNote`, `photoImage`. → **Create**.
5. Card rendered in state **Draft critique** with `Save changes` / `Submit critique` /
   `Withdraw critique`.
6. **Submit critique** → card re-rendered as **Submitted for critique**.

Final UI state: chip **"Submitted for critique"**, attribution chip **"By Fan Camera Member 1"**, and
the action set correctly narrowed to the author's own actions in `submitted` — **Reply** and
**Withdraw critique**. The organizer-only actions (`Complete critique`, `Request changes`) were
correctly **absent** for a member.

## The database row

Read back with `kubectl exec -n loom postgres-0 … psql`, after `create` and again after `submit`.

| field | value |
|---|---|
| `instance_id` | `community_camera_club_critique-submission_hqn35lcajo7l` |
| `community_id` | `community_camera_club` |
| `workflow_type` | `critique-submission` |
| `created_by_fan_id` | **`fan-camera-member-1`** |
| `current_state` | **`submitted`** |
| `created_at` | `1788859098226` = 2026-09-08 **09:18:18Z** (02:18 local) |
| `updated_at` | 2026-09-08 **09:19:27Z** (02:19 local) |

After `create`, `current_state` read `draft`; after `submit` the same `instance_id` read `submitted`.
Total `workflow_instances` went **6 → 7**.

`instance_data` as stored server-side:

```json
{
  "authorFanId": "fan-camera-member-1",
  "comments": [],
  "photoTitle": "Harbour Fog at Dawn",
  "promptOrTopic": "Low light and minimalism",
  "notes": "Shot at f8 1/60s ISO 400 ",
  "consentNote": "Consent given to share thi",
  "photoImage": "harbour-fog-dawn.jpg",
  "submittedAt": "2026-09-08T09:19:27.898350Z"
}
```

**Do the two agree? Yes.** `created_by_fan_id` is `fan-camera-member-1`, which is the identity the
OAuth token carried and the identity the UI attributed the card to ("By Fan Camera Member 1").
`authorFanId` — a `writableBy: platform` field — was populated with the same id, so the server, not
the client, resolved the actor. `submittedAt` is a `writableBy: effect` field with no UI control; its
presence proves the `submit` **transition** executed server-side rather than the row merely being
re-saved.

Service binding diagnostics read from the app's own Account dialog during the run confirm the path
was remote throughout: Workflow engine `http://192.168.56.10:30083/` **remote**, last call
success (200); App Access `:30080` remote, 200; Fan Passport `:30081` remote, 200.

## Findings

### Finding 1 — a stale Keycloak SSO cookie re-authenticates the *previous* user, silently

This blocked the run for ~15 minutes and is the trap most worth carrying forward.

The app had a live session as **`fan-hoa-board-1`**, left over from the Cedar work. Selecting Camera
Member 1 at the entry gate correctly refused:

> Sign-in failed: LoomAuthException(accountNotFound): The authenticated Loom identity cannot sign in
> as account "fan-camera-member-1". Sign in with that person's identity provider session instead.

That guard is **working as designed** — the picker cannot impersonate. But the obvious remedy fails
in a way that looks like success. Running *Sign in securely with Loom…* → *Continue to secure sign-in*
opened the Chrome custom tab, **never displayed a login form**, and returned in ~10 seconds to a
green **"You're signed in — Your secure Loom session is ready."** The community screen still read
**"Signed in as Hoa Board 1"**. Keycloak had a valid SSO cookie for the previous user and re-issued a
token for *them*, without prompting.

**The success screen proves a token exists, not whose it is.** This is the same shape as the
verification traps already in `CLAUDE.md`: a healthy-looking signal measuring the wrong thing. Two
consecutive "You're signed in" screens in this session denoted two different identities.

The fix is to end the browser SSO session first — not to reset anything:

    adb shell am start -a android.intent.action.VIEW \
      -d "http://192.168.56.10:30082/realms/loom/protocol/openid-connect/logout"
    # Keycloak renders "Logging out — Do you want to log out?"; tap Logout.

After that, the same in-app flow presented the real **"Sign in to your account"** form, and
`loom-camera-member-1` / `LoomTest123!` was accepted. **Always confirm the post-login identity
against the community screen's "Signed in as …" line before trusting a walkthrough.**

Chrome's first-run onboarding ("Chrome notifications make things easier") did intercept once, as the
ticket warned; dismissed with **No thanks**.

### Finding 2 — `photoImage` is a required image field with no image affordance

`photoImage` is declared `"type": "image"`, `"required": true`, `"writableBy": "formEntry"`,
`"storage": "reference"`. The `New critique` dialog renders it as a **plain single-line text input**,
identical to the text fields beside it. There is no picker, no camera action, no file chooser, and no
upload — the only way to satisfy a required image field is to type a string. The value stored was the
literal text `harbour-fog-dawn.jpg`; no bytes exist anywhere, and `storage: reference` has nothing to
reference.

This is a genuine product finding: the workflow cannot actually carry a photograph, in a community
whose entire purpose is critiquing photographs. Reported, not papered over — the field was filled
with an honest placeholder string rather than pretending an image was attached.

### Finding 3 — the submitted card renders the field *name* `photoImage`, not its value

On the `submitted` tile the chips read `Harbour Fog at Dawn`, `photoImage`,
`Prompt: Low light and minimalism`, `By Fan Camera Member 1`. The second is the **literal field
key**, not the stored value (`harbour-fog-dawn.jpg`) and not an image.

The neighbouring fields each declare a `labelTemplate` (`"{value}"`, `"Prompt: {value}"`);
`photoImage` declares `displayIcon` and `displayContexts: ["tile","detail"]` but **no
`labelTemplate`**. Whether the defect is the missing template in the package or the renderer's
fallback to the key is not established here — both readings are consistent with what was observed,
and confirming it needs a look at the tile renderer's default path. Recorded as an observation, not
a diagnosis. It is closely related to Finding 2 and probably wants fixing with it.

### Finding 4 — `uiautomator dump` returned stale trees repeatedly

Several dumps returned the **previous** screen's node tree while the screenshot showed the current
one — most visibly on the Account dialog, where two scroll gestures appeared to do nothing in the
dump and had in fact scrolled a long way. Acting on the dump would have produced "the affordance does
not exist" reports for affordances that were plainly on screen.

Consistent with the standing rule: **when a parsed status contradicts the raw evidence, the raw
evidence wins.** Screenshots were treated as authoritative and the dump used only for coordinates,
re-confirmed against a fresh capture.

### Finding 5 — the emulator is reachable from the VM via the Windows host's adb server

`CLAUDE.md` records that the emulator lives on Windows and the VM has no AVD, which reads as "you
cannot drive the device from a VM session". You can. The Windows adb server listens on
**`192.168.56.1:5037`** across the host-only network, and the VM's own `adb` client drives it fully —
`shell`, `input`, `exec-out screencap`, `logcat`, `dumpsys` — with no `connect`/`disconnect` and no
`kill-server`:

    adb -H 192.168.56.1 -P 5037 devices -l
    # emulator-5554  device product:sdk_gphone64_x86_64 model:sdk_gphone64_x86_64

Same family as the "blocked on a Windows setting" lesson already in `CLAUDE.md`: the limitation was
incidental to where the client was running, not intrinsic to the task.

## Harness artifacts — not product defects

`adb shell input text` needs `%s` for spaces; a plain space silently truncates the string at the
first one (`Harbour Fog at Dawn` first landed as `Harbour`). Two long values were also truncated
mid-word (`notes` at `…ISO 400 `, `consentNote` at `…share thi`) because `KEYCODE_BACK` was sent to
dismiss the keyboard while `input text` was still typing. **Neither truncation is product
behaviour** — `notes` allows 1200 characters and `consentNote` 500, and both stored values are well
under those limits. Recorded so no future reader reads the stored strings as evidence of a length
bug.

## Stability

No crash and no ANR for the Loom app. `dumpsys window lastanr` holds a single ANR from **01:21:05**,
before this session began, and it belongs to **`com.android.chrome`**, not to
`com.example.loom_communities_demo`. No `FATAL EXCEPTION` / `AndroidRuntime` crash lines in logcat
for the app; its process stayed alive throughout.

## Not done

- The workflow was **not** driven to a terminal state. `reviewed` requires `camera-club-organizer`
  (`review`), and `withdrawn` would have destroyed the very row this ticket asks to prove. `submitted`
  is a clearly-advanced state and is what the ticket permits.
- No test suites were run; this ticket is a device walkthrough plus a database read, and no
  application code, community JSON or tracker was modified.
