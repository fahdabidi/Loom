# GAP TICKET — the permission catalog is published from a hand-maintained file and has silently drifted

**Status:** 🟡 OPEN — Part A dispatched 2026-09-07 (Loom, implementation agent). Parts B and C follow in
order; C is the one that unblocks calendar workflows live.
**Severity:** functional — every community whose workflows use the `calendar` archetype is
uninstallable today (`400 unknown_permission_id`), and `calendar.*` cannot be granted to any role.
Not a security gap: no grant is over-issued, the whitelist is merely stale.
**Found:** 2026-09-07, while re-verifying tracker row "Declaring community admins as package roles
stops the DELETION but not the STRIPPING" (Access Control §8) against the deployed code and live DB.
That row's mechanism turned out to be stale — see "What is actually true" — and this is what remained.

## What is actually true (verified live, 2026-09-07 — not from tracker text)

- **The admin-role design the user described is implemented and deployed.** Vocabulary
  `governance.adminRole`: `isSystemDefault: true`, `idTemplate: "<communityHandle>-admin"`,
  `grantedPermissions` = exactly `community.view/invite/manage_members/manage_roles/manage_settings`.
  `installCommunityPackage` (backend `2818e32`, inside deployed `loom/app-access:0.3.9`) creates that
  role, grants those five, and shields it from the removal sweep. Live `loom_app_access`: all 11
  community groups hold a `<handle>-admin` with exactly the 5; no role named `admin` exists; zero
  groups lack an admin role. (Known separate anomalies, already tracked: `masjid-nur-admin` carries
  23 extra grants; a duplicate underscored Cedar group holds a 1-of-5 `cedar_commons_hoa_admin`.)
- **A catalog replace cannot strip a grant.** `role_permission` has **no foreign key to
  `permission`** (only to `app_role`, `ON DELETE CASCADE`). `replacePermissionCatalog` deletes and
  re-inserts catalog rows and only *reports* grants pointing at omitted ids (`orphanedRoleGrants`).
  The earlier fear that a replace would cascade or block was wrong on the mechanism.
- **The live catalog is stale.** 127 ids, `permission_catalog_version = 2026-08-26.2`,
  `catalog_published_at = 2026-08-26`. Against the vocabulary (116 ids): 106 shared; **10 missing**
  from the live catalog — the 9 `calendar.*` and `event_rsvp.send_reminder`, both added to the
  vocabulary on 2026-08-31, after the last publish; **21 legacy-only** live ids
  (`approval_queue.*`, `discussion_thread.*`, `form_entry.edit/delete`, `notification_inbox.*`,
  `payment_checkout.pay/refund/view_receipt`, `equipment_loan.borrow`, `event_rsvp.manage_attendees`,
  `table.publish`) that the vocabulary has since dropped — **every one has zero live grants.**
- **The publish input was never under version control in its published form.** The checked-in
  `loom-backend/spec/loom-communities-permission-catalog.json` has 69 entries, `catalogVersion
  2026-08-13.1`, and a single git commit (the repo scaffold). The 127-id 08-26 publish used a
  richer body that exists nowhere in either repo.
- **`ensurePermissionsExist` is the enforcement point**: install hard-fails with
  `400 unknown_permission_id` for any derived permission absent from the catalog. Correct behaviour;
  it is why the stale catalog blocks calendar.
- **The parity guard exists but the wrong copy was being run.** Loom's
  `docs/Build Plan V2/Tools/code/check_spec_parity.sh` compares the vocabulary twin
  (`docs/references/generated/permissions-vocabulary.json` ↔
  `services/app-access/src/main/resources/permissions-vocabulary.json`, lines 81–84) and already
  caught calendar drift once. The backend's `tools/check_spec_parity.sh` is an older OpenAPI-only
  version. Both twins are byte-identical today.

## Root cause

Three artifacts stand in for one chain, with two manual steps between them:

    ArchetypeResolver (Dart, source of truth)
      -> permissions-vocabulary.json   generated; copied by hand into the backend
        -> catalog JSON                 a SECOND, hand-maintained artifact  <- drifts
          -> replacePermissionCatalog   a manual step nobody is forced to run  <- skipped

Any archetype added after the last manual publish is invisible to the whitelist. Calendar is the
first; it will not be the last unless the parallel artifact and the manual step are removed.

