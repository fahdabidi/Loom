# Demo App — Phased Implementation Docs

Per-phase implementation specs for the Demo App (Creator Studio + Fan App).

- **Parent plan:** [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md)
- **Story/workflow IDs** reference [../MVP User Stories Scope.md](../MVP%20User%20Stories%20Scope.md)
- **API surfaces** reference [../../API/01-api-surface-inventory.md](../../API/01-api-surface-inventory.md) and `../../API/OpenAPI/**`

Each phase doc is self-contained and follows the same section structure. An executing agent works through the phases in order, runs automated gates, leaves the app ready for manual UX validation, and proceeds unless the user explicitly pauses or redirects.

## Index

| Phase | Doc | UX gate | On green |
| --- | --- | --- | --- |
| 0 | [Phase 0 - Foundation and Scaffolding.md](./Phase%200%20-%20Foundation%20and%20Scaffolding.md) | low (optional glance) | **auto → 1** |
| 1 | [Phase 1 - Identity and Onboarding.md](./Phase%201%20-%20Identity%20and%20Onboarding.md) | HIGH | **STOP for UX** |
| 2 | [Phase 2 - Creator Publishing and Monetization Setup.md](./Phase%202%20-%20Creator%20Publishing%20and%20Monetization%20Setup.md) | HIGH | **STOP for UX** |
| 3 | [Phase 3 - Discovery Core.md](./Phase%203%20-%20Discovery%20Core.md) | MAJOR | **STOP for UX** |
| 4 | [Phase 4 - Channel Follow Playback and Ads.md](./Phase%204%20-%20Channel%20Follow%20Playback%20and%20Ads.md) | med | **auto → 5** |
| 5 | [Phase 5 - AI Archive QandA.md](./Phase%205%20-%20AI%20Archive%20QandA.md) | med | **auto → 6** |
| 6 | [Phase 6 - Wallet and Revenue Dashboard.md](./Phase%206%20-%20Wallet%20and%20Revenue%20Dashboard.md) | med | **auto → 7** |
| 7 | [Phase 7 - Data Rights and Data for Value.md](./Phase%207%20-%20Data%20Rights%20and%20Data%20for%20Value.md) | HIGH | **STOP for UX** |
| 8 | [Phase 8 - Recommendations Campaigns and Referral.md](./Phase%208%20-%20Recommendations%20Campaigns%20and%20Referral.md) | med | **auto → 9** |
| 9 | [Phase 9 - Export Transparency and Full Demo.md](./Phase%209%20-%20Export%20Transparency%20and%20Full%20Demo.md) | FINAL emulator | **auto → 10** |
| 10 | [Phase 10 - Launch Contracts Store and Fakes.md](./Phase%2010%20-%20Launch%20Contracts%20Store%20and%20Fakes.md) | low (API/data) | **auto → 11** |
| 11 | [Phase 11 - Creator Launch Funnel.md](./Phase%2011%20-%20Creator%20Launch%20Funnel.md) | HIGH | **STOP for UX** |
| 12 | [Phase 12 - Fan Starter Pack Onboarding.md](./Phase%2012%20-%20Fan%20Starter%20Pack%20Onboarding.md) | HIGH | **STOP for UX** |
| 13 | [Phase 13 - Conversion Analytics and Creator Utility Consoles.md](./Phase%2013%20-%20Conversion%20Analytics%20and%20Creator%20Utility%20Consoles.md) | HIGH | **STOP for UX** |
| 14 | [Phase 14 - UX Hardening and Physical Phone Validation.md](./Phase%2014%20-%20UX%20Hardening%20and%20Physical%20Phone%20Validation.md) | FINAL launch + phone | **STOP for final UX** |

---

## Shared conventions (apply to every phase)

These are referenced by every phase doc; phase docs only add phase-specific detail.

### Tooling — WSL Ubuntu only (never PowerShell)
All commands run inside **WSL Ubuntu bash**. Never use PowerShell or Windows paths in the app workflow.

