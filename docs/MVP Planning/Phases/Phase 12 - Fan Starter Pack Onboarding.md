# Phase 12 — Fan Starter Pack Onboarding

**Surface:** Fan App · **UX gate:** HIGH · **On green:** STOP for UX checkpoint, then AUTO → Phase 13
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 11. This phase builds the fan-facing launch entry:
> capture-link landing, one-tap starter-pack follow, and non-empty feed landing. It implements **FE-S13**
> and closes UX gap **U4** by replacing single suggested-creator onboarding with multiple suggested creators.

## 0. Prerequisite gate (validate Phase 11 done)
README gate + confirm Phase 11 can generate a capture link and QR payload through typed APIs. The Phase 12
fan flow consumes that link through `resolveCaptureLink`; it must not depend on creator-feature internals.

## 1. Workflows & user stories in this phase
- **FE-S13 / capture landing** — Fan opens a creator capture link and lands on a creator-branded page.
- **FE-S13 / starter pack** — Fan sees the source creator plus recommended creators, default-selected,
  individually toggleable, and confirmed in one action.
- **FE-S13 / bulk follow** — Bulk follow is idempotent; re-opening the same link does not duplicate follows.
- **FE-S13 / non-empty first session** — Fan lands on a populated feed seeded by starter-pack follows and
  existing interest/persona state.
- **Phase 1 onboarding regression** — Existing fan onboarding suggested-creator surface supports multiple
  suggested creators where applicable, not only one creator card.

## 2. Tools (WSL Ubuntu)
Standard set. No network. Use existing emulator integration-test flow.

## 2A. UX reference research & decision output
Before implementing starter-pack onboarding, review:
- Bluesky Starter Packs: one-tap follow sets, default selected lists, creator/community context, and post-confirm landing.
- Instagram/TikTok profile landing from shared links: creator identity first, immediate follow CTA, and compact context.
- YouTube channel subscribe prompts: creator identity, previews, and no-empty-state landing.
- WhatsApp/community invite flows: invited-by context, group/list preview, and confirmation behavior.
- Mobile onboarding patterns with suggested accounts: avatars, handles, short reasons, selectable rows, and progress state.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 12 specifics:
- Landing page should feel creator-branded and social, not like a web form: avatar/header, creator name, handle,
  short invitation copy, and starter-pack preview.
- Starter-pack rows need avatar/poster, creator name/handle, why recommended, and a clear selected state.
- The primary action should be one-tap: "Follow selected" or equivalent. Advanced explanations belong in sheets.
- After confirm, transition directly to Fan App discovery with visible content; never show an empty generic home.
- Existing onboarding should use the same suggested-creator row/list language so the UX is consistent.

Create [Phase 12 - UX Decisions.md](./Phase%2012%20-%20UX%20Decisions.md) with references, extracted
patterns, key UX/implementation decisions, and a walkthrough of the fan starter-pack workflow.

## 3. APIs invoked & stubs to implement
Use Phase 10 typed clients:
- **Fan Follow Capture API:** resolve capture link, record re-follow.
- **Starter Pack API:** get starter pack and bulk follow selected creators.
- **Fan Passport API:** follows/visibility state, pairwise identity, existing relationship dedupe.
- **Recommendation & Referral API:** starter-pack members are based on Phase 8 recommendation graph.
- **Discovery/Search/Content Host APIs:** feed landing after bulk follow.

No creator feature imports are allowed.

## 4. Data storage (local store)
No new tables expected beyond Phase 10. This phase writes:
- Re-follow events.
- Bulk-follow dedupe records/follows.
- Optional starter-pack seen/accepted audit state if needed by the API contract.

Confirm `resetDemo()` returns to the seeded capture/starter-pack baseline.

## 5. Source files & components to create/update
Design system:
- `core/loom_design_system/lib/components/starter_pack_sheet.dart`
- `core/loom_design_system/lib/components/starter_pack_member_row.dart`
- Optional capture landing composite: `creator_capture_landing.dart`

Fan feature:
- `features/fan/feature_fan_onboarding/`: capture landing screen, starter-pack confirm state, success transition.
- Update fan onboarding view models/mappers to support multiple suggested creators.
- Add route/entry support in app shell or Fan App surface for a simulated capture-link entry point.

Discovery integration:
- Ensure the post-confirm navigation lands on the discovery feed with starter-pack content visible.
- Keep deterministic keys for integration tests.

## 6. API best-practice checks (phase-specific)
- Opening a capture link is read-only until the fan confirms.
- `bulkFollow` and `recordReFollow` are idempotent and safe to retry.
- Bulk follow returns created/skipped counts and selected creator IDs used by the UI.
- Starter-pack response includes only fields rendered by the landing/list.
- Fan visibility defaults from Phase 1 still apply to every created follow.
- The first feed request after starter-pack confirm is bounded and paginated.

## 7. Component boundary / design checks
- `feature_fan_onboarding` imports only contracts, design system, and app shell.
- No fan feature imports creator launch package.
- Starter-pack UI components are business-agnostic and do not import APIs.
- Existing Phase 1 onboarding tests remain valid or are intentionally updated for plural suggested creators.

## 8. Automated validation checks
README baseline plus:
- Unit tests for capture-link resolution view model.
- Unit tests for starter-pack selection toggles and bulk-follow request mapping.
- Unit tests for idempotent re-open and existing-follow skipped behavior.
- Widget tests for landing, selected/unselected rows, loading, empty, and error states.
- Regression test that original fan onboarding can still complete.

## 9. Integration tests
- `it_p12_capture_landing` — Fan opens simulated creator capture link and sees creator-branded landing.
- `it_p12_starter_pack_bulk_follow` — Fan follows selected starter-pack creators in one tap and lands on a non-empty feed.
- `it_p12_starter_pack_idempotency` — Re-opening the same capture link shows existing state and does not duplicate follows.
- `it_p12_onboarding_suggested_creators` — Existing onboarding surfaces multiple suggested creators and preserves Phase 1 completion.

## 10. Definition of done
Fan can join through a creator capture link, confirm a toggleable starter pack in one action, and land on a populated
feed. Existing onboarding supports multiple suggested creators. All checks are green; debug APK builds and launches
on the emulator; [Phase 12 - API Review.md](./Phase%2012%20-%20API%20Review.md) and
[Phase 12 - UX Decisions.md](./Phase%2012%20-%20UX%20Decisions.md) are filed. Update the tracker with Phase 12
status, completion date, API review link/name, gate evidence, and commit SHA.

## 11. Next phase
After Phase 12 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 13 — Conversion Analytics and Creator Utility Consoles.md](./Phase%2013%20-%20Conversion%20Analytics%20and%20Creator%20Utility%20Consoles.md).**
