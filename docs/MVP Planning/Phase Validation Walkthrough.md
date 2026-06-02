# Phase Validation Walkthrough

This is the manual validation playbook for the Demo App while implementation continues in parallel. Use it to validate the latest installed Android emulator build, record pass/fail notes, and send issues back as they appear. Implementation can continue unless a blocker makes the app unusable.

## How To Use

1. Launch the latest installed Demo App on the Flutter Android emulator.
2. Check [Demo App Implementation Plan](./Demo%20App%20Implementation%20Plan.md) for the latest completed or in-progress phase.
3. Walk through the section for that phase. Skip pending phases until a build with that phase is installed.
4. Mark each row as `Pass`, `Fail`, or `Needs change` in the Result column.
5. For every issue, send the issue template at the bottom of this doc with the phase, screen, action, expected result, actual result, and screenshot if useful.

Authoritative final physical Android phone validation is now deferred until Phase 26. Phases 0 through 25 are validated on the Flutter Android emulator unless physical hardware is available for a preliminary smoke pass.

## Parallel Validation Protocol

- Use the currently installed emulator build unless I explicitly say a new build is installed.
- Continue validating the phase you are on while implementation moves ahead. A failed row does not block the next implementation phase unless the app cannot launch or the role switcher/navigation is unusable.
- When reporting an issue, include the phase number and the exact row or action. I will keep implementing forward and patch validation issues in parallel.
- After I install a new build, repeat only the rows affected by the change unless I ask for a broader regression pass.

## Current Phase Availability

| Phase | Validation type | Current state | Primary entry point |
| --- | --- | --- | --- |
| 0 | Foundation regression | Complete | App launch and role switcher |
| 1 | High UX checkpoint | Complete | Fan App and Creator Studio |
| 2 | High UX checkpoint | Complete | Creator Studio publishing setup |
| 3 | Major UX checkpoint | Complete | Fan App discovery feed |
| 4 | Medium UX checkpoint | Complete | Fan creator channel and playback |
| 5 | Medium UX checkpoint | Complete | Fan App archive Q&A |
| 6 | Medium UX checkpoint | Complete | Fan wallet and Creator revenue dashboard |
| 7 | High UX checkpoint | Complete | Fan data rights and Creator audience |
| 8 | Medium UX checkpoint | Complete / ready for validation | Recommendations, referral, and campaigns |
| 9 | Export/transparency full-app emulator validation | Complete / ready for validation | Export, transparency, reset, emulator |
| 10 | Launch contracts/data smoke | Complete / ready for validation | App launch and reset after launch API state |
| 11 | High UX checkpoint | Complete / ready for validation | Creator Studio Launch/Grow |
| 12 | High UX checkpoint | Complete / ready for validation | Fan capture landing and starter pack |
| 13 | High UX checkpoint | Complete / ready for validation | Creator conversion analytics and utility consoles |
| 14 | Emulator UX hardening + launch regression | Complete / ready for validation | UX hardening, full launch demo, optional phone smoke |
| 15 | Extension platform smoke | Complete / ready for validation | Gaming creators and extension slots |
| 16 | Config-driven creator channels | Complete / ready for validation | Five creator worlds and generic channel regression |
| 17 | Competitive/economy extensions | Complete / ready for validation | Clip Arena, Pick'Em, HypeWars |
| 18 | Collaborative/creative extensions | Complete / ready for validation | Quest Log, Build Showcase, Guild Quest |
| 19 | Creator Studio customization | Complete / ready for validation | Customize console and fan preview |
| 20 | Customization showcase | Complete / ready for validation after install | Five-world fan showcase and Studio authoring on emulator |
| 21 | AI search foundation | Complete / ready for validation | Contract/fake/store smoke for AI search and external content |
| 22 | Fan AI search settings | Complete / ready for validation | Settings, simulated agent/source connections, disclosures |
| 23 | AI search results | Complete / ready for validation | Creator-preferred merged results and title/source handling |
| 24 | Embedded external playback | Complete / ready for validation after install | YouTube player, AI-driven next rail, offline/error states |
| 25 | Creator external content in feeds | Complete / ready for validation after install | Studio external content linking and fan feed attribution |
| 26 | Final showcase + physical phone | Pending | Full AI-search showcase, emulator regression, physical-phone sign-off |

