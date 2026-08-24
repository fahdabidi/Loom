# Live TODO — cross-effort rollup

**This is an index, not a memory.** One line per open item, newest/most-relevant first, each linking to its
full entry (context, source, exact wording) in the owning tracker's own `## 8. Live TODO / Next Steps Queue`
section (`docs/Build Plan V2/Tools/reference-tracker-template.md` defines that section's shape and the fixed
tag taxonomy used everywhere below). Never write item detail directly here — if you're about to write more
than one line for an item, that content belongs in the tracker, not here.

**How this file gets updated:** propose-then-promote, never a dispatched agent editing this file directly.
An Implementation Agent proposes next steps in its own STATUS.md (`## Proposed next steps`); during your own
independent-verification step, you review that proposal, write the confirmed items into the owning tracker's
§8, and add/remove the matching one-line rollup here. Every `call_*.sh` dispatch script prints a reminder
banner at completion so this step is never silently skipped — see `docs/Build Plan V2/Tools/README.md`'s core
pipeline step 5.5.

**Verification sweep 2026-08-24.** Every checkable claim below was re-measured against the working tree
rather than carried forward, and nine items closed on measurement alone — they had been fixed by later work
and never struck. Suite baselines quoted inside older tracker entries are stale by construction; the current
numbers are judges **428**, app shell **271**, engine **281 (+3 skipped)**, demo **153**, zero failures on
Windows.

## Open

### The production bar — this is what GA means

- [ ] `needs-spec-decision` — **25% of the production bar cannot be proven as written: 20 of 79 B25 rows name a workflow or role their shipped package does not have.** 11 of the 13 missing roles are the *same* role, `owner`, across Cedar (`hoa-board`), Chess (`chess-organizer`), Book Club (`book-organizer`), Garden (`garden-coordinator`) and Masjid Nur (`masjid-admin`) — while Ad-Free and Soccer *do* declare `ad-off-owner`/`soccer-owner`. So this is one vocabulary decision unblocking 11 rows, not 11 bugs. **Do not settle it by editing the doc rows to match the packages** — rule 14 forbids converging by removal, and two communities model `owner` as real. Full list and method: [Evidence/B25/b25-row-reachability-2026-08-24.md](Evidence/B25/b25-row-reachability-2026-08-24.md)
- [ ] `needs-live-validation` — **0 of 79 B25 rows durably proven**, though the pipeline itself now works: the 2026-08-24 run produced the first non-zero `screenshotCount` (B12 harness 3/3 `completionGateEligible=true`, B15 Chess 4/4) after clearing four stacked blockers — wrong `JAVA_HOME`, the demo app never installed, `adb` not on PATH inside the ANR guard, and the capture iterating all nine phases when each community lives in exactly one — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `needs-debug-agent` — **Garden walkthrough stall**, unfixed and reproducing on both hosts; fails in ~4 min with a diagnostic. The `garden-tool-loan-giveaway` doc/package id mismatch was the trigger; the stall behaviour still needs closing — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — 3 of the 6 product defects found by walking real shipped packages remain open — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)

### Platform phases — no backend is in the loop yet

- [ ] `new-milestone` — **Phase A**: engine implements per-person bookkeeping and response-row fan-out. Scope is smaller than the §8 entry's original text: the 6 visibility models **are** now enforced (`local_workflow_engine_api.dart`, `authz_p4a_visibility_filtering_test`), so bookkeeping and fan-out are what remain. Blocks B and F — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase A.1**: `event-rsvp` response rows become canonical; migrates Masjid Nur's `mosque-event-rsvp` and Tabletop's `tournament-event` — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase B**: all 5 workflow-service operations implemented, App Access-authorized and verified live; only k3s deployment remains — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase C**: auth — Keycloak-as-broker (Google/Apple/Facebook), all 3 services as resource servers. Zero JWT/OAuth2 code exists in either Java service today — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase D**: deploy — App Access derivation endpoint, and redeploy both Java services (running images predate their V2 migrations) — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase E**: app shell asks the access authority instead of deriving locally; hide `tabId`s the caller lacks access to — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Phase G.4**: Ad-Free revert, the last open piece of Phase G (G.1–G.3 done 2026-08-20) — see [Tab Visibility Derivation Spec Proposal.md](Tab%20Visibility%20Derivation%20Spec%20Proposal.md)
- [ ] `needs-verification` — 3 engine tests skip for want of a deployed backend: 2 need `LOOM_POSTGRES_PASSWORD` (k3s PostgreSQL port-forward), 1 needs a real fan JWT plus a live community id. These are the concrete acceptance gate for Phases B/C/D — un-skipping them is how those phases get proven rather than asserted

