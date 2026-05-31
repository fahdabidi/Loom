# Phase 4 — Channel, Follow, Playback & Ads

**Surface:** Fan App · **UX gate:** med · **On green:** AUTO → Phase 5
**Shared conventions:** [README.md](./README.md).

## 0. Prerequisite gate (validate Phase 3 done)
README gate + confirm: discovery feed/search work and open into content (Phase 3), creator content + `CreatorAdPolicy` exist (Phase 2). Phase 3 integration tests pass.

## 1. Workflows & user stories in this phase
- **FE-S1 / FE-S1B** — Follow / unfollow / block a creator (visibility from Phase 1).
- **FE-S12 / FE-W12** — Multi-format consumption (video + post) from one creator home.
- **FE-S2 / FE-W2 / MN-S1** — Ad-supported playback with **creator-controlled contextual ads** (no behavioral targeting) + receipts.

## 2. Tools (WSL Ubuntu)
Standard set. Use a bundled sample video asset + a poster image for playback (no streaming infra).

## 2A. UX reference research & decision output
Before implementing channel, follow, playback, and ad UX, review reference mockups and design guidance from popular social/video apps such as YouTube, Instagram, TikTok, Facebook, WhatsApp Channels, and adjacent streaming/player products. Focus on creator home layouts, follow/block controls, relationship visibility, video/post consumption, player chrome, ad-slot treatment, ad disclosure, completion states, and non-behavioral ad-context explanations.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 4 specifics:
- Build creator channel pages with a banner/header, avatar, handle, follow state, quick actions, and tabbed or segmented content sections like modern channel/profile pages.
- Make watch/detail pages media-first: player/post body at the top, then creator row, metadata, action icons, summary, related items, and receipts/disclosures in sheets.
- Put follow, unfollow, block, and relationship visibility actions in familiar profile menus or confirmation sheets; keep destructive actions explicit.
- Render ads as clearly labeled contextual slots with creator-policy disclosure and no behavioral targeting language; expose the ad receipt through a compact info affordance.
- Player chrome should be minimal, touch-friendly, and safe-area aware, with loading, paused, completed, and error states visible on the emulator.

Create [Phase 4 - UX Decisions.md](./Phase%204%20-%20UX%20Decisions.md) summarizing references reviewed, UX patterns extracted, key UX and implementation decisions, and a walkthrough of how the implemented UX demonstrates channel browsing, follow/unfollow/block, content consumption, ad-supported playback, and receipt flows using the collected guidance.

## 3. APIs invoked & stubs to implement
- **Creator Metadata API:** `getChannelHome`, `getContentDetail`. Extend `CreatorMetadataFake`.
- **Content Host API:** `getPlaybackAsset`. Extend `ContentHostFake`.
- **Playback Authorization API:** `authorize` (single-call decision → playback token **+ ad plan** derived from `CreatorAdPolicy` + session-intent ad context + entitlements), `complete` (completion trigger → emits receipts). Fake: `PlaybackAuthorizationFake`.
- **Fan Passport API:** `unfollow`, `block`. Extend `FanPassportFake`.
- **Receipt Ledger API:** ingest `PlaybackReceipt`, `AdImpressionReceipt`, delivery receipt. Fake: `ReceiptLedgerFake`.

## 4. Data storage (local store)
New tables: `ad_inventory` (seed; mapped to categories/brands), `playback_tokens`, `receipts(type, contentId, intentContext, ...)`. Extend `follows` with block state. Ad selection in the fake filters `ad_inventory` by the content's `CreatorAdPolicy` + session-intent ad posture only.

## 5. Source files & components to create/update
- `core/loom_api_contracts/clients/`: fill `playback_authorization_api.dart`, `receipt_ledger_api.dart`; extend `creator_metadata_api.dart`, `content_host_api.dart`, `fan_passport_api.dart`. Models: `ChannelHome`, `ContentDetail`, `PlaybackAuthorization`, `AdPlan`, `PlaybackReceipt`, `AdImpressionReceipt`.
- `core/loom_fake_backend/`: `playback_authorization_fake.dart`, `receipt_ledger_fake.dart`; extend the others.
- `core/loom_design_system/components/`: `creator_channel_header.dart`, `player_chrome.dart`, `ad_slot.dart`, `post_view.dart`.
- `features/fan/feature_creator_channel/`: screens `channel_home`, `content_detail` (renders video or post by `contentType`); follow/unfollow/block controls; `CHARTER.md`.
- `features/fan/feature_playback/`: `player_screen`, `playback_controller` (authorize → play → complete); `CHARTER.md`.

## 6. API best-practice checks (phase-specific)
- **Playback authorization is a SINGLE call** that returns the full decision (access + ad plan). The UI does **not** make a separate ad-decision round trip.
- **Ad context carries no behavioral targeting:** the `authorize` request payload contains only contentId, session-intent ad posture, and entitlement state — verify no fan-behavior fields are sent. Ad eligibility = `CreatorAdPolicy` ∩ posture.
- **Completion = one trigger** that emits the receipts (batched), idempotent (`Idempotency-Key`).
- Minimal payload: `ContentDetail`/`ChannelHome` return only rendered fields.

## 7. Component boundary / design checks
- `feature_playback` and `feature_creator_channel` import only contracts + design_system + app_shell.
- Player/ad components are presentational; authorization logic stays in the feature's controller calling the contract (no direct fake import).
- `melos run lint:boundaries` clean.

## 8. Automated validation checks
README baseline. Unit tests: ad-plan derivation from `CreatorAdPolicy` + posture (incl. a blocked-category case), receipt emission on completion, block-state suppression of creator content.

## 9. Integration tests
- `it_p4_follow_unfollow_block` — follow → unfollow → block; blocked creator content suppressed.
- `it_p4_multiformat_render` — open a video and a post from one channel home; each renders by type.
- `it_p4_ad_supported_playback` — play free content → ad shown is allowed by `CreatorAdPolicy`; a blocked category never appears; `PlaybackReceipt` + `AdImpressionReceipt` emitted.
- `it_p4_completion_receipts` — completing playback emits receipts once (idempotent).

## 10. Definition of done
Fan can browse a channel, follow/unfollow/block, consume video + post, and watch ad-supported content where ads honor `CreatorAdPolicy` with no behavioral targeting; receipts flow; all checks green; API Review filed; UX Decisions doc filed. Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 4 status, completion date, API review link/name, and gate evidence before marking this phase complete. Commit all Phase 4 changes to git and record the commit SHA in the tracker before proceeding.

## 11. Next phase
UX is med with no new API-shaping decisions beyond those validated. After Phase 4 changes are committed and the commit SHA is recorded, **AUTO-PROCEED: immediately begin [Phase 5 — AI Archive Q&A](./Phase%205%20-%20AI%20Archive%20QandA.md).**
