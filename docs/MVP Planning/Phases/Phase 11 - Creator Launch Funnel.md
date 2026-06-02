# Phase 11 — Creator Launch Funnel

**Surface:** Creator Studio · **UX gate:** HIGH · **On green:** STOP for UX checkpoint, then AUTO → Phase 12
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 10. This phase builds the creator-facing launch/growth
> workflow on top of the Phase 10 contracts and fakes: announcement templates, link-in-bio preview,
> QR/capture link, external account context, and cross-post stub status. It implements the creator side
> of **CE-S10** without building the fan starter-pack onboarding yet.

## 0. Prerequisite gate (validate Phase 10 done)
README gate + confirm Phase 10 contracts, store, fakes, seed data, reset behavior, and DI registrations
are green. New launch APIs must be callable through typed clients only; no screen may reach into fake
backend or local-store internals.

## 1. Workflows & user stories in this phase
- **CE-S10 / creator re-acquisition funnel** — Creator opens Launch/Grow, chooses an announcement
  template, renders the announcement, gets a link-in-bio preview, QR payload, and capture link.
- **CE-S10 / external promotion context** — Creator sees linked external-account rows and cross-post
  stub status so the demo can explain that Loom drives manual re-follows rather than importing a graph.
- **CE-S10 / manual-conversion honesty** — All copy says "invite your audience to follow you on Loom";
  no wording may imply automatic follower import or unavailable incumbent graph import.

Phase 11 does not require the fan to complete the starter pack; it only proves the creator can generate
the launch assets that Phase 12 consumes.

## 2. Tools (WSL Ubuntu)
Standard set. Add an offline QR renderer such as `qr_flutter` only if the design system needs it for
the QR card. No network calls or external posting.

## 2A. UX reference research & decision output
Before implementing the creator launch UX, review:
- Linktree and other link-in-bio layouts: compact creator identity, primary link, secondary links, and
  mobile preview.
- Bluesky Starter Pack sharing surfaces: share link, creator/community context, and clear follow CTA.
- YouTube/Substack/Patreon creator announcement patterns: "I moved here" copy, launch templates, and
  creator-owned-channel calls to action.
- QR follow flows from event/community apps: QR card hierarchy, copyable URL, and share affordances.
- YouTube Studio / Patreon creator tools: dashboard cards, preview panels, task status, and validation.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 11 specifics:
- Add a Creator Studio "Launch" or "Grow" entry that feels like a creator console, not a marketing page.
- Use a two-pane mobile-friendly Studio pattern: task list/status cards followed by preview panels.
- Keep QR, copy-link, and template controls as icon+text buttons with clear primary action hierarchy.
- Put long explanation of "why no follower import" in a sheet; keep the main screen action-oriented.
- Show cross-post as a stubbed delivery/status row, not a fake successful integration with real platforms.

Create [Phase 11 - UX Decisions.md](./Phase%2011%20-%20UX%20Decisions.md) with references, extracted
patterns, key UX/implementation decisions, and a walkthrough of the creator launch workflow.

## 3. APIs invoked & stubs to implement
Use Phase 10 typed clients:
- **Creator Announcement API:** list templates, render announcement, get link-in-bio page.
- **Fan Follow Capture API:** create capture link for the creator/channel.
- **External Account Link API:** list linked/verified public external accounts.
- **Cross-Posting API:** create/read stub cross-post job status.
- **Creator Metadata API:** creator/channel identity for preview.

No new API surface should be introduced unless the Phase 11 API Review proves a concrete screen field
cannot be sourced from existing contracts.

## 4. Data storage (local store)
No new tables expected beyond Phase 10. This phase writes:
- Rendered announcements.
- Capture links.
- Link-in-bio page updates.
- Cross-post stub jobs.

Verify `resetDemo()` clears rendered/mutable launch state while retaining seed templates.

## 5. Source files & components to create/update
Design system:
- `core/loom_design_system/lib/components/studio/launch_panel.dart`
- `core/loom_design_system/lib/components/qr_card.dart`
- Optional small components: `copy_link_row.dart`, `launch_template_card.dart`, `cross_post_status_row.dart`

Creator feature:
- Prefer a new `features/creator/feature_creator_launch/` package to keep launch work isolated.
- Add `CHARTER.md`, barrel, route/entry widget, state/view model, and DTO-to-view mappers.
- Wire the Creator Studio shell to expose Launch/Grow from the Studio dashboard.

App shell / DI:
- Use existing DI getters for Phase 10 clients.
- No feature→fake/backend imports.

## 6. API best-practice checks (phase-specific)
- Rendering an announcement is idempotent for the same template/variables/idempotency key.
- Creating a capture link returns enough data for QR, copy-link, and landing-page resolution.
- Cross-post stub status is explicit: draft, queued, simulated, or unavailable. Do not imply real external posting.
- Link-in-bio response contains only fields shown by the preview.
- External account rows expose public handles/URLs and verification status only.

## 7. Component boundary / design checks
- `feature_creator_launch` imports only contracts, design system, and app shell.
- Launch panel components remain pure UI; no API imports in `loom_design_system`.
- Creator Studio shell wiring does not import fan feature packages.
- `CHARTER.md` documents that Phase 12 owns fan landing/starter-pack UX.

## 8. Automated validation checks
README baseline plus:
- Unit tests for launch view-model state transitions: load templates → render → create capture link → cross-post stub.
- Widget tests for `launch_panel` and `qr_card`: preview renders, copy action exists, loading/error states are present.
- Contract/fake tests for missing variables, expired capture-link preview data, and cross-post unavailable state.

## 9. Integration tests
- `it_p11_creator_launch_assets` — Creator opens Launch/Grow, renders an announcement, sees link-in-bio preview,
  QR card, and capture link.
- `it_p11_cross_post_stub` — Creator starts simulated cross-post and sees explicit stub delivery status without
  any real external-platform promise.
- `it_p11_launch_copy_honesty` — screen copy includes manual re-follow language and does not use "import followers"
  as an action.

## 10. Definition of done
Creator can generate launch assets end to end in Creator Studio: template, rendered announcement, link-in-bio
preview, QR/capture link, and cross-post stub status. All data comes from typed API clients backed by Phase 10
fakes. All checks are green; debug APK builds and launches on the emulator; [Phase 11 - API Review.md](./Phase%2011%20-%20API%20Review.md)
and [Phase 11 - UX Decisions.md](./Phase%2011%20-%20UX%20Decisions.md) are filed. Update the Phase completion
tracker with Phase 11 status, completion date, API review link/name, gate evidence, and commit SHA.

## 11. Next phase
After Phase 11 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 12 — Fan Starter Pack Onboarding.md](./Phase%2012%20-%20Fan%20Starter%20Pack%20Onboarding.md).**
