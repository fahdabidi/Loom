# Phase 14 - UX Decisions

## References Applied

- TikTok and Instagram Reels: immersive vertical browsing, floating action rail, and bottom metadata/actions over media.
- YouTube Shorts and YouTube Home: a switchable relationship between dense browsing and immersive consumption.
- Instagram and TikTok async conventions: skeleton/empty/error states that feel intentional instead of raw spinner-only states.
- YouTube Studio: compact analytics and creator utility surfaces that stay readable at phone width.
- Material mobile guidance: stable tap targets, safe-area spacing, contrast, wrapping, and scroll behavior.

## Key UX Decisions

- Discovery keeps the existing dense feed as the default because it exposes ranking signals, why-shown actions, search, and intent controls clearly.
- A new immersive discovery toggle opens a vertical media-first surface with category-toned posters, creator row, bottom metadata panel, floating actions, and explicit open action.
- The immersive surface uses existing feed data instead of a separate content model, so the dense and immersive views cannot drift on title, creator, explanation, or provider label.
- Loading, empty, and error states are reusable design-system components with stable keys for integration coverage.
- Immersive discovery auto-loads at the end of the vertical surface. Dense discovery keeps the explicit load-more button for deterministic validation.
- Phase 14 performs emulator UX hardening only; final physical-phone sign-off moves to Phase 20 with the later customization sequence.

## Key Implementation Decisions

- `ImmersiveDiscoveryFeed` accepts a small view model, keeping the design system business-agnostic.
- `DiscoveryHomeScreen` owns only the dense/immersive toggle and maps API-backed `FeedItem` data into the immersive view model.
- `LoadingSkeleton`, `LoomEmptyState`, and `LoomErrorState` are exported from `loom_design_system` for reuse across launch, discovery, onboarding, and analytics screens.
- The creator capture landing and conversion analytics screens now use the reusable loading/error states without changing their API controllers.
- Integration tests cover the new visible states and launch-demo path, but device execution remains pending adb visibility in WSL.

## Workflow Walkthrough

1. Fan opens discovery and can browse the dense feed with search, intent chips, why-shown context, and explicit pagination.
2. Fan taps the immersive toggle and sees a full-height creator/media surface with the action rail and bottom metadata pattern common to modern short-form apps.
3. Fan can return to dense discovery without losing feed state or breaking existing Phase 3/4 content navigation.
4. Fan opens a creator invite, confirms the starter pack, lands on a populated feed, and opens playback.
5. Creator switches to Studio, reviews aggregate conversion analytics, then can open the utility consoles added in Phase 13.
6. The runbook keeps export/reset as the final emulator regression path while physical-phone validation is reserved for Phase 20.

## Open Questions And Tradeoffs

- The current immersive media treatment is deterministic and offline, but later phases can replace category-toned posters with richer generated bitmap assets once customization surfaces mature.
- Phase 14 cannot provide phone evidence in this WSL session because no adb-visible Android device is attached.
