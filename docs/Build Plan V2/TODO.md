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

## Open

- [ ] `new-ticket` — Cedar Commons HOA fast-follow: dead-end document access-request flow, overclaimed traceability row — see [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md)
- [ ] `needs-skill-dispatch` — Milestone 2 (retire archetype-pending `NEEDS IMPLEMENTATION` comments) — approved and started 2026-08-12, reference-doc prep done, Chess Club dispatch paused mid-flight (WSL vsock exhaustion), 6 communities not yet attempted; the dispatch pipeline is now migrated to the VirtualBox VM and verified working end to end, so this can resume whenever picked back up — see [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md)
- [x] `blocked` — WSL2 dispatch pipeline unreliable (vsock exhaustion, zombie wslhost process) after ~5hrs continuous use — closed 2026-08-12, migrated to a VirtualBox VM per `wsl-to-virtualbox-migration.md`, verified with a real throwaway ticket run end to end through dispatch/watch/commit/handoff-gate — see [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md)
- [ ] `new-ticket` — 2 pre-existing, previously-untracked failures surfaced by `melos run analyze`/`melos run test` while verifying the VM migration (unrelated to the migration itself): a `directives_ordering` lint in `loom_api_contracts.dart`, and a widget-finder assertion failure in `v3_milestone_phasee_purchase_proposal_test.dart` — see `wsl-to-virtualbox-migration.md` §12
- [ ] `needs-debug-agent` — CJM.16: Member Social Space Messages-tab identity-matching gap, Root Cause Agent dispatch recommended, not yet run — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `needs-debug-agent` — CJM.18: Data Portability Community cross-community sign-up state leak, Root Cause Agent dispatch recommended, not yet run — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `needs-live-validation` — §6 step 7 product-doc reconciliation gate: confirmed closed only for Cedar Commons HOA, status unconfirmed for the other 9 communities — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `new-milestone` — §7 step 8: legacy Dart catalog + bespoke-widget removal, now unblocked (all 10 communities closed), not yet scoped into tickets — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)
- [ ] `new-ticket` — Backlog of deferred polish findings (ISO-8601 date humanization, `maxLines` truncation, contradictory chip pairs) across multiple communities, not yet consolidated — see [Community JSON Migration Tracker.md §8](Community%20JSON%20Migration%20Tracker.md)

## Untracked / ad hoc

Items not tied to a formal tracker doc — the fallback location when a `call_*.sh` dispatch ran without
`DISPATCH_TRACKER_FILE` set. Empty right now.

## Recently closed

- [x] `new-ticket` — Milestone 1 (registry + `table`/`documentLibrary`/`searchAiAnswer`/`exportWizard` widgets) — all 5 sub-tickets done, closed 2026-08-12. 3 of 4 widget tickets caught real bugs in independent verification the dispatch's own checks missed (a rendering-breaking `if`/`else` bug, action-button key collisions, missing test infra). All 4 archetypes reached ✅ REAL. See [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md).
- [x] `needs-skill-dispatch` — Milestone 1.5 (Skill-dispatched JSON authoring, 7 communities) — all 7 done, closed 2026-08-12. 6 durable Skill fixes landed (`solved-patterns.md` patterns 9-14); final validator sweep across all 11 real fixtures confirmed no collateral damage. See [TabId-Archetype Gap Closure.md §8](TabId-Archetype%20Gap%20Closure.md).
