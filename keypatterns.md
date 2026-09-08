# Key Patterns — Loom's institutional memory

**What this file is.** Fed by the Root Cause Agent (`data/call_root_cause_agent.sh`), a single
persistent Codex session that carries context across every dispatch made to it and is meant to act
as this project's standing expert — the one place that accumulates recurring issues, durable
patterns, and key architectural decisions/pivots across every investigation, rather than each
dispatch rediscovering them independently. **The agent itself never writes this file** — it runs
`--sandbox read-only` with zero write access, enforced, not just asked for. It only *proposes* an
entry, as text in its reply, delimited by `<<<KEYPATTERNS_ENTRY>>>`/`<<<END_KEYPATTERNS_ENTRY>>>`;
`call_root_cause_agent.sh` itself extracts and appends that block after the dispatch completes —
that script is this file's only writer.

**Append-only.** Never delete or rewrite an existing entry from this file — that includes the
agent that maintains it. A superseded entry is corrected by adding a new entry that says so and
pointing back at the old one, the same convention this project's trackers already use
(`ORIGINAL: ...` kept alongside a correction, never replaced). If an entry turns out wrong, mark it
`[SUPERSEDED — see <entry>]` in place rather than removing it.

**How this feeds `CLAUDE.md`.** This file is the working/staging memory; `CLAUDE.md` is the
project's actual loaded-every-session instructions. After each Root Cause Agent dispatch, the
orchestrating session reviews what's new here and folds genuinely durable, generally-applicable
entries into `CLAUDE.md` itself (in its own words, at `CLAUDE.md`'s own level of generality) —
this file is not read automatically by every session the way `CLAUDE.md` is, so an entry that
matters going forward needs to actually make that trip, not just sit here.

**Entry shape** (one per finding, dated, most recent last):

```
### YYYY-MM-DD — <short title>

**Kind:** recurring issue | pattern | architectural decision/pivot
**What:** <the thing itself, plainly>
**Why it matters:** <what it costs to not know this>
**Evidence:** <dispatch/investigation it came from, or a file:line/commit if there is one>
```

---

## Entries

_None yet — seeded 2026-09-07 via the Root Cause Agent's first real dispatch (context-loading
across every tracker, architecture doc, OpenAPI spec, Skill file, and the git history). Entries
follow below as the agent finds them, starting with that dispatch's own findings._

### 2026-09-07 -- Identifier spaces are distinct contracts

**Kind:** recurring issue

**What:** `extensionId`, canonical `communityId`, `communityHandle`, App Access group ID, role ID, and fan ID have different jobs. Map between them explicitly at service and artifact boundaries. A role identifies a class of members; a fan identifies a person. Legacy `persona` fields require semantic classification before migration: replacing a subset of named people with their shared role can silently widen access.

**Why it matters:** Passing an extension ID to the remote workflow API caused authorization-resolution 503s. Joining B25 evidence on `communityId` instead of `extensionId` silently excluded communities and produced false workflow counts. These are valid-looking strings used in the wrong identity space, so ordinary type and schema checks do not catch them.

**Evidence:** Commit `9a7b2760`; `docs/Build Plan V2/Build Tracker.md:2542`; `docs/references/reference/identity-types.md`; authoring bundle `00-INSTRUCTIONS.md`, persona-to-role migration cases.

### 2026-09-07 -- Community administration is generated governance, separate from domain ownership

**Kind:** architectural decision/pivot

**What:** Installation generates `<communityHandle>-admin` and its community-management permissions. The package declares domain roles such as organizer, board member, coach, or owner; it does not supply this governance role. One person may hold both kinds of role. App Access owns memberships, roles, and grants; Fan Passport owns personal identity/preferences; workflow instances own domain participation. A workflow called “join” or “approve registration” does not thereby create membership or grant a role.

**Why it matters:** Older tracker proposals leave administration looking unresolved or package-authored. Implementing those proposals now would reverse a settled boundary. Renaming persisted roles also requires moving membership assignments before deleting the old role; deletion can cascade away the assignments.

