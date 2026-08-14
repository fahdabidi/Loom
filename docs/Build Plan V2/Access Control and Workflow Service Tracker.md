# Access Control and Workflow Service Tracker

## 0. What this tracker is

Owns the effort that began as CJM.16 (Member Social Space's empty Messages tab) and grew into making
access control real: identity types, permission derivation, archetype contracts, and the workflow
service that enforces them.

**The through-line:** a community's JSON says which role performs which action, and *nothing else*
grants a permission. Identity comes from Fan Passport, roles and permissions from App Access, and
guards are evaluated server-side by the workflow service. Community JSON contains no user, no
permission, and no identity value.

Sibling trackers: [`Community JSON Migration Tracker.md`](Community%20JSON%20Migration%20Tracker.md)
owns per-community JSON correctness; this one owns the access-control architecture underneath it.
[`CJM.16 Identity Architecture Proposal.md`](CJM.16%20Identity%20Architecture%20Proposal.md) is the
originating diagnosis.

## 1. Locked spec additions

Approved and committed. Changing any of these needs explicit re-approval.

| Decision | Where | Commit |
|---|---|---|
| Permissions are **derived**, never authored — `action` + archetype + `allowedRoleIds` → permission | `reference/permissions.md` | `2a6ec0da` |
| `action` on all 308 bespoke transitions | 9 community fixtures | `630dea02` |
| **One `specVersion`** replaces the three-number scheme; starts at 4, breaking-only bumps | `spec-version.json`, `_meta/versioning-policy.md` | `825ddebc` |
| Identity type split: `roleId` (a kind of member) / `fanId` (a person) | `reference/identity-types.md` | `2b4e0b09`, `cf13878e` |
| **No identity values in community JSON at all** — seed `fanId`s were a workaround for having no backend | `identity-types.md` §5, `permissions.md` §9 | pending F |
| Archetype contracts: actions, bookkeeping, visibility, custom actions | `archetypes/CONTRACTS.md` + 13 docs | `aef55570`, `e9c54492` |
| Declared `action` → archetype semantics; **undeclared → structural**, both first-class | `CONTRACTS.md` §1 | `aef55570` |
| `documentLibrary` gains `edit`/`publish`/`delete` | `permissions.md`, `document-library.md` | `c0cb62cb` |
| The workflow service is the **authority**; the client engine is a cache and renderer | `workflow-engine-api.openapi.yaml` | `927baf87` |
| Identity from the **token**, never the request | same | `927baf87` |
| The server runs **this** engine, not a reimplementation | `store/database.dart` | `4076cba4` |

## 2. Enforced gates

Built this effort, because a policy nothing executes is a suggestion.

| Gate | What it catches | Commit |
|---|---|---|
| `DocsSyncChecker` | doc/spec drift, unmanifested docs, missing `derivedFrom`, **archetype without a doc** | `825ddebc`, `e9c54492` |
| Spec-sync test | `permissions.md` and `ArchetypeResolver` disagreeing | `88d813e1` |
| Vocabulary artifact test | the generated artifact drifting from the resolver | `d1b07226` |
| Validator `action` rules | missing/unknown action, action on a generic family, ambiguous archetype | `88d813e1` |
| Validator identity rules | legacy keys in a v4 package, `$viewer` compared to a `roleId` | `0779ef45` |

## 4. Status

| Area | State |
|---|---|
| Permission derivation spec | ✅ complete |
| Archetype contracts (13) | ✅ specified, ❌ unimplemented in the engine |
| Fan Passport identity linking | ✅ built, 13 tests |
| App Access join requests | ✅ built, 18 tests |
| App Access derivation endpoint | ❌ specified only |
| Workflow service | ⏳ contract only |
| Auth / token issuer | ❌ decided (Keycloak-as-broker), not built |
| Community fixtures on specVersion 4 | ❌ still legacy triple, listed in `pendingMigration` |

## 7. Execution order

Phases, with the dependency that forced this ordering: **the service embeds the engine, so it can only
enforce what the engine implements.** Regenerating fixtures against enforced contracts therefore
requires engine work first.

```
A (engine contracts) → B (service) → D (deploy) → E (app shell) → F (regenerate)
                    C (auth) ────────↗
```

| Phase | Work | Blocks |
|---|---|---|
| **A** | Engine implements archetype contracts: per-person bookkeeping, the 6 visibility models | B, F |
| **B** | Dart workflow service — embeds the engine, Postgres via `drift_postgres`, App Access role resolution | D |
| **C** | Auth: Keycloak-as-broker (Google/Apple/Facebook), all 3 services as resource servers | D |
| **D** | Deploy: redeploy the 2 stale Java services, deploy the workflow service, build the derivation endpoint | E |
| **E** | App shell: local engine becomes cache/renderer; hide `tabId`s the caller lacks access to | F |
| **F** | Regenerate all 11 fixtures in one pass; empty `pendingMigration` | — |

## 8. Live TODO / Next Steps Queue

| Status | Tag | Item | Source | Date |
|---|---|---|---|---|
| ⬜ Open | `new-milestone` | **Phase A — engine implements the archetype contracts.** `CONTRACTS.md` specifies per-person bookkeeping (7 of 13 archetypes) and 6 visibility models; the engine implements neither, so they are prose. Most invasive engine change of this effort: bookkeeping changes effect application for every archetype that has any, and visibility models change read filtering for all of them. `event-rsvp`'s `respond` must move a person between the three response sets **atomically** — today each community writes three transitions with three `actorInList` guards and nothing enforces exclusivity, so a member answering "going" then "maybe" can be counted twice, inflating capacity and starving the waitlist. Safety net: 210 existing engine tests. | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase B — build the workflow service.** Dart HTTP service embedding `loom_workflow_engine`, Postgres via `drift_postgres` (1.3.1 verified against drift 2.33), App Access client for role resolution, deployed to k3s beside the two Java services. Contract is committed (`927baf87`). The decisive test is an integration test proving a guard **refuses server-side** — that is the entire point of the service. | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase C — auth.** Keycloak as an identity *broker* with Google/Apple/Facebook upstream: Loom runs no user directory, and users only ever see the social buttons. All three services become OAuth2 resource servers validating one uniform JWT. `fan_identity` (issuer, subject → fanId) is already built and tested (`5de05e2`). Became load-bearing at the replan: the workflow service contract says identity comes from the token, and there is no token issuer yet — so B can be built and tested but not *used* by the app until C lands. | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase D — deploy and connect.** Build App Access's `installCommunityPackage` derivation endpoint (specified, `e5ec697f`), and **redeploy both Java services** — the running images predate their V2 migrations (`app-access` logs `Current version of schema: 1`), so the join-request and identity-linking endpoints are committed but not reachable. Committed is not deployed. | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase E — app shell switches to remote.** `LocalWorkflowEngineApi` becomes a cache and renderer rather than the authority; the shell renders buttons from the server's `availableTransitions` instead of deciding locally. Plus hiding `tabId`s the caller lacks access to (Dart-side for now; per-persona extension delivery is a later, separate change). | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase F — regenerate all 11 fixtures in one pass**, through the authoring Skill, never by hand: `specVersion: 4`, the identity rename (~1,524 keys), seed identity values stripped (104 instances; 18 read guards go fail-closed, which is correct), and Cedar's draft lifecycle. Then empty `spec-version.json` → `pendingMigration`, whose remaining entries are the fixtures, the 11 package generators, and the validator's legacy branch. | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-ticket` | **11 pre-existing app-shell test failures**, unrelated to this effort and predating it — baseline is `+227 -11` with today's deletions applied *and* reverted. Worth clearing before Phase E, since debugging a change on top of an already-red suite is how a real regression hides. One is already tracked separately (the `v3_milestone_phasee_purchase_proposal_test.dart` widget-finder assertion). | independent verification during cleanup | 2026-08-14 |
| ⬜ Open | `new-ticket` | **73 hardcoded `tabId == '…'` comparisons across 8 files**, including a validator rule (`dead_role_binding`) keyed on the literal tab name `calendar`. Residue from before generic tabIds. Separate genuine platform structure (`home`, `messages` are declared platform tabs) from residue, then remove the rest. Deliberately not documented into `CONTRACTS.md` as a "surface", which would have canonised the violation. | user-identified | 2026-08-14 |
| ⬜ Open | `new-ticket` | **Seven identity-vs-role comparisons that can never be true** — `$viewer == '<a declared roleId>'`, in Cedar Commons HOA (×3, previously unflagged), Masjid Nur, Member Social Space, Neighborhood Book Club (×2). The validator now catches them (`0779ef45`); they are fixed by Phase F's regeneration rather than hand-patched, so the type split is demonstrated to catch them rather than asserted to. | corpus scan | 2026-08-14 |
| ⬜ Open | `needs-verification` | `visibleTo` was **dropped** from `CONTRACTS.md` after `LoomWorkflowState.readGuard` was found to already exist and be preferred by the engine (`stateGuard ?? machine.visibility.readGuard`). The guarantee it was meant to give — that a read guard cannot express an identity/role confusion — needs to land as a **validator rule** instead. Not yet written. | design correction | 2026-08-14 |
| ✅ Closed | `new-milestone` | Archetype contracts for all 13, machine-readable artifact, 13 narrative docs, README index, Skill wiring, and a docs-sync gate for archetype-doc coverage. | this effort | 2026-08-14 |
| ✅ Closed | `new-milestone` | Single `specVersion` replacing the three-number scheme, plus `DocsSyncChecker` built as real code — the gate `_meta/docs-sync-checker.md` specified in July and nobody built, whose own opening line predicted the drift that followed. | this effort | 2026-08-14 |
| ✅ Closed | `new-ticket` | Deleted 5,749 lines of dead per-community engines (6 sniffing predicates, zero call sites) and the 27-file `docs/CardSurfaces/` duplicate. Verified zero community-JSON impact per file. | this effort | 2026-08-14 |