## Phase 0 - Foundation And Shell

Goal: confirm the app launches cleanly, uses the modern shell, and the role switcher is usable.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Launch the app on the emulator. | App reaches the first rendered screen without hanging on the Flutter splash screen. |  |
| 2 | Inspect the first viewport. | The shell looks like a modern mobile app, not a bare test harness. |  |
| 3 | Switch between Fan App and Creator Studio. | Both surfaces load without blank screens, crashes, or stale navigation state. |  |
| 4 | Return to Fan App. | Bottom navigation, toolbar, and content area remain aligned and responsive. |  |
| 5 | Rotate or resize only if convenient. | Layout still avoids clipped text, overlapping controls, and unstable card sizing. |  |

## Phase 1 - Identity And Onboarding

Goal: validate the identity foundation, fan interest picker, creator onboarding, and creator-card follow flow.

### Fan Onboarding

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Fan App and start fan onboarding. | Fan onboarding opens with polished social-app styling and clear progress. |  |
| 2 | Create the demo fan passport. | Passport creation completes and the interest picker appears. |  |
| 3 | Select interests across categories. | Chips are scannable, selected state is clear, and scrolling is smooth. |  |
| 4 | Save interests. | App advances to privacy/persona setup without losing selections. |  |
| 5 | Continue through privacy defaults. | Defaults are understandable and not overly technical. |  |
| 6 | Tap the suggested creator card itself, not only its button. | Creator card is clickable and follow state completes. |  |
| 7 | Review final state. | Final state shows fan onboarding complete, plural starter-creator follows, and private visibility. |  |

### Creator Onboarding

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator Studio. | Creator onboarding screen appears with a polished Studio-style channel card. |  |
| 2 | Create the creator channel. | Channel profile is created and the managed-hosting step appears. |  |
| 3 | Review managed-hosting copy. | The value of managed hosting is clear without feeling like legal text. |  |
| 4 | Accept managed hosting. | Completion state appears. |  |
| 5 | Review final state. | Channel name, handle, and hosting status are visible. |  |
| 6 | Open publishing setup. | Phase 2 Studio setup opens. |  |

## Phase 2 - Creator Publishing And Monetization Setup

Goal: validate that Creator Studio setup feels like a modern creator workflow, not a basic admin form.

### Setup Entry

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator Studio. | Creator onboarding or completed creator state appears. |  |
| 2 | Complete creator onboarding if needed. | The publishing setup entry point is visible. |  |
| 3 | Open publishing setup. | Phase 2 setup screen opens with header, status cards, and publish composer. |  |
| 4 | Review first viewport. | The page feels dense, modern, and creator-focused; status cards and publish path are clear. |  |

### Publish Composer

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Review media preview and title/summary fields. | Media preview comes first; title and required summary are easy to understand. |  |
| 2 | Test missing summary. | Inline error appears for the required summary. |  |
| 3 | Generate an AI draft summary. | Summary field receives a usable draft. |  |
| 4 | Publish video. | Success state shows manifest version. |  |
| 5 | Publish post. | Member-only post publishes successfully after summary exists. |  |

### Import, Membership, Ads, AI

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Start catalog import. | Import completes and external references success state appears. |  |
| 2 | Define membership tiers. | Membership setup reports entitlement definitions registered. |  |
| 3 | Save creator ad policy. | Saved state appears and blocked categories are clear. |  |
| 4 | Enable AI archive access. | AI content policy stored state appears. |  |
| 5 | Review the whole page after setup. | Controls are compact; saved states are easy to verify; no text overlaps. |  |

## Phase 3 - Discovery Core

Goal: validate Fan App discovery: startup tiles, session intent, glass-box feed, feedback, mid-session switching, trending, and neutral search.