**Evidence:** `docs/references/reference/permissions.md`, §§7 and 9; `docs/Build Plan V2/Access Control and Workflow Service Tracker.md:2070` and `:2149`; backend `AppAccessService.installCommunity` and its generated-admin handling.

### 2026-09-07 -- One engine does not eliminate differences in authorization context

**Kind:** architectural decision/pivot

**What:** The authoritative Dart workflow service runs the same `LocalWorkflowEngineApi` used locally; “Local” in the class name does not imply device-only authority. Reusing the engine avoids a second implementation of guards, formulas, and effects. Document, export, and item-queue functionality also stays within the workflow service so it can reuse workflow authorization. Each entry path must still install the correct community, caller roles, and active-membership lookup.

**Why it matters:** The server previously omitted the membership lookup. The shared engine then correctly returned false for membership, making `membersOnly` records effectively creator-only. The rule implementation was shared; its dependencies were not. Similar investigations must inspect request context and cached resolvers before rewriting guards.

**Evidence:** Commit `4076cba4`; `app/packages/core/loom_workflow_service/lib/src/workflow_service.dart:3641`, `:3650`, and `:3745`; Access Control tracker’s archetype-service boundary decision near line 1995.

### 2026-09-07 -- Visibility combines grants, while navigation can impose an explicit audience

**Kind:** recurring issue

**What:** Instance visibility is not one flat role check. Creator access and archetype identity/share grants can admit a viewer; state-level read guards override the workflow-level read guard. Supported document-sharing grants widen the relevant action permission with OR semantics. Navigation must account for readable workflows as well as executable transitions, while an explicit tab `visibleRoleIds` remains an absolute audience restriction.

**Why it matters:** Separate shortcuts have ignored state read guards, treated sharing as an additional restriction, or hidden readable tabs from members who could not act. Widening navigation before declaring intended audiences can expose administrative tabs. Correctness requires following both the shared visibility evaluator and every shortcut that decides whether to invoke it.

**Evidence:** Commits `dc78f7f1`, `ca5f617e`, and `3006fa29`; `app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart:483`, `:554`, and `:600`; `docs/references/reference/solved-patterns.md`, pattern 18.

### 2026-09-07 -- An archetype, a card, and a tab renderer are separate mechanisms

**Kind:** recurring issue

**What:** A tab ID is a placement/join key. Bound archetypes determine rendering behavior; naming a tab `calendar` does not produce a calendar. Conversely, `calendar` is now a real archetype without attendance semantics and can appear in a custom tab. It uses a calendar tab surface with an ordinary instance detail card. Tab-level rendering also depends on compatible bindings and the renderer’s actual field contract, including literal `eventDate` and `eventTime` keys.

**Why it matters:** Declaring a family in documentation or capability metadata has repeatedly been mistaken for implementing it. Adding `calendar` touched nine registries and exposed an unsupported assumption that archetype-to-renderer mapping must be one-to-one. Older “13 archetypes” summaries predate this addition.

**Evidence:** Commit `b6ce5515`; `docs/references/archetypes/README.md`, dispatch explanation; `docs/references/archetypes/calendar.md`; `docs/Build Plan V2/TabId-Archetype Gap Closure.md`.

### 2026-09-07 -- Permission meaning comes from archetype semantics, not transition spelling

**Kind:** architectural decision/pivot

**What:** Bespoke archetypes use explicit semantic actions from their supported vocabulary. Generic archetypes derive permission categories structurally and carry no authored `action` field. `table` belongs to the generic group: its special row layout does not impose a closed action vocabulary. A response workflow can inherit its parent’s archetype through `responseTable` even when it has no bindings of its own.

**Why it matters:** The same transition label or ID can mean different operations across communities. Inferring permission from names can confuse withdrawal with return, or force legitimate table transitions into an invented “publish” vocabulary. Rendering layout, action semantics, and per-transition guards must be evaluated separately.

**Evidence:** `docs/references/reference/permissions.md`, §§1, 4, and 5, especially line 393 onward; `app/packages/core/loom_workflow_engine/lib/src/archetype_resolver.dart`; the documented retraction of the bespoke `table` vocabulary.

### 2026-09-07 -- Response rows are canonical; missing standalone cards are not a modeling defect

