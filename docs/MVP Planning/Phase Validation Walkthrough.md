# Phase Validation Walkthrough

This is the manual validation playbook for the Demo App while implementation continues in parallel. Use it to walk through each validation checkpoint, record pass/fail notes, and send issues back as they come up. Implementation does not need to pause unless a blocker makes the app unusable.

## How To Use

1. Use the Android emulator build that is currently installed.
2. Validate the latest implemented phase available in the tracker.
3. Mark each checklist item as `Pass`, `Fail`, or `Needs change`.
4. For every issue, include the phase, screen, exact action, expected result, actual result, and a screenshot if useful.
5. If I am actively implementing later phases, keep sending validation notes; I will fold fixes into the current work or a follow-up commit.

## Current Validation Status

| Phase | Validation type | Current state | Entry point |
| --- | --- | --- | --- |
| 1 | High UX checkpoint | Complete, available for regression | Fan App and Creator Studio tabs |
| 2 | High UX checkpoint | Complete, ready for parallel validation | Creator Studio -> complete onboarding -> Open publishing setup |
| 3 | Major UX checkpoint | Pending implementation | Fan App discovery/home |
| 7 | High UX checkpoint | Pending implementation | Data rights surfaces |
| 9 | Final full-app validation | Pending implementation | Full demo runbook and physical phone |

## Phase 1 - Identity And Onboarding

Goal: validate the identity foundation, fan interest picker, creator onboarding, and creator-card/follow flow.

### Fan Onboarding

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Fan App and tap `Start fan onboarding`. | Fan onboarding starts with a modern social-app style layout. |  |
| 2 | Create the demo fan passport. | Passport step completes and interest picker appears. |  |
| 3 | Select interests across categories. | Chips are easy to scan, selected state is clear, and scrolling is smooth. |  |
| 4 | Save interests. | App advances to privacy/persona setup without losing selections. |  |
| 5 | Continue through privacy defaults. | Defaults feel understandable and not overly technical. |  |
| 6 | Tap the suggested creator card. | Creator card is clickable and follow state completes. |  |
| 7 | Review final state. | Final state shows Fan onboarding complete, Following Solar Sarah, and private visibility. |  |

### Creator Onboarding

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator Studio. | Creator onboarding screen appears with a polished Studio-style channel card. |  |
| 2 | Tap `Create creator channel`. | Channel profile is created and hosting step appears. |  |
| 3 | Review managed-hosting copy. | The value of managed hosting is clear without feeling like legal text. |  |
| 4 | Tap `Accept managed hosting`. | Completion screen appears. |  |
| 5 | Review final state. | Channel name, handle, and hosting status are visible. |  |
| 6 | Tap `Open publishing setup`. | Phase 2 Studio setup opens. |  |

## Phase 2 - Creator Publishing And Monetization Setup

Goal: validate that the Creator Studio setup feels like a modern creator workflow, not a basic admin form.

### Setup Entry

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Creator Studio. | Creator onboarding or completed creator state appears. |  |
| 2 | Complete creator onboarding if needed. | `Open publishing setup` is visible. |  |
| 3 | Tap `Open publishing setup`. | Phase 2 setup screen opens with header, status cards, and publish composer. |  |
| 4 | Review first viewport. | The page feels dense, modern, and creator-focused; status cards and publish path are clear. |  |

### Publish Composer

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Review media preview and title/summary fields. | Media preview comes first; title and required summary are easy to understand. |  |
| 2 | Tap `Test missing summary`. | Inline error appears with `summary_required`. |  |
| 3 | Tap `AI draft summary`. | Summary field receives a usable draft. |  |
| 4 | Tap `Publish video`. | Success state shows manifest version. |  |
| 5 | Tap `Publish post`. | Member-only post publishes successfully after summary exists. |  |

### Import, Membership, Ads, AI

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Scroll to catalog import and tap `Start import`. | Import completes and external refs success state appears. |  |
| 2 | Tap `Define tiers`. | Membership setup reports entitlement definitions registered. |  |
| 3 | Tap `Save policy`. | CreatorAdPolicy persisted state appears and blocked categories are clear. |  |
| 4 | Tap `Enable AI`. | AIContentPolicy stored state appears. |  |
| 5 | Review whole page after setup. | Controls feel compact; saved states are easy to verify; no text overlaps. |  |

## Phase 3 - Discovery Core

Goal: validate Fan App discovery: startup tiles, session intent, glass-box feed, feedback, mid-session switching, trending, and neutral search.

### Startup Tiles And Intent

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open Fan App after Phase 3 is installed. | Home/Discover surface shows modern intent/topic entry points. |  |
| 2 | Select a startup tile or intent chip. | A session intent is created and the disclosure is visible. |  |
| 3 | Review tile design. | Tiles are visual, scannable, and explain what kind of feed they start. |  |

### Glass-Box Feed

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Review feed cards. | Cards show thumbnail/media, title, summary, creator, and compact why-shown badges. |  |
| 2 | Open a why-shown explanation. | Bottom sheet or detail view explains top ranking factors without overwhelming the feed. |  |
| 3 | Load more. | Page 2 loads without duplicated content or jarring layout shifts. |  |
| 4 | Review trending/entertainment mode. | Trending items use host aggregate stats and feel visually distinct enough. |  |

### Feedback And Search

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Like, dislike, mute, or block from a feed card. | Feedback affordances are icon-based, clear, and optimistic. |  |
| 2 | Refresh or fetch next page. | Disliked/muted content is suppressed or visibly affected. |  |
| 3 | Switch session intent mid-session. | Disclosure updates and feed re-ranks for the new intent. |  |
| 4 | Search for a topic or creator. | Search feels neutral, uses thumbnails/creator rows, paginates, and shows no ad fields. |  |

## Phase 7 - Data Rights And Data For Value

Goal: validate consent, data grants, relationship controls, and data-access receipts.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Open data rights dashboard. | Dashboard explains active consents and data categories clearly. |  |
| 2 | Review a creator data-request. | Request explains purpose, value exchange, categories, duration, and revocation. |  |
| 3 | Approve, deny, and narrow a request in separate runs. | Each choice is obvious, persisted, and reversible where expected. |  |
| 4 | Revoke a grant. | Revocation updates the dashboard and downstream access state. |  |
| 5 | Inspect DataAccessReceipt. | Receipt is understandable and shows who accessed what, when, and why. |  |

## Phase 9 - Final Full-App Validation

Goal: validate the complete demo, portability/export, transparency, reset, and physical-phone run.

| Step | Action | Expected result | Result |
| --- | --- | --- | --- |
| 1 | Run the full author-to-consume demo. | Creator authors content/policies; Fan App consumes the authored output. |  |
| 2 | Run the six-step wow demo. | Flow is smooth and understandable without developer explanation. |  |
| 3 | Create creator export. | Export job completes and contains channel, content, receipts, settlement, and policy data. |  |
| 4 | Review transparency surfaces. | Fan and creator can understand why content, ads, receipts, and data accesses occurred. |  |
| 5 | Reset demo. | App returns to seeded baseline without stale authored state. |  |
| 6 | Run on physical Android phone. | APK installs, launches, and key flows work on physical hardware. |  |

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