| Purpose | Command (run in WSL, from `app/`) |
| --- | --- |
| Bootstrap workspace | `dart pub global activate melos && melos bootstrap` |
| Static analysis | `melos run analyze`  *(per-package `flutter analyze`)* |
| Boundary lints | `melos run lint:boundaries`  *(per-package `dart run custom_lint`)* |
| Unit tests | `melos run test` |
| Integration tests | `melos run test:integration`  *(`flutter test integration_test -d emulator-5554` or current emulator id)* |
| Build debug APK | `cd apps/loom_demo && flutter build apk --debug` |
| List devices | `flutter devices` |
| Launch emulator | `flutter emulators --launch <emulator_id>` |
| Install on emulator | `adb -s <emulator_id> install -r build/app/outputs/flutter-apk/app-debug.apk` |
| Install on phone (Phase 14 only) | `adb -s <phone_id> install -r build/app/outputs/flutter-apk/app-debug.apk` |

`melos run *` scripts are defined in `app/melos.yaml` during Phase 0.

### Prerequisite gate (start of every phase)
Before any new work, run and confirm **green**:
1. `melos run analyze` → 0 issues
2. `melos run lint:boundaries` → 0 violations
3. `melos run test` → all pass
4. Prior phase's integration tests pass (`melos run test:integration`)
5. App boots on the Flutter Android emulator with no runtime errors. Physical-phone boot/install is required only in Phase 14.
6. Prior phase "Definition of done" fully checked
7. Prior phase changes are committed to git, and the commit SHA is recorded in the Phase completion tracker. Do not begin a new phase with uncommitted changes from the prior phase.
If any item fails → fix the prior phase first; do not start new work.

### API best-practice checks (baseline — every phase, for each API touched)
- **No chatty / N+1 calls:** one screen action ⇒ a bounded, known number of calls.
- **Pagination:** list endpoints use cursor + limit; UI requests pages, never "all".
- **Batching:** multiple same-type reads/writes a screen needs are batched.
- **Idempotency:** every mutating call sends `Idempotency-Key`; the fake dedupes.
- **Minimal payload:** every response field is consumed by the UI — flag/cut over-fetch.
- **Standards:** `X-Loom-Correlation-Id` on mutations; `ApiError` handled; `/v1` paths.
- **Provenance:** every request field traces to a prior API response or seed — log gaps.
Findings + proposed spec edits are recorded in a sibling `Phase N - API Review.md` and fed back to `docs/API/OpenAPI/**`.

### UX reference research + decision output (every phase)
Before implementing or materially changing UX, collect reference mockups, interaction patterns, and design guidance from popular social media products and public design resources. Include, where relevant, YouTube, Instagram, TikTok, Facebook, WhatsApp, and adjacent products whose UX patterns fit the workflow. Use these references to guide Loom's UX choices, but do not copy proprietary branding, visual identity, or copyrighted mockups into the app.

The phase docs already encode the baseline social-app patterns extracted from YouTube, Instagram, TikTok, Facebook/Meta, WhatsApp, and adjacent creator tools. Do not depend on local-only reference folders or saved web archives when executing a phase. Additional public references may be consulted, but the implementation must be executable from the patterns written in the phase docs.