**Kind:** architectural decision/pivot

**What:** Per-member response workflows remain a canonical model. They render through their parent’s `responseTable` and may correctly have `renderBindings: []`. The proposal to eliminate response workflows was explicitly retracted. Do not add standalone cards or replace rows with parent arrays merely to silence binding warnings. Existing array-based packages require case-specific assessment; they do not establish a migration rule.

**Why it matters:** An apparent failure to adopt corrected response modeling was actually a file-mapping defect: Masjid Nur, Neighborhood Book Club, and Riverside Youth Soccer reference names differ from their bundled asset names. A mistaken adoption diagnosis escalated into an unnecessary architectural rewrite.

**Evidence:** Commit `2d93bc5e`; `docs/references/reference/solved-patterns.md:1000`, retracted pattern 24; `docs/references/archetypes/event-rsvp.md`; Access Control tracker’s September 3 adoption correction.

### 2026-09-07 -- Remote communities start empty, so real creation is part of the product

**Kind:** architectural decision/pivot

**What:** Package seed instances initialize the local engine. Remote communities intentionally start empty; installing or publishing a package is not a request to copy its demo instances into PostgreSQL. Every member-created workflow therefore needs a usable create action or a real upstream creation effect. The first live scenario must exercise creation and its prerequisites.

**Why it matters:** Seeded records can make editing, transitions, and receiving screens look complete while users have no way to create the first record. Historical fixture fallbacks and sideload hydration defects further obscured which package was actually being exercised. An empty remote community is not itself evidence of a missing seed endpoint.

**Evidence:** September 7 explicit user decision in `docs/Build Plan V2/Access Control and Workflow Service Tracker.md:246`; `_EngineNativeCommunityStore._initialize` in App Shell part 25; `workflow_validator.dart`, AP-13; Community JSON Migration tracker’s CJM.7 and CJM.9 histories.

### 2026-09-07 -- Workflow evidence needs an identified artifact and a verified outcome

**Kind:** recurring issue

**What:** A workflow result must identify the package build, actual workflow, acting/receiving identity, runtime backend, and resulting state. Package provenance, capture completeness, structural validation, UX review, and persisted execution establish different facts. A manifest without package identity is unknown against the current build. A row naming no shipped workflow is a denominator defect, not a failed user journey.

**Why it matters:** B25 totals were repeatedly wrong because of bad joins, obsolete workflow rows, and missing provenance. On September 7, 16 claimed live-write dispatches were reopened after the recorded investigation found no corresponding database rows. Screenshots and successful taps alone did not establish remote persistence.

**Evidence:** `docs/Build Plan V2/Build Tracker.md:2489` and `:2542`; commit `f809e9a4`; Access Control tracker’s September 7 live-proof correction at line 247; recent B25 row reconciliation commits `0da2d948`, `499a51fb`, `6032a57c`, and `93c4cec6`.

### 2026-09-07 -- Tenant isolation requires both restricted credentials and one scoped transaction

**Kind:** architectural decision/pivot

**What:** Community-owned workflow tables use forced PostgreSQL RLS against transaction-local `app.current_community_id`. All statements for a request must use the session carrying that setting. Nested operations may reuse the transaction only for the same community. Runtime credentials must lack superuser/BYPASSRLS authority, including credentials used by sibling services that can reach the database.

**Why it matters:** Adding a policy does not protect queries executed by a bypassing role. Setting tenant context on one pooled connection does not protect work performed on another. Database tenant isolation also complements, rather than replaces, the engine’s per-fan visibility and action checks.

**Evidence:** Commits `5a90042e` and the subsequent all-service credential hardening recorded in the Access Control tracker; `app/packages/core/loom_workflow_service/lib/src/postgres_connection.dart:44`, `:74`, and `:105`.

### 2026-09-07 -- Idempotent creation must handle concurrent first requests

**Kind:** recurring issue

**What:** Idempotency is an atomic lookup/create-or-reload operation inside the community transaction. Creation uses `INSERT ... ON CONFLICT DO NOTHING RETURNING`; a losing request reloads the winner using a subsequent READ COMMITTED statement. A preliminary lookup is an optimization, not concurrency protection.

