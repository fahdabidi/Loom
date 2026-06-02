# MVP Gap Analysis — Launch Scope

Status: Draft for review
Type: Gap analysis (go-to-market → MVP delivery)
Companion to: [Loom Launch Playbook](./Loom%20Launch%20Playbook.md)
Proposed remediation: [Phase 10 — Launch: Audience Re-acquisition & Onboarding](../MVP%20Planning/Phases/Phase%2010%20—%20Launch%20Audience%20Re-acquisition%20and%20Onboarding.md)

## Purpose

The [Launch Playbook](./Loom%20Launch%20Playbook.md) defined a concrete go-to-market scope. This
document answers: **what is missing — across product docs, API specs, MVP scope, and the existing
demo — to deliver that launch scope as a standalone demo with no backend connected?**

It is organized as requested: missing **user stories/workflows** (`docs/Product Docs`), missing
**APIs** (`docs/API`), and missing **scope** (`docs/MVP Planning`), preceded by the capability
checklist and current state, and followed by a consolidated matrix and severity ranking.

## What the launch scope requires (capability checklist)

From the playbook, the launch demo must show:

- **(a) Creator audience re-acquisition funnel** — announcement templates, link-in-bio page, QR code,
  follow-capture landing, cross-post. *(The graph cannot be imported from incumbents; fans re-follow
  manually — so this funnel is the core growth mechanic.)*
- **(b) Single-player utility** — owned hub + import own catalog + archive AI Q&A usable *before* any
  fans arrive.
- **(c) One-tap "starter-pack" onboarding** — follow a creator + their recommended creators in one
  action; land on a non-empty feed.
- **(d) Creator-led recommendations + referral** revenue loop.
- **(e) Campaigns / giveaways.**
- **(f) Contextual creator-controlled ads + a no-ad pass.**
- **(g) Super-fan / data-for-value** consent tools.
- **(h) Creator conversion analytics** — the re-acquisition funnel / *conversion yield*.

## Current state (confirmed by exploration)

- **The demo is already fully standalone with no backend** — typed API clients in
  `core/loom_api_contracts/clients/` are backed by an in-app fake (`core/loom_fake_backend/`) over a
  local SQLite store (`core/loom_local_store/`), seeded by `core/loom_seed_data/`, with ~18 fakes
  registered in [app/apps/loom_demo/lib/main.dart](../../app/apps/loom_demo/lib/main.dart). It runs as
  one app with a Creator Studio and a Fan App surface. **So the no-backend constraint is already met;
  new capabilities just need new fakes + seed data.**
- **Product Docs** (22) are comprehensive; the **API inventory**
  ([docs/API/01-api-surface-inventory.md](../API/01-api-surface-inventory.md)) lists ~27 APIs; **MVP
  Planning** has 10 phases (0–9) and is explicitly scoped as a mocked demo, and is **vertical-agnostic**
  (no gaming/esports anywhere — which is fine; gaming is a go-to-market choice, not a demo change).
- Built and working in the demo: **recommendations + referral (d), campaigns/giveaways (e), and
  data-for-value (g)**. Stubbed: `feature_creator_ads`, `feature_creator_monetization`,
  `feature_creator_ai`.

## Consolidated gap matrix

| Capability | Product Doc story? | API in inventory? | MVP phase scope? | In demo today? | Severity |
| --- | --- | --- | --- | --- | --- |
| (a) Re-acquisition funnel | Partial — Doc 21 stories 1/3 + WF1 (framed as import/link, not conversion) | **No** — narrative-only (`ExternalAccountLinkAPI`, `FanFollowCapture`, `CreatorAnnouncementTemplates`, `CrossPostingTools`) | **No** | **No** | **High** |
| (b) Single-player utility | Yes — Doc 21 S2, Doc 11 S1 | Partial — AI Gateway ✓; `ImportPublicMetadataAPI` missing | Partial — Phase 2 scopes import; Phase 5 fan-side AI | Partial — compose UI only (no import picker); AI Q&A fan-side only | **Medium** |
| (c) Starter-pack onboarding | **No — missing entirely** | **No** — no `StarterPack`/`BulkFollow` API | **No** — Phase 1 is single follow | Partial — single first-follow only | **High** |
| (d) Recommendations + referral | Yes — Doc 12 | **Yes** — Recommendation & Referral API | Yes — Phase 8 | **Yes** | None |
| (e) Campaigns / giveaways | Yes — Doc 10 | **Yes** — Campaign + Sponsor Campaign API | Yes — Phase 8 (one giveaway) | **Yes** | None |
| (f) Contextual ads + no-ad pass | Yes — Doc 09 | Partial — ad logic inside Playback Auth; `AdDecisionAPI`/`PremiumNoAdAPI` not surfaced | Yes — Phase 4/6 (`CreatorAdPolicy`) | Partial — ads render fan-side; `feature_creator_ads` stubbed | **Medium** |
| (g) Super-fan / data-for-value | Yes — Doc 14 | Partial — consent family narrative-only, ownership dispersed | Yes — Phase 7/8 | **Yes** | Low |
| (h) Conversion analytics | Partial — Doc 02 revenue-by-intent only | **No** — `AudienceAnalyticsAPI`/`AudienceSegmentAPI` not in inventory | Partial — Phase 6 revenue dashboard, no funnel | Partial — revenue dashboard; no fans-reached→re-followed funnel | **Medium** |