## Design decision (user, 2026-09-07)

Single source of truth, no exceptions: display names live **in the resolver**, typed. The catalog is
**generated from the vocabulary** and **published by the backend on startup** from the vocabulary it
already bundles — so deploying the image *is* publishing. No separate catalog file, no separate
display-name table, no manual publish step. Rationale: every artifact beside the source of truth is
a place for drift to hide; these strings name authorization primitives and should change exactly as
deliberately as the permissions they label.

## Part A — Loom (dispatch from `~/Loom`, `data/call_implementation_agent.sh --fresh`)

**A1. Typed action records in `ArchetypeResolver`**
(`app/packages/core/loom_workflow_engine/lib/src/archetypes/archetype_resolver.dart`).
Today `bespokeVocabularies` is `Map<String, Set<String>>` of bare action ids (line ~310) and generic
families share `genericActions`. Introduce a small value type — e.g. `ArchetypeAction(id,
displayName, description)` — and declare every bespoke action and every generic action as one, so
an action without a display name does not compile. Keep the existing `Set<String>`-shaped accessors
(`bespokeVocabularies`, `genericActions`) available as derived views so **no current caller
changes**; the conformance test over real fixtures must keep passing untouched. Governance actions
(`view/invite/manage_members/manage_roles/manage_settings`) get the same records — move them from the
generator's `const governanceActions` list into the resolver (or a sibling `GovernanceVocabulary` in
the same file) so the generator declares nothing itself. Display names/descriptions: for the 5
`community.*` use the exact strings already live in the catalog (e.g. `community.invite` →
"Invite members" / "Issue invitations to join this community."); for archetype actions write
user-facing names in the same register (verb phrase, sentence-case, one-line description).

