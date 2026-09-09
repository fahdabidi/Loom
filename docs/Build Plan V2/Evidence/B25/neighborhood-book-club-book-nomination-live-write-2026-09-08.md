# B25 re-verification — Neighborhood Book Club / `book-nomination` — 2026-09-08

**Result: BLOCKED. No live write was produced. Zero `book-nomination` rows exist.**

The blocker is a **seeding gap in Fan Passport**, not a package defect, not an app defect, and
not a credential fault. It is **systemic across the whole 2026-09-09 second-holder seeding pass**,
not specific to this community.

---

## 1. Identity authenticated

| Item | Value |
|---|---|
| Keycloak account | `loom-book-member-2` |
| Fan id (from token claim) | `fan-book-member-2` |
| Realm / client | `loom` @ `192.168.56.10:30082` / `loom-test-client` |
| Password-grant probe | **HTTP 200**, `preferred_username=loom-book-member-2`, `fanId=fan-book-member-2` |
| App Access role | `book-member`, group `loom_communities_neighborhood-book-club`, state `active` |

Authentication **succeeded on the device**. The `LOOM_BINDING` log shows `service=app-access …
outcome=ok status=200` for scope `ext_neighborhood_book_club` immediately after the OAuth redirect.

A real Keycloak login form was rendered and filled (screenshot `16_kcform` → `18_pass`); this was
**not** a silent SSO re-issue of a previous fan. `pm clear com.android.chrome` was run beforehand and
the app reported `LoomAuthNotLoggedInException: No Loom authentication session is stored` at launch,
so no prior identity existed to inherit.

## 2. Path driven

1. App relaunched; community list rendered — *"Loaded 10 example communities"*.
2. Opened **Neighborhood Book Club**.
3. Entry gate → **"Continue to secure sign-in"** (present on the non-error branch; the `7558a3c5`
   fix behaved correctly).
4. Chrome first-run onboarding intercepted → dismissed via *"Use without an account"*.
5. Keycloak form rendered; username and password entered and **visually verified un-truncated**
   (password revealed via the eye toggle: `LoomTest123!` exact, including the `!`).
6. **Sign In** → OAuth redirect returned to `MainActivity`.
7. **Blocked here.** The account gate renders, in red:

   > Bad state: App Access membership for fan "fan-book-member-2" in community
   > "community_neighborhood_book_club" has no Fan Passport record.

   No account tile is rendered, so there is nothing to select and no route into the community.
   **Reproduced deterministically** — identical after tapping *Retry*.

Never reached: the `books` tab, the *"Nominate a book"* FAB, the `draft` form, or
`submit-nomination`.

## 3. Database — baseline and final

Query run against `loom_workflow_service` on `postgres-0`, before and after.

| | Baseline | Final |
|---|---:|---:|
| `workflow_instances` total | **19** | **19** |
| `workflow_type = 'book-nomination'` | **0** | **0** |

```
select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at
from workflow_instances where workflow_type='book-nomination' order by created_at desc limit 5;
-> (0 rows)
```

**Control:** the same table returns 16 other `workflow_type` values across those 19 rows, so the
query mechanism is sound and the zero is a real negative, not a broken query.

**Screen and database agree: nothing was created.** No row, and no screen ever claimed one.

## 4. Root cause — verified, and wider than this ticket

`book-nomination` is **published** (`workflow_definitions`, version 4, alongside 11 other
book-club types; 85 definitions total), so the effect target exists. The gap is at the identity
layer.

`fan-book-member-2` exists in **Keycloak** and in **App Access** (membership + `book-member` role,
both `active`) but has **no `fan_passport` row**. Confirmed three independent ways: the app's own
error text, `LOOM_BINDING service=fan-passport … status=404`, and a direct query.

**Control:** `fan_passport` holds **43** rows, of which the book club has
`fan-book-admin`, `fan-book-member-1`, `fan-book-organizer-1` — so the query works, and the
absence of `fan-book-member-2` is real.

### The gap is systemic

Cross-layer audit — every fan with an App Access membership but no Fan Passport record:

```
61 app-access fans; 43 passports
missing: fan-ad-off-member-2, fan-ad-off-owner-2, fan_alice, fan_bob,
         fan-book-member-2, fan-book-organizer-2, fan-camera-member-2,
         fan-camera-organizer-2, fan-chess-member-2, fan-chess-organizer-2,
         fan-chess-owner-2, fan-garden-coordinator-2, fan-garden-member-2,
         fan-hoa-member-2, fan-masjid-member-2, fan-portability-member-2,
         fan-portability-owner-2, fan-portability-provider-2, fan-soccer-coach-2,
         fan-soccer-guardian-2, fan-soccer-owner-2, fan-social-member-2,
         fan-social-moderator-2, fan-tabletop-member-2, fan-tabletop-organizer-2
```