### Startup Tiles And Intent

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Fan App after Phase 3 or later is installed. | Home or Discover surface shows modern intent/topic entry points. |  |
| 2 | Select a startup tile or intent chip. | A session intent is created and the disclosure is visible. |  |
| 3 | Review tile design. | Tiles are visual, scannable, and explain what kind of feed they start. |  |

### Glass-Box Feed

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Review feed cards. | Cards show thumbnail/media, title, summary, creator, and compact why-shown badges. |  |
| 2 | Open a why-shown explanation. | Sheet or detail view explains top ranking factors without overwhelming the feed. |  |
| 3 | Load more feed content. | Page 2 loads without duplicate content or jarring layout shifts. |  |
| 4 | Review trending/entertainment mode. | Trending items use host aggregate stats and feel visually distinct enough. |  |

### Feedback And Search

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Like, dislike, mute, or block from a feed card. | Feedback affordances are icon-based, clear, and optimistic. |  |
| 2 | Refresh or fetch next page. | Disliked or muted content is suppressed or visibly affected. |  |
| 3 | Switch session intent mid-session. | Disclosure updates and feed re-ranks for the new intent. |  |
| 4 | Search for a topic or creator. | Search feels neutral, uses thumbnails or creator rows, paginates, and shows no ad fields. |  |

## Phase 4 - Channel, Follow, Playback, And Ads

Goal: validate creator-channel browsing, follow/block controls, playback, post consumption, and privacy-safe ad presentation.

### Creator Channel

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open a creator from discovery. | Creator channel opens with strong visual hierarchy, avatar/header, follow state, and content tabs. |  |
| 2 | Follow and unfollow the creator. | State changes are immediate, clear, and reversible. |  |
| 3 | Change relationship visibility if exposed. | Visibility copy is understandable and does not feel buried. |  |
| 4 | Block the creator if exposed. | Block action is clear, guarded where needed, and removes future eligibility. |  |

### Playback And Ads

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open a video item. | Player chrome appears with title, creator, progress/status, and no layout jump. |  |
| 2 | Start or review playback authorization state. | Playback decision is clear and content is playable. |  |
| 3 | Inspect the ad slot on ad-supported playback. | Ad slot is labeled, compact, creator-policy aware, and not behaviorally targeted. |  |
| 4 | Complete playback or close the player. | Playback completion and receipt state do not disrupt navigation. |  |
| 5 | Open a post item. | Post renders with summary, creator context, and receipt/completion state where expected. |  |

## Phase 5 - AI Archive Q&A

Goal: validate cited creator-archive Q&A and source-attribution receipts.

### Fan Q&A

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open a creator or content item with archive Q&A available. | Q&A entry point is visible but does not crowd the primary content. |  |
| 2 | Ask a recommended question. | Answer returns with cited sources and a clear answer/citation split. |  |
| 3 | Ask a custom question if available. | Query works without exposing implementation jargon. |  |
| 4 | Open source citations. | Citations link back to relevant content summaries or source rows. |  |
| 5 | Inspect usage or source-attribution receipt. | Receipt is understandable and includes source attribution. |  |

### Creator AI Setup Regression

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator Studio publishing setup. | AI archive policy state from Phase 2 is still visible. |  |
| 2 | Enable or review archive Q&A policy. | Creator understands what archive access enables and what content is eligible. |  |
| 3 | Return to Fan App Q&A. | Fan Q&A still works after role switching. |  |

## Phase 6 - Wallet And Revenue Dashboard

Goal: validate simulated no-ad premium, creator membership, entitlement status, fan allocation, and creator revenue by source/intent.

### Fan Wallet

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Fan Wallet. | Wallet uses modern subscriptions/payments styling with entitlement rows and clear simulated-money language. |  |
| 2 | Start no-ad premium purchase. | Confirmation sheet appears with amount, benefit, and simulated-payment state. |  |
| 3 | Confirm no-ad purchase. | Premium no-ad entitlement appears, receipt is visible, and no duplicate charge appears on repeat confirmation. |  |
| 4 | Play ad-supported content after purchase. | Playback skips the ad slot or clearly shows no-ad premium eligibility. |  |
| 5 | Start creator membership purchase. | Confirmation sheet shows creator, tier, amount, and membership benefit. |  |
| 6 | Confirm membership purchase. | Membership subscription appears and member entitlement state is visible. |  |
| 7 | Open fan allocation statement. | Statement explains how the subscription supported creators with amounts and receipt context. |  |

