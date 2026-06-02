# Phase 9 — Export / Portability + Transparency + Full Demo

**Surface:** both · **UX gate:** FINAL emulator full-app · **On green:** auto → Phase 10 for launch + phone validation
**Shared conventions:** [README.md](./README.md).

## 0. Prerequisite gate (validate Phase 8 done)
README gate + confirm **all** prior phases green (Phases 0–8 integration tests pass on the Flutter Android emulator) and the app runs the full surface on the emulator. This phase closes the export/transparency loop and runs the whole-app emulator audits. Physical Android phone validation is now deferred to Phase 10.

## 1. Workflows & user stories in this phase
- **CE-S8 / CE-W6** — Creator exports everything (metadata + content catalog + receipts).
- **Transparency surfaces** — `FanSubscriptionAllocationStatement` + "how this supported creators" (fan), revenue transparency (creator) — finalize.
- **Demo orchestration** — `resetDemo()` control; scripted **author → consume** loop; the six-step "wow" demo runbook.

## 2. Tools (WSL Ubuntu)
Standard set. Export bundle is written to the app sandbox (and surfaced via share) — no cloud.

## 2A. UX reference research & decision output
Before implementing final export, transparency, reset, and full-demo UX, review reference mockups and design guidance from popular social/export/privacy products such as YouTube/Google Takeout-style export surfaces, Facebook/Meta data download and transparency controls, Instagram/TikTok account data surfaces, WhatsApp export/privacy flows, and adjacent receipt/audit products. Focus on export job status, portability bundle clarity, transparency dashboards, receipt reconciliation, reset-demo controls, scripted demo presentation, and final emulator review flow.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 9 specifics:
- Export should use a clear job/status pattern: start action, progress state, completed bundle summary, portable contents checklist, and share/open affordance.
- Transparency surfaces should reconcile fan and creator views with receipt-ledger rows, allocation summaries, and explainers in sheets rather than dense legal text.
- Reset/demo controls belong in a debug/demo menu, not in the primary social navigation; make the scripted demo path obvious for reviewers without exposing test controls as normal UX.
- Perform a final visual consistency sweep across top bars, bottom nav, cards, sheets, icon buttons, thumbnails, avatars, empty states, and dark/light surfaces.
- Phase 9 validates the full export/transparency demo on the Flutter Android emulator. Phase 10 is the physical Android phone validation phase.

Create [Phase 9 - UX Decisions.md](./Phase%209%20-%20UX%20Decisions.md) summarizing references reviewed, UX patterns extracted, key UX and implementation decisions, and a walkthrough of how the final UX demonstrates export, transparency, reset, author→consume, and the six-step wow demo using the collected guidance.

## 3. APIs invoked & stubs to implement
- **Migration & Export API:** `createExportJob`, `getExportJob` (async), produce an export **bundle** (JSON: channel manifest + content + receipts + settlement history). Fake: `MigrationExportFake` (extend from Phase 2 import fake).
- **Receipt Ledger / Settlement Engine:** transparency reads (reuse fakes).
- No new domain APIs — this phase integrates and audits.

## 4. Data storage (local store)
New: `export_jobs(state, bundleRef)`. No new domain tables; export reads across all tables. `resetDemo()` finalized to restore seed v1 and clear authored state.

## 5. Source files & components to create/update
- `core/loom_api_contracts/clients/`: extend `migration_export_api.dart` (export ops).
- `core/loom_fake_backend/`: extend `migration_export_fake.dart` (bundle assembly + async status).
- `core/loom_design_system/components/`: `studio/export_panel.dart`, `supported_creators_view.dart`; finalize `receipt_statement.dart`.
- `features/creator/feature_creator_export/`: screens `export_wizard`, `export_result`; `CHARTER.md`.
- `features/fan/feature_transparency/` (or fold into `feature_wallet`): `supported_creators` + allocation views; `CHARTER.md`.
- `core/loom_app_shell/`: `resetDemo()` control in a debug/demo menu.
- `docs/MVP Planning/Phases/Demo Runbook.md` — the scripted six-step demo + author→consume script (doc, not code).

## 6. API best-practice checks (phase-specific)
- **Export is async** (`createExportJob` → poll `getExportJob` with backoff); no blocking call.
- **Export completeness:** bundle contains all **Required Export State** (channel manifest, content + manifests, receipts, settlement history) — verify against Doc 04 portability classes; no over-fetch of non-portable runtime state.
- **Whole-app provenance sweep:** confirm every screen field across all phases traces to an API response (run the provenance checklist).
- **Whole-app efficiency sweep:** confirm no chatty calls, working pagination/batching, idempotent writes, no material over-fetch — consolidate findings from all phase API Reviews.

## 7. Component boundary / design checks
- `feature_creator_export` and `feature_transparency` import only contracts + design_system + app_shell.
- Final `melos run lint:boundaries` across the whole workspace is clean.
- All feature `CHARTER.md` files accurate and current.

## 8. Automated validation checks
README baseline across the whole workspace. Unit tests: export-bundle assembly/completeness, allocation-statement totals reconcile with receipts.

## 9. Integration tests
- `it_p9_export` — create export job → bundle contains channel + content + receipts; reimport/validate shape.
- `it_p9_full_loop` — **author as creator → switch role → consume as fan** end-to-end (publish w/ summary → discover → play → Q&A → support) on one device.
- `it_p9_wow_demo` — scripted six-step demo runs end-to-end without manual intervention.
- `it_p9_reset_demo` — `resetDemo()` restores seed v1 and clears authored state.

## 10. Definition of done (milestone)
- Creator export produces a complete, portable bundle.
- Transparency surfaces reconcile with receipts.
- Whole-app provenance + efficiency audits pass; consolidated API Review delivered with all spec changes applied.
- The author→consume loop and six-step wow demo run end-to-end, fully offline, on the Android emulator. Physical-phone validation is completed in Phase 10.
- `Phase 9 - UX Decisions.md` filed with final reference research, key UX/implementation decisions, and full-demo workflow walkthrough.
- Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 9 status, completion date, consolidated API review link/name, and emulator gate evidence before marking Phase 9 complete.
- Commit all Phase 9 changes to git and record the commit SHA in the Phase completion tracker before milestone sign-off.

## 11. Next phase
Proceed to [Phase 10 — Launch Audience Re-acquisition and Onboarding.md](./Phase%2010%20—%20Launch%20Audience%20Re-acquisition%20and%20Onboarding.md) for the launch acquisition loop, UX hardening, final manual UX validation, and physical Android phone sign-off.
