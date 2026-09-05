---
status: current
audience: llm-agent
---

# Skill versioning — `skillVersion`, and how to migrate a community forward

**Why this exists.** On 2026-09-05, an investigation into a live permission anomaly (Masjid Nur's
system admin role carrying 28 grants instead of the platform baseline of 5) traced back to a
mundane cause: Masjid Nur's package was authored 2026-08-11, before the `owner` role convention
existed (ratified 2026-08-24), and was never regenerated since — only patched by narrow, deliberately
surgical dispatches (§17) that correctly preserved everything outside their exact scope, including the
missing convention. Three other communities (Ad-Free, Book Club, Garden Club, Data Portability) *did*
get regenerated after that date and picked up the convention automatically. Nothing told anyone Masjid
Nur was stale; it was found by accident, days later, while investigating something else.

The fix is not a periodic audit script — that only catches drift when someone remembers to run it.
**The fix is versioning the artifacts themselves**, so every future Skill invocation — even a narrow,
single-field fix — is structurally forced to check currency before doing anything else.

## The mechanism

1. **Every shipped community JSON declares `skillVersion`** at the package root, beside `specVersion`:
   ```jsonc
   "specVersion": 4,
   "skillVersion": "3.3.0",
   ```
   This records which Skill version last touched the file — not necessarily a full regeneration, any
   touch. A file with no `skillVersion` predates this mechanism entirely (2026-09-05); treat it as
   `0.0.0` for comparison purposes only, never write that literal string.

2. **The Skill itself has a version**, recorded at the top of this document (see "Current version"
   below) and bumped on every change that affects what a conformant community JSON looks like.
   - **MINOR** (`x.Y.0`) — additive. Existing packages remain valid; a new capability, field, or
     declared value becomes available but nothing already shipped is now wrong.
   - **MAJOR** (`X.0.0`) — a package built against an earlier major version is not simply
     out-of-date, it needs to be rebuilt from the product doc. Grammar removed or renamed, a
     previously-optional shape becoming mandatory in a way existing content can't satisfy without
     redesign, or a foundational convention (like the identity split, or the reserved `owner` role)
     that changes what "correct" means for every workflow in the package.
   - A change that doesn't affect the shape or content of a shipped community JSON at all (tooling,
     dispatch-channel plumbing, internal Skill self-check wording) does not bump the version.

3. **Every version bump is recorded in the log below** with: what changed, which reference files
   changed, and the exact migration instructions to bring a package from the previous version to
   this one. The log is written newest-last, oldest-first, so reading top-to-bottom from a package's
   stamped version to the current one gives the exact sequence of migrations it still owes.

4. **The Skill's own fetch-order instructions (`00-INSTRUCTIONS.md`, step 0) now mandate**: before
   doing anything else — including a single-field surgical fix — read the target community's stamped
   `skillVersion`. If it is behind the Skill's current version, fetch this document, apply every
   intervening migration in order, and only then proceed with whatever was actually asked. This
   applies regardless of how narrow the requested change is. A surgical dispatch's "touch nothing
   outside the ask" rule (§17) governs *unrelated* content; a stamped-version gap is never unrelated
   — it means the file does not conform to the grammar the Skill is currently authoring against.

## Current version: **3.6.0** (2026-09-04)

## How the 2026-09-05 baseline was established

No community JSON carried `skillVersion` before this document existed. The version each of the 11
shipped/reference packages is stamped with below was reconstructed from git history — the date of
that package's own last content-changing commit, mapped onto the version log's dates — not from any
contemporaneous record. This is a one-time reconstruction; every stamp from this point forward is
written by the Skill itself, at dispatch time, not inferred after the fact.

| Community | File | Last content commit | Stamped `skillVersion` |
|---|---|---|---|
| Ad-Free Community | `...AdFreeCommunity_Example.jsonc` | `56dc7998` (2026-09-02) | `3.5.0` |
| Neighborhood Book Club | `...BookClub_Example.jsonc` | `7ebfc3fc` (2026-09-03) | `3.5.0` |
| Camera Club | `...CameraClub_Example.jsonc` | `31652ee7` (2026-08-31) | `3.3.0` |
| Cedar Commons HOA | `...CedarCommonsHOA_Example.jsonc` | `56dc7998` (2026-09-02) | `3.5.0` |
| Chess Club | `...ChessClub_Example.jsonc` | `cad5c1bc` (2026-08-31) | `3.3.0` |
| Export and Migration | `...DataPortabilityCommunity_Example.jsonc` | `56dc7998` (2026-09-02) | `3.5.0` |
| Garden Club | `...GardenClub_Example.jsonc` | `56dc7998` (2026-09-02) | `3.5.0` |
| Platform Social | `...MemberSocialSpace_Example.jsonc` | `c617548c` (2026-08-31) | `3.3.0` |
| **Masjid Nur** | `...Mosque_Example.jsonc` | `f2b456d6` (2026-08-31) | `3.3.0` |
| Riverside Youth Soccer | `...YouthSoccer_Example.jsonc` | `7ee9aa2c` (2026-08-31) | `3.3.0` |
| Tabletop Club (reference fixture, not shipped to the demo app) | `...Phase1_TabletopClub_Example.jsonc` | unreviewed — check before use | `unstamped` |

