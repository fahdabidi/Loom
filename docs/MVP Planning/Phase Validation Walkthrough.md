# Phase Validation Walkthrough

This is the manual validation playbook for the Demo App while implementation continues in parallel. Use it to validate the latest installed Android emulator build, record pass/fail notes, and send issues back as they appear. Implementation can continue unless a blocker makes the app unusable.

## How To Use

1. Launch the latest installed Demo App on the Flutter Android emulator.
2. Check [Demo App Implementation Plan](./Demo%20App%20Implementation%20Plan.md) for the latest completed or in-progress phase.
3. Walk through the section for that phase. Skip pending phases until a build with that phase is installed.
4. Mark each row as `Pass`, `Fail`, or `Needs change` in the Result column.
5. For every issue, send the issue template at the bottom of this doc with the phase, screen, action, expected result, actual result, and screenshot if useful.

Physical Android phone validation is deferred until Phase 9. Phases 0 through 8 are validated on the Flutter Android emulator.

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
| 8 | Medium UX checkpoint | In implementation / validation | Recommendations, referral, and campaigns |
| 9 | Final full-app validation | Pending implementation | Export, transparency, reset, emulator, physical phone |

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
| 7 | Review final state. | Final state shows fan onboarding complete, Following Solar Sarah, and private visibility. |  |

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

Goal: validate export/portability, transparency surfaces, demo reset, full author-to-consume flow, emulator run, and physical-phone run.

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
| 6 | Validate on physical Android phone. | APK installs, launches, and key full-demo flows work on physical hardware. |  |

## Cross-Phase Visual Regression Pass

Run this after Phase 6, Phase 8, and Phase 9, or whenever the app shell changes.

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