**Why it matters:** Two requests can both observe “absent.” A later unique constraint then turns the loser into a 500 unless the conflict path deliberately returns the existing result. Moving lookup and insertion into separate transactions preserves the race and can also separate the work from its RLS context. The shared solution was needed across workflow-service repositories and then item queues.

**Evidence:** Commits `836100b8` and `1bc87122`; `app/packages/core/loom_workflow_service/lib/src/idempotency.dart`; `runWithPostgresCommunity` in `postgres_connection.dart`.

### 2026-09-07 -- Cross-workflow effects invalidate local-only writer analysis

**Kind:** recurring issue

**What:** To determine whether a field has a writer, follow effect targets across workflow types. In a `relatedInstance` effect, the ID-bearing reference is resolved from the source instance, but the written key belongs to the target schema. `createInstance`, nested effects, and success effects also require their proper execution contexts. A warning cannot establish absence if its collector attributes writes to the wrong workflow.

**Why it matters:** Cedar’s five supposed orphan fields are written by committee-decision effects targeting architectural requests. Changing their declaration from `effect` to `platform` silences the warning while making the package less accurate. The validator currently credits keyed writes to the owning workflow, explaining this false positive.

**Evidence:** `docs/Build Plan V2/Community JSON Migration Tracker.md:1418`; `app/packages/tooling/loom_ux_judges/lib/src/validator/workflow_validator.dart:1562`; `docs/references/reference/effects.md`, related-instance and related-transition sections.

### 2026-09-07 -- A field’s writer and its value-producing service are different declarations

**Kind:** pattern

**What:** `writableBy` identifies who writes a field; it does not invoke a service. `platformSource` selects a supported generic mechanism where one exists. Handler-owned platform fields can legitimately omit it. Current opaque-ID minting consumes `platformSource: "opaqueId"`; export checksums come from generating real export bytes. Stored document content is platform-written and must not be a required member-entered URL.

**Why it matters:** Reclassifying an unwritten field does not make it populate, and adding placeholder effects fabricates results. Conversely, demanding `platformSource` on every platform field misclassifies legitimate bookkeeping. Export verification must hash the stored bytes afresh and preserve the recorded digest on mismatch; comparing metadata with itself cannot detect corruption.

**Evidence:** `workflow_validator.dart:1621`; `workflow_service.dart:2152`, `:2279`, and `:4161`; commit `79da87b1`; `docs/references/archetypes/document-library.md`, §3a.

### 2026-09-07 -- Shared content and each member’s relationship to it need separate state

**Kind:** pattern

**What:** A shared document has content and lifecycle state; each member separately has read, saved, and acknowledgement state. Acknowledgement records the service-assigned document version and cannot be toggled off. Publishing a revision preserves the earlier bytes and acknowledgement evidence while making earlier acknowledgements insufficient for the current version. Decisions on individual access requests similarly need individually addressable request records.

**Why it matters:** Putting these facts into one shared lifecycle lets one member’s action overwrite everyone’s state. A member-typed version string cannot reliably bind acceptance to content. A shared “access requested” audit entry also cannot support independent board decisions for multiple requesters.

**Evidence:** `docs/API/OpenAPI/community-surfaces/document-library-api.openapi.yaml:318` and `:405`; Access Control tracker’s scoped document-bookkeeping decisions; commit `7061b1e7`, Cedar’s separate access-request workflow.

### 2026-09-07 -- Reminder ownership, initiation, and delivery are independent choices

**Kind:** architectural decision/pivot

**What:** `set_reminder` expresses a member’s choice about their own row. `send_reminder` is a deliberate, role-authorized human action. Automatic `deliver_reminder` is platform work driven by a declarative reminder block, with no authored transition or role grant. A parent-level schedule does not replace a member-owned response-row preference. Notification defaults, saved member choices, and transport delivery are additional layers.

**Why it matters:** Reminder migrations repeatedly deleted requested member controls or removed legitimate manual send buttons. Computing schedule times informally also loses date/timezone semantics. A created notification or app-open local notification must not be described as proof of background server push.