### Creator Revenue

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator Studio revenue dashboard. | Dashboard opens with metric cards, source breakdown, intent breakdown, and recent receipts. |  |
| 2 | Review by-source revenue. | Source breakdown is readable and reconciles with simulated purchases/receipts. |  |
| 3 | Review by-intent revenue. | Intent breakdown appears in one dashboard view and is not hidden behind developer terminology. |  |
| 4 | Inspect recent receipts. | Receipt rows include amount, source, intent or support context, and status. |  |
| 5 | Switch back to Fan App and return. | Revenue dashboard remains stable after role switching. |  |

## Phase 7 - Data Rights And Data For Value

Goal: validate consent, data grants, relationship controls, and DataAccessReceipts.

### Fan Data Rights

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open data rights dashboard. | Dashboard explains active consents, data categories, and revocation paths clearly. |  |
| 2 | Review a creator data-request. | Request explains actor, purpose, value exchange, categories, duration, and revocation. |  |
| 3 | Approve a request. | Approval is obvious, persisted, and reflected in dashboard state. |  |
| 4 | Narrow a request. | Sheet or control lets the fan choose allowed fields/categories without confusion. |  |
| 5 | Deny a request in a separate run if possible. | Denial state is clear and creator access is blocked. |  |
| 6 | Set a category default. | Future matching requests honor the default and explain why. |  |
| 7 | Revoke a grant. | Revocation updates dashboard state and blocks future access. |  |

### Creator Audience

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator audience or data request screen. | Creator sees aggregate insight panels and permission status, not raw surveillance-like data. |  |
| 2 | Create or review interest-data request. | Request flow uses purpose, fields, retention, and value exchange clearly. |  |
| 3 | Query approved audience data after fan approval. | Only approved fields or aggregates appear. |  |
| 4 | Inspect DataAccessReceipt. | Receipt shows who accessed what, when, why, and under which grant. |  |

## Phase 8 - Recommendations, Campaigns, And Referral

Goal: validate creator recommendations, referral transparency, campaign setup, giveaway participation, and sponsor data-for-value reuse.

### Creator Recommendations And Campaigns

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator recommendation builder. | Builder follows Studio patterns with preview, status, validation, and publish state. |  |
| 2 | Publish a recommendation. | Recommendation publishes with disclosure-ready metadata. |  |
| 3 | Publish or review referral terms. | Terms, window, caps, and destination creator are clear. |  |
| 4 | Settle the demo referral. | Creator revenue shows referral source revenue and a referral receipt. |  |
| 5 | Open campaign builder. | Campaign setup uses preview, reward, eligibility, schedule, and final review. |  |
| 6 | Publish giveaway campaign. | Campaign appears ready for fan participation. |  |

### Fan Discovery And Participation

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Fan discovery after recommendation publish. | Recommendation appears with "recommended by" context and lightweight disclosure. |  |
| 2 | Record the recommendation as seen. | Discovery receipt appears near the recommendation card. |  |
| 3 | Convert through recommendation from Creator Studio. | Referral attribution receipt is emitted and visible in creator revenue. |  |
| 4 | Open giveaway campaign card. | Card feels like a social/community post with visual media, concise terms, and clear CTA. |  |
| 5 | Enter giveaway. | Entry flow confirms eligibility, consent/data-value offer if present, reward status, and receipt. |  |
| 6 | Accept sponsor data-for-value offer if present. | Flow reuses Phase 7 consent language and does not introduce behavioral-targeting copy. |  |

## Phase 9 - Export, Transparency, And Full Demo

Goal: validate export/portability, transparency surfaces, demo reset, full author-to-consume flow, and emulator run.

