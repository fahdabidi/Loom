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
| ⬜ Open | `new-milestone` | **Phase A — engine implements the archetype contracts.** `CONTRACTS.md` specifies per-person bookkeeping and 6 visibility models; the engine implements neither, so they are prose. Most invasive engine change of this effort: bookkeeping changes effect application, and visibility models change read filtering for all 13 archetypes. Safety net: 210 existing engine tests, plus the Regression Impact Judge pass §6 mandates. | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase A.1 — `event-rsvp` response rows become canonical** (approved 2026-08-14). An earlier draft claimed nothing enforced response exclusivity; measuring the corpus disproved it — six of eight communities use response rows where exclusivity is inherent, Masjid Nur's arrays are hand-written correctly, and only Tabletop's `tournament-event` genuinely lacks it. The real blocker is that `respond` maps to three different arrays depending on the transition, so an archetype cannot tell which set to fill from the action alone; rows remove that ambiguity rather than encoding it, and make Tabletop's bug unrepresentable. Migrates Masjid Nur's `mosque-event-rsvp` and Tabletop's `tournament-event` from arrays to rows, **through the Skill, never by hand**. | corpus measurement during Phase A | 2026-08-14 |
| ⬜ Open | `blocked` | **D9 — four visibility models cannot be implemented: nothing declares which instance-data field plays which part. AWAITING SPEC APPROVAL.** Surfaced by the Phase A.2 dispatch, which correctly stopped rather than inventing a heuristic, and independently verified here. `ArchetypeResolver` resolves the *family*, but `ArchetypeContract` carries only `family` / `isBespoke` / `bookkeeping` / `visibility` — no identity-field metadata — and neither `LoomWorkflowStateMachine`, `RenderBinding` nor `InstanceDataField` supplies any. The corpus has no canonical naming to fall back on: **parties** — `requesterPersonaId` ×6, `guardianPersonaId` ×4, `reviewerPersonaId` ×2, `submitterPersonaId`, `assignedReviewerPersonaId`, `coachReviewerPersonaId`; **participants** — two *incompatible shapes*, `participantPersonaIds` (list) and `participantAPersonaId`/`participantBPersonaId` (pair); **payer** — `ownerPersonaId` ×9, `memberPersonaId` ×4, `guardianPersonaId` ×4, `payerPersonaId` ×3; **recipient** — `recipientPersonaId` ×7, `handoffRecipientPersonaId`. Inferring from every `fanId`-shaped field would admit audit actors and senders; a hard-coded prefix allowlist would silently refuse valid community names. Either is an undocumented access-control heuristic, and access control that guesses is the failure mode this effort exists to remove. **`archetypes/approval-queue-item.md` §7 already lists this as Open** ("The model must let a community say which fields play which part"), so the spec anticipated it. `owner` and `roles` are unaffected and already shipped (`fdb653c8`). | Phase A.2 dispatch + independent verification | 2026-08-14 |
| ⬜ Open | `needs-verification` | **D8 straddle: Phase A reads both `*PersonaIds` and `*FanIds`; delete the dual-read at Phase F's closeout.** Approved 2026-08-14. The archetype contracts name the bookkeeping fields `openedFanIds`, `queuedFanIds`, `reminderFanIds` and so on — the specVersion 4 target, exactly as `allowedRoleIds` is the v4 name for today's `allowedPersonaIds`. The corpus still carries the old spelling, in **129 occurrences** across 7 families: `queuedPersonaIds` 38, `accessRequestedPersonaIds` 23, `acknowledgedPersonaIds` 21, `savedPersonaIds` 17, `downloadedPersonaIds` 13, `openedPersonaIds` 12, `reminderPersonaIds` 5. The bind is circular — A runs against the pre-rename corpus, and F performs the rename but is blocked on A — so A accepts both spellings for the duration. **Exit condition:** at F's closeout, after regeneration, delete the dual-read and confirm nothing resolves the legacy spelling; do it in the same pass as the D3 ratchet, since both are "the corpus is now clean, tighten the code" steps. Leaving the dual-read in place would silently accept un-migrated fixtures forever. | user-approved D8 | 2026-08-14 |
| ⬜ Open | `needs-verification` | **D3 ratchet: promote `orphaned_response_rows` from warning to error as part of Phase F's closeout.** Approved 2026-08-14. It stays a warning while six shipped communities trip it — the guide's own rule is that a community failing the validator is not a deliverable — and becomes an error once Phase F's regeneration makes the corpus clean, so the fix cannot regress. Achievability is demonstrated rather than assumed: a Codex dispatch emitted the full per-state cascade unprompted from the docs alone. **Exit condition:** after Phase F, flip `warning: true` on `_validateResponseRowSweep` and confirm the corpus still validates at zero errors. | user-approved D3 | 2026-08-14 |
| ✅ Closed | `new-ticket` | **D7a — a member with no response row can now RSVP.** Both halves landed: `_loadActions` offers the controls by resolving availability against a synthetic row at the response workflow's `initialState`, and `_applyTransition` materializes the real row on tap. Diagnosed by instrumenting rather than reading: the plumbing was correct all along (`respTable` and `respMachine` both resolved, `viewerRow` null), and the actual blocker was in the test — `tabletop-member-15` was not a registered account, so it had no entry in `_personaTypeById` and `allowedPersonaIds` refused it, which looks identical to the bug under test. The fixture has no late-joiner shape to borrow (all 13 accounts already hold rows on the only event that has any), so the test now registers a typed account with no row. Covered end to end; baseline `+230 ~1 -8` → `+231 -8`. | this effort | 2026-08-14 |
| ⬜ Open | `new-ticket` | **`responseTable` should declare its member field rather than have the code infer `personaId`.** The create-or-get above writes `personaId` when creating a row, because all six response tables in the corpus declare exactly that field — verified, not assumed. It is still an inference. `responseTable` already declares `workflowType`, `eventField` and `pendingStates`; a `memberField` alongside them would make it explicit, and matters specifically at Phase F's `personaId` → `fanId` identity rename, where an inferred literal silently stops matching. | noted while implementing D7a | 2026-08-14 |
| ⬜ Open | `new-ticket` | **Eager response-row fan-out is specified but unimplemented, and the validator is deliberately silent about it.** **User-visible symptom, confirmed by reading the dispatch path:** on any *newly created* event in a row-based community, a member sees the RSVP controls (a missing row reads as "pending", so the buttons render as unanswered), taps *Going*, and **nothing happens** — `_applyTransition` returns `Future.value()` early when `_usesResponseRows && response == null`, with no error and no feedback. A dead button. Seeded demo events work only because their rows were hand-authored into the fixture, which is exactly the AP-13 shape (`no_creation_path_for_editable_type`) the exemption now suppresses. D2 (approved 2026-08-14) makes the engine create one response row per member, in the response workflow's declared initial state, at event creation. **No code does this** — `responseTable` is consumed only for reading (`part28_engine_native_calendar_surface.dart:858` looks a viewer's row up and tests it against `pendingStates`); nothing anywhere creates one, in JSON or in Dart. Seven app-shell tests fail on exactly this, including `organizer creates an event and one pending response per member`, which asserts the target behaviour outright. **The risk to track:** D4 exempts workflows reached through `responseTable.workflowType` from `no_creation_path_for_editable_type`, which is correct for the target design but means the validator now stays quiet about a hole that is real *today*. A visible ⚠ in `archetypes/event-rsvp.md` §4 says so, but a doc warning is not a gate. Land the fan-out with Phase A's engine work, then confirm the seven tests go green — that, not the exemption, is what makes the silence correct. If Phase A ships without it, revisit D4 rather than leaving the exemption in place. | flagged during D1/D2/D6 adoption | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase B — build the workflow service.** Dart HTTP service embedding `loom_workflow_engine`, Postgres via `drift_postgres` (1.3.1 verified against drift 2.33), App Access client for role resolution, deployed to k3s beside the two Java services. Contract is committed (`927baf87`). The decisive test is an integration test proving a guard **refuses server-side** — that is the entire point of the service. | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase C — auth.** Keycloak as an identity *broker* with Google/Apple/Facebook upstream: Loom runs no user directory, and users only ever see the social buttons. All three services become OAuth2 resource servers validating one uniform JWT. `fan_identity` (issuer, subject → fanId) is already built and tested (`5de05e2`). Became load-bearing at the replan: the workflow service contract says identity comes from the token, and there is no token issuer yet — so B can be built and tested but not *used* by the app until C lands. | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase D — deploy and connect.** Build App Access's `installCommunityPackage` derivation endpoint (specified, `e5ec697f`), and **redeploy both Java services** — the running images predate their V2 migrations (`app-access` logs `Current version of schema: 1`), so the join-request and identity-linking endpoints are committed but not reachable. Committed is not deployed. | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase E — app shell switches to remote.** `LocalWorkflowEngineApi` becomes a cache and renderer rather than the authority; the shell renders buttons from the server's `availableTransitions` instead of deciding locally. Plus hiding `tabId`s the caller lacks access to (Dart-side for now; per-persona extension delivery is a later, separate change). | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-milestone` | **Phase F — regenerate all 11 fixtures in one pass**, through the authoring Skill, never by hand: `specVersion: 4`, the identity rename (~1,524 keys), seed identity values stripped (104 instances; 18 read guards go fail-closed, which is correct), and Cedar's draft lifecycle. Then empty `spec-version.json` → `pendingMigration`, whose remaining entries are the fixtures, the 11 package generators, and the validator's legacy branch. | user-directed replan | 2026-08-14 |
| ⬜ Open | `new-ticket` | **9 app-shell test failures** — baseline now `+229 -9`, down from `+227 -11`. **Correction 2026-08-14: these were never "unrelated to this effort", as this row originally claimed.** Decomposed by running them: **7** are the unimplemented eager response-row fan-out (`v3_milestone_a11_event_rsvp_archetype_test.dart` ×6, plus `v3_milestone_calr2g_live_package_test.dart`) — the row above; **1** is the `phasee` purchase-proposal assertion, now characterised as a probable access-control leak — see its own row. The `cjm8` (×2) and `cjm9` failures are **closed**. Baseline is now `+230 -8`. | independent verification during cleanup; decomposed 2026-08-14 | 2026-08-14 |
| ⬜ Open | `needs-debug-agent` | **A member persona renders the Admin tab — probable access-control leak, and it belongs with Phase E.** `v3_milestone_phasee_purchase_proposal_test.dart:287` asserts `community-tab-admin` is absent while `tabletop-member` is the active persona (selected at :227) and finds it present. The test's own comment frames the intent exactly: a direct engine read proves the member cannot `approve`/`request-changes`/`reject`, and the tab assertion is meant to prove the same is true of the rendered surface. **Partially diagnosed, deliberately not guessed at further:** the *generated* path is ruled out — `_personaCanAdministerAnyWorkflow` requires a transition out of an admin-bound state whose guard admits the persona, and a scan of both Tabletop workflows carrying `tabId: "admin"` bindings (`game-purchase-proposal` from `pending`, `tabletop-meetup-announcement` from `draft`) found **no** member-guarded transition. So the tab is arriving via the *declarative* path (`admin` is in `_engineNativeSpecialTabIdsForCosmetics`), and the next step is to instrument `appShellTabsFor` for `tabletop-member` and identify which branch emits it rather than reason about it further. This is Phase E's subject matter ("hide `tabId`s the caller lacks access to"), so fixing it there is likely cheaper than in isolation. Previously tracked only as a generic "widget-finder assertion failure" in `wsl-to-virtualbox-migration.md` §12, which understated it. | decomposed 2026-08-14 | 2026-08-14 |
| ✅ Closed | `new-ticket` | **CJM.9 duplicate tab — a tab id could render twice in the shell nav.** `_mergeDeclarativeTabSpecs` keys `mergedById` by tabId so duplicates collapse there, but the ordering pass after it was a `List`, emitting one entry per *occurrence*. Reachable in production: `overrides` concatenates the configuration's `tabs` with the persona's `personaTabs`, and installing a package over an already-preloaded shell contributes both — a user installing Garden Club onto a preloaded shell saw two Marketplace tabs. Fixed by making `orderedIds` a `LinkedHashSet`, which keeps first-occurrence ordering and restores the uniqueness the downstream `mergedById[tabId]` lookup already assumed (`355fcd20`). Engine's 210 tests confirmed unaffected. | this effort | 2026-08-14 |
| ✅ Closed | `new-ticket` | **CJM.8 Garden Club tab failures — membership was never established in the fixture.** Root cause was one line in each of two layers, both failing *closed* on unknown membership rather than open: `_readPermissionCouldAdmitPersona` returns `hasActiveMembership == true` (so a `null` hides the tab), and the engine's `_isActiveMember` returns `false` when no lookup is set (so `membersOnly` instances vanish). The test supplied neither, which is a state the app never reaches — all three `appShellTabsFor` call sites in `part01` pass `_activeAccountHasActiveMembership`. **Not a Garden Club bug and not a fixture bug:** Camera Club's workflows are *all* `public` and Book Club's tested instance is `public`, so they pass either way; Garden Club is simply the first community with `membersOnly` workflows on the tested surfaces. Fixed by having the fixture call the same `configureEngineAuthorizationForExtensionId` hook production uses. Two false leads worth recording: the `mulch-day-shift` → `mulch-delivery-shift` rename (`154493e6`) was genuinely stale but *not* the cause, and the `Exchange` label expectation was correct all along — `appShellTabsFor` does not derive the label from `appShell.tabs[].label`, so "correcting" it to `Marketplace` was wrong and the test caught it. | this effort | 2026-08-14 |
| ⬜ Open | `new-ticket` | **73 hardcoded `tabId == '…'` comparisons across 8 files**, including a validator rule (`dead_role_binding`) keyed on the literal tab name `calendar`. Residue from before generic tabIds. Separate genuine platform structure (`home`, `messages` are declared platform tabs) from residue, then remove the rest. Deliberately not documented into `CONTRACTS.md` as a "surface", which would have canonised the violation. | user-identified | 2026-08-14 |
| ⬜ Open | `new-ticket` | **Seven identity-vs-role comparisons that can never be true** — `$viewer == '<a declared roleId>'`, in Cedar Commons HOA (×3, previously unflagged), Masjid Nur, Member Social Space, Neighborhood Book Club (×2). The validator now catches them (`0779ef45`); they are fixed by Phase F's regeneration rather than hand-patched, so the type split is demonstrated to catch them rather than asserted to. | corpus scan | 2026-08-14 |
| ⬜ Open | `needs-verification` | `visibleTo` was **dropped** from `CONTRACTS.md` after `LoomWorkflowState.readGuard` was found to already exist and be preferred by the engine (`stateGuard ?? machine.visibility.readGuard`). The guarantee it was meant to give — that a read guard cannot express an identity/role confusion — needs to land as a **validator rule** instead. Not yet written. | design correction | 2026-08-14 |
| ✅ Closed | `new-milestone` | Archetype contracts for all 13, machine-readable artifact, 13 narrative docs, README index, Skill wiring, and a docs-sync gate for archetype-doc coverage. | this effort | 2026-08-14 |
| ✅ Closed | `new-milestone` | Single `specVersion` replacing the three-number scheme, plus `DocsSyncChecker` built as real code — the gate `_meta/docs-sync-checker.md` specified in July and nobody built, whose own opening line predicted the drift that followed. | this effort | 2026-08-14 |
| ✅ Closed | `new-ticket` | Deleted 5,749 lines of dead per-community engines (6 sniffing predicates, zero call sites) and the 27-file `docs/CardSurfaces/` duplicate. Verified zero community-JSON impact per file. | this effort | 2026-08-14 |
