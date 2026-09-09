# B25 re-verification — Neighborhood Book Club / `book-nomination` — 2026-09-08

**Result: PARTIAL. The live write succeeded; the state could not be advanced.**

A `book-nomination` row was created live, through the real UI, by the intended fan, and is
confirmed in Postgres. It is stranded in `draft`, because **the `draft` card renders on no
surface for anyone** — so `submit-nomination` has no button to press and the terminal states
`submitted` / `selected` / `withdrawn` are unreachable through the app.

This supersedes the earlier BLOCKED manifest at this path: the Fan Passport gap it reported was
repaired, and sign-in worked end to end this session.

---

## 1. Identity authenticated

| Item | Value |
|---|---|
| Keycloak account | `loom-book-member-2` |
| Fan id (token claim) | `fan-book-member-2` |
| Realm / client | `loom` @ `192.168.56.10:30082` / `loom-test-client` |
| App Access role | `book-member` |
| Out-of-band token probe | **HTTP 200**, `preferred_username=loom-book-member-2`, `fanId=fan-book-member-2` |

**A real Keycloak login form was rendered and filled — not a silent SSO re-issue.** Before signing
in I ran `pm clear com.android.chrome`, hit the Keycloak logout endpoint (200), and `pm clear` on
the app itself; the entry gate then reported `LoomAuthNotLoggedInException: No Loom authentication
session is stored`, so no prior identity existed to inherit. The username/password form appeared
and was filled by hand (screenshots `07_kc` → `12_presign`).

`created_by_fan_id` on the resulting row is `fan-book-member-2`, matching the identity driven.

### Input truncation was hit and corrected

`adb shell input text 'loom-book-member-2'` rendered as `loom-book-membe` mid-update. Appending the
apparent remainder produced `loom-book-member-2r-2` — i.e. **the value had been complete and the
display was lagging**. The field was cleared and retyped, then verified (`10_crop`). Every
load-bearing value was afterwards settled against the stored row, not the screen (§4).

## 2. Path driven

1. App relaunched → *"Loaded 10 example communities"*.
2. Opened **Neighborhood Book Club**.
3. Entry gate → **"Continue to secure sign-in"** present on the non-error branch (`7558a3c5`
   behaved correctly).
4. Chrome first-run onboarding intercepted the redirect → dismissed via *"Use without an account"*.
5. Keycloak form → credentials entered and visually verified un-truncated (password revealed via
   the eye toggle: `LoomTest123!`, `!` included).
6. **Sign In** → redirect back to `MainActivity`; the account list now loaded.
7. Selected **Test book-member-2 / `fan-book-member-2`**; community opened, header read
   *"Signed in as Test book-member-2 — Member"*.
8. **Books** tab → create FAB → **"Nominate a book"**.
9. Filled all five fields; **Create**.
10. **Stopped here.** The Books tab renders no card for the new instance, so
    `submit-nomination` cannot be fired. See §5.

## 3. Database — baseline and final

Baseline immediately before the dispatch: **19** rows total, **0** of `book-nomination`.

```
select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at
from workflow_instances where workflow_type='book-nomination' order by created_at desc limit 5;
```

| Field | Value |
|---|---|
| `instance_id` | `community_neighborhood_book_club_book-nomination_il5zplsant0a` |
| `community_id` | `community_neighborhood_book_club` |
| `workflow_type` | `book-nomination` |
| `created_by_fan_id` | **`fan-book-member-2`** |
| `current_state` | `draft` |
| `created_at` | `1788917198712` (2026-09-09 01:26:38 UTC) |

Total moved **19 → 21**: this row, plus one control instance (§5). Both are attributed to
`fan-book-member-2`.

**Screen and row agree** on every field, and on the identity.

## 4. Stored fields — no truncation

`instance_data` read back from Postgres:

```
'title'        = 'Dune'
'author'       = 'Frank Herbert'
'reason'       = 'B25 live proof'
'genre'        = 'SciFi'
'meetingCycle' = '2026-Q4'
```