### Export And Transparency

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator export screen. | Export uses job/status pattern with start, progress, completed summary, and share/open affordance. |  |
| 2 | Create export job. | Job completes and reports portable bundle contents. |  |
| 3 | Review export contents summary. | Bundle includes channel, content/catalog, receipts, settlement history, and policy data. |  |
| 4 | Open fan transparency or supported-creators view. | Fan sees allocation and receipt-ledger context in clear language. |  |
| 5 | Open creator transparency/revenue reconciliation. | Creator view reconciles receipts, allocation, and revenue without conflicting totals. |  |

### Full Demo

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Run the author-to-consume loop. | Creator authors content/policies, switches role, and Fan App consumes the authored output. |  |
| 2 | Run the six-step wow demo. | Flow is smooth and understandable without developer explanation. |  |
| 3 | Reset demo from debug/demo menu. | App returns to seeded baseline without stale authored state. |  |
| 4 | Relaunch after reset. | App starts cleanly and seed world is restored. |  |
| 5 | Validate on emulator. | APK installs, launches, and full demo works on the Flutter Android emulator. |  |

## Phase 10 - Launch Contracts, Store, And Fakes

Goal: validate that the app still launches and resets cleanly after launch API contracts, local-store tables, fakes, and seed data are added. This phase has no main UX checkpoint.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Launch the app on the emulator. | App reaches the first rendered screen without hanging or showing a schema/reset error. |  |
| 2 | Switch between Fan App and Creator Studio. | Existing Phase 0-9 surfaces still load. |  |
| 3 | Reset demo from debug/demo menu. | App resets without errors and returns to seeded baseline. |  |
| 4 | Relaunch after reset. | App starts cleanly and existing seed world is restored. |  |

## Phase 11 - Creator Launch Funnel

Goal: validate the Creator Studio launch-growth workflow: announcement templates, link-in-bio preview, QR/capture link, external account context, and cross-post stub.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator Studio Launch / Grow area. | Creator sees a modern Studio console with launch status, templates, preview, QR/capture link, and external account context. |  |
| 2 | Choose an announcement template. | Template selection updates preview without layout shift. |  |
| 3 | Render or copy an announcement. | Copy is honest about inviting fans to re-follow on Loom and never implies follower import. |  |
| 4 | Review link-in-bio preview. | Preview shows creator identity, primary Loom follow link, and relevant public links. |  |
| 5 | Review QR/capture link card. | QR/copy controls are clear and capture-link state is visible. |  |
| 6 | Start simulated cross-post. | Cross-post status is explicitly stubbed/simulated and does not imply real external posting. |  |

## Phase 12 - Fan Starter-Pack Onboarding

Goal: validate fan arrival through a creator capture link, one-tap starter-pack follow, idempotency, and non-empty feed landing.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open a creator capture link. | Fan lands on a creator-branded follow-capture page. |  |
| 2 | Review starter-pack list. | Source creator and recommended creators show avatars, names/handles, why-recommended context, and selected states. |  |
| 3 | Toggle one recommended creator off and on. | Selection state is clear and primary action remains stable. |  |
| 4 | Confirm starter pack. | Fan follows the selected creators in one action. |  |
| 5 | Land in Fan App feed. | Feed is non-empty and reflects the starter-pack follows. |  |
| 6 | Re-open the same capture link. | App shows existing/accepted state and does not duplicate follows. |  |
| 7 | Run existing fan onboarding if reachable. | Suggested creator UX supports multiple creators and Phase 1 completion still works. |  |

## Phase 13 - Conversion Analytics And Creator Utility Consoles

Goal: validate creator conversion-yield analytics and completed creator utility consoles.

### Launch Analytics

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator conversion analytics. | Funnel shows reached -> re-followed -> member/premium with aggregate-only values. |  |
| 2 | Review funnel visuals at phone width. | Visual is compact, readable, and not row-only. |  |
| 3 | Inspect supporting trend/source rows if present. | Rows do not expose per-fan behavioral data or universal fan IDs. |  |

