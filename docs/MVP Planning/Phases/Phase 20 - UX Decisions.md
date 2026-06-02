# Phase 20 - UX Decisions

Date: 2026-06-02

## Reference Patterns Applied

Phase 20 applies patterns common in YouTube channel pages, Instagram/TikTok creator surfaces, Twitch extension panels, and modern creator Studio previews:

- Creator worlds need a strong first-viewport visual signal: banner media, creator identity, follow state, and a compact policy/persona cue before the module stack.
- Different creators in the same vertical should feel related but not cloned. The channel should vary media tone, accent colors, module order, extension content, and copy.
- Loading, empty, and error states should feel like product surfaces, not test placeholders.
- Live interactive modules should sit inside the creator channel feed as native content blocks, not as detached admin widgets.
- Studio authoring should make the fan-facing effect visible immediately through preview and then verifiable from the Fan App after save.

## Key Decisions

- `ChannelMediaBackdrop` renders deterministic offline media from `bannerRef`. This keeps the showcase visual-first without external assets, network, or copyrighted screenshots.
- `ChannelBanner` now uses richer procedural media while preserving the existing theme pill and channel header hierarchy.
- `CreatorChannelHomeScreen` now has explicit loading, empty, and error states for the new config-driven surfaces.
- Empty enabled modules are treated as a valid creator-authored state. The fan sees a stable empty-state explanation instead of a broken or blank channel.
- Extension runtime startup now uses loading/error states for missing or unavailable extension sessions.
- The Studio customize console uses a loading skeleton while fetching creator/config/catalog state, keeping it visually consistent with the fan surfaces.

## Workflow Walkthrough

1. Fan opens the gaming creator set and sees five distinct creator worlds rather than one reused channel template.
2. Each channel renders creator identity, media, ad posture, AI persona, and module stack from API-backed config.
3. Fan enters live extension modules and sees interaction feedback inside the same channel context.
4. Creator opens Studio customization, changes appearance/extensions/module order, and sees a preview before save.
5. Fan channel rendering consumes the saved creator-authored config, proving the authoring loop.
6. The gaming starter pack brings a new fan into the customized segment and resets cleanly back to seed state.

## Tradeoffs

- Procedural media is less realistic than final hosted artwork, but it is deterministic, offline, and proves the API/data path without adding asset-management scope.
- The Phase 20 showcase remains emulator-first because the final physical-phone gate moved to Phase 26 with the AI-search/external-playback final demo.
- The new async states are intentionally generic design-system components so later Phases 21-26 can reuse them for network and external-player failures.