### Spec decisions that block other work

- [ ] `needs-spec-decision` — `deliver_reminder` applies cleanly to 2 of 4 candidates; Chess and Soccer expose a contradiction inside `permissions.md` itself and are deliberately UNAPPLIED — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `needs-spec-decision` — Calendar hardcodes transition id `send-reminder`; 9 communities declare 7 different spellings, so Camera/Cedar/Garden/Masjid Nur get **no** reminder and the failure is swallowed by a `debugPrint` — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `needs-spec-decision` — two permission vocabularies that do not meet: `community.surface.navigation.*` (app-shell only, decided by string suffix) vs `permissions.md`'s `community.manage_settings` (App Access). Prerequisite for Phase E — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-milestone` — **Document ACL**: `sharedWith` is one flat `fanId` list, so there is exactly one permission level ("shared" = "can read") and sharing with a group is impossible. Sequenced AFTER Phase F — see [Document ACL Spec Proposal.md](Document%20ACL%20Spec%20Proposal.md)
- [ ] `new-milestone` — **Spec-version compatibility hardening**: Layers 1–3 land with the v4-only cut; Layer 4 (packages declaring `requiresCapabilities`) needs a spec decision — see [Spec Version Compatibility.md](Spec%20Version%20Compatibility.md)

### Known defects and debt