### Utility Consoles

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Review creator catalog import. | Import UI has preview, validation, job status, and usable imported public references. |  |
| 2 | Review ad-policy console. | Creator can allow/block categories or brands and saved version is visible. |  |
| 3 | Play or inspect ad-supported fan content after policy save. | Playback/ad decision reflects the latest creator policy. |  |
| 4 | Review creator archive-AI preview. | Creator can ask their own archive and receive cited answers before fans arrive. |  |
| 5 | Review membership setup. | Tier editor has preview, validation, and saved tier state. |  |

## Phase 14 - UX Hardening And Launch Regression

Goal: validate immersive discovery, richer media, async states, feed-style pagination, full launch demo, and optional preliminary physical-phone smoke. Final phone sign-off happens in Phase 26.

### UX Hardening

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open immersive discovery surface. | Full-height media surface renders with floating actions and bottom metadata/action panel. |  |
| 2 | Switch between dense and immersive discovery. | Navigation feels intentional and state does not get stale. |  |
| 3 | Check loading, empty, and error states where reachable. | States use reusable polished components and avoid raw test scaffolding. |  |
| 4 | Review media assets across feed, channel, player, campaign, launch, starter-pack, and Studio surfaces. | Main social surfaces are visual-first and not mostly text or generic placeholders. |  |
| 5 | Trigger feed pagination. | Additional content loads without duplicates or jarring layout shifts; explicit test path still exists. |  |

### Final Launch Demo And Optional Phone Smoke

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Run the full launch demo on emulator. | Re-acquisition -> starter pack -> consume -> conversion analytics -> utility console -> export/reset works end to end. |  |
| 2 | Reset demo and relaunch on emulator. | App returns to seeded baseline without stale launch state. |  |
| 3 | If physical hardware is available, install APK on Android phone as a preliminary smoke. | Install succeeds and app launches to first rendered screen; otherwise record phone validation as deferred to Phase 26. |  |
| 4 | If hardware is available, run key launch flows as a preliminary smoke. | Capture/starter pack, discovery/playback, conversion analytics, and export/reset work on hardware. |  |
| 5 | If hardware is available, inspect phone layout. | Safe areas, scrolling, text wrapping, and tap targets work without clipping or overlap. |  |

## Phase 15 - Extensions Platform Foundation

Goal: validate that certified extensions, installs, creator configs, and reset behavior exist before live extension UX.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Reset demo and open a gaming creator channel such as NovaClutch. | Channel loads with a distinct gaming theme and installed extension slots. |  |
| 2 | Review all five gaming creators. | Each has a different theme/banner/module order; no creator appears as a clone of another. |  |
| 3 | Inspect extension slot copy. | Slot names, versions, approved surfaces, and config summaries are visible and not broken placeholders. |  |
| 4 | Reset demo again. | Extension slots and creator configs return to seeded baseline. |  |

## Phase 16 - Config-Driven Channel Renderer

Goal: validate the fan channel renderer uses `CreatorExperienceConfig` rather than hardcoded creator UI.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open NovaClutch, EmberHollow, FrameByFrame, DriftAndChill, and IronVael channels. | Theme, banner, first module, and module order visibly differ per creator. |  |
| 2 | Open a non-gaming creator channel. | The generic renderer still shows identity, ad posture, archive entry, and content without gaming-specific copy. |  |
| 3 | Review AI archive entry and ad posture copy. | Persona and ad posture read as creator-specific data and remain legible at phone width. |  |
| 4 | Scroll through all modules. | Unknown or inactive modules render stable safe placeholders, not crashes or raw debug text. |  |

## Phase 17 - Competitive And Economy Extensions

Goal: validate Clip Arena, Pick'Em, and HypeWars render as live fan modules inside creator channels.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open NovaClutch. | Clip Arena, Pick'Em, and HypeWars appear inside the channel module stack. |  |
| 2 | In Clip Arena, submit a clip and vote the leader. | The leaderboard updates, shows the submitted clip, and vote/reward feedback is visible. |  |
| 3 | In Pick'Em, choose an option. | The selected pick is shown and the ladder includes the fan standing/points. |  |
| 4 | In HypeWars, send simulated hype. | Wallet copy remains clearly simulated, meter advances, and contribution feedback is visible. |  |
| 5 | Compare NovaClutch and FrameByFrame Clip Arena. | Same module renders with different creator-specific prompt/config. |  |