**Evidence:** `docs/references/reference/permissions.md:150`; `docs/references/reference/solved-patterns.md:759`; `docs/references/reference/workflow-grammar.md`, reminder block; `docs/references/reference/platform-services.md`, notification semantics and transport status.

### 2026-09-07 -- Replica synchronization includes authorization changes, not only row changes

**Kind:** architectural decision/pivot

**What:** The workflow change feed is per viewer. Its contract returns the caller’s complete currently visible ID set so the replica can remove records that are no longer readable. A role change invalidates the cursor and requires resynchronization because newly visible records may have old timestamps. Pagination uses the exclusive pair `(updatedAt, instanceId)`; both cursor components travel together.

**Why it matters:** A community-wide feed leaks records across readers. Row-only deltas retain revoked content and miss newly granted content. An inclusive timestamp-only cursor loops forever when more rows share one timestamp than fit in a page; an exclusive timestamp alone skips rows. This is a read-only replica contract, not an offline-write reconciliation design.

**Evidence:** `docs/API/OpenAPI/community-surfaces/workflow-engine-api.openapi.yaml:390` through its change-feed explanation; membership admission in `workflow_service.dart:3700`.

### 2026-09-07 -- Destructive lifecycle actions must respect orthogonal commitments

**Kind:** recurring issue

**What:** Lifecycle state and availability are separate dimensions. A listing can remain `published` while its availability data says reserved or on loan. Delisting therefore needs both owner authority and an availability condition that permits removal. Trace the borrower’s return or completion path before deciding a destructive transition is safe.

**Why it matters:** Owner-only delist guards independently appeared in Camera Club and Garden Club and could strand active borrowers. The converse mistake also occurs: applying a success-only prerequisite to cancellation can trap a failed operation. Each exit needs conditions derived from the obligation it ends, rather than mechanically copying neighboring guards.

**Evidence:** `docs/references/reference/solved-patterns.md:26`, Camera/Garden delist examples; TabId-Archetype tracker’s Cedar export review, where requiring checksum readiness for cancellation was correctly rejected.

### 2026-09-07 -- Schema versions, Skill versions, and provenance prove different things

**Kind:** architectural decision/pivot

**What:** `specVersion` identifies package grammar compatibility. `skillVersion` records the authoring convention version last applied. Provenance hashes identify exact bytes. None substitutes for the others. Updates must apply required Skill migrations before the requested edit, but historically reconstructed stamps still require direct semantic checks where the version log identifies exceptions.

**Why it matters:** Some packages reconstructed as Skill `3.3.0` had never received the earlier owner-role convention; comparing version numbers alone would incorrectly declare them migrated. A matching provenance hash detects artifact drift but does not prove Skill authorship, because the manifest can be regenerated after any edit. Merely raising a stamp fixes neither problem.

**Evidence:** Commit `825ddebc`, single `specVersion` pivot; `docs/references/reference/skill-versioning.md:65` and `:93`; `docs/Build Plan V2/Community JSON Migration Tracker.md:1421`; both authoring channels’ migration instructions.

### 2026-09-07 -- Product-document boilerplate can manufacture requirements and undo shipped behavior

**Kind:** recurring issue

**What:** Reconcile the community’s specific product intent, current grammar, and actual shipped package before regeneration. Shared product-document boilerplate is not automatically a requirement. Older fallback mappings are not instructions to undo subsequently implemented archetypes. Preserve identifiers that cross package boundaries and assess the resulting functional diff, including surfaces and alternate paths.

**Why it matters:** Repeated dispatches invented an export-reviewer role or an invite/connect subsystem from template prose. A later cleanup nearly regenerated already-correct archetypes back to obsolete generic fallbacks. The approved recovery was a targeted Skill edit against the shipped package, with an independently checked diff; that did not exempt the package from required migrations.

**Evidence:** `docs/references/reference/solved-patterns.md`, patterns 12, 13, and 17; `docs/Build Plan V2/TabId-Archetype Gap Closure.md`, Milestone 2 “Resumed and closed” account; authoring `00-INSTRUCTIONS.md`, “match or beat what ships today.”

### 2026-09-08 -- A walkthrough identity must be authenticated, not merely selected