The two **High** gaps — (a) and (c) — are exactly the playbook's two core growth mechanics, and both
are missing from *every* layer. Everything else is either done or a contained extension.

## §A — Missing workflows / user stories in `docs/Product Docs`

1. **(c) Starter-pack / bulk-follow onboarding — no story anywhere (new).** Add a user story to
   **Doc 03 (Fan Experience)**, with a fan-app surface note in **Doc 15 (Fan Apps)**: *"As a fan
   arriving via a creator's link, I want to follow that creator and their recommended creators in one
   tap and land on a populated feed, so my first session is immediately valuable."* This is the Bluesky
   Starter-Pack equivalent and the fan-side of the re-acquisition funnel.
2. **(h) Conversion analytics — partial (new story).** **Doc 02 (Creator Experience)** has
   revenue-by-intent stories but none for an acquisition funnel. Add: *"As a creator, I want to see how
   many of the people I drove to Loom actually re-followed, subscribed, or went premium (my conversion
   yield), so I can judge whether my launch push is working."*
3. **(a) Re-acquisition as *conversion* — refinement (not net-new).** **Doc 21 (Migration)** already
   has owned-hub (Story 1) and follow-capture (Story 3) stories, but they are framed around importing/
   linking. Add or reframe a story to make explicit that **the follower graph cannot be imported** and
   the funnel is **manual conversion** — promoting link-in-bio, QR, and announcement templates to
   first-class, fan-converting surfaces.

No story gaps for (b), (d), (e), (f), (g) — they are covered in Docs 21/11, 12, 10, 09, and 14
respectively.

## §B — Missing APIs in `docs/API`

The API inventory omits a set of capabilities that exist only narratively in product-doc FAQs. Because
the demo is built **contract-first** ("typed clients shaped exactly like the OpenAPI specs," per the
Demo App Implementation Plan), **a fake cannot be written until the contract exists** — so these specs
are prerequisites for the launch demo work:

- **Re-acquisition family (a):** `ExternalAccountLinkAPI`, `ImportPublicMetadataAPI`,
  `FanFollowCaptureAPI`, `CreatorAnnouncementTemplatesAPI`, `CrossPostingToolsAPI`, plus a
  link-in-bio / landing surface. *(All named in Doc 21 FAQ; none in the inventory.)*
- **Onboarding (c):** a **new** `StarterPackAPI` / `BulkFollowAPI` — does not exist in any doc.
- **Ads (f):** surface `CreatorAdPolicy` control and `PremiumNoAdAPI` / `AdDecisionAPI` as named API
  surfaces (today dispersed inside Playback Authorization).
- **Analytics (h):** `AudienceAnalyticsAPI` / `AudienceSegmentAPI` (named in Docs 02/14, absent from
  the inventory).

*(For completeness, the exploration also found `StartupTileSurfaceAPI` and `SessionIntentAPI` are
narrative-only despite discovery being built in the demo — worth folding into an inventory cleanup, but
not required for the launch scope.)*

## §C — Missing scope in `docs/MVP Planning`

Phases 0–9 do **not** scope (a), (c), or (h), and leave (b) and (f) partially built:

- **Not scoped:** (a) re-acquisition funnel, (c) starter-pack onboarding, (h) conversion-yield analytics.
- **Partial:** (b) Phase 2 scopes catalog import but the demo only has a compose UI (no import picker),
  and creator-side archive-AI preview isn't scoped (Phase 5 is fan-side); (f) `CreatorAdPolicy` is in
  scope but `feature_creator_ads` is stubbed (no creator control surface).
- **Demo stubs to close:** `feature_creator_ads` (ad-policy console), `feature_creator_ai`
  (creator-side archive-AI preview), `feature_creator_monetization` (membership setup) — all under
  [app/packages/features/creator/](../../app/packages/features/creator/).

**Recommendation:** add a single new phase — **Phase 10 — Launch: Audience Re-acquisition &
Onboarding** (see the companion doc) — that scopes (a) + (c) + (h) and closes the (b)/(f) partials, all
through typed API clients backed by the in-app fake backend over the local store, keeping the demo
vertical-agnostic.

