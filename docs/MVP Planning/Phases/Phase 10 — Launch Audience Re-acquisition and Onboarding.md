# Phase 10 — Launch: Audience Re-acquisition & Onboarding

**Surface:** both · **UX gate:** med · **On green:** END (post-MVP launch phase)
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution. It closes the gaps identified in
> [MVP Gap Analysis — Launch Scope](../../Go-To-Market/MVP%20Gap%20Analysis%20—%20Launch%20Scope.md) so the standalone
> demo can tell the [Launch Playbook](../../Go-To-Market/Loom%20Launch%20Playbook.md) story. **No backend; new
> capabilities use typed API clients backed by the in-app fake backend over the local store for app runs,
> with in-memory Drift only for tests. Vertical-agnostic — reuses existing mixed seed creators.**
>
> New story IDs introduced here (added to `MVP User Stories Scope.md` and Product Docs 02/03/15/21):
> **CE-S10** (creator re-acquisition funnel), **CE-S11** (conversion-yield analytics),
> **FE-S13** (starter-pack onboarding).
>
> This phase also carries the **UX hardening** items **U1–U7** from the
> [Gap Analysis §D](../../Go-To-Market/MVP%20Gap%20Analysis%20—%20Launch%20Scope.md) (design-guidance vs. build), since
> there is no later phase to absorb them. They are scoped in §1, §2A, §5, and the Definition of Done below.

## 0. Prerequisite gate (validate Phase 9 emulator gates)
README gate + confirm the full Phase 0–9 demo is green on the Flutter Android emulator: author→consume
loop, recommendations & referral (Phase 8), wallet/settlement (Phase 6), data-for-value (Phase 7), and
export (Phase 9). The recommendation graph must be populated (Phase 8) because starter packs reuse it.
Phase 10 is now the physical-phone validation gate for the completed launch demo.

## 1. Workflows & user stories in this phase
- **CE-S10 / new** — Creator runs the re-acquisition funnel: pick an announcement template, get a
  link-in-bio page + QR code, and a shareable follow-capture landing (cross-post is a stub). *(The
  follower graph is **not** imported — this drives manual re-follows.)*
- **FE-S13 / new** — Fan arriving via a creator's link follows that creator **+ their recommended
  creators in one tap** (starter pack) and lands on a non-empty feed.
- **CE-S11 / new** — Creator views the conversion funnel: audience reached → re-followed → member/
  premium (**conversion yield**).
- **CE-S2B (finish)** — Creator catalog-import UI (Phase 2 leftover): import own public-metadata
  references, usable before any fans exist.
- **MISSING-S1 / CE-S3B (finish)** — Creator ad-policy console: allow/block ad categories & brands
  (`CreatorAdPolicy`), completing `feature_creator_ads`.
- **CE-W7 (finish surface)** — Creator-side archive-AI preview: the creator can ask their own archive
  before fans arrive (single-player utility), completing `feature_creator_ai`.
- **MN-S* (finish surface)** — Membership tier setup console, completing `feature_creator_monetization`.

**UX hardening (U1–U7 — fixing design-guidance gaps; see Gap Analysis §D):**
- **U1 (High)** — Add the **immersive vertical / short-form discovery surface** the baseline requires
  (full-height media, floating actions, bottom metadata/action panel) alongside the existing dense
  feed; a feed toggle switches between them.
- **U4 (High)** — Onboarding offers **multiple suggested creators** (delivered by the starter pack
  in FE-S13), not a single recommended creator.
- **U5 (Medium)** — Render the **conversion funnel and the revenue-by-intent / audience breakdowns as
  compact visuals** (bar/funnel), not row-only — phone-sized, aggregates only.
- **U6 (Medium)** — Build the newly-unstubbed creator setup tasks (ad-policy, AI preview, membership,
  import) as **real console editors with preview + validation states**, not one-action modules.
- **U2 (Medium)** — Replace placeholder posters with **richer generated media** across feed, channel,
  player, campaign, and starter-pack surfaces (still no external assets — generated, offline).
- **U3 (Medium)** — Add reusable **loading-skeleton, empty, and error states** to the design system
  and apply them on the new (and existing) async surfaces.
- **U7 (Low)** — Offer **feed-style pagination** on discovery while keeping an explicit "Load more"
  path for integration tests.

## 2. Tools (WSL Ubuntu)
Standard set. QR generation via an offline package (e.g. `qr_flutter`) — no network.