**Kind:** pattern

**What:** Seeded App Access memberships and demo picker entries do not establish an OAuth session. Remote sign-in requires the selected account to equal the token’s fanId. Existing seeded credentials are documented in the Access Control tracker, and LoomAuthSession also supports a test-only password grant. An emulator test that authenticates and calls the engine directly proves a different boundary from a UI-driven workflow.

**Why it matters:** Missing credential context can strand a walkthrough at Keycloak despite existing usable test infrastructure. Conversely, selecting roles locally or running a direct engine test can produce misleading claims of persona coverage or UI completion. Bind each walkthrough to its authenticated fan, server-resolved role, actual UI action, and persisted instance.

**Evidence:** Access Control and Workflow Service Tracker.md:1783; loom_auth_session.dart:145; part39_remote_auth_api.dart:201; on_device_remote_backend_proof_test.dart:103 and :135. This dispatch established these code paths; current credential validity and the September 7 notification row’s origin remain unverified.

### 2026-09-08 -- Authentication recovery must not depend on account-loading failure

**Kind:** pattern
**What:** Account discovery, OAuth authentication, community account selection, and membership admission are separate states. Expose secure login independently of whether the account list loaded successfully. Failed admission checks must return to a recoverable gate rather than leave a cached active account on an unresolved spinner.
**Why it matters:** The remote login button was added only to the account-list error branch. A later sign-in failure merely showed a snackbar, leaving no login route until membership refresh recreated the screen. Reusing the screen for account switching extends the same defect beyond first entry.
**Evidence:** `part31_auth_screens.dart:42`, `:61`, and `:143`; `part01_local_extension_screen.dart:306` and `:1388`; introducing commit `8b61a3ee`; September 8 on-device reproduction supplied in this dispatch.

### 2026-09-08 -- Service call failure is not evidence of backend unreachability

**Kind:** pattern
**What:** Preserve authentication, authorization, HTTP failure, and transport failure as distinct outcomes. The current binding badge labels every failure “BACKEND UNREACHABLE,” including a missing session before any request was sent. Its state is the latest outcome per service/scope; an uncalled remote binding does not trigger the label.
**Why it matters:** Users are directed toward infrastructure recovery when they need to sign in, and a later successful call makes the warning disappear without explaining the original condition. Absence of the badge also does not prove a service has answered.
**Evidence:** `remote_workflow_engine_api.dart:369` and `:396`; `part52_service_binding_report.dart:185`, `:239`, and `:287`; September 8 missing-session banner and post-create clearing observations.

### 2026-09-08 -- Preserve failure classification; treat the universal outage label as fixed

**Kind:** pattern

**What:** This corrects the current-behavior claim in “Service call failure is not evidence of backend unreachability” (`keypatterns.md:255`): “The current binding badge labels every failure ‘BACKEND UNREACHABLE,’ including a missing session before any request was sent.” That describes the implementation before `7558a3c5`, not the current source. The classifier now distinguishes `SIGN-IN REQUIRED`, `ACCESS REFUSED`, and `SERVICE REQUEST FAILED`, reserving `BACKEND UNREACHABLE` for recognized transport failures without an HTTP status. Preserve that distinction when adding diagnostic producers or changing badge behavior. The original entry’s latest-outcome and never-called caveats remain valid.

**Why it matters:** The original Cedar and Chess observations sent investigation toward backend infrastructure when authentication was missing. Leaving the entry phrased as a current defect would also encourage readers to reopen a completed fix. The durable lesson is to classify the recorded failure cause; the universal outage label is the historical counterexample.

**Evidence:** Observed in the supplied history: `305ee24a` introduced service-binding observability; `528d0241` recorded the classification defect; `7558a3c5` records its fix and independent five-suite verification. Observed directly in source: `app/packages/core/loom_communities_app_shell/lib/src/part52_service_binding_report.dart:290` implements classification using `statusCode` and `errorKind`. `app/packages/core/loom_communities_app_shell/test/service_binding_report_test.dart:214` checks that HTTP 503 produces `SERVICE REQUEST FAILED` and excludes `BACKEND UNREACHABLE`; `:231` covers all four failure classes and never-called bindings; `:287` covers replacement of only the matching service/scope failure by a later success. These are source and recorded-history observations, not fresh runtime verification.