All five match what was typed. `nominatorFanId` and `submittedAt` are absent — correctly, since
both are written by the `submit-nomination` effect, which never fired.

## 5. DEFECT — the `draft` nomination renders on no surface, so it cannot be submitted

**Observed.** After Create, the Books tab shows only its header and *"Local package details"* —
no card. Reproduced across a tab switch, a community re-entry, a scroll, and a **full app
force-stop and relaunch** (`40_final_books`).

**Control (positive).** In the same session, as the same fan, in the same community, I created a
`book-discussion-message` via the Discussions tab. It rendered **immediately and completely** —
state chip *"Open"*, its prompt field, and all five transition buttons (`38_control`), and again
after the restart (`41_final_disc`). So instance-card rendering, role resolution and the remote
engine all work; the failure is specific to `book-nomination`'s `draft` binding.

The app was reaching the backend throughout: `LOOM_BINDING service=workflow-engine mode=remote
… outcome=ok status=200` for scope `ext_neighborhood_book_club`.

**Mechanism**, read from the rendering path (`part02_tab_shell.dart:1172` →
`deriveInstanceRoles` → `resolveBindings`):

- `book-nomination`'s `draft` render binding is `audience: "actor"`.
- `resolveBindings` matches a binding when the viewer's derived role set contains that string.
- `deriveInstanceRoles` scans the machine's transitions for the **first** guard carrying
  `actorEqualsField`. For `book-nomination` that is `revise-nomination`, keyed on
  **`nominatorFanId`** — so `actorFanId = instanceData['nominatorFanId']`.
- In `draft`, `nominatorFanId` is **unset**: it is written by the `submit-nomination` effect,
  which only fires on the way *out* of `draft` (confirmed absent in §4).
- So `actorFanId` is null, the viewer never earns `'actor'`, and the `draft` binding matches
  nobody — **including the creator**.

The instance is therefore permanently stranded: `submitted`, `selected` and `withdrawn` are all
unreachable through the UI.

Note the fallback that would have saved it exists but is skipped: when *no* transition declares
`actorEqualsField`, `deriveInstanceRoles` falls back to `instance.createdByFanId`, which is
populated. The defect appears only when such a transition exists *and* its key is unwritten in the
initial state.

**Same shape, not verified live** — three sibling workflows in this package have an initial-state
binding of `audience: "actor"` together with an `actorEqualsField` key written on exit:
`book-vote-response` (`voterFanId`), `book-shared-library-item` (`ownerFanId`),
`book-search-ai-digest` (`submitterFanId`). `book-selection-publish` and `book-export-metadata`
also bind `actor` but declare no `actorEqualsField`, so they take the `createdByFanId` fallback and
should be fine. Worth checking the other nine communities for the same pattern.

This belongs to the documented family *"a workflow can be perfectly valid and still have an outcome
nobody can reach"*: every individual guard here is well-formed, and the defect lives in the
interaction between the binding's audience, the actor-resolution order, and when the field is
written.

## 6. Environment

- Emulator `emulator-5554`, Windows-hosted, reached via `adb -H 192.168.56.1 -P 5037`.
- APK `lastUpdateTime=2026-09-08 18:12:21` — the post-`7558a3c5` build; **not** rebuilt.
- All six `loom` pods `1/1 Running`; load ~5 on 8 cores throughout.
- `book-nomination` is present in the deployed `workflow_definitions` catalog (12 `book-*` types),
  so this is not an unpublished-definition case.
- No ANR or crash from the Loom app. `dumpsys window lastanr` reports Chrome's `CustomTabActivity`
  at 17:35:21, **39 minutes before** this session began at 18:14.

## 7. What was not done

- `submit-nomination` was **not** fired — no affordance exists to fire it (§5). No terminal state
  was reached, and none is claimed.
- No application code, community JSON, tracker, or credential was created or modified.