**Every `*-2` fan seeded on 2026-09-09 UTC is affected** (23 of them; `fan_alice`/`fan_bob` are
older fixtures). Book club timestamps: `fan-book-member-2` joined `2026-09-09 00:14:23Z`,
`fan-book-organizer-2` `00:22:11Z` — versus the working `*-1` fans seeded `2026-08-31`.

The second-holder seeding pass wrote Keycloak + App Access and **skipped Fan Passport**, so none of
those 23 accounts can pass the app's account gate. This is the *"a capability has to be true at
every layer"* pattern: the role is provisioned, the membership is active, the credential works, and
the account is still unusable in the UI.

Note the consequence for the campaign this seeding was meant to unblock: the second holders were
seeded to make two-party same-role interactions reachable, and **not one of them can currently sign
in**.

## 5. Why no in-scope workaround exists

`book-nomination` gates all three steps on `book-member` — the create FAB
(`actions[0].byRoleIds: ["book-member"]`), the `draft` `editGuard`, and the `submit-nomination`
guard. `book-organizer` can only fire `select-for-ballot` **from** `submitted`, so an organizer
cannot originate a nomination.

| Account | Holds `book-member` | Has passport | Password known | Usable |
|---|---|---|---|---|
| `fan-book-member-1` | yes | yes | **no** (replaced 2026-09-04, unrecorded; ticket forbids use/reset) | no |
| `fan-book-member-2` | yes | **no** | yes | no |
| `fan-book-organizer-1` | no | yes | yes | no — cannot create |

The intersection of "holds `book-member`", "has a Fan Passport record" and "has a known password"
is **empty**. No credential was created or reset, per the ticket.

## 6. Remedy

Create Fan Passport records for the 23 fans listed above (at minimum `fan-book-member-2`), then
re-run this walkthrough. Seeding, not a code or package change.

Worth adding to the parity gates: this class — App Access membership without a Fan Passport record
— is exactly what `check_spec_parity.sh` / `check_published_definitions.sh` do for their own layer
pairs, and nothing currently compares these two. The `comm -23` audit in §4 is the whole check.

## 7. Evidence

Screenshots are `*.png` and therefore gitignored; sha256 recorded here, files under `/tmp/b25evi/`
on the VM for the life of that directory.

| File | sha256 | Shows |
|---|---|---|
| `04_bookclub.png` | `bd3ac3bbeed486dda3c032401ea5826c3500529a9f5abab630398454d359cc30` | entry gate, secure sign-in available |
| `12_anr.png` | `c371d098734c206a3a12317ce88508e91e25645b6e398d463517ea7c5342d18c` | Keycloak form behind Chrome ANR dialog |
| `16_kcform.png` | `8f890ba6c2353712a2464cb160e474c2f4ce3b868e7c223f4f56908fc921c7a9` | real login form, empty fields (no SSO re-issue) |
| `17_user.png` | `0b410fc0799d1985c8dc77202dfc64e759934cdd5924d79d9b79f349de3e53b7` | username `loom-book-member-2` un-truncated |
| `18_pass.png` | `102f6d429781b931f1bd7ae82d3e239a56bcae9b820affdb3c3d7a8c3489a4a4` | password revealed, exact |
| `19_after_signin.png` | `6cdadb99014703811e39209d8931cee66e91245eb4bd24844c9b7143660fe804` | post-OAuth Fan Passport error |
| `20_retry.png` | `77e0b12f94fd578c032d6ccda3643962ee085659c5b2076c2897b97e00152bf8` | identical after Retry — deterministic |

## 8. Environment notes

- All six `loom` pods `1/1 Running` throughout; `app-access` answered `200`. No `403`, no
  `unknown_permission_id`.
- The emulator is slow enough that Chrome ANR'd repeatedly during first-run. CPU sampling
  (`/proc/<pid>/stat`, +8.85s CPU over 45s) showed it working, not deadlocked, so it was waited out
  rather than killed. `settings put global hide_error_dialogs 1` was used to stop the ANR dialog
  stealing input focus, and **restored to `0`** afterwards. This is emulator performance, unrelated
  to the finding.
- No application code, community JSON, or tracker was modified. No credential was created or reset.
