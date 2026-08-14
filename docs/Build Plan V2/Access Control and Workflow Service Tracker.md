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

## 3. Roles — who does what

Ported from [`Community JSON Migration Tracker.md`](Community%20JSON%20Migration%20Tracker.md) §5/§6,
with the WSL-era commands replaced: the pipeline moved to the VirtualBox VM (`ssh loom-vm`), and
`wsl_dispatch_tracker.sh` / `wsl_slot.sh` no longer exist. See
[`Tools/README.md`](Tools/README.md) for the current recipe and
[`Tools/wsl-to-virtualbox-migration.md`](Tools/wsl-to-virtualbox-migration.md) for why.

| Agent | Tool | Used in this effort for |
|---|---|---|
| **Implementation Agent** | `data/call_implementation_agent.sh` (Codex CLI, backgrounded) | Phase A engine work, Phase B service, Phase C auth, Phase D deploy |
| **Root Cause Agent** | `data/call_root_cause_agent.sh` | The 11 pre-existing app-shell failures; anything resisting normal investigation |
| **Skill Authoring Agent** | `data/call_skill_authoring_agent.sh`, or a Claude Code `Agent` dispatch running the Skill | **Phase F only.** Community JSON is never hand-authored — see §5 |
| **Regression Impact Judge** | [`Tools/regression-impact-judge-tool.md`](Tools/regression-impact-judge-tool.md) | **Mandatory** for Phase A: bookkeeping and visibility change shared engine behaviour for every archetype |
| **LLM Vision UX Judge** | [`Tools/ux-gate-judge-tools.md`](Tools/ux-gate-judge-tools.md) | Phase E only, where rendered UI changes |
| **Skill Output Judge** | CJM tracker §1c | Phase F, judging the regenerated JSON before it is merged |

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

## 5. Dispatch mechanics — emulate exactly, do not improvise a shortcut

The canonical recipe, on the VM. Full detail lives in `data/call_implementation_agent.sh`'s own header;
read it before this tracker's first dispatch if any step is unclear.

```bash
# 1. Author the ticket at data/v3_ticket_acws_<slug>.md, following the proven structure:
#    ## Context / ## Scope / ## Do not do / ## Required verification /
#    ## Git safety reminder / ## Commit / ## Required response format (the _STATUS.md template).

# 2. Dispatch, backgrounded. Never run it in the foreground -- it blocks for the full duration.
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && \
  setsid nohup bash data/call_implementation_agent.sh data/v3_ticket_acws_<slug>.md --fresh \
  < /dev/null > .codex-logs/<label>_dispatch.out.log 2>&1 & disown'

# 3. Watch for genuine completion -- fires on "codex exec exited with status",
#    not on any mid-run output.
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && bash data/watch_dispatch_log.sh <label>'

# 4. Gate check -- must print READY FOR VALIDATION before verification begins.
ssh loom-vm '. ~/.loom-env.sh && cd ~/Loom && bash data/handoff_gate.sh'
```

**Never `bash -l`.** Non-interactive shells skip `.bashrc`, so the toolchain does not resolve. Every
command sources `~/.loom-env.sh` explicitly.

**Backend builds need JDK 21.** `~/.loom-env.sh` pins `JAVA_HOME` to 17 for Flutter/Android, and Maven
follows `JAVA_HOME` rather than `PATH` — so a normal build fails at *compile* with "release version 21
not supported", long after codegen succeeds, which reads like a code fault. Use `loom-backend/build.sh`,
which carries the override.

**No concurrency budget applies.** The WSL vsock cap that required `wsl_slot.sh` is gone; `sshd` reaps
child processes on channel close.

### Independent verification — mine, never the agent's STATUS.md

Every dispatch this effort has produced code that did not compile or did not match its own report. The
standing rule: **run it yourself.**

- `dart analyze` clean on every touched package; `flutter test` / `dart test` with no unexplained
  pass-count drop. Baseline first if the suite is already red — the app shell currently sits at
  `+227 -11`.
- **Backend:** `loom-backend/build.sh test <service>`, against the real PostgreSQL in k3s. Not
  Testcontainers — Docker 29 requires API 1.44 and the bundled docker-java negotiates 1.32.
- **Any package touching community JSON:** re-run the real `community_package_validator` against the
  changed fixture *and* every other shipped community, and **baseline the pre-change state** — identical
  warning counts are what prove a change introduced nothing.
- **Any change to shared engine code (all of Phase A):** a Regression Impact Judge dispatch against every
  real consumer. "The ticket's tests pass" is not evidence the other twelve archetypes are unaffected.

## 6. Mandatory completion gates

Different phases produce different artifacts, so they need different proof. Nothing here is satisfied by
analyze/unit tests alone.

**Phase A — engine contracts.** A Regression Impact Judge pass over every archetype, plus tests proving
each owned behaviour: `respond` leaves a person in exactly one of the three response sets after any
sequence of responses; a per-person action records the caller once; each of the six visibility models
admits and refuses the right viewers.

**Phase B — the service.** The decisive test is an integration test proving a guard **refuses
server-side** — a request that the client engine would have allowed, rejected by the service. Without
that, the service is a proxy, not an authority. Also: `availableTransitions` omits (never disables) a
transition the caller cannot invoke, and `queryInstances` omits an instance the caller cannot read.

**Phase C — auth.** An unauthenticated call to a protected endpoint returns **401**, verified against
the deployed service rather than a test double. Admin operations require `app.access.admin`.

**Phase D — deploy.** Verified against the *running* pods, not the repo: the new endpoints answer, and
Flyway reports the expected schema version. This gate exists because `app-access` currently logs
`Current version of schema: 1` while its V2 migration is committed — committed is not deployed.

**Phase E — app shell.** Live LLM Vision UX Judge walkthrough per
[`Tools/ux-gate-judge-tools.md`](Tools/ux-gate-judge-tools.md) — this is the phase where rendered UI
changes, and the judge is the only gate that checks the pixels rather than the code. Any finding becomes
a ticket, is fixed, then **recaptured and re-judged**.

**Phase F — regenerated JSON.** Skill Output Judge on the returned JSON, then the real validator against
all 11 fixtures with a pre-change baseline, then `pendingMigration` emptied. Community JSON is
regenerated through the Skill and **never hand-edited**, even for a one-character change.

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