Ad-Free, Book Club, Cedar, Export/Migration, and Garden Club are already at `3.5.0` (the current
minor line at the time of stamping) via their 09-02/09-03 regenerations. Camera Club, Chess Club,
Platform Social, Masjid Nur, and Youth Soccer stamp at `3.3.0` — each owes the `3.4.0` and `3.5.0`
migrations below. **Masjid Nur and Platform Social additionally never picked up the `3.0.0` owner-role
migration** — Chess Club and Youth Soccer got it in their 08-24 regeneration batch (see the `3.0.0`
entry), so `3.3.0` alone does not mean "owner role present"; check the package directly.

## Version log

Each entry: what changed, which files, and the migration a stamped-behind package must apply to reach
this version from the previous one.

### 1.0.0 — 2026-08-05
Skill created (`4811c655`): ChatGPT-authorable calendar-experience skill + validator packaging API.
Baseline. No prior `skillVersion`-stamped package exists before this point.

### 1.1.0 (minor) — 2026-08-09 to 2026-08-10
Files: `guide/01-authoring-procedure.md`, new `reference/solved-patterns.md`, self-check additions.
Cedar Commons HOA first authored. Self-check rules added for defect classes D1 (reachable state with
no render binding), D4, D5 (role:actor/receiver per-tab resolution trap). Solved Patterns bank +
requirement-traceability table + Skill Retrospective process introduced. Chess Club retrospective
findings folded into the authoring procedure.
**Migration: none.** Additive self-check rules flag new mistakes; they don't invalidate content that
doesn't happen to have those specific defects.

### 1.2.0 (minor) — 2026-08-11 to 2026-08-12
Files: `archetypes/README.md`, `_meta/versioning-policy.md`, Codex dispatch channel docs.
Archetype grammar locked: `tabId` open, `cardSurfaceFamily` closed to a real enum; 4 archetypes
promoted from pending to real. Codex GitHub-fetch dispatch channel added. `appShellConfiguration` key
corrected to `appShell`. `workflowGrammarVersion` pinned to its real value. Existing personas/tabs
now supplied when updating an already-shipped community (an early precursor of this document's whole
concern, not yet generalized). searchAI/documentLibrary authoring pitfalls documented.
**Migration:** confirm every `cardSurfaceFamily` your package uses is in the closed real enum in
`archetypes/README.md`; if it predates the 4 promotions and used a workaround, switch to the real
archetype.

### 2.0.0 (MAJOR) — 2026-08-13 to 2026-08-14
Files: `reference/identity-types.md` (new), `reference/permissions.md` (new), `reference/workflow-grammar.md`,
`archetypes/event-rsvp.md`, `spec-version.json` (new).
The foundational identity/permissions/version rework: `personaId` split into `roleId` (a kind of
member) and `fanId` (one specific person) — grammar 3, corrected same day to be grammar 3 not 2, since
grammar 2 (creatable-FAB restructuring, 2026-07-20) had never been formally declared. Permissions are
now **derived** from community JSON via a required `action` field on every transition, never authored
directly. A single package-root `specVersion` replaces the legacy three-field version scheme
(`schemaVersion` / `experience.experienceSchemaVersion` / `experience.workflowGrammarVersion`).
Archetype contracts documented for all 13 archetypes. `event-rsvp` fully redesigned onto per-row
response tables: community-owned states, eager row provisioning, a full sweep rule, orphaned-row
detection (warning at this point, see `2.3.0`).
**Migration REQUIRED — this is the largest single break in the corpus's history:**
1. Replace any `schemaVersion` / `experience.experienceSchemaVersion` / `experience.workflowGrammarVersion`
   with a single package-root `specVersion` (value `3` at this point in history; see `2.1.0` for the
   bump to `4`).