Shared social-app UX baseline:
- App shell: use a compact top app bar with Loom identity plus icon actions, and a persistent bottom navigation bar for primary destinations, following YouTube/Instagram-style mobile structure. Keep role/account switching in a profile/account menu or bottom sheet instead of a large always-visible segmented control.
- Feed rhythm: make content visual-first. Use large thumbnails/posters, creator avatar + handle rows, compact metadata, and icon action rows. Avoid plain bordered cards, oversized text-only panels, and generic colored blocks as the primary visual.
- Discovery: support both dense feed browsing and an immersive vertical/short-form surface. The immersive view should use full-height or near full-height media, floating actions, and a bottom metadata/action panel rather than a form-like layout.
- Navigation depth: use bottom sheets for details, filters, score explanations, privacy choices, purchase confirmation, and quick actions. Reserve full screens for primary tabs, publish flows, channel pages, and settings dashboards.
- Onboarding: use progressive, mobile-first steps with chips, avatars, suggested creators, and clear completion states. Keep forms short, split advanced settings into sheets, and make the next action obvious.
- Creator Studio: use a work-focused dashboard with status cards, compact task lists, preview panels, validation states, and clear publish/monetization controls. It should feel closer to a creator console than a marketing page.
- Trust, receipts, and privacy: use plain-language rows/cards with status, actor, purpose, date, and "why/how" affordances. Put long explanations in sheets so core flows remain scannable.
- Visual assets: every feed, channel, player, campaign, and studio preview should include a meaningful media thumbnail, poster, avatar, or generated demo asset. Do not ship a phase where the main social surface is mostly text.
- Accessibility and polish: keep touch targets at least 44 px, respect safe areas, provide loading skeletons/empty/error states, avoid text overlap at emulator phone widths, and validate with screenshots from the Flutter Android emulator.

Each phase creates or updates a sibling `Phase N - UX Decisions.md` before implementation is considered complete. The doc must include:
- Reference sources reviewed: links or names of official guidelines, public screenshots, pattern libraries, or product flows.
- UX patterns extracted: what the phase learned from the references and why those patterns fit or do not fit Loom.
- Key UX decisions: navigation, layout, controls, copy, empty/loading/error states, accessibility, and responsive behavior.
- Key implementation decisions: important state, data provenance, module, fake-backend, or API choices that shape implementation.
- Workflow walkthrough: how the implemented UX demonstrates each workflow in the phase, and why it is the best fit given the collected UX guidance.
- Open questions/tradeoffs: unresolved UX or implementation risks for the next phase or manual UX review.

### Component boundary / design checks (every phase)
- `melos run lint:boundaries` enforces: `features/**` import only `loom_api_contracts`, `loom_design_system`, `loom_app_shell`; **no** feature→feature, feature→`loom_fake_backend`, or feature→`loom_local_store`.
- `loom_design_system` has no API/business imports.
- Every new/edited feature has an accurate `CHARTER.md`.
- Only `apps/loom_demo` binds concrete impls (fake/http) to contracts.

### Automated validation (every phase)
`melos run analyze` + `melos run lint:boundaries` + `melos run test` all green; new state/mappers have unit tests; `flutter build apk --debug` succeeds.

### Integration tests (every phase)
One `integration_test` per workflow listed in the phase, named `it_p<N>_<workflow-id>`. Each asserts the workflow's **end state** from the scope doc. Run on the Flutter Android emulator via `melos run test:integration` for Phases 0–13; rerun the full launch-demo suite on a physical Android phone in Phase 14.

### Definition of done (every phase)
- Every scope story/workflow in the phase is demonstrable in-app on the Flutter Android emulator. Phase 14 also requires physical Android phone demonstration.
- All automated checks green; integration tests pass.
- API Review filed; spec gaps logged.
- UX Decisions doc filed with reference research, key decisions, and workflow walkthrough.
- UX checkpoint is available through [../Phase Validation Walkthrough.md](../Phase%20Validation%20Walkthrough.md); human validation may continue in parallel.
- All changes for the phase are committed to git after validation, and the commit SHA is recorded in the Phase completion tracker.

### Auto-proceed and Parallel Manual UX Validation
- Human UX validation is especially important for **Phases 1, 2, 3, 7, 9, 11, 12, 13, 14** because UX choices have API/downstream implications.
- Implementation still proceeds after automated gates pass, unless the user explicitly pauses or redirects.
- Validation findings are handled as follow-up fixes while later implementation continues where possible.
Each phase doc restates its own checkpoint.
