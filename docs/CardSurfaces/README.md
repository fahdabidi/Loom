# Loom Card Surfaces Catalog

Status: Draft for review
Audience: Skill authors, extension builders, product designers, API reviewers

Card surfaces are reusable, production-grade Loom community UI patterns. A Skill-created extension
should choose card surfaces before it writes routes, schemas, rules, workflows, jobs, or tests. Each
surface has a domain interaction model, persona/permission model, customization points, and backend API
support requirements.

## How To Use This Catalog

1. Identify the community job-to-be-done.
2. Select the closest card surface family.
3. Configure domain copy, fields, actions, icons, imagery, and role/persona rules.
4. Map every interaction to the API contracts in [../API/CardSurfaces/README.md](../API/CardSurfaces/README.md).
5. Verify that selected interactions exist in the executable
   [Community Card Surfaces OpenAPI](../API/OpenAPI/community-surfaces/community-card-surfaces-api.openapi.yaml)
   and the Product Docs V2
   [workflow/user-story coverage map](../Product%20Docs%20V2/Card%20Surface%20Workflow%20and%20User%20Story%20Coverage.md).
6. Add seed data and fake backend fixtures for entry, action, result, receiver, read-only, disabled, and unauthorized states.
7. Capture B25 screenshot evidence for every persona/state before claiming production UX readiness.

## Surface Families

| Surface | Use for |
| --- | --- |
| [Community Card and Home](./community-card-home.md) | Installed community identity, entry, pinned state, next action. |
| [Announcement and Publish](./announcement-publish.md) | Compose, preview, schedule, publish, read, and revise announcements. |
| [Event RSVP](./event-rsvp.md) | Events, classes, practices, meetings, services, and capacity-based attendance. |
| [Member Meetup Scheduling](./member-meetup-scheduling.md) | One-to-one or small-group tennis matches, study sessions, photo walks, pickup games. |
| [Volunteer Signup](./volunteer-signup.md) | Shifts, roles, rosters, protected contact, check-in, and coordinator handoff. |
| [Equipment Loan](./equipment-loan.md) | Member-owned racquets, cameras, lenses, tools, books, or community gear loans. |
| [Plant or Item Exchange](./plant-exchange.md) | Offers, claims, pickup, privacy-safe contact, and handoff. |
| [Book Nomination](./book-nomination.md) | Nominations, rationale, eligibility, duplicate checks, ballot handoff. |
| [Vote and Poll](./vote-poll.md) | Ballots, polls, votes, change vote, close, results, selected outcome. |
| [Discussion and Message](./discussion-message.md) | Threads, replies, read state, moderation, archive, and attachments. |
| [Payment, Donation, Dues, and Ad-Off](./payment-donation-dues-ad-off.md) | Checkout, donation, dues, receipts, refunds, recurring payments, ad-off. |
| [Care and Protected Request](./care-protected-request.md) | Sensitive care/support requests with protected/public data split. |
| [Approval and Request](./approval-request.md) | HOA architectural requests, join approvals, committee reviews, gear approvals. |
| [Documents, Facilities, and Roster](./documents-facilities-roster.md) | Document viewers, facility booking, team/committee roster state. |
| [Search and AI Digest](./search-ai-digest.md) | Permission-aware search, citations, AI answers, saved/shareable digests. |
| [Export, Import, and Transfer](./export-import-transfer.md) | Export scope, redaction, checksum, provider transfer, rollback. |
| [Messaging and Connections](./messaging-connections.md) | Invites, connections, block/mute/archive, direct and group messaging. |
| [Ads, No-Fill, and Ad-Off](./ads-no-fill-ad-off.md) | Sponsored items, disclosures, no-fill, ad-off entitlement and receipt. |
| [Custom Form Submission](./custom-form-submission.md) | Generic but production-grade forms, drafts, validation, review, protected fields. |
| [Notification Inbox](./notification-inbox.md) | Delivered messages, notification preferences, read/archive, retry and source open. |

## Required Documentation Per Extension

Every generated extension must include:

- A surface selection matrix.
- Persona/permission mapping for each selected surface.
- API/rules/events mapping for every surface action.
- Entry/action/result/receiver screenshot evidence.
- Fake backend fixtures proving state changes.
- Export/import coverage for surface-owned data.

## Production UX Rule

A card surface is not production-grade when it only displays a workflow label and a single action. It
must show the concrete object, decision context, natural primary and alternate actions, durable result
state, and receiver or continuation state a real user expects.