## Phase 18 - Collaborative And Creative Extensions

Goal: validate Quest Log, Build Showcase, and Guild Quest once implemented.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open EmberHollow. | Quest Log and Build Showcase render as live modules with cozy/lore-specific copy. |  |
| 2 | Add progress to Quest Log. | Progress persists and aggregate progress updates without exposing fan identity beyond the demo fan view. |  |
| 3 | Submit and vote on Build Showcase. | Submission appears in the showcase and rank/vote affordances remain phone-readable. |  |
| 4 | Open IronVael. | Guild Quest renders roster/progress state and milestone rewards using the shared runtime pattern. |  |

## Phase 19 - Creator Studio Customize Console

Goal: validate creator controls for channel theme, extension installs, module order, and preview.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator Studio customization. | Theme/banner controls, extension list, module order, and preview are reachable from Studio. |  |
| 2 | Change a theme/banner option. | Preview updates immediately and saved changes persist after navigation. |  |
| 3 | Install/configure an extension. | Permissions/surfaces are clear, config fields are understandable, and save uses idempotent API behavior. |  |
| 4 | Reorder modules. | Fan channel preview reflects the new order without layout jumps. |  |
| 5 | Switch to Fan App and open the creator channel. | Fan-facing channel uses the Studio-authored config. |  |

## Phase 20 - Customization Showcase

Goal: validate the complete customized demo on the Flutter Android emulator. Final physical-phone validation is Phase 26.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Run the full customized fan demo on emulator. | Discovery -> creator channel -> extension modules -> playback/Q&A/wallet/export flows work together. |  |
| 2 | Run the Creator Studio customization path on emulator. | Creator can adjust appearance/extensions and immediately verify in preview/Fan App. |  |
| 3 | Review the five gaming creator worlds on emulator. | Each creator has distinct generated media, theme, module order, extension content, persona, and ad posture. |  |
| 4 | Check loading, empty, and error states on the new surfaces. | Channel, extension, and Studio customization surfaces use polished reusable states without raw placeholders. |  |
| 5 | Reset demo on emulator. | App returns to seeded baseline without stale extension, wallet, or customization state. |  |

## Phase 21 - AI Search And External Content Foundation

Goal: validate that AI-search contracts, seed state, fakes, and reset behavior exist before user-facing search UX.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Reset demo and relaunch. | App starts cleanly with AI-search/external-content seed state loaded. |  |
| 2 | Open existing Fan App search/discovery. | Existing neutral search and creator feeds still work before AI-search UI is enabled. |  |
| 3 | Inspect five gaming creator channels if reachable. | Seeded external-content references do not break channel rendering. |  |
| 4 | Reset demo again. | Seeded external-content and AI-search fake state returns to baseline. |  |

## Phase 22 - Fan AI Search Settings

Goal: validate simulated agent/source connection settings and disclosure UX.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Fan Settings. | AI search settings are discoverable without crowding primary social navigation. |  |
| 2 | Connect a simulated AI search agent. | Provider, status, and simulated connection copy are explicit and honest. |  |
| 3 | Enable external sources and simulated YouTube. | Source toggles persist and explain query egress clearly. |  |
| 4 | Set prefer-creators default. | The preference is saved and the UI explains creator-first ranking behavior. |  |

## Phase 23 - AI Search Results

Goal: validate merged creator + external search results with creator-preferred ranking and compliant external-title handling.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Search with an AI-search agent connected. | Results merge creator-owned and external content without paid-placement copy. |  |
| 2 | Review creator-preferred ordering. | Creator results are clearly prioritized when relevant and explainable. |  |
| 3 | Inspect external result rows. | External title/thumbnail/source remain unaltered; additive match labels and source chips are separate. |  |
| 4 | Disconnect or disable the agent if reachable. | Search falls back to neutral existing behavior. |  |

