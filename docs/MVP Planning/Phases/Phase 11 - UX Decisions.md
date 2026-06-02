# Phase 11 - UX Decisions

## Reference Patterns Applied

- Link-in-bio products: compact creator identity, one primary Loom follow link, and secondary public profile links.
- Bluesky Starter Pack sharing: launch assets should make the follow CTA clear while deferring the fan-side starter-pack confirmation to Phase 12.
- YouTube/Substack/Patreon creator announcements: use direct "follow me here" language and reusable channel-specific templates.
- Event/community QR flows: QR card pairs a scannable visual with a copyable URL and a short destination explanation.
- YouTube Studio and Patreon tools: creator workflows use task cards, status rows, and previews rather than marketing-style hero layouts.

## Decisions

- The Creator Studio dashboard gets a `Launch` entry, separate from recommendations/campaigns/export, because this is an operational launch workflow.
- The main panel leads with actions and status; the explanation that followers are not imported lives in an info sheet.
- QR rendering is a deterministic offline visual derived from the capture payload, avoiding network and image dependencies.
- Link copy and rendered announcement remain selectable/copyable because this phase is about creator assets, not fan onboarding.
- External accounts are shown as verified public promotion channels, not as credential or follower-graph sources.
- Cross-post status is labeled as simulated delivery; real external posting is not implied.

## Workflow Walkthrough

1. Creator opens Studio and selects Launch.
2. Screen loads creator identity, templates, link-in-bio data, and verified external accounts through typed APIs.
3. Creator selects an announcement template.
4. Creator generates launch assets, which creates a capture link and rendered announcement.
5. Screen shows copyable capture URL, QR follow card, link-in-bio preview, and rendered announcement copy.
6. Creator simulates cross-post delivery and sees explicit stub status rows for verified channels.
7. Creator can open the info sheet to explain that Loom invites manual re-follows and does not import followers.

## Implementation Notes

- `CreatorLaunchController` owns API orchestration and exposes testable state transitions.
- `StudioLaunchPanel` keeps the console dense and mobile-friendly, with task/status cards before preview sections.
- Phase 12 should consume the capture-link fan landing and starter-pack APIs rather than extending Phase 11's creator UI.