- [ ] `needs-debug-agent` — CJM.18: Data Portability cross-community sign-up state leak — a statically-confirmed stale-closure defect in `_authApiForCommunity`, with a fix and 2 regression tests already specified — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `needs-debug-agent` — CJM.16 Messages-tab fix, landing with Phase F rather than as its own dispatch — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-ticket` — Cedar Commons HOA fast-follow: dead-end document access-request flow, overclaimed traceability row — see [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md)
- [ ] `new-ticket` — eager response-row fan-out (D2) is specified but **no code implements it**; land it with Phase A, or revisit D4's validator exemption — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `new-ticket` — **30** hardcoded `tabId == '…'` comparisons across **16** files (re-measured 2026-08-24; the previously recorded "73 across 8" no longer matches the tree), including a validator rule keyed on the literal `calendar` — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `needs-skill-dispatch` — **Ad-Free product doc enrichment, redo under hard rule 14b.** The 2026-08-24 convergence dispatch returned a materially better doc (24 → 54 named interactions) that also rewrote the B25 header to five columns, which makes the judge parse **zero** rows for that community. The enrichment is worth keeping; the table shape is not negotiable
- [ ] `needs-verification` — D3 ratchet: promote `orphaned_response_rows` warning→error at Phase F closeout — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `needs-verification` — `visibleTo` dropped in favour of the existing `LoomWorkflowState.readGuard`; its guarantee still needs to land as a validator rule — see [Access Control and Workflow Service Tracker.md §8](Access%20Control%20and%20Workflow%20Service%20Tracker.md)
- [ ] `needs-live-validation` — §6 step 7 product-doc reconciliation gate: confirmed closed only for Cedar Commons HOA, unconfirmed for the other 9 — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `new-milestone` — §7 step 8: legacy Dart catalog + bespoke-widget removal, now unblocked but not yet scoped into tickets — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `new-ticket` — backlog of deferred polish findings (ISO-8601 date humanization, `maxLines` truncation, contradictory chip pairs) across multiple communities, not yet consolidated — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `new-ticket` — **rotate three exposed secrets before GA**: Google client secret, Facebook app secret, DeepSeek API key. Deferred by user decision until production-ready, which makes it a release blocker rather than a backlog item

## Untracked / ad hoc

Items not tied to a formal tracker doc — the fallback location when a `call_*.sh` dispatch ran without
`DISPATCH_TRACKER_FILE` set. Empty right now.

## Recently closed

- [x] `new-ticket` — **Phase F's fixture half is done**, verified 2026-08-24: all 11 packages declare `specVersion: 4`, zero legacy triple fields, `pendingMigration` is empty (emptied 2026-08-19/20), and `missing_visibility_fields` findings across the corpus are **0**. The entry recording "32 expected findings until Phase F backfills" no longer describes the tree.
- [x] `new-ticket` — **All 11 shipped packages validate clean through the validator API**, now gated by `shipped_corpus_validation_test.dart`. Ad-Free, Book Club and Soccer were regenerated through the Skill on 2026-08-24 to close 4 `invalid_visibility_field_type` errors that rules added after authoring had never been re-run against.
- [x] `needs-debug-agent` — app-shell test failures (last recorded `+236 -4`, and separately "3 of 7 target failures remain") — closed on measurement 2026-08-24: **271 passed / 0 failed**, with the total up from 248, so nothing was deleted to get there.
- [x] `new-milestone` — demo app never migrated to specVersion 4 and never in the verification loop (last recorded 56 passed / 73 failed) — closed on measurement 2026-08-24: **153 passed / 0 failed**.
- [x] `new-ticket` — 7 `$viewer == '<roleId>'` comparisons that can never be true — closed on measurement 2026-08-24: **zero** remain across all 11 packages.
- [x] `new-ticket` — Dart never enforces a tab's `requiredPermission` (`enforceRequiredPermission` defaulted to **false**) — closed: it now defaults to **true** (`part11_shell_models.dart:608`).
- [x] `needs-skill-dispatch` — 10 communities declare `requiredPermission` on no tab — **obsolete**: Phase G removed `requiredPermission` from the grammar, and **0** corpus files reference it.
- [x] `needs-skill-dispatch` — Tabletop Club regeneration reverted over `formula` + `required: true` on `queueLength` — closed 2026-08-24: the shipped file carries the formula without `required`, validates at 0 errors, and Tabletop is a reference example rather than one of the ten B25 product communities.
- [x] `new-ticket` — 2 pre-existing failures surfaced during the VM migration — both closed on measurement 2026-08-24: `loom_api_contracts` analyzes clean, and `v3_milestone_phasee_purchase_proposal_test` passes inside the green app-shell suite.
- [x] `new-ticket` — **Skill channel drift**: `chatgpt-upload` was missing hard rules 14/14a entirely, so runs on that channel were authorised to ship packages never compared against their product doc. Ported, and gated by `skill_channel_parity_test.dart` (verified red on removal).
- [x] `new-ticket` — **ChatGPT bundle rot**: 7 mirrored files stale against `docs/references`, including `04-validation.md` 114 lines behind and `16-spec-version.json`. Refreshed via SKILL.md's own recipe, gated by `chatgpt_bundle_mirror_test.dart`.
- [x] `new-ticket` — **Worked example taught retired vocabulary** under a specVersion 4 header (46 errors). Regenerated through the Skill: 0 errors, teaching comments preserved.
- [x] `new-ticket` — **`data/` partially tracked despite `.gitignore`**: 2 dispatch scripts were committed before the ignore, so `git reset --hard` kept reverting them to DeepSeek and only some agents lost their GPT-5.6 profile. Untracked; the adoption kit is the single source.
- [x] `new-ticket` — `_fileSha256`'s Windows `certutil` fallback was unreachable (`Process.runSync` throws on a missing binary). Fixed; judges suite 427/1 → 428/0 on Windows.
- [x] `new-ticket` — Milestone 1 (registry + `table`/`documentLibrary`/`searchAiAnswer`/`exportWizard` widgets) — all 5 sub-tickets done, closed 2026-08-12. See [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md).
- [x] `needs-skill-dispatch` — Milestone 1.5 (Skill-dispatched JSON authoring, 7 communities) — all 7 done, closed 2026-08-12. See [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md).
- [x] `blocked` — WSL2 dispatch pipeline unreliable (vsock exhaustion, zombie wslhost) — closed 2026-08-12, migrated to a VirtualBox VM and verified end to end. See [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md).
- [x] `needs-skill-dispatch` — Milestone 2 (retire archetype-pending `NEEDS IMPLEMENTATION` comments) — closed 2026-08-13, all 7 communities via narrow surgical-edit Skill dispatches. See [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md).