## Phase 24 - Embedded Player And AI-Driven Next

Goal: validate official external playback and AI-driven next recommendations.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open a YouTube external result. | Official in-app YouTube player renders unobscured with source attribution. |  |
| 2 | Review the next rail. | "Next from your AI search" appears as Loom-owned recommendation context, not platform autoplay. |  |
| 3 | Open a non-YouTube external result if seeded. | App uses external-open behavior with clear source context. |  |
| 4 | Test offline/error state if possible. | External playback shows a polished error state and preserves navigation. |  |

## Phase 25 - Creator External Content In Feeds

Goal: validate creator-authored external-content linking and fan feed rendering.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator Studio external-content linking. | Creator can add/review external content with source, title, attribution, and gating controls. |  |
| 2 | Save an external-content item. | Saved state is visible and uses idempotent API behavior. |  |
| 3 | Switch to Fan App and open the creator channel/feed. | External content appears as a native tile with unaltered source title and clear attribution. |  |
| 4 | Toggle search/indexing or AI-queryable controls if available. | Fan feed/search behavior reflects the selected gates. |  |

## Phase 26 - Gaming Seed Showcase And Final Validation

Goal: validate the full AI-search + external-content showcase on emulator and complete authoritative physical Android phone sign-off.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Run the full launch + customization + AI-search showcase on emulator. | Re-acquisition, starter pack, five gaming worlds, AI search, external playback, Studio authoring, export, and reset work together. |  |
| 2 | Open Fan Settings, connect the simulated agent, enable YouTube, and search a gaming topic. | Mixed creator/external results preserve original external title, source chip, accurate-match label, and no-ad/no-boost disclosure. |  |
| 3 | Open a YouTube AI-search result. | Official embedded player is unobscured, no Loom ads cover the embed, and AI-driven next rail appears. |  |
| 4 | Open NovaClutch, EmberHollow, FrameByFrame, DriftAndChill, and IronVael. | Each channel includes a native creator-linked YouTube tile with source attribution and creator note. |  |
| 5 | Tap one creator-linked YouTube tile. | It opens the same embedded playback flow and preserves original title/source context. |  |
| 6 | Install the final APK on a physical Android phone and record device ID/model. | `adb install` succeeds and app launches to first rendered screen on hardware. |  |
| 7 | Run the full showcase on the phone. | Safe areas, scrolling, text wrapping, tap targets, async states, and real network playback work on hardware. |  |
| 8 | Capture validation screenshots. | Emulator and physical-phone screenshots are stored under `data/validation/` and remain gitignored. |  |
| 9 | Reset demo on phone and emulator. | Both return to seeded baseline without stale extension, wallet, customization, search, or external-content state. |  |

## Cross-Phase Visual Regression Pass

Run this after Phase 6, Phase 8, Phase 9, Phase 13, Phase 14, Phase 17, Phase 19, Phase 20, Phase 23, Phase 24, Phase 26, or whenever the app shell changes.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Visit Fan App home, creator channel, playback, Q&A, wallet, data rights, campaigns. | Surfaces look like one coherent modern social app. |  |
| 2 | Visit Creator Studio onboarding, publishing, revenue, audience, campaign, export. | Studio surfaces look like one coherent creator tool. |  |
| 3 | Check top bars and bottom navigation. | Icons, labels, spacing, selected states, and tap targets are consistent. |  |
| 4 | Check sheets and dialogs. | Sheets use clear titles, primary/secondary actions, and no clipped text. |  |
| 5 | Check long content and scrolling. | Text does not overlap; cards maintain stable dimensions; no controls jump while loading. |  |
| 6 | Check empty/loading/success/error states where reachable. | States feel intentional and not like raw test scaffolding. |  |

## Issue Log Template

Copy this block for each validation issue:

```text
Phase:
Screen:
Action:
Expected:
Actual:
Severity: blocker / high / medium / low
Screenshot:
Notes:
```