## §D — UX implementation gaps (design guidance vs. what was built)

Separate from the capability gaps above, this section audits the **implemented UX against the design
guidance** in the shared baseline ([Phases/README.md](../MVP%20Planning/Phases/README.md) §"Shared
social-app UX baseline") and each `Phase N - UX Decisions.md`. Findings are tagged **[Guidance not
met]** (the guidance specified something that wasn't built the best way) or **[Improvement]** (the
build is acceptable but the guidance supports doing it better). Each was verified against the
`loom_design_system` components and feature screens.

| # | Finding | Tag | Evidence | Severity |
| --- | --- | --- | --- | --- |
| U1 | **No immersive vertical / short-form discovery surface.** The baseline mandates discovery support *both* a dense feed *and* an immersive full-height media surface (floating actions, bottom metadata panel, TikTok-style). Only the dense feed + content sheet exists. | Guidance not met | README baseline ("Discovery"); Phase 3 UX doc lists only feed cards + sheet; no `PageView`/immersive component in `loom_design_system` | **High** |
| U2 | **Media is placeholder, not meaningful.** Baseline: every feed/channel/player/campaign/studio surface needs a real thumbnail/poster/avatar; "do not ship a phase where the main social surface is mostly text." Build uses generated placeholder posters and never resolved richer assets. | Guidance not met | Phase 0/1/2 UX docs ("generated-looking media", "generated demo posters"); Phase 1 open question defers richer assets to Phase 3 — never resolved | **Medium** |
| U3 | **No loading-skeleton / empty / error states.** The baseline requires skeletons + empty + error states *every phase*; none exist as components. | Guidance not met | No `skeleton`/`shimmer`/`EmptyState`/`ErrorState` components in `loom_design_system` | **Medium** |
| U4 | **Onboarding offers a single suggested creator, not "suggested creators."** Baseline onboarding guidance lists *suggested creators* (plural); Phase 1 built one recommended creator + a single first-follow. (Same root as capability gap (c) starter-pack.) | Guidance not met | README ("Onboarding"); Phase 1 UX doc ("follows … by tapping the recommended creator card") | **Medium** |
| U5 | **Analytics are row-based, not visual.** Studio guidance favors a console with preview panels; revenue-by-intent, audience insights, and especially the *new conversion funnel* read far better as compact visuals (bars/funnel) and still fit a phone. | Improvement | Phase 6 UX doc ("row-based instead of chart-heavy"); Phase 7 UX doc (same); no chart component exists | **Medium** |
| U6 | **Creator Studio setup tasks are shallow "one-action modules."** Import, membership, ad-policy, and AI were built as minimal one-action modules; the editors exist in the design system (`ad_policy_editor`, `monetization_editor`, `import_wizard`) but the flows are thin and three feature packages stayed stubs. Guidance wants real console editors with preview + validation. | Improvement | Phase 2 UX doc ("compact one-action modules … without overbuilding"); stubbed `feature_creator_ads`/`_ai`/`_monetization` | **Medium** |
| U7 | **Pagination never upgraded past manual "Load more."** Acceptable for testing, but the feed-rhythm guidance implies modern continuous browsing; Phase 0/3 flagged upgrading and never did. | Improvement | Phase 0/3 UX docs (open questions on feed-style/infinite scroll) | **Low** |

**Cross-cutting read:** U1–U3 are the biggest "modern social feel" gaps and are *cross-cutting*
(not launch-specific). U4–U6 sit directly on the Launch-scope surfaces — U4 is the fan starter-pack,
U5 is the new conversion-yield analytics, and U6 is the very set of stubbed creator editors Phase 10
must finish. All UX remediations are folded into Phase 10 (see its "UX hardening" scope), since there
is no later phase to carry them.

## Severity ranking & recommended order

1. **High — do first:** (a) re-acquisition funnel and (c) starter-pack onboarding [+ **U4**]; plus the
   one cross-cutting UX gap that most damages the demo's credibility, **U1** (no immersive surface).
   These are the playbook's core growth loop and the headline "modern social" surface.
2. **Medium:** (h) conversion analytics [+ **U5** visual funnel]; (b) finish catalog-import UI +
   creator-side AI preview; (f) creator ad-policy control surface [+ **U6** real editors];
   **U2** richer media; **U3** loading/empty/error states.
3. **Low / none:** (d), (e), (g) — already delivered; **U7** pagination — nice-to-have.

Sequencing note: because the demo is contract-first, **§B (API specs) must land before the §C/Phase-10
demo work** for each capability — write the contract, then the fake, then the UI.