**A2. Generator emits the catalog data additively**
(`app/packages/tooling/loom_ux_judges/bin/generate_permissions_vocabulary.dart`). Do **not** change
or remove any existing key — the Java parser reads `bespokeArchetypes/*.permissionPrefix`,
`*.actions`, `governance.adminRole.*`, and `docs_sync_checker.dart` reads `archetypeContracts`. Add,
for every family (bespoke, generic, governance), a parallel `catalog` array of
`{permissionId, displayName, description, category}` where `category` is the family's
`cardSurfaceFamily` (the rule the old catalog file's own header states), and a top-level
`catalogVersion` derived deterministically from the content (e.g. `sha256` of the sorted permission
ids + names, or the spec version + content hash) so two identical vocabularies publish the same
version and any change publishes a new one. Regenerate `docs/references/generated/permissions-vocabulary.json`.

**A3. Tests.** Extend `test/permissions_vocabulary_artifact_test.dart`: every `permissions[]` id has
exactly one `catalog[]` entry with a non-empty `displayName`; the `community.*` entries match the
five known strings; `catalogVersion` is stable across two generations and changes when an action is
added (construct the test so it proves both). The existing "byte-identical to what the generator
produces now" test stays and must pass against the regenerated artifact.

**A4. Sync the twin.** Copy the regenerated vocabulary into
`~/loom-backend/services/app-access/src/main/resources/permissions-vocabulary.json` byte-identically,
and run Loom's `check_spec_parity.sh` (the Tools/code copy, which covers the vocabulary) — must
report parity. Do **not** rebuild/deploy the backend in this part; Part B consumes the new keys.

Verification for A: `flutter analyze` clean on `loom_workflow_engine` and `loom_ux_judges`;
`dart run bin/generate_permissions_vocabulary.dart --check` exits 0; the five suites with real
totals pasted (baselines in CLAUDE.md — engine 312(+5), judges 498 as of 2026-09-07, app shell
381(+2), demo 160; workflow service unaffected but run it). No existing `hasLength`/`expect` count
lowered.

## Part B — backend (dispatch from `~/loom-backend`, its own `data/call_implementation_agent.sh --fresh`)

**B1. Startup reconcile.** In `app-access`, add a bean that runs once the application is ready
(no startup hook exists yet — `grep ApplicationRunner|ApplicationReadyEvent` is empty; use
`@EventListener(ApplicationReadyEvent)` or `ApplicationRunner`) and reconciles the live catalog for
`loom_communities` against the bundled vocabulary's new `catalog[]` data:
- **upsert** every vocabulary permission (insert missing, update `displayName/description/category`
  on existing) — never delete;
- **report, do not delete,** catalog ids absent from the vocabulary and any `role_permission` rows
  pointing at them (the 21 legacy ids; log at WARN with counts) — retirement is a deliberate,
  separate operation, not a side effect of boot;
- set `app.permission_catalog_version = vocabulary.catalogVersion` and `catalog_published_at = now()`
  **only when something changed**, so an idle restart is a no-op and the timestamps stay meaningful;
- idempotent and safe under concurrent replicas (single transaction; tolerate a lost race on insert).
Reuse `CommunityPermissionDeriver`'s vocabulary loader (`loadVocabulary`, `ClassPathResource
"permissions-vocabulary.json"`) — extend its parse to read `catalog[]`/`catalogVersion`; do not load
the file a second way. `replacePermissionCatalog` stays as the explicit full-replace API.

**B2. Parity gate in `build.sh`.** Before `mvn` runs, invoke the parity check and fail the build on
drift. Replace the backend's stale `tools/check_spec_parity.sh` with a byte-identical copy of Loom's
(`docs/Build Plan V2/Tools/code/check_spec_parity.sh`), which covers the vocabulary twin; a build
whose bundled vocabulary differs from Loom's must not produce an image.

**B3. Delete `spec/loom-communities-permission-catalog.json`** and any reference to it. It is the
parallel artifact this ticket exists to remove. Its header comment's category rule now lives in the
generator.

**B4. Tests.** Integration test (real Postgres, per the repo's existing pattern): boot against a
catalog missing N ids → after startup they exist with the vocabulary's names and the version is
stamped; boot again → no writes, timestamp unchanged; a catalog containing a retired id with a live
grant → row and grant both survive and a WARN is logged. Suite counts pasted (app-access was 60 tests
at `d2bb649`; must not go down).

Verification for B: `./build.sh test app-access` green with pasted totals; parity gate proven to
fail by temporarily perturbing the bundled copy in a scratch check, then restored.

## Part C — deploy, publish, prove (me, directly — infra, not code)

**Before-snapshot, captured live 2026-09-07 (the numbers C must reproduce or explain):**
`permission` rows **127**; `role_permission` rows **425**; admin roles holding exactly 5
`community.*` grants **11 of 11**; `app.permission_catalog_version = 2026-08-26.2`,
`catalog_published_at = 2026-08-26 02:15:29+00`. Deployed image `loom/app-access:0.3.9` ==
manifest `deploy/k8s/app-access.yaml:41` == backend HEAD at that moment (`2500208`); next tag
`0.3.10`. After C: `permission` rows must be **137** (127 + the 10 missing; the 21 retired ids
untouched), `role_permission` **still 425** (nothing added or removed by the reconcile), admins
**still 11 of 11 at exactly 5**, and the version/timestamp freshly stamped once — a second restart
must not move the timestamp.

Build and import the app-access image, bump the manifest tag, `kubectl apply`, **commit the manifest
bump** (the twice-repeated trap), then the audit: deployed image == manifest == HEAD;
`check_spec_parity.sh` clean. Prove the reconcile ran: `select permission_catalog_version,
catalog_published_at from app` shows the new version and a fresh timestamp; the 10 missing ids now
exist with display names; the 21 legacy ids and all `role_permission` rows are untouched (row counts
identical before/after); all 11 admins still hold exactly their 5 (`community_grants = 5`). Then the
real end-to-end: install (or re-install) one calendar-bearing community through the provisioning
tool's normal path and confirm `ensurePermissionsExist` no longer 400s and `calendar.*` lands on its
roles. Only then is this ticket closed and the calendar blocker in Access Control §8 with it.

## Open question carried, not decided here

The code grants the `<handle>-admin` role **only** the 5 governance permissions; workflow permissions
come from also holding a domain role (`permissions.md` §7: a person may hold `[garden-club-admin,
garden-coordinator]`). The user's 2026-09-07 description could be read as the admin role itself also
carrying the workflow permissions. Concrete consequence: `masjid-nur-admin` holds 5 + 23; a
re-install trims it to 5. Nothing in this ticket changes that behaviour; it needs a one-line ruling.

## Constraints

- Application code only via the implementation agents; `docs/references/**` untouched; no community
  JSON touched.
- Part A must not break the Java parser or `docs_sync_checker.dart`: additive keys only.
- No deletion of catalog rows or grants anywhere in A or B. Retirement of the 21 legacy ids is a
  separate, explicit decision.

---

## Part C — DEPLOYED AND PROVEN, 2026-09-08

Deployed `loom/app-access:0.3.10` (manifest bump committed **before** `kubectl apply`, as
`047e0be`, and pushed). Rollout clean; new pod ready with 0 restarts.

### The reconciler's own report (not the proof — the thing being checked)

```
Permission catalog for app 'loom_communities' retains retired permission ids [21 ids];
retiredCatalogPermissionCount=21, retiredRolePermissionCount=0, retiredRolePermissionGrantCounts={}.
No permission or role_permission rows were deleted.
Reconciled permission catalog for app 'loom_communities': inserted=10, updated=106,
catalogVersion='4-d15e5ea24e19457a20a7ffff9e296caef264ead2582529e18f2849bec9f066a5'
```

### Proven independently in the live database

| Quantity | Before (committed) | Predicted | Measured after | |
|---|---:|---:|---:|---|
| `permission` rows | 127 | 137 | **137** | ✅ |
| `role_permission` rows | 425 | 425 (unchanged) | **425** | ✅ |
| admin roles with exactly 5 `community.*` | 11 | 11 | **11** | ✅ |
| `permission_catalog_version` | `2026-08-26.2` | fresh generated hash | **`4-d15e5ea2…`** | ✅ |

- All **9 `calendar.*`** ids present, each with a real display name (`Create calendar item`,
  `Deliver reminder`, …) — no placeholders, and `blank_display_names = 0`.
- `event_rsvp.send_reminder` present — the tenth insert.
- `community.*` still **5** — the hand-granted governance permissions were *not* dropped, which was
  the specific fear this whole ticket was written around.
- The 21 retired ids are still present (sampled 4/4), consistent with report-never-delete.

### The second boot is a true no-op — proven by state, not by the log line

Restarted the pod again. The log says "already matches … no writes were made", but the load-bearing
evidence is that **`catalog_published_at` is byte-identical across the restart**
(`2026-09-08 06:49:06.134546+00` before and after), with counts still 137/425. A version re-stamp
would have moved that timestamp.

### The calendar blocker is structurally closed

`ensurePermissionsExist` 400s `unknown_permission_id` exactly when a *derived* permission is absent
from the catalog, and `CommunityPermissionDeriver` can only derive ids its bundled vocabulary names.
So the decisive check is vocabulary ⊆ catalog. Measured, with a control:

- vocabulary ids: **116**; present in the live catalog: **116** (the control — a broken query would
  have shown 0 here, and did on the first attempt, which is how a wrong grep was caught)
- vocabulary ids **missing** from the catalog: **0**
- catalog ids not in the vocabulary: **21** — exactly the retired set, nothing unexplained
- `calendar.*` in both: 9

The derived set is a subset of the vocabulary by construction, so no install can now fail on
`unknown_permission_id`.

### What Part C deliberately did NOT do

The plan's last line was "re-install one calendar community end-to-end". **That step was not run, on
purpose.** `installCommunityPackage` replaces every declared role's permissions and deletes every
group-scoped role the package does not declare — it would destroy the 11 community admin roles,
unrecoverably, since their `community.*` grants are not archetype-derived. That is the open
**role deletion** decision (A declare admin in packages / B reserved naming / C provenance tracking),
not something this ticket resolves. Running it to "prove" the catalog fix would have traded a
verified blocker for an unrecoverable one.

The catalog precondition it was meant to prove is proven above by a check that does not require the
destructive path. A live install remains the right final proof **after** the role-deletion decision
lands.

### Post-deploy audit (the three-source comparison)

Deployed `loom/app-access:0.3.10` == manifest `deploy/k8s/app-access.yaml:41` == committed HEAD
`047e0be`, `git status` clean, spec parity 8/8 + generated artifact 1/1. All six pods ready with no
new restart counts, and app-access answers a real request (401 with auth enforced, i.e. serving) —
checked because a heavy image build on this node has previously left services Running but broken.