## 2A. UX reference research & decision output
Review reference patterns from creators' real launch/migration playbooks and onboarding surfaces:
Bluesky **Starter Packs** (one-tap follow a curated set + land on a full feed), Linktree / link-in-bio
pages, Substack/YouTube "I've moved here" announcement posts, QR-driven follow flows, and creator
analytics funnels (YouTube Studio audience tab, Patreon insights). Focus on: announcement templates,
link-in-bio layout, QR/landing capture, one-tap bulk-follow, and a simple conversion funnel.

Apply the shared social-app UX baseline from the README, plus these Phase 10 specifics:
- The re-acquisition surface lives in Creator Studio as a "Launch / Grow" area: template picker,
  live link-in-bio preview panel, QR card, and a copyable landing link — Studio preview/validation
  patterns.
- The starter-pack onboarding is a short progressive flow: a creator-branded landing → "Follow
  [creator] + N recommended creators" toggleable list defaulting to all-on → one-tap confirm → feed.
- Conversion analytics is a single funnel card (reached → re-followed → member/premium) plus a small
  trend; never expose per-fan behavioral data (respect the firewall).
- Re-acquisition copy must be honest about manual re-follow ("invite your audience to follow you on
  Loom"), never implying an automatic follower import.
- **UX hardening references:** TikTok/Instagram Reels **immersive vertical players** (full-height
  media, floating action rail, bottom metadata) for U1; Material/Skeleton loading patterns and
  empty/error-state guidance for U3; YouTube Studio / Patreon **funnel & bar visualizations** for U5;
  YouTube Studio multi-step editors for U6. Apply, don't copy proprietary visuals.

Create `Phase 10 - UX Decisions.md` summarizing references, patterns extracted, decisions, and a
walkthrough of the launch loop.

## 3. APIs invoked & stubs to implement
*(Contracts have been added to the API inventory; implement typed clients, fakes, and UI against those
surfaces, then file the Phase 10 API Review.)*
- **Fan Follow Capture API (new):** `createCaptureLink`, `resolveCaptureLink`, `recordReFollow`. Fake:
  `FanFollowCaptureFake`.
- **Creator Announcement Templates API (new):** `listTemplates`, `renderAnnouncement`,
  `getLinkInBio`. Fake: `CreatorAnnouncementFake`.
- **Starter Pack API (new):** `getStarterPack(creatorId)` (creator + recommended creators from the
  Phase 8 recommendation graph), `bulkFollow`. Fake: `StarterPackFake`.
- **Audience Analytics API (new):** `getConversionFunnel(creatorId)` → reached / re-followed /
  member / premium, sourced from follow + entitlement + capture state. Fake: `AudienceAnalyticsFake`.
- **Creator Metadata API (extend):** persist `CreatorAdPolicy` from the ad console; persist
  membership tiers; expose creator-side archive-AI permission for the preview.
- **AI Gateway API (reuse):** creator-side archive Q&A preview reuses the existing fan Q&A path.
- **Follow / Entitlement / Recommendation & Referral APIs (reuse):** bulk-follow writes follows;
  funnel reads entitlements; starter pack reads recommendations.

## 4. Data storage (local store)
New tables: `capture_links(creatorId, token, channel)`, `re_follow_events`, `announcement_templates`,
`starter_packs(creatorId, memberIds)`. Reuse `follows`, `entitlements`, `recommendation_manifests`,
and `ad_policies` (or add `ad_policies` if not present from Phase 2). No network; all local.

## 5. Source files & components to create/update
- `core/loom_api_contracts/clients/`: add `fan_follow_capture_api.dart`,
  `creator_announcement_api.dart`, `starter_pack_api.dart`, `audience_analytics_api.dart`. Models:
  `CaptureLink`, `AnnouncementTemplate`, `LinkInBio`, `StarterPack`, `ConversionFunnel`, `AdPolicy`,
  `MembershipTier`.
- `core/loom_fake_backend/`: add `fan_follow_capture_fake.dart`, `creator_announcement_fake.dart`,
  `starter_pack_fake.dart`, `audience_analytics_fake.dart`; register all in
  [app/apps/loom_demo/lib/main.dart](../../app/apps/loom_demo/lib/main.dart).
- `core/loom_seed_data/`: add a simulated inbound capture link/deep-link and a small
  recommended-creator bundle (reusing existing seed creators — no vertical change).
- `core/loom_design_system/components/`: `studio/launch_panel.dart` (templates + link-in-bio + QR),
  `qr_card.dart`, `starter_pack_sheet.dart`, `studio/conversion_funnel_card.dart`. **UX hardening
  components:** `discovery/immersive_feed.dart` (U1, `PageView` full-height player), `loading_skeleton.dart`
  + `empty_state.dart` + `error_state.dart` (U3, reused across surfaces), `viz/mini_bar_chart.dart` +
  `viz/funnel_chart.dart` (U5), and deepen the existing `studio/ad_policy_editor.dart`,
  `studio/monetization_editor.dart`, `studio/import_wizard.dart` into full editors with preview +
  validation (U6).
- `core/loom_seed_data/`: richer generated media for posters/avatars/campaign art (U2) — generated
  offline, no external assets, no vertical change.
- `features/creator/feature_creator_*`: new launch/re-acquisition screens (new package
  `feature_creator_launch` **or** extend `feature_creator_audience`); fill stubs in
  `feature_creator_ads`, `feature_creator_ai`, `feature_creator_monetization`; finish import UI in
  `feature_creator_publishing`. Update each `CHARTER.md`.
- `features/fan/feature_fan_onboarding/`: add starter-pack entry screen + bulk-follow confirm.

## 6. API best-practice checks (phase-specific)
- Capture-link resolve + re-follow is **idempotent** (re-opening a link doesn't double-count); bulk
  follow is idempotent (no duplicate follows).
- Re-acquisition emits an **audit-class** capture/re-follow event, **not** an economic receipt (no
  payout tied to a follow).
- Conversion funnel returns **aggregates only** — never per-fan behavioral rows (Audience Data
  Firewall); no universal fan IDs.
- Ad-policy edits are versioned; playback authorization (Phase 4) consumes the latest `CreatorAdPolicy`.
- Minimal payloads; starter pack reuses the Phase 8 recommendation graph rather than a new ranking path.

## 7. Component boundary / design checks
- New/extended features import only contracts + design_system + app_shell; no feature→feature imports
  (fan onboarding must not import creator features).
- `melos run lint:boundaries` clean; all touched charters updated.

## 8. Automated validation checks
README baseline. Unit tests: capture-link idempotency, bulk-follow idempotency + starter-pack
membership resolution, conversion-funnel aggregation math, ad-policy versioning, creator-side AI
preview permission. Widget tests for the new UX-hardening components: immersive feed renders
full-height media + actions (U1); `loading_skeleton`/`empty_state`/`error_state` render per async state
(U3); funnel/bar viz render from aggregates (U5).

## 9. Integration tests
- `it_p10_re_acquisition` — creator creates an announcement + capture link/QR → opening the link lands
  on the creator-branded follow-capture page.
- `it_p10_starter_pack` — fan opens a creator capture link → one-tap follow creator + N recommended
  creators → lands on a **non-empty** feed; re-opening does not duplicate follows.
- `it_p10_conversion_funnel` — after starter-pack follows + a simulated premium purchase, the creator's
  conversion funnel shows reached → re-followed → premium, aggregates only.
- `it_p10_ad_policy` — creator blocks an ad category in the console → fan playback (Phase 4) no longer
  serves that category.
- `it_p10_creator_ai_preview` — creator asks their own archive before any fan exists → cited answer
  (single-player utility).

## 10. Definition of done
Creator can run a re-acquisition funnel (template + link-in-bio + QR + capture landing), a fan can join
via a starter pack in one tap and land on a populated feed, and the creator can see conversion yield;
catalog import, ad-policy console, creator-side AI preview, and membership setup are no longer stubs;
**UX hardening U1–U7 done: an immersive vertical discovery surface exists alongside the dense feed (U1);
onboarding suggests multiple creators (U4); funnel/breakdowns are visual (U5); the unstubbed editors
have preview + validation (U6); media is richer-generated (U2); loading/empty/error states exist and are
applied (U3); feed-style pagination is available with Load-more retained for tests (U7);**
everything works fully offline through typed API clients backed by the in-app fake backend over local
Drift/SQLite for app runs and in-memory Drift for tests; the demo stays vertical-agnostic; all checks
green; final physical Android phone install/launch and key full-demo flows pass; API Review filed;
`Phase 10 - UX Decisions.md` filed. Append the launch loop to the wow-demo narrative in
[../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) and update the Phase
completion tracker with status, date, API review link, and commit SHA.

## 11. Next phase
END of the MVP + launch demo. Optional follow-ups (not in this phase): full extension marketplace,
live/streaming formats, real backend swap (HTTP clients replace fakes with zero UI changes), and
inventory cleanup of the remaining narrative-only APIs (`StartupTileSurfaceAPI`, `SessionIntentAPI`).