2. Rename every `personaId`-shaped field, guard key, and action key to its `roleId`/`fanId` form per
   `identity-types.md` §2 (`allowedPersonaIds`→`allowedRoleIds`, `byPersonaIds`→`byRoleIds`,
   `visiblePersonaIds`→`visibleRoleIds`, `createdByPersonaId`→`createdByFanId`, etc.) — this is the
   single most error-prone migration in the log; read `identity-types.md` §3 in full, not this summary.
3. Add a required `action` field (from `permissions.md`'s closed vocabulary, matched to the
   transition's archetype) to every transition that doesn't already have one.
4. If the package uses `event-rsvp`, migrate response data onto per-row response tables — see
   `archetypes/event-rsvp.md` for the shape; do not leave responses as array fields on the parent
   instance.

### 2.1.0 (MAJOR, in practice supersedes 2.0.0's version number) — 2026-08-17
Files: `identity-types.md`, `permissions.md` (both ratified to `status: current`).
`specVersion` bumped to `4` specifically, and `personaId` retired **everywhere** — `roleId`/`fanId` is
the only legal spelling under `specVersion: 4`. (An AP-14 rule locking `messages` as a system-only tab
was added 2026-08-18 and retracted the same window as wrong — net no-op, no migration from it.)
**Migration REQUIRED:** any package still declaring `specVersion: 3` (or no `specVersion` at all) or
still using `personaId` anywhere must move to `specVersion: 4` and complete the `2.0.0` identity
rename in full.

### 2.2.0 (minor) — 2026-08-18 to 2026-08-19
Files: `reference/permissions.md`, `codex-dispatch` instructions (5 migration-quality fixes),
`reference/field-types.md`.
`visibility.fields` conditional requirement documented; role-as-party pattern documented (a role, not
just a fan id, can be a visibility party). Five defects that would have produced half-migrated
packages fixed in the dispatch channel: preserve `personaId`→`roleId`/`fanId` renames' underlying ids
exactly, preserve workflow-type ids and seed `instanceId`s across a migration, seeds must declare
`createdByFanId`. Governing principle stated: a re-authoring dispatch is a **migration**, never a
rewrite. A computed field must not be marked `required` (the engine rejects it). `requiresCapabilities`
field added.
**Migration:** if a workflow's visibility uses `parties`, declare `visibility.fields` explicitly rather
than leaving it implicit. Otherwise additive.

### 2.3.0 (MAJOR) — 2026-08-20
Files: `render-bindings.md`, `permissions.md`, `guide/05-validation.md`.
Marked `spec!:` and `feat(validator)!:` in their own commits — explicit breaking-change signals.
`requiredPermission` **removed** from tab grammar entirely: tab visibility is now derived from the
role guards on workflows bound to the tab, never authored as a permission string. `deliver_reminder`
split out of `set_reminder` as its own action (later corrected further at `3.3.0`).
`orphaned_response_rows` ratcheted from a warning to a hard validator **error** — a package that
previously passed with this warning now fails outright.
**Migration REQUIRED:** delete any `requiredPermission` field declared on a tab (derive visibility from
guards instead). Fix any orphaned response row the validator flags — it is no longer tolerated as a
warning.

### 2.4.0 (minor) — 2026-08-22 to 2026-08-23
Files: `guide/05-validation.md`, Chess Club package.
Visibility-field type rule enforced by the validator (previously stated, not checked). Chess Club's
already-implemented alternate paths backfilled into its own doc. Governing order changed: the Skill
now designs the product doc first, then derives JSON from it, rather than the reverse.
**Migration:** none required for an already-conformant package; re-validate to confirm.

### 3.0.0 (MAJOR) — 2026-08-24
Files: `identity-types.md` §2a (new section).
**`owner` reserved as the one standard platform role.** Every other `roleId` remains a community's own
invention, but `owner` means the same thing in every community: the person who sets the community up
and approves who is allowed in. A community SHOULD declare exactly one owner role, named
`<prefix>-owner`, with `roleLabel: "Owner"`. Before this, packages named their leadership role whatever
suited them — `hoa-board`, `chess-organizer`, `garden-coordinator`, `masjid-admin` are the four named
directly in the ratifying doc as pre-convention examples. The package declares only that the role
*exists*; it must never declare admission/membership authority, which belongs to App Access.
**Migration REQUIRED:** if the package's leadership role is not already named `<prefix>-owner` with
`roleLabel: "Owner"`, add one (or rename the existing leadership role to it), and update every guard
throughout the package that referenced the old name. **This is the exact migration Masjid Nur and
Platform Social are still owed** — both stamp at `3.3.0` in the baseline table above but never went
through this one, because their subsequent touches were narrow, single-purpose dispatches that
correctly left roles untouched. Ad-Free, Book Club, Chess Club, and Youth Soccer received this
migration in a regeneration batch on 2026-08-24/08-25 and already have it.

### 3.1.0 (minor) — 2026-08-26 to 2026-08-27
Files: `archetypes/calendar.md` (new — calendar promoted to a real, placeable archetype),
`workflow-grammar.md` (`writableBy` gains `"platform"`).
`writableBy: "platform"` is now a legal value distinguishing a platform-computed field (a checksum, a
reminder timestamp, upload metadata) from one an author or a transition effect writes. Reminders are
now declared via the `reminder` block, never computed via a formula.
**Migration REQUIRED:** audit every prefill-stamped or platform-computed field (checksums,
reminder timestamps, upload metadata, receipt/transfer ids) and mark each `writableBy: "platform"`
rather than leaving it looking author-writable or formula-computed. **This migration was already
carried out for every one of the 11 shipped communities in this exact window** (2026-08-27 through
2026-08-29) — including Masjid Nur (`04eb71ad`) — so every package in the baseline table already has
it, even the ones stamped as low as `3.3.0`.

### 3.2.0 (minor) — 2026-08-29 to 2026-08-30
Files: `workflow-grammar.md` (`platformSource` field).
`platformSource` declares *which* platform value populates a `writableBy: "platform"` field (so the
engine and the reader both know the value's real origin, not just that it isn't author-written).
Declared across every community with a checksum/transferId field.
**Migration REQUIRED (for any package with an un-sourced platform field):** add `platformSource`
naming the value. Already done for all 11 in the baseline table.

### 3.3.0 (minor) — 2026-08-30 to 2026-08-31
Files: `workflow-grammar.md` (`experience.notifications`), `permissions.md` (`send_reminder` vs
`deliver_reminder` properly split).
`experience.notifications` declares the offered notification channels and the default. Declared
across **all 11** shipped communities in this window (the "11 of 11" commit run) — this is the version
every community in the baseline table that hasn't been regenerated since stamps at, because it's the
last change every one of them picked up. `send_reminder` (manual, role-guarded) and `deliver_reminder`
(automatic, buttonless, platform-swept) are both confirmed real and distinct paths.
**Migration:** already complete for all 11 as of this version.

### 3.4.0 (minor) — 2026-09-01
Files: `archetypes/*.md` (4 bespoke archetypes gain the `create` action they already needed),
`permissions.md` §7 (admin clarified as a system-created default per community, not app-level).
**Migration:** additive; re-validate if the package uses one of the 4 affected archetypes.

### 3.5.0 (minor) — 2026-09-02 to 2026-09-03
Files: `guide/03-common-patterns.md` (archetype-selection guidance: booking scenarios use `calendar`,
not `event-rsvp`), `guide/04-antipatterns.md` (keep-but-warn for an affordance with no backing
transition, patterns 22–23). Pattern 24 (forbidding per-response `*-response` state machines) was
proposed 2026-09-02 and **retracted** 2026-09-03 — response rows remain canonical; no package needs to
change because of this proposal's brief existence.
**Migration:** re-check archetype selection for any booking/scheduling workflow modeled as
`event-rsvp`; otherwise additive.

### 3.6.0 (minor, current) — 2026-09-04
Files: `permissions.md` (authoring guidance for `send_reminder` vs `deliver_reminder` — which one to
write, with worked JSON for each path).
**Migration:** none required; this is documentation clarifying `3.3.0`'s split, not a grammar change.

---

## Adding a new version entry

When a change to any file the Skill's fetch-order reads (`docs/references/guide/**`,
`docs/references/reference/**`, `docs/references/archetypes/**`) would change what a conformant
community JSON looks like:

1. Decide minor vs major using the definitions at the top of this document.
2. Append a new entry to the log above, in the same format: what changed, which files, and exact
   migration instructions (or "none" if genuinely additive with nothing for an existing package to
   do).
3. Update "Current version" at the top.
4. The next Skill dispatch against any package — even a single-field surgical fix — reads this
   document as part of its mandatory fetch order and applies every migration between that package's
   stamped `skillVersion` and the new current version before doing anything else.
