# Phase 1 — UX Decisions

## Reference sources reviewed

- [Material Design onboarding guidance](https://m2.material.io/design/communication/onboarding.html) for progressive setup and keeping first-run flows short.
- [Material Design chips](https://m3.material.io/components/chips/overview) for compact multi-select controls.
- [YouTube Help: Create a YouTube channel](https://support.google.com/youtube/answer/1646861?hl=en) for channel name/handle setup.
- [YouTube Help: Customize your channel layout](https://support.google.com/youtube/answer/3219384?hl=en) for creator-home setup and "For you" channel personalization patterns.
- [TikTok Help: Manage topics](https://support.tiktok.com/en/using-tiktok/exploring-videos/manage-topics) and [TikTok Help: For You](https://support.tiktok.com/en/using-tiktok/exploring-videos/for-you) for topic preference and recommendation-control patterns.
- [Instagram Help: account privacy](https://help.instagram.com/116024195217477) for clear public/private relationship defaults.
- [Meta: keeping WhatsApp modern, simple, and accessible](https://about.fb.com/news/2024/05/keeping-whatsapp-modern-simple-and-accessible/) for restrained mobile setup flows.

## UX patterns extracted

- Use a short, progressive onboarding sequence instead of a dense setup form.
- Represent interest cold-start as selectable chips because the task is scanning and selecting many lightweight topics.
- Keep privacy state explicit before the first social action, then make the resulting follow visibility visible after completion.
- Treat creator setup as channel name, handle, description, category, then hosting acceptance. This mirrors common creator products without forcing publishing decisions into Phase 1.
- Keep the Phase 0 catalog visible in the Fan App default surface so existing proof-slice validation remains easy.

## Key UX decisions

- The Fan App opens to the Phase 0 creator catalog with a direct `Start fan onboarding` action. This preserves the catalog proof slice while making Phase 1 reachable without extra navigation.
- Fan onboarding steps are passport, interests, privacy, first follow, complete. A progress indicator gives orientation without adding a heavy stepper.
- The interest picker requires at least 10 selected topics, matching the phase gate and giving discovery enough cold-start signal for Phase 3.
- The first follow defaults to private visibility. The complete state includes a visibility toggle so FE-S1A is demonstrable immediately.
- Creator Studio opens directly to creator onboarding because Phase 1 is the first real Studio workflow.
- Managed hosting acceptance is a separate step so the creator explicitly accepts the simulated hosted-content baseline before Phase 2 publishing.

## Key implementation decisions

- Added Phase 1 DTOs and abstract APIs for Fan Passport, Fan Vault, Creator Channel Registry, and Creator Metadata extensions.
- Added Drift tables for fan passports, personas, follows, consent grants, interest taxonomy/profile, ad preferences, creator channels, channel manifests, hosting contracts, and idempotency records.
- Added fake implementations per API surface while keeping feature packages isolated from fake/store imports.
- Added design-system components for onboarding layout, interest chips, persona/visibility segmented selection, and channel setup fields.
- Added integration tests for FE-W1, MISSING-S2, FE-S1A, and CE-W1, plus a controller/mapper unit test for interest batching.

## Workflow walkthrough

1. Fan starts from the Fan App catalog and opens fan onboarding.
2. The app creates a fan passport, active persona, and baseline consent grant through idempotent Fan Passport calls.
3. The app fetches the interest taxonomy once, the fan selects 10 chips, and the app persists them through one `putInterests` batch call.
4. The fan chooses first-follow visibility, then follows Solar Sarah using a creator id returned by the catalog API.
5. The completion state shows saved interest count, one taxonomy fetch, one interest batch write, followed creator, and visibility; the visibility toggle demonstrates FE-S1A.
6. Creator Studio opens to channel setup, creates a channel, binds a handle, writes the profile manifest, then accepts managed hosting.
7. The creator completion state shows the created channel and accepted hosting contract.

## Open questions / tradeoffs

- Manual UX review should confirm whether 10 topics is the right minimum before Phase 3 discovery uses the taxonomy.
- The role switcher remains in the app bar for now; Phase 2 can revisit whether identity/persona controls should absorb role switching.
- The first-follow visibility model is intentionally simple. Phase 7 should revisit consent/visibility language when data-rights flows are implemented.