**Not already covered because:** This explicitly corrects “Service call failure is not evidence of backend unreachability”; it does not propose a second version of that pattern. I also checked “Authentication recovery must not depend on account-loading failure,” “A walkthrough identity must be authenticated, not merely selected,” and CLAUDE.md’s failure-classification evidence rule. Those preserve the relevant principles but do not correct keypatterns.md’s now-false present-tense description.

### 2026-09-08 -- LOCKED DECISION: seed test users per role in the backend, never in JSON

**Kind:** architectural decision (locked by the user; do not re-open)

**What:** Every community role gets **several seeded test users, provisioned in the backend**
(Keycloak + App Access `group_membership_role`). Community `*.jsonc` packages carry **no user ids** —
no `fanId` values, no `createdByFanId`, no participant lists naming people. Roles are declared in the
package; the humans who hold them are backend data.

Two consequences that follow directly, and both have already bitten:

- **"Only one holder of role X" is never a package problem and never a reason to edit a package.**
  Measured 2026-09-08: 36 of 37 role assignments had exactly one holder (only `cedar-commons-hoa:hoa-board`
  had two), which silently killed every two-party same-role interaction — Member Social Space's
  `connected`, and the six `join-queue`/`leave-queue` transitions in Book Club, Camera and Garden that
  a 2026-08-31 row had recorded as "dead" with no cause. Seed more users; do not touch the JSON.
- **A declared role with no holder is a provisioning gap, not a missing feature.** Masjid Nur's
  package declares `owner` and App Access never provisioned it, so four donation transitions are
  unreachable and a donation can never be `paid`. The fix is seeding, not re-guarding the transitions.

**Why it matters:** this decision has been asked for and re-answered repeatedly — the user's words:
"I have asked you repeatedly for seeding roles, and I keep saying to seed them in the back end,
remove the userids from JSON." Every time it is re-asked, work stalls behind a question that was
already settled. It is recorded here so it stops being a question. **A credential that stops working
for one seeded user is also not a decision point** — seed another user holding that role
(this is what made `loom-book-member-1`'s replaced password a non-issue rather than a blocker).

**Distinguish carefully, because conflating them is what produces wrong "fixes":** a package's
declared role (e.g. Masjid's `owner`) is a DOMAIN role; `<community>-admin` is GENERATED platform
governance holding the five `community.*` permissions. They are different roles with different
meanings, and substituting the admin for a missing domain role is never the fix.

**Evidence:** user instruction 2026-09-08, restating a standing decision. Live data:
`group_membership_role` holder counts; `app_role` for `loom_communities_masjid-nur` holding only
`community-member` and `masjid-nur-admin`; Garden's `join-queue` guard requiring a `garden-member`
who is not the item owner.

### 2026-09-08 -- Simulated payment completion needs durable provenance and an explicit service binding

**Kind:** architectural decision/pivot
**What:** Payment ownership, initiation and confirmation are separate responsibilities. An authorized person may initiate checkout, but service success must gate workflow completion and its related effects. A local simulation may exercise the paid lifecycle only while preserving explicit simulation provenance on the payment, each attempt, receipts and downstream status projections. A field’s platformSource identifies a value-producing mechanism; it does not establish a service-backed transition or platform-only authority.
**Why it matters:** Removing a role guard opens an ordinary transition rather than reserving it for the platform. Copying only a paid checkpoint strips simulation provenance and lets downstream consumers mistake a demo result for money received. Payment invocation needs a declared execution contract before package authors can use it; guessing from field, transition or state names repeats the hidden-service-gap failure.
**Evidence:** September 8 payment scoping dispatch. local_workflow_engine_api.dart:1282 commits state and effects without a payment-service gate; workflow_models.dart:449 has no transition service binding; permissions.md:153 specifies no authored transition for automatic reminder delivery; guard_evaluator.dart:29 treats absent or empty allowedRoleIds as unrestricted; RiversideYouthSoccer_Example.jsonc:568 propagates only paymentCheckpoint = paid.
